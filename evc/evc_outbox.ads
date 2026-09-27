--  ETCS on-board (EVC)
--  The bounded queue of the outputs of the on-board.
--
--  An output is a record (port, payload). The queue holds the records
--  serialised as they leave the on-board (EVC_Core.Take_Outputs):
--     port   u8  (EVC_Ports.Port_T'Pos)
--     length u16 (little endian, the payload length)
--     payload
--  Capacity bytes of static storage; a record that does not fit is
--  dropped whole and counted (Dropped), the queue never overflows.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Ports; use EVC_Ports;

package EVC_Outbox
  with SPARK_Mode => On,
       Abstract_State => Queue,
       Initializes => Queue
is

   Capacity      : constant := 2048;
   Record_Header : constant := 3;

   --  Bytes queued
   function Used return Natural
     with Global => Queue,
          Post => Used'Result <= Capacity;

   --  Records dropped because the queue was full, since the last Clear
   function Dropped return Natural
     with Global => Queue;

   procedure Clear
     with Global => (In_Out => Queue),
          Post => Used = 0 and then Dropped = 0;

   --  Queue one record, or count it as dropped when it does not fit
   procedure Put (Port : Port_T; Payload : Byte_Array)
     with Global => (In_Out => Queue),
          Pre => Payload'Length <= Max_Payload (Port),
          Post => Used >= Used'Old;

   --  Move the queued records to Buffer, as many whole records as fit,
   --  in their order; those that do not fit stay queued. Last is the
   --  index of the last byte written, Buffer'First - 1 when none: Last -
   --  (Buffer'First - 1) bytes are written.
   procedure Take (Buffer : out Byte_Array; Last : out Natural)
     with Global => (In_Out => Queue),
          Pre => Buffer'First >= 1,
          Post => Last >= Buffer'First - 1
                  and then Last - (Buffer'First - 1) <= Buffer'Length
                  and then Used <= Used'Old
                  and then (if Used'Old = 0 then Last = Buffer'First - 1);

end EVC_Outbox;
