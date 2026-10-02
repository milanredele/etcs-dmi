--  ETCS on-board (EVC)
--  phase E3 (profiles): the stored information -- SSP, gradients,
--  TSR, MA, timers, national values, track conditions, and the
--  seams of the two halves of E3.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Profiles is

      procedure Scenario_E3_Protocol;
      procedure Scenario_SSP_Categories;
      procedure Scenario_SSP_Gradients;
      procedure Scenario_SSP_Replacement;
      procedure Scenario_TSR;
      procedure Scenario_MA;
      procedure Scenario_Section_Timer;
      procedure Scenario_Section_Timer_Stopped;
      procedure Scenario_Overlap_Timer;
      procedure Scenario_End_Section_Timer;
      procedure Scenario_LOA_Timer;
      procedure Scenario_MA_Shortening;
      procedure Scenario_National_Values;
      procedure Scenario_Track_Conditions;
      procedure Scenario_Other_Profiles;
      procedure Scenario_Rear_Deletion;
      procedure Scenario_Snapshot_Seams;

end EVC_Test_Profiles;
