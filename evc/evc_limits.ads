--  ETCS on-board (EVC)
--  The supervision limits of SUBSET-026 3.13.9: the ceiling limits
--  (3.13.9.2), the braking to target limits EBI, SBI1 / SBI2, W, P and I
--  of a target for a given speed (3.13.9.3) with the speeds displayed
--  for them, the release speed (3.13.9.4) and the perturbation location
--  (3.13.11). Functions only: EVC_SDM calls them for every target in
--  every cycle and keeps the state.
--
--  Locations are in ahead coordinates (EVC_Profile), speeds cm/s, times
--  ms. Rounding keeps every limit on the safe side: a location of a
--  limit is rounded rearwards (the time margins are rounded up, the
--  speeds V_bec, D_bec and the compensations up), a speed of a limit
--  down. The limits of one target are ordered by construction: each is
--  the previous one moved rearwards by a margin that is never negative,
--  hence I <= P <= W <= SBI <= EBI at every speed (Ordered).
--
--  Curve evaluations per target and cycle: an EBD based target 1
--  location (EBI at V_est) and 2 speeds (the displayed P and SBI2), 1
--  location more for the P at the target speed of an MRSP or LOA target
--  (3.13.9.3.5.9), 1 more with a service brake feedback (the
--  Indication limit of 3.13.9.3.6.5), and with the guidance curve 1
--  location and 1 speed of the GUI; the EOA 1 location and 2 speeds of
--  the SBD. The release speed calculated on-board (3.13.9.4.8) is a
--  bisection of Release_Iterations steps of 1 speed each per target
--  concerned; the RSM start location 1 location per target concerned.

with EVC_Braking;   use EVC_Braking;
with EVC_Curves;    use EVC_Curves;
with EVC_Distances; use EVC_Distances;
with EVC_Fixed;     use EVC_Fixed;
with EVC_Profile;   use EVC_Profile;

package EVC_Limits
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------
   --  Fixed values (A.3.1) and SUBSET-041
   ---------------------------------------------------------------------

   T_Warning : constant := 2_000;   -- ms, T_warning
   T_Driver  : constant := 4_000;   -- ms, T_driver
   T_Disp_TTI : constant := 14_000; -- ms, T_dispTTI
   --  A.3.10.4: T_bs2_locked
   T_Bs2_Locked : constant := 2_000;
   --  SUBSET-041 5.2.1.13: T41
   T_41 : constant := 1_000;

   type Margin_Kind_T is (Warning, SBI, EBI);

   --  3.13.9.2.3, .5, .6: dV_warning, dV_sbi, dV_ebi at the speed V,
   --  cm/s rounded down; dV_warning <= dV_sbi <= dV_ebi
   function Margin (Kind : Margin_Kind_T; V : Speed_T) return Speed_T
     with Post => Margin'Result <= 420;

   --  SUBSET-041 5.3.1.2: the accuracy of the speed, cm/s rounded up
   function F41 (V : Speed_T) return Speed_T
     with Post => F41'Result in 56 .. 1_400;

   ---------------------------------------------------------------------
   --  Braking to target limits
   ---------------------------------------------------------------------

   --  What the limits of 3.13.9.3 depend on besides the curves
   type Terms_T is record
      V       : Speed_T := 0;   -- the speed the limits are for (V_est)
      V_Delta0 : Speed_T := 0;  -- 3.13.9.3.2.1
      A_Est1  : Decel_T := 0;   -- 3.13.9.3.2.8, >= 0
      A_Est2  : Decel_T := 0;   -- 3.13.9.3.2.9, 0 .. 400
      T_Be    : Time_T := 0;    -- T_be_reduced (or T_be where so said)
      T_Bs1   : Time_T := 0;    -- 3.13.9.3.3.3 to .5
      T_Bs2   : Time_T := 0;
      T_Ind   : Time_T := 0;    -- 3.13.9.3.6.2, .4
      TCO     : Boolean := True;  -- 3.13.9.3.2.3: cut-off implemented
      T_Traction_Cut_Off : Time_T := 0;
   end record;

   --  3.13.9.3.2.3: T_traction for a given T_bs2
   function T_Traction (Terms : Terms_T; T_Bs2 : Time_T) return Time_T is
     (if Terms.TCO
      then Max (Terms.T_Traction_Cut_Off - (T_Warning + T_Bs2), 0)
      else Terms.T_Traction_Cut_Off);

   --  The locations of the limits of an EBD based target (EBD, EBI, SBI2,
   --  W, P, I) or of the EOA (SBD, -, SBI1, W, P, I), and the speeds
   --  displayed for them (3.13.9.3.3.7, .8, 3.13.9.3.5.5 to .8)
   type Limits_T is record
      Curve : Num := 0;   -- d_EBD (V_bec) or d_SBD (V_est)
      EBI   : Num := 0;
      SBI   : Num := 0;
      W     : Num := 0;
      P     : Num := 0;
      I     : Num := 0;
      V_P   : Speed_T := 0;
      V_SBI : Speed_T := 0;
   end record;

   function Ordered (L : Limits_T) return Boolean is
     (L.I <= L.P and then L.P <= L.W and then L.W <= L.SBI
      and then L.SBI <= L.EBI and then L.EBI <= L.Curve);

   subtype Location_T is Num range -4 * Max_Cm .. 4 * Max_Cm;

   --  3.13.9.3.2 to 3.13.9.3.6 for an EBD based target: the EBD, its
   --  target speed and location (the D_target of 3.13.9.3.5.1), the GUI
   --  when enabled, the speed terms, the location of the max safe front
   --  end (for the displayed speeds) and Stop (a location of a limit
   --  behind Stop may be given as behind Stop only)
   function EBD_Limits (M        : Model_T;
                        P        : Profile_T;
                        EBD      : Curve_T;
                        V_Target : Speed_T;
                        D_Target : Dist_T;
                        With_GUI : Boolean;
                        GUI      : Curve_T;
                        Terms    : Terms_T;
                        X_Max    : Dist_T;
                        Stop     : Dist_T) return Limits_T
     with Pre  => EBD.Floor_W <= EBD.Anchor_W
                  and then GUI.Floor_W <= GUI.Anchor_W
                  and then Stop > -Max_Cm,
          Post => Ordered (EBD_Limits'Result)
                  and then EBD_Limits'Result.Curve in Location_T
                  and then EBD_Limits'Result.I in Location_T;

   --  3.13.9.3.3.1, .4.1, .5.1, .5.4, .6.1 for the EOA: the SBD, the GUI
   --  when enabled, the terms and the estimated front end
   function EOA_Limits (M        : Model_T;
                        P        : Profile_T;
                        SBD      : Curve_T;
                        With_GUI : Boolean;
                        GUI      : Curve_T;
                        Terms    : Terms_T;
                        X_Est    : Dist_T;
                        Stop     : Dist_T) return Limits_T
     with Pre  => SBD.Floor_W <= SBD.Anchor_W
                  and then GUI.Floor_W <= GUI.Anchor_W
                  and then Stop > -Max_Cm,
          Post => Ordered (EOA_Limits'Result)
                  and then EOA_Limits'Result.Curve in Location_T
                  and then EOA_Limits'Result.I in Location_T;

   --  3.13.9.3.5.9, .10: the location of the Permitted speed limit for
   --  the target speed of an MRSP or LOA target, with T_be_react /
   --  T_traction_max / T_bs_foot as there
   function P_At_Target (M          : Model_T;
                         P          : Profile_T;
                         EBD        : Curve_T;
                         V_Target   : Speed_T;
                         D_Target   : Dist_T;
                         V_Delta0t  : Speed_T;
                         T_Be_React : Time_T;
                         T_Traction_Max : Time_T;
                         T_Bs_Foot  : Time_T;
                         Stop       : Dist_T) return Num
     with Pre  => EBD.Floor_W <= EBD.Anchor_W and then Stop > -Max_Cm,
          Post => P_At_Target'Result in Location_T;

end EVC_Limits;
