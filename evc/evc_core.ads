--  ETCS on-board (EVC)
--  Core of the ETCS on-board (SUBSET-026), independent of any transport.
--
--  Same shape as DMI_Core: the host initialises it, hands over what
--  arrives on the ports (Handle_Input), runs one cycle per period (Tick)
--  and takes what the on-board sends (Take_Outputs). There is no
--  tasking, no allocation, no exception propagation: an input of the
--  wrong shape is ignored, and every operation is proven free of
--  run-time errors (evc/prove.sh).
--
--  One cycle (Tick) does, in this order (doc/EVC-PLAN.md §2): read the
--  ports, update the position, evaluate the stored information, speed
--  and distance monitoring, mode machine, produce the outputs. Inputs
--  that arrive between two cycles are latched and read at the start of
--  the next one.
--
--  Phase E0: power-up in No Power, transition NP -> SB (SUBSET-026
--  4.6.2, condition [4]), isolation by the driver (condition [1]), and
--  every cycle the DMI messages that show the mode (MSG_MODE_LEVEL,
--  MSG_ONBOARD). Phase E1: the telegrams (BTM) and radio messages (RTM)
--  latched since the last cycle are parsed when the ports are read
--  (EVC_Received keeps the last accepted of each, and counts the
--  rejections by reason) and recorded on the JRU port. Phase E2: the
--  accepted telegrams go with the stamp of their balise to the train
--  position (EVC_Position), which the second step updates with the cab
--  status and the odometer sample of the cycle; its events are recorded
--  on the JRU port, the geographical position goes to the DMI
--  (MSG_STATUS) and the validity of the position to MSG_ONBOARD. Phase
--  E3: the third step evaluates the stored information
--  (EVC_Stored_Information: the snapshot of 3.13.2, MSG_PLANNING,
--  MSG_TRACK_COND, JRU event 32), the fourth runs the speed and distance
--  monitoring and the brake command handling on that snapshot (EVC_SDM,
--  EVC_Brake_Commands: MSG_SPEED_STATE every cycle, the brake and the
--  time to Indication in MSG_STATUS, the TIU output, JRU events 20 to
--  22). Phase E4, modes and levels (e4/modes): the driver's requests of
--  the DMI port (EVC_Driver_Requests) and the inputs of the train
--  interface (EVC_Train_Inputs) are taken with the ports; the stored
--  information filters what it receives by level and mode (4.8) and
--  takes the level transition orders (EVC_Levels); after the
--  supervision the levels (5.10) and the mission (5.4, 5.5:
--  EVC_Mission) evaluate the cycle; the mode machine takes the
--  transition of 4.6.2 of the highest priority whose condition of 4.6.3
--  holds (EVC_Modes.Conditions, EVC_Transition_Conditions.Holds) and
--  carries out what entering the mode means (4.10, 4.12, 5.4.3.2, 5.5);
--  the outputs show the mode, the level, the announcement and the
--  acknowledgements (4.7, MSG_MODE_LEVEL, MSG_ONBOARD) and record the
--  events of the levels and the mission (JRU events 40 and 41). Phase
--  E4, the procedures (e4/procedures, integrated with the modes in
--  e4/integration): after the levels and the mission, the procedures of
--  chapter 5 (EVC_Procedures, the text messages of EVC_Text_Messages)
--  evaluate the conditions of 4.6.3 they own; after the mode machine
--  they do what entering the mode means for them and give their brake
--  demand; the outputs carry the acknowledgements and "override" in
--  MSG_MODE_LEVEL, the system status messages, the text messages, their
--  brake commands on the TIU, the information for an external function
--  (the second TIU output) and JRU events 23 and 24. Phase E5, the joint
--  (e5/joint): the RTM port carries the messages and connection events
--  of the communication sessions (EVC_Ports, EVC_Radio); the ports step
--  hands them to the session and link half (EVC_Sessions), which passes
--  the messages it accepts to the authority half (EVC_Radio_Authority);
--  both evaluate after the levels and the mission, hear of a mode
--  change after the mode machine and produce their messages at the end
--  of the outputs, which EVC_Radio.Drain moves to the RTM port. The
--  later phases fill the empty steps.

--  The postconditions name the state before the call ('Old) of query
--  functions behind "and then" and "if": allowed, and evaluated at entry
pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Brake_Commands;
with EVC_Bytes;
with EVC_Config;
with EVC_Distances;
with EVC_Driver_Requests;
with EVC_JRU_Records;
with EVC_Levels;
with EVC_Mission;
with EVC_Modes;    use EVC_Modes;
with EVC_Movement_Authority;
with EVC_National_Values;
with EVC_Odometry;
with EVC_Origins;
with EVC_Outbox;
with EVC_Ports;    use EVC_Ports;
with EVC_Location;
with EVC_Position;
with EVC_Procedures;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Radio_Info;
with EVC_Received;
with EVC_Retained;
with EVC_Sessions;
with EVC_SDM;
with EVC_Stored_Information;
with EVC_Supervision_Input;
with EVC_Text_Messages;
with EVC_Track_Conditions;
with EVC_Track_Description;
with EVC_Train_Data;
with EVC_Train_Inputs;

use type EVC_Config.Config_T;
use type EVC_Config.Status_T;
use type EVC_Distances.Cm_T;
use type EVC_Distances.Sense_T;
use type EVC_Location.Anchor_T;
use type EVC_Position.Cab_T;
use type EVC_Position.Status_T;

package EVC_Core
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   type Cycle_T is mod 2**32;    -- wraps after 13 years at 10 Hz
   type Time_Ms_T is mod 2**64;  -- on-board time, ms since Initialise

   ---------------------------------------------------------------------
   --  State, for the contracts, the tests and the hosts
   ---------------------------------------------------------------------

   function Mode return Mode_T
     with Global => State;

   --  The level and its status (EVC_Levels, phase E4)
   function Level_Status return Level_Status_T
     with Global => EVC_Levels.State;

   --  The stored level; meaningful when Level_Status is Valid
   function Level return Level_T
     with Global => EVC_Levels.State;

   function Failed return Boolean
     with Global => State;

   --  Cycles run since Initialise
   function Cycle return Cycle_T
     with Global => State;

   function Time_Ms return Time_Ms_T
     with Global => State;

   --  The driver isolated the on-board (a MSG_DRIVER_ACTION 20 on the
   --  DMI port) since the last cycle: 4.6.3 condition [1] holds at the
   --  next Tick
   function Isolation_Requested return Boolean
     with Global => EVC_Driver_Requests.State;

   --  Inputs accepted and rejected on each port since Initialise
   --  (saturating)
   function Accepted (Port : Port_T) return Natural
     with Global => State;
   function Rejected (Port : Port_T) return Natural
     with Global => State;

   --  Inputs accepted on a port but dropped because the latch of the
   --  cycle was full (BTM: the 8 telegrams of a balise group, RTM: 4
   --  radio messages and 4 connection events), since Initialise
   --  (saturating)
   function Overflowed (Port : Port_T) return Natural
     with Global => State;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   --  The power-up of a new on-board: it starts in No Power (SUBSET-026
   --  4.4.4.1.1) and nothing is stored, the store of the data kept over
   --  No Power (EVC_Retained) is empty. The installation configuration
   --  (Configure) stays, as the installation does over a power-up.
   procedure Initialise
     with Global => (Output => (State, EVC_Received.Store,
                                EVC_Retained.State,
                                EVC_Position.State, EVC_Odometry.State,
                                EVC_Origins.State,
                                EVC_Stored_Information.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                EVC_Train_Data.State,
                                EVC_Driver_Requests.State,
                                EVC_Train_Inputs.State,
                                EVC_Levels.State,
                                EVC_Mission.State,
                                EVC_Procedures.State,
                                EVC_Text_Messages.State,
                                EVC_JRU_Records.State,
                                EVC_Radio.State, EVC_Radio.Queue,
                                EVC_Sessions.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio_Info.State),
                     Input  => EVC_Config.State,
                     In_Out => EVC_Outbox.Queue),
          Post => Mode = M_NP
                  and then not Failed
                  and then Level_Status = Unknown
                  and then Cycle = 0
                  and then Time_Ms = 0
                  and then not Isolation_Requested
                  and then EVC_Outbox.Used = 0
                  and then not EVC_Received.Has_Telegram
                  and then not EVC_Received.Has_Message
                  and then EVC_Position.Status = EVC_Position.Unknown
                  and then not EVC_Position.LRBG.Valid
                  and then Installed;

   --  The power-up after a No Power period: as Initialise, but the data
   --  kept over No Power (4.10 column NP, EVC_Retained: the train
   --  position, the level and the table of priority of the trackside
   --  supported levels) are restored with the status "invalid"
   --  (3.6.1.3.3), the kept LRBG the SOLR (3.6.4.2.2.1); the cold
   --  movement detection read at the first odometer sample then makes
   --  them valid or leaves them invalid (4.11.1.1, 4.11.1.3). The first
   --  power-up of an on-board is Initialise.
   procedure Power_Up
     with Global => (Output => (State, EVC_Received.Store,
                                EVC_Odometry.State,
                                EVC_Origins.State,
                                EVC_Stored_Information.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                EVC_Train_Data.State,
                                EVC_Driver_Requests.State,
                                EVC_Train_Inputs.State,
                                EVC_Mission.State,
                                EVC_Procedures.State,
                                EVC_Text_Messages.State,
                                EVC_JRU_Records.State,
                                EVC_Position.State, EVC_Levels.State,
                                EVC_Radio.State, EVC_Radio.Queue,
                                EVC_Sessions.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio_Info.State),
                     Input  => (EVC_Config.State, EVC_Retained.State),
                     In_Out => EVC_Outbox.Queue),
          Post => Mode = M_NP
                  and then not Failed
                  and then Cycle = 0
                  and then Level_Status /= Valid
                  and then EVC_Position.Status /= EVC_Position.Valid;

   ---------------------------------------------------------------------
   --  The installation configuration (EVC_Config): data, not code
   ---------------------------------------------------------------------

   --  A valid image was loaded (else the configuration is
   --  EVC_Config.Default)
   function Configured return Boolean
     with Global => EVC_Config.State;

   --  The configuration in use: always valid (the ranges and Table 3 of
   --  3.13.2.2.6.1)
   function Configuration return EVC_Config.Config_T
     with Global => EVC_Config.State,
          Post => EVC_Config.Valid (Configuration'Result);

   --  The position uses the antenna of the configuration
   function Installed return Boolean is
     (EVC_Position.Front_Offset (EVC_Distances.Plus)
        = EVC_Config.Current.Antenna_To_Cab_A
      and then EVC_Position.Front_Offset (EVC_Distances.Minus)
                 = EVC_Config.Current.Antenna_To_Cab_B)
     with Global => (EVC_Config.State, EVC_Position.State);

   --  The installation configuration as a byte image (EVC_Config: the
   --  layout, the CRC, the checks). The host calls it before or at
   --  Initialise: it is accepted while the on-board is in No Power
   --  (before the first cycle after the power-up), refused in any other
   --  mode (an installation does not change under a running on-board);
   --  it stays over Initialise. A valid image becomes the configuration;
   --  an invalid or refused one is counted (EVC_Config.Rejections) and
   --  leaves the previous configuration. Either is recorded on the JRU
   --  at the next cycle (EVC_Ports, event 33).
   procedure Configure (Bytes : EVC_Bytes.Byte_Array)
     with Global => (Input  => State,
                     In_Out => (EVC_Config.State, EVC_Position.State)),
          Post => (if Mode = M_NP
                     and then EVC_Config.Decoded (Bytes).Status
                                = EVC_Config.Accepted
                   then Configured
                        and then Configuration
                                   = EVC_Config.Decoded (Bytes).Config
                   else Configured = Configured'Old
                        and then Configuration = Configuration'Old)
                  and then EVC_Config.Valid (Configuration)
                  and then Installed
                  and then EVC_Config.Report_Pending
                  and then EVC_Position.Status = EVC_Position.Status'Old
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old;

   --  One input on a port. It is checked against the documented shape
   --  (EVC_Ports) and ignored when it does not match; otherwise it is
   --  latched for the next cycle. Nothing changes the mode here.
   procedure Handle_Input (Port : Port_T; Payload : EVC_Bytes.Byte_Array)
     with Global => (In_Out => (State, EVC_Driver_Requests.State)),
          Post => Mode = Mode'Old
                  and then Failed = Failed'Old
                  and then Cycle = Cycle'Old
                  and then (if Isolation_Requested'Old
                            then Isolation_Requested);

   --  One cycle of the on-board, Dt_Ms milliseconds after the previous
   --  one (any value: 0 and the largest are allowed)
   procedure Tick (Dt_Ms : Natural)
     with Global => (In_Out => (State, EVC_Outbox.Queue, EVC_Retained.State,
                                EVC_Received.Store, EVC_Position.State,
                                EVC_Odometry.State, EVC_Origins.State,
                                EVC_Stored_Information.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                EVC_Config.State,
                                EVC_Train_Data.State,
                                EVC_Driver_Requests.State,
                                EVC_Train_Inputs.State,
                                EVC_Levels.State,
                                EVC_Mission.State,
                                EVC_Procedures.State,
                                EVC_Text_Messages.State,
                                EVC_JRU_Records.State,
                                EVC_Radio.Queue,
                                EVC_Sessions.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio_Info.State),
                     --  phase E5: In_Out once EVC_Sessions writes the
                     --  session table
                     Input  => EVC_Radio.State),
          Post => Failed = Failed'Old
                  and then
                  (if Failed
                   then Mode = Mode'Old
                        and then Cycle = Cycle'Old
                        and then EVC_Outbox.Used = EVC_Outbox.Used'Old
                   else
                     Cycle = Cycle'Old + 1
                     --  the on-board runs, so it is powered: condition
                     --  [29] never holds and [4] always does
                     and then Mode /= M_NP
                     --  only the transitions of 4.6.2
                     and then (Mode = Mode'Old
                               or else Transition_Exists (Mode'Old, Mode))
                     --  4.4.3.1.3: nothing leaves Isolation
                     and then (if Mode'Old = M_IS then Mode = M_IS)
                     --  4.6.2: NP -> IS [1] -p1- before NP -> SB [4] -p2-
                     and then (if Mode'Old = M_NP
                               then Mode = (if Isolation_Requested'Old
                                            then M_IS else M_SB))
                     and then not Isolation_Requested)
                  --  SUBSET-026 3.6.1.5: the orientation changes only
                  --  with the cab status, to the cab that is active
                  and then
                  (if EVC_Position.Orientation
                        /= EVC_Position.Orientation'Old
                   then EVC_Position.Active_Cab
                          = (if EVC_Position.Orientation
                                  = EVC_Distances.Plus
                             then EVC_Position.Cab_A
                             else EVC_Position.Cab_B))
                  --  3.6.4.1.2: against the same LRBG and orientation the
                  --  confidence interval never shrinks
                  and then
                  (if EVC_Position.LRBG = EVC_Position.LRBG'Old
                     and then EVC_Position.Orientation
                                = EVC_Position.Orientation'Old
                   then EVC_Position.Doubt_Over
                          >= EVC_Position.Doubt_Over'Old
                        and then EVC_Position.Doubt_Under
                                   >= EVC_Position.Doubt_Under'Old)
                  --  the installation configuration does not change in
                  --  service (only Configure, in No Power, changes it)
                  and then Configuration = Configuration'Old
                  and then Configured = Configured'Old;

   --  Move the queued outputs to Buffer: records (port u8, length u16,
   --  payload) as EVC_Outbox describes, as many whole records as fit;
   --  the others stay queued. Last is Buffer'First - 1 when nothing is
   --  pending. A buffer of EVC_Outbox.Capacity bytes takes everything.
   --  (Buffer'First >= 1 holds for any buffer but a null one declared
   --  with a lower bound below 1.)
   procedure Take_Outputs (Buffer : out EVC_Bytes.Byte_Array;
                           Last   : out Natural)
     with Global => (Input => State, In_Out => EVC_Outbox.Queue),
          Pre => Buffer'First >= 1,
          Post => Last >= Buffer'First - 1
                  and then Last - (Buffer'First - 1) <= Buffer'Length
                  and then (if Failed then Last = Buffer'First - 1);

   --  Containment of internal failures, as DMI_Core has it. The host
   --  calls Enter_Failure when any operation above failed (exception
   --  handler in a full runtime, last chance handler or trap handler
   --  otherwise). From then on and until Initialise, inputs and time are
   --  ignored and nothing is output: the on-board falls silent, the DMI
   --  shows SF when its link supervision expires, and the train
   --  interface, which is fail-safe, applies the emergency brake. The
   --  mode becomes System Failure where 4.6.2 has that transition
   --  (condition [13], 4.4.5.1.1).
   procedure Enter_Failure
     with Global => (In_Out => (State, EVC_Outbox.Queue)),
          Post => Failed
                  and then EVC_Outbox.Used = 0
                  and then (if Transition_Exists (Mode'Old, M_SF)
                            then Mode = M_SF else Mode = Mode'Old);

   ---------------------------------------------------------------------
   --  Speed and distance monitoring (phase E3, e3/supervision)
   ---------------------------------------------------------------------

   --  For the tests of the hosts (evc_test, evc_fuzz), not for an
   --  on-board in service: from the next cycle on and until Initialise,
   --  the speed and distance monitoring reads S instead of the snapshot
   --  of the stored information (EVC_Stored_Information.Current, 3.13.2);
   --  the stored information is still evaluated and still sends its
   --  frames. Called again, the last S counts.
   procedure Set_Snapshot_For_Test (S : EVC_Supervision_Input.Snapshot_T)
     with Global => (In_Out => State),
          Post => Mode = Mode'Old and then Failed = Failed'Old
                  and then Cycle = Cycle'Old;

   --  For the tests of the hosts (evc_test, evc_fuzz), not for an
   --  on-board in service, like Set_Snapshot_For_Test (phase E4): the
   --  scenarios of phases E2 and E3 exercise the position, the stored
   --  information and the supervision as they were written, before the
   --  modes, in a mode of their own: from the next cycle on, the mode is
   --  Mode (the mode machine runs from there), the level Level (valid)
   --  and the Train Data the default train of EVC_Train_Data (valid), as
   --  after a start of mission; in SR the SR data of the national values
   --  (EVC_Mission.Set_For_Test). Nothing of entering the mode (4.10,
   --  4.12) is done. The scenarios of E4 start their missions through
   --  the ports; those of the procedures (evc_test_procedures) start
   --  from a mode set here when the mode is not their subject.
   procedure Set_Mode_For_Test (Mode : Mode_T; Level : Level_T)
     with Global => (In_Out => (State, EVC_Levels.State, EVC_Mission.State),
                     Output => EVC_Train_Data.State,
                     Input  => (EVC_National_Values.State,
                                EVC_Position.State, EVC_Odometry.State)),
          Pre  => Mode /= M_NP,
          Post => EVC_Core.Mode = Mode and then Failed = Failed'Old
                  and then Cycle = Cycle'Old
                  and then EVC_Core.Level = Level
                  and then Level_Status = Valid;

   --  What the speed and distance monitoring found in the last cycle
   --  (3.13.10)
   function Supervision return EVC_SDM.Result_T
     with Global => State;

   --  The commands to the train interface of the last cycle (3.14.1)
   function Brake_Commands return EVC_Brake_Commands.Commands_T
     with Global => State;

end EVC_Core;
