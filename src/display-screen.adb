--  ETCS DMI
--  Single full-screen frame buffer implementation.

pragma Ada_2012;
with Ada.Streams.Stream_IO;
with Ada.Unchecked_Conversion;
with DMI_Protocol; use DMI_Protocol;
with Interfaces;   use Interfaces;
with System;

package body Display.Screen is

   Width  : constant Natural := General_Parameters.Display_Resolution.Width;
   Height : constant Natural := General_Parameters.Display_Resolution.Height;

   type Buffer_T is array (Natural range 0 .. Width * Height - 1)
     of General_Parameters.Color;

   Buffer : Buffer_T := (others => General_Parameters.Background_Color);

   function Get_Pixel (X : Screen_X_T; Y : Screen_Y_T)
                       return General_Parameters.Color is
     (Buffer (X + Y * Width));

   procedure Set_Pixel (X : Screen_X_T;
                        Y : Screen_Y_T;
                        The_Color : General_Parameters.Color) is
   begin
      Buffer (X + Y * Width) := The_Color;
   end Set_Pixel;

   procedure Fill (The_Color : General_Parameters.Color) is
   begin
      Buffer := (others => The_Color);
   end Fill;

   procedure Fill_Area (The_Area : Area_T; The_Color : General_Parameters.Color) is
   begin
      for Y in The_Area.Position.Y .. The_Area.Position.Y + The_Area.Height - 1 loop
         for X in The_Area.Position.X .. The_Area.Position.X + The_Area.Width - 1 loop
            Set_Pixel (X, Y, The_Color);
         end loop;
      end loop;
   end Fill_Area;

   procedure Write_Raw (Stream : not null access Ada.Streams.Root_Stream_Type'Class) is
      use type Ada.Streams.Stream_Element_Offset;

      Item_Size : constant Ada.Streams.Stream_Element_Offset :=
        Buffer_T'Object_Size / Ada.Streams.Stream_Element'Size;

      type SEA_Pointer is
        access all Ada.Streams.Stream_Element_Array (1 .. Item_Size);

      function As_SEA_Pointer is
        new Ada.Unchecked_Conversion (System.Address, SEA_Pointer);
   begin
      Ada.Streams.Write (Stream.all, As_SEA_Pointer (Buffer'Address).all);
   end Write_Raw;

   procedure Write (Stream : not null access Ada.Streams.Root_Stream_Type'Class) is
      use type Ada.Streams.Stream_Element_Offset;
      Frame_Header_Length : constant := 8; -- x, y, w, h as u16
      Header : Ada.Streams.Stream_Element_Array
        (1 .. Header_Length + Frame_Header_Length);
      Offset : Ada.Streams.Stream_Element_Offset := Header'First;
   begin
      Put_Header (Header, Offset, MSG_FRAME,
                  Frame_Header_Length + Buffer'Length);
      Put_U16 (Header, Offset, 0);
      Put_U16 (Header, Offset, 0);
      Put_U16 (Header, Offset, Unsigned_16 (Width));
      Put_U16 (Header, Offset, Unsigned_16 (Height));
      Ada.Streams.Write (Stream.all, Header);
      Write_Raw (Stream);
   end Write;

   procedure Dump (File_Name : String) is
      Output_File   : Ada.Streams.Stream_IO.File_Type;
      Output_Stream : Ada.Streams.Stream_IO.Stream_Access;
   begin
      Ada.Streams.Stream_IO.Create (File => Output_File,
                                    Mode => Ada.Streams.Stream_IO.Out_File,
                                    Name => File_Name);
      Output_Stream := Ada.Streams.Stream_IO.Stream (Output_File);
      Write_Raw (Ada.Streams.Root_Stream_Type'Class (Output_Stream.all)'Access);
      Ada.Streams.Stream_IO.Close (Output_File);
   end Dump;

   function Matches_Dump (File_Name : String) return Boolean is
      use Ada.Streams;
      use type Ada.Streams.Stream_Element_Offset;
      Input_File : Stream_IO.File_Type;
      Chunk      : Stream_Element_Array (1 .. 4096);
      Last       : Stream_Element_Offset;
      Index      : Natural := Buffer'First;
      Matches    : Boolean := True;
   begin
      Stream_IO.Open (File => Input_File,
                      Mode => Stream_IO.In_File,
                      Name => File_Name);
      while Matches and then not Stream_IO.End_Of_File (Input_File) loop
         Stream_IO.Read (Input_File, Chunk, Last);
         for I in Chunk'First .. Last loop
            if Index > Buffer'Last
              or else General_Parameters.Color'Pos (Buffer (Index)) /=
                      Natural (Chunk (I))
            then
               Matches := False;
               exit;
            end if;
            Index := Index + 1;
         end loop;
      end loop;
      Stream_IO.Close (Input_File);
      return Matches and then Index = Buffer'Last + 1;
   exception
      when others =>
         if Stream_IO.Is_Open (Input_File) then
            Stream_IO.Close (Input_File);
         end if;
         return False;
   end Matches_Dump;

end Display.Screen;
