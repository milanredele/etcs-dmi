#!/usr/bin/env python3
"""Import an ERTMS/ETCS subset (one or more PDFs) as searchable markdown.

    python3 -m venv venv && venv/bin/pip install pymupdf4llm
    venv/bin/python doc/SRS/tools/import_subset.py SUBSET-034 4.0.0 SUBSET-034_v400.pdf
    venv/bin/python doc/SRS/tools/import_subset.py SUBSET-037 4.0.0 \\
        SUBSET-037-1_v400.pdf SUBSET-037-2_v400.pdf SUBSET-037-3_v400.pdf
Options: --title and --url (once per PDF) for a new README, --depth for
the index (3: down to x.y.z), --pdf-only to copy the PDFs and write a README
without contents.

Writes doc/SRS/<SUBSET>_v<version without dots>/: the PDFs (named after
the subset and part, e.g. SUBSET-037-2_v400.pdf), sections/*.md and
README.md. Derived from import_subset026.py, without its SUBSET-026
specific rebuilds. The text comes from pymupdf4llm (layout mode, no OCR,
running page headers and footers dropped); this script only
  - turns the page separators into <!-- end of page N --> comments, so a
    clause can be looked up on its page in the PDF,
  - drops the running banners the converter keeps ("ERA * UNISIG * EEIG
    ERTMS USERS GROUP", "© This document has been developed and released by
    UNISIG", and any heading without digits repeated on four pages or more)
    and the <mark>/<u> tags of change marks,
  - turns back into paragraphs the text the converter took for a table (a
    table whose rows have one non-empty cell, or a clause number and one
    other cell; not a table of contents),
  - restores clause numbers that the PDF draws as small images left of the
    text (Word numbering printed through Foxit, SUBSET-125 and SUBSET-130):
    each image is read with tesseract at four resolutions, needed on the
    PATH only for those PDFs, the reading is chosen by the sequence of the
    numbers, and the number is written in front of the text right of the
    image, cutting a paragraph in two where the converter joined two
    clauses; the corrections are printed,
  - prints the numbered entries of the PDF outline, where there is one,
    that start no line of the markdown,
  - joins a clause number standing alone on its line to the text or title
    that follows, removes the list dash and the bold around clause numbers,
    and separates headings and clauses that were glued to the previous
    clause, so that grep '^2.2.3.1 ' finds a clause,
  - splits each PDF at its top-level numbered chapters (and annexes), one
    file per chapter, what precedes the first chapter in 00_front.md,
  - builds the index of README.md from the numbered headings, down to
    x.y.z (--depth), and prints the count of numbered lines per file.
A README.md already in the folder keeps everything above its "## Contents"
line (the hand-written description); only the contents are regenerated.
With --pdf-only only the PDFs are copied and the README gets no contents.
The markdown is a reading and search aid. Tables that span pages are split,
formulas and figures are lost or garbled: the PDF is the reference.
Converted with pymupdf4llm 1.28.2 and tesseract 5.5.
"""
import argparse
import collections
import difflib
import re
import shutil
import subprocess
import sys
from pathlib import Path

import pymupdf
import pymupdf4llm

SRS = Path(__file__).resolve().parents[1]
NUM = r"(?:[A-Z]\.?)?\d+(?:\.\d+)*"   # 3.1.2, A.1.2, A1, B2.3

BANNER = re.compile(
    r"^(?:#+ )?\*\*(?:(?:ERA|UNISIG|EEIG|ERTMS|USERS|GROUP|UNIFE|UNIT)[ *]*)+\*\* *$"
    r"|^(?:> )?© _?This document has been developed and released by UNISIG_? *$")
PAGE = re.compile(r"^--- end of page\.page_number=(\d+) ---$")
DASH = re.compile(rf"^- (?=(\*\*)?{NUM} )")
BOLD_NUM = re.compile(rf"^(?:- )?(?:\*\*|_)({NUM})(?:\*\*|_) +(?=\S)")
BOLD_HEAD = re.compile(r"^\*\*((?:[A-Z]\.)?\d+(?:\.\d+){1,2})\.? +[^*]+\*\* *$")
ALONE = re.compile(rf"^(#+ |- )?(\*\*)?({NUM})\.?(\*\*)? *$")
GLUED_HEAD = re.compile(r"(?<=\S) +(\*\*(\d+(?:\.\d+){1,4}) +[^*|]+\*\*) *")
GLUED_CLAUSE = re.compile(r"(?<=[.:;]) +(?=\d+(?:\.\d+){2,} +(?:[A-Z]|\())")
HEAD = re.compile(rf"^(?:#+ )?\*\*({NUM})\.? +(.+?)\*\* *$|^#+ ({NUM})\.? +(.+?) *$")
TOP = re.compile(
    r"^#+ \*\*(?:(\d{1,2})\.?|((?:ANNEX|Annex|APPENDIX|Appendix)\s+([A-Z]))[.:,]?)"
    r"\s+(.*?)\*\* *$")
SKIP_TITLES = ("modification history", "table of contents", "amendment record")


def slug(text):
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")[:48]


def norm(text):
    return re.sub(r"[^a-z0-9]", "", text.lower())


# ---------------------------------------------------------------- numbers --

def ocr(page, rect):
    """Readings of the clause number drawn in rect, one per rendering
    (tesseract misreads small Arial digits now and then, differently at
    each resolution); [] when tesseract is not there."""
    votes = []
    for dpi, pad in ((400, 2), (300, 2), (600, 2), (400, 8)):
        pix = page.get_pixmap(dpi=dpi, clip=rect + (-pad, -pad, pad, pad),
                              colorspace=pymupdf.csGRAY)
        try:
            out = subprocess.run(
                ["tesseract", "stdin", "stdout", "--psm", "7",
                 "-c", "tessedit_char_whitelist=0123456789.ABCDEFGH"],
                input=pix.tobytes("png"), capture_output=True, check=True)
        except (OSError, subprocess.CalledProcessError):
            return []
        votes.append(out.stdout.decode().strip().rstrip("."))
    # a clause number has a dot: chapter numbers are text in these PDFs
    return [v for v in votes if re.fullmatch(NUM, v) and "." in v]


def number_images(doc):
    """{page: [(number, first words of the text right of it)]} for the
    clause numbers drawn as images."""
    found, other = collections.defaultdict(list), set()
    for page in doc:
        words = page.get_text("words")
        for info in sorted(page.get_image_info(), key=lambda i: i["bbox"][1]):
            r = pymupdf.Rect(info["bbox"])
            if r.height > 16 or r.width > 80 or r.x0 > page.rect.width * 0.3:
                continue
            cy = (r.y0 + r.y1) / 2
            line = sorted(w for w in words if abs((w[1] + w[3]) / 2 - cy) < 5)
            if not line or any(w[0] < r.x1 - 1 and w[2] > r.x0 + 1 for w in line):
                continue  # nothing to the right, or text over the image
            right = [w[4] for w in line if w[0] >= r.x1 - 1][:8]
            votes = ocr(page, r)
            if votes and right:
                found[page.number + 1].append((votes, " ".join(right)))
            else:
                other.add(page.number + 1)
    if other:
        print(f"  small images left of text not read as a clause number (list"
              f" labels, figures), ignored on pages {sorted(other)}")
    resequence(found)
    return found


def successors(prev):
    """The numbers that may follow prev: the next one at any level, then
    down to three levels deeper (4.1.1.3 -> 4.1.1.4, 4.2, 4.2.1.1, 5.1 ...)."""
    p = [int(x) for x in prev.split(".")]
    out = {".".join(map(str, p + [1] * j)) for j in range(1, 4)}
    for k in range(len(p)):
        out |= {".".join(map(str, p[:k] + [p[k] + 1] + [1] * j)) for j in range(4)}
    return out


def resequence(found):
    """Choose each number from its readings and the previous number: a
    successor of the previous number that one reading gives, else the
    successor closest to the readings (4.2 read as 42, 7.7.1.4 as 7.7.14),
    else the most frequent reading (a new sequence, as after a table of
    contents). The numbers taken against the majority reading, and those
    that do not follow, are printed."""
    prev = None
    for pno, items in sorted(found.items()):
        for i, (votes, right) in enumerate(items):
            common = collections.Counter(votes).most_common()
            number = common[0][0]
            nexts = successors(prev) if prev and re.fullmatch(r"[\d.]+", prev) else set()
            read = [v for v, _ in common if v in nexts]
            if read:
                number = read[0]
            elif nexts:
                best = max(sorted(nexts), key=lambda n: max(
                    difflib.SequenceMatcher(None, n, v).ratio() for v in votes))
                if max(difflib.SequenceMatcher(None, best, v).ratio() for v in votes) >= 0.8:
                    number = best
                else:
                    print(f"  page {pno}: {number} does not follow {prev}")
            if number != common[0][0]:
                print(f"  page {pno}: {number} by sequence, read {votes}")
            items[i] = (number, right)
            prev = number


def restore_numbers(md, found):
    """Write each image number in front of its line (raw converter output)."""
    lines = md.splitlines()
    starts, page = {1: 0}, 1
    for i, line in enumerate(lines):
        m = PAGE.match(line)
        if m:
            page = int(m.group(1)) + 1
            starts[page] = i + 1
    starts[page + 1] = len(lines)
    lost = 0
    # last page first: a line cut in two does not move the pages before it
    for pno, items in sorted(found.items(), reverse=True):
        lo, hi = starts.get(pno, 0), starts.get(pno + 1, len(lines))
        cursor = lo
        for number, right in items:
            key = norm(right)[:24]
            hit = None
            for rng in (range(cursor, hi), range(lo, hi)):
                hit = next((i for i in rng if key and norm(lines[i]).startswith(key)), None)
                if hit is not None:
                    break
            if hit is None:
                # two clauses the converter ran into one paragraph: cut the
                # line where the text of the numbered one starts
                chars = norm(right)[:24]
                pat = re.compile(r"(?<=\S) +(?=[^a-z0-9]*" + "[^a-z0-9]*".join(chars) + ")",
                                 re.IGNORECASE)
                hit = next((i for i in range(max(lo, cursor - 1), hi)
                            if pat.search(lines[i])), None)
                if hit is None:
                    lost += 1
                    print(f"  page {pno}: {number} not placed (text {right[:40]!r})")
                    continue
                m = pat.search(lines[hit])
                lines[hit:hit + 1] = [lines[hit][:m.start()].rstrip(), "",
                                      f"{number} {lines[hit][m.end():].lstrip()}"]
                hi += 2
                cursor = hit + 3
                continue
            if lines[hit].startswith("|"):  # a table row: into its first cell
                lines[hit] = f"|{number} {lines[hit][1:]}"
                cursor = hit + 1
                continue
            m = re.match(r"^(\s*(?:#+ |- )?)(.*)$", lines[hit])
            lead, text = m.group(1), m.group(2)
            if not lead.startswith("#"):
                lead = ""
            if re.fullmatch(r"\*\*[^*]+\*\* *", text):
                lines[hit] = f"{lead}**{number} {text[2:]}"
            else:
                lines[hit] = f"{lead}{number} {text}"
            cursor = hit + 1
    placed = sum(len(v) for v in found.values()) - lost
    print(f"  {placed} clause numbers restored from images, {lost} not placed")
    return "\n".join(lines)


def check_numbers(md, doc):
    """Report the numbered outline entries whose number starts no line."""
    starts = set(re.findall(rf"(?m)^(?:#+ )?(?:\*\*)?({NUM})\.? ", md))
    outline = [t for t in doc.get_toc() if re.match(rf"{NUM}\.? ", t[1])]
    missing = [t[1].split()[0].rstrip(".") for t in outline
               if t[1].split()[0].rstrip(".") not in starts]
    if outline:
        print(f"  outline: {len(outline) - len(missing)} of {len(outline)} numbered"
              f" entries start a line" + (f"; missing {missing[:8]}" if missing else ""))


# ------------------------------------------------------------------ clean --

def unwrap_tables(md):
    """Paragraphs the converter took for a table (text in a box, or clauses
    laid out in columns) back to paragraphs: a table whose rows have one
    non-empty cell, or a clause number and one other cell."""
    def row_text(line):
        cells = [c.replace("<br>", " ").strip() for c in line.strip().strip("|").split("|")]
        full = [c for c in cells if c]
        if len(full) == 2 and re.fullmatch(r"(\*\*)?(?:[A-Z]\.?)?\d+(?:\.\d+)+\.?(\*\*)?", full[0]):
            number = full[0].strip("*").rstrip(".")
            title = re.fullmatch(r"\*\*(.+?)\*\*", full[1])
            return f"**{number} {title.group(1)}**" if title else f"{number} {full[1]}"
        return full[0] if len(full) == 1 else None if full else ""

    lines, out, block = md.splitlines(), [], []

    def flush():
        rows = [l for l in block if not re.fullmatch(r"\|(?:\s*:?-+:?\s*\|)+\s*", l.strip())]
        texts = [row_text(l) for l in rows]
        leaders = any(re.search(r"\.{5,}", l) for l in rows)  # a table of contents
        if rows and not leaders and all(t is not None for t in texts):
            for t in texts:
                if t:
                    out.extend([t, ""])
        else:
            out.extend(block)
        block.clear()

    for line in lines:
        if line.startswith("|"):
            block.append(line)
            continue
        if block:
            flush()
        out.append(line)
    if block:
        flush()
    return "\n".join(out)


def banners(md):
    """Headings without digits that repeat on four pages or more."""
    count = collections.Counter(
        l.strip() for l in md.splitlines()
        if l.startswith("#") and not re.search(r"\d", l))
    return {l for l, n in count.items() if n >= 4}


def join_alone(lines):
    """A number alone on its line takes the next non-empty line."""
    out, i = [], 0
    while i < len(lines):
        m = ALONE.match(lines[i].strip())
        j = i + 1
        while j < len(lines) and lines[j].strip() == "":
            j += 1
        if m and "." in m.group(3) and j < len(lines) and j - i <= 3 \
                and not lines[j].lstrip().startswith(("|", "<!--", "---")) \
                and not ALONE.match(lines[j].strip()):
            nxt = re.sub(r"^\s*(?:#+ |- |> )?", "", lines[j]).rstrip()
            lead = m.group(1) if (m.group(1) or "").startswith("#") else ""
            title = re.fullmatch(r"\*\*(.+?)\*\*", nxt)
            if m.group(2) or title:
                body = title.group(1) if title else nxt.replace("**", "")
                out.append(f"{lead}**{m.group(3)} {body}**")
            else:
                out.append(f"{m.group(3)} {nxt}")
            i = j + 1
            continue
        out.append(lines[i])
        i += 1
    return out


def clean(md):
    drop = banners(md)
    out = []
    for line in join_alone([l.rstrip() for l in md.splitlines()]):
        if BANNER.match(line.strip()) or line.strip() in drop:
            continue
        m = PAGE.match(line)
        if m:
            line = f"<!-- end of page {m.group(1)} -->"
        line = BOLD_NUM.sub(r"\1 ", line)
        line = DASH.sub("", line)
        # a bold numbered title on its own is a heading: 2.2 -> ##, 2.2.1 -> ###
        line = BOLD_HEAD.sub(lambda g: "#" * (g.group(1).count(".") + 1) + " " + g.group(0), line)
        if not line.startswith(("|", "#")):
            # a heading or a clause glued to the end of the previous clause
            line = GLUED_HEAD.sub(
                lambda g: f"\n\n{'#' * (g.group(2).count('.') + 1)} {g.group(1)}\n\n", line)
            line = GLUED_CLAUSE.sub("\n\n", line)
        for piece in line.split("\n"):
            piece = piece.strip() if "\n" in line else piece
            if piece == "" and out and out[-1] == "":
                continue
            out.append(piece)
    return "\n".join(out).strip() + "\n", sorted(drop)


# ------------------------------------------------------- split and index --

def split_chapters(md, prefix):
    """(name, key, title, text): the front matter, then one part per
    top-level heading whose number follows the previous one, or annex."""
    parts, name, key, title, buf = [], f"{prefix}00_front", None, "Front matter", []
    last = 0
    for line in md.splitlines():
        m = TOP.match(line)
        new = None
        if m and m.group(1) and int(m.group(1)) > last and int(m.group(1)) <= last + 2:
            last = int(m.group(1))
            new = (f"{prefix}{last:02d}_{slug(m.group(4))}", str(last),
                   re.sub(r"\s+", " ", m.group(4)).strip())
        elif m and m.group(2):
            new = (f"{prefix}{m.group(3)}_{slug(m.group(4))}", m.group(3),
                   f"{m.group(2)} {m.group(4)}".strip())
        if new:
            parts.append((name, key, title, "\n".join(buf).strip() + "\n"))
            (name, key, title), buf = new, []
        buf.append(line)
    parts.append((name, key, title, "\n".join(buf).strip() + "\n"))
    return [p for p in parts if p[3].strip()]


def headings(text, key, depth):
    """(number, title, line) of the numbered headings of chapter key."""
    seen, found = set(), []
    for n, line in enumerate(text.splitlines(), 1):
        m = HEAD.match(line)
        if not m:
            continue
        number, title = (m.group(1), m.group(2)) if m.group(1) else (m.group(3), m.group(4))
        first = re.match(r"[A-Z]|\d+", number).group(0)
        if key is None or first != key or number in seen:
            continue
        if number.count(".") < 1 or number.count(".") > depth - 1:
            continue
        title = re.sub(r"\*\*|\s+\.{4,}.*$", "", title).strip()
        if not title or title.lower().startswith(SKIP_TITLES):
            continue
        seen.add(number)
        found.append((number, title, n))
    return found


def clauses(text):
    return len(re.findall(rf"(?m)^{NUM} ", text))


def human(size):
    return f"{size / 1e6:.1f} MB" if size >= 1e6 else f"{size / 1e3:.0f} kB"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("subset", help="e.g. SUBSET-034")
    ap.add_argument("version", help="e.g. 4.0.0")
    ap.add_argument("pdfs", nargs="+", help="the PDF, or its parts in order")
    ap.add_argument("--title", help="title for a new README")
    ap.add_argument("--url", action="append", default=[], help="source URL, per PDF")
    ap.add_argument("--depth", type=int, default=3, help="index depth (3: x.y.z)")
    ap.add_argument("--pdf-only", action="store_true", help="copy the PDFs, no markdown")
    args = ap.parse_args()

    ver = args.version.replace(".", "")
    root = SRS / f"{args.subset}_v{ver}"
    root.mkdir(parents=True, exist_ok=True)
    sections = root / "sections"
    if sections.exists():
        shutil.rmtree(sections)
    readme = root / "README.md"
    head = []
    if readme.exists():
        old = readme.read_text().splitlines()
        head = old[:old.index("## Contents")] if "## Contents" in old else old
    if not head:
        head = [f"# {args.subset} v{args.version}: {args.title or args.subset}", ""]
        if not args.pdf_only:
            head += [
                "The PDF is the reference; `sections/` holds its text as markdown",
                "for searching and reading, generated by",
                "[../tools/import_subset.py](../tools/import_subset.py). Tables that",
                "span pages are split, formulas and figures are lost or garbled: check the",
                "PDF page (`<!-- end of page N -->` comments) before relying on a detail.",
                "A clause starts its own line: `grep -rn '^3.1.1.1 ' sections/`.", ""]
    while head and head[-1] == "":
        head.pop()
    index = head + ["", "## Contents", ""]

    multi = len(args.pdfs) > 1
    for part, src in enumerate(args.pdfs, 1):
        src = Path(src)
        # a part of the subset keeps its part number: SUBSET-037-2
        m = re.search(rf"{re.escape(args.subset)}-(\d+(?:-\d+)*)", src.name, re.I)
        stem = f"{args.subset}-{m.group(1)}" if m else args.subset
        if multi and not m:
            stem = f"{args.subset}-{part}"
        dst = root / f"{stem}_v{ver}.pdf"
        if src.resolve() != dst.resolve():
            shutil.copyfile(src, dst)
        doc = pymupdf.open(dst)
        size = human(dst.stat().st_size)
        url = args.url[part - 1] if len(args.url) >= part else None
        link = f", [source]({url})" if url else ""
        if multi:
            index += [f"### {stem}", ""]
        index += [f"[{dst.name}]({dst.name}), {doc.page_count} pages, {size}{link}", ""]
        print(f"{dst.name}: {doc.page_count} pages, {size}")
        if args.pdf_only:
            continue
        sections.mkdir(exist_ok=True)
        md = pymupdf4llm.to_markdown(
            doc, header=False, footer=False, page_separators=True,
            write_images=False, show_progress=False, use_ocr=False)
        # highlighting and underlining (change marks) only split the text
        md = re.sub(r"</?(?:mark|u)>", "", md)
        md = unwrap_tables(md)
        found = number_images(doc)
        if found:
            md = restore_numbers(md, found)
        md, dropped = clean(md)
        for d in dropped:
            print(f"  dropped repeated heading {d!r}")
        check_numbers(md, doc)
        prefix = f"{stem.rsplit('-', 1)[1]}_" if multi else ""
        for name, key, title, text in split_chapters(md, prefix):
            (sections / f"{name}.md").write_text(text)
            label = f"{key} " if key else ""
            index.append(f"- {label}[{title}](sections/{name}.md)")
            for number, head_, line in headings(text, key, args.depth):
                depth = number.count(".")
                index.append(f"{'  ' * depth}- {number} [{head_}](sections/{name}.md#L{line})")
            print(f"  {name}.md: {len(text.splitlines())} lines, {clauses(text)} numbered lines")
        index.append("")
    while index[-1] == "":
        index.pop()
    readme.write_text("\n".join(index) + "\n")


if __name__ == "__main__":
    sys.exit(main())
