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
with DMI_Ack;
with DMI_Buttons;
with DMI_Core;
with DMI_Data_Format;
with Display.A_Area;
with Display.B_Area;
with Display.Draw;
with Display.Screen.Files;
with DMI_Data_Entry;
with DMI_Driver_Data;
with DMI_Flash;
with DMI_Planning;
with DMI_Protocol;
with DMI_Sounds;
with DMI_Status;
with DMI_Text_Messages;
with DMI_Train_Data;
with DMI_Windows;
with EVC_Core;
with EVC_Driver;
with EVC_Track;
with EVC_Train;
with General_Parameters;
with Interfaces;
with Speed_And_Distance;
with Supplementary_Driving_Info;
with Test_Support; use Test_Support;
with User_Settings;

procedure DMI_Test is

   procedure Reset is
   begin
      DMI_Core.Initialise;
      Test_Support.Reset_EVC_Model;
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

      -- AD with IntS: hyphens only in Tables 8 and 9. No CSG; the pointer
      -- stays, grey, so that the driver keeps the current speed during a
      -- brake intervention (implementation choice, see Draw_Speed_Pointer)
      Send_Mode_Level (Mode => 3, Level => 5); -- AD, L2
      Send_Speed_State_Raw
        (V_Cur => 140, V_Perm => 120, V_Target => 0, V_Release => 0,
         V_Sbi => 135, V_Wsl => 125, D_Target => 0, Monitoring => 0,
         Dial_Range => 1, Flags => 0, Status => 4);
      Step;
      Check_Frame ("rob_ad_csm_ints_grey_pointer");
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
      Send_Status (TTI => 10, T_Disp_TTI => 14);
      Expect_Sound (DMI_Sounds.Sinfo, "TTI display plays Sinfo");
      Step;
      Check_Frame ("tti_10s");
      Send_Status (TTI => 2, T_Disp_TTI => 14);
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
   procedure Scenario_Text_Unknown_Glyphs is
      function W (Code : Natural) return Wide_Character is
        (Wide_Character'Val (Code));
      Wide_Line : constant Wide_String (1 .. 36) := (others => '@');
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      -- Latin-1 accented letters, the characters after 'z'
      Send_Text (1, "Arr" & W (16#EA#) & "t T" & W (16#FC#) & "r Stra"
                    & W (16#DF#) & "e {|}~", HH => 10, MM => 5);
      -- control characters, DEL, NBSP and 16#FF#
      Send_Text (2, "c" & W (16#00#) & W (16#01#) & W (16#0A#) & W (16#1F#)
                    & "d" & W (16#7F#) & W (16#80#) & W (16#A0#)
                    & W (16#FF#) & "e",
                 First_Group => True, Class => 2, HH => 10, MM => 6);
      Drain_Sounds;
      Step;
      Check_Frame ("text_unknown_glyphs");
      -- 36 of the widest glyph are far wider than a line: no raise (the
      -- lines themselves are checked in Scenario_Text_Wrap)
      Send_Text_Remove (1);
      Send_Text_Remove (2);
      Send_Text (3, Wide_Line, HH => 10, MM => 7);
      Drain_Sounds;
      Step;
      Check (True, "over-wide text is drawn without raising");
   end Scenario_Text_Unknown_Glyphs;

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
      Pointer_Down (310, 440); Pointer_Up (310, 440); -- E11 scroll down
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

   -- Acknowledgement FIFO (5.4.1.7, 5.4.1.9, 5.4.1.9.1, 8.2.3.4.8)

   -- Ack_Kind_T'Pos as sent with the acknowledgement (DMI_Protocol)
   ACK_LEVEL : constant := 0;
   ACK_MODE  : constant := 1;
   ACK_FIXED : constant := 2;
   ACK_PLAIN : constant := 3;
   ACK_BRAKE : constant := 5;

   procedure Ack_Reset is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Outbox;
   end Ack_Reset;

   -- Press the acknowledgement area of this kind of request and let the
   -- DMI handle it
   procedure Ack_Tap (Kind : Natural) is
      X : constant Natural :=
        (case Kind is
            when ACK_LEVEL | ACK_MODE => 190,  -- C1
            when ACK_BRAKE            => 25,   -- C8, extended brake area
            when others               => 150); -- E5-E9
      Y : constant Natural :=
        (case Kind is
            when ACK_LEVEL | ACK_MODE => 340,
            when ACK_BRAKE            => 330,
            when others               => 400);
   begin
      Pointer_Down (X, Y);
      Pointer_Up (X, Y);
      Step;
      Drain_Sounds;
   end Ack_Tap;

   -- 5.4.1.9: nothing is offered for 1 s (20 cycles of 50 ms) after the
   -- last request went; Ack_Tap has used one cycle more
   procedure Ack_Expect_Gap (What : String) is
   begin
      for I in 1 .. 19 loop
         Step;
      end loop;
      Check (not DMI_Ack.Current_Valid, What & ": nothing offered for 1 s");
      Expect_No_Sound (What & ": silent for 1 s");
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, What & ": next offer after 1 s");
   end Ack_Expect_Gap;

   -- ROB-5: two texts of the same class are offered one after the other
   procedure Scenario_Ack_Same_Class is
   begin
      Ack_Reset;
      Send_Text (9, "Entering FS", HH => 11, MM => 0);
      Send_Text (10, "Level crossing not protected", Ack_Required => True,
                 HH => 11, MM => 1);
      Send_Text (11, "Route unsuitable - axle load category",
                 Ack_Required => True, HH => 11, MM => 2);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "first text ack offer plays Sinfo");
      Check (DMI_Ack.Pending_Count = 2, "one request per text message");
      Check_Frame ("ack_fifo_text_first");

      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 10, "first text acknowledged with its id");
      -- 5.4.1.10: the list stays hidden, the second text is not due yet
      Check_Frame ("ack_fifo_text_gap");
      Ack_Expect_Gap ("second text of the same class");
      Check_Frame ("ack_fifo_text_second");

      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 11, "second text acknowledged with its id");
      -- 8.2.3.4.8 c: both are ordinary messages now
      Check (not DMI_Text_Messages.Ack_Pending, "no text left to acknowledge");
      Check_Frame ("ack_fifo_text_done");
   end Scenario_Ack_Same_Class;

   -- GEN-1: order of arrival; 5.4.1.9.1 only for simultaneous requests
   procedure Scenario_Ack_Arrival_Order is
   begin
      Ack_Reset;
      -- three cycles: plain text, brake release, mode change
      Send_Text (20, "Level crossing not protected", Ack_Required => True);
      Step;
      Send_Status (Brake => 2, Radio => 1);
      Step;
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "only the first request is offered");
      Expect_No_Sound ("the later requests wait");

      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 20, "text arrived first");
      Ack_Expect_Gap ("brake release after the text");
      Ack_Tap (ACK_BRAKE);
      Expect_Ack (ACK_BRAKE, 0, "brake release arrived second");
      Ack_Expect_Gap ("mode change after the brake release");
      Ack_Tap (ACK_MODE);
      Expect_Ack (ACK_MODE, 0, "mode change arrived last");

      -- one cycle: brake release, fixed text, mode change and level
      -- transition are queued in the sequence of 5.4.1.9.1
      Ack_Reset;
      Send_Status (Brake => 2, Radio => 1);
      Send_Text (21, "Level crossing not protected", Ack_Required => True,
                 Class => 0);
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6,
                       Level_Ann => 2, Level_Ann_Ack => True);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "simultaneous: one offer");
      Ack_Tap (ACK_LEVEL);
      Expect_Ack (ACK_LEVEL, 0, "simultaneous: level transition first");
      Ack_Expect_Gap ("simultaneous: mode change");
      Ack_Tap (ACK_MODE);
      Expect_Ack (ACK_MODE, 0, "simultaneous: mode change second");
      Ack_Expect_Gap ("simultaneous: fixed text");
      Ack_Tap (ACK_FIXED);
      Expect_Ack (ACK_FIXED, 21, "simultaneous: fixed text third");
      Ack_Expect_Gap ("simultaneous: brake release");
      Ack_Tap (ACK_BRAKE);
      Expect_Ack (ACK_BRAKE, 0, "simultaneous: brake release last");
   end Scenario_Ack_Arrival_Order;

   -- 5.4.1.9: the 1 s also runs after a revoked request
   procedure Scenario_Ack_Revoked is
   begin
      Ack_Reset;
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "mode ack offered");
      Send_Text (30, "Level crossing not protected", Ack_Required => True);
      Step;
      Expect_No_Sound ("text waits behind the mode ack");
      -- the EVC withdraws the mode acknowledgement
      Send_Mode_Level (Mode => 2, Level => 4);
      Ack_Expect_Gap ("text after the revoked mode ack");
      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 30, "text acknowledged after the revocation");
   end Scenario_Ack_Revoked;

   -- Removing one message revokes its own request only
   procedure Scenario_Ack_Remove_One is
   begin
      Ack_Reset;
      Send_Text (40, "Level crossing not protected", Ack_Required => True);
      Step;
      Send_Text (41, "Route unsuitable - axle load category",
                 Ack_Required => True);
      Step;
      Drain_Sounds;
      -- the waiting one goes: the offered one stays offered
      Send_Text_Remove (41);
      Step;
      Check (DMI_Ack.Current_Valid and then DMI_Ack.Current_Text_ID = 40,
             "removing the waiting text keeps the offered one");
      Expect_No_Sound ("no new offer after removing the waiting text");
      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 40, "offered text still acknowledgeable");

      Ack_Reset;
      Send_Text (42, "Level crossing not protected", Ack_Required => True);
      Step;
      Send_Text (43, "Route unsuitable - axle load category",
                 Ack_Required => True);
      Step;
      Drain_Sounds;
      -- the offered one goes: the other one follows after 1 s
      Send_Text_Remove (42);
      Ack_Expect_Gap ("text after the removed text");
      Check (DMI_Ack.Current_Valid and then DMI_Ack.Current_Text_ID = 43,
             "the remaining text is offered");
      Check_Frame ("ack_fifo_text_after_removal");
      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 43, "remaining text acknowledged");
   end Scenario_Ack_Remove_One;

   -- More requests than the queue holds: nothing raises, everything can
   -- still be acknowledged
   procedure Scenario_Ack_Queue_Full is
      type Expected_T is record
         Kind, ID : Natural;
      end record;
      -- 8 texts fill the text slots, the objects use their reserved
      -- slots, the 4 texts that did not fit follow as slots come free
      Expected : constant array (1 .. 15) of Expected_T :=
        ((ACK_PLAIN, 101), (ACK_PLAIN, 102), (ACK_PLAIN, 103),
         (ACK_PLAIN, 104), (ACK_PLAIN, 105), (ACK_PLAIN, 106),
         (ACK_PLAIN, 107), (ACK_PLAIN, 108),
         (ACK_LEVEL, 0), (ACK_MODE, 0), (ACK_BRAKE, 0),
         (ACK_PLAIN, 109), (ACK_PLAIN, 110), (ACK_PLAIN, 111),
         (ACK_PLAIN, 112));
   begin
      Ack_Reset;
      for ID in 101 .. 112 loop
         Send_Text (ID, "Level crossing not protected", Ack_Required => True);
      end loop;
      Step;
      Check (DMI_Ack.Pending_Count = DMI_Ack.Text_Capacity,
             "queue full: text requests limited to the capacity");
      Send_Status (Brake => 2, Radio => 1);
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6,
                       Level_Ann => 2, Level_Ann_Ack => True);
      Step;
      Check (DMI_Ack.Pending_Count = DMI_Ack.Text_Capacity + 3,
             "queue full: object requests are never refused");
      Drain_Sounds;

      for I in Expected'Range loop
         if I > Expected'First then
            for J in 1 .. 20 loop
               Step;
            end loop;
            Drain_Sounds;
         end if;
         Ack_Tap (Expected (I).Kind);
         Expect_Ack (Expected (I).Kind, Expected (I).ID,
                     "queue full: acknowledgement" & Natural'Image (I));
      end loop;
      Check (DMI_Ack.Pending_Count = 0
             and then not DMI_Text_Messages.Ack_Pending,
             "queue full: everything was acknowledged");
   end Scenario_Ack_Queue_Full;

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

   ---------------------------------------------------------------------
   -- Coordinates of the data entry windows (Tables 22, 23, 25) and the
   -- two sequences the scenarios repeat: the Level window of Table 38
   -- and the train data of Table 40 over two windows (audit WIN-8,
   -- WIN-10)
   ---------------------------------------------------------------------

   -- Table 25: key K of the keyboard, three per row from y 200
   function Key_X (K : Positive) return Natural is
     (334 + ((K - 1) mod 3) * 102 + 51);
   function Key_Y (K : Positive) return Natural is
     (15 + 200 + ((K - 1) / 3) * 50 + 25);

   procedure Key (K : Positive) is
   begin
      Press (Key_X (K), Key_Y (K));
   end Key;

   -- Table 23: the data part of the input field I, which is its [Enter]
   -- button (10.3.1.22)
   procedure Enter_Field (I : Positive) is
   begin
      Press (589, 15 + (I - 1) * 50 + 25);
   end Enter_Field;

   -- Table 22: the merged data part of a window with a single input
   -- field (10.3.5.5)
   procedure Enter_Single is
   begin
      Press (487, 90);
   end Enter_Single;

   -- Tables 22 and 23: [Previous] and [Next] right of [Close]
   procedure Press_Previous is
   begin
      Press (457, 440);
   end Press_Previous;

   procedure Press_Next is
   begin
      Press (539, 440);
   end Press_Next;

   -- 11.3.2: choose a level on the dedicated keyboard of Table 38 and
   -- accept it (K is the button number of the table)
   procedure Choose_Level (K : Positive := 1) is
   begin
      Key (K);
      Enter_Single;
   end Choose_Level;

   -- 11.3.9: the seven items of Table 40 over the two windows of
   -- Figures 120 and 121, ending on the first window again
   procedure Enter_Train_Data (Length, Brake, Speed : Positive) is
      procedure Type_Number (N : Natural) is
         Img : constant Wide_String := Natural'Wide_Image (N);
      begin
         for I in 2 .. Img'Last loop
            -- Table 25: '1' .. '9' on the keys 1 .. 9, '0' on the key 11
            if Img (I) = '0' then
               Key (11);
            else
               Key (Wide_Character'Pos (Img (I))
                    - Wide_Character'Pos ('0'));
            end if;
         end loop;
      end Type_Number;
   begin
      Key (1); Enter_Field (1);           -- train category PASS 1
      Type_Number (Length); Enter_Field (2);
      Type_Number (Brake); Enter_Field (3);
      Type_Number (Speed); Enter_Field (4);
      Press_Next;
      Key (1); Enter_Field (1);           -- axle load category A
      Key (7); Enter_Field (2);           -- airtight: No (Table 40)
      Key (5); Enter_Field (3);           -- loading gauge Out of GC
      Press_Previous;
   end Enter_Train_Data;

   ---------------------------------------------------------------------
   -- Input hardening (audit ROB-6 .. ROB-9)
   ---------------------------------------------------------------------

   MSG_PLANNING_Raw : constant := 16#06#;

   -- ROB-6: planning messages with any content. Malformed ones are
   -- ignored as a whole, not valid elements are left out, nothing raises.
   procedure Scenario_Planning_Malformed is

      procedure Send_Reference (Orders : Gradient_Array) is
      begin
         Send_Planning
           (MA_Dist    => 2500,
            Ceiling    => 140,
            Indication => 1200,
            Gradients  => (0, 12, 800, -5, 1800, 0),
            Speeds     => (1000, 70, 0,  1700, 40, 0,  2500, 0, 1),
            Orders     => Orders);
      end Send_Reference;

      procedure Check_Unchanged (What : String) is
      begin
         Check (DMI_Planning.Valid
                and then DMI_Planning.MA_Dist_M = 2500
                and then DMI_Planning.Ceiling_Speed = 140
                and then DMI_Planning.Gradient_Count = 3
                and then DMI_Planning.Speed_Count = 3
                and then DMI_Planning.Order_Count = 2,
                What & " is ignored as a whole");
      end Check_Unchanged;

      -- deterministic pseudo random bytes
      Seed : Natural := 12345;
      function Next_Byte return Natural is
      begin
         Seed := (Seed * 1_103 + 12_345) mod 65_536;
         return (Seed / 7) mod 256;
      end Next_Byte;
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 100, V_Perm => 140, V_Target => 0,
                        V_Release => 0, V_Sbi => 155, V_Wsl => 145,
                        D_Target => 2500, Monitoring => 0, Dial_Range => 2,
                        Vrelease_Exists => False);
      Send_Reference (Orders => (2, 600,  5, 1500));

      Send_Raw (MSG_PLANNING_Raw, (1 .. 0 => 0));
      Check_Unchanged ("empty planning payload");
      Send_Raw (MSG_PLANNING_Raw, (16#E8#, 3, 255, 255, 255, 255, 100, 0));
      Check_Unchanged ("planning header without the lists");
      Send_Raw (MSG_PLANNING_Raw,
                (16#E8#, 3, 255, 255, 255, 255, 100, 0,  255));
      Check_Unchanged ("gradient count beyond the payload");
      Send_Raw (MSG_PLANNING_Raw,
                (16#E8#, 3, 255, 255, 255, 255, 100, 0,
                 1,  0, 0, 5,
                 2,  100, 0, 80, 0,  200, 0, 60));
      Check_Unchanged ("payload cut inside a speed element");
      Send_Raw (MSG_PLANNING_Raw,
                (16#E8#, 3, 255, 255, 255, 255, 100, 0,
                 1,  0, 0, 5,
                 1,  100, 0, 80, 0));
      Check_Unchanged ("payload without the order count");
      Send_Raw (MSG_PLANNING_Raw,
                (16#E8#, 3, 255, 255, 255, 255, 100, 0,
                 0,  0,  200,  1, 100));
      Check_Unchanged ("order count beyond the payload");
      Send_Raw (MSG_PLANNING_Raw,
                (16#E8#, 3, 255, 255, 255, 255, 100, 0,  0, 0, 0,  9, 9));
      Check_Unchanged ("bytes after the last list");
      Send_Raw (MSG_PLANNING_Raw,
                (16#E8#, 3, 255, 255, 255, 255, 16#91#, 1,  0, 0, 0));
      Check_Unchanged ("ceiling speed of 401 km/h");
      Drain_Sounds;
      Step;
      Check_Frame ("planning_fs");

      -- order symbols that do not exist (0, 38, 255) or that are no
      -- orders (PL21-PL23, PL37) between the two valid ones: the picture
      -- is the one with the two valid orders alone
      Send_Reference (Orders => (0, 600,  2, 600,  38, 900,  21, 700,
                                 255, 1000,  5, 1500,  22, 1100,
                                 23, 1200,  37, 800));
      Check (DMI_Planning.Order_Count = 2,
             "orders with an unknown symbol are left out");
      Drain_Sounds;
      Step;
      Check_Frame ("planning_fs");

      -- the extremes of every field: distances 0 and 65535, gradients
      -- -128 and 127, 400 km/h, first and last order symbol
      Send_Raw (MSG_PLANNING_Raw,
                (255, 255,  254, 255,  254, 255,  16#90#, 1,
                 3,  0, 0, 128,  16#D0#, 7, 127,  255, 255, 0,
                 3,  0, 0, 16#90#, 1,  16#DC#, 5, 0, 0,
                     255, 255, 0, 16#80#,
                 3,  1, 0, 0,  36, 255, 255,  20, 16#DC#, 5));
      Check (DMI_Planning.MA_Dist_M = 65_535
             and then DMI_Planning.Gradient_Count = 2
             and then DMI_Planning.Gradients (1).Value = -128
             and then DMI_Planning.Gradients (2).Value = 127,
             "field extremes are decoded");
      Drain_Sounds;
      Step;
      Check_Frame ("planning_extremes");
      for I in 1 .. 5 loop -- every range, 0-4000 up to 0-32000 and back
         Pointer_Down (350, 20); Pointer_Up (350, 20);
         Step;
      end loop;
      for I in 1 .. 5 loop
         Pointer_Down (350, 300); Pointer_Up (350, 300);
         Step;
      end loop;

      -- well formed lists of any length filled with any bytes, and
      -- plain noise, rendered in the longest range
      for Round in 1 .. 300 loop
         declare
            G : constant Natural := Next_Byte mod 80;
            S : constant Natural := Next_Byte mod 80;
            O : constant Natural := Next_Byte mod 80;
            Bytes : Byte_Array (1 .. 11 + G * 3 + S * 4 + O * 3);
         begin
            for B of Bytes loop
               B := Next_Byte;
            end loop;
            Bytes (8) := Bytes (8) mod 2; -- a ceiling speed that may pass
            Bytes (9) := G;
            Bytes (10 + G * 3) := S;
            Bytes (11 + G * 3 + S * 4) := O;
            Send_Raw (MSG_PLANNING_Raw, Bytes);
            Send_Raw (MSG_PLANNING_Raw,
                      Bytes (1 .. Natural'Min (Bytes'Last, Round)));
            if Round = 1 then
               for I in 1 .. 3 loop
                  Pointer_Down (350, 20); Pointer_Up (350, 20);
               end loop;
            end if;
            Step;
         end;
      end loop;
      Drain_Sounds;
      Check (True, "planning survives any byte content");
   end Scenario_Planning_Malformed;

   -- ROB-9: more elements than the lists hold, and profiles that break
   -- the rules. What is left out is not drawn as if it were known.
   procedure Scenario_Planning_Overflow is
      procedure Zoom_Out (Times : Natural) is
      begin
         for I in 1 .. Times loop
            Pointer_Down (350, 20); Pointer_Up (350, 20);
         end loop;
      end Zoom_Out;

      -- N gradients Step_M apart from 0, N speed discontinuities and N
      -- orders; the orders are sent farthest first
      procedure Send_Profile (G_N, S_N, O_N : Natural;
                              G_Step, S_Step, O_Step : Natural) is
         G : Gradient_Array (1 .. G_N * 2);
         S : Gradient_Array (1 .. S_N * 3);
         O : Gradient_Array (1 .. O_N * 2);
      begin
         for I in 1 .. G_N loop
            G (I * 2 - 1) := (I - 1) * G_Step;
            G (I * 2) := (if I mod 2 = 0 then -(I mod 30) else I mod 30);
         end loop;
         for I in 1 .. S_N loop
            S (I * 3 - 2) := I * S_Step;
            S (I * 3 - 1) := (if I mod 2 = 0 then 160 else 120);
            S (I * 3) := 0;
         end loop;
         for I in 1 .. O_N loop
            O (I * 2 - 1) := 1 + (I mod 20);
            O (I * 2) := (O_N - I + 1) * O_Step;
         end loop;
         Send_Planning (MA_Dist => 32_000, Ceiling => 160,
                        Gradients => G, Speeds => S, Orders => O);
      end Send_Profile;
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 100, V_Perm => 160, V_Target => 0,
                        V_Release => 0, V_Sbi => 175, V_Wsl => 165,
                        D_Target => 32_000, Monitoring => 0, Dial_Range => 2,
                        Vrelease_Exists => False);

      -- a dense but realistic profile over the longest range fits
      Send_Profile (G_N => 60, S_N => 30, O_N => 30,
                    G_Step => 500, S_Step => 1000, O_Step => 1000);
      Step;
      Zoom_Out (3); -- 0-32000 (8.3.3.4)
      Check (DMI_Planning.Gradient_Count = 60
             and then DMI_Planning.Speed_Count = 30
             and then DMI_Planning.Order_Count = 30
             and then DMI_Planning.Orders_Left_Out = 0
             and then DMI_Planning.Gradient_End_M >= 32_000
             and then DMI_Planning.Speed_End_M >= 32_000,
             "a profile of 60 gradients, 30 speeds, 30 orders is complete");
      Drain_Sounds;
      Step;
      Check_Frame ("planning_full_32000");

      -- too many: the profiles end where the first left out element
      -- starts, the nearest orders are kept
      Send_Profile (G_N => 70, S_N => 35, O_N => 40,
                    G_Step => 400, S_Step => 800, O_Step => 700);
      Check (DMI_Planning.Gradient_Count = DMI_Planning.Max_Gradients
             and then DMI_Planning.Gradient_End_M = 64 * 400,
             "the gradient profile ends at the first gradient left out");
      Check (DMI_Planning.Speed_Count = DMI_Planning.Max_Speeds
             and then DMI_Planning.Speed_End_M = 33 * 800,
             "the speed profile ends at the first discontinuity left out");
      Check (DMI_Planning.Order_Count = DMI_Planning.Max_Orders
             and then DMI_Planning.Orders_Left_Out = 8,
             "orders beyond the capacity are counted");
      declare
         Farthest : Natural := 0;
      begin
         for I in 1 .. DMI_Planning.Order_Count loop
            Farthest := Natural'Max (Farthest, DMI_Planning.Orders (I).Dist_M);
         end loop;
         Check (Farthest = 32 * 700, "the nearest orders are the ones kept");
      end;
      Drain_Sounds;
      Step;
      Check_Frame ("planning_overflow_32000");

      -- a gradient nearer than the one before it, a speed above 400 km/h
      Pointer_Down (350, 300); Pointer_Up (350, 300);
      Pointer_Down (350, 300); Pointer_Up (350, 300);
      Pointer_Down (350, 300); Pointer_Up (350, 300); -- back to 0-4000
      Send_Planning
        (MA_Dist    => 2500,
         Ceiling    => 140,
         Gradients  => (0, 12,  1000, -5,  500, 8,  2000, 3),
         Speeds     => (1000, 70, 0,  1700, 401, 0,  2500, 0, 1),
         Orders     => (2, 600,  5, 1500));
      Check (DMI_Planning.Gradient_Count = 2
             and then DMI_Planning.Gradient_End_M = 1000,
             "a gradient out of order cuts the profile before it");
      Check (DMI_Planning.Speed_Count = 1
             and then DMI_Planning.Speed_End_M = 1700,
             "a speed above 400 km/h cuts the speed profile");
      Drain_Sounds;
      Step;
      Check_Frame ("planning_cut");
   end Scenario_Planning_Overflow;

   -- ROB-7: a full sound queue must not lose the start or the stop of
   -- the continuous S2 warning (14.3.3.2)
   procedure Scenario_Sound_Overflow is
      use type DMI_Sounds.Sound_T;

      S2_Playing : Boolean := False; -- what the display unit would play
      S1_Heard   : Boolean := False;

      procedure Listen is
         Got : DMI_Sounds.Sound_T;
      begin
         S1_Heard := False;
         while DMI_Sounds.Pop (Got) loop
            if Got = DMI_Sounds.S2_Warning_Start then
               S2_Playing := True;
            elsif Got = DMI_Sounds.S2_Warning_Stop then
               S2_Playing := False;
            elsif Got = DMI_Sounds.S1_Overspeed then
               S1_Heard := True;
            end if;
         end loop;
      end Listen;
   begin
      Reset;
      -- the stop arrives when the queue is full
      DMI_Sounds.Play (DMI_Sounds.S2_Warning_Start);
      for I in 1 .. 20 loop
         DMI_Sounds.Play (DMI_Sounds.Click);
      end loop;
      DMI_Sounds.Play (DMI_Sounds.S2_Warning_Stop);
      Listen;
      Check (not S2_Playing, "S2 stop is not lost when the queue is full");

      -- the start arrives when the queue is full
      for I in 1 .. 20 loop
         DMI_Sounds.Play (DMI_Sounds.Sinfo);
      end loop;
      DMI_Sounds.Play (DMI_Sounds.S2_Warning_Start);
      Listen;
      Check (S2_Playing, "S2 start is not lost when the queue is full");

      -- stop, start and stop again behind a full queue
      for I in 1 .. 20 loop
         DMI_Sounds.Play (DMI_Sounds.Click);
      end loop;
      DMI_Sounds.Play (DMI_Sounds.S2_Warning_Stop);
      DMI_Sounds.Play (DMI_Sounds.S2_Warning_Start);
      DMI_Sounds.Play (DMI_Sounds.S2_Warning_Stop);
      Listen;
      Check (not S2_Playing, "S2 ends up stopped after stop, start, stop");

      -- S1 takes the place of a click or a Sinfo
      for I in 1 .. 4 loop
         DMI_Sounds.Play (DMI_Sounds.Click);
         DMI_Sounds.Play (DMI_Sounds.Sinfo);
      end loop;
      DMI_Sounds.Play (DMI_Sounds.S1_Overspeed);
      Listen;
      Check (S1_Heard, "S1 is not lost when the queue is full");
      Expect_No_Sound ("sound queue drained");
   end Scenario_Sound_Overflow;

   -- ROB-8: the scroll offset after removals (8.2.3.4.7 e), the full
   -- message store and the cut of a long text
   procedure Scenario_Text_Store is
      package TM renames DMI_Text_Messages;

      function Line_Text (Index : Positive) return Wide_String is
         Line  : TM.Line_T;
         Valid : Boolean;
      begin
         TM.Get_Visible_Line (Index, Line, Valid);
         return (if Valid then Line.Text (1 .. Line.Length) else "<none>");
      end Line_Text;

      function Number (N : Natural) return Wide_String is
         Img : constant Wide_String := Natural'Wide_Image (N);
      begin
         return Img (2 .. Img'Last);
      end Number;

      Steps : Natural := 0;
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);

      -- eight lines, scrolled to the end, then five messages go
      for I in 1 .. 8 loop
         Send_Text (ID => I, Text => "Auxiliary " & Number (I));
      end loop;
      for I in 1 .. 3 loop
         TM.Scroll_Down;
      end loop;
      Check (Line_Text (5) = "Auxiliary 1" and then not TM.Can_Scroll_Down,
             "list scrolled to its end");
      for I in 1 .. 5 loop
         Send_Text_Remove (I);
      end loop;
      Check (Line_Text (1) = "Auxiliary 8"
             and then Line_Text (3) = "Auxiliary 6"
             and then not TM.Can_Scroll_Up
             and then not TM.Can_Scroll_Down,
             "scroll offset follows the removals");
      Drain_Sounds;
      Step;
      Check_Frame ("messages_scroll_clamped");

      -- a first group message, one to be acknowledged and ten auxiliary
      -- ones fill the store of 12; five more auxiliary ones and a first
      -- group one arrive
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Text (ID => 100, Text => "Balise read error", First_Group => True,
                 Class => 2);
      Send_Text (ID => 101, Text => "Acknowledge me", Ack_Required => True);
      for I in 1 .. 10 loop
         Send_Text (ID => I, Text => "Auxiliary " & Number (I));
      end loop;
      for I in 11 .. 15 loop
         Send_Text (ID => I, Text => "Auxiliary " & Number (I));
      end loop;
      Send_Text (ID => 300, Text => "Runaway movement", First_Group => True,
                 Class => 2);
      Step; -- the acknowledgement request is offered on the next cycle
      Check (TM.Ack_Pending and then DMI_Ack.Current_Valid
             and then DMI_Ack.Current_Text_ID = 101,
             "the message to be acknowledged survives a full store");
      Send_Text_Remove (101);
      Check (Line_Text (1) = "Runaway movement"
             and then Line_Text (2) = "Balise read error",
             "first group messages survive and enter a full store");
      Check (Line_Text (3) = "Auxiliary 15"
             and then Line_Text (5) = "Auxiliary 13",
             "new auxiliary messages take the place of the oldest ones");
      Drain_Sounds;
      Step;
      Check_Frame ("messages_store_full");
      while TM.Can_Scroll_Down and then Steps < 100 loop
         TM.Scroll_Down;
         Steps := Steps + 1;
      end loop;
      -- 12 slots, one freed by the removal: 11 lines, the oldest kept
      -- auxiliary message is number 7
      Check (Steps = 6 and then Line_Text (5) = "Auxiliary 7",
             "the oldest auxiliary messages are the ones given up");

      -- nothing but first group messages: an auxiliary one is dropped,
      -- a first group one takes the place of the oldest
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      for I in 1 .. 12 loop
         Send_Text (ID => I, Text => "Important " & Number (I),
                    First_Group => True);
      end loop;
      Send_Text (ID => 400, Text => "Auxiliary late");
      Send_Text (ID => 401, Text => "Important late", First_Group => True);
      Steps := 0;
      while TM.Can_Scroll_Down and then Steps < 100 loop
         TM.Scroll_Down;
         Steps := Steps + 1;
      end loop;
      Check (Steps = 7 and then Line_Text (5) = "Important 2",
             "an auxiliary message never displaces a first group one");
      while TM.Can_Scroll_Up loop
         TM.Scroll_Up;
      end loop;
      Check (Line_Text (1) = "Important late",
             "a first group message displaces the oldest first group one");

      -- the protocol carries 255 characters and all are kept; a longer
      -- text (only a caller inside the DMI can pass one) is cut and
      -- says so
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      declare
         Too_Long : Wide_String (1 .. TM.Max_Text + 45);
      begin
         for I in Too_Long'Range loop
            Too_Long (I) := (if I mod 11 = 0 then ' '
                             else Wide_Character'Val (48 + I mod 10));
         end loop;
         TM.Put (ID => 1, First_Group => False, Ack_Required => False,
                 Class => TM.Plain_Text, Hour => 0, Minute => 0,
                 Text => Too_Long);
      end;
      Steps := 0;
      while TM.Can_Scroll_Down and then Steps < 1000 loop
         TM.Scroll_Down;
         Steps := Steps + 1;
      end loop;
      for I in reverse 1 .. TM.Visible_Lines loop
         declare
            Last : constant Wide_String := Line_Text (I);
         begin
            if Last /= "<none>" then
               Check (Last'Length >= 3
                      and then Last (Last'Last - 2 .. Last'Last) = "...",
                      "a cut text ends in an ellipsis");
               exit;
            end if;
         end;
      end loop;
      Drain_Sounds;
      Step;
   end Scenario_Text_Store;

   procedure Scenario_Startup_Sequence is
      use type DMI_Windows.Window_ID_T;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 0); -- SB, level unknown
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Drain_Outbox;

      -- Table 49 S0 -> S1: the sequence is engaged with the entry into
      -- SB, not by a button; 11.7.2.2: [Close] is disabled (NA12)
      Step;
      Check_Frame ("startup_driver_id");
      Press (370, 440);       -- [Close]: disabled
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "S1: the disabled [Close] does not close the Driver ID window");
      Press (610, 40);        -- F1 is under the window's rule (5.3.1.1.5)
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "S1: only the Driver ID window responds");

      Press (385, 240);       -- 1
      Press (487, 240);       -- 2
      Press (589, 240);       -- 3
      Step;
      Check_Frame ("startup_driver_id_123");
      Press (487, 90);        -- [Enter] -> D2 -> S2 Level window
      Step;
      Check_Frame ("startup_level");
      Press (370, 440);       -- [Close]: disabled
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Level,
             "S2: the disabled [Close] does not close the Level window");

      -- 11.3.2.4, Table 38: the button 1 is 'Level 1'; the choice has to
      -- be accepted on the input field -> S10 = S1 of the Main window
      Key (1);
      Check (DMI_Windows.Top = DMI_Windows.W_Level,
             "S2: a key of the dedicated keyboard does not leave the window");
      Step;
      Check_Frame ("startup_level_1");
      Enter_Single;
      Step;
      Check (not DMI_Windows.In_Start_Up, "S10: the Start Up sequence ended");
      Check_Frame ("main_window"); -- 'Start' disabled: data not valid
      Press (410, 90);        -- Start: disabled (Table 33)
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Main,
             "disabled Start does not react");
      Expect_Actions (5, 0, "no mission start while Start is disabled");

      -- 11.7.3.2: [Close] is enabled in the Main window sequence
      Press (370, 440);
      Check (not DMI_Windows.Is_Open, "S10: [Close] leads to the default window");
      Press (610, 40);        -- F1: Main window

      Press (410, 140);       -- Train data -> Table 50 S3-1
      Step;
      Check_Frame ("startup_train_data");

      -- Figure 120: train category, length, brake percentage and
      -- maximum speed on the first window, the rest on the second
      Key (1); Enter_Field (1);           -- train category PASS 1
      Press (385, 290); Press (487, 390); Press (487, 390);
      Enter_Field (2);        -- length 400, the data field is [Enter]
      Press (385, 240); Press (589, 240); Press (487, 290);
      Enter_Field (3);        -- brake percentage 135
      Press (385, 240); Press (385, 290); Press (487, 390);
      Step;
      Check_Frame ("startup_train_data_filled");
      Enter_Field (4);        -- maximum speed 140
      -- 10.3.5.9: 'Yes' stays disabled while the second window still
      -- has input fields without a data value (Table 50 S3-1)
      Press (167, 440);
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "the 'Yes' button waits for the items of the other window");
      Press_Next;             -- Table 23: [Next] -> Figure 121
      Step;
      Check_Frame ("startup_train_data_2");
      Key (1); Enter_Field (1);           -- axle load category A
      Key (7); Enter_Field (2);           -- airtight: No (Table 40)
      Key (5); Enter_Field (3);           -- loading gauge Out of GC
      Step;
      Check_Frame ("startup_train_data_2_filled");
      Press (167, 440);       -- 'Train data entry complete?' Yes (Table 24)
      Step;
      Check_Frame ("startup_validation");
      -- 11.7.1.6.1: nothing is stored on board before the validation
      Check (not DMI_Driver_Data.Train_Data_Entered
             and then DMI_Driver_Data.Train_Length = 0,
             "the 'Yes' of the question stores no train data");

      Press (487, 40);        -- accept the proposed 'Yes' (Table 29)
                              -- -> D6: TRN not valid -> S3-3
      Step;
      Check_Frame ("startup_trn");

      -- TRN 4711
      Press (385, 290); Press (385, 340); Press (385, 240); Press (385, 240);
      Press (487, 90);        -- [Enter] -> D1 -> S1, the Main window
      Step;
      Check_Frame ("startup_done"); -- 'Start' enabled
      Expect_Actions (5, 0, "the DMI does not start the mission by itself");

      Check (DMI_Driver_Data.Driver_ID_Entered, "driver id entered");
      Check (DMI_Driver_Data.Level_Entered, "level entered");
      Check (DMI_Driver_Data.Train_Data_Entered, "train data validated");
      Check (DMI_Driver_Data.TRN_Entered, "TRN entered");
      Check (DMI_Driver_Data.Train_Length = 400, "train length 400");
      Check (DMI_Driver_Data.Brake_Pct = 135, "brake percentage 135");
      Check (DMI_Driver_Data.Max_Speed = 140, "max speed 140");
      -- Table 40, Table 41, Table 42 and SUBSET-026 7.5.1.61 / 7.5.1.62
      Check (DMI_Train_Data.Category_CD = 0
             and then DMI_Train_Data.Category_Other = 4,
             "PASS 1 is cant deficiency 80 mm, passenger train");
      Check (DMI_Train_Data.Axle_Load_Value = 0, "axle load category A");
      Check (DMI_Train_Data.Airtight_Value = 0, "airtight: not fitted");
      Check (DMI_Train_Data.Gauge_Value = 0, "loading gauge: out of GC");

      -- Table 50 S1: 'Start' with level 1 leads to the default window and
      -- is the driver's single request
      Press (410, 90);
      Check (not DMI_Windows.Is_Open, "Start leads to the default window");
      Expect_Actions (5, 1, "Start sends one mission start request");
      Press (610, 40);        -- F1: Main window again
      Step;
      Check_Frame ("startup_start_pending"); -- 'Start' disabled
      Press (410, 90);
      Expect_Actions (5, 0, "no second request while the first is pending");

      -- the mission runs: Table 33 does not enable 'Start' in FS
      Send_Mode_Level (Mode => 2, Level => 4);
      Press (410, 90);
      Expect_Actions (5, 0, "no mission start request while the mission runs");
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Main,
             "a mode change outside SB leaves the Main window alone");

      -- end of mission: SB again. S1 proposes the stored Driver ID for
      -- revalidation (SUBSET-026 4.10.1.3), the level is still valid (D2
      -- -> D3 -> S10), train data and TRN have to be revalidated
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Check (DMI_Windows.In_Start_Up
             and then DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "SB again: Start Up engaged with the Driver ID window");
      Check_Frame ("startup_again_driver_id");
      Press (487, 90);        -- [Enter]: revalidated -> D2 -> D3 -> S10
      Check (not DMI_Windows.In_Start_Up
             and then DMI_Windows.Top = DMI_Windows.W_Main,
             "valid level: Driver ID leads to the Main window");
      Check (not DMI_Driver_Data.Train_Data_Entered
             and then not DMI_Driver_Data.TRN_Entered,
             "train data and TRN are to be revalidated");
      Press (410, 90);
      Expect_Actions (5, 0, "Start stays disabled until the data are valid");

      -- SB is left during Start Up (e.g. SL): nothing stale stays behind
      Send_Mode_Level (Mode => 3, Level => 4);
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Check (DMI_Windows.In_Start_Up, "Start Up engaged once more");
      Send_Mode_Level (Mode => 16, Level => 4); -- SL
      Step;
      Check (not DMI_Windows.In_Start_Up and then not DMI_Windows.Is_Open,
             "leaving SB ends the Start Up sequence and its windows");
      Press (610, 40);        -- F1
      Press (370, 440);       -- [Close]
      Check (not DMI_Windows.Is_Open, "[Close] is enabled again");
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
      -- 11.3.11.4, Table 43: the button 2 is 'Slippery rail'; accepting
      -- it on the input field leaves the window (10.6.1.2 a)
      Key (2);
      Step;
      Check_Frame ("adhesion_slippery");
      Enter_Single;
      Step;
      Check_Frame ("special_window");

      Press (370, 440);       -- close Special
      Press (610, 240);       -- F5: Settings
      Step;
      Check_Frame ("settings_window");
      Press (563, 90);        -- Volume
      Step;
      Check_Frame ("volume_window");
      -- 11.3.7.4: a dedicated keyboard; here one key per level, so the
      -- key 7 is the volume 6
      Key (7);
      Step;
      Check_Frame ("volume_six");
      Enter_Single;           -- accepted -> back to the Settings window
      Check (General_Parameters."=" (General_Parameters.Loudspeaker_Volume, 6),
             "the accepted choice sets the volume");
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

   ---------------------------------------------------------------------
   -- Containment of internal failures (DMI_Core.Enter_Failure): nothing
   -- but the system failure symbol on a blank screen (8.2.3.1.2.1), deaf
   -- to messages and time until the DMI is restarted
   ---------------------------------------------------------------------

   procedure Scenario_Failure_Presentation is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS, L1
      Send_Speed_State (V_Cur => 100, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Check (not DMI_Core.Failed, "not failed in normal operation");

      DMI_Core.Enter_Failure;
      Step;
      Check (DMI_Core.Failed, "failure latched");
      Check_Frame ("dmi_failure");

      -- messages, touches and time change nothing
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 60, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Press (610, 40); -- F1: Main window
      Drain_Sounds;
      Step;
      Check_Frame ("dmi_failure");

      -- a restart ends it
      Reset;
      Check (not DMI_Core.Failed, "restart clears the failure");
   end Scenario_Failure_Presentation;

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
      use type EVC_Core.Mode_T;

      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

      -- The driver's actions travel back to the EVC like on the wire
      procedure Pump_To_EVC is
         use Ada.Streams;
         use DMI_Protocol;
         Buffer : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
         Last   : Stream_Element_Offset;
         Offset : Stream_Element_Offset := Buffer'First;
      begin
         DMI_Core.Take_Outbox (Buffer, Last);
         while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last loop
            declare
               The_Type : constant Msg_Type_T :=
                 Msg_Type_T (Get_U8 (Buffer, Offset));
               Length   : constant Stream_Element_Offset :=
                 Stream_Element_Offset (Get_U32 (Buffer, Offset));
               Next     : constant Stream_Element_Offset := Offset + Length;
            begin
               exit when Next - 1 > Last;
               if The_Type = MSG_DRIVER_ACTION
                 and then Length = Driver_Action_Length
               then
                  declare
                     Action : constant Interfaces.Unsigned_8 :=
                       Get_U8 (Buffer, Offset);
                     Arg    : constant Interfaces.Unsigned_16 :=
                       Get_U16 (Buffer, Offset);
                  begin
                     EVC_Core.Handle_Driver_Action
                       (Natural (Action), Natural (Arg));
                  end;
               elsif The_Type = MSG_DRIVER_DATA then
                  -- the driver's data reach the EVC, which stores them
                  -- and reports their status back (MSG_ONBOARD)
                  EVC_Core.Handle_Driver_Data
                    (Buffer (Offset .. Next - 1));
               end if;
               Offset := Next;
            end;
         end loop;
      end Pump_To_EVC;

      procedure Sim_Step is
      begin
         EVC_Driver.Auto_Drive;
         EVC_Core.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
      end Sim_Step;

      -- One cycle of the wire in both directions, as test/wasm/smoke.js
      -- replays it: the EVC talks first (the DMI decides the enabling
      -- conditions of Tables 33 to 36 on what it just heard), then the
      -- driver touches the screen, then the DMI's actions and data go
      -- back to the EVC
      procedure Touch (X, Y : Natural) is
      begin
         EVC_Driver.Auto_Drive;
         EVC_Core.Step (0.05, Emit'Unrestricted_Access);
         Pointer_Down (X, Y);
         Pointer_Up (X, Y);
         DMI_Core.Tick (50);
         Pump_To_EVC;
         Drain_Sounds;
      end Touch;


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
      -- this scenario has its own EVC: it sends MSG_ONBOARD itself
      External_EVC;

      -- a few idle steps in SB
      for I in 1 .. 5 loop
         Sim_Step;
      end loop;
      DMI_Core.Render;
      Check_Frame ("mission_sb"); -- Table 49 S1: the Driver ID window

      -- the driver's start of mission by touch (Tables 49 and 50)
      Touch (385, 240); Touch (487, 90);   -- Driver ID 1, Enter
      Touch (385, 240); Touch (487, 90);   -- Level 1 accepted -> Main
      Touch (410, 140);                     -- Train data (1/2)
      Touch (385, 240); Touch (589, 40);   -- train category PASS 1
      Touch (385, 290); Touch (487, 390); Touch (487, 390);
      Touch (589, 90);                     -- length 400
      Touch (385, 240); Touch (589, 240); Touch (487, 290);
      Touch (589, 140);                     -- brake percentage 135
      Touch (385, 240); Touch (385, 290); Touch (487, 390);
      Touch (589, 190);                     -- maximum speed 140
      Touch (539, 440);                     -- [Next] -> Train data (2/2)
      Touch (385, 240); Touch (589, 40);   -- axle load category A
      Touch (385, 340); Touch (589, 90);   -- airtight: No
      Touch (487, 290); Touch (589, 140);  -- loading gauge Out of GC
      Touch (167, 440);                     -- entry complete? Yes
      Touch (487, 40);                      -- validation 'Yes' -> TRN
      Touch (385, 240); Touch (487, 90);   -- TRN 1, Enter -> Main window
      Check (EVC_Core.Mode = EVC_Core.SB, "no mission start without Start");
      Touch (410, 90);                      -- Start -> default window

      -- mission start (the EVC grants FS with a full MA)
      Pump_To_EVC;
      Check (EVC_Core.Mode = EVC_Core.FS, "Start reaches the EVC");
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

   ---------------------------------------------------------------------
   -- SDI-5, SDI-6, SDI-7, GEN-8
   ---------------------------------------------------------------------

   -- Area (1 .. 3 = B3 .. B5, 0 = waiting) and kind of a track condition
   -- object; 99 when the DMI does not hold this id
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

   procedure Planning_Reset (V_Perm : Natural) is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 100, V_Perm => V_Perm, V_Target => 0,
                        V_Release => 0, V_Sbi => V_Perm + 15,
                        V_Wsl => V_Perm + 5,
                        D_Target => 2500, Monitoring => 0, Dial_Range => 2,
                        Vrelease_Exists => False);
   end Planning_Reset;

   -- PLN-1: 8.3.10.4 enlarges the sensitive area of D9 by 15 cells above
   -- D9, 8.3.10.5 the one of D12 by 15 cells below D12, 40x30 each. Area
   -- D starts at (334, 15): D9 is y 300 .. 314, D12 is y 15 .. 29.
   procedure Scenario_Planning_Zoom_Areas is
      use type DMI_Planning.Range_Index_T;

      procedure Tap (X, Y : Natural) is
      begin
         Pointer_Down (X, Y); Pointer_Up (X, Y);
         Step;
         Drain_Sounds;
      end Tap;
   begin
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 2500, Ceiling => 140,
                     Gradients => (0, 12),
                     Speeds => (1 => 2500, 2 => 0, 3 => 0));
      Drain_Sounds;
      Step;
      Check (DMI_Planning.Current_Range = 3, "zoom areas: starts at 0-4000");

      Tap (350, 320); -- 5 cells below area D: was sensitive before PLN-1
      Tap (350, 315);
      Check (DMI_Planning.Current_Range = 3,
             "8.3.10.4: nothing below D9 is sensitive");
      Tap (350, 284); -- 16 cells above D9
      Tap (374, 290); -- right of the 40 cell width
      Check (DMI_Planning.Current_Range = 3,
             "8.3.10.4: the sensitive area of D9 is 40x30");
      Tap (350, 285); -- 15 cells above D9: the first sensitive row
      Check (DMI_Planning.Current_Range = 2,
             "8.3.10.4: 15 cells above D9 are sensitive");
      Tap (373, 314); -- last cell of D9 itself
      Check (DMI_Planning.Current_Range = 1, "8.3.10.4: D9 is sensitive");
      Step;
      Check_Frame ("planning_zoom_1000");

      Tap (350, 45);  -- 16 cells below D12
      Tap (374, 40);
      Check (DMI_Planning.Current_Range = 1,
             "8.3.10.5: the sensitive area of D12 is 40x30");
      Tap (373, 44);  -- 15 cells below D12: the last sensitive row
      Check (DMI_Planning.Current_Range = 2,
             "8.3.10.5: 15 cells below D12 are sensitive");
      Tap (334, 15);  -- first cell of D12 itself
      Check (DMI_Planning.Current_Range = 3, "8.3.10.5: D12 is sensitive");
   end Scenario_Planning_Zoom_Areas;

   -- PLN-2: 8.3.5.6 gives '+' to an uphill and '-' to a downhill
   -- gradient; a zero gradient has no sign, only its number.
   procedure Scenario_Planning_Zero_Gradient is
   begin
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 4000, Ceiling => 140,
                     Gradients => (0, 0,  500, 5,  1000, 0,  1200, -5,
                                   2000, 0),
                     Speeds => (1 => 4000, 2 => 0, 3 => 0));
      Drain_Sounds;
      Step;
      Check_Frame ("planning_zero_gradient");
   end Scenario_Planning_Zero_Gradient;

   -- PLN-3: 8.3.7.5 to 8.3.7.9 with both examples of Figure 80.
   procedure Scenario_Planning_PASP is
   begin
      -- 140/130/120/110/60 and the zero speed target: 130, 120 and 110 share
      -- the 3/4 quarter, 60 (42 %) takes the 1/4 one, the zero speed target
      -- ends the PASP. 8.3.7.5 and 8.3.7.6 follow from the quarters of
      -- 8.3.7.7, nothing is counted.
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 3000, Ceiling => 140,
                     Speeds => (500, 130, 0,  1000, 120, 0,  1500, 110, 0,
                                2000, 60, 0,  3000, 0, 0));
      Drain_Sounds;
      Step;
      Check_Frame ("planning_pasp_three");

      -- the three widths of 8.3.7.7/.8, and a PASP that ends with a
      -- movement authority which has no zero speed target
      Send_Planning (MA_Dist => 3000, Ceiling => 140,
                     Speeds => (500, 105, 0,  1000, 70, 0,  1500, 40, 0,
                                2000, 20, 0));
      Step;
      Check_Frame ("planning_pasp_quarters");

      -- Figure 80 left: 160, then 120, 80, 60, 40 and an increase to 140
      -- which does not widen the diagram
      Planning_Reset (V_Perm => 160);
      Send_Planning (MA_Dist => 4000, Ceiling => 160,
                     Speeds => (300, 120, 0,  800, 80, 0,  1400, 60, 0,
                                1900, 40, 0,  2600, 140, 0));
      Drain_Sounds;
      Step;
      Check_Frame ("planning_pasp_fig80_left");

      -- Figure 80 right: 160, the indication target 80, increases to 120
      -- and 140, then the zero speed target
      Send_Planning (MA_Dist => 3200, Ceiling => 160, Indication => 400,
                     Speeds => (900, 80, 1,  1800, 120, 0,  2400, 140, 0,
                                3200, 0, 0));
      Step;
      Check_Frame ("planning_pasp_fig80_right");

      -- 8.3.7.9: after an increase a further decrease is not shown, the
      -- zero speed target is
      Send_Planning (MA_Dist => 3200, Ceiling => 160,
                     Speeds => (500, 100, 0,  1000, 140, 0,  1600, 30, 0,
                                2400, 0, 0));
      Step;
      Check_Frame ("planning_pasp_after_increase");
   end Scenario_Planning_PASP;

   -- PLN-4: 8.3.4.2 (and 8.3.5.2, 8.3.6.2, 8.3.7.2): within the movement
   -- authority and up to the first target at zero speed.
   procedure Scenario_Planning_Order_Limit is
   begin
      -- no zero speed target (LOA): the end of the movement authority
      -- limits; the order at 2000 m is shown, the one at 2600 m is not
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 2000, Ceiling => 140,
                     Gradients => (0, 3),
                     Speeds => (1 => 2000, 2 => 80, 3 => 0),
                     Orders => (2, 600,  5, 2000,  9, 2600,  7, 3500));
      Drain_Sounds;
      Step;
      Check (DMI_Planning.Order_Count = 4,
             "order limit: the orders beyond the MA are valid and stored");
      Check_Frame ("planning_orders_ma_limit");

      -- a zero speed target before the end of the movement authority
      -- limits orders, gradient profile and discontinuities alike
      Send_Planning (MA_Dist => 3000, Ceiling => 140,
                     Gradients => (0, 3,  1000, -4,  2000, 6),
                     Speeds => (800, 70, 0,  1500, 0, 0,  2200, 100, 0),
                     Orders => (2, 600,  5, 1500,  9, 1800,  7, 2600));
      Step;
      Check_Frame ("planning_zero_target_limit");
   end Scenario_Planning_Order_Limit;
   ---------------------------------------------------------------------
   -- Acknowledgements against the Start Up sequence and open data entry
   -- / validation windows (audit WIN-3: 5.4.1.11, 11.7.1.8, 11.7.1.9,
   -- 11.2.1.4) and the delay-type acknowledgement of MO10 (audit SDI-3:
   -- 8.2.3.1.4)
   ---------------------------------------------------------------------

   procedure Scenario_Ack_And_Windows is
      ACK_MODE_KIND  : constant := 1;
      ACK_PLAIN_KIND : constant := 3;

      function Top_Is (ID : DMI_Windows.Window_ID_T) return Boolean is
        (DMI_Windows.Is_Open
         and then DMI_Windows."=" (DMI_Windows.Top, ID));

      -- 1 s = 20 cycles of 50 ms; the cycle that set the hold was the
      -- first one
      procedure Expect_Shown_After_1_S (What : String) is
      begin
         for I in 1 .. 19 loop
            Step;
         end loop;
         Check (not DMI_Ack.Current_Valid, What & ": nothing offered for 1 s");
         Expect_No_Sound (What & ": silent for 1 s");
         Step;
         Check (DMI_Ack.Current_Valid, What & ": offered after 1 s");
         Expect_Sound (DMI_Sounds.Sinfo, What & ": the offer plays Sinfo");
      end Expect_Shown_After_1_S;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 0); -- SB: Start Up, S1
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;

      -- 11.7.1.8: required during Start Up, displayed 1 s after its end
      Send_Mode_Level (Mode => 1, Level => 0, Mode_Ack => 7); -- SR
      for I in 1 .. 30 loop
         Step;
      end loop;
      Check (DMI_Ack.Pending_Count = 1 and then not DMI_Ack.Current_Valid,
             "Start Up: the acknowledgement is required but not displayed");
      Expect_No_Sound ("Start Up: no Sinfo for the held acknowledgement");
      Check_Frame ("ack_held_in_startup");
      Pointer_Down (190, 340);   -- C1 is no button now
      Pointer_Up (190, 340);
      Step;
      Expect_No_Ack ("Start Up: nothing to acknowledge in C1");

      Press (385, 240);          -- Driver ID 1
      Press (487, 90);          -- Enter -> Level window
      Check (not DMI_Ack.Current_Valid, "S2: still held");
      Choose_Level;              -- Level 1 -> S10, the Main window
      Check (Top_Is (DMI_Windows.W_Main), "S10 reached");
      Drain_Outbox;
      Expect_Shown_After_1_S ("after Start Up");
      -- 11.2.1.4: no Main window button is enabled under the request
      Check_Frame ("ack_after_startup");
      Press (563, 190);          -- Train running number: disabled
      Check (Top_Is (DMI_Windows.W_Main),
             "no data entry starts while an acknowledgement is required");

      -- 8.2.3.1.4: the Ack-button of MO10 is a delay-type button
      Pointer_Down (190, 340);
      Expect_Sound (DMI_Sounds.Click, "MO10: the press clicks");
      for I in 1 .. 10 loop
         Step;
      end loop;
      Pointer_Up (190, 340);     -- released after 0.5 s
      Step;
      Expect_No_Ack ("MO10: a press shorter than 2 s is no acknowledgement");
      Check (DMI_Ack.Current_Valid, "MO10: still offered");
      Pointer_Down (190, 340);
      for I in 1 .. 40 loop
         Step;
      end loop;
      Pointer_Up (190, 340);     -- released after 2 s
      Step;
      Drain_Sounds;
      Expect_Ack (ACK_MODE_KIND, 0, "MO10: acknowledged by a 2 s press");
      Send_Mode_Level (Mode => 7, Level => 4); -- the EVC switches to SR

      -- 11.7.1.9: a request stops the data entry, the parent window is
      -- displayed and the request appears 1 s afterwards
      Check (Top_Is (DMI_Windows.W_Main), "Main window still open in SR");
      Press (563, 190);          -- Train running number (enabled again)
      Check (Top_Is (DMI_Windows.W_TRN), "TRN window open");
      Press (385, 240);          -- 1
      -- a short text: the picture does not depend on the line wrapping
      Send_Text (20, "SH refused", Ack_Required => True,
                 HH => 11, MM => 1);
      Step;
      Check (Top_Is (DMI_Windows.W_Main),
             "data entry stopped, parent window displayed");
      Check (not DMI_Driver_Data.TRN_Entered, "the stopped entry stores nothing");
      Check_Frame ("ack_stops_entry");
      Expect_Shown_After_1_S ("after the stopped data entry");
      Check_Frame ("ack_after_stopped_entry");
      Pointer_Down (150, 400);   -- E5-E9
      Pointer_Up (150, 400);
      Step;
      Drain_Sounds;
      Expect_Ack (ACK_PLAIN_KIND, 20, "text acknowledged under the Main window");

      -- ... and the validation process, together with its train data
      -- window (SR: the Train data button needs standstill only)
      Press (410, 140);          -- Train data
      Enter_Train_Data (Length => 1, Brake => 1, Speed => 5);
      Press (167, 440);                     -- entry complete? -> validation
      Check (Top_Is (DMI_Windows.W_Train_Data_Validation),
             "validation window open");
      Send_Status (Brake => 2);  -- brake release acknowledgement
      Step;
      Check (Top_Is (DMI_Windows.W_Main),
             "validation stopped, Main window displayed");
      Check (not DMI_Driver_Data.Train_Data_Entered,
             "the stopped validation validates nothing");
      Expect_Shown_After_1_S ("after the stopped validation");
      Drain_Outbox;
   end Scenario_Ack_And_Windows;

   Status : Natural;
   -- SDI-1: lines of the text messages (8.2.3.4.6 c) by cell width and
   -- at word boundaries, the same lines for drawing and for scrolling
   -- (8.2.3.4.7 e), a message to be acknowledged of the greatest length
   -- (8.2.3.4.8 a, b) and texts that must not stop the DMI
   procedure Scenario_Text_Wrap is
      package TM renames DMI_Text_Messages;
      use type General_Parameters.Color;

      function W (Code : Natural) return Wide_Character is
        (Wide_Character'Val (Code));

      function Line_Text (Index : Positive) return Wide_String is
         Line  : TM.Line_T;
         Valid : Boolean;
      begin
         TM.Get_Visible_Line (Index, Line, Valid);
         return (if Valid then Line.Text (1 .. Line.Length) else "<none>");
      end Line_Text;

      function Lines_Shown return Natural is
         Line   : TM.Line_T;
         Valid  : Boolean;
         Result : Natural := 0;
      begin
         for I in 1 .. TM.Visible_Lines loop
            TM.Get_Visible_Line (I, Line, Valid);
            exit when not Valid;
            Result := Result + 1;
         end loop;
         return Result;
      end Lines_Shown;

      -- Every visible line fits the width the text has (the double
      -- strike of the bold style included)
      function Lines_Fit return Boolean is
         Line  : TM.Line_T;
         Valid : Boolean;
      begin
         for I in 1 .. TM.Visible_Lines loop
            TM.Get_Visible_Line (I, Line, Valid);
            exit when not Valid;
            if Display.Draw.String_Width
                 (Line.Text (1 .. Line.Length), TM.Text_Size)
               + (if Line.Bold then TM.Bold_Extra else 0) > TM.Line_Width
            then
               return False;
            end if;
         end loop;
         return True;
      end Lines_Fit;

      -- The list from its first to its last line, read by scrolling
      -- line by line: the lines joined by Joint, and their number.
      -- Fits is False if any line seen on the way was too wide.
      Buffer : Wide_String (1 .. 4000);
      Last   : Natural;
      Count  : Natural;
      Fits   : Boolean;

      procedure Read_List (Joint : Wide_String) is
         procedure Add (Text : Wide_String) is
         begin
            if Count > 0 then
               Buffer (Last + 1 .. Last + Joint'Length) := Joint;
               Last := Last + Joint'Length;
            end if;
            Buffer (Last + 1 .. Last + Text'Length) := Text;
            Last := Last + Text'Length;
            Count := Count + 1;
         end Add;
      begin
         Last := 0;
         Count := 0;
         while TM.Can_Scroll_Up loop
            TM.Scroll_Up;
         end loop;
         Fits := Lines_Fit;
         for I in 1 .. Lines_Shown loop
            Add (Line_Text (I));
         end loop;
         while TM.Can_Scroll_Down and then Count < 300 loop
            TM.Scroll_Down;
            Fits := Fits and then Lines_Fit;
            Add (Line_Text (TM.Visible_Lines));
         end loop;
      end Read_List;

      -- No text cell in the margin at the right edge of E5-E9 (absolute
      -- 285 .. 287), which is where an over-wide line would show first
      function Margin_Clear return Boolean is
      begin
         for Y in 365 .. 464 loop
            for X in 54 + TM.Area_Width - TM.Right_Margin
                  .. 54 + TM.Area_Width - 1
            loop
               if Display.Screen.Get_Pixel (X, Y) = General_Parameters.WHITE
               then
                  return False;
               end if;
            end loop;
         end loop;
         return True;
      end Margin_Clear;

      Long_Text : constant Wide_String :=
        "Stop at the next station and wait for the written order of the "
        & "signaller before you proceed towards the junction and report "
        & "your position";

      Long_Word : constant Wide_String :=
        "Donaudampfschifffahrtsgesellschaftskapitaenswitwe";

      -- the greatest length of the protocol and of SUBSET-026 7.5.1.53
      Max_Message : Wide_String (1 .. 255);
      Phrase : constant Wide_String :=
        "Proceed on sight to the next main signal. ";

      Scrolls : Natural := 0;
   begin
      for I in Max_Message'Range loop
         Max_Message (I) := Phrase (Phrase'First + (I - 1) mod Phrase'Length);
      end loop;
      if Max_Message (Max_Message'Last) = ' ' then
         Max_Message (Max_Message'Last) := '.';
      end if;

      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      -- the case of the audit: 28 characters that are wider than the
      -- area; regular and bold
      Send_Text (1, "Level crossing not protected", HH => 9, MM => 30);
      Check (Line_Text (1) = "Level crossing not"
             and then Line_Text (2) = "protected"
             and then Line_Text (3) = "<none>",
             "a message wider than the area continues on the next line");
      Send_Text (2, "Level crossing not protected", First_Group => True,
                 HH => 9, MM => 31);
      Check (Line_Text (1) = "Level crossing not"
             and then Line_Text (2) = "protected"
             and then Line_Text (3) = "Level crossing not",
             "the same in bold style");
      Drain_Sounds;
      Step;
      Check (Lines_Fit and then Margin_Clear,
             "the lines stay inside E5-E9");
      Check_Frame ("wrap_level_crossing");

      -- a long message of several words: more lines than the area has,
      -- the list scrolls through the very lines that are drawn
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Text (1, "Entering FS", HH => 9, MM => 32);
      Send_Text (2, Long_Text, HH => 9, MM => 33);
      Check (not TM.Can_Scroll_Up and then TM.Can_Scroll_Down,
             "a message of more than five lines can be scrolled");
      Drain_Sounds;
      Step;
      Check (Margin_Clear, "long message: nothing in the right margin");
      Check_Frame ("wrap_long_top");
      Read_List (Joint => " ");
      Check (Buffer (1 .. Last) = Long_Text & " Entering FS",
             "scrolling line by line shows the whole text, word by word");
      Check (Fits and then Count > TM.Visible_Lines + 1,
             "every line of the long message fits the area");
      Check (not TM.Can_Scroll_Down and then TM.Can_Scroll_Up
             and then Line_Text (TM.Visible_Lines) = "Entering FS",
             "the list ends with the last line of the last message");
      Drain_Sounds;
      Step;
      Check (Margin_Clear, "scrolled: nothing in the right margin");
      Check_Frame ("wrap_long_scrolled");
      -- ROB-8: the long message goes while the list is scrolled to its
      -- end, the offset follows the lines that are left
      Send_Text_Remove (2);
      Check (Line_Text (1) = "Entering FS"
             and then not TM.Can_Scroll_Up
             and then not TM.Can_Scroll_Down,
             "the scroll offset follows the removal of a wrapped message");
      -- the scroll buttons work on the same lines
      Send_Text (3, Long_Text, First_Group => True, HH => 9, MM => 34);
      Drain_Sounds;
      Step; -- the buttons follow the list once per cycle
      while TM.Can_Scroll_Down and then Scrolls < 300 loop
         Pointer_Down (310, 440); Pointer_Up (310, 440); -- E11
         Step;
         Scrolls := Scrolls + 1;
      end loop;
      Read_List (Joint => " ");
      Check (Scrolls = Count - TM.Visible_Lines,
             "the [Down] button scrolls one wrapped line at a time");
      Check (Fits and then Buffer (1 .. Last) = Long_Text & " Entering FS",
             "bold: the whole text, every line inside the area");

      -- a word that is wider than a line is broken, after the words
      -- that fit; nothing is lost
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Text (1, "Halt " & Long_Word, HH => 9, MM => 35);
      Check (Line_Text (1) = "Halt", "the over-long word begins a line");
      Read_List (Joint => "");
      Check (Buffer (1 .. Last) = "Halt" & Long_Word and then Fits
             and then Count >= 3,
             "an over-long word is broken into lines that fit");
      Drain_Sounds;
      Step;
      Check (Margin_Clear, "long word: nothing in the right margin");
      Check_Frame ("wrap_long_word");

      -- a message to be acknowledged of the greatest length: alone, not
      -- scrollable (8.2.3.4.8 a, b), so the fifth line says that the
      -- text goes on
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Text (1, "Entering FS", HH => 9, MM => 36);
      Send_Text (2, Max_Message, Ack_Required => True, Class => 1,
                 HH => 9, MM => 37);
      Drain_Sounds;
      Step;
      declare
         Fifth : constant Wide_String := Line_Text (TM.Visible_Lines);
      begin
         Check (Lines_Shown = TM.Visible_Lines
                and then Fifth'Length > 3
                and then Fifth (Fifth'Last - 2 .. Fifth'Last) = "...",
                "a message to be acknowledged that does not fit ends in an "
                & "ellipsis");
      end;
      Check (Line_Text (1) = "Proceed on sight to the next" and then Lines_Fit,
             "its lines are wrapped like any other");
      Check (Margin_Clear, "ack message: nothing in the right margin");
      Check_Frame ("wrap_ack_max");
      Pointer_Down (310, 440); Pointer_Up (310, 440); -- E11 is disabled
      Step;
      Check (Line_Text (1) = "Proceed on sight to the next",
             "a message to be acknowledged cannot be scrolled");
      Pointer_Down (150, 400); Pointer_Up (150, 400); -- acknowledge
      Drain_Sounds;
      Step;
      Check (not TM.Ack_Pending and then TM.Can_Scroll_Down,
             "once acknowledged the message can be scrolled");
      Read_List (Joint => " ");
      Check (Buffer (1 .. Last) = Max_Message & " Entering FS" and then Fits,
             "all 255 characters are kept and can be read");
      while TM.Can_Scroll_Up loop
         TM.Scroll_Up;
      end loop;
      Drain_Sounds;
      Step;
      Check_Frame ("wrap_ack_max_acked");

      -- texts that must not stop the DMI, as messages and as messages
      -- to be acknowledged: empty, spaces only, one word of the widest
      -- glyph, one of characters without a glyph, spaces around a word
      for Ack in Boolean loop
         Reset;
         Send_Mode_Level (Mode => 2, Level => 4);
         Send_Text (1, "", Ack_Required => Ack);
         Step;
         Check (Lines_Shown = 1 and then Line_Text (1) = "",
                "an empty text is one empty line");
         Send_Text (1, (1 .. 255 => ' '), Ack_Required => Ack);
         Step;
         Check (Lines_Shown = 1 and then Line_Text (1) = "",
                "a text of spaces is one empty line");
         Send_Text (1, (1 .. 255 => '@'), Ack_Required => Ack);
         Step;
         Check (Lines_Shown = TM.Visible_Lines and then Lines_Fit
                and then Margin_Clear,
                "255 of the widest glyph are broken into lines that fit");
         Send_Text (1, (1 .. 255 => W (16#FF#)), Ack_Required => Ack);
         Step;
         Check (Lines_Shown = TM.Visible_Lines and then Lines_Fit
                and then Margin_Clear,
                "255 accented letters are broken the same way");
         -- 16#7F# is a C1 control: no font has a glyph for it, so every
         -- one of them is a replacement box (ROB-2)
         Send_Text (1, (1 .. 255 => W (16#7F#)), Ack_Required => Ack);
         Step;
         Check (Lines_Shown = TM.Visible_Lines and then Lines_Fit
                and then Margin_Clear,
                "255 characters without a glyph are broken the same way");
         Send_Text (1, (1 .. 120 => ' ') & "word" & (1 .. 120 => ' '),
                    Ack_Required => Ack);
         Step;
         Check (Lines_Shown = 1 and then Line_Text (1) = "word",
                "spaces around a word make no lines");
         Send_Text (1, "a  b" & (1 .. 60 => ' ') & "c", Ack_Required => Ack);
         Step;
         Check (Line_Text (1) = "a  b" and then Line_Text (2) = "c"
                and then Lines_Shown = 2,
                "the spaces at a line break are not shown");
      end loop;
      Drain_Sounds;
   end Scenario_Text_Wrap;

   ---------------------------------------------------------------------
   -- Data view window (11.5.1 with Table 45, laid out per 10.5.1): the
   -- items and their order, the two windows with [Previous] / [Next]
   -- (5.3.1.1.6 d/e, 5.3.1.2.1 g), a data part only for a valid value
   -- (10.5.1.4) and the grouping of long data (5.1.5)
   ---------------------------------------------------------------------

   procedure Scenario_Data_View is
      use DMI_Data_Format;
      use type DMI_Windows.Window_ID_T;

      procedure Set (Value : out DMI_Driver_Data.Text_Value_T;
                     Text  : Wide_String) is
      begin
         Value.Length := Text'Length;
         Value.Text (1 .. Text'Length) := Text;
      end Set;

      procedure Check_Grouped (Data : Wide_String;
                               Line : Positive;
                               Text : Wide_String;
                               What : String) is
         Blocks : constant Grouped_T := Grouped (Data);
      begin
         Check (Blocks.Count >= Line
                and then Blocks.Lines (Line).Text
                           (1 .. Blocks.Lines (Line).Length) = Text,
                What);
      end Check_Grouped;
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS, L1
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      -- 10.5.1.4: nothing is valid yet, every label stands without data
      Press (610, 140);       -- F3: Data view
      Check_Frame ("data_view_p1_no_data");

      -- 5.3.2.7.5: [Previous] is disabled on the first window and does
      -- not react to the driver
      Press (457, 440);
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Data_View,
             "[Previous] on the first data view window does nothing");
      Check_Frame ("data_view_p1_no_data");

      Set (DMI_Driver_Data.Driver_ID, "12345678");
      DMI_Driver_Data.Driver_ID_Entered := True;
      Set (DMI_Driver_Data.TRN, "5678");
      DMI_Driver_Data.TRN_Entered := True;
      DMI_Driver_Data.Train_Length := 200;
      DMI_Driver_Data.Brake_Pct := 135;
      DMI_Driver_Data.Max_Speed := 160;
      -- Table 45 items 4, 8, 9 and 10: the choices of Tables 41, 42 and
      -- of SUBSET-026 7.5.1.61 / 7.5.1.62 (audit WIN-8)
      DMI_Driver_Data.Train_Category := 1;    -- Table 41: PASS 1
      DMI_Driver_Data.Axle_Load := 1;         -- 7.5.1.62: A
      DMI_Driver_Data.Airtight := 2;          -- Table 40: Yes
      DMI_Driver_Data.Loading_Gauge := 4;     -- Table 42: GC
      DMI_Driver_Data.Train_Data_Entered := True;
      Step;
      Check_Frame ("data_view_p1");

      Check_Grouped ("12345678", 1, "1234 5678",
                     "5.1.5.1: 8 characters are shown as two groups");
      Check_Grouped ("123456", 1, "123 456",
                     "5.1.5.1: 6 characters are split as well");
      Check_Grouped ("12345", 1, "12345",
                     "5.1.5.1: 5 characters stay in one group");
      Check_Grouped ("123456789012", 1, "1234 5678",
                     "5.1.5.2: the first line holds 8 characters");
      Check_Grouped ("123456789012", 2, "9012",
                     "5.1.5.2: the rest follows on the next line");
      Check (Grouped ("").Count = 0, "an empty value has no text line");

      -- Table 45: the second window carries the topic "Radio data info"
      Press (539, 440);       -- [Next]
      Check_Frame ("data_view_p2");
      Press (539, 440);       -- 5.3.2.7.5: [Next] is disabled at the end
      Check_Frame ("data_view_p2");
      Press (457, 440);       -- [Previous]
      Check_Frame ("data_view_p1");

      -- reopening the window starts at its first window again
      Press (539, 440);       -- [Next]
      Press (370, 440);       -- [Close]
      Press (610, 140);       -- F3
      Check_Frame ("data_view_p1");
   end Scenario_Data_View;

   ---------------------------------------------------------------------
   -- DMI 5.3.2.6.4 and 5.3.2.6.5 (audit finding GEN-4). E11, the [Down]
   -- button of the text message list, is a down-type button with a
   -- repeat function (5.3.2.7.2): it goes to "pressed" and immediately
   -- back to "enabled", and after 1.5 s of holding it activates every
   -- 0.3 s "as if the driver was pressing on the button", click and
   -- press included. A Step is one 50 ms tick followed by one screen.
   procedure Scenario_Button_Down_Type is
      package TM renames DMI_Text_Messages;
      use type DMI_Buttons.Button_ID_T;

      E11_X : constant := 310; -- inside E11, as Scenario_Text_Wrap taps it
      E11_Y : constant := 440;

      function Number (N : Natural) return Wide_String is
         Img : constant Wide_String := Natural'Wide_Image (N);
      begin
         return Img (2 .. Img'Last);
      end Number;

      function Top return Wide_String is
         Line  : TM.Line_T;
         Valid : Boolean;
      begin
         TM.Get_Visible_Line (1, Line, Valid);
         return (if Valid then Line.Text (1 .. Line.Length) else "<none>");
      end Top;

      function Down_Pressed return Boolean is
        (DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_Msg_Down));
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      -- twelve one-line messages: seven scroll positions, enough for the
      -- press and several repeats
      for I in 1 .. 12 loop
         Send_Text (ID => I, Text => "Msg " & Number (I));
      end loop;
      Drain_Sounds;
      Step;
      Check (Top = "Msg 12" and then TM.Can_Scroll_Down,
             "the message list starts at its newest line");

      -- 5.3.2.6.4: click and activation on the press
      Pointer_Down (E11_X, E11_Y);
      Expect_Sound (DMI_Sounds.Click,
                    "a down-type button plays the click on the press");
      Step;
      Check (Top = "Msg 11",
             "a down-type button activates with the press (5.3.2.6.4)");
      Check (Down_Pressed,
             "and is shown pressed on the screen that follows it");
      Step;
      Check (not Down_Pressed,
             "and back in the enabled state although the finger stays on "
             & "it (5.3.2.6.4)");
      Check (Top = "Msg 11", "holding it does not activate it again");

      -- 5.3.2.6.5: the first repeat 0.3 s after the 1.5 s delay
      Drain_Sounds;
      for I in 3 .. 35 loop -- up to 1.75 s of holding
         Step;
      end loop;
      Check (Top = "Msg 11",
             "nothing repeats within the first 1.5 s + 0.3 s (5.3.2.6.5)");
      Expect_No_Sound ("and no click is played before the first repeat");
      Step; -- 1.80 s
      Check (Top = "Msg 10",
             "the repeat activates 0.3 s after the 1.5 s delay (5.3.2.6.5)");
      Check (Down_Pressed, "a repeat shows the press (5.3.2.6.5)");
      Expect_Sound (DMI_Sounds.Click,
                    "a repeat plays the click like a press (5.3.2.6.5)");
      Step;
      Check (not Down_Pressed, "and lets the button go again");
      Expect_No_Sound ("no click between two repeats");

      -- and every 0.3 s from there
      for I in 2 .. 5 loop
         Step;
      end loop;
      Check (Top = "Msg 10", "the repeats are 0.3 s apart");
      Step; -- 2.10 s
      Check (Top = "Msg 9" and then Down_Pressed,
             "the next repeat follows 0.3 s later (5.3.2.6.5)");
      Expect_Sound (DMI_Sounds.Click, "with its own click");

      -- the release ends the repeat and counts no further activation
      Pointer_Up (E11_X, E11_Y);
      Drain_Sounds;
      for I in 1 .. 20 loop
         Step;
      end loop;
      Check (Top = "Msg 9", "the release ends the repeat (5.3.2.6.4)");
      Check (not Down_Pressed, "and leaves the button enabled");
      Expect_No_Sound ("no click after the release");
      Drain_Sounds;
   end Scenario_Button_Down_Type;

   -- DMI 5.3.2.6.2: the contrast to the above. An up-type button stays
   -- in the pressed state as long as the driver keeps it pressed and is
   -- activated on the release. F1 of the default window is one (8.6.1).
   procedure Scenario_Button_Up_Type is
      use type DMI_Windows.Window_ID_T;
      F1_X : constant := 610;
      F1_Y : constant := 40;
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS, no Start Up sequence
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Step;

      Pointer_Down (F1_X, F1_Y);
      Expect_Sound (DMI_Sounds.Click,
                    "an up-type button plays the click on the press");
      Step;
      Check (DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_F1),
             "an up-type button is pressed while the driver holds it "
             & "(5.3.2.6.2)");
      for I in 1 .. 40 loop -- 2 s, past every down-type timer
         Step;
      end loop;
      Check (DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_F1),
             "and stays pressed however long it is held");
      Check (not DMI_Windows.Is_Open,
             "it is not activated before the release (5.3.2.6.2)");
      Expect_No_Sound ("an up-type button does not repeat");

      Pointer_Up (F1_X, F1_Y);
      Step;
      Check (not DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_F1),
             "the release exits the pressed state (5.3.2.6.2)");
      Check (DMI_Windows.Is_Open
             and then DMI_Windows.Top = DMI_Windows.W_Main,
             "and counts the activation");
      Drain_Sounds;
   end Scenario_Button_Up_Type;

   ---------------------------------------------------------------------
   -- WIN-2: the enabling conditions of Tables 33 to 36 (11.2.1.4,
   -- 11.2.2.4, 11.2.3.4, 11.2.4.4) and Table 48 (11.7.1.7). The on-board
   -- state comes on the wire (MSG_ONBOARD); the DMI evaluates the rows.
   ---------------------------------------------------------------------

   procedure Scenario_Enabling_Conditions is
      use type Interfaces.Unsigned_8;
      subtype U8 is Interfaces.Unsigned_8;

      --  MSG_ONBOARD bytes, see dmi_protocol.ads
      Data_All    : constant U8 := 16#0F#; -- id, train data, level, TRN valid
      Data_No_TRN : constant U8 := 16#07#;
      Standing    : constant U8 := 16#03#; -- standstill, override speed ok
      Running     : constant U8 := 16#02#; -- moving, still below the limit
      NV_Adh      : constant U8 := 16#02#; -- adhesion may be modified

      procedure Onboard (Data     : U8 := Data_All;
                         Session  : U8 := 0;
                         RBC      : U8 := 0;
                         Train    : U8 := Standing;
                         National : U8 := NV_Adh;
                         Pending  : U8 := 0) is
      begin
         Send_Onboard_Raw (Data, Session, RBC, Train, National, 0, 0, Pending);
         Step;
      end Onboard;

      function Enabled (Index : Positive) return Boolean is
        (DMI_Windows.Button_Enabled (Index));

      function Top_Is (ID : DMI_Windows.Window_ID_T) return Boolean is
        (DMI_Windows.Is_Open
         and then DMI_Windows."=" (DMI_Windows.Top, ID));

      procedure Open_Window (X, Y : Natural) is
      begin
         while DMI_Windows.Is_Open loop
            Press (370, 440);
         end loop;
         Press (X, Y);
      end Open_Window;

      F1_Main     : constant := 40;
      F2_Override : constant := 90;
      F4_Special  : constant := 190;
      F5_Settings : constant := 240;
   begin
      Reset;
      --  the scenario owns MSG_ONBOARD from here on; no start of mission
      Onboard;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Open_Window (610, F1_Main);
      Check (Top_Is (DMI_Windows.W_Main), "the Main window is on display");

      -- Table 33 #1 Start, first row: SB, all data valid, level 1
      Check (Enabled (1), "Table 33 #1: Start in SB with valid data, level 1");
      Onboard (Pending => 1);
      Check (not Enabled (1), "Table 33 #1: no Start while one is pending");
      Onboard (Train => Running);
      Check (not Enabled (1), "Table 33 #1: no Start while the train runs");
      Onboard (Data => Data_No_TRN);
      Check (not Enabled (1),
             "Table 33 #1: no Start without a valid running number");

      -- Table 33 #1 with level 2: with a session the train data have to
      -- be acknowledged by the RBC, without one they do not
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Onboard (Session => 2);
      Check (not Enabled (1),
             "Table 33 #1: level 2 with a session needs the RBC's ack");
      Onboard (Session => 2, RBC => 1);
      Check (Enabled (1), "Table 33 #1: level 2, session, train data acked");
      Onboard (Session => 0);
      Check (Enabled (1), "Table 33 #1: level 2 without a session");
      Onboard (Session => 1);
      Check (not Enabled (1),
             "Table 33 #1: a session being established is neither");
      Send_Mode_Level (Mode => 1, Level => 4); -- back to level 1
      Onboard;

      -- Table 33 #2 Driver ID, #3 Train data, #5 Level, #6 TRN in SB
      Check (Enabled (2) and then Enabled (3) and then Enabled (5)
             and then Enabled (6),
             "Table 33 #2, #3, #5, #6: enabled in SB at standstill");
      Onboard (Data => 0);
      Check (not Enabled (2) and then not Enabled (3) and then not Enabled (5)
             and then not Enabled (6),
             "Table 33 #2, #3, #5, #6: nothing without a valid Driver ID");

      -- Table 33 #3: a safe consist length that is not zero in front of
      -- the engine takes the Train data button away
      Onboard (Data => Data_All or 16#40#);
      Check (not Enabled (3),
             "Table 33 #3: no Train data with a safe consist length ahead");
      Onboard (Data => Data_All or 16#C0#);
      Check (Enabled (3),
             "Table 33 #3: Train data when that length is zero");

      -- Table 33 #7 Shunting: level 1 at standstill; #8 Non-Leading
      -- needs the "non leading" input signal
      Onboard;
      Check (Enabled (7), "Table 33 #7: Shunting in SB with level 1");
      Check (not Enabled (8),
             "Table 33 #8: no Non-Leading without the input signal");
      Onboard (Train => Standing or 16#04#);
      Check (Enabled (8), "Table 33 #8: Non-Leading with the input signal");

      -- Table 33 #2 while running: only with the national value
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Onboard (Train => Running);
      Check (not Enabled (2),
             "Table 33 #2: no Driver ID while running by default");
      Onboard (Train => Running, National => NV_Adh or 1);
      Check (Enabled (2),
             "Table 33 #2: Driver ID while running when the NV allows it");
      Check (not Enabled (1), "Table 33 #1: no Start in FS");

      -- Table 34 #1 EOA (Override window)
      Onboard;
      Open_Window (610, F2_Override);
      Check (Top_Is (DMI_Windows.W_Override), "the Override window is open");
      Check (Enabled (1), "Table 34 #1: EOA in FS below the override limit");
      Onboard (Train => 0);
      Check (not Enabled (1), "Table 34 #1: no EOA above the override limit");
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Onboard;
      Check (not Enabled (1), "Table 34 #1: no EOA in SB below level 2");
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Onboard;
      Check (Enabled (1), "Table 34 #1: EOA in SB with level 2 and the data");

      -- Table 35 (Special window)
      Send_Mode_Level (Mode => 7, Level => 4); -- SR, level 1
      Onboard;
      Open_Window (610, F4_Special);
      Check (Top_Is (DMI_Windows.W_Special), "the Special window is open");
      Check (Enabled (2), "Table 35 #2: SR speed / distance in SR");
      Check (not Enabled (3),
             "Table 35 #3: no Train integrity without an RBC session");
      Onboard (Session => 2, RBC => 16#09#, Data => Data_All or 16#20#);
      Check (Enabled (3),
             "Table 35 #3: Train integrity with the RBC's ack and the length");
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Onboard;
      Check (not Enabled (2), "Table 35 #2: no SR speed / distance outside SR");
      Check (Enabled (1), "Table 35 #1: Adhesion in FS when the NV allows it");
      Onboard (National => 0);
      Check (not Enabled (1),
             "Table 35 #1: no Adhesion when the NV forbids it");

      -- Table 36 (Settings window)
      Send_Mode_Level (Mode => 1, Level => 4); -- SB
      Onboard;
      Open_Window (610, F5_Settings);
      Check (Top_Is (DMI_Windows.W_Settings), "the Settings window is open");
      Check (Enabled (2) and then Enabled (3),
             "Table 36 #2, #3: Volume and Brightness in SB at standstill");
      Onboard (Train => Running);
      Check (not Enabled (2) and then not Enabled (3),
             "Table 36 #2, #3: nothing in SB while the train runs");
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Onboard (Train => Running);
      Check (Enabled (2) and then Enabled (3),
             "Table 36 #2, #3: enabled in FS whatever the speed");

      -- 11.7.1.7 and Table 48: an open data entry window whose button
      -- loses its enabling conditions gives way to the parent window
      Send_Mode_Level (Mode => 1, Level => 4); -- SB
      Onboard;
      Open_Window (610, F1_Main);
      Press (563, 190);                        -- Train run. nr
      Check (Top_Is (DMI_Windows.W_TRN), "the Train running number window");
      Onboard (Data => 0);                     -- the Driver ID is invalid now
      Check (Top_Is (DMI_Windows.W_Main),
             "Table 48: the TRN window gives way to the Main window");

      Onboard;
      Press (410, 140);                        -- Train data
      Check (Top_Is (DMI_Windows.W_Train_Data), "the Train data window");
      Enter_Train_Data (Length => 400, Brake => 135, Speed => 140);
      Press (167, 440);                        -- entry complete? Yes
      Check (Top_Is (DMI_Windows.W_Train_Data_Validation),
             "the train data validation window");
      Onboard (Train => Running);              -- the train starts moving
      Check (Top_Is (DMI_Windows.W_Main),
             "Table 48: the validation gives way to the Main window");
      Drain_Outbox;
   end Scenario_Enabling_Conditions;

   ---------------------------------------------------------------------
   -- WIN-11: the hour glass ST05 and the Main window with all buttons
   -- disabled while the on-board awaits an answer (11.2.1.6, Table 49
   -- S0/S4/A31, Table 50 S7/S8/S9)
   ---------------------------------------------------------------------

   procedure Scenario_Waiting_Window is
      subtype U8 is Interfaces.Unsigned_8;
      Data_All : constant U8 := 16#0F#;
      Standing : constant U8 := 16#03#;

      procedure Onboard (SOM, Waiting : U8) is
      begin
         Send_Onboard_Raw (Data_All, 0, 0, Standing, 0, SOM, Waiting, 0);
         Step;
      end Onboard;

      function Top_Is (ID : DMI_Windows.Window_ID_T) return Boolean is
        (DMI_Windows.Is_Open
         and then DMI_Windows."=" (DMI_Windows.Top, ID));
   begin
      Reset;
      Onboard (SOM => 0, Waiting => 0);
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      -- Table 49 S0: the mode is SB but a communication session is still
      -- up; the Main window comes with all buttons disabled and ST05
      Onboard (SOM => 1, Waiting => 0);
      Check (Top_Is (DMI_Windows.W_Main)
             and then DMI_Windows.Waiting_Displayed,
             "S0: the Main window is presented while the session ends");
      for I in 1 .. DMI_Windows.Button_Count loop
         Check (not DMI_Windows.Button_Enabled (I),
                "S0: Main window button" & Natural'Image (I) & " disabled");
      end loop;
      Check (not DMI_Windows.Close_Enabled, "S0: [Close] is disabled");
      Press (370, 440);
      Check (Top_Is (DMI_Windows.W_Main), "S0: [Close] does not close");
      Step;
      Check_Frame ("waiting_main_st05");

      -- 11.2.1.6: 26 cells to the right every second
      for I in 1 .. 20 loop      -- 1 s of 50 ms ticks
         Step;
      end loop;
      Check_Frame ("waiting_main_st05_moved");

      -- S0 -> S1: the conditions are fulfilled, Start Up is engaged
      Onboard (SOM => 2, Waiting => 0);
      Check (DMI_Windows.In_Start_Up
             and then Top_Is (DMI_Windows.W_Driver_ID),
             "S0 -> S1: Start Up engages with the Driver ID window");
      Check (not DMI_Windows.Waiting_Displayed, "S1: no hour glass");

      -- Table 50 S9: the on-board awaits an answer from the RBC; when it
      -- comes the Main window stays (S1)
      Onboard (SOM => 2, Waiting => 2);
      Check (Top_Is (DMI_Windows.W_Main)
             and then DMI_Windows.Waiting_Displayed,
             "S9: the Main window with all buttons disabled");
      Check (not DMI_Windows.Button_Enabled (1), "S9: Start is disabled too");
      Onboard (SOM => 2, Waiting => 0);
      Check (Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.Waiting_Displayed,
             "S9 -> S1: the Main window stays, without the hour glass");
      Check (DMI_Windows.Close_Enabled, "S1: [Close] is enabled again");

      -- Table 50 S7: after 'Start' with level 2 the MA is awaited; when
      -- it arrives the default window is shown
      Onboard (SOM => 0, Waiting => 3);
      Check (Top_Is (DMI_Windows.W_Main)
             and then DMI_Windows.Waiting_Displayed,
             "S7: the Main window with all buttons disabled");
      Onboard (SOM => 0, Waiting => 0);
      Check (not DMI_Windows.Is_Open,
             "S7: the MA leads back to the default window");

      -- an undocumented waiting code still means "an answer is awaited"
      Onboard (SOM => 0, Waiting => 200);
      Check (Top_Is (DMI_Windows.W_Main)
             and then DMI_Windows.Waiting_Displayed,
             "an unknown waiting code is read as an awaited RBC answer");
      Onboard (SOM => 0, Waiting => 0);
      Drain_Outbox;
      Drain_Sounds;
   end Scenario_Waiting_Window;

   ---------------------------------------------------------------------
   -- Input field mechanics of a data entry window (audit WIN-4:
   -- 10.3.1.19, 10.3.1.20, 10.3.1.22, 10.3.1.25, 10.3.1.26, 10.3.2.1 to
   -- 10.3.2.3, 10.3.5.13, 10.3.5.15)
   ---------------------------------------------------------------------

   procedure Scenario_Entry_Mechanics is
      use type DMI_Windows.Window_ID_T;

      -- Table 22 / Table 23 in absolute coordinates
      Merged_Field : constant := 90;          -- half grid array, y 50 .. 100
      function Field_Y (I : Positive) return Natural is (15 + (I - 1) * 50 + 25);
      Label_X : constant := 400;              -- label part, x 334 .. 538
      Data_X  : constant := 589;              -- data part,  x 538 .. 640

      function Value_Of (I : Positive) return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (I);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, valid level
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;

      -- Table 49 S1: the Driver ID window with a single input field
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID, "S1: Driver ID");
      Press (385, 240);                       -- 1
      Press (487, 240);                       -- 2
      Check (Value_Of (1) = "12", "the keys are echoed in the input field");

      -- 10.3.5.15: key 12 is the '.' button and it is disabled
      Press (589, 390);
      Check (Value_Of (1) = "12", "the disabled '.' key does nothing");

      -- 10.3.5.13: the keys of the keyboard are down-type buttons, so
      -- the value is entered with the press, not with the release
      Pointer_Down (589, 240);                -- 3
      Step;
      Check (Value_Of (1) = "123", "a down-type key enters with the press");
      Pointer_Up (589, 240);
      Step;
      Check (Value_Of (1) = "123", "the release of a down-type key adds nothing");
      Drain_Sounds;

      -- 10.3.1.22: the [Enter] button is the data field itself
      Press (487, Merged_Field);
      Check (DMI_Windows.Top = DMI_Windows.W_Level,
             "the data field accepts the value (10.3.1.22)");
      Check (DMI_Driver_Data.Driver_ID.Length = 3
             and then DMI_Driver_Data.Driver_ID.Text (1 .. 3) = "123",
             "the accepted value is stored");
      Drain_Outbox;

      -- a window with several input fields: the train data window
      Choose_Level;                           -- Level 1 -> S10, Main window
      Press (410, 140);                       -- Train data
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data, "train data open");

      -- 10.3.1.23: the first input field is selected; Figure 120 puts
      -- the train category there, with the dedicated keyboard of Table 41
      Key (1);
      Check (Value_Of (1) = "PASS 1",
             "one key of a dedicated keyboard carries the whole choice");
      -- 10.3.5.19: with more than 12 predefined choices the key 12 is
      -- the [More] button and the keys 1 to 11 take the next group
      Key (12);
      Key (1);
      Check (Value_Of (1) = "FP 2",
             "[More] shows the next group of predefined choices");
      Key (12);
      Key (1);
      Check (Value_Of (1) = "PASS 1",
             "the list of predefined choices is circular");
      Enter_Field (1);                        -- accepted -> field 2

      -- 10.3.1.26: another input field is selected by its label part;
      -- 10.3.1.20: the value entered without accepting it is erased
      Press (385, 240); Press (487, 240);     -- 12 into field 2
      Check (Value_Of (2) = "12", "field 2 takes the keys");
      Press (Label_X, Field_Y (3));
      Check (Value_Of (2) = "", "an entry left without accepting is erased");
      Press (385, 240);                       -- 1 into field 3
      Check (Value_Of (3) = "1", "field 3 is the selected one now");

      -- 10.3.1.26: the data part of an input field that is not selected
      -- selects it as well
      Press (Data_X, Field_Y (4));
      -- the maximum speed has a resolution of 5 km/h (10.3.4.3,
      -- SUBSET-026 7.5.1.160 V_MAXTRAIN)
      Press (487, 290);                       -- 5 into field 4
      Check (Value_Of (4) = "5" and then Value_Of (3) = "",
             "the data part of another field selects it");

      -- 10.3.1.24 / 10.3.1.25: accepting the last input field selects
      -- the first one again, the list is circular
      Press (Data_X, Field_Y (4));
      Key (2);                                -- 'PASS 2' into field 1
      Check (Value_Of (1) = "PASS 2" and then Value_Of (4) = "5",
             "the field after the last one is the first one");

      -- 10.3.1.19: the first key press replaces the data value
      Enter_Field (1);                        -- accepted -> field 2
      Press (385, 240); Press (487, 240);     -- 12 into the length
      Enter_Field (2);                        -- accepted -> field 3
      Press (Data_X, Field_Y (2));            -- the length again
      Press (589, 240);                       -- 3
      Check (Value_Of (2) = "3", "the first key replaces the data value");

      -- 10.3.2.3: the cursor flashes at 2 Hz (5 cycles of 50 ms)
      Step;
      Check_Frame ("entry_cursor_visible");
      for I in 1 .. 5 loop
         Step;
      end loop;
      Check_Frame ("entry_cursor_hidden");
      for I in 1 .. 5 loop
         Step;
      end loop;
      Check_Frame ("entry_cursor_visible");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Entry_Mechanics;

   ---------------------------------------------------------------------
   -- Data validation window (audit WIN-7: 10.4.1.1 to 10.4.1.5, Table
   -- 29, 10.3.5.18, 11.4.1)
   ---------------------------------------------------------------------

   procedure Scenario_Validation_Window is
      use type DMI_Windows.Window_ID_T;
      Key_No  : constant := 385;   -- Table 29 / Table 25 key 7, y 300
      Key_Yes : constant := 487;   -- key 8
      Field_Y : constant := 40;    -- Table 29: the input field at y 0

      function Value_Of return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (1);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;

      Press (385, 240); Press (487, 90);      -- Driver ID 1
      Choose_Level;                           -- Level 1 -> Main window
      Press (410, 140);                       -- Train data
      Enter_Train_Data (Length => 1, Brake => 1, Speed => 5);
      Press (167, 440);                       -- entry complete? -> validation
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data_Validation,
             "the validation window is open");

      -- Figure 105: the input field proposes 'Yes'
      Check (Value_Of = "Yes", "the input field proposes 'Yes'");
      Step;
      Check_Frame ("validation_window");

      -- 10.3.5.18: key 7 is 'No', key 8 is 'Yes'; 10.4.1.2 / 10.3.1.22:
      -- the choice has to be accepted on the data field
      Press (Key_No, 340);
      Check (Value_Of = "No", "the 'No' key writes the choice in the field");
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data_Validation,
             "a key press alone does not leave the validation window");
      Press (Key_Yes, Field_Y);               -- the data field is [Enter]
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "'No' accepted returns to the train data window (Table 50 S3-2)");
      Check (not DMI_Driver_Data.Train_Data_Entered,
             "'No' validates nothing");

      -- Table 50 S3-1 entered from S3-2: the first window of the topic
      -- with the data values of the previous S3-1 proposed
      Check (DMI_Data_Entry.Value (2).Length = 1
             and then DMI_Data_Entry.Value (2).Text (1) = '1',
             "the values of the previous S3-1 are proposed again");

      -- and once more with the proposed 'Yes'
      Press (167, 440);                       -- entry complete? -> validation
      Press (Key_Yes, Field_Y);
      Check (DMI_Driver_Data.Train_Data_Entered, "'Yes' validates the data");
      Check (DMI_Driver_Data.Train_Length = 1
             and then DMI_Driver_Data.Max_Speed = 5,
             "the validated values are the ones stored on board");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Validation_Window;

   ---------------------------------------------------------------------
   -- Data checks of a data entry window (audit WIN-5: 10.3.4.2 to
   -- 10.3.4.7, Figure 98, 5.3.2.7.3)
   ---------------------------------------------------------------------

   procedure Scenario_Data_Checks is
      use type DMI_Windows.Window_ID_T;
      use type DMI_Data_Entry.Cross_Kind_T;

      Data_X : constant := 589;   -- the data parts of Table 23
      function Field_Y (I : Positive) return Natural is (15 + (I - 1) * 50 + 25);

      function Value_Of (I : Positive) return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (I);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;

      -- a delay-type activation: 2 s of pressing (5.3.2.6.6)
      procedure Long_Press (X, Y : Natural) is
      begin
         Pointer_Down (X, Y);
         for I in 1 .. 41 loop
            Step;
         end loop;
         Pointer_Up (X, Y);
         Step;
         Drain_Sounds;
      end Long_Press;

      procedure Short_Press (X, Y : Natural) is
      begin
         Pointer_Down (X, Y);
         for I in 1 .. 10 loop
            Step;
         end loop;
         Pointer_Up (X, Y);
         Step;
         Drain_Sounds;
      end Short_Press;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;
      Press (385, 240); Press (487, 90);      -- Driver ID 1
      Choose_Level;                           -- Level 1 -> Main window
      Press (410, 140);                       -- Train data (1/2)
      Key (1); Enter_Field (1);               -- train category PASS 1

      -- 10.3.4.2: 5000 m is outside the range of L_TRAIN (0 .. 4095 m,
      -- SUBSET-026 7.5.1.56)
      Press (487, 290); Press (487, 390);     -- 5, 0
      Press (487, 390); Press (487, 390);     -- 0, 0
      Press (Data_X, Field_Y (2));            -- [Enter]
      Check (Value_Of (2) = "5000",
             "the input field out of range still shows the entered value");
      Step;
      Check_Frame ("entry_check_technical");

      -- 10.3.4.2.4: [Enter] is disabled until a key is pressed; the
      -- input field stays selected, so [Delete] works on its entry
      Press (Data_X, Field_Y (2));
      Press (385, 390);                       -- [Delete]
      Check (Value_Of (2) = "500" and then Value_Of (3) = "",
             "the disabled [Enter] accepted nothing");
      Press (Data_X, Field_Y (2));            -- 500 m is in range

      -- 10.3.4.3: 141 km/h does not match the 5 km/h resolution of
      -- V_MAXTRAIN (SUBSET-026 7.5.1.160)
      Press (Data_X, Field_Y (4));            -- select the maximum speed
      Press (385, 240); Press (385, 290); Press (385, 240);  -- 141
      Press (Data_X, Field_Y (4));            -- [Enter]
      Check (Value_Of (4) = "141", "the wrong resolution is not accepted");
      Press (385, 390);                       -- a key re-enables [Enter]
      Press (487, 390);                       -- 140
      Press (Data_X, Field_Y (4));
      Check (Value_Of (4) = "140", "140 km/h matches the resolution");

      -- 10.3.4.5: the operational range check; zero is not a nominal
      -- value for a train length (configuration of the DMI)
      Press (Data_X, Field_Y (2));            -- select the length
      Press (487, 390);                       -- 0
      Press (Data_X, Field_Y (2));            -- [Enter]
      Step;
      Check_Frame ("entry_check_operational");
      -- 10.3.4.5.5: [Enter] became a delay-type button
      Short_Press (Data_X, Field_Y (2));
      Press (385, 290);                       -- 4 is appended to the entry
      Check (Value_Of (2) = "04" and then Value_Of (3) = "",
             "a press shorter than 2 s does not overrule the check");
      -- 10.3.1.20: leaving the field without accepting erases the entry
      Press (Data_X, Field_Y (3));
      Press (Data_X, Field_Y (2));
      Press (385, 290); Press (487, 390); Press (487, 390);  -- 400
      Press (Data_X, Field_Y (2));            -- accepted -> field 3
      Press (385, 240); Press (487, 390); Press (487, 390);  -- 100
      Press (Data_X, Field_Y (3));
      Check (Value_Of (2) = "400" and then Value_Of (3) = "100"
             and then Value_Of (4) = "140",
             "every input field displays a data value");

      -- 10.3.5.9: the items of the second window as well, otherwise the
      -- 'Yes' button of the question stays disabled (Table 50 S3-1)
      Press_Next;
      Key (1); Enter_Field (1);               -- axle load category A
      Key (7); Enter_Field (2);               -- airtight: No
      Key (5); Enter_Field (3);               -- loading gauge Out of GC
      Press_Previous;
      Check (Value_Of (2) = "400" and then Value_Of (4) = "140",
             "the process keeps the values over [Next] and [Previous]");

      -- 10.3.4.4: a technical cross-check rule that is not satisfied
      -- ('length not greater than maximum speed' is nonsense as a rule,
      -- it only has to fail: no cross-check rule is configured)
      DMI_Data_Entry.Cross_Rules (1) :=
        (Kind => DMI_Data_Entry.Technical_Cross, A => 2, B => 4,
         Relation => DMI_Data_Entry.Not_Greater);
      Press (167, 440);                       -- 'Yes' of the question
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "the failed technical cross-check does not complete the entry");
      Step;
      Check_Frame ("entry_check_cross");
      -- 10.3.4.4.4: 'Yes' stays disabled until a value is modified
      Press (167, 440);
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "the disabled 'Yes' does not react");

      -- 10.3.4.6: the same rule as an operational one is overruled by a
      -- valid activation of the delay-type 'Yes'
      DMI_Data_Entry.Cross_Rules (1).Kind := DMI_Data_Entry.Operational_Cross;
      Press (Data_X, Field_Y (2));            -- select the length
      Press (487, 290); Press (487, 390); Press (487, 390);  -- 500
      Press (Data_X, Field_Y (2));            -- accepted: 'Yes' enabled
      Press (167, 440);
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "the failed operational cross-check does not complete either");
      Short_Press (167, 440);
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "a press shorter than 2 s does not overrule the cross-check");
      Long_Press (167, 440);
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data_Validation,
             "the delay-type 'Yes' overrules the operational cross-check");

      DMI_Data_Entry.Cross_Rules := (others => (others => <>));
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Data_Checks;

   ---------------------------------------------------------------------
   -- Dedicated keyboards on the half grid array (audit WIN-10): Level
   -- (11.3.2), Adhesion (11.3.11), Volume (11.3.7) and Brightness
   -- (11.3.8) are data entry windows with one input field, a list of
   -- predefined choices (10.3.5.19) and an acceptance step
   ---------------------------------------------------------------------

   procedure Scenario_Dedicated_Keyboards is
      use type DMI_Windows.Window_ID_T;

      function Value_Of return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (1);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 0); -- SB, level unknown
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;

      -- Table 49 S1 -> S2: the Level window of 11.3.2
      Press (385, 240); Press (487, 90);      -- Driver ID 1
      Check (DMI_Windows.Top = DMI_Windows.W_Level, "the Level window");
      -- 11.7.1.4: with an unknown level nothing is proposed
      Check (Value_Of = "", "an unknown level proposes no value");

      -- Table 38: the buttons 1, 2 and 4 are reserved for the levels 1,
      -- 2 and 0, the button 3 carries no choice at all
      Check (DMI_Windows.Button_Enabled (1)
             and then DMI_Windows.Button_Enabled (2)
             and then DMI_Windows.Button_Enabled (4)
             and then DMI_Windows.Button_Enabled (5),
             "Table 38: the levels 1, 2, 0 and NTC are on offer");
      Check (not DMI_Windows.Button_Enabled (3),
             "Table 38: the button 3 carries no choice");
      Check (not DMI_Windows.Button_Enabled (6),
             "11.3.2.8: no button beyond the configured list of levels");

      -- 10.3.1.19: the choice is displayed instead of the data value;
      -- 10.3.1.22: it becomes the data value on the input field
      Key (4);
      Check (Value_Of = "Level 0", "the button 4 writes 'Level 0'");
      Check (DMI_Windows.Top = DMI_Windows.W_Level,
             "a key press alone does not leave the window");
      Key (3);
      Check (Value_Of = "Level 0", "the button without a choice does nothing");
      Key (2);
      Check (Value_Of = "Level 2", "another choice replaces the value");
      Enter_Single;
      Check (not DMI_Windows.In_Start_Up,
             "the accepted level ends the Start Up sequence (Table 49 S2)");
      Expect_Actions (11, 1, "the accepted level is sent to the EVC");

      -- 11.7.1.4: reopened, the window proposes the level stored on board
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Press (410, 190);                        -- Main window: Level
      Check (DMI_Windows.Top = DMI_Windows.W_Level, "the Level window again");
      Check (Value_Of = "Level 2",
             "11.7.1.4: the level stored on board is proposed");
      Press (370, 440);                        -- [Close]

      -- 11.3.11.4, Table 43: the Adhesion window. Table 35 #1 offers it
      -- in FS without further conditions.
      Press (370, 440);                        -- close the Main window
      Send_Mode_Level (Mode => 2, Level => 5); -- FS
      Press (610, 190);                        -- F4: Special window
      Press (410, 90);                         -- Adhesion
      Check (DMI_Windows.Top = DMI_Windows.W_Adhesion, "the Adhesion window");
      Key (1);
      Check (Value_Of = "Non slippery rail", "Table 43: the button 1");
      Enter_Single;
      Check (DMI_Windows.Top = DMI_Windows.W_Special,
             "10.6.1.2 a: the accepted value leaves the window");
      Expect_Actions (9, 1, "the accepted adhesion is sent to the EVC");

      -- 11.3.8: the Brightness window, one key per level of luminance
      Press (370, 440);                        -- close Special
      Press (610, 240);                        -- F5: Settings
      Press (410, 140);                        -- Brightness
      Check (DMI_Windows.Top = DMI_Windows.W_Brightness,
             "the Brightness window");
      Check (Value_Of = "5", "11.7.1.4: the stored luminance is proposed");
      Key (9);                                 -- the level 8
      Enter_Single;
      Check (General_Parameters."="
               (General_Parameters.Display_Luminance, 8),
             "the accepted choice sets the luminance");
      Check (DMI_Windows.Top = DMI_Windows.W_Settings,
             "accepting the luminance leaves the window");

      -- 11.7.1.9 and Table 48: the four windows are data entry windows,
      -- so a required acknowledgement stops their process (audit WIN-3)
      Press (410, 140);                        -- Brightness again
      Check (DMI_Windows.Entry_Open,
             "Table 48: Brightness is a data entry window");
      DMI_Windows.Stop_Entry;
      Check (DMI_Windows.Top = DMI_Windows.W_Settings,
             "11.7.1.9: the stopped entry shows the parent window");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Dedicated_Keyboards;

   ---------------------------------------------------------------------
   -- Train data window(s) of the flexible train data entry (audit
   -- WIN-8: 11.3.9.6 b, Table 40, Figures 120 and 121, 11.7.1.6.1) and
   -- what MSG_DRIVER_DATA carries to the EVC
   ---------------------------------------------------------------------

   procedure Scenario_Train_Data_Windows is
      use type DMI_Windows.Window_ID_T;
      use Ada.Streams;
      use DMI_Protocol;

      -- the last MSG_DRIVER_DATA of kind 2 (the train data of Table 40)
      Train_Msg : Stream_Element_Array
        (1 .. Stream_Element_Offset (Driver_Data_Train_Length)) :=
          (others => 0);
      Train_Msg_Len : Natural := 0;

      procedure Collect_Train_Data is
         Buffer : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
         Last   : Stream_Element_Offset;
         Offset : Stream_Element_Offset := Buffer'First;
      begin
         Train_Msg_Len := 0;
         DMI_Core.Take_Outbox (Buffer, Last);
         while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last loop
            declare
               The_Type : constant Msg_Type_T :=
                 Msg_Type_T (Get_U8 (Buffer, Offset));
               Length   : constant Stream_Element_Offset :=
                 Stream_Element_Offset (Get_U32 (Buffer, Offset));
               Next     : constant Stream_Element_Offset := Offset + Length;
            begin
               exit when Next - 1 > Last;
               if The_Type = MSG_DRIVER_DATA
                 and then Length = Stream_Element_Offset
                                     (Driver_Data_Train_Length)
                 and then Natural (Buffer (Offset)) = 2
               then
                  Train_Msg_Len := Natural (Length);
                  Train_Msg := Buffer (Offset .. Next - 1);
               end if;
               Offset := Next;
            end;
         end loop;
      end Collect_Train_Data;

      function Byte (I : Positive) return Natural is
        (Natural (Train_Msg (Stream_Element_Offset (I))));

      function Word (I : Positive) return Natural is
        (Byte (I) + Byte (I + 1) * 256);

      function Value_Of (I : Positive) return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (I);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;

      Press (385, 240); Press (487, 90);      -- Driver ID 1
      Choose_Level;                           -- Level 1 -> Main window
      Press (410, 140);                       -- Train data (1/2)
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data,
             "the first train data window");

      -- 10.3.1.20 read for a window change: an entry that was not
      -- accepted is lost with the window
      Key (2);                                -- 'PASS 2'
      Press_Next;
      Press_Previous;
      Check (Value_Of (1) = "",
             "a window change drops the entry that was not accepted");

      Enter_Train_Data (Length => 250, Brake => 96, Speed => 120);
      -- 10.3.5.19 on the second window: 13 axle load categories
      -- (SUBSET-026 7.5.1.62) need the [More] button of the key 12
      Press_Next;
      Key (12);
      Key (2);
      Check (Value_Of (1) = "E5",
             "[More] reaches the 13th axle load category");
      Enter_Field (1);
      Press_Previous;
      -- Table 50 S3-1: the values survive [Previous] and [Next]
      Check (Value_Of (2) = "250" and then Value_Of (4) = "120",
             "the process keeps the values of the first window");

      -- 11.7.1.6.1: pressing 'Yes' stores nothing on board
      Press (167, 440);                       -- entry complete? Yes
      Check (DMI_Windows.Top = DMI_Windows.W_Train_Data_Validation,
             "the validation window follows (Table 50 S3-2)");
      Check (not DMI_Driver_Data.Train_Data_Entered
             and then DMI_Driver_Data.Train_Length = 0,
             "11.7.1.6.1: nothing is stored before the validation");
      -- the outbox is read here, before the test wrapper drains it with
      -- the sounds, so that MSG_DRIVER_DATA can be inspected
      Pointer_Down (487, 40); Pointer_Up (487, 40);
      DMI_Core.Tick (50);
      Collect_Train_Data;
      DMI_Core.Render;
      Check (DMI_Driver_Data.Train_Data_Entered
             and then DMI_Driver_Data.Train_Length = 250
             and then DMI_Driver_Data.Brake_Pct = 96
             and then DMI_Driver_Data.Max_Speed = 120,
             "the validated values are stored on board");

      -- MSG_DRIVER_DATA kind 2: the seven items of Table 40 as the
      -- ERTMS/ETCS variables of SUBSET-026 chapter 7
      Check (Train_Msg_Len = Driver_Data_Train_Length,
             "the train data message carries the seven items");
      Check (Word (2) = 250 and then Word (4) = 96 and then Word (6) = 120,
             "length, brake percentage and maximum speed on the wire");
      Check (Byte (8) = 0 and then Word (9) = 4,
             "Table 41 PASS 1: NC_CDTRAIN 0, NC_TRAIN passenger train");
      Check (Byte (11) = 12, "M_AXLELOADCAT 12 is E5");
      Check (Byte (12) = 0, "M_AIRTIGHT 0: no airtight system fitted");
      Check (Byte (13) = 0, "M_LOADINGGAUGE 0: out of the profiles");

      -- Table 45: the data view window shows what was stored
      Press (370, 440);                       -- close the TRN window
      Press (370, 440);                       -- close the Main window
      Press (610, 140);                       -- F3: Data view
      Step;
      Check_Frame ("data_view_train_data");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Train_Data_Windows;

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
   Scenario_BMM_Inhibition;
   Scenario_Text_Unknown_Glyphs;
   Scenario_SM_Direction;
   Scenario_Text_Messages;
   Scenario_Ack_Same_Class;
   Scenario_Ack_Arrival_Order;
   Scenario_Ack_Revoked;
   Scenario_Ack_Remove_One;
   Scenario_Ack_Queue_Full;
   Scenario_Planning;
   Scenario_Planning_Malformed;
   Scenario_Planning_Overflow;
   Scenario_Sound_Overflow;
   Scenario_Text_Store;
   Scenario_Startup_Sequence;
   Scenario_Other_Windows;
   Scenario_EVC_Link_Lost;
   Scenario_Failure_Presentation;
   Scenario_Mission;
   Scenario_Supervision_Sounds;
   Scenario_TC_Areas_Kept;
   Scenario_Level_NTC_In_C8;
   Scenario_Level_Ann_Acknowledged;
   Scenario_Flash_Starts_Visible;
   Scenario_Planning_Zoom_Areas;
   Scenario_Planning_Zero_Gradient;
   Scenario_Planning_PASP;
   Scenario_Planning_Order_Limit;
   Scenario_Text_Wrap;
   Scenario_Ack_And_Windows;
   Scenario_Data_View;
   Scenario_Button_Down_Type;
   Scenario_Button_Up_Type;
   Scenario_Enabling_Conditions;
   Scenario_Waiting_Window;
   Scenario_Entry_Mechanics;
   Scenario_Validation_Window;
   Scenario_Data_Checks;
   Scenario_Dedicated_Keyboards;
   Scenario_Train_Data_Windows;

   Status := Summary;
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Exit_Status (Status));
end DMI_Test;
