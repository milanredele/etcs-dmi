--  ETCS DMI
--  Speed dial and supervision (areas A and B; chapters 7, 8.2.1),
--  status objects and track conditions, and pixel-probe checks
--  of the dial and the TTI square (px_/pt_).
--  Golden-frame scenarios extracted from dmi_test.adb;
--  called from DMI_Test in the original order.

package DMI_Test_Supervision is

   procedure Scenario_FS_CSM;

   procedure Scenario_FS_TSM;

   procedure Scenario_AD_White;

   procedure Scenario_CSM_Target_Info;

   procedure Scenario_Supervision_Sounds;

   procedure Scenario_Mode_Ack;

   procedure Scenario_Level_Announcement;

   procedure Scenario_Windows;

   procedure Scenario_Speed_Toggle;

   procedure Scenario_Status_Objects;

   procedure Scenario_TTI;

   procedure Scenario_BMM_Inhibition;

   procedure Scenario_SM_Direction;

   procedure Scenario_TC_Areas_Kept;

   procedure Scenario_Level_NTC_In_C8;

   procedure Scenario_Level_Ann_Acknowledged;

   procedure Scenario_Flash_Starts_Visible;

   procedure Scenario_PT_TTI_Steps;

   procedure Scenario_Px_Speed_Dial;

end DMI_Test_Supervision;
