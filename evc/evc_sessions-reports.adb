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
with EVC_Balise_Groups;
with EVC_Bytes;
with EVC_Ports;
with Interfaces;             use Interfaces;
with ETCS_Variables;         use ETCS_Variables;

package body EVC_Sessions.Reports
  with SPARK_Mode => On,
       Refined_State => (State => (P58, P58_Ref, P58_Held, Due,
                                   Was_Up, Last_Level,
                                   Level_Seen, N_Sent, N_Params))
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
      if P58_Held then
         EVC_Position.Set_Report_Parameters (P58, P58_Ref, OK);
         if OK then
            Bump (N_Params);
         end if;
         P58_Held := False;
      end if;
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
      if To not in EVC_Modes.M_NP | EVC_Modes.M_PS | EVC_Modes.M_SF
                 | EVC_Modes.M_IS
        and then not (From = EVC_Modes.M_PS and then To = EVC_Modes.M_SH)
      then
         Due := True;
      end if;
   end Mode_Changed;

   --  8.6.6: message 136 with packet 0, or packet 1 when the LRBG is a
   --  single group without co-ordinate system (3.6.5.1.2 i, 3.4.2.3.3)
   subtype Writer_T is ETCS_Bits.Writer (64);

   procedure Send_136 (S : R.Session_T; Ctx : R.Context_T)
     with Global => (In_Out => (R.State, R.Queue, N_Sent),
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
      ETCS_Message.Write_Fields (W, Train_M136, V, OK);
      if OK then
         if EVC_Position.Report_Kind = EVC_Position.Report_P1 then
            ETCS_Train_Packets.P1.Encode
              (EVC_Position.Position_Report_2 (Ctx.Mode, EVC_Levels.Level),
               W, OK);
         else
            ETCS_Train_Packets.P0.Encode
              (EVC_Position.Position_Report (Ctx.Mode, EVC_Levels.Level),
               W, OK);
         end if;
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
               Bump (N_Sent);
            end if;
         end;
      end if;
   end Send_136;

   --  3.6.5.1.4 (decision 3): to the supervising RBC, its session
   --  established and its connection up
   procedure Produce (Ctx : EVC_Radio.Context_T) is
      Sv : constant R.Session_Ref_T := R.Supervising;
   begin
      if Due and then Sv /= R.No_Session
        and then R.Info (R.Session_T (Sv)).State = R.Established
      then
         Send_136 (R.Session_T (Sv), Ctx);
      end if;
      Due := False;
   end Produce;

   procedure Request
     with Refined_Global => (Output => Due)
   is
   begin
      Due := True;
   end Request;

end EVC_Sessions.Reports;
