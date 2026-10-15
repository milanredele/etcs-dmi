--  ETCS on-board (EVC)
--  Phase E5, the radio (e5/joint, then e5/session and e5/authority): the
--  RTM port in both directions, EVC_Radio, the entry points of the two
--  halves (EVC_Sessions, EVC_Radio_Authority), the single-session
--  configuration.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Radio is

   procedure Scenario_Radio_Joint;

   --  8.4.4.2.1, 3.16.3.1.1 c): a message whose L_MESSAGE disagrees with
   --  its length reaches the on-board, recorded and reported inconsistent
   procedure Scenario_Radio_Length_Check;

   --  3.17.3.11 b), 3.16.1.1.1: an unknown NID_MESSAGE is recorded and
   --  ignored, a spare value of a known message reported inconsistent
   procedure Scenario_Radio_Unknown_Message;

end EVC_Test_Radio;
