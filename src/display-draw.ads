--  ETCS DMI
--  Drawing primitives over the shared screen buffer, in absolute screen
--  coordinates. Area-relative drawing goes through Display.Frame_Buffer.

with Font;
with Symbol;

package Display.Draw is

   type Text_Alignment is (Left, Right, Center);

   procedure Draw_Glyph (Pen_X : Width_T;
                         Pen_Y : Height_T;
                         The_Glyph  : Font.Glyph;
                         The_Bitmap : Font.Bitmap_T;
                         The_Color  : General_Parameters.Color);

   procedure Draw_String (Pen_X : Width_T;
                          Pen_Y : Height_T;
                          The_String : Font.Glyph_String;
                          The_Bitmap : Font.Bitmap_T;
                          The_Color  : General_Parameters.Color;
                          The_Alignment : Text_Alignment := Left);

   -- Draw a string with given cap height (cell size per DMI 5.1.2.2.3)
   -- Pen_X, Pen_Y: for left alignment the pen position of the first
   -- character; for right alignment the pen position after the last
   -- character; for center alignment the middle of the string
   procedure Draw_String (Pen_X : Width_T;
                          Pen_Y : Height_T;
                          The_String : Wide_String;
                          The_Size   : Font.Size_T;
                          The_Color  : General_Parameters.Color;
                          The_Alignment : Text_Alignment := Left);

   procedure Draw_Symbol (The_Symbol   : Symbol.T;
                          The_Position : Position_T);

   -- DMI 5.1.1.1.2: border, black left/top and shadow right/bottom
   procedure Draw_Frame (The_Area : Area_T);

   -- DMI 5.1.1.3: 2 cell yellow flashing frame
   procedure Draw_Yellow_Frame (The_Area : Area_T; Show : Boolean := True);

   -- DMI 5.1.1.1.3: 'lifted' button border
   procedure Draw_Button_Frame (The_Area : Area_T);

   -- DMI 5.1.1.1.4: medium grey input field border
   procedure Draw_Input_Field_Frame (The_Area : Area_T);

end Display.Draw;
