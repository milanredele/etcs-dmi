--  ETCS on-board (EVC)
--  the balise side of the transition buffer
--  of 4.8.5. The packets of a balise group judged "stored" by 4.8.3 [1]
--  (level 1 information read in level 0 or 2 with a transition to level
--  1 announced, EVC_Acceptance.Stored) are kept here, one set per group
--  (4.8.5.2.1: the part of the message being stored), three sets at
--  most, the oldest replaced by a fourth (4.8.5.3). The packets are
--  copied bit for bit, each from a byte boundary of its set; a packet
--  that does not fit any more is not kept (Add_Packet). The parent
--  judges, deletes (4.8.5.4 a) and releases (4.8.5.5, 4.8.5.6) the
--  sets. Part of EVC_Stored_Information.State: package state, written
--  and read in place (no set by value).

with ETCS_Bits;
with ETCS_Catalogue;
with EVC_Balise_Groups;
with EVC_Origins;

--  @req 4.8.3.1.1 Table, 4.8.3.1.1 Table-footnote [1], 4.8.5.1, 4.8.5.4 a)
--  @req 4.8.5.5, 5.10.1.7
private package EVC_Stored_Information.Balise_Buffer
  with SPARK_Mode => On,
       Abstract_State => (State with Part_Of => EVC_Stored_Information.State),
       Initializes => State
is

   Max_Sets        : constant := 3;
   --  the bytes of the packets of one set (about one group's
   --  telegrams), the packets of one set
   Set_Bytes       : constant := 1024;
   Max_Set_Packets : constant := 32;

   --  What a group message brings besides its packets: the origin of its
   --  distances, their sense, the time of the group, and the context of
   --  4.8.3 [11] and [16]
   type Set_Info_T is record
      Origin   : EVC_Origins.Count_T := 0;
      Sense    : Sense_T := Plus;
      Start_Ms : Unsigned_64 := 0;
      Linked   : Boolean := False;
      Has_41   : Boolean := False;
      Count    : Natural range 0 .. Max_Set_Packets := 0;
      --  the group, the reference of a linking
      --  (packet 5) kept in the set
      Group    : EVC_Balise_Groups.Identity_T := (others => <>);
   end record;

   function Count return Natural
     with Global => State,
          Post => Count'Result <= Max_Sets;

   function Info (S : Positive) return Set_Info_T
     with Global => State,
          Pre => S <= Count;

   function Kind (S, P : Positive) return ETCS_Catalogue.Packet_Kind_T
     with Global => State,
          Pre => S <= Count and then P <= Info (S).Count;

   --  The state of the start (EVC_Stored_Information.Clear)
   procedure Clear
     with Global => (Output => State),
          Post => Count = 0;

   --  4.8.5.4: every set deleted
   procedure Delete_All
     with Global => (In_Out => State),
          Post => Count = 0;

   --  4.8.5.1, 4.8.5.3: a new, empty set for a group, the oldest set
   --  deleted when three are kept
   --  @req 4.8.5.3
   procedure New_Set (I : Set_Info_T)
     with Global => (In_Out => State),
          Pre => I.Count = 0,
          Post => Count >= 1;

   --  The packet R holds from its position to its limit, of kind K,
   --  appended to the last set (nothing when it does not fit)
   procedure Add_Packet (K : ETCS_Catalogue.Packet_Kind_T;
                         R : in out ETCS_Bits.Reader)
     with Global => (In_Out => State),
          Post => Count = Count'Old;

   --  the group of the last set
   procedure Set_Group (Id : EVC_Balise_Groups.Identity_T)
     with Global => (In_Out => State),
          Post => Count = Count'Old;

   --  Packet P of set S in R (as ETCS_Telegram.Open_Packet)
   procedure Open (S, P : Positive; R : in out ETCS_Bits.Reader)
     with Global => State,
          Pre => S <= Count and then P <= Info (S).Count;

end EVC_Stored_Information.Balise_Buffer;
