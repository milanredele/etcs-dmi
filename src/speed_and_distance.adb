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
   begin
      Vcurrent := New_Speed;
   end Set_Speed;

   function Get_Speed return Speed_T is
      (Vcurrent);

   procedure Set_Speed_Params (New_Speed_Params : Speed_Params) is
   begin
      Speed := New_Speed_Params;
   end Set_Speed_Params;

   function Get_Speed_Params return Speed_Params is
     (Speed);

   procedure Set_Seed_Dial_Range (The_Range : Speed_Dial_Range_T) is
   begin
      Speed_Dial_Range := The_Range;
   end Set_Seed_Dial_Range;

   function Get_Speed_Dial_Range return Speed_Dial_Range_T is
     (Speed_Dial_Range);

   -- DMI 7.2.3.3 / 7.4.4.3 / 14.3.3.2: S2 sounds while the Warning
   -- Status is active, unless in Automatic Driving mode. Evaluated as a
   -- state, so that it also follows a mode change under an unchanged
   -- status (leaving AD in WaS starts it, entering AD stops it).
   procedure Update_S2 is
      Wanted : constant Boolean := Supervision_Status = WaS and not In_AD;
   begin
      if Wanted /= S2_Sounding then
         S2_Sounding := Wanted;
         DMI_Sounds.Play (if Wanted then DMI_Sounds.S2_Warning_Start
                          else DMI_Sounds.S2_Warning_Stop);
      end if;
   end Update_S2;

   function Normalised (The_Monitoring : Monitoring_T;
                        The_Status     : Supervision_Status_T)
                        return Supervision_Status_T is
     (case The_Monitoring is
         when CSM => (if The_Status = IndS then NoS else The_Status),
         when TSM => (if The_Status = NoS then IndS else The_Status),
         when RSM => (if The_Status = IntS then IntS else IndS));

   -- The train is above the Permitted supervision limit in these
   -- statuses (DMI 7.4.3.1, 7.4.4.1, 7.4.5.1)
   function Over_Permitted (The_Status : Supervision_Status_T) return Boolean is
     (The_Status in OvS | WaS | IntS);

   procedure Set_Supervision (The_Monitoring : Monitoring_T;
                              The_Status     : Supervision_Status_T;
                              The_MRDT       : MRDT_T)
   is
      Old_Monitoring : constant Monitoring_T := Monitoring_Mode;
      Old_Status     : constant Supervision_Status_T := Supervision_Status;
      Old_MRDT       : constant MRDT_T := MRDT;
   begin
      Monitoring_Mode := The_Monitoring;
      Supervision_Status := Normalised (The_Monitoring, The_Status);
      MRDT := The_MRDT;

      -- DMI 7.4.1.1 / 7.5.1.1: Sinfo when entering TSM or RSM from CSM,
      -- and on a change of MRDT (within TSM: entering TSM has its Sinfo
      -- already), unless in Limited Supervision or Automatic Driving mode
      if not In_LS and then not In_AD then
         if (Old_Monitoring = CSM and then The_Monitoring in TSM | RSM)
           or else (Old_Monitoring = TSM and then The_Monitoring = TSM
                    and then The_MRDT /= Old_MRDT)
         then
            DMI_Sounds.Play (DMI_Sounds.Sinfo);
         end if;
      end if;

      -- DMI 7.4.3.3 / 14.3.2.2: S1 once, as soon as the Over-speed Status
      -- is activated in TSM, unless in AD. "Activated" is read as: the
      -- train gets above the Permitted limit, whichever status reports it
      -- first (a jump from IndS straight to WaS or IntS has passed P as
      -- well); falling back from WaS or IntS to OvS activates nothing, and
      -- neither does entering TSM from CSM while already over speed.
      if The_Monitoring = TSM
        and then Over_Permitted (Supervision_Status)
        and then not Over_Permitted (Old_Status)
        and then not In_AD
      then
         DMI_Sounds.Play (DMI_Sounds.S1_Overspeed);
      end if;

      Update_S2;
   end Set_Supervision;

   procedure Mode_Changed is
   begin
      Update_S2;
   end Mode_Changed;

   procedure Reset is
   begin
      Monitoring_Mode := CSM;
      Supervision_Status := NoS;
      MRDT := 0;
      Update_S2; -- a sounding S2 stops
   end Reset;

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
