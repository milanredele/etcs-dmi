--  ETCS on-board (EVC)
--  E3 after the integration: the speed restriction to ensure a
--  permitted braking distance (3.11.11, packet 52, EVC_PBD) and
--  the gaps of the gradient and SSP profiles (3.11.12.2, 3.13.7.2).
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_PBD is

      procedure Scenario_PBD_Precision;
      procedure Scenario_PBD;
      procedure Scenario_Gradient_Gaps;
      procedure Scenario_SSP_Gaps;

end EVC_Test_PBD;
