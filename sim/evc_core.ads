--  ETCS DMI test simulator
--  Simplified EVC: braking curve supervision (constant deceleration),
--  CSM/TSM/RSM transitions, mode/level state machine, track condition
--  and text message generation. Emits protocol v2 messages through a
--  caller-provided sink so it runs over TCP (evc_sim) or in process
--  (regression runner).

with Ada.Streams; use Ada.Streams;
with DMI_Protocol; use DMI_Protocol;

package EVC_Core is

   type Sink_T is access procedure (The_Type : Msg_Type_T;
                                    Payload  : Stream_Element_Array);

   type Mode_T is (SB, SR, FS, TR);

   Mode : Mode_T := SB;

   -- Advance the simulation by Dt_S and emit the DMI state
   procedure Step (Dt_S : Float; Emit : Sink_T);

   -- Driver actions coming back from the DMI
   -- ID: only with action 2 (acknowledgement), the id of the acknowledged
   -- text message (DMI_Protocol.MSG_DRIVER_ACTION)
   procedure Handle_Driver_Action (Action : Natural;
                                   Arg    : Natural;
                                   ID     : Natural := 0);

   -- The driver's data as the DMI reports them (MSG_DRIVER_DATA). The
   -- on-board stores them and their status becomes "valid"
   -- (SUBSET-026 3.18.3, 3.18.4); the DMI is told so in MSG_ONBOARD and
   -- evaluates Tables 33 to 36 with it. Any payload is accepted; one
   -- that does not match the documented shape is ignored.
   procedure Handle_Driver_Data (Payload : Stream_Element_Array);

   procedure Reset;

   -- Introspection for scenario assertions
   function Monitoring return Natural;       -- 0 CSM / 1 TSM / 2 RSM
   function Permitted_Speed return Natural;  -- km/h at the current position
   function Mode_Ack_Pending return Boolean;

end EVC_Core;
