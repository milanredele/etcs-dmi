--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half (see the specification).

with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P49;
with ETCS_Track_Packets.P57;
with ETCS_Track_Packets.P63;
with ETCS_Train_Packets.P0;
with ETCS_Variables;          use ETCS_Variables;
with EVC_DMI_Port;
with EVC_Distances;           use EVC_Distances;
with EVC_Radio_Acceptance;
with EVC_Radio_Authority.Buffer;
with Interfaces;              use Interfaces;

package body EVC_Radio_Authority
  with SPARK_Mode => On,
       Refined_State => (State => (Messages, Rejected_N, TD_Acked, Held, Stop_Received,
                                   Mode_Changes, Cycles, Radio_MAs,
                                   Params, Reasons, Request_Due,
                                   Request_Sent, Last_Request_Ms,
                                   SR_Authorised, Requests, Start_Reason,
                                   Deleted_Reason, Shortening, Emergency,
                                   SR_Auth, Passed_Listed, Mode_Now,
                                   Exit_Recognised, SH_Req, Status_Now,
                                   EVC_Radio_Authority.Buffer.State))
is

   use type ETCS_Message_Catalogue.Message_Kind_T;
   use type ETCS_Catalogue.Packet_Kind_T;
   use type EVC_Radio_Info.Action_T;
   use type EVC_Balise_Groups.Identity_T;

   type Held_T is array (Condition_T) of Boolean;

   Messages      : Natural := 0;
   --  4.8.3 [3]: the RBC acknowledged Train Data in the ongoing session
   --  of the supervising RBC (EVC_Radio.Train_Data_Acknowledged seen)
   TD_Acked      : Boolean := False;
   --  4.8: the messages rejected since Clear
   Rejected_N    : Natural := 0;
   Held          : Held_T := (others => False);
   Stop_Received : Boolean := False;
   Mode_Changes  : Natural := 0;
   Cycles        : Natural := 0;
   --  the MAs by radio accepted since Clear
   Radio_MAs     : Natural := 0;

   --  3.8.2.1.2, 3.8.2.1.4: the MA request parameters of the RBC (packet
   --  57), valid until new ones are received
   type Params_T is record
      Known         : Boolean := False;
      T_MAR         : T_MAR_T := T_MAR_No_MA_Request_Triggering;
      T_TIMEOUTRQST : T_TIMEOUTRQST_T :=
        T_TIMEOUTRQST_No_MA_Request_Triggering;
      T_CYCRQST     : T_CYCRQST_T := T_CYCRQST_No_Repetition;
   end record;
   Params          : Params_T := (others => <>);
   --  the reasons applicable (Q_MARQSTREASON bits), a request due in the
   --  cycle, one sent since Clear and when
   Reasons         : Q_MARQSTREASON_T := 0;
   Request_Due     : Boolean := False;
   Request_Sent    : Boolean := False;
   Last_Request_Ms : EVC_Radio.Time_Ms_T := 0;
   --  3.8.2.3.2 b): an SR authorisation (message 2) received
   SR_Authorised   : Boolean := False;
   Requests        : Natural := 0;
   --  the reasons that persist (3.8.2.3.2, 3.8.2.5.2)
   Start_Reason    : Boolean := False;
   Deleted_Reason  : Boolean := False;

   --  3.8.6: a request to shorten the MA (message 9) taken in the cycle
   --  (Pending), the answer owed (137 or 138) with the T_TRAIN of the
   --  request (8.6.5, 8.6.6) to the session it came from, the answers
   --  given since Clear
   type Answer_T is (None, Granted, Rejected);
   type Shortening_T is record
      Pending  : Boolean := False;
      --  4.8 rejected the request
      Refused  : Boolean := False;
      Answer   : Answer_T := None;
      Session  : EVC_Radio.Session_T := 1;
      Stamp    : T_TRAIN_T := 0;
      Granted  : Natural := 0;
      Rejected : Natural := 0;
   end record;
   Shortening : Shortening_T := (others => <>);

   --  3.10: the emergency stops accepted and not revoked, by NID_EM
   --  (3.10.1.3.1: a new one with the same identifier replaces it); the
   --  NID_EM of the conditional stop of each radio message of the cycle;
   --  an unconditional stop accepted in the cycle ([20]); the
   --  acknowledgements 147 owed (3.10.1.4), with Q_EMERGENCYSTOP
   type Stop_Kind_T is (No_Stop, Conditional, Unconditional);
   type Stops_T is array (NID_EM_T) of Stop_Kind_T;
   type Ack_T is record
      NID     : NID_EM_T := 0;
      Q       : Q_EMERGENCYSTOP_T := 0;
      Session : EVC_Radio.Session_T := 1;
   end record;
   type Slot_EM_T is array (EVC_Radio_Info.Index_T) of Ack_T;
   Max_Acks : constant := 4;
   type Ack_Array_T is array (1 .. Max_Acks) of Ack_T;
   type Emergency_T is record
      Stops      : Stops_T := (others => No_Stop);
      Slot_EM    : Slot_EM_T := (others => (others => <>));
      Uncond_New : Boolean := False;
      Acks       : Ack_Array_T := (others => (others => <>));
      Acks_N     : Natural range 0 .. Max_Acks := 0;
      Acks_Lost  : Natural := 0;
   end record;
   Emergency : Emergency_T := (others => <>);

   --  4.4.11: the SR authorisation of the RBC (message 2): its SR
   --  distance (Given: the RBC's applies; Distance not Active: D_SR
   --  infinite) and its list of expected balise groups (packet 63;
   --  List_Known False: no list, every group may be passed)
   Max_SR_List : constant := 31;
   type SR_List_T is array (1 .. Max_SR_List)
     of EVC_Balise_Groups.Identity_T;
   type SR_Auth_T is record
      Given      : Boolean := False;
      Distance   : EVC_Odometry.Virtual_T := (others => <>);
      List_Known : Boolean := False;
      List_N     : Natural range 0 .. Max_SR_List := 0;
      List       : SR_List_T := (others => (others => <>));
   end record;
   SR_Auth : SR_Auth_T := (others => <>);
   --  4.4.11.1.3 d): the groups passed in the cycle are in the list
   Passed_Listed : Boolean := False;

   --  The mode of the last cycle (EVC_Radio.Context_T.Mode, Evaluate),
   --  and 5.11.2.2 S120: message 6, "Recognition of exit from TRIP mode",
   --  received in PT
   Mode_Now        : Mode_T := M_NP;
   Exit_Recognised : Boolean := False;

   --  5.6 in level 2: the request for shunting (130) and its answer (27,
   --  28): Pending from the driver's selection to the answer or the
   --  last time-out, Due when 130 is to be sent, the time and T_TRAIN of
   --  the last one sent (4.8.4 [14]: the answer names it), the
   --  repetitions (A.3.1: 3, every 15 s), the grant of the cycle, the
   --  list of balise groups for the SH area of the grant (packet 49)
   type SH_List_T is array (1 .. Max_SH_List)
     of EVC_Balise_Groups.Identity_T;
   type SH_Request_T is record
      Pending    : Boolean := False;
      Due        : Boolean := False;
      Sent       : Boolean := False;
      Sent_Ms    : EVC_Radio.Time_Ms_T := 0;
      Stamp      : T_TRAIN_T := 0;
      Repeats    : Natural range 0 .. 3 := 0;
      Granted    : Boolean := False;
      Answer     : Natural range 0 .. 1 := 0;
      Failed     : Boolean := False;
      Count      : Natural := 0;
      List_Known : Boolean := False;
      List_N     : Natural range 0 .. Max_SH_List := 0;
      List       : SH_List_T := (others => (others => <>));
   end record;
   SH_Req    : SH_Request_T := (others => <>);
   SH_Repeat_Ms : constant := 15_000;
   --  the DMI system status message of the cycle (0: none)
   Status_Now : Natural := 0;

   --  5.11.2.2 A035, S120, 4.8.4 [1]: in TR no MA, track description or
   --  mode authorisation of the RBC is taken; in PT only once the exit
   --  from TR is recognised by the RBC (a time stamp later than message
   --  6: EVC_Sessions' order of the time stamps)
   function Authorisation_Allowed return Boolean is
     (Mode_Now /= M_TR and then (Mode_Now /= M_PT or else Exit_Recognised))
     with Global => (Mode_Now, Exit_Recognised);

   --  3.10.2.4: an emergency stop accepted and not revoked
   function Any_Stop return Boolean is
     (for some N in NID_EM_T => Emergency.Stops (N) /= No_Stop)
     with Global => Emergency;

   --  An acknowledgement 147 owed (dropped, counted, when too many are
   --  owed in one cycle: an engineering limit)
   procedure Owe_Ack (A : Ack_T)
     with Global => (In_Out => Emergency)
   is
   begin
      if Emergency.Acks_N < Max_Acks then
         Emergency.Acks_N := Emergency.Acks_N + 1;
         Emergency.Acks (Emergency.Acks_N) := A;
      elsif Emergency.Acks_Lost < Natural'Last then
         Emergency.Acks_Lost := Emergency.Acks_Lost + 1;
      end if;
   end Owe_Ack;

   --  A.3.1 TCYCRQSTD: the repetition cycle without parameters, ms
   Default_Cycle_Ms : constant := 60_000;

   --  Q_MARQSTREASON (7.5.1.118.3) of the reasons
   function Reason_Bits (Start, Perturbation, Timer, Deleted : Boolean)
     return Q_MARQSTREASON_T
   is ((if Start then 1 else 0) + (if Perturbation then 2 else 0)
       + (if Timer then 4 else 0) + (if Deleted then 8 else 0));

   procedure Count (N : in out Natural) is
   begin
      if N < Natural'Last then
         N := N + 1;
      end if;
   end Count;

   function Holds (C : Condition_T) return Boolean is (Held (C))
     with Refined_Global => Held;
   function Unconditional_Stop_Received return Boolean is (Stop_Received)
     with Refined_Global => Stop_Received;
   function Messages_Rejected return Natural is (Rejected_N);

   function Messages_Taken return Natural is (Messages)
     with Refined_Global => Messages;
   function Mode_Changes_Taken return Natural is (Mode_Changes)
     with Refined_Global => Mode_Changes;
   function Cycles_Produced return Natural is (Cycles)
     with Refined_Global => Cycles;
   function Radio_MAs_Accepted return Natural is (Radio_MAs)
     with Refined_Global => Radio_MAs;
   function MA_Request_Reasons return Natural is (Natural (Reasons))
     with Refined_Global => Reasons;
   function MA_Requests_Sent return Natural is (Requests)
     with Refined_Global => Requests;
   function Emergency_Stops return Natural
     with Refined_Global => Emergency
   is
      N : Natural := 0;
   begin
      for I in NID_EM_T loop
         pragma Loop_Invariant (N <= Natural (I));
         if Emergency.Stops (I) /= No_Stop then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Emergency_Stops;
   function RBC_SR_Given return Boolean is (SR_Auth.Given);

   function RBC_SR_Distance return EVC_Odometry.Virtual_T is
     (SR_Auth.Distance);

   function In_SR_List (Id : EVC_Balise_Groups.Identity_T) return Boolean
   is (SR_Auth.List_Known
       and then (for some I in 1 .. SR_Auth.List_N =>
                   SR_Auth.List (I) = Id));

   function Groups_Passed_Listed return Boolean is (Passed_Listed);

   function Trip_Exit_Recognised return Boolean is (Exit_Recognised);

   function SH_Waiting return Boolean is (SH_Req.Pending);
   function SH_Answer return Natural is (SH_Req.Answer);
   function SH_List_Given return Boolean is (SH_Req.List_Known);
   function SH_List_Count return Natural is (SH_Req.List_N);
   function SH_List_Item (I : Positive) return EVC_Balise_Groups.Identity_T
   is (SH_Req.List (I));
   function SH_Request_Failed return Boolean is (SH_Req.Failed);
   function SH_Requests_Sent return Natural is (SH_Req.Count);
   function SH_Request_Stamp return T_TRAIN_T is (SH_Req.Stamp);
   function Status_Entry return Natural is (Status_Now);

   use type EVC_Radio_Acceptance.Verdict_T;

   function To_Buffer return Boolean is
     (Buffer.Judge (EVC_Received.Last_Kind) = EVC_Radio_Acceptance.Stored);

   procedure Store_Message (S : EVC_Radio.Session_T;
                            Data : EVC_Bytes.Byte_Array) is
   begin
      Buffer.Store (S, Data);
   end Store_Message;

   function Buffered return Natural is (Buffer.Buffered);

   function Has_Released return Boolean is (Buffer.Has_Released);

   procedure Take_Released (S    : out EVC_Radio.Session_T;
                            Data : in out EVC_Bytes.Byte_Array;
                            Last : out Natural) is
   begin
      Buffer.Take_Released (S, Data, Last);
   end Take_Released;

   procedure Override_Selected is
   begin
      SR_Auth.Given := False;
      SR_Auth.Distance := (others => <>);
   end Override_Selected;

   function Shortenings_Granted return Natural is (Shortening.Granted)
     with Refined_Global => Shortening;
   function Shortenings_Rejected return Natural is (Shortening.Rejected)
     with Refined_Global => Shortening;

   procedure Clear is
   begin
      Buffer.Clear;
      TD_Acked := False;
      Messages := 0;
      Rejected_N := 0;
      Held := (others => False);
      Stop_Received := False;
      Mode_Changes := 0;
      Cycles := 0;
      Radio_MAs := 0;
      Params := (others => <>);
      Reasons := 0;
      Request_Due := False;
      Request_Sent := False;
      Last_Request_Ms := 0;
      SR_Authorised := False;
      Requests := 0;
      Start_Reason := False;
      Deleted_Reason := False;
      Shortening := (others => <>);
      Emergency := (others => <>);
      SR_Auth := (others => <>);
      Passed_Listed := False;
      Mode_Now := M_NP;
      Exit_Recognised := False;
      SH_Req := (others => <>);
      Status_Now := 0;
      EVC_Radio_Info.Clear;
   end Clear;

   ---------------------------------------------------------------------
   --  The messages received
   ---------------------------------------------------------------------

   --  The fields of the header of the last message received (8.4.4.6.1)
   function LRBG_Of_Last return EVC_Balise_Groups.Identity_T is
     ((NID_C  => NID_C_T (EVC_Received.Last_Value (NID_C) mod 1024),
       NID_BG => NID_BG_T (EVC_Received.Last_Value (NID_BG) mod 16384)))
     with Global => EVC_Received.Store;

   function Stamp_Of_Last return T_TRAIN_T is
     (T_TRAIN_T (EVC_Received.Last_Value (T_TRAIN) mod 2**32))
     with Global => EVC_Received.Store;

   --  D_REF of message 33 (7.5.1.17), with its Q_SCALE: the distance
   --  from the LRBG to the shifted location reference, signed along the
   --  nominal direction of the LRBG; Valid False for a spare Q_SCALE
   procedure Shift_Of_Last (Shift : out Dist_T; Valid : out Boolean)
     with Global => EVC_Received.Store
   is
      Scale : constant Natural :=
        Natural (EVC_Received.Last_Value (Q_SCALE) mod 4);
      Ref   : constant D_REF_T :=
        To_D_REF (EVC_Received.Last_Value (D_REF) mod 65536);
   begin
      Shift := 0;
      Valid := Scale <= 2;
      if Valid then
         Shift := Scaled (Natural (abs Integer (Ref)), Scale);
         if Ref < 0 then
            Shift := -Shift;
         end if;
      end if;
   end Shift_Of_Last;

   --  3.8.5, 3.8.4.2.1 a), 3.8.4.3.1 a), 3.6.2.2.2 c): the MA of message
   --  3 or 33 (Shifted: 33, its location reference shifted by D_REF), to
   --  the stores of E3 through EVC_Radio_Info: referred to the LRBG it
   --  names (an LRBG the on-board does not know leaves no origin, and
   --  the stored information rejects the MA), its timers started at
   --  the time stamp of the message; Action: how the stored information
   --  takes it (Shortening: message 9, 3.8.6)
   procedure Take_Stored_Information (Shifted : Boolean;
                                      Now_Ms  : EVC_Radio.Time_Ms_T;
                                      Action  : EVC_Radio_Info.Action_T :=
                                        EVC_Radio_Info.Packets)
     with Global => (Input  => (EVC_Received.Store, EVC_Position.State,
                                EVC_Odometry.State, Emergency),
                     In_Out => (EVC_Origins.State, EVC_Radio_Info.State))
   is
      Sl    : EVC_Radio_Info.Slot_T;
      Shift : Dist_T := 0;
      Valid : Boolean := True;
   begin
      if Shifted then
         Shift_Of_Last (Shift, Valid);
      end if;
      if Valid then
         EVC_Position.Radio_Origin
           (LRBG_Of_Last, Shifted, Shift, Sl.Origin, Sl.G, Sl.T, Sl.S);
      end if;
      Sl.Start_Ms := EVC_Radio.Time_Of_Stamp (Stamp_Of_Last, Now_Ms);
      Sl.Action := Action;
      --  3.10.2.4: no MA while an emergency stop is not revoked
      Sl.MA_Allowed := not Any_Stop;
      --  3.10.2.2: the stop location of message 15 from the shifted
      --  location reference, for the direction of Q_DIR (one the train
      --  is not running in leaves no origin: rejected, a decision)
      if Action = EVC_Radio_Info.Conditional_Stop then
         Sl.Stop_D := Scaled
           (Natural (EVC_Received.Last_Value (D_EMERGENCYSTOP) mod 32768),
            Natural (EVC_Received.Last_Value (Q_SCALE) mod 4) mod 3);
         if not EVC_Position.Valid_For
                  (Q_DIR_T (EVC_Received.Last_Value (Q_DIR) mod 4),
                   Sl.G, Sl.T)
         then
            Sl.Origin := 0;
         end if;
      end if;
      EVC_Radio_Info.Put_Last (Sl);
   end Take_Stored_Information;

   --  3.8.2.1.2, 3.8.2.1.4: packet 57 of the last message, the new MA
   --  request parameters (taken whatever its Q_DIR: they concern the
   --  train, not a direction)
   procedure Take_Parameters
     with Global => (Input => EVC_Received.Store, In_Out => Params)
   is
      pragma Warnings
        (GNATprove, Off, """R"" is set by ""Decode"" but not used after*",
         Reason => "the reader of one packet is not used after it");
      R  : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
      P  : ETCS_Track_Packets.P57.Packet_T;
      OK : Boolean;
   begin
      for I in 1 .. EVC_Received.Last_Packet_Count loop
         pragma Loop_Invariant (True);
         if EVC_Received.Last_Packet_Kind (I) = ETCS_Catalogue.Track_P57
         then
            EVC_Received.Open_Message_Packet (I, R);
            ETCS_Track_Packets.P57.Decode (R, P, OK);
            if OK then
               Params := (Known         => True,
                          T_MAR         => P.T_MAR,
                          T_TIMEOUTRQST => P.T_TIMEOUTRQST,
                          T_CYCRQST     => P.T_CYCRQST);
            end if;
         end if;
      end loop;
   end Take_Parameters;

   --  4.4.11.1.3 c), 4.4.11.1.6.6: packet 63 of the last message, the
   --  list of expected balise groups in SR (7.4.2.16), replacing the
   --  stored one; an empty list lets no group pass. A group's country is
   --  the one of the item before it, the first the LRBG's of the message
   --  (Q_NEWCOUNTRY 0). Taken whatever its Q_DIR: the groups are those
   --  the train may pass (a decision)
   procedure Take_SR_List
     with Global => (Input => EVC_Received.Store, In_Out => SR_Auth)
   is
      pragma Warnings
        (GNATprove, Off, """R"" is set by ""Decode"" but not used after*",
         Reason => "the reader of one packet is not used after it");
      R  : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
      P  : ETCS_Track_Packets.P63.Packet_T;
      OK : Boolean;
      C  : NID_C_T;
   begin
      for I in 1 .. EVC_Received.Last_Packet_Count loop
         pragma Loop_Invariant (True);
         if EVC_Received.Last_Packet_Kind (I) = ETCS_Catalogue.Track_P63
         then
            EVC_Received.Open_Message_Packet (I, R);
            ETCS_Track_Packets.P63.Decode (R, P, OK);
            if OK then
               C := LRBG_Of_Last.NID_C;
               SR_Auth.List_Known := True;
               SR_Auth.List_N := 0;
               SR_Auth.List := (others => (others => <>));
               for J in 1 .. Natural'Min (Natural (P.N_ITER), Max_SR_List)
               loop
                  pragma Loop_Invariant (SR_Auth.List_N < J);
                  if P.Q_NEWCOUNTRY_List (J).Has_NID_C then
                     C := P.Q_NEWCOUNTRY_List (J).NID_C;
                  end if;
                  SR_Auth.List_N := SR_Auth.List_N + 1;
                  SR_Auth.List (SR_Auth.List_N) :=
                    (NID_C  => C,
                     NID_BG => P.Q_NEWCOUNTRY_List (J).NID_BG);
               end loop;
            end if;
         end if;
      end loop;
   end Take_SR_List;

   --  4.4.11.1.6.2, 4.4.11.1.6.4 b), 4.4.11.1.3.1 b), 4.4.11.1.6.6:
   --  message 2, the SR authorisation. Its SR distance applies (Given),
   --  supervised from its reception along the train orientation
   --  (D_SR_Infinite: no distance); its list of expected balise groups
   --  replaces the stored one, a message without packet 63 deletes it.
   --  A spare Q_SCALE: the message is not taken. That it authorises SR
   --  (3.8.2.3.2 b, the proposal of SR) is SR_Authorised
   procedure Take_SR_Authorisation
     with Global => (Input  => (EVC_Received.Store, EVC_Position.State,
                                EVC_Odometry.State),
                     In_Out => SR_Auth)
   is
      Scale : constant Natural :=
        Natural (EVC_Received.Last_Value (Q_SCALE) mod 4);
      D     : constant D_SR_T :=
        To_D_SR (EVC_Received.Last_Value (D_SR) mod 32768);
   begin
      if Scale <= 2 then
         SR_Auth.Given := True;
         SR_Auth.Distance := (others => <>);
         if D /= D_SR_Infinite then
            SR_Auth.Distance := EVC_Odometry.Start_Virtual
              (Scaled (Natural (D), Scale), EVC_Position.Orientation);
         end if;
         SR_Auth.List_Known := False;
         SR_Auth.List_N := 0;
         Take_SR_List;
      end if;
   end Take_SR_Authorisation;

   --  5.6.2.2 S050, A050: packet 49 of message 28, the list of balise
   --  groups for the SH area (7.4.2.12), its countries as in Take_SR_List
   procedure Take_SH_List
     with Global => (Input => EVC_Received.Store, In_Out => SH_Req)
   is
      pragma Warnings
        (GNATprove, Off, """R"" is set by ""Decode"" but not used after*",
         Reason => "the reader of one packet is not used after it");
      R  : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
      P  : ETCS_Track_Packets.P49.Packet_T;
      OK : Boolean;
      C  : NID_C_T;
   begin
      for I in 1 .. EVC_Received.Last_Packet_Count loop
         pragma Loop_Invariant (True);
         if EVC_Received.Last_Packet_Kind (I) = ETCS_Catalogue.Track_P49
         then
            EVC_Received.Open_Message_Packet (I, R);
            ETCS_Track_Packets.P49.Decode (R, P, OK);
            if OK then
               C := LRBG_Of_Last.NID_C;
               SH_Req.List_Known := True;
               SH_Req.List_N := 0;
               SH_Req.List := (others => (others => <>));
               for J in 1 .. Natural'Min (Natural (P.N_ITER), 31) loop
                  pragma Loop_Invariant (SH_Req.List_N < J);
                  if P.Q_NEWCOUNTRY_List (J).Has_NID_C then
                     C := P.Q_NEWCOUNTRY_List (J).NID_C;
                  end if;
                  SH_Req.List_N := SH_Req.List_N + 1;
                  SH_Req.List (SH_Req.List_N) :=
                    (NID_C  => C,
                     NID_BG => P.Q_NEWCOUNTRY_List (J).NID_BG);
               end loop;
            end if;
         end if;
      end loop;
   end Take_SH_List;

   --  5.6.2.2 S050, E090, E215: message 27 (SH refused) or 28 (SH
   --  authorised) answering the last request for shunting sent (4.8.4
   --  [14]: its second T_TRAIN is the time stamp of that request; any
   --  other answer, or one without a request pending, is not taken).
   --  28: the grant of the cycle ([6], Evaluate) with its list of balise
   --  groups for the SH area (none without packet 49); 27: the driver is
   --  told (A220, DMI system status "SH refused")
   procedure Take_SH_Answer (Granted : Boolean)
     with Global => (Input  => EVC_Received.Store,
                     In_Out => (SH_Req, Status_Now))
   is
   begin
      if SH_Req.Pending and then SH_Req.Sent
        and then EVC_Received.Last_Field (7) = Unsigned_64 (SH_Req.Stamp)
      then
         SH_Req.Pending := False;
         SH_Req.Due := False;
         SH_Req.Granted := Granted;
         SH_Req.Answer := (if Granted then 1 else 0);
         SH_Req.List_Known := False;
         SH_Req.List_N := 0;
         if Granted then
            Take_SH_List;
         else
            Status_Now := EVC_DMI_Port.SS_SH_Refused;
         end if;
      end if;
   end Take_SH_Answer;

   --  3.10: the emergency messages. 15: to EVC_Radio_Info with its stop
   --  location, judged by the stored information of the cycle (3.10.2.2)
   --  and acknowledged in Evaluate; 16: accepted, the train tripped by
   --  [20] (3.10.2.3), acknowledged with Q_EMERGENCYSTOP 2; 18: the stop
   --  of its NID_EM revoked (3.10.3.3: the others stay), acknowledged by
   --  the general acknowledgement of 3.16.3.5 (M_ACK, the session half)
   procedure Take_Emergency (S      : EVC_Radio.Session_T;
                             Kind   : ETCS_Message_Catalogue.Message_Kind_T;
                             Now_Ms : EVC_Radio.Time_Ms_T)
     with Global => (Input  => (EVC_Received.Store, EVC_Position.State,
                                EVC_Odometry.State),
                     In_Out => (Emergency, EVC_Origins.State,
                                EVC_Radio_Info.State))
   is
      NID : constant NID_EM_T :=
        NID_EM_T (EVC_Received.Last_Value (NID_EM) mod 16);
      N   : constant EVC_Radio_Info.Count_T := EVC_Radio_Info.Count;
   begin
      if Kind = ETCS_Message_Catalogue.Track_M15 then
         Take_Stored_Information
           (True, Now_Ms, EVC_Radio_Info.Conditional_Stop);
         if EVC_Radio_Info.Count > N then
            Emergency.Slot_EM (EVC_Radio_Info.Count) :=
              (NID => NID, Q => 0, Session => S);
         end if;
      elsif Kind = ETCS_Message_Catalogue.Track_M16 then
         Emergency.Stops (NID) := Unconditional;
         Emergency.Uncond_New := True;
         Owe_Ack ((NID => NID, Q => 2, Session => S));
      else
         Emergency.Stops (NID) := No_Stop;
      end if;
   end Take_Emergency;

   procedure Take_Message (S      : EVC_Radio.Session_T;
                           Now_Ms : EVC_Radio.Time_Ms_T)
   is
      Kind : constant ETCS_Message_Catalogue.Message_Kind_T :=
        EVC_Received.Last_Kind;
      C    : EVC_Radio_Acceptance.Context_T := Buffer.Context;
   begin
      Count (Messages);
      --  4.8: the context of the last cycle, with what this cycle's
      --  messages changed (the mode, message 6)
      C.Mode := Mode_Now;
      C.Trip_Exit_Known := Exit_Recognised;
      if EVC_Radio_Acceptance.Verdict
           (EVC_Radio_Acceptance.Info_Of (Kind), C)
         /= EVC_Radio_Acceptance.Accepted
      then
         Count (Rejected_N);
         --  3.8.6.1 c): the RBC is informed of a request to shorten the
         --  MA rejected (decision: also when 4.8 rejects it)
         if Kind = ETCS_Message_Catalogue.Track_M9 then
            Shortening.Pending := True;
            Shortening.Refused := True;
            Shortening.Session := S;
            Shortening.Stamp := Stamp_Of_Last;
         end if;
         return;
      end if;
      Take_Parameters;
      if Kind = ETCS_Message_Catalogue.Track_M6 then
         --  5.11.2.2 S120, E125: in PT (4.8.4: rejected in other modes)
         if Mode_Now = M_PT then
            Exit_Recognised := True;
         end if;
      elsif Kind in ETCS_Message_Catalogue.Track_M2
                  | ETCS_Message_Catalogue.Track_M27
                  | ETCS_Message_Catalogue.Track_M28
                  | ETCS_Message_Catalogue.Track_M3
                  | ETCS_Message_Catalogue.Track_M33
                  | ETCS_Message_Catalogue.Track_M9
        and then not Authorisation_Allowed
      then
         null;
      elsif Kind = ETCS_Message_Catalogue.Track_M2 then
         SR_Authorised := True;
         Take_SR_Authorisation;
      elsif Kind in ETCS_Message_Catalogue.Track_M27
                  | ETCS_Message_Catalogue.Track_M28
      then
         Take_SH_Answer (Kind = ETCS_Message_Catalogue.Track_M28);
      elsif Kind = ETCS_Message_Catalogue.Track_M3 then
         Take_Stored_Information (False, Now_Ms);
      elsif Kind = ETCS_Message_Catalogue.Track_M33 then
         Take_Stored_Information (True, Now_Ms);
      elsif Kind = ETCS_Message_Catalogue.Track_M9 then
         --  3.8.6.1 a): the proposed shortened MA, judged in this cycle
         --  (Evaluate); a second request in the cycle replaces the first
         Take_Stored_Information (False, Now_Ms, EVC_Radio_Info.Shortening);
         Shortening.Pending := True;
         Shortening.Session := S;
         Shortening.Stamp := Stamp_Of_Last;
      elsif Kind in ETCS_Message_Catalogue.Track_M15
                  | ETCS_Message_Catalogue.Track_M16
                  | ETCS_Message_Catalogue.Track_M18
      then
         Take_Emergency (S, Kind, Now_Ms);
      end if;
   end Take_Message;

   ---------------------------------------------------------------------
   --  The cycle
   ---------------------------------------------------------------------

   --  The repetition cycle of the MA requests in ms (3.8.2.1.5): the
   --  RBC's T_CYCRQST, A.3.1 TCYCRQSTD without parameters; 0: none
   function Cycle_Ms return EVC_Radio.Time_Ms_T is
     (if not Params.Known then Default_Cycle_Ms
      elsif Params.T_CYCRQST = T_CYCRQST_No_Repetition then 0
      else 1000 * EVC_Radio.Time_Ms_T (Params.T_CYCRQST))
     with Global => Params;

   --  3.8.2 (level 2 only, 3.8.2.1.1): the reasons applicable in the
   --  cycle and whether a request is due. MA_Received: an MA was taken
   --  in the cycle. A reason that becomes applicable sends at once and
   --  restarts the cycle (3.8.2.1.6); while one is applicable the request
   --  is repeated every Cycle_Ms (3.8.2.1.5; new parameters apply at
   --  once, 3.8.2.1.4.1). The track ahead free reason (3.8.2.4) is not
   --  handled yet.
   procedure Evaluate_Request (Now_Ms      : EVC_Radio.Time_Ms_T;
                               Facts       : Facts_T;
                               MA_Received : Boolean)
     with Global => (Input  => (Params, EVC_Levels.State,
                                EVC_Movement_Authority.State,
                                EVC_Stored_Information.State,
                                EVC_Radio.State, TD_Acked, Mode_Now),
                     In_Out => (Reasons, Request_Due, Start_Reason,
                                Deleted_Reason, SR_Authorised))
   is
      L2     : constant Boolean :=
        EVC_Levels.Valid and then EVC_Levels.Level = EVC_Modes.L2;
      --  5.4.3.2 D15, S11: "Start" is offered at S20 (in SB), once the
      --  RBC acknowledged the Train Data (3.18.3.4); before, the driver's
      --  Start waits for it (decision 8 of e5/session-3). Start in
      --  another mode (SR, PT) is not the start of mission
      Acked  : constant Boolean :=
        Mode_Now /= M_SB
        or else EVC_Radio.Train_Data_Acknowledged or else TD_Acked;
      Old    : constant Q_MARQSTREASON_T := Reasons;
      Pert   : Boolean;
      Timer  : Boolean;
      Rising : Boolean;
   begin
      --  3.8.2.3: from Start until an MA, an SR authorisation or the
      --  desk closed; 3.8.2.5: from a deletion until an MA
      if Facts.Start then
         Start_Reason := True;
      end if;
      if MA_Received or else SR_Authorised or else not Facts.Desk_Open then
         Start_Reason := False;
      end if;
      if EVC_Stored_Information.MA_Timer_Deletion then
         Deleted_Reason := True;
      end if;
      if MA_Received then
         Deleted_Reason := False;
      end if;
      SR_Authorised := False;
      --  3.8.2.2: only with the parameters of the RBC (3.8.2.1.3)
      Pert := Params.Known
        and then Params.T_MAR /= T_MAR_No_MA_Request_Triggering
        and then Facts.MA_Request;
      Timer := Params.Known
        and then Params.T_TIMEOUTRQST
                   /= T_TIMEOUTRQST_No_MA_Request_Triggering
        and then EVC_Movement_Authority.Timer_Expiring
                   (Now_Ms, 1000 * Unsigned_64 (Params.T_TIMEOUTRQST));
      if not L2 then
         Start_Reason := False;
         Deleted_Reason := False;
         Reasons := 0;
         Request_Due := False;
         return;
      end if;
      Reasons := Reason_Bits (Start_Reason and then Acked, Pert, Timer,
                              Deleted_Reason);
      Rising := (Start_Reason and then Acked
                 and then (Facts.Start or else Old mod 2 = 0))
        or else (Pert and then Old / 2 mod 2 = 0)
        or else (Timer and then Old / 4 mod 2 = 0)
        or else (Deleted_Reason and then Old / 8 mod 2 = 0);
      Request_Due := Request_Due or else Rising;
   end Evaluate_Request;

   --  3.8.6.1 b), c): the request to shorten the MA taken in the cycle,
   --  judged on the supervision of the cycle: granted when the train
   --  front end is in rear of the Indication supervision limit of the
   --  proposed MA (EVC_SDM, Facts.Proposal_In_Rear): its message stays in
   --  EVC_Radio_Info and the stored information of the next cycle takes
   --  it as the new MA, with its mode profile and list of balise groups
   --  for SH area (3.8.6.2: the deletions of A.3.4 of an MA replacing a
   --  longer one, 3.8.5.1.3); rejected otherwise, and in a level other
   --  than 2 (3.8.6 "Level 2 only"), when nothing changes. Either way
   --  the RBC is answered (3.8.6.1 c, Produce). The other messages of
   --  the cycle were taken by the stored information.
   --  3.10.2.2, 3.10.1.4: the conditional stops of the cycle as the
   --  stored information judged them (EVC_Stored_Information.Stop_Outcome:
   --  accepted with or without a new EOA, or rejected): the accepted
   --  ones stored, each acknowledged with its Q_EMERGENCYSTOP
   procedure Collect_Stops
     with Global => (Input  => (EVC_Radio_Info.State,
                                EVC_Stored_Information.State),
                     In_Out => Emergency)
   is
   begin
      for I in 1 .. EVC_Radio_Info.Count loop
         pragma Loop_Invariant (True);
         if EVC_Radio_Info.Slot (I).Action = EVC_Radio_Info.Conditional_Stop
           and then EVC_Stored_Information.Stop_Outcome (I) <= 3
         then
            declare
               A : Ack_T := Emergency.Slot_EM (I);
            begin
               A.Q := Q_EMERGENCYSTOP_T
                        (EVC_Stored_Information.Stop_Outcome (I));
               if A.Q <= 1 then
                  Emergency.Stops (A.NID) := Conditional;
               end if;
               Owe_Ack (A);
            end;
         end if;
      end loop;
   end Collect_Stops;

   procedure Judge_Shortening (Facts : Facts_T)
     with Global => (Input  => (EVC_Levels.State, Emergency),
                     In_Out => (Shortening, EVC_Radio_Info.State)),
          Post => EVC_Radio_Info.Count <= 1
   is
      Level_2 : constant Boolean :=
        EVC_Levels.Valid and then EVC_Levels.Level = L2;
   begin
      if not Shortening.Pending then
         EVC_Radio_Info.Empty;
      elsif Level_2 and then Facts.Proposal_In_Rear
        and then not Shortening.Refused
        --  3.10.2.4: not while an emergency stop is not revoked
        and then not Any_Stop
      then
         Shortening.Answer := Granted;
         Count (Shortening.Granted);
         EVC_Radio_Info.Keep_Granted;
      else
         Shortening.Answer := Rejected;
         Count (Shortening.Rejected);
         EVC_Radio_Info.Empty;
      end if;
      Shortening.Pending := False;
      Shortening.Refused := False;
   end Judge_Shortening;

   --  4.6.3 [36], 4.4.11.1.3 c): in SR with a list of expected balise
   --  groups of the RBC, a group passed in the cycle that is not in it,
   --  the override not active
   function Group_Not_Listed (Ctx : EVC_Radio.Context_T; Facts : Facts_T)
     return Boolean
     with Global => (SR_Auth, EVC_Position.State)
   is
   begin
      if Ctx.Mode /= M_SR or else not SR_Auth.List_Known
        or else Facts.Override_Active
      then
         return False;
      end if;
      for G in 1 .. EVC_Position.Taken_Count loop
         pragma Loop_Invariant (True);
         if not In_SR_List (EVC_Position.Taken (G).Group.Id) then
            return True;
         end if;
      end loop;
      return False;
   end Group_Not_Listed;

   --  5.6 in level 2: the driver's selection of Shunting at standstill
   --  in FS, LS, AD, OS, SM, SR, UN, PT (after message 6) or SB (5.6.2.2
   --  S0, D020, A045) starts the request (message 130, Produce), sent
   --  once the session of the Supervising RBC is established, at once a
   --  failure without it (a decision); 5.6.4.1.1: no answer within 15 s,
   --  sent again, at most 3 times (A.3.1); 5.6.4.1.2: then the driver is
   --  told ("SH request failed") and the request ends (the termination
   --  of the session is the session half's: SH_Request_Failed). [6]:
   --  the grant of the cycle at standstill in level 2
   procedure Evaluate_SH (Ctx : EVC_Radio.Context_T; Facts : Facts_T;
                          L2  : Boolean)
     with Global => (Input  => (Mode_Now, Exit_Recognised,
                                EVC_Radio.State),
                     In_Out => (SH_Req, Status_Now, Held))
   is
   begin
      Held (C_6) := SH_Req.Granted and then Facts.Standstill and then L2;
      SH_Req.Granted := False;
      if Facts.Shunting_Selected and then L2 and then Facts.Standstill
        and then not SH_Req.Pending
        and then Ctx.Mode in M_FS | M_LS | M_AD | M_OS | M_SM | M_SR
                           | M_UN | M_PT | M_SB
        and then Authorisation_Allowed
      then
         SH_Req.Failed := False;
         SH_Req.Answer := 0;
         if EVC_Radio.In_Communication then
            SH_Req.Pending := True;
            SH_Req.Due := True;
            SH_Req.Sent := False;
            SH_Req.Repeats := 0;
         else
            SH_Req.Failed := True;
            Status_Now := EVC_DMI_Port.SS_SH_Request_Failed;
         end if;
      elsif SH_Req.Pending and then SH_Req.Sent and then not SH_Req.Due
        and then Ctx.Now_Ms - SH_Req.Sent_Ms >= SH_Repeat_Ms
      then
         if SH_Req.Repeats < 3 then
            SH_Req.Repeats := SH_Req.Repeats + 1;
            SH_Req.Due := True;
         else
            SH_Req.Pending := False;
            SH_Req.Failed := True;
            Status_Now := EVC_DMI_Port.SS_SH_Request_Failed;
         end if;
      end if;
   end Evaluate_SH;

   procedure Evaluate (Ctx : EVC_Radio.Context_T; Facts : Facts_T) is
      MA_Received : constant Boolean :=
        EVC_Stored_Information.Radio_MA_Accepted;
      F           : Facts_T := Facts;
   begin
      if MA_Received then
         Count (Radio_MAs);
      end if;
      Mode_Now := Ctx.Mode;
      if Mode_Now /= M_PT then
         Exit_Recognised := False;
      end if;
      --  4.8.3 [3]: "not yet acknowledged any train data in the ongoing
      --  communication session" (Train Data sent again in the session do
      --  not reject; their changed values are not compared, decision)
      --  The ongoing session: one established or being established (an
      --  acknowledgement may come before the session is established, and
      --  the Train Data are sent again when it is, 3.18.3.4.2)
      if not (for some X in EVC_Radio.Session_T =>
                EVC_Radio.Established (X)
                or else EVC_Radio.Being_Established (X))
      then
         TD_Acked := False;
      elsif EVC_Radio.Train_Data_Acknowledged then
         TD_Acked := True;
      end if;
      --  4.8: the context of the messages of the next cycle; 4.8.5.4,
      --  4.8.5.5: the transition buffer deleted or released
      Buffer.Update
        ((Mode               => Mode_Now,
          Level_Valid        => EVC_Levels.Valid,
          Level              => EVC_Levels.Level,
          L2_Announced       => EVC_Levels.Announced
                                and then EVC_Levels.Announced_Level = L2,
          Train_Data_Unacked => Facts.Train_Data_Unacked
                                and then not TD_Acked,
          Trip_Exit_Known    => Exit_Recognised,
          Cab_Active         => Facts.Cab_Active,
          Train_Data_Valid   => Facts.Train_Data_Valid,
          TRN_Valid          => Facts.TRN_Valid));
      --  5.11.2.2 S120, D130, S130, S140 b), S150: in PT, "Start" requests
      --  an MA once the exit from TR is recognised and no emergency stop
      --  is pending
      F.Start := Facts.Start
                 and then (Ctx.Mode /= M_PT
                           or else (Exit_Recognised and then not Any_Stop));
      Evaluate_Request (Ctx.Now_Ms, F, MA_Received);
      --  3.8.2.1.5: the repetition
      if Reasons /= 0 and then Request_Sent and then Cycle_Ms > 0
        and then Ctx.Now_Ms - Last_Request_Ms >= Cycle_Ms
      then
         Request_Due := True;
      end if;
      --  3.13.11.8: T_MAR for the snapshot of the next cycle
      EVC_Radio_Info.Set_T_MAR
        (if Params.Known
           and then Params.T_MAR /= T_MAR_No_MA_Request_Triggering
         then 1000 * Unsigned_64 (Params.T_MAR) else 0);
      Held := (others => False);
      --  4.4.11.1.6.4: the driver's entry is now the last value received
      if Facts.SR_Entered then
         Override_Selected;
      end if;
      Held (C_36) := Group_Not_Listed (Ctx, Facts);
      Evaluate_SH (Ctx, Facts,
                   EVC_Levels.Valid and then EVC_Levels.Level = L2);
      Passed_Listed := SR_Auth.List_Known
        and then EVC_Position.Taken_Count > 0
        and then (for all G in 1 .. EVC_Position.Taken_Count =>
                    In_SR_List (EVC_Position.Taken (G).Group.Id));
      --  [31] (MA+SSP+gradient are on-board) AND (the train position
      --  confidence interval does not overlap any Mode Profile) AND
      --  (ERTMS/ETCS level is 2)
      Held (C_31) := EVC_Stored_Information.MA_On_Board
                     and then not EVC_Stored_Information.Mode_Profile_Overlap
                     and then EVC_Levels.Valid
                     and then EVC_Levels.Level = L2;
      --  3.10: the emergency stops; [20] an unconditional stop accepted in
      --  the cycle (3.10.2.3), [45] one not revoked
      Collect_Stops;
      Held (C_20) := Emergency.Uncond_New;
      Emergency.Uncond_New := False;
      Stop_Received :=
        (for some N in NID_EM_T => Emergency.Stops (N) = Unconditional);
      --  the messages of the cycle were taken by the stored information
      Judge_Shortening (Facts);
   end Evaluate;

   --  4.10 (the rows of the emergency stops): entering NP, SB, PS, SH,
   --  SR, SL, NL, UN, SN or RV deletes them; SM, FS, AD, LS, OS, TR and
   --  PT keep them (so [45] holds back the exit from Trip until the
   --  revocation). The end of a session deletes none: no clause asks it.
   --  4.4.11.1.6.2: SR entered from SB or PT (the SR authorisation of
   --  5.4, 5.11 acknowledged) keeps the SR distance and the list of the
   --  RBC; any other change of mode deletes them (4.10: a decision for
   --  the authorisation received in SB or PT and not used)
   procedure Mode_Changed (From, To : Mode_T) is
   begin
      Count (Mode_Changes);
      Mode_Now := To;
      --  5.11.2.2 S120: the recognition is that of the PT entered
      if To /= M_PT then
         Exit_Recognised := False;
      end if;
      if not (To = M_SR and then From in M_SB | M_PT) then
         SR_Auth := (others => <>);
      end if;
      if To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL | M_NL | M_UN
             | M_SN | M_RV
      then
         Emergency.Stops := (others => No_Stop);
         Stop_Received := False;
      end if;
   end Mode_Changed;

   --  A train to track message of Kind with the variables V (3 ..: its
   --  T_TRAIN and NID_ENGINE, the ETCS identity of the configuration,
   --  8.4.4.7.1, are set here) and packet 0, the position
   --  report of EVC_Position (3.6.5.1.2; the session half builds its own
   --  for message 136: to be unified at integration), sent in the
   --  session S; OK False when it could not be built
   procedure Send_With_Report (S      : EVC_Radio.Session_T;
                               Kind   : ETCS_Message_Catalogue
                                          .Known_Message_T;
                               V      : ETCS_Message.Value_Array;
                               Ctx    : EVC_Radio.Context_T;
                               OK     : out Boolean)
     with Global => (In_Out => (EVC_Radio.State, EVC_Radio.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State))
   is
      W      : ETCS_Bits.Writer (128);
      Values : ETCS_Message.Value_Array := V;
   begin
      Values (3) := Unsigned_64 (EVC_Radio.T_Train_At (Ctx.Now_Ms));
      Values (4) := Unsigned_64 (EVC_Radio.Engine_Id);
      ETCS_Bits.Clear (W);
      ETCS_Message.Write_Fields (W, Kind, Values, OK);
      if OK then
         ETCS_Train_Packets.P0.Encode
           (EVC_Position.Position_Report (Ctx.Mode, EVC_Levels.Level),
            W, OK);
      end if;
      if OK then
         ETCS_Message.Finish (W, OK);
      end if;
      if OK then
         declare
            D : constant EVC_Bytes.Byte_Array := ETCS_Bits.Data (W);
         begin
            OK := EVC_Ports.Valid_RTM (D);
            if OK then
               EVC_Radio.Send (S, D);
            end if;
         end;
      end if;
   end Send_With_Report;

   --  3.8.6.1 c): the answer to the request to shorten the MA, 137
   --  granted or 138 rejected with the time stamp of the request (8.6.5,
   --  8.6.6), to the session it came from; kept while the outbox has no
   --  room, dropped when the session is no longer established
   procedure Answer_Shortening (Ctx : EVC_Radio.Context_T)
     with Global => (In_Out => (Shortening, EVC_Radio.State,
                                EVC_Radio.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State))
   is
      OK : Boolean := True;
      V  : ETCS_Message.Value_Array := (others => 0);
   begin
      if Shortening.Answer /= None
        and then EVC_Radio.Established (Shortening.Session)
      then
         V (5) := Unsigned_64 (Shortening.Stamp);
         Send_With_Report
           (Shortening.Session,
            (if Shortening.Answer = Granted
             then ETCS_Message_Catalogue.Train_M137
             else ETCS_Message_Catalogue.Train_M138),
            V, Ctx, OK);
      end if;
      if OK then
         Shortening.Answer := None;
      end if;
   end Answer_Shortening;

   --  3.10.1.4: the acknowledgements 147 owed (8.6.8: NID_EM,
   --  Q_EMERGENCYSTOP), each to the session of its message; kept while
   --  the outbox has no room, dropped when the session is no longer
   --  established
   procedure Acknowledge_Stops (Ctx : EVC_Radio.Context_T)
     with Global => (In_Out => (Emergency, EVC_Radio.State,
                                EVC_Radio.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State))
   is
      Kept : Ack_Array_T := (others => (others => <>));
      N    : Natural range 0 .. Max_Acks := 0;
      OK   : Boolean;
      V    : ETCS_Message.Value_Array := (others => 0);
   begin
      for I in 1 .. Emergency.Acks_N loop
         pragma Loop_Invariant (N < I);
         declare
            A : constant Ack_T := Emergency.Acks (I);
         begin
            if EVC_Radio.Established (A.Session) then
               V (5) := Unsigned_64 (A.NID);
               V (6) := Unsigned_64 (A.Q);
               Send_With_Report (A.Session,
                                 ETCS_Message_Catalogue.Train_M147,
                                 V, Ctx, OK);
               if not OK then
                  N := N + 1;
                  Kept (N) := A;
               end if;
            end if;
         end;
      end loop;
      Emergency.Acks := Kept;
      Emergency.Acks_N := N;
   end Acknowledge_Stops;

   procedure Produce (Ctx : EVC_Radio.Context_T) is
      OK : Boolean;
      V  : ETCS_Message.Value_Array := (others => 0);
   begin
      Count (Cycles);
      --  3.8.2: message 132 with the reasons (3.8.2.1.7) to the
      --  Supervising RBC, once the session is established
      if Request_Due and then Reasons /= 0
        and then EVC_Radio.In_Communication
      then
         V (5) := Unsigned_64 (Reasons);
         Send_With_Report
           (EVC_Radio.Session_T (EVC_Radio.Supervising),
            ETCS_Message_Catalogue.Train_M132, V, Ctx, OK);
         if OK then
            Request_Due := False;
            Request_Sent := True;
            Last_Request_Ms := Ctx.Now_Ms;
            Count (Requests);
         end if;
      end if;
      Answer_Shortening (Ctx);
      Acknowledge_Stops (Ctx);
      --  5.6.2.2 A045: message 130 with the position report (8.6.12)
      if SH_Req.Due and then EVC_Radio.In_Communication then
         V := (others => 0);
         Send_With_Report
           (EVC_Radio.Session_T (EVC_Radio.Supervising),
            ETCS_Message_Catalogue.Train_M130, V, Ctx, OK);
         if OK then
            SH_Req.Due := False;
            SH_Req.Sent := True;
            SH_Req.Sent_Ms := Ctx.Now_Ms;
            SH_Req.Stamp := EVC_Radio.T_Train_At (Ctx.Now_Ms);
            Count (SH_Req.Count);
         end if;
      end if;
      --  the system status message of the cycle was sent (EVC_Core)
      Status_Now := 0;
   end Produce;

end EVC_Radio_Authority;
