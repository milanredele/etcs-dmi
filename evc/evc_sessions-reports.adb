--  ETCS on-board (EVC)
--  Phase E5, session and link, phase 3: the position reports of 3.6.5
--  (see the specification).

with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Message;
with ETCS_Message_Catalogue; use ETCS_Message_Catalogue;
with ETCS_Track_Packets.P58;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P1;
with ETCS_Train_Packets.P4;
with EVC_Balise_Groups;
with EVC_Bytes;
with EVC_Ports;
with Interfaces;             use Interfaces;
with ETCS_Variables;         use ETCS_Variables;

package body EVC_Sessions.Reports
  with SPARK_Mode => On,
       Refined_State => (State => (P58, P58_Ref, P58_Held, Due,
                                   Was_Up, Last_Level,
                                   Level_Seen, N_Sent, N_Params,
                                   Error_Due, Error_Code))
is
   package R renames EVC_Radio;
   use type R.Session_Ref_T;
   use type R.Session_State_T;
   use type ETCS_Catalogue.Packet_Kind_T;
   use type EVC_Position.Report_Kind_T;

   --  The packet 58 of the last message that had one, its LRBG
   P58        : ETCS_Track_Packets.P58.Packet_T;
   P58_Ref    : EVC_Balise_Groups.Identity_T :=
     EVC_Balise_Groups.Unknown_Identity;
   P58_Held   : Boolean := False;
   --  A report to send at the end of the cycle
   Due        : Boolean := False;
   --  h): the supervising RBC's session was established
   Was_Up     : Boolean := False;
   --  g): the level of the last cycle
   Last_Level : EVC_Modes.Level_T := EVC_Modes.L0;
   Level_Seen : Boolean := False;
   N_Sent     : Natural := 0;
   N_Params   : Natural := 0;
   --  per session, the inconsistent messages still to
   --  report (3.16.3.1.1.2), one message 136 each, one per cycle, and
   --  the M_ERROR of the last (decisions: one packet 4 per message, the
   --  codes of the ones before the last not kept, at most 8 pending)
   Max_Errors : constant := 8;
   type Error_Count_T is range 0 .. Max_Errors;
   Error_Due  : array (R.Session_T) of Error_Count_T := (others => 0);
   Error_Code : array (R.Session_T) of M_ERROR_T := (others => 0);

   function Reports_Sent return Natural is (N_Sent)
     with Refined_Global => N_Sent;
   function Parameters_Taken return Natural is (N_Params)
     with Refined_Global => N_Params;

   procedure Bump (N : in out Natural) is
   begin
      if N < Natural'Last then
         N := N + 1;
      end if;
   end Bump;

   procedure Clear is
   begin
      P58 := (others => <>);
      P58_Ref := EVC_Balise_Groups.Unknown_Identity;
      P58_Held := False;
      Due := False;
      Was_Up := False;
      Last_Level := EVC_Modes.L0;
      Level_Seen := False;
      N_Sent := 0;
      N_Params := 0;
      Error_Due := (others => 0);
      Error_Code := (others => 0);
   end Clear;

   --  3.6.5.1.5, 3.6.5.1.7 (decision 4): the last packet 58 of the
   --  message, referred to its LRBG (8.4.2.1)
   procedure Take_Message is
      pragma Warnings
        (GNATprove, Off, """Rd"" is set by ""Decode"" but not used after*",
         Reason => "the reader of one packet is not used after it");
      Rd : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
      P  : ETCS_Track_Packets.P58.Packet_T;
      OK : Boolean;
   begin
      for I in 1 .. EVC_Received.Last_Packet_Count loop
         pragma Loop_Invariant (True);
         if EVC_Received.Last_Packet_Kind (I) = ETCS_Catalogue.Track_P58
         then
            EVC_Received.Open_Message_Packet (I, Rd);
            ETCS_Track_Packets.P58.Decode (Rd, P, OK);
            if OK and then ETCS_Track_Packets.P58.Valid (P) then
               P58 := P;
               P58_Ref :=
                 (NID_C  => NID_C_T (EVC_Received.Last_Value (NID_C)
                                     mod 1024),
                  NID_BG => NID_BG_T (EVC_Received.Last_Value (NID_BG)
                                      mod 16384));
               P58_Held := True;
            end if;
         end if;
      end loop;
   end Take_Message;

   --  4.5.2, "Report Train Position" (PDF page 43 of chapter 4): the
   --  modes in which an event is reported. No row has NP or PS; SF and
   --  IS are "not relevant" and report nothing here.
   subtype Mode_T is EVC_Modes.Mode_T;
   --  a), i): the train reaches or leaves standstill
   function Standstill_Reported (M : Mode_T) return Boolean is
     (M in EVC_Modes.M_SB | EVC_Modes.M_SM | EVC_Modes.M_FS
         | EVC_Modes.M_AD | EVC_Modes.M_LS | EVC_Modes.M_SR
         | EVC_Modes.M_OS | EVC_Modes.M_RV);
   --  g): a change of level (the rows of the trackside order and of the
   --  driver's request together)
   function Level_Reported (M : Mode_T) return Boolean is
     (M in EVC_Modes.M_SB | EVC_Modes.M_FS | EVC_Modes.M_AD
         | EVC_Modes.M_LS | EVC_Modes.M_SR | EVC_Modes.M_OS
         | EVC_Modes.M_SL | EVC_Modes.M_NL | EVC_Modes.M_TR);
   --  h): a session established with the RBC
   function Session_Reported (M : Mode_T) return Boolean is
     (M not in EVC_Modes.M_NP | EVC_Modes.M_PS | EVC_Modes.M_SF
             | EVC_Modes.M_IS);
   --  "As requested by RBC" (3.6.5.1.5) and j)
   function Requested_Reported (M : Mode_T) return Boolean is
     (M not in EVC_Modes.M_NP | EVC_Modes.M_PS | EVC_Modes.M_SH
             | EVC_Modes.M_SF | EVC_Modes.M_IS);

   --  4.8.4, "Position Report parameters": the
   --  modes that accept them from the RBC (rejected in PS, SH, SL and
   --  TR; NP, SF and IS not relevant). The notes [1], [2], [13] of the
   --  row concern the message's filters of 4.8.2 and 4.8.3, applied
   --  before (EVC_Radio_Acceptance)
   function Parameters_Accepted (M : Mode_T) return Boolean is
     (M not in EVC_Modes.M_NP | EVC_Modes.M_PS | EVC_Modes.M_SH
             | EVC_Modes.M_SL | EVC_Modes.M_TR | EVC_Modes.M_SF
             | EVC_Modes.M_IS);

   --  3.6.5.1.4, 3.6.5.1.5, 4.9.1.3
   procedure Evaluate (SoM : Boolean; Mode : EVC_Modes.Mode_T) is
      T     : constant EVC_Position.Triggers_T :=
        EVC_Position.Report_Triggers;
      Level : constant EVC_Modes.Level_T := EVC_Levels.Level;
      Up    : constant Boolean := R.In_Communication;
      OK    : Boolean;
   begin
      --  4.9.1.3: entering level 1 deletes the parameters
      if Level_Seen and then Level /= Last_Level
        and then Level = EVC_Modes.L1
      then
         EVC_Position.Delete_Report_Parameters;
      end if;
      --  4.8.4: taken in the mode of the cycle that received them
      --  (SUBSET-076 4080428_01: given in SH, not applied in the SB of
      --  the next session, step 134)
      if P58_Held and then Parameters_Accepted (Mode) then
         EVC_Position.Set_Report_Parameters (P58, P58_Ref, OK);
         if OK then
            Bump (N_Params);
         end if;
      end if;
      P58_Held := False;
      --  a), g), h), i), j); 3.6.5.1.5 a) to e)
      if ((T.Standstill_Reached or else T.Standstill_Left)
          and then Standstill_Reported (Mode))
        or else ((T.LRBG_Passed or else T.Periodic_Time
                  or else T.Periodic_Distance or else T.Location_Passed
                  or else T.Immediate)
                 and then Requested_Reported (Mode))
        or else (Level_Seen and then Level /= Last_Level
                 and then Level_Reported (Mode))
        or else (Up and then not Was_Up and then not SoM
                 and then Session_Reported (Mode))
      then
         Due := True;
      end if;
      Last_Level := Level;
      Level_Seen := True;
      Was_Up := Up;
   end Evaluate;

   --  3.6.5.1.4 b)
   procedure Mode_Changed (From, To : EVC_Modes.Mode_T) is
   begin
      if Mode_Reported (From, To) then
         Due := True;
      end if;
   end Mode_Changed;

   --  8.6.6: message 136 with packet 0, or packet 1 when the LRBG is a
   --  single group without co-ordinate system (3.6.5.1.2 i, 3.4.2.3.3)
   subtype Writer_T is ETCS_Bits.Writer (64);

   --  with packet 4 (7.4.3.4) when Error, M_ERROR Code; Text: message
   --  158 instead (8.6.16), NID_TEXTMESSAGE Text_Id, the same position
   --  report, not counted as a position report
   procedure Send_136 (S       : R.Session_T;
                       Ctx     : R.Context_T;
                       Error   : Boolean;
                       Code    : M_ERROR_T;
                       Text    : Boolean := False;
                       Text_Id : Natural := 0)
     with Global => (In_Out => (R.State, R.Queue, N_Sent,
                                Integrity.State),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State))
   is
      pragma Warnings
        (GNATprove, Off, """W"" is set by ""*"" but not used after*",
         Reason => "the writer of one message is not used after it");
      V  : ETCS_Message.Value_Array := (others => 0);
      W  : Writer_T;
      OK : Boolean;
   begin
      ETCS_Bits.Clear (W);
      V (3) := Unsigned_64 (R.T_Train_At (Ctx.Now_Ms));
      V (4) := Unsigned_64 (R.Engine_Id);
      V (5) := Unsigned_64 (Text_Id mod 256);
      ETCS_Message.Write_Fields
        (W, (if Text then Train_M158 else Train_M136), V, OK);
      if OK then
         if EVC_Position.Report_Kind = EVC_Position.Report_P1 then
            declare
               P : ETCS_Train_Packets.P1.Packet_T :=
                 EVC_Position.Position_Report_2 (Ctx.Mode, EVC_Levels.Level);
            begin
               P.Q_INTEGRITY := Q_INTEGRITY_T (Integrity.Q_Integrity);
               P.Has_L_TRAININT := P.Q_INTEGRITY in 1 | 2;
               P.L_TRAININT := (if P.Has_L_TRAININT
                                then L_TRAININT_T (Integrity.Confirmed_Length)
                                else 0);
               ETCS_Train_Packets.P1.Encode (P, W, OK);
            end;
         else
            declare
               P : ETCS_Train_Packets.P0.Packet_T :=
                 EVC_Position.Position_Report (Ctx.Mode, EVC_Levels.Level);
            begin
               P.Q_INTEGRITY := Q_INTEGRITY_T (Integrity.Q_Integrity);
               P.Has_L_TRAININT := P.Q_INTEGRITY in 1 | 2;
               P.L_TRAININT := (if P.Has_L_TRAININT
                                then L_TRAININT_T (Integrity.Confirmed_Length)
                                else 0);
               ETCS_Train_Packets.P0.Encode (P, W, OK);
            end;
         end if;
      end if;
      if OK and then Error then
         ETCS_Train_Packets.P4.Encode ((M_ERROR => Code, others => <>),
                                       W, OK);
      end if;
      if OK then
         ETCS_Message.Finish (W, OK);
      end if;
      if OK then
         declare
            M : constant EVC_Bytes.Byte_Array := ETCS_Bits.Data (W);
         begin
            if EVC_Ports.Valid_RTM (M) then
               R.Send (S, M);
               if not Text then
                  Bump (N_Sent);
               end if;
               --  3.6.5.2.5 Table 2c [5]
               Integrity.Reported;
            end if;
         end;
      end if;
   end Send_136;

   --  3.6.5.1.4 (decision 3): to the supervising RBC, its session
   --  established and its connection up; 3.15.1.3.4, 3.15.1.3.9: to the
   --  other RBC of a handover likewise; 3.16.3.1.1.2, 3.16.4.1: to a
   --  session with an inconsistent message to report, packet 4 added, as
   --  soon as the session is established (the report waits otherwise)
   procedure Produce (Ctx    : EVC_Radio.Context_T;
                      Also   : Targets_T := No_Targets;
                      Forced : Targets_T := No_Targets)
   is
      Sv : constant R.Session_Ref_T := R.Supervising;
   begin
      for S in R.Session_T loop
         pragma Loop_Invariant (True);
         if ((Due and then (Sv = R.Session_Ref_T (S) or else Also (S)))
             or else Forced (S) or else Error_Due (S) > 0)
           and then R.Info (S).State = R.Established
         then
            Send_136 (S, Ctx, Error_Due (S) > 0, Error_Code (S));
            if Error_Due (S) > 0 then
               Error_Due (S) := Error_Due (S) - 1;
            end if;
         end if;
      end loop;
      Due := False;
   end Produce;

   procedure Produce_Text_Acks (Ctx : EVC_Radio.Context_T) is
   begin
      for I in 1 .. EVC_Text_Messages.Ack_Report_Count loop
         pragma Loop_Invariant (True);
         declare
            A : constant EVC_Text_Messages.Ack_Report_T :=
              EVC_Text_Messages.Ack_Report (I);
         begin
            for S in R.Session_T loop
               pragma Loop_Invariant (True);
               if R.Info (S).State = R.Established
                 and then R.Info (S).RBC.NID_C = NID_C_T (A.NID_C)
                 and then R.Info (S).RBC.NID_RBC = NID_RBC_T (A.NID_RBC)
                 and then EVC_System_Version.Major (R.Info (S).Version) >= 2
               then
                  Send_136 (S, Ctx, False, 0, Text => True, Text_Id => A.Id);
               end if;
            end loop;
         end;
      end loop;
   end Produce_Text_Acks;

   procedure Request
     with Refined_Global => (Output => Due)
   is
   begin
      Due := True;
   end Request;

   procedure Request_Error (S     : EVC_Radio.Session_T;
                            Error : ETCS_Variables.M_ERROR_T)
     with Refined_Global => (In_Out => (Error_Due, Error_Code))
   is
   begin
      if Error_Due (S) < Max_Errors then
         Error_Due (S) := Error_Due (S) + 1;
      end if;
      Error_Code (S) := Error;
   end Request_Error;

end EVC_Sessions.Reports;
