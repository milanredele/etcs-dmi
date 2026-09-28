#!/bin/sh
# Build test/wasm/dmi.wasm, evc.wasm and onboard.wasm with GNAT-LLVM and the
# AdaWebPack wasm32 runtime (etcsdmi_wasm.gpr).
#
# Native, when setup-native-toolchain.sh has installed the toolchain under
# $ETCS_TOOLS/adawebpack-native (Apple Silicon Macs); otherwise in the
# linux/amd64 container of the Dockerfile (the image is built on first use).
#   WASM_NATIVE=1  the native toolchain, an error if it is not installed
#   WASM_NATIVE=0  the container even when the native toolchain is there
#   WASM_JOBS=n    gprbuild -jn in the container (default: see below)
# Extra arguments go to gprbuild.
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ETCS_TOOLS=${ETCS_TOOLS:-$HOME/.local/share/etcs-dmi}
AWP=$ETCS_TOOLS/adawebpack-native
IMAGE=etcs-dmi-wasm

case "${WASM_NATIVE:-auto}" in
   1) [ -x "$AWP/bin/llvm-gnat1" ] || {
         echo "no native toolchain in $AWP: run test/wasm/setup-native-toolchain.sh" >&2
         exit 1; }
      NATIVE=1 ;;
   0) NATIVE=0 ;;
   *) if [ -x "$AWP/bin/llvm-gnat1" ]; then NATIVE=1; else NATIVE=0; fi ;;
esac

if [ "$NATIVE" = 1 ]; then
   # gprbuild: the one on PATH, else the one Alire installed for the host build.
   GPRBUILD_BIN=
   if command -v gprbuild >/dev/null; then
      GPRBUILD_BIN=$(dirname "$(command -v gprbuild)")
   else
      for d in "$HOME"/.local/share/alire/toolchains/gprbuild_*/bin; do
         [ -x "$d/gprbuild" ] && GPRBUILD_BIN=$d
      done
   fi
   [ -n "$GPRBUILD_BIN" ] || { echo "gprbuild not found" >&2; exit 1; }
   # The toolchain first: its clang and wasm-ld link the modules.
   PATH=$AWP/bin:$GPRBUILD_BIN:$PATH
   export PATH
   cd "$ROOT/test/wasm"
   mkdir -p obj
   gprconfig --batch -o obj/llvm.cgpr \
      --db "$AWP/share/gprconfig" --target=llvm --config=ada,,,"$AWP/bin"
   gprbuild -j0 -p --config=obj/llvm.cgpr -P etcsdmi_wasm.gpr "$@"
   ls -l dmi.wasm evc.wasm onboard.wasm
   exit 0
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
   docker build --platform linux/amd64 -t "$IMAGE" "$ROOT/test/wasm"
fi

# Parallel on an x86_64 host (CI). Under emulation (an Apple Silicon host,
# Rosetta) a parallel build is about four times slower than a serial one:
# measured 1 h 53 min with -j0 against 29 min with -j1 for a clean build.
case "$(uname -m)" in
   x86_64|amd64) JOBS=${WASM_JOBS:-0} ;;
   *)            JOBS=${WASM_JOBS:-1} ;;
esac

docker run --rm --platform linux/amd64 \
   -v "$ROOT":/src -w /src/test/wasm "$IMAGE" sh -ec '
   mkdir -p obj
   gprconfig --batch -o obj/llvm.cgpr \
      --db /opt/adawebpack/share/gprconfig --target=llvm --config=ada,,
   gprbuild -j'"$JOBS"' -p --config=obj/llvm.cgpr -P etcsdmi_wasm.gpr "$@"
   ls -l dmi.wasm evc.wasm onboard.wasm' -- "$@"
