--  ETCS DMI test simulator
--  WebAssembly host interface of the EVC / track / train simulator. The
--  page steps the model and moves protocol frames between this module
--  and the DMI module through its simulated wire; the driver desk is
--  local to the simulator.

with Interfaces; use Interfaces;
with System;

package EVC_Wasm is

   -- Back to the start of the mission
   procedure Reset
     with Export, Convention => C, Link_Name => "evc_reset";

   -- Receive path (frames from the DMI): the host writes up to
   -- Rx_Capacity bytes at Rx_Buffer and calls Receive with the count
   function Rx_Buffer return System.Address
     with Export, Convention => C, Link_Name => "evc_rx_buffer";
   function Rx_Capacity return Unsigned_32
     with Export, Convention => C, Link_Name => "evc_rx_capacity";
   procedure Receive (Length : Unsigned_32)
     with Export, Convention => C, Link_Name => "evc_receive";

   -- Driver desk: traction/brake demand in -100 .. 100, automatic
   -- driving overrides the demand while enabled
   procedure Set_Desk (Demand : Integer_32; Auto_Drive : Integer_32)
     with Export, Convention => C, Link_Name => "evc_set_desk";

   -- Advance the simulation by Dt_Ms milliseconds; the messages for
   -- the DMI and the visualisation are queued for Transmit
   procedure Step (Dt_Ms : Unsigned_32)
     with Export, Convention => C, Link_Name => "evc_step";

   -- Transmit path: Transmit fills Tx_Buffer with the queued protocol
   -- frames and returns the byte count
   function Tx_Buffer return System.Address
     with Export, Convention => C, Link_Name => "evc_tx_buffer";
   function Transmit return Unsigned_32
     with Export, Convention => C, Link_Name => "evc_transmit";

end EVC_Wasm;
