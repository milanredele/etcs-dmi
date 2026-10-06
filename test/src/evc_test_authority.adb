--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half (see the specification).

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P15;
with ETCS_Track_Packets.P49;
with ETCS_Track_Packets.P57;
with ETCS_Track_Packets.P63;
with ETCS_Variables;
with EVC_Core;
with EVC_Distances;
with EVC_DMI_Port;
with EVC_Ports;              use EVC_Ports;
with EVC_Modes;              use EVC_Modes;
with EVC_Levels;
with EVC_Procedures;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_SDM;
with EVC_Stored_Information;
with EVC_Test_Support;       use EVC_Test_Support;
with Interfaces;             use Interfaces;

package body EVC_Test_Authority is

   package MCat renames ETCS_Message_Catalogue;
   package SI renames EVC_Stored_Information;
   package T15 renames ETCS_Track_Packets.P15;
   package T57 renames ETCS_Track_Packets.P57;
   package T63 renames ETCS_Track_Packets.P63;
   package T49 renames ETCS_Track_Packets.P49;
   package RA renames EVC_Radio_Authority;
   use type MCat.Message_Kind_T;
   use type EVC_SDM.Status_T;
   use type SIn.Release_Speed_Kind_T;
   use type EVC_Distances.Cm_T;
   use type Byte_Array;

   ---------------------------------------------------------------------
   --  Helpers
   ---------------------------------------------------------------------

   --  The RBC acknowledges (message 8) the Train Data the session half
   --  sends (129, 3.18.3.4, repeated every 15 s): 4.8.3 [3] rejects the
   --  authorisations of the RBC before
   procedure Ack_Train_Data is
      M  : ETCS_Message.Message_T;
      St : ETCS_Message.Status_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      use type ETCS_Message.Status_T;
   begin
      for C in 1 .. 160 loop
         Stand_X (100);
         for N in 1 .. Radio_Outputs loop
            Decode_Radio_Message (N, M, St);
            if St = ETCS_Message.Accepted
              and then M.Kind = MCat.Train_M129
            then
               V (3) := Unsigned_64 (EVC_Radio.T_Train_At
                                       (Unsigned_64 (EVC_Core.Time_Ms)));
               --  the second T_TRAIN is the seventh value (NID_LRBG is two)
               V (7) := M.Values (3);
               Give_Radio_Message (1, Message_Of (MCat.Track_M8, V));
               Stand_X (100);
               return;
            end if;
         end loop;
      end loop;
   end Ack_Train_Data;

   --  The session half's part, put through the writers of EVC_Radio: an
   --  established session 1 with the Supervising RBC (3.5.3.7 d, 3.15.1),
   --  the Train Data acknowledged
   procedure Establish is
   begin
      EVC_Radio.Set_Peer (1, (NID_C => 123, NID_RBC => 1), 0);
      EVC_Radio.Set_State (1, EVC_Radio.Established);
      EVC_Radio.Set_Version (1, 33);
      EVC_Radio.Set_Roles (1, EVC_Radio.No_Session);
      Ack_Train_Data;
   end Establish;

   --  The on-board's T_TRAIN Ago_Ms before now (a time stamp, 3.16.3.1)
   function Stamp (Ago_Ms : Natural := 0) return ETCS_Variables.T_TRAIN_T is
     (EVC_Radio.T_Train_At
        (Unsigned_64 (EVC_Core.Time_Ms) - Unsigned_64 (Ago_Ms)));

   --  Packet 15 with the variables of a packet 12 (7.4.2.4, 7.4.2.5)
   function To_P15 (X : T12.Packet_T) return T15.Packet_T is
      Y : T15.Packet_T;
   begin
      Y.Q_DIR := X.Q_DIR;
      Y.Q_SCALE := X.Q_SCALE;
      Y.V_EMA := X.V_EMA;
      Y.T_EMA := X.T_EMA;
      Y.N_ITER := X.N_ITER;
      for I in Y.L_SECTION_List'Range loop
         Y.L_SECTION_List (I) :=
           (L_SECTION             => X.L_SECTION_List (I).L_SECTION,
            Q_SECTIONTIMER        => X.L_SECTION_List (I).Q_SECTIONTIMER,
            Has_T_SECTIONTIMER    =>
              X.L_SECTION_List (I).Has_T_SECTIONTIMER,
            T_SECTIONTIMER        => X.L_SECTION_List (I).T_SECTIONTIMER,
            D_SECTIONTIMERSTOPLOC =>
              X.L_SECTION_List (I).D_SECTIONTIMERSTOPLOC);
      end loop;
      Y.L_ENDSECTION := X.L_ENDSECTION;
      Y.Q_SECTIONTIMER := X.Q_SECTIONTIMER;
      Y.Has_T_SECTIONTIMER := X.Has_T_SECTIONTIMER;
      Y.T_SECTIONTIMER := X.T_SECTIONTIMER;
      Y.D_SECTIONTIMERSTOPLOC := X.D_SECTIONTIMERSTOPLOC;
      Y.Q_ENDTIMER := X.Q_ENDTIMER;
      Y.Has_T_ENDTIMER := X.Has_T_ENDTIMER;
      Y.T_ENDTIMER := X.T_ENDTIMER;
      Y.D_ENDTIMERSTARTLOC := X.D_ENDTIMERSTARTLOC;
      Y.Q_DANGERPOINT := X.Q_DANGERPOINT;
      Y.Has_D_DP := X.Has_D_DP;
      Y.D_DP := X.D_DP;
      Y.V_RELEASEDP := X.V_RELEASEDP;
      Y.Q_OVERLAP := X.Q_OVERLAP;
      Y.Has_D_STARTOL := X.Has_D_STARTOL;
      Y.D_STARTOL := X.D_STARTOL;
      Y.T_OL := X.T_OL;
      Y.D_OL := X.D_OL;
      Y.V_RELEASEOL := X.V_RELEASEOL;
      return Y;
   end To_P15;

   --  Message 3 (or 33, shifted by Shift_M metres) referring to the
   --  group NID_BG of country 123, with the MA X, an SSP and a gradient
   --  (Kind 9: the MA alone)
   function MA_Message (NID_BG  : Natural;
                        X       : T12.Packet_T;
                        T_Train : ETCS_Variables.T_TRAIN_T;
                        Shift_M : Integer := 0;
                        Kind    : MCat.Known_Message_T := MCat.Track_M3;
                        With_57 : Boolean := False;
                        P57     : T57.Packet_T := (others => <>))
     return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
      S  : constant T27.Packet_T := SSP ((1 => (0, 100, False)));
      G  : constant T21.Packet_T := Grad ((1 => (0, 0)));
   begin
      V (3) := Unsigned_64 (T_Train);
      V (5) := 123;
      V (6) := Unsigned_64 (NID_BG);
      if Kind = MCat.Track_M33 then
         V (7) := 1;
         V (8) := ETCS_Variables.Code (ETCS_Variables.D_REF_T (Shift_M));
      end if;
      Start_Message (W, Kind, V);
      T15.Encode (To_P15 (X), W, OK);
      Check (OK, "authority: packet 15 encoded");
      if Kind /= MCat.Track_M9 then
         T21.Encode (G, W, OK);
         Check (OK, "authority: packet 21 encoded");
         T27.Encode (S, W, OK);
         Check (OK, "authority: packet 27 encoded");
      end if;
      if With_57 then
         T57.Encode (P57, W, OK);
         Check (OK, "authority: packet 57 encoded");
      end if;
      return Message_Bytes (W);
   end MA_Message;

   --  A level 2 start: the track of EVC_Test_Support, level 2 and FS by
   --  the test entry of the core, a group 10 at 100 m (the LRBG once
   --  passed), the session established
   procedure Start_L2 is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, L2);
      Add_Group (Group (10, 100));
      Establish;
   end Start_L2;

   procedure Establish_Session renames Establish;

   function Radio_MA (NID_BG  : Natural;
                      Lengths : EVC_Test_Support.Nat_List)
     return EVC_Bytes.Byte_Array is
     (MA_Message (NID_BG, MA_Of (Lengths), Stamp));

   ---------------------------------------------------------------------
   --  Scenarios
   ---------------------------------------------------------------------

   --  3.8 by radio: message 3 with the level 2 MA (packet 15), its SSP and
   --  gradient, referred to the LRBG it names (3.6.2.2.2 c), supervised to
   --  its EOA like the same MA given in level 1 by packet 12 with the same
   --  SSP and gradient from the same group (the supervision results
   --  agree); [31] holds in level 2 with the MA on-board. An MA referring
   --  to a group the on-board did not report is refused. The section
   --  timer of a radio MA starts at the time stamp of the message
   --  (3.8.4.2.1 a).
   procedure Scenario_Radio_MA is
      M        : constant T12.Packet_T := MA_Of ((300, 400), 600);
      EOA_1    : Integer_64;
      SvL_1    : Integer_64;
      R_1      : EVC_SDM.Result_T;
      R_2      : EVC_SDM.Result_T;
      Timed    : T12.Packet_T := MA_Of ((300, 400), 600);
   begin
      --  level 1, packet 12 from the group
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 1, M);
      Run_X (11_000);
      Run_X (30_000);
      EOA_1 := Integer_64 (SI.Current.MA.EOA);
      SvL_1 := Integer_64 (SI.Current.MA.SvL);
      R_1 := EVC_Core.Supervision;
      Check (SI.Current.MA.Present and then EOA_1 = 80_000,
             "authority: level 1 reference, the MA of packet 12");

      --  level 2, message 3 once the group is passed
      Start_L2;
      Run_X (11_000);
      Check (not SI.Current.MA.Present
             and then not RA.MA_On_Board_Level_2,
             "authority: level 2, no MA yet, [31] does not hold");
      Give_Radio_Message (1, MA_Message (10, M, Stamp));
      Run_X (30_000);
      R_2 := EVC_Core.Supervision;
      Check (SI.Current.MA.Present
             and then Integer_64 (SI.Current.MA.EOA) = EOA_1
             and then Integer_64 (SI.Current.MA.SvL) = SvL_1
             and then RA.Radio_MAs_Accepted = 1,
             "authority: the MA of message 3 has the EOA and SvL of the "
             & "same MA by packet 12 (3.8.3, 3.6.2.2.2 c)");
      Check (R_2.V_Perm = R_1.V_Perm and then R_2.D_Target = R_1.D_Target
             and then R_2.Status = R_1.Status
             and then R_2.V_SBI = R_1.V_SBI,
             "authority: the supervision of the radio MA agrees with the "
             & "level 1 one (3.13)");
      Check (RA.MA_On_Board_Level_2,
             "authority: [31] MA, SSP and gradient on-board, level 2");
      Run_X (79_000, 500);
      Stand_X (2_000);
      Check (EVC_Core.Supervision.EOA_Passed = False
             and then Integer_64 (SI.Current.MA.EOA) = EOA_1,
             "authority: the train stops before the EOA of the radio MA");

      --  an LRBG the on-board does not know (3.6.2.2.2 c)
      Start_L2;
      Run_X (11_000);
      Give_Radio_Message (1, MA_Message (99, M, Stamp));
      Run_X (12_000);
      Check (not SI.Current.MA.Present and then RA.Radio_MAs_Accepted = 0,
             "authority: an MA referring to a group not reported is "
             & "refused (3.6.2.2.2 c)");

      --  3.8.4.2.1 a): the section timer from the time stamp, 5 s old
      Timed.Q_SECTIONTIMER := 1;
      Timed.Has_T_SECTIONTIMER := True;
      Timed.T_SECTIONTIMER := 20;
      Timed.D_SECTIONTIMERSTOPLOC := 50;
      Start_L2;
      Run_X (11_000);
      Stand_X (6_000);
      Give_Radio_Message (1, MA_Message (10, Timed, Stamp (5_000)));
      Stand_X (14_000);
      Check (SI.Current.MA.Present and then SI.Current.MA.EOA = 80_000,
             "authority: the section timer of the radio MA running");
      Stand_X (1_500);
      Check (SI.Current.MA.EOA = 40_000
             and then SI.Current.MA.Release_Speed.Kind = SIn.Fixed,
             "authority: the section timer started at the time stamp of "
             & "the message, expired 5 s before 20 s after its reception "
             & "(3.8.4.2.1 a)");
   end Scenario_Radio_MA;

   --  Message 33: the location reference shifted by D_REF from the LRBG
   --  along its nominal direction (7.5.1.17, 3.6.4.2.3)
   procedure Scenario_Radio_MA_Shifted is
      M : constant T12.Packet_T := MA_Of ((300, 400), 600);
   begin
      Start_L2;
      Run_X (11_000);
      Give_Radio_Message
        (1, MA_Message (10, M, Stamp, 5, MCat.Track_M33));
      Run_X (12_000);
      Check (SI.Current.MA.Present and then SI.Current.MA.EOA = 80_500,
             "authority: message 33, the MA 5 m further (D_REF; its SSP and "
             & "gradient from the shifted reference cover the train, 3.7.2.3)");
      Give_Radio_Message
        (1, MA_Message (10, M, Stamp, -20, MCat.Track_M33));
      Run_X (13_000);
      Check (SI.Current.MA.Present and then SI.Current.MA.EOA = 78_000
             and then RA.Radio_MAs_Accepted = 2,
             "authority: message 33 with a negative D_REF, the MA "
             & "replaced and shortened (3.8.5.1, 3.8.5.1.3)");
   end Scenario_Radio_MA_Shifted;

   --  The NID_MESSAGE of the first train to track message among the RTM
   --  outputs of the last Take whose NID_MESSAGE is 137 or 138, with its
   --  T_TRAIN_2 (the request's time stamp); 0 when there is none
   procedure Shortening_Answer (NID : out Natural; Stamp : out Unsigned_64)
   is
      M : ETCS_Message.Message_T;
      S : ETCS_Message.Status_T;
      use type ETCS_Message.Status_T;
   begin
      NID := 0;
      Stamp := 0;
      for N in 1 .. Radio_Outputs loop
         Decode_Radio_Message (N, M, S);
         if S = ETCS_Message.Accepted
           and then M.Kind in MCat.Train_M137 | MCat.Train_M138
         then
            NID := (if M.Kind = MCat.Train_M137 then 137 else 138);
            Stamp := M.Values (5);
            return;
         end if;
      end loop;
   end Shortening_Answer;

   --  Stand until the on-board sends an MA request (at most Max_Ms);
   --  True when one was sent: the last Take holds it
   function Wait_Request (Max_Ms : Natural) return Boolean is
      N : constant Natural := RA.MA_Requests_Sent;
   begin
      for I in 1 .. Max_Ms / 100 loop
         Stand_X (100);
         if RA.MA_Requests_Sent > N then
            return True;
         end if;
      end loop;
      return False;
   end Wait_Request;

   --  Q_MARQSTREASON of the message 132 among the RTM outputs of the
   --  last Take, -1 when there is none
   function Request_Reason return Integer is
      M : ETCS_Message.Message_T;
      S : ETCS_Message.Status_T;
      use type ETCS_Message.Status_T;
   begin
      for N in 1 .. Radio_Outputs loop
         Decode_Radio_Message (N, M, S);
         if S = ETCS_Message.Accepted and then M.Kind = MCat.Train_M132
         then
            return Integer (ETCS_Message.Value
                              (M, ETCS_Variables.Q_MARQSTREASON));
         end if;
      end loop;
      return -1;
   end Request_Reason;

   --  3.8.2: the MA request (message 132 with its position report) by
   --  its triggers in level 2 with the session established: the driver's
   --  Start (3.8.2.3, reason 1), the time before a section timer expires
   --  with the parameters of packet 57 (3.8.2.2.1 b, reason 4), the
   --  repetition every T_CYCRQST while a reason holds (3.8.2.1.5), the
   --  track description deleted by the section time-out (3.8.2.5,
   --  reason 8, which resets the cycle, 3.8.2.1.6); nothing in level 1
   procedure Scenario_MA_Request is
      Timed : T12.Packet_T := MA_Of ((300, 400), 600);
      P57   : T57.Packet_T;
   begin
      --  Start, without parameters: the reason holds until an MA
      Start_L2;
      Input (DMI, (16#40#, 3, 0, 0, 0, 5, 0, 0));
      Check (Wait_Request (500) and then Request_Reason = 1
             and then RA.MA_Request_Reasons = 1,
             "MA request: 'Start' selected, message 132 with reason 1 "
             & "(3.8.2.3.1, 3.8.2.1.7)");
      Run_X (11_000);
      Give_Radio_Message (1, MA_Message (10, Timed, Stamp));
      Stand_X (200);
      Check (RA.MA_Request_Reasons = 0,
             "MA request: the reason 'Start' ends with the MA "
             & "(3.8.2.3.2 a)");

      --  a section timer of 30 s (not the End Section's), T_TIMEOUTRQST
      --  10 s, T_CYCRQST 4 s
      Timed.L_SECTION_List (1).Q_SECTIONTIMER := 1;
      Timed.L_SECTION_List (1).Has_T_SECTIONTIMER := True;
      Timed.L_SECTION_List (1).T_SECTIONTIMER := 30;
      Timed.L_SECTION_List (1).D_SECTIONTIMERSTOPLOC := 250;
      P57.T_MAR := 255;
      P57.T_TIMEOUTRQST := 10;
      P57.T_CYCRQST := 4;
      Start_L2;
      Run_X (11_000);
      Give_Radio_Message
        (1, MA_Message (10, Timed, Stamp, With_57 => True, P57 => P57));
      Check (not Wait_Request (19_000),
             "MA request: none before the time before the section timer");
      Check (Wait_Request (1_500) and then Request_Reason = 4,
             "MA request: 10 s before the section time-out, reason 4 "
             & "(3.8.2.2.1 b, 3.8.2.2.2)");
      Check (not Wait_Request (3_500) and then Wait_Request (1_000)
             and then Request_Reason = 4,
             "MA request: repeated every T_CYCRQST (3.8.2.1.5)");
      Stand_X (4_500);
      Check (Wait_Request (2_500) and then Request_Reason = 8,
             "MA request: the section time-out deleted track description, "
             & "reason 8 at once (3.8.2.5.1, 3.8.2.1.6)");

      --  level 1: none
      Start_X;
      Establish;
      Input (DMI, (16#40#, 3, 0, 0, 0, 5, 0, 0));
      Check (not Wait_Request (500) and then RA.MA_Request_Reasons = 0,
             "MA request: only in level 2 (3.8.2.1.1)");
   end Scenario_MA_Request;

   --  3.8.6: the co-operative shortening of the MA (message 9), at
   --  standstill at 200 m with an MA to 800 m. A proposed EOA behind the
   --  front end: the front end is in advance of its Indication limit,
   --  the request is rejected (138 with the request's time stamp, 8.6.6)
   --  and the MA stays (3.8.6.1 b). A proposed EOA at 400 m: granted (137,
   --  8.6.5), the proposed MA replaces the MA. In level 1: rejected
   --  (3.8.6, Level 2 only).
   procedure Scenario_Shortening is
      M     : constant T12.Packet_T := MA_Of ((300, 400), 600);
      NID   : Natural;
      T9    : ETCS_Variables.T_TRAIN_T;
      Got   : Unsigned_64;
   begin
      Start_L2;
      Run_X (11_000);
      Give_Radio_Message (1, MA_Message (10, M, Stamp));
      Run_X (20_000);
      Stand_X (2_000);
      Check (SI.Current.MA.Present and then SI.Current.MA.EOA = 80_000,
             "shortening: the MA to 800 m, the train standing at 200 m");

      T9 := Stamp;
      Give_Radio_Message
        (1, MA_Message (10, MA_Of ((20, 30)), T9, Kind => MCat.Track_M9));
      Stand_X (100);
      Shortening_Answer (NID, Got);
      Check (NID = 138 and then Got = Unsigned_64 (T9)
             and then RA.Shortenings_Rejected = 1
             and then RA.Shortenings_Granted = 0,
             "shortening: a proposed EOA (150 m) behind the front end, in "
             & "advance of its Indication limit: rejected, message 138 with "
             & "the request's time stamp (3.8.6.1 b, c; 8.6.6)");
      Stand_X (500);
      Check (SI.Current.MA.Present and then SI.Current.MA.EOA = 80_000,
             "shortening: rejected, the MA unchanged (3.8.6.1 b)");

      Stand_X (1_000);
      T9 := Stamp;
      Give_Radio_Message
        (1, MA_Message (10, MA_Of ((200, 100)), T9, Kind => MCat.Track_M9));
      Stand_X (100);
      Shortening_Answer (NID, Got);
      Check (NID = 137 and then Got = Unsigned_64 (T9)
             and then RA.Shortenings_Granted = 1,
             "shortening: a proposed EOA at 400 m, the front end in rear of "
             & "its Indication limit: granted, message 137 (3.8.6.1 b, c; "
             & "8.6.5)");
      Stand_X (200);
      Check (SI.Current.MA.Present and then SI.Current.MA.EOA = 40_000
             and then RA.Radio_MAs_Accepted = 2,
             "shortening: granted, the proposed MA is the MA (3.8.6.1 b)");

      --  level 1
      Start_X;
      Establish;
      Add_Group (Group (10, 100));
      Run_X (11_000);
      Give_Radio_Message
        (1, MA_Message (10, MA_Of ((200, 100)), Stamp, Kind => MCat.Track_M9));
      Stand_X (100);
      Shortening_Answer (NID, Got);
      Check (NID = 138 and then not SI.Current.MA.Present,
             "shortening: in level 1, rejected (3.8.6, Level 2 only)");
   end Scenario_Shortening;

   --  Message 15 (NID_EM, a stop D_M metres beyond the group NID_BG,
   --  both directions), 16 or 18 for NID_EM
   function Emergency_Message (Kind   : MCat.Known_Message_T;
                               NID_EM : Natural;
                               D_M    : Natural := 0) return Byte_Array
   is
      W : Writer_T;
      V : ETCS_Message.Value_Array := (others => 0);
   begin
      V (3) := Unsigned_64 (Stamp);
      V (5) := 123;
      V (6) := 10;
      V (7) := Unsigned_64 (NID_EM);
      if Kind = MCat.Track_M15 then
         V (8) := 1;
         V (10) := 2;
         V (11) := Unsigned_64 (D_M);
      end if;
      Start_Message (W, Kind, V);
      return Message_Bytes (W);
   end Emergency_Message;

   --  The NID_EM and Q_EMERGENCYSTOP of the message 147 among the RTM
   --  outputs of the last Take; -1 when there is none
   procedure Stop_Ack (NID, Q : out Integer) is
      M : ETCS_Message.Message_T;
      S : ETCS_Message.Status_T;
      use type ETCS_Message.Status_T;
   begin
      NID := -1;
      Q := -1;
      for N in 1 .. Radio_Outputs loop
         Decode_Radio_Message (N, M, S);
         if S = ETCS_Message.Accepted and then M.Kind = MCat.Train_M147 then
            NID := Integer (M.Values (5));
            Q := Integer (M.Values (6));
            return;
         end if;
      end loop;
   end Stop_Ack;

   --  3.10: the emergency messages at standstill at 200 m with an MA to
   --  800 m (no danger point, no overlap: the SvL at the EOA)
   procedure Scenario_Emergency_Stops is
      M      : constant T12.Packet_T := MA_Of ((300, 400), 600);
      NID, Q : Integer;
   begin
      Start_L2;
      Run_X (11_000);
      Give_Radio_Message (1, MA_Message (10, M, Stamp));
      Run_X (20_000);
      Stand_X (1_000);

      Give_Radio_Message (1, Emergency_Message (MCat.Track_M15, 3, 50));
      Stand_X (100);
      Stop_Ack (NID, Q);
      Check (NID = 3 and then Q = 3 and then RA.Emergency_Stops = 0
             and then SI.Current.MA.EOA = 80_000,
             "emergency: a conditional stop behind the min safe front end "
             & "rejected, acknowledged with Q_EMERGENCYSTOP 3 (3.10.2.2 a, "
             & "3.10.1.4)");

      Give_Radio_Message (1, Emergency_Message (MCat.Track_M15, 4, 400));
      Stand_X (100);
      Stop_Ack (NID, Q);
      Stand_X (100);
      Check (NID = 4 and then Q = 0 and then RA.Emergency_Stops = 1
             and then SI.Current.MA.EOA = 50_000
             and then SI.Current.MA.SvL = 50_000
             and then SI.Current.MA.Release_Speed.Kind = SIn.None,
             "emergency: a conditional stop before the EOA accepted, the new "
             & "EOA and SvL at it without release speed, Q_EMERGENCYSTOP 0 "
             & "(3.10.2.2 b 1st bullet)");

      Give_Radio_Message (1, MA_Message (10, M, Stamp));
      Stand_X (200);
      Check (SI.Current.MA.EOA = 50_000 and then RA.Radio_MAs_Accepted = 1,
             "emergency: a new MA rejected while the stop is not revoked "
             & "(3.10.2.4)");

      Give_Radio_Message (1, Emergency_Message (MCat.Track_M15, 5, 600));
      Stand_X (100);
      Stop_Ack (NID, Q);
      Check (NID = 5 and then Q = 1 and then RA.Emergency_Stops = 2
             and then SI.Current.MA.EOA = 50_000,
             "emergency: a stop beyond the SvL accepted, the EOA unchanged, "
             & "Q_EMERGENCYSTOP 1; several stops by NID_EM (3.10.2.2 b "
             & "3rd bullet, 3.10.1.2)");

      Give_Radio_Message (1, Emergency_Message (MCat.Track_M18, 4));
      Stand_X (200);
      Check (RA.Emergency_Stops = 1,
             "emergency: the revocation of NID_EM 4 leaves NID_EM 5 "
             & "(3.10.3.3)");
      Give_Radio_Message (1, Emergency_Message (MCat.Track_M18, 5));
      Stand_X (100);
      Give_Radio_Message (1, MA_Message (10, M, Stamp));
      Stand_X (200);
      Check (RA.Emergency_Stops = 0 and then SI.Current.MA.EOA = 80_000,
             "emergency: every stop revoked, a new MA accepted (3.10.2.4)");

      Give_Radio_Message (1, Emergency_Message (MCat.Track_M16, 7));
      Stand_X (100);
      Stop_Ack (NID, Q);
      Stand_X (100);
      Check (NID = 7 and then Q = 2 and then EVC_Core.Mode = M_TR
             and then RA.Unconditional_Stop_Received,
             "emergency: an unconditional stop trips the train, "
             & "acknowledged with Q_EMERGENCYSTOP 2 (3.10.2.3, [20]); kept "
             & "in Trip ([45], 4.10)");
      Give_Radio_Message (1, Emergency_Message (MCat.Track_M18, 7));
      Stand_X (200);
      Check (RA.Unconditional_Stop_Received
             and then RA.Emergency_Stops = 1
             and then RA.Messages_Rejected = 1,
             "emergency: in TR the revocation is rejected, the stop kept "
             & "(4.8.4 'Revocation of Emergency Stop', TR: R; 4.10: kept)");
   end Scenario_Emergency_Stops;

   ---------------------------------------------------------------------
   --  Phase 2: the authorisations of the modes by the RBC
   ---------------------------------------------------------------------

   --  Message 2, the SR authorisation, referring to the group NID_BG of
   --  country 123: D_SR metres (D_SR_Infinite: none), with packet 63
   --  listing the groups List of country 123 when With_63
   function SR_Message (NID_BG  : Natural;
                        D_SR_M  : Natural;
                        With_63 : Boolean := False;
                        List    : Nat_List := (1 .. 0 => 0))
     return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      P  : T63.Packet_T;
      OK : Boolean;
   begin
      V (3) := Unsigned_64 (Stamp);
      V (5) := 123;
      V (6) := Unsigned_64 (NID_BG);
      V (7) := 1;
      V (8) := Unsigned_64 (D_SR_M);
      Start_Message (W, MCat.Track_M2, V);
      if With_63 then
         P.N_ITER := ETCS_Variables.N_ITER_T (List'Length);
         for I in List'Range loop
            P.Q_NEWCOUNTRY_List (I - List'First + 1).NID_BG :=
              ETCS_Variables.NID_BG_T (List (I));
         end loop;
         T63.Encode (P, W, OK);
         Check (OK, "authority: packet 63 encoded");
      end if;
      return Message_Bytes (W);
   end SR_Message;

   --  4.4.11 in level 2: the SR authorisation of the RBC (message 2). Its
   --  SR distance replaces the national value (4.4.11.1.6.2, .6.4 b),
   --  supervised from its reception (4.4.11.1.3.1 b): passing its end
   --  trips the train ([42]); it ends the MA request reason "Start"
   --  (3.8.2.3.2 b). Its list of expected balise groups (packet 63):
   --  a group not in it trips the train ([36], 4.4.11.1.3 c); a new
   --  authorisation without packet 63 deletes the list (4.4.11.1.6.6).
   --  The driver's entry of the SR distance replaces the RBC's
   --  (4.4.11.1.6.4 a)
   procedure Scenario_SR_Authorisation is
      use type EVC_Procedures.Trip_Reason_T;
   begin
      --  the distance, and the reason Start ended
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L2);
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 300));
      Add_Group (Group (30, 500));
      Establish;
      Input (DMI, (16#40#, 3, 0, 0, 0, 5, 0, 0));
      Check (Wait_Request (500) and then RA.MA_Request_Reasons = 1,
             "SR authorisation: 'Start' in SR, level 2, an MA request");
      Give_Radio_Message (1, SR_Message (10, 250));
      Stand_X (200);
      Check (RA.RBC_SR_Given and then RA.RBC_SR_Distance.Active
             and then RA.MA_Request_Reasons = 0,
             "SR authorisation: message 2 gives the SR distance "
             & "(4.4.11.1.6.4 b) and ends the reason Start (3.8.2.3.2 b)");
      Run_X (20_000);
      Check (EVC_Core.Mode = M_SR,
             "SR authorisation: in SR short of the RBC's SR distance");
      Run_X (27_000);
      Check (EVC_Core.Mode = M_TR
             and then EVC_Procedures.Trip_Reason
                        = EVC_Procedures.SR_Distance_Passed,
             "SR authorisation: the RBC's SR distance passed, train trip "
             & "(4.4.11.1.3 b, 4.6.3 [42])");

      --  the list: group 20 listed, group 30 not
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L2);
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 300));
      Add_Group (Group (30, 500));
      Establish;
      Run_X (15_000);
      Give_Radio_Message
        (1, SR_Message (10, 32767, With_63 => True, List => (1 => 20)));
      Stand_X (200);
      Check (RA.In_SR_List ((123, 20)) and then not RA.In_SR_List ((123, 30)),
             "SR authorisation: the list of packet 63 stored");
      Run_X (40_000);
      Check (EVC_Core.Mode = M_SR and then not RA.RBC_SR_Distance.Active,
             "SR authorisation: D_SR infinite, the listed group passed "
             & "(4.4.11.1.3 c)");
      Run_X (55_000);
      Check (EVC_Core.Mode = M_TR
             and then EVC_Procedures.Trip_Reason
                        = EVC_Procedures.SR_Balise_Not_Listed,
             "SR authorisation: a group not in the list, train trip "
             & "(4.6.3 [36])");

      --  a new authorisation without the list: every group may pass; the
      --  driver's entry replaces the RBC's distance
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L2);
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 300));
      Establish;
      Run_X (15_000);
      Give_Radio_Message
        (1, SR_Message (10, 32767, With_63 => True, List => (1 => 20)));
      Stand_X (200);
      Give_Radio_Message (1, SR_Message (10, 100));
      Stand_X (200);
      Check (RA.RBC_SR_Given and then not RA.In_SR_List ((123, 20)),
             "SR authorisation: a new one without packet 63 deletes the "
             & "list (4.4.11.1.6.6)");
      Input (DMI, Frame (EVC_DMI_Port.MSG_DRIVER_DATA,
                         Byte_Array'(1 => 3) & U16 (40) & U16 (1000)));
      Stand_X (200);
      Check (not RA.RBC_SR_Given,
             "SR authorisation: the driver's SR distance replaces the "
             & "RBC's (4.4.11.1.6.4 a)");
      Run_X (40_000);
      Check (EVC_Core.Mode = M_SR,
             "SR authorisation: past the RBC's former distance and group "
             & "20 in SR");
   end Scenario_SR_Authorisation;

   --  A message of the RBC with the header fields only (message 6)
   function Header_Message (Kind : MCat.Known_Message_T) return Byte_Array
   is
      W : Writer_T;
      V : ETCS_Message.Value_Array := (others => 0);
   begin
      V (3) := Unsigned_64 (Stamp);
      V (5) := 123;
      V (6) := 10;
      Start_Message (W, Kind, V);
      return Message_Bytes (W);
   end Header_Message;

   --  5.11 in level 2, Post Trip: until the RBC recognises the exit from
   --  TR (message 6, S120) the driver's "Start" requests no MA and an MA
   --  is not taken (A035, 4.8.4 [1]); after it, "Start" sends the MA
   --  request (S140 b, S150). With an emergency stop pending, "Start"
   --  waits for its revocation (D130, S130). Message 6 outside PT is
   --  not taken.
   procedure Scenario_Trip_L2 is
      MAs : Natural;
   begin
      Start_L2;
      Run_X (15_000);
      Give_Radio_Message (1, Header_Message (MCat.Track_M6));
      Stand_X (200);
      Check (not RA.Trip_Exit_Recognised,
             "post trip, level 2: message 6 outside PT not taken");
      EVC_Core.Set_Mode_For_Test (M_PT, L2);
      Stand_X (200);
      Input (DMI, (16#40#, 3, 0, 0, 0, 5, 0, 0));
      Check (not Wait_Request (1_000),
             "post trip, level 2: no MA request before the exit from TR "
             & "is recognised (5.11.2.2 S120)");
      MAs := RA.Radio_MAs_Accepted;
      Give_Radio_Message (1, MA_Message (10, MA_Of ((300, 400), 600),
                                         Stamp));
      Stand_X (200);
      Check (RA.Radio_MAs_Accepted = MAs,
             "post trip, level 2: no MA before message 6 (5.11.2.2 A035, "
             & "4.8.4 [1])");
      Give_Radio_Message (1, Header_Message (MCat.Track_M6));
      Stand_X (200);
      Input (DMI, (16#40#, 3, 0, 0, 0, 5, 0, 0));
      Check (RA.Trip_Exit_Recognised and then Wait_Request (1_000)
             and then Request_Reason = 1,
             "post trip, level 2: message 6, then 'Start' sends the MA "
             & "request (5.11.2.2 E125, S140 b, S150)");

      --  an unconditional emergency stop pending
      Start_L2;
      Run_X (15_000);
      Give_Radio_Message (1, Emergency_Message (MCat.Track_M16, 3));
      Stand_X (500);
      EVC_Core.Set_Mode_For_Test (M_PT, L2);
      Stand_X (200);
      Give_Radio_Message (1, Header_Message (MCat.Track_M6));
      Stand_X (200);
      Input (DMI, (16#40#, 3, 0, 0, 0, 5, 0, 0));
      Check (RA.Trip_Exit_Recognised and then RA.Emergency_Stops = 1
             and then not Wait_Request (1_000),
             "post trip, level 2: an emergency stop pending, no MA "
             & "request (5.11.2.2 D130, S130)");
      Give_Radio_Message (1, Emergency_Message (MCat.Track_M18, 3));
      Stand_X (200);
      Input (DMI, (16#40#, 3, 0, 0, 0, 5, 0, 0));
      Check (RA.Emergency_Stops = 0 and then Wait_Request (1_000),
             "post trip, level 2: the stop revoked, 'Start' requests an "
             & "MA (5.11.2.2 E135, S140)");
   end Scenario_Trip_L2;

   --  The driver selects Shunting (MSG_DRIVER_ACTION 7)
   procedure Select_Shunting is
   begin
      Input (DMI, (16#40#, 3, 0, 0, 0, 7, 0, 0));
   end Select_Shunting;

   --  Stand until the on-board sends a request for shunting (at most
   --  Max_Ms); True when one was sent
   function Wait_SH_Request (Max_Ms : Natural) return Boolean is
      N : constant Natural := RA.SH_Requests_Sent;
   begin
      for I in 1 .. Max_Ms / 100 loop
         Stand_X (100);
         if RA.SH_Requests_Sent > N then
            return True;
         end if;
      end loop;
      return False;
   end Wait_SH_Request;

   --  Message 27 or 28 answering the request of time stamp Req, 28 with
   --  packet 49 listing the groups List of country 123 when With_49
   function SH_Answer (Kind    : MCat.Known_Message_T;
                       Req     : ETCS_Variables.T_TRAIN_T;
                       With_49 : Boolean := False;
                       List    : Nat_List := (1 .. 0 => 0))
     return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      P  : T49.Packet_T;
      OK : Boolean;
   begin
      V (3) := Unsigned_64 (Stamp);
      V (5) := 123;
      V (6) := 10;
      V (7) := Unsigned_64 (Req);
      Start_Message (W, Kind, V);
      if With_49 then
         P.N_ITER := ETCS_Variables.N_ITER_T (List'Length);
         for I in List'Range loop
            P.Q_NEWCOUNTRY_List (I - List'First + 1).NID_BG :=
              ETCS_Variables.NID_BG_T (List (I));
         end loop;
         T49.Encode (P, W, OK);
         Check (OK, "authority: packet 49 encoded");
      end if;
      return Message_Bytes (W);
   end SH_Answer;

   --  5.6 in level 2: Shunting selected at standstill sends the request
   --  for shunting (message 130, A045) and waits (S050, MSG_ONBOARD
   --  waiting 4); an answer naming another request is not taken (4.8.4
   --  [14]); "SH refused" (27) ends the wait, the mode stays (A220);
   --  "SH authorised" (28) is [6]: SH, with the list of balise groups for
   --  the SH area of packet 49 (A050: a group not in it trips, [52]);
   --  without an answer the request is sent again every 15 s, 3 times,
   --  then it fails (5.6.4.1.1, 5.6.4.1.2)
   procedure Scenario_Shunting_L2 is
      use type EVC_Procedures.Trip_Reason_T;
      T : ETCS_Variables.T_TRAIN_T;
   begin
      Start_L2;
      Add_Group (Group (20, 300));
      Add_Group (Group (30, 500));
      Run_X (15_000);
      Stand_X (1_000);
      Select_Shunting;
      Check (Wait_SH_Request (1_000) and then RA.SH_Waiting,
             "shunting, level 2: message 130 sent, waiting for the RBC "
             & "(5.6.2.2 A045, S050)");
      T := RA.SH_Request_Stamp;
      Give_Radio_Message (1, SH_Answer (MCat.Track_M27, ETCS_Variables."+" (T, 1)));
      Stand_X (200);
      Check (RA.SH_Waiting,
             "shunting, level 2: an answer to another request not taken "
             & "(4.8.4 [14])");
      Give_Radio_Message (1, SH_Answer (MCat.Track_M27, T));
      Stand_X (200);
      Check (not RA.SH_Waiting and then RA.SH_Answer = 0
             and then EVC_Core.Mode = M_FS,
             "shunting, level 2: SH refused, the mode stays (5.6.2.2 E215, "
             & "A220)");
      Select_Shunting;
      Check (Wait_SH_Request (1_000),
             "shunting, level 2: a new request");
      Give_Radio_Message
        (1, SH_Answer (MCat.Track_M28, RA.SH_Request_Stamp,
                       With_49 => True, List => (1 => 20)));
      Stand_X (300);
      Check (EVC_Core.Mode = M_SH and then RA.SH_Answer = 1
             and then not RA.SH_Waiting,
             "shunting, level 2: SH authorised, SH entered (4.6.3 [6], "
             & "5.6.2.2 E090, A050)");
      Run_X (40_000);
      Check (EVC_Core.Mode = M_SH,
             "shunting, level 2: the group of the RBC's list passed");
      Run_X (55_000);
      Check (EVC_Core.Mode = M_TR
             and then EVC_Procedures.Trip_Reason
                        = EVC_Procedures.SH_Balise_Not_Listed,
             "shunting, level 2: a group not in the list of the RBC, trip "
             & "(5.6.2.2 A050, 4.6.3 [52])");

      --  no answer
      Start_L2;
      Run_X (15_000);
      Stand_X (1_000);
      Select_Shunting;
      Check (Wait_SH_Request (1_000)
             and then not Wait_SH_Request (14_000)
             and then Wait_SH_Request (2_000)
             and then Wait_SH_Request (16_000)
             and then Wait_SH_Request (16_000),
             "shunting, level 2: no answer, 130 repeated every 15 s, 3 "
             & "times (5.6.4.1.1)");
      Check (not Wait_SH_Request (16_000) and then not RA.SH_Waiting
             and then RA.SH_Request_Failed and then EVC_Core.Mode = M_FS,
             "shunting, level 2: then the request fails (5.6.4.1.2)");
   end Scenario_Shunting_L2;

   ---------------------------------------------------------------------
   --  Phase 4: the acceptance of radio information (4.8)
   ---------------------------------------------------------------------

   --  4.8.3 and 4.8.4 for the RBC as the transmission medium, one class
   --  of each table per check (EVC_Radio_Acceptance)
   procedure Scenario_Radio_Acceptance is
      M      : constant T12.Packet_T := MA_Of ((300, 400), 600);
      R0     : Natural;
      NID, Q : Integer;
      Got    : Unsigned_64;
   begin
      --  4.8.4 'Unconditional Emergency Stop', SH: R
      Start_L2;
      EVC_Core.Set_Mode_For_Test (M_SH, L2);
      Stand_X (200);
      R0 := RA.Messages_Rejected;
      Give_Radio_Message (1, Emergency_Message (MCat.Track_M16, 7));
      Stand_X (100);
      Stop_Ack (NID, Q);
      Stand_X (100);
      Check (EVC_Core.Mode = M_SH and then NID = -1
             and then not RA.Unconditional_Stop_Received
             and then RA.Messages_Rejected = R0 + 1,
             "acceptance: an unconditional stop in SH rejected, no trip, no "
             & "acknowledgement (4.8.4 'Unconditional Emergency Stop', SH)");

      --  4.8.3 'Unconditional Emergency Stop', level 1: R [2]
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_FS, L1);
      Add_Group (Group (10, 100));
      Establish;
      Run_X (11_000);
      R0 := RA.Messages_Rejected;
      Give_Radio_Message (1, Emergency_Message (MCat.Track_M16, 7));
      Stand_X (200);
      Check (EVC_Core.Mode /= M_TR and then RA.Messages_Rejected = R0 + 1
             and then RA.Buffered = 0,
             "acceptance: an unconditional stop in level 1 without a level 2 "
             & "announcement rejected (4.8.3 'Unconditional Emergency Stop', "
             & "level 1: R [2])");
      Give_Radio_Message (1, MA_Message (10, M, Stamp));
      Stand_X (200);
      Check (not SI.Current.MA.Present
             and then RA.Messages_Rejected = R0 + 2,
             "acceptance: an MA of the RBC in level 1 rejected (4.8.3 "
             & "'Movement Authority', From RBC, level 1: R [2])");

      --  4.8.4 'SR Authorisation', FS: R
      Start_L2;
      Run_X (11_000);
      R0 := RA.Messages_Rejected;
      Give_Radio_Message (1, SR_Message (10, 500));
      Stand_X (200);
      Check (not RA.RBC_SR_Given and then RA.Messages_Rejected = R0 + 1,
             "acceptance: an SR authorisation in FS rejected (4.8.4 'SR "
             & "Authorisation', FS: R)");

      --  4.8.4 'Request to shorten MA', SR: R, answered
      EVC_Core.Set_Mode_For_Test (M_SR, L2);
      Stand_X (200);
      Give_Radio_Message
        (1, MA_Message (10, MA_Of ((200, 100)), Stamp, Kind => MCat.Track_M9));
      Stand_X (100);
      Shortening_Answer (NID, Got);
      Check (NID = 138 and then RA.Messages_Rejected = R0 + 2,
             "acceptance: a request to shorten the MA in SR rejected, "
             & "answered 138 (4.8.4 'Request to shorten MA', SR: R; "
             & "3.8.6.1 c)");
   end Scenario_Radio_Acceptance;

   --  Packet 41: an order to level 2 at D_M metres from the group
   function Order_L2 (D_M : Natural) return TP41.Packet_T is
      P : TP41.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_LEVELTR := ETCS_Variables.D_LEVELTR_T (D_M);
      P.M_LEVELTR := ETCS_Variables.M_LEVELTR_Level_2;
      P.Has_NID_NTC := False;
      P.L_ACKLEVELTR := 0;
      P.N_ITER := 0;
      return P;
   end Order_L2;

   --  Level 1 in FS, the session established and the Train Data
   --  acknowledged, the group 10 at 100 m announcing level 2 at 400 m,
   --  passed
   procedure Start_L2_Announced is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_FS, L1);
      Add_Group (Group (10, 100));
      Carry (Track_N, 0, Order_L2 (300));
      Establish;
      Run_X (15_000);
   end Start_L2_Announced;

   --  4.8.5: the transition buffer of the authority half
   procedure Scenario_Transition_Buffer is
      M : constant T12.Packet_T := MA_Of ((300, 400), 600);
   begin
      Start_L2_Announced;
      Check (EVC_Levels.Announced
             and then EVC_Levels.Announced_Level = L2,
             "buffer: level 2 announced at 400 m");
      Give_Radio_Message (1, MA_Message (10, M, Stamp));
      Stand_X (200);
      Check (RA.Buffered = 1 and then not SI.Current.MA.Present,
             "buffer: an MA of the RBC in level 1 with level 2 announced is "
             & "stored, not used (4.8.3 [2], 4.8.5.1)");
      for I in 1 .. 3 loop
         Give_Radio_Message (1, MA_Message (10, M, Stamp));
         Stand_X (100);
      end loop;
      Check (RA.Buffered = 3,
             "buffer: three messages kept, the oldest replaced (4.8.5.1, "
             & "4.8.5.3)");
      Run_X (45_000);
      Check (EVC_Levels.Level = L2 and then RA.Buffered = 0
             and then SI.Current.MA.Present,
             "buffer: the level 2 transition performed, the messages "
             & "released and accepted in level 2: the MA used (4.8.5.5)");

      Start_L2_Announced;
      Give_Radio_Message (1, MA_Message (10, M, Stamp));
      Stand_X (200);
      EVC_Radio.Set_State (1, EVC_Radio.Idle);
      Stand_X (200);
      Check (RA.Buffered = 0,
             "buffer: the session that gave the messages terminated, the "
             & "buffer deleted (4.8.5.4 c)");
   end Scenario_Transition_Buffer;

   --  5.4.3.2 D15, S11, S20, S21: in SB, the driver's Start in level 2
   --  requests the MA once the RBC acknowledged the Train Data (3.18.3.4)
   procedure Scenario_Start_After_Ack is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SB, L2);
      Add_Group (Group (10, 100));
      EVC_Radio.Set_Peer (1, (NID_C => 123, NID_RBC => 1), 0);
      EVC_Radio.Set_State (1, EVC_Radio.Established);
      EVC_Radio.Set_Version (1, 33);
      EVC_Radio.Set_Roles (1, EVC_Radio.No_Session);
      Stand_X (200);
      Input (DMI, (16#40#, 3, 0, 0, 0, 5, 0, 0));
      Check (not Wait_Request (1000) and then RA.MA_Request_Reasons = 0,
             "start: in SB, Start before the Train Data are acknowledged "
             & "requests no MA (5.4.3.2 D15, S11)");
      Ack_Train_Data;
      Check (RA.MA_Requests_Sent = 1 and then RA.MA_Request_Reasons = 1,
             "start: the Train Data acknowledged, the MA requested with "
             & "the reason Start (5.4.3.2 S20, S21; 3.8.2.3.1)");
   end Scenario_Start_After_Ack;

   --  Message 34 referring to the group 10 of country 123: the display
   --  from Begin_M to Begin_M + Len_M metres beyond it
   function TAF_Message (Begin_M, Len_M : Natural) return Byte_Array is
      V : ETCS_Message.Value_Array := (others => 0);
   begin
      V (3) := Unsigned_64 (Stamp);
      V (5) := 123;
      V (6) := 10;
      V (7) := 1;
      V (9) := 1;
      V (10) := Unsigned_64 (Begin_M);
      V (11) := Unsigned_64 (Len_M);
      return Message_Of (MCat.Track_M34, V);
   end TAF_Message;

   --  The message 149 among the RTM outputs of the last Take
   function Has_149 return Boolean is
     (for some N in 1 .. Radio_Outputs =>
        not Radio_Output (N).Request and then Radio_Output (N).Kind = 149);

   --  3.15.5, messages 34 and 149: the track ahead free request
   procedure Scenario_Track_Ahead_Free is
      Sent : Boolean := False;
   begin
      Start_L2;
      Run_X (15_000);
      Give_Radio_Message (1, TAF_Message (200, 100));
      Stand_X (200);
      Check (not RA.TAF_Stored,
             "TAF: a request in FS rejected (4.8.4 'Track Ahead Free "
             & "Request', FS: R)");

      EVC_Core.Set_Mode_For_Test (M_SR, L2);
      Stand_X (200);
      Give_Radio_Message (1, TAF_Message (200, 100));
      Stand_X (200);
      Check (RA.TAF_Stored and then not RA.TAF_Shown,
             "TAF: the request in SR stored, not shown before its "
             & "beginning (3.15.5.2 a)");
      Run_X (32_000);
      Check (RA.TAF_Shown
             and then Byte_At (Find_DMI (EVC_DMI_Port.MSG_MODE_LEVEL), 12)
                      = 1,
             "TAF: shown to the driver from its beginning (3.15.5.2 a, "
             & "MSG_MODE_LEVEL taf)");
      Input (DMI, (16#40#, 3, 0, 0, 0, 0, 0, 0));
      for I in 1 .. 3 loop
         Stand_X (100);
         Sent := Sent or else Has_149;
      end loop;
      Check (Sent and then RA.TAF_Granted = 1 and then not RA.TAF_Shown
             and then not RA.TAF_Stored,
             "TAF: the driver's acknowledgement ends the display, message "
             & "149 to the RBC (3.15.5.3, 3.15.5.4)");

      Give_Radio_Message (1, TAF_Message (0, 50));
      Stand_X (200);
      Check (RA.TAF_Shown, "TAF: a new request replaces the stored one, "
             & "shown at once (3.15.5.6)");
      Run_X (45_000);
      Check (not RA.TAF_Shown and then not RA.TAF_Stored
             and then RA.TAF_Granted = 1,
             "TAF: passed its end unanswered, the request ends without "
             & "consequence (3.15.5.2 b, 3.15.5.5)");
   end Scenario_Track_Ahead_Free;

end EVC_Test_Authority;
