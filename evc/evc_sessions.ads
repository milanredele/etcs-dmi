--  ETCS on-board (EVC)
--  Phase E5, the session and link half (e5/session; doc/EVC-PLAN.md
--  §13): the communication sessions of 3.5 (set-up, the system version
--  of 3.5.3 and 3.17, maintaining, termination, the radio networks of
--  3.5.6, the safe radio connection indication of 3.5.7), the time
--  stamps and the link supervision of 3.16.3 (T_NVCONTACT), the
--  position reports of 3.6.5, the acceptance of radio information of
--  4.8 with the transition buffer of 4.8.5, the level 2 parts of the
--  start and end of mission (5.4, 5.5), the level transitions into and
--  out of level 2 (5.10, 5.15) and the RBC handover (3.15.1).
--
--  The joint (e5/joint) gave the entry points EVC_Core calls, in the
--  order of the cycle. This unit is the only writer of the session
--  table of EVC_Radio.
--
--  Phase 1 of the half (e5/session-1) fills:
--    - the communication session of 3.5: set-up by order (packet 42 of
--      a balise group, Take_Order, or of a message 24 of an RBC), by the
--      start of mission in level 2 and by the driver's RBC data
--      (3.5.3.4 a, b, h); the safe radio connection requested and its
--      request repeated (3.5.3.7 a: three times in the start of mission,
--      A.3.1, else until it succeeds), message 155, the system version
--      (message 32) checked against the one this on-board supports (X =
--      3, version 3.0: the older versions of chapter 6 are phase E7),
--      159 with packet 2 and its acknowledgement 38 awaited and the 159
--      repeated once (3.5.3.7.4), or 154 and the termination; the
--      version awaited 15 s (3.5.3.7.3); maintaining (3.5.4: the
--      connection lost and set up again, the session kept 5 minutes,
--      then terminated and established again, 3.5.3.4 f); terminating
--      (3.5.5: 156, its acknowledgement 39, 156 repeated three times
--      every 15 s, the release); the abort of 3.5.3.8 (a, c, e). One RBC
--      at a time (3.5.3.5.2: a new RBC terminates the session with the
--      other one): with two sessions (EVC_Config) the new one is set up
--      at once in the free session while the old one terminates; with
--      one session it waits until the old one is terminated (3.5.3.5.2.1,
--      as 3.5.3.4.2). The handover with two RBCs (3.15.1) is phase 2.
--    - the link of 3.16.3: the sequence of the time stamps (a message
--      not newer than the last one of its session is inconsistent and
--      ignored, 3.16.3.3.3, wrap-around 3.16.3.2.3), the acknowledgement
--      146 of a message with M_ACK (3.16.3.5), the supervision of
--      T_NVCONTACT for the session of the supervising RBC in level 2
--      (3.16.3.4: the age of the time stamp of the latest message; the
--      reaction M_NVCONTACT: [41] train trip, the service brake released
--      at standstill or by a new message (3.14.1.7), none; 60 s later
--      the safe radio connection released and set up again, 3.16.3.4.3;
--      the driver informed, 3.16.3.4.4).
--    - the indication of the safe radio connection (3.5.7, Tables 1
--      and 2, the "connection status" timer of 45 s) for MSG_STATUS.
--    - the level 2 parts of the start of mission (5.4.3.2: D2 and the
--      level and RBC contact data to invalid as 5.4.3.3 says, D3/D7/A31
--      with the stored contact, S3 the driver's RBC contact, A31 the
--      session, D31/A32, D32 A33/A34 the SoM position report 157, the
--      answers 43 (A35), 41 (D34/A24) and 40 (D35/A39/A40), the Train
--      Data 129 at E16 (3.18.3.4) and their acknowledgement 8 (D15,
--      S11), 'Start' noted for the authority half (EVC_Radio.SoM_Start,
--      S21)) and the end of mission (5.5: message 150; with the desk
--      open repeated until the RBC orders the termination, 5.5.4.1.1).
--  Not yet (phase 2 of the half): the position reports of 3.6.5 other
--  than the SoM one, 4.8 and the transition buffer (every message
--  passes), the level transitions 5.10 / 5.15, the RBC handover and the
--  roles of 3.15.1 beyond the supervising session, the radio network
--  registration of 3.5.6 (the mobile is taken as registered).
--
--  The cycle (EVC_Core.Tick):
--    1. Read_Ports: Take_Event for each connection event of the RTM
--       port, then Take_Message for each message the codec accepted (its
--       bits are EVC_Received's last message); a message whose verdict
--       is Pass goes on to EVC_Radio_Authority.Take_Message. Then, while
--       Has_Released, Take_Released hands a message of the transition
--       buffer (4.8.5) back: the core parses it and gives it to the
--       authority as received in this cycle.
--    3. the balise group messages (EVC_Stored_Information): Take_Order
--       for a packet 42.
--    5. after the levels and the mission (EVC_Levels, EVC_Mission):
--       Evaluate, then EVC_Radio_Authority.Evaluate; the conditions of
--       4.6.3 this half owns are computed there for the mode machine.
--    6. after the mode machine, when the mode changed: Mode_Changed.
--    8. at the end of the outputs: Produce (the messages and requests
--       of the cycle, EVC_Radio.Send), then the authority's Produce, then
--       EVC_Radio.Drain.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Variables;
with EVC_Bytes;
with EVC_Driver_Requests;
with EVC_Levels;
with EVC_Mission;
with EVC_Modes;  use EVC_Modes;
with EVC_National_Values;
with EVC_Odometry;
with EVC_Ports;
with EVC_Position;
with EVC_Radio;
with EVC_Received;
with EVC_Train_Data;
with EVC_Train_Inputs;

package EVC_Sessions
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  What becomes of a message received (3.16.3, 3.5.5.6, 4.8)
   type Verdict_T is
     (Pass,       -- accepted: the authority takes it now
      Ignore,     -- rejected or consumed here (the session messages)
      Buffered);  -- kept in the transition buffer (4.8.5)

   --  The conditions of 4.6.3 this half owns (EVC_Transition_Conditions)
   type Condition_T is (C_41);

   Max_Infos : constant := 4;

   --  The power-up: no session, nothing buffered, nothing counted
   procedure Clear
     with Global => (Output => State),
          Post => Events_Taken = 0
                  and then Messages_Taken = 0
                  and then not Has_Released
                  and then not Service_Brake
                  and then Info_Count = 0
                  and then (for all C in Condition_T => not Holds (C));

   --  1. A connection event of the RTM port on the session S, at the
   --  on-board time Now_Ms
   procedure Take_Event (S      : EVC_Radio.Session_T;
                         Event  : EVC_Ports.RTM_Event_T;
                         Now_Ms : EVC_Radio.Time_Ms_T)
     with Global => (In_Out => (State, EVC_Radio.State)),
          Post => Has_Released = Has_Released'Old;

   --  1. A message received on the session S and accepted by the codec
   --  (EVC_Received: the last message), at the on-board time Now_Ms: its
   --  time stamp and sequence (3.16.3), the messages of the session
   --  (3.5: 32, 38, 39; 5.4: 8, 40, 41, 43), the session management
   --  orders of a message 24 (packet 42); Verdict says what becomes of it
   procedure Take_Message (S       : EVC_Radio.Session_T;
                           Now_Ms  : EVC_Radio.Time_Ms_T;
                           Verdict : out Verdict_T)
     with Global => (In_Out => (State, EVC_Radio.State),
                     Input  => EVC_Received.Store),
          Post => Has_Released = Has_Released'Old;

   --  3.5.2.6.1, 3.5.3.4 b), 3.5.5.1 a): a session management order
   --  (packet 42) of a balise group: establish (Q_RBC 1) or terminate
   --  the session with RBC on the number Radio; taken by the next
   --  Evaluate (the last order of a cycle wins)
   procedure Take_Order (Establish : Boolean;
                         RBC       : EVC_Radio.RBC_Id_T;
                         Radio     : ETCS_Variables.NID_RADIO_T)
     with Global => (In_Out => State),
          Post => Has_Released = Has_Released'Old;

   --  1b. The transition buffer (4.8.5) has a message to release
   function Has_Released return Boolean
     with Global => State;

   --  1b. The next message released from the transition buffer, into
   --  Data (Data'First .. Last), with its session
   procedure Take_Released (S    : out EVC_Radio.Session_T;
                            Data : out EVC_Bytes.Byte_Array;
                            Last : out Natural)
     with Global => (In_Out => State),
          Pre  => Has_Released
                  and then Data'Length >= EVC_Ports.RTM_Max_Length
                  and then Data'Last < Positive'Last,
          Post => Last in Data'Range
                  and then EVC_Ports.Valid_RTM (Data (Data'First .. Last));

   --  5. The cycle of the half (after the levels and the mission): the
   --  orders, the start of mission, the timers of the sessions, the
   --  indication, the link supervision, the conditions of 4.6.3
   procedure Evaluate (Ctx : EVC_Radio.Context_T)
     with Global => (In_Out => (State, EVC_Radio.State, EVC_Levels.State,
                                EVC_Position.State),
                     Input  => (EVC_Mission.State,
                                EVC_Driver_Requests.State,
                                EVC_National_Values.State,
                                EVC_Odometry.State,
                                EVC_Train_Data.State));

   --  6. The mode changed from From to To (5.5.2: the end of mission)
   procedure Mode_Changed (From, To : Mode_T)
     with Global => (In_Out => State, Input => EVC_Radio.State);

   --  8. The messages and requests of the cycle (EVC_Radio.Send)
   procedure Produce (Ctx : EVC_Radio.Context_T)
     with Global => (In_Out => (State, EVC_Radio.State, EVC_Radio.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Mission.State,
                                EVC_Train_Data.State,
                                EVC_Train_Inputs.State));

   --  The condition C holds in this cycle (computed by Evaluate)
   function Holds (C : Condition_T) return Boolean
     with Global => State;

   --  [41] (T_NVCONTACT is passed) AND (associated reaction is "train
   --  trip"): 3.16.3.4
   function T_NVCONTACT_Trip return Boolean is (Holds (C_41))
     with Global => State;

   ---------------------------------------------------------------------
   --  For the outputs of EVC_Core
   ---------------------------------------------------------------------

   --  3.16.3.4.2 b): the service brake of T_NVCONTACT is commanded
   --  (released at standstill or by a new message, 3.14.1.7)
   function Service_Brake return Boolean
     with Global => State;

   --  3.5.7: the indication of the safe radio connection, as the radio
   --  byte of MSG_STATUS (0 no connection, 1 up, 2 lost / set-up failed):
   --  that of the session of the supervising RBC, else of the first
   --  session that indicates more than "no connection"
   function Indication return Natural
     with Global => (State, EVC_Radio.State),
          Post => Indication'Result <= 2;

   --  The session byte of MSG_ONBOARD (0 none, 1 being established, 2
   --  established, 3 established, the only one, with a system version
   --  above 2.2)
   function Session_Code return Natural
     with Global => EVC_Radio.State,
          Post => Session_Code'Result <= 3;

   --  5.4.3.2 D15: the RBC acknowledged the Train Data (message 8)
   function Train_Data_Acknowledged return Boolean
     with Global => State;

   --  5.4.3.2 A31 to D31, D33, S11: the start of mission awaits an
   --  answer of the RBC (MSG_ONBOARD waiting 2)
   function Awaiting_RBC return Boolean
     with Global => (State, EVC_Radio.State);

   --  The driver information of the cycle (the system status messages
   --  of the DMI, EVC_DMI_Port.SS_*: 3.5.3.7 d, 5.4.3.2 A40, 3.16.3.4.4)
   function Info_Count return Natural
     with Global => State,
          Post => Info_Count'Result <= Max_Infos;
   function Info_Code (I : Positive) return Natural
     with Global => State,
          Pre => I <= Info_Count;

   --  For the tests: the events and messages taken since Clear
   --  (saturating)
   function Events_Taken return Natural
     with Global => State;
   function Messages_Taken return Natural
     with Global => State;
   --  the mode changes heard and the cycles produced since Clear
   function Mode_Changes_Taken return Natural
     with Global => State;
   function Cycles_Produced return Natural
     with Global => State;

end EVC_Sessions;
