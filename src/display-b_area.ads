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

with Display.Frame_Buffer;

package Display.B_Area is
   
   package B_Buffer is new Display.Frame_Buffer (B);
   
   -- Draw the current state
   procedure Draw;
   
private
   
   The_Area   : constant Area_T := Get_Area (B);
   The_Center : constant Position_T := (The_Area.Width  / 2,
                                        The_Area.Height / 2);

   subtype Radius_T is Natural range 0 .. 137;
   -- DMI 6.3.1.2.a
   B0_Radius : constant Radius_T := 125;
   -- DMI 6.3.1.2.c
   B2_Radius_Inner : constant Radius_T := 128;
   B2_Radius_Outer : constant Radius_T := 137;
   
end Display.B_Area;
