--  ETCS DMI
--  Settings and special windows: the Main/Special Settings menus,
--  Radio data and its dialogue sequences, the Simulator window,
--  and the stored hardware settings (luminance, volume,
--  isolation).
--  Golden-frame scenarios extracted from dmi_test.adb;
--  called from DMI_Test in the original order.

package DMI_Test_Settings is

   procedure Scenario_Win_Main_Menu;

   procedure Scenario_Win_Special_Settings;

   procedure Scenario_Win_Radio_Data;

   procedure Scenario_Win_Start_Up_Radio;

   procedure Scenario_Win_Simulator;

   procedure Scenario_HW_Settings_Stored;

   procedure Scenario_HW_Desk_Settings;

   procedure Scenario_HW_Isolation;

   procedure Scenario_HW_Simulator_Isolation;

end DMI_Test_Settings;
