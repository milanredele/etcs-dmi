--  ETCS DMI
--  Data entry window mechanics: input fields, validation, data
--  checks, the alphanumeric keyboard, dedicated keyboards and
--  the flexible train data entry (audit WIN-4 .. WIN-10).
--  Golden-frame scenarios extracted from dmi_test.adb;
--  called from DMI_Test in the original order.

package DMI_Test_Data_Entry is

   procedure Scenario_Entry_Mechanics;

   procedure Scenario_Validation_Window;

   procedure Scenario_Data_Checks;

   procedure Scenario_Alphanumeric_Entry;

   procedure Scenario_Dedicated_Keyboards;

   procedure Scenario_Train_Data_Windows;

end DMI_Test_Data_Entry;
