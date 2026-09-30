--  ETCS on-board (EVC)
--  Generic reader of the line oriented .scn scenario files (host only).
--
--  Two consumers share this format family: test/efs/*.scn, translated
--  from the ERTMSFormalSpecs test frames by test/tools/efs_frames.py
--  and read by evc_efs_test; and the SUBSET-076 test sequences of a
--  sibling checkout (sequences/<SV>/*.scn), read by evc_s076_check. One
--  item per line, the first word says what it is; '#' starts a comment,
--  a blank line is nothing. Everything specific to one format -- its
--  keywords, its units, the meaning of its numbers -- stays in its own
--  runner; this package only knows lines, words and numbers.
--
--  Never raises: an unreadable file, a line with too many words, or a
--  malformed number does not stop the reader (Ok / Valid say so, as
--  they did in evc_efs_test before this package was split out of it).

pragma Ada_2012;

package Scn_Reader is

   subtype Real is Long_Float;

   ------------------------------------------------------------------
   --  A line, split into words
   ------------------------------------------------------------------

   Max_Words : constant := 400;

   type Word_T is record
      First, Last : Natural := 0;
   end record;
   type Words_T is array (1 .. Max_Words) of Word_T;

   type Line_T (Length : Natural) is record
      Text  : String (1 .. Length);
      Count : Natural := 0;
      W     : Words_T;
   end record;

   --  Splits L.Text on blanks into L.W (1 .. L.Count); words beyond
   --  Max_Words are dropped
   procedure Split (L : in out Line_T);

   function Word (L : Line_T; K : Positive) return String;

   --  The text from word K to the end of the line, verbatim (its own
   --  spacing kept): the "key: ..." forms of both formats (efs:,
   --  expect efs:, raw:) that take the rest of the line as is are read
   --  through this, not through Word.
   function Rest (L : Line_T; K : Positive) return String;

   --  Field K (1-based) of a word of sub-fields, cut on any character
   --  of Delims (default the ':' '=' '@' '+' of the EFS scenarios,
   --  e.g. "kind@from+length" or "id:speed:accel"); a consumer passes
   --  its own Delims for another convention, e.g. "/" for a SUBSET-076
   --  "k/n" or ";" for a trailing "; comment".
   function Field (S : String; K : Positive; Delims : String := ":=@+")
     return String;

   ------------------------------------------------------------------
   --  Numbers (never raise: Valid is False, and 0.0 comes back, on
   --  anything a caller does not recognise; a caller resets Valid to
   --  True before a conversion whose validity it wants to check)
   ------------------------------------------------------------------

   Valid : Boolean := True;

   --  "inf" (Real'Last), or a plain number (digits, '.', '-', '+', 'e',
   --  'E'), at most 40 characters, magnitude under 1.0E12
   function To_Real (S : String) return Real;

   ------------------------------------------------------------------
   --  A file, line by line
   ------------------------------------------------------------------

   --  Called once per line that is neither blank nor a '#' comment,
   --  already split into words, with its 1-based line number
   procedure Read_File
     (Path    : String;
      Handler : not null access procedure (L : Line_T; Line_No : Positive);
      Ok      : out Boolean);

   ------------------------------------------------------------------
   --  *.scn files under a directory
   ------------------------------------------------------------------

   Max_Path  : constant := 300;
   Max_Files : constant := 1024;

   type Path_T is record
      S : String (1 .. Max_Path) := (others => ' ');
      N : Natural := 0;
   end record;
   type Paths_T is array (1 .. Max_Files) of Path_T;

   --  The *.scn files directly under Dir (Recurse: and every
   --  subdirectory of it too), full names, sorted for a stable order.
   --  Count is 0 when Dir does not exist, is not a directory, or holds
   --  none (a caller that wants to say "absent" on its own checks Dir
   --  itself first, as the two runners of this package do).
   procedure List_Scn_Files
     (Dir     : String;
      Recurse : Boolean;
      Paths   : out Paths_T;
      Count   : out Natural);

end Scn_Reader;
