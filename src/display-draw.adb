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

   procedure Draw_Glyph (Pen_X : Width_T;
                         Pen_Y : Height_T;
                         The_Glyph  : Font.Glyph;
                         The_Bitmap : Font.Bitmap_T;
                         The_Color  : General_Parameters.Color) is
      Top    : constant Height_T := Pen_Y - The_Glyph.Top;
      Bottom : constant Height_T := Top + The_Glyph.Height;
      Left   : constant Width_T  := Pen_X + The_Glyph.Left;
      Right  : constant Width_T  := Left + The_Glyph.Width;
      Pos    :          Positive      := The_Glyph.Bitmap_Pos;
   begin
      for J in Top .. Bottom - 1 loop
         for I in Left .. Right - 1 loop
            if The_Bitmap (Pos) then
               Set_Pixel (I, J, The_Color);
            end if;
            Pos := Pos + 1;
         end loop;
      end loop;
   end Draw_Glyph;

   procedure Draw_String (Pen_X : Width_T;
                          Pen_Y : Height_T;
                          The_String : Font.Glyph_String;
                          The_Bitmap : Font.Bitmap_T;
                          The_Color  : General_Parameters.Color;
                          The_Alignment : Text_Alignment := Left) is
      Cur_X : Width_T  := Pen_X;
   begin
      if The_Alignment = Center then
         declare
            Length : Width_T := 0;
         begin
            for I in The_String'Range loop
               Length := Length + The_String (I).Advance_X;
            end loop;
            Cur_X := Cur_X - Length / 2;
         end;
      end if;

      if The_Alignment in Left | Center then
         for I in The_String'Range loop
            Draw_Glyph (Pen_X      => Cur_X,
                        Pen_Y      => Pen_Y,
                        The_Glyph  => The_String (I),
                        The_Bitmap => The_Bitmap,
                        The_Color  => The_Color);
            Cur_X := Cur_X + The_String (I).Advance_X;
         end loop;
      else
         for I in reverse The_String'Range loop
            Cur_X := Cur_X - The_String (I).Advance_X;
            Draw_Glyph (Pen_X      => Cur_X,
                        Pen_Y      => Pen_Y,
                        The_Glyph  => The_String (I),
                        The_Bitmap => The_Bitmap,
                        The_Color  => The_Color);
         end loop;
      end if;
   end Draw_String;

   procedure Draw_String (Pen_X : Width_T;
                          Pen_Y : Height_T;
                          The_String : Wide_String;
                          The_Size   : Font.Size_T;
                          The_Color  : General_Parameters.Color;
                          The_Alignment : Text_Alignment := Left) is
      function Get_Glyph_Map return Font.Glyph_Map is
      begin
         case The_Size is
            when 10 =>
               return Font.FreeSans_10.Glyphs;
            when 12 =>
               return Font.FreeSans_12.Glyphs;
            when 16 =>
               return Font.FreeSans_16.Glyphs;
            when 17 =>
               return Font.FreeSans_17.Glyphs;
            when 18 =>
               return Font.FreeSans_18.Glyphs;
            when others =>
               raise Program_Error with "Character size not available";
         end case;
      end Get_Glyph_Map;

      function Get_Bitmap return Font.Bitmap_T is
      begin
         case The_Size is
            when 10 =>
               return Font.FreeSans_10.Bitmap;
            when 12 =>
               return Font.FreeSans_12.Bitmap;
            when 16 =>
               return Font.FreeSans_16.Bitmap;
            when 17 =>
               return Font.FreeSans_17.Bitmap;
            when 18 =>
               return Font.FreeSans_18.Bitmap;
            when others =>
               raise Program_Error with "Character size not available";
         end case;
      end Get_Bitmap;

      Glyphs  : Font.Glyph_String (1 .. The_String'Length);
      Idx     : Positive := Glyphs'First;
      Glyph_M : constant Font.Glyph_Map := Get_Glyph_Map;
      Bitmap  : constant Font.Bitmap_T  := Get_Bitmap;
   begin

      for I in The_String'Range loop
         declare
            Invalid_Character_Error : exception;
            C : constant Wide_Character := The_String (I);
         begin
            Glyphs (Idx) := Glyph_M (C);
            Idx := Idx + 1;
         exception
            when Constraint_Error =>
               raise Invalid_Character_Error;
         end;
      end loop;
      Draw_String (Pen_X      => Pen_X,
                   Pen_Y      => Pen_Y,
                   The_String => Glyphs,
                   The_Bitmap => Bitmap,
                   The_Color  => The_Color,
                   The_Alignment => The_Alignment);

   end Draw_String;

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
