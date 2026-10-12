#!/usr/bin/env python3
"""Our supervision limits against a SUBSET-076 sequence's workbook (B174).

    curve_probe.py <sequence .scn> [set] [options]
    curve_probe.py --breadth <sequence .scn>... [options]

Reads the workbook of the sequence (the cells of `Train (main)`, `Track`,
`Brake parameters (lambda)`, the `track G(...)` gradient line, the
`curves` block number `set`, 1 by default) and the national values of
its packet 3 (the first one of the file, `--nv N` the N-th), runs
obj/evc_curve_probe at the speeds of the curve rows (every 5 km/h and the
initial speed) and prints, per speed and limit (Indication, Permitted,
Warning, SBI, EBI; metres from the max safe front end to the target):
the workbook, ours with the train's brake percentage (F2), ours minus
the workbook, and the B175 margin, ours at F2 minus ours at the tool's
emergency brake percentage (F3): the part of the difference that is the
tool's lambda_o = 100 (A.3.7.1, decided B175).

The workbook's train has the speed accuracy of SUBSET-041 when the
compensation is not inhibited (Q_NVINHSMICPERM 0: the tool's Subset_sci,
V_delta0 = S41_speed_inacc(V_est)); the probe's odometer reports the
same (vura=f41) unless `--vura 0` (the runner's bench: V_max = V_est).

`--breadth` runs every sequence given and prints, per limit, the median
and the extremes of ours minus the workbook over all their rows (with
the margin taken off: `--raw` keeps it), nearer negative; `--lines FILE`
writes the per-sequence lines there. A Gamma sheet is refused with its
reason (the Gamma judging is B100).
"""
import os
import re
import statistics
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROBE = os.path.join(ROOT, "obj", "evc_curve_probe")
LIMITS = ["I", "P", "W", "SBI", "EBI"]
COLUMNS = {"I": "Indication", "P": "Permitted", "W": "Warning", "SBI": "SBI-", "EBI": "EBI"}


class Refused(Exception):
    pass


def read(path):
    cells, grad, sets, packets = {}, None, [], []
    cur_packet = None
    for line in open(path, encoding="utf-8"):
        s = line.strip()
        w = s.split()
        if s.startswith("cell "):
            key, _, val = s[5:].partition(" ")
            m = re.match(r"(.*![A-Z]+[0-9]+)$", key)
            if not m:   # sheet names hold spaces: split at the cell ref
                m2 = re.match(r"(.*?![A-Z]+[0-9]+) (.*)$", s[5:])
                key, val = (m2.group(1), m2.group(2)) if m2 else (key, val)
            cells[key] = val
        elif s.startswith("track G(") and "compensated" not in s:
            grad = [p.split(":") for p in w[2:]]
        elif s.startswith("curves "):
            sets.append({"sheet": s[7:], "limits": {}, "rows": [], "cols": None})
        elif s.startswith("curve-columns") and sets:
            sets[-1]["cols"] = w[1:]
        elif s.startswith("curve ") and sets:
            sets[-1]["rows"].append([None if x == "-" else float(x) for x in w[1:]])
        elif s.startswith("limit ") and sets:
            sets[-1]["limits"][w[1]] = w[2]
        elif s.startswith("var ") and len(w) >= 5:
            name, val = w[1], "".join(w[3:-1]) if w[-1] in ("b", "d") else w[3]
            num = int(val, 2) if w[-1] == "b" else int(val) if val.lstrip("-").isdigit() else 0
            if name == "NID_PACKET":
                cur_packet = [] if num == 3 else None
                if cur_packet is not None:
                    packets.append(cur_packet)
            elif cur_packet is not None:
                cur_packet.append((name, num))
    return cells, grad, sets, packets


def national(fields):
    """The probe's keys from packet 3 (resolutions of 7.5.1)."""
    f = dict(fields)
    args = ["ebcl=%d" % f.get("M_NVEBCL", 9),
            "inhsmic=%d" % f.get("Q_NVINHSMICPERM", 0),
            "gui=%d" % f.get("Q_NVGUIPERM", 0)]
    if not f.get("Q_NVKINT", 0):
        # A.3.2: the default integrated correction factors
        return args + ["kv=0:0.7", "kr=0:0.9", "kt=1.1"]
    sets, kr, kt, last_v, kind = {}, [], 1.0, None, 0
    for name, num in fields:
        if name == "Q_NVKVINTSET":
            kind = num
            sets.setdefault(kind, [])
        elif name == "V_NVKVINT":
            last_v = num * 5
        elif name == "M_NVKVINT" and last_v is not None:
            sets.setdefault(kind, []).append("%d:%.2f" % (last_v, num * 0.02))
            last_v = None
        elif name == "L_NVKRINT":
            kr.append(num * 25)
        elif name == "M_NVKRINT" and kr and isinstance(kr[-1], int):
            kr[-1] = "%d:%.2f" % (kr[-1], num * 0.05)
        elif name == "M_NVKTINT":
            kt = num * 0.05
    if 0 in sets:
        args.append("kv=" + ",".join(sets[0]))
    if 1 in sets:
        args.append("kvp=" + ",".join(sets[1]))
    if kr:
        args.append("kr=" + ",".join(str(x) for x in kr))
    return args + ["kt=%.2f" % kt]


def setup(path, set_no=1, nv=1, vura="f41"):
    cells, grad, sets, packets = read(path)
    if set_no > len(sets):
        raise Refused("no curves block %d" % set_no)
    cs = sets[set_no - 1]
    if "gamma" in cs["sheet"].lower():
        raise Refused("Gamma sheet: the Gamma train is B100, not probed")
    c = lambda k, d=None: cells.get(k, d)
    pos = c("Train (main)!D23", "")
    pos = "pp" if pos.startswith("Passenger") else "fg" if pos.endswith("G") else "fp"
    target_speed = float(c("Track!B2", "0") or 0)
    args = ["lambda=" + c("Brake parameters (lambda)!F2", "100"),
            "length=" + c("Train (main)!D18", "400"),
            "pos=" + pos, "tco=" + c("Train (main)!D4", "0"),
            "target=" + c("Track!B3", "2000"), "ci=0"]
    if target_speed > 0:
        args.append("loa=%d" % target_speed)
    else:
        release = c("Track!E2", "0")
        if float(release or 0) == 0 and re.match(r"[0-9.]+$", cs["limits"].get("Release-speed", "-")):
            release = cs["limits"]["Release-speed"]   # calculated on-board
        args += ["svl=" + c("Track!E1", "0"), "release=" + release]
    if grad:
        args.append("grad=" + ",".join("%s:%s" % (a, b) for a, b in grad if b != "end"))
    if packets:
        args += national(packets[min(nv, len(packets)) - 1])
    inhibit = "inhsmic=1" in args
    args.append("vura=" + ("0" if inhibit else vura))
    initial = int(float(c("Track!B4", "0") or 0))
    args.append("ceiling=%d" % initial)
    cols = cs["cols"] or []
    idx = {}
    for lim in LIMITS:
        for i, col in enumerate(cols):
            if col.startswith(COLUMNS[lim]):
                idx[lim] = i
                break
    rows = {int(r[0]): r for r in cs["rows"] if r and r[0] is not None and r[0] == int(r[0])}
    speeds = sorted(v for v in rows if v > 0 and (v % 5 == 0 or v == initial)
                    and v <= initial and rows[v][idx.get("P", 0)] is not None)
    return args, rows, idx, speeds, c("Brake parameters (lambda)!F3", "100"), cs["sheet"]


def run_probe(args, speeds):
    out = subprocess.run([PROBE] + args + ["speeds=" + ",".join(map(str, speeds))],
                         capture_output=True, text=True, check=True).stdout
    res = {}
    for line in out.splitlines():
        if line.startswith("#"):
            continue
        w = line.split()
        res[int(w[0])] = [int(x) for x in w[1:6]]
    return res


def compare(path, set_no=1, nv=1, vura="f41"):
    args, rows, idx, speeds, lambda_eb, sheet = setup(path, set_no, nv, vura)
    ours = run_probe(args, speeds)
    eb = run_probe([a for a in args if not a.startswith("lambda=")]
                   + ["lambda=" + lambda_eb], speeds)
    table = []
    # a limit at the origin of the workbook is its "everywhere" (V = MRSP)
    origin = float([a for a in args if a.startswith("target=")][0][7:])
    for v in speeds:
        for k, lim in enumerate(LIMITS):
            wb = rows[v][idx[lim]] if lim in idx else None
            o, o_eb = ours[v][k], eb[v][k]
            if wb is None or wb >= origin or o < 0 or o_eb < 0:
                continue
            table.append((v, lim, wb, o, o - wb, o - o_eb))
    return args, sheet, table


def show(path, set_no, nv, vura):
    args, sheet, table = compare(path, set_no, nv, vura)
    print("# %s, %s; probe: %s" % (os.path.basename(path), sheet, " ".join(args)))
    print("# V_kmh limit workbook ours ours-workbook B175-margin rest  (m, max safe front end to the target; nearer negative)")
    for v, lim, wb, o, d, m in table:
        print("%3d %-3s %8.1f %6d %7.1f %6d %7.1f" % (v, lim, wb, o, d, m, d - m))


def breadth(paths, nv, vura, raw, lines_file):
    per = {lim: [] for lim in LIMITS}
    out = open(lines_file, "w") if lines_file else None
    for p in paths:
        name = os.path.basename(p)[:-4]
        try:
            _, _, table = compare(p, 1, nv, vura)
        except Refused as e:
            print("# %s: refused, %s" % (name, e), file=sys.stderr)
            continue
        except (subprocess.CalledProcessError, KeyError, ValueError) as e:
            print("# %s: not probed, %s" % (name, e), file=sys.stderr)
            continue
        for v, lim, wb, o, d, m in table:
            rest = d if raw else d - m
            per[lim].append((rest, name, v))
            if out:
                out.write("%s %d %s %.1f %d %.1f %d\n" % (name, v, lim, wb, o, d, m))
    print("| limit | rows | median | nearest | furthest |")
    print("|---|---|---|---|---|")
    for lim in LIMITS:
        xs = sorted(per[lim])
        if not xs:
            continue
        med = statistics.median(x[0] for x in xs)
        lo, hi = xs[0], xs[-1]
        print("| %s | %d | %.1f | %.1f (%s, %d) | %.1f (%s, %d) |"
              % (lim, len(xs), med, lo[0], lo[1], lo[2], hi[0], hi[1], hi[2]))


def main():
    argv = sys.argv[1:]
    opts = {"--nv": "1", "--vura": "f41", "--lines": None}
    pos, raw, mode = [], False, "show"
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in opts:
            opts[a] = argv[i + 1]
            i += 2
            continue
        if a == "--raw":
            raw = True
        elif a == "--breadth":
            mode = "breadth"
        else:
            pos.append(a)
        i += 1
    if not pos:
        print(__doc__)
        return 2
    try:
        if mode == "breadth":
            breadth(pos, int(opts["--nv"]), opts["--vura"], raw, opts["--lines"])
        else:
            show(pos[0], int(pos[1]) if len(pos) > 1 else 1, int(opts["--nv"]), opts["--vura"])
    except Refused as e:
        print("curve_probe: refused: %s" % e)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
