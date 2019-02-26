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

package Supervision_Mode is

   type Mode_T is (M_NP, --No Power
                   M_SB, --Stand by
                   M_FS, --Full supervision
                   M_LS, --Limited supervision
                   M_OS, --On sight
                   M_SR, --Staff responsible
                   M_SH, --Shunting
                   M_UN, --Unfitted
                   M_TR, --Trip
                   M_PT, --Post trip
                   M_SL, --Sleep
                   M_NL, --Non leading
                   M_RV, --Reversing
                   M_SF, --System failure
                   M_IS, --Isolated
                   M_SN, --STM National
                   M_SE); --STM European
   
   Mode : Mode_T := M_SB;

end Supervision_Mode;
