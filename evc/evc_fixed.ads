--  ETCS on-board (EVC)
--  The integer arithmetic of the speed and distance monitoring.
--
--  Plan §3 "Arithmetic": integers only. Speeds are cm/s, distances cm,
--  accelerations mm/s², times ms, factors in thousandths; the products
--  are computed in 64 bit integers (Num, the type of the distances of
--  EVC_Distances) whose operands are bounded by the subtypes below, so
--  that no product overflows. Every division says how it rounds:
--  Div_Floor rounds towards minus infinity, Div_Ceil towards plus
--  infinity, and the callers choose the one that keeps their result on
--  the safe side (a supervision limit never higher, a braking distance
--  never shorter than the exact value; EVC_Curves states the rule for
--  the curves). Square roots are integer square roots (Sqrt_Floor).

with EVC_Distances; use EVC_Distances;

package EVC_Fixed
  with SPARK_Mode => On, Pure
is

   --  The wide integer of every intermediate result
   subtype Num is Cm_T;

   --  cm/s: 60 000 cm/s is 2160 km/h, above any speed and its margins
   Max_Speed : constant := 60_000;
   subtype Speed_T is Num range 0 .. Max_Speed;

   --  mm/s², signed: a deceleration is positive, an acceleration due to
   --  a downhill gradient negative
   Max_Accel : constant := 60_000;
   subtype Accel_T is Num range -Max_Accel .. Max_Accel;
   subtype Decel_T is Accel_T range 0 .. Max_Accel;

   --  ms: a little more than an hour
   Max_Time : constant := 4_000_000;
   subtype Time_T is Num range 0 .. Max_Time;

   --  The square of a speed, (cm/s)²; the curves keep squares
   Max_Square : constant := 2**42;
   subtype Square_T is Num range 0 .. Max_Square;

   --  Factors, thousandths (1000 = 1.00)
   subtype Factor_T is Num range 0 .. 10_000;

   function Min (A, B : Num) return Num is (if A < B then A else B);
   function Max (A, B : Num) return Num is (if A > B then A else B);

   ---------------------------------------------------------------------
   --  Rounded divisions
   ---------------------------------------------------------------------

   --  A / B rounded towards minus infinity
   function Div_Floor (A, B : Num) return Num is
     (if A >= 0 then A / B else -((B - 1 - A) / B))
     with Pre  => B in 1 .. 2**40 and then A in -2**61 .. 2**61,
          Post => (if A >= 0 then Div_Floor'Result in 0 .. A
                   else Div_Floor'Result in A .. 0);

   --  A / B rounded towards plus infinity
   function Div_Ceil (A, B : Num) return Num is
     (if A <= 0 then -((-A) / B) else (A + B - 1) / B)
     with Pre  => B in 1 .. 2**40 and then A in -2**61 .. 2**61,
          Post => (if A >= 0 then Div_Ceil'Result in 0 .. A
                   else Div_Ceil'Result in A .. 0);

   ---------------------------------------------------------------------
   --  Square roots
   ---------------------------------------------------------------------

   --  The integer square root, rounded down
   function Sqrt_Floor (X : Num) return Num
     with Pre  => X in 0 .. 2**62,
          Post => Sqrt_Floor'Result in 0 .. 2**31
                  and then Sqrt_Floor'Result * Sqrt_Floor'Result <= X
                  and then (Sqrt_Floor'Result + 1)
                           * (Sqrt_Floor'Result + 1) > X;

   --  The speed whose square is W, rounded down, at most Max_Speed
   function Speed_Of (W : Num) return Speed_T is
     (if W <= 0 then 0 else Min (Sqrt_Floor (Min (W, 2**62)), Max_Speed))
     with Pre => W in -2**62 .. 2**62;

   function Square (V : Speed_T) return Square_T is (V * V);

   ---------------------------------------------------------------------
   --  Kinematics
   ---------------------------------------------------------------------

   --  The distance, cm, run at V cm/s during T ms, rounded up
   function Travel_Ceil (V : Speed_T; T : Time_T) return Num is
     (Div_Ceil (V * T, 1000));

   --  The same, rounded down
   function Travel_Floor (V : Speed_T; T : Time_T) return Num is
     (Div_Floor (V * T, 1000));

   --  The speed gained, cm/s, at A mm/s² during T ms, rounded up
   function Gain_Ceil (A : Decel_T; T : Time_T) return Num is
     (Div_Ceil (A * T, 10_000));

   ---------------------------------------------------------------------
   --  Units of the ERTMS/ETCS language and of the DMI
   ---------------------------------------------------------------------

   --  K tenths of km/h in cm/s (1 km/h = 250 / 9 cm/s), rounded down
   function Kmh10_To_Cms (K : Num) return Num is
     (Div_Floor (K * 25, 9))
     with Pre => K in 0 .. 100_000;

   --  The same, rounded up
   function Kmh10_To_Cms_Ceil (K : Num) return Num is
     (Div_Ceil (K * 25, 9))
     with Pre => K in 0 .. 100_000;

   --  A speed in km/h for the driver, to the nearest km/h
   function Cms_To_Kmh (V : Speed_T) return Num is
     ((V * 36 + 500) / 1000);

   --  A speed in km/h, rounded down
   function Cms_To_Kmh_Floor (V : Speed_T) return Num is
     (V * 36 / 1000);

end EVC_Fixed;
