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

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Speed_And_Distance;

package body Display.A_Area.A_3 is

   procedure Draw_Indicators is
      procedure Draw_Indicator (X : Width_T; Y : Height_T; Wide : Boolean := False) is
         -- DMI 8.2.2.1.4
         Short_Length : constant Width_T  := 9;
         Long_Length  : constant Width_T  := 13;
         Line_Start_X : constant Width_T  := X + The_A3_Area.Position.X;
         Line_Start_Y : constant Height_T := Y + The_A3_Area.Position.Y;
         -- DMI 8.2.2.1.5
         The_Color    : constant General_Parameters.Color := General_Parameters.GREY;
         
         Length : Width_T := Short_Length;
      begin
         if Wide then
            Length := Long_Length;
            for I in Line_Start_X .. Line_Start_X + Length loop
               A_Buffer.Set_Pixel (I, Line_Start_Y+1, The_Color);
            end loop;
         end if;
            
         for I in Line_Start_X .. Line_Start_X + Length loop
            A_Buffer.Set_Pixel (I, Line_Start_Y, The_Color);
         end loop;
      end Draw_Indicator;
   begin
      -- DMI 8.2.2.1.4
      -- The -1 for y position makes no sense to me so shifting by 1
      Draw_Indicator (12, 0, True);
      Draw_Indicator (16, 7);
      Draw_Indicator (16, 14);
      Draw_Indicator (16, 23);
      Draw_Indicator (16, 33);
      Draw_Indicator (12, 46, True);
      Draw_Indicator (16, 60);
      Draw_Indicator (16, 80);
      Draw_Indicator (16, 106);
      Draw_Indicator (16, 153);
      Draw_Indicator (12, 186, True);
   end Draw_Indicators;
   
   procedure Draw_Bar is
      -- DMI 8.2.2.1.6
      Distance : Speed_And_Distance.Distance_T := Speed_And_Distance.Get_Distance_To_Target;
      use type Speed_And_Distance.Distance_T;
      Left_X   : constant Width_T  := 29 + The_A3_Area.Position.X;
      Bottom_Y : constant Height_T := 186 + The_A3_Area.Position.Y;
      Right_X  : constant Width_T  := Left_X + 9;
      Top_Y    :          Height_T;
      -- DMI 8.2.2.1.7
      The_Color : constant General_Parameters.Color := General_Parameters.GREY;
   begin
      if Distance > 1000 then
         Distance := 1000;
      end if;
      if Distance <= 100 then
         -- linear scale
         Top_Y := Bottom_Y - Height_T (Float (Distance) * 0.33); 
      else
         -- log scale
         Top_Y := Bottom_Y - Height_T (186.0 * Log (Float (Distance) * (17.0/1000.0), 17.0));
      end if;
      
      for Y in Top_Y .. Bottom_Y loop
         for X in Left_X .. Right_X loop
            A_Buffer.Set_Pixel(X, Y, The_Color);
         end loop;
      end loop;
      
   end Draw_Bar;
   
   procedure Draw is
   begin
      Draw_Indicators;
      Draw_Bar;
   end Draw;

end Display.A_Area.A_3;
