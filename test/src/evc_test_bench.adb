with EVC_Test_Support;  use EVC_Test_Support;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Streams.Stream_IO;
with Ada.Streams;
with Ada.Text_IO;
with ETCS_Track_Packets.P79;
with ETCS_Train_Packets.P0;
with ETCS_Variables;
with EVC_Core;
with EVC_Distances;
with EVC_Location;
with EVC_Modes;
with EVC_Odometry;
with EVC_Ports;
with EVC_Position;
with EVC_Track;
with GNAT.SHA256;
with Interfaces;
with Sim_JRU;
with Sim_Onboard_Env;
with Sim_RBC;
with EVC_Radio_Authority;
with Sim_Trackside;
with Sim_Vehicle;

package body EVC_Test_Bench is

   package R0 renames ETCS_Train_Packets.P0;
   package Pos renames EVC_Position;
   package Odo renames EVC_Odometry;
   package T79 renames ETCS_Track_Packets.P79;

   use type EVC_Location.Anchor_T;
   use type EVC_Distances.Cm_T;
   use type EVC_Distances.Direction_T;
   use type EVC_Core.Time_Ms_T;
   use type Pos.Status_T;
   use type Sim_RBC.State_T;
   use type ETCS_Variables.NID_BG_T;
   use type ETCS_Variables.Q_DIRLRBG_T;
   use type ETCS_Variables.Q_DLRBG_T;
   use type ETCS_Variables.Q_DIRTRAIN_T;
   use Ada.Text_IO;
   use Ada.Streams;
   use EVC_Modes;
   use EVC_Ports;
   use Interfaces;

   --  The bench: the on-board in the environment of sim/ (Sim_Onboard_Env)
   --  that onboard.wasm and obj/evc_onboard run. The first Bench_Cycles
   --  cycles are the scenario of test/wasm/onboard_smoke.js: the digest of
   --  the on-board's DMI frames is the golden bench_onboard, which the
   --  wasm build must reproduce byte for byte. Then the mission goes on to
   --  its end, and what the on-board did on the way is checked and
   --  printed. The line's packet 3 (Sim_Trackside) keeps Q_NVEMRRLS = 0,
   --  the A.3.2 default: an emergency brake of the speed and distance
   --  monitoring is revoked at standstill only; the value 1 is run by
   --  Scenario_SDM_Mission, and both by the Scenario_EMRRLS_* scenarios
   --  at the end.
   ---------------------------------------------------------------------

   Bench_Cycles : constant := 600;

   procedure Scenario_Bench_Onboard is
      package Env renames Sim_Onboard_Env;

      Frames : Stream_Element_Array (1 .. 16_384);
      Last   : Stream_Element_Offset;
      Ctx    : GNAT.SHA256.Context := GNAT.SHA256.Initial_Context;
      Bytes  : Natural := 0;
      Trace  : constant Boolean :=
        Ada.Environment_Variables.Exists ("BENCH_TRACE");

      --  where things happened (m of the front end)
      Never : constant Integer := Integer'First;
      Supervised_At, TSM_At, RSM_At, SB_At, EB_At : Integer := Never;
      --  phase E4: the cycle of SR and of FS, the levels shown
      SR_Cycle, FS_Cycle : Natural := 0;
      Cycles             : Natural := 0;
      Other_Level        : Boolean := False;
      Acks, Acks_Supervised : Natural := 0;
      Max_Kmh : Natural := 0;
      Last_Mon, Last_Cmd, Last_Brake : Natural := 99;

      --  EVC_DUMP=dir: the hashed frames also go to dir/bench_onboard.bin,
      --  one record per DMI frame in the format of the other dumps (port
      --  u8, length u16 little endian, payload; test/tools/evc_dump.py),
      --  so that golden_review.py sees this golden too; the digest is the
      --  frames' alone, as before
      package SIO renames Ada.Streams.Stream_IO;
      Dumping : constant Boolean :=
        Ada.Environment_Variables.Exists ("EVC_DUMP");
      Dump_F  : SIO.File_Type;

      procedure Dump_Frames (Data : Stream_Element_Array) is
         P : Stream_Element_Offset := Data'First;
      begin
         while P <= Data'Last loop
            declare
               --  a frame: type u8, length u32 (little endian), payload
               N : constant Stream_Element_Offset :=
                 (if P + 4 <= Data'Last
                  then Stream_Element_Offset'Min
                         (5 + Stream_Element_Offset (Data (P + 1))
                            + 256 * Stream_Element_Offset (Data (P + 2)),
                          Data'Last - P + 1)
                  else Data'Last - P + 1);
               Head : constant Stream_Element_Array (1 .. 3) :=
                 (Stream_Element (Port_T'Pos (DMI)),
                  Stream_Element (N mod 256), Stream_Element (N / 256));
            begin
               SIO.Write (Dump_F, Head);
               SIO.Write (Dump_F, Data (P .. P + N - 1));
               P := P + N;
            end;
         end loop;
      end Dump_Frames;

      procedure Note (Where : in out Integer; Now : Boolean) is
      begin
         if Now and then Where = Never then
            Where := Env.Position_M;
         end if;
      end Note;

      procedure Cycle (Digest : Boolean) is
         Cmd : constant Natural := Natural (Sim_Vehicle.Commands);
      begin
         Env.Step (100);
         Cycles := Cycles + 1;
         if Env.Mode_Code = 7 and then SR_Cycle = 0 then
            SR_Cycle := Cycles;
         end if;
         if Env.Mode_Code = 2 and then FS_Cycle = 0 then
            FS_Cycle := Cycles;
         end if;
         if Cycles > 3 and then Env.Level_Code /= 4 then
            Other_Level := True;
         end if;
         Env.Take_DMI (Frames, Last);
         if Digest then
            GNAT.SHA256.Update (Ctx, Frames (Frames'First .. Last));
            Bytes := Bytes + Natural (Last - Frames'First + 1);
            if Dumping then
               Dump_Frames (Frames (Frames'First .. Last));
            end if;
         end if;
         if Env.V_Perm_KMH > 0 then
            Note (Supervised_At, True);
            Note (TSM_At, Env.Monitoring = 1);
            Note (RSM_At, Env.Monitoring = 2);
            Note (SB_At, (Sim_Vehicle.Commands and EVC_Ports.TIU_SBC) /= 0);
            Note (EB_At, (Sim_Vehicle.Commands and EVC_Ports.TIU_EBC) /= 0);
         end if;
         Max_Kmh := Natural'Max (Max_Kmh, Env.Speed_KMH);
         if Trace and then (Env.Monitoring /= Last_Mon
                            or else Cmd /= Last_Cmd
                            or else Env.Brake_Indication /= Last_Brake)
         then
            Put_Line ("  bench t" & Img (Natural (EVC_Core.Time_Ms / 100))
                      & " x" & Integer'Image (Env.Position_M)
                      & " v" & Img (Env.Speed_KMH)
                      & " vperm" & Img (Env.V_Perm_KMH)
                      & " mon" & Img (Env.Monitoring)
                      & " st" & Img (Env.Status)
                      & " tiu" & Img (Cmd)
                      & " brake" & Img (Env.Brake_Indication));
         end if;
         Last_Mon := Env.Monitoring;
         Last_Cmd := Cmd;
         Last_Brake := Env.Brake_Indication;
         if Env.Ack_Requested then
            Env.Receive (Env.Brake_Release_Ack);
            Acks := Acks + 1;
            if Env.V_Perm_KMH > 0 then
               Acks_Supervised := Acks_Supervised + 1;
            end if;
         end if;
      end Cycle;

      Stopped_At : Integer := Never;
      function Img_M (M : Integer) return String is
        (if M = Never then " never" else Integer'Image (M) & " m");
   begin
      Env.Reset;
      Check (Sim_Trackside.Built_OK,
             "bench: every telegram of the line encoded");
      Env.Set_Desk (0, Auto => True);
      if Dumping then
         Ada.Directories.Create_Path
           (Ada.Environment_Variables.Value ("EVC_DUMP"));
         SIO.Create (Dump_F, SIO.Out_File,
                     Ada.Environment_Variables.Value ("EVC_DUMP")
                     & "/bench_onboard.bin");
      end if;
      for I in 1 .. Bench_Cycles loop
         Cycle (Digest => True);
         --  phase E4: the start of mission in level 1, a step a cycle
         if I <= Env.SoM_Steps then
            Env.Receive (Env.SoM_Frame (I));
         end if;

      end loop;
      if Dumping then
         SIO.Close (Dump_F);
      end if;
      Check_Digest ("bench_onboard", GNAT.SHA256.Digest (Ctx));
      Put_Line ("  bench:" & Img (Bench_Cycles) & " cycles," & Img (Bytes)
                & " bytes of DMI frames, the train at"
                & Integer'Image (Env.Position_M) & " m,"
                & Img (Env.Speed_KMH) & " km/h");
      Check (EVC_Position.LRBG.Valid and then Env.V_Perm_KMH > 0,
             "bench: the first group read, its MA supervised");

      --  the rest of the mission, to the stop in front of the EOA
      for I in 1 .. 6_000 loop
         Cycle (Digest => False);
         if RSM_At /= Never and then Env.Speed_KMH = 0 then
            Stopped_At := Env.Position_M;
            exit;
         end if;
      end loop;
      Put_Line ("  bench: the MA supervised from" & Img_M (Supervised_At)
                & ", TSM at" & Img_M (TSM_At)
                & ", RSM at" & Img_M (RSM_At)
                & ", stopped at" & Img_M (Stopped_At)
                & " (EOA" & Integer'Image (EVC_Track.EOA_M)
                & " m); service brake" & Img_M (SB_At)
                & ", emergency brake" & Img_M (EB_At)
                & " under the MA; top speed" & Img (Max_Kmh) & " km/h;"
                & Img (Acks) & " brake releases acknowledged;"
                & Img (Env.Balises_Read) & " balises;"
                & Img (Sim_JRU.Count) & " JRU records");
      Check (Env.Balises_Read = Sim_Trackside.Balise_Count
             and then Sim_JRU.Count_Of (2) = Sim_Trackside.Balise_Count,
             "bench: every balise of the line read and its telegram "
             & "accepted");
      Check (RSM_At /= Never and then Stopped_At /= Never
             and then Stopped_At <= EVC_Track.EOA_M,
             "bench: the train stops in front of the EOA in RSM");
      --  phase E4: the start of mission in level 1 (5.4.3.2: driver ID,
      --  level, Train Data, train running number, 'Start', SR
      --  acknowledged) before the train moves, FS at the MA of the first
      --  group (4.6.3 [32]); the order to level 2 at 5000 m keeps level 1
      --  (5.10.2.4: no radio before E5)
      Check (Acks = 0 and then SR_Cycle = Env.SoM_Steps + 1
             and then FS_Cycle > SR_Cycle and then not Other_Level
             and then Env.Mode_Code = 2,
             "bench: SR after the start of mission at cycle"
             & Img (SR_Cycle) & ", FS at cycle" & Img (FS_Cycle)
             & ", level 1 throughout, no brake to acknowledge (5.4.3.2, "
             & "4.6.3 [8], [32], 5.10.2.4)");
      Check (SB_At = Never and then EB_At = Never,
             "bench: the automatic driver keeps below the on-board's "
             & "permitted speed, no intervention under the MA");
      Check (not Env.Failed and then Env.Dropped_DMI = 0
             and then Sim_JRU.Malformed = 0,
             "bench: no failure, no DMI frame lost, JRU records whole");
   end Scenario_Bench_Onboard;

   ---------------------------------------------------------------------
   --  The wrap of the odometer counters (EVC_Ports: d_est is a wrapping
   --  32 bit counter, over and under are wrapping u32 counters;
   --  EVC_Odometry takes the difference of two samples modulo 2**32)
   ---------------------------------------------------------------------

   --  Two power-ups whose first sample has d_est just below a 32 bit
   --  boundary: the signed one (2**31 - 1 to -2**31, the frame goes on
   --  beyond the 32 bit range) and the unsigned one (2**32 - 1 to 0, the
   --  frame goes through 0); over and under start below the other
   --  boundary and wrap on the way. A balise group straddles the wrap of
   --  d_est, the next one is read after it. Every cycle the frame, its
   --  confidence, the front ends and the geographical position move by
   --  the change of the sample, forth and back, without a jump and
   --  without saturation. An over- or under-reading counter that goes
   --  back (across its wrap) is an anomaly; d_est going back while the
   --  train moves towards cab B is not.
   procedure Scenario_Odometer_Wrap is
      subtype Cm is EVC_Distances.Cm_T;
      Two_31 : constant Integer_64 := 2**31;
      Two_32 : constant Integer_64 := 2**32;

      --  A and B on different sides of a multiple of 2**31 (the signed
      --  and the unsigned boundaries of a 32 bit counter)
      function Crosses (A, B : Integer_64) return Boolean is
        (A - A mod Two_31 /= B - B mod Two_31);

      --  D0: the first reading of d_est, 499.5 m below a boundary, so
      --  that it wraps between the balises of group 10 (498 m, 501 m)
      procedure Phase (Name : String; D0, Over0, Under0 : Integer_64) is
         --  the first reading as a signed 32 bit value
         X0      : constant Integer_64 :=
           (if D0 mod Two_32 >= Two_31 then D0 mod Two_32 - Two_32
            else D0 mod Two_32);
         Cycles  : Natural := 0;
         Jumps   : Natural := 0;
         Wrapped_D, Wrapped_Over, Wrapped_Under, Back_D : Boolean := False;
         G       : T79.Packet_T;
         P       : R0.Packet_T;

         function Frame_Of (Track_Cm : Integer_64) return Cm is
           (Cm (X0 + Track_Cm));

         --  One step of the track model, the under-reading counter
         --  growing Extra more than the over-reading one, checked
         --  against the change of the sample
         procedure Checked_Step (Step_Cm : Integer_64;
                                 Extra   : Integer_64 := 10) is
            D_0    : constant Integer_64 := Odo_D;
            O_0    : constant Integer_64 := Odo_Over;
            U_0    : constant Integer_64 := Odo_Under;
            X      : constant Cm := Odo.Position;
            Low    : constant Cm := Odo.Low;
            High   : constant Cm := Odo.High;
            Over   : constant Cm := Odo.Over;
            Under  : constant Cm := Odo.Under;
            Trav   : constant Cm := Odo.Travelled;
            Anom   : constant Natural := Odo.Anomalies;
            LRBG   : constant EVC_Location.Anchor_T := Pos.LRBG;
            Est    : constant Cm := Pos.Estimated_Front;
            D_Over : constant Cm := Pos.Doubt_Over;
            D_Und  : constant Cm := Pos.Doubt_Under;
            Min_S  : constant Cm := Pos.Min_Safe_Front;
            Max_S  : constant Cm := Pos.Max_Safe_Front;
            Geo_K  : constant Boolean := Pos.Geo_Known;
            Geo    : constant Natural := Pos.Geo_Metres;
            DX, D_O, D_U, D_Low, D_High : Cm;
            OK     : Boolean;
         begin
            Odo_Under := Odo_Under + Extra;
            Step (Step_Cm);
            DX := Cm (Odo_D - D_0);
            D_O := Cm (Odo_Over - O_0);
            D_U := Cm (Odo_Under - U_0);
            --  towards cab A the over-reading widens the low side,
            --  towards cab B the high side
            D_Low := (if Step_Cm > 0 then D_O else D_U);
            D_High := (if Step_Cm > 0 then D_U else D_O);
            OK := Odo.Position = Frame_Of (Train_Cm)
              and then Odo.Position - X = DX
              and then Odo.Low - Low = D_Low
              and then Odo.High - High = D_High
              and then Odo.Over - Over = D_O
              and then Odo.Under - Under = D_U
              and then Odo.Travelled - Trav = abs DX
              and then Odo.Anomalies = Anom;
            if LRBG.Valid and then Pos.LRBG = LRBG then
               OK := OK
                 and then Pos.Estimated_Front - Est = DX
                 and then Pos.Doubt_Over - D_Over = D_Low
                 and then Pos.Doubt_Under - D_Und = D_High
                 and then Pos.Min_Safe_Front - Min_S = DX - D_Low
                 and then Pos.Max_Safe_Front - Max_S = DX + D_High;
            end if;
            if Geo_K and then Pos.Geo_Known then
               OK := OK
                 and then Integer_64 (Pos.Geo_Metres) - Integer_64 (Geo)
                          = Integer_64 (DX) / 100
                 and then Geo_Seen = Unsigned_32 (Pos.Geo_Metres);
            end if;
            Cycles := Cycles + 1;
            if not OK then
               Jumps := Jumps + 1;
               Put_Line ("odometer wrap: " & Name
                         & ", a jump in the step to"
                         & Integer_64'Image (Train_Cm));
            end if;
            if Step_Cm > 0 then
               Wrapped_D := Wrapped_D or else Crosses (D_0, Odo_D);
            else
               Back_D := Back_D or else Crosses (D_0, Odo_D);
            end if;
            Wrapped_Over := Wrapped_Over or else Crosses (O_0, Odo_Over);
            Wrapped_Under := Wrapped_Under
                             or else Crosses (U_0, Odo_Under);
         end Checked_Step;

      begin
         --  Start_Track with the counters of the odometer elsewhere
         EVC_Core.Initialise;
         Reset_Capture;
         Forget;
         Track_N := 0;
         Train_Cm := 0;
         Odo_D := D0;
         Odo_Over := Over0;
         Odo_Under := Under0;
         Error_Per_Mille := 0;
         Bound_Per_Mille := 20;
         Speed_Cms := 1000;
         Cold_Byte := 0;
         Cold_Distance := 0;
         Input (TIU, (1, 1));
         Sample (0);
         Cycle;
         EVC_Core.Set_Mode_For_Test (Legacy_Mode, L1);
         Check (Odo.Known and then Odo.Position = Cm (X0)
                and then Odo.Low = 0 and then Odo.High = 0
                and then Odo.Anomalies = 0,
                "odometer wrap: " & Name & ", the frame starts at the "
                & "first reading taken as signed");

         --  group 10 straddles the wrap of d_est: balise 0 at 498 m is
         --  read below it, balise 1 at 501 m above it, in one step;
         --  group 20 at 520 m is read after it
         G.Q_DIR := 1;
         G.Q_SCALE := 1;
         G.NID_BG := 10;
         G.D_POSOFF := 0;
         G.Q_MPOSITION := 1;
         G.M_POSITION := 42_000;
         G.N_ITER := 0;
         Add_Group (Group (10, 498));
         Track (1).Has_Geo := True;
         Track (1).Geo := G;
         Add_Group (Group (20, 520));

         while Train_Cm < 51_000 loop
            Checked_Step (1_000);
         end loop;
         Check (Pos.Status = Pos.Valid
                and then Pos.LRBG.Valid and then Pos.LRBG.Id.NID_BG = 10
                and then Pos.LRBG.X = Frame_Of (49_800)
                and then Pos.LRBG.Orientation = EVC_Distances.Plus
                and then Pos.Estimated_Front = 51_300 - 49_800,
                "odometer wrap: " & Name & ", the group read across the "
                & "wrap is the LRBG at its place, nominal, got X"
                & Cm'Image (Pos.LRBG.X) & ", expected"
                & Cm'Image (Frame_Of (49_800)));
         Check (Pos.Geo_Known and then Pos.Geo_Metres = 42_015
                and then Geo_Seen = 42_015,
                "odometer wrap: " & Name & ", geographical position "
                & "42 015 m, on the DMI (MSG_STATUS), got"
                & Natural'Image (Pos.Geo_Metres));

         while Train_Cm < 60_000 loop
            Checked_Step (1_000);
         end loop;
         Check (Pos.LRBG.Id.NID_BG = 20
                and then Pos.LRBG.X = Frame_Of (52_000)
                and then Pos.LRBG.Orientation = EVC_Distances.Plus
                and then Pos.Estimated_Front = 60_300 - 52_000
                and then Pos.Geo_Metres = 42_105
                and then Geo_Seen = 42_105,
                "odometer wrap: " & Name & ", the group read after the "
                & "wrap is the LRBG at its place, got X"
                & Cm'Image (Pos.LRBG.X));
         Check (JRU_Seen (4) = 0 and then JRU_Seen (5) = 0
                and then JRU_Seen (6) = 0 and then JRU_Seen (10) = 2,
                "odometer wrap: " & Name & ", two new LRBGs, nothing "
                & "unexpected, nothing missed");
         Stand;
         P := Pos.Position_Report (M_SB, L1);
         Check (P.NID_BG = 20 and then P.Q_DIRLRBG = 1
                and then P.Q_DLRBG = 1 and then P.Q_DIRTRAIN = 1
                and then Integer (P.D_LRBG) = 830,
                "odometer wrap: " & Name
                & ", packet 0 83 m from the LRBG");

         --  the over-reading counter back by 10 m, across its own wrap:
         --  an anomaly, its growth ignored for this sample
         declare
            X     : constant Cm := Odo.Position;
            Low   : constant Cm := Odo.Low;
            High  : constant Cm := Odo.High;
            Over  : constant Cm := Odo.Over;
            Under : constant Cm := Odo.Under;
            Back  : constant Boolean :=
              Crosses (Odo_Over, Odo_Over - 1_000);
         begin
            Odo_Over := Odo_Over - 1_000;
            Step (1_000);
            Check (Back and then Odo.Anomalies = 1
                   and then Odo.Position - X = 1_000
                   and then Odo.Over = Over and then Odo.Low = Low
                   and then Odo.Under - Under = 20
                   and then Odo.High - High = 20,
                   "odometer wrap: " & Name & ", the over counter back "
                   & "across its wrap is an anomaly, nothing added");
         end;
         declare
            Under : constant Cm := Odo.Under;
            High  : constant Cm := Odo.High;
         begin
            Odo_Under := Odo_Under - 1;
            Stand;
            Check (Odo.Anomalies = 2 and then Odo.Under = Under
                   and then Odo.High = High,
                   "odometer wrap: " & Name & ", the under counter back "
                   & "by 1 cm at standstill is an anomaly");
         end;
         --  from the new readings on, normal again
         Checked_Step (1_000);
         Stand;

         --  back towards cab B, the track without balises: d_est goes
         --  back across its wrap
         Track_N := 0;
         while Train_Cm > 45_000 loop
            Checked_Step (-1_000);
         end loop;
         Check (Odo.Anomalies = 2
                and then Odo.Position = Frame_Of (45_000)
                and then Pos.LRBG.Id.NID_BG = 20
                and then Pos.Estimated_Front = 45_300 - 52_000
                and then Pos.Geo_Metres = 42_000 - 45
                and then Geo_Seen = 42_000 - 45,
                "odometer wrap: " & Name & ", back towards cab B across "
                & "the wrap, no anomaly");

         Check (Jumps = 0 and then Cycles = 78,
                "odometer wrap: " & Name & "," & Natural'Image (Cycles)
                & " cycles, each changed the frame, its confidence, the "
                & "front ends and the geographical position by the "
                & "sample's change," & Natural'Image (Jumps) & " did not");
         Check (Wrapped_D and then Back_D and then Wrapped_Over
                and then Wrapped_Under,
                "odometer wrap: " & Name & ", d_est crossed its boundary "
                & "forth and back, over and under crossed theirs");
         Check (Odo.Position /= EVC_Distances.Max_Cm
                and then Odo.Position /= -EVC_Distances.Max_Cm
                and then Odo.Travelled = 60_000 + 2_000 + 17_000,
                "odometer wrap: " & Name & ", no saturation");
      end Phase;

   begin
      --  d_est 2**31 - 499.5 m; over below 2**32, under below 2**31
      Phase ("signed", Two_31 - 49_950, Two_32 - 500, Two_31 - 300);
      Check (Pos.LRBG.X = Cm (Two_31) + 2_050,
             "odometer wrap: the frame goes on beyond the 32 bit range");
      --  d_est 2**32 - 499.5 m (-499.5 m signed); over below 2**31,
      --  under below 2**32
      Phase ("unsigned", Two_32 - 49_950, Two_31 - 500, Two_32 - 300);
      Check (Pos.LRBG.X = 2_050 and then Odo.Position = 45_000 - 49_950,
             "odometer wrap: the frame through 0 and back");
   end Scenario_Odometer_Wrap;

   ---------------------------------------------------------------------
   --  Phase E5: the level 2 line of the bench page (the third track
   --  choice of test/wasm/index.html, onboard_smoke.js): the default
   --  track with the radio on (Sim_Onboard_Env.Set_Radio), the scripted
   --  start of mission in level 2 (5.4.3.2: S1, S2, S3, the session of
   --  3.5.3.7 with Sim_RBC, the SoM position report 157 answered with 41
   --  (S10), S12 Train Data acknowledged by 8, S13, 'Start' S20 / S21 /
   --  S22) and the mission on the MA by radio (message 3, packet 15) to
   --  the stop in front of the EOA. The first L2_Cycles cycles are the
   --  golden bench_level2, which the wasm build must reproduce.
   ---------------------------------------------------------------------

   L2_Cycles : constant := 600;

   procedure Scenario_Bench_Level_2 is
      package Env renames Sim_Onboard_Env;

      Frames : Stream_Element_Array (1 .. 16_384);
      Last   : Stream_Element_Offset;
      Ctx    : GNAT.SHA256.Context := GNAT.SHA256.Initial_Context;
      Trace  : constant Boolean :=
        Ada.Environment_Variables.Exists ("BENCH_TRACE");
      Cycles, FS_Cycle, SoM_Cycle : Natural := 0;
      Modes_Seen : array (0 .. 255) of Boolean := (others => False);
      Last_Line : String (1 .. 60) := (others => ' ');
      RSM_Seen  : Boolean := False;
      Stopped   : Boolean := False;
      Start_Pos : Integer := 0;

      procedure Cycle (Digest : Boolean) is
      begin
         Env.Step (100);
         Cycles := Cycles + 1;
         Env.Take_DMI (Frames, Last);
         if Digest then
            GNAT.SHA256.Update (Ctx, Frames (Frames'First .. Last));
         end if;
         if Env.Mode_Code <= 255 then
            Modes_Seen (Env.Mode_Code) := True;
         end if;
         if Env.Mode_Code = 2 and then FS_Cycle = 0 then
            FS_Cycle := Cycles;
         end if;
         if Env.SoM_L2_Sent >= 6 and then SoM_Cycle = 0 then
            SoM_Cycle := Cycles;
         end if;
         RSM_Seen := RSM_Seen or else Env.Monitoring = 2;
         if Env.Ack_Requested then
            Env.Receive (Env.Brake_Release_Ack);
         end if;
         if Trace then
            declare
               L : constant String :=
                 " mode" & Img (Env.Mode_Code) & " lvl" & Img (Env.Level_Code)
                 & " data" & Img (Env.Onboard_Data)
                 & " ses" & Img (Env.Onboard_Session)
                 & " rbc" & Img (Env.Onboard_RBC)
                 & " wait" & Img (Env.Onboard_Waiting)
                 & " som" & Img (Env.SoM_L2_Sent)
                 & " vperm" & Img (Env.V_Perm_KMH)
                 & " srg" & Boolean'Image (EVC_Radio_Authority.RBC_SR_Given)
                 & " tk" & Img (Sim_RBC.Taken) & "/" & Img (Sim_RBC.Last_NID_Taken);
               Pad : String (1 .. 60) := (others => ' ');
            begin
               Pad (1 .. Natural'Min (60, L'Length)) :=
                 L (L'First .. L'First + Natural'Min (60, L'Length) - 1);
               if Pad /= Last_Line then
                  Put_Line ("  level2 c" & Img (Cycles) & L
                            & " x" & Integer'Image (Env.Position_M)
                            & " rbc-last" & Img (Sim_RBC.Last_NID_Taken));
                  Last_Line := Pad;
               end if;
            end;
         end if;
      end Cycle;
   begin
      Env.Set_Radio (True);
      Env.Reset;
      Env.Set_Desk (0, Auto => True);
      Start_Pos := Env.Position_M;
      for I in 1 .. L2_Cycles loop
         Cycle (Digest => True);
      end loop;
      Check_Digest ("bench_level2", GNAT.SHA256.Digest (Ctx));
      for I in 1 .. 6_000 loop
         Cycle (Digest => False);
         if RSM_Seen and then Env.Speed_KMH = 0 then
            Stopped := True;
            exit;
         end if;
      end loop;
      Put_Line ("  level 2: start of mission sent by cycle" & Img (SoM_Cycle)
                & ", FS at cycle" & Img (FS_Cycle) & ", stopped at"
                & Integer'Image (Env.Position_M) & " m (EOA"
                & Integer'Image (EVC_Track.EOA_M) & " m), RBC: "
                & Img (Sim_RBC.Taken) & " messages taken,"
                & Img (Sim_RBC.Answered) & " answered,"
                & Img (Sim_RBC.Errors) & " errors");
      Check (SoM_Cycle > 0 and then Env.Level_Code = 5
             and then Sim_RBC.State (1) = Sim_RBC.Established
             and then Env.Onboard_RBC mod 2 = 1
             and then EVC_Radio_Authority.RBC_SR_Given,
             "bench level 2: the start of mission in level 2 with Sim_RBC "
             & "to 'Start' (5.4.3.2 S1 to S21: the session of 3.5.3.7, 157 "
             & "answered by 41, 129 acknowledged by 8), the MA request "
             & "answered by the SR authorisation (message 2, 4.4.11)");
      --  The on-board does not yet propose SR on the SR authorisation
      --  (5.4.3.2 S21 -> S24, E26 / E27; EVC_Mission leaves it to the
      --  authority half, which keeps it in SR_Authorised and does not
      --  read it again): until it does, the line stays in SB at S21.
      --  Once it does, the scripted driver acknowledges SR (step 7), the
      --  train reads the first group, reports its position (136) and
      --  Sim_RBC gives the MA: then FS and the stop are checked, and the
      --  golden bench_level2 changes (expected, to be reviewed)
      if Modes_Seen (7) then
         Check (Env.SoM_L2_Sent = Env.SoM_L2_Steps
                and then FS_Cycle > SoM_Cycle and then Modes_Seen (2),
                "bench level 2: SR acknowledged, FS on the MA by radio "
                & "(message 3, 3.8, 4.6.3)");
         Check (Stopped and then Env.Position_M <= EVC_Track.EOA_M
                and then not Env.Failed and then Sim_RBC.Errors = 0,
                "bench level 2: the train stops in front of the EOA, no "
                & "failure, every RTM output read by the RBC");
      else
         Put_Line ("  level 2: the line waits at S21 in SB: the on-board "
                   & "proposes no SR on the SR authorisation "
                   & "(5.4.3.2 E26 / E27 not implemented)");
         Check (Modes_Seen (1) and then not Modes_Seen (2)
                and then Env.Position_M = Start_Pos
                and then not Env.Failed and then Sim_RBC.Errors = 0,
                "bench level 2: no other mode than SB, the train at its "
                & "start, no failure, every RTM output read by the RBC");
      end if;
      Env.Set_Radio (False);
      Env.Reset;
   end Scenario_Bench_Level_2;


end EVC_Test_Bench;
