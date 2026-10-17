--  ETCS on-board (EVC)
--  The juridical recording in the message format of SUBSET-027 4.2
--  (EVC_JRU_Messages, EVC_Outbox.Put_JRU / Flush_JRU): the header and
--  every message of an event of the on-board, encoded and read back;
--  the header the on-board captures with the UTC time.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_JRU is

   procedure Scenario_JRU_Format;
   procedure Scenario_JRU_On_Board;
   procedure Scenario_JRU_To_RBC;
   procedure Scenario_JRU_Track_Conditions;

end EVC_Test_JRU;
