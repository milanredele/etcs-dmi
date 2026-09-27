--  ETCS DMI
--  Bitmap font access. Total: no index ever leaves the bitmap.

pragma Ada_2012;

package body Font is

   function Cell (The_Glyph  : Glyph;
                  The_Bitmap : Bitmap_T;
                  X, Y       : Natural) return Boolean
   is
      Pitch : constant Natural := (The_Glyph.Width + 7) / 8;
      Index : Integer;
   begin
      if X >= The_Glyph.Width or else Y >= The_Glyph.Height then
         return False;
      end if;
      Index := The_Glyph.Bitmap_Pos + Y * Pitch + X / 8;
      if Index not in The_Bitmap'Range then
         return False;
      end if;
      return (The_Bitmap (Index) and
                Byte_T (2 ** (7 - (X mod 8)))) /= 0;
   end Cell;

end Font;
