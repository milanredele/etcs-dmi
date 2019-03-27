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

package Supplementary_Driving_Info is

   type Mode_T is (M_NP, --No Power
                   M_SB, --Stand by
                   M_FS, --Full supervision
                   M_LS, --Limited supervision
                   M_OS, --On sight
                   M_SR, --Staff responsible
                   M_SH, --Shunting
                   M_UN, --Unfitted
                   M_RV, --Reversing
                   M_TR, --Trip
                   M_SN, --STM National
                   M_SE, --STM European
                   M_PT, --Post trip
                   M_NL, --Non leading
                   M_SF, --System failure
                   M_SL, --Sleep
                   M_IS);--Isolated
                   
   
   subtype Acknowledgment_Mode_T is Mode_T range M_LS .. M_SN; 
   
   type Optional_Acknowledgement_Mode_T (Valid : Boolean := False) is
      record
         case Valid is
            when True =>
               Mode : Acknowledgment_Mode_T;
            when False =>
               null;
         end case;
      end record;
   
   Mode                : Mode_T := M_SB;
   Acknowledgment_Mode : Optional_Acknowledgement_Mode_T;
   Override            : Boolean := False;
   
   type Level_T is (Unknown,
                    Invalid,
                    L0,
                    NTC,
                    L1,
                    L2,
                    L3);
   
   type Level_Announcement_T (Valid : Boolean := False) is
      record
         case Valid is
            when True =>
               Level        : Level_T;
               Ack_Required : Boolean;
            when False =>
               null;
         end case;
      end record;
   
   Level : Level_T := Unknown;
   Level_Announcement : Level_Announcement_T;

end Supplementary_Driving_Info;
