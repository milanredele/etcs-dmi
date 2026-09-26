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
with DMI_ATO;
with DMI_Buttons;
with DMI_Core;
with DMI_Data_Format;
with Display.A_Area;
with Display.B_Area;
with Display.Draw;
with Display.Screen.Files;
with DMI_Data_Entry;
with DMI_Data_View;
with DMI_Driver_Data;
with DMI_Flash;
with DMI_Planning;
with DMI_Protocol;
with DMI_Radio_Data;
with DMI_Sounds;
with DMI_Status;
with DMI_System_Status;
with DMI_System_Version;
with DMI_Text_Messages;
with DMI_Texts;
with DMI_Train_Data;
with DMI_VBC;
with DMI_Windows;
with EVC_ATO;
with EVC_Core;
with EVC_Driver;
with EVC_Track;
with EVC_Train;
with Font.FreeSans_10;
with Font.FreeSans_12;
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
                                    when 0 => 0, when 1 => 1, when 2 => 139,
                                    when 3 => 140, when 4 => 65534,
                                    when others => 65535),
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

      -- Every visible line fits the width the text has, measured with
      -- the font it is drawn with (bold for the first group)
      function Lines_Fit return Boolean is
         Line  : TM.Line_T;
         Valid : Boolean;
      begin
         for I in 1 .. TM.Visible_Lines loop
            TM.Get_Visible_Line (I, Line, Valid);
            exit when not Valid;
            if Display.Draw.String_Width
                 (Line.Text (1 .. Line.Length), TM.Text_Size,
                  Bold => Line.Bold) > TM.Line_Width
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
      -- SB with the level unknown, so that Table 49 D2 leads to S2
      Send_Mode_Level (Mode => 1, Level => 0);
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
      -- the level is unknown, so that Table 49 D2 leads to the Level window
      Send_Mode_Level (Mode => 1, Level => 0); -- SB
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
      -- the level is unknown, so that Table 49 D2 leads to the Level window
      Send_Mode_Level (Mode => 1, Level => 0); -- SB
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
   -- The alphanumeric keyboard of the Driver ID window (audit WIN-9:
   -- 11.3.3.4 to 11.3.3.7, 10.3.5.17, 10.3.2.5, 11.6.1.2, 11.7.2.2),
   -- the 5 character grouping of the entered data (audit GEN-6,
   -- 10.3.2.6 with 5.1.5) and the repeat function of the keys
   -- (5.3.2.6.5, 5.3.2.7.2)
   ---------------------------------------------------------------------

   procedure Scenario_Alphanumeric_Entry is
      use type DMI_Windows.Window_ID_T;

      Enter_Y : constant := 90;    -- Table 22: the merged data part
      Col_1   : constant := 385;   -- Table 25: the three key columns
      Col_2   : constant := 487;
      Col_3   : constant := 589;
      Row_1   : constant := 240;   -- Table 25: the four key rows
      Row_2   : constant := 290;
      Row_4   : constant := 390;
      Close_X : constant := 370;
      TRN_X   : constant := 517;   -- 11.3.3.7 a: (142,400), 82 x 50
      Set_X   : constant := 599;   -- 11.3.3.6 a: (224,400), 82 x 50
      Btn_Y   : constant := 440;

      function Value_Of return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (1);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;

      -- 10.3.2.5 a: let the 2 s delay-time run out
      procedure Wait_Tap is
      begin
         for I in 1 .. 41 loop
            Step;
         end loop;
      end Wait_Tap;
   begin
      Reset;
      -- SB with the level unknown, so that the sequence stays in S1
      Send_Mode_Level (Mode => 1, Level => 0);
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "Table 49 S1: the Driver ID window");

      -- 10.3.5.17 / 11.3.3.4: the key 2 of the alphanumeric keyboard
      -- carries '2', 'a', 'b' and 'c'; 10.3.2.5 b: the same key again
      -- within the 2 s delay-time selects the next one
      Press (Col_2, Row_1);
      Check (Value_Of = "2", "the first press enters the number of the key");
      Press (Col_2, Row_1);
      Check (Value_Of = "a", "the same key again selects the next character");
      Press (Col_2, Row_1);
      Press (Col_2, Row_1);
      Check (Value_Of = "c", "and so on through the letters of the key");
      Press (Col_2, Row_1);
      Check (Value_Of = "2", "the characters of one key are circular");

      -- 10.3.2.5 a: after the 2 s the cursor has jumped by itself
      Wait_Tap;
      Press (Col_2, Row_1);
      Check (Value_Of = "22",
             "after the 2 s delay-time the same key enters a new character");

      -- 10.3.2.5 c: another data key makes the cursor jump directly
      Press (Col_3, Row_1);
      Check (Value_Of = "223", "another data key jumps to the next position");
      Press (Col_3, Row_1);
      Check (Value_Of = "22d", "and starts its own selection there");

      -- 5.3.2.7.1 e: [Delete] removes the just entered character
      Press (Col_1, Row_4);
      Check (Value_Of = "22", "[Delete] removes the entered character");
      Press (Col_1, Row_4);
      Press (Col_1, Row_4);
      Check (Value_Of = "", "and the input field is empty again");

      -- 10.3.5.17: the key 12 shows the '.' as disabled, the key 11 is
      -- the number '0' and the key 1 the number '1' alone
      Press (Col_3, Row_4);
      Check (Value_Of = "", "the disabled '.' key does nothing");
      Press (Col_1, Row_1);
      Press (Col_1, Row_1);
      Check (Value_Of = "11", "a key with one character enters it twice");
      Press (Col_2, Row_4);
      Check (Value_Of = "110", "the key 11 is the number '0'");
      Press (Col_1, Row_4);
      Press (Col_1, Row_4);
      Press (Col_1, Row_4);

      -- 10.3.2.6 with 5.1.5.1: from the 6th character on, a single space
      -- splits the data into two groups of at most 5 characters
      Press (Col_1, Row_1); Press (Col_2, Row_1); Press (Col_3, Row_1);
      Press (Col_1, Row_2); Press (Col_2, Row_2); Press (Col_3, Row_2);
      Check (Value_Of = "123456", "six characters are entered");
      Step;
      Check_Frame ("driver_id_grouped");     -- '123 456'

      -- 5.1.5.2: a line break every 8 characters
      Press (Col_1, Row_1); Press (Col_2, Row_1); Press (Col_3, Row_1);
      Check (Value_Of = "123456123",
             "SUBSET-026 A.3.11: the Driver ID takes up to 16 characters");
      Step;
      Check_Frame ("driver_id_two_lines"); -- '1234 5612' / '3'

      -- 5.3.2.6.5 / 5.3.2.7.2: the repeat function is a property of the
      -- button. A key that enters one single character does not repeat.
      Press (Col_1, Row_4); Press (Col_1, Row_4); Press (Col_1, Row_4);
      Press (Col_1, Row_4); Press (Col_1, Row_4); Press (Col_1, Row_4);
      Press (Col_1, Row_4); Press (Col_1, Row_4); Press (Col_1, Row_4);
      Check (Value_Of = "", "the input field is empty again");
      Pointer_Down (Col_1, Row_1);
      for I in 1 .. 60 loop                 -- 3 s, past every repeat
         Step;
      end loop;
      Pointer_Up (Col_1, Row_1);
      Step;
      Drain_Sounds;
      Check (Value_Of = "1",
             "a data key with one character does not repeat (5.3.2.6.5)");

      -- 10.3.2.5 b: holding a data key selects another character under it
      Press (Col_1, Row_4);
      Pointer_Down (Col_2, Row_1);
      Step;
      Check (Value_Of = "2", "the press enters the number of the key");
      for I in 1 .. 39 loop                 -- 1.5 s + one 0.3 s repeat
         Step;
      end loop;
      Pointer_Up (Col_2, Row_1);
      Step;
      Drain_Sounds;
      Check (Value_Of = "a",
             "holding a data key selects another character (10.3.2.5 b)");
      Press (Col_1, Row_4);

      -- 11.3.3.7 / Table 49 S1-2: the 'TRN' button leads to the Train
      -- running number window, whose parent is the Driver ID window
      -- (11.6.1.2); 11.7.2.2: [Close] is enabled in S1-2
      Press (TRN_X, Btn_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_TRN,
             "S1: the 'TRN' button leads to S1-2");
      Check (DMI_Windows.Close_Enabled, "S1-2: [Close] is enabled");
      Press (Close_X, Btn_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "S1-2: [Close] comes back to S1");
      Press (TRN_X, Btn_Y);
      Press (Col_1, Row_1);                 -- 1
      Press (Col_2, Enter_Y);               -- [Enter]: E1-2 -> S1
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "E1-2: the entered train running number comes back to S1");
      Check (DMI_Driver_Data.TRN.Length = 1
             and then DMI_Driver_Data.TRN.Text (1 .. 1) = "1",
             "and is stored");

      -- 11.3.3.6 / Table 49 S1-1: the 'settings' button leads to the
      -- Settings window, [Close] enabled there too
      Press (Set_X, Btn_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_Settings,
             "S1: the 'settings' button leads to S1-1");
      Check (DMI_Windows.Close_Enabled, "S1-1: [Close] is enabled");
      Press (Close_X, Btn_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "E1-1: [Close] comes back to S1");

      -- 11.7.2.2: in S1 itself [Close] stays disabled
      Check (not DMI_Windows.Close_Enabled, "S1: [Close] is disabled");
      Press (Close_X, Btn_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_Driver_ID,
             "S1: the disabled [Close] does not close the window");

      -- Table 49 E1 -> D2: the level is not valid, so the procedure goes
      -- to S2 whatever the DMI's own record of the entry says
      Press (Col_1, Row_1);
      Press (Col_2, Enter_Y);
      Check (DMI_Windows.Top = DMI_Windows.W_Level,
             "D2: an invalid level leads to S2");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Alphanumeric_Entry;

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
      -- Table 49 S2: level 1 goes to S10 (level 2 goes to S3-1, the
      -- Radio data window: scenario Win_Start_Up_Radio)
      Key (1);
      Check (Value_Of = "Level 1", "and another one");
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
      -- the level is unknown, so that Table 49 D2 leads to the Level window
      Send_Mode_Level (Mode => 1, Level => 0); -- SB
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

   ---------------------------------------------------------------------
   -- SDI-2, SDI-9: the catalogue of the system status messages (chapter
   -- 15, Tables 68 and 70; DMI_System_Status)
   ---------------------------------------------------------------------

   package SS renames DMI_Protocol;

   -- Step is one DMI cycle of 50 ms: 30 s are 600 of them
   SS_Steps_30s : constant := 600;

   ACTION_MAIN_WINDOW_BUTTON : constant := 16;

   function SS_Active (Number : Natural) return Boolean is
     (DMI_System_Status.Active (DMI_System_Status.Entry_T (Number)));

   procedure SS_Steps (Count : Natural) is
   begin
      for I in 1 .. Count loop
         Step;
      end loop;
   end SS_Steps;

   -- A standing train in FS, level 1, at 09:41 on the DMI's clock
   procedure SS_Reset (Mode : Natural := 2) is
   begin
      Reset;
      Send_Mode_Level (Mode => Mode, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Send_Status (HH => 9, MM => 41, SS => 7);
      Step;
      Drain_Sounds;
      Drain_Outbox;
   end SS_Reset;

   -- 15.1.1.3 text and case, 8.2.3.4.7 first group / bold / Sinfo, the
   -- time stamp of the DMI's clock, the end by the named event; SDI-9
   -- MSG_TEXT class 2; what is not in the catalogue is ignored
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
   -- Automatic Train Operation information (audit ATO-1: DMI 8.5,
   -- 11.3.14; audit PLN-5: 8.3.4.25). MSG_ATO carries what the
   -- ERTMS/ATO on-board tells and the ATO selector position.
   ---------------------------------------------------------------------

   -- G1 and G5 (area G at (334, 315)): the ATO engage / disengage and
   -- the skip stopping point buttons
   G1_X : constant := 358;
   G5_X : constant := 555;
   G_Y  : constant := 340;

   -- FS, a planning with two orders and an advice change at 600 m
   procedure ATO_Reset is
   begin
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 4000, Ceiling => 140,
                     Advice => 600,
                     Gradients => (0, 2),
                     Speeds => (1 => 4000, 2 => 0, 3 => 1),
                     Orders => (5, 1200,  9, 2600));
      Send_Status (HH => 17, MM => 33, SS => 25);
      Step;
      Drain_Sounds;
      Drain_Outbox;
   end ATO_Reset;

   -- Everything of 8.5.1.2 d the on-board can tell outside stopping
   -- points in FS (Figure 93e)
   procedure Send_ATO_Outside (Selector : Natural;
                               Status   : Natural := 2;
                               Skip     : Natural := 1) is
   begin
      Send_ATO (Selector     => Selector,
                Status       => Status,
                Skip         => Skip,
                Advice_Speed => 125,
                Coasting     => True,
                ETA_H        => 17, ETA_M => 36, ETA_S => 48,
                Name         => "Welwyn North",
                Stops        => (1 => 1800));
   end Send_ATO_Outside;

   procedure Scenario_ATO_Displays is
      Without_ATO : Natural := 0;
   begin
      ATO_Reset;
      Step;
      declare
         Picture : constant String := Display.Screen.Files.Digest;
      begin
         -- 8.5.1.1: with the selector at Stand-by nothing of 8.5 is
         -- shown, whatever the on-board tells; the next advice change
         -- marker of MSG_PLANNING neither
         Send_ATO_Outside (Selector => 1);
         Step;
         Check (Display.Screen.Files.Digest = Picture,
                "8.5.1.1: Stand-by shows no ATO information");
         -- a selector position not known is read as Stand-by
         Send_ATO_Outside (Selector => 7);
         Step;
         Check (Display.Screen.Files.Digest = Picture,
                "an unknown selector position shows nothing either");
         Check (not DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_ATO_Engage),
                "no ATO button without the selector");
         Without_ATO := 1;
      end;
      Check_Frame ("ato_selector_standby");

      -- 8.5.1.1 / Figure 93e: on, outside stopping points in FS: ATO02
      -- in G1, name and arrival time over G2-G4, ATO17 in G5, the target
      -- advice speed in B0, the coasting advice in B8, the stopping
      -- point in D2 and the next advice change marker in D7
      Send_ATO_Outside (Selector => 2);
      Step;
      Check_Frame ("ato_outside_fs");
      Expect_No_Sound ("the ATO objects play no sound");

      -- Figure 93c: engaged in AD; the skip requested by the driver.
      -- Target advice speed and coasting advice are the on-board's to
      -- send (SUBSET-026 Table 4.7.2: FS only); the DMI shows what comes
      Send_Mode_Level (Mode => 3, Level => 4); -- AD
      Send_ATO (Status => 3, Skip => 3,
                ETA_H => 17, ETA_M => 36, ETA_S => 48,
                Name => "Welwyn North", Stops => (1 => 1800));
      Step;
      Drain_Sounds;
      Check_Frame ("ato_outside_ad");

      -- Figures 93b / 93d: at a stopping point, accurate stop, 1:09 of
      -- dwell time, doors open; the stopping point at the train front
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_ATO (Status => 1, At_Stop => True, Accuracy => 3, Dwell => 69,
                Doors => 4, Skip => 1, Advice_Speed => 125,
                Coasting => True, Name => "Welwyn North",
                ETA_H => 17, ETA_M => 36, ETA_S => 48,
                Stops => (0, 2500));
      Step;
      Drain_Sounds;
      Check_Frame ("ato_at_stop");
      Check (not DMI_ATO.Skip_Button,
             "8.5.1.2: no skip stopping point button at a stopping point");

      -- 8.5.5.4: up to 59 s the seconds alone; overshoot, request to
      -- open the left doors
      Send_ATO (Status => 1, At_Stop => True, Accuracy => 1, Dwell => 45,
                Doors => 2, Stops => (1 => 0));
      Step;
      Check_Frame ("ato_dwell_seconds");

      -- 8.5.5.7: "Train hold"; undershoot, doors being closed by ATO
      Send_ATO (Status => 1, At_Stop => True, Accuracy => 2, Dwell => 45,
                Train_Hold => True, Doors => 6, Stops => (1 => 0));
      Step;
      Check_Frame ("ato_train_hold");

      -- the other statuses and door symbols of 8.5.2.4 / 8.5.6.3
      Send_ATO (Status => 5, At_Stop => True, Dwell => 5_999, Doors => 1);
      Step;
      Check_Frame ("ato_failure_both_doors");
      Send_ATO (Status => 4, At_Stop => True, Dwell => 600, Doors => 5);
      Step;
      Check_Frame ("ato_disengaging");
      Send_ATO (Status => 1, At_Stop => True, Dwell => 0, Doors => 3);
      Step;
      Check_Frame ("ato_right_doors");
      Send_ATO (Status => 1, At_Stop => True, Doors => 7);
      Step;
      Check_Frame ("ato_doors_closed");

      -- ATO18: skip requested by the ATO-TS, not a button (8.5.8.5); a
      -- name wider than G2-G4 stays inside it
      Send_ATO (Status => 3, Skip => 2,
                Name => "Hertford North Interchange Road",
                Stops => (1 => 900));
      Step;
      Check_Frame ("ato_skip_trackside_long_name");
      Check (not DMI_ATO.Skip_Button, "8.5.8.5: ATO18 is no button");

      -- the "nothing known" readings of dmi_protocol.ads: undefined
      -- codes and out of range values show nothing
      Send_ATO (Status => 9, At_Stop => True, Accuracy => 4, Dwell => 6_000,
                Doors => 8, Skip => 4);
      Step;
      Check_Frame ("ato_nothing_known_at_stop");
      Send_ATO (Status => 6, Skip => 9, Advice_Speed => 401,
                ETA_H => 24);
      Step;
      Check_Frame ("ato_nothing_known_outside");
      Check (Without_ATO = 1, "the stand-by pictures were compared");
   end Scenario_ATO_Displays;

   -- A message that does not match its counts is ignored as a whole
   procedure Scenario_ATO_Malformed is
      Name_33 : constant String (1 .. 33) := (others => 'x');
   begin
      ATO_Reset;
      Send_ATO_Outside (Selector => 2);
      Step;
      declare
         Picture : constant String := Display.Screen.Files.Digest;
      begin
         -- a name longer than ATO_Max_Name
         Send_ATO (Status => 5, Name => Name_33);
         Step;
         Check (Display.Screen.Files.Digest = Picture,
                "a name above 32 bytes: the message is ignored");
         -- too short, too long, count beyond the payload
         Send_Raw (16#0B#, (1 .. 17 => 0));
         Send_Raw (16#0B#, (1 .. 19 => 0));
         Send_Raw (16#0B#, (2, 5, 0, 0, 0, 255, 255, 0, 0, 0, 255, 255,
                            0, 255, 0, 0, 0, 3, 1, 0));
         Step;
         Check (Display.Screen.Files.Digest = Picture,
                "wrong lengths: the messages are ignored");
      end;
      Check (DMI_ATO."=" (DMI_ATO.Status, DMI_ATO.Ready),
             "the status stays ATO02");
      -- the longest name is accepted
      Send_ATO (Status => 2, Name => Name_33 (1 .. 32));
      Step;
      Check (DMI_ATO.Name_Length = 32, "a name of 32 bytes is taken");
   end Scenario_ATO_Malformed;

   -- 8.5.2.5 / 8.5.2.6 (G1, up-type) and 8.5.8.5 (G5, delay-type): the
   -- driver's requests reach the EVC as actions 13 and 14
   procedure Scenario_ATO_Buttons is
      procedure Hold_G5 (Steps : Natural) is
      begin
         Pointer_Down (G5_X, G_Y);
         for I in 1 .. Steps loop
            Step;
         end loop;
         Pointer_Up (G5_X, G_Y);
         Step;
      end Hold_G5;
   begin
      ATO_Reset;
      Send_ATO_Outside (Selector => 2, Status => 2);
      Step;
      Drain_Outbox;

      -- ATO02: G1 is the engage button
      Pointer_Down (G1_X, G_Y);
      Step;
      Check_Frame ("ato_engage_pressed");
      Pointer_Up (G1_X, G_Y);
      Step;
      Expect_Action (13, 1, "8.5.2.5: G1 requests the start of automatic "
                     & "driving");
      Drain_Sounds;

      -- ATO03 and ATO04: G1 is the disengage button
      Send_Mode_Level (Mode => 3, Level => 4); -- AD
      Send_ATO_Outside (Selector => 2, Status => 3);
      Press (G1_X, G_Y);
      Expect_Action (13, 0, "8.5.2.6: ATO03, G1 requests the stop");
      Send_ATO_Outside (Selector => 2, Status => 4);
      Press (G1_X, G_Y);
      Expect_Action (13, 0, "8.5.2.6: ATO04, G1 requests the stop");

      -- ATO01 and ATO05: no button
      Send_ATO_Outside (Selector => 2, Status => 1);
      Press (G1_X, G_Y);
      Send_ATO_Outside (Selector => 2, Status => 5);
      Press (G1_X, G_Y);
      Expect_Actions (13, 0, "8.5.2: ATO01 and ATO05 are no buttons");

      -- 8.5.8.5: G5 with ATO17 is a delay-type button: a short press
      -- does nothing, a press of 2 s requests the skip
      Send_ATO_Outside (Selector => 2, Status => 3, Skip => 1);
      Step;
      Drain_Outbox;
      Hold_G5 (10);
      Expect_Actions (14, 0, "5.3.2.6.6: half a second is not enough");
      Hold_G5 (42);
      Expect_Action (14, 1, "8.5.8.5: ATO17, G5 requests the skip");
      -- ATO19: G5 revokes it
      Send_ATO_Outside (Selector => 2, Status => 3, Skip => 3);
      Step;
      Hold_G5 (42);
      Expect_Action (14, 0, "8.5.8.5: ATO19, G5 revokes the skip");
      Drain_Sounds;

      -- a window over the default window takes the buttons (5.3.1.1.5)
      Press (610, 240);                        -- F5: Settings
      Press (G1_X, G_Y);
      Expect_Actions (13, 0, "no ATO request under a window");
      Press (370, 440);                        -- [Close]

      -- Stand-by: no buttons
      Send_ATO_Outside (Selector => 1, Status => 2);
      Press (G1_X, G_Y);
      Hold_G5 (42);
      Expect_Actions (13, 0, "8.5.1.1: no engage button at Stand-by");
      Drain_Sounds;
   end Scenario_ATO_Buttons;

   -- 8.5.1.7: S2 while the ERTMS/ATO on-board requests the warning
   -- sound, a reason of its own beside the Warning status (14.3.3.2)
   procedure Scenario_ATO_Warning_Sound is
      procedure Speed (V : Natural; Status : Natural) is
      begin
         Send_Speed_State (V_Cur => V, V_Perm => 120, V_Target => 0,
                           V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                           D_Target => 0, Monitoring => 0, Dial_Range => 1,
                           Vrelease_Exists => False, Status => Status);
      end Speed;
   begin
      ATO_Reset;
      Speed (100, 0);
      Drain_Sounds;
      Send_ATO (Status => 3, Warning => True);
      Expect_Sound (DMI_Sounds.S2_Warning_Start,
                    "8.5.1.7: the ATO warning starts S2");
      Send_ATO (Status => 3, Warning => True);
      Expect_No_Sound ("the warning held: S2 goes on");
      -- the supervision's Warning status comes on top
      Speed (127, 3);
      Expect_No_Sound ("WaS while S2 sounds for the ATO: nothing new");
      Send_ATO (Status => 3, Warning => False);
      Expect_No_Sound ("the ATO warning ends, WaS keeps S2");
      Speed (100, 0);
      Expect_Sound (DMI_Sounds.S2_Warning_Stop, "both reasons gone: S2 stops");
      -- and the other way round
      Speed (127, 3);
      Expect_Sound (DMI_Sounds.S2_Warning_Start, "WaS starts S2");
      Send_ATO (Status => 3, Warning => True);
      Speed (100, 0);
      Expect_No_Sound ("WaS ends, the ATO warning keeps S2");
      -- the selector does not gate the sound (Choice, see Apply_ATO)
      Send_ATO (Selector => 1, Status => 0, Warning => True);
      Expect_No_Sound ("Stand-by: the requested warning still sounds");
      Send_ATO (Selector => 1, Status => 0, Warning => False);
      Expect_Sound (DMI_Sounds.S2_Warning_Stop, "the ATO warning ends");
      -- the link loss forgets the warning
      Send_ATO (Status => 3, Warning => True);
      Expect_Sound (DMI_Sounds.S2_Warning_Start, "the warning again");
      DMI_Core.Initialise;
      Expect_Sound (DMI_Sounds.S2_Warning_Stop,
                    "a reset DMI stops the ATO warning");
   end Scenario_ATO_Warning_Sound;

   -- PLN-5, 8.3.4.25 / 8.5.3.6 to 8.5.3.8: the stopping points share the
   -- column distribution of the orders
   procedure Scenario_ATO_Stopping_Points is
   begin
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 3000, Ceiling => 140,
                     Gradients => (0, 2),
                     Speeds => (1 => 3000, 2 => 0, 3 => 1),
                     Orders => (5, 300,  9, 600,  7, 700));
      Send_ATO (Selector => 1, Stops => (450, 3000, 3500));
      Step;
      Drain_Sounds;
      -- Stand-by: the orders alone in D2, D3, D4
      Check_Frame ("ato_columns_standby");
      -- On: 300 order D2, 450 stop D3, 600 order D4, 700 order D2; the
      -- stop at the end of the MA is shown (D3), the one beyond is not
      Send_ATO (Status => 1, Stops => (450, 3000, 3500));
      Step;
      Check_Frame ("ato_columns_on");
      -- 8.5.3.7: overlapping symbols, the closest one on top: two stops
      -- 20 m apart fall into adjacent columns; with three columns the
      -- fourth symbol comes back to D2 on top of the farther one
      Send_Planning (MA_Dist => 3000, Ceiling => 140,
                     Gradients => (0, 2),
                     Speeds => (1 => 3000, 2 => 0, 3 => 1));
      Send_ATO (Status => 1, Stops => (1000, 1020, 1040, 1060));
      Step;
      Check_Frame ("ato_columns_overlap");
      -- more stopping points than kept: the nearest 8
      Send_ATO (Status => 1,
                Stops => (2900, 2800, 2700, 2600, 2500, 2400, 2300, 2200,
                          100, 40_000));
      Check (DMI_Planning.Stop_Count = 8, "8 stopping points are kept");
      Check ((for some I in 1 .. DMI_Planning.Stop_Count =>
                DMI_Planning.Stops (I) = 100)
             and then (for all I in 1 .. DMI_Planning.Stop_Count =>
                         DMI_Planning.Stops (I) /= 2900),
             "the nearest ones are kept");
   end Scenario_ATO_Stopping_Points;

   -- 11.3.14: the ATO selector window, reached from the Settings window
   -- (Table 36 #7, Table 54 S8), with Table 48 closing it
   procedure Scenario_ATO_Selector_Window is
      use type DMI_Windows.Window_ID_T;

      function Value_Of return Wide_String is
         V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (1);
      begin
         return V.Text (1 .. V.Length);
      end Value_Of;
   begin
      ATO_Reset;
      -- nothing reported yet: no position proposed (11.7.1.4)
      Press (610, 240);                        -- F5: Settings
      Check (DMI_Windows.Button_Enabled (7),
             "Table 36 #7: 'ATO' is enabled in FS");
      Press (410, 240);                        -- ATO
      Check (DMI_Windows.Top = DMI_Windows.W_ATO_Selector,
             "Table 54 S8: the ATO selector window");
      Check (Value_Of = "", "an unknown position proposes no value");
      Press (370, 440);                        -- [Close]

      Send_ATO (Selector => 1);
      Press (410, 240);                        -- ATO
      Check (Value_Of = "Stand-by",
             "11.7.1.4: the position the on-board holds is proposed");
      Check_Frame ("ato_selector_window");
      Key (2);
      Check (Value_Of = "On", "Table 43a: the button 2 is 'On'");
      Enter_Single;
      Expect_Action (15, 2, "the accepted position goes to the EVC");
      Check (DMI_Windows.Top = DMI_Windows.W_Settings,
             "Table 54 S8: back to S1, the Settings window");
      Check (not DMI_ATO.Displayed,
             "the position is the on-board's: shown once it reports it");
      Send_ATO (Selector => 2, Status => 2);

      -- revalidation of 'On' and the choice of 'Stand-by'
      Press (410, 240);
      Check (Value_Of = "On", "the reported position is proposed");
      Key (1);
      Enter_Single;
      Expect_Action (15, 1, "Stand-by goes to the EVC");

      -- Table 48: the window closes when the button's condition fails;
      -- Table 36 #7 does not name the mode SL
      Press (410, 240);
      Check (DMI_Windows.Top = DMI_Windows.W_ATO_Selector,
             "the window again");
      Send_Mode_Level (Mode => 16, Level => 4); -- SL
      Step;
      Check (DMI_Windows.Top = DMI_Windows.W_Settings,
             "Table 48: SL closes the ATO selector window");
      Check (not DMI_Windows.Button_Enabled (7),
             "Table 36 #7: 'ATO' disabled in SL");
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_ATO_Selector_Window;

   -- The simulator's ERTMS/ATO on-board (sim/evc_ato) through the DMI,
   -- the way the browser bench runs it: the driver switches the ATO
   -- selector on, engages, the ATO stops the train at Welwyn North,
   -- disengages itself, the driver engages again, disengages and
   -- engages once more, and the ATO holds the train at Knebworth
   procedure Scenario_ATO_Mission is
      use type EVC_Core.Mode_T;

      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

      procedure Pump_To_EVC is
         use Ada.Streams;
         use DMI_Protocol;
         Buffer : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
         Last   : Stream_Element_Offset;
         Offset : Stream_Element_Offset := Buffer'First;
      begin
         DMI_Core.Take_Outbox (Buffer, Last, With_Sounds => False);
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
                  EVC_Core.Handle_Driver_Data (Buffer (Offset .. Next - 1));
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
         Pump_To_EVC;
      end Sim_Step;

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

      function At_Stop return Boolean is (EVC_ATO.At_Stopping_Point);
      function Ready return Boolean is
        (DMI_ATO."=" (DMI_ATO.Status, DMI_ATO.Ready));
      function Beyond_3000 return Boolean is
        (EVC_Train.Position_M > 3_000.0);
      function In_FS return Boolean is (EVC_Core.Mode = EVC_Core.FS);

      procedure Wait_Stop is new Run_Until (At_Stop);
      procedure Wait_Ready is new Run_Until (Ready);
      procedure Wait_3000 is new Run_Until (Beyond_3000);
      procedure Wait_FS is new Run_Until (In_FS);

      function Error_At (M : Natural) return Float is
        (abs (EVC_Train.Position_M - Float (M)));
   begin
      Reset;
      EVC_Core.Reset;
      External_EVC;
      for I in 1 .. 5 loop
         Sim_Step;
      end loop;

      -- start of mission (as Scenario_Mission)
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
      Touch (410, 90);                      -- Start -> default window
      Check (EVC_Core.Mode = EVC_Core.FS, "the mission starts in FS");

      -- 11.3.14: the driver sets the ATO selector to "On"
      Touch (610, 240);                     -- F5: Settings
      Touch (410, 240);                     -- ATO
      Touch (Key_X (2), Key_Y (2));         -- On
      Touch (487, 90);                      -- accept
      Touch (370, 440);                     -- [Close]
      Check (EVC_ATO.Selector_On, "the EVC holds the selector 'On'");
      Wait_Ready ("ATO02", 50);
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("ato_mission_ready");

      -- 8.5.2.5: engage; SUBSET-026 [80]: AD
      Touch (G1_X, G_Y);
      Check (EVC_Core.Mode = EVC_Core.AD, "ATO engage: the mode is AD");
      Wait_Stop ("the stop at Welwyn North", 6_000);
      Check (Error_At (EVC_Track.Stopping_Points (1).At_M) <= 2.0,
             "the ATO stops within 2 m of Welwyn North");
      Check (EVC_Core.Mode = EVC_Core.FS,
             "4.4.16.3.2.1: the ATO disengages itself at the stop");
      for I in 1 .. 10 loop
         Sim_Step;                          -- the doors are open
      end loop;
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("ato_mission_at_welwyn");

      -- after the dwell time the ATO is ready again
      Wait_Ready ("ATO02 after the dwell time", 400);
      Touch (G1_X, G_Y);
      Check (EVC_Core.Mode = EVC_Core.AD, "engaged again");
      Wait_3000 ("leaving Welwyn North", 3_000);
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("ato_mission_engaged");

      -- 8.5.2.6: disengage; ATO04 with the ATO warning (8.5.1.7)
      Touch (G1_X, G_Y);
      Sim_Step;
      Check (DMI_ATO."=" (DMI_ATO.Status, DMI_ATO.Disengaging),
             "ATO disengage: ATO04");
      Expect_Sound (DMI_Sounds.S2_Warning_Start, "the ATO warning: S2");
      Wait_FS ("the end of the disengagement", 50);
      Sim_Step;
      Expect_Sound (DMI_Sounds.S2_Warning_Stop, "the warning ends");
      Drain_Sounds;

      -- the automatic driver follows the advice in FS; engage again
      Wait_Ready ("ATO02 in FS", 50);
      Touch (G1_X, G_Y);
      Wait_Stop ("the stop at Knebworth", 8_000);
      Check (Error_At (EVC_Track.Stopping_Points (2).At_M) <= 2.0,
             "the ATO stops within 2 m of Knebworth");
      for I in 1 .. 40 loop
         Sim_Step;                          -- 4 s of train hold
      end loop;
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("ato_mission_train_hold");
      for I in 1 .. 100 loop
         Sim_Step;                          -- the hold is over
      end loop;
      Drain_Sounds;
      DMI_Core.Render;
      Check_Frame ("ato_mission_dwell");
   end Scenario_ATO_Mission;

   ---------------------------------------------------------------------
   -- P3, audit WIN-12 / WIN-13: the Radio data window and its children
   -- (11.2.5, 11.3.4, 11.3.5, 11.3.15, 11.3.16), the Main and Special
   -- window entries of Tables 33 and 35 that were missing, the symbols
   -- of Table 36, and the dialogue sequences that use them (Tables 49,
   -- 50, 51, 54a)
   ---------------------------------------------------------------------

   subtype Win_U8 is Interfaces.Unsigned_8;
   use type Win_U8;

   --  MSG_ONBOARD bytes (dmi_protocol.ads)
   Win_Data_All : constant Win_U8 := 16#0F#; -- id, train data, level, TRN
   Win_Standing : constant Win_U8 := 16#03#; -- standstill, override ok
   Win_Running  : constant Win_U8 := 16#02#;
   Win_NV       : constant Win_U8 := 16#02#; -- adhesion may be modified

   --  radio byte: the type in bits 0-1, the installed systems in bits
   --  2-3, the registrations, 'one radio system' and the RBC contact
   --  information known
   Win_FRMCS      : constant Win_U8 := 1;
   Win_FRMCS_GSMR : constant Win_U8 := 2;
   Win_GSMR       : constant Win_U8 := 3;
   Win_Only_FRMCS : constant Win_U8 := 4;
   Win_Only_GSMR  : constant Win_U8 := 8;
   Win_Both       : constant Win_U8 := 12;
   Win_FRMCS_Reg  : constant Win_U8 := 16;
   Win_GSMR_Reg   : constant Win_U8 := 32;
   Win_One_Yes    : constant Win_U8 := 64;
   Win_Known      : constant Win_U8 := 128;

   --  the on-board of most steps below: GSM-R, one Mobile Terminal
   --  registered, RBC contact information known
   Win_Radio_GSMR : constant Win_U8 :=
     Win_GSMR or Win_Only_GSMR or Win_GSMR_Reg or Win_Known;

   procedure Win_Onboard (Data       : Win_U8 := Win_Data_All;
                          Session    : Win_U8 := 0;
                          RBC        : Win_U8 := 0;
                          Train      : Win_U8 := Win_Standing;
                          SOM        : Win_U8 := 0;
                          Waiting    : Win_U8 := 0;
                          Radio      : Win_U8 := 0;
                          Radio_Wait : Win_U8 := 0;
                          Answer     : Win_U8 := 0) is
   begin
      Send_Onboard_Raw (Data, Session, RBC, Train, Win_NV, SOM, Waiting, 0,
                        Radio, Radio_Wait, Answer);
      Step;
   end Win_Onboard;

   procedure Win_At_Standstill is
   begin
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
   end Win_At_Standstill;

   --  Table 20: the menu button Slot, two columns of 153 x 50 from y 50
   function Win_Slot_X (Slot : Positive) return Natural is
     (334 + ((Slot - 1) mod 2) * 153 + 76);
   function Win_Slot_Y (Slot : Positive) return Natural is
     (15 + 50 + ((Slot - 1) / 2) * 50 + 25);

   procedure Win_Menu (Slot : Positive) is
   begin
      Press (Win_Slot_X (Slot), Win_Slot_Y (Slot));
   end Win_Menu;

   --  a delay-type button: 2 s of pressing (5.3.2.6.6)
   procedure Win_Menu_Long (Slot : Positive) is
   begin
      Pointer_Down (Win_Slot_X (Slot), Win_Slot_Y (Slot));
      for I in 1 .. 41 loop
         Step;
      end loop;
      Pointer_Up (Win_Slot_X (Slot), Win_Slot_Y (Slot));
      Step;
      Drain_Sounds;
   end Win_Menu_Long;

   function Win_Top_Is (ID : DMI_Windows.Window_ID_T) return Boolean is
     (DMI_Windows.Is_Open and then DMI_Windows."=" (DMI_Windows.Top, ID));

   function Win_Enabled (Index : Positive) return Boolean is
     (DMI_Windows.Button_Enabled (Index));

   function Win_Value (I : Positive := 1) return Wide_String is
      V : constant DMI_Driver_Data.Text_Value_T := DMI_Data_Entry.Value (I);
   begin
      return V.Text (1 .. V.Length);
   end Win_Value;

   procedure Win_Close is
   begin
      Press (370, 440);
   end Win_Close;

   --  Close every window that can be closed
   procedure Win_Default is
   begin
      while DMI_Windows.Is_Open and then DMI_Windows.Close_Enabled loop
         Win_Close;
      end loop;
   end Win_Default;

   procedure Win_Open_Main is
   begin
      Win_Default;
      Press (610, 40);                          -- F1
   end Win_Open_Main;

   --  Table 25: '1' .. '9' on the keys 1 .. 9, '0' on the key 11
   procedure Win_Type (Digits_Text : String) is
   begin
      for C of Digits_Text loop
         if C = '0' then
            Key (11);
         else
            Key (Character'Pos (C) - Character'Pos ('0'));
         end if;
      end loop;
   end Win_Type;

   --  The wire bytes of an RBC data message after the kind (kind 5)
   function Win_RBC_Bytes (Choice : Natural;
                           ID     : Natural;
                           Phone  : String) return Byte_Array is
      Result : Byte_Array (1 .. 22) := (others => 0);
   begin
      Result (1) := Choice;
      Result (2) := ID mod 256;
      Result (3) := (ID / 256) mod 256;
      Result (4) := (ID / 65536) mod 256;
      Result (5) := ID / 16777216;
      Result (6) := Phone'Length;
      for I in Phone'Range loop
         Result (7 + I - Phone'First) := Character'Pos (Phone (I));
      end loop;
      return Result;
   end Win_RBC_Bytes;

   function Win_Name_Bytes (Name : String) return Byte_Array is
      Result : Byte_Array (1 .. Name'Length + 1);
   begin
      Result (1) := Name'Length;
      for I in Name'Range loop
         Result (2 + I - Name'First) := Character'Pos (Name (I));
      end loop;
      return Result;
   end Win_Name_Bytes;

   ---------------------------------------------------------------------
   -- Table 33 #7, #9, #10, #11, #12 and the Shunting (11.7.4, Table 51)
   -- and Supervised Manoeuvre (11.7.8, Table 54a) dialogue sequences
   ---------------------------------------------------------------------

   procedure Scenario_Win_Main_Menu is
      --  level 2 with what Table 33 #11 asks for: the position referred
      --  to an LRBG (bit 5) and the safe consist length information, zero
      --  in front of the engine (bits 6, 7)
      Data_SM : constant Win_U8 := Win_Data_All or 16#E0#;
   begin
      Reset;
      Win_Onboard;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Win_At_Standstill;
      Win_Open_Main;
      Check (Win_Top_Is (DMI_Windows.W_Main), "win: the Main window");

      -- #10 Radio data
      Check (Win_Enabled (10),
             "Table 33 #10: Radio data in SB at standstill with valid data");
      Win_Onboard (Data => 16#0B#);             -- level not valid
      Check (not Win_Enabled (10), "Table 33 #10: not without a valid level");
      Win_Onboard (Train => Win_Running);
      Check (not Win_Enabled (10), "Table 33 #10: not while running");
      Win_Onboard;

      -- #9 Maintain Shunting, #7 Exit Shunting in SH
      Check (not Win_Enabled (9), "Table 33 #9: no Maintain Shunting in SB");
      Check (not Win_Enabled (12), "Table 33 #12: no Exit SM outside SM");
      Send_Mode_Level (Mode => 8, Level => 4); -- SH
      Win_Onboard;
      Check (not Win_Enabled (9),
             "Table 33 #9: SH without the passive shunting signal");
      Check (Win_Enabled (7), "Table 33 #7: 'Exit Shunting' in SH");
      Win_Onboard (Train => Win_Standing or 16#08#);
      Check (Win_Enabled (9),
             "Table 33 #9: Maintain Shunting with the passive shunting"
             & " signal");
      Step;
      Check_Frame ("win_main_sh");
      Win_Onboard (Train => Win_Running or 16#08#);
      Check (not Win_Enabled (7),
             "Table 33 #7: no Exit Shunting while running");
      Check (Win_Enabled (9), "Table 33 #9: Maintain Shunting while running");
      Drain_Outbox;
      Win_Menu_Long (9);
      Expect_Actions (19, 1, "Maintain Shunting is sent (action 19)");
      Check (not DMI_Windows.Is_Open,
             "Table 50 S1: Maintain Shunting -> the default window");

      Win_Onboard (Train => Win_Standing);
      Win_Open_Main;
      Drain_Outbox;
      Win_Menu_Long (7);
      Expect_Actions (8, 1, "'Exit Shunting' is sent (action 8)");
      Check (not DMI_Windows.Is_Open,
             "Table 50 S1: Exit Shunting -> S0 of Start Up (default window)");
      Send_Mode_Level (Mode => 1, Level => 4); -- the EVC: SB
      Win_Onboard (Data => 16#04#, SOM => 2);  -- start of mission
      Check (DMI_Windows.In_Start_Up
             and then Win_Top_Is (DMI_Windows.W_Driver_ID),
             "after Exit Shunting the EVC engages Start Up (S0 -> S1)");
      Win_Onboard (SOM => 0);                   -- ends it again
      Check (not DMI_Windows.Is_Open, "the Start Up sequence is aborted");

      -- #11 Initiate SM: level 2, a session with an RBC above 2.2
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Win_Onboard (Data => Data_SM, Session => 3);
      Win_Open_Main;
      Check (Win_Enabled (11), "Table 33 #11: Initiate SM in SB, level 2");
      Win_Onboard (Data => Data_SM, Session => 2);
      Check (not Win_Enabled (11),
             "Table 33 #11: not without an RBC above system version 2.2");
      Win_Onboard (Data => Data_SM, Session => 3, RBC => 16#04#);
      Check (not Win_Enabled (11),
             "Table 33 #11: not with an RBC transition order stored");
      Win_Onboard (Data => Win_Data_All or 16#20#, Session => 3);
      Check (not Win_Enabled (11),
             "Table 33 #11: not without safe consist length information");
      Win_Onboard (Data => Win_Data_All or 16#C0#, Session => 3);
      Check (not Win_Enabled (11),
             "Table 33 #11: not without a position referred to an LRBG");
      Win_Onboard (Data => Data_SM, Session => 3);
      Step;
      Check_Frame ("win_main_initiate_sm");

      Drain_Outbox;
      Win_Menu_Long (11);
      Expect_Action_Arg (17, 0, "'Initiate SM' is sent (action 17, arg 0)");
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 54a S1: the Main window stays");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 5);
      Check (DMI_Windows.Waiting_Displayed
             and then not Win_Enabled (11) and then not Win_Enabled (2),
             "Table 54a S1: all buttons disabled while the RBC is asked");
      Check (not DMI_Windows.Close_Enabled,
             "11.7.8.2: [Close] is disabled in S1");
      Step;
      Check_Frame ("win_sm_waiting");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 0, Answer => 0);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.Waiting_Displayed,
             "Table 54a S1: 'SM refused' -> S0, the Main window");

      Drain_Outbox;
      Win_Menu_Long (11);
      Expect_Action_Arg (17, 0, "'Initiate SM' again");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 5);
      Send_Mode_Level (Mode => 4, Level => 5); -- SM
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 0, Answer => 1);
      Check (not DMI_Windows.Is_Open,
             "Table 54a S1: the SM authorisation -> the default window");

      -- #11 Continue in SM and #12 Exit SM in SM
      Win_Open_Main;
      Check (Win_Enabled (11), "Table 33 #11: 'Continue in SM' in SM");
      Check (Win_Enabled (12), "Table 33 #12: Exit SM in SM at standstill");
      Step;
      Check_Frame ("win_main_sm");
      Drain_Outbox;
      Win_Menu_Long (11);
      Expect_Action_Arg (17, 1, "'Continue in SM' is sent (action 17, arg 1)");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 5);
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 0, Answer => 1);
      Check (not DMI_Windows.Is_Open,
             "Table 54a S1: authorised in SM, the answer and not the mode"
             & " leads to the default window");
      Win_Open_Main;
      Win_Onboard (Data => Data_SM, Session => 3, Train => Win_Running);
      Check (not Win_Enabled (12), "Table 33 #12: no Exit SM while running");
      Win_Onboard (Data => Data_SM, Session => 3);
      Drain_Outbox;
      Win_Menu_Long (12);
      Expect_Action_Arg (17, 2, "'Exit SM' is sent (action 17, arg 2)");
      Check (not DMI_Windows.Is_Open,
             "Table 50 S1: Exit SM -> S0 of Start Up (default window)");

      -- Shunting in level 2 asks the RBC (Table 51 D1 -> S1)
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Win_Onboard (Data => Data_SM, Session => 3);
      Win_Open_Main;
      Drain_Outbox;
      Win_Menu_Long (7);
      Expect_Actions (7, 1, "the request for shunting is sent");
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 51 D1: level 2 -> S1, the Main window stays");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 4);
      Check (DMI_Windows.Waiting_Displayed
             and then not DMI_Windows.Close_Enabled,
             "Table 51 S1 / 11.7.4.2: all buttons and [Close] disabled");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 0);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.Waiting_Displayed,
             "Table 51 S1: 'Shunting Refused' -> S0, the Main window");
      Win_Menu_Long (7);
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 4);
      Send_Mode_Level (Mode => 8, Level => 5); -- SH
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 0, Answer => 1);
      Check (not DMI_Windows.Is_Open,
             "Table 51 S1: 'Shunting Authorised' -> the default window");

      -- Shunting in level 1 goes at once (Table 51 D1)
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Win_Onboard;
      Win_Open_Main;
      Drain_Outbox;
      Win_Menu_Long (7);
      Expect_Actions (7, 1, "the request for shunting in level 1");
      Check (not DMI_Windows.Is_Open,
             "Table 51 D1: level 1 -> the default window");
      Drain_Outbox;
   end Scenario_Win_Main_Menu;

   ---------------------------------------------------------------------
   -- Table 35 #4 (BMM reaction inhibition) and Table 36 (symbols)
   ---------------------------------------------------------------------

   procedure Scenario_Win_Special_Settings is
   begin
      Reset;
      Win_Onboard;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Win_At_Standstill;
      Win_Default;
      Press (610, 190);                         -- F4: Special
      Check (Win_Top_Is (DMI_Windows.W_Special), "win: the Special window");
      Check (Win_Enabled (4),
             "Table 35 #4: BMM reaction inhibition in SB, level 1");
      Drain_Outbox;
      Win_Menu (4);
      Expect_Action_Arg (18, 0,
                         "'BMM reaction inhibition' is sent (action 18, 0)");
      Check (not DMI_Windows.Is_Open,
             "Table 53 S1: -> the default window (ST07 is the EVC's)");

      Win_Onboard (Train => Win_Standing or 16#10#); -- inhibition active
      Press (610, 190);
      Check (Win_Enabled (4),
             "Table 35 #4: 'Revoke BMM reaction inhibition' when active");
      Step;
      Check_Frame ("win_special_bmm_revoke");
      Drain_Outbox;
      Win_Menu (4);
      Expect_Action_Arg (18, 1, "'Revoke ...' is sent (action 18, arg 1)");
      Check (not DMI_Windows.Is_Open, "Table 53 S1: -> the default window");

      Press (610, 190);
      Send_Mode_Level (Mode => 1, Level => 2); -- level 0
      Win_Onboard;
      Check (not Win_Enabled (4), "Table 35 #4: not in level 0");
      Send_Mode_Level (Mode => 7, Level => 5); -- SR, level 2
      Win_Onboard (Data => 0);
      Check (Win_Enabled (4),
             "Table 35 #4: in SR without the SB conditions on the data");
      Win_Onboard (Data => 0, Train => Win_Running);
      Check (not Win_Enabled (4), "Table 35 #4: not while running");

      -- Table 36: the symbols SE03, SE02, SE01; disabled in SB while
      -- running, drawn dark grey
      Send_Mode_Level (Mode => 1, Level => 4);
      Win_Onboard (Train => Win_Running);
      Win_Default;
      Press (610, 240);                         -- F5: Settings
      Check (Win_Top_Is (DMI_Windows.W_Settings), "win: the Settings window");
      Check (not Win_Enabled (2) and then not Win_Enabled (3),
             "Table 36 #2, #3: disabled in SB while running");
      Step;
      Check_Frame ("win_settings_disabled");
      Win_Onboard;
      Win_Menu (2);
      Check (Win_Top_Is (DMI_Windows.W_Volume), "Table 36 #2: SE02 -> Volume");
      Win_Close;
      Win_Menu (3);
      Check (Win_Top_Is (DMI_Windows.W_Brightness),
             "Table 36 #3: SE01 -> Brightness");
      Win_Default;
      Drain_Outbox;
   end Scenario_Win_Special_Settings;

   ---------------------------------------------------------------------
   -- Table 37 and the Radio data part of the Main window dialogue
   -- sequence (Table 50 S1 -> S5-1 .. S5-4, S5-2-x, A5 / A6 / A7, D9,
   -- S10, S4 -> D5) and Table 48
   ---------------------------------------------------------------------

   procedure Scenario_Win_Radio_Data is
      Data_Valid : constant Win_U8 := Win_Data_All or 16#10#; -- + RBC info

      procedure Radio (R : Win_U8; Data : Win_U8 := Data_Valid;
                       Radio_Wait : Win_U8 := 0) is
      begin
         Win_Onboard (Data => Data, Radio => R, Radio_Wait => Radio_Wait);
      end Radio;

      procedure Open_Radio_Data is
      begin
         Win_Open_Main;
         Win_Menu (10);
      end Open_Radio_Data;
   begin
      Reset;
      Radio (Win_Radio_GSMR);
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Win_At_Standstill;
      Open_Radio_Data;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 50 S1 -> S5-1: the Radio data window");
      Check (Win_Enabled (1) and then Win_Enabled (2) and then Win_Enabled (3)
             and then Win_Enabled (5) and then Win_Enabled (6),
             "Table 37 #1, #2, #3, #5, #6: GSM-R registered, level 2");
      Check (not Win_Enabled (7),
             "Table 37 #7: no mission with one radio system with GSM-R only");
      Check (DMI_Windows.Close_Enabled, "11.7.3.2: [Close] in S5-1");
      Step;
      Check_Frame ("win_radio_data");

      -- Table 37, row by row
      Radio (Win_GSMR or Win_Only_GSMR or Win_Known);
      Check (not Win_Enabled (1) and then not Win_Enabled (2)
             and then not Win_Enabled (3),
             "Table 37 #1 .. #3: nothing without a registered GSM-R MT");
      Check (Win_Enabled (5) and then Win_Enabled (6),
             "Table 37 #5, #6: no registration needed");
      Radio (Win_GSMR or Win_Only_GSMR or Win_GSMR_Reg);
      Check (not Win_Enabled (1) and then Win_Enabled (3),
             "Table 37 #1: 'Contact last RBC' needs RBC contact information");
      Radio (Win_FRMCS or Win_Only_FRMCS or Win_FRMCS_Reg or Win_Known);
      Check (Win_Enabled (1) and then Win_Enabled (3)
             and then not Win_Enabled (2) and then not Win_Enabled (6),
             "Table 37: FRMCS registered: #1, #3, no short number, no GSM-R");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_FRMCS_Reg or Win_Known);
      Check (not Win_Enabled (1) and then not Win_Enabled (3),
             "Table 37 #1, #3: both systems need both registrations");
      Check (Win_Enabled (7),
             "Table 37 #7: one registration of two -> one radio system");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_FRMCS_Reg or Win_Known
             or Win_One_Yes);
      Check (Win_Enabled (1) and then Win_Enabled (3)
             and then not Win_Enabled (2),
             "Table 37 #1, #3: ... or one of them with 'one radio system'");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_One_Yes);
      Check (Win_Enabled (2),
             "Table 37 #2: short number with GSM-R and 'one radio system'");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_FRMCS_Reg);
      Check (not Win_Enabled (7),
             "Table 37 #7: not with both registrations");
      Send_Mode_Level (Mode => 1, Level => 4); -- level 1
      Radio (Win_Radio_GSMR);
      Check (not Win_Enabled (1) and then not Win_Enabled (2)
             and then not Win_Enabled (3) and then Win_Enabled (5)
             and then Win_Enabled (6),
             "Table 37: in level 1 only the radio network type and ID");
      Send_Mode_Level (Mode => 4, Level => 5); -- SM
      Radio (Win_Radio_GSMR);
      Check (not Win_Enabled (5) and then Win_Enabled (6),
             "Table 37 #5 not in SM, #6 in SM");
      Send_Mode_Level (Mode => 1, Level => 5);
      Radio (Win_Radio_GSMR, Data => Win_Data_All and 16#0E#);
      Check (not Win_Enabled (5) and then not Win_Enabled (6),
             "Table 37 #5, #6: not without a valid Driver ID");
      Radio (Win_Radio_GSMR);

      -- S5-1: 'Contact last RBC' and 'Use short number' -> S8
      Drain_Outbox;
      Win_Menu (1);
      Expect_Driver_Data (5, Win_RBC_Bytes (1, 0, ""),
                          "'Contact last RBC': kind 5, choice 1");
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 50 S5-1 -> S8: the Main window");
      Win_Onboard (Data => Data_Valid, Radio => Win_Radio_GSMR, Waiting => 2);
      Check (DMI_Windows.Waiting_Displayed,
             "Table 50 S8: the EVC awaits the RBC");
      Radio (Win_Radio_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Main), "Table 50 D3 / D4 -> S1");
      Win_Menu (10);
      Drain_Outbox;
      Win_Menu (2);
      Expect_Driver_Data (5, Win_RBC_Bytes (2, 0, ""),
                          "'Use short number': kind 5, choice 2");

      -- S5-3: the RBC data window
      Win_Menu (10);
      Win_Menu (3);
      Check (Win_Top_Is (DMI_Windows.W_RBC_Data),
             "Table 50 S5-1 -> S5-3: the RBC data window");
      Check (Win_Value (1) = "" and then Win_Value (2) = "",
             "11.7.1.4: nothing entered on this DMI, nothing proposed");
      Win_Type ("16777215");
      Enter_Field (1);
      Check (not Win_Enabled (17),
             "RBC ID above 16 777 214 fails the technical range (A.3.11)");
      for I in 1 .. 8 loop
         Key (10);                              -- [Delete]
      end loop;
      Win_Type ("1234567");
      Enter_Field (1);
      Win_Type ("0123456789012345");
      Enter_Field (2);
      Step;
      Check_Frame ("win_rbc_data");
      Drain_Outbox;
      Press (167, 440);                         -- RBC data entry complete? Yes
      Expect_Driver_Data (5, Win_RBC_Bytes (0, 1234567, "0123456789012345"),
                          "the RBC data: kind 5, choice 0, id, phone");
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 50 S5-3 'Yes' -> S8: the Main window");
      Win_Menu (10);
      Win_Menu (3);
      Check (Win_Value (1) = "1234567"
             and then Win_Value (2) = "0123456789012345",
             "11.7.1.4: the RBC data held are proposed");
      -- Table 48: the RBC data window gives way to its parent
      Radio (Win_Radio_GSMR, Data => Win_Data_All and 16#0E#);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 48: RBC data -> the Radio data window when 'Enter RBC"
             & " data' loses its conditions");
      Radio (Win_Radio_GSMR);

      -- 11.3.5.4: no phone number field with FRMCS alone
      Radio (Win_FRMCS or Win_Only_FRMCS or Win_FRMCS_Reg or Win_Known);
      Win_Menu (3);
      Step;
      Check_Frame ("win_rbc_data_frmcs");
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "11.7.3.2: [Close] of S5-3 goes back to S5-1");

      -- S5-4: the Radio network type window
      Radio (Win_Radio_GSMR);
      Win_Menu (5);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Network_Type)
             and then Win_Value = "GSM-R",
             "Table 50 S5-4: the stored type GSM-R is proposed");
      Step;
      Check_Frame ("win_radio_network_type");
      Drain_Outbox;
      Key (2);
      Enter_Single;
      Expect_Driver_Data (6, (1 => 2), "FRMCS+GSM-R: kind 6, value 2");
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 50 S5-4 E2 (FRMCS not installed) -> S5-1");
      -- E1 -> A6 -> D9: FRMCS installed, not registered
      Radio (Win_GSMR or Win_Both or Win_GSMR_Reg or Win_Known);
      Win_Menu (5);
      Key (2);
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 50 S5-4 E1 -> A6 -> D9 (both systems) -> S5-1");
      Win_Menu (5);
      Drain_Outbox;
      Key (1);
      Enter_Single;
      Expect_Driver_Data (6, (1 => 1), "FRMCS: kind 6, value 1");
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 50 S5-4 E1 -> A6 -> D9 (FRMCS alone) -> S1");

      -- S5-2-1 .. S5-2-3: the GSM-R network ID
      Radio (Win_Radio_GSMR);
      Win_Menu (10);
      Drain_Outbox;
      Win_Menu_Long (6);
      Expect_Driver_Data (4, (1 => 0),
                          "'GSM-R network ID': kind 4 without a name");
      Check (DMI_Windows.Radio_Step_Displayed
             and then not Win_Enabled (1) and then not Win_Enabled (5),
             "Table 50 S5-2-1: all buttons disabled at once");
      Check (not DMI_Windows.Close_Enabled,
             "11.7.3.2: [Close] is disabled in S5-2-1");
      Step;
      Check_Frame ("win_radio_data_st05");
      Radio (Win_Radio_GSMR, Radio_Wait => 1);
      Send_Radio_Networks ("GSMR-A,GSMR-B,Telecom X");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "S5-2-1: the list waits for the EVC to end the step");
      Send_Raw (16#0D#, (2, 3, 65, 66, 67));   -- truncated: ignored
      Radio (Win_Radio_GSMR, Radio_Wait => 0);
      Check (Win_Top_Is (DMI_Windows.W_GSMR_Network),
             "Table 50 S5-2-1 -> S5-2-2: the GSM-R network ID window");
      Check (DMI_Windows.Close_Enabled, "11.7.3.2: [Close] in S5-2-2");
      Check (Win_Value = "", "no network selected on this DMI yet");
      Step;
      Check_Frame ("win_gsmr_network");
      Drain_Outbox;
      Key (2);
      Enter_Single;
      Expect_Driver_Data (4, Win_Name_Bytes ("GSMR-B"),
                          "the selected network: kind 4 with its name");
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.Radio_Step_Displayed,
             "Table 50 S5-2-2 -> S5-2-3: the Radio data window waits");
      Radio (Win_Radio_GSMR);
      Check (DMI_Windows.Radio_Step_Displayed,
             "S5-2-3 lasts until the EVC reported the registration");
      Radio (Win_Radio_GSMR, Radio_Wait => 2);
      Check (DMI_Windows.Radio_Step_Displayed, "S5-2-3 while the EVC waits");
      Radio (Win_Radio_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then not DMI_Windows.Radio_Step_Displayed
             and then Win_Enabled (1),
             "Table 50 S5-2-3 -> S5-1 once registered");
      Win_Menu_Long (6);
      Send_Radio_Networks ("GSMR-A,GSMR-B,Telecom X");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_GSMR_Network)
             and then Win_Value = "GSMR-B",
             "11.7.1.4: the network selected before is proposed");
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then not DMI_Windows.Radio_Step_Displayed,
             "[Close] of S5-2-2 goes back to S5-1");
      -- A5 -> D9: an empty list
      Win_Menu_Long (6);
      Send_Radio_Networks ("");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 50 A5 -> D9 (GSM-R alone) -> S1");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_Known);
      Win_Menu (10);
      Win_Menu_Long (6);
      Send_Radio_Networks ("");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then not DMI_Windows.Radio_Step_Displayed,
             "Table 50 A5 -> D9 (both systems) -> S5-1");

      -- A7 -> S10: the Mission with one radio system window
      Win_Menu (7);
      Check (Win_Top_Is (DMI_Windows.W_One_Radio) and then Win_Value = "",
             "Table 50 S10: no value proposed");
      Step;
      Check_Frame ("win_one_radio");
      Drain_Outbox;
      Key (8);                                  -- 'Yes'
      Enter_Single;
      Expect_Driver_Data (7, (1 => 1), "'Yes': kind 7, value 1");
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 50 S10 'Yes' -> S5-1");
      Win_Menu (7);
      Drain_Outbox;
      Key (7);                                  -- 'No'
      Enter_Single;
      Expect_Driver_Data (7, (1 => 0), "'No': kind 7, value 0");
      Check (Win_Top_Is (DMI_Windows.W_Main), "Table 50 S10 'No' -> S1");

      -- Table 50 S4 -> D5: level 2 entered from the Main window
      Radio (Win_Radio_GSMR);
      Win_Menu (5);
      Choose_Level (2);
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 50 D5: valid RBC contact information, registered -> S8");
      Radio (Win_Radio_GSMR, Data => Win_Data_All);
      Win_Menu (5);
      Choose_Level (2);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 50 D5: without valid RBC contact information -> S5-1");
      Win_Default;
      Drain_Outbox;
   end Scenario_Win_Radio_Data;

   ---------------------------------------------------------------------
   -- The radio steps of the Start Up dialogue sequence (Table 49 S2 ->
   -- S3-1 .. S3-4, S3-2-x, A29 / A41 / A43 -> D10, S5, D7 -> S4 -> D9)
   ---------------------------------------------------------------------

   procedure Scenario_Win_Start_Up_Radio is
      --  the Driver ID is valid once entered, the level is not
      Data_ID : constant Win_U8 := 16#01#;

      procedure Radio (R : Win_U8; Data : Win_U8 := Data_ID or 16#04#;
                       SOM : Win_U8 := 2; Radio_Wait : Win_U8 := 0;
                       Waiting : Win_U8 := 0) is
      begin
         Win_Onboard (Data => Data, SOM => SOM, Radio => R,
                      Radio_Wait => Radio_Wait, Waiting => Waiting);
      end Radio;

      --  S0 -> S1 -> S2 -> S3-1 with the radio byte R
      procedure To_S3_1 (R : Win_U8) is
      begin
         Win_Onboard (Data => 0, SOM => 0, Radio => R);
         Send_Mode_Level (Mode => 1, Level => 0); -- SB, level unknown
         Win_Onboard (Data => 0, SOM => 2, Radio => R);
         Press (385, 240); Press (487, 90);    -- Driver ID 1
         Radio (R, Data => Data_ID);
         Choose_Level (2);
         Send_Mode_Level (Mode => 1, Level => 5);
         Radio (R);
      end To_S3_1;
   begin
      Reset;
      Win_At_Standstill;
      To_S3_1 (Win_Radio_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "Table 49 S2 level 2 -> S3-1: the Radio data window");
      Check (not DMI_Windows.Close_Enabled,
             "11.7.2.2: [Close] is disabled in S3-1");
      Step;
      Check_Frame ("win_startup_radio_data");

      -- S3-3 and S3-4 can be closed (11.7.2.2)
      Win_Menu (3);
      Check (Win_Top_Is (DMI_Windows.W_RBC_Data)
             and then DMI_Windows.Close_Enabled,
             "Table 49 S3-3: the RBC data window, [Close] enabled");
      Win_Close;
      Win_Menu (5);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Network_Type)
             and then DMI_Windows.Close_Enabled,
             "Table 49 S3-4: the Radio network type window, [Close] enabled");
      Key (3);
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "Table 49 S3-4 E6 -> S3-1");

      -- S3-2-1 .. S3-2-3
      Win_Menu_Long (6);
      Check (DMI_Windows.Radio_Step_Displayed
             and then not DMI_Windows.Close_Enabled,
             "Table 49 S3-2-1: hour glass, [Close] disabled");
      Send_Radio_Networks ("GSMR-A,GSMR-B,Telecom X");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_GSMR_Network)
             and then DMI_Windows.Close_Enabled,
             "Table 49 S3-2-2, [Close] enabled (11.7.2.2)");
      Key (1);
      Enter_Single;
      Radio (Win_Radio_GSMR, Radio_Wait => 2);
      Check (DMI_Windows.Radio_Step_Displayed
             and then not DMI_Windows.Close_Enabled,
             "Table 49 S3-2-3: hour glass, [Close] disabled");
      Radio (Win_Radio_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then not DMI_Windows.Radio_Step_Displayed
             and then DMI_Windows.In_Start_Up,
             "Table 49 S3-2-3 -> S3-1");

      -- A29 -> D10 -> S10
      Win_Menu_Long (6);
      Send_Radio_Networks ("");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 A29 -> D10 (GSM-R alone) -> S10");

      -- S3-1 'Contact last RBC' -> A31
      To_S3_1 (Win_Radio_GSMR);
      Drain_Outbox;
      Win_Menu (1);
      Expect_Driver_Data (5, Win_RBC_Bytes (1, 0, ""),
                          "S3-1 'Contact last RBC': kind 5, choice 1");
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S3-1 -> A31: the Main window");
      Radio (Win_Radio_GSMR, Waiting => 2);
      Check (DMI_Windows.Waiting_Displayed, "Table 49 A31: hour glass");
      Radio (Win_Radio_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Main), "Table 49 D31 .. -> S10");

      -- S3-4 E5 -> A41 -> D10
      To_S3_1 (Win_GSMR or Win_Both or Win_GSMR_Reg);
      Win_Menu (5);
      Key (1);                                  -- FRMCS, not registered
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S3-4 E5 -> A41 -> D10 (FRMCS alone) -> S10");
      To_S3_1 (Win_GSMR or Win_Both or Win_GSMR_Reg);
      Win_Menu (5);
      Key (2);                                  -- FRMCS+GSM-R
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "Table 49 S3-4 E5 -> A41 -> D10 (both systems) -> S3-1");

      -- A43 -> S5: E3, E2
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg);
      Win_Menu (7);
      Check (Win_Top_Is (DMI_Windows.W_One_Radio)
             and then DMI_Windows.In_Start_Up
             and then not DMI_Windows.Close_Enabled,
             "Table 49 A43 -> S5, [Close] disabled (11.7.2.2)");
      Key (8);
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "Table 49 S5 E3 ('Yes', RBC contact not valid) -> S3-1");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_One_Yes,
             Data => Data_ID or 16#14#);
      Win_Menu (7);
      Key (8);
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S5 E2 ('Yes', RBC contact valid) -> A31");

      -- D7 -> S4 -> A42 -> D9 -> S5 -> E4
      Win_Onboard (Data => 0, SOM => 0);
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2 stored
      Radio (Win_FRMCS_GSMR or Win_Both, Data => 16#04#, SOM => 2);
      Press (385, 240); Press (487, 90);    -- Driver ID 1
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 49 D2 / D3 level 2 -> D7 -> S4: the Main window");
      Radio (Win_FRMCS_GSMR or Win_Both, Waiting => 1);
      Check (DMI_Windows.Waiting_Displayed, "Table 49 S4: hour glass");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg);
      Check (Win_Top_Is (DMI_Windows.W_One_Radio)
             and then DMI_Windows.In_Start_Up
             and then not DMI_Windows.Close_Enabled,
             "Table 49 S4 -> A42 -> D9 -> S5");
      Step;
      Check_Frame ("win_startup_s5");
      Key (7);
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S5 E4 ('No') -> S10");

      -- D7 -> S4 -> A31: the registration completes, no S5
      Win_Onboard (Data => 0, SOM => 0);
      Radio (Win_FRMCS_GSMR or Win_Both, Data => 16#04#, SOM => 2);
      Press (385, 240); Press (487, 90);
      Radio (Win_FRMCS_GSMR or Win_Both, Waiting => 1);
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_FRMCS_Reg,
             Waiting => 2);
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_FRMCS_Reg);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S4 -> A31 -> S10: no S5 once registered");
      Drain_Outbox;
   end Scenario_Win_Start_Up_Radio;

   ---------------------------------------------------------------------
   -- The simulator answers the radio data (sim/evc_core.adb): the list
   -- of GSM-R networks, the registration and a session with its RBC
   ---------------------------------------------------------------------

   procedure Scenario_Win_Simulator is
      use type EVC_Core.Mode_T;

      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

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
                  EVC_Core.Handle_Driver_Data (Buffer (Offset .. Next - 1));
               end if;
               Offset := Next;
            end;
         end loop;
      end Pump_To_EVC;

      procedure Sim_Step is
      begin
         EVC_Core.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
         Pump_To_EVC;
         Drain_Sounds;
      end Sim_Step;

      procedure Touch (X, Y : Natural; Hold : Natural := 0) is
      begin
         EVC_Core.Step (0.05, Emit'Unrestricted_Access);
         Pointer_Down (X, Y);
         for I in 1 .. Hold loop
            DMI_Core.Tick (50);
         end loop;
         Pointer_Up (X, Y);
         DMI_Core.Tick (50);
         Pump_To_EVC;
         Drain_Sounds;
      end Touch;

      procedure Run (Steps : Natural) is
      begin
         for I in 1 .. Steps loop
            Sim_Step;
         end loop;
      end Run;
   begin
      Reset;
      EVC_Core.Reset;
      External_EVC;
      Run (3);
      Touch (385, 240); Touch (487, 90);       -- Driver ID 1
      Run (2);
      Touch (Key_X (2), Key_Y (2)); Touch (487, 90);  -- level 2
      Run (2);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "sim: level 2 in Start Up -> S3-1");

      -- the GSM-R network ID: list, selection, registration
      Touch (Win_Slot_X (6), Win_Slot_Y (6), Hold => 41);
      Run (5);
      Check (DMI_Windows.Radio_Step_Displayed,
             "sim: the on-board acquires the list (S3-2-1)");
      Run (20);
      Check (Win_Top_Is (DMI_Windows.W_GSMR_Network),
             "sim: the list arrives (S3-2-2)");
      Touch (Key_X (1), Key_Y (1)); Touch (487, 90);
      Run (5);
      Check (DMI_Windows.Radio_Step_Displayed,
             "sim: the Mobile Terminal registers (S3-2-3)");
      Run (20);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then not DMI_Windows.Radio_Step_Displayed,
             "sim: registered, back to S3-1");

      -- 'Use short number' -> A31, the session opens
      Touch (Win_Slot_X (2), Win_Slot_Y (2));
      Run (5);
      Check (DMI_Windows.Waiting_Displayed,
             "sim: the on-board contacts the RBC (A31)");
      Run (20);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.Waiting_Displayed,
             "sim: the session is open (S10)");

      -- Initiate SM: the RBC authorises it
      Touch (Win_Slot_X (11), Win_Slot_Y (11), Hold => 41);
      Run (5);
      Check (DMI_Windows.Waiting_Displayed, "sim: the RBC is asked for SM");
      Run (20);
      Check (EVC_Core.Mode = EVC_Core.SM and then not DMI_Windows.Is_Open,
             "sim: SM authorised -> the default window");
      DMI_Core.Render;
      Check_Frame ("win_sim_sm");

      -- Exit SM -> SB -> Start Up
      Touch (610, 40);
      Touch (Win_Slot_X (12), Win_Slot_Y (12), Hold => 41);
      Run (3);
      Check (EVC_Core.Mode = EVC_Core.SB and then DMI_Windows.In_Start_Up,
             "sim: Exit SM -> SB, Start Up engaged");
      External_EVC (False);
   end Scenario_Win_Simulator;

   ---------------------------------------------------------------------
   -- GEN-3, GEN-10, GEN-11: the devices of the DMI unit. The luminance
   -- and the volume take effect in the UI (MSG_SETTINGS) and are kept
   -- over a reset (5.2.2, 5.2.3); the desk keys for the Settings window
   -- (8.6.1.6) and the isolation (5.6.1.1, MSG_DESK_INPUT); the mode IS
   -- (8.2.3.1.2.2)
   ---------------------------------------------------------------------

   -- The scenarios below change the stored luminance and volume; they
   -- leave them as they found them
   HW_Saved_Luminance : General_Parameters.Display_Luminance_T;
   HW_Saved_Volume    : General_Parameters.Loudspeaker_Volume_T;

   procedure HW_Save is
   begin
      HW_Saved_Luminance := General_Parameters.Display_Luminance;
      HW_Saved_Volume := General_Parameters.Loudspeaker_Volume;
   end HW_Save;

   procedure HW_Restore is
   begin
      General_Parameters.Display_Luminance := HW_Saved_Luminance;
      General_Parameters.Loudspeaker_Volume := HW_Saved_Volume;
      General_Parameters.EVC_Link_Timeout_Ms := 0;
   end HW_Restore;

   -- 5.2.2 / 5.2.3: the values the windows propose after a change and
   -- after a reset, and what the UI is told
   procedure Scenario_HW_Settings_Stored is
      use type General_Parameters.Display_Luminance_T;
      use type General_Parameters.Loudspeaker_Volume_T;
   begin
      HW_Save;
      -- 5.2.2.2 / 5.2.3.2: nothing stored yet, the median of the range
      General_Parameters.Display_Luminance := 5;
      General_Parameters.Loudspeaker_Volume := 5;
      Reset;
      -- FS at standstill: Volume and Brightness enabled (Table 36)
      Send_Mode_Level (Mode => 2, Level => 4);
      Win_At_Standstill;
      Step;
      Expect_Settings (1, 5, 5, 0,
                       "MSG_SETTINGS once after Initialise and the start "
                       & "of the EVC link");
      Step;
      Expect_Settings (0, 0, 0, 0, "nothing changed: nothing sent");

      -- the Volume window proposes the stored value; the driver chooses
      -- the lowest level
      Press (610, 240);                        -- F5: Settings
      Win_Menu (2);                            -- Volume
      Check (Win_Top_Is (DMI_Windows.W_Volume), "hw: the Volume window");
      Check (Win_Value = "5", "11.7.1.4: the median volume is proposed");
      Key (1);                                 -- level 0
      Enter_Single;
      Check (General_Parameters.Loudspeaker_Volume = 0,
             "11.7.1.5: the accepted volume is stored");
      Expect_Settings (1, 5, 0, 0, "5.2.3.1: the UI learns the new volume");

      Win_Menu (3);                            -- Brightness
      Check (Win_Top_Is (DMI_Windows.W_Brightness),
             "hw: the Brightness window");
      Check (Win_Value = "5", "11.7.1.4: the median luminance is proposed");
      Key (3);                                 -- level 2
      Enter_Single;
      Check (General_Parameters.Display_Luminance = 2,
             "11.7.1.5: the accepted luminance is stored");
      Expect_Settings (1, 2, 0, 0,
                       "5.2.2.1: the UI learns the new luminance");

      -- revalidation of the same value: nothing new for the UI
      Win_Menu (3);
      Enter_Single;
      Expect_Settings (0, 0, 0, 0, "the same luminance again: not sent");
      Win_Default;

      -- the reset of the DMI (a new mission, a restart of its software):
      -- the values are the DMI unit's and stay (5.2.2.2, 5.2.3.2)
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Win_At_Standstill;
      Step;
      Check (General_Parameters.Display_Luminance = 2
             and then General_Parameters.Loudspeaker_Volume = 0,
             "5.2.2.2 / 5.2.3.2: the stored values survive a reset");
      Expect_Settings (1, 2, 0, 0,
                       "after a restart the UI is told the stored values");
      Press (610, 240);                        -- F5: Settings
      Win_Menu (2);
      Check (Win_Value = "0",
             "11.7.1.4: after the reset the stored volume is proposed");
      Step;
      Check_Frame ("hw_volume_after_reset");
      Win_Close;
      Win_Menu (3);
      Check (Win_Value = "2",
             "11.7.1.4: after the reset the stored luminance is proposed");
      Step;
      Check_Frame ("hw_brightness_after_reset");
      Win_Default;

      -- the EVC link: its return after a loss tells the UI again (a UI
      -- may have (re)connected with it); the loss keeps the values
      -- (the wrapper's EVC keeps quiet, so that the link times out)
      External_EVC;
      General_Parameters.EVC_Link_Timeout_Ms := 1000;
      Send_Mode_Level (Mode => 1, Level => 4);
      Expect_Settings (0, 0, 0, 0, "hw: the link is up, nothing new");
      for I in 1 .. 21 loop
         Step;
      end loop;
      Check (DMI_Core.EVC_Link_Lost, "hw: the EVC link is lost");
      Check (General_Parameters.Display_Luminance = 2
             and then General_Parameters.Loudspeaker_Volume = 0,
             "the link loss keeps the stored values");
      Expect_Settings (0, 0, 0, 0, "the loss itself sends nothing");
      Send_Mode_Level (Mode => 1, Level => 4);
      Check (not DMI_Core.EVC_Link_Lost, "hw: the EVC is back");
      Expect_Settings (1, 2, 0, 0, "the EVC link restarts: told again");
      Send_Mode_Level (Mode => 1, Level => 4);
      Expect_Settings (0, 0, 0, 0, "and not on every EVC message");

      -- the UI message waits in DMI_Core rather than being dropped when
      -- the caller only takes the driver's actions
      General_Parameters.Loudspeaker_Volume := 7;
      Step;                                    -- takes actions only
      Expect_Settings (1, 2, 7, 0, "the change waits for the UI");
      HW_Restore;
      Reset;
      Drain_Outbox;
   end Scenario_HW_Settings_Stored;

   -- 8.6.1.6: the desk key for the Settings window
   procedure Scenario_HW_Desk_Settings is
      use DMI_Protocol;
   begin
      Reset;
      Step;
      -- 8.6.1.7: an up-type button: nothing on the way down
      Send_Desk_Input (DESK_SETTINGS, 1);
      Step;
      Check (not DMI_Windows.Is_Open, "8.6.1.7: nothing while held down");
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "8.6.1.6: the desk key opens the Settings window");
      Check_Frame ("hw_desk_settings");
      Expect_No_Sound ("the desk key plays no click (5.3.2.2.1 b)");

      -- a window is displayed: only it responds (5.3.1.1.5)
      Send_Desk_Input (DESK_SETTINGS, 1);
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Win_Close;
      Check (not DMI_Windows.Is_Open,
             "the key over the Settings window stacks nothing");
      Press (610, 40);                         -- F1: Main
      Send_Desk_Input (DESK_SETTINGS, 1);
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "5.3.1.1.5: over the Main window the key is ignored");
      Win_Default;

      -- pressed on the default window, released over another window
      Send_Desk_Input (DESK_SETTINGS, 1);
      Press (610, 140);                        -- F3: Data view
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Data_View),
             "released over the Data view: ignored");
      Win_Default;
      -- pressed over a window, released on the default window
      Press (610, 40);                         -- F1: Main
      Send_Desk_Input (DESK_SETTINGS, 1);
      Win_Default;
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (not DMI_Windows.Is_Open,
             "pressed over the Main window: ignored when released");
      -- up without down
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (not DMI_Windows.Is_Open, "a key up alone does nothing");

      -- a window that cannot be left: Start Up before S10 (11.7.2.2)
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Check (DMI_Windows.In_Start_Up
             and then Win_Top_Is (DMI_Windows.W_Driver_ID),
             "hw: Start Up with the Driver ID window");
      Send_Desk_Input (DESK_SETTINGS, 1);
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (DMI_Windows.In_Start_Up
             and then Win_Top_Is (DMI_Windows.W_Driver_ID),
             "11.7.2 / 5.3.1.1.5: Start Up is not left for Settings");
      Send_Mode_Level (Mode => 16, Level => 4); -- SL ends Start Up
      Step;
      Check (not DMI_Windows.Is_Open, "hw: the default window again");

      -- the key works in any mode on the default window (8.6.1.4),
      -- also while the EVC link is lost (SF)
      General_Parameters.EVC_Link_Timeout_Ms := 1000;
      Send_Mode_Level (Mode => 2, Level => 4);
      for I in 1 .. 21 loop
         Step;
      end loop;
      Check (DMI_Core.EVC_Link_Lost, "hw: SF, the link is lost");
      Send_Desk_Input (DESK_SETTINGS, 1);
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "8.6.1.4: the Settings window in SF too");
      General_Parameters.EVC_Link_Timeout_Ms := 0;
      Reset;

      -- malformed input: the whole message is ignored
      Send_Raw (16#52#, (1 => 1));
      Send_Raw (16#52#, (1 => 1, 2 => 0, 3 => 0));
      Send_Raw (16#52#, (1 .. 0 => 0));
      Step;
      Check (not DMI_Windows.Is_Open, "wrong lengths are ignored");
      Send_Desk_Input (DESK_SETTINGS, 1);
      Send_Raw (16#52#, (1 => 1, 2 => 1, 3 => 7));
      Send_Desk_Input (DESK_SETTINGS, 2);      -- neither down nor up
      Send_Desk_Input (DESK_SETTINGS, 255);
      Step;
      Check (not DMI_Windows.Is_Open,
             "a pressed byte other than 0 / 1 is ignored");
      Send_Desk_Input (DESK_SETTINGS, 0);      -- the real release
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "the key stays pressed through ignored messages");
      Win_Default;
      for Input of Byte_Array'(0, 3, 4, 127, 255) loop
         Send_Desk_Input (Input, 1);
         Send_Desk_Input (Input, 0);
      end loop;
      Step;
      Check (not DMI_Windows.Is_Open, "unknown desk inputs are ignored");
      Expect_Actions (20, 0, "and send nothing to the EVC");
      Drain_Sounds;
   end Scenario_HW_Desk_Settings;

   -- 5.6.1.1: the means to isolate the on-board, a delay-type desk key;
   -- 8.2.3.1.2.2: the mode IS is indicated by the isolation device
   procedure Scenario_HW_Isolation is
      use DMI_Protocol;
      use type Supplementary_Driving_Info.Mode_T;

      procedure Hold (Steps : Natural) is
      begin
         Send_Desk_Input (DESK_ISOLATION, 1);
         for I in 1 .. Steps loop
            Step;
         end loop;
         Send_Desk_Input (DESK_ISOLATION, 0);
         Step;
      end Hold;
   begin
      HW_Save;
      General_Parameters.Display_Luminance := 5;
      General_Parameters.Loudspeaker_Volume := 5;
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);  -- FS, L1
      Send_Speed_State (V_Cur => 80, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Expect_Settings (1, 5, 5, 0, "hw: not isolated");

      -- 5.3.2.6.6: released before 2 s, no activation
      Hold (39);                               -- 1.95 s
      Expect_Actions (20, 0, "5.3.2.6.6: less than 2 s: no isolation");
      -- held for 2 s: the activation when the key comes up
      Send_Desk_Input (DESK_ISOLATION, 1);
      for I in 1 .. 45 loop
         Step;
      end loop;
      Expect_Actions (20, 0, "5.3.2.6.6: nothing while still held");
      Send_Desk_Input (DESK_ISOLATION, 0);
      Step;
      Expect_Action (20, 0, "5.6.1.1: the isolation request to the EVC");
      Expect_No_Sound ("the desk key plays no click (5.3.2.2.1 b)");

      -- SUBSET-026 4.7.2: in every mode and whatever window is shown
      Press (610, 240);                        -- F5: Settings
      Hold (40);
      Expect_Action (20, 0, "isolation over the Settings window");
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "the window is not affected");
      Win_Default;
      -- a key down repeated keeps the timer running
      Send_Desk_Input (DESK_ISOLATION, 1);
      for I in 1 .. 20 loop
         Step;
      end loop;
      Send_Desk_Input (DESK_ISOLATION, 1);
      for I in 1 .. 20 loop
         Step;
      end loop;
      Send_Desk_Input (DESK_ISOLATION, 0);
      Step;
      Expect_Action (20, 0, "a repeated key down does not restart it");
      Send_Mode_Level (Mode => 1, Level => 4);  -- SB: Start Up
      Step;
      Check (DMI_Windows.In_Start_Up, "hw: Start Up");
      Hold (40);
      Expect_Action (20, 0, "isolation during Start Up");
      Send_Mode_Level (Mode => 16, Level => 4); -- SL
      Hold (40);
      Expect_Action (20, 0, "isolation in SL");

      -- the EVC reports IS: B7 shows no symbol (8.2.3.1.2 has none),
      -- the isolation device indicates it (8.2.3.1.2.2)
      Send_Mode_Level (Mode => 17, Level => 4); -- IS
      Step;
      Check (Supplementary_Driving_Info.Mode = Supplementary_Driving_Info.M_IS,
             "hw: the mode IS is taken over");
      Check_Frame ("hw_mode_is");
      Expect_Settings (1, 5, 5, 1,
                       "8.2.3.1.2.2: the isolation device lights up");
      Step;
      Expect_Settings (0, 0, 0, 0, "and stays lit, nothing new");
      -- the isolation key stays available in IS (4.7.2: X in IS)
      Hold (40);
      Expect_Action (20, 0, "the key in IS too");
      -- leaving IS (the special procedure of SUBSET-026 4.4.3.1.3 is
      -- outside the DMI; the EVC reports another mode)
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Expect_Settings (1, 5, 5, 0, "the indication goes out");
      -- the link loss shows SF: no longer IS
      Send_Mode_Level (Mode => 17, Level => 4);
      Step;
      Expect_Settings (1, 5, 5, 1, "hw: IS again");
      General_Parameters.EVC_Link_Timeout_Ms := 1000;
      for I in 1 .. 21 loop
         Step;
      end loop;
      Check (DMI_Core.EVC_Link_Lost, "hw: the link is lost");
      Expect_Settings (1, 5, 5, 0, "SF is shown instead of IS");
      General_Parameters.EVC_Link_Timeout_Ms := 0;

      -- a DMI reset forgets a key held down
      Reset;
      Send_Desk_Input (DESK_ISOLATION, 1);
      for I in 1 .. 41 loop
         Step;
      end loop;
      DMI_Core.Initialise;
      Send_Desk_Input (DESK_ISOLATION, 0);
      Step;
      Expect_Actions (20, 0, "Initialise releases the desk keys");
      -- malformed: the key down of a wrong length is not a key down
      Send_Raw (16#52#, (1 => 2, 2 => 1, 3 => 0));
      for I in 1 .. 41 loop
         Step;
      end loop;
      Send_Desk_Input (DESK_ISOLATION, 0);
      Step;
      Expect_Actions (20, 0, "a key down of a wrong length is ignored");
      Drain_Sounds;
      HW_Restore;
      Reset;
      Drain_Outbox;
   end Scenario_HW_Isolation;

   -- The simulator's on-board takes the isolation request (action 20)
   -- and reports IS; no other request leaves it (SUBSET-026 4.4.3.1.3)
   procedure Scenario_HW_Simulator_Isolation is
      use type EVC_Core.Mode_T;
      use type Supplementary_Driving_Info.Mode_T;

      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;
   begin
      Reset;
      EVC_Core.Reset;
      External_EVC;
      EVC_Core.Step (0.1, Emit'Unrestricted_Access);
      Check (Supplementary_Driving_Info.Mode = Supplementary_Driving_Info.M_SB,
             "sim: SB");
      EVC_Core.Handle_Driver_Action (20, 0);
      EVC_Core.Step (0.1, Emit'Unrestricted_Access);
      Check (EVC_Core.Mode = EVC_Core.Isolation
             and then Supplementary_Driving_Info.Mode
                        = Supplementary_Driving_Info.M_IS,
             "sim: action 20 -> IS, reported to the DMI");
      EVC_Core.Handle_Driver_Action (7, 0);      -- shunting
      EVC_Core.Handle_Driver_Action (5, 0);      -- start of mission
      EVC_Core.Step (0.1, Emit'Unrestricted_Access);
      Check (EVC_Core.Mode = EVC_Core.Isolation,
             "sim: no transition from IS");
      EVC_Core.Reset;
      Check (EVC_Core.Mode = EVC_Core.SB, "sim: the reset leaves IS");
      External_EVC (False);
      Reset;
      Drain_Outbox;
   end Scenario_HW_Simulator_Isolation;


   ---------------------------------------------------------------------
   -- P3, audit WIN-12 / WIN-13 (the rest but Language) and SDI-8: the
   -- Settings buttons of Table 36 #4 to #6, the Set VBC and Remove VBC
   -- windows (11.3.12, 11.3.13) with their validation windows (11.4.2,
   -- 11.4.3) and the Settings dialogue sequence (Table 54 S5 to S7-2),
   -- the System version window (11.5.2), the National System name in
   -- the level symbols (8.2.3.2.9, 8.2.3.2.10) and the Table 45 items
   -- of the Data view that the DMI now holds
   ---------------------------------------------------------------------

   --  MSG_ONBOARD national bits 2 and 3 (dmi_protocol.ads)
   VBC_Room_Bit   : constant Win_U8 := 16#04#;
   VBC_Stored_Bit : constant Win_U8 := 16#08#;

   procedure VBC_Onboard (National : Win_U8;
                          Train    : Win_U8 := Win_Standing;
                          Data     : Win_U8 := Win_Data_All;
                          Radio    : Win_U8 := 0) is
   begin
      Send_Onboard_Raw (Data, 0, 0, Train, Win_NV or National, 0, 0, 0,
                        Radio, 0, 0);
      Step;
   end VBC_Onboard;

   procedure VBC_Settings is
   begin
      Win_Default;
      Press (610, 240);                         -- F5: Settings
   end VBC_Settings;

   --  Table 29 / Table 25: 'No' is key 7, 'Yes' key 8; the input field
   --  of the validation window at y 0 is its [Enter]
   procedure VBC_Validate (Yes : Boolean) is
   begin
      Press ((if Yes then 487 else 385), 340);
      Press (487, 40);
   end VBC_Validate;

   --  The wire bytes of a VBC code after the kind (kinds 8 and 9)
   function VBC_Bytes (Code : Natural) return Byte_Array is
     ((Code mod 256, (Code / 256) mod 256, (Code / 65536) mod 256,
       Code / 16777216));

   procedure Scenario_VBC_Settings is
   begin
      Reset;
      VBC_Onboard (National => 0);
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Win_At_Standstill;
      VBC_Settings;
      Check (Win_Top_Is (DMI_Windows.W_Settings), "vbc: the Settings window");
      Check (Win_Enabled (4), "Table 36 #4: System version in SB at standstill");
      Check (not Win_Enabled (5),
             "Table 36 #5: no Set VBC when the VBC storage is full");
      Check (not Win_Enabled (6), "Table 36 #6: no Remove VBC with none stored");
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit);
      Check (Win_Enabled (5) and then Win_Enabled (6),
             "Table 36 #5, #6: Set / Remove VBC in SB at standstill");
      Check_Frame ("vbc_settings");
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit,
                   Train => Win_Running);
      Check (not Win_Enabled (4) and then not Win_Enabled (5)
             and then not Win_Enabled (6),
             "Table 36 #4 to #6: not in SB while running");
      Send_Mode_Level (Mode => 2, Level => 4);  -- FS
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit,
                   Train => Win_Running);
      Check (Win_Enabled (4) and then not Win_Enabled (5)
             and then not Win_Enabled (6),
             "Table 36: System version in FS, Set / Remove VBC in SB only");
      Send_Mode_Level (Mode => 1, Level => 4);
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit);

      -- Table 54 S6-1: from S1 no value is proposed
      VBC_Settings;
      Win_Menu (5);
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC)
             and then Win_Value = "",
             "Table 54 S1 -> S6-1: the Set VBC window, no value proposed");
      Check (DMI_Windows.Close_Enabled, "11.7.7.2: [Close] enabled");
      -- 11.3.12.5 / SUBSET-026 7.5.1.154.1: 24 bits at most
      Win_Type ("16777216");
      Enter_Field (1);
      Step;
      Check_Frame ("vbc_set_out_of_range");
      Drain_Outbox;
      Press (167, 440);
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC),
             "10.3.4.2: a code above 16 777 215 cannot be completed");
      for I in 1 .. 8 loop
         Key (10);                              -- [Delete]
      end loop;
      Win_Type ("321456");
      Enter_Field (1);
      Step;
      Check_Frame ("vbc_set_entered");          -- Figure 128
      Press (167, 440);                         -- Set VBC entry complete? Yes
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC_Validation)
             and then Win_Value = "Yes",
             "Table 54 S6-1 -> S6-2: the validation window proposes 'Yes'");
      Expect_No_Driver_Data
        (8, "11.7.1.6.2: nothing is sent when 'Yes' of S6-1 is pressed");
      Step;
      Check_Frame ("vbc_set_validation");       -- Figure 131
      -- 'No' -> S6-1 with the previous value proposed
      VBC_Validate (Yes => False);
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC)
             and then Win_Value = "321456",
             "Table 54 S6-2 'No' -> S6-1, the previous value proposed");
      Expect_No_Driver_Data (8, "'No' sends nothing");
      Press (167, 440);
      VBC_Validate (Yes => True);
      Expect_Driver_Data (8, VBC_Bytes (321456),
                          "Table 54 S6-2 'Yes': kind 8 with the set code");
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S6-2 'Yes' -> S1, the Settings window");

      -- [Close] of S6-2: the process stops, a new one proposes nothing
      Win_Menu (5);
      Win_Type ("12");
      Enter_Field (1);
      Press (167, 440);
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC) and then Win_Value = "",
             "[Close] of S6-2 -> the Set VBC window, no value proposed");
      Drain_Outbox;
      Win_Close;
      Expect_No_Driver_Data (8, "[Close] sends nothing");
      Check (Win_Top_Is (DMI_Windows.W_Settings), "[Close] -> Settings");

      -- Remove VBC, Table 54 S7-1 / S7-2
      Win_Menu (6);
      Check (Win_Top_Is (DMI_Windows.W_Remove_VBC) and then Win_Value = "",
             "Table 54 S1 -> S7-1: the Remove VBC window, nothing proposed");
      Win_Type ("50078");
      Enter_Field (1);
      Step;
      Check_Frame ("vbc_remove_entered");       -- Figure 129
      Press (167, 440);
      Check (Win_Top_Is (DMI_Windows.W_Remove_VBC_Validation),
             "Table 54 S7-1 -> S7-2");
      Expect_No_Driver_Data (9, "11.7.1.6.2: nothing sent before S7-2");
      Step;
      Check_Frame ("vbc_remove_validation");    -- Figure 132
      VBC_Validate (Yes => False);
      Check (Win_Top_Is (DMI_Windows.W_Remove_VBC)
             and then Win_Value = "50078",
             "Table 54 S7-2 'No' -> S7-1, the previous value proposed");
      Press (167, 440);
      VBC_Validate (Yes => True);
      Expect_Driver_Data (9, VBC_Bytes (50078),
                          "Table 54 S7-2 'Yes': kind 9 with the remove code");
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S7-2 'Yes' -> S1, the Settings window");

      -- the largest code of 24 bits goes through
      Win_Menu (5);
      Win_Type ("16777215");
      Enter_Field (1);
      Press (167, 440);
      VBC_Validate (Yes => True);
      Expect_Driver_Data (8, VBC_Bytes (16777215),
                          "the largest set code, 16 777 215");

      -- 11.7.1.9: a driver's acknowledgement stops the process
      Win_Menu (5);
      Win_Type ("7");
      Enter_Field (1);
      Press (167, 440);
      Send_Text (91, "Ack me", Ack_Required => True);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "11.7.1.9: the acknowledgement stops Set VBC -> Settings");
      Send_Text_Remove (91);                    -- the EVC withdraws it
      for I in 1 .. 30 loop
         Step;
      end loop;
      Drain_Sounds;
      Drain_Outbox;

      -- Table 48 names no enabling condition for these windows: they
      -- stay when 'Set VBC' loses its conditions (11.7.1.7)
      Win_Default;
      VBC_Settings;
      Win_Menu (5);
      VBC_Onboard (National => VBC_Stored_Bit);
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC),
             "Table 48 has no Set VBC row: the window stays");
      Win_Default;
      Drain_Outbox;
   end Scenario_VBC_Settings;

   ---------------------------------------------------------------------
   -- 11.5.2: the System version window and MSG_SYSTEM_VERSION
   ---------------------------------------------------------------------

   procedure Scenario_VBC_System_Version is
   begin
      Reset;
      VBC_Onboard (National => 0);
      Send_Mode_Level (Mode => 1, Level => 4);
      Win_At_Standstill;
      VBC_Settings;
      Win_Menu (4);
      Check (Win_Top_Is (DMI_Windows.W_System_Version),
             "Table 54 S1 -> S5: the System version window");
      Check (DMI_Windows.Button_Count = 0,
             "Figure 135: no button but [Close]");
      Step;
      Check_Frame ("vbc_system_version_unknown");
      Send_System_Version (3, 0);
      Step;
      Check_Frame ("vbc_system_version");       -- Figure 135
      -- malformed and out of range
      Send_Raw (16#0E#, (1 => 2));
      Send_Raw (16#0E#, (2, 3, 0));
      Check (DMI_System_Version.Image = "3.0",
             "MSG_SYSTEM_VERSION of a wrong length is ignored");
      Send_System_Version (2, 3);
      Check (DMI_System_Version.Image = "2.3", "2.3 is taken");
      Send_System_Version (8, 0);
      Check (not DMI_System_Version.Known,
             "X above 7: the version is not known");
      Send_System_Version (2, 3);
      Send_System_Version (2, 16);
      Check (not DMI_System_Version.Known,
             "Y above 15: the version is not known");
      Step;
      Check_Frame ("vbc_system_version_unknown");
      Send_System_Version (3, 0);
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S5 [Close] -> S1");
      Win_Default;
   end Scenario_VBC_System_Version;

   ---------------------------------------------------------------------
   -- SDI-8, 8.2.3.2.9 / 8.2.3.2.10: the abbreviation of the National
   -- System in LE02, LE08 and LE09
   ---------------------------------------------------------------------

   procedure Scenario_VBC_Level_Name is
      function Name return Wide_String is
        (Supplementary_Driving_Info.National_Name.Text
           (1 .. Supplementary_Driving_Info.National_Name.Length));
   begin
      Reset;
      Send_Mode_Level (Mode => 8, Level => 3, National_Name => "PZB");
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      Step;
      Check_Frame ("vbc_level_name_c8");
      Send_Mode_Level (Mode => 8, Level => 3, National_Name => "ATB");
      Step;
      Check_Frame ("vbc_level_name_c8_short");
      -- 8.2.3.2.10: a name wider than 48 cells even with characters of
      -- 10 cells is cut at the edge of that space
      Send_Mode_Level (Mode => 8, Level => 3, National_Name => "PZB/LZB");
      Step;
      Check_Frame ("vbc_level_name_c8_wide");
      -- 8.2.3.2.2: nothing in C8 in SN and NL, with or without a name
      Send_Mode_Level (Mode => 12, Level => 3, National_Name => "ATB");
      Step;
      Check_Frame ("level_ntc_sn_c8_empty");
      -- the 9 byte form: no name, LE02
      Send_Mode_Level (Mode => 8, Level => 3);
      Step;
      Check (Name = "", "the 9 byte message: no name");
      Check_Frame ("level_ntc_sh_le02");
      -- name_len 0 in the long form: no name either
      Send_Raw (16#02#, (8, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#, 16#FF#, 0));
      Check (Name = "", "name_len 0: no name");

      -- malformed: ignored as a whole (the mode byte would be FS)
      Send_Mode_Level (Mode => 8, Level => 3, National_Name => "ATB");
      Send_Raw (16#02#, (2, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#, 16#FF#,
                         3, 65, 66));
      Send_Raw (16#02#, (2, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#, 16#FF#,
                         2, 65, 66, 67));
      Send_Raw (16#02#, (2, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#, 16#FF#,
                         11, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65));
      Send_Raw (16#02#, (2, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#));
      Check (Name = "ATB"
             and then Supplementary_Driving_Info."="
                        (Supplementary_Driving_Info.Mode,
                         Supplementary_Driving_Info.M_SH),
             "MSG_MODE_LEVEL of a wrong length is ignored as a whole");
      -- the longest name
      Send_Raw (16#02#, (8, 3, 16#FF#, 16#FF#, 0, 0, 0, 16#FF#, 16#FF#,
                         10, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74));
      Check (Name = "ABCDEFGHIJ", "a name of 10 characters is taken");
      Step;
      Check_Frame ("vbc_level_name_c8_cut");

      -- LE08: the announcement of level NTC
      Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 3,
                       National_Name => "PZB/LZB");
      Step;
      Check_Frame ("vbc_level_name_le08");
      Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 3,
                       National_Name => "ATB");
      Step;
      Check_Frame ("vbc_level_name_le08_short");
      -- LE09: with acknowledgement, yellow
      Send_Mode_Level (Mode => 2, Level => 4, Level_Ann => 3,
                       Level_Ann_Ack => True, National_Name => "PZB/LZB");
      Step;
      Drain_Sounds;
      Check_Frame ("vbc_level_name_le09");
      Send_Mode_Level (Mode => 2, Level => 4);
      Step;
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_VBC_Level_Name;

   ---------------------------------------------------------------------
   -- Table 45 items 11 to 16...: the radio data info and the VBCs stored
   -- on-board in the Data view window (11.5.1.6, 11.5.1.6.1)
   ---------------------------------------------------------------------

   procedure Scenario_VBC_Data_View is
      procedure Set (Value : out DMI_Driver_Data.Text_Value_T;
                     Text  : Wide_String) is
      begin
         Value.Length := Text'Length;
         Value.Text (1 .. Text'Length) := Text;
      end Set;

      Radio_Both : constant Win_U8 :=
        Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_Known;
      RBC_Valid  : constant Win_U8 := Win_Data_All or 16#10#;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 5);  -- SB, level 2
      VBC_Onboard (National => 0, Data => RBC_Valid, Radio => Radio_Both);
      Win_At_Standstill;
      Win_Default;
      Press (610, 140);                         -- F3: Data view
      Press_Next;
      Step;
      Check_Frame ("vbc_data_view_p2_empty");

      -- Figure 134: what the driver entered on this DMI
      DMI_Radio_Data.GSMR_Network.Length := 6;
      DMI_Radio_Data.GSMR_Network.Text (1 .. 6) := "GSMR-A";
      Set (DMI_Radio_Data.RBC_ID, "12345678");
      Set (DMI_Radio_Data.RBC_Phone, "1234567809123456");
      DMI_Radio_Data.RBC_Entered := True;
      DMI_Radio_Data.Last_Choice := DMI_Radio_Data.Entered;
      Send_VBC_List ((71951, 321456));
      Step;
      Check_Frame ("vbc_data_view_p2");
      Check (DMI_Data_View.Title = "Data view (2/2)", "two windows");

      -- 11.5.1.6.1: no phone number without GSM-R
      VBC_Onboard (National => 0, Data => RBC_Valid,
                   Radio => Win_FRMCS or Win_Only_FRMCS or Win_Known);
      Step;
      Check_Frame ("vbc_data_view_p2_frmcs");
      -- after 'Contact last RBC' the RBC data are the on-board's
      VBC_Onboard (National => 0, Data => RBC_Valid,
                   Radio => Win_GSMR or Win_Only_GSMR or Win_Known);
      DMI_Radio_Data.Last_Choice := DMI_Radio_Data.Contact_Last_RBC;
      Step;
      Check_Frame ("vbc_data_view_p2_last_rbc");
      DMI_Radio_Data.Last_Choice := DMI_Radio_Data.Entered;

      -- "2..n": the VBCs that do not fit go on to window 3
      Send_VBC_List ((1, 22, 333, 4444, 55555, 666666, 7777777, 16777215,
                      9, 10, 11, 12, 13, 14, 15, 16));
      Step;
      Check (DMI_Data_View.Title = "Data view (2/3)", "16 VBCs: three windows");
      Check_Frame ("vbc_data_view_p2_full");
      Press_Next;
      Check_Frame ("vbc_data_view_p3");
      Check (not DMI_Windows.Button_Enabled (DMI_Data_View.Next_Button),
             "[Next] disabled on the last window");

      -- malformed lists are ignored as a whole
      Send_Raw (16#0F#, (1 => 17));
      Send_Raw (16#0F#, (2, 1, 0, 0, 0));
      Send_Raw (16#0F#, (1, 0, 0, 0, 1));             -- 2**24
      Send_Raw (16#0F#, (1 => 0, 2 => 0));
      Send_Raw (16#0F#, (1 .. 0 => 0));
      Check (DMI_VBC.Count = 16, "malformed MSG_VBC_LIST is ignored");
      -- the list shrinks while window 3 is displayed: the last window
      Send_VBC_List ((1 => 71951));
      Step;
      Check (DMI_Data_View.Title = "Data view (2/2)",
             "a shorter list: back to the last window");
      Send_VBC_List ((1 .. 0 => 0));
      Step;
      Check_Frame ("vbc_data_view_p2_no_vbc");
      Win_Default;
   end Scenario_VBC_Data_View;

   ---------------------------------------------------------------------
   -- The simulator stores what the driver sets and removes, and reports
   -- it (MSG_VBC_LIST, MSG_ONBOARD national bits)
   ---------------------------------------------------------------------

   procedure Scenario_VBC_Simulator is
      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

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
                  EVC_Core.Handle_Driver_Data (Buffer (Offset .. Next - 1));
               end if;
               Offset := Next;
            end;
         end loop;
      end Pump_To_EVC;

      procedure Run (Steps : Natural) is
      begin
         for I in 1 .. Steps loop
            EVC_Core.Step (0.1, Emit'Unrestricted_Access);
            DMI_Core.Tick (100);
            Pump_To_EVC;
            Drain_Sounds;
         end loop;
      end Run;

      procedure Touch (X, Y : Natural) is
      begin
         Pointer_Down (X, Y);
         Pointer_Up (X, Y);
         DMI_Core.Tick (50);
         Pump_To_EVC;
         Run (1);
      end Touch;

      Stored : Natural;
   begin
      Reset;
      EVC_Core.Reset;
      External_EVC;
      Run (3);
      Stored := DMI_VBC.Count;
      Check (DMI_VBC.Known and then Stored >= 1
             and then DMI_System_Version.Image = "3.0",
             "sim: the VBC list and the system version are reported");
      Touch (385, 240); Touch (487, 90);       -- Driver ID 1
      Touch (Key_X (1), Key_Y (1)); Touch (487, 90);  -- level 1
      Touch (370, 440);                        -- [Close] the Main window
      Touch (610, 240);                        -- F5: Settings
      Check (Win_Top_Is (DMI_Windows.W_Settings)
             and then Win_Enabled (5) and then Win_Enabled (6),
             "sim: Set VBC and Remove VBC on offer");
      -- set 321456 (NID_VBCMK 48, NID_C 926, T_VBC 4)
      Touch (Win_Slot_X (5), Win_Slot_Y (5));
      for C of String'("321456") loop
         Touch (Key_X (Character'Pos (C) - Character'Pos ('0')),
                Key_Y (Character'Pos (C) - Character'Pos ('0')));
      end loop;
      Touch (589, 40);
      Touch (167, 440);
      Touch (487, 40);
      Run (2);
      Check (DMI_VBC.Count = Stored + 1
             and then DMI_VBC.Codes (DMI_VBC.Count) = 321456,
             "sim: the VBC set by the driver is stored and reported");
      -- remove it by its remove code 50078 (11.3.13.5)
      Touch (Win_Slot_X (6), Win_Slot_Y (6));
      for C of String'("50078") loop
         if C = '0' then
            Touch (Key_X (11), Key_Y (11));
         else
            Touch (Key_X (Character'Pos (C) - Character'Pos ('0')),
                   Key_Y (Character'Pos (C) - Character'Pos ('0')));
         end if;
      end loop;
      Touch (589, 40);
      Touch (167, 440);
      Touch (487, 40);
      Run (2);
      Check (DMI_VBC.Count = Stored,
             "sim: the VBC removed by the driver is gone");
      -- the level NTC of the simulator carries its National System
      Touch (370, 440);                        -- [Close] Settings
      Touch (610, 40);                         -- F1: Main
      Touch (Win_Slot_X (5), Win_Slot_Y (5));  -- Level
      Touch (Key_X (5), Key_Y (5)); Touch (487, 90);   -- NTC
      Run (2);
      Check (Supplementary_Driving_Info.National_Name.Length = 3,
             "sim: level NTC with the name of its National System");
      Win_Default;
      Run (1);
      DMI_Core.Render;
      Check_Frame ("vbc_sim_level_ntc");
      External_EVC (False);
   end Scenario_VBC_Simulator;

   ---------------------------------------------------------------------
   -- Languages (audit GEN-2: DMI 5.5, 11.3.6, Table 36 #1, Table 48,
   -- Table 54 S2): the Language window, every text in the selected
   -- language, the selection kept over a reset, MSG_DRIVER_DATA kind 10
   ---------------------------------------------------------------------

   package TX renames DMI_Texts;

   function Lang_Is (L : TX.Language_T) return Boolean is
     (TX."=" (TX.Selected, L));

   --  The wire bytes of kind 10 after the kind: the ISO 639-1 code
   function Lang_Bytes (Code : String) return Byte_Array is
     ((Character'Pos (Code (Code'First)),
       Character'Pos (Code (Code'First + 1))));

   --  SB, level 1, a standing train whose data are all valid
   procedure Lang_Standstill is
   begin
      Reset;
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit);
      Send_Mode_Level (Mode => 1, Level => 4);
      Win_At_Standstill;
      Drain_Outbox;
   end Lang_Standstill;

   --  Table 54 S1 -> S2: Settings, then the Language window; Key is the
   --  key of the language (1 Deutsch, 2 English, 3 Magyar, Figure 119),
   --  accepted on the input field
   procedure Lang_Select (Key_Number : Positive) is
   begin
      Win_Default;
      Press (610, 240);                          -- F5: Settings
      Win_Menu (1);                              -- SE03: Language
      Key (Key_Number);
      Enter_Single;
   end Lang_Select;

   --  Leave the scenarios in English, whatever happened
   procedure Lang_English is
   begin
      TX.Select_Language (TX.English);
      Win_Default;
      Drain_Outbox;
   end Lang_English;

   --  5.5.1.3 with the layout rules the English texts follow: in every
   --  language a text fits the object it is drawn in, on one line or,
   --  for the buttons and the keys, broken over two at a space the way
   --  Draw_Labelled_Button and Draw_Choice_Key break it
   procedure Scenario_Lang_Texts_Fit is
      use type TX.Text_ID;

      function Width (S : Wide_String) return Natural is
        (Display.Draw.String_Width (S, 12));

      --  one line, or the last space that leaves the first line inside
      --  Room and a second line that fits as well
      function Fits (S : Wide_String; Room : Natural) return Boolean is
         Cut : Natural := 0;
      begin
         if Width (S) <= Room then
            return True;
         end if;
         for I in S'Range loop
            if S (I) = ' ' and then Width (S (S'First .. I - 1)) <= Room then
               Cut := I;
            end if;
         end loop;
         return Cut > 0 and then Width (S (Cut + 1 .. S'Last)) <= Room;
      end Fits;

      type ID_List is array (Positive range <>) of TX.Text_ID;

      --  Tables 33 to 37: 153 x 50 buttons, 3 cells of margin a side
      Menu_Labels : constant ID_List :=
        (TX.Start, TX.Driver_ID, TX.Train_Data, TX.Level,
         TX.Train_Running_Number, TX.Shunting, TX.Exit_Shunting,
         TX.Non_Leading, TX.Maintain_Shunting, TX.Radio_Data,
         TX.Initiate_SM, TX.Continue_SM, TX.Exit_SM, TX.EOA, TX.Adhesion,
         TX.SR_Speed_Distance, TX.Train_Integrity, TX.BMM_Inhibition,
         TX.Revoke_BMM_Inhibition, TX.System_Version, TX.Set_VBC,
         TX.Remove_VBC, TX.ATO, TX.Contact_Last_RBC, TX.Use_Short_Number,
         TX.Enter_RBC_Data, TX.Radio_Network_Type, TX.GSMR_Network_ID,
         TX.Mission_One_Radio);
      --  10.3.5.19: 102 x 50 keys
      Key_Labels : constant ID_List :=
        (TX.Yes, TX.No, TX.More, TX.Level_0, TX.Level_1, TX.Level_2,
         TX.Non_Slippery_Rail, TX.Slippery_Rail, TX.Stand_By, TX.ATO_On,
         TX.Out_Of_GC);
      Train_Data_Values : constant ID_List :=
        (TX.Yes, TX.No, TX.Out_Of_GC);
      --  8.6.1: the 60 x 50 buttons F1 to F4, each line on its own
      F_Lines : constant ID_List :=
        (TX.F_Main, TX.F_Override_1, TX.F_Override_2, TX.F_Data_View_1,
         TX.F_Data_View_2, TX.F_Special);
      --  10.3.1.10 / 10.3.3.7 / 10.5.1.7: right aligned 10 (label area)
      --  or 5 (echo, data view) cells left of X 204, inside the window
      Labels : constant ID_List :=
        (TX.Driver_ID, TX.Train_Running_Number, TX.Train_Running_Nr,
         TX.RBC_ID, TX.RBC_Phone_Number, TX.SR_Speed, TX.SR_Distance,
         TX.VBC_Code, TX.Train_Category, TX.Train_Length,
         TX.Brake_Percentage, TX.Max_Speed, TX.Axle_Load_Category,
         TX.Airtight, TX.Loading_Gauge, TX.Maximum_Speed,
         TX.Radio_Network_Type, TX.GSMR_Network_ID,
         TX.Operated_System_Version, TX.Validate);

      --  every character has a glyph in the font it is drawn with, so
      --  that no text shows a replacement box (the Hungarian o and u
      --  with double acute are Latin Extended-A)
      function Has_Glyphs (S : Wide_String; Map : Font.Glyph_Map)
        return Boolean is
        (for all C of S =>
           C in Map'Range and then Font.Defined (Map (C)));

      --  15.1.1.3 / 8.2.3.4: a system status message breaks at its
      --  spaces only when every word fits a line of the text message
      --  area, measured in the bold font they are drawn with (first
      --  group, 8.2.3.4.7 c)
      function Words_Fit (S : Wide_String) return Boolean is
         First : Positive := S'First;
      begin
         for I in S'Range loop
            if S (I) = ' ' or else I = S'Last then
               if Display.Draw.String_Width
                    (S (First .. (if S (I) = ' ' then I - 1 else I)), 12,
                     Bold => True)
                    > DMI_Text_Messages.Line_Width
               then
                  return False;
               end if;
               First := I + 1;
            end if;
         end loop;
         return True;
      end Words_Fit;
   begin
      for L in TX.Language_T loop
         declare
            Name : constant String := TX.Language_T'Image (L);
         begin
            for T in TX.Text_ID loop
               --  the window titles: 30 characters in the window
               --  definitions (DMI_Data_Entry.Max_Label), 3 cells of
               --  indent in the 306 cells of the D/F/G column
               if T <= TX.Language then
                  Check (TX.Text (T, L)'Length
                           <= DMI_Data_Entry.Max_Label
                         and then Width (TX.Text (T, L)) <= 300,
                         "lang: " & Name & " title "
                         & TX.Text_ID'Image (T) & " fits");
               end if;
            end loop;
            for T of Menu_Labels loop
               Check (Fits (TX.Text (T, L), 147),
                      "lang: " & Name & " button " & TX.Text_ID'Image (T)
                      & " fits its 153 cells");
            end loop;
            for T of Key_Labels loop
               Check (Fits (TX.Text (T, L), 96)
                      and then TX.Text (T, L)'Length
                                 <= DMI_Data_Entry.Max_Choice_Label,
                      "lang: " & Name & " key " & TX.Text_ID'Image (T)
                      & " fits its 102 cells");
            end loop;
            --  Table 23: the data part of an input field with a label
            --  is 102 cells, the value indented by 10 (10.3.1.11): the
            --  choices of the train data keyboards that are texts
            for T of Train_Data_Values loop
               Check (Width (TX.Text (T, L)) <= 92,
                      "lang: " & Name & " value " & TX.Text_ID'Image (T)
                      & " fits the data part of its input field");
            end loop;
            for T of F_Lines loop
               Check (Width (TX.Text (T, L)) <= 56,
                      "lang: " & Name & " " & TX.Text_ID'Image (T)
                      & " fits its 60 cells");
            end loop;
            for T of Labels loop
               Check (Width (TX.Text (T, L)) <= 194
                      and then TX.Text (T, L)'Length
                                 <= DMI_Data_Entry.Max_Label,
                      "lang: " & Name & " label " & TX.Text_ID'Image (T)
                      & " fits left of X 204");
            end loop;
            for L2 in TX.Language_T loop
               Check (Fits (TX.Name (L2), 96),
                      "lang: the key of " & TX.Language_T'Image (L2));
            end loop;
            --  10.3.5.7: the question on the 334 cells of A/B/C/E
            Check (Width (TX.Text (TX.Entry_Complete_Before, L)
                          & TX.Text (TX.SR_Speed_Distance, L)
                          & TX.Text (TX.Entry_Complete_After, L)) <= 330,
                   "lang: " & Name & " the longest question fits");
            --  11.3.3.7 a: the 'TRN' button of the Driver ID window,
            --  82 cells, label size 10 (5.1.2.2.3 g); 'Yes' on the 82
            --  cells of the TAF answer (8.2.3.3) and of 10.3.5.10
            Check (Display.Draw.String_Width (TX.Text (TX.TRN_Button, L),
                                              10) <= 78
                   and then Width (TX.Text (TX.Yes, L)) <= 78,
                   "lang: " & Name & " 'TRN' and 'Yes' fit 82 cells");
            --  Table 45 item 15: 'VBC #n set code' with two digits
            Check (Width (TX.Text (TX.VBC_Code_Before, L) & "63"
                          & TX.Text (TX.VBC_Code_After, L)) <= 194,
                   "lang: " & Name & " 'VBC #63 set code' fits left of X 204");
            for T in TX.Balise_Read_Error .. TX.Text_ID'Last loop
               Check (Words_Fit (TX.Text (T, L)),
                      "lang: " & Name & " message " & TX.Text_ID'Image (T)
                      & " breaks at its spaces");
            end loop;
            for T in TX.Text_ID loop
               Check (Has_Glyphs (TX.Text (T, L), Font.FreeSans_12.Glyphs)
                      and then (T /= TX.TRN_Button
                                or else Has_Glyphs (TX.Text (T, L),
                                                    Font.FreeSans_10.Glyphs)),
                      "lang: " & Name & " " & TX.Text_ID'Image (T)
                      & " has a glyph for every character");
            end loop;
            Check (Has_Glyphs (TX.Name (L), Font.FreeSans_12.Glyphs),
                   "lang: the name of " & Name & " has its glyphs");
         end;
      end loop;
      Check (Lang_Is (TX.English) and then TX."=" (TX.Default_Language,
                                                   TX.English),
             "5.5: English is the default language");
   end Scenario_Lang_Texts_Fit;

   -- 11.3.6, Table 36 #1, Table 48, Table 54 S2, MSG_DRIVER_DATA kind 10
   procedure Scenario_Lang_Window is
   begin
      Lang_English;
      Lang_Standstill;
      Press (610, 240);                          -- F5: Settings
      Check (Win_Top_Is (DMI_Windows.W_Settings) and then Win_Enabled (1),
             "Table 36 #1: Language in SB at standstill");
      VBC_Onboard (National => 0, Train => Win_Running);
      Check (not Win_Enabled (1), "Table 36 #1: not in SB while running");
      Send_Mode_Level (Mode => 2, Level => 4);  -- FS
      VBC_Onboard (National => 0, Train => Win_Running);
      Check (Win_Enabled (1), "Table 36 #1: in FS, also while running");
      Send_Mode_Level (Mode => 1, Level => 4);
      VBC_Onboard (National => 0);

      -- Table 54 S1 -> S2: the language window, the selected language
      -- proposed (11.7.1.4)
      Win_Menu (1);
      Check (Win_Top_Is (DMI_Windows.W_Language)
             and then Win_Value = "English",
             "Table 54 S2: the Language window proposes English");
      Check (DMI_Windows.Close_Enabled, "11.7.7.2: [Close] enabled");
      Step;
      Check_Frame ("lang_window");                -- Figure 119
      Key (1);                                    -- Deutsch
      Check (Win_Value = "Deutsch" and then Lang_Is (TX.English),
             "the key enters the language, nothing selected yet");
      Step;
      Check_Frame ("lang_window_deutsch");
      Expect_No_Driver_Data (10, "nothing sent before the entry");
      Enter_Single;
      Check (Lang_Is (TX.German), "5.5: German is selected");
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S2 -> S1, the Settings window");
      Expect_Driver_Data (10, Lang_Bytes ("de"),
                          "kind 10 with the code of the language");
      Step;
      Check_Frame ("lang_settings_de");

      -- the window in German, German proposed; revalidation sends again
      Win_Menu (1);
      Check (Win_Top_Is (DMI_Windows.W_Language)
             and then Win_Value = "Deutsch",
             "11.7.1.4: the selected language is proposed");
      Step;
      Check_Frame ("lang_window_de");
      Enter_Single;
      Check (Lang_Is (TX.German), "revalidated: German stays");
      Expect_Driver_Data (10, Lang_Bytes ("de"),
                          "Table 54 S2: the revalidation is an entry too");

      -- [Close]: nothing changes, nothing is sent
      Win_Menu (1);
      Key (2);
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Settings) and then Lang_Is (TX.German),
             "[Close] of the Language window changes nothing");
      Expect_No_Driver_Data (10, "[Close] sends nothing");

      -- Table 48: the window gives way when 'Language' loses its
      -- conditions (11.7.1.7)
      Win_Menu (1);
      Key (2);
      VBC_Onboard (National => 0, Train => Win_Running);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings) and then Lang_Is (TX.German),
             "Table 48: Language -> the Settings window when running in SB");
      VBC_Onboard (National => 0);

      -- 11.7.1.9: a driver's acknowledgement stops the entry
      Win_Menu (1);
      Key (2);
      Send_Text (92, "Ack me", Ack_Required => True);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings) and then Lang_Is (TX.German),
             "11.7.1.9: the acknowledgement stops the Language window");
      Send_Text_Remove (92);
      for I in 1 .. 30 loop
         Step;
      end loop;
      Drain_Sounds;
      Drain_Outbox;

      -- back to English: kind 10 "en", the windows in English at once
      Win_Menu (1);
      Key (2);
      Enter_Single;
      Check (Lang_Is (TX.English), "English again");
      Expect_Driver_Data (10, Lang_Bytes ("en"), "kind 10 'en'");
      Step;
      Check_Frame ("lang_settings_en_again");
      Lang_English;
   end Scenario_Lang_Window;

   -- 5.5.1.3: the texts of the windows, the buttons, the keys, the input
   -- fields, the echo texts and the data view in German
   procedure Scenario_Lang_German_Windows is
   begin
      Lang_English;
      Lang_Standstill;
      Lang_Select (1);
      Check (Lang_Is (TX.German), "lang: German selected");
      Win_Default;
      Step;
      Check_Frame ("lang_default_de");            -- F1 .. F4

      -- the menu windows, Tables 33 to 35 and 37
      Press (610, 40);                            -- F1: Main
      Step;
      Check_Frame ("lang_main_de");
      Win_Default;
      Press (610, 190);                           -- F4: Special
      Step;
      Check_Frame ("lang_special_de");
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit,
                   Train => Win_Standing or 16#10#);  -- BMM inhibited
      Step;
      Check_Frame ("lang_special_bmm_de");
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit);
      Win_Default;
      DMI_Windows.Open (DMI_Windows.W_Main);
      DMI_Windows.Open (DMI_Windows.W_Radio_Data);
      Step;
      Check_Frame ("lang_radio_data_de");
      Win_Default;

      -- the dedicated keyboards: Table 43 on two lines, Table 43a
      Press (610, 190);                           -- F4: Special
      Win_Menu (1);                               -- Adhesion
      Check (Win_Top_Is (DMI_Windows.W_Adhesion)
             and then Win_Value = "Nicht rutschig",
             "lang: the proposed adhesion in German");
      Step;
      Check_Frame ("lang_adhesion_de");
      Key (2);
      Enter_Single;
      Expect_Actions (9, 1, "lang: the adhesion goes to the EVC as before");
      Win_Default;

      -- the train data windows: labels, echo texts, question, [More],
      -- 'Ja' / 'Nein', 'Außerhalb GC' and the validation window
      Press (610, 40);                            -- F1: Main
      Win_Menu (3);                               -- Train data
      Check (Win_Top_Is (DMI_Windows.W_Train_Data),
             "lang: the train data window");
      Step;
      Check_Frame ("lang_train_data_1_de");
      Enter_Train_Data (Length => 450, Brake => 120, Speed => 160);
      Press_Next;
      Enter_Field (2);                            -- select the airtight
      Key (8);                                    -- airtight: Ja
      Step;
      Check_Frame ("lang_train_data_2_de");
      Enter_Field (2);
      Press (167, 440);                           -- entry complete? Ja
      Check (Win_Top_Is (DMI_Windows.W_Train_Data_Validation)
             and then Win_Value = "Ja",
             "lang: the validation window proposes 'Ja'");
      Step;
      Check_Frame ("lang_train_data_validation_de");
      Press (487, 40);                            -- accept 'Ja'
      Check (DMI_Driver_Data.Airtight = DMI_Data_Entry.Yes_Choice
             and then DMI_Train_Data.Airtight_Value = 1,
             "lang: 'Ja' is the choice 'Yes', M_AIRTIGHT fitted");
      Drain_Outbox;
      Win_Default;

      -- the data view (Table 45) and the System version window (Table 46)
      Send_System_Version (2, 1);
      Send_VBC_List ((71951, 321456));            -- 'VBC #n Setzcode'
      Press (610, 140);                           -- F3: Data view
      Check (DMI_Data_View.Title = "Datenansicht (1/2)",
             "lang: the data view title in German");
      Step;
      Check_Frame ("lang_data_view_de");
      Press_Next;
      Check_Frame ("lang_data_view_2_de");
      Win_Default;
      Press (610, 240);                           -- F5: Settings
      Win_Menu (4);                               -- System version
      Step;
      Check_Frame ("lang_system_version_de");
      Win_Close;
      Win_Menu (5);                               -- Set VBC: total grid
      Win_Type ("4711");
      Step;
      Check_Frame ("lang_set_vbc_de");
      Win_Default;

      -- 8.2.3.3: the Track Ahead Free question
      Send_Mode_Level (Mode => 2, Level => 5, TAF => True);
      Step;
      Check_Frame ("lang_taf_de");
      Send_Mode_Level (Mode => 1, Level => 4);
      Lang_English;
      Step;
      Check_Frame ("lang_default_en_again");
   end Scenario_Lang_German_Windows;

   -- 15.1.1.4.2 with 5.5.1.3: the system status messages follow the
   -- selected language, also the ones displayed; a plain text message
   -- of the trackside does not (5.5.1.3)
   procedure Scenario_Lang_Messages is
   begin
      Lang_English;
      SS_Reset (Mode => 2);
      Send_Text (7, "Streckentext bleibt", First_Group => False,
                 HH => 9, MM => 30);
      Send_System_Status (SS.SS_Trackside_Malfunction, 0);
      Send_System_Status (SS.SS_Route_Unsuitable_Traction, 0);
      Step;
      Drain_Sounds;
      Check_Frame ("lang_messages_en");
      Send_Status (HH => 9, MM => 44, SS => 0);
      Lang_Select (1);
      Win_Default;
      Step;
      Drain_Sounds;
      Check (SS_Active (SS.SS_Trackside_Malfunction)
             and then SS_Active (SS.SS_Route_Unsuitable_Traction),
             "lang: the messages stay displayed");
      Check_Frame ("lang_messages_de");           -- 09:41 kept
      Expect_No_Sound ("lang: a new text is no new message (no Sinfo)");

      -- a message that starts now comes in German, and one to be
      -- acknowledged is offered in German
      Send_Mode_Level (Mode => 14, Level => 4);   -- NL
      Send_System_Status (SS.SS_NL_No_Longer_Permitted, 0);
      Step;
      Drain_Sounds;
      Check_Frame ("lang_nl_ack_de");
      Pointer_Down (150, 400);
      Pointer_Up (150, 400);
      Step;
      Drain_Sounds;
      Check (not SS_Active (SS.SS_NL_No_Longer_Permitted),
             "lang: the German message is acknowledged as before");
      Lang_English;
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Lang_Messages;

   -- 5.5 with 5.2.2.2 / 5.2.3.2: the selection is a setting of the DMI
   -- unit and survives a reset and a loss of the EVC link; Table 54 S2
   -- from the Start Up (S1-1): the Driver ID window below comes back in
   -- the new language
   procedure Scenario_Lang_Reset is
   begin
      Lang_English;
      Lang_Standstill;
      Lang_Select (1);
      Win_Default;
      Reset;
      Check (Lang_Is (TX.German), "lang: the selection survives a reset");
      Send_Mode_Level (Mode => 1, Level => 4);
      Win_At_Standstill;
      VBC_Onboard (National => 0);
      Press (610, 240);
      Win_Menu (1);
      Check (Win_Value = "Deutsch",
             "11.7.1.4: after the reset the stored language is proposed");
      Step;
      Check_Frame ("lang_after_reset");
      Win_Default;

      -- the link lost and back: still German
      External_EVC;
      General_Parameters.EVC_Link_Timeout_Ms := 1000;
      Send_Mode_Level (Mode => 1, Level => 4);
      for I in 1 .. 21 loop
         Step;
      end loop;
      Check (DMI_Core.EVC_Link_Lost and then Lang_Is (TX.German),
             "lang: the link loss keeps the selection");
      Send_Mode_Level (Mode => 1, Level => 4);
      External_EVC (False);
      General_Parameters.EVC_Link_Timeout_Ms := 0;

      -- Table 49 S1 -> S1-1 (Settings) -> Table 54 S2: English
      Reset;
      Win_At_Standstill;
      Win_Onboard (Data => 0, SOM => 0);
      Send_Mode_Level (Mode => 1, Level => 0);
      Win_Onboard (Data => 0, SOM => 2);
      Check (Win_Top_Is (DMI_Windows.W_Driver_ID)
             and then DMI_Windows.In_Start_Up,
             "lang: Table 49 S1, the Driver ID window");
      Step;
      Check_Frame ("lang_start_up_driver_id_de");  -- 'Zugnr.'
      Press (599, 440);                           -- settings, S1-1
      Win_Menu (1);
      Key (2);
      Enter_Single;
      Check (Lang_Is (TX.English)
             and then Win_Top_Is (DMI_Windows.W_Settings),
             "lang: English selected from S1-1, back to Settings");
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Driver_ID),
             "lang: [Close] -> S1, the Driver ID window");
      Step;
      Check_Frame ("lang_start_up_driver_id_en");
      Lang_English;
      Reset;
   end Scenario_Lang_Reset;

   -- 11.7.7, Table 54: the steps of the Settings window dialogue
   -- sequence, S2 with the others (S6 and S7 are Scenario_VBC_Settings)
   procedure Scenario_Lang_Settings_Sequence is
      procedure Back_To_S1 (What : String) is
      begin
         Check (DMI_Windows.Close_Enabled,
                "11.7.7.2: [Close] enabled in " & What);
         Win_Close;
         Check (Win_Top_Is (DMI_Windows.W_Settings),
                "Table 54: " & What & " -> S1 by [Close]");
      end Back_To_S1;
   begin
      Lang_English;
      Lang_Standstill;
      Send_ATO (Selector => 1);
      Win_Default;
      Press (610, 240);                           -- S0 -> S1
      Check (Win_Top_Is (DMI_Windows.W_Settings), "Table 54 S0 -> S1");
      Check (DMI_Windows.Close_Enabled, "11.7.7.2: [Close] enabled in S1");
      Win_Menu (1);
      Check (Win_Top_Is (DMI_Windows.W_Language), "Table 54 S1 -> S2");
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S2 revalidated -> S1");
      Win_Menu (1);
      Back_To_S1 ("S2");
      Win_Menu (2);
      Check (Win_Top_Is (DMI_Windows.W_Volume), "Table 54 S1 -> S3");
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S3 revalidated -> S1");
      Win_Menu (2);
      Back_To_S1 ("S3");
      Win_Menu (3);
      Check (Win_Top_Is (DMI_Windows.W_Brightness), "Table 54 S1 -> S4");
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S4 revalidated -> S1");
      Win_Menu (3);
      Back_To_S1 ("S4");
      Win_Menu (4);
      Check (Win_Top_Is (DMI_Windows.W_System_Version),
             "Table 54 S1 -> S5");
      Back_To_S1 ("S5");
      Win_Menu (5);
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC), "Table 54 S1 -> S6-1");
      Back_To_S1 ("S6-1");
      Win_Menu (6);
      Check (Win_Top_Is (DMI_Windows.W_Remove_VBC), "Table 54 S1 -> S7-1");
      Back_To_S1 ("S7-1");
      Win_Menu (7);
      Check (Win_Top_Is (DMI_Windows.W_ATO_Selector)
             and then Win_Value = "Stand-by",
             "Table 54 S1 -> S8, the stored position proposed");
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S8 revalidated -> S1");
      Win_Menu (7);
      Back_To_S1 ("S8");
      Lang_English;
   end Scenario_Lang_Settings_Sequence;

   -- The simulator holds the language the DMI reports (kind 10)
   procedure Scenario_Lang_Simulator is
      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

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
               if The_Type = MSG_DRIVER_DATA then
                  EVC_Core.Handle_Driver_Data (Buffer (Offset .. Next - 1));
               end if;
               Offset := Next;
            end;
         end loop;
      end Pump_To_EVC;

      procedure Touch (X, Y : Natural) is
      begin
         Pointer_Down (X, Y);
         Pointer_Up (X, Y);
         DMI_Core.Tick (50);
         Pump_To_EVC;
         EVC_Core.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
         Pump_To_EVC;
         Drain_Sounds;
      end Touch;
   begin
      Lang_English;
      Reset;
      EVC_Core.Reset;
      External_EVC;
      for I in 1 .. 3 loop
         EVC_Core.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
         Pump_To_EVC;
      end loop;
      Check (EVC_Core.Language_Code = "en", "sim: English at the start");
      Touch (385, 240); Touch (487, 90);       -- Driver ID 1
      Touch (Key_X (1), Key_Y (1)); Touch (487, 90);  -- level 1
      Touch (370, 440);                        -- [Close] the Main window
      Touch (610, 240);                        -- F5: Settings
      Touch (Win_Slot_X (1), Win_Slot_Y (1));  -- Language
      Touch (Key_X (1), Key_Y (1)); Touch (487, 90);  -- Deutsch
      Check (EVC_Core.Language_Code = "de",
             "sim: the on-board stores the language the driver selected");
      -- malformed kind 10: ignored
      EVC_Core.Handle_Driver_Data ((10, 16#45#, 16#4E#));
      EVC_Core.Handle_Driver_Data ((10, 16#65#));
      Check (EVC_Core.Language_Code = "de", "sim: malformed kind 10 ignored");
      Touch (Win_Slot_X (1), Win_Slot_Y (1));
      Touch (Key_X (2), Key_Y (2)); Touch (487, 90);  -- English
      Check (EVC_Core.Language_Code = "en", "sim: English again");
      External_EVC (False);
      Lang_English;
      Reset;
   end Scenario_Lang_Simulator;


   ---------------------------------------------------------------------
   -- Hungarian, the third language (DMI 5.5.1.1, 11.3.6.4): the wording
   -- of the MAV ETCS operating instructions, Latin Extended-A glyphs
   ---------------------------------------------------------------------

   -- 11.3.6.4 / Figure 119: three keys, Magyar the third (the order of
   -- the names); Table 54 S2 with kind 10 "hu"
   procedure Scenario_Hu_Language_Window is
   begin
      Lang_English;
      Lang_Standstill;
      Press (610, 240);                          -- F5: Settings
      Win_Menu (1);                              -- Language
      Check (Win_Top_Is (DMI_Windows.W_Language)
             and then Win_Value = "English",
             "hu: the Language window proposes English");
      Key (3);
      Check (Win_Value = "Magyar" and then Lang_Is (TX.English),
             "hu: the third key enters 'Magyar', nothing selected yet");
      Step;
      Check_Frame ("hu_lang_window_magyar");
      Expect_No_Driver_Data (10, "hu: nothing sent before the entry");
      Enter_Single;
      Check (Lang_Is (TX.Hungarian)
             and then Win_Top_Is (DMI_Windows.W_Settings),
             "hu: Hungarian selected, back to the Settings window");
      Check (TX.Code (TX.Hungarian) = "hu"
             and then TX.Name (TX.Hungarian) = "Magyar",
             "hu: ISO 639-1 'hu', named 'Magyar'");
      Expect_Driver_Data (10, Lang_Bytes ("hu"), "hu: kind 10 'hu'");
      Step;
      Check_Frame ("hu_settings");               -- Hangero, Fenyero
      Win_Menu (1);
      Check (Win_Top_Is (DMI_Windows.W_Language)
             and then Win_Value = "Magyar",
             "hu: 11.7.1.4, Magyar proposed");
      Step;
      Check_Frame ("hu_lang_window");            -- title 'Nyelv'
      Win_Close;

      -- the simulator stores the code as it comes
      EVC_Core.Handle_Driver_Data ((10, Character'Pos ('h'),
                                    Character'Pos ('u')));
      Check (EVC_Core.Language_Code = "hu",
             "hu: sim, the on-board stores 'hu'");
      EVC_Core.Handle_Driver_Data ((10, Character'Pos ('e'),
                                    Character'Pos ('n')));
      Lang_English;
   end Scenario_Hu_Language_Window;

   -- 5.5.1.3: the default window, the menus, the keyboards, the data
   -- entry windows with their echo texts, the data view and the System
   -- version window in Hungarian
   procedure Scenario_Hu_Windows is
   begin
      Lang_English;
      Lang_Standstill;
      Lang_Select (3);
      Check (Lang_Is (TX.Hungarian), "hu: Hungarian selected");
      Win_Default;
      Step;
      Check_Frame ("hu_default");                -- F1 .. F4

      -- the menu windows, Tables 33 to 35
      Press (610, 40);                           -- F1: Fomenu
      Step;
      Check_Frame ("hu_main");
      Win_Menu (5);                              -- Szint
      Check (Win_Top_Is (DMI_Windows.W_Level), "hu: the Level window");
      Step;
      Check_Frame ("hu_level");                  -- 'ETCS 1 szint'
      Win_Default;
      Press (610, 90);                           -- F2: Meghaladas
      Step;
      Check_Frame ("hu_override");               -- 'Menetengedely vege'
      Win_Default;
      Press (610, 190);                          -- F4: Kulonleges
      Step;
      Check_Frame ("hu_special");
      Win_Menu (1);                              -- Tapadas
      Check (Win_Top_Is (DMI_Windows.W_Adhesion)
             and then Win_Value = "Nem cs["FA"]sz["F3"]s s["ED"]n",
             "hu: the proposed adhesion in Hungarian");
      Win_Default;

      -- the train data windows: labels, echo texts, the question,
      -- 'Igen' / 'Nem' and the validation window
      Press (610, 40);                           -- F1
      Win_Menu (3);                              -- Vonatadatok
      Check (Win_Top_Is (DMI_Windows.W_Train_Data),
             "hu: the train data window");
      Step;
      Check_Frame ("hu_train_data_1");
      Enter_Train_Data (Length => 450, Brake => 120, Speed => 160);
      Press_Next;
      Enter_Field (2);                           -- select the airtight
      Key (8);                                   -- airtight: Igen
      Step;
      Check_Frame ("hu_train_data_2");
      Enter_Field (2);
      Press (167, 440);                          -- entry complete? Igen
      Check (Win_Top_Is (DMI_Windows.W_Train_Data_Validation)
             and then Win_Value = "Igen",
             "hu: the validation window proposes 'Igen'");
      Step;
      Check_Frame ("hu_train_data_validation");
      Press (487, 40);                           -- accept 'Igen'
      Check (DMI_Driver_Data.Airtight = DMI_Data_Entry.Yes_Choice,
             "hu: 'Igen' is the choice 'Yes'");
      Drain_Outbox;
      Win_Default;

      -- the data view (Table 45) and the System version window
      -- (Table 46): 'Mukodo rendszerverzio' holds u and o with
      -- double acute
      Send_System_Version (2, 1);
      Send_VBC_List ((71951, 321456));
      Press (610, 140);                          -- F3: Adatnezet
      Check (DMI_Data_View.Title = "Adatn["E9"]zet (1/2)",
             "hu: the data view title in Hungarian");
      Step;
      Check_Frame ("hu_data_view");
      Press_Next;
      Check_Frame ("hu_data_view_2");
      Win_Default;
      Press (610, 240);                          -- F5: Beallitasok
      Win_Menu (4);                              -- Rendszerverzio
      Check (TX.Text (TX.Operated_System_Version)
               = "M["0171"]k["F6"]d["0151"] rendszerverzi["F3"]",
             "hu: the text with u and o with double acute");
      Step;
      Check_Frame ("hu_system_version");
      Win_Default;

      -- 8.2.3.3: the Track Ahead Free question, 'Igen'
      Send_Mode_Level (Mode => 2, Level => 5, TAF => True);
      Step;
      Check_Frame ("hu_taf");
      Send_Mode_Level (Mode => 1, Level => 4);
      Lang_English;
      Step;
      Check_Frame ("lang_default_en_again");     -- English unchanged
   end Scenario_Hu_Windows;

   -- 15.1.1.4.2: two catalogue messages and the acknowledgeable 'NL no
   -- longer permitted' in Hungarian, the trackside text as it came
   procedure Scenario_Hu_Messages is
   begin
      Lang_English;
      SS_Reset (Mode => 2);
      Lang_Select (3);
      Win_Default;
      Send_Text (7, "P["E1"]lyasz["F6"]veg marad", First_Group => False,
                 HH => 9, MM => 30);
      Send_System_Status (SS.SS_Trackside_Malfunction, 0);
      Send_System_Status (SS.SS_Route_Unsuitable_Traction, 0);
      Step;
      Drain_Sounds;
      Check (SS_Active (SS.SS_Trackside_Malfunction)
             and then SS_Active (SS.SS_Route_Unsuitable_Traction),
             "hu: the two messages displayed");
      Check_Frame ("hu_messages");
      Send_Mode_Level (Mode => 14, Level => 4);  -- NL
      Send_System_Status (SS.SS_NL_No_Longer_Permitted, 0);
      Step;
      Drain_Sounds;
      Check_Frame ("hu_nl_ack");                 -- 'NL mar nem megengedett'
      Pointer_Down (150, 400);
      Pointer_Up (150, 400);
      Step;
      Drain_Sounds;
      Check (not SS_Active (SS.SS_NL_No_Longer_Permitted),
             "hu: the Hungarian message is acknowledged as before");
      Lang_English;
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Hu_Messages;

   -- 5.5 with 5.2.2.2: the selection survives a reset; the Start Up
   -- Driver ID window comes in Hungarian ('Vonatszam' on the TRN button)
   procedure Scenario_Hu_Reset is
   begin
      Lang_English;
      Lang_Standstill;
      Lang_Select (3);
      Win_Default;
      Reset;
      Check (Lang_Is (TX.Hungarian), "hu: the selection survives a reset");
      Send_Mode_Level (Mode => 1, Level => 4);
      Win_At_Standstill;
      VBC_Onboard (National => 0);
      Press (610, 240);
      Win_Menu (1);
      Check (Win_Value = "Magyar",
             "hu: after the reset Magyar is proposed");
      Win_Default;
      Reset;
      Win_At_Standstill;
      Win_Onboard (Data => 0, SOM => 0);
      Send_Mode_Level (Mode => 1, Level => 0);
      Win_Onboard (Data => 0, SOM => 2);
      Check (Win_Top_Is (DMI_Windows.W_Driver_ID)
             and then DMI_Windows.In_Start_Up
             and then Lang_Is (TX.Hungarian),
             "hu: Table 49 S1, the Driver ID window, still Hungarian");
      Step;
      Check_Frame ("hu_start_up_driver_id");
      Press (599, 440);                          -- settings, S1-1
      Win_Menu (1);
      Key (2);                                   -- English
      Enter_Single;
      Check (Lang_Is (TX.English), "hu: English again from S1-1");
      Lang_English;
      Reset;
   end Scenario_Hu_Reset;

   -- The same Hungarian texts from the WebAssembly build: the frame
   -- test/wasm/smoke.js renders after the same touches (the wire cycle
   -- of Scenario_Mission) must be this golden, so that the brackets
   -- notation of the Latin Extended-A letters reaches the wasm fonts
   procedure Scenario_Hu_Wasm_Start_Up is
      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

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
                  EVC_Core.Handle_Driver_Data (Buffer (Offset .. Next - 1));
               end if;
               Offset := Next;
            end;
         end loop;
      end Pump_To_EVC;

      -- test/wasm/smoke.js press()
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
   begin
      Lang_English;
      Reset;
      EVC_Core.Reset;
      External_EVC;
      for I in 1 .. 5 loop
         EVC_Driver.Auto_Drive;
         EVC_Core.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
      end loop;
      Touch (599, 440);                          -- Table 49 S1-1: Settings
      Touch (Win_Slot_X (1), Win_Slot_Y (1));    -- Language
      Touch (Key_X (3), Key_Y (3));              -- Magyar
      Touch (487, 90);                           -- accepted
      Touch (370, 440);                          -- [Close]: S1
      Check (Lang_Is (TX.Hungarian)
             and then Win_Top_Is (DMI_Windows.W_Driver_ID)
             and then EVC_Core.Language_Code = "hu",
             "hu: selected from the Start Up, the EVC told 'hu'");
      DMI_Core.Render;
      Check_Frame ("hu_wasm_driver_id");
      Touch (599, 440);
      Touch (Win_Slot_X (1), Win_Slot_Y (1));
      Touch (Key_X (2), Key_Y (2));              -- English
      Touch (487, 90);
      Touch (370, 440);
      Check (Lang_Is (TX.English) and then EVC_Core.Language_Code = "en",
             "hu: English again");
      External_EVC (False);
      Lang_English;
      Reset;
   end Scenario_Hu_Wasm_Start_Up;

   --  SUP-8, 8.2.2.5.3: the TTI arrives in tenths of a second and the
   --  white square takes n x 5 cells for
   --    TdispTTI * (10 - n) / 10 <= TTI < TdispTTI * (10 - (n - 1)) / 10.
   --  With TdispTTI = 14 s every step is 1.4 s long: its lower bound
   --  14 * (10 - n) tenths and its upper bound 14 * (11 - n) - 1 tenths
   --  give the same square, the tenth after it the next one.
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
   Scenario_Alphanumeric_Entry;
   Scenario_Dedicated_Keyboards;
   Scenario_Train_Data_Windows;
   Scenario_SS_Catalogue;
   Scenario_SS_Timers;
   Scenario_SS_Main_Window;
   Scenario_SS_Mode_Change;
   Scenario_SS_NL_Acknowledged;
   Scenario_ATO_Displays;
   Scenario_ATO_Malformed;
   Scenario_ATO_Buttons;
   Scenario_ATO_Warning_Sound;
   Scenario_ATO_Stopping_Points;
   Scenario_ATO_Selector_Window;
   Scenario_ATO_Mission;
   Scenario_Win_Main_Menu;
   Scenario_Win_Special_Settings;
   Scenario_Win_Radio_Data;
   Scenario_Win_Start_Up_Radio;
   Scenario_Win_Simulator;
   Scenario_HW_Settings_Stored;
   Scenario_HW_Desk_Settings;
   Scenario_HW_Isolation;
   Scenario_HW_Simulator_Isolation;
   Scenario_VBC_Settings;
   Scenario_VBC_System_Version;
   Scenario_VBC_Level_Name;
   Scenario_VBC_Data_View;
   Scenario_VBC_Simulator;
   Scenario_Lang_Texts_Fit;
   Scenario_Lang_Window;
   Scenario_Lang_German_Windows;
   Scenario_Lang_Messages;
   Scenario_Lang_Reset;
   Scenario_Lang_Settings_Sequence;
   Scenario_Lang_Simulator;
   Scenario_Hu_Language_Window;
   Scenario_Hu_Windows;
   Scenario_Hu_Messages;
   Scenario_Hu_Reset;
   Scenario_Hu_Wasm_Start_Up;
   Scenario_PT_TTI_Steps;

   Status := Summary;
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Exit_Status (Status));
end DMI_Test;
