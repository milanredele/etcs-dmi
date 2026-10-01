#!/usr/bin/env python3
"""Deterministic review of changed golden frames (AGENTS.md "Regression").

  golden_review.py [--base REV] [--head REV] [--out DIR]
                    [--areas A,B,...] [--intent TEXT] [--check-tool]

A "golden" is one test/golden*/<name>.sha256: a digest obj/dmi_test or
obj/evc_test checks a scenario against (AGENTS.md "Testing & Tooling").
This tool builds both sides of a change, dumps every golden's raw bytes
on each side (DUMP=1 obj/dmi_test, EVC_DUMP=dir obj/evc_test -- the dump
interfaces test/check.sh and AGENTS.md already rely on; this tool does
not change them), diffs the two sets, and turns every difference into
something a reviewer can judge against a stated intent, before
`UPDATE=1` re-records the goldens, in two steps (a small model is
enough for either): first a reviewer who is shown the pictures and diff
excerpts alone (BLIND.md) and does not know the intent describes,
literally, every visible difference; then a reviewer who knows the
intent (REPORT.md) judges those descriptions against it. Splitting the
two matters: a reviewer told the intent tends to see only the change it
names and approve a picture where text also silently re-wrapped
elsewhere; a reviewer who must describe everything it sees, with no
idea what the change was meant to do, does not get to skip that.

Sides
-----
--base (default "HEAD") and --head (default: the working tree as it
stands, uncommitted changes included) each name a side. A side that is
a revision (anything other than an omitted --head) is checked out into
a throwaway detached `git worktree`, built, dumped, and discarded; its
dumps are cached under ~/.cache/etcs-dmi/golden-review/<commit sha>/ so
a second run against the same revision does not rebuild. The working
tree side is built and dumped in place (it is not cached: its content
can change from one run to the next); the .actual frame dumps that
DUMP=1 leaves next to the committed goldens are moved out to
<out>/_dumps/worktree/ so test/golden/ is left exactly as it was found.
`obj/dmi_test` and `obj/evc_test` are run for their DUMP/EVC_DUMP side
effect only -- their own pass/fail exit status is not the tool's
concern (the whole point of a review is that the head side's dumped
bytes usually do NOT match its still-old committed .sha256 yet).

Comparison
----------
Every golden name present on either side is compared. A changed, added
(head only) or removed (base only) golden goes into the report. Two
further, separately flagged conditions: a golden whose dumped bytes
changed but whose .sha256 text did NOT (nobody ran UPDATE=1 yet -- "not
re-recorded"), and the mirror oddity, a golden whose .sha256 text
changed while its dumped bytes did not (the digest was edited, or
something about the dump is nondeterministic).

Grouping
--------
Changed display goldens (test/golden/*.sha256, 640x480 colour-index
frames, Display.Screen.Files) that end up with the very same set of
changed pixels and the same before/after colours at each one are one
group; forty goldens that all changed the same banner are one line in
the report, not forty. Each changed pixel is attributed to the
smallest DMI layout area containing it (dmi/display.ads, via the
vendored dmi_areas helper compiled against the *head* side's dmi/
sources -- see test/tools/golden_review/dmi_areas.adb); that per-area
attribution and its pixel counts go in the report text. The pictures
themselves are per touched *region* instead: adjacent or overlapping
areas' bounding boxes are merged (merge_boxes) so one continuous change
spanning several sub-areas (several text-message lines, say) is one
picture, not a strip per line -- or once for the whole frame when the
merged regions cover most of it. Each picture is a before | after |
difference triptych (magenta marking the changed pixels in the dimmed
difference panel), its three panels laid out side by side or stacked,
whichever gets the crop's shape the larger integer scale factor
(choose_layout).

Changed on-board goldens (test/golden/evc/*.sha256, EVC_Outbox output
records, see test/tools/evc_dump.py) are grouped by which record kinds
differ and by how many; the grouping and the diff text reuse this
tool's own vendored copy of evc_dump.py's --diff logic (not the
reviewed tree's test/tools/evc_dump.py: an old base revision may not
have the options this tool needs).

One on-board golden, evc/end_to_end_sb, is a 640x480 frame digest
(Display.Screen.Files.Digest) living under test/golden/evc/ rather than
an EVC_Outbox byte stream (evc_test.adb's Scenario_End_To_End uses
Check_Digest directly, not Check_Golden); this tool tells display from
on-board goldens by which dump each run actually produced (a DUMP=1
.actual next to the .sha256, or an EVC_DUMP .bin) rather than by
directory, so that golden is reviewed as a display frame like any
other, picture included.

Declared expectation
---------------------
--areas (comma separated DMI area names, e.g. B3,D) and --intent (free
text) say what the change is meant to do. Every group is still
reported and still needs a look; the inside/OUTSIDE marking only
orders the report (outside first) and tells a reviewer where to be
suspicious. Without --areas, groups are marked "no --areas given"
instead -- the tool does not guess an expectation nobody declared. None
of this -- the intent, the declared areas, the marking, a golden's own
name -- appears in BLIND.md: the describing reviewer must have nothing
to go on but the pictures and diff excerpts themselves.

Output
------
<out>/REPORT.md (the judging sheet: sides, intent, declared areas, the
one-line-per-group table, marking, and a Verdict: line per group) and
<out>/BLIND.md (the describing sheet: the same groups with no
intent/areas/marking/golden names, each picture's layout stated in
words, and a Description: line per group to fill in first) in --out
(default obj/golden-review/, git-ignored); <out>/review.json carries
REPORT.md's content structured, plus BLIND.md's file name. Exit status
is 0 whenever the tool ran to completion -- a changed golden is not an
error, a build or dump failure is. The last stdout line is a one-line
summary:

  golden_review: N display groups (M frames), K on-board groups
  (L goldens), X outside declared areas

Self test: --check-tool synthesises small frame dumps and a small area
table (no build) and checks pixel attribution, grouping, bounding
boxes, the picture scaling/layout rule, and that a synthetic BLIND.md
carries none of a run's intent, declared areas or OUTSIDE marking;
test/check.sh runs it.
"""

import argparse
import hashlib
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import time
import zlib
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent               # test/tools
HELPER_DIR = TOOL_DIR / "golden_review"                   # dmi_areas.adb/.gpr
REPO_ROOT = TOOL_DIR.parent.parent                         # repository root

FRAME_W, FRAME_H = 640, 480
FRAME_SIZE = FRAME_W * FRAME_H

# General_Parameters.RGB_Colors (dmi/general_parameters.ads), mirrored here
# and in frame2png.py -- both are the tool's own data, not the reviewed
# tree's, same reasoning as the vendored evc_dump.py logic below.
PALETTE = [
    (255, 255, 255), (0, 0, 0), (195, 195, 195), (150, 150, 150),
    (85, 85, 85), (3, 17, 34), (8, 24, 57), (223, 223, 0),
    (234, 145, 0), (191, 0, 2), (33, 49, 74), (41, 74, 107),
]
MAGENTA = (255, 0, 255)  # not in PALETTE: the diff-picture marker colour
SEPARATOR = (128, 128, 128)
SEPARATOR_W = 2

DEFAULT_OUT = REPO_ROOT / "obj" / "golden-review"
CACHE_ROOT = Path(os.environ.get(
    "GOLDEN_REVIEW_CACHE", Path.home() / ".cache" / "etcs-dmi" / "golden-review"))


class ToolError(Exception):
    """A build or dump failure: the tool could not produce one side."""


# ---------------------------------------------------------------------
# Build environment (mirrors test/check.sh)
# ---------------------------------------------------------------------

def build_env():
    """An environment dict with SDKROOT/LIBRARY_PATH/PATH set the way
    test/check.sh sets them on macOS, so this script runs from a plain
    shell without the caller having to prepare anything."""
    env = dict(os.environ)
    if sys.platform == "darwin" and "SDKROOT" not in env:
        try:
            sdk = subprocess.run(["xcrun", "--show-sdk-path"], check=True,
                                  capture_output=True, text=True).stdout.strip()
        except Exception:
            sdk = ""
        if sdk:
            env["SDKROOT"] = sdk
            env["LIBRARY_PATH"] = str(Path(sdk) / "usr" / "lib")
    toolchains = Path.home() / ".local" / "share" / "alire" / "toolchains"
    extra = []
    if toolchains.is_dir():
        for pattern in ("gprbuild_*/bin", "gnat_native_*/bin"):
            extra.extend(sorted(str(p) for p in toolchains.glob(pattern)))
    if extra:
        env["PATH"] = ":".join(extra) + ":" + env.get("PATH", "")
    return env


def run(cmd, cwd, env, check=True, capture=True):
    """Run a subprocess, printing the command line to stderr first."""
    print("+ %s   (in %s)" % (" ".join(str(c) for c in cmd), cwd), file=sys.stderr)
    kw = dict(cwd=str(cwd), env=env)
    if capture:
        kw.update(capture_output=True, text=True)
    r = subprocess.run(cmd, **kw)
    if check and r.returncode != 0:
        tail = ""
        if capture:
            tail = ((r.stdout or "") + (r.stderr or ""))[-4000:]
        raise ToolError("command failed (%d): %s\n%s"
                         % (r.returncode, " ".join(str(c) for c in cmd), tail))
    return r


def git(args, cwd=REPO_ROOT, check=True):
    return run(["git"] + args, cwd=cwd, env=os.environ.copy(), check=check)


# ---------------------------------------------------------------------
# Building and dumping one side
# ---------------------------------------------------------------------

def build_mains(root, env):
    """gprbuild the two mains the runners need; fall back to the whole
    project if that target list does not work on this revision."""
    r = run(["gprbuild", "-s", "-j0", "-p", "-q", "-P", "etcsdmi.gpr",
             "dmi_test.adb", "evc_test.adb"], cwd=root, env=env, check=False)
    if r.returncode == 0:
        return
    run(["gprbuild", "-s", "-j0", "-p", "-q", "-P", "etcsdmi.gpr"],
        cwd=root, env=env)


def run_dumps(root, env, evc_dump_dir):
    """Run obj/dmi_test and obj/evc_test with DUMP=1 (both) and
    EVC_DUMP=evc_dump_dir (the on-board one), ignoring their own exit
    status: the dump is unconditional (Check_Frame/Check_Golden dump on
    every checked golden when DUMP is set), the pass/fail of the check
    against whatever .sha256 happens to be committed on this side is not
    what this tool is asking.

    A revision from before evc_test.adb existed (the on-board predates
    phase E1, see doc/EVC-PLAN.md) simply has no obj/evc_test to run: its
    on-board golden set is then empty on that side, not a tool failure."""
    dmi_env = dict(env)
    dmi_env["DUMP"] = "1"
    if (Path(root) / "obj" / "dmi_test").exists():
        run(["obj/dmi_test"], cwd=root, env=dmi_env, check=False)
    else:
        print("golden_review: no obj/dmi_test on this side, skipping", file=sys.stderr)
    evc_env = dict(env)
    evc_env["DUMP"] = "1"
    evc_env["EVC_DUMP"] = str(evc_dump_dir)
    if (Path(root) / "obj" / "evc_test").exists():
        run(["obj/evc_test"], cwd=root, env=evc_env, check=False)
    else:
        print("golden_review: no obj/evc_test on this side, skipping", file=sys.stderr)


def golden_name(golden_dir, path):
    return path.relative_to(golden_dir).with_suffix("").as_posix()


def collect_dumps(root, evc_dump_dir, *, move_actuals_to=None):
    """Read every *.sha256 under test/golden/, and every *.actual next to
    them (dmi_test's and evc_test's DUMP output; evc_test's own on-board
    .bin files live in evc_dump_dir, EVC_DUMP's target).

    When move_actuals_to is given (the working-tree side), the .actual
    files are moved there rather than merely read, and none are left
    behind in test/golden/ -- the AGENTS.md "regression" rule is that a
    working tree review leaves the tree as found. For a throwaway
    revision worktree this does not matter (the whole worktree is about
    to be discarded), so move_actuals_to is left None there and the
    .actual files are simply read in place.
    """
    golden_dir = root / "test" / "golden"
    sha = {}
    for p in golden_dir.rglob("*.sha256"):
        sha[golden_name(golden_dir, p)] = p.read_text().strip()
    display = {}
    for p in sorted(golden_dir.rglob("*.actual")):
        name = golden_name(golden_dir, p)
        data = p.read_bytes()
        display[name] = data
        if move_actuals_to is not None:
            dest = Path(move_actuals_to) / (name + ".actual")
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(p), str(dest))
    onboard = {}
    evc_dump_dir = Path(evc_dump_dir)
    if evc_dump_dir.is_dir():
        for p in sorted(evc_dump_dir.glob("*.bin")):
            onboard["evc/" + p.stem] = p.read_bytes()
    return display, onboard, sha


# ---------------------------------------------------------------------
# The dmi_areas helper: the DMI layout area table of one side's dmi/
# ---------------------------------------------------------------------

class Area:
    __slots__ = ("name", "parent", "x", "y", "w", "h")

    def __init__(self, name, parent, x, y, w, h):
        self.name, self.parent = name, parent
        self.x, self.y, self.w, self.h = x, y, w, h

    @property
    def size(self):
        return self.w * self.h

    def to_json(self):
        return {"name": self.name, "parent": self.parent,
                "x": self.x, "y": self.y, "w": self.w, "h": self.h}

    @staticmethod
    def from_json(d):
        return Area(d["name"], d["parent"], d["x"], d["y"], d["w"], d["h"])

    def label(self):
        return self.name if self.parent == "-" else "%s (in %s)" % (self.name, self.parent)


def find_dmi_dir(root):
    """Where this side's Display package (dmi/display.ads) lives. Before
    the dmi/common/evc split the DMI alone sat in src/; rather than
    hardcode both names, find display.ads itself so an even older or
    differently laid out revision still has a chance."""
    for candidate in ("dmi", "src"):
        p = Path(root) / candidate / "display.ads"
        if p.exists():
            return p.parent
    matches = list(Path(root).rglob("display.ads"))
    if matches:
        return matches[0].parent
    raise ToolError("cannot find display.ads under %s" % root)


def compile_areas(dmi_dir, env):
    """Build and run the dmi_areas helper against dmi_dir (some side's
    Display package sources, see find_dmi_dir) and return its area table.
    dmi_dir may belong to an old revision that does not carry
    test/tools/golden_review/ itself -- the helper always comes from this
    checkout."""
    gpr = HELPER_DIR / "dmi_areas.gpr"
    with tempfile.TemporaryDirectory(prefix="golden-review-areas-obj-") as obj:
        run(["gprbuild", "-q", "-p", "-P", str(gpr),
             "-XDMI_DIR=%s" % dmi_dir, "-XOBJ_DIR=%s" % obj],
            cwd=HELPER_DIR, env=env)
        r = run([str(Path(obj) / "dmi_areas")], cwd=HELPER_DIR, env=env)
    areas = []
    for line in r.stdout.splitlines():
        name, parent, x, y, w, h = line.split()
        areas.append(Area(name, parent, int(x), int(y), int(w), int(h)))
    return areas


def build_area_grid(areas, width=FRAME_W, height=FRAME_H):
    """A width*height lookup table mapping every pixel to the smallest
    area containing it (main areas drawn first, sub-areas drawn over
    them, so a sub-area wins where it nests inside its parent)."""
    grid = [None] * (width * height)
    ordered = sorted(areas, key=lambda a: (a.parent != "-", a.size))
    for area in ordered:
        y0, y1 = max(0, area.y), min(height, area.y + area.h)
        x0, x1 = max(0, area.x), min(width, area.x + area.w)
        for yy in range(y0, y1):
            row = yy * width
            grid[row + x0:row + x1] = [area] * (x1 - x0)
    return grid


# ---------------------------------------------------------------------
# Pixel diffing and grouping (display goldens)
# ---------------------------------------------------------------------

def diff_positions(a, b):
    """Indices where two equal-length byte strings differ. Fast path: an
    unconditional equality check in C; the per-byte XOR trick only runs
    for frames that actually differ, and only touches as many bytes."""
    if a == b:
        return []
    x = (int.from_bytes(a, "big") ^ int.from_bytes(b, "big")).to_bytes(len(a), "big")
    return [i for i, v in enumerate(x) if v]


def group_changed_display(names_bh, width=FRAME_W):
    """names_bh: {name: (base_bytes, head_bytes)}. Returns a list of
    groups: {positions, diffs (list of (i, old, new)), members}. Frames
    with the exact same changed pixels and before/after colours group
    together."""
    groups = {}
    order = []
    for name in sorted(names_bh):
        b, h = names_bh[name]
        diffs = tuple((i, b[i], h[i]) for i in diff_positions(b, h))
        key = ("changed", diffs)
        if key not in groups:
            groups[key] = {"status": "changed", "diffs": diffs, "members": []}
            order.append(key)
        groups[key]["members"].append(name)
    return [groups[k] for k in order]


def group_added_removed(names_bytes, status):
    """names_bytes: {name: bytes}. Goldens present on one side only
    group by content (forty identical new goldens are one group too)."""
    groups = {}
    order = []
    for name in sorted(names_bytes):
        data = names_bytes[name]
        key = (status, hashlib.sha256(data).hexdigest())
        if key not in groups:
            groups[key] = {"status": status, "data": data, "members": []}
            order.append(key)
        groups[key]["members"].append(name)
    return [groups[k] for k in order]


def attribute_areas(diffs, grid, width=FRAME_W):
    """diffs: iterable of (i, old, new). Returns {area_label: {"positions":
    [...], "area": Area_or_None}}; positions outside every area go under
    the key "(outside any area)"."""
    buckets = {}
    for i, _old, _new in diffs:
        area = grid[i] if i < len(grid) else None
        label = area.label() if area else "(outside any area)"
        b = buckets.setdefault(label, {"area": area, "positions": []})
        b["positions"].append(i)
    return buckets


def bbox_of(positions, width=FRAME_W, height=FRAME_H, margin=12):
    xs = [p % width for p in positions]
    ys = [p // width for p in positions]
    x0, x1 = max(0, min(xs) - margin), min(width, max(xs) + margin + 1)
    y0, y1 = max(0, min(ys) - margin), min(height, max(ys) + margin + 1)
    return x0, y0, x1 - x0, y1 - y0


def _boxes_touch(a, b):
    """True if two (x, y, w, h) boxes (half-open: x .. x+w, y .. y+h)
    overlap or share an edge with no gap between them."""
    ax0, ay0, aw, ah = a
    bx0, by0, bw, bh = b
    ax1, ay1 = ax0 + aw, ay0 + ah
    bx1, by1 = bx0 + bw, by0 + bh
    return ax0 <= bx1 and bx0 <= ax1 and ay0 <= by1 and by0 <= ay1


def merge_boxes(boxes_by_label):
    """One picture per touched *area* (bbox_of per area) cuts an adjacent,
    visually continuous change (e.g. several text-message lines, each its
    own sub-area) into separate strips. Merge boxes that overlap or touch
    into regions instead -- repeat pairwise merging until nothing more
    joins -- and return [(region_box, [labels])], the area labels making
    up each region (the per-area pixel counts and attribution stay in the
    report text; only the pictures are per merged region)."""
    items = [{"box": list(box), "labels": [label]} for label, box in boxes_by_label.items()]
    changed = True
    while changed:
        changed = False
        for i in range(len(items)):
            for j in range(i + 1, len(items)):
                if _boxes_touch(tuple(items[i]["box"]), tuple(items[j]["box"])):
                    ax0, ay0, aw, ah = items[i]["box"]
                    bx0, by0, bw, bh = items[j]["box"]
                    x0, y0 = min(ax0, bx0), min(ay0, by0)
                    x1 = max(ax0 + aw, bx0 + bw)
                    y1 = max(ay0 + ah, by0 + bh)
                    items[i]["box"] = [x0, y0, x1 - x0, y1 - y0]
                    items[i]["labels"].extend(items[j]["labels"])
                    del items[j]
                    changed = True
                    break
            if changed:
                break
    return [(tuple(it["box"]), it["labels"]) for it in items]


def bare_area_name(label):
    """"E5 (in E)" -> "E5"; a label with no parent (e.g. "B",
    "(outside any area)") is returned unchanged."""
    return label.split(" (")[0]


def slug(text):
    return "".join(c if c.isalnum() or c == "-" else "_" for c in text).strip("_") or "area"


def region_name(labels, index):
    """A filename for a merged region: the bare area names joined by "-"
    when there are few enough to stay a sane filename (dmi_display's own
    naming, e.g. "E5-E9"), else "r<index>" (the full label list still
    goes in the report caption)."""
    bare = sorted(set(bare_area_name(l) for l in labels))
    if len(bare) <= 4:
        return slug("-".join(bare))
    return "r%d" % index


# ---------------------------------------------------------------------
# Picture rendering: before | after | difference triptychs
# ---------------------------------------------------------------------

def _best_factor(dims_fn, min_short=400, max_long=1500, max_f=8):
    """The integer factor 1..max_f that grows a picture (whose total
    width/height at factor f is given by dims_fn(f)) until its short edge
    reaches about min_short, but never past max_long on its long edge --
    except factor 1 is always accepted (a crop already wider than
    max_long at factor 1 has no smaller factor to fall back to)."""
    best = 1
    for f in range(1, max_f + 1):
        tw, th = dims_fn(f)
        if f > 1 and max(tw, th) > max_long:
            break
        best = f
        if min(tw, th) >= min_short:
            break
    return best


def choose_scale(w, h, min_short=400, max_long=1500):
    """Integer scale factor 1..8 for a single w x h panel (render_single:
    an added/removed golden has only one side to show)."""
    return _best_factor(lambda f: (w * f, h * f), min_short, max_long)


def choose_layout(w, h, sep=SEPARATOR_W, min_short=400, max_long=1500):
    """Pick the triptych's panel layout -- the three w x h panels
    (before, after, difference) side by side, or stacked -- and the
    integer scale factor: whichever layout reaches the larger factor
    under the picture sizing rule (short edge >= ~min_short where
    possible, long edge <= ~max_long, factor 1..8). A wide, short crop
    (adjacent text lines merged into one region, say) stacks taller
    instead of staying a thin strip; a tall, narrow one stays side by
    side.

    On a tie (most often factor 1 each, neither reaching min_short: the
    whole-frame case, 640x480), prefer whichever of the two stays within
    max_long over one that does not (a whole frame is 1924px wide side
    by side at factor 1, over the cap, but 640 x 1444 stacked, within
    it); side by side if both do, or neither does."""
    side_dims = lambda f: (3 * w * f + 2 * sep, h * f)
    stack_dims = lambda f: (w * f, 3 * h * f + 2 * sep)
    f_side = _best_factor(side_dims, min_short, max_long)
    f_stack = _best_factor(stack_dims, min_short, max_long)
    if f_stack > f_side:
        return "stacked", f_stack
    if f_side > f_stack:
        return "side_by_side", f_side
    stack_ok = max(stack_dims(f_stack)) <= max_long
    side_ok = max(side_dims(f_side)) <= max_long
    if stack_ok and not side_ok:
        return "stacked", f_stack
    return "side_by_side", f_side


def _pixels_rgb(index_row, w):
    out = []
    for x in range(w):
        c = index_row[x]
        out.append(bytes(PALETTE[c]) if 0 <= c < len(PALETTE) else bytes(MAGENTA))
    return out


def _dim(rgb, factor=0.4):
    return bytes(int(v * factor) for v in rgb)


def render_triptych(before_idx, after_idx, changed, box, width=FRAME_W):
    """before_idx/after_idx: full-frame bytes of colour indices (or None
    for an added/removed golden, where only one side exists).
    changed: a set of raw frame indices that differ, used for the
    difference panel. box: (x, y, w, h) to crop to. Panels are laid out
    side by side or stacked, whichever choose_layout picks for this
    crop's shape, in reading order (before, after, difference). Returns
    (PNG bytes, layout) -- the caller needs the layout too, to say it in
    words next to the picture (BLIND.md, for a reviewer who must not
    need REPORT.md's area/caption text to make sense of the picture)."""
    x0, y0, w, h = box
    layout, f = choose_layout(w, h)

    def panel(idx_buf, dim_panel):
        rows = []
        for yy in range(y0, y0 + h):
            row = idx_buf[yy * width + x0: yy * width + x0 + w] if idx_buf else None
            pixels = []
            for xx in range(w):
                i = yy * width + x0 + xx
                if dim_panel:
                    base_c = after_idx if after_idx is not None else before_idx
                    c = base_c[i] if base_c is not None else 0
                    rgb = bytes(PALETTE[c]) if 0 <= c < len(PALETTE) else bytes(MAGENTA)
                    pixels.append(bytes(MAGENTA) if i in changed else _dim(rgb))
                else:
                    if row is None:
                        pixels.append(bytes((40, 40, 40)))  # no such side
                    else:
                        c = row[xx]
                        pixels.append(bytes(PALETTE[c]) if 0 <= c < len(PALETTE)
                                      else bytes(MAGENTA))
            rows.append(b"".join(pixels))
        return rows

    before_rows = panel(before_idx, False)
    after_rows = panel(after_idx, False)
    diff_rows = panel(None, True)

    def scale_rows(rows):
        out = []
        for row in rows:
            cells = [row[i:i + 3] for i in range(0, len(row), 3)]
            scaled = b"".join(c * f for c in cells)
            out.extend([scaled] * f)
        return out

    panels = [scale_rows(before_rows), scale_rows(after_rows), scale_rows(diff_rows)]
    pw, ph = w * f, h * f
    if layout == "side_by_side":
        sep_col = bytes(SEPARATOR) * SEPARATOR_W
        total_w = 3 * pw + 2 * SEPARATOR_W
        out_rows = [panels[0][r] + sep_col + panels[1][r] + sep_col + panels[2][r]
                    for r in range(ph)]
        return encode_png(total_w, ph, out_rows), layout
    else:  # stacked: before on top, then after, then difference
        sep_row = bytes(SEPARATOR) * pw
        out_rows = (panels[0] + [sep_row] * SEPARATOR_W
                    + panels[1] + [sep_row] * SEPARATOR_W
                    + panels[2])
        return encode_png(pw, 3 * ph + 2 * SEPARATOR_W, out_rows), layout


def render_single(idx_buf, box, width=FRAME_W, missing_rgb=(40, 40, 40)):
    """A single scaled picture (added/removed golden: only one side)."""
    x0, y0, w, h = box
    f = choose_scale(w, h)
    rows = []
    for yy in range(y0, y0 + h):
        pixels = []
        for xx in range(w):
            c = idx_buf[yy * width + x0 + xx]
            pixels.append(bytes(PALETTE[c]) if 0 <= c < len(PALETTE) else bytes(MAGENTA))
        rows.append(b"".join(pixels))

    def scale_rows(rows):
        out = []
        for row in rows:
            cells = [row[i:i + 3] for i in range(0, len(row), 3)]
            scaled = b"".join(c * f for c in cells)
            out.extend([scaled] * f)
        return out

    scaled = scale_rows(rows)
    return encode_png(w * f, h * f, scaled)


def encode_png(width, height, rgb_rows):
    """A minimal truecolor PNG encoder (stdlib zlib only), one filter
    byte 0 per row, no palette (the diff picture needs a colour -
    magenta - the palette itself does not carry)."""
    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff))
    raw = b"".join(b"\0" + row for row in rgb_rows)
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9))
            + chunk(b"IEND", b""))


# ---------------------------------------------------------------------
# On-board (EVC_Outbox) record decoding -- a vendored copy of
# test/tools/evc_dump.py's --diff logic (kept separate on purpose: a
# base revision under review may not carry evc_dump.py, or an older
# version of it without the options this tool needs). Keep this in sync
# with evc_dump.py by hand if the record wire format changes.
# ---------------------------------------------------------------------

EVC_PORTS = ['BTM', 'RTM', 'ODO', 'TIU', 'DMI', 'ATO', 'JRU']
EVC_DMI_TYPES = {0x01: 'SPEED_STATE', 0x02: 'MODE_LEVEL', 0x05: 'TRACK_COND',
                 0x06: 'PLANNING', 0x07: 'STATUS', 0x0A: 'ONBOARD'}


def evc_records(data):
    i, out = 0, []
    while i + 3 <= len(data):
        port = data[i]
        length = data[i + 1] + 256 * data[i + 2]
        payload = data[i + 3:i + 3 + length]
        out.append((EVC_PORTS[port] if port < len(EVC_PORTS) else str(port),
                    bytes(payload)))
        i += 3 + length
    if i != len(data):
        raise ValueError("not a sequence of whole records")
    return out


def evc_kind(rec):
    port, p = rec
    if port == 'DMI' and p:
        return 'DMI:' + EVC_DMI_TYPES.get(p[0], '%02X' % p[0])
    if port == 'JRU' and p:
        return 'JRU:%d' % p[0]
    return port


def evc_describe(rec):
    port, p = rec
    k = evc_kind(rec)
    if k == 'DMI:SPEED_STATE' and len(p) == 26:
        q = p[5:]

        def u16(n):
            return q[n] + 256 * q[n + 1]
        return ('%s v %d perm %d target %d rel %d sbi %d w %d d %d mon %d '
                'dial %d flags %d st %d mrdt %d'
                % (k, u16(0), u16(2), u16(4), u16(6), u16(8), u16(10),
                   q[12] + 256 * (q[13] + 256 * (q[14] + 256 * q[15])),
                   q[16], q[17], q[18], q[19], q[20]))
    if k == 'DMI:STATUS' and len(p) == 28:
        q = p[5:]
        geo = q[16] + 256 * (q[17] + 256 * (q[18] + 256 * q[19]))
        return ('%s brake %d tti %d geo %s' % (
            k, q[0], q[8] + 256 * q[9],
            'unknown' if geo == 0xFFFFFFFF else str(geo)))
    if port == 'JRU' and len(p) >= 8:
        cyc = p[4] + 256 * (p[5] + 256 * (p[6] + 256 * p[7]))
        return '%s %d %d %d (cycle %d)' % (k, p[1], p[2], p[3], cyc)
    if port == 'TIU' and len(p) == 2:
        return 'TIU commands %d reasons %d' % (p[0], p[1])
    return '%s %s' % (k, p.hex())


def evc_cycles(recs):
    out = [[]]
    for r in recs:
        if evc_kind(r) == 'DMI:MODE_LEVEL' and out[-1]:
            out.append([])
        out[-1].append(r)
    return out


def evc_diff(old_bytes, new_bytes, max_lines=40):
    """Diff two evc_test golden captures cycle-group by cycle-group, the
    way evc_dump.py --diff does. Returns (lines, kind_delta, diff_groups,
    total_groups): lines is the full diff text (not just the excerpt),
    kind_delta maps a record kind to [removed, added] counts (the group
    signature), diff_groups/total_groups the cycle-group counts."""
    co = evc_cycles(evc_records(old_bytes))
    cn = evc_cycles(evc_records(new_bytes))
    lines = []
    kind_delta = {}
    diff_groups = 0
    for n in range(max(len(co), len(cn))):
        ca = co[n] if n < len(co) else []
        cb = cn[n] if n < len(cn) else []
        da = [evc_describe(r) for r in ca]
        db = [evc_describe(r) for r in cb]
        if da == db:
            continue
        diff_groups += 1
        removed = [r for r, d in zip(ca, da) if d not in db]
        added = [r for r, d in zip(cb, db) if d not in da]
        lines.append("cycle group %d:" % n)
        for r in removed:
            lines.append("  - " + evc_describe(r))
            kind_delta.setdefault(evc_kind(r), [0, 0])[0] += 1
        for r in added:
            lines.append("  + " + evc_describe(r))
            kind_delta.setdefault(evc_kind(r), [0, 0])[1] += 1
    return lines, kind_delta, diff_groups, max(len(co), len(cn))


def group_changed_onboard(names_bh):
    """names_bh: {name: (base_bytes, head_bytes)}. Groups by signature:
    the set of record kinds that differ with their +/- counts."""
    groups = {}
    order = []
    details = {}
    for name in sorted(names_bh):
        b, h = names_bh[name]
        lines, kind_delta, diff_groups, total_groups = evc_diff(b, h)
        sig = tuple(sorted((k, tuple(v)) for k, v in kind_delta.items()))
        key = ("changed", sig)
        if key not in groups:
            groups[key] = {"status": "changed", "signature": sig, "members": []}
            order.append(key)
        groups[key]["members"].append(name)
        details[name] = (lines, kind_delta, diff_groups, total_groups)
    return [groups[k] for k in order], details


# ---------------------------------------------------------------------
# Sides
# ---------------------------------------------------------------------

class Side:
    def __init__(self, label, commit, display, onboard, sha, areas):
        self.label = label
        self.commit = commit
        self.display = display
        self.onboard = onboard
        self.sha = sha
        self.areas = areas


def cache_paths(sha):
    base = CACHE_ROOT / sha
    return base, base / "display", base / "onboard", base / "sha.json", base / "areas.json", base / "DONE"


def load_cached_side(sha, label):
    base, disp_dir, onb_dir, sha_json, areas_json, done = cache_paths(sha)
    display = {}
    for p in disp_dir.rglob("*.actual"):
        display[golden_name(disp_dir, p)] = p.read_bytes()
    onboard = {}
    for p in onb_dir.glob("*.bin"):
        onboard["evc/" + p.stem] = p.read_bytes()
    sha_map = json.loads(sha_json.read_text())
    areas = [Area.from_json(d) for d in json.loads(areas_json.read_text())]
    return Side(label, sha, display, onboard, sha_map, areas)


def save_cache(sha, display, onboard, sha_map, areas):
    base, disp_dir, onb_dir, sha_json, areas_json, done = cache_paths(sha)
    if base.exists():
        shutil.rmtree(base)
    disp_dir.mkdir(parents=True)
    onb_dir.mkdir(parents=True)
    for name, data in display.items():
        dest = disp_dir / (name + ".actual")
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
    for name, data in onboard.items():
        (onb_dir / (name[4:] + ".bin") if name.startswith("evc/")
         else onb_dir / (name + ".bin")).write_bytes(data)
    sha_json.write_text(json.dumps(sha_map))
    areas_json.write_text(json.dumps([a.to_json() for a in areas]))
    done.write_text("ok\n")


def get_revision_side(rev, env):
    sha = git(["rev-parse", rev]).stdout.strip()
    _, _, _, _, _, done = cache_paths(sha)
    label = "%s (%s)" % (rev, sha) if rev != sha else sha
    if done.exists():
        print("golden_review: %s: cached" % label, file=sys.stderr)
        return load_cached_side(sha, label)
    tmp = Path(tempfile.mkdtemp(prefix="golden-review-wt-"))
    wt = tmp / "wt"
    try:
        git(["worktree", "add", "--detach", str(wt), sha])
        try:
            build_mains(wt, env)
            evc_dump_dir = tmp / "evc_dump"
            evc_dump_dir.mkdir()
            run_dumps(wt, env, evc_dump_dir)
            display, onboard, sha_map = collect_dumps(wt, evc_dump_dir)
            areas = compile_areas(find_dmi_dir(wt), env)
            save_cache(sha, display, onboard, sha_map, areas)
        finally:
            git(["worktree", "remove", "-f", "-f", str(wt)], check=False)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return Side(label, sha, display, onboard, sha_map, areas)


def get_worktree_side(env, out_dir):
    root = REPO_ROOT
    commit = git(["rev-parse", "HEAD"], cwd=root, check=False).stdout.strip() or "?"
    dirty = bool(git(["status", "--porcelain"], cwd=root, check=False).stdout.strip())
    label = "working tree (%s%s)" % (commit, ", uncommitted changes" if dirty else "")
    build_mains(root, env)
    dumps_dir = out_dir / "_dumps" / "worktree"
    if dumps_dir.exists():
        shutil.rmtree(dumps_dir)
    dumps_dir.mkdir(parents=True)
    evc_dump_dir = dumps_dir / "evc_dump"
    evc_dump_dir.mkdir()
    run_dumps(root, env, evc_dump_dir)
    display, onboard, sha_map = collect_dumps(
        root, evc_dump_dir, move_actuals_to=dumps_dir / "display")
    areas = compile_areas(find_dmi_dir(root), env)
    return Side(label, commit, display, onboard, sha_map, areas)


# ---------------------------------------------------------------------
# Comparing two sides
# ---------------------------------------------------------------------

def declared_marking(touched_area_names, declared):
    """touched_area_names: iterable of Area objects or None (outside).
    declared: list of area names from --areas. Returns (marking_text,
    outside_list)."""
    if not declared:
        return "no --areas given", []
    declared_set = set(declared)
    outside = []
    for area in touched_area_names:
        if area is None:
            outside.append("(outside any area)")
            continue
        covered = area.name in declared_set or (area.parent != "-" and area.parent in declared_set)
        if not covered:
            outside.append(area.name)
    if outside:
        return "OUTSIDE declared areas: " + ", ".join(sorted(set(outside))), sorted(set(outside))
    return "inside declared areas", []


def compare_sides(base, head, areas_decl, out_dir):
    display_names = sorted(set(base.display) | set(head.display))
    onboard_names = sorted(set(base.onboard) | set(head.onboard))

    changed_display_bh = {}
    added_display, removed_display = {}, {}
    not_rerecorded, sha_only = [], []
    for name in display_names:
        b, h = base.display.get(name), head.display.get(name)
        if b is None and h is not None:
            added_display[name] = h
        elif h is None and b is not None:
            removed_display[name] = b
        elif b != h:
            changed_display_bh[name] = (b, h)
            if base.sha.get(name) == head.sha.get(name):
                not_rerecorded.append(name)
        else:
            if base.sha.get(name) != head.sha.get(name):
                sha_only.append(name)

    changed_onboard_bh = {}
    added_onboard, removed_onboard = {}, {}
    for name in onboard_names:
        b, h = base.onboard.get(name), head.onboard.get(name)
        if b is None and h is not None:
            added_onboard[name] = h
        elif h is None and b is not None:
            removed_onboard[name] = b
        elif b != h:
            changed_onboard_bh[name] = (b, h)
            if base.sha.get(name) == head.sha.get(name):
                not_rerecorded.append(name)
        else:
            if base.sha.get(name) != head.sha.get(name):
                sha_only.append(name)

    grid = build_area_grid(head.areas)

    disp_groups = (group_changed_display(changed_display_bh)
                   + group_added_removed(added_display, "added")
                   + group_added_removed(removed_display, "removed"))
    onb_groups, onb_details = group_changed_onboard(changed_onboard_bh)
    onb_groups += (group_added_removed(added_onboard, "added")
                   + group_added_removed(removed_onboard, "removed"))

    # Attach area attribution + marking to each display group.
    for g in disp_groups:
        if g["status"] == "changed":
            buckets = attribute_areas(g["diffs"], grid)
            g["buckets"] = buckets
            areas_touched = [b["area"] for b in buckets.values()]
            g["marking"], g["outside"] = declared_marking(areas_touched, areas_decl)
            g["pixel_count"] = len(g["diffs"])
        else:
            # An added/removed golden has no "before" to diff against, so
            # it is not attributed to an area; treat it as OUTSIDE whenever
            # areas were declared (a new or vanished golden is always worth
            # a second look), "no --areas given" otherwise.
            g["buckets"] = {}
            if areas_decl:
                g["marking"] = "OUTSIDE declared areas: %s golden, not attributed to an area" % g["status"]
            else:
                g["marking"] = "no --areas given"
            g["outside"] = []
            g["pixel_count"] = None

    for g in onb_groups:
        g["marking"] = "n/a (on-board)"
        g["outside"] = []

    # Order: display groups outside-first, then onboard groups outside-first.
    disp_groups.sort(key=lambda g: (0 if g["marking"].startswith("OUTSIDE") else 1,
                                     -(g["pixel_count"] or 0)))
    onb_groups.sort(key=lambda g: (0,))

    return {
        "display_groups": disp_groups,
        "onboard_groups": onb_groups,
        "onboard_details": onb_details,
        "not_rerecorded": sorted(set(not_rerecorded)),
        "sha_only": sorted(set(sha_only)),
    }


# ---------------------------------------------------------------------
# Rendering the report
# ---------------------------------------------------------------------

def layout_words(layout):
    """How a triptych's panels are laid out, in words, so a reviewer who
    must not be told what the area/caption means (BLIND.md) still knows
    which panel is which."""
    if layout == "side_by_side":
        return "three panels side by side, left to right: before, after, difference"
    return "three panels stacked, top to bottom: before, after, difference"


def render_group_pictures(gid, g, base, head, out_dir):
    """Write the PNGs for one display group; return a list of
    {"caption", "path" (relative), "layout_words"} dicts -- caption is
    the area/region name (REPORT.md only; BLIND.md must not use it to
    say what changed), layout_words says the panel order in words
    (needed by both: a picture alone does not say which panel is which)."""
    pics = []
    gdir = out_dir / "display" / gid
    gdir.mkdir(parents=True, exist_ok=True)
    rep = g["members"][0]
    if g["status"] == "changed":
        before = base.display[rep]
        after = head.display[rep]
        changed = set(i for i, _, _ in g["diffs"])
        buckets = g["buckets"]
        boxes = {label: bbox_of(b["positions"]) for label, b in buckets.items()}
        # One picture per touched *region* (adjacent/overlapping touched
        # areas merged), not one per area: several sub-areas forming one
        # visually continuous change (e.g. adjacent text-message lines)
        # would otherwise be cut into separate strips. The per-area
        # attribution and pixel counts (buckets, above) stay in the
        # report text regardless.
        regions = merge_boxes(boxes)
        covers_most = False
        if regions:
            xs0 = min(r[0][0] for r in regions)
            ys0 = min(r[0][1] for r in regions)
            xs1 = max(r[0][0] + r[0][2] for r in regions)
            ys1 = max(r[0][1] + r[0][3] for r in regions)
            union_area = (xs1 - xs0) * (ys1 - ys0)
            covers_most = union_area >= 0.6 * FRAME_SIZE
        if covers_most or not regions:
            png, layout = render_triptych(before, after, changed, (0, 0, FRAME_W, FRAME_H))
            path = gdir / "whole_frame.png"
            path.write_bytes(png)
            pics.append({"caption": "whole frame",
                         "path": "display/%s/whole_frame.png" % gid,
                         "layout_words": layout_words(layout)})
        else:
            for idx, (box, labels) in enumerate(regions, start=1):
                name = region_name(labels, idx)
                png, layout = render_triptych(before, after, changed, box)
                path = gdir / ("%s.png" % name)
                path.write_bytes(png)
                caption = ", ".join(sorted(set(labels)))
                pics.append({"caption": caption,
                             "path": "display/%s/%s.png" % (gid, name),
                             "layout_words": layout_words(layout)})
    else:
        data = g["data"]
        box = (0, 0, FRAME_W, FRAME_H)
        png = render_single(data, box)
        path = gdir / "frame.png"
        path.write_bytes(png)
        which = "new" if g["status"] == "added" else "removed"
        pics.append({"caption": g["status"],
                     "path": "display/%s/frame.png" % gid,
                     "layout_words": "one panel: the %s picture" % which})
    return pics


def render_group_onboard(gid, g, details, out_dir):
    gdir = out_dir / "onboard" / gid
    gdir.mkdir(parents=True, exist_ok=True)
    rep = g["members"][0]
    excerpt = []
    full_path = None
    if g["status"] == "changed":
        lines, kind_delta, diff_groups, total_groups = details[rep]
        full_path = gdir / "diff.txt"
        full_path.write_text("\n".join(lines) + "\n")
        excerpt = lines[:40]
        g["summary"] = {k: "-%d +%d" % (v[0], v[1]) for k, v in kind_delta.items()}
        g["diff_groups"] = diff_groups
        g["total_groups"] = total_groups
    return excerpt, (("onboard/%s/diff.txt" % gid) if full_path else None)


def fmt_sides(base, head):
    return ("- base: `%s` -- %s\n- head: `%s` -- %s\n"
            % (base.commit, base.label, head.commit, head.label))


INSTRUCTIONS = """## Instructions for the judging reviewer

The descriptions below come from a reviewer who has not seen this file
or review.json (BLIND.md, next to this report -- a small model is
enough for that first pass; it looked at the pictures and diff
excerpts alone, with no idea what the change was meant to do). For each
group, compare its description and its numbers (changed pixel count or
record kinds) with the stated intent and answer **as intended** /
**not intended** / **cannot tell**, on the group's `Verdict:` line, and
name every side effect the intent does not mention -- even one that is
acceptable (text that re-wrapped along with an intended character
change, say). A group whose description is missing, or does not account
for its changed pixel count (a few characters described against
thousands of changed pixels, say), is `cannot tell` and goes back to
BLIND.md's reviewer. Be especially suspicious of a group marked
`OUTSIDE declared areas`. Never approve a group you did not look at.
"""

BLIND_INSTRUCTIONS = """# Golden review: picture descriptions

Describe every group below from its pictures (display) or diff excerpt
(on-board) alone. Do not read REPORT.md or review.json -- nothing here
says what the change was meant to do, and the description must not
guess it either.

Open every picture. For each group, list **every** visible difference
between the before and after panels, as separate items:
- characters or symbols that appeared, disappeared, or changed;
- text that moved sideways or to another line -- which words, and
  where the line breaks fall before and after;
- text cut off, or gaining or losing an ellipsis;
- changes of colour, frames, lines, spacing.

Quote text literally, exactly as it reads in each panel. Then add a
line `magenta covers:` saying which part of the picture is magenta in
the difference panel (a few characters, whole lines, everything). For
an on-board group, say literally which record kinds and fields differ
and how, with the values before and after, from the diff excerpt.

No summary, no guess at the purpose of the change, no judgement of
whether it is correct -- only what is visibly different. Say so plainly
when something is unreadable or cut off at an edge.
"""


def write_report(out_dir, result, args, base, head):
    disp = result["display_groups"]
    onb = result["onboard_groups"]

    group_ids = {}
    gi = 0
    for g in disp:
        gi += 1
        group_ids[id(g)] = "d%d" % gi
    gi = 0
    for g in onb:
        gi += 1
        group_ids[id(g)] = "o%d" % gi

    # Render/compute once, reuse for both REPORT.md and BLIND.md.
    disp_pics = {group_ids[id(g)]: render_group_pictures(group_ids[id(g)], g, base, head, out_dir)
                 for g in disp}
    onb_render = {group_ids[id(g)]: render_group_onboard(group_ids[id(g)], g, result["onboard_details"], out_dir)
                  for g in onb}

    lines = []
    lines.append("# Golden review\n")
    lines.append(fmt_sides(base, head))
    lines.append("Intent: %s\n" % (args.intent or "(none given)"))
    lines.append("Declared areas: %s\n" % (", ".join(args.areas_list) if args.areas_list else "(none given)"))
    lines.append("")
    lines.append(INSTRUCTIONS)

    if result["not_rerecorded"]:
        lines.append("**Not re-recorded** (dumped bytes changed, .sha256 text did not): "
                      + ", ".join(result["not_rerecorded"]) + "\n")
    if result["sha_only"]:
        lines.append("**.sha256 text changed, dumped bytes did not** (suspicious): "
                      + ", ".join(result["sha_only"]) + "\n")

    lines.append("## Groups\n")
    lines.append("| id | kind | members | changed | areas | marking |")
    lines.append("|----|------|---------|---------|-------|---------|")

    for g in disp:
        gid = group_ids[id(g)]
        changed_col = ("%d pixels" % g["pixel_count"]) if g["pixel_count"] is not None else g["status"]
        areas_col = ", ".join(sorted(g["buckets"])) if g.get("buckets") else "-"
        lines.append("| %s | display | %d | %s | %s | %s |"
                      % (gid, len(g["members"]), changed_col, areas_col or "-", g["marking"]))
    for g in onb:
        gid = group_ids[id(g)]
        if g["status"] == "changed":
            # g["signature"] (set at grouping time) is used here rather than
            # g["summary"] (set by render_group_onboard above) so the table
            # reflects it too, independent of render order.
            changed_col = ", ".join("%s -%d +%d" % (k, counts[0], counts[1])
                                     for k, counts in g["signature"]) or "(no record kind differs)"
        else:
            changed_col = g["status"]
        lines.append("| %s | on-board | %d | %s | - | %s |"
                      % (gid, len(g["members"]), changed_col, g["marking"]))

    lines.append("")
    lines.append("## Display groups\n")
    for g in disp:
        gid = group_ids[id(g)]
        lines.append("### %s (%s, %d member%s)\n"
                      % (gid, g["status"], len(g["members"]), "" if len(g["members"]) == 1 else "s"))
        lines.append("Members: " + ", ".join(g["members"]) + "\n")
        lines.append("Marking: " + g["marking"] + "\n")
        for pic in disp_pics[gid]:
            lines.append("- %s: ![%s](%s)" % (pic["caption"], pic["caption"], pic["path"]))
        lines.append("")
        lines.append("Verdict: ")
        lines.append("")

    lines.append("## On-board groups\n")
    for g in onb:
        gid = group_ids[id(g)]
        excerpt, relpath = onb_render[gid]
        lines.append("### %s (%s, %d member%s)\n"
                      % (gid, g["status"], len(g["members"]), "" if len(g["members"]) == 1 else "s"))
        lines.append("Members: " + ", ".join(g["members"]) + "\n")
        if g["status"] == "changed":
            lines.append("Record kinds: " + (", ".join("%s %s" % (k, v) for k, v in g.get("summary", {}).items())
                                              or "(none)") + "\n")
            lines.append("%d of %d cycle groups differ.\n" % (g.get("diff_groups", 0), g.get("total_groups", 0)))
            if relpath:
                lines.append("Full diff: [%s](%s)\n" % (relpath, relpath))
            if excerpt:
                lines.append("```")
                lines.extend(excerpt)
                lines.append("```")
        lines.append("")
        lines.append("Verdict: ")
        lines.append("")

    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "REPORT.md").write_text("\n".join(lines) + "\n")
    (out_dir / "BLIND.md").write_text(
        write_blind(result, group_ids, disp_pics, onb_render))

    def group_json(g, gid):
        d = {"id": gid, "status": g["status"], "members": g["members"], "marking": g["marking"]}
        if "pixel_count" in g:
            d["pixel_count"] = g["pixel_count"]
        if "buckets" in g and g["buckets"]:
            d["areas"] = sorted(g["buckets"])
        if "signature" in g:
            d["signature"] = g["signature"]
        if "summary" in g:
            d["record_kinds"] = g["summary"]
        return d

    review = {
        "base": {"commit": base.commit, "label": base.label},
        "head": {"commit": head.commit, "label": head.label},
        "intent": args.intent,
        "areas": args.areas_list,
        "not_rerecorded": result["not_rerecorded"],
        "sha_only": result["sha_only"],
        "display_groups": [group_json(g, group_ids[id(g)]) for g in disp],
        "onboard_groups": [group_json(g, group_ids[id(g)]) for g in onb],
        "blind_file": "BLIND.md",
    }
    (out_dir / "review.json").write_text(json.dumps(review, indent=2))

    outside = sum(1 for g in disp if g["marking"].startswith("OUTSIDE")) \
        + sum(1 for g in onb if g["marking"].startswith("OUTSIDE"))
    summary = ("golden_review: %d display groups (%d frames), "
               "%d on-board groups (%d goldens), %d outside declared areas"
               % (len(disp), sum(len(g["members"]) for g in disp),
                  len(onb), sum(len(g["members"]) for g in onb), outside))
    return summary


def write_blind(result, group_ids, disp_pics, onb_render):
    """BLIND.md's text: instructions, then per group its id, kind, member
    count, pictures (each with its layout in words) or on-board diff
    excerpt, and an empty Description: line -- nothing here may say what
    the change was meant to do: no intent, no declared areas, no
    inside/OUTSIDE marking, no commit subjects, no member (golden) names
    either (a scenario's own name, e.g. one naming the fix, could give
    the game away)."""
    disp = result["display_groups"]
    onb = result["onboard_groups"]
    lines = [BLIND_INSTRUCTIONS]

    lines.append("## Display groups\n")
    for g in disp:
        gid = group_ids[id(g)]
        lines.append("### %s (display, %d member%s)\n"
                      % (gid, len(g["members"]), "" if len(g["members"]) == 1 else "s"))
        for pic in disp_pics[gid]:
            lines.append("- ![%s](%s) -- %s" % (gid, pic["path"], pic["layout_words"]))
        lines.append("")
        lines.append("Description: ")
        lines.append("")

    lines.append("## On-board groups\n")
    for g in onb:
        gid = group_ids[id(g)]
        excerpt, relpath = onb_render[gid]
        lines.append("### %s (on-board, %d member%s)\n"
                      % (gid, len(g["members"]), "" if len(g["members"]) == 1 else "s"))
        if relpath:
            lines.append("Full diff: [%s](%s)\n" % (relpath, relpath))
        if excerpt:
            lines.append("```")
            lines.extend(excerpt)
            lines.append("```")
        else:
            lines.append("(no record kind differs)")
        lines.append("")
        lines.append("Description: ")
        lines.append("")

    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------
# Self test (--check-tool)
# ---------------------------------------------------------------------

def check_tool():
    ok = True

    def check(cond, what):
        nonlocal ok
        status = "ok" if cond else "FAIL"
        if not cond:
            ok = False
        print("%-60s %s" % (what, status))

    # A tiny synthetic 8x6 "frame" with a main area M (0,0,4,6) holding a
    # sub-area S (1,1,2,2), and the rest outside any area.
    areas = [Area("M", "-", 0, 0, 4, 6), Area("S", "M", 1, 1, 2, 2)]
    W, H = 8, 6
    grid = build_area_grid(areas, width=W, height=H)
    check(grid[1 * W + 1].name == "S", "pixel (1,1) attributed to the sub-area S")
    check(grid[0 * W + 0].name == "M", "pixel (0,0) attributed to the main area M")
    check(grid[5 * W + 7] is None, "pixel (7,5) outside any area")

    base = bytearray(W * H)
    head = bytearray(W * H)
    # Change one pixel inside S, one inside M but outside S, one outside.
    head[1 * W + 1] = 3     # inside S
    head[0 * W + 0] = 2     # inside M only
    head[5 * W + 7] = 9     # outside any area
    diffs = tuple((i, base[i], head[i]) for i in diff_positions(bytes(base), bytes(head)))
    check(len(diffs) == 3, "three changed pixels found")
    buckets = attribute_areas(diffs, grid, width=W)
    check(set(buckets) == {"S (in M)", "M", "(outside any area)"},
          "attribution buckets: S (in M), M, (outside any area)")
    box = bbox_of(buckets["S (in M)"]["positions"], width=W, height=H, margin=1)
    check(box == (0, 0, 3, 3), "bounding box of the S bucket, with margin, clamped")

    # Merging adjacent/overlapping boxes into regions (several touched
    # sub-areas that are really one visually continuous change).
    check(bare_area_name("E5 (in E)") == "E5", "bare_area_name strips the parent suffix")
    check(region_name(["E5 (in E)", "E6 (in E)", "E7 (in E)"], 1) == "E5-E6-E7",
          "region_name joins bare area names")

    touching = merge_boxes({"A": (0, 0, 5, 5), "B": (5, 0, 5, 5), "C": (100, 100, 5, 5)})
    check(len(touching) == 2, "two touching boxes merge, a far one stays separate")
    merged = next(r for r in touching if len(r[1]) == 2)
    check(merged[0] == (0, 0, 10, 5), "merged region box covers both touching boxes")
    check(set(merged[1]) == {"A", "B"}, "merged region keeps both area labels")

    overlapping = merge_boxes({"A": (0, 0, 10, 10), "B": (5, 5, 10, 10)})
    check(len(overlapping) == 1 and overlapping[0][0] == (0, 0, 15, 15),
          "overlapping boxes merge into their union")

    gapped = merge_boxes({"A": (0, 0, 5, 5), "B": (6, 0, 5, 5)})
    check(len(gapped) == 2, "boxes with a one-pixel gap do not merge")

    # Grouping: two identical changes group together, a third different one does not.
    names_bh = {
        "f1": (bytes(base), bytes(head)),
        "f2": (bytes(base), bytes(head)),
    }
    head2 = bytearray(base)
    head2[2] = 5
    names_bh["f3"] = (bytes(base), bytes(head2))
    groups = group_changed_display(names_bh, width=W)
    check(len(groups) == 2, "two groups from three frames, two identical")
    sizes = sorted(len(g["members"]) for g in groups)
    check(sizes == [1, 2], "group sizes 2 and 1")

    # Added/removed grouping by content.
    added = {"a1": b"\x01\x02", "a2": b"\x01\x02", "a3": b"\x03\x04"}
    agroups = group_added_removed(added, "added")
    check(len(agroups) == 2, "added goldens grouped by content (two of three identical)")

    # Scale rule (single panel, render_single: an added/removed golden):
    # short edge >= ~400 where the factor allows, long edge <= ~1500,
    # factor in 1..8.
    fs = choose_scale(50, 50)
    check(1 <= fs <= 8, "single-panel scale factor in range for a 50x50 crop")
    check(50 * fs >= 400 or fs == 8, "single-panel 50x50 crop reaches ~400px (or caps at factor 8)")
    check(50 * fs <= 1500, "single-panel 50x50 crop stays within ~1500px")

    # Layout + scale rule (triptych, render_triptych): whichever of side
    # by side / stacked reaches the larger factor under the same limits;
    # side by side on a tie.
    def dims(layout, w, h, f):
        return ((3 * w * f + 2 * SEPARATOR_W, h * f) if layout == "side_by_side"
                else (w * f, 3 * h * f + 2 * SEPARATOR_W))

    layout, f = choose_layout(50, 50)
    tw, th = dims(layout, 50, 50, f)
    check(min(tw, th) >= 400 or f == 8, "50x50 triptych reaches ~400px short edge (or caps at factor 8)")
    check(max(tw, th) <= 1500, "50x50 triptych stays within ~1500px long edge")

    layout_fw, f_fw = choose_layout(FRAME_W, FRAME_H)
    check(f_fw == 1, "a whole-frame triptych falls back to factor 1 (already over the cap)")

    layout2, f2 = choose_layout(200, 100)
    tw2, th2 = dims(layout2, 200, 100, f2)
    check(max(tw2, th2) <= 1500, "200x100 triptych respects the long-edge cap")

    # A wide, short crop (several adjacent sub-areas merged into one wide
    # region) stacks instead of staying a thin strip: side by side caps
    # out at factor 1 (80px high), stacked reaches factor 2 (short edge
    # 484px).
    layout3, f3 = choose_layout(434, 80)
    check((layout3, f3) == ("stacked", 2),
          "434x80 crop picks the stacked layout, factor 2 (not an 80px-tall strip)")
    tw3, th3 = dims(layout3, 434, 80, f3)
    check(min(tw3, th3) >= 400, "434x80 crop's stacked triptych clears ~400px on its short edge")

    # A tall, narrow crop stays side by side (reaches a larger factor
    # that way: 3, vs 2 stacked).
    layout4, f4 = choose_layout(60, 200)
    check((layout4, f4) == ("side_by_side", 3),
          "60x200 crop picks the side-by-side layout, factor 3")

    # Tie at factor 1 (the whole-frame case): side by side is 1924px
    # wide, over the long-edge cap; stacked is 640 x 1444, within it --
    # take the one within the limit instead of defaulting to side by
    # side.
    layout5, f5 = choose_layout(FRAME_W, FRAME_H)
    check((layout5, f5) == ("stacked", 1),
          "whole-frame crop ties at factor 1, picks stacked (within the long-edge cap)")
    check(3 * FRAME_H * f5 + 2 * SEPARATOR_W <= 1500,
          "whole-frame stacked triptych respects the long-edge cap")

    # BLIND.md must not leak the intent, the declared areas, or the
    # inside/OUTSIDE marking -- build a tiny synthetic review with a
    # recognisable intent and a declared area that does not cover the
    # change (forcing an OUTSIDE marking in REPORT.md) and check BLIND.md
    # carries none of it.
    with tempfile.TemporaryDirectory(prefix="golden-review-blind-") as td:
        blind_dir = Path(td)
        tiny_areas = [Area("M", "-", 0, 0, 4, 4)]
        base_frame = bytes(FRAME_SIZE)
        head_frame = bytearray(base_frame)
        head_frame[0] = 5
        base_side = Side("base", "deadbeef", {"f1": base_frame}, {}, {"f1": "x"}, tiny_areas)
        head_side = Side("head", "cafef00d", {"f1": bytes(head_frame)}, {}, {"f1": "x"}, tiny_areas)
        secret_intent = "SECRET SPECIFIC INTENT TEXT"
        secret_area = "NOWHERE"
        fake_args = argparse.Namespace(intent=secret_intent, areas_list=[secret_area])
        blind_result = compare_sides(base_side, head_side, [secret_area], blind_dir)
        write_report(blind_dir, blind_result, fake_args, base_side, head_side)
        report_text = (blind_dir / "REPORT.md").read_text()
        blind_text = (blind_dir / "BLIND.md").read_text()
        check("OUTSIDE" in report_text, "synthetic REPORT.md marks the group OUTSIDE declared areas")
        check(secret_intent not in blind_text, "BLIND.md does not contain the intent text")
        check(secret_area not in blind_text, "BLIND.md does not contain the declared area list")
        check("OUTSIDE" not in blind_text, "BLIND.md does not contain the word OUTSIDE")
        check("f1" not in blind_text, "BLIND.md does not name the golden")

    # On-board diff: a record added, a record removed between two cycles.
    def rec(port, payload):
        pb = bytes(payload)
        return bytes([port]) + struct.pack("<H", len(pb)) + pb

    mode_level = rec(4, bytes([0x02] + [0] * 5))  # DMI:MODE_LEVEL, port 4 = DMI
    tiu_old = rec(3, bytes([1, 0]))                # TIU
    tiu_new = rec(3, bytes([2, 0]))                # TIU, different payload
    old_bytes = mode_level + tiu_old
    new_bytes = mode_level + tiu_new
    lines, kind_delta, diff_groups, total_groups = evc_diff(old_bytes, new_bytes)
    check(diff_groups == 1 and total_groups == 1, "one on-board cycle group differs")
    check(kind_delta.get("TIU") == [1, 1], "TIU counted as one removed, one added")

    print("golden_review --check-tool: %s" % ("ok" if ok else "FAILED"))
    return 0 if ok else 1


# ---------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------

def parse_args(argv):
    p = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--base", default="HEAD",
                    help="revision for the 'before' side (default: HEAD)")
    p.add_argument("--head", default=None,
                    help="revision for the 'after' side (default: the working tree)")
    p.add_argument("--out", default=None, help="output directory (default: obj/golden-review/)")
    p.add_argument("--areas", default="", help="comma separated DMI areas the change should touch")
    p.add_argument("--intent", default="", help="free text: what the change is meant to do")
    p.add_argument("--check-tool", action="store_true", help="run the fast self test and exit")
    args = p.parse_args(argv)
    args.areas_list = [a.strip() for a in args.areas.split(",") if a.strip()]
    return args


def main(argv):
    args = parse_args(argv)
    if args.check_tool:
        return check_tool()

    out_dir = Path(args.out).resolve() if args.out else DEFAULT_OUT.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    env = build_env()

    t0 = time.time()
    try:
        base = get_revision_side(args.base, env)
        if args.head is None:
            head = get_worktree_side(env, out_dir)
        else:
            head = get_revision_side(args.head, env)
    except ToolError as e:
        print("golden_review: %s" % e, file=sys.stderr)
        return 1

    result = compare_sides(base, head, args.areas_list, out_dir)
    summary = write_report(out_dir, result, args, base, head)
    print("golden_review: report in %s (%.1fs)" % (out_dir / "REPORT.md", time.time() - t0),
          file=sys.stderr)
    print(summary)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
