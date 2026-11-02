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

   --  e4/ls-display-2 (B092), 4.8.2.1 c) exception 2: the LSSMA display
   --  toggle order of the Accepting RBC rejected, also when released
   procedure Scenario_Handover_LSSMA;

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

   --  B121, 4.8.2.1 c) exception 2: the request to shorten the MA, the
   --  revocation of an emergency stop of the Accepting RBC are rejected,
   --  not taken at the switch
   procedure Scenario_Handover_Exception_2;
   --  3.16.3.4.1.2
   procedure Scenario_Handover_Contact;
   --  3.5.3.8 f)
   procedure Scenario_Handover_Rear_Border;
   --  3.6.5.1.4 e), 3.15.1.3.1 c), 3.15.1.3.4: the report in the cycle
   --  the min safe rear end passes the border, to both RBCs
   procedure Scenario_Handover_Rear_Report;
   --  A.3.5.1 6th bullet: the border passed by the front, then by the
   --  rear, each followed by a roll back in rear of it and forward again
   procedure Scenario_Handover_Roll_Back;

   --  3.15.1.3.3, 3.18.3.4: the Train Data to the Accepting RBC sent
   --  once its session is established, not repeated to the Handing
   --  Over RBC that acknowledged its own, also after the Accepting
   --  session's end
   procedure Scenario_Handover_Train_Data_Once;

   --  3.15.1.3.1 c), 3.15.1.3.2.2, 3.15.1.3.4: after the switch a group
   --  past the border orders the transition at once to the RBC already
   --  supervising: the border kept, the min safe rear end's report to
   --  the Handing Over RBC, the reports to both until then
   procedure Scenario_Handover_Order_Again;

   --  3.6.3.1.4, 3.12.3.4.3.1.3, 3.15.1.3.6: the Accepting RBC's fixed
   --  texts referred to an LRBG "unknown" without a location
   --  sub-condition, stored until the switch: the one valid for both
   --  directions shown at the switch, the one valid for the nominal
   --  direction rejected
   procedure Scenario_Handover_Text_No_LRBG;

   --  3.18.3.4, A.3.1: the Train Data (message 129) not acknowledged:
   --  sent once and repeated three times 15 s apart, then no more
   procedure Scenario_Train_Data_Repeats;

   --  3.6.5.1.4 h), 3.15.1.3.3, 3.15.1.3.4: the session with the
   --  Accepting RBC established, its Train Data then a position report
   --  to both RBCs
   procedure Scenario_Handover_Session_Report;

   --  3.6.5.1.4 l), 3.16.4.1, 3.15.1.3.4: connected to both RBCs, a
   --  balise group error reported to both
   procedure Scenario_Handover_Error_Report;

end EVC_Test_Handover;
