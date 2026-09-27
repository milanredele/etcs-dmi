#!/bin/sh
# Install the arm-eabi cross toolchain and the light runtime for the
# TMS570LC43x outside the repository. Idempotent: what is already in place
# is kept (delete a directory below to redo its step). See
# ports/tms570/README.md.
#
#   ETCS_TOOLS   install prefix (default ~/.local/share/etcs-dmi)
#   JOBS         parallel jobs for the libgcc build (default: CPU count)
#
# 1. gnat_arm_elf 16.1.0 (GNAT FSF, Alire community index) is fetched with
#    `alr get` into $ETCS_TOOLS. alr's default toolchain selection is left
#    alone: the cross compiler is used through PATH by build.sh only.
# 2. That compiler's libgcc, crtbegin.o and crtend.o exist only
#    little-endian (--with-multilib-list=rmprofile). A big-endian set for
#    the Cortex-R5F is built from the same GCC 16.1 sources the toolchain
#    was built from (iains/gcc-16-branch, gcc-16.1-darwin-r0) with a C-only
#    arm-eabi GCC (ARM mode, cortex-r5, vfpv3-d16, hard float) whose
#    target libraries are compiled -mbig-endian. Only libgcc.a,
#    crtbegin.o and crtend.o are kept.
# 3. The toolchain ships light-tms570lc (bb-runtimes, Cortex-R5F,
#    big-endian BE-32) without Ada.Streams, which common/ needs for its
#    byte types. The runtime is copied to $ETCS_TOOLS/runtimes/light-tms570lc,
#    Ada.Streams and Ada.IO_Exceptions are added to its gnat_user source
#    directory from the embedded-tms570lc runtime of the same toolchain, it
#    is rebuilt with its own build.py, and the big-endian libgcc of step 2 is
#    installed in its adalib, where the link finds it before the
#    little-endian multilib.
set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ETCS_TOOLS=${ETCS_TOOLS:-$HOME/.local/share/etcs-dmi}
GNAT_VERSION=16.1.0
GCC_TAG=gcc-16.1-darwin-r0
GCC_URL=https://github.com/iains/gcc-16-branch/archive/refs/tags/$GCC_TAG.tar.gz
GCC_SHA256=0c8f5c8acef29e039cd959b18a6b0617e0c9b5af56a92b958962d76232f47aeb
RTS_NAME=light-tms570lc
JOBS=${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}

case "$ETCS_TOOLS/" in
   "$ROOT"/*) echo "ETCS_TOOLS must be outside the repository" >&2; exit 1 ;;
esac
mkdir -p "$ETCS_TOOLS/runtimes" "$ETCS_TOOLS/build"

find_toolchain () {
   for d in "$ETCS_TOOLS"/gnat_arm_elf_"$GNAT_VERSION"_*; do
      if [ -x "$d/bin/arm-eabi-gcc" ]; then echo "$d"; return; fi
   done
}

# --- 1. Toolchain -----------------------------------------------------------
TOOLCHAIN=$(find_toolchain)
if [ -z "$TOOLCHAIN" ]; then
   command -v alr >/dev/null || { echo "alr (Alire) not on PATH" >&2; exit 1; }
   # Never inside the repository: alr would rewrite config/ there.
   (cd "$ETCS_TOOLS" && alr -n get "gnat_arm_elf=$GNAT_VERSION")
   TOOLCHAIN=$(find_toolchain)
   [ -n "$TOOLCHAIN" ] || { echo "gnat_arm_elf not found after alr get" >&2; exit 1; }
fi

# gprbuild: the one on PATH, else the one Alire installed for the host build.
GPRBUILD_BIN=
if command -v gprbuild >/dev/null; then
   GPRBUILD_BIN=$(dirname "$(command -v gprbuild)")
else
   for d in "$HOME"/.local/share/alire/toolchains/gprbuild_*/bin; do
      [ -x "$d/gprbuild" ] && GPRBUILD_BIN=$d
   done
fi
[ -n "$GPRBUILD_BIN" ] || { echo "gprbuild not found (alr toolchain --select installs it)" >&2; exit 1; }
PATH=$TOOLCHAIN/bin:$GPRBUILD_BIN:$PATH
export PATH

# --- 2. Big-endian libgcc -----------------------------------------------------
LIBGCC_BE=$ETCS_TOOLS/libgcc-be-cortex-r5f
if [ ! -f "$LIBGCC_BE/libgcc.a" ] || [ ! -f "$LIBGCC_BE/crtbegin.o" ]; then
   B=$ETCS_TOOLS/build
   SRC=$B/gcc-16-branch-$GCC_TAG
   LOG=$B/libgcc-be.log
   if [ ! -d "$SRC" ]; then
      [ -f "$B/$GCC_TAG.tar.gz" ] || curl -sSL -o "$B/$GCC_TAG.tar.gz" "$GCC_URL"
      echo "$GCC_SHA256  $B/$GCC_TAG.tar.gz" | shasum -a 256 -c - >/dev/null
      (cd "$B" && tar xzf "$GCC_TAG.tar.gz")
   fi
   [ -d "$SRC/gmp" ] || (cd "$SRC" && ./contrib/download_prerequisites) >> "$LOG" 2>&1
   if [ "$(uname -s)" = Darwin ] && [ -z "$SDKROOT" ]; then
      SDKROOT=$(xcrun --show-sdk-path); export SDKROOT
   fi
   echo "building a big-endian libgcc (C-only arm-eabi GCC $GNAT_VERSION, log $LOG)..."
   rm -rf "$B/gcc-be"
   mkdir -p "$B/gcc-be"
   # The arm port has no --with-endian (big-endian by default would be the
   # armeb-eabi triplet, with an assembler to match): the compiler defaults
   # to the Cortex-R5F in ARM mode with hard float, and the target
   # libraries are compiled -mbig-endian.
   (cd "$B/gcc-be" && "$SRC/configure" \
      --target=arm-eabi --prefix="$B/gcc-be-install" \
      --with-build-time-tools="$TOOLCHAIN/arm-eabi/bin" \
      --enable-languages=c --disable-multilib \
      --with-mode=arm --with-cpu=cortex-r5 \
      --with-fpu=vfpv3-d16 --with-float=hard \
      CFLAGS_FOR_TARGET="-g -O2 -mbig-endian" \
      --with-newlib --without-headers --without-isl \
      --disable-shared --disable-threads --disable-tls --disable-nls \
      --disable-lto --disable-plugin --disable-decimal-float \
      --disable-libssp --disable-libgomp --disable-libquadmath \
      --disable-libffi --disable-libstdcxx \
      --with-pkgversion="etcs-dmi libgcc BE cortex-r5f" \
      && make -j"$JOBS" all-gcc \
      && make -j"$JOBS" all-target-libgcc) >> "$LOG" 2>&1 || {
      echo "libgcc build failed, see $LOG" >&2; exit 1; }
   # Refuse anything but big-endian objects.
   for f in crtbegin.o crtend.o libgcc.a; do
      if arm-eabi-readelf -h "$B/gcc-be/arm-eabi/libgcc/$f" | grep -q 'little endian'; then
         echo "libgcc build produced little-endian objects ($f)" >&2; exit 1
      fi
   done
   rm -rf "$LIBGCC_BE"
   mkdir -p "$LIBGCC_BE"
   for f in libgcc.a crtbegin.o crtend.o; do
      cp "$B/gcc-be/arm-eabi/libgcc/$f" "$LIBGCC_BE/$f"
   done
fi

# --- 3. Runtime ---------------------------------------------------------------
SHIPPED=$TOOLCHAIN/arm-eabi/lib/gnat
RTS=$ETCS_TOOLS/runtimes/$RTS_NAME
if [ ! -f "$RTS/adalib/a-stream.ali" ] || [ ! -f "$RTS/adalib/libgnat.a" ] \
   || [ ! -f "$RTS/adalib/libgcc.a" ]; then
   [ -d "$SHIPPED/$RTS_NAME" ] || { echo "$SHIPPED/$RTS_NAME missing" >&2; exit 1; }
   rm -rf "$RTS"
   cp -R "$SHIPPED/$RTS_NAME" "$RTS"
   for f in a-stream.ads a-stream.adb a-ioexce.ads; do
      cp "$SHIPPED/embedded-tms570lc/gnat/$f" "$RTS/gnat_user/$f"
   done
   (cd "$RTS" && python3 build.py) > "$ETCS_TOOLS/runtimes/$RTS_NAME.build.log" 2>&1 || {
      echo "runtime build failed, see $ETCS_TOOLS/runtimes/$RTS_NAME.build.log" >&2
      exit 1
   }
   # The link passes -L<runtime>/adalib before GCC's multilib directory:
   # -lgcc resolves to the big-endian libgcc. The C startfiles are named by
   # the runtime's spec file; point it at the big-endian ones.
   cp "$LIBGCC_BE/libgcc.a" "$LIBGCC_BE/crtbegin.o" "$LIBGCC_BE/crtend.o" "$RTS/adalib/"
   printf '*startfile:\n%s/adalib/crtbegin.o\n\n*endfile:\n%s/adalib/crtend.o\n' \
      "$RTS" "$RTS" > "$RTS/link-noexceptions.spec"
fi

echo "toolchain: $TOOLCHAIN ($("$TOOLCHAIN/bin/arm-eabi-gcc" --version | head -1))"
echo "gprbuild:  $GPRBUILD_BIN/gprbuild"
echo "libgcc:    $LIBGCC_BE (big-endian, cortex-r5, vfpv3-d16, hard float)"
echo "runtime:   $RTS"
