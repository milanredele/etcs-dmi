#!/bin/sh
#  ETCS DMI -- regenerate the bitmap font packages dmi/font-freesans_*.ads
#  and dmi/font-freesansbold_*.ads.
#
#  Usage:  utils/gen_fonts.sh [path to FreeSans.ttf [path to FreeSansBold.ttf]]
#
#  Without an argument the script downloads the GNU FreeFont release the
#  fonts in the repository were made from and checks its digest, so the
#  generation is reproducible on any machine with FreeType and a C
#  compiler. The .ttf files themselves are not kept in the repository
#  (1.5 MB and more, and their licence text would have to come with
#  them); this script and the
#  header of every generated package name the exact release instead.
#
#  FreeType comes from Homebrew (brew install freetype) or MacPorts
#  (port install freetype) on macOS and from libfreetype6-dev on Debian;
#  pkg-config finds it.

set -e

here=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$here")
work=${TMPDIR:-/tmp}/etcs-dmi-fonts
mkdir -p "$work"

#  GNU FreeFont, release 20120503 (the last release of the project),
#  https://ftp.gnu.org/gnu/freefont/freefont-ttf-20120503.zip
#  GPL v3 with the font exception; FreeSans follows the metrics of
#  Helvetica, one of the character types 5.1.2.1.4 recommends.
ZIP_URL=https://ftp.gnu.org/gnu/freefont/freefont-ttf-20120503.zip
ZIP_SHA=7c85baf1bf82a1a1845d1322112bc6ca982221b484e3b3925022e25b5cae89af
TTF_SHA=c80858440d8fb618e0ac5ff6f16251dbfa6b3316f00f3cdd17d477297dd87b04
BOLD_SHA=982534a3731416a15e2756601721f26053f68bf4239011550f3dd23ce6308215
SOURCE="GNU FreeFont FreeSans.ttf, release 20120503, GPL v3 with the font exception"
BOLD_SOURCE="GNU FreeFont FreeSansBold.ttf, release 20120503, GPL v3 with the font exception"

ttf=$1
bold=$2
if [ -z "$ttf" ] || [ -z "$bold" ]; then
  if [ ! -f "$work/freefont-20120503/FreeSansBold.ttf" ]; then
    curl -sSL -o "$work/freefont.zip" "$ZIP_URL"
    echo "$ZIP_SHA  $work/freefont.zip" | shasum -a 256 -c -
    unzip -o -q "$work/freefont.zip" -d "$work"
  fi
  ttf=${ttf:-$work/freefont-20120503/FreeSans.ttf}
  bold=${bold:-$work/freefont-20120503/FreeSansBold.ttf}
fi
echo "$TTF_SHA  $ttf" | shasum -a 256 -c -
echo "$BOLD_SHA  $bold" | shasum -a 256 -c -

cc -O2 -o "$work/ttf2ada" "$here/ttf2ada.c" \
   $(pkg-config --cflags --libs freetype2)

#  The character heights of 5.1.2.2.3 and what each one carries. Every
#  font gets the printable part of ISO 8859-1 (16#20#..16#7E# and
#  16#A0#..16#FF#): a plain text message is a string of X_TEXT
#  characters, "each character encoded as ISO 8859-1, also known as
#  Latin Alphabet #1" (SUBSET-026 7.5.1.174), and 5.5.1.1 asks for the
#  languages configured on board. The C1 range 16#7F#..16#9F# has no
#  printable form and is left to the replacement box. Latin Extended-A
#  (16#100#..16#17F#) carries the letters of the ISO 8859-2 languages
#  (Hungarian o and u with double acute, Czech, Polish, Slovak,
#  Romanian) for the fixed texts of DMI_Texts; trackside texts stay
#  ISO 8859-1.
SET=20-7E,A0-17F

for cells in 10 12 16 17 18; do
  "$work/ttf2ada" "$ttf" "$cells" "$SET" "$SOURCE" \
    > "$root/dmi/font-freesans_$cells.ads"
done

#  The bold style is asked for at one height only, 12 cells (5.1.2.2.3 h):
#  the text messages of the first group (8.2.3.4.7 c) and the '.' of a
#  keyboard (5.1.2.1.5). Same character set as the regular fonts.
for cells in 12; do
  "$work/ttf2ada" "$bold" "$cells" "$SET" "$BOLD_SOURCE" \
    > "$root/dmi/font-freesansbold_$cells.ads"
done

echo "written: $root/dmi/font-freesans_{10,12,16,17,18}.ads"
echo "written: $root/dmi/font-freesansbold_12.ads"
