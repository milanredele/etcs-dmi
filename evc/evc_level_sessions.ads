--  ETCS on-board (EVC)
--  Phase E5 (e5/levels): the communication sessions of the level
--  transitions to and from level 2, SUBSET-026 5.10.3.
--
--  Into level 2:
--    - by trackside (5.10.3.1, .2): the order to connect is given by a
--      balise group in rear of the border (packet 42, EVC_Sessions.
--      Take_Order from the stored information, at the announcement
--      already); the Train Data (5.10.3.1.3, .2.2) and the report of the
--      new level with a position report (5.10.3.1.5, .2.5) are the
--      session half's (EVC_Sessions.Mission, EVC_Sessions.Reports:
--      3.6.5.1.4 for the level change);
--    - by the driver (5.10.3.15.2, 3.5.3.4 d): the session established
--      immediately when a valid RBC contact is stored (a); decision: in
--      SB the start of mission does it (EVC_Sessions.Mission, 5.4.3.2
--      D7), elsewhere this unit. b) (the driver's Radio data outside the
--      start of mission) is left.
--
--  Out of level 2 (5.10.3.3.3 .. .5, 5.10.3.6.2, .6.5, 5.10.3.10.3,
--  .10.6 by trackside; 5.10.3.15.3, .15.4 by the driver): a position
--  report when the min safe rear end has passed the border (trackside)
--  or the level change reported (driver: the session half's report of
--  3.6.5.1.4), then repeated every 15 s (A.3.1 "waiting time before
--  radio message repetition") at most 3 times (A.3.1 "repetition of
--  radio messages") while the RBC does not order the termination; no
--  reply 15 s after the last one: the on-board terminates the session.
--  Decisions: the border is where the estimated front end was in the
--  cycle of the transition; the min safe rear end has passed it once
--  the odometer has run the train length plus the under-reading of the
--  confidence interval (3.6.4) since. "The termination ordered" is the
--  session of the supervising RBC no longer established (terminated or
--  terminating, whoever ordered it). Back in level 2: the exit is over.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Levels;
with EVC_Modes;     use EVC_Modes;
with EVC_Odometry;
with EVC_Position;
with EVC_Radio;
with EVC_Sessions;
with EVC_Train_Data;
with Interfaces;    use Interfaces;

package EVC_Level_Sessions
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  A.3.1
   Repeat_Wait_Ms : constant := 15_000;
   Max_Repeats    : constant := 3;

   type Exit_Phase_T is (None, Border_Ahead, Awaiting_Order);

   function Exit_Phase return Exit_Phase_T
     with Global => State;

   --  For the tests: the sessions ordered (driver's level 2), the
   --  position reports requested and the sessions terminated by the
   --  exit procedure, since Clear (saturating)
   function Sessions_Ordered return Natural
     with Global => State;
   function Reports_Requested return Natural
     with Global => State;
   function Terminations return Natural
     with Global => State;

   --  Power-up: no exit procedure, the level as unknown
   procedure Clear
     with Global => (Output => State),
          Post => Exit_Phase = None;

   --  The cycle, after the levels (EVC_Core.Evaluate_Modes_And_Levels)
   --  and before the session half (EVC_Sessions.Evaluate applies the
   --  orders given here in the same cycle)
   procedure Evaluate (Mode : Mode_T; Now_Ms : Unsigned_64)
     with Global => (In_Out => (State, EVC_Sessions.State),
                     Input  => (EVC_Levels.State, EVC_Radio.State,
                                EVC_Odometry.State, EVC_Position.State,
                                EVC_Train_Data.State)),
          Post => EVC_Sessions.Has_Released = EVC_Sessions.Has_Released'Old;

end EVC_Level_Sessions;
