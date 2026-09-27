# Build environment for the WebAssembly build of the DMI and the EVC
# simulator: GNAT-LLVM with the AdaWebPack wasm32 runtime (prebuilt for
# Ubuntu 22.04 / x86_64; runs under emulation on Apple Silicon).
#
#   docker build --platform linux/amd64 -t etcs-dmi-wasm test/wasm
#   test/wasm/build.sh
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg make gprbuild gnat file \
 && curl -sL https://apt.llvm.org/llvm-snapshot.gpg.key \
      | gpg --dearmor -o /usr/share/keyrings/llvm.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/jammy/ llvm-toolchain-jammy-16 main" \
      > /etc/apt/sources.list.d/llvm16.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends lld-16 clang-16 \
 && rm -rf /var/lib/apt/lists/* \
 && ln -s /usr/bin/wasm-ld-16 /usr/local/bin/wasm-ld \
 && ln -s /usr/bin/clang-16 /usr/local/bin/clang

ARG AWP_URL=https://github.com/godunko/adawebpack/releases/download/24.0.0/adawebpack-24.0.0.tar.gz
RUN curl -sL "$AWP_URL" | tar xz -C /opt

# gprconfig expects the binder driver under libexec, Ubuntu installs it in lib
RUN mkdir -p /usr/libexec && ln -s /usr/lib/gprbuild /usr/libexec/gprbuild

ENV PATH=/opt/adawebpack/bin:$PATH
WORKDIR /src
