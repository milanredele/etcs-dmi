--  ETCS on-board (EVC)
--  Phase E5, the session and link half, phase 1 (see the
--  specification): the sessions of 3.5, the link of 3.16.3, the
--  indication of 3.5.7 and the level 2 parts of 5.4 and 5.5.

with ETCS_Bits;
with ETCS_Message;
with ETCS_Message_Catalogue; use ETCS_Message_Catalogue;
with ETCS_Track_Packets.P42;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P1;
with ETCS_Train_Packets.P2;
with ETCS_Train_Packets.P5;
with ETCS_Train_Packets.P11;
with ETCS_Variables;         use ETCS_Variables;
with EVC_DMI_Port;
with EVC_Supervision_Input;
with Interfaces;             use Interfaces;

package body EVC_Sessions
  with SPARK_Mode => On,
       Refined_State => (State => (Events, Messages, Held_Back, Held,
                                   Mode_Changes, Cycles, Links, Order,
                                   Pending, Acks, Ack_N, SoM, EoM, NV,
                                   Infos, Info_N, Rd, Wr, Buf))
is

   package R renames EVC_Radio;
   use type R.Session_State_T;
   use type R.Session_Ref_T;
   use type R.RBC_Id_T;
   use type EVC_Position.Status_T;
   use type EVC_Position.Report_Kind_T;

   subtype Session_T is R.Session_T;
   subtype Time_Ms_T is R.Time_Ms_T;

   ---------------------------------------------------------------------
   --  Fixed values (A.3.1) and the system version (3.17, 7.5.1.79)
   ---------------------------------------------------------------------

   --  the number of times to try to establish a safe radio connection
   Max_Attempts    : constant := 3;
   --  the repetition of radio messages (excluding the first sending)
   Max_Repeats     : constant := 3;
   --  the waiting time before a radio message repetition, for the
   --  system version message, for the acknowledgement of the session
   --  establishment
   Wait_Ms         : constant := 15_000;
   --  the maximum time to maintain a session in case of failed
   --  re-connection attempts
   Keep_Ms         : constant := 300_000;
   --  the additional delay time to disconnection on supervision of the
   --  safe radio connection
   Extra_Ms        : constant := 60_000;
   --  the "connection status" timer
   Status_Timer_Ms : constant := 45_000;

   --  The system version this on-board supports with an RBC: X = 3
   --  (version 3.0 of SUBSET-026 4.0.0). Decision (e5/session-1): the
   --  older versions X = 1, 2 of chapter 6 are phase E7; an RBC of
   --  another X is "no compatible version" (3.5.3.7 d)
   Supported_X     : constant := 3;
   Onboard_Version : constant := 48;   -- 011 0000, version 3.0

   --  7.5.1.96: NID_RBC "contact last known RBC" (3.5.3.13)
   Last_Known_RBC  : constant := 16_383;
   --  7.5.1.95: NID_RADIO "use the short number stored on-board"
   Short_Number    : constant NID_RADIO_T := NID_RADIO_T'Last;

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   --  3.5.7 Table 1 (its position is the code of MSG_STATUS)
   type Indication_T is (No_Connection, Up, Lost_Failed);

   --  What this half keeps of a session (the table is EVC_Radio's)
   type Link_T is record
      --  3.5.3.7 a: the request is part of the start of mission
      --  (repeated Max_Attempts times); For_SoM: A31 of 5.4.3.2
      Capped      : Boolean := False;
      For_SoM      : Boolean := False;
      Attempts     : Natural := 0;
      --  the requests of the cycle (Produce)
      Request_Due  : Boolean := False;
      Release_Due  : Boolean := False;
      --  the start of the current wait: the system version, the
      --  acknowledgement of 159, of 156
      Since        : Time_Ms_T := 0;
      Repeats      : Natural range 0 .. Max_Repeats := 0;
      Send_155     : Boolean := False;
      Send_159     : Boolean := False;
      Send_154     : Boolean := False;
      Send_156     : Boolean := False;
      Ack_Awaited  : Boolean := False;   -- 3.5.3.7.4: message 38
      --  3.5.4.1: the safe radio connection lost at
      Lost_Since   : Time_Ms_T := 0;
      Connected    : Boolean := False;
      --  3.5.7: the indication, the "connection status" timer, and the
      --  events of the cycle for Table 2 ([1], [5])
      Ind          : Indication_T := No_Connection;
      Timer_On     : Boolean := False;
      Timer_Since  : Time_Ms_T := 0;
      Final_Failed : Boolean := False;
      Released     : Boolean := False;
   end record;

   type Links_T is array (Session_T) of Link_T;

   --  A session management order not yet taken (3.5.2.6.1)
   type Order_T is record
      Present   : Boolean := False;
      Establish : Boolean := False;
      RBC       : R.RBC_Id_T := R.No_RBC;
      Radio     : NID_RADIO_T := 0;
   end record;

   --  A session to establish once a session is free (3.5.3.4.2,
   --  3.5.3.5.2.1, 3.5.3.7.4.1, 3.5.4.3.1)
   type Pending_T is record
      Active  : Boolean := False;
      Capped : Boolean := False;
      For_SoM : Boolean := False;
      RBC     : R.RBC_Id_T := R.No_RBC;
      Radio   : NID_RADIO_T := 0;
   end record;

   --  3.16.3.5: the acknowledgements owed (T_TRAIN of the message)
   Max_Acks : constant := 8;
   type Ack_T is record
      S : Session_T := 1;
      T : T_TRAIN_T := 0;
   end record;
   type Acks_T is array (1 .. Max_Acks) of Ack_T;

   --  5.4.3.2 with the RBC
   type SoM_T is record
      Report_Due     : Boolean := False;     -- D32: 157 to send
      Report_S       : Session_T := 1;
      Answer_Awaited : Boolean := False;     -- D33
      Confirmed      : Boolean := False;     -- 43 (A35)
      Accepted       : Boolean := False;     -- 41 (A23)
      Rejected       : Boolean := False;     -- 40 (A38)
      TD_Due         : Boolean := False;     -- E16: 129 to send
      TD_Sent        : Boolean := False;     -- the Train Data sent in
      TD_T           : T_TRAIN_T := 0;       -- the message of this T_TRAIN
      TD_Acked       : Boolean := False;     -- 8 (D15)
   end record;

   --  5.5.3.1.3, 5.5.4.1.1
   type EoM_T is record
      Due     : Boolean := False;
      Waiting : Boolean := False;
      S       : Session_T := 1;
      Since   : Time_Ms_T := 0;
      Repeats : Natural range 0 .. Max_Repeats := 0;
   end record;

   --  3.16.3.4
   type NV_T is record
      Expired     : Boolean := False;
      Since       : Time_Ms_T := 0;
      Trip        : Boolean := False;
      SB          : Boolean := False;
      SB_Released : Boolean := False;
      Reconnected : Boolean := False;
   end record;

   type Held_T is array (Condition_T) of Boolean;
   type Infos_T is array (1 .. Max_Infos) of Natural;

   Events       : Natural := 0;
   Messages     : Natural := 0;
   --  the messages waiting in the transition buffer (none in phase 1)
   Held_Back    : Natural := 0;
   Held         : Held_T := (others => False);
   Mode_Changes : Natural := 0;
   Cycles       : Natural := 0;
   Links        : Links_T := (others => (others => <>));
   Order        : Order_T;
   Pending      : Pending_T;
   Acks         : Acks_T := (others => (S => 1, T => 0));
   Ack_N        : Natural range 0 .. Max_Acks := 0;
   SoM          : SoM_T;
   EoM          : EoM_T;
   NV           : NV_T;
   Infos        : Infos_T := (others => 0);
   Info_N       : Natural range 0 .. Max_Infos := 0;
   --  the packets of a message read, the messages written (static: no
   --  kilobyte on the stack, doc/EVC-PLAN.md §2)
   Rd           : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
   Wr           : ETCS_Bits.Writer (ETCS_Message.Max_Bytes);
   Buf          : EVC_Bytes.Byte_Array (1 .. ETCS_Message.Max_Bytes) :=
     (others => 0);

   ---------------------------------------------------------------------
   --  Helpers
   ---------------------------------------------------------------------

   procedure Count (N : in out Natural) is
   begin
      if N < Natural'Last then
         N := N + 1;
      end if;
   end Count;

   function Elapsed (Since, Now : Time_Ms_T) return Time_Ms_T is
     (if Now >= Since then Now - Since else 0);

   --  T_TRAIN of the on-board time (10 ms, 7.5.1.152), modulo 2**32
   function Stamp (Now : Time_Ms_T) return T_TRAIN_T is
     (T_TRAIN_T ((Now / 10) and 16#FFFF_FFFF#));

   function To_T (V : Unsigned_64) return T_TRAIN_T is
     (T_TRAIN_T (V and 16#FFFF_FFFF#));

   --  3.16.3.3.3, 3.16.3.2.3: T is later than Last (modulo 2**32)
   function Newer (T, Last : T_TRAIN_T) return Boolean is
     (((Unsigned_64 (T) - Unsigned_64 (Last)) and 16#FFFF_FFFF#)
        in 1 .. 2**31 - 1);

   --  3.16.3.4.1: the age of the time stamp T at the on-board time Now
   function Age_Ms (T : T_TRAIN_T; Now : Time_Ms_T) return Time_Ms_T is
      D : constant Unsigned_64 :=
        (Unsigned_64 (Stamp (Now)) - Unsigned_64 (T)) and 16#FFFF_FFFF#;
   begin
      return (if D < 2**31 then D * 10 else 0);
   end Age_Ms;

   --  3.17: the X of M_VERSION (its three most significant bits)
   function Compatible (V : M_VERSION_T) return Boolean is
     (Natural (V) / 16 = Supported_X);

   procedure Put_Info (Code : Natural)
     with Global => (In_Out => (Infos, Info_N))
   is
   begin
      if Info_N < Max_Infos then
         Info_N := Info_N + 1;
         Infos (Info_N) := Code;
      end if;
   end Put_Info;

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Has_Released return Boolean is (Held_Back > 0)
     with Refined_Global => Held_Back;
   function Holds (C : Condition_T) return Boolean is (Held (C))
     with Refined_Global => Held;
   function Events_Taken return Natural is (Events)
     with Refined_Global => Events;
   function Messages_Taken return Natural is (Messages)
     with Refined_Global => Messages;
   function Mode_Changes_Taken return Natural is (Mode_Changes)
     with Refined_Global => Mode_Changes;
   function Cycles_Produced return Natural is (Cycles)
     with Refined_Global => Cycles;
   function Service_Brake return Boolean is
     (NV.Expired and then NV.SB and then not NV.SB_Released)
     with Refined_Global => NV;
   function Train_Data_Acknowledged return Boolean is (SoM.TD_Acked)
     with Refined_Global => SoM;
   function Info_Count return Natural is (Info_N)
     with Refined_Global => Info_N;
   function Info_Code (I : Positive) return Natural is (Infos (I))
     with Refined_Global => (Infos, Proof_In => Info_N);

   function Indication return Natural is
     (if R.Supervising /= R.No_Session
      then Indication_T'Pos (Links (Session_T (R.Supervising)).Ind)
      elsif Links (1).Ind /= No_Connection
      then Indication_T'Pos (Links (1).Ind)
      else Indication_T'Pos (Links (2).Ind))
     with Refined_Global => (Links, R.State);

   function Session_Code return Natural is
     (if (for some S in Session_T => R.Established (S))
      then (if R.Supervising /= R.No_Session
              and then R.Info (Session_T (R.Supervising)).Version_Known
              and then R.Info (Session_T (R.Supervising)).Version > 34
              and then not R.Handover
            then 3 else 2)
      elsif (for some S in Session_T => R.Being_Established (S)) then 1
      else 0);

   function Awaiting_RBC return Boolean is
     (SoM.Answer_Awaited
      or else (for some S in Session_T =>
                 Links (S).For_SoM and then R.Being_Established (S))
      or else (SoM.TD_Sent and then not SoM.TD_Acked
               and then R.In_Communication))
     with Refined_Global => (SoM, Links, R.State);

   ---------------------------------------------------------------------
   --  The steps of a session (3.5)
   ---------------------------------------------------------------------

   --  3.5.3.7 a: a session is set up with RBC on the number Radio in
   --  the first session the on-board handles that is free; none free:
   --  it waits (Pending). The "connection status" timer starts with the
   --  first request, except in the start of mission (3.5.7.3 a)
   procedure Open (RBC     : R.RBC_Id_T;
                   Radio   : NID_RADIO_T;
                   Capped : Boolean;
                   For_SoM : Boolean;
                   Now     : Time_Ms_T)
     with Global => (In_Out => (Links, Pending, R.State))
   is
   begin
      for S in Session_T loop
         pragma Loop_Invariant (True);
         if R.Usable (S) and then R.Info (S).State = R.Idle then
            R.Reset_Session (S);
            R.Set_Peer (S, RBC, Radio);
            R.Set_State (S, R.Connecting);
            Links (S).Capped := Capped;
            Links (S).For_SoM := For_SoM;
            Links (S).Attempts := 0;
            Links (S).Request_Due := True;
            Links (S).Repeats := 0;
            Links (S).Send_155 := False;
            Links (S).Send_159 := False;
            Links (S).Send_154 := False;
            Links (S).Send_156 := False;
            Links (S).Ack_Awaited := False;
            Links (S).Final_Failed := False;
            if not For_SoM then
               Links (S).Timer_On := True;
               Links (S).Timer_Since := Now;
            end if;
            Pending := (others => <>);
            return;
         end if;
      end loop;
      Pending := (Active  => True,
                  Capped => Capped,
                  For_SoM => For_SoM,
                  RBC     => RBC,
                  Radio   => Radio);
   end Open;

   --  The session S is over: back to Idle, its safe radio connection
   --  released (3.5.5.2 c, 3.5.5.3.2, 3.5.3.8, 3.5.4.2.1)
   procedure Close (S : Session_T)
     with Global => (In_Out => (Links, EoM, R.State))
   is
   begin
      Links (S).Release_Due := True;
      Links (S).Request_Due := False;
      Links (S).Send_155 := False;
      Links (S).Send_159 := False;
      Links (S).Send_154 := False;
      Links (S).Send_156 := False;
      Links (S).Ack_Awaited := False;
      Links (S).Timer_On := False;   -- 3.5.7.4
      if EoM.S = S then
         EoM.Waiting := False;
         EoM.Due := False;
      end if;
      if R.Supervising = R.Session_Ref_T (S) then
         R.Set_Roles (R.No_Session, R.No_Session);
      end if;
      R.Reset_Session (S);
   end Close;

   --  3.5.5.2 a: terminate the session S (established: message 156, its
   --  acknowledgement awaited; being established: aborted, 3.5.3.8)
   procedure Terminate_Session (S : Session_T; Now : Time_Ms_T)
     with Global => (In_Out => (Links, EoM, R.State))
   is
   begin
      case R.Info (S).State is
         when R.Established | R.Connection_Lost =>
            R.Set_State (S, R.Terminating);
            Links (S).Send_156 := True;
            Links (S).Since := Now;
            Links (S).Repeats := 0;
            --  3.5.5.3: nothing else is sent after 156
            Links (S).Send_159 := False;
            Links (S).Send_154 := False;
            Links (S).Ack_Awaited := False;
            Links (S).Request_Due := False;
            Links (S).Timer_On := False;
         when R.Connecting | R.Initiating =>
            Close (S);
         when R.Idle | R.Terminating =>
            null;
      end case;
   end Terminate_Session;

   --  3.5.3.4, 3.5.3.4.1, 3.5.3.4.2, 3.5.3.5.2: establish a session with
   --  RBC: nothing when one is established or being established with it
   --  (not terminating); the sessions with other RBCs terminated; a
   --  session with it that terminates: the new one once it is over
   procedure Establish (RBC     : R.RBC_Id_T;
                        Radio   : NID_RADIO_T;
                        Capped : Boolean;
                        For_SoM : Boolean;
                        Now     : Time_Ms_T)
     with Global => (In_Out => (Links, Pending, EoM, R.State))
   is
      Waiting_For_It : Boolean := False;
   begin
      for S in Session_T loop
         pragma Loop_Invariant (True);
         if R.Info (S).State /= R.Idle and then R.Info (S).RBC = RBC then
            if R.Info (S).State /= R.Terminating then
               Links (S).For_SoM := Links (S).For_SoM or else For_SoM;
               return;
            end if;
            Waiting_For_It := True;
         end if;
      end loop;
      for S in Session_T loop
         pragma Loop_Invariant (True);
         if R.Info (S).State /= R.Idle and then R.Info (S).RBC /= RBC then
            Terminate_Session (S, Now);
         end if;
      end loop;
      if Waiting_For_It then
         Pending := (Active  => True,
                     Capped => Capped,
                     For_SoM => For_SoM,
                     RBC     => RBC,
                     Radio   => Radio);
      else
         Open (RBC, Radio, Capped, For_SoM, Now);
      end if;
   end Establish;

   ---------------------------------------------------------------------
   --  Clear, the RTM port
   ---------------------------------------------------------------------

   procedure Clear is
   begin
      Events := 0;
      Messages := 0;
      Held_Back := 0;
      Held := (others => False);
      Mode_Changes := 0;
      Cycles := 0;
      Links := (others => (others => <>));
      Order := (others => <>);
      Pending := (others => <>);
      Acks := (others => (S => 1, T => 0));
      Ack_N := 0;
      SoM := (others => <>);
      EoM := (others => <>);
      NV := (others => <>);
      Infos := (others => 0);
      Info_N := 0;
      ETCS_Bits.Clear (Wr);
      Buf := (others => 0);
   end Clear;

   --  3.5.3.7, 3.5.4, 3.5.7: the events of the safe radio connection
   procedure Take_Event (S      : EVC_Radio.Session_T;
                         Event  : EVC_Ports.RTM_Event_T;
                         Now_Ms : EVC_Radio.Time_Ms_T)
   is
      L : Link_T renames Links (S);
   begin
      Count (Events);
      if not R.Usable (S) then
         return;
      end if;
      case Event is
         when EVC_Ports.Connection_Set_Up =>
            case R.Info (S).State is
               when R.Connecting =>
                  --  3.5.3.7 b
                  L.Connected := True;
                  L.Timer_On := False;
                  R.Set_State (S, R.Initiating);
                  L.Send_155 := True;
                  L.Since := Now_Ms;
               when R.Connection_Lost =>
                  --  3.5.4.2: the session goes on
                  L.Connected := True;
                  L.Timer_On := False;
                  R.Set_State (S, R.Established);
               when others =>
                  null;
            end case;
         when EVC_Ports.Connection_Lost =>
            L.Connected := False;
            case R.Info (S).State is
               when R.Established =>
                  --  3.5.4.1, 3.5.4.2, 3.5.7.3 b
                  R.Set_State (S, R.Connection_Lost);
                  L.Lost_Since := Now_Ms;
                  L.Request_Due := True;
                  L.Capped := False;
                  L.Timer_On := True;
                  L.Timer_Since := Now_Ms;
               when R.Initiating =>
                  --  still being established (3.5.3.8): step a) again
                  R.Set_State (S, R.Connecting);
                  L.Request_Due := True;
               when R.Terminating =>
                  Close (S);
               when others =>
                  null;
            end case;
         when EVC_Ports.Set_Up_Failed =>
            case R.Info (S).State is
               when R.Connecting =>
                  --  3.5.3.7 a: repeated at once; in the start of
                  --  mission a defined number of times (A32, Table 2 [1])
                  if L.Capped and then L.Attempts >= Max_Attempts then
                     L.Final_Failed := True;
                     Close (S);
                  else
                     L.Request_Due := True;
                  end if;
               when R.Connection_Lost =>
                  L.Request_Due := True;   -- 3.5.4.3
               when others =>
                  null;
            end case;
         when EVC_Ports.Connection_Released =>
            L.Connected := False;
            L.Released := True;
         when EVC_Ports.Registered | EVC_Ports.Registration_Failed =>
            null;   -- 3.5.6: phase 2 (the mobile is taken as registered)
      end case;
   end Take_Event;

   --  3.5.3.7 d, 3.5.4.7: the system version of the RBC (message 32)
   procedure Take_Version (S : Session_T; V : M_VERSION_T; Now : Time_Ms_T)
     with Global => (In_Out => (Links, SoM, Infos, Info_N, R.State)),
          Pre => R.Usable (S)
   is
      Info : constant R.Session_Info_T := R.Info (S);
   begin
      case Info.State is
         when R.Initiating =>
            R.Set_Version (S, V);
            R.Set_State (S, R.Established);
            if Compatible (V) then
               Links (S).Send_159 := True;
               Links (S).Ack_Awaited := True;
               Links (S).Since := Now;
               Links (S).Repeats := 0;
               R.Set_Roles (R.Session_Ref_T (S), R.No_Session);
               --  5.4.3.3 D31: the RBC contact information valid
               R.Set_Contact ((Known => True, Valid => True,
                               RBC   => Info.RBC, Radio => Info.Radio));
               if Links (S).For_SoM then
                  SoM.Report_Due := True;   -- D32
                  SoM.Report_S := S;
               end if;
            else
               --  3.5.3.7 d) second bullet: 154, the driver informed, the
               --  session terminated (A32 in the start of mission)
               Links (S).Send_154 := True;
               Put_Info (EVC_DMI_Port.SS_Trackside_Not_Compatible);
            end if;
         when R.Established | R.Connection_Lost =>
            if Compatible (V) then
               Links (S).Send_159 := True;   -- 3.5.4.7
            end if;
         when others =>
            null;
      end case;
   end Take_Version;

   --  3.5.2.6.1: the packets 42 of the last message (a message 24)
   procedure Take_Packets_42
     with Global => (In_Out => (Order, Rd), Input => EVC_Received.Store)
   is
      P  : ETCS_Track_Packets.P42.Packet_T;
      OK : Boolean;
   begin
      for I in 1 .. EVC_Received.Message_Packets loop
         pragma Loop_Invariant (I <= EVC_Received.Message_Packets);
         if EVC_Received.Message_Packet_NID (I) = 42 then
            EVC_Received.Open_Message_Packet (I, Rd);
            ETCS_Track_Packets.P42.Decode (Rd, P, OK);
            if OK and then ETCS_Track_Packets.P42.Valid (P) then
               Order := (Present   => True,
                         Establish => P.Q_RBC = 1,
                         RBC       => (NID_C => P.NID_C,
                                       NID_RBC => P.NID_RBC),
                         Radio     => P.NID_RADIO);
            end if;
         end if;
      end loop;
   end Take_Packets_42;

   procedure Take_Message (S       : EVC_Radio.Session_T;
                           Now_Ms  : EVC_Radio.Time_Ms_T;
                           Verdict : out Verdict_T)
   is
      Kind : constant Message_Kind_T := EVC_Received.Message_Kind;
      T    : constant T_TRAIN_T :=
        To_T (EVC_Received.Message_Value (ETCS_Variables.T_TRAIN));
      Info : constant R.Session_Info_T := R.Info (S);
   begin
      Count (Messages);
      Verdict := Pass;
      if not R.Usable (S) then
         Verdict := Ignore;   -- a session the on-board does not handle
         return;
      end if;
      --  3.16.3.3.3: not newer than the preceding message: inconsistent
      if Info.Received and then not Newer (T, Info.Last_Received) then
         Verdict := Ignore;
         return;
      end if;
      --  3.5.5.6: after 156 only its acknowledgement
      if Info.State = R.Terminating and then Kind /= Track_M39 then
         Verdict := Ignore;
         return;
      end if;
      R.Note_Received (S, T, Now_Ms);
      if R.Supervising = R.Session_Ref_T (S) then
         NV := (others => <>);   -- 3.16.3.4, 3.14.1.7: a new message
      end if;
      --  3.16.3.5.1, 3.16.3.5.3
      if EVC_Received.Message_Value (ETCS_Variables.M_ACK) = 1
        and then Ack_N < Max_Acks
      then
         Ack_N := Ack_N + 1;
         Acks (Ack_N) := (S => S, T => T);
      end if;
      case Kind is
         when Track_M32 =>
            Take_Version
              (S,
               M_VERSION_T
                 (EVC_Received.Message_Value (ETCS_Variables.M_VERSION)
                  and 127),
               Now_Ms);
            Verdict := Ignore;
         when Track_M38 =>
            Links (S).Ack_Awaited := False;   -- 3.5.3.7 e
            Verdict := Ignore;
         when Track_M39 =>
            if Info.State = R.Terminating then
               Close (S);                     -- 3.5.5.2 c
            end if;
            Verdict := Ignore;
         when Track_M40 =>
            SoM.Rejected := True;             -- 5.4.3.2 A38
            Verdict := Ignore;
         when Track_M41 =>
            SoM.Accepted := True;             -- A23
            Verdict := Ignore;
         when Track_M43 =>
            SoM.Confirmed := True;            -- A35
            Verdict := Ignore;
         when Track_M8 =>
            --  D15, S11: the acknowledgement refers to the T_TRAIN of
            --  the message with the Train Data (field 7)
            if SoM.TD_Sent
              and then To_T (EVC_Received.Message_Field (7)) = SoM.TD_T
            then
               SoM.TD_Acked := True;
            end if;
         when Track_M24 =>
            Take_Packets_42;
         when others =>
            null;
      end case;
   end Take_Message;

   procedure Take_Order (Establish : Boolean;
                         RBC       : EVC_Radio.RBC_Id_T;
                         Radio     : ETCS_Variables.NID_RADIO_T)
   is
   begin
      Order := (Present   => True,
                Establish => Establish,
                RBC       => RBC,
                Radio     => Radio);
   end Take_Order;

   procedure Take_Released (S    : out EVC_Radio.Session_T;
                            Data : out EVC_Bytes.Byte_Array;
                            Last : out Natural)
   is
   begin
      --  phase 1 holds nothing (4.8.5 is phase 2): an empty message
      --  (NID_MESSAGE 0, L_MESSAGE 3), which the codec rejects
      S := 1;
      Data := (others => 0);
      Data (Data'First + 2) := 192;
      Last := Data'First + 2;
      if Held_Back > 0 then
         Held_Back := Held_Back - 1;
      end if;
   end Take_Released;

   ---------------------------------------------------------------------
   --  Evaluate
   ---------------------------------------------------------------------

   --  3.5.2.6.1, 3.5.3.13, 3.5.5.1 a), 3.5.3.8 c): the order of the cycle
   procedure Apply_Order (Now : Time_Ms_T)
     with Global => (In_Out => (Order, Links, Pending, EoM, R.State))
   is
      O : constant Order_T := Order;
      RBC   : R.RBC_Id_T := O.RBC;
      Radio : NID_RADIO_T := O.Radio;
   begin
      Order := (others => <>);
      if not O.Present then
         return;
      end if;
      if RBC.NID_RBC = Last_Known_RBC then
         if not R.Contact.Known then
            return;                    -- 3.5.3.13.1
         end if;
         RBC := R.Contact.RBC;
         Radio := R.Contact.Radio;
      end if;
      if O.Establish then
         Establish (RBC, Radio, False, False, Now);
      else
         for S in Session_T loop
            pragma Loop_Invariant (True);
            if R.Info (S).State /= R.Idle and then R.Info (S).RBC = RBC then
               Terminate_Session (S, Now);
            end if;
         end loop;
         if Pending.Active and then Pending.RBC = RBC then
            Pending := (others => <>);
         end if;
      end if;
   end Apply_Order;

   --  5.4.3.2 S3 (DMI 11.3.5, MSG_DRIVER_DATA kind 5): the RBC contact
   --  the driver entered, the last stored one, or the short number
   --  (3.5.3.11: the stored ID and number not used; RBC unknown); valid
   --  (5.4.3.3 "Following S3"), and A31 / 3.5.3.4 h
   procedure Take_RBC_Data (For_SoM : Boolean; Now : Time_Ms_T)
     with Global => (In_Out => (Links, Pending, EoM, R.State),
                     Input  => EVC_Driver_Requests.State)
   is
      B     : constant EVC_Driver_Requests.Bytes_23_T :=
        EVC_Driver_Requests.RBC_Data;
      Id    : constant Unsigned_32 :=
        Unsigned_32 (B (2)) or Shift_Left (Unsigned_32 (B (3)), 8)
        or Shift_Left (Unsigned_32 (B (4)), 16)
        or Shift_Left (Unsigned_32 (B (5)), 24);
      Len   : constant Natural := Natural'Min (Natural (B (6)), 16);
      RBC   : R.RBC_Id_T;
      Radio : NID_RADIO_T := 0;
   begin
      case B (1) is
         when 0 =>
            RBC := (NID_C   => NID_C_T ((Id / 2**14) mod 2**10),
                    NID_RBC => NID_RBC_T (Id mod 2**14));
            --  NID_RADIO: 16 digits, left adjusted, F for no digit
            for I in 1 .. 16 loop
               pragma Loop_Invariant (True);
               Radio := Radio * 16
                 + (if I <= Len and then B (6 + I) in 48 .. 57
                    then NID_RADIO_T (B (6 + I) - 48) else 15);
            end loop;
         when 1 =>
            if not R.Contact.Known then
               return;
            end if;
            RBC := R.Contact.RBC;
            Radio := R.Contact.Radio;
         when 2 =>
            RBC := R.No_RBC;
            Radio := Short_Number;
         when others =>
            return;
      end case;
      R.Set_Contact ((Known => True, Valid => True, RBC => RBC,
                      Radio => Radio));
      Establish (RBC, Radio, For_SoM, For_SoM, Now);
   end Take_RBC_Data;

   --  5.4.3.3: the RBC contact information from valid to invalid
   procedure Invalidate_Contact
     with Global => (In_Out => R.State)
   is
      C : R.RBC_Contact_T := R.Contact;
   begin
      if C.Known and then C.Valid then
         C.Valid := False;
         R.Set_Contact (C);
      end if;
   end Invalidate_Contact;

   --  5.4.3.2 D34, D35: a valid train position referred to an unlinked
   --  balise group is kept, else the position is deleted (A24, A39)
   procedure Delete_Unless_Unlinked
     with Global => (In_Out => EVC_Position.State,
                     Proof_In => EVC_Odometry.State)
   is
   begin
      if not (EVC_Position.Status = EVC_Position.Valid
              and then EVC_Position.Unlinked_ORBG (1).Valid)
      then
         EVC_Position.Delete_Position;
      end if;
   end Delete_Unless_Unlinked;

   --  5.4.3.2 with the RBC, in SB with the start of mission engaged (and
   --  the driver's RBC contact outside it, 3.5.3.4 h)
   procedure SoM_Steps (Ctx : R.Context_T)
     with Global => (In_Out => (Links, Pending, EoM, SoM, Infos, Info_N,
                                R.State, EVC_Levels.State,
                                EVC_Position.State),
                     Input  => (EVC_Mission.State,
                                EVC_Driver_Requests.State,
                                EVC_Odometry.State))
   is
      Engaged : constant Boolean :=
        Ctx.Mode = M_SB and then EVC_Mission.SoM_Engaged;
      L2      : constant Boolean :=
        EVC_Levels.Valid and then EVC_Levels.Level = L2;
      Pos_OK  : constant Boolean :=
        EVC_Position.Status = EVC_Position.Valid
        and then EVC_Position.LRBG.Valid;
   begin
      --  5.4.3.2.2, 3.5.3.8 a): the desk closed during the start of
      --  mission terminates the session
      if EVC_Mission.Desk_Closed_In_SoM then
         for S in Session_T loop
            pragma Loop_Invariant (True);
            Terminate_Session (S, Ctx.Now_Ms);
         end loop;
         Pending := (others => <>);
         SoM := (others => <>);
      end if;
      if Engaged then
         --  D2 after S1 (5.4.3.3 "Following D2"); D3, D7, A31 with the
         --  stored RBC contact
         if EVC_Driver_Requests.Entered (EVC_Driver_Requests.Driver_ID) then
            if not Pos_OK then
               EVC_Levels.Invalidate;
               Invalidate_Contact;
            elsif not EVC_Levels.Valid then
               Invalidate_Contact;
            elsif EVC_Levels.Level = L2 and then R.Contact.Known then
               Establish (R.Contact.RBC, R.Contact.Radio, True, True,
                          Ctx.Now_Ms);
            end if;
         end if;
         --  "Following S10 or S20: driver chooses to re-enter the level"
         if EVC_Driver_Requests.Level_Selected then
            Invalidate_Contact;
         end if;
      end if;
      --  S3 (A31), 3.5.3.4 h)
      if EVC_Driver_Requests.Entered (EVC_Driver_Requests.RBC_Data)
        and then (L2 or else (Engaged
                              and then EVC_Driver_Requests.Level_Selected
                              and then EVC_Driver_Requests.
                                         Selected_Level_Code = 5))
      then
         Take_RBC_Data (Engaged, Ctx.Now_Ms);
      end if;
      --  the answers of the RBC to the SoM position report
      if SoM.Confirmed then
         EVC_Position.Revalidate;              -- A35
         SoM.Answer_Awaited := False;
      end if;
      if SoM.Accepted then
         Delete_Unless_Unlinked;               -- D34, A24
         SoM.Answer_Awaited := False;
      end if;
      if SoM.Rejected then
         Delete_Unless_Unlinked;               -- D35, A39
         SoM.Answer_Awaited := False;
         if R.Supervising /= R.No_Session then -- A40
            Terminate_Session (Session_T (R.Supervising), Ctx.Now_Ms);
         end if;
         Put_Info (EVC_DMI_Port.SS_Train_Rejected);
      end if;
      SoM.Confirmed := False;
      SoM.Accepted := False;
      SoM.Rejected := False;
      --  E16 (3.18.3.4): the Train Data validated go to the RBC
      if EVC_Mission.Train_Data_Validated and then L2
        and then R.In_Communication
      then
         SoM.TD_Due := True;
         SoM.TD_Acked := False;
      end if;
      --  S20 / 5.4.5.3 h): 'Start' in level 2 with the session open: S21
      R.Set_SoM_Start
        (EVC_Driver_Requests.Start_Selected and then Engaged and then L2
         and then R.In_Communication);
   end SoM_Steps;

   --  3.5.3.7.3, 3.5.3.7.4, 3.5.4.2.1, 3.5.5.3.1, 3.5.5.3.2: the waits of
   --  the session S
   procedure Supervise_Session (S : Session_T; Now : Time_Ms_T)
     with Global => (In_Out => (Links, Pending, EoM, R.State))
   is
      Info : constant R.Session_Info_T := R.Info (S);
      L    : Link_T renames Links (S);
   begin
      case Info.State is
         when R.Initiating =>
            if Elapsed (L.Since, Now) > Wait_Ms then
               --  3.5.3.7.3: released, step a) again
               L.Release_Due := True;
               L.Connected := False;
               L.Request_Due := True;
               L.Attempts := 0;
               R.Set_State (S, R.Connecting);
            end if;
         when R.Established =>
            if L.Ack_Awaited and then Elapsed (L.Since, Now) > Wait_Ms then
               if L.Repeats = 0 then
                  L.Send_159 := True;            -- 3.5.3.7.4
                  L.Repeats := 1;
                  L.Since := Now;
               else
                  --  3.5.3.7.4.1: terminated, and a new one
                  Terminate_Session (S, Now);
                  Pending := (Active  => True,
                              Capped => False,
                              For_SoM => False,
                              RBC     => Info.RBC,
                              Radio   => Info.Radio);
               end if;
            end if;
         when R.Connection_Lost =>
            if Elapsed (L.Lost_Since, Now) > Keep_Ms then
               --  3.5.4.2.1 terminated; 3.5.3.4 f), 3.5.4.3.1 again
               Close (S);
               Open (Info.RBC, Info.Radio, False, False, Now);
            end if;
         when R.Terminating =>
            if Elapsed (L.Since, Now) > Wait_Ms then
               if L.Repeats < Max_Repeats then
                  L.Send_156 := True;            -- 3.5.5.3.1
                  L.Repeats := L.Repeats + 1;
                  L.Since := Now;
               else
                  Close (S);                     -- 3.5.5.3.2
               end if;
            end if;
         when R.Idle | R.Connecting =>
            null;
      end case;
   end Supervise_Session;

   --  3.5.7.5, Tables 1 and 2: the indication of the session S;
   --  SoM: a start of mission is going on
   procedure Indicate (S : Session_T; SoM_On : Boolean; Now : Time_Ms_T)
     with Global => (In_Out => Links, Input => R.State)
   is
      L       : Link_T renames Links (S);
      St      : constant R.Session_State_T := R.Info (S).State;
      --  requests to set up a safe radio connection are going on
      Asking  : constant Boolean := St in R.Connecting | R.Connection_Lost;
      Expired : constant Boolean :=
        L.Timer_On and then Elapsed (L.Timer_Since, Now) > Status_Timer_Ms;
   begin
      if Expired then
         L.Timer_On := False;
      end if;
      case L.Ind is
         when No_Connection =>
            if L.Connected and then St /= R.Idle then
               L.Ind := Up;                               -- [4]
            elsif (SoM_On and then L.Final_Failed) or else Expired then
               L.Ind := Lost_Failed;                      -- [1], [2]
            end if;
         when Lost_Failed =>
            if L.Connected and then St /= R.Idle then
               L.Ind := Up;                               -- [4]
            elsif not SoM_On and then not Asking then
               L.Ind := No_Connection;                    -- [3]
            end if;
         when Up =>
            if L.Released or else (not L.Connected and then not Asking)
            then
               L.Ind := No_Connection;                    -- [5], [6]
            elsif Expired then
               L.Ind := Lost_Failed;                      -- [2]
            end if;
      end case;
      L.Final_Failed := False;
      L.Released := False;
   end Indicate;

   --  5.5.4.1.1: the end of mission reported with the desk open, no
   --  order to terminate within the waiting time: repeated, then the
   --  session terminated
   procedure EoM_Wait (Now : Time_Ms_T)
     with Global => (In_Out => (EoM, Links, R.State))
   is
   begin
      if not EoM.Waiting then
         return;
      end if;
      if not R.Established (EoM.S) then
         EoM.Waiting := False;
      elsif Elapsed (EoM.Since, Now) > Wait_Ms then
         if EoM.Repeats < Max_Repeats then
            EoM.Repeats := EoM.Repeats + 1;
            EoM.Due := True;
            EoM.Since := Now;
         else
            EoM.Waiting := False;
            Terminate_Session (EoM.S, Now);
         end if;
      end if;
   end EoM_Wait;

   --  3.16.3.4: the supervision of the safe radio connection with the
   --  supervising RBC in level 2, the reaction M_NVCONTACT
   procedure Supervise_Contact (Now : Time_Ms_T)
     with Global => (In_Out => (NV, Held, Links, Infos, Info_N, R.State),
                     Input  => (EVC_Levels.State,
                                EVC_National_Values.State,
                                EVC_Odometry.State))
   is
      Sup : constant R.Session_Ref_T := R.Supervising;
   begin
      Held := (others => False);
      if Sup = R.No_Session
        or else not R.Established (Session_T (Sup))
        or else not R.Info (Session_T (Sup)).Received
        or else EVC_Levels.Level /= L2
      then
         NV := (others => <>);
         return;
      end if;
      declare
         S    : constant Session_T := Session_T (Sup);
         Set  : constant EVC_National_Values.Set_T :=
           EVC_National_Values.Current;
         Late : constant Boolean :=
           Age_Ms (R.Info (S).Last_Received, Now) > Set.T_NVCONTACT;
      begin
         if not Late then
            NV := (others => <>);
            return;
         end if;
         if not NV.Expired then
            NV.Expired := True;
            NV.Since := Now;
            NV.Trip := Set.M_NVCONTACT = 0;
            NV.SB := Set.M_NVCONTACT = 1;
            --  3.16.3.4.4
            if NV.Trip then
               Put_Info (EVC_DMI_Port.SS_Communication_Error_Trip);
            elsif NV.SB then
               Put_Info (EVC_DMI_Port.SS_Communication_Error_Brake);
            end if;
         end if;
         --  3.14.1.7: the service brake released at standstill
         if NV.SB and then EVC_Odometry.Standstill then
            NV.SB_Released := True;
         end if;
         --  3.16.3.4.3: released and set up again, the session kept
         if not NV.Reconnected and then Elapsed (NV.Since, Now) > Extra_Ms
         then
            NV.Reconnected := True;
            Links (S).Release_Due := True;
            Links (S).Connected := False;
            Links (S).Request_Due := True;
            Links (S).Lost_Since := Now;
            Links (S).Timer_On := True;
            Links (S).Timer_Since := Now;
            if R.Info (S).State = R.Established then
               R.Set_State (S, R.Connection_Lost);
            end if;
         end if;
         Held (C_41) := NV.Trip;
      end;
   end Supervise_Contact;

   procedure Evaluate (Ctx : EVC_Radio.Context_T) is
      SoM_On : constant Boolean :=
        Ctx.Mode = M_SB and then EVC_Mission.SoM_Engaged;
   begin
      Info_N := 0;
      Apply_Order (Ctx.Now_Ms);
      SoM_Steps (Ctx);
      for S in Session_T loop
         pragma Loop_Invariant (True);
         Supervise_Session (S, Ctx.Now_Ms);
      end loop;
      if Pending.Active then
         Open (Pending.RBC, Pending.Radio, Pending.Capped, Pending.For_SoM,
               Ctx.Now_Ms);
      end if;
      EoM_Wait (Ctx.Now_Ms);
      Supervise_Contact (Ctx.Now_Ms);
      for S in Session_T loop
         pragma Loop_Invariant (True);
         Indicate (S, SoM_On, Ctx.Now_Ms);
      end loop;
      if not SoM_On then
         SoM.Answer_Awaited := False;
      end if;
   end Evaluate;

   --  5.5.2: entering SB or SH from these modes is an end of mission
   --  (from PT: decision, as when a mission was going on, 5.5.2.1.3)
   procedure Mode_Changed (From, To : Mode_T) is
   begin
      Count (Mode_Changes);
      if ((To = M_SB
           and then From in M_FS | M_AD | M_LS | M_OS | M_SM | M_UN | M_NL
                          | M_SR | M_PT | M_RV | M_SN)
          or else (To = M_SH
                   and then From in M_FS | M_AD | M_LS | M_OS | M_SR | M_SM
                                  | M_SN | M_UN | M_PT))
        and then R.In_Communication   -- 5.5.4.1.2
      then
         EoM := (Due     => True,
                 Waiting => False,
                 S       => Session_T (R.Supervising),
                 Since   => 0,
                 Repeats => 0);
      end if;
      if To /= M_SB then
         SoM.Report_Due := False;      -- 5.4.3.2.1
         SoM.Answer_Awaited := False;
      end if;
   end Mode_Changed;

   ---------------------------------------------------------------------
   --  Produce: the messages (8.6)
   ---------------------------------------------------------------------

   --  NID_OPERATIONAL (7.5.1.88): up to 8 digits left adjusted, F for no
   --  digit
   function TRN_Code return NID_OPERATIONAL_T
     with Global => EVC_Mission.State
   is
      T : constant EVC_Driver_Requests.Text_T := EVC_Mission.TRN;
      V : Unsigned_64 := 0;
   begin
      for I in 1 .. 8 loop
         pragma Loop_Invariant (V < 16**(I - 1));
         V := V * 16
           + (if I <= T.Length and then T.Chars (I) in 48 .. 57
              then Unsigned_64 (T.Chars (I) - 48) else 15);
      end loop;
      return NID_OPERATIONAL_T (V);
   end TRN_Code;

   --  Packet 11 (7.4.2.?): the Train Data validated
   function Train_Packet return ETCS_Train_Packets.P11.Packet_T
     with Global => EVC_Train_Data.State
   is
      D : constant EVC_Supervision_Input.Train_Data_T :=
        EVC_Train_Data.Data;
      C : constant EVC_Train_Data.Categories_T :=
        EVC_Train_Data.Categories;
      P : ETCS_Train_Packets.P11.Packet_T;
      N : Natural := 0;
   begin
      P.NC_CDTRAIN := C.Cant_Deficiency;
      P.NC_TRAIN := C.Other;
      P.L_TRAIN := L_TRAIN_T (Natural'Min (Natural (D.Length / 100), 4095));
      P.V_MAXTRAIN :=
        V_MAXTRAIN_T (Natural'Min (Natural (D.Max_Speed) * 36 / 5000, 127));
      P.M_LOADINGGAUGE := C.Loading_Gauge;
      P.M_AXLELOADCAT := C.Axle_Load;
      P.M_AIRTIGHT := 0;
      P.N_AXLE := 0;
      --  M_VOLTAGE 1 .. 15: the bits of the traction systems accepted
      for V in 1 .. 15 loop
         pragma Loop_Invariant (N < V);
         if (C.Voltages / 2**V) mod 2 = 1 then
            N := N + 1;
            P.M_VOLTAGE_List (N) :=
              (M_VOLTAGE => M_VOLTAGE_T (V), Has_NID_CTRACTION => False,
               NID_CTRACTION => 0);
         end if;
      end loop;
      --  the first traction system is M_VOLTAGE, the loop the others
      if N > 0 then
         P.M_VOLTAGE := P.M_VOLTAGE_List (1).M_VOLTAGE;
         for I in 1 .. N - 1 loop
            pragma Loop_Invariant (I < N);
            P.M_VOLTAGE_List (I) := P.M_VOLTAGE_List (I + 1);
         end loop;
         P.N_ITER := N_ITER_T (N - 1);
      end if;
      P.N_ITER_2 := 0;
      return P;
   end Train_Packet;

   --  The fields of a message: NID_MESSAGE, L_MESSAGE (Finish), T_TRAIN,
   --  NID_ENGINE (0: no engine identity configured, phase E8), V5
   procedure Start (Kind : Known_Message_T;
                    T    : T_TRAIN_T;
                    V5   : Unsigned_64;
                    OK   : out Boolean)
     with Global => (In_Out => Wr)
   is
      V : ETCS_Message.Value_Array := (others => 0);
   begin
      ETCS_Bits.Clear (Wr);
      V (3) := Unsigned_64 (T);
      V (5) := V5;
      ETCS_Message.Write_Fields (Wr, Kind, V, OK);
   end Start;

   --  The padding, L_MESSAGE, and the message to the outbox
   procedure Send (S : Session_T; OK : in out Boolean)
     with Global => (In_Out => (Wr, Buf, R.State, R.Queue))
   is
      N : Natural;
   begin
      if OK then
         ETCS_Message.Finish (Wr, OK);
      end if;
      if OK then
         N := ETCS_Bits.Byte_Length (Wr);
         if N in 1 .. Buf'Last then
            Buf (1 .. N) := ETCS_Bits.Data (Wr);
            if EVC_Ports.Valid_RTM (Buf (1 .. N)) then
               R.Send (S, Buf (1 .. N));
            end if;
         end if;
      end if;
   end Send;

   procedure Send_Plain (S : Session_T; Kind : Known_Message_T;
                         T : T_TRAIN_T; V5 : Unsigned_64 := 0)
     with Global => (In_Out => (Wr, Buf, R.State, R.Queue))
   is
      OK : Boolean;
   begin
      Start (Kind, T, V5, OK);
      Send (S, OK);
   end Send_Plain;

   --  Packet 0 or 1 (3.6.5.1.2, EVC_Position)
   procedure Put_Position (Mode : Mode_T; OK : in out Boolean)
     with Global => (In_Out => Wr,
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State))
   is
   begin
      if not OK then
         return;
      end if;
      if EVC_Position.Report_Kind = EVC_Position.Report_P1 then
         ETCS_Train_Packets.P1.Encode
           (EVC_Position.Position_Report_2 (Mode, EVC_Levels.Level), Wr, OK);
      else
         ETCS_Train_Packets.P0.Encode
           (EVC_Position.Position_Report (Mode, EVC_Levels.Level), Wr, OK);
      end if;
   end Put_Position;

   --  159 (8.6.17): packet 2, the system version of the on-board
   procedure Send_159 (S : Session_T; T : T_TRAIN_T)
     with Global => (In_Out => (Wr, Buf, R.State, R.Queue))
   is
      OK : Boolean;
      P  : ETCS_Train_Packets.P2.Packet_T;
   begin
      P.M_VERSION := Onboard_Version;
      P.N_ITER := 0;
      Start (Train_M159, T, 0, OK);
      if OK then
         ETCS_Train_Packets.P2.Encode (P, Wr, OK);
      end if;
      Send (S, OK);
   end Send_159;

   --  157 (8.6.15, 5.4.3.2 A33/A34): Q_STATUSLRBG, the position, the
   --  train running number and the Train Data when valid; 129 (8.6.1):
   --  the position and the Train Data. TD: the Train Data went with it
   procedure Send_Report (S    : Session_T;
                          Kind : Known_Message_T;
                          Mode : Mode_T;
                          T    : T_TRAIN_T;
                          TD   : out Boolean)
     with Global => (In_Out => (Wr, Buf, R.State, R.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Mission.State,
                                EVC_Train_Data.State))
   is
      Status : constant Unsigned_64 :=
        (if EVC_Position.Status = EVC_Position.Valid
           and then EVC_Position.LRBG.Valid then 1
         elsif EVC_Position.Status = EVC_Position.Invalid
           and then EVC_Position.LRBG.Valid then 0
         else 2);
      OK : Boolean;
   begin
      TD := Kind = Train_M129
        or else EVC_Mission.Train_Data_Status = EVC_Mission.Valid;
      Start (Kind, T, (if Kind = Train_M157 then Status else 0), OK);
      Put_Position (Mode, OK);
      if OK and then Kind = Train_M157
        and then EVC_Mission.TRN_Status = EVC_Mission.Valid
      then
         ETCS_Train_Packets.P5.Encode
           ((NID_OPERATIONAL => TRN_Code, others => <>), Wr, OK);
      end if;
      if OK and then TD then
         ETCS_Train_Packets.P11.Encode (Train_Packet, Wr, OK);
      end if;
      TD := TD and then OK;
      Send (S, OK);
   end Send_Report;

   --  150 (8.6.11, 5.5.3.1.3): Q_DESK and the position
   procedure Send_150 (S : Session_T; Mode : Mode_T; T : T_TRAIN_T)
     with Global => (In_Out => (Wr, Buf, R.State, R.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Train_Inputs.State))
   is
      OK : Boolean;
   begin
      Start (Train_M150, T,
             (if EVC_Train_Inputs.Desk_Open then 1 else 0), OK);
      Put_Position (Mode, OK);
      Send (S, OK);
   end Send_150;

   --  The requests and the session messages of S (3.5.3.7, 3.5.5)
   procedure Produce_Session (S : Session_T; T : T_TRAIN_T;
                              Now : Time_Ms_T)
     with Global => (In_Out => (Links, EoM, Wr, Buf, R.State, R.Queue))
   is
      L : Link_T renames Links (S);
   begin
      if L.Release_Due then
         R.Request_Release (S);
         L.Release_Due := False;
         L.Connected := False;
         L.Released := True;
      end if;
      if L.Request_Due then
         R.Request_Set_Up (S, R.Info (S).RBC, R.Info (S).Radio, False);
         L.Request_Due := False;
         Count (L.Attempts);
      end if;
      if L.Send_155 then
         Send_Plain (S, Train_M155, T);
         L.Send_155 := False;
      end if;
      if L.Send_154 then
         Send_Plain (S, Train_M154, T);
         L.Send_154 := False;
         Terminate_Session (S, Now);      -- 3.5.3.7 d)
      end if;
      if L.Send_159 then
         Send_159 (S, T);
         L.Send_159 := False;
      end if;
   end Produce_Session;

   procedure Produce (Ctx : EVC_Radio.Context_T) is
      T  : constant T_TRAIN_T := Stamp (Ctx.Now_Ms);
      TD : Boolean;
   begin
      Count (Cycles);
      for S in Session_T loop
         pragma Loop_Invariant (True);
         Produce_Session (S, T, Ctx.Now_Ms);
      end loop;
      --  3.16.3.5: the acknowledgements (not after 156, 3.5.5.3)
      for I in 1 .. Ack_N loop
         pragma Loop_Invariant (True);
         if R.Info (Acks (I).S).State /= R.Terminating then
            Send_Plain (Acks (I).S, Train_M146, T, Unsigned_64 (Acks (I).T));
         end if;
      end loop;
      Ack_N := 0;
      --  5.4.3.2 D32: A33 / A34
      if SoM.Report_Due then
         SoM.Report_Due := False;
         if R.Established (SoM.Report_S)
           and then R.Info (SoM.Report_S).State /= R.Terminating
         then
            Send_Report (SoM.Report_S, Train_M157, Ctx.Mode, T, TD);
            SoM.Answer_Awaited :=
              not (EVC_Position.Status = EVC_Position.Valid
                   and then EVC_Position.LRBG.Valid);
            if TD then
               SoM.TD_Sent := True;
               SoM.TD_T := T;
               SoM.TD_Acked := False;
            end if;
         end if;
      end if;
      --  E16, 3.18.3.4: 129
      if SoM.TD_Due then
         SoM.TD_Due := False;
         if R.In_Communication then
            Send_Report (Session_T (R.Supervising), Train_M129, Ctx.Mode, T,
                         TD);
            SoM.TD_Sent := TD;
            SoM.TD_T := T;
         end if;
      end if;
      --  5.5.3.1.3: 150; with a desk open the RBC's order is awaited
      if EoM.Due then
         EoM.Due := False;
         if R.Established (EoM.S) then
            Send_150 (EoM.S, Ctx.Mode, T);
            EoM.Waiting := EVC_Train_Inputs.Desk_Open;
            EoM.Since := Ctx.Now_Ms;
         end if;
      end if;
      --  3.5.5.2 a: 156 last (3.5.5.3)
      for S in Session_T loop
         pragma Loop_Invariant (True);
         if Links (S).Send_156 then
            Send_Plain (S, Train_M156, T);
            Links (S).Send_156 := False;
         end if;
      end loop;
   end Produce;

end EVC_Sessions;
