# Tools for the specifications

## clause.py

[clause.py](clause.py) answers "what does clause N say" without reading a
chapter: `clause.py 3.6.5.1.4` prints the clause and its subclauses from
`sections/*.md` with the section file and the PDF page; `--page` appends
the PDF page(s) rendered by `pdftotext -layout` (poppler), where a table
keeps its columns, which the markdown loses; `--page 4:43` renders one
page; `--grep REGEX` lists the matching lines with their clause and page;
`--spec 036` (a number or a folder name: `036`, `SUBSET-036`, `015560`)
does the same in any document imported under doc/SRS, SUBSET-026 being the
default and `--dmi` the DMI specification (ERA_ERTMS_015560); `--specs`
lists the documents it finds (every folder with `sections/`), their PDFs
and clause lines. A document in several PDFs takes `--page part:page`, the
part being the number of the PDF's name and the first field of its section
files (`--page 4:43` chapter 4 of SUBSET-026, `--spec 037 --page 2:12` part
2 of SUBSET-037); a document in one PDF takes `--page N`. Clauses are the
lines that start with a number, `A.3.4` or a heading `### **4.2.9 Title**`;
the front matter, modification history and tables of contents are left out.
Limits: the DMI specification has no page markers (a clause has no page;
`--page N` works), and the glossary SUBSET-023 has no numbered clauses, its
terms being table rows `|CAB, ACTIVE|definition|`: `--spec 023 --grep`.

## import_subset026.py

[import_subset026.py](import_subset026.py) imports the SUBSET-026 v4.0.0 PDF bundle as
searchable markdown: it copies the PDFs to `../SUBSET-026_v400/`, converts
them with pymupdf4llm into `sections/*.md` (page separators as
`<!-- end of page N -->`, clauses at the start of a line, chapter 3 split
per section 3.x, the 4.6.2 transition matrix rebuilt from the PDF page) and
writes the index `README.md`. It needs pymupdf4llm:

    python3 -m venv venv && venv/bin/pip install pymupdf4llm
    venv/bin/python doc/SRS/tools/import_subset026.py <folder with the PDFs>

## import_subset.py

[import_subset.py](import_subset.py) imports an ERTMS/ETCS subset, one PDF
or its parts, into `doc/SRS/<SUBSET>_v<version>/`: the PDF, `sections/*.md`
with one file per top-level chapter or annex, and `README.md` with the index
built from the numbered headings. It applies the clean-ups of
[import_subset026.py](import_subset026.py) (page-end comments, banners,
clause numbers at the start of their line) without its SUBSET-026 specific
rebuilds, and adds what the other subsets need: clause numbers drawn as
images are read back with tesseract and checked against the sequence and
the PDF outline, and paragraphs the converter took for a table are turned
back into paragraphs. A README already in the folder keeps its hand-written
part above `## Contents`, so a re-import only regenerates the index.

    python3 -m venv venv && venv/bin/pip install pymupdf4llm   # 1.28.2
    brew install tesseract        # only for PDFs with numbers as images
    venv/bin/python doc/SRS/tools/import_subset.py SUBSET-034 4.0.0 SUBSET-034_v400.pdf \
        --title "Train Interface FIS" --url <ERA link>
    venv/bin/python doc/SRS/tools/import_subset.py SUBSET-037 4.0.0 \
        SUBSET-037-1_v400.pdf SUBSET-037-2_v400.pdf SUBSET-037-3_v400.pdf --title "EuroRadio FIS"

It prints, per PDF, the banners it dropped, the numbers it restored or
corrected, the outline entries it could not find at the start of a line,
and the number of clause lines per chapter file: read that output after a
re-import. `--depth` sets the depth of the index (3: x.y.z), `--pdf-only`
copies the PDF and writes the README without contents.

## trace_subset026.py

[trace_subset026.py](trace_subset026.py) writes the clause coverage matrix
`doc/TRACE-SUBSET-026.csv` (doc/EVC-PLAN.md §4): one row per clause that
SUBSET-026 chapter 9 classifies as an ETCS on-board requirement, with the
chapter 9 flags, the EVC phase (the prefix table `PHASES` at the top of the
tool, from doc/EVC-PLAN.md §3), a status (`todo`, `partial`, `done`,
`n/a`, `deferred`) and a note. The status and note are kept by hand; a
rerun keeps them and reports the clauses that appeared or disappeared.
`--check` fails on an unknown status, on a `partial`, `n/a` or `deferred`
row without a note, or when the CSV differs from what the tool would
regenerate; `--summary` prints the counts per chapter, phase and status.
The normal run reads the chapter 9 markdown with the standard library
only; `--pdf` reads the PDF instead and `--compare` lists every clause
whose classification differs between the two (both need pymupdf):

    python3 doc/SRS/tools/trace_subset026.py              # write or update the CSV
    python3 doc/SRS/tools/trace_subset026.py --check      # verify, exit 1 on error
    python3 doc/SRS/tools/trace_subset026.py --summary
    python3 -m venv venv && venv/bin/pip install pymupdf
    venv/bin/python doc/SRS/tools/trace_subset026.py --compare
