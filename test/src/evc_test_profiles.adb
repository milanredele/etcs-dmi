with EVC_Test_Support;  use EVC_Test_Support;
with DMI_Protocol;
with ETCS_Track_Packets.P12;
with ETCS_Track_Packets.P141;
with ETCS_Track_Packets.P39;
with ETCS_Track_Packets.P3;
with ETCS_Track_Packets.P51;
with ETCS_Track_Packets.P65;
with ETCS_Track_Packets.P66;
with ETCS_Track_Packets.P67;
with ETCS_Track_Packets.P68;
with ETCS_Track_Packets.P70;
with ETCS_Track_Packets.P71;
with ETCS_Track_Packets.P80;
with ETCS_Track_Packets.P88;
with ETCS_Variables;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Distances;
with EVC_Modes;
with EVC_Movement_Authority;
with EVC_National_Values;
with EVC_Origins;
with EVC_Ports;
with EVC_Position;
with EVC_Profiles;
with EVC_SDM;
with EVC_Stored_Information;
with EVC_Supervision_Input;
with EVC_Track_Conditions;
with EVC_Track_Description;
with EVC_Train_Data;
with Interfaces;

package body EVC_Test_Profiles is

   package T65 renames ETCS_Track_Packets.P65;
   package Pos renames EVC_Position;
   package SI renames EVC_Stored_Information;
   package TD renames EVC_Track_Description;
   package MAu renames EVC_Movement_Authority;
   package TCo renames EVC_Track_Conditions;
   package NVa renames EVC_National_Values;
   package Prof renames EVC_Profiles;
   package SIn renames EVC_Supervision_Input;
   package T3 renames ETCS_Track_Packets.P3;
   package T12 renames ETCS_Track_Packets.P12;
   package T39 renames ETCS_Track_Packets.P39;
   package T51 renames ETCS_Track_Packets.P51;
   package T66 renames ETCS_Track_Packets.P66;
   package T67 renames ETCS_Track_Packets.P67;
   package T68 renames ETCS_Track_Packets.P68;
   package T70 renames ETCS_Track_Packets.P70;
   package T71 renames ETCS_Track_Packets.P71;
   package T80 renames ETCS_Track_Packets.P80;
   package T88 renames ETCS_Track_Packets.P88;
   package T141 renames ETCS_Track_Packets.P141;

   use type EVC_Distances.Cm_T;
   use type EVC_Distances.Sense_T;
   use type T65.Packet_T;
   use type ETCS_Variables.NID_C_T;
   use type SIn.Release_Speed_Kind_T;
   use type SIn.National_Values_T;
   use type SIn.Kv_Step_T;
   use type SIn.Kr_Step_T;
   use type SIn.Brake_Inhibition_T;
   use type SIn.Redadh_Use_T;
   use type SIn.Onboard_Config_T;
   use type ETCS_Variables.M_MAMODE_T;
   use EVC_Modes;
   use EVC_Ports;
   use Interfaces;

   ---------------------------------------------------------------------
   --  Scenarios
   ---------------------------------------------------------------------

   --  The frames the on-board adds for E3 repeat DMI_Protocol
   pragma Warnings (Off, "condition is always*");
   procedure Scenario_E3_Protocol is
      use DMI_Protocol;
      P : EVC_DMI_Port.Planning_T;
      F : EVC_DMI_Port.Frame_Buffer_T;
      L : Natural;
      C : EVC_DMI_Port.Track_Cond_List_T := (others => (0, 0));
   begin
      Check (Unsigned_8 (MSG_TRACK_COND) = EVC_DMI_Port.MSG_TRACK_COND
             and then Unsigned_8 (MSG_PLANNING) = EVC_DMI_Port.MSG_PLANNING
             and then Track_Cond_Entry_Length = 2
             and then Planning_Gradient_Entry_Length = 3
             and then Planning_Speed_Entry_Length = 4
             and then Planning_Order_Entry_Length = 3,
             "E3: MSG_TRACK_COND and MSG_PLANNING equal DMI_Protocol");
      P.MA_Dist := 1234;
      P.Ceiling := 160;
      P.Gradient_Count := 2;
      P.Gradients (1) := (0, 5);
      P.Gradients (2) := (300, -8);
      P.Speed_Count := 1;
      P.Speeds (1) := (1234, 0);
      P.Order_Count := 1;
      P.Orders (1) := (2, 700);
      EVC_DMI_Port.Planning_Frame (P, F, L);
      Check (L = 5 + 8 + 1 + 6 + 1 + 4 + 1 + 3
             and then F (1) = EVC_DMI_Port.MSG_PLANNING
             and then Natural (F (2)) = L - 5
             and then F (6) = 16#D2# and then F (7) = 16#04#     -- 1234
             and then F (8) = 16#FF# and then F (9) = 16#FF#     -- none
             and then F (12) = 160
             and then F (14) = 2
             and then F (15) = 0 and then F (17) = 5
             and then F (18) = 16#2C# and then F (19) = 1        -- 300
             and then F (20) = 248                               -- -8
             and then F (21) = 1
             and then F (26) = 1 and then F (27) = 2
             and then F (28) = 16#BC# and then F (29) = 2,       -- 700
             "E3: MSG_PLANNING laid out as DMI_Protocol says");
      C (1) := (7, 3);
      C (2) := (9, 38);
      EVC_DMI_Port.Track_Cond_Frame (2, C, F, L);
      Check (L = 10 and then F (1) = EVC_DMI_Port.MSG_TRACK_COND
             and then F (2) = 5 and then F (6) = 2
             and then F (7) = 7 and then F (8) = 3
             and then F (9) = 9 and then F (10) = 38,
             "E3: MSG_TRACK_COND laid out as DMI_Protocol says");
   end Scenario_E3_Protocol;
   pragma Warnings (On, "condition is always*");

   --  3.11.3.2.3, 3.11.3.2.6: the SSP category of the train
   procedure Scenario_SSP_Categories is
      C : constant EVC_Train_Data.Categories_T :=
        EVC_Train_Data.Default_Categories;   -- 130 mm, passenger
      D : TD.Diff_Array := (others => (others => <>));
      Basic : constant ETCS_Variables.V_STATIC_T := 28;   -- 140 km/h
   begin
      Check (TD.Train_Speed (Basic, 0, D, C) = 3_888,
             "SSP category: the basic SSP without specific ones");
      D (1) := (Q_DIFF => 0, NC => 2, V_DIFF => 30);
      Check (TD.Train_Speed (Basic, 1, D, C) = 4_166,
             "SSP category: the cant deficiency of the train (a)");
      D (1) := (Q_DIFF => 0, NC => 0, V_DIFF => 24);
      D (2) := (Q_DIFF => 0, NC => 1, V_DIFF => 26);
      D (3) := (Q_DIFF => 0, NC => 5, V_DIFF => 32);
      Check (TD.Train_Speed (Basic, 3, D, C) = 3_611,
             "SSP category: the highest cant deficiency below (b)");
      D (1) := (Q_DIFF => 0, NC => 5, V_DIFF => 32);
      Check (TD.Train_Speed (Basic, 1, D, C) = 3_888,
             "SSP category: only higher ones, the basic SSP (c)");
      D (1) := (Q_DIFF => 2, NC => 2, V_DIFF => 20);
      Check (TD.Train_Speed (Basic, 1, D, C) = 2_777,
             "SSP category: an other specific category of the train that "
             & "does not replace, the lowest (3.11.3.2.6)");
      D (1) := (Q_DIFF => 1, NC => 2, V_DIFF => 32);
      Check (TD.Train_Speed (Basic, 1, D, C) = 4_444,
             "SSP category: an other specific category that replaces");
      D (1) := (Q_DIFF => 1, NC => 0, V_DIFF => 10);
      Check (TD.Train_Speed (Basic, 1, D, C) = 3_888,
             "SSP category: other categories of other trains ignored "
             & "(3.11.3.2.5)");
   end Scenario_SSP_Categories;

   --  3.11.3, 3.11.12, 3.6.4.2.3: the SSP and the gradients of a group
   --  as offsets from its location reference, in the frame; the MRSP
   --  with the train length delay (3.11.3.1.3), the gradient profile
   procedure Scenario_SSP_Gradients is
      S : Prof.Store_T := TD.SSP;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, True), 2 => (1000, 80, True),
                         3 => (500, 120, False))));
      Carry (1, 1, Grad ((1 => (0, 5), 2 => (2000, -3))));
      Run_X (15_000);
      S := TD.SSP;
      Check (SI.Messages = 1 and then S.Count = 3
             and then TD.Gradients.Count = 2,
             "SSP: three elements and two gradients stored");
      Check (Est (S.List (1).Start) = 10_000
             and then Est (S.List (2).Start) = 110_000
             and then Est (S.List (3).Start) = 160_000
             and then S.List (3).Open
             and then Min_X (S.List (2).Start) = 110_000
             and then Max_X (S.List (2).Start) = 110_000,
             "SSP: the element starts at the offsets from the location "
             & "reference in the frame (3.6.4.2.3), items equal");
      Check (MRSP_Is ((0, 10_000, 110_000, 180_000),
                      (4_444, 2_777, 2_222, 3_333)),
             "MRSP: V_MAXTRAIN, then the SSP, 80 km/h up to its end plus "
             & "the train length (3.11.3.1.3, 3.13.7)");
      Check (SI.Current.Gradients.Count = 3
             and then SI.Current.Gradients.Segments (2).Start = 10_000
             and then SI.Current.Gradients.Segments (2).Gradient = 5
             and then SI.Current.Gradients.Segments (3).Start = 210_000
             and then SI.Current.Gradients.Segments (3).Gradient = -3,
             "gradients: the profile in the frame (3.11.12)");
      --  phase E4: Supervise is the mode's (FS, valid Train Data), the
      --  MA is not there
      Check (not SI.Current.MA.Present and then SI.Current.Supervise
             and then Plan_Frames = 0,
             "no MA: no MA supervised, no planning");
      Check (SI_Seen (SI.Info_SSP, SI.Change_Stored) = 1
             and then SI_Seen (SI.Info_Gradients, SI.Change_Stored) = 1,
             "JRU: SSP and gradients stored");
      Check (MRSP_Below_Sources,
             "MRSP: sorted, never above a source (proved; checked)");
      Check (SI.Current.Train.Position_Valid
             and then SI.Current.Train.Ahead = EVC_Distances.Plus
             and then Integer_64 (SI.Current.Train.Est_Front) = 15_300,
             "snapshot: the train, the estimated front end in the frame");
   end Scenario_SSP_Gradients;

   --  3.7.3.1 a): a new SSP replaces the stored one from its start; the
   --  relocation by travelled distance (3.6.4.2.5 c, no linking) widens
   --  the min and max items of the older one
   procedure Scenario_SSP_Replacement is
      S : Prof.Store_T := TD.SSP;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 600));
      Carry (1, 0, SSP ((1 => (0, 100, True), 2 => (1000, 80, True),
                         3 => (500, 120, False))));
      Carry (2, 0, SSP ((1 => (200, 60, False))));
      Run_X (65_000);
      S := TD.SSP;
      Check (SI.Messages = 2 and then S.Count = 2
             and then Est (S.List (1).Finish) = 80_000
             and then not S.List (1).Open
             and then Est (S.List (2).Start) = 80_000 and then S.List (2).Open,
             "SSP replaced from the start of the new one (3.7.3.1 a)");
      Check (Max_X (S.List (1).Start) < Est (S.List (1).Start)
             and then Min_X (S.List (1).Start) > Est (S.List (1).Start)
             and then Max_X (S.List (2).Start) = Est (S.List (2).Start),
             "SSP: relocated by the travelled distance, the max and min "
             & "items of the older one apart (3.6.4.2.5 c)");
      Check (SI.Current.MRSP.Count = 3
             and then Integer_64 (SI.Current.MRSP.Segments (2).Start)
                        = Max_X (S.List (1).Start)
             and then SI.Current.MRSP.Segments (2).Speed = 2_777
             and then SI.Current.MRSP.Segments (3).Start = 80_000
             and then SI.Current.MRSP.Segments (3).Speed = 1_666,
             "MRSP: the older SSP from its max item, the new one from its "
             & "start");
      Check (MRSP_Below_Sources, "MRSP below its sources after relocation");
   end Scenario_SSP_Replacement;

   --  3.11.5: TSRs by identity, non revocable ones, revocation without
   --  train length delay, deletion with the orientation (3.11.5.10)
   procedure Scenario_TSR is
      function TSR_At (Id : Natural; D_M, L_M, Kmh : Natural;
                       Delay_L : Boolean) return T65.Packet_T
      is
         P : T65.Packet_T;
      begin
         P.Q_DIR := 1;
         P.Q_SCALE := 1;
         P.NID_TSR := ETCS_Variables.NID_TSR_T (Id);
         P.D_TSR := ETCS_Variables.D_TSR_T (D_M);
         P.L_TSR := ETCS_Variables.L_TSR_T (L_M);
         P.Q_FRONT := (if Delay_L then 0 else 1);
         P.V_TSR := ETCS_Variables.V_TSR_T (Kmh / 5);
         return P;
      end TSR_At;
      Revoke : T66.Packet_T;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 200));
      Add_Group (Group (30, 300));
      Add_Group (Group (40, 350));
      Carry (1, 0, SSP ((1 => (0, 160, False))));
      Carry (1, 0, TSR_At (5, 300, 100, 40, True));
      Carry (1, 1, TSR_At (255, 600, 50, 60, False));
      Carry (1, 1, TSR_At (255, 700, 20, 30, False));
      Run_X (15_000);
      Check (TD.TSR.Count = 3, "TSR: three stored");
      Check (SI.Current.MRSP.Segments (2).Start = 40_000
             and then SI.Current.MRSP.Segments (2).Speed = 1_111
             and then SI.Current.MRSP.Segments (3).Start = 70_000
             and then SI.Current.MRSP.Segments (3).Speed = 1_666
             and then SI.Current.MRSP.Segments (4).Start = 75_000
             and then SI.Current.MRSP.Segments (5).Start = 80_000
             and then SI.Current.MRSP.Segments (5).Speed = 833
             and then SI.Current.MRSP.Segments (6).Start = 82_000,
             "TSR: in the MRSP, the delayed one to its end plus the train "
             & "length (3.11.5.3)");
      Check (not SI.Current.MRSP.TSR (1) and then SI.Current.MRSP.TSR (2)
             and then SI.Current.MRSP.TSR (3)
             and then not SI.Current.MRSP.TSR (4)
             and then SI.Current.MRSP.TSR (5)
             and then not SI.Current.MRSP.TSR (6),
             "TSR: the MRSP segments due to a TSR flagged for the default "
             & "gradient of the supervision (3.13.4.1.3 a)");
      --  the same identity again, elsewhere (3.11.5.9)
      Revoke.Q_DIR := 1;
      Revoke.NID_TSR := 5;
      Carry (2, 0, TSR_At (5, 50, 20, 70, False));
      Carry (3, 0, Revoke);
      Revoke.NID_TSR := 255;
      Carry (4, 0, Revoke);
      Run_X (25_000);
      Check (TD.TSR.Count = 3 and then Est (TD.TSR.List (3).Start) = 25_000
             and then TD.TSR.List (3).Id = 5,
             "TSR: the one of the same identity replaced (3.11.5.9)");
      Run_X (32_000);
      Check (TD.TSR.Count = 2
             and then SI_Seen (SI.Info_TSR, SI.Change_Deleted) = 1
             and then SI_Detail (SI.Info_TSR, SI.Change_Deleted) = 5,
             "TSR: revoked at once by its identity (3.11.5.5)");
      Run_X (37_000);
      Check (TD.TSR.Count = 2,
             "TSR: a non revocable one is not revoked (3.11.5.8, 7.5.1.99)");
      Check (MRSP_Below_Sources, "MRSP below its sources with TSRs");
      --  the orientation changes: every TSR goes (3.11.5.10)
      Input (TIU, (1, 0));
      Input (TIU, (2, 1));
      Stand;
      Collect_E3;
      Check (TD.TSR.Count = 0
             and then SI_Seen (SI.Info_TSR, SI.Change_Orientation) = 1,
             "TSR: deleted when the orientation changes (3.11.5.10)");
   end Scenario_TSR;

   --  3.8.3, 3.8.4.5, 3.7.2.3: an MA of level 1 accepted when the SSP
   --  and the gradients cover it, its EOA, SvL and release speed in the
   --  frame; the planning to the DMI
   procedure Scenario_MA is
      M : T12.Packet_T := MA_Of ((300, 400));
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 200));
      --  no gradient: the MA is not accepted (3.7.2.3)
      Carry (1, 0, SSP ((1 => (0, 100, True))));
      Carry (1, 1, M);
      M.Q_DANGERPOINT := 1;
      M.Has_D_DP := True;
      M.D_DP := 50;
      M.V_RELEASEDP := 8;
      M.Q_OVERLAP := 1;
      M.Has_D_STARTOL := True;
      M.D_STARTOL := 150;
      M.T_OL := 30;
      M.D_OL := 100;
      M.V_RELEASEOL := 6;
      Carry (2, 0, SSP ((1 => (0, 100, True))));
      Carry (2, 0, Grad ((1 => (0, 0))));
      Carry (2, 1, M);
      Run_X (11_000);
      Check (not SI.Current.MA.Present
             and then SI_Seen (SI.Info_MA, SI.Change_Rejected) = 1
             and then SI_Seen (SI.Info_Signalling_Speed, SI.Change_Stored)
                        = 1,
             "MA: not accepted, the gradients do not cover it (3.7.2.3); "
             & "its V_MAIN is (3.11.6.2)");
      Run_X (21_000);
      Check (SI.Current.MA.Present and then SI.Current.Supervise
             and then SI.Current.MA.EOA = 90_000
             and then SI.Current.MA.SvL = 100_000
             and then SI.Current.MA.LOA_Speed = 0
             and then SI.Current.MA.Release_Speed.Kind = SIn.Fixed
             and then SI.Current.MA.Release_Speed.Speed = 833,
             "MA: EOA at the end of the End Section, SvL the end of the "
             & "overlap with its release speed (3.8.4.5.1 a)");
      Check (MAu.MA.Count = 2 and then MAu.V_Main = 3_333,
             "MA: two sections, V_MAIN 120 km/h");
      Check (SI.Current.MRSP.Count = 2
             and then SI.Current.MRSP.Segments (1).Speed = 3_333
             and then SI.Current.MRSP.Segments (2).Speed = 2_777,
             "MRSP: the signalling related speed restriction from its "
             & "reception, under V_MAXTRAIN (3.11.6.2, 3.11.8)");
      Check (Plan_Frames > 0 and then Plan_U16 (0) = (90_000 - 21_300) / 100
             and then Plan_U16 (2) = 16#FFFF#
             and then Plan_U16 (6) = 100
             and then Natural (Plan_Payload (9)) = 1      -- gradients
             and then Plan_U16 (9) = 0
             and then Natural (Plan_Payload (12)) = 0
             and then Natural (Plan_Payload (13)) = 1     -- speeds: the EOA
             and then Plan_U16 (13) = 687
             and then Plan_U16 (15) = 0
             and then Natural (Plan_Payload (18)) = 0,    -- orders
             "planning: the EOA, the ceiling speed, the gradient, the EOA "
             & "as a zero target (DMI 8.3)");
      Check_Golden ("profiles_ma_planning");
      Check (MRSP_Below_Sources, "MRSP below its sources with an MA");
   end Scenario_MA;

   --  3.8.4.2: a section time-out withdraws the EOA to the entry of the
   --  section, the national release speed applies, the information
   --  beyond is deleted (A.3.4.1.3 [1])
   procedure Scenario_Section_Timer is
      M : T12.Packet_T := MA_Of ((300, 400));
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      M.L_ENDSECTION := 400;
      M.Q_SECTIONTIMER := 1;
      M.Has_T_SECTIONTIMER := True;
      M.T_SECTIONTIMER := 20;
      M.D_SECTIONTIMERSTOPLOC := 50;
      Carry (1, 1, M);
      Run_X (15_000);
      Check (SI.Current.MA.EOA = 80_000
             and then SI.Current.MA.Release_Speed.Kind = SIn.None,
             "section timer: the MA, no release speed at the end of the "
             & "End Section (3.13.9.4.4)");
      Stand_X (19_000);
      Check (SI.Current.MA.EOA = 80_000, "section timer: running");
      Stand_X (2_000);
      Check (SI.Current.MA.EOA = 40_000 and then SI.Current.MA.SvL = 40_000
             and then SI.Current.MA.Release_Speed.Kind = SIn.Fixed
             and then SI.Current.MA.Release_Speed.Speed = 1_111
             and then SI_Seen (SI.Info_MA, SI.Change_Section) = 1
             and then SI_Detail (SI.Info_MA, SI.Change_Section) = 2,
             "section timer over: EOA and SvL at the entry of the section, "
             & "the national release speed (3.8.4.2.2)");
      Check (TD.SSP.Count = 1 and then not TD.SSP.List (1).Open
             and then Est (TD.SSP.List (1).Finish) = 40_000,
             "section timer over: the SSP deleted beyond the new SvL "
             & "(A.3.4.1.3 [1])");
   end Scenario_Section_Timer;

   --  3.8.4.2.3: a section timer stops when the min safe front end
   --  passes its stop location
   procedure Scenario_Section_Timer_Stopped is
      M : T12.Packet_T := MA_Of ((300, 400));
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      M.L_SECTION_List (1).Q_SECTIONTIMER := 1;
      M.L_SECTION_List (1).Has_T_SECTIONTIMER := True;
      M.L_SECTION_List (1).T_SECTIONTIMER := 10;
      M.L_SECTION_List (1).D_SECTIONTIMERSTOPLOC := 100;
      Carry (1, 1, M);
      Run_X (25_000);
      Check (MAu.MA.Sections (1).Stopped,
             "section timer stopped by the min safe front end (3.8.4.2.3)");
      Stand_X (15_000);
      Check (SI.Current.MA.EOA = 80_000
             and then SI_Seen (SI.Info_MA, SI.Change_Section) = 0,
             "section timer stopped: no time-out");
      --  back in rear of the stop location, then standstill
      Run_X (17_000);
      Check (SI.Current.MA.EOA = 80_000,
             "section timer: moving back, nothing before the standstill");
      Stand;
      Collect_E3;
      Check (SI.Current.MA.EOA = 10_000
             and then SI_Seen (SI.Info_MA, SI.Change_Section) = 1
             and then SI_Detail (SI.Info_MA, SI.Change_Section) = 1,
             "section timer: back in rear of its stop location at "
             & "standstill, timed out (3.8.4.2.4)");
   end Scenario_Section_Timer_Stopped;

   --  3.8.4.4: the overlap timer starts with the max safe front end at
   --  its start location; a standstill after it (3.8.4.4.3) deletes the
   --  overlap: the SvL is the danger point with its release speed
   procedure Scenario_Overlap_Timer is
      M : T12.Packet_T := MA_Of ((700, 100));
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      M.Q_DANGERPOINT := 1;
      M.Has_D_DP := True;
      M.D_DP := 50;
      M.V_RELEASEDP := 126;
      M.Q_OVERLAP := 1;
      M.Has_D_STARTOL := True;
      M.D_STARTOL := 300;
      M.T_OL := 1023;
      M.D_OL := 100;
      M.V_RELEASEOL := 127;
      Carry (1, 1, M);
      Run_X (40_000);
      Check (SI.Current.MA.SvL = 100_000
             and then SI.Current.MA.Release_Speed.Kind = SIn.Fixed
             and then SI.Current.MA.Release_Speed.Speed = 1_111
             and then not MAu.MA.OL_Timer.Running,
             "overlap: the SvL, the national release speed (V_RELEASEOL "
             & "127), the timer not started");
      Run_X (60_000);
      Check (MAu.MA.OL_Timer.Running and then MAu.MA.Has_OL,
             "overlap timer started by the max safe front end (3.8.4.4.1)");
      Stand;
      Collect_E3;
      Check (not MAu.MA.Has_OL
             and then SI.Current.MA.SvL = 95_000
             and then SI.Current.MA.Release_Speed.Kind
                        = SIn.Calculated_On_Board
             and then SI_Seen (SI.Info_MA, SI.Change_Overlap) = 1,
             "overlap deleted at standstill even with an infinite time-out "
             & "(3.8.4.4.3): the danger point is the SvL (3.8.4.5.1 b)");
   end Scenario_Overlap_Timer;

   --  3.8.4.1: the End Section timer, and its time-out withdrawing the
   --  EOA to the train (A.3.4.1.3 [11]) with the deletion beyond the max
   --  safe front end [10]
   procedure Scenario_End_Section_Timer is
      M       : T12.Packet_T := MA_Of ((300, 400));
      Started : Unsigned_64;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 530));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      M.Q_ENDTIMER := 1;
      M.Has_T_ENDTIMER := True;
      M.T_ENDTIMER := 5;
      M.D_ENDTIMERSTARTLOC := 300;
      Carry (1, 1, M);
      --  the same MA again from a group beyond the start location
      M.N_ITER := 0;
      M.L_ENDSECTION := 270;
      Carry (2, 1, M);
      Run_X (45_000);
      Check (not MAu.MA.End_Timer.Running,
             "End Section timer: not started before its start location");
      Run_X (52_000);
      Check (MAu.MA.End_Timer.Running,
             "End Section timer started by the max safe front end "
             & "(3.8.4.1.1)");
      Started := MAu.MA.End_Timer.Started;
      Run_X (55_000);
      Check (SI_Seen (SI.Info_MA, SI.Change_Stored) = 2
             and then MAu.MA.End_Timer.Running
             and then MAu.MA.End_Timer.Started = Started
             and then MAu.MA.Msg = 2,
             "End Section timer: a new MA with its start location passed "
             & "keeps it running (3.8.4.1.4)");
      Stand_X (6_000);
      Check (MAu.MA.Withdrawn
             and then Integer_64 (SI.Current.MA.EOA) = 55_300
             and then SI.Current.MA.SvL
                        = SI.Current.Train.Max_Safe_Front
             and then SI.Current.MA.Release_Speed.Kind = SIn.None
             and then SI_Seen (SI.Info_MA, SI.Change_End) = 1,
             "End Section time-out: EOA at the estimated front end, SvL at "
             & "the max safe front end, no release speed (3.8.4.1.2, "
             & "A.3.4.1.3 [11])");
      Check (TD.SSP.Count = 1 and then not TD.SSP.List (1).Open
             and then Est (TD.SSP.List (1).Finish)
                        = Integer_64 (SI.Current.MA.SvL),
             "End Section time-out: the SSP deleted beyond the max safe "
             & "front end (A.3.4.1.3 [10])");
   end Scenario_End_Section_Timer;

   --  3.8.4.3: the LOA speed timer; 3.8.4.1.3: an End Section timer
   --  start location already passed when the MA is received
   procedure Scenario_LOA_Timer is
      M : T12.Packet_T := MA_Of ((500, 300));
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      M.V_EMA := 8;
      M.T_EMA := 5;
      Carry (1, 1, M);
      Run_X (15_000);
      Check (SI.Current.MA.LOA_Speed = 1_111
             and then SI.Current.MA.Release_Speed.Kind = SIn.None
             and then SI.Current.MA.SvL = SI.Current.MA.EOA,
             "LOA: the target speed, no SvL and no release speed "
             & "(3.8.4.5.2, 3.13.9.4.4)");
      Stand_X (6_000);
      Check (SI.Current.MA.LOA_Speed = 0
             and then SI_Seen (SI.Info_MA, SI.Change_LOA) = 1,
             "LOA speed time-out: the LOA becomes an EOA (3.8.4.3.2)");

      Start_X;
      Add_Group (Group (10, 100));
      M := MA_Of ((300, 400));
      M.Q_ENDTIMER := 1;
      M.Has_T_ENDTIMER := True;
      M.T_ENDTIMER := 60;
      M.D_ENDTIMERSTARTLOC := 700;
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 1, M);
      Run_X (15_000);
      --  phase E4: the train is beyond the EOA the time-out withdrew it
      --  to, so it trips (4.6.3 [12]) and the trip deletes the MA (4.10)
      Check ((MAu.MA.Withdrawn or else EVC_Core.Mode = M_TR)
             and then SI_Seen (SI.Info_MA, SI.Change_End) = 1,
             "End Section timer start location passed at reception: over "
             & "at once (3.8.4.1.3); beyond the EOA withdrawn, a trip "
             & "(4.6.3 [12], phase E4)");

      Start_X;
      Add_Group (Group (10, 100));
      M := MA_Of ((300, 400));
      M.Q_OVERLAP := 1;
      M.Has_D_STARTOL := True;
      M.D_STARTOL := 750;
      M.T_OL := 60;
      M.D_OL := 100;
      M.V_RELEASEOL := 4;
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 1, M);
      Run_X (15_000);
      Check (not MAu.MA.Has_OL and then SI.Current.MA.SvL = 80_000
             and then SI_Seen (SI.Info_MA, SI.Change_Overlap) = 1,
             "Overlap timer start location passed at reception: over at "
             & "once, the SvL at the EOA (3.8.4.4.4)");
   end Scenario_LOA_Timer;

   --  3.8.5.1.3, A.3.4.1.3 [1], 3.8.5.1.5: a shortened MA deletes the
   --  information stored before it beyond its SvL, not what came with it
   procedure Scenario_MA_Shortening is
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 300));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 1, MA_Of ((300, 400)));
      Carry (2, 0, Grad ((1 => (0, 2), 2 => (1000, End_Mark))));
      Carry (2, 1, MA_Of ((1 => 200)));
      Run_X (15_000);
      Check (SI.Current.MA.EOA = 80_000, "shortening: the first MA");
      Run_X (31_000);
      Check (SI.Current.MA.EOA = 50_000
             and then SI_Seen (SI.Info_MA, SI.Change_Shortened) = 1,
             "shortening: a closer SvL (3.8.5.1.3)");
      Check (TD.SSP.Count = 1 and then not TD.SSP.List (1).Open
             and then Est (TD.SSP.List (1).Finish) = 50_000,
             "shortening: the SSP stored before deleted beyond the SvL "
             & "(A.3.4.1.3 [1])");
      Check (TD.Gradients.Count = 2
             and then Est (TD.Gradients.List (2).Finish) = 130_000,
             "shortening: the gradients of the same message kept "
             & "(3.8.5.1.5)");
   end Scenario_MA_Shortening;

   --  3.18.2: national values, now or at a location, the countries;
   --  A.3.2 defaults; the packet converted
   procedure Scenario_National_Values is
      P : T3.Packet_T;
      S : NVa.Set_T;
   begin
      P.Q_DIR := 2;
      P.Q_SCALE := 1;
      P.D_VALIDNV := 32_767;
      P.NID_C := 123;
      P.N_ITER := 1;
      P.NID_C_List (1) := 124;
      P.V_NVSHUNT := 8;
      P.V_NVSTFF := 8;
      P.V_NVONSIGHT := 6;
      P.V_NVLIMSUPERV := 20;
      P.V_NVUNFIT := 20;
      P.V_NVREL := 10;
      P.D_NVROLL := 5;
      P.Q_NVSBTSMPERM := 1;
      P.Q_NVEMRRLS := 1;
      P.Q_NVGUIPERM := 1;
      P.V_NVALLOWOVTRP := 2;
      P.V_NVSUPOVTRP := 6;
      P.D_NVOVTRP := 200;
      P.T_NVOVTRP := 60;
      P.D_NVPOTRP := 200;
      P.M_NVCONTACT := 1;
      P.T_NVCONTACT := 30;
      P.M_NVDERUN := 1;
      P.D_NVSTFF := 32_767;
      P.Q_NVDRIVER_ADHES := 1;
      P.A_NVMAXREDADH1 := 20;
      P.A_NVMAXREDADH2 := 63;
      P.A_NVMAXREDADH3 := 14;
      P.Q_NVLOCACC := 10;
      P.M_NVAVADH := 10;
      P.M_NVEBCL := 5;
      P.Q_NVKINT := 1;
      P.Has_Q_NVKVINTSET := True;
      P.Q_NVKVINTSET := 1;
      P.Has_A_NVP12 := True;
      P.A_NVP12 := 16;
      P.A_NVP23 := 20;
      P.V_NVKVINT := 0;
      P.M_NVKVINT := 35;
      P.Has_M_NVKVINT_2 := True;
      P.M_NVKVINT_2 := 40;
      P.N_ITER_2 := 1;
      P.V_NVKVINT_List (1) :=
        (V_NVKVINT => 20, M_NVKVINT => 30, Has_M_NVKVINT_2 => True,
         M_NVKVINT_2 => 35);
      P.N_ITER_3 := 1;
      P.Q_NVKVINTSET_List (1).Q_NVKVINTSET := 0;
      P.Q_NVKVINTSET_List (1).V_NVKVINT := 0;
      P.Q_NVKVINTSET_List (1).M_NVKVINT := 45;
      P.L_NVKRINT := 4;
      P.M_NVKRINT := 18;
      P.N_ITER_4 := 1;
      P.L_NVKRINT_List (1) := (L_NVKRINT => 7, M_NVKRINT => 16);
      P.M_NVKTINT := 22;
      S := NVa.From_Packet (P);
      Check (S.Values.V_NVSHUNT = 1_111 and then S.Values.V_NVREL = 1_388
             and then S.Values.D_NVROLL = 500
             and then S.Values.Q_NVEMRRLS and then S.Values.Q_NVGUIPERM
             and then S.Values.T_NVOVTRP = 60_000
             and then S.Values.D_NVSTFF = EVC_Distances.Max_Cm
             and then S.Values.A_NVMAXREDADH1 = 1_000
             and then S.Values.A_NVMAXREDADH2 = SIn.Decel_Mms2_T'Last
             and then S.Values.M_NVAVADH = 500
             and then S.Values.M_NVEBCL = 5
             and then S.Q_NVLOCACC = 1_000
             and then S.M_NVCONTACT = 1 and then S.T_NVCONTACT = 30_000
             and then S.Country_Count = 2 and then S.Countries (2) = 124,
             "national values: the packet in on-board units");
      Check (S.Redadh_Use (1) = SIn.Limit
             and then S.Redadh_Use (2) = SIn.No_Limit
             and then S.Redadh_Use (3) = SIn.Limit,
             "national values: A_NVMAXREDADH2 = 63, no maximum deceleration "
             & "and no more display (7.5.0.2), kept for the supervision");
      Check (S.Values.Kv_Int_Passenger.Count = 2
             and then S.Values.Kv_Int_Passenger.Steps (1).Factor = 700
             and then S.Values.Kv_Int_Passenger.Steps (2) = (2_777, 600)
             and then S.Values.Kv_Int_Passenger_B.Steps (1).Factor = 800
             and then S.Values.Kv_Int_Passenger_B.Steps (2).Factor = 700
             and then S.Values.Kv_Int_Fresh.Steps (1).Factor = 900
             and then S.Values.A_NVP12 = 800 and then S.Values.A_NVP23 = 1_000
             and then S.Values.Kr_Int.Count = 2
             and then S.Values.Kr_Int.Steps (1) = (10_000, 900)
             and then S.Values.Kr_Int.Steps (2) = (30_000, 800)
             and then S.Values.Kt_Int = 1_100,
             "national values: the integrated correction factors");

      Start_X;
      Check (SI.Current.National = NVa.Default_Values
             and then Onboard_Field (5) / 2 mod 2 = 0,
             "national values: the defaults of A.3.2 at power-up");
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 200));
      Add_Group (Group (30, 600));
      Add_Group (Group (40, 700));
      Carry (1, 0, P);
      P.D_VALIDNV := 200;
      P.V_NVREL := 12;
      Carry (2, 0, P);
      Country (4) := 200;
      Run_X (15_000);
      Check (SI.Current.National.V_NVREL = 1_388
             and then Onboard_Field (5) / 2 mod 2 = 1,
             "national values: applicable at once (D_VALIDNV now), the "
             & "driver's adhesion on the DMI");
      Check (SI.Current.Extra.National.Redadh_Use (2) = SIn.No_Limit
             and then SI.Current.Extra.National.Redadh_Use (1) = SIn.Limit,
             "snapshot: the use of A_NVMAXREDADHn from the national values "
             & "in use (3.13.6.2.1.6)");
      Run_X (35_000);
      Check (SI.Current.National.V_NVREL = 1_388 and then NVa.Pending,
             "national values: waiting for their location (3.18.2.3)");
      Run_X (40_500);
      Check (SI.Current.National.V_NVREL = 1_666 and then not NVa.Pending
             and then SI_Seen (SI.Info_National_Values,
                               SI.Change_Applicable) = 1,
             "national values: applicable when the estimated front end "
             & "reaches D_VALIDNV (3.18.2.3)");
      Run_X (65_000);
      Check (SI.Current.National.V_NVREL = 1_666,
             "national values: a group of a country of the set (124... "
             & "123) changes nothing");
      Run_X (75_000);
      Check (SI.Current.National = NVa.Default_Values
             and then SI_Seen (SI.Info_National_Values,
                               SI.Change_Defaults) = 1,
             "national values: a group of another country, the defaults "
             & "(3.18.2.5, 3.18.2.10)");
   end Scenario_National_Values;

   --  3.12.1, 5.18: track conditions stored, indicated on the DMI
   --  (MSG_TRACK_COND), in the planning, and the braking areas
   procedure Scenario_Track_Conditions is
      C  : T68.Packet_T;
      Tr : T39.Packet_T;
      B  : T67.Packet_T;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      C.Q_DIR := 1;
      C.Q_SCALE := 1;
      C.Q_TRACKINIT := 0;
      C.Has_D_TRACKCOND := True;
      C.D_TRACKCOND := 1000;      -- 1100 m
      C.L_TRACKCOND := 200;
      C.M_TRACKCOND := 3;         -- powerless section, lower pantograph
      C.N_ITER := 1;
      C.D_TRACKCOND_List (1) :=
        (D_TRACKCOND => 1300, L_TRACKCOND => 100, M_TRACKCOND => 6);
      Tr.Q_DIR := 1;
      Tr.Q_SCALE := 1;
      Tr.D_TRACTION := 1500;      -- 1600 m
      Tr.M_VOLTAGE := 3;
      Tr.Has_NID_CTRACTION := True;
      Tr.NID_CTRACTION := 7;
      B.Q_DIR := 1;
      B.Q_SCALE := 1;
      B.D_TRACKCOND := 300;
      B.L_TRACKCOND := 50;
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 0, C);
      Carry (1, 1, MA_Of ((1 => 3000)));
      Carry (1, 1, Tr);
      Carry (1, 1, B);
      Run_X (15_000);
      Check (TCo.Conditions.Count = 2 and then TCo.Traction_Changes.Count = 1
             and then TCo.Big_Metal_Masses.Count = 1
             and then Est (TCo.Conditions.List (2).Start) = 240_000
             and then TCo.Traction_Changes.List (1).Value = 3 * 1_024 + 7,
             "track conditions: stored (3.12.1)");
      Check (TC_Frames = 0, "track conditions: nothing indicated yet");
      Check (SI.Current.Inhibitions.Count = 2
             and then SI.Current.Inhibitions.Areas (1).Kind
                        = SIn.Powerless_Section
             and then SI.Current.Inhibitions.Areas (1).Start = 110_000
             and then SI.Current.Inhibitions.Areas (1).Finish = 150_000
             and then SI.Current.Inhibitions.Areas (2).Kind
                        = SIn.Regenerative_Inhibited
             and then SI.Current.Inhibitions.Areas (2).Start = 240_000,
             "track conditions: the powerless section and the area without "
             & "regenerative brake, to their end plus the train length "
             & "(3.13.2.3.4)");
      Check (Natural (Plan_Payload (13)) = 1
             and then Natural (Plan_Payload (18)) = 4
             and then Natural (Plan_Payload (19)) = 2
             and then Plan_U16 (19) = (110_000 - 15_300) / 100,
             "planning: the orders of the track conditions ahead (lower "
             & "and raise pantograph, regenerative brake, DC 3 kV)");
      Run_X (100_000, 1000);
      Check (TC_Shows (3), "5.18.2.2: lower pantograph announced (TC03)");
      Run_X (112_000, 1000);
      Check (TC_Shows (1) and then not TC_Shows (3),
             "5.18.2.3: pantograph lowered (TC01)");
      Run_X (135_000, 1000);
      Check (TC_Shows (5), "5.18.2.5: raise pantograph (TC05)");
      Run_X (160_000, 1000);
      Stand_X (6_000);
      Check (not TC_Shows (5),
             "5.18.2.6: raise pantograph removed 5 s after the rear end");
      Check (TC_Shows (30) or else TC_Shows (29),
             "5.18.10: the change of traction system (TC30, TC29)");
      Run_X (200_000, 1000);
      Stand_X (6_000);
      Check (not TC_Shows (29) and then not TC_Shows (30),
             "5.18.10.6: the new traction system removed 5 s after the "
             & "rear end");
      Run_X (232_000, 1000);
      Check (TC_Shows (18),
             "5.18.7.3: inhibition of the regenerative brake announced");
      Run_X (250_000, 1000);
      Check (TC_Shows (17), "5.18.7.4: regenerative brake inhibited");
      Check_Golden ("profiles_track_conditions");
   end Scenario_Track_Conditions;

   --  3.12.2, 3.12.4, 3.12.5, 3.11.4, 3.13.2.3.5, 3.11.12.5: route
   --  suitability, mode profile, level crossing, ASP, adhesion, default
   --  gradient for TSR
   procedure Scenario_Other_Profiles is
      RS : T70.Packet_T;
      MP : T80.Packet_T;
      LX : T88.Packet_T;
      AS : T51.Packet_T;
      AD : T71.Packet_T;
      DG : T141.Packet_T;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 200));
      RS.Q_DIR := 1;
      RS.Q_SCALE := 1;
      RS.Has_D_SUITABILITY := True;
      RS.D_SUITABILITY := 500;
      RS.Q_SUITABILITY := 0;
      RS.Has_M_LINEGAUGE := True;
      RS.M_LINEGAUGE := 3;
      RS.N_ITER := 1;
      RS.D_SUITABILITY_List (1).D_SUITABILITY := 300;
      RS.D_SUITABILITY_List (1).Q_SUITABILITY := 1;
      RS.D_SUITABILITY_List (1).Has_M_LINEAXLELOADCAT := True;
      RS.D_SUITABILITY_List (1).M_LINEAXLELOADCAT := 16#0101#;
      MP.Q_DIR := 1;
      MP.Q_SCALE := 1;
      MP.D_MAMODE := 900;
      MP.M_MAMODE := 0;
      MP.V_MAMODE := 127;
      MP.L_MAMODE := 200;
      MP.L_ACKMAMODE := 100;
      MP.Q_MAMODE := 1;
      LX.Q_DIR := 1;
      LX.Q_SCALE := 1;
      LX.NID_LX := 3;
      LX.D_LX := 400;
      LX.L_LX := 20;
      LX.Q_LXSTATUS := 1;
      LX.Has_V_LX := True;
      LX.V_LX := 4;
      LX.Q_STOPLX := 1;
      LX.Has_L_STOPLX := True;
      LX.L_STOPLX := 30;
      AS.Q_DIR := 1;
      AS.Q_SCALE := 1;
      AS.Q_TRACKINIT := 0;
      AS.Has_D_AXLELOAD := True;
      AS.D_AXLELOAD := 200;
      AS.L_AXLELOAD := 100;
      AS.Q_FRONT := 1;
      AS.N_ITER := 2;
      AS.M_AXLELOADCAT_List (1) := (M_AXLELOADCAT => 0, V_AXLELOAD => 12);
      AS.M_AXLELOADCAT_List (2) := (M_AXLELOADCAT => 4, V_AXLELOAD => 8);
      AS.N_ITER_2 := 1;
      AS.D_AXLELOAD_List (1).D_AXLELOAD := 300;
      AS.D_AXLELOAD_List (1).L_AXLELOAD := 100;
      AS.D_AXLELOAD_List (1).N_ITER := 1;
      AS.D_AXLELOAD_List (1).M_AXLELOADCAT_List (1) :=
        (M_AXLELOADCAT => 4, V_AXLELOAD => 6);
      AD.Q_DIR := 1;
      AD.Q_SCALE := 1;
      AD.D_ADHESION := 100;
      AD.L_ADHESION := 300;
      AD.M_ADHESION := 0;
      DG.Q_DIR := 1;
      DG.Q_GDIR := 0;
      DG.G_TSR := 7;
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, RS);
      Carry (1, 0, LX);
      Carry (1, 1, AS);
      Carry (1, 1, AD);
      Carry (1, 1, DG);
      Carry (1, 1, MP);           -- no MA in the message: ignored
      Run_X (15_000);
      Check (TD.Suitability (1).Used and then TD.Suitability (2).Used
             and then TD.Suitability (1).Kind = 0
             and then TD.Suitability (2).Kind = 1
             and then TD.Suitability (2).Value = 16#0101#
             and then Est (TD.Suitability (2).At_Loc) = 90_000,
             "route suitability: stored (3.12.2; the check is E4/E6)");
      Check (not MAu.Mode_Profiles (1).Used,
             "mode profile: not taken without its MA (3.7.1.1 b)");
      Check (TD.LX (1).Used and then not TD.LX (1).Protected_LX
             and then TD.LX (1).Speed = 555 and then TD.LX (1).Stop_Required,
             "level crossing: stored (3.12.5)");
      Check (TD.ASP.Count = 1 and then Est (TD.ASP.List (1).Start) = 30_000
             and then TD.ASP.List (1).Value = 1_666,
             "ASP: the speed of the train's axle load category "
             & "(3.11.4.3), nothing where it is not listed");
      Check (SI.Current.Adhesion.Count = 1
             and then SI.Current.Adhesion.Areas (1).Start = 20_000
             and then SI.Current.Adhesion.Areas (1).Finish = 50_000,
             "adhesion: a slippery rail area (3.13.2.3.5)");
      Check (SI.Current.Gradients.Count = 1
             and then not SI.Current.Gradients.Covered (1)
             and then SI.Current.Gradients.Segments (1).Gradient = 0
             and then SI.Current.Gradients.Has_Default_TSR
             and then SI.Current.Gradients.Default_TSR = -7,
             "default gradient for TSR where no gradient is known "
             & "(3.11.12.5), for the targets due to a TSR (3.13.4.1.3)");
      Check (SI.Current.MRSP.Segments (2).Start = 10_000
             and then SI.Current.MRSP.Segments (3).Start = 30_000
             and then SI.Current.MRSP.Segments (3).Speed = 1_666
             and then SI.Current.MRSP.Segments (5).Start = 50_000
             and then SI.Current.MRSP.Segments (5).Speed = 555
             and then SI.Current.MRSP.Segments (6).Start = 52_000,
             "MRSP: the ASP and the LX speed restriction (3.11.9)");
      Check (SI.Current.Temporary.Present
             and then SI.Current.Temporary.EOA = 50_000
             and then SI.Current.Temporary.Has_SvL,
             "level crossing not protected: its start a temporary EOA and "
             & "SvL (3.12.5.8)");
      Check (MRSP_Below_Sources, "MRSP below its sources, all kinds");

      --  a new route suitability of one type replaces that type only
      RS.N_ITER := 0;
      RS.D_SUITABILITY := 100;
      RS.M_LINEGAUGE := 1;
      Carry (2, 0, RS);
      Carry (2, 0, Grad ((1 => (0, 0))));
      Carry (2, 0, SSP ((1 => (0, 100, False))));
      Carry (2, 1, MA_Of ((1 => 500)));
      Carry (2, 1, MP);
      Run_X (25_000);
      Check (TD.Suitability (1).Used and then TD.Suitability (1).Value = 1
             and then TD.Suitability (2).Used
             and then TD.Suitability (2).Kind = 1,
             "route suitability: a type replaced, the others kept "
             & "(3.7.3.1 h, j)");
      Check (MAu.Mode_Profiles (1).Used
             and then MAu.Mode_Profiles (1).Mode = 0
             and then Est (MAu.Mode_Profiles (1).Start) = 110_000
             and then Est (MAu.Mode_Profiles (1).Ack_Start) = 100_000,
             "mode profile: stored with its MA (3.12.4)");
      Check (Integer_64 (SI.Current.Temporary.EOA)
               = Max_X (TD.LX (1).Start)
             and then SI.Current.Temporary.SvL = SI.Current.Temporary.EOA,
             "temporary EOA: the nearest (the LX before the mode profile); "
             & "its SvL, the max item moved by the relocation, and the EOA "
             & "not beyond it");

      --  3.7.3.2 b) to d): the initial states resumed from D_TRACKINIT
      declare
         C : T68.Packet_T;
      begin
         Add_Group (Group (30, 260));
         Add_Group (Group (40, 280));
         AS := (NID_PACKET => 51, Q_DIR => 1, Q_SCALE => 1,
                Q_TRACKINIT => 1, Has_D_TRACKINIT => True, D_TRACKINIT => 0,
                others => <>);
         RS := (NID_PACKET => 70, Q_DIR => 1, Q_SCALE => 1,
                Q_TRACKINIT => 1, Has_D_TRACKINIT => True, D_TRACKINIT => 0,
                others => <>);
         C.Q_DIR := 1;
         C.Q_SCALE := 1;
         C.Q_TRACKINIT := 0;
         C.Has_D_TRACKCOND := True;
         C.D_TRACKCOND := 400;
         C.L_TRACKCOND := 100;
         C.M_TRACKCOND := 0;
         Carry (3, 0, C);
         C := (NID_PACKET => 68, Q_DIR => 1, Q_SCALE => 1,
               Q_TRACKINIT => 1, Has_D_TRACKINIT => True, D_TRACKINIT => 0,
               others => <>);
         Carry (4, 0, AS);
         Carry (4, 0, RS);
         Carry (4, 1, C);
      end;
      Run_X (27_000);
      Check (TCo.Conditions.Count = 1, "track conditions: one stored");
      Run_X (35_000);
      Check (TD.ASP.Count = 0
             and then not TD.Suitability (1).Used
             and then not TD.Suitability (2).Used
             and then TCo.Conditions.Count = 0,
             "initial states resumed from D_TRACKINIT: ASP, route "
             & "suitability, track conditions (3.7.3.2 b, c, d)");
   end Scenario_Other_Profiles;

   --  A.3.1: the information 300 m in rear of the min safe rear end is
   --  deleted, and its origin released
   procedure Scenario_Rear_Deletion is
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False), 2 => (100, 80, False),
                         3 => (100, 60, False))));
      Run_X (15_000);
      Check (TD.SSP.Count = 3 and then EVC_Origins.Used_Count = 1,
             "rear: stored, one origin");
      Run_X (70_000, 2000);
      Check (TD.SSP.Count = 3, "rear: kept up to 300 m in rear");
      Run_X (80_000, 2000);
      Check (TD.SSP.Count = 2,
             "rear: an element 300 m behind the min safe rear end deleted "
             & "(A.3.1)");
   end Scenario_Rear_Deletion;

   --  The seams of the two halves of E3 in the snapshot: the coverage of
   --  the gradient profile and the default gradient for TSR (3.13.4.1.3),
   --  Extra (the configuration, the trip margin of 3.13.9.4.8.2, the
   --  fields of E4 and E5 at their defaults), and the speed and distance
   --  monitoring on this snapshot
   procedure Scenario_Snapshot_Seams is
      DG : T141.Packet_T;
      G  : SIn.Gradient_Profile_T;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      DG.Q_DIR := 1;
      DG.Q_GDIR := 0;
      DG.G_TSR := 12;
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, -5), 2 => (3000, End_Mark))));
      Carry (1, 1, MA_Of ((1 => 3000)));
      Carry (1, 1, DG);
      Run_X (15_000);
      G := SI.Current.Gradients;
      Check (G.Count = 3
             and then not G.Covered (1) and then G.Segments (1).Gradient = 0
             and then G.Covered (2) and then G.Segments (2).Start = 10_000
             and then G.Segments (2).Gradient = -5
             and then not G.Covered (3) and then G.Segments (3).Start = 310_000
             and then G.Has_Default_TSR and then G.Default_TSR = -12,
             "snapshot: the gradient profile covers 100 m to 3100 m, the "
             & "default gradient for TSR beside it (3.13.4.1.3)");
      Check (SI.Current.MA.Present and then SI.Current.Supervise
             and then SI.Current.Extra.Config
                        = EVC_Core.Configuration.Supervision
             and then SI.Current.Extra.Trip_Margin
                        = 2 * Pos.SOLR.Locacc + 1_000 + 300_000 / 10
             and then SI.Current.Extra.T_MAR = 0
             and then not SI.Current.Extra.SR_Distance
             and then not SI.Current.Temporary.Present,
             "snapshot: Extra, the trip margin 2 Q_LOCACC + 10 m + 10 % of "
             & "the distance from the SOLR to the EOA (3.13.9.4.8.2)");
      Check (EVC_Core.Supervision.Active
             and then EVC_Core.Supervision.V_MRSP = 2_777
             and then EVC_SDM."=" (EVC_Core.Supervision.Monitoring,
                                   EVC_SDM.CSM),
             "the speed and distance monitoring runs on the snapshot of the "
             & "stored information: CSM at 100 km/h");
   end Scenario_Snapshot_Seams;


end EVC_Test_Profiles;
