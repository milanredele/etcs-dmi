#!/usr/bin/env python3
"""A clause of the specification by number, instead of reading a chapter.

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
  doc/SRS/tools/clause.py --dmi 8.3.2.1      the same in the DMI specification
                                             (ERA_ERTMS_015560), whose PDF is
                                             one file

The markdown under sections/ is a search aid converted from the PDFs: a
line that starts with a clause number opens the clause, "<!-- end of page
N -->" closes PDF page N. The numbers of tables and figures and the
columns of a table are only reliable on the PDF page: read it with --page
when a table matters (and mind that a cell's X is placed by character
column under its header in layout mode).
"""
import glob
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRS = os.path.dirname(HERE)
SPECS = {
    'subset026': {
        'sections': os.path.join(SRS, 'SUBSET-026_v400', 'sections'),
        'pdf': lambda chapter: os.path.join(SRS, 'SUBSET-026_v400', f'SUBSET-026-{chapter}_v400.pdf'),
    },
    'dmi': {
        'sections': os.path.join(SRS, 'ERA_ERTMS_015560_v400', 'sections'),
        'pdf': lambda chapter: next(iter(glob.glob(os.path.join(SRS, 'ERA_ERTMS_015560_v400', '*.pdf'))), None),
    },
}
CLAUSE = re.compile(r'^\s*(?:#+\s+)?(?:[-*]\s+)?(?:\*\*)?(\d+(?:\.\d+)+)(?:\*\*)?(?=[\s.:,)]|$)')
PAGE = re.compile(r'<!-- end of page (\d+) -->')


def section_files(spec):
    # the front matter and table of contents of a specification list every
    # clause number once more: left out
    return sorted(f for f in glob.glob(os.path.join(SPECS[spec]['sections'], '*.md'))
                  if 'toc' not in os.path.basename(f))


def chapter_of(number):
    return number.split('.')[0]


def pages_after(lines, start):
    """The PDF page of line `start`: the next page marker after it."""
    for k in range(start, len(lines)):
        m = PAGE.search(lines[k])
        if m:
            return int(m.group(1))
    return None


def find_clause(spec, number):
    """[(file, first, last, page)] of the clause: from its opening line to
    the line before the next clause that is not one of its subclauses."""
    hits = []
    chapter = chapter_of(number)
    for f in section_files(spec):
        base = os.path.basename(f)
        if spec == 'subset026' and not base.startswith(chapter.zfill(2) + '_'):
            continue
        lines = open(f).readlines()
        i = 0
        while i < len(lines):
            m = CLAUSE.match(lines[i])
            if m and m.group(1) == number:
                j = i + 1
                while j < len(lines):
                    m2 = CLAUSE.match(lines[j])
                    if m2 and not m2.group(1).startswith(number + '.') and m2.group(1) != number:
                        break
                    j += 1
                # trim trailing blank lines and page markers of the next page
                k = j
                while k > i + 1 and (not lines[k - 1].strip() or PAGE.search(lines[k - 1])):
                    k -= 1
                hits.append((f, i, k, pages_after(lines, i)))
                i = j
            else:
                i += 1
    return hits


def print_clause(spec, number, with_page):
    hits = find_clause(spec, number)
    if not hits:
        print(f'clause: {number} not found in {spec} (a table row or a footnote is only on the PDF page: --grep, --page)')
        return 1
    pages = []
    for f, first, last, page in hits:
        lines = open(f).readlines()
        where = f'PDF page {page}' if page else 'no page markers in this specification: --page unavailable'
        print(f'== {os.path.relpath(f, SRS)}:{first + 1}-{last} ({where})')
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
                if (f, p) not in pages:
                    pages.append((f, p))
    if with_page:
        for f, p in pages:
            print_page(spec, chapter_of(number), p)
    return 0


def print_page(spec, chapter, page):
    pdf = SPECS[spec]['pdf'](chapter)
    if not pdf or not os.path.exists(pdf):
        print(f'clause: no PDF for chapter {chapter}')
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


def main(argv):
    if not argv or argv[0] in ('-h', '--help'):
        print(__doc__)
        return 0
    spec = 'subset026'
    if '--dmi' in argv:
        argv.remove('--dmi')
        spec = 'dmi'
    if argv[0] == '--grep':
        return grep(spec, ' '.join(argv[1:]))
    if argv[0] == '--page':
        chapter, page = argv[1].split(':')
        return print_page(spec, chapter, int(page))
    return print_clause(spec, argv[0], '--page' in argv)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
