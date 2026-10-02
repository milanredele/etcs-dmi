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

# Run a check, show the last N lines of its output and stop with its
# exit status when it fails: a plain "cmd | tail -1" takes the exit
# status of tail and loses the check's (sh has no pipefail), so a failing
# test would let check.sh say ok.
check_tail() {
   n=$1
   shift
   out=$("$@" 2>&1) && status=0 || status=$?
   if [ "$status" -ne 0 ]; then
      printf '%s\n' "$out" | tail -n 12
      echo "check.sh: FAILED: $* (exit $status)" >&2
      exit "$status"
   fi
   printf '%s\n' "$out" | tail -n "$n"
}
check() {
   check_tail 1 "$@"
}

gprbuild -s -j0 -p -q -P etcsdmi.gpr
check ./obj/dmi_test
check ./obj/dmi_fuzz
check ./obj/evc_test
# the stored information phase: its line and the cycles by mode
check_tail 2 ./obj/evc_fuzz "$steps"
check python3 evc/language/gen_language.py --check
check python3 evc/language/check_catalogue.py
check python3 doc/SRS/tools/trace_subset026.py --check
check python3 test/tools/efs_frames.py --check
check python3 test/tools/golden_review.py --check-tool
check ./obj/evc_efs_test
check ./obj/evc_s076_check
check ./obj/evc_s076_run
echo "check.sh: ok"
