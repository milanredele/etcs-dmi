#!/usr/bin/env python3
"""The backlog of doc/BACKLOG.csv: the open items that are neither a clause
of the coverage matrix nor a failure signature of the triage (runner gaps,
protocol items, decisions pending, tooling, harness).

    python3 test/tools/backlog.py            counts by kind and state
    python3 test/tools/backlog.py --check    validates the file (check.sh)
    python3 test/tools/backlog.py --open     lists the open items

Columns: id (B followed by three digits, unique), kind, state, since (the
round or date the item was written), text (one line, plain words; cite
clauses and signature ids so that the matrix and the triage can be
searched for it). An item is closed with state done or dropped and a
short reason appended to its text; it is never deleted, so the burndown
can count it.
"""

import csv
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATH = os.path.join(ROOT, 'doc', 'BACKLOG.csv')
KINDS = ('onboard', 'dmi', 'protocol', 'runner', 'decision', 'tooling', 'harness')
STATES = ('open', 'done', 'dropped')
ID = re.compile(r'^B\d{3}$')


def load():
    rows = []
    with open(PATH, newline='') as f:
        for line_no, row in enumerate(csv.reader(f), 1):
            if not row or row[0].startswith('#'):
                continue
            rows.append((line_no, row))
    return rows


def check(rows):
    errors = []
    ids = set()
    for line_no, row in rows:
        if len(row) != 5:
            errors.append(f'line {line_no}: {len(row)} fields, 5 expected')
            continue
        i, kind, state, since, text = row
        if not ID.match(i):
            errors.append(f'line {line_no}: id {i!r}')
        if i in ids:
            errors.append(f'line {line_no}: id {i} twice')
        ids.add(i)
        if kind not in KINDS:
            errors.append(f'line {line_no}: kind {kind!r}')
        if state not in STATES:
            errors.append(f'line {line_no}: state {state!r}')
        if not since.strip():
            errors.append(f'line {line_no}: since empty')
        if len(text.strip()) < 20:
            errors.append(f'line {line_no}: text too short')
        if text != text.strip():
            errors.append(f'line {line_no}: text with surrounding spaces')
    return errors


def main():
    rows = load()
    errors = check(rows)
    if '--check' in sys.argv:
        for e in errors:
            print('backlog:', e)
        print(f'backlog: {len(rows)} items, '
              f'{sum(1 for _, r in rows if len(r) == 5 and r[2] == "open")} open'
              + (', ok' if not errors else f', {len(errors)} errors'))
        return 1 if errors else 0
    if '--open' in sys.argv:
        for _, r in rows:
            if len(r) == 5 and r[2] == 'open':
                print(f'{r[0]} {r[1]:9} {r[3]:9} {r[4]}')
        return 0
    by_kind = Counter(r[1] for _, r in rows if len(r) == 5 and r[2] == 'open')
    by_state = Counter(r[2] for _, r in rows if len(r) == 5)
    print(f'{len(rows)} items; by state: ' + ', '.join(f'{k} {v}' for k, v in sorted(by_state.items())))
    print('open by kind: ' + ', '.join(f'{k} {v}' for k, v in sorted(by_kind.items())))
    for e in errors:
        print('error:', e)
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
