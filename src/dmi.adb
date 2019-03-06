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

with Display.B_Area;
with Speed_And_Distance;
with Supervision_Mode;
with User_Settings;

procedure Dmi is

begin
   Supervision_Mode.Mode := Supervision_Mode.M_OS;
   User_Settings.Toggle (User_Settings.Basic_Speed_Hook) := True;
   Speed_And_Distance.Set_Monitoring_Mode (Speed_And_Distance.TSM);
   Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_400);
   Speed_And_Distance.Set_Speed_Params ((Vperm => 120,
                                         Vtarget => 80,
                                         Vwsl => 130,
                                         Visl => 140,
                                         Vsbi => 150,
                                         Vrelease => 40,
                                         Vrelease_Exists => True));
   Speed_And_Distance.Set_Speed (249);
   Display.B_Area.Draw;
   Display.B_Area.B_Buffer.Dump ("b_frame.dmp");
end Dmi;
