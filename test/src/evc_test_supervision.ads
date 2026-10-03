--  ETCS on-board (EVC)
--  phase E3: speed and distance monitoring (EVC_SDM,
--  EVC_Brake_Commands and the units under them), against the
--  floating point reference model of EVC_Test_Support.
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Supervision is

      procedure Scenario_SDM_Precision;
      procedure Scenario_SDM_Ceiling;
      procedure Scenario_SDM_Approach;
      procedure Scenario_SDM_Release;
      procedure Scenario_SDM_Protections;
      procedure Scenario_SDM_MRSP_Target;
      procedure Scenario_SDM_LOA;
      procedure Scenario_SDM_Calculated_Release;
      procedure Scenario_SDM_Perturbation;
      procedure Scenario_SDM_LOA_And_Temporary;
      procedure Scenario_SDM_Perturbation_Curves;
      procedure Scenario_SDM_Feedback;
      procedure Scenario_SDM_GUI;
      procedure Scenario_SDM_Adhesion;
      procedure Scenario_SDM_Special_Brakes;
      procedure Scenario_SDM_Masking;
      procedure Scenario_SDM_SR;
      procedure Scenario_SDM_Seams;

end EVC_Test_Supervision;
