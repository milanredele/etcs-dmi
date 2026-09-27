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

with Display.Draw;
with DMI_Ack;
with DMI_Flash;
with Font;
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

   ---------------------------------------------------------------------
   -- DMI 8.2.3.2.9 / 8.2.3.2.10: the abbreviation of the National System
   -- instead of the text "NTC" of LE02, LE08 and LE09 (audit SDI-8)
   ---------------------------------------------------------------------

   function National_Name return Wide_String is
     (Supplementary_Driving_Info.National_Name.Text
        (1 .. Supplementary_Driving_Info.National_Name.Length));

   function Has_National_Name return Boolean is
     (Supplementary_Driving_Info.National_Name.Length > 0);

   -- 8.2.3.2.10: the characters comply with the minimum size of 5.1.2,
   -- whose smallest character height is 10 cells (5.1.2.2.3 e, f, g);
   -- 12 cells, the size of "other characters" (h), is used when the
   -- name fits with it (implementation choice)
   function Name_Size (Text : Wide_String; Width : Natural) return Font.Size_T
   is (if Display.Draw.String_Width (Text, 12) <= Width then 12 else 10);

   -- One line of the name, centred in Box on the baseline Pen_Y; a name
   -- too wide even at 10 cells is cut at the edges of Box (left aligned)
   procedure Name_Line (Text  : Wide_String;
                        Box   : Area_T;
                        Pen_Y : Natural;
                        Size  : Font.Size_T;
                        Color : General_Parameters.Color) is
   begin
      if Display.Draw.String_Width (Text, Size) <= Box.Width then
         C_Buffer.Draw_String
           (Pen_X => Box.Position.X + Box.Width / 2,
            Pen_Y => Pen_Y,
            The_String => Text,
            The_Size => Size,
            The_Color => Color,
            The_Alignment => C_Buffer.Center);
      else
         C_Buffer.Draw_String_Clipped
           (Pen_X => Box.Position.X,
            Pen_Y => Pen_Y,
            The_String => Text,
            The_Size => Size,
            The_Color => Color,
            The_Clip => Box);
      end if;
   end Name_Line;

   -- LE02 with the name: 8.2.3.2.10, the name stays within 48 x 19
   -- cells, centred in C8 like the symbol; one line (two lines of 10
   -- cells do not fit in 19)
   procedure Draw_Level_Name is
      Box : constant Area_T :=
        (The_C8_Area.Position
           + ((The_C8_Area.Width - 48) / 2, (The_C8_Area.Height - 19) / 2),
         48, 19);
      Size : constant Font.Size_T := Name_Size (National_Name, Box.Width);
   begin
      Name_Line (National_Name, Box,
                 Box.Position.Y + (Box.Height + Natural (Size)) / 2,
                 Size, General_Parameters.GREY);
   end Draw_Level_Name;

   -- LE08 / LE09 with the name: the arrow of the symbol (its columns
   -- left of the text "NTC", 0 .. Arrow_Width - 1) and the name to its
   -- right, grey (LE08) or yellow (LE09) as the symbol's text. A name
   -- that does not fit on one line is broken after its last '/', '-' or
   -- '+' (or at its last space) that leaves both lines inside, as LE08a
   -- / LE09a show "PZB/" over "LZB"; implementation choice for what the
   -- symbol does not fix.
   Arrow_Width : constant := 21;

   procedure Draw_Announced_Name (The_Symbol : Symbol.T;
                                  Position   : Position_T;
                                  Color      : General_Parameters.Color) is
      -- right of the arrow, 2 cells from it and 3 from the right border
      -- of C1 (its flashing frame is 2 cells wide, 5.1.1.3, and one
      -- cell stays clear of it), 4 from the top and the bottom. The
      -- width of a text is its ink (Display.Draw.String_Width), so the
      -- '/' of "PZB/" keeps its last cell inside the box.
      Box : constant Area_T :=
        ((Position.X + Arrow_Width + 2, The_C1_Area.Position.Y + 4),
         The_C1_Area.Position.X + The_C1_Area.Width - 3
           - (Position.X + Arrow_Width + 2),
         The_C1_Area.Height - 8);
      -- the centre line of the arrow
      Middle : constant Natural := Position.Y + The_Symbol.Height / 2;
      Name   : constant Wide_String := National_Name;
      Cut    : Natural := 0;
      Size   : Font.Size_T := 12;

      function Fits (S : Font.Size_T; From, To : Natural) return Boolean is
        (Display.Draw.String_Width (Name (From .. To), S) <= Box.Width);
   begin
      C_Buffer.Draw_Symbol (The_Symbol, Position);
      C_Buffer.Fill_Area
        ((Position + (Arrow_Width, 0), The_Symbol.Width - Arrow_Width,
          The_Symbol.Height),
         General_Parameters.Background_Color);

      if Fits (12, Name'First, Name'Last)
        or else Fits (10, Name'First, Name'Last)
      then
         Size := Name_Size (Name, Box.Width);
         Name_Line (Name, Box, Middle + Natural (Size) / 2, Size, Color);
         return;
      end if;

      for S in reverse Font.Size_T range 10 .. 12 loop
         if S in 10 | 12 and then Cut = 0 then
            for I in reverse Name'First .. Name'Last - 1 loop
               if Name (I) in '/' | '-' | '+' | ' '
                 and then Fits (S, Name'First,
                                (if Name (I) = ' ' then I - 1 else I))
                 and then Fits (S, I + 1, Name'Last)
               then
                  Cut := I;
                  Size := S;
                  exit;
               end if;
            end loop;
         end if;
      end loop;

      if Cut = 0 then
         Name_Line (Name, Box, Middle + 5, 10, Color);
         return;
      end if;
      declare
         Total : constant Natural := 2 * Natural (Size) + 4;
         First_Baseline : constant Natural :=
           Middle - Total / 2 + Natural (Size);
      begin
         Name_Line (Name (Name'First
                            .. (if Name (Cut) = ' ' then Cut - 1 else Cut)),
                    Box, First_Baseline, Size, Color);
         Name_Line (Name (Cut + 1 .. Name'Last), Box,
                    First_Baseline + Natural (Size) + 4, Size, Color);
      end;
   end Draw_Announced_Name;

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
      -- DMI 8.4.2.2 (reversing permitted, ST06) and 8.2.3.11.1/.2 (Big
      -- Metal Mass reaction inhibition, ST07) both name area C6. Both
      -- symbols are 32 x 32 cells (chapter 13, Table 61) and C6 is
      -- 37 x 50, so only one fits. The SRS gives no precedence rule; by
      -- choice ST06 is shown while both apply: it exists only at
      -- standstill inside a reversing area, whereas the inhibition was
      -- selected by the driver (Special window, 11.2.3.4 and 11.7.6) and
      -- its symbol returns as soon as ST06 is removed.
      if DMI_Status.Reversing_Permitted then
         C_Buffer.Draw_Symbol (Symbol.ST_06, Position);
      elsif DMI_Status.BMM_Inhibited then
         C_Buffer.Draw_Symbol (Symbol.ST_07, Position);
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
            C_Buffer.Draw_Yellow_Frame (The_C9_Area, DMI_Flash.Frame_Visible);
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
         C_Buffer.Draw_Yellow_Frame (The_C1_Area, DMI_Flash.Frame_Visible);

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
                  when NTC =>
                     -- 8.2.3.2.9: the National System's abbreviation
                     if Has_National_Name then
                        Draw_Announced_Name (Symbol.LE_09, Position_Level,
                                             General_Parameters.YELLOW);
                     else
                        DS (Symbol.LE_09, Position_Level);
                     end if;
                  when others =>
                     null;
               end case;
            when others =>
               null;
         end case;
      elsif Level_Announcement.Valid then
         -- DMI 8.2.3.2.7: announcement without acknowledgement.
         -- DMI 8.2.3.2.8: LE06, LE08 also replace LE07, LE09 as soon as
         -- the driver has acknowledged. The DMI does this itself: the
         -- request has left the acknowledgement service (DMI_Core,
         -- BTN_Ack) while the EVC still announces the level "with
         -- acknowledgement", which does not enter a second request.
         -- By choice the same holds while the request of the level
         -- announcement waits behind another acknowledgement or for the
         -- 1 s of 5.4.1.9 (5.4.1.7: one request at a time; the SRS does
         -- not say what C1 shows meanwhile): the announcement itself is
         -- valid, only its flashing frame and LE07, LE09 have to wait.
         -- 8.2.3.2.6 is met by the branch above: a mode acknowledgement
         -- displayed in C1 hides the level announcement.
         C_Buffer.Draw_Frame (The_C1_Area);
         case Level_Announcement.Level is
            when L0 =>  DS (Symbol.LE_06, Position_Level);
            when NTC =>
               -- 8.2.3.2.9: the National System's abbreviation
               if Has_National_Name then
                  Draw_Announced_Name (Symbol.LE_08, Position_Level,
                                       General_Parameters.GREY);
               else
                  DS (Symbol.LE_08, Position_Level);
               end if;
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
         when NTC =>
            -- "NTC (except in the modes SN and NL)": in these modes C8
            -- stays empty in level NTC
            if Mode not in M_SN | M_NL then
               -- 8.2.3.2.9: the National System's abbreviation instead
               -- of the text "NTC", when the EVC names it
               if Has_National_Name then
                  Draw_Level_Name;
               else
                  DS (Symbol.LE_02);
               end if;
            end if;
         when L1 =>  DS (Symbol.LE_03);
         when L2 =>  DS (Symbol.LE_04);
         when others =>
            -- DMI 8.2.3.2.3
            null;
      end case;
   end Draw_C8;

end Display.C_Area;
