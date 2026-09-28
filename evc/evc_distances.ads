--  ETCS on-board (EVC)
--  Distances along the track and the directions of the odometer frame.
--
--  Every distance the position of phase E2 handles is in centimetres,
--  as an integer (no floating point under evc/). The arithmetic is done
--  in Cm_T, wide enough for the sum or the difference of any two values
--  of Dist_T, and brought back into Dist_T by Clamp: a result never
--  overflows, it saturates at Max_Cm (about 11 million km, beyond any
--  distance a train covers between two power-ups). The kernel stays on
--  additions, subtractions and multiplications by small constants of
--  64 bit integers; the few divisions are by constants.
--
--  The odometer frame (EVC_Odometry) has one axis: positions grow when
--  the engine moves towards its cab A end (Plus) and fall when it moves
--  towards cab B (Minus). The train orientation of SUBSET-026 3.6.1.5,
--  the orientation of a balise group (3.4.2.2.2) and the directions of
--  movement are Senses on this axis.

package EVC_Distances
  with SPARK_Mode => On, Pure
is

   Max_Cm : constant := 2**40;

   type Cm_T is range -2**62 .. 2**62;
   subtype Dist_T is Cm_T range -Max_Cm .. Max_Cm;
   subtype Length_T is Cm_T range 0 .. Max_Cm;

   function Clamp (X : Cm_T) return Dist_T is
     (if X > Max_Cm then Max_Cm elsif X < -Max_Cm then -Max_Cm else X);

   function Clamp_Length (X : Cm_T) return Length_T is
     (if X > Max_Cm then Max_Cm elsif X < 0 then 0 else X);

   function Sum (A, B : Dist_T) return Dist_T is (Clamp (A + B));
   function Diff (A, B : Dist_T) return Dist_T is (Clamp (A - B));

   --  A + B for lengths, saturating; never below A
   function Add (A, B : Length_T) return Length_T is
     (if A + B > Max_Cm then Max_Cm else A + B)
     with Post => Add'Result >= A and then Add'Result >= B;

   --  How much Now grew since Since, never negative
   function Growth (Now, Since : Length_T) return Length_T is
     (if Now > Since then Now - Since else 0);

   function Abs_Dist (X : Dist_T) return Length_T is
     (if X < 0 then -X else X);

   ---------------------------------------------------------------------
   --  Senses on the odometer axis
   ---------------------------------------------------------------------

   type Sense_T is (Plus, Minus);

   --  A sense, or none known
   type Direction_T is (Unknown, Plus, Minus);

   function Opposite (S : Sense_T) return Sense_T is
     (if S = Plus then Minus else Plus);

   function To_Direction (S : Sense_T) return Direction_T is
     (if S = Plus then Plus else Minus);

   function Same (D : Direction_T; S : Sense_T) return Boolean is
     ((D = Plus and then S = Plus) or else (D = Minus and then S = Minus));

   function Sign (S : Sense_T) return Cm_T is (if S = Plus then 1 else -1);

   --  X measured along S: X itself along Plus, -X along Minus
   function Along (S : Sense_T; X : Dist_T) return Dist_T is
     (if S = Plus then X else -X);

   --  The signed distance from A to B along S
   function Between (S : Sense_T; A, B : Dist_T) return Dist_T is
     (Along (S, Clamp (B - A)));

   --  The point at distance D from X along S
   function Advance (X : Dist_T; S : Sense_T; D : Dist_T) return Dist_T is
     (Sum (X, Along (S, D)));

   ---------------------------------------------------------------------
   --  Distances of the ERTMS/ETCS language
   ---------------------------------------------------------------------

   --  7.5.1.131 Q_SCALE: the resolution of the distances of a packet;
   --  3 is spare
   function Valid_Scale (Q_SCALE : Natural) return Boolean is
     (Q_SCALE <= 2);

   --  A 15 bit distance at the resolution Q_SCALE, cm
   function Scaled (Value : Natural; Q_SCALE : Natural) return Length_T is
     (Cm_T (Value) * (case Q_SCALE is
                         when 0 => 10,
                         when 1 => 100,
                         when others => 1000))
     with Pre => Value <= 2**16 and then Q_SCALE <= 2;

   --  Metres to cm
   function Metres (M : Natural) return Length_T is
     (Cm_T (M) * 100)
     with Pre => M <= 2**24;

end EVC_Distances;
