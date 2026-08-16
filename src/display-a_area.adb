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
with DMI_Status;
with Speed_And_Distance;
with Supplementary_Driving_Info;
with Symbol;
with User_Settings;

package body Display.A_Area is

   procedure Draw_TTI is
      -- DMI 8.2.2.5.3/.4: dark grey 50x50 square with a growing white
      -- square, both centred in A1
      A1 : constant Area_T := Get_Sub_Area_With_Relative_Position (Display.A1);
      T  : constant Natural := Natural'Max (1, DMI_Status.T_Disp_TTI);
      N  : constant Natural :=
        Natural'Min (10, Natural'Max (1, 10 - (DMI_Status.TTI_Seconds * 10) / T));
      White_Size : constant Natural := N * 5;
   begin
      A_Buffer.Fill_Area ((A1.Position + (2, 2), 50, 50),
                          General_Parameters.DARK_GREY);
      A_Buffer.Fill_Area ((A1.Position + (2 + (50 - White_Size) / 2,
                                          2 + (50 - White_Size) / 2),
                           White_Size, White_Size),
                          General_Parameters.WHITE);
   end Draw_TTI;

   procedure Draw_A4 is
      A4 : constant Area_T := Get_Sub_Area_With_Relative_Position (Display.A4);
   begin
      -- DMI 8.2.3.7: adhesion factor 'slippery rail'
      if DMI_Status.Slippery_Rail then
         A_Buffer.Draw_Symbol (Symbol.ST_02, A4.Position + (1, 2));
      end if;
   end Draw_A4;

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

      -- DMI 8.2.2.5, Table 15a (mode/monitoring/toggle checked inside)
      if DMI_Status.TTI_Displayed then
         Draw_TTI;
      end if;

      Draw_A4;
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
