--  ETCS on-board (EVC) / DMI
--  Native, touch-only start of mission: implementation.

pragma Ada_2012;
with Ada.Streams; use Ada.Streams;
with Display;
with Display.C_Area;
with DMI_Ack;
with DMI_Conditions;
with DMI_Core;
with DMI_Data_Entry;
with DMI_Link;
with DMI_Protocol; use DMI_Protocol;
with DMI_Windows;
with EVC_Track;
with Sim_Onboard_Env;
with Sim_Trackside;
with Supplementary_Driving_Info;
with Test_Support;

package body Evc_Test_Touch is

   package Env renames Sim_Onboard_Env;
   package SDI renames Supplementary_Driving_Info;

   use type DMI_Windows.Window_ID_T;
   use type DMI_Ack.Ack_Kind_T;
   use type SDI.Mode_T;

   ------------------------------------------------------------------
   --  Window-internal button indices (DMI_Windows.Button_Area), the
   --  same for every data entry / validation window: Tables 22, 23,
   --  24, 25 and 29, derived from the public DMI_Data_Entry.Max_Fields
   --  so that a change there moves these with it, not a copied pixel
   --  or a copied index.
   ------------------------------------------------------------------
   Key_Last    : constant := 12;                     -- Table 25
   Label_First : constant := Key_Last + 1;           -- Tables 22/23
   Data_First  : constant := Label_First + DMI_Data_Entry.Max_Fields;
   Yes_Button  : constant := Data_First + DMI_Data_Entry.Max_Fields;
                                                       -- Table 24
   Next_Button : constant := Yes_Button + 2;          -- Tables 22/23
   Key_Yes     : constant := 8;                       -- Table 29

   function Field_Data (I : Positive) return Positive is (Data_First + I - 1);

   function Digit_Key (C : Character) return Positive is
     (if C = '0' then 11 else Character'Pos (C) - Character'Pos ('0'));

   ------------------------------------------------------------------
   --  The wire, both directions, as the bench page connects them
   --  (test/wasm/index.html): the on-board's DMI frames (whole, from
   --  Sim_Onboard_Env.Take_DMI) split and fed to DMI_Core, the DMI's
   --  driver actions and data (Take_Outbox, With_Sounds => False: the
   --  caller only wants the driver's actions) fed to the on-board
   ------------------------------------------------------------------
   procedure To_DMI (The_Type : Msg_Type_T; Payload : Stream_Element_Array) is
   begin
      DMI_Core.Handle_Message (The_Type, Payload);
   end To_DMI;
   package From_Onboard is new DMI_Link (To_DMI, Capacity => 16_384);

   procedure Pump_To_Onboard is
      Buf  : Stream_Element_Array (1 .. 1024);
      Last : Stream_Element_Offset;
   begin
      DMI_Core.Take_Outbox (Buf, Last, With_Sounds => False);
      if Last >= Buf'First then
         Env.Receive (Buf (Buf'First .. Last));
      end if;
   end Pump_To_Onboard;

   --  One macro-cycle: the on-board's 100 ms cycle as two of the DMI's
   --  50 ms ticks (the bench page's ratio), both directions pumped.
   --  The bench page steps the DMI and the on-board on two independent
   --  timers (requestAnimationFrame): neither ever waits for the
   --  other. This harness instead drives both from the same thread, so
   --  every touch calls Cycle at least once to keep the on-board heard
   --  within General_Parameters.EVC_Link_Timeout_Ms (1 s, DMI 5.6.1):
   --  a touch sequence that called only DMI_Core.Tick would starve the
   --  on-board of its own cycle and trip the EVC link supervision,
   --  which would close every window (not a defect: the DMI is right
   --  to do that on a silent link; it is this harness's job not to
   --  create one).
   procedure Cycle is
      Frames : Stream_Element_Array (1 .. 16_384);
      Last   : Stream_Element_Offset;
   begin
      Env.Step (100);
      Env.Take_DMI (Frames, Last);
      if Last >= Frames'First then
         From_Onboard.Feed (Frames (Frames'First .. Last));
      end if;
      DMI_Core.Tick (50);
      DMI_Core.Tick (50);
      Pump_To_Onboard;
   end Cycle;

   ------------------------------------------------------------------
   --  Touch: down, a macro-cycle, an optional hold (a delay-type
   --  button, DMI 5.3.2.6.6, needs >= 2 s), up, another macro-cycle so
   --  the DMI's reaction (a window change, a queued driver action) is
   --  visible before the next touch
   ------------------------------------------------------------------
   procedure Tap (Area : Display.Area_T; Hold_Ms : Natural := 0) is
      X    : constant Natural := Area.Position.X + Area.Width / 2;
      Y    : constant Natural := Area.Position.Y + Area.Height / 2;
      Held : Natural := 0;
   begin
      Test_Support.Pointer_Down (X, Y);
      Cycle;
      while Held < Hold_Ms loop
         Cycle;
         Held := Held + 100;
      end loop;
      Test_Support.Pointer_Up (X, Y);
      Cycle;
   end Tap;

   procedure Tap_Button (Index : Positive; Hold_Ms : Natural := 0) is
   begin
      Tap (DMI_Windows.Button_Area (Index), Hold_Ms);
   end Tap_Button;

   procedure Tap_Digits (S : String) is
   begin
      for C of S loop
         Tap_Button (Digit_Key (C));
      end loop;
   end Tap_Digits;

   Settle_Cycles : constant := 50;  -- 5 s of margin for an on-board round trip

   procedure Run is
   begin
      DMI_Core.Initialise;
      Env.Set_Track_Preset (EVC_Track.Default);
      Env.Reset;
      Check (Sim_Trackside.Built_OK,
             "touch: every telegram of the default mission encoded");
      Env.Set_Desk (0, Auto => True);

      --------------------------------------------------------------
      --  S0 -> S1: the on-board reports the start of mission possible
      --  (SUBSET-026 5.4.3.2, a desk open and SB) and the DMI engages
      --  the Start Up dialogue sequence with the Driver ID window
      --  (DMI chapter 11.7.1.8, Table 49 S0 -> S1)
      --------------------------------------------------------------
      for I in 1 .. Settle_Cycles loop
         exit when DMI_Windows.Is_Open
                   and then DMI_Windows.Top = DMI_Windows.W_Driver_ID;
         Cycle;
      end loop;
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "DMI 11.7.1.8 Table 49 S0 -> S1: the Driver ID window with "
             & "a desk open and no mission (SUBSET-026 5.4.3.2)");
      if not DMI_Windows.Is_Open then
         return;  -- nothing further to drive through touch
      end if;

      --  S1: the driver ID, entered digit by digit (10.3.5.15) and
      --  accepted on the data part of its field (10.3.1.22)
      Tap_Digits ("1234");
      Tap_Button (Field_Data (1));

      --------------------------------------------------------------
      --  S1 -> S2: the level, not yet valid on a fresh on-board
      --------------------------------------------------------------
      Check (DMI_Windows.Is_Open and then DMI_Windows.Top = DMI_Windows.W_Level,
             "DMI Table 49 S1 -> S2: the Level window (11.3.2) once the "
             & "level is not valid");
      --  the dedicated keyboard of Table 38: choice 1 is level 1
      --  (dmi_windows.adb Level_Of_Choice), accepted the same way
      Tap_Button (1);
      Tap_Button (Field_Data (1));

      --------------------------------------------------------------
      --  S2 -> S10: level 0, 1 or NTC reaches the Main window at once
      --  (Table 49); S10 is S1 of the Main window dialogue sequence
      --  (11.7.3), where the driver chooses what to enter next
      --------------------------------------------------------------
      Check (DMI_Windows.Is_Open and then DMI_Windows.Top = DMI_Windows.W_Main,
             "DMI Table 49 S2 -> S10: the Main window after level 1");

      --  the on-board confirms the driver ID and the level
      --  (MSG_ONBOARD) before 'Train data' (Table 33 #3) enables
      for I in 1 .. Settle_Cycles loop
         exit when DMI_Conditions.Driver_ID_Valid
                   and then DMI_Conditions.Level_Valid;
         Cycle;
      end loop;
      Check (DMI_Conditions.Driver_ID_Valid and then DMI_Conditions.Level_Valid,
             "the on-board confirms the driver ID and the level "
             & "(MSG_ONBOARD, 11.7.1.3)");
      Check (DMI_Conditions.Main_Train_Data,
             "Table 33 #3: 'Train data' enabled (Driver_ID_Valid, "
             & "Level_Valid, standstill)");

      --------------------------------------------------------------
      --  Train Data (1/2): train category (a dedicated keyboard,
      --  choice 1), length, brake percentage, max speed (numeric).
      --  11.7.1.7 / Table 48: once Sequence_Active ends at S10, the
      --  window stays only while its enabling condition holds
      --  (DMI_Windows.Check_Enabling_Conditions, every DMI_Core.Tick),
      --  so every touch keeps the on-board heard (Cycle, above) or the
      --  window would close from under the driver on a silent link.
      --------------------------------------------------------------
      Tap_Button (3);  -- Table 33 #3 'Train data'
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "DMI 11.3.9: the Train Data window (1/2)");
      Tap_Button (1);                    -- category: choice 1
      Tap_Button (Field_Data (1));
      Tap_Digits ("400");                -- length (m)
      Tap_Button (Field_Data (2));
      Tap_Digits ("135");                -- brake percentage
      Tap_Button (Field_Data (3));
      Tap_Digits ("140");                -- max speed (km/h)
      Tap_Button (Field_Data (4));
      Tap_Button (Next_Button);          -- Table 22/23 [Next]: (2/2)

      --------------------------------------------------------------
      --  Train Data (2/2): axle load category, airtight, loading
      --  gauge (dedicated keyboards, choice 1 each), then "entry
      --  complete?" / 'Yes' (Table 24)
      --------------------------------------------------------------
      Tap_Button (1);
      Tap_Button (Field_Data (1));       -- axle load category: choice 1
      Tap_Button (Key_Yes);              -- airtight: Table 40 key 8 'Yes'
                                          -- (10.3.5.18, a Yes/No keyboard,
                                          -- not a dedicated choice list)
      Tap_Button (Field_Data (2));
      Tap_Button (1);
      Tap_Button (Field_Data (3));       -- loading gauge: choice 1
      Tap_Button (Yes_Button);           -- 'entry complete?' Yes

      --------------------------------------------------------------
      --  10.4.1 / 11.4.1: the validation window echoes the entered
      --  values; 'Yes' of its own single field stores them
      --------------------------------------------------------------
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Train_Data_Validation,
             "DMI 11.4.1: the Train Data validation window");
      Tap_Button (Key_Yes);
      Tap_Button (Field_Data (1));

      --------------------------------------------------------------
      --  Table 50 D6: the train running number requested next, since
      --  it is not yet valid (5.4.3.2)
      --------------------------------------------------------------
      Check (DMI_Windows.Is_Open and then DMI_Windows.Top = DMI_Windows.W_TRN,
             "DMI Table 50 D6: the train running number window (11.3.1), "
             & "not yet valid");
      Tap_Digits ("5678");
      Tap_Button (Field_Data (1));

      Check (DMI_Windows.Is_Open and then DMI_Windows.Top = DMI_Windows.W_Main,
             "DMI Table 50 S3-3 -> S1: back to the Main window");

      --------------------------------------------------------------
      --  'Start' (Table 33 #1), once the on-board confirms the Train
      --  Data and the train running number too
      --------------------------------------------------------------
      for I in 1 .. Settle_Cycles loop
         exit when DMI_Conditions.Main_Start;
         Cycle;
      end loop;
      Check (DMI_Conditions.Main_Start,
             "Table 33 #1: 'Start' enabled (Driver ID, Train Data, level "
             & "and the train running number all valid, standstill, SB)");
      Tap_Button (1);

      --------------------------------------------------------------
      --  5.4.3.2 / 5.4.5.3: the mode proposed (Staff Responsible,
      --  level 1 without a radio session) and its acknowledgement,
      --  a delay-type button for SR (8.2.3.1.4, MO10, 5.3.2.6.6: 2 s)
      --------------------------------------------------------------
      for I in 1 .. Settle_Cycles loop
         exit when DMI_Ack.Current_Valid
                   and then DMI_Ack.Current_Kind = DMI_Ack.Mode_Change;
         Cycle;
      end loop;
      Check (DMI_Ack.Current_Valid
             and then DMI_Ack.Current_Kind = DMI_Ack.Mode_Change
             and then DMI_Ack.Current_Mode = SDI.M_SR,
             "SUBSET-026 5.4.5.3 h): SR proposed in level 1 without a "
             & "radio session, DMI 5.4.1: its acknowledgement offered");
      Tap (Display.C_Area.C1_Absolute_Area, Hold_Ms => 2_100);

      for I in 1 .. Settle_Cycles loop
         exit when Env.Mode_Code = 7;
         Cycle;
      end loop;
      Check (Env.Mode_Code = 7 and then SDI.Mode = SDI.M_SR,
             "SUBSET-026 4.6.3 [8]: SR once the mode proposed is "
             & "acknowledged on the DMI, not by a frame of this test");

      --------------------------------------------------------------
      --  4.6.3 [32]: FS at the movement authority of the first balise
      --  group, with the automatic driver below the permitted speed
      --------------------------------------------------------------
      for I in 1 .. 2_000 loop
         exit when Env.Mode_Code = 2;
         Cycle;
      end loop;
      Check (Env.Mode_Code = 2 and then SDI.Mode = SDI.M_FS,
             "SUBSET-026 4.6.3 [32]: FS at the movement authority of the "
             & "first balise group, driven on the DMI alone");
      Check (not Env.Failed, "touch: the on-board did not fail");
   end Run;

end Evc_Test_Touch;
