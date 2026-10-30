--  ETCS DMI
--  Body of DMI_Test_Windows (see dmi_test_windows.ads).

with DMI_Buttons;
with DMI_Data_Format;
with DMI_Driver_Data;
with DMI_Protocol;
with DMI_Radio_Data;
with DMI_Sounds;
with DMI_Test_Support;
with DMI_Text_Messages;
with DMI_Train_Data;
with DMI_Windows;
with General_Parameters;
with Interfaces;
with Test_Support;
use Test_Support;
use DMI_Test_Support;

package body DMI_Test_Windows is

   procedure Scenario_Startup_Sequence is
      use type DMI_Windows.Window_ID_T;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 0); -- SB, level unknown
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Drain_Outbox;

      -- Table 49 S0 -> S1: the sequence is engaged with the entry into
      -- SB, not by a button; 11.7.2.2: [Close] is disabled (NA12)
      Step;
      Check_Frame ("startup_driver_id");
      Press (370, 440);       -- [Close]: disabled
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "S1: the disabled [Close] does not close the Driver ID window");
      Press (610, 40);        -- F1 is under the window's rule (5.3.1.1.5)
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "S1: only the Driver ID window responds");

      Press (385, 240);       -- 1
      Press (487, 240);       -- 2
      Press (589, 240);       -- 3
      Step;
      Check_Frame ("startup_driver_id_123");
      Press (487, 90);        -- [Enter] -> D2 -> S2 Level window
      Step;
      Check_Frame ("startup_level");
      Press (370, 440);       -- [Close]: disabled
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Level,
             "S2: the disabled [Close] does not close the Level window");

      -- 11.3.2.4, Table 38: the button 1 is 'Level 1'; the choice has to
      -- be accepted on the input field -> S10 = S1 of the Main window
      Key (1);
      Check (DMI_Windows.Top = DMI_Windows.W_Level,
             "S2: a key of the dedicated keyboard does not leave the window");
      Step;
      Check_Frame ("startup_level_1");
      Enter_Single;
      Step;
      Check (not DMI_Windows.In_Start_Up, "S10: the Start Up sequence ended");
      Check_Frame ("main_window"); -- 'Start' disabled: data not valid
      Press (410, 90);        -- Start: disabled (Table 33)
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Main,
             "disabled Start does not react");
      Expect_Actions (5, 0, "no mission start while Start is disabled");

      -- 11.7.3.2: [Close] is enabled in the Main window sequence
      Press (370, 440);
      Check (not DMI_Windows.Is_Open, "S10: [Close] leads to the default window");
      Press (610, 40);        -- F1: Main window

      Press (410, 140);       -- Train data -> Table 50 S3-1
      Step;
      Check_Frame ("startup_train_data");

      -- Figure 120: train category, length, brake percentage and
      -- maximum speed on the first window, the rest on the second
      Key (1); Enter_Field (1);           -- train category PASS 1
      Press (385, 290); Press (487, 390); Press (487, 390);
      Enter_Field (2);        -- length 400, the data field is [Enter]
      Press (385, 240); Press (589, 240); Press (487, 290);
      Enter_Field (3);        -- brake percentage 135
      Press (385, 240); Press (385, 290); Press (487, 390);
      Step;
      Check_Frame ("startup_train_data_filled");
      Enter_Field (4);        -- maximum speed 140
      -- 10.3.5.9: 'Yes' stays disabled while the second window still
      -- has input fields without a data value (Table 50 S3-1)
      Press (167, 440);
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "the 'Yes' button waits for the items of the other window");
      Press_Next;             -- Table 23: [Next] -> Figure 121
      Step;
      Check_Frame ("startup_train_data_2");
      Key (1); Enter_Field (1);           -- axle load category A
      Key (7); Enter_Field (2);           -- airtight: No (Table 40)
      Key (5); Enter_Field (3);           -- loading gauge Out of GC
      Step;
      Check_Frame ("startup_train_data_2_filled");
      Press (167, 440);       -- 'Train data entry complete?' Yes (Table 24)
      Step;
      Check_Frame ("startup_validation");
      -- 11.7.1.6.1: nothing is stored on board before the validation
      Check (not DMI_Driver_Data.Train_Data_Entered
             and then DMI_Driver_Data.Train_Length = 0,
             "the 'Yes' of the question stores no train data");

      Press (487, 40);        -- accept the proposed 'Yes' (Table 29)
                              -- -> D6: TRN not valid -> S3-3
      Step;
      Check_Frame ("startup_trn");

      -- TRN 4711
      Press (385, 290); Press (385, 340); Press (385, 240); Press (385, 240);
      Press (487, 90);        -- [Enter] -> D1 -> S1, the Main window
      Step;
      Check_Frame ("startup_done"); -- 'Start' enabled
      Expect_Actions (5, 0, "the DMI does not start the mission by itself");

      Check (DMI_Driver_Data.Driver_ID_Entered, "driver id entered");
      Check (DMI_Driver_Data.Level_Entered, "level entered");
      Check (DMI_Driver_Data.Train_Data_Entered, "train data validated");
      Check (DMI_Driver_Data.TRN_Entered, "TRN entered");
      Check (DMI_Driver_Data.Train_Length = 400, "train length 400");
      Check (DMI_Driver_Data.Brake_Pct = 135, "brake percentage 135");
      Check (DMI_Driver_Data.Max_Speed = 140, "max speed 140");
      -- Table 40, Table 41, Table 42 and SUBSET-026 7.5.1.61 / 7.5.1.62
      Check (DMI_Train_Data.Category_CD = 0
             and then DMI_Train_Data.Category_Other = 4,
             "PASS 1 is cant deficiency 80 mm, passenger train");
      Check (DMI_Train_Data.Axle_Load_Value = 0, "axle load category A");
      Check (DMI_Train_Data.Airtight_Value = 0, "airtight: not fitted");
      Check (DMI_Train_Data.Gauge_Value = 0, "loading gauge: out of GC");

      -- Table 50 S1: 'Start' with level 1 leads to the default window and
      -- is the driver's single request
      Press (410, 90);
      Check (not DMI_Windows.Is_Open, "Start leads to the default window");
      Expect_Actions (5, 1, "Start sends one mission start request");
      Press (610, 40);        -- F1: Main window again
      Step;
      Check_Frame ("startup_start_pending"); -- 'Start' disabled
      Press (410, 90);
      Expect_Actions (5, 0, "no second request while the first is pending");

      -- the mission runs: Table 33 does not enable 'Start' in FS
      Send_Mode_Level (Mode => 2, Level => 4);
      Press (410, 90);
      Expect_Actions (5, 0, "no mission start request while the mission runs");
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Main,
             "a mode change outside SB leaves the Main window alone");

      -- end of mission: SB again. S1 proposes the stored Driver ID for
      -- revalidation (SUBSET-026 4.10.1.3), the level is still valid (D2
      -- -> D3 -> S10), train data and TRN have to be revalidated
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Check (DMI_Windows.In_Start_Up
             and then DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "SB again: Start Up engaged with the Driver ID window");
      Check_Frame ("startup_again_driver_id");
      Press (487, 90);        -- [Enter]: revalidated -> D2 -> D3 -> S10
      Check (not DMI_Windows.In_Start_Up
             and then DMI_Windows.Top = DMI_Windows.W_Main,
             "valid level: Driver ID leads to the Main window");
      Check (not DMI_Driver_Data.Train_Data_Entered
             and then not DMI_Driver_Data.TRN_Entered,
             "train data and TRN are to be revalidated");
      Press (410, 90);
      Expect_Actions (5, 0, "Start stays disabled until the data are valid");

      -- SB is left during Start Up (e.g. SL): nothing stale stays behind
      Send_Mode_Level (Mode => 3, Level => 4);
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Check (DMI_Windows.In_Start_Up, "Start Up engaged once more");
      Send_Mode_Level (Mode => 16, Level => 4); -- SL
      Step;
      Check (not DMI_Windows.In_Start_Up and then not DMI_Windows.Is_Open,
             "leaving SB ends the Start Up sequence and its windows");
      Press (610, 40);        -- F1
      Press (370, 440);       -- [Close]
      Check (not DMI_Windows.Is_Open, "[Close] is enabled again");
   end Scenario_Startup_Sequence;

   procedure Scenario_Other_Windows is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      Press (610, 90);        -- F2: Override window
      Step;
      Check_Frame ("override_window");
      Press (410, 90);        -- EOA -> closes
      Step;
      Check_Frame ("default_after_override");

      Press (610, 190);       -- F4: Special window
      Step;
      Check_Frame ("special_window");
      Press (410, 90);        -- Adhesion
      Step;
      Check_Frame ("adhesion_window");
      -- 11.3.11.4, Table 43: the button 2 is 'Slippery rail'; accepting
      -- it on the input field leaves the window (10.6.1.2 a)
      Key (2);
      Step;
      Check_Frame ("adhesion_slippery");
      Enter_Single;
      Step;
      Check_Frame ("special_window");

      Press (370, 440);       -- close Special
      Press (610, 240);       -- F5: Settings
      Step;
      Check_Frame ("settings_window");
      Press (563, 90);        -- Volume
      Step;
      Check_Frame ("volume_window");
      -- 11.3.7.4: a dedicated keyboard; here one key per level, so the
      -- key 7 is the volume 6
      Key (7);
      Step;
      Check_Frame ("volume_six");
      Enter_Single;           -- accepted -> back to the Settings window
      Check (General_Parameters."=" (General_Parameters.Loudspeaker_Volume, 6),
             "the accepted choice sets the volume");
      Press (370, 440);       -- close Settings

      Press (610, 140);       -- F3: Data view
      Step;
      Check_Frame ("data_view_window");
   end Scenario_Other_Windows;

   ---------------------------------------------------------------------
   -- EVC link supervision: silence of the EVC beyond the timeout shows
   -- mode SF with the EVC provided picture discarded; the next message
   -- restores normal operation (General_Parameters.EVC_Link_Timeout_Ms)
   ---------------------------------------------------------------------

   ---------------------------------------------------------------------
   -- Containment of internal failures (DMI_Core.Enter_Failure): nothing
   -- but the system failure symbol on a blank screen (8.2.3.1.2.1), deaf
   -- to messages and time until the DMI is restarted
   ---------------------------------------------------------------------

   procedure Scenario_Data_View is
      use DMI_Data_Format;
      use type DMI_Windows.Window_ID_T;

      procedure Set (Value : out DMI_Driver_Data.Text_Value_T;
                     Text  : Wide_String) is
      begin
         Value.Length := Text'Length;
         Value.Text (1 .. Text'Length) := Text;
      end Set;

      procedure Check_Grouped (Data : Wide_String;
                               Line : Positive;
                               Text : Wide_String;
                               What : String) is
         Blocks : constant Grouped_T := Grouped (Data);
      begin
         Check (Blocks.Count >= Line
                and then Blocks.Lines (Line).Text
                           (1 .. Blocks.Lines (Line).Length) = Text,
                What);
      end Check_Grouped;
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS, L1
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      -- 10.5.1.4: nothing is valid yet, every label stands without data
      Press (610, 140);       -- F3: Data view
      Check_Frame ("data_view_p1_no_data");

      -- 5.3.2.7.5: [Previous] is disabled on the first window and does
      -- not react to the driver
      Press (457, 440);
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Data_View,
             "[Previous] on the first data view window does nothing");
      Check_Frame ("data_view_p1_no_data");

      Set (DMI_Driver_Data.Driver_ID, "12345678");
      DMI_Driver_Data.Driver_ID_Entered := True;
      Set (DMI_Driver_Data.TRN, "5678");
      DMI_Driver_Data.TRN_Entered := True;
      DMI_Driver_Data.Train_Length := 200;
      DMI_Driver_Data.Brake_Pct := 135;
      DMI_Driver_Data.Max_Speed := 160;
      -- Table 45 items 4, 8, 9 and 10: the choices of Tables 41, 42 and
      -- of SUBSET-026 7.5.1.61 / 7.5.1.62 (audit WIN-8)
      DMI_Driver_Data.Train_Category := 1;    -- Table 41: PASS 1
      DMI_Driver_Data.Axle_Load := 1;         -- 7.5.1.62: A
      DMI_Driver_Data.Airtight := 2;          -- Table 40: Yes
      DMI_Driver_Data.Loading_Gauge := 4;     -- Table 42: GC
      DMI_Driver_Data.Train_Data_Entered := True;
      Step;
      Check_Frame ("data_view_p1");

      Check_Grouped ("12345678", 1, "1234 5678",
                     "5.1.5.1: 8 characters are shown as two groups");
      Check_Grouped ("123456", 1, "123 456",
                     "5.1.5.1: 6 characters are split as well");
      Check_Grouped ("12345", 1, "12345",
                     "5.1.5.1: 5 characters stay in one group");
      Check_Grouped ("123456789012", 1, "1234 5678",
                     "5.1.5.2: the first line holds 8 characters");
      Check_Grouped ("123456789012", 2, "9012",
                     "5.1.5.2: the rest follows on the next line");
      Check (Grouped ("").Count = 0, "an empty value has no text line");

      -- Table 45: the second window carries the topic "Radio data info"
      Press (539, 440);       -- [Next]
      Check_Frame ("data_view_p2");
      Press (539, 440);       -- 5.3.2.7.5: [Next] is disabled at the end
      Check_Frame ("data_view_p2");
      Press (457, 440);       -- [Previous]
      Check_Frame ("data_view_p1");

      -- reopening the window starts at its first window again
      Press (539, 440);       -- [Next]
      Press (370, 440);       -- [Close]
      Press (610, 140);       -- F3
      Check_Frame ("data_view_p1");

      -- SUBSET-026 3.18.6.1: the Driver ID and the train running number
      -- stored on-board (MSG_STORED_VALUES) replace the DMI's own
      -- entries: their texts emptied (the status stays valid, as this
      -- test's EVC reports it from the entered flags), the same window
      -- from the on-board's values
      DMI_Driver_Data.Driver_ID := (others => <>);
      DMI_Driver_Data.TRN := (others => <>);
      Send_Raw (16#11#, (1 => 8, 2 => 49, 3 => 50, 4 => 51, 5 => 52,
                         6 => 53, 7 => 54, 8 => 55, 9 => 56, 10 .. 17 => 0,
                         18 => 4, 19 => 53, 20 => 54, 21 => 55, 22 => 56,
                         23 .. 34 => 0));
      Step;
      Check (DMI_Driver_Data.Onboard_Values_Known,
             "3.18.6.1: MSG_STORED_VALUES taken");
      Check_Frame ("data_view_p1");
      Send_Raw (16#11#, (1 => 17, 2 .. 34 => 0));
      Check (DMI_Driver_Data.Onboard_Driver_ID.Length = 8,
             "MSG_STORED_VALUES with a length above 16 is dropped");
      -- the long form: the Train Data in the codes of the entry and the
      -- GSM-R network ID; a train_valid above 1 drops the message
      Send_Raw (16#11#, (1 => 8, 2 .. 34 => 0, 35 => 2, 36 .. 65 => 0));
      Check (not DMI_Driver_Data.Onboard_Long_Known,
             "MSG_STORED_VALUES with train_valid 2 is dropped");
      Send_Raw (16#11#, (1 => 8, 2 => 49, 3 => 50, 4 => 51, 5 => 52,
                         6 => 53, 7 => 54, 8 => 55, 9 => 56, 10 .. 17 => 0,
                         18 => 4, 19 => 53, 20 => 54, 21 => 55, 22 => 56,
                         23 .. 34 => 0,
                         35 => 1, 36 => 200, 37 => 0, 38 => 135, 39 => 0,
                         40 => 160, 41 => 0, 42 => 2, 43 => 4, 44 => 0,
                         45 => 0, 46 => 1, 47 => 1,
                         48 => 6, 49 => 49, 50 => 50, 51 => 51, 52 => 52,
                         53 => 53, 54 => 54, 55 .. 65 => 0));
      Check (DMI_Driver_Data.Onboard_Long_Known
             and then DMI_Driver_Data.Onboard_Train_Valid
             and then DMI_Driver_Data.Onboard_Length = 200
             and then DMI_Driver_Data.Onboard_Brake_Pct = 135
             and then DMI_Driver_Data.Onboard_Max_Speed = 160
             and then DMI_Driver_Data.Onboard_Category > 0
             and then DMI_Driver_Data.Onboard_Axle_Load > 0
             and then DMI_Driver_Data.Onboard_Airtight > 0
             and then DMI_Driver_Data.Onboard_Gauge > 0
             and then DMI_Driver_Data.Onboard_Network.Length = 6,
             "3.18.6.1: MSG_STORED_VALUES long form, the Train Data and "
             & "the network taken");
      Check (DMI_Train_Data.Onboard_Text (DMI_Train_Data.I_Category).Length
               > 0
             and then DMI_Train_Data.Onboard_Text
                        (DMI_Train_Data.I_Airtight).Length > 0,
             "3.18.6.1: the on-board's codes shown as the labels of the "
             & "entry");
   end Scenario_Data_View;

   -- 3.18.6.1, Table 45 items 13, 14: the RBC contact stored on-board is
   -- shown whatever the driver chose last in the Radio data window; after
   -- 'Contact last RBC' the on-board keeps the contact it last sent
   -- (MSG_RBC_CONTACT) and sends nothing new
   procedure Scenario_Data_View_RBC_Contact is
      use type DMI_Windows.Window_ID_T;
      use type DMI_Radio_Data.RBC_Choice_T;
      use type Interfaces.Unsigned_8;
   begin
      Reset;
      Win_Onboard (Data => Win_Data_All or 16#10#, Radio => Win_Radio_GSMR);
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Win_At_Standstill;
      -- the contact stored on-board: RBC ID 82220, phone 0077
      Send_Raw (16#10#, (1, 16#2C#, 16#41#, 16#01#, 0, 4,
                         48, 48, 55, 55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
      Win_Open_Main;
      Win_Menu (10);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "3.18.6.1: the Radio data window opened");
      Win_Menu (1);                             -- 'Contact last RBC'
      Check (DMI_Radio_Data.Last_Choice = DMI_Radio_Data.Contact_Last_RBC,
             "3.18.6.1: the driver chose 'Contact last RBC'");
      Check (DMI_Windows.Top /= DMI_Windows.W_Radio_Data,
             "3.18.6.1: the Radio data window left");
      Win_Default;
      Press (610, 140);                         -- F3: Data view
      Press_Next;
      Check (DMI_Windows.Top = DMI_Windows.W_Data_View,
             "3.18.6.1: the Data view opened");
      Step;
      Check_Frame ("data_view_p2_last_rbc");
   end Scenario_Data_View_RBC_Contact;

   ---------------------------------------------------------------------
   -- DMI 5.3.2.6.4 and 5.3.2.6.5 (audit finding GEN-4). E11, the [Down]
   -- button of the text message list, is a down-type button with a
   -- repeat function (5.3.2.7.2): it goes to "pressed" and immediately
   -- back to "enabled", and after 1.5 s of holding it activates every
   -- 0.3 s "as if the driver was pressing on the button", click and
   -- press included. A Step is one 50 ms tick followed by one screen.
   procedure Scenario_Button_Down_Type is
      package TM renames DMI_Text_Messages;
      use type DMI_Buttons.Button_ID_T;

      E11_X : constant := 310; -- inside E11, as Scenario_Text_Wrap taps it
      E11_Y : constant := 440;

      function Number (N : Natural) return Wide_String is
         Img : constant Wide_String := Natural'Wide_Image (N);
      begin
         return Img (2 .. Img'Last);
      end Number;

      function Top return Wide_String is
         Line  : TM.Line_T;
         Valid : Boolean;
      begin
         TM.Get_Visible_Line (1, Line, Valid);
         return (if Valid then Line.Text (1 .. Line.Length) else "<none>");
      end Top;

      function Down_Pressed return Boolean is
        (DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_Msg_Down));
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      -- twelve one-line messages: seven scroll positions, enough for the
      -- press and several repeats
      for I in 1 .. 12 loop
         Send_Text (ID => I, Text => "Msg " & Number (I));
      end loop;
      Drain_Sounds;
      Step;
      Check (Top = "Msg 12" and then TM.Can_Scroll_Down,
             "the message list starts at its newest line");

      -- 5.3.2.6.4: click and activation on the press
      Pointer_Down (E11_X, E11_Y);
      Expect_Sound (DMI_Sounds.Click,
                    "a down-type button plays the click on the press");
      Step;
      Check (Top = "Msg 11",
             "a down-type button activates with the press (5.3.2.6.4)");
      Check (Down_Pressed,
             "and is shown pressed on the screen that follows it");
      Step;
      Check (not Down_Pressed,
             "and back in the enabled state although the finger stays on "
             & "it (5.3.2.6.4)");
      Check (Top = "Msg 11", "holding it does not activate it again");

      -- 5.3.2.6.5: the first repeat 0.3 s after the 1.5 s delay
      Drain_Sounds;
      for I in 3 .. 35 loop -- up to 1.75 s of holding
         Step;
      end loop;
      Check (Top = "Msg 11",
             "nothing repeats within the first 1.5 s + 0.3 s (5.3.2.6.5)");
      Expect_No_Sound ("and no click is played before the first repeat");
      Step; -- 1.80 s
      Check (Top = "Msg 10",
             "the repeat activates 0.3 s after the 1.5 s delay (5.3.2.6.5)");
      Check (Down_Pressed, "a repeat shows the press (5.3.2.6.5)");
      Expect_Sound (DMI_Sounds.Click,
                    "a repeat plays the click like a press (5.3.2.6.5)");
      Step;
      Check (not Down_Pressed, "and lets the button go again");
      Expect_No_Sound ("no click between two repeats");

      -- and every 0.3 s from there
      for I in 2 .. 5 loop
         Step;
      end loop;
      Check (Top = "Msg 10", "the repeats are 0.3 s apart");
      Step; -- 2.10 s
      Check (Top = "Msg 9" and then Down_Pressed,
             "the next repeat follows 0.3 s later (5.3.2.6.5)");
      Expect_Sound (DMI_Sounds.Click, "with its own click");

      -- the release ends the repeat and counts no further activation
      Pointer_Up (E11_X, E11_Y);
      Drain_Sounds;
      for I in 1 .. 20 loop
         Step;
      end loop;
      Check (Top = "Msg 9", "the release ends the repeat (5.3.2.6.4)");
      Check (not Down_Pressed, "and leaves the button enabled");
      Expect_No_Sound ("no click after the release");
      Drain_Sounds;
   end Scenario_Button_Down_Type;

   -- DMI 5.3.2.6.2: the contrast to the above. An up-type button stays
   -- in the pressed state as long as the driver keeps it pressed and is
   -- activated on the release. F1 of the default window is one (8.6.1).
   procedure Scenario_Button_Up_Type is
      use type DMI_Windows.Window_ID_T;
      F1_X : constant := 610;
      F1_Y : constant := 40;
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS, no Start Up sequence
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Step;

      Pointer_Down (F1_X, F1_Y);
      Expect_Sound (DMI_Sounds.Click,
                    "an up-type button plays the click on the press");
      Step;
      Check (DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_F1),
             "an up-type button is pressed while the driver holds it "
             & "(5.3.2.6.2)");
      for I in 1 .. 40 loop -- 2 s, past every down-type timer
         Step;
      end loop;
      Check (DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_F1),
             "and stays pressed however long it is held");
      Check (not DMI_Windows.Is_Open,
             "it is not activated before the release (5.3.2.6.2)");
      Expect_No_Sound ("an up-type button does not repeat");

      Pointer_Up (F1_X, F1_Y);
      Step;
      Check (not DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_F1),
             "the release exits the pressed state (5.3.2.6.2)");
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Main,
             "and counts the activation");
      Drain_Sounds;
   end Scenario_Button_Up_Type;

   ---------------------------------------------------------------------
   -- WIN-2: the enabling conditions of Tables 33 to 36 (11.2.1.4,
   -- 11.2.2.4, 11.2.3.4, 11.2.4.4) and Table 48 (11.7.1.7). The on-board
   -- state comes on the wire (MSG_ONBOARD); the DMI evaluates the rows.
   ---------------------------------------------------------------------

   procedure Scenario_Enabling_Conditions is
      use type Interfaces.Unsigned_8;
      subtype U8 is Interfaces.Unsigned_8;

      --  MSG_ONBOARD bytes, see dmi_protocol.ads
      Data_All    : constant U8 := 16#0F#; -- id, train data, level, TRN valid
      Data_No_TRN : constant U8 := 16#07#;
      Standing    : constant U8 := 16#03#; -- standstill, override speed ok
      Running     : constant U8 := 16#02#; -- moving, still below the limit
      NV_Adh      : constant U8 := 16#02#; -- adhesion may be modified
      Ovr_OK      : constant U8 := 16#10#; -- the override is selectable

      procedure Onboard (Data     : U8 := Data_All;
                         Session  : U8 := 0;
                         RBC      : U8 := 0;
                         Train    : U8 := Standing;
                         National : U8 := NV_Adh;
                         Pending  : U8 := 0) is
      begin
         Send_Onboard_Raw (Data, Session, RBC, Train, National, 0, 0, Pending);
         Step;
      end Onboard;

      function Enabled (Index : Positive) return Boolean is
        (DMI_Windows.Button_Enabled (Index));

      function Top_Is (ID : DMI_Windows.Window_ID_T) return Boolean is
        (DMI_Windows.Is_Open
         and then DMI_Windows."=" (DMI_Windows.Top, ID));

      procedure Open_Window (X, Y : Natural) is
      begin
         while DMI_Windows.Is_Open loop
            Press (370, 440);
         end loop;
         Press (X, Y);
      end Open_Window;

      F1_Main     : constant := 40;
      F2_Override : constant := 90;
      F4_Special  : constant := 190;
      F5_Settings : constant := 240;
   begin
      Reset;
      --  the scenario owns MSG_ONBOARD from here on; no start of mission
      Onboard;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Open_Window (610, F1_Main);
      Check (Top_Is (DMI_Windows.W_Main), "the Main window is on display");

      -- Table 33 #1 Start, first row: SB, all data valid, level 1
      Check (Enabled (1), "Table 33 #1: Start in SB with valid data, level 1");
      Onboard (Pending => 1);
      Check (not Enabled (1), "Table 33 #1: no Start while one is pending");
      Onboard (Train => Running);
      Check (not Enabled (1), "Table 33 #1: no Start while the train runs");
      Onboard (Data => Data_No_TRN);
      Check (not Enabled (1),
             "Table 33 #1: no Start without a valid running number");

      -- Table 33 #1 with level 2: with a session the train data have to
      -- be acknowledged by the RBC, without one they do not
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Onboard (Session => 2);
      Check (not Enabled (1),
             "Table 33 #1: level 2 with a session needs the RBC's ack");
      Onboard (Session => 2, RBC => 1);
      Check (Enabled (1), "Table 33 #1: level 2, session, train data acked");
      Onboard (Session => 0);
      Check (Enabled (1), "Table 33 #1: level 2 without a session");
      Onboard (Session => 1);
      Check (not Enabled (1),
             "Table 33 #1: a session being established is neither");
      Send_Mode_Level (Mode => 1, Level => 4); -- back to level 1
      Onboard;

      -- Table 33 #2 Driver ID, #3 Train data, #5 Level, #6 TRN in SB
      Check (Enabled (2) and then Enabled (3) and then Enabled (5)
             and then Enabled (6),
             "Table 33 #2, #3, #5, #6: enabled in SB at standstill");
      Onboard (Data => 0);
      Check (not Enabled (2) and then not Enabled (3) and then not Enabled (5)
             and then not Enabled (6),
             "Table 33 #2, #3, #5, #6: nothing without a valid Driver ID");

      -- Table 33 #3: a safe consist length that is not zero in front of
      -- the engine takes the Train data button away
      Onboard (Data => Data_All or 16#40#);
      Check (not Enabled (3),
             "Table 33 #3: no Train data with a safe consist length ahead");
      Onboard (Data => Data_All or 16#C0#);
      Check (Enabled (3),
             "Table 33 #3: Train data when that length is zero");

      -- Table 33 #7 Shunting: level 1 at standstill; #8 Non-Leading
      -- needs the "non leading" input signal
      Onboard;
      Check (Enabled (7), "Table 33 #7: Shunting in SB with level 1");
      Check (not Enabled (8),
             "Table 33 #8: no Non-Leading without the input signal");
      Onboard (Train => Standing or 16#04#);
      Check (Enabled (8), "Table 33 #8: Non-Leading with the input signal");

      -- Table 33 #2 while running: only with the national value
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Onboard (Train => Running);
      Check (not Enabled (2),
             "Table 33 #2: no Driver ID while running by default");
      Onboard (Train => Running, National => NV_Adh or 1);
      Check (Enabled (2),
             "Table 33 #2: Driver ID while running when the NV allows it");
      Check (not Enabled (1), "Table 33 #1: no Start in FS");

      -- Table 34 #1 EOA (Override window): the on-board's word, national
      -- bit 4 (SUBSET-026 5.8.2.1, 5.4.5.3 a)), whatever the other bytes
      Onboard (National => NV_Adh or Ovr_OK);
      Open_Window (610, F2_Override);
      Check (Top_Is (DMI_Windows.W_Override), "the Override window is open");
      Check (Enabled (1), "Table 34 #1: EOA in FS, the on-board takes it");
      Onboard;
      Check (not Enabled (1),
             "Table 34 #1: no EOA in FS where the on-board refuses it");
      Onboard (Train => 0, National => NV_Adh or Ovr_OK);
      Check (Enabled (1),
             "Table 34 #1: the speed is the on-board's term of the bit");
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Onboard;
      Check (not Enabled (1),
             "Table 34 #1: no EOA in SB, level 2, the data valid, refused");
      Onboard (National => NV_Adh or Ovr_OK);
      Check (Enabled (1), "Table 34 #1: EOA in SB with level 2, taken");
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Onboard;

      -- Table 35 (Special window)
      Send_Mode_Level (Mode => 7, Level => 4); -- SR, level 1
      Onboard;
      Open_Window (610, F4_Special);
      Check (Top_Is (DMI_Windows.W_Special), "the Special window is open");
      Check (Enabled (2), "Table 35 #2: SR speed / distance in SR");
      Check (not Enabled (3),
             "Table 35 #3: no Train integrity without an RBC session");
      Onboard (Session => 2, RBC => 16#09#, Data => Data_All or 16#20#);
      Check (Enabled (3),
             "Table 35 #3: Train integrity with the RBC's ack and the length");
      -- B015, SUBSET-026 4.4.11.1.5.1: the on-board watches the SR speed /
      -- distance entry from the window opened (action 23) to the window
      -- left without the data (action 24)
      Drain_Outbox;
      Win_Menu (2);
      Check (Top_Is (DMI_Windows.W_SR_Data), "the SR speed / distance window");
      Expect_Action (23, 0, "Table 35 #2: the SR entry requested (action 23)");
      Win_Close;
      Expect_Action (24, 0, "[Close]: the SR entry left (action 24)");
      Check (Top_Is (DMI_Windows.W_Special), "back to the Special window");
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Onboard;
      Check (not Enabled (2), "Table 35 #2: no SR speed / distance outside SR");
      Check (Enabled (1), "Table 35 #1: Adhesion in FS when the NV allows it");
      Onboard (National => 0);
      Check (not Enabled (1),
             "Table 35 #1: no Adhesion when the NV forbids it");

      -- Table 36 (Settings window)
      Send_Mode_Level (Mode => 1, Level => 4); -- SB
      Onboard;
      Open_Window (610, F5_Settings);
      Check (Top_Is (DMI_Windows.W_Settings), "the Settings window is open");
      Check (Enabled (2) and then Enabled (3),
             "Table 36 #2, #3: Volume and Brightness in SB at standstill");
      Onboard (Train => Running);
      Check (not Enabled (2) and then not Enabled (3),
             "Table 36 #2, #3: nothing in SB while the train runs");
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Onboard (Train => Running);
      Check (Enabled (2) and then Enabled (3),
             "Table 36 #2, #3: enabled in FS whatever the speed");

      -- 11.7.1.7 and Table 48: an open data entry window whose button
      -- loses its enabling conditions gives way to the parent window
      Send_Mode_Level (Mode => 1, Level => 4); -- SB
      Onboard;
      Open_Window (610, F1_Main);
      Press (563, 190);                        -- Train run. nr
      Check (Top_Is (DMI_Windows.W_TRN), "the Train running number window");
      Onboard (Data => 0);                     -- the Driver ID is invalid now
      Check (Top_Is (DMI_Windows.W_Main),
             "Table 48: the TRN window gives way to the Main window");

      Onboard;
      Press (410, 140);                        -- Train data
      Check (Top_Is (DMI_Windows.W_Train_Data), "the Train data window");
      Enter_Train_Data (Length => 400, Brake => 135, Speed => 140);
      Press (167, 440);                        -- entry complete? Yes
      Check (Top_Is (DMI_Windows.W_Train_Data_Validation),
             "the train data validation window");
      Onboard (Train => Running);              -- the train starts moving
      Check (Top_Is (DMI_Windows.W_Main),
             "Table 48: the validation gives way to the Main window");
      Expect_Action (22, 0, "B220, 11.7.1.7: the entry stopped is reported "
                     & "as left (action 22)");
      -- B220, SUBSET-026 3.18.3.3.1: [Close] of the Train data window
      Onboard;
      Press (410, 140);                        -- Train data
      Win_Close;
      Check (Top_Is (DMI_Windows.W_Main), "[Close]: back to the Main window");
      Expect_Action (22, 0, "B220: the Train data window left without the "
                     & "data (action 22)");
      Drain_Outbox;
   end Scenario_Enabling_Conditions;

   ---------------------------------------------------------------------
   -- The EOA button of the Override window over the start of mission in
   -- level 2 (SUBSET-026 5.4.5.3 a), 5.8.2.1; DMI 11.2.2.4 Table 34 #1):
   -- the data of the row are valid at S11, S10 and S21 alike, the
   -- on-board takes the override at S10 only and says so in national
   -- bit 4, so the button is enabled at S10 and disabled at S11 (the
   -- Train Data acknowledgement awaited) and at S21 (after Start)
   ---------------------------------------------------------------------

   procedure Scenario_Override_Selectable is
      use type Interfaces.Unsigned_8;
      subtype U8 is Interfaces.Unsigned_8;
      Data_All : constant U8 := 16#0F#; -- id, train data, level, TRN valid
      Standing : constant U8 := 16#03#; -- standstill, override speed ok
      NV_Adh   : constant U8 := 16#02#; -- adhesion may be modified
      Ovr_OK   : constant U8 := 16#10#; -- the override is selectable

      function EOA_Enabled return Boolean is
        (DMI_Windows.Is_Open
         and then DMI_Windows."=" (DMI_Windows.Top, DMI_Windows.W_Override)
         and then DMI_Windows.Button_Enabled (1));
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      --  S11: the session open, the Train Data sent, not acknowledged
      Send_Onboard_Raw (Data_All, 2, 0, Standing, NV_Adh, 0, 0, 0);
      Step;
      Drain_Sounds;
      Press (610, 90);                          -- F2: Override window
      Step;
      Check (DMI_Windows.Is_Open
             and then DMI_Windows."=" (DMI_Windows.Top,
                                       DMI_Windows.W_Override),
             "S11: the Override window is open");
      Check (not EOA_Enabled,
             "5.4.5.3 a): no EOA at S11, the on-board refuses it");
      Check_Frame ("override_eoa_s11");
      --  S10: the Train Data acknowledged, the on-board takes it
      Send_Onboard_Raw (Data_All, 2, 1, Standing, NV_Adh or Ovr_OK, 0, 0, 0);
      Step;
      Check (EOA_Enabled, "5.4.5.3 a): EOA at S10, the on-board takes it");
      Check_Frame ("override_eoa_s10");
      --  S21: 'Start' selected, the MA requested and awaited (MSG_ONBOARD
      --  waiting 3): DMI_Windows.Onboard_State_Changed closes the Override
      --  window and shows the Main window with every button disabled and
      --  the hour glass (Table 50 S7, its [close] disabled by 11.7.3.2),
      --  so the driver cannot reach the EOA button at all
      Send_Onboard_Raw (Data_All, 2, 1, Standing, NV_Adh, 0, 3, 0);
      Step;
      Check (DMI_Windows.Is_Open
             and then DMI_Windows."=" (DMI_Windows.Top, DMI_Windows.W_Main),
             "S21: the Main window of Table 50 S7 replaces the Override "
             & "window");
      Press (610, 90);                          -- F2 again
      Step;
      Press (370, 440);                         -- [close] of the window
      Step;
      Press (610, 90);                          -- and F2 once more
      Step;
      Check (DMI_Windows.Is_Open
             and then DMI_Windows."=" (DMI_Windows.Top, DMI_Windows.W_Main)
             and then not EOA_Enabled,
             "5.4.5.3 a): at S21 F2 does not open the Override window, the "
             & "Main window of Table 50 S7 stays ([close] disabled, "
             & "11.7.3.2)");
      Check_Frame ("override_s21_main_waiting");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Override_Selectable;

   ---------------------------------------------------------------------
   -- WIN-11: the hour glass ST05 and the Main window with all buttons
   -- disabled while the on-board awaits an answer (11.2.1.6, Table 49
   -- S0/S4/A31, Table 50 S7/S8/S9)
   ---------------------------------------------------------------------

   procedure Scenario_Waiting_Window is
      subtype U8 is Interfaces.Unsigned_8;
      Data_All : constant U8 := 16#0F#;
      Standing : constant U8 := 16#03#;

      procedure Onboard (SOM, Waiting : U8) is
      begin
         Send_Onboard_Raw (Data_All, 0, 0, Standing, 0, SOM, Waiting, 0);
         Step;
      end Onboard;

      function Top_Is (ID : DMI_Windows.Window_ID_T) return Boolean is
        (DMI_Windows.Is_Open
         and then DMI_Windows."=" (DMI_Windows.Top, ID));
   begin
      Reset;
      Onboard (SOM => 0, Waiting => 0);
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      -- Table 49 S0: the mode is SB but a communication session is still
      -- up; the Main window comes with all buttons disabled and ST05
      Onboard (SOM => 1, Waiting => 0);
      Check (Top_Is (DMI_Windows.W_Main)
             and then DMI_Windows.Waiting_Displayed,
             "S0: the Main window is presented while the session ends");
      for I in 1 .. DMI_Windows.Button_Count loop
         Check (not DMI_Windows.Button_Enabled (I),
                "S0: Main window button" & Natural'Image (I) & " disabled");
      end loop;
      Check (not DMI_Windows.Close_Enabled, "S0: [Close] is disabled");
      Press (370, 440);
      Check (Top_Is (DMI_Windows.W_Main), "S0: [Close] does not close");
      Step;
      Check_Frame ("waiting_main_st05");

      -- 11.2.1.6: 26 cells to the right every second
      for I in 1 .. 20 loop      -- 1 s of 50 ms ticks
         Step;
      end loop;
      Check_Frame ("waiting_main_st05_moved");

      -- S0 -> S1: the conditions are fulfilled, Start Up is engaged
      Onboard (SOM => 2, Waiting => 0);
      Check (DMI_Windows.In_Start_Up
             and then Top_Is (DMI_Windows.W_Driver_ID),
             "S0 -> S1: Start Up engages with the Driver ID window");
      Check (not DMI_Windows.Waiting_Displayed, "S1: no hour glass");

      -- Table 50 S9: the on-board awaits an answer from the RBC; when it
      -- comes the Main window stays (S1)
      Onboard (SOM => 2, Waiting => 2);
      Check (Top_Is (DMI_Windows.W_Main)
             and then DMI_Windows.Waiting_Displayed,
             "S9: the Main window with all buttons disabled");
      Check (not DMI_Windows.Button_Enabled (1), "S9: Start is disabled too");
      Onboard (SOM => 2, Waiting => 0);
      Check (Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.Waiting_Displayed,
             "S9 -> S1: the Main window stays, without the hour glass");
      Check (DMI_Windows.Close_Enabled, "S1: [Close] is enabled again");

      -- Table 50 S7: after 'Start' with level 2 the MA is awaited; when
      -- it arrives the default window is shown
      Onboard (SOM => 0, Waiting => 3);
      Check (Top_Is (DMI_Windows.W_Main)
             and then DMI_Windows.Waiting_Displayed,
             "S7: the Main window with all buttons disabled");
      Onboard (SOM => 0, Waiting => 0);
      Check (not DMI_Windows.Is_Open,
             "S7: the MA leads back to the default window");

      -- an undocumented waiting code still means "an answer is awaited"
      Onboard (SOM => 0, Waiting => 200);
      Check (Top_Is (DMI_Windows.W_Main)
             and then DMI_Windows.Waiting_Displayed,
             "an unknown waiting code is read as an awaited RBC answer");
      Onboard (SOM => 0, Waiting => 0);
      Drain_Outbox;
      Drain_Sounds;
   end Scenario_Waiting_Window;

   --  The wait for the FRMCS registration that the Radio network type
   --  entry begins (Table 49 S3-4 E5, the hour glass of the Main window:
   --  MSG_ONBOARD waiting 1), and its end: A41 -> D10, back to S3-1 the
   --  Radio data window when the stored type is FRMCS+GSM-R with both
   --  radio systems installed, S10 the Main window otherwise; a
   --  registration in time ends the wait in S3-1 as E6 does
   procedure Scenario_Network_Type_Wait is
      use type Interfaces.Unsigned_8;
      --  the Driver ID is valid once entered, the level is not
      Data_ID : constant Win_U8 := 16#01#;
      --  FRMCS not registered, a GSM-R Mobile Terminal registered
      Both_GSMR  : constant Win_U8 := Win_GSMR or Win_Both or Win_GSMR_Reg;
      Both_Mixed : constant Win_U8 :=
        Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg;
      Only_FRMCS : constant Win_U8 := Win_FRMCS_GSMR or Win_Only_FRMCS;

      procedure Radio (R : Win_U8; Waiting : Win_U8 := 0;
                       Data : Win_U8 := Data_ID or 16#04#) is
      begin
         Win_Onboard (Data => Data, SOM => 2, Radio => R,
                      Waiting => Waiting,
                      Train => Win_Standing or Win_Position);
      end Radio;

      --  S0 -> S1 -> S2 -> S3-1 with the radio byte R, then S3-4: the
      --  driver enters FRMCS+GSM-R
      procedure Enter_Type (R : Win_U8) is
      begin
         Reset;
         Win_At_Standstill;
         Win_Onboard (Data => 0, SOM => 0, Radio => R);
         Send_Mode_Level (Mode => 1, Level => 0); -- SB, level unknown
         Win_Onboard (Data => 0, SOM => 2, Radio => R);
         Press (385, 240); Press (487, 90);    -- Driver ID 1
         Radio (R, Data => Data_ID);
         Choose_Level (2);
         Send_Mode_Level (Mode => 1, Level => 5);
         Radio (R);
         Win_Menu (5);
         Key (2);                                  -- FRMCS+GSM-R
         Enter_Single;
      end Enter_Type;
   begin
      -- both systems installed: D10 is S3-1, taken at the entry
      Enter_Type (Both_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "Table 49 S3-4 E5 (both systems): the Radio data window");
      Radio (Both_Mixed, Waiting => 1);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then DMI_Windows.Waiting_Displayed,
             "the FRMCS registration awaited: the Main window with all "
             & "buttons disabled and ST05 (11.2.1.6)");
      Step;
      Check_Frame ("network_type_wait_main");
      -- A41: the text message is the EVC's; the wait ends
      Send_System_Status (DMI_Protocol.SS_FRMCS_Registration_Failed, 0);
      Radio (Both_Mixed, Waiting => 0);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up
             and then not DMI_Windows.Waiting_Displayed,
             "Table 49 A41 -> D10: FRMCS+GSM-R stored, both systems "
             & "installed -> S3-1, the Radio data window");
      Check (not DMI_Windows.Close_Enabled,
             "11.7.2.2: [Close] is disabled in S3-1 again");
      Step;
      Check_Frame ("network_type_wait_radio_data");

      -- the FRMCS registration in time: no A41, back to S3-1 (E6)
      Enter_Type (Both_GSMR);
      Radio (Both_Mixed, Waiting => 1);
      Radio (Both_Mixed or Win_FRMCS_Reg, Waiting => 0);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "Table 49 S3-4: the FRMCS registration in time -> S3-1");

      -- FRMCS alone: D10 is S10, taken at the entry; the wait over the
      -- Main window ends in it
      Enter_Type (Only_FRMCS);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S3-4 E5 (FRMCS alone): D10 -> S10 at the entry");
      Radio (Only_FRMCS, Waiting => 1);
      Radio (Only_FRMCS, Waiting => 0);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.Waiting_Displayed,
             "Table 49 A41 -> D10 (FRMCS alone) -> S10: the Main window "
             & "stays");
      Drain_Outbox;
      Drain_Sounds;
   end Scenario_Network_Type_Wait;

   ---------------------------------------------------------------------
   -- Input field mechanics of a data entry window (audit WIN-4:
   -- 10.3.1.19, 10.3.1.20, 10.3.1.22, 10.3.1.25, 10.3.1.26, 10.3.2.1 to
   -- 10.3.2.3, 10.3.5.13, 10.3.5.15)
   ---------------------------------------------------------------------


end DMI_Test_Windows;
