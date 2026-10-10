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

   --  3.15.1.3.4.1: End of Mission while connected to both RBCs
   procedure Scenario_Handover_EoM;

   --  3.5.7.5, 3.5.7.6: the indication of the safe radio connection while
   --  the Accepting RBC is not set up: lost, released (Table 1)
   procedure Scenario_Handover_Indication;

   --  3.5.3.4.1, 3.5.3.4.2 b), 3.15.1.3.7: an order naming the RBC in
   --  session: no second session; set up again after its termination
   procedure Scenario_Handover_Same_RBC;

   --  3.5.3.7.4.1 with 3.15.1.3.1 a): the Accepting RBC's session set up
   --  again without its 38, the supervising one kept (3150100_01)
   procedure Scenario_Handover_Ack_Missing;

   --  3.15.1.3.1 c), 3.15.1.3.9: the min safe rear end past the border
   --  reported, the report repeated, then the session terminated
   procedure Scenario_Handover_Rear_Repeat;

end EVC_Test_Handover;
