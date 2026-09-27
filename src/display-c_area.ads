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

package Display.C_Area is

   package C_Buffer is new Display.Frame_Buffer (C);

   procedure Draw;

   -- Absolute area of C1; per 5.4.1.4 it is the acknowledgement button
   -- while a mode/level acknowledgement is displayed there
   function C1_Absolute_Area return Area_T;

   -- Absolute area of the tunnel stopping area toggle (C2+C3+C4, 8.2.3.6.4)
   function Tunnel_Toggle_Area return Area_T;

   -- Absolute C9 + C8 + E1 column: the extended sensitive area of the
   -- brake intervention acknowledgement (8.2.2.3.5)
   function Brake_Ack_Area return Area_T;

private

   The_Area    : constant Area_T := Get_Area (C);
   The_C1_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (C1);
   The_C2_C4_Area : constant Area_T :=
     (Get_Sub_Area_With_Relative_Position (C2).Position, 111, 50);
   The_C2_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (C2);
   The_C6_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (C6);
   The_C7_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (C7);
   The_C8_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (C8);
   The_C9_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (C9);

   Flashing_Frame_Displayed : Boolean := False;

   procedure Draw_C1;
   procedure Draw_C2_C4;
   procedure Draw_C6;
   procedure Draw_C7;
   procedure Draw_C8;
   procedure Draw_C9;

end Display.C_Area;
