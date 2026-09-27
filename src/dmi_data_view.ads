--  ETCS DMI
--  The ETCS Data view window (DMI 11.5.1) in the D/F/G area, laid out
--  per chapter 10.5 (touch screen technology).
--
--  The items and their order are Table 45 (flexible train data entry:
--  every train data item has its own input field, 11.5.1.5.1). Table 45
--  also fixes how they are spread over the windows: window 1 carries the
--  topics "Driver ID", "Train running number" and "Train data", window 2
--  the topic "Radio data info" and the VBCs stored on-board, which go on
--  to the windows 3 .. n when there are more than window 2 holds. The window
--  title therefore carries the sequence number and the total number of
--  windows per 5.3.1.2.1 g, and [Previous] / [Next] (5.3.1.1.6 d/e)
--  navigate between them without wrapping (5.3.1.1.9).
--
--  DMI_Windows owns the window stack, the title bar and the [Close]
--  button; it delegates the content, the two navigation buttons and the
--  title text of the View window kind here.

with Display;

package DMI_Data_View is

   -- Window-internal button indices, as DMI_Windows numbers them
   Previous_Button : constant := 1; -- 5.3.2.7.1 d, symbol NA18
   Next_Button     : constant := 2; -- 5.3.2.7.1 c, symbol NA17

   function Button_Count return Natural;
   function Button_Area (Index : Positive) return Display.Area_T;

   -- 5.3.2.7.5: disabled when the function would not change anything,
   -- i.e. at the first and at the last window (5.3.1.1.9)
   function Button_Enabled (Index : Positive) return Boolean;

   procedure Button_Pressed (Index : Positive);

   -- The window is (re)opened: back to its first window
   procedure Reset;

   -- Window title with the sequence number, 11.5.1.2 and 11.5.1.3
   function Title return Wide_String;

   procedure Render (Previous_Pressed : Boolean;
                     Next_Pressed     : Boolean);

   -- The content of the System version window (11.5.2, Table 46), a
   -- data view window of its own with the layout of 10.5.1
   procedure Render_System_Version;

end DMI_Data_View;
