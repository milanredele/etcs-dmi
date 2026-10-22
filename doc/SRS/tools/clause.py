#!/usr/bin/env python3
"""A clause of a specification by number, instead of reading a chapter.

  doc/SRS/tools/clause.py 3.6.5.1.4          the clause and its subclauses
                                             (3.6.5.1.4, 3.6.5.1.4.1, ...),
                                             with the section file and the
                                             PDF page of each
  doc/SRS/tools/clause.py 4.5.2 --page       ... and then the PDF page(s) of
                                             the clause in layout mode:
                                             tables keep their columns there,
                                             the markdown loses them
  doc/SRS/tools/clause.py --page 4:43        page 43 of chapter 4 alone
  doc/SRS/tools/clause.py --grep "Report Train Position"
                                             the lines matching, with the
                                             clause they belong to and the page
  doc/SRS/tools/clause.py --spec 036 4.2.9   the same in another imported
                                             document: --spec takes its number
                                             (036, 36, 015560) or its folder
                                             (SUBSET-036, SUBSET-036_v400);
                                             SUBSET-026 is the default
  doc/SRS/tools/clause.py --dmi 8.3.2.1      the DMI specification
                                             (ERA_ERTMS_015560), --spec 015560
  doc/SRS/tools/clause.py --spec 036 --page 33
                                             page 33 of a document in one PDF
  doc/SRS/tools/clause.py --spec 037 --page 2:12
                                             page 12 of part 2: a document in
                                             several PDFs (SUBSET-026 by
                                             chapter, SUBSET-037 by part) takes
                                             part:page, the part being the
                                             number of the PDF's name
                                             (SUBSET-037-2_v400.pdf) and the
                                             first field of its section files
                                             (2_05_interface_to_safe_services.md)
  doc/SRS/tools/clause.py --specs            the documents found under doc/SRS,
                                             their PDFs and clause lines

The markdown under sections/ is a search aid converted from the PDFs: a
line that starts with a clause number (3.6.5.1.4, A.3.4, also as a heading
"### **4.2.9 Title**") opens the clause, "<!-- end of page N -->" closes
PDF page N. The front matter, the modification history and the tables of
contents, figures and tables list clause numbers once more: they are left
out. The numbers of tables and figures and the columns of a table are only
reliable on the PDF page: read it with --page when a table matters (and
mind that a cell's X is placed by character column under its header in
layout mode).

Limits: the DMI specification has no page markers (no page with a clause;
--page N works). The glossary SUBSET-023 has no numbered clauses: its terms
are table rows |TERM|definition|, some inverted ("CAB, ACTIVE"): use
--spec 023 --grep "cab, active".
"""
import glob
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRS = os.path.dirname(HERE)
DEFAULT = 'SUBSET-026_v400'
DMI = 'ERA_ERTMS_015560_v400'
CLAUSE = re.compile(r'^\s*(?:#+\s+)?(?:[-*]\s+)?(?:\*\*)?((?:[A-Z]|\d+)(?:\.\d+)+)(?:\*\*)?(?=[\s.:,)]|$)')
PAGE = re.compile(r'<!-- end of page (\d+) -->')
LEFT_OUT = ('toc', 'table_of_contents', 'list_of_tables', 'table_of_figures',
            'list_of_figures', 'modification_history', 'front')


def documents():
    """The folders of doc/SRS with a sections/ folder: the imported documents."""
    return sorted(os.path.basename(os.path.dirname(d))
                  for d in glob.glob(os.path.join(SRS, '*', 'sections')))


def select(name):
    """The folder of the document named by `name`: its number or its folder."""
    key = name.strip().upper()
    if key == 'DMI':
        return DMI
    if key.isdigit() and len(key) < 3:
        key = key.zfill(3)
    found = [d for d in documents()
             if re.search(r'(^|[-_])' + re.escape(key) + r'(_|$)', d.upper())]
    if len(found) != 1:
        print(f'clause: --spec {name}: {"ambiguous: " + ", ".join(found) if found else "no such document"}'
              f' (documents: {", ".join(documents())})')
        return None
    return found[0]


def pdfs(spec):
    return sorted(glob.glob(os.path.join(SRS, spec, '*.pdf')))


def part_of(section_file):
    """The part (or chapter) of a section file: the first field of its name."""
    return os.path.basename(section_file).split('_')[0].lstrip('0') or '0'


def pdf_of(spec, part):
    """The PDF of `part` (None: the document's only PDF)."""
    files = pdfs(spec)
    if len(files) == 1:
        return files[0]
    if part is None:
        return None
    for f in files:
        m = re.search(r'-(\d+)_[^/]*\.pdf$', f)
        if m and m.group(1).lstrip('0') == part.lstrip('0'):
            return f
    return None


def section_files(spec):
    return sorted(f for f in glob.glob(os.path.join(SRS, spec, 'sections', '*.md'))
                  if not any(w in os.path.basename(f) for w in LEFT_OUT))


def chapter_of(number):
    return number.split('.')[0]


def pages_after(lines, start):
    """The PDF page of line `start`: the next page marker after it."""
    for k in range(start, len(lines)):
        m = PAGE.search(lines[k])
        if m:
            return int(m.group(1))
    return None


def clause_end(lines, i, number):
    """The line after clause `number` opened at line i: the next clause that
    is not one of its subclauses."""
    j = i + 1
    while j < len(lines):
        m2 = CLAUSE.match(lines[j])
        if m2 and not m2.group(1).startswith(number + '.') and m2.group(1) != number:
            break
        j += 1
    return j


def find_clause(spec, number):
    """[(file, first, last, page)] of the clause: from its opening line to
    the line before the next clause that is not one of its subclauses."""
    hits = []
    chapter = chapter_of(number)
    for f in section_files(spec):
        base = os.path.basename(f)
        if spec == DEFAULT and chapter.isdigit() and not base.startswith(chapter.zfill(2) + '_'):
            continue
        lines = open(f).readlines()
        i = 0
        while i < len(lines):
            m = CLAUSE.match(lines[i])
            if m and m.group(1) == number:
                j = clause_end(lines, i, number)
                # trim trailing blank lines and page markers of the next page
                k = j
                while k > i + 1 and (not lines[k - 1].strip() or PAGE.search(lines[k - 1])):
                    k -= 1
                hits.append((f, i, k, pages_after(lines, i)))
                i = j
            else:
                i += 1
    return hits


def where(spec, f, page):
    if page is None:
        return 'no page markers in this document: --page N alone'
    pdf = pdf_of(spec, part_of(f))
    return f'PDF page {page}' + (f' of {os.path.basename(pdf)}' if pdf and len(pdfs(spec)) > 1 else '')


def print_clause(spec, number, with_page):
    hits = find_clause(spec, number)
    if not hits:
        print(f'clause: {number} not found in {spec} (a table row or a footnote is only on the PDF page: --grep, --page)')
        return 1
    pages = []
    for f, first, last, page in hits:
        lines = open(f).readlines()
        print(f'== {os.path.relpath(f, SRS)}:{first + 1}-{last} ({where(spec, f, page)})')
        for k in range(first, last):
            l = lines[k].rstrip('\n')
            m = PAGE.search(l)
            if m:
                print(f'   -- page {m.group(1)} ends --')
                continue
            if l.strip():
                print(l)
        print()
        if page is not None:
            last_page = pages_after(lines, last - 1) or page
            for p in range(page, last_page + 1):
                if (part_of(f), p) not in pages:
                    pages.append((part_of(f), p))
    if with_page:
        for part, p in pages:
            print_page(spec, part, p)
    return 0


def print_page(spec, part, page):
    pdf = pdf_of(spec, part)
    if not pdf or not os.path.exists(pdf):
        print(f'clause: no PDF for part {part} of {spec} (part:page, the parts: '
              f'{", ".join(os.path.basename(p) for p in pdfs(spec))})')
        return 1
    print(f'== {os.path.relpath(pdf, SRS)} page {page} (pdftotext -layout)')
    res = subprocess.run(['pdftotext', '-layout', '-f', str(page), '-l', str(page), pdf, '-'],
                         capture_output=True, text=True)
    if res.returncode != 0:
        print(res.stderr.strip() or 'pdftotext failed (poppler: port/brew install poppler)')
        return 1
    print(res.stdout.rstrip())
    print()
    return 0


def grep(spec, pattern):
    rx = re.compile(pattern, re.I)
    n = 0
    for f in section_files(spec):
        lines = open(f).readlines()
        current = None
        for k, l in enumerate(lines):
            m = CLAUSE.match(l)
            if m:
                current = m.group(1)
            if rx.search(l):
                n += 1
                page = pages_after(lines, k)
                text = re.sub(r'<br>', ' | ', l.strip())
                print(f'{os.path.basename(f)}:{k + 1} [clause {current}, page {page}] {text[:160]}')
    print(f'-- {n} lines')
    return 0


def list_specs():
    for d in documents():
        n = sum(1 for f in section_files(d) for l in open(f) if CLAUSE.match(l))
        marks = sum(1 for f in section_files(d) for l in open(f) if PAGE.search(l))
        print(f'{d:24} {n:5} clause lines, {marks:4} page markers, '
              f'{", ".join(os.path.basename(p) for p in pdfs(d))}')
    return 0


def main(argv):
    if not argv or argv[0] in ('-h', '--help'):
        print(__doc__)
        return 0
    if argv[0] == '--specs':
        return list_specs()
    spec = DEFAULT
    if '--dmi' in argv:
        argv.remove('--dmi')
        spec = DMI
    if '--spec' in argv:
        k = argv.index('--spec')
        if k + 1 >= len(argv):
            print('clause: --spec needs a document')
            return 2
        spec = select(argv[k + 1])
        del argv[k:k + 2]
        if spec is None:
            return 2
    if not argv:
        print('clause: a clause number, --grep or --page')
        return 2
    if argv[0] == '--grep':
        return grep(spec, ' '.join(argv[1:]))
    if argv[0] == '--page':
        part, _, page = argv[1].rpartition(':')
        return print_page(spec, part or None, int(page))
    return print_clause(spec, argv[0], '--page' in argv)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
