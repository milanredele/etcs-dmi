--  ETCS DMI
--  Headless golden-frame regression runner. Drives DMI_Core in process
--  and compares rendered screens against test/golden/*.frame.
--
--  Usage:  obj/dmi_test            compare against goldens
--          UPDATE=1 obj/dmi_test   (re)record goldens
--          VERBOSE=1 obj/dmi_test  list passing checks too

pragma Ada_2012;
with Ada.Command_Line;
with DMI_Core;
with DMI_Sounds;
with General_Parameters;
with Test_Support; use Test_Support;

procedure DMI_Test is

   -- Fixed flash phase for deterministic frames
   procedure Reset is
   begin
      DMI_Core.Initialise;
      General_Parameters.Flash_On := True;
      Drain_Sounds;
   end Reset;

   ---------------------------------------------------------------------
   -- Speed monitoring scenarios (chapters 7 and 8.2.1)
   ---------------------------------------------------------------------

   procedure Scenario_FS_CSM is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS, L1
      Send_Speed_State (V_Cur => 100, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Step;
      Check_Frame ("fs_csm_nos");

      -- over-speed: OvS then WaS then IntS; no S1 in CSM
      Send_Speed_State (V_Cur => 122, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Expect_No_Sound ("CSM over-speed plays no S1");
      Step;
      Check_Frame ("fs_csm_ovs");

      Send_Speed_State (V_Cur => 127, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Expect_Sound (DMI_Sounds.S2_Warning_Start, "CSM warning starts S2");
      Step;
      Check_Frame ("fs_csm_was");

      Send_Speed_State (V_Cur => 137, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Expect_Sound (DMI_Sounds.S2_Warning_Stop, "CSM IntS stops S2");
      Step;
      Check_Frame ("fs_csm_ints");
   end Scenario_FS_CSM;

   procedure Scenario_FS_TSM is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      -- start in CSM
      Send_Speed_State (V_Cur => 100, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      -- entering TSM plays Sinfo
      Send_Speed_State (V_Cur => 100, V_Perm => 120, V_Target => 80,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 800, Monitoring => 1, Dial_Range => 1,
                        Vrelease_Exists => False);
      Expect_Sound (DMI_Sounds.Sinfo, "TSM entry plays Sinfo");
      Step;
      Check_Frame ("fs_tsm_inds");

      -- over-speed in TSM plays S1 once
      Send_Speed_State (V_Cur => 122, V_Perm => 120, V_Target => 80,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 700, Monitoring => 1, Dial_Range => 1,
                        Vrelease_Exists => False);
      Expect_Sound (DMI_Sounds.S1_Overspeed, "TSM over-speed plays S1");
      Step;
      Check_Frame ("fs_tsm_ovs");

      -- release speed monitoring with release speed
      Send_Speed_State (V_Cur => 30, V_Perm => 40, V_Target => 0,
                        V_Release => 35, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 150, Monitoring => 2, Dial_Range => 1,
                        Vrelease_Exists => True);
      Drain_Sounds;
      Step;
      Check_Frame ("fs_rsm_inds");
   end Scenario_FS_TSM;

   procedure Scenario_AD_White is
   begin
      Reset;
      Send_Mode_Level (Mode => 3, Level => 5); -- AD, L2
      Send_Speed_State (V_Cur => 100, V_Perm => 120, V_Target => 80,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 800, Monitoring => 1, Dial_Range => 1,
                        Vrelease_Exists => False);
      -- AD suppresses the monitoring entry Sinfo
      Expect_No_Sound ("AD suppresses Sinfo");
      Step;
      Check_Frame ("ad_tsm");

      -- warning in AD: no S2
      Send_Speed_State (V_Cur => 127, V_Perm => 120, V_Target => 80,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 700, Monitoring => 1, Dial_Range => 1,
                        Vrelease_Exists => False);
      Expect_No_Sound ("AD suppresses S1/S2");
      Step;
      Check_Frame ("ad_tsm_was");
   end Scenario_AD_White;

   procedure Scenario_CSM_Target_Info is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 100, V_Perm => 120, V_Target => 80,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 1500, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False, CSM_Target_Info => True);
      Drain_Sounds;
      Step;
      Check_Frame ("fs_csm_target_info");
   end Scenario_CSM_Target_Info;

   ---------------------------------------------------------------------
   -- Mode and level acknowledgements (5.4, 8.2.3.1, 8.2.3.2)
   ---------------------------------------------------------------------

   procedure Scenario_Mode_Ack is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      -- EVC requests the OS acknowledgement
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "mode ack offer plays Sinfo");
      Check_Frame ("mode_ack_os");

      -- driver presses C1
      Pointer_Down (190, 340);
      Expect_Sound (DMI_Sounds.Click, "ack press clicks");
      Pointer_Up (190, 340);
      Step;
      Check_Frame ("mode_ack_os_acked");
   end Scenario_Mode_Ack;

   procedure Scenario_Level_Announcement is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      -- plain L2 announcement, no acknowledgement
      Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 5);
      Expect_No_Sound ("plain announcement is silent");
      Step;
      Check_Frame ("level_ann_l2");

      -- L0 announcement with acknowledgement
      Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 2,
                       Level_Ann_Ack => True);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "level ack offer plays Sinfo");
      Check_Frame ("level_ann_l0_ack");
   end Scenario_Level_Announcement;

   ---------------------------------------------------------------------
   -- Windows and toggling (5.3, 8.2.2.4, 8.6)
   ---------------------------------------------------------------------

   procedure Scenario_Windows is
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Step;
      Check_Frame ("default_sb");

      -- open Main via F1
      Pointer_Down (610, 40);
      Pointer_Up (610, 40);
      Drain_Sounds;
      Step;
      Check_Frame ("window_main");

      -- close it again
      Pointer_Down (370, 440);
      Pointer_Up (370, 440);
      Drain_Sounds;
      Step;
      Check_Frame ("default_sb");
   end Scenario_Windows;

   procedure Scenario_Speed_Toggle is
   begin
      Reset;
      -- OS mode with target information: hooks appear only after toggling
      Send_Mode_Level (Mode => 6, Level => 4); -- OS
      Send_Speed_State (V_Cur => 30, V_Perm => 40, V_Target => 30,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 400, Monitoring => 1, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Step;
      Check_Frame ("os_toggled_off");

      -- press the A/B sensitive area
      Pointer_Down (150, 150);
      Pointer_Up (150, 150);
      Drain_Sounds;
      Step;
      Check_Frame ("os_toggled_on");
   end Scenario_Speed_Toggle;

   Status : Natural;
begin
   Scenario_FS_CSM;
   Scenario_FS_TSM;
   Scenario_AD_White;
   Scenario_CSM_Target_Info;
   Scenario_Mode_Ack;
   Scenario_Level_Announcement;
   Scenario_Windows;
   Scenario_Speed_Toggle;

   Status := Summary;
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Exit_Status (Status));
end DMI_Test;
