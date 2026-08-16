--  ETCS DMI
--  Driver-entered data (chapter 11 data entry windows). Values live here
--  between windows and are reported to the EVC as MSG_DRIVER_DATA.

package DMI_Driver_Data is

   Max_Field_Len : constant := 12;

   type Text_Value_T is record
      Length : Natural := 0;
      Text   : Wide_String (1 .. Max_Field_Len) := (others => ' ');
   end record;

   Driver_ID  : Text_Value_T;             -- 11.3.3
   TRN        : Text_Value_T;             -- 11.3.1

   -- Fixed train data (11.3.9.8), simplified to the numeric items
   Train_Length : Natural := 0;           -- m
   Brake_Pct    : Natural := 0;           -- %
   Max_Speed    : Natural := 0;           -- km/h

   SR_Speed : Natural := 0;               -- 11.3.10
   SR_Dist  : Natural := 0;

   Driver_ID_Entered  : Boolean := False;
   Level_Entered      : Boolean := False;
   Train_Data_Entered : Boolean := False; -- set after validation
   TRN_Entered        : Boolean := False;

   procedure Reset;

end DMI_Driver_Data;
