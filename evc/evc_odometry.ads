--  ETCS on-board (EVC)
--  The odometry of the on-board: the odometer frame, its confidence,
--  the monitoring of its accuracy (SUBSET-026 3.6.8), the cold movement
--  detection read at power-up (3.15.8) and the distances not referred
--  to balise groups (3.6.7).
--
--  The odometer port (EVC_Ports) delivers counters: the travelled
--  distance d_est and the accumulated over- and under-reading amounts,
--  all wrapping modulo 2**32. Apply takes the difference of each counter
--  since the previous sample and accumulates it here:
--    Position   the frame position: the reading of the odometer, cm,
--               growing towards cab A. A point of the track has the
--               position the odometer had when the balise antenna was
--               over it (the stamp of a balise, EVC_Ports).
--    Low, High  the confidence of the frame: between any two samples
--               the true displacement, measured towards cab A, is at
--               least (Position change - Low change) and at most
--               (Position change + High change). A movement towards cab
--               A adds the over-reading to Low and the under-reading to
--               High; a movement towards cab B the other way round; a
--               sample whose direction is not certain adds both to both.
--    Over, Under the over- and under-reading amounts themselves, each
--               accumulated over every movement whatever its direction
--               (3.6.8.1.1), and Travelled, the length of every
--               movement.
--  All six never decrease (Apply's postcondition): the confidence
--  interval of a position measured from a fixed reference only widens,
--  which is what 3.6.4.1.2 states. A counter that goes back (a
--  malfunction of the odometer) adds nothing and is counted
--  (Anomalies); the confidence then grows no more than the odometer
--  says, which is its own responsibility (SUBSET-041 5.3.1.1 notes).
--
--  Monitoring of the odometer accuracy (3.6.8, values of A.3.1): the
--  travelled distance is cut into intervals of exactly Interval_Cm
--  (100 m, the maximum distance interval), the over- and under-reading
--  growth of each interval is kept for the last Total_Cm (5000 m), and
--  at the end of every interval the two sums are checked (3.6.8.3,
--  3.6.8.4): above Impairment_Cm (250 m) the odometer performance is
--  impaired (3.6.8.5), above Safety_Cm (1500 m) the safety threshold is
--  exceeded (3.6.8.7). Both apply from the first interval on, before the
--  whole 5000 m were travelled (3.6.8.8). Impaired ends once 5000 m were
--  travelled with both sums, at every check, below the accuracy of
--  distances measured on-board, 5 m + 5 % of the distance of the sums
--  (SUBSET-041 5.3.1.1; 3.6.8.6). E2 reports; the reactions (informing
--  the driver, System Failure) are those of phase E4 (EVC_Position
--  events, EVC_Core).
--
--  Cold movement (3.15.8): the detection works while the on-board is in
--  No Power and is part of the odometer port. The first sample after
--  power-up carries whether its information is available and how far
--  the engine was moved; the on-board applies the 2 m of 3.15.8.1.1.
--
--  Virtual positions (3.6.7): a Virtual_T is a supervised distance with
--  the frame position and the accumulated amounts at its start; the
--  functions below give what 3.6.7.2 and 3.6.7.3 define. The functions
--  that supervise such distances (roll away protection, SR distance,
--  ...) keep their own Virtual_T (phases E3 and E4).

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Distances; use EVC_Distances;
with EVC_Ports;     use EVC_Ports;
with Interfaces;    use Interfaces;

package EVC_Odometry
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  A.3.1, monitoring of odometer accuracy
   Total_Cm      : constant := 500_000;  -- total distance, 5000 m
   Interval_Cm   : constant := 10_000;   -- maximum distance interval
   Impairment_Cm : constant := 25_000;   -- 5 % of 5000 m
   Safety_Cm     : constant := 150_000;  -- 30 % of 5000 m
   Intervals     : constant := Total_Cm / Interval_Cm;

   --  SUBSET-041 5.3.1.1, the accuracy of a distance S measured on-board
   function Accuracy (S : Length_T) return Length_T is
     (Clamp_Length (500 + S / 20));

   --  3.15.8.1.1: small movements in No Power, 2 m
   Cold_Allowance_Cm : constant := 200;

   type Cold_T is
     (Cold_Unknown,         -- no sample since power-up
      No_Cold_Movement,
      Cold_Movement,
      Cold_Not_Available);  -- 3.15.8.3

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   --  A sample was applied since Clear
   function Known return Boolean
     with Global => State;

   function Position return Dist_T
     with Global => State;

   function Low return Length_T
     with Global => State;
   function High return Length_T
     with Global => State;
   function Over return Length_T
     with Global => State;
   function Under return Length_T
     with Global => State;
   function Travelled return Length_T
     with Global => State;

   --  The speed and its interval, the movement, of the last sample
   function Speed return Speed_Cms_T
     with Global => State;
   function Speed_Max return Speed_Cms_T
     with Global => State;
   function Movement return Movement_T
     with Global => State;

   function Standstill return Boolean is (Movement = Standstill)
     with Global => State;

   --  The sense of the last movement whose direction was known
   function Last_Direction return Direction_T
     with Global => State;

   --  Samples whose over or under counter went back
   function Anomalies return Natural
     with Global => State;

   --  The frame position of a d_est reading of the odometer (a balise
   --  stamp): the current position moved by the difference of the
   --  readings; before any sample, the reading itself
   function To_Frame (Reading : Unsigned_32) return Dist_T
     with Global => State;

   --  3.6.8
   function Impaired return Boolean
     with Global => State;
   function Safety_Exceeded return Boolean
     with Global => State;
   --  The accumulated over- and under-reading of the last Total_Cm,
   --  as of the last check
   function Window_Over return Length_T
     with Global => State;
   function Window_Under return Length_T
     with Global => State;

   --  3.15.8
   function Cold return Cold_T
     with Global => State;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   --  Power-up: nothing measured
   procedure Clear
     with Global => (Output => State),
          Post => not Known
                  and then Position = 0
                  and then Low = 0 and then High = 0
                  and then Over = 0 and then Under = 0
                  and then Travelled = 0
                  and then Standstill
                  and then not Impaired
                  and then not Safety_Exceeded
                  and then Cold = Cold_Unknown;

   --  One sample of the odometer port. Applying the same sample twice
   --  changes nothing the second time.
   procedure Apply (Sample : Odometer_Sample_T)
     with Global => (In_Out => State),
          Post => Known
                  and then Low >= Low'Old
                  and then High >= High'Old
                  and then Over >= Over'Old
                  and then Under >= Under'Old
                  and then Travelled >= Travelled'Old
                  and then (if Safety_Exceeded'Old then Safety_Exceeded)
                  and then (if Safety_Exceeded then Impaired)
                  and then (if Known'Old then Cold = Cold'Old
                            else Cold /= Cold_Unknown)
                  and then Movement = Sample.Movement;

   ---------------------------------------------------------------------
   --  3.6.7: distances not referred to balise groups
   ---------------------------------------------------------------------

   type Virtual_T is record
      Active   : Boolean := False;
      --  the supervised distance and its sense (for 3.6.7.3, the train
      --  orientation when the supervision started)
      Distance : Length_T := 0;
      Sense    : Sense_T := Plus;
      --  the frame position and the accumulated amounts at the start
      Start    : Dist_T := 0;
      Over_0   : Length_T := 0;
      Under_0  : Length_T := 0;
   end record;

   --  Start (or re-start, 3.6.7.5) the supervision of Distance from
   --  here, along Sense
   function Start_Virtual (Distance : Length_T; Sense : Sense_T)
     return Virtual_T
     with Global => State,
          Post => Start_Virtual'Result.Active
                  and then Start_Virtual'Result.Distance = Distance
                  and then Start_Virtual'Result.Start = Position;

   --  3.6.7.5: new National Values change the distance, not the start
   procedure Set_Distance (V : in out Virtual_T; Distance : Length_T)
     with Global => null,
          Post => V.Distance = Distance
                  and then V.Start = V.Start'Old
                  and then V.Active = V.Active'Old;

   --  3.6.7.2: the estimated distance travelled away from the start, in
   --  the direction D (Plus, Minus) or in both (Unknown)
   function Away (V : Virtual_T; D : Direction_T) return Length_T
     with Global => State;

   --  3.6.7.3 a): the remaining distance from the estimated front end to
   --  the end of the supervised distance
   function Remaining_Estimated (V : Virtual_T) return Dist_T
     with Global => State;

   --  3.6.7.3 b): from the max safe front end: minus the under-reading
   --  amount since the start
   function Remaining_Max_Safe (V : Virtual_T) return Dist_T
     with Global => State,
          Post => Remaining_Max_Safe'Result <= Remaining_Estimated (V);

   --  3.6.7.3 c): from the min safe front end: plus the over-reading
   --  amount since the start
   function Remaining_Min_Safe (V : Virtual_T) return Dist_T
     with Global => State,
          Post => Remaining_Min_Safe'Result >= Remaining_Estimated (V);

end EVC_Odometry;
