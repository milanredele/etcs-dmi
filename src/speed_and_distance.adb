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
with DMI_Sounds;
with Supplementary_Driving_Info;

package body Speed_And_Distance is

   use type Supplementary_Driving_Info.Mode_T;

   function In_AD return Boolean is
     (Supplementary_Driving_Info.Mode = Supplementary_Driving_Info.M_AD);

   function In_LS return Boolean is
     (Supplementary_Driving_Info.Mode = Supplementary_Driving_Info.M_LS);

   procedure Set_Speed (New_Speed : Speed_T) is
      Old_Status : constant Supervision_Status_T := Supervision_Status;
   begin
      case Monitoring_Mode is
         when CSM =>
            if New_Speed > Speed.Vsbi or Supervision_Status = IntS then
               -- DMI 7.2.4.1 (deactivation 7.2.4.2 only on brake release, see EVC)
               Supervision_Status := IntS;
            elsif New_Speed > Speed.Vwsl
              or (Supervision_Status = WaS and New_Speed > Speed.Vperm) then
               -- DMI 7.2.3.1 / 7.2.3.2 (hysteresis: deactivated at <= Vperm)
               Supervision_Status := WaS;
            elsif New_Speed > Speed.Vperm then
               -- DMI 7.2.2.1
               Supervision_Status := OvS;
            else
               -- DMI 7.2.1.1
               Supervision_Status := NoS;
            end if;
         when TSM =>
            -- v4.0.0: the base status in TSM is IndS (DMI 7.4.2.1);
            -- NoS does not exist under TSM.
            -- DMI 7.4.5.1.1: in AD mode IntS is not activated on SBI
            -- exceedance
            if (New_Speed > Speed.Vsbi and not In_AD)
              or Supervision_Status = IntS
            then
               -- DMI 7.4.5.1
               Supervision_Status := IntS;
            elsif New_Speed > Speed.Vwsl
              or (Supervision_Status = WaS and New_Speed > Speed.Vperm) then
               -- DMI 7.4.4.1 / 7.4.4.2
               Supervision_Status := WaS;
            elsif New_Speed > Speed.Vperm then
               -- DMI 7.4.3.1
               Supervision_Status := OvS;
            else
               -- DMI 7.4.2.1
               Supervision_Status := IndS;
            end if;
         when RSM =>
            if New_Speed > Speed.Vrelease or Supervision_Status = IntS then
               -- DMI 7.5.3.1
               Supervision_Status := IntS;
            else
               -- DMI 7.5.2.1
               Supervision_Status := IndS;
            end if;
      end case;

      Vcurrent := New_Speed;

      -- Audible information on status transitions (chapter 7)
      if Supervision_Status /= Old_Status then
         if Old_Status = WaS then
            DMI_Sounds.Play (DMI_Sounds.S2_Warning_Stop);
         end if;
         if not In_AD then
            case Supervision_Status is
               when WaS =>
                  -- DMI 7.2.3.3 / 7.4.4.3: S2 while the Warning Status
                  -- information is active
                  DMI_Sounds.Play (DMI_Sounds.S2_Warning_Start);
               when OvS =>
                  -- DMI 7.4.3.3: S1 as soon as the Over-speed Status is
                  -- activated, TSM only
                  if Monitoring_Mode = TSM then
                     DMI_Sounds.Play (DMI_Sounds.S1_Overspeed);
                  end if;
               when others =>
                  null;
            end case;
         end if;
      end if;
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
      Old_Mode : constant Monitoring_T := Monitoring_Mode;
   begin
      Monitoring_Mode := The_Mode;
      if The_Mode /= Old_Mode then
         -- DMI 7.4.1.1 / 7.5.1.1: Sinfo when entering TSM or RSM from
         -- CSM, unless in Limited Supervision or Automatic Driving mode
         if Old_Mode = CSM
           and then The_Mode in TSM | RSM
           and then not In_LS
           and then not In_AD
         then
            DMI_Sounds.Play (DMI_Sounds.Sinfo);
         end if;
         -- leaving the old monitoring invalidates a WaS-bound S2
         if Supervision_Status = WaS then
            DMI_Sounds.Play (DMI_Sounds.S2_Warning_Stop);
         end if;
      end if;
   end Set_Monitoring_Mode;

   function Get_Monitoring_Mode return Monitoring_T is
     (Monitoring_Mode);

   function Get_Supervision_Status return Supervision_Status_T is
     (Supervision_Status);

   procedure Set_CSM_Target_Info (Enabled : Boolean) is
   begin
      CSM_Target_Info := Enabled;
   end Set_CSM_Target_Info;

   function Get_CSM_Target_Info return Boolean is
     (CSM_Target_Info);

   function Get_Distance_To_Target return Distance_T is
     (Distance_To_Target);

   procedure Set_Distance_To_Target (The_Distance : Distance_T) is
   begin
      Distance_To_Target := The_Distance;
   end Set_Distance_To_Target;

   function Get_LSSMA return Speed_T is
     (LSSMA);

   function Get_LSSMA_Valid return Boolean is
     (LSSMA_Valid);

   procedure Set_LSSMA (The_LSSMA : Speed_T; Valid : Boolean := True) is
   begin
      LSSMA := The_LSSMA;
      LSSMA_Valid := Valid;
   end Set_LSSMA;

end Speed_And_Distance;
