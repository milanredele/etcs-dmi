--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half: the acceptance of the
--  information received from the RBC, SUBSET-026 4.8, as tables (the
--  balise information is EVC_Acceptance's). The first filter of Figure
--  3 by the level (4.8.3, the rows "From RBC: Yes") and the third filter
--  by the mode (4.8.4), for the messages this on-board takes by radio
--  (EVC_Radio_Authority.Take_Message). The second filter (the
--  supervising RBC, 4.8.2.1 c) is the session half's (handover).
--
--  The context of the tables and the transition buffer of 4.8.5 are
--  the state of EVC_Radio_Authority (its private child Buffer).
--
--  The exceptions of the tables:
--    4.8.3 [2] "stored on-board if an order to switch to level 2 at a
--      further location has been received": verdict Stored, the
--      transition buffer of 4.8.5 (EVC_Radio_Authority).
--    4.8.3 [3] rejected while Train Data sent to the RBC are not
--      acknowledged (Context.Train_Data_Unacked).
--    4.8.3 [4] (the SSP and gradient cover the MA): 3.7.2.3 in
--      EVC_Stored_Information; [5] (emergency stops not revoked):
--      3.10.2.4 in EVC_Radio_Authority.
--    4.8.4 [1] level 2 in PT: only after the recognition of the exit
--      from TR (message 6; the order of the time stamps is the session
--      half's, 3.16.3).
--    4.8.4 [2] a cab is active, [4] valid Train Data, [11] a valid train
--      running number stored (one received in the same message is not:
--      the messages of the RBC taken here carry no packet 5).
--    4.8.4 [14] the time stamp of the request (messages 27 and 28):
--      EVC_Radio_Authority (SH_Request_Stamp).
--  A level that is not valid is no level of the tables: what level 2
--  alone accepts is rejected.

with ETCS_Message_Catalogue;
with EVC_Modes; use EVC_Modes;

package EVC_Radio_Acceptance
  with SPARK_Mode => On
is

   --  The kinds of information of the tables in the messages the
   --  on-board takes by radio (the messages in brackets); Other: not
   --  filtered here (the session messages, the general message 24 whose
   --  packets the tables filter one by one where they are used)
   type Info_T is
     (Other,
      Movement_Authority,   -- 3, 33
      SR_Authorisation,     -- 2
      Trip_Exit,            -- 6, recognition of exit from TR mode
      Shorten_MA,           -- 9
      Conditional_Stop,     -- 15
      Unconditional_Stop,   -- 16
      Stop_Revocation,      -- 18
      SH_Refused,           -- 27
      SH_Authorised,        -- 28
      TAF_Request);         -- 34

   function Info_Of (K : ETCS_Message_Catalogue.Message_Kind_T)
     return Info_T
   is (case K is
          when ETCS_Message_Catalogue.Track_M3
             | ETCS_Message_Catalogue.Track_M33 => Movement_Authority,
          when ETCS_Message_Catalogue.Track_M2  => SR_Authorisation,
          when ETCS_Message_Catalogue.Track_M6  => Trip_Exit,
          when ETCS_Message_Catalogue.Track_M9  => Shorten_MA,
          when ETCS_Message_Catalogue.Track_M15 => Conditional_Stop,
          when ETCS_Message_Catalogue.Track_M16 => Unconditional_Stop,
          when ETCS_Message_Catalogue.Track_M18 => Stop_Revocation,
          when ETCS_Message_Catalogue.Track_M27 => SH_Refused,
          when ETCS_Message_Catalogue.Track_M28 => SH_Authorised,
          when ETCS_Message_Catalogue.Track_M34 => TAF_Request,
          when others => Other);

   type Context_T is record
      Mode               : Mode_T := M_NP;
      --  the level of the on-board, when its status is valid
      Level_Valid        : Boolean := False;
      Level              : Level_T := L0;
      --  4.8.3 [2]: an order to switch to level 2 at a further location
      L2_Announced       : Boolean := False;
      --  4.8.3 [3]
      Train_Data_Unacked : Boolean := False;
      --  4.8.4 [1], [2], [4], [11]
      Trip_Exit_Known    : Boolean := False;
      Cab_Active         : Boolean := False;
      Train_Data_Valid   : Boolean := False;
      TRN_Valid          : Boolean := False;
   end record;

   type Verdict_T is (Accepted, Rejected, Stored);

   --  4.8.3, the rows "From RBC: Yes": level 2 accepts, with [3] for the
   --  authorisations; the other levels reject, or store [2]
   function First_Filter (I : Info_T; C : Context_T) return Verdict_T
   is (if I = Other then Accepted
       elsif C.Level_Valid and then C.Level = L2 then
         (if I in Movement_Authority | SR_Authorisation | Shorten_MA
                | SH_Refused | SH_Authorised | TAF_Request
             and then C.Train_Data_Unacked
          then Rejected                                           -- [3]
          else Accepted)
       elsif I in Movement_Authority | Conditional_Stop | Unconditional_Stop
         and then C.L2_Announced
       then Stored                                                -- [2]
       else Rejected);

   --  4.8.4 [1]: level 2 in PT, after message 6
   function In_PT (C : Context_T) return Boolean is
     (C.Trip_Exit_Known);

   --  4.8.4, the third filter in the mode of C
   function Third_Filter (I : Info_T; C : Context_T) return Boolean
   is (case I is
          when Other => True,
          when Movement_Authority =>
             (case C.Mode is
                 when M_SB =>
                    C.Cab_Active and then C.Train_Data_Valid
                    and then C.TRN_Valid,                   -- [2][4][11]
                 when M_FS | M_AD | M_LS | M_SR | M_OS | M_UN | M_SN =>
                    True,
                 when M_PT => In_PT (C) and then C.Train_Data_Valid,
                 when others => False),
          when SR_Authorisation =>
             (case C.Mode is
                 when M_SB =>
                    C.Cab_Active and then C.Train_Data_Valid
                    and then C.TRN_Valid,                   -- [2][4][11]
                 when M_SR => True,
                 when M_PT => In_PT (C) and then C.Train_Data_Valid,
                 when others => False),
          when Trip_Exit => C.Mode = M_PT,
          when Shorten_MA => C.Mode in M_FS | M_AD | M_LS | M_OS,
          when Unconditional_Stop =>
             (case C.Mode is
                 when M_SB => C.Cab_Active,                 -- [2]
                 when M_SM | M_FS | M_AD | M_LS | M_SR | M_OS | M_UN
                    | M_SN => True,
                 when others => False),
          when Conditional_Stop =>
             C.Mode in M_SM | M_FS | M_AD | M_LS | M_OS | M_UN | M_SN,
          when Stop_Revocation =>
             C.Mode in M_SM | M_FS | M_AD | M_LS | M_OS
             or else (C.Mode = M_PT and then In_PT (C)),
          when SH_Refused | SH_Authorised =>
             (case C.Mode is
                 when M_SB => C.Cab_Active,                 -- [2]
                 when M_SM | M_FS | M_AD | M_LS | M_SR | M_OS => True,
                 when M_PT => In_PT (C),
                 when others => False),
          when TAF_Request =>
             (case C.Mode is
                 when M_SB => C.Cab_Active,                 -- [2]
                 when M_LS | M_SR | M_OS => True,
                 when M_PT => In_PT (C),
                 when others => False));

   --  4.8: both filters; information stored in the transition buffer is
   --  judged again when the level changes (4.8.5.5)
   function Verdict (I : Info_T; C : Context_T) return Verdict_T is
     (case First_Filter (I, C) is
         when Accepted =>
            (if Third_Filter (I, C) then Accepted else Rejected),
         when Rejected => Rejected,
         when Stored   => Stored);

end EVC_Radio_Acceptance;
