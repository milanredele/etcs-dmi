--  ETCS DMI
--  Driver-entered data (chapter 11 data entry windows). Values live here
--  between windows and are reported to the EVC as MSG_DRIVER_DATA.

package DMI_Driver_Data is

   -- The longest data value of a chapter 11 input field: the predefined
   -- choice 'Non slippery rail' of the adhesion keyboard (DMI Table 43)
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

   procedure Reset;

end DMI_Driver_Data;
