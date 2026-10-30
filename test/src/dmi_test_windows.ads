--  ETCS DMI
--  Windows of the start-up dialogue and the general window/button
--  mechanics (chapter 10, 11.7.2).
--  Golden-frame scenarios extracted from dmi_test.adb;
--  called from DMI_Test in the original order.

package DMI_Test_Windows is

   procedure Scenario_Startup_Sequence;

   procedure Scenario_Other_Windows;

   procedure Scenario_Data_View;
   procedure Scenario_Data_View_RBC_Contact;

   procedure Scenario_Button_Down_Type;

   procedure Scenario_Button_Up_Type;

   procedure Scenario_Enabling_Conditions;

   procedure Scenario_Override_Selectable;

   procedure Scenario_Waiting_Window;

   procedure Scenario_Network_Type_Wait;

end DMI_Test_Windows;
