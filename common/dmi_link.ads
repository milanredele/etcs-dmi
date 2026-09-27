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

--  Reassembly of protocol v2 frames from an arbitrary byte stream. The
--  transport (TCP socket, WebAssembly host, Ethernet driver on the
--  target) hands over whatever it received, in whatever chunks; every
--  complete frame is passed to Handle. Frames larger than the buffer are
--  discarded whole so that a big message (e.g. a screen frame echoed by a
--  hub) cannot wedge the link.

with Ada.Streams; use Ada.Streams;
with DMI_Protocol; use DMI_Protocol;

generic
   with procedure Handle (The_Type : Msg_Type_T;
                          Payload  : Stream_Element_Array);
   Capacity : Stream_Element_Offset := 65536;
package DMI_Link is

   -- Append received bytes and dispatch every complete frame
   procedure Feed (Data : Stream_Element_Array);

   -- Forget any partially received frame
   procedure Reset;

   -- Frames discarded because they exceeded Capacity
   function Oversized_Frames return Natural;

end DMI_Link;
