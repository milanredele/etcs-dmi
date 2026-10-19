--  ETCS on-board (EVC)
--  Phase E6: the consistency of a balise group's message (SUBSET-026
--  3.16.1, 3.16.2.4): the check of a passage (EVC_Balise_Groups) and the
--  record 12 of its reaction (EVC_JRU_Messages).

package EVC_Test_Consistency is

   procedure Scenario_Message_Consistency;
   procedure Scenario_Consistency_Record;

end EVC_Test_Consistency;
