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
with Supervision_Mode;
with Symbol;

package body Display.B_Area is

   procedure Fill_Background is
   begin
      B_Buffer.Fill (General_Parameters.Background_Color);
   end Fill_Background;

   ----------
   -- Draw --
   ----------

   procedure Draw is
   begin
      Fill_Background;

      Draw_B7;
      Speed_Dial.Draw;
   end Draw;

   procedure Draw_B7 is
      Position : constant Position_T := Get_Sub_Area_With_Relative_Position (B7).Position + (1, 2);
      procedure DS (The_Symbol : Symbol.T; The_Position : Position_T := Position) renames B_Buffer.Draw_Symbol;
      use Supervision_Mode;
   begin
      case Mode is
         when M_SB => DS (Symbol.MO_13);
         when M_FS => DS (Symbol.MO_11);
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
