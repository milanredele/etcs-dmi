# Tools for the specifications

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
