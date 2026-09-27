--  ETCS on-board (EVC)
--  Hosted main of the on-board: connects to the test hub (tcp 1338, the
--  port of evc_sim, which it replaces on the bench), runs EVC_Core at
--  10 Hz and exchanges the frames of the DMI protocol v2 with the DMI.
--  Only the DMI port is wired in phase E0: what arrives from the hub
--  goes to the DMI port of the on-board, what the on-board outputs on
--  its DMI port goes to the hub. The other ports have no source on the
--  bench yet; the bench desk (MSG_DESK: throttle and auto-drive) drives
--  the simulated train of evc_sim and is ignored here.
--
--  This is the only place of the on-board where Ada.Streams and
--  GNAT.Sockets appear: EVC_Core only sees bytes.

with EVC_Bytes;
with EVC_Core;
with EVC_Outbox;
with EVC_Ports;

with GNAT.Sockets;  use GNAT.Sockets;
with Ada.Streams;   use Ada.Streams;
with Ada.Real_Time; use Ada.Real_Time;

with DMI_Link;
with DMI_Protocol; use DMI_Protocol;

procedure Evc is
   use type EVC_Bytes.Byte;

   Client  : Socket_Type;
   Address : Sock_Addr_Type;
   Channel : Stream_Access;

   Period    : constant := 100;  -- ms
   Next_Step : Time := Clock;

   --  A frame from the hub, whole again (DMI_Link), to the DMI port.
   --  The on-board checks the shape; frames larger than its DMI port
   --  (the screen frames a hub may echo) are not even copied.
   procedure Handle (The_Type : Msg_Type_T;
                     Payload  : Stream_Element_Array) is
   begin
      if The_Type = MSG_DESK
        or else Payload'Length > EVC_Ports.DMI_Max_Length - Header_Length
      then
         return;
      end if;
      declare
         Frame  : EVC_Bytes.Byte_Array
           (1 .. Header_Length + Natural (Payload'Length));
         Header : Stream_Element_Array (1 .. Header_Length);
         Offset : Stream_Element_Offset := Header'First;
      begin
         Put_Header (Header, Offset, The_Type, Payload'Length);
         for I in Header'Range loop
            Frame (Natural (I)) := EVC_Bytes.Byte (Header (I));
         end loop;
         for I in Payload'Range loop
            Frame (Header_Length + Natural (I - Payload'First) + 1) :=
              EVC_Bytes.Byte (Payload (I));
         end loop;
         EVC_Core.Handle_Input (EVC_Ports.DMI, Frame);
      end;
   end Handle;

   package Link is new DMI_Link (Handle);
   Chunk : Stream_Element_Array (1 .. 4096);

   procedure Receive_Available is
      Request : Request_Type (N_Bytes_To_Read);
      Last    : Stream_Element_Offset;
   begin
      loop
         Control_Socket (Client, Request);
         exit when Request.Size = 0;
         Receive_Socket (Client, Chunk, Last);
         exit when Last < Chunk'First; -- connection closed
         Link.Feed (Chunk (Chunk'First .. Last));
      end loop;
   end Receive_Available;

   --  The outputs of the on-board: the payloads of the DMI port records
   --  (each one whole protocol frame) go to the hub
   Outputs : EVC_Bytes.Byte_Array (1 .. EVC_Outbox.Capacity);
   Last    : Natural;

   procedure Send_Outputs is
      Pos    : Natural := Outputs'First;
      Length : Natural;
   begin
      EVC_Core.Take_Outputs (Outputs, Last);
      while Last - Pos + 1 >= EVC_Outbox.Record_Header loop
         Length := Natural (Outputs (Pos + 1))
                   + 256 * Natural (Outputs (Pos + 2));
         exit when Pos + EVC_Outbox.Record_Header + Length - 1 > Last;
         if Outputs (Pos) = EVC_Ports.Port_T'Pos (EVC_Ports.DMI) then
            declare
               Bytes : Stream_Element_Array
                 (1 .. Stream_Element_Offset (Length));
            begin
               for I in Bytes'Range loop
                  Bytes (I) := Stream_Element
                    (Outputs (Pos + EVC_Outbox.Record_Header
                              + Natural (I) - 1));
               end loop;
               Ada.Streams.Write (Channel.all, Bytes);
            end;
         end if;
         Pos := Pos + EVC_Outbox.Record_Header + Length;
      end loop;
   end Send_Outputs;

begin
   EVC_Core.Initialise;

   Create_Socket (Client);
   Address.Addr := Inet_Addr ("127.0.0.1");
   Address.Port := 1338;
   Connect_Socket (Client, Address);
   Channel := Stream (Client);

   loop
      begin
         Receive_Available;
         EVC_Core.Tick (Period);
      exception
         when Socket_Error =>
            raise; -- the hub is gone: end the program
         when others =>
            --  a defect inside the on-board: it falls silent
            --  (EVC_Core.Enter_Failure), the DMI shows SF
            EVC_Core.Enter_Failure;
      end;
      Send_Outputs;

      Next_Step := Next_Step + Milliseconds (Period);
      delay until Next_Step;
   end loop;
end Evc;
