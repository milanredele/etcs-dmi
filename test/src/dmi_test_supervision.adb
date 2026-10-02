--  ETCS DMI
--  Body of DMI_Test_Supervision (see dmi_test_supervision.ads).

with DMI_Ack;
with DMI_Core;
with DMI_Flash;
with DMI_Sounds;
with DMI_Status;
with DMI_Test_Support;
with Speed_And_Distance;
with Test_Support;
use Test_Support;
use DMI_Test_Support;

package body DMI_Test_Supervision is

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

   -- ROB-3 / ROB-4: mode (MSG_MODE_LEVEL), monitoring and speeds
   -- (MSG_SPEED_STATE) and the set speed / TTI (MSG_STATUS) arrive in
   -- separate messages and every field is EVC controlled, so every
   -- combination, in any order, has to render without raising; this
   -- includes the ones Tables 8 to 11, 13 and 14 mark "not applicable"
   -- (8.2.1.2.5, 8.2.1.4.9, 8.2.1.5.7, 8.2.1.6.5, 8.2.2.1.8, 8.2.2.2.7)
   -- and values beyond the dial (8.2.1.1.3) and the bar (8.2.2.1.6).
   -- An exception ends the run: there is no handler, as on the target.
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

   ---------------------------------------------------------------------
   -- Supervision status from the EVC and the sounds of chapter 7
   -- (SUP-1 .. SUP-5, SDI-4)
   ---------------------------------------------------------------------

   procedure Scenario_Supervision_Sounds is
      procedure TSM (Status : Natural; MRDT : Natural := 1; V_Cur : Natural := 100) is
      begin
         Send_Speed_State (V_Cur => V_Cur, V_Perm => 120, V_Target => 60,
                           V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                           D_Target => 800, Monitoring => 1, Dial_Range => 1,
                           Vrelease_Exists => False, Status => Status,
                           MRDT => MRDT);
      end TSM;

      procedure CSM (Status : Natural; V_Cur : Natural := 100) is
      begin
         Send_Speed_State (V_Cur => V_Cur, V_Perm => 120, V_Target => 0,
                           V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                           D_Target => 0, Monitoring => 0, Dial_Range => 1,
                           Vrelease_Exists => False, Status => Status);
      end CSM;

      use type Speed_And_Distance.Supervision_Status_T;
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS

      -- SUP-1: the status is the EVC's, not a comparison of speeds. A
      -- brake commanded below the DMI's view of the SBI speed shows IntS.
      CSM (Status => 4, V_Cur => 100);
      Check (Speed_And_Distance.Get_Supervision_Status = Speed_And_Distance.IntS,
             "IntS from the EVC below Vsbi");
      Step;
      Check_Frame ("sup_csm_ints_below_vsbi");
      -- and a speed above Vsbi with status NoS stays NoS
      CSM (Status => 0, V_Cur => 140);
      Check (Speed_And_Distance.Get_Supervision_Status = Speed_And_Distance.NoS,
             "NoS from the EVC above Vsbi");

      -- a status that does not exist under the monitoring is replaced
      CSM (Status => 1);
      Check (Speed_And_Distance.Get_Supervision_Status = Speed_And_Distance.NoS,
             "IndS in CSM is NoS");
      Drain_Sounds;
      TSM (Status => 0);
      Check (Speed_And_Distance.Get_Supervision_Status = Speed_And_Distance.IndS,
             "NoS in TSM is IndS");
      Expect_Sound (DMI_Sounds.Sinfo, "entering TSM plays Sinfo");
      Expect_No_Sound ("nothing else on entering TSM");

      -- SUP-2: change of MRDT within TSM
      TSM (Status => 1, MRDT => 1);
      Expect_No_Sound ("same MRDT is silent");
      TSM (Status => 1, MRDT => 2);
      Expect_Sound (DMI_Sounds.Sinfo, "change of MRDT plays Sinfo");
      Expect_No_Sound ("one Sinfo per change of MRDT");

      -- SUP-3: S1 when the train gets above P, whichever status says so
      TSM (Status => 3, MRDT => 2); -- IndS straight to WaS
      Expect_Sound (DMI_Sounds.S2_Warning_Start, "WaS starts S2");
      Expect_Sound (DMI_Sounds.S1_Overspeed, "IndS to WaS plays S1");
      TSM (Status => 4, MRDT => 2);
      Expect_Sound (DMI_Sounds.S2_Warning_Stop, "IntS stops S2");
      TSM (Status => 2, MRDT => 2); -- IntS back to OvS
      Expect_No_Sound ("IntS to OvS does not replay S1");
      TSM (Status => 1, MRDT => 2);
      TSM (Status => 2, MRDT => 2);
      Expect_Sound (DMI_Sounds.S1_Overspeed, "IndS to OvS plays S1");
      -- entering TSM while already over speed activates nothing
      CSM (Status => 2);
      Drain_Sounds;
      TSM (Status => 2, MRDT => 3);
      Expect_Sound (DMI_Sounds.Sinfo, "entering TSM over speed: Sinfo");
      Expect_No_Sound ("entering TSM over speed: no S1");

      -- SUP-4: S2 follows the mode under an unchanged WaS
      Send_Mode_Level (Mode => 3, Level => 5); -- AD
      Drain_Sounds;
      TSM (Status => 3, MRDT => 3);
      Expect_No_Sound ("WaS in AD is silent");
      Send_Mode_Level (Mode => 2, Level => 5); -- the driver takes over: FS
      Expect_Sound (DMI_Sounds.S2_Warning_Start, "leaving AD in WaS starts S2");
      Send_Mode_Level (Mode => 3, Level => 5);
      Expect_Sound (DMI_Sounds.S2_Warning_Stop, "entering AD stops S2");
      -- AD: no Sinfo on a change of MRDT either
      TSM (Status => 1, MRDT => 4);
      Expect_No_Sound ("change of MRDT in AD is silent");

      -- SUP-5: the EVC brakes because the mode acknowledgement is not
      -- given (brake = 3); the acknowledgement releases it: no Sinfo
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6); -- OS ack
      Step;
      Send_Status (Brake => 3, Radio => 1, HH => 9, MM => 0, SS => 0);
      Step;
      Check_Frame ("sup_brake_for_pending_ack");
      Drain_Sounds;
      Drain_Outbox;
      Pointer_Down (190, 340);
      Pointer_Up (190, 340);
      Step;
      Drain_Sounds; -- click
      Expect_Ack (DMI_Ack.Ack_Kind_T'Pos (DMI_Ack.Mode_Change), 0,
                  "mode acknowledged while the brake symbol is shown");
      Send_Mode_Level (Mode => 6, Level => 4);
      Expect_No_Sound ("entering OS after the acknowledgement is silent");
      Send_Status (Brake => 0, Radio => 1, HH => 9, MM => 0, SS => 1);
      Expect_No_Sound ("brake released by the mode acknowledgement: no Sinfo");
      -- an ordinary intervention during which the driver acknowledges an
      -- unrelated text: the release still plays Sinfo
      Send_Status (Brake => 1, Radio => 1, HH => 9, MM => 0, SS => 2);
      Send_Text (20, "Balise read error", Ack_Required => True,
                 HH => 9, MM => 0);
      for I in 1 .. 25 loop -- past the 1 s between two requests (5.4.1.9)
         Step;
      end loop;
      Drain_Sounds;
      Drain_Outbox;
      Pointer_Down (150, 400);
      Pointer_Up (150, 400);
      Step;
      Drain_Sounds;
      Expect_Ack (3, 20, "unrelated text acknowledged during the intervention");
      Send_Status (Brake => 0, Radio => 1, HH => 9, MM => 0, SS => 3);
      Expect_Sound (DMI_Sounds.Sinfo,
                    "release after an unrelated acknowledgement plays Sinfo");
      -- the last cause counts: pending acknowledgement, then overspeed
      Send_Status (Brake => 3, Radio => 1, HH => 9, MM => 0, SS => 4);
      Send_Status (Brake => 1, Radio => 1, HH => 9, MM => 0, SS => 5);
      Send_Status (Brake => 0, Radio => 1, HH => 9, MM => 0, SS => 6);
      Expect_Sound (DMI_Sounds.Sinfo, "cause changed to an ordinary one: Sinfo");

      -- SDI-4: the supervised manoeuvre direction changes
      Reset;
      Send_Mode_Level (Mode => 4, Level => 5); -- SM
      Send_Status (SM_Direction => 1, Radio => 1, HH => 9, MM => 0, SS => 0);
      Drain_Sounds;
      Send_Status (SM_Direction => 1, Radio => 1, HH => 9, MM => 0, SS => 1);
      Expect_No_Sound ("same SM direction is silent");
      Send_Status (SM_Direction => 2, Radio => 1, HH => 9, MM => 0, SS => 2);
      Expect_Sound (DMI_Sounds.Sinfo, "SM direction change plays Sinfo");
   end Scenario_Supervision_Sounds;

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
      procedure Tap (X, Y : Natural) is
      begin
         Pointer_Down (X, Y);
         Pointer_Up (X, Y);
         Step;
      end Tap;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      -- the entry into SB engages the Start Up dialogue sequence (Table
      -- 49, see Scenario_Startup_Sequence): Driver ID 1, Level 1, and
      -- the Main window of S10 is closed
      Tap (385, 240);
      Tap (487, 90);
      Tap (410, 90);
      Tap (370, 440);
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

   ---------------------------------------------------------------------
   -- Status objects and text messages (8.2.2.3/.5, 8.2.3.5-.11, 8.4)
   ---------------------------------------------------------------------

   procedure Scenario_Status_Objects is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 80, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      -- radio up, slippery rail, reversing, set speed, clock, track
      -- conditions in B3/B4/B5 (pantograph announcement + neutral
      -- section + LX), announced tunnel with distance
      Send_Track_Cond ((2, 6, 38));
      Send_Status (Radio => 1, Adhesion => True, Reversing => True,
                   Set_Speed => 100,
                   Tunnel => 2, Tunnel_Dist => 1234,
                   Geo_Pos => 123456, Geo_Valid => True,
                   HH => 17, MM => 33, SS => 25);
      Drain_Sounds;
      Step;
      Check_Frame ("status_base");

      -- tunnel toggle on via C2-C4 press, geo toggle on via G12 press
      Pointer_Down (100, 340); Pointer_Up (100, 340);
      Pointer_Down (450, 440); Pointer_Up (450, 440);
      Drain_Sounds;
      Step;
      Check_Frame ("status_toggled");

      -- brake intervention without ack, then release: Sinfo
      Send_Status (Brake => 1, Radio => 1,
                   HH => 17, MM => 33, SS => 25);
      Drain_Sounds;
      Step;
      Check_Frame ("brake_shown");
      Send_Status (Brake => 0, Radio => 1,
                   HH => 17, MM => 33, SS => 25);
      Expect_Sound (DMI_Sounds.Sinfo, "brake release without ack plays Sinfo");

      -- brake with ack: flashing frame + Sinfo, ack via extended area
      Send_Status (Brake => 2, Radio => 1,
                   HH => 17, MM => 33, SS => 25);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "brake ack offer plays Sinfo");
      Check_Frame ("brake_ack");
      Pointer_Down (25, 330); -- C8, part of the extended sensitive area
      Expect_Sound (DMI_Sounds.Click, "brake ack press clicks");
      Pointer_Up (25, 330);
      Step;
      Check_Frame ("brake_acked");
   end Scenario_Status_Objects;

   procedure Scenario_TTI is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 100, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      -- TTI appears (National Value requested): Sinfo, growing square
      Send_Status (TTI => 100, T_Disp_TTI => 14);
      Expect_Sound (DMI_Sounds.Sinfo, "TTI display plays Sinfo");
      Step;
      Check_Frame ("tti_10s");
      Send_Status (TTI => 20, T_Disp_TTI => 14);
      Drain_Sounds;
      Step;
      Check_Frame ("tti_2s");
   end Scenario_TTI;

   -- 8.2.3.11 / chapter 13 Table 61: ST07 in C6. Regression for the
   -- audit finding ROB-1 (the former text stand-in stopped the DMI).
   procedure Scenario_BMM_Inhibition is
   begin
      Reset;
      Send_Mode_Level (Mode => 7, Level => 4); -- SR, L1
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Send_Status (BMM => True);
      Drain_Sounds;
      Step;
      Check_Frame ("bmm_shown");
      -- C6 holds one 32 x 32 symbol: ST06 (8.4.2.2) while both apply
      Send_Status (BMM => True, Reversing => True);
      Drain_Sounds;
      Step;
      Check_Frame ("bmm_with_reversing");
      -- ST07 returns when ST06 is removed
      Send_Status (BMM => True);
      Drain_Sounds;
      Step;
      Check_Frame ("bmm_shown");
      -- revoked (11.7.6 S1): the symbol is removed
      Send_Status;
      Drain_Sounds;
      Step;
      Check_Frame ("bmm_removed");
   end Scenario_BMM_Inhibition;

   -- 8.2.3.4.1: text comes from the EVC and must never stop the DMI
   -- (audit finding ROB-2). Characters without a glyph are drawn as the
   -- replacement box of Display.Draw.
   procedure Scenario_SM_Direction is
   begin
      Reset;
      Send_Mode_Level (Mode => 4, Level => 5); -- SM, L2
      Send_Speed_State (V_Cur => 10, V_Perm => 30, V_Target => 0,
                        V_Release => 0, V_Sbi => 40, V_Wsl => 35,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Send_Status (SM_Direction => 1);
      Drain_Sounds;
      Step;
      Check_Frame ("sm_forward");
   end Scenario_SM_Direction;

   function TC_Slot_Of (ID : Natural) return Natural is
   begin
      for I in 1 .. DMI_Status.TC_Count loop
         if DMI_Status.TC_List (I).ID = ID then
            return DMI_Status.TC_List (I).Slot;
         end if;
      end loop;
      return 99;
   end TC_Slot_Of;

   function TC_Kind_Of (ID : Natural) return Natural is
   begin
      for I in 1 .. DMI_Status.TC_Count loop
         if DMI_Status.TC_List (I).ID = ID then
            return DMI_Status.TC_List (I).Kind;
         end if;
      end loop;
      return 99;
   end TC_Kind_Of;

   -- SDI-5 (8.2.3.5.3, 8.2.3.8.3): a displayed object keeps its area, a
   -- freed area goes to a waiting object
   procedure Scenario_TC_Areas_Kept is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS, L1
      Send_Speed_State (V_Cur => 80, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      -- four objects for three areas: lower pantograph (TC03), neutral
      -- section (TC07), level crossing; the radio hole (TC12) waits
      Send_Track_Cond_IDs (((10, 3), (20, 7), (30, 38), (40, 12)));
      Step;
      Check (TC_Slot_Of (10) = 1 and then TC_Slot_Of (20) = 2
             and then TC_Slot_Of (30) = 3,
             "track conditions fill B3, B4, B5 from the left");
      Check (TC_Slot_Of (40) = 0, "the fourth object waits");
      Check_Frame ("tc_fourth_waits");

      -- the neutral section ends: B4 is free and goes to the radio
      -- hole; the level crossing stays in B5
      Send_Track_Cond_IDs (((10, 3), (30, 38), (40, 12)));
      Step;
      Check (TC_Slot_Of (10) = 1 and then TC_Slot_Of (30) = 3,
             "displayed objects keep their area");
      Check (TC_Slot_Of (40) = 2, "the waiting object takes the freed B4");
      Check_Frame ("tc_freed_b4_taken");

      -- the pantograph object ends and nothing waits: B3 stays empty,
      -- B4 and B5 do not shift to the left
      Send_Track_Cond_IDs (((30, 38), (40, 12)));
      Step;
      Check (TC_Slot_Of (40) = 2 and then TC_Slot_Of (30) = 3,
             "no shift into the free B3");
      Check_Frame ("tc_b3_free_no_shift");

      -- the next object takes the first free area from the left
      Send_Track_Cond_IDs (((30, 38), (40, 12), (50, 35)));
      Step;
      Check (TC_Slot_Of (50) = 1, "a new object takes the free B3");
      Check (TC_Slot_Of (40) = 2 and then TC_Slot_Of (30) = 3,
             "the others still keep their area");

      -- non stopping area announced (TC11) becoming the area itself
      -- (TC10) under one id: same object, same area, new symbol; the
      -- order in which the EVC lists the objects moves nothing
      Send_Track_Cond_IDs (((40, 10), (50, 35), (30, 38)));
      Step;
      Check (TC_Slot_Of (40) = 2 and then TC_Kind_Of (40) = 10,
             "a known id takes the new kind in its area");
      Check (TC_Slot_Of (50) = 1 and then TC_Slot_Of (30) = 3,
             "the order of the EVC list does not move objects");
      Check_Frame ("tc_kind_changed_in_place");

      -- two waiting objects are served in their order of arrival
      Send_Track_Cond_IDs
        (((40, 10), (50, 35), (30, 38), (60, 1), (70, 6)));
      Send_Track_Cond_IDs (((50, 35), (70, 6), (60, 1)));
      Step;
      Check (TC_Slot_Of (60) = 2 and then TC_Slot_Of (70) = 3
             and then TC_Slot_Of (50) = 1,
             "freed areas go to the waiting objects, oldest first");

      -- totality: repeated ids, unknown kinds and more objects than the
      -- store holds
      Send_Track_Cond_IDs
        (((1, 1), (1, 2), (2, 0), (3, 39), (4, 4), (5, 5), (6, 6), (7, 7),
          (8, 8), (9, 9), (10, 10), (11, 11), (12, 12)));
      Step;
      Check (DMI_Status.TC_Count in 3 .. DMI_Status.TC_List'Length,
             "track condition store is cut at its capacity");
      Check (TC_Slot_Of (1) = 1 and then TC_Slot_Of (4) = 2
             and then TC_Slot_Of (5) = 3,
             "the first three valid objects are displayed");
      Check (TC_Kind_Of (1) = 1, "a repeated id counts once");
      Check (TC_Slot_Of (2) = 99 and then TC_Slot_Of (3) = 99,
             "unknown kinds are ignored");
      Send_Raw (16#05#, (1 => 0));
      Step;
      Check (DMI_Status.TC_Count = 0, "an empty list ends all objects");
   end Scenario_TC_Areas_Kept;

   -- SDI-6 (8.2.3.2.2): no LE02 in C8 in the modes SN and NL
   procedure Scenario_Level_NTC_In_C8 is
   begin
      Reset;
      Send_Mode_Level (Mode => 8, Level => 3); -- SH, level NTC
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Step;
      Check_Frame ("level_ntc_sh_le02");

      Send_Mode_Level (Mode => 12, Level => 3); -- SN
      Step;
      Check_Frame ("level_ntc_sn_c8_empty");

      Send_Mode_Level (Mode => 14, Level => 3); -- NL
      Step;
      Check_Frame ("level_ntc_nl_c8_empty");

      -- the exception is for level NTC only
      Send_Mode_Level (Mode => 14, Level => 4); -- NL, L1
      Step;
      Check_Frame ("level_1_nl_le03");
   end Scenario_Level_NTC_In_C8;

   -- SDI-7 (8.2.3.2.8): once acknowledged, LE07 / LE09 give way to
   -- LE06 / LE08 although the EVC still announces "with acknowledgement"
   procedure Scenario_Level_Ann_Acknowledged is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Drain_Outbox;

      -- level NTC announced with acknowledgement: LE09, flashing frame
      Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 3,
                       Level_Ann_Ack => True);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "NTC announcement ack plays Sinfo");
      Check_Frame ("level_ann_ntc_ack");

      -- the driver acknowledges in C1: LE08 at once
      Pointer_Down (190, 340);
      Pointer_Up (190, 340);
      Step;
      Expect_Ack (0, 0, "level announcement acknowledged");
      Check (not DMI_Ack.Current_Valid, "acknowledged: nothing offered");
      Check_Frame ("level_ann_ntc_acked");

      -- the EVC repeats the announcement with the flag still set: no
      -- second request, LE08 stays (longer than the 1 s of 5.4.1.9)
      for I in 1 .. 30 loop
         Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 3,
                          Level_Ann_Ack => True);
         Step;
      end loop;
      Check (not DMI_Ack.Current_Valid,
             "repeated announcement is not offered again");
      Expect_No_Sound ("repeated announcement is silent");
      Check_Frame ("level_ann_ntc_acked");

      -- the same for level 0: LE07, then LE06
      Send_Mode_Level (Mode => 2, Level => 4);
      Step;
      Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 2,
                       Level_Ann_Ack => True);
      Step;
      Drain_Sounds;
      Check_Frame ("level_ann_l0_ack");
      Pointer_Down (190, 340);
      Pointer_Up (190, 340);
      Step;
      Check_Frame ("level_ann_l0_acked");

      -- 8.2.3.2.6: a mode acknowledgement in C1 hides the announcement
      for I in 1 .. 20 loop
         Step;
      end loop;
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6,
                       Level_Ann => 2, Level_Ann_Ack => True);
      Step;
      Drain_Sounds;
      Check_Frame ("level_ann_hidden_by_mode_ack");
   end Scenario_Level_Ann_Acknowledged;

   -- GEN-8 (5.1.1.3.2): a flashing frame starts visible, whenever it
   -- appears, and toggles every 0.25 s from then on
   procedure Scenario_Flash_Starts_Visible is
      procedure Offer_And_Check (Delay_Steps : Natural; What : String) is
      begin
         Reset;
         Send_Mode_Level (Mode => 2, Level => 4);
         Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                           V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                           D_Target => 0, Monitoring => 0, Dial_Range => 1,
                           Vrelease_Exists => False);
         -- the request arrives at any moment of the DMI's life
         for I in 1 .. Delay_Steps loop
            Step;
         end loop;
         Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6); -- OS
         Step;
         Drain_Sounds;
         Check (DMI_Flash.Frame_Visible, What & ": starts visible");
         Check_Frame ("flash_mode_ack_visible");
         for I in 1 .. 4 loop -- 50 .. 200 ms after the first picture
            Step;
            Check (DMI_Flash.Frame_Visible, What & ": visible for 0.25 s");
         end loop;
         Step; -- 250 ms
         Check (not DMI_Flash.Frame_Visible, What & ": then not visible");
         Check_Frame ("flash_mode_ack_hidden");
         for I in 1 .. 4 loop
            Step;
            Check (not DMI_Flash.Frame_Visible,
                   What & ": not visible for 0.25 s");
         end loop;
         Step; -- 500 ms
         Check (DMI_Flash.Frame_Visible, What & ": visible again");
         Check_Frame ("flash_mode_ack_visible");
      end Offer_And_Check;
   begin
      Offer_And_Check (0, "frame at start-up");
      Offer_And_Check (3, "frame after 150 ms");
      Offer_And_Check (7, "frame after 350 ms");

      -- the next request starts visible as well, whatever the phase of
      -- the one before was: text message after the mode acknowledgement
      Send_Text (31, "Level crossing not protected", Ack_Required => True,
                 Class => 0);
      for I in 1 .. 3 loop
         Step; -- the mode ack frame is 150 ms into its period
      end loop;
      Pointer_Down (190, 340);
      Pointer_Up (190, 340);
      Step;
      Check (not DMI_Ack.Current_Valid, "mode acknowledged");
      for I in 1 .. 20 loop
         Step; -- 5.4.1.9: 1 s
      end loop;
      Drain_Sounds;
      Check (DMI_Ack.Current_Valid, "text acknowledgement offered");
      Check (DMI_Flash.Frame_Visible, "text ack frame: starts visible");
      Check_Frame ("flash_text_ack_visible");
      for I in 1 .. 5 loop
         Step;
      end loop;
      Check (not DMI_Flash.Frame_Visible,
             "text ack frame: not visible after 0.25 s");
      Check_Frame ("flash_text_ack_hidden");

      -- any tick length is accepted; whole periods do not move the phase
      DMI_Core.Tick (Natural'Last - Natural'Last mod 500);
      Check (not DMI_Flash.Frame_Visible, "huge tick: phase kept");
   end Scenario_Flash_Starts_Visible;
   -- Planning area conformance (audit PLN-1 .. PLN-4)
   ---------------------------------------------------------------------

   procedure Scenario_PT_TTI_Steps is
      use type DMI_Status.Radio_T;
      function Name (N : Positive) return String is
         Img : constant String := Positive'Image (N);
      begin
         return "pt_tti_step_" & Img (Img'First + 1 .. Img'Last);
      end Name;
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 100, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Send_Status (TTI => 16#FFFF#);
      Step;
      Check (not DMI_Status.TTI_Displayed, "no TTI: nothing in A1");
      Expect_No_Sound ("no TTI, no Sinfo");
      Check_Frame ("pt_tti_none");

      --  a TTI of TdispTTI or more is not shown (Table 15a)
      Send_Status (TTI => 140, T_Disp_TTI => 14);
      Step;
      Check (not DMI_Status.TTI_Displayed, "TTI 14.0 s = TdispTTI: not shown");
      Expect_No_Sound ("TTI not shown, no Sinfo");
      Check_Frame ("pt_tti_none");

      --  the TTI counts down: step 1 first, the square grows
      for N in 1 .. 10 loop
         Send_Status (TTI => 14 * (11 - N) - 1, T_Disp_TTI => 14);
         Step;
         Check (DMI_Status.TTI_Displayed and then DMI_Status.TTI_Step = N,
                "TTI" & Natural'Image (14 * (11 - N) - 1)
                & " tenths: step" & Positive'Image (N));
         if N = 1 then
            --  8.2.2.5.7: Sinfo when the TTI appears, once
            Expect_Sound (DMI_Sounds.Sinfo, "the TTI appears: Sinfo");
         end if;
         Expect_No_Sound ("TTI step" & Positive'Image (N) & " plays nothing more");
         Check_Frame (Name (N));
         Send_Status (TTI => 14 * (10 - N), T_Disp_TTI => 14);
         Step;
         Check (DMI_Status.TTI_Step = N,
                "TTI" & Natural'Image (14 * (10 - N))
                & " tenths: step" & Positive'Image (N));
         Check_Frame (Name (N));
      end loop;

      --  the square of step n is n x 5 cells: 10 is the whole 50 x 50
      Check (DMI_Status.TTI_Step = 10, "TTI 0: the full white square");

      --  a MSG_STATUS of the earlier layout (22 bytes, tti u8 in whole
      --  seconds) is ignored as a whole
      Send_Status (TTI => 70, T_Disp_TTI => 14); -- step 10 - 5 = 5
      Step;
      Check (DMI_Status.TTI_Step = 5, "TTI 7.0 s: step 5");
      Send_Raw (16#07#, (0, 1, 0, 0, 0, 0, 16#FF#, 16#FF#, 1, 14, 0,
                         0, 0, 0, 0, 16#FF#, 16#FF#, 16#FF#, 16#FF#,
                         12, 0, 0));
      Step;
      Check (DMI_Status.TTI_Step = 5, "a 22 byte MSG_STATUS is ignored");
      Check (DMI_Status.Radio = DMI_Status.No_Connection,
             "... none of its fields is taken");
      Check_Frame (Name (5));

      --  TdispTTI 10 s: one step a second; 0 keeps the TdispTTI known
      Send_Status (TTI => 55, T_Disp_TTI => 10);
      Step;
      Check (DMI_Status.TTI_Step = 5, "TdispTTI 10 s, TTI 5.5 s: step 5");
      Send_Status (TTI => 60, T_Disp_TTI => 0);
      Step;
      Check (DMI_Status.T_Disp_TTI = 10 and then DMI_Status.TTI_Step = 4,
             "t_disp_tti 0 keeps TdispTTI 10 s: TTI 6.0 s, step 4");
      Check_Frame (Name (4));
      Send_Status (TTI => 99, T_Disp_TTI => 10);
      Step;
      Check (DMI_Status.TTI_Step = 1, "TdispTTI 10 s, TTI 9.9 s: step 1");
      Send_Status (TTI => 100, T_Disp_TTI => 10);
      Step;
      Check (not DMI_Status.TTI_Displayed, "TdispTTI 10 s, TTI 10.0 s: gone");

      --  the extremes of the fields
      Send_Status (TTI => 2549, T_Disp_TTI => 255);
      Step;
      Check (DMI_Status.TTI_Displayed and then DMI_Status.TTI_Step = 1,
             "TdispTTI 255 s, TTI 254.9 s: step 1");
      Send_Status (TTI => 65534, T_Disp_TTI => 255);
      Step;
      Check (not DMI_Status.TTI_Displayed, "TTI 6553.4 s: not shown");
      Send_Status (TTI => 0, T_Disp_TTI => 1);
      Step;
      Check (DMI_Status.TTI_Step = 10, "TdispTTI 1 s, TTI 0: step 10");
      Send_Status (TTI => 9, T_Disp_TTI => 1);
      Step;
      Check (DMI_Status.TTI_Step = 1, "TdispTTI 1 s, TTI 0.9 s: step 1");
      Check_Frame (Name (1));
   end Scenario_PT_TTI_Steps;

   ---------------------------------------------------------------------
   -- P4 item 25: the pixel geometry of the speed dial (8.2.1). Every
   -- frame puts the pointer, a hook or a band at a chosen speed, most of
   -- them at 0 degrees (90, 70, 125 and 150 km/h on the four dials) where
   -- the cells can be counted: the CSG is 9 cells wide (8.2.1.4.6), the
   -- hook 6 x 20 (8.2.1.4.7) and the Basic Speed Hook 10 x 20 cells
   -- (8.2.1.5.4), the indicator lines 15 and 25 cells long (8.2.1.1.6,
   -- 8.2.1.1.7), the release speed 5 + 1 + 3 cells (8.2.1.6.4), the
   -- circular part of the pointer 50 cells across (Figure 34), the set
   -- speed 10 cells (8.2.3.9) and the digits of the current speed right
   -- aligned in three sub areas of B1 (8.2.1.3.3, 8.2.1.3.4) with one,
   -- two and three digits in every colour of the pointer (8.2.1.3.5).
   ---------------------------------------------------------------------

   procedure Scenario_Px_Speed_Dial is
      procedure Frame (Name       : String;
                       Mode       : Natural;
                       V_Cur, V_Perm, V_Target, V_Release : Natural;
                       V_Sbi, V_Wsl : Natural;
                       Monitoring : Natural;
                       Dial_Range : Natural;
                       Release    : Boolean := False;
                       Target_Info : Boolean := False;
                       Set_Speed  : Natural := 16#FFFF#) is
      begin
         Reset;
         Send_Mode_Level (Mode => Mode, Level => 4);
         Send_Status (Set_Speed => Set_Speed);
         Send_Speed_State (V_Cur => V_Cur, V_Perm => V_Perm,
                           V_Target => V_Target, V_Release => V_Release,
                           V_Sbi => V_Sbi, V_Wsl => V_Wsl,
                           D_Target => (if Monitoring = 0 then 0 else 500),
                           Monitoring => Monitoring,
                           Dial_Range => Dial_Range,
                           Vrelease_Exists => Release,
                           CSM_Target_Info => Target_Info);
         Drain_Sounds;
         Step;
         Check_Frame (Name);
      end Frame;
   begin
      -- 140 km/h dial, FS CSM NoS: the hook at 70 km/h (0 degrees), one
      -- grey digit
      Frame ("px_dial_140_nos", Mode => 2,
             V_Cur => 7, V_Perm => 70, V_Target => 0, V_Release => 0,
             V_Sbi => 85, V_Wsl => 75, Monitoring => 0, Dial_Range => 0);
      -- 180 km/h dial, FS CSM OvS: the hook at 90 km/h (0 degrees), the
      -- orange band 20 cells wide up to VSBI (8.2.1.4.8), two digits, the
      -- set speed at 90 km/h
      Frame ("px_dial_180_ovs", Mode => 2,
             V_Cur => 95, V_Perm => 90, V_Target => 0, V_Release => 0,
             V_Sbi => 110, V_Wsl => 100, Monitoring => 0, Dial_Range => 1,
             Set_Speed => 90);
      -- 250 km/h dial, FS CSM IntS: the hook at 125 km/h (0 degrees), the
      -- red band, white digits (8.2.1.3.5), a narrow 1 and two 7s
      Frame ("px_dial_250_ints", Mode => 2,
             V_Cur => 177, V_Perm => 125, V_Target => 0, V_Release => 0,
             V_Sbi => 135, V_Wsl => 130, Monitoring => 0, Dial_Range => 2);
      -- 400 km/h dial, FS TSM IndS: the hook at 150 km/h (0 degrees),
      -- dark grey up to Vtarget, three yellow digits
      Frame ("px_dial_400_tsm", Mode => 2,
             V_Cur => 120, V_Perm => 150, V_Target => 100, V_Release => 0,
             V_Sbi => 165, V_Wsl => 160, Monitoring => 1, Dial_Range => 3);
      -- CSM with target information (Table 9): dark grey to Vtarget, white
      -- to the hook at 90 km/h, white pointer
      Frame ("px_csm_target_white", Mode => 2,
             V_Cur => 77, V_Perm => 90, V_Target => 60, V_Release => 0,
             V_Sbi => 105, V_Wsl => 95, Monitoring => 0, Dial_Range => 1,
             Target_Info => True);
      -- the hook at both ends of the scale: at 0 km/h over the lowermost
      -- part (8.2.1.4.5), and at the maximum of the dial
      Frame ("px_csg_hook_zero", Mode => 2,
             V_Cur => 0, V_Perm => 0, V_Target => 0, V_Release => 0,
             V_Sbi => 10, V_Wsl => 5, Monitoring => 0, Dial_Range => 0);
      Frame ("px_csg_hook_max", Mode => 2,
             V_Cur => 180, V_Perm => 180, V_Target => 0, V_Release => 0,
             V_Sbi => 190, V_Wsl => 185, Monitoring => 0, Dial_Range => 1);
      -- the release speed as in Figure 47 (Vperm > Vrelease, TSM) and in
      -- Figure 48 (Vperm < Vrelease, RSM), on the 400 km/h dial like the
      -- figures; in CSM Table 9 shows no release speed
      Frame ("px_release_perm_above", Mode => 2,
             V_Cur => 28, V_Perm => 48, V_Target => 0, V_Release => 25,
             V_Sbi => 60, V_Wsl => 55, Monitoring => 1, Dial_Range => 3,
             Release => True);
      Frame ("px_release_perm_below", Mode => 2,
             V_Cur => 19, V_Perm => 12, V_Target => 0, V_Release => 25,
             V_Sbi => 30, V_Wsl => 28, Monitoring => 2, Dial_Range => 3,
             Release => True);
      Frame ("px_release_csm", Mode => 2,
             V_Cur => 28, V_Perm => 48, V_Target => 0, V_Release => 25,
             V_Sbi => 60, V_Wsl => 55, Monitoring => 0, Dial_Range => 3,
             Release => True);
      -- Basic Speed Hooks in SM (Table 10): at 90 km/h (0 degrees) and at
      -- 0 km/h, then overlapping (8.2.1.5.6) near the end of the 400 dial
      Frame ("px_hooks_sm", Mode => 4,
             V_Cur => 5, V_Perm => 90, V_Target => 0, V_Release => 0,
             V_Sbi => 105, V_Wsl => 95, Monitoring => 1, Dial_Range => 1);
      Frame ("px_hooks_sm_overlap", Mode => 4,
             V_Cur => 300, V_Perm => 392, V_Target => 388, V_Release => 0,
             V_Sbi => 400, V_Wsl => 396, Monitoring => 1, Dial_Range => 3);
   end Scenario_Px_Speed_Dial;

   ---------------------------------------------------------------------
   -- P4 pixel work (pf_): the cells of 8.2.2.1 (Table 12), 8.2.3.3.14,
   -- 5.3.2.5.5 a, 8.1.1.4 b and the border corners of Figures 50 / 60,
   -- checked cell by cell and pinned by goldens
   ---------------------------------------------------------------------


end DMI_Test_Supervision;
