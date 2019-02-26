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

package Speed_And_Distance is

   -- DMI 7.1.1.3
   type Monitoring_T is (CSM, -- Ceiling Speed Monitoring
                         PIM, -- Pre-Indication Monitoring
                         TSM, -- Target Speed Monitoring
                         RSM); -- Release Speed Monitoring
   
   type Supervision_Status_T is (NoS, -- Normal Status
                                 IndS, -- Indication
                                 OvS, -- Over-speed
                                 WaS, -- Warning
                                 IntS); -- Intervention
   
   -- DMI 8.2.1.1.3
   type Speed_Dial_Range_T is (Range_140, Range_180, Range_250, Range_400);
   type Speed_T is new Natural range 0 .. 400;
   Max_Speed_Map : constant array (Speed_Dial_Range_T) of Speed_T := (Range_140 => 140,
                                                                      Range_180 => 180,
                                                                      Range_250 => 250,
                                                                      Range_400 => 400);
      
   type Speed_Params is
      record
         Vperm, Vtarget, Vwsl, Visl, Vsbi, Vrelease : Speed_T;
         Vrelease_Exists : Boolean := False;
      end record;

   -- Set the current speed
   procedure Set_Speed (New_Speed : Speed_T);
   
   function Get_Speed return Speed_T;
   
   procedure Set_Speed_Params (New_Speed_Params : Speed_Params);
   
   function Get_Speed_Params return Speed_Params;
   
   procedure Set_Seed_Dial_Range (The_Range : Speed_Dial_Range_T);
   
   function Get_Speed_Dial_Range return Speed_Dial_Range_T;
   
   procedure Set_Monitoring_Mode (The_Mode : Monitoring_T);
   
   function Get_Monitoring_Mode return Monitoring_T;
   
   function Get_Supervision_Status return Supervision_Status_T;
   
private
   Monitoring_Mode    : Monitoring_T;
   Supervision_Status : Supervision_Status_T;
   Speed              : Speed_Params;
   Vcurrent           : Speed_T := 0;
   Speed_Dial_Range   : Speed_Dial_Range_T := Range_180;
end Speed_And_Distance;
