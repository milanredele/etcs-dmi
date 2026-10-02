--  ETCS on-board (EVC)
--  phase E4, modes and levels (e4/modes): the mode machine of 4.6,
--  the start of mission of 5.4, the level transitions of 5.10,
--  the acceptance of 4.8, the data of 4.10 and A.3.4.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Modes is

      procedure Scenario_E4_Tables;
      procedure Scenario_E4_SoM_Level_1;
      procedure Scenario_E4_SoM_Other_Levels;
      procedure Scenario_E4_SR_Distance;
      procedure Scenario_E4_Level_Transition_0;
      procedure Scenario_E4_Level_Ack_Again;
      procedure Scenario_E4_Level_Orders;
      procedure Scenario_E4_Acceptance;
      procedure Scenario_E4_SL_NL_IS;
      procedure Scenario_E4_Odometer_Failure;
      procedure Scenario_E4_Desk_Closed;
      procedure Scenario_E4_Continue_Shunting;

end EVC_Test_Modes;
