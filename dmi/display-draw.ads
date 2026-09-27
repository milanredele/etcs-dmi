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
   -- Total: never raises, whatever The_String holds. Every font covers
   -- the printable part of ISO 8859-1 (16#20# .. 16#7E# and
   -- 16#A0# .. 16#FF#, the characters a text message can hold, X_TEXT);
   -- a character outside it, the C1 controls included, is drawn as a box
   -- outline of the cap height; cells outside the screen are not drawn;
   -- a size without a font (11, 13 .. 15) uses the next smaller font.
   -- Bold: the bold style (8.2.3.4.7 c, 5.1.2.1.5), which exists at
   -- 12 cells; at any other size the regular font of that size is used.
   -- The length the alignment works with is String_Width.
   procedure Draw_String (Pen_X : Width_T;
                          Pen_Y : Height_T;
                          The_String : Wide_String;
                          The_Size   : Font.Size_T;
                          The_Color  : General_Parameters.Color;
                          The_Alignment : Text_Alignment := Left;
                          Bold       : Boolean := False);

   -- The same, left aligned, for text that must stay inside an area
   -- whatever it holds (text messages, DMI 8.2.3.4.2): no cell outside
   -- The_Clip (absolute coordinates) is drawn.
   procedure Draw_String_Clipped (Pen_X : Width_T;
                                  Pen_Y : Height_T;
                                  The_String : Wide_String;
                                  The_Size   : Font.Size_T;
                                  The_Color  : General_Parameters.Color;
                                  The_Clip   : Area_T;
                                  Bold       : Boolean := False);

   -- Width in cells of The_String as Draw_String draws it, the
   -- replacement boxes included: from the pen position to the last cell
   -- of ink, which is the sum of the advances, or beyond it by the ink
   -- of a last glyph that reaches past its advance ('y', '/' ...). The
   -- measure to decide whether a text fits an area.
   function String_Width (The_String : Wide_String;
                          The_Size   : Font.Size_T;
                          Bold       : Boolean := False) return Natural;

   -- The pen advance over The_String (the sum of the advances): where
   -- the pen stands after it, the place of the next character
   function String_Advance (The_String : Wide_String;
                            The_Size   : Font.Size_T;
                            Bold       : Boolean := False) return Natural;

   procedure Draw_Symbol (The_Symbol   : Symbol.T;
                          The_Position : Position_T);

   -- The same with the grey cells drawn dark grey: the symbol of a
   -- disabled button that has no disabled variant (DMI 5.3.2.5.5 a)
   procedure Draw_Symbol_Dimmed (The_Symbol   : Symbol.T;
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
