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
with Display.B_Area.Speed_Dial;
package body Display.B_Area is

   procedure Fill_Background is
   begin
      B_Buffer.Fill (General_Parameters.Background_Color);
   end Fill_Background;

   ----------
   -- Draw --
   ----------

   procedure Draw is
   begin
      Fill_Background;
      Speed_Dial.Draw;
   end Draw;


end Display.B_Area;
