--  ETCS DMI
--  Body of DMI_Test_System_Status (see dmi_test_system_status.ads).

with DMI_Ack;
with DMI_Protocol;
with DMI_Sounds;
with DMI_Test_Support;
with DMI_Windows;
with Test_Support;
use Test_Support;
use DMI_Test_Support;

package body DMI_Test_System_Status is


   ---------------------------------------------------------------------
   -- SDI-2, SDI-9: the catalogue of the system status messages (chapter
   -- 15, Tables 68 and 70; DMI_System_Status)
   ---------------------------------------------------------------------

   package SS renames DMI_Protocol;

   -- Step is one DMI cycle of 50 ms: 30 s are 600 of them
   SS_Steps_30s : constant := 600;

   ACTION_MAIN_WINDOW_BUTTON : constant := 16;

   procedure Scenario_SS_Catalogue is
   begin
      SS_Reset;
      Send_System_Status (SS.SS_Entering_FS, 0);
      Expect_Sound (DMI_Sounds.Sinfo, "a system status message plays Sinfo");
      Step;
      Check (SS_Active (SS.SS_Entering_FS), "Entering FS started");
      Check_Frame ("ss_entering_fs");

      -- SDI-9: class 2 is a first group message whatever the flag says
      Send_Text (100, "Plain auxiliary text", Class => 1, HH => 9, MM => 42);
      Expect_No_Sound ("a second group message is silent");
      Send_Text (101, "Balise read error", First_Group => False,
                 Class => 2, HH => 9, MM => 43);
      Expect_Sound (DMI_Sounds.Sinfo,
                    "MSG_TEXT class 2 without the flag plays Sinfo");
      Step;
      Check_Frame ("ss_text_class2_bold");

      -- not in the catalogue, no such event, wrong lengths: ignored
      Send_System_Status (0, 0);
      Send_System_Status (39, 0);
      Send_System_Status (255, 0);
      Send_System_Status (SS.SS_Trackside_Malfunction, 3);
      Send_System_Status (SS.SS_Entering_FS, 255);
      Send_Raw (16#0C#, (1 => SS.SS_Trackside_Malfunction));
      Send_Raw (16#0C#, (SS.SS_Trackside_Malfunction, 0, 0));
      Send_Raw (16#0C#, (SS.SS_Entering_FS, 1, 0));
      Expect_No_Sound ("unknown entries and events are ignored");
      Step;
      Check (not SS_Active (SS.SS_Trackside_Malfunction)
             and then SS_Active (SS.SS_Entering_FS),
             "unknown entries and events change nothing");
      Check_Frame ("ss_text_class2_bold");

      -- an end or an intermediate event of an entry not displayed
      Send_System_Status (SS.SS_Runaway_Movement, 1);
      Send_System_Status (SS.SS_Balise_Read_Error_Brake, 2);
      Step;
      Check (not SS_Active (SS.SS_Runaway_Movement)
             and then not SS_Active (SS.SS_Balise_Read_Error_Brake),
             "events of an entry not displayed start nothing");

      -- 4.4.9.1.4: the end event of the EVC ends Entering FS
      Send_System_Status (SS.SS_Entering_FS, 1);
      Step;
      Check (not SS_Active (SS.SS_Entering_FS), "Entering FS ended");
      Check_Frame ("ss_entering_fs_ended");
      Expect_No_Sound ("an end plays nothing");

      -- more texts of the catalogue, as the tables write them
      Send_Text_Remove (100);
      Send_Text_Remove (101);
      Send_Status (HH => 23, MM => 59, SS => 30);
      Send_System_Status (SS.SS_Safe_Consist_Length, 0);
      Send_System_Status (SS.SS_Unauthorized_Passing, 0);
      Send_System_Status (SS.SS_Route_Unsuitable_Axle_Load, 0);
      Drain_Sounds;
      Step;
      Check_Frame ("ss_catalogue_texts");
   end Scenario_SS_Catalogue;

   -- "Message displayed for 30 s": from the start, once the named event
   -- came, and the end event that waits for the 30 s; 15.1.1.7
   procedure Scenario_SS_Timers is
   begin
      -- from the start (Trackside malfunction); the end event of the EVC
      -- is not one of its end conditions
      SS_Reset;
      Send_System_Status (SS.SS_Trackside_Malfunction, 0);
      Drain_Sounds;
      Step;
      Check_Frame ("ss_trackside_malfunction");
      Send_System_Status (SS.SS_Trackside_Malfunction, 1);
      SS_Steps (SS_Steps_30s - 2);
      Check (SS_Active (SS.SS_Trackside_Malfunction),
             "Trackside malfunction shown for 30 s");
      Step;
      Check (not SS_Active (SS.SS_Trackside_Malfunction),
             "Trackside malfunction ends after 30 s");
      Check_Frame ("ss_timer_ended");

      -- 15.1.1.7: a second start while displayed gives one instance that
      -- lasts until the later end; no second Sinfo
      Send_System_Status (SS.SS_Trackside_Malfunction, 0);
      Drain_Sounds;
      SS_Steps (400);
      Send_System_Status (SS.SS_Trackside_Malfunction, 0);
      Expect_No_Sound ("a second instance plays no Sinfo");
      SS_Steps (SS_Steps_30s - 1);
      Check (SS_Active (SS.SS_Trackside_Malfunction),
             "the second instance holds the message");
      Check_Frame ("ss_trackside_malfunction");
      Step;
      Check (not SS_Active (SS.SS_Trackside_Malfunction),
             "the message ends with the second instance");

      -- "30 s once 3.14.1.6 is fulfilled" (Balise read error, brake)
      Send_System_Status (SS.SS_Balise_Read_Error_Brake, 0);
      SS_Steps (SS_Steps_30s + 100);
      Check (SS_Active (SS.SS_Balise_Read_Error_Brake),
             "Balise read error waits for 3.14.1.6");
      Send_System_Status (SS.SS_Balise_Read_Error_Brake, 2);
      SS_Steps (SS_Steps_30s - 1);
      Send_System_Status (SS.SS_Balise_Read_Error_Brake, 2);
      Check (SS_Active (SS.SS_Balise_Read_Error_Brake),
             "Balise read error for 30 s after 3.14.1.6");
      Step;
      Check (not SS_Active (SS.SS_Balise_Read_Error_Brake),
             "Balise read error ends 30 s after 3.14.1.6, not restarted");
      -- 15.1.1.6: the brake command reason revoked ends it at once
      Send_System_Status (SS.SS_Balise_Read_Error_Brake, 0);
      Step;
      Send_System_Status (SS.SS_Balise_Read_Error_Brake, 1);
      Step;
      Check (not SS_Active (SS.SS_Balise_Read_Error_Brake),
             "a revoked brake command reason ends Balise read error");

      -- Communication error: 3.14.1.7 before the 30 s waits for them ...
      Send_System_Status (SS.SS_Communication_Error_Brake, 0);
      SS_Steps (100);
      Send_System_Status (SS.SS_Communication_Error_Brake, 1);
      SS_Steps (SS_Steps_30s - 101);
      Check (SS_Active (SS.SS_Communication_Error_Brake),
             "Communication error shown for 30 s");
      Step;
      Check (not SS_Active (SS.SS_Communication_Error_Brake),
             "Communication error ends 30 s after its start");
      -- ... and after the 30 s ends it at once
      Send_System_Status (SS.SS_Communication_Error_Brake, 0);
      SS_Steps (SS_Steps_30s + 100);
      Check (SS_Active (SS.SS_Communication_Error_Brake),
             "Communication error waits for 3.14.1.7");
      Send_System_Status (SS.SS_Communication_Error_Brake, 1);
      Check (not SS_Active (SS.SS_Communication_Error_Brake),
             "3.14.1.7 after 30 s ends Communication error");

      -- "30 s from the time a train movement is detected"
      Send_System_Status (SS.SS_Train_Data_Changed, 0);
      SS_Steps (50);
      Send_System_Status (SS.SS_Train_Data_Changed, 1);
      Send_System_Status (SS.SS_Train_Data_Changed, 2);
      SS_Steps (SS_Steps_30s - 1);
      Check (SS_Active (SS.SS_Train_Data_Changed),
             "Train data changed for 30 s after the movement");
      Step;
      Check (not SS_Active (SS.SS_Train_Data_Changed),
             "Train data changed ends 30 s after the movement");

      -- 15.1.1.7: two entries of one text are one message, until both
      -- have ended
      Send_System_Status (SS.SS_Balise_Read_Error_Trip, 0);
      Send_System_Status (SS.SS_Balise_Read_Error_Brake, 0);
      Drain_Sounds;
      Step;
      Check_Frame ("ss_single_instance");
      Send_System_Status (SS.SS_Balise_Read_Error_Trip, 1);
      Step;
      Check (SS_Active (SS.SS_Balise_Read_Error_Brake)
             and then not SS_Active (SS.SS_Balise_Read_Error_Trip),
             "one entry of the text ended");
      Check_Frame ("ss_single_instance");
      Send_System_Status (SS.SS_Balise_Read_Error_Brake, 1);
      Step;
      Check_Frame ("ss_timer_ended");
      Expect_No_Sound ("timers play nothing");
   end Scenario_SS_Timers;

   -- "As soon as any button in the main window is selected", reported to
   -- the EVC as driver action 16
   procedure Scenario_SS_Main_Window is
      function Main_Open return Boolean is
        (DMI_Windows.Is_Open
         and then DMI_Windows."=" (DMI_Windows.Top, DMI_Windows.W_Main));
   begin
      SS_Reset;
      Send_System_Status (SS.SS_SH_Refused, 0);
      Send_System_Status (SS.SS_Trackside_Malfunction, 0);
      Drain_Sounds;
      Step;
      Check_Frame ("ss_sh_refused");

      -- F1 is a button of the default window
      Press (610, 40);
      Check (Main_Open, "F1 opens the Main window");
      Check (SS_Active (SS.SS_SH_Refused), "F1 does not end SH refused");
      Expect_Actions (ACTION_MAIN_WINDOW_BUTTON, 0, "F1 is not reported");

      -- [Close] of the Main window ends SH refused only
      Press (370, 440);
      Check (not SS_Active (SS.SS_SH_Refused),
             "a Main window button ends SH refused");
      Check (SS_Active (SS.SS_Trackside_Malfunction),
             "Trackside malfunction does not end so");
      Expect_Actions (ACTION_MAIN_WINDOW_BUTTON, 1,
                      "the Main window button is reported");
      Check_Frame ("ss_main_window_ended");

      -- nothing to end: nothing is reported
      Press (610, 40);
      Press (370, 440);
      Expect_Actions (ACTION_MAIN_WINDOW_BUTTON, 0,
                      "no report without such a message");

      -- a button of another window does not end it
      Send_System_Status (SS.SS_Train_Rejected, 0);
      Send_System_Status (SS.SS_GSMR_Registration_Failed, 0);
      Press (630, 440);       -- F5: Settings
      Press (370, 440);       -- [Close] of Settings
      Check (SS_Active (SS.SS_Train_Rejected)
             and then SS_Active (SS.SS_GSMR_Registration_Failed),
             "a button of the Settings window ends nothing");
      Expect_Actions (ACTION_MAIN_WINDOW_BUTTON, 0,
                      "the Settings window is not reported");

      -- one selection ends all of them (the mode change of 15.1.1.2
      -- aside: Train is rejected is an SB message, the train is in FS)
      Press (610, 40);
      Press (370, 440);
      Check (not SS_Active (SS.SS_Train_Rejected)
             and then not SS_Active (SS.SS_GSMR_Registration_Failed),
             "one Main window button ends both");
      Expect_Actions (ACTION_MAIN_WINDOW_BUTTON, 1,
                      "reported once for both");

      -- "the driver elects to perform the mission with only one radio
      -- system": the end event of the EVC
      Send_System_Status (SS.SS_FRMCS_Registration_Failed, 0);
      Step;
      Send_System_Status (SS.SS_FRMCS_Registration_Failed, 1);
      Step;
      Check (not SS_Active (SS.SS_FRMCS_Registration_Failed),
             "FRMCS network registration failed ends by the EVC too");
      Drain_Sounds;
   end Scenario_SS_Main_Window;

   -- 15.1.1.2: a mode change to a mode of Table 4.7.2 that does not show
   -- the information ends the message
   procedure Scenario_SS_Mode_Change is
   begin
      SS_Reset;
      Send_System_Status (SS.SS_Entering_FS, 0);         -- FS only
      Send_System_Status (SS.SS_Trackside_Malfunction, 0);
      Send_System_Status (SS.SS_Route_Unsuitable_Gauge, 0); -- FS AD LS OS
      Send_System_Status (SS.SS_SH_Refused, 0);          -- not SH
      Drain_Sounds;
      Step;
      -- the same mode again is no change
      Send_Mode_Level (Mode => 2, Level => 4);
      Step;
      Check (SS_Active (SS.SS_Entering_FS), "no mode change, no end");

      Send_Mode_Level (Mode => 6, Level => 4);           -- OS
      Step;
      Check (not SS_Active (SS.SS_Entering_FS)
             and then SS_Active (SS.SS_Trackside_Malfunction)
             and then SS_Active (SS.SS_Route_Unsuitable_Gauge)
             and then SS_Active (SS.SS_SH_Refused),
             "OS ends Entering FS only");
      Check_Frame ("ss_mode_os");

      Send_Mode_Level (Mode => 8, Level => 4);           -- SH
      Step;
      Check (SS_Active (SS.SS_Trackside_Malfunction)
             and then not SS_Active (SS.SS_Route_Unsuitable_Gauge)
             and then not SS_Active (SS.SS_SH_Refused),
             "SH ends Route unsuitable and SH refused");
      Check_Frame ("ss_mode_sh");

      Send_Mode_Level (Mode => 17, Level => 4);          -- IS: NA
      Step;
      Check (not SS_Active (SS.SS_Trackside_Malfunction),
             "IS ends Trackside malfunction");

      -- the trip reason messages last through TR and PT
      Send_Mode_Level (Mode => 11, Level => 4);          -- TR
      Send_System_Status (SS.SS_Emergency_Stop, 0);
      Send_Mode_Level (Mode => 13, Level => 4);          -- PT
      Step;
      Check (SS_Active (SS.SS_Emergency_Stop), "Emergency stop kept in PT");
      Send_Mode_Level (Mode => 1, Level => 4);           -- PT mode left
      Step;
      Check (not SS_Active (SS.SS_Emergency_Stop),
             "leaving PT ends Emergency stop");
      Drain_Sounds;
   end Scenario_SS_Mode_Change;

   -- 15.1.1.4.1: "NL no longer permitted" is acknowledged, and ends so
   procedure Scenario_SS_NL_Acknowledged is
      ACK_SYSTEM_STATUS : constant := 4;
   begin
      SS_Reset (Mode => 14);                             -- NL
      Send_System_Status (SS.SS_NL_No_Longer_Permitted, 0);
      Expect_No_Sound ("the request plays Sinfo when it is displayed");
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "NL no longer permitted is offered");
      Check (DMI_Ack.Current_Valid
             and then DMI_Ack."=" (DMI_Ack.Current_Kind,
                                   DMI_Ack.System_Status),
             "offered as a system status message (5.4.1.9.1)");
      Check_Frame ("ss_nl_ack");
      Pointer_Down (150, 400);
      Pointer_Up (150, 400);
      Step;
      Drain_Sounds;
      Expect_Ack (ACK_SYSTEM_STATUS, 16#8000# + SS.SS_NL_No_Longer_Permitted,
                  "the acknowledgement names the catalogue entry");
      Check (not SS_Active (SS.SS_NL_No_Longer_Permitted),
             "Text acknowledged ends NL no longer permitted");
      Step;
      Check_Frame ("ss_nl_acked");

      -- 15.1.1.2: leaving NL ends it, and its request with it
      Send_System_Status (SS.SS_NL_No_Longer_Permitted, 0);
      Step;
      Send_Mode_Level (Mode => 1, Level => 4);           -- SB
      Step;
      Check (not SS_Active (SS.SS_NL_No_Longer_Permitted)
             and then DMI_Ack.Pending_Count = 0,
             "leaving NL ends the message and revokes its request");
      Drain_Sounds;
      Expect_No_Ack ("nothing acknowledged");
   end Scenario_SS_NL_Acknowledged;

end DMI_Test_System_Status;
