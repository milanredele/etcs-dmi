--  ETCS DMI
--  WebAssembly host interface implementation.

with Ada.Streams; use Ada.Streams;
with DMI_Core;
with DMI_Link;
with Display.Screen;
with General_Parameters;

package body DMI_Wasm is

   package Link is new DMI_Link (DMI_Core.Handle_Message);

   Rx : Stream_Element_Array (1 .. 16384);
   Tx : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);

   -- DMI 5.1.1.3.2: flashing frames toggle every 0.25 seconds
   Flash_Interval_Ms : constant := 250;
   Flash_Elapsed_Ms  : Natural := 0;

   procedure Initialise is
   begin
      DMI_Core.Initialise;
      Link.Reset;
      General_Parameters.Flash_On := True;
      Flash_Elapsed_Ms := 0;
   end Initialise;

   function Rx_Buffer return System.Address is (Rx'Address);
   function Rx_Capacity return Unsigned_32 is (Rx'Length);

   procedure Receive (Length : Unsigned_32) is
   begin
      if Length in 1 .. Rx'Length then
         Link.Feed (Rx (1 .. Stream_Element_Offset (Length)));
      end if;
   end Receive;

   procedure Tick (Dt_Ms : Unsigned_32) is
   begin
      Flash_Elapsed_Ms := Flash_Elapsed_Ms + Natural (Dt_Ms);
      while Flash_Elapsed_Ms >= Flash_Interval_Ms loop
         General_Parameters.Flash_On := not General_Parameters.Flash_On;
         Flash_Elapsed_Ms := Flash_Elapsed_Ms - Flash_Interval_Ms;
      end loop;
      DMI_Core.Tick (Natural (Dt_Ms));
   end Tick;

   procedure Render is
   begin
      DMI_Core.Render;
   end Render;

   function Frame_Address return System.Address is
     (Display.Screen.Frame_Address);
   function Frame_Width return Unsigned_32 is
     (Unsigned_32 (General_Parameters.Display_Resolution.Width));
   function Frame_Height return Unsigned_32 is
     (Unsigned_32 (General_Parameters.Display_Resolution.Height));

   function Tx_Buffer return System.Address is (Tx'Address);

   function Transmit return Unsigned_32 is
      Last : Stream_Element_Offset;
   begin
      DMI_Core.Take_Outbox (Tx, Last);
      return Unsigned_32 (Last - Tx'First + 1);
   end Transmit;

   function Link_Lost return Integer_32 is
     (if DMI_Core.EVC_Link_Lost then 1 else 0);

end DMI_Wasm;
