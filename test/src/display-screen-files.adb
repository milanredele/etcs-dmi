--  ETCS DMI
--  Host side helpers over the screen buffer, implementation.

with Ada.Streams.Stream_IO;
with Ada.Unchecked_Conversion;
with GNAT.SHA256;
with System;

package body Display.Screen.Files is

   use type Ada.Streams.Stream_Element_Offset;

   subtype Frame_Bytes_T is
     Ada.Streams.Stream_Element_Array
       (1 .. Ada.Streams.Stream_Element_Offset (Frame_Size));
   type Frame_Bytes_Access is access all Frame_Bytes_T;

   function To_Bytes is
     new Ada.Unchecked_Conversion (System.Address, Frame_Bytes_Access);

   ----------
   -- Dump --
   ----------

   procedure Dump (File_Name : String) is
      Output_File   : Ada.Streams.Stream_IO.File_Type;
      Output_Stream : Ada.Streams.Stream_IO.Stream_Access;
   begin
      Ada.Streams.Stream_IO.Create (File => Output_File,
                                    Mode => Ada.Streams.Stream_IO.Out_File,
                                    Name => File_Name);
      Output_Stream := Ada.Streams.Stream_IO.Stream (Output_File);
      Write_Raw (Output_Stream);
      Ada.Streams.Stream_IO.Close (Output_File);
   end Dump;

   ------------
   -- Digest --
   ------------

   function Digest return String is
      Context : GNAT.SHA256.Context := GNAT.SHA256.Initial_Context;
   begin
      GNAT.SHA256.Update (Context, To_Bytes (Frame_Address).all);
      return GNAT.SHA256.Digest (Context);
   end Digest;

   ------------------
   -- Matches_Dump --
   ------------------

   function Matches_Dump (File_Name : String) return Boolean is
      use Ada.Streams;
      Frame      : Frame_Bytes_T renames To_Bytes (Frame_Address).all;
      Input_File : Stream_IO.File_Type;
      Chunk      : Stream_Element_Array (1 .. 4096);
      Last       : Stream_Element_Offset;
      Index      : Stream_Element_Offset := Frame'First;
      Matches    : Boolean := True;
   begin
      Stream_IO.Open (File => Input_File,
                      Mode => Stream_IO.In_File,
                      Name => File_Name);
      while Matches and then not Stream_IO.End_Of_File (Input_File) loop
         Stream_IO.Read (Input_File, Chunk, Last);
         for I in Chunk'First .. Last loop
            if Index > Frame'Last or else Frame (Index) /= Chunk (I) then
               Matches := False;
               exit;
            end if;
            Index := Index + 1;
         end loop;
      end loop;
      Stream_IO.Close (Input_File);
      return Matches and then Index = Frame'Last + 1;
   exception
      when others =>
         if Stream_IO.Is_Open (Input_File) then
            Stream_IO.Close (Input_File);
         end if;
         return False;
   end Matches_Dump;

end Display.Screen.Files;
