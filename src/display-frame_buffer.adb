--  ETCS DMI
--  Copyright (C) 2019  Milan Redele
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma Ada_2012;
with Ada.Unchecked_Conversion;
with Font.FreeSans_10;
with Font.FreeSans_12;
with Font.FreeSans_16;
with Font.FreeSans_17;
with System;

package body Display.Frame_Buffer is

   function Get_Pixel (X : Area_Width_T;
                       Y : Area_Height_T) return General_Parameters.Color is
     (Buffer (X + Y * Area.Width));

   procedure Set_Pixel (X : Area_Width_T;
                        Y : Area_Height_T;
                        The_Color : General_Parameters.Color) is
   begin
      Buffer (X + Y * Area.Width) := The_Color;
   end Set_Pixel;

   procedure Fill (The_Color : General_Parameters.Color) is
   begin
      for I in Buffer'Range loop
         Buffer (I) := The_Color;
      end loop;
      declare
         Subs_With_Frame : constant Area_Array := Get_Sub_Requiring_Border (Area_ID);
      begin
         for Sub of Subs_With_Frame loop
            Draw_Frame (Sub);
         end loop;
      end;
   end Fill;

   procedure Fill_Area (The_Area : Area_T; The_Color : General_Parameters.Color) is
   begin
      for Y in The_Area.Position.Y .. The_Area.Position.Y + The_Area.Height - 1 loop
         for X in The_Area.Position.X .. The_Area.Position.X + The_Area.Width - 1 loop
            Set_Pixel (X, Y, The_Color);
         end loop;
      end loop;
   end Fill_Area;

   procedure Draw_Glyph (Pen_X : Area_Width_T;
                         Pen_Y : Area_Height_T;
                         The_Glyph  : Font.Glyph;
                         The_Bitmap : Font.Bitmap_T;
                         The_Color  : General_Parameters.Color) is
      Top    : constant Area_Height_T := Pen_Y - The_Glyph.Top;
      Bottom : constant Area_Height_T := Top + The_Glyph.Height;
      Left   : constant Area_Width_T  := Pen_X + The_Glyph.Left;
      Right  : constant Area_Width_T  := Left + The_Glyph.Width;
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

   procedure Draw_String (Pen_X : Area_Width_T;
                          Pen_Y : Area_Height_T;
                          The_String : Font.Glyph_String;
                          The_Bitmap : Font.Bitmap_T;
                          The_Color  : General_Parameters.Color;
                          The_Alignment : Text_Alignment := Left) is
      Cur_X : Area_Width_T  := Pen_X;
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

   procedure Draw_String (Pen_X : Area_Width_T;
                          Pen_Y : Area_Height_T;
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

   procedure Dump (File_Name : String) is
      Output_File : Ada.Streams.Stream_IO.File_Type;
      Output_Stream : Ada.Streams.Stream_IO.Stream_Access;
   begin
      Ada.Streams.Stream_IO.Create (File => Output_File,
                                    Mode => Ada.Streams.Stream_IO.Out_File,
                                    Name => File_Name);
      Output_Stream := Ada.Streams.Stream_IO.Stream (Output_File);

      Buffer_T'Write (Output_Stream, Buffer);

      Ada.Streams.Stream_IO.Close (Output_File);
   end Dump;

   procedure Write_Buffer (Stream : not null access Ada.Streams.Root_Stream_Type'Class) is
      use type Ada.Streams.Stream_Element_Offset;

      Item_Size : constant Ada.Streams.Stream_Element_Offset :=
        Buffer_T'Object_Size / Ada.Streams.Stream_Element'Size;

      type SEA_Pointer is
        access all Ada.Streams.Stream_Element_Array (1 .. Item_Size);

      function As_SEA_Pointer is
        new Ada.Unchecked_Conversion (System.Address, SEA_Pointer);
   begin
      Ada.Streams.Write (Stream.all, As_SEA_Pointer (Buffer'Address).all);
   end Write_Buffer;

   procedure Write (Output_Stream : Ada.Streams.Stream_IO.Stream_Access) is
   begin
      Short_Integer'Write (Output_Stream, Short_Integer (Area.Position.X));
      Short_Integer'Write (Output_Stream, Short_Integer (Area.Position.Y));
      Short_Integer'Write (Output_Stream, Short_Integer (Area.Width));
      Short_Integer'Write (Output_Stream, Short_Integer (Area.Height));
      Write_Buffer (Output_Stream);
   end Write;

end Display.Frame_Buffer;
