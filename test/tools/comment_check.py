#!/usr/bin/env python3
"""The comments of the on-board name no phase and no round.

  test/tools/comment_check.py            list every comment line of evc/
                                         naming a phase (E0 to E8) or a
                                         round, as file:line
  test/tools/comment_check.py --check    fail when there is one (the
                                         whole check runs this)
  test/tools/comment_check.py --comments-only <rev>
                                         fail when the working tree
                                         differs from <rev> under evc/ in
                                         any line that is not a comment
                                         (a cleanup of comments must
                                         change nothing else)

A phase is the plan's unit of work (doc/EVC-PLAN.md), a round the
agents': both are history, which git and the plan hold. A comment says
what a unit or a subprogram is for, where a clause leaves a choice what
was decided, and what is missing is said as what is missing ("in-fill
by radio is not taken"), not as the phase that will bring it. The
generated code under evc/language/ is left out (its generator is
test/tools/../evc/language/gen_language.py).
"""
import glob
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PHASE = re.compile(r'\b[Pp]hase\s+E[0-9]\b|\bE[0-9]\b|\b[Rr]ound\s+[0-9]+\b')
COMMENT = re.compile(r'^\s*--')


def files():
    return sorted(glob.glob(os.path.join(ROOT, 'evc', '*.ads'))
                  + glob.glob(os.path.join(ROOT, 'evc', '*.adb')))


def offenders():
    out = []
    for f in files():
        for n, line in enumerate(open(f), 1):
            if COMMENT.match(line) and PHASE.search(line):
                out.append((os.path.relpath(f, ROOT), n, line.rstrip()))
    return out


def comments_only(rev):
    """Every changed line under evc/ between rev and the working tree is
    a comment line (removed or added); returns the offending lines."""
    res = subprocess.run(['git', 'diff', '-U0', rev, '--', 'evc'],
                         cwd=ROOT, capture_output=True, text=True)
    bad = []
    f = ''
    for line in res.stdout.splitlines():
        if line.startswith('+++ ') or line.startswith('--- '):
            if line.startswith('+++ '):
                f = line[6:]
            continue
        if line.startswith('@@') or not line or line[0] not in '+-':
            continue
        body = line[1:]
        if body.strip() == '' or COMMENT.match(body):
            continue
        bad.append((f, line[:120]))
    return bad


def main(argv):
    if argv and argv[0] == '--comments-only':
        bad = comments_only(argv[1])
        for f, l in bad[:40]:
            print(f'{f}: {l}')
        if bad:
            print(f'comment_check: {len(bad)} changed lines under evc/ are not comments')
            return 1
        print('comment_check --comments-only: ok, comments only')
        return 0
    off = offenders()
    if argv and argv[0] == '--check':
        for f, n, l in off[:20]:
            print(f'{f}:{n}: {l.strip()[:100]}')
        if off:
            print(f'comment_check: {len(off)} comment lines name a phase or a round')
            return 1
        print('comment_check: ok')
        return 0
    for f, n, l in off:
        print(f'{f}:{n}: {l.strip()[:110]}')
    print(f'-- {len(off)} lines in {len({f for f, _, _ in off})} files')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
