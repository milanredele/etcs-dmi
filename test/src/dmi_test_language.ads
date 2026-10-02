--  ETCS DMI
--  The language window and every text in the selected language
--  (audit GEN-2; DMI 5.5), English/German/Hungarian.
--  Golden-frame scenarios extracted from dmi_test.adb;
--  called from DMI_Test in the original order.

package DMI_Test_Language is

   procedure Scenario_Lang_Texts_Fit;

   procedure Scenario_Lang_Window;

   procedure Scenario_Lang_German_Windows;

   procedure Scenario_Lang_Messages;

   procedure Scenario_Lang_Reset;

   procedure Scenario_Lang_Settings_Sequence;

   procedure Scenario_Lang_Simulator;

   procedure Scenario_Hu_Language_Window;

   procedure Scenario_Hu_Windows;

   procedure Scenario_Hu_Messages;

   procedure Scenario_Hu_Reset;

   procedure Scenario_Hu_Wasm_Start_Up;

end DMI_Test_Language;
