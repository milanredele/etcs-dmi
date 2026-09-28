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
--  location, cm; with the deceleration a in mm/s², a dx of D cm changes
--  W by a * D / 5. Every rounding keeps the curve below the exact one:
--  along an arc the change of W is rounded down (rearwards it is a
--  gain, forwards a loss), the location where the curve reaches a
--  given W is rounded towards where the curve is lower, and the speed
--  is the integer square root of W rounded down. The error per arc is
--  below 1 (cm/s)² and 1 cm; over the at most a few hundred arcs of a
--  curve it stays below 0.1 km/h and 1 m at the speeds of the
--  supervision (evc_test measures it against a floating point
--  reference). Every query walks the arcs from the anchor, at most
--  Max_Iterations of them (every segment of the profile times every
--  step of the deceleration); the callers make a fixed number of
--  queries per target (EVC_Limits).

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
   end record;

   --  The deceleration of the curve Kind in the segment Seg of the
   --  profile for W, and the squares bounding the step it holds for
   --  (EVC_Braking.Lookup)
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

end EVC_Curves;
