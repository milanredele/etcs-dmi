--  ETCS on-board (EVC)
--  Locations of the stored information, and the lower envelope of
--  elements along the track (SUBSET-026 3.6.4.2, 3.13.7).
--
--  Locations. A location of stored information is an offset from an
--  origin (EVC_Origins): along the sense of the distances of the group
--  message that gave it, from the location reference of the group. Its
--  frame position depends on the kind of location item of Table 2a
--  that a clause uses: the "estimated", "min" or "max" item of the
--  origin moved by the offset. A location of origin 0 is a frame
--  position that relocation does not move (the train position when an
--  MA was withdrawn to it, A.3.4.1.3 [11]). The frame positions of the
--  origins are taken once per cycle into an Origin_Table_T.
--
--  Elements and their lower envelope. A speed restriction, a gradient
--  or any other value that holds over a stretch of track is an element
--  [Start, Finish) with a value, in coordinates along the sense of the
--  movement authority (Along of EVC_Distances: they grow ahead). Its
--  start is the "max" location item and its end the "min" location
--  item of its locations (Table 2a: a restriction begins where the max
--  safe front end may already be and ends where the min safe front end
--  surely is), the end moved by the train length where the rear end
--  counts (3.11.2.4). The envelope of a set of elements is the step
--  profile whose value at every position is the lowest of the elements
--  there, the Default where none is, never above a Ceiling: the MRSP of
--  3.13.7 from the speed restrictions, and the gradient profile from
--  the gradients (3.6.4.2.6, "the lowest parts of the overlapping
--  elements" when a relocation made them overlap).
--
--  Envelope proves what the SRS asks of it (its postcondition): the
--  steps are sorted and start at the rear end of the axis, and no step
--  is above any element it overlaps nor above the Ceiling. The profile
--  is computed on the breakpoints of the elements; the steps beyond the
--  Capacity are folded into the last one with their lowest value; and
--  the result is checked against every element before it is returned.
--  A check that fails (none is expected: the tests count them) returns
--  the most restrictive profile, the Floor everywhere.

with EVC_Distances; use EVC_Distances;
with EVC_Location;  use EVC_Location;
with EVC_Origins;
with Interfaces;    use Interfaces;

package EVC_Profiles
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------
   --  Locations
   ---------------------------------------------------------------------

   type Location_T is record
      Origin : EVC_Origins.Count_T := 0;
      Offset : Dist_T := 0;
   end record;

   --  The frame positions of the three items of an origin at offset 0,
   --  and the sense of its offsets
   type Origin_Frame_T is record
      Used  : Boolean := False;
      Sense : Sense_T := Plus;
      Est   : Dist_T := 0;
      Min   : Dist_T := 0;
      Max   : Dist_T := 0;
   end record;

   type Origin_Table_T is array (EVC_Origins.Index_T) of Origin_Frame_T;

   --  The table of the current origins
   function Origin_Table return Origin_Table_T
     with Global => EVC_Origins.State;

   --  The frame position of the item of kind K of L
   function Frame (T : Origin_Table_T; L : Location_T; K : Item_Kind_T)
     return Dist_T
   is (if L.Origin = 0 or else not T (L.Origin).Used then L.Offset
       else Advance ((case K is
                         when Estimated_Item => T (L.Origin).Est,
                         when Min_Item       => T (L.Origin).Min,
                         when Max_Item       => T (L.Origin).Max),
                     T (L.Origin).Sense, L.Offset));

   --  The location of origin O at the frame position X (estimated)
   function At_Frame (T : Origin_Table_T; O : EVC_Origins.Count_T;
                      X : Dist_T) return Location_T
   is (if O = 0 or else not T (O).Used then (Origin => 0, Offset => X)
       else (Origin => O,
             Offset => Between (T (O).Sense, T (O).Est, X)));

   --  L moved by D along the sense of its origin (along S for origin 0)
   function Moved (T : Origin_Table_T; L : Location_T; D : Dist_T;
                   S : Sense_T) return Location_T
   is (if L.Origin = 0 or else not T (L.Origin).Used
       then (Origin => 0, Offset => Advance (L.Offset, S, D))
       else (Origin => L.Origin, Offset => Sum (L.Offset, D)));

   ---------------------------------------------------------------------
   --  The train in the frame (EVC_Position against the SOLR, which
   --  every stored location is referred to)
   ---------------------------------------------------------------------

   type Train_Frame_T is record
      --  the position is valid and referred to a SOLR
      Valid      : Boolean := False;
      --  the train orientation: the sense of the front end
      Sense      : Sense_T := Plus;
      Est_Front  : Dist_T := 0;
      Min_Front  : Dist_T := 0;
      Max_Front  : Dist_T := 0;
      --  the min safe rear end, with the train length (3.6.1.7)
      Min_Rear   : Dist_T := 0;
      Length     : Length_T := 0;
      Speed      : Natural := 0;   -- estimated, cm/s
      Standstill : Boolean := True;
      --  the reference of the confidence interval, the SOLR: the frame
      --  position of its location reference and its location accuracy
      --  (3.6.4.1.3), for the trip location of 3.13.9.4.8.2
      Ref_X      : Dist_T := 0;
      Ref_Locacc : Length_T := 0;
   end record;

   --  A group message being evaluated: the origin of its distances (0:
   --  none could be allocated, its location based information cannot be
   --  kept), their sense, its number in the order of evaluation, and
   --  the time of the passage over its first balise
   type Message_T is record
      Origin   : EVC_Origins.Count_T := 0;
      Sense    : Sense_T := Plus;
      Msg      : Natural := 0;
      Start_Ms : Unsigned_64 := 0;
   end record;

   --  A speed of the language (V_ variables of 7.5: 5 km/h steps, the
   --  codes above 120 are spare or special and are taken as 600 km/h),
   --  in cm/s rounded down
   function V5_To_Cms (Code : Natural) return Natural is
     (Natural'Min (Code, 120) * 1_250 / 9)
     with Post => V5_To_Cms'Result <= 16_666;

   --  The location at Offset from the origin of message M
   function At_Offset (M : Message_T; Offset : Dist_T) return Location_T is
     ((Origin => M.Origin, Offset => Offset));

   --  X along S: the coordinate that grows in the sense S
   function A (S : Sense_T; X : Dist_T) return Dist_T renames Along;

   ---------------------------------------------------------------------
   --  Stored elements: what a store keeps of a group message, with the
   --  message it came with (the order of evaluation, 3.8.5.1.5)
   ---------------------------------------------------------------------

   --  Speeds (cm/s) and gradients (per mille) both fit
   subtype Value_T is Integer range -30_000 .. 30_000;

   type Stored_T is record
      Start  : Location_T;
      Finish : Location_T;
      --  no end: the last element of a continuous profile (3.6.3.2.2 d)
      Open   : Boolean := False;
      Value  : Value_T := 0;
      --  the rear end counts: the train length delay (Q_FRONT 0)
      Delay_Length : Boolean := False;
      --  the identity (NID_TSR, NID_LX), the type of track condition...
      Id     : Natural := 0;
      Msg    : Natural := 0;
      --  a time the store notes on the element (a track condition: its
      --  end passed by the min safe rear end, 5.18; a section of a speed
      --  restriction to ensure a permitted braking distance: its Value
      --  computed, 3.11.11.3)
      Noted    : Boolean := False;
      Noted_Ms : Unsigned_64 := 0;
      --  the order of a speed restriction to ensure a permitted braking
      --  distance (packet 52, 3.11.11.2): its gradient (per mille,
      --  signed) and whether the service brake is to achieve it
      --  (Q_PBDSR 1); the permitted braking distance is Id (cm)
      Gradient : Value_T := 0;
      Service  : Boolean := False;
   end record;

   Max_Stored : constant := 96;

   type Stored_Array is array (1 .. Max_Stored) of Stored_T;

   type Store_T is record
      --  the sense of the distances of the store: the train orientation
      --  when its information was received
      Sense : Sense_T := Plus;
      Count : Natural range 0 .. Max_Stored := 0;
      List  : Stored_Array;
      --  elements that found no room
      Lost  : Natural := 0;
   end record;

   Empty_Store : constant Store_T :=
     (Sense => Plus, Count => 0, List => (others => (others => <>)),
      Lost => 0);

   --  One more element at the end
   procedure Append (St : in out Store_T; E : Stored_T)
     with Post => St.Sense = St.Sense'Old
                  and then (if St.Count'Old < Max_Stored
                            then St.Count = St.Count'Old + 1
                            else St.Count = St.Count'Old);

   --  Element I out, those after it one place down
   procedure Remove (St : in out Store_T; I : Positive)
     with Pre => I <= St.Count,
          Post => St.Count = St.Count'Old - 1 and then St.Sense = St.Sense'Old;

   --  3.7.3.1, A.3.4.1.3: the elements of messages before Before_Msg
   --  are deleted from the frame position X on (along the sense of the
   --  store, "estimated" items): those starting at or beyond X go, those
   --  across X end at To (the location X stands for)
   procedure Cut_Beyond (St         : in out Store_T;
                         T          : Origin_Table_T;
                         X          : Dist_T;
                         To         : Location_T;
                         Before_Msg : Natural)
     with Post => St.Sense = St.Sense'Old and then St.Count <= St.Count'Old;

   --  The elements whose end (the "min" item, and the train length when
   --  the rear end counts) is more than Keep behind the frame position
   --  Rear are deleted (A.3.1: 300 m in rear of the min safe rear end)
   procedure Cut_Behind (St   : in out Store_T;
                         T    : Origin_Table_T;
                         Rear : Dist_T;
                         Keep : Length_T)
     with Post => St.Sense = St.Sense'Old and then St.Count <= St.Count'Old;

   --  3.7.2.3: the union of the elements covers From .. To (frame
   --  positions, "estimated" items, along the sense of the store)
   function Covers (St : Store_T; T : Origin_Table_T; From, To : Dist_T)
     return Boolean;

   --  Mark the origins the elements refer to
   type Origin_Marks_T is array (EVC_Origins.Index_T) of Boolean;

   procedure Mark (St : Store_T; Marks : in out Origin_Marks_T);

   procedure Mark (L : Location_T; Marks : in out Origin_Marks_T);

   ---------------------------------------------------------------------
   --  Elements and envelopes
   ---------------------------------------------------------------------

   --  The rear end of the axis: the first step starts there
   Axis_Start : constant Dist_T := -Max_Cm;

   Max_Elements : constant := 400;

   type Element_T is record
      Start  : Dist_T := 0;
      Finish : Dist_T := 0;
      Value  : Value_T := 0;
   end record;

   type Element_Array is array (1 .. Max_Elements) of Element_T;

   type Elements_T is record
      Count : Natural range 0 .. Max_Elements := 0;
      List  : Element_Array;
      --  elements that found no room
      Lost  : Natural := 0;
   end record;

   --  One more element [Start, Finish); an empty one is not kept
   procedure Add (E : in out Elements_T;
                  Start, Finish : Dist_T;
                  Value : Value_T)
     with Post => E.Count >= E.Count'Old
                  and then (for all I in 1 .. E.Count'Old =>
                              E.List (I) = E.List'Old (I));

   Max_Steps : constant := 256;

   type Step_T is record
      Start : Dist_T := Axis_Start;
      Value : Value_T := 0;
   end record;

   type Step_Array is array (1 .. Max_Steps) of Step_T;

   --  Step K holds from List (K).Start up to the start of step K + 1,
   --  the last one without end
   type Steps_T is record
      Count : Natural range 0 .. Max_Steps := 0;
      List  : Step_Array;
   end record;

   function Step_End (P : Steps_T; K : Positive) return Cm_T is
     (if K < P.Count then P.List (K + 1).Start else Max_Cm + 1)
     with Pre => K <= P.Count;

   --  Step K and element X share a position
   function Overlaps (P : Steps_T; K : Positive; X : Element_T)
     return Boolean
   is (P.List (K).Start < X.Finish and then X.Start < Step_End (P, K))
     with Pre => K <= P.Count;

   function Sorted (P : Steps_T) return Boolean is
     (P.Count >= 1
      and then P.List (1).Start = Axis_Start
      and then (for all K in 1 .. P.Count - 1 =>
                  P.List (K).Start < P.List (K + 1).Start));

   --  No step above an element it overlaps, all within Floor .. Ceiling
   function Below (P : Steps_T; E : Elements_T; Floor, Ceiling : Value_T)
     return Boolean
   is ((for all K in 1 .. P.Count =>
          P.List (K).Value in Floor .. Ceiling)
       and then
       (for all I in 1 .. E.Count =>
          (for all K in 1 .. P.Count =>
             (if Overlaps (P, K, E.List (I))
              then P.List (K).Value <= E.List (I).Value))));

   --  The value of P at the position X
   function Value_At (P : Steps_T; X : Dist_T) return Value_T
     with Pre => Sorted (P);

   --  The lowest value of P over [From, To] (From <= To), the value at
   --  From when To is before it
   function Lowest (P : Steps_T; From, To : Dist_T) return Value_T
     with Pre => Sorted (P);

   --  The envelope of E (see above): at every position the lowest value
   --  of the elements there, Default where there is none, at most
   --  Ceiling; at most Capacity steps
   --  An element below the Floor, which no caller gives (speeds are not
   --  negative, gradients not below -255), is first raised to it.
   procedure Envelope (E        : in out Elements_T;
                       Default  : Value_T;
                       Floor    : Value_T;
                       Ceiling  : Value_T;
                       Capacity : Positive;
                       P        : out Steps_T;
                       Checked  : out Boolean)
     with Pre => Capacity in 2 .. Max_Steps
                 and then Floor <= Ceiling
                 and then Floor <= Default,
          Post => E.Count = E.Count'Old
                  and then (for all I in 1 .. E.Count =>
                              E.List (I).Start = E.List'Old (I).Start
                              and then E.List (I).Finish
                                         = E.List'Old (I).Finish
                              and then E.List (I).Value
                                         = Value_T'Max
                                             (E.List'Old (I).Value, Floor))
                  and then Sorted (P)
                  and then P.Count <= Capacity
                  and then Below (P, E, Floor, Ceiling)
                  --  the check failed: the Floor everywhere
                  and then (if not Checked
                            then P.Count = 1
                                 and then P.List (1).Value = Floor);

end EVC_Profiles;
