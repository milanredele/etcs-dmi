--  ETCS DMI
--  ATO additions (DMI 8.5, 11.3.14; audit ATO-1, PLN-5).
--  Golden-frame scenarios extracted from dmi_test.adb;
--  called from DMI_Test in the original order.

package DMI_Test_ATO is

   procedure Scenario_ATO_Displays;

   procedure Scenario_ATO_Malformed;

   procedure Scenario_ATO_Buttons;

   procedure Scenario_ATO_Warning_Sound;

   procedure Scenario_ATO_Stopping_Points;

   procedure Scenario_ATO_Selector_Window;

   procedure Scenario_ATO_Mission;

end DMI_Test_ATO;
