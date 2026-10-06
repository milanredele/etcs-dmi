#!/usr/bin/env python3
"""An outline of an Ada unit, for reading it piecewise instead of whole.

  test/tools/outline.py evc/evc_sessions.adb          every subprogram: lines, profile
  test/tools/outline.py evc_sessions                  spec and body of the unit
  test/tools/outline.py evc_sessions Evaluate         that subprogram in full: the
                                                      declaration with its contract
                                                      (spec) and the body, with the
                                                      comment that heads each
  test/tools/outline.py --refs Position_To_Delete     every use outside its own
                                                      declaration, as file:line
  test/tools/outline.py --refs Evaluate --in evc/     limit the search

A unit is given by file name or by Ada name (evc_sessions, EVC_Sessions,
EVC_Sessions.Mission); the search roots are evc/, common/, sim/, test/src/.
The outline shows for each declaration its first and last line, so that a
following `sed -n A,Bp` is exact, and the first line of each aspect
(Global, Depends, Pre, Post, Contract_Cases, Refined_*).

The parser is the one of subprogram_size.py: a declaration starts at
`procedure` / `function` and ends at the matching `;` (a spec) or at the
`end Name;` at the same indentation (a body). Nested bodies are listed
under their parent, with deeper indentation.
"""
import glob
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROOTS = ['evc', 'common', 'sim', 'test/src']
START = re.compile(r'^(\s*)(?:overriding\s+)?(procedure|function)\s+("?[\w\.]+"?)', re.I)
ASPECT = re.compile(r'\b(Global|Depends|Pre|Post|Contract_Cases|Refined_Global|Refined_Depends|'
                    r'Refined_Post|Refined_State|Abstract_State|Initializes|Convention|Import|'
                    r'Inline|Ghost|SPARK_Mode|Annotate)\s*=>', re.I)


def unit_files(name):
    """The files of a unit given as path, file name or Ada name."""
    if os.path.exists(name):
        return [name]
    base = name.lower().replace('.', '-')
    base = re.sub(r'\.ad[sb]$', '', base)
    out = []
    for r in ROOTS:
        for ext in ('ads', 'adb'):
            p = os.path.join(ROOT, r, base + '.' + ext)
            if os.path.exists(p):
                out.append(os.path.relpath(p, ROOT))
    return out


def declarations(lines):
    """[(indent, kind, name, first, last, is_body)] of every subprogram
    declaration; a body ends at its `end Name;` at the same indentation, a
    spec at the `;` that closes it (depth 0, outside parentheses)."""
    out = []
    for i, line in enumerate(lines):
        m = START.match(line)
        if not m:
            continue
        indent = len(m.group(1))
        name = m.group(3).strip('"')
        depth = 0
        is_body = None
        expr = False
        j = i
        while j < len(lines) and j < i + 200 and is_body is None:
            s = re.sub(r'--.*', '', lines[j])
            s = re.sub(r'"[^"]*"', '""', s)
            for tok in re.finditer(r'\(|\)|;|\bis\b', s):
                t = tok.group(0)
                if t == '(':
                    depth += 1
                elif t == ')':
                    depth -= 1
                elif depth == 0 and t == ';':
                    is_body = False
                    break
                elif depth == 0 and t == 'is':
                    rest = s[tok.end():]
                    if not rest.strip():
                        # "is" at the end of the line: look at the next code line
                        k = j + 1
                        while k < len(lines) and not re.sub(r'--.*', '', lines[k]).strip():
                            k += 1
                        rest = re.sub(r'--.*', '', lines[k]) if k < len(lines) else ''
                    # "is (expr)" expression function, "is new", "is abstract": a spec
                    if re.match(r'\s*(\(|new\b|abstract\b|null\b|separate\b)', rest):
                        is_body = False
                        expr = True
                    else:
                        is_body = True
                    break
            j += 1
        last = j - 1
        if is_body is False and expr:
            # an expression function or an instance ends at its ';' at depth 0
            depth = 0
            for k in range(i, min(len(lines), i + 200)):
                s = re.sub(r'--.*', '', lines[k])
                s = re.sub(r'"[^"]*"', '""', s)
                stop = False
                for tok in re.finditer(r'\(|\)|;', s):
                    if tok.group(0) == '(':
                        depth += 1
                    elif tok.group(0) == ')':
                        depth -= 1
                    elif depth == 0:
                        last = k
                        stop = True
                        break
                if stop:
                    break
        if is_body:
            end = re.compile(r'^' + ' ' * indent + r'end\s+"?' + re.escape(name) + r'"?\s*;', re.I)
            for k in range(j, len(lines)):
                if end.match(lines[k]):
                    last = k
                    break
        elif is_body is False:
            # the spec may continue with aspects until the ';' found above
            last = j - 1
        out.append((indent, m.group(2).lower(), name, i, last, bool(is_body), expr))
    return out


def heading(lines, first):
    """The comment block right above a declaration (the clause numbers)."""
    k = first - 1
    block = []
    while k >= 0 and lines[k].strip().startswith('--'):
        block.insert(0, lines[k].rstrip('\n'))
        k -= 1
    return block


def profile(lines, first, last):
    """The declaration without its body: up to the `is` or `;`."""
    out = []
    for k in range(first, last + 1):
        s = lines[k].rstrip('\n')
        out.append(s)
        t = re.sub(r'--.*', '', s)
        if re.search(r'\bis\b\s*$', t) or t.rstrip().endswith(';'):
            if not re.search(r'\bwith\b', ''.join(out)) or t.rstrip().endswith(';'):
                break
    return out


def outline(path):
    lines = open(os.path.join(ROOT, path)).readlines()
    print(f'== {path} ({len(lines)} lines)')
    for indent, kind, name, first, last, is_body, expr in declarations(lines):
        head = lines[first].strip()
        # the parameter profile on one line
        prof = ' '.join(l.strip() for l in lines[first:min(last + 1, first + 12)])
        prof = re.sub(r'\s+', ' ', prof)
        prof = re.split(r'\s+(?:is\b|with\b|;)', prof)[0]
        tag = 'body' if is_body else ('expr' if expr else 'spec')
        print(f'{" " * (indent // 3)}{first + 1:5d}-{last + 1:<5d} {tag} {prof}')
        for k in range(first, last + 1):
            a = ASPECT.search(lines[k])
            if a and not is_body or (a and k < first + 40 and 'Refined' in a.group(1)):
                print(f'{" " * (indent // 3)}            {lines[k].strip()[:100]}')


def show(path, name):
    lines = open(os.path.join(ROOT, path)).readlines()
    found = False
    for indent, kind, n, first, last, is_body, expr in declarations(lines):
        if n.lower() != name.lower():
            continue
        found = True
        print(f'== {path}:{first + 1}-{last + 1} ({"body" if is_body else "spec"})')
        for l in heading(lines, first):
            print(l)
        for k in range(first, last + 1):
            print(f'{k + 1:5d}  {lines[k].rstrip()}')
        print()
    return found


def refs(name, roots):
    pat = r'\b' + re.escape(name) + r'\b'
    cmd = ['grep', '-rn', '-E', pat, '--include=*.ads', '--include=*.adb'] + roots
    res = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    decl = re.compile(r'^\s*(overriding\s+)?(procedure|function|package|type|subtype)\s+' + pat, re.I)
    endl = re.compile(r'^\s*end\s+' + pat, re.I)
    n = 0
    for line in res.stdout.splitlines():
        f, ln, text = line.split(':', 2)
        if decl.match(text) or endl.match(text) or text.strip().startswith('--'):
            continue
        n += 1
        print(f'{f}:{ln}: {text.strip()[:110]}')
    print(f'-- {n} uses of {name} (declarations, end lines and comments left out)')


def main(argv):
    if not argv or argv[0] in ('-h', '--help'):
        print(__doc__)
        return 0
    if argv[0] == '--refs':
        roots = ROOTS
        if '--in' in argv:
            roots = [argv[argv.index('--in') + 1]]
        refs(argv[1], roots)
        return 0
    files = unit_files(argv[0])
    if not files:
        print(f'outline: no unit {argv[0]} under {", ".join(ROOTS)}', file=sys.stderr)
        return 1
    if len(argv) > 1:
        ok = False
        for f in files:
            ok = show(f, argv[1]) or ok
        if not ok:
            print(f'outline: no subprogram {argv[1]} in {", ".join(files)}', file=sys.stderr)
            return 1
        return 0
    for f in files:
        outline(f)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
