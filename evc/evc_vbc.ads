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
--    - the store holds VBC_Max covers, the DMI's list length
--      (DMI_Protocol.VBC_List_Max), set by the driver or by trackside
--      alike; a new identity when the store is full is ignored, and the
--      DMI's Set VBC is disabled then (national bit 2, Full);
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

   VBC_Max : constant := 16;

   --  One cover: its identity, T_VBC as it was given (for the DMI's set
   --  code) and the time of its period left, in ms
   type Cover_T is record
      Used   : Boolean := False;
      NID_C  : NID_C_T := 0;
      Marker : NID_VBCMK_T := 0;
      T_VBC  : T_VBC_T := 0;
      Left   : Unsigned_64 := 0;
   end record;

   type Cover_List_T is array (1 .. VBC_Max) of Cover_T;

   --  What is kept over No Power (EVC_Retained)
   type Kept_T is record
      Covers : Cover_List_T := (others => (others => <>));
   end record;

   --  T_VBC in ms (24 hours a step)
   Day_Ms : constant := 24 * 3_600_000;

   function Count return Natural
     with Global => State,
          Post => Count'Result <= VBC_Max;

   --  No room for a new identity
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

   --  @req 3.15.9.4, 3.15.9.6
   procedure Set (NID_C : NID_C_T; Marker : NID_VBCMK_T; T : T_VBC_T)
     with Global => (In_Out => State);

   --  @req 3.15.9.5 a), 3.15.9.5 c)
   procedure Remove (NID_C : NID_C_T; Marker : NID_VBCMK_T)
     with Global => (In_Out => State),
          Post => not Covers (NID_C, Marker);

   --  The clock of the cycle: the periods count down from the last call
   --  @req 3.15.9.5 b)
   procedure Expire (Now_Ms : Unsigned_64)
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
