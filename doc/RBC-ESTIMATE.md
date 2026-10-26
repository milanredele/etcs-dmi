# What an RBC would cost, compared with the on-board (2026-10-26)

**Answer.** An RBC built in this repository's style comes to about 32k
lines of kernel Ada and 25k of harness: about 49 rounds, 1700 USD of agent
cost and 3 weeks at the observed pace. The range is 29 to 75 rounds, 1000
to 2600 USD, 2 to 4.5 weeks. This assumes level 2, one system version, the
codec reused, a generic interlocking interface, and no operator HMI or
EuroRadio safety layer.

That is about half of what the on-board has taken so far (about 99
round-equivalents, 3296 USD, 4 weeks), although SUBSET-026 gives the RBC
only 17 % of the on-board's behavioural rows (325 against 1887). The
difference is the RBC's own core: the MA computed from routes, the track
database, many trains and the interlocking link. SUBSET-026 leaves these to
"external trackside systems (interlockings, ...), for which no
interoperability requirement will be established" (2.4.1.3 d)), and they
carry most of the uncertainty.

## What the on-board cost (measured at a8790912)

- **Size.** `find <tree> -name '*.ad[sb]' -exec cat {} + | wc -l`:
  - `evc/` has 75203 lines. 20539 of them are generated in `evc/language`
    (1444 there are hand-written, `grep -L generated`), so 54664 are
    hand-written, in 67 top-level specs.
  - The harness has 51013 lines in `test/src` `evc_*`, `s076_*` and
    `scn_*` (`evc_test*` 31506, the SUBSET-076 runner 14791), plus 5821
    in `sim/`.
- **Proof.** 13531 checks at the round-53 integration.
- **Runner.** 1163 passed, 1075 failed and 952 blocked of 3190 sequences.
- **Scope.** All of chapter 9, re-classified with `trace_subset026.py`'s
  own parser (`classify(parse_markdown(MD))`), has 5466 clauses: 1973
  on-board only, 425 both, 492 trackside only and 2576 neither.
  `doc/TRACE-SUBSET-026.csv` holds only the 2398 on-board rows. Of those,
  2052 are done, 73 partial, 236 deferred, 35 n/a and 2 todo.
- **Time.**
  - 29 days from E0 (2026-09-27) to the last integration (2026-10-25).
  - E0 to E4 took 5 days, then 53 numbered rounds followed; the plan has 51
    "E5 integration" subsections on 19 dates.
  - 1171 commits since 2026-09-27.
- **Cost.**
  - `doc/ROUNDS.csv` measures 258 agents for 3296 USD: 1593 for E0 to E4
    and preparation, 1704 for the numbered rounds. It covers every round
    from round 1 (judgement columns from round 26) but not the
    coordinating session.
  - A round costs 34.6 USD, the mean of rounds 44 to 53.
  - E0 to E4 wrote 59.2k lines of `evc/` and 33.4k net of harness
    (`git diff --shortstat 132d1b76 75311eae`); E5 and E6 added 24.5k and
    26.9k. Over the whole on-board that is 29.6 USD per 1000 lines of
    hand-written Ada, or 1.17k lines a round.
- **The DMI.** 18.4k lines of hand-written Ada (plus 50.1k of generated
  fonts) and 10.5k lines of tests, built 2026-09-14 to 09-26 (157 commits;
  its cost is not measured). Its specification has 1416 clause lines on 305
  pages, against SUBSET-026's 3632 on 839 (`clause.py --specs`).

## What an RBC is

The trackside rows number 917 (by chapter: 1: 2, 3: 294, 4: 1, 5: 45, 6:
187, 7: 306, 8: 82). Three groups need no new work:

- **Language (chapters 7 and 8, 388 rows).** The codec already encodes and
  decodes both directions (`ETCS_Message.Write_Fields` and `Parse`).
- **Older system versions (6.5, 183 rows).** These are not needed for a
  single-version RBC.
- **Infill (3.9, 17 rows).** This belongs to the radio infill unit.

That leaves 325 behavioural rows. The main groups are:

| Section | Rows | What it covers |
|---|---|---|
| 3.6 | 51 | Position reports and their use |
| 3.15 | 33 | Mostly the RBC/RBC handover (3.15.1: 24) |
| 3.12 | 31 | Text messages and level crossings |
| 3.13 | 31 | Inputs to supervision |
| 3.7 | 27 | Completeness responsibility (3.7.2) |
| 3.11 | 27 | SSP and gradients |
| 5.10.3 | 25 | Level transition orders |
| 3.8 | 21 | MA structure (3.8.3) |

Beyond SUBSET-026, an RBC needs:

- an interlocking interface;
- a track database, where the EVC has one configuration image
  (`EVC_Config`, 1298 lines);
- a table of N trains;
- the RBC/RBC protocol. SUBSET-039 and -098 are cited in chapter 2 but not
  imported;
- optionally, EuroRadio's trackside side and the KMC (SUBSET-037, -038,
  -114). The on-board skipped its own safety layer too.

Reusable from the on-board:

- the codec (20.5k generated lines);
- the session pattern of `EVC_Sessions` (5921 lines) and `EVC_Radio` (888);
- the RTM port format in `EVC_Ports`;
- `EVC_Position`'s arithmetic (4029), read in mirror;
- `evc/restrictions.adc` and the proof setup;
- `Sim_RBC` (558 lines, scripted), which an RBC kernel would replace in
  `Sim_Onboard_Env`, with the real on-board at the other end.

**Testing.** SUBSET-076 tests the on-board, but 525 of its 1144 sv30
sequences carry radio traffic: 3892 messages from the RBC and 3486 expected
from the train. Replayed in reverse, they can check an RBC's sessions and
acknowledgements exactly. They can check its MA content only against a
track database rebuilt from each sequence's own packets.

## The estimate

**Method.** Each part was sized from the on-board unit most like it.

- **Harness.** Taken as about 0.8 of the kernel, below the on-board's 1.04
  (56.8k to 54.7k), because `Scn_Reader`, the bench and the test support
  are reused.
- **Rounds.** 1.17k lines and 34.6 USD each.
- **Weeks.** 2.4 rounds per calendar day: 51 integrations in 21 days.

| | EVC measured (to date, unfinished) | RBC low / likely / high |
|---|---|---|
| SUBSET-026 rows | 2398 (1887 behavioural) | 325 behavioural, 388 language reused |
| Other specifications | 027, 034, 036, 037 (part), 040, 041, 076, DMI | 037 trackside, 039/098 (absent), 040, interlocking (none) |
| Kernel lines | 54.7k + 20.5k generated | 20k / 32k / 48k |
| Harness lines | 56.8k | 14k / 25k / 40k |
| Units (top-level specs) | 67 | 15 / 25 / 35 |
| Proof checks (0.18 per line) | 13531 | 3500 / 6000 / 9000 |
| Rounds | 53 + 46 equivalents (E0 to E4: 1593 / 34.6 USD) | 29 / 49 / 75 |
| Agent cost | 3296 USD | 1000 / 1700 / 2600 USD |
| Calendar | 4.1 weeks | 1.7 / 2.9 / 4.4 weeks |

| RBC part (likely) | Kernel lines | Share | Analogue |
|---|---|---|---|
| MA builder: 3.8.3, 3.7.2, emergency stops 3.10, TSR, texts, SR/SH authorisations, transition orders 5.10.3 | 7k | 22 % | `EVC_Radio_Authority` 2.8k plus stored information |
| Track database, loader and validator (plus 2k Python) | 6k | 18 % | `EVC_Config` and stored information, 7.2k |
| Sessions with N trains: 3.5, 3.16.3, version | 5k | 15 % | `EVC_Sessions` and `EVC_Radio`, 7.1k |
| Train table and position report use: 3.6.5, 3.18.3 | 4k | 12 % | `EVC_Position` 4.0k |
| Interlocking interface (plus 1.5k simulator in `sim/`) | 3k | 9 % | none |
| RBC/RBC handover: 3.15.1, 5.15 | 3k | 9 % | `EVC_Sessions.Handover` 0.5k |
| Core, ports, cycle | 3k | 9 % | `EVC_Core` 5.6k |
| Operator commands (no HMI) | 1.5k | 5 % | none |
| EuroRadio safety layer and KMC | 0 (high: 5k) | 0 % | none |

**What moves the estimate most.**

1. **The interlocking interface.** A generic route-state abstraction is in
   the figures. A real protocol (EULYNX SCI-RBC or a national one, neither
   in `doc/SRS`) could double that part.
2. **The safety case.** The figures assume a proof of absence of run-time
   errors, like the on-board's. Functional proofs (an MA never passes the
   end of a locked route) push towards the high end.
3. **The outer layers.** An HMI like the DMI adds about 24 rounds; the KMC
   and safety layer about 8.

The number of trains changes static bounds, not lines. The parts without a
specification wait on the user's decisions, not on the agents' pace.

**A first round, as a spike.** Write the RBC's session half as a SPARK
kernel behind the RTM port format. Swap it for `Sim_RBC` in
`Sim_Onboard_Env`, drive a level 2 start of mission against the real
on-board, and check it with the reverse replay of some sv30 sequences'
session messages. The round would measure the cost per trackside row, fix
the shape of the train table, and give a draft of the interlocking
interface.
