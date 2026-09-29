#!/usr/bin/env python3
"""Convert the ERTMSFormalSpecs test frames into scenario files of ours.

ERTMSFormalSpecs (EFS) is an executable model of SUBSET-026 3.4.0 by
ERTMS Solutions under the EUPL v1.1. Its functional test frames
(ErtmsFormalSpecs/doc/specs/subset-026_test/TestFrames/*.efs_tst) drive
the model with actions and check it with expectations written in the
EFS expression language. This tool (ours, GPL-3.0 like the repository)
reads an EFS checkout and writes one scenario file per frame:

  test/efs/<slug>.scn     the frame as a line oriented scenario
  test/efs/INDEX.md       per frame: cases, steps, translated / verbatim
                          actions and expectations, clause status counts

test/efs/ holds derived data only and is under the EUPL v1.1, not the
GPL (test/efs/README.md). Deleting the folder leaves the build and every
check untouched: obj/evc_efs_test then skips, and --check skips.

Usage:
  python3 test/tools/efs_frames.py [--efs PATH]          regenerate
  python3 test/tools/efs_frames.py [--efs PATH] --check  fail if the
                                                         files differ
The EFS checkout is PATH, else $EFS_CHECKOUT, else ../ERTMSFormalSpecs
next to the repository. Standard library only; deterministic output.

The .scn format
===============
One item per line; the first word says what it is. Values are in the
units of EFS (metres, km/h, m/s², seconds) unless said otherwise; the
runner (test/src/evc_efs_test.adb) converts them.

  # ...                        comment
  frame <name>                 a test frame (one per file)
  sequence <name>              a sub-sequence of the frame
  case <name>                  a test case; its requirements follow as
  clause <phase> <status> <id> ; efs <EFS id>
                               the clause of SUBSET-026 the case refers
                               to, normalised to the numbering of
                               doc/TRACE-SUBSET-026.csv, with the phase
                               and status of its row there, and the id
                               of EFS (3.4.0 numbering); or
  clause - absent <id> ; efs <EFS id>     the matrix has no such row
  clause - other <id> ; <document>        another document (SUBSET-027,
                                          SUBSET-034, design choices)
  clause - unresolved <guid>              not found in the checkout
  step <name>                  a step of the case
  sub <name>                   a sub-step: its actions, then its
                               expectations
Actions:
  init <position m> <mode>     Testing.InitializeTestEnvironment; the
                               lines up to "end init" are the actions of
                               the EFS test environment it runs
                               (Testing.efs_ns), translated like the
                               frame's own
  end init
  set <key> <values...>        an assignment translated into a state
                               variable of ours (keys: see SET_KEYS)
  call <procedure>             an EFS procedure without effect on the
                               translated state (the model recomputes
                               derived values on it; ours at every use)
  telegram <medium> <header fields> | <packet> <fields> | ...
                               a telegram given to the BTM, flattened:
                               FIELD=value in the order of the packet,
                               the names those of our catalogue
                               (evc/language/etcs_language.toml),
                               enumerated values as numbers
  taint <area> ...             the next verbatim action changes state of
                               the area(s) the translated expectations
                               read (train, nv, track, odo, ma): the
                               runner skips the expectations on it up to
                               the next init
  efs: <expression>            an action not translated, verbatim
                               (white space collapsed outside strings)
Expectations:
  expect <function> <args...> <op> <value> [@ <attributes>]
                               a translated expectation; <op> is ==, <,
                               >, <=, >= or "in" with two bounds (the
                               EFS "X > a AND X < b"); the attributes
                               are the EFS Kind, DeadLine, CyclePhase
                               and Blocking when not the default
  expect efs: <expression> [@ <attributes>]
                               an expectation not translated, verbatim
  xfail <reason>               the next expect is a known difference
                               (EXPECTED_DIFFERENCES below): the runner
                               counts it as an expected failure, and as a
                               failure when it passes

The clause normalisation: "3.5.3.4.a" becomes "3.5.3.4 a)" when the
matrix has that row, else "3.5.3.4"; "Entry 5.4.3.2.A32.2.1" becomes
"5.4.3.2 A32"; other forms are tried as given, then without their last
component.
"""

import argparse
import collections
import csv
import glob
import os
import re
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
OUT_DIR = os.path.join(REPO, "test", "efs")
TRACE = os.path.join(REPO, "doc", "TRACE-SUBSET-026.csv")
CATALOGUE = os.path.join(REPO, "evc", "language", "etcs_language.toml")

FRAMES_REL = os.path.join("ErtmsFormalSpecs", "doc", "specs",
                          "subset-026_test", "TestFrames")
SPECS_REL = os.path.join("ErtmsFormalSpecs", "doc", "specs", "subset-026")
MESSAGES_REL = os.path.join("ErtmsFormalSpecs", "doc", "specs",
                            "messages_340", "Messages.efs_ns")

HEADER = [
    "# Derived from ERTMSFormalSpecs (ERTMS Solutions), EUPL v1.1:",
    "# see test/efs/README.md and test/efs/LICENSE. Generated by",
    "# test/tools/efs_frames.py (format in its header); do not edit.",
]

# ----------------------------------------------------------------------
# Expected differences (ours): translated expectations that are known to
# fail, each with its reason, which the converter writes on an xfail
# line before the expect line. An entry is (reason, frame, case, step,
# expectations): the names exactly, the expectations as the text of the
# expect line after "expect " and before the attributes. The runner
# prints, for a failure of a step function, whether it passes 1 cm/s
# above the speed (a step boundary); that and the analysis of each
# group are in doc/EVC-PLAN.md §11.
# ----------------------------------------------------------------------

R_STEP = ("3.13.2.2.3.1.3 (3.4.0 = 4.0): at a step boundary V1 the step"
          " below applies (AD_0 for 0 <= V <= V1); EFS BrakingModelFunction"
          " takes the step above (SpeedStep <= V)")
R_KN = ("3.13.2.2.9.2.3 (3.4.0 = 4.0): at a step boundary V1 Kn_0 applies"
        " (0 <= V <= V1); EFS takes the step above")
R_EXTENT = ("3.13.5.1 (3.4.0 = 4.0): no contribution of the special brake"
            " from the start of the track condition to the foot of the"
            " curve: ours (EVC_Profile) from the start of the area on, EFS"
            " A_brake_*(V, d) only inside the area")
R_EXTENT_STEP = (R_EXTENT + "; and the speed is a step boundary, where"
                 " 3.13.2.2.3.1.3 takes the step below, EFS the step above")
R_BNS_EB = ("EFS defect: its normal service set at a location"
            " (A_brk_service_TrackCondition) drops the eddy current brake"
            " where it is switched off for the emergency brake;"
            " 3.13.6.4.4 and 3.12.1.3 (3.4.0 = 4.0): the set of"
            " A_brake_service (V = 0) there, which the switch-off for the"
            " service brake only changes")
R_GRADIENT = ("3.13.4.2.1 (3.4.0 = 4.0): the lowest gradient under the"
              " train, front at d and rear L_TRAIN behind; EFS A_gradient (d)"
              " is the gradient at d (and ours takes M_rotating_nom 0 as"
              " not given, 3.13.4.3.2 then uses M_rotating_max)")
R_KN_GRAD = ("3.13.6.4.3: 3.4.0 subtracts Kn(V) * grad, 4.0 Kn(V) * grad /"
             " 1000 (grad per mille); ours is 4.0")
R_KN_GRAD_BNS = (R_KN_GRAD + "; and at d EFS drops the eddy current brake"
                 " from its normal service set where it is switched off for"
                 " the emergency brake (an EFS defect)")
R_UNITS = ("EFS defect: V_bec and D_bec add V_delta1 and V_delta2 in m/s to"
           " speeds in km/h (3.13.9.3.2.10, 3.4.0 = 4.0; V_delta1 and"
           " V_delta2 themselves agree)")
R_EP = ("not clear-cut, reported: 3.13.2.2.6.2 (3.4.0 = 4.0) does not say"
        " which T_brake_emergency applies when the status of the Ep brake"
        " does not affect it (interface for the service brake only): EFS"
        " takes the Ep brake as not in use, ours (EVC_Braking.Build) as in"
        " use, the shorter T_be")

EXPECTED_DIFFERENCES = [
    (R_STEP,
     'Braking models',
     'Check emergency braking model information',
     'Eddy Current + Magnetic Shoe brakes',
     ('braking_model eb 250.0 == 0.1',
      'braking_model eb 150.0 == 0.2',)),
    (R_STEP,
     'Braking models',
     'Check emergency braking model information',
     'Eddy Current + Regenerative brakes',
     ('braking_model eb 50.0 == 0.9',
      'braking_model eb 100.0 == 0.8',)),
    (R_STEP,
     'Braking models',
     'Check emergency braking model information',
     'Eddy Current brake',
     ('braking_model eb 30.0 == 0.65',
      'braking_model eb 100.0 == 0.5',)),
    (R_STEP,
     'Braking models',
     'Check emergency braking model information',
     'Magnetic Shoe + Regenerative Brakes',
     ('braking_model eb 250.0 == 0.1',
      'braking_model eb 120.0 == 0.6',)),
    (R_STEP,
     'Braking models',
     'Check emergency braking model information',
     'Magnetic Shoe brake',
     ('braking_model eb 150.0 == 0.45',)),
    (R_STEP,
     'Braking models',
     'Check service braking model information',
     'Eddy Current + Magnetic Shoe + Regenerative brakes',
     ('braking_model sb 100.0 == 0.7',
      'braking_model sb 50.0 == 0.9',)),
    (R_STEP,
     'Braking models',
     'Check service braking model information',
     'Eddy Current + Magnetic Shoe brakes',
     ('braking_model sb 100.0 == 0.55',
      'braking_model sb 30.0 == 0.65',)),
    (R_STEP,
     'Braking models',
     'Check service braking model information',
     'Eddy Current + Regenerative brakes',
     ('braking_model sb 50.0 == 0.9',
      'braking_model sb 100.0 == 0.7',)),
    (R_STEP,
     'Braking models',
     'Check service braking model information',
     'Eddy Current brake',
     ('braking_model sb 30.0 == 0.65',
      'braking_model sb 100.0 == 0.55',)),
    (R_STEP,
     'Braking models',
     'Freight train in G',
     'BNS0',
     ('braking_model nsb 250.0 == 0.3',
      'braking_model nsb 50.0 == 0.72',)),
    (R_STEP,
     'Braking models',
     'Freight train in G',
     'BNS1',
     ('braking_model nsb 200.0 == 0.27',
      'braking_model nsb 100.0 == 0.51',
      'braking_model nsb 50.0 == 0.7',
      'braking_model nsb 150.0 == 0.34',)),
    (R_STEP,
     'Braking models',
     'Freight train in G',
     'BNS2',
     ('braking_model nsb 200.0 == 0.35',
      'braking_model nsb 100.0 == 0.5',
      'braking_model nsb 250.0 == 0.3',
      'braking_model nsb 150.0 == 0.4',)),
    (R_STEP,
     'Braking models',
     'Freigth train in P / Passenger train in P',
     'BNS0',
     ('braking_model nsb 200.0 == 0.2',)),
    (R_STEP,
     'Braking models',
     'Freigth train in P / Passenger train in P',
     'BNS1',
     ('braking_model nsb 100.0 == 0.35',
      'braking_model nsb 150.0 == 0.2',
      'braking_model nsb 25.0 == 0.8',
      'braking_model nsb 75.0 == 0.5',
      'braking_model nsb 200.0 == 0.14',)),
    (R_STEP,
     'Braking models',
     'Freigth train in P / Passenger train in P',
     'BNS2',
     ('braking_model nsb 200.0 == 0.1',)),
    (R_STEP,
     'Computation of the expected deceleration',
     'Check A_brake_service values',
     'No brakes switched off',
     ('A_brake_service 150.0 1000.0 == 0.27',)),
    (R_STEP,
     'Computation of the expected deceleration',
     'Check A_brake_service values',
     'Eddy Current brake switched off',
     ('A_brake_service 250.0 1200.0 == 0.2',)),
    (R_EXTENT,
     'Computation of the expected deceleration',
     'Check A_brake_service values',
     'Regenerative brake switched off',
     ('A_brake_service 50.0 2500.0 == 0.65',
      'A_brake_service 200.0 2500.0 == 0.27',
      'A_brake_service 0.0 2500.0 == 0.8',
      'A_brake_service 250.0 2500.0 == 0.2',
      'A_brake_service 300.0 2500.0 == 0.2',)),
    (R_BNS_EB,
     'Computation of the normal service brake deceleration',
     'Check A_brake_normal_service values - Passenger  train in P',
     'Eddy Current brake switched off (BNS_0)',
     ('A_brake_normal_service 150.0 1800.0 == 0.65',
      'A_brake_normal_service 100.0 1800.0 == 0.84',
      'A_brake_normal_service 200.0 1800.0 == 0.58',
      'A_brake_normal_service 0.0 1800.0 == 0.9',
      'A_brake_normal_service 250.0 1800.0 == 0.47',
      'A_brake_normal_service 300.0 1800.0 == 0.47',)),
    (R_STEP,
     'Computation of the normal service brake deceleration',
     'Check A_brake_normal_service values - Passenger  train in P',
     'Regenerative brake switched off (BNS_2)',
     ('A_brake_normal_service 50.0 2500.0 == 0.71',
      'A_brake_normal_service 100.0 2500.0 == 0.58',
      'A_brake_normal_service 250.0 2500.0 == 0.24',)),
    (R_KN,
     'Computation of the normal service brake deceleration',
     'Check gradient profile without compensation of rotating mass',
     'Check KnMin',
     ('Kn_minus 100.0 == 0.39',
      'Kn_minus 50.0 == 0.34',)),
    (R_KN,
     'Computation of the normal service brake deceleration',
     'Check gradient profile without compensation of rotating mass',
     'Check KnPlus',
     ('Kn_plus 150.0 == 0.41',
      'Kn_plus 250.0 == 0.52',)),
    (R_STEP,
     'Computation of the safe deceleration',
     'Check A_brake_emergency values',
     'Regenerative brake switched off',
     ('A_brake_emergency 250.0 1700.0 == 0.2',)),
    (R_EXTENT,
     'Computation of the safe deceleration',
     'Check A_brake_emergency values',
     'No brakes switched off',
     ('A_brake_emergency 50.0 2000.0 == 0.95',
      'A_brake_emergency 150.0 2000.0 == 0.8',
      'A_brake_emergency 100.0 2000.0 == 0.9',
      'A_brake_emergency 200.0 2000.0 == 0.7',
      'A_brake_emergency 0.0 2000.0 == 0.999',
      'A_brake_emergency 250.0 2000.0 == 0.6',
      'A_brake_emergency 300.0 2000.0 == 0.4',)),
    (R_EXTENT,
     'Computation of the safe deceleration',
     'Check A_brake_emergency values',
     'Magnetic shoe brake switched off',
     ('A_brake_emergency 50.0 2500.0 == 0.9',
      'A_brake_emergency 100.0 2500.0 == 0.8',
      'A_brake_emergency 200.0 2500.0 == 0.5',
      'A_brake_emergency 0.0 2500.0 == 0.99',
      'A_brake_emergency 250.0 2500.0 == 0.45',
      'A_brake_emergency 300.0 2500.0 == 0.45',)),
    (R_STEP,
     'Computation of the safe deceleration',
     'Check A_brake_emergency values',
     'Magnetic shoe and regenerative brakes switched off',
     ('A_brake_emergency 150.0 3100.0 == 0.45',
      'A_brake_emergency 100.0 3100.0 == 0.5',)),
    (R_GRADIENT,
     'Computation of the safe deceleration',
     'Locations with normal adhesion conditions',
     'Check A_safe values - gradient defined',
     ('A_gradient 1400.0 == 0.03924',)),
    (R_GRADIENT,
     'Computation of the safe deceleration',
     'Locations with reduced adhesion conditions',
     'Check A_safe values - gradient defined',
     ('A_gradient 1500.0 == 0.03924',)),
    (R_EP,
     'Speed and distance monitoring',
     'Brake build up time, T_be and T_bs',
     'Disable Electro pneumatic brake for EB',
     ('T_brake_emergency == 1.82',
      'T_be 0.0 == 1.82',)),
    (R_UNITS,
     'Supervision limits',
     'Vbec',
     'Check Vbec',
     ('Vbec 88.0 90.0 == 93.824',
      'Vbec 75.0 90.0 == 91.408',)),
    (R_UNITS,
     'Supervision limits',
     'Dbec',
     'Check Dbec',
     ('Dbec 88.0 90.0 in 235.377 235.378',
      'Dbec 75.0 90.0 in 229.3767 229.3768',)),
    (R_UNITS,
     'Supervision limits',
     'd_EBI',
     'Check d_EBI',
     ('Vbec 30.0 0.0 == 34.34',
      'Vbec 30.0 20.0 == 34.34',)),
    (R_UNITS,
     'Supervision limits',
     'Vsbi2',
     'Check Vsbi2',
     ('Vbec 88.0 25.0 == 91.34',)),
    (R_UNITS,
     'Supervision limits',
     'V_P_EBD',
     'Check V_P_EBD, V_EBD',
     ('Vbec 100.0 20.0 == 103.34',)),
    (R_EXTENT_STEP,
     'Computation of the expected deceleration',
     'Check A_brake_service values',
     'Regenerative brake switched off',
     ('A_brake_service 150.0 2500.0 == 0.31',
      'A_brake_service 100.0 2500.0 == 0.38',)),
    (R_EXTENT_STEP,
     'Computation of the safe deceleration',
     'Check A_brake_emergency values',
     'Magnetic shoe brake switched off',
     ('A_brake_emergency 150.0 2500.0 == 0.6',)),
    (R_GRADIENT,
     'Computation of the expected deceleration',
     'Conversion model is used',
     'Check A_brake_safe values - gradient defined',
     ('A_expected 100.0 1500.0 in 1.12262 1.12263',)),
    (R_GRADIENT,
     'Computation of the safe deceleration',
     'Locations with normal adhesion conditions',
     'Check A_safe values - gradient defined',
     ('A_safe 100.0 1400.0 == 0.0954',)),
    (R_GRADIENT,
     'Computation of the safe deceleration',
     'Locations with reduced adhesion conditions',
     'Check A_safe values - gradient defined',
     ('A_safe 100.0 1500.0 == 0.04624',)),
    (R_BNS_EB,
     'Computation of the normal service brake deceleration',
     'Check A_normal_service',
     'Check A_normal_service',
     ('A_normal_service 0.0 700.0 == 0.9',
      'A_normal_service 100.0 700.0 == 0.84',)),
    (R_KN_GRAD_BNS,
     'Computation of the normal service brake deceleration',
     'Check A_normal_service',
     'Check A_normal_service',
     ('A_normal_service 0.0 941.0 in 0.2541 0.2542',
      'A_normal_service 100.0 941.0 in -0.5259 -0.5258',)),
    (R_KN_GRAD,
     'Computation of the normal service brake deceleration',
     'Check A_normal_service',
     'Check A_normal_service',
     ('A_normal_service 0.0 1300.0 in 1.34076 1.34077',
      'A_normal_service 100.0 1300.0 in 1.52076 1.52077',)),
]


# ----------------------------------------------------------------------
# The EFS expression language: a tokenizer and a recursive descent
# parser for the part the translation needs. Anything it does not parse
# stays verbatim.
# ----------------------------------------------------------------------

class ParseError(Exception):
    pass


TOKEN = re.compile(r"""
    (?P<ws>\s+)
  | (?P<num>\d+\.\d*(?:[eE][-+]?\d+)?|\d+(?:[eE][-+]?\d+)?)
  | (?P<str>'[^']*'|"[^"]*")
  | (?P<name>[A-Za-z_][A-Za-z_0-9]*)
  | (?P<op><-|=>|==|!=|<=|>=|[<>+\-*/(){}\[\],.|])
""", re.VERBOSE)

KEYWORDS = {"AND", "OR", "NOT", "IN", "FIRST", "LAST", "COUNT",
            "THERE_IS", "FORALL", "INSERT", "REMOVE", "REPLACE",
            "FUNCTION", "TARGETS", "REDUCE", "USING", "SUM", "MAP",
            "APPLY", "ON", "INITIAL_VALUE", "STABILIZE", "BY", "LET",
            "ALL", "IS", "AT"}


def tokenize(text):
    out = []
    pos = 0
    while pos < len(text):
        m = TOKEN.match(text, pos)
        if not m:
            raise ParseError("bad character %r" % text[pos])
        pos = m.end()
        kind = m.lastgroup
        if kind == "ws":
            continue
        out.append((kind, m.group(kind)))
    return out


def collapse(text):
    """White space collapsed to one blank outside string literals."""
    parts = re.split(r"('[^']*'|\"[^\"]*\")", text.strip())
    for i in range(0, len(parts), 2):
        parts[i] = re.sub(r"\s+", " ", parts[i])
    return "".join(parts).strip()


class Parser:
    """Nodes: ('num', text) ('str', text) ('name', dotted) ('call',
    dotted, [(argname or None, node)]) ('struct', dotted, [(field,
    node)]) ('list', [node]) ('bin', op, a, b) ('not', a) ('neg', a)
    ('empty',)"""

    def __init__(self, text):
        self.toks = tokenize(text)
        self.i = 0

    def peek(self, k=0):
        j = self.i + k
        return self.toks[j] if j < len(self.toks) else (None, None)

    def take(self, value=None):
        kind, v = self.peek()
        if kind is None or (value is not None and v != value):
            raise ParseError("expected %r, got %r" % (value, v))
        self.i += 1
        return kind, v

    def at(self, value):
        return self.peek()[1] == value

    def done(self):
        return self.i == len(self.toks)

    # expr := or
    def expr(self):
        a = self.and_()
        while self.at("OR"):
            self.take()
            a = ("bin", "OR", a, self.and_())
        return a

    def and_(self):
        a = self.not_()
        while self.at("AND"):
            self.take()
            a = ("bin", "AND", a, self.not_())
        return a

    def not_(self):
        if self.at("NOT"):
            self.take()
            return ("not", self.not_())
        return self.cmp()

    def cmp(self):
        a = self.add()
        if self.peek()[1] in ("==", "!=", "<", ">", "<=", ">=", "<-"):
            op = self.take()[1]
            a = ("bin", op, a, self.add())
        return a

    def add(self):
        a = self.mul()
        while self.peek()[1] in ("+", "-"):
            op = self.take()[1]
            a = ("bin", op, a, self.mul())
        return a

    def mul(self):
        a = self.unary()
        while self.peek()[1] in ("*", "/"):
            op = self.take()[1]
            a = ("bin", op, a, self.unary())
        return a

    def unary(self):
        if self.at("-"):
            self.take()
            x = self.unary()
            if x[0] == "num":
                return ("num", "-" + x[1])
            return ("neg", x)
        return self.primary()

    def dotted(self):
        kind, v = self.take()
        if kind != "name" or v in KEYWORDS:
            raise ParseError("name expected, got %r" % v)
        parts = [v]
        while self.at(".") and self.peek(1)[0] == "name":
            self.take(".")
            parts.append(self.take()[1])
        return ".".join(parts)

    def args(self, close):
        out = []
        if self.at(close):
            self.take(close)
            return out
        while True:
            if self.peek()[0] == "name" and self.peek(1)[1] == "=>":
                n = self.take()[1]
                self.take("=>")
                out.append((n, self.expr()))
            else:
                out.append((None, self.expr()))
            if self.at(","):
                self.take(",")
                continue
            self.take(close)
            return out

    def primary(self):
        kind, v = self.peek()
        if kind == "num":
            self.take()
            return ("num", v)
        if kind == "str":
            self.take()
            return ("str", v)
        if v == "(":
            self.take("(")
            x = self.expr()
            self.take(")")
            return self.postfix(x)
        if v == "[":
            self.take("[")
            items = [a for _, a in self.args("]")]
            return ("list", items)
        if kind == "name" and v == "EMPTY":
            self.take()
            return ("empty",)
        if kind == "name" and v not in KEYWORDS:
            n = self.dotted()
            if self.at("("):
                self.take("(")
                return self.postfix(("call", n, self.args(")")))
            if self.at("{"):
                self.take("{")
                fields = self.args("}")
                if any(f is None for f, _ in fields):
                    raise ParseError("positional field")
                return ("struct", n, fields)
            return ("name", n)
        raise ParseError("unexpected %r" % v)

    def postfix(self, x):
        # (call).Field: a member of a call result, kept as a name path
        while self.at(".") and self.peek(1)[0] == "name":
            self.take(".")
            f = self.take()[1]
            x = ("member", x, f)
        return x


def parse(text):
    p = Parser(text)
    x = p.expr()
    if not p.done():
        raise ParseError("trailing %r" % (p.peek()[1],))
    return x


# ----------------------------------------------------------------------
# Values
# ----------------------------------------------------------------------

class Untranslated(Exception):
    pass


ENUMS = {}          # "Q_DIR.Nominal" -> 1 (EFS messages, 3.4.0)


def load_enums(efs):
    path = os.path.join(efs, MESSAGES_REL)
    root = ET.parse(path).getroot()
    for el in root.iter():
        name = el.get("Name")
        if not name or el.tag not in ("Range", "Enum"):
            continue
        for ev in el.iter("EnumValue"):
            if ev.get("Value") is not None:
                ENUMS["%s.%s" % (name, ev.get("Name"))] = ev.get("Value")


def num(node):
    """A number of EFS, as its text; Infinity as inf."""
    if node[0] == "num":
        return node[1]
    if node[0] == "name" and node[1].endswith(".Infinity"):
        return "inf"
    raise Untranslated("number expected")


def boolean(node):
    if node[0] == "name":
        v = node[1].split(".")[-1]
        if v in ("True", "False"):
            return v.lower()
    raise Untranslated("boolean expected")


def enum_tail(node, prefix=None):
    if node[0] != "name":
        raise Untranslated("enumeration expected")
    if prefix and not node[1].startswith(prefix):
        raise Untranslated("enumeration of %s expected" % prefix)
    return node[1].split(".")[-1]


def message_value(node):
    """A value of a packet field: a number, or an enumerated value of
    the EFS messages as its number."""
    if node[0] == "num":
        return node[1]
    if node[0] == "str":
        return node[1]
    if node[0] == "name":
        n = node[1]
        if n.startswith("Messages."):
            key = n[len("Messages."):]
            if key in ENUMS:
                return ENUMS[key]
        if n.endswith(".True") or n == "True":
            return "1"
        if n.endswith(".False") or n == "False":
            return "0"
    raise Untranslated("packet value")


def fields(node, typename=None):
    if node[0] != "struct":
        raise Untranslated("structure expected")
    if typename and not node[1].endswith(typename):
        raise Untranslated("structure %s expected" % typename)
    return collections.OrderedDict(node[2])


# ----------------------------------------------------------------------
# Actions
# ----------------------------------------------------------------------

TD = "Kernel.TrainData.TrainData.Value."
KB = "Kernel.TrainData.BrakingParameters."
NV = "Kernel.NationalValues.ApplicableNationalValues"

# The combinations of special brakes of EFS, by the names of its model
# sets, as the index of ours (EVC_Supervision_Input.Combination_T: bit 0
# regenerative, 1 eddy current, 2 magnetic shoe, 3 Ep)
def combination(name):
    if name == "No_Special_Brakes":
        return 0
    bits = {"Regenerative": 1, "EddyCurrent": 2, "Magnetic": 4, "Ep": 8}
    c = 0
    for part in name.split("_"):
        if part not in bits:
            raise Untranslated("combination %s" % name)
        c |= bits[part]
    return c


BRAKES = {"Regenerative": "regenerative", "EddyCurrent": "eddy_current",
          "MagneticShoe": "magnetic_shoe", "Magnetic": "magnetic_shoe",
          "Ep": "ep", "EP": "ep"}


def model_steps(node):
    """A BrakingModelStruct: 'speed:accel' per ValK, in the order of K
    (EFS lower bounds of the steps, km/h; m/s²)"""
    f = fields(node, "BrakingModelStruct")
    out = []
    for k in range(7):
        v = f.get("Val%d" % k)
        if v is None:
            # the defaults of the EFS structure: Val0 0 km/h 1.0 m/s²,
            # the others Infinity (no step)
            if k == 0:
                out.append("0:0.0:1.0")
            continue
        g = fields(v, "BrakingModelValueStruct")
        s = num(g["SpeedStep"]) if "SpeedStep" in g else "inf"
        a = num(g["Acceleration"]) if "Acceleration" in g else "0.0"
        out.append("%d:%s:%s" % (k, s, a))
    return out


def cf_values(node):
    f = fields(node, "CorrectFactorValueStruct")
    return ["%d:%s" % (k, num(f["CF%d" % k]))
            for k in range(7) if "CF%d" % k in f]


def ebcl(name):
    """A confidence level Cl__99_99 of EFS as M_NVEBCL."""
    key = "M_NVEBCL.Confidence_level___" + name[len("Cl__"):]
    if key not in ENUMS:
        raise Untranslated("confidence level %s" % name)
    return ENUMS[key]


def models_set(kind, node):
    """EBModels / SBModels"""
    lines = ["set train.%s_models clear" % kind]
    if node[0] == "empty":
        return [lines[0].replace(" clear", " empty")]
    f = fields(node)
    for key, v in f.items():
        if key == "ModelSet":
            for comb, m in fields(v, "BrakingModelSetStruct").items():
                lines.append("set train.%s_model %d %s"
                             % (kind, combination(comb),
                                " ".join(model_steps(m))))
        elif key == "Kdry_rstValuesSet" and kind == "eb":
            for comb, m in fields(v, "Kdry_rstValuesSetStruct").items():
                for cl, cfs in fields(m, "Kdry_rstValuesStruct").items():
                    lines.append("set train.kdry %d %s %s"
                                 % (combination(comb), ebcl(cl),
                                    " ".join(cf_values(cfs))))
        elif key == "Kwet_rstValuesSet" and kind == "eb":
            for comb, m in fields(v, "Kwet_rstValuesSetStruct").items():
                lines.append("set train.kwet %d %s"
                             % (combination(comb), " ".join(cf_values(m))))
        else:
            raise Untranslated("model set field %s" % key)
    return lines


def times_set(kind, node):
    lines = ["set train.t_brake_%s clear" % kind]
    if node[0] == "empty":
        return [lines[0].replace(" clear", " empty")]
    for comb, v in fields(node, "T_brake_build_upSetStruct").items():
        lines.append("set train.t_brake_%s %d %s"
                     % (kind, combination(comb), num(v)))
    return lines


def bns_set(node):
    lines = ["set train.nsb clear"]
    if node[0] == "empty":
        return [lines[0].replace(" clear", " empty")]
    for key, v in fields(node, "BNSModelSetStruct").items():
        if key in ("A_SB01", "A_SB12"):
            lines.append("set train.nsb_%s %s" % (key.lower(), num(v)))
        elif key in ("TrainInP", "TrainInG"):
            pos = "p" if key == "TrainInP" else "g"
            for bns, m in fields(v, "BNSModelStruct").items():
                if not re.match(r"BNS_[012]$", bns):
                    raise Untranslated(bns)
                lines.append("set train.nsb_model %s %s %s"
                             % (pos, bns[-1], " ".join(model_steps(m))))
        else:
            raise Untranslated("BNS field %s" % key)
    return lines


# National values: the fields of NationalDefaultDataStruct translated
# as scalars, EFS name -> key of ours
NV_SCALARS = {
    "ConfLevelForEmergBrakeSafeDecelerationOnDryRails": "M_NVEBCL",
    "WeightingFactorForAvailableWheelRailAdhesion": "M_NVAVADH",
    "MaxDecelValueUnderReducedAdhesionCond1": "A_NVMAXREDADH1",
    "MaxDecelValueUnderReducedAdhesionCond2": "A_NVMAXREDADH2",
    "MaxDecelValueUnderReducedAdhesionCond3": "A_NVMAXREDADH3",
    "IntegratedCorrectionFactorForBrakeBuildUpTime": "Kt_int",
    "PermToInhibitTheCompOfTheSpeedMeasurementInaccuracy": "Q_NVINHSMICPERM",
    "PermToUseGuidanceCurves": "Q_NVGUIPERM",
    "PermToUseTheServiceBrakeFeedback": "Q_NVSBFBPERM",
    "UseServiceBrakeInTargetSpeedMonitoring": "Q_NVSBTSMPERM",
    "PermToReleaseEmergencyBrake": "Q_NVEMRRLS",
    "ModificationOfAdhesionFactorByDriver": "Q_NVDRIVER_ADHES",
    "ReleaseSpeed": "V_NVREL",
    "ShuntingModeSpeedLimit": "V_NVSHUNT",
    "StaffResponsibleModeSpeedLimit": "V_NVSTFF",
    "OnSightModeSpeedLimit": "V_NVONSIGHT",
    "LimitedSupervisionModeSpeedLimit": "V_NVLIMSUPERV",
    "UnfittedModeSpeedLimit": "V_NVUNFIT",
    "SpeedLimitForTriggeringTheOverrideFunction": "V_NVALLOWOVTRP",
    "OverrideSpeedLimitToBeSupervisedWhenOverrideIsActive": "V_NVSUPOVTRP",
    "DistForTrainTripSuppressionWhenOverrideIsTriggered": "D_NVOVTRP",
    "MaxTimeForTrainTripSuppressionWhenOverrideIsTriggered": "T_NVOVTRP",
    "DistToBeUsedInRollAwayProt_RevMvtProt_StandstillSup": "D_NVROLL",
    "DistToBeAllowedForReversingInPostTripMode": "D_NVPOTRP",
    "MaxPermDistToRunInStaffResponsibleMode": "D_NVSTFF",
    "DefaultLocationAccuracyOfABaliseGroup": "Q_NVLOCACC",
    "ChangeOfDriverIDPermittedWhileRunning": "M_NVDERUN",
    "SystemReactionIfRadioChannelMonitoringTimeLimitExpires": "M_NVCONTACT",
    "MaxTimeSinceCreationInTheRBCOfLastReceivedTelegram": "T_NVCONTACT",
}


def nv_value(node):
    """A national value: a number, or an enumerated value of the EFS
    messages as its number, or inf"""
    if node[0] == "num":
        return node[1]
    if node[0] == "name" and node[1].endswith(".Infinity"):
        return "inf"
    return message_value(node)


def nv_field(name, node):
    if name in NV_SCALARS:
        return ["set nv %s %s" % (NV_SCALARS[name], nv_value(node))]
    if name == "IntegratedCorrectionFactorKrInt":
        f = fields(node, "KrIntValueSetStruct")
        steps = []
        for k in range(5):
            v = f.get("Val%d" % k)
            if v is None or v[0] == "empty":
                continue
            g = fields(v, "KrIntValueStruct")
            steps.append("%d:%s:%s" % (k, num(g["LengthStep"]),
                                       num(g["Value"])))
        return ["set nv Kr_int %s" % " ".join(steps)]
    if name == "IntegratedCorrectionFactorKvInt_FreightTrain":
        f = fields(node, "KvIntValueSet_FreightTrainStruct")
        steps = []
        for k in range(5):
            v = f.get("Val%d" % k)
            if v is None or v[0] == "empty":
                continue
            g = fields(v, "KvIntValue_FreightTrainStruct")
            steps.append("%d:%s:%s" % (k, num(g["SpeedStep"]),
                                       num(g["Value"])))
        return ["set nv Kv_int_freight %s" % " ".join(steps)]
    if name == "IntegratedCorrectionFactorKvInt_PassengerTrain":
        f = fields(node, "KvIntValueSet_PassengerTrainStruct")
        steps = []
        out = []
        for k in range(5):
            v = f.get("Val%d" % k)
            if v is None or v[0] == "empty":
                continue
            g = fields(v, "KvIntValue_PassengerTrainStruct")
            steps.append("%d:%s:%s:%s" % (k, num(g["SpeedStep"]),
                                          num(g["ValueA"]),
                                          num(g["ValueB"])))
        out.append("set nv Kv_int_passenger %s" % " ".join(steps))
        for key in ("A_NVP12", "A_NVP23"):
            if key in f:
                v = f[key]
                out.append("set nv %s %s" % (key, "na" if v[0] == "name"
                                             and v[1].endswith(".NA")
                                             else num(v)))
        return out
    raise Untranslated("national value %s" % name)


def nv_struct(node):
    """ApplicableNationalValues <- NationalValuesStruct{...}: the fields
    not given take the defaults of the EFS structure, the values of A.3.2"""
    lines = ["set nv defaults"]
    for key, v in fields(node, "NationalValuesStruct").items():
        if key == "DataState":
            lines.append("set nv data_state %s" % enum_tail(v).lower())
        elif key == "ApplicableCountries":
            if v[0] != "list":
                raise Untranslated("countries")
            lines.append("set nv countries %s"
                         % " ".join(num(x) for x in v[1]))
        elif key in ("ApplicableStartLocation", "ApplicableStopLocation"):
            lines.append("set nv %s %s" % (
                "start" if key == "ApplicableStartLocation" else "stop",
                nv_value(v)))
        elif key == "Value":
            if v[0] == "name" and v[1].endswith("DefaultValues"):
                continue
            for k2, v2 in fields(v, "NationalDefaultDataStruct").items():
                lines.extend(nv_field(k2, v2))
        else:
            raise Untranslated("national values field %s" % key)
    return lines


TRACK_CONDITIONS = {
    "SwitchOffRegenerativeBrake": "regenerative",
    "SwitchOffEddyCurrentBrakeForSB": "eddy_current_sb",
    "SwitchOffEddyCurrentBrakeForEB": "eddy_current_eb",
    "SwitchOffMagneticShoeBrake": "magnetic_shoe",
    "PowerlessSection_LowerPantograph": "powerless_lower_pantograph",
    "PowerlessSection_SwitchOffTheMainPowerSwitch": "powerless_main_switch",
    "AirTightness": "air_tightness",
    "NonStoppingArea": "non_stopping_area",
    "TunnelStoppingArea": "tunnel_stopping_area",
    "RadioHole": "radio_hole",
    "SoundHorn": "sound_horn",
    "None": "none",
}


def list_items(node):
    if node[0] == "empty":
        return []
    if node[0] != "list":
        raise Untranslated("list expected")
    return node[1]


def track_conditions(node):
    out = []
    for it in list_items(node):
        f = fields(it, "TrackConditionInformationStruct")
        kind = enum_tail(f["Value"])
        if kind not in TRACK_CONDITIONS:
            raise Untranslated(kind)
        out.append("%s@%s+%s" % (TRACK_CONDITIONS[kind], num(f["Location"]),
                                 num(f["Length"])))
    return ["set track_conditions %s" % " ".join(out)]


def gradients(node):
    out = []
    for it in list_items(node):
        f = fields(it, "GradientStruct")
        g = f["Gradient"]
        gv = ("indefinite" if g[0] == "name" and g[1].endswith("Indefinite")
              else num(g))
        out.append("%s:%s" % (num(f["Location"]), gv))
    return ["set gradients %s" % " ".join(out)]


def adhesion(node):
    out = []
    for it in list_items(node):
        f = fields(it, "AdhesionFactorStruct")
        out.append("%s+%s:%s" % (num(f["Location"]), num(f["Length"]),
                                 message_value(f["Value"])))
    return ["set adhesion %s" % " ".join(out)]


def kn_set(key, node):
    f = fields(node, "CorFactStruct")
    out = []
    for k in range(7):
        v = f.get("Val%d" % k)
        if v is None:
            continue
        g = fields(v, "CorFactValueStruct")
        out.append("%d:%s:%s" % (k, num(g.get("SpeedStep", ("num", "0.0"))),
                                 num(g.get("Factor", ("num", "0.0")))))
    return ["set %s %s" % (key, " ".join(out))]


def tsrs(node):
    out = []
    for it in list_items(node):
        f = fields(it, "TemporarySpeedRestriction")
        out.append("%s@%s+%s:%s" % (num(f["Id"]), num(f["Location"]),
                                    num(f["Length"]), num(f["Speed"])))
    return ["set tsrs %s" % " ".join(out)]


# ---- telegrams --------------------------------------------------------

CATALOGUE_VARS = set()


def load_catalogue():
    with open(CATALOGUE, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"\[variables\.([A-Z_0-9]+)\]", line)
            if m:
                CATALOGUE_VARS.add(m.group(1))


def fields_list(node):
    if node[0] != "struct":
        raise Untranslated("structure expected")
    return node[2]


# The variables of 3.4.0 that 4.0 renamed (our catalogue has the new
# names): the speed and time of the LOA became V_EMA / T_EMA
RENAMED = {"V_LOA": "V_EMA", "T_LOA": "T_EMA"}


def catalogue_name(key):
    """The name of our catalogue for a field of an EFS packet: renamed,
    or without the index EFS gives a repeated variable (M_NVKVINT_0)"""
    if key in RENAMED:
        return RENAMED[key]
    if key not in CATALOGUE_VARS:
        base = re.sub(r"_\d+$", "", key)
        if base in CATALOGUE_VARS:
            return base
    return key


def telegram(node):
    if node[0] == "struct" and node[1] == "Messages.BTM.Message":
        inner = [v for k, v in node[2] if k == "SystemVersion2"]
        others = [v for k, v in node[2]
                  if k not in ("SystemVersion2", "BitField")]
        if len(inner) != 1 or any(v[0] != "empty" for v in others):
            raise Untranslated("BTM message")
        node = inner[0]
    f = fields_list(node)
    if node[1] != "Messages.EUROBALISE.Message":
        raise Untranslated("not a balise telegram of system version 2")
    header = []
    packets = []
    for key, v in f:
        if key == "Sequence1":
            for sub in list_items(v):
                for _, tt in fields_list(sub):          # TRACK_TO_TRAIN
                    for pname, p in fields_list(tt):    # the packet
                        if p[0] == "empty":
                            continue
                        body = []
                        flatten_packet(p, body)
                        packets.append("%s %s" % (pname, " ".join(body)))
        elif key == "BitField":
            continue
        else:
            if key not in CATALOGUE_VARS:
                raise Untranslated("header variable %s" % key)
            header.append("%s=%s" % (key, message_value(v)))
    return ["telegram balise %s" % " | ".join([" ".join(header)] + packets)]


def flatten_packet(node, out):
    """The fields of a packet structure in their order, the sequences
    (N_ITER iterations) inline"""
    for key, v in fields_list(node):
        if v[0] == "list":
            for it in v[1]:
                flatten_packet(it, out)
            continue
        if v[0] == "struct":
            flatten_packet(v, out)
            continue
        name = catalogue_name(key)
        if name == "BitField":
            continue
        if name not in CATALOGUE_VARS:
            raise Untranslated("variable %s not in the catalogue" % name)
        out.append("%s=%s" % (name, message_value(v)))


# ---- scalar assignments ----------------------------------------------

SCALAR_TD = {
    "TrainLength": ("train.length", num),
    "MaximumSpeed": ("train.v_max", num),
    "BrakePercentage": ("train.lambda", num),
    "SBCommandIsImplemented": ("train.sb_command", boolean),
    "SBFeedbackIsImplemented": ("train.sb_feedback", boolean),
    "TractionCutOffInterfaceIsImplemented": ("train.traction_cut_off",
                                             boolean),
}

BRAKE_POSITIONS = {"PassengerTrainInP": "passenger_p",
                   "FreightTrainInP": "freight_p",
                   "FreightTrainInG": "freight_g"}

INTERFACES = {"NoInterface": "none", "EB": "eb", "SB": "sb", "Both": "both"}

TIU_ACTIVE = {"RegenerativeBrakeIsActive": "regenerative",
              "EddyCurrentBrakeIsActive": "eddy_current",
              "MagneticShoeBrakeIsActive": "magnetic_shoe",
              "EPBrakeIsActive": "ep"}

# EFS procedures without effect on what the translation keeps: the
# model recomputes on them what ours computes at every use
INERT_CALLS = {
    KB + "ConversionModel.Initialize",
    KB + "ConversionModel.ComputeBasicDeceleration",
}


def assignment(lhs, rhs):
    """lhs: dotted path (blanks removed), rhs: node. Lines or raise."""
    if lhs.startswith(TD):
        f = lhs[len(TD):]
        if f in SCALAR_TD:
            key, conv = SCALAR_TD[f]
            return ["set %s %s" % (key, conv(rhs))]
        if f == "BrakePosition":
            return ["set train.brake_position %s"
                    % BRAKE_POSITIONS[enum_tail(rhs)]]
        if f == "M_rotating_nom":
            if rhs[0] == "name" and rhs[1].endswith(".NA"):
                return ["set train.m_rotating_nom na"]
            return ["set train.m_rotating_nom %s" % num(rhs)]
        m = re.match(r"(Regenerative|EddyCurrent|MagneticShoe|Ep)"
                     r"BrakeInterface$", f)
        if m:
            return ["set train.interface %s %s"
                    % (BRAKES[m.group(1)], INTERFACES[enum_tail(rhs)])]
        if f in ("EBModels", "SBModels"):
            return models_set(f[:2].lower(), rhs)
        m = re.match(r"(EB|SB)Models\.ModelSet\.(\w+)\.Val(\d)$", f)
        if m:
            g = fields(rhs, "BrakingModelValueStruct")
            return ["set train.%s_step %d %s %s %s"
                    % (m.group(1).lower(), combination(m.group(2)),
                       m.group(3), num(g["SpeedStep"]),
                       num(g["Acceleration"]))]
        m = re.match(r"EBModels\.Kdry_rstValuesSet\.(\w+)\.(Cl__\w+)$", f)
        if m:
            return ["set train.kdry %d %s %s"
                    % (combination(m.group(1)), ebcl(m.group(2)),
                       " ".join(cf_values(rhs)))]
        m = re.match(r"EBModels\.Kwet_rstValuesSet\.(\w+)$", f)
        if m:
            return ["set train.kwet %d %s"
                    % (combination(m.group(1)), " ".join(cf_values(rhs)))]
        if f in ("T_brake_emergency", "T_brake_service"):
            return times_set(f[len("T_brake_"):], rhs)
        m = re.match(r"T_brake_(emergency|service)\.(\w+)$", f)
        if m:
            return ["set train.t_brake_%s %d %s"
                    % (m.group(1), combination(m.group(2)), num(rhs))]
        if f == "NormalServiceBrakeModels":
            return bns_set(rhs)
        m = re.match(r"NormalServiceBrakeModels\.(A_SB01|A_SB12)$", f)
        if m:
            return ["set train.nsb_%s %s" % (m.group(1).lower(), num(rhs))]
        if f == "TractionModel":
            g = fields(rhs, "TractionModelStruct")
            return ["set train.traction_model %s %s"
                    % (num(g["Coefficient"]), num(g["Constant"]))]
        raise Untranslated(lhs)
    if lhs == "Kernel.TrainData.TrainData.DataState":
        return ["set train.data_state %s" % enum_tail(rhs).lower()]
    if lhs.startswith("TIU.SpecialBrakeStatus."):
        f = lhs[len("TIU.SpecialBrakeStatus."):]
        if f in TIU_ACTIVE:
            return ["set tiu.active %s %s" % (TIU_ACTIVE[f], boolean(rhs))]
        raise Untranslated(lhs)
    if lhs == "TIU.AdditionalBrakesActive":
        return ["set tiu.additional %s" % boolean(rhs)]
    if lhs == KB + "ContributionOfSpecialBrakeIsAllowed":
        return ["set config.additional_brake_allowed %s" % boolean(rhs)]
    if lhs == NV:
        return nv_struct(rhs)
    if lhs == NV + ".DataState":
        return ["set nv data_state %s" % enum_tail(rhs).lower()]
    if lhs.startswith(NV + ".Value."):
        f = lhs[len(NV + ".Value."):]
        m = re.match(r"IntegratedCorrectionFactorKvInt_PassengerTrain\."
                     r"(A_NVP12|A_NVP23)$", f)
        if m:
            return ["set nv %s %s" % (m.group(1), num(rhs))]
        return nv_field(f, rhs)
    if lhs == "Odometry.EstimatedSpeed":
        return ["set odo.speed %s" % num(rhs)]
    if lhs == "Odometry.EstimatedAcceleration":
        return ["set odo.accel %s" % num(rhs)]
    if lhs == "Odometry.NominalDistance":
        return ["set odo.position %s" % num(rhs)]
    if lhs == "Odometry.Accuracy":
        g = fields(rhs, "OdometerAccuracyStruct")
        return ["set odo.accuracy %s" % " ".join(
            "%s=%s" % (k, num(v)) for k, v in g.items())]
    m = re.match(r"Odometry\.Accuracy\.(D_ura|D_ora|V_ura|V_ora)$", lhs)
    if m:
        return ["set odo.accuracy %s=%s" % (m.group(1), num(rhs))]
    if lhs == "Kernel.TrackDescription.TrackConditions.General.TCProfile":
        return track_conditions(rhs)
    if lhs == "Kernel.TrackDescription.Gradient.Gradients":
        return gradients(rhs)
    if lhs == "Kernel.TrackDescription.AdhesionFactors.AdhFactors":
        return adhesion(rhs)
    if lhs == ("Kernel.TrackDescription.AdhesionFactors."
               "SlipperyRailSelectedByDriver"):
        return ["set adhesion.driver_slippery %s" % boolean(rhs)]
    if lhs == "Kernel.TrackDescription.Gradient.KnPlus":
        return kn_set("train.kn_plus", rhs)
    if lhs == "Kernel.TrackDescription.Gradient.KnMin":
        return kn_set("train.kn_minus", rhs)
    if lhs == "Kernel.TSR.TSRs":
        return tsrs(rhs)
    if lhs == "Kernel.MA.MA.TargetSpeed":
        return ["set ma.target_speed %s" % num(rhs)]
    if lhs in ("BTM.Message.SystemVersion2", "BTM.Message"):
        return telegram(rhs)
    raise Untranslated(lhs)


# The areas of the state the translated expectations read, by the EFS
# path an untranslated action writes (prefix match, first wins)
TAINT_PREFIXES = [
    (TD + "LoadingGauge", None),
    (TD + "AxleLoadCategory", None),
    (TD + "TractionSystems", None),
    (TD + "TrainCategories", None),
    (TD + "CantDeficiency", None),
    (TD + "NID_ENGINE", None),
    (TD + "AirTightSystem", None),
    ("Kernel.TrainData", "train"),
    ("TIU.SpecialBrakeStatus", "train"),
    ("TIU.AdditionalBrakesActive", "train"),
    ("Kernel.NationalValues", "nv"),
    ("Kernel.TrackDescription", "track"),
    ("Kernel.TSR", "track"),
    ("Kernel.MRSP", "track"),
    ("Kernel.LX", "track"),
    ("BTM.Message", "track nv ma"),
    ("EURORADIO.Messages", "track nv ma"),
    ("Odometry", "odo"),
    ("Kernel.TrainPosition", "odo"),
    ("Kernel.MA", "ma"),
    ("Testing.InitializeTrainData", "train"),
    ("Testing.InitializeElementsForMA", "ma track"),
    ("Testing.InitializeMA", "ma track"),
]


def taint_of(text):
    body = text
    m = re.match(r"\s*(INSERT|REMOVE|REPLACE)\b(.*?)\bIN\s+([\w.]+)",
                 text, re.S)
    if m:
        body = m.group(3)
    else:
        m = re.match(r"\s*([\w. ]+?)\s*(<-|\()", text)
        if m:
            body = m.group(1).replace(" ", "")
        else:
            m = re.match(r".*\)\s*\.?([\w.]*)\s*<-", text, re.S)
            if m:
                # (FIRST X IN P | ...).Field <- v: the collection P
                m2 = re.search(r"IN\s+([\w.]+)", text)
                body = m2.group(1) if m2 else ""
    for prefix, area in TAINT_PREFIXES:
        if body.startswith(prefix):
            return area
    return None


def translate_action(text, init_expansion):
    """The lines of one action: translated, or taint + efs:"""
    flat = collapse(text)
    try:
        node = parse(flat)
        if node[0] == "call" and \
                node[1] == "Testing.InitializeTestEnvironment":
            a = dict(node[2])
            pos = num(a["aTrainPosition"])
            mode = enum_tail(a["aMode"], "ModeEnum")
            return (["init %s %s" % (pos, mode)] + init_expansion
                    + ["end init"], True)
        if node[0] == "call" and node[1] in INERT_CALLS and not node[2]:
            return (["call %s" % node[1][len(KB):]], True)
        if node[0] == "bin" and node[1] == "<-":
            lhs = node[2]
            if lhs[0] != "name":
                raise Untranslated("target")
            return (assignment(lhs[1], node[3]), True)
        raise Untranslated("form")
    except (ParseError, Untranslated, KeyError):
        lines = []
        area = taint_of(flat)
        if area:
            lines.append("taint %s" % area)
        lines.append("efs: " + flat)
        return (lines, False)


# ----------------------------------------------------------------------
# Expectations
# ----------------------------------------------------------------------

def arg(args, name, pos):
    """The argument name (or at position pos when positional)"""
    for n, v in args:
        if n == name:
            return v
    positional = [v for n, v in args if n is None]
    if pos is not None and pos < len(positional) and \
            len(positional) == len(args):
        return positional[pos]
    raise Untranslated("argument %s" % name)


def is_current_ebcl(node):
    """The confidence level argument of Kdry_rst: the current one"""
    if node[0] == "name" and node[1] == (
            NV + ".Value.ConfLevelForEmergBrakeSafeDecelerationOnDryRails"):
        return True
    if node[0] == "member" and node[2] == \
            "ConfLevelForEmergBrakeSafeDecelerationOnDryRails" and \
            node[1][0] == "call" and \
            node[1][1] == "Kernel.NationalValues.CurrentNV":
        return True
    return False


def use_brake(node, kind):
    if node[0] != "call" or node[1] != KB + "UseBrakeFor_A_brake_" + kind:
        raise Untranslated("brake use")
    return enum_tail(node[2][0][1])


def select_model(node):
    """SelectBrakingModel of the brakes in use for the EB or SB models,
    or SelectBNSBrakingModel (the normal service model of the set the
    service brake model in use selects)"""
    if node[0] == "call" and node[1] == KB + "SelectBNSBrakingModel" \
            and not node[2]:
        return "nsb"
    if node[0] != "call" or node[1] != KB + "SelectBrakingModel":
        raise Untranslated("model selection")
    a = dict(node[2])
    ms = a["aModelSet"]
    if ms[0] != "name" or ms[1] not in (TD + "EBModels.ModelSet",
                                       TD + "SBModels.ModelSet"):
        raise Untranslated("model set")
    kind = "eb" if "EBModels" in ms[1] else "sb"
    word = "emergency" if kind == "eb" else "service"
    got = {use_brake(a["aRegBrakeUsed"], word),
           use_brake(a["aEddyCurBrakeUsed"], word),
           use_brake(a["aMagnBrakeUsed"], word)}
    if got != {"Regenerative", "EddyCurrent", "MagneticShoe"}:
        raise Untranslated("brake use arguments")
    return kind


SDMP = "Kernel.SpeedAndDistanceMonitoring.DecelerationCurves.Parameters."
TSM = "Kernel.SpeedAndDistanceMonitoring.TargetSpeedMonitoring."
CM = KB + "ConversionModel."


def no_a_est(args):
    v = arg(args, "NoA_est", None) if any(n == "NoA_est" for n, _ in args) \
        else arg(args, "aNoA_est", 0)
    if boolean(v) != "false":
        raise Untranslated("NoA_est")


def quantity(node):
    """The translated left side of an expectation: 'function args'"""
    if node[0] == "call":
        n, a = node[1], node[2]
        if n == KB + "BrakingModelFunction":
            kind = select_model(arg(a, "aBrakingModel", 0))
            return "braking_model %s %s" % (kind, num(arg(a, "aSpeed", 1)))
        if n in (KB + "UseBrakeFor_A_brake_emergency",
                 KB + "UseBrakeFor_A_brake_service"):
            kind = "eb" if n.endswith("emergency") else "sb"
            b = enum_tail(a[0][1], KB + "SpecialBrakeNameEnum")
            return "brake_used %s %s" % (kind, BRAKES[b])
        for f in ("A_brake_emergency", "A_brake_service",
                  "A_brake_normal_service", "A_brake_safe"):
            if n == KB + f:
                return "%s %s %s" % (f, num(arg(a, "V", None)),
                                     num(arg(a, "d", None)))
        # the deceleration of the EBD, SBD, GUI at d for the target
        # of the test environment (not due to a TSR)
        for f, key in (("A_safe", "A_safe"), ("A_expected", "A_expected"),
                       ("A_normal_service", "A_normal_service")):
            if n == KB + f:
                t = arg(a, "aTarget", None)
                if t != ("call", "Testing.DecelerationCurves."
                                 "SupervisedTarget", []):
                    raise Untranslated("target")
                return "%s %s %s" % (key, num(arg(a, "V", None)),
                                     num(arg(a, "d", None)))
        if n == KB + "Kdry_rst":
            cl = arg(a, "aM_NVEBCL", 1)
            if not is_current_ebcl(cl):
                raise Untranslated("confidence level argument")
            return "Kdry_rst %s" % num(arg(a, "V", 0))
        if n == KB + "Kwet_rst":
            return "Kwet_rst %s" % num(arg(a, "V", 0))
        if n == "Kernel.NationalValues.Kv_int":
            return "Kv_int %s" % num(arg(a, "V", 0))
        if n == "Kernel.NationalValues.Kr_int":
            return "Kr_int %s" % num(arg(a, "L", 0))
        if n == "Kernel.NationalValues.A_MAXREDADH" and not a:
            return "A_MAXREDADH"
        if n == KB + "A_ebmax" and not a:
            return "A_ebmax"
        if n == CM + "ConversionModelIsUsed" and not a:
            return "conversion_used"
        for k in ("emergency", "service"):
            for z in ("cm0", "cmt"):
                if n == "%s%sBrakes.T_brake_%s_%s" % (
                        CM, k.capitalize(), k, z) and not a:
                    return "T_brake_%s_%s" % (k, z)
        if n == CM + "EmergencyBrakes.A_brake_emergency":
            return "cm_A_brake_emergency %s" % num(a[0][1])
        if n == CM + "ServiceBrakes.A_brake_service":
            return "cm_A_brake_service %s" % num(a[0][1])
        if n in (KB + "T_be", KB + "T_bs"):
            f = n.split(".")[-1]
            return "%s %s" % (f, num(arg(a, "aTargetSpeed", 0)))
        if n in (KB + "T_brake_emergency", KB + "T_brake_service") and not a:
            return n.split(".")[-1]
        if n == "Kernel.TrackDescription.Gradient.A_gradient":
            return "A_gradient %s" % num(a[0][1])
        if n == "Kernel.TrackDescription.Gradient.KnPlus":
            return "Kn_plus %s" % num(a[0][1])
        if n == "Kernel.TrackDescription.Gradient.KnMin":
            return "Kn_minus %s" % num(a[0][1])
        if n == KB + "T_traction_cut_off":
            no_a_est(a)
            return "T_traction_cut_off"
        if n in (SDMP + "Vdelta0", SDMP + "Aest1", SDMP + "Aest2") and not a:
            return n.split(".")[-1]
        if n in (SDMP + "T_traction", SDMP + "T_berem", SDMP + "Vdelta1",
                 SDMP + "Vdelta2"):
            no_a_est(a)
            return "%s %s" % (n.split(".")[-1],
                              num(arg(a, "aTargetSpeed", None)))
        if n in (SDMP + "Vbec", SDMP + "Dbec"):
            no_a_est(a)
            return "%s %s %s" % (n.split(".")[-1], num(arg(a, "Vest", None)),
                                 num(arg(a, "Vtarget", None)))
        if n in (TSM + "T_bs1", TSM + "T_bs2"):
            return "%s %s" % (n.split(".")[-1],
                              num(arg(a, "aTargetSpeed", 0)))
        if n == ("Kernel.SpeedAndDistanceMonitoring.CeilingSpeedMonitoring.P"):
            return "ceiling_P %s" % num(a[0][1])
        for f, key in (("Kernel.TrackDescription.StaticSpeedProfile."
                        "SpeedRestrictions", "SSP"),
                       ("Kernel.TSR.SpeedRestrictions", "TSR"),
                       ("Kernel.MRSP.SpeedRestrictions", "MRSP")):
            if n == f:
                return "%s %s" % (key, num(a[0][1]))
        raise Untranslated(n)
    if node[0] == "name":
        n = node[1]
        m = re.match(re.escape(CM) + r"(Emergency|Service)Brakes\."
                     r"A_brake_(emergency|service)\.Val(\d)\."
                     r"(SpeedStep|Acceleration)$", n)
        if m:
            return "cm_%s_step %s %s" % (
                "eb" if m.group(1) == "Emergency" else "sb", m.group(3),
                "speed" if m.group(4) == "SpeedStep" else "accel")
        if n == TSM + "T_warning":
            return "T_warning"
        raise Untranslated(n)
    raise Untranslated("left side")


def value(node):
    if node[0] == "num":
        return node[1]
    if node[0] == "name":
        n = node[1]
        if n.endswith(".Infinity"):
            return "inf"
        if n in ("True", "False", "Boolean.True", "Boolean.False"):
            return n.split(".")[-1].lower()
    raise Untranslated("value")


FLIP = {"<": ">", ">": "<", "<=": ">=", ">=": "<=", "==": "=="}


def comparison(node):
    if node[0] != "bin" or node[1] not in ("==", "<", ">", "<=", ">="):
        raise Untranslated("comparison")
    try:
        return quantity(node[2]), node[1], value(node[3])
    except Untranslated:
        return quantity(node[3]), FLIP[node[1]], value(node[2])


def translate_expectation(text):
    flat = collapse(text)
    try:
        node = parse(flat)
        if node[0] == "bin" and node[1] == "AND":
            q1, o1, v1 = comparison(node[2])
            q2, o2, v2 = comparison(node[3])
            if q1 == q2 and {o1, o2} <= {"<", ">", "<=", ">="}:
                lo = v1 if o1.startswith(">") else v2
                hi = v2 if o1.startswith(">") else v1
                if o1[0] != o2[0]:
                    return ("expect %s in %s %s" % (q1, lo, hi), True)
            raise Untranslated("conjunction")
        q, o, v = comparison(node)
        return ("expect %s %s %s" % (q, o, v), True)
    except (ParseError, Untranslated, KeyError, IndexError):
        return ("expect efs: " + flat, False)


# ----------------------------------------------------------------------
# Requirements: the clause ids of the EFS specification, the matrix
# ----------------------------------------------------------------------

def load_paragraphs(efs):
    """Paragraph Guid -> (document, id)"""
    out = {}
    base = os.path.join(efs, SPECS_REL, "Specifications")
    for path in sorted(glob.glob(os.path.join(base, "**", "*.efs_ch"),
                                 recursive=True)):
        doc = os.path.basename(os.path.dirname(path))
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError:
            continue
        for p in root.iter("Paragraph"):
            if p.get("Guid") and p.get("id"):
                out[p.get("Guid")] = (doc, p.get("id"))
    return out


def load_trace():
    out = {}
    with open(TRACE, encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            out[row["clause"]] = (row["phase"], row["status"])
    return out


def normalise(efs_id, trace):
    """The row of our matrix for an EFS id (3.4.0 numbering)"""
    i = efs_id.strip()
    # the rows of the tables of appendix A.3 are 3.A3.2.1.N in EFS
    m = re.match(r"3\.A(\d+)\.(\d+)(\..*)?$", i)
    if m:
        base = "A.%s.%s" % (m.group(1), m.group(2))
        cands = [base + (m.group(3) or ""), base + " Table", base]
    else:
        m = re.match(r"Entry (\d+\.\d+\.\d+\.\d+)\.([A-Z]\d+)", i)
        if m:
            cands = ["%s %s" % (m.group(1), m.group(2)), m.group(1)]
        else:
            m = re.match(r"(.*\d)\.([a-z])$", i)
            if m:
                cands = ["%s %s)" % (m.group(1), m.group(2)), m.group(1)]
            else:
                cands = [i]
                if "." in i:
                    cands.append(i.rsplit(".", 1)[0])
    for c in cands:
        if c in trace:
            return c, trace[c]
    return cands[0], None


def clause_lines(tc, paragraphs, trace):
    """(line, status word) per requirement of a test case"""
    out = []
    for r in tc.findall("ReqRef"):
        guid = r.get("Id")
        if guid not in paragraphs:
            out.append(("clause - unresolved %s" % guid, "unresolved"))
            continue
        doc, pid = paragraphs[guid]
        if doc != "Subset 26":
            out.append(("clause - other %s ; %s" % (pid, doc), "other"))
            continue
        ours, row = normalise(pid, trace)
        if row is None:
            out.append(("clause - absent %s ; efs %s" % (ours, pid),
                        "absent"))
        else:
            out.append(("clause %s %s %s ; efs %s"
                        % (row[0], row[1], ours, pid), row[1]))
    return out


# ----------------------------------------------------------------------
# The init expansion: Testing.InitializeTestEnvironment of the model
# ----------------------------------------------------------------------

# The procedures of Testing.efs_ns (and the kernel) the test environment
# runs, in its order, that set what the translation keeps; the rest of
# it (DMI, EURORADIO, time, the balise group, the undesired movement
# references) is outside the translated state
INIT_PROCEDURES = [
    ("Testing.efs_ns", "InitializeTrainData_ERA"),
    ("Testing.efs_ns", "InitializeBrakingParameters"),
    ("Testing.efs_ns", "InitializeTrainData_BNS"),
    (os.path.join("Kernel", "NationalValues.efs_ns"), "Initialize"),
]


#: The defaults of the EFS model for what the translation keeps (the
#: Default of TrainDataValuesStruct and of its element types, of the TIU
#: variables, of the track description collections), then the actions
#: of InitializeTestEnvironment on them
EFS_DEFAULTS = [
    "# the defaults of the EFS model (TrainDataValuesStruct, TIU)",
    "set train.data_state unknown",
    "set train.length 400.0",
    "set train.v_max 150.0",
    "set train.lambda na",
    "set train.brake_position passenger_p",
    "set train.m_rotating_nom na",
    "set train.interface regenerative none",
    "set train.interface eddy_current none",
    "set train.interface magnetic_shoe none",
    "set train.interface ep none",
    "set train.sb_command false",
    "set train.sb_feedback false",
    "set train.traction_cut_off false",
    "set train.traction_model 0.0 0.0",
    "set train.eb_models clear",
    "set train.sb_models clear",
    "set train.nsb clear",
    "set train.t_brake_emergency clear",
    "set train.t_brake_service clear",
    "set train.kn_plus clear",
    "set train.kn_minus clear",
    "set tiu.active regenerative true",
    "set tiu.active eddy_current true",
    "set tiu.active magnetic_shoe true",
    "set tiu.active ep true",
    "set tiu.additional true",
    "set config.additional_brake_allowed false",
    "set track_conditions",
    "set gradients",
    "set adhesion",
    "set adhesion.driver_slippery false",
    "set tsrs",
    "set odo.speed 0.0",
    "set odo.accel 0.0",
    "set nv defaults",
    "# the EFS test environment (Testing.InitializeTestEnvironment)",
    "set odo.accuracy D_ura=0.0 D_ora=0.0 V_ura=0.0 V_ora=0.0",
]


def init_expansion(efs):
    lines = list(EFS_DEFAULTS)
    for rel, name in INIT_PROCEDURES:
        root = ET.parse(os.path.join(efs, SPECS_REL, rel)).getroot()
        proc = None
        for p in root.iter("Procedure"):
            if p.get("Name") == name:
                proc = p
                break
        if proc is None:
            lines.append("# %s not found" % name)
            continue
        lines.append("# %s" % name)
        for a in proc.iter("Action"):
            text = collapse(a.text or "")
            text = re.sub(r"^NationalValues\.",
                          "Kernel.NationalValues.", text)
            if re.match(r"Kernel\.NationalValues\.ApplicableNationalValues"
                        r"\.Value <- (Kernel\.)?NationalValues\."
                        r"DefaultValues$", text):
                lines.append("set nv defaults")
                continue
            if text.startswith("ValidateInformation"):
                lines.append("set nv data_state valid")
                continue
            got, ok = translate_action(text, [])
            if ok:
                lines.extend(got)
            else:
                lines.extend("# " + g for g in got if g.startswith("efs:"))
    return lines


# ----------------------------------------------------------------------
# Frames
# ----------------------------------------------------------------------

def slug(name):
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def attributes(e):
    out = []
    kind = e.get("Kind")
    if kind and kind != "Instantaneous":
        out.append("kind=" + kind.lower())
    for key in ("DeadLine", "CyclePhase", "Blocking"):
        if e.get(key):
            out.append("%s=%s" % (key.lower(), e.get(key)))
    return (" @ " + " ".join(out)) if out else ""


def xfail_for(frame, case, step, line):
    """The reason of a known difference of the expect line, or None"""
    text = line[len("expect "):]
    for reason, f, c, s, texts in EXPECTED_DIFFERENCES:
        if f == frame and c == case and s == step and text in texts:
            return reason
    return None


def convert_frame(path, paragraphs, trace, init_lines):
    root = ET.parse(path).getroot()
    name = root.get("Name")
    out = list(HEADER) + ["frame " + name]
    st = collections.Counter()
    for seq in root.iter("SubSequence"):
        out.append("sequence " + seq.get("Name", ""))
        for tc in seq.iter("TestCase"):
            st["cases"] += 1
            case = tc.get("Name", "")
            out.append("case " + case)
            for c, status in clause_lines(tc, paragraphs, trace):
                out.append(c)
                st["clause " + status] += 1
            for step in tc.iter("Step"):
                st["steps"] += 1
                out.append("step " + step.get("Name", ""))
                for sub in step.iter("SubStep"):
                    out.append("sub " + sub.get("Name", ""))
                    for a in sub.iter("Action"):
                        lines, ok = translate_action(a.text or "",
                                                     init_lines)
                        st["actions translated" if ok
                           else "actions verbatim"] += 1
                        out.extend(lines)
                    for e in sub.iter("Expectation"):
                        line, ok = translate_expectation(e.text or "")
                        st["expectations translated" if ok
                           else "expectations verbatim"] += 1
                        if ok:
                            reason = xfail_for(name, case,
                                               step.get("Name", ""), line)
                            if reason:
                                out.append("xfail " + reason)
                                st["xfail"] += 1
                        out.append(line + attributes(e))
    return name, "\n".join(out) + "\n", st


def index_md(rows):
    out = ["# EFS test frames: index", "",
           "Derived from ERTMSFormalSpecs under the EUPL v1.1 (README.md,"
           " LICENSE). Generated by `test/tools/efs_frames.py`; the"
           " format of the `.scn` files is in its header.", "",
           "Actions and expectations: translated into primitives of ours"
           " / kept verbatim (`efs:`). Clauses: the requirements of the"
           " cases, by the status of their row in"
           " `doc/TRACE-SUBSET-026.csv`.", "",
           "| frame | file | cases | steps | actions tr. / verb. |"
           " expectations tr. / verb. | xfail | clauses |",
           "|---|---|---:|---:|---:|---:|---:|---|"]
    total = collections.Counter()
    for name, fname, st in rows:
        cl = ", ".join("%s %d" % (k[len("clause "):], v)
                       for k, v in sorted(st.items())
                       if k.startswith("clause "))
        out.append("| %s | %s | %d | %d | %d / %d | %d / %d | %d | %s |" % (
            name, fname, st["cases"], st["steps"],
            st["actions translated"], st["actions verbatim"],
            st["expectations translated"], st["expectations verbatim"],
            st["xfail"], cl or "-"))
        total.update(st)
    cl = ", ".join("%s %d" % (k[len("clause "):], v)
                   for k, v in sorted(total.items())
                   if k.startswith("clause "))
    out.append("| **total** | %d files | %d | %d | %d / %d | %d / %d | %d |"
               " %s |" % (
                   len(rows), total["cases"], total["steps"],
                   total["actions translated"], total["actions verbatim"],
                   total["expectations translated"],
                   total["expectations verbatim"], total["xfail"], cl))
    return "\n".join(out) + "\n"


def generate(efs):
    load_enums(efs)
    load_catalogue()
    paragraphs = load_paragraphs(efs)
    trace = load_trace()
    init_lines = init_expansion(efs)
    files = {}
    rows = []
    for path in sorted(glob.glob(os.path.join(efs, FRAMES_REL,
                                              "*.efs_tst"))):
        name, text, st = convert_frame(path, paragraphs, trace, init_lines)
        fname = slug(name) + ".scn"
        files[fname] = text
        rows.append((name, fname, st))
    files["INDEX.md"] = index_md(rows)
    return files


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--efs", help="the ERTMSFormalSpecs checkout")
    ap.add_argument("--check", action="store_true",
                    help="fail if the files in test/efs differ")
    args = ap.parse_args()
    efs = (args.efs or os.environ.get("EFS_CHECKOUT")
           or os.path.join(os.path.dirname(REPO), "ERTMSFormalSpecs"))
    if args.check and not os.path.isdir(OUT_DIR):
        print("efs_frames.py --check: test/efs absent, skipped")
        return 0
    if not os.path.isdir(os.path.join(efs, FRAMES_REL)):
        if args.check:
            print("efs_frames.py --check: no EFS checkout at %s, skipped"
                  % efs)
            return 0
        print("efs_frames.py: no EFS checkout at %s (--efs)" % efs,
              file=sys.stderr)
        return 2
    files = generate(efs)
    if args.check:
        bad = []
        for fname, text in sorted(files.items()):
            p = os.path.join(OUT_DIR, fname)
            try:
                with open(p, encoding="utf-8") as f:
                    if f.read() != text:
                        bad.append(fname)
            except OSError:
                bad.append(fname)
        extra = sorted(f for f in os.listdir(OUT_DIR)
                       if (f.endswith(".scn") or f == "INDEX.md")
                       and f not in files)
        for fname in bad + extra:
            print("efs_frames.py --check: %s differs" % fname)
        if bad or extra:
            print("efs_frames.py --check: %d file(s) differ; run"
                  " python3 test/tools/efs_frames.py"
                  % (len(bad) + len(extra)))
            return 1
        print("efs_frames.py --check: %d files up to date" % len(files))
        return 0
    os.makedirs(OUT_DIR, exist_ok=True)
    for fname, text in sorted(files.items()):
        with open(os.path.join(OUT_DIR, fname), "w", encoding="utf-8") as f:
            f.write(text)
    print("efs_frames.py: %d files written to test/efs" % len(files))
    for fname in ("README.md", "LICENSE"):
        if not os.path.exists(os.path.join(OUT_DIR, fname)):
            print("efs_frames.py: test/efs/%s is missing (not generated:"
                  " restore it from git; the folder is under the EUPL"
                  " v1.1)" % fname, file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
