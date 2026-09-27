#!/usr/bin/env python3
"""SUBSET-026 clause coverage matrix from the chapter 9 classification.

    python3 doc/SRS/tools/trace_subset026.py            # write the CSV
    python3 doc/SRS/tools/trace_subset026.py --check    # verify, exit 1 on error
    python3 doc/SRS/tools/trace_subset026.py --summary  # counts only
    venv/bin/python doc/SRS/tools/trace_subset026.py --compare  # md vs PDF

Chapter 9 of SUBSET-026 classifies every clause of chapters 1 to 8 as
ETCS on-board requirement, trackside requirement, definition, informative
or others (9.3.2.1). This tool writes doc/TRACE-SUBSET-026.csv with one row
per clause classified as an on-board requirement:

    clause, chapter, onboard, trackside, definition, informative, others,
    phase, status, note

- clause: the clause number and its qualifier as chapter 9 writes it
  ("3.5.3.4 a)", "3.6.6.10 1st bullet", "7.4.1.2 Table",
  "A.3.2 Table-footnote [1]"). The title that chapter 9 prints after the
  number of a packet, message or variable ("7.4.2.2 Packet Number 5:
  Linking", "7.5.1.42.2 L_CONSISTFRONTENGINEMIN") is dropped: the number
  identifies the element (9.3.2.2 b). Appendix clauses "A.3.x" belong to
  chapter 3 and sort after 3.x.
- onboard .. others: "x" as chapter 9 gives them. Only the first two are
  meant to combine (9.3.2.3); A.3.2 is on-board and informative in the
  document itself.
- phase: the EVC phase of doc/EVC-PLAN.md section 3, from PHASES below
  (longest prefix of the clause number wins, "-" when nothing matches).
- status: todo, partial, done, n/a or deferred (doc/EVC-PLAN.md section 4);
  partial, n/a and deferred need a note. New rows are "todo", or
  "deferred" with note "E7" in phase E7.

Status and note are kept by hand: a rerun keeps them for every clause that
is still there (keyed by clause) and reports the clauses that appeared or
disappeared. The rows are sorted by the numeric value of the clause
components, so the file diffs cleanly.

Sources. The normal run reads the markdown of chapter 9
(sections/09_classification_of_clauses.md) with the standard library only.
That markdown is a pymupdf4llm conversion and is handled as follows: <br>
and <sup> inside cells, the repeated table headers at every page break
(<!-- end of page N --> comments), clause cells split over two table rows
(a row with a clause number and no mark, continued by a row without a
number that carries the marks), titles after the number, the 6-column
header of chapters 1-5, 7, 8 and the 11-column header of chapter 6 (whose
left part has 5 columns: "Definition" and "Informative" are merged in one
cell, so the markdown cannot tell them apart there; the tool warns when
this matters for an on-board row), and a header row itself split over
two table rows. Converter damage is repaired: numbers that lost their dots
("74351" after 7.4.3.5 is 7.4.3.5.1, recovered from the previous row; -v
lists them), an ordinal glued to the number ("5.18.2.32<sup>nd</sup>
bullet" is 5.18.2.3 2nd bullet), "Figure2a". Typos of the document are
normalised ("7..4.2.20.1" is 7.4.2.20.1, "bulet" is bullet).

--pdf reads the PDF (SUBSET-026-9_v400.pdf) instead, from the word
positions on each page; it needs pymupdf (pip install pymupdf), which is
imported only then. --compare parses both sources and lists every clause
whose classification differs, over all categories, not only the on-board
rows. With pymupdf 1.28.2 and the v4.0.0 files the two sources agree on
every clause (see the report of --compare); the markdown is therefore the
default source.
"""
import argparse
import csv
import io
import re
import sys
from collections import Counter, OrderedDict
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRS = HERE.parent / "SUBSET-026_v400"
MD = SRS / "sections" / "09_classification_of_clauses.md"
PDF = SRS / "SUBSET-026-9_v400.pdf"
CSV = HERE.parents[1] / "TRACE-SUBSET-026.csv"

# Phase of doc/EVC-PLAN.md section 3 for a clause number prefix. The
# longest matching prefix wins; a clause no prefix matches gets "-".
PHASES = [
    ("1", "-"),
    ("2", "-"),
    ("3.3", "-"),
    # E1 Language
    ("7", "E1"),
    ("8", "E1"),
    # E2 Position
    ("3.4", "E2"),
    ("3.6", "E2"),
    ("3.15.8", "E2"),
    ("5.12", "E2"),
    # E3 Supervision
    ("3.11", "E3"),
    ("3.12", "E3"),
    ("3.13", "E3"),
    ("3.14", "E3"),
    # E4 Modes and procedures, level 1
    ("4", "E4"),
    ("5", "E4"),
    ("3.12.3", "E4"),
    # E5 Radio, level 2
    ("3.5", "E5"),
    ("3.8", "E5"),
    ("3.10", "E5"),
    ("3.15.1", "E5"),
    ("3.16.3", "E5"),
    ("5.15", "E5"),
    # E6 Special functions and data
    ("3.7", "E6"),
    ("3.15", "E6"),
    ("3.16", "E6"),
    ("3.17", "E6"),
    ("3.18", "E6"),
    ("3.20", "E6"),
    # E7 Compatibility
    ("6", "E7"),
    ("3.9", "E7"),
]
PHASE_ORDER = ["E1", "E2", "E3", "E4", "E5", "E6", "E7", "-"]

STATUSES = ("todo", "partial", "done", "n/a", "deferred")
NEEDS_NOTE = ("partial", "n/a", "deferred")
FLAGS = ("onboard", "trackside", "definition", "informative", "others")
COLUMNS = ("clause", "chapter") + FLAGS + ("phase", "status", "note")

# --------------------------------------------------------------------------
# Clause labels

NUMBER = re.compile(r"(A\.)?(\d+(?:\.\d+)+)")
# The qualifiers chapter 9 writes after a clause number. Whatever follows
# the last qualifier is a title and is dropped.
QUALIFIER = re.compile(
    r"(?:Table-footnote(?: [\[{]\d+[a-z]?[\]}](?: Note)?)?"
    r"|Table(?: \d+[a-z]?)?"
    r"|Figure \d+[a-z]?"
    r"|\d+(?:st|nd|rd|th) (?:bullet|sub-bullet|hyphen)"
    r"|[a-z]{1,2}\)"
    r"|\d+\)"
    r"|step \d+"
    r"|last sentence"
    r"|[ADES]\d+)(?= |$)")


def clean(text):
    """Cell text as plain words: markup removed, spacing normalised."""
    # "5.18.2.32<sup>nd</sup> bullet" is 5.18.2.3 2nd bullet
    text = re.sub(r"(\.\d*)(\d)<sup>(st|nd|rd|th)</sup>", r"\1 \2\3", text)
    text = re.sub(r"<br\s*/?>", " ", text)
    text = re.sub(r"</?sup>", "", text)
    text = re.sub(r"</?(?:b|i|u|strong|em)>|\*\*|__", "", text)
    text = re.sub(r"(\d)\.\.(\d)", r"\1.\2", text)          # 7..4.2.20.1
    text = re.sub(r"(\d(?:st|nd|rd|th))\s*(bullet|bulet|sub-bullet|hyphen)",
                  r"\1 \2", text)
    text = text.replace("bulet", "bullet")
    text = re.sub(r"Table\s*-\s*footnote", "Table-footnote", text)
    text = re.sub(r"Figure\s*(\d)", r"Figure \1", text)
    text = re.sub(r"^((?:A\.)?\d+(?:\.\d+)+)(?=[A-Za-z])", r"\1 ", text)
    return " ".join(text.split())


def split_label(text):
    """(number, qualifier, title) of a clause cell, or None without number."""
    text = clean(text)
    m = NUMBER.match(text)
    if not m:
        return None
    number = m.group(0)
    rest = text[m.end():].strip()
    quals = []
    while rest:
        q = QUALIFIER.match(rest)
        if not q:
            break
        quals.append(q.group(0))
        rest = rest[q.end():].strip()
    return number, " ".join(quals), rest


def number_parts(number):
    """(chapter, appendix, components) of "3.5.1" or "A.3.1"."""
    appendix = number.startswith("A.")
    parts = [int(p) for p in number[2 if appendix else 0:].split(".")]
    return parts[0], appendix, parts


def sort_key(clause):
    number, _, qual = clause.partition(" ")
    chapter, appendix, parts = number_parts(number)
    qkey = []
    for tok in re.findall(r"\d+|[A-Za-z-]+|[^\sA-Za-z\d]", qual):
        qkey.append((0, int(tok), "") if tok.isdigit() else (1, len(tok), tok))
    return (chapter, appendix, parts, qkey)


def phase_of(number):
    _, appendix, parts = number_parts(number)
    if appendix:
        return "-"
    best, best_len = "-", 0
    for prefix, phase in PHASES:
        p = [int(x) for x in prefix.split(".")]
        if parts[:len(p)] == p and len(p) > best_len:
            best, best_len = phase, len(p)
    return best

# --------------------------------------------------------------------------
# Sources. Both return a list of entries in document order:
#   {"label": raw clause text, "flags": [5 x bool], "where": str,
#    "ambiguous": bool (definition/informative merged)}


def parse_markdown(path):
    lines = path.read_text(encoding="utf-8").split("\n")
    start = next(i for i, l in enumerate(lines)
                 if re.match(r"#+ \**9\.4 Classification of clauses", l))
    entries, warnings = [], []
    cmap = None          # cell index -> tuple of flag indices
    pending = None       # cells of the column header row
    page = None
    cur = None
    for lineno in range(start, len(lines)):
        line = lines[lineno].strip()
        m = re.match(r"<!-- end of page (\d+) -->", line)
        if m:
            page = int(m.group(1)) + 1
            continue
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line[1:-1].split("|")]
        words = clean(" ".join(cells))
        if re.fullmatch(r"[-| :]*", line):
            continue                                   # separator row
        first = clean(cells[0]).lower()
        if first.startswith("clause") and "number" in first:
            pending = cells                            # column header row
            cmap = header_map(pending)
            continue
        if pending is not None and cmap is None:
            # Header row split over two table rows: merge cell by cell.
            pending = [a + " " + b for a, b in zip(pending, cells)]
            cmap = header_map(pending)
            if cmap is None:
                raise SystemExit(f"md line {lineno + 1}: unrecognised "
                                 f"header {pending}")
            continue
        label = clean(cells[0])
        if (not NUMBER.match(label) and "x" not in map(clean, cells)
                and re.search(r"lassif|Claus|ETCS|Replac", words)):
            continue                                   # upper header rows
        if cmap is None:
            warnings.append(f"md line {lineno + 1}: row before any header")
            continue
        flags, ambiguous, odd = [False] * 5, False, []
        for idx, targets in cmap.items():
            v = clean(cells[idx]) if idx < len(cells) else ""
            if v == "x":
                for t in targets:
                    flags[t] = True
                ambiguous |= len(targets) > 1
            elif v:
                odd.append(v)
        if odd:
            warnings.append(f"md line {lineno + 1}: unexpected marks {odd}")
        where = f"md line {lineno + 1} (page {page})"
        dotless = re.match(r"(\d{3,}) ", label)
        if dotless and cur is not None:
            fixed = restore_dots(dotless.group(1), cur["label"])
            if fixed:
                warnings.append(f"note: {where}: clause number "
                                f"{dotless.group(1)} read as {fixed}")
                label = fixed + label[dotless.end() - 1:]
            else:
                warnings.append(f"{where}: clause number {dotless.group(1)} "
                                f"without dots, not recovered")
        if NUMBER.match(label) or label.startswith("APPENDIX"):
            cur = {"label": label, "flags": flags, "where": where,
                   "ambiguous": ambiguous}
            entries.append(cur)
        elif cur is not None and (label or any(flags)):
            cur["label"] += " " + label                # continuation row
            cur["flags"] = [a or b for a, b in zip(cur["flags"], flags)]
            cur["ambiguous"] |= ambiguous
        elif label:
            warnings.append(f"md line {lineno + 1}: orphan row {label!r}")
    return entries, warnings


def restore_dots(digits, previous):
    """The dots of a clause number the converter lost ("74351"), from the
    number of the previous row (7.4.3.5): the longest ancestor of it whose
    digits start the run, followed by the rest of the run as one component."""
    m = NUMBER.match(previous)
    if not m or m.group(1):
        return None
    parts = m.group(2).split(".")
    for n in range(len(parts), 0, -1):
        head = "".join(parts[:n])
        if digits.startswith(head) and len(digits) > len(head):
            return ".".join(parts[:n] + [digits[len(head):]])
    return None


def header_map(cells):
    """Cell index -> flag indices from the 'Clause number' header row, or
    None when the row does not name the five columns."""
    cmap = {}
    for i, c in enumerate(cells[1:], 1):
        t = clean(c)
        if "clause" in t.lower() and "number" in t.lower():
            break                                      # chapter 6: replaced
        targets = []
        if "board" in t:
            targets.append(0)
        if "trackside" in t:
            targets.append(1)
        if "Definition" in t:
            targets.append(2)
        if "Informative" in t:
            targets.append(3)
        if "Others" in t:
            targets.append(4)
        if targets:
            cmap[i] = tuple(targets)
        if 4 in targets:
            break
    if sorted(t for ts in cmap.values() for t in ts) != [0, 1, 2, 3, 4]:
        return None
    return cmap


def parse_pdf(path):
    try:
        import pymupdf
    except ImportError:
        raise SystemExit("--pdf and --compare need pymupdf: pip install pymupdf")
    doc = pymupdf.open(path)
    entries, warnings = [], []
    cur = None
    heads = ("board", "trackside", "Definition", "Informative", "Others")
    for pno in range(doc.page_count):
        words = doc[pno].get_text("words")
        foot = [w[1] for w in words if w[4].startswith("SUBSET-026-9")]
        ybot = min(foot) if foot else doc[pno].rect.height
        # Table headers on the page (chapter 7 and 8 share page 144).
        tops = sorted(w[1] for w in words if w[4] == "classification"
                      and any(v[4] == "Clause" and abs(v[1] - w[1]) < 3
                              for v in words))
        if not tops:
            continue
        bands = []
        for k, top in enumerate(tops):
            nxt = tops[k + 1] if k + 1 < len(tops) else ybot
            hw = [w for w in words if top - 3 <= w[1] < min(top + 60, nxt)]
            cols = []
            for h in heads:
                c = [w for w in hw if w[4] == h]
                if not c:
                    break
                cols.append(min(c, key=lambda w: w[0])[0])
            if len(cols) < 5:
                continue                               # no table here
            rep = [w[0] for w in hw if w[4] == "Replaced"]
            xmax = min(rep) - 10 if rep else 1e9
            hbot = max(w[3] for w in hw if w[4] in (
                "requirement", "requireme", "nt", "number", "Others"))
            bands.append((hbot, nxt, cols, xmax))
        for hbot, ybot_band, cols, xmax in bands:
            body = [w for w in words if w[1] > hbot and w[3] < ybot_band
                    and w[0] < xmax]
            text_words = [w for w in body if w[2] < cols[0] - 5]
            marks = [w for w in body if w[0] >= cols[0] - 12]
            # Lines of the clause column, by vertical centre.
            rows = []
            for w in sorted(text_words, key=lambda w: ((w[1] + w[3]) / 2, w[0])):
                yc = (w[1] + w[3]) / 2
                if rows and abs(rows[-1]["y"] - yc) < 3:
                    rows[-1]["words"].append(w)
                else:
                    rows.append({"y": yc, "words": [w]})
            owner = []
            for r in rows:
                ws = sorted(r["words"], key=lambda w: w[0])
                text = " ".join(w[4] for w in ws)
                if re.match(r"9\.4\.\d", text):
                    owner.append(None)                 # chapter heading
                    continue
                if NUMBER.match(clean(text)) or text.startswith("APPENDIX"):
                    cur = {"label": text, "flags": [False] * 5,
                           "where": f"pdf page {pno + 1}", "ambiguous": False}
                    entries.append(cur)
                elif cur is not None:
                    cur["label"] += " " + text
                owner.append(cur)
            for m in marks:
                if m[4] != "x":
                    warnings.append(f"pdf page {pno + 1}: stray {m[4]!r}")
                    continue
                yc = (m[1] + m[3]) / 2
                cands = [(abs(r["y"] - yc), i) for i, r in enumerate(rows)
                         if owner[i] is not None]
                if not cands:
                    warnings.append(f"pdf page {pno + 1}: mark without row")
                    continue
                d, i = min(cands)
                if d > 8:
                    warnings.append(f"pdf page {pno + 1}: mark {d:.1f} pt "
                                    f"from its row")
                xc = (m[0] + m[2]) / 2
                k = max(i for i in range(5) if cols[i] - 12 <= xc)
                e = owner[i]
                if e["flags"][k]:
                    warnings.append(f"{e['where']}: {e['label']}: two marks "
                                    f"in column {FLAGS[k]}")
                e["flags"][k] = True
    return entries, warnings

# --------------------------------------------------------------------------


def classify(entries):
    """Clause -> (flags, ambiguous, where) for every numbered entry."""
    table, warnings = OrderedDict(), []
    for e in entries:
        parts = split_label(e["label"])
        if parts is None:
            if e["flags"][0]:
                warnings.append(f"{e['where']}: on-board row without "
                                f"clause number: {e['label']!r}")
            continue
        number, qual, _title = parts
        clause = f"{number} {qual}".strip()
        if not any(e["flags"]):
            warnings.append(f"{e['where']}: {clause}: no classification")
        if clause in table:
            warnings.append(f"{e['where']}: {clause}: listed twice, "
                            f"classifications merged")
            old = table[clause]
            e = dict(e, flags=[a or b for a, b in zip(old[0], e["flags"])],
                     ambiguous=old[1] or e["ambiguous"])
        table[clause] = (e["flags"], e["ambiguous"], e["where"])
    return table, warnings


def build_rows(table):
    rows, warnings = [], []
    for clause, (flags, ambiguous, where) in table.items():
        if not flags[0]:
            continue
        if ambiguous and (flags[2] or flags[3]):
            warnings.append(f"{where}: {clause}: definition/informative "
                            f"merged in the markdown, check with --pdf")
        number = clause.split(" ")[0]
        chapter = number_parts(number)[0]
        row = {"clause": clause, "chapter": str(chapter)}
        for name, f in zip(FLAGS, flags):
            row[name] = "x" if f else ""
        row["phase"] = phase_of(number)
        row["status"], row["note"] = default_status(row["phase"])
        rows.append(row)
    rows.sort(key=lambda r: sort_key(r["clause"]))
    return rows, warnings


def default_status(phase):
    return ("deferred", "E7") if phase == "E7" else ("todo", "")


def read_csv(path):
    if not path.exists():
        return None
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def write_csv(path, rows):
    buf = io.StringIO()
    w = csv.DictWriter(buf, fieldnames=COLUMNS, lineterminator="\n")
    w.writeheader()
    w.writerows(rows)
    path.write_text(buf.getvalue(), encoding="utf-8")


def summary(rows, out=sys.stdout):
    by_ch = Counter(r["chapter"] for r in rows)
    by_ph = Counter(r["phase"] for r in rows)
    by_st = Counter(r["status"] for r in rows)
    print(f"{len(rows)} on-board clauses", file=out)
    print("per chapter: " + ", ".join(
        f"{c}: {by_ch[c]}" for c in sorted(by_ch, key=int)), file=out)
    print("per phase:   " + ", ".join(
        f"{p}: {by_ph[p]}" for p in PHASE_ORDER if by_ph[p]), file=out)
    print("per status:  " + ", ".join(
        f"{s}: {by_st[s]}" for s in STATUSES + tuple(
            sorted(set(by_st) - set(STATUSES))) if by_st[s]), file=out)
    ph_st = Counter((r["phase"], r["status"]) for r in rows)
    for p in PHASE_ORDER:
        if by_ph[p]:
            print(f"  {p:2}  " + ", ".join(
                f"{s}: {ph_st[p, s]}" for s in STATUSES if ph_st[p, s]),
                file=out)


def check(rows, existing):
    errors = []
    if existing is None:
        return ["the CSV does not exist; run the tool to create it"]
    if existing and list(existing[0].keys()) != list(COLUMNS):
        errors.append(f"columns are {list(existing[0].keys())}, "
                      f"expected {list(COLUMNS)}")
    for n, r in enumerate(existing, 2):
        st, note = r.get("status", ""), (r.get("note") or "").strip()
        if st not in STATUSES:
            errors.append(f"line {n}: {r.get('clause')}: status {st!r} "
                          f"not in {', '.join(STATUSES)}")
        elif st in NEEDS_NOTE and not note:
            errors.append(f"line {n}: {r.get('clause')}: status {st} "
                          f"needs a note")
    key = [c for c in COLUMNS if c not in ("status", "note")]
    want = [tuple(r[c] for c in key) for r in rows]
    have = [tuple(r.get(c, "") for c in key) for r in existing]
    if want != have:
        ws, hs = set(want), set(have)
        for t in sorted(ws - hs, key=lambda t: sort_key(t[0]))[:20]:
            errors.append(f"missing or different: {','.join(t)}")
        for t in sorted(hs - ws, key=lambda t: sort_key(t[0]))[:20]:
            errors.append(f"not expected: {','.join(t)}")
        if ws == hs:
            errors.append("rows are not in clause order")
    return errors


def compare(md_table, pdf_table):
    diffs = []
    for clause in sorted(set(md_table) | set(pdf_table), key=sort_key):
        a, b = md_table.get(clause), pdf_table.get(clause)
        if a is None or b is None:
            diffs.append(f"{clause}: only in {'pdf' if a is None else 'md'} "
                         f"({(a or b)[2]})")
            continue
        fa, fb = list(a[0]), list(b[0])
        if a[1]:                   # markdown merged definition/informative
            if (fa[2] or fa[3]) and (fb[2] or fb[3]):
                fa[2], fa[3] = fb[2], fb[3]
        if fa != fb:
            show = lambda f: "".join("x" if v else "." for v in f)
            diffs.append(f"{clause}: md {show(a[0])} ({a[2]}) "
                         f"pdf {show(b[0])} ({b[2]})")
    return diffs


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--check", action="store_true",
                   help="verify the CSV, exit 1 on error")
    g.add_argument("--summary", action="store_true", help="counts only")
    g.add_argument("--compare", action="store_true",
                   help="compare the markdown and the PDF (needs pymupdf)")
    ap.add_argument("--pdf", action="store_true",
                    help="read the PDF instead of the markdown (needs pymupdf)")
    ap.add_argument("--csv", type=Path, default=CSV, help=f"default {CSV}")
    ap.add_argument("-v", "--verbose", action="store_true",
                    help="also list the repairs made to the markdown")
    args = ap.parse_args()

    if args.summary:
        existing = read_csv(args.csv)
        if existing is None:
            raise SystemExit(f"{args.csv} does not exist")
        summary(existing)
        return 0

    if args.compare:
        md_t, w1 = classify(parse_markdown(MD)[0])
        pdf_t, w2 = classify(parse_pdf(PDF)[0])
        diffs = compare(md_t, pdf_t)
        onb = lambda t: sum(1 for v in t.values() if v[0][0])
        print(f"markdown: {len(md_t)} clauses, {onb(md_t)} on-board; "
              f"pdf: {len(pdf_t)} clauses, {onb(pdf_t)} on-board")
        for d in diffs:
            print("  " + d)
        print(f"{len(diffs)} differences")
        return 1 if diffs else 0

    entries, warnings = (parse_pdf(PDF) if args.pdf else parse_markdown(MD))
    table, w = classify(entries)
    rows, w2 = build_rows(table)
    warnings += w + w2
    for msg in warnings:
        if not msg.startswith("note: "):
            print("warning: " + msg, file=sys.stderr)
        elif args.verbose:
            print(msg, file=sys.stderr)
    existing = read_csv(args.csv)

    if args.check:
        errors = check(rows, existing)
        summary(existing or [])
        for e in errors:
            print("error: " + e)
        if errors:
            print(f"{len(errors)} errors")
            return 1
        print("ok")
        return 0

    old = OrderedDict((r["clause"], r) for r in existing or [])
    for r in rows:
        if r["clause"] in old:
            r["status"] = old[r["clause"]]["status"]
            r["note"] = old[r["clause"]]["note"]
    new = [r["clause"] for r in rows if r["clause"] not in old]
    gone = [c for c in old if c not in {r["clause"] for r in rows}]
    write_csv(args.csv, rows)
    if existing is not None:
        for c in new:
            print(f"appeared: {c}")
        for c in gone:
            print(f"disappeared: {c} (status {old[c]['status']}, "
                  f"note {old[c]['note']!r})")
    print(f"wrote {args.csv}")
    summary(rows)
    return 0


if __name__ == "__main__":
    sys.exit(main())
