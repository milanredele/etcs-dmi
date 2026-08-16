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

**Interactive session** (mimics the embedded setup where framebuffer
content is sent to the display driver):
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
failing checks dump the frame as `*.actual` for inspection.

![Sample image](doc/images/sample.png)
![Image of B Area](doc/images/b_area.png)
