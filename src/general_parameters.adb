pragma Ada_2012;
with Interfaces; use Interfaces;

package body General_Parameters is


   procedure Write_Color
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  Color)
   is
   begin
      RGB'Write (Stream, RGB_Colors (Item));
   end Write_Color;

   ---------------
   -- Write_RGB --
   ---------------

   procedure Write_RGB
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  RGB) is
   begin
        Unsigned_8'Write (Stream, Unsigned_8 (Item.R));
        Unsigned_8'Write (Stream, Unsigned_8 (Item.G));
        Unsigned_8'Write (Stream, Unsigned_8 (Item.B));
   end Write_RGB;

end General_Parameters;
