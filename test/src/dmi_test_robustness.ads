--  ETCS DMI
--  Link supervision and robustness: malformed/overflow input,
--  EVC silence, internal failure containment, and the full
--  mission with the in-process EVC simulator.
--  Golden-frame scenarios extracted from dmi_test.adb;
--  called from DMI_Test in the original order.

package DMI_Test_Robustness is

   procedure Scenario_Speed_Robustness;

   procedure Scenario_Planning_Malformed;

   procedure Scenario_Planning_Overflow;

   procedure Scenario_Sound_Overflow;

   procedure Scenario_Failure_Presentation;

   procedure Scenario_EVC_Link_Lost;

   procedure Scenario_Mission;

end DMI_Test_Robustness;
