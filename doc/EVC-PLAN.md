# ETCS on-board (EVC) — Plan

> **Status (2026-10-01):** E0 closed (§5), E1 closed (§6), E2 closed
> (§7), E3 integrated and merged (§8 plan, §9 outcome). E4 (§10 plan,
> §11 bench, §12 outcome): the modes and the procedures integrated on
> `e4/integration`; its open rows are listed in §12. Next: E5 (radio,
> level 2).
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
- **Proof settings** (measured 2026-10-02 on the E4 on-board, 8548
  checks, a ten core host): with the shared cache warm a proof costs 8 s
  when nothing changed, 13 to 16 s after one file, 35 s in a fresh
  worktree. From nothing, `--level=2` with its three provers took 22 min
  (155 min of processor time): Alt-Ergo 37 % of it for 120 of 10 000
  conditions, `gnatwhy3` 34 % (it generates, transforms and prints every
  condition anew for each prover and after each failed attempt), CVC5
  12 %, Z3 3 %. CVC5 and Z3 alone prove everything in 12 min; Z3 alone
  leaves 20 checks; the order of the provers and a quick first pass at
  `--level=1` change nothing. The limit of an attempt is 100000 steps
  with 60 s as a backstop, in place of the 5 s of level 2: a
  postcondition of `EVC_Position` needed 4.8 of those 5 s and failed in
  three of five runs from nothing, while the cache held a lucky result.
  Steps are the same in every run, so `evc/prove.sh` can demand a margin
  (a proved check over 60000 steps or 20 s fails the run) and prints the
  margin of every run; it also lets one proof run at a time on the
  machine. The host build is `-O2` and the whole check runs its programs
  side by side: 150 s became 15 s.
- **Size of subprograms** (2026-10-02): the largest one per cent of the
  subprogram bodies were split, without any change of behaviour (every
  test line, golden and sequence outcome identical). In the on-board a
  part is a subprogram at package level with its own contract and is
  headed by its clauses: a nested subprogram without a contract is
  inlined by gnatprove and gains nothing. `EVC_SDM.Step` (876 code
  lines) became the list of its stages, likewise `Build` and
  `Take_Packet` of the stored information (394, 288), `Build` of the
  braking model, `Produce_Outputs`, `Read_Ports` and `Enter_Mode` of the
  core, `Holds` of the transition conditions, `Take_Packet` and
  `Mode_Changed` of the procedures; nothing in those units is over 100
  code lines. A unit proved from nothing: EVC_SDM 334 s -> 43 s, the
  stored information 265 s -> 37 s, the braking model 95 s -> 18 s, the
  core 264 s -> 79 s; the whole on-board 12 min -> 6 min (8803 checks).
  A loop with static bounds and no invariant is unrolled by gnatprove,
  one condition per iteration and branch: a loop invariant on four such
  loops took the braking model from 1205 conditions to 464. New
  subprograms stay under about 100 code lines; a loop over a table gets
  an invariant. `gnatprove --info` named 38 more unrolled loops
  (2026-10-03; a bound up to a count of at most 20 values counts too):
  with an invariant each, `True` where nothing is needed after the loop,
  the checks of 16 conditions or more went from 16 to 4 (postconditions
  over many paths), the conditions from 9363 to 9154 and the processor
  time of a proof from nothing from 2416 s to 2274-2341 s (the loops
  held cheap checks; wall time on a machine loaded by other proofs: 387
  s against 435-634 s, noise), and `evc/prove.sh` fails above 6 such
  checks. The two regression runners are split by subject
  (`EVC_Test_<Subject>`, `DMI_Test_<Subject>`): a new scenario goes into
  the package of its subject. Of what was noticed while reading, checked
  against the clauses on 2026-10-03: the MA request and the perturbation
  location over several targets and 3.13.11.9 on every curve were
  defects and are fixed; the EOA or LOA passed and V_MAIN without an MA
  were not (the code now says why); the stack is the "Stack" bullet; the
  two test checks are fixed. The next five, checked on 2026-10-03:
  `EVC_Text_Messages.Store` was a defect (no room: it took the first
  message not displayed in slot order, else slot 1, dropping a message
  waiting for its acknowledgement with its brake, against 3.12.3.4.7.1;
  3.12.3 sets no number, now the oldest not displayed gives way, else
  the oldest displayed not waiting, else the new one is refused);
  `EVC_Position.Set_Report_Parameters` and `Assign_Coordinate_System`
  were a defect (a group passed again is twice in the wrapping ring of
  the last LRBGs; now its last passage, 3.6.1.3); the temporary EOA of a
  level crossing beyond the MA is not one (3.12.2.5, 3.13.1.5: the
  closer of the two; 3.7.2.2.1 beyond an LOA; A.3.4 keeps it on an MA
  shortening: the comment says so); the direction controller's two
  decodings were the same, now one function; the stop conditions of
  `Scenario_SDM_LOA` and `Scenario_SDM_MRSP_Target` read the train, and
  their checks hold where they were meant. Nothing of that list is open.
  The compiler enforces the embedded constraints of the on-board through
  `evc/restrictions.adc`; No_Secondary_Stack is not among them yet (247
  uses, in the catalogues of the language mostly).
- **Stack** (2026-10-03): `ports/tms570/stack.sh` builds the on-board
  for the TMS570 with `-fstack-usage -fcallgraph-info=su,da` and walks
  GCC's call graph: the frame of each subprogram plus its deepest
  callee, from the four entry points of `EVC_Core` and the elaboration,
  the calls into the runtime measured from the disassembly of
  `libgnat.a` and `libgcc.a`; it fails on a cycle, an indirect call, a
  call to nothing, a dynamic frame without a bound in `stack.py`, or a
  worst case over the budget. Before: `Initialise` 84500 bytes (57 KB
  of aggregates built in temporaries and copied), `Tick` 55024; after:
  `Initialise` 1012, `Tick` 26592 (Evaluate of the stored information,
  Build, Build_Gradients, `EVC_Profiles.Envelope`: the gradient
  elements and the breakpoints of the envelope), `Handle_Input` 184,
  `Take_Outputs` 96, no change of behaviour. The budget, the main stack
  of the target, is 32 KiB: about 20 % for the executive that calls the
  core, E8's own last chance handler, a compiler update and growth, and
  one MPU region; the interrupt stacks, the secondary stack (functions
  returning unconstrained arrays) and the DMI, if it is ported, are
  measured on their own in E8. The rule: no large object by value. GNAT
  builds `(others => <>)` in a temporary when a component has no default
  expression, `(others => (others => <>))` of an array of records always,
  and an aggregate that reads a parameter or calls a function; a function
  returns its result on its caller's stack. So every composite component
  has a default expression and an array of records a named element
  (`(others => No_X)`), state is filled component by component or
  through an `out` parameter (`Get_Current`, `Get_Inputs`), a store is
  read through accessors that return a component (`MA_Present`,
  `SSP_Count`, `LX_Item`), the snapshot of the cycle is package state of
  the core passed by reference, the PBD computes in the profile of the
  supervision's work area (the two never overlap in a cycle), and a
  part of a step that holds a large local is `No_Inline` (GCC inlines a
  subprogram called once and keeps its locals in the caller's frame).
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
its place in the bits. Outcome against the full corpus (3191
sequences, 7338 balise telegrams and 6229 radio messages carried as
bits): 0 failures; 764 rejected by the codec, which the check counts
apart from failures because the sequences carry data meant to be
refused (spare values, an unknown NID_MESSAGE 254, a packet after the
end of information, M_DUP 11) and the runner of E4 judges the
reaction; 257 of the rejections are telegrams of system version 1.0
(3.17.3, E6/E7). Euroloop messages are skipped (no LTM). Two things
the corpus taught: the layout of what the on-board sends follows the
operated system version (chapter 6, phase E7): under 2.1 packet 0 has
a 4-bit M_MODE and Q_LENGTH, under 2.2 a 5-bit M_MODE with Q_LENGTH,
under 3.0 the 4.0.0 layout, and the version comes from the balises'
M_VERSION or from the RBC's message 32; the check applies that rule
before calling a width difference a failure. And three SV30 sequences
(5180200_01 step 60, 9990200_06 step 57, 4080433_01 step 287) send a
position report with the 4-bit M_MODE while operating in 3.0, which
contradicts 7.4.3.1: they are listed as known differences of
SUBSET-076 in the check. The sequences also tabulate what the on-board
is expected to send, so the train-to-track messages are checked too,
the RIU taken as the other end where the catalogue has the message for
the RIU alone.

## 12. E4 — Modes and procedures, level 1: outcome (2026-10-01)

**Modes and levels** (`e4/modes`). The mode machine runs:
`EVC_Core.Run_Mode_Machine` takes, of the transitions of 4.6.2
(`EVC_Modes.Transitions`, now with the condition lists of Figure 2 in
`EVC_Modes.Conditions`), the one of the highest priority whose condition
of 4.6.3 holds (`EVC_Transition_Conditions.Holds`); the proof shows that
only transitions of the table are taken, that nothing leaves IS and that
NP goes to IS before SB. One cycle is now: ports (the DMI's frames
decoded into `EVC_Driver_Requests`, the train interface into
`EVC_Train_Inputs`), position, stored information (filtered by 4.8),
supervision, the levels and the mission (`EVC_Levels`, `EVC_Mission`),
the mode machine and what entering the mode means (`Enter_Mode`: the
data of 4.10 through reset entry points added to the E3 stores, the
brake reasons of 4.12), outputs. The supervision runs before the mode
machine, so the ceiling of a new mode shows from the next cycle.

- Conditions of this half: [1] to [4], [10], [13] (a fault of the host,
  `Enter_Failure`), [14], [21], [25], [26], [29], [32], [39], [42],
  [44], [45], [46], [47], [56], [58], [60], [67], [77] to [79], [84].
  [22], [23] and [59] are listed for both halves in §10 and left to
  `e4/procedures` (packet 135 and reversing); the mode profile ones
  ([34], [61], [71]) are theirs. At the integration the trips [39],
  [42], [67] moved to `EVC_Procedures` (one trip entry, see below) and
  [44], [45] read the override of `EVC_Procedures`.
- 4.4 and 4.5: the functions of each mode as predicates of `EVC_Modes`
  (Figure 1) that the snapshot uses: the MA, the SSP, ASP, LX and PBD
  restrictions, V_MAIN in FS / AD / LS / OS (and SM for the track
  description), the TSRs also in SR and UN, the train speed where the
  table has it, `Supervise` in those modes with valid Train Data; the
  mode speed of SR (V_NVSTFF or the driver's), SH, OS, LS, UN; the SR
  distance (4.4.11.1.3 b) as a virtual position supervised by E3's
  `EVC_SDM`; the unauthorised direction protection in SR against the
  train orientation; the emergency brake of SF every cycle (TIU reason
  bit 6, `TIU_Reason_Failure`); IS commands nothing; "Entering FS" (4.4.9.1.4) while SSP and
  gradient do not cover the train; "non-leading no longer permitted"
  (4.4.15.1.1.3), both as MSG_SYSTEM_STATUS.
- 4.7: MSG_MODE_LEVEL carries the mode, the level, the mode to
  acknowledge, the level announced and its acknowledgement; MSG_ONBOARD
  the data statuses (driver ID, Train Data, level, train running number,
  position), the train inputs and the start of mission; MSG_STATUS brake
  3 while the service brake of 5.10.4.2 waits for the acknowledgement.
- 4.8: `EVC_Acceptance`, the first filter by level and the third by mode
  as tables for the balise information this on-board takes, applied to
  every packet of a group message after the level orders (4.8.1.3: an
  immediate order switches the level before the rest is filtered); a
  rejection is JRU event 32, change 15. Information of 4.8.3 [1] is
  accepted at once: there is no transition buffer (4.8.5, with E5).
- 4.10, 4.12, A.3.4 k: `Enter_Mode` with `EVC_Track_Description.Delete`,
  `EVC_Movement_Authority.Delete_MA`, `EVC_Track_Conditions.Reset`,
  `EVC_Position.Delete_Linking` / `Delete_Geo`,
  `EVC_National_Values.Delete_Pending`, `EVC_Levels.Mode_Entered`,
  `EVC_Mission.Mode_Entered`, each with the modes of its row. Nothing is
  kept over No Power, so 4.11 does not apply.
- 5.4, 5.5 in levels 0, 1, NTC: the start of mission is engaged in SB
  with a desk open; the driver's entries are taken in the modes of 4.7.2
  and checked against A.3.11 and 7.5 (a refusal is JRU event 41, kind
  4); 'Start' with a valid driver ID, level and Train Data proposes UN,
  SN or SR (level 2 without a radio: SR, 5.4.5.3 h); the mission starts
  and ends as 5.4.6 and 5.5.2 say (JRU event 41). The Train Data are
  the driver's entry (DMI Table 40) with the installation's fixed part
  (`EVC_Config.Fixed_Train_T`, in `Config_T` but not yet in the byte
  image, see below). The RBC steps are E5.
- 5.10: `EVC_Levels`, the table of priority (level 2 is not available
  before the radio, NTC never), the announcement shown when it changes
  the level, the acknowledgement area and the transition location, the
  immediate and the conditional order, the driver's level, the
  acknowledgement and the service brake after T_ACK (TIU reason bit 5,
  `TIU_Reason_Level_Ack`).
- `EVC_Driver_Requests` decodes MSG_DRIVER_ACTION and MSG_DRIVER_DATA,
  latched per cycle, with queries named after the actions; the
  procedures' queries were folded in at the integration.

**Tests**: eleven scenarios `Scenario_E4_*` drive the on-board through
its ports (start of mission in levels 0, 1, NTC and 2, SR distance and
SR data, the transition to level 0 with its acknowledgement and brake,
the immediate, conditional and prioritised orders, acceptance, SL, NL,
IS, the odometer's safety threshold, the desk closed during the start of
mission, "Continue Shunting on desk closure", the tables); the scenarios
of E2 and E3 run in FS, level 1, with the default train
(`EVC_Core.Set_Mode_For_Test`). `evc_fuzz` sends the start of mission
frames with values in and out of range. The bench mission
(`Scenario_Bench_Onboard`, `onboard_smoke.js`) now starts with the
driver's start of mission in level 1, runs in SR and enters FS at the
first group; no brake release needs acknowledging any more. Goldens
re-recorded, each looked at with `test/tools/evc_dump.py --diff`: the
E2 position scenarios (FS instead of SB: no standstill supervision
brake, the supervision recorded, the mission events); the power-up,
malformed, valid inputs, isolation and received telegram scenarios
(MSG_ONBOARD som 0 without a desk open); the two profile scenarios (the
same and "Entering FS"); the bench.

**Proof**: the full `evc/prove.sh`, 7989 checks, 0 unproved (3498 flow,
4491 provers). The postcondition of `EVC_Position.Update` (the doubts
never shrink against the same LRBG) was found unproved twice while the
WIP state was proved and proved after; it is near the provers' limit
at level 2 and the first place to look if a later change upsets it.
`evc_test` 10487 checks, `evc_fuzz` raised 0, the wasm smoke checks
identical bytes.

**Matrix** (the 337 clauses of this half, 4.3 to 4.12, 5.3, 5.4, 5.5,
5.10, A.3.3 to A.3.6): 142 `done`, 53 `partial`, 127 `deferred` (E5
radio and sessions above all, E7 Euroloop, AD with the ATO), 14 `n/a`
(4.11: nothing is kept over No Power; infill; STM), 1 `todo`
(4.4.11.1.5.1); eight E2/E3 rows closed or narrowed (3.6.6.9 d,
3.6.8.7, 3.11.3.3.2, 3.11.7.1, 3.11.7.1.3, 3.14.1.11, 3.14.3.1, A.3.11
Table). The other 431 E4 rows are the procedures half's.

**Left** (at the end of this half; [22], [23], [59] are the procedures'
since the integration): 4.4.11.1.5.1 (a movement while
the SR data window is open: the on-board does not know the window); the
position's train length (`EVC_Position.Set_Train_Length` is still not
called: the engine ends of SB, SL, NL, PS and the train integrity are
E5's reports); the transition buffer of 4.8.5; the fixed Train Data in
the configuration image (a format version 2 of `EVC_Config` with the
gamma curves and the correction factors of `Train_Data_Extra_T`, with
the train data view of E6). The bench page still offers the stopgap
"Acknowledge brake release" and says the on-board has no modes; with
the real start of mission the DMI's start-up dialogue drives it (the
page's rework, see the integration below).

**Procedures** (branch `e4/procedures`, 2026-10-01). The procedures of
chapter 5 in `EVC_Procedures` (SPARK), the text messages in
`EVC_Text_Messages`; the driver's actions they read were the interim
`EVC_Procedure_Requests`, the transitions they own the interim
`EVC_Procedure_Transitions`: both deleted at the integration (the
queries are `EVC_Driver_Requests`', the transitions the mode machine's). One cycle: after the speed and distance monitoring,
`EVC_Procedures.Evaluate` takes the packets of the cycle (132, 135, 49,
137, 12, 138, 139; 73, 74 for the texts), runs override, the mode
profile against the train position, the trip conditions, post trip,
reversing, the BTM alarm inhibition, the level crossings and the Train
Data changes, and sets the conditions of 4.6.3 it owns; after the mode
machine `Mode_Changed` does what entering a mode means for them and
`Finish_Cycle` gives their brake demand. What is in:
- shunting 5.6 and 5.7 ([5], [19], [22], [23], [27], [28], [30], [49]
  to [52], [61] with the level switch of `EVC_Levels`), the list
  of balise groups for the SH area (packet 49, 4.4.8.1.1 b, deleted with
  its mode profile, 3.12.4.4), "stop if in shunting", Passive Shunting
  with "stop shunting on desk opening" and "continue shunting on desk
  closure" (since the integration `EVC_Mission`'s, one state for [26]
  and [27]);
- override 5.8 ([37], [43], [54]), the former EOA, every trip inhibited
  while it is active, its end conditions a) to e), g), h) (with the SR
  distance of `EVC_Mission`), i), the override speed restriction
  (3.11.10);
- On Sight 5.9 and Limited Supervision 5.19 ([15], [34], [40], [70] to
  [76]): the rectangle of
  acknowledgement, the request never taken back, the service brake after
  T_ACK (3.14.1.7.3), the profile of the mode in use no temporary EOA
  (3.12.4.7);
- train trip and post trip 5.11 ([7], [12], [16] to [18], [62], [63],
  [65], [66], [68], [69]; [39], [42], [67] since the integration): the
  reason as a system status message, the MA and track description
  deleted (4.10, `EVC_Core.Enter_Mode`) and refused in TR (A035, the
  third filter of 4.8.4), the
  acknowledgement at standstill, the PT reverse distance (4.4.14.1.3,
  3.14.1.7.4), the forward movement protected in PT and RV
  (EVC_Brake_Commands);
- reversing 5.13 with 3.15.4 ([59], the RV speed and distance, 3.14.1.7.1);
- level crossings 5.16 ([9]): the substitution of the temporary EOA and
  SvL by the LX speed restriction, stopped in the stopping area or at the
  location of the Permitted limit for V_LX computed by `EVC_SDM` with the
  formulas of V_est (3.13.9.3.5.11), LX01 on the DMI; a start passed
  without the substitution trips;
- Train Data changed by another source 5.17, from a new TIU input 13
  (the train configuration of SUBSET-034 2.6.4.2, with two bits standing
  for the train implementation's choices of D0 and D1): the service brake
  and its acknowledgement, "Train data changed", the re-validation asked
  (S6) and ended by the driver's Train Data entry (E6, `EVC_Mission`);
- the indication of track conditions 5.18: the E3 profiles already did
  everything but the virtual SBI limits of a non stopping area (5.18.4.2)
  and the tunnel stopping area (5.18.8), which now use SBD curves the
  supervision evaluates at the estimated speed for feet the stored
  information puts in the snapshot (`Snapshot_T.Virtual`, one cycle
  late); the tunnel area goes in MSG_STATUS, its display toggle is the
  DMI's;
- the information for an external function 5.20 (SUBSET-034 2.3.4,
  2.4.1, 2.4.2, 2.4.4, 2.4.6, 2.4.7, 2.4.10) as a second TIU output (tag
  16#54#), with packets 69 and 40 now stored;
- Supervised Manoeuvre 5.21: the exit [82]; the rest is level 2;
- the inhibition of the BTM alarm reaction 5.22 (manual triggering, its
  three ends, 5.22.5.2.1); text messages 3.12.3 (packets 73 and 74,
  MSG_TEXT and MSG_TEXT_REMOVE, the acknowledgement by id, the brake of
  3.12.3.4.7, 3.12.3.5.3); the mode related speed restrictions 3.11.7 as
  `Snapshot_T.Mode_Speed` (since the integration the one source, with
  the SR speed of `EVC_Mission`).

The DMI gets the acknowledgement of a mode and "override" in
MSG_MODE_LEVEL, reversing, the tunnel area and brake 3 ("applied because
an acknowledgement is pending") in MSG_STATUS, the system status
messages of the trip reasons, the reverse distances and 5.17; the TIU
three more brake reasons (trip, acknowledgement missing, procedure: bits
5, 6, 7 in this half, which collided with the modes'; bits 7, 8, 9 of
the u16 reasons since the integration); the JRU events 23 (procedures)
and 24 (text messages). The joint files changed additively only:
`Snapshot_T` gained `LX` and `Virtual`, `EVC_Transition_Conditions.Holds`
reads `EVC_Procedures.State`.

**Choices**: locations the procedures keep (former EOA, reversing area,
start of PT, the substitution of an LX, the text conditions) are frame
positions taken when the information arrives, not relocated; the speed
of 5.8.2.1 a) is the upper bound of the odometer's; T_ACK 5 s and the
BMM distance 300 m of A.3.1; the fixed texts in English only.

**Not here, and why**: everything of level 2 and the RBC ([6], [11],
[20], [41], [81], the reports and requests of 5.6, 5.11, 5.21: E5);
National Systems; the automatic triggering of 5.22.3.1 (needs the
resets of a BMM track condition with the antenna in it). What this half
left to the modes ([34], [61], [71] with the level switch, "start" in
PT, the train running number, the SR distance of 5.8.4.1 h), the 4.x
rows of the matrix) is in since the integration.

**Tests**: `evc_test` 10595 checks, 0 failures (10223 at E3; the
WIP of this branch 10540), 19 scenarios of the procedures
in `test/src/evc_test_procedures.adb` that drive the on-board through
its ports only (balise telegrams of `Sim_Telegrams`, now with packets 39,
40, 67, 69, 88 and the mode profile, odometer, TIU, DMI frames) and
check MSG_MODE_LEVEL, MSG_STATUS, MSG_SPEED_STATE, MSG_TRACK_COND,
MSG_SYSTEM_STATUS, MSG_TEXT, the two TIU outputs and the JRU; the
scenarios follow the SUBSET-076 sequences of their features where
level 1 allows (5160000_01, 5170200_01, 5090200_01, ...). They start
from a mode set with `EVC_Core.Set_Mode_For_Test` (after the train
running number entered through the DMI port, since the integration).
One golden changed, profiles_track_conditions,
by the 175 TIU track condition outputs alone (without them it hashes to
the old golden). `evc_fuzz` raised: 0; `test/check.sh` green with the EFS and
SUBSET-076 checkouts (test/efs regenerated: its frames carry the
matrix statuses); the wasm smoke checks pass. Proof: 7955 checks, 0
unproved (3518 flow, 4437 provers); the LX and virtual-curve
computations of `EVC_SDM` sit in their own subprogram
(`Procedure_Targets`) so that the contracts of `Step` keep proving.
Cross build: 598 kB code, 21 kB data, 219 kB static state (E3: 512,
13.5, 183).

**Matrix**: of the 336 E4 rows of these sections 266 `done`, 22
`partial`, 36 `deferred` (E5, E7), 4 `n/a` (National Systems, the BTM
alarm), 8 `todo` that belong to the modes half or remain (5.22.3.1);
25 E3 rows, 1 E2 row and the 7 rows of 3.15.4 (E6) closed with them.

**Integration** (branch `e4/integration`, 2026-10-01): the two halves
merged and made one on-board.

- One mode machine (`EVC_Core.Run_Mode_Machine` over
  `EVC_Modes.Conditions`); `EVC_Procedure_Transitions` deleted; the arms
  of `EVC_Transition_Conditions` are the union of both halves, `Holds`
  reads both halves' state (its postcondition on [1], [4], [29] kept).
- One decoder of the driver's actions: `EVC_Driver_Requests` with the
  procedures' queries (`Override_Selected`, `Shunting_Selected`,
  `Exit_Shunting_Selected`, `Exit_SM_Selected`, `BMM_Inhibition_Selected`,
  `BMM_Revoke_Selected`, `Tunnel_Toggle_Selected`, the text
  acknowledgements of a cycle, `Text_Acknowledged`); one
  `Mode_Acknowledged`, the start of mission's proposal taking it first
  (`EVC_Mission.Ack_Taken`). `EVC_Procedure_Requests` deleted.
- One cycle: ports, position, stored information, supervision, the
  levels and the mission, the procedures (with the context of the modes'
  units: the level switched, the train running number, the desk, the
  passive shunting input, the SR distance passed, the filters of 4.8),
  the mode machine, `Enter_Mode` (now also `EVC_Procedures.Mode_Changed`
  and `EVC_Text_Messages.Mode_Changed`: every reset of 4.10 and every
  brake reason of 4.12 goes through it; the procedures' own deletions on
  trip, SR, SH and RV and their refusal in TR were dropped for the 4.10
  table and the third filter of 4.8.4, which do the same), the brake
  demand of the procedures, outputs. A trip order (V_MAIN 0) is used in
  the cycle in level 1 and kept in the other levels for [67].
- One trip entry: every trip condition is computed in `EVC_Procedures`
  ([39], [42], [67] moved there), and the reason of a trip is the first
  condition of 4.6.2 for the transition taken (SS 22 and 23 added).
- One mode speed (`EVC_Procedures.Mode_Speed`, with the SR speed of
  `EVC_Mission`); one "Continue Shunting on desk closure"
  (`EVC_Mission`); 4.4.11.1.6.5 (override in SR deletes the driver's SR
  data, the national SR distance counted from the override) with 5.8.4.1
  h); 5.17.2.2 E6 (`Train_Data_Revalidated` on the driver's Train Data).
- 4.8 for the information of the procedures and the text messages
  (`EVC_Acceptance`: danger for SH, stop shunting on desk opening, stop
  if in SR, the reversing area and supervision, the text messages).
- `EVC_Ports`: the TIU reasons collided (bit 5: level acknowledgement /
  trip, bit 6: SF / acknowledgement missing); the reasons are a u16, one
  bit each: 0 speed and distance monitoring, 1 service brake failed, 2
  roll away, 3 unauthorised direction, 4 standstill supervision, 5 level
  transition not acknowledged, 6 System Failure, 7 trip, 8
  acknowledgement missing (mode, text), 9 other procedure (linking
  reaction, PT and RV distances, 5.17); the TIU output is 3 bytes, the
  track condition output is told from it by its tag; JRU event 20 keeps
  its status byte and carries the reason bits 8 to 12 in bits 3 to 7 of
  its byte 2. TIU signals 1 to 13 (13 the train configuration), JRU
  events 23, 24 (procedures), 40, 41 (modes): no collision.
- `EVC_DMI_Port`: one MSG_MODE_LEVEL builder (mode, level, mode to
  acknowledge: the start of mission's or a procedure's, level announced
  and its acknowledgement, override), one MSG_STATUS builder, one
  MSG_SYSTEM_STATUS with the numbers of the DMI's catalogue
  (dmi_protocol.ads: 2, 6, 7, 16, 17, 18, 21 to 25, 27 to 29, 35); dmi/
  unchanged. "Entering OS" (4.4.12.1.7) added as "Entering FS".
- 4.4.18.1.6: in RV the SBI commands the emergency brake
  (`EVC_SDM.Inputs_T.EB_Instead_Of_SB`).

Tests: `evc_test` 10706 checks, 0 failures, with six integration
scenarios (`Scenario_Integration_*` of `evc_test_procedures`, and a
part of `Scenario_Reversing`) that need both halves, through the
ports: the start of mission in level 1, SR, override with D_NVOVTRP and
with the national SR distance (h), the trip of [42] with its reason, PT,
'Start' in PT, SR, "stop if in SR" with and without override; SR, FS, SH
at standstill (the end of mission), exit, PS and [22], [23], [27]; FS,
an On Sight profile acknowledged ("Entering OS"), a transition to level
0 announced, acknowledged and taken in OS, UN; a text to acknowledge read
in SB during the start of mission (after the level, 4.8.3); override and
the switch to level 1 from UN ([44] above the trip of [39]); the order
kept in SH (4.4.8.1.5); RV above the SBI. Three goldens re-recorded
after `golden_review.py --base master`: position_linking_errors (a group
passed in the unexpected direction now trips, [66]), position_orientation
(the cab change closes both desks for a cycle: [28], FS to SB, the end
of mission, the start of mission engaged), profiles_track_conditions
(the 175 records of 5.20); `EVC_DUMP` also writes bench_onboard.bin (its
digest unchanged). `evc_fuzz` sends the procedures' actions and TIU input
13: raised 0 (1 000 000 steps).

The fuzzer had lost its stored information phase without saying so: the
random data of its groups now trip the train (mostly [69], the SSP or
the gradients starting ahead of the front end, and [12] at the EOA,
which the fuzz train passes as it ignores the brakes), TR deletes the MA
and 4.8.4 refuses the next one, so the cycles with an MA fell from 17 350
of 45 849 (E3) to 956 of 44 658 at the default step count and to 0 of
9 219 at check.sh's. The phase now enters FS by the hook or by the
driver's start of mission, enters an MA mode again some cycles after
the train left it (half of the time by the driver: the trip
acknowledgement and 'Start' in PT, or the start of mission in SB; else
the hook), visits TR, PT, SR, SH, OS, RV and UN on purpose every 50
cycles, and gives the SSP and the gradients of its plausible groups from
the group four times in five. With it: 16 227 of 47 645 cycles with an
MA at the default step count, 2 847 of 8 603 at check.sh's, the cycles
by mode in its summary line; it fails (and check.sh with it) below a
floor of a tenth of the cycles with an MA or with a mode of the visits
without a cycle, at 5000 steps or more (five runs of the phase at
least; the lowest share over 30 seeds at 5000 steps was 19 %).
`test/check.sh` no longer loses the exit status of a check behind
`| tail -1` (it did for every program: a failing test let it say ok).
`test/check.sh` green with the EFS and
SUBSET-076 checkouts; the wasm smoke checks pass; the full proof 8543
checks, 0 unproved; cross build 655 kB code, 21 kB data, 221 kB static
state.

Matrix, E4 (766 rows): 463 `done`, 74 `partial`, 190 `deferred`, 19
`n/a`, 20 `todo`: the LSSMA display of LS (4.4.19.1.4 a, b, 4.4.19.1.4.2
to 4.4.19.1.4.8, 16 rows), the TIU output "ready for remote shunting"
(4.4.8.1.4), a movement while the driver enters the SR data
(4.4.11.1.5.1), the automatic triggering of the BTM alarm inhibition
(5.22.3.1, 5.22.3.1.1).

Left for E5 and later: level 2 and the RBC (5.15 and the RBC steps of
5.4, 5.6, 5.11, 5.21, SM, [6], [11], [20], [31], [36], [41], [81]); the
transition buffer of 4.8.5; the train length in the position and the
engine ends (E5); the message consistency reactions (3.16.2.4.4, E6);
the fixed Train Data in the configuration image (E6). The bench page
(test/wasm/index.html) needs: the TIU reasons above bit 4 named (level
acknowledgement, failure, trip, acknowledgement missing, procedure), the
stopgap "Acknowledge brake release" and the "no modes" text removed, the
driver's actions of the procedures offered (override, shunting, exit of
shunting, maintain shunting, BMM inhibition), the JRU events 23, 24, 40,
41 described (Sim_JRU now names them), the second TIU output (5.20)
shown.

**The bench page after E4** (branch `e4/bench-page`, 2026-10-02): the
list above done. The real on-board is the page's default ("On-board:
ETCS on-board"); `EVC_Mock` stays selectable ("simulator (mock)") for
the DMI's own goldens. Checking the DMI's windows (`dmi/`) against the
driver actions `EVC_Driver_Requests` decodes found every one of them
already offered: driver ID, level, train data entry and validation,
train running number and 'Start' (the Start Up windows of 11.3 and
11.4), acknowledgements of a mode, a level transition, a text and a
brake release (one acknowledgement area, 5.4.1.4, `DMI_Ack`), override
(`W_Override`), shunting, exit shunting and maintain shunting (the
Main window, Table 50), the BMM inhibition (`W_Special`), the tunnel
toggle (C2/C3/C4) and the SR speed and distance (`W_SR_Data`); the
stopgap "Acknowledge brake release" button is gone, acknowledged on
the DMI like everything else now that the on-board models the Start
Up dialogue's brake release properly (`DMI_Ack.Brake_Release`,
3.14.1.9). What the DMI has no window for and the bench adds instead:
the train interface inputs besides the desk demand and Auto drive
(SUBSET-034 2.5.1, 2.6.4.2) — the cab, the direction controller
(including neutral), sleeping requested, passive shunting and non
leading permitted, and the train configuration of TIU input 13 (5.17)
— a "Train interface" fieldset in the on-board panel, `Sim_Vehicle`
gaining the setters and `Sim_Onboard_Env` the pass-through
(`Set_Cab`, `Set_Controller`, ...). The panel also shows the TIU
reasons bits 0 to 9 by name, the second TIU output of 5.20 decoded
from `Sim_Vehicle.TC_Payload` (a new capture: `Collect_Outputs` used to
discard it), and the JRU (`Sim_JRU` already named events 23, 24, 40,
41). `EVC_Track` gained a second, independent track of the same shape
(`Preset_T`, a page selector): an On Sight profile with a level
transition to level 0 inside it, a level order back to level 1
(needing Override to avoid the trip of [39], 5.8.4.1), a "stop if in
SR" balise (override avoids its trip too, 5.8.4.1 d, 4.6.3 [54]), a
Shunting area ordered by the trackside (5.7.3) and a plain text with
its acknowledgement (3.12.3), all built with `Sim_Telegrams`'
encoders, parameterised like the proven scenarios of
`evc_test_procedures.adb` (`Scenario_Integration_OS_Level`,
`Scenario_Integration_Override_Level`, `Scenario_Override`,
`Scenario_Shunting_Trackside`); `Sim_Trackside.Build` takes the preset
(default `Default`, so every other caller and the native golden are
unaffected). `test/wasm/onboard_smoke.js` extended: the modes seen
during the driver's start of mission include SB, SR and FS; a further
20 000 cycles (not hashed) run the mission to the stop at 9888 m,
before the EOA at 10 000 m, the acceptance of phase E4; the page's
default selector and the new exports (`onboard_set_track_preset`, the
TIU setters, `onboard_tiu_tc_buffer`/`length`) are exercised without a
trap. A manual walk of the features track (a throwaway harness in
`sim/`'s shape, not committed) reached the On Sight / level 0 group
correctly (the level order switches FS to UN at the group's D_M
regardless of speed; the On Sight request itself needs a speed below
the national value, as 5.9.3.2 b) requires), engaged Override at
standstill in UN, and tripped or passed the level-back and SR-stop
points depending on whether Override still covered the distance
(5.8.4.1 a, b) when reached — the override timing is sensitive to the
driving distances chosen there, same as a real driver's; no exception
was raised and `Sim_Trackside.Built_OK` was true throughout.

**Follow-up, touch only** (2026-10-02): the touch-coordinate replay
above (a throwaway Node script, not committed) was found to diverge
while filling the Train Data window's second page because of two bugs
of the *reproduction*, not of `dmi/` or `evc/`: airtight is a Yes/No
keyboard (Table 40, 10.3.5.18), not a dedicated choice list, so "choice
1" never gave it a value; and, more importantly, a long run of touches
that ticks `DMI_Core` without ever letting the on-board run starves the
simulated EVC link past `General_Parameters.EVC_Link_Timeout_Ms` (1 s),
which the DMI correctly answers by entering System Failure and closing
every window (DMI 5.6.1, 11.7.1.7 / Table 48's
`DMI_Windows.Check_Enabling_Conditions`, active once S10 is reached and
`Sequence_Active` ends). The bench page itself has no such bug: it
steps the DMI and the on-board on two independent timers
(`requestAnimationFrame`), so neither ever starves the other. A native
scenario, `test/src/evc_test_touch.adb` (instantiated like
`EVC_Test_Procedures`), now drives the whole start of mission through
`DMI_Core`/`EVC_Core` connected as the bench page connects them, the
driver acting only through touch coordinates taken from
`DMI_Windows.Button_Area` and `Display.C_Area` (never a copied pixel),
with a cycle of the on-board on every touch; it reaches FS at the
first balise group (10721 `evc_test` checks, 0 failures).
`test/wasm/dmi_wasm.ads` gained a read-only `dmi_window_top` export (no
behaviour change) and `test/wasm/screenshots.js` now asserts the window
a navigation touch reached instead of trusting its coordinates blindly,
and selects "simulator (mock)" explicitly (it was written for
`EVC_Mock`'s dynamics, and the page's default changed above); its own
coordinates were already correct.

**SUBSET-076 runner** (branch `e4/s076-runner`, 2026-10-02):
`obj/evc_s076_run` replays the SUBSET-076 sequences of the sibling
checkout (3190 sequences of SV21, SV22, SV30; 276 000 steps) against
the whole on-board through its ports, with `DMI_Core` in the loop so
that the driver's inputs are touches on the real windows (no Render).
`S076_Sequences` parses a `.scn` (steps with their state columns,
telegrams with their tags and bits, the national timers, the speed
chart, the ERA workbook's train); `S076_Bench` is the world: a train
following the chart (or the step's speed) cycle by cycle at 100 ms,
balises placed at the step distance and crossed by the antenna, the
odometer sample with its confidence interval, the TIU inputs, and what
the on-board sends (the DMI frames, the two TIU outputs, the JRU
records), folded into a window per step; `S076_Run` maps each step: an
input is applied (BTM, ODO reach points and speeds against the
supervision limits and the national values of the sequence, TIU cab,
direction, sleeping, train data, SIM power, fault, odometer
degradation, INT timers, DMI touches), an output is judged against the
state, the window or the JRU (`S076_Tables`: JRU M_DRIVERACTIONS 21 of
56, DMI_SYMB_STATUS 36 of 110 bits, SYSTEM_STATUS_MESSAGE 13 of 31
bits, 12 whole JRU messages plus 3, 4, 11, 12, 20, 21, 23, 43 and ALL
by their fields), and the mode and level columns are checked against
the states the step's reaction block names. A step ends passed, failed
or not judged with one of fourteen reasons (never counted as passed); a
sequence passed, failed at step N, or blocked at step N by a reason.
The baseline (`test/s076/baseline.csv`) turns any earlier stop into a
failing run; `test/s076/triage.csv` gives every first failure a
category; `test/check.sh` runs it (30 s for the corpus).

Outcome: 468 passed, 808 failed, 1914 blocked; steps 133 714 passed,
5 501 failed (4 693 of them after the first failure of their
sequence), 16 034 not judged, 121 089 not run. Per version (passed /
failed / blocked): SV21 153 / 266 / 590, SV22 153 / 268 / 616, SV30
162 / 274 / 708. Blocked: 1214 need level 2/3 or the RBC (E5), 203
unreadable telegrams or steps in the sibling, 135 another system
version (E7), 72 SUBSET-076 defects, 67 runner gaps (the modification
of the maximum speed and of the SR data, the language, V_STEP speeds),
63 Euroloop, 60 NTC, 44 ATO, 27 E6. Not judged steps: 9920 JRU
messages or fields we do not record (38 cab status, 45 track
conditions, 51 remote shunting, the V_* fields of 20, NID_SOLR of the
header, ...), 3192 DMI internals (data values, echo texts, the time),
1639 E5. The failed sequences by the triage of their first failure:
371 braking curves (the ERA workbook's train, 750 m freight trains: our
supervision limits sit metres to tens of metres from the ERA tool's at
the sequence's locations, and the chart speed is a drawing; no
pre-programmed braking models, E6), 156 the runner's model (the chart
drives the train past a location before the step), 95 on-board gaps
still open (4.11 nothing kept over NP; 3.12.2.3 route suitability;
4.4.19.1.4 the LSSMA display; 4.8.5 the transition buffer; JRU driver
actions), 82 E6 (balise consistency 3.16.2.4 and 3.16.2.7, the
driver's adhesion 3.18.4.6), 41 SUBSET-076 (override at speed with the
default V_NVALLOWOVTRP 0, the override restarting the SR distance,
M_MODE 21, IS kept over a power off, the inputs of an inserted case
missing), 34 E5, 23 our DMI (the Main window from the start-up Driver
ID window, buttons enabled in a state), 3 E7, 3 NTC.

On-board defects found and fixed: the linking reaction's service brake
without "Balise read error" (3.16.2.6.1, SS 1, procedures Linking); the
roll away and reverse movement protections without "Runaway movement"
(3.14.2.6, 3.14.3.4, SS 9, SDM_Protections); a new announcement to an
acknowledged level kept the acknowledgement when its area was entered
later (5.10.4.1.3, E4_Level_Ack_Again). SUBSET-076 and extraction
defects met: M_LEVELTEXTDISPLAY 5 (the coding before 4.0.0) in 33 SV30
sequences, orders to level 3 in SV30, balise groups with a second
NID_BG, Q_UPDOWN 0 or a repeated N_PIG, the 4-bit M_MODE in SV30
5180200_03, telegram tables and header rows lost by the extractor. And
`evc_s076_check` had checked 1024 of the 3190 files
(`Scn_Reader.Max_Files`, now 4096): with all of them 23 451 telegrams
and 18 706 messages, 0 failures, the SV21 and SV22 envelope widths
counted as rejections.

Next: the 371 curve failures need the ERA tool's numbers for the
workbook train (or the pre-programmed models, E6); recording JRU 38,
45, 51 and the fields of 20, and a queryable DMI data view, would turn
13 000 not judged steps into judged ones; E5 unblocks 1214 sequences.

## 13. E5 — Radio, level 2: plan (2026-10-03)

461 clauses: the 180 rows of the phase (3.5: 95, 3.8.2/3.8.5/3.8.6: 32,
3.10: 14, 3.15.1: 23, 3.16.3: 15, 5.15: 1) and 281 rows the earlier
phases left for it (5.4 and 5.5: 48, 4.4: 44, 4.8: 37 of which 4.8.5: 13,
5.10: 28, 3.6.5 and 3.6.2: 27, 5.11: 16, 5.6: 12, 5.21: 9, A.3: 18, the
rest in 3.11 to 3.14, 5.7 to 5.9, 5.17, 5.19). It is what blocks 1215 of
the 3190 SUBSET-076 sequences.

What exists: the language of every radio message and packet in both
directions (E1, `ETCS_Message`), the RTM port as an input (one message
of chapter 8 per input; `EVC_Received` takes every sender for an RBC),
the acceptance tables of 4.8 for the balise side, the MA and its stores
(packet 12; packet 15 and the messages 3 and 33 share them), the
locations of the MA request and of the perturbation (3.13.11, proved,
not read by anything), the level table with level 2 "not available".

**The boundary** (decisions below): the on-board ends at the RTM port.
The port carries application messages of chapter 8 in both directions
and the events of the safe connection (established, lost, the request to
set up or release one with the RBC's identity and number); Euroradio
(SUBSET-037, the safe layer, the keys of SUBSET-038) is the port's other
side, as the BTM is for the balise air gap.

**Joint, first and small** (`e5/joint`, one agent, before the halves):
- `EVC_Ports`: RTM as an output too, and the connection events; the
  framing documented as BTM and TIU are.
- `EVC_Radio` (specification with contracts, bodies as stubs that keep
  the build and the proof green): the session table (two sessions, for
  the handover of 3.15.1), per session its state of 3.5, the RBC's
  identity, the system version agreed, T_TRAIN, the time stamp of the
  last message of each direction; `Send (Session, Message)` into an
  outbox the core drains in `Produce_Outputs`; `Received (Session)` for
  the consumers; the queries the two halves call on each other.
- The coverage matrix: the 461 rows assigned to a half (column note),
  the transition conditions each half owns.
- The SUBSET-076 runner and `evc_test`: the helper that gives a radio
  message to the on-board and reads the ones it sends.

**Session and link** (`e5/session`): 3.5 whole (set-up by order of the
trackside, by the driver at start of mission, at power-up after a level
2 standstill; the system version exchange of 3.5.3 with messages 32,
159, 154; maintaining, T_NVCONTACT and its reaction 3.16.3.4; the
termination, message 156 and 39; the radio network registration and the
"safe radio connection" indication to the DMI), 3.16.3 (time stamps,
sequence, the acknowledgement of messages 146, the link supervision),
the position reports of 3.6.5 (packet 58 parameters, message 136 with
packet 0 or 1, the events that trigger a report, the previous LRBGs of
3.6.2.2.2), the acceptance of radio information 4.8 with the transition
buffer of 4.8.5, the level 2 parts of start and end of mission 5.4 and
5.5 (the S-states with an RBC: 155, 129 and its acknowledgement 8,
157, 150; the RBC contact data and the level 2 entry of the DMI), the
level transitions into and out of level 2 (5.10, 5.15 with the two
sessions, 3.15.1 the RBC handover: packet 131, the announcement, the
border, the messages of both RBCs).

**Authority by radio** (`e5/authority`): the MA by radio (messages 3 and
33 with the shifted location reference, 3.8.5 the update, 3.8.6 the
co-operative shortening with message 9 and its answers 137/138), the MA
request 3.8.2 (message 132 and packet 57: T_MAR, T_TIMEOUTRQST, the
cycle, the reasons Q_MARQSTREASON; the first reader of 3.13.11), the
emergency messages 3.10 (15, 16, their acknowledgement 147 and the
revocation 18), the authorisations of the modes by the RBC (4.4 and the
procedures: SR authorisation 2, the trip recognition 6 and 5.11's
reports, the shunting request 130 and its answers 27, 28, 5.6; track
ahead free 34 and 149; the supervised manoeuvre 5.21; the reversing and
limited supervision parts), train data to the RBC and its changes
(5.17), the text message reports (message 158), the level 2 column of
the transition conditions still open ([20], [41], [81] and those marked
E5).

**Bench and sequences** (`e5/bench`, starts with the joint, integrates
at the end): `Sim_RBC` in `sim/` (a scripted RBC: session, MA on
request, handover to a second one, emergency stop on a button of the
page), the bench line with a level 2 section (the preset that orders
level 2 at 5000 m today), `onboard.wasm` and the smoke check; the
SUBSET-076 runner's RBC side (radio stimuli, the `expect RTM` vocabulary,
the 1215 blocked sequences unblocked step by step, each new failure
signature triaged).

**Order and size.** The joint is a day's work of one agent and gates the
rest. The two halves and the bench then run in parallel; `e5/session`
is the larger half and `e5/authority` depends on it only through the
`EVC_Radio` specification. Integration merges session, authority, bench,
then re-records the SUBSET-076 baseline once the differences are
understood. Rules for the briefs (from the E4 and the 2026-10-02 rounds):
a turn budget, loops as one command, phases with fresh agents for
anything over a day, the Ada language server for navigation; every new
body under 100 code lines with a contract, table loops with an
invariant, the restrictions and the 32 KiB stack budget, the proof
margins.

**Done** means: the on-board drives the bench mission through a level 1
to level 2 transition, receives its MA by radio, hands over to a second
RBC and stops at an emergency stop; `evc_test` has a scenario per
procedure; the 461 rows are `done`, or `partial`/`deferred` with a
reason; the sequences blocked for level 2 are down to those that need
E6 or E7; proof, fuzzers, stack and whole check green.

**Decisions (confirmed 2026-10-04):**
1. Euroradio (SUBSET-037/038) stays outside the on-board, behind the
   RTM port.
2. Two communication sessions are the default; the on-board must also
   handle the degraded case of one session only (3.15.1: the handover
   with a single session), selected by configuration and tested like
   the other.
3. Train integrity is reported as "no information" unless a TIU input
   says otherwise; no integrity monitoring device.
4. Radio infill (3.9) stays in E7.
5. The fuzzer gets a radio phase (an RBC that sends anything, at any
   time) as part of the bench package.

**Before E5 (2026-10-03).** Three preparations, merged: the sibling's
parser fixed (tables continued over a page break, captions with a title,
tables without rules: 203 unreadable sequences down to 134, of which 125
have exactly the packet rows of their PDF, so the rest are gaps of
SUBSET-076 itself, as are the input steps of inserted cases); the JRU
events 11 (driver's actions without an event of their own), 38 (cab
status) and 45 (track conditions) in the new `EVC_JRU_Records`, and
`DMI_Observe` (host only) for the data values a window shows; the five
findings of the code readings (§2). The runner on that state: 3190
sequences, 477 passed, 847 failed, 1866 blocked; steps 146747 passed,
5877 failed, 4649 not judged (16034 before: JRU not modelled 9923 to
about 1650, DMI internal 3192 to 98). More sequences fail because more
steps are judged. Open from it: a change of traction system to a line
not fitted is sent to the train interface as "traction system" where
5181000 expects "main power switch off" (SUBSET-034 2.4, signature
S707f6e73); the stored position at start of mission (5.4.3.3,
Sa184249e); the train running number revalidated after the Train Data
(5.4.3.2 S13, S274cb49d); the two DMI flow cases of §12 not yet checked
against the DMI specification; 40 telegrams the extractor refuses.

**The unreadable sequences (2026-10-04).** The 134 sequences blocked as
unreadable were checked against a second, independent reading of their
PDFs: 60 were a defect of the runner (the plain text packet is 72 up to
system version 2.1 and 73 from 2.2; "packet 72/73" in a step is an
alternative), 66 name packets their telegram table does not hold, 5
lose header rows at a page break of the PDF, 3 have a wrong Length in a
packet 44 row. Over the whole corpus the same checks find 141 such
steps in 121 sequences; the report for the maintainers of SUBSET-076
and the scripts are in the sibling repository (`reports/`,
`tools/findings/`). The runner now: 487 passed, 887 failed, 1816
blocked (1236 for level 2, 144 for defects of SUBSET-076).

**Last preparations (2026-10-04).** The four oversize bodies of the
units E5 edits are split (`EVC_Mission.Evaluate`, `EVC_Driver_Requests.
Receive`, `EVC_Position.Evaluate` and `Update`; the postcondition of
`Update`, once the slowest proof, from 4.2 s to 0.1 s). Both projects
build and the on-board proves without a warning, and `check.sh` and
`prove.sh` fail on one. What is kept over No Power is in `EVC_Retained`
(4.10 column NP, 4.11.1.1, .3): the level, the table of priority and
the train position come back invalid through `EVC_Core.Power_Up` and are
revalidated by the cold movement information; `Initialise` is a new
on-board with an empty store; a position still invalid is deleted when
the start of mission leaves SB (5.4.3.2 S22 to S24). E5 fills the RBC
contact slot of `Kept_T` and reads `EVC_Position.Status` for the
position report of the start of mission. Not done: 5.4.3.3 D2 and
S10/S20 (level and RBC data to invalid), 4.11.1.4, a position that
refers to unlinked groups only is not kept, and the bench sends no cold
movement information (signature Sef5e0918). Two of the three runner
signatures looked at were defects of SUBSET-076 (a telegram with
Q_LINK = 1 where the step says 0; a step its own comment calls
incompatible). The runner: 487 passed, 884 failed, 1819 blocked.


### Joint: outcome (2026-10-05)

Branch `e5/joint`. The on-board behaves as before: every golden, test
line, EFS frame and SUBSET-076 outcome unchanged; the stubs count what
they are given and decide nothing.

**The RTM port** (`EVC_Ports`, end of the package). Inputs: a message of
chapter 8 without a tag (the format of E1 to E4) is the message of
session 1; a first byte from `RTM_Tag_First` (16#F0#) on is a tag, which
no NID_MESSAGE has: `RTM_Tag_Message` (16#F1#), session u8 (1 or 2),
message: the message received in that session; `RTM_Tag_Event`
(16#F2#), session, event u8: 1 the safe radio connection set up, 2 lost
(3.5.4.1), 3 released, 4 set-up failed (3.5.3.7 a), 5 the mobile of the
session registered to the radio network, 6 its registration failed. The
events latched between two cycles are taken before the messages.
Outputs: `RTM_Tag_Message`, session, a train to track message;
`RTM_Tag_Request` (16#F3#), session, request u8: 1 set up a safe radio
connection (NID_C u16, NID_RBC u16, NID_RADIO u64 as coded, radio system
u8 0 GSM-R / 1 FRMCS; 16 bytes), 2 release it (3 bytes), 3 register the
mobile to the GSM-R network NID_MN u24 (6 bytes). `Valid_RTM` stays the
shape of a message; `Valid_RTM_Input` is the shape of an input.
`Max_Payload (RTM)` is 1025. The fuzzer sends tagged messages and events
(sessions and events now and then out of range).

**Ownership of the state** (`EVC_Radio`, header). `EVC_Radio` holds and
decides nothing: the session table (per session its state `Idle`,
`Connecting`, `Initiating`, `Established`, `Connection_Lost`,
`Terminating` as 3.5 names its steps, the RBC identity and number, the
system version agreed, T_TRAIN and the on-board time of the last message
received, T_TRAIN of the last sent), the roles of 3.15.1 (supervising,
accepting session), the RBC contact information (`RBC_Contact_T`, the
type of `EVC_Retained.Kept_T.RBC`), the radio network, the outbox.
`EVC_Sessions` is the only writer of the table, the roles, the contact
and the network (`Set_State`, `Set_Peer`, `Set_Version`,
`Note_Received`, `Reset_Session`, `Set_Roles`, `Set_Contact`,
`Set_Network`); `EVC_Radio_Authority` reads them. Both send
(`Send (Session, Message)`, `Request_Set_Up`, `Request_Release`,
`Request_Registration`): the outbox (2048 bytes) never raises, a message
for a session the on-board does not handle or without room is refused
and counted (`Refused`); `Send` records the T_TRAIN of what it queued.
`EVC_Core` clears the unit at each power-up with the sessions of the
configuration, restores the contact kept over No Power invalid
(`Restore_Contact`), saves it each cycle (`Save_Retained`) and drains
the outbox to the RTM port as far as `EVC_Outbox` has room (`Drain`;
the rest waits, in its order). Queries for both halves are expression
functions over `Info (S)`: `Usable`, `Established` (also while the
connection is lost, 3.5.4.1), `Being_Established` (3.5.3.8),
`In_Session_With`, `In_Communication` (the supervising RBC's session
established: 4.8 and the mode conditions), `Supervising_RBC`,
`Handover`, `Supervising_Version_Known`, `Roles_Consistent`. The private
state of each half stays in its unit (timers, repetitions, the
transition buffer, the report parameters; the MA request, the emergency
stops, the acknowledgements owed).

**Configuration.** `EVC_Config.Config_T.Radio.Sessions` (1 or 2, default
2): like the fixed Train Data, not in the image of format version 1;
`EVC_Config.Set_Radio_For_Test` selects one session for the tests until
a format version carries it (for the bench page too: the bench half).

**Entry points and their order in the cycle** (`EVC_Core.Tick`):
1. ports (`Read_Ports`): `Read_Radio_Events` (each event:
   `EVC_Sessions.Take_Event (S, Event)`), `Read_Radio_Messages` (each
   message the codec accepts, after its JRU record:
   `EVC_Sessions.Take_Message (S, Verdict)`; `Pass` goes on to
   `EVC_Radio_Authority.Take_Message (S)`, `Ignore` and `Buffered` stop),
   `Read_Released_Messages` (4.8.5: while `EVC_Sessions.Has_Released`,
   `Take_Released (S, Data, Last)` gives a message of the transition
   buffer back; the core parses it again and the authority takes it);
5a. after the levels and the mission, before the procedures:
   `Evaluate_Radio` = `EVC_Sessions.Evaluate (Ctx)`, then
   `EVC_Radio_Authority.Evaluate (Ctx)` (`Ctx`: the mode and the on-board
   time; the conditions of 4.6.3 are computed here, as EVC_Procedures
   does);
6b. after the mode machine, when the mode changed: `Radio_Mode_Changed`
   = both `Mode_Changed (From, To)`;
8k. the last outputs: `Send_Radio` = `EVC_Sessions.Produce (Ctx)`, then
   `EVC_Radio_Authority.Produce (Ctx)`, then `EVC_Radio.Drain`.
The stubs' Global contracts name only their own state; a half that reads
or writes more widens its contracts and those of the core steps above
(the expected merge points: `Read_Ports`, `Read_Radio_Messages`,
`Evaluate_Radio`, `Send_Radio`, `Produce_Outputs`, `Tick`, whose
`EVC_Radio.State` is an Input until `EVC_Sessions` writes the table).

**Conditions of 4.6.3** (`EVC_Transition_Conditions.Holds` dispatches):
session half 1: [41] (`EVC_Sessions.T_NVCONTACT_Trip`); authority half
6: [6] `Shunting_Granted`, [11] `Group_At_EOA_In_RSM`, [20]
`Unconditional_Stop_Accepted`, [31] `MA_On_Board_Level_2`, [36]
`Group_Not_In_SR_List`, [81] `SM_Authorised`, and
`Unconditional_Stop_Received` in [45]. Not evaluated: [24], [33], [48],
[53], [80] (AD), [83] (the safe consist length: no radio in it, the
matrix row says E5; left to the integration), [35], [38] (NTC), [55],
[57], [64] (absent from 4.0.0).

**The matrix** (doc/TRACE-SUBSET-026.csv, the note ends with the half):
463 rows: 180 of the phase (session 133, authority 46, joint 1: 3.5.2.4,
now partial) and 283 earlier rows deferred or partial for E5 (session
170, authority 112, joint 1: the 4.6.3 table); bench 0. By the longest
clause prefix, then exceptions:

| half | clause prefixes |
|---|---|
| session | 3.4.2, 3.5, 3.6.2, 3.6.5, 3.6.6, 3.12.1, 3.14.1.7, 3.15.1, 3.16.3, 4.8, 4.11.1, 5.4, 5.5, 5.10, 5.15, 8.4.4, 8.5.2, 8.5.3, A.3.1 Table, A.3.11 |
| authority | 3.7, 3.8, 3.10, 3.11, 3.12.3, 3.13, 4.4, 4.9, 5.6, 5.7, 5.8, 5.9, 5.11, 5.17, 5.19, 5.21, A.3.4, A.3.5 |
| session (exceptions in 4.4: sessions, reports, handover) | 4.4.6.1.4, 4.4.6.1.10, 4.4.6.1.13, 4.4.7.1.6, 4.4.8.1.3, 4.4.8.1.5, 4.4.15.1.3, 4.4.15.1.4, 4.4.18.1.7, 4.4.20.1.4, 4.4.20.1.12, 4.4.20.1.13 |
| joint | 3.5.2.4, 4.6.3 Table |

**Tests.** `EVC_Test_Support`: `RTM_Tagged`, `RTM_Event_Input`,
`Give_Radio_Message`, `Give_Radio_Event`, `Start_Message`,
`Message_Bytes`, `Message_Of` (ETCS_Message), `Radio_Outputs`,
`Radio_Output` (session, message or request, NID_MESSAGE or request
code), `Decode_Radio_Message` (ETCS_Message.Parse, train to track),
`Request_Byte`. `EVC_Test_Radio.Scenario_Radio_Joint` (22 checks): the
port and the stubs, the outbox to the port and back, the contact over
No Power, one session by configuration. The SUBSET-076 runner feeds no
radio input yet and is unchanged; its radio side is the bench's.

**What each half fills.**
- Session and link (`EVC_Sessions`): the bodies of `Take_Event`,
  `Take_Message` (3.16.3 time stamps and order, the session messages 32,
  39, 41 of 5.4, 4.8 for radio information, the verdict), `Has_Released` /
  `Take_Released` (4.8.5), `Evaluate` (3.5 states and timers of A.3.1,
  T_NVCONTACT and [41], 3.5.6 networks, 3.5.7 indication to the DMI,
  position reports 3.6.5, the level 2 start and end of mission, 5.10 and
  5.15, the handover and its roles), `Mode_Changed`, `Produce` (155, 159,
  156, 136, 129, 150, 154, 157 ...); the contact into `EVC_Radio` (and
  its revalidation, 4.11.1, 5.4.3.3 D2); a format version of the
  configuration image with the sessions if the bench needs it.
- Authority (`EVC_Radio_Authority`): `Take_Message` (3, 33, 2, 6, 9, 15,
  16, 18, 27, 28, 34, 45 ... into the stores of E3 and the procedures),
  `Evaluate` (the MA request of 3.8.2 and its reasons, the emergency
  stops, the conditions [6] [11] [20] [31] [36] [81] and the stop of
  [45]), `Mode_Changed`, `Produce` (132, 137, 138, 147, 149, 130, 158,
  the Train Data of 5.17).
- Bench (`sim/`, `test/src/s076_*`): `Sim_RBC` behind the RTM port in the
  format above (events and tagged messages in, outputs read like
  `Radio_Output`), the runner's `expect RTM`, the fuzzer's radio phase
  (decision 5).

### Bench and sequences, first round (e5/bench-1, 2026-10-05)

**The SUBSET-076 runner's radio side** (`test/src/s076_run-radio_input.adb`,
`s076_run-radio_expect.adb`, `S076_Bench` RTM capture, the message blocks in
`S076_Sequences`). The RBC of a sequence is a script in session 1:
`input RTM connect` gives the event "set up" at the step, asked for or not
(the step before, `expect RTM connect`, judges the request); `disconnect`
is "released" after a release request or message 156, else "lost";
`registration` is "registered"; `message N` is the step's message block
with its time stamps set as an RBC sets them (3.16.3.2.2, 3.16.3.3: the
last T_TRAIN of the on-board in the session plus the time since, strictly
increasing; the answered T_TRAIN of messages 4, 5, 7, 8, 27, 28). The
expectations: a request to set up, release or register (NID_MN) in the
window; message N decoded with `ETCS_Message` with the packets and fields
the line names; their negations. Level 2 steps run. The reason "E5" is
narrowed to: E5-radio (the RBC data dialogues of the DMI when the
on-board opened them, radio timers without a name, the SM symbol),
E5-handover (the RTM steps after an RBC transition order: the runner does
not tell two RBCs apart yet), E7-infill (153, message 37), L3 (absent
from 4.0.0). The report's "## Radio" section is the work list of the two
halves: per output of the on-board, the sequences waiting for it. On the
branch with the stub halves: 498 passed (none of the 487 lost), 2018
failed, 674 blocked (1819 before); the first failure of 1044 sequences is
the connection request, then 155, 159, 129, 156, 136, 132 ... (sessions
1135, 1116, 988, 316, 295, 160).

**Sim_RBC** (`sim/sim_rbc`), behind `Sim_Onboard_Env.Set_Radio` (off by
default): connection, session (155/32, 159/38), Train Data (129/8), MA
on request (132/3, packet 15 to the bench line's EOA from the reported
LRBG), termination (156/39), release, an emergency stop on command (16);
RBC 2 and `Handover` are the interface only. `EVC_Test_RBC.Scenario_RBC`.

**The fuzzer's radio phase** (`obj/evc_fuzz`, decision 5): messages of
every track to train NID_MESSAGE with random fields and packets, tagged
for either session or untagged, damaged or truncated, events in any order,
oversized and random inputs; floor: every NID and every event in both
sessions, one message in 50 accepted by the codec.

**Left for the next round of the bench:** the bench page with Sim_RBC on
the level 2 section of the default line (a selector, the emergency stop
button, `onboard.wasm`), once the halves send something; the handover in
the runner (telling the RBCs apart from the identities of packet 131/42
and the connection requests) and in Sim_RBC; the RBC data dialogues of
the DMI in the runner; the re-recorded baseline after the integration of
the halves.

### Authority by radio, phase 1 (e5/authority-1, e5/authority-2, 2026-10-05)

**Implemented** (`EVC_Radio_Authority`, the leaf `EVC_Radio_Info`, test
package `EVC_Test_Authority`):
- The MA by radio, messages 3 and 33 (3.8, 3.6.2.2.2 c): the message goes
  to `EVC_Radio_Info` with its origin (the LRBG it names,
  `EVC_Position.Radio_Origin`, shifted by D_REF for 33) and is taken by
  the stored information of the same cycle like a balise group; the
  timers start at its time stamp (3.8.4.2.1 a); [31].
- The MA request, 3.8.2: message 132 with packet 0 and Q_MARQSTREASON
  (Start, perturbation location of `EVC_SDM.Result_T.MA_Request`, the
  section or LOA timer within T_TIMEOUTRQST, the track description
  deleted by an MA timer), the parameters of packet 57, the repetition
  every T_CYCRQST (A.3.1 TCYCRQSTD without parameters), level 2 only.
- The co-operative shortening, 3.8.6: message 9 makes a proposed MA that
  is not stored (`EVC_Stored_Information.Take_Proposal`,
  `EVC_Movement_Authority.Authority_Of`, `Snapshot.Extra.Proposal`);
  `EVC_SDM.Step` evaluates it with the curves and the context of the
  cycle (`Proposal_In_Rear`: one `Eval_T` more on the stack of Step, no
  copy of the snapshot or the work area); granted: the message is kept
  (`EVC_Radio_Info.Keep_Granted`) and taken as the MA by the next cycle,
  137; rejected: nothing changes, 138.
- The emergency messages, 3.10: 15 judged by the stored information
  (`Take_Stop`, `EVC_Movement_Authority.Conditional_Stop`, Q_EMERGENCYSTOP
  0, 1 or 3), 16 ([20], [45]), 18, the table by NID_EM, 147 for 15 and 16,
  no MA nor shortening while a stop is not revoked (3.10.2.4), the stops
  deleted by the modes of 4.10.

**Decisions.** The on-board's T_TRAIN is `(Now_Ms / 10) mod (2**32 - 1)`;
NID_ENGINE is 0 until the configuration carries it; packet 0 of the
authority's messages is built by `Send_With_Report` from
`EVC_Position.Position_Report` (to be unified with the session half's);
a granted shortening takes effect one cycle after the request (the
message is taken by the stored information of the next cycle);
the indication limit of a proposed MA is that of the current speed (also
below the release speed); a request to shorten outside level 2 is
rejected (138); a message 15 whose Q_DIR is not valid for the train is
rejected (Q_EMERGENCYSTOP 3); an accepted conditional stop withdraws the
EOA and SvL (no release speed, the timers of the MA stop); the stops
survive the end of a session (no clause deletes them); answers and
acknowledgements owed go to the session of the message and are dropped
when it is no longer established; 4.8 acceptance is the session half's
verdict.

**Left:** the trigger "track ahead free up to the level 2 transition
location" of 3.8.2.4 (packet 90, one request with packet 9); scenarios
for the perturbation trigger, for the end of the Start reason by the
desk closed and by an SR authorisation, for 3.10.2.2 b) 2nd and 4th
bullets; the deletion situations of A.3.4 not yet covered; the mode
authorisations of the RBC (messages 2, 6, 27, 28, 34, the conditions
[6], [11], [36], [81]), 5.17 Train Data, 5.21, message 158; the
acknowledgement of message 18 by M_ACK (session half).

### Session and link, phase 1 (e5/session-1, e5/session-2, 2026-10-05)

**Implemented** (`EVC_Sessions`, scenarios in `EVC_Test_Sessions`,
55 `[E5 session]` rows done or partial). The communication session of
3.5: the order of packet 42 (a new kind K42 of the stored information,
dispatched next to K15 on the balise and the radio path, given to
`Take_Order`, applied by the next `Evaluate`; 3.5.3.13 the last known
RBC, 3.5.3.15 the short number, the contact stored, 4.10.1.4.2 b), one
RBC at a time (3.5.3.4.1, 3.5.3.4.2, 3.5.3.5.2) with one or two sessions
by configuration, the set-up request repeated at once (3.5.3.7 a), 155,
32 with the version check of 3.17.2 (159 with packet 2, or 154, DMI entry
15 and the termination), the waits and repetitions of A.3.1 (3.5.3.7.3,
3.5.3.7.4, 3.5.3.7.4.1, 3.5.5.3.1, 3.5.5.3.2), the connection lost and
kept for 5 minutes (3.5.4), the termination by 156 / 39 (3.5.5, nothing
but 39 taken after 156); the time stamps of 3.16.3 (an older T_TRAIN
ignored, 146 for M_ACK = 1 with the stamp of the message) on the clock of
`EVC_Radio.T_Train_At`; T_NVCONTACT (3.16.3.4: the trip of [41] with its
reason `Communication_Lost` in `EVC_Procedures`, DMI entry 5; the service
brake, DMI entry 4, released by a new message or at standstill, 3.14.1.7;
60 s later released and set up again, 3.16.3.4.3); the indication of the
safe radio connection (3.5.7, Table 1 by [2] to [6], the connection status
timer of 45 s) as the radio byte of MSG_STATUS.

**Decisions.** (1) A message on a session not yet established passes to
the authority half until the acceptance of 4.8 comes (phase 2). (2) The
session established first becomes the supervising RBC's (3.15.1 is phase
2). (3) T_NVCONTACT is supervised in any level while the session of the
supervising RBC is established, also while its connection is lost. (4) A
connection lost while terminating ends the session (no 39 can come). (5) A
"released" event the on-board did not order counts as lost (3.5.4.1).
(6) NID_ENGINE is 0 until the configuration has an ETCS identity (E8).
(7) Q_SLEEPSESSION is ignored (no sleeping trains). (8) The indication
follows the supervising RBC's session, before there is one any session
(3.5.7.6 by the change of the supervising session; no handover yet).
(9) The service brake of T_NVCONTACT expiring at standstill is released at
once and not shown.

**Left for phase 2:** the start and end of mission in level 2 (5.4.3.2,
5.5: the RBC contact and its validity, the driver's RBC data, the three
attempts of A.3.1 with Table 2 [1], the SoM position report 157 with the
RBC's answer, Train Data 129 / 8 and the query "Train Data acknowledged"
the authority half needs in `EVC_Radio`, 150, D2, S10/S20, level 2 in
`EVC_Levels`); the acceptance of 4.8 and the transition buffer of 4.8.5;
the position reports of 3.6.5; the radio networks and registration of
3.5.6; the radio holes (3.5.4.4, 3.16.3.4.1.3, Table 2 [7]); the
handover (3.15.1, 3.5.3.5.2.1 with the transition order, 3.5.7.6,
3.16.3.4.1.2); 3.16.3.4.1.1 (the time of the level transition); the
shortening of 3.16.3.4.5 b) (the authority half's, A.3.4); a time stamp
increment between two messages of the same cycle (3.16.3.3.2: they carry
the same T_TRAIN today); informing the RBC of an inconsistent message
(3.16.3.1.1.2).

### Authority by radio, phase 2 (e5/authority-3, 2026-10-06)

**Implemented** (`EVC_Radio_Authority`, the level 2 part of E4's
procedures in `EVC_Procedures`, scenarios in `EVC_Test_Authority`):
- Staff Responsible in level 2 (4.4.11): message 2 gives the SR distance
  (D_SR, supervised from its reception, 4.4.11.1.3.1 b), which applies
  while it is the last value received (4.4.11.1.6.4: `EVC_Core.SR_Distance`
  takes `EVC_Radio_Authority.SR_Distance_Of (EVC_Mission.SR_Distance)` for
  the snapshot, `SR_End` and [42]; the driver's later entry and
  "Override" delete it), and the list of expected balise groups of
  packet 63: [36] (trip reason `SR_Balise_Not_Listed`, DMI entry of "stop
  if in SR"), the exception of [54] for a listed group
  (`EVC_Procedures.Context_T.SR_Listed`); message 2 ends the MA request
  reason Start (3.8.2.3.2 b).
- Post trip in level 2 (5.11): message 6 taken in PT
  (`Trip_Exit_Recognised`); before it no MA, track description, SR or SH
  authorisation is taken (A035, 4.8.4 [1]) and "Start" requests no MA
  (S120); with an emergency stop pending "Start" waits (D130, S130).
- Shunting in level 2 (5.6): the driver's selection sends 130 with the
  position report (A045); 27 and 28 are taken only when they name the
  last request (4.8.4 [14], `EVC_Received.Last_Field`); 28 is [6] with its
  packet 49, which `EVC_Procedures` takes on entering SH (A050); 27 and
  the failure after 3 repetitions every 15 s (5.6.4.1) give the DMI
  system status 12 / 14 (`Status_Entry`); MSG_ONBOARD waiting 4 and
  answer (`SH_Waiting`, `SH_Answer`).

**Decisions.** Message 2 carries no speed: the SR speed limit stays the
national or the driver's. The RBC's SR distance and list survive the
entry of SR from SB or PT only; any other change of mode deletes them;
"Override" deletes the distance, not the list ([36] is off while the
override is active). D_SR "infinite": no SR distance (the national value
does not come back). Packets 63 and 49 by radio are taken whatever their
Q_DIR; the first group's country is the LRBG's of the message. Without
the session of the Supervising RBC a request for shunting fails at once.
The grant [6] holds in the cycle of the answer only (at standstill).
Messages 2, 3, 33, 9, 27, 28 are ignored in TR and in PT before message
6; message 6 outside PT is ignored.

**For the acceptance of 4.8 (session half).** Message 2: SB [2][4][11],
SR, PT [1][4]; 6: PT only; 27, 28: SB [2][14], SM, FS, AD, LS, SR, OS
[14], PT [1][14] ([14] can use `SH_Request_Stamp`); 34: SB [2], LS, SR,
OS, PT [1]; 16: SB [2], SM, FS, AD, LS, SR, OS, UN, SN (not SH, PS, TR,
PT, RV: today an unconditional stop trips the train in every mode it is
taken in). [1] is `Trip_Exit_Recognised` with a later time stamp.

**Left:** [11] (a linked group at or beyond the EOA in release speed
monitoring); the SR proposal in PT level 2 on message 2 (5.11.2.2 S150 a,
S160: `EVC_Mission`, which can read `EVC_Radio_Authority`); the reports of
the mode change and their repetitions (5.11.2.2 A030, A115, 5.11.4.1,
5.6.2.2 A095, 5.6.4.2, 5.6.4.3) and the termination after a failed
request for shunting (`SH_Request_Failed`): the session half; a scenario
for the exception of [54] (the radio scenarios' track has no packet 137)
and for 3.8.2.3.2 c); track ahead free (3.15.5, messages 34 and 149,
MSG_MODE_LEVEL taf, the trigger of 3.8.2.4 with packet 90); the
Supervised Manoeuvre of level 2 (5.21, [81]); message 158; the Train Data
of 5.17.

### Session and link, phase 2 (e5/session-3, 2026-10-06)

**Implemented** (`EVC_Sessions.Mission`, a private child of
`EVC_Sessions` whose state is part of the parent's; scenarios
`Scenario_Session_SoM_Level_2`, `_SoM_Failures`, `_EoM` in
`EVC_Test_Sessions`). The level 2 start of mission of 5.4.3.2: D2 (the
contact valid -> invalid, 5.4.3.3), D7 with a known contact, the driver's
RBC contact of S3 (MSG_DRIVER_DATA kind 5: entered, 'Contact last RBC',
'Use short number'; also at S10 / S20, 5.4.5.3 j), A31 with the three
attempts of A.3.1, D31 (the contact valid) / A32, the SoM position
report 157 with Q_STATUS (D32, A33, A34; packet 11 when the Train Data are
valid), the answers 43 (A35: `EVC_Position.Revalidate` by `EVC_Core`), 41
(D34) and 40 (D35, A40: 156 and "Train is rejected", DMI entry 20;
the deletions of A24 / A39 are decided but not applied: they break the
postcondition of Tick on 3.6.4.1.2, left), 5.4.3.2.2; the Train Data to the RBC of 3.18.3.4 (129 with packets 0
and 11 when the supervising session is established with valid Train Data
and when the driver validates them, repeated every 15 s until message 8
acknowledges them, again after a connection set up again, 3.18.3.4.2);
`EVC_Radio.Train_Data_Acknowledged` (D15 / S11; MSG_ONBOARD rbc bit0); the
end of mission (5.5.3.1.3, 5.5.3.1.4, 5.5.4.1: 150 with packet 0,
repeated while the desk is open, the session terminated after the
repetitions); 'Start' in level 2 with a session proposes no mode (5.4.5.3
h, S21: the MA request is the authority half's). MSG_ONBOARD now carries
the session byte, the contact's status (data bit4, radio bit7), the
acknowledgement (rbc bit0) and waiting 2 during A31. NID_ENGINE:
`EVC_Config.Radio_Config_T.Engine_Id` (default 0, not in the image of
format version 1), `EVC_Radio.Engine_Id` for both halves (taken at
`Clear`); the SUBSET-076 bench sets 76000 (9093 of the corpus's 9271
NID_ENGINE rows).

**Decisions.** (1) D7 / S4: the radio networks are not modelled (3.5.6
left): a stored level 2 with a known contact opens the session at D7.
(2) The Train Data of the start of mission go in 157 (packet 11) when
valid then; message 8 acknowledges them as it does 129. (3) Message 8
acknowledges when its second T_TRAIN (8.7.4 field 6) is the T_TRAIN of
the message that carried them. (4) 129 is repeated every 15 s without a
limit until acknowledged. (5) D34 / D35 "valid position referred to an
unlinked balise group": a Valid position that was not reported "valid
referred to an LRBG" is kept, anything else deleted. (6) N_AXLE 0 and
M_AIRTIGHT 0 in packet 11 (not in the installation data). (7) 'Use short
number': the RBC identity of the session is 0 (unknown). (8) 'Start' in
level 2 with a session is not refused before the Train Data are
acknowledged (D15): the authority half's MA request is to wait for
`EVC_Radio.Train_Data_Acknowledged`.

**Found and fixed.** `EVC_Driver_Requests` took the RBC data frame only
with 24 bytes; the DMI sends 23 (the kind and 22 bytes,
`Driver_Data_RBC_Length`): no driver's RBC entry ever reached the
on-board.

**Left for phase 3:** the train running number (packet 5) and the safe
consist length (packet 10) in 157; the position reports of 3.6.5 (136:
the events of 3.6.5.1.4, packet 58, at mode and level changes, the last
reported LRBGs of 3.6.2.2.2 c); S4 and the radio networks (3.5.6, D7 /
D8 / D9, A29, A41 to A43, S5); the driver's Radio Network type and GSM-R
network ID; SM at S10 (E34, E35); the acceptance of 4.8 and 4.8.5; the
handover; level transitions into and out of level 2 (5.10, 5.15); the
SUBSET-076 runner's filling of the Radio data window (the 51 sequences
blocked at "E5-radio": the sequences give the driver's entry only in a
comment, e.g. "The Driver enters: RBC ID = 1").

### Bench and sequences, second round (e5/bench-2, 2026-10-05)

**Runner, the driver at standstill** (`Press_Menu` in `s076_run.adb`): a
menu button that is disabled is looked at again for up to five cycles
while the train is at standstill, because the DMI receives the standstill
one cycle after the on-board has it. 4 sequences moved (3 more
passed, one went on to step 90); the triage line Scd518a05 is gone. Summary before
the round: 518 passed, 1928 failed, 744 blocked; after: 521 / 1925 / 744.

**Runner, the RBC data windows** (`RBC_Data_Entry`, `Radio_Values`):
`press Enter-RBC-data`, `Contact-last-RBC`, `Use-short-number` press the
buttons of the Radio data window (Table 37) and `enter` / `confirm` /
`validate RBC-data` type the RBC ID and phone number into the RBC data
window by touch (Tables 22, 25) and end the entry. Decision: a value is
used only when a comment of the step or of the ten steps before it names
it ("RBC ID = N", "ETCS ID : N", "RBCid: N", "RBC phone number = N",
"Phone : N"); otherwise the step is blocked ("RBC data: the sequence
names no value", still E5-radio): 35 sequences. The steps give no value
at all (88 `enter RBC-data`, no field); nothing was invented. The other
radio dialogues (GSM-R network ID, Radio network type, Mission with one
radio system) stay blocked. Finding: the buttons are disabled in the
DMI because `EVC_Core.Send_Onboard` does not report the radio equipment
in the MSG_ONBOARD radio byte (bits 0-1 network type, 2-3 installed, 4-5
registered, 6 one radio: only bit 7 "contact known" is sent), so
Table 37 #1 to #3 can never be enabled by the on-board. 49 sequences
moved from blocked to failed at the press (signatures S96bd5570,
S9ca3aeaf, S36a6b300, triaged `onboard`). `S076_RADIO_STATUS=1` ORs the
bits of GSM-R only, registered into the frame the runner gives the DMI,
a verification aid that hides the gap (never in the baseline): with it
the same 49 go further and most of them stop at the step that names no
value (35 steps in the report).

**Runner, a second RBC** (`Route` in `s076_run-radio_input.adb`,
`RBC_Alive`, `RBC_Current`): the sequences identify the RBC by the order
of events only (no NID_RBC on a step). `connect` goes to the session
whose request the on-board made and that has no connection; a message
goes to the session set up last, 39 to the session that sent 156, 24
with packet 42 and `disconnect` to the session being left; with one
session alive everything is session 1 as before. The block E5-handover
is gone (the reason stays in the table, empty). 13 sequences moved from
blocked to failed (mostly Sa8a3ba1a, connect not requested, and
S13c9beb3, message 136 not sent; three sequences that failed at the
latter already now fail one step earlier): the handover of 3.15.1 is not implemented. One new
signature, Se3765f9b (4080300_13 step 64): a balise group with an RBC
transition order and packet 42 (Q_RBC=1) makes the on-board send 156 to
the handing RBC, where the sequence waits for no termination: suspected
on-board defect (packet 42 of an RBC transition must not end the session
with the handing RBC, 3.15.1). Summary after the round: 521 passed, 1987
failed, 682 blocked.

**Left:** the bench page (task 4) was not started. Needs: a third track
preset or a switch (`onboard_set_radio` export calling
`Sim_Onboard_Env.Set_Radio`, which exists and is unused), the level 2
start-of-mission frames (the Text_Entry / Action 11 level 5 / RBC_Entry /
Train_Entry / Action 5 of `Scenario_Session_SoM_Level_2`, each sent after
the answer of the one before, not blind at cycles 0 to 5 as the level 1
frames), `Sim_RBC` answers it lacks (41 "train accepted" to the
SoM position report 157; 43 is not needed by the on-board's current
Mission), the page line and one check of `onboard_smoke.js` that the
level 2 line reaches FS by radio; the default mission and its golden
must stay unchanged. The RBC data windows of the runner will do more
once the on-board reports the radio equipment in MSG_ONBOARD; the
GSM-R network ID / Radio network type dialogues and the values of
`enter RBC-data` that no sequence names are still blocked.

### Authority by radio, phase 3: acceptance and leftovers (e5/authority-4, 2026-10-06)

**Implemented** (`EVC_Radio_Acceptance`, the private child
`EVC_Radio_Authority.Buffer` whose state is part of the authority's,
scenarios `Radio_Acceptance`, `Transition_Buffer`, `Start_After_Ack`,
`Track_Ahead_Free` in `EVC_Test_Authority`):
- 4.8 for the RBC (taken over from the session half): the rows "From
  RBC: Yes" of 4.8.3 and the RBC rows of 4.8.4 for the messages taken by
  radio (2, 3, 33, 6, 9, 15, 16, 18, 27, 28, 34) as tables
  (`First_Filter`, `Third_Filter`, `Verdict`), applied at the start of
  `EVC_Radio_Authority.Take_Message` with the context of the last
  cycle (`Buffer.Update` in `Evaluate`; the mode and message 6 of the
  cycle). Message 16 no longer trips in SB without a cab, PS, SH, SL,
  NL, TR, PT, RV; 18 is rejected in TR.
- The transition buffer of 4.8.5 for 4.8.3 [2] (an MA, conditional or
  unconditional stop in level 0/1 with level 2 announced): `EVC_Core`
  stores the message (`To_Buffer`, `Store_Message`) instead of giving
  it; three messages, the oldest replaced; deleted by 4.8.5.4 a), c);
  released when the level is 2 (`Has_Released`, `Take_Released`, in
  `Read_Released_Messages` after the session half's).
- 5.4.3.2 D15 / S11: in SB the driver's Start in level 2 requests the
  MA once the Train Data are acknowledged.
- NID_ENGINE of the authority's messages is `EVC_Radio.Engine_Id`.
- Track ahead free, 3.15.5 (message 34, 149): shown on MSG_MODE_LEVEL
  taf (`EVC_DMI_Port.Mode_Level_Frame` gained `TAF`), answered by the
  driver's TAF_Yes, ended at its end, out of level 2 and by the modes of
  4.10.

**Decisions.** A message rejected by 4.8 is ignored, except a request to
shorten the MA, answered 138 (3.8.6.1 c). The released messages are
taken in the cycle after the level transition (the stored information
of a cycle is evaluated before its levels). [3] of 4.8.3 counts an
acknowledgement seen in the ongoing session (Train Data sent again do
not reject). 3.16.3.3.2 is the trackside's: the on-board's messages of
one cycle may share T_TRAIN. Message 34 is taken only when it refers to
the on-board's LRBG; its window is placed from the estimated front end
at reception, Q_DIR not checked. A rejected 34 is not stored. Start in
SR or PT does not wait for the acknowledgement.

**Left:** 4.8.3 [3] is in the table but not fed (`Train_Data_Unacked
=> False` in `EVC_Core.Evaluate_Radio`): with it 87 SUBSET-076
sequences of a level 2 transition regress, as the session half does not
recognise message 8 acknowledging Train Data sent before the session is
established (9990600 and others); 4.8.5.5 "at the same time" (one
cycle late: 5100400_06 trips at the transition, triage S2f278aca);
4.8.5.2 and 4.8.5.4 b) (handover); the packets of message 24 and the
session messages (8, 32, 39 to 43) through the tables; [17] (SM); the
trigger of 3.8.2.4 (packet 90); message 158; the leftovers of phase 2.

### Session and link, phase 3 (e5/session-4, 2026-10-06)

**Implemented.** The position reports of 3.6.5 (`EVC_Sessions.Reports`,
a private child like `Mission`): message 136 with packet 0, or 1 when
`EVC_Position.Report_Kind` says so, to the supervising RBC (session
established, connection up) on 3.6.5.1.4 a), b), g), h), i), j) and the
parameters of packet 58 (3.6.5.1.5 a to e, kept by `EVC_Position`),
taken from the messages passed to the authority, referred to their LRBG
and applied in `Evaluate`; entering level 1 deletes them (4.9.1.3, the
parameter part; `EVC_Position.Delete_Report_Parameters`). A24 / A39 of
5.4.3.2 applied in `EVC_Core.Evaluate_Radio` (its postcondition now has
the form of `Delete_Invalid_Position`'s; Tick's 3.6.4.1.2 proves). Q_DESK
in message 150 (8.6.10 of 4.0.0 has it). Packet 42 of message 24 by
radio (`EVC_Sessions.Take_Radio_Order`: the termination ordered by the
RBC was never applied, message 24 goes to no store). Message 8 matched
on its second T_TRAIN read from the catalogue's seventh value (it read
NID_BG: the Train Data were never acknowledged in the SUBSET-076 runs;
the test helper had the same error). Scenarios
`Scenario_Session_Reports` and checks added to `_Establish`,
`_SoM_Failures`, `_EoM`.

**Decisions.** (1) Mode and level changes are seen in the cycle they
happen; the report goes at its end (3.6.5.1.4.1). (2) h) is the
supervising session becoming established; during the level 2 start of
mission 157 is that report. (3) No report while the connection is lost;
an event meanwhile is not kept. (4) Packet 58 from any message passed to
the authority (4.8 is the authority's), referred to the message's LRBG.
(5) The periods of 3.6.5.1.5 a) b) are not restarted by a report sent
for another reason. (6) Q_DESK from the cab status of the position. (7)
Packet 42 of 3 / 33 keeps the way of their stored information; of 24 it
is taken by the session half (4.8.4 accepts session management in every
mode with a session).

**Analysed.** S1f552964 (Main window after a stop): the joint of two
test cases without a driver action, triaged model. S7e250917: fixed
(Q_DESK). S7d250784: 5070300_02 / _04 expect Q_DESK 0 with a desk open,
triaged s076. SUBSET-076: 518 -> 530 passed.

**Left.** Level transitions to and from level 2 (5.10, 5.15, step 4 of
the brief: not started; `EVC_Levels.Available` still L0 / L1 while an
order whose only level is 2 selects it as the last entry, noted by the
acceptance agent; 131 sequences "connect not requested", 53 "level L2
shown"); 3.6.5.1.4 c) d) e) k) l) (integrity, RBC/RBC border, errors of
3.16.4); the last reported LRBGs of 3.6.2.2.2 c) on the RBC's side;
the train running number and safe consist length in 157; the signatures
S15dab337 (Start/Main disabled after a second level 2 SoM) and Sb83b2c65
(136 on SH -> PS) to analyse; 3.5.6, the handover, 4.8.5 as before.

### E5 integration after the third round (2026-10-05)

Merged on master: bench round 2, the acceptance package (e5/authority-4)
and session phase 3 (e5/session-4). Added while merging:

- **4.5.2, "Report Train Position"** (PDF page 43 of chapter 4; the
  markdown loses the columns): `EVC_Sessions.Reports` reports an event of
  3.6.5.1.4 only in the modes of its row (standstill: SB, SM, FS, AD, LS,
  SR, OS, RV; a mode change: not into PS, not from PS to SH; a level
  change: SB, FS, AD, LS, SR, OS, SL, NL, TR; a session established and
  what the RBC requested: not in PS, the latter not in SH either).
  Sequences 4050200_01 and _03 judge it; `Scenario_Session_Reports` has
  the Shunting case. Note {5} (SB and SL: only with a session
  established) holds by construction: a report needs the session.
- The level change rows of the trackside order and of the driver's
  request are taken together (the on-board does not tell them apart at
  that place).

Open after this round, in the order a next round would take them:

1. 4.8.3 [3] is built and switched off (`Train_Data_Unacked => False` in
   `EVC_Core.Evaluate_Radio`). The reason it was switched off (message 8
   never matched) is fixed in session phase 3; switching it on needs a
   run of the sequences.
2. Level transitions to and from level 2 (5.10, 5.15), with the release
   of the transition buffer in the cycle of the transition (4.8.5.5).
3. RBC handover (3.15.1); the runner routes a second RBC already.
4. Radio network registration (3.5.6) and the radio equipment bits of
   MSG_ONBOARD (the DMI's Radio data window buttons).
5. The level 2 line of the bench page (Sim_RBC lacks message 41).
6. The system version of the RBC (chapter 6, E7): 563 SV21 / SV22
   sequences stop at "159 not sent".

### Level transitions to and from level 2 (e5/levels, 2026-10-06)

**Implemented.** 4.8.3 [3] switched on: `Train_Data_Unacked` of
`EVC_Core.Evaluate_Radio` is `EVC_Sessions.Train_Data_Awaited` (Train
Data sent, message 8 not received yet). Level 2 available for use
(5.10.2.4.1 a, `EVC_Levels.Available`). The transition buffer released
in the cycle of the transition (4.8.5.5 "at the same time"):
`EVC_Core.Release_Transition_Buffer` after `Evaluate_Modes_And_Levels`
(`EVC_Radio_Authority.Release_At_Transition`, the messages judged in
level 2, `EVC_Stored_Information.Evaluate_Released` takes them) before
the procedures and the mode machine; 5100400_06 no longer trips. The
sessions of the transitions (`EVC_Level_Sessions`, new, first in
`Evaluate_Radio`): the driver's change to level 2 establishes the
session with the stored contact (5.10.3.15.2 a, 3.5.3.4 d); out of
level 2 a position report when the min safe rear end has passed the
border (5.10.3.3.3, .6.2, .10.3) or the level change reported by the
session half (5.10.3.15.3), repeated every 15 s at most 3 times, then
the session terminated (5.10.3.3.5, .6.5, .10.6, .15.4). Appended to the
session half: `EVC_Sessions.Train_Data_Awaited`,
`EVC_Sessions.Request_Position_Report` (`Reports.Request`,
`Mission.Train_Data_Awaited`). Scenarios in `EVC_Test_Levels`
(`L2_Buffer_Same_Cycle`, `L2_Driver_Change`, `L2_Exit_By_Order`);
`EVC_Test_Authority` exports `Establish_Session` and `Radio_MA`.

**Decisions.** (1) Level 2 is always available: the radio equipment of
5.10.2.4.1 a) is configuration not modelled, one radio taken as working,
registered or not. (2) 4.8.3 [3], second bullet: any Train Data sent
again count as changed (the four values are not compared). (3) A
message 9 rejected by [3] is ignored without 138 (4080407_01; the
authority's decision "138 also when 4.8 rejects" narrowed). (4) The
driver's change to level 2 connects to the stored RBC contact, known
and valid; in SB the start of mission does it (5.4.3.2 D7). (5) The
border of an exit is where the estimated front end was at the
transition; the min safe rear end has passed it once the odometer ran
the train length plus the under-reading of the confidence interval.
(6) "The order to terminate received" is the supervising session no
longer established. (7) The released messages' snapshot is the next
cycle's (the supervision of the cycle of the transition uses the old).

**SUBSET-076.** 537 / 1962 / 691 before; 4.8.3 [3]: 537 / 1962 / 691
(4 improvements); level 2 available: 554 / 1944 / 692; the buffer in
the cycle: 554 / 1944 / 692 (42 improvements); the sessions: 555 /
1943 / 692, 0 regressions.

**Left.** 5.10.3.15.2 b) (the driver's Radio data outside the start of
mission); 5.15.1.4 (handover, 3.15.1); 3.5.6 (the connection set-up
waits for a registration the runner gives in 12 sequences: most of the
147 "connect not requested" are radio infill, E7, or this); the level 2
line of the bench page (sim/, Sim_RBC).

### System version, part of chapter 6 (e5/version, 2026-10-06)

Brought into E5 by the owner's decision of 2026-10-06 (563 SV21 / SV22
sequences stopped at "159 not sent"); the rest of chapter 6 stays E7.

- **`EVC_System_Version`** (new, SPARK): the envelope 1.0 up to 3.0
  (6.4.2.1, 6.4.2.2: X = 1, 2, 3; within X the highest Y, 1.1, 2.3, 3.0,
  3.17.2.1.1), `Compatible`, the operated X (3.17.2.2) and whether the RBC
  governs it. `Follow`, once a cycle from `EVC_Sessions.Evaluate`
  (3.17.2.8): the RBC's X is operated while the level is 2 and the
  session with the supervising RBC is established with a known
  compatible version (a: from the cycle the transition is executed; b:
  at once in level 2); out of level 2 or without that session (d, e) the
  version last operated stays, from which the non-RBC control of
  3.17.2.3 (E6 / E7) would go on; c comes with the handover (the
  accepting RBC becomes the supervising one). .8.1 / .8.2 (the balise
  group of the transition checked again with the new version) wait for
  the layouts of chapter 6 (E7). `Restore`: the X kept over No Power
  (3.17.2.9, `EVC_Retained.Operated_X`, saved by
  `EVC_Core.Save_Retained`, restored by `Power_Up`), the highest when the
  store is empty (3.17.2.9.1, `Initialise`).
- **`EVC_Sessions`**: `Compatible` is the envelope's (3.5.3.7 d,
  3.17.3.7); 159 lists the envelope in packet 2, 3.0 then N_ITER 6 (2.3,
  2.2, 2.1, 2.0, 1.1, 1.0; decision: every X.Y, as the sequences list them
  for a 3.x on-board); `Msg_Size` 24 bytes. 6.5.2.2.2 (and 6.5.1.2 for
  X = 1) replace 3.5.3.7 e) / 3.5.4.6 for an RBC of 1.x or 2.0 .. 2.2: no
  acknowledgement (38) is awaited from it, 3.5.3.7.4 / .4.1 do not apply
  (`Session_Acknowledged`).
- **`EVC_Core`**: the balise check of 3.17.3.5 d) compares with
  `EVC_System_Version.Highest_X`.
- 3.17.3.11: `ETCS_Message` already passes an unknown packet over and
  ignores an unknown message for any version; telling a higher Y from a
  consistency error of the same Y is 3.16 (E6).
- Scenarios `EVC_Test_Version` (negotiation with 2.1, 1.1, 2.3, 0.0;
  retention); `Scenario_Session_Lost_Version` uses X = 4 now.
- SUBSET-076 runner: 537 / 1962 / 691 (passed / failed / blocked) before;
  575 / 1870 / 745 after the envelope; 630 / 1762 / 798 after 6.5.2.2.2
  (SV21 161 -> 203, SV22 167 -> 212, SV30 209 -> 215). Six regressions
  understood (3060700_01, 3070300_03, 5040300_20 in SV21 / SV22 got
  further only because the session was terminated for the missing
  acknowledgement; they now stop where their SV30 twins stop).

Left: the remaining SV21 / SV22 first failures are not version
behaviour of the session half: chart positions of the workbook train
(Sf99123ce, Sc70786e6), the balise side (2.x telegrams, E6 / E7), the
X = 1 layouts (Se18f3f0a: 159 with packet 3 to an X = 1 RBC, E7), and
signatures triaged to the other halves (test/s076/triage.csv, block
"e5/version"). Proposal for the generator (not implemented): a
per-version variant of a message's packet list (159 packet 3 for X = 1)
would move 6 sequences.

### Bench, third round: the level 2 line of the page (e5/bench-3, 2026-10-06)

**Sim_RBC**: the SoM position report 157 is answered with 41 "train
accepted" (5.4.3.2 S10). Message 32 carried M_VERSION 4.0 (100 0000),
which the on-board finds incompatible (3.17.2: X 3 only) and answered
with 156: it is 3.0 now (011 0000, "introduced in SRS 4.0.0",
7.5.1.79). The MA request with the position unknown is answered with
the SR authorisation (message 2, D_SR 500 m); the MA (message 3) is
given with the line's SSP and gradient profile (packets 27, 21 from the
LRBG, 3.7.3.1; `Sim_Trackside.Put_SSP` / `Put_Gradients`, which also
write the first group's telegram, byte for byte as before) on a 132
with an LRBG, or unasked on the first position report 136 that gives
one.

**The page**: a third "Track" choice, "level 2 by radio", is the
default track with `Sim_Onboard_Env.Set_Radio (True)` (export
`onboard_set_radio`): Sim_RBC behind the RTM port and a scripted driver
that sends the start of mission in level 2 (`SoM_L2_Frame`: the frames
of `Scenario_Session_SoM_Level_2`, then the acknowledgement of SR), each
step once the on-board's MSG_ONBOARD / MSG_MODE_LEVEL show the answer to
the step before (`SoM_L2_Ready`). Decision: frames from the environment,
not touches on the DMI: the same Ada code feeds the native run and the
wasm run, so `onboard_smoke.js` compares them byte for byte (golden
`bench_level2`, `EVC_Test_Bench.Scenario_Bench_Level_2`); and the touch
route is closed while the on-board does not report its radio equipment
in MSG_ONBOARD (the Radio data window buttons, bench round 2).

**Finding, on-board**: the line stops at S21 in SB. After 'Start' the
on-board sends 132, takes the SR authorisation (`RBC_SR_Given`) but
proposes no SR (5.4.3.2 S21 -> S24, E26 / E27: `EVC_Mission` leaves the
proposal to the authority half, `SR_Authorised` is never read).
SUBSET-076 3040200_04 SV30 stops at the same place (step 136,
S55128ce0, analysed in the triage). With a local change that proposes
SR there, the line runs through: SR acknowledged, the first group read,
136, the MA by radio, FS at cycle 65, the stop at 9806 m before the EOA;
`Scenario_Bench_Level_2` and `onboard_smoke.js` then check FS and the
stop, and `bench_level2` changes (expected).

**Triage**: S15dab337 and Sb83b2c65 are no longer reached on master
(notes updated: message 8 matched on its second T_TRAIN; 4.5.2 excludes
SH -> PS from the report of a mode change).

**Left**: the on-board's S21 -> S24 on message 2 (then re-record
`bench_level2`); the waiting value 3 of MSG_ONBOARD after 'Start' (the
on-board shows 0 while it awaits the MA or the SR authorisation, Table
50 S7); the DMI in the page follows the on-board's answers but its own
start-up windows are not driven by the scripted frames.

### E5 integration after the fourth round (2026-10-06)

Merged on master, in this order: e5/levels (level 2 available, the
sessions of the level transitions, the transition buffer released in
the cycle of the transition, 4.8.3 [3] on), e5/version (the envelope
1.0 .. 3.0, the negotiation with packet 2, `EVC_System_Version`, no
session acknowledgement awaited from 1.x / 2.0 .. 2.2 RBCs) and
e5/bench-3 (the level 2 line of the page). The two on-board branches met
only in the Globals of `EVC_Core.Evaluate_Radio` (both kept). The
SUBSET-076 baseline was re-recorded on the merged tree: 656 passed,
1733 failed, 801 blocked (levels alone 555, version alone 630: the two
add up, 0 regressions against either). Green: check.sh (evc_test
11262), the full proof (10483 checks, margin 47726 steps, 4 wide
checks), the cross build (stack 27096 B), the wasm build and both
smoke checks.

Open after this round, in the order a next round would take them:

1. **The SR proposal on message 2** after 'Start' in level 2 (5.4.3.2
   S21 -> S24, E26 / E27): `EVC_Radio_Authority.SR_Authorised` is set and
   never read, `EVC_Mission` leaves the proposal to the authority half.
   Found by the bench's level 2 line, which stops at S21; the same gap is
   signature S55128ce0. With it the line reaches FS by radio (verified
   with a local patch, not committed): then `bench_level2` is
   re-recorded and the smoke check's FS expectation tightened. With it:
   MSG_ONBOARD "waiting" 3 after 'Start' (DMI Table 50 S7).
2. RBC handover (3.15.1, 5.15.1.4, 4.8.5.2, 4.8.5.4 b, 3.17.2.8 c);
   the runner routes a second RBC and `EVC_Radio.Accepting` exists.
3. Radio network registration (3.5.6; the connection set-up waits for
   it in 12 sequences) and the radio equipment bits of MSG_ONBOARD (the
   DMI's Radio data buttons; the page's touch route to the level 2 start
   of mission needs them); 5.10.3.15.2 b).
4. The on-board signatures the round reached: S44acb613 (a later 138
   answer to a message 9 rejected by 4.8), Sbfa49d0b (a trip in level 2
   FS before the RBC's MA, 5100300_07), S5d36d452 (the JRU record of the
   level selection), Sd4cbc324 (a trip expected in SH level 2),
   Sc18cdb2f (132 with packet 1), S908191ec (the Train integrity button
   in FS level 2), S0e2fe215 (a JRU 45 record in OS level 1).
5. Chapter 6 left in E7: the X = 1 / X = 2 layouts (a per-version packet
   list of a message in the generator would move 6 sequences: 159 with
   packet 3 to an X = 1 RBC), the non-RBC determination of the operated
   version (3.17.2.3 to .7, 3.17.3.3/.4, then 3.17.2.8.1/.8.2), 1.x
   balise telegrams (`ETCS_Telegram.Supported`).

### SR proposal on message 2 (e5/sr-proposal, 2026-10-06)

**Implemented.** 5.4.3.2 S21 -> S24 (E26): 'Start' in level 2 with the
session established waits for the RBC (`EVC_Mission.Waiting_For_RBC`,
set by `Take_Start`); an SR authorisation taken during the wait
(`EVC_Radio_Authority.SR_Authorisations`, a saturated count of the
messages 2 taken, read through `Context_T.SR_Authorisations`) proposes SR
(`EVC_Mission.Take_RBC_Answer`); the driver's acknowledgement gives SR as
in level 1 (4.6.3 [8]). The same for 'Start' in PT level 2 (5.11.2.2
S150 a), S160). The wait ends with a change of mode (E29, the MA allowing
FS), level or desk. MSG_ONBOARD waiting 3 while it lasts (DMI Table 50
S7; `EVC_DMI_Port.Waiting_Start`). Scenario
`EVC_Test_Sessions.Scenario_SoM_L2_SR_Proposal`; the bench's level 2 line
now reaches SR then FS (`bench_level2` re-recorded, the smoke check
requires it).

**Decisions.** A count rather than the one-cycle `SR_Authorised`: a
message 2 released from the transition buffer is taken after
`EVC_Mission.Evaluate` and the flag is cleared in the same cycle. A
message 2 without a 'Start' waiting proposes nothing (5.4.3.2 goes to
S24 from S21 only); its SR distance and list stay with the authority
half and a later 'Start' waits at S21 again.

**Left.** E27 / S25 and 5.11.2.2 S150 b) / S170: the proposal of OS / LS
/ SH on an MA with a mode profile; a scenario of its own for PT level 2
(S150 a); golden_review.py does not dump the bench goldens (reviewed
with BENCH_TRACE=1).

### Radio network registration (e5/registration, 2026-10-06)

**Done.** `EVC_Sessions.Network` (private child, part of the parent's
state): the Radio Network type and GSM-R identity stored are
`EVC_Radio.Network` (new fields `Type_Known`, `Net_Type`; memorized over
No Power in `EVC_Retained.Kept_T.Network`, 3.5.6.2), the defaults of
`EVC_Config.Radio_Config_T` (`Systems` both, `Default_Type` GSM-R,
`Default_MN` 0; not in the image, 3.5.6.3 / 3.5.6.4), the registration
of each session's mobile from the port's events 5 / 6, the
registration ordered at power-up (3.5.6.1 a), on the driver's GSM-R
network (b) and on packet 45 (c; balise groups and messages 3 / 33 via
`EVC_Stored_Information` K45, message 24 via the session half), held for
a session not Idle (3.5.6.5 b / c, 3.5.6.6). 3.5.6.7: the set-up
request stays due in `Produce_Session` while `Network.Ready` does not
hold. The driver's Radio Network type (kind 6), GSM-R network (kind 4)
and "mission with one radio system" (kind 7) with 3.18.4.3.6.1 / .3.
MSG_ONBOARD: radio bits 0-6, radio_wait 2, waiting 1 during A31 while
not registered (5.4.3.2 S4). "GSM-R network registration failed"
(entry 34) on event 6 and on the empty list. The test support and the
SUBSET-076 bench answer a registration request with event 5 in the
next cycle (`Auto_Register`; `S076_Bench.Registering`), as `Sim_RBC`.

**Decisions.** (1) A session of the port is one GSM-R mobile. (2) The
port reports no FRMCS registration: FRMCS counts as not registered. (3)
The power-up registration whenever GSM-R is installed. (4) A mobile
counts as registered to its former network until its request is sent.
(5) 3.5.6.7 is applied to every set-up request (D7 / S4, 5.10.3.15.2 a
ask the same). (6) The port offers no list of networks: the list is
empty (S3 E3 -> A29); a network named by the driver is taken as its
NID_MN digits. Packet 45 is filtered by 4.8 as session management.

**Left.** The FRMCS report in the port; MSG_RADIO_NETWORKS (the list,
3.18.4.3.6.2); the A.3.1 time of S4 (E7 / E71 / E72 -> A42) and D8 /
D9 / S5 / A43 as a flow (the driver's entries are taken, the steps not
sequenced); 5.10.3.15.2 b) (the Radio data window outside the start of
mission); 3.5.6.8 (RIU, E7); the 4.8 rows of the Radio Network
transition order in `EVC_Acceptance`.

### RBC handover (e5/handover, 2026-10-06)

**Implemented.** `EVC_Sessions.Handover` (private child, part of
`EVC_Sessions.State`): the RBC transition order (packet 131 by balise,
`EVC_Acceptance.RBC_Transition_Order` with the rows of 4.8.3 / 4.8.4,
[8] in PS / SH; by radio from the supervising RBC only, 4.8.2.1 c)
exception 2), replaced by a newer one (3.15.1.3.2.2, .2.3); the session
with the Accepting RBC opened beside the other (3.15.1.3.1 a),
3.5.3.5.2.1) and given the role; Train Data to it once established
(3.15.1.3.3, `Mission.Send_Train_Data`); reports to both
(3.15.1.3.4, `Reports.Produce (Also, Forced)`); the border kept by
`EVC_Position` (`Set_Border`, triggers `Border_Front` / `Border_Rear`,
3.15.1.3.1 b) c), 5.15.1.4); the switch (3.15.1.3.5, .7, 3.17.2.8 c):
roles, contact, the Handing Over session and contact retained
(3.15.1.3.8 a); from it only packet 42 is taken; 3.15.1.3.9 (15 s, 3
repetitions of A.3.1); messages of the Accepting RBC before the switch
to the authority's transition buffer (verdict `Buffered`), held while
`EVC_Radio.Handover`, dropped when the session loses its role (4.8.5.2,
4.8.5.4 b); 4.8.3 [14] (Se3765f9b); one session only: 3.15.1.3.2.
Scenarios `EVC_Test_Handover.Scenario_Handover_Radio`, `_Balise`.
SUBSET-076: 670 passed, 1710 failed, 810 blocked (was 664 / 1725 / 801),
0 regressions, 41 improvements; baseline re-recorded.

**Decisions.** The switch in the cycle after the border report; a border
referred to a group the position does not keep: the order is dropped; a
balise order refers to the LRBG when applied; without a session with the
Accepting RBC at the switch no RBC supervises until one is established
(3.17.2.8 e: the version last operated stays); the second session busy:
the open waits for a free session (never `Establish`, which would
terminate the supervising one); a terminate order (packet 42 Q_RBC 0)
ends only the session with its RBC when there is one.

**Edits outside the child** (for the merge with the registration work):
`EVC_Sessions` spec (`Take_Transition`, `with EVC_Balise_Groups`), body
(`Refined_State`, `Clear`, `Close` keeps the supervising role when the
accepting session closes, `Apply_Order` [14] and terminate by RBC,
`Take_Radio_Transition`, `Take_Message` filters, `Apply_Handover` in
`Evaluate`, `Produce`); `EVC_Sessions.Reports.Produce` (parameters);
`EVC_Sessions.Mission.Send_Train_Data`; `EVC_Position` (border);
`EVC_Acceptance`, `EVC_Stored_Information` (K131);
`EVC_Radio_Authority.Buffer` (`Drop_Ended`, `Update`); `EVC_Core.
Read_Radio_Messages` (`Buffered` to `Store_Message`).

**Left.** 3.15.1.3.2.4; 3.15.1.3.4.1 (End of Mission with both);
3.15.1.3.8 b) (the 4.10 deletion events to `Handover.Delete`) and the use
of the retained contact by 3.5.3.4 f); the safe consist length in SM
(3.15.1.3.3); scenarios of their own for 3.15.1.3.1 c) and 3.15.1.3.9;
packet 31 (FRMCS); S776cef6c (a text message of the Accepting RBC
released at the switch is not shown).

### E5 integration after the fifth round (2026-10-06)

Merged on master, in this order: e5/sr-proposal (item 1 of the fourth
round's list), e5/registration (item 3) and e5/handover (item 2). The
two last met in `EVC_Sessions` (its children `Network` and `Handover`,
both kept), in `EVC_Stored_Information` (the order kinds K45 and K131,
both kept) and in the call list of `evc_test`; one scenario left a
one-session radio configuration behind and restores the default now.
The SUBSET-076 baseline on the merged tree: 675 passed, 1669 failed,
846 blocked (656 / 1733 / 801 before the round), 0 regressions, no
signature untriaged. Green: check.sh (evc_test 11337), the full proof
(10692 checks, margin 47726 steps, 4 wide checks), the cross build
(stack 27136 B), the wasm build and both smoke checks.

Reading tools since this round: `test/tools/outline.py` and
`doc/SRS/tools/clause.py` (AGENTS.md); the three agents of the round
used them 12 to 15 times each and read no file whole.

Open after this round, in the order a next round would take them:

1. The leftovers of the three packages, listed at the end of their
   subsections above: E27 / S25 and the OS / LS / SH proposal on an MA
   with a mode profile (S30e45cf6), the PT level 2 scenario; FRMCS
   registration from the port, MSG_RADIO_NETWORKS, 5.10.3.15.2 b),
   3.5.6.8; 3.15.1.3.2.4, the end of mission with both RBCs
   (3.15.1.3.4.1), the 4.10 deletion of the order, the safe consist
   length in SM, the text message of the accepting RBC (S776cef6c).
2. Item 4 of the fourth round's list (the on-board signatures it reached)
   and the 52 sequences of S55128ce0.
3. Chapter 6 in E7 (item 5 of the fourth round's list).

### RBC handover, second round (e5/handover-2, 2026-10-07)

**Implemented.** S776cef6c analysed: the release path was not at fault;
the text messages by radio were not taken at all. Packets 73 / 74 of
message 24 now go to the stores through `EVC_Radio_Info` (Take_Message
of `EVC_Radio_Authority`, referred to the message's LRBG) and from
there to `EVC_Text_Messages.Take_Radio` (step 3, before the table is
emptied; stored by the next `Evaluate`), also for a message the
transition buffer releases. Scenario `EVC_Test_Handover.
Scenario_Handover_Text` (4.8.2.1 c, 4.8.5.2, 3.12.3). SUBSET-076 sv30:
3 improvements; 3160300_01 stops 2 steps earlier (Se341da87: an older
message 24, 3.16.2.4.1, now shows its text); 3150100_08 still fails at
step 95 (its text ends 50 m after its LRBG, 3.12.3.4.6, before the
switch at 1000 m: triage note). Baseline not re-recorded.

**Decisions.** A message 24 goes to `EVC_Radio_Info` only when it
carries packet 73 or 74 (its track description is then taken too, as
for message 3).

**Left.** All of the "Left" of e5/handover except S776cef6c's cause:
3.15.1.3.2.4; 3.15.1.3.4.1; 3.15.1.3.8 b) and 3.5.3.4 f); 3.15.1.3.3 in
SM; scenarios for 3.15.1.3.1 c) and 3.15.1.3.9; the time stamp check of
3.16.2.4.1 for radio texts; the baseline re-record.

### Mode proposal on an MA with a mode profile (e5/mode-proposal, 2026-10-07)

**Not implemented; findings for the next agent.** The budget went into
two findings and the test helpers:

- S30e45cf6 (3150100_03, three sequences) is not the gap of 5.4.3.2
  E27 / S25: the train is in SR in level 2 and the message 3 of step
  88 (packet 80 SH from 950 m, the train at 1000 m: SR to SH at once by
  4.6.3, then the acknowledgement) comes from the second session (RBC2,
  established at 600 m). It never reaches `EVC_Radio_Authority`
  (`Messages_Taken`, `Messages_Rejected`, `Radio_MAs_Accepted` and
  `Buffered` all 0 over the sequence), so `EVC_Sessions.Take_Message`
  gives it the verdict Ignore (the branch `Handover.Old = S and then
  Supervising /= S`, or `Handover.Held`): a matter of the handover
  package (`EVC_Sessions.Handover`), not of `EVC_Mission`.
- `EVC_Procedures.Profiles_Step` already raises the acknowledgement
  request in SB and PT in level 2 for a mode profile area the train is
  in (5.7.4.1, 5.9.5.1, 5.19.5.1: `Ack_On`, `Ack_M`), which the
  conditions [15], [50] and the LS one read. E27 / S25 may therefore
  need in `EVC_Mission` only the end of the wait (`Take_RBC_Answer`:
  `RBC_Wait` cleared when `EVC_Procedures.Ack_Requested` in SB / PT
  level 2) and the decision on an MA and a message 2 in the same cycle
  (pick the MA); to be confirmed by the scenario.
- The scenario `EVC_Test_Sessions.Scenario_SoM_L2_Mode_Proposal` and
  its helpers `MA_With_Profile` (message 3 with packets 15, 21, 27 and
  optionally 80) and `SoM_L2_At_S20` are committed but not called from
  `evc_test`: a group passed with `Run_X` after `Start_E4` in SB leaves
  `EVC_Position.Status` Unknown, so the MA's LRBG is not known. A start
  of mission with a valid position is needed first. Probe: the same
  group passed after `Start_X` (legacy FS) gives Valid, after
  `Start_E4` (SB) Unknown: the on-board does not take the group in SB
  (by design or not, to be read in 4.5 / 4.4.7); a power-up with a
  stored valid position (the cold movement detector of `Start_E4`) or
  a trip to PT after FS in level 2 (the PT path of 5.11.2.2 S150) are
  the two ways to a valid position at 'Start'.

**Left.** All of the brief: E27 / S25, 5.11.2.2 S150 b) / S170, the PT
level 2 scenarios (S150 a and b), the matrix rows, the runner.

### Radio network registration, second round (e5/registration-2, 2026-10-07)

**Done.** MSG_RADIO_NETWORKS (3.18.4.3.6.2): in the cycle the driver
elects to modify the GSM-R network, `EVC_Core.Send_Networks` sends
`EVC_DMI_Port.Networks_Frame` with the networks of
`EVC_Sessions.Network.Offered`: the configured default network and the
stored one when different, each named by its NID_MN digits (entry 34
only when the list is empty). 5.4.3.2 S4: `Network.Supervise_Wait`
watches the latest registration order (`Produce`) and, while the start
of mission waits at S4, after the 40 s of A.3.1 ("Time from the latest
Radio Network registration order ... considered as failed", page 218)
shows entry 34 (A42) and ends the wait (MSG_ONBOARD waiting 0, D9 ->
S10); the driver's new network is A43's restart. 4.8.3 / 4.8.4: packet
45 on its own rows (`EVC_Acceptance.Network_Order`). Scenarios in the
new `EVC_Test_Network`.

**Decisions.** (1) The list: the default and the stored network (the
port offers none). (2) S4 watches GSM-R only (FRMCS never registered,
e5/registration decision 2): E61 / E62 / E71 / E72 are not watched. (3)
Outside the start of mission the time is watched silently; a start of
mission reaching S4 after it fails at once. (4) A42 ends the wait of S4
and leaves the set-up request due under 3.5.6.7; the DMI's Radio data
window is the driver's to open again (the on-board cannot open it).

**Left.** 5.10.3.15.2 b) (the Radio data window outside the start of
mission: the driver's level 2 without the conditions of a); D8 / S5 with
FRMCS; 4.8.4 [13] of packet 45 (inside a rejected SM authorisation); the
SUBSET-076 runner not rerun outside `check.sh`; FRMCS report of the
port and 3.5.6.8 stay in E7.

### E5 integration after the sixth round (2026-10-07)

Merged on master: e5/handover-2 (step 1 of six: text messages by radio,
packets 73 / 74 of message 24, reach `EVC_Text_Messages` from any RBC
and from the transition buffer; before, the on-board took text messages
from balise groups only), e5/mode-proposal (findings only: S30e45cf6 is
a filter of a second session in `EVC_Sessions.Take_Message`, not the
E27 / S25 gap; a start of mission scenario cannot get a valid position
in SB; the scenario kept, not called) and e5/registration-2 (steps 1, 2
and 4 of six: MSG_RADIO_NETWORKS, 5.4.3.2 S4 as a flow with the 40 s of
A.3.1, packet 45 on its own acceptance rows). SUBSET-076 on the merged
tree: 679 passed, 1665 failed, 846 blocked (675 / 1669 / 846 before), 0
regressions against the re-recorded baseline (two sequences of
3160300_01 fail earlier, Se341da87: the 3.16.2.4.1 time stamp check of
radio messages is missing, noted in the triage). Green: check.sh
(evc_test 11354), the full proof (10775 checks, 0 unproved, margin
47726 steps), the cross build (stack 27136 B), wasm and both smoke
checks.

The round was a measurement too: three agents of 100 tool calls on the
trimmed agent types (`opus-trim`, `opus-medium`), 163 to 173 requests,
14 to 18 minutes, 129k to 153k final context, about 8 to 9 USD each, no
wait over 5 minutes, no cache rewrite; the first-request prefix 17.4k
tokens (42k before the trim). The reading tools: outline.py 8 to 16 and
clause.py 4 to 12 runs per agent, grep still 56 to 65 and `sed -n` 22 to
28; the LSP tool once in all (the language server is rooted at the main
checkout, so a worktree file resolves nothing: the common brief says to
query the main checkout's path). Two harness facts cost tool calls: a
harness worktree starts at origin/master (71b12f9, stale while nothing
is pushed; every agent reset to master, which the briefs demanded), and
the worktree guard refused 7 to 11 commands per agent (sourcing a file,
`export X=$(...)`, unquoted computed arguments, `git -C`); the common
brief now gives literal commands. The medium-effort agent did the most
code of the three at the same cost: no sign that medium is worse for a
brief that names clauses and subprograms.

Open after this round, in the order a next round would take them:

1. The handover leftovers (five of six steps: 3.15.1.3.2.4, 3.15.1.3.8
   b) with the 4.10 deletion and 3.5.3.4 f), 3.15.1.3.4.1, 3.15.1.3.3
   in SM, the scenarios of 3.15.1.3.1 c) and 3.15.1.3.9), S30e45cf6 (the
   second session's filter) and Se341da87 (3.16.2.4.1), 3150100_08 step
   95 (3.12.3.4: a text whose end condition holds at the switch).
2. The mode proposal (5.4.3.2 E27 / S25, 5.11.2.2 S150 b) / S170) after
   the two findings of its subsection.
3. The registration leftovers (5.10.3.15.2 b), D8 / S5 with FRMCS, 4.8.4
   [13] for packet 45, packet 45 by radio in `EVC_Radio_Acceptance`).
4. Item 2 and 3 of the fifth round's list (the reached signatures, S55128ce0;
   chapter 6 in E7).

### Radio network registration, third round (e5/registration-3, 2026-10-07)

**Done.** Packet 45 by radio: the row "Radio Network transition order"
of 4.8.3 (from RBC: accepted in every level) and 4.8.4 (NR in NP, SF,
IS; [2] a cab active in SB; [1] in PT only after message 6) as
`EVC_Radio_Acceptance.Network_Order`, applied by
`EVC_Sessions.Network.Take_Radio_Order (Kind, Cab_Active)` to message
24 of the supervising RBC (the mode from `Network.Mode_Changed`,
message 6 noted for [1]). 4.8.4 [13]: no message 4 (SM authorisation)
is taken by this on-board, so neither its packet 45. Scenario
`EVC_Test_Network.Scenario_Network_Radio_Order`.

**Decisions.** (1) [1] in PT: a message 6 received in PT since PT was
entered (the order of the time stamps is 3.16.3's, as for the other
rows). (2) Packet 45 of messages 3 / 33 stays in the path of
`EVC_Stored_Information` (taken only when its message is accepted: a
packet 45 of an MA rejected by the mode is lost, which 4.8 would keep;
the authority half's).

**Left.** 5.10.3.15.2 b) (the Radio data outside the start of mission:
`EVC_Level_Sessions.Driver_To_L2` would remember the request when the
contact is not valid, and `EVC_Sessions.Mission`'s RBC data entry, now
taken only at the start of mission steps Decided / Reported, would
open the session; the on-board cannot open the window, e5/registration-2
decision 4); [14] for message 4 with the SM mode. D8 / S5 of 5.4.3.2
with FRMCS is E7: the port reports no FRMCS registration, so FRMCS
never counts as registered and S4 watches GSM-R only.

### RBC handover, third round (e5/handover-3, 2026-10-07)

**Implemented.** 4.10 (row "RBC Transition Order") in
`EVC_Sessions.Mode_Changed`: entering NP, SB, PS, SH, SM, SR, SL, NL,
UN, TR, SN or RV calls `Handover.Delete`, which now also drops the
retained contact of the Handing Over RBC (3.15.1.3.8 b). 3.5.3.4 f)
with 3.15.1.3.8.1: a lost Handing Over session (3.5.4.2.1) is opened
again with the retained contact beside the supervising one
(`EVC_Sessions.Evaluate`, `Open`, not `Establish`, which ends the
others). 3.15.1.3.4.1: message 150 also to the other connected session
(`EVC_Sessions.Mission`, `EoM_Also`). Query
`EVC_Sessions.Handing_Over_Retained`. Scenarios
`EVC_Test_Handover.Scenario_Handover_Deletion`, `_EoM`.
SUBSET-076: 679 passed, 1665 failed, 846 blocked (unchanged counts),
0 regressions, 2 improvements (3160300_01 SV22 / SV30 85 -> 87);
baseline re-recorded.

**Findings and decisions.** S30e45cf6 is not a filter defect: BG2d
carries packet 131 (border at 2600 m), so RBC2 is the Accepting RBC and
its MA at 1000 m is buffered by 4.8.2.1 c) / 3.15.1.3.6 (verdict
`Buffered`): triaged `s076`. Se341da87 was the runner's time stamps
(always rising); 3.16.3.3.3 was already in `Take_Message`; the runner
now gives the step asking for a smaller stamp one below the previous
(`S076_Run.Radio_Input`); next stop S13c9beb3, 3.16.3.1.1.2 (packet 4
M_ERROR to the RBC), triaged `onboard`. S776cef6c: 3.12.3.4.4, no
display when the end condition holds at once: on-board right, `s076`.
The order executed by the switch counts as stored for 4.10 until a
deletion event; the EoM repetitions and 5.5.4.1.1 follow the
supervising session only.

**Left.** 3.16.3.1.1.2 (packet 4 in 136, JRU 13); 3.15.1.3.2.4;
3.15.1.3.3 in SM; scenarios of 3.15.1.3.1 c) and 3.15.1.3.9.

### Mode proposal on an MA with a mode profile, second round (e5/mode-proposal-2, 2026-10-07)

**Implemented.** 5.4.3.2 E27 -> S25 and 5.11.2.2 S150 b) -> S170: while
'Start' waits for the RBC in SB / PT level 2, the acknowledgement that
`EVC_Procedures.Profiles_Step` asks for a mode profile at the train
(5.7.4.1, 5.9.5.1, 5.19.5.1; `EVC_Mission.Context_T.Profile_Ack`, filled
by `EVC_Core.Evaluate_Modes_And_Levels`) ends the wait
(`EVC_Mission.Take_RBC_Answer`); that request is the proposal, the
driver's acknowledgement gives OS / SH / LS by 4.6.3. The request is
raised after `EVC_Mission.Evaluate`, so the wait ends one cycle after the
MA. Scenarios in `EVC_Test_Sessions`: `Scenario_SoM_L2_Mode_Proposal`
(OS, now called), `_SH`, `Scenario_SoM_L2_MA_Without_Profile` (E29: FS,
nothing proposed), `Scenario_PT_L2_SR_Proposal` (S150 a), S160) and
`Scenario_PT_L2_Mode_Proposal` (S150 b), S170). Matrix: 5.4.3.2 S25,
5.11.2.2 S150 a), S150 b), S170 done, S150 partial (c).

**Finding 3 corrected.** The on-board takes a balise group in SB (the
position is Valid after the group, 4.4.7.1.6); the helper
`SoM_L2_At_S20` lost it because it gave message 41 after a valid
position report: per A33 the RBC goes to S10 without an answer, and 41
(A23) makes the on-board delete the position (D34 / A24). The helper no
longer sends it; no change in `EVC_Position`.

**Left.** The decision "an MA and a message 2 in the same cycle: the MA"
is not implemented: message 2 is counted when the ports are read, before
`EVC_Mission.Evaluate`, and the MA accepted after it in `Evaluate_Radio`,
so SR is proposed and the profile's request does not come; it needs the
MA's acceptance before the mission's evaluation or the SR proposal
withdrawn. LS has no scenario of its own. SUBSET-076: 679 passed, 1665
failed, 846 blocked, unchanged (0 regressions, 0 improvements).

### E5 integration after the seventh round (2026-10-07)

Merged on master: e5/registration-3 (packet 45 by radio through the 4.8
filters of `EVC_Radio_Acceptance`, 4.8.4 [13] checked; 5.10.3.15.2 b)
left), e5/handover-3 (the 4.10 deletion of the RBC transition order and
the retained contact, 3.5.3.4 f) with 3.15.1.3.8.1, End of Mission to
both RBCs; the runner's radio stamps corrected, which uncovered
3.16.3.1.1.2, S13c9beb3) and e5/mode-proposal-2 (5.4.3.2 E27 / S25 and
5.11.2.2 S150 b) / S170 through the procedures' acknowledgement
request; the same-cycle MA and message 2 left). Two triage lines moved
to `s076`: S30e45cf6 (the sequence pairs an MA for the supervising RBC
with a pending handover, 4.8.2.1 c) and S776cef6c (3.12.3.4.4: no
display when the end condition holds at once). The merge of handover-3
on registration-3 met in `EVC_Sessions.Mode_Changed` (both kept).
SUBSET-076 on the merged tree: 679 passed, 1665 failed, 846 blocked,
unchanged, 0 regressions. Green: check.sh (evc_test 11441), the full
proof (10786 checks, 0 unproved, margin 47726 steps), the cross build
(stack 27136 B), wasm and both smoke checks.

Measured, three agents of 100 tool calls (two `opus-medium`, one
`opus-trim`), worktrees from local master (`worktree.baseRef`): 142 to
195 requests, 18 to 21 minutes, 126k to 153k final context, 7 to 11
USD, no wait over 5 minutes; outline.py 8 to 15 runs (`--decl` 1 to 2),
clause.py 4 to 9, grep still 43 to 57, `sed -n` 22 to 31; the LSP tool
not loaded by any; the worktree guard 5 to 7 refusals per agent (down
from 7 to 11). Two of the six brief premises of the round were wrong and
corrected by the agents (a runner fault, a test helper fault): a brief
should state what a trace shows, not what a triage note assumes.

Open after this round, in the order a next round would take them:

1. 3.16.3.1.1.2 (packet 4 in message 136, JRU record 13; S13c9beb3);
   the same-cycle MA and message 2 after 'Start' (5.4.3.2 E26 / E27);
   5.10.3.15.2 b) (`EVC_Level_Sessions.Driver_To_L2` remembering the
   level 2 selection until the RBC data are entered).
2. The handover remainder: 3.15.1.3.2.4, 3.15.1.3.3 in SM, scenarios of
   3.15.1.3.1 c) and 3.15.1.3.9; 4.8.4 [14] for message 4 with SM; the
   authority half's packet 45 inside a rejected message 3 / 33.
3. Items 2 and 3 of the fifth round's list (the reached signatures,
   S55128ce0; chapter 6 in E7).
