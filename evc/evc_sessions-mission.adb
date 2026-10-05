--  ETCS on-board (EVC)
--  Phase E5, session and link, phase 2: the level 2 start and end of
--  mission and the Train Data to the RBC (see the specification).

with ETCS_Bits;
with ETCS_Message;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P11;
with EVC_Bytes;
with EVC_Ports;
with Interfaces;       use Interfaces;
with ETCS_Variables;   use ETCS_Variables;

package body EVC_Sessions.Mission
  with SPARK_Mode => On,
       Refined_State => (State => (Step, SoM_RBC, SoM_S, Report_Valid,
                                   Reject_Due, Reject_S,
                                   TD_Due, TD_Awaited, TD_Stamp, TD_Since,
                                   TD_S, Was_Up,
                                   EoM_Due, EoM_Awaited, EoM_Since,
                                   EoM_Repeats, EoM_S,
                                   Confirm, Delete, N_TD, N_Rep, N_EoM))
is
   package R renames EVC_Radio;
   use type R.Session_State_T;
   use type R.Session_Ref_T;
   use type R.Session_T;
   use type R.RBC_Id_T;
   use type EVC_Mission.Data_Status_T;

   --  A.3.1 "Waiting time before radio message repetition" (15 s) and
   --  "Repetition of radio messages" (3, excluding the first sending)
   Repeat_Ms   : constant := 15_000;
   Max_Repeats : constant := 3;

   --  Q_STATUS (7.5.1.110.1): 0 invalid, 1 valid, 2 unknown
   Q_Invalid : constant := 0;
   Q_Valid   : constant := 1;
   Q_Unknown : constant := 2;

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   --  The steps of the start of mission this half follows: Idle (no
   --  start of mission, or D2 not reached), Decided (D2 passed: S2, S3,
   --  S10 ...), Opening (A31, until D31), Report_Due (D32: the SoM
   --  position report of the next Produce), Reported (S10 after A33 /
   --  A34, the RBC's answer may come)
   type Step_T is (Idle, Decided, Opening, Report_Due, Reported);
   Step         : Step_T := Idle;
   SoM_RBC      : R.RBC_Id_T := R.No_RBC;
   SoM_S        : R.Session_T := 1;
   --  the SoM position report said "valid train position referred to an
   --  LRBG"
   Report_Valid : Boolean := False;
   --  A40: the session to terminate, then "Train is rejected"
   Reject_Due   : Boolean := False;
   Reject_S     : R.Session_T := 1;

   --  3.18.3.4: the Train Data to send (TD_Due), sent and awaiting their
   --  acknowledgement (message 8 with TD_Stamp) in TD_S since TD_Since;
   --  Was_Up: the supervising session was established at the last cycle
   TD_Due       : Boolean := False;
   TD_Awaited   : Boolean := False;
   TD_Stamp     : T_TRAIN_T := 0;
   TD_Since     : R.Time_Ms_T := 0;
   TD_S         : R.Session_T := 1;
   Was_Up       : Boolean := False;

   --  5.5.3.1.3, 5.5.4.1.1: End of Mission to send, sent and repeated
   --  while the desk is open until the RBC terminates the session
   EoM_Due      : Boolean := False;
   EoM_Awaited  : Boolean := False;
   EoM_Since    : R.Time_Ms_T := 0;
   EoM_Repeats  : Natural range 0 .. Max_Repeats := 0;
   EoM_S        : R.Session_T := 1;

   Confirm      : Boolean := False;
   Delete       : Boolean := False;
   N_TD         : Natural := 0;
   N_Rep        : Natural := 0;
   N_EoM        : Natural := 0;

   function Position_Confirmed return Boolean is (Confirm)
     with Refined_Global => Confirm;
   function Position_To_Delete return Boolean is (Delete)
     with Refined_Global => Delete;
   function Opening return Boolean is (Step = Opening)
     with Refined_Global => Step;
   function Reporting return Boolean is
     (Step = Step_T'(Opening) or else Step = Report_Due)
     with Refined_Global => Step;
   function Train_Data_Sent return Natural is (N_TD)
     with Refined_Global => N_TD;
   function Reports_Sent return Natural is (N_Rep)
     with Refined_Global => N_Rep;
   function EoM_Sent return Natural is (N_EoM)
     with Refined_Global => N_EoM;

   procedure Bump (N : in out Natural) is
   begin
      if N < Natural'Last then
         N := N + 1;
      end if;
   end Bump;

   function Elapsed (Since, Now : R.Time_Ms_T) return R.Time_Ms_T is
     (if Now >= Since then Now - Since else 0);

   --  The session S is established (3.5.3.7 d: the system version agreed)
   function Up (S : R.Session_T) return Boolean is
     (R.Usable (S) and then R.Info (S).State = R.Established
      and then R.Info (S).Version_Known)
     with Global => R.State;

   procedure Clear is
   begin
      Step := Idle;
      SoM_RBC := R.No_RBC;
      SoM_S := 1;
      Report_Valid := False;
      Reject_Due := False;
      Reject_S := 1;
      TD_Due := False;
      TD_Awaited := False;
      TD_Stamp := 0;
      TD_Since := 0;
      TD_S := 1;
      Was_Up := False;
      EoM_Due := False;
      EoM_Awaited := False;
      EoM_Since := 0;
      EoM_Repeats := 0;
      EoM_S := 1;
      Confirm := False;
      Delete := False;
      N_TD := 0;
      N_Rep := 0;
      N_EoM := 0;
   end Clear;

   ---------------------------------------------------------------------
   --  1. The answers of the RBC
   ---------------------------------------------------------------------

   --  D34, D35: the position is kept when it is valid and was not
   --  reported "valid referred to an LRBG" (decision 5), else deleted
   --  (A24, A39)
   procedure Judge_Position
     with Global => (Input  => (EVC_Position.State, Report_Valid),
                     Output => Delete)
   is
   begin
      Delete := not (EVC_Position.Status = EVC_Position.Valid
                     and then not Report_Valid);
   end Judge_Position;

   procedure Take_Answer (S     : EVC_Radio.Session_T;
                          Kind  : Message_Kind_T;
                          Taken : out Boolean)
   is
   begin
      Taken := Kind in Track_M8 | Track_M40 | Track_M41 | Track_M43;
      case Kind is
         when Track_M8 =>
            --  3.18.3.4.1, decision 3
            if TD_Awaited and then S = TD_S
              and then T_TRAIN_T (EVC_Received.Last_Field (6)
                                  and 16#FFFF_FFFF#) = TD_Stamp
            then
               TD_Awaited := False;
               R.Set_Train_Data_Acknowledged (True);
            end if;
         when Track_M43 =>
            --  A35: the reported position is valid
            if Step = Reported
              and then EVC_Position.Status = EVC_Position.Invalid
            then
               Confirm := True;
            end if;
         when Track_M41 =>
            --  A23 / D34: accepted without a valid position
            if Step = Reported then
               Judge_Position;
            end if;
         when Track_M40 =>
            --  A38 / D35: rejected; A40 the session terminated
            if Step = Reported then
               Judge_Position;
               Reject_Due := True;
               Reject_S := S;
            end if;
         when others =>
            null;
      end case;
   end Take_Answer;

   ---------------------------------------------------------------------
   --  5. The start of mission (5.4.3.2)
   ---------------------------------------------------------------------

   --  S3: the RBC contact information the driver gave (DMI 11.3.5,
   --  MSG_DRIVER_DATA kind 5 of dmi_protocol.ads): choice 0 entered (the
   --  RBC ID, NID_C above the 14 bits of NID_RBC; the phone number,
   --  NID_RADIO as 16 BCD digits padded with F, 7.5.1.95), 1 'Contact
   --  last RBC' (the stored contact, 3.5.3.13), 2 'Use short number'
   --  (NID_RADIO all F, 3.5.3.11: the stored RBC ID and number not
   --  used; decision: the RBC identity is unknown, 0). Found: usable;
   --  Entered: choice 0 (5.4.3.3 "Following S3": the contact valid)
   procedure Driver_Contact (Found, Entered : out Boolean;
                             C              : out R.RBC_Contact_T)
     with Global => (Input => (EVC_Driver_Requests.State, R.State))
   is
      B     : constant EVC_Driver_Requests.Bytes_23_T :=
        EVC_Driver_Requests.RBC_Data;
      N     : constant Natural := Natural'Min (Natural (B (6)), 16);
      Id    : Unsigned_32;
      Radio : Unsigned_64 := 0;
   begin
      C := R.Contact;
      Found := False;
      Entered := False;
      case B (1) is
         when 0 =>
            Id := Unsigned_32 (B (2))
              or Shift_Left (Unsigned_32 (B (3)), 8)
              or Shift_Left (Unsigned_32 (B (4)), 16)
              or Shift_Left (Unsigned_32 (B (5)), 24);
            if Id <= 16_777_214 then
               for I in 1 .. 16 loop
                  pragma Loop_Invariant (True);
                  Radio := Shift_Left (Radio, 4)
                    or (if I <= N and then B (6 + I) in 48 .. 57
                        then Unsigned_64 (B (6 + I) - 48) else 16#F#);
               end loop;
               C := (Known => True, Valid => True,
                     RBC   => (NID_C   => NID_C_T (Id / 2**14),
                               NID_RBC => NID_RBC_T (Id mod 2**14)),
                     Radio => NID_RADIO_T (Radio));
               Found := True;
               Entered := True;
            end if;
         when 1 =>
            Found := C.Known;
         when 2 =>
            C := (Known => True, Valid => C.Valid, RBC => R.No_RBC,
                  Radio => NID_RADIO_T'Last);
            Found := True;
         when others =>
            null;
      end case;
   end Driver_Contact;

   --  A31: the session with RBC opened, three attempts (A.3.1)
   procedure Open_SoM (RBC   : R.RBC_Id_T;
                       Radio : NID_RADIO_T;
                       Req   : in out Request_T)
     with Global => (Output => (Step, SoM_RBC, Report_Valid))
   is
   begin
      Req.Open := True;
      Req.RBC := RBC;
      Req.Radio := Radio;
      SoM_RBC := RBC;
      Step := Opening;
      Report_Valid := False;
   end Open_SoM;

   --  D31: opened (the system version agreed: D32, and 5.4.3.3
   --  "Following D31" the contact valid) or failed (A32: no session
   --  with the RBC any more; the driver is informed by the indication
   --  of 3.5.7, EVC_Sessions: S10)
   procedure Judge_Opening
     with Global => (In_Out => (Step, R.State),
                     Input  => SoM_RBC,
                     Output => SoM_S)
   is
      Any   : Boolean := False;
      Found : R.Session_Ref_T := R.No_Session;
   begin
      SoM_S := 1;
      for S in R.Session_T loop
         pragma Loop_Invariant (True);
         if R.Usable (S) and then R.Info (S).State /= R.Idle
           and then R.Info (S).RBC = SoM_RBC
         then
            Any := True;
            if Up (S) then
               Found := R.Session_Ref_T (S);
            end if;
         end if;
      end loop;
      if Found /= R.No_Session then
         SoM_S := R.Session_T (Found);
         R.Set_Contact ((Known => True, Valid => True,
                         RBC   => R.Info (SoM_S).RBC,
                         Radio => R.Info (SoM_S).Radio));
         Step := Report_Due;
      elsif not Any then
         Step := Decided;
      end if;
   end Judge_Opening;

   procedure Evaluate_SoM (Ctx : R.Context_T; Req : in out Request_T)
     with Global => (In_Out => (Step, SoM_RBC, SoM_S, Report_Valid,
                                Reject_Due, R.State),
                     Input  => (Reject_S, EVC_Mission.State,
                                EVC_Levels.State, EVC_Position.State,
                                EVC_Driver_Requests.State))
   is
      C       : R.RBC_Contact_T := R.Contact;
      Found   : Boolean;
      Entered : Boolean;
      Sv      : constant R.Session_Ref_T := R.Supervising;
   begin
      if Ctx.Mode /= M_SB or else not EVC_Mission.SoM_Engaged then
         --  5.4.3.2.2: the desk closed during the start of mission
         if Step /= Idle and then Ctx.Mode = M_SB
           and then EVC_Position.Active_Cab = EVC_Position.No_Cab
           and then Sv /= R.No_Session
         then
            Req.Stop := True;
            Req.Session := R.Session_T (Sv);
         end if;
         Step := Idle;
         Reject_Due := False;
         return;
      end if;
      --  D2 once the Driver ID is entered or revalidated (E1)
      if Step = Idle
        and then EVC_Mission.Driver_ID_Status = EVC_Mission.Valid
      then
         Step := Decided;
         if EVC_Position.Status /= EVC_Position.Valid
           or else not EVC_Levels.Valid
         then
            --  5.4.3.3 "Following D2": the contact valid -> invalid
            if C.Valid then
               C.Valid := False;
               R.Set_Contact (C);
            end if;
         elsif EVC_Levels.Level = L2 and then C.Known then
            --  D3 -> D7 -> A31 (decision 1)
            Open_SoM (C.RBC, C.Radio, Req);
         end if;
      end if;
      --  S3, and 5.4.5.3 j) at S10 / S20: the driver's RBC contact
      if Step in Decided | Reported
        and then EVC_Driver_Requests.Entered (EVC_Driver_Requests.RBC_Data)
        and then EVC_Levels.Valid and then EVC_Levels.Level = L2
      then
         Driver_Contact (Found, Entered, C);
         if Found then
            if Entered then
               R.Set_Contact (C);
            end if;
            Open_SoM (C.RBC, C.Radio, Req);
         end if;
      end if;
      if Step = Opening and then not Req.Open then
         Judge_Opening;
      end if;
      --  A40: the session terminated, the driver informed; S10
      if Reject_Due then
         Reject_Due := False;
         Req.Stop := True;
         Req.Session := Reject_S;
         Req.Rejected := True;
         Step := Decided;
      end if;
   end Evaluate_SoM;

   ---------------------------------------------------------------------
   --  5. The Train Data to the RBC (3.18.3.4)
   ---------------------------------------------------------------------

   --  Sent when the supervising session is established with valid Train
   --  Data (not while the start of mission sends its report, decision
   --  2), when the driver validates them in a session, again after a
   --  connection lost before the acknowledgement (3.18.3.4.2) and every
   --  Repeat_Ms until acknowledged (decision 4); the acknowledgement is
   --  forgotten with the session
   procedure Evaluate_TD (Ctx : R.Context_T)
     with Global => (In_Out => (TD_Due, TD_Awaited, Was_Up, R.State),
                     Input  => (TD_Since, Step, EVC_Train_Data.State,
                                EVC_Mission.State))
   is
      Sv    : constant R.Session_Ref_T := R.Supervising;
      Is_Up : constant Boolean :=
        Sv /= R.No_Session and then Up (R.Session_T (Sv));
   begin
      if not Is_Up then
         if not (Sv /= R.No_Session
                 and then R.Info (R.Session_T (Sv)).State
                            = R.Connection_Lost)
         then
            TD_Awaited := False;
            TD_Due := False;
            if R.Train_Data_Acknowledged then
               R.Set_Train_Data_Acknowledged (False);
            end if;
         end if;
         Was_Up := False;
         return;
      end if;
      if EVC_Train_Data.Valid and then Step not in Opening | Report_Due
        and then ((not Was_Up
                   and then (TD_Awaited
                             or else not R.Train_Data_Acknowledged))
                  or else EVC_Mission.Train_Data_Validated
                  or else (TD_Awaited
                           and then Elapsed (TD_Since, Ctx.Now_Ms)
                                      >= Repeat_Ms))
      then
         TD_Due := True;
      end if;
      Was_Up := True;
   end Evaluate_TD;

   ---------------------------------------------------------------------
   --  5. The end of mission (5.5.3.1.3, 5.5.3.1.4, 5.5.4.1.1)
   ---------------------------------------------------------------------

   procedure Evaluate_EoM (Ctx : R.Context_T; Req : in out Request_T)
     with Global => (In_Out => (EoM_Awaited, EoM_Due, EoM_Repeats),
                     Input  => (EoM_Since, EoM_S, R.State,
                                EVC_Position.State))
   is
   begin
      if not EoM_Awaited then
         return;
      end if;
      if not Up (EoM_S)
        or else EVC_Position.Active_Cab = EVC_Position.No_Cab
      then
         --  terminated (5.5.3.1.4 steps 3, 4), or the desk closed: the
         --  end of the procedure (5.5.3.1.3)
         EoM_Awaited := False;
      elsif Elapsed (EoM_Since, Ctx.Now_Ms) >= Repeat_Ms then
         if EoM_Repeats < Max_Repeats then
            EoM_Repeats := EoM_Repeats + 1;
            EoM_Due := True;
         else
            --  5.5.4.1.1: no reply after the last repetition
            EoM_Awaited := False;
            Req.Stop := True;
            Req.Session := EoM_S;
         end if;
      end if;
   end Evaluate_EoM;

   procedure Evaluate (Ctx : EVC_Radio.Context_T; Req : out Request_T) is
   begin
      Req := (others => <>);
      Evaluate_SoM (Ctx, Req);
      Evaluate_TD (Ctx);
      Evaluate_EoM (Ctx, Req);
   end Evaluate;

   --  5.5.2.1, 5.5.2.3: the modes entered that end a mission (from PT:
   --  when a mission was going on, EVC_Mission.Mission)
   procedure Mode_Changed (From, To : EVC_Modes.Mode_T) is
      Sv         : constant R.Session_Ref_T := R.Supervising;
      PT_Mission : constant Boolean :=
        From = M_PT and then EVC_Mission.Mission;
      EoM        : constant Boolean :=
        (To = M_SB
         and then (From in M_FS | M_AD | M_LS | M_OS | M_SM | M_UN | M_NL
                         | M_SR | M_RV | M_SN
                   or else PT_Mission))
        or else
        (To = M_SH
         and then (From in M_FS | M_AD | M_LS | M_OS | M_SR | M_SM | M_SN
                         | M_UN
                   or else PT_Mission));
   begin
      if EoM and then Sv /= R.No_Session and then Up (R.Session_T (Sv))
      then
         EoM_Due := True;
         EoM_S := R.Session_T (Sv);
         EoM_Repeats := 0;
         EoM_Awaited := False;
      end if;
   end Mode_Changed;

   ---------------------------------------------------------------------
   --  8. The messages (8.6.1 129, 8.6.10 150, 8.6.15 157)
   ---------------------------------------------------------------------

   subtype Writer_T is ETCS_Bits.Writer (128);

   --  Packet 11 (7.4.2.3.4) from the Train Data (3.18.3.4 a to i):
   --  L_TRAIN in m, V_MAXTRAIN in 5 km/h steps (the speed rounded to the
   --  km/h first), the traction systems of the bits of Voltages (bit k:
   --  M_VOLTAGE k, NID_CTRACTION 0), no National System; decision 6
   function Train_Packet return ETCS_Train_Packets.P11.Packet_T
     with Global => EVC_Train_Data.State
   is
      Cat  : constant EVC_Train_Data.Categories_T :=
        EVC_Train_Data.Categories;
      Len  : constant Natural :=
        (if EVC_Train_Data.Data.Length in 0 .. 409_500
         then Natural (EVC_Train_Data.Data.Length) / 100 else 4095);
      Kmh  : constant Natural :=
        (Natural (EVC_Train_Data.Data.Max_Speed) * 36 + 500) / 1000;
      P    : ETCS_Train_Packets.P11.Packet_T;
      N    : Natural range 0 .. 5 := 0;
   begin
      P.NC_CDTRAIN := Cat.Cant_Deficiency;
      P.NC_TRAIN := Cat.Other;
      P.L_TRAIN := L_TRAIN_T (Natural'Min (Len, 4095));
      P.V_MAXTRAIN := V_MAXTRAIN_T (Natural'Min (Kmh / 5, 120));
      P.M_LOADINGGAUGE := Cat.Loading_Gauge;
      P.M_AXLELOADCAT := Cat.Axle_Load;
      P.M_AIRTIGHT := 0;
      P.N_AXLE := 0;
      for V in 1 .. 5 loop
         pragma Loop_Invariant (N < V);
         if (Cat.Voltages / 2**V) mod 2 = 1 then
            N := N + 1;
            P.M_VOLTAGE_List (N) :=
              (M_VOLTAGE         => M_VOLTAGE_T (V),
               Has_NID_CTRACTION => True,
               NID_CTRACTION     => 0);
         end if;
      end loop;
      P.N_ITER := N_ITER_T (N);
      P.N_ITER_2 := 0;
      return P;
   end Train_Packet;

   --  The header of Kind (8.4.4.7.1) with T, NID_ENGINE and V5, then
   --  packet 0 (EVC_Position.Position_Report, 3.6.5.1.2)
   procedure Start (W    : in out Writer_T;
                    Kind : Known_Message_T;
                    T    : T_TRAIN_T;
                    V5   : Unsigned_64;
                    Mode : EVC_Modes.Mode_T;
                    OK   : out Boolean)
     with Global => (Input => (R.State, EVC_Position.State,
                               EVC_Odometry.State, EVC_Levels.State))
   is
      V : ETCS_Message.Value_Array := (others => 0);
   begin
      ETCS_Bits.Clear (W);
      V (3) := Unsigned_64 (T);
      V (4) := Unsigned_64 (R.Engine_Id);
      V (5) := V5;
      ETCS_Message.Write_Fields (W, Kind, V, OK);
      if OK then
         ETCS_Train_Packets.P0.Encode
           (EVC_Position.Position_Report (Mode, EVC_Levels.Level), W, OK);
      end if;
   end Start;

   --  The padding and L_MESSAGE, then the message to the outbox of S
   procedure Finish_And_Send (W  : in out Writer_T;
                              S  : R.Session_T;
                              OK : in out Boolean)
     with Global => (In_Out => (R.State, R.Queue))
   is
   begin
      if OK then
         ETCS_Message.Finish (W, OK);
      end if;
      if OK then
         declare
            M : constant EVC_Bytes.Byte_Array := ETCS_Bits.Data (W);
         begin
            OK := EVC_Ports.Valid_RTM (M);
            if OK then
               R.Send (S, M);
            end if;
         end;
      end if;
   end Finish_And_Send;

   pragma Warnings
     (GNATprove, Off, """W"" is set by ""Finish_And_Send"" but not used*",
      Reason => "the writer of one message is not used after it");

   --  The Train Data are awaiting their acknowledgement (message 8)
   procedure Await_TD (S    : R.Session_T; T : T_TRAIN_T;
                       Now  : R.Time_Ms_T;
                       Sent : Boolean)
     with Global => (In_Out => (R.State, N_TD),
                     Output => (TD_Awaited, TD_Stamp, TD_Since, TD_S))
   is
   begin
      TD_Awaited := True;
      TD_Stamp := T;
      TD_Since := Now;
      TD_S := S;
      R.Set_Train_Data_Acknowledged (False);
      if Sent then
         Bump (N_TD);
      end if;
   end Await_TD;

   --  A33, A34: the SoM position report with Q_STATUS, and packet 11
   --  when the Train Data are valid (decision 2)
   procedure Send_Report (S : R.Session_T; Ctx : R.Context_T; T : T_TRAIN_T)
     with Global => (In_Out => (R.State, R.Queue, N_TD, N_Rep, TD_Awaited,
                                TD_Stamp, TD_Since, TD_S),
                     Output => Report_Valid,
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Train_Data.State))
   is
      Q  : constant Unsigned_64 :=
        (if not EVC_Position.LRBG.Valid then Q_Unknown
         elsif EVC_Position.Status = EVC_Position.Valid then Q_Valid
         elsif EVC_Position.Status = EVC_Position.Invalid then Q_Invalid
         else Q_Unknown);
      TD : constant Boolean := EVC_Train_Data.Valid;
      W  : Writer_T;
      OK : Boolean;
   begin
      Report_Valid := Q = Q_Valid;
      Start (W, Train_M157, T, Q, Ctx.Mode, OK);
      if OK and then TD then
         ETCS_Train_Packets.P11.Encode (Train_Packet, W, OK);
      end if;
      Finish_And_Send (W, S, OK);
      if OK then
         Bump (N_Rep);
         if TD then
            Await_TD (S, T, Ctx.Now_Ms, Sent => True);
         end if;
      end if;
   end Send_Report;

   --  3.18.3.4: message 129 with packets 0 and 11
   procedure Send_TD (S : R.Session_T; Ctx : R.Context_T; T : T_TRAIN_T)
     with Global => (In_Out => (R.State, R.Queue, N_TD),
                     Output => (TD_Awaited, TD_Stamp, TD_Since, TD_S),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Train_Data.State))
   is
      W  : Writer_T;
      OK : Boolean;
   begin
      Start (W, Train_M129, T, 0, Ctx.Mode, OK);
      if OK then
         ETCS_Train_Packets.P11.Encode (Train_Packet, W, OK);
      end if;
      Finish_And_Send (W, S, OK);
      --  a message that could not be built is not awaited: tried again
      --  at the next repetition time, as if sent
      Await_TD (S, T, Ctx.Now_Ms, Sent => OK);
   end Send_TD;

   --  5.5.3.1.3: message 150 with Q_DESK and packet 0 (8.6.10: Q_DESK
   --  1 when a desk is open, 7.5.1.102.2, as the cab status of the
   --  position knows it; e5/session-4)
   procedure Send_EoM (S : R.Session_T; Ctx : R.Context_T; T : T_TRAIN_T)
     with Global => (In_Out => (R.State, R.Queue, N_EoM),
                     Output => (EoM_Awaited, EoM_Since),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State))
   is
      W  : Writer_T;
      OK : Boolean;
   begin
      Start (W, Train_M150, T,
             (if EVC_Position.Active_Cab = EVC_Position.No_Cab then 0
              else 1),
             Ctx.Mode, OK);
      Finish_And_Send (W, S, OK);
      EoM_Awaited := True;
      EoM_Since := Ctx.Now_Ms;
      if OK then
         Bump (N_EoM);
      end if;
   end Send_EoM;

   pragma Warnings
     (GNATprove, On, """W"" is set by ""Finish_And_Send"" but not used*");

   procedure Produce (Ctx : EVC_Radio.Context_T) is
      T  : constant T_TRAIN_T := R.T_Train_At (Ctx.Now_Ms);
      Sv : constant R.Session_Ref_T := R.Supervising;
   begin
      if Step = Report_Due then
         if Up (SoM_S) then
            Send_Report (SoM_S, Ctx, T);
         end if;
         Step := Reported;
      end if;
      if TD_Due then
         TD_Due := False;
         if Sv /= R.No_Session and then Up (R.Session_T (Sv)) then
            Send_TD (R.Session_T (Sv), Ctx, T);
         end if;
      end if;
      if EoM_Due then
         EoM_Due := False;
         if Up (EoM_S) then
            Send_EoM (EoM_S, Ctx, T);
         end if;
      end if;
      Confirm := False;
      Delete := False;
   end Produce;

end EVC_Sessions.Mission;
