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
--  order of the cycle, with bodies that do nothing but count: the half
--  fills the bodies, adds its private state and widens the Global
--  contracts (and those of the core steps that call them: Read_Radio,
--  Evaluate_Radio, Radio_Mode_Changed, Send_Radio). It is the only
--  writer of the session table of EVC_Radio.
--
--  The cycle (EVC_Core.Tick):
--    1. Read_Ports: Take_Event for each connection event of the RTM
--       port, then Take_Message for each message the codec accepted (its
--       bits are EVC_Received.Last_Message); a message whose verdict is
--       Pass goes on to EVC_Radio_Authority.Take_Message. Then, while
--       Has_Released, Take_Released hands a message of the transition
--       buffer (4.8.5) back: the core parses it and gives it to the
--       authority as received in this cycle.
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
with EVC_Distances;
with EVC_Driver_Requests;
with EVC_Levels;
with EVC_System_Version;
with EVC_Location;
with EVC_Mission;
with EVC_Modes;  use EVC_Modes;
with EVC_National_Values;
with EVC_Odometry;
with EVC_Ports;
with EVC_Position;
with EVC_Radio;
with EVC_Received;
with EVC_Train_Data;
use type EVC_Location.Anchor_T;
use type EVC_Position.Status_T;
use type EVC_Position.Cab_T;
use type EVC_Distances.Sense_T;
use type EVC_Distances.Cm_T;

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

   --  The power-up: no session, nothing buffered, nothing counted
   procedure Clear
     with Global => (Output => State),
          Post => Events_Taken = 0
                  and then Messages_Taken = 0
                  and then not Has_Released
                  and then (for all C in Condition_T => not Holds (C));

   --  1. A connection event of the RTM port on the session S, at the
   --  on-board time Now_Ms
   procedure Take_Event (S      : EVC_Radio.Session_T;
                         Event  : EVC_Ports.RTM_Event_T;
                         Now_Ms : EVC_Radio.Time_Ms_T)
     with Global => (In_Out => (State, EVC_Radio.State)),
          Post => Has_Released = Has_Released'Old;

   --  1. A message received on the session S and accepted by the codec
   --  (EVC_Received.Last_Message): its time stamp and sequence (3.16.3),
   --  the messages of the session (3.5: 32, 39, ...), the acceptance of
   --  4.8; Verdict says what becomes of it
   procedure Take_Message (S       : EVC_Radio.Session_T;
                           Now_Ms  : EVC_Radio.Time_Ms_T;
                           Verdict : out Verdict_T)
     with Global => (In_Out => (State, EVC_Radio.State),
                     Input  => (EVC_Received.Store, EVC_Position.State)),
          Post => Has_Released = Has_Released'Old;

   --  3. 3.5.2.6.1, 3.5.3.4 b), 3.5.5.1 a): a session management order
   --  (packet 42) of a balise group accepted (4.8): establish (Q_RBC 1)
   --  or terminate the session with RBC on the number Radio; applied by
   --  the next Evaluate (the last order of a cycle wins)
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
   --  sessions, the link supervision, the reports to send, the
   --  conditions of 4.6.3
   procedure Evaluate (Ctx : EVC_Radio.Context_T)
     with Global => (In_Out => (State, EVC_Radio.State, EVC_Position.State,
                                EVC_System_Version.State),
                     Input  => (EVC_National_Values.State,
                                EVC_Odometry.State, EVC_Mission.State,
                                EVC_Levels.State,
                                EVC_Train_Data.State,
                                EVC_Driver_Requests.State)),
          --  phase 3: the position report parameters (3.6.5) change
          --  nothing of the position itself
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

   --  6. The mode changed from From to To (3.5.3.4 c, 3.6.5.1.4, ...)
   procedure Mode_Changed (From, To : Mode_T)
     with Global => (In_Out => State,
                     Input  => (EVC_Mission.State, EVC_Radio.State));

   --  8. The messages and requests of the cycle (EVC_Radio.Send)
   procedure Produce (Ctx : EVC_Radio.Context_T)
     with Global => (In_Out => (State, EVC_Radio.State, EVC_Radio.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Train_Data.State));

   --  The level 2 start of mission (5.4.3.2, EVC_Sessions.Mission), for
   --  EVC_Core after Evaluate: A35 the RBC confirmed the position
   --  (EVC_Position.Revalidate), A24 / A39 the position to delete
   --  (EVC_Position.Delete_Position); A31 / D31 the session being opened
   --  (MSG_ONBOARD waiting 2)
   function Position_Confirmed return Boolean
     with Global => State;
   function Position_To_Delete return Boolean
     with Global => State;
   function SoM_Opening return Boolean
     with Global => State;

   --  For the tests: the Train Data sent to the RBC (129, or 157 with
   --  packet 11), the SoM position reports (157), the End of Mission
   --  messages (150), since Clear
   function Train_Data_Sent return Natural
     with Global => State;
   function SoM_Reports_Sent return Natural
     with Global => State;
   function EoM_Sent return Natural
     with Global => State;

   --  Phase 3, for the tests: the position reports 136 sent (3.6.5) and
   --  the position report parameters (packet 58) applied
   function Position_Reports_Sent return Natural
     with Global => State;
   function Report_Parameters_Taken return Natural
     with Global => State;

   --  The condition C holds in this cycle (computed by Evaluate)
   function Holds (C : Condition_T) return Boolean
     with Global => State;

   --  [41] (T_NVCONTACT is passed) AND (associated reaction is "train
   --  trip"): 3.16.3.4
   function T_NVCONTACT_Trip return Boolean is (Holds (C_41))
     with Global => State;

   --  3.16.3.4.2 b): the service brake of T_NVCONTACT is commanded
   --  (released by a new message, 3.14.1.7)
   function Service_Brake return Boolean
     with Global => State;

   --  3.5.7.1: the indication status of the safe radio connection with
   --  the relevant RBC (Table 1; MSG_STATUS radio: 0, 1, 2)
   type Indication_T is (No_Connection, Connection_Up, Connection_Lost);
   function Indication return Indication_T
     with Global => State;

   --  The system status messages of the catalogue of DMI chapter 15
   --  that started or ended in the cycle (MSG_SYSTEM_STATUS: entry,
   --  event 0 start, 1 end): 3.5.3.7 d) "Trackside not compatible",
   --  3.16.3.4.4 "Communication error" (the service brake; the trip is
   --  the reason of EVC_Procedures). Emptied by Produce.
   Max_Status_Events : constant := 4;
   type Status_Event_T is record
      Entry_Number : Natural range 0 .. 255 := 0;
      Event        : Natural range 0 .. 2 := 0;
   end record;
   function Status_Event_Count return Natural
     with Global => State,
          Post => Status_Event_Count'Result <= Max_Status_Events;
   function Status_Event (I : Positive) return Status_Event_T
     with Global => State,
          Pre => I <= Status_Event_Count;

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
