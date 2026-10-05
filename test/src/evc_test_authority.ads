--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half (e5/authority,
--  EVC_Radio_Authority): the MA by radio (messages 3 and 33), the MA
--  request (message 132), the co-operative shortening (9, 137, 138) and
--  the emergency messages (15, 16, 18, 147). The session half is not in
--  these scenarios: a session is put into the state they need through
--  the writers of EVC_Radio (Establish), the on-board is then driven
--  through its ports only. Level 2 is set by the test entry of the core
--  (EVC_Core.Set_Mode_For_Test), the level table having level 2 "not
--  available" until the session half makes it selectable.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Authority is

   procedure Scenario_Radio_MA;
   procedure Scenario_Radio_MA_Shifted;
   procedure Scenario_MA_Request;
   procedure Scenario_Shortening;

end EVC_Test_Authority;
