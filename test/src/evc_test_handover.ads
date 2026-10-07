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

   --  S776cef6c, 4.8.2.1 c), 4.8.5.2, 3.12.3: a text message of the
   --  Accepting RBC before the switch, shown after it
   procedure Scenario_Handover_Text;

   --  3.15.1.3.8 b), 4.10 (the row of the RBC transition order),
   --  3.5.3.4 f): the retained contact of the Handing Over RBC used to set
   --  its lost session up again, then deleted by a mode of 4.10
   procedure Scenario_Handover_Deletion;

end EVC_Test_Handover;
