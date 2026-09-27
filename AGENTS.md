# AI Agent Instructions for ETCS-DMI

This document provides context and guidelines for AI agents (GitHub Copilot and others) working on the **European Train Control System (ETCS) Driver Machine Interface (DMI)** implementation.

## Project Context
- **Domain**: ETCS DMI, ERA_ERTMS_015560 version 4.0.0 (text under `doc/SRS/ERA_ERTMS_015560_v400/sections/`).
- **System specification**: SUBSET-026 v4.0.0, reference [2] of the DMI specification, is under `doc/SRS/SUBSET-026_v400/` (index with DMI entry points in its `README.md`). Use it for what the on-board does (supervision statuses, modes and transitions, procedures). The markdown of both documents is a search aid: when a table, figure or legend matters, check the PDF page.
- **Scope**: the ETCS DMI with the touch screen layout. NTC (chapters 9 and 12) and the soft-key technology are out of scope by decision (PLAN.md status note); do not implement them.
- **Backlog**: PLAN.md §7, from the audit in `doc/AUDIT-2026-09.md`. Cite real clause numbers only; re-read the clause before relying on a finding.
- **Core Technology**: **Ada 2012** (GNAT compiler).
- **Embedded Constraints**: Targeting resource-constrained systems (32-bit ARM/POWER MCUs, ~128kB RAM, ~1MB Flash).
- **No dependencies**: The application uses only standard GNAT libraries; no external graphics or OS libraries are allowed.
- **Architecture**: Framebuffer-based rendering with fonts and symbols pre-rendered as Ada source bitmaps.

## Codebase Structure
The repository holds two products that share a wire protocol: the DMI and the
ETCS on-board (EVC). The on-board is being built in phases, see
[doc/EVC-PLAN.md](doc/EVC-PLAN.md).

- **`dmi/`** — the DMI. `DMI_Core` is the transport independent core
  (Initialise / Handle_Message / Tick / Render / Take_Outbox) and supervises
  the EVC link (silence → mode SF).
    - `Display`: layout and coordinate ranges ([dmi/display.ads](dmi/display.ads)).
    - `Display-X_Area`: sub-packages per screen area (A, B, C, D, …), following ETCS naming.
    - `Display-Frame_Buffer`: pixel drawing ([dmi/display-frame_buffer.ads](dmi/display-frame_buffer.ads)).
- **`evc/`** — the ETCS on-board, SUBSET-026. `EVC_Core` has the same shape as
  `DMI_Core` (Initialise / Handle_Input / Tick / Take_Outputs) behind enumerated
  ports (BTM, RTM, odometer, TIU, DMI, ATO, JRU). Its safety kernel is SPARK
  (`SPARK_Mode`), proven with gnatprove: see the plan for what is in the kernel.
- **`common/`** — shared by both: the DMI–EVC protocol
  ([common/dmi_protocol.ads](common/dmi_protocol.ads)) and `DMI_Link`, the
  reassembly of protocol frames from any byte stream.
- **`sim/`** — the environment simulator for the bench and the regression
  runners: track, train dynamics, automatic driver, the ATO on-board, and
  `EVC_Mock`, the simplified on-board the DMI goldens were recorded against
  (kept until the real on-board replaces it, plan phase E4).
- **`ports/hosted/`** — the native TCP mains `dmi.adb` and `evc_sim.adb` for the
  hub setup. The wasm glue lives with the bench in `test/wasm/`; a Hercules
  port comes in plan phase E8.
- **Testing & Tooling**:
    - `test/wasm/`: browser test bench. The DMI and the EVC simulator are built to WebAssembly (`build.sh`, Docker + GNAT-LLVM/AdaWebPack) and run as two modules; `index.html` is the display, touch screen, desk and a fault-injecting wire; `smoke.js` cross-checks the wasm rendering against the native goldens.
    - `test/tools/`: a Node.js hub ([server.js](test/tools/server.js)) and HTML client ([client.html](test/tools/client.html)) for the TCP setup; `frame2png.py` renders frame dumps.
    - `test/src/`: the golden-frame regression runner (`dmi_test`), the fuzzer and host-only helpers (`Display.Screen.Files`) — keep file I/O and GNAT-only packages out of `dmi/`, `evc/`, `common/` and `sim/`, which must build for the wasm32 light runtime and the bare-board runtimes (no tasking, no exception propagation, no `Interfaces.C`, no dynamic allocation).
- **Utilities (`utils/`)**:
    - C programs for converting `.ttf` and `.bmp` files into Ada source constants.
- **Build projects**: `etcsdmi.gpr` builds everything on the host (Alire crate);
  `etcs_evc.gpr` is the on-board alone for the cross and proof builds;
  `test/wasm/etcsdmi_wasm.gpr` the bench.

## Guidelines for AI Agents

### 1. Ada 2012 Implementation
- **Strong Typing**: Use Ada subtypes and ranges extensively ([dmi/display.ads](dmi/display.ads#L34-L52)) to enforce safety at compile-time and runtime.
- **Naming Convention**: Use `Parent-Child.ads/adb` for packages, translated to `parent-child.ads/adb` file names (e.g., `Display.Area_A` is in [dmi/display-a_area.ads](dmi/display-a_area.ads)).
- **No Dynamic Allocation**: Avoid `new` or `Unbounded_String`. All data structures must be static or stack-allocated.

### 2. Graphics and Rendering
- All coordinates and dimensions are defined in [dmi/display.ads](dmi/display.ads). Refer to this file for any UI-related changes.
- Framebuffer interaction should only happen through `Display.Frame_Buffer`.

### 3. Workflow and Building
- **Build**: Use `alr build` to compile the project (Alire package manager). Alternatively, `gprbuild -P etcsdmi.gpr` can be used. The on-board alone: `gprbuild -P etcs_evc.gpr`; for the TMS570, `ports/tms570/build.sh` (toolchain via `ports/tms570/setup-toolchain.sh`).
- **Proof**: `evc/prove.sh` (gnatprove on `etcs_evc.gpr`) must report no unproved check. Every unit under `evc/` is `SPARK_Mode => On`; a unit that cannot be SPARK says why in its header.
- **Robustness**: `obj/dmi_fuzz` and `obj/evc_fuzz` must report `raised: 0`. Code under `dmi/`, `evc/` and `common/` must never raise on any message, input, touch or tick: validate and ignore, clamp, or draw nothing.
- **Regression**: `obj/dmi_test` and `obj/evc_test` must stay at zero failures; `UPDATE=1` re-records goldens only after an intended change, and a changed golden is looked at before it is re-recorded.
- **Visual Testing** (browser bench): `test/wasm/build.sh`, then serve the repository over HTTP and open `test/wasm/`; `node test/wasm/smoke.js` verifies the wasm build.
- **Visual Testing** (TCP setup):
    1. Start the hub: `node test/tools/server.js`
    2. Open `test/tools/client.html` in a browser.
    3. Run the compiled `dmi` and `evc_sim` binaries (or `evc_onboard`, the real on-board, in place of the simulator).

### 4. Safety Considerations
- This project implements a safety-critical interface. When suggesting logic, prioritize clarity, predictability, and conformance to ETCS specifications over "clever" solutions.
