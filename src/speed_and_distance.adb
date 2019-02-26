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
package body Speed_And_Distance is


   procedure Set_Speed (New_Speed : Speed_T) is
   begin
      case Monitoring_Mode is
         when CSM | PIM =>
            -- DMI 7.3.2.1
            if New_Speed > Speed.Vsbi or Supervision_Status = IntS then
               -- DMI 7.2.4.1
               Supervision_Status := IntS;
            elsif New_Speed > Speed.Vwsl
              or (Supervision_Status = WaS and New_Speed > Speed.Vperm) then
               -- DMI 7.2.3.1
               Supervision_Status := WaS;
            elsif New_Speed > Speed.Vperm then
               -- DMI 7.2.2.1
               Supervision_Status := OvS;
            else
               -- DMI 7.2.1.1
               Supervision_Status := NoS;
            end if;
         when TSM =>
            if New_Speed > Speed.Vsbi or Supervision_Status = IntS then
               -- DMI 7.4.5.1
               Supervision_Status := IntS;
            elsif New_Speed > Speed.Vwsl
              or (Supervision_Status = WaS and New_Speed > Speed.Vperm) then
               -- DMI 7.4.4.1
               Supervision_Status := WaS;
            elsif New_Speed > Speed.Vperm then
               -- DMI 7.4.3.1
               Supervision_Status := OvS;
            elsif New_Speed > Speed.Visl
              or (Supervision_Status = IndS and New_Speed >= Speed.Vtarget) then
               -- DMI 7.4.2.1
               Supervision_Status := IndS;
            else
               -- DMI 7.4.1.1
               Supervision_Status := NoS;
            end if;
         when RSM =>
            if New_Speed > Speed.Vrelease or Supervision_Status = IntS then
               -- DMI 7.5.2.1
               Supervision_Status := IntS;
            else
               -- DMI 7.5.1.1
               Supervision_Status := IndS;
            end if;
      end case;

      Vcurrent := New_Speed;

   end Set_Speed;

   function Get_Speed return Speed_T is
      (Vcurrent);

   procedure Set_Speed_Params (New_Speed_Params : Speed_Params) is
   begin
      Speed := New_Speed_Params;
      Set_Speed (Vcurrent); -- To make sure model is consistent
   end Set_Speed_Params;

   function Get_Speed_Params return Speed_Params is
     (Speed);

   procedure Set_Seed_Dial_Range (The_Range : Speed_Dial_Range_T) is
   begin
      Speed_Dial_Range := The_Range;
   end Set_Seed_Dial_Range;

   function Get_Speed_Dial_Range return Speed_Dial_Range_T is
     (Speed_Dial_Range);

   procedure Set_Monitoring_Mode (The_Mode : Monitoring_T) is
   begin
      Monitoring_Mode := The_Mode;
   end Set_Monitoring_Mode;

   function Get_Monitoring_Mode return Monitoring_T is
     (Monitoring_Mode);

   function Get_Supervision_Status return Supervision_Status_T is
      (Supervision_Status);

end Speed_And_Distance;
