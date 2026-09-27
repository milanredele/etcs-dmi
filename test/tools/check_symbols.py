#!/usr/bin/env python3
"""Compare every bitmap in dmi/symbol.ads with the official bmp of the same
name under doc/SRS/ERA_ERTMS_015560_v400/symbols (24 bit RGB). A pixel of the
bmp is mapped to the nearest colour of General_Parameters; the official
files carry scaling artefacts, so a few differing pixels are normal and a
symbol is reported from a threshold on (default 5 % of its pixels).

    python3 test/tools/check_symbols.py [percent]
"""
import glob, os, re, struct, sys

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
COLOURS = {"WHITE": (255, 255, 255), "BLACK": (0, 0, 0), "GREY": (195, 195, 195),
           "MEDIUM_GREY": (150, 150, 150), "DARK_GREY": (85, 85, 85),
           "DARK_BLUE": (3, 17, 34), "SHADOW": (8, 24, 57), "YELLOW": (223, 223, 0),
           "ORANGE": (234, 145, 0), "RED": (191, 0, 2)}


def nearest(rgb):
    return min(COLOURS, key=lambda c: sum((a - b) ** 2 for a, b in zip(COLOURS[c], rgb)))


def read_bmp(path):
    d = open(path, "rb").read()
    off, = struct.unpack_from("<I", d, 10)
    header, = struct.unpack_from("<I", d, 14)
    w, h = struct.unpack_from("<ii", d, 18)
    bpp, = struct.unpack_from("<H", d, 28)
    if bpp not in (8, 24, 32):
        return None
    palette = 14 + header
    step, row = bpp // 8, ((w * bpp + 31) // 32) * 4
    rows = []
    for y in range(abs(h)):
        line = []
        for x in range(w):
            i = off + y * row + x * step
            if bpp == 8:
                i = palette + 4 * d[i]
            line.append(nearest((d[i + 2], d[i + 1], d[i])))
        rows.append(line)
    # symbol.ads stores the rows bottom-up, like a bmp with positive height
    return w, abs(h), (rows if h > 0 else rows[::-1])


def key(name):
    """PL_23, NA_18_2 / NA_18.2, SM_01 / SM01 -> one spelling"""
    return re.sub(r"[^A-Z0-9]", "", name.upper())


def main():
    limit = float(sys.argv[1]) if len(sys.argv) > 1 else 5.0
    bmps = {key(os.path.splitext(os.path.basename(p))[0]): p
            for p in glob.glob(os.path.join(ROOT, "doc/SRS/ERA_ERTMS_015560_v400/symbols/*/*.bmp"))}
    src = open(os.path.join(ROOT, "dmi/symbol.ads")).read()
    bad = 0
    for m in re.finditer(r"^(\w+) : constant T\s*:= \(Length => \d+,\s*Width => (\d+),\s*"
                         r"Height => (\d+),\s*Bitmap => \((.*?)\)\);", src, re.S | re.M):
        name, w, h = m.group(1), int(m.group(2)), int(m.group(3))
        pix = [c for c in re.split(r"[,\s]+", m.group(4)) if c]
        if key(name) not in bmps:
            print(f"{name}: no official bmp")
            continue
        got = read_bmp(bmps[key(name)])
        if got is None:
            print(f"{name}: official bmp is not 8/24/32 bit, not compared")
            continue
        bw, bh, rows = got
        if (bw, bh) != (w, h):
            print(f"{name}: size {w}x{h}, official {bw}x{bh}")
            bad += 1
            continue
        diff = sum(1 for i, c in enumerate(pix) if rows[i // w][i % w] != c)
        if diff * 100.0 / len(pix) >= limit:
            print(f"{name}: {diff} of {len(pix)} pixels differ")
            bad += 1
    print(f"symbols over the limit: {bad}")


main()
