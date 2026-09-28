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
--
--  The installation configuration (evc/evc_config.ads) is a byte image
--  in a file, given with --config <file> or in the environment variable
--  EVC_CONFIG (the option wins); test/tools/evc_config.py makes it from
--  the text form (ports/hosted/evc.cfg is the default). The on-board
--  loads it before its power-up (EVC_Core.Configure); an image it
--  refuses stops the program with the reason on stderr. Without either,
--  the on-board runs with EVC_Config.Default.
--
--  Usage: obj/evc_onboard [--config <image>]

with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Streams;   use Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;
with DMI_Protocol;  use DMI_Protocol;
with EVC_Bytes;
with EVC_Config;
with EVC_Core;
with GNAT.Sockets;  use GNAT.Sockets;
with Sim_Onboard_Env;
with Sim_Trackside;

procedure Evc is

   use type Ada.Directories.File_Kind;
   use type Ada.Directories.File_Size;
   use type EVC_Config.Status_T;

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

   --  The command line: nothing, or --config <image>
   function Usage_OK return Boolean is
     (Ada.Command_Line.Argument_Count = 0
      or else (Ada.Command_Line.Argument_Count = 2
               and then Ada.Command_Line.Argument (1) = "--config"));

   --  The configuration file of the command line or of EVC_CONFIG, ""
   --  when there is none
   function Config_Path return String is
     (if Ada.Command_Line.Argument_Count = 2
      then Ada.Command_Line.Argument (2)
      elsif Ada.Environment_Variables.Exists ("EVC_CONFIG")
      then Ada.Environment_Variables.Value ("EVC_CONFIG")
      else "");

   --  Load the image of Path into the on-board: False (and the reason on
   --  stderr) when it cannot be read or the on-board refuses it
   function Configure (Path : String) return Boolean is
      use Ada.Streams.Stream_IO;
      Max  : constant := 65_536;
      File : File_Type;
   begin
      if not Ada.Directories.Exists (Path)
        or else Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File
        or else Ada.Directories.Size (Path) > Max
      then
         Ada.Text_IO.Put_Line
           (Ada.Text_IO.Standard_Error,
            "evc_onboard: " & Path & ": no such file, or larger than"
            & Natural'Image (Max) & " bytes");
         return False;
      end if;
      Open (File, In_File, Path);
      declare
         Data  : Stream_Element_Array
           (1 .. Stream_Element_Offset (Size (File)));
         Last  : Stream_Element_Offset;
         Image : EVC_Bytes.Byte_Array (1 .. Data'Length);
      begin
         Read (File, Data, Last);
         Close (File);
         for I in 1 .. Natural (Last) loop
            Image (I) := EVC_Bytes.Byte (Data (Stream_Element_Offset (I)));
         end loop;
         EVC_Core.Configure (Image (1 .. Natural (Last)));
      end;
      if EVC_Config.Last_Status /= EVC_Config.Accepted then
         Ada.Text_IO.Put_Line
           (Ada.Text_IO.Standard_Error,
            "evc_onboard: " & Path & ": configuration refused ("
            & EVC_Config.Status_T'Image (EVC_Config.Last_Status) & ")");
         return False;
      end if;
      Ada.Text_IO.Put_Line ("evc_onboard: configuration " & Path);
      return True;
   end Configure;

begin
   if not Usage_OK then
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,
                            "usage: evc_onboard [--config <image>]");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;
   if Config_Path /= "" and then not Configure (Config_Path) then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;
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
