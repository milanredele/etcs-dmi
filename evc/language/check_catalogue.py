#!/usr/bin/env python3
"""Check etcs_language.toml against SCHEMA.md and against the SRS markdown.

Usage: python3 evc/language/check_catalogue.py [catalogue.toml]

Standard library only; needs Python 3.11 or newer (tomllib).

1. Schema: every variable, packet and message entry has the keys SCHEMA.md
   defines and nothing else; bits in 1 .. 32 (NID_RADIO: 64); min/max and
   special values fit the width; spare values (single values and "a..b"
   ranges) fit, lie within min .. max, hold no special value and do not
   overlap; bcd variables are unsigned with a whole number of digits;
   every packet starts NID_PACKET [Q_DIR]
   L_PACKET (packet 255 and track-to-train packet 0 excepted, 7.3.3.5); every
   `var` is defined; every `if`, `loop` and `raw` variable was read before
   at this level or an enclosing one; condition values fit the variable;
   no name read twice at one record level (packet or loop body, `if`
   blocks flattened into it) without `as`.
2. Markdown (doc/SRS/SUBSET-026_v400/sections/07_ertms_etcs_language.md and
   08_messages.md): for every packet, the flattened list of variable names
   (loops and conditions flattened, (k)/(n) suffixes dropped, "10 + 14"
   read as NID_C, NID_BG) equals the markdown table, and each length equals
   `bits`; the packet lists 7.4.1.1 and 7.4.1.2; the variable headings of
   7.5 (name, clause, length); the message tables of 8.6 and 8.7 (the
   picture text of the markdown). A difference that is a defect of the
   markdown is listed in KNOWN_MD_DEFECTS with the PDF page that shows the
   correct content; anything else fails.

Exit status 0 only when everything passes.
"""
import os
import re
import sys

if sys.version_info < (3, 11):
    sys.exit("check_catalogue.py needs Python 3.11 or newer (tomllib)")
import tomllib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
SECTIONS = os.path.join(ROOT, "doc", "SRS", "SUBSET-026_v400", "sections")
MD7 = os.path.join(SECTIONS, "07_ertms_etcs_language.md")
MD8 = os.path.join(SECTIONS, "08_messages.md")

# Variables written "10 + 14" in chapter 7: NID_C then NID_BG, no entry.
COMBINED = {"NID_LRBG", "NID_PRVLRBG", "NID_LTRBG"}
# Variables wider than 32 bits (SCHEMA.md, "Variables").
WIDE = {"NID_RADIO": 64}
SENDERS = {"balise", "loop", "rbc", "riu"}
DIRECTIONS = {"track_to_train", "train_to_track"}

# Differences between the catalogue and the markdown that are defects of
# the markdown, each with the PDF page (SUBSET-026-7_v400.pdf unless said
# otherwise) that shows the right content. Key: (kind, identifier).
KNOWN_MD_DEFECTS = {
    ("variable-heading", "A_NVP23"):
        "7.5.0.5 A_NVP23, PDF p. 47: the markdown heading '### 7.5.0.5' lost "
        "the name (it went into the table of A_NVP12)",
    ("variable-length", "D_AXLELOAD"):
        "7.5.1.2 D_AXLELOAD, PDF p. 47: the markdown heading has no table, the "
        "table (15 bits) sits before it, merged into the table of D_ADHESION",
    ("variable-length", "D_PBD"):
        "7.5.1.19.1 D_PBD, PDF p. 50: the markdown heading has no table, the "
        "table (15 bits) sits before it, merged into the table of D_OL",
    ("variable-length", "D_POSOFF"):
        "7.5.1.20 D_POSOFF, PDF p. 50: the markdown heading has no table, the "
        "table (15 bits) sits before it, merged into the table of D_PBDSR",
    ("variable-length", "L_AXLELOAD"):
        "7.5.1.42 L_AXLELOAD, PDF p. 53: the markdown heading has no table, the "
        "table (15 bits) sits before it, merged into the table of L_ADHESION",
    ("variable-length", "Q_NVSBFBPERM"):
        "7.5.1.123.6 Q_NVSBFBPERM, PDF p. 81: the markdown heading has no table, "
        "the table (1 bit) sits before it, merged into the table of Q_NVLOCACC",
    ("packet-heading", "track_to_train:0"):
        "packet 0 (7.4.2.0), PDF p. 12: the markdown start line is plain text, "
        "not a heading",
    ("packet-heading", "track_to_train:66"):
        "packet 66 (7.4.2.18), PDF p. 27: the markdown start line is plain text, "
        "not a heading",
    ("packet-heading", "track_to_train:254"):
        "packet 254 (7.4.2.38), PDF p. 39: the markdown start line is plain "
        "text, not a heading",
    ("packet-heading", "train_to_track:1"):
        "packet 1 (7.4.3.2), PDF p. 40: the markdown start line is plain text, "
        "not a heading",
    ("packet-heading", "train_to_track:44"):
        "packet 44 (7.4.3.6), PDF p. 44: the markdown start line is plain text, "
        "not a heading",
    ("packet", "track_to_train:63"):
        "packet 63 (7.4.2.16), PDF p. 27: the last row NID_BG(k), 14 bits, is "
        "plain text after the page break in the markdown, not a table row",
}

# How to repair the markdown table of a packet before comparing, for the
# packet defects above: (index, row to insert).
MD_PACKET_PATCHES = {
    ("track_to_train", 63): (6, ("NID_BG", 14)),
}


class Report:
    def __init__(self):
        self.errors = []
        self.known = []
        self.info = []

    def err(self, where, msg):
        self.errors.append(f"ERROR {where}: {msg}")

    def note(self, msg):
        self.info.append(msg)


R = Report()

# --------------------------------------------------------------------------
# 1. Schema
# --------------------------------------------------------------------------
VAR_KEYS = {"bits", "clause", "min", "max", "special", "scale", "resolution",
            "spare", "bcd"}
SPARE_RANGE_RE = re.compile(r"^\s*(-?\d+)\s*\.\.\s*(-?\d+)\s*$")


def spare_ranges(v):
    """The spare values of a variable as (a, b) ranges; None items for
    the malformed ones."""
    out = []
    for item in v.get("spare", []) if isinstance(v.get("spare", []), list) else []:
        if isinstance(item, int) and not isinstance(item, bool):
            out.append((item, item))
        elif isinstance(item, str) and SPARE_RANGE_RE.match(item):
            m = SPARE_RANGE_RE.match(item)
            out.append((int(m.group(1)), int(m.group(2))))
        else:
            out.append(None)
    return out


def is_spare(v, x):
    return any(r and r[0] <= x <= r[1] for r in spare_ranges(v))
PACKET_KEYS = {"nid", "name", "clause", "direction", "sent_by", "fields"}
MESSAGE_KEYS = {"nid", "name", "clause", "direction", "sent_by", "fields", "packets"}
NAME_RE = re.compile(r"^[A-Z][A-Z0-9]*(_[A-Z0-9]+)+$")
COND_RE = re.compile(r"^([A-Z][A-Z0-9_]*)\s*(==|!=|<=|>=|<|>)\s*(-?\d+)$")
COND_IN_RE = re.compile(r"^([A-Z][A-Z0-9_]*)\s+in\s+\[\s*(-?\d+(?:\s*,\s*-?\d+)*)\s*\]$")


def var_range(v):
    bits = v["bits"]
    signed = v.get("min", 0) < 0
    lo = -(1 << (bits - 1)) if signed else 0
    hi = (1 << (bits - 1)) - 1 if signed else (1 << bits) - 1
    return lo, hi


def check_variables(variables):
    for name, v in variables.items():
        w = f"variable {name}"
        if not NAME_RE.match(name):
            R.err(w, "name is not an SRS variable name")
        if name in COMBINED:
            R.err(w, "10 + 14 variable must not have an entry (NID_C, NID_BG instead)")
        if not isinstance(v, dict):
            R.err(w, "not a table")
            continue
        for k in v:
            if k not in VAR_KEYS:
                R.err(w, f"unknown key {k!r}")
        bits = v.get("bits")
        if not isinstance(bits, int):
            R.err(w, "bits missing")
            continue
        if name in WIDE:
            if bits != WIDE[name]:
                R.err(w, f"bits {bits}, expected {WIDE[name]}")
        elif not 1 <= bits <= 32:
            R.err(w, f"bits {bits} not in 1 .. 32")
        c = v.get("clause")
        if not isinstance(c, str) or not re.match(r"^7\.5\.[01](\.\d+)+$", c):
            R.err(w, f"clause {c!r} is not a 7.5 clause")
        lo, hi = var_range(v)
        mn, mx = v.get("min", 0), v.get("max", hi)
        for k, x in (("min", mn), ("max", mx)):
            if not isinstance(x, int) or not lo <= x <= hi:
                R.err(w, f"{k} {x!r} outside {lo} .. {hi}")
        if isinstance(mn, int) and isinstance(mx, int) and mn > mx:
            R.err(w, f"min {mn} > max {mx}")
        sp = v.get("special", {})
        if not isinstance(sp, dict):
            R.err(w, "special is not a table")
            sp = {}
        for k, t in sp.items():
            if not re.fullmatch(r"-?\d+", k):
                R.err(w, f"special key {k!r} is not a number")
                continue
            if not lo <= int(k) <= hi:
                R.err(w, f"special value {k} outside {lo} .. {hi}")
            if not isinstance(t, str) or not t:
                R.err(w, f"special value {k} has no text")
        if "spare" in v:
            if not isinstance(v["spare"], list) or not v["spare"]:
                R.err(w, "spare is not a non-empty list")
            seen = []
            for item, r in zip(v["spare"] if isinstance(v["spare"], list) else [],
                               spare_ranges(v)):
                if r is None:
                    R.err(w, f"spare {item!r} is neither a value nor a range \"a..b\"")
                    continue
                a, b = r
                if not lo <= a <= b <= hi:
                    R.err(w, f"spare {item!r} outside {lo} .. {hi} or empty")
                if isinstance(mn, int) and isinstance(mx, int) and (b < mn or a > mx):
                    R.err(w, f"spare {item!r} outside min .. max, spare already")
                for k in sp:
                    if re.fullmatch(r"-?\d+", k) and a <= int(k) <= b:
                        R.err(w, f"spare {item!r} holds the special value {k}")
                for c, d in seen:
                    if a <= d and c <= b:
                        R.err(w, f"spare {item!r} overlaps another")
                seen.append((a, b))
        if "bcd" in v:
            if not isinstance(v["bcd"], bool):
                R.err(w, "bcd is not true or false")
            elif v["bcd"] and (bits % 4 != 0 or lo < 0):
                R.err(w, "bcd needs an unsigned variable of whole 4-bit digits")
        if "scale" in v and v["scale"] != "Q_SCALE":
            R.err(w, f"scale {v['scale']!r}")
        if "resolution" in v and not isinstance(v["resolution"], str):
            R.err(w, "resolution is not text")


def parse_cond(cond, variables, readable, where):
    """Return the variable of a condition; report errors."""
    m = COND_RE.match(cond)
    if m:
        var, vals = m.group(1), [int(m.group(3))]
    else:
        m = COND_IN_RE.match(cond)
        if not m:
            R.err(where, f"condition {cond!r} not in the form of SCHEMA.md")
            return None
        var, vals = m.group(1), [int(x) for x in m.group(2).split(",")]
    if var not in readable:
        R.err(where, f"condition variable {var} not read before at this or an enclosing level")
        return var
    v = variables.get(readable[var])
    if v:
        lo, hi = var_range(v)
        valid = set(range(v.get("min", 0), v.get("max", hi) + 1)) | {int(k) for k in v.get("special", {})}
        for x in vals:
            if not lo <= x <= hi:
                R.err(where, f"condition value {x} outside the width of {var}")
            elif x not in valid:
                R.err(where, f"condition value {x} of {var} is neither in min .. max nor special")
            elif is_spare(v, x):
                R.err(where, f"condition value {x} of {var} is spare")
    return var


def check_fields(fields, variables, where, readable, names, used):
    """readable: name (var or as) -> variable read so far at this or an
    enclosing level; names: component names of this record level."""
    if not isinstance(fields, list) or not fields:
        R.err(where, "fields is not a non-empty list")
        return
    for i, f in enumerate(fields):
        w = f"{where} field {i + 1}"
        if not isinstance(f, dict):
            R.err(w, "not a table")
            continue
        kinds = [k for k in ("var", "if", "loop", "raw") if k in f]
        if len(kinds) != 1:
            R.err(w, f"exactly one of var, if, loop, raw expected, got {kinds}")
            continue
        kind = kinds[0]
        allowed = {"var": {"var", "as"}, "if": {"if", "fields"}, "loop": {"loop", "fields"}, "raw": {"raw"}}[kind]
        for k in f:
            if k not in allowed:
                R.err(w, f"unknown key {k!r} in a {kind} field")
        if kind == "var":
            name = f["var"]
            if name not in variables:
                R.err(w, f"variable {name} not defined")
            used.add(name)
            comp = f.get("as", name)
            if "as" in f and not NAME_RE.match(f["as"]):
                R.err(w, f"as {f['as']!r} is not an identifier")
            if comp in names:
                R.err(w, f"{comp} occurs twice at one record level (give it an `as`)")
            names.add(comp)
            readable[name] = name
            readable[comp] = name
        elif kind == "if":
            parse_cond(f["if"], variables, readable, w)
            # an if block adds components to the enclosing record (names),
            # but what it reads is visible only inside it (readable copy)
            check_fields(f.get("fields"), variables, w + " (if)", dict(readable), names, used)
        elif kind == "loop":
            var = f["loop"]
            if var not in readable:
                R.err(w, f"loop variable {var} not read before")
            check_fields(f.get("fields"), variables, w + " (loop)", dict(readable), set(), used)
        elif kind == "raw":
            if f["raw"] not in readable:
                R.err(w, f"raw length variable {f['raw']} not read before")


def check_packets(packets, variables, used):
    seen = set()
    for p in packets:
        nid, d = p.get("nid"), p.get("direction")
        w = f"packet {d}:{nid}"
        for k in PACKET_KEYS:
            if k not in p:
                R.err(w, f"missing key {k}")
        for k in p:
            if k not in PACKET_KEYS:
                R.err(w, f"unknown key {k!r}")
        if not isinstance(nid, int) or not 0 <= nid <= 255:
            R.err(w, "nid not in 0 .. 255")
        if d not in DIRECTIONS:
            R.err(w, f"direction {d!r}")
        if (d, nid) in seen:
            R.err(w, "defined twice")
        seen.add((d, nid))
        c = p.get("clause", "")
        want = "7.4.2." if d == "track_to_train" else "7.4.3."
        if not isinstance(c, str) or not c.startswith(want):
            R.err(w, f"clause {c!r} is not in {want[:-1]}")
        sb = p.get("sent_by")
        if not isinstance(sb, list) or not sb or not set(sb) <= SENDERS:
            R.err(w, f"sent_by {sb!r}")
        fields = p.get("fields", [])
        heads = [f.get("var") for f in fields[:3] if isinstance(f, dict)]
        if nid == 255:
            if heads != ["NID_PACKET"] or len(fields) != 1:
                R.err(w, "packet 255 is NID_PACKET only")
        elif nid == 0 and d == "track_to_train":
            if heads != ["NID_PACKET", "NID_VBCMK"]:
                R.err(w, "packet 0 (7.3.3.5) is NID_PACKET, NID_VBCMK")
        elif d == "track_to_train":
            if heads != ["NID_PACKET", "Q_DIR", "L_PACKET"]:
                R.err(w, f"header {heads}, expected NID_PACKET Q_DIR L_PACKET")
        elif heads[:2] != ["NID_PACKET", "L_PACKET"]:
            R.err(w, f"header {heads[:2]}, expected NID_PACKET L_PACKET")
        check_fields(fields, variables, w, {}, set(), used)
    return seen


def check_messages(messages, variables, packet_keys, used):
    seen = set()
    for m in messages:
        nid, d = m.get("nid"), m.get("direction")
        w = f"message {nid}"
        for k in MESSAGE_KEYS:
            if k not in m:
                R.err(w, f"missing key {k}")
        for k in m:
            if k not in MESSAGE_KEYS:
                R.err(w, f"unknown key {k!r}")
        if not isinstance(nid, int) or not 0 <= nid <= 255:
            R.err(w, "nid not in 0 .. 255")
        if nid in seen:
            R.err(w, "defined twice")
        seen.add(nid)
        if d not in DIRECTIONS:
            R.err(w, f"direction {d!r}")
        c = m.get("clause", "")
        want = "8.7." if d == "track_to_train" else "8.6."
        if not isinstance(c, str) or not c.startswith(want):
            R.err(w, f"clause {c!r} is not in {want[:-1]}")
        sb = m.get("sent_by")
        if not isinstance(sb, list) or not sb or not set(sb) <= {"rbc", "riu"}:
            R.err(w, f"sent_by {sb!r}")
        fields = m.get("fields", [])
        heads = [f.get("var") for f in fields[:5] if isinstance(f, dict)]
        if d == "track_to_train":
            want_h = ["NID_MESSAGE", "L_MESSAGE", "T_TRAIN", "M_ACK", "NID_C"]
            if nid == 38:  # 8.7.16: the table has no NID_LRBG
                want_h = want_h[:4]
            if heads[:len(want_h)] != want_h:
                R.err(w, f"header {heads}, expected {want_h} (8.4.4.6.1)")
        else:
            want_h = ["NID_MESSAGE", "L_MESSAGE", "T_TRAIN", "NID_ENGINE"]
            if heads[:4] != want_h:
                R.err(w, f"header {heads[:4]}, expected {want_h} (8.4.4.7.1)")
        check_fields(fields, variables, w, {}, set(), used)
        pks = m.get("packets")
        if not isinstance(pks, list):
            R.err(w, "packets is not a list")
            continue
        pd = "track_to_train" if d == "track_to_train" else "train_to_track"
        listed = set()
        opt_seen = False
        for i, e in enumerate(pks):
            we = f"{w} packet entry {i + 1}"
            if not isinstance(e, dict):
                R.err(we, "not a table")
                continue
            for k in e:
                if k not in {"nid", "one_of", "optional", "repeat", "from"}:
                    R.err(we, f"unknown key {k!r}")
            if ("nid" in e) == ("one_of" in e):
                R.err(we, "exactly one of nid, one_of expected")
                continue
            nids = [e["nid"]] if "nid" in e else e["one_of"]
            for n in nids:
                if (pd, n) not in packet_keys:
                    R.err(we, f"packet {pd}:{n} not in the catalogue")
                key = (n, tuple(e.get("from", ())))
                if key in listed:
                    R.err(we, f"packet {n} listed twice")
                listed.add(key)
            if e.get("optional", False):
                opt_seen = True
            elif opt_seen:
                R.err(we, "mandatory packet after an optional one")
            if "from" in e and (not isinstance(e["from"], list) or not set(e["from"]) <= set(sb or [])):
                R.err(we, f"from {e.get('from')!r} not a subset of sent_by")
        if d == "train_to_track":
            has_pos = any(e.get("one_of") == [0, 1] for e in pks if isinstance(e, dict))
            no_pos = nid in (146, 154, 155, 156, 159)  # 8.4.4.7.2
            if has_pos == no_pos:
                R.err(w, "packet 0 or 1 presence contradicts 8.4.4.7.2")


# --------------------------------------------------------------------------
# 2. Markdown cross-checks
# --------------------------------------------------------------------------
def flatten(fields, variables):
    out = []
    for f in fields:
        if "var" in f:
            out.append((f["var"], variables.get(f["var"], {}).get("bits")))
        elif "raw" in f:
            out.append(("RAW", None))
        else:
            out += flatten(f.get("fields", []), variables)
    return out


def md_cells(line):
    s = line.strip()
    if not (s.startswith("|") and s.endswith("|")):
        return None
    return [c.strip() for c in s[1:-1].split("|")]


def md_packets(text):
    """(direction, nid) -> list of (name, length) from the markdown tables."""
    lines = text.split("\n")
    start = re.compile(r"^(?:### )?(7\.4\.([23])\.[\d.]+) Packet [Nn]umber (\d+):")
    res = {}
    cur = None
    for ln in lines:
        m = start.match(ln)
        if m:
            d = "track_to_train" if m.group(2) == "2" else "train_to_track"
            cur = (d, int(m.group(3)))
            res[cur] = []
            if not ln.startswith("### "):
                key = ("packet-heading", f"{d}:{cur[1]}")
                if key in KNOWN_MD_DEFECTS:
                    R.known.append(KNOWN_MD_DEFECTS[key])
                else:
                    R.err(f"packet {d}:{cur[1]}", "markdown start line is not a heading")
            continue
        if ln.startswith("## **7.4.4") or ln.startswith("# **7.5"):
            cur = None
        if cur is None:
            continue
        cells = md_cells(ln)
        if not cells:
            continue
        cells = [c for c in cells if c != ""]
        if not cells:
            continue
        if cells[0].startswith("Other"):
            res[cur].append(("RAW", None))
            continue
        # "NID_PACKET<br>8": name and length merged in one cell (packet 181)
        parts = cells[0].split("<br>")
        if len(parts) == 2 and re.fullmatch(r"\d+", parts[1].strip()):
            cells = [parts[0], parts[1]] + cells[1:]
        first = cells[0].replace("<br>", " ").strip()
        nm = re.match(r"^([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+)\s*(?:\([^)]*\))?$", first)
        if not nm or len(cells) < 2:
            continue
        # "8<br>= 255 (1111 1111)": length and comment merged (packet 255);
        # "_2_": italics (packet 63)
        length = cells[1].split("<br>")[0].strip().strip("_*").strip()
        name = nm.group(1)
        if re.fullmatch(r"10\s*\+\s*14", length):
            res[cur] += [("NID_C", 10), ("NID_BG", 14)]
        elif re.fullmatch(r"\d+", length):
            res[cur].append((name, int(length)))
        else:
            res[cur].append((name, length))
    return res


def md_packet_lists(text):
    """The lists 7.4.1.1 and 7.4.1.2 of the markdown."""
    sec = text.split("### 7.4.1.1 Track to Train", 1)[1].split("### 7.4.1.3", 1)[0]
    res = set()
    d = "track_to_train"
    for ln in sec.split("\n"):
        cells = md_cells(ln)
        if not cells:
            continue
        if cells[0].startswith("7.4.1.2"):
            d = "train_to_track"
            continue
        if re.fullmatch(r"\d+", cells[0]):
            res.add((d, int(cells[0])))
    return res


def md_variables(text):
    """name -> (clause, length or None) from the 7.5 headings."""
    sec = text.split("# **7.5 Definitions of Variables**", 1)[1]
    lines = sec.split("\n")
    head = re.compile(r"^### (7\.5\.[\d.]+?)\s*([A-Z][A-Z0-9_]*)?\s*(?:\(Values to be assigned[^)]*\))?\s*$")
    res = {}
    empty = []
    cur = None
    for ln in lines:
        m = head.match(ln)
        if m:
            if m.group(2):
                cur = m.group(2)
                res[cur] = [m.group(1), None]
            else:
                empty.append(m.group(1))
                cur = None
            continue
        if cur and res[cur][1] is None:
            b = re.search(r"\|\s*(\d+(?:\s*\+\s*\d+)?)\s*bits?\b", ln)
            if b:
                res[cur][1] = b.group(1).replace(" ", "")
    return res, empty


def md_messages(text):
    """nid -> list of items: variable names, ('P', n), ('P', 0, 1), 'OPT'."""
    res = {}
    parts = re.split(r"^## \*\*(8\.[67]\.[\d.]+) Message (\d+): .*$", text, flags=re.M)
    for i in range(1, len(parts), 3):
        nid = int(parts[i + 1])
        body = parts[i + 2]
        m = re.search(r"<!-- Start of picture text -->(.*?)<!-- End of picture text -->", body, re.S)
        if not m:
            continue
        rows = [r.strip() for r in m.group(1).replace("\n", " ").split("<br>")]
        items = []
        for r in rows:
            mm = re.match(r"^(\d+)\s+(.*)$", r)
            if not mm:
                # continuation of a broken variable name (Q_MARQSTREAS / ON)
                if items and isinstance(items[-1], str) and re.fullmatch(r"[A-Z_]+", r.split()[0] if r else ""):
                    items[-1] += r.split()[0]
                continue
            rest = mm.group(2)
            pk = re.search(r"[Pp]acket (?:type )?(\d+)(?: or (\d+))?", rest)
            if rest.startswith("Optional packet"):
                items.append("OPT")
            elif pk:
                items.append(("P",) + tuple(int(x) for x in pk.groups() if x))
            else:
                items.append(rest.split()[0])
        res[nid] = items
    return res


def cross_check(cat, variables):
    t7 = open(MD7, encoding="utf-8").read()
    t8 = open(MD8, encoding="utf-8").read()
    stats = {"packets": 0, "vars": 0, "messages": 0}

    # packets
    mdp = md_packets(t7)
    for p in cat.get("packets", []):
        key = (p["direction"], p["nid"])
        w = f"packet {key[0]}:{key[1]}"
        mine = flatten(p["fields"], variables)
        theirs = mdp.get(key)
        if theirs is None:
            R.err(w, "no table in the markdown")
            continue
        if key in MD_PACKET_PATCHES:
            at, row = MD_PACKET_PATCHES[key]
            theirs = theirs[:at] + [row] + theirs[at:]
            R.known.append(KNOWN_MD_DEFECTS[("packet", f"{key[0]}:{key[1]}")])
        names_m = [n for n, _ in mine]
        names_t = [n for n, _ in theirs]
        if names_m != names_t:
            R.err(w, f"variables differ from the markdown:\n    catalogue {names_m}\n    markdown  {names_t}")
            continue
        for (n, b), (_, l) in zip(mine, theirs):
            if n != "RAW" and b != l:
                R.err(w, f"{n}: bits {b} in the catalogue, {l} in the markdown")
        stats["packets"] += 1
    for key in mdp:
        if key not in {(p["direction"], p["nid"]) for p in cat.get("packets", [])}:
            R.err(f"packet {key[0]}:{key[1]}", "in the markdown, not in the catalogue")
    lists = md_packet_lists(t7)
    have = {(p["direction"], p["nid"]) for p in cat.get("packets", [])}
    for key in sorted(lists - have):
        R.err(f"packet {key[0]}:{key[1]}", "listed in 7.4.1, not in the catalogue")
    for key in sorted(have - lists):
        R.err(f"packet {key[0]}:{key[1]}", "not listed in 7.4.1")

    # variables
    mdv, empty = md_variables(t7)
    for name, (clause, length) in mdv.items():
        w = f"variable {name}"
        if name in COMBINED:
            if name in variables:
                R.err(w, "10 + 14 variable has an entry")
            if length != "10+14":
                R.err(w, f"markdown length {length}, expected 10 + 14")
            stats["vars"] += 1
            continue
        v = variables.get(name)
        if v is None:
            R.err(w, f"heading {clause} in the markdown, not in the catalogue")
            continue
        if v["clause"] != clause:
            R.err(w, f"clause {v['clause']} in the catalogue, {clause} in the markdown")
        if length is None or str(v["bits"]) != length:
            key = ("variable-length", name)
            if key in KNOWN_MD_DEFECTS:
                R.known.append(KNOWN_MD_DEFECTS[key])
            else:
                R.err(w, f"bits {v['bits']} in the catalogue, {length} in the markdown")
        stats["vars"] += 1
    for name in variables:
        if name not in mdv:
            key = ("variable-heading", name)
            if key in KNOWN_MD_DEFECTS:
                R.known.append(KNOWN_MD_DEFECTS[key])
            else:
                R.err(f"variable {name}", "no heading in the markdown")
    if empty and not any(k[0] == "variable-heading" for k in KNOWN_MD_DEFECTS):
        R.err("markdown", f"headings without a name: {empty}")

    # messages
    mdm = md_messages(t8)
    for m in cat.get("messages", []):
        w = f"message {m['nid']}"
        theirs = mdm.get(m["nid"])
        if theirs is None:
            R.err(w, "no table in the markdown")
            continue
        mine = []
        vars_ = [f["var"] for f in m["fields"]]
        # the markdown writes NID_LRBG where the catalogue has NID_C, NID_BG
        i = 0
        while i < len(vars_):
            if m["direction"] == "track_to_train" and vars_[i:i + 2] == ["NID_C", "NID_BG"] and i == 4:
                mine.append("NID_LRBG")
                i += 2
            else:
                mine.append(vars_[i])
                i += 1
        for e in m["packets"]:
            if e.get("optional"):
                if "OPT" not in mine:
                    mine.append("OPT")
            elif "one_of" in e:
                mine.append(("P",) + tuple(e["one_of"]))
            else:
                mine.append(("P", e["nid"]))
        # optional packets of 8.4.4.4 are not all announced in the tables
        theirs_c = list(theirs)
        if "OPT" in mine and "OPT" not in theirs_c:
            R.err(w, "optional packets not announced in the message table")
        if "OPT" in theirs_c and "OPT" not in mine:
            R.err(w, "message table announces optional packets, the catalogue has none")
        mine = [x for x in mine if x != "OPT"]
        theirs_c = [x for x in theirs_c if x != "OPT"]
        if mine != theirs_c:
            R.err(w, f"fields differ from the markdown:\n    catalogue {mine}\n    markdown  {theirs_c}")
            continue
        stats["messages"] += 1
    ids = set(mdm)
    for nid in sorted(ids - {m["nid"] for m in cat.get("messages", [])}):
        R.err(f"message {nid}", "in the markdown, not in the catalogue")
    return stats


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "etcs_language.toml")
    with open(path, "rb") as f:
        cat = tomllib.load(f)
    for k in cat:
        if k not in ("variables", "packets", "messages"):
            R.err("catalogue", f"unknown top-level key {k!r}")
    variables = cat.get("variables", {})
    check_variables(variables)
    used = set()
    keys = check_packets(cat.get("packets", []), variables, used)
    check_messages(cat.get("messages", []), variables, keys, used)
    stats = cross_check(cat, variables)
    unused = sorted(set(variables) - used)

    t2t = sum(1 for p in cat.get("packets", []) if p.get("direction") == "track_to_train")
    t2g = sum(1 for p in cat.get("packets", []) if p.get("direction") == "train_to_track")
    print(f"catalogue: {len(variables)} variables, {t2t} track-to-train and {t2g} "
          f"train-to-track packets, {len(cat.get('messages', []))} messages")
    print(f"markdown: {stats['packets']} packets, {stats['vars']} variables and "
          f"{stats['messages']} messages match")
    if unused:
        print(f"variables used by no packet or message ({len(unused)}; the balise and "
              f"loop telegram headers of 8.4.2 and 8.4.3 use them): {', '.join(unused)}")
    used_known = set(R.known)
    for k, text in KNOWN_MD_DEFECTS.items():
        if text not in used_known:
            R.err("KNOWN_MD_DEFECTS", f"{k} listed but not found in the markdown (stale entry)")
    if R.known:
        print(f"known markdown defects ({len(R.known)}):")
        for k in sorted(set(R.known)):
            print(f"  - {k}")
    for e in R.errors:
        print(e)
    print("PASS" if not R.errors else f"FAIL: {len(R.errors)} error(s)")
    return 0 if not R.errors else 1


if __name__ == "__main__":
    sys.exit(main())
