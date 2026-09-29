# test/efs: the ERTMSFormalSpecs test frames, as scenarios

**This folder is not under the licence of the repository.** It is a
derivative work of ERTMSFormalSpecs and is distributed under the
**European Union Public Licence v1.1** (the text is in `LICENSE` next to
this file), not under the GPL-3.0 of the rest of the repository.

## Provenance

ERTMSFormalSpecs (EFS) is an executable model of SUBSET-026 3.4.0 /
3.6.0 by ERTMS Solutions, published under the EUPL v1.1.

- Origin: <https://github.com/ERTMSSolutions/ERTMSFormalSpecs> (no longer
  on GitHub).
- Archived by Software Heritage: snapshot
  `13f7925512be6876547415215bdc5cd226570e58`, head revision
  `7eec807f90ad2ee44f0d7b5e3ab5a632ced6e470` of 2018-03-11.
- The files here were generated from a checkout of that revision next to
  the repository (`../ERTMSFormalSpecs`, on the machine of the author
  `/Users/milan/GitHub/ERTMSFormalSpecs`), from its functional test
  frames `ErtmsFormalSpecs/doc/specs/subset-026_test/TestFrames/*.efs_tst`,
  with the requirement ids of `.../subset-026/Specifications/**/*.efs_ch`
  and the enumerations of `.../messages_340/Messages.efs_ns`.

## What is here

- `*.scn`: one scenario per test frame (49 frames): every action and
  expectation of the frame, either translated into a primitive of ours
  or kept verbatim (`efs:`), and the requirements of every test case
  with the status of their clause in `doc/TRACE-SUBSET-026.csv`. The
  format is described in the header of `test/tools/efs_frames.py`.
- `INDEX.md`: per frame, the number of cases, steps, translated and
  verbatim actions and expectations, known differences, clause statuses.
- `README.md` (this file) and `LICENSE` (the EUPL v1.1).

The `.scn` files and `INDEX.md` are generated, never edited by hand
(`README.md` and `LICENSE` are kept as they are):

    python3 test/tools/efs_frames.py [--efs ../ERTMSFormalSpecs]
    python3 test/tools/efs_frames.py --check   # in test/check.sh

The tools that make and read them are ours, under the GPL-3.0 of the
repository, and depend on nothing here: `test/tools/efs_frames.py` (the
converter; its table of known differences is ours) and
`test/src/evc_efs_test.adb` (the runner, `obj/evc_efs_test`), which
executes the expectations of the supervision family (braking models,
conversion model, correction factors, build up times, target terms)
against the SPARK units of `evc/`.

## Removing the folder

Deleting `test/efs/` (and nothing else) leaves the build, `test/check.sh`
and every product of the repository untouched: nothing under `dmi/`,
`evc/`, `common/`, `sim/` or `ports/` reads it; `obj/evc_efs_test` prints
`evc_efs_test: test/efs absent, skipped` and succeeds; `efs_frames.py
--check` says it skipped. Regenerating it needs the EFS checkout.
