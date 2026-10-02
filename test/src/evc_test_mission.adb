with EVC_Test_Support;  use EVC_Test_Support;
with Ada.Directories;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Streams;
with Ada.Text_IO;
with DMI_Core;
with DMI_Protocol;
with Display.Screen.Files;
with Display.Screen;
with EVC_Braking;
with EVC_Build_Up;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Distances;
with EVC_Driver;
with EVC_Fixed;
with EVC_Mock;
with EVC_Ports;
with EVC_SDM;
with EVC_Stored_Information;
with EVC_Supervision_Input;
with EVC_Train;
with General_Parameters;
with Interfaces;
with Test_Support;

package body EVC_Test_Mission is

   package SI renames EVC_Stored_Information;
   package SIn renames EVC_Supervision_Input;
   package SDM renames EVC_SDM;

   use type EVC_Distances.Cm_T;
   use type SIn.Brake_Position_T;
   use type SDM.Monitoring_T;
   use Ada.Text_IO;
   use Ada.Streams;
   use EVC_Ports;
   use Interfaces;

   procedure Scenario_SDM_Mission is
      use type General_Parameters.Color;

      subtype X_T is Natural range 0 .. 639;
      subtype Y_T is Natural range 0 .. 479;
      type Frame_T is array (X_T, Y_T) of General_Parameters.Color;
      type Point_T is
        (Mission_SB, Mission_TSM, Mission_After_LX, Mission_RSM,
         Mission_Stopped);
      function Name (P : Point_T) return String is
        (case P is
            when Mission_SB       => "mission_sb",
            when Mission_TSM      => "mission_tsm",
            when Mission_After_LX => "mission_after_lx",
            when Mission_RSM      => "mission_rsm",
            when Mission_Stopped  => "mission_stopped");
      type Frames_T is array (Point_T) of Frame_T;
      type Frames_Access is access Frames_T;
      Mock_Frames : constant Frames_Access := new Frames_T;

      --  what each side showed at the checkpoints
      type Shown_T is record
         V_Cur, V_Perm, V_Target, D_Target, Monitoring, Status : Natural;
      end record;
      Mock_Shown    : array (Point_T) of Shown_T;
      Onboard_Shown : array (Point_T) of Shown_T;

      Mission_Diffs : array (Point_T) of Natural := (others => 0);
      --  the pixels that differ outside the areas A and B (the distance
      --  to target and the speed dial)
      Outside_AB    : array (Point_T) of Natural := (others => 0);

      On_Board : Boolean := False;

      --  the odometer of the mission: 2 per mille of the distance run on
      --  each side (the mock models no odometer error; the confidence
      --  interval of the on-board grows from the group on)
      Travel : Integer_64 := 0;
      Base_Over, Base_Under : Integer_64 := 0;
      Supervised : Boolean := False;

      --  pass 2: where the on-board first entered TSM and RSM and
      --  commanded the service and the emergency brake; pass 1: where
      --  the mock entered TSM and RSM (m)
      Board_TSM, Board_RSM, Board_SB, Board_EB : Integer := -1;
      Mock_TSM, Mock_RSM : Integer := -1;

      procedure Note (Where : in out Integer; Now : Boolean) is
      begin
         if Now and then Where < 0 then
            Where := Integer (EVC_Train.Position_M);
         end if;
      end Note;
      --  the mock's MSG_SPEED_STATE of the last step
      Mock_Speed : Shown_T := (others => 0);

      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Stream_Element_Array)
      is
         use type DMI_Protocol.Msg_Type_T;
      begin
         if The_Type = DMI_Protocol.MSG_SPEED_STATE then
            declare
               function W (N : Stream_Element_Offset) return Natural is
                 (Natural (Payload (Payload'First + N))
                  + 256 * Natural (Payload (Payload'First + N + 1)));
            begin
               Mock_Speed :=
                 (V_Cur      => W (0),
                  V_Perm     => W (2),
                  V_Target   => W (4),
                  D_Target   => W (12),
                  Monitoring => Natural (Payload (Payload'First + 16)),
                  Status     => Natural (Payload (Payload'First + 19)));
            end;
            if On_Board then
               return;   -- the on-board's replaces it
            end if;
         end if;
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

      --  One cycle of the on-board with the mock's train: its antenna
      --  3 m behind the mock's front end (EVC_Position), its odometer
      --  sample; its MSG_SPEED_STATE goes to the DMI
      procedure Onboard_Cycle (Dt : Natural) is
         Antenna : constant Integer_64 :=
           Integer_64 (LF'Floor (LF (EVC_Train.Position_M) * 100.0))
           - Integer_64 (EVC_Core.Configuration.Antenna_To_Cab_A);
         Step_Cm : constant Integer_64 := Antenna - Train_Cm;
      begin
         Speed_Cms := Unsigned_16
           (LF'Floor (LF (EVC_Train.Speed_MS) * 100.0));
         Feed_X (Step_Cm);
         Travel := Travel + abs Step_Cm;
         Odo_Over := Base_Over + Travel * 2 / 1000;
         Odo_Under := Base_Under + Travel * 2 / 1000;
         Sample ((if Step_Cm > 0 then 1 elsif Step_Cm < 0 then -1 else 0));
         EVC_Core.Tick (Dt);
         Take;
         Supervised := EVC_Stored_Information.Current.Supervise;
         if On_Board and then Supervised then
            Note (Board_TSM, Res.Monitoring = SDM.TSM);
            Note (Board_RSM, Res.Monitoring = SDM.RSM);
            Note (Board_SB, Cmd.SB);
            Note (Board_EB, Cmd.EB);
         elsif not On_Board then
            Note (Mock_TSM, EVC_Mock.Monitoring = 1);
            Note (Mock_RSM, EVC_Mock.Monitoring = 2);
         end if;
         if On_Board then
            for I in 1 .. Rec_Count loop
               if Recs (I).Port = DMI and then Rec_Length (I) = 26
                 and then Out_Buf (Recs (I).First)
                            = EVC_DMI_Port.MSG_SPEED_STATE
               then
                  declare
                     Payload : Stream_Element_Array (1 .. 21);
                  begin
                     for K in Payload'Range loop
                        Payload (K) := Stream_Element
                          (Out_Buf (Recs (I).First + 4
                                    + Natural (K)));
                     end loop;
                     DMI_Core.Handle_Message
                       (DMI_Protocol.MSG_SPEED_STATE, Payload);
                  end;
               end if;
            end loop;
         end if;
      end Onboard_Cycle;

      --  The DMI's actions and data back to the mock, as dmi_test does
      procedure Pump_To_Mock is
         use DMI_Protocol;
         Buffer : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
         Last   : Stream_Element_Offset;
         Offset : Stream_Element_Offset := Buffer'First;
      begin
         DMI_Core.Take_Outbox (Buffer, Last);
         while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last
         loop
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
                     Action : constant Unsigned_8 := Get_U8 (Buffer, Offset);
                     Arg    : constant Unsigned_16 :=
                       Get_U16 (Buffer, Offset);
                  begin
                     EVC_Mock.Handle_Driver_Action
                       (Natural (Action), Natural (Arg));
                  end;
               elsif The_Type = MSG_DRIVER_DATA then
                  EVC_Mock.Handle_Driver_Data (Buffer (Offset .. Next - 1));
               end if;
               Offset := Next;
            end;
         end loop;
      end Pump_To_Mock;

      procedure Sim_Step is
      begin
         EVC_Driver.Auto_Drive;
         EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
         Onboard_Cycle (100);
         DMI_Core.Tick (100);
      end Sim_Step;

      procedure Touch (X, Y : Natural) is
      begin
         EVC_Driver.Auto_Drive;
         EVC_Mock.Step (0.05, Emit'Unrestricted_Access);
         Onboard_Cycle (50);
         Test_Support.Pointer_Down (X, Y);
         Test_Support.Pointer_Up (X, Y);
         DMI_Core.Tick (50);
         Pump_To_Mock;
         Test_Support.Drain_Sounds;
      end Touch;

      --  area by area, the pixels that differ from the mock's frame
      procedure Compare (Point : Point_T) is
         type Count_Array is array (Display.Main_ID_T) of Natural;
         Counts : Count_Array := (others => 0);
         Sub_Counts : array (Display.Sub_ID_T) of Natural :=
           (others => 0);
         Total  : Natural := 0;

         function Inside (A : Display.Area_T; X, Y : Natural)
           return Boolean
         is (X >= A.Position.X and then X < A.Position.X + A.Width
             and then Y >= A.Position.Y and then Y < A.Position.Y + A.Height);
      begin
         for X in X_T loop
            for Y in Y_T loop
               if Display.Screen.Get_Pixel (X, Y)
                    /= Mock_Frames (Point) (X, Y)
               then
                  Total := Total + 1;
                  for M in Display.Main_ID_T loop
                     if Inside (Display.Get_Area (M), X, Y) then
                        Counts (M) := Counts (M) + 1;
                        exit;
                     end if;
                  end loop;
                  for Sub in Display.Sub_ID_T loop
                     declare
                        Parent : constant Display.Main_ID_With_Sub_T :=
                          (case Sub is
                              when Display.A1 .. Display.A4 => Display.A,
                              when Display.B0 .. Display.B8 => Display.B,
                              when Display.C1 .. Display.C9 => Display.C,
                              when Display.D1 .. Display.D14 => Display.D,
                              when Display.E1 .. Display.E11 => Display.E,
                              when Display.F1 .. Display.F9 => Display.F,
                              when Display.G1 .. Display.G13 => Display.G);
                        R  : constant Display.Area_T :=
                          Display.Get_Sub_Area_With_Relative_Position (Sub);
                        PA : constant Display.Area_T :=
                          Display.Get_Area (Parent);
                        A  : constant Display.Area_T :=
                          (Position => (PA.Position.X + R.Position.X,
                                        PA.Position.Y + R.Position.Y),
                           Width    => R.Width,
                           Height   => R.Height);
                     begin
                        if Inside (A, X, Y) then
                           Sub_Counts (Sub) := Sub_Counts (Sub) + 1;
                           exit;
                        end if;
                     end;
                  end loop;
               end if;
            end loop;
         end loop;
         Put ("  mission " & Name (Point) & ": mock v_perm"
              & Img (Mock_Shown (Point).V_Perm) & " v_target"
              & Img (Mock_Shown (Point).V_Target) & " d_target"
              & Img (Mock_Shown (Point).D_Target) & " mon"
              & Img (Mock_Shown (Point).Monitoring) & " st"
              & Img (Mock_Shown (Point).Status) & " | on-board v_perm"
              & Img (Onboard_Shown (Point).V_Perm) & " v_target"
              & Img (Onboard_Shown (Point).V_Target) & " d_target"
              & Img (Onboard_Shown (Point).D_Target) & " mon"
              & Img (Onboard_Shown (Point).Monitoring) & " st"
              & Img (Onboard_Shown (Point).Status) & " (v"
              & Img (Onboard_Shown (Point).V_Cur) & ") | pixels"
              & Img (Total));
         for M in Display.Main_ID_T loop
            if Counts (M) > 0 then
               Put (" " & Display.Main_ID_T'Image (M) & Img (Counts (M)));
            end if;
         end loop;
         Put (" | sub-areas");
         for Sub in Display.Sub_ID_T loop
            if Sub_Counts (Sub) > 0 then
               Put (" " & Display.Sub_ID_T'Image (Sub)
                    & Img (Sub_Counts (Sub)));
            end if;
         end loop;
         New_Line;
         Mission_Diffs (Point) := Total;
         Outside_AB (Point) :=
           Total - Counts (Display.A) - Counts (Display.B);
      end Compare;

      procedure Checkpoint (Point : Point_T) is
      begin
         DMI_Core.Render;
         if On_Board then
            Onboard_Shown (Point) :=
              (V_Cur      => Speed_Frame.V_Cur,
               V_Perm     => Speed_Frame.V_Perm,
               V_Target   => Speed_Frame.V_Target,
               D_Target   => Speed_Frame.D_Target,
               Monitoring => Speed_Frame.Monitoring,
               Status     => Speed_Frame.Status);
            Compare (Point);
         else
            Mock_Shown (Point) := Mock_Speed;
            declare
               Golden : constant String :=
                 DMI_Golden_Dir & Name (Point) & ".sha256";
            begin
               Check (Ada.Directories.Exists (Golden)
                      and then Read_Line (Golden)
                               = Display.Screen.Files.Digest,
                      "mission: the mock draws " & Name (Point)
                      & " as recorded");
            end;
            for X in X_T loop
               for Y in Y_T loop
                  Mock_Frames (Point) (X, Y) :=
                    Display.Screen.Get_Pixel (X, Y);
               end loop;
            end loop;
         end if;
      end Checkpoint;

      function In_TSM return Boolean is (EVC_Mock.Monitoring = 1);
      function In_RSM return Boolean is (EVC_Mock.Monitoring = 2);
      function Stopped return Boolean is
        (EVC_Train.Speed_KMH = 0 and then EVC_Train.Position_M > 9_000.0);
      function Past_LX return Boolean is
        (EVC_Train.Position_M > 5_600.0);

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
         Check (False, "mission: timeout waiting for " & What);
      end Run_Until;

      procedure Wait_TSM is new Run_Until (In_TSM);
      procedure Wait_RSM is new Run_Until (In_RSM);
      procedure Wait_Stop is new Run_Until (Stopped);
      procedure Wait_LX is new Run_Until (Past_LX);

      Timeout : constant Natural := General_Parameters.EVC_Link_Timeout_Ms;
   begin
      for Pass in 1 .. 2 loop
         On_Board := Pass = 2;
         DMI_Core.Initialise;
         Test_Support.Reset_EVC_Model;
         General_Parameters.EVC_Link_Timeout_Ms := 0;
         Test_Support.Drain_Sounds;
         EVC_Mock.Reset;
         Test_Support.External_EVC;
         --  the on-board passes its balise group before the mission:
         --  moving in Stand By without an MA, the standstill supervision
         --  brakes it after D_NVROLL (4.4.7.1.5); at standstill the
         --  driver acknowledges (3.14.1.5), and the MA is supervised
         Start_X (Start_Cm => (Mission_Group_M - 13) * 100);
         Mission_Track;
         Bound_Per_Mille := 2;
         Run_X (-Integer_64 (EVC_Core.Configuration.Antenna_To_Cab_A), 100);
         Stand_X (500);
         Input (DMI, Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 5, 0, 0, 0)));
         Stand_X (200);
         Check (SI.Current.Supervise and then SI.Current.MA.Present
                and then not EVC_Core.Brake_Commands.EB
                and then EVC_Core.Supervision.Active
                and then SI.Current.National.Q_NVEMRRLS
                and then SI.Current.MRSP.Count = 4
                and then SI.Current.Gradients.Count = 6,
                "mission: before the start the group is read, the MA of 10 "
                & "km supervised, the brake of the standstill supervision "
                & "released");
         Travel := 0;
         Base_Over := Odo_Over;
         Base_Under := Odo_Under;
         Reset_Capture;

         for I in 1 .. 5 loop
            Sim_Step;
         end loop;
         Checkpoint (Mission_SB);

         --  the start of mission by touch, as dmi_test
         Touch (385, 240); Touch (487, 90);
         Touch (385, 240); Touch (487, 90);
         Touch (410, 140);
         Touch (385, 240); Touch (589, 40);
         Touch (385, 290); Touch (487, 390); Touch (487, 390);
         Touch (589, 90);
         Touch (385, 240); Touch (589, 240); Touch (487, 290);
         Touch (589, 140);
         Touch (385, 240); Touch (385, 290); Touch (487, 390);
         Touch (589, 190);
         Touch (539, 440);
         Touch (385, 240); Touch (589, 40);
         Touch (385, 340); Touch (589, 90);
         Touch (487, 290); Touch (589, 140);
         Touch (167, 440);
         Touch (487, 40);
         Touch (385, 240); Touch (487, 90);
         Touch (410, 90);
         Pump_To_Mock;
         Sim_Step;
         Test_Support.Drain_Sounds;

         Wait_TSM ("TSM entry", 2_000);
         Test_Support.Drain_Sounds;
         Checkpoint (Mission_TSM);
         Wait_LX ("passing the level crossing", 3_000);
         Test_Support.Drain_Sounds;
         Checkpoint (Mission_After_LX);
         Wait_RSM ("RSM entry", 8_000);
         Test_Support.Drain_Sounds;
         Checkpoint (Mission_RSM);
         Wait_Stop ("standstill at the EOA", 4_000);
         Test_Support.Drain_Sounds;
         Checkpoint (Mission_Stopped);
      end loop;
      General_Parameters.EVC_Link_Timeout_Ms := Timeout;
      DMI_Core.Initialise;
      Test_Support.Reset_EVC_Model;
      Put_Line ("  mission: the mock enters TSM at" & Integer'Image (Mock_TSM)
                & " m, RSM at" & Integer'Image (Mock_RSM)
                & " m; the on-board, on the mock's train, TSM at"
                & Integer'Image (Board_TSM) & " m, commands the service "
                & "brake at" & Integer'Image (Board_SB)
                & " m, the emergency brake at" & Integer'Image (Board_EB)
                & " m, RSM at" & Integer'Image (Board_RSM) & " m");

      Check (Mission_Diffs (Mission_SB) = 0,
             "mission: SB, the on-board's picture is the mock's");
      Check (Board_TSM in 0 .. Mock_TSM - 1
             and then Board_SB in Board_TSM .. Mock_TSM - 1,
             "mission: with build up times and correction factors the "
             & "Indication of the 100 km/h target comes before the mock's "
             & "TSM, and the mock's train passes the on-board's SBI before "
             & "the mock shows the target");
      Check (Outside_AB (Mission_TSM) = 0 and then Outside_AB (Mission_RSM) = 0
             and then Outside_AB (Mission_Stopped) = 0,
             "mission: the pictures differ in the areas A and B only");
      Check (Board_RSM in 0 .. Mock_RSM - 1,
             "mission: the on-board starts RSM before the mock (SBI1 of the "
             & "EOA and SBI2 of the SvL at the release speed)");
      Check (Mission_Diffs (Mission_After_LX) = 0,
             "mission: after the level crossing (CSM at 100 km/h) the "
             & "on-board's picture is the mock's");
   end Scenario_SDM_Mission;

   ---------------------------------------------------------------------
   --  A.3.12: the reduced build up times against the formulas in
   --  floating point
   ---------------------------------------------------------------------

   function R_Be_Reduced (I : EVC_Build_Up.Input_T) return LF is
      use Ada.Numerics.Long_Elementary_Functions;
      use type EVC_Build_Up.Target_Kind_T;
      --  s, cm/s, cm/s²
      Tbe  : constant LF := LF (I.T_Be) / 1000.0;
      Tr   : constant LF := LF (I.T_Be_React) / 1000.0;
      Ttm  : constant LF := LF (I.T_Traction_Max) / 1000.0;
      Ttn  : constant LF := LF (I.T_Traction_Min) / 1000.0;
      A1   : constant LF := LF (I.A_Est1) / 10.0;
      A2   : constant LF := LF (I.A_Est2) / 10.0;
      AEB  : constant LF := LF (I.A_EB) / 1000.0;
      ASM  : constant LF := LF (I.A_Safe_Max) / 1000.0;
      V0   : constant LF := LF (I.V_Est + I.V_Delta0);
      Vt   : constant LF := LF (I.V_Target);
      T2   : constant LF := 2.0 * Tbe - Tr;
      Tinc : constant LF := T2 - Tr;
      Vt1, Vt2, Te, D, T_Dist : LF;
      Speed : constant Boolean := I.Kind = EVC_Build_Up.Speed_Target;
   begin
      if I.Kind = EVC_Build_Up.EOA_Target or else I.Kt_Zero
        or else I.T_Traction >= I.T_Be
      then
         return Tbe;
      end if;
      Vt1 := (if Ttm < Tr then V0 + A1 * Ttm + A2 * (Tr - Ttm)
              else V0 + A1 * Tr);
      if (Speed and then Vt1 <= Vt) or else (not Speed and then Vt1 = 0.0)
      then
         return Tr;
      end if;
      Vt2 := LF'Max (0.0, V0 + A1 * Ttm + A2 * (T2 - Ttm)
                          - AEB * (T2 - Tr) / 2.0);
      if (Speed and then Vt2 >= Vt) or else (not Speed and then Vt2 > 0.0)
      then
         return Tbe;
      end if;
      declare
         R  : constant LF := A2 / AEB * Tinc;
         DV : constant LF := LF'Max (0.0, V0 - Vt);
      begin
         Te := Tr + R + Sqrt (R ** 2 + 2.0 * Tinc / AEB
                                    * (DV + (A1 - A2) * Ttm + A2 * Tr));
      end;
      D := ((A2 - A1) * Ttm ** 2 / 2.0 + AEB * Tr ** 3 / (6.0 * Tinc))
        + (V0 + (A1 - A2) * Ttm - AEB * Tr ** 2 / (2.0 * Tinc)) * Te
        + (A2 + AEB * Tr / Tinc) * Te ** 2 / 2.0
        - AEB / Tinc * Te ** 3 / 6.0;
      if A2 = 0.0 then
         T_Dist := (D + Vt ** 2 / (2.0 * ASM)) / V0 - V0 / (2.0 * ASM);
      else
         declare
            TX : constant LF := (V0 + (A1 - A2) * Ttn) / (-A2);
         begin
            T_Dist := TX + Sqrt (ASM / (ASM + A2)
                                 * (TX ** 2 + ((A1 - A2) * Ttn ** 2
                                               + 2.0 * D) / A2)
                                 + Vt ** 2 / (A2 * (ASM + A2)));
         end;
      end if;
      return LF'Max (Tr, LF'Min (LF'Max ((Tr + Te) / 2.0, T_Dist), Tbe));
   end R_Be_Reduced;

   function R_Bs_Reduced (I : EVC_Build_Up.Input_T) return LF is
      use Ada.Numerics.Long_Elementary_Functions;
      use type EVC_Build_Up.Target_Kind_T;
      Tbs  : constant LF := LF (I.T_Bs) / 1000.0;
      Tr   : constant LF := LF (I.T_Bs_React) / 1000.0;
      ASB  : constant LF := LF (I.A_SB) / 1000.0;
      AEM  : constant LF := LF (I.A_Expected_Max) / 1000.0;
      V    : constant LF := LF (I.V_Est);
      Vt   : constant LF := LF (I.V_Target);
      T2   : constant LF := 2.0 * Tbs - Tr;
      Tinc : constant LF := T2 - Tr;
      Speed : constant Boolean := I.Kind = EVC_Build_Up.Speed_Target;
      Te, D, T_Dist : LF;
   begin
      if (Speed and then V <= Vt) or else (not Speed and then V = 0.0) then
         return Tr;
      end if;
      declare
         V2 : constant LF := LF'Max (0.0, V - ASB * (T2 - Tr) / 2.0);
      begin
         if (Speed and then V2 >= Vt) or else (not Speed and then V2 > 0.0)
         then
            return Tbs;
         end if;
      end;
      Te := Tr + Sqrt (2.0 * Tinc / ASB * LF'Max (0.0, V - Vt));
      D := V * Te - ASB / (6.0 * Tinc) * (Te - Tr) ** 3;
      T_Dist := (D + Vt ** 2 / (2.0 * AEM)) / V - V / (2.0 * AEM);
      return LF'Max (Tr, LF'Min (LF'Max ((Tr + Te) / 2.0, T_Dist), Tbs));
   end R_Bs_Reduced;

   procedure Scenario_SDM_Build_Up is
      use EVC_Fixed;
      E0      : constant EVC_Braking.Times_T :=
        EVC_Braking.Conversion_Emergency (SIn.Passenger_P, 40_000, True);
      S0      : constant EVC_Braking.Times_T :=
        EVC_Braking.Conversion_Service (SIn.Passenger_P, 40_000, True);
      Speeds  : constant array (1 .. 4) of LF := (20.0, 60.0, 120.0, 160.0);
      Targets : constant array (1 .. 3) of LF := (0.0, 40.0, 80.0);
      Accels  : constant array (1 .. 3) of Num := (0, 20, 300);
      Reduced : Natural := 0;
      Compared_BU : Natural := 0;
      Worst   : LF := 0.0;
   begin
      for V of Speeds loop
         for VT of Targets loop
            for A of Accels loop
               for Ttm in 0 .. 1 loop
                  declare
                     I : constant EVC_Build_Up.Input_T :=
                       (Kind           => (if VT = 0.0
                                           then EVC_Build_Up.Zero_Target
                                           else EVC_Build_Up.Speed_Target),
                        V_Est          => Speed_T (Cms (V)),
                        V_Delta0       => 56,
                        V_Target       => Speed_T (Cms (VT)),
                        A_Est1         => A,
                        A_Est2         => Min (A, 400),
                        T_Be_React     => Div_Ceil (E0.React * 1_100, 1_000),
                        T_Be           => Div_Ceil (E0.Build_Up * 1_100,
                                                    1_000),
                        T_Bs_React     => S0.React,
                        T_Bs           => S0.Build_Up,
                        T_Traction     => Num (Ttm) * 500,
                        T_Traction_Min => 0,
                        T_Traction_Max => Num (Ttm) * 500,
                        A_EB           => 55_000,
                        A_Safe_Max     => 72_000,
                        A_SB           => 80_000,
                        A_Expected_Max => 95_000,
                        Kt_Zero        => False);
                     K_Be : constant Num := EVC_Build_Up.T_Be_Reduced (I);
                     K_Bs : constant Num := EVC_Build_Up.T_Bs_Reduced (I);
                     R_Be : constant LF := R_Be_Reduced (I) * 1000.0;
                     R_Bs : constant LF := R_Bs_Reduced (I) * 1000.0;
                     Tag  : constant String :=
                       Img_LF (V) & " km/h to" & Img_LF (VT) & " km/h, A"
                       & Img (Natural (A)) & ", traction" & Img (Ttm * 500);
                  begin
                     Compared_BU := Compared_BU + 2;
                     if K_Be < I.T_Be or else K_Bs < I.T_Bs then
                        Reduced := Reduced + 1;
                     end if;
                     Worst := LF'Max (Worst, LF'Max (LF (K_Be) - R_Be,
                                                     LF (K_Bs) - R_Bs));
                     Check (LF (K_Be) >= R_Be - 0.001
                            and then LF (K_Be) - R_Be <= 50.0,
                            "A.3.12 T_be_reduced " & Tag & ":" & Img_LF (LF (K_Be))
                            & " ms, the formulas" & Img_LF (R_Be) & " ms");
                     Check (LF (K_Bs) >= R_Bs - 0.001
                            and then LF (K_Bs) - R_Bs <= 50.0,
                            "A.3.12 T_bs_reduced " & Tag & ":" & Img_LF (LF (K_Bs))
                            & " ms, the formulas" & Img_LF (R_Bs) & " ms");
                  end;
               end loop;
            end loop;
         end loop;
      end loop;
      Check (Reduced > 0, "A.3.12: some build up times reduced");
      Put_Line ("  A.3.12:" & Img (Compared_BU) & " reduced times compared,"
                & Img (Reduced) & " cases reduced, the kernel at most"
                & Img_LF (Worst) & " ms longer (never shorter)");
   end Scenario_SDM_Build_Up;

end EVC_Test_Mission;
