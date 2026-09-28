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
--  rejections by reason) and recorded on the JRU port; nothing acts on
--  their content yet. The later phases fill the empty steps.

--  The postconditions name the state before the call ('Old) of query
--  functions behind "and then" and "if": allowed, and evaluated at entry
pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Bytes;
with EVC_Modes;    use EVC_Modes;
with EVC_Outbox;
with EVC_Ports;    use EVC_Ports;
with EVC_Received;

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

   function Level_Status return Level_Status_T
     with Global => State;

   --  The stored level; meaningful when Level_Status is Valid
   function Level return Level_T
     with Global => State;

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
     with Global => State;

   --  Inputs accepted and rejected on each port since Initialise
   --  (saturating)
   function Accepted (Port : Port_T) return Natural
     with Global => State;
   function Rejected (Port : Port_T) return Natural
     with Global => State;

   --  Inputs accepted on a port but dropped because the latch of the
   --  cycle was full (BTM: the 8 telegrams of a balise group, RTM: 4
   --  radio messages), since Initialise (saturating)
   function Overflowed (Port : Port_T) return Natural
     with Global => State;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   --  Power-up: the on-board starts in No Power (SUBSET-026 4.4.4.1.1)
   --  and nothing is stored (phase E0 keeps nothing over No Power)
   procedure Initialise
     with Global => (Output => (State, EVC_Received.Store),
                     In_Out => EVC_Outbox.Queue),
          Post => Mode = M_NP
                  and then not Failed
                  and then Level_Status = Unknown
                  and then Cycle = 0
                  and then Time_Ms = 0
                  and then not Isolation_Requested
                  and then EVC_Outbox.Used = 0
                  and then not EVC_Received.Has_Telegram
                  and then not EVC_Received.Has_Message;

   --  One input on a port. It is checked against the documented shape
   --  (EVC_Ports) and ignored when it does not match; otherwise it is
   --  latched for the next cycle. Nothing changes the mode here.
   procedure Handle_Input (Port : Port_T; Payload : EVC_Bytes.Byte_Array)
     with Global => (In_Out => State),
          Post => Mode = Mode'Old
                  and then Failed = Failed'Old
                  and then Cycle = Cycle'Old
                  and then (if Isolation_Requested'Old
                            then Isolation_Requested);

   --  One cycle of the on-board, Dt_Ms milliseconds after the previous
   --  one (any value: 0 and the largest are allowed)
   procedure Tick (Dt_Ms : Natural)
     with Global => (In_Out => (State, EVC_Outbox.Queue,
                                EVC_Received.Store)),
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
                     and then not Isolation_Requested);

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

end EVC_Core;
