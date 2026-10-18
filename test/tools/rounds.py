#!/usr/bin/env python3
"""The process statistics of the agent rounds: doc/ROUNDS.csv, one row per
agent, the mechanical columns measured from the agent's transcript, the
judgement columns filled at integration by hand.

  rounds.py measure <transcript.jsonl ...> [--csv doc/ROUNDS.csv]
      reads each transcript (the JSONL a subagent writes; the Claude Code
      session keeps them under ~/.claude/projects/<project>/<session>/
      subagents/agent-<id>.jsonl) and merges one row per agent id into the
      CSV: the package and round from the launch prompt, the round briefs
      and the plan, the budget from the prompt or the package brief, the
      requests, duration, final context and cost from the usage records,
      the tool mix from the tool_use blocks (and inside Bash the runs of
      outline.py, clause.py, grep and sed -n, each also counted on the
      source trees alone, the commits, the proofs, the runner and the
      whole check), the agent's own running tally (the ordinal at the
      start of a Bash call's description, since round 30), the report's
      premise mentions. A row's
      judgement columns are kept as they are; a measured column is always
      rewritten.
  rounds.py report [--last N] [--csv ...]
      the aggregates: per kind and per round the calls against the budget,
      the cost, the tool mix, the premise survival and the conversion of
      items where the judgement columns are filled.
  rounds.py --check [--csv ...]
      the file is well formed: the header, unique agent ids, the kinds and
      states, numbers where numbers belong; part of test/check.sh.

Judgement columns (hand-filled at integration): items (assigned), done,
dropped, left, premises (stated in the brief), premises_wrong, moved (the
runner's passed delta of the branch), regressions (explained, in the
branch's run), backlog_added, outside (edits outside the agent's units),
conflicts (merge conflicts the coordinator resolved by hand), done_list
(y / n / partial), note.

Cost: the public rates of the model named in the transcript (opus 5 / 25 /
6.25 / 0.5, sonnet 3 / 15 / 3.75 / 0.3, haiku 1 / 5 / 1.25 / 0.1 USD per
million tokens of input, output, cache write, cache read), one usage per
message id.
"""
import argparse
import csv
import glob
import json
import os
import re
import sys
from datetime import datetime

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CSV = os.path.join(ROOT, 'doc', 'ROUNDS.csv')
PLAN = os.path.join(ROOT, 'doc', 'EVC-PLAN.md')
BRIEFS = os.path.expanduser(
    '~/.claude/projects/-Users-milan-GitHub-etcs-dmi/briefs')

MEASURED = ['agent', 'date', 'round', 'package', 'kind', 'model', 'agent_type',
            'first_k', 'budget', 'calls',
            'requests', 'minutes', 'context_k', 'cost_usd',
            'bash', 'edit', 'write', 'read', 'other',
            'outline', 'outline_decl', 'clause', 'grep', 'grep_src', 'sed', 'sed_src',
            'commits', 'proofs', 'runner_runs', 'checks', 'tally',
            'report_chars', 'premise_mentions', 'premise_flags']
JUDGED = ['items', 'done', 'dropped', 'left', 'premises', 'premises_wrong',
          'moved', 'regressions', 'backlog_added', 'outside', 'conflicts',
          'done_list', 'note']
COLUMNS = MEASURED + JUDGED
# kind is measured once (from the package name) and then kept if filled
KEPT_IF_FILLED = {'kind', 'budget', 'round'}
KINDS = {'onboard', 'runner', 'analysis', 'dmi', 'tooling', 'prep', 'other'}
# the agents named in prose before the package folders existed
ALIASES = {
    'e5/acceptance-of-radio-information-and-authority-leftovers': 'e5/authority-4',
    'e5/bench-and-sequences-round-2': 'e5/bench-2',
    'e5/session-and-link-phase-3': 'e5/session-4',
}
# the E5 rounds before the round briefs (the plan's first integration
# heading covers the first three rounds together)
EARLY_ROUNDS = {
    'e5/bench-1': 1, 'e5/authority-1': 1, 'e5/authority-2': 1,
    'e5/session-1': 1, 'e5/session-1b': 1, 'e5/session-2': 1,
    'e5/authority-3': 2, 'e5/session-3': 2, 'e5/bench-2': 2,
    'e5/authority-4': 3, 'e5/session-4': 3,
}
PREP_PREFIXES = ('refactor/', 'perf/', 'fix/', 'chore/', 'e5prep/')
# USD per million tokens: input, output, cache write, cache read, by the
# model's name prefix (the opus rates for an unknown model)
RATES_BY_MODEL = [
    ('haiku', (1.0, 5.0, 1.25, 0.1)),
    ('sonnet', (3.0, 15.0, 3.75, 0.3)),
    ('opus', (5.0, 25.0, 6.25, 0.5)),
]


def rates_for(model):
    for prefix, r in RATES_BY_MODEL:
        if model.startswith(prefix):
            return dict(zip(['input_tokens', 'output_tokens',
                             'cache_creation_input_tokens',
                             'cache_read_input_tokens'], r))
    return rates_for('opus')
ORDINALS = ['first', 'second', 'third', 'fourth', 'fifth', 'sixth',
            'seventh', 'eighth', 'ninth', 'tenth', 'eleventh', 'twelfth',
            'thirteenth', 'fourteenth', 'fifteenth', 'sixteenth',
            'seventeenth', 'eighteenth', 'nineteenth', 'twentieth']
TENS = {'twenty': 20, 'thirty': 30, 'forty': 40}


def ordinal(word):
    word = word.lower()
    if word in ORDINALS:
        return ORDINALS.index(word) + 1
    m = re.match(r'(twenty|thirty|forty)(?:-(\w+))?$', word)
    if m:
        n = TENS[m.group(1)]
        if m.group(2):
            n += ORDINALS.index(m.group(2)) + 1
        return n
    return None


# --- the maps from the briefs and the plan -------------------------------

def round_briefs():
    """package -> round number, from the agent lists of roundNN.md."""
    out = {}
    for path in glob.glob(os.path.join(BRIEFS, '*', 'round*.md')):
        m = re.search(r'round(\d+)\.md$', path)
        if not m:
            continue
        with open(path) as f:
            text = f.read()
        for pkg in set(re.findall(r'\be[0-9]/[a-z0-9-]+', text)):
            out.setdefault(pkg, int(m.group(1)))
    return out


def plan_rounds():
    """package -> round number, from the plan: a package heading followed by
    an 'E5 integration after the Nth round' heading."""
    out = {}
    if not os.path.exists(PLAN):
        return out
    pending = []
    with open(PLAN) as f:
        for line in f:
            if not line.startswith('#'):
                continue
            pkgs = re.findall(r'\((e[0-9]/[a-z0-9-]+(?:, e[0-9]/[a-z0-9-]+)*),\s*20\d\d-', line)
            if pkgs:
                for p in pkgs[0].split(', '):
                    pending.append(p)
            m = re.search(r'integration after the ([a-z-]+) round', line)
            if m:
                n = ordinal(m.group(1))
                if n:
                    for p in pending:
                        out.setdefault(p, n)
                pending = []
    return out


def brief_budget(pkg):
    name = pkg.split('/', 1)[-1]
    for path in glob.glob(os.path.join(BRIEFS, '*', name, 'brief.md')):
        with open(path) as f:
            m = re.search(r'Budget: (\d+) tool calls', f.read())
            if m:
                return int(m.group(1))
    return ''


def round_starts():
    """[(start datetime UTC, round number)] from the roundNN-start.txt stamps."""
    out = []
    for path in glob.glob(os.path.join(BRIEFS, '*', 'round*-start.txt')):
        m = re.search(r'round(\d+)-start\.txt$', path)
        with open(path) as f:
            stamp = f.read().strip()
        if not m or not stamp:
            continue
        try:
            t = datetime.fromisoformat(stamp)
        except ValueError:
            continue
        if t.tzinfo is None:  # the early stamps are local time (UTC+2)
            from datetime import timedelta, timezone
            t = t.replace(tzinfo=timezone(timedelta(hours=2)))
        out.append((t, int(m.group(1))))
    out.sort()
    return out


def round_by_date(t, starts):
    """the latest round started before t, if it started within a day."""
    best = ''
    for start, n in starts:
        if start <= t and (t - start).total_seconds() < 36 * 3600:
            best = n
    return best


def kind_of(pkg):
    name = pkg.split('/', 1)[-1] if '/' in pkg else pkg
    if pkg.startswith('tools/'):
        return 'tooling'
    if pkg.startswith(PREP_PREFIXES) or pkg == 'e5/joint':
        return 'prep'
    if pkg.startswith('dmi/') or re.match(r'p[0-9]/', pkg):
        return 'dmi'
    if re.match(r'(runner|bench|curves?|factors|s076)', name):
        return 'runner'
    if re.match(r'(untraced|bookkeeping|retriage|runner-e5-group)', name):
        return 'analysis'
    if '/' in pkg:
        return 'onboard'
    return 'other'


# --- the transcript -------------------------------------------------------

PROMPT_PACKAGE = [
    re.compile(r'checkout -b ([a-z0-9]+/[a-z0-9-]+)'),
    re.compile(r'You are the ([a-z0-9]+/[a-z0-9-]+) agent'),
    re.compile(r'[Ww]ork on branch `?([a-z0-9]+/[a-z0-9-]+)'),
    re.compile(r'[Bb]ranch:? `([a-z0-9]+/[a-z0-9-]+)`'),
    re.compile(r'package ([a-z0-9]+/[a-z0-9-]+)'),
    re.compile(r'/(e[0-9])/([a-z0-9-]+)/brief\.md'),
]


# a Bash command that reads a source file (not a sequence, a csv or the
# specification's markdown): the Ada source trees and their extensions
SOURCE_PATH = re.compile(r'(^|[\s/"\'])(evc|sim|dmi|common|ports|test/src)/|\.ad[sb]\b')


def text_of(content):
    if isinstance(content, str):
        return content
    return ' '.join(c.get('text', '') for c in content
                    if isinstance(c, dict) and c.get('type') == 'text')


def measure(path, briefs_map, plan_map, starts):
    agent = re.sub(r'^agent-|\.jsonl$|\.output$', '', os.path.basename(path))
    prompt = None
    seen = {}
    first_ts = last_ts = None
    last_ctx = 0
    first_ctx = None
    model = ''
    agent_type = ''
    meta_path = re.sub(r'\.(jsonl|output)$', '.meta.json', os.path.realpath(path))
    if os.path.exists(meta_path):
        try:
            with open(meta_path) as f:
                agent_type = json.load(f).get('agentType', '')
        except ValueError:
            pass
    tools = {}
    bash_cmds = []
    bash_descs = []
    handback = None
    last_text = ''
    with open(path) as f:
        for line in f:
            try:
                o = json.loads(line)
            except ValueError:
                continue
            ts = o.get('timestamp')
            if ts:
                t = datetime.fromisoformat(ts.replace('Z', '+00:00'))
                first_ts = first_ts or t
                last_ts = t
            if o.get('type') == 'user' and prompt is None:
                prompt = text_of(o.get('message', {}).get('content', ''))
            if o.get('type') != 'assistant':
                continue
            m = o.get('message') or {}
            if m.get('id') and m.get('usage'):
                seen[m['id']] = m['usage']
                model = model or re.sub(r'^claude-', '', str(m.get('model', '')))
                if first_ctx is None:
                    u = m['usage']
                    first_ctx = (u.get('input_tokens', 0) + u.get('cache_creation_input_tokens', 0)
                                 + u.get('cache_read_input_tokens', 0))
            for c in m.get('content', []) or []:
                if not isinstance(c, dict):
                    continue
                if c.get('type') == 'text' and c['text'].strip():
                    last_text = c['text']
                if c.get('type') == 'tool_use':
                    name = c.get('name', '?')
                    inp = c.get('input') or {}
                    if name == 'SubagentHandback':
                        handback = str(inp.get('message', ''))
                        continue
                    tools[name] = tools.get(name, 0) + 1
                    if name == 'Bash':
                        bash_cmds.append(str(inp.get('command', '')))
                        bash_descs.append(str(inp.get('description', '')))
    prompt = prompt or ''
    pkg = ''
    for rx in PROMPT_PACKAGE:
        mm = rx.search(prompt)
        if mm:
            pkg = '/'.join(mm.groups())
            break
    if not pkg:
        mm = re.search(r'"([^"]{3,60})" agent of phase (E\d)', prompt)
        if mm:
            pkg = mm.group(2).lower() + '/' + re.sub(r'[^a-z0-9]+', '-', mm.group(1).lower()).strip('-')
    pkg = ALIASES.get(pkg, pkg)
    # a brief folder named without its phase: the round brief knows the branch
    if pkg and pkg not in briefs_map and '/' in pkg:
        name = pkg.split('/', 1)[1]
        for known in briefs_map:
            if known.split('/', 1)[1] == name:
                pkg = known
                break
    rnd = ''
    mm = re.search(r'agent of round (\d+)', prompt)
    if mm:
        rnd = int(mm.group(1))
    elif pkg in EARLY_ROUNDS:
        rnd = EARLY_ROUNDS[pkg]
    elif pkg in briefs_map:
        rnd = briefs_map[pkg]
    elif pkg in plan_map:
        rnd = plan_map[pkg]
    elif pkg.startswith(PREP_PREFIXES) or pkg == 'e5/joint':
        rnd = 'prep'
    elif re.match(r'e[0-4]/', pkg) and first_ts and first_ts.date().isoformat() < '2026-10-05':
        rnd = pkg[:2].upper()
    elif pkg.startswith(('e4/', 'e5/', 's076/')) and first_ts:
        rnd = round_by_date(first_ts, starts)
    budget = ''
    nums = [int(x) for x in re.findall(r'(\d+) tool calls', prompt)]
    if nums:
        budget = max(nums)
    elif pkg:
        budget = brief_budget(pkg)
    cost = 0.0
    rates = rates_for(model)
    for u in seen.values():
        for k, rate in rates.items():
            cost += u.get(k, 0) * rate / 1e6
        last_ctx = (u.get('input_tokens', 0) + u.get('cache_creation_input_tokens', 0)
                    + u.get('cache_read_input_tokens', 0))
    minutes = round((last_ts - first_ts).total_seconds() / 60) if first_ts else ''
    report = handback if handback is not None else last_text
    flags = len(re.findall(
        r'premise[^.\n]{0,60}?(?:wrong|not hold|false|half right|did not hold)'
        r'|(?:wrong|false)[^.\n]{0,40}?premise', report, re.I))
    row = {
        'agent': agent,
        'date': first_ts.date().isoformat() if first_ts else '',
        'round': rnd,
        'package': pkg or ('other: ' + re.sub(r'\s+', ' ', prompt[:50]).strip()),
        'kind': kind_of(pkg) if pkg else 'other',
        'model': model,
        'agent_type': agent_type,
        'first_k': round((first_ctx or 0) / 1000),
        'budget': budget,
        'calls': sum(tools.values()),
        'requests': len(seen),
        'minutes': minutes,
        'context_k': round(last_ctx / 1000),
        'cost_usd': round(cost, 2),
        'bash': tools.get('Bash', 0),
        'edit': tools.get('Edit', 0),
        'write': tools.get('Write', 0),
        'read': tools.get('Read', 0),
        'other': sum(v for k, v in tools.items() if k not in ('Bash', 'Edit', 'Write', 'Read')),
        'outline': sum(1 for c in bash_cmds if 'outline.py' in c and '--decl' not in c),
        'outline_decl': sum(1 for c in bash_cmds if 'outline.py' in c and '--decl' in c),
        'clause': sum(1 for c in bash_cmds if 'clause.py' in c),
        'grep': sum(1 for c in bash_cmds if re.search(r'\bgrep\b', c)),
        'grep_src': sum(1 for c in bash_cmds if re.search(r'\bgrep\b', c) and SOURCE_PATH.search(c)),
        'sed': sum(1 for c in bash_cmds if re.search(r'\bsed -n\b', c)),
        'sed_src': sum(1 for c in bash_cmds if re.search(r'\bsed -n\b', c) and SOURCE_PATH.search(c)),
        'commits': sum(1 for c in bash_cmds if 'git commit' in c),
        'proofs': sum(1 for c in bash_cmds if 'prove.sh' in c or 'gnatprove' in c),
        'runner_runs': sum(1 for c in bash_cmds if 'evc_s076_run' in c),
        'checks': sum(1 for c in bash_cmds if 'check.sh' in c),
        'tally': max([int(m.group(1)) for d in bash_descs for m in [re.match(r'\s*(\d+)\s*[:.)-]', d)] if m] or [0]),
        'report_chars': len(report),
        'premise_mentions': len(re.findall(r'premise', report, re.I)),
        'premise_flags': flags,
    }
    return row


# --- the file -----------------------------------------------------------

def load(path):
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path, newline='') as f:
        for r in csv.DictReader(f):
            rows.append(r)
    return rows


def save(path, rows):
    def key(r):
        rnd = r.get('round', '')
        try:
            n = int(rnd)
            return (1, n, r.get('date', ''), r.get('package', ''))
        except ValueError:
            return (0, 0, r.get('date', ''), r.get('package', ''))
    rows.sort(key=key)
    with open(path, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator='\n')
        w.writeheader()
        for r in rows:
            w.writerow({c: r.get(c, '') for c in COLUMNS})


def cmd_measure(args):
    rows = load(args.csv)
    by_id = {r['agent']: r for r in rows}
    briefs_map = round_briefs()
    plan_map = plan_rounds()
    starts = round_starts()
    n_new = n_upd = 0
    for path in args.transcripts:
        row = measure(path, briefs_map, plan_map, starts)
        old = by_id.get(row['agent'])
        if old is None:
            by_id[row['agent']] = {**{c: '' for c in COLUMNS}, **row}
            n_new += 1
        else:
            for c in MEASURED:
                if c in KEPT_IF_FILLED and str(old.get(c, '')).strip():
                    continue
                old[c] = row[c]
            n_upd += 1
    save(args.csv, list(by_id.values()))
    print(f'rounds: {n_new} rows added, {n_upd} updated, {len(by_id)} in {os.path.relpath(args.csv, ROOT)}')


def check(path):
    errors = []
    if not os.path.exists(path):
        return [f'{path}: missing']
    with open(path, newline='') as f:
        reader = csv.DictReader(f)
        if reader.fieldnames != COLUMNS:
            errors.append('header differs from the tool\'s columns')
        ids = set()
        for i, r in enumerate(reader, 2):
            a = r.get('agent', '')
            if not re.match(r'^[0-9a-f]{8,}$', a):
                errors.append(f'line {i}: agent id "{a}"')
            if a in ids:
                errors.append(f'line {i}: duplicate agent {a}')
            ids.add(a)
            if r.get('kind') not in KINDS:
                errors.append(f'line {i}: kind "{r.get("kind")}"')
            for c in ['first_k', 'budget', 'calls', 'requests', 'minutes', 'context_k',
                      'bash', 'edit', 'write', 'read', 'other', 'outline',
                      'outline_decl', 'clause', 'grep', 'grep_src', 'sed', 'sed_src', 'commits',
                      'proofs', 'runner_runs', 'checks', 'tally', 'report_chars',
                      'premise_mentions', 'premise_flags', 'items', 'done',
                      'dropped', 'left', 'premises', 'premises_wrong',
                      'regressions', 'backlog_added', 'outside', 'conflicts']:
                v = r.get(c, '')
                if v != '' and not re.match(r'^-?\d+$', v):
                    errors.append(f'line {i}: {c} "{v}" is not a whole number')
            for c in ['cost_usd']:
                v = r.get(c, '')
                if v != '' and not re.match(r'^-?\d+(\.\d+)?$', v):
                    errors.append(f'line {i}: {c} "{v}" is not a number')
            v = r.get('moved', '')
            if v != '' and not re.match(r'^[-+]?\d+$', v):
                errors.append(f'line {i}: moved "{v}" is not a signed whole number')
            if r.get('done_list', '') not in ('', 'y', 'n', 'partial'):
                errors.append(f'line {i}: done_list "{r.get("done_list")}"')
            if r.get('premises') and r.get('premises_wrong'):
                if int(r['premises_wrong']) > int(r['premises']):
                    errors.append(f'line {i}: more premises wrong than stated')
    return errors


def cmd_check(args):
    errors = check(args.csv)
    rows = load(args.csv)
    judged = sum(1 for r in rows if r.get('items'))
    if errors:
        for e in errors[:20]:
            print('rounds:', e)
        print(f'rounds: {len(errors)} errors')
        return 1
    print(f'rounds: {len(rows)} agents, {judged} with judgement columns, ok')
    return 0


# --- the report ---------------------------------------------------------

def num(v, default=0.0):
    try:
        return float(v)
    except (TypeError, ValueError):
        return default


def mean(xs):
    xs = [x for x in xs if x is not None]
    return sum(xs) / len(xs) if xs else 0.0


def cmd_report(args):
    rows = load(args.csv)
    numbered = [r for r in rows if re.match(r'^\d+$', str(r.get('round', '')))]
    if args.last and numbered:
        last = sorted({int(r['round']) for r in numbered})[-args.last:]
        numbered = [r for r in numbered if int(r['round']) in last]
    print(f'{len(rows)} agents in all, {len(numbered)} in the numbered rounds reported')
    print()
    print('Per kind (the numbered rounds): agents, mean calls, mean budget, over budget, mean cost, cost per agent-hour, tool mix')
    for kind in sorted({r['kind'] for r in numbered}):
        rs = [r for r in numbered if r['kind'] == kind]
        with_budget = [r for r in rs if r.get('budget')]
        over = sum(1 for r in with_budget if num(r['calls']) > num(r['budget']))
        calls = mean([num(r['calls']) for r in rs])
        bash = sum(num(r['bash']) for r in rs)
        edits = sum(num(r['edit']) + num(r['write']) for r in rs)
        reads = sum(num(r['read']) for r in rs)
        total = max(1.0, bash + edits + reads + sum(num(r['other']) for r in rs))
        mins = sum(num(r['minutes']) for r in rs)
        cost = sum(num(r['cost_usd']) for r in rs)
        print(f'  {kind:9s} {len(rs):3d}  calls {calls:5.1f}  budget {mean([num(r["budget"]) for r in with_budget]):5.1f}'
              f'  over {over}/{len(with_budget)}  cost {cost / max(1, len(rs)):5.1f}'
              f'  {cost / max(1e-9, mins / 60):5.1f}/h'
              f'  bash {bash / total:4.0%} edit+write {edits / total:4.0%} read {reads / total:4.0%}')
    print()
    print('Per model and agent type (all agents): agents, initial context, mean calls, mean final context, mean cost')
    for key in sorted({(r.get('model', ''), r.get('agent_type', '')) for r in rows}):
        rs = [r for r in rows if (r.get('model', ''), r.get('agent_type', '')) == key]
        print(f'  {key[0] or "?":12s} {key[1] or "?":16s} {len(rs):3d}  first {mean([num(r["first_k"]) for r in rs]):5.1f}k'
              f'  calls {mean([num(r["calls"]) for r in rs]):5.1f}  final {mean([num(r["context_k"]) for r in rs]):5.1f}k'
              f'  cost {mean([num(r["cost_usd"]) for r in rs]):5.1f}')
    print()
    print('Inside Bash (the numbered rounds), per agent: outline, --decl, clause, grep (of them on sources), sed -n (on sources), commits, proofs, runner runs, checks')
    for kind in sorted({r['kind'] for r in numbered}):
        rs = [r for r in numbered if r['kind'] == kind]
        print(f'  {kind:9s} ' + '  '.join(
            f'{c} {mean([num(r[c]) for r in rs]):4.1f}' for c in
            ['outline', 'outline_decl', 'clause', 'grep', 'grep_src', 'sed', 'sed_src', 'commits', 'proofs', 'runner_runs', 'checks']))
    tallied = [r for r in numbered if num(r.get('tally', 0)) > 0]
    if tallied:
        print()
        print('Self-count (the tally in the Bash descriptions) against the measured calls:')
        for r in tallied:
            print(f'  round {r["round"]:>2} {r["package"]:28s} tally {num(r["tally"]):4.0f}  measured {num(r["calls"]):4.0f}')
    print()
    print('Per round: agents, calls/budget, over budget, cost, premises wrong/stated, items done/assigned, moved, regressions explained, conflicts')
    for rnd in sorted({int(r['round']) for r in numbered}):
        rs = [r for r in numbered if int(r['round']) == rnd]
        wb = [r for r in rs if r.get('budget')]
        over = sum(1 for r in wb if num(r['calls']) > num(r['budget']))
        prem = [r for r in rs if r.get('premises')]
        items = [r for r in rs if r.get('items')]
        pw = sum(num(r['premises_wrong']) for r in prem)
        ps = sum(num(r['premises']) for r in prem)
        dn = sum(num(r['done']) for r in items)
        it = sum(num(r['items']) for r in items)
        moved = sum(num(r['moved']) for r in rs if r.get('moved'))
        regs = sum(num(r['regressions']) for r in rs if r.get('regressions'))
        conf = sum(num(r['conflicts']) for r in rs if r.get('conflicts'))
        judged = ' judged' if items else ''
        print(f'  round {rnd:2d}  {len(rs)} agents  calls {mean([num(r["calls"]) for r in rs]):5.1f}'
              f' / budget {mean([num(r["budget"]) for r in wb]) if wb else 0:5.1f}  over {over}/{len(wb)}'
              f'  cost {sum(num(r["cost_usd"]) for r in rs):5.1f}'
              + (f'  premises {pw:.0f}/{ps:.0f} wrong  items {dn:.0f}/{it:.0f} done  moved {moved:+.0f}'
                 f'  regressions {regs:.0f}  conflicts {conf:.0f}' if items else '  (judgement columns empty)'))
    judged = [r for r in numbered if r.get('premises') and r.get('items')]
    if judged:
        print()
        print('Judgement columns, where filled: premise survival and conversion by kind')
        for kind in sorted({r['kind'] for r in judged}):
            rs = [r for r in judged if r['kind'] == kind]
            ps = sum(num(r['premises']) for r in rs)
            pw = sum(num(r['premises_wrong']) for r in rs)
            it = sum(num(r['items']) for r in rs)
            dn = sum(num(r['done']) for r in rs)
            dr = sum(num(r['dropped']) for r in rs)
            calls = sum(num(r['calls']) for r in rs)
            cost = sum(num(r['cost_usd']) for r in rs)
            moved = sum(num(r['moved']) for r in rs if r.get('moved'))
            print(f'  {kind:9s} {len(rs):2d} agents  premises wrong {pw:.0f}/{ps:.0f} ({pw / max(1, ps):.0%})'
                  f'  items done {dn:.0f}/{it:.0f} ({dn / max(1, it):.0%}), dropped {dr:.0f}'
                  f'  calls per item done {calls / max(1, dn):5.1f}  cost per item done {cost / max(1, dn):5.1f}'
                  f'  sequences moved {moved:+.0f} ({cost / max(1, moved):.1f} USD each)' if moved > 0 else
                  f'  {kind:9s} {len(rs):2d} agents  premises wrong {pw:.0f}/{ps:.0f} ({pw / max(1, ps):.0%})'
                  f'  items done {dn:.0f}/{it:.0f} ({dn / max(1, it):.0%}), dropped {dr:.0f}'
                  f'  calls per item done {calls / max(1, dn):5.1f}  cost per item done {cost / max(1, dn):5.1f}')
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--csv', default=CSV)
    ap.add_argument('--check', action='store_true')
    sub = ap.add_subparsers(dest='cmd')
    m = sub.add_parser('measure')
    m.add_argument('transcripts', nargs='+')
    r = sub.add_parser('report')
    r.add_argument('--last', type=int, default=0)
    args = ap.parse_args()
    if args.check:
        return cmd_check(args)
    if args.cmd == 'measure':
        return cmd_measure(args)
    if args.cmd == 'report':
        return cmd_report(args)
    ap.print_help()
    return 2


if __name__ == '__main__':
    sys.exit(main())
