--  ETCS on-board (EVC)
--  Phase E5, the radio (e5/joint, then e5/session and e5/authority): the
--  RTM port in both directions, EVC_Radio, the entry points of the two
--  halves (EVC_Sessions, EVC_Radio_Authority), the single-session
--  configuration.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Radio is

   procedure Scenario_Radio_Joint;

end EVC_Test_Radio;
