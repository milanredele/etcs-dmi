#!/bin/sh
# The whole host check of the repository, as AGENTS.md requires before a
# merge: build everything, run the four test programs, the generator and
# catalogue checks and the coverage matrix check, the ERTMSFormalSpecs
# frames (test/efs/, optional: both skip when the folder or the EFS
# checkout is absent) and the SUBSET-076 test sequences (also optional:
# evc_s076_check skips when the sibling checkout, ../etcs-subset076 or
# $S076_CHECKOUT, is absent). The SPARK proof (evc/prove.sh) and the
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
./obj/dmi_test | tail -1
./obj/dmi_fuzz | tail -1
./obj/evc_test | tail -1
./obj/evc_fuzz "$steps" | tail -1
python3 evc/language/gen_language.py --check | tail -1
python3 evc/language/check_catalogue.py | tail -1
python3 doc/SRS/tools/trace_subset026.py --check | tail -1
python3 test/tools/efs_frames.py --check | tail -1
python3 test/tools/golden_review.py --check-tool | tail -1
./obj/evc_efs_test | tail -1
./obj/evc_s076_check | tail -1
echo "check.sh: ok"
