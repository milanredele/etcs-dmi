# ETCS DMI v4.0.0 — Verified Gap Analysis and Implementation Plan

> **Status (2026-08-16):** Phases 0–3 and the simulator/regression
> infrastructure are implemented (see git history from `e0c7394`).
> Remaining scope: Phase 4 (ATO displays 8.5, chapter 15 message
> catalogue wiring), Phase 5 (NTC chapters 9/12, soft-key layout,
> embedded optimisation), and the simplifications noted below:
> alphanumeric keyboards / multi-tap, full data checks (10.3.4),
> VBC/radio/language windows, LSSMA toggling details, ST07 bitmap,
> fonts regenerated with full ASCII at sizes 10/16/17/18.

This document supersedes [ANALYSIS.md](ANALYSIS.md). Every claim in that document was
checked against the actual SRS text in
[doc/SRS/ERA_ERTMS_015560_v400/sections/](doc/SRS/ERA_ERTMS_015560_v400/sections/) and
against the source code; most of it turned out to be wrong (see §1). Sections 2–4 are a
verified re-analysis, §5 is the implementation plan, §6 the test-tool/simulator plan.

---

## 1. Review of ANALYSIS.md — claim by claim

| # | ANALYSIS.md claim | Verdict | What the SRS actually says |
|---|---|---|---|
| 1 | Missing `NAS` (No Applicable Status), "v4.0.0 Section 7 specifies transitions" | **Fabricated** | No "NAS" / "No Applicable Status" anywhere in the SRS. The five statuses are NoS, OvS, WaS, IntS, IndS (7.2.1–7.5.3). |
| 2 | Missing `OSM` (On-Sight Monitoring), "updated LS behaviour per 7.1.1.2" | **Fabricated** | No "OSM" anywhere. Monitoring types are CSM, TSM, RSM only. 7.1.1.2 is a two-sentence pointer to Figures 11/12. The *real* change: **PIM was deleted** — section 7.3 is "Intentionally deleted", and the code still implements PIM. |
| 3 | Speed pointer: "IndS in CSM raises Program_Error, but v4.0.0 describes specific indication transitions" | **False** | Table 8 (8.2.1.2.5) has no IndS row under CSM; IndS exists only in TSM and RSM (7.2 vs 7.4/7.5). The `raise Program_Error` in [draw_speed_pointer.adb:39](src/display-b_area-speed_dial-draw_speed_pointer.adb#L39) marks a genuinely impossible case. |
| 4 | "8.2.1.4 defines Basic Speed Hook and Target Speed Hook" | **False** | 8.2.1.4 is the CSG (its Vperm "hook" is 6×20 cells, 8.2.1.4.7). Basic Speed Hook(s) are 8.2.1.5: two 10×20-cell hooks at Vperm and Vtarget (8.2.1.5.4/.5). "Target speed hook" as a named object exists only in chapter 9 (STM displays). The code already implements this correctly. |
| 5 | "8.1.1.4 assigns B6 to Layer −2; a layer engine is required" | **Half true** | B6 *is* on Layer −2 (8.1.1.4 c, along with B3–B8). But layers (5.1.1.2) are a *border/depth drawing convention* — bordered areas nested in layer 0 form −1, bordered areas inside −1 form −2 — not a z-order/occlusion engine. The only superimposition-order clause is 8.3.2, and it applies to planning-area objects only. |
| 6 | "Use LUTs instead of Sin/Cos for embedded targets" | Opinion, not an SRS gap | Legitimate optimisation, optional. See §5, Phase 0 notes — the real embedded-budget problem is framebuffer RAM, not trig. |
| 7 | "v4.0.0 Section 5 updated RGB constants for GREY / MEDIUM_GREY / DARK_GREY" | **False** | Table 4 (5.2.1.3.1) lists 12 colours whose RGB values are *identical* to [general_parameters.ads](src/general_parameters.ads). The amendment record contains no colour change. No "contrast on newer LCDs" rationale exists in the document. |
| 8 | "8.2.1.1.13 defines a non-linear 0–400 scale; current code uses simple linear mapping" | **False on both ends** | The 400 km/h dial is 8.2.1.1.11 (8.2.1.1.13 is the 180 dial). It is two *linear* segments breaking at 200 km/h / +48°, and [speed_dial.adb:40-46](src/display-b_area-speed_dial.adb#L40-L46) **already implements exactly this**. |
| 9 | "Figure 11 provides a rigorous state transition graph" | **False** | Figure 11 is "Colour philosophy and supervision limits", explicitly non-normative (7.1.1.2: "only give a general overview"). Chapter 7 delegates the transition conditions to Subset-026 §3.13 (7.1.1.1). |
| 10 | "Sound priorities in Section 14 clarified" | Misleading | Chapter 14 defines just 4 sounds. Priority/FIFO rules for acknowledgements live in 5.4.1.9; Sinfo triggers are scattered across chapters 5, 7 and 8 (see §5, Phase 2). |

**Bottom line:** of the checkable claims, one is true (B6 on layer −2), two are partially
true, and the rest are fabricated or factually wrong — including both headline "missing
features" (NAS, OSM). ANALYSIS.md also missed every substantive v4.0.0 change that
*does* affect this codebase (PIM removal, Level 3 removal, AD/SM modes, ATO, B8, …).
It should not be used as a basis for work.

---

## 2. What is actually implemented (and broadly conformant)

- **Area B**: speed dial B0 with all four ranges incl. the two-segment 400 dial
  (8.2.1.1); speed pointer + digital speed in B1 with per-mode/status colour logic
  (Table 8, v3.4 flavour); CSG with Vperm hook and OvS/WaS/IntS widening (8.2.1.4);
  Basic Speed Hooks (8.2.1.5); release speed digital in B6 (8.2.1.6); mode symbol in B7.
- **Area A**: LSSMA in A1 (8.2.1.7), distance-to-target digital in A2 (8.2.2.2),
  distance bar with log scale in A3 (8.2.2.1).
- **Area C**: mode acknowledgement + level announcement in C1 (flashing yellow frame),
  override in C7, level in C8.
- **Area D**: Track Ahead Free question box only (8.2.3.3, partial — answer is not wired
  to any input).
- **Supervision status derivation** per chapter 7 prose, incl. WaS/IntS hysteresis —
  but including the now-deleted PIM.
- **Infrastructure**: generic per-area framebuffer with fonts (cap heights 10/12/16/17/18),
  border/frame/button-frame drawing, symbol blitting; near-complete *v3.4.0* symbol set
  (LE01–15, MO01–22, NA01–23, PL01–36, SE, ST01–06, TC01–37, DR, LX, LS01).
- **Test tool**: Node WS↔TCP bridge + canvas client; one-way 16-byte state telegram with
  CRC-16 ([dmi_protocol.ads](src/dmi_protocol.ads)), layout auto-extracted from the Ada
  spec by [protocol.js](test/tools/protocol.js).

---

## 3. Real v4.0.0 deltas to the existing code (small, do first)

1. **Remove PIM** — SRS 7.3 is "Intentionally deleted". Touches
   [speed_and_distance.ads](src/speed_and_distance.ads),
   [speed_and_distance.adb](src/speed_and_distance.adb),
   [draw_speed_pointer.adb](src/display-b_area-speed_dial-draw_speed_pointer.adb),
   [speed_dial.adb](src/display-b_area-speed_dial.adb).
2. **Remove Level 3** — v4.0.0 level symbols are LE01–LE12 only; there is no L3.
   Drop `L3` from `Level_T`, drop LE_13/14/15 from
   [symbol.ads](src/symbol.ads) and the C1/C8 mappings in
   [display-c_area.adb](src/display-c_area.adb).
3. **Add AD and SM modes** — MO23 (Automatic Driving) and MO24 (Supervised Manoeuvre)
   in Table 60; Tables 8/9/10/11 give AD its own colour rows (white replaces
   yellow/orange) and group SM with FS/OS. Extend `Mode_T`, B7, pointer/CSG/hook logic.
   While there, audit `Mode_T` against the full v4 mode list.
4. **"CSM with target information"** variant of Table 8 (National Value–gated): grey
   below Vtarget / white between Vtarget and Vperm even in CSM.
5. **Add sub-area B8** (centre (140,216), 36×36, layer −2; 6.3.1.2 g) — missing from
   `ID_T` in [display.ads](src/display.ads). Hosts SM direction (8.2.3.10), coasting
   advice (8.5.10), ATO info.
6. **Release speed digital colour** — Table 11: yellow (medium grey in AD);
   currently hard-coded MEDIUM_GREY in [speed_dial.adb:167](src/display-b_area-speed_dial.adb#L167).
7. **Graphical release speed on the CSG** per 8.2.1.6.3/.4 (outer part of the CSG,
   1-cell separator, Vperm part 3 cells) — current rendering approximates this.
8. **Comment audit** — clause numbers in comments refer to v3.4.0; renumber against
   v4.0.0 while doing the above.

Not a delta, but flagged for the embedded goal: the four area buffers already hold
~190 kB at 1 byte/pixel (B alone is 84 kB) against the 128 kB RAM target. Packing
`Color` to 4 bits (12 colours) halves this; worth doing when the E/F/G buffers are
added, and more impactful than the trig→LUT idea.

---

## 4. Missing scope (verified against the SRS chapter by chapter)

| SRS | Missing functionality | Size |
|---|---|---|
| 5.1.1.3, 5.3.2, 5.4 | Button model (up/down/delay types, states, click sound), acknowledgement FIFO with 1 s spacing and priority order (5.4.1.9.1), generic flashing-frame service | M |
| 5.3.1, 10.x | Window subsystem: default vs sub-level windows, title bar with "(n/m)", navigation buttons, menu windows, **data entry** (4 keyboard types, input-field states, echo text, data checks 10.3.4), validation windows, data view windows | XL |
| 5.5, 5.2.2/5.2.3 | Languages; luminance & volume adjustment (with Settings windows) | M |
| 7 + 14 | Sounds: click, Sinfo, S1, S2 and *all* their trigger points (7.2.3.3, 7.4.1.1, 7.4.3.3, 7.4.4.3, 7.5.1.1, 5.4.1.5, 8.2.2.3.6, 8.2.2.5.7, 8.2.3.4 h, 8.2.3.11) with LS/AD suppression rules | M |
| 8.2.2.3–8.2.2.5 | Brake intervention indication C9 + ack, speed-info toggle function, **TTI in A1** | M |
| 8.2.3.4 | Text messages E5–E9 with scrolling (NA15/NA16 in E10/E11) and ack flow | L |
| 8.2.3.5–8.2.3.11 | Track conditions B3–B5 with queueing; tunnel stopping area C2–C4 + toggle; adhesion A4; LX01; **Set Speed in B0**; SM direction B8; BMM inhibition C6 | L |
| 8.3 | **Whole planning area** (D1–D14): distance scale + zoom, orders/announcements overview, gradient profile, speed profile discontinuities, PASP, indication marker | XL |
| 8.4 | Radio connection E1, reversing-permitted C6, local time G13, geographical position G12 + toggle | M |
| 8.5 | **Whole ATO block**: status G1 + engage button F9, stopping points, stopping accuracy, dwell time, doors, skip-stop F10, target advice speed B0, coasting advice B8, advice-change marker | XL |
| 8.6 | F1–F5 sub-level window buttons (Main, Override, Special, Settings, Radio data) | S (once buttons exist) |
| 11 | All ETCS sub-level windows: Main/Override/Special/Settings/Radio data menus, ~16 data entry windows (Driver ID, Level, Train data incl. flexible/switchable, TRN, SR data, VBC, ATO selector, radio…), validation + data view windows, **start-up dialogue sequence** (11.7.2), parent/child navigation (11.6, Table 48) | XL |
| 13 | Symbols: add MO23, MO24, ST07, ATO01–21, SM01/02, PL37 (BMPs for most are in [doc/.../symbols/](doc/SRS/ERA_ERTMS_015560_v400/symbols/); ST07 bitmap is absent and needs authoring); regenerate via [utils/bmp2ada.c](utils/bmp2ada.c) | S |
| 15 | ~32 system status messages with start/end conditions, routed through the text-message machinery | M |
| 9, 12 | NTC default window, STM services, NTC/ATO data windows | XL — propose **out of scope** until the ETCS side is complete |
| 6.3.1.6 | Soft-key technology layout (H/I areas, F1–F10) | Propose out of scope; target touch-screen layout (already the basis of `display.ads`) |
| — | **Driver input path**: nothing exists — no touch handling, no DMI→EVC channel | prerequisite for most of the above |

---

## 5. Implementation plan

Phases are ordered by dependency; each has an exit criterion tied to the test tool so
progress stays demonstrable.

### Phase 0 — v4.0.0 alignment of existing code (S)
The eight items of §3. No new subsystems.
*Exit:* existing scenarios render identically except PIM removal, AD/SM selectable in
the test tool, release-speed digital yellow.

### Phase 1 — Platform: input, protocol v2, UI primitives (L)
The enabling layer everything else sits on.

1. **Protocol v2** (replaces the 16-byte telegram): framed, typed, CRC-protected
   messages in both directions.
   - EVC→DMI: `SPEED_STATE` (Vcur, Vperm, Vtarget, Vsbi, Vwsl, Visl, Vrelease,
     d_target, monitoring type — stop synthesising Vwsl/Visl/Vsbi in
     [dmi.adb:137-139](src/dmi.adb#L137-L139) and stop hard-coding TSM), `MODE_LEVEL`
     (mode, level, acks pending, override), `PLANNING` (gradient/PASP/order lists),
     `TRACK_COND`, `TEXT_MSG`, `ATO_STATE`, `TIME_GEO`.
   - DMI→EVC: `DRIVER_ACTION` (button id / ack id / toggle), `DATA_ENTRY_RESULT`.
   - DMI→test-client only: framebuffer (as today) + `SOUND` events.
   - Keep the [protocol.js](test/tools/protocol.js) approach of deriving the JS codec
     from the Ada spec, or generate both from one description file.
2. **Touch input**: client forwards canvas pointer events; DMI hit-tests against a
   button registry.
3. **Button engine** per 5.3.2 (up/down/delay types, enabled/pressed/disabled, repeat
   function, click sound event).
4. **Window manager** per 5.3.1: a window = full-screen composition of areas; sub-level
   windows cover the default window; only the newest responds to input. This is a
   window *stack*, not the imaginary "layer engine" — layers stay what 5.1.1.2 says
   (border nesting), already served by the existing border drawing.
5. **Flashing-frame + ack service** per 5.1.1.3/5.4: 0.25 s toggle, FIFO, priority
   order, Sinfo on offer.
6. **Sound engine**: DMI raises sound ids; test client plays the WAVs already in
   [doc/.../sounds/](doc/SRS/ERA_ERTMS_015560_v400/sounds/); S2 is continuous
   (start/stop), others one-shot.
7. **E/F/G/Y/Z rendering** (buffers or one packed full-screen buffer; take the 4-bit
   colour packing from §3 here).

*Exit:* a demo window with working buttons, a flashing ack that can be acknowledged by
clicking, click/Sinfo audible in the browser.

### Phase 2 — Complete the ETCS default window (XL)
Everything in §4 rows 8.2.x–8.6 except ATO: text messages + scrolling, brake
intervention + ack, TTI, speed-info toggle, track conditions incl. tunnel stopping
area, adhesion, LX, Set Speed, BMM, radio status, reversing, time, geo position,
F1–F5 buttons (windows behind them may open as stubs), and the **planning area**
(recommended order: distance scale + zoom → PASP → gradient → orders/announcements →
indication marker, layered per 8.3.2).

*Exit:* with the simulator driving a scripted run, the default window shows every
object of chapter 8 (minus 8.5) at the right place, colour and time; sounds fire per
chapter 7.

### Phase 3 — Windows and data entry (XL)
Chapter 10 generics first (menu window, input fields + keyboards + checks + echo,
validation, data view), then the chapter 11 windows on top, then the start-up dialogue
sequence (11.7.2, Figure 136) and parent/child navigation (Table 48).

*Exit:* full cold-start: Driver ID → Level → Train data entry + validation → TRN →
Start, all driven from the browser, ending in SR/FS driving.

### Phase 4 — ATO + system status messages + symbol completion (L)
8.5 in full (needs Phase 1 buttons + Phase 2 planning area), chapter 15 messages routed
through the Phase 2 text-message machinery, symbol regeneration per §4 row 13.

*Exit:* scripted ATO run: engage via F9, station stop with stopping accuracy, dwell
countdown, door states, skip-stop, coasting advice.

### Phase 5 — Deferred / optional
NTC default window + STM services (ch. 9), NTC/ATO sub-level windows (ch. 12),
soft-key layout, trig→LUT and further embedded optimisation, real target bring-up
(framebuffer + touch + audio drivers behind the existing `Display.Frame_Buffer`
interface).

---

## 6. Test tool → track/train simulator

The SRS never covers the tool, but almost every DMI behaviour is *reactive to a
driving situation* (monitoring transitions, planning data, acks, ATO), so manually
poking parameter sliders cannot reach most of the spec. The tool becomes a small
simulator with the current sliders kept as a "manual override" panel.

**Architecture** (all in the browser; [server.js](test/tools/server.js) stays a dumb
WS↔TCP bridge):

- **Track model** (JSON files, one per scenario): a list of segments with gradient,
  static speed profile, plus point objects — EOA/LOA targets with/without release
  speed, level transitions, mode profiles (OS/SH areas), track conditions
  (start/end + type), tunnel stopping areas, level crossings, radio holes, stations
  with stopping point + dwell time.
- **Train model**: position/speed integration at ~10 Hz from simple traction/brake
  curves; driver desk UI (throttle/brake lever, or "auto-drive at Vperm − margin" /
  "follow ATO advice").
- **EVC model** (simplified Subset-026): computes MRSP from the track, picks the most
  restrictive target, derives P/W/SBI supervision limits from a constant-deceleration
  braking curve, runs the CSM→TSM→RSM transitions and release speed, runs mode/level
  state machines, emits acks, text messages and track-condition announcements at the
  right distances, feeds ATO state. Sends protocol-v2 state; consumes driver actions
  coming back from the DMI.
- **Scenario engine**: a scenario = track file + scripted events (timed or
  position-based: "at km 2.3 EVC requests OS ack", "driver ignores warning") +
  **assertions** ("expect S2 sound", "expect ack request id", "expect frame checkpoint").
- **DMI view**: the existing canvas, now also forwarding pointer events and playing
  sound events.

**Status (2026-09)**: the DMI and the EVC simulator also build to WebAssembly
(`test/wasm/`, GNAT-LLVM + AdaWebPack in Docker) and run in the browser as two
separate modules joined by a fault-injecting wire (latency, jitter, loss, duplication,
reordering, MTU, link cut); `smoke.js` proves the wasm rendering identical to the
native goldens. The DMI supervises the EVC link (silence beyond
`EVC_Link_Timeout_Ms` → mode SF, `evc_link_lost` golden). Still open for a real
Ethernet link: per-message integrity (CRC/sequence numbers) — not needed while the
transport is TCP or the in-page wire.

**Regression testing**: a headless Node runner (no browser) executes scenario scripts
against the compiled `dmi` binary, captures framebuffer output at named checkpoints
(the `Dump` procedure in
[display-frame_buffer.ads](src/display-frame_buffer.ads#L84) already exists), and
compares against golden frames plus protocol-level expectations (sound events, driver
prompts). Run it in CI.

**Coverage matrix**: one file mapping SRS requirements → scenario IDs, so "covers all
features" is checkable. Seed scenario families:

1. **Braking-curve run**: CSM cruise → TSM entry (Sinfo, TTI) → OvS/WaS/IntS
   excursions (S1/S2, pointer/CSG colours per Tables 8/9) → RSM with release speed →
   stop at EOA. Repeat per speed-dial range and in AD (white palette).
2. **Mode transitions**: SB → SR → FS → OS (ack in C1) → SH → TR/PT, RV; SM initiate/
   exit; B7 symbol + ack flow each time.
3. **Level transitions**: announcement with and without ack, C1/C8 sequence.
4. **Track conditions & planning**: pantograph/neutral-section/tunnel sequence
   crossing the train; B3–B5 queueing, C2–C4 toggle, planning-area overview + PASP +
   gradient + indication marker + zoom.
5. **Text messages & acks**: queue depth > visible rows (scrolling), simultaneous ack
   requests exercising the 5.4.1.9.1 priority order.
6. **Start-up data entry** (Phase 3): full dialogue incl. invalid input hitting each
   data-check class of 10.3.4.
7. **ATO service run** (Phase 4): engage, stop with over/under-shoot, dwell, doors,
   skip stop, coasting advice.
8. **Degraded situations**: radio loss (ST03/ST04), balise read error, brake
   intervention + release ack — chapter 15 messages.

**Suggested build order** (interleaved with the phases): protocol v2 + manual panel
(with Phase 1) → track/train/EVC braking model + scenario runner (start of Phase 2 —
it is the tool that makes Phase 2 testable) → sound playback + pointer forwarding
(Phase 1) → golden-frame CI (during Phase 2) → ATO/track-condition scripting
(Phase 4).
