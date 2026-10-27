# The RBC's interface to the interlocking, and the harness an RBC needs (2026-10-27)

The second study after [RBC-ESTIMATE.md](RBC-ESTIMATE.md). That document's
scope section names the interlocking interface as the first fact that would
narrow its estimate; this study is that fact.

**Is there a well defined interface to interlockings?** Not in ETCS.
SUBSET-026 states only what the RBC must do with route information and leaves
the interlocking to "external trackside systems ... for which no
interoperability requirement will be established" (2.4.1.3 d)). Its interface
figure puts no subset between the RBC and the interlocking, but SUBSET-039
and -098 between two RBCs (2.5.3, Figure 1, PDF page 11). EuroRadio reserves
an application type for "RBC-Interlocking communication" under "National use
for trackside equipment" (SUBSET-037 6.3.4.6.4, Table 3). It does not define
the content. Outside ETCS, the EULYNX interface SCI-RBC is the published,
supplier-neutral one, but every detail of it below is from memory,
unverified. For a supplier building against EULYNX, the interface is
well defined, with a functional and a form-fit specification to build to. For
this project, it is well defined enough to give the shape of a mock: route
states, section states, element states and the RBC's few answers. There is no
public test suite for it, and its documents are not under `doc/SRS`.

**Does the harness need a full interlocking mock and a large track
simulator?** No. Every RBC function in SUBSET-026 can be exercised on a
layout of about 15 sections: a line of blocks, one junction, a station with
two platform tracks and a crossover, and one RBC border. A large station adds
scale (routes, elements and trains to bound, and cycle time), but no new
function. The mock is a route table set by a script and released by the
simulated trains' passage, and it checks nothing. The interlocking's own logic
(locking tables, flank protection, conflicts) stays out: the script sets only
consistent routes. The simulator needs a graph of sections and points where
`sim/` has a line, with each train kept one-dimensional along its path. This
adds about 3.5k lines of harness to the estimate, about 3 rounds.

## What ETCS specifies

`clause.py --grep interlocking` finds 18 lines. Chapter 3 has only 3.8.1.1
d) (the overlap "if used in the existing interlocking system") and 3.8.1.5
(the section, end section and overlap time-outs mirror the interlocking's
route release and overlap revocation). Chapter 5 has 5.8.1.2 ("lost
connection with the interlocking") and 5.15.2.2.3 (the handing over RBC's MA
from "the trackside equipment and interlocking of its own area").
SUBSET-035, -040, -041, -125 and -130 never name it. The other obligations
are stated from the train's side: the danger point at an occupied block or a
fouling point (3.8.1.3), route suitability (3.12.2), emergency stops (3.10,
messages 15, 16), Request to Shorten MA (message 9), SR and SH
authorisations (messages 2, 28) and track ahead free (3.15.5, messages 34,
149). Train separation may be the RBC's own (2.6.6.1.4). Not under
`doc/SRS`: SUBSET-039, -098 (cited in 3.15.1.5.2), any EULYNX or national
document.

## The interfaces that exist

None of the six permitted web fetches verified a document. eulynx.eu's home,
deliverables and documents pages name no SCI-RBC, RaSTA or Eu.Doc number, and
say the specifications are on a members' platform. ERA's CCS TSI page lists
no subsets. Every "from memory" row below is unverified.

| Name | Owner | Status | What it carries | Transport |
|---|---|---|---|---|
| RBC-Interlocking application type | UNISIG, SUBSET-037 Table 3 | verified (doc/SRS) | an application type and ETCS ID type only, content national | EuroRadio |
| EULYNX SCI-RBC | EULYNX consortium of infrastructure managers | from memory, unverified (number, baseline: Baseline 4, release unknown) | route / "ETCS route" states, section (TVPS) occupancy, point positions, emergency stop areas, level crossings; RBC answers: MA over a route, its revocation | SCP over RaSTA (DIN VDE V 0831-200) |
| National RBC–interlocking interfaces (DB ESTW–RBC, Network Rail, RFI, ProRail before EULYNX) | each infrastructure manager | from memory, unverified | the same content in national form | national safe protocols |
| Single-supplier interfaces (an RBC and an interlocking of one supplier) | the supplier | from memory | proprietary, often a shared process or bus | proprietary |
| SUBSET-039 / SUBSET-098 | UNISIG | verified as cited (2.5.3, 3.15.1.5.2), not imported | RBC to RBC handover, not the interlocking | SUBSET-098 safe interface |

## What the RBC consumes

`doc/TRACE-SUBSET-026.csv` holds only the on-board rows, so its trackside
column marks the 425 shared rows (chapter 7: 306, 8: 69, 3: 45); the
estimate's 917 trackside rows come from its own parse of the whole text.

| Input | For (SUBSET-026) | Source |
|---|---|---|
| Route set and locked, its sections, its end | EOA / LOA, sections of packet 15 (3.8.1.1 a), f)) | interlocking |
| Section occupancy | danger point at an occupied block (3.8.1.3) | interlocking, or the RBC from position reports and integrity (2.6.6.1.4) |
| Point positions, fouling points | danger point (3.8.1.3), route-dependent data | interlocking (positions), track database (geometry) |
| Overlap locked, its release | 3.8.1.1 d), overlap timer 3.8.1.5 c) | interlocking |
| Route release, revocation | section / end section timers (3.8.1.5 a), b)), message 9 | interlocking (signalman), RBC confirms the MA shortened |
| Route type (on sight, shunting route) | mode profile, SH authorisation (5.6) | interlocking |
| Level crossing state | packet 88 | interlocking or LX |
| Emergency stop | 3.10, messages 15 / 16 | interlocking, operator |
| SSP, gradients, linking, track conditions, suitability, level borders, RBC border | 3.11, 3.12.2, 3.7, 5.10.3 | track database, per route |
| TSR, texts | 3.11.5, 3.12.3 | operator |
| Position, integrity, train data, MA requests | 3.6.5, 5.4, 3.8.2 | trains |
| Route information beyond the border | 5.15.2.2.3 b), 3.15.1.2.3 | accepting RBC (SUBSET-039 / 098) |

## The harness

**Today.** `sim/` has 5821 lines. `EVC_Track` (221 lines) is one line of
locations: a preset holds 6 balise groups, the EOA at 10000 m, three MRSP
segments and four gradients. `S076_Bench` (2238 lines) runs one train on a
straight track with the telegrams and messages of the sequence's file.
`EVC_Core` keeps its state in package variables, so one process holds one
on-board: N trains are scripted trains (the codec sending position reports
and MA requests) or N processes behind the TCP hub.

**The sequences as the RBC's tests.** 525 of the 1144 sv30 sequences carry
RBC messages, among them:

| Feature (SRS section) | Sequences with radio |
|---|---|
| 3.5, sessions | 25 of 29 |
| 3.6, position reports | 23 of 27 |
| 5.4, start of mission | 26 of 31 |
| 5.10, level transitions | 20 of 36 |
| 3.8, MA | 18 of 22 |
| 3.15, handover and TAF | 15 of 22 |
| 3.18 | 8 of 9 |
| 3.10, emergency stops | 1 of 1 |

Driven in reverse by a script of orders, with each MA's content taken from
the sequence's packets, they need no interlocking. They test the sessions,
version, acceptance, acknowledgements, MA request parameters and timers,
emergency stops, transition orders, and the train-facing half of the
handover. The MA builder is tested only where its input is a route: computing
packet 15, overlaps, timers, revocation, release behind the train, two trains.
That is where the mock is needed.

**Which shape each function needs.**

| RBC function | Plain line of blocks | Junction (two routes, one platform) | Station (two platforms, crossover) |
|---|---|---|---|
| MA by sections, position reports, train table, section / end section timers | yes | | |
| Level transitions, emergency stops, LX, handover at an RBC border | yes | | |
| Danger point at a fouling point, overlap and its timer, route release behind the train, revocation (message 9), two trains on converging routes, route suitability | | yes | |
| On sight into an occupied platform, shunting area (SH), TAF at a platform, a second train using the crossover | | | yes |

**The mock** (about 1.2k lines) is a route table (sections, point positions
per route, overlap, end) whose states (set, locked, occupied, released) a
script sets, released automatically as the simulated trains clear the
sections, with revocation, emergency stops and a lost link on command, and a
signal aspect only if the RBC reads one; an internal message set shaped like
SCI-RBC behind the kernel's interface.

**The simulator** (about 2k lines, against the 575 of `EVC_Track` and
`Sim_Trackside`) is a graph of sections joined through points, balise groups
placed per section, each train one-dimensional along the path its points
give and reporting occupancy to the mock. The layout is read through the
RBC's own track database loader (0.8k of glue); the scripted trains add 1k.

**The smallest layout:**

```
 L1 | L2                                  RBC A | RBC B
 [B1]-[B2]-[B3]-[B4]--J--[P1 platform 1]--X--[B5]-[B6] | [B7]-[B8]
                       \  [P2 platform 2]-/
                        \--[B9 branch, axle load limit]
                 LX at B3, shunting area on P2
```

It has about 15 sections, 3 points, about 10 routes and 2 or 3 trains.

## What this moves in the estimate

The estimate's interlocking part is 3k kernel lines plus a 1.5k simulator.
This study keeps the kernel's 3k for an internal route-state interface. The
harness part becomes about 5k (mock 1.2k, graph 2k, scripted trains 1k,
loader glue 0.8k), +3.5k. That moves the likely harness from 25k to 28.5k
and the rounds from 49 to about 52 (1700 to 1800 USD). Two things do not
move the estimate: a large station (data, not code) and the reverse replay
(the risk falls, the lines do not). A real SCI-RBC adds about 3k kernel
lines, 3 rounds, with RaSTA counted with the EuroRadio safety layer at the
high end.

## What to verify next

- The EULYNX SCI-RBC specification: its Eu.Doc number, baseline and
  release, the FIS and FFFIS, and whether the RBC confirms revocations.
- SUBSET-039 and SUBSET-098 (ERA CCS TSI Annex A), to import under
  `doc/SRS`.
- RaSTA, DIN VDE V 0831-200, only if the safety layer comes into scope.
- The national interface of the line the user has in mind, if there is one:
  it decides between the internal interface and SCI-RBC.
