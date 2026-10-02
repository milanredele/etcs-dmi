--  ETCS on-board (EVC)
--  The main of the runner of the SUBSET-076 test sequences against the on-board (host
--  only). See S076_Run for how a sequence is replayed and judged, and
--  S076_Tables for the mappings of the names the sequences use.
--
--  The sequences come from a sibling checkout (../etcs-subset076, or
--  $S076_CHECKOUT: sequences/<SV>/*.scn); the hand-written fixture
--  test/s076-sample/runner/*.scn exercises the runner itself and runs
--  always. Each sequence ends passed, failed at a step, or blocked at
--  a step by a reason; test/s076/baseline.csv holds the outcome of
--  every sequence of the last recorded run (our own results only, no
--  SUBSET-076 text) and the run fails when a sequence got worse: it
--  fails or blocks at an earlier step, or a step that blocked now
--  fails. Improvements are reported; UPDATE=1 records the baseline
--  anew. The report obj/evc_s076_run.txt has the counts per system
--  version, per feature and per reason, and the failure signatures
--  ranked by the number of sequences they stop.
--
--  Usage:  obj/evc_s076_run              the fixture and the corpus
--          obj/evc_s076_run NAME|PATH    one sequence; VERBOSE=1 for a
--                                        line per step
--          S076_ONLY=sv30 ...            only the system version given
--  Exit status 1 on a regression against the baseline. Never raises on
--  any content of a sequence file.

pragma Ada_2012;
with Ada.Calendar;     use Ada.Calendar;
with Ada.Command_Line;
with Ada.Directories;  use Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Text_IO;      use Ada.Text_IO;
with Interfaces;       use Interfaces;
with S076_Run;         use S076_Run;
with S076_Sequences;   use S076_Sequences;
with S076_Tables;
with Scn_Reader;

package body S076_Main is

   package Env renames Ada.Environment_Variables;

   Verbose : constant Boolean := Env.Exists ("VERBOSE");
   Update  : constant Boolean := Env.Exists ("UPDATE");

   Root : constant String :=
     (if Env.Exists ("S076_CHECKOUT") then Env.Value ("S076_CHECKOUT")
      else "../etcs-subset076");
   Fixture_Dir   : constant String := "test/s076-sample/runner";
   Baseline_Path : constant String := "test/s076/baseline.csv";
   Report_Path   : constant String := "obj/evc_s076_run.txt";

   function Img (N : Integer) return String is
      S : constant String := Integer'Image (N);
   begin
      return (if N < 0 then S else S (S'First + 1 .. S'Last));
   end Img;

   ---------------------------------------------------------------------
   --  Signatures: the normalised text of a failure, with a stable id
   ---------------------------------------------------------------------

   function Hash (S : String) return String is
      H : Unsigned_32 := 2_166_136_261;
      Hex : constant String := "0123456789abcdef";
      R : String (1 .. 8);
   begin
      for C of S loop
         H := (H xor Character'Pos (C)) * 16_777_619;
      end loop;
      for I in reverse R'Range loop
         R (I) := Hex (Natural (H and 15) + 1);
         H := Shift_Right (H, 4);
      end loop;
      return "S" & R;
   end Hash;

   Max_Sigs : constant := 4096;
   type Sig_T is record
      Text      : Text_T;
      Id        : String (1 .. 9) := (others => ' ');
      Sequences : Natural := 0;  -- sequences whose first failure it is
      Steps     : Natural := 0;  -- failed steps with it
      Examples  : Text_T;        -- names, comma separated
      Example_N : Natural := 0;
   end record;
   Sigs   : array (1 .. Max_Sigs) of Sig_T;
   Sig_N  : Natural := 0;

   function Find_Sig (S : String) return Natural is
   begin
      for I in 1 .. Sig_N loop
         if Image (Sigs (I).Text) = S then
            return I;
         end if;
      end loop;
      if Sig_N = Max_Sigs then
         return 0;
      end if;
      Sig_N := Sig_N + 1;
      Sigs (Sig_N) := (Text => To_Text (S), Id => Hash (S), others => <>);
      return Sig_N;
   end Find_Sig;

   procedure Add_Example (I : Positive; Name : String) is
      E : Text_T renames Sigs (I).Examples;
   begin
      if Sigs (I).Example_N < 3 then
         E := To_Text (Image (E) & (if E.N > 0 then ", " else "") & Name);
         Sigs (I).Example_N := Sigs (I).Example_N + 1;
      end if;
   end Add_Example;

   --  The signature of a failed step: the expectation's interface and
   --  kind, then what was expected and what was got
   function Signature (Index : Positive) return String is
      St : Step_T renames Loaded.Steps (Index);
      L  : Scn_Reader.Line_T (St.Line.N);
   begin
      L.Text := Image (St.Line);
      Scn_Reader.Split (L);
      return Scn_Reader.Word (L, 1) & " " & Scn_Reader.Word (L, 2) & " "
        & Scn_Reader.Word (L, 3) & ": "
        & Image (Results (Index).Signature)
        & (if Loaded.Workbook then " [workbook train]" else "");
   end Signature;

   ---------------------------------------------------------------------
   --  Counters
   ---------------------------------------------------------------------

   type Count_T is record
      Sequences, Passed_S, Failed_S, Blocked_S : Natural := 0;
      Passed, Failed, After_First, Not_Judged, Not_Run : Natural := 0;
   end record;

   procedure Add (C : in out Count_T) is
   begin
      C.Sequences := C.Sequences + 1;
      case Outcome is
         when Seq_Passed  => C.Passed_S := C.Passed_S + 1;
         when Seq_Failed  => C.Failed_S := C.Failed_S + 1;
         when Seq_Blocked => C.Blocked_S := C.Blocked_S + 1;
      end case;
      for I in 1 .. Loaded.Step_Count loop
         case Results (I).Verdict is
            when Passed => C.Passed := C.Passed + 1;
            when Failed =>
               C.Failed := C.Failed + 1;
               if Results (I).After_First_Failure then
                  C.After_First := C.After_First + 1;
               end if;
            when Not_Judged => C.Not_Judged := C.Not_Judged + 1;
            when Not_Run => C.Not_Run := C.Not_Run + 1;
         end case;
      end loop;
   end Add;

   function Line_Of (C : Count_T) return String is
     (Img (C.Sequences) & " sequences: " & Img (C.Passed_S) & " passed, "
      & Img (C.Failed_S) & " failed, " & Img (C.Blocked_S) & " blocked; steps: "
      & Img (C.Passed) & " passed, " & Img (C.Failed) & " failed ("
      & Img (C.After_First) & " after the first failure), "
      & Img (C.Not_Judged) & " not judged, " & Img (C.Not_Run) & " not run");

   Total, Fixture : Count_T;
   By_SV   : array (0 .. 2) of Count_T;     -- sv21, sv22, sv30
   Max_Features : constant := 400;
   type Feature_T is record
      Name : String (1 .. 7) := (others => ' ');
      C    : Count_T;
   end record;
   Features  : array (1 .. Max_Features) of Feature_T;
   Feature_N : Natural := 0;

   --  not judged steps by reason, and by reason and detail
   Reason_Steps : array (Reason_T) of Natural := (others => 0);
   Block_Seqs   : array (Reason_T) of Natural := (others => 0);
   Max_Details : constant := 2048;
   type Detail_T is record
      Reason : Reason_T := R_None;
      Text   : Text_T;
      Count  : Natural := 0;
      Blocks : Natural := 0;
   end record;
   Details  : array (1 .. Max_Details) of Detail_T;
   Detail_N : Natural := 0;

   procedure Count_Detail (R : Reason_T; S : String; Is_Block : Boolean) is
      --  the detail without its numbers past the message id, so that
      --  "JRU not modelled" lists the messages
      K : Natural := 0;
   begin
      for I in 1 .. Detail_N loop
         if Details (I).Reason = R and then Image (Details (I).Text) = S then
            K := I;
            exit;
         end if;
      end loop;
      if K = 0 then
         if Detail_N = Max_Details then
            return;
         end if;
         Detail_N := Detail_N + 1;
         K := Detail_N;
         Details (K) := (Reason => R, Text => To_Text (S), others => <>);
      end if;
      if Is_Block then
         Details (K).Blocks := Details (K).Blocks + 1;
      else
         Details (K).Count := Details (K).Count + 1;
      end if;
   end Count_Detail;

   ---------------------------------------------------------------------
   --  The baseline
   ---------------------------------------------------------------------

   Max_Rows : constant := 4096;
   type Row_T is record
      Name    : Text_T;
      Outcome : Outcome_T := Seq_Passed;
      Step    : Natural := 0;
      Why     : Text_T;      -- the reason code or the signature id
      Seen    : Boolean := False;
   end record;
   Old_Rows : array (1 .. Max_Rows) of Row_T;
   Old_N    : Natural := 0;
   New_Rows : array (1 .. Max_Rows) of Row_T;
   New_N    : Natural := 0;

   Regressions, Improvements, New_Seqs : Natural := 0;
   Regression_List, Improvement_List : Text_T;

   function Outcome_Word (O : Outcome_T) return String is
     (case O is when Seq_Passed => "passed", when Seq_Failed => "failed",
                when Seq_Blocked => "blocked");

   function Reason_Code (R : Reason_T) return String is
     (case R is
         when R_None             => "-",
         when R_Level_2          => "E5-level2",
         when R_Version          => "E7-version",
         when R_Euroloop         => "E7-euroloop",
         when R_NTC              => "NTC",
         when R_ATO              => "ATO",
         when R_DMI_Internal     => "DMI-internal",
         when R_JRU_Not_Modelled => "JRU-not-modelled",
         when R_Not_Modelled     => "not-modelled",
         when R_Unclassified     => "unclassified",
         when R_Extractor        => "extractor",
         when R_S076_Defect      => "S076-defect",
         when R_Optional         => "optional",
         when R_Runner           => "runner");

   procedure Read_Baseline is
      F : File_Type;
   begin
      if not Exists (Baseline_Path) then
         return;
      end if;
      Open (F, In_File, Baseline_Path);
      while not End_Of_File (F) and then Old_N < Max_Rows loop
         declare
            L : constant String := Get_Line (F);
            C1, C2, C3 : Natural := 0;
         begin
            if L'Length > 0 and then L (L'First) /= '#' then
               for I in L'Range loop
                  if L (I) = ',' then
                     if C1 = 0 then C1 := I;
                     elsif C2 = 0 then C2 := I;
                     elsif C3 = 0 then C3 := I;
                     end if;
                  end if;
               end loop;
               if C3 > 0 then
                  Old_N := Old_N + 1;
                  Old_Rows (Old_N).Name := To_Text (L (L'First .. C1 - 1));
                  Old_Rows (Old_N).Outcome :=
                    (if L (C1 + 1 .. C2 - 1) = "failed" then Seq_Failed
                     elsif L (C1 + 1 .. C2 - 1) = "blocked" then Seq_Blocked
                     else Seq_Passed);
                  Old_Rows (Old_N).Step :=
                    Natural'Value (L (C2 + 1 .. C3 - 1));
                  Old_Rows (Old_N).Why := To_Text (L (C3 + 1 .. L'Last));
               end if;
            end if;
         exception
            when others =>
               null;
         end;
      end loop;
      Close (F);
   end Read_Baseline;

   --  A step frontier: where a sequence stops being clean (passed:
   --  beyond every step)
   function Frontier (O : Outcome_T; Step : Natural) return Natural is
     (if O = Seq_Passed then Natural'Last else Step);

   procedure Compare (Name : String; Why : String) is
      Old : Natural := 0;
   begin
      for I in 1 .. Old_N loop
         if Image (Old_Rows (I).Name) = Name then
            Old := I;
            exit;
         end if;
      end loop;
      if New_N < Max_Rows then
         New_N := New_N + 1;
         New_Rows (New_N) := (Name => To_Text (Name), Outcome => Outcome,
                              Step => Outcome_Step, Why => To_Text (Why),
                              Seen => True);
      end if;
      if Old = 0 then
         New_Seqs := New_Seqs + 1;
         return;
      end if;
      Old_Rows (Old).Seen := True;
      declare
         O  : Row_T renames Old_Rows (Old);
         Fo : constant Natural := Frontier (O.Outcome, O.Step);
         Fn : constant Natural := Frontier (Outcome, Outcome_Step);
         Note : constant String :=
           Name & ": " & Outcome_Word (O.Outcome) & " " & Img (O.Step)
           & " -> " & Outcome_Word (Outcome) & " " & Img (Outcome_Step)
           & " " & Why;
      begin
         if Fn < Fo or else (Fn = Fo and then O.Outcome = Seq_Blocked
                             and then Outcome = Seq_Failed)
         then
            Regressions := Regressions + 1;
            Put_Line ("REGRESSION " & Note);
            if Regression_List.N < 200 then
               Regression_List := To_Text (Image (Regression_List) & " "
                                           & Name);
            end if;
         elsif Fn > Fo or else (Fn = Fo and then O.Outcome = Seq_Failed
                                and then Outcome = Seq_Blocked)
         then
            Improvements := Improvements + 1;
            if Verbose or else Improvements <= 20 then
               Put_Line ("improved " & Note);
            end if;
            if Improvement_List.N < 200 then
               Improvement_List := To_Text (Image (Improvement_List) & " "
                                            & Name);
            end if;
         end if;
      end;
   end Compare;

   procedure Write_Baseline is
      F : File_Type;
   begin
      --  sorted by name
      for I in 2 .. New_N loop
         for J in reverse 2 .. I loop
            exit when Image (New_Rows (J - 1).Name)
                      <= Image (New_Rows (J).Name);
            declare
               T : constant Row_T := New_Rows (J);
            begin
               New_Rows (J) := New_Rows (J - 1);
               New_Rows (J - 1) := T;
            end;
         end loop;
      end loop;
      Create_Path (Containing_Directory (Baseline_Path));
      Create (F, Out_File, Baseline_Path);
      Put_Line (F, "# obj/evc_s076_run: the outcome of every SUBSET-076 "
                & "sequence of the last recorded run (UPDATE=1).");
      Put_Line (F, "# name,outcome,step,reason (blocked) or signature id "
                & "(failed, see obj/evc_s076_run.txt)");
      for I in 1 .. New_N loop
         Put_Line (F, Image (New_Rows (I).Name) & ","
                   & Outcome_Word (New_Rows (I).Outcome) & ","
                   & Img (New_Rows (I).Step) & ","
                   & Image (New_Rows (I).Why));
      end loop;
      Close (F);
   end Write_Baseline;

   ---------------------------------------------------------------------
   --  One sequence
   ---------------------------------------------------------------------

   function SV_Index return Natural is
     (case Loaded.SV is when 21 => 0, when 22 => 1, when others => 2);

   procedure Run_One (Path : String; Is_Fixture : Boolean) is
      Ok : Boolean;
   begin
      Read (Path, Ok);
      if not Ok or else Loaded.Name.N = 0 then
         Put_Line ("evc_s076_run: " & Path & " unreadable, skipped");
         return;
      end if;
      Run_Loaded (Verbose => False);
      declare
         Name : constant String := Image (Loaded.Name);
         Why  : Text_T;
      begin
         if Is_Fixture then
            Add (Fixture);
         else
            Add (Total);
            Add (By_SV (SV_Index));
            declare
               F : constant String :=
                 (if Loaded.Feature.N >= 7
                  then Image (Loaded.Feature) (1 .. 7) else "unknown");
               K : Natural := 0;
            begin
               for I in 1 .. Feature_N loop
                  if Features (I).Name = F then
                     K := I;
                  end if;
               end loop;
               if K = 0 and then Feature_N < Max_Features then
                  Feature_N := Feature_N + 1;
                  K := Feature_N;
                  Features (K).Name := F;
               end if;
               if K > 0 then
                  Add (Features (K).C);
               end if;
            end;
            for I in 1 .. Loaded.Step_Count loop
               declare
                  R : Result_T renames Results (I);
               begin
                  if R.Verdict in Passed | Failed and then R.Detail.N > 0
                  then
                     Count_Detail (R_JRU_Not_Modelled,
                                   "field (step judged on the others): "
                                   & Image (R.Detail), Is_Block => False);
                  end if;
                  if R.Verdict = Not_Judged then
                     Reason_Steps (R.Reason) := Reason_Steps (R.Reason) + 1;
                     if R.Reason in R_JRU_Not_Modelled | R_DMI_Internal
                       | R_Runner | R_Not_Modelled | R_Unclassified
                     then
                        Count_Detail (R.Reason, Image (R.Signature),
                                      Is_Block => False);
                     end if;
                  elsif R.Verdict = Failed then
                     declare
                        K : constant Natural := Find_Sig (Signature (I));
                     begin
                        if K > 0 then
                           Sigs (K).Steps := Sigs (K).Steps + 1;
                        end if;
                     end;
                  end if;
               end;
            end loop;
         end if;
         case Outcome is
            when Seq_Passed =>
               Why := To_Text ("-");
            when Seq_Blocked =>
               Why := To_Text (Reason_Code (Block_Reason));
               if not Is_Fixture then
                  Block_Seqs (Block_Reason) := Block_Seqs (Block_Reason) + 1;
                  Count_Detail (Block_Reason, Image (Block_Detail),
                                Is_Block => True);
               end if;
            when Seq_Failed =>
               declare
                  S : constant String := Signature (Outcome_Index);
                  K : constant Natural := Find_Sig (S);
               begin
                  Why := To_Text (Hash (S));
                  if K > 0 and then not Is_Fixture then
                     Sigs (K).Sequences := Sigs (K).Sequences + 1;
                     Add_Example (K, Name);
                  end if;
               end;
         end case;
         Compare (Name, Image (Why));
      end;
   end Run_One;

   ---------------------------------------------------------------------
   --  The report
   ---------------------------------------------------------------------

   procedure Write_Report (Elapsed : Duration; Corpus : Boolean) is
      F : File_Type;
      Order : array (1 .. Sig_N) of Positive;
   begin
      Create (F, Out_File, Report_Path);
      Put_Line (F, "SUBSET-076 sequences against the on-board "
                & "(obj/evc_s076_run)");
      Put_Line (F, "");
      Put_Line (F, "fixture: " & Line_Of (Fixture));
      if not Corpus then
         Put_Line (F, "corpus: " & Root & " absent");
         Close (F);
         return;
      end if;
      Put_Line (F, "corpus:  " & Line_Of (Total));
      Put_Line (F, "run time:" & Duration'Image (Elapsed) & " s");
      Put_Line (F, "tables: " & S076_Tables.Table_Sizes);
      Put_Line (F, "baseline: " & Img (Regressions) & " regressions, "
                & Img (Improvements) & " improvements, " & Img (New_Seqs)
                & " new");
      Put_Line (F, "");
      Put_Line (F, "## Per system version");
      for I in By_SV'Range loop
         Put_Line (F, (case I is when 0 => "SV21", when 1 => "SV22",
                                 when others => "SV30")
                   & ": " & Line_Of (By_SV (I)));
      end loop;
      Put_Line (F, "");
      Put_Line (F, "## Sequences blocked, by reason");
      for R in Reason_T loop
         if Block_Seqs (R) > 0 then
            Put_Line (F, Img (Block_Seqs (R)) & "  " & Reason_Image (R));
            for I in 1 .. Detail_N loop
               if Details (I).Reason = R and then Details (I).Blocks >= 3 then
                  Put_Line (F, "      " & Img (Details (I).Blocks) & "  "
                            & Image (Details (I).Text));
               end if;
            end loop;
         end if;
      end loop;
      Put_Line (F, "");
      Put_Line (F, "## Steps not judged, by reason");
      for R in Reason_T loop
         if Reason_Steps (R) > 0 then
            Put_Line (F, Img (Reason_Steps (R)) & "  " & Reason_Image (R));
            for I in 1 .. Detail_N loop
               if Details (I).Reason = R and then Details (I).Count >= 1 then
                  Put_Line (F, "      " & Img (Details (I).Count) & "  "
                            & Image (Details (I).Text));
               end if;
            end loop;
         end if;
      end loop;
      Put_Line (F, "");
      Put_Line (F, "## Failure signatures (sequences stopped, failed steps, "
                & "id, signature, examples)");
      for I in Order'Range loop
         Order (I) := I;
      end loop;
      for I in 2 .. Order'Last loop
         for J in reverse 2 .. I loop
            exit when Sigs (Order (J - 1)).Sequences
                        > Sigs (Order (J)).Sequences
              or else (Sigs (Order (J - 1)).Sequences
                         = Sigs (Order (J)).Sequences
                       and then Sigs (Order (J - 1)).Steps
                                  >= Sigs (Order (J)).Steps);
            declare
               T : constant Positive := Order (J);
            begin
               Order (J) := Order (J - 1);
               Order (J - 1) := T;
            end;
         end loop;
      end loop;
      for I of Order loop
         Put_Line (F, Img (Sigs (I).Sequences) & "  " & Img (Sigs (I).Steps)
                   & "  " & Sigs (I).Id & "  " & Image (Sigs (I).Text));
         if Sigs (I).Example_N > 0 then
            Put_Line (F, "        e.g. " & Image (Sigs (I).Examples));
         end if;
      end loop;
      Put_Line (F, "");
      Put_Line (F, "## Per feature");
      for I in 1 .. Feature_N loop
         Put_Line (F, Features (I).Name & "  " & Line_Of (Features (I).C));
      end loop;
      Close (F);
   end Write_Report;

   ---------------------------------------------------------------------
   --  A single sequence by name or path
   ---------------------------------------------------------------------

   function Find (Arg : String) return String is
      Cands : constant array (1 .. 4) of Text_T :=
        (To_Text (Root & "/sequences/sv30/"), To_Text (Root & "/sequences/sv22/"),
         To_Text (Root & "/sequences/sv21/"), To_Text (Fixture_Dir & "/"));
   begin
      if Exists (Arg) then
         return Arg;
      end if;
      for C of Cands loop
         declare
            P1 : constant String := Image (C) & Arg;
            P2 : constant String := Image (C) & Arg & ".scn";
            P3 : constant String := Image (C) & "Subset-076-6-3_" & Arg
                                    & "_v400_SV30.scn";
         begin
            if Exists (P1) then
               return P1;
            elsif Exists (P2) then
               return P2;
            elsif Exists (P3) then
               return P3;
            end if;
         end;
      end loop;
      return "";
   end Find;

   Paths : Scn_Reader.Paths_T;

   procedure Run is
   Start : constant Time := Clock;
   Count : Natural := 0;
   Corpus : Boolean := False;
   Only  : constant String :=
     (if Env.Exists ("S076_ONLY") then Env.Value ("S076_ONLY") else "");
begin
   if Ada.Command_Line.Argument_Count >= 1 then
      declare
         Path : constant String := Find (Ada.Command_Line.Argument (1));
         Ok   : Boolean;
      begin
         if Path = "" then
            Put_Line ("evc_s076_run: " & Ada.Command_Line.Argument (1)
                      & " not found");
            Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
            return;
         end if;
         Read (Path, Ok);
         Run_Loaded (Verbose);
         Put_Line (Image (Loaded.Name) & ": "
                   & Outcome_Word (Outcome)
                   & (if Outcome = Seq_Passed then ""
                      else " at step" & Natural'Image (Outcome_Step))
                   & (case Outcome is
                         when Seq_Blocked => " by " & Reason_Image (Block_Reason)
                                             & ": " & Image (Block_Detail),
                         when Seq_Failed => ": " & Signature (Outcome_Index),
                         when Seq_Passed => ""));
      end;
      return;
   end if;

   Read_Baseline;

   --  the fixture, always
   Scn_Reader.List_Scn_Files (Fixture_Dir, Recurse => False,
                              Paths => Paths, Count => Count);
   for I in 1 .. Count loop
      Run_One (Paths (I).S (1 .. Paths (I).N), Is_Fixture => True);
   end loop;

   --  the corpus, when the sibling checkout is there
   if Exists (Root) and then Kind (Root) = Directory
     and then Exists (Root & "/sequences")
   then
      Corpus := True;
      Scn_Reader.List_Scn_Files (Root & "/sequences", Recurse => True,
                                 Paths => Paths, Count => Count);
      for I in 1 .. Count loop
         declare
            P : constant String := Paths (I).S (1 .. Paths (I).N);
         begin
            if Only = "" or else Ada.Strings.Fixed.Index (P, "/" & Only & "/")
                                   > 0
            then
               Run_One (P, Is_Fixture => False);
            end if;
         end;
      end loop;
   end if;

   --  baseline rows of sequences that did not run: kept, unless the
   --  corpus ran (then they are gone from it)
   for I in 1 .. Old_N loop
      if not Old_Rows (I).Seen
        and then (not Corpus or else Only /= "")
        and then New_N < Max_Rows
      then
         New_N := New_N + 1;
         New_Rows (New_N) := Old_Rows (I);
      end if;
   end loop;

   Write_Report (Clock - Start, Corpus);
   if Update then
      Write_Baseline;
   end if;

   if not Corpus then
      Put_Line ("evc_s076_run: " & Root & " absent, corpus skipped; "
                & "fixture: " & Line_Of (Fixture));
   else
      Put_Line ("evc_s076_run: " & Line_Of (Total)
                & "; baseline: " & Img (Regressions) & " regressions, "
                & Img (Improvements) & " improvements"
                & (if Update then " (recorded)" else ""));
   end if;
   if Regressions > 0 and then not Update then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Run;

end S076_Main;
