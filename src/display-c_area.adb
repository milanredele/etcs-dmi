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

with DMI_Ack;
with General_Parameters;
with Supplementary_Driving_Info;
with Symbol;

package body Display.C_Area is

   function C1_Absolute_Area return Area_T is
     ((The_Area.Position + The_C1_Area.Position,
       The_C1_Area.Width, The_C1_Area.Height));

   procedure Draw is
   begin
      C_Buffer.Fill (General_Parameters.Background_Color);

      Draw_C1;
      Draw_C7;
      Draw_C8;
   end Draw;

   procedure Draw_C1 is
      Position       : constant Position_T := The_C1_Area.Position + (13, 9);
      Position_MO_10 : constant Position_T := The_C1_Area.Position + (6, 2);
      Position_Level : constant Position_T := The_C1_Area.Position + (2, 14);

      procedure DS (The_Symbol : Symbol.T; The_Position : Position_T := Position) renames C_Buffer.Draw_Symbol;
      use Supplementary_Driving_Info;
      use all type DMI_Ack.Ack_Kind_T;

      Ack_In_C1 : constant Boolean :=
        DMI_Ack.Current_Valid
        and then DMI_Ack.Current_Kind in Level_Transition | Mode_Change;
   begin
      if Ack_In_C1 then
         -- DMI 5.4.1.5 / 5.1.1.3.2: flashing yellow frame with the object
         C_Buffer.Draw_Yellow_Frame (The_C1_Area, General_Parameters.Flash_On);

         case DMI_Ack.Current_Kind is
            when Mode_Change =>
               case DMI_Ack.Current_Mode is
                  when M_LS => DS (Symbol.MO_22);
                  when M_OS => DS (Symbol.MO_08);
                  when M_SR => DS (Symbol.MO_10, Position_MO_10);
                  when M_SH => DS (Symbol.MO_02);
                  when M_UN => DS (Symbol.MO_17);
                  when M_TR => DS (Symbol.MO_05);
                  when M_RV => DS (Symbol.MO_15);
                  when M_SN => DS (Symbol.MO_20);
               end case;
            when Level_Transition =>
               -- DMI 8.2.3.2.8 (v4.0.0: ack symbols only for L0 and NTC)
               case DMI_Ack.Current_Level is
                  when L0 =>  DS (Symbol.LE_07, Position_Level);
                  when NTC => DS (Symbol.LE_09, Position_Level);
                  when others =>
                     null;
               end case;
            when others =>
               null;
         end case;
      elsif Level_Announcement.Valid
        and then not Level_Announcement.Ack_Required
      then
         -- DMI 8.2.3.2.6/.7: plain announcement, no acknowledgement
         C_Buffer.Draw_Frame (The_C1_Area);
         case Level_Announcement.Level is
            when L0 =>  DS (Symbol.LE_06, Position_Level);
            when NTC => DS (Symbol.LE_08, Position_Level);
            when L1 =>  DS (Symbol.LE_10, Position_Level);
            when L2 =>  DS (Symbol.LE_12, Position_Level);
            when others =>
               null;
         end case;
      else
         C_Buffer.Draw_Frame (The_C1_Area);
      end if;
   end Draw_C1;
   
   procedure Draw_C7 is
      Position : constant Position_T := The_C7_Area.Position + (2, 9);
   begin
      -- DMI 8.2.3.1.5
      if Supplementary_Driving_Info.Override then
         C_Buffer.Draw_Symbol (Symbol.MO_03, Position);
      end if;
   end Draw_C7;
   
   procedure Draw_C8 is
      Position : constant Position_T := The_C8_Area.Position + (1, 2);
      procedure DS (The_Symbol : Symbol.T; The_Position : Position_T := Position) renames C_Buffer.Draw_Symbol;
      use Supplementary_Driving_Info;
   begin
      case Level is
         -- DMI 8.2.3.2.2
         when L0 =>  DS (Symbol.LE_01);
         when NTC => DS (Symbol.LE_02);
         when L1 =>  DS (Symbol.LE_03);
         when L2 =>  DS (Symbol.LE_04);
         when others =>
            -- DMI 8.2.3.2.3
            null;
      end case;
   end Draw_C8;

end Display.C_Area;
