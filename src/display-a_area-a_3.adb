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

with Speed_And_Distance;

package body Display.A_Area.A_3 is

   use type Speed_And_Distance.Distance_T;

   -- DMI 8.2.2.1.4 / 8.2.2.1.6: the distance scale. A3 cells are counted
   -- from the top left corner of A3; Table 12 gives the top left corner
   -- of each distance indicator line and puts 0 m at row 185, 100 m at
   -- row 152 and 1000 m at row -1 (the last row of A2, inside the
   -- A2+A3 border of 8.1.1.4 b), i.e. 33 cells for the linear 0-100 m
   -- and 153 cells for the logarithmic decade 100-1000 m. Every row of
   -- Table 12 is floor (185 - 0.33 d) below 100 m and
   -- floor (152 - 153 log10 (d / 100)) above, so the bar uses the same
   -- mapping: the height in cells of the bar for a distance d is
   -- 185 - that row, the bar standing on the bottom edge of row 185
   -- (the grid point (29,186) of 8.2.2.1.6, as Figure 50 draws it).
   -- 0 m is no bar, 100 m 33 cells, 1000 m 186 cells.

   Bar_Bottom : constant := 185;  -- last row of the bar
   Linear_Cells : constant := 33;  -- 0 .. 100 m
   Log_Cells : constant := 153;  -- 100 .. 1000 m

   -- The logarithmic part in integers, so that every platform draws the
   -- same cells: Log_Limit (K) = floor (100 * 10 ** (K / 153)) is the
   -- longest distance in metres whose height is 33 + K cells.
   type Log_Index_T is range 1 .. Log_Cells;
   Log_Limit : constant array (Log_Index_T) of Speed_And_Distance.Distance_T :=
       (101, 103, 104, 106, 107, 109, 111, 112, 114, 116, 118,
         119, 121, 123, 125, 127, 129, 131, 133, 135, 137, 139,
         141, 143, 145, 147, 150, 152, 154, 157, 159, 161, 164,
         166, 169, 171, 174, 177, 179, 182, 185, 188, 191, 193,
         196, 199, 202, 205, 209, 212, 215, 218, 222, 225, 228,
         232, 235, 239, 243, 246, 250, 254, 258, 261, 265, 270,
         274, 278, 282, 286, 291, 295, 300, 304, 309, 313, 318,
         323, 328, 333, 338, 343, 348, 354, 359, 364, 370, 375,
         381, 387, 393, 399, 405, 411, 417, 424, 430, 437, 443,
         450, 457, 464, 471, 478, 485, 492, 500, 508, 515, 523,
         531, 539, 547, 556, 564, 573, 581, 590, 599, 608, 617,
         627, 636, 646, 656, 666, 676, 686, 696, 707, 718, 729,
         740, 751, 762, 774, 786, 797, 810, 822, 834, 847, 860,
         873, 886, 900, 913, 927, 941, 955, 970, 985, 1000);

   function Bar_Height (Distance : Speed_And_Distance.Distance_T)
                        return Natural is
      -- 8.2.2.1.6: above 1000 m the bar shows 1000 m
      D : constant Speed_And_Distance.Distance_T :=
        Speed_And_Distance.Distance_T'Min (Distance, 1000);
   begin
      if D <= 100 then
         -- 33 cells for 100 m, rounded up: any distance above 0 m shows
         return (Linear_Cells * Natural (D) + 99) / 100;
      end if;
      for K in Log_Index_T loop
         if D <= Log_Limit (K) then
            return Linear_Cells + Natural (K);
         end if;
      end loop;
      return Linear_Cells + Log_Cells;
   end Bar_Height;

   procedure Draw_Indicators is
      -- DMI 8.2.2.1.5
      The_Color : constant General_Parameters.Color :=
        General_Parameters.GREY;

      -- DMI 8.2.2.1.4: (X, Y) is the top left cell of the line in A3 as
      -- in Table 12; a long line (0, 500 and 1000 m) is 13 cells long
      -- and 2 cells wide, a short line 9 cells long and 1 cell wide
      procedure Draw_Indicator (X : Width_T; Y : Integer;
                                Long : Boolean := False) is
         Length : constant Width_T := (if Long then 13 else 9);
         Width  : constant Height_T := (if Long then 2 else 1);
      begin
         A_Buffer.Fill_Area
           (((The_A3_Area.Position.X + X, The_A3_Area.Position.Y + Y),
             Length, Width),
            The_Color);
      end Draw_Indicator;
   begin
      -- DMI 8.2.2.1.4 Table 12
      Draw_Indicator (12, -1, Long => True);   -- 1000
      Draw_Indicator (16, 6);                  --  900
      Draw_Indicator (16, 13);                 --  800
      Draw_Indicator (16, 22);                 --  700
      Draw_Indicator (16, 32);                 --  600
      Draw_Indicator (12, 45, Long => True);   --  500
      Draw_Indicator (16, 59);                 --  400
      Draw_Indicator (16, 79);                 --  300
      Draw_Indicator (16, 105);                --  200
      Draw_Indicator (16, 152);                --  100
      Draw_Indicator (12, 185, Long => True);  --    0
   end Draw_Indicators;

   procedure Draw_Bar is
      -- DMI 8.2.2.1.6: 10 cells wide, left column 29, on the bottom
      -- edge of row 185; DMI 8.2.2.1.7: grey
      Height : constant Natural :=
        Bar_Height (Speed_And_Distance.Get_Distance_To_Target);
   begin
      if Height > 0 then
         A_Buffer.Fill_Area
           (((The_A3_Area.Position.X + 29,
              The_A3_Area.Position.Y + Bar_Bottom + 1 - Height),
             10, Height),
            General_Parameters.GREY);
      end if;
   end Draw_Bar;

   procedure Draw is
   begin
      Draw_Indicators;
      Draw_Bar;
   end Draw;

end Display.A_Area.A_3;
