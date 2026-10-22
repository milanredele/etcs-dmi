--  ETCS on-board (EVC) regression: Supervised Manoeuvre, implementation.

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P15;
with ETCS_Track_Packets.P21;
with ETCS_Track_Packets.P27;
with ETCS_Train_Packets.P0;
with ETCS_Variables;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Distances;       use EVC_Distances;
with EVC_Modes;           use EVC_Modes;
with EVC_Ports;           use EVC_Ports;
with EVC_Mission;
with EVC_Movement_Authority;
with EVC_Position;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Sessions;
with EVC_Train_Data;
with EVC_Test_Support;    use EVC_Test_Support;
with Interfaces;          use Interfaces;

package body EVC_Test_Manoeuvre is

   package MCat renames ETCS_Message_Catalogue;
   use type MCat.Message_Kind_T;
   use type ETCS_Message.Status_T;

   --  A TIU frame of the safe consist length (EVC_Ports signal 15):
   --  value V, the lengths in front of the engine (nominal, min, max),
   --  then in rear of it, in metres
   function SCL_Frame (V : Byte; F_Nom, F_Min, F_Max,
                       R_Nom, R_Min, R_Max : Natural := 0)
     return Byte_Array
   is
      L     : constant array (0 .. 5) of Natural :=
        (F_Nom, F_Min, F_Max, R_Nom, R_Min, R_Max);
      Frame : Byte_Array (1 .. TIU_SCL_Length) := (others => 0);
   begin
      Frame (1) := 15;
      Frame (2) := V;
      for K in L'Range loop
         Frame (3 + 2 * K) := Byte (L (K) mod 256);
         Frame (4 + 2 * K) := Byte (L (K) / 256);
      end loop;
      return Frame;
   end SCL_Frame;

   procedure Scenario_Safe_Consist is
      Valid_Before : Boolean;
   begin
      Start_X;
      Stand_X (300);
      Check (not EVC_Train_Data.Consist_Available
             and then not EVC_Train_Data.Consist_Known
             and then EVC_Train_Data.Entry_Possible,
             "SCL: no safe consist length before the first TIU input");
      Check (Valid_TIU (SCL_Frame (1, 0, 0, 0, 400, 398, 402))
             and then Valid_TIU (SCL_Frame (0))
             and then not Valid_TIU (SCL_Frame (1, 0, 0, 0, 400, 401, 402))
             and then not Valid_TIU (SCL_Frame (1, 0, 0, 0, 400, 398, 4096))
             and then not Valid_TIU (SCL_Frame (2))
             and then not Valid_TIU ((15, 1)),
             "SCL: the TIU frame of signal 15 (EVC_Ports): min <= nom <= "
             & "max in 0 .. 4095 m on each side, value 0 or 1, 14 bytes");

      --  3.18.3.2 b) 1st bullet: available, nothing in front
      EVC_Core.Handle_Input (TIU, SCL_Frame (1, 0, 0, 0, 400, 398, 402));
      Stand_X (300);
      Check (EVC_Train_Data.Consist_Available
             and then EVC_Train_Data.Consist.Rear_Max = 402
             and then EVC_Train_Data.Consist.Rear_Min = 398
             and then EVC_Train_Data.Entry_Possible
             and then Natural (EVC_Train_Data.Consist_Length) = 40_200,
             "SCL: available from the TIU, nothing in front of the engine, "
             & "the train length the sum of the max lengths (3.18.3.2 b), "
             & "3.18.3.2.4)");

      --  3.18.3.5 a) b): a length in front of the engine
      Valid_Before := EVC_Train_Data.Valid;
      EVC_Core.Handle_Input (TIU, SCL_Frame (1, 20, 19, 21, 400, 398, 402));
      Stand_X (300);
      Check (not EVC_Train_Data.Valid
             and then not EVC_Train_Data.Entry_Possible
             and then EVC_Train_Data.Consist_In_Front,
             "SCL: a length in front of the engine, no valid Train Data "
             & "(valid before:" & Boolean'Image (Valid_Before) & ") and no "
             & "driver entry (3.18.3.5 a), b))");

      --  3.18.3.2.5: unavailable, the values kept
      EVC_Core.Handle_Input (TIU, SCL_Frame (0));
      Stand_X (300);
      Check (not EVC_Train_Data.Consist_Available
             and then EVC_Train_Data.Consist_Known
             and then EVC_Train_Data.Consist.Front_Max = 21
             and then EVC_Train_Data.Entry_Possible,
             "SCL: unavailable, the safe consist length kept (3.18.3.2.5)");
   end Scenario_Safe_Consist;

   --  The on-board's T_TRAIN now
   function Now_Stamp return Unsigned_64 is
     (Unsigned_64 (EVC_Radio.T_Train_At (Unsigned_64 (EVC_Core.Time_Ms))));

   --  Stand until the on-board sends message Kind (at most Max_Ms); its
   --  T_TRAIN, 0 when none was sent
   function Wait_For (Kind : MCat.Message_Kind_T; Max_Ms : Natural)
     return Unsigned_64
   is
      M  : ETCS_Message.Message_T;
      St : ETCS_Message.Status_T;
   begin
      for C in 1 .. Max_Ms / 100 loop
         Stand_X (100);
         for N in 1 .. Radio_Outputs loop
            Decode_Radio_Message (N, M, St);
            if St = ETCS_Message.Accepted and then M.Kind = Kind then
               return M.Values (3);
            end if;
         end loop;
      end loop;
      return 0;
   end Wait_For;

   --  Wait_For on session S only
   function Wait_On (Kind : MCat.Message_Kind_T; S : Natural; Max_Ms : Natural)
     return Unsigned_64
   is
      M  : ETCS_Message.Message_T;
      St : ETCS_Message.Status_T;
   begin
      for C in 1 .. Max_Ms / 100 loop
         Stand_X (100);
         for N in 1 .. Radio_Outputs loop
            Decode_Radio_Message (N, M, St);
            if St = ETCS_Message.Accepted and then M.Kind = Kind
              and then Radio_Output (N).Session = S
            then
               return M.Values (3);
            end if;
         end loop;
      end loop;
      return 0;
   end Wait_On;

   --  The level 2 start of the authority scenarios: FS in level 2, the
   --  LRBG 10 at 100 m passed, an established session 1 whose RBC
   --  acknowledged the Train Data (message 8), the safe consist length
   --  available (nothing in front of the engine, 400 m in rear)
   procedure Start_L2_SM is
      T : Unsigned_64;
      V : ETCS_Message.Value_Array := (others => 0);
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, L2);
      Add_Group (Group (10, 100));
      EVC_Radio.Set_Peer (1, (NID_C => 123, NID_RBC => 1), 0);
      EVC_Radio.Set_State (1, EVC_Radio.Established);
      EVC_Radio.Set_Version (1, 33);
      EVC_Radio.Set_Roles (1, EVC_Radio.No_Session);
      T := Wait_For (MCat.Train_M129, 16_000);
      V (3) := Now_Stamp;
      V (7) := T;
      Give_Radio_Message (1, Message_Of (MCat.Track_M8, V));
      Run_X (15_000);
      Stand_X (1_000);
      EVC_Core.Handle_Input (TIU, SCL_Frame (1, 0, 0, 0, 400, 398, 402));
      Stand_X (300);
   end Start_L2_SM;

   --  The driver selects 'Initiate SM' (MSG_DRIVER_ACTION 17, arg 0)
   procedure Select_SM is
   begin
      Input (DMI, (16#40#, 3, 0, 0, 0, 17, 0, 0));
   end Select_SM;

   --  Message 5 (SM refused) answering the request of time stamp Req
   function SM_Refused (Req : Unsigned_64) return Byte_Array is
      V : ETCS_Message.Value_Array := (others => 0);
   begin
      V (3) := Now_Stamp;
      V (5) := 123;
      V (6) := 10;
      V (7) := Req;
      return Message_Of (MCat.Track_M5, V);
   end SM_Refused;

   --  Message 4 (SM authorisation) answering the request of time stamp
   --  Req: an MA of 500 m from the LRBG 10 in the direction Q_DIR, flat,
   --  100 km/h, V_SM 30 km/h
   function SM_Authorisation (Req : Unsigned_64; Q_DIR : Natural := 1)
     return Byte_Array
   is
      V  : ETCS_Message.Value_Array := (others => 0);
      W  : Writer_T;
      A  : ETCS_Track_Packets.P15.Packet_T;
      G  : ETCS_Track_Packets.P21.Packet_T := Grad ((1 => (0, 0)));
      S  : ETCS_Track_Packets.P27.Packet_T :=
        SSP ((1 => (0, 100, False)));
      OK : Boolean;
   begin
      V (3) := Now_Stamp;
      V (5) := 123;
      V (6) := 10;
      V (7) := Req;
      V (8) := 1;
      V (10) := 6;
      Start_Message (W, MCat.Track_M4, V);
      A.Q_DIR := ETCS_Variables.Q_DIR_T (Q_DIR);
      A.Q_SCALE := 1;
      A.L_ENDSECTION := 500;
      G.Q_DIR := ETCS_Variables.Q_DIR_T (Q_DIR);
      S.Q_DIR := ETCS_Variables.Q_DIR_T (Q_DIR);
      ETCS_Track_Packets.P15.Encode (A, W, OK);
      Check (OK, "SM: packet 15 encoded");
      ETCS_Track_Packets.P21.Encode (G, W, OK);
      Check (OK, "SM: packet 21 encoded");
      ETCS_Track_Packets.P27.Encode (S, W, OK);
      Check (OK, "SM: packet 27 encoded");
      return Message_Bytes (W);
   end SM_Authorisation;

   --  The report of message 131 with the safe consist received equals
   --  the position report
   function Same_Report return Boolean is
     (ETCS_Train_Packets.P0."="
        (EVC_Position.Consist_Report (EVC_Core.Mode, L2,
                                      EVC_Train_Data.Consist),
         EVC_Position.Position_Report (EVC_Core.Mode, L2)));

   --  The report of message 131 has its estimated front end Ahead cm
   --  further than the position report and its confidence interval
   --  More_Over and More_Under cm wider, to the resolution of its scale
   function Front_Moved (Ahead, More_Over, More_Under : Length_T)
     return Boolean
   is
      C : constant ETCS_Train_Packets.P0.Packet_T :=
        EVC_Position.Consist_Report (EVC_Core.Mode, L2,
                                     EVC_Train_Data.Consist);
      P : constant ETCS_Train_Packets.P0.Packet_T :=
        EVC_Position.Position_Report (EVC_Core.Mode, L2);
      use type ETCS_Variables.Q_SCALE_T, ETCS_Variables.Q_DLRBG_T;
      Q : constant Natural := Natural (C.Q_SCALE);
      R : constant Length_T := Scaled (1, Q);
      function Near (A, B : Length_T) return Boolean is
        (A <= B + R and then B <= A + R);
   begin
      return C.Q_SCALE = P.Q_SCALE and then C.Q_DLRBG = P.Q_DLRBG
        and then Near (Scaled (Natural (C.D_LRBG), Q),
                       Scaled (Natural (P.D_LRBG), Q) + Ahead)
        and then Near (Scaled (Natural (C.L_DOUBTOVER), Q),
                       Scaled (Natural (P.L_DOUBTOVER), Q) + More_Over)
        and then Near (Scaled (Natural (C.L_DOUBTUNDER), Q),
                       Scaled (Natural (P.L_DOUBTUNDER), Q) + More_Under);
   end Front_Moved;

   procedure Scenario_SM_Authorisation is
      T : Unsigned_64;
   begin
      Start_L2_SM;
      Select_SM;
      T := Wait_For (MCat.Train_M131, 1_000);
      Give_Radio_Message (1, SM_Authorisation (T + 1));
      Stand_X (300);
      Check (EVC_Sessions.SM_Waiting and then EVC_Core.Mode = M_FS,
             "SM authorisation: one answering another request not taken "
             & "(4.8.4 [14])");
      Give_Radio_Message (1, SM_Authorisation (T));
      Stand_X (300);
      Check (not EVC_Sessions.SM_Waiting and then EVC_Sessions.SM_Answer = 1
             and then EVC_Core.Mode = M_SM,
             "SM authorisation: message 4 answering the request, SM entered "
             & "(4.6.3 [81], 5.21.2.2 E115, D080, A050; 4.4.21.1.2); mode "
             & Mode_T'Image (EVC_Core.Mode));
      Check (not EVC_Radio_Authority.SM_Opposite
               and then EVC_Position.Orientation = Plus,
             "SM authorisation: packet 15 with Q_DIR nominal, the train "
             & "not turned (5.21.2.2 A075)");
      Check (EVC_Position.Manoeuvre_Orientation and then EVC_Mission.Mission,
             "SM authorisation: the same direction, the orientation fixed "
             & "by it (3.6.1.5.1, 3.7.3.4 a)");
      --  50 m in front of the engine (49 .. 52), the authorisation in the
      --  train orientation: the front end at the far end of that consist
      Start_L2_SM;
      EVC_Core.Handle_Input (TIU, SCL_Frame (1, 50, 49, 52, 400, 398, 402));
      Stand_X (300);
      Select_SM;
      T := Wait_For (MCat.Train_M131, 1_000);
      declare
         E0 : constant Dist_T := EVC_Position.Estimated_Front;
         O0 : constant Length_T := EVC_Position.Doubt_Over;
         U0 : constant Length_T := EVC_Position.Doubt_Under;
      begin
         Give_Radio_Message (1, SM_Authorisation (T));
         Stand_X (300);
         Check (EVC_Core.Mode = M_SM
                and then EVC_Position.Estimated_Front = E0 + 5_000
                and then EVC_Position.Doubt_Over = O0 + 100
                and then EVC_Position.Doubt_Under = U0 + 200,
                "SM same direction: the front end 50 m ahead, 1 m and 2 m "
                & "wider, from the consist in front (3.18.3.2.5.1):"
                & Dist_T'Image (E0)
                & Dist_T'Image (EVC_Position.Estimated_Front)
                & Length_T'Image (EVC_Position.Doubt_Over - O0)
                & Length_T'Image (EVC_Position.Doubt_Under - U0));
         Check (Same_Report,
                "SM same direction: the report of 131 is the position "
                & "report from it (5.21.2.2 A045, 3.18.3.2.5.1)");
      end;
      --  the MA in the direction opposite to the train orientation: the
      --  front end at the far end of the 400 m in rear of the engine
      --  (4.4.21.1.7)
      Start_L2_SM;
      Select_SM;
      T := Wait_For (MCat.Train_M131, 1_000);
      declare
         E0 : constant Dist_T := EVC_Position.Estimated_Front;
         O0 : constant Length_T := EVC_Position.Doubt_Over;
         U0 : constant Length_T := EVC_Position.Doubt_Under;
         S0 : constant Sense_T := EVC_Position.Orientation;
      begin
         Give_Radio_Message (1, SM_Authorisation (T, Q_DIR => 0));
         Check (Wait_For (MCat.Train_M136, 1_000) /= 0,
                "SM opposite: the position reported (5.21.2.2 A095)");
         Check (EVC_Position.Orientation = Opposite (S0)
                and then EVC_Position.Manoeuvre_Orientation,
                "SM opposite: the orientation turned (5.21.2.2 A075, "
                & "3.6.1.5.1)");
         Check (EVC_Position.Estimated_Front = 40_000 - E0,
                "SM opposite: the estimated front end 400 m back "
                & "(4.4.21.1.7 a)):" & Dist_T'Image (E0)
                & Dist_T'Image (EVC_Position.Estimated_Front));
         Check (EVC_Position.Doubt_Over = U0 + 200
                and then EVC_Position.Doubt_Under = O0 + 200,
                "SM opposite: the min / max safe front ends from the max / "
                & "min ones and the min / max consist in rear (4.4.21.1.7 "
                & "b) c)):" & Length_T'Image (EVC_Position.Doubt_Over)
                & Length_T'Image (EVC_Position.Doubt_Under));
         Check (not EVC_Position.Linking.Stored,
                "SM opposite: the location based information deleted "
                & "(3.7.3.4 b))");
         Stand_X (300);
         Check (EVC_Core.Mode = M_SM
                  and then EVC_Movement_Authority.MA_Present,
                "SM opposite: SM entered from FS, the MA of the "
                & "authorisation kept (4.6.3 [81], 4.10, 5.21.2.2 A050); "
                & "mode " & Mode_T'Image (EVC_Core.Mode));
         Check (Same_Report,
                "SM opposite: the position shifted to the consist's end, "
                & "the report of 131 is the position report (5.21.2.2 "
                & "A045)");
      end;
      declare
         Selected : constant Natural := JRU_Actions (8);
      begin
         --  'Continue in SM' (MSG_DRIVER_ACTION 17, argument 1)
         Input (DMI, (16#40#, 3, 0, 0, 0, 17, 1, 0));
         Check (Wait_For (MCat.Train_M131, 1_000) /= 0
                and then JRU_Actions (8) = Selected + 1,
                "SM: 'Continue in SM' sends 131 and is recorded as "
                & "Supervised Manoeuvre selected (5.21.2.2 S0, E015, "
                & "SUBSET-027 4.2.4.11 M_DRIVERACTIONS 8)");
      end;
   end Scenario_SM_Authorisation;

   --  3.18.3.9, 3.18.3.2.4, 3.18.3.2.5.1, 4.4.21.1.8, 4.4.21.3.1: SM
   --  without valid Train Data, the safe consist length 100 m in front
   --  of the engine and 400 m in rear: from the authorisation the
   --  configured default set (EVC_Config) with the train length of the
   --  max safe consist lengths, the MRSP and the EOA supervised; the set
   --  gone when the mission ends
   procedure Scenario_SM_Default_Data is
      T : Unsigned_64;
   begin
      Start_L2_SM;
      EVC_Core.Handle_Input
        (TIU, SCL_Frame (1, 100, 98, 102, 400, 398, 402));
      Stand_X (300);
      Check (not EVC_Train_Data.Valid and then not EVC_Train_Data.Manoeuvre_Set,
             "SM data: a consist in front of the engine, no valid Train "
             & "Data (3.18.3.5 a))");
      Select_SM;
      T := Wait_For (MCat.Train_M131, 1_000);
      Give_Radio_Message (1, SM_Authorisation (T));
      Stand_X (300);
      Check (EVC_Core.Mode = M_SM and then EVC_Train_Data.Manoeuvre_Set
             and then not EVC_Train_Data.Valid
             and then EVC_Train_Data.Data.Max_Speed = 2_222
             and then EVC_Train_Data.Data.Brake_Percentage = 100,
             "SM data: from the authorisation the default Train Data in "
             & "force, no valid Train Data (3.18.3.9); mode "
             & Mode_T'Image (EVC_Core.Mode));
      Check (EVC_Train_Data.Length = 50_400
             and then EVC_Position.Train_Length_Known
             and then EVC_Position.Length_Of_Train = 50_400,
             "SM data: the train length the sum of the max safe consist "
             & "lengths, 102 + 402 m (3.18.3.2.4, 3.18.3.2.5.1):"
             & Length_T'Image (EVC_Train_Data.Length));
      Check (EVC_Core.Supervision.Active
             and then Natural (EVC_Core.Supervision.V_Perm) = 2_222
             and then EVC_Movement_Authority.MA_Present,
             "SM data: the MRSP and the EOA supervised with the default "
             & "set, the permitted speed its 80 km/h under the SSP's 100 "
             & "(4.4.21.1.8, 4.4.21.3.1):"
             & Natural'Image (Natural (EVC_Core.Supervision.V_Perm)));
      Input (TIU, (Byte (TIU_Signal_T'Pos (Cab_A_Active) + 1), 0));
      Stand_X (300);
      Check (not EVC_Mission.Mission and then not EVC_Train_Data.Manoeuvre_Set
             and then not EVC_Train_Data.Valid,
             "SM data: the mission ended, the default set no longer in "
             & "force, the Train Data still not valid (3.18.3.9)");
   end Scenario_SM_Default_Data;

   --  Message 7 acknowledging the message 133 of time stamp Sent
   function Consist_Ack (Sent : Unsigned_64) return Byte_Array is
      V : ETCS_Message.Value_Array := (others => 0);
   begin
      V (3) := Now_Stamp;
      V (5) := 123;
      V (6) := 10;
      V (7) := Sent;
      return Message_Of (MCat.Track_M7, V);
   end Consist_Ack;

   --  3.18.3.10, 3.18.3.10.1, 3.18.3.10.2: the safe consist length
   --  information for SM (message 133) sent on a change in SB in level 2
   --  with a session and after a request for SM, acknowledged by message
   --  7, sent again after the connection lost and re-established before
   --  the acknowledgement; not sent outside those periods
   procedure Scenario_SM_Consist_Info is
      T  : Unsigned_64;
      N0 : Natural;
   begin
      Start_L2_SM;
      EVC_Core.Handle_Input (TIU, SCL_Frame (1, 0, 0, 0, 300, 298, 302));
      Check (Wait_For (MCat.Train_M133, 1_000) = 0,
             "SM consist: in FS without a request no message 133 "
             & "(3.18.3.10)");
      EVC_Core.Set_Mode_For_Test (M_SB, L2);
      Stand_X (300);
      EVC_Core.Handle_Input (TIU, SCL_Frame (1, 0, 0, 0, 400, 398, 402));
      T := Wait_For (MCat.Train_M133, 1_000);
      Check (T /= 0 and then EVC_Sessions.SM_Consist_Awaited,
             "SM consist: in SB in level 2 with a session, a changed safe "
             & "consist length sent by message 133 (3.18.3.10)");
      Give_Radio_Message (1, Consist_Ack (T));
      Stand_X (300);
      Check (not EVC_Sessions.SM_Consist_Awaited,
             "SM consist: message 7 acknowledges it (3.18.3.10.1)");
      --  after a request for SM in FS: the safe consist length becoming
      --  unavailable is sent; the connection lost before the
      --  acknowledgement, the information sent again once re-established
      Start_L2_SM;
      Select_SM;
      Check (Wait_For (MCat.Train_M131, 1_000) /= 0,
             "SM consist: the request for SM sent");
      N0 := EVC_Sessions.SM_Consist_Sent;
      EVC_Core.Handle_Input (TIU, SCL_Frame (0));
      T := Wait_For (MCat.Train_M133, 1_000);
      Check (T /= 0 and then EVC_Sessions.SM_Consist_Sent = N0 + 1,
             "SM consist: after the request, the safe consist length "
             & "unavailable sent by message 133 (3.18.3.10)");
      EVC_Radio.Set_State (1, EVC_Radio.Connection_Lost);
      Stand_X (300);
      EVC_Radio.Set_State (1, EVC_Radio.Established);
      T := Wait_For (MCat.Train_M133, 1_000);
      Check (T /= 0 and then EVC_Sessions.SM_Consist_Sent = N0 + 2,
             "SM consist: the connection lost before the acknowledgement "
             & "and re-established, message 133 sent again (3.18.3.10.2)");
      Give_Radio_Message (1, Consist_Ack (T));
      Stand_X (300);
      Check (not EVC_Sessions.SM_Consist_Awaited,
             "SM consist: the resent one acknowledged (3.18.3.10.1)");
   end Scenario_SM_Consist_Info;

   --  3.15.1.3.3: in Supervised Manoeuvre the session with the Accepting
   --  RBC, once established, gets the safe consist length information
   --  (message 133) instead of the Train Data (129); message 7 on that
   --  session acknowledges it (3.18.3.10.1)
   procedure Scenario_SM_Handover is
      T  : Unsigned_64;
      N0 : Natural;
      D0 : Natural;
   begin
      Start_L2_SM;
      Select_SM;
      T := Wait_For (MCat.Train_M131, 1_000);
      Give_Radio_Message (1, SM_Authorisation (T));
      Stand_X (300);
      Check (EVC_Core.Mode = M_SM, "SM handover: SM entered");
      N0 := EVC_Sessions.SM_Consist_Sent;
      D0 := EVC_Sessions.Train_Data_Sent;
      EVC_Radio.Set_Peer (2, (NID_C => 123, NID_RBC => 2), 0);
      EVC_Radio.Set_State (2, EVC_Radio.Established);
      EVC_Radio.Set_Version (2, 33);
      EVC_Radio.Set_Roles (1, 2);
      T := Wait_On (MCat.Train_M133, 2, 1_000);
      Check (T /= 0 and then EVC_Sessions.SM_Consist_Sent = N0 + 1
             and then EVC_Sessions.Train_Data_Sent = D0
             and then EVC_Sessions.SM_Consist_Awaited,
             "SM handover: the session with the Accepting RBC established, "
             & "message 133 sent on it, not the Train Data (3.15.1.3.3)");
      Give_Radio_Message (2, Consist_Ack (T));
      Stand_X (300);
      Check (not EVC_Sessions.SM_Consist_Awaited,
             "SM handover: message 7 of the Accepting RBC acknowledges it "
             & "(3.18.3.10.1)");
      Check (Wait_On (MCat.Train_M133, 2, 1_000) = 0
             and then EVC_Sessions.Train_Data_Sent = D0,
             "SM handover: sent once (3.15.1.3.3)");
   end Scenario_SM_Handover;

   --  The sm_direction of the last MSG_STATUS sent in Max_Ms, 16#FFFF#
   --  when none was sent
   function Last_SM_Direction (Max_Ms : Natural) return Natural is
      Last : Natural := 16#FFFF#;
   begin
      for C in 1 .. Max_Ms / 100 loop
         Stand_X (100);
         if Status_SM_Direction /= 16#FFFF# then
            Last := Status_SM_Direction;
         end if;
      end loop;
      return Last;
   end Last_SM_Direction;

   --  4.4.21.1.9, DMI 8.2.3.10: the SM authorised direction to the DMI,
   --  forward (SM01) after an authorisation in the orientation of the
   --  active cab, backward (SM02) after one opposite to it, none outside
   --  Supervised Manoeuvre
   procedure Scenario_SM_Direction is
      T : Unsigned_64;
   begin
      Start_L2_SM;
      Check (Last_SM_Direction (300) in 0 | 16#FFFF#,
             "SM direction: none in FS (4.4.21.1.9)");
      Select_SM;
      T := Wait_For (MCat.Train_M131, 1_000);
      Give_Radio_Message (1, SM_Authorisation (T));
      Check (Last_SM_Direction (500) = 1 and then EVC_Core.Mode = M_SM,
             "SM direction: the authorisation in the active cab's "
             & "orientation shown forward, SM01 (4.4.21.1.9, DMI "
             & "8.2.3.10)");
      EVC_Core.Set_Mode_For_Test (M_FS, L2);
      Check (Last_SM_Direction (300) = 0,
             "SM direction: none once the mode is no longer SM "
             & "(4.4.21.1.9)");
      Start_L2_SM;
      Select_SM;
      T := Wait_For (MCat.Train_M131, 1_000);
      Give_Radio_Message (1, SM_Authorisation (T, Q_DIR => 0));
      Check (Last_SM_Direction (500) = 2 and then EVC_Core.Mode = M_SM,
             "SM direction: the authorisation opposite to the active "
             & "cab shown backward, SM02 (4.4.21.1.9, DMI 8.2.3.10)");
   end Scenario_SM_Direction;

   procedure Scenario_SM_Request is
      T : Unsigned_64;
   begin
      Start_L2_SM;
      Check (EVC_Core.Mode = M_FS and then not EVC_Sessions.SM_Waiting,
             "SM request: FS in level 2, the safe consist length available");
      Select_SM;
      T := Wait_For (MCat.Train_M131, 1_000);
      Check (T /= 0 and then EVC_Sessions.SM_Waiting
             and then EVC_Sessions.SM_Requests_Sent = 1,
             "SM request: 'Initiate SM' at standstill sends message 131 "
             & "and waits for the RBC (5.21.2.2 S0, E015, A045, S050)");
      Give_Radio_Message (1, SM_Refused (T + 1));
      Stand_X (200);
      Check (EVC_Sessions.SM_Waiting,
             "SM request: an answer to another request not taken (4.8.4 "
             & "[14])");
      declare
         Shown : constant Natural :=
           SS_Seen (Natural (EVC_DMI_Port.SS_SM_Refused));
      begin
         EVC_Core.Set_Mode_For_Test (M_FS, L1);
         Give_Radio_Message (1, SM_Refused (T));
         Stand_X (200);
         Check (EVC_Sessions.SM_Waiting
                and then SS_Seen (Natural (EVC_DMI_Port.SS_SM_Refused))
                         = Shown,
                "SM request: SM refused in level 1, rejected by 4.8.3, "
                & "neither ends the wait nor is shown (4.8.4, B952)");
         EVC_Core.Set_Mode_For_Test (M_FS, L2);
         Stand_X (200);
      end;
      Give_Radio_Message (1, SM_Refused (T));
      Stand_X (200);
      Check (not EVC_Sessions.SM_Waiting and then EVC_Sessions.SM_Answer = 0
             and then EVC_Core.Mode = M_FS,
             "SM request: SM refused ends the wait, the mode stays "
             & "(5.21.2.2 E215, A220)");

      --  5.21.4.1: no answer
      Select_SM;
      Check (Wait_For (MCat.Train_M131, 1_000) /= 0
             and then Wait_For (MCat.Train_M131, 14_000) = 0
             and then Wait_For (MCat.Train_M131, 2_000) /= 0
             and then Wait_For (MCat.Train_M131, 16_000) /= 0
             and then Wait_For (MCat.Train_M131, 16_000) /= 0,
             "SM request: no answer, 131 repeated every 15 s, 3 times "
             & "(5.21.4.1)");
      Check (Wait_For (MCat.Train_M131, 16_000) = 0
             and then not EVC_Sessions.SM_Waiting
             and then EVC_Core.Mode = M_FS,
             "SM request: then the request ends, the driver informed "
             & "(5.21.4.1)");

      --  S0: no request without the safe consist length
      EVC_Core.Handle_Input (TIU, SCL_Frame (0));
      Stand_X (300);
      Select_SM;
      Check (Wait_For (MCat.Train_M131, 2_000) = 0
             and then not EVC_Sessions.SM_Waiting,
             "SM request: none without the safe consist length available "
             & "(5.21.2.2 S0, 4.4.21.1.3)");

      --  A045: the report's front end from the safe consist length in
      --  front of the engine
      EVC_Core.Handle_Input (TIU, SCL_Frame (1, 0, 0, 0, 400, 398, 402));
      Stand_X (300);
      Check (Same_Report,
             "SM request: nothing in front of the engine, the report of 131 "
             & "is the position report (5.21.2.2 A045)");
      EVC_Core.Handle_Input (TIU, SCL_Frame (1, 50, 49, 52, 400, 398, 402));
      Stand_X (300);
      Check (Front_Moved (5_000, 100, 200),
             "SM request: 50 m in front of the engine (49 .. 52), the report "
             & "of 131 has its front end 50 m ahead, the confidence interval "
             & "1 m and 2 m wider (5.21.2.2 A045, 3.18.3.2.5.1)");
      Select_SM;
      Check (Wait_For (MCat.Train_M131, 1_000) /= 0,
             "SM request: 131 sent with the consist in front (5.21.2.2 "
             & "A045)");
   end Scenario_SM_Request;

   --  4.8.4 [1] in level 2, Post Trip: message 5 (SM refused) is taken
   --  only after the recognition of the exit from TR (message 6) with a
   --  more recent time stamp than the trip; a message 6 stamped before
   --  the trip does not count, for the session half (message 5) and the
   --  authority half (EVC_Radio_Authority.Trip_Exit_Recognised) alike
   procedure Scenario_SM_Post_Trip is
      T, Before : Unsigned_64;
      Shown     : Natural;
      function M6 (Stamp : Unsigned_64) return Byte_Array is
         V : ETCS_Message.Value_Array := (others => 0);
      begin
         V (3) := Stamp;
         V (5) := 123;
         V (6) := 10;
         return Message_Of (MCat.Track_M6, V);
      end M6;
   begin
      Start_L2_SM;
      Stand_X (200);
      Before := Now_Stamp;
      --  the trip by an unconditional emergency stop (message 16), then
      --  the driver's acknowledgement: PT
      declare
         V : ETCS_Message.Value_Array := (others => 0);
      begin
         V (3) := Before;
         V (5) := 123;
         V (6) := 10;
         V (7) := 3;
         Give_Radio_Message (1, Message_Of (MCat.Track_M16, V));
      end;
      Stand_X (500);
      EVC_Core.Handle_Input
        (DMI, Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 1, 0, 0, 0)));
      Stand_X (500);
      Check (EVC_Core.Mode = M_PT,
             "SM post trip: the trip acknowledged, PT, got "
             & EVC_Core.Mode'Image);
      --  consistent (3.16.3.3.3: above message 16) but before the trip
      Give_Radio_Message (1, M6 (Before + 1));
      Stand_X (200);
      Select_SM;
      T := Wait_For (MCat.Train_M131, 1_000);
      Shown := SS_Seen (Natural (EVC_DMI_Port.SS_SM_Refused));
      Give_Radio_Message (1, SM_Refused (T));
      Stand_X (200);
      Check (T /= 0 and then EVC_Sessions.SM_Waiting
             and then SS_Seen (Natural (EVC_DMI_Port.SS_SM_Refused))
                      = Shown,
             "SM post trip: message 6 stamped before the trip, SM refused "
             & "rejected (4.8.4 [1])");
      --  one recognition for both halves: the authority half takes no
      --  exit from TR the session half did not recognise
      Check (not EVC_Radio.Trip_Exit_Recognised
             and then not EVC_Radio_Authority.Trip_Exit_Recognised,
             "SM post trip: message 6 stamped before the trip, no exit "
             & "from TR recognised by either half (4.8.4 [1])");
      Give_Radio_Message (1, M6 (Now_Stamp));
      Stand_X (200);
      Check (EVC_Radio.Trip_Exit_Recognised
             and then EVC_Radio_Authority.Trip_Exit_Recognised,
             "SM post trip: message 6 more recent than the trip, the exit "
             & "from TR recognised by both halves (4.8.4 [1])");
      Give_Radio_Message (1, SM_Refused (T));
      Stand_X (200);
      Check (not EVC_Sessions.SM_Waiting
             and then SS_Seen (Natural (EVC_DMI_Port.SS_SM_Refused))
                      > Shown,
             "SM post trip: message 6 more recent than the trip, SM "
             & "refused taken and shown (4.8.4 [1])");
   end Scenario_SM_Post_Trip;

end EVC_Test_Manoeuvre;
