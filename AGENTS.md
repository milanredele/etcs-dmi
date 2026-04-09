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
- **Testing & Tooling (`test/tools/`)**:
    - A Node.js server ([test/tools/server.js](test/tools/server.js)) and HTML client ([test/tools/client.html](test/tools/client.html)) visualize framebuffer data sent over TCP.
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
- **Build**: Use `gprbuild -P dmi.gpr` to compile (GPR project file).
- **Visual Testing**:
    1. Start the server: `node test/tools/server.js`
    2. Open `test/tools/client.html` in a browser.
    3. Run the compiled `dmi` binary.

### 4. Safety Considerations
- This project implements a safety-critical interface. When suggesting logic, prioritize clarity, predictability, and conformance to ETCS specifications over "clever" solutions.
