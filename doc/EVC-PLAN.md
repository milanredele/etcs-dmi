# ETCS on-board (EVC) — Plan

> **Status (2026-09-28):** E0 closed (§5), E1 closed (§6), E2 closed
> (§7), E3 integrated and merged (§8 plan, §9 outcome); its follow-up
> `e3/pbd` (3.11.11) runs. Next: E4 (modes and procedures, level 1).
> The DMI is complete for its scope (PLAN.md §7 closed 2026-09-26). This
> document plans the second product of the repository: an ETCS on-board
> implementing SUBSET-026 v4.0.0, runnable on a microcontroller of the
> TI Hercules family, tested with the same bench and the same discipline
> as the DMI.

## 1. What the on-board is, and what it is not

SUBSET-026 ([doc/SRS/SUBSET-026_v400](SRS/SUBSET-026_v400/README.md))
specifies the ETCS on-board *logic*. Everything below it is in other
subsets, which are interfaces the on-board uses, not behaviour it owns:

| Interface | Subset | In this project |
|---|---|---|
| Eurobalise air gap, telegram coding | SUBSET-036 | Out. The BTM port delivers decoded telegrams (the bit string of chapter 8.4.2 after the 1023/341 bit decoding). |
| Euroradio, safety layer, FRMCS | SUBSET-037 | Out. The RTM port delivers chapter 8 radio messages; session set-up of 3.5 is in, the safety layer (SaPDU, keys) is not. |
| Odometry accuracy | SUBSET-041 | Out. The odometer port delivers distance, speed, their confidence intervals and the direction; `sim/` models the errors. |
| Train interface (brakes, traction, cab, doors, pantograph, main switch…) | SUBSET-034 | Out. The TIU port carries the signals SUBSET-034 names, as typed Ada values. |
| Juridical recording | SUBSET-027 | Out. The JRU port receives the events the on-board must record; no file format. |
| STM / national systems | SUBSET-035 | Out, as for the DMI (PLAN.md scope decision). Level NTC and mode SN exist as level and mode; no STM interface. |
| ATO on-board | SUBSET-125, SUBSET-130 | Out of the EVC. The ATO of `sim/evc_ato` becomes a separate module on the ATO port with the ETCS-side conditions of 4.4.16 and 3.15.11. |
| Safety case | — | The code is structured for it (static memory, cyclic executive, no exception propagation, SPARK kernel with proofs). It is not certified and the README says so. |

Scope of the SRS itself: levels 0, 1 and 2 in full; Euroloop and radio
infill (3.9) deferred; chapter 6 (system versions X = 1 and X = 2) as a
late phase; chapter 9 is the coverage matrix (§4).

The subsets above are public at
[ERA, CCS TSI Appendix A](https://www.era.europa.eu/era-folder/1-ccs-tsi-appendix-mandatory-specifications-etcs-b4-r1-rmr-gsm-r-b1-mr1-frmcs-b0-ato-b1);
those needed for the port definitions are imported under `doc/SRS/` as they
are used. SUBSET-076 (test cases and sequences) is the validation material
for E3 to E5.

## 2. Architecture

Same shape as the DMI, because that shape is proven to build on the host,
on wasm32 and on a light runtime, and to be testable headless:

- **Pure core** `EVC_Core` in `evc/`: `Initialise`, `Handle_Input (Port,
  Payload)`, `Tick (Dt_Ms)`, `Take_Outputs`. No tasking, no exception
  propagation, no `Interfaces.C`, no allocation. Every store is bounded by
  the packet iteration limits of chapter 7 (`N_ITER` is 5 bits) or by a
  documented engineering constant.
- **Ports** are an enumeration: BTM, RTM, odometer, TIU, DMI, ATO, JRU.
  Inputs arrive as byte payloads of documented shape (as the DMI protocol
  does), outputs leave the same way. The hosted, wasm and target glue only
  moves bytes.
- **Cyclic executive** with a fixed period. One tick does, in this order:
  read the ports, update the position, evaluate stored information, speed
  and distance monitoring, mode machine, produce outputs. The order is part
  of the specification of the goldens.
- **ERTMS/ETCS language as data**: a bit-level codec driven by tables of
  variables and packets, generated into Ada from the chapter 7 markdown by
  a Python tool next to `import_subset026.py`, the way fonts are generated.
- **Traceability**: the on-board column of chapter 9 imported into a table
  of clauses with a status each (§4). It is the coverage matrix and the
  audit tool.
- **Verification**: `evc_test`, a golden runner where a golden is the
  recorded output of a scenario (the byte stream of every port), plus the
  DMI frame goldens through the real chain; `evc_fuzz` with the `raised:
  0` rule; gnatprove on the kernel packages for absence of run-time errors,
  and functional contracts where the SRS states a property directly (limits
  ordered, a mode transition only from its source modes, …).
- **SPARK**: `SPARK_Mode (On)` on `evc/` from the first package. What leaves
  SPARK is stated per unit with the reason. The proof runs in the regular
  check (`gnatprove -P etcs_evc.gpr`), not as an afterthought.

### Repository layout (E0)

```
common/        DMI–EVC protocol, frame reassembly (shared)
dmi/           the DMI (was src/)
evc/           the ETCS on-board
sim/           environment: track, train, driver, ATO, EVC_Mock
ports/hosted/  native TCP mains
test/src/      dmi_test, dmi_fuzz, evc_test, evc_fuzz, host helpers
test/wasm/     browser bench and wasm glue
etcsdmi.gpr    host build of everything (Alire crate)
etcs_evc.gpr   the on-board alone: cross build and proof
```

`EVC_Mock` (was `sim/evc_core`) is the simplified on-board the DMI goldens
were recorded against. It stays as the reference until E4, and every
DMI-visible difference between it and the on-board is a decision, not an
accident.

## 3. Phases

| Phase | Content | SRS | Size |
|---|---|---|---|
| **E0 Foundation** | Repository split, `EVC_Core` skeleton with ports and scheduler, `evc_test` and `evc_fuzz`, SPARK and gnatprove in the build, chapter 9 matrix, cross build for arm-eabi, this plan | 9 | M |
| **E1 Language** | Codec generator, all track-to-train and train-to-track packets, radio messages, telegram fixtures, round trips, fuzz | 7, 8, A.3.11 | L |
| **E2 Position** | Balise groups, linking, train position and confidence interval, relocation, odometer accuracy monitoring, cold movement, train orientation | 3.4, 3.6, 3.15.8, 5.12 | L |
| **E3 Supervision** | SSP, ASP, TSR, gradients, completeness of stored data, use of the MA on board, conversion models, brake build-up, MRSP, EBD/SBD/GUI curves, supervision limits, commands, perturbation location, brake command handling, roll away protection. Replaces the constant-deceleration mock | 3.7, 3.8.4, 3.11, 3.12 (except 3.12.3), 3.13, 3.14, A.3.1, A.3.7 to A.3.10, A.3.12, A.3.13 | XL |
| **E4 Modes and procedures, level 1** | All 17 modes, 4.6 transitions, 4.8 acceptance, 4.10 stored information, 4.12 brakes, SoM and EoM in L0/L1, SH, override, OS, level transitions, trip, reversing, LS, SM, LX, track conditions and 5.20 outputs, train data changes, text messages | 4, 5 (except 5.12, 5.15), 3.12.3, A.3.3 to A.3.6 | XL |
| **E5 Radio, level 2** | Session management, MA request and update, co-operative shortening, emergency messages, position reports, handover, radio data consistency, SoM in L2, RBC simulator in `sim/` | 3.5, 3.8 (except 3.8.4), 3.10, 3.15.1, 3.16.3, 5.15 | L |
| **E6 Special functions and data** | Non-leading engines, splitting and joining, TAF, big metal mass, VBC, advance route information, system version, national values, train data and data view, balise consistency, juridical data port | 3.15 (rest), 3.16 (except 3.16.3), 3.17, 3.18, 3.20, A.3.2 | L |
| **E7 Compatibility** | Older system versions X = 1 and X = 2; Euroloop and radio infill if wanted | 6, 3.9 | L, deferrable |
| **E8 Hercules** | TMS570LC43x LaunchPad, `gnat_arm_elf` with a light runtime for TMS570 (bb-runtimes), RTI timer executive, ESM and lockstep fault reporting, DMI link over Ethernet with CRC and sequence numbers, memory and timing measurements | — | L |

Level 1 is drivable at the end of E4, level 2 at the end of E5. E1 and E2
are independent and can run as parallel branches, like the P4 branches of
the DMI. E3 is the critical path.

### Decisions taken

- **Target**: TMS570LC4357 (Cortex-R5F lockstep, 512 kB RAM, 4 MB flash).
  The TMS570 family is big-endian: multi-byte fields on any wire are read
  and written byte by byte, as the DMI protocol already does, never by
  overlay.
- **Arithmetic**: integers only under `evc/` (revised 2026-09-28, after
  E2). Distances are cm, speeds cm/s, accelerations mm/s², times ms,
  factors in thousandths, in 64-bit integers with saturation
  (`EVC_Distances`). The curves of 3.13 are computed in fixed point with
  an integer square root. Reasons: bit-identical results on host, wasm
  and target come for free; the proof of absence of run-time errors
  stays in the integer theory the provers handle well; the light runtime
  restriction `No_Floating_Point` holds. The precision is documented
  where a curve is computed and checked against the ERA braking curve
  workbook of SUBSET-076 in E3.
- **Formal verification**: SPARK on the safety kernel (position, speed and
  distance monitoring, brake commands, mode machine, codec) and wherever a
  proof is cheaper than a test; the host-only tooling and the bench are
  not SPARK.

## 4. Coverage matrix

[doc/TRACE-SUBSET-026.csv](TRACE-SUBSET-026.csv) lists every clause
chapter 9 classifies as an on-board requirement (2398 of the 5466 clauses
it classifies), with the chapter 9 flags, the phase of §3, a status and a
note. [doc/SRS/tools/trace_subset026.py](SRS/tools/trace_subset026.py)
produces it from the chapter 9 markdown; `--compare` re-reads the PDF
with a second parser and confirms every flag of every clause (0
differences at import), `--check` validates the file and prints the
counts per chapter, phase and status. The statuses are kept by hand and
preserved when the tool is rerun. Statuses:

| Status | Meaning |
|---|---|
| `todo` | not started |
| `partial` | implemented in part; the note says what is missing |
| `done` | implemented, with a scenario or a proof the note names |
| `n/a` | not applicable to this project; the note gives the reason (scope table of §1) |
| `deferred` | planned in a later phase; the note names it |

A phase is closed when every clause it lists is `done`, `n/a` or `deferred`
with a reason, and `evc_test`, `evc_fuzz`, `dmi_test`, `dmi_fuzz`,
gnatprove and the wasm smoke check are green.

## 5. E0 — Foundation: outcome (2026-09-27)

Four parallel branches on top of the repository split, merged into
`e0/foundation`.

**Core** (`evc/`, 1.25 kloc, six units, all `SPARK_Mode => On`, none
`Off`): `EVC_Core`, `EVC_Modes`, `EVC_Ports`, `EVC_DMI_Port`,
`EVC_Outbox`, `EVC_Bytes`. `common/` is not used by the on-board: it
frames the DMI protocol itself, byte by byte, and `evc_test` checks its
constants against `common/dmi_protocol.ads`. Behaviour: power-up in NP,
NP → SB (4.6.2 condition [4]), isolation by the driver from any mode
(condition [1], driver action 20, absorbing per 4.4.3.1.3), every cycle
MSG_MODE_LEVEL and MSG_ONBOARD on the DMI port, a JRU record per mode
change, national values at the A.3.2 defaults. The whole 4.6.2 table is
data in `EVC_Modes.Transitions` with priorities; it was checked against
the transition list rebuilt from the PDF page (159 transitions, no
difference). Inputs are latched and read at the start of the next Tick;
BTM and RTM inputs are checked for shape only (E1 decodes them); the
odometer and TIU shapes are provisional until E2 and E4.

**Proof**: `evc/prove.sh`, gnatprove 15.1.0 (Alire, installed outside
the repository), `--mode=all --level=2`: 289 checks, 0 unproved, 0
justified (129 run-time checks, 54 functional contracts, 12 assertions,
35 termination, 59 flow). Proven properties include: Tick never leaves
NP, a mode changes only along a 4.6.2 transition, IS is absorbing, from
NP the next mode is IS when isolation was requested and SB otherwise,
Handle_Input never changes the mode, Take_Outputs stays in its buffer
and outputs nothing once failed.

**Tests**: `evc_test` 132 checks, six goldens under `test/golden/evc/`;
`evc_fuzz` 10^6 steps, 0 raised, 0 contract violations. End to end: the
on-board's DMI output fed into `DMI_Core` draws the same start-up frame
as `EVC_Mock`, pixel for pixel, except area E1: the mock reported its
radio as connected from the start (ST03), the on-board has no session in
SB and shows nothing. `dmi_test` 2156 and `dmi_fuzz` unchanged; the wasm
bench builds and its smoke check is identical (evc/ is not in the wasm
build yet).

**Hosted main**: `ports/hosted/evc.adb`, built as `obj/evc_onboard`
(`obj/evc` is the object directory of `etcs_evc.gpr`), takes the hub
port of `evc_sim`.

**Cross build** (`ports/tms570/`): `gnat_arm_elf` 16.1.0 from Alire
(`alr get`, under `~/.local/share/etcs-dmi`, alr's defaults untouched)
with the shipped `light-tms570lc` runtime (Cortex-R5F, `-mbig-endian
-mbe32`, VFPv3-D16 hard float). Two fixes were needed and are made by
`setup-toolchain.sh`: the shipped light runtime has no `Ada.Streams`
(copied from the `embedded-tms570lc` runtime and rebuilt; `common/`
needs it, `evc/` does not), and the FSF toolchain has no big-endian
libgcc (built from the GCC 16.1 sources, about four minutes). `build.sh`
compiles `etcs_evc.gpr` for the target: 12.9 kB code, 2.2 kB data for
the E0 skeleton. Findings for later: `Stream_Element_Offset` is 64-bit
and drags in `__aeabi_ldivmod`, so kernel index arithmetic stays in
32-bit types; there is no exception propagation on the board, a failed
check halts it, which is why the proof is not optional.

**Coverage matrix**: 2398 on-board clauses (§4), all `todo` except the
156 of E7 (`deferred`) and the two general rules of chapter 1 (`n/a`).
Per phase: E1 380, E2 184, E3 426, E4 766, E5 219, E6 265, E7 156.

**Specifications imported** under `doc/SRS/`, all as PDF plus markdown
with an index, by the general `doc/SRS/tools/import_subset.py`: see
[doc/SRS/README.md](SRS/README.md). SUBSET-034 (TIU signals), 041
(performance values) and 130 (ATO packets) carry tables of what the ports
take from them. SUBSET-125 is at 1.1.0 on the ERA page. In 125 and 130
the clause numbers are images in the PDF and were read back with OCR,
checked by sequence and outline.

**SUBSET-076 for validation** (not committed, 2.2 GB of zips): part 5-2
is 613 test case PDFs per SRS feature and system version envelope (SV21,
SV22, SV30); part 6-3 is 3191 test sequences, each a PDF with the step
table (distance, level and mode before and after, event, interface),
every balise telegram and RBC message variable by variable, every DMI
event, an SVG of the speed profile, and for 772 of them the ERA braking
curve workbook. There is no machine-readable format: the telegram and
message tables can be parsed from the PDF text, the expected reactions
are sentences to translate into bench checks. Plan for E3: a converter
from a 6-3 sequence PDF to an `evc_test` scenario, starting with the
stimuli.

**Open points carried forward**
- E1: the codec generator; BTM/RTM payload shapes become the decoded
  telegram and message.
- E2/E4: the odometer and TIU port shapes (SUBSET-041, SUBSET-034) replace
  the provisional ones; the desk is taken as open until the cab signals
  are used.
- E8 list from the cross build: startup with ECC initialisation and
  self-tests (MINITGCR/MSINENA, STC, PBIST, flash ECC), own flash linker
  script with measured stacks, RTI tick, ESM handling, DWD watchdog, the
  DMI link over EMAC or SCI, flashing via XDS110.
- The 2.7 GB GCC build tree under `~/.local/share/etcs-dmi/build` can be
  deleted after the setup.

## 6. E1 — Language: outcome (2026-09-28)

Two parallel branches, `e1/codec` and `e1/catalogue`, merged on
`e1/language`; the seed catalogue of the codec replaced by the complete
one at merge, the Ada regenerated.

**Catalogue** ([evc/language/etcs_language.toml](../evc/language/etcs_language.toml),
format [SCHEMA.md](../evc/language/SCHEMA.md)): 234 variables (7.5), 67
packets (57 track to train including 44 as raw data and 255, 10 train to
track), 43 radio messages (24 track to train, 19 train to track), every
entry with its clause. Written from the PDF pages, because the markdown
loses which fields belong to a loop or a condition: 31 packets needed the
page for their structure, 5 had headings the markdown lost.
`check_catalogue.py` validates the file against the schema and
cross-checks every packet's flattened field list and lengths, the 7.4.1
lists, the 7.5 headings and the message tables against the markdown; the
markdown defects it tolerates are listed in it with the PDF page.

**Generator** (`gen_language.py`, standard library): 143 checked-in Ada
files, `--check` regenerates and diffs. One package per packet with a
record type, `Decode` and `Encode`; a range type per variable with
`To_`, `Code` and `Is_Valid`; `ETCS_Catalogue` and
`ETCS_Message_Catalogue` as data. Record sizes total 19.9 kB, the largest
packet 27 (6.1 kB) and packet 3 (4.4 kB).

**Codec** (hand-written, SPARK): `ETCS_Bits` (reader and writer over
their own copy of up to 1024 bytes, MSB first, 1 to 64 bit variables,
total operations with a sticky `Failed`), `ETCS_Packet_Index` (one
packet: header, L_PACKET consistency by decoding on a copy, skip of an
unknown packet), `ETCS_Telegram` (8.4.2: header checks, packet index
over the kept bits, 8.4.1.4 duplicate rule with its exceptions, packet 0
first, 255 at the end, 210 and 830 bit formats, building), `ETCS_Message`
(8.4.4: L_MESSAGE, message variables from the catalogue, mandatory
packets in order then optional ones by the rules, padding, building).
Versions accepted: 2.0 to 2.3 and 3.x as 7.5.1.79 defines them; 0.x and
1.x rejected under `Unsupported_Version` with the header kept.

**Core**: `EVC_Received` keeps the last accepted telegram and message
(bits plus index) and counts every rejection reason; `EVC_Core.Read_Ports`
latches up to 8 telegrams and 4 messages per cycle, parses them and
writes a JRU record each. No behaviour on the content yet. The E0
contracts stay proven.

**Proof**: 4101 checks, 0 unproved, 0 justified (858 run-time, 1297
functional contracts, 42 assertions, 772 termination, 1090
initialisation). 26 min CPU; 77 min wall on a machine shared with the
cross build. A generator change made this feasible: `Decode` fills locals
and assigns the record once, each loop item has its own procedure
(packet 3 went from 32 min to 14 s).

**Tests**: `evc_test` 503 checks (27,202 encode → decode round trips of
random valid packets with boundary values, framing, padding, truncation
at every bit boundary, L_PACKET mismatch, unknown packet skipped,
duplicate rule, versions), one new golden; `evc_fuzz` random bits on BTM
and RTM, 0 raised. `dmi_test` 2156, `dmi_fuzz` clean, wasm unaffected
(evc/ is not in the wasm build yet).

**Cross build**: 195 kB code, 7.5 kB data on the TMS570LC43x with the
whole language. Stack worst case for parsing a message about 10 kB
(message record 1.8 kB, two 1 kB readers, packet record up to 6.1 kB).

**Matrix review and fix round** (branches `e1/trace`, `e1/fix`). The
classification of the 380 E1 clauses re-verified the catalogue against
the PDF (no structural error) and found 66 clauses only partly met, all
of one kind: the parsers accepted what they should refuse. Closed in one
round: spare values are rejected at parse (3.16.1.1.1: a spare value
makes the message non-compliant) through a generated `Valid (P)` per
packet and `ETCS_Variables.Valid_Code` for message variables, with two
new catalogue keys, `spare` (values and ranges inside the defined range:
M_MODETEXTDISPLAY, M_VERSION, M_LINEGAUGE, M_LINEAXLELOADCAT, NC_TRAIN,
NID_OPERATIONAL FFFF FFFF) and `bcd` (NID_MN, NID_OPERATIONAL,
NID_RADIO: digits 0..9, F only as filler after the last digit); a packet
is refused when its `Sent_By` excludes the medium (balise telegram) or
the sender (RBC or RIU, a parameter of `ETCS_Message.Parse`; message 37
is RIU only); a balise telegram has exactly 210 or 830 user bits, which
SUBSET-036 4.3.1.2 states and 8.4.2 does not. E1 stands at 373 `done`
and 7 `deferred` (sender identity and the version-invariant column of
8.5.2/8.5.3 in E5; unknown packet and message numbers per 3.17.3.11 in
E6; the packet 136 infill rule and Euroloop in E7; the A.3.11 data entry
ranges in E4/E6). Proof after the round: 4451 checks, 0 unproved, 34 min
wall alone; `evc_test` 649 checks.

**Open points carried forward**
- `EVC_Received` passes RBC as the sender of every RTM message until E5
  tells RIU sessions apart; until then message 37 and packet 143 on the
  RTM port are refused.
- The catalogue cannot express value constraints (M_ACK = 0 in message
  39, NID_TSR ranges by sender, D_REF using the message's Q_SCALE),
  spare values between defined ones (M_MODETEXTDISPLAY), or rules at
  telegram level (packet 136 applies to the packets after it): these are
  behaviour of E2 to E6 and are noted in the TOML.
- Euroloop telegram header (8.4.3) is E7 with the loop.
- The proof of the whole on-board is now long: run it on an idle
  machine; consider `--level=1` for the generated packets once the
  contracts are stable.

## 7. E2 — Position: outcome (2026-09-28)

One branch, `e2/position`, 3.3 kloc of SPARK in six units, merged with
the E1 fix round.

**Units**: `EVC_Distances` (cm in 64-bit integers with saturation, the
senses of the odometer frame), `EVC_Odometry` (frame position and its
confidence from the odometer's over- and under-reading counters, all
accumulators proven monotone; 3.6.8 accuracy monitoring with the A.3.1
values: 100 m intervals, a 5000 m window, impairment and safety
thresholds, recovery per SUBSET-041 5.3.1.1; 3.15.8 cold movement; 3.6.7
virtual positions), `EVC_Balise_Groups` (one passage: location reference
balise 1 or its duplicate, orientation from the numbering against the
stamps, single balise and duplicated pairs without orientation),
`EVC_Linking` (packet 5 as a chain of cumulated distances),
`EVC_Location` (anchors with their deviations at detection and Q_LOCACC,
`Doubt_Over`/`Doubt_Under` per 3.6.4.1.5, location items relocated per
3.6.4.2.5 a to c), `EVC_Position` (orientation from the cab, LRBG, SOLR,
the last 8 LRBGs, unlinked groups, expectation windows and the linking
reactions of 3.4.4.4 and 3.16.2.3, geographical position, packet 58
parameters and the report triggers of 3.6.5.1.4/.5, packets 0 and 1).

**Ports**: the odometer sample is 22 bytes (wrapping distance counter
towards cab A, over- and under-reading amounts, estimated / min / max
speed, movement code, cold movement flag and distance); the BTM payload
carries the odometer stamp of the balise before the telegram; the cab A /
cab B signals of SUBSET-034 2.5.1 give the orientation; JRU events 4 to
10 report linking reaction, unexpected and missed groups, odometer
accuracy, position status, cold movement and a new LRBG.

**Design**: positions stay in the odometer frame; an anchor keeps the
deviations it had when processed, telegrams are processed before the
cycle's odometer sample, so every interval measured from an anchor is
the wider one. E2 detects and reports; the reactions (trip, brakes,
driver information) are E3 and E4. Engineering constants in
`EVC_Position` to make configuration later: end of a passage 15 m past
the last balise, antenna offsets 3 m to cab A and 17 m to cab B.

**Contracts proven**: min safe ≤ estimated ≤ max safe front end and min
safe rear end ≤ min safe front end; the orientation changes only with the
cab status; against the same LRBG and orientation the confidence never
shrinks (with a ghost lemma in the body of `EVC_Position`: the same lemma
in a package spec made gnatprove 15.1.0 crash on `evc_core.adb`); the
LRBG changes only at the end of a passage. Proof of the whole on-board:
5084 checks, 0 unproved (1056 run-time, 1461 contracts, 70 assertions,
990 termination, 1384 initialisation), 39 min CPU.

**Tests**: `evc_test` 747 checks, six new goldens: a track model with an
odometer error model drives first group, linking windows, missed / early /
unexpected / unlinked / wrong-direction groups, single balises and
packet 1 with the RBC assignment, duplicated balises, geographical
position on the DMI, odometer impaired / recovered / safety threshold,
cold movement, orientation from the cab, virtual positions, report
triggers, relocation b and c, repositioning, packet 0 and 1 round trips.
`evc_fuzz` sends stamped telegrams of linked groups, moving odometer
samples and cab signals, checks the confidence interval every cycle.
`dmi_test` 2156, `dmi_fuzz` clean.

**Matrix E2**: 100 `done`, 34 `partial` (all waiting on a later phase for
the reaction or the consumer: E3 supervision uses the position, E4 acts
on the events, E5 reports to the RBC, E6 for 3.16.2.4.1 and 3.7.3.1),
49 `deferred`, 1 `n/a`. The partial rows close when those phases consume
the events; the notes say which.

**Cross build**: 295 kB code, 8.7 kB data, 18.7 kB static state on the
TMS570LC43x after E2 (E1: 195 kB code).

**Open points**: the wrap-around of the odometer counter is not
exercised by a scenario; Q_DIRTRAIN at standstill reports the last
movement; unknown-LRBG reports use NID_C 0; the balise detection error is
taken as inside the odometer's amounts (SUBSET-041 5.3.1.1).

## 8. E3 — Supervision: plan (2026-09-28)

E3 is the critical path and is split in two halves along the boundary
the SRS itself draws in 3.13.2 (the inputs of the speed and distance
monitoring), fixed in
[evc/evc_supervision_input.ads](../evc/evc_supervision_input.ads):

- **Profiles** (`e3/profiles`): the stored information. Reception,
  storage, completeness, extension, replacement and deletion (3.7) of
  SSP (27), ASP (51), TSR (65, 66, 141), gradients (21), MA in level 1
  (12) with section and overlap timers, danger point, overlap and release
  speed (3.8.3, 3.8.4), track conditions (68, 39, 67; 3.12.1 and 5.18
  displays: MSG_TRACK_COND), route suitability (70; 3.12.2), mode profile
  (80; 3.12.4, stored for E4), level crossings (88; 3.12.5), adhesion
  (71), national values (3, replacing the E0 record), train data as a
  store with defaults; the distances converted to the odometer frame at
  reception with the location items of E2; the MRSP of 3.13.7 with the
  front / rear end rules of 3.11.2 and 3.11.3; the `Snapshot_T` per
  cycle; MSG_PLANNING to the DMI.
- **Supervision** (`e3/supervision`): from the snapshot, 3.13.2 to
  3.13.6 (conversion models A.3.7 to A.3.10, gradient acceleration,
  reduced adhesion, deceleration and brake build-up with the correction
  factors), 3.13.8 (targets, EBD / SBD / GUI curves), 3.13.9 (EBI, SBI,
  W, P, I limits, release speed calculation), 3.13.10 (CSM / TSM / RSM,
  statuses, brake commands, Tables 5 to 15), 3.13.11 (perturbation
  location), 3.14 (brake command handling, roll away, reverse movement
  and standstill supervision); the TIU brake outputs; MSG_SPEED_STATE
  and the MSG_STATUS fields the DMI shows; fixed point with an integer
  square root, precision checked against the ERA braking curve workbook.

Each half classifies its rows of the matrix; the coordinator merges the
profiles first, then the supervision, and runs the mission of the mock
against the on-board through the DMI goldens.

## 9. E3 — Supervision: outcome (2026-09-28)

Three branches: `e3/profiles`, `e3/supervision` in parallel from the
same base, then `e3/integrate` for the merge (ten files in conflict, all
"both appended at the end", both sides kept) and the seams the halves
left for each other. A follow-up branch `e3/pbd` adds 3.11.11 (§9,
"Open points").

**Stored information** (profiles): `EVC_Origins` (32 location
references, each the three items of Table 2a, relocated with the SOLR),
`EVC_Profiles` (locations as offsets from an origin; replacement,
deletion in rear, coverage; the lower envelope proven sorted and never
above any element), `EVC_Train_Data` (a documented default train until
E4 enters one: 200 m, 160 km/h, lambda 135 % P), `EVC_National_Values`
(packet 3 with D_VALIDNV and the NID_C rule of 3.18.2, A.3.2 defaults;
replaces the E0 record), `EVC_Track_Description` (SSP with categories,
gradients, ASP, TSR and revocation, default gradient, LX, adhesion, route
suitability), `EVC_Movement_Authority` (level 1 MA, section / End
Section / overlap / LOA timers and their effects, EOA, SvL, release speed,
V_MAIN, mode profile), `EVC_Track_Conditions` (68, 39, 67; the 5.18
indications and planning orders; braking inhibition areas),
`EVC_Stored_Information` (runs the step, builds `Snapshot_T`). Bounds: 96
elements per store, 32 MA sections, 400 MRSP sources; about 90 kB of
state. An MA is refused unless SSP and gradients cover it to the SvL
(3.7.2.3); a shortening deletes only information of earlier messages
(3.8.5.1.5); the announcement point of a track condition is 10 s at the
current speed, at least 100 m (a choice the SRS leaves open).

**Supervision**: `EVC_Fixed` (cm/s, squares of speeds, ms, divisions
rounded down or up, integer square root), `EVC_Braking` (A.3.7 basic
deceleration, the A.3.8/A.3.9 conversion model, Kdry_rst, Kwet_rst,
Kv_int, Kr_int, Kt_int, Kn, A_MAXREDADH, special brakes and the Table 4
combinations; decelerations in 10⁻⁵ m/s²), `EVC_Profile` (the track under
the curves: gradient with train length and rotating mass, reduced
adhesion, inhibition and powerless areas), `EVC_Curves` (EBD, SBD, GUI as
arcs of parabola on v²; speed at a location, location of a speed, the
A.3.12.2 extremes), `EVC_Limits` (margins, EBI, SBI1/SBI2, W, P, I,
permitted speed, P at the target), `EVC_Build_Up` (A.3.12 reduced times),
`EVC_SDM` (targets including the temporary EOA/SvL of the mode profile
and of a non-protected LX, given and calculated release speed with the
3.13.9.4.9 cap, CSM / TSM / RSM with Tables 5 to 16, MRDT, indication
location, service brake feedback, the pawl of A.3.13, perturbation and
MA request locations), `EVC_Brake_Commands` (3.14: SDM commands, service
brake failure, roll away and unauthorised direction with D_NVROLL,
release after acknowledgement at standstill). Every rounding is on the
safe side: against a floating point reference in the tests, 6813 curve
values are never ahead of the exact location and at most 4.13 m behind
(1.5 ‰), speeds never above and at most 1.5 cm/s below; the calculated
release speed 11.16 km/h against 11.18. The per-cycle cost is bounded:
a fixed number of arc walks per target, 16 bisection steps for the
release speed. Choices recorded in the `EVC_SDM` header: measured
acceleration from the speed with a 1 s filter; reduced times at the
current speed; service brake failure after T_bs + 2 s without
deceleration.

**Outputs**: MSG_SPEED_STATE every cycle, MSG_PLANNING while an MA is
present, MSG_TRACK_COND on change, MSG_STATUS brake indication and TTI;
the TIU output (2 bytes: EB, SB, traction cut-off commands and the
reason) when it changes and every cycle while active; JRU events 20
(brake commands), 21 (supervision), 22 (EOA/SvL passed), 32 (stored
information), 33 (configuration loaded or refused).

**Installation configuration as data** (owner's decision 2026-09-28,
branch `e3/config`): the on-board configuration of 3.13.2.2.6 to
3.13.2.2.8, the service brake failure detection of 3.14.1.2 and the
antenna offsets are installation data, `EVC_Config`: a 36-byte image
with magic, format version, length and CRC-32, loaded by
`EVC_Core.Configure` in No Power only, validated against the field
ranges and Table 3 of 3.13.2.2.6.1 (magnetic shoe brake: no interface or
emergency brake model only; Ep brake: not emergency only), kept over
`Initialise`, always `Valid` by a state predicate, every outcome on the
JRU. Sources: `obj/evc_onboard --config <image>` or `EVC_CONFIG`; the
page and `onboard_smoke.js` load `test/wasm/onboard.cfg`;
`test/tools/evc_config.py` converts the readable form
(`ports/hosted/evc.cfg`, every field with its clause) to the image and
back and validates like the kernel; on the TMS570 a `.evc_config` flash
sector written by the flashing tool (E8). The default is the previous
constant with one correction: the magnetic shoe brake was set to both
brake models, which Table 3 forbids. Each field has a behavioural
scenario; all 16 Table 3 combinations are tried (13 legal). What stays
constant and why is listed in the unit header (store sizes, values the
SRS or SUBSET-041 fixes, algorithm choices).

**Both values of Q_NVEMRRLS** (owner's decision, branch `e3/emrrls`):
the kernel follows Tables 6, 10, 11 and 14 and 3.14.1 for 0 (revocation
at standstill only) and 1 (also when the permitted speed is no longer
exceeded), in CSM, TSM, RSM and combined with a roll away reason; five
scenarios run each with both values through a packet 3. The bench keeps
0 (the A.3.2 default), the `evc_test` mission 1, each saying so.

**Proof**: 7385 checks, 0 unproved (3129 flow, 4256 provers). Contracts
that state the SRS: intervention implies a brake command; a triggered EB
implies EB commanded; EB revoked only when supervision stops, at
standstill, or outside RSM at or below the MRSP; RSM only with a release
speed; V_perm ≤ V_warning ≤ V_SBI; the MRSP never above any source; the
SvL never before the EOA.

**Tests**: `evc_test` 9001 checks (the profiles' telegrams and stores,
the supervision's reference comparison and the tables, the seams);
`evc_fuzz` random snapshots and random valid packets of every kind, the
supervision on the real snapshot, 10⁶ steps clean. Goldens: the E2
scenarios move a train in Stand By without an MA, so the standstill
supervision of 4.4.7.1.5 now commands the emergency brake after D_NVROLL
and their goldens changed by exactly that (TIU output, JRU 20, MSG_STATUS
brake indication); the position records are identical.
`test/tools/evc_dump.py` decodes a golden's output for such comparisons.

**Mission of the mock** (fed as telegrams: one balise group with packets
3, 27, 21 and 12 carrying `sim/evc_track.ads`): the pictures at `mission_sb`
and `mission_after_lx` are identical to the DMI goldens; TSM, RSM and
stopped differ in areas A and B only. The on-board enters TSM at 2220 m
where the mock does at 3547 m, commands the service brake at 2850 m and
the emergency brake at 3282 m, enters RSM at 9818 m against 9970 m: the
mock's constant 0.8 m/s² without build-up times or correction factors is
optimistic, and its train ignores the on-board's brakes, so the on-board
shows intervention where the mock shows a picture no compliant on-board
would. The bench keeps the mock until E4 gives the on-board its modes;
then the on-board drives the DMI.

**Cross build**: 512 kB code, 13.5 kB data, 183 kB static state on the
TMS570LC43x (of 4 MB flash and 512 kB RAM). The state grew with the
96-element stores in 64-bit distances; E8 decides whether 32-bit
distances in the stores (the frame never exceeds ±2⁴⁰ cm but the stores
never need it) or smaller bounds are the way to trim it.

**Matrix E3**: 393 `done`, 28 `partial`, 76 `deferred` of 497 before the
follow-up. The partial rows wait on E4 (modes, trip, data entry: 13
rows), E5 (level 2 parts and the MA request: 9), E6 and E7 (6).

**Follow-up `e3/pbd`** (merged): the speed restriction to ensure the
permitted braking distance (3.11.11, packet 52) as a store in
`EVC_Track_Description`, replaced and deleted per 3.7.3.1 d), 3.7.3.1.4
and 3.7.3.2 a), entering the MRSP and the planning; `EVC_PBD` computes
V_PBD with the braking model of E3 (single section gradient, no trackside
adhesion or inhibition, d_offset from the antenna and the 1 s of
SUBSET-041 5.2.1.1, a 15-step bisection, rounded down to 5 km/h; against
the floating point reference none of 720 speeds is above it, 472 of 480
equal it, the rest one step below), recomputed when train data, national
values, brake status, slippery rail or antenna change (JRU 32, change 14).
Gradient gaps left by relocation towards a less accurate reference
(3.6.4.2.5 c) are covered track (3.11.12.2), so the snapshot takes the
lower neighbouring gradient in a gap, never above what any curve of
Table 2a reads there. Proof 7458 checks, 0 unproved, 17 min; `evc_test`
10223. Matrix E3: 413 `done`, 28 `partial`, 56 `deferred`.

**Small round after the follow-up** (branches `e3/odo-wrap`,
`e3/ssp-gap`, `e3/cleanup`): a scenario drives the odometer counters
across both 32-bit boundaries (position, confidence, LRBG, geographical
position continuous; backwards counters counted as anomalies); the MRSP
in a relocation gap between SSP elements takes the lower neighbour (read
literally, Table 2a would give the higher one there, since the gap puts
the "max" item ahead of the "min" item; the lower one is the safe side
and the same argument as for the gradients, one paragraph in
`EVC_Track_Description` for both); the `evc_test` mission builds its
telegrams with `Sim_Telegrams`.

**Open points**
- `EVC_Odometry.Anomalies` (a counter stepping backwards) is read by
  nothing: no JRU record, no reaction. E4 decides what an odometer fault
  does; a JRU record at least.
- The fixed train data (braking models, Kdry_rst/Kwet_rst, Kn, rotating
  mass) are installation data too (3.13.2.2.9.1.1) and still record
  defaults: same treatment as `EVC_Config` with E4's data entry.
  `Default_Locacc_Cm` should come from the national values.
- The page's "Acknowledge brake release" button is a stopgap until E4
  ends the DMI's start-up dialogue.
- Conservative choices to review: T_bs1 = T_bs in the PBD computation
  where 3.13.9.3.3.3 names T_bs_reduced; the ±1 km/h tolerance of 3.11.11
  is not used; the driver's slippery rail is kept as an input.
- Cost on target: a full PBD recalculation (96 sections) is a few 10⁴ arc
  steps, and `EVC_PBD` builds a 14 kB profile on the stack: to time and
  measure in E8.
- Until E4 the on-board stays in Stand By: moving a train without an MA
  triggers the standstill supervision, correctly.
- `Snapshot_T.Extra`: the extra train data, T_MAR and the SR distance
  stay at their defaults until E4/E5.

## 10. E4 — Modes and procedures, level 1: plan (2026-09-28)

766 clauses, split in two halves plus the bench, along the 84 transition
conditions of 4.6.3, which are the joint: `EVC_Modes.Transitions` says
which condition allows which transition with which priority (E0), and
[evc/evc_transition_conditions.ads](../evc/evc_transition_conditions.ads)
(generated once by `doc/SRS/tools/gen_conditions_skeleton.py` with the
text of every condition, then edited by hand) says whether a condition
holds. Each half implements the arms of the conditions it owns; the
identifiers 55, 57 and 64 are not in the 4.0.0 table.

- **Modes and levels** (`e4/modes`): the mode machine of 4.6 with its
  priorities running in `EVC_Core.Run_Mode_Machine`; the mode definitions
  and responsibilities of 4.4 (what each mode supervises, the ceiling
  speeds into `Snapshot_T.Mode_Speed`, the `Supervise` gating), the
  active functions table 4.5, the DMI per mode 4.7 (what MSG_MODE_LEVEL,
  MSG_ONBOARD and the acknowledgement fields carry, as the DMI expects
  them: read `common/dmi_protocol.ads` and how `EVC_Mock` fills them),
  the acceptance of information by level, mode and origin 4.8, what
  happens to stored information on level and mode entry 4.9 to 4.12 and
  A.3.3 to A.3.6 (reset entry points in the E3 stores), level transitions
  5.10 (packets 41 and 46, announcement and acknowledgement, the
  transition location and the immediate transition), start and end of
  mission 5.4 and 5.5 in levels 0 and 1 (the S-states, driver ID, level,
  train data validation from the DMI, train running number; the RBC parts
  are E5), the decoding of the DMI's MSG_DRIVER_ACTION and
  MSG_DRIVER_DATA into `EVC_Driver_Requests` (queries named after the DMI
  actions, latched per cycle; the procedures half may add queries
  additively), the isolation and the conditions [1] to [4], [13], [14],
  [21] to [23], [25], [26], [29], [44] to [46], [56], [58] to [60], [67],
  [77] to [79], [84] and every level related one.
- **Procedures** (`e4/procedures`): shunting 5.6 and 5.7 (SH, PS,
  conditions [5], [6], [19], [22], [23], [27], [28], [30], [49] to [52],
  [61]), override 5.8 ([37] and the override state, 3.11.10), on sight
  5.9 ([15], [34], [40], [73], [75]), train trip and post trip 5.11
  ([7], [11], [12], [16] to [18], [20], [41], [62], [63], [65], [66],
  [68], [69]: the reactions to the E2 events and the E3 overrun), reversing
  5.13 ([59]), non protected level crossings 5.16 ([9]), train data
  changes from other sources 5.17, the indication of track conditions
  5.18 (rows to classify against what the E3 profiles already do),
  limited supervision 5.19 ([70] to [72], [74], [76]), the track condition
  outputs to the train interface 5.20 (TIU outputs: pantograph, main
  switch, air tightness, brakes inhibition, per SUBSET-034), supervised
  manoeuvre 5.21 ([81], [82]), inhibition of the balise transmission alarm
  5.22, text messages 3.12.3 (packets 72 and 76: display and end
  conditions, acknowledgement, MSG_TEXT and MSG_TEXT_REMOVE to the DMI),
  the mode related speed restrictions 3.11.7 as the source of
  `Mode_Speed`, and the E2/E3 partial rows these procedures close.
- **Bench** (`e4/bench`, started 2026-09-28 from E3): the environment
  simulator for the on-board in `sim/` (trackside with balise groups and
  telegrams from the encoder, odometer with an error model, vehicle that
  obeys the on-board's brakes, JRU sink), `onboard.wasm` next to the mock,
  a switch on the page, the hosted `evc_onboard` on the same environment,
  and a wasm smoke check proving the wasm on-board byte-identical to the
  native one.

At the end of E4 the on-board runs the mission of the mock through the
DMI on the bench in level 1, from start of mission to the stop at the
EOA, and `EVC_Mock` is retired from the default page.

## 11. E4 bench: outcome (2026-09-28)

Branch `e4/bench`, merged. The real on-board drives the DMI on the
bench, and its wasm build sends exactly the bytes of the native one.

**Environment** (`sim/`): `EVC_Track` extended with six linked balise
groups (NID_C 123, two balises 3 m apart, at −12, 1500, 4000, 6500, 8000
and 9600 m), a TSR and a plain text the mock ignores; `Sim_Telegrams`
builds 830-bit telegrams with the on-board's own encoder (packets 3, 5,
12, 21, 27, 41, 65, 68, 73); `Sim_Trackside` places them (national
values and SSP in the first balise, gradients and the level 1 MA with its
danger point and 25 km/h release speed in the second; linking with
service brake reaction and 2 m accuracy); `Sim_Odometer` with an integer
error model (+1000 ppm scale, ±500 ppm noise from a fixed seed, bounds
that always cover the true error, interpolated balise stamps);
`Sim_Vehicle` (cab A, direction controller, brake pipe pressure; the
on-board's EB, SB and traction cut-off act on `EVC_Train`, which gained
brake build-up times; a failed on-board makes the vehicle brake by
itself); `Sim_JRU` (a ring of decoded records);
`EVC_Driver.Auto_Drive_Onboard` following the permitted speed of
MSG_SPEED_STATE; `Sim_Onboard_Env.Step` running driver → vehicle →
odometer → balises → `EVC_Core.Tick` → outputs.

**Modules**: `onboard.wasm` (960 kB) next to `dmi.wasm` and `evc.wasm`;
the hosted `obj/evc_onboard` runs the same environment on the hub port.
The wasm build needed `__multi3`: LLVM turns the overflow-checked 64-bit
multiplications of the kernel into a 128-bit multiply, the modules link
with `-nostdlib` and the AdaWebPack runtime has no compiler-rt, so
`test/wasm/wasm_int128` provides it in Ada (64-bit modular arithmetic
only) and the smoke check compares it with BigInt on 2000 operands.

**Page**: a selector "On-board: simulator (mock) | ETCS on-board", the
mock by default until E4 gives the on-board its modes; with the on-board,
a panel with mode and level, TIU commands and reasons, brake pipe
pressure, the last JRU records, the balise groups on the strip, and an
"Acknowledge brake release" button, because the DMI shows no
acknowledgement request during its start-up dialogue (11.7.1.8) and the
on-board cannot end that dialogue before E4 (to review then).

**Same bytes on wasm and natively**: the vehicle integrates in Float but
quantises position and speed to cm and cm/s at the port boundary;
everything after is integer. `test/wasm/onboard_smoke.js` runs 600 cycles
and compares the SHA-256 of the on-board's DMI output with the golden of
the native scenario `Scenario_Bench_Onboard`: identical. The native
scenario then runs the whole mission: one standstill supervision brake
before the group is read, MA supervised from −6 m, TSM at 2340 m, the TSR
respected at 7390 m, RSM at 9871 m, stop at 9888 m before the EOA at
10 000 m, no intervention under the MA, all 12 balises accepted.

**What the mission needs from E4**: start of mission and the modes (the
on-board stays in SB and the DMI in its start-up dialogue), train data
from the driver (MSG_DRIVER_DATA is ignored, the default 200 m train is
used), acting on packets 41 and 73, the linking reactions; the demo line
orders level 2 at 5000 m, which needs E5 or a change of the line.

**Open points**: the vehicle ignores gradients; the 1 MB wasm stack is
not measured for the on-board; `evc/README.md` still describes
`evc_onboard` as bridging the DMI port only; `Mission_Track` in
`evc_test` can move to `Sim_Telegrams`.

**Tooling** (same day): the wasm bench builds natively on the Mac,
`test/wasm/setup-native-toolchain.sh` installs GNAT-LLVM with the GCC 14
front end, LLVM 16.0.4 and the AdaWebPack 24.0.0 runtime from pinned
sources outside the repository; a clean build of the three modules takes
about 9 s against 28 min in the Docker image under Rosetta, with
byte-identical modules (Docker stays the fallback and the CI path).
gnatprove's proof results are shared across worktrees through its file
cache (`etcs_evc.gpr`, package `Prove`), so an agent's worktree re-proves
only what it changed. The generator now emits the standard packet header
(7.3.3.2) once per direction, in the parent packages
`ETCS_Track_Packets` and `ETCS_Train_Packets` (`Decode_Header`,
`Header_OK`, `Encode_Header`, `Finish_Length`), instead of repeating it
in the 67 packet bodies: 1.1 kloc less generated Ada, 12.5 kB less wasm,
the L_PACKET patching in one place. Inheritance was considered and
rejected: the packets share shape, not behaviour, and class-wide
dispatching would add verification conditions to a kernel whose
consumers always know which packet they hold.

**ERTMSFormalSpecs frames** (`e3/efs`): the 49 functional test frames
of ERTMSFormalSpecs (EFS, an executable model of SUBSET-026 3.4.0 by
ERTMS Solutions, EUPL v1.1) are converted by `test/tools/efs_frames.py`
into scenarios in `test/efs/` (derived data under the EUPL, apart from
the GPL of the repository; the folder is optional). Of 3610 actions
1576 are translated (the EFS test environment expanded from its model),
of 3376 expectations 657; the rest is kept verbatim for E4. The 828
cases cite 1361 requirements: in our matrix 250 done, 21 partial, 39
deferred, 402 todo, 597 without a row (3.4.0 numbering, or no on-board
row), 52 of other documents. `obj/evc_efs_test`
checks the supervision family against the SPARK units, one unit of our
resolution on the safe side: 518 checks (braking models 111, safe
deceleration 187, conversion model 87, normal service 53, expected
deceleration 32, supervision limits 35, build up times 13), 424 pass,
94 known differences in the table of the converter, 0 failures; 2858
skipped (2556 verbatim, 163 in the five frames without the test
environment, 111 SSP / TSR / MRSP that need the stored information of
the telegrams, E4, 18 computed inside `EVC_SDM`, 10 after a telegram). To call the code the supervision
runs, `EVC_Braking` exports `Kr_Int`, `Kv_Int`, `A_Ebmax` and
`EVC_Limits` `Bec` (the terms of the EBI, used by `EBD_Limits`), both
re-proved. What the known differences are: at a step boundary EFS takes
the step above, 3.13.2.2.3.1.3 and 3.13.2.2.9.2.3 (same in 3.4.0) the
step below (46); EFS inhibits a special brake only inside the track
condition, 3.13.5.1 (same in 3.4.0) up to the foot of the curve, as
`EVC_Profile` does (21); EFS takes the gradient at d without the train
length compensation of 3.13.4.2.1 (5); 3.13.6.4.3 went from Kn(V) *
grad (3.4.0) to Kn(V) * grad / 1000 (4.0), ours is 4.0 (4); two defects
of EFS: V_bec and D_bec add V_delta1/2 in m/s to km/h (8), and its
normal service set drops the eddy current brake where it is switched off
for the emergency brake (8). No defect of ours was found; open for
review: with the Ep brake interface for the service brake only, ours
takes the Ep brake as in use for T_brake_emergency (EFS: not in use,
3.13.2.2.6.2 is silent), which gives the shorter T_be (2); and
`Train_Data_Extra_T` keeps one set of Kdry_rst / Kwet_rst for every
combination, where 3.13.2.2.9.1.2 wants one per combination (the runner
gives it the set of the combination in use); both for the train data of
E4.

**`e3/scn-reader`** (same phase): the generic part of the EFS reader
moved into `Scn_Reader` (`test/src/`) so that a second consumer can
share it: `evc_s076_check` reads SUBSET-076's own test sequences, a
sibling repository (`../etcs-subset076`, optional like the EFS
checkout) generating `sequences/<SV>/*.scn` in the same format family;
for every telegram / message it decodes the hex with `ETCS_Telegram` /
`ETCS_Message` as the BTM / RTM ports do and walks the sequence's own
"var" rows with `ETCS_Bits.Reader` directly, checking the ones that
name a variable of our catalogue and skipping the rest without losing
its place in the bits.
