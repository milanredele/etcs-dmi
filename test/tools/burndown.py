#!/usr/bin/env python3
"""Burndown data of the on-board plan (doc/EVC-PLAN.md) from the git history.

Two series, one point per first-parent commit of the branch that changed
either file:

* the coverage matrix doc/TRACE-SUBSET-026.csv: per phase of the plan the
  clauses by status (todo, partial, done, n/a, deferred); the work left of
  a phase is todo + partial;
* the SUBSET-076 runner's baseline test/s076/baseline.csv: sequences
  passed, failed, blocked; the work left is failed + blocked;
* the backlog doc/BACKLOG.csv: items open, done, dropped.

The markers are read from the plan's headings: a phase outcome
("## N. Ex — ...: outcome (date)") and an E5 integration ("### E5
integration after the Nth round (date)").

    python3 test/tools/burndown.py [--out obj/burndown] [--rev master]

writes <out>/burndown.json and copies test/tools/burndown.html next to it,
so `python3 -m http.server -d obj/burndown` shows the chart locally; the
same pair is what the published page is made of.
"""

import argparse
import csv
import io
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MATRIX = 'doc/TRACE-SUBSET-026.csv'
BASELINE = 'test/s076/baseline.csv'
BACKLOG = 'doc/BACKLOG.csv'
PLAN = 'doc/EVC-PLAN.md'
PAGE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'burndown.html')

PHASES = ['E1', 'E2', 'E3', 'E4', 'E5', 'E6', 'E7']
STATUSES = ['todo', 'partial', 'done', 'n/a', 'deferred']

OUTCOME = re.compile(r'^## \d+\. (E\d) — [^:]*: outcome \((\d{4}-\d{2}-\d{2})\)')
ROUND = re.compile(r'^### E5 integration after the (\w+) round \((\d{4}-\d{2}-\d{2})\)')
ORDINALS = {'first': 1, 'second': 2, 'third': 3, 'fourth': 4, 'fifth': 5,
            'sixth': 6, 'seventh': 7, 'eighth': 8, 'ninth': 9, 'tenth': 10,
            'eleventh': 11, 'twelfth': 12, 'thirteenth': 13, 'fourteenth': 14,
            'fifteenth': 15, 'sixteenth': 16, 'seventeenth': 17,
            'eighteenth': 18, 'nineteenth': 19, 'twentieth': 20}


def git(*args):
    return subprocess.run(['git', *args], cwd=ROOT, check=True,
                          capture_output=True, text=True).stdout


def show(sha, path):
    r = subprocess.run(['git', 'show', f'{sha}:{path}'], cwd=ROOT,
                       capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None


def matrix_counts(text):
    counts = {p: {s: 0 for s in STATUSES} for p in PHASES}
    for row in csv.DictReader(io.StringIO(text)):
        p, s = row.get('phase'), row.get('status')
        if p in counts and s in STATUSES:
            counts[p][s] += 1
    return counts


def baseline_counts(text):
    counts = {'passed': 0, 'failed': 0, 'blocked': 0}
    for line in text.splitlines():
        if not line or line.startswith('#'):
            continue
        parts = line.split(',')
        # The three fixtures of test/s076-sample/runner are recorded too; the
        # chart counts the SUBSET-076 corpus alone, as the summary line does.
        if len(parts) >= 2 and parts[1] in counts and parts[0].startswith('Subset-076'):
            counts[parts[1]] += 1
    counts['total'] = sum(counts.values())
    return counts


def backlog_counts(text):
    counts = {'open': 0, 'done': 0, 'dropped': 0}
    for row in csv.reader(io.StringIO(text)):
        if len(row) == 5 and not row[0].startswith('#') and row[2] in counts:
            counts[row[2]] += 1
    return counts


def markers(plan_text):
    out = []
    for line in plan_text.splitlines():
        m = OUTCOME.match(line)
        if m:
            out.append({'date': m.group(2), 'label': f'{m.group(1)} closed',
                        'kind': 'phase'})
            continue
        m = ROUND.match(line)
        if m:
            n = ORDINALS.get(m.group(1).lower())
            label = f'round {n}' if n else f'{m.group(1)} round'
            out.append({'date': m.group(2), 'label': label, 'kind': 'round'})
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--out', default=os.path.join(ROOT, 'obj', 'burndown'))
    ap.add_argument('--rev', default='HEAD')
    a = ap.parse_args()

    log = git('log', '--first-parent', '--reverse', '--format=%H %ct %ad %s',
              '--date=short', a.rev, '--', MATRIX, BASELINE, BACKLOG)
    points = []
    last_matrix = last_baseline = last_backlog = None
    for line in log.splitlines():
        sha, ts, date, subject = line.split(' ', 3)
        mtext = show(sha, MATRIX)
        btext = show(sha, BASELINE)
        if mtext is not None:
            last_matrix = matrix_counts(mtext)
        if btext is not None:
            last_baseline = baseline_counts(btext)
        ktext = show(sha, BACKLOG)
        if ktext is not None:
            last_backlog = backlog_counts(ktext)
        points.append({'sha': sha[:7], 'time': int(ts), 'date': date,
                       'subject': subject, 'matrix': last_matrix,
                       's076': last_baseline, 'backlog': last_backlog})

    plan = show(a.rev, PLAN) or ''
    data = {'generated_at': git('log', '-1', '--format=%cI', a.rev).strip(),
            'head': git('rev-parse', '--short', a.rev).strip(),
            'phases': PHASES, 'statuses': STATUSES,
            'markers': markers(plan), 'points': points}

    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, 'burndown.json'), 'w') as f:
        json.dump(data, f, indent=1)
    with open(PAGE) as f, open(os.path.join(a.out, 'index.html'), 'w') as g:
        # The published page gets its skeleton from the host; the local copy needs one.
        g.write('<!doctype html>\n<html lang="en"><head><meta charset="utf-8">\n'
                '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
                '</head><body style="margin:0">\n' + f.read() + '</body></html>\n')
    last = points[-1]
    left = sum(last['matrix'][p]['todo'] + last['matrix'][p]['partial'] for p in PHASES)
    print(f"{len(points)} points, head {data['head']}; clauses left {left}, "
          f"sequences left {last['s076']['failed'] + last['s076']['blocked']} "
          f"of {last['s076']['total']}; {a.out}/burndown.json")
    return 0


if __name__ == '__main__':
    sys.exit(main())
