--  ETCS on-board (EVC)
--  Phase E5, the session and link half, phase 1 (see the
--  specification): the communication sessions of 3.5 and the link of
--  3.16.3.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Bits;
with ETCS_Message;
with ETCS_Message_Catalogue; use ETCS_Message_Catalogue;
with ETCS_Train_Packets.P2;
with ETCS_Variables;         use ETCS_Variables;
with EVC_DMI_Port;
with EVC_Sessions.Mission;
with EVC_Sessions.Reports;
with Interfaces;             use Interfaces;

package body EVC_Sessions
  with SPARK_Mode => On,
       Refined_State => (State => (Events, Messages, Held_Back, Held,
                                   Mode_Changes, Cycles, Links, Order,
                                   Pending, Acks, Ack_N, NV, Ind,
                                   Requesting, Timer_On, Timer_Since,
                                   SB_Shown, Status_List, Status_N,
                                   EVC_Sessions.Mission.State,
                                   EVC_Sessions.Reports.State))
is

   package R renames EVC_Radio;
   use type R.Session_State_T;
   use type R.Session_Ref_T;
   use type R.RBC_Id_T;

   subtype Session_T is R.Session_T;
   subtype Time_Ms_T is R.Time_Ms_T;

   ---------------------------------------------------------------------
   --  Fixed values (A.3.1) and the system version (3.17, 7.5.1.79)
   ---------------------------------------------------------------------

   --  "The number of times to try to establish a safe radio connection"
   Max_Attempts : constant := 3;
   --  "Repetition of radio messages (i.e. excluding the first sending)"
   Max_Repeats  : constant := 3;
   --  "Waiting time before radio message repetition", "Waiting time for
   --  system version message", "Waiting time for acknowledgement of
   --  session establishment": all 15 s
   Wait_Ms      : constant := 15_000;
   --  "Maximum time to maintain a communication session in case of
   --  failed re-connection attempts"
   Keep_Ms      : constant := 300_000;
   --  "Additional delay time to disconnection on supervision of safe
   --  radio connection"
   Extra_Ms     : constant := 60_000;

   --  The system version this on-board supports with an RBC: version 3.0
   --  of 4.0.0 (M_VERSION 011 0000); the older versions of chapter 6
   --  are phase E7. Compatible: the same X (3.17.2)
   Supported_X     : constant := 3;
   Onboard_Version : constant := 48;

   --  A.3.1: the "connection status" timer (3.5.7.2)
   Status_Timer_Ms : constant := 45_000;

   --  7.5.1.96: NID_RBC "contact last known RBC" (3.5.3.13)
   Last_Known_RBC  : constant := 16_383;

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   --  What this half keeps of a session (the table is EVC_Radio's)
   type Link_T is record
      --  3.5.3.7 a: the requests to set up the safe radio connection are
      --  repeated at most Max_Attempts times (Capped) or until success
      Capped      : Boolean := False;
      Attempts    : Natural := 0;
      --  the requests of the next Produce
      Request_Due : Boolean := False;
      Release_Due : Boolean := False;
      --  the start of the current wait (the system version, the
      --  acknowledgement of 159 or of 156, the connection lost) and the
      --  repetitions made in it
      Since       : Time_Ms_T := 0;
      Repeats     : Natural range 0 .. Max_Repeats := 0;
      --  the messages of the next Produce
      Send_155    : Boolean := False;
      Send_159    : Boolean := False;
      Send_154    : Boolean := False;
      Send_156    : Boolean := False;
      --  3.5.3.7.4: message 38 awaited
      Ack_Awaited : Boolean := False;
   end record;

   type Links_T is array (Session_T) of Link_T;

   --  A session management order not yet applied (3.5.2.6.1)
   type Order_T is record
      Present   : Boolean := False;
      Establish : Boolean := False;
      RBC       : R.RBC_Id_T := R.No_RBC;
      Radio     : NID_RADIO_T := 0;
   end record;

   --  A session to establish once a session is free (3.5.3.4.2,
   --  3.5.3.5.2.1, 3.5.3.7.4.1, 3.5.4.3.1)
   type Pending_T is record
      Active : Boolean := False;
      Capped : Boolean := False;
      RBC    : R.RBC_Id_T := R.No_RBC;
      Radio  : NID_RADIO_T := 0;
   end record;

   --  3.16.3.5: the acknowledgements owed (T_TRAIN of the message)
   Max_Acks : constant := 8;
   type Ack_T is record
      S : Session_T := 1;
      T : T_TRAIN_T := 0;
   end record;
   type Acks_T is array (1 .. Max_Acks) of Ack_T;

   --  3.16.3.4: the supervision of the safe radio connection
   type NV_T is record
      Expired     : Boolean := False;   -- T_NVCONTACT passed
      Since       : Time_Ms_T := 0;     -- at
      SB          : Boolean := False;   -- the service brake commanded
      Reconnected : Boolean := False;   -- 3.16.3.4.3 done
   end record;

   type Held_T is array (Condition_T) of Boolean;

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
   NV           : NV_T;

   --  3.5.7: the indication status, whether requests to set up the
   --  safe radio connection with the relevant RBC are going on, the
   --  "connection status" timer (3.5.7.2, 3.5.7.3)
   Ind          : Indication_T := No_Connection;
   Requesting   : Boolean := False;
   Timer_On     : Boolean := False;
   Timer_Since  : Time_Ms_T := 0;

   --  3.16.3.4.4: the service brake of T_NVCONTACT shown to the driver
   SB_Shown     : Boolean := False;
   type Status_List_T is array (1 .. Max_Status_Events) of Status_Event_T;
   Status_List  : Status_List_T := (others => (others => <>));
   Status_N     : Natural range 0 .. Max_Status_Events := 0;

   ---------------------------------------------------------------------
   --  Helpers
   ---------------------------------------------------------------------

   procedure Count (N : in out Natural)
     with Post => (if N'Old < Natural'Last then N = N'Old + 1 else N = N'Old)
   is
   begin
      if N < Natural'Last then
         N := N + 1;
      end if;
   end Count;

   --  The elapsed time from Since to Now (0 when the clock went back)
   function Elapsed (Since, Now : Time_Ms_T) return Time_Ms_T is
     (if Now >= Since then Now - Since else 0);

   --  A system status message of the DMI catalogue for the cycle
   procedure Show (Entry_Number : Natural; Event : Natural)
     with Global => (In_Out => (Status_List, Status_N)),
          Pre => Entry_Number <= 255 and then Event <= 2
   is
   begin
      if Status_N < Max_Status_Events then
         Status_N := Status_N + 1;
         Status_List (Status_N) :=
           (Entry_Number => Entry_Number, Event => Event);
      end if;
   end Show;

   ---------------------------------------------------------------------
   --  The indication of the safe radio connection (3.5.7, Tables 1, 2)
   ---------------------------------------------------------------------

   --  3.5.7.5, 3.5.7.6: the session S is the one indicated: the session
   --  of the supervising RBC; before there is one, any session.
   --  Decision (phase 1, no handover): the switch of 3.5.7.6 is the
   --  change of the supervising session.
   function Relevant (S : Session_T) return Boolean is
     (R.Supervising = R.No_Session
      or else R.Supervising = R.Session_Ref_T (S))
     with Global => R.State;

   --  3.5.7.3: a request to set up the safe radio connection of S sent at
   --  Now: the first one of a series starts the "connection status" timer
   procedure Ind_Request (S : Session_T; Now : Time_Ms_T)
     with Global => (Input  => R.State,
                     In_Out => (Requesting, Timer_On, Timer_Since))
   is
   begin
      if Relevant (S) and then not Requesting then
         Requesting := True;
         Timer_On := True;
         Timer_Since := Now;
      end if;
   end Ind_Request;

   --  Table 2 [4]: the safe radio connection of S is set up
   procedure Ind_Set_Up (S : Session_T)
     with Global => (Input  => R.State,
                     In_Out => (Ind, Requesting, Timer_On))
   is
   begin
      if Relevant (S) then
         Ind := Connection_Up;
         Requesting := False;
         Timer_On := False;
      end if;
   end Ind_Set_Up;

   --  3.5.7.4: the requests to set up the safe radio connection of S are
   --  stopped, not by success, or its connection is over: the timer is
   --  stopped; Table 2 [1] (Final_SoM: the final attempt of a start of
   --  mission failed) to "Connection Lost/Set-Up failed", else [3], [5],
   --  [6] to "No Connection"
   procedure Ind_Stopped (S : Session_T; Final_SoM : Boolean)
     with Global => (Input  => R.State,
                     In_Out => (Ind, Requesting, Timer_On))
   is
   begin
      if Relevant (S) then
         Requesting := False;
         Timer_On := False;
         if Final_SoM then
            if Ind = No_Connection then
               Ind := Connection_Lost;
            end if;
         else
            Ind := No_Connection;
         end if;
      end if;
   end Ind_Stopped;

   --  Table 2 [5]: the on-board releases the safe radio connection of S
   procedure Ind_Released (S : Session_T)
     with Global => (Input  => R.State, In_Out => Ind)
   is
   begin
      if Relevant (S) and then Ind = Connection_Up then
         Ind := No_Connection;
      end if;
   end Ind_Released;

   --  Table 2 [2]: the "connection status" timer expires
   procedure Ind_Timer (Now : Time_Ms_T)
     with Global => (In_Out => (Ind, Timer_On), Input => Timer_Since)
   is
   begin
      if Timer_On and then Elapsed (Timer_Since, Now) >= Status_Timer_Ms
      then
         Ind := Connection_Lost;
         Timer_On := False;
      end if;
   end Ind_Timer;

   ---------------------------------------------------------------------
   --  The steps of a session (3.5)
   ---------------------------------------------------------------------

   --  3.5.3.7 a: set up a session with RBC on the number Radio in the
   --  first session the on-board handles that is free; none free: it
   --  waits until one is (Pending, 3.5.3.4.2, 3.5.3.5.2.1)
   procedure Open (RBC    : R.RBC_Id_T;
                   Radio  : NID_RADIO_T;
                   Capped : Boolean)
     with Global => (In_Out => (Links, R.State), Output => Pending),
          Post => R.Sessions = R.Sessions'Old
                  and then R.Supervising = R.Supervising'Old
                  and then R.Accepting = R.Accepting'Old
   is
      N  : constant R.Session_Count_T := R.Sessions;
      Sv : constant R.Session_Ref_T := R.Supervising;
      Ac : constant R.Session_Ref_T := R.Accepting;
   begin
      for S in Session_T loop
         pragma Loop_Invariant (R.Sessions = N
                                and then R.Supervising = Sv
                                and then R.Accepting = Ac);
         if R.Usable (S) and then R.Info (S).State = R.Idle then
            R.Reset_Session (S);
            R.Set_Peer (S, RBC, Radio);
            R.Set_State (S, R.Connecting);
            --  a release requested by the end of the session before it
            --  goes first (Produce)
            Links (S) := (Capped      => Capped,
                          Request_Due => True,
                          Release_Due => Links (S).Release_Due,
                          others      => <>);
            Pending := (others => <>);
            return;
         end if;
      end loop;
      Pending := (Active => True, Capped => Capped,
                  RBC    => RBC,  Radio  => Radio);
   end Open;

   --  The session S is over (3.5.5.2 c, 3.5.5.3.2, 3.5.3.8, 3.5.4.2.1):
   --  back to Idle; Release: the release of its safe radio connection is
   --  requested; the indication (3.5.7.4, Table 2: Final_SoM [1], else
   --  [3], [5], [6])
   procedure Close (S : Session_T; Release : Boolean;
                    Final_SoM : Boolean := False)
     with Global => (In_Out => (Links, R.State, Ind, Requesting, Timer_On)),
          Post => R.Info (S).State = R.Idle
                  and then R.Sessions = R.Sessions'Old
                  and then R.Roles_Consistent
   is
   begin
      Ind_Stopped (S, Final_SoM);
      Links (S) := (Release_Due => Release, others => <>);
      if R.Supervising = R.Session_Ref_T (S)
        or else R.Accepting = R.Session_Ref_T (S)
        or else not R.Roles_Consistent
      then
         R.Set_Roles (R.No_Session, R.No_Session);
      end if;
      R.Reset_Session (S);
   end Close;

   --  3.5.5.2 a: terminate the session S. Established: message 156, its
   --  acknowledgement awaited (3.5.5.3.1); being established: aborted
   --  and its safe radio connection released (3.5.3.8)
   procedure Terminate_Session (S : Session_T; Now : Time_Ms_T)
     with Global => (In_Out => (Links, R.State, Ind, Requesting, Timer_On)),
          Post => R.Sessions = R.Sessions'Old
   is
   begin
      case R.Info (S).State is
         when R.Established | R.Connection_Lost =>
            R.Set_State (S, R.Terminating);
            --  3.5.5.3: nothing else is sent after 156
            Links (S) := (Send_156 => True, Since => Now, others => <>);
         when R.Connecting | R.Initiating =>
            Close (S, Release => True);
         when R.Idle | R.Terminating =>
            null;
      end case;
   end Terminate_Session;

   --  3.5.3.4, 3.5.3.4.1, 3.5.3.4.2, 3.5.3.5.2: establish a session with
   --  RBC. Nothing when one is being established or established with it
   --  (156 not sent); the sessions with other RBCs are terminated; with
   --  a session with it terminating, the new one once it is over
   procedure Establish (RBC    : R.RBC_Id_T;
                        Radio  : NID_RADIO_T;
                        Capped : Boolean;
                        Now    : Time_Ms_T)
     with Global => (In_Out => (Links, Pending, R.State,
                                Ind, Requesting, Timer_On)),
          Post => R.Sessions = R.Sessions'Old
   is
      N : constant R.Session_Count_T := R.Sessions;
      Waiting_For_It : Boolean := False;
   begin
      for S in Session_T loop
         pragma Loop_Invariant (R.Sessions = N);
         if R.Info (S).State /= R.Idle and then R.Info (S).RBC = RBC then
            if R.Info (S).State /= R.Terminating then
               return;
            end if;
            Waiting_For_It := True;
         end if;
      end loop;
      for S in Session_T loop
         pragma Loop_Invariant (R.Sessions = N);
         if R.Info (S).State /= R.Idle and then R.Info (S).RBC /= RBC then
            Terminate_Session (S, Now);
         end if;
      end loop;
      if Waiting_For_It then
         Pending := (Active => True, Capped => Capped,
                     RBC    => RBC,  Radio  => Radio);
      else
         Open (RBC, Radio, Capped);
      end if;
   end Establish;

   procedure Take_Order (Establish : Boolean;
                         RBC       : EVC_Radio.RBC_Id_T;
                         Radio     : ETCS_Variables.NID_RADIO_T)
   is
   begin
      Order := (Present => True, Establish => Establish,
                RBC     => RBC,  Radio     => Radio);
   end Take_Order;

   function Service_Brake return Boolean is (NV.SB)
     with Refined_Global => NV;
   function Has_Released return Boolean is (Held_Back > 0)
     with Refined_Global => Held_Back;
   function Holds (C : Condition_T) return Boolean is (Held (C))
     with Refined_Global => Held;
   function Indication return Indication_T is (Ind)
     with Refined_Global => Ind;
   function Status_Event_Count return Natural is (Status_N)
     with Refined_Global => Status_N;
   function Status_Event (I : Positive) return Status_Event_T is
     (Status_List (I))
     with Refined_Global => (Input => Status_List, Proof_In => Status_N);
   function Events_Taken return Natural is (Events)
     with Refined_Global => Events;
   function Messages_Taken return Natural is (Messages)
     with Refined_Global => Messages;
   function Mode_Changes_Taken return Natural is (Mode_Changes)
     with Refined_Global => Mode_Changes;
   function Cycles_Produced return Natural is (Cycles)
     with Refined_Global => Cycles;

   --  3.16.3.3.3, 3.16.3.2.3: T is later than Last, the on-board timer
   --  (EVC_Radio.T_Train_At, modulo 2**32 - 1) wrapping around (a
   --  difference of less than half the range)
   function Newer (T, Last : T_TRAIN_T) return Boolean is
     (T /= T_TRAIN_Unknown and then Last /= T_TRAIN_Unknown
      and then ((Unsigned_64 (T) + (2**32 - 1) - Unsigned_64 (Last))
                  mod (2**32 - 1)) in 1 .. 2**31 - 1);

   --  3.17.2: the X of M_VERSION (its three most significant bits)
   function Compatible (V : M_VERSION_T) return Boolean is
     (Natural (V) / 16 = Supported_X);

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
      NV := (others => <>);
      Ind := No_Connection;
      Requesting := False;
      Timer_On := False;
      Timer_Since := 0;
      SB_Shown := False;
      Status_List := (others => (others => <>));
      Status_N := 0;
      Mission.Clear;
      Reports.Clear;
   end Clear;

   --  3.5.3.7 a, 3.5.4.2: the set-up of the safe radio connection of S
   --  failed (or the connection went down before the system version): a
   --  new request at once; in a start of mission, after the last of
   --  Max_Attempts the establishment is given up (3.5.3.7 a)
   procedure Set_Up_Failed (S : Session_T)
     with Global => (In_Out => (Links, R.State, Ind, Requesting, Timer_On)),
          Post => R.Sessions = R.Sessions'Old
   is
   begin
      if Links (S).Capped and then Links (S).Attempts >= Max_Attempts then
         Close (S, Release => False, Final_SoM => True);
      else
         if R.Info (S).State = R.Initiating then
            R.Set_State (S, R.Connecting);
         end if;
         Links (S).Request_Due := True;
         Links (S).Send_155 := False;
      end if;
   end Set_Up_Failed;

   --  3.5.3.7, 3.5.4, 3.5.5: the events of the safe radio connection.
   --  A connection released that was not ordered is lost (3.5.4.1: the
   --  release the on-board requests closes the session first). The
   --  registration events are those of 3.5.6 (phase 2).
   --  Decision: the connection lost while terminating ends the session
   --  (no acknowledgement can come, nothing to release).
   procedure Take_Event (S      : EVC_Radio.Session_T;
                         Event  : EVC_Ports.RTM_Event_T;
                         Now_Ms : EVC_Radio.Time_Ms_T)
   is
      St : constant R.Session_State_T := R.Info (S).State;
   begin
      Count (Events);
      if not R.Usable (S) then
         return;
      end if;
      case Event is
         when EVC_Ports.Connection_Set_Up =>
            if St = R.Connecting then
               --  3.5.3.7 b: message 155, the system version awaited
               R.Set_State (S, R.Initiating);
               Links (S).Send_155 := True;
               Links (S).Since := Now_Ms;
               Ind_Set_Up (S);
            elsif St = R.Connection_Lost then
               --  3.5.4.3: set up again within the session
               R.Set_State (S, R.Established);
               Links (S).Request_Due := False;
               Ind_Set_Up (S);
            end if;
         when EVC_Ports.Connection_Lost | EVC_Ports.Connection_Released =>
            case St is
               when R.Established =>
                  --  3.5.4.1, 3.5.4.2: kept for Keep_Ms, set up again
                  R.Set_State (S, R.Connection_Lost);
                  Links (S).Since := Now_Ms;
                  Links (S).Request_Due := True;
               when R.Initiating =>
                  Set_Up_Failed (S);
               when R.Terminating =>
                  Close (S, Release => False);
               when R.Idle | R.Connecting | R.Connection_Lost =>
                  null;
            end case;
         when EVC_Ports.Set_Up_Failed =>
            if St = R.Connecting then
               Set_Up_Failed (S);
            elsif St = R.Connection_Lost then
               Links (S).Request_Due := True;   -- 3.5.4.3
            end if;
         when EVC_Ports.Registered | EVC_Ports.Registration_Failed =>
            null;
      end case;
   end Take_Event;

   --  3.5.3.7 d, 3.5.4.7: the system version V of the RBC (message 32)
   --  received on S. The session is established; the on-board supports
   --  a compatible version: 159 (with packet 2) and its acknowledgement
   --  awaited; none: 154, the driver informed and the session terminated.
   --  Decision (phase 1, no handover yet): the session established
   --  becomes the one of the supervising RBC (3.15.1 is phase 2)
   procedure Take_Version (S : Session_T; V : M_VERSION_T; Now : Time_Ms_T)
     with Global => (In_Out => (Links, R.State, Ind, Requesting,
                                Timer_On, Status_List, Status_N)),
          Pre  => R.Usable (S),
          Post => R.Sessions = R.Sessions'Old
   is
      St : constant R.Session_State_T := R.Info (S).State;
   begin
      if St not in R.Initiating | R.Established | R.Connection_Lost then
         return;
      end if;
      R.Set_Version (S, V);
      if St = R.Initiating then
         R.Set_State (S, R.Established);
      end if;
      if Compatible (V) then
         Links (S).Send_159 := True;
         Links (S).Ack_Awaited := True;
         Links (S).Since := Now;
         Links (S).Repeats := 0;
         if R.Supervising = R.No_Session and then R.Accepting = R.No_Session
         then
            R.Set_Roles (R.Session_Ref_T (S), R.No_Session);
         end if;
      else
         --  3.5.3.7 d) second bullet: the driver informed (DMI
         --  "Trackside not compatible", entry 15)
         Terminate_Session (S, Now);
         Links (S).Send_154 := True;
         Show (EVC_DMI_Port.SS_Trackside_Not_Compatible,
               Natural (EVC_DMI_Port.SS_Event_Start));
      end if;
   end Take_Version;

   --  3.16.3.3.3: a message whose time stamp is not later than the one
   --  of the message received before it on S is inconsistent: ignored.
   --  3.5.5.6: after 156 only the acknowledgement 39 is taken. 3.16.3.5:
   --  an acknowledgement owed (M_ACK). The session messages (32, 38, 39)
   --  are taken here; the others pass to the authority half.
   --  Decision: a message on a session not established passes (whether
   --  the information is accepted is 4.8, phase 2); one on a session the
   --  on-board does not handle is ignored.
   procedure Take_Message (S       : EVC_Radio.Session_T;
                           Now_Ms  : EVC_Radio.Time_Ms_T;
                           Verdict : out Verdict_T)
   is
      Kind : constant Message_Kind_T := EVC_Received.Last_Kind;
      T    : constant T_TRAIN_T :=
        T_TRAIN_T (EVC_Received.Last_Value (T_TRAIN) and 16#FFFF_FFFF#);
      Info : constant R.Session_Info_T := R.Info (S);
   begin
      Count (Messages);
      Verdict := Ignore;
      if not R.Usable (S)
        or else (Info.Received and then not Newer (T, Info.Last_Received))
      then
         return;
      end if;
      R.Note_Received (S, T, Now_Ms);
      if Info.State = R.Terminating then
         if Kind = Track_M39 then
            Close (S, Release => True);       -- 3.5.5.2 c
         end if;
         return;
      end if;
      if EVC_Received.Last_Value (M_ACK) = 1 and then Ack_N < Max_Acks
      then
         Ack_N := Ack_N + 1;
         Acks (Ack_N) := (S => S, T => T);
      end if;
      case Kind is
         when Track_M32 =>
            Take_Version
              (S, M_VERSION_T (EVC_Received.Last_Value (M_VERSION)
                               and 127),
               Now_Ms);
         when Track_M38 =>
            Links (S).Ack_Awaited := False;   -- 3.5.3.7.4
         when Track_M39 =>
            null;                             -- no termination going on
         when Track_M8 | Track_M40 | Track_M41 | Track_M43 =>
            --  3.18.3.4.1, 5.4.3.2 A35, A23, A38 (EVC_Sessions.Mission)
            declare
               Taken : Boolean;
            begin
               Mission.Take_Answer (S, Kind, Taken);
               if not Taken then
                  Verdict := Pass;
               end if;
            end;
         when others =>
            --  3.6.5.1.5: the position report parameters
            Reports.Take_Message;
            Verdict := Pass;
      end case;
   end Take_Message;

   procedure Take_Released (S    : out EVC_Radio.Session_T;
                            Data : out EVC_Bytes.Byte_Array;
                            Last : out Natural)
   is
   begin
      --  the stub holds nothing: an empty message (NID_MESSAGE 0,
      --  L_MESSAGE 3), which the codec rejects
      S := 1;
      Data := (others => 0);
      Data (Data'First + 2) := 192;
      Last := Data'First + 2;
      if Held_Back > 0 then
         Held_Back := Held_Back - 1;
      end if;
   end Take_Released;

   --  The waits of the session S at the on-board time Now
   procedure Supervise_Session (S : Session_T; Now : Time_Ms_T)
     with Global => (In_Out => (Links, Pending, R.State,
                                Ind, Requesting, Timer_On)),
          Post => R.Sessions = R.Sessions'Old
   is
      L     : Link_T renames Links (S);
      Info  : constant R.Session_Info_T := R.Info (S);
      Over  : constant Boolean := Elapsed (L.Since, Now) >= Wait_Ms;
   begin
      case Info.State is
         when R.Initiating =>
            --  3.5.3.7.3: no system version: released, set up again
            if Over then
               R.Set_State (S, R.Connecting);
               L.Release_Due := True;
               L.Request_Due := True;
            end if;
         when R.Established =>
            --  3.5.3.7.4: 159 once again; 3.5.3.7.4.1: then terminated
            --  and established again
            if L.Ack_Awaited and then Over then
               if L.Repeats = 0 then
                  L.Send_159 := True;
                  L.Repeats := 1;
                  L.Since := Now;
               else
                  Terminate_Session (S, Now);
                  Pending := (Active => True, Capped => False,
                              RBC    => Info.RBC, Radio => Info.Radio);
               end if;
            end if;
         when R.Connection_Lost =>
            --  3.5.4.2.1: not set up again in time: terminated (the
            --  attempts stopped); 3.5.4.3.1, 3.5.3.4 f): a new one
            if Elapsed (L.Since, Now) >= Keep_Ms then
               Close (S, Release => True);
               Pending := (Active => True, Capped => False,
                           RBC    => Info.RBC, Radio => Info.Radio);
            end if;
         when R.Terminating =>
            --  3.5.5.3.1: 156 repeated; 3.5.5.3.2: then terminated
            if Over then
               if L.Repeats < Max_Repeats then
                  L.Send_156 := True;
                  L.Repeats := L.Repeats + 1;
                  L.Since := Now;
               else
                  Close (S, Release => True);
               end if;
            end if;
         when R.Idle | R.Connecting =>
            null;
      end case;
   end Supervise_Session;

   --  3.5.2.6.1, 3.5.5.1 a): the session management order of the cycle
   procedure Apply_Order (Now : Time_Ms_T)
     with Global => (In_Out => (Order, Links, Pending, R.State,
                                Ind, Requesting, Timer_On)),
          Post => R.Sessions = R.Sessions'Old
   is
      N : constant R.Session_Count_T := R.Sessions;
   begin
      if not Order.Present then
         return;
      end if;
      if Order.Establish and then Order.RBC.NID_RBC = Last_Known_RBC then
         --  3.5.3.13: the stored contact, the number of the order
         --  ignored; none stored: the order ignored (3.5.3.13.1)
         if R.Contact.Known then
            Establish (R.Contact.RBC, R.Contact.Radio, Capped => False,
                       Now => Now);
         end if;
      elsif Order.Establish then
         --  4.10.1.4.2 b): the RBC contact of the order is stored; 3.5.3.15:
         --  NID_RADIO "use the short number" goes to the RTM as it is
         R.Set_Contact ((Known => True, Valid => True,
                         RBC   => Order.RBC, Radio => Order.Radio));
         Establish (Order.RBC, Order.Radio, Capped => False, Now => Now);
      else
         Pending := (others => <>);
         for S in Session_T loop
            pragma Loop_Invariant (R.Sessions = N);
            Terminate_Session (S, Now);
         end loop;
      end if;
      Order := (others => <>);
   end Apply_Order;

   --  3.16.3.4.1: the age of the time stamp T at the on-board time Now
   --  (the on-board clock of EVC_Radio.Time_Of_Stamp)
   function Age_Ms (T : T_TRAIN_T; Now : Time_Ms_T) return Time_Ms_T is
     (Now - EVC_Radio.Time_Of_Stamp (T, Now));

   --  3.16.3.4: the supervision of the safe radio connection with the
   --  supervising RBC: the time stamp of the latest message older than
   --  T_NVCONTACT, the reaction M_NVCONTACT ([41] train trip, the
   --  service brake, none); 3.16.3.4.3: Extra_Ms later the connection
   --  released and set up again, the session kept. A new message ends
   --  it (the service brake released, 3.14.1.7).
   --  Decision: supervised whenever the session of the supervising RBC
   --  is established, in any level (the RBC sends empty messages,
   --  3.16.3.4.7); not while the connection is lost (the session being
   --  maintained, 3.5.4) the supervision goes on
   procedure Supervise_Contact (Now : Time_Ms_T; Standstill : Boolean)
     with Global => (In_Out => (NV, Held, Links, R.State),
                     Input  => EVC_National_Values.State),
          Post => R.Sessions = R.Sessions'Old
   is
      Sv   : constant R.Session_Ref_T := R.Supervising;
      NVal : constant EVC_National_Values.Set_T :=
        EVC_National_Values.Current;
   begin
      if Sv = R.No_Session
        or else not R.Established (Session_T (Sv))
        or else not R.Info (Session_T (Sv)).Received
        or else Age_Ms (R.Info (Session_T (Sv)).Last_Received, Now)
                  <= Unsigned_64 (NVal.T_NVCONTACT)
      then
         NV := (others => <>);
         return;
      end if;
      if not NV.Expired then
         NV := (Expired => True, Since => Now, SB => NVal.M_NVCONTACT = 1,
                Reconnected => False);
      end if;
      Held (C_41) := NVal.M_NVCONTACT = 0;
      --  3.14.1.7, 3.16.3.4.5 a): the service brake released at
      --  standstill (not applied again until a new expiry)
      if Standstill then
         NV.SB := False;
      end if;
      if not NV.Reconnected and then Elapsed (NV.Since, Now) >= Extra_Ms
        and then R.Info (Session_T (Sv)).State = R.Established
      then
         R.Set_State (Session_T (Sv), R.Connection_Lost);
         Links (Session_T (Sv)).Since := Now;
         Links (Session_T (Sv)).Release_Due := True;
         Links (Session_T (Sv)).Request_Due := True;
         NV.Reconnected := True;
      end if;
   end Supervise_Contact;

   --  The requests of the level 2 start and end of mission and of the
   --  Train Data (EVC_Sessions.Mission): A31 (the three attempts of
   --  A.3.1), A40 and 5.5.4.1.1 (the termination), A40 "Train is
   --  rejected" (DMI entry 20)
   procedure Apply_Mission (Ctx : EVC_Radio.Context_T)
     with Global => (In_Out => (Mission.State, Links, Pending, R.State,
                                Ind, Requesting, Timer_On, Status_List,
                                Status_N),
                     Input  => (EVC_Mission.State, EVC_Levels.State,
                                EVC_Position.State, EVC_Train_Data.State,
                                EVC_Driver_Requests.State))
   is
      Req : Mission.Request_T;
   begin
      Mission.Evaluate (Ctx, Req);
      if Req.Stop and then R.Usable (Req.Session)
        and then R.Info (Req.Session).State /= R.Idle
      then
         Terminate_Session (Req.Session, Ctx.Now_Ms);
      end if;
      if Req.Rejected then
         Show (EVC_DMI_Port.SS_Train_Rejected,
               Natural (EVC_DMI_Port.SS_Event_Start));
      end if;
      if Req.Open then
         Establish (Req.RBC, Req.Radio, True, Ctx.Now_Ms);
      end if;
   end Apply_Mission;

   procedure Evaluate (Ctx : EVC_Radio.Context_T) is
      N : constant R.Session_Count_T := R.Sessions;
   begin
      Held := (others => False);
      Apply_Order (Ctx.Now_Ms);
      for S in Session_T loop
         pragma Loop_Invariant (R.Sessions = N);
         if R.Usable (S) then
            Supervise_Session (S, Ctx.Now_Ms);
         end if;
      end loop;
      --  3.5.3.4.2, 3.5.3.5.2.1, 3.5.4.3.1: a session waiting for a free
      --  one, or for the end of the one with the same RBC
      declare
         P : constant Pending_T := Pending;
      begin
         if P.Active and then not R.In_Session_With (P.RBC) then
            Establish (P.RBC, P.Radio, P.Capped, Ctx.Now_Ms);
         end if;
      end;
      Apply_Mission (Ctx);
      Reports.Evaluate (SoM => Mission.Reporting);
      Supervise_Contact (Ctx.Now_Ms, EVC_Odometry.Standstill);
      --  3.16.3.4.4: the driver informed of the service brake ("Communication
      --  error", the DMI's entry 4; its end: 3.14.1.7)
      if NV.SB /= SB_Shown then
         Show (EVC_DMI_Port.SS_Communication_Error_Brake,
               (if NV.SB then 0 else 1));
         SB_Shown := NV.SB;
      end if;
      Ind_Timer (Ctx.Now_Ms);
   end Evaluate;

   procedure Mode_Changed (From, To : Mode_T) is
   begin
      Count (Mode_Changes);
      Mission.Mode_Changed (From, To);
      Reports.Mode_Changed;
   end Mode_Changed;

   ---------------------------------------------------------------------
   --  Produce: the messages (8.6) and the requests of the RTM port
   ---------------------------------------------------------------------

   --  The session messages are short: a writer of Msg_Size bytes
   Msg_Size : constant := 16;
   subtype Msg_Writer_T is ETCS_Bits.Writer (Msg_Size);

   --  The header of a train to track message of Kind (8.4.4.7.1): T,
   --  NID_ENGINE, and V5, the fifth variable (the T_TRAIN acknowledged
   --  by 146)
   procedure Start (W    : in out Msg_Writer_T;
                    Kind : Known_Message_T;
                    T    : T_TRAIN_T;
                    V5   : Unsigned_64;
                    OK   : out Boolean)
   is
      V : ETCS_Message.Value_Array := (others => 0);
   begin
      ETCS_Bits.Clear (W);
      V (3) := Unsigned_64 (T);
      --  NID_ENGINE (7.5.1.86): the identity of the configuration
      V (4) := Unsigned_64 (R.Engine_Id);
      V (5) := V5;
      ETCS_Message.Write_Fields (W, Kind, V, OK);
   end Start;

   --  The padding and L_MESSAGE, then the message to the outbox of S
   procedure Finish_And_Send (W : in out Msg_Writer_T; S : Session_T;
                              OK : Boolean)
     with Global => (In_Out => (R.State, R.Queue))
   is
      Done : Boolean := OK;
   begin
      if Done then
         ETCS_Message.Finish (W, Done);
      end if;
      if Done then
         declare
            M : constant EVC_Bytes.Byte_Array := ETCS_Bits.Data (W);
         begin
            if EVC_Ports.Valid_RTM (M) then
               R.Send (S, M);
            end if;
         end;
      end if;
   end Finish_And_Send;

   pragma Warnings
     (GNATprove, Off, """W"" is set by ""Finish_And_Send"" but not used*",
      Reason => "the writer of one message is not used after it");

   --  A message of Kind without packets on S
   procedure Send_Plain (S  : Session_T; Kind : Known_Message_T;
                         T  : T_TRAIN_T; V5 : Unsigned_64 := 0)
     with Global => (In_Out => (R.State, R.Queue))
   is
      W  : Msg_Writer_T;
      OK : Boolean;
   begin
      Start (W, Kind, T, V5, OK);
      Finish_And_Send (W, S, OK);
   end Send_Plain;

   --  159 (8.6.17): packet 2, the system version of the on-board
   procedure Send_159 (S : Session_T; T : T_TRAIN_T)
     with Global => (In_Out => (R.State, R.Queue))
   is
      W  : Msg_Writer_T;
      OK : Boolean;
      P  : ETCS_Train_Packets.P2.Packet_T;
   begin
      P.M_VERSION := Onboard_Version;
      P.N_ITER := 0;
      Start (W, Train_M159, T, 0, OK);
      if OK then
         ETCS_Train_Packets.P2.Encode (P, W, OK);
      end if;
      Finish_And_Send (W, S, OK);
   end Send_159;

   pragma Warnings
     (GNATprove, On, """W"" is set by ""Finish_And_Send"" but not used*");

   --  The requests and the session messages of S (156 apart)
   procedure Produce_Session (S : Session_T; T : T_TRAIN_T; Now : Time_Ms_T)
     with Global => (In_Out => (Links, R.State, R.Queue, Ind,
                                Requesting, Timer_On, Timer_Since))
   is
      L : Link_T renames Links (S);
   begin
      if L.Release_Due then
         R.Request_Release (S);
         L.Release_Due := False;
         Ind_Released (S);
      end if;
      if L.Request_Due then
         R.Request_Set_Up (S, R.Info (S).RBC, R.Info (S).Radio, False);
         L.Request_Due := False;
         Count (L.Attempts);
         Ind_Request (S, Now);
      end if;
      if L.Send_155 then
         Send_Plain (S, Train_M155, T);
         L.Send_155 := False;
      end if;
      if L.Send_154 then
         Send_Plain (S, Train_M154, T);
         L.Send_154 := False;
      end if;
      if L.Send_159 then
         Send_159 (S, T);
         L.Send_159 := False;
      end if;
   end Produce_Session;

   procedure Produce (Ctx : EVC_Radio.Context_T) is
      T : constant T_TRAIN_T := EVC_Radio.T_Train_At (Ctx.Now_Ms);
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
      --  3.5.5.2 a: 156 last (3.5.5.3)
      for S in Session_T loop
         pragma Loop_Invariant (True);
         if Links (S).Send_156 then
            Send_Plain (S, Train_M156, T);
            Links (S).Send_156 := False;
         end if;
      end loop;
      --  157, 129, 150 (after 159 of the cycle)
      Mission.Produce (Ctx);
      --  136 (3.6.5), after the SoM position report of the cycle
      Reports.Produce (Ctx);
      --  the system status messages of the cycle were sent (EVC_Core)
      Status_N := 0;
   end Produce;

   function Position_Confirmed return Boolean is
     (Mission.Position_Confirmed);
   function Position_To_Delete return Boolean is
     (Mission.Position_To_Delete);
   function SoM_Opening return Boolean is (Mission.Opening);
   function Train_Data_Sent return Natural is (Mission.Train_Data_Sent);
   function SoM_Reports_Sent return Natural is (Mission.Reports_Sent);
   function EoM_Sent return Natural is (Mission.EoM_Sent);
   function Position_Reports_Sent return Natural is
     (Reports.Reports_Sent);
   function Report_Parameters_Taken return Natural is
     (Reports.Parameters_Taken);

end EVC_Sessions;
