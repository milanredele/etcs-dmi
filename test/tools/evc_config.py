#!/usr/bin/env python3
"""The installation configuration of the ETCS on-board (evc/evc_config.ads)
between its readable text form (TOML) and its byte image, which
EVC_Core.Configure loads.

  evc_config.py TEXT IMAGE        the text form TEXT to the image IMAGE
  evc_config.py --decode IMAGE    the image back to the text form (stdout)
  evc_config.py --check FILE      validate a text form or an image
  evc_config.py --default         the text form of EVC_Config.Default

The image (little endian) and its rules are those of evc/evc_config.ads:
magic "EVCF", version u16, length u16, the fields, CRC-32 of IEEE 802.3
(zlib's crc32) of the bytes before it, in its last 4 bytes. Format
version 1: 36 bytes. Format version 2 (format = 2 and a [train] section
in the text form): the bytes 0 .. 31 of version 1, the braking model and
the special brakes the vehicle has, and for a gamma train (a [gamma]
section) its models, factors and times; 38 to 1248 bytes. The tool
validates like the on-board does: every field in its range, the curves
of their counts with the speeds rising, the fields ending at the CRC,
and Table 3 of SUBSET-026 3.13.2.2.6.1 (magnetic shoe brake: no
interface or the emergency brake model only; Ep brake: not the emergency
brake model only). An invalid input is refused with the reason, exit
status 1.

Python standard library only (tomllib, Python 3.11 or later).
"""
import struct
import sys
import tomllib
import zlib

MAGIC = b'EVCF'
VERSION = 1
LENGTH = 36
CRC_OFFSET = 32
# format version 2 (EVC_Config.Encode_V2)
VERSION_2 = 2
MIN_LENGTH_2 = 38
MAX_LENGTH_2 = 1248
MODELS = ['lambda', 'gamma']        # byte 32 (Fixed_Train_T.Model)
MAX_STEPS = 8                       # EVC_Supervision_Input.Max_Curve_Steps
MAX_SPEED_CMS = 30_000              # Speed_Cms_T
MAX_DECEL_MMS2 = 30_000             # Decel_Mms2_T
MAX_FACTOR_MILLI = 2_000            # Factor_Milli_T
MAX_TIME_MS = 60_000

# 3.13.2.2.6.1: the configuration possibilities, in the order of the
# image codes 0 .. 3 (EVC_Supervision_Input.Special_Brake_Interface_T)
INTERFACES = ['none', 'emergency', 'service', 'both']
BRAKES = ['regenerative', 'eddy_current', 'magnetic_shoe', 'ep']
# Table 3 (PDF page 122 of SUBSET-026-3 v4.0.0): the possibilities
# marked "x" for each special brake
TABLE_3 = {
    'regenerative': {'none', 'emergency', 'service', 'both'},
    'eddy_current': {'none', 'emergency', 'service', 'both'},
    'magnetic_shoe': {'none', 'emergency'},
    'ep': {'none', 'service', 'both'},
}

# (section, key, kind, low, high): the fields of the text form in the
# order of the image
FLAGS = [('brakes', 'service_brake_command'),
         ('brakes', 'service_brake_feedback'),
         ('brakes', 'feedback_from_cylinder'),
         ('brakes', 'traction_cut_off')]
RANGES = {
    ('brakes', 'k1_milli'): (1000, 5000),
    ('antenna', 'to_cab_a_cm'): (0, 100_000),
    ('antenna', 'to_cab_b_cm'): (0, 100_000),
    ('service_brake_failure', 'time_ms'): (0, 60_000),
    ('service_brake_failure', 'decel_mms2'): (0, 3_000),
}
SECTIONS = {
    'brakes': ['service_brake_command', 'service_brake_feedback',
               'feedback_from_cylinder', 'k1_milli', 'traction_cut_off',
               'additional_brake_allowed', 'regenerative_needs_catenary'],
    'special_brakes': BRAKES,
    'service_brake_failure': ['time_ms', 'decel_mms2'],
    'antenna': ['to_cab_a_cm', 'to_cab_b_cm'],
}

DEFAULT = {
    'format': 1,
    'brakes': {'service_brake_command': True,
               'service_brake_feedback': True,
               'feedback_from_cylinder': False,
               'k1_milli': 2500,
               'traction_cut_off': True,
               'additional_brake_allowed': False,
               'regenerative_needs_catenary': True},
    'special_brakes': {'regenerative': 'both', 'eddy_current': 'both',
                       'magnetic_shoe': 'emergency', 'ep': 'both'},
    'service_brake_failure': {'time_ms': 2000, 'decel_mms2': 100},
    'antenna': {'to_cab_a_cm': 300, 'to_cab_b_cm': 1700},
}

TEMPLATE = '''\
# The installation configuration of the ETCS on-board (evc/evc_config.ads):
# what SUBSET-026 v4.0.0 lets the engineering of the on-board define for
# the vehicle it is fitted to. Data, not code: test/tools/evc_config.py
# makes the byte image the on-board loads (EVC_Core.Configure):
#   test/tools/evc_config.py THIS_FILE IMAGE
#   test/tools/evc_config.py --decode IMAGE     (back to this form)

# the format of the image (EVC_Config.Format_Version)
format = {format}

[brakes]
# 3.13.2.2.7.1: a service brake interface commands a full service brake
service_brake_command = {service_brake_command}
# 3.13.2.2.7.2: the service brake feedback (the brake pressure of
# SUBSET-034 2.3.2) is acquired; used where Q_NVSBFBPERM allows it
# (3.13.2.2.7.3, A.3.10)
service_brake_feedback = {service_brake_feedback}
# 3.13.2.2.7.3, A.3.10.3: the feedback is the brake cylinder pressure,
# converted to a fictive main brake pipe pressure with k1
feedback_from_cylinder = {feedback_from_cylinder}
# A.3.10.3: k1 in thousandths, 1000 .. 5000 (k1 "is normally between 2.0
# and 2.7")
k1_milli = {k1_milli}
# 3.13.2.2.8.1: the traction cut-off command is implemented
traction_cut_off = {traction_cut_off}
# 3.13.2.2.6.4, 3.13.2.2.6.6: the contribution of a special or additional
# brake independent from the adhesion may select A_NVMAXREDADH1
additional_brake_allowed = {additional_brake_allowed}
# 3.12.1.3.3: the regenerative brake depends on the voltage of the
# catenary, so a powerless section inhibits it
regenerative_needs_catenary = {regenerative_needs_catenary}

[special_brakes]
# 3.13.2.2.6.1 Table 3: whether an interface with the special brake
# exists and which brake models its status affects: "none" (no
# interface), "emergency" (the emergency brake model only), "service"
# (the service brake model only), "both". Table 3 allows every value for
# the regenerative and the eddy current brake, "none" or "emergency" for
# the magnetic shoe brake, and "none", "service" or "both" for the Ep
# brake.
regenerative = "{regenerative}"
eddy_current = "{eddy_current}"
magnetic_shoe = "{magnetic_shoe}"
ep = "{ep}"

[service_brake_failure]
# 3.14.1.2 (3.14.1.1 leaves the detection to the implementation): the
# service brake failed when, time_ms (0 .. 60000) beyond its build up
# time T_bs after the command, the train does not decelerate by at least
# decel_mms2 (mm/s², 0 .. 3000); the emergency brake is then commanded
time_ms = {time_ms}
decel_mms2 = {decel_mms2}

[antenna]
# 3.6.1.3.4: the front end is the end of the engine the orientation
# points to; the balises are detected at the antenna (3.6.4.1.1 a,
# 3.13.10.2.7): the antenna from the cab A end and from the cab B end of
# the engine, cm, 0 .. 100000
to_cab_a_cm = {to_cab_a_cm}
to_cab_b_cm = {to_cab_b_cm}
'''


TRAIN_TEMPLATE = '''
[train]
# format 2 only. 3.13.2.2.3: the braking model, "lambda" (the conversion
# model of the brake percentage the driver enters) or "gamma" (the
# models of the [gamma] section, installation data, 3.18.3.2 c))
braking_model = "{braking_model}"
# 3.13.2.2.6: the special brakes the vehicle has, of "regenerative",
# "eddy_current", "magnetic_shoe" and "ep"
special_brakes = {special_brakes}
'''

GAMMA_TEMPLATE = '''
[gamma]
# a gamma train (EVC_Config.Gamma_T). 3.13.2.2.3.2: the brake reaction
# and equivalent build up times, ms, 0 .. 60000
t_brake_react_emergency_ms = {t_brake_react_emergency_ms}
t_brake_build_up_emergency_ms = {t_brake_build_up_emergency_ms}
t_brake_react_service_ms = {t_brake_react_service_ms}
t_brake_build_up_service_ms = {t_brake_build_up_service_ms}
# 3.13.2.2.3.1: a curve is a list of steps [speed cm/s, deceleration
# mm/s²], each 0 .. 30000, the speeds strictly rising; a step's
# deceleration applies up to its speed, the last one open ended; 1 to 8
# steps for the emergency and the service brake, 0 to 8 for the normal
# service brake (used when no [gamma.normal_service] is given)
a_brake_emergency = {a_brake_emergency}
a_brake_service = {a_brake_service}
a_brake_normal_service = {a_brake_normal_service}
# 3.13.2.2.9.1: Kdry_rst for M_NVEBCL 0 to 9, 8 factors each, one per
# step of a_brake_emergency (those beyond its steps unused), and Kwet_rst,
# thousandths 0 .. 2000
kdry_rst = {kdry_rst}
kwet_rst = {kwet_rst}
# 3.13.2.2.9.2: Kn+ and Kn-, curves of 0 to 8 steps [speed cm/s, mm/s²
# per unit of gradient]
kn_plus = {kn_plus}
kn_minus = {kn_minus}
# 3.13.2.2.10: the nominal rotating mass, % 0 .. 100 (0: not given, A.3.1
# applies)
m_rotating_nom = {m_rotating_nom}
'''

NORMAL_SERVICE_TEMPLATE = '''
[gamma.normal_service]
# optional. 3.13.2.2.3.1.9, .10: the pivots A_SB01, A_SB12 (mm/s², 0 ..
# 30000) and the models A_brake_normal_service_0 .. _2 in G, then in P,
# curves of 0 to 8 steps each
a_sb01_mms2 = {a_sb01_mms2}
a_sb12_mms2 = {a_sb12_mms2}
g = {g}
p = {p}
'''

BY_COMBINATION_TEMPLATE = '''
[gamma.by_combination]
# optional. 3.13.2.2.3.1.7: A_brake_emergency and A_brake_service for the
# combinations 0 .. 7 of the special brakes in use (bit 0 regenerative,
# bit 1 eddy current, bit 2 magnetic shoe), curves of 1 to 8 steps;
# 3.13.2.2.3.2.8 Table 4: [reaction, build up] times, ms 0 .. 60000, of
# the emergency and the service brake for the combinations 0 .. 15 (bit 3
# Ep)
emergency = {emergency}
service = {service}
t_emergency_ms = {t_emergency_ms}
t_service_ms = {t_service_ms}
'''

GAMMA_TIMES = ['t_brake_react_emergency_ms', 't_brake_build_up_emergency_ms',
               't_brake_react_service_ms', 't_brake_build_up_service_ms']
# (key, the least number of steps) of the curves of the gamma train
GAMMA_CURVES = [('a_brake_emergency', 1), ('a_brake_service', 1),
                ('a_brake_normal_service', 0)]
GAMMA_KEYS = (GAMMA_TIMES + [k for k, _ in GAMMA_CURVES]
              + ['kdry_rst', 'kwet_rst', 'kn_plus', 'kn_minus',
                 'm_rotating_nom'])
NORMAL_SERVICE_KEYS = ['a_sb01_mms2', 'a_sb12_mms2', 'g', 'p']
BY_COMBINATION_KEYS = ['emergency', 'service', 't_emergency_ms',
                       't_service_ms']


class Invalid(Exception):
    pass


def check_int(name, v, high):
    if type(v) is not int or not 0 <= v <= high:
        raise Invalid(f'{name} = {v!r}: an integer in 0 .. {high}')


def check_list(name, v, count):
    if not isinstance(v, list) or len(v) != count:
        raise Invalid(f'{name}: a list of {count}')


def check_curve(name, c, low):
    """A curve: low to MAX_STEPS steps [speed, deceleration], the speeds
    strictly rising (EVC_Config.Get_Curve)"""
    if not isinstance(c, list) or not low <= len(c) <= MAX_STEPS:
        raise Invalid(f'{name}: a curve of {low} to {MAX_STEPS} steps')
    for k, step in enumerate(c):
        check_list(f'{name}[{k}]', step, 2)
        check_int(f'{name}[{k}] speed', step[0], MAX_SPEED_CMS)
        check_int(f'{name}[{k}] deceleration', step[1], MAX_DECEL_MMS2)
        if k > 0 and step[0] <= c[k - 1][0]:
            raise Invalid(f'{name}[{k}]: the speeds not rising')


def check_keys(name, values, keys):
    if not isinstance(values, dict) or set(values) != set(keys):
        raise Invalid(f'[{name}]: expected the keys ' + ', '.join(keys))


def check_train(t):
    check_keys('train', t, ['braking_model', 'special_brakes'])
    if t['braking_model'] not in MODELS:
        raise Invalid(f'train.braking_model = {t["braking_model"]!r}: one of '
                      + ', '.join(MODELS))
    b = t['special_brakes']
    if (not isinstance(b, list) or any(x not in BRAKES for x in b)
            or len(set(b)) != len(b)):
        raise Invalid(f'train.special_brakes = {b!r}: a list of distinct '
                      'names of ' + ', '.join(BRAKES))


def check_gamma(g):
    optional = {'normal_service', 'by_combination'}
    if (not isinstance(g, dict) or set(g) - optional != set(GAMMA_KEYS)):
        raise Invalid('[gamma]: expected the keys ' + ', '.join(GAMMA_KEYS)
                      + ' and the tables normal_service, by_combination '
                      'if given')
    for k in GAMMA_TIMES:
        check_int(f'gamma.{k}', g[k], MAX_TIME_MS)
    for k, low in GAMMA_CURVES:
        check_curve(f'gamma.{k}', g[k], low)
    check_list('gamma.kdry_rst', g['kdry_rst'], 10)
    for ebcl, row in enumerate(g['kdry_rst']):
        check_list(f'gamma.kdry_rst[{ebcl}]', row, MAX_STEPS)
        for k, v in enumerate(row):
            check_int(f'gamma.kdry_rst[{ebcl}][{k}]', v, MAX_FACTOR_MILLI)
    check_list('gamma.kwet_rst', g['kwet_rst'], MAX_STEPS)
    for k, v in enumerate(g['kwet_rst']):
        check_int(f'gamma.kwet_rst[{k}]', v, MAX_FACTOR_MILLI)
    check_curve('gamma.kn_plus', g['kn_plus'], 0)
    check_curve('gamma.kn_minus', g['kn_minus'], 0)
    check_int('gamma.m_rotating_nom', g['m_rotating_nom'], 100)
    if 'normal_service' in g:
        n = g['normal_service']
        check_keys('gamma.normal_service', n, NORMAL_SERVICE_KEYS)
        check_int('gamma.normal_service.a_sb01_mms2', n['a_sb01_mms2'],
                  MAX_DECEL_MMS2)
        check_int('gamma.normal_service.a_sb12_mms2', n['a_sb12_mms2'],
                  MAX_DECEL_MMS2)
        for key in ('g', 'p'):
            check_list(f'gamma.normal_service.{key}', n[key], 3)
            for i, c in enumerate(n[key]):
                check_curve(f'gamma.normal_service.{key}[{i}]', c, 0)
    if 'by_combination' in g:
        c = g['by_combination']
        check_keys('gamma.by_combination', c, BY_COMBINATION_KEYS)
        for key in ('emergency', 'service'):
            check_list(f'gamma.by_combination.{key}', c[key], 8)
            for i, curve in enumerate(c[key]):
                check_curve(f'gamma.by_combination.{key}[{i}]', curve, 1)
        for key in ('t_emergency_ms', 't_service_ms'):
            check_list(f'gamma.by_combination.{key}', c[key], 16)
            for i, pair in enumerate(c[key]):
                check_list(f'gamma.by_combination.{key}[{i}]', pair, 2)
                for v in pair:
                    check_int(f'gamma.by_combination.{key}[{i}]', v,
                              MAX_TIME_MS)


def gamma_model(config):
    return (config.get('format') == VERSION_2
            and isinstance(config.get('train'), dict)
            and config['train'].get('braking_model') == 'gamma')


def check(config):
    """Validate a configuration of the text form (a dict as tomllib gives
    it); raise Invalid with the reason."""
    fmt = config.get('format')
    if fmt not in (VERSION, VERSION_2):
        raise Invalid(f'format {fmt!r}: {VERSION} or {VERSION_2}')
    expected = ['format'] + list(SECTIONS)
    if fmt == VERSION_2:
        expected += ['train'] + (['gamma'] if gamma_model(config) else [])
    if set(config) != set(expected):
        raise Invalid('sections: expected ' + ', '.join(expected) +
                      ', got ' + ', '.join(config))
    for section, keys in SECTIONS.items():
        values = config[section]
        check_keys(section, values, keys)
        for key in keys:
            v = values[key]
            if section == 'special_brakes':
                if v not in INTERFACES:
                    raise Invalid(f'{section}.{key} = {v!r}: one of ' +
                                  ', '.join(INTERFACES))
                if v not in TABLE_3[key]:
                    raise Invalid(f'{section}.{key} = {v!r}: Table 3 of '
                                  '3.13.2.2.6.1 allows ' +
                                  ', '.join(i for i in INTERFACES
                                            if i in TABLE_3[key]))
            elif (section, key) in RANGES:
                low, high = RANGES[(section, key)]
                if type(v) is not int or not low <= v <= high:
                    raise Invalid(f'{section}.{key} = {v!r}: an integer '
                                  f'in {low} .. {high}')
            elif type(v) is not bool:
                raise Invalid(f'{section}.{key} = {v!r}: true or false')
    if fmt == VERSION_2:
        check_train(config['train'])
        if gamma_model(config):
            check_gamma(config['gamma'])


def curve_bytes(c):
    return bytes([len(c)]) + b''.join(struct.pack('<HH', s, d) for s, d in c)


def gamma_bytes(g):
    """The gamma train from byte 34 on, in the order of Encode_V2"""
    out = struct.pack('<4H', *(g[k] for k in GAMMA_TIMES))
    for k, _ in GAMMA_CURVES:
        out += curve_bytes(g[k])
    out += struct.pack('<80H', *(v for row in g['kdry_rst'] for v in row))
    out += struct.pack('<8H', *g['kwet_rst'])
    out += curve_bytes(g['kn_plus']) + curve_bytes(g['kn_minus'])
    out += bytes([g['m_rotating_nom']])
    n = g.get('normal_service')
    if n is None:
        out += b'\x00'
    else:
        out += b'\x01' + struct.pack('<HH', n['a_sb01_mms2'], n['a_sb12_mms2'])
        out += b''.join(curve_bytes(c) for c in n['g'] + n['p'])
    c = g.get('by_combination')
    if c is None:
        out += b'\x00'
    else:
        out += b'\x01' + b''.join(curve_bytes(x)
                                  for x in c['emergency'] + c['service'])
        for key in ('t_emergency_ms', 't_service_ms'):
            out += struct.pack('<32H', *(v for pair in c[key] for v in pair))
    return out


def encode(config):
    check(config)
    fmt = config['format']
    b, s = config['brakes'], config['special_brakes']
    f, a = config['service_brake_failure'], config['antenna']
    body = MAGIC + struct.pack(
        '<HHBBBBH4BBBIIHH', fmt, LENGTH if fmt == VERSION else 0,
        b['service_brake_command'], b['service_brake_feedback'],
        b['feedback_from_cylinder'], b['traction_cut_off'], b['k1_milli'],
        *(INTERFACES.index(s[k]) for k in BRAKES),
        b['additional_brake_allowed'], b['regenerative_needs_catenary'],
        a['to_cab_a_cm'], a['to_cab_b_cm'], f['time_ms'], f['decel_mms2'])
    assert len(body) == CRC_OFFSET
    if fmt == VERSION_2:
        t = config['train']
        body += bytes([MODELS.index(t['braking_model']),
                       sum(1 << BRAKES.index(x) for x in t['special_brakes'])])
        if gamma_model(config):
            body += gamma_bytes(config['gamma'])
        length = len(body) + 4
        assert MIN_LENGTH_2 <= length <= MAX_LENGTH_2
        body = body[:6] + struct.pack('<H', length) + body[8:]
    return body + struct.pack('<I', zlib.crc32(body))


class Reader:
    """The fields of an image of format version 2 from Pos to the CRC at
    Last, refused as EVC_Config.Get refuses them: a field running past
    the CRC a bad length, a value out of its range a bad field"""

    def __init__(self, image, pos, last):
        self.image, self.pos, self.last = image, pos, last

    def get(self, size, high, what):
        if self.last - self.pos < size:
            raise Invalid(f'bad length: {what} runs into the CRC')
        v = (self.image[self.pos] if size == 1
             else struct.unpack_from('<H', self.image, self.pos)[0])
        self.pos += size
        if v > high:
            raise Invalid(f'a field out of its range: {what} = {v}')
        return v

    def curve(self, low, what):
        n = self.get(1, MAX_STEPS, f'{what} count')
        if n < low:
            raise Invalid(f'a field out of its range: {what} count {n}')
        c = []
        for k in range(n):
            s = self.get(2, MAX_SPEED_CMS, f'{what}[{k}] speed')
            d = self.get(2, MAX_DECEL_MMS2, f'{what}[{k}] deceleration')
            if k > 0 and s <= c[-1][0]:
                raise Invalid(f'a field out of its range: {what}[{k}] '
                              'speeds not rising')
            c.append([s, d])
        return c


def decode_gamma(image, last):
    """The gamma train of an image whose CRC is at last
    (EVC_Config.Get_Gamma)"""
    r = Reader(image, 34, last)
    g = {k: r.get(2, MAX_TIME_MS, k) for k in GAMMA_TIMES}
    for k, low in GAMMA_CURVES:
        g[k] = r.curve(low, k)
    g['kdry_rst'] = [[r.get(2, MAX_FACTOR_MILLI, f'kdry_rst[{e}][{k}]')
                      for k in range(MAX_STEPS)] for e in range(10)]
    g['kwet_rst'] = [r.get(2, MAX_FACTOR_MILLI, f'kwet_rst[{k}]')
                     for k in range(MAX_STEPS)]
    g['kn_plus'] = r.curve(0, 'kn_plus')
    g['kn_minus'] = r.curve(0, 'kn_minus')
    g['m_rotating_nom'] = r.get(1, 100, 'm_rotating_nom')
    if r.get(1, 1, 'normal service sets') == 1:
        g['normal_service'] = {
            'a_sb01_mms2': r.get(2, MAX_DECEL_MMS2, 'a_sb01_mms2'),
            'a_sb12_mms2': r.get(2, MAX_DECEL_MMS2, 'a_sb12_mms2'),
            'g': [r.curve(0, f'normal_service.g[{i}]') for i in range(3)],
            'p': [r.curve(0, f'normal_service.p[{i}]') for i in range(3)]}
    if r.get(1, 1, 'by combination') == 1:
        c = {'emergency': [r.curve(1, f'by_combination.emergency[{i}]')
                           for i in range(8)],
             'service': [r.curve(1, f'by_combination.service[{i}]')
                         for i in range(8)]}
        for key in ('t_emergency_ms', 't_service_ms'):
            c[key] = [[r.get(2, MAX_TIME_MS, f'by_combination.{key}[{i}]')
                       for _ in range(2)] for i in range(16)]
        g['by_combination'] = c
    if r.pos != last:
        raise Invalid(f'bad length: the fields end at {r.pos}, the CRC at '
                      f'{last}')
    return g


def decode(image):
    """The configuration of an image, checked as EVC_Config.Decoded does
    and in its order; raise Invalid with the status it would give."""
    if len(image) < 8:
        raise Invalid('truncated: shorter than the header')
    if image[0:4] != MAGIC:
        raise Invalid('bad magic')
    version, length = struct.unpack_from('<HH', image, 4)
    if version not in (VERSION, VERSION_2):
        raise Invalid(f'bad version {version}')
    if (length != LENGTH if version == VERSION
            else not MIN_LENGTH_2 <= length <= MAX_LENGTH_2):
        raise Invalid(f'bad length {length}')
    if len(image) < length:
        raise Invalid(f'truncated: {len(image)} bytes of {length}')
    crc, = struct.unpack_from('<I', image, length - 4)
    if zlib.crc32(image[:length - 4]) != crc:
        raise Invalid('bad CRC')
    (sbc, sbf, cyl, tco, k1, i0, i1, i2, i3, add, cat, ant_a, ant_b,
     t_ms, decel) = struct.unpack_from('<BBBBH4BBBIIHH', image, 8)
    flags = [sbc, sbf, cyl, tco, add, cat]
    if (any(x > 1 for x in flags) or not 1000 <= k1 <= 5000
            or any(i > 3 for i in (i0, i1, i2, i3))
            or ant_a > 100_000 or ant_b > 100_000
            or t_ms > 60_000 or decel > 3_000):
        raise Invalid('a field out of its range')
    config = {
        'format': version,
        'brakes': {'service_brake_command': sbc == 1,
                   'service_brake_feedback': sbf == 1,
                   'feedback_from_cylinder': cyl == 1,
                   'k1_milli': k1,
                   'traction_cut_off': tco == 1,
                   'additional_brake_allowed': add == 1,
                   'regenerative_needs_catenary': cat == 1},
        'special_brakes': {k: INTERFACES[i] for k, i in
                           zip(BRAKES, (i0, i1, i2, i3))},
        'service_brake_failure': {'time_ms': t_ms, 'decel_mms2': decel},
        'antenna': {'to_cab_a_cm': ant_a, 'to_cab_b_cm': ant_b},
    }
    if version == VERSION_2:
        model, has = image[32], image[33]
        if model > 1 or has > 15:
            raise Invalid('a field out of its range: the braking model or '
                          'the special brakes')
        config['train'] = {'braking_model': MODELS[model],
                           'special_brakes': [x for i, x in enumerate(BRAKES)
                                              if has & (1 << i)]}
        if model == 1:
            config['gamma'] = decode_gamma(image, length - 4)
        elif length != MIN_LENGTH_2:
            raise Invalid(f'bad length {length} for a lambda train')
    try:
        check(config)
    except Invalid as e:
        raise Invalid(f'Table 3 violated: {e}')
    return config


def toml_list(v):
    """A list of the text form: TOML takes Python's form of a list of
    integers; a list of lists one element a line"""
    if v and isinstance(v[0], list) and v[0] and isinstance(v[0][0], list):
        return '[\n' + ''.join(f'  {x!r},\n' for x in v) + ']'
    if len(v) > 4 and isinstance(v[0], list):
        return '[\n' + ''.join(f'  {x!r},\n' for x in v) + ']'
    return repr(v)


def text(config):
    values = {'format': config['format']}
    for section in SECTIONS:
        for key, v in config[section].items():
            values[key] = ('true' if v else 'false') if type(v) is bool else v
    out = TEMPLATE.format(**values)
    if config['format'] == VERSION_2:
        t = config['train']
        out += TRAIN_TEMPLATE.format(
            braking_model=t['braking_model'],
            special_brakes='[' + ', '.join(f'"{x}"' for x in
                                           t['special_brakes']) + ']')
        if gamma_model(config):
            g = config['gamma']
            out += GAMMA_TEMPLATE.format(
                **{k: (toml_list(v) if isinstance(v, list) else v)
                   for k, v in g.items()
                   if k not in ('normal_service', 'by_combination')})
            if 'normal_service' in g:
                out += NORMAL_SERVICE_TEMPLATE.format(
                    **{k: (toml_list(v) if isinstance(v, list) else v)
                       for k, v in g['normal_service'].items()})
            if 'by_combination' in g:
                out += BY_COMBINATION_TEMPLATE.format(
                    **{k: toml_list(v)
                       for k, v in g['by_combination'].items()})
    return out


def main(argv):
    assert zlib.crc32(b'123456789') == 0xCBF43926
    try:
        if len(argv) == 2 and argv[1] == '--default':
            sys.stdout.write(text(DEFAULT))
        elif len(argv) == 3 and argv[1] == '--decode':
            with open(argv[2], 'rb') as f:
                sys.stdout.write(text(decode(f.read())))
        elif len(argv) == 3 and argv[1] == '--check':
            with open(argv[2], 'rb') as f:
                data = f.read()
            if data[:4] == MAGIC:
                decode(data)
                print(f'{argv[2]}: a valid image')
            else:
                check(tomllib.loads(data.decode('utf-8')))
                print(f'{argv[2]}: a valid text form')
        elif len(argv) == 3 and not argv[1].startswith('-'):
            with open(argv[1], 'rb') as f:
                image = encode(tomllib.load(f))
            with open(argv[2], 'wb') as f:
                f.write(image)
            print(f'{argv[2]}: {len(image)} bytes, CRC-32 '
                  f'{struct.unpack_from("<I", image, len(image) - 4)[0]:08X}')
        else:
            sys.stderr.write(__doc__)
            return 2
    except (Invalid, tomllib.TOMLDecodeError) as e:
        sys.stderr.write(f'evc_config.py: invalid: {e}\n')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
