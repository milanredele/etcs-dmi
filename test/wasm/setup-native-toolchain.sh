#!/bin/sh
# Install GNAT-LLVM with the AdaWebPack wasm32 runtime natively on an Apple
# Silicon Mac (aarch64-apple-darwin), outside the repository, so that
# test/wasm/build.sh builds the wasm modules without Docker. Idempotent: an
# installed toolchain of the same pinned versions is left alone (delete
# $ETCS_TOOLS/adawebpack-native to reinstall).
#
#   ETCS_TOOLS   install prefix (default ~/.local/share/etcs-dmi)
#   GNAT_BIN     bootstrap GNAT (default: the newest Alire gnat_native)
#   GPRBUILD_BIN gprbuild (default: the one on PATH, else Alire's)
#   ZSTD_LIB     a static libzstd.a (default: Homebrew's, `brew install zstd`)
#
# It is the compiler of the Docker image (Dockerfile: the AdaWebPack 24.0.0
# release for Ubuntu x86_64), rebuilt from the sources that release was
# built from, as its CI (.github/workflows/build.yml at tag 24.0.0) does:
#
#   AdaWebPack   24.0.0 (godunko/adawebpack tag, cd0c10ae): the wasm32
#                runtime (source/rtl, Makefile.target), the gprconfig
#                database (packages/Fedora/llvm.xml) and two patches to
#                gnat-llvm (patches/gnat-llvm.patch: nest attributes of
#                calls; patches/llvm_wrapper2.patch: LLVMCreateTargetMachine
#                WithABI)
#   gnat-llvm    AdaCore/gnat-llvm 66e36d929524972353600db5d604d0189cf0308f
#                (the revision the AdaWebPack CI checks out)
#   GNAT sources GCC 14.1.0 release, gcc/ada only (the CI checks out
#                releases/gcc-14.1.0 of gcc-mirror/gcc)
#   bb-runtimes  Fabien-Chouteau/bb-runtimes branch gnat-fsf-14, head
#                e59080e0c4b49d12e00538595052dea2dceb5a6e (2024-06-05, the
#                head when 24.0.0 was built): the light runtime sources the
#                wasm runtime takes some units from
#   LLVM         16.0.4, the official release build
#                clang+llvm-16.0.4-arm64-apple-darwin22.0 (the CI uses the
#                x86_64 Ubuntu 22.04 build of the same release). gnat-llvm
#                is linked statically with it; clang (the link driver) and
#                lld (wasm-ld) of the same release are installed with it.
#
# Every download is pinned by its SHA-256. The bootstrap compiler is the
# Alire GNAT (tested with gnat_native 15.1.2; the CI uses 14.x): it builds
# the GCC 14 front end with its style checks and warnings off
# (-gnatyN -gnatws), since a newer GNAT flags older sources. Differences to
# the CI build, all in how the compiler is built, not in what it generates:
# gnat-llvm in its Production mode (-O2, the Makefile's build-opt) instead of
# Debug; its two C++ files with Apple clang++ and libc++ (the C++ library the
# LLVM release is built with), linked by the GNAT driver with the system
# libc++ and a static libzstd; the runtime archive made with llvm-ar.
set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ETCS_TOOLS=${ETCS_TOOLS:-$HOME/.local/share/etcs-dmi}
PREFIX=$ETCS_TOOLS/adawebpack-native
B=$ETCS_TOOLS/build/adawebpack-native
DL=$B/dl

AWP_TAG=24.0.0
AWP_URL=https://github.com/godunko/adawebpack/archive/refs/tags/$AWP_TAG.tar.gz
AWP_SHA256=dc942ab4f796bbdfd0ef7defd3ff173e6ef1742c7585296563c5095f72c990dd
GNAT_LLVM_REV=66e36d929524972353600db5d604d0189cf0308f
GNAT_LLVM_URL=https://github.com/AdaCore/gnat-llvm/archive/$GNAT_LLVM_REV.tar.gz
GNAT_LLVM_SHA256=4f3c29e543f41186eef4e471b6565b4e54e2035e275e19d1d40fd34c4811cdb5
GCC_VERSION=14.1.0
GCC_URL=https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz
GCC_SHA256=e283c654987afe3de9d8080bc0bd79534b5ca0d681a73a11ff2b5d3767426840
BB_REV=e59080e0c4b49d12e00538595052dea2dceb5a6e
BB_URL=https://github.com/Fabien-Chouteau/bb-runtimes/archive/$BB_REV.tar.gz
BB_SHA256=17299430bf1c1aa7119fc8a12b6c31290fe216212b05be0187384b3b9cc65535
LLVM_VERSION=16.0.4
LLVM_NAME=clang+llvm-$LLVM_VERSION-arm64-apple-darwin22.0
LLVM_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVM_VERSION/clang%2Bllvm-$LLVM_VERSION-arm64-apple-darwin22.0.tar.xz
LLVM_SHA256=429b8061d620108fee636313df55a0602ea0d14458c6d3873989e6b130a074bd

# What an installed toolchain is stamped with: a change of any pin redoes it.
STAMP="adawebpack $AWP_TAG, gnat-llvm $GNAT_LLVM_REV, gcc $GCC_VERSION, bb-runtimes $BB_REV, llvm $LLVM_VERSION"

case "$ETCS_TOOLS/" in
   "$ROOT"/*) echo "ETCS_TOOLS must be outside the repository" >&2; exit 1 ;;
esac
if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
   echo "this installer builds for aarch64-apple-darwin only (use Docker elsewhere)" >&2
   exit 1
fi

summary () {
   echo "adawebpack-native: $PREFIX ($(du -sh "$PREFIX" | cut -f1))"
   echo "  $(cat "$PREFIX/VERSION")"
   echo "  compiler: $PREFIX/bin/llvm-gcc ($("$PREFIX/bin/llvm-gcc" -v 2>&1 | tail -1))"
   echo "  runtime:  $PREFIX/lib/rts-native (wasm32)"
   echo "  gprconfig database: $PREFIX/share/gprconfig"
   echo "  link: $PREFIX/bin/clang and wasm-ld (LLVM $LLVM_VERSION)"
}

if [ -f "$PREFIX/VERSION" ] && [ "$(cat "$PREFIX/VERSION")" = "$STAMP" ] \
   && [ -x "$PREFIX/bin/llvm-gnat1" ] && [ -f "$PREFIX/lib/rts-native/adalib/libgnat.a" ]
then
   echo "already installed, nothing to do"
   summary
   exit 0
fi

# --- Tools --------------------------------------------------------------------
newest () { # the last of the existing directories given, in version order
   for d in "$@"; do [ -d "$d" ] && echo "$d"; done | sort -V | tail -1
}
GNAT_BIN=${GNAT_BIN:-$(newest "$HOME"/.local/share/alire/toolchains/gnat_native_*/bin)}
[ -x "$GNAT_BIN/gnatmake" ] || {
   echo "no bootstrap GNAT (set GNAT_BIN, or alr toolchain --select gnat_native)" >&2; exit 1; }
if [ -z "$GPRBUILD_BIN" ]; then
   if command -v gprbuild >/dev/null; then
      GPRBUILD_BIN=$(dirname "$(command -v gprbuild)")
   else
      GPRBUILD_BIN=$(newest "$HOME"/.local/share/alire/toolchains/gprbuild_*/bin)
   fi
fi
[ -x "$GPRBUILD_BIN/gprbuild" ] || { echo "gprbuild not found (set GPRBUILD_BIN)" >&2; exit 1; }
if [ -z "$ZSTD_LIB" ]; then
   for f in "$(brew --prefix zstd 2>/dev/null)/lib/libzstd.a" \
            /opt/homebrew/opt/zstd/lib/libzstd.a /usr/local/opt/zstd/lib/libzstd.a; do
      [ -f "$f" ] && { ZSTD_LIB=$f; break; }
   done
fi
[ -f "$ZSTD_LIB" ] || { echo "no static libzstd.a (brew install zstd, or set ZSTD_LIB)" >&2; exit 1; }
[ -x /usr/bin/clang++ ] || { echo "no /usr/bin/clang++ (xcode-select --install)" >&2; exit 1; }

# The Alire GNAT needs the SDK for its C compiles and links.
SDKROOT=$(xcrun --show-sdk-path)
export SDKROOT
LIBRARY_PATH=$SDKROOT/usr/lib
export LIBRARY_PATH
MACOSX_DEPLOYMENT_TARGET=$(sw_vers -productVersion | cut -d. -f1).0
export MACOSX_DEPLOYMENT_TARGET

# --- Sources --------------------------------------------------------------------
mkdir -p "$DL"
fetch () { # url file sha256
   if [ ! -f "$DL/$2" ]; then
      echo "downloading $2"
      curl -fsSL -o "$DL/$2.part" "$1"
      mv "$DL/$2.part" "$DL/$2"
   fi
   echo "$3  $DL/$2" | shasum -a 256 -c - >/dev/null || {
      echo "checksum mismatch: $DL/$2 (delete it to download it again)" >&2; exit 1; }
}
fetch "$AWP_URL" "adawebpack-$AWP_TAG.tar.gz" "$AWP_SHA256"
fetch "$GNAT_LLVM_URL" "gnat-llvm-$GNAT_LLVM_REV.tar.gz" "$GNAT_LLVM_SHA256"
fetch "$GCC_URL" "gcc-$GCC_VERSION.tar.xz" "$GCC_SHA256"
fetch "$BB_URL" "bb-runtimes-$BB_REV.tar.gz" "$BB_SHA256"
fetch "$LLVM_URL" "$LLVM_NAME.tar.xz" "$LLVM_SHA256"

LLVM=$B/$LLVM_NAME
if [ ! -f "$LLVM/.extracted" ]; then
   echo "extracting LLVM $LLVM_VERSION (the parts gnat-llvm needs)"
   rm -rf "$LLVM"
   (cd "$B" && tar xJf "$DL/$LLVM_NAME.tar.xz" \
      --include="$LLVM_NAME/bin/llvm-config" --include="$LLVM_NAME/bin/clang-16" \
      --include="$LLVM_NAME/bin/lld" --include="$LLVM_NAME/bin/opt" \
      --include="$LLVM_NAME/bin/llvm-dis" --include="$LLVM_NAME/bin/llvm-ar" \
      --include="$LLVM_NAME/include/*" --include="$LLVM_NAME/lib/libLLVM*.a" \
      --include="$LLVM_NAME/lib/libclang*.a" --include="$LLVM_NAME/lib/libPolly*.a")
   ln -s llvm-ar "$LLVM/bin/llvm-ranlib"
   touch "$LLVM/.extracted"
fi

# A fresh build tree for gnat-llvm, laid out as the AdaWebPack CI does.
S=$B/src
W=$S/gnat-llvm-$GNAT_LLVM_REV/llvm-interface
LOG=$B/build.log
rm -rf "$S"
mkdir -p "$S"
echo "unpacking the sources"
(cd "$S" && tar xzf "$DL/adawebpack-$AWP_TAG.tar.gz" \
   && tar xzf "$DL/gnat-llvm-$GNAT_LLVM_REV.tar.gz" \
   && tar xzf "$DL/bb-runtimes-$BB_REV.tar.gz" \
   && tar xJf "$DL/gcc-$GCC_VERSION.tar.xz" "gcc-$GCC_VERSION/gcc/ada")
AWP_SRC=$S/adawebpack-$AWP_TAG
(cd "$W" \
   && ln -s "$AWP_SRC" adawebpack_src \
   && ln -s "$S/gcc-$GCC_VERSION/gcc/ada" gnat_src \
   && ln -s "$S/bb-runtimes-$BB_REV" bb-runtimes \
   && ln -s adawebpack_src/source/rtl/Makefile.target Makefile.target \
   && ln -s bb-runtimes/gnat_rts_sources/include/rts-sources rts-sources \
   && patch -s -p1 < adawebpack_src/patches/gnat-llvm.patch \
   && patch -s -p1 < adawebpack_src/patches/llvm_wrapper2.patch)

PATH=$W/bin:$GNAT_BIN:$GPRBUILD_BIN:$LLVM/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PATH

# --- gnat-llvm ------------------------------------------------------------------
# The host configuration: Ada and C with the Alire GNAT (C given the SDK),
# C++ with Apple clang++, and the GNAT driver as the linker (not g++, which
# would bring libstdc++ to an LLVM built against libc++).
mkdir -p "$W/obj"
gprconfig --batch -o "$W/obj/host.cgpr.in" --config=ada,,,"$GNAT_BIN",GNAT \
   --config=c,,,"$GNAT_BIN",GCC --config=c++,,,"$GNAT_BIN",G++ >> "$LOG" 2>&1
sed -e 's|for Driver *("C++") use .*|for Driver ("C++") use "/usr/bin/clang++";|' \
    -e '/Include_Switches_Via_Spec *("C++")/d' \
    -e 's|("-c", "-x", "c") & Compiler|("-c", "-x", "c", "-isysroot", "'"$SDKROOT"'") \& Compiler|' \
    -e 's|for Driver use Compiler.Driver ("C++");|for Driver use Compiler'"'"'Driver ("Ada");|' \
    "$W/obj/host.cgpr.in" > "$W/obj/host.cgpr"
grep -q 'Driver ("C++") use "/usr/bin/clang++"' "$W/obj/host.cgpr" \
   && grep -q '"-isysroot"' "$W/obj/host.cgpr" \
   && grep -q "for Driver use Compiler'Driver (\"Ada\")" "$W/obj/host.cgpr" || {
   echo "could not adapt the gprconfig output, see $W/obj/host.cgpr.in" >&2; exit 1; }

# llvm-config prints one line per option; the static libzstd and the
# system libc++ replace -lzstd and the libc++ of the LLVM release.
LLVM_LDFLAGS="$(llvm-config --ldflags --libs all --system-libs | tr '\n' ' ' \
   | sed "s| -lzstd | $ZSTD_LIB |") $SDKROOT/usr/lib/libc++.tbd"

echo "building gnat-llvm with $GNAT_BIN/gnat (log $LOG)"
(cd "$W" && make build-opt \
   GPRBUILD="gprbuild -v --config=$W/obj/host.cgpr -cargs:Ada -gnatws -gnatyN -gargs" \
   LDFLAGS="$LLVM_LDFLAGS") >> "$LOG" 2>&1 || {
   echo "gnat-llvm build failed, see $LOG" >&2; exit 1; }

# --- The wasm32 runtime -------------------------------------------------------------
echo "building the AdaWebPack wasm32 runtime"
(cd "$W" && make -o build wasm AR="llvm-ar q") >> "$LOG" 2>&1 || {
   echo "runtime build failed, see $LOG" >&2; exit 1; }

# --- Install ------------------------------------------------------------------------
# The layout of the AdaWebPack release (bin, lib/rts-native, share/gprconfig,
# lib/gnat, share/adawebpack), plus clang and wasm-ld for the link.
T=$PREFIX.tmp
rm -rf "$T"
mkdir -p "$T/bin" "$T/lib/gnat" "$T/share/gprconfig" "$T/share/adawebpack"
cp -p "$W"/bin/llvm-* "$T/bin/"
cp -p "$W/bin/target.atp" "$T/bin/"
for f in "$T"/bin/llvm-*; do # the rpaths of the build tree (the CI: chrpath -d)
   for r in $(otool -l "$f" | awk '/cmd LC_RPATH/ {p=1} p && /path / {print $2; p=0}'); do
      install_name_tool -delete_rpath "$r" "$f" 2>/dev/null
   done
done
cp -Rp "$W/lib/rts-native" "$T/lib/"
cp -p "$AWP_SRC/packages/Fedora/llvm.xml" "$T/share/gprconfig/"
cp -p "$AWP_SRC/gnat/adawebpack_config.gpr" "$T/lib/gnat/"
cp -p "$AWP_SRC/source/adawebpack.mjs" "$T/share/adawebpack/"
cp -p "$LLVM/bin/clang-16" "$T/bin/clang"
cp -p "$LLVM/bin/lld" "$T/bin/wasm-ld"

# The AdaWebPack library (Web.*) built with the new compiler and installed
# beside the runtime, as in the release (the bench does not use it).
echo "building the AdaWebPack library"
(PATH=$T/bin:$GPRBUILD_BIN:/usr/bin:/bin
 cd "$AWP_SRC" \
 && gprconfig --batch -o "$B/llvm.cgpr" --db "$T/share/gprconfig" --target=llvm --config=ada,, \
 && gprbuild -j0 --target=llvm -p -P gnat/adawebpack.gpr --config="$B/llvm.cgpr" \
 && gprinstall --target=llvm --prefix="$T" --project-subdir="$T/lib/gnat" -p \
      -P gnat/adawebpack.gpr --config="$B/llvm.cgpr") >> "$LOG" 2>&1 || {
   echo "AdaWebPack library build failed, see $LOG" >&2; exit 1; }

echo "$STAMP" > "$T/VERSION"
rm -rf "$PREFIX"
mv "$T" "$PREFIX"
# The build tree goes; the downloads stay for a reinstall.
rm -rf "$S" "$LLVM"
echo "downloads kept in $DL ($(du -sh "$DL" | cut -f1)); delete $B to free them"
summary
