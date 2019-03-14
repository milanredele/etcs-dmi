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

package body Display is

   Relative_Layout : constant Layout_T (Sub_ID_T)
     := (A1 => ((0,0), 54, 54),
         A2 => ((0, 54), 54, 30),
         A3 => ((0, 84), 54, 191),
         A4 => ((0, 84+191), 54, 25),
         B0 => ((15, 25), 250, 250),
         B1 => ((115, 125), 50, 50),
         B2 => ((3, 13), 274, 274),
         B3 => ((122-36, 256), 36, 36),
         B4 => ((122, 256), 36, 36),
         B5 => ((122+36, 256), 36, 36),
         B6 => ((8, 256), 36, 36),
         B7 => ((236, 256), 36, 36),
         C1 => ((54+3*37, 0), 58, 50),
         C2 => ((54, 0), 37, 50),
         C3 => ((54+37, 0), 37, 50),
         C4 => ((54+2*37, 0), 37, 50),
         C5 => ((54+3*37+58, 0), 37, 50),
         C6 => ((54+4*37+58, 0), 37, 50),
         C7 => ((54+5*37+58, 0), 37, 50),
         C8 => ((0, 0), 54, 25),
         C9 => ((0, 25), 54, 25),
         D1 => ((0, 15), 40, 270),
         D2 => ((40, 15), 25, 270),
         D3 => ((40+25, 15), 25, 270),
         D4 => ((40+2*25, 15), 25, 270),
         D5 => ((40+3*25, 15), 18, 270),
         D6 => ((40+3*25+18, 15), 14, 270),
         D7 => ((40+3*25+18+14, 15), 93, 270),
         D8 => ((40+3*25+18+14+93, 15), 6, 270),
         D9 => ((0, 285), 40, 15),
         D10 => ((40, 285), 166, 15),
         D11 => ((40+166, 285), 40, 15),
         D12 => ((0, 0), 40, 15),
         D13 => ((40, 0), 166, 15),
         D14 => ((40+166, 0), 40, 15),
         E1 => ((0, 0), 54, 25),
         E2 => ((0, 25), 54, 25),
         E3 => ((0, 50), 54, 25),
         E4 => ((0, 75), 54, 25),
         E5 => ((54, 0), 234, 20),
         E6 => ((54, 20), 234, 20),
         E7 => ((54, 40), 234, 20),
         E8 => ((54, 60), 234, 20),
         E9 => ((54, 80), 234, 20),
         E10 => ((288, 0), 46, 50),
         E11 => ((288, 50), 46, 50),
         F1 => ((0, 0), 60, 50),
         F2 => ((0, 50), 60, 50),
         F3 => ((0, 100), 60, 50),
         F4 => ((0, 150), 60, 50),
         F5 => ((0, 200), 60, 50),
         F6 => ((0, 250), 60, 50),
         F7 => ((0, 300), 60, 50),
         F8 => ((0, 350), 60, 50),
         F9 => ((0, 400), 60, 50),
         G1 => ((0, 0), 49, 50),
         G2 => ((49, 0), 49, 50),
         G3 => ((98, 0), 49, 50),
         G4 => ((3*49, 0), 49, 50),
         G5 => ((4*49, 0), 50, 50),
         G6 => ((0, 50), 49, 50),
         G7 => ((49, 50), 49, 50),
         G8 => ((98, 50), 49, 50),
         G9 => ((3*49, 50), 49, 50),
         G10 => ((4*49, 50), 50, 50),
         G11 => ((0, 100), 63, 50),
         G12 => ((63, 100), 120, 50),
         G13 => ((183, 100), 63, 50));

   --------------
   -- Get_Area --
   --------------

   function Get_Area (ID: ID_T) return Area_T is

      function Get_Sub_Area (Sub_ID  : Sub_ID_T) return Area_T is
         function Area_With_Absolute_Position (Main, Sub : Area_T) return Area_T is
           (Main.Position + Sub.Position, Sub.Width, Sub.Height);

         Main : constant Area_T := Main_Layout (Sub_To_Main_Map (ID));

      begin
         return Area_With_Absolute_Position (Main, Relative_Layout (Sub_ID));
      end;

      Result : Area_T;
   begin
      case ID is
      when Main_ID_T =>
         Result := Main_Layout (ID);
      when others =>
         Result := Get_Sub_Area (ID);
      end case;
      return Result;
   end Get_Area;

   function Get_Sub_Area_With_Relative_Position (ID: Sub_ID_T) return Area_T is
     (Relative_Layout (ID));

   function Get_Sub_Layout (ID: Main_ID_With_Sub_T) return Layout_T is
      First_Array : constant array (Main_ID_With_Sub_T) of Sub_ID_T
        := (A => A1, B => B3, C => C1, D => D1, E => E1, F => F1, G => G1);
      Last_Array  : constant array (Main_ID_With_Sub_T) of Sub_ID_T := (A => Sub_ID_A_T'Last,
                                                                        B => Sub_ID_B_T'Last,
                                                                        C => Sub_ID_C_T'Last,
                                                                        D => Sub_ID_D_T'Last,
                                                                        E => Sub_ID_E_T'Last,
                                                                        F => Sub_ID_F_T'Last,
                                                                        G => Sub_ID_G_T'Last);
      Result : Layout_T (First_Array (ID) .. Last_Array (ID));
   begin
      for I in Result'Range loop
         Result (I) := Relative_Layout (I);
      end loop;
      return Result;
   end Get_Sub_Layout;

end Display;
