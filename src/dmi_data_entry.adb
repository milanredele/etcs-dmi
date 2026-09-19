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
   --  the label and the data part of input field I (10.3.1.26, 10.3.1.22)
   Label_First : constant := 13;
   Data_First  : constant := Label_First + Max_Fields;
   --  'Yes' of the '[Window Title] entry complete?' question (Table 24)
   Yes_Button   : constant := Data_First + Max_Fields;
   Button_Total : constant := Yes_Button;

   --  Validation window (10.3.5.18): key 7 is 'No', key 8 is 'Yes'
   Key_No  : constant := 7;
   Key_Yes : constant := 8;

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   --  The six states of Figure 97 as three flags: 'selected' is
   --  Index = Current, Has_Value says whether a data value is displayed
   --  (10.3.5.9), Editing whether what is displayed is the value of the
   --  pressed key(s), and Accepted whether the driver accepted the value
   --  during this data entry / validation process (10.3.1.15, 10.3.3.5)
   type Field_State_T is record
      Value     : DMI_Driver_Data.Text_Value_T;
      Has_Value : Boolean := False;
      Editing   : Boolean := False;
      Accepted  : Boolean := False;
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
         Fields (I) := (Value     => Def.Fields (I).Proposed,
                        --  a proposed value is a data value that the
                        --  driver has not accepted yet (Figure 97)
                        Has_Value => Def.Fields (I).Proposed.Length > 0,
                        Editing   => False,
                        Accepted  => False);
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

   --  10.3.5.3 / 10.4.1.1: the window covers the A/B/C/D/E/F/G area
   --  (the validation window still uses the half grid array; it moves to
   --  the total grid array of Table 29 with audit WIN-7)
   function On_Total_Grid return Boolean is (Def.Layout = Total_Grid);

   function Covered_Area return Display.Area_T is
     (if On_Total_Grid then (Grid_Origin, Grid_Width, Grid_Height)
      else (Column_Origin, Column_Width, Grid_Height));

   --  Table 25: 12 keys of 102x50 in three columns from y 200 of D/F/G
   function Key_Area (Index : Positive) return Area_T is
     ((Column_Origin + (((Index - 1) mod 3) * 102,
                        200 + ((Index - 1) / 3) * 50),
       102, 50));

   --  10.3.1.7 / 10.3.5.5: a window with a single input field has no
   --  label area, the data part covers the width of the whole field
   function Has_Label_Area return Boolean is (Def.Field_Count > 1);

   --  Table 22 (half grid array) / Table 23 (total grid array). The Y
   --  locations of Table 23 are read from Figure 100: the first input
   --  field of a total grid array window sits at the top of the D/F/G
   --  column, as the input field of the validation window does in Table
   --  29, and the fourth one ends where Table 25 starts the keyboard.
   --  With the Y locations 50 .. 200 printed in Table 23 the fourth
   --  input field and the first keyboard row would overlap.
   function Field_Top (Index : Positive) return Natural is
     (case Def.Layout is
         when Half_Grid  => 50,
         when Total_Grid => (Index - 1) * 50,
         when Validation => 0);

   function Label_Area (Index : Positive) return Area_T is
     ((Column_Origin + (0, Field_Top (Index)), 204, 50));

   function Data_Area (Index : Positive) return Area_T is
     (if Has_Label_Area
      then (Column_Origin + (204, Field_Top (Index)), 102, 50)
      else (Column_Origin + (0, Field_Top (Index)), Column_Width, 50));

   function Field_Area (Index : Positive) return Area_T is
     (if Has_Label_Area
      then (Column_Origin + (0, Field_Top (Index)), Column_Width, 50)
      else Data_Area (Index));

   --  Validation window: [Yes] and [No] side by side above the close row
   --  (the layout of Table 29 arrives with audit WIN-7)
   function Validation_Button_Area (Index : Positive) return Area_T is
     ((Column_Origin + ((Index - 1) * 153, 350), 153, 50));

   --  Table 24: the question and the 'Yes' button in the A/B/C/E column
   Question_Area : constant Area_T := (Grid_Origin + (0, 350), 334, 50);
   Yes_Area      : constant Area_T := (Grid_Origin + (0, 400), 334, 50);

   --  10.3.5.9: 'Yes' is enabled when every input field of the topic
   --  displays a data value
   function All_Fields_Have_Values return Boolean is
   begin
      for I in 1 .. Def.Field_Count loop
         if not Fields (I).Has_Value then
            return False;
         end if;
      end loop;
      return Def.Field_Count > 0;
   end All_Fields_Have_Values;

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
            elsif Index in Label_First .. Label_First + Max_Fields - 1 then
               return Label_Area (Index - Label_First + 1);
            elsif Index in Data_First .. Data_First + Max_Fields - 1 then
               return Data_Area (Index - Data_First + 1);
            elsif Index = Yes_Button then
               --  10.3.5.8: the sensitive area of 'Yes' covers the
               --  question as well
               return (Question_Area.Position, 334, 100);
            end if;
         when Validation =>
            if Index in 1 .. 2 then
               return ((Column_Origin + ((Index - 1) * 153, 350), 153, 50));
            end if;
      end case;
      return ((0, 0), 0, 0);
   end Button_Area;

   function Button_Enabled (Index : Positive) return Boolean is
   begin
      case Def.Layout is
         when Half_Grid | Total_Grid =>
            if Index in Key_First .. Key_Last then
               return True;
            elsif Index = Yes_Button then
               --  Table 24 objects exist on the total grid array only
               return Def.Layout = Total_Grid
                 and then All_Fields_Have_Values;
            else
               --  the input fields become buttons with audit WIN-4
               return False;
            end if;
         when Validation =>
            return Index in 1 .. 2;
      end case;
   end Button_Enabled;

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
      --  10.3.5.11: the 'Yes' button is an up-type button
      return DMI_Buttons.Up_Type;
   end Button_Kind;

   ---------------------------------------------------------------------
   --  Behaviour
   ---------------------------------------------------------------------

   --  10.3.1.21, 10.3.1.24: the entered value replaces the current data
   --  value, the input field goes to the 'accepted' state and the next
   --  input field of the topic is selected. A window on the half grid
   --  array has no 'Yes' button (Table 24 belongs to the total grid
   --  array), so accepting its single value completes the entry
   --  (10.6.1.2 a read for a topic with one input field; this is what
   --  Tables 49 and 50 expect of the Driver ID and train running number
   --  windows).
   procedure Accept_Value is
   begin
      if Fields (Current).Value.Length = 0 then
         return; -- nothing to accept
      end if;
      Fields (Current).Has_Value := True;
      Fields (Current).Editing := False;
      Fields (Current).Accepted := True;
      if Def.Layout = Half_Grid then
         Completed := True;
      elsif Current < Def.Field_Count then
         Current := Current + 1;
      end if;
   end Accept_Value;

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
            Accept_Value;
         when others =>
            null;
      end case;
   end Key_Pressed;

   procedure Press (Index : Positive) is
   begin
      if not Open_Flag or else not Button_Enabled (Index) then
         return;
      end if;
      case Def.Layout is
         when Half_Grid | Total_Grid =>
            if Index in Key_First .. Key_Last then
               Key_Pressed (Index);
            elsif Index = Yes_Button then
               --  10.3.5.7: the driver confirms the data entry complete
               Completed := True;
            end if;
         when Validation =>
            --  10.4.1.2: the 'No'/'Yes' choice of the single input field
            if Index = 1 then
               Set_Text (Fields (1).Value, "Yes");
               Completed := True;
            elsif Index = 2 then
               Set_Text (Fields (1).Value, "No");
               Completed := True;
            end if;
      end case;
   end Press;

   ---------------------------------------------------------------------
   --  Rendering
   ---------------------------------------------------------------------

   procedure Draw_Title is
      --  Table 22: 306 cells over the D/F/G column; Tables 23 and 29:
      --  334 cells over the A/B/C/E column, right aligned (10.3.5.4,
      --  10.4.1.4)
      Total : constant Boolean := On_Total_Grid;
      The_Area : constant Area_T :=
        (if Total then (Grid_Origin, 334, Title_Height)
         else (Column_Origin, Column_Width, Title_Height));
   begin
      Screen.Fill_Area (The_Area, General_Parameters.BLACK);
      --  5.1.3.2: an indent of 3 cells from the limit of the area
      Draw.Draw_String
        (Pen_X      => (if Total then The_Area.Position.X + The_Area.Width - 3
                        else The_Area.Position.X + 3),
         Pen_Y      => The_Area.Position.Y + Title_Height - 6,
         The_String => Trim (Def.Title),
         The_Size   => 12,
         The_Color  => General_Parameters.GREY,
         The_Alignment => (if Total then Draw.Right else Draw.Left));
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

   procedure Draw_Entry_Field (Index : Field_Index_T) is
      use General_Parameters;
      The_Data  : constant Area_T := Data_Area (Index);
      Selected  : constant Boolean := Index = Current;
      State     : Field_State_T renames Fields (Index);
      --  Table 21: the background of the data area and the colour of the
      --  data value follow the state of the input field (10.3.1.13 to
      --  10.3.1.15)
      Back      : constant Color :=
        (if Selected then MEDIUM_GREY else DARK_GREY);
      Ink       : constant Color :=
        (if Selected then BLACK
         elsif State.Accepted then WHITE
         else GREY);
   begin
      if Has_Label_Area then
         --  10.3.1.12: grey text on a dark grey background; 10.3.1.10:
         --  right aligned with an indent of 10 cells
         Screen.Fill_Area (Label_Area (Index), DARK_GREY);
         Draw.Draw_String
           (Pen_X => Label_Area (Index).Position.X + 204 - 10,
            Pen_Y => Label_Area (Index).Position.Y + 50 / 2 + 6,
            The_String => Trim (Def.Fields (Index).Label),
            The_Size => 12,
            The_Color => GREY,
            The_Alignment => Draw.Right);
      end if;
      Screen.Fill_Area (The_Data, Back);
      --  5.1.1.1.4: the input field has a medium grey border
      Draw.Draw_Input_Field_Frame (Field_Area (Index));
      --  10.3.1.11: the data value is left aligned with an indent of 10
      Draw.Draw_String
        (Pen_X => The_Data.Position.X + 10,
         Pen_Y => The_Data.Position.Y + The_Data.Height / 2 + 6,
         The_String => State.Value.Text (1 .. State.Value.Length),
         The_Size => 12,
         The_Color => Ink);
   end Draw_Entry_Field;

   --  10.3.5.7, Table 24: the question and the 'Yes' button, only on the
   --  total grid array
   procedure Draw_Entry_Complete is
      use General_Parameters;
      Enabled : constant Boolean := All_Fields_Have_Values;
   begin
      --  The text and the label are centred in their 334 cell area as
      --  Figure 100 shows them (implementation choice: 5.1.3.1 would
      --  left align them, the figure is the only statement about this
      --  object's layout).
      Draw.Draw_String
        (Pen_X => Question_Area.Position.X + Question_Area.Width / 2,
         Pen_Y => Question_Area.Position.Y + Question_Area.Height / 2 + 6,
         The_String => Trim (Def.Title) & " entry complete?",
         The_Size => 12,
         The_Color => GREY,
         The_Alignment => Draw.Center);
      --  10.3.5.10: black label, dark grey background when disabled and
      --  medium grey when enabled, the border of an input field
      Screen.Fill_Area (Yes_Area, (if Enabled then MEDIUM_GREY
                                   else DARK_GREY));
      Draw.Draw_Input_Field_Frame (Yes_Area);
      Draw.Draw_String
        (Pen_X => Yes_Area.Position.X + Yes_Area.Width / 2,
         Pen_Y => Yes_Area.Position.Y + Yes_Area.Height / 2 + 6,
         The_String => "Yes",
         The_Size => 12,
         The_Color => BLACK,
         The_Alignment => Draw.Center);
   end Draw_Entry_Complete;

   --  10.3.3: the echo texts of the input fields, in the A/B/C/E area
   procedure Draw_Echo_Texts is
      use General_Parameters;
      --  10.3.3.7 / 10.3.3.9: right and left of the X position 204 with
      --  an indent of 5; 10.3.3.8 / 10.3.3.10: the first one 112 cells
      --  below the top of the area; 5.1.3.5: line spacing 2 x 12 cells
      First_Y : constant := 112;
      Step_Y  : constant := 24;
   begin
      for I in 1 .. Def.Field_Count loop
         declare
            Y : constant Natural :=
              Grid_Origin.Y + First_Y + (I - 1) * Step_Y;
            --  10.3.3.5: white once the driver accepted the value
            Ink : constant Color :=
              (if Fields (I).Accepted then WHITE else GREY);
         begin
            Draw.Draw_String
              (Pen_X => 204 - 5, Pen_Y => Y,
               The_String => Trim (Def.Fields (I).Label),
               The_Size => 12, The_Color => Ink,
               The_Alignment => Draw.Right);
            Draw.Draw_String
              (Pen_X => 204 + 5, Pen_Y => Y,
               The_String =>
                 Fields (I).Value.Text (1 .. Fields (I).Value.Length),
               The_Size => 12, The_Color => Ink);
         end;
      end loop;
   end Draw_Echo_Texts;

   procedure Draw_Data_Entry is
   begin
      for I in 1 .. Def.Field_Count loop
         Draw_Entry_Field (I);
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

      if Def.Layout = Total_Grid then
         --  10.3.5.6: the values are echoed on the A/B/C/E area
         Draw_Echo_Texts;
         Draw_Entry_Complete;
      end if;
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
