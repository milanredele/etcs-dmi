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
   procedure Scenario_RBC_Contact_To_DMI;
   procedure Scenario_Network_List;

   --  5.4.3.2 S4: the registration awaited for the time of A.3.1 (E6 /
   --  E7), A42 "registration failed" and the end of the wait, A43 the
   --  driver's network restarts it
   procedure Scenario_Network_S4_Timeout;

   --  3.5.6.1.3, 3.5.6.7 a) b), 5.4.3.2 S4 E61 / E62 / E71 / E72 -> A42:
   --  the FRMCS on-board's report on the RTM port (events 7, 8), the
   --  wait of S4 and its time from the FRMCS detection, "FRMCS network
   --  registration failed"
   procedure Scenario_Network_FRMCS;

   --  5.4.3.2 D7 -> S4 without a known RBC contact (the position and
   --  level 2 valid at D2): the wait of S4 ends at the time of A.3.1 by
   --  E72, E71 and E7 as when the session is being opened, A42 entry 33
   --  or 34
   procedure Scenario_Network_S4_Without_Contact;

   --  A.3.4.1.2 k): the desk closed and opened again during the start of
   --  mission after the driver elected the mission with only one radio
   --  system (5.4.3.2 S5): the choice is deleted (A.3.4 column k), the
   --  start of mission reaches S4 again and its wait ends by E72 at once,
   --  the time since the latest GSM-R order elapsed: entry 33 again, S5
   --  offered again with no value
   procedure Scenario_Network_One_Radio_Desk_Closed;

   --  5.4.3.2 S3 E4 -> A41 -> D8: the driver's Radio Network type naming
   --  FRMCS while the FRMCS on-board is not registered; the wait until
   --  the time of A.3.1 from its detection, entry 33, the wait ended
   procedure Scenario_Network_Type_At_S3;

   --  e5/registration-3: packet 45 by radio (message 24) filtered by
   --  4.8.3 / 4.8.4 (EVC_Radio_Acceptance), 4.8.4 [1], [2], [13]
   procedure Scenario_Network_Radio_Order;

   --  5.4.5.3 j) 2nd bullet: in level 1 at S10 and S20 the Radio data
   --  re-entered: the Radio Network taken, the RBC contact not
   procedure Scenario_Network_Level_1;

end EVC_Test_Network;
