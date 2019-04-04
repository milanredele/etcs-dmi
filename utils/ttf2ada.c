#include <stdio.h>
#include <stdlib.h>
#include <ft2build.h>
#include FT_FREETYPE_H

unsigned long bitmap_pos = 1;

void
write_bitmap_params( FT_Bitmap*  bitmap )
{
  printf ("Height => %d,\nWidth => %d,\nBitmap_Pos => %ld\n", bitmap->rows, bitmap->width,  bitmap_pos);
  bitmap_pos += bitmap->rows * bitmap->width;
}

void write_bitmap (FT_Bitmap* bitmap){
	FT_Int i,j;
	
	for (j = 0; j < bitmap->rows; j++){
		for ( i = 0; i < bitmap->width; i++ ){
      unsigned char pixels = bitmap->buffer[i/8 + j*(bitmap->pitch)];
      int pix = (pixels >> (7 - i%8)) & 1;
      pix ? printf("True ") : printf("False");
      putchar(',');
    }
    printf (" -- ");
    for ( i = 0; i < bitmap->width; i++ ){
      unsigned char pixels = bitmap->buffer[i/8 + j*(bitmap->pitch)];
      int pix = (pixels >> (7 - i%8)) & 1;
      putchar( pix ? '*' : ' ');
    }
		putchar ('\n');
	}
}

int main (int argc, char** argv) {

  FT_Library    library;
  FT_Face       face;
  FT_GlyphSlot  slot;
  FT_Error      error;
  char*         filename;
  int           size;
  unsigned long code_from, code_to;
  
  if ( argc != 5 )
  {
    fprintf ( stderr, "usage: %s fontsize <UTF-32 hex codepoint from> <codepoint to>\n", argv[0] );
    exit( 1 );
  }
  
  filename  = argv[1];
  size      = atoi (argv[2]);
  char *end;
  code_from = strtoul(argv[3], &end, 16);
  code_to   = strtoul(argv[4], &end, 16);
  
  error = FT_Init_FreeType( &library );
  error = FT_New_Face( library, filename, 0, &face );
  error = FT_Set_Char_Size( face, size * 64, 0, 100, 0 );
  if (error) {
  	fprintf (stderr, "Some error happened\n");
  }
  
  slot = face->glyph;
  
  printf ("package Font.%s_%d is\n\n", face->family_name, size);

  printf ("Glyphs : Glyph_Map := (");
  
  for (unsigned long i=code_from; i<=code_to; i++) {
	  
	  FT_UInt chridx = FT_Get_Char_Index (face, i);
	  error = FT_Load_Glyph ( face, chridx, FT_LOAD_TARGET_MONO);
	  error = FT_Render_Glyph (face->glyph, FT_RENDER_MODE_MONO);
  	if (error) {
  		fprintf (stderr, "Some error happened loading codepoint: %ld\n", i);
  	} else {
  		printf("'%c' => (Left => %d,\nTop => %d,\nAdvance_X => %ld,\n", (char) i, slot->bitmap_left, slot->bitmap_top, slot->advance.x >> 6);
  		write_bitmap_params (&slot->bitmap);
  		if (i < code_to ) {
	  		printf("),\n");
	  	} else {
	  		printf(")");
	  	}
  	}
  }
  printf (");\n\n");
  printf ("Bitmap : Bitmap_T \n:= (\n");
  
  for (unsigned long i=code_from; i<=code_to; i++) {
	  
	  FT_UInt chridx = FT_Get_Char_Index (face, i);
	  error = FT_Load_Glyph ( face, chridx, FT_LOAD_TARGET_MONO);
	  error = FT_Render_Glyph (face->glyph, FT_RENDER_MODE_MONO);
  	if (error) {
  		fprintf (stderr, "Some error happened loading codepoint: %ld\n", i);
  	} else {
  		printf ("-- codepoint %#lX\n", i); 
  		write_bitmap (&slot->bitmap);
  	}
  }
  
  printf (");\n");
  printf ("end;\n");
	return 0;
}
