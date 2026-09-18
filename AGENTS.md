# AI Agent Instructions for ETCS-DMI

This document provides context and guidelines for AI agents (GitHub Copilot and others) working on the **European Train Control System (ETCS) Driver Machine Interface (DMI)** implementation.

## Project Context
- **Domain**: ETCS DMI version 3.4.0 (Subset-026, Chapter 7).
- **Core Technology**: **Ada 2012** (GNAT compiler).
- **Embedded Constraints**: Targeting resource-constrained systems (32-bit ARM/POWER MCUs, ~128kB RAM, ~1MB Flash).
- **No dependencies**: The application uses only standard GNAT libraries; no external graphics or OS libraries are allowed.
- **Architecture**: Framebuffer-based rendering with fonts and symbols pre-rendered as Ada source bitmaps.

## Codebase Structure
- **Core Logic (`src/`)**:
    - `Display`: Main package defining layout and coordinate ranges ([src/display.ads](src/display.ads)).
    - `Display-X_Area`: Sub-packages for specific screen areas (A, B, C, D, etc.), following ETCS naming.
    - `Display-Frame_Buffer`: Low-level pixel drawing logic ([src/display-frame_buffer.ads](src/display-frame_buffer.ads)).
    - `DMI`: Main entry point and initialization loop ([src/dmi.adb](src/dmi.adb)).
- **Transport (`src/dmi_link.ads`, `src/dmi.adb`)**:
    - `DMI_Link`: generic reassembly of protocol frames from any byte stream; `dmi.adb` is the TCP main. `DMI_Core` is transport independent and supervises the EVC link (silence → mode SF).
- **Testing & Tooling**:
    - `test/wasm/`: browser test bench. The DMI and the EVC simulator are built to WebAssembly (`build.sh`, Docker + GNAT-LLVM/AdaWebPack) and run as two modules; `index.html` is the display, touch screen, desk and a fault-injecting wire; `smoke.js` cross-checks the wasm rendering against the native goldens.
    - `test/tools/`: a Node.js hub ([server.js](test/tools/server.js)) and HTML client ([client.html](test/tools/client.html)) for the TCP setup; `frame2png.py` renders frame dumps.
    - `test/src/`: the golden-frame regression runner (`dmi_test`) and host-only helpers (`Display.Screen.Files`) — keep file I/O and GNAT-only packages out of `src/` and `sim/`, which must build for the wasm32 light runtime (no tasking, no exception propagation, no `Interfaces.C`).
- **Utilities (`utils/`)**:
    - C programs for converting `.ttf` and `.bmp` files into Ada source constants.

## Guidelines for AI Agents

### 1. Ada 2012 Implementation
- **Strong Typing**: Use Ada subtypes and ranges extensively ([src/display.ads](src/display.ads#L34-L52)) to enforce safety at compile-time and runtime.
- **Naming Convention**: Use `Parent-Child.ads/adb` for packages, translated to `parent-child.ads/adb` file names (e.g., `Display.Area_A` is in [src/display-a_area.ads](src/display-a_area.ads)).
- **No Dynamic Allocation**: Avoid `new` or `Unbounded_String`. All data structures must be static or stack-allocated.

### 2. Graphics and Rendering
- All coordinates and dimensions are defined in [src/display.ads](src/display.ads). Refer to this file for any UI-related changes.
- Framebuffer interaction should only happen through `Display.Frame_Buffer`.

### 3. Workflow and Building
- **Build**: Use `alr build` to compile the project (Alire package manager). Alternatively, `gprbuild -P etcsdmi.gpr` can be used.
- **Regression**: `obj/dmi_test` must stay at zero failures; `UPDATE=1` re-records goldens only after an intended rendering change.
- **Visual Testing** (browser bench): `test/wasm/build.sh`, then serve the repository over HTTP and open `test/wasm/`; `node test/wasm/smoke.js` verifies the wasm build.
- **Visual Testing** (TCP setup):
    1. Start the hub: `node test/tools/server.js`
    2. Open `test/tools/client.html` in a browser.
    3. Run the compiled `dmi` and `evc_sim` binaries.

### 4. Safety Considerations
- This project implements a safety-critical interface. When suggesting logic, prioritize clarity, predictability, and conformance to ETCS specifications over "clever" solutions.
