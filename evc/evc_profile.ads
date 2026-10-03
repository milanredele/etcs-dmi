--  ETCS on-board (EVC)
--  The track as the curves of the speed and distance monitoring see it:
--  SUBSET-026 3.13.4 (the acceleration due to the gradient, compensated
--  in location with the train length and in value with the rotating
--  mass) and 3.13.5 (the locations with reduced adhesion and without
--  the contribution of a special brake).
--
--  Build merges, once per cycle, the gradient profile, the adhesion
--  areas and the special brake inhibition areas of the snapshot into
--  one list of segments along the track, in the sense of the movement
--  authority ("ahead" coordinates: Along (Ahead, frame position), so
--  that a larger coordinate is further ahead). Segment I covers
--  [Points (I).Start, Points (I + 1).Start), as the gradient profile
--  does, the first one starts at minus infinity (-Max_Cm) and the last
--  one is open ended. Every attribute of a segment is its most
--  restrictive value anywhere in the segment:
--    - Gradient: 3.13.4.2, the lowest gradient under a fictive train
--      whose front end is in the segment ([front - L_TRAIN, front]);
--      where the gradient profile gives nothing (before its first
--      segment, and its segments not Covered), 0 (3.13.4.1.3 b);
--    - A_Gradient: 3.13.4.3.2, g * grad / (1000 + 10 * M_rotating),
--      in 1e-5 m/s² (EVC_Braking), rounded down (M_rotating_max uphill,
--      _min downhill, or the nominal one);
--    - Gradient_TSR, A_Gradient_TSR: the same for the curves of a
--      target due to a TSR, with the default gradient for TSR where the
--      gradient profile gives nothing, when one is stored (3.13.4.1.2,
--      3.13.4.1.3 a);
--    - Reduced: 3.13.5.3 to 3.13.5.5, the segment meets a reduced
--      adhesion area extended by the train length, or the driver
--      selected "slippery rail";
--    - Inhibited: 3.13.5.1, a special brake inhibition area of that kind
--      starts in or before the segment (the inhibition then holds up to
--      the foot of any curve, which is always beyond the segments a
--      curve walks). Areas the min safe rear end has left are ignored.
--      A powerless section (3.13.2.3.4.1) inhibits the regenerative
--      brake when it needs the catenary (3.12.1.3.3, the configuration
--      Regenerative_Needs_Catenary).
--  The size is bounded by the snapshot: Max_Points segments, the work
--  of Build by the product of the profile sizes (a few 10^4 steps).

with EVC_Braking;           use EVC_Braking;
with EVC_Distances;         use EVC_Distances;
with EVC_Fixed;             use EVC_Fixed;
with EVC_Supervision_Input; use EVC_Supervision_Input;

package EVC_Profile
  with SPARK_Mode => On
is

   Max_Points : constant :=
     1 + 2 * Max_Gradient_Segments + 2 * Max_Adhesion_Areas
     + Max_Inhibition_Areas;
   subtype Point_Index is Positive range 1 .. Max_Points;

   --  1e-5 m/s² (EVC_Braking.Decel_Unit)
   subtype Gradient_Accel_T is Num range -300_000 .. 300_000;

   type Point_T is record
      Start      : Dist_T := -Max_Cm;
      Gradient   : Gradient_T := 0;
      A_Gradient : Gradient_Accel_T := 0;
      Gradient_TSR   : Gradient_T := 0;
      A_Gradient_TSR : Gradient_Accel_T := 0;
      Reduced    : Boolean := False;
      Inhibited  : Inhibitions_T := (others => False);
   end record;
   type Point_Array is array (Point_Index) of Point_T;
   No_Point : constant Point_T := (others => <>);

   --  (every component has a default expression, the points a named
   --  element: an aggregate (others => <>) of the type is then built in
   --  place, not in a temporary on the stack and copied)
   type Profile_T is record
      Count  : Point_Index := 1;
      Points : Point_Array := (others => No_Point);
   end record;

   --  A position of the frame in ahead coordinates
   function Ahead_Of (S : Snapshot_T; X : Dist_T) return Dist_T is
     (Along (S.Train.Ahead, X));

   --  3.13.4.3.2: A_gradient for Grad, 1e-5 m/s², rounded down (g =
   --  9.81 m/s²)
   function Gradient_Acceleration (Grad       : Gradient_T;
                                   Up, Down   : Natural) return Num
   is (Max (Min (Div_Floor (981_000 * Num (Grad),
                            1_000 + 10 * Num (if Grad > 0 then Up
                                              else Down)),
                 300_000), -300_000))
     with Pre => Up <= 100 and then Down <= 100,
          Post => Gradient_Acceleration'Result in -300_000 .. 300_000;

   --  Rear: the min safe rear end of the train, ahead coordinates
   procedure Build (S     : Snapshot_T;
                    Model : Model_T;
                    Rear  : Dist_T;
                    P     : out Profile_T);

   --  The segment that holds X: the last one that starts at or before
   --  X
   function Segment_Of (P : Profile_T; X : Num) return Point_Index
     with Post => Segment_Of'Result <= P.Count;

end EVC_Profile;
