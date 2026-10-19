--  ETCS on-board (EVC)
--  phase E2: the train position (evc/evc_position.ads), on the
--  track model and odometer of EVC_Test_Support.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Position is

      procedure Scenario_Position_First_Group;
      procedure Scenario_Linking;
      procedure Scenario_Linking_Errors;
   procedure Scenario_Linking_Double_Missed;
      procedure Scenario_Linking_Replacement;
      procedure Scenario_Single_Balise;
      procedure Scenario_Geo;
      procedure Scenario_Geo_Rejected_In_SH;
      procedure Scenario_Geo_By_Radio;
   procedure Scenario_Radio_Linking;
      procedure Scenario_Odometer_Accuracy;
      procedure Scenario_Odometer_Check_By_Mode;
      procedure Scenario_Cold_Movement;
      procedure Scenario_Orientation;
      procedure Scenario_Virtual;
      procedure Scenario_Report_Triggers;
      procedure Scenario_Relocation;
      procedure Scenario_Repositioning;
      procedure Scenario_MA_Repositioning;
      procedure Scenario_Geo_Orientation;
      procedure Scenario_Rear_End;
      procedure Scenario_Report_Reference;
      procedure Scenario_Unauthorised_Direction_Groups;
      procedure Scenario_SOLR_Unlinked;
      procedure Scenario_SL_Deletes_Invalid;

end EVC_Test_Position;
