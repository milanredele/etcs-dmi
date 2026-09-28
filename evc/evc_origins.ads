--  ETCS on-board (EVC)
--  The origins of the stored location based information (SUBSET-026
--  3.6.4.2.3 to 3.6.4.2.5).
--
--  The location based information a balise group gives is processed
--  into location items referred to that group (3.6.4.2.3). The stored
--  information of phase E3 keeps its distances as offsets from one
--  origin per group message: the location reference of the group as
--  three location items at distance 0 along the sense of the distances,
--  one of each kind of Table 2a ("estimated", "min", "max"). Every
--  distance of the message is the same offset from the three items, and
--  its "min" and "max" locations are those of the "min" and "max" items
--  moved by the offset: the items of one message share their reference
--  and their history of relocation, so relocating the origin relocates
--  all of them (3.6.4.2.4.3).
--
--  The origins are allocated by EVC_Position when it takes a balise
--  group into account, and relocated by it, with its own location
--  items, at the moment a group becomes the SOLR (3.6.4.2.5). The stored
--  information releases those it no longer refers to. This package is
--  only the store: a bounded table, no relocation logic.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Distances; use EVC_Distances;
with EVC_Location;  use EVC_Location;

package EVC_Origins
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  An engineering constant: the group messages whose information is
   --  stored at the same time (the information behind the train is
   --  deleted 300 m in rear of it, A.3.1, and releases its origin)
   Max_Origins : constant := 32;

   subtype Count_T is Natural range 0 .. Max_Origins;
   subtype Index_T is Count_T range 1 .. Max_Origins;

   type Origin_T is record
      Used : Boolean := False;
      Est  : Item_T;
      Min  : Item_T;
      Max  : Item_T;
   end record;

   function Get (I : Index_T) return Origin_T
     with Global => State;

   --  Origins in use
   function Used_Count return Count_T
     with Global => State;

   --  Allocations refused because the table was full, since Clear
   function Refused return Natural
     with Global => State;

   --  Power-up: no origin
   procedure Clear
     with Global => (Output => State),
          Post => (for all I in Index_T => not Get (I).Used);

   --  A new origin: the location reference of Ref, distances along S.
   --  I is 0 when the table is full.
   procedure Allocate (Ref : Anchor_T; S : Sense_T; I : out Count_T)
     with Global => (In_Out => State),
          Post => (if I /= 0
                   then Get (I).Used
                        and then Get (I).Est.Ref = Ref
                        and then Get (I).Est.Sense = S);

   --  Replace origin I (EVC_Position, after a relocation)
   procedure Put (I : Index_T; O : Origin_T)
     with Global => (In_Out => State),
          Post => Get (I) = O;

   procedure Release (I : Index_T)
     with Global => (In_Out => State),
          Post => not Get (I).Used;

end EVC_Origins;
