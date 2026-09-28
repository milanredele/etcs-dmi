# evc/ — the ETCS on-board

The ETCS on-board of SUBSET-026 v4.0.0, built in phases
([doc/EVC-PLAN.md](../doc/EVC-PLAN.md)). Every unit here is SPARK
(`SPARK_Mode => On`) and proven with gnatprove; none uses `common/`,
Ada.Streams, tasking, allocation, floating point or anything host-only, so
the same sources build for the host, wasm32 and a bare-board light runtime
(`etcs_evc.gpr`).

| Package | Role |
|---|---|
| `EVC_Core` | The core: `Initialise`, `Handle_Input (Port, Payload)`, `Tick (Dt_Ms)`, `Take_Outputs`, `Enter_Failure` / `Failed`. One `Tick` is one cycle, in the order of the plan: read ports, position, stored information, monitoring, mode machine, outputs. |
| `EVC_Modes` | The 19 modes of 4.3.2 (`M_FS` .. `M_RV`), the levels (0, NTC, 1, 2), the status of the stored level, and the transitions table of 4.6.2 with its priorities. |
| `EVC_Ports` | The ports (BTM, RTM, odometer, TIU, DMI, ATO, JRU), the maximum payload of each and the documented shape of every payload; `Valid_Input` checks it. |
| `EVC_DMI_Port` | The frames of the DMI protocol v2 the on-board accepts and sends, byte by byte (the constants repeat `common/dmi_protocol.ads`; `evc_test` checks them). |
| `EVC_Outbox` | The bounded queue of outputs: records `port u8, length u16, payload`. |
| `EVC_Bytes` | Bytes and little endian fields, read and written byte by byte. |
| `EVC_Received` | What came from the track: the last accepted telegram and radio message (bits plus packet index), the counts by status, a reader on packet I. |
| `EVC_Distances` | Distances in cm (integers, saturating) and the senses of the odometer frame (Plus: towards cab A). |
| `EVC_Odometry` | The odometer frame and its confidence from the odometer port's counters (never decreasing), the monitoring of the odometer accuracy (3.6.8, A.3.1), the cold movement detection read at power-up (3.15.8), virtual positions for the distances not referred to balise groups (3.6.7). |
| `EVC_Balise_Groups` | One passage over a balise group: its telegrams with the frame position of their balises; location reference, orientation, crossing direction (3.4.1, 3.4.2). |
| `EVC_Linking` | The linking information of packet 5 as a chain of cumulated distances (3.4.4, 3.6.3.2.6). |
| `EVC_Location` | Reference balise groups as anchors in the odometer frame, the confidence interval against them (3.6.4.1), location items and their relocation to the SOLR (3.6.4.2.5). |
| `EVC_Position` | The train position: orientation from the cab status, LRBG, SOLR, ORBGs, expectation windows and linking reactions, geographical position, the content of the position report and its triggers; the events for the JRU and the later phases. |
| `EVC_Origins` | The origins of the stored location based information: per group message its location reference as the three location items of Table 2a, relocated by `EVC_Position` with its own items (3.6.4.2.5). |
| `EVC_Profiles` | Locations of the stored information as offsets from an origin; stores of elements with replacement (3.7.3.1), deletion in rear (A.3.1) and coverage (3.7.2.3); the lower envelope of elements, proved sorted and never above any element (the MRSP of 3.13.7, the gradient profile). |
| `EVC_Train_Data` | The Train Data the stored information and the supervision use, with a documented default train (entry from the DMI: phase E4). |
| `EVC_National_Values` | Packet 3 in on-board units, applicable now or at D_VALIDNV, the countries of 3.18.2, the defaults of A.3.2. |
| `EVC_Track_Description` | SSP with the train categories, gradients, ASP, TSR and their revocation, default gradient for TSR, level crossings, adhesion, route suitability (3.7.3, 3.11, 3.12.2, 3.12.5). |
| `EVC_Movement_Authority` | The level 1 MA: sections, danger point, overlap, EOA/SvL and release speed (3.8.3, 3.8.4.5), the section, End Section, overlap and LOA timers and their effects (3.8.4), the signalling related speed restriction (3.11.6), the mode profile (3.12.4). |
| `EVC_Track_Conditions` | Track conditions of packets 68, 39 and 67, their indication (5.18) and planning orders, the areas of lost braking (3.13.2.3.4). |
| `EVC_Stored_Information` | The third step of the cycle: the group messages of the cycle, the deletions of A.3.4, the `Snapshot_T` (MRSP with its TSR flags, gradients with their coverage and the default gradient for TSR, MA, braking inhibitions and powerless sections, adhesion areas, temporary EOA and SvL, `Extra`: the configuration of the on-board, the use of A_NVMAXREDADHn, the trip margin), the planning and the track conditions for the DMI, the JRU records. |
| `EVC_Supervision_Input` | The boundary between the third and the fourth step (the two halves of phase E3): `Snapshot_T`, what the speed and distance monitoring reads each cycle (types only). |
| `EVC_Fixed` | The integer arithmetic of the supervision: speeds in cm/s, squares of speeds, times in ms, divisions rounded down or up, integer square root, km/h conversions. |
| `EVC_Braking` | The braking models of 3.13.2.2 and 3.13.6: the deceleration steps, A.3.7 (basic deceleration), A.3.8 / A.3.9 (conversion model), the correction factors (Kdry_rst, Kwet_rst, Kv_int, Kr_int, Kt_int, Kn), A_MAXREDADH, the special brakes and the combinations of Table 4; decelerations in 1e-5 m/s². |
| `EVC_Profile` | The track under the curves (3.13.4, 3.13.5): segments of the gradient acceleration for the train length and the rotating mass (with the default gradient for TSR where the profile gives nothing, for the targets due to a TSR, 3.13.4.1.3), reduced adhesion, brake inhibitions and powerless sections, ahead of the train. |
| `EVC_Curves` | The EBD, SBD and GUI of 3.13.8 as arcs of parabola in fixed point, rounded to the safe side; speed at a location, location of a speed, the extremes of A.3.12.2. |
| `EVC_Limits` | The supervision limits of 3.13.9.3: the speed margins, EBI, SBI1 / SBI2, W, P, I and the permitted speed, from the curves and the times. |
| `EVC_Build_Up` | The reduced brake build up times of A.3.12 (T_be_reduced, T_bs_reduced) in fixed point, never shorter than the formulas. |
| `EVC_SDM` | The speed and distance monitoring of 3.13.10 and 3.13.11: the target list (the EOA and SvL the closest of the MA's and the temporary ones, 3.13.1.5), the release speed (given or calculated, 3.13.9.4), CSM / TSM / RSM and their commands and statuses (Tables 5 to 16), the MRDT and the displayed values, the indication location, the service brake feedback (A.3.10), the pawl (A.3.13), the perturbation location. |
| `EVC_Brake_Commands` | The brake command handling of 3.14: the SDM commands, the service brake failure (3.14.1.2), roll away and reverse movement protection (3.14.2, 3.14.3) with D_NVROLL and the acknowledgement at standstill; the TIU outputs (EB, SB, TCO). |

The ERTMS/ETCS language (SUBSET-026 chapters 7 and 8) is in `language/`:

| Package | Role |
|---|---|
| `ETCS_Bits` | `Reader` and `Writer` of bit strings, MSB first, variables of 1 to 64 bits; total operations with a sticky `Failed` flag. |
| `ETCS_Variables` | *Generated.* One type per variable of 7.5, the special values, `To_X`, `Code`, `Is_Valid` (not a spare value, BCD numbers), `Valid_Code (V, Code)`, `Bits (V)`, `Max (V)`. |
| `ETCS_Track_Packets.P<n>`, `ETCS_Train_Packets.P<n>` | *Generated.* One package per packet: `Packet_T` (loops as bounded arrays with their count, conditions as components plus `Has_` flags), `Decode` (structural), `Valid` (no spare value, 3.16.1.1.1), `Encode`. |
| `ETCS_Catalogue` | *Generated.* NID_PACKET to kind, direction, name, clause, senders; `Check` (decode any kind, and `Valid`), `Skip` by L_PACKET. |
| `ETCS_Message_Catalogue` | *Generated.* The radio messages of 8.6 and 8.7: variables and packet rules. |
| `ETCS_Packet_Index` | Scan of one packet: header, length, decode and spare value check; the index entry. |
| `ETCS_Telegram` | The Eurobalise telegram of 8.4.2: 210 or 830 user bits, header checks, versions, index of the packets, no spare value, only packets a balise transmits; building (header, 255, padding with ones to 210 or 830 bits). |
| `ETCS_Message` | The radio message of 8.4.4: L_MESSAGE, the sender (RBC or RIU) of the message and of each packet, variables, no spare value, mandatory and optional packets by the message catalogue; building. |

The generated units come from `language/etcs_language.toml` (format:
`language/SCHEMA.md`) by `language/gen_language.py`, never by hand:
`python3 evc/language/gen_language.py` regenerates, `--check` fails when
a checked-in file differs, `--stats` prints the sizes of the packet
records (a packet is decoded on the stack, on demand). The generator also
writes `test/src/etcs_language_random.ad[sb]`, the random valid packets
of the tests.

What phase E0 does: power-up in NP, NP -> SB (condition [4]), isolation
by the driver from any mode (condition [1], driver action 20), and every
cycle MSG_MODE_LEVEL and MSG_ONBOARD on the DMI port; a JRU event on every
mode change. Inputs of the wrong shape are ignored and counted. Phase E1: the
telegrams and radio messages are parsed at the next cycle, the last
accepted of each is kept and recorded on the JRU port, the rejections are
counted by reason. Phase E2: a telegram comes with the odometer stamp of
its balise; the position (`EVC_Position`, second step of the cycle) puts
the telegrams of a balise group together, checks them against the stored
linking, sets the LRBG and the SOLR, keeps the confidence interval from the
odometer's over- and under-reading amounts, monitors the odometer accuracy,
reads the cold movement detection, follows the active cab for the train
orientation and computes the geographical position (MSG_STATUS to the
DMI). It detects and reports (queries, JRU events 4 to 10): reacting on a
linking error, an impaired odometer or a cold movement is phases E3 and E4,
sending the position report E5.
Phase E3 (the stored information and the supervision, joined on
`e3/integrate`): the third step of the cycle takes the balise groups the
position took into account, converts their location based information
into offsets from an origin that relocation moves (3.6.4.2), stores it
with the replacement rules of 3.7.3, runs the timers of the MA of level 1
(3.8.4) and the deletions they ask (A.3.4), and builds the `Snapshot_T`:
the MRSP of 3.13.7 (proved sorted and never above any of its sources)
with the segments due to a TSR, the gradient profile with its coverage
and the default gradient for TSR, the MA with its EOA, SvL (never before
the EOA) and release speed, the temporary EOA and SvL of a mode profile
or a level crossing, the braking inhibition areas and powerless sections,
the adhesion areas, national values, Train Data and the configuration of
the on-board. It sends MSG_PLANNING while an MA is supervised and
MSG_TRACK_COND when the indications of 5.18 change, and records event 32
on the JRU. The fourth step, `Monitor_Speed_And_Distance`, runs
`EVC_SDM.Step` and `EVC_Brake_Commands.Step` on that snapshot (the tests
may set one in its place, `EVC_Core.Set_Snapshot_For_Test`). Its outputs
are MSG_SPEED_STATE every cycle (speeds, distance to target, monitoring,
status, release speed), the brake indication and the time to indication
in MSG_STATUS, the TIU output (EB, SB, TCO and the reasons, see
`EVC_Ports.TIU_Output`) when it changes and every cycle while a command
is active, and the JRU events 20 (brake commands), 21 (supervision) and
22 (the EOA or LOA, or the SvL, passed). Everything is in integers with
the rounding to the safe side; `evc_test` compares the curves, limits,
release speeds and reduced build up times with a floating point
reference of the formulas. Level and mode
filters (4.8), tripping on an overrun, the reactions (trip, route
suitability), the procedures' brake reasons, the data entry and the MA
request are phases E4 and E5. Until the modes of E4 the on-board stays
in Stand By, where the standstill supervision (4.4.7.1.5) brakes a train
that moves more than D_NVROLL without an MA.

Checks:

```
evc/prove.sh           # gnatprove: flow and proof, no unproved check
obj/evc_test           # golden runner (test/golden/evc/), UPDATE=1 records
EVC_DUMP=dir obj/evc_test && test/tools/evc_dump.py --diff old.bin new.bin
                       # what changed in the output of a golden
obj/evc_fuzz           # random inputs, must end with raised: 0
python3 evc/language/gen_language.py --check   # generated code up to date
```

The hosted TCP main is `ports/hosted/evc.adb`, built as `obj/evc_onboard`
(`obj/evc` is the object directory of `etcs_evc.gpr`): it takes the hub
port 1338 of `evc_sim` and moves DMI protocol frames between the socket
and the DMI port.
