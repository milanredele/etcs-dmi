--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half (e5/authority; doc/EVC-PLAN.md
--  §13): the MA by radio (messages 3 and 33, 3.8.5 the update, 3.8.6
--  the co-operative shortening with message 9 and 137/138), the MA
--  request of 3.8.2 (message 132, packet 57, Q_MARQSTREASON), the
--  emergency messages of 3.10 (15, 16, their acknowledgement 147, the
--  revocation 18), the authorisations of the modes by the RBC (4.4 and
--  chapter 5: SR authorisation 2, the recognition of the exit from Trip
--  6 and the reports of 5.11, the shunting request 130 and its answers
--  27, 28 of 5.6, track ahead free 34 and 149, the Supervised Manoeuvre
--  of 5.21), the Train Data to the RBC and its changes (5.17), the
--  text message acknowledgements (message 158).
--
--  The joint (e5/joint) gave the entry points EVC_Core calls with
--  bodies that do nothing but count; the half fills them, adds its
--  private state, and widens the Global contracts (and those of the core
--  steps that call them). It reads the session table of EVC_Radio and
--  sends through EVC_Radio.Send; it does not write the table. The order
--  of the cycle is in EVC_Sessions: each step of this half follows the
--  same step of the session half.

with EVC_Levels;
with EVC_Modes;  use EVC_Modes;
with EVC_Movement_Authority;
with EVC_Odometry;
with EVC_Origins;
with EVC_Position;
with EVC_Radio;
with EVC_Radio_Info;
with EVC_Received;
with EVC_Stored_Information;

package EVC_Radio_Authority
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  The conditions of 4.6.3 this half owns (EVC_Transition_Conditions)
   type Condition_T is (C_6, C_11, C_20, C_31, C_36, C_81);

   --  The power-up: nothing received, nothing counted
   procedure Clear
     with Global => (Output => (State, EVC_Radio_Info.State)),
          Post => Messages_Taken = 0
                  and then not Unconditional_Stop_Received
                  and then (for all C in Condition_T => not Holds (C));

   --  1. A message of the session S that EVC_Sessions passed (received
   --  in this cycle, or released from the transition buffer): its bits
   --  are EVC_Received.Last_Message. Now_Ms: the on-board time.
   --  Messages 3 and 33 (3.8): their stored information to
   --  EVC_Radio_Info, referred to the LRBG they name (3.6.2.2.2 c,
   --  EVC_Position.Radio_Origin), for the stored information of the
   --  cycle (EVC_Stored_Information.Evaluate).
   procedure Take_Message (S      : EVC_Radio.Session_T;
                           Now_Ms : EVC_Radio.Time_Ms_T)
     with Global => (In_Out => (State, EVC_Origins.State,
                                EVC_Radio_Info.State),
                     Input  => (EVC_Received.Store, EVC_Position.State,
                                EVC_Odometry.State));

   --  5. The cycle of the half, after EVC_Sessions.Evaluate: the MA
   --  request, the emergency stops, the conditions of 4.6.3
   --  What the cycle tells the half besides the context (EVC_Core)
   type Facts_T is record
      --  3.13.11.8: the location to request an MA passed (EVC_SDM)
      MA_Request : Boolean := False;
      --  3.8.2.3.1: the driver selected Start in this cycle
      Start      : Boolean := False;
      --  3.8.2.3.2 c): a desk is open
      Desk_Open  : Boolean := False;
   end record;

   procedure Evaluate (Ctx : EVC_Radio.Context_T; Facts : Facts_T)
     with Global => (In_Out => (State, EVC_Radio_Info.State),
                     Input  => (EVC_Stored_Information.State,
                                EVC_Levels.State,
                                EVC_Movement_Authority.State,
                                EVC_Radio.State)),
          Post => EVC_Radio_Info.Count = 0;

   --  3.8.2: the reasons of the MA request applicable (Q_MARQSTREASON,
   --  7.5.1.118.3: bit 0 Start, 1 perturbation, 2 timer, 3 track
   --  description deleted, 4 track ahead free), as of the last Evaluate,
   --  and the MA requests sent since Clear
   function MA_Request_Reasons return Natural
     with Global => State;
   function MA_Requests_Sent return Natural
     with Global => State;

   --  6. The mode changed from From to To
   procedure Mode_Changed (From, To : Mode_T)
     with Global => (In_Out => State);

   --  8. The messages of the cycle (EVC_Radio.Send), after those of
   --  EVC_Sessions
   procedure Produce (Ctx : EVC_Radio.Context_T)
     with Global => (In_Out => (State, EVC_Radio.State, EVC_Radio.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State));

   --  The condition C holds in this cycle (computed by Evaluate)
   function Holds (C : Condition_T) return Boolean
     with Global => State;

   --  [6] (train is at standstill) AND (ERTMS/ETCS level is 2) AND
   --  (reception of the information "Shunting granted by RBC", due to a
   --  Shunting request from the driver): 5.6, message 28
   function Shunting_Granted return Boolean is (Holds (C_6))
     with Global => State;

   --  [11] in release speed monitoring, a balise group known by linking
   --  to be at or beyond the EOA (or in rear of it by less than the
   --  antenna to front end distance), level 2: the level 2 trip of
   --  5.11 (the level 1 one is [12], EVC_Procedures)
   function Group_At_EOA_In_RSM return Boolean is (Holds (C_11))
     with Global => State;

   --  [20] (unconditional emergency stop message is accepted): 3.10,
   --  message 16
   function Unconditional_Stop_Accepted return Boolean is (Holds (C_20))
     with Global => State;

   --  [31] (MA+SSP+gradient are on-board) AND (the train position
   --  confidence interval does not overlap any Mode Profile) AND
   --  (ERTMS/ETCS level is 2)
   function MA_On_Board_Level_2 return Boolean is (Holds (C_31))
     with Global => State;

   --  [36] (the identity of the overpassed balise group is not in the
   --  list of expected balises related to SR mode) AND (override is not
   --  active): the list of packet 63 with the SR authorisation (message
   --  2)
   function Group_Not_In_SR_List return Boolean is (Holds (C_36))
     with Global => State;

   --  [81] An MA, which is included in a "Supervised Manoeuvre
   --  authorisation" due to a Supervised Manoeuvre request by the
   --  driver, is received from the RBC: 5.21
   function SM_Authorised return Boolean is (Holds (C_81))
     with Global => State;

   --  [45] (no unconditional emergency stop message has been received):
   --  an unconditional emergency stop accepted and not revoked (3.10)
   function Unconditional_Stop_Received return Boolean
     with Global => State;

   --  For the tests: the messages taken since Clear (saturating)
   function Messages_Taken return Natural
     with Global => State;
   --  the mode changes heard and the cycles produced since Clear
   function Mode_Changes_Taken return Natural
     with Global => State;
   function Cycles_Produced return Natural
     with Global => State;
   --  the MAs received by radio and accepted since Clear (saturating)
   function Radio_MAs_Accepted return Natural
     with Global => State;

end EVC_Radio_Authority;
