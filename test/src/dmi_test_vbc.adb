--  ETCS DMI
--  Body of DMI_Test_VBC (see dmi_test_vbc.ads).

with Ada.Streams;
with DMI_Core;
with DMI_Data_View;
with DMI_Driver_Data;
with DMI_Protocol;
with DMI_Radio_Data;
with DMI_System_Version;
with DMI_Test_Support;
with DMI_VBC;
with DMI_Windows;
with EVC_Mock;
with Interfaces;
with Supplementary_Driving_Info;
with Test_Support;
use Test_Support;
use DMI_Test_Support;
use type DMI_Test_Support.Win_U8;

package body DMI_Test_VBC is

   procedure VBC_Settings is
   begin
      Win_Default;
      Press (610, 240);                         -- F5: Settings
   end VBC_Settings;

   --  Table 29 / Table 25: 'No' is key 7, 'Yes' key 8; the input field
   --  of the validation window at y 0 is its [Enter]
   procedure VBC_Validate (Yes : Boolean) is
   begin
      Press ((if Yes then 487 else 385), 340);
      Press (487, 40);
   end VBC_Validate;

   --  The wire bytes of a VBC code after the kind (kinds 8 and 9)
   function VBC_Bytes (Code : Natural) return Byte_Array is
     ((Code mod 256, (Code / 256) mod 256, (Code / 65536) mod 256,
       Code / 16777216));

   procedure Scenario_VBC_Settings is
   begin
      Reset;
      VBC_Onboard (National => 0);
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Win_At_Standstill;
      VBC_Settings;
      Check (Win_Top_Is (DMI_Windows.W_Settings), "vbc: the Settings window");
      Check (Win_Enabled (4), "Table 36 #4: System version in SB at standstill");
      Check (not Win_Enabled (5),
             "Table 36 #5: no Set VBC when the VBC storage is full");
      Check (not Win_Enabled (6), "Table 36 #6: no Remove VBC with none stored");
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit);
      Check (Win_Enabled (5) and then Win_Enabled (6),
             "Table 36 #5, #6: Set / Remove VBC in SB at standstill");
      Check_Frame ("vbc_settings");
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit,
                   Train => Win_Running);
      Check (not Win_Enabled (4) and then not Win_Enabled (5)
             and then not Win_Enabled (6),
             "Table 36 #4 to #6: not in SB while running");
      Send_Mode_Level (Mode => 2, Level => 4);  -- FS
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit,
                   Train => Win_Running);
      Check (Win_Enabled (4) and then not Win_Enabled (5)
             and then not Win_Enabled (6),
             "Table 36: System version in FS, Set / Remove VBC in SB only");
      Send_Mode_Level (Mode => 1, Level => 4);
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit);

      -- Table 54 S6-1: from S1 no value is proposed
      VBC_Settings;
      Win_Menu (5);
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC)
             and then Win_Value = "",
             "Table 54 S1 -> S6-1: the Set VBC window, no value proposed");
      Check (DMI_Windows.Close_Enabled, "11.7.7.2: [Close] enabled");
      -- 11.3.12.5 / SUBSET-026 7.5.1.154.1: 24 bits at most
      Win_Type ("16777216");
      Enter_Field (1);
      Step;
      Check_Frame ("vbc_set_out_of_range");
      Drain_Outbox;
      Press (167, 440);
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC),
             "10.3.4.2: a code above 16 777 215 cannot be completed");
      for I in 1 .. 8 loop
         Key (10);                              -- [Delete]
      end loop;
      Win_Type ("321456");
      Enter_Field (1);
      Step;
      Check_Frame ("vbc_set_entered");          -- Figure 128
      Press (167, 440);                         -- Set VBC entry complete? Yes
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC_Validation)
             and then Win_Value = "Yes",
             "Table 54 S6-1 -> S6-2: the validation window proposes 'Yes'");
      Expect_No_Driver_Data
        (8, "11.7.1.6.2: nothing is sent when 'Yes' of S6-1 is pressed");
      Step;
      Check_Frame ("vbc_set_validation");       -- Figure 131
      -- 'No' -> S6-1 with the previous value proposed
      VBC_Validate (Yes => False);
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC)
             and then Win_Value = "321456",
             "Table 54 S6-2 'No' -> S6-1, the previous value proposed");
      Expect_No_Driver_Data (8, "'No' sends nothing");
      Press (167, 440);
      VBC_Validate (Yes => True);
      Expect_Driver_Data (8, VBC_Bytes (321456),
                          "Table 54 S6-2 'Yes': kind 8 with the set code");
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S6-2 'Yes' -> S1, the Settings window");

      -- [Close] of S6-2: the process stops, a new one proposes nothing
      Win_Menu (5);
      Win_Type ("12");
      Enter_Field (1);
      Press (167, 440);
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC) and then Win_Value = "",
             "[Close] of S6-2 -> the Set VBC window, no value proposed");
      Drain_Outbox;
      Win_Close;
      Expect_No_Driver_Data (8, "[Close] sends nothing");
      Check (Win_Top_Is (DMI_Windows.W_Settings), "[Close] -> Settings");

      -- Remove VBC, Table 54 S7-1 / S7-2
      Win_Menu (6);
      Check (Win_Top_Is (DMI_Windows.W_Remove_VBC) and then Win_Value = "",
             "Table 54 S1 -> S7-1: the Remove VBC window, nothing proposed");
      Win_Type ("50078");
      Enter_Field (1);
      Step;
      Check_Frame ("vbc_remove_entered");       -- Figure 129
      Press (167, 440);
      Check (Win_Top_Is (DMI_Windows.W_Remove_VBC_Validation),
             "Table 54 S7-1 -> S7-2");
      Expect_No_Driver_Data (9, "11.7.1.6.2: nothing sent before S7-2");
      Step;
      Check_Frame ("vbc_remove_validation");    -- Figure 132
      VBC_Validate (Yes => False);
      Check (Win_Top_Is (DMI_Windows.W_Remove_VBC)
             and then Win_Value = "50078",
             "Table 54 S7-2 'No' -> S7-1, the previous value proposed");
      Press (167, 440);
      VBC_Validate (Yes => True);
      Expect_Driver_Data (9, VBC_Bytes (50078),
                          "Table 54 S7-2 'Yes': kind 9 with the remove code");
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S7-2 'Yes' -> S1, the Settings window");

      -- the largest code of 24 bits goes through
      Win_Menu (5);
      Win_Type ("16777215");
      Enter_Field (1);
      Press (167, 440);
      VBC_Validate (Yes => True);
      Expect_Driver_Data (8, VBC_Bytes (16777215),
                          "the largest set code, 16 777 215");

      -- 11.7.1.9: a driver's acknowledgement stops the process
      Win_Menu (5);
      Win_Type ("7");
      Enter_Field (1);
      Press (167, 440);
      Send_Text (91, "Ack me", Ack_Required => True);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "11.7.1.9: the acknowledgement stops Set VBC -> Settings");
      Send_Text_Remove (91);                    -- the EVC withdraws it
      for I in 1 .. 30 loop
         Step;
      end loop;
      Drain_Sounds;
      Drain_Outbox;

      -- Table 48 names no enabling condition for these windows: they
      -- stay when 'Set VBC' loses its conditions (11.7.1.7)
      Win_Default;
      VBC_Settings;
      Win_Menu (5);
      VBC_Onboard (National => VBC_Stored_Bit);
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC),
             "Table 48 has no Set VBC row: the window stays");
      Win_Default;
      Drain_Outbox;
   end Scenario_VBC_Settings;

   ---------------------------------------------------------------------
   -- 11.5.2: the System version window and MSG_SYSTEM_VERSION
   ---------------------------------------------------------------------

   procedure Scenario_VBC_System_Version is
   begin
      Reset;
      VBC_Onboard (National => 0);
      Send_Mode_Level (Mode => 1, Level => 4);
      Win_At_Standstill;
      VBC_Settings;
      Win_Menu (4);
      Check (Win_Top_Is (DMI_Windows.W_System_Version),
             "Table 54 S1 -> S5: the System version window");
      Check (DMI_Windows.Button_Count = 0,
             "Figure 135: no button but [Close]");
      Step;
      Check_Frame ("vbc_system_version_unknown");
      Send_System_Version (3, 0);
      Step;
      Check_Frame ("vbc_system_version");       -- Figure 135
      -- malformed and out of range
      Send_Raw (16#0E#, (1 => 2));
      Send_Raw (16#0E#, (2, 3, 0));
      Check (DMI_System_Version.Image = "3.0",
             "MSG_SYSTEM_VERSION of a wrong length is ignored");
      Send_System_Version (2, 3);
      Check (DMI_System_Version.Image = "2.3", "2.3 is taken");
      Send_System_Version (8, 0);
      Check (not DMI_System_Version.Known,
             "X above 7: the version is not known");
      Send_System_Version (2, 3);
      Send_System_Version (2, 16);
      Check (not DMI_System_Version.Known,
             "Y above 15: the version is not known");
      Step;
      Check_Frame ("vbc_system_version_unknown");
      Send_System_Version (3, 0);
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S5 [Close] -> S1");
      Win_Default;
   end Scenario_VBC_System_Version;

   ---------------------------------------------------------------------
   -- SDI-8, 8.2.3.2.9 / 8.2.3.2.10: the abbreviation of the National
   -- System in LE02, LE08 and LE09
   ---------------------------------------------------------------------

   procedure Scenario_VBC_Level_Name is
      function Name return Wide_String is
        (Supplementary_Driving_Info.National_Name.Text
           (1 .. Supplementary_Driving_Info.National_Name.Length));
   begin
      Reset;
      Send_Mode_Level (Mode => 8, Level => 3, National_Name => "PZB");
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Step;
      Check_Frame ("vbc_level_name_c8");
      Send_Mode_Level (Mode => 8, Level => 3, National_Name => "ATB");
      Step;
      Check_Frame ("vbc_level_name_c8_short");
      -- 8.2.3.2.10: a name wider than 48 cells even with characters of
      -- 10 cells is cut at the edge of that space
      Send_Mode_Level (Mode => 8, Level => 3, National_Name => "PZB/LZB");
      Step;
      Check_Frame ("vbc_level_name_c8_wide");
      -- 8.2.3.2.2: nothing in C8 in SN and NL, with or without a name
      Send_Mode_Level (Mode => 12, Level => 3, National_Name => "ATB");
      Step;
      Check_Frame ("level_ntc_sn_c8_empty");
      -- the 9 byte form: no name, LE02
      Send_Mode_Level (Mode => 8, Level => 3);
      Step;
      Check (Name = "", "the 9 byte message: no name");
      Check_Frame ("level_ntc_sh_le02");
      -- name_len 0 in the long form: no name either
      Send_Raw (16#02#, (8, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#, 16#FF#, 0));
      Check (Name = "", "name_len 0: no name");

      -- malformed: ignored as a whole (the mode byte would be FS)
      Send_Mode_Level (Mode => 8, Level => 3, National_Name => "ATB");
      Send_Raw (16#02#, (2, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#, 16#FF#,
                         3, 65, 66));
      Send_Raw (16#02#, (2, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#, 16#FF#,
                         2, 65, 66, 67));
      Send_Raw (16#02#, (2, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#, 16#FF#,
                         11, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65));
      Send_Raw (16#02#, (2, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#));
      Check (Name = "ATB"
             and then Supplementary_Driving_Info."="
                        (Supplementary_Driving_Info.Mode,
                         Supplementary_Driving_Info.M_SH),
             "MSG_MODE_LEVEL of a wrong length is ignored as a whole");
      -- the longest name
      Send_Raw (16#02#, (8, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#, 16#FF#,
                         10, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74));
      Check (Name = "ABCDEFGHIJ", "a name of 10 characters is taken");
      Step;
      Check_Frame ("vbc_level_name_c8_cut");

      -- LE08: the announcement of level NTC
      Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 3,
                       National_Name => "PZB/LZB");
      Step;
      Check_Frame ("vbc_level_name_le08");
      Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 3,
                       National_Name => "ATB");
      Step;
      Check_Frame ("vbc_level_name_le08_short");
      -- LE09: with acknowledgement, yellow
      Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 3,
                       Level_Ann_Ack => True, National_Name => "PZB/LZB");
      Step;
      Drain_Sounds;
      Check_Frame ("vbc_level_name_le09");
      Send_Mode_Level (Mode => 2, Level => 4);
      Step;
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_VBC_Level_Name;

   ---------------------------------------------------------------------
   -- Table 45 items 11 to 16...: the radio data info and the VBCs stored
   -- on-board in the Data view window (11.5.1.6, 11.5.1.6.1)
   ---------------------------------------------------------------------

   procedure Scenario_VBC_Data_View is
      procedure Set (Value : out DMI_Driver_Data.Text_Value_T;
                     Text  : Wide_String) is
      begin
         Value.Length := Text'Length;
         Value.Text (1 .. Text'Length) := Text;
      end Set;

      Radio_Both : constant Win_U8 :=
        Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_Known;
      RBC_Valid  : constant Win_U8 := Win_Data_All or 16#10#;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 5);  -- SB, level 2
      VBC_Onboard (National => 0, Data => RBC_Valid, Radio => Radio_Both);
      Win_At_Standstill;
      Win_Default;
      Press (610, 140);                         -- F3: Data view
      Press_Next;
      Step;
      Check_Frame ("vbc_data_view_p2_empty");

      -- Figure 134: what the driver entered on this DMI
      DMI_Radio_Data.GSMR_Network.Length := 6;
      DMI_Radio_Data.GSMR_Network.Text (1 .. 6) := "GSMR-A";
      Set (DMI_Radio_Data.RBC_ID, "12345678");
      Set (DMI_Radio_Data.RBC_Phone, "1234567809123456");
      DMI_Radio_Data.RBC_Entered := True;
      DMI_Radio_Data.Last_Choice := DMI_Radio_Data.Entered;
      Send_VBC_List ((71951, 321456));
      Step;
      Check_Frame ("vbc_data_view_p2");
      Check (DMI_Data_View.Title = "Data view (2/2)", "two windows");

      -- 11.5.1.6.1: no phone number without GSM-R
      VBC_Onboard (National => 0, Data => RBC_Valid,
                   Radio => Win_FRMCS or Win_Only_FRMCS or Win_Known);
      Step;
      Check_Frame ("vbc_data_view_p2_frmcs");
      -- after 'Contact last RBC' the RBC data are the on-board's
      VBC_Onboard (National => 0, Data => RBC_Valid,
                   Radio => Win_GSMR or Win_Only_GSMR or Win_Known);
      DMI_Radio_Data.Last_Choice := DMI_Radio_Data.Contact_Last_RBC;
      Step;
      Check_Frame ("vbc_data_view_p2_last_rbc");
      DMI_Radio_Data.Last_Choice := DMI_Radio_Data.Entered;

      -- "2..n": the VBCs that do not fit go on to window 3
      Send_VBC_List ((1, 22, 333, 4444, 55555, 666666, 7777777, 16777215,
                      9, 10, 11, 12, 13, 14, 15, 16));
      Step;
      Check (DMI_Data_View.Title = "Data view (2/3)", "16 VBCs: three windows");
      Check_Frame ("vbc_data_view_p2_full");
      Press_Next;
      Check_Frame ("vbc_data_view_p3");
      Check (not DMI_Windows.Button_Enabled (DMI_Data_View.Next_Button),
             "[Next] disabled on the last window");

      -- malformed lists are ignored as a whole
      Send_Raw (16#0F#, (1 => 17));
      Send_Raw (16#0F#, (2, 1, 0, 0, 0));
      Send_Raw (16#0F#, (1, 0, 0, 0, 1));             -- 2**24
      Send_Raw (16#0F#, (1 => 0, 2 => 0));
      Send_Raw (16#0F#, (1 .. 0 => 0));
      Check (DMI_VBC.Count = 16, "malformed MSG_VBC_LIST is ignored");
      -- the list shrinks while window 3 is displayed: the last window
      Send_VBC_List ((1 => 71951));
      Step;
      Check (DMI_Data_View.Title = "Data view (2/2)",
             "a shorter list: back to the last window");
      Send_VBC_List ((1 .. 0 => 0));
      Step;
      Check_Frame ("vbc_data_view_p2_no_vbc");
      Win_Default;
   end Scenario_VBC_Data_View;

   ---------------------------------------------------------------------
   -- The simulator stores what the driver sets and removes, and reports
   -- it (MSG_VBC_LIST, MSG_ONBOARD national bits)
   ---------------------------------------------------------------------

   procedure Scenario_VBC_Simulator is
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
         DMI_Core.Take_Outbox (Buffer, Last);
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

      procedure Run (Steps : Natural) is
      begin
         for I in 1 .. Steps loop
            EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
            DMI_Core.Tick (100);
            Pump_To_EVC;
            Drain_Sounds;
         end loop;
      end Run;

      procedure Touch (X, Y : Natural) is
      begin
         Pointer_Down (X, Y);
         Pointer_Up (X, Y);
         DMI_Core.Tick (50);
         Pump_To_EVC;
         Run (1);
      end Touch;

      Stored : Natural;
   begin
      Reset;
      EVC_Mock.Reset;
      External_EVC;
      Run (3);
      Stored := DMI_VBC.Count;
      Check (DMI_VBC.Known and then Stored >= 1
             and then DMI_System_Version.Image = "3.0",
             "sim: the VBC list and the system version are reported");
      Touch (385, 240); Touch (487, 90);       -- Driver ID 1
      Touch (Key_X (1), Key_Y (1)); Touch (487, 90);  -- level 1
      Touch (370, 440);                        -- [Close] the Main window
      Touch (610, 240);                        -- F5: Settings
      Check (Win_Top_Is (DMI_Windows.W_Settings)
             and then Win_Enabled (5) and then Win_Enabled (6),
             "sim: Set VBC and Remove VBC on offer");
      -- set 321456 (NID_VBCMK 48, NID_C 926, T_VBC 4)
      Touch (Win_Slot_X (5), Win_Slot_Y (5));
      for C of String'("321456") loop
         Touch (Key_X (Character'Pos (C) - Character'Pos ('0')),
                Key_Y (Character'Pos (C) - Character'Pos ('0')));
      end loop;
      Touch (589, 40);
      Touch (167, 440);
      Touch (487, 40);
      Run (2);
      Check (DMI_VBC.Count = Stored + 1
             and then DMI_VBC.Codes (DMI_VBC.Count) = 321456,
             "sim: the VBC set by the driver is stored and reported");
      -- remove it by its remove code 50078 (11.3.13.5)
      Touch (Win_Slot_X (6), Win_Slot_Y (6));
      for C of String'("50078") loop
         if C = '0' then
            Touch (Key_X (11), Key_Y (11));
         else
            Touch (Key_X (Character'Pos (C) - Character'Pos ('0')),
                   Key_Y (Character'Pos (C) - Character'Pos ('0')));
         end if;
      end loop;
      Touch (589, 40);
      Touch (167, 440);
      Touch (487, 40);
      Run (2);
      Check (DMI_VBC.Count = Stored,
             "sim: the VBC removed by the driver is gone");
      -- the level NTC of the simulator carries its National System
      Touch (370, 440);                        -- [Close] Settings
      Touch (610, 40);                         -- F1: Main
      Touch (Win_Slot_X (5), Win_Slot_Y (5));  -- Level
      Touch (Key_X (5), Key_Y (5)); Touch (487, 90);   -- NTC
      Run (2);
      Check (Supplementary_Driving_Info.National_Name.Length = 3,
             "sim: level NTC with the name of its National System");
      Win_Default;
      Run (1);
      DMI_Core.Render;
      Check_Frame ("vbc_sim_level_ntc");
      External_EVC (False);
   end Scenario_VBC_Simulator;

end DMI_Test_VBC;
