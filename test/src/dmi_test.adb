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

pragma Ada_2012;
with Ada.Command_Line;
with Ada.Streams;
with DMI_Core;
with Display.A_Area;
with Display.B_Area;
with Display.Screen.Files;
with DMI_Driver_Data;
with DMI_Protocol;
with DMI_Sounds;
with EVC_Core;
with EVC_Driver;
with EVC_Track;
with EVC_Train;
with General_Parameters;
with Interfaces;
with Supplementary_Driving_Info;
with Test_Support; use Test_Support;
with User_Settings;

procedure DMI_Test is

   -- Fixed flash phase for deterministic frames
   procedure Reset is
   begin
      DMI_Core.Initialise;
      General_Parameters.Flash_On := True;
      -- scenarios send EVC messages only when the picture changes
      General_Parameters.EVC_Link_Timeout_Ms := 0;
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

   -- ROB-3 / ROB-4: mode (MSG_MODE_LEVEL), monitoring and speeds
   -- (MSG_SPEED_STATE) and the set speed / TTI (MSG_STATUS) arrive in
   -- separate messages and every field is EVC controlled, so every
   -- combination, in any order, has to render without raising; this
   -- includes the ones Tables 8 to 11, 13 and 14 mark "not applicable"
   -- (8.2.1.2.5, 8.2.1.4.9, 8.2.1.5.7, 8.2.1.6.5, 8.2.2.1.8, 8.2.2.2.7)
   -- and values beyond the dial (8.2.1.1.3) and the bar (8.2.2.1.6).
   -- An exception ends the run: there is no handler, as on the target.
   procedure Scenario_Speed_Robustness is
      use Interfaces;

      Dial_Max : constant array (Unsigned_8 range 0 .. 3) of Unsigned_16 :=
        (140, 180, 250, 400);

      Distances : constant array (0 .. 5) of Unsigned_32 :=
        (0, 1, 1000, 90000, 90001, 16#FFFF_FFFF#);

      type Speed_Set is array (1 .. 8) of Unsigned_16;

      function Boundary_Speeds (Max : Unsigned_16) return Speed_Set is
        (0, 1, Max - 1, Max, Max + 1, 400, 401, 65535);

      -- Limit patterns 1 .. 8 put every limit at the same boundary speed,
      -- 9 .. 11 mix them so that every supervision status occurs
      Patterns : constant := 11;

      -- The current speed and the limits meet only in the supervision
      -- status, so the uniform patterns run with the current speed at the
      -- limit (normal or indication) and at the next boundary speed
      -- (intervention, or far below for the last), the mixed ones with all
      function Paired (V_Index, Pattern : Positive) return Boolean is
        (Pattern > 8
         or else V_Index = Pattern
         or else V_Index = Pattern mod 8 + 1);

      Renders : Natural := 0;
      Cycle   : Natural := 0;

      -- Areas A and B hold everything drawn from these fields; the other
      -- areas cost more than half of a full render, so they are rendered
      -- once per outer combination only (Full)
      procedure Render (Full : Boolean := False) is
      begin
         if Full then
            Step;
         else
            DMI_Core.Tick (50);
            Display.B_Area.Draw;
            Display.A_Area.Draw;
         end if;
         Renders := Renders + 1;
      end Render;

      procedure Send_Speeds (V_Cur      : Unsigned_16;
                             Pattern    : Positive;
                             Max        : Unsigned_16;
                             Monitoring : Unsigned_8;
                             Dial       : Unsigned_8;
                             Flags      : Unsigned_8)
      is
         S : constant Speed_Set := Boundary_Speeds (Max);
         -- the distance is independent of the speeds: cycle through it
         D : constant Unsigned_32 := Distances (Cycle mod Distances'Length);
      begin
         Cycle := Cycle + 1;
         case Pattern is
            when 1 .. 8 =>
               Send_Speed_State_Raw
                 (V_Cur => V_Cur, V_Perm => S (Pattern),
                  V_Target => S (Pattern), V_Release => S (Pattern),
                  V_Sbi => S (Pattern), V_Wsl => S (Pattern),
                  D_Target => D, Monitoring => Monitoring,
                  Dial_Range => Dial, Flags => Flags);
            when 9 =>
               -- ordered limits straddling the end of the dial
               Send_Speed_State_Raw
                 (V_Cur => V_Cur, V_Perm => Max - 1, V_Target => Max / 2,
                  V_Release => Max / 4, V_Sbi => 401, V_Wsl => Max + 1,
                  D_Target => D, Monitoring => Monitoring,
                  Dial_Range => Dial, Flags => Flags);
            when 10 =>
               -- limits in reverse order
               Send_Speed_State_Raw
                 (V_Cur => V_Cur, V_Perm => Max + 1, V_Target => 65535,
                  V_Release => 65535, V_Sbi => 1, V_Wsl => Max,
                  D_Target => D, Monitoring => Monitoring,
                  Dial_Range => Dial, Flags => Flags);
            when others =>
               Send_Speed_State_Raw
                 (V_Cur => V_Cur, V_Perm => 0, V_Target => 0,
                  V_Release => 1, V_Sbi => 65535, V_Wsl => 400,
                  D_Target => D, Monitoring => Monitoring,
                  Dial_Range => Dial, Flags => Flags);
         end case;
      end Send_Speeds;

      procedure Send_Mode (Mode : Natural; LSSMA : Natural; Toggle : Boolean) is
      begin
         -- 18 stands for an undefined mode code
         Send_Mode_Level (Mode  => (if Mode = 18 then 255 else Mode),
                          Level => 4, LSSMA => LSSMA);
         -- OS/SR/SH draw their objects only when toggled on (8.2.2.4.5
         -- toggles them off on entry)
         User_Settings.Speed_Info_Visible := Toggle;
      end Send_Mode;

      LSSMAs : constant array (0 .. 4) of Natural := (0, 1, 400, 401, 65534);

      -- The modes that draw from the speed data: FS and AD the CSG
      -- (Table 9), SM/OS/SR/SH/RV the hooks (Table 10), LS the LSSMA.
      -- The other modes get a rotating selection of the limit patterns.
      function Draws_Limits (Mode : Natural) return Boolean is
        (Mode in 2 .. 8 | 10);
   begin
      Reset;

      -- Order 1: the mode is known, the speed states arrive under it.
      -- mode x monitoring x dial x flag extremes x current speed x limits
      for Mode in 0 .. 17 loop
         for Flags in Unsigned_8 range 0 .. 1 loop
            Send_Mode (Mode, LSSMAs ((Mode + Natural (Flags)) mod 5),
                       Toggle => Flags /= 0);
            Render (Full => True);
            for Monitoring in Unsigned_8 range 0 .. 2 loop
               for Dial in Dial_Max'Range loop
                  for V in Speed_Set'Range loop
                     for Pattern in 1 .. Patterns loop
                        if (if Draws_Limits (Mode) then Paired (V, Pattern)
                            else Pattern = 1 + Cycle mod Patterns)
                        then
                           Send_Speeds
                             (Boundary_Speeds (Dial_Max (Dial)) (V), Pattern,
                              Dial_Max (Dial), Monitoring, Dial,
                              Flags * 16#FF#);
                           Render;
                        end if;
                     end loop;
                  end loop;
                  Render (Full => True);
               end loop;
            end loop;
         end loop;
      end loop;

      -- Order 2: speed states and modes alternate, a render after each
      -- message, so every mode also arrives under a speed state that was
      -- sent for another mode. 19 mode codes against 40 speed states keep the
      -- pairs rotating. Monitoring 255 and dial 252 are undefined codes.
      Cycle := 0;
      for Flags in Unsigned_8 range 0 .. 1 loop
         for Monitoring in Unsigned_8 range 0 .. 3 loop
            for Dial in Unsigned_8 range 0 .. 4 loop
               for V in Speed_Set'Range loop
                  for Pattern in 1 .. Patterns loop
                     if Paired (V, Pattern) then
                        Send_Speeds
                          (Boundary_Speeds (Dial_Max (Dial mod 4)) (V),
                           Pattern, Dial_Max (Dial mod 4),
                           Monitoring * 85, Dial * 63, Flags * 16#FF#);
                        Render;
                        Send_Mode (Cycle mod 19, 65535, Toggle => Flags /= 0);
                        Render;
                     end if;
                  end loop;
               end loop;
               Render (Full => True);
            end loop;
         end loop;
      end loop;

      -- MSG_STATUS: a set speed (8.2.3.9) beyond every dial, and the TTI
      -- (8.2.2.5) in every relation to TdispTTI, in the modes of Table 15a
      -- and one without, before and after the speed state
      for Dial in Dial_Max'Range loop
         for Set_Speed of Boundary_Speeds (Dial_Max (Dial)) loop
            for TTI in 0 .. 5 loop
               Send_Status
                 (Set_Speed  => Natural (Set_Speed),
                  TTI        => (case TTI is
                                    when 0 => 0, when 1 => 1, when 2 => 13,
                                    when 3 => 14, when 4 => 254,
                                    when others => 255),
                  T_Disp_TTI => (case TTI mod 3 is
                                    when 0 => 0, when 1 => 14,
                                    when others => 255));
               Render;
               for Mode in 1 .. 7 loop
                  Send_Mode (Mode, 65535, Toggle => True);
                  Send_Speeds (400, 9, Dial_Max (Dial), 0, Dial, 2);
                  Render (Full => Mode = 2);
               end loop;
            end loop;
         end loop;
      end loop;

      Check (Renders > 0, "speed robustness sweep completed");

      -- Representative pictures of the decisions above
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS, L1
      -- 140 km/h dial, 150 km/h under a permitted speed of 160 km/h:
      -- pointer, CSG and hook rest at the end of the scale (8.2.1.1.4),
      -- the digital speed shows 150
      Send_Speed_State_Raw
        (V_Cur => 150, V_Perm => 160, V_Target => 0, V_Release => 0,
         V_Sbi => 175, V_Wsl => 165, D_Target => 0, Monitoring => 0,
         Dial_Range => 0, Flags => 0);
      Step;
      Check_Frame ("rob_fs_above_dial_140");

      -- distance beyond the 5 digits of 8.2.2.2.4: 99990, bar at 1000 m
      -- (8.2.2.1.6); the speeds beyond every dial are clamped to 400
      Send_Speed_State_Raw
        (V_Cur => 65535, V_Perm => 65535, V_Target => 300, V_Release => 0,
         V_Sbi => 65535, V_Wsl => 65535, D_Target => 16#FFFF_FFFF#,
         Monitoring => 1, Dial_Range => 3, Flags => 0);
      Step;
      Check_Frame ("rob_fs_tsm_wire_maximum");

      -- SR in RSM: no row in Tables 8, 10 and 14, so no pointer, no hooks
      -- and no distance, although everything is toggled on
      Send_Mode_Level (Mode => 7, Level => 4); -- SR
      User_Settings.Speed_Info_Visible := True;
      Send_Speed_State_Raw
        (V_Cur => 30, V_Perm => 40, V_Target => 0, V_Release => 35,
         V_Sbi => 55, V_Wsl => 45, D_Target => 150, Monitoring => 2,
         Dial_Range => 1, Flags => 1);
      Step;
      Check_Frame ("rob_sr_rsm_not_applicable");

      -- AD with IntS: hyphens only in Tables 8 and 9, no pointer, no CSG
      Send_Mode_Level (Mode => 3, Level => 5); -- AD, L2
      Send_Speed_State_Raw
        (V_Cur => 140, V_Perm => 120, V_Target => 0, V_Release => 0,
         V_Sbi => 135, V_Wsl => 125, D_Target => 0, Monitoring => 0,
         Dial_Range => 1, Flags => 0);
      Step;
      Check_Frame ("rob_ad_csm_ints_not_applicable");
   end Scenario_Speed_Robustness;

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
      Send_Status (TTI => 10, T_Disp_TTI => 14);
      Expect_Sound (DMI_Sounds.Sinfo, "TTI display plays Sinfo");
      Step;
      Check_Frame ("tti_10s");
      Send_Status (TTI => 2, T_Disp_TTI => 14);
      Drain_Sounds;
      Step;
      Check_Frame ("tti_2s");
   end Scenario_TTI;

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

   procedure Scenario_Text_Messages is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      -- second group message: silent
      Send_Text (1, "Entering FS", HH => 10, MM => 5);
      Expect_No_Sound ("second group message is silent");
      -- first group message: Sinfo, displayed above the older one
      Send_Text (2, "Balise read error", First_Group => True,
                 Class => 2, HH => 10, MM => 6);
      Expect_Sound (DMI_Sounds.Sinfo, "first group message plays Sinfo");
      Step;
      Check_Frame ("messages_two");

      -- fill beyond five lines and scroll
      Send_Text (3, "Communication error", First_Group => True,
                 Class => 2, HH => 10, MM => 7);
      Send_Text (4, "Trackside malfunction", First_Group => True,
                 Class => 2, HH => 10, MM => 8);
      Send_Text (5, "Runaway movement", First_Group => True,
                 Class => 2, HH => 10, MM => 9);
      Send_Text (6, "No track description", First_Group => True,
                 Class => 2, HH => 10, MM => 10);
      Drain_Sounds;
      Step;
      Check_Frame ("messages_full");
      Pointer_Down (610, 380); Pointer_Up (610, 380); -- E11 scroll down
      Drain_Sounds;
      Step;
      Check_Frame ("messages_scrolled");

      -- acknowledgeable trackside message: presented alone with frame
      Send_Text (7, "Level crossing not protected", Ack_Required => True,
                 Class => 0, HH => 10, MM => 11);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "text ack offer plays Sinfo");
      Check_Frame ("message_ack");
      Pointer_Down (150, 400); -- inside E5-E9
      Expect_Sound (DMI_Sounds.Click, "text ack press clicks");
      Pointer_Up (150, 400);
      Step;
      Check_Frame ("message_acked");
      Send_Text_Remove (7);
      Send_Text_Remove (1);
      Drain_Sounds;
      Step;
      Check_Frame ("messages_removed");
   end Scenario_Text_Messages;

   ---------------------------------------------------------------------
   -- Planning area (8.3)
   ---------------------------------------------------------------------

   procedure Scenario_Planning is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 100, V_Perm => 140, V_Target => 0,
                        V_Release => 0, V_Sbi => 155, V_Wsl => 145,
                        D_Target => 2500, Monitoring => 0, Dial_Range => 2,
                        Vrelease_Exists => False);
      -- MA 2.5 km, indication at 1.2 km, gradients, two speed drops and
      -- a zero speed target, pantograph + neutral section announcements
      Send_Planning
        (MA_Dist    => 2500,
         Ceiling    => 140,
         Indication => 1200,
         Gradients  => (0, 12, 800, -5, 1800, 0),
         Speeds     => (1000, 70, 0,  1700, 40, 0,  2500, 0, 1),
         Orders     => (2, 600,  5, 1500));
      Drain_Sounds;
      Step;
      Check_Frame ("planning_fs");

      -- zoom out to 0-8000 and back in twice to 0-2000
      Pointer_Down (350, 20); Pointer_Up (350, 20);   -- D12 scale down
      Drain_Sounds;
      Step;
      Check_Frame ("planning_8000");
      Pointer_Down (350, 300); Pointer_Up (350, 300); -- D9 scale up
      Pointer_Down (350, 300); Pointer_Up (350, 300);
      Drain_Sounds;
      Step;
      Check_Frame ("planning_2000");

      -- AD mode: indication marker and PL37 in white
      Send_Mode_Level (Mode => 3, Level => 4);
      Drain_Sounds;
      Step;
      Check_Frame ("planning_ad");

      -- OS mode: hidden until toggled on (8.3.1.1 c)
      Send_Mode_Level (Mode => 6, Level => 4);
      Drain_Sounds;
      Step;
      Check_Frame ("planning_os_off");
      Pointer_Down (150, 150); Pointer_Up (150, 150); -- A/B toggle
      Drain_Sounds;
      Step;
      Check_Frame ("planning_os_on");
   end Scenario_Planning;

   ---------------------------------------------------------------------
   -- Windows and the start-up dialogue sequence (10, 11.7.2)
   ---------------------------------------------------------------------

   procedure Press (X, Y : Natural) is
   begin
      Pointer_Down (X, Y);
      Pointer_Up (X, Y);
      -- process the activation so consecutive presses see the updated
      -- window state
      Step;
      Drain_Sounds;
   end Press;

   procedure Scenario_Startup_Sequence is
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 0); -- SB, level unknown
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      Press (610, 40);        -- F1: Main window
      Step;
      Check_Frame ("main_window");

      Press (410, 90);        -- Start: no data yet -> sequence begins
      Step;
      Check_Frame ("startup_driver_id");

      Press (385, 240);       -- 1
      Press (487, 240);       -- 2
      Press (589, 240);       -- 3
      Step;
      Check_Frame ("startup_driver_id_123");
      Press (589, 390);       -- Enter -> Level window
      Step;
      Check_Frame ("startup_level");

      Press (410, 90);        -- Level 1 -> Train data window
      Step;
      Check_Frame ("startup_train_data");

      -- length 400
      Press (385, 290); Press (487, 390); Press (487, 390);
      Press (589, 390);       -- Enter -> next field
      -- brake percentage 135
      Press (385, 240); Press (589, 240); Press (487, 290);
      Press (589, 390);
      -- max speed 140
      Press (385, 240); Press (385, 290); Press (487, 390);
      Step;
      Check_Frame ("startup_train_data_filled");
      Press (589, 390);       -- Enter -> validation window
      Step;
      Check_Frame ("startup_validation");

      Press (410, 390);       -- Yes -> TRN window
      Step;
      Check_Frame ("startup_trn");

      -- TRN 4711
      Press (385, 290); Press (385, 340); Press (385, 240); Press (385, 240);
      Press (589, 390);       -- Enter -> sequence completes
      Step;
      Check_Frame ("startup_done");

      Check (DMI_Driver_Data.Driver_ID_Entered, "driver id entered");
      Check (DMI_Driver_Data.Level_Entered, "level entered");
      Check (DMI_Driver_Data.Train_Data_Entered, "train data validated");
      Check (DMI_Driver_Data.TRN_Entered, "TRN entered");
      Check (DMI_Driver_Data.Train_Length = 400, "train length 400");
      Check (DMI_Driver_Data.Brake_Pct = 135, "brake percentage 135");
      Check (DMI_Driver_Data.Max_Speed = 140, "max speed 140");
   end Scenario_Startup_Sequence;

   procedure Scenario_Other_Windows is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      Press (610, 90);        -- F2: Override window
      Step;
      Check_Frame ("override_window");
      Press (410, 90);        -- EOA -> closes
      Step;
      Check_Frame ("default_after_override");

      Press (610, 190);       -- F4: Special window
      Step;
      Check_Frame ("special_window");
      Press (410, 90);        -- Adhesion
      Step;
      Check_Frame ("adhesion_window");
      Press (563, 90);        -- Slippery rail -> closes to Special
      Step;
      Check_Frame ("special_window");

      Press (370, 440);       -- close Special
      Press (610, 240);       -- F5: Settings
      Step;
      Check_Frame ("settings_window");
      Press (563, 90);        -- Volume
      Step;
      Check_Frame ("volume_window");
      Press (563, 90);        -- '+' -> volume 6
      Step;
      Check_Frame ("volume_plus");
      Press (370, 440);       -- close Volume
      Press (370, 440);       -- close Settings

      Press (610, 140);       -- F3: Data view
      Step;
      Check_Frame ("data_view_window");
   end Scenario_Other_Windows;

   ---------------------------------------------------------------------
   -- EVC link supervision: silence of the EVC beyond the timeout shows
   -- mode SF with the EVC provided picture discarded; the next message
   -- restores normal operation (General_Parameters.EVC_Link_Timeout_Ms)
   ---------------------------------------------------------------------

   procedure Scenario_EVC_Link_Lost is
      Timeout_Ms       : constant Positive := 1000;
      Steps_To_Timeout : constant Positive := Timeout_Ms / 50;

      procedure Send_FS_Picture is
      begin
         Send_Mode_Level (Mode => 2, Level => 4); -- FS, L1
         Send_Speed_State (V_Cur => 100, V_Perm => 120, V_Target => 0,
                           V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                           D_Target => 0, Monitoring => 0, Dial_Range => 1,
                           Vrelease_Exists => False);
         Drain_Sounds;
         Step;
      end Send_FS_Picture;
   begin
      Reset;
      General_Parameters.EVC_Link_Timeout_Ms := Timeout_Ms;
      -- before the EVC has ever spoken nothing is supervised
      for I in 1 .. Steps_To_Timeout + 1 loop
         Step;
      end loop;
      Check (not DMI_Core.EVC_Link_Lost, "no supervision before the EVC talks");

      Send_FS_Picture;
      Check (not DMI_Core.EVC_Link_Lost, "link up while the EVC talks");
      declare
         Picture : constant String := Display.Screen.Files.Digest;
      begin
         -- silence just short of the timeout keeps the picture
         for I in 1 .. Steps_To_Timeout - 2 loop
            Step;
         end loop;
         Check (not DMI_Core.EVC_Link_Lost, "link up before the timeout");
         Check (Display.Screen.Files.Digest = Picture,
                "picture kept before the timeout");

         Step; -- crosses the timeout
         Check (DMI_Core.EVC_Link_Lost, "link lost after the timeout");
         Check_Frame ("evc_link_lost");

         -- the EVC comes back: normal presentation resumes
         Send_FS_Picture;
         Check (not DMI_Core.EVC_Link_Lost, "link recovered");
         Check (Display.Screen.Files.Digest = Picture,
                "picture restored after recovery");
      end;
   end Scenario_EVC_Link_Lost;

   ---------------------------------------------------------------------
   -- Full mission with the in-process EVC simulator: SB start -> FS
   -- cruise -> TSM braking curve -> level transition ack -> track
   -- conditions -> RSM -> stop at the EOA
   ---------------------------------------------------------------------

   procedure Scenario_Mission is
      use type Supplementary_Driving_Info.Level_T;

      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

      procedure Sim_Step is
      begin
         EVC_Driver.Auto_Drive;
         EVC_Core.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
      end Sim_Step;

      -- run until Condition or the step budget runs out
      generic
         with function Done return Boolean;
      procedure Run_Until (What : String; Max_Steps : Natural);

      procedure Run_Until (What : String; Max_Steps : Natural) is
      begin
         for I in 1 .. Max_Steps loop
            Sim_Step;
            if Done then
               return;
            end if;
         end loop;
         Check (False, "timeout waiting for " & What);
      end Run_Until;

      function In_TSM return Boolean is (EVC_Core.Monitoring = 1);
      function In_RSM return Boolean is (EVC_Core.Monitoring = 2);
      function Stopped return Boolean is
        (EVC_Train.Speed_KMH = 0 and then EVC_Train.Position_M > 9_000.0);
      function Past_LX return Boolean is
        (EVC_Train.Position_M > 5_600.0);

      procedure Wait_TSM is new Run_Until (In_TSM);
      procedure Wait_RSM is new Run_Until (In_RSM);
      procedure Wait_Stop is new Run_Until (Stopped);
      procedure Wait_LX is new Run_Until (Past_LX);
   begin
      Reset;
      EVC_Core.Reset;

      -- a few idle steps in SB
      for I in 1 .. 5 loop
         Sim_Step;
      end loop;
      DMI_Core.Render;
      Check_Frame ("mission_sb");

      -- mission start (the EVC grants FS with a full MA)
      EVC_Core.Handle_Driver_Action (5, 0);
      Sim_Step;
      Expect_Sound (DMI_Sounds.Sinfo, "mission start text plays Sinfo");
      Drain_Sounds;

      Wait_TSM ("TSM entry", 2_000);
      Expect_Sound (DMI_Sounds.Sinfo, "TSM entry plays Sinfo");
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("mission_tsm");

      Wait_LX ("passing the level crossing", 3_000);
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("mission_after_lx");
      Check (Supplementary_Driving_Info.Level =
               Supplementary_Driving_Info.L2,
             "level transition to L2 executed");

      Wait_RSM ("RSM entry", 8_000);
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("mission_rsm");

      Wait_Stop ("standstill at the EOA", 4_000);
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("mission_stopped");
      Check (EVC_Train.Position_M < Float (EVC_Track.EOA_M),
             "train stopped before the EOA");
   end Scenario_Mission;

   Status : Natural;
begin
   Scenario_FS_CSM;
   Scenario_FS_TSM;
   Scenario_Speed_Robustness;
   Scenario_AD_White;
   Scenario_CSM_Target_Info;
   Scenario_Mode_Ack;
   Scenario_Level_Announcement;
   Scenario_Windows;
   Scenario_Speed_Toggle;
   Scenario_Status_Objects;
   Scenario_TTI;
   Scenario_SM_Direction;
   Scenario_Text_Messages;
   Scenario_Planning;
   Scenario_Startup_Sequence;
   Scenario_Other_Windows;
   Scenario_EVC_Link_Lost;
   Scenario_Mission;

   Status := Summary;
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Exit_Status (Status));
end DMI_Test;
