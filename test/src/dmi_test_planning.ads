--  ETCS DMI
--  Planning area (D): the profile, zoom, PASP, orders, and the
--  pixel-probe checks of its frame geometry (pf_).
--  Golden-frame scenarios extracted from dmi_test.adb;
--  called from DMI_Test in the original order.

package DMI_Test_Planning is

   procedure Scenario_Planning;

   procedure Scenario_Planning_Zoom_Areas;

   procedure Scenario_Planning_Zero_Gradient;

   procedure Scenario_Planning_PASP;

   procedure Scenario_Planning_Order_Limit;

   procedure Scenario_PF_Distance_Bar;

   procedure Scenario_PF_TAF;

   procedure Scenario_PF_Scroll_Disabled;

   procedure Scenario_PF_G_Empty;

end DMI_Test_Planning;
