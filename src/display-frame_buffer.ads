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

with Font;

generic Area_ID : in ID_T;
package Display.Frame_Buffer is

   Area : constant Area_T := Get_Area (Area_ID);
   
   subtype Area_Width_T is Width_T range 0 .. Area.Width;
   subtype Area_Height_T is Height_T range 0 .. Area.Height;
   
   function Get_Pixel (X : Area_Width_T;
                       Y : Area_Height_T) return General_Parameters.Color;
   
   procedure Set_Pixel (X : Area_Width_T; 
                        Y : Area_Height_T;
                        The_Color : General_Parameters.Color);
   
   procedure Fill (The_Color : General_Parameters.Color);
   
   procedure Draw_Glyph (Pen_X : Area_Width_T; 
                         Pen_Y : Area_Height_T; 
                         The_Glyph  : Font.Glyph; 
                         The_Bitmap : Font.Bitmap_T;
                         The_Color  : General_Parameters.Color);
   
   procedure Draw_String (Pen_X : Area_Width_T; 
                          Pen_Y : Area_Height_T; 
                          The_String : Font.Glyph_String; 
                          The_Bitmap : Font.Bitmap_T;
                          The_Color  : General_Parameters.Color);
   
   procedure Draw_String (Pen_X : Area_Width_T; 
                          Pen_Y : Area_Height_T; 
                          The_String : Wide_String; 
                          The_Size   : Font.Size_T;
                          The_Color  : General_Parameters.Color);
   
   procedure Dump (File_Name : String);

private
   type Buffer_T is array (Natural range 0 .. Area.Width * Area.Height) of General_Parameters.Color;
   Buffer : Buffer_T;

end Display.Frame_Buffer;
