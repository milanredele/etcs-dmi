--  ETCS DMI
--  Body of DMI_Test_ATO (see dmi_test_ato.ads).

with Ada.Streams;
with DMI_ATO;
with DMI_Buttons;
with DMI_Core;
with DMI_Data_Entry;
with DMI_Driver_Data;
with DMI_Planning;
with DMI_Protocol;
with DMI_Sounds;
with DMI_Test_Support;
with DMI_Windows;
with Display.Screen;
with Display.Screen.Files;
with EVC_ATO;
with EVC_Driver;
with EVC_Mock;
with EVC_Track;
with EVC_Train;
with Interfaces;
with Test_Support;
use Test_Support;
use DMI_Test_Support;

package body DMI_Test_ATO is

   -- Automatic Train Operation information (audit ATO-1: DMI 8.5,
   -- 11.3.14; audit PLN-5: 8.3.4.25). MSG_ATO carries what the
   -- ERTMS/ATO on-board tells and the ATO selector position.
   ---------------------------------------------------------------------

   -- G1 and G5 (area G at (334, 315)): the ATO engage / disengage and
   -- the skip stopping point buttons
   G1_X : constant := 358;
   G5_X : constant := 555;
   G_Y  : constant := 340;

   -- FS, a planning with two orders and an advice change at 600 m
   procedure ATO_Reset is
   begin
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 4000, Ceiling => 140,
                     Advice => 600,
                     Gradients => (0, 2),
                     Speeds => (1 => 4000, 2 => 0, 3 => 1),
                     Orders => (5, 1200,  9, 2600));
      Send_Status (HH => 17, MM => 33, SS => 25);
      Step;
      Drain_Sounds;
      Drain_Outbox;
   end ATO_Reset;

   -- Everything of 8.5.1.2 d the on-board can tell outside stopping
   -- points in FS (Figure 93e)
   procedure Send_ATO_Outside (Selector : Natural;
                               Status   : Natural := 2;
                               Skip     : Natural := 1) is
   begin
      Send_ATO (Selector     => Selector,
                Status       => Status,
                Skip         => Skip,
                Advice_Speed => 125,
                Coasting     => True,
                ETA_H        => 17, ETA_M => 36, ETA_S => 48,
                Name         => "Welwyn North",
                Stops        => (1 => 1800));
   end Send_ATO_Outside;

   procedure Scenario_ATO_Displays is
      Without_ATO : Natural := 0;
   begin
      ATO_Reset;
      Step;
      declare
         Picture : constant String := Display.Screen.Files.Digest;
      begin
         -- 8.5.1.1: with the selector at Stand-by nothing of 8.5 is
         -- shown, whatever the on-board tells; the next advice change
         -- marker of MSG_PLANNING neither
         Send_ATO_Outside (Selector => 1);
         Step;
         Check (Display.Screen.Files.Digest = Picture,
                "8.5.1.1: Stand-by shows no ATO information");
         -- a selector position not known is read as Stand-by
         Send_ATO_Outside (Selector => 7);
         Step;
         Check (Display.Screen.Files.Digest = Picture,
                "an unknown selector position shows nothing either");
         Check (not DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_ATO_Engage),
                "no ATO button without the selector");
         Without_ATO := 1;
      end;
      Check_Frame ("ato_selector_standby");

      -- 8.5.1.1 / Figure 93e: on, outside stopping points in FS: ATO02
      -- in G1, name and arrival time over G2-G4, ATO17 in G5, the target
      -- advice speed in B0, the coasting advice in B8, the stopping
      -- point in D2 and the next advice change marker in D7
      Send_ATO_Outside (Selector => 2);
      Step;
      Check_Frame ("ato_outside_fs");
      Expect_No_Sound ("the ATO objects play no sound");

      -- Figure 93c: engaged in AD; the skip requested by the driver.
      -- Target advice speed and coasting advice are the on-board's to
      -- send (SUBSET-026 Table 4.7.2: FS only); the DMI shows what comes
      Send_Mode_Level (Mode => 3, Level => 4); -- AD
      Send_ATO (Status => 3, Skip => 3,
                ETA_H => 17, ETA_M => 36, ETA_S => 48,
                Name => "Welwyn North", Stops => (1 => 1800));
      Step;
      Drain_Sounds;
      Check_Frame ("ato_outside_ad");

      -- Figures 93b / 93d: at a stopping point, accurate stop, 1:09 of
      -- dwell time, doors open; the stopping point at the train front
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_ATO (Status => 1, At_Stop => True, Accuracy => 3, Dwell => 69,
                Doors => 4, Skip => 1, Advice_Speed => 125,
                Coasting => True, Name => "Welwyn North",
                ETA_H => 17, ETA_M => 36, ETA_S => 48,
                Stops => (0, 2500));
      Step;
      Drain_Sounds;
      Check_Frame ("ato_at_stop");
      Check (not DMI_ATO.Skip_Button,
             "8.5.1.2: no skip stopping point button at a stopping point");

      -- 8.5.5.4: up to 59 s the seconds alone; overshoot, request to
      -- open the left doors
      Send_ATO (Status => 1, At_Stop => True, Accuracy => 1, Dwell => 45,
                Doors => 2, Stops => (1 => 0));
      Step;
      Check_Frame ("ato_dwell_seconds");

      -- 8.5.5.7: "Train hold"; undershoot, doors being closed by ATO
      Send_ATO (Status => 1, At_Stop => True, Accuracy => 2, Dwell => 45,
                Train_Hold => True, Doors => 6, Stops => (1 => 0));
      Step;
      Check_Frame ("ato_train_hold");

      -- the other statuses and door symbols of 8.5.2.4 / 8.5.6.3
      Send_ATO (Status => 5, At_Stop => True, Dwell => 5_999, Doors => 1);
      Step;
      Check_Frame ("ato_failure_both_doors");
      Send_ATO (Status => 4, At_Stop => True, Dwell => 600, Doors => 5);
      Step;
      Check_Frame ("ato_disengaging");
      Send_ATO (Status => 1, At_Stop => True, Dwell => 0, Doors => 3);
      Step;
      Check_Frame ("ato_right_doors");
      Send_ATO (Status => 1, At_Stop => True, Doors => 7);
      Step;
      Check_Frame ("ato_doors_closed");

      -- ATO18: skip requested by the ATO-TS, not a button (8.5.8.5); a
      -- name wider than G2-G4 stays inside it
      Send_ATO (Status => 3, Skip => 2,
                Name => "Hertford North Interchange Road",
                Stops => (1 => 900));
      Step;
      Check_Frame ("ato_skip_trackside_long_name");
      Check (not DMI_ATO.Skip_Button, "8.5.8.5: ATO18 is no button");

      -- the "nothing known" readings of dmi_protocol.ads: undefined
      -- codes and out of range values show nothing
      Send_ATO (Status => 9, At_Stop => True, Accuracy => 4, Dwell => 6_000,
                Doors => 8, Skip => 4);
      Step;
      Check_Frame ("ato_nothing_known_at_stop");
      Send_ATO (Status => 6, Skip => 9, Advice_Speed => 401,
                ETA_H => 24);
      Step;
      Check_Frame ("ato_nothing_known_outside");
      Check (Without_ATO = 1, "the stand-by pictures were compared");
   end Scenario_ATO_Displays;

   -- A message that does not match its counts is ignored as a whole
   procedure Scenario_ATO_Malformed is
      Name_33 : constant String (1 .. 33) := (others => 'x');
   begin
      ATO_Reset;
      Send_ATO_Outside (Selector => 2);
      Step;
      declare
         Picture : constant String := Display.Screen.Files.Digest;
      begin
         -- a name longer than ATO_Max_Name
         Send_ATO (Status => 5, Name => Name_33);
         Step;
         Check (Display.Screen.Files.Digest = Picture,
                "a name above 32 bytes: the message is ignored");
         -- too short, too long, count beyond the payload
         Send_Raw (16#0B#, (1 .. 17 => 0));
         Send_Raw (16#0B#, (1 .. 19 => 0));
         Send_Raw (16#0B#, (2, 5, 0, 0, 0, 255, 255, 0, 0, 0, 255, 255,
                            0, 255, 0, 0, 0, 3, 1, 0));
         Step;
         Check (Display.Screen.Files.Digest = Picture,
                "wrong lengths: the messages are ignored");
      end;
      Check (DMI_ATO."=" (DMI_ATO.Status, DMI_ATO.Ready),
             "the status stays ATO02");
      -- the longest name is accepted
      Send_ATO (Status => 2, Name => Name_33 (1 .. 32));
      Step;
      Check (DMI_ATO.Name_Length = 32, "a name of 32 bytes is taken");
   end Scenario_ATO_Malformed;

   -- 8.5.2.5 / 8.5.2.6 (G1, up-type) and 8.5.8.5 (G5, delay-type): the
   -- driver's requests reach the EVC as actions 13 and 14
   procedure Scenario_ATO_Buttons is
      procedure Hold_G5 (Steps : Natural) is
      begin
         Pointer_Down (G5_X, G_Y);
         for I in 1 .. Steps loop
            Step;
         end loop;
         Pointer_Up (G5_X, G_Y);
         Step;
      end Hold_G5;
   begin
      ATO_Reset;
      Send_ATO_Outside (Selector => 2, Status => 2);
      Step;
      Drain_Outbox;

      -- ATO02: G1 is the engage button
      Pointer_Down (G1_X, G_Y);
      Step;
      Check_Frame ("ato_engage_pressed");
      Pointer_Up (G1_X, G_Y);
      Step;
      Expect_Action (13, 1, "8.5.2.5: G1 requests the start of automatic "
                     & "driving");
      Drain_Sounds;

      -- ATO03 and ATO04: G1 is the disengage button
      Send_Mode_Level (Mode => 3, Level => 4); -- AD
      Send_ATO_Outside (Selector => 2, Status => 3);
      Press (G1_X, G_Y);
      Expect_Action (13, 0, "8.5.2.6: ATO03, G1 requests the stop");
      Send_ATO_Outside (Selector => 2, Status => 4);
      Press (G1_X, G_Y);
      Expect_Action (13, 0, "8.5.2.6: ATO04, G1 requests the stop");

      -- ATO01 and ATO05: no button
      Send_ATO_Outside (Selector => 2, Status => 1);
      Press (G1_X, G_Y);
      Send_ATO_Outside (Selector => 2, Status => 5);
      Press (G1_X, G_Y);
      Expect_Actions (13, 0, "8.5.2: ATO01 and ATO05 are no buttons");

      -- 8.5.8.5: G5 with ATO17 is a delay-type button: a short press
      -- does nothing, a press of 2 s requests the skip
      Send_ATO_Outside (Selector => 2, Status => 3, Skip => 1);
      Step;
      Drain_Outbox;
      Hold_G5 (10);
      Expect_Actions (14, 0, "5.3.2.6.6: half a second is not enough");
      Hold_G5 (42);
      Expect_Action (14, 1, "8.5.8.5: ATO17, G5 requests the skip");
      -- ATO19: G5 revokes it
      Send_ATO_Outside (Selector => 2, Status => 3, Skip => 3);
      Step;
      Hold_G5 (42);
      Expect_Action (14, 0, "8.5.8.5: ATO19, G5 revokes the skip");
      Drain_Sounds;

      -- a window over the default window takes the buttons (5.3.1.1.5)
      Press (610, 240);                        -- F5: Settings
      Press (G1_X, G_Y);
      Expect_Actions (13, 0, "no ATO request under a window");
      Press (370, 440);                        -- [Close]

      -- Stand-by: no buttons
      Send_ATO_Outside (Selector => 1, Status => 2);
      Press (G1_X, G_Y);
      Hold_G5 (42);
      Expect_Actions (13, 0, "8.5.1.1: no engage button at Stand-by");
      Drain_Sounds;
   end Scenario_ATO_Buttons;

   -- 8.5.1.7: S2 while the ERTMS/ATO on-board requests the warning
   -- sound, a reason of its own beside the Warning status (14.3.3.2)
   procedure Scenario_ATO_Warning_Sound is
      procedure Speed (V : Natural; Status : Natural) is
      begin
         Send_Speed_State (V_Cur => V, V_Perm => 120, V_Target => 0,
                           V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                           D_Target => 0, Monitoring => 0, Dial_Range => 1,
                           Vrelease_Exists => False, Status => Status);
      end Speed;
   begin
      ATO_Reset;
      Speed (100, 0);
      Drain_Sounds;
      Send_ATO (Status => 3, Warning => True);
      Expect_Sound (DMI_Sounds.S2_Warning_Start,
                    "8.5.1.7: the ATO warning starts S2");
      Send_ATO (Status => 3, Warning => True);
      Expect_No_Sound ("the warning held: S2 goes on");
      -- the supervision's Warning status comes on top
      Speed (127, 3);
      Expect_No_Sound ("WaS while S2 sounds for the ATO: nothing new");
      Send_ATO (Status => 3, Warning => False);
      Expect_No_Sound ("the ATO warning ends, WaS keeps S2");
      Speed (100, 0);
      Expect_Sound (DMI_Sounds.S2_Warning_Stop, "both reasons gone: S2 stops");
      -- and the other way round
      Speed (127, 3);
      Expect_Sound (DMI_Sounds.S2_Warning_Start, "WaS starts S2");
      Send_ATO (Status => 3, Warning => True);
      Speed (100, 0);
      Expect_No_Sound ("WaS ends, the ATO warning keeps S2");
      -- the selector does not gate the sound (Choice, see Apply_ATO)
      Send_ATO (Selector => 1, Status => 0, Warning => True);
      Expect_No_Sound ("Stand-by: the requested warning still sounds");
      Send_ATO (Selector => 1, Status => 0, Warning => False);
      Expect_Sound (DMI_Sounds.S2_Warning_Stop, "the ATO warning ends");
      -- the link loss forgets the warning
      Send_ATO (Status => 3, Warning => True);
      Expect_Sound (DMI_Sounds.S2_Warning_Start, "the warning again");
      DMI_Core.Initialise;
      Expect_Sound (DMI_Sounds.S2_Warning_Stop,
                    "a reset DMI stops the ATO warning");
   end Scenario_ATO_Warning_Sound;

   -- PLN-5, 8.3.4.25 / 8.5.3.6 to 8.5.3.8: the stopping points share the
   -- column distribution of the orders
   procedure Scenario_ATO_Stopping_Points is
   begin
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 3000, Ceiling => 140,
                     Gradients => (0, 2),
                     Speeds => (1 => 3000, 2 => 0, 3 => 1),
                     Orders => (5, 300,  9, 600,  7, 700));
      Send_ATO (Selector => 1, Stops => (450, 3000, 3500));
      Step;
      Drain_Sounds;
      -- Stand-by: the orders alone in D2, D3, D4
      Check_Frame ("ato_columns_standby");
      -- On: 300 order D2, 450 stop D3, 600 order D4, 700 order D2; the
      -- stop at the end of the MA is shown (D3), the one beyond is not
      Send_ATO (Status => 1, Stops => (450, 3000, 3500));
      Step;
      Check_Frame ("ato_columns_on");
      -- 8.5.3.7: overlapping symbols, the closest one on top: two stops
      -- 20 m apart fall into adjacent columns; with three columns the
      -- fourth symbol comes back to D2 on top of the farther one
      Send_Planning (MA_Dist => 3000, Ceiling => 140,
                     Gradients => (0, 2),
                     Speeds => (1 => 3000, 2 => 0, 3 => 1));
      Send_ATO (Status => 1, Stops => (1000, 1020, 1040, 1060));
      Step;
      Check_Frame ("ato_columns_overlap");
      -- more stopping points than kept: the nearest 8
      Send_ATO (Status => 1,
                Stops => (2900, 2800, 2700, 2600, 2500, 2400, 2300, 2200,
                          100, 40_000));
      Check (DMI_Planning.Stop_Count = 8, "8 stopping points are kept");
      Check ((for some I in 1 .. DMI_Planning.Stop_Count =>
                DMI_Planning.Stops (I) = 100)
             and then (for all I in 1 .. DMI_Planning.Stop_Count =>
                         DMI_Planning.Stops (I) /= 2900),
             "the nearest ones are kept");
   end Scenario_ATO_Stopping_Points;

   -- 11.3.14: the ATO selector window, reached from the Settings window
   -- (Table 36 #7, Table 54 S8), with Table 48 closing it
   procedure Scenario_ATO_Selector_Window is
      use type DMI_Windows.Window_ID_T;

      function Value_Of return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (1);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;
   begin
      ATO_Reset;
      -- nothing reported yet: no position proposed (11.7.1.4)
      Press (610, 240);                        -- F5: Settings
      Check (DMI_Windows.Button_Enabled (7),
             "Table 36 #7: 'ATO' is enabled in FS");
      Press (410, 240);                        -- ATO
      Check (DMI_Windows.Top = DMI_Windows.W_ATO_Selector,
             "Table 54 S8: the ATO selector window");
      Check (Value_Of = "", "an unknown position proposes no value");
      Press (370, 440);                        -- [Close]

      Send_ATO (Selector => 1);
      Press (410, 240);                        -- ATO
      Check (Value_Of = "Stand-by",
             "11.7.1.4: the position the on-board holds is proposed");
      Check_Frame ("ato_selector_window");
      Key (2);
      Check (Value_Of = "On", "Table 43a: the button 2 is 'On'");
      Enter_Single;
      Expect_Action (15, 2, "the accepted position goes to the EVC");
      Check (DMI_Windows.Top = DMI_Windows.W_Settings,
             "Table 54 S8: back to S1, the Settings window");
      Check (not DMI_ATO.Displayed,
             "the position is the on-board's: shown once it reports it");
      Send_ATO (Selector => 2, Status => 2);

      -- revalidation of 'On' and the choice of 'Stand-by'
      Press (410, 240);
      Check (Value_Of = "On", "the reported position is proposed");
      Key (1);
      Enter_Single;
      Expect_Action (15, 1, "Stand-by goes to the EVC");

      -- Table 48: the window closes when the button's condition fails;
      -- Table 36 #7 does not name the mode SL
      Press (410, 240);
      Check (DMI_Windows.Top = DMI_Windows.W_ATO_Selector,
             "the window again");
      Send_Mode_Level (Mode => 16, Level => 4); -- SL
      Step;
      Check (DMI_Windows.Top = DMI_Windows.W_Settings,
             "Table 48: SL closes the ATO selector window");
      Check (not DMI_Windows.Button_Enabled (7),
             "Table 36 #7: 'ATO' disabled in SL");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_ATO_Selector_Window;

   -- The simulator's ERTMS/ATO on-board (sim/evc_ato) through the DMI,
   -- the way the browser bench runs it: the driver switches the ATO
   -- selector on, engages, the ATO stops the train at Welwyn North,
   -- disengages itself, the driver engages again, disengages and
   -- engages once more, and the ATO holds the train at Knebworth
   procedure Scenario_ATO_Mission is
      use type EVC_Mock.Mode_T;

      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

      procedure Pump_To_EVC is
         use Ada.Streams;
         use DMI_Protocol;
         Buffer : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
         Last   : Stream_Element_Offset;
         Offset : Stream_Element_Offset := Buffer'First;
      begin
         DMI_Core.Take_Outbox (Buffer, Last, With_Sounds => False);
         while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last loop
            declare
               The_Type : constant Msg_Type_T :=
                 Msg_Type_T (Get_U8 (Buffer, Offset));
               Length   : constant Stream_Element_Offset :=
                 Stream_Element_Offset (Get_U32 (Buffer, Offset));
               Next     : constant Stream_Element_Offset := Offset + Length;
            begin
               exit when Next - 1 > Last;
               if The_Type = MSG_DRIVER_ACTION
                 and then Length = Driver_Action_Length
               then
                  declare
                     Action : constant Interfaces.Unsigned_8 :=
                       Get_U8 (Buffer, Offset);
                     Arg    : constant Interfaces.Unsigned_16 :=
                       Get_U16 (Buffer, Offset);
                  begin
                     EVC_Mock.Handle_Driver_Action
                       (Natural (Action), Natural (Arg));
                  end;
               elsif The_Type = MSG_DRIVER_DATA then
                  EVC_Mock.Handle_Driver_Data (Buffer (Offset .. Next - 1));
               end if;
               Offset := Next;
            end;
         end loop;
      end Pump_To_EVC;

      procedure Sim_Step is
      begin
         EVC_Driver.Auto_Drive;
         EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
         Pump_To_EVC;
      end Sim_Step;

      procedure Touch (X, Y : Natural) is
      begin
         EVC_Driver.Auto_Drive;
         EVC_Mock.Step (0.05, Emit'Unrestricted_Access);
         Pointer_Down (X, Y);
         Pointer_Up (X, Y);
         DMI_Core.Tick (50);
         Pump_To_EVC;
         Drain_Sounds;
      end Touch;

      generic
         with function Done return Boolean;
      procedure Run_Until (What : String; Max_Steps : Natural);

      procedure Run_Until (What : String; Max_Steps : Natural) is
      begin
         for I in 1 .. Max_Steps loop
            Sim_Step;
            if Done then
               return;
            end if;
         end loop;
         Check (False, "timeout waiting for " & What);
      end Run_Until;

      function At_Stop return Boolean is (EVC_ATO.At_Stopping_Point);
      function Ready return Boolean is
        (DMI_ATO."=" (DMI_ATO.Status, DMI_ATO.Ready));
      function Beyond_3000 return Boolean is
        (EVC_Train.Position_M > 3_000.0);
      function In_FS return Boolean is (EVC_Mock.Mode = EVC_Mock.FS);

      procedure Wait_Stop is new Run_Until (At_Stop);
      procedure Wait_Ready is new Run_Until (Ready);
      procedure Wait_3000 is new Run_Until (Beyond_3000);
      procedure Wait_FS is new Run_Until (In_FS);

      function Error_At (M : Natural) return Float is
        (abs (EVC_Train.Position_M - Float (M)));
   begin
      Reset;
      EVC_Mock.Reset;
      External_EVC;
      for I in 1 .. 5 loop
         Sim_Step;
      end loop;

      -- start of mission (as Scenario_Mission)
      Touch (385, 240); Touch (487, 90);   -- Driver ID 1, Enter
      Touch (385, 240); Touch (487, 90);   -- Level 1 accepted -> Main
      Touch (410, 140);                     -- Train data (1/2)
      Touch (385, 240); Touch (589, 40);   -- train category PASS 1
      Touch (385, 290); Touch (487, 390); Touch (487, 390);
      Touch (589, 90);                     -- length 400
      Touch (385, 240); Touch (589, 240); Touch (487, 290);
      Touch (589, 140);                     -- brake percentage 135
      Touch (385, 240); Touch (385, 290); Touch (487, 390);
      Touch (589, 190);                     -- maximum speed 140
      Touch (539, 440);                     -- [Next] -> Train data (2/2)
      Touch (385, 240); Touch (589, 40);   -- axle load category A
      Touch (385, 340); Touch (589, 90);   -- airtight: No
      Touch (487, 290); Touch (589, 140);  -- loading gauge Out of GC
      Touch (167, 440);                     -- entry complete? Yes
      Touch (487, 40);                      -- validation 'Yes' -> TRN
      Touch (385, 240); Touch (487, 90);   -- TRN 1, Enter -> Main window
      Touch (410, 90);                      -- Start -> default window
      Check (EVC_Mock.Mode = EVC_Mock.FS, "the mission starts in FS");

      -- 11.3.14: the driver sets the ATO selector to "On"
      Touch (610, 240);                     -- F5: Settings
      Touch (410, 240);                     -- ATO
      Touch (Key_X (2), Key_Y (2));         -- On
      Touch (487, 90);                      -- accept
      Touch (370, 440);                     -- [Close]
      Check (EVC_ATO.Selector_On, "the EVC holds the selector 'On'");
      Wait_Ready ("ATO02", 50);
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("ato_mission_ready");

      -- 8.5.2.5: engage; SUBSET-026 [80]: AD
      Touch (G1_X, G_Y);
      Check (EVC_Mock.Mode = EVC_Mock.AD, "ATO engage: the mode is AD");
      Wait_Stop ("the stop at Welwyn North", 6_000);
      Check (Error_At (EVC_Track.Stopping_Points (1).At_M) <= 2.0,
             "the ATO stops within 2 m of Welwyn North");
      Check (EVC_Mock.Mode = EVC_Mock.FS,
             "4.4.16.3.2.1: the ATO disengages itself at the stop");
      for I in 1 .. 10 loop
         Sim_Step;                          -- the doors are open
      end loop;
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("ato_mission_at_welwyn");

      -- after the dwell time the ATO is ready again
      Wait_Ready ("ATO02 after the dwell time", 400);
      Touch (G1_X, G_Y);
      Check (EVC_Mock.Mode = EVC_Mock.AD, "engaged again");
      Wait_3000 ("leaving Welwyn North", 3_000);
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("ato_mission_engaged");

      -- 8.5.2.6: disengage; ATO04 with the ATO warning (8.5.1.7)
      Touch (G1_X, G_Y);
      Sim_Step;
      Check (DMI_ATO."=" (DMI_ATO.Status, DMI_ATO.Disengaging),
             "ATO disengage: ATO04");
      Expect_Sound (DMI_Sounds.S2_Warning_Start, "the ATO warning: S2");
      Wait_FS ("the end of the disengagement", 50);
      Sim_Step;
      Expect_Sound (DMI_Sounds.S2_Warning_Stop, "the warning ends");
      Drain_Sounds;

      -- the automatic driver follows the advice in FS; engage again
      Wait_Ready ("ATO02 in FS", 50);
      Touch (G1_X, G_Y);
      Wait_Stop ("the stop at Knebworth", 8_000);
      Check (Error_At (EVC_Track.Stopping_Points (2).At_M) <= 2.0,
             "the ATO stops within 2 m of Knebworth");
      for I in 1 .. 40 loop
         Sim_Step;                          -- 4 s of train hold
      end loop;
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("ato_mission_train_hold");
      for I in 1 .. 100 loop
         Sim_Step;                          -- the hold is over
      end loop;
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("ato_mission_dwell");
   end Scenario_ATO_Mission;

end DMI_Test_ATO;
