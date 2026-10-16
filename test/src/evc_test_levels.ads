--  ETCS on-board (EVC)
--  Phase E5 (e5/levels): the level transitions to and from level 2
--  (5.10.3, 4.8.5.5, 4.8.3 [3]): the transition buffer released in the
--  cycle of the transition, the sessions of the driver's change of level
--  and of the exit from level 2 (EVC_Level_Sessions).
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Levels is

   procedure Scenario_L2_Buffer_Same_Cycle;
   --  4.8.1.3.1: the level 1 MA of the group of an immediate order to
   --  level 2
   procedure Scenario_L2_Order_With_L1_MA;
   procedure Scenario_L1_Order_With_L1_MA_In_L0;
   --  e5/balise-buffer: 4.8.3 [1], 4.8.5 for balise groups
   procedure Scenario_L1_Balise_Buffer;
   procedure Scenario_L1_Balise_Buffer_Deleted;
   procedure Scenario_L1_Balise_Buffer_From_L0;
   procedure Scenario_L1_Balise_Buffer_Units;
   procedure Scenario_L1_Order_Own_Group_Linking;
   procedure Scenario_L2_Driver_Change;
   procedure Scenario_L2_Exit_By_Order;
   procedure Scenario_L2_Exit_Aborts_Establishment;
   procedure Scenario_L2_Switch_Contact;
   procedure Scenario_L2_Order_Linked_Group;
   --  e5/level2-radio-data: 5.10.3.15.2 b) and its note
   procedure Scenario_L2_Radio_Data_No_Contact;
   procedure Scenario_L2_Radio_Data_No_Registration;
   procedure Scenario_L2_Radio_Data_Into_TR;
   procedure Scenario_SR_Order_Single_Group;

end EVC_Test_Levels;
