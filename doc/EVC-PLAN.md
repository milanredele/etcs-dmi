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
| Juridical recording | SUBSET-027 | In: the JRU port emits the messages of SUBSET-027 4.2.2 (the header of 4.2.3, the variables of 4.2.4) as a byte stream; the physical link is E8's. |
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

Since 2026-10-12 the check ties the matrix to the sources both ways
(§13 "Comments and traceability"): every unit, subprogram, type or
scenario a note names must exist (a rename breaks the check, not the
trace), and the sources carry `@req` tags, comment lines
`--  @req 3.5.3.4 a), 3.5.3.4.1` directly above the declaration that
implements those clauses (above the package for the unit as a whole),
each of which must be a row of the matrix, done or partial, whose note
names the unit. A new implementation therefore edits the row and the
tag together; AGENTS.md "Comments and traceability" has the rules.

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

### Level 2 selected without the conditions for a session (e5/level2-radio-data, 2026-10-09)

**Done.** 5.10.3.15.2 b) and its note in `EVC_Level_Sessions`:
`Driver_To_L2` gives the session order of a) only with a valid contact
and `EVC_Sessions.Network_Ready` (3.5.6.7); otherwise the selection is
remembered (`Radio_Data_Awaited`: `No_Contact` or `No_Registration`)
and `Take_Radio_Data` turns the driver's RBC data (MSG_DRIVER_DATA kind
5) into the order: they are read by `EVC_Sessions.Mission.Take_Radio_Data`
(the S3 decoding of 5.4.3.2, `Driver_Contact`; a contact entered is
stored by `EVC_Radio.Set_Contact`, still the only writer), reached
through the new `EVC_Sessions.Take_Radio_Data`; the set-up then waits
for the registration (3.5.6.7). Scenarios in `EVC_Test_Levels`:
`L2_Radio_Data_No_Contact`, `L2_Radio_Data_No_Registration`,
`L2_Radio_Data_Into_TR`.

**Decisions.** (1) The request to the driver is the DMI's own (DMI
Table 50 S4 -> D5 -> S5-1 from the contact and registration bits of
MSG_ONBOARD); the protocol has no bit for it and every "waiting" value
disables the window the driver must use, so nothing new is sent. (2)
The selection is forgotten when level 2 is left, once the session of
the supervising RBC is established, and in SB (the start of mission's,
5.4.3.2 D7), SL, PS, SF, IS and NP. (3) The note: in TR the driver's
data are not taken (the DMI cannot offer the window there), in PT they
are; the selection is kept through TR. (4) a) now also requires the
registration: a valid contact without it awaits the driver's Radio data
too (b), instead of an order held by 3.5.6.7.

**SUBSET-076.** 679 / 1665 / 846 before and after, 0 regressions.

**Left.** The DMI's MO05 exception of Table 50 D5 (the Radio data window
once MO05 is acknowledged after a switch to TR; `dmi_windows.adb` says
it is not modelled); FRMCS in a) (the port reports no FRMCS
registration).

### Same-cycle MA and message 2 (e5/same-cycle, 2026-10-09)

**Implemented.** 5.4.3.2 E26 / E27 in one cycle after 'Start' in level 2
(and S150 a) / b) of 5.11.2.2 in PT): the MA wins. The cycle order is
kept: the message 2 still proposes SR in its cycle
(`EVC_Mission.Take_RBC_Answer`), which remembers the count of radio MAs
(`Context_T.Radio_MAs`, from `EVC_Radio_Authority.Radio_MAs_Accepted`;
the one field added in `EVC_Core.Evaluate_Modes_And_Levels` and the
three other context aggregates). In the next cycle, when that count has
changed and the procedures ask the acknowledgement of a mode profile
(`Profile_Ack`), the SR proposal, still unacknowledged, is withdrawn as
an expired one is, and the mode profile's proposal stands (S25).
Scenarios in `EVC_Test_Sessions`: `Scenario_SoM_L2_Same_Cycle` (OS) and
`Scenario_SoM_L2_Mode_Proposal_LS` (LS by 4.6.3 [70]). Matrix: 5.4.3.2
S21 done, S25 note.

**Note.** Two radio messages of one cycle need increasing T_TRAIN
(3.16.3.3.3: a stamp equal to the preceding one is inconsistent); the
test helper `SR_Authorisation` takes an `Earlier` stamp offset for it.

SUBSET-076: 679 passed, 1665 failed, 846 blocked, unchanged (0
regressions, 0 improvements). Unit proofs of `EVC_Mission` and
`EVC_Core`: 0 unproved.

**Left.** Nothing of this package.

### Inconsistent radio messages reported (e5/error-report, 2026-10-09)

**Implemented.** 3.16.3.1.1.2 for the radio cases: a message refused by
its time stamp (3.16.3.3.3, `EVC_Sessions.Take_Message`) gives M_ERROR 4
(3.16.3.1.1 b), a message the codec refuses on a usable session
(3.16.3.1.1 c, 3.16.1.1; `EVC_Sessions.Take_Inconsistent`, called by
`EVC_Core.Read_Radio_Messages`) M_ERROR 3; `EVC_Sessions.Reports.
Request_Error` queues it per session and `Produce` sends a 136 with
packet 0/1 and packet 4 to that RBC in the next cycle, one per message
(3.16.4.1: waiting while the session is not established). JRU record 13
with M_ERROR in byte 2 (`EVC_JRU_Records.JRU_Radio_Error`,
`EVC_Core.Record_Radio_Error`, from `EVC_Sessions.Error_Noted`).
Scenario `EVC_Test_Sessions.Scenario_Session_Error_Report`. Golden
`valid_inputs`: two JRU 13 records added (M_ERROR 3, radio input the
codec refuses), as intended.

**Decisions.** 3.16.3.1.1 a) is the Euroradio port's. One packet 4 per
message, at most 8 pending per session, the code of the last kept.
M_ERROR 5 (3.16.3.4, after the link is re-established) not sent.

**Runner.** SUBSET-076 sv30 unchanged (230 passed, 615 failed, 299
blocked, 0 regressions): 3160300_01 still stops at step 87 although the
136 with packet 4 M_ERROR 4 goes out; `S076_Run.Radio_Expect` judges the
first 136 of the window only and FIELD=value against the message's own
variables. S13c9beb3 triaged `model`.

**Left.** The runner's packet fields in `Radio_Expect`; M_ERROR 5; the
balise group errors of 3.16.4.2 (0, 1, 2, 7, 8: 3.16.2, E6) and the
odometer ones (9, 10), which can call `Reports.Request_Error` through a
public `EVC_Sessions` entry.

### E5 integration after the eighth round (2026-10-09)

Merged on master: e5/level2-radio-data (5.10.3.15.2 b) and its TR / PT
note: the driver's level 2 without a valid contact or a registered
mobile waits for the Radio data, `EVC_Level_Sessions.Radio_Data_Awaited`,
the data taken outside the start of mission by
`EVC_Sessions.Take_Radio_Data`; no new MSG_ONBOARD bit, the DMI shows
the request from the contact and registration bits), e5/same-cycle (a
message 2 and an MA with a mode profile in one cycle after 'Start': the
MA wins, the SR proposal withdrawn in the next cycle; the LS proposal
scenario, 4.6.3 [70]) and e5/error-report (3.16.3.1.1.2: an inconsistent
radio message is reported to its RBC with packet 4 in a message 136,
M_ERROR 4 for the time stamp of 3.16.3.3.3 and 3 for a message the
codec refuses, at most 8 pending per session, sent once the session is
established; JRU record 13; the golden `valid_inputs` gained two such
records, reviewed). SUBSET-076 on the merged tree: 679 passed, 1665
failed, 846 blocked, unchanged; 3160300_01 stays at step 87 because
`S076_Run.Radio_Expect` judges only the first message of a window and
reads no packet field (S13c9beb3 retriaged `model`). Green: check.sh
(evc_test 11577), the full proof (10824 checks, 0 unproved, margin 47726
steps), the cross build (stack 27136 B), wasm and both smoke checks.

Measured, three agents (two `opus-medium`, one `opus-trim`), the briefs'
premises checked on the trace before launch: 116 to 173 requests, 13 to
19 minutes, 106k to 127k final context, 5 to 9 USD, no wait over 5
minutes, the guard 1 to 2 refusals per agent (down from 5 to 7 with the
literal environment lines); every brief premise held and every package
finished its steps. The Edit tool: the trim agent used it 15 times, the
two medium agents kept to Bash heredocs because of the auto-mode rule.

Open after this round, in the order a next round would take them:

1. The runner's `Radio_Expect`: any message of the window, a packet's
   fields (M_ERROR); then 3160300_01 passes step 87. M_ERROR 5
   (3.16.3.4). The balise group and odometer error reports (3.16.4.2)
   with E6.
2. The handover remainder: 3.15.1.3.2.4, 3.15.1.3.3 in SM, scenarios of
   3.15.1.3.1 c) and 3.15.1.3.9; 4.8.4 [14] with SM; the authority half's
   packet 45 inside a rejected message 3 / 33.
3. The DMI's MO05 exception of Table 50 D5 (the Radio data window after
   a switch to TR); items 2 and 3 of the fifth round's list (the reached
   signatures, S55128ce0; chapter 6 in E7).

### Bench page and the runner's level rule (2026-10-09)

The bench page's "How to drive it" text was rewritten from
`Evc_Test_Touch`: the SR acknowledgement after 'Start' is a delay-type
button (DMI 5.3.2.6.6), pressed and held for two seconds in area C1,
which the old text did not say; the level 2 paragraph described the
gap closed by e5/sr-proposal. Checking the level 2 touch route found
the runner selecting level 1 where a sequence meant level 2: the
sequences disagree with themselves (the step's column, the DMI event's
LEVEL, the comment's note and the steps that follow), and the reader
cut the comments at 256 characters before the author's note.
`S076_Run.Selected_Level` now takes the level the next four steps
settle on, within the item's list ("Level-0/1/NTC"), then the column,
the comment, the LEVEL field. 685 passed, 1619 failed, 886 blocked
(679 / 1665 / 846 before), 40 improvements, 5 regressions understood
(the whole comment reveals a set speed input and a known packet 80
defect). The start of mission by touch in level 2 now passes the Radio
data window, the RBC data and the session set-up (5040300_17 to step
39); S322852a4 keeps 37 sequences, mostly chapter 6 families where
level 2 is selected with a valid contact and the DMI's Table 50 D5
goes to the Main window: an item for E7 or the DMI. Three stale triage
lines of the radio data buttons were removed.

### Train Data to the RBC (e5/train-data-129, 2026-10-09)

S13f5df67 ("129 not sent", 43 SV30 sequences) was the runner's, not the
on-board's: the on-board sends 129 in the cycle of 159, as 3.18.3.4
asks ("following the successful establishment", which 3.5.3.7 d places
at the system version), and a debug listing of the windows of
3040200_01 showed 159, 129 and 136 together at step 53. The sequences
record the RBC's 38 before or after the 129 (436 cases before, 69
after, sometimes both in one family): the input 38 opened a new window
and dropped the 129. `S076_Bench.New_Window (Keep_Radio)` keeps the
radio outputs listed when the input is an RTM message at the distance
of the step before (without the distance condition an earlier 147 of
4080405_01 and 136 of 3180400_01 matched first). No change under
`evc/`, no matrix row. 685 / 1619 / 886 -> 689 passed, 1605 failed,
896 blocked, 48 improvements, 0 regressions; all 43 moved on.

Left: 4080455 (six of eight now stop at Sa03cccdc, step 78: the
immediate order to level 2 of BG3d after an MA by radio in level 1
reaches no level event; acceptance of the group to analyse), two at
S6c605c52 (E6); the new S0ebd65fd (3040200_03 step 137: an MA 33 after
the level 2 start of mission leaves the on-board in SB, the authority
half's); the others stop at signatures triaged before.

### Session orders not followed (e5/session-orders, 2026-10-09)

The signature Sa8a3ba1a ("expect RTM connect: not requested", 147
sequences) is not one cause, and mostly not packet 42. Classified from
the telegrams before the failing step (one trace per cause):

- 111 sequences, every one of the large families (3090300, 9990500,
  9990400, 3070300, 3050300_03, 4100103_01 ...): a group with packet 133,
  Q_RIU = 1, orders a session with an RIU: radio infill (3.9), E7.
- 4 (4100103_15, 5040300_23 to _25): a packet 45 of type FRMCS+GSM-R
  (Q_NETWORKTYPE 1) comes first; with both radio systems installed (the
  default of `EVC_Config.Radio_Config_T`) and the port reporting no FRMCS
  registration (e5/registration decision 2), 3.5.6.7 b) holds the set-up
  of the following packet 42 for ever. The on-board follows the clause;
  the runner's installation is the gap. Installing GSM-R only in
  `S076_Bench.Power_On` moves the four (to steps 82-100) but regresses
  3050600_05, which tests exactly 3.5.6.7 b) with both systems and FRMCS
  not registered. Not committed: the runner needs the systems per
  feature (both for 3050600, GSM-R only elsewhere), or the port an FRMCS
  registration report (E7).
- SUBSET-076 data: 3050300_11 (the 200 m group carries NID_RBC 16383,
  "last known RBC", with no contact stored: ignored, 3.5.3.13.1; the
  text says 1515), 4080500_02 (a single balise group without linking,
  packet 42 with Q_DIR nominal: rejected, 3.6.3.1.4), 4080100_02 (the
  group's second balise has M_VERSION 0: ignored, 3.17.3.5 a), so no
  orientation for the nominal packet 42).
- Not analysed: 9990500_02 (the runner's train still reversing when the
  group at 180 m comes), 3060500_01, and 17 sequences whose last input is
  no balise group (3040200, 3060300, 4040600, 4040800, 4080415, 5060200).

Nothing in `EVC_Sessions` or `EVC_Acceptance` was changed: packet 42 is
accepted in every level (4.8.3, [14] / [15]) and applied by
`Apply_Order` in level 1 too (3.5.3.4 b). The triage line of the
signature is rewritten with these causes (category E7, the majority).

### Position reports by event, and the runner's radio expectations (e5/reports-136, 2026-10-09)

**Implemented.** `S076_Run.Radio_Expect` judges every message of the
kind in the window (the first that meets the expectation passes) and
reads FIELD=value from packets 0, 1 and 4 (`Packet_Field`: M_ERROR,
V_TRAIN, M_LEVEL, M_MODE), else from the message's own variables:
3160300_01 SV22 / SV30 pass step 87. 3.16.1.1 / 3.16.3.1.1.2: a radio
message with a packet that chapter 7 does not define (the codec skips it
by L_PACKET, `EVC_Received.Last_Unknown_Packets`) is reported with
M_ERROR 3 and not used (`EVC_Core.Read_Radio_Messages`); 7040200_03
passes in all three versions. Scenario: `Scenario_Session_Error_Report`
gained the case. 3.6.5.1.4: a), b), g), h), i), j) were already there;
k) and e) are sent by the handover (`Border_Front` / `Border_Rear` ->
`Req.Report`, rows done / partial); l) partial (radio errors); c), d)
(train integrity) and f) still deferred.

**Analysed (S13c9beb3).** 3060500_03: s076 (a joined case refers to an
LRBG BG6 the sequence never passes). 3150100: runner model (an ODO
reach-point goes to the step's nominal position, not to the location of
packet 58 or LRBG + D_RBCTR). 9990400_24: s076 (the bits carry M_LOC 2
while the step says M_LOC 0, TC bug 1124). SUBSET-076: 685 / 1619 / 886
-> 688 / 1614 / 888.

**Left.** The runner's reach-point to the location of packets 58 / 131
(3150100, 11 sequences); 3160300_01 SV21 (its packet 72 counted unknown
before the time stamp check: M_ERROR 3, the sequence expects 4); the
families 3110500, 3160200, 4080100, 4080428, 4080442, 5100300, 5100400,
5150400, 3060100 not traced; 3.6.5.1.4 c), d), f).

### E5 integration after the ninth round (2026-10-09)

The round took the runner's three largest stopping signatures. Merged:
e5/train-data-129 (no on-board change: the on-board sends 129 with 159
as 3.18.3.4 asks; the runner dropped it when the RBC's message 38 came
first, now the window keeps the radio messages already sent),
e5/session-orders (no on-board change: of the 147 sequences without a
connection request, 111 wait for a session with an RIU ordered by
packet 133, radio infill, E7; 4 are held by 3.5.6.7 b) because the
runner installs FRMCS that never registers; 3 are SUBSET-076 data
defects; 19 to analyse) and e5/reports-136 (the runner's `Radio_Expect`
judges every message of the window and reads the fields of packets 0,
1 and 4; the on-board reports a radio message carrying a packet chapter
7 does not define with M_ERROR 3 and does not use it, 3.16.1.1; the
3.6.5.1.4 events a, b, e, g, h, i, j, k were found implemented, c, d, f
left). SUBSET-076 on the merged tree: 692 passed, 1600 failed, 898
blocked (685 / 1619 / 886 before), 0 regressions, baseline re-recorded.
Green: check.sh (evc_test 11542), the full proof (10826 checks, 0
unproved, margin 47726 steps), the cross build (stack 27120 B), wasm and
both smoke checks.

Measured, three agents (one `opus-trim`, two `opus-medium`): 133 to 191
requests, 14 to 21 minutes, 103k to 159k final context, 6 to 11 USD, no
wait over 5 minutes; the runner itself ran 5 to 21 times per agent (the
traces are the reading of this round); the LSP tool again unused. One
brief premise was wrong although checked on a trace: the trace showed a
balise group read and a connection expected, and the brief assumed a
session order (packet 42) where the group carried packet 133; the check
of a premise must read the telegram's packets, not only the step's
verdicts. Two of the three signatures were runner gaps, not on-board
ones: the runner's judging is now a first suspect for a radio
expectation.

Open after this round, in the order a next round would take them:

1. Sa03cccdc (6 of 4080455): an immediate level 2 order from a balise
   group in level 1 with a session, no level event; S0ebd65fd
   (3040200_03: an MA at standstill after 'Start' in level 2 leaves SB);
   the order of the error checks when a message is both stale and
   malformed (3160300_01 SV21).
2. The runner: the reach-point moved to the location of packets 58 and
   131 (3150100, 11 sequences); the radio systems installed per feature
   (3.5.6.7 b with FRMCS); the 19 + 9 untraced sequences of Sa8a3ba1a
   and S13c9beb3.
3. The handover remainder (3.15.1.3.2.4, 3.15.1.3.3 in SM, scenarios of
   3.15.1.3.1 c) and 3.15.1.3.9), 3.6.5.1.4 c) d) f), S322852a4 (chapter
   6 and Table 50 D5), M_ERROR 5; radio infill (111 sequences) in E7.

### The untraced sequences of the ninth round (e5/untraced, 2026-10-09)

Analysis only, one trace per family; no behaviour changed.

**Sa8a3ba1a (8 sequences, 24 with the versions).** Onboard: 4040800_03,
4080415_01, 5060200_03, Exit Shunting to SB in level 2 is a mode change
to report, so a session is due (3.5.3.4 c), with the contact of a packet
42 read in SH (4.8.4 [3]); 3.5.3.4 c) is not implemented
(`EVC_Sessions.Mode_Changed` opens no session); 4040600_01, the
informative 4.4.6.1.6 (a fault in SL reported to an RBC). Runner:
3060500_01, a joined case re-delivers BG1d at the same place and the new
observation window drops the connection request of the first delivery
(keep the radio list for a balise input at the place of the step before,
in `S076_Run`, the runner package's file); 9990500_02, the train still
reversing. SUBSET-076: 3040200_01 (a joined case without the entry of
the RBC data), 3060300_02 (Use_FT references not expanded).

**S13c9beb3 (9 families).** Runner: 4080100_03, 5150400_02 (the rear end
at the RBC transition border, the reach-point of 3150100), 4080442_01 (an
optional step "only if in L2" judged in level 1). Onboard: 3060100_01,
3160200_15 (balise errors M_ERROR 0 / 2 not reported to the RBC,
3.6.5.1.4 l), 3110500_03 (the handover's 136 to both RBCs). To analyse:
4080428_01, 5100400_06, 5100300_09.

**3160300_01 SV21.** Its packet 72 is the plain text packet of system
version 2 (73 in 4.0.0, 7.4.2.23; translated by chapter 6, 6.6.5.2.3):
the codec is right for chapter 7, chapter 6 is not modelled. Decision,
written at `EVC_Core.Read_Radio_Messages`: the general criteria of
3.16.1.1 are checked before the time stamp of 3.16.3.1.1 b), one report
(M_ERROR 3).

**Left.** 3.5.3.4 c) (a session for a mode change to report in level 2,
9 sequences); the balise errors to the RBC (3.6.5.1.4 l); the runner's
window for a re-delivered group and its optional-step reading; the three
families to analyse.

### Runner: locations of packets 58 / 131 and the radio systems per feature (e5/runner-locations, 2026-10-09)

**Radio systems.** `S076_Bench.Set_Radio_Systems`, chosen per sequence in
`S076_Run` before the first power-up: both systems for feature 3050600
(3.5.6 tests; 3050600_05 holds the set-up by 3.5.6.7 b while FRMCS is not
registered), GSM-R only elsewhere (the port reports no FRMCS registration,
e5/registration decision 2). 4100103_15, 5040300_23 to _25 moved on.

**Reach-point.** A reach-point of the max safe front end or the min safe
rear end whose comment names packet 58 (Q_LGTLOC, D_LOC) or the RBC/RBC
border (D_RBCTR, "RBC transition") runs the train until the on-board's
nearest stored location of that kind is passed, through a new read-only
query `EVC_Position.Report_Location_To_Go (Front)` (Global `State`,
`EVC_Odometry.State`; proved); else the step's nominal position. Moved:
3150100_01 SV21/22 (90 -> 102), _02 (77 -> 80), _07 (73 -> 76),
4080428_01 (78 -> 119), 4080500_03 SV21 (94 -> 99).

**Finding (on-board, not changed here).** `EVC_Position.Set_Train_Length`
is called only by evc_test: `Length_Known` stays False in service, so no
min safe rear end location of packet 58 (3.6.5.1.5 c) and no rear border
passage (3.15.1.3.1 c) ever triggers a report: 3150100_02 step 80, _07
step 76. The train length of the validated Train Data should reach it.

SUBSET-076: 692 / 1600 / 898 -> 692 / 1598 / 900, 16 improvements, 0
regressions. **Left.** The train length above; 3150100_01 SV30 step 90
(location passed, no 136 while the sessions cycle 159 / 129 / 156);
3150100_05 SV21/22 step 103; 4080428_01 step 119.

### Level order by balise in level 1 and the MA at standstill (e5/level-order-ma, 2026-10-09)

Both signatures were the sequences' data, not the on-board: no change
under `evc/`. **Sa03cccdc** in 4080455 (SV30 _01 _02 _05 to _08, step
78): the linking of BG1d places BG3d, the group with the immediate
order to level 2, 300 m after BG2d (450 m, Q_LOCACC 10 m), and the
sequences put it at 200 m (400 m in _05 to _08); the on-board rejects
the message of a group found outside its expectation window
(3.4.4.4.3.2). Moved to 450 m in a copy of _01, the order is carried
out and the sequence runs on to step 80. **S0ebd65fd** (3040200_03
SV30, step 137): after the change to cab B the train is reverse to its
LRBG (the sequence's own 129 and 132 report Q_DIRLRBG 0), and the RBC's
message 33 is for the nominal direction of the LRBG (Q_DIR 1, D_REF
+2050 m): only data valid for the train orientation is taken
(3.6.3.1.1 a, 3.6.3.1.3), so no MA and SB stays; with Q_DIR 0 in a copy
the on-board reaches FS at step 137 (5.4.3.2 E29) and runs on to step
142. Scenarios: `EVC_Test_Levels.Scenario_L2_Order_Linked_Group`,
`EVC_Test_Authority.Scenario_Radio_MA_Direction` (`MA_Message` takes
Q_DIR). Matrix: the notes of 3.6.3.1.3 (still partial) and 3.4.4.4.3.2.
Triage: S0ebd65fd `s076`; Sa03cccdc rewritten, still `onboard` for its
other, unanalysed families. SUBSET-076: 692 / 1600 / 898 before and
after, 0 regressions, baseline kept.

Left: the other families of Sa03cccdc (3070300_12/13 step 87: BG11d at
1600 m with an immediate order to level 2, in level 1 with the linking
of the radio MA of 400 m that announces BG4 only, against 3.4.4.4.2 in
`EVC_Position.Decide_Linking`; 4080100_06, 4080425_04, 4100103_15,
5220200_03, 6060504/6060505, 9990500_24); a runner that places a linked
group at the location its linking gives (s076_bench) would move 4080455.

### E5 integration after the tenth round (2026-10-09)

Merged: e5/untraced (analysis: the 19 sequences without a connection
request and the nine families without a position report classified;
3.5.3.4 c) is not implemented for a mode change to report in level 2,
9 sequences; balise errors are not reported to the RBC; two runner
gaps; the SV21 packet 72 is the chapter 6 plain text packet; the check
order 3.16.1.1 before 3.16.3.3.3 decided), e5/runner-locations (the
runner's reach-point resolves to the stored packet 58 location or the
RBC border, `EVC_Position.Report_Location_To_Go`; the radio systems
installed per feature: both for 3050600, GSM-R only elsewhere) and
e5/level-order-ma (both signatures are sequence data: 4080455 places
its group outside the linking window, 3040200_03 sends a message 33
for the other direction; two scenarios). The runner-locations agent
found the on-board defect of the round: `Set_Train_Length` was called
by one test only, so no min safe rear end existed in service and no
rear-end trigger ever fired (3.6.5.1.5 c, 3.15.1.3.1 c). Fixed by the
coordinator: `EVC_Core.Sync_Train_Length` gives the position the
length of the valid Train Data every cycle (3.6.1.7, 3.18.3), with the
preservation the cycle's postcondition needs; the 3150100 family moved
on to the radio connection indication (Se0240012, S6514d681) and
5150400_02 to the packet of a rear-end report (Scdc515e8), all three
triaged `onboard`. SUBSET-076 on the merged tree: 694 passed, 1596
failed, 900 blocked (692 / 1600 / 898 before), 0 regressions, baseline
re-recorded. Green: check.sh (evc_test 11558), the full proof (10840
checks, 0 unproved, margin 47726 steps), the cross build (stack 27120
B), wasm and both smoke checks.

Measured, three agents (one `opus-trim`, two `opus-medium`): 140 to
185 requests, 16 to 22 minutes, 114k to 141k final context, 6 to 9
USD, no wait over 5 minutes, the runner 4 to 13 times each. Two of the
three packages were analysis with no on-board change; the on-board
defect of the round came from the runner package's side finding. The
Ada language server plugin was disabled before the round (three servers
of 1 GB for one project, no agent use in nine rounds).

Open after this round, in the order a next round would take them:

1. 3.5.3.4 c): a session for a mode change to report in level 2 (9
   sequences); the radio connection indication of 3.5.7 after a release
   or a loss (Se0240012, S6514d681); the packet of a rear-end position
   report (Scdc515e8).
2. The runner: the radio window kept for a group delivered again at the
   same place; "optional step, only if in L2"; the train still reversing
   at 9990500_02; 4080428, 5100400, 5100300 to analyse.
3. Balise errors reported to the RBC (3.6.5.1.4 l, with E6); the
   linking of 3070300_12 (3.4.4.4.2); the handover remainder; chapter 6
   (packet 72 translation, S322852a4) in E7.

### The packet of a position report after a single balise group (e5/report-packet, 2026-10-10)

Scdc515e8 (5150400_02 step 71, three system versions) is the sequence's
data, triaged `s076`: BG2d is a single balise group (N_TOTAL 1) and the
sequence holds no linking (no packet 5, no MA), so the on-board cannot
evaluate its orientation and reports on two groups, packet 1 with BG1d as
the previous LRBG (3.4.2.3.3.1, 3.4.2.3.3.2; only a previous linking
assigns a co-ordinate system to a single balise, 3.4.2.3.2.2). No change
in `evc/`: `EVC_Position.Report_Kind` and `EVC_Sessions.Reports` already
do this. `EVC_Test_Sessions.Scenario_Report_Packet` checks the 136 itself:
a linked single group gives packet 0, an unlinked one packet 1 with the
previous LRBG. Matrix: the note of 3.4.2.3.3.1 (the sending, was "E5").
SUBSET-076 unchanged: 694 passed, 1596 failed, 900 blocked.

### Session for a mode change to report (e5/mode-change-session, 2026-10-10)

3.5.3.4 c): `EVC_Sessions.Mode_Changed` notes a change that 4.5.2
reports (`Reports.Mode_Reported`, the rule of `Reports.Mode_Changed`)
and that is no End of Mission (`Mission.Ends_Mission`, 5.5.2); the next
`Evaluate` (`Mode_Session_Order`) orders the session through the order
path, as d) does, in level 2 with a valid stored contact. 4.8.4 [3]:
`Apply_Order` in SH and PS stores the contact of an order to establish
without the session (it opened one before). Decisions: a change out of
SB is not c) (the start of mission's a and g); nothing is ordered while
a session is established or being established with any RBC (3.5.3.4.1;
a handover's sessions are left to it; 3.5.3.4.2 through `Establish`'s
pending session); a trackside order of the cycle wins; without a valid
contact nothing is requested and the report stays due in `Reports`.
Scenario `Scenario_Session_Mode_Change`; matrix 3.5.3.4 c) and 4.8.4.2
footnote [3] done. SUBSET-076: 694 / 1596 / 900 before, 700 / 1590 /
900 after, 0 regressions, 15 improvements (4040800_03, 5060200_03 pass
in the three versions; 4080415_01, 4040800_05, 4080428_01 move on),
baseline re-recorded; new signatures S0dd91d8e (S3 skipped for a
contact valid from SH?) and S635191ad triaged `onboard`, to analyse.

### Safe radio connection indication (e5/connection-indication, 2026-10-10)

The indication of 3.5.7 is kept per session (3.5.7.6.1: a transition
table and a connection status timer per RBC): `EVC_Sessions` holds the
status, the requests and the timer of each session, and `Shown`, the
session the driver sees (`Indication`, MSG_STATUS radio byte).
`Ind_Timer`, every cycle, runs the timers (Table 2 [2]) and moves
`Shown` to the supervising RBC's session once it is established (3.5.7.6
a) or once the one shown is over (3.5.7.6 b); without a supervising RBC
the one shown stays until it is over, then the first session in use.
Both gaps were one cause: at the border the Accepting RBC became the
supervising one before its session was set up, and the single
indication followed that session only, so the Handing Over RBC's
release (3150100_02) and loss (3150100_07) changed nothing. The runner
waits 46 s for the Connection Lost symbol (A.3.1: 45 s; the sequence
repeats the connect "until t0+45", the window was 4 s;
`S076_Run.Wait_Limit`). Scenario `EVC_Test_Handover.
Scenario_Handover_Indication`. SUBSET-076: 694 / 1596 / 900 before and
after, 6 improvements (3150100_02 to step 92, _07 to step 97, three
system versions each), 0 regressions. Left: both sequences now stop at
an RTM connect expected only after the Handing Over session ends (the
on-board opens the Accepting session at the order, Sa8a3ba1a, the
handover remainder); [1] and [7] of Table 2; 3.5.7.7 (RIU, E7).

### E5 integration after the eleventh round (2026-10-10)

Merged: e5/report-packet (no on-board change: a position report after
an unlinked single balise group uses packet 1, 3.4.2.3.3.1 / .2; the
sequence expects packet 0: s076; scenario for both the linked and the
unlinked case), e5/mode-change-session (3.5.3.4 c): in level 2 a mode
change that the 4.5.2 table reports opens the session with the stored
contact, with 3.5.3.4.1 / .2; a packet 42 order read in SH or PS only
stores the contact, 4.8.4 [3]; 15 sequences moved, 4040800_03 and
5060200_03 pass) and e5/connection-indication (the indication of 3.5.7
kept per session, 3.5.7.6, the one shown following the supervising
RBC's session at a handover and the session that is over; the A.3.1
connection status timer of 45 s respected by the runner's wait for the
"Connection Lost" symbol). The merges met in `EVC_Sessions`'
`Refined_State` (both kept) and twice in the triage file, where the
merge took an older line for Scdc515e8 and lost a note of Sa8a3ba1a,
both restored by hand: the triage file is edited by every agent of a
round and its conflicts need reading, not a rule. SUBSET-076 on the
merged tree: 700 passed, 1590 failed, 900 blocked (694 / 1596 / 900
before), 0 regressions, baseline re-recorded. Green: check.sh (evc_test
11606), the full proof (10851 checks, 0 unproved, margin 47726 steps),
the cross build (stack 27120 B), wasm and both smoke checks.

Measured, three agents (one `opus-trim`, two `opus-medium`): 91 to 140
requests, 8 to 12 minutes, 83k to 126k final context, 3.5 to 7 USD, no
wait over 5 minutes, the runner 2 to 14 times each; all three premises
held, read with the packets and the clauses before the briefs. The
round's cheapest package (8 minutes) was the one that ended in a triage
with a scenario documenting the behaviour.

Open after this round, in the order a next round would take them:

1. The handover: the Accepting RBC's session is opened when the order
   arrives, the sequences 3150100_02 / _07 expect its connection only
   after the Handing Over session ends (steps 92 / 97; 3.15.1.3.1 a) to
   read again against 3.5.3.4.1 / .2); the remainder of 3.15.1.3
   (.2.4, .3 in SM, scenarios of .1 c) and .9).
2. S0dd91d8e (the DMI stays on the Main window after level 2 at S2 with
   a contact stored in SH) and S635191ad (the geographical position
   shown where hidden is expected); Table 2 [1] and [7] of 3.5.7.
3. The runner: the radio window kept for a group delivered again at the
   same place; "optional step, only if in L2"; 9990500_02; 4080428,
   5100400, 5100300; balise errors reported to the RBC (3.6.5.1.4 l,
   E6); chapter 6 (packet 72, S322852a4) in E7.

**Burndown chart** (2026-10-10): `test/tools/burndown.py` draws the state of
this plan from the repository's history: the clauses of the coverage
matrix left per phase (todo + partial) and the SUBSET-076 sequences
passed / failed / blocked at every first-parent commit that changed
them, with the phase outcomes and the E5 rounds read from the headings
of this file. The page `test/tools/burndown.html` is published as a
private artifact and republished after every integration, with the data
file `obj/burndown/burndown.json` next to it. At this round: 422 clauses
left in all phases, 227 in E1 to E5; 700 of 3190 sequences passed.

### Position reports by event, second round (e5/reports-by-event-2, 2026-10-10)

**Implemented.** 4.8.4.2 (row "Geographical Position", column SH: R):
packet 79 of a balise group is taken only when the acceptance table
accepts it in the on-board's level and mode
(`EVC_Position.Set_Linking_Context`, new parameter `Accept_P79`, set by
`EVC_Core` from `EVC_Acceptance.Accepted (Geographical_Position, ...)`);
scenario `Scenario_Geo_Rejected_In_SH` (`EVC_Test_Position`).
4080415_01 moves from step 231 to 295 in all three versions (S635191ad
gone).

**Analysed, no on-board change.** 5100300_09 step 61: the on-board is
in level 1 (the driver selected L1, the sequence's columns say L1), so
3.6.5.1.4 f) and 5.10.3.3.3 / .6.2 / .10.3, transitions from level 2,
do not apply; the 136 of the level change L1 -> L0 (3.6.5.1.4 g) is
sent at 850 m in the window of step 56. 5100400_06 step 103: the 136 of
the level change into level 2 and the mode change to OS (3.6.5.1.4 b, g)
is sent at 1200 m in the window of step 93 (BG4d), before the OS
acknowledgement. Both are windows of the runner (Keep_Radio), triaged
`model` in S13c9beb3. SUBSET-076: 700 / 1590 / 900 before and after,
3 improvements, baseline re-recorded.

**Left.** Packet 79 by radio is not taken at all (Sf5f9f637, 4080415_01
step 295: message 24 in level 1 with level 2 announced, 3.6.6, 4.8.3,
the transition buffer); 4080407_01 stops at step 90 (S44acb613, a 138
not expected); 5100400_06 after the runner's window: step 106 (FS at
the min safe front end) not traced; the rest of 5100300 (_02 Sc1c4236f,
_07 Sbfa49d0b, _08 S81c940f5) re-traced, unchanged.
### RBC handover, fourth round (e5/handover-4, 2026-10-10)

**Findings.** Premise 1 did not hold: the order of 3150100_02 step 67
(message 67 of the scn) names RBC 1616 at 900 m, not the RBC in
session; the D_RBCTR 0 / 1515 block is another one. 3150100_02 (cases
3, 4, 7) and _07 (cases 10, 11) all test 3.15.1.3.2, the exception for a
single-session on-board (connect only after the Handing Over session
ends). 3150100_01 step 90: no session was up at the location: 30 s
after the Accepting RBC's 159 without its 38, 3.5.3.7.4.1 terminated it
and set it up again through `Establish`, which ended the supervising
session too.

**Implemented.** `EVC_Sessions.Evaluate`: a pending session of the
Accepting RBC of the stored order is opened beside the supervising one
(3.5.3.7.4.1 with 3.15.1.3.1 a). `EVC_Sessions.Handover.Apply_Order`,
decision 5: an order whose Accepting RBC is the supervising RBC opens no
second session (3.5.3.4.1); that session goes on supervising and is set
up again once terminated and released (3.5.3.4.2 b), as with one
session (`Single`). Scenarios `EVC_Test_Handover.
Scenario_Handover_Same_RBC`, `_Ack_Missing`, `_Rear_Repeat` (3.15.1.3.1
c), 3.15.1.3.9). Matrix: 3.15.1.3.2 with a) to d), the last sentence and
.2.4 n/a (two sessions); 3.15.1.3.1 c) and .9 done. The runner blocks
the five cases from their first step (`S076_Run.Single_Session_Cases`,
reason optional, "not applicable: 3.15.1.3.2"). SUBSET-076: 700 / 1590
/ 900 before, 700 / 1584 / 906 after; 6 expected regressions (_02, _07
blocked, three versions), 3150100_01 SV30 90 -> 102 (S776cef6c);
baseline re-recorded.

**Left.** 3.15.1.3.3 in SM (the safe consist length: no SM mode in
this on-board yet, row stays partial); 3.15.1.3.2.3 has its scenario in
`Handover_Radio` already. For the runner: 3150100_01 drives 586 m at 12
km/h (170 s) to the packet 58 location of step 88, past both 159 waits.
### Runner, third round (e5/runner-3, 2026-10-10)

Five rules in `S076_Run` (test/src/s076_run.adb), no change in `evc/` or
`dmi/`:

- An expectation whose comment restricts it to level 2 ("Only if in L2",
  "only in L2", 44 sequences of sv30) is not judged (optional) when its
  level columns or the on-board's level are not 2 (4080442_01 step 51).
- A balise group delivered again at the place of an earlier delivery of
  the same group keeps the radio messages listed (`Keep_Radio`;
  3060500_01, BG1d at 50 m in steps 39 and 43, step 49 the connect
  request of step 39).
- A balise group or ODO input more than 5 m ahead of a train going
  backwards turns the train forward first (9990500_02, BG2d at 180 m
  after the reversal); not for other inputs (9990500_27 step 47, a
  timer at the place of a max safe front end reach-point).
- A driver's acknowledgement right after a balise group input keeps the
  radio messages of the group listed (5100400_06: the 136 of the level
  and mode change at BG4d, 3.6.5.1.4 b / g, sent at 1200 m and listed
  after the OS acknowledgement at 1215 m). 5100300_09 step 61 (a 136 of
  the group at 850 m expected after a min safe rear end reach-point at
  the same place) has the same cause but another shape: not covered.
- "confirm RBC-data" reaches the RBC data window through the Radio data
  window ('Enter RBC data', also from the Main window) and confirms the
  stored contact, typed from the on-board's contact since the protocol
  does not carry it to the DMI (11.7.1.4). 4040800_05: the level after
  Exit Shunting is valid, so 5.4.3.2 D2 / D3 end at S10, the level 2
  selected from the Main window follows Table 50 S4 -> D5, and with the
  contact stored in SH (4.8.4 [3]) valid and the radio registered D5
  goes to S8: the DMI is right; the sequence shows the RBC data window
  (its case rows 5 to 9 are not in the extract). Open: the DMI cannot
  propose the stored contact (no protocol field).

SUBSET-076: 700 / 1590 / 900 before, 706 passed, 1584 failed, 900
blocked after, 0 regressions, baseline re-recorded. New signature
Sd577e7be (5100400_06 step 106, the joined case's end of the OS area
behind the train), triaged `model`. Not done: item 6 (S1f552964, the
Main window expected at the start of a joined case).

### E5 integration after the twelfth round (2026-10-10)

Merged: e5/reports-by-event-2 (4.8.4.2: the packet 79 of a balise group
read in SH is rejected like the table says, `EVC_Position.Set_Linking_
Context (Accept_P79)` from `EVC_Acceptance`; 5100300_09 and 5100400_06
analysed: their 136 is sent at the level change, the step expects it in a
later window), e5/handover-4 (the Accepting RBC's session set up again
after a missing 38, 3.5.3.7.4.1, without ending the supervising one;
an order naming the supervising RBC opens no second session, 3.5.3.4.1
/ .2; 3.15.1.3.2 n/a for this two-session on-board and its test cases
blocked as not applicable, `S076_Run.Single_Session_Cases`; scenarios
for 3.15.1.3.1 c) and .9) and e5/runner-3 ("only if in L2" steps
optional outside level 2; `Keep_Radio` for a re-delivered group and for
a DMI acknowledgement right after a group; a reversing train turns
forward for an input ahead; the RBC data confirmed through the Radio
data window, Table 50 S4 / D5 / S8, with the stored contact typed).

Verification on the merged master: `test/check.sh` ok (evc_test 11646
checks), the full proof 10853 checks, 0 unproved (margin 47726 steps),
cross build and stack 27120 B (margin 5648), wasm and both smokes 0
failures. SUBSET-076: 700 / 1590 / 900 before, 706 / 1578 / 906 after
(the 6 blocked are the not-applicable cases of 3150100_02 and _07),
0 regressions, 0 untriaged. Triage conflicts: the lines of Sa8a3ba1a and
S13c9beb3 were rewritten in different parts by two agents each and
merged by part by hand.

Measurements (requests, duration, final context, cost at the rates used
before): handover-4 238 / 19 min / 190k / 16.0; reports-by-event-2 142
/ 14 min / 116k / 6.6; runner-3 190 / 19 min / 131k / 8.9. The handover
agent made the most requests of any round so far for a brief of 110
tool calls: a third of its turns carried no tool call.

Lessons: of the eight premises in the three briefs, three did not
hold. The `var` blocks after the steps of a scn file are not in the
order of the steps (the "same RBC" order of 3150100_02 was another
message; the runner's reading, `S076_Sequences`, maps them: ask it, not
the file order); a sequence's level column is to be read before a
clause is chosen (5100300_09 is level 1); and a 136 "not sent" at a step
after other expectations of the same event is first a window question.
The runner's windows now have four keep-rules; a fifth shape is open.

Open:
1. Packet 79 by radio is not taken at all (Sf5f9f637, 4080415_01 step
   295: 3.6.6, 4.8.3 with the transition buffer in level 1 with level 2
   announced); 4080407_01 S44acb613 (a 138 sent where none is
   expected); 4080428_01 not traced.
2. Runner windows: 5100300_09 step 61 (a reach-point at the place of the
   group that triggered the 136); Sd577e7be (5100400_06 step 106, the
   joined case's OS area end behind the train); S1f552964 (the Main
   window expected at the start of a joined case, 25 sequences:
   undecided); 3150100_01 next stop step 102 (S776cef6c, s076), and its
   170 s drive at 12 km/h to the packet 58 location, after which the 38
   of step 94 comes after both 159 waits.
3. The DMI protocol has no field for the stored RBC contact, so the RBC
   data window cannot propose the stored values (DMI 11.7.1.4): a
   protocol item for the DMI side.
4. 3.15.1.3.3 in SM (no SM mode yet); balise errors reported to the RBC
   (3.6.5.1.4 l, E6); chapter 6 (packet 72, S322852a4) in E7.

**Backlog** (2026-10-11): `doc/BACKLOG.csv`, checked by
`test/tools/backlog.py --check` in the whole check, holds the open items
that are neither a clause of the coverage matrix nor a failure signature
of the triage (runner gaps, protocol items, decisions pending, tooling,
harness). It replaces the "Open" lists of the integration subsections,
which were re-written by hand every round; the burndown counts it. The
first 25 items are the open items of rounds 4 to 12 and the level 1 gaps
E2 to E4 left behind (the bookkeeping of round 13 re-reads their rows).


### Bookkeeping of the rows left open by E2 to E4 (e5/bookkeeping, 2026-10-11)

The 82 rows of phases E2 to E4 with status todo or partial and no `[E5 ...]`
tag (backlog item B025) were re-read against the code their notes name,
the scenarios and the clause. Outcome per phase (done / partial / todo /
deferred / n/a):

| Phase | Rows | Done | Partial | Todo | Deferred | n/a |
|---|---|---|---|---|---|---|
| E2 | 24 | 17 | 4 | 0 | 3 (E6) | 0 |
| E3 | 11 | 3 | 5 | 0 | 3 (E6, E7) | 0 |
| E4 | 47 | 1 | 24 | 20 | 1 (E7) | 1 |

Every row left partial or todo names its backlog item (`[B0nn]`); a
deferred row carries the tag `[E6 ...]` or `[E7 ...]`. Statuses per
phase, from `trace_subset026.py --check`, before and after: E2 done 114
/ partial 30 / deferred 39 / n/a 1, then 131 / 10 / 42 / 1; E3 done 445
/ partial 17 / deferred 35, then 448 / 11 / 38; E4 done 544 / partial
93 / todo 20 / deferred 93 / n/a 16, then 545 / 90 / 20 / 94 / 17 (the
other partial rows of E4 are E5's, tagged). No code changed, no
scenario added.

Genuine gaps found (new backlog items): B030 the driver not informed of
an impaired odometer (3.6.8.5, 3.6.8.6.2); B031 gamma = 1 of 3.6.4.1.5
(SB without Train Data, Supervised Manoeuvre); B032 no scenario of the
crossing direction in SL / PS / SH (3.6.3.1.3.1); B033 the linking in
rear of the new reference group not kept (3.7.3.1 m); B034 the route
unsuitability's temporary EOA (3.12.2.4, 3.13.1.5); B035 the brake of a
movement during the Train Data entry (3.14.1.5, 3.14.1.7.6); B036 the
columns of A.3.4.1.3 other than k not re-read since E3; B037 no
scenario of A.3.5.2's examples; B038 the balise information of a new
level accepted at once instead of buffered (4.8.3 [1], 4.8.5.1,
5.10.1.7). The rows already covered by B013 (Limited Supervision
display, 17 rows and the 3 of 4.7.2.1), B014 (4.12.1, 10 rows with 3.14.1.11) and B015 (the
small level 1 gaps, 6 rows plus 3.14.1.5) keep them.

Stale deferrals outside the 82 (not changed, status deferred): 3.12.2.4
and 3.14.1.7.6 defer to "E4", 3.14.3.6 to "E4" too; 4.11.1.1 and
4.11.1.3 (partial, `[E5 session]`): the RBC contact and the radio
network are kept over No Power since the E5 registration rounds
(`EVC_Retained.RBC`, `.Network`), so what is left is the EOLM (E7) and
the non-volatile store of the target (E8): partial stays right only
until the table's remaining item ("not yet applicable" level table) is
checked, then deferred `[E7 ...]`.
### Juridical record of a received radio message (e5/jru-radio, 2026-10-11)

**Implemented.** SUBSET-027 record 9 (message from the RBC, the JRU
port's event 3: NID_MESSAGE, L_MESSAGE) is written at reception in
`EVC_Core.Read_Radio_Messages`, once per message the RTM port delivers,
before the codec and whatever the message's later use. Before, it was
written at reception too, but only for the messages the codec accepted:
the 35 sequences of S63b7a729 had messages the codec refuses (packet 70
with M_LINEAXLELOADCAT 0, a spare value; 254) or wrong lengths, not
unused messages as first thought. Scenario
`EVC_Test_Sessions.Scenario_Session_JRU_Received`. Golden `valid_inputs`:
two JRU 3 records added (the refused messages), as intended.

**Decision.** "Received" is what the Euroradio delivers (3.16.3.1.1.2
speaks of an inconsistent message "received"): a message refused by the
codec (3.16.1.1, an unknown NID_MESSAGE such as 254) or later by the
time stamp check (3.16.3.3.3) is recorded too, its refusal by the JRU 13
of e5/error-report after it. A frame whose L_MESSAGE disagrees with its
length never leaves the RTM port (`EVC_Ports.Valid_RTM_Input`): not
recorded, and not reported either (3.16.3.1.1 c, 8.4.4.2.1; B050,
8040400_01 step 66).

**Runner.** An `expect JRU record 9` after an output step and directly
before an `input RTM message` is judged after that input
(`S076_Run.Step_Order`; 3150100_09 / _11 step 71); "Only if L2" is a
level 2 only comment too (6060302_04, 6060303_01). Record 10 is listed
before its `expect RTM message` 625 times in sv30, but is not judged
(B051). SUBSET-076: 706 / 1578 / 906 before, 706 / 1575 / 909 after,
0 regressions, 30 improvements; S63b7a729 35 -> 9 sequences (8040400_01
B050; 8040100_01, 9990400_28, 6060400_07 extractor: bits and L_MESSAGE
disagree; 9990200_13 a record 9 meant as 10). 4080100_01 did not change
level at the message 24: the "L2" was the state after the runner's wait;
it stops at step 96 now. 3120200_05 (step 72, S49bc1c1a, not this
package's signature): "Route unsuitable - axle load category" not
shown; the comparison of route suitability with the Train Data and its
reaction (3.12.2.3, 3.12.2.4) are deferred in the matrix (rows of E3,
noted E4), not E5: left for the matrix owner.
### Geographical position by radio and the balise transition buffer (e5/radio-geo-buffer, 2026-10-11)

**Implemented** (B001): the packet 79 of a radio message (3.6.6.4.1).
Message 24 with packet 79 goes to `EVC_Radio_Info` like a text message
(`EVC_Radio_Authority.Take_Message`); `EVC_Core.Take_Radio_Geo`, after
`Release_Transition_Buffer`, gives the cycle's radio messages to
`EVC_Position.Take_Radio_Geo` with the verdict of
`EVC_Acceptance.Radio_Geo_Verdict` (4.8.3, the row "Geographical
Position, From RBC: Yes": A in level 2, R [2] elsewhere; 4.8.4.2, the
mode column shared with the balise row). Accepted: `Take_Geo` with the
LRBG, the references naming the LRBG or one of the last groups anchored
at once, the others when passed. Stored (level 1 with level 2
announced): the last packet kept in `EVC_Position` and used at the
transition (4.8.5.5). Rejected: the kept one deleted (4.8.5.4 a).
Scenario `Geo_By_Radio` in `EVC_Test_Position`.

**Decisions.** One packet kept, not three sets: a packet 79 replaces
the references not yet applicable (3.6.6.3), so the sequential
re-evaluation of 4.8.5.5 leaves the last one; only the packet is kept,
the other packets of its message 24 are taken at once (4.8.5.2.1: the
"set of information" is the part of the message stored). A packet whose
message names an LRBG the on-board does not know is not taken; the
default country of its references is the LRBG's. In PT, rejected (as for
a group). Judged in the level and mode after the transitions of the
cycle.

**SUBSET-076**: 706 / 1578 / 906 before and after; 0 regressions, 6
improvements (4080415_01 295 -> 297 in the three versions, Sadfc7768
triaged `model`: the TRN window of the joined case before is still open;
9990400_29 68 -> 86).

**Left.** B002, the balise side of the transition buffer, not started
(budget). Its premise is to be corrected first: the balise rows of
4.8.3 carry [2] only in the column NTC (out of scope), so with level 2
announced in level 1 no balise information is stored; the case is [1],
level 1 information (packets 12, 21, 27, 5, 68...) read in level 0 or 2
with level 1 announced, accepted at once today (`EVC_Acceptance`
header, `Level_Accepts` with `C.L1_Announced`). Shape proposed: keep the
group's packets judged [1] (not the whole passage: up to about 1 KB of
telegrams per group) in a buffer of three sets owned by
`EVC_Stored_Information`, deleted by 4.8.5.4 a), and evaluated by
`Evaluate_Released`'s path when `EVC_Levels.Switched_To (L1)`, with
`Level_Accepts` returning a third verdict "stored" for [1]. B060: the
kept packet 79 is not deleted when the session that gave it ends
(4.8.5.4 c).

### E5 integration after the thirteenth round (2026-10-11)

Merged: e5/bookkeeping (the 82 rows of E2 to E4 left open re-read: 21
done, 33 partial and 20 todo with a backlog id each, 7 deferred to E6 /
E7, 1 n/a; E2 partial 30 -> 10, E3 17 -> 11; nine gaps as backlog items
B030 to B038), e5/jru-radio (JRU record 9 for every radio message the
port delivers, before the codec, 3.16.3.1.1.2: a refused message is
received too and then gets its JRU 13; the runner judges a record 9 the
sequence lists before its message after that input; S63b7a729 35 -> 9
sequences, the rest s076 extractor and B050) and e5/radio-geo-buffer
(packet 79 by radio taken by `EVC_Position` through `EVC_Radio_Info`,
3.6.6.4.1, judged by 4.8.3 with the kept packet of 4.8.5 while level 2
is announced and by the mode column of 4.8.4.2; B001 closed; B002 not
started: its premise was wrong, the balise footnote [2] exists only in
the NTC column, the real case is [1], level 1 information read with
level 1 announced, shape proposed in the subsection).

Verification on the merged master: `test/check.sh` ok (evc_test 11686
checks), the full proof 10884 checks, 0 unproved (margin 47726 steps),
cross build and stack 27120 B (margin 5648), wasm and both smokes 0
failures. SUBSET-076: 706 / 1578 / 906 before, 706 / 1575 / 909 after,
0 regressions, 0 untriaged. Matrix: 413 -> 385 clauses left in all
phases, 218 -> 190 in E1 to E5 (the bookkeeping, mostly).

Measurements (requests, of them without a tool call, duration, final
context, cost): bookkeeping 134 / 51 / 10 min / 120k / 6.6; jru-radio
186 / 62 / 15 min / 139k / 9.9; radio-geo-buffer 186 / 65 / 21 min /
172k / 12.3. A third of every agent's turns carries no tool call
(B021).

Lessons: two of the round's premises were wrong again, both from
reading too little before writing (the JRU record was already written
at reception, only for accepted messages; footnote [2] of 4.8.3 does
not apply to the balise rows outside NTC): a brief's premise about
existing code is to be checked with `outline.py` on the subprogram,
not inferred from a trace. The bookkeeping of a closed phase is cheap
(one agent, 10 minutes) and should follow every phase closure.

Open items: doc/BACKLOG.csv (`python3 test/tools/backlog.py --open`);
the "Open" lists of the subsections above are superseded by it.

### Limited Supervision display, LSSMA (e4/ls-display, 2026-10-11)

Implemented: `EVC_LS_Display` (4.4.19.1.4 to 4.4.19.1.4.7): the generic
LS function marker (packet 181), the toggle orders of packet 180 with
their delay timer (started at the radio time stamp, a, or the first
balise, b), the display state (4.4.19.1.4.3 to .6, 4.10 on a mode
change) and the LSSMA (the lowest MRSP element between the min safe
front end and the EOA/LOA, and the target speed there), sent in
MSG_MODE_LEVEL in km/h in LS only (`EVC_Core.Send_Mode_Level`, the step
after the mode machine in `Tick`). Packets 180 / 181 are taken by
`EVC_Stored_Information` (kinds K180, K181, after the mode profile) with
their 4.8.3 / 4.8.4 rows in `EVC_Acceptance` (`Generic_LS_Marker`,
`LSSMA_Toggle`; the toggle off order narrowed to LS); message 24 with
packet 180 goes to `EVC_Radio_Info`. Decisions: the target speed at an
EOA is 0 and the release speed is not part of the LSSMA; a timer that
has reached the time-out displays; km/h rounded down. evc_test
`EVC_Test_LS.Scenario_LS_Display`. Matrix: 15 of 17 rows done, 4.4.19.1.4.2
c) partial (B091), 4.4.19.1.4.8 todo (B090). SUBSET-076: 0 regressions,
24 improvements; Scb539e7a gone, four new signatures triaged (B092: the
Accepting RBC's toggle order, 4.8.2.1 c exception 2). Left: B090 to B093.
### Authority by radio, fifth round (e5/authority-5, 2026-10-11)

**Implemented.** The MA request at the perturbation location
(3.8.2.2.1 a, 3.13.11.8) had two causes, both outside the authority
half: (1) `EVC_SDM.Perturbation_Of` took every MRSP element from the
first, so an element wholly in rear of the train (a high speed whose
Indication location lies kilometres behind) gave a perturbation
location behind the train, passed at once, and the reason rose at the
first MA and never again (3080200_04: -3064 m); (2) T_MAR = 0 s was
taken as "no parameters" (`Extra.T_MAR > 0`), so 3131100 never
requested. Now an element whose end is at or in rear of the min safe
front end is skipped, `Below_First_Element` (3.13.11.9) compares at
the train in the element holding it (`Element_At`), and
`Supervision_Extra_T.MAR_Known` / `EVC_Radio_Info.MAR_Known` say that
parameters asking for requests are stored (3.8.2.1.3). Scenario:
evc_test `Scenario_SDM_Perturbation_Behind` (fails without the fix).

**Decisions.** The MRSP of 3.13.11 starts at the min safe front end
(3.13.11.9 "the start location of the MRSP"; the earliest request);
the element holding the train keeps its own start, so a location
passed stays passed (3.8.2.2.3; clipping it lost the repetition of
3080200_06).

**Runner.** 706 / 1575 / 909 before, 718 / 1560 / 912 after, 0
regressions, 21 improvements (3080200_04, _05, 3131100_04, _06, _08,
_09, _10 in three versions). S256f4faf 15 -> 3: 3080200_08 is the
reason of 3.8.2.4 (track ahead free up to the level 2 transition, not
implemented, B081). S1531c721: the brief's premise for 3080500_03 was
wrong (no packet 16; BG3d carries in-fill, packet 136 for BG4d: E7);
triage rewritten by family, the other families not traced (B080).
B019 done, B018 updated.

**Edits outside the authority units:** `EVC_SDM`,
`EVC_Supervision_Input` (one component), `EVC_Radio_Info`,
`EVC_Stored_Information` (one line in the snapshot build),
evc_fuzz, evc_test_supervision.
### Balise side of the transition buffer (e5/balise-buffer, 2026-10-11)

**Implemented** (B002, B060): 4.8.3 [1] for balise groups.
`EVC_Acceptance.Level_Stores` / `Stored` is the first filter's third
verdict (levels 0, NTC and 2 with level 1 announced, the rows and
columns carrying [1]; Adhesion and Level Crossing not in level 2, the
TSR rows, packet 79 and the texts only in NTC). `Take_Packet` keeps the
packets so judged, bit for bit, in the private child
`EVC_Stored_Information.Balise_Buffer` (one set per group, three sets,
the oldest replaced, 4.8.5.3; 1 KB and 32 packets per set, package
state); deleted at the start of `Evaluate` when level 1 is no longer
announced (4.8.5.4 a); released by `EVC_Core.Release_Transition_Buffer`
when `EVC_Levels.Switched_To (L1)` (`Release_Balise_Buffer`,
`Take_Balise_Set`: each set judged like a new group in level 1, in the
order received, 4.8.5.5, 4.8.5.6), then the facts of 4.6.3 [25] built
again so that UN or SR goes to FS in the cycle of the transition.
Scenarios `L1_Balise_Buffer`, `L1_Balise_Buffer_Deleted`,
`L1_Balise_Buffer_From_L0` in `EVC_Test_Levels`. B060: the packet 79
kept for level 2 is rejected, so deleted, when no session is
established (`Radio_Geo_Verdict (Session_Up)`, 4.8.5.4 c).

**Decisions.** `Level_Accepts` / `Accepted` still accept the [1] cases:
the units that take a packet themselves keep no buffer and take it at
once as before (linking, packet 5, in `EVC_Position`; reversing, 138 /
139, in `EVC_Procedures`): B070. "Stop if in SR mode" has no [1] (R R A
A): no longer accepted in level 0 with level 1 announced. The third
filter is applied at the release, not at the storing. B060 by "no
session established" rather than by the session of the message
(`EVC_Radio_Info` keeps no session per message; before the transition
the on-board talks to one RBC). The LSSMA hook of 4.4.19.1.4.2 c)
(e4/ls-display): a released balise packet goes only through
`Take_Balise_Set`; packet 180 needs a kind there and in `Level_Stores`
(its row carries [1] in levels 0 and 2).

**Left.** B070.

### E5 integration after the fourteenth round (2026-10-11)

Merged: e4/ls-display (the Limited Supervision display, 4.4.19.1.4:
`EVC_LS_Display` with the toggle order of packet 180, its delay timer
and the LSSMA of a) and b), the marker of packet 181, the value sent in
MSG_MODE_LEVEL, not MSG_SPEED_STATE as the brief said; 15 of 17 rows
done, B090 to B093 left), e5/authority-5 (the MA request at the
perturbation location, 3.8.2.2.1 a / 3.13.11.8: `EVC_SDM.Perturbation_Of`
skipped the MRSP elements behind the min safe front end, and MA request
parameters with T_MAR 0 were read as none, now `MAR_Known`, 3.8.2.1.3;
S256f4faf 15 -> 3 sequences, the rest 3.8.2.4, B081; S1531c721 triaged
by family: 3080500_03 is in-fill by balise, E7, the brief's packet 16
premise was wrong; B080 for the untraced families) and e5/balise-buffer
(the balise side of the transition buffer: `EVC_Acceptance.Level_Stores`
as the first filter's third verdict for 4.8.3 [1], the private child
`EVC_Stored_Information.Balise_Buffer` with three sets of 1 KB, deleted
by 4.8.5.4 a), released at the switch to level 1 through
`Release_Transition_Buffer` and judged like new groups, 4.6.3 [25]
rebuilt in the cycle of the transition; the kept packet 79 deleted when
no session is established, B060; B070 for the units that take a packet
themselves). The merge needed one contract: `EVC_LS_Display.State` in
the Global of the balise release path (a released packet 180 reaches
the LS display, the hook of 4.4.19.1.4.2 c), B091).

Verification on the merged master: `test/check.sh` ok (evc_test 11725
checks), the full proof 11047 checks, 0 unproved (margin 47726 steps),
cross build and stack 27144 B (margin 5624), wasm and both smokes 0
failures. SUBSET-076: 706 / 1575 / 909 before, 724 / 1551 / 915 after,
0 regressions, 0 untriaged. Matrix: 385 -> 366 clauses left in all
phases, 190 -> 173 in E1 to E5; E4 todo 20 -> 4.

Measurements (requests, of them without a tool call, duration, final
context, cost): balise-buffer 281 / 88 / 25 min / 254k / 25.3;
authority-5 181 / 60 / 22 min / 164k / 13.2; ls-display 237 / 78 / 20
min / 190k / 16.4. The two agents that went over their budget did so on
regressions they found themselves (the balise buffer's 15 at the
transition cycle) and on the worktree guard (9 refusals).

Lessons: two premises wrong again, both about data the brief read from
a trace or a triage note rather than from the source (the LSSMA field's
message, the packet of 3080500_03): the rule of round 13 holds for
protocol fields and sequence contents too (read `dmi_protocol.ads`, the
scn's `var` blocks through the runner's mapping). Three branches on the
same two units merge cleanly in git and fail in the proof: a flow
contract union is part of every such merge, checked by the unit proofs
of the touched units before the chain.

Open items: doc/BACKLOG.csv (`python3 test/tools/backlog.py --open`,
37 open after this round).

### Runner, fourth round (e5/runner-4, 2026-10-11)

Three rules in `S076_Run`, no change in `evc/`, `dmi/` or
`S076_Bench`:

- The Main window expected as the first row of a joined test case,
  at standstill, is opened by the runner (area F, `Open_Window`): the
  driver's action the joint of two cases leaves out (B005, decision a;
  3110300_03 step 69 "case 5210200 1", "waits for the driver action",
  then a button of the Main window). 22 of 25 move on to the supervised
  manoeuvre (blocked E5-radio); 3 (4080445_05, 4100103_48, 5210200_03)
  run on at the speed of the case before, the rule does not apply.
- A reach-point at the place of the balise group input before it keeps
  the group's radio messages when the next step expects one
  (`Reach_Point_At_Group`, B003; 5100300_09 step 61, the 136 of the
  L1 -> L0 change at BG2d). An absence after such a reach-point keeps
  its own window (4050200_04 step 88, a regression of the wider form).
- A timer input without a name runs the duration its comment gives,
  "N seconds" / "N s" (`Text_Seconds`, B110; 3080200_04 step 72, "255
  seconds have passed since the MA request"; 84 of 147 in sv30).

Decisions without code: B004 (Sd577e7be) is `s076`: the sequence's
packet 80 (message 3, LRBG BG2d at 400 m, D_MAMODE 500, L_MAMODE 790)
ends the OS area at 1690 m, the joined case's 1190 m is another
geography. B006: the reach-point drive of 3150100_01 already follows
the sequence's chart (4.5 to 14.7 km/h between 800 and 1000 m); step 94
passes on master, the three versions stop at step 102.

SUBSET-076: 724 / 1551 / 915 before, 741 passed, 1534 failed, 915
blocked after, 0 regressions, baseline re-recorded; new signature
Sded37509 (4080100_04 step 124, the LSSMA removed after BG3d) triaged
`onboard` for the LS display. Not done: item 6 (the `~JRU supervision`
windows).
### Trips where Full Supervision is expected (e5/trips-fs, 2026-10-11)

**Implemented.** 3.8.5.2.2, the MA section updated by repositioning
information (packet 16), was not implemented: 3040400_10 kept the EOA of
the group in rear and tripped at 864 m. `EVC_Movement_Authority.Reposition`
sets the end of the section the estimated front end is in (L_SECTION from
the group) and moves what lies beyond it (following sections, end timer
start, danger point, overlap); `EVC_Position.Taken_T.Repositioning` marks
a group met against a link with an unknown identity (3.4.4.4.2.1);
packet 16 is the order kind K16 of `EVC_Stored_Information`, after the MA,
accepted as `EVC_Acceptance.Repositioning` (4.8.3 R R A R, 4.8.4 A in
FS/AD/LS/OS). Scenario evc_test `Scenario_MA_Repositioning`.

**Decisions.** 3.8.5.2.4: a repositioning that shortens deletes nothing.
"Only if" of 3.8.5.2.2 read literally: 4080432_01 links its packet 16
group by identity and expects the update; triaged s076.

**Runner.** 724 / 1551 / 915 before and after, 0 regressions, 3
improvements (3040400_10 in three versions, 49 -> 54, now 3.16.2.4.9,
E6). 9990500_09 is an extraction defect (message 3 truncated);
5160000_01 (B130), 3040400_08, 6060504_07 and B081 left.

**Edits outside the MA units:** `EVC_Acceptance` (one literal, four
lines), `EVC_Stored_Information` (K16), `EVC_Position` (one field).
### Limited Supervision display, second round (e4/ls-display-2, 2026-10-11)

**Implemented.** B091, 4.4.19.1.4.2 c): `EVC_Acceptance.Level_Stores`
keeps packet 180 in levels 0, NTC and 2 with level 1 announced (4.8.3
[1]); `Take_Balise_Set` takes it through `Take_LS_Packet` with the
release time as the start of its timer. B090, 4.4.19.1.4.8:
`Take_MA_Packet` deletes the generic LS function marker when the mode
profile taken has an LS section; a packet 181 of the same group is taken
after the profile and stores it again. B092, 4.8.2.1 c) exception 2:
the authority buffer marks a message held from the Accepting RBC
(`Store_Message (Accepting)`), `EVC_Core` passes
`Released_Accepting` to `Take_Message`, the radio slot carries
`From_Accepting` and `Take_Radio` rejects its packet 180. Scenarios:
evc_test `LS_Order_Buffered`, `LS_Marker_Deleted`, `Handover_LSSMA`.

**Decisions.** The buffer keeps packet 180 whole; a released toggle off
order (R, not R [1], outside level 1) is rejected at the release. The
marker is deleted by a profile taken with its MA ("received", 3.7.1.1).
Only a balise group message deletes the marker (a radio mode profile
does not: the first run regressed 4080300_10 on it); a packet 181 of a
group whose profile goes to the transition buffer goes there too, so the
released profile does not delete it (4080300_08, which counts T_LSSMA
from the transition). A.3.4: the toggle on order is deleted only in situation k (the desk
closed in the start of mission, SB), where 4.10 has deleted it already:
nothing to add. The radio side of 4.4.19.1.4.2 c) does not arise:
message 24 is not kept by the radio transition buffer (B120).

**Left.** B093 (4.8.4.2 [9] [10]: the condition on the LS area of a mode
profile of the same message), B120, B121 (messages 9 and 18 of the
Accepting RBC). Item 5 of the brief not started: S60f37765, S9f4f23d2,
S18160388 and the families 4080300_10, 4080300_17, 4100103_22,
9990400_47 not traced. 4080100_04 stops at step 122 (136 at the rear
end, S13c9beb3, model) before step 124 of B092.
SUBSET-076: 724 / 1551 / 915 before, 733 / 1542 / 915 after, 0
regressions, 12 improvements; Sded37509 (4080100_04 step 124, found by
e5/runner-4) triaged as fixed by B092.
### Braking curve results imported from the SUBSET-076 workbooks (s076/curves-import, 2026-10-11)

The ERA braking curves tool attached to the workbook sequences carries
its results: the sibling repository (branch `curves-import`) now
writes, after a workbook's `cell`/`track` lines, a `curves <sheet>`
block: one `limit <name> <value> <unit>` line per value of the tool's
table 3 (initial speed, the locations of Perturbation, Indication,
Permitted, Warning, SBI, EBI and StartRSM at that speed, release speed;
metres counted from the target), a `curve-columns` header and the
`curve` lines (speed, then EBD, SBD, EBI, SBI1, SBI2, SBI, Warning,
Permitted, Indication, GUI-EOA, EBI for release speed; `-` empty),
sampled at whole km/h where a distance moved by more than 1 m, plus the
rows where a column starts or stops (at most 330 rows, linear between
them to centimetres). The sheet still holding the tool's own example
(a fixed fingerprint per tool version) is left out; 1037 of the 1049
workbooks have results (589 Gamma, 448 Lambda), 760 sequences gain 36
to 1483 lines (median 110), every other file is byte-identical. The
contract is in the sibling's README ("The .scn format").

`S076_Sequences` reads it into `Loaded.Curves` (10 sets of 340 rows,
static; limits by `Limit_Name_T`, curves by `Curve_Column_T`, columns
taken by their header, unknown names and columns skipped),
`Curve_Distance` interpolates, `VERBOSE=1 obj/evc_s076_run <one>`
prints the sets (`Put_Curves`). The runner's judging is unchanged (0
regressions); B101 is its use, B100 the Gamma trains it cannot model.

How the runner should use it for `~[workbook train]` and `~JRU
supervision`: the step's workbook is named in its comment ("According
to ..._06b"); the step's location is where the train passes the named
limit at its speed. First the target: our `tgt0@d` at that location
against the workbook's distance of that limit at our speed (a large
difference is a target or MA placement defect, not a curve one); then
the curves: our `perm=` / `sbi` speeds at distance d against the
workbook's location of the same speed. Three examples (SV30; ours from
the trace line, the workbook's by `Curve_Distance`):

- 3130234_06 step 64, x 1250 m, 06b, Permitted passed at 74 km/h: ours
  d = 147 m (perm 0, intervention), the workbook's Permitted at 74 km/h
  422.5 m: our target 275 m nearer, a target defect, not a curve one;
  at step 63 (d 369 m) our perm 60 / sbi 74 km/h against 06b's 281.9 /
  315.5 m (ours 87 / 54 m further out).
- 3131040_15 step 58, x 1383 m, Permitted left at 52 km/h: ours d 262
  m, the workbook's Permitted at 52 km/h 224.3 m (target +38 m); our
  perm 51 / sbi 63 km/h at 262 m against 217.5 / 235.2 m (ours 44.5 /
  26.8 m further out); the failure itself is the emergency brake of
  step 55 kept to standstill where the sequence expects the service
  brake released below Permitted.
- 3130235_01 step 60, x 915 m, Permitted passed at 55 km/h: ours d 410
  m, the workbook's 335.2 m (target +75 m); our perm 41 / sbi 48 km/h at
  410 m against 213.2 / 217.5 m (about 195 m further out). The sheet has
  no SBD column here and its EBD reaches 0 km/h 3.4 m behind the
  target: the tool's target is supervised on the EBD (an SvL-like
  target), our d is to our target 0 (ma 432 m): the reference points
  must be matched before a difference is read as a curve defect.

The three are Gamma trains (B100): part of every difference is the
train model. Open: B016 (stays open), B100, B101.

### E5 integration after the fifteenth round (2026-10-11)

Merged: e5/runner-4 (the Main window opened by the driver at a joined
test case's first step at standstill, S1f552964 22 of 25 moved on; a
reach-point at the group's place keeps its radio messages for a
positive expectation; an unnamed timer runs the seconds its comment
gives, 147 steps of sv30; Sd577e7be s076; B006 was already so), e5/
trips-fs (3.8.5.2.2, MA repositioning by packet 16 after a link with an
unknown identity: `EVC_Movement_Authority.Reposition`, the real defect
behind 3040400_10 where the triage had named another family; 4080432_01
s076 by the "only if", 9990500_09 an extraction defect; B130 for the
level crossing trip), e4/ls-display-2 (the toggle order released from
the balise buffer starts its timer at the release, 4.4.19.1.4.2 c); the
marker deleted by a balise mode profile with an LS section, .8; a
message held from the Accepting RBC marked through the authority buffer
and its toggle order rejected, 4.8.2.1 c) exception 2; B093 partly,
B120, B121) and s076/curves-import (the ERA workbooks' result sheets in
the sibling as `curves` blocks: `limit` lines of table 3, `curve-columns`
and sampled `curve` lines, the tool's own example sheet recognised and
dropped, 1037 of 1049 workbooks, 760 sequences; `S076_Sequences` reads
them, `Curve_Distance` interpolates; three worked examples show target
placement differences of 38 to 275 m before any curve difference, and
that the runner enters every train with the lambda model while 589
workbooks are Gamma trains, B100; the judging is B101). Four merges in
one round: the two on `EVC_Acceptance` / `EVC_Stored_Information` met
in one `case` arm (K16 from the trips, `From_Balise` from the LS
display), resolved by hand and unit-proved before the chain.

Verification on the merged master: `test/check.sh` ok (evc_test 11762
checks), the full proof 11071 checks, 0 unproved (margin 47726 steps),
cross build and stack 27128 B (margin 5640), wasm and both smokes 0
failures. SUBSET-076: 724 / 1551 / 915 before, 753 / 1522 / 915 after
(6 of the improvements only appear with the branches combined), 0
regressions, 0 untriaged. Matrix: 366 clauses left in all phases before
and after (three rows done, two deferred rows of 4.8.2.1 c) and 4.8.4.2
back to partial as their work started).
The sibling repository: master 4f43136 (the import), 760 sequence files
changed, every other file byte-identical.

Measurements (requests, of them without a tool call, duration, final
context, cost): curves-import 216 / 81 / 28 min / 166k / 13.0; runner-4
143 / 50 / 20 min / 108k / 6.0; ls-display-2 230 / 76 / 25 min / 168k /
13.2; trips-fs 242 / 93 / 23 min / 183k / 15.7. The "no text-only
turns" instruction of the round brief changed nothing: a third of the
turns still carry no tool call (B021).

Lessons: three premises wrong (B006 already done, 4080432_01 not the
same shape, the "empty" result sheet holding the tool's example), two
of them from a stale triage note or an earlier report taken as current:
before a brief, re-run the trace on master, not the note. The runner's
own sequences, read by an agent without a Claude worktree in the
sibling repository, worked: the guard is not needed there.

Open items: doc/BACKLOG.csv (`python3 test/tools/backlog.py --open`,
35 open after this round).

**Correction of the measurements of rounds 12 to 15** (2026-10-12). The
"requests" of those subsections counted the assistant records of the
transcripts, and one API response is recorded as several lines (a
thinking block, then the tool call, the same message id and the same
usage on each). Counted by message id every request but four of 1438
carried a tool call: there were no "turns without a tool call", B021 is
dropped, and the costs were inflated by the repeated usage. The true
figures (requests, cost): round 12 handover-4 130 / 8.6, reports-by-
event-2 83 / 3.8, runner-3 98 / 4.4; round 13 bookkeeping 77 / 3.7,
jru-radio 100 / 5.1, radio-geo-buffer 106 / 6.9; round 14 balise-buffer
143 / 12.4, authority-5 100 / 6.5, ls-display 128 / 8.5; round 15
curves-import 115 / 6.8, runner-4 84 / 3.5, ls-display-2 136 / 7.7,
trips-fs 138 / 9.0. The budgets of 100 to 120 tool calls were met or
exceeded by 10 to 20 percent, as the agents' own counts said. From here
the measurements count distinct message ids and take the usage once per
id.
### Trips where Full Supervision is expected, second round (e5/trips-fs-2, 2026-10-12)

**Traced, none ours.** 5160000_01 step 54 (B130): the speed chart runs
the train at 70.6 km/h from 800 m (the chart's zero is drawn at -1.2,
MRSP 70 as 70.6), above V_LX 70 km/h, so 5.16.3.2 never substitutes
the LX start and the train passes its temporary EOA: `EVC_SDM.
Procedure_Targets` and `EVC_Procedures.LX_Step` are right; triaged
model. Snapping chart speeds within 1 km/h of a multiple of 5 km/h was
tried and reverted (31 improvements, 17 regressions in the braking
curve families): B160. 3040400_08 step 87 and 6060504_07 step 67: the
joined case needs an MA beyond the level 2 transition (1250 m) or
beyond 7650 m that the file does not give (no message 3; 3040400_08
has only the conditional emergency stop 15): extractor, as 9990500_09.
B080 and B130 closed.

**Implemented.** Scenario `Scenario_MA_Request_Perturbation`
(3.8.2.2.3: reason 2 held at standstill and repeated, ended by an MA
moving the EOA away); row 3.8.2.2.3 done. No on-board code changed.

**Left.** B081 (3.8.2.4, packet 90: the design is in its backlog
text), B011, B160. Runner 753 / 1522 / 915 before and after.
### Runner judges with the ERA curves (e5/curves-judge, 2026-10-12)

`S076_Run` (B101): a step whose comment says the train passed (reached,
left, overpasses) a limit with one of its ends sets the reference of
its location: the workbook (named in that comment or an earlier one,
else the only set), the limit (Indication, Permitted, Warning, SBI,
EBI; release speed, RSM, perturbation, EOA and SvL not judged), the
named end's distance to our target (D_Target of MSG_SPEED_STATE, from
the estimated front end for an EOA/SvL), the speed, the permitted and
SBI speeds shown. A failed supervision status (JRU 20), brake or
traction cut-off step (JRU 3/4/43, TIU) at that location is judged:
target first (workbook distance of the limit at our speed, tolerance
10 m plus the larger side of the confidence interval), then the
permitted and SBI curves (our distance against the workbook's band of
the shown speed +-0.5 km/h; 10 m further out allowed, conservative,
2 m nearer, the sampling). A step whose check passed stays passed (the
curves explain a failure, they do not overrule a matched status). A
Gamma sheet's step is not judged and blocks ("Gamma train braking model
(E6)", `R_Gamma`, B100). Signatures name the cause and a band of
metres; the metres are in the trace (`curves:` line).

SUBSET-076: 753 / 1522 / 915 before, 753 / 1429 / 1008 after, 0
regressions, 94 improvements (failed to blocked by Gamma at the same
step, or a later stop). Gamma: 93 sequences blocked, 121 steps. Lambda:
71 sequences stop on a curve signature (198 steps). Unreached (no limit
named at the location; `~[workbook train]`, B140): 129 sequences, 554
steps.

| family | train | target difference | limit | difference |
|---|---|---|---|---|
| curve target nearer | Lambda | 10 to over 300 m (20 seq.) | Permitted | - |
| curve target further | Lambda | 100 to 300 m (5 seq.) | Permitted | - |
| curve target | Lambda | 30 to 300 m nearer/further (8 seq.) | Indication, Warning | - |
| no target shown | Lambda | none shown (17 seq.) | Indication, Warning, EBI | - |
| no workbook value | Lambda | our speed outside the rows (10 seq.) | Permitted, Indication | - |
| curve PERMITTED | Lambda | within | Permitted | over 300 m further out (5 seq.) |
| curve target | Gamma | 10 to 300 m nearer, 30 to 100 m further (35 seq.) | Permitted, SBI, Warning | - |
| no target shown | Gamma | none shown (27 seq.) | Permitted, Indication, Warning | - |
| curve PERMITTED / SBI | Gamma | within | Permitted, SBI | 30 to 300 m further out (9 seq.) |

The three examples re-measured: 3130234_06 step 66 (06b, Permitted at
74 km/h) workbook 423 m, ours 141 m: target -282 m (tolerance 30 m);
3131040_15 step 60, Permitted at 52 km/h, 225 m against 262 m: +37 m
(26 m), perm 51 +41 m, sbi 63 +23 m; 3130235_01 step 62, Permitted at
55 km/h, 336 m against 408 m: +72 m (31 m), perm 43 +196 m, sbi 50
+192 m. All three Gamma: blocked. For B016 the order holds: the target
placement first (most Lambda stops), then the permitted curve.
Fixture: runner_fail step 20 fails on purpose ("curve target: PERMITTED
limit, no target shown", a Lambda sheet in SR); runner_pass step 20 is a
curve step whose check holds (stays passed). A within-tolerance pass
needs an MA, which the hand-written fixture has not. Open: B016, B100,
B140.
### Limited Supervision display, third round (e4/ls-display-3, 2026-10-12)

**Signatures.** S9f4f23d2 (4080300_17 step 88): model; packet 80 puts
the LS area at 450-670 m and the OS area at 720-1020 m (D_MAMODE
incremental, 3.6.3.2.4 a), the sequence wants the max safe front end in
the OS area at 650 m (a confidence interval over 70 m), the bench gives
30 m + 1 %: the train leaves the LS area into no area and goes to FS.
S18160388 (4100103_22 step 125) and S828969ca (4080300_10 step 110):
s076, a symbol status bit of another symbol (Bit36 is LS, Bit27 NL).
S60f37765 removed. 4080100_04 passes; 9990400_47 stops at step 73
(S5436c26d, balise consistency, E6).

**Implemented.** B093, 4.8.4.2 [9] [10]:
`EVC_Stored_Information.LS_Area_Furthest` in `Take_LS_Packet`, over
the mode profiles of the same message (`Msg`). B120, 4.8.3 [2]: the
RBC's toggle on order outside level 2 held in `EVC_LS_Display`
(`Hold_Order`, the packet alone, decision), released by
`EVC_Core.Release_LS_Held` at the switch to level 2 and taken in LS
with its timer from the transition (outside LS rejected: message 24
carries no mode profile, [9]), deleted with the announcement or the
session (4.8.5.4). Scenarios: evc_test `LS_Order_Area`,
`LS_Radio_Held`; `LS_Order_Buffered` carries an LS profile now,
`Handover_LSSMA` takes its last order in LS.

**Left.** B121 (messages 9 and 18 of the Accepting RBC) not started
(budget); the OS acknowledgement part of [10] has no scenario of its
own.

### E5 integration after the sixteenth round (2026-10-12)

Merged: e5/trips-fs-2 (none of the three families ours: 5160000_01 a
runner model gap, the drawn chart speed 70.6 km/h above V_LX 70 where
5.16.3.2 compares exactly, B160; 3040400_08 and 6060504_07 extraction
defects, no message 3 in the file; a scenario for 3.8.2.2.3; B080 and
B130 closed, B081 designed), e5/curves-judge (B101: a failed status or
brake step whose comment names the limit the train passes is judged
against the ERA results, the target placement first with a tolerance of
10 m plus the confidence interval, then the Permitted and SBI curves
within 10 m further out / 2 m nearer at the shown speed ± 0.5 km/h;
Gamma sheets not judged, `R_Gamma`, 93 sequences blocked; 71 Lambda
sequences stop on a curve signature by cause: the target nearer or
further about 33, no target shown 17, our speed outside the rows 10,
the Permitted curve over 300 m further out 5; no Lambda step within
tolerance yet; 129 sequences name no limit, B140) and e4/ls-display-3
(the toggle on order outside LS only with the train in the LS area of a
mode profile of the same message, 4.8.4.2 [9] [10]; the RBC's order
held for the level 2 transition, 4.8.3 [2], released in LS with the
timer at the transition; S9f4f23d2 model, the bench's confidence
interval too small for the sequence's OS area; S18160388 and S828969ca
s076, the symbol bits of the sequences; B121 left).

Verification on the merged master: `test/check.sh` ok (evc_test 11795
checks), the full proof 11091 checks, 0 unproved (margin 47726 steps),
cross build and stack 27128 B (margin 5640), wasm and both smokes 0
failures. SUBSET-076: 753 / 1522 / 915 before, 753 / 1429 / 1008 after
(the 93 Gamma sequences moved from failed to blocked), 0 regressions, 0
untriaged. Matrix: 366 -> 363 clauses left in all phases.

Measurements (requests by message id, duration, final context, cost):
curves-judge 106 / 19 min / 174k / 6.5; ls-display-3 139 / 22 min /
186k / 8.4; trips-fs-2 91 / 13 min / 127k / 4.3.

What the curves say for B016, the on-board side: of the three worked
examples the target sits 282 m nearer (3130234_06), 37 m and 72 m
further (3131040_15, 3130235_01) than the workbook's, before any curve
difference; the Permitted curve runs 41 to 196 m further out. The order
of work is the target placement (the EOA / SvL and the LOA of the
sequences' MAs, 3.8.4, 3.13.1), then the curves (3.13.8, 3.13.9), with
the Lambda sequences as the judge and the Gamma ones waiting for E6.

Open items: doc/BACKLOG.csv (31 open after this round).

### Lambda model: where the difference is (2026-10-12)

The 71 Lambda sequences that stop on a curve signature were taken
apart by hand (3130234, 3130237, 3131040, 3131060; 24 SV21, 24 SV22,
23 SV30) with the runner's `curves:` lines, the workbooks' own rows and
VBA (the inner zips of the sibling, `olevba`), and a probe on
`EVC_Test_Support` that drives a train at a constant speed to a target
and bisects the locations where our supervision status changes (kept
with the briefs, `e5/curve-probe`). The differences are five, in order
of size; none of them is a defect of the on-board's curves so far.

1. **The SV21 and SV22 workbooks were filled with an ERA tool without
   the brake build up time reduction (A.3.12).** Their VBA has no
   `t_be_reduced`; their rows are the plain limits of 3.13.9.3 with
   T_be and T_bs full (3130237_07, freight P 750 m, λ 109: T_be 15.9 s,
   T_bs2 28.5 s, T_indication 26.8 s at every speed). The SV30
   workbooks come from the tool with A.3.12 and CR1344 (223 of 223 in
   the curve families checked): T_bs2 21.7 s and T_indication 21.4 s at
   60 km/h in the same sequence. A 4.0.0 on-board applies the reduction
   (3.13.9.3.2.6, 3.13.9.3.3.3), so against an SV21/SV22 workbook our
   limits sit nearer the target by the reduction itself:

   | 3130237_07, LOA 30 km/h, max safe front end to the LOA | I | P | W | SBI |
   |---|---|---|---|---|
   | SV21 workbook at 60 km/h | 1373 | 926 | 892 | 859 |
   | ours at 60 km/h (probe) | 1113 | 763 | 730 | 697 |
   | SV30 workbook at 61 km/h | 1197 | 833 | 799 | 765 |
   | ours at 61 km/h (probe) | 1144 | 786 | 752 | 718 |
   | ours at 61 km/h with λ 100 | 1169 | 804 | 770 | 737 |

   The EOA case (3131040_04, SvL +450 m, release 30 km/h) against its
   SV21 workbook: ours 40 m nearer at 60 km/h (P 591 against 631, SBI
   524 against 564, estimated front end), the T_bs reduction of an SBD
   target. B170.
2. **The tool's emergency brake percentage is 100 while the train's is
   109, in every workbook of the corpus** (`Brake parameters (lambda)`
   F2 109, F3 100 from a control; A.3.7.1 says λo = λ). Its EBD is the
   conversion model at λ 100 (0.714 m/s² with Kv_int 0.96 and Kr_int
   0.9, the national values of the sequences); the runner enters F2.
   18 m at 61 km/h. Decision B175.
3. **The runner's target check for an LOA or MRSP target reads the
   wrong distance.** `D_Target` of MSG_SPEED_STATE for such a target is
   the reference location of 3.13.9.3.5.9 (the Permitted limit for the
   target speed, with the reduced build up times), 73 m before the LOA
   of 3130237_07; the workbook's distances are to the target. B171.
4. **The runner's Permitted and SBI checks compare the displayed speed
   with the limit column.** The displayed V_Perm follows 3.13.9.3.5.7
   with the time terms at V_est (39 km/h at 836 m before the LOA at 60
   km/h, as the formula gives), the column is the limit location for
   V_est = V_P (55 km/h there); the two agree only at the limit. The
   "ours further out by 200 to 400 m" signatures are this, not a curve
   difference. B172.
5. **The sequences' step locations do not follow from their attached
   workbooks.** 3131040_04 passes the Permitted limit 818 m before the
   EOA in the sequence, 631 m in its workbook at the stated 60 km/h;
   3130237_07 814 m against 926 m, its two comments give the LOA 100 m
   apart; the SV30 files keep the SV21 step locations with recomputed
   workbooks. The sign and size of the "target" family scatter by
   sequence (−475 to +269 m) for this reason. B173.

Also seen: the `brakes`/`jru` lines of a DEBUG trace belong to the
step's search window, not to its location (the SB of 3130237_07 step 58
came 300 m later); the on-board's EBD of an LOA is anchored at V_target
+ dV_ebi like the tool's (3.13.8.3.1); T_bs of a freight P train of 750
m is 23.775 s × kto (A.3.9.2 with L ≤ 900 m), the same in both.

What remains for the on-board: 47 m (λ 109) or 29 m (λ 100) nearer than
the SV30 workbook at 61 km/h in P, SBI and I, to be traced in the
A.3.12 inputs (A_EB, A_SB, A_expected_max, the CR1344 T_traction) with
the probe turned into a tool fed by a sequence's cells (B174). The
runner's B016 work is the three method fixes; the SV21/SV22 workbooks
are no reference for the limit locations of a 4.0.0 on-board.

### Runner judges at its own status changes (e5/curves-method, 2026-10-12)

`S076_Run.Curve_Judgement` (B172, B173): a failed supervision status,
brake or traction cut-off step at a location whose comment names a
limit is judged on the first change of our supervision of the limit's
kind (Indication, Overspeed, Warning, SBI by the SB command, EBI by the
EB command; else a higher status, the limit passed at the latest
there) since the train left the location before: `S076_Bench` keeps
the last 32 changes, cycle by cycle, with the speed, the target speed
and the distances of `EVC_SDM.Result_T.Shown_At` (`Target_X`,
`Target_EOA`, `X_Est`: new, ahead coordinates; B171: D_Target of an LOA or MRSP target counts
to the reference location of 3.13.9.3.5.9). The named end's distance to
the target (to the EOA of an EOA target) against the workbook's column
at our speed there: 10 m further out, 2 m nearer plus the margin of the
tool's emergency brake (λ 100 against the train's 109, A.3.7.1, B175:
`(EBD(V) - EBD(V_target)) * (1 - 0.826 / 0.8935)` from the workbook's
EBD column, 11 m at 61 km/h for 3130237_07; the probe's 18 m includes
the time terms). Within: blocked, `R_Placement` ("the sequence's
location is off its own workbook by N m"); beyond: `onboard` by band;
no change: "no status change of that kind seen" (`model`, B176), split
by whether the named end has passed the workbook's location (then
`onboard`). A Lambda step of an SV21/SV22 sequence without a
`curves-from` line blocks, `R_Old_Tool` (B170); a Gamma one `R_Gamma`.
The displayed-speed comparison and its signatures are gone.

SUBSET-076 with the sibling at 4d40260 (twins copied): 753 / 1429 /
1008 before, 753 / 1415 / 1022 after; blocked by Gamma 93 sequences
(121 steps), old tool 2 (4), placement 12 (12). One regression,
understood: 3131040_38 SV30 now fails at step 53, our Indication 188 m
further out than its workbook (the old method compared the sequence's
location and passed it).

| Lambda SV30 | cause | limit | metres (ours − workbook) |
|---|---|---|---|
| 3130237_07, 3131040_20, _22, _86 | placement (agree) | P | −8, 0, −8, −9; the sequence 20 to 28 m off |
| 3131040_58 | ours nearer | P | −66 at 82 km/h (margin 12) |
| 3131040_14, 3130237_13 | P passed without our change | P | −97 at 71 km/h; −218 at 135 km/h (SB since 1857 m) |
| 3131040_62 | Warning passed without our change | W | 100 to 300 |
| 3131040_02, _38, _50 | ours further out | I | +317, +188, +264 |
| 3131040_26 | ours further out | W | +87 at 81 km/h |
| 3131040_04, _16, _32, _34, _42 (SR), _52, _54, _56, _97, 3131060_14 | no change at the sequence's location | P, I, W, EBI | 04: workbook's location not reached (+123) |
| 3131040_06 | no workbook value at our speed | I | - |

For B016 the order: the Indication of an EOA target (three
sequences, 190 to 320 m further out), then the P nearer / passed
cases (three), then B176 (drive on to our limit) for the rest.

### SV30 workbooks as the reference of their twins (s076/curves-twin, 2026-10-12)

The importer side of B170, in the sibling `../etcs-subset076` (branch
`curves-twin`): a `curves` block of an SV21 or SV22 sequence is replaced
by the same sheet's block of its SV30 twin (same feature and sequence
number; a sequence with workbooks `a`, `b`, ... matched workbook by
workbook), with the line `curves-from <SV30 sequence name>` right after
`curves <sheet>`, where the EBD rows are identical. Rule, on the sampled
rows the importer emits: the same first and last speed with an EBD value
and, at every speed sampled in both blocks, the same EBD within 0.05 m
(both empty the same, one empty not). The speed range condition keeps
out the twins with the same EBD over another initial speed (3131040_13,
_14, _64, _67, _68, _81, _90, 3131030_18, 3131060_02c: their table 3 is
for another speed). Elsewhere the file keeps its own block, without the
line.

| per system version (SV21 and SV22 alike), blocks | Lambda | Gamma |
|---|---|---|
| replaced by the SV30 twin | 136 | 168 |
| kept: EBD rows differ (or another EBD speed range) | 12 | 18 |
| kept: the twin workbook has no block | 0 | 10 |
| kept: the twin has the other sheet | 0 | 1 |

(The plan's 105 of 112 Lambda counted twins with another grouping; the
numbers here are blocks, one per sheet and workbook.) 450 SV21/SV22
files change in their curves blocks only; every SV30 file, `index.csv`
and `testcases.csv` are byte-identical; the importer's `--check` passes;
the README's format section has the rule and the counts, `REPORT.md` the
counts. Against the regenerated sibling, `obj/evc_s076_check` of master
reports 0 failures; `obj/evc_s076_run` of master reads the replaced
blocks as the file's own (the unknown `curves-from` line skipped, e.g.
3130237_07 SV21: "curves 1: ..._SV21.xlsm, Curves Lambda train, 75
rows", the SV30 rows): 753 passed, 1429 failed, 1008 blocked, 0
regressions, 2 improvements (3131040_38 SV21 and SV22, failed at 53 ->
failed at 59, S280f8372). The runner side (the `From_Twin`
flag, a reason of its own for the blocks kept) is e5/curves-method's.

### Accepting RBC messages 9 and 18, track ahead free request (e5/accepting-rbc, 2026-10-12)

**Implemented.** B121, 4.8.2.1 c) exception 2: the request to shorten
the MA (9) and the revocation of an emergency stop (18) of the
Accepting RBC are rejected at the reception by
`EVC_Radio_Authority.Store_Message`, not held; a packet 131 of a
released message 3 / 33 of the Accepting RBC is rejected by
`EVC_Stored_Information.Take_Radio` (the session half already ignores
its radio packet 131, `Take_Radio_Transition`). B081, 3.8.2.4: packet
90 taken from a balise group (`K90`, `Take_TAF_Packet`; acceptance
`EVC_Acceptance.Track_Ahead_Free_L2`: 4.8.3 A [9] in levels 0, NTC and
1 with a level 2 transition order stored, a new `Context_T.L2_Announced`;
the 4.8.4 row, A in PT too); `Evaluate_Request` gives the reason 16 in
any level with level 2 announced and a session established, once
(`TAF_Request`, 3.8.2.4.3); message 132 carries packet 9 after packet
0 (`Send_With_Report`, `LTR`). Scenarios: evc_test
`Handover_Exception_2`, `TAF_Up_To_L2`.

**Decisions.** The brief read B121 as "held and taken at the switch";
4.8.2.1 c) says they "shall be rejected": rejected. At the reception,
not at the release, so that message 9 is answered 138 to the Accepting
RBC at once (3.8.6.1 c, as any request 4.8 rejects). A track ahead
free request not sent before the session is lost is dropped; packet
90 in a radio message is ignored (7.4.2.21, a balise packet). Shared
places: `EVC_Core.Acceptance_Context` fills `L2_Announced`; the runner's
`S076_Run.Radio_Expect.Matches` reads Q_MARQSTREASON as bits (it read
10000 as a decimal).

**Sequences.** 3080200_08 passes in SV21, SV22, SV30. Before 754 / 1430
/ 1009, after 756 / 1426 / 1008 (the run, with the sibling's
`curves-from` blocks of the same day changing six SV21/SV22 signatures
of the 3130237, 3131040, 3131060 families: not re-recorded here). Left
under S256f4faf: 3131100_04 step 86 and _07 step 74, the perturbation
location request at 60 km/h (3.8.2.2.1 a), not traced.

### The curve probe and the residual (e5/curve-probe, 2026-10-12)

The probe of the previous subsection is a tool now (B174):
`obj/evc_curve_probe` (test/src, key=value arguments: train, target
EOA / SvL / release or LOA, gradient, Kv_int / Kr_int / Kt_int,
M_NVEBCL, Q_NVINHSMICPERM, Q_NVGUIPERM, confidence interval, the
odometer's V_ura, speeds) bisects on `EVC_Core` where the status of
MSG_SPEED_STATE reaches Indication, Overspeed, Warning, Intervention and
where the EB comes, from the max safe and the estimated front end, with
V_Perm / V_SBI shown on the Permitted limit. `test/tools/curve_probe.py
<sequence> [set]` feeds it from the workbook's cells, the `track G(‰)`
line and the packet 3 of the sequence and prints ours against the curve
rows with the B175 margin (ours at λ F2 minus ours at the tool's F3)
apart; `--vura 0` is the runner's exact odometer, `--nv 0` the packet 3
that fits, `--with` keys by hand, `--breadth` the table below. Gamma
sheets and accelerating workbook trains (D22, 3 SV30 files) are refused.

**The 29 m is the speed measurement inaccuracy.** With Q_NVINHSMICPERM
0 the ERA tool takes V_delta0 = SUBSET-041's V_ura at V_est (its
Subset_sci control, `S41_speed_inacc`, vba-sv30-tool line 3601; the
empty D8 cell): 2.66 km/h at 61 km/h. The on-board takes V_ura from the
odometer (V_max − V_est, 3.13.9.3.2.1); the runner's bench reports
V_max = V_est. With V_max = V_est + f41 the probe gives, for 3130237_07
SV30 at 61 km/h, λ 100: I 1197 / P 833 / W 799 / SBI 765 / EBI 394 m,
the workbook 1197.4 / 833.0 / 799.1 / 765.2 / 394.4; at λ 109 every
limit is the B175 margin nearer (18 to 38 m by speed) and nothing else:
the rest is within 1 m from 35 to 80 km/h, the Indication included
(T_indication with T_bs_reduced agrees). Kt_int, A_EB / A_safe_max /
A_SB / A_expected_max and CR1344's T_traction need no change. Not a
defect of the on-board; the runner's bench should report the f41
accuracy while the workbook train runs (B191).

**A defect found on the way: the start of the release speed
monitoring.** 3131040_04 SV30 (EOA, SvL +450 m, release 30 km/h): I, P,
W, SBI within 1.4 m, but the EB 236 m before the EOA against the
workbook's 182.6 (its StartRSM). `EVC_SDM.RSM_Start` took the full T_bs
for SBI1 (V_release) and the full T_be / T_bs for SBI2; 3.13.9.4.7
applies "the same formulas", so T_bs1 = T_bs2 = T_bs_reduced
(3.13.9.3.3.3) and T_be reduced (A.3.12), at V_release with the zero
acceleration and f41 of .6 a), b). Fixed with `Reduced_Of` / `Terms_Of`
in advance: 175 m (0.6 m after the margin); 3131050_20 set 3
(calculated release 39.4 km/h) 327 → 267 m against 280.8 (0.8 m).
Scenario SDM_RSM_Start_Reduced, matrix rows 3.13.9.4.6/.7, B190. The
runner: 3131060_18 SV30 passes; 3131050_20 SV21/SV22/SV30, 3131060_10
SV21/SV22 and 3131060_18 SV21/SV22 now enter the RSM later than their
step locations (SV21/SV22: no A.3.12 in their tool, B170; 3131050_20
SV30: its step location, B173), triaged curves; baseline re-recorded:
750 passed, 1433 failed, 1007 blocked.

**Breadth** (`curve_probe.py --breadth --nv 0` over the 116 SV30
files with a Lambda curves block, first set; 107 probed, 2 Gamma and 3
accelerating refused, 4 without a comparable row; ours minus the workbook minus the B175 margin, m,
nearer negative; per-row lines in obj/curve_probe_lines.txt):

| limit | rows | median | nearest | furthest |
|---|---|---|---|---|
| I | 1202 | −0.5 | −565.8 (3131100_02, 90) | +741.5 (3130233_02, 50) |
| P | 1103 | −0.4 | −609.0 (3130237_05, 80) | +671.6 (3130233_02, 50) |
| W | 1199 | −0.4 | −501.2 (3131100_02, 90) | +626.4 (3130237_13, 160) |
| SBI | 1169 | −0.4 | −501.2 (3131100_02, 90) | +626.3 (3130237_13, 160) |
| EBI | 1120 | −0.2 | −648.9 (3131100_04, 90) | +948.0 (3131040_10, 190) |

68 of the 107 sequences agree in every row within 2 m (3774 of 5793
rows). With `--vura 0` (the runner's odometer) the medians are −5.5 to
−7.9 m. The 39 others, by family, not traced yet (B192): the workbook
computed with other integrated correction factors than the sequence's
packets 3 (3130237_15: Kv 0.96 / Kt 1.0 fits to 1 m, the packets give
0.7 / 1.1; likely 3130237_12/13/17, 3131050_06/22/24, 3131040_26); an
EOA with SvL = EOA and a release speed (3131040_20 to _42, nine files:
the RSM start ours further by up to 107 m); an EOA without SvL or
release speed (3130234_07, 3130235_02/04, 3131020_02/04, 3131030_24,
3131040_44/46/48/98, 3131060_14); several sets, gradients or targets
(3130233_02, 3130810_02, 3131050_08, 3131060_02, 3131100_02/04/07,
3130237_05/06, 3131040_10/12).

### E5 integration after the seventeenth round (2026-10-12)

Merged: e5/curves-method (the runner judges a curve step at its own
supervision status change, the first of the limit's kind since the
previous location, against the workbook column at the speed of that
change; the target location from the on-board through
`EVC_SDM.Result_T.Shown_At`, B171; the author's placement blocked as
`R_Placement` when our change agrees with the workbook, B173; an
SV21/SV22 block without a twin blocked as `R_Old_Tool`, B170; the
lambda margin of B175 from the workbook's EBD column; the
displayed-speed comparison dropped, B172; B176 for the steps our limit
has not reached), s076/curves-twin (the sibling's importer writes the
SV30 twin's block into an SV21/SV22 file where the EBD rows are
identical in range and values, with a `curves-from` line: 608 blocks,
450 files; sibling master 4d40260), e5/curve-probe (`obj/evc_curve_probe`
and `test/tools/curve_probe.py`, B174; the 29 m residual is the
SUBSET-041 speed accuracy the workbook applies and the bench's odometer
does not report, B191; the start of the release speed monitoring now
uses the reduced build up times, 3.13.9.4.6, .7, B190; 68 of 107 Lambda
SV30 workbooks agree with the on-board within 2 m in every row, the 39
outside by family in B192, one of them a SUBSET-076 inconsistency: a
workbook computed with other correction factors than its own packet 3)
and e5/accepting-rbc (messages 9 and 18 of the Accepting RBC rejected at
reception with 138 answered to message 9, 4.8.2.1 c) exception 2, B121;
packet 90 taken as K90, the track ahead free MA request reason 16 in any
level with level 2 announced and packet 9 in message 132, 3.8.2.4.1 to
.3, B081; the runner reads Q_MARQSTREASON as a bit pattern; 3080200_08
passes in the three system versions).

Merge by hand: the B170 line (both agents appended to it: combined), the
plan subsections (all appended at the end), the baseline (the runner
branch's lines kept, the merged run then matched them exactly), the
backlog ids by id with the done state winning.

Verification on the merged master: `test/check.sh` ok (evc_test 11825
checks), the full proof 11140 checks, 0 unproved (margin 47726 steps),
cross build and stack 27128 B (margin 5640), wasm and both smokes 0
failures. SUBSET-076: 753 / 1429 / 1008 before, 753 / 1416 / 1021 after
(blocked: Gamma 93, placement 12, old tool 2), 0 regressions, 0
untriaged. Matrix: 363 -> 359 clauses left in all phases (4.8.2.1 c)
done, 3.8.2.4.1 to .3 done).

Measurements (requests by message id, duration, final context, cost):
curves-method 118 / 22 min / 185k / 7.8; curves-twin 46 / 7 min / 83k /
1.8; curve-probe 131 / 23 min / 216k / 10.1; accepting-rbc 152 / 22 min
/ 209k / 11.1 (over its budget of 120 calls by 48; its "Done" list was
complete).

Lessons: a backlog line can describe the defect rather than the
requirement (B121 said "held and taken at the switch instead of
rejected" and the brief copied it; the clause says rejected; the agent
checked the clause first and implemented it); a probe that reproduces
the reference to the metre is worth more than a tolerance (the 29 m fell
to the odometer's V_ura in one afternoon, and a real defect of the
release speed monitoring came out with it).

Next for the curves: B191 (the bench's V_ura), B176 (driving on to our
limit), B192 by family (the release speed monitoring start with SvL at
the EOA, the EOA without SvL or release speed, the several-set
workbooks), then the Gamma model with E6. Open items: doc/BACKLOG.csv
(32 open after this round).

### Lambda workbooks by family (e5/curves-families, 2026-10-12)

The 39 Lambda SV30 workbooks of B192 traced with `curve_probe.py`; no
defect of the on-board. Ours minus the workbook minus the B175 margin,
the worst row of the file, m:

| family | sequences | outcome | before | after |
|---|---|---|---|---|
| EOA, SvL = EOA, release speed | 3131040_20 to _42 (9) | the tool's target type LoA/MRSP at 0 km/h, not EoA/SvL | −107 (I) | refused |
| EOA without SvL or release | 3131040_44/46/48, 3130235_02/04 | the same | −97 | refused |
| | 3131020_02/04 | probe: Q_NVSBTSMPERM 0 of packet 3 not fed | +140 | ≤ 2 |
| | 3131030_24, 3131040_98 | probe: the cells of the file's last workbook | | ≤ 2 |
| | 3130234_07 | correction factors (family 4) | +139 | ≤ 2 with 0.96 / 1.0 |
| | 3131060_14 | high-speed residual | +3.7 | +3.7 |
| several sets, gradients, targets | 3130233_02, 3131050_08, 3131060_02, 3131100_02/04/07 | probe: the cells of the file's last workbook | −649 to +948 | ≤ 2 (3130233_02 set 3: 2.5) |
| | 3130810_02 | probe: the reduced adhesion area not fed | −74 | +10 at 45–60 km/h, B201 |
| | 3130237_05 sets 2, 3 | an EB model of 0.41 / 0.64 m/s² from a control that is no cell | −121 / +110 | B201 |
| | 3130237_06, 3131040_10 | correction factors (family 4) | −50 / +948 | ≤ 2 / +3.5 |
| | 3131040_12 | high-speed residual | +3.5 | +3.5 |
| other correction factors | 3130237_04 (set 2), _12, _13, _15, _17, 3131050_05 (sets 7–9), _06, _22, _24 | Kv_int 0.96, Kr_int 1.0 / 0.9, Kt_int 1.0 where the packets give 0.7 / 0.9 / 1.1 | +92 to +627 | ≤ 2 with them |

**The EOA workbooks with SvL = EOA** have no SBD and no SBI1 column, the
EBD reaches 0 m at 7.5 km/h (dV_ebi(0) above an LoA of 0 km/h) and
(SBI2 − EBI) / V is 23.775 s at every speed, the full T_bs of a freight
P train of 750 m: the workbook was made with the target type
"LoA/MRSP", target speed 0. The tool then never reduces T_bs
(vba-sv30-tool line 3684: `LoA_MRSP And V_t2bs >= V_target`, true for
V_target 0), computes no SBI1 (3790, only `EoA_SvL`) and no release
speed (3752). The sequence sends packet 12 with Q_DANGERPOINT 0 and
Q_OVERLAP 0: an EOA whose SvL is the EOA, for which A.3.12.4.5 reduces
T_bs below V_t2bs = 0 (ours: up to 52 m nearer below 65 km/h, the same
above) and 3.13.9.4 supervises the release speed. Our reading is the
tool's own for an EoA/SvL (3131040_04, SvL +450 m, within 1.4 m). The
probe refuses these workbooks now; the runner's judging is B200.

**Other correction factors** (12 files, 21 blocks): with
`--with "kv=0:0.96 kr=0:1.00,250:0.90 kt=1.00"` every row is within
2 m (3131040_10: 3.5 m at 180 km/h); the sequences send packet 3 with
Q_NVKINT 0 or none (A.3.2: 0.7, 0.9, 1.1). A SUBSET-076 inconsistency,
B200.

**The probe's gaps**, fixed: a file with several workbooks
(3131030_24a, _24b) gave the first curves block the cells and gradient
of the last; `--breadth` probed the first block only (now every block,
`name/2`); Q_NVSBTSMPERM (key `sbtsm`) and the workbook's reduced
adhesion area with its A_max (keys `adhesion`, `redadh`) were not fed.

After: 101 of 129 curves blocks of 99 files within 2 m in every row
(5280 of 6371 rows); 15 refused as LoA/MRSP workbooks, 7 Gamma, 4
accelerating. Left (B201): 3130237_05 sets 2 and 3, 3130810_02 at 45 to
60 km/h, 2 to 3.7 m further out at 160 to 185 km/h in four files. The
on-board is unchanged: no unit proof, no runner baseline change.

### The bench's speed accuracy and driving on (e5/curves-bench, 2026-10-12)

B191: `S076_Bench.Sample` states v_min = v_est − f41 and v_max = v_est +
f41 (SUBSET-041 5.3.1.2, the bench's own copy of the formula) while the
sequence has a `workbook` line (`Set_Speed_Accuracy`, set per sequence
by `S076_Run`); the other sequences keep the exact speed (decision:
3110500_01 and 3131040_59, without a workbook, place an Indication and
an Overspeed step on it), and `S076_EXACT_SPEED=1` restores it for all.
The 28 m of 3130237_07 do not show in the runner: its P step is passed
by an Intervention where the probe's P lies, the Overspeed status
skipped (B195, present with the exact speed too; for EVC_SDM).

B176: `S076_Run.Drive_On` runs the train on, for real (the sequence has
failed at the step), at its speed until our change of the limit's kind
or 10 m past the workbook's location, at most the workbook's distance
plus 10 m, then judges as before; ", driven on" and a band in the
signature, the metres in the trace; without a target of ours shown
after the drive, "no target of ours shown" (B193). None of the 13
agrees after the drive (table).

SUBSET-076: 753 / 1416 / 1021 before, 745 / 1423 / 1022 after; 24
regressions (8 per system version), understood and re-recorded: Gamma
3131040_07, _17, _89 (E6; passed by chance without V_ura), 3131040_10
and _98 (B192 families, several sets and an EOA without SvL),
3131040_76 (the SB of B195, 54 m before the workbook's W, now judged at
its step), 3130237_01 (a trip after the EB, the bench keeps the chart's
70 km/h), 3130235_02 (placement one step earlier). Improved: 3131040_14
SV30 passes, 3130234_07 and 3131060_08 SV21/SV22 pass, 3131040_58 runs
to step 69. Untriaged 0.

| Lambda SV30 (24) | cause | limit | metres (ours − workbook) |
|---|---|---|---|
| 3130237_07, 3131040_20, _22, _86, 3130235_02 | placement (agree) | P | −8, 0, −8, −9, −27 (margin 27) |
| 3131040_02, _38, _50 | ours further out | I | +317, +188, +342 |
| 3131040_26, _76 | ours further out (the SB of B195) | W | +87 at 81 km/h, +54 at 38 km/h |
| 3131040_58 | ours nearer | P | −25 at 82 km/h (margin 12) |
| 3130237_13, 3131040_62 | passed without our change | P, W | −218 at 135 km/h, −181 at 97 km/h |
| 3131040_04 | passed +10 m without Overspeed (driven 133 m) | P | −10, no margin known (B194) |
| 3131040_32 | our target further than the sequence's (driven to the cap) | W | +487 |
| 3131040_42, _52, _54, _56 | no target of ours (SR; FS with the EOA 7.7 km ahead) | I, EBI | B193 |
| 3131040_06, _16, _34, 3131060_14 | our speed outside the workbook rows | I, P | 81 to 88, 200 km/h |
| 3131040_97 | at a standstill | P | - |

Next: B195 (the Overspeed status skipped in target speed monitoring),
the Indication of an EOA target (+188 to +342 m), B193, B194.

### E4 closure, second round (e4/closure-2, 2026-10-12)

**B030** (3.6.8.5, 3.6.8.6.2 done): "Odometer impaired" (DMI entry 36)
started and ended with `EVC_Odometry.Impaired` in
`EVC_Core.Show_Mode_Indications`, in the modes of the check of odometer
accuracy thresholds only (4.5.2 Table: SM, FS, AD, LS, SR, OS; SUBSET-076
4050200_10 and _11 expect it hidden in UN and SB). The check itself still
runs in every mode (B222). **B033** (3.7.3.1 done): `EVC_Linking.Replace`,
called from `EVC_Position.Take_Packets` in place of the plain assignment,
keeps the stored chain up to the new reference group when that group is a
link of it (same sense); the joined chain beyond `Max_Links` falls back to
the new linking alone (decision). **B035** (3.14.1.5 stays partial for
the SR data entry, B015): reason `Data_Entry_Movement` of
`EVC_Brake_Commands` (3.18.3.3.1), from `EVC_Mission.Modifying_Train_Data`
(DMI action 21 after the start of mission, in FS AD LS SR OS UN SN, until
the Train Data are entered, action 16, the end of mission or another
mode); emergency brake released at standstill after the acknowledgement,
revoked in NP SB SH (4.12.1.2) and IS; TIU reason "procedure". The DMI
does not report a Train Data window left by its close button (B220,
protocol: the brake then comes on the next movement, the safe side).
**B039**: 3.14.1.7.6 is the safe consist length of Supervised Manoeuvre,
deferred with 4.4.21.1.12 `[E5 authority]`; 3.14.3.6 todo (B221: gate the
balise information during an unauthorised direction movement in
`EVC_Core`); 3.12.2.4 todo (B034 open; the rows of 3.12.2.3 still defer
to "E4" as well). Scenarios: `Scenario_Odometer_Accuracy` (3 checks),
`Scenario_Linking_Replacement`, `Scenario_Train_Data_Movement`.

### Level transition buffer for the units' own packets, message 138, level symbols (e5/onboard-gaps, 2026-10-12)

**Implemented.** B070, 4.8.3 [1] for the packets a unit takes itself:
the linking (packet 5, `EVC_Position`) and the reversing area and
supervision (138, 139, `EVC_Procedures`) of a group read in level 0 or
2 with level 1 announced are kept in the group's set of the balise
transition buffer (`EVC_Stored_Information.Keep_Unit_Packets`, the set
now carries the group identity), not taken at once (`EVC_Core.Update_Position`
and `EVC_Procedures.Take_Packets`: accepted and not `Stored`), handed
over at the transition to level 1 by `EVC_Core.Release_Unit_Packets`
(through the stores' `Balise_Set_*` accessors, before
`Release_Balise_Buffer` deletes the sets) to
`EVC_Position.Take_Released_Linking` (it replaces the RBC's linking
then, not before) and `EVC_Procedures.Take_Released`; deleted with the
stores' packets (4.8.5.4 a). Scenario `L1_Balise_Buffer_Units`
(`EVC_Test_Levels`). B011, 3.8.6.1 c): the RBC is informed of the
decision of b) only (137, or 138 for a front end beyond the indication
limit of the proposal); a message 9 rejected before it (4.8, 4.8.2.1 c)
exception 2, 3.10.2.4) is not answered (`Judge_Shortening`).

**Decisions.** The released linking is taken only when the SOLR is its
group or a group it announces (the reference of its windows); the
windows passed are skipped as at a passage. B011 reverses the decision
"138 also when 4.8 rejects" (e5/levels, e5/accepting-rbc): 4080407_01
expects no answer in four rejections ([3], 3.10.2.4, coverage, SR);
4080421_01 / _03 expect 138 for a message 9 rejected in SH, against the
same row of 4.8.4 (R in SH and SR); they already failed there and stay.
Three scenarios of `EVC_Test_Authority` / `_Handover` changed with it.

**SUBSET-076.** 753 / 1416 / 1021 before and after; 4080407_01 SV21,
SV22, SV30 90 -> 113 (Sa9695ede), 0 regressions. S44acb613 carried by
no sequence; Sb83b2c65 is reached again (4080428_01 step 134, B211).

**Left.** B210 (the proposal's own SSP and gradient not covering it),
B211, B212 (a linking in the group carrying the level 1 order itself is
taken at once: `EVC_Position.Update` runs before the order is
evaluated), B017 (Sa03cccdc, the level symbol families: not reached).
Edits outside the brief's units: `EVC_Stored_Information` (and its
child `Balise_Buffer`), `EVC_Core` (`Release_Unit_Packets`, the linking
context of `Update_Position`, the Global of `Release_Transition_Buffer`).
`EVC_Position`: only the new `Take_Released_Linking` (spec and body).

### E5 integration after the eighteenth round (2026-10-12)

Merged: e5/curves-families (the 39 Lambda workbooks outside 2 m traced
with the probe, none a defect of our curves: 15 made with the tool's
"LoA/MRSP" target at 0 km/h instead of "EoA/SvL", so without a release
speed monitoring, 21 blocks computed with other integrated correction
factors than their own packet 3, both SUBSET-076 inconsistencies for the
runner to block or judge, B200; two probe defects fixed, the adhesion
inputs added; 101 of 129 blocks agree within 2 m in every row; the
remainder B201), e5/curves-bench (the bench reports the SUBSET-041 speed
accuracy while a workbook sequence runs, B191, `S076_EXACT_SPEED=1`
restores the exact speed; a curve step our limit has not reached drives
on at the step's speed until our change, B176; 24 understood regressions
re-recorded: Gamma passes by chance, B192 families, B195; found B195:
the on-board goes from Indication to Intervention without the Overspeed
status in 3130237_07 and five others, the displayed Permitted speed
dropping 28 km/h in one cycle), e5/onboard-gaps (packets 5, 138 and 139
read with level 1 announced kept in the balise transition buffer and
released at the transition, 4.8.3 [1], B070; a message 9 rejected before
the decision of 3.8.6.1 b) gets no 137/138, B011, reversing the decision
of e5/levels and e5/accepting-rbc; 4080407_01 moves from step 90 to 113;
B210 to B212; B017 not started) and e4/closure-2 (the Odometer impaired
text in the modes of Table 4.5.2, 3.6.8.5, B030; new linking keeps the
stored chain in rear of its reference group, 3.7.3.1 m), B033; the brake
reason of a movement while the driver modifies Train Data, 3.14.1.5,
B035; the three rows deferred to E4 given their outcome, B039:
3.14.1.7.6 is the safe consist length and goes with E5 authority,
3.14.3.6 todo as B221, 3.12.2.4 todo as B034; 4050200_11 regressed
knowingly, the odometer check should run only in the Table 4.5.2 modes,
B222).

Merge by hand: the backlog ids by id with the done state winning; the
B016 line's two appended tails combined (a common-prefix join cut the
shared words "Round 18 (e5/curves-": restored in a commit of its own;
join by sentence next time); the plan subsections appended; the
baseline auto-merged and matched by the run.

Verification on the merged master: `test/check.sh` ok (evc_test 11840
checks), the full proof 11221 checks, 0 unproved (margin 47726 steps),
cross build and stack 27136 B (margin 5632), wasm and both smokes 0
failures. SUBSET-076: 753 / 1416 / 1021 before, 742 / 1426 / 1022 after
(the speed accuracy took three Gamma passes by chance and the B192
families; 4050200_11 by B222), 0 regressions against the merged
baseline, 0 untriaged. Matrix: 359 -> 358 clauses left in all phases
(E3 has two todo rows again, 3.12.2.4 and 3.14.3.6, honestly).

Measurements (requests by message id, duration, final context, cost):
curves-bench 101 / 23 min / 171k / 6.1; curves-families 104 / 21 min /
189k / 6.9; onboard-gaps 160 / 33 min / 206k / 11.5 (over its budget of
130 by 15, two proof fixes in `EVC_Core`); closure-2 136 / 24 min /
187k / 9.2 (over 120 by 5).

The curves after this round: the on-board's limits reproduce the ERA
tool's to the metre wherever the workbook's inputs are the sequence's;
what the runner still fails on the curve sequences is B195 (ours), the
Indication of an EOA target 190 to 340 m further out (3131040_02, _38,
_50; ours), and runner or data items (B193, B194, B200, B201). Open
items: doc/BACKLOG.csv (35 open after this round).

### The Overspeed status and the Indication of an EOA (e5/curves-sdm, 2026-10-12)

**B195 is the runner's last cycle, not our curves.** Traced cycle by
cycle (3130237_07 SV30, a temporary print in the bench, not kept): at
1512 m the bench reports 4.7 m/s for one cycle, the train at 16.9 m/s
before and after: `S076_Run.Drive_To` (and `S076_Bench.Move_To`) end
on the location by running the last cycle at the distance left per
cycle. The on-board's measured acceleration (`EVC_SDM.Observe_Train`,
a 1 s filter of the speed's derivative, clamped at ±60 m/s²) goes to
−6 m/s², then rebounds to +0.6 m/s² when the speed returns; A_est2 =
0.4 m/s² over T_berem (about 20 s for this freight train) adds 8 m/s to
V_bec (3.13.9.3.2.9, .10), so every limit of the LOA moves out by the
same: the shown P drops 62 → 35 km/h, the train is past the SBI at once
(Intervention, SB), and the pawl of A.3.13 keeps the shown values down
while the build up time stays reduced. The reaction follows the
clauses for an acceleration measured at 0.6 m/s²; the input is not
physical (12 m/s² both ways). Decision: no change of the estimator;
the runner keeps the speed (B224). The probe reproduces it:
`obj/evc_curve_probe ... drive=900 dip=818:17` (new keys: `drive=<m>`
a continuous run with the state carried, one line per change;
`dip=<m>:<km/h>` one cycle's speed); without the dip the statuses come
one at a time at 1172 / 814 / 780 / 746 m (the bisection's I / P / W /
SBI within 1 m). Scenario `SDM_Status_Order` (3.13.10.4.10.1: I, P, W,
SBI of an LOA in order at 61 km/h, the shown P meeting the train's speed
at P; the dip's Intervention). A trial with the speed held in that
cycle (overshooting the location): 3130237_07, 3131040_22, _86 pass,
_20 and _76 move on; 3131040_26 is the same and a LoA/MRSP workbook
(B200).

**The Indication of an EOA (+188 to +342 m)** is no curve difference
either. 3131040_38 and _50 send V_RELEASEDP 30, 150 km/h, where their
workbook (Track!E2) has 30 km/h (3131040_04 sends 6; 3131040_37 the
same defect): limited to the MRSP of 80 km/h (3.13.9.4.9) the release
speed monitoring starts 1111 m before the EOA at 50 km/h, where the
workbook's train is in target speed monitoring (B225). 3131040_02 runs
at 86.6 km/h, above the ceiling's SBI (the runner's speed for
"overpasses the warning speed"), and is judged on the workbook row at
65 km/h; the sequence itself states the Indication 1427 m before the
EOA, ours is 1427 m (B226). The probe agrees with the workbooks of _02
and _50 within 1.4 m after the B175 margin.

Triage: Sc980dfa5 (_02, _50) model, Scc92cf5f (_38) s076, S39f273d3
(_26, _76) model, specific lines before the families. The on-board is
unchanged: no unit proof, no baseline change. Backlog: B195 done,
B224 to B226 opened, B016 updated.

### Odometer check by mode, the Train Data brake text, level symbols (e4/odometer-levels, 2026-10-12)

**B222** (3.6.8.5, 3.6.8.7, 4.5.2 Table): the check of the odometer
accuracy thresholds and its reactions (impaired, System Failure, the JRU
record) run in SM, FS, AD, LS, SR and OS only: `EVC_Odometry.Set_Check`,
called by `EVC_Position.Update` each cycle with
`EVC_Modes.Odometer_Check_Mode`; `Close_Interval` checks only while
active; out of those modes the impairment is not considered (4.5.2.1;
a safety threshold once exceeded stays, the mode is SF). **Decision**:
the window continues, it does not restart: the accumulation of 3.6.8.1
and 3.6.8.2 is not in the table's row, and the first check after the
entry (at the end of the interval open then, at most 100 m) judges the
amounts of the total distance (SUBSET-076 4050200_10: impaired in FS
at the first interval after UN; 4050200_11, SR after SB, passes as
well). **B223** (3.18.3.3.1): the DMI specification's table of system
status messages starts "Runaway movement" (entry 9) by 3.18.3.3.1 too,
ended by 3.14.1.5: `EVC_Core.Show_Mode_Indications` shows it while the
reason `Data_Entry_Movement` is commanded. Scenarios:
`Scenario_Odometer_Check_By_Mode` (`EVC_Test_Position`),
`Scenario_Train_Data_Movement` extended (`EVC_Test_Modes`). Matrix:
3.18.3.3.1 todo -> done; 3.6.8.5, 3.6.8.6.2, 3.6.8.7 notes.

**B017** traced in part: the families expect Level 2 after an immediate
order to level 2 by balise that the on-board does not carry out (the
backlog's "level unchanged" was the symptom). 6060504/6060505 are s076
data like 4080455 (the linking announces NID_BG 2 where BG1 carries the
order, 3.4.4.4.3.2); 5220200_03 and 9990500_24 (a single balise group in
SR, level 1) are B240, cause not found; 3070300_12/13, 4080425_04,
4080100_06, 4100103_15 not traced.

**SUBSET-076**: 742 / 1426 / 1022 before, 751 / 1417 / 1022 after
(4050200_10, _11, 4120100_03 pass in SV21, SV22, SV30), 0 regressions.
Edits outside the units: `EVC_Position.Update` (the call of
`Set_Check`, one statement); `EVC_Core.Show_Mode_Indications` only.

### Acceptance gates: the order's own group, the unauthorised direction; the second report; the proposal's coverage (e5/acceptance-gates, 2026-10-12)

**Implemented.** B212, 4.8.3 [1]: a linking read in the group that itself
carries the order to level 1 at a further location is no longer taken at
the passage. `EVC_Core.Update_Position` passes `Defer_On_Order` to
`EVC_Position.Set_Linking_Context` (the verdict `Stored` of 4.8 with level
1 announced, `Ordered_Context`); `EVC_Position.Take_Packets` holds the
linking of a group with a packet 41 valid for its direction; the new
`EVC_Core.Take_Held_Linking`, called in `Tick` right after
`Evaluate_Stored_Information`, judges it again once the stores evaluated
the order (accepted and not stored: taken through
`EVC_Position.Take_Held_Linking`, the old `Take_Packets` tail now
`Commit_Linking`; else dropped, the stores' `Keep_Unit_Packets` having
kept it). Scenario `L1_Order_Own_Group_Linking` (`EVC_Test_Levels`).

**Decision.** The position waits for the stores' evaluation (a second
verdict in the same cycle) rather than reading packet 41 itself: the
order, its level priorities and its location are judged in one place.

**SUBSET-076.** 742 / 1426 / 1022 before and after, 0 regressions.

**Left.** B221 (3.14.3.6): the gate was written (an `Ignore_Info`
setting of `EVC_Position` skipping `Take_Packets` and `Record_Taken`, fed
by `Brake_State.Direction`), but no scenario discriminated it within the
budget, so it was not committed (B221 says why). B211 analysed, not fixed
(the trigger of the second 136 to trace). B210 not started. Found B250
(an evc_test isolation defect). Edits outside the units of the package:
none; in `EVC_Core`: `Update_Position` (the new argument), the new
`Ordered_Context` and `Take_Held_Linking`, one call in `Tick`.

### Runner: the workbooks that are no reference, the margin, the unreached steps (e5/curves-runner-2, 2026-10-12)

B200: `S076_Run.No_Reference` says why the curve steps of a set are not
judged, for a step naming its limit and now also for one naming none
(the set named last or the only one): Gamma (B100), old tool (B170),
and two new reasons, both SUBSET-076 inconsistencies. `R_Tool_Target`:
the tool's target type LoA/MRSP at 0 km/h for an EOA, recognised from
the block as the probe does (Track!B2 0, no SBD or SBI1 value, the EBD
0 m above 0 km/h): exactly the 15 SV30 files of B200. `R_Factors`: the
workbook's Kv_int x Kr_int is none the sequence gives. Decision: the
workbook's factors are not in the sequence file (the sheet "Integrated
correction factors" is not extracted, B230), so the runner reads the
product from the EBD's deceleration on a flat profile (20 to 50 km/h,
over AD_0 of Brake parameters (lambda)!F3) and compares it, within
0.03, with the set in force on the on-board, every packet 3 of the file
(`S076_Sequences` reads them, bounded, static) and the A.3.2 defaults
without one; Kt_int is not compared. 3130237_06 is judged (the workbook
has its first packet's factors; the defaults of BG3d are in force).

B194: without an EBD value at the speed the margin is the conversion
model's EBD distance at the tool's percentage times 1 - AD_0(100) /
AD_0(109); the drive on goes past the workbook's location by the margin
and a location passed within it agrees. 3131040_04 still fails: our
Overspeed 27 m nearer than its workbook against a margin of 15 m (the
613 m of B194 was the end of the drive); the probe's margin is larger
(V_bec, B231).

B193: _42 is blocked by `R_Tool_Target`; _52, _54, _56 (and _32) are
workbooks of their first packet 3 while the on-board holds the defaults
at the step: right after BG0d of another country in _54, unexplained in
_56 (B232, on-board).

SUBSET-076: 742 / 1426 / 1022 before, 742 / 1339 / 1109 after, 0
regressions; 87 failed -> blocked (64 Gamma, 15 tool target, 6 factors,
2 old tool), 7 placement -> tool target. B224 (the last cycle at the
speed) was tried: the B195 cases pass, but 83 regressions: reverted.
B140 not reached.

### E5 integration after the nineteenth round (2026-10-12)

Merged: e5/curves-sdm (neither on-board curve finding is ours: the
Overspeed status is skipped because the runner's last cycle before a
location runs at the leftover distance per cycle, a one-cycle speed dip
that swings the acceleration estimator and moves every limit out by
A_est2 over T_berem, 3.13.9.3.2.9, B195 done, B224 runner; the Indication
of an EOA 190 to 340 m further out is V_RELEASEDP 30 = 150 km/h in the
telegrams of 3131040_37, _38 and _50 against 30 km/h in their workbooks,
B225, and a chart speed above the ceiling's SBI in 3131040_02, B226; the
probe gained `drive=` and `dip=`; scenario SDM_Status_Order drives the
four statuses in order and reproduces the dip), e5/curves-runner-2 (the
workbooks that are no reference blocked by rules read from the block:
`R_Tool_Target`, target speed 0 with no SBD or SBI1 and the EBD at 0 m
above 0 km/h, and `R_Factors`, the workbook's Kv x Kr read from its EBD
deceleration against the sequence's packets 3 and the A.3.2 defaults,
B200; the steps naming no limit blocked with their set; the margin
without an EBD value from the conversion model, B194, 3131040_04 left as
B231; B193 traced, B232 for the national values at their defaults in
3131040_56; the brief's premise wrong: the workbook's factors are not in
the sequence files, B230 for the sibling; B224 tried and reverted after
83 regressions against 50 improvements, the patch kept with the briefs;
B140 not reached), e4/odometer-levels (the odometer accuracy check only
in the modes of the 4.5.2 Table, the distance window continuing on entry,
3.6.8.5 to 3.6.8.7, B222, 4050200_10 and _11 pass; Runaway movement
shown while the Train Data brake is commanded, 3.18.3.3.1, B223,
4120100_03 passes; B017 in part: 6060504/5 are linking data of
SUBSET-076 like 4080455, 5220200_03 and 9990500_24 an order by a single
group in SR not carried out, B240, five families left) and
e5/acceptance-gates (a linking read in the very group that orders level 1
at a further location is held until the stores have evaluated the order
and then kept in the buffer only, 4.8.3 [1], B212; B221 written as a
gate in `EVC_Position` but no scenario could tell it on from off, the
patch kept with the briefs; B211 analysed, two candidate triggers; B210
not started; B250 harness: state surviving `EVC_Core.Initialise` in a
position scenario).

Merge by hand: the backlog three-way by id with a tool
(`briefs/merge_backlog.py`: one side changed wins, both changed the done
state wins and the other's tail is joined at a sentence boundary); the
plan subsections appended; the baselines auto-merged and matched by the
run.

Verification on the merged master: `test/check.sh` ok (evc_test 11853
checks), the full proof 11237 checks, 0 unproved (margin 47726 steps),
cross build and stack 27136 B (margin 5632), wasm and both smokes 0
failures. SUBSET-076: 742 / 1426 / 1022 before, 751 / 1330 / 1109 after
(blocked by reason: Gamma 160, tool target 22, factors 6, placement 6,
old tool 4), 0 regressions, 0 untriaged. Matrix: 358 -> 357 clauses
left in all phases.

Measurements (requests by message id, duration, final context, cost):
curves-sdm 108 / 20 min / 169k / 6.7; curves-runner-2 114 / 28 min /
200k / 7.9; odometer-levels 103 / 20 min / 165k / 6.5; acceptance-gates
112 / 23 min / 176k / 7.3. All four inside their budgets.

The curves after this round: no on-board item is left on the Lambda
sequences but B232 (the national values at their defaults in one
sequence); the rest is the runner's last cycle (B224), the margin at
V_bec (B231), the data defects (B225, B226, the two blocked kinds) and
the sibling's extraction of the correction factors sheet (B230). Two
patches wait with the briefs: B221's gate (needs a scenario that shows
it) and B224's shorter last cycle (needs the 83 regressions understood).
Open items: doc/BACKLOG.csv (36 open after this round).

### The workbooks' integrated correction factors as cells (s076/factors-sheet, 2026-10-12)

B230, in the sibling repository (branch factors-sheet, 8c1864b): stage 1
exports the sheet "Integrated correction factors" of every workbook as
`cell` lines with the values in force (the cached results: half of its
step tables are formulas). Layout, the same in all 1049 workbooks: Kv_int
of freight trains A5:B14 (speed, factor; two rows per step), the
conventional passenger sets a (D3: deceleration <= A_NVP12) D5:E14, the
interpolated set D18:E27 (empty unless A_NVP12 < deceleration < A_NVP23:
only 3130237_05c SV30, 0.778), b (D29) D31:E40, Kr_int A32:B41, A_NVP12
D44, A_NVP23 F44, Kt_int D47 (1.1 in 601 workbooks, 1 in 448); labels
included, 113 cells a workbook. Q_NVKINT is not on the sheet. The ActiveX
controls of the dumped sheets are readable (the persisted Value of each
option button in xl/activeX/*.bin) and exported as `cell <sheet>!<control
name> 0|1` after the sheet's cells: the train type (Freight_G, Freight_P,
Passenger_P), Gamma / Lambda, the target type (Track!EoA_SvL / LoA_MRSP:
LoA_MRSP in 354 workbooks), levels, release speed choice, the Q_NV
permissions, EBCL, the conversion model; scroll bars are not read.
118548 sheet cells and 47979 control values added; 772 sequence files
change by added `cell` lines only (checked by script), testcases/,
index.csv and testcases.csv byte-identical, `--check` green.

The runner of master ignores the new lines: evc_s076_check 0 failures,
evc_s076_run 751 / 1330 / 1109, 0 regressions, 0 improvements against
the baseline. Left for the runner: B290 (R_Factors from the sheet,
Kt_int compared), B291 (R_Tool_Target and the train type from the
controls).

### The unauthorised-direction gate, the order from a single group, the national values, level symbols (e4/gates-levels, 2026-10-12)

**B221, 3.14.3.6** (done): the patch of e5/acceptance-gates applied
unchanged: while `EVC_Brake_Commands` watches or brakes for a movement
opposite to the authorised direction (the state of the cycle before),
`EVC_Core.Update_Position` passes `Ignore_Info` to
`EVC_Position.Set_Linking_Context`; `Take_Group` still locates the train
with the group but neither takes its packets (5, 79) nor records them in
`Taken` for the stores. The scenario that tells it on from off
(`Scenario_Unauthorised_Direction_Groups`, `EVC_Test_Position`): FS
level 1, the train backs from 300 m over a group at 200 m laid after it
passed there, with a packet 3 valid in both directions: with the gate
the national values stay at their defaults, without it they are taken.
Matrix 3.14.3.6 todo -> done.

**B240** (not ours): the group of 9990500_24 is a single balise group,
that of 5220200_03 a group of two read with one balise; neither has a
co-ordinate system in SR without linking, so the order valid for the
nominal direction only is rejected (3.6.3.1.4, note 3.6.3.1.4.2). The
earlier "copy with Q_DIR both" had not changed the telegram bits; with
Q_DIR 10 in the bits 9990500_24 runs on to step 58.
`Scenario_SR_Order_Single_Group` (`EVC_Test_Levels`). B017: 3070300_12/13
alike (BG11d, single, not in the linking); 4080425_04, 4080100_06 (SV21),
4100103_15 (SV21, SV22) not traced.

**B232** (not ours): the packet 3 of 3131040_32 and _56 is for country
64 in groups of country 352, applied and dropped at the next group
(3.18.2.5, 3.18.2.10); the workbooks use it: B280 for the runner. _52 is
another failure (the SR Indication). **B250**: not reproduced; the new
scenario runs before `Scenario_MA_Repositioning` as the order check.

**SUBSET-076**: 751 / 1330 / 1109 before and after, 0 regressions.
Edits in `EVC_Core`: `Update_Position` (the `Ignore_Info` argument and
`Brake_State` in its Global) only. Outside the units: none.

### Runner: the last cycle, the margin at V_bec, the warning speed, the unreached steps (e5/runner-cycle, 2026-10-12)

B224: the trial's 83 regressions came back unchanged with a full-length
last cycle at the speed moving only the distance left, so the shorter
cycle (timing) was not their cause: the dip was. By family (27 SV30): a
brake released or a Shunting acknowledgement shown at the dip's low
speed where the train otherwise stays above the permitted speed
(5070300_01, 4050200_08, 4100103_17, _28, 3111200_01, 3131040_61, _71,
_88, _90, ...); a JRU 20 record re-recorded in the step's window by the
dip, or a limit moved out by the swing of A_est2 (the Gamma blocks of
3130232_17, 3131040_03, _05, _21, _23, _82, the Indication of 3131030_12,
3131040_14, 3131060_08: B195 the other way round); a chart above the
limit (3131040_59 102 under 100, 4040800_01 Shunting 33 under 30,
3130232_18 Reversing 60 under 30). Rule (`S076_Bench.Cycle
(Distance_Cm)`, `Move_To`, `S076_Run.Drive_To`): the last cycle keeps
its length and the train's speed and moves the distance left; under a
brake command the leftover speed of before stays, the bench having no
braking model (B262). That takes the first family back: 36 regressions
remain (12 per system version), the second and third families,
understood and re-recorded.

B226: a speed above the warning speed (an ODO speed step naming it, or a
reach-point whose comment says the train overpasses the warning speed)
is the middle of the warning speed and the SBI shown, held. 3131040_02
passes step 61 and stops at 62 (V_TRAIN<<V_STEP>, runner gap).
3131040_76 still fails at 54: its speed step 37 to 45 km/h comes in one
cycle and swings A_est2 like B195 (a ramp at a physical acceleration
saturates A_est2's 0.4 m/s2 as well).

B231: the margin takes the EBD at V_bec = V + V_ura (3.13.9.3.2.10 with
A_est 0; the brief's dV_ebi is no part of V_bec): +1 m (3131040_04: 16 m
against ours 27 m nearer, the probe's margin 26 m). V_bec does not
explain the probe's margin; B261 names the candidates (the SBD of an
EOA's limits, Kv_int by A_ebmax).

B140: 67 first failures under ~[workbook train] (21 SV30): 16 a status
by name only (among them the Indication expected back after an emergency
brake below the permitted speed with Q_NVEMRRLS 1, B260), 5 the release
speed; the method not extended.

SUBSET-076: 751 / 1330 / 1109 before, 756 / 1331 / 1103 after; 36
regressions understood, 47 improvements (3130237_07, 3131040_22, _86
pass in all three versions); untriaged 0. Backlog: B224, B226 done; B231,
B140 updated; B260 to B262 opened.

### The proposal's coverage, the second report, the connection indication (e5/radio-items, 2026-10-12)

B210: the brief's premise was wrong, message 9 carries no packets 21
or 27 (8.4.4.4.1: 49 and 80 only). The proposed shortened MA is an MA:
3.7.2.3 does not accept it unless the SSP and gradients stored cover it
from the estimated front end to its SvL (`EVC_Stored_Information.
Take_Proposal`, `Proposal_Covered`); then there is no decision of
3.8.6.1 b) and no answer (`EVC_Radio_Authority.Judge_Shortening`, the
fact `Proposal_Covered` given by `EVC_Core`): SUBSET-076 4080407_01
expects neither 137 nor 138 (its message 3 had replaced the SSP with
one ending before the proposed LOA). Scenario `EVC_Test_Authority.
Scenario_Shortening_Cover`. B211: neither candidate trigger fires;
counted in the trace, the on-board sends one 136 (129.2 s) and none
after message 38 up to 133.5 s: the runner's no-message window of step
134 takes the 136 of step 129 (B270, Sb83b2c65 triaged model). Found
on the way: packet 58 given in SH (step 99, "the complete message is
rejected") was taken; 4.8.4 rejects the position report parameters in
PS, SH, SL and TR (`EVC_Sessions.Reports.Parameters_Accepted`,
Scenario_Session_Reports). B022: Table 2 [1] was already reached
(`Set_Up_Failed` after the last attempt of a start of mission), now
checked; [7] and 3.5.4.4 need the radio holes in the session half
(B271). B040: 4.11.1.1 and 4.11.1.3 stay partial, the matrix names
what is left: the RBC contact made valid by "no cold movement" (B272;
ours waits for the driver), EOLM (E7), the non-volatile store (E8).
SUBSET-076: the baseline of master 752 / 1331 / 1110, the run after
754 / 1327 / 1109; 3 improvements (4080407_01 passes in three
system versions), 0 regressions. Edits outside the package's units:
`EVC_Core.Evaluate_Radio`'s facts aggregate (one line,
`Proposal_Covered`).

### E5 integration after the twentieth round (2026-10-12)

Merged: s076/factors-sheet (the sibling exports every workbook's
"Integrated correction factors" sheet as cells, the cached values of
its step tables, and the tool's ActiveX control values, among them the
train type, Gamma/Lambda and the target type EoA_SvL / LoA_MRSP, 1049
workbooks, 772 files changed by added cell lines only; B230 done, B290
and B291 for the runner to read them; sibling master 8c1864b),
e4/gates-levels (3.14.3.6: the information of balise groups read while
the unauthorised direction is watched or braked is ignored, B221, with
a scenario that tells the gate on from off by a packet 3 of both
directions; B240 and B232 are SUBSET-076 data: single groups in SR
without linking whose order is valid for the nominal direction only,
3.6.3.1.4, and a packet 3 of another country dropped at the next group,
3.18.2, B280 for the runner; B250 not reproduced, `Initialise` writes
every state; B017: two more families are the B240 case, three left),
e5/runner-cycle (the last cycle before a location keeps its length and
the train's speed and moves only the distance left, B224: the one-cycle
speed dip had been masking failures as well as causing them, 36
sequences that passed by it regress, 47 improve, all understood; under
a brake command the old low speed stands in for the bench's missing
braking model, B262; the warning speed between the warning and the SBI
shown, B226; the margin at V_bec, B231 left with two candidate causes,
B261; B140 counted: 67 first failures, 16 a status named only, 5 the
release speed, B260 on-board: after an emergency brake with Q_NVEMRRLS 1
ours stays in Intervention below the permitted speed) and
e5/radio-items (a proposed shortened MA not covered by the stored SSP
and gradients up to its SvL is not taken and not answered, 3.7.2.3,
3.8.6.1 c), B210, the brief wrong twice: message 9 carries no packet 21
or 27, 8.4.4.4.1, and the sequence expects no answer; packet 58 rejected
in PS, SH, SL and TR, 4.8.4, found on the way of B211, which is a runner
window, B270; Table 2 [1] checked explicitly, [7] needs radio holes,
B271; 4.11.1.1 and .3 stay partial with what is left named, B272;
4080407_01 passes in all three system versions).

Merge by hand: the backlog three-way by id (`briefs/merge_backlog.py`),
the plan subsections appended, the baselines auto-merged and matched by
the run.

Verification on the merged master: `test/check.sh` ok (evc_test 11885
checks), the full proof 11242 checks, 0 unproved (margin 47726 steps),
cross build and stack 27136 B (margin 5632), wasm and both smokes 0
failures. SUBSET-076: 751 / 1330 / 1109 before, 759 / 1328 / 1103 after,
0 regressions against the merged baseline, 0 untriaged. Matrix: 357 ->
356 clauses left in all phases.

Measurements (requests by message id, duration, final context, cost):
runner-cycle 101 / 23 min / 170k / 6.0; radio-items 162 / 26 min / 209k
/ 11.3 (over its budget of 130 by 32); gates-levels 122 / 20 min / 158k
/ 7.1; factors-sheet 59 / 15 min / 110k / 2.9.

Lessons: four briefs of this round carried a premise the agent had to
correct at the source (packets of message 9, the second report's
trigger, dV_ebi in V_bec, the shorter cycle's timing as the cause): the
agents did, and the rule "check at the source first" earns its place in
every brief; a bench without a braking model passes and fails sequences
by accident (B262 is the next runner item of weight). Open items:
doc/BACKLOG.csv (34 open after this round).

### Runner: the factor sheet and the controls (e5/runner-cells, 2026-10-12)

B290: `S076_Sequences` keeps, per curve set, its workbook's sheet
"Integrated correction factors" (`Sheet_T`: the freight Kv_int steps
A5:B14, the passenger sets a / interpolated / b D5:E40, Kr_int A32:B41,
A_NVP12 D44, A_NVP23 F44, Kt_int D47) and the option buttons
(`Train (main)!Freight_G / Freight_P / Passenger_P`, `Gamma / Lambda`,
`Track!EoA_SvL / LoA_MRSP`, `Release_speed_fixed / _OB`, with Track!E2).
`S076_Run.Sheet_Difference` compares the set the train type selects
with the national values in force on the on-board at the step, exactly
(to 0.001): Kv_int at every km/h + 0.5 up to the set's top speed,
Kr_int at the train's length less 0.25 m, Kt_int; for a passenger train
both sides take subset a, b or the interpolation at A_ebmax = AD_0 at
the tool's emergency brake percentage. The EBD rule stays as the
fallback without a sheet: no workbook lacks it. Found at the source:
the 195 passenger workbooks of the A.3.2 defaults carry a set a of 0.9
between 25 and 30 km/h (the tool's template, not A.3.2): all Gamma.

B291: `R_Tool_Target` from Track!LoA_MRSP with target speed 0
(Track!B2): SV30 has 26 such workbooks (15 Lambda, the B200 list; 11
Gamma), 84 LoA_MRSP workbooks with a target speed above 0 (real LoA or
MRSP targets, judged) and 6 without B2 (Gamma); the same 19 sequences
are blocked. `R_Gamma` from the Gamma button (agrees with the sheet's
name everywhere). The release speed choice is recorded for B140.

B225, B280: `Release_Defect` (a fixed release speed no V_RELEASEDP of
the sequence gives, an S076 defect read from the cells, not a list):
3131040_38, _50 and a fourth, _32 (V_RELEASEDP 40 for 40 km/h); _37 is
Gamma first. `Other_Country` names in the not-judged text the packet 3
of another country than its group's (_56, country 64, 3.18.2.5).

SUBSET-076: 759 / 1328 / 1103 before, 765 / 1310 / 1115 after, 0
regressions, 18 improvements (SV21/22/30 each): _38, _50 failed ->
passed; _52, _54, _56 failed -> blocked factors (Kt_int 1.0 of the
workbook against 1.1 in force; _52 the BG2d defaults at its step, which
the old rule's "any packet 3 of the file" accepted); _32 failed ->
blocked by the runner at step 65. Blocked by factors 3 -> 12, tool
target 19 -> 19, Gamma 160 -> 160, S076 defect 186 -> 186. No new
signature.

### The emergency brake revocation, radio holes, the kept RBC contact, level symbols (e5/onboard-misc, 2026-10-12)

**B260** (not ours, the premise wrong): the packet 3 in force in
3130234_08 and 3131020_01 carries Q_NVEMRRLS 0 (the scn's `var
Q_NVEMRRLS 1 0` is width 1, value 0); 3131020_01 sets Q_NVSBTSMPERM 0,
so its emergency brake of step 57 is the SBI's in place of the service
brake (3.13.10.2.3), revoked as the service brake under the permitted
speed (3.13.10.2.4, Table 10 r3), which `EVC_SDM` does
(`Scenario_SDM_EB_Revocation_TSM`: the EB for the SB revoked whatever
Q_NVEMRRLS, the EBI's EB under the permitted speed with 1, at standstill
with 0). Ours brakes by the EBI earlier (717 m at 79 km/h, 1005 m at 73
km/h) because its curves are lower than the ERA tool's there: the
curves family (B140, B261); the EB is then kept to standstill as Table
10 says.

**B271, 3.5.4.4, Table 2 [7], 3.12.1.2.1.5** (done):
`EVC_Track_Conditions.Overlaps_Radio_Hole` (an expression function over
the stored conditions, M_TRACKCOND 4, the estimated front end for the
engine's both ends: no engine length is known), stored at `Evaluate` and
read as `Engine_In_Radio_Hole` by `EVC_Core.Radio_Context` into
`EVC_Radio.Context_T.Radio_Hole`. `EVC_Sessions`: no set-up request
while the engine overlaps the hole (`Produce_Session`), the requests
stopped on entering it (`Stop_Attempts`, Table 2 [3] / [6]; decision: a
request already with Euroradio is not withdrawn, its result is taken),
a connection lost there goes to No Connection ([7]), set up again once
the engine has left it; the defined time of 3.5.4.2.1 still runs. The
session half sees the hole of the cycle before (`Take_Event` runs
before `Evaluate`). `Scenario_Session_Radio_Hole`.

**B272, 4.11.1.1** (RBC contact row done; 4.11.1.1 and .3 stay partial
for EOLM, E7, and the non-volatile store, E8): no cold movement
(`EVC_Odometry.Cold`, 3.15.8) makes the kept contact valid
(`EVC_Radio.Revalidate_Contact` from `EVC_Core.Revalidate_Kept`); a
cold movement or no information leaves it invalid (4.11.1.3); the start
of mission still invalidates it at D2 with an invalid position or level
(5.4.3.3). Checks added to `Scenario_Radio_Joint`.

**B017** (left open): 4080425_04 is the runner's (step 65 at 350 m is
case 5100100's "Level X is already displayed", the level before the
transition at 400 m, judged against the step's L2 column; step 67 at
400 m passes); 4080100_06 SV21: message 24 with packet 41 and a packet
72 in the 2.x layout is not taken (another system version, E7);
4100103_15 SV21/SV22 not traced.

**SUBSET-076**: 759 / 1328 / 1103 before and after, 0 regressions, 0
improvements, no new signature. Edits in `EVC_Core`: `Radio_Context`,
`Revalidate_Kept`, the Globals of `Evaluate_Radio`, `Send_Radio`,
`Produce_Outputs` (`EVC_Track_Conditions.State` as input). Outside the
units: none.

### Protocol: the stored RBC contact, the abandoned entry, the Radio data window after Trip (e4/protocol-items, 2026-10-12)

**Protocol** (common/dmi_protocol.ads, still "v2": the protocol has no
version field; a message or action is added, never redefined).
MSG_RBC_CONTACT 0x10, EVC -> DMI, 22 bytes: known u8, rbc_id u32 (NID_C
above the 14 bits of NID_RBC, DMI 11.3.5.3.1), phone_len u8, 16 digit
bytes of NID_RADIO up to its first nibble that is not a digit. Driver
actions 22 (Train data window, or its validation window, left without
the data: [Close] or the stop of 11.7.1.7 / 11.7.1.9), 23 (SR speed /
distance window opened from the Special window), 24 (that window left).
Both fuzzers know the new message.

**B007** (DMI 11.7.1.4): `EVC_Core.Send_RBC_Contact` (after
`Send_Networks` in `Produce_Outputs`, state `Contact_Sent`) sends the
frame of `EVC_DMI_Port.RBC_Contact_Frame` when `EVC_Radio.Contact`
changes (identity, number or known; not its status, which MSG_ONBOARD
carries); `DMI_Core.Apply_RBC_Contact` makes it the values the RBC data
window proposes and the Data view shows. Decisions: sent on a change
only, none at the power-up while nothing is stored (the on-board does not
learn when the DMI opens the window); NID_C 1023 with NID_RBC 16383 is
sent as no contact; the short number (all F) gives no phone digits. The
runner (test/src/s076_*) can stop typing the contact. **B220**
(3.18.3.3.1) and the 4.4.11.1.5.1 part of **B015**:
`EVC_Driver_Requests` decodes 22 to 24; `EVC_Mission.Take_Data_Entry`
ends the Train Data entry on 22 and watches the SR entry in SR
(`Entering_SR_Data`, from 23 to 24, the SR data entered or SR left);
`EVC_Core` passes either to `EVC_Brake_Commands` as `Modifying_Data`.
**B023** (DMI Table 50 D5, exception): a level entry that led to S5-1
arms it; a switch to TR while the Radio data window is in the stack
presents the default window with MO05 and S5-1 follows its
acknowledgement (`DMI_Windows.Mode_Changed`, `Trip_Acknowledged`).
Scenarios: `Scenario_RBC_Contact_To_DMI` (`EVC_Test_Network`),
`Scenario_Train_Data_Left`, `Scenario_SR_Data_Movement`
(`EVC_Test_Modes`), checks in `DMI_Test_Settings`
(`Scenario_Win_Radio_Data`) and `DMI_Test_Windows`
(`Scenario_Enabling_Conditions`). Matrix: 4.4.11.1.5.1 and 3.14.1.5
done. Golden bench_level2 re-recorded (the new frame alone: with the
call disabled the old digest matched and the 600 cycles' state trace was
identical). Edits outside the brief's units: `EVC_Driver_Requests`,
`EVC_JRU_Records` (the new actions have no SUBSET-027 code), test/wasm/fuzz.js.
SUBSET-076: 759 / 1328 / 1103 before and after, 0 regressions, 3
improvements: 4120100_05 SV21, SV22, SV30 failed at step 47 -> 130 (the
movement in the SR speed / distance window brakes now, 4.4.11.1.5.1; the
next failure is the known S8a01e477, the JRU record of the emergency
brake revoked); no sequence moved by the new message or action 22.

### The bench brakes: a braking model, the step window, the margin from the model (e5/bench-braking, 2026-10-12)

B262: `S076_Bench` brakes after each cycle while the on-board commands
it, at A_basic of the conversion model (A.3.7, `EVC_Braking.
Basic_Deceleration` at the speed) for the brake percentage entered
(the workbook's, else 109): the emergency brake at lambda, the service
brake at min (lambda, 135) (A.3.7.1), down to standstill; once
released the train regains the speed asked for at 0.3 m/s2 (a ramp,
under A_est2's 0.4). Decisions: the speed asked for settles at the next
cycle (the last asked for counts: a handler that restores an old speed
before the chart's no longer lowers the train under a brake); an ODO
speed step is forced whatever the brake (the steps that provoke the SBI
or EBI on purpose), the model acts on it afterwards; in Trip the chart's
stop rules (the sequences' trains stop more gently than lambda 109:
5170200_01 still moving 20 m after the trip, 4080300_03 0.6 m/s2); a
crawl of 10 km/h while the runner drives to a location (4120100_03 reads
a group 2 m on under the runaway EB); the service brake off where the
sequence says "SB must be disabled in LABORATORY" (8 sequences). The
B224 stand-in is gone.

B270: a no-message expectation ignores the radio outputs sent before its
window opened (`Window_Ms`, `Radio_Out_T.At_Ms`); 4080428_01 passes step
134 in the three versions and stops at 168 (a 136 after a rejected
packet 58, as triaged before). No other sequence moved by it.

B261 (left as B300): `Tool_Margin` is the difference of the EBD
distances of the conversion model (`S076_Bench.Ebd_Distance`: A_basic,
Kv_int by A_ebmax, Kr_int in force) at the tool's and the train's
percentage from V_bec: 16 m at 60 km/h for 3131040_04, as the ratio
gave. The brief's premise (no margin where the SBD decides) is
contradicted at the source: that P is SBD-based (618 m; the SvL's EBD
from 60 km/h gives 192 m) and the probe's full margin of 26 m leaves a
rest of 1 m, so the tool ran its service brake at 100 as well; the SBD
difference of A_basic alone is 13 m. The remaining lambda dependence of
our limits is not found yet.

SUBSET-076: 759 / 1328 / 1103 before, 821 / 1293 / 1076 after; 122
improvements, 24 regressions (8 per version), understood: Gamma blocks
(3131040_11, _17, _35, 4100103_17: the SB now slows a Gamma train with
lambda 109's deceleration, the status change of the step falls before
or after its window), 3131040_36 (tool-target), 3131040_18 (the
sequence's train keeps 80 km/h under the SB to reach the EBI, the lab's
SB disabled without saying so), 5070300_01 (the chart at 70 km/h under
a Shunting limit of 30: the SB slows the train, the acknowledgement
comes later), 3131040_54 (SR, no target of ours, B193). None of B224's
twelve turned (B303: 3131040_59 has no brake to act on, Overspeed at
102 under 100 below the SBI; the Gamma ones are the A_est2 swing).
New signatures triaged: S61f30c39 (B301), Sa90fd42a (B302). Backlog:
B262, B270 done; B261 updated; B300 to B303 opened.

### E5 integration after the twenty-first round (2026-10-12)

Merged: e5/runner-cells (the runner reads the workbooks' Integrated
correction factors sheet and the tool's controls: `R_Factors` compares
the set the train type selects with the national values in force
exactly, Kt_int included, B290; `R_Tool_Target` and `R_Gamma` from the
controls, B291; a fixed release speed of the workbook against the
telegram's V_RELEASEDP as an S076 defect, B225, 3131040_32 found too;
the other country's packet 3 named, B280; 3131040_38 and _50 pass; a
template finding for E6: the 195 passenger Gamma workbooks at the
defaults carry a set a of 0.9 between 25 and 30 km/h that is the tool's,
not A.3.2's), e5/onboard-misc (radio holes in the session half: no
set-up and the attempts stopped while the engine overlaps an announced
hole, a connection lost there to No Connection, 3.5.4.4, Table 2 [7],
`EVC_Track_Conditions.Overlaps_Radio_Hole`, B271; the kept RBC contact
made valid without cold movement, 4.11.1.1, `EVC_Radio.Revalidate_Contact`,
B272; B260 had no defect: the `var` line gives the width before the
value, so `Q_NVEMRRLS 1 0` is 0, and the EB triggered instead of the SB
is revoked under the permitted speed already, a scenario added; B017:
4080425_04 is a runner column, 4080100_06 another system version),
e4/protocol-items (`MSG_RBC_CONTACT` 0x10 carries the stored RBC contact
to the DMI, which proposes it in the RBC data window, DMI 11.7.1.4,
B007; driver actions 22 to 24 for the Train Data or SR data window left
without data and the SR window opened, the entries ended and the SR data
movement braked, 3.18.3.3.1, 4.4.11.1.5.1, B220, part of B015, 3.14.1.5
done; the MO05 exception of Table 50 D5, B023; the bench_level2 golden
re-recorded for the added frame, checked by trace) and e5/bench-braking
(the bench decelerates under a brake command at the conversion model's
A_basic for the entered brake percentage and ramps back at 0.3 m/s²,
B262, the stand-in of B224 removed; 122 improvements against 24
understood regressions: Gamma trains now braked at lambda 109, a lab
brake disabled without the comment, a chart above a Shunting limit; the
no-message window ignores outputs sent before it opened, B270,
4080428_01 passes step 134; the margin from `EVC_Braking` at the two
percentages, B261 partly: the P of 3131040_04 is SBD-based and 10 m of
lambda dependence are unexplained, B300; B301 to B303).

Merge by hand: the backlog three-way by id, the plan subsections
appended, the baseline's two conflicting blocks taken from the bench
branch and the merged run then re-recorded (18 improvements of the
union over either branch, 0 regressions).

Verification on the merged master: `test/check.sh` ok (evc_test 11920
checks, dmi_test 2168), the full proof 11280 checks, 0 unproved (margin
47726 steps), cross build and stack 27064 B (margin 5704), wasm and
both smokes 0 failures. SUBSET-076: 759 / 1328 / 1103 before, 830 /
1272 / 1088 after, 0 regressions, 0 untriaged. Matrix: 356 -> 351
clauses left in all phases.

Measurements (requests by message id, duration, final context, cost):
bench-braking 138 / 37 min / 233k / 10.8; runner-cells 81 / 19 min /
158k / 5.0; onboard-misc 150 / 24 min / 213k / 11.1; protocol-items 151
/ 25 min / 218k / 11.7. Two over their budgets (onboard-misc and
protocol-items by about 20 calls each), their "Done" lists complete.

Lessons: the bench's physics decides sequences by the dozen (the
braking model alone moved 146); a `var` line of the sequences reads
width then value (B260's premise); the protocol has no version field,
so a new message or action is added, never redefined. Open items:
doc/BACKLOG.csv (26 open after this round).

### Comments and traceability (2026-10-12)

An analysis of the comments of `evc/` (105 files, 42,937 lines) before
the change: 9,702 comment lines, a quarter of the non-blank lines and a
third of the bytes (568 KB against 1,176 KB of code, about 150k against
335k tokens). By kind of the bytes: plain prose 58%, clause references
28%, history (branch names, backlog ids, "Added by", "Phase En") 7%, GNAT
box separators and rule lines 7%. The impact on the agents' context is
small because they do not read units whole: over 184 transcripts the
sources were read through `sed -n` 1,775 times (median window 31 lines),
`outline.py` 807 times, `grep` 1,747 times and whole only 28 times; a
quarter of a 31-line window is comment, a few thousand tokens per run
against a 17k-token prompt prefix per call. The clause numbers in the
comments were not the traceability either: the agents searched the
sources by clause number 53 times against 5,993 by identifier (they read
the specification through `clause.py`), 684 of the 1,824 done or partial
rows were cited nowhere in the sources, nothing verified the numbers (15
exist in no SUBSET-026 section), and nothing verified the matrix notes'
names against the code.

Done, with one-off scripts kept in the coordinator's scratchpad:

- Dropped from `evc/`: the 166 subprogram name boxes and the 183 titled
  section rules (the title line stays, 744 rule lines go), 261 branch
  names, 101 "Added by" / "Phase En (branch)" prefixes and 65 backlog ids
  (all closed); 1,382 lines less, 299 comment lines rewritten (a branch
  name that points to a numbered decision of a plan subsection stays as
  "decision N of e5/x in the plan").
- `@req` tags derived from the matrix: for every done or partial row
  whose note names `EVC_Unit.Name`, the clause goes on a tag line above
  that declaration (the spec first, else the body); a note naming the
  unit alone, or an enumeration literal, tags the package. 2,006 clause
  tags on 681 lines in 67 files, 34 KB. Net: 9,467 comment lines, 558 KB
  (32.2% of the bytes).
- `trace_subset026.py --check` resolves every `EVC_X.Y` (also `ETCS_`,
  `DMI_`, `S076_`, `Sim_`) and `evc_test <scenario>` of the notes against
  `evc/`, `evc/language/`, `common/`, `sim/` and `test/src/`, and checks
  the tags (an on-board row, done or partial, its note naming the unit).
  The first run found 22 stale references: `EVC_Procedure_Requests` (now
  `EVC_Driver_Requests`, 14 rows), `EVC_PBD.Profile_Of` (now
  `Section_Profile`), a deletion procedure of the E4 work in progress
  that the mode entry of `EVC_Core` replaced, and three prose mentions of
  `evc_test`; fixed in the notes.
- The rules in AGENTS.md "Comments and traceability" and in the common
  brief of the agents: the heading, the decision and the quoted
  specification text stay; a tag and its matrix row are written
  together; no boxes, branch names, round numbers or closed backlog ids.

Not done: the free-form clause numbers inside bodies (2,523 lines) stay
unchecked, by design (they explain a branch); the 15 numbers that exist
in no SUBSET-026 section are other documents' or typos, to be looked at
when their subprogram is next touched.


### The session rows left (e5/session-rows, 2026-10-12)

Premises checked at the source first: 3.5.3.4 a) (`Mission.Evaluate_SoM`,
D2 / S3), d) (`EVC_Level_Sessions.Driver_To_L2`), 3.5.3.8 i)
(`EVC_Sessions.Apply_Network`), 3.5.3.11 (`Mission.Driver_Contact`,
choice 2) and 3.5.7.3 b) / 3.5.7.5 [7] (the radio holes of
e5/onboard-misc) were done; their rows closed with notes and tags.

**Done.** 3.5.3.4 e) (the engine out of the hole: `Mode_Session`, then
`Mode_Session_Order` in level 2 with the stored valid contact), g) (SB
left for a mode of a mission, `Mode_Changed`), h) (`EVC_Level_Sessions.
Take_Radio_Data`: in level 2 outside SB the driver's RBC data order the
session, awaited or not). 3.5.3.8 a) (the desk closed: the session of the
start of mission being established is stopped, not only the supervising
one), b) (`Mode_Changed`: End of Mission), d) (`EVC_Sessions.
Abort_Establishment` from `EVC_Level_Sessions.Evaluate` when the min safe
rear end passes the border, the exit phase now kept without a supervised
session), f) (`Handover` request `Rear_Passed`, `Apply_Handover`), g)
(`Stop_Attempts` closes and releases a session being established; the
onboard-misc decision "a request already with Euroradio is not withdrawn"
is replaced by 3.5.3.8's release). 3.16.3.4.1.1 and .1.3 (`Ref_On`,
`Ref_Ms`: the switch to level 2 with no session, the engine out of a
hole; no supervision in a hole). Scenarios `Scenario_Session_Abort_Desk`,
`_Abort_EoM`, `_Short_Number`, `_SoM_Completed`, `_Hole_Rows`,
`_Driver_Contact`, `_Hole_Contact` (EVC_Test_Sessions),
`Scenario_L2_Exit_Aborts_Establishment`, `_L2_Switch_Contact`
(EVC_Test_Levels).

**n/a / deferred.** 3.5.3.7.1 1) to 3), 3.5.3.7.2: n/a, FRMCS is not
modelled (both radio systems never installed). 3.5.3.8 h), 3.5.4.3 3rd
bullet, 3.5.6.8, 3.5.7.7: deferred, RIU (E7).

**Decisions.** (1) g): the session of a completed start of mission is
ordered whenever none is established or being established in level 2,
whatever happened to it during the start of mission (also after "Train
is rejected"). (2) f): the sessions with the supervising or accepting
role are kept at the rear border. (3) 3.16.3.4.1.1: after the switch to
level 2 the connection is supervised without a session too, while in
level 2; the reference is forgotten when level 2 is left with no session
established. (4) The reference ends with any message accepted
(`Take_Message`, after `Note_Received`).

**Left.** 3.16.3.3.2 (B341: every message of a cycle carries the same
T_TRAIN; the fix belongs in `EVC_Radio.Send` with both halves reading
the stamp back); 3.16.3.4.1.2 partial and .2.1 (no scenario; the changed
Handing Over RBC), 3.5.3.8 f) without a scenario (B342); 3.16.3.4.5 b)
(the shortening at standstill is the authority half's); 3.5.4.5; 3.5.5.1
b); 3.5.2.4, 3.5.3.5.2.1, 3.5.3.7 / a), 3.5.4.3, 3.5.5.1 as they were.

**SUBSET-076**: 830 / 1272 / 1088 before, 833 / 1268 / 1089 after, 0
regressions, 6 improvements (5040300_05 passes in 3 SV; 9990400_08 runs
past the T_NVCONTACT steps, new signature S15472ab5 triaged E5, B340).
Edits outside the units: none in `EVC_Core`; `EVC_Test_Levels` (two
scenarios).

### The margin per limit, the twelve regressions of B224 (e5/runner-margin, 2026-10-12)

B300: the 10 m of lambda dependence that the EBD and A_basic left are
T_bs_reduced. A.3.12 reduces the T_bs of an EOA along a ramp whose speed
loss depends on A_SB, the SBD's own deceleration at min (lambda, 135):
3131040_04 at 60 km/h (freight P, 750 m, T_bs 23.775 s) has
T_bs_reduced 23.000 s at 100 against 22.194 s at 109, 13.4 m, and the
SBD distance 168.1 against 155.4 m, 12.7 m: 26.1 m, the probe's 26 (P)
to 27 m (SBI); the tool's SBD at 100 is the workbook's SBD column
(168.15 m). `S076_Run.Tool_Margin` per limit: where the SBD of an EOA
decides (the workbook's SBI1 at the speed at or beyond its SBI2) the
SBD distance and V times the T_bs_reduced difference of
`S076_Bench.Sbd_Terms` (the conversion model's service brake, A.3.9's
times, `EVC_Build_Up.T_Bs_Reduced`), the Indication also by
T_indication; an EBD-based SBI2, W, P and I by the EBD difference at
V_bec and V times the T_bs_reduced difference of the speed target
(3130237_07, P at 60 km/h: 10.5 + 8.0 m, the probe 18); the EBI by the
EBD alone. Checked against the probe within 2 m on 3131040_04,
3130237_07, 3131060_08 and 3131060_16. Left: a gradient, and T_be_reduced's
A_EB, in the margin (B370).

B303: of B224's twelve SV30 regressions, 3130232_17 and _18 pass again
in the three versions. The intermediate bench of round 21 passed them by
an artefact (the EB at the start of the reverse movement left the train
braked without a ramp, at standstill at 494 m); the runner drove their
Reversing backwards at the forward chart's 40 to 60 km/h, where the
sequences' `speedprofile-reverse` chart says 13 km/h. That chart is read
now (`S076_Sequences.Chart_Speed_Reverse`, taken by `S076_Run.Chart_Kmh`
while the train moves backwards: edits outside this package's
subprograms). 3131040_59 and 4040800_01 are chart findings of B160's
family (a chart at 102.5 km/h for a ceiling of 100, Shunting at 33 under
30: Overspeed below the SBI, no brake to act on), triaged. The five Gamma
ones (3131040_03, _05, _21, _23, _82) are blocked by the reason Gamma
(B100, E6), not failed. 3131060_08 is blocked by placement now (the
margin); 3131030_12 and 3131040_14 stay curve differences (B140).

SUBSET-076: 830 / 1272 / 1088 before, 836 / 1261 / 1093 after; 14
improvements (3131040_04 and 3131060_08 in three versions, 3131060_16 in
SV21 and SV22 to placement; 3130232_17 and _18 pass in three), 0
regressions, no new signature. Backlog: B300, B303, B261, B231 done;
B370 opened.

### The authority rows left, the message length check, the early level transition (e5/authority-rows, 2026-10-12)

B050: the RTM port is extended, not redefined: a tagged input (the
session's message) takes a message frame of 3 to 1023 bytes whatever
its L_MESSAGE (`EVC_Ports.Valid_RTM_Frame`); the untagged form of E1
keeps its contract (the malformed golden is unchanged).
`EVC_Core.Read_Radio_Messages` records such a frame as received (JRU
9, its length as received) and reports it inconsistent (8.4.4.2.1,
3.16.3.1.1 c: `EVC_Sessions.Take_Inconsistent`, M_ERROR 3, JRU 13);
`Scenario_Radio_Length_Check`. 8040400_01 passes in SV30; SV21 and
SV22 stop at step 68 without the 136 (B350). 3.8.2.5.1: i) done, the
shortening of 3.16.3.4.5 b) (`EVC_Movement_Authority.Shorten_To_Train`,
`EVC_Stored_Information.Contact_Shortening`, decision: the service brake
of T_NVCONTACT seen commanded in an earlier cycle, then standstill;
`Scenario_Contact_Shortening`); g) h) j) l) m) cannot happen until E6
brings their reactions, o) needs SM (B008). B301: no defect; ours is L2
up to BG11d and enters L1 on its immediate packet 41 (5.10.2); the
after-state column of 3110300_01 step 154 contradicts its step 156
(M_LEVEL=2): triaged `s076`. Rows: 3.8.2.3.2 c), 3.10.2.2 b) 2nd and
4th bullets (`Scenario_Conditional_Stop_Ends`, with a danger point and
with a LOA), 3.10.3.2 (146 for message 18 with M_ACK), 3.5.2.4,
3.16.3.4.5 and b), 3.16.3.1.1.2 done; 3.15.1.3.3 stays partial (no SM).
SUBSET-076: 830 / 1272 / 1088 before, 834 / 1268 / 1088 after, 17
improvements, 0 regressions. Edits outside the package's units: none
(`EVC_Core`: `Latch_RTM`'s assertion and `Read_Radio_Messages`).

### The release speed and status-by-name steps, the Adhesion window, the proposed RBC contact (e5/runner-release, 2026-10-12)

Premises checked at the source: the baseline names signature ids, not
`~[workbook train]` (52 first failures, 16 SV30, matched by the triage
text); of the five release speed sequences of B140, 3131050_19 and
3131060_01 passed already.

B140: `S076_Run.Location_Judgement`. A status, brake or JRU record step
of a braking curve sequence whose own window missed it is judged over
its location: the JRU records since the train left the location before
(`Sync_Location_Records` copies each step's window; `Rec_Count` / `Rec`
switch the record judging to them) and, for a TIU command, the bench's
changes since then. The steps of one location describe one instant.
That is how 3131050_14 now passes in all three versions: the emergency
brake at the level transition came in the window of step 46, and step
60 expected its record. It also took 3131050_05 and _06 on to their
release speed step. A release speed step (JRU 20 M_SDMTYPE 2) that the
location does not show gets its own signature, naming the origin of the
release speed: fixed by the workbook (Track!Release_speed_fixed), or
calculated on board (V_RELEASEDP 126, `Sequence_T.Release_OB`). The
trace gives ours (`EVC_SDM.Result_T.V_Release`, the monitoring). In
3131050_20 ours is 24 km/h against the comment's 23, but we are still in
CSM 20 m past the sequence's RSM start. The location where we change to
RSM is not among the bench's changes (B360). 3131050_18 is the speed
chart: 29 km/h at 1063 m, where the step needs more than the release
speed of 40. Triage `~[release speed` (16 first failures, 4
signatures). The other status-by-name first failures are speed or
on-board differences, not the window: the SR distance is not supervised
as a target in 3131020_03 to _05, and the chart is above the limit in
3130232_16, _18, 3130700_02, 3131020_01 and 3131040_76.

RBC contact: `RBC_Data_Entry` confirms the contact that the window
proposes (DMI 11.7.1.4) when the step names those values or none. It
types them otherwise. The decision: a step that names no value takes
the proposal. In SV30, 9 entries are confirmed as shown and 7 typed; no
outcome changed. The 56 blocks "the sequence names no value" remain,
because no contact is stored there.

B302: the rows that ask for the Adhesion window (2 and 3 of the case)
are absent from the extract of 3130235_01. `DMI_Window` performs the
request through the Special window (DMI 11.3.11) when the window is
expected at standstill after missing rows. 3130235_01 now runs from step
73 to 76 in three versions: ST02 "slippery rail" is not shown after the
driver's choice (B361).

SUBSET-076: 830 / 1272 / 1088 before, 833 / 1269 / 1088 after, 0
regressions, 12 improvements, untriaged 0. Backlog: B302 done, B140
updated, B360 and B361 opened.

### E5 integration after the twenty-second round (2026-10-12)

Merged: e5/session-rows (the session rows left in 3.5.3 and 3.16.3: the
sessions of 3.5.3.4 e) g) h), the aborts of an establishment in progress
of 3.5.3.8 a) b) d) f) g) with `EVC_Sessions.Abort_Establishment`, the
reference of the connection supervision after the switch to level 2
with no session and after a radio hole, 3.16.3.4.1.1 and .1.3; a), d),
i) and 3.5.3.11 were done already and got their scenarios and tags;
3.5.3.7.1 and .7.2 n/a (FRMCS), the RIU rows deferred to E7; B340 to
B342: every message of a cycle carries the same T_TRAIN, 3.16.3.3.2),
e5/runner-margin (the tool margin per limit: the SBD-based P and SBI of
an EOA from the SBD of the conversion model with T_bs_reduced at the two
lambdas, `S076_Bench.Sbd_Terms`; the 10 m of B300 are T_bs_reduced,
3131040_04 within 1 m of the probe, B300, B303, B261, B231 done; the
reverse movement chart read and driven, 3130232_17 and _18 pass again;
3131040_59 and 4040800_01 chart findings of B160's family; the Gamma
blocks to E6; B370), e5/authority-rows (a radio message whose L_MESSAGE
disagrees with its bytes reaches the on-board through the tagged RTM
frame, `EVC_Ports.Valid_RTM_Frame`, and is refused there with JRU record 9
and M_ERROR 3, B050, 8040400_01 passes in SV30, B350 for the other
versions; the shortening to the train at standstill after the
T_NVCONTACT brake, 3.16.3.4.5 b), A.3.4 i) with the MA request,
`EVC_Movement_Authority.Shorten_To_Train`; B301 was no defect of ours:
the sequence expects level 2 at step 154 and level 1 at 156 from the
same packet 41, triaged s076; 3.8.2.3.2 c), 3.10.2.2 b), 3.10.3.2,
3.5.2.4 closed; B351) and e5/runner-release (a failed status, brake or
JRU step of a braking curve sequence judged over its whole location,
`S076_Run.Location_Judgement`, the release speed steps signed by where
the release speed comes from; 3131050_14 passes, B360 the start of RSM;
the runner confirms the RBC contact the DMI proposes; the Adhesion
window opened through the Special window when the extract lacks the
request rows, B302 done, 3130235_01 to step 76, B361).

Merge by hand: the backlog three-way by id, the plan subsections
appended, the matrix row by row against the merge base (a row changed on
one side wins: 3.5.2.4 from the authority branch, 3.5.3.4 from the
session branch); the baselines merged by git and the union re-run with 0
regressions after each merge.

Verification on the merged master: `test/check.sh` ok (evc_test 11994
checks, dmi_test 2168), the full proof 11304 checks, 0 unproved (margin
47726 steps), cross build and stack (margin 5704 B), wasm and both
smokes 0 failures. SUBSET-076: 830 / 1272 / 1088 before, 846 / 1250 /
1094 after, 0 regressions, 0 untriaged. Matrix: 351 -> 315 clauses left
in all phases (E5: 50 -> 14, of which 5 n/a and 4 deferred this round).

Measurements (requests by message id, duration, final context, cost):
session-rows 109 / 21 min / 210k / 8.5; authority-rows 140 / 24 min /
187k / 9.0; runner-release 115 / 25 min / 185k / 7.7; runner-margin 106
/ 22 min / 168k / 6.6. One over its budget (authority-rows by about 10
calls), every "Done" list complete.

Lessons: two brief premises wrong again (B301 named our transition
early, the sequence contradicts itself; the baseline holds signature
ids, not triage texts); the first round under the `@req` rule: every
closed row came with its tag and the matrix check caught the one left
out (3.10.3.2's tag belongs on a unit the agent was told not to edit,
B351); a unit shared by two agents is best split by subprogram in the
round brief, which held, except the reverse chart that the margin agent
needed in the release agent's reader (named, merged without conflict).
Open items: doc/BACKLOG.csv (27 open after this round).


### The messages to the RBC as juridical records (e5/runner-jru10, 2026-10-13)

Premises checked at the source: 494 of the 1144 sv30 sequences expect
JRU record 10, 3310 times (3207 bare, the others with NID_MESSAGE,
M_VERSION, NID_ENGINE or NID_PACKET). The record follows its
`expect RTM message` (3300 of 3310), it does not precede it: B051's
"625 pairs" are the records between two RTM expectations, which belong
to the one before. So no reordering in `Step_Order` was needed. The
on-board's JRU port has no event for a sent message.

B051: `S076_Run.JRU_Sent` judges record 10 from the bench's RTM capture
of the step's window. The message is the one the line names, else the
one of the RTM expectation directly before (`no-message` included). It
is judged by `Radio_Expect` without that step's packets, with the
record's own fields, so one message satisfies both. NID_PACKET counts as
a packet. A record 10 that names a message from the RBC (4100103_28 step
94: NID_MESSAGE 3) is a SUBSET-076 defect. A record of no named message
passes on any message sent. Result: 5505 steps judged, no outcome
changed. The 532 new failures all come after the first failure of their
sequence.

The other records, by count of steps not judged over the three versions
(13347 before the round, 6294 after):

- Judged now from what the on-board or the bench shows:
  - record 21 bits 39 to 43 (ST02 to ST06, 1506 steps), from the DMI
    state the DMI step of the same symbol reads
    (`S076_Tables.Symbol_Shown`);
  - record 13 with M_ERROR 3 or 4 (event 13);
  - record 44 when expected (the LSSMA displayed).
- Under the reason of their phase: records 5 and 8 (radio infill, 727),
  7 (Euroloop) and 26 (NTC).
- Not written by the on-board (kind onboard):
  - 20 for a change of a speed or distance (690, B400);
  - 13 with M_ERROR 5 (14, B401);
  - 51 (114, B402);
  - 39 (71, B403);
  - 24 and 48 (55 and 15, B404);
  - 30, 31 and 32 (50, 15 and 31, B405).
- Not read by the runner yet (kind runner):
  - record 21's other bits and record 23 (707 and 686, B406);
  - the header fields of ALL, NID_LRBG first (368, B407);
  - 11, 12.M_ERROR and an absent 44 (150, B408).

Judging record 13 revealed one finding. In 8040400_01, step 64 expects
no radio error after the unknown message 254. Ours records one and
reports it, by the decision of e5/jru-radio (3.16.1.1.1). The sequence
fails at step 64 in all three versions (SV30 passed before). This is
triaged onboard (Se89b51af) and left open for the session owner (B409).

SUBSET-076: 846 / 1250 / 1094 before, 845 / 1251 / 1094 after. The
baseline was re-recorded with that one understood regression; 0
untriaged. Backlog: B051 done, B400 to B409 opened.

### Closing the session half (e5/session-close, 2026-10-13)

**Done.** B341, 3.16.3.3.2: `EVC_Radio.Send` raises a stamp that is not
above the last one sent in its session to one unit above it, so two
messages of one cycle carry different stamps. The halves match an
acknowledgement on the stamp they read back from `EVC_Radio.Info
(S).Last_Sent`: `Mission.Await_TD` for message 8, and the 130 of
`EVC_Radio_Authority` for 27 / 28 (the one edit in the authority half).
`EVC_Radio.Stamp_Age` makes `Time_Of_Stamp` treat a stamp ahead of the
clock as now. Scenario: `Scenario_Session_Stamp_Increment`. B342:
`Scenario_Handover_Contact` closes 3.16.3.4.1.2 (the Handing Over RBC's
latest message before the switch, the Accepting RBC's after it), and
`Scenario_Handover_Rear_Border` closes 3.5.3.8 f) under decision (2) of
e5/session-rows. 3.16.3.4.1.2.1 is n/a: with two sessions, a new order
keeps the supervising RBC as the Handing Over one (3.15.1.3.2.3), and
3.15.1.3.2 and .2.4 are n/a, so an announcement never changes the
Handing Over RBC. B351: the 3.10.3.2 tag is now on
`EVC_Sessions.Take_Message`.

B340: Bit38 is ST01, the brake intervention symbol. Fixing it exposed a
defect of ours. In 9990400_08 the national values of BG999d lengthened
T_NVCONTACT, and `Supervise_Contact` then released the service brake at
300 m while the train was still moving. Decision: once triggered, the
reaction ends only with a new message or at standstill (3.16.3.4.5 a,
3.14.1.7); `Scenario_Session_NVCONTACT_Values`. Step 62 still fails, on
the runner's judging of a symbol that is still shown (B380, S15472ab5
triaged `model`). B350 is not a defect of ours. The message 32 of
8040400_01 gives M_VERSION 3.15 in all three versions, so the on-board
awaits the 38. The SV21 and SV22 variants leave the 38 out, so the
on-board terminates the session (3.5.3.7.4.1) and has none left for the
136 of step 68. Triaged `s076` in the note of S13c9beb3.

**Left.** The rows with stale notes were not reviewed against the code
(the budget ran out):
- 3.5.3.5.2.1, 3.5.3.7, 3.5.4.3, 3.5.5.1 and b), 3.5.6.7.
- 3.5.3.7 a): `Capped => True` is passed nowhere, so the limit of A.3.1
  is not applied yet.
- 3.5.4.5: nothing in the code names it; `EVC_Radio.Send` leaves it to
  the halves.

The E5 rows left after this branch, by reason:
- Session half, todo or partial: 3.5.3.5.2.1, 3.5.3.7, 3.5.3.7 a),
  3.5.4.3, 3.5.4.5, 3.5.5.1, 3.5.5.1 b), 3.5.6.7.
- Partial, waiting for SM (B008) or E6: 3.8.2.5.1 and 3.15.1.3.3.

**SUBSET-076**: 846 / 1250 / 1094 before and after, 0 regressions.
**Edits outside the package's units**: `EVC_Radio_Authority` (the stamp
of the 130); `EVC_Test_Handover` (two scenarios).

### The SR distance as a target, the driver's slippery rail, the RSM start exposed, the route unsuitability (e5/sr-target, 2026-10-13)

Premise checked at the source, and wrong: the end of the SR distance was
already a target of `EVC_SDM` (3.13.8.2.1 d), 3.13.8.3.3, scenario
SDM_SR). In 3131020_03 to _05 the on-board had no SR distance at all.
SR was entered with D_NVSTFF infinite, and the national values of a
group passed in SR were not applied. The sequences apply them at once.
Their MRSP charts show the new V_NVSTFF from the group (also in
4080410_01 and 3131040_43). Their comments place the end of the SR
distance at the new D_NVSTFF from the SoM (3131020_03: 1150 m, _04: SvL
at 1333 m). Decision: while the SR values are the national ones,
national values in force taken in SR apply at once (4.4.11.1.6.3 and
.6.4 read as "else the national values"). The SR speed limit changes,
and the end of the SR distance counts from where SR was entered or
Override activated (4.4.11.1.3.1 a)). The driver's values stay, and the
RBC's distance still wins in `EVC_Radio_Authority.SR_Distance_Of`. This
is in `EVC_Mission.Start_National_SR` / `Take_National_SR`, with scenario
SR_National_Distance. The E4 integration scenario of
`EVC_Test_Procedures` now takes its national packet after the driver's
entry: taken before it, the packet would have placed the end 150 m from
the override, behind the train.

B361: the driver's adhesion choice was recorded in the JRU but never
applied. `EVC_Stored_Information.Take_Driver_Adhesion` now applies it
under Q_NVDRIVER_ADHES and resets it when the national values withdraw
the permission (3.18.4.6.2.1). `Driver_Slippery_Rail` goes into the
adhesion byte of MSG_STATUS (`EVC_DMI_Port.Status_Frame`,
`EVC_Core.Send_Status`). The DMI already showed ST02 from that byte. The
scenario is Driver_Adhesion, and 3130235_01 passes.

B360, the on-board half: `EVC_SDM.Shown_At_T.RSM_Start` (ahead
coordinates, like X_Est) and `RSM_Max_Safe` (the start compared with the
max safe front end, the SBI2) for the release speed in force
(`V_Release`). They are reachable through `EVC_Core.Supervision`, and
SDM_RSM_Start_Reduced checks them. The runner's use is a later round.

B034: scope only. Packet 70 is stored, but the comparison of 3.12.2.3
with the Train Data is not made, so it comes first (backlog updated).

EVC_Core edits: the call of `Take_Driver_Adhesion` in
`Evaluate_Stored_Information` (its Global gains
`EVC_Driver_Requests.State`), and `Status_Slip_Sent` in `Send_Status`
and the refined state.

Next failures named: 3131020_03 step 57 expects Indication and the
emergency brake revoked while running with Q_NVEMRRLS 0 (B391); _04 step
70 drives faster than the comment's 60 km/h at 850 m, so the EB comes
earlier (curves triage); _05 step 53 expects the EB where
Q_NVSBTSMPERM 1 permits the service brake. 3131040_43 counts the
national distance from its reception, against the 3131020 family
(Sddb8ef0b, s076). 4080410_01 now fails at step 104: the bench is
faster after the national 80 km/h and passes the SBI of a 50 km/h
target at the override (B390). 3131040_39 and _40 are blocked three
steps earlier by their own reasons (Gamma, tool target), because the SR
end is now a target.

### The speed chart's axis, the chart after a brake, the margin on a gradient (e5/runner-chart, 2026-10-13)

B160: every sequence has a `chart mrsp` line besides its `speedprofile`,
drawn on the same axis: its first point is the zero as drawn (-2.0 to
+4.0 km/h) and its plateaus are speeds of the language. The scale is the
one that puts every plateau within 0.5 km/h of a multiple of 5 km/h
(searched from 0.90 to 1.10 by 0.0005, least squares inside the interval
that fits); the drawings fall into families by their zero, each with one
scale over the whole SV30 corpus (-1.9: 0.954 to 0.963, 415 sequences;
-1.8: 0.962 to 0.973, 221; 0.3: 1.065 to 1.091, 174; five smaller), and
the family decides where two intervals fit (39.6 and 80.9 fit 40 and 80
or 45 and 90). `S076_Sequences.Calibrated`, applied in
`S076_Run.Chart_Kmh` to the forward and the reverse chart;
`S076_RAW_CHART=1` keeps the drawing. Unlike the snapping trial it moves
every speed by the fit only: none of the 17 braking curve sequences of
that trial regressed. 5160000_01 now runs at 70.0 at V_LX 70, 3131040_59
at 100.0 under 100 (and 102 where its chart rises to 104.6: still
S1fd323b5), 3131060_08 at 58 km/h, the speed its comment names.

The chart after a brake: the brief's premise does not hold at the
source. Se041b7f8 (4120100_01, 3 SV) keeps the SR ceiling EB after the
switch to FS at 25 km/h under the FS MRSP of 50: on-board (B411).
3130700_02 step 51: the calibrated chart runs at exactly the sequence's
V5 = 12 km/h, our PBD speed is 10 (B412). The bench's speed model was
left as it is.

B370: the workbook's gradient profile is read (`S076_Sequences.Grades_T`,
Track!B3, I, J) and taken by `S076_Bench.Sbd_Terms` and `Ebd_Distance`
(`Grade_Acceleration`: the lowest gradient under the train, 3.13.4.2,
the rotating masses of A.3.1, 3.13.4.3), passed by `Tool_Margin`. Every
workbook with a gradient is a Gamma one or not a reference, so no step
uses it yet and the comparison with the probe is open (B370 stays open,
T_be_reduced too). B201: not re-checked (budget).

SUBSET-076: 846 / 1250 / 1094 before, 852 / 1247 / 1091 after; 52
improvements, 18 regressions (6 per version), understood and
re-recorded: 3131040_07, _71, _75 Gamma blocks (E6; passed by the
drawing's speed); 3131050_19 (release speed step 55, the train at 25
km/h instead of 24.1 reaches the release speed 15 a cycle late:
speed-sensitive, curves family); 3131060_08 (B410: V_max against
V_NVALLOWOVTRP); 4050200_11 (step 88: the train reaches 5300 m where the
drawing stopped it 1 m short, our periodic odometer check shows there).
Chart families: S4ad45e1a 3 -> 0, S1fd323b5 4 -> 1, S749b2957 9 -> 12,
S7b03e0c6 9 -> 12, S69f1f87e 14 -> 17 (sequences that run further and
stop at a later chart step). Backlog: B160 done, B370 updated, B410 to
B412 opened.

### E5 integration after the twenty-third round (2026-10-13)

Merged: e5/runner-jru10 (`expect JRU record 10` judged from the bench's
RTM capture, the same sent message satisfying the RTM expectation before
it, B051: 5505 steps judged and no sequence outcome changed; record 21's
symbol bits ST02 to ST06, record 13 for M_ERROR 3 and 4, record 44 from
the DMI state; records 5, 7, 8 and 26 under their phase's reason; the
steps not judged 13347 -> 6294; the premise was wrong twice: 494 files,
not 1143, and record 10 follows its RTM expectation; B400 to B409),
e5/session-close (a time stamp increment between consecutive messages,
`EVC_Radio.Send` raising a stamp not above the last one and both halves
reading the stamp back, 3.16.3.3.2, B341; the handover's contact
supervision and the rear border scenarios, B342, 3.16.3.4.1.2.1 n/a
with two sessions; the tag of 3.10.3.2, B351; the T_NVCONTACT reaction
no longer ended by national values that lengthen it, 3.16.3.4.5 a,
found by B340; B350 is the sequence's data; B380), e5/sr-target (the
brief's premise was wrong: the SR distance was a target already; the
cause of 3131020_03 to _05 is that national values received in SR were
never applied: they apply at once while the SR values are the national
ones, 4.4.11.1.3.1 a, 4.4.11.1.6.2, `EVC_Mission.Take_National_SR`; the
driver's slippery rail applied when Q_NVDRIVER_ADHES permits and shown
as ST02 through MSG_STATUS, 3.18.4.6, B361, 3130235_01 passes;
`EVC_SDM.Shown_At_T` carries the RSM start, B360's on-board half; B034
scoped: the comparison of 3.12.2.3 comes first; B390, B391) and
e5/runner-chart (the speed charts calibrated per sequence from their
MRSP line, zero and scale by family, `S076_Sequences.Calibrated`, B160
done, the 17 sequences of the snapping trial unchanged; the workbook's
gradient profile read into the tool margin, B370 partial; the chart
after a brake was not the chart: B411 the EB kept after SR to FS, B412
the PBD speed; B410 the override refused on V_max against
V_NVALLOWOVTRP).

Merge by hand: the backlog three-way by id, the plan subsections
appended, the triage and the baseline by signature or sequence id with
the branch's version of a line it changed; the union of the four showed
6 regressions and 6 improvements against the merged baselines, all
understood (3131060_07 the B410 family at the calibrated 58 km/h,
triaged onboard; 5110400_01 blocked nine steps earlier by its Gamma
reason now that the SR values apply at once), re-recorded. Decision on
B409 at integration: an unknown NID_MESSAGE is ignored and recorded, not
a message consistency error (the conformance test's own comment,
3.17.3.11); to do next round.

Verification on the merged master: `test/check.sh` ok (evc_test 12075
checks, dmi_test 2168), the full proof 11343 checks, 0 unproved (margin
47726 steps), cross build and stack (margin 5696 B), wasm and both
smokes 0 failures. SUBSET-076: 846 / 1250 / 1094 before, 863 / 1239 /
1088 after, steps not judged 13347 -> 6260, 0 regressions, 0 untriaged.
Matrix: 315 -> 307 clauses left in all phases (E5: 14 -> 10).

Measurements (requests by message id, duration, final context, cost):
session-close 131 / 24 min / 210k / 9.8; sr-target 148 / 26 min / 234k
/ 11.3; runner-jru10 100 / 23 min / 150k / 5.3; runner-chart 131 / 28
min / 189k / 9.4. Two over their budgets (sr-target by about 18 calls,
runner-chart by 2), every "Done" list complete.

Lessons: three brief premises wrong (the SR distance target existed;
record 10 follows its message and 494 files hold it; the chart after a
brake was the on-board), each caught at the source; a count from a
grep in the coordinator's survey (1143 files) was the count of all
files, not of the matches: check the command, not only the number; a
backlog line edited by hand at integration needs the quoting of its
commas, the check caught it. Open items: doc/BACKLOG.csv (35 open after
this round).

### The SR target of 4080410_01, the header fields, the curve families after the calibration (e5/runner-curves, 2026-10-15)

B390, checked at the source: the 50 km/h target of 4080410_01 is the TSR
of BG2d (packet 65, 600 m from 500 m) with its packet 141 (50 permille
downhill). A TSR is a source of the MRSP in SR (4.5.2, row TSR); entering
SR deletes the gradient profile and keeps the default gradient for TSR
(4.10), so the TSR's curve runs on 50 permille downhill (3.13.4.1.3 a)).
The sequence's Indication at 730 m at 60 km/h fits a level track (the
gradient profile kept in SR): data (s076), the on-board unchanged.

B407: `S076_Run.Header_Field` judges NID_LRBG (the passed group taken as
the LRBG or not, from the JRU events 10 and 2: `S076_Bench.JRU_LRBG_Id`,
`JRU_Last_BG_Id`), M_VERSION by its X (`EVC_System_Version`, read like
`EVC_Core.Supervision`; Y is 2.3 within X 2, where the sequences name
2.2) and V_TRAIN=0. NID_LRBG given as a group's name, D_SOLR, D_LRBG,
Q_LRBG 1/2 and the doubts stay not judged under `ALL.<field>`. Header
steps not judged 306 -> 37. Findings: B450 (the operated X stays 3 where
the balise groups carry 2.1, S8902de51 / S65dae40b, onboard); B451 (a
linking reaction keeps the old LRBG: the linking packet names the group
before, S4df9e175, s076; found early, Sa4e19acc, s076, partly analysed).

B140 re-counted from the report (30 first failures, 10 SV30), causes
from their rounds' notes; B201 and B370 not continued (budget).

SUBSET-076: 863 / 1239 / 1088 before, 854 / 1280 / 1056 after; 47
regressions, all from the header fields (B450, B451), re-recorded; not
judged 6260 -> 5994. Edit outside the package: the `with
EVC_System_Version` of test/src/s076_run.adb.

### The on-board findings of the runner (e5/onboard-findings, 2026-10-15)

B409: an unknown NID_MESSAGE is recorded (JRU 9) and ignored, not a
message data consistency error: no JRU 13, no report (3.17.3.11 b, the
decision of the twenty-third integration), for an RBC of any version
since the on-board cannot tell a higher Y from a spare value of its own;
a spare value of a known message stays an error (3.16.1.1.1).
`EVC_Core.Read_Radio_Messages`; `EVC_Test_Radio.Scenario_Radio_Unknown_Message`,
and the two scenarios of `EVC_Test_Sessions` that expected the old
reaction now refuse by a spare Q_DIR. 8040400_01 passes in SV30.

B410: "the train speed" of 5.8.2.1 a) is the estimated speed, the speed
of the speed monitoring and of the driver's indication (3.13.10.2.1),
not its upper bound: `EVC_Core.Update_Position` (`Below_Override`, the
DMI's button) and `EVC_Procedures.Override_Allowed`
(`Context_T.Speed_Est`, given by `EVC_Core.Run_Procedures`). 3131060_08
passes, 3131060_07 runs to its Gamma block at step 65.

B411: 4.12.1.2's table gives "TBR" for the speed and distance
monitoring reason when entering FS (and SH, SM, LS, SR, OS, UN, SN): the
reason is re-evaluated on the entered mode's data (4.12.1.2 c,
3.14.1.11.2). Decision: on the first supervision after such an entry
the emergency brake is revoked on its revocation condition of the new
mode (Tables 6 r1, 10 / 11 r1 r3) whatever Q_NVEMRRLS, and kept where a
triggering condition of the new mode holds (no release for one cycle);
Q_NVEMRRLS restricts the release of a command triggered in the mode.
`EVC_SDM.State_T.Reevaluate`, set by `EVC_Core.Revoke_Brake_Reasons`,
taken by `EVC_SDM.Set_Commands`; scenario
`Scenario_Brake_Reevaluated` (evc_test_procedures). 4120100_01 moves from
step 60 to step 93 (B420: the bench keeps 25 km/h after the revoked
brake).

B412 refuted: 3.11.11.6 rounds the PBD speed down to the next lower
multiple of 5 km/h; the sequence's V5 = 12 km/h is the tool's unrounded
value, ours 10 (`EVC_PBD`) is the rounded one: a SUBSET-076 defect, its
blocking in the runner is B421.

B391: the expectation of 3131020_03 step 57 holds only for an
emergency brake commanded by the SBI instead of the service brake,
revoked as the service brake (3.13.10.2.4); ours is triggered by the EBI
(the chart runs at 85 km/h where our TSM EBI is under it at 507 m, the
tool's SBI only decreasing from 540 m), kept under Q_NVEMRRLS 0 to
standstill (Table 11 r0, r3), and the status stays Intervention while a
brake command is applied (3.13.10.2.5). No on-board change: the
difference is the target curve's location (curves family).

### The start of release speed monitoring, the standing symbols, the record bits (e5/runner-rsm, 2026-10-15)

Premises checked at the source: the release speed family is 3131050_05,
_06, _18, _19, _20 and 3131060_10, _18 (the latter two SV21 / SV22),
five signatures; the workbooks carry the tool's own start of release
speed monitoring (`limit StartRSM`, m from the EOA, with its release
speed), read already into `Limits (Start_RSM)` but not used; the
sequences number DMI_SYMB_STATUS as SUBSET-027 4.0 does (TC01 = bit
44), and their track condition steps come as alternatives, grey for an
automatic execution and yellow when the driver acts (DMI 8.2.3.5).

B360: `S076_Run.Release_Judgement` judges a release speed step at our
own start (`EVC_SDM.Shown_At_T.RSM_Start` through `EVC_Core.Supervision`,
by the estimated front end, or the max safe one with `RSM_Max_Safe`).
The reference is the workbook's StartRSM for our release speed (within
1 km/h, `Release_Set`), less the tool margin (`Tool_Margin`, declared
ahead of its body), else the step's location. When our start is ahead
and at most 10 m past it, the train runs on until we monitor the release
speed and the step is judged again over its location, as `Drive_On`
does for a curve step. No change kind in the bench's ring was needed.
3131060_10 SV21 / SV22 pass the step (ours 275 m from the EOA, the
workbook's 287.6, the comment's 339). The others are named per sequence
in the triage of `~[release speed`: no release speed supervised (_05,
_06: the level 1 MA of BG2d at the transition to level 2 is not ours,
B441); our start 48 m past (_20: the SBI1 of the EOA, where the sequence
has the SBI2 of a target between the trip location and the SvL, B442);
and the speed chart (_18, 3131060_18) or the status (_19).

B380: `Holds (Brakes_Shown)` passes a set Bit38 on the symbol still
shown (MSG_STATUS brake) or shown in the window, as `Mode_Proposed` does
for a standing request; 9990400_08 passes (SV22, SV30).

B406: record 21's TC01 to TC37, DR02, LX01 and LS01 (with the LSSMA)
and every bit of record 23 (by its system status messages, `SS_Shown`)
are judged from the bench's DMI state. A failed track condition bit
whose twin of the other execution is ours (`Twin_Shown`), or a step
whose comment says "Only if" or "(automatic execution)", is the other
alternative: optional. Decision: the bench's train is one where the
driver acts (B443). The spare bits 05, 11 and 13 set are a SUBSET-076
defect. A failed JRU step is judged again over its location
(`JRU_Expect` around `JRU_Window_Expect`): an earlier step at the same
location that waited for its own symbol used up the window of the
record. Tables: DMI_SYMB_STATUS bits 41 -> 81 of 110,
SYSTEM_STATUS_MESSAGE 13 -> 31 of 31. Not judged still: record 23
without bits (352 steps), the LE bits cleared, DR03 to DR05. B408 was
not reached.

SUBSET-076: 863 / 1239 / 1088 before, 875 / 1229 / 1086 after; steps
not judged 6260 -> 5407 (JRU not modelled 2965 -> 2048, optional 222 ->
255, SUBSET-076 defect 260 -> 294); 14 improvements, 3 regressions
understood: 3131050_13 step 53 (3 SV), now judged, expects Entering FS
removed at the level transition at 200 m, which ours keeps
(S010e5048, onboard, B440). Baseline re-recorded, 0 untriaged.
Backlog: B360, B380, B406 done, B440 to B443 opened.

### The session rows left, the juridical records the on-board did not write (e5/session-jru, 2026-10-15)

**Rows.** Premise wrong in part: `Capped` was passed already, by the
level 2 start of mission (`Apply_Mission`); what lacked the limit of
A.3.1 (3 times) was the session of a mode change to report, 3.5.3.4 c).
`Mode_Capped` carries it through `Mode_Session_Order` and `Order_T` to
`Establish`; given up, the indication is Table 2 [1] only while the
start of mission opens the session, else [3] (`Set_Up_Failed`). 3.5.4.5:
decision 3 of the position reports already treats a report due during
the loss as sent (not given to the port, not kept); the other messages
go to the port while `EVC_Radio.Established` holds. 3.5.3.5.2.1, 3.5.3.7,
3.5.4.3 (its RIU bullet deferred to E7 by its own row), 3.5.5.1, 3.5.5.1
b) (the conditions of the other sections, each through
`Terminate_Session`) and 3.5.6.7 were done by their subrows. Scenarios
`Scenario_Session_Mode_Change_Capped`, `Scenario_Session_Lost_Send`.
E5 left: 3.8.2.5.1 and 3.15.1.3.3 (E6, SM).

**Records.** `EVC_JRU_Records.Inputs` and `EVC_Core.Record_Inputs_Radio_Data`:
30, 31, 39 and 132 (record 32; 32 is the stored information's event) when
the TIU input is first known and when it changes; 51 while in SH
(4.4.8.1.4); 124 (record 24: Q_RBCENTRY, NID_RBC; NID_C and NID_RADIO do
not fit, B431) and 48 at the driver's entry; 13 with M_ERROR 5 when the
T_NVCONTACT reaction triggers (`EVC_Sessions.Contact_Error`). The runner
maps them in `S076_Tables.Message_Event` (fields not compared yet).
`Scenario_JRU_Inputs`. B400 not implemented: decision left (one record
per cycle under a curve otherwise). Steps not judged 6260 -> 5909;
regressions 4100103_30 (3 SV), record 31 expected at a repeated input of
the same value (Sc4547107, B430).

### E5 integration after the twenty-fourth round (2026-10-15)

Merged: e5/runner-curves (B390 is the sequence's data: the 50 km/h
target of 4080410_01 is the TSR of BG2d on the default 50 permille
downhill that SR keeps, 4.10, while the sequence expects a level track;
the JRU header fields NID_LRBG, M_VERSION and V_TRAIN judged, B407, 306
-> 37 steps, with 47 failures that were blocked before: B450 the
on-board operating 3.0 where level 1 groups carry M_VERSION 2.1,
3.17.2.3; B451 linking data of the sequences; B140 re-counted),
e5/onboard-findings (an unknown NID_MESSAGE recorded and ignored, no
report, 3.17.3.11 b, B409; the override allowed on V_est, 5.8.2.1 a,
B410, `EVC_Procedures.Override_Allowed` too, 3131060_08 passes; the
speed and distance monitoring brake re-evaluated at a mode change,
4.12.1.2, `EVC_SDM.State_T.Reevaluate`, B411; B412 refuted, 3.11.11.6
rounds the PBD speed down to 5 km/h, the tool's 12 is an S076 defect,
B421; B391 analysed, our brake comes from the EBI), e5/runner-rsm (the
release speed steps judged at our own start of release speed monitoring
against the workbook's StartRSM less the margin, B360, with B441 and
B442 for the two families left; a brake symbol still shown passes,
B380; the bits of records 21 and 23 judged from the bench's DMI state,
B406, 81 of 110 and 31 of 31; B440 "Entering FS" kept at the level
transition) and e5/session-jru (the eight E5 session rows closed, the
A.3.1 limit on the mode change session, 3.5.4.5 as a report not kept
while the connection is lost; E5 has 159 done and 2 partial waiting for
E6 and SM; JRU records 24, 30, 31, 32, 39, 48, 51 and 13 with M_ERROR 5
written, B401 to B405, events 124 and 132 for the taken numbers; B400
left with the rate question; B430, B431).

Merge by hand: the backlog three-way by id, the plan subsections
appended, the triage by signature id; the union of the four merged with
0 regressions after each merge (the two runner branches fast-forwarded
or merged without a baseline conflict). The chain was run twice: the
first run was lost with the machine's suspend (the scratchpad's script
gone), the second is the one below.

Verification on the merged master: `test/check.sh` ok (evc_test 12110
checks, dmi_test 2168), the full proof 11392 checks, 0 unproved (margin
47726 steps), cross build and stack (margin 5648 B), wasm and both
smokes 0 failures. SUBSET-076: 863 / 1239 / 1088 before, 870 / 1263 /
1057 after (the failures up by 24 are blocked sequences whose header
fields are judged now and fail), steps not judged 6260 -> 4787, 0
regressions, 0 untriaged. Matrix: 307 -> 299 clauses left in all phases
(E5: 10 -> 2).

Measurements (requests by message id, duration, final context, cost):
onboard-findings 150 / 28 min / 185k / 9.5; session-jru 161 / 34 min /
209k / 11.9; runner-rsm 129 / 33 min / 205k / 9.2; runner-curves 116 /
26 min / 172k / 7.2. Two over their budgets (session-jru by about 12
calls, onboard-findings by 20), every "Done" list complete.

Lessons: two brief premises wrong (the `Capped` limit was passed by the
start of mission already, the mode change session lacked it; the runner
did not judge the new records by number, the table needed them), both
caught at the source; a decision taken at integration (B409) was carried
out next round as written; judging more of a sequence turns blocks into
failures, so the passed / failed / blocked line alone misleads: read the
steps not judged with it. Open items: doc/BACKLOG.csv (30 open after
this round).

### The operated system version, the level transition's MA and indication, the level symbol families (e5/version-levels, 2026-10-15)

**B450** (3.17.2.3, .5, .6, .7, .8, .8 d): `EVC_System_Version.Take_Balise_Group`,
called for every balise group message taken into account by
`EVC_Stored_Information.Take_Version` (the highest X of its telegrams,
`EVC_Position.Taken_Version`; the first packet 2 valid for the direction;
the country mismatch of `EVC_National_Values.Check_Country`): the order is
executed whatever the group's X, else the group's X when higher (or at a
mismatch, even lower), an X outside the envelope ignored, nothing while
the RBC governs; out of level 2 the groups apply again. Left: loops and
RIU (E7), 3.17.2.8.1 / .8.2 (the group of the transition judged again,
E7), the national values of the group itself at the mismatch.
`evc_test` `Scenario_Version_Balise_Groups`.

**B441** (4.8.1.3.1): ours. The information of a message whose immediate
or conditional order changed the level is judged first in the level
before the order with the new level announced; what that accepts stays
(`EVC_Stored_Information.Message_Acceptance`). Decision: what step 1
rejects without [1] or [2] is judged in the new level too.
`Scenario_L2_Order_With_L1_MA`.

**B440** analysed in part (BG1d's profiles start at the group, the rear
is behind it: the question is whether the profiles from before the
transition are kept), **B017** not continued (budget).

**SUBSET-076**: 870 / 1263 / 1057 before, 870 / 1259 / 1061 after, 0
regressions, 5 improvements (SV30 3170200_01, _02, _06, _07, _09);
baseline re-recorded; S8902de51 s076, S65dae40b E7. Edits outside the
units: `EVC_Position.Taken_Version`, the Global of
`EVC_Core.Evaluate_Stored_Information`, `EVC_Test_Support.Version`.

### The records judged in part, the new records' fields, the train after a revoked brake (e5/runner-records, 2026-10-15)

Premises checked at the source: the runner judged records 24, 30, 31,
32, 39 and 51 by number only (`S076_Tables.Message_Event`; a numeric
field noted as a gap); the sequences give M_REMOTE_SHUNTING_STATE (158
steps in SV30), Q_RBCENTRY (66), M_DIRECTION_CONTROLLER (34, in bits as
SUBSET-027 4.2.4.39 writes it), M_SLEEPING (21), M_NON_LEADING (14),
M_PASSIVE_SHUNTING (5). The brief's `--decl Known` of S076_Run does not
exist: the runner's S076-defect blocks are recognised by rule, the
`Known` table is the check's.

**Fields.** `S076_Tables.Record_Field` names the byte of the event of
`EVC_JRU_Records` that carries a field (NID_RBC wide in bytes 3 and 4),
`Field_Value` reads it in decimal or bits; `JRU_Window_Expect` passes a
record only on a record of the event whose given numbers are its own
("recorded with other values" else). Q_RBCENTRY 2 for RBC data entered
on an on-board with GSM-R only is the coding before 4.0.0 (3 in
4.2.4.24): a SUBSET-076 defect when ours recorded 3. Record 13 with
M_ERROR 5 is judged (event 13, `EVC_Sessions.Contact_Error`).

**B408.** Record 11 without M_DRIVERACTIONS passes on any driver action
an event of ours records in the window (else not judged); M_DRIVERACTION
and M_DRIVER, misspelt in a few sequences, are read; an action without
an event of ours is not judged by its reason: 37 is spare in 4.0.0
(SUBSET-076 defect), 43 to 48 ATO, the others (FRMCS 51 to 55,
scrolling) JRU. Record 12 with M_ERROR 0 (linking consistency, 3.16.2.3)
is judged on the position's events 4 to 6; 1, 2, 7 and 8 have no event
(B481). Record 44 absent: the bench notes a change of the LSSMA value
shown in the window (`S076_Bench.Seen_T.LSSMA_Changed`; the end of the
display is no record, 4080300_17 step 178).

**B421.** `S076_Run.Defect_Steps` blocks a step by sequence and step as
S076-defect (3130700_02 step 51, the tool's unrounded V_PBD 12 against
3.11.11.6's 10), not by its signature, which 3130232_18 shares.

**B420.** The chart decides: 4120100_01's speed profile falls from 54.2
km/h at 525 m to 0.5 at 655 m, the desk opened there at standstill. The
explicit speed of the ODO step that provoked the emergency brake (58
km/h) stayed the speed asked for after the brake was revoked on the
desk's closure (4.12.1.2, B411), and the train regained it. Decision: an
explicit speed that a brake lowered and then released is spent
(`S076_Bench.Forced_Spent`, until the next forced speed), the train
follows the chart again (`S076_Run.Drive_To`). 4120100_01 passes (SV22,
SV30; SV21 runs on to its E7 block at step 145), 3131040_78 passes too.

**B443** not done: the comments name the automatic execution of a track
condition in 15 sv30 sequences ("(automatic execution)", already
optional; "executed automatically"), so a per-step rule is possible; a
train with automatic execution is not modelled.

SUBSET-076: 870 / 1263 / 1057 before, 875 / 1257 / 1058 after; steps not
judged 4787 -> 4692 (JRU not modelled 1425 -> 1309, SUBSET-076 defect
294 -> 315); 9 improvements; 3 regressions understood: 9990200_04 step
70 (3 SV), record 13 M_ERROR 5 now judged, expects the T_NVCONTACT
reaction of a packet 3 for country 64 sent in groups of country 352,
not in force (3.18.2.5, the B280 case): triaged s076 (S55180337). New
signatures after a first failure: record 51 with other values
(Sa6e2a661), record 44 absent with a changed LSSMA (S11888609, B480).
Baseline re-recorded, 0 untriaged. Backlog: B408, B420, B421 done; B480,
B481 opened; B443 left open.

### The LRBG families, the curve families, the margin's last terms (e5/runner-families, 2026-10-15)

B451, every sequence traced: the data in all of them. A linked group
found outside the expectation window that the LRBG's linking gives
(3.4.4.4.3.2: 3131040_13, BG1d links BG2 at 350 m and BG3 at 550, the
track has them at 50 and 250; _27; _31; 3130234_10, BG2d at 300 where
BG1d links it at 250, its MA rejected), or a linked group the linking
does not name (3.4.4.4.2: 3131040_20, _37, _38, _50; 3080500_03, whose
BG3d linking leaves out BG4d). The bench places each group at its
step's location, as the telegram lines do. `S076_Run.Linking_Data_Cases`
(sequence, step, the reason with its clause) blocks them as S076-defect
at the step that expects the group taken as the LRBG; it also holds
3131040_78 (the step text says the speed rises above V_EMA, its comment
and the Indication expected say below, 3.13.10.4.15).

B140: the ~[workbook train] triage line rewritten by cause, 24 first
failures left (chart 3130232_16, 3131020_01, _04; on-board analysed
3131020_03; s076 3130700_02 B421 and 3131030_12 SV21/22, an
L_ENDSECTION 94 m longer than the SV30 twin's; undecided 3131020_05;
model 3131040_76 and 3130234_08, the runner's speed held after a speed
decrease input where the chart rises again, B490). B140 stays open.

B370: T_be_reduced in (`S076_Bench.Ebd_Distance` With_Bec, taken by
`Tool_Margin`): 0 for 3130237_07's 62 to 30 km/h, up to 8 m for a
freight train with a small speed drop. Against `evc_curve_probe` at
loa=40 the bench's EBI is 65 m beyond the on-board's, so the term is not
validated: open. B201: 3131060_14 re-probed, unchanged (+3.7 m at 180
km/h in every limit, the EBD itself); the rest not re-probed.

SUBSET-076: 870 / 1263 / 1057 before, 870 / 1233 / 1087 after; 24
improvements (failed -> blocked at the same step), 6 regressions
understood (3130234_10 and 3131040_78 blocked at the defect's step,
before their failure), re-recorded; no new signature. Edit outside the
package's subprograms: the call of `Linking_Data_Case` in the step loop
of `S076_Run`, next to `Single_Session_Case`.

### Route suitability, the brake reasons at a mode entry, the start of release speed monitoring (e5/route-brakes, 2026-10-15)

B034: the route suitability data are compared with the Train Data each
cycle, so again at a change of the Train Data (3.12.2.3 a to c; 3.12.2.3.1
from bit 0 of the configuration's Voltages; NID_CTRACTION not compared,
the Train Data has none: decision), `EVC_Track_Description.Unsuitable`;
the closest unsuitable location not passed by the min safe rear end is a
temporary EOA and SvL with no release speed (3.12.2.4, 3.13.1.5),
`Suitability_Target`, taken by `EVC_Stored_Information.Build_Temporary`
when closer than the mode profile's and the level crossing's (its
passage by the min safe front end is the trip of [12], [16]); the system
status messages 30 to 32 per kind, `EVC_Core.Show_Route_Unsuitable`. A
message 24 with packet 70 now reaches the stores
(`EVC_Radio_Authority.Take_Message`; the other packets of message 24,
B474). Scenario `Route_Suitability` (evc_test_profiles). 3120200_01 and
_04 pass (3 SV), _05 runs to its trip and fails at step 82 on M_LEVEL 7
(S0e7148b0, s076); 9990400_28 needs the train's D2 (S49bc1c1a, model,
B471); 3120200_06 regresses from passed to step 45, understood: its
engine runs on lines without traction system, the bench's configuration
does not (Sb480a8fc, model, B472); 4100103_43 moves 47 -> 65 (S82794294,
B473).

B014: every brake reason the on-board has was checked against the table
of 4.12.1.2 cell by cell; the one difference, the T_NVCONTACT service
brake kept on entering NP, SB, SH, SR, UN, TR, SN, is revoked by
`EVC_Sessions.Revoke_Contact_Brake` from `EVC_Core.Revoke_Brake_Reasons`
(checks in `Scenario_Session_NVCONTACT_Brake`). a) to e) and [1] done;
4.12.1.2, its Table and [2] partial for the reasons not modelled (B470)
and SM (E6).

B442, the sequence's data: 3.13.9.4.6 names the SBI2 of targets between
the trip location and the SvL without D41 (that is 3.13.9.4.8's, for the
release speed value); the only such target of 3131050_20, the 15 km/h
step at 2050 m, has its SBI2 beyond the EOA, so the SBI1 of the EOA
rules, as `EVC_SDM.RSM_Start` does and as the comment's last sentence
says; its 176 m before the EOA is not the workbook's own SBI at 23 km/h
(about 124 m, `curve_probe.py`, ours inside the B175 margin).

SUBSET-076: 870 / 1263 / 1057 before, 873 / 1257 / 1060 after, 14
improvements, 3 regressions understood (3120200_06, 3 SV), baseline
re-recorded. EVC_Core edits: `Revoke_Brake_Reasons`, `Show_Route_Unsuitable`
and its call, `Unsuitable_Shown` in the state, `Produce_Outputs`' Global.
Outside the package: `EVC_Stored_Information.Build_Temporary`,
`EVC_Radio_Authority.Take_Message`, `EVC_Sessions.Revoke_Contact_Brake`,
the catalogue check of evc_test_procedures.

### E5 integration after the twenty-fifth round (2026-10-15)

Merged: e5/version-levels (the version order of packet 2 and the
operated system version from the balise groups, 3.17.2.5 to 3.17.2.8 d),
`EVC_System_Version.Take_Balise_Group`, B450; the brief's claim was only
half right: a lower X cannot lower the operated one, the order can; a
message whose immediate order changes the level is judged first in the
old level, 4.8.1.3.1, `EVC_Stored_Information.Message_Acceptance`,
B441: 3131050_05 and _06 supervise the release speed now; B440 analysed
in part; B017 left), e5/runner-records (the fields of JRU records 24,
30, 31, 32, 39, 51 and 13 with M_ERROR 5 compared; records 11, 12 and an
absent 44 judged, B408; 3130700_02 step 51 blocked by sequence and
step, `S076_Run.Defect_Steps`, B421; an explicit speed spent once a
brake lowered and released it, B420; B480, B481), e5/runner-families
(the "found early" and "another group" families are linking data of
SUBSET-076, 3.4.4.4.3.2 and 3.4.4.4.2, blocked with the clause in
`S076_Run.Linking_Data_Cases`, B451; the `~[workbook train]` triage
rewritten by cause, B140; T_be_reduced in the margin, not validated,
B370; 3131060_14's residual is in the EBD, B201; B490) and
e5/route-brakes (route suitability compared with the Train Data every
cycle, the system status messages 30 to 32, the temporary EOA and SvL at
the closest unsuitable location, 3.12.2.3 to 3.13.1.5, B034, a message
24 with packet 70 alone now reaching the stores; the brake reasons
checked cell by cell against the 4.12.1.2 table, the T_NVCONTACT brake
revoked on the entered modes the table says, B014, with B470 for the
reasons not modelled; B442 is the sequence's data; B471 to B474).

Merge by hand: the backlog three-way by id, the plan subsections
appended, the triage and the baseline by id; one source conflict, the
two runner agents each adding a block table at the same place of the
step loop, both kept, and the merge's own mistake caught by the union's
run: the first branch's block call had fallen outside its `elsif`, so
3130700_02 ran past its blocked step (restored before the commit).

Verification on the merged master: `test/check.sh` ok (evc_test 12129
checks, dmi_test 2168), the full proof 11437 checks, 0 unproved (margin
47726 steps), cross build and stack (margin 5632 B), wasm and both
smokes 0 failures. SUBSET-076: 870 / 1263 / 1057 before, 875 / 1220 /
1095 after (the blocks up by 38: the linking data cases and the PBD
block), steps not judged 4787 -> 4689, 0 regressions, 0 untriaged.
Matrix: 299 -> 287 clauses left in all phases.

Measurements (requests by message id, duration, final context, cost):
version-levels 123 / 24 min / 185k / 7.8; route-brakes 176 / 36 min /
226k / 13.1; runner-records 122 / 25 min / 212k / 8.5; runner-families
139 / 33 min / 207k / 9.9. One well over its budget (route-brakes by
about 45 calls, the three items each a package of its own), every
"Done" list complete.

Lessons: three brief premises wrong or half right (the lowering of the
operated version; the runner's `Known` table is the check's, the runner
had none; a message 24 with packet 70 alone never reached the stores),
each caught at the source; a merge that keeps both sides of a source
conflict must re-read the common tail of the hunk (a call that belonged
to both branches stayed with one); three items of that size are two
too many for one brief. Open items: doc/BACKLOG.csv (29 open after this
round).


### The stale triage lines re-traced (e5/runner-retriage, 2026-10-16)

The triage lines of the E5 group and the stale lines of the onboard
group were re-traced on master a25dc92, one sequence or more per
signature (`VERBOSE=1 DEBUG=1 obj/evc_s076_run`, the scn's step and
`var` block, the clause). Each line re-traced now says what the
sequence waits for and why, with "(re-traced 2026-10-16)"; a defect of
ours names its backlog line. One rule of the runner's driver was fixed:
"The driver presses Radio Data" is the Main window's button (DMI
11.2.5), pressed by `S076_Run.DMI_Input`, no longer judged as a window
the on-board opens.

| cause | signatures (sequences) | backlog |
|---|---|---|
| ours | Safa2d197 (12), Saa959bed (9), Saeffd85e (9), Sc4bf79ea (3), Sdecbd2e2 (3), Sc4c3a7a1 (3), ~159 (3 + 3050300_19), S40db9a42 (3), S6b9f37cf (3) | B520, B522, B521, B521, B525, B526, B527, B528, B529 |
| s076 | S9519b1f5 (9), Seef98e05 (6, presumed), ~156 / S185bee31 (13, two traced) | |
| model | S65c3faf6 (8), S17ad648d (3), S8902de51 / S65dae40b (18, the version operated before the sequence; the SV30 rest is B530) | B524, B530 |
| model, fixed | ~DMI radio data dialogue (16): 5040300_17, _18, 3050600_05, 3180400_05, 4080453_01 move to their E5-radio blocks, 3050300_19 to its 159 | |
| dmi | S322852a4 (4): DMI Table 50 D5 against 5.4.3.2 S2 -> S3 | B523 |

The defects of ours go to the authority and procedures owners: the
emergency stop's system status message (B520), the MA request before
the End Section's section timer (B521, 12 sequences), a linking trip
on a group that was found (B522), the trip at the former temporary EOA
(B525), the 132 in level 1 (B526), the 159 after the driver's RBC data
(B527), the route unsuitability message (B528), the LSSMA (B529).

Left untraced by budget (their texts unchanged): in the E5 group
S0578fc93, S3e2df66d, S0c7e8942, S5967fccc, S4a80e57d, Sa32fcae0,
S127a1224, the ~registration, ~disconnect, ~150, ~147, ~138, ~158
lines, S65c13939, S7e2edbdf, Sac5a37a6, Sc18cdb2f, Sd4cbc324,
Sce3c7004, S81c940f5, S83896b5d, S112c80a6, S863aab40, Sfb725745,
S41e5392f, S61d2b0d5, S1d2c2503, S52fbd3cd, Sf95a7750 (about 85
sequences); in the onboard group S3f6059ba, S908191ec, S0e2fe215,
S5fab4e40, Scefec287, Sb12d0fcd, Se3765f9b, S793ccb34, S0ebd65fd,
S56315725, Sa06b325b, S707f6e73, Se341da87 (about 40). SUBSET-076: 875 /
1220 / 1095 before, 875 / 1207 / 1108 after, 0 regressions, 16
improvements, no untriaged signature.
### The level 1 MA in level 2, the stale transition signatures, message 24's packets (e5/authority-left, 2026-10-16)

Sbfa49d0b split in two: 5100300_07 is the sequence's data (the level 1
MA of BG33d, EOA 450 m, is still supervised in level 2 by 5.10.3.1.4;
the train is placed at 500 m in FS before the RBC's first MA), triaged
s076; 3130700_07 is ours: the level crossing not protected of message 3
at D_LX 0 behind the train trips as a temporary EOA passed (3.12.5.8)
where 5.16.3.2 substitutes it at once. A fix in `EVC_SDM` (the targets
of the cycle of `LX_Release` rebuilt without the temporary EOA, proved)
moved 3130700_07 to blocked at step 78 but failed 3130700_04 at step 65:
reverted, B513. S2f278aca: 3050300_01 re-traced, a trip by 4.6.3 [39]
at an immediate order from level 0 to level 1 whose MA is in the
group's second balise; the one-balise case passes natively
(`EVC_Test_Levels.Scenario_L1_Order_With_L1_MA_In_L0`, 4.8.1.3.1 2)),
cause left (B510). S256f4faf not re-traced (B511). B474 tried (every
message 24 with packets to the stores, 8.7.9): 60 improvements, 15
regressions in five families, reverted (B512). B440 and B473 not
started. SUBSET-076 unchanged: 875 / 1220 / 1095.
### The driver actions the JRU misses, record 20 at every change, the records of the TIU inputs (e5/jru-actions, 2026-10-16)

**M_DRIVERACTIONS.** Re-traced on master, four of the five signatures
are the sequences' data: S31584e9f (case 5080300 4 joined from its step
8, the driver never presses Override EoA: the PDF goes from step 40 to
49), Saf17a2ce (no acknowledgement of OS before step 54, the PDF goes
from 51 to 54), S81316df3 (1 "Ack of Shunting mode" expected for a
press of Shunting, SUBSET-027 4.2.4.11 gives 11, which 57 steps of the
corpus expect), S2dde4dd3 (the sequence starts at step 9, no driver ID
entered). Sc1c4236f is the runner's: it confirms the Level window with
Enter while the DMI proposes no level (not valid after the power-up), so
nothing is sent (B500). On the way, `EVC_Levels.Evaluate` records the
driver's selection of the level in force too (event 40 kind 1 cause 0,
`Scenario_JRU_Level_Again`).

**Record 20 (B400).** `EVC_Core.Send_Supervision` writes event 21
whenever the monitoring, the status, the MRDT or any field of record 20
as displayed changes (`SDM_Shown_T`: V_PERM, V_SBI, V_TARGET and D_TARGET
where the DMI shows the target (TSM, RSM, or the CSM target flag),
V_RELEASE while shown, the TTI of MSG_STATUS; 1 km/h, 1 m), at most one a
cycle: one record a cycle under a curve (165 of 165 cycles in TSM in
`Scenario_SDM_JRU_Every_Change`), 16 bytes of the 2048 of the outbox. The
record still carries bytes 2 to 4 only (M_SDMTYPE, M_SDMSUPSTAT, the
MRDT): the runner can judge the presence of a record 20 at a change, not
V_PERM and the others (B431). Goldens: one record more in two (as
intended).

**B430** dropped: SUBSET-027 4.2.3 triggers records 30, 31, 32 and 39 at
start up and when the input state changes; 4100103_30 repeats the same
value with no power-up between (Sc4547107, s076).

**B431** left, decision proposed: a continuation record (event 255, its
bytes 2 to 16 fields of the record before it, in the same cycle) would
carry record 20's 59 bits and record 24's NID_C and NID_RADIO in one
record each; every reader of the 16-byte layout (Sim_JRU's cycle and
time, the runner's capture in S076_Bench, the hosted port, the wasm
glue) must skip or decode it, so it goes with the runner owner.
### The sequence's train in the bench, the explicit speed, the negative record window, record 20's fields (e5/runner-train, 2026-10-16)

B471: the trains of a sequence's messages 129 (their packets 11) are read
(`S076_Sequences.Trains`, `Train_At`: the first message 129 at or after
the entry's location) and `S076_Run.Enter_Train_Data` keys their axle
load category and loading gauge (A .. D4XL on the keys 1 to 11, E4 and
E5 after [More]; G1 .. GC on 1 to 4, else "Out of GC" as before).
9990400_28 enters D2 now and still fails at step 69: no "Route
unsuitable - axle load category" for the line's A, HS17, B1 (B540, an
on-board trace for the owner of `EVC_Track_Description`). 4080436_01
SV30 101 -> 80, understood: its joined case 3120200_01 expects its line
G1 unsuitable, this sequence's own train is G1 (S40db9a42, the joined
case's data). B472: the test hook `EVC_Config.Set_Voltages_For_Test`
(proved), applied at `S076_Bench.Power_On` (`Set_Voltages`, kept over
Reset) with `S076_Sequences.Engine_Voltages` (the M_VOLTAGE list of the
first packet 11, else AC 25 kV; bit 0 where a comment says the engine
runs on a line not fitted, 3.12.2.3.1); 3120200_06 passes in the three
versions. B490: an explicit speed ends where the chart leaves the speed
it had where the speed came by more than 5 km/h, either way
(`S076_Run.Chart_Left`, in `Drive_To`); decision: a fall ends it too
(+14 sequences: 3130234_08 and _01, 3131040_10, 4100103_16 and _24),
although 3131020_04 stops at 68 instead of 70 (it reached 70 by holding
78 km/h over the chart's fall; step 68 now judges the chart's speed
against our curves, [workbook train]). Record 20 without M_SDMTYPE /
M_SDMSUPSTAT (`S076_Run.JRU_20_Fields`): passed on an event 21 of the
window with its numeric fields (V_PERM, V_SBI, V_TARGET, V_RELEASE at
1 km/h, D_TARGET at 1 m) against the values the DMI shows, symbolic
ones by the record alone; without a record 20 in the window not judged
naming the field (555 steps today, 116 more expected absent). On the
merged tree with record 20 at every change of the displayed
information these become judged. B480 left: the window of the steps
of one location includes the waits of an earlier failed step; a
negative record 44 judged over its own part needs the step loop to mark
where a failed step's wait began (the loop is not this package's).
SUBSET-076: 875 / 1220 / 1095 before, 892 / 1212 / 1086 after, steps
not judged 4689 -> 4665; 4 regressions understood, baseline re-recorded.

### E5 integration after the twenty-sixth round (2026-10-16)

Merged: e5/runner-retriage (the stale triage lines of the E5 and onboard
groups re-traced, 18 signatures rewritten by cause: eight on-board defects
found behind texts that still said "not written yet" or "phase 2" (B520 to
B522, B525 to B529), two runner rules (B524, the driver's Radio data press
fixed in `S076_Run.DMI_Input`), one DMI decision (B523), 6060302's version
expectation at 100 m (B530); about 85 sequences of the E5 group left
untraced), e5/authority-left (5100300_07 the sequence's data by 5.10.3.1.4;
3130700_07 ours: a level crossing not protected whose start the train has
passed at or below V_LX is a speed restriction, 5.16.3.2, the `EVC_SDM`
fix reverted for a regression of 3130700_04, B513; the two-balise level 0
to level 1 case of 3050300_01 with its scenario, B510; B474 tried on every
message 24 and reverted for 15 regressions, B512; B511; no on-board change
kept), e5/jru-actions (the driver's selection of the level in force
recorded, SUBSET-027 4.2.4.11, `EVC_Levels.Evaluate`; JRU record 20 at
every change of the displayed speed and distance monitoring information,
SUBSET-027 4.2.3, `EVC_Core.Send_Supervision` with `SDM_Shown_T`, one
record per cycle under a curve, B400 done; four of the five
M_DRIVERACTIONS signatures are the sequences' data, the fifth the runner's
Level confirm, B500; B430 dropped: records 30 to 32 and 39 follow a change
of the input state; B431 left with a continuation record proposed) and
e5/runner-train (the sequence's axle load category and loading gauge from
its packet 11, `S076_Sequences.Trains`, B471; the engine's traction
systems through `EVC_Config.Set_Voltages_For_Test`, B472, 3120200_06
passes; an explicit speed ends where the chart moves 5 km/h from its value
at the input, `S076_Run.Chart_Left`, B490; record 20 steps judged by their
fields against the DMI values, `S076_Run.JRU_20_Fields`; B480 left; B540).

Merge by hand: the backlog three-way by id, the plan subsections appended,
one triage line rewritten on two sides (S40db9a42: both texts kept), the
baselines merged by git without a conflict and confirmed by the union's
run; no source conflict.

Verification on the merged master: `test/check.sh` ok (evc_test 12133
checks, dmi_test 2168), the full proof 11444 checks, 0 unproved (margin
47726 steps), cross build and stack (margin 5632 B), wasm and both smokes
0 failures. SUBSET-076: 875 / 1220 / 1095 before, 904 / 1205 / 1081 after,
steps not judged 4689 -> 4434 (record 20 steps without a record in the
window 683 -> 384 once the on-board writes one at every change and the
runner compares the fields), 0 regressions, 0 untriaged. Matrix: 287
clauses left, unchanged (no row done this round: the round was analysis,
recording and the runner).

Measurements (requests by message id, duration, final context, cost):
jru-actions 136 / 28 min / 164k / 7.8; authority-left 115 / 27 min / 178k
/ 7.3; runner-retriage 100 / 23 min / 149k / 5.5; runner-train 132 / 34
min / 192k / 9.0. All within budget, every "Done" list complete.

Lessons: a triage text is a snapshot; the re-trace of the E5 group found
eight on-board defects and three data cases behind 60 sequences that the
report had been counting as "radio not written yet" for weeks, so a
re-trace of stale texts belongs in every few rounds, not once. Two
on-board fixes that were right by the clause were reverted by their agent
for regressions it could not explain in budget (B512, B513): the next
brief starts from the regression, not from the fix. Both runner agents
and the JRU agent met on record 20 without a conflict because the brief
named the record's fields on both sides. Open items: doc/BACKLOG.csv (41
open after this round).

### The E5 group's remainder re-traced, the runner's Level confirm and conditional steps (e5/runner-e5-group, 2026-10-16)

Two rules of the runner's driver. "The driver confirms Level" on a Level
window that proposes no level (the level not valid after a power-up)
selects the level the steps settle on (`S076_Run.Selected_Level`)
before Enter, as a select step does (`S076_Run.DMI_Input`; B500 done:
4100103_09 passes in the three system versions, _15, _26 and 5040500_02
stop later at a radio block or the runner). A step conditional on the
initial mode of its test case ("only if initial mode is SB mode",
"isn't SM"; the initial mode is the mode before of the case's first row,
the nearest step with row 1) is not taken when the case began in another
mode (`S076_Run.Initial_Mode_Excludes`, reason optional; B524 done), and
a failed step of a choice made at the sequence's start ("only if
USE_FT... has been chosen") is not judged: 3110500_02 moves from step 70
to step 293 (B591).

The signatures of the E5 and onboard groups left untraced last round
were traced to their first failure on master 846aba0 (one trace each,
`VERBOSE=1 obj/evc_s076_run`, the scn's step); their triage texts name
the step and the backlog line, "(re-traced 2026-10-16, one trace to the
first failure)": a first look, the clause of each shape is for the owner
to read. None was the runner's; one was the sequences'.

| cause | signatures (sequences) | backlog |
|---|---|---|
| ours, level transitions | S0578fc93, S127a1224, S81c940f5, S41e5392f, S863aab40, S65c13939 (18) | B580 |
| ours, level symbol | S3f6059ba, S52fbd3cd, Sb12d0fcd (9) | B581 |
| ours, network and connection | ~registration, ~disconnect, Sce3c7004, Se3765f9b, S7e2edbdf (18) | B582 |
| ours, messages to the RBC | ~150, ~147, Sa32fcae0, ~138, ~158, Sc18cdb2f, Sf95a7750 (20) | B583 |
| ours, mode profiles and modes | Sac5a37a6, S5fab4e40, S112c80a6, S5967fccc, S0ebd65fd (12) | B584 |
| ours, trips | Sd4cbc324, S61d2b0d5 (5) | B585 |
| ours, track ahead free | S3e2df66d, S1d2c2503 (6) | B586 |
| ours, Train integrity button | S908191ec (3) | B587 |
| ours, status messages and symbols | S793ccb34, S56315725, Sfb725745, Se341da87, Sa06b325b (15) | B588 |
| ours, planning gradients | S4a80e57d (3) | B589 |
| ours, JRU record calls | S0c7e8942, Scefec287, S0e2fe215, S707f6e73 (15) | B590 |
| ours, after the conditional step | S256875a4 (3, new) | B591 |
| s076 | S83896b5d (6): record 21 Bit27 after the FS symbol, 929 steps of sv30 record Bit26 | |

The seven first failures seen last round and not written up are among
them (4070201_03 B580, 3060800_01 B583, 9990500_02 B586, 5100200_01
B580, 4080416_01 B589, 3060500_05 B587, 5170200_03 B581). B480 left with
what was learnt (the negative step judges the JRU capture of the whole
window; a mark where a failed step's wait began is the fix, after the
JRU capture's rewrite of `S076_Bench`).
### The level crossing substitution from its regression, the linking trip in SR level 2, the session after message 32, the loading gauge message (e5/level2-left, 2026-10-16)

B513 done: the `EVC_SDM` fix of c83777c re-applied (`LX_Substitution`,
5.16.3.2), 3130700_07 failed 75 -> blocked 78. The regression of
3130700_04 step 65 was not caused by it: on master that step passed only
because the LX start at D_LX 0 behind the train braked it to a stop; with
the substitution the train runs on at the runner's 12 km/h, the
sequence's V5 as the ERA tool computes it unrounded, over our V_PBD of 10
rounded down by 3.11.11.6 (S8727c744, s076). B522 done: BG10 was read in
SR, where the linking is not checked (4.5.2.2), so its window stayed the
expected one and the check of FS found it passed; a group read while the
linking is not checked now ends the windows up to it without a reaction
(3.4.4.4.6 a), 3.4.4.2.1.1 b), `EVC_Position.Decide_Linking`): nine
sequences move on. B527 dropped: the same RBC entered does nothing
(3.5.3.4.1); message 32 comes 17.1 s after our 155, past A.3.1's 15 s,
and 3.5.3.7.3 has restarted the establishment: the runner's timing
(B570). B528 not started. SUBSET-076: 904 / 1205 / 1081 before, 901 /
1205 / 1084 after (3 regressions understood, 12 improvements).
### The trips and MA requests found behind stale triage (e5/trips-ma, 2026-10-16)

Four on-board items of the re-trace, each checked at the source first.
B520 done: the trip of the unconditional emergency stop (4.6.3 [20]) has
the reason `Emergency_Stop` (`EVC_Procedures.Enter_Trip`, from
`EVC_Radio_Authority.Unconditional_Stop_Accepted`) and shows the system
status message "Emergency stop" (DMI 15.1.1.5, `EVC_DMI_Port.SS_Emergency_Stop`
26; appended last to `Trip_Reason_T`, so the earlier positions of the
records keep their values). B525 done: the cause was not [43] but the
level crossing of message 24 never reaching the stores (packet 88 was not
in the list of `EVC_Radio_Authority.Take_Message`, part of B474), so no
temporary EOA became the former EOA of 5.8.1.9; packet 88 is passed now,
rejected while the Train Data are not acknowledged (4.8.3 [3]: without
it 4080300_07 regressed at step 75; decision: a message 24 whose other
packets are taken carries it along). B521 done: `EVC_Movement_Authority.Timer_Expiring`
counts the End Section's own Section timer (3.8.2.2.1 b excludes the End
Section timer T_ENDTIMER only). B526 dropped: the 132 found was sent in
level 2 before the transition; the runner's negative window starts too
early (B561). Scenarios: `Scenario_Emergency_Stops` (the reason),
`Scenario_LX_By_Radio` (4.8.3 [3], 3.12.5.8, 5.8.1.9, [43]),
`Scenario_MA_Request` (the End Section's timer). Left: B560 (the runner's
timer step T_SECTIONTIMER - T_TIMEOUTRQST, 3080200_01 family), B561, B562
(3100200_01 step 116: PT to FS where OS is awaited), and the two new
signatures S79f8dcc0, S88430f53 not analysed. SUBSET-076: 904 / 1205 /
1081 before, 910 / 1195 / 1085 after, 0 regressions, 24 improvements.
### The juridical recording in the SUBSET-027 message format (e5/jru-messages, 2026-10-16)

The decision of 2026-10-16 reverses the scope line of §1: the JRU port
emits the messages of SUBSET-027 4.2.2, one message a payload, of
variable length (`EVC_Ports.JRU_Max_Length` 1100 bytes, the old 16-byte
record is gone).

**Codec route: by hand.** `EVC_JRU_Messages` (evc/, SPARK, no state):
the generator of evc/language describes radio messages from chapter 7
variables of at most 64 bits; the JRU header has DRIVER_ID (128 bits),
DATE and TIME and V_TRAIN that are not chapter 7 variables, a part
conditional on Q_LRBG and messages that embed a telegram or a radio
message of up to 1023 bytes, and `ETCS_Bits.Writer` holds 1024 bytes
and returns its data by value. The unit has `Put_Bits` / `Get_Bits`
(MSB first, in place), `Put_Header` (fields 1 to 11 with the lengths
of 4.2.3; the "by analogy" variables with chapter 7's: Q_SCALE 2,
NID_SOLR / NID_LRBG 24, D 15, Q_DIR 2, Q_D 2, L_DOUBTOVER /
L_DOUBTUNDER 15, NID_ENGINE 24, M_VERSION 7, M_LEVEL 3, M_MODE 5: 311
bits, 386 with the LRBG part), `Put_Length`, `Set_Time`, the decoder
(`Is_Message`, `Get_Header`, `Body_Bit`) and `View`, the event of
EVC_Ports a message records with its three bytes, through which every
reader keeps working (no second parser). `Event_Message` maps an event
to its message.

**The messages.** 1 general (header only) at a mode change, followed
by the proprietary 255 of event 1 that keeps the level status (4.1.1.5
allows several messages for one event); 6 the telegram as received
(its bits after the BTM bit count); 9 NID_C, NID_RBC of the session
(`EVC_Radio.Info`) and the message as received; 11 M_DRIVERACTIONS;
13 NID_C, NID_RBC (decision: the Supervising RBC), M_ERROR; 20 all
eight variables from `SDM_Shown_T` (`EVC_Core.Put_SDM`: V_TARGET and
D_TARGET "none" 1023 / 32767 without a target shown, V_RELEASE 1023
while not shown, speeds at most 600, M_TTI at most 15); 24 Q_RBCENTRY,
NID_C and NID_RBC with Q 2 or 3, NID_RADIO with Q 3
(`EVC_JRU_Records.RBC_Entry_Fields`, B431 done); 30, 31, 32, 39, 51
their one variable; 38 with M_CAB_B_STATUS only for Q_CAB_B 1; 48
NID_MN; every other event of EVC_Ports as 255 (its number u8 and three
bytes): the ones with a SUBSET-027 message of their own are B550. The
readers' event numbers stay those of EVC_Ports (`View`: 21 for the
message 20, 124 for 24, 132 for 32, 2 for 6, 3 for 9), because 20, 24
and 32 are events of the on-board too; on the wire the numbers are
SUBSET-027's.

**Header.** Captured at the end of the cycle of the event
(`EVC_Core.Flush_Juridical`, the last step of `Produce_Outputs`), the
time of each message its event's (kept with it): the position from
`EVC_Position.Position_Report` (the computation of the position
report, not a second one), the LRBG the SOLR (Q_LRBG 1) unless
`EVC_Position.SOLR` is another group (Q_LRBG 2: the SOLR's identity,
distance and doubts in metres, its direction qualifiers unknown,
B552), Q_LRBG 0 and the values "unknown" without an LRBG; V_TRAIN in
km/h, 1023 at standstill; DRIVER_ID "?" x 16 while unknown; NID_ENGINE
`EVC_Radio.Engine_Id`; M_VERSION the operated version; M_LEVEL and
M_MODE as the position report codes them.

**UTC (decision).** `EVC_Core.Set_UTC (seconds since 2000-01-01)` at
the on-board time 0, forgotten by Initialise and Power_Up; until it is
given DATE and TIME are "unknown" (4.2.3.3, 4.2.3.4). The bench gives
2026-01-01 00:00:00 (`Sim_Onboard_Env.Reset`), so it stays
deterministic and Sim_JRU's time of day is the time since the reset;
the hosted port, the runner and evc_test give none (B553); E8's port
gives its clock.

**Outbox (decision).** `EVC_Outbox.Put_JRU` keeps a message (NID, the
time of its event, its complementary bits) in a queue of 4096 bytes
inside the outbox's state; `Flush_JRU` builds each message in a static
buffer of the outbox (no message on the stack) and puts it as a record
of the port JRU while the outbox (2048 bytes, unchanged) has room; the
others wait for the next cycle (4.1.1.4: within 5 s). A message the
queue cannot keep is lost and counted (`EVC_Outbox.JRU_Lost`). The JRU
messages of a cycle now come after its other outputs.

**Readers.** `EVC_Test_Support` (`JRU_Views` filled at `Parse`,
`Byte_At` of a JRU record its view, `JRU_NID`), the procedures' own
parser (`EVC_Test_Procedures.Collect`), `Sim_JRU` (the ring keeps the
view, NID_MESSAGE and the header's time of day; Describe names the
general message; the bench page and onboard_smoke read it unchanged),
`S076_Bench.Observe_JRU` (the view; the general message is not kept,
so the runner's record lists and counts are what they were),
`test/tools/golden_review.py` (`jru_view`, the same view in Python).
`S076_Run.Header_Field` still judges the header expectations from the
on-board's state: the message carries NID_LRBG, M_VERSION, V_TRAIN,
D_SOLR and the doubts now (B554).

**Scenarios.** `EVC_Test_JRU.Scenario_JRU_Format` (the header with and
without the LRBG part read back field by field, DATE and TIME, every
message of an event round trip to its view), `Scenario_JRU_On_Board`
(the general message of the power-up: UTC, SB, level 0, standstill,
the driver ID and the LRBG unknown); the power-up and isolation
scenarios of `EVC_Test_Core` count the general message.

**Goldens.** 13 on-board goldens re-recorded. Review
(`golden_review.py --base 846aba0`): 12 on-board groups; the tool pairs
by cycle groups that start at MSG_MODE_LEVEL, and the JRU records that
came first in a cycle now come last, so every group shows its records
moved one group; over all groups the records removed and added are the
same records (DMI, RTM, TIU payloads and JRU views equal, checked as
multisets) once the general messages are left out: as intended, the
side effect the move of the JRU records to the end of the cycle and
one general message per mode change.

### E5 integration after the twenty-seventh round (2026-10-16)

Decision of the round (the user, 2026-10-16): SUBSET-027's message format
is in scope; §1's line changed from "Out" to the JRU port emitting the
messages of 4.2.2.

Merged: e5/runner-e5-group (the runner's Level confirm selects the level
the steps settle on, B500; a step conditional on the initial mode is
skipped when the case began in another, `S076_Run.Initial_Mode_Excludes`,
B524; the whole remainder of the E5 group and the onboard group's stale
lines traced once each and sorted into twelve on-board lines by shape,
B580 to B591, one s076 case; B480 left), e5/level2-left (the level
crossing not protected substituted at once for a train beyond its start
at or below V_LX, 5.16.3.2, `EVC_SDM.LX_Substitution`, B513: the
regression of round 26 was a sequence passing only because a wrong brake
stopped the train, its speed being the tool's unrounded V_PBD, 3.11.11.6;
a group read while the linking is not checked ends the expectation
windows up to it without a reaction, 3.4.4.4.6 a),
`EVC_Position.Decide_Linking`, B522, nine sequences move; B527 dropped,
the runner answers 155 after the 15 s of A.3.1, B570; B528 not started),
e5/trips-ma (the unconditional emergency stop trip has its reason and
shows "Emergency stop", 4.6.3 [20], `EVC_Procedures.Trip_Reason_T`
`Emergency_Stop`, B520; packet 88 of message 24 passed to the stores and
rejected until the Train Data are acknowledged, 4.8.3 [3], so the former
EOA trip of [43] holds, B525, the brief's premise wrong; the End
Section's own section timer counted, 3.8.2.2.1 b), B521; B526 dropped,
the runner's window, B561; B560, B562) and e5/jru-messages (the
juridical recording in the SUBSET-027 message format: `EVC_JRU_Messages`
written by hand in SPARK, the generator's variables being chapter 7's of
at most 64 bits while the header has a 128-bit DRIVER_ID, DATE, TIME and
a part conditional on Q_LRBG; the header of 4.2.3 on every message,
captured at the end of the event's cycle from the position report, the
estimated speed, the driver ID, NID_ENGINE, the operated version, level
and mode; the bodies of 4.2.4 for messages 1, 6, 9, 11, 13, 20, 24, 30,
31, 32, 38, 39, 48 and 51; the other events carried as an interim message
255 with their old three bytes, B550; `EVC_Outbox.Put_JRU` with a
4096-byte queue drained over cycles under 4.1.1.4's five seconds, the
message built in a static buffer, `EVC_Ports.JRU_Max_Length` 1100;
`EVC_Core.Set_UTC`, the bench giving 2026-01-01, the other ports none yet,
B553; every reader through `EVC_JRU_Messages.View`, so the runner's
counts are unchanged; 13 on-board goldens re-recorded, as intended; B431
closed by the format; B551, B552, B554).

Merge by hand: the backlog three-way by id, the plan subsections
appended, two triage hunks resolved by signature id (the branch's version
of the lines it changed), the baselines merged by git and confirmed by
each union's run; no source conflict: the three on-board branches did not
add a JRU record call, so nothing had to be adapted to `Put_Event`.

Verification on the merged master: `test/check.sh` ok (evc_test 12189
checks, dmi_test 2168), the full proof 11828 checks, 0 unproved (margin
47726 steps), cross build and stack (worst case 27160 B, margin 5608 B:
the format cost 24 bytes), wasm and both smokes 0 failures. SUBSET-076:
904 / 1205 / 1081 before, 910 / 1185 / 1095 after, steps not judged 4434
-> 4467 (the conditional steps), 0 regressions, 0 untriaged. Matrix: 287
clauses left, unchanged (SUBSET-027 is not in the matrix; the rows touched
kept their status).

Measurements (requests by message id, duration, final context, cost):
jru-messages 210 / 52 min / 331k / 24.5 (budget 200, context past the
usual 200k: the format is one unit, one writer and six readers, and it
held); trips-ma 156 / 31 min / 198k / 10.8; level2-left 120 / 25 min /
164k / 7.0; runner-e5-group 86 / 20 min / 159k / 5.0. Every "Done" list
complete.

Lessons: a regression of a right fix can be a sequence that passed for a
wrong reason (3130700_04 stood still under a brake it should not have
had): the re-analysis from the regression found it in one trace where
the previous agent had reverted. Two of four brief premises wrong again
(B525's cause was a packet not passed, not the trip logic; the "124 and
132 disappear" claim: on the wire they do, the readers' view keeps them
because 20, 24 and 32 are also on-board event numbers). The interim
message 255 is a debt with a line (B550): every remaining event's body per
4.2.4 is the next JRU package, with the runner reading the header from
the message (B554). Open items: doc/BACKLOG.csv (52 open after this
round).

### The messages to the RBC by shape, the radio network and the connection, the track ahead free request (e5/rbc-messages, 2026-10-17)

B583 analysed, no on-board change: each of its seven shapes traced once at
its step (the scn's step and `var` block, the trace with the session table
and the LRBG). Two are the sequences': 4080421_02's case at 100 m leaves
out the 38 its message 32 (M_VERSION 3.0) asks, so the session ends by
3.5.3.7.4.1 before the entry to SH and no 150 can follow (5.6.2 A100);
4080421_01's message 9 carries packet 49 twice for one direction, refused
by 8.4.1.4 (M_ERROR 3), so no 138 is owed. Two are chapter 6 (E7): an RBC
of system version 1 in 6060303_01 (message 15 without D_REF, the 147's
translation of 6.6.3.4.5 [5]) and 6060304_01 (the 132 with packet 1 and
Q_TRACKDEL). One is the runner's: ours sends Q_STATUSLRBG 2, the runner
reads the step's binary 10 as decimal (B631). Two are ours and left:
the 147 of 3060800_01 rejects the stop because BG2d, a single group
linked in level 1, is not taken as LRBG in level 2 (B630; not the
runner's odometer impairment: the same without its error), and message
158 is not implemented (3.12.3.5.2, B632). A reading tried and withdrawn:
answering with 138 a request to shorten the MA that the mode alone
rejects (4.8.4, SH) had no sequence left to support it once the message 9
above was found inconsistent. B582 and B586 not started (budget).
### The level transition shapes, the mode profile in Post Trip, the MA with a shifted reference (e5/levels-shapes, 2026-10-17)

**B580** done, the six shapes decided from one trace each. Ours, three:
the level transition order of message 24 never reached the stores
(packets 41 and 46 added to the list of `EVC_Radio_Authority.Take_Message`,
5.10.1.2: 5100200_01, 5100400_08); with it, 4.8.4 [5] in PT (only the
announcement: `EVC_Levels.Take_Order`, `Take_Conditional`; without it
4080413_02 regressed); and an order at D_LEVELTR 0 is an immediate one,
kept in SH, PS and SM (4.8.4 [7]: 4100103_28). Decision: an order at
distance 0 from its reference is immediate for the filters of 4.8.4 [5]
and [7] (its location is passed when it is received; the sequences say
"D_LEVELTR = 0 or 32767"). The sequences' data, three (s076): 4070201_03
(BG3d's announcement places the border at 500 m, before the MA of 600 m:
the trip by 4.6.3 [39] is right), 5100300_08 (the train stopped on the
border announced in SL, where orders are accepted, 5.10.1.4.1),
5100200_09 (the second announcement replaces the first, 5.10.1.6).
Scenarios `EVC_Test_Levels.Scenario_Radio_Level_Orders`,
`Scenario_SH_Order_At_Zero`. Matrix: 4.8.4.2 footnote [5] done.

**B562** decided: the runner's model. The On Sight area of 3100200_01
starts 20 m ahead of the train's estimated front end; the step needs a
confidence interval the bench odometer (1 %) does not give; [31] is
right for ours (B620, runner). **B591** decided: the sequence's data
(after the cab change message 33 gives Q_DIR nominal for a train running
against its LRBG). **B581** first looks only (see its line).

SUBSET-076: 910 / 1185 / 1095 before, 925 / 1170 / 1095 after, 0
regressions, 21 improvements; baseline re-recorded. Edits outside the
units: `EVC_Radio_Authority.Take_Message` (two packet kinds and its
comment).
### Every juridical message with its SUBSET-027 body, the general message's triggers (e5/jru-bodies, 2026-10-17)

The messages now written with their 4.2.4 body: 2 the Train Data
(`EVC_JRU_Records.Train_Data_Body`, at their entry; decisions: the
categories and traction systems as packet 11 gives them, M_NOM_ROT_MASS
16 unknown, one brake configuration of the special brakes the train has,
a lambda train's service brake times those of the conversion model, a
gamma train's steps as at most seven sections, the correction factors
1.0), 3 and 4 the emergency and service brake command states when each
changes (`EVC_Core.Put_Brake_States`), 10 every message to an RBC as put
on the RTM port with the RBC of its session (`EVC_Outbox.Put_JRU_Sent`,
after `EVC_Radio.Drain`), 12 the balise group error (M_ERROR 0, linking
consistency) at an unexpected or missed group, 15 the cold movement
detector, 25 the SR speed and distance the driver entered (the national
values of an override keep the 255), 45 the whole list of the track
conditions for the external functions when an item appears or changes
its phase (`Track_Conditions_Body`: Q_SCALE 1 m, the TIU's distances),
47 the brake and traction interface of the installation configuration
(`Interface_Fields`), 49 NID_OPERATIONAL, 52 M_ERROR 9 or 10.
`EVC_JRU_Messages.Paired_Message` writes a message before the one of
`Event_Message` (1 at a mode change, 12 at events 5 and 6); `View` gives
the old events back for 2, 15, 25, 49 and 52 (their body holds the
three bytes); 3, 4, 10, 12, 45 and 47 have the view 0, like the general
message: where an event's three bytes carry more than SUBSET-027's
message (the brake reasons and supervision status of event 20, the
missed or unexpected kind of 5 and 6, the phase and id of each track
condition item of 45) the proprietary 255 stays after the message
(4.1.1.5), so no reader changed.

Triggers (4.3.1.1, `EVC_Core.Record_General`): the general message every
5 s after the last one (decision: two are never more than 5 s apart), at
a change of the operated version and of the level; 15 (0, or 2 without
information; a detected cold movement is the position's event 9) and 47
at the first cycle after Initialise or Power_Up. The hosted port gives
the host's UTC (`ports/hosted/evc.adb`, once a minute).

Still the proprietary message 255: the text messages 16 to 19 (B600: the
Q_TEXT of a fixed text and the text of a plain one are not kept after
the display), the linking reaction (4), the odometer back to nominal (7
with 0), new LRBG (10), the position status (8), the supervision (21),
overrun (22), procedures (23), stored information (32), configuration
(33), levels (40) and the other mission kinds (41): SUBSET-027 has no
message of their own (4.2.1). B552 (the SOLR's direction qualifiers)
not started.
### The header judged from the message, the runner's timing and window rules (e5/runner-header, 2026-10-17)

**Header (B554 done).** `S076_Bench` keeps every JRU message of the
window as received (the general message too, 2048 of up to
`JRU_Max_Length` bytes; `Message_Count`, `Message_NID`,
`Message_Header` through `EVC_JRU_Messages.Get_Header`), next to the
record list of the views, which is unchanged. `S076_Run.Header_Judge`
judges the fields of an ALL step that the header carries (the SOLR's
and the LRBG's, the doubts, Q_LRBG, V_TRAIN, M_VERSION, NID_ENGINE) on
one message holding them all (`Header_Value`, `Header_Holds`): a
number exactly (V_TRAIN 0 also the standstill 1023; the unknown NID
whichever way coded, B610), alternatives, "<>N", M_VERSION's X; a name
of the sequence ("<BG2>", "<updated>", "<D0>", the doubts' sums) the
field known, the names not resolved (decision); NID_LRBG / NID_SOLR
"<IDofthepassedBG>" and its kin against the group of the last telegram.
A step with no message in its window is not judged ("no message for
the header"). Decision: M_MODE, M_LEVEL and DRIVER_ID stay judged from
the on-board's state in the window (`Header_Field`): judged from the
messages they moved 9 sequences back and 12 on, the message's mode
being that at the end of its event's cycle and the sequences coding
some modes otherwise (M_MODE 21); left as is. `S076_Bench.Identity`
reads the event's bytes least significant first, as
`EVC_Position.Put_Identity_Event` and `View` write them (the LRBG / last
group comparison was unaffected, both swapped alike). The ALL. reasons
not judged: 224 steps before, 3 after, plus 29 without a message.

**Timers (B560 done).** `Timer_Input` runs T_SECTIONTIMER or T_EMA less
T_TIMEOUTRQST when the comment shows the second after a minus, its
garbled "'" or an acute accent, and knows T_EMA by name: 3080200_01,
3080200_07 and 3080400_03 pass, 3080200_03 moves to step 87, 3080200_02
to step 73 (a named timer run with the train moving). 3080400_14 step
72 is not a timer difference (Saeffd85e re-noted).

**Window (B561 done).** A negative RTM message expectation after a
balise group input has its window from the time of that input, after
`Apply_Input` moved the train there (`Group_Input_Ms`,
`S076_Bench.Now_Ms`): 4090100_01 moves from step 115 to 131.

**UTC.** `S076_Bench.Power_On` gives the bench page's reference
(2026-01-01 00:00:00 at the on-board time 0): DATE and TIME known in the
runner's messages (B553 noted).

**Counts.** 910 / 1185 / 1095 before, 919 / 1185 / 1086 after; steps
passed 202031 -> 202384, not judged 4467 -> 4388; 6 regressions
understood and re-recorded (4100103_47 passed because the bench forgot
the LRBG at its power-on: the header keeps the SOLR in SL, B611;
3131100_11 judged Q_LRBG 2 as "an LRBG known": the SOLR does not
separate from the LRBG, B612), 0 untriaged.

**Left.** B570 (the RBC's 32 given after A.3.1's 15 s): the trace
confirms the line; the fix designed but not built is a held RTM input in
the bench (`Hold_RTM` until the 155's time plus 14 s, the step of the 32
passing as given earlier or giving it then), the payload built by
`Radio_Input` for the later step. B480 (the negative JRU step after a
failed step): the mark goes before the `Wait_Cycle` loop of the output
steps in the step loop, and `Rec_Count` must honour it for both scopes
(the window's and `Location_Scope`'s records); 8 steps, all after a
first failure.

### E5 integration after the twenty-eighth round (2026-10-17)

Merged: e5/rbc-messages (B583's seven shapes decided, nothing fixed: two
the sequences' data, 150 after a session the case ends itself and 138 to
an inconsistent message 9; two chapter 6 (an RBC of system version 1,
E7); one the runner's reading of a binary Q_STATUSLRBG, B631; two ours,
the conditional emergency stop refused for want of an origin when a
single linked group is not the LRBG in level 2, B630, and message 158 not
implemented, B632; B582 and B586 not started), e5/levels-shapes (the
level transition order of message 24, packets 41 and 46, reaches the
stores, 5.10.1.2; in PT only the announcement is accepted, 4.8.4 [5],
done; in SH an order at D_LEVELTR 0 counts as immediate and is kept,
4.8.4 [7], `EVC_Levels.Take_Order`; B580's six shapes decided, three
fixed, three the sequences' data; B562 the bench's odometer accuracy,
B620; B591 the sequence's data; B581 first looks), e5/jru-bodies (the
SUBSET-027 bodies of messages 2, 3, 4, 10, 12, 15, 25, 45, 47, 49 and
52, `EVC_Outbox.Put_JRU_Sent` for the messages sent to the RBC; the
general message every 5 s and at a change of the operated version or the
level, 15 and 47 at start-up, 4.3.1.1, `EVC_Core.Record_General`; the
hosted port's UTC; B550, B551, B553 done; the text messages 16 to 19
left as B600, B552 left; B601 the correction factors of message 2
recorded as 1.0, an integration finding) and e5/runner-header (the
header expectations judged from the messages, `S076_Run.Header_Judge`
through `EVC_JRU_Messages.Get_Header`, 224 steps, B554; the timer
difference of a step naming two timers, B560; the negative RTM window
after a balise group input, B561; the runner's UTC; the identity byte
order; two passes for a wrong reason exposed by the header, B611 (the
SOLR kept in SL after a power-up) and B612 (an unlinked group as SOLR);
B570 and B480 designed, not built; B610).

Merge by hand: the backlog three-way by id (B553 joined from two sides),
the plan subsections appended, no triage or source conflict, the
baselines merged by git and confirmed by each union's run.

Verification on the merged master: `test/check.sh` ok (evc_test 12224
checks, dmi_test 2168), the full proof 12060 checks, 0 unproved (margin
47726 steps), cross build and stack (worst case 27200 B, margin 5568 B),
wasm and both smokes 0 failures. SUBSET-076: 910 / 1185 / 1095 before,
934 / 1170 / 1086 after, steps not judged 4467 -> 4365, 0 regressions, 0
untriaged. Matrix: 287 clauses left (one deferred row done, 4.8.4.2 [5]).

Measurements (requests by message id, duration, final context, cost):
jru-bodies 160 / 29 min / 246k / 13.7; runner-header 118 / 30 min / 198k
/ 8.3; levels-shapes 122 / 19 min / 199k / 8.3; rbc-messages 149 / 19
min / 181k / 9.2. Every "Done" list complete.

Lessons: the JRU header is a second witness: judging it from the message
exposed two sequences that passed on the on-board's state alone (B611,
B612). A shape line of "first looks" (B580, B583) costs a trace per shape
to decide and most decisions are data or another phase: three of six and
two of seven were ours; a brief should expect that ratio and size the
package by the traces, not by the fixes. The brief premise "ours switches
at about 602 m" was wrong (500 m, from the announcement), the trace found
it. Open items: doc/BACKLOG.csv (51 open after this round).

### Round statistics (2026-10-18)

The process of the rounds is measured, not remembered: `doc/ROUNDS.csv`,
one row per agent, kept by `test/tools/rounds.py`. `rounds.py measure
<transcripts>` fills the measured columns from the agents' transcripts
(the session keeps them under its `subagents/` folder): the package and
round from the launch prompt, the round briefs, the plan's headings and
the round start stamps; the budget from the prompt or the package brief;
the model, the agent type (the session's meta file), the initial context (the first request: the prefix of the agent type with its prompt), the requests, duration, final context and cost from the usage records;
the tool mix from the tool_use blocks, and inside Bash the runs of
`outline.py`, `clause.py`, grep, `sed -n`, the commits, the proofs, the
runner and the whole check; the report's premise mentions. The judgement
columns are the coordinator's at integration: items assigned, done,
dropped, left; the brief's premises stated and wrong; the sequences
moved; the regressions explained; the backlog lines added; the edits
outside the units; the merge conflicts; the "Done" list. `rounds.py
report` aggregates per kind and per round; `--check` is in the whole
check. The round brief's lessons paragraph cites the report from round
29 on.

Backfill: 158 agents of this session measured, 139 of them in the phases
E0 to E4, the preparation and the E5 rounds 1 to 28 (round 4's three
transcripts are not in the session's folder); the judgement columns
filled for rounds 26 to 28 only.

First findings: the budget has been a wish, not a bound: 47 of 64
on-board agents and 16 of 30 runner agents of the numbered rounds used
more calls than their brief gave, the mean on-board agent 140 against a
mean budget of 121, and the overrun did not shrink as the budgets grew
from 100 to 130. The guidance "outline.py over grep and sed" is not
followed: an on-board agent runs grep 77 times and `sed -n` 40 times per
package against 9 `outline.py` runs; a runner agent 64 and 28 against 5.
Cost runs at 16 to 20 USD per agent-hour whatever the kind. Where the
judgement columns are filled (three rounds): 9 of 42 on-board brief
premises were wrong (21 %), 1 of 14 runner ones; on-board items convert
at 52 % with 82 calls and 5.5 USD per item done, runner items at 54 %
with 16 calls and 0.9 USD; a sequence moved costs 3.0 USD on the
on-board side and 1.0 on the runner's.

### The RBC's answer in time, binary field values, the negative record window, the bench's odometer accuracy (e5/runner-timing, 2026-10-18)

**Binary values (B631 done).** `S076_Run.Radio_Expect`'s `Matches`
reads a field text of 0 and 1 exactly as long as the variable
(`ETCS_Variables.Bits`) as a bit pattern: as decimal it would exceed the
variable (Q_STATUSLRBG=10 is 2, unknown, 7.5.1.137). 5040300_16 moves
from step 83 to 89 in all three versions (S6a1a136d: the JRU header
codes the SOLR unknown after a power cycle where the sequence keeps the
stored position; onboard, kin of B612); 5040300_03 stops at step 51
before its binary field (B581).

**The answer in time (B570 done).** `S076_Run.Hold_Answer`, called
before each step, arms the answer to a question with a waiting time of
A.3.1 that ends the session: the system version (32) to the initiation
(155), 3.5.3.7.3, and the acknowledgement of the session establishment
(38) to the session established report (159), 3.5.3.7.4, when the
first radio step ahead gives it (only driver, odometer, balise and train
interface inputs and negative radio expectations between). `Radio_Input`
builds the message stamped for its time, the question's time plus 14 s,
and `S076_Bench.Hold_RTM` gives it at the first cycle then;
`New_Window` keeps the records, JRU messages and radio messages since
until the answer's step, which passes as "given earlier" (or gives it at
once when the hold has not fired). Decision: 8 to 129 and 24 to 132
have no waiting time that ends the session, not held. 3050300_19 58 ->
72 (S9e1b46dc: the MA of message 3 refused in SR level 2 at standstill,
first look, onboard), 3050300_02 57 -> 97 (Sce3c7004, B582), all three
versions.

**Not built.** B480: the steps it names come after their sequence's
first failure and the step before them fails on its own (ours keeps the
LSSMA shown), no sequence would move. B620: neither the sequences nor
the workbooks give the reference odometer accuracy; 5 % in place of
1 % gave 41 improvements (3100200_01 passes) and 8 regressions, not
analysed (listed in B620); kept at 1 %.

**Counts.** 934 / 1170 / 1086 before and after (steps passed 202488
and failed 14170 after), 9 improvements, 0 regressions, 0
untriaged.
### The mode profile shapes, the trip shapes, the Train integrity button, the planning gradients (e5/shapes-2, 2026-10-18)

Nine shapes, one trace each, decided with their clause: one ours and
fixed, one ours and left (another package), seven the sequences' data.

| shape | decision |
|---|---|
| 4100103_27 step 44 (B584) | s076: BG7d gives OS from D_MAMODE 0 where the text says SH beyond; OS at once in level 1 (5.9.2.1) |
| 3130700_06 step 39 (B584) | s076: one group with the MA and OS at D_MAMODE 0 (5.9.2.1); the sequence records OS at step 52, the columns of the rows splitting the group keep SR (B661, runner) |
| 5190200_03 step 94 (B584) | s076: the LS area left, FS recorded at steps 95-97 under LS columns (B661) |
| 4100103_42 SV21/22 step 95 (B584) | s076: the MA by radio ends the override (5.8.4.1 f) and gives FS by 4.6.3 [31] |
| 3040200_03 step 137 (B584) | s076: message 33 with Q_DIR nominal for a train running against its LRBG after the cab change (as B591) |
| 4080421_02 SV21/22 step 101 (B585) | ours, fixed: packet 49 sent by radio with the MA of an SH mode profile is the list for the SH area (4.4.8.1.1 b), 4.4.8.1.8); to step 174 |
| 9990400_49 step 162 (B585) | s076: message 153 places the EOA 300 m behind the train; in OS [16] trips in level 2 |
| 3060500_05 step 73 (B587) | ours, left: the DMI's condition is right; the on-board never sets the RBC bit 3 of MSG_ONBOARD and has no train integrity reporting (3.6.5.2, deferred): B660 |
| 4080416_01 step 71 (B589) | s076: the step's NOT contradicts its comment (a gradient profile is shown); message 24's packet 21 replaces the gradients (3.7.3.1 b) |

The fix: `EVC_Stored_Information.Take_Radio_SH_List` keeps packet 49 of
a radio message whose MA was accepted (the country of the LRBG unless an
item gives another), `EVC_Procedures.Take_MA_SH_List` makes it the
stored list in the same cycle, as a list read from a balise group
(`Take_P49`). Decision: the list is taken only with an accepted MA (it
comes "together with the order", 4.4.8.1.8; the order is the mode
profile of the MA). Scenario `EVC_Test_Shapes.Scenario_Radio_SH_List`
(a new test package). Matrix: 4.4.8.1.1 b) note extended. Backlog:
B584, B585, B587, B589 done; B660 (train integrity reporting), B661
(the runner's mode window) added.
### The text messages' bodies, the correction factors of message 2, the SOLR's qualifiers and choice, the position deleted in SL (e5/jru-left, 2026-10-18)

Done: the text messages 16 to 19 (SUBSET-027 4.2.4.16 to 4.2.4.19) at
the start and the stop of a display, Q_TEXT of a fixed text, L_TEXT and
X_TEXT of a plain one, before the record 255 of event 24
(`EVC_Core.Record_Text_Display`; `EVC_Text_Messages` keeps the text of
each record of the cycle, `Event_Q_Text`, `Event_Length`, `Event_Text`,
since a removed message is gone by the time the recording reads it;
B600). Message 2: the correction factors 1.00 are what the on-board
applies (the default of `Train_Data_Extra_T`, never set from the Train
Data; M_KDRY_RST and M_KWET_RST have no unknown value), named
`EVC_JRU_Records.No_Correction`; decision: N_BRAKE_CONF (4 bits, 1 to
16) codes the number minus one, 0 for the one configuration (B601). The
header's unknown SOLR or LRBG is 16777215 as 7.5.1.90 codes NID_LRBG
(B610; 13 goldens, the header field only). `EVC_Core.SOLR_Reference`
gives Q_DIR and Q_D against the SOLR's direction (7.5.1.104, .106),
unknown where the SOLR has no direction or the orientation is unknown
(B552). Entering SL deletes an invalid position (4.10.1.3 Table, column
SL, note [1], `EVC_Core.Delete_Invalid_Position`; 4100103_47 passes;
B611). B612 is the sequence's data: its BG4d is marked linked and has
no packet 5 (the text says Q_LINK=0 with packet 5); with the linking
exhausted ours rightly takes it as LRBG and SOLR; an unlinked group does
give Q_LRBG 2 (`EVC_Test_Position.Scenario_SOLR_Unlinked`), Sc3e96504
triaged s076.
### Message 158, the origin of an emergency stop, message 24's packets one by one, the track ahead free request (e5/rbc-left, 2026-10-18)

B632 done: `EVC_Text_Messages` keeps NID_C / NID_RBC of a text's report
request and lists the acknowledgements of the cycle (`Ack_Report`);
`EVC_Sessions.Reports.Produce_Text_Acks` sends message 158 with the
position report to the session established with that RBC (3.12.3.5.2,
8.6.16). Decisions: no session with that RBC, no report (3.12.3.5.2
names no wait); none to an RBC of system version 1 (6.6.3.2 [6] sets
Q_TEXTREPORT to 0; 6060304_05 step 79). Scenario
`EVC_Test_Sessions.Scenario_Text_Ack_Report`. B630 dropped: 3060800_01's
BG1d (read in SR level 1, its linking accepted there by 4.8.1.3.1)
announces BG2 at D_LINK 0 with Q_LOCACC 10 m while BG2d lies at 1000 m,
so BG2d is rejected by 3.4.4.4.3.2 and is not LRBG compliant; the
sequence's data, Sa32fcae0 triaged s076. B474 / B512 done packet by
packet (`EVC_Radio_Authority.Take_Message`, one sv30 run per family):
21, 27, 39, 40, 65, 66, 68, 69 (and 70, 180 moved there) under the
Train Data guard of 4.8.3 [3] (the 4080445_01 step 85 family was a
message 24 with packet 68 before message 8), 64, 67, 71 without it (no
[3] in their rows); scenario `EVC_Test_Authority.Scenario_Track_Condition_By_Radio`;
golden received_telegram_message: two stored information records added
(the TSR of its message 24 stored; a group record "no origin" for its
NID_LRBG 0), as intended. Left (B640): 51 and 52 (applied at once in
level 1 with level 2 announced, 4080300_03 step 105, where 4.8.3 [2]
keeps them for the transition), 3, 5, 57, 138, 139. B586 in part:
9990500_02's message 34 is an all-default extraction (NID_LRBG 0,
Q_SCALE 0, Q_DIR 0), the sequence's data; 9990500_16 not traced. New:
B641 (packet 132 in SH level 0 trips where 4080300_04 expects it
rejected), B642 (4080445_02's track condition symbol bits). SUBSET-076:
934 / 1170 / 1086 before, 952 / 1152 / 1086 after, 0 regressions, 43
improvements.

### E5 integration after the twenty-ninth round (2026-10-18)

The first round whose briefs cited doc/ROUNDS.csv: a budget declared a
bound with a stop at 80 %, and the reading rule (outline.py before grep
and `sed -n`) spelled out, both in the round brief.

Merged: e5/runner-timing (binary field values compared as bit patterns of
the variable's width, B631; the RBC's answer to a question with a waiting
time of A.3.1 held and delivered in time, 32 to 155 and 38 to 159,
`S076_Run.Hold_Answer`, `S076_Bench.Hold_RTM`, B570; B480 moves no
sequence, B620 tried at 5 % with 41 improvements and 8 regressions, both
left), e5/shapes-2 (the list of balise groups for the SH area sent by
radio with the MA stored and used, 4.4.8.1.1 b),
`EVC_Stored_Information.Take_Radio_SH_List`; of nine shapes one fixed, one
ours as B660 (train integrity reporting), seven the sequences' data or
extraction; B661), e5/jru-left (the text messages 16 to 19 with their
bodies, `EVC_Core.Record_Text_Display`, B600; message 2's factors as the
on-board applies them and N_BRAKE_CONF as the count minus one, B601; an
unknown reference coded 16777215, B610; the SOLR's qualifiers, B552; B612
the sequence's data; an invalid position deleted on entering SL,
4.10.1.3 [1], B611: all six done) and e5/rbc-left (message 158 reporting
the driver's acknowledgement of a text to the RBC of the request,
3.12.3.5.2, done; message 24's packets passed family by family under the
Train Data guard, B474 and B512 done, 51 and 52 left for the transition
buffer as B640; B630 the sequence's data; B586 traced in part; B641,
B642).

Merge by hand: the backlog three-way by id, the plan subsections
appended, two triage hunks by signature id, one source conflict (both
sides appended declarations to `EVC_Text_Messages`: both kept), one
golden on two sides (received_telegram_message: re-recorded for the union
and reviewed, as intended, the two stored information records of the TSR
and the no-origin group), and one signature renamed by the union (the
unknown coding of B610 changed the text of 5040300_16's failure: a triage
line pointing at the old one).

Verification on the merged master: `test/check.sh` ok (evc_test 12273
checks, dmi_test 2168), the full proof 12141 checks, 0 unproved (margin
47726 steps), cross build and stack (worst case 27200 B, margin 5568 B),
wasm and both smokes 0 failures. SUBSET-076: 934 / 1170 / 1086 before,
955 / 1149 / 1086 after, steps not judged 4365 -> 4369, 0 regressions, 0
untriaged. Matrix: 287 clauses left (3.12.3.5.2 deferred -> done).

Measurements (doc/ROUNDS.csv, measured from the transcripts): rbc-left
174 calls / 28 min / 243k / 12.3; jru-left 188 / 26 min / 226k / 13.3;
shapes-2 185 / 25 min / 235k / 13.0; runner-timing 135 / 20 min / 183k /
7.4; all four over the budget of 130 (the "Done" lists complete all the
same). The agents' self-counts were 135, 112, 128 and 112: under the
measured by 25 to 45 %. grep runs 90, 81, 102 and 55 against outline.py
4 to 15; `sed -n` down to 6 to 13.

Lessons: a rule written in the round brief changed little in one round:
the budget was exceeded by every agent, and the agents believed they were
within it because they count only what they notice; the stop at 80 %
needs a count the agent can see (the harness gives none), so the next
brief asks the agent to count its own Bash calls in a running tally in
the response text, or the budget is dropped as a bound and the packages
are sized instead. `sed -n` on sources fell by half once named; grep did
not, because the agents grep the scn and csv files, which the rule
allowed: the count must separate the sources from the data files before
it can be judged. Of 23 brief premises 10 were wrong this round, 7 of
them the first-look shapes of B584 to B589: a shape line's "ours" is a
guess until traced, so a shapes package is an analysis package and should
be budgeted and named as one. Open items: doc/BACKLOG.csv (40 open after
this round).

### The level symbol, network and connection, status message and JRU call shapes (e5/shapes-3, 2026-10-18)

An analysis package: seventeen shapes of B581, B582, B588 and B590, each
traced once on master to its step (all still failed there; 4080429_01's
shape is SV21/SV22 only, SV30 fails later), decided with its clause. No
code change; triage and backlog only (B700 to B710).

| shape | decision |
|---|---|
| 4080429_01 SV21/22 step 52 (B582) | E7: BG22d's packet 45 is of system version 2 (L_PACKET 47, no Q_NETWORKTYPE), read in the 4.0 layout; 6.6.3.2.3 [23] / 6.6.5.2.7 (B703) |
| 3050300_18 step 60 (B582) | model: the runner puts the min safe rear end at the step's 300 m, the border is at 250 m; ours releases at the rear's passage (3.5.3.8 d)), before the step (B701) |
| 3050600_03 step 45 (B582) | model: the feature's laboratory has the Radio Network type FRMCS+GSM-R, FRMCS never registered: 3.5.6.7 b) holds the set-up; the runner keeps the default GSM-R (B700) |
| 5070300_02 SV21 step 77 (B582) | ours: packet 42 of message 24 taken whatever its Q_DIR (3.6.3.1.3, EVC_Sessions.Take_Radio_Order; also 45, 131) (B702) |
| 3050600_06 step 55 (B582) | model: 5.4.3.2 D7 / S4 waits with the type FRMCS+GSM-R (B700) |
| 4050200_11 step 88 (B588) | s076 (decision): the step's comment says the error over 5000 m still exceeds 250 m after SB is left; 3.6.8.5 is active in SR by 4.5.2 |
| 4041800_02 step 71 (B588) | ours, first look: EB before the RV distance of the relocated area ends, the message not shown (3.15.4.8) (B704) |
| 5040300_25 step 100 (B588) | model: FRMCS not installed by the runner outside feature 3050600 (B700) |
| 3120300_06 step 55 (B588) | ours, to be read: the end condition by level or mode other than the current (3.12.3.4, 7.5.1.73) (B710) |
| 5220200_01 step 43 (B588) | ours, to be traced: JRU 23 kind 9 recorded, the symbol not shown (5.22.4.1) (B705) |
| 3060600_01 step 150 (B590) | ours: no record 11 for Geographical Position (B706) |
| 3131040_44 step 47 (B590) | ours: no record 25 at the modification of the SR values in SR (B707) |
| 4080445_01 step 103 (B590) | ours: record 45 written in OS where none is expected (B708) |
| 5181000_02 step 46 (B590) | ours: record 45 TI 1 not written at the announcement, 6 sequences (B708) |
| 5170200_03 step 32 (B581) | s076: step 28 shows a valid L0, step 32 assumes it invalid (two cases' initial states) |
| 5040300_03 step 51 (B581) | ours: the 5.4.3.3 table after D2 sets the level invalid with the position unknown; ours keeps L2 (B709) |
| 3131050_23 step 50 (B581) | not traced (budget) |

Of the sixteen decided (all triaged onboard before), seven are the
runner's (4), the sequences' (2) or chapter 6 (1); nine are ours (B702,
B704 to B710), five of them still first looks to be traced. B582, B588 and B590 done, B581 open for
3131050_23. The runner's summary does not move (no code change).
### The transition buffer for radio packets 51 and 52, the danger for shunting packet in SH, the track condition bits of record 21 (e5/buffer-radio, 2026-10-18)

B640 done: the rows "Axle Load speed profile" and "Permitted Braking
Distance Information", From RBC: Yes, of 4.8.3 (A [3] in level 2, R [2]
elsewhere) as `EVC_Radio_Acceptance.Level_2_Track_Filter`; a message 24
with packet 51 or 52 in level 0 or 1 with level 2 announced is kept whole
in the transition buffer (`EVC_Radio_Authority.To_Buffer`; decision: its
other track description packets carry R [2] as well) and taken at the
transition; outside level 2 the packets are rejected
(`EVC_Radio_Authority.Take_Message`, `EVC_Stored_Information.Take_Radio`
for a message 24 taken for its other packets). The premise of the brief
was wrong for 4080300_03 step 82: level 2 is not announced there (BG7d
orders it immediately), the packet is rejected, as its comment says; its
step 212 is the stored case (announced by BG10d, applied at BG11d).
Scenario `EVC_Test_Authority.Scenario_PBD_By_Radio_Buffered`.
B641 done, ours: 4.8.3 [13] was not applied (a decision of E4, "on the
safe side"); BG5d carries packet 132 without a level transition order
(rejected in level 0), BG6d with an immediate order to level 1
(accepted, the trip). `EVC_Acceptance.Danger_Order_Accepts`,
`EVC_Procedures.Orders_L12_Now` (decision: level 1 or 2 anywhere in the
order's list; immediate: D_LEVELTR now or 0, as `EVC_Levels.Take_Order`);
`EVC_Test_Procedures.Scenario_Shunting_Trips` checks both cases, and lost
its level 0 check of 4.6.3 [62] (B680). New signature S6f9ed66d behind it
(B681, triaged onboard). B642 not started (budget). SUBSET-076: 955 /
1149 / 1086 before and after, 0 regressions, 5 improvements (4080300_04
171 -> 224 in SV22 and SV30, 4080408_01 103 -> 124 / 134).
### The bench's odometer accuracy from its regressions, the mode window of the columns, two data checks (e5/runner-odometer, 2026-10-18)

**The odometer accuracy (B620 done).** The regressions of the 5 % trial
traced: 5090200_01 (OS entered earlier, so T_ACK and its service brake
come before step 58's window), 5180400_01 (the announcement of the
second non-stopping area expected removed at its start, 1400 m, the
estimated location) and 3131040_98 (a trip between the case boundary at
948 m and 1150 m) place max safe front end events at their estimated
location, i.e. assume a small interval; a sweep at 20, 30, 40 and 50 per
mille regressed at every value (4080300_16 from 20 to 40), and the
workbooks' odometer inaccuracy cells (0, for the braking calculation)
separate nothing. Decision: the bench keeps 1 %; a sequence whose step
comment says the confidence interval "already overlaps" an area ahead
gets the bound of SUBSET-041, 5 % (`S076_Run`,
`S076_Bench.Accuracy_Bound_Per_Mille`). 3100200_01 passes in the three
versions; 4080300_17 changes its signature at step 88 (S9f5e2e5c,
onboard, first look: OS expected with the max safe front end in the OS
area and the min safe front end in the LS area, ours stays LS).

**The mode window (B661 done).** `S076_Run.Columns` takes a row that
continues a balise group (an input `BTM balise-group` without telegrams,
`Continues_Group`) as part of its input's block, and judges a mode its
columns contradict on the sequence's own latest expectation of the mode
under the same columns (`Expected_Modes`: the DMI mode symbol displayed,
a JRU record's M_MODE). 3130700_06 39 -> 92, 5190200_03 94 -> 96,
3131020_02 passes, 5060400_01 40 -> 126, 6060302_05 39 -> 74, 4080417_01
107 -> 151 (S301ac019, onboard, first look: TR where UN is expected).

**Data checks.** B586: 9990500_16's packet 90 fields are right (800 /
190 end where the comment's 900 / 90 do, 990 m from BG5d, and the
display begins at step 84's 1300 m); the request is to go at step 88
because BG6d, linked at 1500 m and read at 1450 m inside its window, is
relocated by the linking distance (3.4.4.1.1, 3.6.4.2.5 a)); ours keeps
the measured position: B720 (onboard). 9990500_02 the data (S3e2df66d
s076). B480 dropped (moves no sequence).

**Counts.** 955 / 1149 / 1086 before, 961 / 1143 / 1086 after (steps
not judged 4369 -> 4375), 21 improvements, 0 regressions, 0 untriaged.
### Train integrity reporting, the MA refused in SR level 2, the SOLR over a power cycle (e5/integrity, 2026-10-18)

Done: train integrity reporting (3.6.5.2.2 to 3.6.5.2.6, 3.6.5.1.4 c)
and d); B660). `EVC_Sessions.Integrity` (a private child, its state part
of the parent's) keeps the status of Table 2b, moved each cycle by the
conditions of Table 2c in their priorities, and the confirmed train
length of Figure 15 (the min safe rear end when the train was last known
to be integer to the estimated front end now, rounded up to the metre);
`EVC_Sessions.Reports.Send_136` writes Q_INTEGRITY and L_TRAININT into
packet 0 or 1 and reports [5]; the driver's confirmation and a loss
request a report. The external source is the new TIU signal 14
(`EVC_Ports`: value 0 unknown, 1 confirmed, 2 lost), latched by
`EVC_Core.Handle_Input` and handed by `Read_Ports` to
`EVC_Sessions.Take_Integrity_Input`; each input is one reception of
the information. `EVC_Core.Send_Onboard` sets the RBC bit 3 of
MSG_ONBOARD (the train length and the under-reading amount within
L_TRAININT's 32767 m), which the DMI's Train integrity button needs
(11.2.3.5 #3); bit 4 stays 0. Decisions in the unit's header: the safe
consist length and SM are not modelled (3.6.5.2.5 and Table 2b partial);
[2] asks the position valid and referred to an LRBG (3.6.5.2.7); a
reverse movement is one towards the cab not active. Scenario
`EVC_Test_Sessions.Scenario_Train_Integrity`.

For the runner's owner: the TIU input "train integrity" is
`S076_Bench.TIU_Input (14, 1 | 2 | 0)`; `S076_Run.TIU_Input` still
answers "not modelled" for "TIU train-integrity" (B690). JRU message 50
is not written (B691).

Left: S9e1b46dc (3050300_19 step 72, the MA of message 3 refused in SR
level 2) and S6a1a136d / Se8e0d3d0 (5040300_16 step 89, the SOLR after a
power cycle) were not traced: the budget went to B660.

### E5 integration after the thirtieth round (2026-10-18)

The round of the tally: every Bash call's description carries the
agent's own ordinal, so the agent sees its count and the measurer checks
it; the budget a bound at 80 %; the reading rule with the source-tree
counts named.

Merged: e5/shapes-3 (an analysis package: sixteen of seventeen shapes
decided, nine ours as B702 and B704 to B710, four the runner's as B700
and B701, two the sequences' data, one chapter 6 as B703; 3131050_23
left), e5/buffer-radio (packets 51 and 52 of message 24 taken in level 2
under the Train Data guard and kept whole in the transition buffer when
level 2 is announced, 4.8.3 [2] [3], B640; packet 132 accepted only with
an immediate order to level 1 or 2, 4.8.3 [13] done, B641; B642 not
started; B680, B681), e5/runner-odometer (the bench's odometer accuracy
at 5 permille, SUBSET-041's bound, only for a sequence whose comment says
the confidence interval already overlaps the area ahead, B620; a step
whose mode columns contradict the window's own expectation judged on the
expectation, `S076_Run.Columns`, B661, six sequences move; B586 done, its
second sequence ours as B720, the position not relocated over a linked
group; B480 dropped) and e5/integrity (train integrity reporting, 3.6.5.2
with Table 2b and 2c, `EVC_Sessions.Integrity`, Q_INTEGRITY and
L_TRAININT in the position report, the TIU signal 14, the RBC bit 3 of
MSG_ONBOARD; B660 done, 12 rows done and 2 partial; S9e1b46dc and
S6a1a136d not started; B690, B691).

Merge by hand: the backlog three-way by id, the plan subsections
appended, two triage hunks by signature id, no source conflict, the
baselines merged by git and confirmed by each union's run.

Verification on the merged master: `test/check.sh` ok (evc_test 12301
checks, dmi_test 2168), the full proof 12205 checks, 0 unproved (margin
47726 steps), cross build and stack (worst case 27200 B, margin 5568 B),
wasm and both smokes 0 failures. SUBSET-076: 955 / 1149 / 1086 before,
961 / 1143 / 1086 after, steps not judged 4369 -> 4371, 0 regressions, 0
untriaged. Matrix: 289 clauses left (287 before: 15 deferred rows of
3.6.5.2 entered the count, 13 done and 2 partial, and the two partial
ones count as left).

Measurements (doc/ROUNDS.csv): buffer-radio 130 calls / tally 132 / 176k
/ 7.0 USD; integrity 126 / 122 / 181k / 7.8; runner-odometer 109 / 107 /
165k / 5.9; shapes-3 96 / 97 / 145k / 4.8 (budget 110). No agent over its
budget (round 29: four of four), the tallies within four calls of the
measured, the round at 25.5 USD against 45.9. Reading on the source
trees: grep 19, 44, 6, 7 and `sed -n` 13, 13, 10, 8 per agent: two
reading failures by the rule (buffer-radio, integrity).

Lessons: a count the agent can see works where a rule it cannot check
did not: the tally brought every agent inside the bound in one round and
halved the round's cost without a visible loss of output (14 items
assigned, 9 done, 2 of 3 on-board packages complete). The reading rule
on sources still fails for the agents that build (grep 19 and 44), not
for the ones that trace: the next brief asks for the `outline.py` run
before each grep by name in the description, or accepts that a builder
greps. The analysis package (shapes-3) converted 16 of 17 shapes at 6
calls each and found 9 defects: a line of first looks is best spent that
way, not fixed in passing. Brief premises wrong: 10 of 26, 7 of them
shapes. Open items: doc/BACKLOG.csv (46 open after this round).

### The direction of radio orders, the relocation over a linked group, the level after an unknown position (e5/radio-dir, 2026-10-19)

**B702 done.** Packets 42, 45 and 131 of an RBC message are taken only
when valid for the train orientation relative to the LRBG the message
names (3.6.3.1.1 a), 3.6.3.1.3): `EVC_Position.Radio_Valid_For` (the
group's orientation as `Radio_Origin` finds it, without allocating an
origin) in `EVC_Sessions.Take_Radio_Order`, `Take_Radio_Transition` and
`EVC_Sessions.Network.Take_Radio_Order`, the LRBG through the new
`EVC_Sessions.Last_LRBG`. Decision: with the group's orientation or the
train's not known the order is taken (3.6.3.1.4 read for location based
data; a first version rejecting it regressed 3131100_08 and 4100103_28
in three versions, which expect the order taken). Scenario: an order for
the reverse direction of the LRBG ignored, `Scenario_Session_Reports`.
5070300_02 SV21 and SV22 pass.

**B720 traced, not started.** The premise was wrong: the relocation by
the linking distance exists (`Relocate_Item`, 3.6.4.2.5 a)); the linking
of 9990500_16 comes by radio (message 24, packet 5), and no radio
linking is taken anywhere (`EVC_Radio_Authority.Take_Message` lists
packet 5 as not taken). New item B730.

**B709 traced, not started.** 5040300_03 has no power cycle: the second
start of mission follows a closed desk in SB, so `Revalidate_Kept` is
not the path; D2 of `EVC_Mission` is (another package's unit this
round). The table of 5.4.3.3 needs the PDF layout (the markdown columns
are shifted).
### The runner's integrity input, radio systems and network type, the border reach-point, three traces (e5/runner-net, 2026-10-19)

Runner only, no evc/ edit. B690 done: `S076_Run.TIU_Input` feeds "TIU
train-integrity confirmed / lost / unknown" as the TIU signal 14 (1 / 2 /
0); 3060500_06, _10, _14 in three versions and 4050200_05 move, 3060500_14
now fails at step 74: the re-validation of Train Data from an external
source is requested (5.17.2.2 D9) but the Train Data window not shown
(S4ec90124, B760, ours, first look). B700 done: `S076_Bench.Set_Network_Type`
(the configured default type of 3.5.6.4); feature 3050600 runs with both
systems and FRMCS+GSM-R: 3050600_03 passes in three versions; 3050600_06
step 55 is the runner's clock against the A.3.1 registration time (ours
times out at 40 s from power-up before the sequence's own timer step,
B761); 5040300_25 needs FRMCS registered before its power cycle and failing
after it, which the port cannot give (B762; both systems there regress it
to step 55). B701 done: packet 41 of BG3d puts the border at 300 m, the
step's own 300 m, and the rear end placed there stops a few decimetres
short of the on-board's passage (length and under-reading amount from the
front's passage); `S076_Run.Reach_Border_Rear` runs on until
`EVC_Level_Sessions.Exit_Phase` leaves Border_Ahead: 3050300_18 passes in
SV22 and SV30; 4050200_04 (three versions) now fails at step 88, ours: the
136 at the rear's passage sent in NL, where 5.10.3.6.2, 5.10.3.3.3 and
5.10.3.10.3 ask it of the leading engine only (B763).

SUBSET-076: 961 / 1143 / 1086 before, 968 / 1143 / 1079 after, steps not
judged 4371 -> 4381, 16 improvements, 3 regressions understood (B763),
baseline re-recorded, 0 untriaged.

Left (the budget's bound reached): the three traces, 3131050_23 step 50
(Sb12d0fcd; first reading: steps 41 to 48 feed a balise group without a
name, the sequence's BGa, whose packet 41 announcement must not be shown),
3050300_19 step 72 (S9e1b46dc) and 5040300_16 step 89 (S6a1a136d).
### The reversing distance, the BMM inhibition symbol, the text end condition, the acknowledgement of a level order (e5/status-left, 2026-10-19)

B704 the runner's: 4041800_02 step 60 (direction controller forward,
"Optional step: only if no backward movement occurs after this TC") is
applied, the train moves forward in RV and the EB comes from that
movement; with the step left out the train moves back and steps 71 to
76 pass (RV distance exceeded, the EB, JRU 23 bit 18): ours right
(3.15.4.8), the runner's item B750, S56315725 triaged model. B705 ours:
the DMI draws ST07 from MSG_STATUS bmm, which stayed 0 (only the button
state of MSG_ONBOARD train bit 4 was sent); `EVC_Core.Send_Status`
sends `EVC_Procedures.BMM_Inhibited` there (`EVC_DMI_Port.Status_Frame`
BMM; 5.22.4.1, Scenario_BMM); 5220200_01, _04, _05 move to the BTM
alarm input not modelled. B710 decided against the sequence: the
reading of 3120300_06 (an end mode other than the current one fulfilled
at once, no display) made 3111200_01 step 57 fail, which expects such a
text displayed; decision (3.12.3.4.3): fulfilled by the transition from
the mode or level only (`EVC_Text_Messages.End_Condition`, taken out of
`Evaluate`, its size entry 144 -> 105), Se341da87 triaged s076. B681
ours: `EVC_Levels.Mode_Entered` cleared the acknowledgement of level 0
where 4.12.1.2 a) revokes only the brake reason; decision: the reason
revoked for good, the acknowledgement stays asked (`Pending_Unbraked`;
evc_test_modes Scenario_E4_Level_0_Ack_In_SH); 4080300_04 passes in SV22
and SV30. B680 not started (budget). Edits outside the units:
`EVC_DMI_Port.Status_Frame` (one defaulted parameter), the size table.
### The juridical records' missing triggers, message 50, the track condition bits of record 21 (e5/jru-triggers, 2026-10-19)

An analysis round in the end: the three first looks of e5/shapes-3 traced
are none of them ours, so no code changed.

- B708 (S0e2fe215, S707f6e73): record 45 stays written when the
  information to the external function starts (point C, 5.20.x.2) and
  when an item changes its phase (SUBSET-027 4.2.3 Table 2: "each time
  information related to track condition(s) is provided"). 4080445_01
  step 103: the record in the window is the lower pantograph of BG5d
  (start 675 m), whose point C is 100 m before it in ours
  (`EVC_Track_Conditions.Announce_Min_Cm`) and 60 m in the sequence (its
  reach-point at 615 m): point C is the on-board's choice. 5181000_02:
  packet 39 with M_VOLTAGE 0 is a change of traction system (5.20.6.3),
  M_TRACKCOND_TI 7 with M_VOLTAGE 0 as 4.2.4.45 allows; the sequence's TI
  1 with an end distance has no 4.0.0 clause. Both triaged s076.
- B707 (Scefec287): case 5080300 4 is joined from its step 6; the
  driver's modification of the SR data (its step 5) is in no step of
  3131040_44; ours records 25 at the modification in SR
  (`EVC_Mission.Take_Data`). Triaged s076, like S31584e9f.
- B706 (S0c7e8942): the press is recorded, as 31 (hide): the toggle was
  on since step 49 and DMI 8.4.4.5 keeps its last status over the loss
  of the position; the joined case 4080415 1 assumes it off. Triaged
  s076.
- B691 not started (budget): the design found. Message 50 records the
  TIU's information (SUBSET-027 4.2.4.50, M_TRAIN_INTEGRITY_INFO 0
  confirmed, 1 lost, 2 unknown, from the TIU input 1, 2, 0), not the
  status of Table 2b; trigger at its first reception (the start up) and
  at each change. Shape: `EVC_JRU_Messages.NID_Integrity` 50, a branch
  of `Event_Message` (event 50, one 2-bit field) and of `View` (event 50,
  B2 the value: the new event number for the readers); in
  `EVC_JRU_Records` the last value recorded and a `Cab_Status`-like
  procedure; in `EVC_Core.Read_Ports` the call where
  `Take_Integrity_Input` is (`Latched_Integrity` is cleared there, so
  the 8j step does not see it; Read_Ports' Global gains
  `EVC_JRU_Records.State`); in `S076_Tables.Message_Event` and
  `Record_Field` 50 as the same number with M_TRAIN_INTEGRITY_INFO at
  byte 2. The sequences move only with the runner's TIU integrity input
  (B690).
- B642 not started.

### E5 integration after the thirty-first round (2026-10-19)

Merged: e5/radio-dir (packets 42, 45 and 131 of an RBC message taken
only when valid for the train's orientation relative to the message's
LRBG, 3.6.3.1.3, `EVC_Position.Radio_Valid_For`, B702; B720's premise
wrong: no radio linking is taken at all, `EVC_Radio_Authority` lists
packet 5 as not taken, B730; B709 is the start of mission's D2 in
`EVC_Mission`, not the revalidation), e5/runner-net (the TIU train
integrity input as signal 14, B690; feature 3050600 with both radio
systems and the FRMCS+GSM-R type, B700; a rear-end reach-point at a level
border decided by the on-board's passage, `S076_Run.Reach_Border_Rear`,
B701, which exposed a 136 sent at the border in NL, B763; B760 to B762;
the three traces not started), e5/status-left (the BMM inhibition sent
to the DMI, 5.22.4.1, B705; a text's mode or level end condition
fulfilled only by the transition from it, 3.12.3.4.3, decided against
3120300_06, B710; the level 0 acknowledgement kept when SH is entered,
its brake reason revoked for good, 4.12.1.2 a), B681; B704 the runner's
optional step applied, B750; B680 left) and e5/jru-triggers (B706, B707,
B708 traced: all three the sequences' data; B691 designed, B642 not
started).

Merge by hand: the backlog three-way by id, the plan subsections
appended, no triage or source conflict; one triage line extended by the
coordinator (Sb83b2c65 now also names B763); the baselines merged by git
and confirmed by each union's run.

Verification on the merged master: `test/check.sh` ok (evc_test 12311
checks, dmi_test 2168), the full proof 0 unproved (margin 47726 steps),
cross build and stack (worst case 27200 B, margin 5568 B), wasm and both
smokes 0 failures. SUBSET-076: 961 / 1143 / 1086 before, 972 / 1136 /
1082 after, steps not judged 4371 -> 4381, 0 regressions, 0 untriaged.
Matrix: 289 clauses left, unchanged.

Measurements (doc/ROUNDS.csv): radio-dir 131 calls / tally 125 / 164k /
7.0 USD; jru-triggers 122 / 121 / 154k / 7.5; status-left 130 / 129 /
180k / 8.0; runner-net 120 / 116 / 146k / 5.7; one over the budget by a
call, the tallies within six, the round at 28.2 USD. Reading on the
source trees (grep plus `sed -n`): 27, 28, 44, 14: three of four over
the rule's 15 although each grep was said to follow an outline run.

Lessons: the tally holds (two rounds within budget). The reading rule's
count does not fall for the agents that build, even with the outline run
named: a builder reads bodies, and `outline.py <unit> <Subprogram>` is
one call per subprogram where a `sed -n` range shows several; the rule
should count `outline.py` runs against source reads as a ratio, or the
limit should be 30 for a building package. Eight of nineteen premises
wrong, three of them a package whose three traced items were all data
(jru-triggers): a first-look line with no sequence moved yet is an
analysis item, and should be given to an analysis package. Open items:
doc/BACKLOG.csv (41 open after this round).

### Estimate to finish (2026-10-19)

What is left, from the matrix, the backlog and the plan's phases:

- **E5 closure.** The phase's own rows are done (159 done, 2 partial for
  Supervised Manoeuvre, E6). The earlier phases hold 134 rows whose notes
  point at E5 (79 partial, 55 deferred, most in E4's 4.4, 5.4, 5.6, 5.8,
  5.11): a re-read against what E5 built, as e5/bookkeeping did in round
  13, closes most of them in one round of three agents. The backlog's
  E5 items (B730 radio linking, B709, B691, B642, B760, B763, B720, the
  three traces, B680): two rounds of three on-board agents at the measured
  2.8 items per agent. Estimate: 3 to 4 rounds.
- **E6.** 186 rows todo or partial plus 55 deferred rows of E1 to E4 that
  name E6: about 240 rows. The groups: balise group message consistency
  and linking reactions, 3.16.2, 64 rows and the largest family of
  SUBSET-076 failures (about 130 sequences triaged E6); Train Data and
  data view, 3.18.3 and 3.18.4, 53 rows; the version remainder 3.17, 22;
  national values 3.18.2, 13; VBC 3.15.9, 11; big metal mass, 6; NL, 4;
  Supervised Manoeuvre, 5.21 and the E4 rows deferred to it; the
  pre-programmed braking model that unblocks the 108 Gamma sequences. A
  package that implements a function closes 10 to 15 rows (route
  suitability 4, the brake table 9, integrity 14); three on-board agents
  a round give 30 to 40 rows, with a runner agent beside them. Estimate:
  8 to 11 rounds, the consistency family first because it unblocks the
  most sequences.
- **E7.** 154 deferred rows plus 18 of the earlier phases: chapter 6's
  translations of system versions 1 and 2 (6.6.2 to 6.6.5, 130 rows),
  table-driven and a candidate for the language generator, 3 to 4
  rounds; radio infill and Euroloop (3.9, 24 rows, 939 steps and 66
  sequences of the corpus), 2 rounds, deferrable by the plan's own words.
  Estimate: 4 to 6 rounds.
- **E8.** No matrix rows: the TMS570 runtime, the RTI executive, ESM and
  lockstep reporting, the DMI link over Ethernet, the measurements. The
  agents build and measure on the host; the board bring-up needs the
  user with the hardware. Estimate: 3 to 5 rounds of agent work plus the
  user's bench time.

Total: 18 to 26 rounds at the current shape (four agents, 25 to 30 USD
and about an hour of wall clock a round, three or four rounds a working
day), so five to eight working days of sessions and 550 to 800 USD of
agent cost; 14 to 18 rounds if radio infill and Euroloop stay deferred
and E8 is counted as its own effort. The SUBSET-076 corpus at the end:
of 3190 sequences, 136 are out of scope (NTC, ATO, level 3) and a few
hundred are the sequences' own data defects already triaged; the
reachable pass count is about 2400 to 2600 against 972 today. The
uncertainty is in E6's consistency family, which touches the position
and acceptance units every other function depends on, and in the
backlog's rate of finding new items (46, 44, 41 over the last three
rounds: falling, slowly).


### The rows of E1 to E4 that point at E5, re-read (e5/bookkeeping-2, 2026-10-19)

The rows of phases E1 to E4 with status partial or deferred whose note
names E5 (the selection of the package brief, the `[E5 ...]` tag
included): 171 rows, 144 of them naming E5 outside the tag. 110 were
re-read against the code their notes name (`outline.py` on the unit
and the subprogram, the scenario list of `test/src/evc_test*.ads`) and
the clause, and their notes rewritten to name the unit, the
subprogram and the scenario, or what is left and its owner; the
`[E5 ...]` tag kept. No code changed but the `@req` tags.

| Phase | Rows | Re-read | Done | Still partial | Deferred (owner) | n/a |
|---|---|---|---|---|---|---|
| E1 | 4 | 2 | 0 | 0 | 2 (E7 infill) | 0 |
| E2 | 11 | 1 | 1 | 0 | 0 | 0 |
| E3 | 14 | 1 | 0 | 1 (E6, B036) | 0 | 0 |
| E4 | 142 | 106 | 23 | 39 (B780 to B789, B036, B730, E6) | 44 (E6 Supervised Manoeuvre 29, E7 Euroloop / infill 4, E8 faults 1, B730 / B784 / B785 / B788 / B789 10) | 0 |

Done: the SR list replaced by message 2 (4.4.11.1.6.6), the track
ahead free request in SR and OS (4.4.11.1.9, 4.4.12.1.5), the session
order in SL and in SH / PS (4.4.6.1.10 a), 4.4.8.1.5.2, 4.4.20.1.12),
the position reports in NL (4.4.15.1.4), 4.8.3 [9] and [12], the trip
in level 2 (5.11.2.2 A030, A115, S120, S140 b), S150, S150 c)), the mode
profiles of the RBC with an area already entered (5.7.4.1, 5.7.4.2,
5.9.2.2, 5.9.5.1, 5.9.5.2, 5.19.2.2, 5.19.5.1, 5.19.5.2), Q_INTEGRITY of
the position report (3.6.5.1.2 g)). Tags added: 12 clauses on 8 lines
(`EVC_Sessions.Apply_Order`, `EVC_Sessions.Reports.Evaluate` and
`Mode_Changed`, `EVC_Radio_Authority.Take_TAF` and the package,
`EVC_Text_Messages.Store`, `EVC_Acceptance.Context_T`).

Decisions:

1. Supervised Manoeuvre is E6 (the estimate's E6 list): its 29 rows of
   E4 (4.4.21.1, 5.21.2.2, 5.21.4.1, 5.4.5.3 k), 5.11.2.2 S140 c),
   4.8.3 [17], 4.8.4 [12]) are deferred with the tag
   `[E6 Supervised Manoeuvre]` and B008.
2. Euroloop and radio infill stay E7: A.3.5.1 5th bullet, 4.4.11.1.6.7,
   4.8.4 [6], 5.5.3.1.2 (the RIU session), 8.4.4.4.1 and 8.5.3 (the RIU
   sender rules) deferred with `[E7 Euroloop]` / `[E7 infill]`.
3. 4.4.6.1.10 c) (a safety critical fault reported from SL) is E8: the
   on-board detects no fault yet.
4. A row whose behaviour exists but whose scenario does not name the
   case stays partial with a backlog id (B783, B784, B787, B789), not
   done.

Genuine gaps found (backlog B780 to B789): the location based texts
not deleted by the shortenings (B780); no scenario of a reversal over
a location action (B781); the train position and the integrity
information of the Train Data in every mode where chapter 4 asks for
the engine and no integrity in SB without Train Data and in NL (B782);
SL and RV with the RBC (B783); four acceptance exceptions (B784); packet
64 not stored (B785); the MA request parameters kept on entering level 1
(B786); no scenario of a listed "stop if in SR" group (B787); the mode
report not repeated (B788); the session terminations of 5.4.1.4 and
5.6.4.1.2 (B789).

Left unread by budget (61 rows): E1 A.3.11 Table, 8.5.2 Table; E2
3.4.2.3.3.6, 3.4.2.3.3.7, 3.6.2.2.2 (with c) and .3), 3.6.5.1.4 e) and
l), 3.6.5.2.5 with Tables 2a and 2b; E3 3.8.4.2.2, 3.11.5.13, 3.11.5.14
(three rows), 3.11.6.3.1, 3.13.10.2.6 (five rows), 3.14.1.7.6, A.3.1
Table; E4 4.6.3 Table, 4.8.3.1.1 Table, 4.8.4.2 Table and its [13],
4.11.1.1, 4.11.1.3, 5.4.3.2 (14 rows), 5.4.3.3 Table, 5.4.5.1, 5.4.5.3
(seven rows), 5.6.2.2 D020, 5.8.4.1 (three rows), 5.11.4.3, 5.17.2.2 A7
and D5. Most of 5.4.3.2 and 5.4.5.3 are the start of mission of
`EVC_Sessions.Mission` and `EVC_Sessions.Network` (their notes already
name the units and say what is left); 3.13.10.2.6 b) waits for 4.6.3
[11] in `EVC_Radio_Authority`.
### Linking consistency and reactions, the RAMS supervision, the error report to the RBC (e6/consistency-linking, 2026-10-19)

- Cases (3.16.2.3.1 a to c): already in `EVC_Position.Decide_Linking` (early, a group announced later) and `Supervise_Windows` (not detected) since E2; now tagged and done. 3.16.2.3.1.1: the 1.3 m margin only, the time after it (100 ms, Tn) and 3.16.2.3.4 left (B822).
- 3.16.2.7.1.1 (the brief said a trip: the clause gives the service brake): `Supervise_Windows` requests the service brake (`Cause_Double_Missed`, 5) when a window is passed missed and the one before was too, with no group passage between (`Missed_Last`, reset at the start of the group `Evaluate`, a one-line edit beside the passage completion). The service brake, "Balise read error" and the release at standstill come from the existing linking reaction path of `EVC_Procedures` (`Link_SB`); the runner's JRU 23 bit 1 now reads the DMI entries 1 and 2 (`S076_Tables.System_Status_Fact`).
- 3.16.2.6.2, 3.16.2.7.1.1: `EVC_Stored_Information.Linking_Shortening` (beside `Contact_Shortening`): a service brake reaction requested while moving in FS, AD, LS, OS, SM, then standstill: `Shorten_To_Train`. Decision: a request at standstill shortens nothing.
- 3.16.4: `EVC_Sessions.Reports.Request_Balise_Errors`, called by `EVC_Sessions.Evaluate` after `Reports.Evaluate`: a linking reaction of the cycle (applied or not) reported in level 2 to the supervising RBC while established, M_ERROR 7 for the double linking error, else 0; one per cycle; none kept for a later session. Hand-over to e6/consistency-message: an inconsistent group requests `Request_Reaction` with a cause of its own (B821) and is then braked, shortened and reported by the same path (M_ERROR 1 / 2 need the cause distinguished in `Request_Balise_Errors`). Hand-over to e5/remainder: 3060100_01 and 3160400_01 judge the report once `Take_Radio_Linking` takes the linking of message 24.
- Left: 3.16.2.7.2 cross-talk (B820), 3.16.2.5 (B821), the evc_test scenario of the report and of the shortening (B823), record 12 with M_ERROR 7 (the runner does not judge it).
- SUBSET-076: 3160200_05 passes in three versions; 3131040_01 blocks one step earlier (Gamma, not judged both ways): its linking announces BG2 and BG3, never passed, with "no reaction", so 3.16.2.7.1.1 brakes there, as the clause asks.
### Balise group message consistency (e6/consistency-message, 2026-10-19)

The first E6 subsection. The checks, at the end of a passage
(`EVC_Balise_Groups.Consistent`): every telegram read compliant
(3.16.1.1: a telegram the codec refuses with its header read enters its
group through `EVC_Received.Refused_Header` and
`EVC_Position.Receive_Refused`), every balise up to N_TOTAL read or
duplicated by a neighbour read (3.16.2.4.1 a), 3.16.2.4.2, `Duplicated`),
the message counters matching, 255 fitting all, 254 none, the first of a
duplicated pair left out (3.16.2.4.7, 3.16.2.4.7.1, `Counters_Match`,
`Superseded`). The reactions (`EVC_Position.React_Inconsistent`, called
by `Evaluate`, the message rejected, 3.16.1.4): with linking checked, the
expected group's Q_LINKREACTION (or the one of unknown identity), none for
another group (3.16.2.4.1, 3.16.2.4.3); with linking not checked, the
service brake as a linking reaction of Q_LINKREACTION 1 (EVC_Procedures:
"Balise read error", released at standstill), unless packet 145 inhibits
it (3.16.2.4.4.1 b), or the last announced group's reaction
(3.16.2.4.4.4). Record 12 with M_ERROR 1 (linked) and 2 (unlinked):
events 12 and 13 of `EVC_Position.Event_Code`,
`EVC_JRU_Messages.Paired_Message`. Record 6 for every telegram received
(SUBSET-027 4.3.1.1).

For e6/consistency-linking: the unlinked group's consistency, 3.16.2.5.1
to 3.16.2.5.3 (the service brake, packet 145, M_ERROR 2), is implemented
by `React_Inconsistent`; its rows can point at it (not tagged here).

Decisions: the BTM port carries decoded telegrams only, so "a balise
detected, no telegram decoded" (b) arrives as a missed balise (a); the
`INT btm-alarm` steps are the big metal masses, no port change. A refused
telegram is not compliant (3.16.1.1), without the duplicate exception. A
telegram of a version not read counts as a balise read, its content left
out (5040300_05/06 carry such a second balise). 3.16.2.2.1: a header read
counts as read for Q_LINK. The content bullets of 3.16.2.4.4.1 a) are not
told apart; 3.16.2.4.3.1 a) is not told apart from b). 3.16.2.4.8.2.1
n/a (STM).

Rows: 35 of 3.16.1, 3.16.2.2, 3.16.2.4: 25 done, 9 partial, 1 n/a; left
3.16.2.4.4.2 (B800), 3.16.2.4.9 (B801), 3.16.2.4.8.1 (B802). Scenarios:
`EVC_Test_Consistency` (the check of a passage, record 12); the end to
end reactions are B803. SUBSET-076: 972 / 1136 / 1082 before, 977 / 1145
/ 1068 after; 15 regressions of the 3131040 family understood and triaged
s076 (groups with M_MCOUNT 254, a blank second balise of M_VERSION 0);
three new signatures onboard (B804, B805).
### Radio linking, the position report at a border in NL, the level after D2, message 50 (e5/remainder, 2026-10-19)

**B730 done.** Packet 5 of RBC messages 3, 33 and 24 is taken by
`EVC_Position.Take_Radio_Linking` (3.4.4.1.1, 4.8.1.6, 4.8.4 row
Linking), called by the new core step `EVC_Core.Take_Radio_Linking`
before `Evaluate_Stored_Information`: the origins of the messages' LRBG
are released by the stored information, and 4.8.1.6 wants the linking
first. Referred to the message's origin, valid for the train by Q_DIR;
in level 2 only (4.8.3) and the modes of the row. Decision: taken when
the LRBG of the message is the SOLR, or the SOLR is one of its linked
groups; a reference ahead of the SOLR (message 33 shifted forward) is
not taken. `EVC_Radio_Authority.Take_Message` passes a message 24 with
packet 5 to `EVC_Radio_Info`. Scenario `Scenario_Radio_Linking`.
9990500_16 still fails at step 88: the MA is relocated now (611 to 561
m), the track ahead free window is not (B790, `Take_TAF` keeps it as
odometer distances).

**B763 done.** The report at the border from the leading engine only
(5.10.3.6.2): none in NL, no wait for the order
(`EVC_Level_Sessions.Evaluate`); `Scenario_L2_Exit_In_NL`. 4050200_04
SV30 passes.

**Regressions of the radio linking, traced and triaged.** Seven, in
three families, all from B730 (an experiment without the core step
passes 9990500_15): 9990500_15 SV21/SV22/SV30 step 73 (S5c9019aa)
and 4100103_37 SV21/SV22 step 86 (Sc36bdd59) passed before, only
because no radio linking was used. Traced (B791): the RBC's packet 5
names a group the track does not hold (9990500_15: NID_BG 5 at 400 m
from BG2, and message 24 refers to LRBG 5, while BG3 is read there;
4100103_37: NID_BG 2 announced, BG4 read), so the read group is not
the expected one and is ignored with its level order (packet 41);
triaged s076. 9990500_09 SV21/SV22 moves from
step 95 to 85 (S13c9beb3, model already): BG3 read 100 m before its
linked location appears outside the window of 3.4.4.4.3 with the
runner's odometer (not verified). Two signatures reached by improved
sequences triaged onboard untraced (S4eed293c, Sd640223d; B792). After:
976 passed, 1128 failed, 1086 blocked (master 972/1136/1082), the
baseline re-recorded.

**Left:** B709 traced (the PDF table read: following D2 with the
position not valid the level and the RBC contact become invalid; the
contact part exists, the level part needs an invalidation in
`EVC_Levels` and its call at D2, see the backlog line), B691, B642,
B680 not started (budget).

### E5 integration after the thirty-second round, the first of E6 (2026-10-19)

The round of the estimate's recommendation: one bookkeeping agent, one
E5 remainder, two E6 packages on balise consistency.

Merged: e5/bookkeeping-2 (171 rows of E1 to E4 point at E5, not the 134
the brief counted; 110 re-read, 24 to done, 39 kept partial with their
owner, 44 deferred to E6 Supervised Manoeuvre, E7 or E8 by tag; ten gaps
found, B780 to B789; 61 rows left unread), e6/consistency-linking (the
service brake after two expectation windows passed without a balise,
3.16.2.7.1.1, `EVC_Position.Supervise_Windows`; the stored information
shortened at standstill after a linking service brake, 3.16.2.6.2; the
balise error report to the RBC with M_ERROR 0 and 7, 3.16.4,
`EVC_Sessions.Reports.Request_Balise_Errors`; 3.16.2.3.1 tagged done;
B820 to B824; the brief's "trip" of 3.16.2.7.1.1 wrong, it is the service
brake), e6/consistency-message (balise group message consistency at the
passage's end, 3.16.1.1 and 3.16.2.4: a missed balise, a refused telegram
with its header read, the counters with 254 and 255, the duplicate
exception, packet 145; `EVC_Balise_Groups.Consistent`,
`EVC_Position.Receive_Refused` and `React_Inconsistent`; the reaction by
Q_LINKREACTION when linking is checked, the service brake with "Balise
read error" when not; record 12 with M_ERROR 1 and 2, record 6 for every
telegram received; 25 rows done, 9 partial, 1 n/a; B800 to B805; the 15
regressions of the 3131040 family traced to groups carrying M_MCOUNT 254,
the sequences' data) and e5/remainder (linking received by radio taken
from messages 3, 33 and 24, 4.8.1.6, `EVC_Position.Take_Radio_Linking`
before the stored information, B730; no position report and no wait at a
level border in NL, 5.10.3.6.2, B763; the two sequences the radio
linking regressed carry a linking that names another group than the
track has at that place, the sequences' data; B790 to B792; B709 traced;
B691, B642, B680 not started).

Two agents stopped at their budget with the "Done" list unfinished
(consistency-message: the whole check not run, four signatures
untriaged, one regression re-recorded untraced; remainder: seven
regressions unanalysed) and were sent back with an extra budget of 35
and 40 plus 40 calls; both came back complete, the remainder's third
pass tracing its regressions to the sequences' data where the second had
only triaged them.

Merge by hand: the backlog three-way by id, the plan subsections
appended, the matrix row by row against the merge base (one row changed
on both sides, 4.8.1.6: the remainder's), the triage by signature id,
the EFS index regenerated for each union, two hunks in the position unit
(the inconsistency cause renumbered to 7 beside the linking branch's 5
and 6; the `Missed_Last` reset placed before the consistency check), the
golden `valid_inputs` re-recorded for the union and reviewed (as
intended: three refused telegrams recorded, the group's record 12 and its
reaction with the renumbered cause), one signature new to the union
triaged by the coordinator (S451bc2d8: the 136 with M_ERROR 1 that the
radio linking now reaches and the error report does not tell apart,
B821).

Verification on the merged master: `test/check.sh` ok (evc_test 12341
checks, dmi_test 2168), the full proof 0 unproved (margin 47726 steps),
cross build and stack (worst case 27216 B, margin 5552 B), wasm and both
smokes 0 failures. SUBSET-076: 972 / 1136 / 1082 before, 1000 / 1108 /
1082 after, steps not judged 4381 -> 4339, 0 regressions, 0 untriaged.
Matrix: 289 -> 255 clauses left; E6 done 47 -> 78, todo 176 -> 132.

Measurements (doc/ROUNDS.csv): bookkeeping-2 146 calls (budget 150) /
203k / 8.3 USD; consistency-linking 130 / 183k / 8.1; consistency-message
160 (130 + 35 granted) / 224k / 11.4; remainder 183 (130 + 80 granted) /
239k / 13.0; the tallies within four of the measured; the round 40.9
USD. Reading on the source trees: 25, 47, 55, 91 runs: the two E6
builders and the remainder far over the building limit of 30.

Lessons: an E6 function package is bigger than an E5 item package: both
consistency agents filled their budget on the function and left the
"Done" list to the end, one past it; the first E6 round should have given
them 160. A second pass costs less than a reverted branch: the two
resumptions (35 and 80 calls, about 9 USD) kept 1000 passing sequences
where the alternative was to merge two branches with unexplained
regressions or to drop the radio linking. The source-tree reading of a
builder is a function of the function's size, not of the rule: 47 to 91
runs for the three builders, so the rule's limit says nothing useful for
a building package and the measurer should report the ratio to outline
runs instead. The brief's clause reading was wrong once more (3.16.2.7.1.1
gives a service brake, the brief said a trip) and its counts twice (134
rows, 171; the btm-alarm steps are big metal masses). Open items:
doc/BACKLOG.csv (62 open after this round; the two E6 packages and the
bookkeeping added 21).

### The level after D2, message 50, the record 21 bits, the TAF window, two traces (e5/remainder-2, 2026-10-19)

**B709 done.** Following D2 of the start of mission with the stored
position invalid or unknown the level valid -> invalid (5.4.3.3 Table,
PDF page 23): `EVC_Mission.D2_Passed` (the driver ID entered or
revalidated in SB during the start of mission, set in `Evaluate` after
`Take_Identity`), `EVC_Levels.Invalidate`, called in `EVC_Core` right
after `EVC_Mission.Evaluate` (the step that already holds the
position's validity); the RBC contact part was there
(`EVC_Sessions.Mission`). `Scenario_E4_Desk_Closed` now re-enters the
level after the revalidated driver ID. 5040300_03 SV30 passes step 51
and stops at step 53: the DMI decides D2 itself on the level alone at
the validation of the Driver ID window, before the on-board's report
(B890; with the position bit of MSG_ONBOARD five dmi_test checks fail,
so not changed).

**B691 done.** JRU message 50 (SUBSET-027 4.2.4.50) records the TIU's
train integrity input, not the status of Table 2b: `Integrity` among
the inputs of `EVC_JRU_Records` (`Integrity_Code`: TIU 1 confirmed, 2
lost, 0 unknown -> M_TRAIN_INTEGRITY_INFO 0, 1, 2), written at the first
value received and at each change by the 8j step of `EVC_Core`
(`TIU_Value_Now`, so `Read_Ports` keeps its Global);
`EVC_JRU_Messages.NID_Integrity` in `Event_Message` and `View`;
`S076_Tables` maps record 50. Scenarios `Scenario_JRU_Format`,
`Scenario_JRU_On_Board`. 3060500_10 judges its two records 50 now.

**Left (budget):** B642 traced in part (the backlog line), B790, B792,
B680 not started.
### The 61 rows left and the E6 tags of the deferred rows (e5/bookkeeping-3, 2026-10-19)

Part 1: the 61 rows bookkeeping-2 left unread (the count confirmed: the
selection now gives 146 rows, of which these 61 by clause; 5.4.5.3 k)
was already tagged Supervised Manoeuvre). 58 re-read against the code
(`outline.py`, the scenario list) and the clause; notes rewritten to
name the unit, the subprogram and the scenario, or what is left and its
owner; the `[E5 ...]` tags kept. No behaviour changed; `@req` tags added
on `EVC_Sessions.Integrity` (3.6.5.2.5 Table 2a),
`EVC_Sessions.Mission` (5.4.3.2 D11; `Driver_Contact`: A.3.11 Table,
5.4.5.3 j) 1st bullet), `EVC_Sessions.Network.Driver_Entries` (5.4.3.2
D8, S3, S5, 5.4.5.3 j) 2nd bullet), `EVC_Driver_Requests` (5.4.5.3 l)).

| Phase | Rows | Re-read | Done | Still partial (owner) | Deferred (owner) | n/a |
|---|---|---|---|---|---|---|
| E1 | 2 | 2 | 0 | 2 (E6 train data; 8.5.2 to partial: E6 version, SM) | 0 | 0 |
| E2 | 10 | 10 | 2 (3.6.2.2.2, c)) | 8 (B840, B841, E6 consistency, train data, SM; 3.6.2.2.2.3 and Table 2a to partial) | 0 | 0 |
| E3 | 13 | 13 | 1 (3.8.4.2.2) | 2 (B842; A.3.1: B788, B844, E6 big metal) | 10 (B785 4, B842 4, B847, E6 SM) | 0 |
| E4 | 36 | 33 | 8 (5.4.3.2 D11, D15, S3, S11; 5.4.5.3 j), j) 1st, l); 5.6.2.2 D020) | 22 (B841, B842, B843, B844, B845, B846, E6 SM / train data, E7 Euroloop, E8) | 3 (A41: B844; 5.4.5.3 i): E6 VBC; 5.8.4.1 f): B845) | 0 |

Done: the RBC information referred to one of the last eight LRBGs
(`EVC_Position.Radio_Origin`, `Radio_Valid_For`, 3.6.2.2.2 c)); the
section timer exception of A.3.4.1.3 [11] (the MA's `Withdrawn`, any
shortening); D11, D15, S3, S11 of the level 2 start of mission; the
radio data re-entered at S10 / S20 (5.4.5.3 j)); the BMM inhibition at
S10 / S20 (5.4.5.3 l)); the level 2 branch A045 of D020.

Decisions:

1. "3.6.5.2.5 Table 2a" is read as Table 2c, the conditions: in 4.0.0
   the tables of 3.6.5.2.5 are 2b and 2c, Table 2a is 3.6.4.2.4's; the
   row is kept (the clause list is the matrix key) and says so.
2. FRMCS is not n/a: the configuration may install it, only the RTM
   port reports no FRMCS registration yet; its branches of 5.4.3.2
   (A41, A43, D7, D8, D9, S4, S5) stay partial or deferred on B844.
3. A row whose decision branch exists for GSM-R only is partial, not
   done (D7, D8, D9, S4).
4. 8.5.2 Table goes from deferred to partial: the structure and the
   receivers are built, only the Invariant column (3.17) and the SM
   messages 131 / 133 are left.

Genuine gaps found (B840 to B847): message 45 not taken (B840); the
scenarios missing for 3.6.2.2.2.3, 3.6.5.1.4 e), 5.4.5.3 a) and j) 2nd
bullet (B841); 4.6.3 [11] declared and never held, so no level 2 trip
of 3.13.10.2.6 b) (B842); the session messages' rows of Tables 4.8.3
and 4.8.4 not looked up (B843); the FRMCS registration (B844); the
override not ended by an MA of the RBC or a group off the SR list of
packet 63 (5.8.4.1 f), g); B845); 5.17.2.2 D5 not built (B846); V_MAIN
over a transition from level 1 to level 2 not traced (B847).

Left unread by budget (3 rows): 5.4.3.3 Table (the position and RBC
contact rows), 5.4.5.1 (loss of a session during the start of
mission), 5.11.4.3 (a transition to level 0 in PT).

Part 2: the 25 rows of E1 to E5, partial or deferred, naming E6 without
an `[E6 ...]` tag: 24 tagged, one false match (5.4.3.2 S4: "E6 / E7"
are the flowchart's events). Tags added: consistency 13, train data
14, Supervised Manoeuvre 14, version 2, other (reversing area) 1; a
row of A.3.4.1.3 or 3.7.3.3 carries several. The rows of E1 to E5,
partial or deferred, by tag after this package (the E6 briefs'
selection from now on):

| Tag | Rows |
|---|---|
| `[E6 Supervised Manoeuvre]` | 52 |
| `[E6 train data]` | 23 |
| `[E6 consistency]` | 14 |
| `[E6 version]` | 3 |
| `[E6 BTM alarm]` | 2 |
| `[E6 VBC]` | 2 |
| `[E6 balise consistency]` | 1 |
| `[E6 big metal mass]`, `[E6 big metal]` | 1 + 1 |
| `[E6 other: reversing area]` | 1 |

The two spellings of the consistency and big metal tags predate this
package on one row each; a selection should match both.
### What the consistency packages left: default balise information, unlinked groups, the shortening, the message's end (e6/consistency-left, 2026-10-19)

- B801, 3.16.2.4.9: `EVC_Core.Show_Trackside_Malfunction` (beside `Show_Route_Unsuitable`): "Trackside malfunction" (entry 3, `EVC_DMI_Port.SS_Trackside_Malfunction`) when a group taken in the cycle holds packet 254 valid for the train's direction. Decision (A.3.3.3): a taken group's message is consistent; the filters of 4.8.3 (every level) and 4.8.4 (not NP, SF, IS; SB with a cab active, footnote [2]); the rest of the message is used. 3140300_02, 3040400_10, 3160200_16 pass.
- B821, 3.16.2.5: the reaction was already in `EVC_Position.React_Inconsistent`; rows closed with tags. New: `EVC_Balise_Groups.In_Order` in `Consistent` (decision: balises read out of the order of their numbers, 0, 2, 1, mean one was missed: 3160200_12 passes); `EVC_Sessions.Reports.Request_Balise_Errors` reports M_ERROR 1 (linked) and 2 (unlinked) from the position's events, with or without a reaction (3.16.4.2); a linking reaction caused by an inconsistent message is no longer reported as M_ERROR 0 (S451bc2d8: 3060100_01 now runs to its extractor block at step 135).
- B800, 3.16.2.4.4.2 and 3.16.2.5.2: no procedure of its own: A.3.4.1.2 g) and m) are in the column of h) and i) of Table A.3.4, and the consistency service brake is a linking reaction of Q_LINKREACTION 1, so `EVC_Stored_Information.Linking_Shortening` shortens it (tag and comment extended, no code change).
- B824, 3.16.2.6.1: `EVC_Procedures.Mode_Changed` ends "Balise read error" when the linking service brake is revoked on NP or SB (decision: the 30 s of 3.14.1.6 are for a brake released at standstill, not revoked). 4120100_09 runs to step 132.
- Left: B805 (two traces), B802 (3.16.2.4.8.1 / .8.2: the packets of the superseded telegram still taken), B803 / B823 (end-to-end scenarios of the reactions, the shortening and the error report through EVC_Core; only `Scenario_Default_Balise` added), B820, B822 (no decision taken).
- New signature S54f1704c (3160200_33 step 55): the sequence's second balise of BG3d is said not decodable (CRC) but its telegram is valid in the file, so the group is consistent and its packet 254 shows "Trackside malfunction"; triaged s076.
### Train Data and the additional data (e6/train-data) (2026-10-19)

The first package of 3.18.3 / 3.18.4: the 53 rows todo or partial re-read
against the code of E4 and E5, the missing behaviours built.

Re-read: done by existing code 23 (the Train Data entry of
`EVC_Mission.Train_Data_Of` / `Take_Data` for 3.18.3.2 and 3.18.3.3,
the driver ID and train running number of `Take_Identity`, the level of
`EVC_Levels.Evaluate`, the NID_ENGINE of the installation, the adhesion
default), built now 8 (below), partial 15 (the gamma model's data, the
traction model, the rotating mass, the axle number; 3.18.3.7 b); the RBC
contact rows of 3.18.4.3 named but not re-read; the TRN from the RBC),
n/a 1 (3.18.3.2 i), NTC), left todo 11 (the safe consist length and
Supervised Manoeuvre, 3.18.3.8).

Decisions: no safe consist length input on the TIU port: its rows
(3.18.3.2 b) 1st bullet, 3.18.3.2.5, 3.18.3.5) and 3.18.3.9 / 3.18.3.10
go with Supervised Manoeuvre, `[E6 Supervised Manoeuvre]` (B873, also
B031). The train running number goes to the RBC in packet 5 of the next
message 136 to the supervising RBC (8.4.4.4.2 b) after the driver's entry
with the session established and after an establishment outside the
start of mission, and of the 157 of the start of mission when valid
(5.4.3.2 A33). 3.18.3.7 a) shortens as A.3.4.1.2 i) does (the same column
of A.3.4.1.3), one cycle after the entry (the flag of `EVC_Mission` read
by `EVC_Core.Evaluate_Stored_Information`); the first Train Data since
power-up is no change.

Built: 3.18.3.7 a) (`EVC_Mission.Categories_Changed`,
`EVC_Stored_Information.Train_Data_Shortening`), 3.18.4.5.4
(`EVC_Sessions.Reports.Evaluate` / `Send_136`,
`EVC_Sessions.Mission.Send_Report`), 3.18.4.1.2 (M_NVDERUN, through
`EVC_Mission.Context_T.ID_Running`), 3.18.4.2.5 (`EVC_Levels.Selectable`),
3.18.3.2 h) (M_AIRTIGHT kept in `EVC_Train_Data.Categories_T` and sent in
packet 11). Scenarios: `Train_Data_Categories`, `Driver_Level_Table`
(EVC_Test_Modes), `Session_TRN` (EVC_Test_Sessions). Left: B870 (3.18.3.7
b), the transition buffer), B871 (3.18.3.8), B872 (packet 140), B760,
B782, B031 not started.

### E5 integration after the thirty-third round, the second of E6 (2026-10-19)

The round of the first E6 round's recommendation: the bookkeeping's
rest, the consistency follow-ups, the next E6 function (Train Data),
the small E5 items.

Merged: e5/bookkeeping-3 (58 of the 61 rows left re-read, 11 to done,
the rest naming their owner; three left: 5.4.3.3 Table, 5.4.5.1,
5.11.4.3; 24 deferred rows of E1 to E5 tagged `[E6 <function>]`, so that
an E6 brief selects its rows by tag: Supervised Manoeuvre 52, train
data 23, consistency 14, version 3, VBC 2, big metal 2 under two
spellings; B840 to B847: message 45 not taken, 4.6.3 [11] declared but
never set, the session messages' rows of the acceptance tables not
looked up, FRMCS registration, 5.8.4.1 f), 5.17.2.2 D5),
e6/consistency-left ("Trackside malfunction" for a group whose packet
254 is valid for the train's direction, 3.16.2.4.9,
`EVC_Core.Show_Trackside_Malfunction`; balises read out of the order of
their numbers count a balise as missed, `EVC_Balise_Groups.In_Order`,
3.16.2.5; the balise error report with M_ERROR 1 and 2 beside 0 and 7,
3.16.4.2; the consistency shortening found covered by
`Linking_Shortening`, A.3.4's g) and m) in the linking column; "Balise
read error" removed when the linking brake is revoked on NP or SB,
3.16.2.6.1; 10 rows done, 7 partial; B801, B821, B800, B824 done; B805,
B802, B803 / B823, B820, B822 left; 3160200_33's CRC step the sequence's
data, S54f1704c), e6/train-data (the 53 rows of 3.18.3 and 3.18.4 read
against the code of E4 and E5: 31 done, 15 partial, 1 n/a, 11 todo
deferred to Supervised Manoeuvre with the safe consist length, B873 with
B031; built: the shortening at a change of train category, axle load
category, loading gauge or traction system at standstill, 3.18.3.7 a),
`EVC_Stored_Information.Train_Data_Shortening`; the train running number
to the RBC in the next 136 and in the 157, 3.18.4.5.4; the driver ID
while running only with M_NVDERUN, 3.18.4.1.2; the driver's level choice
limited to the table of supported levels, 3.18.4.2.5,
`EVC_Levels.Selectable`; the airtight entry kept and sent, 3.18.3.2 h);
B870 to B873; B760, B782, B031 not started) and e5/remainder-2 (the level
valid to invalid after D2 of the start of mission with the position
invalid or unknown, 5.4.3.3 Table, `EVC_Levels.Invalidate` called from
`EVC_Core` because D2 is decided in `EVC_Sessions.Mission`, not
`EVC_Mission`, B709; message 50 TRAIN INTEGRITY INFORMATION from the TIU
input at its first value and each change, SUBSET-027 4.2.4.50, B691;
B642 traced in part; B790, B792, B680 not started; B890: the DMI decides
D2 on the level alone).

All four agents were stopped at once by the monthly API spend limit
(HTTP 429, reset at 14:30) about twenty minutes into the round; a
message to each agent after the reset resumed it in its worktree with
its context, no budget lost; the stop cost about half an hour of wall
clock.

Merge by hand: the backlog three-way by id, the plan subsections
appended, the triage lines of two branches both kept, the EFS index
regenerated, two hunks of the train-data merge joined (the context
aggregate of `EVC_Core` with `ID_Running` beside the D2 check;
`Take_Identity`'s new parameter beside the D2 flag in `EVC_Mission`); no
golden changed, no signature new to the union.

Verification on the merged master: `test/check.sh` ok (evc_test 12372
checks, dmi_test 2168), the full proof 0 unproved (12366 checks, margin
47726 steps), cross build and stack (worst case 27216 B, margin 5552 B),
wasm and both smokes 0 failures. SUBSET-076: 1000 / 1108 / 1082 before,
1009 / 1090 / 1091 after, steps not judged 4339 -> 4320, 0 regressions,
0 untriaged (the three regressions of consistency-left the sequence's
data, S54f1704c). Matrix: 255 -> 216 clauses left; E6 done 78 -> 114,
todo 132 -> 73, partial 22 -> 44.

Measurements (doc/ROUNDS.csv): bookkeeping-3 130 calls (budget 130) /
182k / 8.6 USD; remainder-2 119 (130) / 146k / 6.9; consistency-left 150
(160) / 183k / 9.0; train-data 169 (160; tally 160) / 229k / 13.7; the
round 38.2 USD. Premises wrong 3 of 27 stated (B709's unit, B821's
missing part, the plan section number of E4's outcome). Source-tree
reading: 22 + 9, 12 + 14, 9, 22 + 20 runs against 17, 22, 22, 26
outline runs: the consistency agent read a third of what the two
other builders did for the same kind of work.

Lessons: 160 calls let both E6 builders finish their "Done" lists, but
both passed the 80 % bound to do so, the Done list of an E6 builder
costing 30 to 40 calls (whole check, unit proofs, runner with its
triage and baseline, plan, commit): the bound of a 160 package is 120.
A re-read of rows against existing code is cheap and closes many (31 of
the 53 Train Data rows were built by E4 and E5 under 5.4 and 5.17; 11 of
the 58 bookkeeping rows), so an E6 function package should begin with
the re-read of its rows as train-data did. The tags `[E6 <function>]`
now carry 52 rows for Supervised Manoeuvre: it is the largest E6 group
left, before the consistency rest (about 25 rows and five backlog items)
and the Train Data rest (B870 to B873, B760, B782). Open items:
doc/BACKLOG.csv (69 open after this round; 13 added, 8 closed).

### National values and the version remainder; the TAF window, two traces, the record 21 bits (e6/national-version, 2026-10-19)

3.18.2: the 13 rows read against `EVC_National_Values` (E1, E3): 12
existed (reception now or at a location, the country check and the
defaults, the overwrite whatever the countries, a new set deleting the
one waiting, the supervisions reading the set in use at every cycle so
that a time or distance keeps its start and takes the new value,
3.18.2.11: the SR distance of `EVC_Mission`, override and post trip of
`EVC_Procedures`, T_NVCONTACT of `EVC_Sessions`, D_NVROLL); built: the
set applicable kept over No Power, the one waiting lost (3.18.2.7,
3.18.2.9 2nd bullet: `Keep`, `Restore`, `EVC_Retained.Kept_T.National`,
`EVC_Core.Save_Retained` and `Power_Up`, about 460 B more in the kept
record on the stack of those two). 13 done, tagged; evc_test
National_Values_Kept.

3.17.3: 3.17.3.3, .4 (decision: the version is taken only for a group
message taken into account, after the checks of Table 17, so a rejected
message never changes it), .5 a) d) e), .7, .11 a) done; .5 and .5 c)
partial (X = 1 refused by the decoder until the translations of chapter
6, `[E7 version]`); .5 b) n/a (the lowest X of the envelope is 1); 3.17.3.6
deferred `[E7 Euroloop]`; .11 b) c) stay partial (the consistency error
of a spare value for the operated Y is 3.16). Track_And_Version checks
X = 0 and X = 1 without a trip. B940: the mismatch of 3.17.2.6 ignores
the countries of an immediate packet 3 of the same group (3.17.3.4.1).

B790 traced, not built (the backlog line holds the trace and the fix:
the window as offsets from the LRBG of message 34, moved by the linking
distance when the LRBG changes, which needs a query of `EVC_Position`).
B792, B642, B680 not started (the bound of 100 calls reached).
