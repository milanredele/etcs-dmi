--  ETCS DMI
--  Data view window implementation (DMI 10.5.1, 11.5.1).

pragma Ada_2012;
with Display.Draw;
with DMI_Conditions;
with DMI_Data_Format;
with DMI_Driver_Data;
with DMI_Train_Data;
with General_Parameters;
with Symbol;

package body DMI_Data_View is

   use Display;

   -- Same window area as DMI_Windows (Table 20): the D/F/G column,
   -- 306 x 450 from the top left corner of area D (10.5.1.1)
   Origin : constant Position_T := Get_Area (D).Position;

   ---------------------------------------------------------------------
   -- Layout (10.5.1, Table 31)
   ---------------------------------------------------------------------

   Split_X        : constant := 204; -- 10.5.1.7 and 10.5.1.9
   Indent         : constant := 5;   -- 10.5.1.7 and 10.5.1.9
   First_Baseline : constant := 62;  -- 10.5.1.8 and 10.5.1.10
   Line_Spacing   : constant := 24;  -- 5.1.3.5 with 12 cell characters
   Char_Size      : constant := 12;  -- 5.1.2.2.3 h

   Button_Row_Y   : constant := 400; -- Table 31
   Button_Width   : constant := 82;
   Button_Height  : constant := 50;

   -- The last text line that still stays clear of the button row
   Last_Line : constant :=
     (Button_Row_Y - First_Baseline) / Line_Spacing;

   ---------------------------------------------------------------------
   -- Items (Table 45, in the order of the table)
   ---------------------------------------------------------------------

   -- 10.5.1.6: items of different topics are separated by an empty
   -- text line
   type Topic_T is (T_Driver_ID, T_TRN, T_Train_Data, T_Radio_Data);

   Max_Label_Len : constant := 20;

   type Item_T is record
      Page  : Positive := 1;
      Topic : Topic_T := T_Driver_ID;
      Label : Wide_String (1 .. Max_Label_Len) := (others => ' ');
   end record;

   function Label_Of (S : Wide_String) return Wide_String is
      Result : Wide_String (1 .. Max_Label_Len) := (others => ' ');
   begin
      Result (1 .. S'Length) := S;
      return Result;
   end Label_Of;

   function Item (Page  : Positive;
                  Topic : Topic_T;
                  Label : Wide_String) return Item_T is
     ((Page, Topic, Label_Of (Label)));

   -- Table 45. Item 3 "Train type" belongs to the fixed train data
   -- entry of Table 44 only. Item 14 "RBC phone number" is displayed
   -- only when the radio network type stored on-board is GSM-R or
   -- FRMCS+GSM-R (11.5.1.6.1); this DMI stores no radio network type,
   -- so the item cannot be on offer. Items 15.. are one per VBC stored
   -- on-board (11.5.1.6) and this DMI stores none.
   Items : constant array (1 .. 12) of Item_T :=
     (Item (1, T_Driver_ID,  "Driver ID"),            -- 1
      Item (1, T_TRN,        "Train running number"), -- 2
      Item (1, T_Train_Data, "Train category"),       -- 4
      Item (1, T_Train_Data, "Length (m)"),           -- 5
      Item (1, T_Train_Data, "Brake percentage"),     -- 6
      Item (1, T_Train_Data, "Maximum speed (km/h)"), -- 7
      Item (1, T_Train_Data, "Axle load category"),   -- 8
      Item (1, T_Train_Data, "Airtight"),             -- 9
      Item (1, T_Train_Data, "Loading gauge"),        -- 10
      Item (2, T_Radio_Data, "Radio network type"),   -- 11
      Item (2, T_Radio_Data, "GSM-R network ID"),     -- 12
      Item (2, T_Radio_Data, "RBC ID"));              -- 13

   Page_Count : constant := 2;

   Current_Page : Positive := 1;

   ---------------------------------------------------------------------
   -- Values
   ---------------------------------------------------------------------

   Max_Value_Len : constant := DMI_Driver_Data.Max_Field_Len;

   type Value_T is record
      -- 10.5.1.4: the data part displays the value only when it is
      -- valid. An item the DMI has no source for stays "unknown": the
      -- label is displayed with an empty data part.
      Valid  : Boolean := False;
      -- 5.1.5: grouping applies to numeric and alphanumeric data, not
      -- to data limited to dedicated values (5.1.5.2.2)
      Group  : Boolean := True;
      Length : Natural := 0;
      Text   : Wide_String (1 .. Max_Value_Len) := (others => ' ');
   end record;

   function Num_Value (N : Natural) return Value_T is
      -- 5.1.4.1: no leading zeros
      Img    : constant Wide_String := Natural'Wide_Image (N);
      Digits_Only : constant Wide_String := Img (2 .. Img'Last);
      Result : Value_T;
   begin
      Result.Valid := True;
      Result.Length := Natural'Min (Digits_Only'Length, Max_Value_Len);
      Result.Text (1 .. Result.Length) :=
        Digits_Only (Digits_Only'First
                       .. Digits_Only'First + Result.Length - 1);
      return Result;
   end Num_Value;

   function Text_Value (V : DMI_Driver_Data.Text_Value_T) return Value_T is
      Result : Value_T;
   begin
      Result.Valid := True;
      Result.Length := Natural'Min (V.Length, Max_Value_Len);
      Result.Text (1 .. Result.Length) := V.Text (1 .. Result.Length);
      return Result;
   end Text_Value;

   -- 5.1.5.2.2: grouping does not apply to data limited to dedicated
   -- values, which the train category, the axle load category, the
   -- airtight and the loading gauge are (Tables 40 to 42)
   function Choice_Value (V : DMI_Driver_Data.Text_Value_T) return Value_T is
      Result : Value_T := Text_Value (V);
   begin
      Result.Valid := V.Length > 0;
      Result.Group := False;
      return Result;
   end Choice_Value;

   -- The data the DMI holds. The radio network type, the GSM-R network
   -- ID and the RBC ID are not entered on this DMI and are not carried
   -- by the protocol either: they are unknown and stay without a value.
   -- Index is the position in Items above, not the item number of
   -- Table 45: 4, 5 and 6 are the length, the brake percentage and the
   -- maximum speed (items 5, 6 and 7 of the table).
   --
   -- 10.5.1.4: the data part displays the value only when its status is
   -- valid. The status of the data stored on-board is the on-board's
   -- (SUBSET-026 3.18, DMI 11.7.1.3) and the EVC reports it
   -- (DMI_Conditions). The value itself is what the driver entered on
   -- this DMI, so both are needed: the EVC's "valid" and a value the DMI
   -- has (*_Entered). After a restart the DMI knows no value and shows
   -- none, whatever the on-board says.
   --
   -- Items: 3 is the train category, 4, 5 and 6 are the length, the
   -- brake percentage and the maximum speed, 7, 8 and 9 the axle load
   -- category, the airtight and the loading gauge.
   function Value_Of (Index : Positive) return Value_T is
      use DMI_Driver_Data;
      use DMI_Train_Data;
      None : constant Value_T := (others => <>);
   begin
      case Index is
         when 1 =>
            return (if DMI_Conditions.Driver_ID_Valid
                      and then Driver_ID_Entered
                    then Text_Value (Driver_ID) else None);
         when 2 =>
            return (if DMI_Conditions.TRN_Valid and then TRN_Entered
                    then Text_Value (TRN) else None);
         when 3 =>
            return (if DMI_Conditions.Train_Data_Valid
                      and then Train_Data_Entered
                    then Choice_Value (Stored_Text (I_Category)) else None);
         when 4 =>
            return (if DMI_Conditions.Train_Data_Valid
                      and then Train_Data_Entered
                    then Num_Value (Train_Length) else None);
         when 5 =>
            return (if DMI_Conditions.Train_Data_Valid
                      and then Train_Data_Entered
                    then Num_Value (Brake_Pct) else None);
         when 6 =>
            return (if DMI_Conditions.Train_Data_Valid
                      and then Train_Data_Entered
                    then Num_Value (Max_Speed) else None);
         when 7 =>
            return (if DMI_Conditions.Train_Data_Valid
                      and then Train_Data_Entered
                    then Choice_Value (Stored_Text (I_Axle_Load)) else None);
         when 8 =>
            return (if DMI_Conditions.Train_Data_Valid
                      and then Train_Data_Entered
                    then Choice_Value (Stored_Text (I_Airtight)) else None);
         when 9 =>
            return (if DMI_Conditions.Train_Data_Valid
                      and then Train_Data_Entered
                    then Choice_Value (Stored_Text (I_Gauge)) else None);
         when others =>
            return None;
      end case;
   end Value_Of;

   ---------------------------------------------------------------------
   -- Navigation buttons (Table 31, 5.3.1.1.6 d/e)
   ---------------------------------------------------------------------

   function Button_Count return Natural is (2);

   function Button_Area (Index : Positive) return Display.Area_T is
   begin
      case Index is
         when Previous_Button =>
            return (Origin + (Button_Width, Button_Row_Y),
                    Button_Width, Button_Height);
         when Next_Button =>
            return (Origin + (2 * Button_Width, Button_Row_Y),
                    Button_Width, Button_Height);
         when others =>
            return ((0, 0), 0, 0);
      end case;
   end Button_Area;

   function Button_Enabled (Index : Positive) return Boolean is
     (case Index is
         when Previous_Button => Current_Page > 1,
         when Next_Button     => Current_Page < Page_Count,
         when others          => False);

   procedure Button_Pressed (Index : Positive) is
   begin
      -- 5.3.1.1.9: the scrolling is not circular
      if Index = Previous_Button and then Current_Page > 1 then
         Current_Page := Current_Page - 1;
      elsif Index = Next_Button and then Current_Page < Page_Count then
         Current_Page := Current_Page + 1;
      end if;
   end Button_Pressed;

   procedure Reset is
   begin
      Current_Page := 1;
   end Reset;

   ---------------------------------------------------------------------
   -- Title (11.5.1.2, 11.5.1.3 with 5.3.1.2.1 g)
   ---------------------------------------------------------------------

   -- 11.5.1.2 "Data view"; 11.5.1.3 with 5.3.1.2.1 g: the items of
   -- Table 45 do not fit on one window area, so the title carries the
   -- sequence number of the current window and the total number of
   -- windows between brackets, e.g. "Data view (1/2)"
   function Title return Wide_String is
      Page_Img  : constant Wide_String := Positive'Wide_Image (Current_Page);
      Total_Img : constant Wide_String := Positive'Wide_Image (Page_Count);
   begin
      return "Data view (" & Page_Img (2 .. Page_Img'Last)
        & "/" & Total_Img (2 .. Total_Img'Last) & ")";
   end Title;

   ---------------------------------------------------------------------
   -- Rendering
   ---------------------------------------------------------------------

   procedure Draw_Nav_Button (The_Area : Area_T;
                              Enabled  : Boolean;
                              Pressed  : Boolean;
                              Forward  : Boolean) is
      -- 5.3.2.7.7: NA18.2 replaces NA17 ([Next]) and NA19 replaces
      -- NA18 ([Previous]) while the button is disabled. 5.3.2.5.5 a:
      -- the disabled button keeps the border of an enabled button, only
      -- its symbol changes.
      procedure Place (The_Symbol : Symbol.T) is
      begin
         Draw.Draw_Symbol
           (The_Symbol,
            The_Area.Position
              + ((The_Area.Width - The_Symbol.Width) / 2,
                 (The_Area.Height - The_Symbol.Height) / 2));
      end Place;
   begin
      if not (Enabled and then Pressed) then
         Draw.Draw_Button_Frame (The_Area);
      end if;
      if Forward then
         if Enabled then
            Place (Symbol.NA_17);
         else
            Place (Symbol.NA_18_2);
         end if;
      else
         if Enabled then
            Place (Symbol.NA_18);
         else
            Place (Symbol.NA_19);
         end if;
      end if;
   end Draw_Nav_Button;

   procedure Draw_Label (Line : Natural; Text : Wide_String) is
   begin
      -- 10.5.1.7: right aligned, indent of 5 on the left of X 204
      Draw.Draw_String
        (Pen_X         => Origin.X + Split_X - Indent,
         Pen_Y         => Origin.Y + First_Baseline + Line * Line_Spacing,
         The_String    => Text,
         The_Size      => Char_Size,
         The_Color     => General_Parameters.GREY, -- 10.5.1.5
         The_Alignment => Draw.Right);
   end Draw_Label;

   procedure Draw_Data (Line : Natural; Text : Wide_String) is
   begin
      -- 10.5.1.9: left aligned, indent of 5 on the right of X 204
      Draw.Draw_String
        (Pen_X      => Origin.X + Split_X + Indent,
         Pen_Y      => Origin.Y + First_Baseline + Line * Line_Spacing,
         The_String => Text,
         The_Size   => Char_Size,
         The_Color  => General_Parameters.GREY);
   end Draw_Data;

   procedure Render (Previous_Pressed : Boolean;
                     Next_Pressed     : Boolean) is
      Line       : Natural := 0;
      Prev_Topic : Topic_T := Topic_T'First;
      First      : Boolean := True;
   begin
      for Index in Items'Range loop
         if Items (Index).Page = Current_Page then
            -- 10.5.1.6: one empty text line between two topics
            if not First and then Items (Index).Topic /= Prev_Topic then
               Line := Line + 1;
            end if;
            First := False;
            Prev_Topic := Items (Index).Topic;

            if Line > Last_Line then
               exit;
            end if;

            declare
               Trimmed : Natural := Max_Label_Len;
               Value   : constant Value_T := Value_Of (Index);
               Rows    : Natural := 1;
            begin
               while Trimmed > 0
                 and then Items (Index).Label (Trimmed) = ' '
               loop
                  Trimmed := Trimmed - 1;
               end loop;
               Draw_Label (Line, Items (Index).Label (1 .. Trimmed));

               if Value.Valid and then Value.Group then
                  declare
                     Blocks : constant DMI_Data_Format.Grouped_T :=
                       DMI_Data_Format.Grouped (Value.Text (1 .. Value.Length));
                  begin
                     for Row in 1 .. Blocks.Count loop
                        exit when Line + Row - 1 > Last_Line;
                        Draw_Data
                          (Line + Row - 1,
                           Blocks.Lines (Row).Text
                             (1 .. Blocks.Lines (Row).Length));
                     end loop;
                     Rows := Natural'Max (1, Blocks.Count);
                  end;
               elsif Value.Valid then
                  Draw_Data (Line, Value.Text (1 .. Value.Length));
               end if;

               Line := Line + Rows;
            end;
         end if;
      end loop;

      Draw_Nav_Button (Button_Area (Previous_Button),
                       Enabled => Button_Enabled (Previous_Button),
                       Pressed => Previous_Pressed,
                       Forward => False);
      Draw_Nav_Button (Button_Area (Next_Button),
                       Enabled => Button_Enabled (Next_Button),
                       Pressed => Next_Pressed,
                       Forward => True);
   end Render;

end DMI_Data_View;
