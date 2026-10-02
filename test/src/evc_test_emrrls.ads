--  ETCS on-board (EVC)
--  Q_NVEMRRLS (7.5.1.123, 3.13.2.3.7.2): the emergency brake command
--  of the speed and distance monitoring, run on the mission's
--  line with both values of the national parameter.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_EMRRLS is

      procedure Scenario_EMRRLS_Ceiling;
      procedure Scenario_EMRRLS_Target;
      procedure Scenario_EMRRLS_EOA_Target;
      procedure Scenario_EMRRLS_Release;
      procedure Scenario_EMRRLS_Acknowledgement;

end EVC_Test_EMRRLS;
