with EVC_Test_Support;  use EVC_Test_Support;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P58;
with ETCS_Track_Packets.P5;
with ETCS_Track_Packets.P16;
with ETCS_Track_Packets.P79;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P1;
with ETCS_Variables;
with EVC_Acceptance;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Levels;
with EVC_Radio;
with EVC_Test_Authority;
with EVC_Distances;
with EVC_Linking;
with EVC_Location;
with EVC_Modes;
with EVC_National_Values;
with EVC_Odometry;
with EVC_Ports;
with EVC_Position;
with EVC_Stored_Information;
with EVC_Train_Data;
with Interfaces;
with Sim_Telegrams;

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

      --  3.6.2.2.2 a) second bullet, 3.6.2.2.2.1, 3.6.4.2.2 b), 3.6.1.3:
      --  without linking, a group marked as unlinked becomes the SOLR and
      --  an ORBG, the position is valid, the LRBG stays "unknown"
      --  (what SUBSET-076 3070200_02 step 42 means; its telegram is
      --  marked linked, see test/s076/triage.csv S7fe2b1bf)
      Start_Track;
      Add_Group (Group (80, 100));
      Track (1).Linked := False;
      Run_To (20_000);
      Check (Pos.Status = Pos.Valid and then not Pos.LRBG.Valid
             and then Pos.SOLR.Valid and then Pos.SOLR.Id.NID_BG = 80
             and then Pos.Unlinked_ORBG (1).Id.NID_BG = 80
             and then Pos.Position_Report (M_SB, L1).NID_BG = 16383,
             "unlinked first group: the SOLR, an ORBG, LRBG unknown");
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

   --  3.16.2.7.1.1: two groups announced by linking missed in a row, no
   --  balise detected between the start of the first window and the end
   --  of the second, give the service brake although their reaction is
   --  "no reaction" (Q_LINKREACTION 2); a group read between them does not
   procedure Scenario_Linking_Double_Missed is
      Brake_At : Integer_64 := 0;
      Missed   : Natural := 0;
   begin
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 500, 500),
                                                       (20, 30, 40), 5, 2)));
      Run_To (20_000);
      while Train_Cm < 130_000 and then Brake_At = 0 loop
         Step (1_000);
         if Pos.Missed_Group_Found then
            Missed := Missed + 1;
         end if;
         if Pos.Linking_Reaction_Requested and then Pos.Reaction = 1 then
            Brake_At := Train_Cm;
         end if;
      end loop;
      Check (Missed = 2 and then Brake_At > 110_000
             and then JRU_Last (4, 2) = 1
             and then JRU_Last (4, 3) = Pos.Cause_Double_Missed,
             "double missed: the service brake at the end of the second "
             & "window (3.16.2.7.1.1), got" & Integer_64'Image (Brake_At)
             & Natural'Image (Missed));

      --  an unlinked group read between the two windows
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 500, 500),
                                                       (20, 30, 40), 5, 2)));
      Add_Group (Group (80, 800));
      Track (2).Linked := False;
      Brake_At := 0;
      Missed := 0;
      while Train_Cm < 130_000 loop
         Step (1_000);
         if Pos.Missed_Group_Found then
            Missed := Missed + 1;
         end if;
         if Pos.Linking_Reaction_Requested and then Pos.Reaction = 1 then
            Brake_At := Train_Cm;
         end if;
      end loop;
      Check (Missed = 2 and then Brake_At = 0,
             "double missed: a balise between the windows, no brake");
   end Scenario_Linking_Double_Missed;

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

   --  3.7.3.1 m): new linking replaces the stored linking from its
   --  reference group on; the part in rear of that group is kept
   procedure Scenario_Linking_Replacement is
      P58      : T58.Packet_T;
      OK       : Boolean;
      Fired_At : Integer_64 := 0;
   begin
      P58.Q_SCALE := 1;
      P58.T_CYCLOC := 255;
      P58.D_CYCLOC := 32_767;
      P58.M_LOC := 2;
      P58.N_ITER := 1;
      P58.D_LOC_List (1) := (D_LOC => 800, Q_LGTLOC => 1);
      --  the first group links the second, the second the third and the
      --  fourth: the chain from the first group is kept up to the second
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((1 => 500),
                                                       (1 => 20))));
      Add_Group (With_Links (Group (20, 600), Link_To ((400, 300),
                                                       (30, 40))));
      Add_Group (Group (30, 1000, 3));
      Add_Group (Group (40, 1300));
      Run_To (15_000);
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Run_To (65_000);
      Check (OK and then Pos.Linking.Stored
             and then Pos.Linking.Ref_Id.NID_BG = 10
             and then Pos.Linking.Count = 3
             and then Pos.Linking.Links (1).Id.NID_BG = 20
             and then Pos.Linking.Links (2).Id.NID_BG = 30
             and then Pos.Linking.Links (3).D = 120_000
             and then Pos.Linking.Solr = 1
             and then Pos.Linking.Expected = 2,
             "linking replacement: the new linking from the second group, "
             & "the first group in rear kept (3.7.3.1 m)");
      while Train_Cm < 95_000 and then Fired_At = 0 loop
         Step (1_000);
         if Pos.Report_Triggers.Location_Passed then
            Fired_At := Train_Cm;
         end if;
      end loop;
      Check (Fired_At = 89_000,
             "linking replacement: a location from the first group still "
             & "relocated by the linking distance, got"
             & Integer_64'Image (Fired_At));
      Run_To (140_000);
      Check (Pos.LRBG.Id.NID_BG = 40 and then JRU_Seen (4) = 0
             and then JRU_Seen (5) = 0 and then JRU_Seen (6) = 0,
             "linking replacement: the groups of the new linking found");
      --  a group outside the stored chain: the new linking alone
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((1 => 500),
                                                       (1 => 20))));
      Add_Group (Group (20, 600));
      Add_Group (With_Links (Group (50, 1500), Link_To ((1 => 300),
                                                        (1 => 60))));
      Run_To (160_000);
      Check (Pos.Linking.Stored and then Pos.Linking.Ref_Id.NID_BG = 50
             and then Pos.Linking.Count = 1
             and then Pos.Linking.Solr = 0
             and then Pos.Linking.Expected = 1,
             "linking replacement: no stored part in rear, the new "
             & "linking alone (3.7.3.1 m)");
   end Scenario_Linking_Replacement;

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

   --  4.8.4.2, row "Geographical Position", column SH: packet 79 of a
   --  balise group read in Shunting is rejected, not stored (4080415_01
   --  step 171; the DMI's symbol not shown after it)
   procedure Scenario_Geo_Rejected_In_SH is
      G : T79.Packet_T;
   begin
      Start_Track;
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SH, EVC_Modes.L2);
      G.Q_DIR := 1;
      G.Q_SCALE := 1;
      G.NID_BG := 10;
      G.D_POSOFF := 0;
      G.Q_MPOSITION := 1;
      G.M_POSITION := 42_000;
      Add_Group (Group (10, 100));
      Track (1).Has_Geo := True;
      Track (1).Geo := G;
      Run_To (20_000);
      Check (EVC_Core.Mode = EVC_Modes.M_SH
             and then Pos.LRBG.Id.NID_BG = 10 and then not Pos.Geo_Known,
             "geo: packet 79 of a group read in SH is rejected (4.8.4.2)");
   end Scenario_Geo_Rejected_In_SH;

   --  Message 24 (T_TRAIN now, LRBG 123/10) with a packet 79 naming the
   --  group Ref of country 123 at M_POSITION M, counting up
   function M24_With_79 (Ref : Natural; M : Natural) return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      P  : T79.Packet_T;
      OK : Boolean;
   begin
      V (3) := Interfaces.Unsigned_64
        (EVC_Radio.T_Train_At (Interfaces.Unsigned_64 (EVC_Core.Time_Ms)));
      V (5) := 123;
      V (6) := 10;
      Start_Message (W, ETCS_Message_Catalogue.Track_M24, V);
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.Q_NEWCOUNTRY := 1;
      P.Has_NID_C := True;
      P.NID_C := 123;
      P.NID_BG := ETCS_Variables.NID_BG_T (Ref);
      P.D_POSOFF := 0;
      P.Q_MPOSITION := 1;
      P.M_POSITION := ETCS_Variables.M_POSITION_T (M);
      T79.Encode (P, W, OK);
      Check (OK, "radio geo: packet 79 encoded");
      return Message_Bytes (W);
   end M24_With_79;

   --  3.6.6.4.1, 4.8.3 (the row "Geographical Position, From RBC: Yes":
   --  R [2] in level 1, A in level 2), 4.8.4.2 (R in SH), 4.8.5.5: a
   --  packet 79 by radio in level 1 with level 2 announced is kept and
   --  used at the transition (SUBSET-076 4080415_01 steps 287 to 295);
   --  in level 2 it is taken at once, its reference group anchored when
   --  passed; in SH it is rejected
   procedure Scenario_Geo_By_Radio is
      package A renames EVC_Acceptance;
      use type A.Radio_Verdict_T;
      C : A.Context_T := (Mode => EVC_Modes.M_FS, Level_Valid => True,
                          Level => EVC_Modes.L1, others => <>);
   begin
      Check (A.Radio_Geo_Verdict (C, False) = A.Radio_Rejected
             and then A.Radio_Geo_Verdict (C, True) = A.Radio_Stored,
             "radio geo: level 1, rejected; stored with level 2 announced "
             & "(4.8.3 [2])");
      Check (A.Radio_Geo_Verdict (C, True, Session_Up => False)
               = A.Radio_Rejected,
             "radio geo: no session established: rejected, the packet kept "
             & "for the transition deleted (4.8.5.4 c, B060)");
      C.Level := EVC_Modes.L2;
      Check (A.Radio_Geo_Verdict (C, False) = A.Radio_Accepted,
             "radio geo: level 2 FS, accepted");
      C.Mode := EVC_Modes.M_SH;
      Check (A.Radio_Geo_Verdict (C, False) = A.Radio_Rejected,
             "radio geo: level 2 SH, rejected (4.8.4.2)");

      EVC_Test_Authority.Start_L2_Announced;
      Give_Radio_Message (1, M24_With_79 (10, 42_000));
      Stand_X (200);
      Check (not Pos.Geo_Known and then Geo_Seen = EVC_DMI_Port.Geo_Unknown,
             "radio geo: kept in level 1 with level 2 announced, not used "
             & "(4.8.3 [2], 4.8.5.1)");
      Run_X (45_000);
      Check (EVC_Levels.Level = EVC_Modes.L2 and then Pos.Geo_Known
             and then Pos.Geo_Metres in 42_300 .. 42_400
             and then Geo_Seen = Interfaces.Unsigned_32 (Pos.Geo_Metres),
             "radio geo: used at the level 2 transition, shown (4.8.5.5, "
             & "3.6.6.4.1: the LRBG as reference), got"
             & Natural'Image (Pos.Geo_Metres));
      --  in level 2: a reference group ahead, anchored when passed
      Add_Group (Group (11, 600));
      Give_Radio_Message (1, M24_With_79 (11, 50_000));
      Stand_X (200);
      Check (Pos.Geo_Metres in 42_300 .. 42_400,
             "radio geo: a reference ahead not applicable yet (3.6.6.4.2)");
      Run_X (65_000);
      Check (Pos.Geo_Metres in 50_000 .. 50_100,
             "radio geo: the group ahead passed, its reference applies, got"
             & Natural'Image (Pos.Geo_Metres));
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SH, EVC_Modes.L2);
      Stand_X (200);
      Pos.Delete_Geo;
      Give_Radio_Message (1, M24_With_79 (11, 60_000));
      Stand_X (200);
      Check (not Pos.Geo_Known,
             "radio geo: rejected in SH (4.8.4.2)");
   end Scenario_Geo_By_Radio;

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
      Check (Odo_SS_Count = 1 and then Odo_SS_Event = 0,
             "odometer: the driver informed, Odometer impaired shown "
             & "(3.6.8.5, the DMI's entry 36)");
      Run_To (500_000);
      Check (Odo_SS_Count = 1,
             "odometer: Odometer impaired shown once while impaired "
             & "(3.6.8.6.2)");
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
      Check (Odo_SS_Count = 2 and then Odo_SS_Event = 1,
             "odometer: Odometer impaired ended with the impairment "
             & "(3.6.8.6)");

      Start_Track;
      Bound_Per_Mille := 350;
      Run_To (430_000);
      Check (Odo.Safety_Exceeded and then Odo.Impaired
             and then JRU_Last (7, 2) = 2,
             "odometer: 35 % exceeds the safety threshold at 4300 m");
      Run_To (429_000);
      Check (Odo.Safety_Exceeded, "odometer: safety threshold latched");
   end Scenario_Odometer_Accuracy;

   --  4.5.2 Table, 3.6.8.5, 3.6.8.7 (B222): the check of the odometer
   --  accuracy thresholds runs in SM, FS, AD, LS, SR and OS only; the
   --  accumulation goes on in every mode, and the first check after the
   --  entry into FS judges it (SUBSET-076 4050200_10)
   procedure Scenario_Odometer_Check_By_Mode is
      Impaired_At : Integer_64 := 0;
   begin
      Start_Track;
      EVC_Core.Set_Mode_For_Test (M_UN, L0);
      Bound_Per_Mille := 60;
      Run_To (500_000);
      Check (not Odo.Impaired and then JRU_Seen (7) = 0
             and then Odo_SS_Count = 0,
             "odometer by mode: no check in UN (4.5.2), 300 m over 5000 m "
             & "neither impaired nor recorded nor shown");
      EVC_Core.Set_Mode_For_Test (M_FS, L1);
      while Impaired_At = 0 and then Train_Cm < 520_000 loop
         Step (1_000);
         if Odo.Impaired then
            Impaired_At := Train_Cm;
         end if;
      end loop;
      Check (Impaired_At in 500_001 .. 510_000
             and then JRU_Seen (7) = 1 and then JRU_Last (7, 2) = 1
             and then Odo_SS_Count = 1 and then Odo_SS_Event = 0,
             "odometer by mode: impaired at the first check in FS "
             & "(3.6.8.5), recorded and shown, got"
             & Integer_64'Image (Impaired_At));
      EVC_Core.Set_Mode_For_Test (M_SB, L1);
      Step (1_000);
      Check (not Odo.Impaired and then JRU_Last (7, 2) = 0
             and then Odo_SS_Count = 2 and then Odo_SS_Event = 1,
             "odometer by mode: the impairment not considered in SB "
             & "(4.5.2.1), the text removed");

      Start_Track;
      EVC_Core.Set_Mode_For_Test (M_SH, L1);
      Bound_Per_Mille := 350;
      Run_To (500_000);
      Check (not Odo.Safety_Exceeded and then not Odo.Impaired,
             "odometer by mode: 35 % in SH, no safety reaction (3.6.8.7 "
             & "inactive in SH)");
      EVC_Core.Set_Mode_For_Test (M_OS, L1);
      --  the end of the interval open at the entry
      Run_To (510_000);
      Check (Odo.Safety_Exceeded and then JRU_Last (7, 2) = 2,
             "odometer by mode: the safety threshold at the first check "
             & "in OS (3.6.8.7)");
   end Scenario_Odometer_Check_By_Mode;

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

      --  4.10 column NP, 4.11.1.1: the level kept over No Power, invalid
      --  at the power-up, valid when no cold movement occurred
      EVC_Core.Initialise;
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SB, EVC_Modes.L1);
      Cycle;
      EVC_Core.Power_Up;
      Check (EVC_Core.Level_Status = EVC_Modes.Invalid
             and then EVC_Core.Level = EVC_Modes.L1,
             "kept: the level L1, invalid after the power-up (4.10)");
      Input (Odometer, Odometer_Payload (0, 0, 0, 0, 0, 0, 0, 1, 100));
      Cycle;
      Check (EVC_Core.Level_Status = EVC_Modes.Valid
             and then EVC_Core.Level = EVC_Modes.L1,
             "kept: no cold movement, the level valid (4.11.1.1)");
      EVC_Core.Power_Up;
      Input (Odometer, Odometer_Payload (0, 0, 0, 0, 0, 0, 0, 1, 250));
      Cycle;
      Check (EVC_Core.Level_Status = EVC_Modes.Invalid,
             "kept: a cold movement, the level stays invalid (4.11.1.3)");
      EVC_Core.Initialise;
      Check (EVC_Core.Level_Status = EVC_Modes.Unknown,
             "kept: a new on-board keeps nothing");

      --  4.10 column NP, 3.6.1.3.3, 3.6.4.2.2.1: the position kept, the
      --  LRBG the SOLR, the train where it was, invalid until validated
      Start_Track;
      Add_Group (Group (10, 100));
      Run_To (20_000);
      declare
         K : Pos.Kept_Position_T;
         F : constant EVC_Distances.Dist_T := Pos.Estimated_Front;
      begin
         Pos.Keep (K);
         Pos.Clear;
         Pos.Restore (K);
         Check (Pos.Status = Pos.Invalid and then Pos.LRBG.Id.NID_BG = 10
                and then Pos.SOLR = Pos.LRBG
                and then Pos.Estimated_Front = F,
                "kept: the position restored invalid, at the same place");
         Pos.Revalidate;
         Check (Pos.Status = Pos.Valid, "kept: the position revalidated");
      end;
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

   --  3.8.5.2.2, 3.8.5.2.4 (e5/trips-fs, SUBSET-076 3040400_10): the
   --  repositioning information of the group announced as unknown sets
   --  the end of the section the train is in; elsewhere it is ignored
   procedure Scenario_MA_Repositioning is
      procedure Track_With (Reposition : Boolean; Unknown : Boolean) is
         L : T5.Packet_T :=
           Link_To ((1 => 500), (1 => (if Unknown then 16383 else 55)));
      begin
         L.D_LINK := 500;
         Start_X;
         Add_Group (With_Links (Group (10, 100), L));
         Add_Group (Group (55, 400));
         if Reposition then
            declare
               W  : Writer_T;
               OK : Boolean;
               P  : ETCS_Track_Packets.P16.Packet_T;
            begin
               P.Q_DIR := 2;
               P.Q_SCALE := 1;
               P.L_SECTION := 100;
               ETCS_Track_Packets.P16.Encode (P, W, OK);
               Check (OK, "MA repositioning: packet 16 encoded");
               Carry_Writer (2, 0, W);
            end;
         end if;
         Carry (1, 0, SSP ((1 => (0, 100, True))));
         Carry (1, 0, Grad ((1 => (0, 0))));
         Carry (1, 1, MA_Of ((1 => 350)));
      end Track_With;
   begin
      Track_With (Reposition => True, Unknown => True);
      Run_X (30_000);
      Check (EVC_Stored_Information.Current.MA.Present
             and then EVC_Stored_Information.Current.MA.EOA = 45_000,
             "MA repositioning: the EOA of the group in rear (3.8.5.2.2)");
      Run_X (44_000);
      Check (EVC_Stored_Information.Current.MA.Present
             and then EVC_Stored_Information.Current.MA.EOA = 50_000,
             "MA repositioning: the end section ends 100 m after the "
             & "announced group (3.8.5.2.2)");
      Track_With (Reposition => True, Unknown => False);
      Run_X (44_000);
      Check (EVC_Stored_Information.Current.MA.EOA = 45_000,
             "MA repositioning: ignored at a group linked by its identity "
             & "(3.8.5.2.2)");
   end Scenario_MA_Repositioning;

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
      --  the core gives the position the length of the valid Train Data
      --  once per cycle (EVC_Core.Sync_Train_Length, 3.18.3): none while
      --  the Train Data are invalid
      EVC_Train_Data.Invalidate;
      Run_To (50_000);
      Check (not Pos.Train_Length_Known
             and then Pos.Min_Safe_Rear = Pos.Min_Safe_Front,
             "rear end: no train length without valid Train Data");
      EVC_Train_Data.Set (EVC_Train_Data.Default,
                          EVC_Train_Data.Default_Categories);
      Run_To (51_000);
      Check (Pos.Train_Length_Known
             and then Pos.Min_Safe_Rear = Pos.Min_Safe_Front - 20_000,
             "rear end: the min safe front end minus the 200 m of the "
             & "Train Data");
   end Scenario_Rear_End;

   --  Packet 58 referring to one of the last LRBGs (3.6.2.2.2 c), a
   --  group passed twice and the ring of the last LRBGs (8) wrapped in
   --  between: its location D_LOC counts from the last passage of that
   --  group (3.6.1.3), not from the one kept further down the ring
   procedure Scenario_Report_Reference is
      P58 : T58.Packet_T;
      OK  : Boolean;
      Fired_At : Integer_64 := 0;
   begin
      Start_Track;
      for K in 0 .. 5 loop
         Add_Group (Group (11 + K, Integer_64 (100 + 100 * K)));
      end loop;
      Add_Group (Group (10, 700));
      Add_Group (Group (17, 800));
      Add_Group (Group (10, 900));
      Add_Group (Group (18, 1000));
      Run_To (105_000);
      Check (Pos.LRBG.Id.NID_BG = 18,
             "report reference: group 18 the LRBG, group 10 passed at 700 m "
             & "and at 900 m");
      P58.Q_SCALE := 1;
      P58.T_CYCLOC := 255;
      P58.D_CYCLOC := 32_767;
      P58.M_LOC := 2;
      P58.N_ITER := 1;
      P58.D_LOC_List (1) := (D_LOC => 300, Q_LGTLOC => 1);
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Forget;
      while Train_Cm < 130_000 and then Fired_At = 0 loop
         Step (1_000);
         if Pos.Report_Triggers.Location_Passed then
            Fired_At := Train_Cm;
         end if;
      end loop;
      Check (OK and then Fired_At > 115_000 and then Fired_At <= 120_000,
             "3.6.2.2.2 c), 3.6.5.1.5 c): the location 300 m from the last "
             & "passage of group 10 (1200 m), got"
             & Integer_64'Image (Fired_At));
   end Scenario_Report_Reference;

   --  3.14.3.6 (e4/gates-levels, B221): FS level 1 with the MA of the
   --  group 10 at 100 m; from 300 m the train moves backwards (the
   --  unauthorised direction protection watches, then brakes, 3.14.3.2)
   --  over the group 20 at 200 m (laid after the train passed there),
   --  whose packet 3 valid in both directions (Q_DIR 2, D_VALIDNV 0:
   --  now) would replace the national values without the gate: ignored,
   --  the group still locates the train
   procedure Scenario_Unauthorised_Direction_Groups is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_FS, EVC_Modes.L1);
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, True))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 1, MA_Of ((1 => 900)));
      Run_X (30_000);
      Add_Group (Group (20, 200));
      Carry (2, 1, Sim_Telegrams.National_Values (123));
      Check (EVC_Stored_Information.Current.MA.Present
             and then not EVC_National_Values.Current.From_Trackside,
             "unauthorised direction: FS with the MA of group 10, the "
             & "national values at their defaults");
      Run_X (19_000, 500);
      Check (Natural (Pos.LRBG.Id.NID_BG) = 20
             and then EVC_Core.Mode = EVC_Modes.M_FS,
             "unauthorised direction: the group 20 read backwards locates "
             & "the train (3.6)");
      Check (not EVC_National_Values.Current.From_Trackside
             and then not EVC_National_Values.Pending,
             "unauthorised direction: the information of a group read "
             & "during a movement opposite to the authorised direction is "
             & "ignored: its national values not taken (3.14.3.6, B221)");
   end Scenario_Unauthorised_Direction_Groups;

   --  3.6.4.2.2 b), 3.6.2.2.2 a): once the furthest announced group is
   --  passed the linking consistency is no longer checked
   --  (3.4.4.2.1.1 c)): a group marked as unlinked becomes the SOLR, the
   --  LRBG stays the last linked one; the JRU header gives both
   --  (SUBSET-027 4.2.3.5, Q_LRBG 2) with the train's orientation and
   --  the side of its front end against the SOLR (Q_DIRLRBG, Q_DLRBG of
   --  7.5.1.104, 7.5.1.106)
   procedure Scenario_SOLR_Unlinked is
   begin
      Start_Track;
      Add_Group (With_Links (Group (10, 100),
                             Link_To ((1 => 200), (1 => 20))));
      Add_Group (Group (20, 300));
      Add_Group (Group (80, 500));
      Track (3).Linked := False;
      Run_To (55_000);
      Check (Pos.LRBG.Id.NID_BG = 20 and then Pos.SOLR.Id.NID_BG = 80,
             "3.6.4.2.2 b): the unlinked group the SOLR, the LRBG the last "
             & "linked one");
      Check (JRU_Header.Q_LRBG = 2 and then JRU_Header.SOLR.NID = Id (80)
             and then JRU_Header.LRBG.NID = Id (20),
             "SUBSET-027 4.2.3.5: Q_LRBG 2, the SOLR and the LRBG");
      Check (JRU_Header.SOLR.Q_Dir = 1 and then JRU_Header.SOLR.Q_D = 1
             and then JRU_Header.SOLR.D in 1 .. 50,
             "SUBSET-027 4.2.3.5: the train nominal against the SOLR, its "
             & "front end on the nominal side beyond it, got"
             & Img (JRU_Header.SOLR.Q_Dir) & Img (JRU_Header.SOLR.Q_D)
             & Img (JRU_Header.SOLR.D) & Img (JRU_Header.SOLR.Q_Scale));
   end Scenario_SOLR_Unlinked;

   --  4.10.1.3 Table, column SL, note [1]: entering Sleeping deletes the
   --  train position when it is invalid (here kept over No Power, the
   --  cold movement information not yet known, 4.11.1.3); the JRU header
   --  then gives the SOLR unknown (SUBSET-076 4100103_47 step 70)
   procedure Scenario_SL_Deletes_Invalid is
      function Sig (S : TIU_Signal_T; On : Boolean) return Byte_Array is
        ((Byte (TIU_Signal_T'Pos (S) + 1), (if On then 1 else 0)));
   begin
      Start_Track;
      Add_Group (Group (10, 100));
      Run_To (20_000);
      Stand;
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SB, EVC_Modes.L1);
      Input (TIU, Sig (Cab_A_Active, False));
      Cycle;
      EVC_Core.Power_Up;
      Cycle;
      Check (Pos.Status = Pos.Invalid and then Pos.SOLR.Valid,
             "SL: the position kept, invalid after the power-up");
      Input (TIU, Sig (Sleeping_Requested, True));
      Stand;
      Check (EVC_Core.Mode = EVC_Modes.M_SL
             and then Pos.Status = Pos.Unknown and then not Pos.SOLR.Valid,
             "4.10.1.3 [1]: entering SL deletes the invalid position");
      Check (JRU_Header.SOLR.NID = 16_777_215
             and then JRU_Header.SOLR.D = 32_767,
             "SUBSET-027 4.2.3.5: the SOLR unknown in the JRU header");
   end Scenario_SL_Deletes_Invalid;


end EVC_Test_Position;
