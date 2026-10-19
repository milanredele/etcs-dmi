--  ETCS on-board (EVC)

with Interfaces;         use Interfaces;
with ETCS_Telegram;
with ETCS_Track_Packets.P254;
with DMI_Protocol;
with EVC_Bytes;
with EVC_DMI_Port;
with ETCS_Variables;    use ETCS_Variables;
with EVC_Balise_Groups; use EVC_Balise_Groups;
with EVC_JRU_Messages;  use EVC_JRU_Messages;
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

end EVC_Test_Consistency;
