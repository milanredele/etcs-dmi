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

   -- Absolute touch sensitive area of the TAF "Yes" answer (8.2.3.3)
   function TAF_Answer_Area return Area_T;

private

   The_Area    : constant Area_T := Get_Area (D);
   -- DMI 8.2.3.3.3-.5, .8: the question box, 244x50, and its question
   -- part, 162 cells wide. Choice: the box starts at X 1 of D as Figure
   -- 60 draws it (cells 335-578 of the screen, inside the border of D,
   -- 244 = 246 - 2); the (0,50) of 8.2.3.3.5 would cover the left border
   -- of D (layer -1, 8.1.1.4 b) and leave the cell left of its right
   -- border empty. Y 50 is the same in the text and the figure.
   Track_Ahead_Free_Area : constant Area_T := ((1, 50), 244, 50);
   TAF_Question_Width : constant Width_T := 162;

   procedure Draw_Track_Ahead_Free;

end Display.D_Area;
