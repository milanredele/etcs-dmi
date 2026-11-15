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
      procedure Scenario_SSP_Zero_Length;
      procedure Scenario_SSP_Replacement;
      procedure Scenario_TSR;
      procedure Scenario_MA;
      procedure Scenario_Section_Timer;
      procedure Scenario_Section_Timer_Stopped;
      procedure Scenario_Overlap_Timer;
      procedure Scenario_End_Section_Timer;
      procedure Scenario_LOA_Timer;
      procedure Scenario_MA_Shortening;
      procedure Scenario_NV_Shortening;
      procedure Scenario_National_Values;
      procedure Scenario_National_Values_Kept;
      procedure Scenario_Track_Conditions;
      procedure Scenario_Other_Profiles;
      procedure Scenario_Mode_Profile_Roll_Back;
      --  ERA_ERTMS_015560 5.4.1.9, 5.4.1.9.1: a text to be acknowledged
      --  held behind the acknowledgement of a mode asked
      procedure Scenario_Text_Behind_Mode_Ack;
      --  5.4.1.9.1 6): a text to be acknowledged held behind the
      --  acknowledgement of a brake's release asked before it
      procedure Scenario_Text_Behind_Brake_Ack;

   --  5.4.1.9.1 3) before 6): a text to be acknowledged and the
   --  acknowledgement of a brake's release asked in the same cycle: the
   --  text is sent in that cycle, the request waits in the DMI's queue
   procedure Scenario_Text_Brake_Ack_Same_Cycle;
   procedure Scenario_Text_Held_Before_Brake_Ack;
   --  DMI 5.4.1.9: a text shown, then the brake's release request, then
   --  a second text: the request waits only for the first
   procedure Scenario_Text_After_Brake_Request;
      procedure Scenario_Track_Condition_Roll_Back;
      procedure Scenario_MA_Timers_Roll_Back;
      procedure Scenario_LX_Roll_Back;
      procedure Scenario_Mode_Profile_Relocated;
      --  A.3.5.1 4th bullet over a relocation: an LS profile's beginning
      --  passed, the relocation puts the max safe front end in rear of it
      procedure Scenario_LS_Profile_Relocated;
      procedure Scenario_Track_Condition_Relocated;
      procedure Scenario_LX_Relocated;
      procedure Scenario_Route_Suitability;
      procedure Scenario_Rear_Deletion;
      procedure Scenario_Snapshot_Seams;
      --  A.3.5.1 12th bullet over a relocation: the End Section timer's
      --  start location passed, the relocation puts the front in rear of it
      procedure Scenario_MA_Timers_Relocated;

end EVC_Test_Profiles;
