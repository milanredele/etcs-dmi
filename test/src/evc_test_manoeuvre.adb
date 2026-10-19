--  ETCS on-board (EVC) regression: Supervised Manoeuvre, implementation.

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P15;
with ETCS_Track_Packets.P21;
with ETCS_Track_Packets.P27;
with ETCS_Variables;
with EVC_Core;
with EVC_Modes;           use EVC_Modes;
with EVC_Ports;           use EVC_Ports;
with EVC_Radio;
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
   end Scenario_SM_Authorisation;

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
   end Scenario_SM_Request;

end EVC_Test_Manoeuvre;
