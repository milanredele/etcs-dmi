--  ETCS on-board (EVC)
--  Phase E5, the session and link half, phase 3 (e5/session-4): the
--  position reports of 3.6.5 (message 136, 8.6.6), sent to the
--  supervising RBC on the events of 3.6.5.1.4 and as the position report
--  parameters of packet 58 ask (3.6.5.1.5, 3.6.5.1.7), and the deletion
--  of those parameters on entering level 1 (4.9.1.3).
--
--  A private child of EVC_Sessions, its state a part of the parent's.
--  EVC_Position computes what the position knows (Report_Triggers:
--  standstill reached and left, the LRBG passed, the periods, the
--  locations, "immediately") and keeps the parameters; this unit adds
--  the events the radio and the modes know, decides and sends.
--
--  Decisions (doc/EVC-PLAN.md §13, session and link, phase 3):
--  (1) The mode change (b) and the level change (g) are seen here, in
--      the cycle they happen (Mode_Changed, the level at Evaluate): the
--      report goes at the end of that cycle with its consequences
--      (3.6.5.1.4.1); the same triggers of EVC_Position, one cycle
--      later, are not used.
--  (2) h) "a communication session is successfully established": the
--      supervising RBC's session becomes established (EVC_Radio.
--      In_Communication); during the level 2 start of mission the SoM
--      position report (157, EVC_Sessions.Mission) is that report.
--  (3) Reports go to the supervising RBC's session only while it is
--      established and its connection up; an event meanwhile is not
--      kept (the next event or period reports the position).
--  (4) Packet 58 is taken from any message the half passes to the
--      authority (its acceptance, 4.8, is the authority half's) and is
--      referred to the LRBG of the message; applied by the next
--      Evaluate (EVC_Position.Set_Report_Parameters; refused when that
--      group is none the position keeps).
--  (5) The periods of 3.6.5.1.5 a) and b) run from the parameters'
--      reception and from their own last report (EVC_Position): a
--      report for another reason does not restart them.
--  (6) c), d), e), k), l) of 3.6.5.1.4 (integrity, RBC/RBC border,
--      errors of 3.16.4) are not observable yet; f) is the level change.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Levels;
with EVC_Modes;
with EVC_Odometry;
with EVC_Position;
with EVC_Received;

private package EVC_Sessions.Reports
  with SPARK_Mode => On,
       Abstract_State => (State with Part_Of => EVC_Sessions.State)
is

   procedure Clear
     with Global => (Output => State);

   --  1. The message accepted on S (EVC_Received): its packet 58, kept
   --  for Evaluate
   procedure Take_Message
     with Global => (In_Out => State, Input => EVC_Received.Store);

   --  5. The parameters received to EVC_Position; the events of the
   --  cycle (3.6.5.1.4, 3.6.5.1.5) that make a report due. SoM: the
   --  start of mission sends its own report (decision 2)
   --  Mode: the mode of the cycle, for the table of 4.5.2 ("Report
   --  Train Position": which event is reported in which mode)
   procedure Evaluate (SoM : Boolean; Mode : EVC_Modes.Mode_T)
     with Global => (In_Out => (State, EVC_Position.State),
                     Input  => (EVC_Radio.State, EVC_Levels.State,
                                EVC_Odometry.State)),
          Post => EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.Status = EVC_Position.Status'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  6. 3.6.5.1.4 b): the mode changed
   --  4.5.2: not on entering PS (no "X" in its column), nor from PS
   --  to SH (its note {2}), nor in NP, SF, IS
   procedure Mode_Changed (From, To : EVC_Modes.Mode_T)
     with Global => (In_Out => State);

   --  e5/handover: sessions beyond the supervising RBC's
   type Targets_T is array (EVC_Radio.Session_T) of Boolean;
   No_Targets : constant Targets_T := (others => False);

   --  8. The report due, message 136 with packet 0 or 1 (3.6.5.1.2), to
   --  the supervising RBC and to Also (3.15.1.3.4: both RBCs of a
   --  handover); to Forced whether due or not (3.15.1.3.9)
   procedure Produce (Ctx    : EVC_Radio.Context_T;
                      Also   : Targets_T := No_Targets;
                      Forced : Targets_T := No_Targets)
     with Global => (In_Out => (State, EVC_Radio.State, EVC_Radio.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State));

   --  For the tests: the reports sent, the parameters applied
   function Reports_Sent return Natural
     with Global => State;
   function Parameters_Taken return Natural
     with Global => State;

   --  e5/levels: a report due for another reason (5.10.3.3.3, 5.10.3.3.5,
   --  5.10.3.15.4: the exit from level 2), sent by the next Produce
   procedure Request
     with Global => (In_Out => State);

end EVC_Sessions.Reports;
