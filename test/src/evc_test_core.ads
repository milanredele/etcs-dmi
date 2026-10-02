--  ETCS on-board (EVC)
--  the core of EVC_Core itself: protocol constants, power-up,
--  malformed input, valid inputs, isolation, time, the outbox,
--  Enter_Failure, and the whole DMI_Core/EVC_Core chain.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Core is

      procedure Scenario_Protocol_Constants;
      procedure Scenario_Power_Up;
      procedure Scenario_Malformed;
      procedure Scenario_Valid_Inputs;
      procedure Scenario_Isolation;
      procedure Scenario_Time;
      procedure Scenario_Outbox;
      procedure Scenario_Failure;
      procedure Scenario_End_To_End;

end EVC_Test_Core;
