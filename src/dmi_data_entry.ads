--  ETCS DMI
--  Generic data entry engine (DMI 10.3) and data validation window
--  (10.4), touch screen technology.
--
--  DMI_Windows owns the window stack and the dialogue sequences; it
--  opens a window definition here, asks for the buttons of the current
--  state, forwards the presses, renders, and reads the entered values
--  back when the engine reports the entry complete. Nothing in this
--  package knows the windows of chapter 11.

with Display;
with DMI_Buttons;
with DMI_Driver_Data;

package DMI_Data_Entry is

   --  10.3.5.1: at most 4 input fields on the total grid array, one on
   --  the half grid array
   Max_Fields : constant := 4;
   subtype Field_Count_T is Natural range 0 .. Max_Fields;
   subtype Field_Index_T is Positive range 1 .. Max_Fields;

   Max_Label : constant := 24;
   subtype Label_T is Wide_String (1 .. Max_Label);

   --  10.3.5.12: the keyboard presented for the selected input field.
   --  The enhanced numeric keyboard (10.3.5.16), the alphanumeric one
   --  (10.3.5.17) and a dedicated keyboard with predefined choices
   --  (10.3.5.19) are further values of this type; each only adds its
   --  key labels and what a key press appends.
   type Keyboard_T is
     (Numeric,   -- 10.3.5.15
      Yes_No);   -- 10.3.5.18, dedicated keyboard limited to 'No'/'Yes'

   type Field_Def_T is record
      Label    : Label_T := (others => ' ');
      Keyboard : Keyboard_T := Numeric;
      Max_Len  : Natural := 5;
      --  11.7.1.4: the stored value is proposed in the input field
      Proposed : DMI_Driver_Data.Text_Value_T;
   end record;

   type Field_Def_List_T is array (Field_Index_T) of Field_Def_T;

   --  10.3.5.2 / 10.3.5.3 / 10.4.1.1
   type Layout_T is
     (Half_Grid,    -- Table 22: D/F/G, a single input field
      Total_Grid,   -- Tables 23, 24, 25: A/B/C/D/E/F/G, echo texts
      Validation);  -- Table 29: A/B/C/D/E/F/G, 'No'/'Yes' choice

   type Window_Def_T is record
      Layout      : Layout_T := Half_Grid;
      Title       : Label_T := (others => ' ');
      Field_Count : Field_Count_T := 0;
      Fields      : Field_Def_List_T;
   end record;

   --  Build a window title / one field definition; the text is padded,
   --  a longer text is cut
   function Window_Title (Text : Wide_String) return Label_T;

   function Field
     (Label    : Wide_String;
      Max_Len  : Natural;
      Keyboard : Keyboard_T := Numeric;
      Proposed : DMI_Driver_Data.Text_Value_T := (0, (others => ' ')))
      return Field_Def_T;

   --  10.6.1.1: a data entry / validation process starts with the first
   --  window of the topic
   procedure Open (Definition : Window_Def_T);

   function Is_Open return Boolean;

   --  The area the window covers (the background to fill): D/F/G for the
   --  half grid array, the whole grid for the total grid array
   function Covered_Area return Display.Area_T;

   --  Window-internal buttons for the registry of DMI_Core; a button not
   --  enabled is not registered (5.3.2.7.5)
   function Button_Count return Natural;
   function Button_Area (Index : Positive) return Display.Area_T;
   function Button_Enabled (Index : Positive) return Boolean;
   function Button_Kind (Index : Positive) return DMI_Buttons.Kind_T;

   procedure Press (Index : Positive);

   --  True once, when the driver completed the entry (the values are
   --  then read with Value / Number)
   function Take_Completion return Boolean;

   function Value (Index : Field_Index_T) return DMI_Driver_Data.Text_Value_T;

   --  The value as a number; a value that is not a number gives 0, a
   --  value above 99999 is clamped (total, never raises)
   function Number (Index : Field_Index_T) return Natural;

   procedure Render;

end DMI_Data_Entry;
