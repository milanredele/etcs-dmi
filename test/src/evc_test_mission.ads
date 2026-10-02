--  ETCS on-board (EVC)
--  the mission of the mock (dmi_test Scenario_Mission) with the
--  on-board's speed and distance monitoring, and A.3.12's reduced
--  build up times against the reference model.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Mission is

      procedure Scenario_SDM_Mission;
      procedure Scenario_SDM_Build_Up;

end EVC_Test_Mission;
