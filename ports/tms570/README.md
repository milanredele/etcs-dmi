# TI Hercules TMS570LC43x cross build

The ETCS on-board (`etcs_evc.gpr`: `evc/` and `common/`) cross-compiled for
the **TMS570LC4357**, the MCU of the LaunchPad **LAUNCHXL2-570LC43**:
dual Cortex-R5F in lockstep, 300 MHz, 4 MB flash with ECC, 512 kB RAM with
ECC, VFPv3-D16 floating point unit, big-endian. This is the E0 build
check of [doc/EVC-PLAN.md](../../doc/EVC-PLAN.md): it proves the on-board
compiles, with the target's ABI, against a light runtime. Running it on the
board is phase E8.

## Setup

```sh
ports/tms570/setup-toolchain.sh
```

Everything goes outside the repository, under `$ETCS_TOOLS`
(default `~/.local/share/etcs-dmi`). The script is idempotent; delete a
directory to redo its step.

| What | Where | From |
|---|---|---|
| GNAT FSF 16.1.0 `arm-eabi` cross compiler, binutils, gdb | `$ETCS_TOOLS/gnat_arm_elf_16.1.0_<hash>/` | `alr get gnat_arm_elf=16.1.0` (Alire community index, GNAT-FSF-builds release gnat-16.1.0-1) |
| Big-endian `libgcc.a`, `crtbegin.o`, `crtend.o` for Cortex-R5F | `$ETCS_TOOLS/libgcc-be-cortex-r5f/` | built from the GCC 16.1 sources of that release (iains/gcc-16-branch tag `gcc-16.1-darwin-r0`), C only |
| Light runtime `light-tms570lc` with Ada.Streams | `$ETCS_TOOLS/runtimes/light-tms570lc/` | the toolchain's `light-tms570lc` (alire-project/bb-runtimes, tag v15.1.0-1 per the release's build spec; the archive records no revision) plus Ada.Streams, rebuilt |
| GCC build tree (can be deleted) | `$ETCS_TOOLS/build/` | |

alr's default toolchain selection is not changed: the host build keeps
`gnat_native`. The cross compiler is put on `PATH` by `build.sh` only.
`alr` must not be run inside the repository for this (it would rewrite
`config/`); the script runs it in `$ETCS_TOOLS`.

The setup needs `alr`, `gprbuild` (the Alire one is found under
`~/.local/share/alire/toolchains`), `python3`, `curl`, a host C/C++
compiler (Xcode command line tools on macOS) and about 3 GB of disk for the
GCC build, which takes about 4 minutes on a 10-core M-series Mac.

### Why the runtime and libgcc are not used as shipped

The toolchain ships `light-tms570lc`, AdaCore's bb-runtimes light runtime
for the TMS570LC43x. Two things are missing for this project:

1. **Ada.Streams.** The light runtime has no `Ada.Streams`, and
   `common/dmi_protocol.ads` and `common/dmi_link.ads` use
   `Stream_Element`, `Stream_Element_Offset` and `Stream_Element_Array`
   as their byte types. Without it the compilation stops at
   `"Ada.Streams" is not a predefined library unit`. The setup adds
   `a-stream.ads/.adb` and `a-ioexce.ads` of the same compiler (from its
   `embedded-tms570lc` runtime) to the runtime's `gnat_user` source
   directory and rebuilds it with the runtime's own `build.py`. Only the
   types are used; stream attributes (`'Read`, `'Write`) are still not
   available.
2. **A big-endian libgcc.** GNAT-FSF-builds configure GCC with
   `--with-multilib-list=rmprofile`, whose multilibs are all little-endian.
   The link then fails on `crtbegin.o` ("compiled for a little endian
   system and target is big endian"), and on any libgcc helper the code
   needs, such as `__aeabi_ldivmod` for a 64-bit division. The setup
   builds a C-only GCC 16.1 configured `--with-mode=arm
   --with-cpu=cortex-r5 --with-fpu=vfpv3-d16 --with-float=hard` with
   `CFLAGS_FOR_TARGET="-g -O2 -mbig-endian"` (the arm port has no
   `--with-endian`), checks that the result is big-endian, keeps its
   `libgcc.a`, `crtbegin.o` and `crtend.o`, puts them in the runtime's
   `adalib` (searched before the compiler's multilib directory) and points
   the runtime's link spec at the big-endian startfiles.

## Build

```sh
ports/tms570/build.sh [gprbuild switches]
```

runs, from the repository root,

```sh
gprbuild -p -P etcs_evc.gpr --target=arm-eabi \
   --RTS=$ETCS_TOOLS/runtimes/light-tms570lc --subdirs=tms570 [switches] \
   -cargs -mbig-endian -mbe32 -marm -mcpu=cortex-r5 -mfpu=vfpv3-d16 \
          -mfloat-abi=hard -O2 -ffunction-sections -fdata-sections \
   -largs -mbig-endian -mbe32 -marm -mcpu=cortex-r5 -mfpu=vfpv3-d16 \
          -mfloat-abi=hard -Wl,--gc-sections
```

and prints `arm-eabi-size` of every object (and executable) under the
`tms570` object subdirectory (`obj/evc/tms570/`). `ETCS_PROJECT=<gpr>`
builds another project the same way. The target switches are those the
runtime imposes anyway (its `runtime.xml`); they are repeated so the
command documents the ABI. `-O2` is the target's optimisation level; the
host build has none.

A project with a main links with the runtime's `loram.ld` by default;
`-XLOADER=FLASH` links for the flash, `-XLOADER=USER` with a linker script
of our own (phase E8).

### Verified (E0)

Before `etcs_evc.gpr` existed the build was verified with a throw-away
project: `common/dmi_protocol`, `common/dmi_link` instantiated with a
4 kB buffer, a SPARK unit (big-endian decoding, `Float` arithmetic,
contracts) and a main, linked with `loram.ld`:

```
   text    data     bss     dec     hex filename
    189       2       0     191      bf b__probe_main.o
      0       2       0       2       2 dmi_link.o
   1656       2       0    1658     67a dmi_protocol.o
    277       2       0     279     117 probe_kernel.o
   1560       0       0    1560     618 probe_main.o
   3682       8       0    3690     e6a (TOTALS)
   text    data     bss     dec     hex filename
   5812       8   22528   28348    6ebc probe_main
```

The executable is 5.8 kB of code, runtime and startup included. Its bss
is the stacks (20 kB main, 2 kB exception modes); the 4 kB reassembly
buffer of the generic instance is on the main stack. With `-XLOADER=FLASH`
code and constants go at `0x0000_0000` and data at `0x0800_0000`, loaded
from flash. A 64-bit division (`Stream_Element_Offset`) links
`__aeabi_ldivmod` from the big-endian libgcc. The ELF header says
`big endian`, flags `0x5000400` (EABI 5, hard float, no BE-8), and the
attributes say `v7-R`, `VFPv3-D16`, `VFP registers` for arguments.

Compiled with the host project's `-gnatwa`, every run-time check in
`common/` draws a `-gnatw.x` warning: the light runtime imposes
`No_Exception_Propagation`, so a failed check calls the last chance
handler (the board stops) instead of raising. The fuzz rule "never raise"
and the SPARK proof of absence of run-time errors are what make this safe.
`etcs_evc.gpr` can silence the warning with `-gnatw.X` once the proof
covers the kernel.

## Target facts the code relies on

**Memory map** (TMS570LC4357, runtime `ld/tms570.ld`):

| Region | Address | Size | Use |
|---|---|---|---|
| Flash (ECC) | `0x0000_0000` | 4 MB | code and constants (`LOADER=FLASH`) |
| RAM (ECC) | `0x0800_0000` | 512 kB | data, bss, stacks |
| RAM at 0 | `0x0000_0000` | 512 kB | after swapping flash and RAM (BMMCR1), for `LOADER=LORAM` debugging |
| Peripherals | `0xFC00_0000`.. | | RTI, ESM, SCI, EMAC, … |

The runtime's `common.ld` reserves a 20 kB main stack and 2 kB of
exception-mode stacks; `__stack_size` overrides the main stack.

**Endianness.** The TMS570 is big-endian, BE-32 (word-invariant, not the
BE-8 of later ARM cores): `-mbig-endian -mbe32`, and the ELF header shows
no `EF_ARM_BE8` flag. Every multi-byte field on any wire (the DMI protocol,
the SUBSET-026 bit strings, the ports) is read and written byte by byte,
never through an overlay or `Unchecked_Conversion` of a record, so the host
(little-endian), wasm32 (little-endian) and the target agree.

**Floating point.** `Float` is IEEE single precision in the VFPv3-D16, hard
float ABI (`Tag_ABI_VFP_args: VFP registers`). `Long_Float` also runs in
hardware, but the plan excludes it from the on-board.

**`Stream_Element_Offset` is 64-bit** (`Long_Long_Integer`). Comparisons,
additions and subtractions are inline, but a division or `mod` on it calls
libgcc (`__aeabi_ldivmod`), which is why the big-endian libgcc is needed.
Index arithmetic of the kernel is better done in 32-bit types.

**Runtime services.** The light runtime has no tasking, no exception
propagation (a raised exception calls `__gnat_last_chance_handler`), no
heap beyond what the linker script leaves, `Ada.Text_IO` on SCI1/LIN1 at
115200 baud, and the elementary functions for `Float`. Clocks as set by
`system_tms570lc43.c`: PLL 300 MHz, HCLK 150 MHz, VCLK 75 MHz, RTICLK
37.5 MHz.

## What a bring-up on the board still needs (phase E8)

- **Startup.** The runtime's `crt0.S` and `system_tms570lc43.c` set up the
  clocks, stacks, `.data` and `.bss`. Still to do: the RAM ECC
  initialisation (automatic RAM initialisation via `MINITGCR`/`MSINENA`)
  before the first RAM access, the CPU self-test (STC) and PBIST at power
  on, and enabling the flash ECC checks, as TI's HALCoGen startup does.
- **Linker script.** Our own (`LOADER=USER`) for the flash: vectors at 0,
  code and constants in flash, `.data` loaded from flash, the kernel stacks
  sized from measured use, no heap.
- **RTI timer.** A periodic compare interrupt as the tick of the cyclic
  executive (`EVC_Core.Tick`), with an overrun check.
- **ESM.** Error signalling module: lockstep compare errors, RAM/flash ECC
  errors and clock faults reported and mapped to a safe reaction (trip,
  brakes) and to the nERROR pin.
- **Watchdog.** The digital windowed watchdog (DWD) fed from the tick.
- **DMI link.** Ethernet (EMAC and PHY of the LaunchPad) with a small
  UDP/IP or a raw frame format, with CRC and sequence numbers; the SCI
  (115200 baud through the XDS110 USB bridge) as the first, slower link.
  The byte stream feeds `DMI_Link` as on the host.
- **The other ports** (BTM, RTM, odometer, TIU, JRU) over SCI, CAN
  (DCAN) or the same Ethernet link, from the bench simulator.
- **Flashing and debugging.** The XDS110 on the LaunchPad with OpenOCD
  (TMS570 support) or TI UniFlash, and `arm-eabi-gdb` from the toolchain.
- **Measurements.** Worst-case execution time of one tick, stack use
  (`-fstack-usage`), flash and RAM use against the budget.
