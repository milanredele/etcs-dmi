#!/bin/sh
# The whole host check of the repository, as AGENTS.md requires before a
# merge: build everything, run the four test programs, the generator and
# catalogue checks and the coverage matrix check, the ERTMSFormalSpecs
# frames (test/efs/, optional: both skip when the folder or the EFS
# checkout is absent) and the SUBSET-076 test sequences (also optional:
# evc_s076_check, the codec, and evc_s076_run, the sequences replayed
# against the on-board and compared with test/s076/baseline.csv, skip
# the corpus when the sibling checkout, ../etcs-subset076 or
# $S076_CHECKOUT, is absent; the runner's own fixture runs always). The SPARK proof (evc/prove.sh) and the
# cross build (ports/tms570/build.sh) are separate, they take long.
#
#   test/check.sh            # build and check
#   FUZZ_STEPS=1000000 test/check.sh
#
# On macOS the Alire toolchain needs the SDK path for the link; the
# native toolchain and gprbuild are taken from ~/.local/share/alire if
# they are not on PATH already.
set -e
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

if [ "$(uname)" = Darwin ] && [ -z "$SDKROOT" ]; then
   SDKROOT=$(xcrun --show-sdk-path)
   export SDKROOT
   export LIBRARY_PATH="$SDKROOT/usr/lib"
fi
for d in "$HOME"/.local/share/alire/toolchains/gprbuild_*/bin \
         "$HOME"/.local/share/alire/toolchains/gnat_native_*/bin; do
   [ -d "$d" ] && PATH="$d:$PATH"
done
export PATH

steps=${FUZZ_STEPS:-200000}

gprbuild -s -j0 -p -q -P etcsdmi.gpr
# the on-board alone, with its own switches: the style checks and the
# restrictions of evc/restrictions.adc
gprbuild -s -j0 -p -q -P etcs_evc.gpr

# The checks are independent programs on one core each: they run side by
# side, every one into its own file, and are reported in this order when
# all have ended (CHECK_SERIAL=1 runs them one after the other, for a
# machine with few cores or to read a trace).
tmp=$(mktemp -d "${TMPDIR:-/tmp}/etcs-check.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
names=""
start() {   # start <name> <lines shown> <command...>
   name=$1
   lines=$2
   shift 2
   names="$names $name"
   echo "$lines" > "$tmp/$name.n"
   echo "$*" > "$tmp/$name.cmd"
   if [ -n "${CHECK_SERIAL:-}" ]; then
      "$@" > "$tmp/$name.out" 2>&1 && echo 0 > "$tmp/$name.rc" \
         || echo $? > "$tmp/$name.rc"
   else
      ( "$@" > "$tmp/$name.out" 2>&1 && echo 0 > "$tmp/$name.rc" \
           || echo $? > "$tmp/$name.rc" ) &
   fi
}

start dmi_test 1 ./obj/dmi_test
start dmi_fuzz 1 ./obj/dmi_fuzz
start evc_test 1 ./obj/evc_test
# the stored information phase: its line and the cycles by mode
start evc_fuzz 2 ./obj/evc_fuzz "$steps"
start gen_language 1 python3 evc/language/gen_language.py --check
start check_catalogue 1 python3 evc/language/check_catalogue.py
start trace 1 python3 doc/SRS/tools/trace_subset026.py --check
start efs_frames 1 python3 test/tools/efs_frames.py --check
start golden_review 1 python3 test/tools/golden_review.py --check-tool
start subprogram_size 1 python3 test/tools/subprogram_size.py --check
start evc_efs_test 1 ./obj/evc_efs_test
start evc_s076_check 1 ./obj/evc_s076_check
start evc_s076_run 1 ./obj/evc_s076_run
wait

# Every result in the order above; a failing check shows its last lines
# and fails the script with its exit status (a plain "cmd | tail -1"
# would take the exit status of tail and lose the check's).
failed=0
for name in $names; do
   status=$(cat "$tmp/$name.rc" 2>/dev/null || echo 99)
   if [ "$status" -ne 0 ]; then
      tail -n 12 "$tmp/$name.out"
      echo "check.sh: FAILED: $(cat "$tmp/$name.cmd") (exit $status)" >&2
      [ "$failed" -ne 0 ] || failed=$status
   else
      tail -n "$(cat "$tmp/$name.n")" "$tmp/$name.out"
   fi
done
[ "$failed" -eq 0 ] || exit "$failed"
echo "check.sh: ok"
