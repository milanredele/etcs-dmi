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

   -- DMI 7.2 / 7.4 / 7.5 (v4.0.0: PIM deleted, SRS 7.3 "intentionally deleted")
   type Monitoring_T is (CSM, -- Ceiling Speed Monitoring
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
         Vperm, Vtarget, Vwsl, Vsbi, Vrelease : Speed_T := 0;
         Vrelease_Exists : Boolean := False;
      end record;

   -- Set the current speed
   procedure Set_Speed (New_Speed : Speed_T);
   
   function Get_Speed return Speed_T;
   
   procedure Set_Speed_Params (New_Speed_Params : Speed_Params);
   
   function Get_Speed_Params return Speed_Params;
   
   procedure Set_Seed_Dial_Range (The_Range : Speed_Dial_Range_T);
   
   function Get_Speed_Dial_Range return Speed_Dial_Range_T;
   
   -- The monitoring and the supervision status come from the EVC
   -- (MSG_SPEED_STATE): they are results of the speed and distance
   -- monitoring function of the on-board (DMI 7.1.1.1, SUBSET-026
   -- 3.13.10), which knows positions, brake commands and their revocation;
   -- the DMI only presents them and plays the sounds of chapter 7.
   --
   -- A status that does not exist under the monitoring is replaced by the
   -- nearest one that does (implementation choice, the pair comes from
   -- the wire): CSM has no IndS (-> NoS), TSM has no NoS (-> IndS), RSM
   -- has IndS and IntS only (NoS, OvS, WaS -> IndS). SUBSET-026
   -- 3.13.10.3.6, 3.13.10.4.17 and 3.13.10.5.7 demand the same of the
   -- on-board when the monitoring changes.
   --
   -- MRDT identifies the most relevant displayed target; the value has no
   -- meaning to the DMI, a change of it within TSM is "a change of MRDT"
   -- (DMI 7.4.1.1).
   type MRDT_T is mod 256;

   procedure Set_Supervision (The_Monitoring : Monitoring_T;
                              The_Status     : Supervision_Status_T;
                              The_MRDT       : MRDT_T);

   -- To be called when the ETCS mode has changed: whether S2 sounds
   -- depends on the mode (DMI 7.2.3.3, 7.4.4.3)
   procedure Mode_Changed;

   -- Back to CSM / NoS; a sounding S2 stops
   procedure Reset;

   function Get_Monitoring_Mode return Monitoring_T;

   function Get_Supervision_Status return Supervision_Status_T;

   -- Table 8/9 "CSM (with target information)": requested by National Value
   procedure Set_CSM_Target_Info (Enabled : Boolean);

   function Get_CSM_Target_Info return Boolean;

   -- DMI 8.2.2.2.4 / 8.2.2.2.6: up to 5 digits, to the nearest 10 m
   type Distance_T is new Natural range 0 .. 99_990;
   
   function Get_Distance_To_Target return Distance_T;
   
   procedure Set_Distance_To_Target (The_Distance : Distance_T);
   
   function Get_LSSMA return Speed_T;

   function Get_LSSMA_Valid return Boolean;

   procedure Set_LSSMA (The_LSSMA : Speed_T; Valid : Boolean := True);

private
   -- a defined, consistent pair even before DMI_Core.Initialise
   Monitoring_Mode    : Monitoring_T := CSM;
   Supervision_Status : Supervision_Status_T := NoS;
   CSM_Target_Info    : Boolean := False;
   MRDT               : MRDT_T := 0;
   S2_Sounding        : Boolean := False;
   Speed              : Speed_Params;
   Vcurrent           : Speed_T := 0;
   Speed_Dial_Range   : Speed_Dial_Range_T := Range_180;
   Distance_To_Target : Distance_T := 0;
   LSSMA              : Speed_T := 0;
   LSSMA_Valid        : Boolean := False;
end Speed_And_Distance;
