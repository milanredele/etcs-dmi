--  ETCS on-board (EVC)
--  phase E1: the ERTMS/ETCS language (evc/language) -- packets,
--  telegrams and messages built, parsed, damaged, and received by
--  the core on the BTM and RTM ports.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Language is

      procedure Scenario_Packet_Round_Trips;
      procedure Scenario_Telegram;
      procedure Scenario_Telegram_Damaged;
      procedure Scenario_Message;
      procedure Scenario_Telegram_Length;
      procedure Scenario_Spare_Values;
      procedure Scenario_Senders;
      procedure Scenario_Received;

end EVC_Test_Language;
