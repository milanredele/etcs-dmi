--  ETCS on-board (EVC)
--  phase E2: the train position (evc/evc_position.ads), on the
--  track model and odometer of EVC_Test_Support.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Position is

      procedure Scenario_Position_First_Group;
      procedure Scenario_Linking;
      procedure Scenario_Linking_Errors;
      procedure Scenario_Single_Balise;
      procedure Scenario_Geo;
      procedure Scenario_Odometer_Accuracy;
      procedure Scenario_Cold_Movement;
      procedure Scenario_Orientation;
      procedure Scenario_Virtual;
      procedure Scenario_Report_Triggers;
      procedure Scenario_Relocation;
      procedure Scenario_Repositioning;
      procedure Scenario_Geo_Orientation;
      procedure Scenario_Rear_End;

end EVC_Test_Position;
