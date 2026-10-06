--  ETCS on-board (EVC)
--  Phase E5 (e5/handover): the RBC/RBC handover of SUBSET-026 3.15.1.3
--  and 5.15.1.4 (EVC_Sessions.Handover), driven through the ports (the
--  RTM messages of two RBCs, balise groups with packet 131).
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Handover is

   --  An order by radio: the second session, Train Data, reports to
   --  both, the transition buffer, the border, the switch, the
   --  termination by the Handing Over RBC; an order replaced
   procedure Scenario_Handover_Radio;

   --  An order by balise group with packet 42 for the Accepting RBC
   --  (4.8.3 [14]), at once (3.15.1.3.7); one session only (3.15.1.3.2);
   --  3.15.1.3.9
   procedure Scenario_Handover_Balise;

end EVC_Test_Handover;
