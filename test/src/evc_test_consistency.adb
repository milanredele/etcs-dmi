--  ETCS on-board (EVC)

with Interfaces;         use Interfaces;
with ETCS_Telegram;
with ETCS_Track_Packets.P145;
with ETCS_Track_Packets.P254;
with DMI_Protocol;
with EVC_Bytes;
with EVC_DMI_Port;
with ETCS_Variables;    use ETCS_Variables;
with EVC_Balise_Groups; use EVC_Balise_Groups;
with EVC_JRU_Messages;  use EVC_JRU_Messages;
with EVC_Core;
with EVC_Modes;
with EVC_Movement_Authority;
with EVC_Position;
with EVC_Test_Support;  use EVC_Test_Support;

package body EVC_Test_Consistency is

   --  A telegram of balise N_PIG of a group of N_TOTAL + 1 balises with
   --  the counter M_MCOUNT and the duplicate flag M_DUP; Decoded False
   --  as EVC_Position.Receive_Refused keeps it (no bits)
   function Tel (N_PIG, N_TOTAL : Natural; M_MCOUNT : Natural := 7;
                 M_DUP : Natural := 0; Decoded : Boolean := True)
     return ETCS_Telegram.Telegram_T
   is
      T : ETCS_Telegram.Telegram_T := ETCS_Telegram.No_Telegram;
   begin
      T.Header.N_PIG := N_PIG_T (N_PIG);
      T.Header.N_TOTAL := N_TOTAL_T (N_TOTAL);
      T.Header.M_MCOUNT := M_MCOUNT_T (M_MCOUNT);
      T.Header.M_DUP := M_DUP_T (M_DUP);
      T.Header.NID_BG := 5;
      T.Header.Q_LINK := 1;
      T.Bits := (if Decoded then ETCS_Telegram.Short_Bits else 0);
      return T;
   end Tel;

   procedure Read (P : in out Passage_T; T : ETCS_Telegram.Telegram_T) is
      R : constant Reading_T :=
        (N_PIG   => T.Header.N_PIG,
         M_DUP   => T.Header.M_DUP,
         Decoded => T.Bits /= 0,
         others  => <>);
   begin
      if not P.Open then
         Start (P, T, R);
      else
         Add (P, T, R);
      end if;
   end Read;

   --  T with one packet, of NID_PACKET N
   function With_Packet (T : ETCS_Telegram.Telegram_T; N : Natural)
     return ETCS_Telegram.Telegram_T
   is
      R : ETCS_Telegram.Telegram_T := T;
   begin
      R.Count := 1;
      R.Index (1).NID := NID_PACKET_T (N);
      return R;
   end With_Packet;

   --  3.16.2.4.8.1, 3.16.2.4.8.2: the telegram of a duplicated pair
   --  left out of the message loses its packets, the other keeps them
   procedure Scenario_Duplicated_Pair is
      P : Passage_T;

      --  The pair 0 / 1 read in this order with the packets A and B
      procedure Pair (A, B : Natural; Dup : Natural := 1) is
      begin
         P := (others => <>);
         Read (P, With_Packet (Tel (0, 1, M_DUP => Dup), A));
         Read (P, With_Packet (Tel (1, 1, M_DUP => 2 * Dup), B));
      end Pair;
   begin
      Pair (5, 5);
      Check (P.Telegrams (1).Count = 0 and then P.Telegrams (2).Count = 1
             and then Consistent (P),
             "duplicated pair 3.16.2.4.8.2: none with default balise"
             & " information, the last received telegram composes it");
      Pair (254, 254);
      Check (P.Telegrams (1).Count = 0 and then P.Telegrams (2).Count = 1,
             "duplicated pair 3.16.2.4.8.2: both with default balise"
             & " information, the last received telegram composes it");
      Pair (5, 254);
      Check (P.Telegrams (1).Count = 1 and then P.Telegrams (2).Count = 0
             and then not Has_Default (P.Telegrams (1)),
             "duplicated pair 3.16.2.4.8.1: the last with default balise"
             & " information ignored, the first composes it");
      Pair (254, 5);
      Check (P.Telegrams (1).Count = 0 and then P.Telegrams (2).Count = 1,
             "duplicated pair 3.16.2.4.8.1: the first with default balise"
             & " information ignored");
      Pair (5, 5, Dup => 0);
      Check (P.Telegrams (1).Count = 1 and then P.Telegrams (2).Count = 1,
             "duplicated pair: balises not duplicated both compose it");
      P := (others => <>);
      Read (P, With_Packet (Tel (0, 1, M_DUP => 1), 5));
      Read (P, With_Packet (Tel (1, 1, Decoded => False), 5));
      Check (P.Telegrams (1).Count = 1,
             "duplicated pair 3.16.2.4.8.2: the second not decoded, the"
             & " first keeps its packets");
   end Scenario_Duplicated_Pair;

   --  3.16.1.1, 3.16.2.4.1 a) and d), 3.16.2.4.2, 3.16.2.4.4.1 a),
   --  3.16.2.4.4.1 b), 3.16.2.4.7, 3.16.2.4.7.1, 3.16.2.4.8.2: the
   --  message of a passage consistent or not
   procedure Scenario_Message_Consistency is
      P : Passage_T;
   begin
      Read (P, Tel (0, 1));
      Read (P, Tel (1, 1));
      Check (Consistent (P), "consistency: two balises, same counters");

      P := (others => <>);
      Read (P, Tel (0, 1));
      Check (not Consistent (P),
             "consistency 3.16.2.4.1 a): a balise missed in the group");

      P := (others => <>);
      Read (P, Tel (0, 1));
      Read (P, Tel (1, 1, Decoded => False));
      Check (not Consistent (P),
             "consistency 3.16.1.1: a telegram not compliant");

      P := (others => <>);
      Read (P, Tel (0, 1, M_MCOUNT => 3));
      Read (P, Tel (1, 1, M_MCOUNT => 4));
      Check (not Consistent (P),
             "consistency 3.16.2.4.7: the counters differ");

      P := (others => <>);
      Read (P, Tel (0, 1, M_MCOUNT => 3));
      Read (P, Tel (1, 1, M_MCOUNT => 255));
      Check (Consistent (P),
             "consistency 3.16.2.4.6: a counter 255 fits every message");

      P := (others => <>);
      Read (P, Tel (0, 0, M_MCOUNT => 254));
      Check (not Consistent (P),
             "consistency 3.16.2.4.7.1: a single balise's counter 254");

      P := (others => <>);
      Read (P, Tel (1, 1, M_DUP => 2));
      Check (Consistent (P),
             "consistency 3.16.2.4.2: the missed balise duplicated by the"
             & " one read");

      P := (others => <>);
      Read (P, Tel (0, 1, M_MCOUNT => 3, M_DUP => 1));
      Read (P, Tel (1, 1, M_MCOUNT => 4, M_DUP => 2));
      Check (Superseded (P, 1) and then Consistent (P),
             "consistency 3.16.2.4.8.2: the first of a duplicated pair is"
             & " not used, its counter not compared");

      P := (others => <>);
      Read (P, Tel (0, 1));
      Check (not Reaction_Inhibited (P),
             "consistency 3.16.2.4.4.1 b): no packet 145, the reaction"
             & " applies");
   end Scenario_Message_Consistency;

   --  SUBSET-027 4.2.4.12, SUBSET-026 7.5.1.64: record 12 with M_ERROR 1
   --  for a linked group's message (3.16.2.4) and 2 for an unlinked
   --  one's (3.16.2.5), the events of EVC_Position.Event_Code
   procedure Scenario_Consistency_Record is
      NID : EVC_Bytes.Byte;
      F   : Fields_T;
   begin
      Check (EVC_Position.Event_Code (EVC_Position.Inconsistent_Linked) = 12
             and then EVC_Position.Event_Code
                        (EVC_Position.Inconsistent_Unlinked) = 13
             and then EVC_Position.Event_Code (EVC_Position.New_LRBG) = 10,
             "consistency: the event codes of the position");
      Paired_Message (12, 16#05#, 16#C0#, 16#00#, NID, F);
      Check (NID = NID_BG_Error and then F (2).Value = 5
             and then F (3).Value = 1 and then F (3).Bits = 8,
             "consistency SUBSET-027 4.2.4.12: record 12, M_ERROR 1");
      Paired_Message (13, 16#05#, 16#00#, 16#00#, NID, F);
      Check (NID = NID_BG_Error and then F (3).Value = 2,
             "consistency SUBSET-027 4.2.4.12: record 12, M_ERROR 2");
   end Scenario_Consistency_Record;

   --  Group G's balise K carries packet 254 with Q_DIR
   procedure Carry_Default (G : Positive; K : Natural; Q_DIR : Natural) is
      W  : Writer_T;
      OK : Boolean;
      P  : ETCS_Track_Packets.P254.Packet_T;
   begin
      P.Q_DIR := Q_DIR_T (Q_DIR);
      ETCS_Track_Packets.P254.Encode (P, W, OK);
      Check (OK, "default balise: packet 254 encoded");
      Carry_Writer (G, K, W);
   end Carry_Default;

   --  3.16.2.4.9, A.3.3.3 (SUBSET-076 3140300_02): the driver informed
   --  ("Trackside malfunction", catalogue entry 3) by a group whose
   --  message holds default balise information valid for the train;
   --  not by one valid in the other direction only
   procedure Scenario_Default_Balise is
   begin
      Start_X;
      SS_Seen := (others => 0);
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 300));
      Add_Group (Group (30, 500));
      Carry_Default (2, 0, 2);
      Carry_Default (3, 1, 0);
      Run_X (25_000);
      Check (SS_Seen (EVC_DMI_Port.SS_Trackside_Malfunction) = 0,
             "default balise: nothing shown before (3.16.2.4.9)");
      Run_X (40_000);
      Check (SS_Seen (DMI_Protocol.SS_Trackside_Malfunction) = 1,
             "default balise: Trackside malfunction shown (3.16.2.4.9)");
      Run_X (60_000);
      Check (SS_Seen (EVC_DMI_Port.SS_Trackside_Malfunction) = 1,
             "default balise: not for the other direction (A.3.3.3)");
   end Scenario_Default_Balise;

   --  The train runs to To_Cm a cycle (10 m) at a time; SB: the service
   --  brake commanded on the way (the TIU output)
   procedure Run_Watch (To_Cm : Integer_64; SB : out Boolean) is
   begin
      SB := False;
      while Train_Cm < To_Cm loop
         Step_X (1_000);
         if TIU_Out /= 16#FFFF# and then TIU_Out mod 256 / 2 mod 2 = 1 then
            SB := True;
         end if;
      end loop;
   end Run_Watch;

   --  Group G's balise K carries packet 145, the inhibition of the
   --  consistency reaction
   procedure Carry_Inhibition (G : Positive; K : Natural) is
      W  : Writer_T;
      OK : Boolean;
      P  : ETCS_Track_Packets.P145.Packet_T;
   begin
      P.Q_DIR := 2;
      ETCS_Track_Packets.P145.Encode (P, W, OK);
      Check (OK, "reactions: packet 145 encoded");
      Carry_Writer (G, K, W);
   end Carry_Inhibition;

   --  A track of group 10 at 100 m announcing (Linking) 20 at 600 m and
   --  30 at 1000 m with Reaction, 20 of Balises balises with its balise
   --  Skip - 1 missed, 30 present; or (not Linking) 20 marked Linked
   procedure Inconsistent_Track (Linking  : Boolean;
                                 Reaction : Natural := 1;
                                 Skip     : Natural := 1;
                                 Balises  : Positive := 2;
                                 Linked   : Boolean := True) is
   begin
      Start_X;
      SS_Seen := (others => 0);
      if Linking then
         Add_Group (With_Links (Group (10, 100),
                                Link_To ((500, 400), (20, 30), 5,
                                         Reaction)));
      else
         Add_Group (Group (10, 100));
      end if;
      Add_Group (Group (20, 600, Balises));
      Track (2).Skip := Skip;
      Track (2).Linked := Linked;
      Add_Group (Group (30, 1000));
   end Inconsistent_Track;

   procedure Scenario_Consistency_Reactions is
      SB : Boolean;
      Brake_Error : Natural renames
        SS_Seen (EVC_DMI_Port.SS_Balise_Read_Error_Brake);
   begin
      --  linking checked, the expected group's message inconsistent (a
      --  balise missed): the reaction of its linking, train trip
      Inconsistent_Track (Linking => True, Reaction => 0);
      Run_X (80_000);
      Check (EVC_Modes."=" (EVC_Core.Mode, EVC_Modes.M_TR),
             "reactions: the expected group's message inconsistent, its "
             & "linking reaction train trip (3.16.2.4.1 a)");
      Inconsistent_Track (Linking => True, Reaction => 1);
      Run_Watch (80_000, SB);
      Check (SB and then Brake_Error >= 1
             and then EVC_Modes."=" (EVC_Core.Mode, EVC_Modes.M_FS),
             "reactions: the expected group's message inconsistent, its "
             & "linking reaction the service brake, Balise read error "
             & "(3.16.2.4.1, 3.16.2.6.1)");
      --  3.16.2.4.2: the missed balise duplicated by one read
      Inconsistent_Track (Linking => True, Reaction => 0);
      Track (2).Dup_1_2 := True;
      Run_Watch (80_000, SB);
      Check (not SB and then EVC_Modes."=" (EVC_Core.Mode, EVC_Modes.M_FS),
             "reactions: the missed balise duplicated and its duplicate "
             & "read, no reaction (3.16.2.4.2)");

      --  linking not checked: the service brake, Balise read error, and
      --  at standstill the MA shortened to the train (3.16.2.4.4.2)
      Inconsistent_Track (Linking => False);
      Carry (1, 0, MA_Of ((1 => 2_000)));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Run_Watch (80_000, SB);
      Check (SB and then Brake_Error >= 1
             and then EVC_Movement_Authority.MA.Present
             and then not EVC_Movement_Authority.MA.Withdrawn,
             "reactions: linking not checked, a linked group's message "
             & "inconsistent, the service brake and Balise read error "
             & "(3.16.2.4.4 a, 3.16.2.4.4.3)");
      Stand;
      Stand;
      Check (EVC_Movement_Authority.MA.Withdrawn,
             "reactions: at standstill the MA shortened to the train "
             & "(3.16.2.4.4.2, A.3.4.1.2 g, EVC_Stored_Information"
             & ".Linking_Shortening)");
      Inconsistent_Track (Linking => False);
      Carry_Inhibition (2, 1);
      Run_Watch (80_000, SB);
      Check (not SB and then Brake_Error = 0,
             "reactions: packet 145 read in the group, no service brake "
             & "(3.16.2.4.4.1 b)");
      --  3.16.2.4.4.4: the last group announced, its own reaction (none)
      --  instead of the service brake
      Start_X;
      Add_Group (With_Links (Group (10, 100),
                             Link_To ((1 => 500), (1 => 20), 5, 2)));
      Add_Group (Group (20, 600));
      Track (2).Skip := 1;
      Run_Watch (80_000, SB);
      Check (not SB,
             "reactions: the last group announced inconsistent, its "
             & "linking reaction (none) applies (3.16.2.4.4.4)");
      --  an unlinked group's message inconsistent: the service brake,
      --  none with packet 145 (3.16.2.5.1, 3.16.2.5.3)
      Inconsistent_Track (Linking => False, Linked => False);
      Run_Watch (80_000, SB);
      Check (SB and then Brake_Error >= 1,
             "reactions: an unlinked group's message inconsistent, the "
             & "service brake (3.16.2.5.1)");
      Inconsistent_Track (Linking => False, Linked => False);
      Carry_Inhibition (2, 1);
      Run_Watch (80_000, SB);
      Check (not SB,
             "reactions: an unlinked group with packet 145, no service "
             & "brake (3.16.2.5.1.1 b)");
   end Scenario_Consistency_Reactions;

   --  Runs to To_Cm a cycle at a time: the error reports (136 with
   --  packet 4) sent on the way, their count and the last M_ERROR
   procedure Run_Errors (To_Cm : Integer_64; Count, Error : out Natural) is
      C, E : Natural;
   begin
      Count := 0;
      Error := 999;
      while Train_Cm < To_Cm loop
         Step_X (1_000);
         Balise_Error_Reports (0, C, E);
         Count := Count + C;
         if C > 0 then
            Error := E;
         end if;
      end loop;
   end Run_Errors;

   procedure Scenario_Consistency_Error_Report is
      Count, Error : Natural;
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, EVC_Modes.L2);
      Order_Session_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Add_Group (Group (20, 300));
      Track (2).Skip := 1;
      Add_Group (Group (30, 500));
      Track (3).Skip := 1;
      Track (3).Linked := False;
      Run_X (15_000);
      Establish_Session (1);
      Run_Errors (40_000, Count, Error);
      Check (Count = 1 and then Error = 1,
             "error report: a linked group's message inconsistent, "
             & "M_ERROR 1 (3.16.4.1, 3.16.2.4.4, 7.5.1.64), got"
             & Img (Count) & Img (Error));
      Run_Errors (60_000, Count, Error);
      Check (Count = 1 and then Error = 2,
             "error report: an unlinked group's message inconsistent, "
             & "M_ERROR 2 (3.16.4.1, 3.16.2.5.1), got"
             & Img (Count) & Img (Error));
   end Scenario_Consistency_Error_Report;

end EVC_Test_Consistency;
