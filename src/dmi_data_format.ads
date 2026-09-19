--  ETCS DMI
--  Presentation of numeric and alphanumeric data (DMI 5.1.5): the blocks
--  a long data value is displayed in. The space characters and the line
--  breaks are not part of the value (5.1.5.2.1), they are added here for
--  the display only. Shared by every window that shows such a value
--  (data view items, data entry echo texts).

package DMI_Data_Format is

   -- 5.1.5.2: not more than 8 characters on the same text line
   Max_Chars_Per_Line : constant := 8;

   -- 5.1.5.1: one 'space' character is inserted in a line of more than
   -- 5 characters
   Max_Line_Len : constant := Max_Chars_Per_Line + 1;

   -- Enough for the longest data the DMI holds (12 characters)
   Max_Lines : constant := 4;

   type Line_T is record
      Length : Natural := 0;
      Text   : Wide_String (1 .. Max_Line_Len) := (others => ' ');
   end record;

   type Line_List_T is array (1 .. Max_Lines) of Line_T;

   type Grouped_T is record
      Count : Natural := 0;
      Lines : Line_List_T;
   end record;

   -- The text lines Data is displayed in. Total: any string is
   -- accepted, characters beyond Max_Lines * Max_Chars_Per_Line are
   -- dropped rather than drawn outside the window.
   function Grouped (Data : Wide_String) return Grouped_T;

end DMI_Data_Format;
