--  ETCS DMI
--  Bitmap fonts. The packages Font.FreeSans_nn are generated from
--  FreeSans by utils/ttf2ada (utils/gen_fonts.sh drives it); the font
--  and the licence it comes under are named in README.md.

package Font is

   -- Cap height in cells (DMI 5.1.2.2.1: the height of the characters is
   -- the height of the capital characters). Fonts exist for the heights
   -- 5.1.2.2.3 asks for: 10, 12, 16, 17 and 18 (Font.FreeSans_nn);
   -- Display.Draw uses the next smaller font for the sizes in between
   -- instead of raising.
   type Size_T is range 10 .. 18;

   -- Following FreeType notation. The ranges are wide enough for the
   -- printable part of ISO 8859-1 at every size in use; ttf2ada prints
   -- the extremes it reached.
   type Glyph is
      record
         -- Left is negative for the few glyphs that reach under the one
         -- before them ('_' for instance)
         Left : Integer range -32 .. 63;
         Top  : Integer range -32 .. 63;
         Advance_X : Natural range 0 .. 63;
         Height, Width : Natural range 0 .. 63;
         -- Index of the first bitmap byte of the glyph. The largest
         -- bitmap is the 18 cell one with 6.2 kB.
         Bitmap_Pos : Positive range 1 .. 2 ** 16;
      end record
     -- 6 bytes instead of 24: the five fonts hold 1120 glyphs together
     with Pack;

   -- A code point the font has no glyph for. Display.Draw shows the
   -- replacement box for it rather than raising (8.2.3.4.1: a text
   -- message is EVC controlled).
   No_Glyph : constant Glyph :=
     (Left       => 0,
      Top        => 0,
      Advance_X  => 0,
      Height     => 0,
      Width      => 0,
      Bitmap_Pos => 1);

   function Defined (The_Glyph : Glyph) return Boolean is
     (The_Glyph.Advance_X > 0);

   type Glyph_Map is array (Wide_Character range <>) of Glyph;

   type Glyph_String is array (Positive range <>) of Glyph;

   type Byte_T is mod 2 ** 8
     with Size => 8;

   -- Glyph bitmaps, row by row, 8 cells to a byte, most significant bit
   -- first; every row starts on a byte boundary, so a row of a glyph
   -- Width cells wide takes (Width + 7) / 8 bytes. Kept as bytes, not as
   -- a packed Boolean array: GNAT builds a packed Boolean aggregate with
   -- elaboration code (241 kB of it for the 12 cell font alone), a byte
   -- aggregate is read-only data.
   type Bitmap_T is array (Positive range <>) of Byte_T;

   -- Cell (X, Y) of The_Glyph, 0 based, False outside the glyph or
   -- outside the bitmap, so that drawing stays total.
   function Cell (The_Glyph  : Glyph;
                  The_Bitmap : Bitmap_T;
                  X, Y       : Natural) return Boolean;

end Font;
