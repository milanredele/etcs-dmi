#!/usr/bin/env python3
"""The installation configuration of the ETCS on-board (evc/evc_config.ads)
between its readable text form (TOML) and its byte image, which
EVC_Core.Configure loads.

  evc_config.py TEXT IMAGE        the text form TEXT to the image IMAGE
  evc_config.py --decode IMAGE    the image back to the text form (stdout)
  evc_config.py --check FILE      validate a text form or an image
  evc_config.py --default         the text form of EVC_Config.Default

The image (format version 1, 36 bytes, little endian) and its rules are
those of evc/evc_config.ads: magic "EVCF", version u16 = 1, length u16 =
36, the fields, CRC-32 of IEEE 802.3 (zlib's crc32) over bytes 0 .. 31.
The tool validates like the on-board does: every field in its range and
Table 3 of SUBSET-026 3.13.2.2.6.1 (magnetic shoe brake: no interface or
the emergency brake model only; Ep brake: not the emergency brake model
only). An invalid input is refused with the reason, exit status 1.

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


class Invalid(Exception):
    pass


def check(config):
    """Validate a configuration of the text form (a dict as tomllib gives
    it); raise Invalid with the reason."""
    if set(config) != {'format'} | set(SECTIONS):
        raise Invalid('sections: expected format and ' +
                      ', '.join(SECTIONS) + ', got ' + ', '.join(config))
    if config['format'] != VERSION:
        raise Invalid(f'format {config["format"]!r}: only {VERSION}')
    for section, keys in SECTIONS.items():
        values = config[section]
        if not isinstance(values, dict) or set(values) != set(keys):
            raise Invalid(f'[{section}]: expected the keys ' +
                          ', '.join(keys))
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


def encode(config):
    check(config)
    b, s = config['brakes'], config['special_brakes']
    f, a = config['service_brake_failure'], config['antenna']
    body = MAGIC + struct.pack(
        '<HHBBBBH4BBBIIHH', VERSION, LENGTH,
        b['service_brake_command'], b['service_brake_feedback'],
        b['feedback_from_cylinder'], b['traction_cut_off'], b['k1_milli'],
        *(INTERFACES.index(s[k]) for k in BRAKES),
        b['additional_brake_allowed'], b['regenerative_needs_catenary'],
        a['to_cab_a_cm'], a['to_cab_b_cm'], f['time_ms'], f['decel_mms2'])
    assert len(body) == CRC_OFFSET
    return body + struct.pack('<I', zlib.crc32(body))


def decode(image):
    """The configuration of an image, checked as EVC_Config.Decoded does
    and in its order; raise Invalid with the status it would give."""
    if len(image) < 8:
        raise Invalid('truncated: shorter than the header')
    if image[0:4] != MAGIC:
        raise Invalid('bad magic')
    version, length = struct.unpack_from('<HH', image, 4)
    if version != VERSION:
        raise Invalid(f'bad version {version}')
    if length != LENGTH:
        raise Invalid(f'bad length {length}')
    if len(image) < LENGTH:
        raise Invalid(f'truncated: {len(image)} bytes of {LENGTH}')
    crc, = struct.unpack_from('<I', image, CRC_OFFSET)
    if zlib.crc32(image[:CRC_OFFSET]) != crc:
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
        'format': VERSION,
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
    try:
        check(config)
    except Invalid as e:
        raise Invalid(f'Table 3 violated: {e}')
    return config


def text(config):
    values = {'format': config['format']}
    for section in SECTIONS:
        for key, v in config[section].items():
            values[key] = ('true' if v else 'false') if type(v) is bool else v
    return TEMPLATE.format(**values)


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
                  f'{struct.unpack_from("<I", image, CRC_OFFSET)[0]:08X}')
        else:
            sys.stderr.write(__doc__)
            return 2
    except (Invalid, tomllib.TOMLDecodeError) as e:
        sys.stderr.write(f'evc_config.py: invalid: {e}\n')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
