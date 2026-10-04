#!/usr/bin/env python3
"""The size of the subprogram bodies of the on-board (doc/EVC-PLAN.md §2,
"Size of subprograms"): a body under evc/ has at most LIMIT code lines of
its own, counted without comments, blank lines and the bodies nested in
it. Generated code (evc/language/) is not counted.

  test/tools/subprogram_size.py            the largest bodies
  test/tools/subprogram_size.py --check    fail on a body over the limit
  test/tools/subprogram_size.py DIR ...    other directories (report only)

A body that was over the limit when the rule was introduced is listed in
KNOWN with its size then: it may shrink (the entry is then to be lowered
or removed, --check says so) but not grow, and no new one may appear.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIMIT = 100

# (file, subprogram): code lines when the rule was introduced
KNOWN = {
    ('evc/evc_build_up.adb', 'T_Be_Reduced'): 153,
    ('evc/evc_track_conditions.adb', 'Evaluate'): 148,
    ('evc/evc_text_messages.adb', 'Evaluate'): 144,
    ('evc/evc_track_conditions.adb', 'External'): 131,
    ('evc/evc_driver_requests.adb', 'Receive'): 127,
    ('evc/evc_profile.adb', 'Build'): 126,
    ('evc/evc_position.adb', 'Evaluate'): 124,
    ('evc/evc_profiles.adb', 'Envelope'): 122,
    ('evc/evc_position.adb', 'Update'): 112,
}

START = re.compile(r'^(\s*)(?:overriding\s+)?(procedure|function)\s+("?[\w\.]+"?)',
                   re.I)


def is_code(line):
    s = line.strip()
    return bool(s) and not s.startswith('--')


def bodies(lines):
    """(name, first, last) of every subprogram body: 'procedure/function X
    ... is' matched with 'end X;' at the same indentation."""
    out = []
    for i, line in enumerate(lines):
        m = START.match(line)
        if not m:
            continue
        indent = len(m.group(1))
        name = m.group(3).strip('"')
        depth = 0
        kind = None
        j = i
        while j < len(lines) and j < i + 120 and kind is None:
            s = re.sub(r'--.*', '', lines[j])
            s = re.sub(r'"[^"]*"', '""', s)
            for tok in re.finditer(r'\(|\)|;|\bis\b', s):
                t = tok.group(0)
                if t == '(':
                    depth += 1
                elif t == ')':
                    depth -= 1
                elif depth == 0 and t == ';':
                    kind = 'decl'
                    break
                elif depth == 0 and t == 'is':
                    rest = s[tok.end():].strip()
                    nxt = rest or (lines[j + 1].strip() if j + 1 < len(lines) else '')
                    kind = ('decl' if re.match(r'(abstract|null|new|separate|\()', nxt)
                            else 'body')
                    break
            j += 1
        if kind != 'body':
            continue
        end = re.compile(r'^\s{%d}end\s+%s\s*;' % (indent, re.escape(name.split('.')[-1])),
                         re.I)
        k = j
        while k < len(lines) and not end.match(lines[k]):
            k += 1
        if k < len(lines):
            out.append((name, i, k))
    return out


def sizes(directory):
    result = []
    for path in sorted(glob.glob(os.path.join(ROOT, directory, '*.adb'))):
        lines = open(path, encoding='utf-8', errors='replace').read().split('\n')
        found = bodies(lines)
        for name, a, z in found:
            own = set(range(a, z + 1))
            for _, a2, z2 in found:
                if a2 > a and z2 < z:
                    own -= set(range(a2, z2 + 1))
            n = sum(1 for x in own if is_code(lines[x]))
            result.append((n, os.path.relpath(path, ROOT), name, a + 1))
    return result


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    check = '--check' in sys.argv
    dirs = args or ['evc']
    all_sizes = []
    for d in dirs:
        all_sizes += sizes(d)
    all_sizes.sort(reverse=True)
    if not check:
        for n, f, name, line in all_sizes[:25]:
            print('%5d  %-32s %s:%d' % (n, name, f, line))
        return 0
    bad = 0
    seen = set()
    for n, f, name, line in all_sizes:
        key = (f, name)
        allowed = KNOWN.get(key, LIMIT)
        if key in KNOWN:
            seen.add(key)
            if n <= LIMIT:
                print('subprogram_size: %s %s is now %d lines: remove it from KNOWN'
                      % (f, name, n))
                bad += 1
        if n > allowed:
            print('subprogram_size: %s:%d %s has %d code lines (limit %d)'
                  % (f, line, name, n, allowed))
            bad += 1
    for key in KNOWN:
        if key not in seen:
            print('subprogram_size: %s %s is in KNOWN but not found' % key)
            bad += 1
    over = sum(1 for n, *_ in all_sizes if n > LIMIT)
    print('subprogram_size --check: %d bodies, %d over %d lines (listed as known), '
          'largest %d: %s'
          % (len(all_sizes), over, LIMIT, all_sizes[0][0],
             'FAILED' if bad else 'ok'))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
