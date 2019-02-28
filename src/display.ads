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

with General_Parameters;

package Display is

   type ID_T is 
     (A, B, C, D, E, F, G, Y, Z,
      A1, A2, A3, A4,
      B0, B1, B2, B3, B4, B5, B6, B7,
      C1, C2, C3, C4, C5, C6, C7, C8, C9,
      D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13, D14,
      E1, E2, E3, E4, E5, E6, E7, E8, E9, E10, E11,
      F1, F2, F3, F4, F5, F6, F7, F8, F9,
      G1, G2, G3, G4, G5, G6, G7, G8, G9, G10, G11, G12, G13);
      
   subtype Main_ID_T is ID_T range A .. Z;
   subtype Main_ID_With_Sub_T is Main_ID_T range A .. G;
   subtype Sub_ID_T is ID_T range A1 .. G13;
   subtype Sub_ID_A_T is Sub_ID_T range A1 .. A4;
   subtype Sub_ID_B_T is Sub_ID_T range B3 .. B7; -- B0, B1, B2 intentionally left out (don't have border)
   subtype Sub_ID_C_T is Sub_ID_T range C1 .. C9;
   subtype Sub_ID_D_T is Sub_ID_T range D1 .. D14;
   subtype Sub_ID_E_T is Sub_ID_T range E1 .. E11;
   subtype Sub_ID_F_T is Sub_ID_T range F1 .. F9;
   subtype Sub_ID_G_T is Sub_ID_T range G1 .. G13;
   subtype Width_T is Integer range 0 .. General_Parameters.Display_Resolution.Width;
   subtype Height_T is Integer range 0 .. General_Parameters.Display_Resolution.Height;
   
   type Position_T is
      record
         X : Width_T;
         Y : Height_T;
      end record;
   
   type Area_T is
      record
         Position : Position_T;
         Width : Width_T;
         Height : Height_T;
      end record;
   
   type Layout_T is array (ID_T range <>) of Area_T;
   
   function Get_Area (ID: ID_T) return Area_T;
   
   function Get_Sub_Area_With_Relative_Position (ID: Sub_ID_T) return Area_T;
   
   function Get_Sub_Layout (ID: Main_ID_With_Sub_T) return Layout_T;
   
private
   
   
   Main_Layout : constant Layout_T (Main_ID_T)
     := (A => ((  0,  15),  54, 300),
         B => (( 54,  15), 280, 300),
         C => ((  0, 315), 334,  50),
         D => ((334,  15), 246, 300),
         E => ((  0, 365), 334, 100),
         F => ((580,  15),  60, 450),
         G => ((334, 315), 246, 150),
         Y => ((  0, 465), 640,  15),
         Z => ((  0,   0), 640,  15));
   
   type Sub_To_Main_Map_T is array (Sub_ID_T) of Main_ID_T;
   
   Sub_To_Main_Map : constant Sub_To_Main_Map_T
     := (A1 .. A4  => A,
         B0 .. B7  => B,
         C1 .. C9  => C,
         D1 .. D14 => D,
         E1 .. E11 => E,
         F1 .. F9  => F,
         G1 .. G13 => G);
   
   function "+" (Left, Right : Position_T) return Position_T is
     (Left.X + Right.X, Left.Y + Right.Y);
   
   
end Display;
