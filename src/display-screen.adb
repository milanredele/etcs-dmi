--  ETCS DMI
--  Single full-screen frame buffer implementation.

pragma Ada_2012;
with Ada.Unchecked_Conversion;
with DMI_Protocol; use DMI_Protocol;
with Interfaces;   use Interfaces;

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

   function Frame_Address return System.Address is (Buffer'Address);

end Display.Screen;
