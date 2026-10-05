--  ETCS on-board (EVC)
--  Phase E5, the session and link half (EVC_Sessions): the communication
--  sessions of SUBSET-026 3.5 and the link supervision of 3.16.3, driven
--  through the ports (a balise group with packet 42, the RTM events and
--  messages).
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Sessions is

   --  3.5.3 establishment by a balise group order, 3.16.3.3 and
   --  3.16.3.5, 3.5.5 termination by order, 3.5.5.6
   procedure Scenario_Session_Establish;

   --  3.5.3.7 d) no compatible version, 3.5.4 the connection lost and
   --  the session kept, then terminated after 5 minutes; 3.5.3.5.2 with
   --  one session
   procedure Scenario_Session_Lost_Version;

   --  3.16.3.4: T_NVCONTACT, its reaction train trip ([41]) and the
   --  release and set-up 60 s later
   procedure Scenario_Session_NVCONTACT;

end EVC_Test_Sessions;
