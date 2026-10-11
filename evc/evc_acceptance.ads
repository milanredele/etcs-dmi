--  ETCS on-board (EVC)
--  The acceptance of the information received from balise groups,
--  SUBSET-026 4.8: the first filter of Figure 3 by the level and the
--  origin (4.8.3, the rows "From RBC: No, non-infill") and the third
--  filter by the mode (4.8.4), as tables. The second filter (RBC
--  messages) is phase E5; the infill information (3.9, the infill
--  location reference) is not taken by this on-board (E7), so every
--  balise information is non-infill here.
--
--  The information of a group message is evaluated in the order of
--  EVC_Stored_Information (the level transition orders first, 4.8.1.3);
--  each kind is accepted when both filters accept it in the Context of
--  that moment. The exceptions of the tables:
--    4.8.3 [1] "stored on-board if an order to switch to level 1 at a
--      further location has been received" (e5/balise-buffer): Stored
--      (Level_Stores) is the third verdict of the first filter, in
--      levels 0, NTC and 2 with Context.L1_Announced, by the rows and
--      columns that carry [1]. EVC_Stored_Information keeps the packets
--      so judged in the transition buffer of 4.8.5 (its child
--      Balise_Buffer) and judges them again at the transition to level
--      1. Level_Accepts and Accepted still accept these cases: the
--      units that take a [1] packet themselves and keep no buffer take
--      it at once, as before (the linking, packet 5, in EVC_Position;
--      the reversing packets 138 and 139 in EVC_Procedures; backlog
--      B070); the stores ask Stored first.
--    4.8.3 [2] (level 2 at a further location): RBC information, E5.
--    4.8.3 [4] the SSP and gradient cover the MA: 3.7.2.3 in
--      EVC_Stored_Information.
--    4.8.3 [11] (conditional order): Context.Order_In_Message,
--      Context.Order_Pending.
--    4.8.3 [16] (level 2, unlinked group): Context.Unlinked_Group.
--    4.8.4 [1] in PT: level 1 rejected, level 2 the RBC's (E5).
--    4.8.4 [2] a cab is active, [4] valid Train Data, [11] a valid train
--      running number (this on-board takes no train running number from
--      a balise group, 4.8.3: none is sent by balise).
--    4.8.4 [7] in SH, PS, SM only the immediate and conditional orders,
--      stored for later (EVC_Levels).
--    4.8.4 [13], [14]: SM authorisations, E5.
--  A level that is not valid (unknown, or invalid: 5.4.3.2 D2) is no
--  level of the tables: only what every level accepts is accepted.
--  The procedures (EVC_Procedures, EVC_Text_Messages, e4/integration)
--  filter the information they take with the same tables: the rows
--  "Danger for SH information", "Stop Shunting on desk opening", "Stop
--  if in SR mode", "Reversing Area Information", "Reversing Supervision
--  Information", "Plain / Fixed Text Information". 4.8.3 [13] (danger
--  for SH in level 0 or NTC, rejected unless it comes with an immediate
--  transition order to level 1 or 2) is not applied: the order is
--  accepted, on the safe side.

with EVC_Modes; use EVC_Modes;

package EVC_Acceptance
  with SPARK_Mode => On, Pure
is

   --  The kinds of information of the tables that this on-board takes
   --  from balise groups (the packets in brackets)
   type Info_T is
     (National_Values,        -- 3
      Linking,                -- 5
      Signalling_Speed,       -- 12 (V_MAIN)
      Movement_Authority,     -- 12, with the mode profile 80
      Gradient_Profile,       -- 21
      International_SSP,      -- 27
      Axle_Load_Profile,      -- 51
      Level_Order,            -- 41
      Conditional_Order,      -- 46
      TSR,                    -- 65
      TSR_Revocation,         -- 66
      Default_Gradient,       -- 141
      Route_Suitability,      -- 70
      Adhesion,               -- 71
      Geographical_Position,  -- 79
      Track_Conditions,       -- 68, 39 (excluding big metal masses)
      Big_Metal_Masses,       -- 67
      Braking_Distance,       -- 52
      Level_Crossing,         -- 88
      --  e5/trips-fs: 3.8.5.2.2
      Repositioning,          -- 16
      --  the procedures (e4/integration)
      Danger_For_SH,          -- 132
      Stop_SH_On_Desk,        -- 135
      Stop_If_In_SR,          -- 137
      Reversing_Area,         -- 138
      Reversing_Supervision,  -- 139
      Text_Message,           -- 72, 76 (73, 74 of 7.4.2)
      --  phase E5 (e5/session): from a balise group
      Session_Management,     -- 42
      --  e5/handover: from a balise group
      RBC_Transition_Order,   -- 131
      --  e5/registration-2: from a balise group
      Network_Order,          -- 45
      --  e4/ls-display, 4.4.19.1.4 (the toggle off order of packet 180
      --  is narrowed to LS by EVC_Stored_Information, 4.8.4)
      Generic_LS_Marker,      -- 181
      LSSMA_Toggle);          -- 180

   type Context_T is record
      Mode             : Mode_T := M_SB;
      --  the level of the on-board, when its status is valid
      Level_Valid      : Boolean := False;
      Level            : Level_T := L0;
      Cab_Active       : Boolean := False;
      Train_Data_Valid : Boolean := False;
      TRN_Valid        : Boolean := False;
      --  4.8.3 [1]: an order to switch to level 1 at a further location
      --  was received and is not executed yet
      L1_Announced     : Boolean := False;
      --  4.8.3 [11]: a level transition order is in the same message;
      --  a previous order announced a transition still to be executed
      Order_In_Message : Boolean := False;
      Order_Pending    : Boolean := False;
      --  4.8.3 [16]: the group is marked as unlinked
      Unlinked_Group   : Boolean := False;
   end record;

   --  4.8.3: the first filter in the level L
   function Level_Accepts (I : Info_T; L : Level_T; C : Context_T)
     return Boolean
   is (case I is
          when National_Values | Big_Metal_Masses => True,
          when Linking | Signalling_Speed | Movement_Authority
             | Gradient_Profile | International_SSP | Axle_Load_Profile
             | Route_Suitability | Track_Conditions | Braking_Distance =>
             L = L1 or else C.L1_Announced,
          --  rejected in level 2 without the exception [1]
          when Adhesion =>
             L = L1 or else (L /= L2 and then C.L1_Announced),
          when Level_Order =>
             not (L = L2 and then C.Unlinked_Group),
          when Conditional_Order =>
             not C.Order_In_Message and then not C.Order_Pending
             and then not (L = L2 and then C.Unlinked_Group),
          when TSR | TSR_Revocation | Default_Gradient
             | Geographical_Position | Text_Message =>
             L /= NTC or else C.L1_Announced,
          when Level_Crossing =>
             L in L1 | L2 or else C.L1_Announced,
          --  R R A R, no exception (e5/trips-fs)
          when Repositioning => L = L1,
          --  R R A A: no exception [1] (e5/balise-buffer)
          when Stop_If_In_SR => L in L1 | L2,
          when Danger_For_SH | Stop_SH_On_Desk => True,
          --  every level; the exceptions [14] [15] of the table are
          --  phase 2 of e5/session
          when Session_Management => True,
          --  4.8.3: level 2 only ([15], the radio network, not modelled)
          when RBC_Transition_Order => L = L2,
          --  4.8.3: the Radio Network transition order in every level
          when Network_Order => True,
          --  4.8.3 (e4/ls-display): the marker in every level, the
          --  toggle orders from balises in level 1 ([1])
          when Generic_LS_Marker => True,
          when LSSMA_Toggle => L = L1 or else C.L1_Announced,
          when Reversing_Area | Reversing_Supervision =>
             L = L1 or else C.L1_Announced);

   --  4.8.3 for the on-board: in its level when valid, else in every
   --  level
   function First_Filter (I : Info_T; C : Context_T) return Boolean is
     (if C.Level_Valid then Level_Accepts (I, C.Level, C)
      else (for all L in Level_T => Level_Accepts (I, L, C)));

   --  4.8.4: the third filter in the mode of C
   function Third_Filter (I : Info_T; C : Context_T) return Boolean
   is (case C.Mode is
          when M_NP | M_SF | M_IS => False,    -- NR
          when M_SB =>
             C.Cab_Active                                       -- [2]
             and then
             (case I is
                 when National_Values | Level_Order | Conditional_Order
                    | Geographical_Position | Text_Message
                    | Session_Management | Network_Order
                    | Generic_LS_Marker => True,
                 when Movement_Authority =>
                    C.Train_Data_Valid and then C.TRN_Valid,     -- [4][11]
                 when Danger_For_SH | Stop_SH_On_Desk | Stop_If_In_SR
                    | LSSMA_Toggle | Repositioning =>
                    False,
                 when others => C.Train_Data_Valid),             -- [4]
          when M_PS =>
             I in National_Values | Level_Order | Conditional_Order
                | Big_Metal_Masses | Stop_SH_On_Desk
                | Session_Management | RBC_Transition_Order      -- [7] [8]
                | Network_Order | Generic_LS_Marker,
          when M_SH =>
             I in National_Values | Level_Order | Conditional_Order
                | Big_Metal_Masses | Danger_For_SH
                | Session_Management | RBC_Transition_Order      -- [7] [8]
                | Network_Order | Generic_LS_Marker,
          when M_SM =>
             I not in Signalling_Speed | Movement_Authority
                    | Route_Suitability | Braking_Distance
                    | Danger_For_SH | Stop_SH_On_Desk | Stop_If_In_SR
                    | Reversing_Area | Reversing_Supervision
                    | LSSMA_Toggle | Repositioning,
          when M_FS | M_AD | M_LS | M_OS | M_UN | M_SN =>
             I not in Danger_For_SH | Stop_SH_On_Desk | Stop_If_In_SR
             and then not (C.Mode in M_UN | M_SN
                           and then I in RBC_Transition_Order
                                       | Repositioning),
          when M_SR =>
             I not in Danger_For_SH | Stop_SH_On_Desk | Repositioning,
          when M_SL =>
             I in National_Values | Level_Order | Conditional_Order
                | Big_Metal_Masses | Session_Management
                | RBC_Transition_Order | Network_Order
                | Generic_LS_Marker,
          when M_NL =>
             I in National_Values | Linking | Level_Order
                | Conditional_Order | Geographical_Position
                | Track_Conditions | Big_Metal_Masses
                | Session_Management | RBC_Transition_Order
                | Network_Order | Generic_LS_Marker,
          when M_TR =>
             I in National_Values | Level_Order | Conditional_Order
                | TSR | TSR_Revocation | Default_Gradient
                | Geographical_Position | Track_Conditions
                | Big_Metal_Masses | Text_Message | Session_Management
                | RBC_Transition_Order | Network_Order
                | Generic_LS_Marker,
          --  [1]: every information of these tables is marked [1] in PT,
          --  rejected in level 1 (in level 2 the RBC's, phase E5)
          when M_PT => False,
          when M_RV =>
             I in National_Values | Reversing_Area | Reversing_Supervision
                | Text_Message | Session_Management | Network_Order
                | Generic_LS_Marker);

   function Accepted (I : Info_T; C : Context_T) return Boolean is
     (First_Filter (I, C) and then Third_Filter (I, C));

   --  e5/balise-buffer: 4.8.3 [1] "stored onboard if an order to switch
   --  to level 1 at a further location has been received", in the level
   --  L (0, NTC or 2), by the rows and columns that carry it (Adhesion
   --  and Level Crossing not in level 2: R and A there; TSR, its
   --  revocation, the default gradient, packet 79 and the texts only in
   --  NTC). Every case is one Level_Accepts accepts (the exception taken
   --  at once by the units that keep no buffer, see the header).
   function Level_Stores (I : Info_T; L : Level_T; C : Context_T)
     return Boolean
   is (C.L1_Announced and then L /= L1
       and then
       (case I is
           when Linking | Signalling_Speed | Movement_Authority
              | Gradient_Profile | International_SSP | Axle_Load_Profile
              | Route_Suitability | Track_Conditions | Braking_Distance
              | Reversing_Area | Reversing_Supervision => True,
           --  e4/ls-display-2 (B091): the LSSMA toggle on order, R [1] in
           --  levels 0, NTC and 2 (the off order, R there, is kept with it
           --  as one packet 180 and rejected at the release)
           when LSSMA_Toggle => True,
           when Adhesion | Level_Crossing => L /= L2,
           when TSR | TSR_Revocation | Default_Gradient
              | Geographical_Position | Text_Message => L = NTC,
           when others => False));

   --  4.8.3, 4.8.5.1: the first filter's third verdict, "stored in the
   --  transition buffer" (the third filter applies when the set is
   --  released, 4.8.5.6 b)
   function Stored (I : Info_T; C : Context_T) return Boolean is
     (C.Level_Valid and then Level_Stores (I, C.Level, C));

   --  Phase E5 (e5/radio-geo-buffer): the packet 79 of a radio message.
   --  4.8.3, the row "Geographical Position, From RBC: Yes": A in level
   --  2; R [2] in levels 0, NTC and 1, stored (4.8.5) when an order to
   --  switch to level 2 at a further location has been received
   --  (L2_Announced). 4.8.4.2: the mode column of the row, the same for
   --  both origins (Third_Filter); decision: in PT ([1], level 2 after
   --  the recognition of the exit from TR) rejected, as for a group.
   type Radio_Verdict_T is (Radio_Rejected, Radio_Accepted, Radio_Stored);

   --  e5/balise-buffer (B060), 4.8.5.4 c): without an established
   --  session (Session_Up False) rejected, so that the packet kept for
   --  the transition is deleted with the session that gave it (decision:
   --  the on-board keeps one packet 79, from the only RBC it talks to
   --  before the transition; no message arrives without a session)
   function Radio_Geo_Verdict (C            : Context_T;
                               L2_Announced : Boolean;
                               Session_Up   : Boolean := True)
     return Radio_Verdict_T
   is (if not Session_Up then Radio_Rejected
       elsif C.Level_Valid and then C.Level = L2 then
         (if Third_Filter (Geographical_Position, C) then Radio_Accepted
          else Radio_Rejected)
       elsif L2_Announced then Radio_Stored
       else Radio_Rejected);

end EVC_Acceptance;
