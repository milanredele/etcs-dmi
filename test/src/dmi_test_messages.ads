--  ETCS DMI
--  Acknowledgements and text messages (areas C and E): the
--  request FIFO (5.4.1) and the text message store/wrap.
--  Golden-frame scenarios extracted from dmi_test.adb;
--  called from DMI_Test in the original order.

package DMI_Test_Messages is

   procedure Scenario_Text_Unknown_Glyphs;

   procedure Scenario_Text_Messages;

   procedure Scenario_Ack_Same_Class;

   procedure Scenario_Ack_Arrival_Order;

   procedure Scenario_Ack_Revoked;

   procedure Scenario_Ack_Remove_One;

   procedure Scenario_Ack_Queue_Full;

   procedure Scenario_Text_Store;

   procedure Scenario_Ack_And_Windows;

   procedure Scenario_Text_Wrap;

end DMI_Test_Messages;
