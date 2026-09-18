--  ETCS DMI
--  Window system implementation.

pragma Ada_2012;
with Display.Draw;
with Display.Screen;
with DMI_Driver_Data;
with General_Parameters;
with Supplementary_Driving_Info;
with Symbol;

package body DMI_Windows is

   use Display;

   Origin : constant Position_T := Get_Area (D).Position; -- (334, 15)

   The_Window_Area : constant Area_T := (Origin, 306, 450);

   Title_Height : constant := 24; -- DMI 5.3.1.2.2

   type Window_Kind_T is (Menu, Data_Entry, Validation, View);

   Stack : array (1 .. 8) of Window_ID_T;
   Depth : Natural := 0;

   -- Start-up dialogue sequence (11.7.2, simplified): Driver ID ->
   -- Level -> Train data (+ validation) -> TRN -> mission start
   Sequence_Active : Boolean := False;

   ---------------------------------------------------------------------
   -- Outbound action queue
   ---------------------------------------------------------------------

   type Queued_Action_T is record
      Action : Action_T := Action_T'First;
      Arg    : Natural := 0;
   end record;
   Actions : array (1 .. 8) of Queued_Action_T;
   Action_Count : Natural := 0;

   procedure Queue (Action : Action_T; Arg : Natural := 0) is
   begin
      if Action_Count < Actions'Last then
         Action_Count := Action_Count + 1;
         Actions (Action_Count) := (Action, Arg);
      end if;
   end Queue;

   function Pop_Action (Action : out Action_T;
                        Arg    : out Natural) return Boolean is
   begin
      Action := Action_T'First;
      Arg := 0;
      if Action_Count = 0 then
         return False;
      end if;
      Action := Actions (1).Action;
      Arg := Actions (1).Arg;
      Actions (1 .. Action_Count - 1) := Actions (2 .. Action_Count);
      Action_Count := Action_Count - 1;
      return True;
   end Pop_Action;

   ---------------------------------------------------------------------
   -- Data entry state
   ---------------------------------------------------------------------

   Max_Fields : constant := 3;

   type Field_T is record
      Label   : Wide_String (1 .. 16) := (others => ' ');
      Numeric : Boolean := True;
      Max_Len : Natural := 5;
   end record;
   type Field_List_T is array (1 .. Max_Fields) of Field_T;

   type Value_List_T is
     array (1 .. Max_Fields) of DMI_Driver_Data.Text_Value_T;

   type Entry_State_T is record
      Field_Count : Natural := 0;
      Fields      : Field_List_T;
      Current     : Natural := 1;
      Values      : Value_List_T;
   end record;

   Entry_State : Entry_State_T;

   function Pad (S : Wide_String) return Wide_String is
      Result : Wide_String (1 .. 16) := (others => ' ');
   begin
      Result (1 .. S'Length) := S;
      return Result;
   end Pad;

   procedure Setup_Entry (ID : Window_ID_T) is
      use DMI_Driver_Data;

      function Image_Value (N : Natural) return Text_Value_T is
         Img : constant Wide_String := Natural'Wide_Image (N);
         R   : Text_Value_T;
      begin
         if N > 0 then
            R.Length := Img'Length - 1;
            R.Text (1 .. R.Length) := Img (2 .. Img'Last);
         end if;
         return R;
      end Image_Value;
   begin
      Entry_State := (others => <>);
      Entry_State.Current := 1;
      case ID is
         when W_Driver_ID =>
            Entry_State.Field_Count := 1;
            Entry_State.Fields (1) := (Pad ("Driver ID"), True, 8);
            Entry_State.Values (1) := Driver_ID;
         when W_TRN =>
            Entry_State.Field_Count := 1;
            Entry_State.Fields (1) := (Pad ("Train running nr"), True, 8);
            Entry_State.Values (1) := TRN;
         when W_Train_Data =>
            Entry_State.Field_Count := 3;
            Entry_State.Fields (1) := (Pad ("Length (m)"), True, 4);
            Entry_State.Fields (2) := (Pad ("Brake perc (%)"), True, 3);
            Entry_State.Fields (3) := (Pad ("Max speed"), True, 3);
            Entry_State.Values (1) := Image_Value (Train_Length);
            Entry_State.Values (2) := Image_Value (Brake_Pct);
            Entry_State.Values (3) := Image_Value (Max_Speed);
         when W_SR_Data =>
            Entry_State.Field_Count := 2;
            Entry_State.Fields (1) := (Pad ("SR speed"), True, 3);
            Entry_State.Fields (2) := (Pad ("SR distance"), True, 5);
            Entry_State.Values (1) := Image_Value (SR_Speed);
            Entry_State.Values (2) := Image_Value (SR_Dist);
         when others =>
            null;
      end case;
   end Setup_Entry;

   function Value_Of (Index : Positive) return Natural is
      V : DMI_Driver_Data.Text_Value_T renames Entry_State.Values (Index);
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
   end Value_Of;

   ---------------------------------------------------------------------
   -- Window definitions
   ---------------------------------------------------------------------

   function Kind_Of (ID : Window_ID_T) return Window_Kind_T is
     (case ID is
         when W_Main | W_Override | W_Special | W_Settings | W_Level
            | W_Adhesion | W_Volume | W_Brightness => Menu,
         when W_Driver_ID | W_TRN | W_Train_Data | W_SR_Data => Data_Entry,
         when W_Train_Data_Validation => Validation,
         when W_Data_View => View);

   function Title (ID : Window_ID_T) return Wide_String is
     (case ID is
         when W_Main       => "Main",
         when W_Override   => "Override",
         when W_Data_View  => "Data view",
         when W_Special    => "Special",
         when W_Settings   => "Settings",
         when W_Driver_ID  => "Driver ID",
         when W_Level      => "Level",
         when W_TRN        => "Train running number",
         when W_Train_Data => "Train data",
         when W_Train_Data_Validation => "Validate train data",
         when W_SR_Data    => "SR speed / distance",
         when W_Adhesion   => "Adhesion",
         when W_Volume     => "Volume",
         when W_Brightness => "Brightness");

   -- Menu window buttons; empty label = slot not present
   Max_Menu : constant := 10;
   type Label_T is record
      Text    : Wide_String (1 .. 16) := (others => ' ');
      Used    : Boolean := False;
      Enabled : Boolean := True;
      Delayed : Boolean := False; -- delay-type button (11.2.1.4)
   end record;
   type Menu_Def_T is array (1 .. Max_Menu) of Label_T;

   function B (S : Wide_String;
               Enabled : Boolean := True;
               Delayed : Boolean := False) return Label_T is
     ((Text => Pad (S), Used => True, Enabled => Enabled, Delayed => Delayed));

   No_Button : constant Label_T := (others => <>);

   function Menu_Def (ID : Window_ID_T) return Menu_Def_T is
      Volume_Img : constant Wide_String :=
        General_Parameters.Loudspeaker_Volume_T'Wide_Image
          (General_Parameters.Loudspeaker_Volume);
      Lum_Img : constant Wide_String :=
        General_Parameters.Display_Luminance_T'Wide_Image
          (General_Parameters.Display_Luminance);
   begin
      case ID is
         when W_Main =>
            -- 11.2.1, Table 33 (enabling simplified: EVC arbitrates)
            return (1 => B ("Start"),
                    2 => B ("Driver ID"),
                    3 => B ("Train data"),
                    4 => No_Button,
                    5 => B ("Level"),
                    6 => B ("Train run. nr"),
                    7 => B ("Shunting", Delayed => True),
                    8 => B ("Non-Leading", Delayed => True),
                    9 => B ("Maint. Shunt.", Enabled => False),
                    10 => B ("Radio data", Enabled => False));
         when W_Override =>
            -- 11.2.2
            return (1 => B ("EOA"), others => No_Button);
         when W_Special =>
            -- 11.2.3
            return (1 => B ("Adhesion"),
                    2 => B ("SR speed/dist."),
                    3 => B ("Train integrity", Delayed => True),
                    others => No_Button);
         when W_Settings =>
            -- 11.2.4 (language / system version / VBC not implemented)
            return (1 => B ("Language", Enabled => False),
                    2 => B ("Volume"),
                    3 => B ("Brightness"),
                    4 => B ("System version", Enabled => False),
                    others => No_Button);
         when W_Level =>
            -- 11.3.2
            return (1 => B ("Level 1"),
                    2 => B ("Level 2"),
                    3 => No_Button,
                    4 => B ("Level 0"),
                    5 => B ("Level NTC"),
                    others => No_Button);
         when W_Adhesion =>
            -- 11.3.11
            return (1 => B ("Non slippery"),
                    2 => B ("Slippery rail"),
                    others => No_Button);
         when W_Volume =>
            return (1 => B ("-"),
                    2 => B ("+"),
                    3 => B (Volume_Img, Enabled => False),
                    others => No_Button);
         when W_Brightness =>
            return (1 => B ("-"),
                    2 => B ("+"),
                    3 => B (Lum_Img, Enabled => False),
                    others => No_Button);
         when others =>
            return (others => No_Button);
      end case;
   end Menu_Def;

   ---------------------------------------------------------------------
   -- Geometry
   ---------------------------------------------------------------------

   function Window_Area return Display.Area_T is (The_Window_Area);

   function Close_Button_Area return Display.Area_T is
     ((Origin + (0, 400), 82, 50));

   -- Table 20: menu buttons 153x50 in two columns from y 50
   function Menu_Button_Area (Index : Positive) return Area_T is
     ((Origin + (((Index - 1) mod 2) * 153, 50 + ((Index - 1) / 2) * 50),
       153, 50));

   -- Numeric keyboard (10.3.5, simplified layout): 12 keys of 102x50,
   -- three columns, below the field block (up to 3 fields end at y 200)
   function Key_Area (Index : Positive) return Area_T is
     ((Origin + (((Index - 1) mod 3) * 102, 200 + ((Index - 1) / 3) * 50),
       102, 50));

   Key_Delete : constant := 10;
   Key_Zero   : constant := 11;
   Key_Enter  : constant := 12;

   Validation_Yes : constant := 1;
   Validation_No  : constant := 2;

   -- Validation window: [Yes] and [No] side by side above the close row
   function Validation_Button_Area (Index : Positive) return Area_T is
     ((Origin + ((Index - 1) * 153, 350), 153, 50));

   function Button_Count return Natural is
   begin
      if Depth = 0 then
         return 0;
      end if;
      case Kind_Of (Stack (Depth)) is
         when Menu       => return Max_Menu;
         when Data_Entry => return 12;
         when Validation => return 2;
         when View       => return 0;
      end case;
   end Button_Count;

   function Button_Area (Index : Positive) return Display.Area_T is
   begin
      case Kind_Of (Stack (Depth)) is
         when Menu       => return Menu_Button_Area (Index);
         when Data_Entry => return Key_Area (Index);
         when Validation => return Validation_Button_Area (Index);
         when View       => return ((0, 0), 0, 0);
      end case;
   end Button_Area;

   function Button_Enabled (Index : Positive) return Boolean is
   begin
      case Kind_Of (Stack (Depth)) is
         when Menu =>
            declare
               Def : constant Menu_Def_T := Menu_Def (Stack (Depth));
            begin
               return Def (Index).Used and then Def (Index).Enabled;
            end;
         when Data_Entry | Validation =>
            return True;
         when View =>
            return False;
      end case;
   end Button_Enabled;

   function Button_Kind (Index : Positive) return DMI_Buttons.Kind_T is
   begin
      case Kind_Of (Stack (Depth)) is
         when Menu =>
            declare
               Def : constant Menu_Def_T := Menu_Def (Stack (Depth));
            begin
               return (if Def (Index).Delayed then DMI_Buttons.Delay_Type
                       else DMI_Buttons.Up_Type);
            end;
         when Data_Entry =>
            -- 5.3.2.7.2: [Delete] is a down-type button with repeat
            return (if Index = Key_Delete then DMI_Buttons.Down_Type
                    else DMI_Buttons.Up_Type);
         when others =>
            return DMI_Buttons.Up_Type;
      end case;
   end Button_Kind;

   ---------------------------------------------------------------------
   -- Stack handling
   ---------------------------------------------------------------------

   procedure Open (ID : Window_ID_T) is
   begin
      if Depth < Stack'Last then
         Depth := Depth + 1;
         Stack (Depth) := ID;
         if Kind_Of (ID) = Data_Entry then
            Setup_Entry (ID);
         end if;
      end if;
   end Open;

   procedure Close_Top is
   begin
      if Depth > 0 then
         Depth := Depth - 1;
      end if;
      if Depth = 0 then
         Sequence_Active := False;
      end if;
   end Close_Top;

   procedure Close_All is
   begin
      Depth := 0;
      Sequence_Active := False;
      Action_Count := 0;
   end Close_All;

   function Is_Open return Boolean is (Depth > 0);

   function Top return Window_ID_T is (Stack (Depth));

   ---------------------------------------------------------------------
   -- Behaviour
   ---------------------------------------------------------------------

   procedure Entry_Completed is
      use DMI_Driver_Data;
      ID : constant Window_ID_T := Stack (Depth);
   begin
      case ID is
         when W_Driver_ID =>
            Driver_ID := Entry_State.Values (1);
            Driver_ID_Entered := True;
            Queue (Send_Driver_ID);
            Close_Top;
            if Sequence_Active then
               Open (W_Level);
            end if;
         when W_TRN =>
            TRN := Entry_State.Values (1);
            TRN_Entered := True;
            Queue (Send_TRN);
            Close_Top;
            if Sequence_Active then
               -- 11.7.2 (simplified): the sequence ends with the mission
               -- start request
               Sequence_Active := False;
               Queue (Start_Mission);
            end if;
         when W_Train_Data =>
            Train_Length := Value_Of (1);
            Brake_Pct := Value_Of (2);
            Max_Speed := Value_Of (3);
            -- 10.6 / 11.4.1: entered data must be validated
            Open (W_Train_Data_Validation);
         when W_SR_Data =>
            SR_Speed := Value_Of (1);
            SR_Dist := Value_Of (2);
            Queue (Send_SR_Data);
            Close_Top;
         when others =>
            null;
      end case;
   end Entry_Completed;

   procedure Key_Pressed (Index : Positive) is
      V : DMI_Driver_Data.Text_Value_T
        renames Entry_State.Values (Entry_State.Current);
      F : Field_T renames Entry_State.Fields (Entry_State.Current);

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
            -- 10.3.4 (simplified technical check): a value is required
            if V.Length > 0 then
               if Entry_State.Current < Entry_State.Field_Count then
                  -- 10.3.1: [Enter] moves to the next field
                  Entry_State.Current := Entry_State.Current + 1;
               else
                  Entry_Completed;
               end if;
            end if;
         when others =>
            null;
      end case;
   end Key_Pressed;

   procedure Menu_Pressed (Index : Positive) is
      use DMI_Driver_Data;
      use General_Parameters;
      ID : constant Window_ID_T := Stack (Depth);
   begin
      case ID is
         when W_Main =>
            case Index is
               when 1 => -- Start
                  if Driver_ID_Entered and Level_Entered
                    and Train_Data_Entered and TRN_Entered
                  then
                     Queue (Start_Mission);
                     Close_Top;
                  else
                     -- 11.7.2: run the start up dialogue sequence
                     Sequence_Active := True;
                     Open (W_Driver_ID);
                  end if;
               when 2 => Open (W_Driver_ID);
               when 3 => Open (W_Train_Data);
               when 5 => Open (W_Level);
               when 6 => Open (W_TRN);
               when 7 => Queue (SH_Request); Close_Top;
               when 8 => Queue (Non_Leading); Close_Top;
               when others => null;
            end case;
         when W_Override =>
            if Index = 1 then
               Queue (Override_EOA);
               Close_Top;
            end if;
         when W_Special =>
            case Index is
               when 1 => Open (W_Adhesion);
               when 2 => Open (W_SR_Data);
               when 3 => Queue (Train_Integrity); Close_Top;
               when others => null;
            end case;
         when W_Settings =>
            case Index is
               when 2 => Open (W_Volume);
               when 3 => Open (W_Brightness);
               when others => null;
            end case;
         when W_Level =>
            declare
               -- Level_T'Pos values: L0 = 2, NTC = 3, L1 = 4, L2 = 5
               Level : constant Natural :=
                 (case Index is
                     when 1 => 4, when 2 => 5, when 4 => 2, when 5 => 3,
                     when others => 0);
            begin
               if Level > 0 then
                  Level_Entered := True;
                  Queue (Level_Selected, Level);
                  Close_Top;
                  if Sequence_Active then
                     Open (W_Train_Data);
                  end if;
               end if;
            end;
         when W_Adhesion =>
            if Index in 1 .. 2 then
               Queue (Adhesion_Set, (if Index = 2 then 1 else 0));
               Close_Top;
            end if;
         when W_Volume =>
            if Index = 1 and then Loudspeaker_Volume > 0 then
               Loudspeaker_Volume := Loudspeaker_Volume - 1;
            elsif Index = 2 and then Loudspeaker_Volume < 10 then
               Loudspeaker_Volume := Loudspeaker_Volume + 1;
            end if;
         when W_Brightness =>
            if Index = 1 and then Display_Luminance > 0 then
               Display_Luminance := Display_Luminance - 1;
            elsif Index = 2 and then Display_Luminance < 10 then
               Display_Luminance := Display_Luminance + 1;
            end if;
         when others =>
            null;
      end case;
   end Menu_Pressed;

   procedure Button_Pressed (Index : Positive) is
      use DMI_Driver_Data;
   begin
      if Depth = 0 then
         return;
      end if;
      case Kind_Of (Stack (Depth)) is
         when Menu =>
            Menu_Pressed (Index);
         when Data_Entry =>
            Key_Pressed (Index);
         when Validation =>
            -- 11.4.1: Yes confirms, No returns to the entry window
            if Index = Validation_Yes then
               Train_Data_Entered := True;
               Queue (Send_Train_Data);
               Close_Top; -- validation
               Close_Top; -- train data entry
               if Sequence_Active then
                  Open (W_TRN);
               end if;
            elsif Index = Validation_No then
               Close_Top; -- back to the train data entry window
            end if;
         when View =>
            null;
      end case;
   end Button_Pressed;

   ---------------------------------------------------------------------
   -- Rendering
   ---------------------------------------------------------------------

   procedure Draw_Title (ID : Window_ID_T) is
   begin
      Screen.Fill_Area ((Origin, The_Window_Area.Width, Title_Height),
                        General_Parameters.BLACK);
      Draw.Draw_String (Pen_X      => Origin.X + 3,
                        Pen_Y      => Origin.Y + Title_Height - 6,
                        The_String => Title (ID),
                        The_Size   => 12,
                        The_Color  => General_Parameters.GREY);
   end Draw_Title;

   procedure Draw_Close (Pressed : Boolean) is
      Close_Area : constant Area_T := Close_Button_Area;
   begin
      if not Pressed then
         Draw.Draw_Button_Frame (Close_Area);
      end if;
      Draw.Draw_Symbol
        (Symbol.NA_11,
         Close_Area.Position
           + ((Close_Area.Width - Symbol.NA_11.Width) / 2,
              (Close_Area.Height - Symbol.NA_11.Height) / 2));
   end Draw_Close;

   procedure Draw_Labelled_Button (The_Area : Area_T;
                                   Label    : Wide_String;
                                   Enabled  : Boolean;
                                   Pressed  : Boolean) is
   begin
      if not Pressed then
         Draw.Draw_Button_Frame (The_Area);
      end if;
      -- 5.3.2.5.5 / 10.2.1.4: disabled labels in dark grey
      Draw.Draw_String
        (Pen_X => The_Area.Position.X + The_Area.Width / 2,
         Pen_Y => The_Area.Position.Y + The_Area.Height / 2 + 6,
         The_String => Label,
         The_Size => 12,
         The_Color => (if Enabled then General_Parameters.GREY
                       else General_Parameters.DARK_GREY),
         The_Alignment => Draw.Center);
   end Draw_Labelled_Button;

   function Trim (S : Wide_String) return Wide_String is
      Last : Natural := S'Last;
   begin
      while Last >= S'First and then S (Last) = ' ' loop
         Last := Last - 1;
      end loop;
      return S (S'First .. Last);
   end Trim;

   function Pressed (Index : Positive) return Boolean is
     (DMI_Buttons.Is_Pressed
        (DMI_Buttons.Button_ID_T'Val
           (DMI_Buttons.Button_ID_T'Pos (DMI_Buttons.BTN_Menu_1) + Index - 1)));

   procedure Draw_Menu (ID : Window_ID_T) is
      Def : constant Menu_Def_T := Menu_Def (ID);
   begin
      for I in Def'Range loop
         if Def (I).Used then
            Draw_Labelled_Button (Menu_Button_Area (I),
                                  Trim (Def (I).Text),
                                  Def (I).Enabled,
                                  Def (I).Enabled and then Pressed (I));
         end if;
      end loop;
   end Draw_Menu;

   procedure Draw_Entry_Field (Field_Area : Area_T;
                               Label      : Wide_String;
                               Value      : Wide_String;
                               Selected   : Boolean) is
      Data_Area : constant Area_T :=
        (Field_Area.Position + (Field_Area.Width / 2, 0),
         Field_Area.Width / 2, Field_Area.Height);
   begin
      -- 10.3.1 / Table 21: label part; data part grey with black text
      -- while selected, dark grey with white text once accepted
      Draw.Draw_Input_Field_Frame (Field_Area);
      Draw.Draw_String
        (Pen_X => Field_Area.Position.X + 3,
         Pen_Y => Field_Area.Position.Y + Field_Area.Height / 2 + 6,
         The_String => Label,
         The_Size => 12,
         The_Color => General_Parameters.GREY);
      Screen.Fill_Area (Data_Area,
                        (if Selected then General_Parameters.GREY
                         else General_Parameters.DARK_GREY));
      Draw.Draw_String
        (Pen_X => Data_Area.Position.X + 3,
         Pen_Y => Data_Area.Position.Y + Data_Area.Height / 2 + 6,
         The_String => Value,
         The_Size => 12,
         The_Color => (if Selected then General_Parameters.BLACK
                       else General_Parameters.WHITE));
   end Draw_Entry_Field;

   procedure Draw_Data_Entry is
   begin
      for I in 1 .. Entry_State.Field_Count loop
         Draw_Entry_Field
           ((Origin + (0, 50 + (I - 1) * 50), 306, 50),
            Trim (Entry_State.Fields (I).Label),
            Entry_State.Values (I).Text (1 .. Entry_State.Values (I).Length),
            Selected => I = Entry_State.Current);
      end loop;

      -- keyboard: rows below y 150 would collide with three fields, so
      -- the keyboard starts after the field block
      for Key in 1 .. 12 loop
         declare
            Label : constant Wide_String :=
              (case Key is
                  when 1 .. 9  => Natural'Wide_Image (Key) (2 .. 2) & "",
                  when Key_Zero => "0",
                  when Key_Delete => "Del",
                  when Key_Enter => "Enter",
                  when others => "");
         begin
            Draw_Labelled_Button (Key_Area (Key), Label,
                                  Enabled => True,
                                  Pressed => Pressed (Key));
         end;
      end loop;
   end Draw_Data_Entry;

   procedure Draw_Text_Line (Line : Natural; Text : Wide_String) is
   begin
      Draw.Draw_String
        (Pen_X => Origin.X + 6,
         Pen_Y => Origin.Y + 50 + Line * 24,
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
      -- 11.4.1: echo of the entered values with [Yes] / [No]
      Draw_Text_Line (1, "Length: " & Num_Image (Train_Length) & " m");
      Draw_Text_Line (2, "Brake percentage: " & Num_Image (Brake_Pct) & " %");
      Draw_Text_Line (3, "Max speed: " & Num_Image (Max_Speed) & " km/h");
      Draw_Labelled_Button (Validation_Button_Area (Validation_Yes), "Yes",
                            True, Pressed (Validation_Yes));
      Draw_Labelled_Button (Validation_Button_Area (Validation_No), "No",
                            True, Pressed (Validation_No));
   end Draw_Validation;

   procedure Draw_Data_View is
      use DMI_Driver_Data;
      package SDI renames Supplementary_Driving_Info;
   begin
      -- 11.5.1 (simplified single page)
      Draw_Text_Line (1, "Driver ID: "
                      & Driver_ID.Text (1 .. Driver_ID.Length));
      Draw_Text_Line (2, "Level: "
                      & SDI.Level_T'Wide_Image (SDI.Level));
      Draw_Text_Line (3, "Train length: " & Num_Image (Train_Length) & " m");
      Draw_Text_Line (4, "Brake percentage: " & Num_Image (Brake_Pct));
      Draw_Text_Line (5, "Max speed: " & Num_Image (Max_Speed) & " km/h");
      Draw_Text_Line (6, "Train running nr: "
                      & TRN.Text (1 .. TRN.Length));
   end Draw_Data_View;

   procedure Render is
      ID : Window_ID_T;
   begin
      if Depth = 0 then
         return;
      end if;
      ID := Stack (Depth);

      Screen.Fill_Area (The_Window_Area, General_Parameters.Background_Color);
      Draw_Title (ID);
      Draw_Close (DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_Window_Close));

      case Kind_Of (ID) is
         when Menu       => Draw_Menu (ID);
         when Data_Entry => Draw_Data_Entry;
         when Validation => Draw_Validation;
         when View       => Draw_Data_View;
      end case;
   end Render;

end DMI_Windows;
