--  ETCS on-board (EVC)
--  A SUBSET-076 test sequence in memory (host only), as the sibling
--  repository ../etcs-subset076 writes it (sequences/<SV>/*.scn, its
--  README.md "The .scn format" and "Executable step descriptions").
--
--  The reader keeps what the runner of the sequences (evc_s076_run)
--  executes and reports: the header (name, system version, feature),
--  the steps (number, row, distance, the level and mode before and
--  after, I/O, interface, the classified "input" / "expect" line, the
--  text for the report), the balise telegrams with their bits, the
--  radio messages (only to know that there are some), the DMI events
--  of the PDF ("dmi" lines: the data of a driver's entry), the timer
--  values found in the "var" rows, and the speed chart. Everything else
--  (comments of the PDF, workbook cells, raw lines) is passed over.
--
--  Bounded: a sequence with more steps, telegrams or chart points than
--  the limits below keeps the first ones and says so (Truncated). Never
--  raises on any content of a file.

pragma Ada_2012;
with Interfaces; use Interfaces;

package S076_Sequences is

   Max_Steps     : constant := 512;
   Max_Telegrams : constant := 96;
   Max_Messages  : constant := 160;
   Max_DMI       : constant := 48;
   Max_Points    : constant := 128;
   Max_Timers    : constant := 64;
   Max_Text      : constant := 400;
   Max_Line      : constant := 512;
   Max_Bytes     : constant := 104;  -- an 830 bit telegram

   --  A short text (a word, a line), bounded
   type Text_T is record
      S : String (1 .. Max_Line) := (others => ' ');
      N : Natural := 0;
   end record;

   function Image (T : Text_T) return String is (T.S (1 .. T.N));
   function To_Text (S : String) return Text_T;

   type IO_T is (Input, Output, Unknown);

   --  The level and mode columns as the sequence writes them ("N/A",
   --  "L1", "SB", ...), kept as text: the runner maps them
   subtype Column_T is String (1 .. 4);

   type Step_T is record
      Number, Row : Natural := 0;
      --  the distance column, cm
      Dist_Cm     : Integer_64 := 0;
      Lvl_Before, Mode_Before, Lvl_After, Mode_After : Column_T :=
        (others => ' ');
      IO          : IO_T := Unknown;
      Interface_Name : Column_T := (others => ' ');
      --  the step line had the ten words of the format
      Well_Formed : Boolean := False;
      --  the "input ..." / "expect ..." line, verbatim; N = 0 when the
      --  step's text matched no classifier of the sibling
      Line        : Text_T;
      Text        : Text_T;     -- "text:" (cut to Max_Text)
      Comment     : Text_T;     -- "comment:" (cut to Max_Text)
      Line_No     : Natural := 0;
   end record;
   type Steps_T is array (1 .. Max_Steps) of Step_T;

   type Byte_Array is array (Positive range <>) of Unsigned_8;

   --  A balise telegram (or a Euroloop or standalone packet block)
   type Telegram_T is record
      Step      : Natural := 0;
      Tag       : String (1 .. 16) := (others => ' ');  -- BG1d, LOOP
      Tag_Len   : Natural := 0;
      Part      : Natural := 1;                  -- k of k/n
      Parts     : Natural := 1;                  -- n
      Dist_Cm   : Integer_64 := 0;
      Rel_Cm    : Integer_64 := 0;               -- "rel": 0 when absent
      Has_Bits  : Boolean := False;
      Bits      : Natural := 0;
      Data      : Byte_Array (1 .. Max_Bytes) := (others => 0);
      M_Version : Integer := -1;                 -- -1: no var row
      --  the NID_PACKET of its var rows (255 left out)
      Packets   : Byte_Array (1 .. 24) := (others => 0);
      Packet_Count : Natural := 0;
      --  a var row M_LEVELTEXTDISPLAY 5: "no level" in the coding before
      --  4.0.0 (7.5.1.66 of 4.0.0 has it as 4, 5 is spare)
      Old_Level_Text : Boolean := False;
      --  a var row M_LEVELTR 4: an order to level 3, which 4.0.0 has
      --  no longer (7.5.1.67: 4 is spare)
      Level_3 : Boolean := False;
      Loop_Tag  : Boolean := False;
      Packet_Tag : Boolean := False;
   end record;
   type Telegrams_T is array (1 .. Max_Telegrams) of Telegram_T;

   --  An RBC message ("message" block): the message to the on-board of
   --  an input step, or the one an expectation describes. Data: the
   --  message from its first bit on (NID_MESSAGE), as the var rows give
   --  it (Has_Bits False when the extractor refused it); T_Train_At: the
   --  bit of each T_TRAIN var row (the header's, then the time stamp of
   --  the message answered: 8.4.4, messages 4, 5, 7, 8, 27, 28); the
   --  NID_PACKET of its var rows (255 left out)
   Max_Message_Bytes : constant := 160;   -- 1093 bits in the corpus
   type T_Train_At_T is array (1 .. 4) of Natural;
   type Message_T is record
      Step    : Natural := 0;
      Dist_Cm : Integer_64 := 0;
      NID     : Natural := 0;
      Has_Bits : Boolean := False;
      Bits    : Natural := 0;
      Data    : Byte_Array (1 .. Max_Message_Bytes) := (others => 0);
      T_Train_At : T_Train_At_T := (others => 0);
      T_Train_Count : Natural := 0;
      Packets : Byte_Array (1 .. 24) := (others => 0);
      Packet_Count : Natural := 0;
   end record;
   type Messages_T is array (1 .. Max_Messages) of Message_T;

   --  "dmi <step> <event> <name> | <data> | <delay>": the data part
   type DMI_Event_T is record
      Step  : Natural := 0;
      Event : Natural := 0;
      Data  : Text_T;
   end record;
   type DMI_Events_T is array (1 .. Max_DMI) of DMI_Event_T;

   --  A timer value or a national speed value of a var row
   --  (T_SECTIONTIMER, T_TEXTDISPLAY, ..., V_NVALLOWOVTRP, ...):
   --  the name, the value as coded, the step of its telegram / message
   type Timer_T is record
      Name  : Column_T := (others => ' ');
      Name_Text : Text_T;
      Value : Unsigned_64 := 0;
      Step  : Natural := 0;
   end record;
   type Timers_T is array (1 .. Max_Timers) of Timer_T;

   --  The speed chart (chart speedprofile): metres and km/h
   type Point_T is record
      X_M, V_Kmh : Long_Float := 0.0;
   end record;
   type Points_T is array (1 .. Max_Points) of Point_T;

   --  The braking curve results of the ERA braking curves tool filled by
   --  the test authors (a workbook's "curves <sheet>" block: "limit",
   --  "curve-columns" and "curve" lines, README of the sequences, "The
   --  .scn format"). Limits: the tool's table 3, the locations of the
   --  supervision limits at the initial speed, in metres counted from
   --  the target (the speeds in km/h). Curves: per sampled speed (km/h),
   --  the distance of each curve from the target, m; the rows between
   --  two sampled ones are linear (Curve_Distance). No_Value where the
   --  sheet has none. Names and columns not listed here are skipped.
   Max_Curve_Sets : constant := 10;    -- 9 workbooks in a sequence
   Max_Curve_Rows : constant := 340;   -- 330 rows in a set
   No_Value       : constant Long_Float := -1.0E12;
   type Limit_Name_T is
     (Initial_Speed, Perturbation, Indication, Permitted, Warning, SBI,
      EBI, Start_RSM, Release_Speed);
   type Curve_Column_T is
     (EBD, SBD, EBI, SBI1, SBI2, SBI, Warning, Permitted, Indication,
      GUI_EOA, EBI_Release);
   type Limits_T is array (Limit_Name_T) of Long_Float;
   type Distances_T is array (Curve_Column_T) of Long_Float;
   type Curve_Row_T is record
      Speed_Kmh : Long_Float := 0.0;
      D         : Distances_T := (others => No_Value);
   end record;
   type Curve_Rows_T is array (1 .. Max_Curve_Rows) of Curve_Row_T;
   type Curve_Set_T is record
      Workbook  : Text_T;          -- the .xlsm file name
      Sheet     : Text_T;          -- "Curves Gamma train", ...
      --  the block is the copy of the SV30 twin's (a "curves-from <name>"
      --  line right after "curves <sheet>"; plan section 13 round 17):
      --  the name of that SV30 sequence
      From_Twin : Boolean := False;
      Twin      : Text_T;
      --  B200: the target speed of its workbook (Track!B2, km/h;
      --  No_Value when not given) and whether that workbook's gradient
      --  profile is flat (every Track!J value 0)
      Target_Kmh : Long_Float := No_Value;
      Flat       : Boolean := True;
      Limits    : Limits_T := (others => No_Value);
      Rows      : Curve_Rows_T;
      Row_Count : Natural := 0;
   end record;
   type Curve_Sets_T is array (1 .. Max_Curve_Sets) of Curve_Set_T;

   --  B200: the integrated correction factors of the sequence's packets
   --  3 (the first Max_P3, in file order), at the resolutions of 7.5.1:
   --  Kv_int of set 0 by speed step (V_NVKVINT, km/h), Kr_int by train
   --  length step (L_NVKRINT, m), Kt_int; Given is Q_NVKINT 1, else the
   --  packet means the defaults of A.3.2
   Max_K_Steps : constant := 8;
   Max_P3      : constant := 6;
   type K_Step_T is record
      From : Natural := 0;           -- km/h for Kv_int, m for Kr_int
      K    : Long_Float := 0.0;
   end record;
   type K_Steps_T is array (1 .. Max_K_Steps) of K_Step_T;
   type Factors_T is record
      Given    : Boolean := False;
      Kv       : K_Steps_T;
      Kv_Count : Natural := 0;
      Kr       : K_Steps_T;
      Kr_Count : Natural := 0;
      Kt       : Long_Float := 1.1;
   end record;
   type Factor_Sets_T is array (1 .. Max_P3) of Factors_T;

   type Sequence_T is record
      Name      : Text_T;
      SV        : Natural := 0;     -- 21, 22, 30
      Feature   : Text_T;
      Steps     : Steps_T;
      Step_Count : Natural := 0;
      Telegrams : Telegrams_T;
      Telegram_Count : Natural := 0;
      Messages  : Messages_T;
      Message_Count : Natural := 0;
      DMI       : DMI_Events_T;
      DMI_Count : Natural := 0;
      Timers    : Timers_T;
      Timer_Count : Natural := 0;
      Chart     : Points_T;
      Chart_Count : Natural := 0;
      Truncated : Boolean := False;
      --  a "workbook" line: the braking curves are those of the ERA
      --  braking curve workbook's train (not the Train Data entered)
      Workbook  : Boolean := False;
      --  its train: the length (Train (main)!D18, m) and the brake
      --  percentage (Brake parameters (lambda)!F2); 0 when not given
      WB_Length, WB_Lambda : Natural := 0;
      --  the emergency brake percentage the tool computed its EBD with
      --  (Brake parameters (lambda)!F3; 100 in every workbook)
      WB_Lambda_EB : Natural := 0;
      --  B200: its packets 3
      P3       : Factor_Sets_T;
      P3_Count : Natural := 0;
      --  its brake position (Train (main), "Current brake position:"):
      --  0 not given, 1 passenger in P, 2 freight in P, 3 freight in G
      WB_Brake_Position : Natural := 0;
      --  its braking curve results, in the order of the workbooks
      Curves      : Curve_Sets_T;
      Curve_Count : Natural := 0;
   end record;

   --  The sequence read last (Read): too big for a stack, one at a time
   Loaded : aliased Sequence_T;

   --  Read the sequence file at Path into Loaded; Ok is False when the
   --  file could not be read
   procedure Read (Path : String; Ok : out Boolean);

   --  The data part of the "dmi" line of Step ("LEVEL=1"), "" when none
   function DMI_Data (S : Sequence_T; Step : Natural) return String;

   --  The speed of the chart at X_M metres, km/h; -1.0 without a chart
   function Chart_Speed (S : Sequence_T; X_M : Long_Float) return Long_Float;

   --  The distance from the target of Column of C at V_Kmh, m, linear
   --  between the two sampled rows around it; No_Value outside the rows
   --  or where either row has no value
   function Curve_Distance
     (C : Curve_Set_T; Column : Curve_Column_T; V_Kmh : Long_Float)
      return Long_Float;

   --  Print the braking curve results of S (VERBOSE=1 of one sequence):
   --  per set its workbook, sheet, rows, limits, and the curves at its
   --  initial speed
   procedure Put_Curves (S : Sequence_T);

end S076_Sequences;
