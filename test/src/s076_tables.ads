--  ETCS on-board (EVC)
--  The mapping tables of the SUBSET-076 runner (host only): the names
--  the sequences use (sibling README "Executable step descriptions")
--  and the SUBSET-027 messages they quote, to the frames, events and
--  modes of this on-board.
--
--  Every table answers "which facts of ours stand for this name"; a
--  name a table does not know gives an empty answer, which the runner
--  counts as not judged with its reason, never as passed.

pragma Ada_2012;
with EVC_Modes; use EVC_Modes;

package S076_Tables is

   ---------------------------------------------------------------------
   --  Modes and levels
   ---------------------------------------------------------------------

   type Mode_Set_T is array (Mode_T) of Boolean;
   No_Modes : constant Mode_Set_T := (others => False);

   --  The mode column of a step ("SB", "FS", ...) or an abbreviation
   --  of a symbol name ("OS" of "Mode-OS/LS"); No_Modes when unknown
   function Mode_Of (Abbreviation : String) return Mode_Set_T;

   --  A mode symbol name of an "expect DMI mode-symbol" line, without
   --  its "Acknowledge-" prefix ("Stand-By", "Staff-Responsible",
   --  "Mode-OS/LS", "Mode-SH-/-LS-/-OS"): the modes it may stand for
   function Mode_Of_Symbol (Name : String) return Mode_Set_T;

   --  The level of a column or a symbol ("L1", "Level-1", "LNTC",
   --  "NTC"); Known False for "N/A" and anything else. L3 is not a
   --  level of 4.0.0: Known with Is_L3.
   type Level_Kind_T is (K_None, K_L0, K_NTC, K_L1, K_L2, K_L3);
   function Level_Of (Name : String) return Level_Kind_T;

   --  M_MODE of SUBSET-026 7.5.1.72 (and SUBSET-027) to our modes
   function Mode_Of_M_MODE (Value : Natural; Mode : out Mode_T)
     return Boolean;

   --  The code of a mode on the DMI wire (DMI 13.3 Table 60)
   function DMI_Code (Mode : Mode_T) return Natural;

   ---------------------------------------------------------------------
   --  DMI objects
   ---------------------------------------------------------------------

   --  The catalogue entries (dmi_protocol.ads SS_*) a system status
   --  message name of SUBSET-076 stands for; Count 0 when unknown
   type Number_List_T is array (1 .. 16) of Natural;
   type Numbers_T is record
      Count : Natural := 0;
      List  : Number_List_T := (others => 0);
   end record;
   function SS_Entries (Name : String) return Numbers_T;

   --  The track condition symbols (TC numbers of DMI 13, 38 for the
   --  level crossing LX01) a track condition name stands for
   function TC_Kinds (Name : String) return Numbers_T;

   --  The kinds of the track condition output (EVC_Ports, the second
   --  TIU output: 1 pantograph, 2 main power switch, 3 air tightness, 4
   --  regenerative brake, 5 eddy current service, 6 eddy current
   --  emergency, 7 magnetic shoe, 8 traction system, 9 current
   --  consumption, 10 station platform) a SUBSET-034 name stands for
   function TIU_TC_Kinds (Name : String) return Numbers_T;

   ---------------------------------------------------------------------
   --  JRU: SUBSET-027 messages to the events of EVC_Ports
   ---------------------------------------------------------------------

   --  A fact the on-board's JRU port carries
   type Fact_Kind_T is
     (No_Fact,
      Mode_Is,          -- the last event 1 has mode Mode
      Mode_Is_Not,
      Level_Is,         -- the level of the last event 1 / event 40 kind 1
      Event_Seen,       -- an event Event (kind Kind if Kind >= 0, byte 3
                        -- in B3 if B3 >= 0) in the window
      Mode_Proposed,    -- event 41 kind 6 or event 23 kind 4, byte 3 Mode
      Mode_Acked,       -- event 41 kind 7 or event 23 kind 5, byte 3 Mode
      Brake_Change,     -- an event 20 whose bit Bit of byte 2 changed to
                        -- Value
      Brakes_Shown,     -- an event 20 with an EB or SB command (Value 1)
                        -- or with none (Value 0)
      Trip_Reason);     -- event 23 kind 1, byte 3 in the list B3_List

   type Fact_T is record
      Kind   : Fact_Kind_T := No_Fact;
      Mode   : Mode_T := M_NP;
      Level  : Level_T := L0;
      Event  : Natural := 0;
      Sub    : Integer := -1;   -- byte 2 (the kind), -1 any
      B3     : Integer := -1;   -- byte 3, -1 any
      Bit    : Natural := 0;
      Value  : Natural := 0;
      B3_List : Numbers_T;
   end record;

   --  M_DRIVERACTIONS (SUBSET-027 4.2.4.11) to a fact; No_Fact when
   --  the on-board records nothing for it (Why says what)
   function Driver_Action_Fact (Code : Natural) return Fact_T;

   --  A bit of DMI_SYMB_STATUS (4.2.4.21) set (On) or cleared
   function Symbol_Fact (Bit : Natural; On : Boolean) return Fact_T;

   --  A bit of SYSTEM_STATUS_MESSAGE (4.2.4.23) set
   function System_Status_Fact (Bit : Natural; On : Boolean) return Fact_T;

   --  The messages of SUBSET-027 4.2.1 that the JRU port of this
   --  on-board carries as a whole (an event of ours stands for every
   --  record of it): the event and the kind, -1 any
   type JRU_Map_T is record
      Event : Natural := 0;
      Sub   : Integer := -1;
      B4    : Integer := -1;
      Known : Boolean := False;
   end record;
   function Message_Event (NID_Message_JRU : Natural) return JRU_Map_T;

   --  The size of the tables, for the report
   function Table_Sizes return String;

end S076_Tables;
