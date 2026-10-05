--  ETCS on-board (EVC)
--  The movement authority of level 1 and its use on board (SUBSET-026
--  3.8.3, 3.8.4, packet 12), the signalling related speed restriction
--  (3.11.6) and the mode profile (3.12.4, packet 80).
--
--  An MA of a balise group (3.8.3.6: the first section starts at its
--  location reference) is kept as its sections, the end of the last one
--  being the End of Movement Authority, with its timers, danger point
--  and overlap, all as locations of the message (EVC_Profiles). The
--  MA of a balise group at a main signal replaces the stored one as a
--  whole (3.8.5.1 a; infill, 3.8.5.1 b and 3.8.4.6, is phase E7). The
--  stored information accepts it only when the SSP and the gradients
--  cover it from the estimated front end to its SvL (3.7.2.3, checked by
--  the caller), and applies the deletion it asks for (Outcome_T) to the
--  other stores.
--
--  The EOA, the SvL and the release speed the supervision gets
--  (Authority): the SvL is the end of the overlap (before its time-out),
--  else the danger point, else the end of the End Section (3.8.4.5.1);
--  with a Limit of Authority there is no SvL (3.8.4.5.2) and no release
--  speed (3.13.9.4.4); the release speed is the one given with the
--  overlap or the danger point (V_RELEASEOL, V_RELEASEDP: a value, "use
--  onboard calculated release speed" or "use national value"), none for
--  the end of the End Section (3.13.9.4.4), the national one after a
--  section time-out (3.8.4.2.2 b). The EOA is its "estimated" location
--  item, the SvL and a LOA their "max" item (Table 2a: SBD and EBD
--  targets); the EOA is moved back to the SvL when a relocation put the
--  "max" item of the SvL in rear of it, so that the SvL is never before
--  the EOA (Authority's postcondition).
--
--  Timers (3.8.4): the section timers and the LOA speed timer start at
--  the passage over the first balise of the group (3.8.4.2.1 b,
--  3.8.4.3.1 b), the End Section and Overlap timers when the max safe
--  front end passes their start location (3.8.4.1.1, 3.8.4.4.1); a
--  section timer stops when the min safe front end passes its stop
--  location (3.8.4.2.3). A timer is over when its value becomes greater
--  than its time-out (1023: infinite). Their effects and the deletions
--  of A.3.4 are in Supervise and Accept below.
--
--  Level 2 (the time stamps of 3.8.4.2.1 a and 3.8.4.3.1 a) is phase E5;
--  the conditional emergency stop (A.3.4.1.2 a) and the co-operative
--  shortening (f) are E5 too.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Track_Packets.P12;
with ETCS_Track_Packets.P80;
with ETCS_Variables;        use ETCS_Variables;
with EVC_Distances;         use EVC_Distances;
with EVC_Profiles;          use EVC_Profiles;
with EVC_Supervision_Input; use EVC_Supervision_Input;
with Interfaces;            use Interfaces;

package EVC_Movement_Authority
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   Max_Sections : constant := 32;

   type Timer_T is record
      Given    : Boolean := False;
      Infinite : Boolean := False;
      Timeout  : Natural := 0;           -- ms
      Running  : Boolean := False;
      Started  : Unsigned_64 := 0;       -- on-board time, ms
   end record;

   type Section_T is record
      Finish  : Location_T := (others => <>);
      Timer   : Timer_T := (others => <>);
      Stop    : Location_T := (others => <>);
      Stopped : Boolean := False;
   end record;

   type Section_Array is array (1 .. Max_Sections) of Section_T;
   No_Section : constant Section_T := (others => <>);

   type MA_T is record
      Present          : Boolean := False;
      Sense            : Sense_T := Plus;
      Msg              : Natural := 0;
      --  the start of the first section, the location reference of the
      --  group (3.8.3.6)
      Start            : Location_T := (others => <>);
      --  the sections left (a section time-out removes it and those
      --  after it)
      Count            : Natural range 0 .. Max_Sections := 0;
      Sections         : Section_Array := (others => No_Section);
      --  V_EMA: 0, an EOA; else a LOA with this target speed
      Target_Speed     : Speed_Cms_T := 0;
      LOA_Timer        : Timer_T := (others => <>);
      End_Timer        : Timer_T := (others => <>);
      End_Start        : Location_T := (others => <>);
      Has_DP           : Boolean := False;
      DP               : Location_T := (others => <>);
      V_Release_DP     : Natural range 0 .. 127 := 0;
      Has_OL           : Boolean := False;
      OL               : Location_T := (others => <>);
      OL_Timer         : Timer_T := (others => <>);
      OL_Start         : Location_T := (others => <>);
      V_Release_OL     : Natural range 0 .. 127 := 0;
      --  3.8.4.2.2 b): the national release speed applies
      National_Release : Boolean := False;
      --  A.3.4.1.3 [11]: EOA and SvL withdrawn to the train
      Withdrawn        : Boolean := False;
      Withdrawn_EOA    : Location_T := (others => <>);
      Withdrawn_SvL    : Location_T := (others => <>);
   end record;

   --  The mode profile (packet 80)
   Max_Mode_Profiles : constant := 16;
   type Mode_Profile_T is record
      Used      : Boolean := False;
      Mode      : M_MAMODE_T := 0;     -- 0 OS, 1 SH, 2 LS
      Speed     : V_MAMODE_T := 0;     -- 127: the national value
      Start     : Location_T := (others => <>);
      Finish    : Location_T := (others => <>);
      Open      : Boolean := False;    -- SH: no length (3.12.4.2)
      --  L_ACKMAMODE in rear of Start
      Ack_Start : Location_T := (others => <>);
      --  Q_MAMODE 1: the start is a temporary SvL (3.12.4.7 a)
      SvL_At_Start : Boolean := False;
      Msg       : Natural := 0;
   end record;
   type Mode_Profile_Array is array (1 .. Max_Mode_Profiles)
     of Mode_Profile_T;
   No_Mode_Profile : constant Mode_Profile_T := (others => <>);

   --  What an operation did, and the deletion it asks of the other
   --  stores (A.3.4.1.3: beyond the new SvL [1], beyond the max safe
   --  front end [10]), for the information of messages before
   --  Delete_Before
   type Outcome_T is record
      Accepted         : Boolean := False;
      Shortened        : Boolean := False;
      Section_Expired  : Natural := 0;
      End_Expired      : Boolean := False;
      Overlap_Expired  : Boolean := False;
      LOA_Expired      : Boolean := False;
      Delete           : Boolean := False;
      Delete_X         : Dist_T := 0;
      Delete_To        : Location_T := (others => <>);
      Delete_Before    : Natural := 0;
   end record;

   function MA return MA_T
     with Global => State;

   --  Two components of MA without its copy (MA_T is over 2 KB: a
   --  function result is built on the caller's stack)
   function MA_Present return Boolean
     with Global => State,
          Post => MA_Present'Result = MA.Present;
   function MA_Sense return Sense_T
     with Global => State,
          Post => MA_Sense'Result = MA.Sense;

   --  The signalling related speed restriction (3.11.6), up to its end
   --  (A.3.4.1.3 [1] may end it)
   function V_Main_Known return Boolean
     with Global => State;
   function V_Main return Speed_Cms_T
     with Global => State;
   function V_Main_Finish return Location_T
     with Global => State;
   function V_Main_Open return Boolean
     with Global => State;
   --  3.11.6.4: a V_MAIN 0, a train trip order, was received (phase E4
   --  trips); cleared by Clear_Trip_Order
   function Trip_Ordered return Boolean
     with Global => State;

   function Mode_Profiles return Mode_Profile_Array
     with Global => State;
   --  Mode_Profiles (I) without the copy of Mode_Profiles
   function Mode_Profile (I : Positive) return Mode_Profile_T
     with Global => State,
          Pre  => I <= Max_Mode_Profiles,
          Post => Mode_Profile'Result = Mode_Profiles (I);
   --  A mode profile of SH (M_MAMODE 1) is stored
   function SH_Profile return Boolean
     with Global => State,
          Post => SH_Profile'Result
                  = (for some I in 1 .. Max_Mode_Profiles =>
                       Mode_Profiles (I).Used
                       and then Mode_Profiles (I).Mode = 1);

   --  The effective EOA (or LOA) and SvL locations of X
   function EOA_Location (X : MA_T) return Location_T is
     (if X.Withdrawn then X.Withdrawn_EOA
      elsif X.Count = 0 then X.Start
      else X.Sections (X.Count).Finish);

   function Is_LOA (X : MA_T) return Boolean is
     (not X.Withdrawn and then X.Target_Speed > 0);

   function SvL_Location (X : MA_T) return Location_T is
     (if X.Withdrawn then X.Withdrawn_SvL
      elsif Is_LOA (X) then EOA_Location (X)
      elsif X.Has_OL then X.OL
      elsif X.Has_DP then X.DP
      else EOA_Location (X));

   --  Phase E5, 3.8.2.2.1 b): a Section timer (not that of the End
   --  Section, nor the Overlap timer) running and not stopped, or the
   --  LOA speed timer, whose time-out comes within Lead_Ms of Now_Ms
   function Timer_Expiring (Now_Ms, Lead_Ms : Unsigned_64) return Boolean
     with Global => State;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   procedure Clear
     with Global => (Output => State),
          Post => not MA.Present and then not V_Main_Known
                  and then not Trip_Ordered;

   --  The MA of packet 12 of message M, not yet accepted (Present False
   --  when the packet cannot be used)
   function From_Packet (P : ETCS_Track_Packets.P12.Packet_T;
                         M : Message_T) return MA_T;

   --  3.11.6.2, 3.11.6.3: the V_MAIN of a packet 12, taken as soon as it
   --  is received; 0 is a trip order (3.11.6.4), not a speed limit
   procedure Take_V_Main (P : ETCS_Track_Packets.P12.Packet_T)
     with Global => (In_Out => State);

   procedure Clear_Trip_Order
     with Global => (In_Out => State),
          Post => not Trip_Ordered;

   --  X, whose SSP and gradients cover it (3.7.2.3), replaces the stored
   --  MA (3.8.5.1 a) and deletes the mode profile (3.12.4.3): an SvL
   --  closer than the one supervised, or one where a LOA was, is a
   --  shortening (3.8.5.1.3, 3.8.5.1.4; never with a new LOA, 3.8.5.2.4);
   --  the timers start (3.8.4.2.1 b, 3.8.4.3.1 b), the section timers
   --  whose stop location is already passed are stopped (3.8.4.2.5), and
   --  an End Section or Overlap timer whose start location is passed
   --  keeps running with the new time-out if it ran (3.8.4.1.4,
   --  3.8.4.4.5), else is over at once (3.8.4.1.3, 3.8.4.4.4).
   --  Passage_Ms: the passage over the first balise of the group.
   procedure Accept_MA (X          : MA_T;
                        T          : Origin_Table_T;
                        Train      : Train_Frame_T;
                        Passage_Ms : Unsigned_64;
                        Outcome    : out Outcome_T)
     with Global => (In_Out => State),
          Pre => X.Present,
          Post => MA.Present and then Outcome.Accepted;

   --  3.10.2.2 b) (phase E5): the EOA and SvL by the stop location of
   --  an accepted conditional emergency stop, without release speed;
   --  Updated: the EOA or LOA changed (Q_EMERGENCYSTOP 0, else 1)
   procedure Conditional_Stop (T       : Origin_Table_T;
                               Stop    : Location_T;
                               Updated : out Boolean;
                               Outcome : out Outcome_T)
     with Global => (In_Out => State),
          Post => MA.Present = MA.Present'Old
                  and then not Outcome.Accepted;

   --  The mode profile of the message of the MA just accepted
   procedure Take_Mode_Profile (P : ETCS_Track_Packets.P80.Packet_T;
                                M : Message_T)
     with Global => (In_Out => State);

   --  One cycle of the timers (3.8.4.1 to 3.8.4.4) and their effects
   procedure Supervise (T       : Origin_Table_T;
                        Train   : Train_Frame_T;
                        Now_Ms  : Unsigned_64;
                        Outcome : out Outcome_T)
     with Global => (In_Out => State),
          Post => MA.Present = MA.Present'Old;

   --  A.3.4.1.3 [1], [10]: the mode profile and the signalling related
   --  speed restriction beyond the frame position X (the location To)
   procedure Delete_Beyond (T          : Origin_Table_T;
                            X          : Dist_T;
                            To         : Location_T;
                            Before_Msg : Natural)
     with Global => (In_Out => State);

   --  A.3.1: the mode profiles ending more than Keep behind Rear
   procedure Delete_Behind (T : Origin_Table_T; Rear : Dist_T;
                            Keep : Length_T)
     with Global => (In_Out => State);

   procedure Mark (Marks : in out Origin_Marks_T)
     with Global => State;

   ---------------------------------------------------------------------
   --  For the snapshot
   ---------------------------------------------------------------------

   --  The release speed of a V_RELEASEDP or V_RELEASEOL code
   function Release (Code : Natural; V_NVREL : Speed_Cms_T)
     return Release_Speed_T
   is (case Code is
          when 126    => (Kind => Calculated_On_Board, Speed => 0),
          when 0 .. 120 => (Kind => Fixed, Speed => V5_To_Cms (Code)),
          when others => (Kind => Fixed, Speed => V_NVREL));

   --  The MA X as the supervision sees it, frame positions (phase E5:
   --  also a proposed MA not stored, 3.8.6.1 b)
   procedure Authority_Of (X       : MA_T;
                           T       : Origin_Table_T;
                           V_NVREL : Speed_Cms_T;
                           R       : out Movement_Authority_T)
     with Global => null,
          Post => R.Present = X.Present
                  and then (if R.Present
                            then A (X.Sense, R.SvL) >= A (X.Sense, R.EOA));

   --  The MA as the supervision sees it, frame positions
   procedure Authority (T       : Origin_Table_T;
                        V_NVREL : Speed_Cms_T;
                        R       : out Movement_Authority_T)
     with Global => State,
          Post => R.Present = MA.Present
                  and then (if R.Present
                            then A (MA.Sense, R.SvL) >= A (MA.Sense, R.EOA));

   ---------------------------------------------------------------------
   --  Added by e4/modes
   ---------------------------------------------------------------------

   --  4.10: entering a mode that deletes the MA, the mode profile and
   --  the signalling related speed restriction (the same modes for the
   --  three); a trip order received (V_MAIN 0) is not stored information
   --  (4.10.1.4.2 x) and stays
   procedure Delete_MA
     with Global => (In_Out => State),
          Post => not MA.Present and then not V_Main_Known
                  and then Trip_Ordered = Trip_Ordered'Old;

   --  4.6.3 [10], [25], [31], [32]: the train position confidence
   --  interval, from Min_Front to Max_Front (frame positions), overlaps
   --  a mode profile stored with the MA
   function Mode_Profile_Overlap (T         : Origin_Table_T;
                                  Min_Front : Dist_T;
                                  Max_Front : Dist_T) return Boolean
     with Global => State;

   --  Added by the procedures of phase E4: the mode the on-board is in,
   --  as an M_MAMODE (0 On Sight, 1 Shunting, 2 Limited Supervision; 3
   --  another mode), which EVC_Core sets before the stored information
   --  is evaluated. 3.12.4.7: the beginning of a mode profile is a
   --  temporary EOA "until the on-board has switched to the concerned
   --  mode"; the profiles of the mode in use are not
   procedure Set_Mode_In_Use (Code : Natural)
     with Global => (In_Out => State),
          Pre => Code <= 3,
          Post => MA = MA'Old and then Mode_Profiles = Mode_Profiles'Old
                  and then Trip_Ordered = Trip_Ordered'Old;

   --  3.12.4.7: the temporary EOA of the start of the nearest mode
   --  profile that the estimated front end Front has not reached, of a
   --  mode other than the one in use (Set_Mode_In_Use), and the
   --  temporary SvL of the cases a) to c)
   procedure Mode_Profile_Target (T       : Origin_Table_T;
                                  Front   : Dist_T;
                                  Found   : out Boolean;
                                  EOA     : out Dist_T;
                                  Has_SvL : out Boolean;
                                  SvL     : out Dist_T)
     with Global => State;

end EVC_Movement_Authority;
