--  ETCS on-board (EVC)
--  Phase E6: the consistency of a balise group's message (SUBSET-026
--  3.16.1, 3.16.2.4): the check of a passage (EVC_Balise_Groups) and the
--  record 12 of its reaction (EVC_JRU_Messages).

package EVC_Test_Consistency is

   procedure Scenario_Message_Consistency;
   procedure Scenario_Consistency_Record;
   procedure Scenario_Duplicated_Pair;
   --  Through EVC_Core: "Trackside malfunction" for default balise
   --  information (3.16.2.4.9)
   procedure Scenario_Default_Balise;
   --  Through EVC_Core: the reactions to an inconsistent message
   --  (3.16.2.4.1, 3.16.2.4.4, 3.16.2.5.1), Linking_Shortening
   procedure Scenario_Consistency_Reactions;
   --  Through EVC_Core in a level 2 session: the balise group errors
   --  reported to the RBC, M_ERROR 0, 1, 2 and 7 (3.16.4.1)
   procedure Scenario_Consistency_Error_Report;

end EVC_Test_Consistency;
