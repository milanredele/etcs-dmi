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
   Max_Text      : constant := 160;
   Max_Line      : constant := 256;
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
      Loop_Tag  : Boolean := False;
      Packet_Tag : Boolean := False;
   end record;
   type Telegrams_T is array (1 .. Max_Telegrams) of Telegram_T;

   type Message_T is record
      Step    : Natural := 0;
      Dist_Cm : Integer_64 := 0;
      NID     : Natural := 0;
   end record;
   type Messages_T is array (1 .. Max_Messages) of Message_T;

   --  "dmi <step> <event> <name> | <data> | <delay>": the data part
   type DMI_Event_T is record
      Step  : Natural := 0;
      Event : Natural := 0;
      Data  : Text_T;
   end record;
   type DMI_Events_T is array (1 .. Max_DMI) of DMI_Event_T;

   --  A timer value of a var row (T_SECTIONTIMER, T_TEXTDISPLAY, ...):
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

end S076_Sequences;
