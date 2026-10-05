--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half (see the specification).

with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P57;
with ETCS_Train_Packets.P0;
with ETCS_Variables;          use ETCS_Variables;
with EVC_Bytes;
with EVC_Ports;
with EVC_Balise_Groups;
with EVC_Distances;           use EVC_Distances;
with Interfaces;              use Interfaces;

package body EVC_Radio_Authority
  with SPARK_Mode => On,
       Refined_State => (State => (Messages, Held, Stop_Received,
                                   Mode_Changes, Cycles, Radio_MAs,
                                   Params, Reasons, Request_Due,
                                   Request_Sent, Last_Request_Ms,
                                   SR_Authorised, Requests, Start_Reason,
                                   Deleted_Reason, Shortening))
is

   use type ETCS_Message_Catalogue.Message_Kind_T;
   use type ETCS_Catalogue.Packet_Kind_T;

   type Held_T is array (Condition_T) of Boolean;

   Messages      : Natural := 0;
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
      Answer   : Answer_T := None;
      Session  : EVC_Radio.Session_T := 1;
      Stamp    : T_TRAIN_T := 0;
      Granted  : Natural := 0;
      Rejected : Natural := 0;
   end record;
   Shortening : Shortening_T := (others => <>);

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
   function Shortenings_Granted return Natural is (Shortening.Granted)
     with Refined_Global => Shortening;
   function Shortenings_Rejected return Natural is (Shortening.Rejected)
     with Refined_Global => Shortening;

   procedure Clear is
   begin
      Messages := 0;
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
                                EVC_Odometry.State),
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

   procedure Take_Message (S      : EVC_Radio.Session_T;
                           Now_Ms : EVC_Radio.Time_Ms_T)
   is
      Kind : constant ETCS_Message_Catalogue.Message_Kind_T :=
        EVC_Received.Last_Kind;
   begin
      Count (Messages);
      Take_Parameters;
      if Kind = ETCS_Message_Catalogue.Track_M2 then
         SR_Authorised := True;
      end if;
      if Kind = ETCS_Message_Catalogue.Track_M3 then
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
                                EVC_Stored_Information.State),
                     In_Out => (Reasons, Request_Due, Start_Reason,
                                Deleted_Reason, SR_Authorised))
   is
      L2     : constant Boolean :=
        EVC_Levels.Valid and then EVC_Levels.Level = EVC_Modes.L2;
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
      Reasons := Reason_Bits (Start_Reason, Pert, Timer, Deleted_Reason);
      Rising := Facts.Start
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
   procedure Judge_Shortening (Facts : Facts_T)
     with Global => (Input  => EVC_Levels.State,
                     In_Out => (Shortening, EVC_Radio_Info.State)),
          Post => EVC_Radio_Info.Count <= 1
   is
      Level_2 : constant Boolean :=
        EVC_Levels.Valid and then EVC_Levels.Level = L2;
   begin
      if not Shortening.Pending then
         EVC_Radio_Info.Empty;
      elsif Level_2 and then Facts.Proposal_In_Rear then
         Shortening.Answer := Granted;
         Count (Shortening.Granted);
         EVC_Radio_Info.Keep_Granted;
      else
         Shortening.Answer := Rejected;
         Count (Shortening.Rejected);
         EVC_Radio_Info.Empty;
      end if;
      Shortening.Pending := False;
   end Judge_Shortening;

   procedure Evaluate (Ctx : EVC_Radio.Context_T; Facts : Facts_T) is
      MA_Received : constant Boolean :=
        EVC_Stored_Information.Radio_MA_Accepted;
   begin
      if MA_Received then
         Count (Radio_MAs);
      end if;
      Evaluate_Request (Ctx.Now_Ms, Facts, MA_Received);
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
      --  [31] (MA+SSP+gradient are on-board) AND (the train position
      --  confidence interval does not overlap any Mode Profile) AND
      --  (ERTMS/ETCS level is 2)
      Held (C_31) := EVC_Stored_Information.MA_On_Board
                     and then not EVC_Stored_Information.Mode_Profile_Overlap
                     and then EVC_Levels.Valid
                     and then EVC_Levels.Level = L2;
      --  the messages of the cycle were taken by the stored information
      Judge_Shortening (Facts);
   end Evaluate;

   procedure Mode_Changed (From, To : Mode_T) is
      pragma Unreferenced (From, To);
   begin
      Count (Mode_Changes);
   end Mode_Changed;

   --  The identity of the on-board, NID_ENGINE of the train to track
   --  messages (8.4.4.7.1): not configured yet, 0 (a decision of phase
   --  E5 phase 1, to be taken from the configuration at integration)
   Engine_Id : constant := 0;

   --  A train to track message of Kind with the variables V (3 ..: its
   --  T_TRAIN and NID_ENGINE are set here) and packet 0, the position
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
      Values (4) := Engine_Id;
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
   end Produce;

end EVC_Radio_Authority;
