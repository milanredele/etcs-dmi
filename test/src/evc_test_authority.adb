--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half (see the specification).

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P15;
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
                        Kind    : MCat.Known_Message_T := MCat.Track_M3)
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

end EVC_Test_Authority;
