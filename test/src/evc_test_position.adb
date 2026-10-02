with EVC_Test_Support;  use EVC_Test_Support;
with ETCS_Track_Packets.P58;
with ETCS_Track_Packets.P5;
with ETCS_Track_Packets.P79;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P1;
with ETCS_Variables;
with EVC_Core;
with EVC_Distances;
with EVC_Linking;
with EVC_Location;
with EVC_Modes;
with EVC_Odometry;
with EVC_Ports;
with EVC_Position;
with Interfaces;

package body EVC_Test_Position is

   package T5 renames ETCS_Track_Packets.P5;
   package R0 renames ETCS_Train_Packets.P0;
   package Pos renames EVC_Position;
   package Odo renames EVC_Odometry;
   package T58 renames ETCS_Track_Packets.P58;
   package T79 renames ETCS_Track_Packets.P79;
   package R1 renames ETCS_Train_Packets.P1;

   use type EVC_Location.Anchor_T;
   use type EVC_Distances.Cm_T;
   use type EVC_Distances.Sense_T;
   use type EVC_Distances.Direction_T;
   use type T5.Packet_T;
   use type R0.Packet_T;
   use type Pos.Status_T;
   use type Pos.Report_Kind_T;
   use type Pos.Cab_T;
   use type Odo.Cold_T;
   use type R1.Packet_T;
   use type ETCS_Variables.NID_BG_T;
   use type ETCS_Variables.Q_LINKREACTION_T;
   use type ETCS_Variables.D_LRBG_T;
   use type ETCS_Variables.NID_C_T;
   use type ETCS_Variables.Q_SCALE_T;
   use type ETCS_Variables.L_DOUBTOVER_T;
   use type ETCS_Variables.L_DOUBTUNDER_T;
   use type ETCS_Variables.Q_DIRLRBG_T;
   use type ETCS_Variables.Q_DLRBG_T;
   use type ETCS_Variables.Q_DIRTRAIN_T;
   use type ETCS_Variables.V_TRAIN_T;
   use type ETCS_Variables.M_MODE_T;
   use type ETCS_Variables.M_LEVEL_T;
   use type ETCS_Variables.Q_INTEGRITY_T;
   use EVC_Modes;
   use EVC_Ports;
   use Interfaces;

   procedure Scenario_Position_First_Group is
      P : R0.Packet_T;
   begin
      Start_Track;
      Add_Group (Group (10, 100));
      Check (Pos.Status = Pos.Unknown and then not Pos.LRBG.Valid,
             "first group: position unknown before");
      Check (Pos.Report_Kind = Pos.Report_P0
             and then Pos.Position_Report (M_SB, L1).NID_BG = 16383
             and then Pos.Position_Report (M_SB, L1).D_LRBG = 32767,
             "first group: LRBG unknown in the report (3.6.2.2.2.1)");
      Run_To (10_000);
      Check (Pos.Status = Pos.Unknown and then Pos.Passage_Open,
             "first group: balise 1 read, the passage is open");
      Run_To (20_000);
      Check (Pos.Status = Pos.Valid, "first group: position valid");
      Check (Pos.LRBG.Valid and then Pos.LRBG.Id.NID_BG = 10
             and then Pos.LRBG.X = 10_000
             and then Pos.LRBG.Orientation = EVC_Distances.Plus
             and then Pos.LRBG.Locacc = 1_200,
             "first group: LRBG, its location reference, orientation, "
             & "Q_NVLOCACC");
      Check (Pos.SOLR = Pos.LRBG, "first group: the SOLR is the LRBG");
      Check (Pos.Estimated_Front = 10_300,
             "first group: estimated front end 100 m + antenna 3 m, got"
             & EVC_Distances.Cm_T'Image (Pos.Estimated_Front));
      --  2 % of 110 m since the sample before the detection
      Check (Pos.Doubt_Over = 1_420 and then Pos.Doubt_Under = 1_420,
             "first group: confidence 12 m + 2.2 m, got"
             & EVC_Distances.Cm_T'Image (Pos.Doubt_Over));
      Check (Pos.Min_Safe_Front = 10_300 - 1_420
             and then Pos.Max_Safe_Front = 10_300 + 1_420,
             "first group: min and max safe front ends");
      Check (JRU_Seen (10) = 1 and then JRU_Id (10) = Id (10)
             and then JRU_Seen (8) = 1 and then JRU_Last (8, 2) = 1,
             "first group: JRU new LRBG and position valid");
      Check (Seen.LRBG_Passed and then not Seen.Location_Passed,
             "first group: report trigger 3.6.5.1.4 j)");
      Check (Onboard_Field (1) / 32 mod 2 = 1,
             "first group: MSG_ONBOARD position valid, got"
             & Img (Onboard_Field (1)));
      Stand;
      Check (Pos.Report_Triggers.Standstill_Reached,
             "first group: standstill reached (3.6.5.1.4 a)");
      P := Pos.Position_Report (M_SB, L1);
      Check (P.NID_C = 123 and then P.NID_BG = 10 and then P.Q_SCALE = 0
             and then P.D_LRBG = 1_030
             and then P.L_DOUBTOVER = 142 and then P.L_DOUBTUNDER = 142
             and then P.Q_DIRLRBG = 1 and then P.Q_DLRBG = 1
             and then P.Q_DIRTRAIN = 1 and then P.V_TRAIN = 127
             and then P.M_MODE = 6 and then P.M_LEVEL = 2
             and then P.Q_INTEGRITY = 0,
             "first group: packet 0");
      Check (Round_Trip (P), "first group: packet 0 round trip");
      Step (1_000);
      Check (Pos.Report_Triggers.Standstill_Left
             and then Pos.Position_Report (M_SB, L1).V_TRAIN = 7,
             "first group: standstill left, 36 km/h reported as 7");
      Check_Golden ("position_first_group");
   end Scenario_Position_First_Group;

   --  Linked groups with their windows met (3.4.4.4.3, 3.4.4.4.6 a):
   --  each becomes LRBG and SOLR with the accuracy of the linking
   --  (3.6.4.1.3); a location item of packet 58 follows by the linking
   --  distance (3.6.4.2.5 a), and its "max" location passes
   procedure Scenario_Linking is
      P58 : T58.Packet_T;
      OK  : Boolean;
      Fired_At : Integer_64 := 0;
   begin
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30))));
      Add_Group (Group (20, 600));
      Add_Group (Group (30, 1000, 3));
      Run_To (15_000);
      Check (Pos.Linking.Stored and then Pos.Linking.Count = 2
             and then Pos.Linking.Expected = 1
             and then EVC_Linking.Checked (Pos.Linking),
             "linking: stored, the window of the first group supervised");
      P58.Q_SCALE := 1;
      P58.T_CYCLOC := 255;
      P58.D_CYCLOC := 32_767;
      P58.M_LOC := 2;
      P58.N_ITER := 1;
      P58.D_LOC_List (1) := (D_LOC => 800, Q_LGTLOC => 1);
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Check (OK and then Pos.Report_Parameters_Stored,
             "linking: packet 58 against the LRBG");
      Pos.Set_Report_Parameters (P58, (123, 999), OK);
      Check (not OK, "linking: packet 58 against an unknown group refused");
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Forget;
      Run_To (65_000);
      Check (Pos.LRBG.Id.NID_BG = 20 and then Pos.LRBG.Locacc = 500
             and then Pos.SOLR.Id.NID_BG = 20
             and then Pos.Linking.Expected = 2
             and then Pos.Linking.Solr = 1,
             "linking: the second group, LRBG and SOLR, Q_LOCACC 5 m");
      Check (not Seen.LRBG_Passed,
             "linking: M_LOC 2, no report at the LRBG (3.6.5.1.5 d)");
      Check (Pos.Doubt_Over = 500 + 120,
             "linking: the confidence restarts from the new LRBG, got"
             & EVC_Distances.Cm_T'Image (Pos.Doubt_Over));
      --  the location, 800 m from the first group, is 300 m from the
      --  second; it passes when the max safe front end reaches it
      while Train_Cm < 95_000 and then Fired_At = 0 loop
         Step (1_000);
         if Pos.Report_Triggers.Location_Passed then
            Fired_At := Train_Cm;
         end if;
      end loop;
      Check (Fired_At = 89_000,
             "linking: the max safe front end passes the location at 890 m"
             & " (relocated by the linking distance), got"
             & Integer_64'Image (Fired_At));
      Run_To (110_000);
      Check (Pos.LRBG.Id.NID_BG = 30 and then Pos.Linking.Expected = 3
             and then not EVC_Linking.Checked (Pos.Linking),
             "linking: the third group, linking no longer checked");
      Check (JRU_Seen (4) = 0 and then JRU_Seen (5) = 0
             and then JRU_Seen (6) = 0,
             "linking: no reaction, nothing unexpected, nothing missed");
      Check (Pos.Doubt_Over = 500 + 220,
             "linking: confidence against the third group");
      Check_Golden ("position_linking");
   end Scenario_Linking;

   --  A linked group missed (3.16.2.3.1 b, 3.16.2.3.1.1), one detected
   --  in rear of its window (a), one of a later group (c), a group not
   --  in the linking (3.4.4.4.2), one passed the wrong way (3.4.4.4.7)
   procedure Scenario_Linking_Errors is
      Missed_At : Integer_64 := 0;
   begin
      --  missed: announced at 600 m with 5 m, nothing there
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30))));
      Add_Group (Group (30, 1000));
      Run_To (20_000);
      while Train_Cm < 70_000 and then Missed_At = 0 loop
         Step (1_000);
         if Pos.Missed_Group_Found then
            Missed_At := Train_Cm;
            Check (Pos.Linking_Reaction_Requested and then Pos.Reaction = 1,
                   "missed: service brake requested (Q_LINKREACTION 1)");
         end if;
      end loop;
      --  min safe antenna = (X - 100 m) - 12 m - 2 % of (X - 90 m) above
      --  605 m + 1.3 m
      Check (Missed_At = 63_000,
             "missed: detected at 630 m, got" & Integer_64'Image (Missed_At));
      Check (JRU_Seen (6) = 1 and then JRU_Id (6) = Id (20)
             and then JRU_Seen (4) = 1 and then JRU_Last (4, 2) = 1
             and then JRU_Last (4, 3) = Pos.Cause_Not_Detected
             and then JRU_Last (4, 4) = 1,
             "missed: JRU missed group and linking reaction");
      Check (Pos.Linking.Expected = 2 and then Pos.LRBG.Id.NID_BG = 10,
             "missed: the next window, the LRBG stays");
      Run_To (105_000);
      Check (Pos.LRBG.Id.NID_BG = 30, "missed: the next group accepted");

      --  in rear of its window: at 400 m instead of 600 m +- 5 m
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30), 5, 0)));
      Add_Group (Group (20, 400));
      Run_To (45_000);
      Check (Pos.LRBG.Id.NID_BG = 10 and then JRU_Seen (4) = 1
             and then JRU_Last (4, 2) = 0
             and then JRU_Last (4, 3) = Pos.Cause_Early,
             "early: rejected, train trip requested (3.16.2.3.1 a)");

      --  the group announced after the expected one comes first (c,
      --  3.4.4.4.6.1): it is checked against its own window
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30), 5, 2)));
      --  30, announced at 1000 m, lies inside the window of 20
      Add_Group (Group (30, 602));
      Run_To (65_000);
      Check (JRU_Seen (4) = 2 and then JRU_Last (4, 3) = Pos.Cause_Early
             and then Pos.LRBG.Id.NID_BG = 10,
             "other group: reaction c) for 20, then 30 early in its own "
             & "window");

      --  a linked group not in the linking information (3.4.4.4.2)
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30))));
      Add_Group (Group (90, 300));
      Add_Group (Group (20, 600));
      Run_To (35_000);
      Check (JRU_Seen (5) = 1 and then JRU_Id (5) = Id (90)
             and then JRU_Seen (4) = 0
             and then Pos.LRBG.Id.NID_BG = 10,
             "unexpected: rejected without reaction (3.16.2.4.3)");
      Run_To (65_000);
      Check (Pos.LRBG.Id.NID_BG = 20, "unexpected: the expected one next");

      --  unlinked groups are taken into account, not LRBG (3.4.4.4.2.2)
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30))));
      Add_Group (Group (80, 300));
      Track (2).Linked := False;
      Run_To (35_000);
      Check (Pos.LRBG.Id.NID_BG = 10 and then Pos.Unlinked_ORBG (1).Valid
             and then Pos.Unlinked_ORBG (1).Id.NID_BG = 80
             and then Pos.SOLR.Id.NID_BG = 10 and then JRU_Seen (5) = 0,
             "unlinked: an ORBG, neither LRBG nor SOLR");

      --  passed in the unexpected direction (3.4.4.4.7)
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30), 5, 2)));
      Add_Group (Group (20, 600));
      Track (2).Reversed := True;
      Track (2).At_Cm := 60_300;
      Run_To (65_000);
      Check (JRU_Seen (4) = 1 and then JRU_Last (4, 2) = 0
             and then JRU_Last (4, 3) = Pos.Cause_Wrong_Direction
             and then Pos.LRBG.Id.NID_BG = 10,
             "wrong direction: rejected, trip requested");
      Check_Golden ("position_linking_errors");
   end Scenario_Linking_Errors;

   --  Single balise groups: orientation from linking (3.4.2.3.2.2), the
   --  report based on two groups (3.4.2.3.3.1 to .4), the assignment by
   --  the RBC (3.4.2.3.3.6, .8); duplicated balises (3.4.2.2.1.1,
   --  3.4.2.4.1)
   procedure Scenario_Single_Balise is
      P  : R1.Packet_T;
      OK : Boolean;
   begin
      Start_Track;
      Add_Group (With_Links (Group (10, 100),
                             Link_To ((1 => 200), (1 => 15))));
      Add_Group (Group (15, 300, 1));
      Add_Group (Group (30, 500, 1));
      --  a single group behind 30, not read on the way there
      Add_Group (Group (20, 520, 1));
      Track (4).Skip := 1;
      Run_To (35_000);
      Check (Pos.LRBG.Id.NID_BG = 15
             and then Pos.LRBG.Orientation = EVC_Distances.Plus
             and then Pos.Report_Kind = Pos.Report_P0,
             "single: co-ordinate system from the linking (3.4.2.3.2.2)");
      Run_To (55_000);
      Check (Pos.LRBG.Id.NID_BG = 30
             and then Pos.LRBG.Orientation = EVC_Distances.Unknown
             and then Pos.Previous_LRBG.Id.NID_BG = 15
             and then Pos.Report_Kind = Pos.Report_P1,
             "single: no co-ordinate system, report on two groups");
      P := Pos.Position_Report_2 (M_SB, L1);
      Check (P.NID_BG = 30 and then P.NID_BG_PRVLRBG = 15
             and then P.Q_DIRLRBG = 1 and then P.Q_DLRBG = 1
             and then P.Q_DIRTRAIN = 1 and then P.D_LRBG = 530,
             "single: directions against prev -> LRBG (3.4.2.3.3.2)");
      Check (Round_Trip (P), "single: packet 1 round trip");
      Pos.Assign_Coordinate_System ((123, 30), False, OK);
      Check (OK and then Pos.LRBG.Orientation = EVC_Distances.Minus
             and then Pos.Report_Kind = Pos.Report_P0
             and then Pos.Position_Report (M_SB, L1).Q_DIRLRBG = 0,
             "single: the RBC assigns reverse (3.4.2.3.3.6)");

      --  back over 20 only: passed against the direction 30 was passed
      --  in, the previous LRBG is unknown (3.4.2.3.3.4)
      Track (4).Skip := 0;
      Run_To (51_000);
      Check (Pos.LRBG.Id.NID_BG = 20 and then not Pos.Previous_LRBG.Valid,
             "single: passed the other way, previous LRBG unknown");
      P := Pos.Position_Report_2 (M_SB, L1);
      Check (P.NID_BG_PRVLRBG = 16383 and then P.Q_DIRLRBG = 2
             and then P.Q_DLRBG = 2 and then P.Q_DIRTRAIN = 2,
             "single: directions unknown (3.4.2.3.3.3)");
      --  back over 30: now after 20, another previous LRBG
      Run_To (45_000);
      Check (Pos.LRBG.Id.NID_BG = 30
             and then Pos.Previous_LRBG.Id.NID_BG = 20,
             "single: 30 again, after 20");
      Pos.Assign_Coordinate_System ((123, 30), True, OK);
      Check (not OK, "single: reported with different previous LRBGs, "
             & "assignment refused (3.4.2.3.3.7, 3.4.2.3.3.8)");

      --  duplicated balises, balise 1 not read: balise 2 is the location
      --  reference, the group has no orientation of its own
      Start_Track;
      Add_Group (Group (40, 100));
      Track (1).Dup_1_2 := True;
      Track (1).Skip := 1;
      Run_To (11_000);
      Check (Pos.Passage_Open, "duplicate: waits for the other balise");
      Run_To (30_000);
      Check (Pos.LRBG.Id.NID_BG = 40 and then Pos.LRBG.X = 10_300
             and then Pos.LRBG.Orientation = EVC_Distances.Unknown,
             "duplicate: balise 2 is the location reference (3.4.2.2.1.1),"
             & " a single balise group (3.4.2.4.1)");
      Check_Golden ("position_single_balise");
   end Scenario_Single_Balise;

   --  3.6.6: the geographical position from packet 79
   procedure Scenario_Geo is
      G : T79.Packet_T;
   begin
      Start_Track;
      G.Q_DIR := 1;
      G.Q_SCALE := 1;
      G.NID_BG := 10;
      G.D_POSOFF := 50;
      G.Q_MPOSITION := 1;
      G.M_POSITION := 42_000;
      G.N_ITER := 1;
      G.Q_NEWCOUNTRY_List (1).NID_BG := 11;
      G.Q_NEWCOUNTRY_List (1).D_POSOFF := 0;
      G.Q_NEWCOUNTRY_List (1).Q_MPOSITION := 0;
      G.Q_NEWCOUNTRY_List (1).M_POSITION := 50_000;
      Add_Group (Group (10, 100));
      Track (1).Has_Geo := True;
      Track (1).Geo := G;
      Add_Group (Group (11, 300));
      Run_To (14_000);
      Check (not Pos.Geo_Known and then Geo_Count = 0,
             "geo: not before the offset (3.6.6.4.2)");
      Run_To (15_000);
      Check (Pos.Geo_Known and then Pos.Geo_Metres = 42_003,
             "geo: 42 003 m at the reference + 3 m, got"
             & Natural'Image (Pos.Geo_Metres));
      Run_To (20_000);
      Check (Pos.Geo_Metres = 42_053 and then Geo_Seen = 42_053,
             "geo: 42 053 m, on the DMI (MSG_STATUS)");
      Run_To (40_000);
      Check (Pos.Geo_Metres = 50_000 - 103,
             "geo: the second reference, counting down, got"
             & Natural'Image (Pos.Geo_Metres));
      Pos.Delete_Geo;
      Geo_Count := 0;
      Stand;
      Check (Geo_Count = 1 and then Geo_Seen = 16#FFFF_FFFF#,
             "geo: once unknown when it stops");
      Stand;
      Check (Geo_Count = 1, "geo: then nothing");
      Check_Golden ("position_geo");
   end Scenario_Geo;

   --  3.6.8, A.3.1: odometer accuracy impaired, safety threshold
   procedure Scenario_Odometer_Accuracy is
      Impaired_At : Integer_64 := 0;
      Nominal_At  : Integer_64 := 0;
   begin
      Start_Track;
      Bound_Per_Mille := 60;
      while Impaired_At = 0 and then Train_Cm < 600_000 loop
         Step (1_000);
         if Odo.Impaired then
            Impaired_At := Train_Cm;
         end if;
      end loop;
      Check (Impaired_At = 420_000,
             "odometer: 6 % impaired after 4200 m (250 m), got"
             & Integer_64'Image (Impaired_At));
      Check (JRU_Seen (7) = 1 and then JRU_Last (7, 2) = 1
             and then not Odo.Safety_Exceeded,
             "odometer: JRU impaired");
      Run_To (500_000);
      Bound_Per_Mille := 10;
      while Nominal_At = 0 and then Train_Cm < 2_000_000 loop
         Step (1_000);
         if not Odo.Impaired then
            Nominal_At := Train_Cm;
         end if;
      end loop;
      --  the window falls below 255 m after 10 intervals, then 5000 m
      Check (Nominal_At = 1_090_000,
             "odometer: nominal again after 5000 m below the accuracy "
             & "(3.6.8.6), got" & Integer_64'Image (Nominal_At));
      Check (JRU_Seen (7) = 2 and then JRU_Last (7, 2) = 0,
             "odometer: JRU nominal");

      Start_Track;
      Bound_Per_Mille := 350;
      Run_To (430_000);
      Check (Odo.Safety_Exceeded and then Odo.Impaired
             and then JRU_Last (7, 2) = 2,
             "odometer: 35 % exceeds the safety threshold at 4300 m");
      Run_To (429_000);
      Check (Odo.Safety_Exceeded, "odometer: safety threshold latched");
   end Scenario_Odometer_Accuracy;

   --  3.15.8: cold movement at power-up
   procedure Scenario_Cold_Movement is
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      Forget;
      Check (Odo.Cold = Odo.Cold_Unknown, "cold: unknown before a sample");
      Input (Odometer, Odometer_Payload (0, 0, 0, 0, 0, 0, 0, 1, 250));
      Cycle;
      Check (Odo.Cold = Odo.Cold_Movement and then JRU_Seen (9) = 1,
             "cold: 2.5 m moved in No Power is a cold movement");
      Input (Odometer, Odometer_Payload (0, 0, 0, 0, 0, 0, 0, 1, 0));
      Cycle;
      Check (Odo.Cold = Odo.Cold_Movement and then JRU_Seen (9) = 1,
             "cold: read once, at power-up");

      EVC_Core.Initialise;
      Forget;
      Input (Odometer, Odometer_Payload (0, 0, 0, 0, 0, 0, 0, 1, 200));
      Cycle;
      Check (Odo.Cold = Odo.No_Cold_Movement and then JRU_Seen (9) = 0,
             "cold: 2 m allowed (3.15.8.1.1)");

      EVC_Core.Initialise;
      Forget;
      Input (Odometer, Odometer_Payload (0, 0, 0, 0, 0, 0, 0, 0, 0));
      Cycle;
      Check (Odo.Cold = Odo.Cold_Not_Available and then JRU_Seen (9) = 0,
             "cold: information not available (3.15.8.3)");
   end Scenario_Cold_Movement;

   --  3.6.1.5, 5.12.2.5: the active cab defines the orientation; the
   --  front end and the report follow from the previous data
   procedure Scenario_Orientation is
      P : R0.Packet_T;
   begin
      Start_Track;
      Add_Group (Group (10, 100));
      Run_To (15_000);
      Stand;
      Check (Pos.Orientation = EVC_Distances.Plus
             and then Pos.Orientation_Known
             and then Pos.Active_Cab = Pos.Cab_A
             and then Pos.Estimated_Front = 5_300,
             "orientation: cab A, front 53 m ahead of the LRBG");
      Input (TIU, (1, 0));
      Stand;
      Check (Pos.Orientation = EVC_Distances.Plus
             and then Pos.Active_Cab = Pos.No_Cab,
             "orientation: no cab active, the last active one stays");
      Input (TIU, (2, 1));
      Stand;
      Check (Pos.Orientation = EVC_Distances.Minus
             and then Pos.Active_Cab = Pos.Cab_B
             and then Pos.Estimated_Front = -3_300,
             "orientation: cab B, its end 33 m in rear of the LRBG, got"
             & EVC_Distances.Cm_T'Image (Pos.Estimated_Front));
      P := Pos.Position_Report (M_SB, L1);
      Check (P.Q_DIRLRBG = 0 and then P.Q_DLRBG = 1 and then P.D_LRBG = 330,
             "orientation: reverse against the LRBG, front on its "
             & "nominal side");
      Input (TIU, (1, 1));
      Stand;
      Check (Pos.Orientation = EVC_Distances.Minus
             and then Pos.Active_Cab = Pos.No_Cab,
             "orientation: both cabs active, nothing changes");
      Input (TIU, (1, 0));
      Step (-2_000);
      Check (Pos.Estimated_Front = -1_300
             and then Pos.Position_Report (M_SB, L1).Q_DIRTRAIN = 0,
             "orientation: moving towards cab B, reverse against the LRBG");
      Check_Golden ("position_orientation");
   end Scenario_Orientation;

   --  3.6.7: distances not referred to balise groups
   procedure Scenario_Virtual is
      V : Odo.Virtual_T;
   begin
      Start_Track;
      Run_To (10_000);
      V := Odo.Start_Virtual (5_000, EVC_Distances.Plus);
      Run_To (12_000);
      Check (Odo.Remaining_Estimated (V) = 3_000
             and then Odo.Remaining_Max_Safe (V) = 3_000 - 40
             and then Odo.Remaining_Min_Safe (V) = 3_000 + 40,
             "virtual: remaining distances (3.6.7.3)");
      Check (Odo.Away (V, EVC_Distances.Plus) = 2_000
             and then Odo.Away (V, EVC_Distances.Minus) = 0
             and then Odo.Away (V, EVC_Distances.Unknown) = 2_000,
             "virtual: travelled away (3.6.7.2)");
      Odo.Set_Distance (V, 8_000);
      Check (Odo.Remaining_Estimated (V) = 6_000,
             "virtual: new national value, same start (3.6.7.5)");
      Run_To (11_000);
      Check (Odo.Away (V, EVC_Distances.Unknown) = 1_000
             and then Odo.Remaining_Estimated (V) = 7_000,
             "virtual: back");
   end Scenario_Virtual;

   --  3.6.5.1.4, 3.6.5.1.5: report triggers
   procedure Scenario_Report_Triggers is
      P58   : T58.Packet_T;
      OK    : Boolean;
      Times : Natural := 0;
      Dists : Natural := 0;
   begin
      Start_Track;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 500));
      Run_To (15_000);
      P58.Q_SCALE := 1;
      P58.T_CYCLOC := 2;
      P58.D_CYCLOC := 50;
      P58.M_LOC := 0;
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Stand;
      Check (OK and then Pos.Report_Triggers.Immediate,
             "triggers: M_LOC 0, immediately (3.6.5.1.5 e)");
      Forget;
      for I in 1 .. 40 loop
         Step (500);
         Times := Times + (if Pos.Report_Triggers.Periodic_Time then 1
                           else 0);
         Dists := Dists + (if Pos.Report_Triggers.Periodic_Distance then 1
                           else 0);
      end loop;
      Check (Times = 2 and then Dists = 4,
             "triggers: every 2 s and every 50 m in 4 s and 200 m, got"
             & Img (Times) & Img (Dists));
      Check (not Seen.LRBG_Passed,
             "triggers: M_LOC 0 is not every LRBG");
      P58.M_LOC := 1;
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Forget;
      Run_To (52_000);
      Check (Seen.LRBG_Passed, "triggers: M_LOC 1, the LRBG (3.6.5.1.5 d)");
      Input (DMI, Isolate);
      Stand;
      Stand;
      Check (Pos.Report_Triggers.Mode_Changed,
             "triggers: the mode changed (3.6.5.1.4 b)");
   end Scenario_Report_Triggers;

   --  3.6.1.7: the min safe rear end with the train length
   --  3.6.4.2.5 c) then b): a "max" location item of packet 58 referred
   --  to a group, relocated without linking to the next SOLR by the
   --  travelled distance, then with linking widened by twice the
   --  accuracy of its former reference
   procedure Scenario_Relocation is
      P58      : T58.Packet_T;
      OK       : Boolean;
      Fired_At : Integer_64 := 0;

      procedure Until_Passed (Limit : Integer_64) is
      begin
         Fired_At := 0;
         while Train_Cm < Limit and then Fired_At = 0 loop
            Step (1_000);
            if Pos.Report_Triggers.Location_Passed then
               Fired_At := Train_Cm;
            end if;
         end loop;
      end Until_Passed;
   begin
      P58.Q_SCALE := 1;
      P58.T_CYCLOC := 255;
      P58.D_CYCLOC := 32_767;
      P58.M_LOC := 2;
      P58.N_ITER := 1;

      --  c): at 500 m, 400 m from the first group; the max safe front
      --  end against the second group reaches it where it would against
      --  the first (3.6.4.2.5.4)
      Start_Track;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 300));
      Run_To (15_000);
      P58.D_LOC_List (1) := (D_LOC => 400, Q_LGTLOC => 1);
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Until_Passed (60_000);
      Check (OK and then Pos.SOLR.Id.NID_BG = 20 and then Fired_At = 48_000,
             "relocation c): the location passed at 480 m, got"
             & Integer_64'Image (Fired_At));

      --  then b): at 900 m; the second group links the third
      Start_Track;
      Add_Group (Group (10, 100));
      Add_Group (With_Links (Group (20, 300), Link_To ((1 => 300),
                                                        (1 => 30))));
      Add_Group (Group (30, 600));
      Run_To (15_000);
      P58.D_LOC_List (1) := (D_LOC => 800, Q_LGTLOC => 1);
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Until_Passed (100_000);
      Check (OK and then Pos.SOLR.Id.NID_BG = 30
             and then Pos.LRBG.Locacc = 500
             and then Fired_At = 86_000,
             "relocation b): the linking distance plus twice 12 m, passed "
             & "at 860 m, got" & Integer_64'Image (Fired_At));
   end Scenario_Relocation;

   --  3.4.4.4.2.1, 3.4.4.4.4: a group announced with an unknown identity
   --  and repositioning information
   procedure Scenario_Repositioning is
      L : T5.Packet_T := Link_To ((1 => 500), (1 => 16383));
   begin
      L.D_LINK := 500;
      Start_Track;
      Add_Group (With_Links (Group (10, 100), L));
      Add_Group (Group (55, 400));
      Track (2).Reposition := True;
      Run_To (45_000);
      Check (Pos.LRBG.Id.NID_BG = 55 and then Pos.LRBG.Locacc = 500
             and then JRU_Seen (5) = 0 and then JRU_Seen (4) = 0,
             "repositioning: the group with packet 16 accepted in the "
             & "window from the previous group on");

      Start_Track;
      Add_Group (With_Links (Group (10, 100), L));
      Add_Group (Group (56, 400));
      Run_To (45_000);
      Check (Pos.LRBG.Id.NID_BG = 10 and then JRU_Seen (5) = 1
             and then JRU_Id (5) = Id (56),
             "repositioning: without packet 16 the group is rejected");

      Start_Track;
      Add_Group (With_Links (Group (10, 100), L));
      Add_Group (Group (57, 400, 1));
      Track (2).Reposition := True;
      Run_To (45_000);
      Check (Pos.LRBG.Id.NID_BG = 10 and then JRU_Seen (5) = 1,
             "repositioning: a single balise group is rejected (a)");
   end Scenario_Repositioning;

   --  3.6.6.4.3: announced references deleted on a change of orientation
   procedure Scenario_Geo_Orientation is
      G : T79.Packet_T;
   begin
      Start_Track;
      G.Q_DIR := 1;
      G.Q_SCALE := 1;
      G.Q_NEWCOUNTRY := 0;
      G.NID_BG := 11;
      G.M_POSITION := 50_000;
      Add_Group (Group (10, 100));
      Track (1).Has_Geo := True;
      Track (1).Geo := G;
      Add_Group (Group (11, 300));
      Run_To (15_000);
      Input (TIU, (1, 0));
      Input (TIU, (2, 1));
      Stand;
      Input (TIU, (2, 0));
      Input (TIU, (1, 1));
      Run_To (35_000);
      Check (not Pos.Geo_Known and then Geo_Count = 0,
             "geo: the announced reference deleted with the orientation");
   end Scenario_Geo_Orientation;

   procedure Scenario_Rear_End is
   begin
      Start_Track;
      Add_Group (Group (10, 100));
      Run_To (50_000);
      Check (not Pos.Train_Length_Known
             and then Pos.Min_Safe_Rear = Pos.Min_Safe_Front,
             "rear end: no train length");
      Pos.Set_Train_Length (20_000);
      Check (Pos.Min_Safe_Rear = Pos.Min_Safe_Front - 20_000,
             "rear end: the min safe front end minus 200 m");
   end Scenario_Rear_End;


end EVC_Test_Position;
