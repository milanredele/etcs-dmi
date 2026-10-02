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
#
# One proof at a time on the machine: a run takes every core, and two at
# once only slow each other down. A second prove.sh waits for the first
# (the lock is a directory in the cache; ETCS_PROVE_NOLOCK=1 skips it).
#
# The margin: the limit of a prover attempt is 100000 steps with 60 s as
# a backstop (package Prove). A check that is proved with more than
# ETCS_PROOF_MAX_STEPS (default 60000) steps or ETCS_PROOF_MAX_SECONDS
# (default 20) seconds fails the run although it is proved: it is too
# close to the limit to stay proved when the code around it changes, and
# is to be made easier (an assertion, a lemma, a smaller subprogram).

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

lock=$cache/.prove.lock
if [ -z "${ETCS_PROVE_NOLOCK:-}" ]; then
   said=
   while ! mkdir "$lock" 2>/dev/null; do
      holder=$(cat "$lock/pid" 2>/dev/null || true)
      if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then
         rm -rf "$lock"   # the holder is gone
         continue
      fi
      if [ -z "$said" ]; then
         echo "prove.sh: waiting for the proof of process ${holder:-?}" >&2
         said=1
      fi
      sleep 5
   done
   echo $$ > "$lock/pid"
   trap 'rm -rf "$lock"' EXIT
   trap 'exit 130' INT TERM
fi

# The switches of package Prove in etcs_evc.gpr apply: --mode=all
# (flow analysis and proof), CVC5 and Z3 with a limit in steps,
# --checks-as-errors=on (an unproved check fails the run).
# --report=statistics gives the steps and the time of every proved
# check for the margin; only what is not proved is shown here, the rest
# is in the log.
mkdir -p obj/evc
log=obj/evc/prove.log
status=0
"$gnatprove" -P etcs_evc.gpr -j0 --report=statistics "$@" > "$log" 2>&1 \
   || status=$?
grep -v ': info: ' "$log" || true

summary=obj/evc/gnatprove/gnatprove.out
if [ -f "$summary" ]; then
   sed -n '/^Summary of SPARK analysis/,/^Total/p' "$summary"
fi

max_steps=${ETCS_PROOF_MAX_STEPS:-60000}
max_seconds=${ETCS_PROOF_MAX_SECONDS:-20}
awk -v max_steps="$max_steps" -v max_seconds="$max_seconds" '
   / info: .* proved \(/ {
      where = $1
      line = $0
      top_s = 0; top_t = 0
      while (match(line, /in max [0-9.]+ seconds and [0-9]+ step/)) {
         part = substr(line, RSTART, RLENGTH)
         split(part, w, " ")
         if (w[3] + 0 > top_t) top_t = w[3] + 0
         if (w[6] + 0 > top_s) top_s = w[6] + 0
         line = substr(line, RSTART + RLENGTH)
      }
      n++
      if (top_s > best_s) { best_s = top_s; best_s_at = where }
      if (top_t > best_t) { best_t = top_t; best_t_at = where }
      if (top_s > max_steps || top_t > max_seconds) {
         printf "prove.sh: too close to the limit: %s %d steps, %.1f s\n",
                where, top_s, top_t
         bad++
      }
   }
   END {
      if (n == 0) {
         print "prove.sh: proof margin: no statistics in this run"
      } else {
         printf "prove.sh: proof margin: at most %d of 100000 steps (%s), %.1f of 60 s (%s)\n",
                best_s, best_s_at, best_t, best_t_at
      }
      exit (bad > 0) ? 1 : 0
   }' "$log" || { [ "$status" -ne 0 ] || status=1; }
exit $status
