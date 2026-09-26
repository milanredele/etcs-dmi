/* ttf2ada -- render a TrueType font to an Ada bitmap font package.
 *
 * Usage: ttf2ada <font.ttf> <cap height in cells> <ranges> [source note]
 *
 *   <ranges>  comma separated hexadecimal code point ranges, e.g.
 *             "20-7E,A0-FF" for the printable part of ISO 8859-1.
 *
 * The output is the Ada package Font.<family>_<cap height> on standard
 * output (see utils/gen_fonts.sh for the exact invocations); a bold face
 * (style "Bold", FreeSansBold.ttf) is Font.<family>Bold_<cap height>.
 *
 * ERA_ERTMS_015560 5.1.2.2.1 defines the height of the characters as the
 * height of the capital characters, so the second argument is the cap
 * height in cells: the glyphs are rendered unhinted (FT_LOAD_NO_HINTING),
 * the one mode in which FreeType puts the cap height of FreeSans exactly
 * on the nominal size for every size in use (10, 12, 16, 17 and 18).
 * With the TrueType hinting on, the capitals of the 12 cell font come out
 * 13 cells and those of the 17 cell font 18 cells (audit finding GEN-7).
 * The generator checks the rendered height of 'H' and fails otherwise.
 *
 * Storage: glyph rows are packed 8 cells to a byte, most significant bit
 * first, and every row starts on a byte boundary (the layout FreeType
 * itself renders into). Glyph.Bitmap_Pos is the index of the first byte
 * of the glyph. The tables are Ada constants, so they are read-only data
 * and cost no elaboration code.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ft2build.h>
#include FT_FREETYPE_H

#define MAX_CODE 0x10000

static int wanted[MAX_CODE];

/* Per glyph metrics kept for the two passes over the code points. */
struct glyph {
  int defined;
  int left, top, advance, rows, width, pitch;
  long pos;                     /* 1 based byte index in the bitmap */
  unsigned char *bits;
};

static struct glyph glyphs[MAX_CODE];

/* The name of the package after "Font.": the family, and "Bold" for a
   bold face (FreeSansBold.ttf has the family "FreeSans" and the style
   "Bold"), so that the regular and the bold packages of one size
   differ. */
static char package[128];

static void
set_package_name (FT_Face face)
{
  int bold = face->style_name != NULL
             && strstr (face->style_name, "Bold") != NULL;

  snprintf (package, sizeof package, "%s%s", face->family_name,
            bold ? "Bold" : "");
}

static void
parse_ranges (const char *spec, int *lo, int *hi)
{
  const char *p = spec;

  *lo = MAX_CODE;
  *hi = -1;
  while (*p)
    {
      char *end;
      long from = strtol (p, &end, 16);
      long to = from;

      if (end == p)
        {
          fprintf (stderr, "ttf2ada: cannot read the ranges '%s'\n", spec);
          exit (1);
        }
      p = end;
      if (*p == '-')
        {
          to = strtol (p + 1, &end, 16);
          p = end;
        }
      if (from < 0 || to >= MAX_CODE || to < from)
        {
          fprintf (stderr, "ttf2ada: range %lX-%lX out of bounds\n", from, to);
          exit (1);
        }
      for (long i = from; i <= to; i++)
        wanted[i] = 1;
      if (from < *lo)
        *lo = (int) from;
      if (to > *hi)
        *hi = (int) to;
      if (*p == ',')
        p++;
    }
  if (*hi < 0)
    {
      fprintf (stderr, "ttf2ada: empty range\n");
      exit (1);
    }
}

/* The Ada literal naming the code point in the Glyph_Map aggregate. */
static void
put_choice (int code)
{
  if (code == '\'')
    printf ("'''");              /* the Ada character literal for ' */
  else if (code >= 0x20 && code <= 0x7E)
    printf ("'%c'", code);
  else
    printf ("Wide_Character'Val (16#%02X#)", code);
}

int
main (int argc, char **argv)
{
  FT_Library library;
  FT_Face face;
  FT_Error error;
  int cells, lo, hi;
  long pos = 1;
  const char *source;
  int max_left = 0, max_top = 0, min_top = 0, max_adv = 0, max_dim = 0;

  if (argc < 4 || argc > 5)
    {
      fprintf (stderr,
               "usage: %s <font.ttf> <cap height in cells> "
               "<hex ranges, e.g. 20-7E,A0-FF> [source note]\n", argv[0]);
      return 1;
    }
  cells = atoi (argv[2]);
  source = argc == 5 ? argv[4] : argv[1];
  parse_ranges (argv[3], &lo, &hi);

  if (FT_Init_FreeType (&library))
    {
      fprintf (stderr, "ttf2ada: cannot start FreeType\n");
      return 1;
    }
  if (FT_New_Face (library, argv[1], 0, &face))
    {
      fprintf (stderr, "ttf2ada: cannot read %s\n", argv[1]);
      return 1;
    }
  set_package_name (face);
  if (FT_Set_Char_Size (face, cells * 64, 0, 100, 0))
    {
      fprintf (stderr, "ttf2ada: cannot set the size %d\n", cells);
      return 1;
    }

  /* 5.1.2.2.1: the height of the characters is the height of the
     capitals. Refuse to write a font that does not keep it. */
  error = FT_Load_Glyph (face, FT_Get_Char_Index (face, 'H'),
                         FT_LOAD_TARGET_MONO | FT_LOAD_NO_HINTING);
  if (error || FT_Render_Glyph (face->glyph, FT_RENDER_MODE_MONO))
    {
      fprintf (stderr, "ttf2ada: cannot render 'H'\n");
      return 1;
    }
  if ((int) face->glyph->bitmap.rows != cells)
    {
      fprintf (stderr, "ttf2ada: 'H' is %d cells high, %d asked for\n",
               (int) face->glyph->bitmap.rows, cells);
      return 1;
    }

  for (int i = lo; i <= hi; i++)
    {
      FT_UInt index;
      FT_Bitmap *bitmap;
      struct glyph *g = &glyphs[i];

      if (!wanted[i])
        continue;
      index = FT_Get_Char_Index (face, i);
      if (index == 0)
        {
          fprintf (stderr, "ttf2ada: %s has no glyph for 16#%02X#\n",
                   face->family_name, i);
          continue;
        }
      if (FT_Load_Glyph (face, index, FT_LOAD_TARGET_MONO | FT_LOAD_NO_HINTING)
          || FT_Render_Glyph (face->glyph, FT_RENDER_MODE_MONO))
        {
          fprintf (stderr, "ttf2ada: cannot render 16#%02X#\n", i);
          continue;
        }
      bitmap = &face->glyph->bitmap;
      g->defined = 1;
      g->left = face->glyph->bitmap_left;
      g->top = face->glyph->bitmap_top;
      g->advance = (int) (face->glyph->advance.x >> 6);
      g->rows = (int) bitmap->rows;
      g->width = (int) bitmap->width;
      g->pitch = (g->width + 7) / 8;
      g->pos = pos;
      pos += (long) g->rows * g->pitch;
      if (g->rows > 0 && g->pitch > 0)
        {
          g->bits = calloc ((size_t) g->rows * g->pitch, 1);
          for (int r = 0; r < g->rows; r++)
            for (int b = 0; b < g->pitch; b++)
              g->bits[r * g->pitch + b] =
                bitmap->buffer[r * bitmap->pitch + b];
        }
      if (g->left > max_left)
        max_left = g->left;
      if (g->top > max_top)
        max_top = g->top;
      if (g->top < min_top)
        min_top = g->top;
      if (g->advance > max_adv)
        max_adv = g->advance;
      if (g->rows > max_dim)
        max_dim = g->rows;
      if (g->width > max_dim)
        max_dim = g->width;
    }

  printf ("--  ETCS DMI\n");
  printf ("--  Bitmap font, cap height %d cells (DMI 5.1.2.2.1,"
          " 5.1.2.2.3)%s.\n", cells,
          strstr (package, "Bold") ? ", bold style" : "");
  printf ("--  Generated by utils/ttf2ada, do not edit by hand; see\n");
  printf ("--  utils/gen_fonts.sh for the command that produced it.\n");
  printf ("--  Source: %s\n", source);
  printf ("--  Code points 16#%02X# .. 16#%02X#, rendered unhinted.\n",
          lo, hi);
  printf ("\n");
  printf ("package Font.%s_%d is\n\n", package, cells);
  printf ("   Glyphs : constant Glyph_Map :=\n     (");

  for (int i = lo, first = 1; i <= hi; i++)
    {
      struct glyph *g = &glyphs[i];

      if (!first)
        printf (",\n      ");
      first = 0;
      put_choice (i);
      if (!g->defined)
        {
          printf (" => No_Glyph");
          continue;
        }
      printf (" =>\n         (Left => %d,\n", g->left);
      printf ("          Top => %d,\n", g->top);
      printf ("          Advance_X => %d,\n", g->advance);
      printf ("          Height => %d,\n", g->rows);
      printf ("          Width => %d,\n", g->width);
      printf ("          Bitmap_Pos => %ld)", g->pos);
    }
  printf (");\n\n");

  if (pos == 1)
    {
      fprintf (stderr, "ttf2ada: no glyph rendered\n");
      return 1;
    }

  {
    int last = lo;

    for (int i = lo; i <= hi; i++)
      if (glyphs[i].defined && glyphs[i].rows > 0 && glyphs[i].pitch > 0)
        last = i;

  printf ("   Bitmap : constant Bitmap_T :=\n     (\n");
  for (int i = lo; i <= hi; i++)
    {
      struct glyph *g = &glyphs[i];

      if (!g->defined || g->rows == 0 || g->pitch == 0)
        continue;
      printf ("      --  16#%02X#", i);
      if (i >= 0x20 && i <= 0x7E)
        printf (" '%c'", i);
      printf (", %d x %d cells\n", g->width, g->rows);
      for (int r = 0; r < g->rows; r++)
        {
          printf ("      ");
          for (int b = 0; b < g->pitch; b++)
            printf ("16#%02X#%s", g->bits[r * g->pitch + b],
                    (i == last && r == g->rows - 1 && b == g->pitch - 1)
                    ? "" : ", ");
          printf ("  --  ");
          for (int c = 0; c < g->width; c++)
            putchar ((g->bits[r * g->pitch + c / 8] >> (7 - c % 8)) & 1
                     ? '*' : ' ');
          printf ("\n");
        }
    }
  printf ("     );\n\n");
  }
  printf ("end Font.%s_%d;\n", package, cells);

  fprintf (stderr,
           "ttf2ada: %s_%d, %ld bitmap bytes, Left <= %d, Top in %d .. %d,"
           " Advance_X <= %d, Height/Width <= %d\n",
           package, cells, pos - 1, max_left, min_top, max_top,
           max_adv, max_dim);
  return 0;
}
