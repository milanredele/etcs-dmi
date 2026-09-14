--  ETCS DMI
--  WebAssembly host interface of the DMI. The browser page owns time and
--  the wire: it copies received bytes into the receive buffer and calls
--  Receive, advances the DMI with Tick, asks for a Render and reads the
--  frame buffer in place; driver actions and sounds are collected with
--  Transmit. Nothing here knows about sockets or the EVC.

with Interfaces; use Interfaces;
with System;

package DMI_Wasm is

   -- Power-up state
   procedure Initialise
     with Export, Convention => C, Link_Name => "dmi_initialise";

   -- Receive path: the host writes up to Rx_Capacity bytes at Rx_Buffer
   -- and calls Receive with the count; complete protocol frames are
   -- applied, partial ones wait for the rest
   function Rx_Buffer return System.Address
     with Export, Convention => C, Link_Name => "dmi_rx_buffer";
   function Rx_Capacity return Unsigned_32
     with Export, Convention => C, Link_Name => "dmi_rx_capacity";
   procedure Receive (Length : Unsigned_32)
     with Export, Convention => C, Link_Name => "dmi_receive";

   -- Advance time dependent behaviour (flashing, buttons, EVC link
   -- supervision) by Dt_Ms milliseconds
   procedure Tick (Dt_Ms : Unsigned_32)
     with Export, Convention => C, Link_Name => "dmi_tick";

   -- Draw the screen into the frame buffer: Frame_Width * Frame_Height
   -- colour indices, row major, one byte each, at Frame_Address
   procedure Render
     with Export, Convention => C, Link_Name => "dmi_render";
   function Frame_Address return System.Address
     with Export, Convention => C, Link_Name => "dmi_frame";
   function Frame_Width return Unsigned_32
     with Export, Convention => C, Link_Name => "dmi_frame_width";
   function Frame_Height return Unsigned_32
     with Export, Convention => C, Link_Name => "dmi_frame_height";

   -- Transmit path: Transmit fills Tx_Buffer with the pending outbound
   -- protocol frames (driver actions and data for the EVC, sounds for
   -- the display unit) and returns the byte count
   function Tx_Buffer return System.Address
     with Export, Convention => C, Link_Name => "dmi_tx_buffer";
   function Transmit return Unsigned_32
     with Export, Convention => C, Link_Name => "dmi_transmit";

   -- 1 while the EVC is considered failed (silent beyond the timeout)
   function Link_Lost return Integer_32
     with Export, Convention => C, Link_Name => "dmi_link_lost";

end DMI_Wasm;
