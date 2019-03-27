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

package Display.C_Area is

   package C_Buffer is new Display.Frame_Buffer (C);
   
   procedure Draw;
   
private
   
   The_Area    : constant Area_T := Get_Area (C);
   The_C1_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (C1);
   The_C7_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (C7);
   The_C8_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (C8);
   
   Flashing_Frame_Displayed : Boolean := False;
   
   procedure Draw_C1;
   procedure Draw_C7;
   procedure Draw_C8;

end Display.C_Area;
