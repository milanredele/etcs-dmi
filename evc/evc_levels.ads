--  ETCS on-board (EVC)
--  The ERTMS/ETCS level of the on-board and the level transitions:
--  SUBSET-026 5.10 (packets 41 and 46, the table of priority of the
--  trackside supported levels, the announcement, the transition
--  location, the immediate and the conditional transition, the
--  transition by the driver, the acknowledgement), 4.9 and the level
--  rows of 4.10 and 4.12.
--
--  The level has a status (5.4.2.1): unknown at power-up (nothing is
--  kept over No Power, EVC_Core), valid once the driver entered it
--  (5.4.3.2 S2) or a transition was performed.
--
--  Orders (5.10.1.6: one at a time, a new one replaces an order not yet
--  executed). From a packet 41 or 46 the on-board selects the level of
--  the highest priority that is available for use (5.10.2.4), or the
--  one of the lowest priority when none is (5.10.2.7), and carries the
--  transition out as if ordered to that level only (5.10.2.5):
--    - D_LEVELTR "now": the transition at once (Take_Order, while the
--      message is evaluated, so that the rest of the message is
--      evaluated against the new level: 4.8.1.3);
--    - otherwise an announcement: the transition when the estimated
--      front end passes the location (5.10.1.5), shown to the driver
--      from its receipt when it changes the level (5.10.1.3);
--    - packet 46 (5.10.3.14): no change when the level of the on-board
--      is in its table, else as an immediate order.
--  In SH, PS and SM the announcements are rejected and the immediate
--  and conditional orders kept, to be evaluated once another mode than
--  SH, PS or SM is entered (4.4.8.1.5, 4.4.20.1.11, 4.4.21.1.11;
--  4.8.4 [7]). The table of priority of an order becomes applicable
--  when the transition is evaluated (5.10.2.8, 5.10.2.9); the driver's
--  choice of a level deletes the order (5.10.1.6.1, 5.10.2.10 b).
--
--  Available for use (5.10.2.4.1): levels 0 and 1 always; level 2 needs
--  the radio of phase E5 and is not available until then; level NTC
--  needs a National System, which this on-board does not have (STM out
--  of scope, PLAN.md).
--
--  Acknowledgement (5.10.4): when entering level 0 from another level
--  and when entering NTC (the table of 5.10.4.1), not in NL (5.10.4.1.1).
--  It is asked when the max safe front end passes the start of the
--  acknowledgement area, L_ACKLEVELTR in rear of the transition location
--  (a), in SB only at the transition (5.10.4.1.2), or upon the receipt
--  of an immediate order (b). An order to the level of an order not yet
--  executed that the driver acknowledged asks nothing again when it is
--  immediate (5.10.4.1.4) or its area is entered upon the receipt
--  (5.10.4.1.3); an area entered later asks again. Not acknowledged
--  T_ACK (A.3.1) after the transition: the service brake (5.10.4.2),
--  released by the acknowledgement; the reason is revoked by the modes
--  of 4.12 (the rows "Change to level 0 / NTC not acknowledged").
--
--  Locations: the transition location and the start of the
--  acknowledgement area are locations of the message (EVC_Profiles),
--  their "estimated" items; the estimated front end passes the first,
--  the max safe front end the second, along the sense of the message.
--
--  Not here (with the phase that brings it): the radio (5.10.3.1, .2,
--  .3, .6, .7, .10: sessions and reports, E5), 4.9.1.3 (the MA request
--  and position report parameters and the TAF request deleted on
--  entering level 1, the inhibition of revocable TSRs from balises in
--  level 2: E5 stores), 4.11.1.4 (an order of SH, PS or SM kept over No
--  Power: nothing is kept over No Power).

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Track_Packets.P41;
with ETCS_Track_Packets.P46;
with EVC_Distances; use EVC_Distances;
with EVC_Modes;     use EVC_Modes;
with EVC_Profiles;  use EVC_Profiles;
with Interfaces;    use Interfaces;

package EVC_Levels
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   ---------------------------------------------------------------------
   --  Tables of priority (5.10.2)
   ---------------------------------------------------------------------

   --  A level of a table, and for NTC the National System (NID_NTC)
   type Priority_Entry_T is record
      Level : Level_T := L0;
      NTC   : Natural range 0 .. 255 := 0;
      --  L_ACKLEVELTR of the entry, cm (the acknowledgement area of a
      --  transition to it, 5.10.4.1 a)
      Ack_Length : Length_T := 0;
   end record;

   --  The first 8 entries of a table are kept: the four levels and four
   --  National Systems, beyond any table a line has
   Max_Priorities : constant := 8;
   type Priority_List_T is array (1 .. Max_Priorities) of Priority_Entry_T;
   type Priority_Table_T is record
      Count : Natural range 0 .. Max_Priorities := 0;
      List  : Priority_List_T;
   end record;

   --  5.10.2.4.1
   function Available (L : Level_T) return Boolean is (L in L0 | L1);

   --  5.10.2.4, 5.10.2.7: the entry of the level the on-board selects
   function Selected (T : Priority_Table_T) return Positive
     with Pre  => T.Count >= 1,
          Post => Selected'Result <= T.Count;

   function Contains (T : Priority_Table_T; L : Level_T) return Boolean is
     (for some I in 1 .. T.Count => T.List (I).Level = L);

   --  5.10.4.1: the table of the acknowledgements
   function Ack_Needed (From, To : Level_T) return Boolean is
     ((To = L0 and then From /= L0) or else To = NTC);

   --  A.3.1: the driver acknowledgement time of the level transitions
   T_ACK_Ms : constant := 5_000;

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   function Level return Level_T
     with Global => State;
   function Status return Level_Status_T
     with Global => State;
   function Valid return Boolean is (Status = Valid)
     with Global => State;

   --  The level switched in this cycle (since Begin_Cycle): its value or
   --  its status changed (4.6.3 "the ERTMS/ETCS level switches to")
   function Switched return Boolean
     with Global => State;
   function Switched_To (L : Level_T) return Boolean is
     (Switched and then Level = L)
     with Global => State;

   --  An announcement not yet executed is stored (4.8.3 [11]), and
   --  whether it changes the level (5.10.1.3: shown to the driver)
   function Order_Pending return Boolean
     with Global => State;
   function Announced return Boolean
     with Global => State;
   function Announced_Level return Level_T
     with Global => State;
   --  4.8.3 [1]: an order to switch to level 1 at a further location
   function L1_Announced return Boolean is
     (Announced and then Announced_Level = L1)
     with Global => State;

   --  5.10.4: the driver is asked to acknowledge the transition to
   --  Ack_Level (before or after it), and 5.10.4.2 the service brake
   function Ack_Asked return Boolean
     with Global => State;
   function Ack_Level return Level_T
     with Global => State;
   function Ack_Brake return Boolean
     with Global => State;

   --  An immediate or conditional order kept in SH, PS or SM
   function Deferred return Boolean
     with Global => State;

   --  5.10.2.8: the table of priority of the trackside supported levels
   --  that is applicable
   function Table return Priority_Table_T
     with Global => State;

   ---------------------------------------------------------------------
   --  Juridical recording (EVC_Ports, event 40: levels): kind (byte 2),
   --  two bytes (bytes 3 and 4)
   ---------------------------------------------------------------------

   --  1 level switched (Level_T'Pos, the cause: 0 the driver, 1 an
   --    immediate order, 2 the transition location of an announcement,
   --    3 a conditional order, 4 an order kept in SH, PS or SM),
   --  2 order stored (the target, 1 an announcement, 2 kept for later),
   --  3 order deleted (the target, the cause: 0 the driver, 1 a mode
   --    entered, 2 replaced),
   --  4 acknowledgement asked (the level), 5 acknowledged (the level),
   --  6 service brake of 5.10.4.2 (1 applied, 0 released or revoked)
   Event_Switched  : constant := 1;
   Event_Stored    : constant := 2;
   Event_Deleted   : constant := 3;
   Event_Ack_Asked : constant := 4;
   Event_Acked     : constant := 5;
   Event_Brake     : constant := 6;

   type Event_T is record
      Kind, B3, B4 : Unsigned_8 := 0;
   end record;
   Max_Events : constant := 8;
   function Event_Count return Natural
     with Global => State,
          Post => Event_Count'Result <= Max_Events;
   function Event (I : Positive) return Event_T
     with Global => State,
          Pre => I <= Event_Count;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   --  What a cycle of the on-board knows when the levels evaluate
   type Context_T is record
      Mode           : Mode_T := M_SB;
      Standstill     : Boolean := True;
      --  the train position is valid (frame positions of the front end)
      Position_Valid : Boolean := False;
      Est_Front      : Dist_T := 0;
      Max_Front      : Dist_T := 0;
      Now_Ms         : Unsigned_64 := 0;
   end record;

   --  Power-up: the level unknown, nothing stored
   procedure Clear
     with Global => (Output => State),
          Post => Status = Unknown and then not Switched
                  and then not Order_Pending and then not Ack_Asked
                  and then not Ack_Brake and then not Deferred
                  and then Event_Count = 0;

   --  The start of a cycle: nothing switched yet, no event
   procedure Begin_Cycle
     with Global => (In_Out => State),
          Post => not Switched and then Event_Count = 0
                  and then Level = Level'Old and then Status = Status'Old;

   --  Packet 41 of the group message M (accepted by 4.8), in the context
   --  C; an immediate order is carried out at once
   procedure Take_Order (P : ETCS_Track_Packets.P41.Packet_T;
                         M : Message_T;
                         C : Context_T)
     with Global => (In_Out => State);

   --  Packet 46 (accepted by 4.8)
   procedure Take_Conditional (P : ETCS_Track_Packets.P46.Packet_T;
                               C : Context_T)
     with Global => (In_Out => State);

   --  One cycle: the driver's level (Driver_Level, the level code of the
   --  DMI in Code, 5.4.3.2 S2, 5.10.3.15), the orders kept in SH, PS or
   --  SM once another mode is entered, the acknowledgement area and the
   --  transition location of an announcement, the driver's
   --  acknowledgement (Ack), the time of 5.10.4.2
   procedure Evaluate (T            : Origin_Table_T;
                       C            : Context_T;
                       Driver_Level : Boolean;
                       Code         : Unsigned_16;
                       Ack          : Boolean)
     with Global => (In_Out => State);

   --  The mode machine took the transition From -> To (4.10, 4.12)
   procedure Mode_Entered (From, To : Mode_T)
     with Global => (In_Out => State),
          Post => Level = Level'Old and then Status = Status'Old;

   --  A.3.4.1.2 k): the desk closed during the start of mission deletes
   --  the level transition orders and the table not yet applicable
   procedure Delete_Orders
     with Global => (In_Out => State),
          Post => not Order_Pending and then not Deferred
                  and then Level = Level'Old and then Status = Status'Old;

   --  4.10 (column NP "to be revalidated"), 4.11: at the power-up, after
   --  Clear, the level and the table of priority kept over No Power
   --  (EVC_Retained); the level is invalid
   procedure Restore (L : Level_T; T : Priority_Table_T)
     with Global => (In_Out => State),
          Post => Level = L and then Status = Invalid
                  and then not Switched;

   --  4.11.1.1: no cold movement occurred, the kept level is valid
   procedure Revalidate
     with Global => (In_Out => State),
          Post => Level = Level'Old
                  and then (if Status'Old = Invalid then Status = Valid
                            else Status = Status'Old);

   --  4.11.1.1: a cold movement detected, or the information not
   --  available: the kept table of priority is deleted ("unknown")
   procedure Delete_Table
     with Global => (In_Out => State),
          Post => Level = Level'Old and then Status = Status'Old
                  and then Table.Count = 0;

   --  For EVC_Core.Set_Mode_For_Test (the tests of the hosts): the level
   --  L, valid, without a transition
   procedure Set_For_Test (L : Level_T)
     with Global => (In_Out => State),
          Post => Level = L and then Status = Valid;

   --  The origins the stored order refers to (EVC_Stored_Information)
   procedure Mark (Marks : in out Origin_Marks_T)
     with Global => State;

end EVC_Levels;
