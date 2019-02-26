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
