--  The display of the Lowest Supervised Speed within the Movement
--  Authority in Limited Supervision (SUBSET-026 4.4.19.1.4 to
--  4.4.19.1.4.8, phase E4, e4/ls-display): the generic LS function
--  marker (packet 181, 7.4.2.37.4), the toggle orders (packet 180,
--  7.4.2.37.3) with their delay timer, whether the LSSMA is shown and its
--  value, for MSG_MODE_LEVEL (EVC_DMI_Port).
--
--  Decisions:
--  - 4.4.19.1.4 b): the target speed at an EOA is 0, at an LOA its
--    speed; the release speed is not part of the LSSMA (4.4.19.1.4 lists
--    it as a speed displayed beside it).
--  - 4.4.19.1.4.3 "greater than the time-out": the timer counts in
--    milliseconds, T_LSSMA in seconds; a timer that has reached the
--    time-out displays (4.4.19.1.4.4 speaks of "reached"), so that a
--    T_LSSMA of 0 at the reception is "immediately fulfilled".
--  - The LSSMA is shown in Limited Supervision only (4.4.19.1.4 is a
--    clause of the LS mode; 4.7.2: the row LSSMA has its A in LS only),
--    in km/h rounded down, with a position and an MA on board.
--  - 4.10: the toggle on order is deleted on a transition to another
--    mode than LS and PT (the row "LSSMA display toggle on order"); the
--    marker is kept on every transition (its row: U).

with Interfaces;            use Interfaces;
with EVC_Modes;             use EVC_Modes;
with EVC_Supervision_Input;

package EVC_LS_Display
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  T_LSSMA (7.5.1.144.1): 0 .. 255 s
   subtype Delay_S_T is Natural range 0 .. 255;

   --  MSG_MODE_LEVEL: the LSSMA not shown
   No_LSSMA : constant Unsigned_16 := 16#FFFF#;

   --  4.4.19.1.4.8: the generic LS function marker is stored
   function Marker_Stored return Boolean
     with Global => State;

   --  4.4.19.1.4.2 to 4.4.19.1.4.4: a toggle on order not executed yet
   function Order_Pending return Boolean
     with Global => State;

   --  4.4.19.1.4.3, 4.4.19.1.4.5: the LSSMA display is toggled on
   function Toggled_On return Boolean
     with Global => State;

   --  4.4.19.1.4: the LSSMA in km/h as the last Step computed it,
   --  No_LSSMA when not shown
   function LSSMA_Kmh return Unsigned_16
     with Global => State;

   --  Every information deleted (start, power up)
   procedure Clear
     with Global => (Output => State),
          Post => not Marker_Stored and then not Order_Pending
                  and then not Toggled_On and then LSSMA_Kmh = No_LSSMA;

   --  7.4.2.37.4, 4.4.19.1.4: the generic LS function marker received
   procedure Take_Marker
     with Global => (In_Out => State),
          Post => Marker_Stored;

   --  4.4.19.1.4.8: a Limited Supervision mode profile received without
   --  the marker in the same balise group message deletes it
   procedure Delete_Marker
     with Global => (In_Out => State),
          Post => not Marker_Stored;

   --  4.4.19.1.4.3: the delay timer started at Start_Ms has reached the
   --  time-out Delay_S at Now_Ms
   function Elapsed (Start_Ms, Now_Ms : Unsigned_64; Delay_S : Delay_S_T)
     return Boolean
   is (Now_Ms >= Start_Ms
       and then Now_Ms - Start_Ms >= Unsigned_64 (Delay_S) * 1_000);

   --  4.4.19.1.4.2 to 4.4.19.1.4.5: an order to toggle the display on
   --  (On, with its time-out Delay_S) or off, its delay timer started at
   --  Start_Ms (a: the time stamp of the radio message; b: the passage of
   --  the first balise of the group; c: the level transition of the
   --  transition buffer), received at Now_Ms
   procedure Take_Order (On       : Boolean;
                         Delay_S  : Delay_S_T;
                         Start_Ms : Unsigned_64;
                         Now_Ms   : Unsigned_64)
     with Global => (In_Out => State),
          Post => (if not On then not Order_Pending and then not Toggled_On)
                  and then
                  (if On then
                     Toggled_On = Elapsed (Start_Ms, Now_Ms, Delay_S)
                     and then Order_Pending = not Toggled_On);

   --  e4/ls-display-3 (B120), 4.8.3 [2]: a toggle on order of the RBC
   --  (packet 180 of message 24) received in level 0, NTC or 1 with an
   --  order to switch to level 2 at a further location, kept until the
   --  transition (decision: the packet alone, with its T_LSSMA, as the
   --  packet 79 of e5/radio-geo-buffer; the other packets of the message
   --  have their own rows)
   function Order_Held return Boolean
     with Global => State;

   procedure Hold_Order (Delay_S : Delay_S_T)
     with Global => (In_Out => State),
          Post => Order_Held;

   --  4.8.5.5, 4.4.19.1.4.2 c): at the transition to level 2 the held
   --  order taken when Take, its timer started at Now_Ms; 4.8.5.4: else
   --  deleted (level 2 no longer announced, the session lost, or the
   --  order rejected at the transition)
   procedure Release_Held (Take : Boolean; Now_Ms : Unsigned_64)
     with Global => (In_Out => State),
          Post => not Order_Held;

   --  4.4.19.1.4.6: entering LS toggles the display off, unless an order
   --  received in this cycle displayed it immediately; 4.10: a transition
   --  to another mode than LS and PT deletes the toggle on order
   procedure Mode_Changed (From, To : Mode_T)
     with Global => (In_Out => State),
          Post => (if To not in M_LS | M_PT
                   then not Order_Pending and then not Toggled_On);

   --  4.4.19.1.4 a) and b), 4.4.19.1.4.1: the LSSMA of S in cm/s, the
   --  lowest of the MRSP elements between the min safe front end and the
   --  EOA / LOA and of the target speed there
   function LSSMA (S : EVC_Supervision_Input.Snapshot_T)
     return EVC_Supervision_Input.Speed_Cms_T;

   --  Once per cycle, after the supervision and the mode: 4.4.19.1.4.3
   --  the delay timer, then whether the LSSMA is shown in Mode (with the
   --  marker: toggled on; without, 4.4.19.1.4.7) and its value
   procedure Step (S      : EVC_Supervision_Input.Snapshot_T;
                   Mode   : Mode_T;
                   Now_Ms : Unsigned_64)
     with Global => (In_Out => State),
          Post => (if Mode /= M_LS then LSSMA_Kmh = No_LSSMA)
                  and then (if LSSMA_Kmh /= No_LSSMA
                            then LSSMA_Kmh <= 1_080);

end EVC_LS_Display;
