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

with Interfaces; use Interfaces;

package body DMI_Link is

   Buffer : Stream_Element_Array (1 .. Capacity);
   Filled : Stream_Element_Offset := 0;

   -- bytes of an oversized frame still to be discarded
   Skip_Remaining : Unsigned_32 := 0;
   Oversized      : Natural := 0;

   -------------
   -- Process --
   -------------

   -- Dispatch complete frames from the front of the buffer
   procedure Process is
      Offset : Stream_Element_Offset;
   begin
      loop
         if Skip_Remaining > 0 then
            declare
               Chunk : constant Stream_Element_Offset :=
                 (if Unsigned_32 (Filled) < Skip_Remaining
                  then Filled
                  else Stream_Element_Offset (Skip_Remaining));
            begin
               if Filled > Chunk then
                  Buffer (1 .. Filled - Chunk) := Buffer (Chunk + 1 .. Filled);
               end if;
               Filled := Filled - Chunk;
               Skip_Remaining := Skip_Remaining - Unsigned_32 (Chunk);
            end;
            exit when Skip_Remaining > 0; -- need more bytes to finish
         end if;

         exit when Filled < Header_Length;
         Offset := Buffer'First;
         declare
            The_Type : constant Msg_Type_T :=
              Msg_Type_T (Get_U8 (Buffer, Offset));
            Length   : constant Unsigned_32 := Get_U32 (Buffer, Offset);
         begin
            -- compared before converting: a corrupted length must not
            -- overflow the offset type
            if Length > Unsigned_32 (Capacity - Header_Length) then
               Oversized := Oversized + 1;
               Skip_Remaining :=
                 Header_Length + Length - Unsigned_32 (Filled);
               Filled := 0;
            else
               declare
                  Total : constant Stream_Element_Offset :=
                    Header_Length + Stream_Element_Offset (Length);
               begin
                  exit when Filled < Total;
                  Handle (The_Type, Buffer (Header_Length + 1 .. Total));
                  if Filled > Total then
                     Buffer (1 .. Filled - Total) := Buffer (Total + 1 .. Filled);
                  end if;
                  Filled := Filled - Total;
               end;
            end if;
         end;
      end loop;
   end Process;

   ----------
   -- Feed --
   ----------

   procedure Feed (Data : Stream_Element_Array) is
      First : Stream_Element_Offset := Data'First;
   begin
      while First <= Data'Last loop
         declare
            Count : constant Stream_Element_Offset :=
              Stream_Element_Offset'Min (Capacity - Filled,
                                         Data'Last - First + 1);
         begin
            Buffer (Filled + 1 .. Filled + Count) :=
              Data (First .. First + Count - 1);
            Filled := Filled + Count;
            First := First + Count;
            -- a full buffer always holds a complete or an oversized
            -- frame, so Process frees room before the next round
            Process;
         end;
      end loop;
   end Feed;

   -----------
   -- Reset --
   -----------

   procedure Reset is
   begin
      Filled := 0;
      Skip_Remaining := 0;
   end Reset;

   function Oversized_Frames return Natural is (Oversized);

end DMI_Link;
