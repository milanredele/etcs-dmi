--  ETCS DMI
--  Body of DMI_Test_Support (see dmi_test_support.ads).

with DMI_Core;
with DMI_Data_Entry;
with DMI_Driver_Data;
with DMI_System_Status;
with DMI_Texts;
with General_Parameters;

package body DMI_Test_Support is

   procedure Reset is
   begin
      DMI_Core.Initialise;
      Test_Support.Reset_EVC_Model;
      -- scenarios send EVC messages only when the picture changes
      General_Parameters.EVC_Link_Timeout_Ms := 0;
      Drain_Sounds;
   end Reset;

   ---------------------------------------------------------------------
   -- Speed monitoring scenarios (chapters 7 and 8.2.1)
   ---------------------------------------------------------------------

   procedure Press (X, Y : Natural) is
   begin
      Pointer_Down (X, Y);
      Pointer_Up (X, Y);
      -- process the activation so consecutive presses see the updated
      -- window state
      Step;
      Drain_Sounds;
   end Press;

   ---------------------------------------------------------------------
   -- Coordinates of the data entry windows (Tables 22, 23, 25) and the
   -- two sequences the scenarios repeat: the Level window of Table 38
   -- and the train data of Table 40 over two windows (audit WIN-8,
   -- WIN-10)
   ---------------------------------------------------------------------

   -- Table 25: key K of the keyboard, three per row from y 200
   function Key_X (K : Positive) return Natural is
     (334 + ((K - 1) mod 3) * 102 + 51);
   function Key_Y (K : Positive) return Natural is
     (15 + 200 + ((K - 1) / 3) * 50 + 25);

   procedure Key (K : Positive) is
   begin
      Press (Key_X (K), Key_Y (K));
   end Key;

   -- Table 23: the data part of the input field I, which is its [Enter]
   -- button (10.3.1.22)
   procedure Enter_Field (I : Positive) is
   begin
      Press (589, 15 + (I - 1) * 50 + 25);
   end Enter_Field;

   -- Table 22: the merged data part of a window with a single input
   -- field (10.3.5.5)
   procedure Enter_Single is
   begin
      Press (487, 90);
   end Enter_Single;

   -- Tables 22 and 23: [Previous] and [Next] right of [Close]
   procedure Press_Previous is
   begin
      Press (457, 440);
   end Press_Previous;

   procedure Press_Next is
   begin
      Press (539, 440);
   end Press_Next;

   -- 11.3.2: choose a level on the dedicated keyboard of Table 38 and
   -- accept it (K is the button number of the table)
   procedure Choose_Level (K : Positive := 1) is
   begin
      Key (K);
      Enter_Single;
   end Choose_Level;

   -- 11.3.9: the seven items of Table 40 over the two windows of
   -- Figures 120 and 121, ending on the first window again
   procedure Enter_Train_Data (Length, Brake, Speed : Positive) is
      procedure Type_Number (N : Natural) is
         Img : constant Wide_String := Natural'Wide_Image (N);
      begin
         for I in 2 .. Img'Last loop
            -- Table 25: '1' .. '9' on the keys 1 .. 9, '0' on the key 11
            if Img (I) = '0' then
               Key (11);
            else
               Key (Wide_Character'Pos (Img (I))
                    - Wide_Character'Pos ('0'));
            end if;
         end loop;
      end Type_Number;
   begin
      Key (1); Enter_Field (1);           -- train category PASS 1
      Type_Number (Length); Enter_Field (2);
      Type_Number (Brake); Enter_Field (3);
      Type_Number (Speed); Enter_Field (4);
      Press_Next;
      Key (1); Enter_Field (1);           -- axle load category A
      Key (7); Enter_Field (2);           -- airtight: No (Table 40)
      Key (5); Enter_Field (3);           -- loading gauge Out of GC
      Press_Previous;
   end Enter_Train_Data;
   procedure Planning_Reset (V_Perm : Natural) is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 100, V_Perm => V_Perm, V_Target => 0,
                        V_Release => 0, V_Sbi => V_Perm + 15,
                        V_Wsl => V_Perm + 5,
                        D_Target => 2500, Monitoring => 0, Dial_Range => 2,
                        Vrelease_Exists => False);
   end Planning_Reset;

   -- PLN-1: 8.3.10.4 enlarges the sensitive area of D9 by 15 cells above
   -- D9, 8.3.10.5 the one of D12 by 15 cells below D12, 40x30 each. Area
   -- D starts at (334, 15): D9 is y 300 .. 314, D12 is y 15 .. 29.
   function SS_Active (Number : Natural) return Boolean is
     (DMI_System_Status.Active (DMI_System_Status.Entry_T (Number)));

   procedure SS_Steps (Count : Natural) is
   begin
      for I in 1 .. Count loop
         Step;
      end loop;
   end SS_Steps;

   -- A standing train in FS, level 1, at 09:41 on the DMI's clock
   procedure SS_Reset (Mode : Natural := 2) is
   begin
      Reset;
      Send_Mode_Level (Mode => Mode, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Send_Status (HH => 9, MM => 41, SS => 7);
      Step;
      Drain_Sounds;
      Drain_Outbox;
   end SS_Reset;

   -- 15.1.1.3 text and case, 8.2.3.4.7 first group / bold / Sinfo, the
   -- time stamp of the DMI's clock, the end by the named event; SDI-9
   -- MSG_TEXT class 2; what is not in the catalogue is ignored
   procedure Win_Onboard (Data       : Win_U8 := Win_Data_All;
                          Session    : Win_U8 := 0;
                          RBC        : Win_U8 := 0;
                          Train      : Win_U8 := Win_Standing;
                          SOM        : Win_U8 := 0;
                          Waiting    : Win_U8 := 0;
                          Radio      : Win_U8 := 0;
                          Radio_Wait : Win_U8 := 0;
                          Answer     : Win_U8 := 0) is
   begin
      Send_Onboard_Raw (Data, Session, RBC, Train, Win_NV, SOM, Waiting, 0,
                        Radio, Radio_Wait, Answer);
      Step;
   end Win_Onboard;

   procedure Win_At_Standstill is
   begin
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
   end Win_At_Standstill;

   --  Table 20: the menu button Slot, two columns of 153 x 50 from y 50
   function Win_Slot_X (Slot : Positive) return Natural is
     (334 + ((Slot - 1) mod 2) * 153 + 76);
   function Win_Slot_Y (Slot : Positive) return Natural is
     (15 + 50 + ((Slot - 1) / 2) * 50 + 25);

   procedure Win_Menu (Slot : Positive) is
   begin
      Press (Win_Slot_X (Slot), Win_Slot_Y (Slot));
   end Win_Menu;

   --  a delay-type button: 2 s of pressing (5.3.2.6.6)
   procedure Win_Menu_Long (Slot : Positive) is
   begin
      Pointer_Down (Win_Slot_X (Slot), Win_Slot_Y (Slot));
      for I in 1 .. 41 loop
         Step;
      end loop;
      Pointer_Up (Win_Slot_X (Slot), Win_Slot_Y (Slot));
      Step;
      Drain_Sounds;
   end Win_Menu_Long;

   function Win_Top_Is (ID : DMI_Windows.Window_ID_T) return Boolean is
     (DMI_Windows.Is_Open and then DMI_Windows."=" (DMI_Windows.Top, ID));

   function Win_Enabled (Index : Positive) return Boolean is
     (DMI_Windows.Button_Enabled (Index));

   function Win_Value (I : Positive := 1) return Wide_String is
      V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (I);
   begin
      return V.Text (1 .. V.Length);
   end Win_Value;

   procedure Win_Close is
   begin
      Press (370, 440);
   end Win_Close;

   --  Close every window that can be closed
   procedure Win_Default is
   begin
      while DMI_Windows.Is_Open and then DMI_Windows.Close_Enabled loop
         Win_Close;
      end loop;
   end Win_Default;

   procedure Win_Open_Main is
   begin
      Win_Default;
      Press (610, 40);                          -- F1
   end Win_Open_Main;

   --  Table 25: '1' .. '9' on the keys 1 .. 9, '0' on the key 11
   procedure Win_Type (Digits_Text : String) is
   begin
      for C of Digits_Text loop
         if C = '0' then
            Key (11);
         else
            Key (Character'Pos (C) - Character'Pos ('0'));
         end if;
      end loop;
   end Win_Type;

   --  The wire bytes of an RBC data message after the kind (kind 5)
   function Win_RBC_Bytes (Choice : Natural;
                           ID     : Natural;
                           Phone  : String) return Byte_Array is
      Result : Byte_Array (1 .. 22) := (others => 0);
   begin
      Result (1) := Choice;
      Result (2) := ID mod 256;
      Result (3) := (ID / 256) mod 256;
      Result (4) := (ID / 65536) mod 256;
      Result (5) := ID / 16777216;
      Result (6) := Phone'Length;
      for I in Phone'Range loop
         Result (7 + I - Phone'First) := Character'Pos (Phone (I));
      end loop;
      return Result;
   end Win_RBC_Bytes;

   function Win_Name_Bytes (Name : String) return Byte_Array is
      Result : Byte_Array (1 .. Name'Length + 1);
   begin
      Result (1) := Name'Length;
      for I in Name'Range loop
         Result (2 + I - Name'First) := Character'Pos (Name (I));
      end loop;
      return Result;
   end Win_Name_Bytes;

   ---------------------------------------------------------------------
   -- Table 33 #7, #9, #10, #11, #12 and the Shunting (11.7.4, Table 51)
   -- and Supervised Manoeuvre (11.7.8, Table 54a) dialogue sequences
   ---------------------------------------------------------------------

   procedure VBC_Onboard (National : Win_U8;
                          Train    : Win_U8 := Win_Standing;
                          Data     : Win_U8 := Win_Data_All;
                          Radio    : Win_U8 := 0) is
   begin
      Send_Onboard_Raw (Data, 0, 0, Train, Win_NV or National, 0, 0, 0,
                        Radio, 0, 0);
      Step;
   end VBC_Onboard;

   procedure Lang_English is
   begin
      DMI_Texts.Select_Language (DMI_Texts.English);
      Win_Default;
      Drain_Outbox;
   end Lang_English;

   --  5.5.1.3 with the layout rules the English texts follow: in every
   --  language a text fits the object it is drawn in, on one line or,
   --  for the buttons and the keys, broken over two at a space the way
   --  Draw_Labelled_Button and Draw_Choice_Key break it

end DMI_Test_Support;
