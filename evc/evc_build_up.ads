--  ETCS on-board (EVC)
--  The reduced values of the safe and of the expected brake build up
--  times, SUBSET-026 A.3.12 (3.13.6.2.2.4, 3.13.6.3.2.5).
--
--  For every target the ramp model of the brake force (Figure 31) may
--  show that the target speed is reached before the equivalent build up
--  time of the step model has elapsed; A.3.12 derives from it the times
--  T_be_reduced and T_bs_reduced the limits of 3.13.9.3 use, between the
--  brake reaction time and the equivalent build up time
--  (A.3.12.8.1). Functions only: EVC_SDM calls them per target with the
--  extreme decelerations EVC_Curves.Extremes gives.
--
--  Fixed point. Times in ms, speeds in 1/1000 cm/s, decelerations in
--  EVC_Braking's unit (1e-5 m/s², that is 1/1000 cm/s²), distances in
--  1e-6 cm: a deceleration times a time is then a speed / 1000, a speed
--  times a time a distance, and the formulas of A.3.12.3 to A.3.12.7
--  keep their shape. Every rounding goes the way that makes the reduced
--  time longer (the safe side: the limits come earlier): the speeds that
--  decide whether a reduction applies are rounded up, the times and the
--  distances along the ramp up, what is subtracted from them down, the
--  square roots up. The formulas are evaluated only within bounds that
--  keep every product in 64 bits (times up to 60 s, decelerations from
--  0.01 to 10 m/s², the measured accelerations up to 1 m/s², the ramp
--  at least 1 s long, the distances below 1000 km); outside them no
--  reduction is made and the equivalent build up time is the result,
--  which A.3.12.8.1 allows as its upper bound.

with EVC_Distances;
with EVC_Fixed; use EVC_Fixed;

use type EVC_Distances.Cm_T;

package EVC_Build_Up
  with SPARK_Mode => On
is

   --  The kinds of target of A.3.12: an MRSP element or the LOA (a target
   --  speed), the SvL or the end of the SR distance (zero speed, EBD),
   --  the EOA (zero speed, SBD)
   type Target_Kind_T is (Speed_Target, Zero_Target, EOA_Target);

   type Input_T is record
      Kind         : Target_Kind_T := Speed_Target;
      V_Est        : Speed_T := 0;   -- cm/s
      V_Delta0     : Speed_T := 0;   -- cm/s, 3.13.9.3.2.1
      V_Target     : Speed_T := 0;   -- cm/s
      A_Est1       : Decel_T := 0;   -- mm/s², 3.13.9.3.2.8
      A_Est2       : Decel_T := 0;   -- mm/s², 3.13.9.3.2.9
      T_Be_React   : Time_T := 0;
      T_Be         : Time_T := 0;
      T_Bs_React   : Time_T := 0;
      T_Bs         : Time_T := 0;
      --  3.13.9.3.2.3; A.3.12.2.6 to .8
      T_Traction     : Time_T := 0;
      T_Traction_Min : Time_T := 0;
      T_Traction_Max : Time_T := 0;
      --  A.3.12.2.2 to .5, 1e-5 m/s²
      A_EB           : Num := 0;
      A_Safe_Max     : Num := 0;
      A_SB           : Num := 0;
      A_Expected_Max : Num := 0;
      --  A.3.12.1.4: the conversion model with Kt_int = 0
      Kt_Zero        : Boolean := False;
   end record;

   --  A.3.12: T_be_reduced; T_be for the EOA (it has no EBD)
   function T_Be_Reduced (I : Input_T) return Time_T
     with Post => (if I.T_Be_React <= I.T_Be
                   then T_Be_Reduced'Result in I.T_Be_React .. I.T_Be
                   else T_Be_Reduced'Result = I.T_Be);

   --  A.3.12: T_bs_reduced (3.13.6.3.2.5: the caller takes T_bs when the
   --  service brake feedback is available for use)
   function T_Bs_Reduced (I : Input_T) return Time_T
     with Post => (if I.T_Bs_React <= I.T_Bs
                   then T_Bs_Reduced'Result in I.T_Bs_React .. I.T_Bs
                   else T_Bs_Reduced'Result = I.T_Bs);

end EVC_Build_Up;
