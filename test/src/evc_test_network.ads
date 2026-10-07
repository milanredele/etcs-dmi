--  ETCS on-board (EVC)
--  Phase E5 (e5/registration-2): the radio network registration of
--  EVC_Sessions.Network beyond its first round, driven through the
--  ports: the list of GSM-R networks (3.18.4.3.6.2), the registration
--  awaited at 5.4.3.2 S4 and its time (A.3.1), the Radio data window
--  outside the start of mission (5.10.3.15.2 b), the acceptance of the
--  Radio Network transition order (4.8.3, 4.8.4).
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Network is

   --  3.18.4.3.6.2: MSG_RADIO_NETWORKS when the driver elects to modify
   --  the GSM-R network, the default and the stored network
   procedure Scenario_Network_List;

   --  5.4.3.2 S4: the registration awaited for the time of A.3.1 (E6 /
   --  E7), A42 "registration failed" and the end of the wait, A43 the
   --  driver's network restarts it
   procedure Scenario_Network_S4_Timeout;

end EVC_Test_Network;
