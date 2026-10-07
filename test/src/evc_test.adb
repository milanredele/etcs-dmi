--  ETCS on-board (EVC)
--  Headless golden runner for EVC_Core. Drives the on-board in process
--  and compares what it outputs against test/golden/evc/*.sha256: a
--  golden is the SHA-256 of the output bytes (the records of
--  EVC_Outbox, every port) taken since the start of a named checkpoint.
--  Besides the digests the scenarios decode what matters (the mode byte
--  the DMI gets, the counts of rejected inputs, ...).
--
--  The scenarios are grouped by phase and subject into the packages
--  listed below (one file each, at most about 1500 lines); this unit
--  only calls them, in the order they always ran in, and prints the
--  summary. A new scenario goes into the file of its subject (or a new
--  one, named EVC_Test_<Subject>, following the same pattern) as a
--  public procedure Scenario_<Name>, called from here in its place.
--  Shared state (the check counters, the golden/dump comparison, the
--  output capture and decoding, the simulated track and the speed and
--  distance monitoring reference model) is EVC_Test_Support's.
--
--  EVC_Test_Core: protocol constants, power-up, malformed input, valid
--  inputs, isolation, time, the outbox, Enter_Failure, and the whole
--  DMI_Core/EVC_Core chain.
--
--  EVC_Test_Language: phase E1, the ERTMS/ETCS language (evc/language):
--  every packet of the catalogue encoded and decoded, telegrams and
--  radio messages built, parsed, damaged, and received by the core on
--  the BTM and RTM ports.
--
--  EVC_Test_Position: phase E2, the train position (evc/evc_position.ads),
--  on the track model and odometer of EVC_Test_Support.
--
--  EVC_Test_Profiles: phase E3 (profiles), the stored information: SSP,
--  gradients, TSR, MA, timers, national values, track conditions, and
--  the seams of the two halves of E3.
--
--  EVC_Test_Supervision: phase E3, speed and distance monitoring
--  (EVC_SDM, EVC_Brake_Commands and the units under them), against the
--  floating point reference model of EVC_Test_Support.
--
--  EVC_Test_Mission: the mission of the mock (dmi_test Scenario_Mission)
--  with the on-board's speed and distance monitoring, and A.3.12's
--  reduced build up times against the reference model.
--
--  EVC_Test_PBD: E3 after the integration, the speed restriction to
--  ensure a permitted braking distance (3.11.11, packet 52, EVC_PBD)
--  and the gaps of the gradient and SSP profiles.
--
--  EVC_Test_Bench: the bench and end-to-end scenarios: the on-board in
--  the environment of sim/ (Sim_Onboard_Env) against the golden
--  bench_onboard, and the wrap of the odometer counters.
--
--  EVC_Test_EMRRLS: Q_NVEMRRLS (7.5.1.123, 3.13.2.3.7.2), run on the
--  mission's line with both values of the national parameter.
--
--  EVC_Test_Config: the installation configuration (EVC_Config), its
--  checks, EVC_Core.Configure, and every field the supervision or the
--  position reads.
--
--  EVC_Test_Modes: phase E4, modes and levels (e4/modes): the mode
--  machine of 4.6, the start of mission of 5.4, the level transitions
--  of 5.10, the acceptance of 4.8, the data of 4.10 and A.3.4.
--
--  Phase E4, the procedures (e4/procedures), are in EVC_Test_Procedures
--  (test/src/evc_test_procedures.adb); a native, touch-only start of
--  mission in Evc_Test_Touch (test/src/evc_test_touch.adb).
--
--  Usage:  obj/evc_test            compare against goldens
--          UPDATE=1 obj/evc_test   (re)record the goldens of test/golden/evc
--          VERBOSE=1 obj/evc_test  list passing checks too
--          EVC_DUMP=dir obj/evc_test  also write the output bytes of every
--                                     golden to dir/<name>.bin, to decode
--                                     what changed (test/tools/evc_dump.py;
--                                     bench_onboard: its hashed DMI frames,
--                                     one record each)

pragma Ada_2012;
with Ada.Command_Line;
with Ada.Text_IO;  use Ada.Text_IO;
with EVC_Test_Handover;
with EVC_Test_Support;  use EVC_Test_Support;
with EVC_Test_Core;      use EVC_Test_Core;
with EVC_Test_Language;  use EVC_Test_Language;
with EVC_Test_Position;  use EVC_Test_Position;
with EVC_Test_Profiles;  use EVC_Test_Profiles;
with EVC_Test_Supervision;  use EVC_Test_Supervision;
with EVC_Test_Mission;  use EVC_Test_Mission;
with EVC_Test_PBD;       use EVC_Test_PBD;
with EVC_Test_Bench;     use EVC_Test_Bench;
with EVC_Test_EMRRLS;    use EVC_Test_EMRRLS;
with EVC_Test_Config;    use EVC_Test_Config;
with EVC_Test_Modes;     use EVC_Test_Modes;
with EVC_Test_Radio;     use EVC_Test_Radio;
with EVC_Test_Sessions;  use EVC_Test_Sessions;
with EVC_Test_Network;   use EVC_Test_Network;
with EVC_Test_Version;   use EVC_Test_Version;
with EVC_Test_RBC;       use EVC_Test_RBC;
with EVC_Test_Authority; use EVC_Test_Authority;
with EVC_Test_Levels;    use EVC_Test_Levels;
with EVC_Test_Procedures;
with Evc_Test_Touch;

procedure EVC_Test is

   ---------------------------------------------------------------------
   --  Phase E4, the procedures (e4/procedures): the scenarios are in
   --  EVC_Test_Procedures (test/src/evc_test_procedures.adb)
   ---------------------------------------------------------------------

   package Procedures is new EVC_Test_Procedures (Check);

   --  A native, touch-only start of mission (test/src/evc_test_touch.adb,
   --  the e4/bench-page follow-up): DMI_Core and EVC_Core connected as
   --  the bench page connects them, the driver acting only through touch
   --  coordinates taken from the DMI's own layout queries.
   package Touch is new Evc_Test_Touch (Check);

begin
   Scenario_Protocol_Constants;
   Scenario_Power_Up;
   Scenario_Malformed;
   Scenario_Valid_Inputs;
   Scenario_Isolation;
   Scenario_Time;
   Scenario_Outbox;
   Scenario_Failure;
   Scenario_End_To_End;
   Scenario_Packet_Round_Trips;
   Scenario_Telegram;
   Scenario_Telegram_Damaged;
   Scenario_Message;
   Scenario_Telegram_Length;
   Scenario_Spare_Values;
   Scenario_Senders;
   Scenario_Received;
   Scenario_Position_First_Group;
   Scenario_Linking;
   Scenario_Linking_Errors;
   Scenario_Single_Balise;
   Scenario_Geo;
   Scenario_Odometer_Accuracy;
   Scenario_Cold_Movement;
   Scenario_Orientation;
   Scenario_Virtual;
   Scenario_Report_Triggers;
   Scenario_Rear_End;
   Scenario_Report_Reference;
   Scenario_Relocation;
   Scenario_Repositioning;
   Scenario_Geo_Orientation;
   Check (Encodes_OK, "E2: every telegram of the track encoded");
   Scenario_E3_Protocol;
   Scenario_SSP_Categories;
   Scenario_SSP_Gradients;
   Scenario_SSP_Replacement;
   Scenario_TSR;
   Scenario_MA;
   Scenario_Section_Timer;
   Scenario_Section_Timer_Stopped;
   Scenario_Overlap_Timer;
   Scenario_End_Section_Timer;
   Scenario_LOA_Timer;
   Scenario_MA_Shortening;
   Scenario_National_Values;
   Scenario_Track_Conditions;
   Scenario_Other_Profiles;
   Scenario_Rear_Deletion;
   Scenario_Snapshot_Seams;
   Check (Encodes_OK, "E3: every telegram of the track encoded");
   Scenario_SDM_Precision;
   Scenario_SDM_Ceiling;
   Scenario_SDM_Approach;
   Scenario_SDM_Release;
   Scenario_SDM_Protections;
   Scenario_SDM_MRSP_Target;
   Scenario_SDM_LOA;
   Scenario_SDM_Calculated_Release;
   Scenario_SDM_Perturbation;
   Scenario_SDM_LOA_And_Temporary;
   Scenario_SDM_Perturbation_Curves;
   Scenario_SDM_Feedback;
   Scenario_SDM_GUI;
   Scenario_SDM_Adhesion;
   Scenario_SDM_Special_Brakes;
   Scenario_SDM_Masking;
   Scenario_SDM_SR;
   Scenario_SDM_Seams;
   Scenario_SDM_Mission;
   Scenario_SDM_Build_Up;
   Scenario_PBD_Precision;
   Scenario_PBD;
   Scenario_Gradient_Gaps;
   Scenario_SSP_Gaps;

   Scenario_Bench_Onboard;
   Scenario_Odometer_Wrap;
   Scenario_Bench_Level_2;
   Scenario_EMRRLS_Ceiling;
   Scenario_EMRRLS_Target;
   Scenario_EMRRLS_EOA_Target;
   Scenario_EMRRLS_Release;
   Scenario_EMRRLS_Acknowledgement;

   Scenario_Config_Image;
   Scenario_Config_Core;
   Scenario_Config_Behaviour;

   Scenario_E4_Tables;
   Scenario_E4_SoM_Level_1;
   Scenario_E4_SoM_Other_Levels;
   Scenario_E4_SR_Distance;
   Scenario_E4_Level_Transition_0;
   Scenario_E4_Level_Ack_Again;
   Scenario_E4_Level_Orders;
   Scenario_E4_Acceptance;
   Scenario_E4_SL_NL_IS;
   Scenario_E4_Odometer_Failure;
   Scenario_E4_Desk_Closed;
   Scenario_E4_Continue_Shunting;
   Scenario_E5P_JRU_Records;
   Check (Encodes_OK, "E4: every telegram of the track encoded");
   Procedures.Run;
   Touch.Run;
   --  phase E5: the radio
   Scenario_Radio_Joint;
   Scenario_Session_Establish;
   Scenario_Session_Lost_Version;
   Scenario_Session_NVCONTACT;
   Scenario_Session_NVCONTACT_Brake;
   Scenario_Session_Indication;
   Scenario_Session_SoM_Level_2;
   Scenario_SoM_L2_SR_Proposal;
   Scenario_Session_SoM_Failures;
   Scenario_Session_EoM;
   Scenario_Session_Reports;
   Scenario_Session_Registration;
   Scenario_Network_List;
   Scenario_Network_S4_Timeout;
   Scenario_Network_Radio_Order;
   EVC_Test_Handover.Scenario_Handover_Radio;
   EVC_Test_Handover.Scenario_Handover_Balise;
   EVC_Test_Handover.Scenario_Handover_Text;
   Scenario_Version_Negotiation;
   Scenario_Version_Retained;
   Scenario_RBC;
   Scenario_Radio_MA;
   Scenario_Radio_MA_Shifted;
   Scenario_MA_Request;
   Scenario_Shortening;
   Scenario_Emergency_Stops;
   Scenario_SR_Authorisation;
   Scenario_Trip_L2;
   Scenario_Shunting_L2;
   Scenario_Radio_Acceptance;
   Scenario_Transition_Buffer;
   Scenario_Start_After_Ack;
   Scenario_Track_Ahead_Free;
   --  e5/levels: the level transitions to and from level 2
   Scenario_L2_Buffer_Same_Cycle;
   Scenario_L2_Driver_Change;
   Scenario_L2_Exit_By_Order;

   Put_Line ("checks:" & Natural'Image (Checks)
             & "  failures:" & Natural'Image (Failures));
   Ada.Command_Line.Set_Exit_Status
     (if Failures = 0 then Ada.Command_Line.Success
      else Ada.Command_Line.Failure);
end EVC_Test;
