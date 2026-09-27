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

end EVC_Modes;
