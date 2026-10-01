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
`UPDATE=1` re-records the goldens. A changed *display* golden is
reviewed in two steps (a small model is enough for either): first a
reviewer who is shown the pictures alone (BLIND.md) and does not know
the intent describes, literally, every visible difference; then a
reviewer who knows the intent (REPORT.md) judges that description
against it. Splitting the two matters: a reviewer told the intent tends
to see only the change it names and approve a picture where text also
silently re-wrapped elsewhere; a reviewer who must describe everything
it sees, with no idea what the change was meant to do, does not get to
skip that. A changed *on-board* golden has no such description: pairing
and counting records is not a describing job, so the tool computes a
deterministic change summary itself (evc_summarize) and REPORT.md's
reviewer judges that directly.

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
records, see test/tools/evc_dump.py) are grouped by their exact change
summary (summary_signature): within a cycle-group pair, the removed and
added records of the same kind are paired in order (a kind is sent at
most once per cycle) and their fields compared by value (evc_decode,
named fields from the sources of truth: common/dmi_protocol.ads,
evc/evc_dmi_port.ads, evc/evc_modes.ads, evc/evc_ports.ads,
evc/evc_core.adb, evc/evc_position.ads -- a kind or length none of them
know falls back to unnamed "byte <n>" fields, still paired the same
way); every differing field is a "replaced" count, a kind's surplus
(unpaired) records are "removed"/"added", both aggregated over the
whole diff by record kind and field (render_onboard_summary). Two
groups whose summaries are equal after dropping counts, cycle ranges and
a varying field's actual values have the same "shape" (compute_shape):
REPORT.md says so (`shape as oN`) and keeps such groups adjacent,
without merging them -- counting and pairing happen once, in the tool,
not in a reviewer's head (the original motivation: a small model asked
to count and pair records by eye got it wrong on exactly the groups
where it mattered).

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
to go on but the pictures themselves.

Output
------
<out>/REPORT.md (the judging sheet: sides, intent, declared areas, the
one-line-per-group table, marking, a shape note and change summary per
on-board group, and a Verdict: line per group) and <out>/BLIND.md (the
describing sheet: *display* groups only, with no intent, declared
areas, marking or golden names, each picture's layout stated in words,
and a Description: line per group to fill in first -- on-board groups
are not there; their summary needs no blind description) in --out
(default obj/golden-review/, git-ignored); <out>/review.json carries
REPORT.md's content structured (the on-board change summary included),
plus BLIND.md's file name. Exit status
is 0 whenever the tool ran to completion -- a changed golden is not an
error, a build or dump failure is. The last stdout line is a one-line
summary:

  golden_review: N display groups (M frames), K on-board groups
  (L goldens), X outside declared areas

Self test: --check-tool synthesises small frame dumps and a small area
table (no build) and checks pixel attribution, grouping, bounding
boxes, the picture scaling/layout rule, that a synthetic BLIND.md
carries none of a run's intent, declared areas or OUTSIDE marking, the
on-board field decoder on literal frames, and the on-board pairing,
aggregation and shape rules on a synthetic record stream; test/check.sh
runs it.
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
# On-board (EVC_Outbox) record parsing -- a vendored copy of
# test/tools/evc_dump.py's structural logic (kept separate on purpose: a
# base revision under review may not carry evc_dump.py, or an older
# version of it without the options this tool needs). Keep this in sync
# with evc_dump.py by hand if the record wire format changes.
# ---------------------------------------------------------------------

EVC_PORTS = ['BTM', 'RTM', 'ODO', 'TIU', 'DMI', 'ATO', 'JRU']
EVC_DMI_TYPES = {0x01: 'SPEED_STATE', 0x02: 'MODE_LEVEL', 0x05: 'TRACK_COND',
                 0x06: 'PLANNING', 0x07: 'STATUS', 0x0A: 'ONBOARD',
                 0x0C: 'SYSTEM_STATUS'}


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


def evc_cycles(recs):
    """Split a flat record list into cycle groups, the way EVC_Core
    produces them: MSG_MODE_LEVEL first in every cycle (evc_dmi_port.ads,
    "Outputs ... every cycle")."""
    out = [[]]
    for r in recs:
        if evc_kind(r) == 'DMI:MODE_LEVEL' and out[-1]:
            out.append([])
        out[-1].append(r)
    return out


# ---------------------------------------------------------------------
# Named fields instead of hex -- the tool's own decoder (an old revision
# under review cannot be asked for one), from the sources of truth:
#   common/dmi_protocol.ads    the wire layout and field names of every
#                              DMI message EVC_Core sends; the names
#                              below (mode, level, som, geo, ...) are
#                              its own comments' names.
#   evc/evc_dmi_port.ads/.adb  how the on-board fills them: Mode_Code and
#                              Level_Code, the wire byte of a mode/level
#                              in MSG_MODE_LEVEL (WIRE_MODE_NAMES,
#                              WIRE_LEVEL_NAMES below); Mode_Level_Frame,
#                              Onboard_Frame, Status_Frame,
#                              Speed_State_Frame.
#   evc/evc_modes.ads          Mode_T, Level_T, Level_Status_T: the
#                              enumeration literal behind a mode/level
#                              value -- Mode_T'Pos in a JRU_Mode_Change
#                              event (MODE_POS_NAMES, LEVEL_POS_NAMES
#                              below, a different numbering from the
#                              wire byte above), the wire byte elsewhere.
#   evc/evc_ports.ads          the JRU event numbers and their three
#                              parameters (JRU_EVENT_TABLE below); the
#                              TIU command/reason bits (TIU_COMMAND_BITS,
#                              TIU_REASON_BITS).
#   evc/evc_core.adb           the exact parameters of JRU_Mode_Change,
#                              JRU_Telegram, JRU_Message, JRU_Configuration
#                              (the JRU_Record call sites).
#   evc/evc_position.ads       Event_Kind_T, the position JRU events
#                              4..10 and their one meaningful parameter.
#
# A frame whose length or type this table does not know, or a byte this
# table's fields do not cover, is not lost: it becomes an unnamed
# "byte <n>" field (_decode_table below), still paired and aggregated
# the same way as a named one, just without a name or a decoded value.
# ---------------------------------------------------------------------

def _fmt_plain(v):
    return str(v)


def _fmt_bool(v):
    return "yes" if v else "no"


def _fmt_named(names, none=None):
    def f(v):
        if none is not None and v == none:
            return "none"
        n = names.get(v)
        return "%d (%s)" % (v, n) if n else str(v)
    return f


def _fmt_sentinel(none_value, text="none"):
    def f(v):
        return text if v == none_value else str(v)
    return f


def _fmt_bits(bit_names):
    def f(v):
        on = [name for mask, name in bit_names if v & mask]
        return "+".join(on) if on else "none"
    return f


# evc/evc_modes.ads Mode_T literal order (a JRU_Mode_Change event's mode
# byte, evc_core.adb: "Mode_T'Pos (Current_Mode)")
MODE_POS_NAMES = dict(enumerate(
    ["FS", "AD", "LS", "OS", "SR", "SM", "SH", "UN", "PS", "SL",
     "SB", "TR", "PT", "SF", "IS", "NP", "NL", "SN", "RV"]))

# evc/evc_dmi_port.ads Mode_Code: the wire byte of MSG_MODE_LEVEL's mode
WIRE_MODE_NAMES = {0: "NP", 1: "SB", 2: "FS", 3: "AD", 4: "SM", 5: "LS",
                   6: "OS", 7: "SR", 8: "SH", 9: "UN", 10: "RV", 11: "TR",
                   12: "SN", 13: "PT", 14: "NL", 15: "SF", 16: "SL",
                   17: "IS", 255: "PS"}

# evc/evc_modes.ads Level_T literal order (a JRU_Mode_Change event's level
# byte, "Level_T'Pos (Current_Level)")
LEVEL_POS_NAMES = {0: "L0", 1: "NTC", 2: "L1", 3: "L2"}
# evc/evc_modes.ads Level_Status_T literal order
LEVEL_STATUS_NAMES = {0: "unknown", 1: "invalid", 2: "valid"}

# evc/evc_dmi_port.ads Level_Code: the wire byte of MSG_MODE_LEVEL's level
WIRE_LEVEL_NAMES = {0: "unknown", 1: "invalid", 2: "L0", 3: "NTC",
                    4: "L1", 5: "L2"}

DIAL_RANGE_NAMES = {0: "140", 1: "180", 2: "250", 3: "400"}
MONITORING_NAMES = {0: "CSM", 1: "TSM", 2: "RSM"}
SPEED_STATUS_NAMES = {0: "NoS", 1: "IndS", 2: "OvS", 3: "WaS", 4: "IntS"}
BRAKE_NAMES = {0: "none", 1: "shown", 2: "ack_required", 3: "pending_ack"}
RADIO_STATUS_NAMES = {0: "none", 1: "up", 2: "lost"}
SM_DIRECTION_NAMES = {0: "none", 1: "fwd", 2: "bwd"}
TUNNEL_NAMES = {0: "unknown", 1: "active", 2: "announced"}
SESSION_NAMES = {0: "none", 1: "establishing", 2: "exists", 3: "exists>2.2"}
SOM_NAMES = {0: "none", 1: "S0", 2: "possible"}
WAITING_NAMES = {0: "none", 1: "radio_net", 2: "rbc", 3: "ma_or_sr",
                 4: "shunting", 5: "sm"}
RADIO_WAIT_NAMES = {0: "none", 1: "list", 2: "registration"}
ODOMETER_ACCURACY_NAMES = {0: "nominal", 1: "impaired", 2: "safety_threshold"}

# common/dmi_protocol.ads MSG_SYSTEM_STATUS (chapter 15 catalogue, Tables
# 68/70): the SS_* constants, number -> a short name of each
SS_NAMES = {
    1: "balise_read_error_brake", 2: "balise_read_error_trip",
    3: "trackside_malfunction", 4: "communication_error_brake",
    5: "communication_error_trip", 6: "entering_fs", 7: "entering_os",
    8: "entering_sm", 9: "runaway_movement", 10: "sm_refused",
    11: "sm_request_failed", 12: "sh_refused", 13: "sh_refused_trip",
    14: "sh_request_failed", 15: "trackside_not_compatible",
    16: "trackside_not_compatible_trip", 17: "train_data_changed",
    18: "train_data_changed_brake", 19: "safe_consist_length",
    20: "train_rejected", 21: "unauthorized_passing",
    22: "no_ma_level_transition", 23: "sr_distance_exceeded",
    24: "sh_stop_order", 25: "sr_stop_order", 26: "emergency_stop",
    27: "rv_distance_exceeded", 28: "pt_distance_exceeded",
    29: "no_track_description", 30: "route_unsuitable_gauge",
    31: "route_unsuitable_traction", 32: "route_unsuitable_axle_load",
    33: "frmcs_registration_failed", 34: "gsmr_registration_failed",
    35: "nl_no_longer_permitted", 36: "odometer_impaired",
    37: "ato_needs_data", 38: "ato_runaway_movement",
}
SS_EVENT_NAMES = {0: "start", 1: "end", 2: "timer_30s"}
POSITION_STATUS_NAMES = {0: "unknown", 1: "valid", 2: "invalid"}

# evc/evc_ports.ads TIU_Output: commands bit0 EBC, bit1 SBC, bit2 TCO;
# reasons bit0 the speed/distance monitoring .. bit4 standstill supervision
TIU_COMMAND_BITS = [(1, "EBC"), (2, "SBC"), (4, "TCO")]
TIU_REASON_BITS = [(1, "sdm"), (2, "service_brake_failed"),
                    (4, "roll_away"), (8, "unauthorised_direction"),
                    (16, "standstill")]


def _decode_table(payload, min_len, fields):
    """payload: bytes (a DMI message's own payload, after its 5 byte
    type+length header, or a JRU record's 3 parameter bytes). fields:
    [(name, offset, width, formatter)], offset/width in bytes, formatter
    a function of the little-endian integer at that offset. Returns an
    ordered [(name, raw_int, display_str)] covering every byte of
    payload left to right -- a byte no field claims is its own unnamed
    "byte <n>" field -- or None when payload is shorter than min_len (a
    frame too short to be this kind at all)."""
    if len(payload) < min_len:
        return None
    by_offset = sorted(fields, key=lambda f: f[1])
    out = []
    i, fi, n = 0, 0, len(payload)
    while i < n:
        if fi < len(by_offset) and by_offset[fi][1] == i \
           and by_offset[fi][1] + by_offset[fi][2] <= n:
            name, off, width, fmt = by_offset[fi]
            raw = 0
            for k in range(width):
                raw |= payload[off + k] << (8 * k)
            out.append((name, raw, fmt(raw)))
            i += width
            fi += 1
            continue
        out.append(("byte %d" % i, payload[i], str(payload[i])))
        i += 1
    return out


# DMI message field tables: kind -> (min_len, [(name, offset, width, fmt)]),
# offset/width within the message's own payload (after type+length).
DMI_FIELD_TABLES = {
    'DMI:MODE_LEVEL': (9, [
        ("mode", 0, 1, _fmt_named(WIRE_MODE_NAMES)),
        ("level", 1, 1, _fmt_named(WIRE_LEVEL_NAMES)),
        ("mode_ack", 2, 1, _fmt_named(WIRE_MODE_NAMES, none=0xFF)),
        ("level_ann", 3, 1, _fmt_named(WIRE_LEVEL_NAMES, none=0xFF)),
        ("level_ann_ack", 4, 1, _fmt_bool),
        ("override", 5, 1, _fmt_bool),
        ("taf", 6, 1, _fmt_bool),
        ("lssma", 7, 2, _fmt_sentinel(0xFFFF)),
    ]),
    'DMI:ONBOARD': (11, [
        ("data", 0, 1, _fmt_plain),
        ("session", 1, 1, _fmt_named(SESSION_NAMES)),
        ("rbc", 2, 1, _fmt_plain),
        ("train", 3, 1, _fmt_plain),
        ("national", 4, 1, _fmt_plain),
        ("som", 5, 1, _fmt_named(SOM_NAMES)),
        ("waiting", 6, 1, _fmt_named(WAITING_NAMES)),
        ("start_pending", 7, 1, _fmt_plain),
        ("radio", 8, 1, _fmt_plain),
        ("radio_wait", 9, 1, _fmt_named(RADIO_WAIT_NAMES)),
        ("answer", 10, 1, _fmt_plain),
    ]),
    'DMI:STATUS': (23, [
        ("brake", 0, 1, _fmt_named(BRAKE_NAMES)),
        ("radio", 1, 1, _fmt_named(RADIO_STATUS_NAMES)),
        ("adhesion", 2, 1, _fmt_bool),
        ("bmm", 3, 1, _fmt_bool),
        ("reversing", 4, 1, _fmt_bool),
        ("sm_direction", 5, 1, _fmt_named(SM_DIRECTION_NAMES)),
        ("set_speed", 6, 2, _fmt_sentinel(0xFFFF)),
        ("tti", 8, 2, _fmt_sentinel(0xFFFF)),
        ("t_disp_tti", 10, 1, _fmt_plain),
        ("tunnel", 11, 1, _fmt_named(TUNNEL_NAMES)),
        ("tunnel_dist", 12, 4, _fmt_plain),
        ("geo", 16, 4, _fmt_sentinel(0xFFFFFFFF, "unknown")),
        ("hour", 20, 1, _fmt_plain),
        ("minute", 21, 1, _fmt_plain),
        ("second", 22, 1, _fmt_plain),
    ]),
    'DMI:SYSTEM_STATUS': (2, [
        ("entry", 0, 1, _fmt_named(SS_NAMES)),
        ("event", 1, 1, _fmt_named(SS_EVENT_NAMES)),
    ]),
    'DMI:SPEED_STATE': (21, [
        ("v_cur", 0, 2, _fmt_plain),
        ("v_perm", 2, 2, _fmt_plain),
        ("v_target", 4, 2, _fmt_plain),
        ("v_release", 6, 2, _fmt_plain),
        ("v_sbi", 8, 2, _fmt_plain),
        ("v_wsl", 10, 2, _fmt_plain),
        ("d_target", 12, 4, _fmt_plain),
        ("monitoring", 16, 1, _fmt_named(MONITORING_NAMES)),
        ("dial_range", 17, 1, _fmt_named(DIAL_RANGE_NAMES)),
        ("flags", 18, 1, _fmt_plain),
        ("status", 19, 1, _fmt_named(SPEED_STATUS_NAMES)),
        ("mrdt", 20, 1, _fmt_plain),
    ]),
}

# JRU event -> (name, [(param_name, offset, width, fmt)]), offset/width
# within the 3 parameter bytes (B2, B3, B4) of JRU_Record (evc_core.adb);
# the cycle count/clock that follow are structural, not content, and are
# shown separately (evc_describe), not as fields.
JRU_EVENT_TABLE = {
    1: ("mode_change", [
        ("mode", 0, 1, _fmt_named(MODE_POS_NAMES)),
        ("level_status", 1, 1, _fmt_named(LEVEL_STATUS_NAMES)),
        ("level", 2, 1, _fmt_named(LEVEL_POS_NAMES)),
    ]),
    2: ("telegram", [("group_id", 0, 3, _fmt_plain)]),
    3: ("message", [("nid", 0, 1, _fmt_plain), ("length", 1, 2, _fmt_plain)]),
    4: ("linking_reaction", [("q_linkreaction", 0, 1, _fmt_plain),
                              ("cause", 1, 1, _fmt_plain),
                              ("link_index", 2, 1, _fmt_plain)]),
    5: ("unexpected_group", [("identity", 0, 1, _fmt_plain)]),
    6: ("missed_group", [("identity", 0, 1, _fmt_plain)]),
    7: ("odometer_accuracy", [("value", 0, 1, _fmt_named(ODOMETER_ACCURACY_NAMES))]),
    8: ("position_status", [("status", 0, 1, _fmt_named(POSITION_STATUS_NAMES))]),
    9: ("cold_movement", [("detected", 0, 1, _fmt_plain)]),
    10: ("new_lrbg", [("identity", 0, 1, _fmt_plain)]),
    20: ("brake_commands", [("commands", 0, 1, _fmt_bits(TIU_COMMAND_BITS)),
                             ("reasons", 1, 1, _fmt_bits(TIU_REASON_BITS)),
                             ("status", 2, 1, _fmt_named(SPEED_STATUS_NAMES))]),
    21: ("supervision", [("monitoring", 0, 1, _fmt_named(MONITORING_NAMES)),
                          ("status", 1, 1, _fmt_named(SPEED_STATUS_NAMES)),
                          ("mrdt", 2, 1, _fmt_plain)]),
    22: ("overrun", [("which", 0, 1, _fmt_plain)]),
    32: ("stored_information", [("info", 0, 1, _fmt_plain),
                                 ("change", 1, 1, _fmt_plain),
                                 ("value", 2, 1, _fmt_plain)]),
    33: ("configuration", [("outcome", 0, 1, _fmt_plain),
                            ("status", 1, 1, _fmt_plain),
                            ("rejections", 2, 1, _fmt_plain)]),
    # evc/evc_ports.ads, phase E4 (e4/modes): 40 the levels (EVC_Levels:
    # a level switched, an order stored or deleted, a level transition
    # acknowledgement asked or given, the service brake of 5.10.4.2), 41
    # the mission (EVC_Mission: driver ID, running number, Train Data,
    # SR data, 'Start', a mode proposed/acknowledged, a mission
    # started/ended, 5.4.6/5.5). Both share one generic (Kind, B3, B4)
    # shape (evc_core.adb Produce_Outputs) whose Kind dispatches to a
    # further per-event meaning this table does not unpack -- kind/b3/b4
    # stay plain numbers rather than "byte <n>": the event itself is
    # still named.
    40: ("levels", [("kind", 0, 1, _fmt_plain), ("b3", 1, 1, _fmt_plain),
                     ("b4", 2, 1, _fmt_plain)]),
    41: ("mission", [("kind", 0, 1, _fmt_plain), ("b3", 1, 1, _fmt_plain),
                      ("b4", 2, 1, _fmt_plain)]),
}


def evc_kind(rec):
    port, p = rec
    if port == 'DMI' and p:
        return 'DMI:' + EVC_DMI_TYPES.get(p[0], '%02X' % p[0])
    if port == 'JRU' and p:
        spec = JRU_EVENT_TABLE.get(p[0])
        return 'JRU:' + (spec[0] if spec else str(p[0]))
    return port


def evc_decode(rec):
    """rec: (port, payload) as evc_records() returns. Returns (kind,
    fields): fields is _decode_table()'s output for a kind/length this
    tool knows, or a single opaque ("bytes", hex, hex) field otherwise --
    still a well-formed field list, so an unrecognised record pairs and
    aggregates exactly like a named one, just without names."""
    port, p = rec
    k = evc_kind(rec)
    if port == 'DMI' and len(p) >= 5:
        spec = DMI_FIELD_TABLES.get(k)
        if spec:
            decoded = _decode_table(p[5:], spec[0], spec[1])
            if decoded is not None:
                return k, decoded
        return k, [("bytes", p[5:].hex(), p[5:].hex())]
    if port == 'JRU' and len(p) >= 4:
        spec = JRU_EVENT_TABLE.get(p[0])
        if spec:
            decoded = _decode_table(p[1:4], 3, spec[1])
            if decoded is not None:
                return k, decoded
        return k, [("bytes", p[1:4].hex(), p[1:4].hex())]
    if port == 'TIU' and len(p) == 2:
        decoded = _decode_table(
            p, 2, [("commands", 0, 1, _fmt_bits(TIU_COMMAND_BITS)),
                   ("reasons", 1, 1, _fmt_bits(TIU_REASON_BITS))])
        if decoded is not None:
            return k, decoded
    return k, [("bytes", p.hex(), p.hex())]


def evc_describe(rec):
    """One literal line for a record: its kind, its decoded fields
    (name=value), and -- a JRU record only -- the cycle its JRU_Record
    header carries, so the raw diff excerpt stays readable without
    needing the field tables."""
    port, p = rec
    kind, fields = evc_decode(rec)
    text = " ".join("%s=%s" % (name, disp) for name, _raw, disp in fields)
    if port == 'JRU' and len(p) >= 8:
        cyc = p[4] + 256 * (p[5] + 256 * (p[6] + 256 * p[7]))
        return "%s %s (cycle %d)" % (kind, text, cyc)
    return "%s %s" % (kind, text)


# ---------------------------------------------------------------------
# Pairing and aggregation: within a cycle-group pair, the removed and
# added records of the same kind are paired in order (evc_dmi_port.ads:
# a kind is sent once per cycle, so the Nth removed record of a kind
# corresponds to the Nth added one); a paired record's fields are
# compared by value, and every differing field becomes a "replaced"
# count. A kind's surplus (more removed than added, or the reverse) are
# true removals/additions, aggregated by their literal content. Counting
# and pairing happen once, here, in the tool -- not in a reviewer's head.
# ---------------------------------------------------------------------

def format_cycle_range(indices):
    """A sorted set of cycle-group indices as compact runs: {2,3,4,9} ->
    "2..4, 9"."""
    idx = sorted(indices)
    if not idx:
        return ""
    runs = []
    start = prev = idx[0]
    for i in idx[1:]:
        if i == prev + 1:
            prev = i
            continue
        runs.append((start, prev))
        start = prev = i
    runs.append((start, prev))
    return ", ".join(("%d" % a) if a == b else ("%d..%d" % (a, b)) for a, b in runs)


def evc_summarize(old_bytes, new_bytes):
    """The change summary of one on-board golden (AGENTS.md
    "Regression"): pair the removed/added records of each cycle-group
    pair by kind, in order; decode both sides' fields (evc_decode);
    every field that differs becomes a "replaced" count for that field,
    aggregated over the whole diff; a kind's surplus (un-paired) records
    aggregate as "removed"/"added" by their literal content. Returns
    (summary, lines, diff_groups, total_groups): summary is
    {kind: {"replaced": {"total", "cycle_range", "fields": {field:
    {"pairs": [[old, new, count], ...] most frequent first, "total"}}},
    "removed"/"added": {"total", "items": [[content, count,
    cycle_range], ...] most frequent first}}} (JSON-serializable);
    lines is the full cycle-group diff text (evc_dump.py --diff's
    format, unabridged -- the caller excerpts it)."""
    co = evc_cycles(evc_records(old_bytes))
    cn = evc_cycles(evc_records(new_bytes))
    lines = []
    diff_groups = 0
    replaced = {}          # kind -> {field: {(old, new): count}}
    replaced_cycles = {}   # kind -> set(int)
    replaced_pairs = {}    # kind -> int (paired records with >=1 field differing)
    unpaired = {}          # (kind, status) -> {content: {"count", "cycles"}}

    for n in range(max(len(co), len(cn))):
        ca = co[n] if n < len(co) else []
        cb = cn[n] if n < len(cn) else []
        da = [evc_describe(r) for r in ca]
        db = [evc_describe(r) for r in cb]
        if da == db:
            continue
        diff_groups += 1
        lines.append("cycle group %d:" % n)
        removed = [r for r, d in zip(ca, da) if d not in db]
        added = [r for r, d in zip(cb, db) if d not in da]
        for r in removed:
            lines.append("  - " + evc_describe(r))
        for r in added:
            lines.append("  + " + evc_describe(r))

        removed_by_kind, added_by_kind = {}, {}
        for r in removed:
            removed_by_kind.setdefault(evc_kind(r), []).append(r)
        for r in added:
            added_by_kind.setdefault(evc_kind(r), []).append(r)

        for k in sorted(set(removed_by_kind) | set(added_by_kind)):
            rl, al = removed_by_kind.get(k, []), added_by_kind.get(k, [])
            paired = min(len(rl), len(al))
            for i in range(paired):
                _, ofields = evc_decode(rl[i])
                _, nfields = evc_decode(al[i])
                nmap = {name: (raw, disp) for name, raw, disp in nfields}
                any_diff = False
                for name, oraw, odisp in ofields:
                    if name not in nmap:
                        continue
                    nraw, ndisp = nmap[name]
                    if oraw != nraw:
                        any_diff = True
                        d = replaced.setdefault(k, {}).setdefault(name, {})
                        key = (odisp, ndisp)
                        d[key] = d.get(key, 0) + 1
                if any_diff:
                    replaced_pairs[k] = replaced_pairs.get(k, 0) + 1
                    replaced_cycles.setdefault(k, set()).add(n)
            for r in rl[paired:]:
                _, f = evc_decode(r)
                content = " ".join("%s=%s" % (nm, disp) for nm, _rw, disp in f)
                e = unpaired.setdefault((k, "removed"), {}).setdefault(
                    content, {"count": 0, "cycles": set()})
                e["count"] += 1
                e["cycles"].add(n)
            for r in al[paired:]:
                _, f = evc_decode(r)
                content = " ".join("%s=%s" % (nm, disp) for nm, _rw, disp in f)
                e = unpaired.setdefault((k, "added"), {}).setdefault(
                    content, {"count": 0, "cycles": set()})
                e["count"] += 1
                e["cycles"].add(n)

    all_kinds = set(replaced) | set(k for k, _ in unpaired)
    summary = {}
    for k in sorted(all_kinds):
        entry = {}
        if k in replaced:
            fields_out = {}
            for field, counts in replaced[k].items():
                pairs_sorted = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
                fields_out[field] = {
                    "pairs": [[o, n, c] for (o, n), c in pairs_sorted],
                    "total": sum(counts.values()),
                }
            entry["replaced"] = {
                "total": replaced_pairs[k],
                "cycle_range": format_cycle_range(replaced_cycles[k]),
                "fields": fields_out,
            }
        for status in ("removed", "added"):
            if (k, status) in unpaired:
                items = unpaired[(k, status)]
                sorted_items = sorted(items.items(),
                                       key=lambda kv: (-kv[1]["count"], kv[0]))
                entry[status] = {
                    "total": sum(v["count"] for v in items.values()),
                    "items": [[content, v["count"], format_cycle_range(v["cycles"])]
                              for content, v in sorted_items],
                }
        summary[k] = entry
    return summary, lines, diff_groups, max(len(co), len(cn))


def format_field(field, fdict):
    """"<field>: <pairs>" -- most frequent old -> new pair first, at
    most 6, then "... K more distinct pairs"; a field with as many
    distinct pairs as total occurrences (a new value every cycle, e.g.
    geo) collapses to one line instead ("27 distinct pairs, e.g. ...")."""
    pairs, total = fdict["pairs"], fdict["total"]
    distinct = len(pairs)
    if distinct > 1 and distinct == total:
        o0, n0, _ = pairs[0]
        return "%s: %d distinct pairs, e.g. %s -> %s" % (field, distinct, o0, n0)
    shown = pairs[:6]
    text = "; ".join("%s -> %s x%d" % (o, n, c) for o, n, c in shown)
    rest = distinct - len(shown)
    if rest > 0:
        text += "; ... %d more distinct pairs" % rest
    return "%s: %s" % (field, text)


def render_onboard_summary(summary):
    """summary (evc_summarize's) as report lines: one block per kind,
    "<kind> replaced N (cycles ...)" then one line per field
    (format_field), or "<kind> removed/added N" then up to 6 items
    (content x count, cycles ...), "... K more" beyond that."""
    lines = []
    for k in sorted(summary):
        entry = summary[k]
        if "replaced" in entry:
            r = entry["replaced"]
            lines.append("- **%s** replaced %d (cycles %s)"
                          % (k, r["total"], r["cycle_range"] or "-"))
            for field in sorted(r["fields"]):
                lines.append("  - " + format_field(field, r["fields"][field]))
        for status in ("removed", "added"):
            if status in entry:
                s = entry[status]
                lines.append("- **%s** %s %d" % (k, status, s["total"]))
                shown = s["items"][:6]
                for content, count, cyc in shown:
                    lines.append("  - %s x%d (cycles %s)" % (content, count, cyc))
                rest = len(s["items"]) - len(shown)
                if rest > 0:
                    lines.append("  - ... %d more" % rest)
    return lines


def summary_signature(summary):
    """A fully hashable, exact (counts and cycle ranges included) form
    of a summary, for grouping goldens whose on-board behaviour changed
    identically -- see compute_shape for the coarser "same shape"
    relation."""
    sig = []
    for k in sorted(summary):
        entry = summary[k]
        parts = []
        if "replaced" in entry:
            r = entry["replaced"]
            fields = tuple(sorted(
                (f, tuple((o, n, c) for o, n, c in v["pairs"]))
                for f, v in r["fields"].items()))
            parts.append(("replaced", r["total"], r["cycle_range"], fields))
        for status in ("removed", "added"):
            if status in entry:
                s = entry[status]
                items = tuple((c, cnt, cyc) for c, cnt, cyc in s["items"])
                parts.append((status, s["total"], items))
        sig.append((k, tuple(parts)))
    return tuple(sig)


def compute_shape(summary):
    """Two groups "have the same shape" when their summaries are equal
    after dropping counts, cycle ranges, and the values of a field that
    varies per cycle (more than one distinct old -> new pair: its
    specific values are dropped too, just "varies"); a field with
    exactly one distinct pair keeps it (it is not "varying", so it is
    structural). removed/added contribute only whether a kind has any
    (their literal content is, by construction, unpaired data -- not
    structure)."""
    parts = []
    for k in sorted(summary):
        entry = summary[k]
        replaced_part = ()
        if "replaced" in entry:
            fl = []
            for field in sorted(entry["replaced"]["fields"]):
                pairs = entry["replaced"]["fields"][field]["pairs"]
                if len(pairs) == 1:
                    fl.append((field, pairs[0][0], pairs[0][1]))
                else:
                    fl.append((field, "VARIES", None))
            replaced_part = tuple(fl)
        parts.append((k, replaced_part, "removed" in entry, "added" in entry))
    return tuple(parts)


def group_changed_onboard(names_bh):
    """names_bh: {name: (base_bytes, head_bytes)}. Groups by the exact
    change summary (summary_signature): goldens whose on-board output
    changed identically are one group, like group_changed_display groups
    identical pixel diffs."""
    groups = {}
    order = []
    details = {}
    for name in sorted(names_bh):
        b, h = names_bh[name]
        summary, lines, diff_groups, total_groups = evc_summarize(b, h)
        sig = summary_signature(summary)
        key = ("changed", sig)
        if key not in groups:
            groups[key] = {"status": "changed", "signature": sig,
                           "summary": summary, "members": []}
            order.append(key)
        groups[key]["members"].append(name)
        details[name] = (lines, diff_groups, total_groups)
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


ONBOARD_EXCERPT_LINES = 15


def render_group_onboard(gid, g, details, out_dir):
    """Write the full diff text for one on-board group; return (excerpt,
    relpath) -- the excerpt is now a short illustration (the change
    summary, g["summary"], already says what changed and by how much;
    see render_onboard_summary)."""
    gdir = out_dir / "onboard" / gid
    gdir.mkdir(parents=True, exist_ok=True)
    rep = g["members"][0]
    excerpt = []
    full_path = None
    if g["status"] == "changed":
        lines, diff_groups, total_groups = details[rep]
        full_path = gdir / "diff.txt"
        full_path.write_text("\n".join(lines) + "\n")
        excerpt = lines[:ONBOARD_EXCERPT_LINES]
        g["diff_groups"] = diff_groups
        g["total_groups"] = total_groups
    return excerpt, (("onboard/%s/diff.txt" % gid) if full_path else None)


def fmt_sides(base, head):
    return ("- base: `%s` -- %s\n- head: `%s` -- %s\n"
            % (base.commit, base.label, head.commit, head.label))


INSTRUCTIONS = """## Instructions for the judging reviewer

A display group's description comes from a reviewer who has not seen
this file or review.json (BLIND.md, next to this report -- a small
model is enough for that first pass; it looked at the pictures alone,
with no idea what the change was meant to do). An on-board group has no
such description: its change summary below (replaced/removed/added, by
record kind and field) is computed by the tool itself, deterministically,
from the two record streams -- not something to ask a small model to
count or pair up by eye.

For each group, compare its description (display) or change summary
(on-board) and its numbers (changed pixel count, or the replaced/
removed/added counts) with the stated intent, and answer **as intended**
/ **not intended** / **cannot tell**, on the group's `Verdict:` line.
Name every side effect the intent does not mention -- even one that is
acceptable (text that re-wrapped along with an intended character
change; a record kind or field the intent never named, say). A display
group whose description is missing, or does not account for its changed
pixel count (a few characters described against thousands of changed
pixels, say), is `cannot tell` and goes back to BLIND.md's reviewer. Be
especially suspicious of a group marked `OUTSIDE declared areas`. Never
approve a group you did not look at.
"""

BLIND_INSTRUCTIONS = """# Golden review: picture descriptions

Describe every *display* group below from its pictures alone. On-board
groups are not here: their change is described by the tool's own
deterministic change summary in REPORT.md (pairing and counting records
is not a describing job). Do not read REPORT.md or review.json -- nothing
here says what the change was meant to do, and the description must not
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
the difference panel (a few characters, whole lines, everything).

No summary, no guess at the purpose of the change, no judgement of
whether it is correct -- only what is visibly different. Say so plainly
when something is unreadable or cut off at an edge.
"""


def reorder_by_shape(onb):
    """Sort on-board groups so groups of the same shape (compute_shape)
    are adjacent, ordered by each shape's first appearance; groups keep
    their relative order otherwise (a stable sort) and are never merged.
    Returns (ordered_groups, shape_of: id(g) -> shape or None)."""
    shape_of = {}
    for g in onb:
        if g["status"] == "changed":
            shape_of[id(g)] = compute_shape(g["summary"])
    first_seen = {}
    for g in onb:
        shp = shape_of.get(id(g))
        if shp is not None and shp not in first_seen:
            first_seen[shp] = len(first_seen)

    def key(g):
        shp = shape_of.get(id(g))
        return (0, first_seen[shp]) if shp is not None else (1, 0)
    return sorted(onb, key=key), shape_of


def onboard_changed_col(summary):
    """The Groups table's one-line "changed" column for an on-board
    group: "<kind> replaced N, removed M, added K; <kind> ..."."""
    parts = []
    for k in sorted(summary):
        entry = summary[k]
        bits = []
        if "replaced" in entry:
            bits.append("replaced %d" % entry["replaced"]["total"])
        for status in ("removed", "added"):
            if status in entry:
                bits.append("%s %d" % (status, entry[status]["total"]))
        parts.append("%s %s" % (k, ", ".join(bits)))
    return "; ".join(parts) or "(no record kind differs)"


def write_report(out_dir, result, args, base, head):
    disp = result["display_groups"]
    onb, shape_of = reorder_by_shape(result["onboard_groups"])

    group_ids = {}
    gi = 0
    for g in disp:
        gi += 1
        group_ids[id(g)] = "d%d" % gi
    gi = 0
    for g in onb:
        gi += 1
        group_ids[id(g)] = "o%d" % gi

    shape_rep_gid = {}
    for g in onb:
        shp = shape_of.get(id(g))
        if shp is not None and shp not in shape_rep_gid:
            shape_rep_gid[shp] = group_ids[id(g)]

    def shape_note(g):
        shp = shape_of.get(id(g))
        if shp is None or shape_rep_gid[shp] == group_ids[id(g)]:
            return None
        return "shape as %s" % shape_rep_gid[shp]

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
        changed_col = onboard_changed_col(g["summary"]) if g["status"] == "changed" else g["status"]
        note = shape_note(g)
        marking = g["marking"] + (", " + note if note else "")
        lines.append("| %s | on-board | %d | %s | - | %s |"
                      % (gid, len(g["members"]), changed_col, marking))

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
        note = shape_note(g)
        if note:
            lines.append("Shape: " + note + "\n")
        if g["status"] == "changed":
            lines.append("Change summary:\n")
            lines.extend(render_onboard_summary(g["summary"]))
            lines.append("")
            lines.append("%d of %d cycle groups differ.\n" % (g.get("diff_groups", 0), g.get("total_groups", 0)))
            if relpath:
                lines.append("Full diff: [%s](%s)\n" % (relpath, relpath))
            if excerpt:
                lines.append("First %d lines of the diff (the change summary above has the full picture):"
                              % ONBOARD_EXCERPT_LINES)
                lines.append("```")
                lines.extend(excerpt)
                lines.append("```")
        lines.append("")
        lines.append("Verdict: ")
        lines.append("")

    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "REPORT.md").write_text("\n".join(lines) + "\n")
    (out_dir / "BLIND.md").write_text(write_blind(result, group_ids, disp_pics))

    def group_json(g, gid):
        d = {"id": gid, "status": g["status"], "members": g["members"], "marking": g["marking"]}
        if "pixel_count" in g:
            d["pixel_count"] = g["pixel_count"]
        if "buckets" in g and g["buckets"]:
            d["areas"] = sorted(g["buckets"])
        if "summary" in g:
            d["summary"] = g["summary"]
            note = shape_note(g)
            if note:
                d["shape_as"] = shape_rep_gid[shape_of[id(g)]]
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


def write_blind(result, group_ids, disp_pics):
    """BLIND.md's text: instructions, then per *display* group its id,
    kind, member count, pictures (each with its layout in words), and an
    empty Description: line. On-board groups are not here at all -- they
    are described by the tool's own change summary in REPORT.md, not by
    a blind reviewer (see BLIND_INSTRUCTIONS). Nothing here may say what
    the change was meant to do: no intent, no declared areas, no
    inside/OUTSIDE marking, no commit subjects, no member (golden) names
    either (a scenario's own name, e.g. one naming the fix, could give
    the game away)."""
    disp = result["display_groups"]
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

    # On-board: the decoder on literal frames (named fields instead of
    # hex, two different tables for a mode byte depending on context).
    def dmi_frame(msg_type, payload):
        pb = bytes(payload)
        return bytes([msg_type]) + struct.pack("<I", len(pb)) + pb

    def rec(port, payload):
        pb = bytes(payload)
        return bytes([port]) + struct.pack("<H", len(pb)) + pb

    DMI_PORT, TIU_PORT = 4, 3  # EVC_PORTS indices

    mode_level_bytes = dmi_frame(0x02, bytes([10, 4, 0xFF, 0xFF, 0, 1, 0, 0xFF, 0xFF]))
    kind, fields = evc_decode(('DMI', mode_level_bytes))
    fmap = {name: disp for name, _raw, disp in fields}
    check(kind == 'DMI:MODE_LEVEL', "MODE_LEVEL frame kind decoded by type byte")
    check(fmap['mode'] == '10 (RV)', "wire mode byte 10 is RV (evc_dmi_port.ads Mode_Code)")
    check(fmap['level'] == '4 (L1)', "wire level byte 4 is L1 (evc_dmi_port.ads Level_Code)")
    check(fmap['override'] == 'yes', "override field decoded as a bool")

    jru_mode_change = ('JRU', bytes([1, 10, 2, 1]) + bytes(12))
    kind2, fields2 = evc_decode(jru_mode_change)
    fmap2 = {name: disp for name, _raw, disp in fields2}
    check(kind2 == 'JRU:mode_change', "JRU event 1 named mode_change")
    check(fmap2['mode'] == '10 (SB)',
          "JRU_Mode_Change's mode byte 10 is SB (Mode_T'Pos, evc_modes.ads) "
          "-- a different table from the wire byte above (also 10, but RV)")

    _, tiu_fields = evc_decode(('TIU', bytes([3, 0])))
    tfmap = {name: disp for name, _raw, disp in tiu_fields}
    check(tfmap['commands'] == 'EBC+SBC', "TIU commands bits 1+2 decoded as EBC+SBC")
    check(tfmap['reasons'] == 'none', "TIU reasons 0 decoded as none")

    # On-board: pairing and aggregation over a synthetic 3-cycle-group
    # diff -- a field that varies every cycle (geo), an unpaired removal
    # (a TIU record dropped), and a replaced frame of an unknown type
    # (falls back to an opaque "bytes" field, still paired).
    def status_bytes(geo):
        b = bytearray(23)
        b[6:8] = (0xFFFF).to_bytes(2, 'little')    # set_speed: none
        b[8:10] = (0xFFFF).to_bytes(2, 'little')   # tti: none
        b[16:20] = geo.to_bytes(4, 'little')
        return bytes(b)

    def status_rec(geo):
        return rec(DMI_PORT, dmi_frame(0x07, status_bytes(geo)))

    mode_level = rec(DMI_PORT, mode_level_bytes)
    tiu_rec = rec(TIU_PORT, bytes([1, 0]))
    unknown_old = rec(DMI_PORT, dmi_frame(0x99, bytes([1, 2])))
    unknown_new = rec(DMI_PORT, dmi_frame(0x99, bytes([3, 4])))

    old_bytes = (mode_level + status_rec(100)
                 + mode_level + status_rec(300) + tiu_rec
                 + mode_level + status_rec(500) + unknown_old)
    new_bytes = (mode_level + status_rec(200)
                 + mode_level + status_rec(400)
                 + mode_level + status_rec(600) + unknown_new)

    summary, lines, diff_groups, total_groups = evc_summarize(old_bytes, new_bytes)
    check(diff_groups == 3 and total_groups == 3, "three on-board cycle groups differ")
    status = summary.get('DMI:STATUS', {})
    check(status.get('replaced', {}).get('total') == 3,
          "DMI:STATUS paired and replaced in all 3 cycle groups")
    geo_field = status.get('replaced', {}).get('fields', {}).get('geo', {})
    check(len(geo_field.get('pairs', ())) == 3 and geo_field.get('total') == 3,
          "the geo field has 3 distinct pairs across 3 cycles (a new value every cycle)")
    check(summary.get('TIU', {}).get('removed', {}).get('total') == 1,
          "the dropped TIU record counted as one unpaired removal")
    unknown = summary.get('DMI:99', {})
    check(unknown.get('replaced', {}).get('total') == 1,
          "an unrecognised DMI frame type still pairs and replaces")
    check('bytes' in unknown.get('replaced', {}).get('fields', {}),
          "an unrecognised frame's content falls back to a 'bytes' field")

    # Shape: dropping counts, cycle ranges and a varying field's values
    # makes two otherwise different-looking summaries the same shape; a
    # non-varying field's actual value is kept, so a genuinely different
    # change is still a different shape.
    def mk_summary(brake_pairs, geo_pairs):
        return {'DMI:STATUS': {'replaced': {
            'total': sum(c for _, _, c in brake_pairs),
            'cycle_range': '0',
            'fields': {
                'brake': {'pairs': brake_pairs,
                          'total': sum(c for _, _, c in brake_pairs)},
                'geo': {'pairs': geo_pairs,
                        'total': sum(c for _, _, c in geo_pairs)},
            },
        }}}

    shape_a = mk_summary([['0 (none)', '1 (shown)', 5]],
                          [['100', '200', 1], ['300', '400', 1]])
    shape_b = mk_summary([['0 (none)', '1 (shown)', 50]],
                          [['999', '111', 1], ['222', '333', 1], ['444', '555', 1]])
    shape_c = mk_summary([['0 (none)', '2 (ack_required)', 5]],
                          [['100', '200', 1], ['300', '400', 1]])
    check(compute_shape(shape_a) == compute_shape(shape_b),
          "same non-varying field value, both have a varying field -> same shape "
          "despite different counts/cycle ranges/varying values")
    check(compute_shape(shape_a) != compute_shape(shape_c),
          "a different non-varying field value is a different shape")

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
