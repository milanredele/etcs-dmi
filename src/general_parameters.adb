pragma Ada_2012;
with Interfaces; use Interfaces;

package body General_Parameters is

   ---------------
   -- Write_RGB --
   ---------------

   procedure Write_RGB
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  RGB)
   is
      RGB_Pixel : Unsigned_32 := 0;
   begin
      RGB_Pixel := RGB_Pixel
        or Shift_Left (Unsigned_32 (Item.R), 16)
        or Shift_Left (Unsigned_32 (Item.G), 8)
        or Unsigned_32 (Item.B);
      Unsigned_32'Write (Stream, RGB_Pixel);
   end Write_RGB;

end General_Parameters;
