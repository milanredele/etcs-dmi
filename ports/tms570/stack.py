#!/usr/bin/env python3
"""Worst-case stack depth of the ETCS on-board on the TMS570 (stack.sh).

Reads what GCC writes next to each object of the cross build with
-fstack-usage -fcallgraph-info=su,da: the call graph of the unit (*.ci,
VCG text) with the frame of every subprogram it defines.  The frame GCC
reports is the whole frame of the subprogram on the target: the saved
registers, the locals, the temporaries of aggregates and copies and the
outgoing arguments; what the subprogram calls comes on top of it.

The depth of a subprogram is its frame plus the deepest of its callees;
the walk goes through every call GCC emitted, so an inlined call costs
nothing (it is in the caller's frame) and a call GCC adds (memcpy for a
block copy, a 64-bit division, the last chance handler of a failed
check) is counted.  Calls that leave the on-board go into the runtime;
those are measured from the disassembly of the runtime libraries
(libgnat.a, libgcc.a of the runtime given): the prologue of each
function (push, vpush, sub sp) is its frame, its calls are its
relocations, and the same walk applies.

The analysis is sound only for a call graph without indirect calls,
without recursion and with every frame static.  The on-board has no
dispatching, no access to subprogram and no recursion: the tool fails
when it finds an indirect call (GCC's __indirect_call node, a blx to a
register in the runtime), a cycle, a call to a symbol defined nowhere,
or a frame that is dynamic and not listed in DYNAMIC below with a bound
argued from the source.

Usage: stack.py --objdir DIR --rts DIR --objdump PATH [--budget BYTES]
                [--top N] [--path NAME ...]
"""

import argparse
import glob
import os
import re
import subprocess
import sys

# Entry points: the four subprograms of EVC_Core the executive calls,
# by assembler name.  Elaboration (every ___elabs/___elabb, run one after
# the other by adainit before the executive starts) is reported too.
ENTRIES = ["evc_core__initialise", "evc_core__handle_input",
           "evc_core__tick", "evc_core__take_outputs"]

# Frames GCC reports as dynamic, with a bound from the source.  A new
# dynamic frame fails the tool until it is understood and listed here.
DYNAMIC = {
    # ETCS_Packet_Index.Scan: two "Probe : Reader := R" copies of the
    # reader (ETCS_Bits.Reader (Size), Size <= Max_Bytes = 1024): the
    # discriminant, 1024 bytes, Position, Limit and Failed are at most
    # 1040 bytes each, on top of the 32 static bytes GCC reports.
    "etcs_packet_index__scan": 2 * 1040,
}

NODE = re.compile(r'^node: \{ title: "([^"]*)" label: "([^"]*)"(.*)\}$')
EDGE = re.compile(r'^edge: \{ sourcename: "([^"]*)" targetname: "([^"]*)"')
FRAME = re.compile(r'\\n(\d+) bytes \(([a-z,]+)\)')


def fail(msg):
    sys.stdout.flush()
    print("stack: FAIL: " + msg, file=sys.stderr)
    sys.exit(1)


def asm_name(title):
    """The assembler name of a node title ("path:name" or "name")."""
    return title.rsplit(":", 1)[1] if "/" in title else title


class Function:
    def __init__(self, key, name, frame, where):
        self.key = key          # unique key
        self.name = name        # assembler name
        self.frame = frame      # bytes
        self.where = where      # source location or object
        self.calls = []         # raw call targets
        self.callees = []       # resolved Function objects
        self.depth = None
        self.next = None        # deepest callee


def read_call_graphs(objdir):
    """The on-board's subprograms from the *.ci files."""
    funcs = {}
    by_name = {}
    cis = sorted(glob.glob(os.path.join(objdir, "*.ci")))
    if not cis:
        fail("no *.ci in %s: build with -fcallgraph-info=su,da" % objdir)
    for obj in glob.glob(os.path.join(objdir, "*.o")):
        ci = obj[:-2] + ".ci"
        if not os.path.exists(ci) or os.path.getmtime(ci) + 1 < os.path.getmtime(obj):
            fail("%s has no call graph of the same build" % obj)
    for ci in cis:
        local = {}
        edges = []
        with open(ci, encoding="utf-8", errors="replace") as f:
            for line in f:
                m = NODE.match(line)
                if m:
                    title, label = m.group(1), m.group(2)
                    fm = FRAME.search(label)
                    if not fm:
                        continue        # declared here, defined elsewhere
                    size, kind = int(fm.group(1)), fm.group(2)
                    name = asm_name(title)
                    where = label.split("\\n")[1] if "\\n" in label else ci
                    if kind != "static":
                        if name not in DYNAMIC:
                            fail("dynamic frame (%s) of %s at %s: bound it in "
                                 "DYNAMIC" % (kind, name, where))
                        size += DYNAMIC[name]
                    key = os.path.basename(ci) + ":" + name
                    fn = Function(key, name, size, where)
                    funcs[key] = fn
                    local[title] = fn
                    by_name.setdefault(name, []).append(fn)
                    continue
                m = EDGE.match(line)
                if m:
                    edges.append((m.group(1), m.group(2)))
        for src, dst in edges:
            if src not in local:
                fail("edge from an unknown node %s in %s" % (src, ci))
            local[src].calls.append(local.get(dst, dst))
    return funcs, by_name


INSN = re.compile(r'^\s+[0-9a-f]+:\s+[0-9a-f]{8}\s+(\S+)\s*(.*)$')
RELOC = re.compile(r'^\s+[0-9a-f]+: (R_ARM_(?:CALL|JUMP24|THM_CALL|THM_JUMP24|PC24))\s+(\S+)')
FUNC = re.compile(r'^[0-9a-f]+ <([^>]+)>:$')
OBJ = re.compile(r'^(\S+\.o):\s+file format')
SYM = re.compile(r'^([0-9a-f]{8}) [lgw ][ w]....F (\S+)\s+[0-9a-f]{8}\s+(?:\.hidden )?(\S+)$')


def regs_in(lst):
    n = 0
    for part in lst.strip("{} ").split(","):
        part = part.strip()
        m = re.match(r'^[rd](\d+)-[rd](\d+)$', part)
        n += int(m.group(2)) - int(m.group(1)) + 1 if m else 1
    return n


def read_runtime(objdump, libs):
    """Functions of the runtime libraries from their disassembly."""
    funcs = {}
    by_name = {}
    for lib in libs:
        out = subprocess.run([objdump, "-dr", lib], capture_output=True,
                             text=True, check=True).stdout
        obj = os.path.basename(lib)
        cur = None
        pending_bl = None
        for line in out.splitlines():
            m = OBJ.match(line)
            if m:
                obj = os.path.basename(lib) + "(" + m.group(1) + ")"
                cur = None
                continue
            m = FUNC.match(line)
            if m:
                name = m.group(1)
                cur = Function(obj + ":" + name, name, 0, obj)
                cur.indirect = False
                cur.dynamic = False
                funcs[cur.key] = cur
                by_name.setdefault(name, []).append(cur)
                pending_bl = None
                continue
            if cur is None:
                continue
            m = RELOC.match(line)
            if m:
                cur.calls.append(m.group(2))
                pending_bl = None
                continue
            if pending_bl:
                cur.calls.append(pending_bl)
                pending_bl = None
            m = INSN.match(line)
            if not m:
                continue
            op, args = m.group(1), m.group(2)
            if op in ("push", "stmdb", "stmfd") and (op == "push" or args.startswith("sp!")):
                cur.frame += 4 * regs_in(args[args.index("{"):args.index("}") + 1])
            elif op == "vpush":
                cur.frame += 8 * regs_in(args[args.index("{"):args.index("}") + 1])
            elif op == "sub" and args.startswith("sp, sp, "):
                imm = re.match(r'sp, sp, #(\d+)', args)
                if imm:
                    cur.frame += int(imm.group(1))
                else:
                    cur.dynamic = True
            elif op.startswith("blx") and re.match(r'r\d|ip|lr', args):
                cur.indirect = True
            elif op == "bl":
                # a local call carries no relocation: its target is in
                # the instruction ("bl 1c <name>")
                t = re.search(r'<([^>+]+)>$', args)
                pending_bl = t.group(1) if t else None
        if pending_bl and cur:
            cur.calls.append(pending_bl)
        # aliases: the disassembly labels an address with one of its
        # names (__aeabi_ldiv0 is __aeabi_idiv0), the symbol table has all
        out = subprocess.run([objdump, "-t", lib], capture_output=True,
                             text=True, check=True).stdout
        obj = os.path.basename(lib)
        groups = {}
        for line in out.splitlines():
            m = OBJ.match(line)
            if m:
                obj = os.path.basename(lib) + "(" + m.group(1) + ")"
                continue
            m = SYM.match(line)
            if m and m.group(2) != "*UND*":
                groups.setdefault((obj, m.group(2), m.group(1)), []).append(m.group(3))
        for (obj, _, _), names in groups.items():
            known = [f for n in names for f in by_name.get(n, []) if f.where == obj]
            for n in names:
                if known and not any(f.where == obj for f in by_name.get(n, [])):
                    by_name.setdefault(n, []).append(known[0])
    return funcs, by_name


def resolve(fn, by_name, rt_by_name, rt_obj_of):
    for c in fn.calls:
        if isinstance(c, Function):
            fn.callees.append(c)
            continue
        if c == "__indirect_call":
            fail("indirect call in %s (%s)" % (fn.name, fn.where))
        cands = by_name.get(c)
        if cands is None:
            cands = rt_by_name.get(c)
            if cands and len(cands) > 1 and rt_obj_of:
                same = [x for x in cands if x.where == rt_obj_of(fn)]
                cands = same or cands
        if not cands:
            fail("call from %s (%s) to %s, defined nowhere" % (fn.name, fn.where, c))
        if len(cands) > 1:
            if len({x.frame for x in cands}) > 1:
                fail("call from %s to %s: %d definitions" % (fn.name, c, len(cands)))
        fn.callees.append(cands[0])


def depth(fn, stack):
    if fn.depth is not None:
        return fn.depth
    if fn in stack:
        cyc = stack[stack.index(fn):] + [fn]
        fail("recursion: " + " -> ".join(x.name for x in cyc))
    stack.append(fn)
    best, nxt = 0, None
    for c in fn.callees:
        d = depth(c, stack)
        if d > best:
            best, nxt = d, c
    stack.pop()
    fn.depth = fn.frame + best
    fn.next = nxt
    return fn.depth


def path_of(fn):
    out = []
    while fn is not None:
        out.append(fn)
        fn = fn.next
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--objdir", required=True)
    ap.add_argument("--rts", required=True)
    ap.add_argument("--objdump", required=True)
    ap.add_argument("--budget", type=int, default=0)
    ap.add_argument("--top", type=int, default=20)
    ap.add_argument("--path", action="append", default=[],
                    help="also print the deepest path from this subprogram "
                         "(assembler name, e.g. evc_sdm__step)")
    args = ap.parse_args()

    funcs, by_name = read_call_graphs(args.objdir)
    libs = [os.path.join(args.rts, "adalib", "libgnat.a"),
            os.path.join(args.rts, "adalib", "libgcc.a")]
    rt_funcs, rt_by_name = read_runtime(args.objdump, libs)

    for fn in funcs.values():
        resolve(fn, by_name, rt_by_name, None)
    # the runtime: only what the on-board reaches
    todo = [c for fn in funcs.values() for c in fn.callees if c.key in rt_funcs]
    seen = set()
    runtime_used = []
    while todo:
        fn = todo.pop()
        if fn.key in seen:
            continue
        seen.add(fn.key)
        runtime_used.append(fn)
        if fn.indirect:
            fail("indirect call in the runtime: %s (%s)" % (fn.name, fn.where))
        if fn.dynamic:
            fail("dynamic frame in the runtime: %s (%s)" % (fn.name, fn.where))
        resolve(fn, {}, rt_by_name, lambda f: f.where)
        todo.extend(fn.callees)

    for fn in list(funcs.values()) + runtime_used:
        depth(fn, [])

    # (a) frames
    print("Frames of the on-board, largest first (bytes, %d subprograms):"
          % len(funcs))
    for fn in sorted(funcs.values(), key=lambda f: -f.frame)[:args.top]:
        print("  %7d  %s  %s" % (fn.frame, fn.name, fn.where.split("/")[-1]))

    print("\nRuntime reached from the on-board (frame, depth; from the "
          "disassembly of %s):" % ", ".join(os.path.basename(l) for l in libs))
    for fn in sorted(runtime_used, key=lambda f: (-f.depth, f.name)):
        print("  %5d %5d  %s  %s" % (fn.frame, fn.depth, fn.name, fn.where))

    # (b) entry points
    worst = 0
    print("\nWorst-case depth from each entry point (bytes):")
    rows = []
    for e in ENTRIES:
        fns = by_name.get(e)
        if not fns:
            fail("entry point %s not found" % e)
        rows.append((e, fns[0]))
    extra = []
    for e in args.path:
        fns = by_name.get(e)
        if not fns:
            fail("subprogram %s not found" % e)
        extra.append((e + " (asked)", fns[0]))
    elab = [f for f in funcs.values() if f.name.endswith(("___elabs", "___elabb"))]
    if elab:
        rows.append(("elaboration (deepest of %d)" % len(elab),
                     max(elab, key=lambda f: f.depth)))
    for label, fn in rows + extra:
        if (label, fn) in rows:
            worst = max(worst, fn.depth)
        print("\n  %s: %d" % (label, fn.depth))
        total = 0
        for step in path_of(fn):
            total += step.frame
            print("    %7d %7d  %s  %s" % (step.frame, total, step.name,
                                          step.where.split("/")[-1]))

    print("\nWorst case: %d bytes" % worst)
    if args.budget:
        print("Budget:     %d bytes (margin %d bytes, %.0f %%)"
              % (args.budget, args.budget - worst,
                 100.0 * (args.budget - worst) / args.budget))
        if worst > args.budget:
            fail("worst case %d bytes over the budget of %d" % (worst, args.budget))
    print("stack: ok")


if __name__ == "__main__":
    main()
