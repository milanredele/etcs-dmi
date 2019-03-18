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

package Display.A_Area.A_2 is

   -- DMI 8.2.2.2 Distance to target digital
   procedure Draw;
   
private
   -- DMI 8.2.2.2.2
   The_A2_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (A2);

end Display.A_Area.A_2;
