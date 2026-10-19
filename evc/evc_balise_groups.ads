--  ETCS on-board (EVC)
--  One passage over a balise group, and what the on-board derives from
--  the telegrams of that passage (SUBSET-026 3.4.1, 3.4.2).
--
--  A balise group has one to eight balises sharing the group identity
--  (3.4.1.1); each telegram gives the position of its balise in the
--  group (N_PIG, 0 for the first), the number of balises (N_TOTAL, 0 for
--  one) and whether it duplicates a neighbour (M_DUP, 7.5.1.63). The
--  passage collects the telegrams of one group as they arrive with the
--  frame position of their balise (EVC_Odometry.To_Frame of the stamp),
--  at most one per balise. EVC_Position opens, fills and closes it.
--
--  Geometry of a closed passage:
--    - the location reference (3.4.2.2.1): balise 1 (N_PIG 0); when it
--      was not read and balise 2 duplicates it (M_DUP "duplicate of the
--      previous"), balise 2 (3.4.2.2.1.1); otherwise the group has no
--      location reference the on-board can use;
--    - the orientation (3.4.2.2.2): the nominal direction is that of
--      increasing balise numbers, so two balises of different numbers
--      read at different frame positions give the sense of the frame in
--      which the group's nominal direction points. With one balise read
--      (a single balise group, 3.4.2.3, or one of a pair of duplicated
--      balises, 3.4.2.4.1) the group has no orientation of its own:
--      linking (3.4.2.3.2.2) or the RBC (3.4.2.3.3) may assign one;
--    - the crossing direction (3.6.3.1.3.1): the sense in which the
--      train passed it, from the order of the balises or, with one
--      balise, from the movement of the odometer at its detection.
--
--  The telegrams themselves are kept for the evaluation of the message
--  at the end of the passage (packets 5, 16, 79 in phase E2).

with EVC_Distances;  use EVC_Distances;
with ETCS_Telegram;
with ETCS_Variables; use ETCS_Variables;
with Interfaces;     use Interfaces;

package EVC_Balise_Groups
  with SPARK_Mode => On
is

   Max_Balises : constant := 8;

   type Identity_T is record
      NID_C  : NID_C_T := 0;
      NID_BG : NID_BG_T := 0;
   end record;

   --  NID_BG 16383: the identity is unknown (7.5.1.86)
   Unknown_Identity : constant Identity_T := (NID_C => 0, NID_BG => 16383);

   --  The 24 bits of the identity, as the JRU records it
   function Code (Id : Identity_T) return Unsigned_64 is
     (Balise_Group_Identity (Id.NID_C, Id.NID_BG));

   function Identity (H : ETCS_Telegram.Header_T) return Identity_T is
     ((NID_C => H.NID_C, NID_BG => H.NID_BG));

   --  One balise read: its place in the group, its frame position and
   --  the confidence of the frame at its detection
   type Reading_T is record
      N_PIG  : N_PIG_T := 0;
      M_DUP  : M_DUP_T := 0;
      X      : Dist_T := 0;
      Low    : Length_T := 0;
      High   : Length_T := 0;
      --  the last known direction of movement at its detection
      Motion : Direction_T := Unknown;
      --  its telegram compliant with the specifications (3.16.1.1): the
      --  codec accepted it; False when only its header could be read
      Decoded : Boolean := True;
   end record;

   subtype Count_T is Natural range 0 .. Max_Balises;
   subtype Slot_T is Positive range 1 .. Max_Balises;
   type Readings_T is array (Slot_T) of Reading_T;
   type Telegrams_T is array (Slot_T) of ETCS_Telegram.Telegram_T;
   No_Reading : constant Reading_T := (others => <>);

   --  (every component has a default expression, the arrays a named
   --  element: (others => <>) of the type is built in place, not in a
   --  temporary on the stack and copied)
   type Passage_T is record
      Open      : Boolean := False;
      Id        : Identity_T := (others => <>);
      N_TOTAL   : N_TOTAL_T := 0;
      Linked    : Boolean := False;   -- Q_LINK
      Count     : Count_T := 0;
      Readings  : Readings_T := (others => No_Reading);
      Telegrams : Telegrams_T := (others => ETCS_Telegram.No_Telegram);
   end record;

   --  A balise of this number was read in the passage
   function Has (P : Passage_T; N_PIG : N_PIG_T) return Boolean is
     (for some I in 1 .. P.Count => P.Readings (I).N_PIG = N_PIG);

   --  Every balise of the group was read
   function Complete (P : Passage_T) return Boolean is
     (P.Count > Natural (P.N_TOTAL));

   --  3.16.2.4.2, 3.16.2.4.4.1 a): balise N, missed, is duplicated by a
   --  neighbour read and decoded (M_DUP, 7.5.1.63: 1 the duplicate of
   --  the next balise, 2 of the previous one). Decision: the content
   --  bullets of 3.16.2.4.4.1 a) are not told apart; a duplicate left
   --  alone has no orientation of its own, which linking may assign
   --  (3.4.2.3.2.2)
   function Duplicated (P : Passage_T; N : N_PIG_T) return Boolean is
     ((N < N_PIG_T'Last
       and then (for some I in 1 .. P.Count =>
                   P.Readings (I).N_PIG = N + 1
                   and then P.Readings (I).Decoded
                   and then P.Readings (I).M_DUP = 2))
      or else
        (N > 0
         and then (for some I in 1 .. P.Count =>
                     P.Readings (I).N_PIG = N - 1
                     and then P.Readings (I).Decoded
                     and then P.Readings (I).M_DUP = 1)));

   --  The telegram holds packet 254, "default balise information"
   --  (3.16.2.4.8, 7.4.2.40)
   function Has_Default (T : ETCS_Telegram.Telegram_T) return Boolean is
     (for some K in 1 .. T.Count => T.Index (K).NID = 254);

   --  3.4.2.3.2, 7.5.1.63: the balises of slots I and J are a duplicated
   --  pair: neighbours, the M_DUP of either naming the other
   function Paired (P : Passage_T; I, J : Slot_T) return Boolean is
     (I <= P.Count and then J <= P.Count
      and then
        ((P.Readings (I).M_DUP = 1
          and then Natural (P.Readings (J).N_PIG)
                   = Natural (P.Readings (I).N_PIG) + 1)
         or else (P.Readings (I).M_DUP = 2
                  and then Natural (P.Readings (J).N_PIG) + 1
                           = Natural (P.Readings (I).N_PIG))
         or else (P.Readings (J).M_DUP = 1
                  and then Natural (P.Readings (I).N_PIG)
                           = Natural (P.Readings (J).N_PIG) + 1)
         or else (P.Readings (J).M_DUP = 2
                  and then Natural (P.Readings (I).N_PIG) + 1
                           = Natural (P.Readings (J).N_PIG))));

   --  3.16.2.4.7.1: the counter of the telegram of slot I is left out
   --  of the comparison: its duplicate (M_DUP) was read and decoded
   --  after it (its packets are left out by Add, 3.16.2.4.8.2)
   function Superseded (P : Passage_T; I : Slot_T) return Boolean is
     (I <= P.Count
      and then P.Readings (I).M_DUP in 1 .. 2
      and then (for some J in I + 1 .. P.Count =>
                  P.Readings (J).Decoded
                  and then
                    (if P.Readings (I).M_DUP = 1
                     then Natural (P.Readings (J).N_PIG)
                          = Natural (P.Readings (I).N_PIG) + 1
                     else Natural (P.Readings (J).N_PIG) + 1
                          = Natural (P.Readings (I).N_PIG))));

   --  3.16.2.4.7: the message counter of slot I takes part in the
   --  comparison: decoded, used, not "fits all" (255, 3.16.2.4.6)
   function Counted (P : Passage_T; I : Slot_T) return Boolean is
     (I <= P.Count
      and then P.Readings (I).Decoded
      and then not Superseded (P, I)
      and then P.Telegrams (I).Header.M_MCOUNT /= 255);

   --  3.16.2.4.7, 3.16.2.4.7.1: the counters compared are all identical
   --  and none is "never fits" (254, 3.16.2.4.6.1)
   --  @req 3.16.2.5.1 d)
   function Counters_Match (P : Passage_T) return Boolean is
     (for all I in 1 .. P.Count =>
        (if Counted (P, I)
         then P.Telegrams (I).Header.M_MCOUNT /= 254
              and then (for all J in 1 .. P.Count =>
                          (if Counted (P, J)
                           then P.Telegrams (J).Header.M_MCOUNT
                                = P.Telegrams (I).Header.M_MCOUNT))));

   --  3.16.2.4.1 a), 3.16.2.5.1 a): the balises were read in the order
   --  of their numbers, increasing or decreasing (3.4.2.3.2). Decision:
   --  a balise read after one numbered beyond it in the direction of
   --  the passage (0, 2, 1) was missed at its place, the message is
   --  inconsistent
   --  @req 3.16.2.5.1 a)
   function In_Order (P : Passage_T) return Boolean is
     ((for all I in 2 .. P.Count =>
         P.Readings (I).N_PIG > P.Readings (I - 1).N_PIG)
      or else (for all I in 2 .. P.Count =>
                 P.Readings (I).N_PIG < P.Readings (I - 1).N_PIG));

   --  3.16.1.1, 3.16.2.4.1 a), b), d), 3.16.2.4.2: the message of the
   --  passage is consistent: every telegram read is compliant, every
   --  balise of the group read or duplicated by one read, the message
   --  counters matching. Decision: the BTM port carries the telegrams
   --  the BTM decoded only (EVC_Ports), so a balise detected without a
   --  decoded telegram (b) reaches the on-board as a missed one (a); a
   --  telegram the codec refuses is not compliant (3.16.1.1), without
   --  the exception for duplicates of a) and b)
   function Consistent (P : Passage_T) return Boolean is
     ((for all I in 1 .. P.Count => P.Readings (I).Decoded)
      and then In_Order (P)
      and then (for all K in 0 .. Natural (P.N_TOTAL) =>
                  Has (P, N_PIG_T (K)) or else Duplicated (P, N_PIG_T (K)))
      and then Counters_Match (P));

   --  3.16.2.4.4.1 b), 3.16.2.5.1.1 b): a telegram correctly read in the
   --  passage holds packet 145, "Inhibition of balise group message
   --  consistency reaction" (7.4.2.42); its direction is not looked at
   --  @req 3.16.2.5.1.1 b)
   function Reaction_Inhibited (P : Passage_T) return Boolean is
     (for some I in 1 .. P.Count =>
        P.Readings (I).Decoded
        and then (for some K in 1 .. P.Telegrams (I).Count =>
                    P.Telegrams (I).Index (K).NID = 145));

   --  A new passage, with its first telegram
   procedure Start (P : out Passage_T;
                    T : ETCS_Telegram.Telegram_T;
                    R : Reading_T)
     with Post => P.Open
                  and then P.Count = 1
                  and then P.Id = Identity (T.Header);

   --  One more telegram of the same group, of a balise not yet read.
   --  Of a duplicated pair both decoded, the telegram not used to
   --  compose the message keeps its header and loses its packets: the
   --  one with default balise information when only one has it, else
   --  the first received (3.16.2.4.8.1, 3.16.2.4.8.2)
   --  @req 3.16.2.4.8.1, 3.16.2.4.8.2
   procedure Add (P : in out Passage_T;
                  T : ETCS_Telegram.Telegram_T;
                  R : Reading_T)
     with Pre => P.Open and then P.Count < Max_Balises,
          Post => P.Open
                  and then P.Count = P.Count'Old + 1
                  and then P.Id = P.Id'Old;

   type Geometry_T is record
      Has_Reference       : Boolean := False;
      Reference           : Reading_T := (others => <>);
      --  balise 2 stands for the duplicated balise 1 (3.4.2.2.1.1)
      Duplicate_Reference : Boolean := False;
      --  the sense of the nominal direction; Unknown when the group
      --  gives none itself (single balise group, 3.4.2.3)
      Orientation         : Direction_T := Unknown;
      Crossing            : Direction_T := Unknown;
      --  the frame position of the last balise read
      Last_X              : Dist_T := 0;
   end record;

   --  @req 3.4.2.2.1.1, 3.4.2.4.1
   function Geometry (P : Passage_T) return Geometry_T
     with Pre => P.Count >= 1;

end EVC_Balise_Groups;
