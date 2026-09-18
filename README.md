# etcs-dmi

## European Train Control System - Driver Machine Interface (ETCS DMI)
### Goal
My personal goal is to better learn Ada through implementing a well-specified and potentially useful application.

The general goal is to implement Version 4.0.0 of the [ETCS DMI](https://en.wikipedia.org/wiki/European_Train_Control_System#Man_Machine_Interface) according to [specifications published by the European Railway Agency](https://www.era.europa.eu/activities/technical-specifications-interoperability_en#meeting7) (ERA_ERTMS_015560 v4.0.0, included under [doc/SRS](doc/SRS)).
Written in Ada2012 with a strong focus on applicability in resource-limited embedded devices:
primary performance goal is to run on 32bit 200MHz ARM/POWER MCU with 128kB RAM and 1MB ROM, without OS.

See [PLAN.md](PLAN.md) for the implementation status and roadmap.

### Zero dependency
No library is used other than provided by GNAT.

### Building
The project uses the [Alire](https://alire.ada.dev/) package manager. To build the project, run:
```bash
alr build
```
On macOS, if the link step fails with `library not found for -lSystem`,
point the Alire GNAT at the current SDK first:
```bash
export SDKROOT=$(xcrun --show-sdk-path) LIBRARY_PATH=$(xcrun --show-sdk-path)/usr/lib
```

### Fonts & Symbols
Fonts are embedded as bitmaps in source code. FreeSans font is used due to licensing issues and due to similarity to Helvetica (which is recommended by the ERA).
A Freetype based C-program was used to generate Ada code from the TrueType font. It is easily replacable with other font if needed.

Symbols are also embedded as source code. Note: the official bmp files attached to the ERA are 24 bit RGB and some contain other colors than those specified in the ERA - I consider these as errors, they typically look like jpeg or scaling artifacts. These were replaced with the proper color.

### Testing

Three programs are built (`alr build`):
- `obj/dmi` — the DMI itself
- `obj/evc_sim` — an EVC/track/train simulator that drives the DMI
  through a complete mission (braking curves, monitoring transitions,
  level transition, track conditions, TAF, stop at the EOA)
- `obj/dmi_test` — the headless golden-frame regression runner

**Browser test bench** (everything in one page, no hub, no sockets):
the DMI and the EVC simulator are compiled to WebAssembly and run as
two separate modules with their own memories;
[test/wasm/index.html](test/wasm/index.html) is the clock, the display
unit, the touch screen, the driver desk and the wire between them. The
wire is a configurable Ethernet stand-in: latency, jitter, loss,
duplication, reordering, fragmentation (MTU) and a "cut the link"
switch, with live statistics.
1. `test/wasm/build.sh` — builds `test/wasm/dmi.wasm` and `evc.wasm` in
   a Docker container with GNAT-LLVM and the AdaWebPack wasm32 runtime
   (the image is built on first use, see
   [test/wasm/Dockerfile](test/wasm/Dockerfile))
2. serve the repository over HTTP, e.g. `python3 -m http.server 8000`,
   and open <http://localhost:8000/test/wasm/>

The [Browser test bench](.github/workflows/pages.yml) workflow builds
the modules, runs the cross-check below and publishes the page on GitHub
Pages: <https://milanredele.github.io/etcs-dmi/>
(`test/wasm/site.sh <dir>` assembles the same site locally).

`node test/wasm/smoke.js` replays regression scenarios through the
wasm modules and checks the rendered screens against the same golden
digests as the native runner: the two builds render pixel for pixel
the same.

**Interactive session over TCP** (mimics the embedded setup where
framebuffer content is sent to the display driver; also the way to
attach a DMI running on real hardware):
1. `node test/tools/server.js` — the message hub (DMI tcp 1337, EVC tcp
   1338, browser ws 8080)
2. open [test/tools/client.html](test/tools/client.html) in a browser —
   renders the screen, forwards touch input, plays the DMI sounds and
   provides the driver desk (throttle / auto-drive) plus a manual EVC
   panel
3. `obj/dmi` and (for the simulator source) `obj/evc_sim`

Press F1 → Start on the DMI to run the start-up data entry and begin
the mission.

**Regression tests**: `obj/dmi_test` drives the DMI core and the EVC
simulator in process (no sockets) and compares SHA-256 digests of the
rendered screens against [test/golden](test/golden). `UPDATE=1
obj/dmi_test` re-records the goldens after an intended rendering change;
failing checks dump the frame as `*.actual` for inspection, `DUMP=1`
dumps every checked frame, and
[test/tools/frame2png.py](test/tools/frame2png.py) turns a dump into a
PNG.

**EVC link supervision**: the DMI specification does not cover the
DMI–EVC interface, it only defines how a system failure is presented
(8.2.3.1.2, symbol MO18) and that any other means is acceptable when
MO18 cannot be shown (8.2.3.1.2.1). The DMI therefore treats an EVC
that falls silent for longer than
`General_Parameters.EVC_Link_Timeout_Ms` (1 s) as failed: the picture
the EVC provided is discarded and mode SF is shown until the EVC talks
again. Frame reassembly from any byte transport lives in
[src/dmi_link.ads](src/dmi_link.ads), shared by the TCP mains, the wasm
modules and, later, the target's Ethernet driver.

![Sample image](doc/images/sample.png)
![Image of B Area](doc/images/b_area.png)
