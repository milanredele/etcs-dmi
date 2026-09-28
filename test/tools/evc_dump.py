#!/usr/bin/env python3
"""Decode the output of an evc_test golden (EVC_DUMP=dir obj/evc_test
writes dir/<name>.bin): the records of EVC_Outbox (port u8, length u16
little endian, payload), cut into cycles at MSG_MODE_LEVEL (the first
DMI frame of the outputs of a cycle, EVC_Core.Produce_Outputs).

  evc_dump.py FILE                 list the records, cycle by cycle
  evc_dump.py --summary FILE       count the records by kind
  evc_dump.py --diff OLD NEW       what NEW has that OLD has not, and the
                                   reverse, cycle by cycle
  evc_dump.py --diff --ignore K,.. OLD NEW
                                   the same without the record kinds K
                                   (as --summary names them, e.g.
                                   DMI:SPEED_STATE,TIU,JRU:20)

A kind is PORT or PORT:TYPE: the DMI frame type, the JRU event.
"""
import sys

PORTS = ['BTM', 'RTM', 'ODO', 'TIU', 'DMI', 'ATO', 'JRU']
DMI_TYPES = {0x01: 'SPEED_STATE', 0x02: 'MODE_LEVEL', 0x05: 'TRACK_COND',
             0x06: 'PLANNING', 0x07: 'STATUS', 0x0A: 'ONBOARD'}


def records(data):
    i = 0
    out = []
    while i + 3 <= len(data):
        port = data[i]
        length = data[i + 1] + 256 * data[i + 2]
        payload = data[i + 3:i + 3 + length]
        out.append((PORTS[port] if port < len(PORTS) else str(port),
                    bytes(payload)))
        i += 3 + length
    if i != len(data):
        raise SystemExit('not a sequence of whole records')
    return out


def kind(rec):
    port, p = rec
    if port == 'DMI' and p:
        return 'DMI:' + DMI_TYPES.get(p[0], '%02X' % p[0])
    if port == 'JRU' and p:
        return 'JRU:%d' % p[0]
    return port


def describe(rec):
    port, p = rec
    k = kind(rec)
    if k == 'DMI:SPEED_STATE' and len(p) == 26:
        q = p[5:]

        def u16(n):
            return q[n] + 256 * q[n + 1]
        return ('%s v %d perm %d target %d rel %d sbi %d w %d d %d mon %d '
                'dial %d flags %d st %d mrdt %d'
                % (k, u16(0), u16(2), u16(4), u16(6), u16(8), u16(10),
                   q[12] + 256 * (q[13] + 256 * (q[14] + 256 * q[15])),
                   q[16], q[17], q[18], q[19], q[20]))
    if k == 'DMI:STATUS' and len(p) == 28:
        q = p[5:]
        geo = q[16] + 256 * (q[17] + 256 * (q[18] + 256 * q[19]))
        return ('%s brake %d tti %d geo %s' % (
            k, q[0], q[8] + 256 * q[9],
            'unknown' if geo == 0xFFFFFFFF else str(geo)))
    if port == 'JRU' and len(p) >= 8:
        cyc = p[4] + 256 * (p[5] + 256 * (p[6] + 256 * p[7]))
        return '%s %d %d %d (cycle %d)' % (k, p[1], p[2], p[3], cyc)
    if port == 'TIU' and len(p) == 2:
        return 'TIU commands %d reasons %d' % (p[0], p[1])
    return '%s %s' % (k, p.hex())


def cycles(recs):
    out = [[]]
    for r in recs:
        if kind(r) == 'DMI:MODE_LEVEL' and out[-1]:
            out.append([])
        out[-1].append(r)
    return out


def load(path):
    with open(path, 'rb') as f:
        return records(f.read())


def main(argv):
    ignore = set()
    if '--ignore' in argv:
        i = argv.index('--ignore')
        ignore = set(argv[i + 1].split(','))
        del argv[i:i + 2]
    if argv[:1] == ['--summary']:
        counts = {}
        for r in load(argv[1]):
            counts[kind(r)] = counts.get(kind(r), 0) + 1
        for k in sorted(counts):
            print('%-18s %d' % (k, counts[k]))
        return 0
    if argv[:1] == ['--diff']:
        old = [r for r in load(argv[1]) if kind(r) not in ignore]
        new = [r for r in load(argv[2]) if kind(r) not in ignore]
        co, cn = cycles(old), cycles(new)
        diffs = 0
        for n in range(max(len(co), len(cn))):
            a = [describe(r) for r in (co[n] if n < len(co) else [])]
            b = [describe(r) for r in (cn[n] if n < len(cn) else [])]
            if a != b:
                diffs += 1
                if diffs <= 40:
                    print('cycle group %d:' % n)
                    for x in a:
                        if x not in b:
                            print('  - ' + x)
                    for x in b:
                        if x not in a:
                            print('  + ' + x)
        print('%d of %d cycle groups differ'
              % (diffs, max(len(co), len(cn))))
        return 1 if diffs else 0
    for n, c in enumerate(cycles(load(argv[0]))):
        print('cycle group %d' % n)
        for r in c:
            print('  ' + describe(r))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
