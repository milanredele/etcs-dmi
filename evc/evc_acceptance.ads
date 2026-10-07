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
--      further location has been received": the transition buffer of
--      4.8.5 is not kept; such information is accepted at once
--      (Context.L1_Announced). The modes of the levels where it applies
--      (0, NTC: UN, SN, SR; 2 is phase E5) do not use the information
--      of level 1 (4.5.2, EVC_Modes), and the transition to level 1
--      makes it used (4.6.3 [25]): a partial 4.8.5, its note in the
--      matrix.
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
      Network_Order);         -- 45

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
          when Level_Crossing | Stop_If_In_SR =>
             L in L1 | L2 or else C.L1_Announced,
          when Danger_For_SH | Stop_SH_On_Desk => True,
          --  every level; the exceptions [14] [15] of the table are
          --  phase 2 of e5/session
          when Session_Management => True,
          --  4.8.3: level 2 only ([15], the radio network, not modelled)
          when RBC_Transition_Order => L = L2,
          --  4.8.3: the Radio Network transition order in every level
          when Network_Order => True,
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
                    | Session_Management | Network_Order => True,
                 when Movement_Authority =>
                    C.Train_Data_Valid and then C.TRN_Valid,     -- [4][11]
                 when Danger_For_SH | Stop_SH_On_Desk | Stop_If_In_SR =>
                    False,
                 when others => C.Train_Data_Valid),             -- [4]
          when M_PS =>
             I in National_Values | Level_Order | Conditional_Order
                | Big_Metal_Masses | Stop_SH_On_Desk
                | Session_Management | RBC_Transition_Order      -- [7] [8]
                | Network_Order,
          when M_SH =>
             I in National_Values | Level_Order | Conditional_Order
                | Big_Metal_Masses | Danger_For_SH
                | Session_Management | RBC_Transition_Order      -- [7] [8]
                | Network_Order,
          when M_SM =>
             I not in Signalling_Speed | Movement_Authority
                    | Route_Suitability | Braking_Distance
                    | Danger_For_SH | Stop_SH_On_Desk | Stop_If_In_SR
                    | Reversing_Area | Reversing_Supervision,
          when M_FS | M_AD | M_LS | M_OS | M_UN | M_SN =>
             I not in Danger_For_SH | Stop_SH_On_Desk | Stop_If_In_SR
             and then not (C.Mode in M_UN | M_SN
                           and then I = RBC_Transition_Order),
          when M_SR =>
             I not in Danger_For_SH | Stop_SH_On_Desk,
          when M_SL =>
             I in National_Values | Level_Order | Conditional_Order
                | Big_Metal_Masses | Session_Management
                | RBC_Transition_Order | Network_Order,
          when M_NL =>
             I in National_Values | Linking | Level_Order
                | Conditional_Order | Geographical_Position
                | Track_Conditions | Big_Metal_Masses
                | Session_Management | RBC_Transition_Order
                | Network_Order,
          when M_TR =>
             I in National_Values | Level_Order | Conditional_Order
                | TSR | TSR_Revocation | Default_Gradient
                | Geographical_Position | Track_Conditions
                | Big_Metal_Masses | Text_Message | Session_Management
                | RBC_Transition_Order | Network_Order,
          --  [1]: every information of these tables is marked [1] in PT,
          --  rejected in level 1 (in level 2 the RBC's, phase E5)
          when M_PT => False,
          when M_RV =>
             I in National_Values | Reversing_Area | Reversing_Supervision
                | Text_Message | Session_Management | Network_Order);

   function Accepted (I : Info_T; C : Context_T) return Boolean is
     (First_Filter (I, C) and then Third_Filter (I, C));

end EVC_Acceptance;
