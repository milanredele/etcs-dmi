--  ETCS on-board (EVC)
--  Reference balise groups, the train position against them, and the
--  location items with their relocation (SUBSET-026 3.6.1.3, 3.6.4).
--
--  The train position is kept in the odometer frame (EVC_Odometry): a
--  reference balise group (LRBG, SOLR, ORBG) is its identity plus the
--  frame position of its location reference and the confidence of the
--  frame when it was detected (an Anchor_T). The position of the train
--  against any reference is computed when it is needed:
--    estimated distance  along the train orientation, from the location
--                        reference to the antenna (or to the front end,
--                        the antenna offset added: 3.6.1.3.4);
--    Doubt_Over          Q_LOCACC of the reference plus the over-reading
--                        amount since its detection (3.6.4.1.5 a): the
--                        growth of the frame deviation on the rear side;
--    Doubt_Under         the same on the front side (3.6.4.1.5 b).
--  The detection error of the balise is in the odometer's amounts (the
--  odometer port, SUBSET-041 5.3.1.1 notes). The gamma term of 3.6.4.1.5
--  (consist lengths in SB without Train Data and in SM) is 0: phases E4
--  and E6.
--
--  Location items (3.6.4.2.3): location based information received from
--  the track is processed into items, each a signed distance along the
--  train orientation from its reference balise group, of the kind
--  "estimated", "min" or "max" (Table 2a). When a balise group becomes
--  the SOLR, or when information referred to another group is evaluated,
--  Relocate refers the item to the SOLR (3.6.4.2.5): by the linking
--  distance between the two groups when it is known (a), the same
--  widened by twice the location accuracy of the former reference when
--  the item was last relocated by c) towards a group not received
--  earlier than its reference (b), and otherwise by the travelled
--  distance between the two groups as the estimated, min or max front
--  end positions measure it (c). The item keeps a copy of its
--  reference's anchor, so that c) needs no store of former references.

with EVC_Balise_Groups; use EVC_Balise_Groups;
with EVC_Distances;     use EVC_Distances;

package EVC_Location
  with SPARK_Mode => On
is

   --  A reference balise group
   type Anchor_T is record
      Valid       : Boolean := False;
      Id          : Identity_T;
      --  the frame position of its location reference, and the frame
      --  deviations accumulated when it was detected
      X           : Dist_T := 0;
      Low, High   : Length_T := 0;
      --  3.6.4.1.3: its location accuracy, fixed once determined
      Locacc      : Length_T := 0;
      --  the sense of its nominal direction; Unknown: no co-ordinate
      --  system (a single balise group, 3.4.2.3)
      Orientation : Direction_T := Unknown;
      --  the sense in which the train passed it
      Crossing    : Direction_T := Unknown;
      Linked      : Boolean := False;
      --  the order in which the groups were received
      Seq         : Natural := 0;
   end record;

   --  The deviation of the frame on the side behind (Rear) or ahead of
   --  (Front) the sense S, accumulated since the anchor
   function Rear_Growth (A : Anchor_T; S : Sense_T; Low, High : Length_T)
     return Length_T
   is (if S = Plus then Growth (Low, A.Low) else Growth (High, A.High));

   function Front_Growth (A : Anchor_T; S : Sense_T; Low, High : Length_T)
     return Length_T
   is (if S = Plus then Growth (High, A.High) else Growth (Low, A.Low));

   --  3.6.4.1.5 a) and b) (gamma = 0), as distances from the estimated
   --  position
   function Doubt_Over (A : Anchor_T; S : Sense_T; Low, High : Length_T)
     return Length_T
   is (Add (A.Locacc, Rear_Growth (A, S, Low, High)));

   function Doubt_Under (A : Anchor_T; S : Sense_T; Low, High : Length_T)
     return Length_T
   is (Add (A.Locacc, Front_Growth (A, S, Low, High)));

   --  The estimated distance along S from the location reference to the
   --  frame position X
   function Estimated (A : Anchor_T; S : Sense_T; X : Dist_T) return Dist_T
   is (Between (S, A.X, X));

   --  Min and max safe positions around an estimated one
   function Min_Safe (Est : Dist_T; Over : Length_T) return Dist_T is
     (Diff (Est, Over))
     with Post => Min_Safe'Result <= Est;

   function Max_Safe (Est : Dist_T; Under : Length_T) return Dist_T is
     (Sum (Est, Under))
     with Post => Max_Safe'Result >= Est;

   ---------------------------------------------------------------------
   --  Location items
   ---------------------------------------------------------------------

   type Item_Kind_T is (Estimated_Item, Min_Item, Max_Item);

   type Item_T is record
      Valid  : Boolean := False;
      Kind   : Item_Kind_T := Estimated_Item;
      Ref    : Anchor_T;
      --  distances run along Sense (the train orientation when the
      --  information was received)
      Sense  : Sense_T := Plus;
      D      : Dist_T := 0;
      --  the last relocation was by 3.6.4.2.5 c), and towards a group
      --  not received earlier than the reference of the item
      Last_C       : Boolean := False;
      Last_C_Later : Boolean := False;
   end record;

   --  3.6.4.2.5: refer Item to To (the SOLR). Linked says whether the
   --  linking distance Link from the item's reference to To is known;
   --  Low, High are the frame deviations now.
   procedure Relocate (Item   : in out Item_T;
                       To     : Anchor_T;
                       Linked : Boolean;
                       Link   : Dist_T;
                       Low    : Length_T;
                       High   : Length_T)
     with Post => Item.Ref = To
                  and then Item.Kind = Item.Kind'Old
                  and then Item.Sense = Item.Sense'Old
                  and then Item.Valid = Item.Valid'Old;

end EVC_Location;
