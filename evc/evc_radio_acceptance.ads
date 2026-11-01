--  ETCS on-board (EVC)
--  The authority by radio half: the acceptance of the
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
--    4.8.3 [17] rejected while a Safe consist length information for
--      SM (message 133) sent is not acknowledged
--      (Context.Consist_Unacked): the SM authorisation here, the
--      packets of a general message by Consist_Rejected.
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

with ETCS_Catalogue;
with ETCS_Message_Catalogue;
with EVC_Modes; use EVC_Modes;

--  @req 4.8.3.1.1 Table, 4.8.4.2 Table
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
      TAF_Request,          -- 34
      SM_Authorisation,     -- 4
      SM_Refused,           -- 5
      Coordinate_Assignment, -- 45
      --  packet 45 of a message (not a message kind,
      --  so not in Info_Of: EVC_Sessions.Network filters it)
      Network_Order);

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
          when ETCS_Message_Catalogue.Track_M4  => SM_Authorisation,
          when ETCS_Message_Catalogue.Track_M5  => SM_Refused,
          when ETCS_Message_Catalogue.Track_M45 => Coordinate_Assignment,
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
      --  4.8.3 [17]: message 133 sent and not acknowledged (message 7)
      Consist_Unacked    : Boolean := False;
      --  4.8.4 [1], [2], [4], [11]
      Trip_Exit_Known    : Boolean := False;
      Cab_Active         : Boolean := False;
      Train_Data_Valid   : Boolean := False;
      TRN_Valid          : Boolean := False;
   end record;

   type Verdict_T is (Accepted, Rejected, Stored);

   --  4.8.3, the rows "From RBC: Yes": level 2 accepts, with [3] for the
   --  authorisations; the other levels reject, or store [2]
   --  @req 4.8.3.1.1 Table, 4.8.3.1.1 Table-footnote [2]
   --  @req 4.8.3.1.1 Table-footnote [3], 5.10.1.8
   --  The rows "Movement authority (SM Authorisation)" (A [4] [5] [17]:
   --  [4] the stored information's 3.7.2.3, [5] the emergency stops of
   --  EVC_Radio_Authority, [17] no message 133 is sent) and "SM refused"
   --  (A): level 2 accepts, without [3]; the SM authorisation rejected
   --  while a message 133 sent is not acknowledged ([17])
   --  @req 4.8.3.1.1 Table-footnote [17]
   function First_Filter (I : Info_T; C : Context_T) return Verdict_T
   is (if I = Other then Accepted
       --  the row "Radio Network transition order": A in every level
       elsif I = Network_Order then Accepted
       --  the row "Assignment of Co-ordinate system": A [10] in every
       --  level, the exception of [10] applied by
       --  EVC_Position.Assign_Coordinate_System (3.4.2.3.3.8)
       elsif I = Coordinate_Assignment then Accepted
       elsif C.Level_Valid and then C.Level = L2 then
         (if I in Movement_Authority | SR_Authorisation | Shorten_MA
                | SH_Refused | SH_Authorised | TAF_Request
             and then C.Train_Data_Unacked
          then Rejected                                           -- [3]
          elsif I = SM_Authorisation and then C.Consist_Unacked
          then Rejected                                           -- [17]
          else Accepted)
       elsif I in Movement_Authority | Conditional_Stop | Unconditional_Stop
         and then C.L2_Announced
       then Stored                                                -- [2]
       else Rejected);

   --  4.8.3, From RBC: Yes, the rows R [2] in levels 0, NTC and 1 and
   --  A in level 2 whose packets a general message brings to the stored
   --  information (EVC_Stored_Information.Take_Radio): National Values
   --  (3), the gradient (21), the SSP (27), the track conditions (39,
   --  40, 68, 69), the big metal masses (67), the axle load speed
   --  profile (51), the permitted braking distance (52), the TSR and its
   --  revocation (65, 66), Route Suitability Data (70), the Adhesion
   --  Factor (71), Level Crossing information (88). Not here: the rows
   --  A in every level (41, 46, 42, 45, 57, 58), the packets taken by
   --  their own units (5, 72, 76, 79) and the LSSMA toggle (180, held
   --  for level 2 by the stored information)
   function Level_2_Row (P : ETCS_Catalogue.Packet_Kind_T) return Boolean
   is (P in ETCS_Catalogue.Track_P3 | ETCS_Catalogue.Track_P21
          | ETCS_Catalogue.Track_P27 | ETCS_Catalogue.Track_P39
          | ETCS_Catalogue.Track_P40 | ETCS_Catalogue.Track_P51
          | ETCS_Catalogue.Track_P52 | ETCS_Catalogue.Track_P65
          | ETCS_Catalogue.Track_P66 | ETCS_Catalogue.Track_P67
          | ETCS_Catalogue.Track_P68 | ETCS_Catalogue.Track_P69
          | ETCS_Catalogue.Track_P70 | ETCS_Catalogue.Track_P71
          | ETCS_Catalogue.Track_P88);

   --  4.8.3, the first filter of a packet of a radio message by its row
   --  (Level_2_Row): accepted in level 2; outside it Stored [2] when
   --  level 2 is announced or a level transition order is in the same
   --  message (4.8.1.3.1, step 1: as if announced), else Rejected.
   --  The other packets: Accepted (their rows, or their own filters)
   --  @req 4.8.3.1.1 Table, 4.8.3.1.1 Table-footnote [2]
   function Packet_Filter (P                : ETCS_Catalogue.Packet_Kind_T;
                           Level_Valid      : Boolean;
                           Level            : Level_T;
                           L2_Announced     : Boolean;
                           Order_In_Message : Boolean) return Verdict_T
   is (if not Level_2_Row (P) then Accepted
       elsif Level_Valid and then Level = L2 then Accepted
       elsif L2_Announced or else Order_In_Message then Stored
       else Rejected);

   --  4.8.3, the rows "Axle Load speed profile" and "Permitted Braking
   --  Distance Information", From RBC: Yes (packets 51 and 52 of a
   --  message 24): A [3] in level 2; R [2] in the other levels, kept in
   --  the transition buffer when level 2 is announced. The mode column
   --  of 4.8.4 is the stores' (EVC_Stored_Information)
   --  @req 4.8.3.1.1 Table, 4.8.3.1.1 Table-footnote [2]
   function Level_2_Track_Filter (C : Context_T) return Verdict_T
   is (if C.Level_Valid and then C.Level = L2 then
         (if C.Train_Data_Unacked then Rejected else Accepted)   -- [3]
       elsif C.L2_Announced then Stored                         -- [2]
       else Rejected);

   --  4.8.3, the rows whose level 2 cell (From RBC: Yes) carries [17],
   --  by their packets: Linking (5), Gradient Profile (21), International
   --  SSP (27), Axle Load speed profile (51), Temporary Speed Restriction
   --  (65) and its Revocation (66), Route Suitability Data (70), RBC
   --  Transition Order (131), Track Conditions excluding big metal
   --  masses (39, 40, 68, 69), Track condition big metal masses (67),
   --  Level Crossing information (88); the twelfth, the SM
   --  authorisation, is a message (First_Filter)
   function Consist_Row (P : ETCS_Catalogue.Packet_Kind_T) return Boolean
   is (P in ETCS_Catalogue.Track_P5 | ETCS_Catalogue.Track_P21
          | ETCS_Catalogue.Track_P27 | ETCS_Catalogue.Track_P51
          | ETCS_Catalogue.Track_P65 | ETCS_Catalogue.Track_P66
          | ETCS_Catalogue.Track_P70 | ETCS_Catalogue.Track_P131
          | ETCS_Catalogue.Track_P39 | ETCS_Catalogue.Track_P40
          | ETCS_Catalogue.Track_P68 | ETCS_Catalogue.Track_P69
          | ETCS_Catalogue.Track_P67 | ETCS_Catalogue.Track_P88);

   --  4.8.3 [17] "rejected if a Safe consist length information for SM
   --  message has been sent to the RBC and the corresponding
   --  acknowledgment has not been received yet in the ongoing mission",
   --  for packet P of a general message on a row of Consist_Row
   --  @req 4.8.3.1.1 Table-footnote [17]
   function Consist_Rejected (P : ETCS_Catalogue.Packet_Kind_T;
                              C : Context_T) return Boolean
   is (C.Consist_Unacked and then Consist_Row (P));

   --  4.8.4 [1], the rows A [1] of PT: "for level 2: only if following
   --  the reception of the information "Recognition of Exit from TR
   --  mode" with a more recent time stamp; for level 1: rejected"
   --  (message 6: Trip_Exit_Known, its time stamp judged by EVC_Sessions)
   --  decision: a context whose level is not valid cannot satisfy "for
   --  level 2" and is rejected (every caller passes the level of
   --  EVC_Levels)
   --  @req 4.8.4.2 Table-footnote [1]
   function In_PT (C : Context_T) return Boolean is
     (C.Trip_Exit_Known and then C.Level_Valid and then C.Level = L2);

   --  4.8.4, the third filter in the mode of C
   --  @req 4.8.4.2 Table
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
          --  4.8.4, the rows "SM Authorisation" and "SM refused": [2] in
          --  SB; A in SM; [14] in FS, AD, LS, SR, OS and with [1] in PT
          --  (the time stamp: EVC_Sessions); R in the other modes
          when SM_Authorisation | SM_Refused =>
             (case C.Mode is
                 when M_SB => C.Cab_Active,                 -- [2]
                 when M_SM | M_FS | M_AD | M_LS | M_SR | M_OS => True,
                 when M_PT => In_PT (C),                    -- [1]
                 when others => False),
          when TAF_Request =>
             (case C.Mode is
                 when M_SB => C.Cab_Active,                 -- [2]
                 when M_LS | M_SR | M_OS => True,
                 when M_PT => In_PT (C),
                 when others => False),
          --  4.8.4, the row "Assignment of Co-ordinate system": [2] in
          --  SB; A in SM, SR, NL, UN, SN; [1] in PT; R or NR elsewhere
          when Coordinate_Assignment =>
             (case C.Mode is
                 when M_SB => C.Cab_Active,                 -- [2]
                 when M_SM | M_SR | M_NL | M_UN | M_SN => True,
                 when M_PT => In_PT (C),                    -- [1]
                 when others => False),
          --  4.8.4, the row "Radio Network transition order": NR in NP,
          --  SF, IS; [2] in SB; [1] in PT; [13] (in an SM authorisation,
          --  message 4: not taken by this on-board)
          when Network_Order =>
             (case C.Mode is
                 when M_NP | M_SF | M_IS => False,
                 when M_SB => C.Cab_Active,                 -- [2]
                 when M_PT => In_PT (C),                    -- [1]
                 when others => True));

   --  4.8: both filters; information stored in the transition buffer is
   --  judged again when the level changes (4.8.5.5)
   function Verdict (I : Info_T; C : Context_T) return Verdict_T is
     (case First_Filter (I, C) is
         when Accepted =>
            (if Third_Filter (I, C) then Accepted else Rejected),
         when Rejected => Rejected,
         when Stored   => Stored);

end EVC_Radio_Acceptance;
