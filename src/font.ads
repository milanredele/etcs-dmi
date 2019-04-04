package Font is
   
   type Size_T is range 10 .. 18;
   
   -- Following FreeType notation
   type Glyph is 
      record 
         Left : Natural range 0 .. 20;
         Top  : Integer range -5 .. 20;
         Advance_X : Natural range 0 .. 20;
         Height, Width : Natural range 0 .. 20;
         Bitmap_Pos : Positive;
      end record;
   
   type Glyph_Map is array (Wide_Character range <>) of Glyph;
   
   type Glyph_String is array (Positive range <>) of Glyph;
   
   type Bitmap_T is array (Positive range <>) of Boolean
     with Pack => True;
   
end Font;
