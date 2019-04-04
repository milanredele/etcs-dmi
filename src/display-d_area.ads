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

package Display.D_Area is

   package D_Buffer is new Display.Frame_Buffer (D);
   
   procedure Draw;
   
private
   
   The_Area    : constant Area_T := Get_Area (D);
   Track_Ahead_Free_Area : constant Area_T := ((0, 50), 244, 50);
   
   procedure Draw_Track_Ahead_Free;

end Display.D_Area;
