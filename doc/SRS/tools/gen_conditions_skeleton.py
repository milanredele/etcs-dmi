#!/usr/bin/env python3
"""Write the skeleton of evc/evc_transition_conditions.ads from the
transition conditions table of SUBSET-026 4.6.3.

    python3 doc/SRS/tools/gen_conditions_skeleton.py > evc/evc_transition_conditions.ads

One-off aid for phase E4 (doc/EVC-PLAN.md §10): the table rows
`|[n]|text|` of sections/04_modes_and_transitions.md become the comments
of the condition identifiers, so that every condition is quoted where it
is implemented and none is forgotten. The generated file is then edited
by hand (it is not regenerated).
"""
import re
import sys
import textwrap
from pathlib import Path

MD = (Path(__file__).resolve().parents[1]
      / "SUBSET-026_v400/sections/04_modes_and_transitions.md")

conds = {}
cur = None
for line in MD.read_text(encoding="utf-8").split("\n"):
    m = re.match(r"^\|\[(\d+)\]\|(.*)\|\s*$", line)
    if m:
        cur = int(m[1])
        conds[cur] = m[2]
    elif cur is not None and line.startswith("|") and not line.startswith("|---") \
            and "**Condition**" not in line and re.match(r"^\|[^\[]", line):
        # a continuation row without an id: part of the previous text
        conds[cur] += " " + line.strip("|").strip()
    elif line.startswith("## ") and cur is not None and cur >= 84:
        break


def clean(t):
    t = re.sub(r"<br>", " ", t)
    t = re.sub(r"\*\*\{(\d+)\}\*\*", r"{\1}", t)
    t = re.sub(r"\*\*", "", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


# Identifiers the 4.0.0 table does not have: [56] is followed by [58] and
# [63] by [65] on the PDF pages 51 and 52; [55] does not appear either.
ABSENT = {55, 57, 64}

out = open(sys.argv[1], "w", encoding="utf-8") if len(sys.argv) > 1 else sys.stdout
out.write("""--  ETCS on-board (EVC)
--  The conditions of the mode transitions, SUBSET-026 4.6.3, as one
--  identifier each. EVC_Modes.Transitions says which condition allows
--  which transition with which priority; this package says whether a
--  condition holds in the current cycle. Each condition is evaluated by
--  the unit that owns the state it speaks about (the position, the
--  stored information, the supervision, the driver's requests, the
--  train interface); Holds dispatches to it. A condition that is not
--  implemented yet returns False and says so in its arm.
--
--  The texts are quoted from the table of 4.6.3 (SUBSET-026-4 v4.0.0,
--  pages 49 to 51); {n} refers to the notes below the table.

package EVC_Transition_Conditions
  with SPARK_Mode => On
is

   subtype Condition_Id_T is Positive range 1 .. 84;

""")
for n in range(1, 85):
    if n in ABSENT:
        text = ("not in the table of 4.0.0 (the identifier is skipped on the "
                "PDF page); never used by EVC_Modes.Transitions")
    else:
        text = clean(conds.get(n, "(not found in the markdown: read the PDF)"))
    out.write(f"   --  [{n}]\n")
    for l in textwrap.wrap(text, 66):
        out.write(f"   --    {l}\n")
    out.write(f"   C_{n} : constant Condition_Id_T := {n};\n\n")
out.write("""   --  True when the condition holds in the current cycle
   function Holds (C : Condition_Id_T) return Boolean
     with Global => null;  -- to be replaced by the real Global set

end EVC_Transition_Conditions;
""")
if len(sys.argv) > 1:
    out.close()
    body = Path(sys.argv[1]).with_suffix(".adb")
    with body.open("w", encoding="utf-8") as b:
        b.write("""--  ETCS on-board (EVC)
--  Skeleton of phase E4: every condition answers False until the unit
--  that owns it implements it (doc/EVC-PLAN.md §10). An arm names its
--  owner when it is implemented.

package body EVC_Transition_Conditions
  with SPARK_Mode => On
is

   function Holds (C : Condition_Id_T) return Boolean is
   begin
      case C is
""")
        for n in range(1, 85):
            why = "absent from 4.0.0" if n in ABSENT else "not implemented yet"
            b.write(f"         when C_{n} =>\n            return False;  --  {why}\n")
        b.write("""      end case;
   end Holds;

end EVC_Transition_Conditions;
""")
sys.stderr.write(f"{len(conds)} conditions found, {len(ABSENT)} absent\n")
