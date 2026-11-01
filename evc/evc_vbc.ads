--  ETCS on-board (EVC)
--  The Virtual Balise Covers stored on-board, SUBSET-026 3.15.9: a VBC
--  is the pair of a marker (NID_VBCMK) and a country or region (NID_C),
--  its identity, with a validity period (T_VBC, 7.5.1.154.1: days). It
--  is set and removed by the driver during the start of mission (DMI
--  11.3.12, 11.3.13) and by trackside (packet 6, 7.4.2.2.1, balise
--  only); while it is stored, a balise telegram carrying its marker
--  (packet 0 after the header, 8.4.2.3, or packet 200 of system version
--  1.1, 6.5.1.5.21) and its country is not received (Covered).
--
--  Decisions:
--    - the store holds Driver_Max covers set by the driver and, apart,
--      Trackside_Max ordered by trackside (SUBSET-040 4.5.1.2, 4.3.2.1
--      w)), so that the driver can always set 20 whatever trackside
--      ordered; a new identity when its room is full is ignored, no
--      cover is replaced for it (the deletions of 3.15.9.5 are a closed
--      list), and the DMI's Set VBC is disabled while the driver's room
--      is full (national bit 2, Full);
--    - 3.15.9.4: a VBC of a stored identity replaces the stored one in
--      its room, whoever gave it: a VBC is its identity and its period
--      (3.15.9.1), the room is the store's, so the counts never pass
--      their rooms;
--    - 3.15.9.6: the period runs on the on-board's clock while it is
--      powered: the time left is what is kept over No Power, so that
--      time without power does not count (the on-board has no clock
--      that runs without power);
--    - T_VBC = 0 is a period of zero length: the cover is deleted at the
--      next Expire.

with Interfaces;     use Interfaces;
with EVC_Bytes;
with ETCS_Variables; use ETCS_Variables;

package EVC_VBC
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  The room a cover takes: set by the driver (Set) or ordered by
   --  trackside (Order)
   type Origin_T is (Driver, Trackside);

   --  The covers set by the driver the store holds: SUBSET-040 4.5.1.2
   --  ("at least 20 VBCs set by the driver", SUBSET-026 3.15.9.2)
   --  @req 3.15.9.2
   Driver_Max    : constant := 20;
   --  The covers ordered by trackside it holds besides: SUBSET-040
   --  4.3.2.1 w) (10 memorised, not including the driver's 20; packet 6,
   --  SUBSET-026 7.4.2.2.1)
   --  @req 7.4.2.2.1
   Trackside_Max : constant := 10;
   VBC_Max       : constant := Driver_Max + Trackside_Max;

   --  One cover: its identity, T_VBC as it was given (for the DMI's set
   --  code), the time of its period left with power on, in ms, the end
   --  of its period on the calendar clock, UTC seconds since 2000-01-01
   --  (0: the clock was unknown at its set), and the room it takes
   type Cover_T is record
      Used    : Boolean := False;
      NID_C   : NID_C_T := 0;
      Marker  : NID_VBCMK_T := 0;
      T_VBC   : T_VBC_T := 0;
      Left    : Unsigned_64 := 0;
      End_UTC : Unsigned_64 := 0;
      Origin  : Origin_T := Driver;
   end record;

   type Cover_List_T is array (1 .. VBC_Max) of Cover_T;

   --  What is kept over No Power (EVC_Retained)
   type Kept_T is record
      Covers : Cover_List_T := (others => (others => <>));
   end record;

   --  T_VBC in ms and in s (24 hours a step)
   Day_Ms : constant := 24 * 3_600_000;
   Day_S  : constant := 24 * 3_600;

   --  The covers stored, of both rooms (the DMI's list)
   function Count return Natural
     with Global => State,
          Post => Count'Result <= VBC_Max;

   --  The covers stored in the room of Origin
   function Count_Of (Origin : Origin_T) return Natural
     with Global => State,
          Post => Count_Of'Result <= VBC_Max;

   --  No room for a new identity set by the driver (the DMI's Set VBC
   --  disabled, DMI 11.2.4.5.1: "the maximum on-board storage capacity
   --  of VBC set by driver"): the driver's count alone
   function Full return Boolean
     with Global => State;

   --  Cover I of Count, in the order of the store
   function Item (I : Positive) return Cover_T
     with Global => State,
          Pre => I <= Count;

   --  A VBC of this identity is stored
   function Covers (NID_C : NID_C_T; Marker : NID_VBCMK_T) return Boolean
     with Global => State;

   --  The set code of a cover, as DMI 11.3.12.5 composes it
   function Code (C : Cover_T) return Unsigned_32 is
     (Unsigned_32 (C.Marker)
      or Shift_Left (Unsigned_32 (C.NID_C), 6)
      or Shift_Left (Unsigned_32 (C.T_VBC), 16));

   --  The store changed since Mark_Sent (the DMI's list to send)
   function List_Due return Boolean
     with Global => State;

   procedure Mark_Sent
     with Global => (In_Out => State),
          Post => not List_Due;

   --  The empty store of a new on-board
   procedure Clear
     with Global => (Output => State);

   --  The driver's Set VBC: a new identity taken while the driver's room
   --  is not full, else ignored (the DMI's Set VBC is disabled then)
   --  @req 3.15.9.4, 3.15.9.6
   procedure Set (NID_C : NID_C_T; Marker : NID_VBCMK_T; T : T_VBC_T)
     with Global => (In_Out => State);

   --  Trackside's order to set a VBC (packet 6, Q_VBCO 1): a new identity
   --  taken while trackside's room is not full, else ignored. Decision:
   --  an ignored order has no record of its own. SUBSET-040 4.3.2.1 w)
   --  bounds trackside's covers to 10, so a full room is an engineering
   --  error of the trackside; SUBSET-027 records the driver's covers
   --  (4.2.4.28, .29) and no trackside one, and the order stays on the
   --  JRU in its balise telegram (4.2.4.6); the driver's list of the
   --  covers stored simply does not hold it
   --  @req 3.15.9.4, 3.15.9.6
   procedure Order (NID_C : NID_C_T; Marker : NID_VBCMK_T; T : T_VBC_T)
     with Global => (In_Out => State);

   --  @req 3.15.9.5 a), 3.15.9.5 c)
   procedure Remove (NID_C : NID_C_T; Marker : NID_VBCMK_T)
     with Global => (In_Out => State),
          Post => not Covers (NID_C, Marker);

   --  The clock of the cycle: the on-board time Now_Ms and, when the
   --  calendar clock reports, the UTC now in seconds since 2000-01-01.
   --  The periods count down from the last call; a cover whose end is
   --  known is deleted once the clock is past it, else when its time
   --  left with power on is over. A cover set from this call on takes
   --  its end from this clock.
   --  Decision (3.15.9.5 b), 3.18.5.1): the validity period is calendar
   --  time, so the time without power counts when the clock reports at
   --  the power-up; the time left with power on is the fallback for a
   --  cover set without the clock and for a clock that reports nothing.
   --  @req 3.15.9.5 b)
   procedure Expire (Now_Ms    : Unsigned_64;
                     UTC_Known : Boolean := False;
                     UTC_Now   : Unsigned_64 := 0)
     with Global => (In_Out => State);

   --  A consistent balise group message of country NID_C: the covers of
   --  another country are deleted
   --  @req 3.15.9.5 d)
   procedure Check_Country (NID_C : NID_C_T)
     with Global => (In_Out => State);

   --  The telegram part of a BTM input (EVC_Ports.Valid_BTM: its bit
   --  count, then its bits) carries the marker and the country of a
   --  stored VBC
   --  @req 3.15.9.3, 3.15.9.3 a), 3.15.9.3.1
   function Covered (Telegram : EVC_Bytes.Byte_Array) return Boolean
     with Global => State;

   --  The store over No Power (3.15.9.5: retained and applicable again)
   procedure Keep (K : out Kept_T)
     with Global => State;
   --  @req 3.15.9.5
   procedure Restore (K : Kept_T)
     with Global => (Output => State);

end EVC_VBC;
