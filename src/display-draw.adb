--  ETCS DMI
--  Drawing primitives implementation (moved from the per-area frame
--  buffer generic so windows can draw at absolute coordinates).

pragma Ada_2012;
with Display.Screen;
with Font.FreeSans_10;
with Font.FreeSans_12;
with Font.FreeSans_16;
with Font.FreeSans_17;
with Font.FreeSans_18;

package body Display.Draw is

   procedure Set_Pixel (X : Width_T;
                        Y : Height_T;
                        The_Color : General_Parameters.Color) renames Screen.Set_Pixel;

   -- Text is partly EVC controlled (text messages, DMI 8.2.3.4.1) and
   -- must never stop the DMI: everything below is total. Pen positions
   -- are computed as Integer and every cell is clipped to the screen, so
   -- a string that is wider than the space left of or right of the pen
   -- loses cells instead of raising Constraint_Error.
   --
   -- A clip is the rectangle text may be drawn in: the whole screen, or
   -- the part of an area that is on the screen (Draw_String_Clipped).
   type Clip_T is record
      Left, Right, Top, Bottom : Integer; -- inclusive; empty if reversed
   end record;

   Whole_Screen : constant Clip_T :=
     (Left   => 0,
      Right  => General_Parameters.Display_Resolution.Width - 1,
      Top    => 0,
      Bottom => General_Parameters.Display_Resolution.Height - 1);

   function To_Clip (The_Area : Area_T) return Clip_T is
     (Left   => The_Area.Position.X,
      Right  => Integer'Min (The_Area.Position.X + The_Area.Width - 1,
                             Whole_Screen.Right),
      Top    => The_Area.Position.Y,
      Bottom => Integer'Min (The_Area.Position.Y + The_Area.Height - 1,
                             Whole_Screen.Bottom));

   procedure Put_Pixel (X, Y : Integer;
                        The_Color : General_Parameters.Color;
                        The_Clip  : Clip_T := Whole_Screen) is
   begin
      if X in The_Clip.Left .. The_Clip.Right
        and then Y in The_Clip.Top .. The_Clip.Bottom
      then
         Set_Pixel (X, Y, The_Color);
      end if;
   end Put_Pixel;

   procedure Put_Glyph (Pen_X, Pen_Y : Integer;
                        The_Glyph  : Font.Glyph;
                        The_Bitmap : Font.Bitmap_T;
                        The_Color  : General_Parameters.Color;
                        The_Clip   : Clip_T := Whole_Screen) is
      Top  : constant Integer := Pen_Y - The_Glyph.Top;
      Left : constant Integer := Pen_X + The_Glyph.Left;
   begin
      for J in 0 .. The_Glyph.Height - 1 loop
         for I in 0 .. The_Glyph.Width - 1 loop
            if Font.Cell (The_Glyph, The_Bitmap, I, J) then
               Put_Pixel (Left + I, Top + J, The_Color, The_Clip);
            end if;
         end loop;
      end loop;
   end Put_Glyph;

   -- Replacement for a character the font has no glyph for: the outline
   -- of a box standing on the base line, as high as the capitals (the
   -- font size is the cap height in cells) and about as wide as a digit.
   function Replacement_Width (The_Size : Font.Size_T) return Positive is
     (Positive (The_Size) / 2 + 1);

   -- One empty cell column on each side of the box
   function Replacement_Advance (The_Size : Font.Size_T) return Positive is
     (Replacement_Width (The_Size) + 2);

   procedure Put_Replacement (Pen_X, Pen_Y : Integer;
                              The_Size  : Font.Size_T;
                              The_Color : General_Parameters.Color;
                              The_Clip  : Clip_T := Whole_Screen) is
      Left   : constant Integer := Pen_X + 1;
      Right  : constant Integer := Left + Replacement_Width (The_Size) - 1;
      Top    : constant Integer := Pen_Y - Positive (The_Size);
      Bottom : constant Integer := Pen_Y - 1;
   begin
      for X in Left .. Right loop
         Put_Pixel (X, Top, The_Color, The_Clip);
         Put_Pixel (X, Bottom, The_Color, The_Clip);
      end loop;
      for Y in Top .. Bottom loop
         Put_Pixel (Left, Y, The_Color, The_Clip);
         Put_Pixel (Right, Y, The_Color, The_Clip);
      end loop;
   end Put_Replacement;

   -- Fonts exist for these sizes only. All callers pass one of them as
   -- a literal (no size comes from the EVC); any other size is drawn
   -- with the next smaller font rather than raising.
   subtype Available_Size_T is Font.Size_T
     with Static_Predicate => Available_Size_T in 10 | 12 | 16 | 17 | 18;

   function Available (The_Size : Font.Size_T) return Available_Size_T is
     (case The_Size is
         when 10 | 11       => 10,
         when 12 .. 15      => 12,
         when 16            => 16,
         when 17            => 17,
         when 18            => 18);

   -- The maps run over a contiguous range of code points; the ones the
   -- font has no glyph for carry Font.No_Glyph (the C1 controls of
   -- ISO 8859-1, 16#7F# .. 16#9F#, have no printable form) and get the
   -- replacement box like any code outside the range.
   function Has_Glyph (The_Map : Font.Glyph_Map;
                       C       : Wide_Character) return Boolean is
     (C in The_Map'Range and then Font.Defined (The_Map (C)));

   function Width_In (The_Map    : Font.Glyph_Map;
                      The_Size   : Font.Size_T;
                      The_String : Wide_String) return Natural is
      Total : Natural := 0;
   begin
      for C of The_String loop
         Total := Total + (if Has_Glyph (The_Map, C)
                           then The_Map (C).Advance_X
                           else Replacement_Advance (The_Size));
      end loop;
      return Total;
   end Width_In;

   function String_Width (The_String : Wide_String;
                          The_Size   : Font.Size_T) return Natural is
   begin
      case Available (The_Size) is
         when 10 =>
            return Width_In (Font.FreeSans_10.Glyphs, 10, The_String);
         when 12 =>
            return Width_In (Font.FreeSans_12.Glyphs, 12, The_String);
         when 16 =>
            return Width_In (Font.FreeSans_16.Glyphs, 16, The_String);
         when 17 =>
            return Width_In (Font.FreeSans_17.Glyphs, 17, The_String);
         when 18 =>
            return Width_In (Font.FreeSans_18.Glyphs, 18, The_String);
      end case;
   end String_Width;

   -- Pen position of the first character for the given alignment
   function Start_X (Pen_X         : Width_T;
                     Length        : Natural;
                     The_Alignment : Text_Alignment) return Integer is
     (case The_Alignment is
         when Left   => Pen_X,
         when Center => Pen_X - Length / 2,
         when Right  => Pen_X - Length);

   procedure Draw_Glyph (Pen_X : Width_T;
                         Pen_Y : Height_T;
                         The_Glyph  : Font.Glyph;
                         The_Bitmap : Font.Bitmap_T;
                         The_Color  : General_Parameters.Color) is
   begin
      Put_Glyph (Pen_X, Pen_Y, The_Glyph, The_Bitmap, The_Color);
   end Draw_Glyph;

   procedure Draw_String (Pen_X : Width_T;
                          Pen_Y : Height_T;
                          The_String : Font.Glyph_String;
                          The_Bitmap : Font.Bitmap_T;
                          The_Color  : General_Parameters.Color;
                          The_Alignment : Text_Alignment := Left) is
      Length : Natural := 0;
      Cur_X  : Integer;
   begin
      for G of The_String loop
         Length := Length + G.Advance_X;
      end loop;
      Cur_X := Start_X (Pen_X, Length, The_Alignment);
      for G of The_String loop
         Put_Glyph (Cur_X, Pen_Y, G, The_Bitmap, The_Color);
         Cur_X := Cur_X + G.Advance_X;
      end loop;
   end Draw_String;

   -- Common part of the Wide_String drawing procedures
   procedure Put_String (Pen_X : Width_T;
                         Pen_Y : Height_T;
                         The_String : Wide_String;
                         The_Size   : Font.Size_T;
                         The_Color  : General_Parameters.Color;
                         The_Alignment : Text_Alignment;
                         The_Clip   : Clip_T) is
      Size : constant Available_Size_T := Available (The_Size);

      -- The font tables are passed by reference, never copied
      procedure Render (The_Map    : Font.Glyph_Map;
                        The_Bitmap : Font.Bitmap_T) is
         Cur_X : Integer :=
           Start_X (Pen_X, Width_In (The_Map, Size, The_String),
                    The_Alignment);
      begin
         for C of The_String loop
            if Has_Glyph (The_Map, C) then
               Put_Glyph (Cur_X, Pen_Y, The_Map (C), The_Bitmap, The_Color,
                          The_Clip);
               Cur_X := Cur_X + The_Map (C).Advance_X;
            else
               Put_Replacement (Cur_X, Pen_Y, Size, The_Color, The_Clip);
               Cur_X := Cur_X + Replacement_Advance (Size);
            end if;
         end loop;
      end Render;

   begin
      case Size is
         when 10 =>
            Render (Font.FreeSans_10.Glyphs, Font.FreeSans_10.Bitmap);
         when 12 =>
            Render (Font.FreeSans_12.Glyphs, Font.FreeSans_12.Bitmap);
         when 16 =>
            Render (Font.FreeSans_16.Glyphs, Font.FreeSans_16.Bitmap);
         when 17 =>
            Render (Font.FreeSans_17.Glyphs, Font.FreeSans_17.Bitmap);
         when 18 =>
            Render (Font.FreeSans_18.Glyphs, Font.FreeSans_18.Bitmap);
      end case;
   end Put_String;

   procedure Draw_String (Pen_X : Width_T;
                          Pen_Y : Height_T;
                          The_String : Wide_String;
                          The_Size   : Font.Size_T;
                          The_Color  : General_Parameters.Color;
                          The_Alignment : Text_Alignment := Left) is
   begin
      Put_String (Pen_X, Pen_Y, The_String, The_Size, The_Color,
                  The_Alignment, Whole_Screen);
   end Draw_String;

   procedure Draw_String_Clipped (Pen_X : Width_T;
                                  Pen_Y : Height_T;
                                  The_String : Wide_String;
                                  The_Size   : Font.Size_T;
                                  The_Color  : General_Parameters.Color;
                                  The_Clip   : Area_T) is
   begin
      Put_String (Pen_X, Pen_Y, The_String, The_Size, The_Color,
                  Left, To_Clip (The_Clip));
   end Draw_String_Clipped;

   procedure Draw_Symbol (The_Symbol   : Symbol.T;
                          The_Position : Position_T) is
      Pos : Positive range The_Symbol.Bitmap'First .. The_Symbol.Bitmap'Last + 1 := The_Symbol.Bitmap'First;
   begin
      for J in reverse 0 .. The_Symbol.Height - 1 loop
         for I in 0 .. The_Symbol.Width - 1 loop
            Set_Pixel (The_Position.X + I, The_Position.Y + J, The_Symbol.Bitmap (Pos));
            Pos := Pos + 1;
         end loop;
      end loop;
   end Draw_Symbol;

   procedure Draw_Symbol_Dimmed (The_Symbol   : Symbol.T;
                                 The_Position : Position_T) is
      use type General_Parameters.Color;
      Pos : Positive range
        The_Symbol.Bitmap'First .. The_Symbol.Bitmap'Last + 1 :=
          The_Symbol.Bitmap'First;
   begin
      for J in reverse 0 .. The_Symbol.Height - 1 loop
         for I in 0 .. The_Symbol.Width - 1 loop
            Set_Pixel (The_Position.X + I, The_Position.Y + J,
                       (if The_Symbol.Bitmap (Pos) = General_Parameters.GREY
                        then General_Parameters.DARK_GREY
                        else The_Symbol.Bitmap (Pos)));
            Pos := Pos + 1;
         end loop;
      end loop;
   end Draw_Symbol_Dimmed;

   procedure Draw_Frame (The_Area : Area_T) is
   begin
      -- draw top and bottom border
      for X in The_Area.Position.X .. The_Area.Position.X + The_Area.Width - 1 loop
         Set_Pixel (X, The_Area.Position.Y, General_Parameters.BLACK);
         Set_Pixel (X, The_Area.Position.Y + The_Area.Height - 1, General_Parameters.SHADOW);
      end loop;
      -- draw left and right border
      for Y in The_Area.Position.Y .. The_Area.Position.Y + The_Area.Height - 1 loop
         Set_Pixel (The_Area.Position.X, Y, General_Parameters.BLACK);
         Set_Pixel (The_Area.Position.X + The_Area.Width - 1, Y, General_Parameters.SHADOW);
      end loop;
   end Draw_Frame;

   procedure Draw_Yellow_Frame (The_Area : Area_T; Show : Boolean := True) is
      Color : General_Parameters.Color;
   begin
      if Show then
         Color := General_Parameters.YELLOW;
      else
         Color := General_Parameters.DARK_BLUE;
      end if;
      for X in The_Area.Position.X .. The_Area.Position.X + The_Area.Width - 1 loop
         -- horizontal frame
         Set_Pixel (X, The_Area.Position.Y, Color);
         Set_Pixel (X, The_Area.Position.Y + 1, Color);
         Set_Pixel (X, The_Area.Position.Y + The_Area.Height - 2, Color);
         Set_Pixel (X, The_Area.Position.Y + The_Area.Height - 1, Color);
      end loop;
      for Y in The_Area.Position.Y .. The_Area.Position.Y + The_Area.Height - 1 loop
         -- vertical frame
         Set_Pixel (The_Area.Position.X, Y, Color);
         Set_Pixel (The_Area.Position.X + 1, Y, Color);
         Set_Pixel (The_Area.Position.X + The_Area.Width - 2, Y, Color);
         Set_Pixel (The_Area.Position.X + The_Area.Width - 1, Y, Color);
      end loop;
   end Draw_Yellow_Frame;

   procedure Draw_Button_Frame (The_Area : Area_T) is
      Black  : constant General_Parameters.Color := General_Parameters.BLACK;
      Shadow : constant General_Parameters.Color := General_Parameters.SHADOW;
   begin
      for X in The_Area.Position.X .. The_Area.Position.X + The_Area.Width - 1 loop
         -- horizontal frame
         Set_Pixel (X, The_Area.Position.Y, Black);
         Set_Pixel (X, The_Area.Position.Y + 1, Shadow);
         Set_Pixel (X, The_Area.Position.Y + The_Area.Height - 2, Black);
         Set_Pixel (X, The_Area.Position.Y + The_Area.Height - 1, Shadow);
      end loop;
      for Y in The_Area.Position.Y .. The_Area.Position.Y + The_Area.Height - 1 loop
         -- vertical frame
         Set_Pixel (The_Area.Position.X, Y, Black);
         Set_Pixel (The_Area.Position.X + 1, Y, Shadow);
         Set_Pixel (The_Area.Position.X + The_Area.Width - 2, Y, Black);
         Set_Pixel (The_Area.Position.X + The_Area.Width - 1, Y, Shadow);
      end loop;
   end Draw_Button_Frame;

   procedure Draw_Input_Field_Frame (The_Area : Area_T) is
      Color : constant General_Parameters.Color := General_Parameters.MEDIUM_GREY;
   begin
      for X in The_Area.Position.X .. The_Area.Position.X + The_Area.Width - 1 loop
         -- horizontal frame
         Set_Pixel (X, The_Area.Position.Y, Color);
         Set_Pixel (X, The_Area.Position.Y + The_Area.Height - 1, Color);
      end loop;
      for Y in The_Area.Position.Y .. The_Area.Position.Y + The_Area.Height - 1 loop
         -- vertical frame
         Set_Pixel (The_Area.Position.X, Y, Color);
         Set_Pixel (The_Area.Position.X + The_Area.Width - 1, Y, Color);
      end loop;
   end Draw_Input_Field_Frame;


end Display.Draw;
