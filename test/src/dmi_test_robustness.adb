--  ETCS DMI
--  Body of DMI_Test_Robustness (see dmi_test_robustness.ads).

with Ada.Streams;
with DMI_Core;
with DMI_Planning;
with DMI_Protocol;
with DMI_Sounds;
with DMI_Test_Support;
with Display.A_Area;
with Display.B_Area;
with Display.Screen;
with Display.Screen.Files;
with EVC_Driver;
with EVC_Mock;
with EVC_Track;
with EVC_Train;
with General_Parameters;
with Interfaces;
with Supplementary_Driving_Info;
with Test_Support;
with User_Settings;
use Test_Support;
use DMI_Test_Support;

package body DMI_Test_Robustness is

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
      use type EVC_Mock.Mode_T;

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
                     EVC_Mock.Handle_Driver_Action
                       (Natural (Action), Natural (Arg));
                  end;
               elsif The_Type = MSG_DRIVER_DATA then
                  -- the driver's data reach the EVC, which stores them
                  -- and reports their status back (MSG_ONBOARD)
                  EVC_Mock.Handle_Driver_Data
                    (Buffer (Offset .. Next - 1));
               end if;
               Offset := Next;
            end;
         end loop;
      end Pump_To_EVC;

      procedure Sim_Step is
      begin
         EVC_Driver.Auto_Drive;
         EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
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
         EVC_Mock.Step (0.05, Emit'Unrestricted_Access);
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

      function In_TSM return Boolean is (EVC_Mock.Monitoring = 1);
      function In_RSM return Boolean is (EVC_Mock.Monitoring = 2);
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
      EVC_Mock.Reset;
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
      Check (EVC_Mock.Mode = EVC_Mock.SB, "no mission start without Start");
      Touch (410, 90);                      -- Start -> default window

      -- mission start (the EVC grants FS with a full MA)
      Pump_To_EVC;
      Check (EVC_Mock.Mode = EVC_Mock.FS, "Start reaches the EVC");
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

end DMI_Test_Robustness;
