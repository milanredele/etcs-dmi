--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half (see the specification).

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P15;
with ETCS_Track_Packets.P57;
with ETCS_Variables;
with EVC_Core;
with EVC_Distances;
with EVC_Ports;              use EVC_Ports;
with EVC_Modes;              use EVC_Modes;
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
   package RA renames EVC_Radio_Authority;
   use type MCat.Message_Kind_T;
   use type EVC_SDM.Status_T;
   use type SIn.Release_Speed_Kind_T;
   use type EVC_Distances.Cm_T;

   ---------------------------------------------------------------------
   --  Helpers
   ---------------------------------------------------------------------

   --  The session half's part, put through the writers of EVC_Radio: an
   --  established session 1 with the Supervising RBC (3.5.3.7 d, 3.15.1)
   procedure Establish is
   begin
      EVC_Radio.Set_Peer (1, (NID_C => 123, NID_RBC => 1), 0);
      EVC_Radio.Set_State (1, EVC_Radio.Established);
      EVC_Radio.Set_Version (1, 33);
      EVC_Radio.Set_Roles (1, EVC_Radio.No_Session);
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
      T21.Encode (G, W, OK);
      Check (OK, "authority: packet 21 encoded");
      T27.Encode (S, W, OK);
      Check (OK, "authority: packet 27 encoded");
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

end EVC_Test_Authority;
