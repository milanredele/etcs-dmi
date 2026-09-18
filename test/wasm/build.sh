#!/bin/sh
# Build test/wasm/dmi.wasm and test/wasm/evc.wasm inside the GNAT-LLVM
# container (see Dockerfile); the image is built on first use.
set -e
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
IMAGE=etcs-dmi-wasm

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
   docker build --platform linux/amd64 -t "$IMAGE" "$ROOT/test/wasm"
fi

docker run --rm --platform linux/amd64 \
   -v "$ROOT":/src -w /src/test/wasm "$IMAGE" sh -ec '
   mkdir -p obj
   gprconfig --batch -o obj/llvm.cgpr \
      --db /opt/adawebpack/share/gprconfig --target=llvm --config=ada,,
   gprbuild -p --config=obj/llvm.cgpr -P etcsdmi_wasm.gpr "$@"
   ls -l dmi.wasm evc.wasm' -- "$@"
