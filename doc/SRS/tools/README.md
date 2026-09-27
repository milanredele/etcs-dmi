# SRS tools

**import_subset026.py** imports the SUBSET-026 v4.0.0 PDF bundle as
searchable markdown: it copies the PDFs to `../SUBSET-026_v400/`, converts
them with pymupdf4llm into `sections/*.md` (page separators as
`<!-- end of page N -->`, clauses at the start of a line, chapter 3 split
per section 3.x, the 4.6.2 transition matrix rebuilt from the PDF page) and
writes the index `README.md`. It needs pymupdf4llm:

    python3 -m venv venv && venv/bin/pip install pymupdf4llm
    venv/bin/python doc/SRS/tools/import_subset026.py <folder with the PDFs>

**trace_subset026.py** writes the clause coverage matrix
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
