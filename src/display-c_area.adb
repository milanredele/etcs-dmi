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
with DMI_Status;
with General_Parameters;
with Supplementary_Driving_Info;
with Symbol;

package body Display.C_Area is

   function C1_Absolute_Area return Area_T is
     ((The_Area.Position + The_C1_Area.Position,
       The_C1_Area.Width, The_C1_Area.Height));

   function Tunnel_Toggle_Area return Area_T is
     ((The_Area.Position + The_C2_C4_Area.Position,
       The_C2_C4_Area.Width, The_C2_C4_Area.Height));

   function Brake_Ack_Area return Area_T is
     -- C8 (top), C9 and E1 (below C9, in area E) form one 54 wide column
     ((The_Area.Position + The_C8_Area.Position,
       The_C8_Area.Width,
       The_C8_Area.Height + The_C9_Area.Height + 25));

   procedure Draw is
   begin
      C_Buffer.Fill (General_Parameters.Background_Color);

      Draw_C1;
      Draw_C2_C4;
      Draw_C6;
      Draw_C7;
      Draw_C8;
      Draw_C9;
   end Draw;

   procedure Draw_C2_C4 is
      use DMI_Status;
      Symbol_Position : constant Position_T := The_C2_Area.Position + (2, 9);
   begin
      -- DMI 8.2.3.6: tunnel stopping area
      if Tunnel = Unknown then
         return;
      end if;
      if not Tunnel_Toggled_On then
         -- 8.2.3.6.5: DR05 when toggled off
         C_Buffer.Draw_Symbol
           (Symbol.DR_05,
            The_C2_C4_Area.Position
              + ((The_C2_C4_Area.Width - Symbol.DR_05.Width) / 2,
                 (The_C2_C4_Area.Height - Symbol.DR_05.Height) / 2));
      else
         -- 8.2.3.6.7: TC36 active / TC37 announced, in C2
         case Tunnel is
            when Active =>
               C_Buffer.Draw_Symbol (Symbol.TC_36, Symbol_Position);
            when Announced =>
               C_Buffer.Draw_Symbol (Symbol.TC_37, Symbol_Position);
               -- 8.2.3.6.8/.9: remaining distance in C3/C4, grey, right
               -- aligned with a 10 cell indent, vertically centred
               declare
                  Image : constant Wide_String :=
                    Natural'Wide_Image (Natural'Min (Tunnel_Distance, 99999));
               begin
                  C_Buffer.Draw_String
                    (Pen_X => The_C2_C4_Area.Position.X
                              + The_C2_C4_Area.Width - 10,
                     Pen_Y => The_C2_C4_Area.Position.Y + 31,
                     The_String => Image (2 .. Image'Last),
                     The_Size => 12,
                     The_Color => General_Parameters.GREY,
                     The_Alignment => C_Buffer.Right);
               end;
            when Unknown =>
               null;
         end case;
      end if;
   end Draw_C2_C4;

   procedure Draw_C6 is
      Position : constant Position_T := The_C6_Area.Position + (2, 9);
   begin
      -- DMI 8.4.2 reversing permitted (ST06) and 8.2.3.11 BMM reaction
      -- inhibition (ST07) share C6; reversing takes precedence
      if DMI_Status.Reversing_Permitted then
         C_Buffer.Draw_Symbol (Symbol.ST_06, Position);
      elsif DMI_Status.BMM_Inhibited then
         -- ST07 has no bitmap in the SRS symbol package: draw a stand-in
         -- 32x32 framed "BMM" glyph in grey
         declare
            Box : constant Area_T := (Position, 32, 32);
         begin
            C_Buffer.Draw_Input_Field_Frame (Box);
            C_Buffer.Draw_String
              (Pen_X => Position.X + 16,
               Pen_Y => Position.Y + 21,
               The_String => "BMM",
               The_Size => 10,
               The_Color => General_Parameters.GREY,
               The_Alignment => C_Buffer.Center);
         end;
      end if;
   end Draw_C6;

   procedure Draw_C9 is
      use type DMI_Status.Brake_T;
      use all type DMI_Ack.Ack_Kind_T;
   begin
      -- DMI 8.2.2.3: ST01 while ETCS commands the brakes
      if DMI_Status.Brake /= DMI_Status.None then
         C_Buffer.Draw_Symbol (Symbol.ST_01, The_C9_Area.Position + (1, 2));
         -- 5.4.1.5: flashing frame on C9 only (8.2.2.3.5) while the
         -- brake release acknowledgement is offered
         if DMI_Ack.Current_Valid
           and then DMI_Ack.Current_Kind = Brake_Release
         then
            C_Buffer.Draw_Yellow_Frame (The_C9_Area, General_Parameters.Flash_On);
         end if;
      end if;
   end Draw_C9;

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
