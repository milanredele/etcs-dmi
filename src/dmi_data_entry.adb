--  ETCS DMI
--  Data entry engine implementation (DMI 10.3, 10.4).

pragma Ada_2012;
with Display.Draw;
with Display.Screen;
with DMI_Flash;
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
   Key_Dot    : constant := 12;
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
   --  10.3.4: the outcome of the last data check of this input field,
   --  which is what its echo text shows instead of the data value
   type Check_State_T is
     (No_Check,
      Technical_Range,       -- 10.3.4.2.2: '++++' in red
      Technical_Resolution,  -- 10.3.4.3.2: '++++' in red
      Operational_Range,     -- 10.3.4.5.2: '++++' in yellow
      Failed_Technical_Cross,    -- 10.3.4.4.2: '????' in red
      Failed_Operational_Cross); -- 10.3.4.6.2: '????' in yellow

   type Field_State_T is record
      Value     : DMI_Driver_Data.Text_Value_T;
      Has_Value : Boolean := False;
      Editing   : Boolean := False;
      Accepted  : Boolean := False;
      Check     : Check_State_T := No_Check;
   end record;

   type Field_State_List_T is array (Field_Index_T) of Field_State_T;

   Def       : Window_Def_T;
   Open_Flag : Boolean := False;
   Current   : Field_Index_T := 1;
   Fields    : Field_State_List_T;
   Completed : Boolean := False;

   --  10.3.4.4.4 / 10.3.4.6.4: the cross-check rule the 'Yes' button of
   --  the '[Window Title] entry complete?' question last failed
   Cross_Failed : Cross_Kind_T := No_Cross;

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

   function Echo
     (Label    : Wide_String;
      Value    : DMI_Driver_Data.Text_Value_T;
      Accepted : Boolean := True) return Echo_Item_T is
     ((Label => Pad (Label), Value => Value, Accepted => Accepted));

   function Field
     (Label    : Wide_String;
      Max_Len  : Natural;
      Keyboard : Keyboard_T := Numeric;
      Proposed : DMI_Driver_Data.Text_Value_T := (0, (others => ' '));
      Technical   : Check_Rule_T := No_Rule;
      Operational : Check_Rule_T := No_Rule)
      return Field_Def_T is
   begin
      return (Label    => Pad (Label),
              Keyboard => Keyboard,
              Max_Len  => Natural'Min (Max_Len, DMI_Driver_Data.Max_Field_Len),
              Proposed => Proposed,
              Technical => Technical,
              Operational => Operational);
   end Field;

   ---------------------------------------------------------------------
   --  Opening and result
   ---------------------------------------------------------------------

   procedure Open (Definition : Window_Def_T) is
   begin
      Def := Definition;
      Open_Flag := True;
      Completed := False;
      Cross_Failed := No_Cross;
      --  10.3.1.23: the first input field is selected, the others are not
      Current := 1;
      DMI_Flash.Restart_Cursor;
      for I in Field_Index_T loop
         Fields (I) := (Value     => Def.Fields (I).Proposed,
                        --  a proposed value is a data value that the
                        --  driver has not accepted yet (Figure 97)
                        Has_Value => Def.Fields (I).Proposed.Length > 0,
                        Editing   => False,
                        Accepted  => False,
                        Check     => No_Check);
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
            --  8 digits is the longest numeric data of chapter 11 (the
            --  train running number, SUBSET-026 7.5.1.92)
            if Result > 99_999_999 then
               return 99_999_999;
            end if;
         end if;
      end loop;
      return Result;
   end Number;

   ---------------------------------------------------------------------
   --  Geometry
   ---------------------------------------------------------------------

   --  10.3.5.3 / 10.4.1.1: the window covers the A/B/C/D/E/F/G area
   function On_Total_Grid return Boolean is (Def.Layout /= Half_Grid);

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

   function Button_Count return Natural is (Button_Total);

   function Button_Area (Index : Positive) return Display.Area_T is
   begin
      if Index in Key_First .. Key_Last then
         --  Table 29 places the 'No' and 'Yes' keys of the validation
         --  window where Table 25 places the keys 7 and 8 (10.3.5.18)
         return Key_Area (Index);
      elsif Index in Label_First .. Label_First + Max_Fields - 1 then
         return Label_Area (Index - Label_First + 1);
      elsif Index in Data_First .. Data_First + Max_Fields - 1 then
         return Data_Area (Index - Data_First + 1);
      elsif Index = Yes_Button then
         --  10.3.5.8: the sensitive area of 'Yes' covers the question
         return (Question_Area.Position, 334, 100);
      end if;
      return ((0, 0), 0, 0);
   end Button_Area;

   --  10.3.5.15: the keys 1 to 11 hold '1' to '9', the [delete] and the
   --  number '0'; the key 12 shows the '.' button as disabled
   function Key_Enabled (Index : Positive) return Boolean is
     (case Def.Fields (Current).Keyboard is
         when Numeric => Index /= Key_Dot,
         --  10.3.5.18: a dedicated keyboard limited to a 'No'/'Yes'
         --  choice has the key 7 as 'No' and the key 8 as 'Yes'
         when Yes_No  => Index in Key_No | Key_Yes);

   function Button_Enabled (Index : Positive) return Boolean is
   begin
      if Index in Key_First .. Key_Last then
         return Key_Enabled (Index);
      elsif Index in Label_First .. Label_First + Max_Fields - 1 then
         --  10.3.1.26: the label part selects the input field; a single
         --  input field has no label part (10.3.1.7)
         return Has_Label_Area
           and then Index - Label_First + 1 <= Def.Field_Count;
      elsif Index in Data_First .. Data_First + Max_Fields - 1 then
         if Index - Data_First + 1 > Def.Field_Count then
            return False;
         end if;
         --  10.3.4.2.4, 10.3.4.3.4: the [Enter] button, which is the
         --  data field of the selected input field, is disabled until
         --  the state of the input field switches to 'value of pressed
         --  key(s)'. The data part of another input field still selects
         --  it, which is no navigation button.
         return Index - Data_First + 1 /= Current
           or else Fields (Current).Check not in Technical_Range
                                               | Technical_Resolution;
      elsif Index = Yes_Button then
         --  Table 24 objects exist on the total grid array only;
         --  10.3.4.4.4: disabled while a technical cross-check fails
         return Def.Layout = Total_Grid
           and then All_Fields_Have_Values
           and then Cross_Failed /= Technical_Cross;
      end if;
      return False;
   end Button_Enabled;

   function Button_Kind (Index : Positive) return DMI_Buttons.Kind_T is
   begin
      --  10.3.5.13: the buttons of the keyboard are down-type buttons;
      --  5.3.2.7.2 gives [Delete] the repeat function, which 5.3.2.6.5
      --  leaves optional for the other keys
      if Index in Key_First .. Key_Last then
         return DMI_Buttons.Down_Type;
      end if;
      --  5.3.2.7.3, 10.3.4.5.5: the [Enter] button is up-type unless an
      --  operational data check rule is not satisfied, where it becomes
      --  a delay-type button so that the driver can overrule it
      if Index = Data_First + Current - 1
        and then Fields (Current).Check = Operational_Range
      then
         return DMI_Buttons.Delay_Type;
      end if;
      --  10.3.4.6.4: likewise the 'Yes' button of the question
      if Index = Yes_Button and then Cross_Failed = Operational_Cross then
         return DMI_Buttons.Delay_Type;
      end if;
      --  10.3.5.11 / 10.3.1.26: up-type otherwise
      return DMI_Buttons.Up_Type;
   end Button_Kind;

   ---------------------------------------------------------------------
   --  Behaviour
   ---------------------------------------------------------------------

   ---------------------------------------------------------------------
   --  Data checks (10.3.4)
   ---------------------------------------------------------------------

   --  10.3.4.2: the value of an input field is out of its technical
   --  permitted range
   function In_Range (Rule : Check_Rule_T; Val : Natural) return Boolean is
     (not Rule.Defined or else (Val >= Rule.Min and then Val <= Rule.Max));

   --  10.3.4.3: the value does not match its technical resolution
   function Matches_Resolution (Rule : Check_Rule_T;
                                Val  : Natural) return Boolean is
     (not Rule.Defined or else Rule.Resolution <= 1
      or else Val mod Rule.Resolution = 0);

   --  Figure 98: the checks of one input field, in sequence, when the
   --  driver accepts its value. No_Check means every rule is satisfied.
   function Check_Field (Index : Field_Index_T) return Check_State_T is
      F   : Field_Def_T renames Def.Fields (Index);
      Val : constant Natural := Number (Index);
   begin
      if not In_Range (F.Technical, Val) then
         return Technical_Range;
      elsif not Matches_Resolution (F.Technical, Val) then
         return Technical_Resolution;
      --  10.3.4.5.1: the operational check runs only when the technical
      --  one, if any, is satisfied
      elsif not In_Range (F.Operational, Val) then
         return Operational_Range;
      end if;
      return No_Check;
   end Check_Field;

   function Rule_Holds (Rule : Cross_Rule_T) return Boolean is
     (Rule.A > Def.Field_Count or else Rule.B > Def.Field_Count
      or else (case Rule.Relation is
                  when Not_Greater => Number (Rule.A) <= Number (Rule.B),
                  when Not_Less    => Number (Rule.A) >= Number (Rule.B)));

   --  10.3.4.4.1 / 10.3.4.6.1: on a valid activation of the 'Yes'
   --  button the cross-check rules are executed in sequence, the
   --  technical ones first and the operational ones only if every
   --  technical one is satisfied. The first failing rule marks the input
   --  fields it concerns; No_Cross means all rules are satisfied.
   function Run_Cross_Checks (Kind : Cross_Kind_T) return Boolean is
      Mark : constant Check_State_T :=
        (if Kind = Technical_Cross then Failed_Technical_Cross
         else Failed_Operational_Cross);
   begin
      for R of Cross_Rules loop
         if R.Kind = Kind and then not Rule_Holds (R) then
            Fields (R.A).Check := Mark;
            Fields (R.B).Check := Mark;
            return False;
         end if;
      end loop;
      return True;
   end Run_Cross_Checks;

   --  10.3.1.21, 10.3.1.24: the entered value replaces the current data
   --  value, the input field goes to the 'accepted' state and the next
   --  input field of the topic is selected. A window on the half grid
   --  array has no 'Yes' button (Table 24 belongs to the total grid
   --  array), so accepting its single value completes the entry
   --  (10.6.1.2 a read for a topic with one input field; this is what
   --  Tables 49 and 50 expect of the Driver ID and train running number
   --  windows).
   procedure Accept_Value is
      S : Field_State_T renames Fields (Current);
   begin
      if S.Value.Length = 0 then
         return; -- nothing to accept
      end if;
      if S.Check = Operational_Range then
         --  10.3.4.5.6: a valid activation of the delay-type [Enter]
         --  makes the entered value permitted
         S.Check := No_Check;
      else
         S.Check := Check_Field (Current);
         if S.Check /= No_Check then
            --  10.3.4.2.3, 10.3.4.3.3, 10.3.4.5.3: the input field stays
            --  selected and still shows the entered data value
            return;
         end if;
      end if;
      S.Has_Value := True;
      S.Editing := False;
      S.Accepted := True;
      --  10.3.4.4.4: a modified data value re-enables the 'Yes' button
      Cross_Failed := No_Cross;
      for I in Field_Index_T loop
         if Fields (I).Check in Failed_Technical_Cross
                              | Failed_Operational_Cross
         then
            Fields (I).Check := No_Check;
         end if;
      end loop;
      if Def.Layout /= Total_Grid then
         --  10.6.1.3 a for the validation window; a half grid array
         --  window has no 'Yes' button either
         Completed := True;
      elsif Def.Field_Count > 0 then
         --  10.3.1.25: the list of input fields is circular
         Current := (if Current < Def.Field_Count then Current + 1 else 1);
         DMI_Flash.Restart_Cursor;
      end if;
   end Accept_Value;

   --  10.3.1.26: the driver selects a specific input field by activating
   --  its label or data part
   procedure Select_Field (Index : Field_Index_T) is
   begin
      if Index = Current or else Index > Def.Field_Count then
         return;
      end if;
      --  10.3.1.20: an input field left while a value was entered or
      --  modified without accepting it loses the entered value and its
      --  current data value (Figure 97: 'Not Selected IF / No data
      --  value')
      if Fields (Current).Editing then
         Fields (Current) := (Value     => (0, (others => ' ')),
                              Has_Value => False,
                              Editing   => False,
                              Accepted  => False,
                              Check     => No_Check);
      end if;
      Current := Index;
      DMI_Flash.Restart_Cursor;
   end Select_Field;

   procedure Key_Pressed (Index : Positive) is
      S : Field_State_T renames Fields (Current);
      F : Field_Def_T renames Def.Fields (Current);

      procedure Append (C : Wide_Character) is
      begin
         if S.Value.Length < F.Max_Len then
            S.Value.Length := S.Value.Length + 1;
            S.Value.Text (S.Value.Length) := C;
         end if;
      end Append;
   begin
      --  10.3.1.19: after the first press on a data key the value
      --  corresponding to the pressed key is displayed instead of the
      --  data value. [Delete] deletes "the just entered character"
      --  (5.3.2.7.1 e), so with no entry of its own it has nothing to
      --  delete; Figure 97 has it leave the data value all the same
      --  ("one key of the keyboard pressed"), and the field then shows
      --  an empty entry (implementation choice).
      if not S.Editing then
         S.Value.Length := 0;
         S.Editing := True;
         S.Has_Value := False;
      end if;
      --  Figure 98: a key press takes the input field back to 'Selected
      --  IF / value of pressed key(s)', where [Enter] is enabled and
      --  up-type again (10.3.4.2.4, 10.3.4.3.4, 10.3.4.5.4)
      S.Check := No_Check;
      case F.Keyboard is
         when Numeric =>
            case Index is
               when 1 .. 9 =>
                  Append
                    (Wide_Character'Val (Wide_Character'Pos ('0') + Index));
               when Key_Zero =>
                  Append ('0');
               when Key_Delete =>
                  if S.Value.Length > 0 then
                     S.Value.Length := S.Value.Length - 1;
                  end if;
               when others =>
                  null;
            end case;
         when Yes_No =>
            --  10.3.5.18: a key of a dedicated keyboard carries the
            --  whole predefined choice, not one character
            if Index = Key_No then
               Set_Text (S.Value, "No");
            elsif Index = Key_Yes then
               Set_Text (S.Value, "Yes");
            end if;
      end case;
      --  10.3.2.4: the cursor jumps to the next position as soon as the
      --  entry is echoed
      DMI_Flash.Restart_Cursor;
   end Key_Pressed;

   procedure Press (Index : Positive) is
   begin
      if not Open_Flag or else not Button_Enabled (Index) then
         return;
      end if;
      if Index in Key_First .. Key_Last then
         Key_Pressed (Index);
      elsif Index in Label_First .. Label_First + Max_Fields - 1 then
         Select_Field (Index - Label_First + 1);
      elsif Index in Data_First .. Data_First + Max_Fields - 1 then
         --  10.3.1.22: the [Enter] button of the selected input field is
         --  its data field; the data part of another input field selects
         --  it (10.3.1.26)
         if Index - Data_First + 1 = Current then
            Accept_Value;
         else
            Select_Field (Index - Data_First + 1);
         end if;
      elsif Index = Yes_Button then
         --  10.3.5.7: the driver confirms the data entry complete
         if Cross_Failed = Operational_Cross then
            --  10.3.4.6.5: a valid activation of the delay-type 'Yes'
            --  makes the values concerned permitted
            Cross_Failed := No_Cross;
            for I in Field_Index_T loop
               if Fields (I).Check = Failed_Operational_Cross then
                  Fields (I).Check := No_Check;
               end if;
            end loop;
            Completed := True;
         elsif not Run_Cross_Checks (Technical_Cross) then
            Cross_Failed := Technical_Cross;
         elsif not Run_Cross_Checks (Operational_Cross) then
            Cross_Failed := Operational_Cross;
         else
            Completed := True;
         end if;
      end if;
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

   --  5.1.3.3: a text is vertically centred in its area; the pen is on
   --  the base line of the 12 cell characters
   function Base_Y (The_Area : Area_T) return Natural is
     (The_Area.Position.Y + The_Area.Height / 2 + 6);

   --  10.3.2.1 to 10.3.2.3: an underscore below the position of the next
   --  character, flashing at 2 Hz. The next character goes after what
   --  the driver entered; when the input field still shows a data value
   --  the next key replaces it (10.3.1.19), so the cursor stands at the
   --  first position (implementation choice, the clause is silent).
   procedure Draw_Cursor (Index : Field_Index_T) is
      The_Data : constant Area_T := Data_Area (Index);
      State    : Field_State_T renames Fields (Index);
      Shown    : constant Natural :=
        (if State.Editing then State.Value.Length else 0);
      Cell     : constant Natural := Draw.String_Width ("0", 12);
      X        : constant Natural :=
        The_Data.Position.X + 10
          + Draw.String_Width (State.Value.Text (1 .. Shown), 12);
      Y        : constant Natural := Base_Y (The_Data) + 2;
   begin
      if not DMI_Flash.Cursor_Visible
        or else X + Cell > The_Data.Position.X + The_Data.Width
      then
         return;
      end if;
      Screen.Fill_Area (((X, Y), Cell, 1),
                        (if Index = Current then General_Parameters.BLACK
                         else General_Parameters.GREY));
   end Draw_Cursor;

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
         Pen_Y => Base_Y (The_Data),
         The_String => State.Value.Text (1 .. State.Value.Length),
         The_Size => 12,
         The_Color => Ink);
      if Selected and then Def.Fields (Index).Keyboard /= Yes_No then
         Draw_Cursor (Index);
      end if;
   end Draw_Entry_Field;

   --  10.3.5.7, Table 24: the question and the 'Yes' button, only on the
   --  total grid array
   procedure Draw_Entry_Complete is
      use General_Parameters;
      Enabled : constant Boolean := Button_Enabled (Yes_Button);
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

   --  10.3.3: the echo texts of the input fields, in the A/B/C/E area.
   --  10.3.3.7 / 10.3.3.9: right and left of the X position 204 with an
   --  indent of 5; 10.3.3.8 / 10.3.3.10: the first one 112 cells below
   --  the top of the area; 5.1.3.5: line spacing 2 x 12 cells.
   procedure Draw_Echo_Line (Line     : Positive;
                             Label    : Wide_String;
                             Val      : Wide_String;
                             Accepted : Boolean;
                             Check    : Check_State_T := No_Check) is
      use General_Parameters;
      Y : constant Natural := Grid_Origin.Y + 112 + (Line - 1) * 24;
      --  10.3.3.5: white once the driver accepted the value
      Ink : constant Color := (if Accepted then WHITE else GREY);
      --  10.3.3.4: an inconsistent data value gives way to the type of
      --  the inconsistency (10.3.4.2.2, 10.3.4.3.2, 10.3.4.5.2 in red or
      --  yellow '++++'; 10.3.4.4.2, 10.3.4.6.2 '????')
      Data_Ink : constant Color :=
        (case Check is
            when No_Check => Ink,
            when Technical_Range | Technical_Resolution
               | Failed_Technical_Cross => RED,
            when Operational_Range | Failed_Operational_Cross => YELLOW);
      Data_Text : constant Wide_String :=
        (case Check is
            when No_Check => Val,
            when Technical_Range | Technical_Resolution
               | Operational_Range => "++++",
            when Failed_Technical_Cross
               | Failed_Operational_Cross => "????");
   begin
      Draw.Draw_String
        (Pen_X => 204 - 5, Pen_Y => Y,
         The_String => Label, The_Size => 12, The_Color => Ink,
         The_Alignment => Draw.Right);
      Draw.Draw_String
        (Pen_X => 204 + 5, Pen_Y => Y,
         The_String => Data_Text, The_Size => 12, The_Color => Data_Ink);
   end Draw_Echo_Line;

   procedure Draw_Echo_Texts is
   begin
      if Def.Echo_Count > 0 then
         --  10.4.1.5: the echo texts of the topic being validated
         for I in 1 .. Def.Echo_Count loop
            Draw_Echo_Line
              (I, Trim (Def.Echo (I).Label),
               Def.Echo (I).Value.Text (1 .. Def.Echo (I).Value.Length),
               Def.Echo (I).Accepted);
         end loop;
      else
         for I in 1 .. Def.Field_Count loop
            Draw_Echo_Line
              (I, Trim (Def.Fields (I).Label),
               Fields (I).Value.Text (1 .. Fields (I).Value.Length),
               Fields (I).Accepted, Fields (I).Check);
         end loop;
      end if;
   end Draw_Echo_Texts;

   procedure Draw_Data_Entry is
   begin
      for I in 1 .. Def.Field_Count loop
         Draw_Entry_Field (I);
      end loop;

      for Key in Key_First .. Key_Last loop
         declare
            --  10.3.5.15: '1' to '9', the [delete], '0' and the disabled
            --  '.'; 10.3.5.18: the 'No' and 'Yes' keys of a dedicated
            --  keyboard limited to that choice
            Label : constant Wide_String :=
              (if Def.Fields (Current).Keyboard = Yes_No then
                 (case Key is
                     when Key_No  => "No",
                     when Key_Yes => "Yes",
                     when others  => "")
               else
                 (case Key is
                     when 1 .. 9     => Natural'Wide_Image (Key) (2 .. 2) & "",
                     when Key_Zero   => "0",
                     when Key_Delete => "Del",
                     when Key_Dot    => ".",
                     when others     => ""));
         begin
            if Label /= "" then
               Draw_Labelled_Button (Key_Area (Key), Label,
                                     Enabled => Key_Enabled (Key),
                                     Is_Down => Pressed (Key));
            end if;
         end;
      end loop;

      --  10.3.5.6 / 10.4.1.5: the values are echoed on the A/B/C/E area
      if On_Total_Grid then
         Draw_Echo_Texts;
      end if;
      if Def.Layout = Total_Grid then
         Draw_Entry_Complete;
      end if;
   end Draw_Data_Entry;

   procedure Render is
   begin
      if not Open_Flag then
         return;
      end if;
      Draw_Title;
      Draw_Data_Entry;
   end Render;

end DMI_Data_Entry;
