--  ETCS DMI test simulator
--  WebAssembly host interface implementation.

with Ada.Streams;  use Ada.Streams;
with DMI_Link;
with DMI_Protocol; use DMI_Protocol;
with EVC_Core;
with EVC_Driver;
with EVC_Train;

package body EVC_Wasm is

   Rx : Stream_Element_Array (1 .. 4096);
   Tx : Stream_Element_Array (1 .. 8192);
   Tx_Filled : Stream_Element_Offset := 0;

   Auto : Boolean := True;

   -- Sink for EVC_Core: frames accumulate until the host collects them
   procedure Emit (The_Type : Msg_Type_T;
                   Payload  : Stream_Element_Array) is
      Needed : constant Stream_Element_Offset :=
        Header_Length + Payload'Length;
      Offset : Stream_Element_Offset := Tx_Filled + 1;
   begin
      if Tx_Filled + Needed > Tx'Last then
         return; -- host did not collect in time; drop
      end if;
      Put_Header (Tx, Offset, The_Type, Payload'Length);
      Tx (Offset .. Offset + Payload'Length - 1) := Payload;
      Tx_Filled := Tx_Filled + Needed;
   end Emit;

   procedure Handle (The_Type : Msg_Type_T;
                     Payload  : Stream_Element_Array) is
      Offset : Stream_Element_Offset := Payload'First;
   begin
      if The_Type = MSG_DRIVER_ACTION
        and then Payload'Length = Driver_Action_Length
      then
         declare
            Action : constant Unsigned_8 := Get_U8 (Payload, Offset);
            Arg    : constant Unsigned_16 := Get_U16 (Payload, Offset);
         begin
            EVC_Core.Handle_Driver_Action (Natural (Action), Natural (Arg));
         end;
      end if;
   end Handle;

   package Link is new DMI_Link (Handle, Capacity => 4096);

   procedure Reset is
   begin
      EVC_Core.Reset;
      Link.Reset;
      Tx_Filled := 0;
      Auto := True;
   end Reset;

   function Rx_Buffer return System.Address is (Rx'Address);
   function Rx_Capacity return Unsigned_32 is (Rx'Length);

   procedure Receive (Length : Unsigned_32) is
   begin
      if Length in 1 .. Rx'Length then
         Link.Feed (Rx (1 .. Stream_Element_Offset (Length)));
      end if;
   end Receive;

   procedure Set_Desk (Demand : Integer_32; Auto_Drive : Integer_32) is
   begin
      Auto := Auto_Drive /= 0;
      if not Auto and then Demand in -100 .. 100 then
         EVC_Train.Demand := Integer (Demand);
      end if;
   end Set_Desk;

   procedure Step (Dt_Ms : Unsigned_32) is
   begin
      if Auto then
         EVC_Driver.Auto_Drive;
      end if;
      EVC_Core.Step (Float (Dt_Ms) / 1000.0, Emit'Access);
   end Step;

   function Tx_Buffer return System.Address is (Tx'Address);

   function Transmit return Unsigned_32 is
      Count : constant Stream_Element_Offset := Tx_Filled;
   begin
      Tx_Filled := 0;
      return Unsigned_32 (Count);
   end Transmit;

end EVC_Wasm;
