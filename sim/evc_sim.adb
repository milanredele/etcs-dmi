--  ETCS DMI test simulator
--  Live EVC simulator: connects to the test hub (tcp 1338), steps the
--  track/train/EVC model at 10 Hz and exchanges protocol v2 messages
--  with the DMI. Driver desk input arrives as MSG_DESK from the browser
--  (throttle demand and auto-drive), driver actions from the DMI.

with EVC_Core;
with EVC_Train;

with GNAT.Sockets;  use GNAT.Sockets;
with Ada.Streams;   use Ada.Streams;
with Ada.Real_Time; use Ada.Real_Time;

with DMI_Protocol; use DMI_Protocol;
with Interfaces;   use Interfaces;

procedure EVC_Sim is
   Client  : Socket_Type;
   Address : Sock_Addr_Type;
   Channel : Stream_Access;

   Next_Step     : Time := Clock;
   Step_Interval : constant Time_Span := Milliseconds (100);

   Auto_Drive : Boolean := True;

   Rx        : Stream_Element_Array (1 .. 65536);
   Rx_Filled : Stream_Element_Offset := 0;

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

   procedure Receive_Available is
      Request : Request_Type (N_Bytes_To_Read);
      Last    : Stream_Element_Offset;
   begin
      loop
         Control_Socket (Client, Request);
         exit when Request.Size = 0 or Rx_Filled >= Rx'Last;
         Receive_Socket (Client, Rx (Rx_Filled + 1 .. Rx'Last), Last);
         exit when Last <= Rx_Filled;
         Rx_Filled := Last;
      end loop;
   end Receive_Available;

   -- bytes of an oversized message still to be discarded
   Skip_Remaining : Stream_Element_Offset := 0;

   procedure Process_Frames is
      Offset : Stream_Element_Offset;
   begin
      loop
         -- discard the tail of a message that exceeded the buffer
         if Skip_Remaining > 0 then
            declare
               Chunk : constant Stream_Element_Offset :=
                 Stream_Element_Offset'Min (Skip_Remaining, Rx_Filled);
            begin
               if Rx_Filled > Chunk then
                  Rx (Rx'First .. Rx_Filled - Chunk) :=
                    Rx (Chunk + 1 .. Rx_Filled);
               end if;
               Rx_Filled := Rx_Filled - Chunk;
               Skip_Remaining := Skip_Remaining - Chunk;
            end;
            exit when Skip_Remaining > 0; -- need more data to finish
         end if;

         exit when Rx_Filled < Header_Length;
         Offset := Rx'First;
         declare
            The_Type : constant Msg_Type_T :=
              Msg_Type_T (Get_U8 (Rx, Offset));
            Length   : constant Stream_Element_Offset :=
              Stream_Element_Offset (Get_U32 (Rx, Offset));
            Total    : constant Stream_Element_Offset := Header_Length + Length;
         begin
            if Total > Rx'Length then
               -- larger than the buffer can ever hold (e.g. a screen
               -- frame): skip the whole message
               Skip_Remaining := Total - Rx_Filled;
               Rx_Filled := 0;
            else
               exit when Rx_Filled < Total;
               Handle (The_Type, Rx (Rx'First + Header_Length .. Total));
               if Rx_Filled > Total then
                  Rx (Rx'First .. Rx_Filled - Total) :=
                    Rx (Total + 1 .. Rx_Filled);
               end if;
               Rx_Filled := Rx_Filled - Total;
            end if;
         end;
      end loop;
   end Process_Frames;

   use type EVC_Core.Mode_T;
begin
   Create_Socket (Client);
   Address.Addr := Inet_Addr ("127.0.0.1");
   Address.Port := 1338;
   Connect_Socket (Client, Address);
   Channel := Stream (Client);

   loop
      Receive_Available;
      Process_Frames;

      -- simple auto driver: hold a few km/h below the permitted speed
      -- and brake to a stand once in release speed monitoring
      if Auto_Drive and then EVC_Core.Mode = EVC_Core.FS then
         if EVC_Core.Monitoring = 2 then
            EVC_Train.Demand := -100;
         elsif EVC_Train.Speed_KMH + 3 < EVC_Core.Permitted_Speed then
            EVC_Train.Demand := 60;
         elsif EVC_Train.Speed_KMH + 1 >= EVC_Core.Permitted_Speed then
            EVC_Train.Demand := -80;
         else
            EVC_Train.Demand := 0;
         end if;
      end if;

      EVC_Core.Step (0.1, Emit'Unrestricted_Access);

      Next_Step := Next_Step + Step_Interval;
      delay until Next_Step;
   end loop;
end EVC_Sim;
