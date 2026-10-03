--  DMI observation for the test runners (host only): what the DMI shows
--  as data, read from the window model of DMI_Core (DMI_Windows,
--  DMI_Data_Entry, DMI_Driver_Data) without rendering a pixel. Nothing
--  under dmi/ depends on it.

pragma Ada_2012;
with DMI_Windows;

package DMI_Observe is

   --  The data entry windows whose input field shows a stored data value
   --  (DMI 11.3.1.4, 11.3.3.4, 11.7.1.4: the current value is proposed
   --  in the input field)
   function Has_Data_Value (W : DMI_Windows.Window_ID_T) return Boolean is
     (W in DMI_Windows.W_TRN | DMI_Windows.W_Driver_ID);

   --  W is displayed (the top window) with its data entry open
   function Entry_Shown (W : DMI_Windows.Window_ID_T) return Boolean;

   --  The value the input field of W shows (Latin-1, "" when empty); ""
   --  when W is not displayed
   function Field_Value (W : DMI_Windows.Window_ID_T) return String;

   --  The value the DMI holds for the topic of W, the one the input field
   --  must show when the window opens ("" when unknown)
   function Stored_Value (W : DMI_Windows.Window_ID_T) return String
     with Pre => Has_Data_Value (W);

end DMI_Observe;
