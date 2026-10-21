--  ETCS on-board (EVC)
--  Core of the ETCS on-board (SUBSET-026), independent of any transport.
--
--  Same shape as DMI_Core. The host calls Initialise (or Power_Up),
--  Configure with the installation configuration, Handle_Input with what
--  arrives on a port (latched until the next cycle), Tick once per
--  period and Take_Outputs for what the on-board sends. No tasking, no
--  allocation, no exception propagation: an input of the wrong shape is
--  ignored, and every operation is proven free of run-time errors.
--
--  One Tick, in this order (doc/EVC-PLAN.md §2):
--  1. read the ports: the telegrams (EVC_Received, the VBCs), the RTM
--     connection events and messages (EVC_Sessions, which passes what
--     it accepts to EVC_Radio_Authority), the driver's requests
--     (EVC_Driver_Requests) and the train inputs (EVC_Train_Inputs);
--  2. update the position (EVC_Position) with the cab and the odometer;
--  3. evaluate the stored information (EVC_Stored_Information, filtered
--     by level and mode per 4.8; the level orders go to EVC_Levels);
--  4. the speed and distance monitoring and the brake commands
--     (EVC_SDM, EVC_Brake_Commands) on the snapshot of 3.13.2;
--  5. the levels and the mission (EVC_Levels, EVC_Mission), the sessions
--     and the authority, the procedures (EVC_Procedures,
--     EVC_Text_Messages), each evaluating the conditions of 4.6.3 it owns;
--  6. the mode machine (EVC_Modes, EVC_Transition_Conditions), then what
--     entering the mode means for each unit (4.10, 4.12, 5.4.3.2, 5.5);
--  7. the outputs: the DMI, TIU and JRU ports, the RTM port last
--     (EVC_Radio.Drain).

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
with EVC_Level_Sessions;
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
with EVC_System_Version;
with EVC_SDM;
with EVC_Stored_Information;
with EVC_Supervision_Input;
with EVC_Text_Messages;
with EVC_LS_Display;
with EVC_Track_Conditions;
with EVC_Track_Description;
with EVC_Train_Data;
with EVC_Train_Inputs;
with EVC_VBC;
with Interfaces;

use type EVC_Config.Config_T;
use type EVC_Config.Status_T;
use type EVC_Distances.Cm_T;
use type EVC_Distances.Sense_T;
use type EVC_Location.Anchor_T;
use type EVC_Position.Cab_T;
use type EVC_Position.Status_T;

--  @req 3.5.6.2, 3.12.1.5 a), 3.14.1.8, 3.14.1.10, 3.15.1.3.6, A.3.5.2
--  @req 4.4.9.1.4, 4.4.11.1.5.1, 4.4.12.1.7, 4.4.18.1.6, 4.5.1.4, 5.4.3.2 A35
--  @req 5.11.2.2 A035
package EVC_Core
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   type Cycle_T is mod 2**32;    -- wraps after 13 years at 10 Hz
   type Time_Ms_T is mod 2**64;  -- on-board time, ms since Initialise

   --  State, for the contracts, the tests and the hosts

   function Mode return Mode_T
     with Global => State;

   --  The level and its status (EVC_Levels)
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

   --  Operations

   --  The power-up of a new on-board: it starts in No Power (SUBSET-026
   --  4.4.4.1.1) and nothing is stored, the store of the data kept over
   --  No Power (EVC_Retained) is empty. The installation configuration
   --  (Configure) stays, as the installation does over a power-up.
   --  @req 4.4.4.1.2
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
                                EVC_LS_Display.State,
                                EVC_JRU_Records.State,
                                EVC_Radio.State, EVC_Radio.Queue,
                                EVC_Sessions.State,
                                EVC_Level_Sessions.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio_Info.State,
                                EVC_System_Version.State,
                                EVC_VBC.State),
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
   --  @req 3.6.4.2.2.1, 3.15.8.2, 4.11.1.1, 4.11.1.3
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
                                EVC_LS_Display.State,
                                EVC_JRU_Records.State,
                                EVC_Position.State, EVC_Levels.State,
                                EVC_Radio.State, EVC_Radio.Queue,
                                EVC_Sessions.State,
                                EVC_Level_Sessions.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio_Info.State,
                                EVC_System_Version.State,
                                EVC_VBC.State),
                     Input  => (EVC_Config.State, EVC_Retained.State),
                     In_Out => EVC_Outbox.Queue),
          Post => Mode = M_NP
                  and then not Failed
                  and then Cycle = 0
                  and then Level_Status /= Valid
                  and then EVC_Position.Status /= EVC_Position.Valid;

   --  The UTC time at the on-board time 0, seconds since 2000-01-01
   --  00:00:00 UTC, for the date and time of the juridical messages
   --  (SUBSET-027 4.1.1.2 a, 4.2.3.3, 4.2.3.4): given by the port from
   --  its clock; without it the date and the time are recorded
   --  "unknown". Initialise and Power_Up forget it.
   procedure Set_UTC (Seconds : Interfaces.Unsigned_32)
     with Global => (In_Out => State);

   --  The installation configuration (EVC_Config): data, not code

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
   --  @req 3.13.2.2.6.1
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
   --  @req 3.6.1.5, 3.6.4.1.5, 3.6.4.1.5 a), 3.6.4.1.5 b), 4.4.19.1.4.6
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
                                EVC_LS_Display.State,
                                EVC_JRU_Records.State,
                                EVC_Radio.State, EVC_Radio.Queue,
                                EVC_Sessions.State,
                                EVC_Level_Sessions.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio_Info.State,
                                EVC_System_Version.State,
                                EVC_VBC.State)),
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
                  --  with the cab status, to the cab that is active, or
                  --  with a Supervised Manoeuvre authorisation (3.6.1.5.1)
                  and then
                  (if EVC_Position.Orientation
                        /= EVC_Position.Orientation'Old
                   then EVC_Position.Active_Cab
                          = (if EVC_Position.Orientation
                                  = EVC_Distances.Plus
                             then EVC_Position.Cab_A
                             else EVC_Position.Cab_B)
                        or else EVC_Position.Manoeuvre_Orientation)
                  --  3.6.4.1.2: against the same LRBG and orientation the
                  --  confidence interval never shrinks
                  and then
                  (if EVC_Position.LRBG = EVC_Position.LRBG'Old
                     and then EVC_Position.Orientation
                                = EVC_Position.Orientation'Old
                     and then EVC_Position.Manoeuvre_Orientation
                                = EVC_Position.Manoeuvre_Orientation'Old
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
   --  @req 4.4.5.1.1, 4.6.3 Table
   procedure Enter_Failure
     with Global => (In_Out => (State, EVC_Outbox.Queue)),
          Post => Failed
                  and then EVC_Outbox.Used = 0
                  and then (if Transition_Exists (Mode'Old, M_SF)
                            then Mode = M_SF else Mode = Mode'Old);

   --  Speed and distance monitoring

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
   --  on-board in service, like Set_Snapshot_For_Test: the scenarios of
   --  the position, the stored information and the supervision run in a
   --  mode of their choice: from the next cycle on, the mode is
   --  Mode (the mode machine runs from there), the level Level (valid)
   --  and the Train Data the default train of EVC_Train_Data (valid), as
   --  after a start of mission; in SR the SR data of the national values
   --  (EVC_Mission.Set_For_Test). Nothing of entering the mode (4.10,
   --  4.12) is done. The scenarios of the modes start their missions
   --  through the ports; those of the procedures (evc_test_procedures) start
   --  from a mode set here when the mode is not their subject.
   procedure Set_Mode_For_Test (Mode : Mode_T; Level : Level_T)
     with Global => (In_Out => (State, EVC_Levels.State, EVC_Mission.State,
                                EVC_Train_Data.State),
                     Input  => (EVC_National_Values.State,
                                EVC_Position.State, EVC_Odometry.State,
                                EVC_Radio.State)),
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
