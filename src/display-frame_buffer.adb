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

--  Thin per-area adapter over Display.Screen / Display.Draw: shifts
--  area-relative coordinates to absolute screen coordinates.

pragma Ada_2012;
with Display.Draw;
with Display.Screen;

package body Display.Frame_Buffer is

   function Absolute (The_Area : Area_T) return Area_T is
     ((Area.Position + The_Area.Position, The_Area.Width, The_Area.Height));

   function Get_Pixel (X : Area_Width_T;
                       Y : Area_Height_T) return General_Parameters.Color is
     (Screen.Get_Pixel (Area.Position.X + X, Area.Position.Y + Y));

   procedure Set_Pixel (X : Area_Width_T;
                        Y : Area_Height_T;
                        The_Color : General_Parameters.Color) is
   begin
      Screen.Set_Pixel (Area.Position.X + X, Area.Position.Y + Y, The_Color);
   end Set_Pixel;

   procedure Fill (The_Color : General_Parameters.Color) is
   begin
      Screen.Fill_Area (Area, The_Color);
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
      Screen.Fill_Area (Absolute (The_Area), The_Color);
   end Fill_Area;

   procedure Draw_Glyph (Pen_X : Area_Width_T;
                         Pen_Y : Area_Height_T;
                         The_Glyph  : Font.Glyph;
                         The_Bitmap : Font.Bitmap_T;
                         The_Color  : General_Parameters.Color) is
   begin
      Draw.Draw_Glyph (Area.Position.X + Pen_X, Area.Position.Y + Pen_Y,
                       The_Glyph, The_Bitmap, The_Color);
   end Draw_Glyph;

   procedure Draw_String (Pen_X : Area_Width_T;
                          Pen_Y : Area_Height_T;
                          The_String : Font.Glyph_String;
                          The_Bitmap : Font.Bitmap_T;
                          The_Color  : General_Parameters.Color;
                          The_Alignment : Text_Alignment := Left) is
   begin
      Draw.Draw_String (Area.Position.X + Pen_X, Area.Position.Y + Pen_Y,
                        The_String, The_Bitmap, The_Color,
                        Draw.Text_Alignment'Val (Text_Alignment'Pos (The_Alignment)));
   end Draw_String;

   procedure Draw_String (Pen_X : Area_Width_T;
                          Pen_Y : Area_Height_T;
                          The_String : Wide_String;
                          The_Size   : Font.Size_T;
                          The_Color  : General_Parameters.Color;
                          The_Alignment : Text_Alignment := Left) is
   begin
      Draw.Draw_String (Area.Position.X + Pen_X, Area.Position.Y + Pen_Y,
                        The_String, The_Size, The_Color,
                        Draw.Text_Alignment'Val (Text_Alignment'Pos (The_Alignment)));
   end Draw_String;

   procedure Draw_Symbol (The_Symbol   : Symbol.T;
                          The_Position : Position_T) is
   begin
      Draw.Draw_Symbol (The_Symbol, Area.Position + The_Position);
   end Draw_Symbol;

   procedure Draw_Frame (The_Area : Area_T) is
   begin
      Draw.Draw_Frame (Absolute (The_Area));
   end Draw_Frame;

   procedure Draw_Yellow_Frame (The_Area : Area_T; Show : Boolean := True) is
   begin
      Draw.Draw_Yellow_Frame (Absolute (The_Area), Show);
   end Draw_Yellow_Frame;

   procedure Draw_Button_Frame (The_Area : Area_T) is
   begin
      Draw.Draw_Button_Frame (Absolute (The_Area));
   end Draw_Button_Frame;

   procedure Draw_Input_Field_Frame (The_Area : Area_T) is
   begin
      Draw.Draw_Input_Field_Frame (Absolute (The_Area));
   end Draw_Input_Field_Frame;

end Display.Frame_Buffer;
