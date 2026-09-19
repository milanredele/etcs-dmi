#!/bin/sh
#  ETCS DMI -- regenerate the bitmap font packages src/font-freesans_*.ads.
#
#  Usage:  utils/gen_fonts.sh [path to FreeSans.ttf]
#
#  Without an argument the script downloads the GNU FreeFont release the
#  fonts in the repository were made from and checks its digest, so the
#  generation is reproducible on any machine with FreeType and a C
#  compiler. The .ttf itself is not kept in the repository (1.5 MB, and
#  its licence text would have to come with it); this script and the
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
SOURCE="GNU FreeFont FreeSans.ttf, release 20120503, GPL v3 with the font exception"

ttf=$1
if [ -z "$ttf" ]; then
  ttf=$work/freefont-20120503/FreeSans.ttf
  if [ ! -f "$ttf" ]; then
    curl -sSL -o "$work/freefont.zip" "$ZIP_URL"
    echo "$ZIP_SHA  $work/freefont.zip" | shasum -a 256 -c -
    unzip -o -q "$work/freefont.zip" -d "$work"
  fi
fi
echo "$TTF_SHA  $ttf" | shasum -a 256 -c -

cc -O2 -o "$work/ttf2ada" "$here/ttf2ada.c" \
   $(pkg-config --cflags --libs freetype2)

#  The character heights of 5.1.2.2.3 and what each one carries. Every
#  font gets the printable part of ISO 8859-1 (16#20#..16#7E# and
#  16#A0#..16#FF#): a plain text message is a string of X_TEXT
#  characters, "each character encoded as ISO 8859-1, also known as
#  Latin Alphabet #1" (SUBSET-026 7.5.1.174), and 5.5.1.1 asks for the
#  languages configured on board. The C1 range 16#7F#..16#9F# has no
#  printable form and is left to the replacement box.
SET=20-7E,A0-FF

for cells in 10 12 16 17 18; do
  "$work/ttf2ada" "$ttf" "$cells" "$SET" "$SOURCE" \
    > "$root/src/font-freesans_$cells.ads"
done

echo "written: $root/src/font-freesans_{10,12,16,17,18}.ads"
