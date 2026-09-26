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

with Ada.Numerics; use Ada.Numerics;
with Speed_And_Distance; use Speed_And_Distance;

package Display.B_Area.Speed_Dial is
   
   procedure Draw;
   
private

   type Angle is digits 5 range -Pi .. Pi;
   -- DMI 8.2.1.1.11.1
   Lower_Limit   : constant Angle := Pi * (-144.0) / 180.0;
   Upper_Limit   : constant Angle := Pi * 144.0 / 180.0;
   Threshold_200 : constant Angle := Pi * 48.0 / 180.0;

   -- DMI 8.2.1.1.6
   Short_Line_Length : constant Radius_T := 15;
   -- DMI 8.2.1.1.7
   Long_Line_Length  : constant Radius_T := 25;

   -- DMI 8.2.1.2.4, Figure 34: the circular part of the pointer is 50
   -- cells across, the size of B1 (6.3.1.2 b)
   Pointer_Radius : constant := 25;

   function Speed_To_Angle (Speed : Speed_T) return Angle;

   procedure Draw_Speed_Indicator_Lines;

   procedure Draw_Speed_Indicator_Numbers;

   procedure Draw_Speed_Pointer;

   procedure Draw_Release_Speed_Digital;

   package Circular_Speed_Gauge is
      -- DMI 8.2.1.4.4
      Lowermost_Limit      : constant Angle := Pi * (-149.0) / 180.0;
      -- DMI 8.2.1.4.5
      Lowermost_Part_Color : constant General_Parameters.Color :=
        General_Parameters.DARK_GREY;

      -- The hooks are rectangles (Figure 37): the long side lies along
      -- the radius, from the outer border of the CSG towards the centre,
      -- and the short side along the scale, below the speed they show.
      Hook_Length            : constant Radius_T := 20;
      -- DMI 8.2.1.4.7: the hook of the CSG, 6 x 20 cells
      CSG_Hook_Width         : constant := 6;
      -- DMI 8.2.1.5.4, 8.2.1.5.5: the Basic Speed Hooks, 10 x 20 cells
      Basic_Speed_Hook_Width : constant := 10;
      Hook_Inner_Radius      : constant Radius_T :=
        B2_Radius_Outer - Hook_Length;

      -- DMI 8.2.1.6.4: below the release speed the CSG (9 cells, 8.2.1.4.6)
      -- is 3 cells of permitted speed at the inner part, a 1 cell line in
      -- the background colour and 5 cells of release speed at the outer
      -- part
      Release_Perm_Outer   : constant Radius_T := B2_Radius_Inner + 3;
      Release_Band_Inner   : constant Radius_T := Release_Perm_Outer + 1;

      -- CSG per Table 9 (FS and AD modes only)
      procedure Draw;

      -- Basic Speed Hook(s) per Table 10 (SM/OS/SR/SH/RV)
      procedure Draw_Hooks;
   end Circular_Speed_Gauge;

end Display.B_Area.Speed_Dial;
