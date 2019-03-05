package Font is
   -- Following FreeType notation
   
   type Face_T is 
      record
         Ascender  : Integer;
         Descender : Integer;
         Max_Advance_Width : Integer;
         Cap_Height : Natural;
      end record;
   
   type Glyph is 
      record 
         Left : Natural;
         Top  : Natural;
         Advance_X : Natural;
         Height, Width : Natural;
         Bitmap_Pos : Positive;
      end record;
   
   type Glyph_Map is array (Wide_Character range <>) of Glyph;
   
   type Glyph_String is array (Positive range <>) of Glyph;
   
   type Bitmap_T is array (Positive range <>) of Boolean
     with Pack => True;
   
end Font;
