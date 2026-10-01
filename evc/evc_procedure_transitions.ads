--  ETCS on-board (EVC)
--  INTERIM, branch e4/procedures: the transitions of 4.6.2 with the
--  conditions of 4.6.3 that the procedures half owns, so that the mode
--  machine of EVC_Core takes them before the two halves of phase E4
--  merge (doc/EVC-PLAN.md §10). The modes half (e4/modes) gives the mode
--  machine the whole table of 4.6.2 with every condition; at the merge
--  that table replaces this package, which is deleted, and the arms of
--  EVC_Transition_Conditions stay as they are.
--
--  Holds (From, To): one of the conditions of this half that 4.6.2 lists
--  for the transition From -> To holds (EVC_Transition_Conditions.Holds),
--  copied from the list under Figure 2 in
--  doc/SRS/SUBSET-026_v400/sections/04_modes_and_transitions.md.

with EVC_Modes; use EVC_Modes;
with EVC_Procedures;

package EVC_Procedure_Transitions
  with SPARK_Mode => On
is

   function Holds (From, To : Mode_T) return Boolean
     with Global => EVC_Procedures.State,
          Post => (if From = M_NP or else To in M_NP | M_IS
                   then not Holds'Result);

end EVC_Procedure_Transitions;
