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

   --  A new passage, with its first telegram
   procedure Start (P : out Passage_T;
                    T : ETCS_Telegram.Telegram_T;
                    R : Reading_T)
     with Post => P.Open
                  and then P.Count = 1
                  and then P.Id = Identity (T.Header);

   --  One more telegram of the same group, of a balise not yet read
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

   function Geometry (P : Passage_T) return Geometry_T
     with Pre => P.Count >= 1;

end EVC_Balise_Groups;
