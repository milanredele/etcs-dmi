--  ETCS on-board (EVC)
--  The odometry of the on-board, implementation.

package body EVC_Odometry
  with SPARK_Mode => On,
       Refined_State => (State => (Known_Flag,
                                   Raw,
                                   X,
                                   Low_Acc,
                                   High_Acc,
                                   Over_Acc,
                                   Under_Acc,
                                   Travel_Acc,
                                   Last,
                                   Last_Dir,
                                   Anomaly_Count,
                                   Ring,
                                   Ring_Next,
                                   Ring_Filled,
                                   Current_Travel,
                                   Current_Over,
                                   Current_Under,
                                   Good_Distance,
                                   Impaired_Flag,
                                   Safety_Flag,
                                   Sum_Over,
                                   Sum_Under,
                                   Cold_Status))
is

   subtype Interval_Travel_T is Length_T range 0 .. Interval_Cm - 1;

   type Slot_T is record
      Over, Under : Length_T := 0;
   end record;
   subtype Ring_Index_T is Positive range 1 .. Intervals;
   type Ring_T is array (Ring_Index_T) of Slot_T;

   Known_Flag     : Boolean := False;
   --  the last sample, its counters as they came
   Raw            : Odometer_Sample_T := Standstill_Sample;
   Last           : Odometer_Sample_T := Standstill_Sample;
   X              : Dist_T := 0;
   Low_Acc        : Length_T := 0;
   High_Acc       : Length_T := 0;
   Over_Acc       : Length_T := 0;
   Under_Acc      : Length_T := 0;
   Travel_Acc     : Length_T := 0;
   Last_Dir       : Direction_T := Unknown;
   Anomaly_Count  : Natural := 0;
   --  3.6.8: the closed intervals of the last Total_Cm, and the open one
   Ring           : Ring_T := (others => (0, 0));
   Ring_Next      : Ring_Index_T := 1;
   Ring_Filled    : Natural range 0 .. Intervals := 0;
   Current_Travel : Interval_Travel_T := 0;
   Current_Over   : Length_T := 0;
   Current_Under  : Length_T := 0;
   --  distance travelled with both sums below the accuracy, while
   --  impaired
   Good_Distance  : Length_T := 0;
   Impaired_Flag  : Boolean := False;
   Safety_Flag    : Boolean := False;
   Sum_Over       : Length_T := 0;
   Sum_Under      : Length_T := 0;
   Cold_Status    : Cold_T := Cold_Unknown;

   function Known return Boolean is (Known_Flag)
     with Refined_Global => Known_Flag;
   function Position return Dist_T is (X)
     with Refined_Global => X;
   function Low return Length_T is (Low_Acc)
     with Refined_Global => Low_Acc;
   function High return Length_T is (High_Acc)
     with Refined_Global => High_Acc;
   function Over return Length_T is (Over_Acc)
     with Refined_Global => Over_Acc;
   function Under return Length_T is (Under_Acc)
     with Refined_Global => Under_Acc;
   function Travelled return Length_T is (Travel_Acc)
     with Refined_Global => Travel_Acc;
   function Speed return Speed_Cms_T is (Last.V_Est)
     with Refined_Global => Last;
   function Speed_Max return Speed_Cms_T is (Last.V_Max)
     with Refined_Global => Last;
   function Movement return Movement_T is (Last.Movement)
     with Refined_Global => Last;
   function Last_Direction return Direction_T is (Last_Dir)
     with Refined_Global => Last_Dir;
   function Anomalies return Natural is (Anomaly_Count)
     with Refined_Global => Anomaly_Count;
   --  the safety threshold is beyond the impairment threshold
   function Impaired return Boolean is (Impaired_Flag or else Safety_Flag)
     with Refined_Global => (Impaired_Flag, Safety_Flag);
   function Safety_Exceeded return Boolean is (Safety_Flag)
     with Refined_Global => Safety_Flag;
   function Window_Over return Length_T is (Sum_Over)
     with Refined_Global => Sum_Over;
   function Window_Under return Length_T is (Sum_Under)
     with Refined_Global => Sum_Under;
   function Cold return Cold_T is (Cold_Status)
     with Refined_Global => Cold_Status;

   --  A - B of two wrapping counters, as the signed difference of less
   --  than 2**31 in magnitude it stands for
   function Wrap (A, B : Unsigned_32) return Dist_T is
     (if A - B < 2**31 then Cm_T (A - B) else Cm_T (A - B) - 2**32);

   --  A reading taken as a signed 32 bit value
   function Signed (A : Unsigned_32) return Dist_T is (Wrap (A, 0));

   function To_Frame (Reading : Unsigned_32) return Dist_T is
     (if Known_Flag then Sum (X, Wrap (Reading, Raw.D_Est))
      else Signed (Reading))
     with Refined_Global => (Known_Flag, X, Raw);

   -----------
   -- Clear --
   -----------

   procedure Clear
     with Refined_Global => (Output => (Known_Flag, Raw, X, Low_Acc,
                                        High_Acc, Over_Acc, Under_Acc,
                                        Travel_Acc, Last, Last_Dir,
                                        Anomaly_Count, Ring, Ring_Next,
                                        Ring_Filled, Current_Travel,
                                        Current_Over, Current_Under,
                                        Good_Distance, Impaired_Flag,
                                        Safety_Flag, Sum_Over, Sum_Under,
                                        Cold_Status))
   is
   begin
      Known_Flag := False;
      Raw := Standstill_Sample;
      Last := Standstill_Sample;
      X := 0;
      Low_Acc := 0;
      High_Acc := 0;
      Over_Acc := 0;
      Under_Acc := 0;
      Travel_Acc := 0;
      Last_Dir := Unknown;
      Anomaly_Count := 0;
      Ring := (others => (0, 0));
      Ring_Next := 1;
      Ring_Filled := 0;
      Current_Travel := 0;
      Current_Over := 0;
      Current_Under := 0;
      Good_Distance := 0;
      Impaired_Flag := False;
      Safety_Flag := False;
      Sum_Over := 0;
      Sum_Under := 0;
      Cold_Status := Cold_Unknown;
   end Clear;

   ---------------------------------------------------------------------
   --  3.6.8
   ---------------------------------------------------------------------

   --  The end of an interval: keep it in the ring, sum the ring, check
   --  the thresholds
   procedure Close_Interval
     with Global => (In_Out => (Ring, Ring_Next, Ring_Filled,
                                Current_Over, Current_Under,
                                Good_Distance, Impaired_Flag, Safety_Flag),
                     Output => (Sum_Over, Sum_Under)),
          Post => (if Safety_Flag'Old then Safety_Flag)
                  and then Current_Over = 0 and then Current_Under = 0
   is
      S_Over, S_Under : Length_T := 0;
      Window          : Length_T;
   begin
      Ring (Ring_Next) := (Over => Current_Over, Under => Current_Under);
      Ring_Next := (if Ring_Next = Intervals then 1 else Ring_Next + 1);
      if Ring_Filled < Intervals then
         Ring_Filled := Ring_Filled + 1;
      end if;
      Current_Over := 0;
      Current_Under := 0;

      for I in Ring_Index_T loop
         S_Over := Add (S_Over, Ring (I).Over);
         S_Under := Add (S_Under, Ring (I).Under);
      end loop;
      Sum_Over := S_Over;
      Sum_Under := S_Under;
      Window := Cm_T (Ring_Filled) * Interval_Cm;

      if S_Over > Safety_Cm or else S_Under > Safety_Cm then
         --  3.6.8.7
         Safety_Flag := True;
      end if;
      if S_Over > Impairment_Cm or else S_Under > Impairment_Cm
        or else Safety_Flag
      then
         --  3.6.8.5
         Impaired_Flag := True;
         Good_Distance := 0;
      elsif Impaired_Flag then
         --  3.6.8.6: continuously below the accuracy over the total
         --  distance
         if S_Over < Accuracy (Window) and then S_Under < Accuracy (Window)
         then
            Good_Distance := Add (Good_Distance, Interval_Cm);
            if Good_Distance >= Total_Cm then
               Impaired_Flag := False;
               Good_Distance := 0;
            end if;
         else
            Good_Distance := 0;
         end if;
      end if;
   end Close_Interval;

   --  Move cm travelled with the growths Grow_Over and Grow_Under of the
   --  amounts: cut at the ends of the intervals, each part of the
   --  movement taking its share of the growths
   procedure Monitor (Move, Grow_Over, Grow_Under : Length_T)
     with Global => (In_Out => (Ring, Ring_Next, Ring_Filled,
                                Current_Travel, Current_Over,
                                Current_Under, Good_Distance,
                                Impaired_Flag, Safety_Flag,
                                Sum_Over, Sum_Under)),
          Post => (if Safety_Flag'Old then Safety_Flag)
   is
      M      : Length_T := Move;
      G_Over : Length_T := Grow_Over;
      G_Und  : Length_T := Grow_Under;
      Part   : Length_T;
      Share_O, Share_U : Length_T;
   begin
      --  a jump of more than the whole window renews every interval:
      --  Intervals + 1 closings are enough
      for Step in 1 .. Intervals + 1 loop
         pragma Loop_Invariant (if Safety_Flag'Loop_Entry then Safety_Flag);
         if Current_Travel + M < Interval_Cm then
            Current_Travel := Current_Travel + M;
            Current_Over := Add (Current_Over, G_Over);
            Current_Under := Add (Current_Under, G_Und);
            return;
         end if;
         Part := Interval_Cm - Current_Travel;
         pragma Assert (Part > 0 and then Part <= M);
         Share_O := Clamp_Length (G_Over * Part / M);
         Share_U := Clamp_Length (G_Und * Part / M);
         Current_Over := Add (Current_Over, Share_O);
         Current_Under := Add (Current_Under, Share_U);
         Close_Interval;
         Current_Travel := 0;
         M := M - Part;
         G_Over := Clamp_Length (G_Over - Share_O);
         G_Und := Clamp_Length (G_Und - Share_U);
      end loop;
      --  what is left of a jump stays in the open interval, whole
      Current_Travel := M mod Interval_Cm;
      Current_Over := Add (Current_Over, G_Over);
      Current_Under := Add (Current_Under, G_Und);
   end Monitor;

   -----------
   -- Apply --
   -----------

   procedure Apply (Sample : Odometer_Sample_T)
     with Refined_Global => (Output => Last,
                             In_Out => (Known_Flag, Raw, X, Low_Acc,
                                        High_Acc, Over_Acc, Under_Acc,
                                        Travel_Acc, Last_Dir,
                                        Anomaly_Count, Ring, Ring_Next,
                                        Ring_Filled, Current_Travel,
                                        Current_Over, Current_Under,
                                        Good_Distance, Impaired_Flag,
                                        Safety_Flag, Sum_Over, Sum_Under,
                                        Cold_Status))
   is
      Delta_X : Dist_T;
      D_Over  : Dist_T;
      D_Under : Dist_T;
      G_Over  : Length_T;
      G_Under : Length_T;
      Move    : Length_T;
      Both    : Length_T;

      --  the movement has one direction over the whole sample
      function Towards (M : Movement_T; S : Sense_T) return Boolean is
        (M = Standstill
         or else (S = Plus and then M = Towards_Cab_A)
         or else (S = Minus and then M = Towards_Cab_B));
   begin
      if not Known_Flag then
         --  the first sample after power-up: the frame starts at its
         --  reading, and the cold movement detection is read (3.15.8.2)
         Known_Flag := True;
         X := Signed (Sample.D_Est);
         Cold_Status :=
           (if not Sample.Cold_Available then Cold_Not_Available
            elsif Natural (Sample.Cold_Distance) > Cold_Allowance_Cm
            then Cold_Movement
            else No_Cold_Movement);
      else
         Delta_X := Wrap (Sample.D_Est, Raw.D_Est);
         D_Over := Wrap (Sample.Over, Raw.Over);
         D_Under := Wrap (Sample.Under, Raw.Under);
         if D_Over < 0 or else D_Under < 0 then
            if Anomaly_Count < Natural'Last then
               Anomaly_Count := Anomaly_Count + 1;
            end if;
         end if;
         G_Over := (if D_Over > 0 then D_Over else 0);
         G_Under := (if D_Under > 0 then D_Under else 0);
         Move := Abs_Dist (Delta_X);

         X := Sum (X, Delta_X);
         Over_Acc := Add (Over_Acc, G_Over);
         Under_Acc := Add (Under_Acc, G_Under);
         Travel_Acc := Add (Travel_Acc, Move);
         if Delta_X > 0
           and then Towards (Raw.Movement, Plus)
           and then Towards (Sample.Movement, Plus)
         then
            --  towards cab A: over-reading on the low side
            Low_Acc := Add (Low_Acc, G_Over);
            High_Acc := Add (High_Acc, G_Under);
         elsif Delta_X < 0
           and then Towards (Raw.Movement, Minus)
           and then Towards (Sample.Movement, Minus)
         then
            Low_Acc := Add (Low_Acc, G_Under);
            High_Acc := Add (High_Acc, G_Over);
         else
            --  the direction is not certain: both amounts on both sides
            Both := Add (G_Over, G_Under);
            Low_Acc := Add (Low_Acc, Both);
            High_Acc := Add (High_Acc, Both);
         end if;
         Monitor (Move, G_Over, G_Under);
      end if;
      Raw := Sample;
      Last := Sample;
      case Sample.Movement is
         when Towards_Cab_A => Last_Dir := Plus;
         when Towards_Cab_B => Last_Dir := Minus;
         when Standstill | Moving_Unknown => null;
      end case;
   end Apply;

   ---------------------------------------------------------------------
   --  3.6.7
   ---------------------------------------------------------------------

   function Start_Virtual (Distance : Length_T; Sense : Sense_T)
     return Virtual_T
   is ((Active   => True,
        Distance => Distance,
        Sense    => Sense,
        Start    => X,
        Over_0   => Over_Acc,
        Under_0  => Under_Acc))
     with Refined_Global => (X, Over_Acc, Under_Acc);

   procedure Set_Distance (V : in out Virtual_T; Distance : Length_T) is
   begin
      V.Distance := Distance;
   end Set_Distance;

   function Away (V : Virtual_T; D : Direction_T) return Length_T is
     (case D is
         when Plus    => Clamp_Length (X - V.Start),
         when Minus   => Clamp_Length (V.Start - X),
         when Unknown => Abs_Dist (Diff (X, V.Start)))
     with Refined_Global => X;

   function Remaining_Estimated (V : Virtual_T) return Dist_T is
     (Diff (V.Distance, Between (V.Sense, V.Start, X)))
     with Refined_Global => X;

   function Remaining_Max_Safe (V : Virtual_T) return Dist_T is
     (Diff (Remaining_Estimated (V), Growth (Under_Acc, V.Under_0)))
     with Refined_Global => (X, Under_Acc);

   function Remaining_Min_Safe (V : Virtual_T) return Dist_T is
     (Sum (Remaining_Estimated (V), Growth (Over_Acc, V.Over_0)))
     with Refined_Global => (X, Over_Acc);

end EVC_Odometry;
