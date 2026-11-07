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
--  EVC_Test_JRU: the juridical recording in the message format of
--  SUBSET-027 4.2 (EVC_JRU_Messages), the header the on-board captures.
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
with EVC_Test_Shapes;
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
with EVC_Test_JRU;       use EVC_Test_JRU;
with EVC_Test_Consistency; use EVC_Test_Consistency;
with EVC_Test_Modes;     use EVC_Test_Modes;
with EVC_Test_LS;
with EVC_Test_Radio;     use EVC_Test_Radio;
with EVC_Test_Sessions;  use EVC_Test_Sessions;
with EVC_Test_Manoeuvre;
with EVC_Test_Network;   use EVC_Test_Network;
with EVC_Test_Version;   use EVC_Test_Version;
with EVC_Test_VBC;
with EVC_Test_RBC;       use EVC_Test_RBC;
with EVC_Test_Authority; use EVC_Test_Authority;
with EVC_Test_Levels;    use EVC_Test_Levels;
with EVC_Test_Procedures;
with EVC_Test_Train_Data;
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
   Scenario_Onboard_Entry_Type;
   Scenario_System_Version_To_DMI;
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
   Scenario_Linking_Double_Missed;
   Scenario_Linking_Replacement;
   Scenario_Single_Balise;
   Scenario_Geo;
   Scenario_Geo_Rejected_In_SH;
   Scenario_Geo_By_Radio;
   Scenario_Radio_Linking;
   Scenario_TAF_Relocated;
   Scenario_Odometer_Accuracy;
   Scenario_Odometer_Check_By_Mode;
   Scenario_Cold_Movement;
   Scenario_Orientation;
   Scenario_Virtual;
   Scenario_Report_Triggers;
   Scenario_Rear_End;
   Scenario_Report_Reference;
   Scenario_Unauthorised_Direction_Groups;
   Scenario_SOLR_Unlinked;
   Scenario_SL_Deletes_Invalid;
   Scenario_Crossing_Direction;
   Scenario_LRBG_Unknown_Accepted;
   Scenario_Stored_Cells;
   Scenario_Relocation;
   Scenario_Repositioning;
   Scenario_MA_Repositioning;
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
   Scenario_NV_Shortening;
   Scenario_National_Values;
   Scenario_National_Values_Kept;
   Scenario_Track_Conditions;
   Scenario_Other_Profiles;
   Scenario_Mode_Profile_Roll_Back;
   Scenario_Track_Condition_Roll_Back;
   Scenario_MA_Timers_Roll_Back;
   Scenario_LX_Roll_Back;
   Scenario_Mode_Profile_Relocated;
   Scenario_Track_Condition_Relocated;
   Scenario_LX_Relocated;
   Scenario_Route_Suitability;
   Scenario_Rear_Deletion;
   Scenario_Snapshot_Seams;
   Scenario_MA_Timers_Relocated;
   Check (Encodes_OK, "E3: every telegram of the track encoded");
   Scenario_SDM_Precision;
   Scenario_SDM_Gamma;
   Scenario_SDM_Ceiling;
   Scenario_SDM_Approach;
   Scenario_SDM_JRU_Every_Change;
   Scenario_SDM_Release;
   Scenario_SDM_RSM_Start_Reduced;
   Scenario_SDM_Status_Order;
   Scenario_SDM_Protections;
   Scenario_SDM_MRSP_Target;
   Scenario_SDM_EB_Revocation_TSM;
   Scenario_SDM_LOA;
   Scenario_SDM_Calculated_Release;
   Scenario_SDM_Perturbation;
   Scenario_SDM_Perturbation_Behind;
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
   Scenario_Planning;

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
   Scenario_Config_Zones;
   EVC_Test_Core.Scenario_Local_Time;
   Scenario_JRU_Format;
   Scenario_JRU_On_Board;
   Scenario_JRU_Entry_Type;
   Scenario_JRU_To_RBC;
   Scenario_JRU_Track_Conditions;
   Scenario_JRU_General;
   Scenario_JRU_Train_Data;
   Scenario_JRU_Driver_Choices;
   Scenario_JRU_Commands;
   Scenario_JRU_LSSMA;
   Scenario_JRU_Failure;
   Scenario_JRU_Brake_Status;
   Scenario_JRU_Symbols;
   Scenario_JRU_Traction_Status;
   Scenario_Message_Consistency;
   Scenario_Consistency_Record;
   Scenario_Duplicated_Pair;
   Scenario_Default_Balise;
   Scenario_Consistency_Reactions;
   Scenario_Consistency_Modes;
   Scenario_Consistency_Error_Report;
   Scenario_Consistency_NL;
   Scenario_Consistency_Undecoded;

   Scenario_E4_Tables;
   Scenario_E4_SoM_Level_1;
   Scenario_E4_SoM_Other_Levels;
   Scenario_Train_Data_Movement;
   Scenario_Train_Data_Left;
   Scenario_SR_Data_Movement;
   Scenario_SR_Data_Brake_Revoked;
   Scenario_E4_SR_Distance;
   Scenario_SR_National_Distance;
   Scenario_Driver_Adhesion;
   Scenario_Train_Data_Categories;
   EVC_Test_Train_Data.Scenario_Transition_Deleted;
   EVC_Test_Train_Data.Scenario_Longer_Train;
   EVC_Test_Train_Data.Scenario_RBC_TRN;
   EVC_Test_Train_Data.Scenario_Engine_Length;
   EVC_Test_Train_Data.Scenario_Released_TRN;
   EVC_Test_Train_Data.Scenario_Train_Type;
   Scenario_Driver_Level_Table;
   Scenario_E4_Level_Transition_0;
   Scenario_E4_Level_0_Ack_In_SH;
   Scenario_E4_Level_Ack_Again;
   Scenario_E4_Level_Orders;
   Scenario_E4_Acceptance;
   Scenario_E4_SL_NL_IS;
   Scenario_E4_Odometer_Failure;
   Scenario_E4_Desk_Closed;
   Scenario_E4_Continue_Shunting;
   Scenario_Infill_Rejected;
   Scenario_E5P_JRU_Records;
   Scenario_E5P_JRU_Bodies;
   Scenario_JRU_Inputs;
   Scenario_JRU_Level_Again;
   Scenario_TR_Desk_Closed;
   EVC_Test_LS.Scenario_LS_Display;
   EVC_Test_LS.Scenario_LS_Order_Buffered;
   EVC_Test_LS.Scenario_LS_Marker_Deleted;
   EVC_Test_LS.Scenario_LS_Order_Area;
   EVC_Test_LS.Scenario_LS_Radio_Held;
   Check (Encodes_OK, "E4: every telegram of the track encoded");
   Procedures.Run;
   Touch.Run;
   --  phase E5: the radio
   Scenario_Radio_Joint;
   Scenario_Radio_Length_Check;
   Scenario_Radio_Unknown_Message;
   Scenario_Session_Rows;
   Scenario_Session_Establish;
   Scenario_Session_Lost_Version;
   Scenario_Session_NVCONTACT;
   Scenario_Session_NVCONTACT_Brake;
   Scenario_Session_NVCONTACT_Standstill;
   Scenario_Session_Indication;
   Scenario_Session_Radio_Hole;
   Scenario_Session_SoM_Level_2;
   Scenario_Session_TRN;
   Scenario_SoM_L2_SR_Proposal;
   Scenario_SoM_L2_Mode_Proposal;
   Scenario_SoM_L2_Mode_Proposal_SH;
   Scenario_SoM_L2_MA_Without_Profile;
   Scenario_PT_L2_SR_Proposal;
   Scenario_PT_L2_Mode_Proposal;
   Scenario_SoM_L2_Same_Cycle;
   Scenario_Train_Length_To_Position;
   Scenario_Session_Mode_Change;
   Scenario_Session_Mode_Change_Capped;
   Scenario_Session_Lost_Send;
   Scenario_Session_Abort_Desk;
   Scenario_Session_Abort_EoM;
   Scenario_Session_Short_Number;
   Scenario_Session_SoM_Completed;
   Scenario_Session_Hole_Rows;
   Scenario_Session_Driver_Contact;
   Scenario_Session_Hole_Contact;
   Scenario_Session_Stamp_Increment;
   Scenario_Session_NVCONTACT_Values;
   Scenario_Session_Order_Rows;
   Scenario_Report_Parameters_Direction;
   Scenario_SoM_L2_Mode_Proposal_LS;
   Scenario_SoM_L2_Override;
   Scenario_SoM_L2_Override_Before_S10;
   Scenario_SoM_L2_Override_From_S20;
   Scenario_Session_SoM_Failures;
   Scenario_Session_EoM;
   Scenario_Session_Reports;
   Scenario_Report_Packet;
   Scenario_Coordinate_Assignment;
   Scenario_Report_Reversing;
   Scenario_Session_Sleeping;
   Scenario_Session_Desk_Opening;
   Scenario_Mode_Report_Repeated;
   Scenario_SH_Request_Failed;
   Scenario_Shunting_L2_Terminated;
   Scenario_Contact_Error_Report;
   Scenario_Balise_Error_While_Lost;
   Scenario_Session_Terminate_Lost;
   Scenario_Session_Entry_Terminating;
   Scenario_Text_Ack_Report;
   Scenario_Train_Integrity;
   --  phase E6: Supervised Manoeuvre, the safe consist length
   EVC_Test_Manoeuvre.Scenario_Safe_Consist;
   EVC_Test_Manoeuvre.Scenario_SM_Request;
   EVC_Test_Manoeuvre.Scenario_SM_Authorisation;
   EVC_Test_Manoeuvre.Scenario_SM_Default_Data;
   EVC_Test_Manoeuvre.Scenario_SM_Entering;
   EVC_Test_Manoeuvre.Scenario_SM_Consist_Info;
   EVC_Test_Manoeuvre.Scenario_SM_Handover;
   EVC_Test_Manoeuvre.Scenario_SM_Direction;
   EVC_Test_Manoeuvre.Scenario_SM_Brake_Reasons;
   EVC_Test_Manoeuvre.Scenario_SM_Post_Trip;
   EVC_Test_Manoeuvre.Scenario_SM_Start_Of_Mission;
   EVC_Test_Manoeuvre.Scenario_SM_Gamma;
   EVC_Test_Manoeuvre.Scenario_SM_Remote_Shunting;
   EVC_Test_Manoeuvre.Scenario_SM_Consist_Rejects;
   Scenario_Session_Error_Report;
   Scenario_Session_JRU_Received;
   Scenario_Session_Registration;
   Scenario_SoM_S4_Without_Contact;
   Scenario_RBC_Contact_To_DMI;
   Scenario_Network_List;
   Scenario_Network_S4_Timeout;
   Scenario_Network_FRMCS;
   Scenario_Network_S4_Without_Contact;
   Scenario_Network_One_Radio_Desk_Closed;
   Scenario_Network_Type_At_S3;
   Scenario_Network_Radio_Order;
   Scenario_Network_Level_1;
   Scenario_Network_A43_One_Radio;
   EVC_Test_Handover.Scenario_Handover_Radio;
   EVC_Test_Handover.Scenario_Handover_Balise;
   EVC_Test_Handover.Scenario_Handover_Text;
   EVC_Test_Handover.Scenario_Handover_LSSMA;
   EVC_Test_Handover.Scenario_Handover_Deletion;
   EVC_Test_Handover.Scenario_Handover_EoM;
   EVC_Test_Handover.Scenario_Handover_Indication;
   EVC_Test_Handover.Scenario_Handover_Same_RBC;
   EVC_Test_Handover.Scenario_Handover_Ack_Missing;
   EVC_Test_Handover.Scenario_Handover_Rear_Repeat;
   EVC_Test_Handover.Scenario_Handover_Exception_2;
   EVC_Test_Handover.Scenario_Handover_Contact;
   EVC_Test_Handover.Scenario_Handover_Rear_Border;
   EVC_Test_Handover.Scenario_Handover_Rear_Report;
   EVC_Test_Handover.Scenario_Handover_Roll_Back;
   EVC_Test_Handover.Scenario_Handover_Train_Data_Once;
   EVC_Test_Handover.Scenario_Handover_Order_Again;
   EVC_Test_Handover.Scenario_Handover_Text_No_LRBG;
   EVC_Test_Handover.Scenario_Train_Data_Repeats;
   EVC_Test_Handover.Scenario_Handover_Session_Report;
   EVC_Test_Handover.Scenario_Handover_Error_Report;
   EVC_Test_Handover.Scenario_Handover_Relocated;
   EVC_Test_Handover.Scenario_Handover_Message_Error;
   EVC_Test_Handover.Scenario_Handover_TD_Per_Session;
   EVC_Test_Handover.Scenario_Handover_TD_Values_Per_RBC;
   Scenario_Version_Negotiation;
   Scenario_Version_Retained;
   Scenario_Version_Balise_Groups;
   Scenario_Version_Country_Set;
   EVC_Test_VBC.Scenario_VBC_Store;
   EVC_Test_VBC.Scenario_VBC_Driver;
   EVC_Test_VBC.Scenario_VBC_Rooms;
   EVC_Test_VBC.Scenario_VBC_Cover;
   EVC_Test_VBC.Scenario_VBC_Clock;
   Scenario_RBC;
   Scenario_Radio_MA;
   Scenario_Radio_MA_Shifted;
   Scenario_Radio_MA_Direction;
   Scenario_MA_Request;
   Scenario_MA_Request_Perturbation;
   Scenario_Contact_Shortening;
   Scenario_Shortening;
   Scenario_Shortening_Cover;
   Scenario_Emergency_Stops;
   Scenario_LX_By_Radio;
   Scenario_Suitability_By_Radio;
   Scenario_Track_Condition_By_Radio;
   Scenario_Conditional_Stop_Ends;
   Scenario_SR_Authorisation;
   Scenario_SR_Stop_Listed;
   Scenario_Trip_L2;
   Scenario_PT_Acceptance_Level;
   Scenario_Linked_Group_At_EOA;
   Scenario_Override_Ends_By_Radio;
   Scenario_Group_Read_At_EOA;
   Scenario_Shunting_L2;
   EVC_Test_Shapes.Scenario_Radio_SH_List;
   Scenario_Radio_Acceptance;
   Scenario_Transition_Buffer;
   Scenario_L2_Balise_Buffer_LX;
   Scenario_PBD_By_Radio_Buffered;
   Scenario_Buffer_Three_Sets;
   Scenario_Own_Units_Stored;
   Scenario_Released_Linking;
   Scenario_Text_Shortening;
   Scenario_Text_Roll_Back;
   Scenario_Text_Stop_Roll_Back;

   Scenario_Start_After_Ack;
   Scenario_TAF_Up_To_L2;
   Scenario_Track_Ahead_Free;
   Scenario_TAF_Roll_Back;
   Scenario_TSR_Inhibition;
   Scenario_TSR_Inhibition_Border;
   Scenario_Parameters_Direction;
   Scenario_SR_List_Direction;
   Scenario_Text_Relocated;
   Scenario_Text_Stop_Relocated;
   Scenario_TAF_Relocated_In_Rear;
   Scenario_Train_Data_Per_Packet;
   Scenario_Train_Data_Changed;
   --  e5/levels: the level transitions to and from level 2
   Scenario_L2_Buffer_Same_Cycle;
   Scenario_L2_Order_With_L1_MA;
   Scenario_L1_Order_With_L1_MA_In_L0;
   Scenario_L1_Order_With_L1_MA_In_Second_Balise;
   Scenario_L1_Order_After_L0_Order;
   Scenario_L1_Balise_Buffer;
   Scenario_L1_Balise_Buffer_Deleted;
   Scenario_L1_Balise_Buffer_From_L0;
   Scenario_L1_Balise_Buffer_Units;
   Scenario_L1_Order_Own_Group_Linking;
   Scenario_L2_Driver_Change;
   Scenario_L2_Exit_By_Order;
   Scenario_L2_Exit_In_NL;
   Scenario_L2_Exit_Aborts_Establishment;
   Scenario_L2_Switch_Contact;
   Scenario_L2_Order_Linked_Group;
   Scenario_L2_Radio_Data_No_Contact;
   Scenario_L2_Radio_Data_No_Registration;
   Scenario_L2_Radio_Data_Into_TR;
   Scenario_SR_Order_Single_Group;
   Scenario_Radio_Level_Orders;
   Scenario_SH_Order_At_Zero;

   Put_Line ("checks:" & Natural'Image (Checks)
             & "  failures:" & Natural'Image (Failures));
   Ada.Command_Line.Set_Exit_Status
     (if Failures = 0 then Ada.Command_Line.Success
      else Ada.Command_Line.Failure);
end EVC_Test;
