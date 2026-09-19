#!/usr/bin/env python3
"""Import the SUBSET-026 (ERTMS/ETCS SRS) PDF bundle as searchable markdown.

    python3 -m venv venv && venv/bin/pip install pymupdf4llm
    venv/bin/python doc/SRS/tools/import_subset026.py <folder with the PDFs>

Writes doc/SRS/SUBSET-026_v400/: the PDFs, sections/*.md and README.md
(the index). The text comes from pymupdf4llm (layout mode, running page
headers and footers dropped); this script only
  - turns the page separators into <!-- end of page N --> comments, so a
    clause can be looked up on its page in the PDF,
  - drops the repeated "ERA * UNISIG * EEIG ERTMS USERS GROUP" banner,
  - removes the list dash in front of clause numbers and separates headings
    and clauses that were glued to the previous clause, so that
    grep '^3.13.10.4.2 ' finds a clause,
  - splits chapter 3 (252 pages) into one file per section 3.x,
  - builds the index from the numbered headings.
The markdown is a reading and search aid. Tables that span pages are split,
formulas and figures are lost or garbled: the PDF is the reference.
Converted with pymupdf4llm 1.28.2.
"""
import re
import shutil
import sys
from pathlib import Path

import pymupdf
import pymupdf4llm

VERSION = "4.0.0"
ROOT = Path(__file__).resolve().parents[1] / "SUBSET-026_v400"
TITLES = {
    1: "Introduction", 2: "Basic System Description", 3: "Principles",
    4: "Modes and Transitions", 5: "Procedures",
    6: "Management of older System Versions", 7: "ERTMS/ETCS language",
    8: "Messages", 9: "Classification of clauses",
}
DMI_ENTRY_POINTS = """## Where the DMI specification leans on this document

| Topic | Clauses | File |
|---|---|---|
| Supervision statuses, brake commands, what is displayed in CSM, TSM and RSM (DMI chapter 7 summarises this) | 3.13.10, Tables 5 to 15 | [03_13](sections/03_13_speed_and_distance_monitoring.md) |
| Supervision limits behind Vperm, Vwarning, Vsbi, release speed | 3.13.9 | [03_13](sections/03_13_speed_and_distance_monitoring.md) |
| Text messages: display conditions, acknowledgement, end conditions | 3.12.3 | [03_12](sections/03_12_other_profiles.md) |
| Track conditions and their announcement to the driver | 3.12.1, 5.18 | [03_12](sections/03_12_other_profiles.md), [05](sections/05_procedures.md) |
| Geographical position, tolerance of Big Metal Mass, track ahead free, ATO selector | 3.6.6, 3.15.5, 3.15.7, 3.15.11 | [03_06](sections/03_06_location_principles_train_position_and_train_ori.md), [03_15](sections/03_15_special_functions.md) |
| Train data, additional data, national values, data view | 3.18 | [03_18](sections/03_18_system_data.md) |
| Modes: description and responsibilities, among them Automatic Driving | 4.4 (AD: 4.4.16) | [04](sections/04_modes_and_transitions.md) |
| Mode transitions and their conditions. The matrix of 4.6.2 is garbled in the markdown: read page 48 of the chapter 4 PDF; the conditions table 4.6.3 is fine | 4.6.2, 4.6.3 | [04](sections/04_modes_and_transitions.md) |
| What the DMI shows and accepts in each mode | 4.7.2 | [04](sections/04_modes_and_transitions.md) |
| Start of Mission, the dialogue behind the DMI start-up windows | 5.4 | [05](sections/05_procedures.md) |
| Shunting, override, on-sight, level transitions, train trip, reversing, limited supervision, supervised manoeuvre: the acknowledgements and driver requests | 5.6 to 5.13, 5.19, 5.21 | [05](sections/05_procedures.md) |
| Variables and packets, for value ranges and resolutions of what is displayed | 7.4, 7.5 | [07](sections/07_ertms_etcs_language.md) |

The ATO side of Automatic Driving (engage and disengage conditions, what the
ATO on-board does on an ETCS brake command) is in SUBSET-125, which is not
in the repository.
""".splitlines()
SPLIT = {3}  # chapters written as one file per section

BANNER = re.compile(r"^(#+ )?\*\*ERA \* UNISIG \* EEIG ERTMS USERS GROUP\*\* *$")
PAGE = re.compile(r"^--- end of page\.page_number=(\d+) ---$")
DASH = re.compile(r"^- (?=(\*\*)?[0-9A-Z]+(\.[0-9]+)+ )")
GLUED_HEAD = re.compile(r"(?<=\S) +(\*\*(\d+(?:\.\d+){1,4}) +[^*|]+\*\*) *")
GLUED_CLAUSE = re.compile(r"(?<=[.:;]) +(?=\d+(?:\.\d+){2,} +(?:[A-Z]|\())")
HEAD = re.compile(r"^(?:#+ )?\*\*((?:A?\d+)(?:\.\d+){1,2}) +(.+?)\*\* *$")


def slug(text):
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")[:48]


def clean(md):
    out = []
    for line in md.splitlines():
        line = line.rstrip()
        if BANNER.match(line):
            continue
        m = PAGE.match(line)
        if m:
            line = f"<!-- end of page {m.group(1)} -->"
        line = DASH.sub("", line)
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
    return "\n".join(out).strip() + "\n"


def headings(md):
    """(number, title, line) of the numbered headings down to x.y.z."""
    seen, found = set(), []
    for n, line in enumerate(md.splitlines(), 1):
        m = HEAD.match(line)
        if not m or m.group(1) in seen:
            continue
        title = re.sub(r"\*\*|\s+\.{4,}.*$", "", m.group(2)).strip()
        if "Modification History" in title or "Table of Contents" in title:
            continue
        seen.add(m.group(1))
        found.append((m.group(1), title, n))
    return found


def split_sections(chapter, md):
    """Cut a chapter in front of every heading 'chapter.N'."""
    top = re.compile(rf"^#+ \*\*({chapter}\.\d+|APPENDIX TO CHAPTER {chapter})(?: +(.*?))?\*\* *$")
    parts, name, buf = [], f"{chapter:02d}_00_front_and_toc", []
    for line in md.splitlines():
        m = top.match(line)
        if m and "Modification History" not in line and "Table of Contents" not in line:
            parts.append((name, "\n".join(buf).strip() + "\n"))
            if m.group(1).startswith("APPENDIX"):
                name = f"{chapter:02d}_A_appendix"
            else:
                sec = int(m.group(1).split(".")[1])
                name = f"{chapter:02d}_{sec:02d}_{slug(m.group(2) or '')}"
            buf = []
        buf.append(line)
    parts.append((name, "\n".join(buf).strip() + "\n"))
    return parts


def main(src):
    sections = ROOT / "sections"
    if sections.exists():
        shutil.rmtree(sections)
    sections.mkdir(parents=True)
    index = [
        f"# SUBSET-026 v{VERSION}: ERTMS/ETCS System Requirements Specification",
        "",
        "Reference [2] of the DMI specification (ERA_ERTMS_015560). The PDFs in",
        "this folder are the reference; `sections/` holds their text as markdown",
        "for searching and reading, generated by",
        "[../tools/import_subset026.py](../tools/import_subset026.py). Tables that",
        "span pages are split, formulas and figures are lost or garbled: check the",
        "PDF page (`<!-- end of page N -->` comments) before relying on a detail.",
        "A clause starts its own line: `grep -rn '^3.13.10.4.2 ' sections/`.",
        "",
        *DMI_ENTRY_POINTS,
        "## Contents",
        "",
    ]
    for chapter, title in TITLES.items():
        pdf = Path(src) / f"SUBSET-026-{chapter} v400.pdf"
        dst = ROOT / f"SUBSET-026-{chapter}_v400.pdf"
        shutil.copyfile(pdf, dst)
        doc = pymupdf.open(pdf)
        md = clean(pymupdf4llm.to_markdown(
            doc, header=False, footer=False, page_separators=True,
            write_images=False, show_progress=False))
        if chapter in SPLIT:
            files = split_sections(chapter, md)
        else:
            files = [(f"{chapter:02d}_{slug(title)}", md)]
        index += [f"### Chapter {chapter}: {title}", "",
                  f"[{dst.name}]({dst.name}), {doc.page_count} pages", ""]
        for name, text in files:
            (sections / f"{name}.md").write_text(text)
            heads = headings(text)
            if len(files) > 1 and not heads:
                index.append(f"- [{name}.md](sections/{name}.md)")
            for number, head, line in heads:
                depth = number.count(".") - 1
                if chapter == 9 and depth > 0:
                    continue
                index.append(f"{'  ' * depth}- {number} [{head}](sections/{name}.md#L{line})")
        index.append("")
        print(f"chapter {chapter}: {doc.page_count} pages, {len(files)} file(s)")
    (ROOT / "README.md").write_text("\n".join(index))


if __name__ == "__main__":
    main(sys.argv[1])
