--  ETCS DMI
--  Shared scenario infrastructure for the DMI_Test subject
--  packages: resetting to a known state, pressing/typing on
--  windows, and the MSG_ONBOARD / VBC bit helpers several
--  subject packages share. Extracted from dmi_test.adb.

with Test_Support;
with Interfaces;
with DMI_Windows;
use Test_Support;

package DMI_Test_Support is

   procedure Reset;

   procedure Press (X, Y : Natural);

   function Key_X (K : Positive) return Natural;

   function Key_Y (K : Positive) return Natural;

   procedure Key (K : Positive);

   procedure Enter_Field (I : Positive);

   procedure Enter_Single;

   procedure Press_Previous;

   procedure Press_Next;

   procedure Choose_Level (K : Positive := 1);

   procedure Enter_Train_Data (Length, Brake, Speed : Positive);

   procedure Planning_Reset (V_Perm : Natural);

   function SS_Active (Number : Natural) return Boolean;

   procedure SS_Steps (Count : Natural);

   procedure SS_Reset (Mode : Natural := 2);

   ---------------------------------------------------------------------
   -- P3, audit WIN-12 / WIN-13: the Radio data window and its children
   -- (11.2.5, 11.3.4, 11.3.5, 11.3.15, 11.3.16), the Main and Special
   -- window entries of Tables 33 and 35 that were missing, the symbols
   -- of Table 36, and the dialogue sequences that use them (Tables 49,
   -- 50, 51, 54a)
   ---------------------------------------------------------------------

   subtype Win_U8 is Interfaces.Unsigned_8;
   use type Win_U8;

   --  MSG_ONBOARD bytes (dmi_protocol.ads)
   Win_Data_All : constant Win_U8 := 16#0F#; -- id, train data, level, TRN
   Win_Standing : constant Win_U8 := 16#03#; -- standstill, override ok
   Win_Running  : constant Win_U8 := 16#02#;
   Win_NV       : constant Win_U8 := 16#02#; -- adhesion may be modified

   --  radio byte: the type in bits 0-1, the installed systems in bits
   --  2-3, the registrations, 'one radio system' and the RBC contact
   --  information known
   Win_FRMCS      : constant Win_U8 := 1;
   Win_FRMCS_GSMR : constant Win_U8 := 2;
   Win_GSMR       : constant Win_U8 := 3;
   Win_Only_FRMCS : constant Win_U8 := 4;
   Win_Only_GSMR  : constant Win_U8 := 8;
   Win_Both       : constant Win_U8 := 12;
   Win_FRMCS_Reg  : constant Win_U8 := 16;
   Win_GSMR_Reg   : constant Win_U8 := 32;
   Win_One_Yes    : constant Win_U8 := 64;
   Win_Known      : constant Win_U8 := 128;

   --  the on-board of most steps below: GSM-R, one Mobile Terminal
   --  registered, RBC contact information known
   Win_Radio_GSMR : constant Win_U8 :=
     Win_GSMR or Win_Only_GSMR or Win_GSMR_Reg or Win_Known;

   procedure Win_Onboard (Data       : Win_U8 := Win_Data_All;
                          Session    : Win_U8 := 0;
                          RBC        : Win_U8 := 0;
                          Train      : Win_U8 := Win_Standing;
                          SOM        : Win_U8 := 0;
                          Waiting    : Win_U8 := 0;
                          Radio      : Win_U8 := 0;
                          Radio_Wait : Win_U8 := 0;
                          Answer     : Win_U8 := 0);

   procedure Win_At_Standstill;

   function Win_Slot_X (Slot : Positive) return Natural;

   function Win_Slot_Y (Slot : Positive) return Natural;

   procedure Win_Menu (Slot : Positive);

   procedure Win_Menu_Long (Slot : Positive);

   function Win_Top_Is (ID : DMI_Windows.Window_ID_T) return Boolean;

   function Win_Enabled (Index : Positive) return Boolean;

   function Win_Value (I : Positive := 1) return Wide_String;

   procedure Win_Close;

   procedure Win_Default;

   procedure Win_Open_Main;

   procedure Win_Type (Digits_Text : String);

   function Win_RBC_Bytes (Choice : Natural;
                           ID     : Natural;
                           Phone  : String) return Byte_Array;

   function Win_Name_Bytes (Name : String) return Byte_Array;

   ---------------------------------------------------------------------
   -- P3, audit WIN-12 / WIN-13 (the rest but Language) and SDI-8: the
   -- Settings buttons of Table 36 #4 to #6, the Set VBC and Remove VBC
   -- windows (11.3.12, 11.3.13) with their validation windows (11.4.2,
   -- 11.4.3) and the Settings dialogue sequence (Table 54 S5 to S7-2),
   -- the System version window (11.5.2), the National System name in
   -- the level symbols (8.2.3.2.9, 8.2.3.2.10) and the Table 45 items
   -- of the Data view that the DMI now holds
   ---------------------------------------------------------------------

   --  MSG_ONBOARD national bits 2 and 3 (dmi_protocol.ads)
   VBC_Room_Bit   : constant Win_U8 := 16#04#;
   VBC_Stored_Bit : constant Win_U8 := 16#08#;

   procedure VBC_Onboard (National : Win_U8;
                          Train    : Win_U8 := Win_Standing;
                          Data     : Win_U8 := Win_Data_All;
                          Radio    : Win_U8 := 0);

   procedure Lang_English;

end DMI_Test_Support;
