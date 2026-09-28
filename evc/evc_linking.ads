--  ETCS on-board (EVC)
--  Linking information stored on-board (SUBSET-026 3.4.4, 3.6.3.2.6).
--
--  Packet 5 (7.4.2.2) announces the balise groups the train will pass,
--  from the balise group that sent it (the reference of the linking,
--  index 0 below) on: for each, the incremental distance (3.6.3.2.6 a,
--  b), the identity (or "unknown" with repositioning, 3.4.4.2.2), the
--  direction in which it will be passed (Q_LINKORIENTATION), the reaction
--  in case of a data consistency problem (Q_LINKREACTION, 3.4.4.2.3) and
--  the accuracy of its location (Q_LOCACC). From_Packet turns it into a
--  chain of cumulative distances from the reference, in cm, along the
--  sense of the frame in which the distances run (the train orientation
--  the packet was valid for, EVC_Position).
--
--  The store is bounded by the packet: the first group plus N_ITER (5
--  bits) of them. Expected is the group whose expectation window is
--  supervised (3.4.4.4.5); Solr the last group of the chain that became
--  the Single On-board Location Reference (0: the reference itself).

with EVC_Balise_Groups; use EVC_Balise_Groups;
with EVC_Distances;     use EVC_Distances;
with ETCS_Track_Packets.P5;
with ETCS_Variables;    use ETCS_Variables;

package EVC_Linking
  with SPARK_Mode => On
is

   Max_Links : constant := 32;

   subtype Link_Count_T is Natural range 0 .. Max_Links;
   subtype Link_Index_T is Positive range 1 .. Max_Links;

   type Link_T is record
      Known_Id : Boolean := False;       -- else "unknown", repositioning
      Id       : Identity_T;
      D        : Length_T := 0;          -- from the reference, cumulated
      Nominal  : Boolean := True;        -- passed in its nominal direction
      Reaction : Q_LINKREACTION_T := 2;  -- no reaction
      Locacc   : Length_T := 0;
   end record;

   type Links_T is array (Link_Index_T) of Link_T;

   type Linking_T is record
      Stored   : Boolean := False;
      Ref_Id   : Identity_T;
      Sense    : Sense_T := Plus;
      Count    : Link_Count_T := 0;
      Links    : Links_T;
      Expected : Positive range 1 .. Max_Links + 1 := 1;
      Solr     : Link_Count_T := 0;
   end record;

   --  The largest cumulated distance: 32 links of 32767 * 10 m
   Max_Chain_Cm : constant := Max_Links * 32_767 * 1000;

   --  "Linking consistency is checked" (3.4.4.2.1.1 a and c): linking is
   --  stored and the window of the furthest announced group is still to
   --  be supervised. Its b), the modes, is phase E4.
   function Checked (L : Linking_T) return Boolean is
     (L.Stored and then L.Expected <= L.Count);

   --  The cumulated distance of link I, 0 for the reference
   function Distance (L : Linking_T; I : Link_Count_T) return Length_T is
     (if I = 0 then 0 else L.Links (I).D);

   --  The index of the first link from From on with this identity; 0
   --  when there is none
   function Find (L : Linking_T; Id : Identity_T; From : Positive)
     return Link_Count_T
     with Post => Find'Result = 0
                  or else (Find'Result >= From
                           and then Find'Result <= L.Count);

   --  A link to an unknown group (repositioning) after link I up to link
   --  J: then the distance between I and J is not known (3.6.4.2.5 a)
   function Repositioning_Between (L : Linking_T; I, J : Link_Count_T)
     return Boolean
   is (for some K in I + 1 .. J =>
         K <= L.Count and then not L.Links (K).Known_Id);

   --  The chain of packet P, sent by a group of country NID_C, running
   --  along Sense. OK is False when the packet cannot be used (Q_SCALE
   --  or Q_LINKREACTION spare).
   procedure From_Packet (P      : ETCS_Track_Packets.P5.Packet_T;
                          Sender : Identity_T;
                          Sense  : Sense_T;
                          L      : out Linking_T;
                          OK     : out Boolean)
     with Post => (if OK then L.Stored and then L.Count >= 1
                              and then L.Solr = 0
                              and then L.Expected = 1
                              and then L.Ref_Id = Sender);

end EVC_Linking;
