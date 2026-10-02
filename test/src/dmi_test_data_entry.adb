--  ETCS DMI
--  Body of DMI_Test_Data_Entry (see dmi_test_data_entry.ads).

with Ada.Streams;
with DMI_Core;
with DMI_Data_Entry;
with DMI_Driver_Data;
with DMI_Protocol;
with DMI_Test_Support;
with DMI_Windows;
with General_Parameters;
with Test_Support;
use Test_Support;
use DMI_Test_Support;
use type DMI_Test_Support.Win_U8;

package body DMI_Test_Data_Entry is

   procedure Scenario_Entry_Mechanics is
      use type DMI_Windows.Window_ID_T;

      -- Table 22 / Table 23 in absolute coordinates
      Merged_Field : constant := 90;          -- half grid array, y 50 .. 100
      function Field_Y (I : Positive) return Natural is (15 + (I - 1) * 50 + 25);
      Label_X : constant := 400;              -- label part, x 334 .. 538
      Data_X  : constant := 589;              -- data part,  x 538 .. 640

      function Value_Of (I : Positive) return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (I);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;
   begin
      Reset;
      -- SB with the level unknown, so that Table 49 D2 leads to S2
      Send_Mode_Level (Mode => 1, Level => 0);
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;

      -- Table 49 S1: the Driver ID window with a single input field
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID, "S1: Driver ID");
      Press (385, 240);                       -- 1
      Press (487, 240);                       -- 2
      Check (Value_Of (1) = "12", "the keys are echoed in the input field");

      -- 10.3.5.15: key 12 is the '.' button and it is disabled
      Press (589, 390);
      Check (Value_Of (1) = "12", "the disabled '.' key does nothing");

      -- 10.3.5.13: the keys of the keyboard are down-type buttons, so
      -- the value is entered with the press, not with the release
      Pointer_Down (589, 240);                -- 3
      Step;
      Check (Value_Of (1) = "123", "a down-type key enters with the press");
      Pointer_Up (589, 240);
      Step;
      Check (Value_Of (1) = "123", "the release of a down-type key adds nothing");
      Drain_Sounds;

      -- 10.3.1.22: the [Enter] button is the data field itself
      Press (487, Merged_Field);
      Check (DMI_Windows.Top = DMI_Windows.W_Level,
             "the data field accepts the value (10.3.1.22)");
      Check (DMI_Driver_Data.Driver_ID.Length = 3
             and then DMI_Driver_Data.Driver_ID.Text (1 .. 3) = "123",
             "the accepted value is stored");
      Drain_Outbox;

      -- a window with several input fields: the train data window
      Choose_Level;                           -- Level 1 -> S10, Main window
      Press (410, 140);                       -- Train data
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data, "train data open");

      -- 10.3.1.23: the first input field is selected; Figure 120 puts
      -- the train category there, with the dedicated keyboard of Table 41
      Key (1);
      Check (Value_Of (1) = "PASS 1",
             "one key of a dedicated keyboard carries the whole choice");
      -- 10.3.5.19: with more than 12 predefined choices the key 12 is
      -- the [More] button and the keys 1 to 11 take the next group
      Key (12);
      Key (1);
      Check (Value_Of (1) = "FP 2",
             "[More] shows the next group of predefined choices");
      Key (12);
      Key (1);
      Check (Value_Of (1) = "PASS 1",
             "the list of predefined choices is circular");
      Enter_Field (1);                        -- accepted -> field 2

      -- 10.3.1.26: another input field is selected by its label part;
      -- 10.3.1.20: the value entered without accepting it is erased
      Press (385, 240); Press (487, 240);     -- 12 into field 2
      Check (Value_Of (2) = "12", "field 2 takes the keys");
      Press (Label_X, Field_Y (3));
      Check (Value_Of (2) = "", "an entry left without accepting is erased");
      Press (385, 240);                       -- 1 into field 3
      Check (Value_Of (3) = "1", "field 3 is the selected one now");

      -- 10.3.1.26: the data part of an input field that is not selected
      -- selects it as well
      Press (Data_X, Field_Y (4));
      -- the maximum speed has a resolution of 5 km/h (10.3.4.3,
      -- SUBSET-026 7.5.1.160 V_MAXTRAIN)
      Press (487, 290);                       -- 5 into field 4
      Check (Value_Of (4) = "5" and then Value_Of (3) = "",
             "the data part of another field selects it");

      -- 10.3.1.24 / 10.3.1.25: accepting the last input field selects
      -- the first one again, the list is circular
      Press (Data_X, Field_Y (4));
      Key (2);                                -- 'PASS 2' into field 1
      Check (Value_Of (1) = "PASS 2" and then Value_Of (4) = "5",
             "the field after the last one is the first one");

      -- 10.3.1.19: the first key press replaces the data value
      Enter_Field (1);                        -- accepted -> field 2
      Press (385, 240); Press (487, 240);     -- 12 into the length
      Enter_Field (2);                        -- accepted -> field 3
      Press (Data_X, Field_Y (2));            -- the length again
      Press (589, 240);                       -- 3
      Check (Value_Of (2) = "3", "the first key replaces the data value");

      -- 10.3.2.3: the cursor flashes at 2 Hz (5 cycles of 50 ms)
      Step;
      Check_Frame ("entry_cursor_visible");
      for I in 1 .. 5 loop
         Step;
      end loop;
      Check_Frame ("entry_cursor_hidden");
      for I in 1 .. 5 loop
         Step;
      end loop;
      Check_Frame ("entry_cursor_visible");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Entry_Mechanics;

   ---------------------------------------------------------------------
   -- Data validation window (audit WIN-7: 10.4.1.1 to 10.4.1.5, Table
   -- 29, 10.3.5.18, 11.4.1)
   ---------------------------------------------------------------------

   procedure Scenario_Validation_Window is
      use type DMI_Windows.Window_ID_T;
      Key_No  : constant := 385;   -- Table 29 / Table 25 key 7, y 300
      Key_Yes : constant := 487;   -- key 8
      Field_Y : constant := 40;    -- Table 29: the input field at y 0

      function Value_Of return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (1);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;
   begin
      Reset;
      -- the level is unknown, so that Table 49 D2 leads to the Level window
      Send_Mode_Level (Mode => 1, Level => 0); -- SB
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;

      Press (385, 240); Press (487, 90);      -- Driver ID 1
      Choose_Level;                           -- Level 1 -> Main window
      Press (410, 140);                       -- Train data
      Enter_Train_Data (Length => 1, Brake => 1, Speed => 5);
      Press (167, 440);                       -- entry complete? -> validation
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data_Validation,
             "the validation window is open");

      -- Figure 105: the input field proposes 'Yes'
      Check (Value_Of = "Yes", "the input field proposes 'Yes'");
      Step;
      Check_Frame ("validation_window");

      -- 10.3.5.18: key 7 is 'No', key 8 is 'Yes'; 10.4.1.2 / 10.3.1.22:
      -- the choice has to be accepted on the data field
      Press (Key_No, 340);
      Check (Value_Of = "No", "the 'No' key writes the choice in the field");
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data_Validation,
             "a key press alone does not leave the validation window");
      Press (Key_Yes, Field_Y);               -- the data field is [Enter]
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "'No' accepted returns to the train data window (Table 50 S3-2)");
      Check (not DMI_Driver_Data.Train_Data_Entered,
             "'No' validates nothing");

      -- Table 50 S3-1 entered from S3-2: the first window of the topic
      -- with the data values of the previous S3-1 proposed
      Check (DMI_Data_Entry.Value (2).Length = 1
             and then DMI_Data_Entry.Value (2).Text (1) = '1',
             "the values of the previous S3-1 are proposed again");

      -- and once more with the proposed 'Yes'
      Press (167, 440);                       -- entry complete? -> validation
      Press (Key_Yes, Field_Y);
      Check (DMI_Driver_Data.Train_Data_Entered, "'Yes' validates the data");
      Check (DMI_Driver_Data.Train_Length = 1
             and then DMI_Driver_Data.Max_Speed = 5,
             "the validated values are the ones stored on board");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Validation_Window;

   ---------------------------------------------------------------------
   -- Data checks of a data entry window (audit WIN-5: 10.3.4.2 to
   -- 10.3.4.7, Figure 98, 5.3.2.7.3)
   ---------------------------------------------------------------------

   procedure Scenario_Data_Checks is
      use type DMI_Windows.Window_ID_T;
      use type DMI_Data_Entry.Cross_Kind_T;

      Data_X : constant := 589;   -- the data parts of Table 23
      function Field_Y (I : Positive) return Natural is (15 + (I - 1) * 50 + 25);

      function Value_Of (I : Positive) return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (I);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;

      -- a delay-type activation: 2 s of pressing (5.3.2.6.6)
      procedure Long_Press (X, Y : Natural) is
      begin
         Pointer_Down (X, Y);
         for I in 1 .. 41 loop
            Step;
         end loop;
         Pointer_Up (X, Y);
         Step;
         Drain_Sounds;
      end Long_Press;

      procedure Short_Press (X, Y : Natural) is
      begin
         Pointer_Down (X, Y);
         for I in 1 .. 10 loop
            Step;
         end loop;
         Pointer_Up (X, Y);
         Step;
         Drain_Sounds;
      end Short_Press;
   begin
      Reset;
      -- the level is unknown, so that Table 49 D2 leads to the Level window
      Send_Mode_Level (Mode => 1, Level => 0); -- SB
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;
      Press (385, 240); Press (487, 90);      -- Driver ID 1
      Choose_Level;                           -- Level 1 -> Main window
      Press (410, 140);                       -- Train data (1/2)
      Key (1); Enter_Field (1);               -- train category PASS 1

      -- 10.3.4.2: 5000 m is outside the range of L_TRAIN (0 .. 4095 m,
      -- SUBSET-026 7.5.1.56)
      Press (487, 290); Press (487, 390);     -- 5, 0
      Press (487, 390); Press (487, 390);     -- 0, 0
      Press (Data_X, Field_Y (2));            -- [Enter]
      Check (Value_Of (2) = "5000",
             "the input field out of range still shows the entered value");
      Step;
      Check_Frame ("entry_check_technical");

      -- 10.3.4.2.4: [Enter] is disabled until a key is pressed; the
      -- input field stays selected, so [Delete] works on its entry
      Press (Data_X, Field_Y (2));
      Press (385, 390);                       -- [Delete]
      Check (Value_Of (2) = "500" and then Value_Of (3) = "",
             "the disabled [Enter] accepted nothing");
      Press (Data_X, Field_Y (2));            -- 500 m is in range

      -- 10.3.4.3: 141 km/h does not match the 5 km/h resolution of
      -- V_MAXTRAIN (SUBSET-026 7.5.1.160)
      Press (Data_X, Field_Y (4));            -- select the maximum speed
      Press (385, 240); Press (385, 290); Press (385, 240);  -- 141
      Press (Data_X, Field_Y (4));            -- [Enter]
      Check (Value_Of (4) = "141", "the wrong resolution is not accepted");
      Press (385, 390);                       -- a key re-enables [Enter]
      Press (487, 390);                       -- 140
      Press (Data_X, Field_Y (4));
      Check (Value_Of (4) = "140", "140 km/h matches the resolution");

      -- 10.3.4.5: the operational range check; zero is not a nominal
      -- value for a train length (configuration of the DMI)
      Press (Data_X, Field_Y (2));            -- select the length
      Press (487, 390);                       -- 0
      Press (Data_X, Field_Y (2));            -- [Enter]
      Step;
      Check_Frame ("entry_check_operational");
      -- 10.3.4.5.5: [Enter] became a delay-type button
      Short_Press (Data_X, Field_Y (2));
      Press (385, 290);                       -- 4 is appended to the entry
      Check (Value_Of (2) = "04" and then Value_Of (3) = "",
             "a press shorter than 2 s does not overrule the check");
      -- 10.3.1.20: leaving the field without accepting erases the entry
      Press (Data_X, Field_Y (3));
      Press (Data_X, Field_Y (2));
      Press (385, 290); Press (487, 390); Press (487, 390);  -- 400
      Press (Data_X, Field_Y (2));            -- accepted -> field 3
      Press (385, 240); Press (487, 390); Press (487, 390);  -- 100
      Press (Data_X, Field_Y (3));
      Check (Value_Of (2) = "400" and then Value_Of (3) = "100"
             and then Value_Of (4) = "140",
             "every input field displays a data value");

      -- 10.3.5.9: the items of the second window as well, otherwise the
      -- 'Yes' button of the question stays disabled (Table 50 S3-1)
      Press_Next;
      Key (1); Enter_Field (1);               -- axle load category A
      Key (7); Enter_Field (2);               -- airtight: No
      Key (5); Enter_Field (3);               -- loading gauge Out of GC
      Press_Previous;
      Check (Value_Of (2) = "400" and then Value_Of (4) = "140",
             "the process keeps the values over [Next] and [Previous]");

      -- 10.3.4.4: a technical cross-check rule that is not satisfied
      -- ('length not greater than maximum speed' is nonsense as a rule,
      -- it only has to fail: no cross-check rule is configured)
      DMI_Data_Entry.Cross_Rules (1) :=
        (Kind => DMI_Data_Entry.Technical_Cross, A => 2, B => 4,
         Relation => DMI_Data_Entry.Not_Greater);
      Press (167, 440);                       -- 'Yes' of the question
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "the failed technical cross-check does not complete the entry");
      Step;
      Check_Frame ("entry_check_cross");
      -- 10.3.4.4.4: 'Yes' stays disabled until a value is modified
      Press (167, 440);
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "the disabled 'Yes' does not react");

      -- 10.3.4.6: the same rule as an operational one is overruled by a
      -- valid activation of the delay-type 'Yes'
      DMI_Data_Entry.Cross_Rules (1).Kind := DMI_Data_Entry.Operational_Cross;
      Press (Data_X, Field_Y (2));            -- select the length
      Press (487, 290); Press (487, 390); Press (487, 390);  -- 500
      Press (Data_X, Field_Y (2));            -- accepted: 'Yes' enabled
      Press (167, 440);
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "the failed operational cross-check does not complete either");
      Short_Press (167, 440);
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "a press shorter than 2 s does not overrule the cross-check");
      Long_Press (167, 440);
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data_Validation,
             "the delay-type 'Yes' overrules the operational cross-check");

      DMI_Data_Entry.Cross_Rules := (others => (others => <>));
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Data_Checks;

   ---------------------------------------------------------------------
   -- The alphanumeric keyboard of the Driver ID window (audit WIN-9:
   -- 11.3.3.4 to 11.3.3.7, 10.3.5.17, 10.3.2.5, 11.6.1.2, 11.7.2.2),
   -- the 5 character grouping of the entered data (audit GEN-6,
   -- 10.3.2.6 with 5.1.5) and the repeat function of the keys
   -- (5.3.2.6.5, 5.3.2.7.2)
   ---------------------------------------------------------------------

   procedure Scenario_Alphanumeric_Entry is
      use type DMI_Windows.Window_ID_T;

      Enter_Y : constant := 90;    -- Table 22: the merged data part
      Col_1   : constant := 385;   -- Table 25: the three key columns
      Col_2   : constant := 487;
      Col_3   : constant := 589;
      Row_1   : constant := 240;   -- Table 25: the four key rows
      Row_2   : constant := 290;
      Row_4   : constant := 390;
      Close_X : constant := 370;
      TRN_X   : constant := 517;   -- 11.3.3.7 a: (142,400), 82 x 50
      Set_X   : constant := 599;   -- 11.3.3.6 a: (224,400), 82 x 50
      Btn_Y   : constant := 440;

      function Value_Of return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (1);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;

      -- 10.3.2.5 a: let the 2 s delay-time run out
      procedure Wait_Tap is
      begin
         for I in 1 .. 41 loop
            Step;
         end loop;
      end Wait_Tap;
   begin
      Reset;
      -- SB with the level unknown, so that the sequence stays in S1
      Send_Mode_Level (Mode => 1, Level => 0);
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "Table 49 S1: the Driver ID window");

      -- 10.3.5.17 / 11.3.3.4: the key 2 of the alphanumeric keyboard
      -- carries '2', 'a', 'b' and 'c'; 10.3.2.5 b: the same key again
      -- within the 2 s delay-time selects the next one
      Press (Col_2, Row_1);
      Check (Value_Of = "2", "the first press enters the number of the key");
      Press (Col_2, Row_1);
      Check (Value_Of = "a", "the same key again selects the next character");
      Press (Col_2, Row_1);
      Press (Col_2, Row_1);
      Check (Value_Of = "c", "and so on through the letters of the key");
      Press (Col_2, Row_1);
      Check (Value_Of = "2", "the characters of one key are circular");

      -- 10.3.2.5 a: after the 2 s the cursor has jumped by itself
      Wait_Tap;
      Press (Col_2, Row_1);
      Check (Value_Of = "22",
             "after the 2 s delay-time the same key enters a new character");

      -- 10.3.2.5 c: another data key makes the cursor jump directly
      Press (Col_3, Row_1);
      Check (Value_Of = "223", "another data key jumps to the next position");
      Press (Col_3, Row_1);
      Check (Value_Of = "22d", "and starts its own selection there");

      -- 5.3.2.7.1 e: [Delete] removes the just entered character
      Press (Col_1, Row_4);
      Check (Value_Of = "22", "[Delete] removes the entered character");
      Press (Col_1, Row_4);
      Press (Col_1, Row_4);
      Check (Value_Of = "", "and the input field is empty again");

      -- 10.3.5.17: the key 12 shows the '.' as disabled, the key 11 is
      -- the number '0' and the key 1 the number '1' alone
      Press (Col_3, Row_4);
      Check (Value_Of = "", "the disabled '.' key does nothing");
      Press (Col_1, Row_1);
      Press (Col_1, Row_1);
      Check (Value_Of = "11", "a key with one character enters it twice");
      Press (Col_2, Row_4);
      Check (Value_Of = "110", "the key 11 is the number '0'");
      Press (Col_1, Row_4);
      Press (Col_1, Row_4);
      Press (Col_1, Row_4);

      -- 10.3.2.6 with 5.1.5.1: from the 6th character on, a single space
      -- splits the data into two groups of at most 5 characters
      Press (Col_1, Row_1); Press (Col_2, Row_1); Press (Col_3, Row_1);
      Press (Col_1, Row_2); Press (Col_2, Row_2); Press (Col_3, Row_2);
      Check (Value_Of = "123456", "six characters are entered");
      Step;
      Check_Frame ("driver_id_grouped");     -- '123 456'

      -- 5.1.5.2: a line break every 8 characters
      Press (Col_1, Row_1); Press (Col_2, Row_1); Press (Col_3, Row_1);
      Check (Value_Of = "123456123",
             "SUBSET-026 A.3.11: the Driver ID takes up to 16 characters");
      Step;
      Check_Frame ("driver_id_two_lines"); -- '1234 5612' / '3'

      -- 5.3.2.6.5 / 5.3.2.7.2: the repeat function is a property of the
      -- button. A key that enters one single character does not repeat.
      Press (Col_1, Row_4); Press (Col_1, Row_4); Press (Col_1, Row_4);
      Press (Col_1, Row_4); Press (Col_1, Row_4); Press (Col_1, Row_4);
      Press (Col_1, Row_4); Press (Col_1, Row_4); Press (Col_1, Row_4);
      Check (Value_Of = "", "the input field is empty again");
      Pointer_Down (Col_1, Row_1);
      for I in 1 .. 60 loop                 -- 3 s, past every repeat
         Step;
      end loop;
      Pointer_Up (Col_1, Row_1);
      Step;
      Drain_Sounds;
      Check (Value_Of = "1",
             "a data key with one character does not repeat (5.3.2.6.5)");

      -- 10.3.2.5 b: holding a data key selects another character under it
      Press (Col_1, Row_4);
      Pointer_Down (Col_2, Row_1);
      Step;
      Check (Value_Of = "2", "the press enters the number of the key");
      for I in 1 .. 39 loop                 -- 1.5 s + one 0.3 s repeat
         Step;
      end loop;
      Pointer_Up (Col_2, Row_1);
      Step;
      Drain_Sounds;
      Check (Value_Of = "a",
             "holding a data key selects another character (10.3.2.5 b)");
      Press (Col_1, Row_4);

      -- 11.3.3.7 / Table 49 S1-2: the 'TRN' button leads to the Train
      -- running number window, whose parent is the Driver ID window
      -- (11.6.1.2); 11.7.2.2: [Close] is enabled in S1-2
      Press (TRN_X, Btn_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_TRN,
             "S1: the 'TRN' button leads to S1-2");
      Check (DMI_Windows.Close_Enabled, "S1-2: [Close] is enabled");
      Press (Close_X, Btn_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "S1-2: [Close] comes back to S1");
      Press (TRN_X, Btn_Y);
      Press (Col_1, Row_1);                 -- 1
      Press (Col_2, Enter_Y);               -- [Enter]: E1-2 -> S1
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "E1-2: the entered train running number comes back to S1");
      Check (DMI_Driver_Data.TRN.Length = 1
             and then DMI_Driver_Data.TRN.Text (1 .. 1) = "1",
             "and is stored");

      -- 11.3.3.6 / Table 49 S1-1: the 'settings' button leads to the
      -- Settings window, [Close] enabled there too
      Press (Set_X, Btn_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_Settings,
             "S1: the 'settings' button leads to S1-1");
      Check (DMI_Windows.Close_Enabled, "S1-1: [Close] is enabled");
      Press (Close_X, Btn_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "E1-1: [Close] comes back to S1");

      -- 11.7.2.2: in S1 itself [Close] stays disabled
      Check (not DMI_Windows.Close_Enabled, "S1: [Close] is disabled");
      Press (Close_X, Btn_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "S1: the disabled [Close] does not close the window");

      -- Table 49 E1 -> D2: the level is not valid, so the procedure goes
      -- to S2 whatever the DMI's own record of the entry says
      Press (Col_1, Row_1);
      Press (Col_2, Enter_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_Level,
             "D2: an invalid level leads to S2");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Alphanumeric_Entry;

   ---------------------------------------------------------------------
   -- Dedicated keyboards on the half grid array (audit WIN-10): Level
   -- (11.3.2), Adhesion (11.3.11), Volume (11.3.7) and Brightness
   -- (11.3.8) are data entry windows with one input field, a list of
   -- predefined choices (10.3.5.19) and an acceptance step
   ---------------------------------------------------------------------

   procedure Scenario_Dedicated_Keyboards is
      use type DMI_Windows.Window_ID_T;

      function Value_Of return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (1);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 0); -- SB, level unknown
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;

      -- Table 49 S1 -> S2: the Level window of 11.3.2
      Press (385, 240); Press (487, 90);      -- Driver ID 1
      Check (DMI_Windows.Top = DMI_Windows.W_Level, "the Level window");
      -- 11.7.1.4: with an unknown level nothing is proposed
      Check (Value_Of = "", "an unknown level proposes no value");

      -- Table 38: the buttons 1, 2 and 4 are reserved for the levels 1,
      -- 2 and 0, the button 3 carries no choice at all
      Check (DMI_Windows.Button_Enabled (1)
             and then DMI_Windows.Button_Enabled (2)
             and then DMI_Windows.Button_Enabled (4)
             and then DMI_Windows.Button_Enabled (5),
             "Table 38: the levels 1, 2, 0 and NTC are on offer");
      Check (not DMI_Windows.Button_Enabled (3),
             "Table 38: the button 3 carries no choice");
      Check (not DMI_Windows.Button_Enabled (6),
             "11.3.2.8: no button beyond the configured list of levels");

      -- 10.3.1.19: the choice is displayed instead of the data value;
      -- 10.3.1.22: it becomes the data value on the input field
      Key (4);
      Check (Value_Of = "Level 0", "the button 4 writes 'Level 0'");
      Check (DMI_Windows.Top = DMI_Windows.W_Level,
             "a key press alone does not leave the window");
      Key (3);
      Check (Value_Of = "Level 0", "the button without a choice does nothing");
      Key (2);
      Check (Value_Of = "Level 2", "another choice replaces the value");
      -- Table 49 S2: level 1 goes to S10 (level 2 goes to S3-1, the
      -- Radio data window: scenario Win_Start_Up_Radio)
      Key (1);
      Check (Value_Of = "Level 1", "and another one");
      Enter_Single;
      Check (not DMI_Windows.In_Start_Up,
             "the accepted level ends the Start Up sequence (Table 49 S2)");
      Expect_Actions (11, 1, "the accepted level is sent to the EVC");

      -- 11.7.1.4: reopened, the window proposes the level stored on board
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Press (410, 190);                        -- Main window: Level
      Check (DMI_Windows.Top = DMI_Windows.W_Level, "the Level window again");
      Check (Value_Of = "Level 2",
             "11.7.1.4: the level stored on board is proposed");
      Press (370, 440);                        -- [Close]

      -- 11.3.11.4, Table 43: the Adhesion window. Table 35 #1 offers it
      -- in FS without further conditions.
      Press (370, 440);                        -- close the Main window
      Send_Mode_Level (Mode => 2, Level => 5); -- FS
      Press (610, 190);                        -- F4: Special window
      Press (410, 90);                         -- Adhesion
      Check (DMI_Windows.Top = DMI_Windows.W_Adhesion, "the Adhesion window");
      Key (1);
      Check (Value_Of = "Non slippery rail", "Table 43: the button 1");
      Enter_Single;
      Check (DMI_Windows.Top = DMI_Windows.W_Special,
             "10.6.1.2 a: the accepted value leaves the window");
      Expect_Actions (9, 1, "the accepted adhesion is sent to the EVC");

      -- 11.3.8: the Brightness window, one key per level of luminance
      Press (370, 440);                        -- close Special
      Press (610, 240);                        -- F5: Settings
      Press (410, 140);                        -- Brightness
      Check (DMI_Windows.Top = DMI_Windows.W_Brightness,
             "the Brightness window");
      Check (Value_Of = "5", "11.7.1.4: the stored luminance is proposed");
      Key (9);                                 -- the level 8
      Enter_Single;
      Check (General_Parameters."="
               (General_Parameters.Display_Luminance, 8),
             "the accepted choice sets the luminance");
      Check (DMI_Windows.Top = DMI_Windows.W_Settings,
             "accepting the luminance leaves the window");

      -- 11.7.1.9 and Table 48: the four windows are data entry windows,
      -- so a required acknowledgement stops their process (audit WIN-3)
      Press (410, 140);                        -- Brightness again
      Check (DMI_Windows.Entry_Open,
             "Table 48: Brightness is a data entry window");
      DMI_Windows.Stop_Entry;
      Check (DMI_Windows.Top = DMI_Windows.W_Settings,
             "11.7.1.9: the stopped entry shows the parent window");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Dedicated_Keyboards;

   ---------------------------------------------------------------------
   -- Train data window(s) of the flexible train data entry (audit
   -- WIN-8: 11.3.9.6 b, Table 40, Figures 120 and 121, 11.7.1.6.1) and
   -- what MSG_DRIVER_DATA carries to the EVC
   ---------------------------------------------------------------------

   procedure Scenario_Train_Data_Windows is
      use type DMI_Windows.Window_ID_T;
      use Ada.Streams;
      use DMI_Protocol;

      -- the last MSG_DRIVER_DATA of kind 2 (the train data of Table 40)
      Train_Msg : Stream_Element_Array
        (1 .. Stream_Element_Offset (Driver_Data_Train_Length)) :=
          (others => 0);
      Train_Msg_Len : Natural := 0;

      procedure Collect_Train_Data is
         Buffer : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
         Last   : Stream_Element_Offset;
         Offset : Stream_Element_Offset := Buffer'First;
      begin
         Train_Msg_Len := 0;
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
               if The_Type = MSG_DRIVER_DATA
                 and then Length = Stream_Element_Offset
                                     (Driver_Data_Train_Length)
                 and then Natural (Buffer (Offset)) = 2
               then
                  Train_Msg_Len := Natural (Length);
                  Train_Msg := Buffer (Offset .. Next - 1);
               end if;
               Offset := Next;
            end;
         end loop;
      end Collect_Train_Data;

      function Byte (I : Positive) return Natural is
        (Natural (Train_Msg (Stream_Element_Offset (I))));

      function Word (I : Positive) return Natural is
        (Byte (I) + Byte (I + 1) * 256);

      function Value_Of (I : Positive) return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (I);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;
   begin
      Reset;
      -- the level is unknown, so that Table 49 D2 leads to the Level window
      Send_Mode_Level (Mode => 1, Level => 0); -- SB
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;

      Press (385, 240); Press (487, 90);      -- Driver ID 1
      Choose_Level;                           -- Level 1 -> Main window
      Press (410, 140);                       -- Train data (1/2)
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "the first train data window");

      -- 10.3.1.20 read for a window change: an entry that was not
      -- accepted is lost with the window
      Key (2);                                -- 'PASS 2'
      Press_Next;
      Press_Previous;
      Check (Value_Of (1) = "",
             "a window change drops the entry that was not accepted");

      Enter_Train_Data (Length => 250, Brake => 96, Speed => 120);
      -- 10.3.5.19 on the second window: 13 axle load categories
      -- (SUBSET-026 7.5.1.62) need the [More] button of the key 12
      Press_Next;
      Key (12);
      Key (2);
      Check (Value_Of (1) = "E5",
             "[More] reaches the 13th axle load category");
      Enter_Field (1);
      Press_Previous;
      -- Table 50 S3-1: the values survive [Previous] and [Next]
      Check (Value_Of (2) = "250" and then Value_Of (4) = "120",
             "the process keeps the values of the first window");

      -- 11.7.1.6.1: pressing 'Yes' stores nothing on board
      Press (167, 440);                       -- entry complete? Yes
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data_Validation,
             "the validation window follows (Table 50 S3-2)");
      Check (not DMI_Driver_Data.Train_Data_Entered
             and then DMI_Driver_Data.Train_Length = 0,
             "11.7.1.6.1: nothing is stored before the validation");
      -- the outbox is read here, before the test wrapper drains it with
      -- the sounds, so that MSG_DRIVER_DATA can be inspected
      Pointer_Down (487, 40); Pointer_Up (487, 40);
      DMI_Core.Tick (50);
      Collect_Train_Data;
      DMI_Core.Render;
      Check (DMI_Driver_Data.Train_Data_Entered
             and then DMI_Driver_Data.Train_Length = 250
             and then DMI_Driver_Data.Brake_Pct = 96
             and then DMI_Driver_Data.Max_Speed = 120,
             "the validated values are stored on board");

      -- MSG_DRIVER_DATA kind 2: the seven items of Table 40 as the
      -- ERTMS/ETCS variables of SUBSET-026 chapter 7
      Check (Train_Msg_Len = Driver_Data_Train_Length,
             "the train data message carries the seven items");
      Check (Word (2) = 250 and then Word (4) = 96 and then Word (6) = 120,
             "length, brake percentage and maximum speed on the wire");
      Check (Byte (8) = 0 and then Word (9) = 4,
             "Table 41 PASS 1: NC_CDTRAIN 0, NC_TRAIN passenger train");
      Check (Byte (11) = 12, "M_AXLELOADCAT 12 is E5");
      Check (Byte (12) = 0, "M_AIRTIGHT 0: no airtight system fitted");
      Check (Byte (13) = 0, "M_LOADINGGAUGE 0: out of the profiles");

      -- Table 45: the data view window shows what was stored
      Press (370, 440);                       -- close the TRN window
      Press (370, 440);                       -- close the Main window
      Press (610, 140);                       -- F3: Data view
      Step;
      Check_Frame ("data_view_train_data");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Train_Data_Windows;

end DMI_Test_Data_Entry;
