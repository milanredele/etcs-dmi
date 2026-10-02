--  ETCS on-board (EVC)
--  One SUBSET-076 test sequence replayed against the on-board (host
--  only): the steps of S076_Sequences.Loaded in order on the bench of
--  S076_Bench, each step ending in exactly one verdict.
--
--  A step is an input (I) or an expected output (O). Before it, the
--  train moves to the step's distance. An input is applied through the
--  ports (SIM power, TIU signals, the odometer, balise groups, the
--  driver on the DMI's touch screen, timers as time passing), then the
--  bench runs Settle_Cycles. An expectation is judged against what the
--  on-board output since the last input (the observation window of
--  S076_Bench), waiting at most Wait_Cycles more cycles per window for
--  it to come. Then the step's level and mode columns are judged
--  against the on-board's mode and level: the state must be the one
--  before or the one after the step (for an input, at the moment the
--  input arrives).
--
--  The verdicts: Passed; Failed (a signature "expected, got"); Not
--  judged with a Reason_T. A sequence is passed when every judged step
--  passed and nothing blocked it; failed at its first failed step (the
--  later failures are counted as "after the first failure"); blocked at
--  the step whose input (or whose level or mode) the runner or the
--  on-board cannot take yet: the steps before it are judged, the steps
--  after it are not run.

pragma Ada_2012;
with S076_Sequences; use S076_Sequences;

package S076_Run is

   Settle_Cycles : constant := 3;
   Wait_Cycles   : constant := 40;

   type Verdict_T is (Passed, Failed, Not_Judged, Not_Run);

   --  Why a step is not judged, or why a sequence is blocked (a fixed
   --  list)
   type Reason_T is
     (R_None,
      R_Level_2,          -- level 2/3 or the RBC needed (E5)
      R_Version,          -- system version other than the 4.0 layout
                          -- (chapter 6, E7)
      R_Euroloop,         -- Euroloop (E7)
      R_E6,               -- a function of phase E6 (VBC, set speed, ...)
      R_NTC,              -- NTC / STM (out of scope)
      R_ATO,              -- ATO (the ATO port has no payload yet)
      R_DMI_Internal,     -- DMI internal, no query of DMI_Core for it
      R_JRU_Not_Modelled, -- a SUBSET-027 message or field this JRU port
                          -- does not carry
      R_Not_Modelled,     -- an on-board input or output this on-board
                          -- does not have
      R_Unclassified,     -- vocabulary unclassified in the sibling
      R_Extractor,        -- the step line or the telegram could not be
                          -- read by the sibling's extractor
      R_Optional,         -- an optional or implementation dependent
                          -- step of the sequence that our on-board does
                          -- not take (its comment says so)
      R_S076_Defect,      -- a defect of SUBSET-076 against SUBSET-026
                          -- 4.0.0 (the Known list of S076_Run)
      R_Runner);          -- runner not implemented for this kind

   function Reason_Image (R : Reason_T) return String;

   type Result_T is record
      Verdict : Verdict_T := Not_Run;
      Reason  : Reason_T := R_None;
      --  for a failure: the normalised signature (expected, got); for a
      --  step not judged: what was not judged (the JRU message id, the
      --  DMI object); for a pass: what was checked
      Signature : Text_T;
      Detail    : Text_T;
      After_First_Failure : Boolean := False;
   end record;
   type Results_T is array (1 .. Max_Steps) of Result_T;

   type Outcome_T is (Seq_Passed, Seq_Failed, Seq_Blocked);

   Results : Results_T;
   Outcome : Outcome_T := Seq_Passed;
   --  the step (its number in the sequence) of the first failure or the
   --  block; 0 for a passed sequence
   Outcome_Step : Natural := 0;
   --  the index in Results of that step
   Outcome_Index : Natural := 0;
   Block_Reason : Reason_T := R_None;
   Block_Detail : Text_T;
   --  when a sequence both failed and was blocked later
   Blocked_Too  : Boolean := False;

   --  Replay S076_Sequences.Loaded; Verbose prints a line per step
   procedure Run_Loaded (Verbose : Boolean);

end S076_Run;
