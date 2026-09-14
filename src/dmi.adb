--  ETCS DMI
--  Copyright (C) 2019  Milan Redele
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.

--  Main entry point for the live DMI: connects to the test hub over TCP,
--  consumes protocol v2 messages and streams the rendered screen back.

with DMI_Core;
with DMI_Link;
with Display.Screen;
with General_Parameters;

with GNAT.Sockets;  use GNAT.Sockets;
with Ada.Streams;   use Ada.Streams;
with Ada.Real_Time; use Ada.Real_Time;

procedure Dmi is
   Client  : Socket_Type;
   Address : Sock_Addr_Type;
   Channel : Stream_Access;

   Next_Frame     : Time := Clock;
   Frame_Interval : constant Time_Span := Milliseconds (50);

   Last_Flash     : Time := Clock;
   -- DMI 5.1.1.3.2: flashing frames toggle every 0.25 seconds
   Flash_Interval : constant Time_Span := Milliseconds (250);

   -- Incoming frame reassembly
   package Link is new DMI_Link (DMI_Core.Handle_Message);
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
   DMI_Core.Initialise;

   Create_Socket (Client);
   Address.Addr := Inet_Addr ("127.0.0.1");
   Address.Port := 1337;

   Connect_Socket (Client, Address);
   Channel := Stream (Client);

   loop
      -- 1. Consume everything the EVC / UI sent us
      Receive_Available;

      -- 2. Advance time dependent state (flashing, buttons)
      if Clock - Last_Flash >= Flash_Interval then
         General_Parameters.Flash_On := not General_Parameters.Flash_On;
         Last_Flash := Clock;
      end if;
      DMI_Core.Tick (50);

      -- 3. Render and transmit one full screen
      DMI_Core.Render;
      Display.Screen.Write (Ada.Streams.Root_Stream_Type'Class (Channel.all)'Access);

      -- 4. Send pending outbound messages (driver actions, sounds)
      DMI_Core.Flush_Outbox (Ada.Streams.Root_Stream_Type'Class (Channel.all)'Access);

      -- 5. Precise frame timing
      Next_Frame := Next_Frame + Frame_Interval;
      delay until Next_Frame;
   end loop;
end Dmi;
