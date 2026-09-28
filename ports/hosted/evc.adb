--  ETCS on-board (EVC)
--  Hosted main of the on-board: connects to the test hub (tcp 1338, the
--  port of evc_sim, which it replaces on the bench) and runs EVC_Core at
--  10 Hz in the environment of the bench (sim/sim_onboard_env.ads): the
--  balise groups of the demo line, the odometer, the train interface and
--  the train, the JRU sink. What arrives from the hub goes to the
--  environment (DMI frames to the on-board's DMI port, MSG_DESK to the
--  driver desk: throttle and auto-drive); the on-board's DMI frames go
--  to the hub, with the track strip frames of the browser client
--  (MSG_SIM_STATE every cycle, MSG_TRACK_LAYOUT every 2 s) as evc_sim
--  sends them.
--
--  This is the only place of the on-board where GNAT.Sockets appears:
--  EVC_Core only sees bytes.

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Streams;   use Ada.Streams;
with DMI_Protocol;  use DMI_Protocol;
with GNAT.Sockets;  use GNAT.Sockets;
with Sim_Onboard_Env;
with Sim_Trackside;

procedure Evc is

   Client  : Socket_Type;
   Address : Sock_Addr_Type;
   Channel : Stream_Access;

   Period    : constant := 100;  -- ms
   Next_Step : Time := Clock;

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
         Sim_Onboard_Env.Receive (Chunk (Chunk'First .. Last));
      end loop;
   end Receive_Available;

   Frames : Stream_Element_Array (1 .. 16_384);
   Last   : Stream_Element_Offset;

   --  One frame of the track strip
   procedure Send_Sim (The_Type : Msg_Type_T;
                       Payload  : Stream_Element_Array) is
      Header : Stream_Element_Array (1 .. Header_Length);
      Offset : Stream_Element_Offset := Header'First;
   begin
      Put_Header (Header, Offset, The_Type, Payload'Length);
      Ada.Streams.Write (Channel.all, Header);
      Ada.Streams.Write (Channel.all, Payload);
   end Send_Sim;

   Layout_Countdown : Natural := 0;
   Sim_Payload      : Stream_Element_Array (1 .. 256);
   Sim_Last         : Stream_Element_Offset;

begin
   Sim_Onboard_Env.Reset;

   Create_Socket (Client);
   Address.Addr := Inet_Addr ("127.0.0.1");
   Address.Port := 1338;
   Connect_Socket (Client, Address);
   Channel := Stream (Client);

   loop
      begin
         Receive_Available;
         Sim_Onboard_Env.Step (Period);
      exception
         when Socket_Error =>
            raise; -- the hub is gone: end the program
         when others =>
            --  a defect inside the on-board or its environment: the
            --  on-board falls silent (EVC_Core.Enter_Failure), the DMI
            --  shows SF, the train interface applies the emergency brake
            Sim_Onboard_Env.Enter_Failure;
      end;

      Sim_Onboard_Env.Take_DMI (Frames, Last);
      if Last >= Frames'First then
         Ada.Streams.Write (Channel.all, Frames (Frames'First .. Last));
      end if;
      Sim_Onboard_Env.Sim_State_Payload (Sim_Payload, Sim_Last);
      Send_Sim (MSG_SIM_STATE, Sim_Payload (1 .. Sim_Last));
      if Layout_Countdown = 0 then
         Sim_Trackside.Layout_Payload (Sim_Payload, Sim_Last);
         Send_Sim (MSG_TRACK_LAYOUT, Sim_Payload (1 .. Sim_Last));
         Layout_Countdown := 20;
      else
         Layout_Countdown := Layout_Countdown - 1;
      end if;

      Next_Step := Next_Step + Milliseconds (Period);
      delay until Next_Step;
   end loop;
end Evc;
