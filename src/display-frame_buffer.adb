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
with Ada.Streams.Stream_IO;

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
      if Area_ID in Main_ID_With_Sub_T then
         declare
            Subs : constant Layout_T := Get_Sub_Layout (Area_ID);
         begin
            for Sub of Subs loop
               -- draw top and bottom border
               for X in Sub.Position.X .. Sub.Position.X + Sub.Width - 1 loop
                  Set_Pixel (X, Sub.Position.Y, General_Parameters.BLACK);
                  Set_Pixel (X, Sub.Position.Y + Sub.Height - 1, General_Parameters.SHADOW);
               end loop;
               -- draw left and right border
               for Y in Sub.Position.Y .. Sub.Position.Y + Sub.Height - 1 loop
                  Set_Pixel (Sub.Position.X, Y, General_Parameters.BLACK);
                  Set_Pixel (Sub.Position.X + Sub.Width - 1, Y, General_Parameters.SHADOW);
               end loop;
            end loop;
         end;
      end if;
   end Fill;

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
                          The_Color  : General_Parameters.Color) is
      Cur_X : Area_Width_T  := Pen_X;
   begin
      for I in The_String'Range loop
         Draw_Glyph (Pen_X      => Cur_X,
                     Pen_Y      => Pen_Y,
                     The_Glyph  => The_String (I),
                     The_Bitmap => The_Bitmap,
                     The_Color  => The_Color);
         Cur_X := Cur_X + The_String (I).Advance_X;
      end loop;
   end Draw_String;

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

end Display.Frame_Buffer;
