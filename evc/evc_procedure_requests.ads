--  ETCS on-board (EVC)
--  The driver's actions the procedures of phase E4 read (doc/EVC-PLAN.md
--  §10, second bullet), decoded from the DMI port into queries named
--  after the DMI actions (common/dmi_protocol.ads, MSG_DRIVER_ACTION).
--
--  INTERIM. The modes half of E4 (branch e4/modes) creates
--  EVC_Driver_Requests, the decoding of MSG_DRIVER_ACTION and
--  MSG_DRIVER_DATA for the whole on-board; this package is the part the
--  procedures half needs until the two halves merge, in the same style,
--  and is to be folded into EVC_Driver_Requests then (its queries become
--  theirs, the calls in EVC_Core.Handle_Input and Read_Ports go).
--
--  Like the other inputs of the core, an action is latched when it
--  arrives (Latch, from EVC_Core.Handle_Input, any number between two
--  cycles) and read in the cycle that follows (Take, at the first step
--  of EVC_Core.Tick): every query answers for the actions latched
--  before the last Take, and only for those.
--
--  Actions (MSG_DRIVER_ACTION, action u8, arg u16):
--     2 the driver's acknowledgement, with its kind and the id of a text
--       message (kind 1 mode change: an acknowledgement request of
--       On Sight, Shunting, Limited Supervision, Reversing or Trip the
--       procedures displayed; kinds 2 and 3, fixed and plain text
--       messages, by the id of MSG_TEXT; kind 5 brake release, read by
--       EVC_Core for 3.14.1.5);
--     6 "Override" (5.8.2);
--     7 "Shunting" (5.6.2 E015);
--     8 "Exit Shunting" (4.6.3 [19]);
--     17 Supervised Manoeuvre, arg 2 "Exit SM" (4.6.3 [82]);
--     18 the inhibition of the BTM alarm reaction, arg 0 select, arg 1
--        revoke (5.22.2, 5.22.5.1 c);
--     19 "Maintain Shunting", the function "Continue Shunting on desk
--        closure" (4.4.20.1.5);
--     3 "Tunnel stopping area" display toggle (5.18.8.2).

with EVC_Bytes; use EVC_Bytes;
with EVC_DMI_Port;
with Interfaces; use Interfaces;

package EVC_Procedure_Requests
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  The text acknowledgements of one cycle kept (DMI: one per press)
   Max_Text_Acks : constant := 8;

   --  Action codes of MSG_DRIVER_ACTION (dmi_protocol.ads)
   Action_Tunnel_Toggle     : constant := 3;
   Action_Override_EOA      : constant := 6;
   Action_Shunting_Request  : constant := 7;
   Action_Exit_Shunting     : constant := 8;
   Action_Supervised_Manoeuvre : constant := 17;
   Action_BMM_Inhibition    : constant := 18;
   Action_Maintain_Shunting : constant := 19;

   --  Acknowledgement kinds (DMI_Ack.Ack_Kind_T'Pos)
   Ack_Mode_Change : constant := 1;
   Ack_Fixed_Text  : constant := 2;
   Ack_Plain_Text  : constant := 3;

   ---------------------------------------------------------------------
   --  Queries: the actions read at the last Take
   ---------------------------------------------------------------------

   function Override_EOA return Boolean
     with Global => State;
   function Shunting_Request return Boolean
     with Global => State;
   function Exit_Shunting return Boolean
     with Global => State;
   function Maintain_Shunting return Boolean
     with Global => State;
   function Exit_Supervised_Manoeuvre return Boolean
     with Global => State;
   function BMM_Inhibition return Boolean
     with Global => State;
   function Revoke_BMM_Inhibition return Boolean
     with Global => State;
   function Tunnel_Toggle return Boolean
     with Global => State;
   --  an acknowledgement of kind "mode change"
   function Mode_Acknowledged return Boolean
     with Global => State;

   --  The text messages acknowledged (their MSG_TEXT ids)
   function Text_Ack_Count return Natural
     with Global => State,
          Post => Text_Ack_Count'Result <= Max_Text_Acks;
   function Text_Ack (I : Positive) return Unsigned_16
     with Global => State,
          Pre => I <= Text_Ack_Count;
   function Text_Acknowledged (Id : Unsigned_16) return Boolean
     with Global => State;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   --  Power-up: nothing latched, nothing read
   procedure Clear
     with Global => (Output => State),
          Post => not Override_EOA and then not Shunting_Request
                  and then not Mode_Acknowledged
                  and then Text_Ack_Count = 0;

   --  A frame of the DMI port of the documented shape
   --  (EVC_DMI_Port.Valid_Input_Frame): kept when it is one of the
   --  actions above
   procedure Latch (Frame : Byte_Array)
     with Global => (In_Out => State),
          Pre => EVC_DMI_Port.Valid_Input_Frame (Frame);

   --  The start of a cycle: the actions latched become the ones read
   procedure Take
     with Global => (In_Out => State);

end EVC_Procedure_Requests;
