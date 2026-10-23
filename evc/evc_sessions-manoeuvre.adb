--  ETCS on-board (EVC)
--  The procedure Supervised Manoeuvre up to the RBC's answer

with ETCS_Bits;
with ETCS_Message;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P12;
with EVC_Bytes;
with EVC_DMI_Port;
with EVC_Ports;
with EVC_System_Version;
with Interfaces;     use Interfaces;
with ETCS_Variables; use ETCS_Variables;

package body EVC_Sessions.Manoeuvre
  with SPARK_Mode => On,
       Refined_State => (State => (Req, N_Sent, SCL, N_133))
is

   package R renames EVC_Radio;
   use type R.Session_T;

   --  A.3.1: the waiting time before a repetition and the repetitions
   Repeat_Ms   : constant := 15_000;
   Max_Repeats : constant := 3;

   type Request_T is record
      Pending : Boolean := False;   -- S050
      Due     : Boolean := False;   -- message 131 to send in the cycle
      Sent    : Boolean := False;
      Sent_Ms : R.Time_Ms_T := 0;
      Repeats : Natural range 0 .. Max_Repeats := 0;
      Session : R.Session_T := 1;
      Stamp   : T_TRAIN_T := 0;
      Answer  : Natural range 0 .. 1 := 0;
      Latest  : Boolean := False;
   end record;

   Req    : Request_T;
   N_Sent : Natural := 0;

   --  3.18.3.10: the safe consist length information for Supervised
   --  Manoeuvre (message 133). Period: from a request sent (Send_Request)
   --  until the mission ends (Had_Mission: it was on in the period),
   --  continues in NL or the request is refused; Seen, Avail, Last: the
   --  safe consist length of the last cycle, a change of which is sent;
   --  Awaited: sent and not yet acknowledged by message 7
   type Consist_Info_T is record
      Period      : Boolean := False;
      Had_Mission : Boolean := False;
      Seen        : Boolean := False;
      Avail       : Boolean := False;
      Last        : EVC_Train_Data.Consist_T := (others => 0);
      Due         : Boolean := False;
      Awaited     : Boolean := False;
      Was_Up      : Boolean := False;
      Session     : R.Session_T := 1;
      Stamp       : T_TRAIN_T := 0;
   end record;

   SCL   : Consist_Info_T;
   N_133 : Natural := 0;

   procedure Clear is
   begin
      Req := (others => <>);
      N_Sent := 0;
      SCL := (others => <>);
      N_133 := 0;
   end Clear;

   function Waiting return Boolean is (Req.Pending);
   function Answer return Natural is (Req.Answer);
   function Latest return Boolean is (Req.Latest);
   function Sent_Count return Natural is (N_Sent);
   function Consist_Sent return Natural is (N_133);
   function Consist_Awaited return Boolean is (SCL.Awaited);

   --  Whether the RBC of session S takes the radio messages of SM: not one
   --  of system version 1.x (6.5.1.6.6.2.2, 6.5.1.6.6.3.1, 6.5.1.6.6.8:
   --  messages 131, 133 and 7 do not apply) nor of 2.0 .. 2.2
   --  (6.5.2.3.7.1). Decision: the RBC's version is the session's, its
   --  message 32 (6.5.2.3.7 names the RBC's certified version; the
   --  operated X of 3.17.2.8 follows it but carries no Y); a session
   --  without a version yet is not refused here (it is not established)
   function SM_By_Radio (S : R.Session_T) return Boolean is
     (not R.Info (S).Version_Known
      or else EVC_System_Version.Major (R.Info (S).Version) >= 3
      or else (EVC_System_Version.Major (R.Info (S).Version) = 2
               and then Natural (R.Info (S).Version) mod 16 >= 3))
     with Global => R.State;

   --  S0: level 2, a valid position referred to an LRBG, the safe consist
   --  length available, standstill, and FS, AD, OS, LS, SR, PT or SB
   --  without an RBC transition order stored, or SM
   function Possible (Mode : Mode_T; Order_Stored : Boolean) return Boolean
   is (EVC_Levels.Valid and then EVC_Levels.Level = L2
       and then EVC_Position.Status = EVC_Position.Valid
       and then EVC_Position.LRBG.Valid
       and then EVC_Train_Data.Consist_Available
       and then EVC_Odometry.Standstill
       and then (Mode = M_SM
                 or else (Mode in M_FS | M_AD | M_OS | M_LS | M_SR | M_PT
                                | M_SB
                          and then not Order_Stored)))
     with Global => (EVC_Levels.State, EVC_Position.State,
                     EVC_Train_Data.State, EVC_Odometry.State);

   --  3.18.3.10: in SB in level 2 with the session established, and in
   --  the period of a request, a change of the safe consist length (its
   --  lengths, or its availability) makes message 133 due; 3.18.3.10.2:
   --  sent again when the connection lost before the acknowledgement is
   --  re-established within the session. Decisions: a change while the
   --  connection is lost is sent once it is re-established; with the
   --  session ended nothing is awaited any more
   --  @req 3.18.3.10, 3.18.3.10.2
   procedure Evaluate_Consist (Ctx : R.Context_T)
     with Global => (In_Out => SCL,
                     Input  => (R.State, EVC_Levels.State,
                                EVC_Train_Data.State, EVC_Mission.State))
   is
      use type EVC_Train_Data.Consist_T;
      use type R.Session_Ref_T;
      use type R.Session_State_T;
      Sv      : constant R.Session_Ref_T := R.Supervising;
      Is_Up   : constant Boolean :=
        Sv /= R.No_Session
        and then R.Info (R.Session_T (Sv)).State = R.Established;
      Lost    : constant Boolean :=
        Sv /= R.No_Session
        and then R.Info (R.Session_T (Sv)).State = R.Connection_Lost;
      Avail   : constant Boolean := EVC_Train_Data.Consist_Available;
      C       : constant EVC_Train_Data.Consist_T := EVC_Train_Data.Consist;
      Changed : constant Boolean :=
        SCL.Seen and then (Avail /= SCL.Avail or else C /= SCL.Last);
      In_SB   : constant Boolean :=
        Ctx.Mode = M_SB and then EVC_Levels.Valid
        and then EVC_Levels.Level = L2 and then Is_Up;
   begin
      if SCL.Period
        and then (Ctx.Mode = M_NL
                  or else (SCL.Had_Mission and then not EVC_Mission.Mission))
      then
         SCL.Period := False;
      elsif SCL.Period and then EVC_Mission.Mission then
         SCL.Had_Mission := True;
      end if;
      if Changed and then (SCL.Period or else In_SB)
        and then (Is_Up or else Lost)
      then
         SCL.Due := True;
         SCL.Session := R.Session_T (Sv);
      end if;
      if not Is_Up and then not Lost then
         SCL.Due := False;
         SCL.Awaited := False;
      elsif Is_Up and then not SCL.Was_Up and then SCL.Awaited then
         SCL.Due := True;
      end if;
      SCL.Was_Up := Is_Up;
      SCL.Seen := True;
      SCL.Avail := Avail;
      SCL.Last := C;
   end Evaluate_Consist;

   procedure Evaluate (Ctx          : EVC_Radio.Context_T;
                       Order_Stored : Boolean;
                       Status       : out Natural)
   is
   begin
      Evaluate_Consist (Ctx);
      Status := 0;
      if EVC_Driver_Requests.Shunting_Selected then
         Req.Latest := False;
      end if;
      if EVC_Driver_Requests.SM_Selected and then not Req.Pending
        and then Possible (Ctx.Mode, Order_Stored)
      then
         Req.Answer := 0;
         Req.Latest := True;
         --  6.5.1.6.6.2.2, 6.5.2.3.7.1: no message 131 to an RBC of 1.x
         --  or 2.0 .. 2.2; decision: the request fails as without a
         --  session
         if R.In_Communication
           and then SM_By_Radio (R.Session_T (R.Supervising))
         then
            Req.Pending := True;
            Req.Due := True;
            Req.Sent := False;
            Req.Repeats := 0;
            Req.Session := R.Session_T (R.Supervising);
         else
            Status := EVC_DMI_Port.SS_SM_Request_Failed;   -- decision 1
         end if;
      elsif Req.Pending and then Req.Sent and then not Req.Due
        and then Ctx.Now_Ms - Req.Sent_Ms >= Repeat_Ms
      then
         if Req.Repeats < Max_Repeats then
            Req.Repeats := Req.Repeats + 1;
            Req.Due := True;
         else
            Req.Pending := False;
            Status := EVC_DMI_Port.SS_SM_Request_Failed;
         end if;
      end if;
   end Evaluate;

   procedure Take_Answer (S       : EVC_Radio.Session_T;
                          Kind    : Message_Kind_T;
                          Matched : out Boolean;
                          Refused : out Boolean)
   is
   begin
      Matched := Req.Pending and then Req.Sent and then S = Req.Session
        and then Kind in Track_M4 | Track_M5
        and then EVC_Received.Last_Field (7) = Unsigned_64 (Req.Stamp);
      Refused := Matched and then Kind = Track_M5;
      if Refused then
         SCL.Period := False;
      end if;
      if Matched then
         Req.Pending := False;
         Req.Due := False;
         Req.Answer := (if Kind = Track_M4 then 1 else 0);
      end if;
   end Take_Answer;

   procedure Take_Consist_Ack (S : EVC_Radio.Session_T) is
   begin
      if SCL.Awaited and then S = SCL.Session
        and then EVC_Received.Last_Field (7) = Unsigned_64 (SCL.Stamp)
      then
         SCL.Awaited := False;
      end if;
   end Take_Consist_Ack;

   procedure Mode_Changed is
   begin
      Req.Pending := False;
      Req.Due := False;
   end Mode_Changed;

   subtype Writer_T is ETCS_Bits.Writer (128);

   function Consist_Packet return ETCS_Train_Packets.P10.Packet_T is
      C : constant EVC_Train_Data.Consist_T := EVC_Train_Data.Consist;
   begin
      if not EVC_Train_Data.Consist_Available then
         return (Q_SAFECONSISTLENGTH         => 0,
                 Has_L_CONSISTFRONTENGINENOM => False,
                 others                      => <>);
      end if;
      return (Q_SAFECONSISTLENGTH         => 1,
              Has_L_CONSISTFRONTENGINENOM => True,
              L_CONSISTFRONTENGINENOM     =>
                L_CONSISTFRONTENGINENOM_T (C.Front_Nom),
              L_CONSISTFRONTENGINEMIN     =>
                L_CONSISTFRONTENGINEMIN_T (C.Front_Min),
              L_CONSISTFRONTENGINEMAX     =>
                L_CONSISTFRONTENGINEMAX_T (C.Front_Max),
              L_CONSISTREARENGINENOM      =>
                L_CONSISTREARENGINENOM_T (C.Rear_Nom),
              L_CONSISTREARENGINEMIN      =>
                L_CONSISTREARENGINEMIN_T (C.Rear_Min),
              L_CONSISTREARENGINEMAX      =>
                L_CONSISTREARENGINEMAX_T (C.Rear_Max),
              others                      => <>);
   end Consist_Packet;

   --  Packet 12 (7.4.3.6), decision 2: the categories, the speed in 5 km/h
   --  steps, the traction systems of the bits of Voltages (bit k: M_VOLTAGE
   --  k, NID_CTRACTION 0), N_AXLE 0 (not in the installation data)
   procedure Encode_Default (W : in out Writer_T; OK : out Boolean)
     with Global => EVC_Train_Data.State
   is
      Cat : constant EVC_Train_Data.Categories_T :=
        EVC_Train_Data.Categories;
      Kmh : constant Natural :=
        (Natural (EVC_Train_Data.Data.Max_Speed) * 36 + 500) / 1000;
      P   : ETCS_Train_Packets.P12.Packet_T;
      N   : Natural range 0 .. 5 := 0;
   begin
      P.NC_CDTRAIN := Cat.Cant_Deficiency;
      P.NC_TRAIN := Cat.Other;
      P.V_MAXTRAIN := V_MAXTRAIN_T (Natural'Min (Kmh / 5, 120));
      P.M_LOADINGGAUGE := Cat.Loading_Gauge;
      P.M_AXLELOADCAT := Cat.Axle_Load;
      P.M_AIRTIGHT := Cat.Airtight;
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
      ETCS_Train_Packets.P12.Encode (P, W, OK);
   end Encode_Default;

   --  A045: message 131 (8.6.2.1) with the position report, packet 10 and,
   --  outside SM, packet 12; the time stamp of the request is the one
   --  EVC_Radio.Send gave it (3.16.3.3.2)
   procedure Send_Request (Ctx : R.Context_T)
     with Global => (In_Out => (Req, N_Sent, SCL, R.State, R.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Train_Data.State))
   is
      V  : ETCS_Message.Value_Array := (others => 0);
      W  : Writer_T;
      OK : Boolean;
   begin
      ETCS_Bits.Clear (W);
      V (3) := Unsigned_64 (R.T_Train_At (Ctx.Now_Ms));
      V (4) := Unsigned_64 (R.Engine_Id);
      ETCS_Message.Write_Fields (W, Train_M131, V, OK);
      if OK then
         --  A045: the front end from the safe consist length
         ETCS_Train_Packets.P0.Encode
           ((if EVC_Train_Data.Consist_Available
             then EVC_Position.Consist_Report
                    (Ctx.Mode, EVC_Levels.Level, EVC_Train_Data.Consist)
             else EVC_Position.Position_Report (Ctx.Mode, EVC_Levels.Level)),
            W, OK);
      end if;
      if OK then
         ETCS_Train_Packets.P10.Encode (Consist_Packet, W, OK);
      end if;
      if OK and then Ctx.Mode /= M_SM then
         Encode_Default (W, OK);
      end if;
      if OK then
         ETCS_Message.Finish (W, OK);
      end if;
      if OK then
         declare
            M : constant EVC_Bytes.Byte_Array := ETCS_Bits.Data (W);
         begin
            if EVC_Ports.Valid_RTM (M) and then R.Usable (Req.Session) then
               R.Send (Req.Session, M);
               Req.Stamp := R.Info (Req.Session).Last_Sent;
               if N_Sent < Natural'Last then
                  N_Sent := N_Sent + 1;
               end if;
            end if;
         end;
      end if;
      Req.Due := False;
      Req.Sent := True;
      Req.Sent_Ms := Ctx.Now_Ms;
      if not SCL.Period then
         SCL.Period := True;
         SCL.Had_Mission := False;
      end if;
   end Send_Request;

   --  3.18.3.10: message 133 (8.6.3.1) with the position report and
   --  packet 10, awaiting message 7
   procedure Send_Consist (Ctx : R.Context_T)
     with Global => (In_Out => (SCL, N_133, R.State, R.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Train_Data.State))
   is
      V  : ETCS_Message.Value_Array := (others => 0);
      W  : Writer_T;
      OK : Boolean;
   begin
      ETCS_Bits.Clear (W);
      V (3) := Unsigned_64 (R.T_Train_At (Ctx.Now_Ms));
      V (4) := Unsigned_64 (R.Engine_Id);
      ETCS_Message.Write_Fields (W, Train_M133, V, OK);
      if OK then
         ETCS_Train_Packets.P0.Encode
           (EVC_Position.Position_Report (Ctx.Mode, EVC_Levels.Level), W, OK);
      end if;
      if OK then
         ETCS_Train_Packets.P10.Encode (Consist_Packet, W, OK);
      end if;
      if OK then
         ETCS_Message.Finish (W, OK);
      end if;
      if OK then
         declare
            M : constant EVC_Bytes.Byte_Array := ETCS_Bits.Data (W);
         begin
            if EVC_Ports.Valid_RTM (M) and then R.Usable (SCL.Session)
              and then SM_By_Radio (SCL.Session)
            then
               R.Send (SCL.Session, M);
               SCL.Stamp := R.Info (SCL.Session).Last_Sent;
               SCL.Awaited := True;
               if N_133 < Natural'Last then
                  N_133 := N_133 + 1;
               end if;
            end if;
         end;
      end if;
      SCL.Due := False;
   end Send_Consist;

   procedure Send_Consist_To (S : EVC_Radio.Session_T;
                              Ctx : EVC_Radio.Context_T)
   is
   begin
      SCL.Session := S;
      Send_Consist (Ctx);
   end Send_Consist_To;

   procedure Produce (Ctx : EVC_Radio.Context_T) is
   begin
      if Req.Due and then Req.Pending then
         Send_Request (Ctx);
      end if;
      if SCL.Due and then R.Usable (SCL.Session) then
         Send_Consist (Ctx);
      end if;
   end Produce;

end EVC_Sessions.Manoeuvre;
