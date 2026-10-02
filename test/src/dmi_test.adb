--  ETCS DMI
--  Headless golden-frame regression runner. Drives DMI_Core in process
--  and compares rendered screens against test/golden/*.frame.
--
--  Usage:  obj/dmi_test            compare against goldens
--          UPDATE=1 obj/dmi_test   (re)record goldens
--          VERBOSE=1 obj/dmi_test  list passing checks too
--          DUMP=1 obj/dmi_test     write every checked frame as
--                                  test/golden/<name>.actual (raw colour
--                                  indices; test/tools/frame2png.py)
--
--  The scenarios themselves live in the DMI_Test_* subject packages
--  (one per area/window group, see AGENTS.md); add a new one to the
--  matching package and call it below in its place.

pragma Ada_2012;
with Ada.Command_Line;
with DMI_Test_ATO;
with DMI_Test_Data_Entry;
with DMI_Test_Language;
with DMI_Test_Messages;
with DMI_Test_Planning;
with DMI_Test_Robustness;
with DMI_Test_Settings;
with DMI_Test_Supervision;
with DMI_Test_System_Status;
with DMI_Test_VBC;
with DMI_Test_Windows;
with Test_Support; use Test_Support;

procedure DMI_Test is
   Status : Natural;
begin
   DMI_Test_Supervision.Scenario_FS_CSM;
   DMI_Test_Supervision.Scenario_FS_TSM;
   DMI_Test_Robustness.Scenario_Speed_Robustness;
   DMI_Test_Supervision.Scenario_AD_White;
   DMI_Test_Supervision.Scenario_CSM_Target_Info;
   DMI_Test_Supervision.Scenario_Mode_Ack;
   DMI_Test_Supervision.Scenario_Level_Announcement;
   DMI_Test_Supervision.Scenario_Windows;
   DMI_Test_Supervision.Scenario_Speed_Toggle;
   DMI_Test_Supervision.Scenario_Status_Objects;
   DMI_Test_Supervision.Scenario_TTI;
   DMI_Test_Supervision.Scenario_BMM_Inhibition;
   DMI_Test_Messages.Scenario_Text_Unknown_Glyphs;
   DMI_Test_Supervision.Scenario_SM_Direction;
   DMI_Test_Messages.Scenario_Text_Messages;
   DMI_Test_Messages.Scenario_Ack_Same_Class;
   DMI_Test_Messages.Scenario_Ack_Arrival_Order;
   DMI_Test_Messages.Scenario_Ack_Revoked;
   DMI_Test_Messages.Scenario_Ack_Remove_One;
   DMI_Test_Messages.Scenario_Ack_Queue_Full;
   DMI_Test_Planning.Scenario_Planning;
   DMI_Test_Robustness.Scenario_Planning_Malformed;
   DMI_Test_Robustness.Scenario_Planning_Overflow;
   DMI_Test_Robustness.Scenario_Sound_Overflow;
   DMI_Test_Messages.Scenario_Text_Store;
   DMI_Test_Windows.Scenario_Startup_Sequence;
   DMI_Test_Windows.Scenario_Other_Windows;
   DMI_Test_Robustness.Scenario_EVC_Link_Lost;
   DMI_Test_Robustness.Scenario_Failure_Presentation;
   DMI_Test_Robustness.Scenario_Mission;
   DMI_Test_Supervision.Scenario_Supervision_Sounds;
   DMI_Test_Supervision.Scenario_TC_Areas_Kept;
   DMI_Test_Supervision.Scenario_Level_NTC_In_C8;
   DMI_Test_Supervision.Scenario_Level_Ann_Acknowledged;
   DMI_Test_Supervision.Scenario_Flash_Starts_Visible;
   DMI_Test_Planning.Scenario_Planning_Zoom_Areas;
   DMI_Test_Planning.Scenario_Planning_Zero_Gradient;
   DMI_Test_Planning.Scenario_Planning_PASP;
   DMI_Test_Planning.Scenario_Planning_Order_Limit;
   DMI_Test_Messages.Scenario_Text_Wrap;
   DMI_Test_Messages.Scenario_Ack_And_Windows;
   DMI_Test_Windows.Scenario_Data_View;
   DMI_Test_Windows.Scenario_Button_Down_Type;
   DMI_Test_Windows.Scenario_Button_Up_Type;
   DMI_Test_Windows.Scenario_Enabling_Conditions;
   DMI_Test_Windows.Scenario_Waiting_Window;
   DMI_Test_Data_Entry.Scenario_Entry_Mechanics;
   DMI_Test_Data_Entry.Scenario_Validation_Window;
   DMI_Test_Data_Entry.Scenario_Data_Checks;
   DMI_Test_Data_Entry.Scenario_Alphanumeric_Entry;
   DMI_Test_Data_Entry.Scenario_Dedicated_Keyboards;
   DMI_Test_Data_Entry.Scenario_Train_Data_Windows;
   DMI_Test_System_Status.Scenario_SS_Catalogue;
   DMI_Test_System_Status.Scenario_SS_Timers;
   DMI_Test_System_Status.Scenario_SS_Main_Window;
   DMI_Test_System_Status.Scenario_SS_Mode_Change;
   DMI_Test_System_Status.Scenario_SS_NL_Acknowledged;
   DMI_Test_ATO.Scenario_ATO_Displays;
   DMI_Test_ATO.Scenario_ATO_Malformed;
   DMI_Test_ATO.Scenario_ATO_Buttons;
   DMI_Test_ATO.Scenario_ATO_Warning_Sound;
   DMI_Test_ATO.Scenario_ATO_Stopping_Points;
   DMI_Test_ATO.Scenario_ATO_Selector_Window;
   DMI_Test_ATO.Scenario_ATO_Mission;
   DMI_Test_Settings.Scenario_Win_Main_Menu;
   DMI_Test_Settings.Scenario_Win_Special_Settings;
   DMI_Test_Settings.Scenario_Win_Radio_Data;
   DMI_Test_Settings.Scenario_Win_Start_Up_Radio;
   DMI_Test_Settings.Scenario_Win_Simulator;
   DMI_Test_Settings.Scenario_HW_Settings_Stored;
   DMI_Test_Settings.Scenario_HW_Desk_Settings;
   DMI_Test_Settings.Scenario_HW_Isolation;
   DMI_Test_Settings.Scenario_HW_Simulator_Isolation;
   DMI_Test_VBC.Scenario_VBC_Settings;
   DMI_Test_VBC.Scenario_VBC_System_Version;
   DMI_Test_VBC.Scenario_VBC_Level_Name;
   DMI_Test_VBC.Scenario_VBC_Data_View;
   DMI_Test_VBC.Scenario_VBC_Simulator;
   DMI_Test_Language.Scenario_Lang_Texts_Fit;
   DMI_Test_Language.Scenario_Lang_Window;
   DMI_Test_Language.Scenario_Lang_German_Windows;
   DMI_Test_Language.Scenario_Lang_Messages;
   DMI_Test_Language.Scenario_Lang_Reset;
   DMI_Test_Language.Scenario_Lang_Settings_Sequence;
   DMI_Test_Language.Scenario_Lang_Simulator;
   DMI_Test_Language.Scenario_Hu_Language_Window;
   DMI_Test_Language.Scenario_Hu_Windows;
   DMI_Test_Language.Scenario_Hu_Messages;
   DMI_Test_Language.Scenario_Hu_Reset;
   DMI_Test_Language.Scenario_Hu_Wasm_Start_Up;
   DMI_Test_Supervision.Scenario_PT_TTI_Steps;
   DMI_Test_Supervision.Scenario_Px_Speed_Dial;
   DMI_Test_Planning.Scenario_PF_Distance_Bar;
   DMI_Test_Planning.Scenario_PF_TAF;
   DMI_Test_Planning.Scenario_PF_Scroll_Disabled;
   DMI_Test_Planning.Scenario_PF_G_Empty;

   Status := Summary;
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Exit_Status (Status));
end DMI_Test;
