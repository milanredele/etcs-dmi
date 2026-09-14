--  ETCS DMI test simulator
--  Live EVC simulator: connects to the test hub (tcp 1338), steps the
--  track/train/EVC model at 10 Hz and exchanges protocol v2 messages
--  with the DMI. Driver desk input arrives as MSG_DESK from the browser
--  (throttle demand and auto-drive), driver actions from the DMI.

with EVC_Core;
with EVC_Driver;
with EVC_Train;

with GNAT.Sockets;  use GNAT.Sockets;
with Ada.Streams;   use Ada.Streams;
with Ada.Real_Time; use Ada.Real_Time;

with DMI_Link;
with DMI_Protocol; use DMI_Protocol;
with Interfaces;   use Interfaces;

procedure EVC_Sim is
   Client  : Socket_Type;
   Address : Sock_Addr_Type;
   Channel : Stream_Access;

   Next_Step     : Time := Clock;
   Step_Interval : constant Time_Span := Milliseconds (100);

   Auto_Drive : Boolean := True;

   procedure Emit (The_Type : Msg_Type_T;
                   Payload  : Stream_Element_Array) is
      Header : Stream_Element_Array (1 .. Header_Length);
      Offset : Stream_Element_Offset := Header'First;
   begin
      Put_Header (Header, Offset, The_Type, Payload'Length);
      Ada.Streams.Write (Channel.all, Header);
      Ada.Streams.Write (Channel.all, Payload);
   end Emit;

   procedure Handle (The_Type : Msg_Type_T;
                     Payload  : Stream_Element_Array) is
      Offset : Stream_Element_Offset := Payload'First;
   begin
      case The_Type is
         when MSG_DRIVER_ACTION =>
            if Payload'Length = Driver_Action_Length then
               declare
                  Action : constant Unsigned_8 := Get_U8 (Payload, Offset);
                  Arg    : constant Unsigned_16 := Get_U16 (Payload, Offset);
               begin
                  EVC_Core.Handle_Driver_Action
                    (Natural (Action), Natural (Arg));
               end;
            end if;
         when MSG_DESK =>
            if Payload'Length = Desk_Length then
               declare
                  Demand : constant Unsigned_8 := Get_U8 (Payload, Offset);
                  Auto   : constant Unsigned_8 := Get_U8 (Payload, Offset);
               begin
                  Auto_Drive := Auto /= 0;
                  if not Auto_Drive then
                     EVC_Train.Demand :=
                       (if Demand >= 128
                        then Integer (Demand) - 256
                        else Integer (Demand));
                  end if;
               end;
            end if;
         when others =>
            null; -- frames, sounds etc. pass by
      end case;
   end Handle;

   -- Incoming frame reassembly; a hub may echo 300 kB screen frames,
   -- the link skips anything larger than its buffer
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

begin
   Create_Socket (Client);
   Address.Addr := Inet_Addr ("127.0.0.1");
   Address.Port := 1338;
   Connect_Socket (Client, Address);
   Channel := Stream (Client);

   loop
      Receive_Available;

      if Auto_Drive then
         EVC_Driver.Auto_Drive;
      end if;

      EVC_Core.Step (0.1, Emit'Unrestricted_Access);

      Next_Step := Next_Step + Step_Interval;
      delay until Next_Step;
   end loop;
end EVC_Sim;
