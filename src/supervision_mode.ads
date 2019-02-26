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
