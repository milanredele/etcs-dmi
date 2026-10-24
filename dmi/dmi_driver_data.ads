--  ETCS DMI
--  Driver-entered data (chapter 11 data entry windows). Values live here
--  between windows and are reported to the EVC as MSG_DRIVER_DATA.

package DMI_Driver_Data is

   --  The longest data value of a chapter 11 input field: the predefined
   --  choice 'Non slippery rail' of the adhesion keyboard (DMI Table 43).
   --  SUBSET-026 A.3.11 gives the Driver ID 1 to 16 alphanumeric
   --  characters (3.18.4.1.4); the train running number is 8 digits
   --  (NID_OPERATIONAL, 7.5.1.92).
   Max_Field_Len : constant := 18;

   type Text_Value_T is record
      Length : Natural := 0;
      Text   : Wide_String (1 .. Max_Field_Len) := (others => ' ');
   end record;

   Driver_ID  : Text_Value_T;             -- 11.3.3
   TRN        : Text_Value_T;             -- 11.3.1

   -- Train data of the flexible train data entry (11.3.9.6 b, Table
   -- 40), stored only after the validation window was left with 'Yes'
   -- (11.7.1.6.1). The three numeric items are the value itself; the
   -- four items of a dedicated keyboard are the position of the chosen
   -- key in the lists of DMI_Train_Data (0: no value), which turns them
   -- into the label and into the SUBSET-026 value for the EVC.
   Train_Length   : Natural := 0;         -- m, L_TRAIN
   Brake_Pct      : Natural := 0;         -- %
   Max_Speed      : Natural := 0;         -- km/h, V_MAXTRAIN
   Train_Category : Natural := 0;         -- Table 41
   Axle_Load      : Natural := 0;         -- M_AXLELOADCAT, 7.5.1.62
   Airtight       : Natural := 0;         -- M_AIRTIGHT, 7.5.1.61
   Loading_Gauge  : Natural := 0;         -- Table 42, M_LOADINGGAUGE

   SR_Speed : Natural := 0;               -- 11.3.10
   SR_Dist  : Natural := 0;

   Driver_ID_Entered  : Boolean := False;
   Level_Entered      : Boolean := False;
   Train_Data_Entered : Boolean := False; -- set after validation
   TRN_Entered        : Boolean := False;

   --  SUBSET-026 3.18.6.1: the Driver ID and the train running number
   --  stored on-board (MSG_STORED_VALUES); once one is received they
   --  replace the entries above in the data view (decision: before it
   --  the DMI shows its own entries)
   Onboard_Values_Known : Boolean := False;
   Onboard_Driver_ID    : Text_Value_T;
   Onboard_TRN          : Text_Value_T;
   --  ... and the Train Data and the GSM-R network ID, when the message
   --  carries them (its long form): the three numbers as the values,
   --  the four choices as positions in the lists of DMI_Train_Data (0: no
   --  such choice), the network as its name in the list of the on-board
   Onboard_Long_Known   : Boolean := False;
   Onboard_Train_Valid  : Boolean := False;
   Onboard_Length       : Natural := 0;
   Onboard_Brake_Pct    : Natural := 0;
   Onboard_Max_Speed    : Natural := 0;
   Onboard_Category     : Natural := 0;
   Onboard_Axle_Load    : Natural := 0;
   Onboard_Airtight     : Natural := 0;
   Onboard_Gauge        : Natural := 0;
   Onboard_Network      : Text_Value_T;

   procedure Reset;

end DMI_Driver_Data;
