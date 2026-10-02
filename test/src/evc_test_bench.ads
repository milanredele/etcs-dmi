--  ETCS on-board (EVC)
--  the bench and end-to-end scenarios: the on-board in the
--  environment of sim/ (Sim_Onboard_Env) against the golden
--  bench_onboard, and the wrap of the odometer counters.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Bench is

      procedure Scenario_Bench_Onboard;
      procedure Scenario_Odometer_Wrap;

end EVC_Test_Bench;
