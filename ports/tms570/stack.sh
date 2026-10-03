#!/bin/sh
# Stack of the ETCS on-board on the TMS570: builds the on-board for the
# target with the stack usage and call graph of every unit
# (-fstack-usage -fcallgraph-info=su,da, the build of build.sh otherwise)
# and runs stack.py on them, which reports
#   (a) the frames of the subprograms, largest first,
#   (b) the worst-case stack depth from each entry point of EVC_Core
#       (Initialise, Handle_Input, Tick, Take_Outputs) and of the
#       elaboration, with the path that gives it: the frame of each
#       subprogram plus its deepest callee, calls into the runtime
#       measured from the runtime's own disassembly,
#   (c) and fails when the worst case exceeds BUDGET, or when the call
#       graph has a cycle, an indirect call, a call to nothing or a
#       dynamic frame that is not bounded in stack.py.
#
#   ports/tms570/stack.sh                 # build, report, check the budget
#   STACK_TOP=40 ports/tms570/stack.sh    # the 40 largest frames
#   STACK_NO_BUILD=1 ports/tms570/stack.sh   # report on the last build
#   ports/tms570/stack.sh --path evc_sdm__step   # also the deepest path
#                                                # from a subprogram
#
# The budget is the main stack of the target for the on-board
# (doc/EVC-PLAN.md §2, "Stack"): 32 KiB, the measured worst case (26592
# bytes, 2026-10-03, from Tick) and about 20 % for the executive that
# calls EVC_Core, a last chance handler of E8, a compiler update and the
# growth of the code; a power of two, so that one MPU region of the
# Cortex-R5 can guard it. The interrupts (IRQ/FIQ banked stacks) and the
# secondary stack have their own areas, sized in E8. STACK_BUDGET=0
# reports without the check.
set -e

BUDGET=${STACK_BUDGET:-32768}

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ETCS_TOOLS=${ETCS_TOOLS:-$HOME/.local/share/etcs-dmi}
RTS=$ETCS_TOOLS/runtimes/light-tms570lc
TOOLCHAIN=
for d in "$ETCS_TOOLS"/gnat_arm_elf_16.1.0_*; do
   [ -x "$d/bin/arm-eabi-objdump" ] && TOOLCHAIN=$d
done
if [ -z "$TOOLCHAIN" ]; then
   echo "toolchain missing: run ports/tms570/setup-toolchain.sh" >&2
   exit 1
fi

if [ -z "${STACK_NO_BUILD:-}" ]; then
   "$ROOT/ports/tms570/build.sh" -cargs -fstack-usage -fcallgraph-info=su,da \
      > "$ROOT/obj/evc/stack-build.log" 2>&1 \
      || { cat "$ROOT/obj/evc/stack-build.log" >&2; exit 1; }
   grep TOTALS "$ROOT/obj/evc/stack-build.log" \
      | sed 's/^/size of the objects (text data bss dec hex): /'
fi

exec python3 "$ROOT/ports/tms570/stack.py" \
   --objdir "$ROOT/obj/evc/tms570" --rts "$RTS" \
   --objdump "$TOOLCHAIN/bin/arm-eabi-objdump" \
   --budget "$BUDGET" --top "${STACK_TOP:-20}" "$@"
