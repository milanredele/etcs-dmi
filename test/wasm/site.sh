#!/bin/sh
# Assemble the static site of the browser test bench (GitHub Pages):
#   test/wasm/site.sh <output directory>
# The repository layout is kept so that the page finds the sounds under
# doc/ exactly as it does when the repository itself is served; the site
# root redirects to the page. Build the modules first (build.sh).
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
OUT=${1:?usage: site.sh <output directory>}
SOUNDS=doc/SRS/ERA_ERTMS_015560_v400/sounds

for f in dmi.wasm evc.wasm; do
   [ -f "$ROOT/test/wasm/$f" ] || { echo "missing test/wasm/$f: run test/wasm/build.sh" >&2; exit 1; }
done

rm -rf "$OUT"
mkdir -p "$OUT/test/wasm" "$OUT/$SOUNDS"
cp "$ROOT/test/wasm/index.html" "$ROOT/test/wasm/dmi.wasm" "$ROOT/test/wasm/evc.wasm" "$OUT/test/wasm/"
cp "$ROOT/$SOUNDS"/*.wav "$OUT/$SOUNDS/"
cat > "$OUT/index.html" <<'HTML'
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>ETCS DMI</title>
    <meta http-equiv="refresh" content="0; url=test/wasm/">
    <link rel="canonical" href="test/wasm/">
  </head>
  <body><a href="test/wasm/">ETCS DMI test bench</a></body>
</html>
HTML
du -sh "$OUT"
