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

with Display.A_Area.A_2;
with Display.A_Area.A_3;
with Speed_And_Distance;
with Supervision_Mode;
with User_Settings;

package body Display.A_Area is

   procedure Draw is
      use type Speed_And_Distance.Monitoring_T;
   begin
      A_Buffer.Fill (General_Parameters.Background_Color);
      case Supervision_Mode.Mode is
         -- DMI 8.2.2.1.8
         when Supervision_Mode.M_FS =>
            if Speed_And_Distance.Get_Monitoring_Mode /= Speed_And_Distance.CSM then
               Display.A_Area.A_2.Draw;
               Display.A_Area.A_3.Draw;
            end if;
         when Supervision_Mode.M_RV =>
            Display.A_Area.A_2.Draw;
            Display.A_Area.A_3.Draw;
         when Supervision_Mode.M_OS | Supervision_Mode.M_SR =>
            -- DMI 8.2.2.2.7
            if User_Settings.Toggle (User_Settings.Distance_To_Target_Digital) then
               Display.A_Area.A_2.Draw;
            end if;
         when others =>
            null;
      end case;
   end Draw;

end Display.A_Area;
