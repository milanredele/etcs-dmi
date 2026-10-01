--  ETCS on-board (EVC)
--  Modes, levels and the transitions table of SUBSET-026 chapter 4.
--
--  The transitions table of 4.6.2 is data here: for every pair of modes
--  the priority of the transition from the first to the second, 0 where
--  4.6.2 has no transition (the shaded cells of Figure 2). The mode
--  machine of EVC_Core only takes a transition that this table has, and
--  gnatprove shows it (EVC_Core.Tick).
--
--  The modes carry the prefix M_ as in the DMI (Supplementary_Driving_
--  Info): IS, the abbreviation of Isolation, is a reserved word.

package EVC_Modes
  with SPARK_Mode => On, Pure
is

   --  SUBSET-026 4.3.2.1, the modes in the order of the list
   type Mode_T is
     (M_FS,  -- Full Supervision
      M_AD,  -- Automatic Driving
      M_LS,  -- Limited Supervision
      M_OS,  -- On Sight
      M_SR,  -- Staff Responsible
      M_SM,  -- Supervised Manoeuvre
      M_SH,  -- Shunting
      M_UN,  -- Unfitted
      M_PS,  -- Passive Shunting
      M_SL,  -- Sleeping
      M_SB,  -- Stand By
      M_TR,  -- Trip
      M_PT,  -- Post Trip
      M_SF,  -- System Failure
      M_IS,  -- Isolation
      M_NP,  -- No Power
      M_NL,  -- Non Leading
      M_SN,  -- National System
      M_RV); -- Reversing

   --  The ERTMS/ETCS levels of SUBSET-026 v4.0.0: 0, NTC, 1 and 2 (there
   --  is no level 3 any more)
   type Level_T is (L0, NTC, L1, L2);

   --  The status of the stored level, as the start of mission reads it
   --  (SUBSET-026 5.4.3.2 D2: "valid", "invalid" or "unknown")
   type Level_Status_T is (Unknown, Invalid, Valid);

   --  4.6.1.4: each transition has a priority, p1 being the highest; 0
   --  stands for "no transition"
   subtype Priority_T is Natural range 0 .. 8;
   No_Transition : constant Priority_T := 0;

   type Transition_Table_T is array (Mode_T, Mode_T) of Priority_T;

   --  SUBSET-026 4.6.2 Figure 2 (PDF page 48 of SUBSET-026-4): the
   --  element (From, To) is the priority of the transition from From to
   --  To. The conditions are in 4.6.3; EVC_Core evaluates those of the
   --  current phase.
   Transitions : constant Transition_Table_T :=
     (M_NP => (M_SB => 2, M_IS => 1, others => 0),
      M_SB => (M_NP => 2, M_SH => 7, M_SM => 8, M_FS => 7, M_LS => 7,
               M_SR => 7, M_OS => 7, M_SL => 5, M_NL => 6, M_UN => 7,
               M_TR => 4, M_SF => 3, M_IS => 1, M_SN => 7, others => 0),
      M_PS => (M_NP => 2, M_SB => 4, M_SH => 4, M_SL => 4, M_IS => 1,
               others => 0),
      M_SH => (M_NP => 2, M_SB => 5, M_PS => 5, M_NL => 5, M_TR => 4,
               M_SF => 3, M_IS => 1, others => 0),
      M_SM => (M_NP => 2, M_SB => 4, M_SH => 6, M_NL => 6, M_TR => 5,
               M_SF => 3, M_IS => 1, others => 0),
      M_FS => (M_NP => 2, M_SB => 5, M_SH => 6, M_SM => 7, M_AD => 7,
               M_LS => 6, M_SR => 6, M_OS => 6, M_NL => 6, M_UN => 6,
               M_TR => 4, M_SF => 3, M_IS => 1, M_SN => 6, M_RV => 6,
               others => 0),
      M_AD => (M_NP => 2, M_SB => 5, M_SH => 6, M_SM => 7, M_FS => 7,
               M_LS => 6, M_SR => 6, M_OS => 6, M_NL => 6, M_UN => 6,
               M_TR => 4, M_SF => 3, M_IS => 1, M_SN => 6, M_RV => 6,
               others => 0),
      M_LS => (M_NP => 2, M_SB => 5, M_SH => 6, M_SM => 7, M_FS => 6,
               M_SR => 6, M_OS => 6, M_NL => 6, M_UN => 6, M_TR => 4,
               M_SF => 3, M_IS => 1, M_SN => 6, M_RV => 6, others => 0),
      M_SR => (M_NP => 2, M_SB => 5, M_SH => 6, M_SM => 7, M_FS => 6,
               M_LS => 6, M_OS => 6, M_NL => 6, M_UN => 6, M_TR => 4,
               M_SF => 3, M_IS => 1, M_SN => 6, others => 0),
      M_OS => (M_NP => 2, M_SB => 5, M_SH => 6, M_SM => 7, M_FS => 6,
               M_LS => 6, M_SR => 6, M_NL => 6, M_UN => 6, M_TR => 4,
               M_SF => 3, M_IS => 1, M_SN => 6, M_RV => 6, others => 0),
      M_SL => (M_NP => 2, M_SB => 3, M_IS => 1, others => 0),
      M_NL => (M_NP => 2, M_SB => 3, M_IS => 1, others => 0),
      M_UN => (M_NP => 2, M_SB => 6, M_SH => 7, M_FS => 7, M_LS => 7,
               M_SR => 4, M_OS => 7, M_TR => 5, M_SF => 3, M_IS => 1,
               M_SN => 7, others => 0),
      M_TR => (M_NP => 2, M_SH => 4, M_UN => 4, M_PT => 4, M_SF => 3,
               M_IS => 1, M_SN => 4, others => 0),
      M_PT => (M_NP => 2, M_SB => 4, M_SH => 5, M_SM => 6, M_FS => 5,
               M_LS => 5, M_SR => 5, M_OS => 5, M_UN => 5, M_SF => 3,
               M_IS => 1, M_SN => 5, others => 0),
      M_SF => (M_NP => 2, M_IS => 1, others => 0),
      --  4.4.3.1.3: no transition from Isolation is specified
      M_IS => (others => 0),
      M_SN => (M_NP => 2, M_SB => 6, M_SH => 7, M_FS => 7, M_LS => 7,
               M_SR => 4, M_OS => 7, M_UN => 7, M_TR => 5, M_SF => 3,
               M_IS => 1, others => 0),
      M_RV => (M_NP => 2, M_SB => 4, M_SF => 3, M_IS => 1, others => 0));

   function Transition_Exists (From, To : Mode_T) return Boolean is
     (Transitions (From, To) /= No_Transition);

   ---------------------------------------------------------------------
   --  Added by e4/modes: the conditions of each transition, and what the
   --  modes mean for the functions of the on-board (4.5.2, 4.10)
   ---------------------------------------------------------------------

   --  4.6.2 Figure 2: the conditions of 4.6.3 that allow the transition
   --  from From to To ("16, 17, 18" means "16 or 17 or 18", 4.6.1.6), as
   --  a list of identifiers padded with 0; No_Conditions where 4.6.2 has
   --  no transition. EVC_Transition_Conditions.Holds says whether one
   --  holds; evc_test checks that a list is not empty exactly where
   --  Transitions has a priority.
   subtype Condition_Ref_T is Natural range 0 .. 84;
   Max_Conditions : constant := 10;
   type Condition_List_T is array (1 .. Max_Conditions) of Condition_Ref_T;
   No_Conditions : constant Condition_List_T := (others => 0);
   type Condition_Table_T is array (Mode_T, Mode_T) of Condition_List_T;

   Conditions : constant Condition_Table_T :=
     (M_NP => (M_SB => (4, others => 0),
               M_IS => (1, others => 0),
               others => (others => 0)),
      M_SB => (M_NP => (29, others => 0),
               M_SH => (5, 6, 50, others => 0),
               M_SM => (81, others => 0),
               M_FS => (10, others => 0),
               M_LS => (70, others => 0),
               M_SR => (8, 37, others => 0),
               M_OS => (15, others => 0),
               M_SL => (14, others => 0),
               M_NL => (46, others => 0),
               M_UN => (60, others => 0),
               M_TR => (20, others => 0),
               M_SF => (13, others => 0),
               M_IS => (1, others => 0),
               M_SN => (58, others => 0),
               others => (others => 0)),
      M_PS => (M_NP => (29, others => 0),
               M_SB => (22, others => 0),
               M_SH => (23, others => 0),
               M_SL => (14, others => 0),
               M_IS => (1, others => 0),
               others => (others => 0)),
      M_SH => (M_NP => (29, others => 0),
               M_SB => (19, 27, 30, others => 0),
               M_PS => (26, others => 0),
               M_NL => (46, others => 0),
               M_TR => (49, 52, 65, others => 0),
               M_SF => (13, others => 0),
               M_IS => (1, others => 0),
               others => (others => 0)),
      M_SM => (M_NP => (29, others => 0),
               M_SB => (28, 82, others => 0),
               M_SH => (6, others => 0),
               M_NL => (46, others => 0),
               M_TR => (16, 17, 20, 41, 65, 66, 69, others => 0),
               M_SF => (13, 84, others => 0),
               M_IS => (1, others => 0),
               others => (others => 0)),
      M_FS => (M_NP => (29, others => 0),
               M_SB => (28, 83, others => 0),
               M_SH => (5, 6, 50, 51, others => 0),
               M_SM => (81, others => 0),
               M_AD => (80, others => 0),
               M_LS => (70, 72, others => 0),
               M_SR => (37, others => 0),
               M_OS => (15, 40, others => 0),
               M_NL => (46, others => 0),
               M_UN => (21, others => 0),
               M_TR => (11, 12, 16, 17, 18, 20, 41, 65, 66, 69),
               M_SF => (13, 84, others => 0),
               M_IS => (1, others => 0),
               M_SN => (56, others => 0),
               M_RV => (59, others => 0),
               others => (others => 0)),
      M_AD => (M_NP => (29, others => 0),
               M_SB => (28, 83, others => 0),
               M_SH => (5, 6, 50, 51, others => 0),
               M_SM => (81, others => 0),
               M_FS => (9, 24, 33, 48, 53, others => 0),
               M_LS => (70, 72, others => 0),
               M_SR => (37, others => 0),
               M_OS => (15, 40, others => 0),
               M_NL => (46, others => 0),
               M_UN => (21, others => 0),
               M_TR => (11, 12, 16, 17, 18, 20, 41, 65, 66, 69),
               M_SF => (13, 84, others => 0),
               M_IS => (1, others => 0),
               M_SN => (56, others => 0),
               M_RV => (59, others => 0),
               others => (others => 0)),
      M_LS => (M_NP => (29, others => 0),
               M_SB => (28, 83, others => 0),
               M_SH => (5, 6, 50, 51, others => 0),
               M_SM => (81, others => 0),
               M_FS => (76, others => 0),
               M_SR => (37, others => 0),
               M_OS => (15, 73, others => 0),
               M_NL => (46, others => 0),
               M_UN => (21, others => 0),
               M_TR => (11, 12, 16, 17, 18, 20, 41, 65, 66, 69),
               M_SF => (13, 84, others => 0),
               M_IS => (1, others => 0),
               M_SN => (56, others => 0),
               M_RV => (59, others => 0),
               others => (others => 0)),
      M_SR => (M_NP => (29, others => 0),
               M_SB => (28, 83, others => 0),
               M_SH => (5, 6, 51, others => 0),
               M_SM => (81, others => 0),
               M_FS => (31, 32, others => 0),
               M_LS => (72, others => 0),
               M_OS => (40, others => 0),
               M_NL => (46, others => 0),
               M_UN => (21, others => 0),
               M_TR => (18, 20, 42, 43, 36, 54, 65, others => 0),
               M_SF => (13, 84, others => 0),
               M_IS => (1, others => 0),
               M_SN => (56, others => 0),
               others => (others => 0)),
      M_OS => (M_NP => (29, others => 0),
               M_SB => (28, 83, others => 0),
               M_SH => (5, 6, 50, 51, others => 0),
               M_SM => (81, others => 0),
               M_FS => (75, others => 0),
               M_LS => (70, 74, others => 0),
               M_SR => (37, others => 0),
               M_NL => (46, others => 0),
               M_UN => (21, others => 0),
               M_TR => (11, 12, 16, 17, 18, 20, 41, 65, 66, 69),
               M_SF => (13, 84, others => 0),
               M_IS => (1, others => 0),
               M_SN => (56, others => 0),
               M_RV => (59, others => 0),
               others => (others => 0)),
      M_SL => (M_NP => (29, others => 0),
               M_SB => (2, 3, others => 0),
               M_IS => (1, others => 0),
               others => (others => 0)),
      M_NL => (M_NP => (29, others => 0),
               M_SB => (28, 47, others => 0),
               M_IS => (1, others => 0),
               others => (others => 0)),
      M_UN => (M_NP => (29, others => 0),
               M_SB => (28, 83, others => 0),
               M_SH => (5, 61, others => 0),
               M_FS => (25, others => 0),
               M_LS => (71, others => 0),
               M_SR => (44, 45, others => 0),
               M_OS => (34, others => 0),
               M_TR => (67, 39, 20, others => 0),
               M_SF => (13, others => 0),
               M_IS => (1, others => 0),
               M_SN => (56, others => 0),
               others => (others => 0)),
      M_TR => (M_NP => (29, others => 0),
               M_SH => (68, others => 0),
               M_UN => (62, others => 0),
               M_PT => (7, others => 0),
               M_SF => (13, others => 0),
               M_IS => (1, others => 0),
               M_SN => (63, others => 0),
               others => (others => 0)),
      M_PT => (M_NP => (29, others => 0),
               M_SB => (28, 83, others => 0),
               M_SH => (5, 6, 50, 78, others => 0),
               M_SM => (81, others => 0),
               M_FS => (31, others => 0),
               M_LS => (70, others => 0),
               M_SR => (8, 37, others => 0),
               M_OS => (15, others => 0),
               M_UN => (77, others => 0),
               M_SF => (13, others => 0),
               M_IS => (1, others => 0),
               M_SN => (79, others => 0),
               others => (others => 0)),
      M_SF => (M_NP => (29, others => 0),
               M_IS => (1, others => 0),
               others => (others => 0)),
      M_IS => (others => (others => 0)),
      M_SN => (M_NP => (29, others => 0),
               M_SB => (28, 83, others => 0),
               M_SH => (5, 61, others => 0),
               M_FS => (25, others => 0),
               M_LS => (71, others => 0),
               M_SR => (44, 45, others => 0),
               M_OS => (34, others => 0),
               M_UN => (21, others => 0),
               M_TR => (67, 39, 38, 35, 20, others => 0),
               M_SF => (13, others => 0),
               M_IS => (1, others => 0),
               others => (others => 0)),
      M_RV => (M_NP => (29, others => 0),
               M_SB => (28, others => 0),
               M_SF => (13, others => 0),
               M_IS => (1, others => 0),
               others => (others => 0)));

   --  4.5.2 Figure 1 (PDF pages 43 to 45 of SUBSET-026-4): the modes in
   --  which a function is active, as the on-board uses them
   --  - the MA, its release speed, the mode profile, the start of a level
   --    crossing not protected are monitored; the signalling related
   --    speed restriction and the speed restriction to ensure a
   --    permitted braking distance are in the MRSP
   function MA_Mode (M : Mode_T) return Boolean is
     (M in M_FS | M_AD | M_LS | M_OS);
   --  - the SSP, the ASP and the LX speed restriction are in the MRSP
   --    (and the Supervised Manoeuvre MA is monitored in SM)
   function Track_Speed_Mode (M : Mode_T) return Boolean is
     (M in M_SM | M_FS | M_AD | M_LS | M_OS);
   --  - the TSRs are in the MRSP, the gradient is used, the MRSP is
   --    monitored with its braking curves (SH and RV: ceiling speed
   --    monitoring only, {4}; SN: the National System, out of scope)
   function TSR_Mode (M : Mode_T) return Boolean is
     (M in M_SM | M_FS | M_AD | M_LS | M_SR | M_OS | M_UN);
   --  - the train related speed restriction (the maximum train speed)
   function Train_Speed_Mode (M : Mode_T) return Boolean is
     (M in M_SM | M_FS | M_AD | M_LS | M_SR | M_OS | M_UN | M_RV);
   --  - the check of the linking consistency (3.4.4.2.1.1 b) and of the
   --    odometer accuracy thresholds (3.6.8.5 to 3.6.8.7)
   function Linking_Check_Mode (M : Mode_T) return Boolean is
     (M in M_SM | M_FS | M_AD | M_LS | M_OS);
   function Odometer_Check_Mode (M : Mode_T) return Boolean is
     (M in M_SM | M_FS | M_AD | M_LS | M_SR | M_OS);

   --  5.4.6.1: a mission is considered as started on entering these
   --  modes
   function Mission_Mode (M : Mode_T) return Boolean is
     (M in M_FS | M_LS | M_SR | M_OS | M_SM | M_NL | M_UN | M_SN);

end EVC_Modes;
