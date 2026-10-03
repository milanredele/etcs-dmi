--  DMI observation for the test runners, body.

pragma Ada_2012;
with DMI_Data_Entry;
with DMI_Driver_Data;

package body DMI_Observe is

   use DMI_Windows;

   function Latin_1 (V : DMI_Driver_Data.Text_Value_T) return String is
      N : constant Natural := Natural'Min (V.Length, V.Text'Length);
      R : String (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) :=
           (if Wide_Character'Pos (V.Text (I)) < 256
            then Character'Val (Wide_Character'Pos (V.Text (I))) else '?');
      end loop;
      return R;
   end Latin_1;

   function Entry_Shown (W : Window_ID_T) return Boolean is
     (Is_Open and then Top = W and then Entry_Open);

   function Field_Value (W : Window_ID_T) return String is
     (if Entry_Shown (W) then Latin_1 (DMI_Data_Entry.Value (1)) else "");

   function Stored_Value (W : Window_ID_T) return String is
     (if W = W_TRN then Latin_1 (DMI_Driver_Data.TRN)
      else Latin_1 (DMI_Driver_Data.Driver_ID));

end DMI_Observe;
