#!/usr/bin/env python3
"""Convert a raw DMI frame dump (640x480 colour indices, see
Display.Screen.Files.Dump) to a PNG: frame2png.py in.actual out.png"""
import struct, sys, zlib

W, H = 640, 480
PALETTE = [  # General_Parameters.RGB_Colors
    (255, 255, 255), (0, 0, 0), (195, 195, 195), (150, 150, 150),
    (85, 85, 85), (3, 17, 34), (8, 24, 57), (223, 223, 0),
    (234, 145, 0), (191, 0, 2), (33, 49, 74), (41, 74, 107)]

def chunk(tag, data):
    return (struct.pack(">I", len(data)) + tag + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff))

src, dst = sys.argv[1], sys.argv[2]
raw = open(src, "rb").read()
assert len(raw) == W * H, f"{src}: {len(raw)} bytes, expected {W * H}"
rows = b"".join(
    b"\0" + b"".join(bytes(PALETTE[c]) if c < len(PALETTE) else b"\xff\x00\xff"
                     for c in raw[y * W:(y + 1) * W])
    for y in range(H))
png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(rows, 9))
       + chunk(b"IEND", b""))
open(dst, "wb").write(png)
