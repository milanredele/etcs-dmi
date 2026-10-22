--  ETCS on-board (EVC)

with Interfaces;         use Interfaces;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Telegram;
with ETCS_Track_Packets.P15;
with ETCS_Track_Packets.P145;
with ETCS_Track_Packets.P16;
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
with EVC_Ports;
with EVC_Position;
with EVC_Radio_Authority;
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

   --  Group G's balise 0 carries packet 16, repositioning information
   --  valid in both directions
   procedure Carry_Repositioning (G : Positive) is
      W  : Writer_T;
      OK : Boolean;
      P  : ETCS_Track_Packets.P16.Packet_T;
   begin
      P.Q_DIR := 2;
      P.Q_SCALE := 1;
      P.L_SECTION := 100;
      ETCS_Track_Packets.P16.Encode (P, W, OK);
      Check (OK, "cross-talk: packet 16 encoded");
      Carry_Writer (G, 0, W);
   end Carry_Repositioning;

   --  3.16.2.7.2: group 10 at 100 m announces a repositioning group 500 m
   --  on (Locacc 50 m); group 55 at 520 m carries packet 16 and, with
   --  Link_57, the linking of group 57 20 m on; group Second, with packet
   --  16, at Second_M
   procedure Cross_Talk_Track (Second   : Natural;
                               Second_M : Integer_64;
                               Link_57  : Boolean := False) is
      L : T5.Packet_T := Link_To ((1 => 500), (1 => 16383), 50);
   begin
      L.D_LINK := 500;
      Start_X;
      SS_Seen := (others => 0);
      Add_Group (With_Links (Group (10, 100), L));
      if Link_57 then
         Add_Group (With_Links (Group (55, 520),
                                Link_To ((1 => 20), (1 => 57), 5, 2)));
         Add_Group (Group (57, 540));
      else
         Add_Group (Group (55, 520));
      end if;
      Carry_Repositioning (2);
      Add_Group (Group (Second, Second_M));
      Carry_Repositioning (Track_N);
   end Cross_Talk_Track;

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

   --  Runs to To_Cm a cycle at a time: the service brake seen on the way
   --  and the count of balise group error records (JRU 12)
   procedure Run_Records (To_Cm : Integer_64; SB : out Boolean;
                          Rec_12 : out Natural) is
   begin
      SB := False;
      Rec_12 := 0;
      while Train_Cm < To_Cm loop
         Step_X (1_000);
         if TIU_Out /= 16#FFFF# and then TIU_Out mod 256 / 2 mod 2 = 1 then
            SB := True;
         end if;
         Rec_12 := Rec_12 + JRU_Count (12);
      end loop;
   end Run_Records;

   --  3.16.2.4.3.1: linking checked, the expected group 20 announced with
   --  an unknown identity (NID_BG 16383) and against its nominal
   --  direction, its message inconsistent (balise Skip - 1 of Balises
   --  missed); the linking reaction the service brake
   procedure Unknown_Identity_Case (Skip, Balises : Positive;
                                    SB : out Boolean; Rec_12 : out Natural)
   is
   begin
      Start_X;
      SS_Seen := (others => 0);
      Add_Group (With_Links (Group (10, 100),
                             Link_To ((500, 400), (16383, 30), 5, 1,
                                      Nominal => False)));
      Add_Group (Group (20, 600, Balises));
      Track (2).Skip := Skip;
      Add_Group (Group (30, 1000));
      JRU_Last (4, 3) := 0;
      Run_Records (80_000, SB, Rec_12);
   end Unknown_Identity_Case;

   procedure Scenario_Unknown_Identity is
      SB     : Boolean;
      Rec_12 : Natural;
   begin
      --  balises 0 and 2 read: the group's own orientation, nominal,
      --  against the announced one, surely not the expected group
      Unknown_Identity_Case (2, 3, SB, Rec_12);
      Check (Rec_12 >= 1
             and then JRU_Last (4, 3) = EVC_Position.Cause_Not_Detected,
             "reactions: the expected group of unknown identity, an "
             & "inconsistent group crossed against the direction "
             & "announced, its error recorded, no reaction: the brake "
             & "comes when its window ends without it (3.16.2.4.3.1 a, "
             & "3.16.2.3.1 b), got" & Img (Rec_12) & Img (JRU_Last (4, 3)));
      --  balise 0 of 2 read: no orientation of its own, it may be the
      --  expected group
      Unknown_Identity_Case (2, 2, SB, Rec_12);
      Check (SB and then Rec_12 >= 1
             and then JRU_Last (4, 3) = EVC_Position.Cause_Inconsistent,
             "reactions: the expected group of unknown identity, an "
             & "inconsistent group without an orientation of its own, the "
             & "linking reaction (3.16.2.4.3.1 b)");
   end Scenario_Unknown_Identity;

   --  3.16.2.3.1.1: group 10 at 100 m announces 20 at 600 m (5 m, the
   --  service brake), to be passed in its nominal direction or not, and
   --  absent. The train runs 10 m a cycle (100 ms), the odometer giving
   --  V_Cms, until the missed group
   --  is found or it reaches Stand_At, then stands a cycle at a time;
   --  Missed_At its position when the group is found, Standing the
   --  cycles stood until then; With_MA: group 10 gives an MA to 2 km
   procedure Missed_Window (Nominal   : Boolean;
                            Stand_At  : Integer_64;
                            Missed_At : out Integer_64;
                            Standing  : out Natural;
                            V_Cms     : Unsigned_16 := 1000;
                            With_MA   : Boolean := False) is
   begin
      Start_X;
      Speed_Cms := V_Cms;
      Add_Group (With_Links (Group (10, 100),
                             Link_To ((1 => 500), (1 => 20), 5, 1,
                                      Nominal => Nominal)));
      if With_MA then
         Carry (1, 0, MA_Of ((1 => 2_000)));
         Carry (1, 0, Grad ((1 => (0, 0))));
         Carry (1, 0, SSP ((1 => (0, 100, False))));
      end if;
      Add_Group (Group (30, 1000));
      Missed_At := 0;
      Standing := 0;
      while Train_Cm < Stand_At and then Train_Cm < 100_000 loop
         Step_X (1_000);
         if EVC_Position.Missed_Group_Found then
            Missed_At := Train_Cm;
            Speed_Cms := 1000;
            return;
         end if;
      end loop;
      while Standing < 20 loop
         Standing := Standing + 1;
         Step_X (0);
         exit when EVC_Position.Missed_Group_Found;
      end loop;
      Missed_At := Train_Cm;
      Speed_Cms := 1000;
   end Missed_Window;

   procedure Scenario_Consistency_Reactions is
      SB : Boolean;
      Brake_Error : Natural renames
        SS_Seen (EVC_DMI_Port.SS_Balise_Read_Error_Brake);
      X, X_Stood, X_Rev : Integer_64;
      Stood, Stood_Rev  : Natural;
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
      Check (EVC_Position.LRBG.Id.NID_BG = 20
               and then EVC_Position.Linking.Expected = 2
               and then not EVC_Position.Linking_Reaction_Requested,
             "reactions: the duplicate of balise 0 the location reference "
             & "of the linked group, found inside its window, no linking "
             & "reaction (3.16.2.3.4, EVC_Balise_Groups.Geometry)");

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
      --  4.4.14.1.9, 4.4.18.1.10: in Post Trip and Reversing a message
      --  consistency error commands no service brake (Passive Shunting,
      --  4.4.20.1.15, is left for SH by this setup, which has no input
      --  for it)
      for M in EVC_Modes.Mode_T loop
         if EVC_Modes."=" (M, EVC_Modes.M_PT)
           or else EVC_Modes."=" (M, EVC_Modes.M_RV)
         then
            Inconsistent_Track (Linking => False, Linked => False);
            EVC_Core.Set_Mode_For_Test (M, EVC_Modes.L1);
            Run_Watch (80_000, SB);
            Check (Brake_Error = 0
                   and then JRU_Last (4, 3) = EVC_Position.Cause_Inconsistent
                   and then EVC_Modes."=" (EVC_Core.Mode, M),
                   "reactions: a message consistency error in "
                   & EVC_Modes.Mode_T'Image (M) & ", no service brake "
                   & "(4.4.14.1.9, 4.4.18.1.10), got"
                   & Img (Brake_Error) & Img (JRU_Last (4, 3))
                   & " " & EVC_Modes.Mode_T'Image (EVC_Core.Mode));
         end if;
      end loop;
      --  3.16.2.7.2: cross-talk while expecting repositioning
      Cross_Talk_Track (56, 580);
      Run_Watch (55_000, SB);
      Check (not SB and then EVC_Position.LRBG.Id.NID_BG = 55,
             "cross-talk: the repositioning group accepted in its window, "
             & "no reaction (3.4.4.4.2.1)");
      Run_Watch (80_000, SB);
      Check (SB and then Brake_Error >= 1
             and then JRU_Last (4, 3) = EVC_Position.Cause_Double_Repos,
             "cross-talk: a second group with packet 16 inside the window "
             & "of the repositioning group, the service brake and Balise "
             & "read error (3.16.2.7.2.1, 3.16.2.7.2.2)");
      Cross_Talk_Track (56, 720);
      Run_Watch (90_000, SB);
      Check (not SB,
             "cross-talk: the second group past the window, no reaction "
             & "(3.16.2.7.2.1 a)");
      Cross_Talk_Track (56, 580, Link_57 => True);
      Run_Watch (80_000, SB);
      Check (not SB,
             "cross-talk: the watch ended by the linked group 57 of known "
             & "identity, no reaction (3.16.2.7.2.1 b)");
      Scenario_Unknown_Identity;

      --  3.16.2.3.1.1 a): the window's end plus 1.3 m passed in the cycle
      --  before the missed group is found moving; standing there, it is
      --  found one cycle (100 ms) later, not in the cycle of the crossing
      Missed_Window (True, 1_000_000, X, Stood);
      Missed_Window (True, X - 1_000, X_Stood, Stood);
      Check (X > 60_000 and then X_Stood = X - 1_000 and then Stood = 1,
             "margin: the missed group found 100 ms after the min safe "
             & "antenna passed the window's end plus 1.3 m (3.16.2.3.1.1 "
             & "a), got" & Integer_64'Image (X) & Integer_64'Image (X_Stood)
             & Natural'Image (Stood));
      --  3.16.2.3.1.1 b): to be passed in reverse, Tn: at 10 m/s balises
      --  230 ms apart, 100 ms; at 100 m/s 23 ms apart, 100 + 7 x 77 =
      --  639 ms, seven cycles
      Missed_Window (False, X - 1_000, X_Rev, Stood_Rev);
      Check (X_Rev = X - 1_000 and then Stood_Rev = 1,
             "margin: in reverse at 10 m/s, Tn 100 ms (3.16.2.3.1.1 b), "
             & "got" & Natural'Image (Stood_Rev));
      Missed_Window (False, 1_000_000, X_Rev, Stood_Rev, 10_000);
      Check (X_Rev = X + 6_000,
             "margin: in reverse, found Tn after the crossing, moving "
             & "(3.16.2.3.1.1 b), got" & Integer_64'Image (X_Rev));
      Missed_Window (False, X - 1_000, X_Rev, Stood_Rev, 10_000);
      Check (X_Rev = X - 1_000 and then Stood_Rev = 7,
             "margin: in reverse, found Tn after the crossing, standing "
             & "(3.16.2.3.1.1 b), got" & Natural'Image (Stood_Rev));
      --  3.16.2.6.2: the service brake of the missed group's linking
      --  reaction, then standstill: the MA shortened to the train
      Missed_Window (True, 1_000_000, X, Stood, With_MA => True);
      Check (X > 60_000 and then EVC_Position.Linking_Reaction_Requested
             and then EVC_Position.Reaction = 1
             and then EVC_Movement_Authority.MA.Present
             and then not EVC_Movement_Authority.MA.Withdrawn,
             "linking reaction: the missed group's service brake, the MA "
             & "kept while moving (3.16.2.6.2)");
      Stand;
      Stand;
      Check (EVC_Movement_Authority.MA.Withdrawn,
             "linking reaction: at standstill the MA shortened to the "
             & "train (3.16.2.6.2, A.3.4.1.2 i), EVC_Stored_Information"
             & ".Linking_Shortening)");
   end Scenario_Consistency_Reactions;

   procedure Scenario_Consistency_Modes is
      SB : Boolean;
      Brake_Error : Natural renames
        SS_Seen (EVC_DMI_Port.SS_Balise_Read_Error_Brake);
   begin
      --  SR is not excepted from the message consistency reaction
      --  (4.4.11): a linked group's message inconsistent, linking not
      --  checked, the service brake (3.16.2.4.4)
      Inconsistent_Track (Linking => False);
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SR, EVC_Modes.L1);
      Run_Watch (80_000, SB);
      Check (SB and then Brake_Error >= 1
             and then EVC_Modes."=" (EVC_Core.Mode, EVC_Modes.M_SR),
             "consistency modes: in SR a linked group's message "
             & "inconsistent, the service brake and Balise read error "
             & "(3.16.2.4.4, 3.16.2.4.4.3)");
      --  an unlinked group's message inconsistent in SR (3.16.2.5.1)
      Inconsistent_Track (Linking => False, Linked => False);
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SR, EVC_Modes.L1);
      Run_Watch (80_000, SB);
      Check (SB and then Brake_Error >= 1,
             "consistency modes: in SR an unlinked group's message "
             & "inconsistent, the service brake (3.16.2.5.1)");
      --  the same in PT, excepted (4.4.14.1.9): its own brake only
      Inconsistent_Track (Linking => False);
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_PT, EVC_Modes.L1);
      Run_Watch (80_000, SB);
      Check (Brake_Error = 0
             and then EVC_Modes."=" (EVC_Core.Mode, EVC_Modes.M_PT),
             "consistency modes: in PT no service brake for an "
             & "inconsistent message, no Balise read error (4.4.14.1.9)");
      --  a linking reaction in SR, the expected group not found in its
      --  window: no service brake (3.16.2.6.2 keeps FS, AD, LS, OS, SM)
      Inconsistent_Track (Linking => True, Reaction => 1, Skip => 0);
      Track (2).At_Cm := 3_000_00;
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SR, EVC_Modes.L1);
      Run_Watch (80_000, SB);
      Check (not SB and then Brake_Error = 0
             and then EVC_Modes."=" (EVC_Core.Mode, EVC_Modes.M_SR),
             "consistency modes: in SR the linking reaction's service "
             & "brake not commanded (3.16.2.6.2)");
   end Scenario_Consistency_Modes;

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

   --  A message 3 of the RBC referred to the group NID_BG of the
   --  simulated track (NID_C 123): an MA of 2 km (packet 15), a flat
   --  gradient, a speed profile of 100 km/h and the linking L (packet 5)
   function Radio_Linked_MA (NID_BG : Natural; L : T5.Packet_T)
                             return EVC_Ports.Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
      P  : ETCS_Track_Packets.P15.Packet_T;
   begin
      V (3) := Radio_Now;
      V (5) := 123;
      V (6) := Unsigned_64 (NID_BG);
      Start_Message (W, ETCS_Message_Catalogue.Track_M3, V);
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.L_ENDSECTION := 2000;
      ETCS_Track_Packets.P15.Encode (P, W, OK);
      Check (OK, "error report: packet 15 encoded");
      T21.Encode (Grad ((1 => (0, 0))), W, OK);
      T27.Encode (SSP ((1 => (0, 100, False))), W, OK);
      Put (W, L);
      return Message_Bytes (W);
   end Radio_Linked_MA;

   procedure Scenario_Consistency_Error_Report is
      Count, Error, Rejected : Natural;
      Reason : Integer;
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
      --  linking by radio, no reaction: 20, 40 and 50 announced, absent
      Start_X;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, EVC_Modes.L2);
      Order_Session_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Add_Group (Group (30, 500));
      Run_X (15_000);
      Establish_Session_Acked (1);
      Rejected := EVC_Radio_Authority.Messages_Rejected;
      Give_Radio_Message
        (1, Radio_Linked_MA (10, Link_To ((200, 200, 200, 200),
                                          (20, 30, 40, 50), 5, 2)));
      Stand;
      Check (EVC_Radio_Authority.Messages_Rejected = Rejected,
             "error report: the message 3 with linking accepted in "
             & "level 2 (4.8.3, 4.8.4)");
      Run_Errors (45_000, Count, Error);
      Check (Count = 1 and then Error = 0,
             "error report: a linked group missed, M_ERROR 0 (3.16.4.1, "
             & "3.16.2.3.2), got" & Img (Count) & Img (Error));
      Run_Errors (80_000, Count, Error);
      Check (Count = 1 and then Error = 0,
             "error report: the next linked group missed, M_ERROR 0, got"
             & Img (Count) & Img (Error));
      Run_Errors (100_000, Count, Error);
      Check (Count = 1 and then Error = 7,
             "error report: two linked groups missed in a row, M_ERROR 7 "
             & "(3.16.4.1, 3.16.2.7.1), got" & Img (Count) & Img (Error));
      --  the service brake as reaction: at standstill the MA by radio
      --  shortened to the train
      Start_X;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, EVC_Modes.L2);
      Order_Session_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Run_X (15_000);
      Establish_Session_Acked (1);
      Give_Radio_Message
        (1, Radio_Linked_MA (10, Link_To ((200, 200), (20, 30), 5, 1)));
      Stand;
      Run_Errors (45_000, Count, Error);
      Check (Count = 1 and then Error = 0
             and then EVC_Movement_Authority.MA.Present
             and then not EVC_Movement_Authority.MA.Withdrawn,
             "error report: a linked group missed with the service brake, "
             & "M_ERROR 0, the MA kept while running, got"
             & Img (Count) & Img (Error));
      Wait_MA_Request (3_000, Reason);
      Check (EVC_Movement_Authority.MA.Withdrawn,
             "error report: in level 2 at standstill the MA by radio "
             & "shortened to the train (3.16.2.3.2, 3.16.2.6.2, "
             & "EVC_Stored_Information.Linking_Shortening)");
      Check (Reason >= 0 and then Reason / 8 mod 2 = 1,
             "error report: an MA requested after the shortening, "
             & "Q_MARQSTREASON track description deleted (3.8.2.5.1, "
             & "A.3.4 h), 7.5.1.118.3), got" & Reason'Image);
      --  a repositioning group announced by radio, a second one with
      --  packet 16 inside its window: the double repositioning error
      Start_X;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, EVC_Modes.L2);
      Order_Session_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Add_Group (Group (55, 520));
      Carry_Repositioning (Track_N);
      Add_Group (Group (56, 580));
      Carry_Repositioning (Track_N);
      Run_X (15_000);
      Establish_Session_Acked (1);
      Give_Radio_Message
        (1, Radio_Linked_MA (10, Link_To ((1 => 500), (1 => 16383), 50, 2)));
      Stand;
      Run_Errors (55_000, Count, Error);
      Check (Count = 0,
             "error report: the repositioning group accepted, none, got"
             & Img (Count) & Img (Error));
      Run_Errors (70_000, Count, Error);
      Check (Count = 1 and then Error = 8,
             "error report: a second group with the criteria of the "
             & "repositioning group in its window, M_ERROR 8 (3.16.4.1, "
             & "3.16.2.7.2, 7.5.1.64), got" & Img (Count) & Img (Error));
      --  the odometer accuracy monitoring: 6 % reaches the impairment
      --  threshold at 4200 m, then 35 % from 5000 m the safety threshold
      --  once the window's accumulated amounts reach it
      Start_X;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, EVC_Modes.L2);
      Order_Session_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Run_X (15_000);
      Establish_Session (1);
      Bound_Per_Mille := 60;
      Run_Errors (415_000, Count, Error);
      Check (Count = 0,
             "error report: the odometer within its accuracy, none, got"
             & Img (Count) & Img (Error));
      Run_Errors (500_000, Count, Error);
      Check (Count = 1 and then Error = 9,
             "error report: the odometer impaired, M_ERROR 9 once "
             & "(3.16.4.1, 3.6.8.5, 3.6.5.1.4 l), 7.5.1.64), got"
             & Img (Count) & Img (Error));
      Bound_Per_Mille := 350;
      Run_Errors (1_000_000, Count, Error);
      Check (Count = 1 and then Error = 10,
             "error report: the odometer's safety threshold, M_ERROR 10 "
             & "(3.16.4.1, 3.6.8.7, 7.5.1.64), got"
             & Img (Count) & Img (Error));
      --  3.16.4.3: linking checked (20 and 30 announced by radio), group
      --  25 between them marked linked and not in the linking
      --  information: no error report, nor for 20 and 30 found
      Start_X;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, EVC_Modes.L2);
      Order_Session_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Add_Group (Group (20, 300));
      Add_Group (Group (25, 400));
      Add_Group (Group (30, 500));
      Run_X (15_000);
      Establish_Session_Acked (1);
      Give_Radio_Message
        (1, Radio_Linked_MA (10, Link_To ((200, 200), (20, 30), 5, 1)));
      Stand;
      Run_Errors (60_000, Count, Error);
      Check (Count = 0 and then EVC_Position.LRBG.Id.NID_BG = 30,
             "error report: linking checked, a group marked linked and "
             & "not in the linking information, no error report "
             & "(3.16.4.3), got" & Img (Count) & Img (Error)
             & Img (Natural (EVC_Position.LRBG.Id.NID_BG)));
   end Scenario_Consistency_Error_Report;

   --  The JRU records of the last Take of a balise group error
   --  (SUBSET-027 4.2.4.12, NID_BG_Error)
   function BG_Errors return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. Rec_Count loop
         if EVC_Ports."=" (Recs (I).Port, EVC_Ports.JRU)
           and then JRU_NID (I) = NID_BG_Error
         then
            N := N + 1;
         end if;
      end loop;
      return N;
   end BG_Errors;

   --  Runs a mode set for the test over Inconsistent_Track with group 20
   --  unlinked, balise 0 of 2 missed, to 1100 m: the records of an
   --  unlinked group's inconsistent message (the event 13 and the
   --  balise group errors), the service brake, the
   --  Balise read error seen, and the LRBG at the end
   --  (group 20 of Balises balises, its balise 0 detected without a
   --  decoded telegram when Detect)
   procedure Run_Unlinked (Mode : EVC_Modes.Mode_T;
                           Rec_13, Rec_Paired : out Natural;
                           SB, Read_Error : out Boolean;
                           Balises : Positive := 2;
                           Detect  : Boolean := False) is
   begin
      Inconsistent_Track (Linking => False, Linked => False,
                          Balises => Balises);
      Track (2).Detect_Skip := Detect;
      if EVC_Modes."=" (Mode, EVC_Modes.M_PS) then
         --  4.6.3 [26]: the desk closed with the passive shunting
         --  input on, as PS is left when the desk opens
         Input (EVC_Ports.TIU,
                (Unsigned_8 (EVC_Ports.TIU_Signal_T'Pos
                               (EVC_Ports.Passive_Shunting_Permitted) + 1),
                 1));
         Input (EVC_Ports.TIU,
                (Unsigned_8 (EVC_Ports.TIU_Signal_T'Pos
                               (EVC_Ports.Cab_A_Active) + 1),
                 0));
      end if;
      EVC_Core.Set_Mode_For_Test (Mode, EVC_Modes.L1);
      Rec_13 := 0;
      Rec_Paired := 0;
      SB := False;
      while Train_Cm < 110_000 loop
         Step_X (1_000);
         if TIU_Out /= 16#FFFF# and then TIU_Out mod 256 / 2 mod 2 = 1 then
            SB := True;
         end if;
         Rec_13 := Rec_13 + JRU_Count (13);
         Rec_Paired := Rec_Paired + BG_Errors;
      end loop;
      Read_Error := SS_Seen (EVC_DMI_Port.SS_Balise_Read_Error_Brake) > 0;
   end Run_Unlinked;

   procedure Scenario_Consistency_NL is
      SB, Read_Error     : Boolean;
      Rec_13, Rec_Paired : Natural;
   begin
      --  4.4.15.1.10: in Non Leading the balise group's inconsistent
      --  message is rejected and recorded (3.16.2.5.1.1 b), the event 13
      --  with the balise group error of M_ERROR 2, SUBSET-027 4.2.4.12),
      --  without the service brake; the next consistent group is taken
      Run_Unlinked (EVC_Modes.M_NL, Rec_13, Rec_Paired, SB, Read_Error);
      Check (Rec_13 >= 1 and then Rec_Paired >= 1 and then not SB
             and then not Read_Error
             and then EVC_Modes."=" (EVC_Core.Mode, EVC_Modes.M_NL)
             and then EVC_Position.LRBG.Id.NID_BG = 30,
             "consistency NL: an unlinked group's inconsistent message "
             & "recorded (JRU 12, M_ERROR 2), no service brake, the next "
             & "group taken (4.4.15.1.10, 3.16.2.5.1.1 b), got"
             & Img (Rec_13) & Img (Rec_Paired)
             & Img (Natural (EVC_Position.LRBG.Id.NID_BG)));
      --  4.4.20.1.15: the same in Passive Shunting
      Run_Unlinked (EVC_Modes.M_PS, Rec_13, Rec_Paired, SB, Read_Error);
      Check (Rec_13 >= 1 and then Rec_Paired >= 1 and then not SB
             and then not Read_Error
             and then EVC_Modes."=" (EVC_Core.Mode, EVC_Modes.M_PS)
             and then EVC_Position.LRBG.Id.NID_BG = 30,
             "consistency PS: an unlinked group's inconsistent message "
             & "recorded (JRU 12, M_ERROR 2), no service brake, the next "
             & "group taken (4.4.20.1.15, 3.16.2.5.1.1 b), got"
             & Img (Rec_13) & Img (Rec_Paired)
             & Img (Natural (EVC_Position.LRBG.Id.NID_BG)) & " "
             & EVC_Modes.Mode_T'Image (EVC_Core.Mode));
   end Scenario_Consistency_NL;

   --  3.16.2.4.1 b), 3.16.2.4.4 b), 3.16.2.5.1 b), 3.16.2.2.1: a balise
   --  detected without a decoded telegram (the BTM's detection record,
   --  EVC_Ports), in a group of two and alone
   procedure Scenario_Consistency_Undecoded is
      SB, Read_Error     : Boolean;
      Rec_13, Rec_Paired : Natural;
      Count, Error       : Natural;
      Brake_Error : Natural renames
        SS_Seen (EVC_DMI_Port.SS_Balise_Read_Error_Brake);
   begin
      --  linking checked, the expected group's balise 1 not decoded: the
      --  linking reaction, the service brake
      Inconsistent_Track (Linking => True, Reaction => 1, Skip => 2);
      Track (2).Detect_Skip := True;
      Run_Watch (80_000, SB);
      Check (SB and then Brake_Error >= 1,
             "undecoded: the expected group's balise 1 detected, its "
             & "telegram not decoded, the linking reaction (3.16.2.4.1 b)");
      --  linking not checked, a linked group, balise 0 not decoded
      --  before balise 1 is read: the service brake
      Inconsistent_Track (Linking => False, Skip => 1);
      Track (2).Detect_Skip := True;
      Run_Watch (80_000, SB);
      Check (SB and then Brake_Error >= 1,
             "undecoded: linking not checked, a linked group's balise 0 "
             & "detected and not decoded, the service brake "
             & "(3.16.2.4.4 b)");
      --  the balise not decoded duplicated by balise 1, read: no reaction
      Inconsistent_Track (Linking => False, Skip => 1);
      Track (2).Detect_Skip := True;
      Track (2).Dup_1_2 := True;
      Run_Watch (80_000, SB);
      Check (not SB and then Brake_Error = 0
             and then EVC_Position.LRBG.Id.NID_BG = 20,
             "undecoded: the balise not decoded duplicated by the one "
             & "read, no reaction, the message taken (3.16.2.4.4.1 a)");
      --  an unlinked group of two, balise 0 not decoded: the service brake
      Run_Unlinked (EVC_Modes.M_FS, Rec_13, Rec_Paired, SB, Read_Error,
                    Detect => True);
      Check (SB and then Rec_13 >= 1 and then Rec_Paired >= 1,
             "undecoded: an unlinked group's balise 0 detected and not "
             & "decoded, the service brake, recorded (3.16.2.5.1 b)");
      --  a group of one balise detected and not decoded: none of its
      --  balises read, unlinked (3.16.2.2.1), its message inconsistent
      Run_Unlinked (EVC_Modes.M_FS, Rec_13, Rec_Paired, SB, Read_Error,
                    Balises => 1, Detect => True);
      Check (SB and then Read_Error and then Rec_13 >= 1
             and then Rec_Paired >= 1
             and then EVC_Position.LRBG.Id.NID_BG = 30,
             "undecoded: a group of one balise detected and not decoded "
             & "in FS, unlinked, the service brake and the record 12 "
             & "(3.16.2.2.1, 3.16.2.5.1 b), got" & Img (Rec_13)
             & Img (Rec_Paired));
      Run_Unlinked (EVC_Modes.M_NL, Rec_13, Rec_Paired, SB, Read_Error,
                    Balises => 1, Detect => True);
      Check (not SB and then Rec_13 >= 1 and then Rec_Paired >= 1,
             "undecoded: a group of one balise not decoded in NL, "
             & "recorded, no service brake (4.4.15.1.10, 3.16.2.5.1 b)");
      Run_Unlinked (EVC_Modes.M_PS, Rec_13, Rec_Paired, SB, Read_Error,
                    Balises => 1, Detect => True);
      Check (not SB and then Rec_13 >= 1 and then Rec_Paired >= 1
             and then EVC_Modes."=" (EVC_Core.Mode, EVC_Modes.M_PS),
             "undecoded: a group of one balise not decoded in PS, "
             & "recorded, no service brake (4.4.20.1.15, 3.16.2.5.1 b)");
      --  3.16.4.1: reported to the RBC, M_ERROR 2
      Start_X;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, EVC_Modes.L2);
      Order_Session_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Add_Group (Group (20, 400, 1));
      Track (2).Skip := 1;
      Track (2).Detect_Skip := True;
      Add_Group (Group (30, 700));
      Run_X (15_000);
      Establish_Session (1);
      Run_Errors (60_000, Count, Error);
      Check (Count = 1 and then Error = 2,
             "undecoded: a group of one balise not decoded reported to "
             & "the RBC, M_ERROR 2 (3.16.4.1, 3.16.2.5.1 b), got"
             & Img (Count) & Img (Error));
   end Scenario_Consistency_Undecoded;

end EVC_Test_Consistency;
