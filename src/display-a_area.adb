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
with Supplementary_Driving_Info;
with Symbol;
with User_Settings;

package body Display.A_Area is

   procedure Draw is
      use Speed_And_Distance;
      use type Supplementary_Driving_Info.Mode_T;

      -- "yes" rows shared by Tables 13 and 14: CSM only counts when target
      -- information is requested by National Value
      Target_Monitoring : constant Boolean :=
        (case Get_Monitoring_Mode is
            when CSM       => Get_CSM_Target_Info,
            when TSM | RSM => True);
   begin
      A_Buffer.Fill (General_Parameters.Background_Color);
      case Supplementary_Driving_Info.Mode is
         when Supplementary_Driving_Info.M_FS
            | Supplementary_Driving_Info.M_AD
            | Supplementary_Driving_Info.M_SM =>
            -- DMI 8.2.2.1.8 Table 13 / 8.2.2.2.7 Table 14
            if Target_Monitoring then
               Display.A_Area.A_2.Draw;
               Display.A_Area.A_3.Draw;
            end if;
         when Supplementary_Driving_Info.M_RV =>
            Display.A_Area.A_2.Draw;
            Display.A_Area.A_3.Draw;
         when Supplementary_Driving_Info.M_OS | Supplementary_Driving_Info.M_SR =>
            -- DMI 8.2.2.2.7 Table 14: digital only, and only when toggled on;
            -- RSM does not apply for SR
            if User_Settings.Speed_Info_Visible
              and then Target_Monitoring
              and then not (Get_Monitoring_Mode = RSM
                            and Supplementary_Driving_Info.Mode =
                                  Supplementary_Driving_Info.M_SR)
            then
               Display.A_Area.A_2.Draw;
            end if;
         when Supplementary_Driving_Info.M_LS =>
            -- DMI 8.2.1.7.3: display conditions are decided by the EVC
            if Get_LSSMA_Valid then
               Draw_A1;
            end if;
         when others =>
            null;
      end case;
   end Draw;
   
   procedure Draw_A1 is
      LSSMA_String : constant Wide_String := Speed_And_Distance.Speed_T'Wide_Image (Speed_And_Distance.Get_LSSMA);
   begin
      A_Buffer.Draw_Symbol (Symbol.LS_01, The_A1_Area.Position + (2, 2));
      A_Buffer.Draw_String (Pen_X         => The_A1_Area.Position.X + The_A1_Area.Width / 2,
                            Pen_Y         => The_A1_Area.Position.Y + 32,
                            The_String    => LSSMA_String (2 .. LSSMA_String'Last),
                            The_Size      => 12,
                            The_Color     => General_Parameters.GREY,
                            The_Alignment => A_Buffer.Center);
   end Draw_A1;

end Display.A_Area;
