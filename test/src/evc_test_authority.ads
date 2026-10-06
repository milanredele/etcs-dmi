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

with EVC_Bytes;
with EVC_Test_Support;

package EVC_Test_Authority is

   procedure Scenario_Radio_MA;
   procedure Scenario_Radio_MA_Shifted;
   procedure Scenario_MA_Request;
   procedure Scenario_Shortening;
   procedure Scenario_Emergency_Stops;
   procedure Scenario_SR_Authorisation;
   procedure Scenario_Trip_L2;
   procedure Scenario_Shunting_L2;
   procedure Scenario_Radio_Acceptance;
   procedure Scenario_Transition_Buffer;
   procedure Scenario_Start_After_Ack;
   procedure Scenario_Track_Ahead_Free;

   --  For EVC_Test_Levels (e5/levels): the session 1 with the RBC 123/1
   --  established through the writers of EVC_Radio, the Train Data
   --  acknowledged; message 3 referring to the group NID_BG of country
   --  123 with the MA of Lengths (MA_Of), an SSP and a gradient
   procedure Establish_Session;
   function Radio_MA (NID_BG  : Natural;
                      Lengths : EVC_Test_Support.Nat_List)
     return EVC_Bytes.Byte_Array;

end EVC_Test_Authority;
