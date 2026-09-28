--  ETCS on-board (EVC)
--  The brake deceleration curves of SUBSET-026 3.13.8: EBD (3.13.8.3,
--  from the safe deceleration A_safe (V, d)), SBD (3.13.8.4, from the
--  expected deceleration A_expected (V, d)) and GUI (3.13.8.5, from the
--  normal service deceleration A_normal_service (V, d)).
--
--  A curve is given by a point it passes (Anchor, with the square of its
--  speed there) and its target speed (Floor): 3.13.8.3.1 anchors an EBD
--  of an MRSP or LOA target where it crosses the ceiling EBI limit at
--  the target location, an EBD of an SvL or of the end of the SR
--  distance at zero speed there (3.13.8.3.2, .3), an SBD at zero speed
--  at the EOA (3.13.8.4.1), a GUI at its foot (3.13.8.5.2). The curve
--  is computed piecewise (3.13.8.1.3): arcs of parabola along which the
--  deceleration is constant, v² changing by 2 a dx. An arc ends where
--  the segment of EVC_Profile ends (gradient, adhesion, inhibition) or
--  where the speed crosses a step of the deceleration model
--  (EVC_Braking). Rearwards of the anchor the speed grows where the
--  deceleration is positive; where the braking cannot overcome a
--  downhill gradient (a negative deceleration) it falls, and where the
--  two steps around a speed disagree it stays at that speed. Forwards
--  of the anchor the curve falls to the target speed at its foot, and
--  keeps the target speed beyond.
--
--  Fixed point and precision. The curve keeps W = v², (cm/s)², and the
--  location, cm; the deceleration a is in 1e-5 m/s² (EVC_Braking), so a
--  dx of D cm changes W by a * D / 500, computed exactly and rounded
--  down once (Gain). Every rounding keeps the curve below the exact one:
--  rearwards of the anchor the gain of W is rounded down with the model
--  values rounded down; forwards of the anchor the loss of W is taken
--  with a deceleration raised by a margin that covers the rounding of
--  the model (Forward); the location where the curve reaches a given W
--  is rounded towards where the curve is lower, and the speed is the
--  integer square root of W rounded down. Measured by evc_test against
--  a floating point reference (Scenario_SDM_Precision, some 6800 values
--  over trains, gradients and targets): the locations are never ahead of
--  the exact ones and at most 4.2 m (1.5 per mille of the distance)
--  behind, the speeds never above and at most 1.5 cm/s below. Every
--  query walks the arcs from the anchor, at most Max_Iterations of them
--  (every segment of the profile times every step of the deceleration);
--  the callers make a fixed number of queries per target (EVC_Limits,
--  EVC_SDM).

with EVC_Braking;   use EVC_Braking;
with EVC_Distances; use EVC_Distances;
with EVC_Fixed;     use EVC_Fixed;
with EVC_Profile;   use EVC_Profile;

package EVC_Curves
  with SPARK_Mode => On
is

   type Kind_T is (EBD, SBD, GUI);

   type Curve_T is record
      Kind     : Kind_T := EBD;
      Anchor   : Dist_T := 0;
      --  the square of the speed at Anchor
      Anchor_W : Square_T := 0;
      --  the square of the target speed, at most Anchor_W
      Floor_W  : Square_T := 0;
      --  the curve of a target due to a TSR: the gradients where the
      --  gradient profile gives nothing are the default gradient for TSR
      --  (EVC_Profile.Gradient_TSR, 3.13.4.1.3 a)
      TSR      : Boolean := False;
   end record;

   --  The deceleration of the curve Kind (of a target due to a TSR: TSR)
   --  in the segment Seg of the profile for W, and the squares bounding
   --  the step it holds for (EVC_Braking.Lookup)
   --  1e-5 m/s² (EVC_Braking)
   subtype Walk_Accel_T is Num range -20_000_000 .. 20_000_000;
   type Decel_Step_T is record
      A    : Walk_Accel_T;
      W_Lo : Num;
      W_Hi : Num;
   end record;

   function Deceleration (M      : Model_T;
                          P      : Profile_T;
                          Kind   : Kind_T;
                          TSR    : Boolean;
                          Seg    : Point_Index;
                          W      : Square_T;
                          Rising : Boolean) return Decel_Step_T
     with Pre  => Seg <= P.Count,
          Post => Deceleration'Result.W_Lo
                    in -1 .. Max_Speed * Max_Speed
                  and then Deceleration'Result.W_Hi
                             in 0 .. Infinite_Square;

   Max_Iterations : constant := Max_Points * (2 * Max_Steps + 8);

   --  The speed of the curve at X (the target speed beyond the foot),
   --  rounded down
   function Speed_At (M : Model_T;
                      P : Profile_T;
                      C : Curve_T;
                      X : Num) return Speed_T
     with Pre => C.Floor_W <= C.Anchor_W and then X in -Max_Cm .. Max_Cm;

   --  How far ahead of its anchor a curve is followed to its foot
   Max_Forward : constant := 100_000_000;  -- 1000 km

   --  The location where the curve reaches the speed V, rounded to the
   --  safe side (rearwards where the curve grows rearwards): rearwards
   --  of the anchor for a speed at least that of the anchor, forwards
   --  (at most at the foot) otherwise. Rearwards, a curve that does not
   --  reach V ahead of Stop gives Stop - 1: the location is behind Stop.
   --  Forwards, a curve that never falls to V gives its anchor.
   function Location_Of (M    : Model_T;
                         P    : Profile_T;
                         C    : Curve_T;
                         V    : Speed_T;
                         Stop : Num) return Num
     with Pre  => C.Floor_W <= C.Anchor_W
                  and then Stop in -Max_Cm + 1 .. Max_Cm,
          Post => Location_Of'Result in -Max_Cm .. Max_Cm + Max_Forward;

   --  A.3.12.2.2 to .5: the extreme decelerations along [X_From, X_To]
   --  (ahead coordinates; the gradients of a target due to a TSR: TSR)
   --  for the speeds V_EB_Lo .. V_EB_Hi (the
   --  emergency brake) and V_SB_Lo .. V_SB_Hi (the service brake), 1e-5
   --  m/s²: the lowest A_brake_safe (limited by A_MAXREDADH when reduced
   --  adhesion applies anywhere from Reduced_From to X_To), the highest
   --  A_safe, the lowest A_brake_service and the highest A_expected. The
   --  lowest ones are those of the model (never above the exact ones),
   --  the highest ones are raised as Walk_Forward raises the deceleration
   --  (never below the exact ones).
   type Extremes_T is record
      A_EB           : Num := 0;
      A_Safe_Max     : Num := 0;
      A_SB           : Num := 0;
      A_Expected_Max : Num := 0;
   end record;

   function Extremes (M            : Model_T;
                      P            : Profile_T;
                      TSR          : Boolean;
                      X_From       : Num;
                      X_To         : Num;
                      Reduced_From : Num;
                      V_EB_Lo      : Speed_T;
                      V_EB_Hi      : Speed_T;
                      V_SB_Lo      : Speed_T;
                      V_SB_Hi      : Speed_T) return Extremes_T
     with Post => Extremes'Result.A_EB in 0 .. 20_000_000
                  and then Extremes'Result.A_Safe_Max in 0 .. 20_000_000
                  and then Extremes'Result.A_SB in 0 .. 20_000_000
                  and then Extremes'Result.A_Expected_Max
                             in 0 .. 20_000_000;

end EVC_Curves;
