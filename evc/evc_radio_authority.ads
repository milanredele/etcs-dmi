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

with ETCS_Variables;
with EVC_Balise_Groups;
with EVC_Bytes;
with EVC_Levels;
with EVC_Modes;  use EVC_Modes;
with EVC_Movement_Authority;
with EVC_Odometry;
with EVC_Origins;
with EVC_Ports;
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

   --  1. 4.8.3 [2], 4.8.5.1: the last message received (EVC_Received) is
   --  to be kept in the transition buffer instead of taken (Store_Message)
   function To_Buffer return Boolean
     with Global => (State, EVC_Received.Store);

   --  1. 4.8.5.1, 4.8.5.3: the message Data of the session S kept in the
   --  transition buffer (three messages, the oldest replaced)
   procedure Store_Message (S : EVC_Radio.Session_T;
                            Data : EVC_Bytes.Byte_Array)
     with Global => (In_Out => State),
          Pre  => EVC_Ports.Valid_RTM (Data);

   --  4.8.5.1: the messages the transition buffer keeps
   Buffer_Size : constant := 3;

   --  The messages in the transition buffer
   function Buffered return Natural
     with Global => State;

   --  1d. 4.8.5.5: the transition buffer is released (the level is 2):
   --  Take_Released gives its oldest message, with its session, into
   --  Data (Data'First .. Last); EVC_Core parses it and gives it to
   --  Take_Message as received in this cycle
   function Has_Released return Boolean
     with Global => State;
   procedure Take_Released (S    : out EVC_Radio.Session_T;
                            Data : in out EVC_Bytes.Byte_Array;
                            Last : out Natural)
     with Global => (In_Out => State),
          Pre  => Has_Released
                  and then Data'Length >= EVC_Ports.RTM_Max_Length
                  and then Data'Last < Positive'Last,
          Post => Last in Data'Range
                  and then EVC_Ports.Valid_RTM (Data (Data'First .. Last));

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
      --  3.8.6.1 b): the train front end in rear of the Indication
      --  supervision limit of the shortened MA proposed in the cycle
      --  (EVC_SDM.Result_T.Proposal_In_Rear)
      Proposal_In_Rear : Boolean := False;
      --  4.4.11.1.6.4 a): the driver entered the SR speed and distance in
      --  the cycle (taken by EVC_Mission)
      SR_Entered : Boolean := False;
      --  4.6.3 [36]: the override is active (EVC_Procedures, as of the
      --  last cycle)
      Override_Active : Boolean := False;
      --  5.6.2.2 S0, E015: the driver selected Shunting in the cycle; the
      --  train is at standstill
      Shunting_Selected : Boolean := False;
      Standstill        : Boolean := False;
      --  4.8.4 [2], [4], [11]: a cab is active, valid Train Data, a valid
      --  train running number; 4.8.3 [3]: Train Data sent to the RBC and
      --  not acknowledged (the context of the acceptance of 4.8)
      Cab_Active         : Boolean := False;
      Train_Data_Valid   : Boolean := False;
      TRN_Valid          : Boolean := False;
      Train_Data_Unacked : Boolean := False;
      --  3.15.5.3: the driver acknowledged the track ahead free request
      TAF_Confirmed      : Boolean := False;
   end record;

   procedure Evaluate (Ctx : EVC_Radio.Context_T; Facts : Facts_T)
     with Global => (In_Out => (State, EVC_Radio_Info.State),
                     Input  => (EVC_Stored_Information.State,
                                EVC_Position.State, EVC_Radio.State,
                                EVC_Levels.State, EVC_Odometry.State,
                                EVC_Movement_Authority.State)),
          Post => EVC_Radio_Info.Count <= 1;

   --  3.8.2: the reasons of the MA request applicable (Q_MARQSTREASON,
   --  7.5.1.118.3: bit 0 Start, 1 perturbation, 2 timer, 3 track
   --  description deleted, 4 track ahead free), as of the last Evaluate,
   --  and the MA requests sent since Clear
   function MA_Request_Reasons return Natural
     with Global => State;
   function MA_Requests_Sent return Natural
     with Global => State;

   --  3.8.6: the requests to shorten the MA granted (137) and rejected
   --  (138) since Clear
   function Shortenings_Granted return Natural
     with Global => State;
   function Shortenings_Rejected return Natural
     with Global => State;

   --  3.10: the emergency stops accepted and not revoked
   function Emergency_Stops return Natural
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

   --  4.4.11.1.6.2, 4.4.11.1.6.4 b): the SR distance given by the RBC in
   --  an SR authorisation (message 2), supervised from its reception
   --  (4.4.11.1.3.1 b); not Active when the national value or the
   --  driver's applies (RBC_SR_Given False), nor for D_SR "infinite"
   function RBC_SR_Given return Boolean
     with Global => State;
   function RBC_SR_Distance return EVC_Odometry.Virtual_T
     with Global => State;

   --  The SR distance that applies: the RBC's while it is the last one
   --  received, else Mission (EVC_Mission's: the national or the driver's)
   function SR_Distance_Of (Mission : EVC_Odometry.Virtual_T)
     return EVC_Odometry.Virtual_T
   is (if RBC_SR_Given then RBC_SR_Distance else Mission)
     with Global => State;

   --  4.4.11.1.3 c), d): the RBC sent a list of expected balise groups in
   --  SR (packet 63) and Id is in it
   function In_SR_List (Id : EVC_Balise_Groups.Identity_T) return Boolean
     with Global => State;

   --  4.4.11.1.3 d): the groups passed in the cycle are all in that list
   --  (as of the last Evaluate; for the "stop if in SR" of EVC_Procedures)
   function Groups_Passed_Listed return Boolean
     with Global => State;

   --  5.11.2.2 S120, E125: the RBC recognised the exit from TRIP mode
   --  (message 6) in the PT mode of the on-board (for 4.8.4 [1] and
   --  the choices of S140)
   function Trip_Exit_Recognised return Boolean
     with Global => State;

   --  5.6 in level 2: the request for shunting (message 130) waits for
   --  the answer of the RBC (MSG_ONBOARD waiting 4, dmi_protocol.ads),
   --  and the answer (1 authorised, 0 refused or no reply)
   function SH_Waiting return Boolean
     with Global => State;
   function SH_Answer return Natural
     with Global => State,
          Post => SH_Answer'Result <= 1;

   --  5.6.2.2 S050, A050: the list of balise groups for the SH area of
   --  the authorisation (message 28, packet 49), for EVC_Procedures when
   --  SH is entered by [6]; SH_List_Given False: no list
   Max_SH_List : constant := 32;
   function SH_List_Given return Boolean
     with Global => State;
   function SH_List_Count return Natural
     with Global => State,
          Post => SH_List_Count'Result <= Max_SH_List;
   function SH_List_Item (I : Positive) return EVC_Balise_Groups.Identity_T
     with Global => State,
          Pre => I <= SH_List_Count;

   --  The requests for shunting sent since Clear, and T_TRAIN of the last
   --  one (4.8.4 [14]: an answer names it)
   function SH_Requests_Sent return Natural
     with Global => State;
   function SH_Request_Stamp return ETCS_Variables.T_TRAIN_T
     with Global => State;

   --  5.6.4.1.2: no reply after the repetitions; the session is to be
   --  terminated (the session half's), latched until the next request
   function SH_Request_Failed return Boolean
     with Global => State;

   --  The DMI system status message of the cycle (EVC_DMI_Port entry
   --  number, started; 0: none): SH refused (5.6.2.2 A220), SH request
   --  failed (5.6.4.1.2)
   function Status_Entry return Natural
     with Global => State;

   --  4.4.11.1.6.5: "Override" selected; the SR distance given by the RBC
   --  is deleted (EVC_Core, with EVC_Mission.Override_In_SR)
   procedure Override_Selected
     with Global => (In_Out => State),
          Post => not RBC_SR_Given;

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
   --  3.15.5: a track ahead free request of the RBC is stored, shown to
   --  the driver (MSG_MODE_LEVEL taf), and the answers sent (149)
   function TAF_Stored return Boolean
     with Global => State;
   function TAF_Shown return Boolean
     with Global => State;
   function TAF_Granted return Natural
     with Global => State;

   --  4.8: the messages the tables rejected since Clear
   function Messages_Rejected return Natural
     with Global => State;

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
