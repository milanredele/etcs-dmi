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

with Speed_And_Distance; use Speed_And_Distance;

package body Display.A_Area.A_2 is

   
   procedure Draw is
      Distance : Distance_T := Get_Distance_To_Target;
      -- DMI 8.2.2.2.4
      X : constant A_Buffer.Area_Width_T  := 44;
      -- DMI 8.2.2.2.5
      Y : constant A_Buffer.Area_Height_T := 74;
   begin
      -- DMI 8.2.2.2.6
      Distance := (Distance + 5) / 10 * 10; -- rounding to nearest 10
      
      declare
         Dist_String : constant Wide_String := Distance_T'Wide_Image (Distance);
      begin
         A_Buffer.Draw_String (Pen_X         => X,
                               Pen_Y         => Y,
                               The_String    => Dist_String (2 .. Dist_String'Last),
                               The_Size      => 10,
                               The_Color     => General_Parameters.GREY,
                               The_Alignment => A_Buffer.Right);
      end;
   end Draw;

end Display.A_Area.A_2;
