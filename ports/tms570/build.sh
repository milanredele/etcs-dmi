#!/bin/sh
# Cross build of the ETCS on-board for the TMS570LC43x (Cortex-R5F,
# big-endian BE-32) with the light runtime installed by setup-toolchain.sh.
# Run from anywhere; extra arguments go to gprbuild, e.g.
#
#   ports/tms570/build.sh              # etcs_evc.gpr, objects in <Object_Dir>/tms570
#   ports/tms570/build.sh -f -v        # force, verbose
#   ETCS_PROJECT=/path/other.gpr ports/tms570/build.sh
#
# The runtime's own project already imposes the target switches
# (runtime.xml: -mbig-endian -mbe32 -marm -mcpu=cortex-r5 -mfpu=vfpv3-d16
# -mfloat-abi=hard); they are repeated here so the command documents them
# and a different runtime cannot silently change the ABI.
set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ETCS_TOOLS=${ETCS_TOOLS:-$HOME/.local/share/etcs-dmi}
ETCS_PROJECT=${ETCS_PROJECT:-$ROOT/etcs_evc.gpr}
RTS=$ETCS_TOOLS/runtimes/light-tms570lc

TOOLCHAIN=
for d in "$ETCS_TOOLS"/gnat_arm_elf_16.1.0_*; do
   [ -x "$d/bin/arm-eabi-gcc" ] && TOOLCHAIN=$d
done
if [ -z "$TOOLCHAIN" ] || [ ! -f "$RTS/adalib/libgnat.a" ]; then
   echo "toolchain or runtime missing: run ports/tms570/setup-toolchain.sh" >&2
   exit 1
fi
GPRBUILD_BIN=
if command -v gprbuild >/dev/null; then
   GPRBUILD_BIN=$(dirname "$(command -v gprbuild)")
else
   for d in "$HOME"/.local/share/alire/toolchains/gprbuild_*/bin; do
      [ -x "$d/gprbuild" ] && GPRBUILD_BIN=$d
   done
fi
PATH=$TOOLCHAIN/bin:$GPRBUILD_BIN:$PATH
export PATH

TARGET_FLAGS="-mbig-endian -mbe32 -marm -mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard"

cd "$ROOT"
set -x
gprbuild -p -P "$ETCS_PROJECT" --target=arm-eabi --RTS="$RTS" --subdirs=tms570 \
   "$@" \
   -cargs $TARGET_FLAGS -O2 -ffunction-sections -fdata-sections \
   -largs $TARGET_FLAGS -Wl,--gc-sections
{ set +x; } 2>/dev/null

# Sizes: every object of the cross build and, if the project has mains,
# the executables in the object directory (linked with the runtime's
# loram.ld unless -XLOADER=FLASH|HIRAM|USER is given).
XARGS=
for a in "$@"; do
   case "$a" in -X*) XARGS="$XARGS $a" ;; esac
done
# shellcheck disable=SC2086
OBJ_DIR=$(gprinspect -P "$ETCS_PROJECT" --target=arm-eabi --RTS="$RTS" \
            --subdirs=tms570 $XARGS --display=textual 2>/dev/null \
          | sed -n 's/^ *- Object directory *: *//p' | head -1)
if [ -z "$OBJ_DIR" ] || [ ! -d "$OBJ_DIR" ]; then
   echo "object directory not found, no sizes" >&2
   exit 0
fi
OBJECTS=$(find "$OBJ_DIR" -maxdepth 1 -name '*.o' -type f | sort)
if [ -n "$OBJECTS" ]; then
   # shellcheck disable=SC2086
   arm-eabi-size -t $OBJECTS
fi
EXECS=
for f in $(find "$OBJ_DIR" -maxdepth 1 -type f -perm -u+x | sort); do
   if arm-eabi-readelf -h "$f" 2>/dev/null | grep -q 'EXEC (Executable'; then
      EXECS="$EXECS $f"
   fi
done
if [ -n "$EXECS" ]; then
   # shellcheck disable=SC2086
   arm-eabi-size $EXECS
fi
