--  ETCS DMI
--  Data entry engine implementation (DMI 10.3, 10.4).

pragma Ada_2012;
with Display.Draw;
with Display.Screen;
with General_Parameters;

package body DMI_Data_Entry is

   use Display;

   --  The D/F/G column, origin of the half grid array layouts (Table 22)
   Column_Origin : constant Position_T := Get_Area (D).Position; -- (334, 15)
   Column_Width  : constant := 306;

   --  Origin of the total grid array layouts (Tables 23, 24, 29): the
   --  whole grid, the Z and Y strips excluded
   Grid_Origin : constant Position_T := (0, Get_Area (Z).Height); -- (0, 15)
   Grid_Width  : constant := 640;
   Grid_Height : constant := 450;

   Title_Height : constant := 24; -- 5.3.1.2.2

   --  Button indices towards DMI_Core, through DMI_Windows
   Key_First  : constant := 1;   -- Table 25, keyboard keys 1 .. 12
   Key_Last   : constant := 12;
   Key_Delete : constant := 10;  -- 10.3.5.15
   Key_Zero   : constant := 11;
   Key_Enter  : constant := 12;
   Button_Total : constant := 12;

   --  Validation window buttons
   Validation_Yes : constant := 1;
   Validation_No  : constant := 2;

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   type Field_State_T is record
      Value : DMI_Driver_Data.Text_Value_T;
   end record;

   type Field_State_List_T is array (Field_Index_T) of Field_State_T;

   Def       : Window_Def_T;
   Open_Flag : Boolean := False;
   Current   : Field_Index_T := 1;
   Fields    : Field_State_List_T;
   Completed : Boolean := False;

   ---------------------------------------------------------------------
   --  Helpers
   ---------------------------------------------------------------------

   function Pad (S : Wide_String) return Label_T is
      Result : Label_T := (others => ' ');
      Last   : constant Natural := Natural'Min (S'Length, Max_Label);
   begin
      Result (1 .. Last) := S (S'First .. S'First + Last - 1);
      return Result;
   end Pad;

   function Trim (S : Wide_String) return Wide_String is
      Last : Natural := S'Last;
   begin
      while Last >= S'First and then S (Last) = ' ' loop
         Last := Last - 1;
      end loop;
      return S (S'First .. Last);
   end Trim;

   procedure Set_Text (V : in out DMI_Driver_Data.Text_Value_T;
                       S : Wide_String) is
      Last : constant Natural :=
        Natural'Min (S'Length, DMI_Driver_Data.Max_Field_Len);
   begin
      V.Length := Last;
      V.Text := (others => ' ');
      V.Text (1 .. Last) := S (S'First .. S'First + Last - 1);
   end Set_Text;

   --  The window buttons are registered as BTN_Menu_1 .. BTN_Menu_n by
   --  DMI_Core, in the order of the indices used here
   function Pressed (Index : Positive) return Boolean is
     (Index <= Button_Total
      and then DMI_Buttons.Is_Pressed
        (DMI_Buttons.Button_ID_T'Val
           (DMI_Buttons.Button_ID_T'Pos (DMI_Buttons.BTN_Menu_1)
            + Index - 1)));

   function Window_Title (Text : Wide_String) return Label_T is (Pad (Text));

   function Field
     (Label    : Wide_String;
      Max_Len  : Natural;
      Keyboard : Keyboard_T := Numeric;
      Proposed : DMI_Driver_Data.Text_Value_T := (0, (others => ' ')))
      return Field_Def_T is
   begin
      return (Label    => Pad (Label),
              Keyboard => Keyboard,
              Max_Len  => Natural'Min (Max_Len, DMI_Driver_Data.Max_Field_Len),
              Proposed => Proposed);
   end Field;

   ---------------------------------------------------------------------
   --  Opening and result
   ---------------------------------------------------------------------

   procedure Open (Definition : Window_Def_T) is
   begin
      Def := Definition;
      Open_Flag := True;
      Completed := False;
      --  10.3.1.23: the first input field is selected, the others are not
      Current := 1;
      for I in Field_Index_T loop
         Fields (I) := (Value => Def.Fields (I).Proposed);
      end loop;
   end Open;

   function Is_Open return Boolean is (Open_Flag);

   function Take_Completion return Boolean is
      Result : constant Boolean := Completed;
   begin
      Completed := False;
      return Result;
   end Take_Completion;

   function Value (Index : Field_Index_T)
                   return DMI_Driver_Data.Text_Value_T is
     (Fields (Index).Value);

   function Number (Index : Field_Index_T) return Natural is
      V      : DMI_Driver_Data.Text_Value_T renames Fields (Index).Value;
      Result : Natural := 0;
   begin
      for I in 1 .. V.Length loop
         if V.Text (I) in '0' .. '9' then
            Result := Result * 10
              + (Wide_Character'Pos (V.Text (I)) - Wide_Character'Pos ('0'));
            if Result > 99999 then
               return 99999;
            end if;
         end if;
      end loop;
      return Result;
   end Number;

   ---------------------------------------------------------------------
   --  Geometry
   ---------------------------------------------------------------------

   function Covered_Area return Display.Area_T is
     (case Def.Layout is
         --  the validation window still uses the half grid array; it
         --  moves to the total grid array with audit WIN-7
         when Half_Grid | Validation =>
            (Column_Origin, Column_Width, Grid_Height),
         when Total_Grid =>
            (Grid_Origin, Grid_Width, Grid_Height));

   --  Table 25: 12 keys of 102x50 in three columns from y 200 of D/F/G
   function Key_Area (Index : Positive) return Area_T is
     ((Column_Origin + (((Index - 1) mod 3) * 102,
                        200 + ((Index - 1) / 3) * 50),
       102, 50));

   --  Table 22: input field 1 on the half grid array, label and data
   --  part merged when the window has a single field (10.3.5.5)
   function Field_Area (Index : Positive) return Area_T is
     ((Column_Origin + (0, 50 + (Index - 1) * 50), Column_Width, 50));

   --  Validation window: [Yes] and [No] side by side above the close row
   function Validation_Button_Area (Index : Positive) return Area_T is
     ((Column_Origin + ((Index - 1) * 153, 350), 153, 50));

   function Button_Count return Natural is
     (case Def.Layout is
         when Half_Grid | Total_Grid => Button_Total,
         when Validation             => 2);

   function Button_Area (Index : Positive) return Display.Area_T is
   begin
      case Def.Layout is
         when Half_Grid | Total_Grid =>
            if Index in Key_First .. Key_Last then
               return Key_Area (Index);
            end if;
         when Validation =>
            if Index in 1 .. 2 then
               return Validation_Button_Area (Index);
            end if;
      end case;
      return ((0, 0), 0, 0);
   end Button_Area;

   function Button_Enabled (Index : Positive) return Boolean is
     (Index <= Button_Count);

   function Button_Kind (Index : Positive) return DMI_Buttons.Kind_T is
   begin
      case Def.Layout is
         when Half_Grid | Total_Grid =>
            --  5.3.2.7.2: [Delete] is a down-type button with repeat
            if Index = Key_Delete then
               return DMI_Buttons.Down_Type;
            end if;
         when Validation =>
            null;
      end case;
      return DMI_Buttons.Up_Type;
   end Button_Kind;

   ---------------------------------------------------------------------
   --  Behaviour
   ---------------------------------------------------------------------

   procedure Key_Pressed (Index : Positive) is
      V : DMI_Driver_Data.Text_Value_T renames Fields (Current).Value;
      F : Field_Def_T renames Def.Fields (Current);

      procedure Append (C : Wide_Character) is
      begin
         if V.Length < F.Max_Len then
            V.Length := V.Length + 1;
            V.Text (V.Length) := C;
         end if;
      end Append;
   begin
      case Index is
         when 1 .. 9 =>
            Append (Wide_Character'Val (Wide_Character'Pos ('0') + Index));
         when Key_Zero =>
            Append ('0');
         when Key_Delete =>
            if V.Length > 0 then
               V.Length := V.Length - 1;
            end if;
         when Key_Enter =>
            --  10.3.1.21, 10.3.1.24: [Enter] accepts the entered value
            --  and the next input field is selected
            if V.Length > 0 then
               if Current < Def.Field_Count then
                  Current := Current + 1;
               else
                  Completed := True;
               end if;
            end if;
         when others =>
            null;
      end case;
   end Key_Pressed;

   procedure Press (Index : Positive) is
   begin
      if not Open_Flag then
         return;
      end if;
      case Def.Layout is
         when Half_Grid | Total_Grid =>
            if Index in Key_First .. Key_Last then
               Key_Pressed (Index);
            end if;
         when Validation =>
            --  10.4.1.2: the 'No'/'Yes' choice of the single input field
            if Index = Validation_Yes then
               Set_Text (Fields (1).Value, "Yes");
               Completed := True;
            elsif Index = Validation_No then
               Set_Text (Fields (1).Value, "No");
               Completed := True;
            end if;
      end case;
   end Press;

   ---------------------------------------------------------------------
   --  Rendering
   ---------------------------------------------------------------------

   procedure Draw_Title is
   begin
      Screen.Fill_Area ((Column_Origin, Column_Width, Title_Height),
                        General_Parameters.BLACK);
      Draw.Draw_String (Pen_X      => Column_Origin.X + 3,
                        Pen_Y      => Column_Origin.Y + Title_Height - 6,
                        The_String => Trim (Def.Title),
                        The_Size   => 12,
                        The_Color  => General_Parameters.GREY);
   end Draw_Title;

   procedure Draw_Labelled_Button (The_Area : Area_T;
                                   Label    : Wide_String;
                                   Enabled  : Boolean;
                                   Is_Down  : Boolean) is
   begin
      if not Is_Down then
         Draw.Draw_Button_Frame (The_Area);
      end if;
      --  5.3.2.5.5 / 10.2.1.4: disabled labels in dark grey
      Draw.Draw_String
        (Pen_X => The_Area.Position.X + The_Area.Width / 2,
         Pen_Y => The_Area.Position.Y + The_Area.Height / 2 + 6,
         The_String => Label,
         The_Size => 12,
         The_Color => (if Enabled then General_Parameters.GREY
                       else General_Parameters.DARK_GREY),
         The_Alignment => Draw.Center);
   end Draw_Labelled_Button;

   procedure Draw_Entry_Field (The_Area : Area_T;
                               Label    : Wide_String;
                               Val      : Wide_String;
                               Selected : Boolean) is
      Data_Area : constant Area_T :=
        (The_Area.Position + (The_Area.Width / 2, 0),
         The_Area.Width / 2, The_Area.Height);
   begin
      --  10.3.1 / Table 21: label part; data part grey with black text
      --  while selected, dark grey with white text once accepted
      Draw.Draw_Input_Field_Frame (The_Area);
      Draw.Draw_String
        (Pen_X => The_Area.Position.X + 3,
         Pen_Y => The_Area.Position.Y + The_Area.Height / 2 + 6,
         The_String => Label,
         The_Size => 12,
         The_Color => General_Parameters.GREY);
      Screen.Fill_Area (Data_Area,
                        (if Selected then General_Parameters.GREY
                         else General_Parameters.DARK_GREY));
      Draw.Draw_String
        (Pen_X => Data_Area.Position.X + 3,
         Pen_Y => Data_Area.Position.Y + Data_Area.Height / 2 + 6,
         The_String => Val,
         The_Size => 12,
         The_Color => (if Selected then General_Parameters.BLACK
                       else General_Parameters.WHITE));
   end Draw_Entry_Field;

   procedure Draw_Data_Entry is
   begin
      for I in 1 .. Def.Field_Count loop
         Draw_Entry_Field
           (Field_Area (I),
            Trim (Def.Fields (I).Label),
            Fields (I).Value.Text (1 .. Fields (I).Value.Length),
            Selected => I = Current);
      end loop;

      for Key in Key_First .. Key_Last loop
         declare
            Label : constant Wide_String :=
              (case Key is
                  when 1 .. 9     => Natural'Wide_Image (Key) (2 .. 2) & "",
                  when Key_Zero   => "0",
                  when Key_Delete => "Del",
                  when Key_Enter  => "Enter",
                  when others     => "");
         begin
            Draw_Labelled_Button (Key_Area (Key), Label,
                                  Enabled => True,
                                  Is_Down => Pressed (Key));
         end;
      end loop;
   end Draw_Data_Entry;

   procedure Draw_Text_Line (Line : Natural; Text : Wide_String) is
   begin
      Draw.Draw_String
        (Pen_X => Column_Origin.X + 6,
         Pen_Y => Column_Origin.Y + 50 + Line * 24,
         The_String => Text,
         The_Size => 12,
         The_Color => General_Parameters.GREY);
   end Draw_Text_Line;

   function Num_Image (N : Natural) return Wide_String is
      Img : constant Wide_String := Natural'Wide_Image (N);
   begin
      return Img (2 .. Img'Last);
   end Num_Image;

   procedure Draw_Validation is
      use DMI_Driver_Data;
   begin
      --  11.4.1: echo of the entered values with [Yes] / [No]
      Draw_Text_Line (1, "Length: " & Num_Image (Train_Length) & " m");
      Draw_Text_Line (2, "Brake percentage: " & Num_Image (Brake_Pct) & " %");
      Draw_Text_Line (3, "Max speed: " & Num_Image (Max_Speed) & " km/h");
      Draw_Labelled_Button (Validation_Button_Area (1), "Yes",
                            True, Pressed (1));
      Draw_Labelled_Button (Validation_Button_Area (2), "No",
                            True, Pressed (2));
   end Draw_Validation;

   procedure Render is
   begin
      if not Open_Flag then
         return;
      end if;
      Draw_Title;
      case Def.Layout is
         when Half_Grid | Total_Grid => Draw_Data_Entry;
         when Validation             => Draw_Validation;
      end case;
   end Render;

end DMI_Data_Entry;
