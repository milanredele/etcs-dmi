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
with Display.B_Area.Speed_Dial;
with DMI_Status;
with Supplementary_Driving_Info;
with Symbol;

package body Display.B_Area is

   procedure Fill_Background is
   begin
      B_Buffer.Fill (General_Parameters.Background_Color);
   end Fill_Background;

   procedure Draw_B345 is
      -- DMI 8.2.3.5 / 8.2.3.8: track conditions and level crossing fill
      -- B3/B4/B5 left to right; further objects wait for a free slot
      use DMI_Status;

      function Kind_Symbol (Kind : Natural) return Symbol.T is
        (case Kind is
            when 1  => Symbol.TC_01, when 2  => Symbol.TC_02,
            when 3  => Symbol.TC_03, when 4  => Symbol.TC_04,
            when 5  => Symbol.TC_05, when 6  => Symbol.TC_06,
            when 7  => Symbol.TC_07, when 8  => Symbol.TC_08,
            when 9  => Symbol.TC_09, when 10 => Symbol.TC_10,
            when 11 => Symbol.TC_11, when 12 => Symbol.TC_12,
            when 13 => Symbol.TC_13, when 14 => Symbol.TC_14,
            when 15 => Symbol.TC_15, when 16 => Symbol.TC_16,
            when 17 => Symbol.TC_17, when 18 => Symbol.TC_18,
            when 19 => Symbol.TC_19, when 20 => Symbol.TC_20,
            when 21 => Symbol.TC_21, when 22 => Symbol.TC_22,
            when 23 => Symbol.TC_23, when 24 => Symbol.TC_24,
            when 25 => Symbol.TC_25, when 26 => Symbol.TC_26,
            when 27 => Symbol.TC_27, when 28 => Symbol.TC_28,
            when 29 => Symbol.TC_29, when 30 => Symbol.TC_30,
            when 31 => Symbol.TC_31, when 32 => Symbol.TC_32,
            when 33 => Symbol.TC_33, when 34 => Symbol.TC_34,
            when 35 => Symbol.TC_35, when 36 => Symbol.TC_36,
            when 37 => Symbol.TC_37, when others => Symbol.LX_01);

      Slots : constant array (1 .. 3) of Sub_ID_T := (B3, B4, B5);
   begin
      for I in 1 .. Natural'Min (TC_Count, 3) loop
         declare
            Slot : constant Area_T :=
              Get_Sub_Area_With_Relative_Position (Slots (I));
            Sym  : constant Symbol.T := Kind_Symbol (TC_List (I).Kind);
         begin
            B_Buffer.Draw_Symbol
              (Sym,
               Slot.Position + ((Slot.Width - Sym.Width) / 2,
                                (Slot.Height - Sym.Height) / 2));
         end;
      end loop;
   end Draw_B345;

   procedure Draw_B8 is
      -- DMI 8.2.3.10: Supervised Manoeuvre authorised direction
      use all type DMI_Status.SM_Direction_T;
      use type Supplementary_Driving_Info.Mode_T;
      B8_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (B8);

      procedure DS (Sym : Symbol.T) is
      begin
         B_Buffer.Draw_Symbol
           (Sym, B8_Area.Position + ((B8_Area.Width - Sym.Width) / 2,
                                     (B8_Area.Height - Sym.Height) / 2));
      end DS;
   begin
      if Supplementary_Driving_Info.Mode = Supplementary_Driving_Info.M_SM then
         case DMI_Status.SM_Direction is
            when Forward  => DS (Symbol.SM_01);
            when Backward => DS (Symbol.SM_02);
            when None     => null;
         end case;
      end if;
   end Draw_B8;

   ----------
   -- Draw --
   ----------

   procedure Draw is
   begin
      Fill_Background;

      Draw_B7;
      Speed_Dial.Draw;
      Draw_B345;
      Draw_B8;
   end Draw;

   procedure Draw_B7 is
      Position : constant Position_T := Get_Sub_Area_With_Relative_Position (B7).Position + (1, 2);
      procedure DS (The_Symbol : Symbol.T; The_Position : Position_T := Position) renames B_Buffer.Draw_Symbol;
      use Supplementary_Driving_Info;
   begin
      case Mode is
         when M_SB => DS (Symbol.MO_13);
         when M_FS => DS (Symbol.MO_11);
         when M_AD => DS (Symbol.MO_23);
         when M_SM => DS (Symbol.MO_24);
         when M_LS => DS (Symbol.MO_21);
         when M_OS => DS (Symbol.MO_07);
         when M_SR => DS (Symbol.MO_09);
         when M_SH => DS (Symbol.MO_01);
         when M_UN => DS (Symbol.MO_16);
         when M_TR => DS (Symbol.MO_04);
         when M_PT => DS (Symbol.MO_06);
         when M_NL => DS (Symbol.MO_12);
         when M_RV => DS (Symbol.MO_14);
         when M_SF => DS (Symbol.MO_18);
         when M_SN => DS (Symbol.MO_19);
         when others =>
            null;
      end case;
   end Draw_B7;


end Display.B_Area;
