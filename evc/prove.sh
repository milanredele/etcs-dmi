#!/bin/sh
# ETCS on-board (EVC): flow analysis and proof of the SPARK units of evc/
# with gnatprove (doc/EVC-PLAN.md §2). Fails unless every check is
# proved.
#
# gnatprove is not a dependency of the crate: install it outside the
# repository (never run alr inside it), e.g.
#     mkdir -p ~/dev/tools && cd ~/dev/tools && alr get gnatprove=15.1.0
# and put its bin/ directory on PATH, or point GNATPROVE at the binary.
# The GNAT compiler must be on PATH as for the build.
#
# Usage: evc/prove.sh [extra gnatprove switches]
# e.g. evc/prove.sh --report=all to list every proved check,
#      evc/prove.sh -u evc_fixed.adb for one unit during development,
#      evc/prove.sh --replay to replay the recorded proofs without
#      attempting new ones (a verification of a merge).
# The full report is obj/evc/gnatprove/gnatprove.out.
#
# Proof results are shared across worktrees and branches through
# gnatprove's file cache (package Prove in etcs_evc.gpr): the directory
# ETCS_PROOF_CACHE, by default ~/.local/share/etcs-dmi/proof-cache. A
# fresh worktree therefore re-proves only what changed.

set -eu

here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"

cache=${ETCS_PROOF_CACHE:-$HOME/.local/share/etcs-dmi/proof-cache}
mkdir -p "$cache"

gnatprove=${GNATPROVE:-gnatprove}
if ! command -v "$gnatprove" >/dev/null 2>&1; then
   echo "prove.sh: gnatprove not found (set PATH or GNATPROVE)" >&2
   exit 2
fi

# The switches of package Prove in etcs_evc.gpr apply: --mode=all
# (flow analysis and proof), --level=2, --checks-as-errors=on (an
# unproved check fails the run).
status=0
"$gnatprove" -P etcs_evc.gpr -j0 --report=fail "$@" || status=$?

summary=obj/evc/gnatprove/gnatprove.out
if [ -f "$summary" ]; then
   sed -n '/^Summary of SPARK analysis/,/^Total/p' "$summary"
fi
exit $status
