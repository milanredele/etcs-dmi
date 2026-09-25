--  ETCS DMI
--  Data view window implementation (DMI 10.5.1, 11.5.1).

pragma Ada_2012;
with Display.Draw;
with DMI_Conditions;
with DMI_Data_Format;
with DMI_Driver_Data;
with DMI_Radio_Data;
with DMI_System_Version;
with DMI_Texts;
with DMI_Train_Data;
with DMI_VBC;
with General_Parameters;
with Symbol;

package body DMI_Data_View is

   use Display;
   package TX renames DMI_Texts;

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
   type Topic_T is (T_Driver_ID, T_TRN, T_Train_Data, T_Radio_Data, T_VBC);

   -- 5.5.1.3: the label is a text of DMI_Texts, drawn in the selected
   -- language; the VBC rows build theirs around the number (Row_Label)
   type Item_T is record
      Page  : Positive := 1;
      Topic : Topic_T := T_Driver_ID;
      Label : TX.Text_ID := TX.Driver_ID;
   end record;

   function Item (Page  : Positive;
                  Topic : Topic_T;
                  Label : TX.Text_ID) return Item_T is
     ((Page, Topic, Label));

   -- Table 45. Item 3 "Train type" belongs to the fixed train data
   -- entry of Table 44 only. Item 14 "RBC phone number" is displayed
   -- only when the Radio Network type stored on-board is GSM-R or
   -- FRMCS+GSM-R while GSM-R is installed on-board (11.5.1.6.1, the
   -- condition of DMI_Conditions.RBC_Phone_Field). Items 15.. are one
   -- per VBC stored on-board (11.5.1.6), from MSG_VBC_LIST; they follow
   -- in the rows after the fixed items (Row_Count). The Page of an item
   -- is the window Table 45 gives it; the VBC items start on window 2
   -- and continue on the windows 3 .. n when window 2 is full ("2..n").
   Items : constant array (1 .. 13) of Item_T :=
     (Item (1, T_Driver_ID,  TX.Driver_ID),            -- 1
      Item (1, T_TRN,        TX.Train_Running_Number), -- 2
      Item (1, T_Train_Data, TX.Train_Category),       -- 4
      Item (1, T_Train_Data, TX.Train_Length),         -- 5
      Item (1, T_Train_Data, TX.Brake_Percentage),     -- 6
      Item (1, T_Train_Data, TX.Maximum_Speed),        -- 7
      Item (1, T_Train_Data, TX.Axle_Load_Category),   -- 8
      Item (1, T_Train_Data, TX.Airtight),             -- 9
      Item (1, T_Train_Data, TX.Loading_Gauge),        -- 10
      Item (2, T_Radio_Data, TX.Radio_Network_Type),   -- 11
      Item (2, T_Radio_Data, TX.GSMR_Network_ID),      -- 12
      Item (2, T_Radio_Data, TX.RBC_ID),               -- 13
      Item (2, T_Radio_Data, TX.RBC_Phone_Number));    -- 14

   Phone_Item : constant := 13;  -- the index of item 14 above

   -- The rows on offer: the fixed items (item 14 only under its
   -- condition), then one per VBC of the last MSG_VBC_LIST
   function Row_Present (Row : Positive) return Boolean is
     (Row /= Phone_Item or else DMI_Conditions.RBC_Phone_Field);

   function VBC_Count return Natural is
     (if DMI_VBC.Known then DMI_VBC.Count else 0);

   function Row_Count return Natural is (Items'Length + VBC_Count);

   function Row_Item (Row : Positive) return Item_T is
     (if Row <= Items'Length then Items (Row)
      else Item (2, T_VBC, TX.VBC_Code_Before));

   -- The label of a row; Table 45 items 15, 16, ...: 'VBC #n set code'
   function Row_Label (Row : Positive) return Wide_String is
      Img : constant Wide_String :=
        Natural'Wide_Image (Row - Natural'Min (Row, Items'Length));
   begin
      if Row <= Items'Length then
         return TX.Text (Items (Row).Label);
      end if;
      return TX.Text (TX.VBC_Code_Before) & Img (2 .. Img'Last)
        & TX.Text (TX.VBC_Code_After);
   end Row_Label;

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

   -- The data the DMI holds. Index is the position in Items above (or
   -- a VBC row after them), not the item number of
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
   -- category, the airtight and the loading gauge; 10 to 13 the radio
   -- data info (items 11 to 14 of Table 45):
   -- - 10 the Radio Network type stored on-board, which MSG_ONBOARD
   --   reports with its value (bits 0-1 of the radio byte); not known:
   --   no value. A dedicated value (Table 43b), not grouped (5.1.5.2.2);
   --   the names of the radio systems, the same in every language.
   -- - 11 the GSM-R network ID: the network the driver selected on this
   --   DMI from the list of the on-board (11.3.4), while the EVC reports
   --   a GSM-R Mobile Terminal registered to a network (implementation
   --   choice: the registration is the only status of the network ID
   --   the protocol carries, SUBSET-026 3.18.4.3). Chosen from a list
   --   (a dedicated keyboard), so not grouped (5.1.5.2.2).
   -- - 12, 13 the RBC ID and phone number the driver entered on this DMI
   --   (11.3.5), while the RBC contact information is valid (MSG_ONBOARD
   --   data bit 4) and the driver's last choice was to enter them: after
   --   'Contact last RBC' or 'Use short number' the on-board uses
   --   contact information the DMI does not know.
   -- VBC rows: the set code the EVC reported (MSG_VBC_LIST), a number
   -- grouped per 5.1.5.
   function Value_Of (Index : Positive) return Value_T is
      use DMI_Driver_Data;
      use DMI_Train_Data;
      None : constant Value_T := (others => <>);

      function Radio_Type_Value (Text : Wide_String) return Value_T is
         Result : Value_T;
      begin
         Result.Valid := True;
         Result.Group := False;
         Result.Length := Text'Length;
         Result.Text (1 .. Text'Length) := Text;
         return Result;
      end Radio_Type_Value;

      function RBC_Entered return Boolean is
        (DMI_Conditions.RBC_Contact_Valid
         and then DMI_Radio_Data.RBC_Entered
         and then DMI_Radio_Data."=" (DMI_Radio_Data.Last_Choice,
                                      DMI_Radio_Data.Entered));
   begin
      if Index > Items'Length then
         return (if Index - Items'Length <= VBC_Count
                 then Num_Value (DMI_VBC.Codes (Index - Items'Length))
                 else None);
      end if;
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
         when 10 =>
            case DMI_Conditions.Radio_Type is
               when DMI_Conditions.FRMCS =>
                  return Radio_Type_Value ("FRMCS");
               when DMI_Conditions.FRMCS_GSMR =>
                  return Radio_Type_Value ("FRMCS+GSM-R");
               when DMI_Conditions.GSMR =>
                  return Radio_Type_Value ("GSM-R");
               when DMI_Conditions.Type_Unknown =>
                  return None;
            end case;
         when 11 =>
            if DMI_Conditions.GSMR_Registered
              and then DMI_Radio_Data.GSMR_Network.Length > 0
            then
               declare
                  N : constant DMI_Radio_Data.Name_T :=
                    DMI_Radio_Data.GSMR_Network;
                  Result : Value_T;
                  Last : constant Natural :=
                    Natural'Min (N.Length, Max_Value_Len);
               begin
                  Result.Valid := True;
                  Result.Group := False;
                  Result.Length := Last;
                  Result.Text (1 .. Last) := N.Text (1 .. Last);
                  return Result;
               end;
            end if;
            return None;
         when 12 =>
            return (if RBC_Entered and then DMI_Radio_Data.RBC_ID.Length > 0
                    then Text_Value (DMI_Radio_Data.RBC_ID) else None);
         when 13 =>
            return (if RBC_Entered
                      and then DMI_Radio_Data.RBC_Phone.Length > 0
                    then Text_Value (DMI_Radio_Data.RBC_Phone) else None);
         when others =>
            return None;
      end case;
   end Value_Of;

   ---------------------------------------------------------------------
   -- Paging: where each row goes
   ---------------------------------------------------------------------

   -- A dedicated value wider than the data column is broken after its
   -- last '+' (Figure 134: 'FRMCS+' / 'GSM-R'); the split position, 0
   -- when the value stays on one line
   Data_Width : constant := 306 - Split_X - Indent;

   function Split_At (Value : Value_T) return Natural is
   begin
      if not Value.Valid or else Value.Group
        or else Draw.String_Width (Value.Text (1 .. Value.Length), Char_Size)
                  <= Data_Width
      then
         return 0;
      end if;
      for I in reverse 1 .. Value.Length - 1 loop
         if Value.Text (I) = '+' then
            return I;
         end if;
      end loop;
      return 0;
   end Split_At;

   -- The text lines a row takes: its grouped blocks (5.1.5.2), or two
   -- for a split dedicated value, at least one for the label
   function Rows_Of (Value : Value_T) return Positive is
   begin
      if Value.Valid and then Value.Group then
         return Positive'Max
           (1, DMI_Data_Format.Grouped (Value.Text (1 .. Value.Length)).Count);
      elsif Split_At (Value) > 0 then
         return 2;
      end if;
      return 1;
   end Rows_Of;

   type Place_T is record
      Page : Positive := 1;
      Line : Natural := 0;
   end record;

   Max_Rows : constant := Items'Length + DMI_VBC.Max_Stored;
   type Place_List_T is array (1 .. Max_Rows) of Place_T;

   -- The window and the first text line of every present row, in the
   -- order of Table 45: a row starts on the window Table 45 gives it
   -- or, when the previous row is on a later window, there; 10.5.1.6
   -- puts an empty line between two topics; a row that does not fit
   -- below the last one goes to the next window (the VBC rows of
   -- "2..n")
   procedure Walk (Places : out Place_List_T; Last_Page : out Positive) is
      Page      : Positive := 1;
      Line      : Natural := 0;
      Prev      : Topic_T := Topic_T'First;
      First     : Boolean := True;
   begin
      Places := (others => (1, 0));
      Last_Page := 1;
      for Row in 1 .. Natural'Min (Row_Count, Max_Rows) loop
         if Row_Present (Row) then
            declare
               It   : constant Item_T := Row_Item (Row);
               Need : constant Positive := Rows_Of (Value_Of (Row));
            begin
               if It.Page > Page then
                  Page := It.Page;
                  Line := 0;
                  First := True;
               elsif not First and then It.Topic /= Prev then
                  Line := Line + 1;               -- 10.5.1.6
               end if;
               if not First and then Line + Need - 1 > Last_Line then
                  Page := Page + 1;
                  Line := 0;
               end if;
               First := False;
               Prev := It.Topic;
               Places (Row) := (Page, Line);
               Last_Page := Page;
               Line := Line + Need;
            end;
         end if;
      end loop;
   end Walk;

   function Page_Count return Positive is
      Places : Place_List_T;
      Last   : Positive;
   begin
      Walk (Places, Last);
      -- Table 45: window 2 carries the radio data info in any case
      return Positive'Max (2, Last);
   end Page_Count;

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
      -- the number of windows follows the VBCs stored on-board: a list
      -- that shrank while the window was open leaves it on the last one
      Current_Page := Positive'Min (Current_Page, Page_Count);
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
      Page_Img  : constant Wide_String :=
        Positive'Wide_Image (Positive'Min (Current_Page, Page_Count));
      Total_Img : constant Wide_String := Positive'Wide_Image (Page_Count);
   begin
      return TX.Text (TX.Data_View) & " (" & Page_Img (2 .. Page_Img'Last)
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
      Places : Place_List_T;
      Last   : Positive;
   begin
      Walk (Places, Last);
      Current_Page := Positive'Min (Current_Page, Positive'Max (2, Last));
      for Index in 1 .. Natural'Min (Row_Count, Max_Rows) loop
         if Row_Present (Index) then
            declare
               Place   : constant Place_T := Places (Index);
               Value   : constant Value_T := Value_Of (Index);
               Line    : Natural;
               Cut     : Natural;
            begin
               Line := Place.Line;
               if Place.Page = Current_Page and then Line <= Last_Line then
                  Draw_Label (Line, Row_Label (Index));

                  Cut := Split_At (Value);
                  if Value.Valid and then Value.Group then
                     declare
                        Blocks : constant DMI_Data_Format.Grouped_T :=
                          DMI_Data_Format.Grouped
                            (Value.Text (1 .. Value.Length));
                     begin
                        for Row in 1 .. Blocks.Count loop
                           exit when Line + Row - 1 > Last_Line;
                           Draw_Data
                             (Line + Row - 1,
                              Blocks.Lines (Row).Text
                                (1 .. Blocks.Lines (Row).Length));
                        end loop;
                     end;
                  elsif Value.Valid and then Cut > 0 then
                     Draw_Data (Line, Value.Text (1 .. Cut));
                     if Line + 1 <= Last_Line then
                        Draw_Data (Line + 1, Value.Text (Cut + 1 .. Value.Length));
                     end if;
                  elsif Value.Valid then
                     Draw_Data (Line, Value.Text (1 .. Value.Length));
                  end if;
               end if;
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

   ---------------------------------------------------------------------
   -- System version window (11.5.2)
   ---------------------------------------------------------------------

   -- Table 46: the one data view item 'Operated system version', laid
   -- out as the items of the Data view (10.5.1, Figure 135); no value
   -- while the EVC has not reported one
   procedure Render_System_Version is
   begin
      Draw_Label (0, TX.Text (TX.Operated_System_Version));
      if DMI_System_Version.Known then
         Draw_Data (0, DMI_System_Version.Image);
      end if;
   end Render_System_Version;

end DMI_Data_View;
