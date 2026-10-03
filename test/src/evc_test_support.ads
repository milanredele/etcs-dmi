--  ETCS on-board (EVC)
--  Shared state and helpers of the evc_test regression runner: the
--  check counters, the golden/dump comparison, the capture of the
--  on-board's outputs, the simulated track (balise groups, telegrams,
--  odometer), and the speed/distance monitoring reference model used
--  by several subjects. Moved out of evc_test.adb so the subject
--  packages (EVC_Test_Language, EVC_Test_Position, ...) do not each
--  repeat it.

with Ada.Environment_Variables;
with ETCS_Bits;
with ETCS_Track_Packets.P12;
with ETCS_Track_Packets.P141;
with ETCS_Track_Packets.P21;
with ETCS_Track_Packets.P27;
with ETCS_Track_Packets.P39;
with ETCS_Track_Packets.P3;
with ETCS_Track_Packets.P41;
with ETCS_Track_Packets.P46;
with ETCS_Track_Packets.P51;
with ETCS_Track_Packets.P52;
with ETCS_Track_Packets.P5;
with ETCS_Track_Packets.P65;
with ETCS_Track_Packets.P66;
with ETCS_Track_Packets.P67;
with ETCS_Track_Packets.P68;
with ETCS_Track_Packets.P70;
with ETCS_Track_Packets.P71;
with ETCS_Track_Packets.P79;
with ETCS_Track_Packets.P80;
with ETCS_Track_Packets.P88;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P1;
with ETCS_Variables;
with EVC_Brake_Commands;
with EVC_Bytes;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Fixed;
with EVC_Limits;
with EVC_Location;
with EVC_Modes;
with EVC_Outbox;
with EVC_Ports;
with EVC_Position;
with EVC_Profiles;
with EVC_SDM;
with EVC_Supervision_Input;
with Interfaces;

package EVC_Test_Support is

   package T5 renames ETCS_Track_Packets.P5;
   package T21 renames ETCS_Track_Packets.P21;
   package T65 renames ETCS_Track_Packets.P65;
   package R0 renames ETCS_Train_Packets.P0;
   package Pos renames EVC_Position;
   package T79 renames ETCS_Track_Packets.P79;
   package R1 renames ETCS_Train_Packets.P1;
   package Prof renames EVC_Profiles;
   package Loc renames EVC_Location;
   package SIn renames EVC_Supervision_Input;
   package T3 renames ETCS_Track_Packets.P3;
   package T12 renames ETCS_Track_Packets.P12;
   package T27 renames ETCS_Track_Packets.P27;
   package T39 renames ETCS_Track_Packets.P39;
   package T51 renames ETCS_Track_Packets.P51;
   package T52 renames ETCS_Track_Packets.P52;
   package T66 renames ETCS_Track_Packets.P66;
   package T67 renames ETCS_Track_Packets.P67;
   package T68 renames ETCS_Track_Packets.P68;
   package T70 renames ETCS_Track_Packets.P70;
   package T71 renames ETCS_Track_Packets.P71;
   package T80 renames ETCS_Track_Packets.P80;
   package T88 renames ETCS_Track_Packets.P88;
   package T141 renames ETCS_Track_Packets.P141;
   package TP41 renames ETCS_Track_Packets.P41;
   package TP46 renames ETCS_Track_Packets.P46;
   package SDM renames EVC_SDM;
   package BC renames EVC_Brake_Commands;

   use type EVC_Bytes.Byte_Array;
   use type R0.Packet_T;
   use type ETCS_Variables.NID_PACKET_T;
   use type R1.Packet_T;
   use type ETCS_Variables.NID_BG_T;
   use type ETCS_Variables.D_LRBG_T;
   use type ETCS_Variables.NID_C_T;
   use type ETCS_Variables.Q_SCALE_T;
   use type ETCS_Variables.L_DOUBTOVER_T;
   use type ETCS_Variables.L_DOUBTUNDER_T;
   use type ETCS_Variables.Q_DIRLRBG_T;
   use type ETCS_Variables.Q_DLRBG_T;
   use type ETCS_Variables.Q_DIRTRAIN_T;
   use type ETCS_Variables.V_TRAIN_T;
   use type ETCS_Variables.M_MODE_T;
   use type ETCS_Variables.M_LEVEL_T;
   use type ETCS_Variables.Q_INTEGRITY_T;
   use type SIn.Release_Speed_Kind_T;
   use type SIn.Brake_Position_T;
   use type SIn.Brake_Model_T;
   use type SDM.Monitoring_T;
   use type EVC_Limits.Margin_Kind_T;
   use EVC_Modes;
   use EVC_Ports;
   use Interfaces;

   ---------------------------------------------------------------------
   --  Results
   ---------------------------------------------------------------------

   Checks   : Natural := 0;
   Failures : Natural := 0;

   Golden_Dir     : constant String := "test/golden/evc/";
   DMI_Golden_Dir : constant String := "test/golden/";

   function Updating return Boolean is
     (Ada.Environment_Variables.Exists ("UPDATE"));

      procedure Check (Condition : Boolean; What : String);

      function Read_Line (Path : String) return String;

   ---------------------------------------------------------------------
   --  Output capture: every Take appends to Capture, a checkpoint takes
   --  the digest of Capture
   ---------------------------------------------------------------------

   Out_Buf  : Byte_Array (1 .. EVC_Outbox.Capacity);
   Out_Last : Natural := 0;

   Capture      : Byte_Array (1 .. 256 * 1024);
   Capture_Last : Natural := 0;

   --  The records of the last Take are whole (Parse, below)
   Parsed : Boolean := True;
   function Parse return Boolean;

      procedure Reset_Capture;

      procedure Take;

      function Digest (Data : Byte_Array) return String;

   --  A digest against test/golden/evc/<Name>.sha256
      procedure Check_Digest (Name : String; Actual : String);

   --  The digest of the capture against test/golden/evc/<Name>.sha256;
   --  with EVC_DUMP set, the capture itself to $EVC_DUMP/<Name>.bin
      procedure Check_Golden (Name : String);

   ---------------------------------------------------------------------
   --  The records of the last Take (EVC_Outbox: port u8, length u16,
   --  payload)
   ---------------------------------------------------------------------

   type Rec is record
      Port        : Port_T;
      First, Last : Natural;  -- the payload in Out_Buf
   end record;
   Recs      : array (1 .. 1024) of Rec;
   Rec_Count : Natural := 0;

   --  Split Out_Buf (1 .. Out_Last) into records; False when the bytes
   --  are not a sequence of whole records

   function Rec_Length (I : Positive) return Natural is
     (Recs (I).Last - Recs (I).First + 1);

   --  Byte N (1 = first) of the payload of record I
   function Byte_At (I : Positive; N : Positive) return Natural is
     (Natural (Out_Buf (Recs (I).First + N - 1)));

   --  The DMI record of this message type in the last Take; 0 if none
      function Find_DMI (The_Type : Byte) return Natural;

      function Count_Port (Port : Port_T) return Natural;

   --  The mode code of the MSG_MODE_LEVEL of the last Take (payload byte
   --  1, after the 5 byte frame header), 16#FFFF# when there is none
      function DMI_Mode_Byte return Natural;

      function DMI_Level_Byte return Natural;

   --  Field N (1 = data .. 11 = answer) of the MSG_ONBOARD of the last
   --  Take
      function Onboard_Field (N : Positive) return Natural;

   function Img (N : Natural) return String is (Natural'Image (N));

   ---------------------------------------------------------------------
   --  Inputs
   ---------------------------------------------------------------------

      procedure Input (Port : Port_T; Bytes : Byte_Array);

   --  A DMI protocol frame
   function Frame (The_Type : Byte; Payload : Byte_Array)
     return Byte_Array
   is (Byte_Array'(The_Type, Byte (Payload'Length mod 256),
                   Byte (Payload'Length / 256 mod 256), 0, 0)
       & Payload);

   --  A 32 bit field, little endian, two's complement
      function U32 (V : Integer_64) return Byte_Array;

   function U16 (V : Unsigned_16) return Byte_Array is
     (Byte (V mod 256), Byte (V / 256));

   --  An odometer sample (EVC_Ports): the counters d_est, over, under,
   --  the speeds, the movement, the cold movement detection
   function Odometer_Payload
     (D_Est               : Integer_64;
      Over, Under         : Integer_64;
      V_Est, V_Min, V_Max : Unsigned_16;
      Movement            : Byte;
      Cold                : Byte := 0;
      Cold_Distance       : Unsigned_16 := 0) return Byte_Array
   is (U32 (D_Est) & U32 (Over) & U32 (Under)
       & U16 (V_Est) & U16 (V_Min) & U16 (V_Max)
       & Byte_Array'(Movement, Cold) & U16 (Cold_Distance));

   --  A telegram of N_Bits bits behind a detection stamp, with Extra
   --  bytes more or fewer than its shape asks for
      function BTM_Payload (N_Bits : Natural; Extra : Integer := 0)
     return Byte_Array;

   --  A radio message whose L_MESSAGE says L_Message and whose length is
   --  Length
      function RTM_Payload (L_Message : Natural; Length : Natural)
     return Byte_Array;

   Isolate : constant Byte_Array :=
     Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (20, 0, 0));
   subtype Writer_T is ETCS_Bits.Writer (ETCS_Bits.Max_Bytes);
   subtype Reader_T is ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
   --  The BTM payload of a telegram of Bits bits (EVC_Ports), its
   --  balise detected at the odometer reading Stamp
      function BTM_Of (Data  : Byte_Array;
                    Bits  : Natural;
                    Stamp : Integer_64 := 0) return Byte_Array;
   Encodes_OK : Boolean := True;

      procedure Put (W : in out Writer_T; P : T5.Packet_T);

      procedure Put (W : in out Writer_T; P : T21.Packet_T);

      procedure Put (W : in out Writer_T; P : T65.Packet_T);

      procedure Put (W : in out Writer_T; P : R0.Packet_T);

   ---------------------------------------------------------------------
   --  E2: the train position (evc/evc_position.ads)
   --
   --  A small track model drives the on-board: balise groups at track
   --  positions (cm), their telegrams built with the encoder, and a
   --  train whose antenna moves along the track. The odometer measures
   --  the true movement with an error of Error_Per_Mille and declares
   --  over- and under-reading amounts of Bound_Per_Mille of every
   --  movement. Every cycle (100 ms) the train moves one step; the
   --  balises crossed in that step go to the BTM port with the odometer
   --  reading at their crossing as stamp, then the odometer sample, then
   --  Tick. Cab A points to growing track positions.
   ---------------------------------------------------------------------


   Spacing : constant := 300;   -- between the balises of a group, cm

   type Group_Def is record
      NID_BG      : ETCS_Variables.NID_BG_T := 1;
      At_Cm       : Integer_64 := 0;     -- track position of balise 1
      Balises     : Positive := 2;
      --  the nominal direction points to falling track positions
      Reversed    : Boolean := False;
      Linked      : Boolean := True;
      --  N_PIG + 1 of a balise that is not read, 0: all are
      Skip        : Natural := 0;
      --  balises 1 and 2 duplicate each other
      Dup_1_2     : Boolean := False;
      Has_Linking : Boolean := False;
      Linking     : T5.Packet_T;
      Has_Geo     : Boolean := False;
      Geo         : T79.Packet_T;
      Reposition  : Boolean := False;
   end record;

   Max_Groups : constant := 12;
   Track      : array (1 .. Max_Groups) of Group_Def;
   Track_N    : Natural := 0;

      procedure Add_Group (G : Group_Def);

   function Balise_At (G : Group_Def; K : Natural) return Integer_64 is
     (if G.Reversed then G.At_Cm - Integer_64 (K) * Spacing
      else G.At_Cm + Integer_64 (K) * Spacing);

   --  The telegram of balise K (N_PIG) of G, with the BTM stamp
      function Telegram_Of (G : Group_Def; K : Natural; Stamp : Integer_64)
     return Byte_Array;

   --  The simulated train
   Train_Cm        : Integer_64 := 0;   -- true position of the antenna
   Odo_D           : Integer_64 := 0;   -- the odometer's counters
   Odo_Over        : Integer_64 := 0;
   Odo_Under       : Integer_64 := 0;
   Error_Per_Mille : Integer_64 := 0;
   Bound_Per_Mille : Integer_64 := 20;
   Speed_Cms       : Unsigned_16 := 1000;
   Cold_Byte       : Byte := 0;
   Cold_Distance   : Unsigned_16 := 0;

   --  What the runs saw: JRU records by event, the last bytes of each,
   --  the report triggers, the last geographical position on the DMI
   type JRU_Seen_T is array (0 .. 15) of Natural;
   JRU_Seen  : JRU_Seen_T := (others => 0);
   type JRU_Bytes_T is array (0 .. 15, 2 .. 4) of Natural;
   JRU_Last  : JRU_Bytes_T := (others => (others => 0));
   Seen      : Pos.Triggers_T := Pos.No_Triggers;
   Geo_Seen  : Unsigned_32 := EVC_DMI_Port.Geo_Unknown;
   Geo_Count : Natural := 0;

      procedure Forget;

      procedure Collect;

   --  The odometer sample of now
      procedure Sample (Moving : Integer);

      procedure Cycle;

   --  A new track, the train at Start_Cm, the odometer reading Start_Cm,
   --  one sample at standstill (the frame starts there), cab A active.
   --  Phase E4: the scenarios of E2 and E3 run in FS, level 1, with the
   --  default train (EVC_Core.Set_Mode_For_Test), the mode in which the
   --  linking is checked and the information of the groups is accepted
   --  and used, as they were written before the modes
   Legacy_Mode : constant Mode_T := M_FS;

      procedure Start_Track (Start_Cm : Integer_64 := 0);

   --  One step of Step_Cm (signed): the balises crossed, then the sample
      procedure Step (Step_Cm : Integer_64);

   --  Move to the track position To_Cm in steps of Step_Cm, then stand
      procedure Run_To (To_Cm : Integer_64; Step_Cm : Integer_64 := 1000);

      procedure Stand;

   function Id (NID_BG : Natural) return Natural is
     (123 * 2**14 + NID_BG);

   --  The identity of the last JRU record of an event
   function JRU_Id (Event : Natural) return Natural is
     (JRU_Last (Event, 2) + 256 * JRU_Last (Event, 3)
      + 65_536 * JRU_Last (Event, 4));

   --  Linking from a group: to groups at the cumulated metres of
   --  Distances, identities NID, all nominal, Q_LOCACC Locacc
   type Nat_List is array (Positive range <>) of Natural;

      function Link_To (D_Links  : Nat_List;
                     NIDs     : Nat_List;
                     Locacc   : Natural := 5;
                     Reaction : Natural := 1;
                     Nominal  : Boolean := True) return T5.Packet_T;

      function Group (NID : Natural; At_M : Integer_64;
                   Balises : Positive := 2) return Group_Def;

      function With_Links (G : Group_Def; L : T5.Packet_T) return Group_Def;

   --  Packet 0 and 1 through the encoder and back
      function Round_Trip (P : R0.Packet_T) return Boolean;

      function Round_Trip (P : R1.Packet_T) return Boolean;

   --  The first balise group passed: the position becomes valid, the
   --  group the LRBG and the SOLR (3.6.1.4, 3.6.2.2.2 a, 3.6.4.2.2 b),
   --  the confidence interval from Q_NVLOCACC and the odometer
   --  (3.6.4.1.3, 3.6.4.1.5); the position report (3.6.5.1.2)
   ---------------------------------------------------------------------
   --  E3 (profiles): the stored information
   ---------------------------------------------------------------------

   --  The track of E2 carries more packets: the bits of Extras (G, K)
   --  go into the telegram of balise K of group G, after what
   --  Telegram_Of writes; Country (G) is the NID_C of its telegrams


   type Extra_T is record
      Bits : Natural := 0;
      Data : Byte_Array (1 .. 128) := (others => 0);
   end record;
   Extras  : array (1 .. Max_Groups, 0 .. 1) of Extra_T;
   Country : array (1 .. Max_Groups) of ETCS_Variables.NID_C_T :=
     (others => 123);

   --  The bits of W appended to Extras (G, K); a telegram holds 772 bits
   --  of packets (830 less the header and packet 255)
      procedure Carry_Writer (G : Positive; K : Natural; W : Writer_T);

      procedure Finish_Carry (G : Positive; K : Natural; W : Writer_T;
                           OK : Boolean);

      procedure Carry (G : Positive; K : Natural; P : T3.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T12.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T21.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T27.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T39.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T51.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T52.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T65.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T66.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T67.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T68.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T70.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T71.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T80.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T88.Packet_T);
      procedure Carry (G : Positive; K : Natural; P : T141.Packet_T);


      procedure Carry (G : Positive; K : Natural; P : TP41.Packet_T);

      procedure Carry (G : Positive; K : Natural; P : TP46.Packet_T);

   --  Telegram_Of with the extras of the group
      function Telegram_X (G : Positive; K : Natural; Stamp : Integer_64)
     return Byte_Array;

   --  What the E3 runs saw: the last MSG_TRACK_COND and MSG_PLANNING, the
   --  JRU records of the stored information by information and change
   TC_Payload   : Byte_Array (1 .. 64) := (others => 0);
   TC_Length    : Natural := 0;
   TC_Frames    : Natural := 0;
   Plan_Payload : Byte_Array (1 .. 512) := (others => 0);
   Plan_Length  : Natural := 0;
   Plan_Frames  : Natural := 0;
   type SI_Seen_T is array (0 .. 17, 0 .. 15) of Natural;
   SI_Seen      : SI_Seen_T := (others => (others => 0));
   SI_Detail    : SI_Seen_T := (others => (others => 0));

      procedure Collect_E3;

   --  What the E4 runs saw (phase E4, e4/modes): the JRU records of the
   --  levels (event 40) and of the mission (event 41) by kind, the last
   --  bytes 3 and 4 of each kind; the system status messages started
   --  (MSG_SYSTEM_STATUS by catalogue entry); the last brake indication
   --  of MSG_STATUS and the last TIU output (commands + 256 * reasons)
   type E4_Seen_T is array (40 .. 41, 0 .. 15) of Natural;
   E4_Seen    : E4_Seen_T := (others => (others => 0));
   E4_B3      : E4_Seen_T := (others => (others => 0));
   E4_B4      : E4_Seen_T := (others => (others => 0));
   SS_Seen    : array (0 .. 63) of Natural := (others => 0);
   SS_Ended   : array (0 .. 63) of Natural := (others => 0);
   Last_Brake : Natural := 0;
   Last_TIU   : Natural := 0;
   --  EVC_JRU_Records: event 11 by M_DRIVERACTIONS, the events 38 and the
   --  last one's cab A + 2 * cab B, the events 45 by M_TRACKCOND_TI and
   --  the last one's phase
   JRU_Actions  : array (0 .. 63) of Natural := (others => 0);
   JRU_Cabs     : Natural := 0;
   JRU_Cab_Last : Natural := 0;
   JRU_TCs      : array (0 .. 15) of Natural := (others => 0);
   JRU_TC_Phase : array (0 .. 15) of Natural := (others => 0);

      procedure Collect_E4;

      procedure Cycle_X;

   --  The move of Step_X without its odometer sample and cycle: the
   --  telegrams of the balises crossed, the train and the odometer's
   --  counters moved
      procedure Feed_X (Step_Cm : Integer_64);

   --  Step of E2 with the telegrams of Telegram_X
      procedure Step_X (Step_Cm : Integer_64);

      procedure Run_X (To_Cm : Integer_64; Step_Cm : Integer_64 := 1000);

   --  Standing for Ms
      procedure Stand_X (Ms : Natural);

      procedure Start_X (Start_Cm : Integer_64 := 0);

   ---------------------------------------------------------------------
   --  Packets
   ---------------------------------------------------------------------

   --  One element of an SSP or a gradient profile: the distance from the
   --  previous one (m), the value (km/h for the SSP, signed per mille for
   --  the gradient; End_Mark: the profile ends there), the train length
   --  delay of an SSP element
   End_Mark : constant := 999;
   type Profile_Item is record
      D_M   : Natural;
      Value : Integer;
      Delay_Length : Boolean := False;
   end record;
   type Profile_List is array (Positive range <>) of Profile_Item;

   function V_Static (Kmh : Integer) return ETCS_Variables.V_STATIC_T is
     (if Kmh = End_Mark then 127 else ETCS_Variables.V_STATIC_T (Kmh / 5));

      function SSP (L : Profile_List) return T27.Packet_T;

   type Grad_Item is record
      D_M   : Natural;
      Value : Integer;
   end record;
   type Grad_List is array (Positive range <>) of Grad_Item;

      function Grad (L : Grad_List) return T21.Packet_T;

   --  An MA of sections of these lengths (m), the last the End Section;
   --  no timer, no danger point, no overlap
      function MA_Of (Lengths : Nat_List; V_Main_Kmh : Natural := 120)
     return T12.Packet_T;

   --  The frame position of a location of the stored information
   function Est (L : Prof.Location_T) return Integer_64 is
     (Integer_64 (Prof.Frame (Prof.Origin_Table, L, Loc.Estimated_Item)));
   function Min_X (L : Prof.Location_T) return Integer_64 is
     (Integer_64 (Prof.Frame (Prof.Origin_Table, L, Loc.Min_Item)));
   function Max_X (L : Prof.Location_T) return Integer_64 is
     (Integer_64 (Prof.Frame (Prof.Origin_Table, L, Loc.Max_Item)));

   --  The MRSP of the snapshot is Starts / Speeds (frame positions along
   --  Plus, cm/s; the first start is the start of the axis)
   type I64_List is array (Positive range <>) of Integer_64;

      function MRSP_Is (Starts : I64_List; Speeds : Nat_List) return Boolean;

   --  3.13.7: no step of the MRSP above a source it overlaps, checked on
   --  the steps and the sources the stored information exposes
      function MRSP_Below_Sources return Boolean;

   --  Field access of the last MSG_PLANNING payload
   function Plan_U16 (Offset : Natural) return Natural is
     (Natural (Plan_Payload (Offset + 1))
      + 256 * Natural (Plan_Payload (Offset + 2)));

   --  The last MSG_TRACK_COND shows this symbol
      function TC_Shows (Kind : Natural) return Boolean;
   ---------------------------------------------------------------------
   --  E3: speed and distance monitoring (EVC_SDM, EVC_Brake_Commands
   --  and the units under them)
   ---------------------------------------------------------------------


   subtype LF is Long_Float;

   --  km/h in cm/s, rounded down (as the stored information converts
   --  the V_ variables)
   function Cms (Kmh : LF) return SIn.Speed_Cms_T is
     (SIn.Speed_Cms_T (LF'Floor (Kmh * 1000.0 / 36.0)));

   function Kmh_Of (Cms_V : EVC_Fixed.Num) return LF is
     (LF (Cms_V) * 0.036);

      function Img_LF (X : LF) return String;

   --  A snapshot with an MRSP of 140 km/h from 0, flat, a passenger
   --  train of 400 m, lambda 135 %, 140 km/h, and the national values of
   --  A.3.2, the train at 0 at standstill, the position valid
      function Base_Snapshot return SIn.Snapshot_T;

   --  The train at At_Cm, the confidence interval +/- Doubt, at V
      procedure Place (S     : in out SIn.Snapshot_T;
                    At_Cm : Integer_64;
                    V     : SIn.Speed_Cms_T;
                    Doubt : Integer_64 := 1_000);

   --  An end of authority at EOA_M, the SvL SvL_M further, a release speed
      procedure Give_MA (S       : in out SIn.Snapshot_T;
                      EOA_M   : Natural;
                      Over_M  : Natural := 0;
                      Release : SIn.Release_Speed_Kind_T := SIn.None;
                      V_Rel   : SIn.Speed_Cms_T := 0;
                      LOA_Kmh : LF := 0.0);

   ---------------------------------------------------------------------
   --  The reference: the formulas of 3.13 and A.3.7 to A.3.9 in floating
   --  point, from the snapshot, with the exact values of every boundary
   --  (V_lim, the km/h limits), no rounding; its curves are walked the
   --  way 3.13.8.1.3 says, arc by arc, in floating point
   ---------------------------------------------------------------------

   R_Inf : constant LF := 1.0E12;

   type R_Step is record
      Upper : LF;   -- cm/s, the last one R_Inf
      Value : LF;   -- mm/s² or a factor
   end record;
   type R_Step_Array is array (1 .. 16) of R_Step;
   type R_Fn is record
      Count : Natural := 0;
      S     : R_Step_Array := (others => (R_Inf, 0.0));
   end record;

      procedure R_Add (F : in out R_Fn; Upper, Value : LF);

   --  The step of v: v <= Upper, or with Rising v < Upper
      function R_Eval (F : R_Fn; V : LF; Rising : Boolean) return LF;

   --  A.3.7: A_basic (V)
      function R_Basic (Lambda_O : Natural) return R_Fn;

      function R_Curve_Of (C : SIn.Decel_Curve_T) return R_Fn;

   --  The reference model: A_brake_safe, A_brake_service and
   --  A_brake_normal_service (no special brakes), the thresholds of the
   --  speed, the gradient profile compensated
   type R_Model_T is record
      Safe, Service, Normal : R_Fn;
      Kv                    : R_Fn;   -- Kv_int (lambda), factors
      Kr                    : LF := 1.0;
      Kdry, Kwet            : R_Fn;   -- gamma, factors
      Avadh                 : LF := 0.0;
      Lambda                : Boolean := True;
      Kn_Plus, Kn_Minus     : R_Fn;
      Up, Down              : LF := 0.0;   -- rotating masses
   end record;

   Max_R_Points : constant := 600;
   type R_Point is record
      Start     : LF;
      Gradient  : LF;
      A_Grad    : LF;
   end record;
   type R_Points is array (1 .. Max_R_Points) of R_Point;
   type R_Profile_T is record
      Count  : Natural := 0;
      Points : R_Points;
   end record;

      function R_Model (S : SIn.Snapshot_T) return R_Model_T;

   --  3.13.6.2.1.4: A_brake_safe (V)
   function R_Safe (M : R_Model_T; V : LF; Rising : Boolean) return LF is
     (if M.Lambda
      then R_Eval (M.Safe, V, Rising) * R_Eval (M.Kv, V, Rising) * M.Kr
      else R_Eval (M.Safe, V, Rising) * R_Eval (M.Kdry, V, Rising)
           * (R_Eval (M.Kwet, V, Rising)
              + M.Avadh * (1.0 - R_Eval (M.Kwet, V, Rising))));

   --  3.13.4: the profile along ahead coordinates
      function R_Profile (S : SIn.Snapshot_T; M : R_Model_T) return R_Profile_T;

   type R_Kind is (R_EBD, R_SBD, R_GUI);

      function R_Accel (M : R_Model_T; P : R_Profile_T; K : R_Kind;
                     Seg : Positive; V : LF; Rising : Boolean) return LF;

   --  The speed thresholds of the model around V
      function R_Next_Up (M : R_Model_T; V : LF) return LF;

      function R_Next_Down (M : R_Model_T; V : LF) return LF;

      function R_Segment (P : R_Profile_T; X : LF) return Positive;

   --  The segment rearwards of X (walking rearwards from a boundary)
      function R_Segment_Below (P : R_Profile_T; X : LF) return Positive;

   type R_Curve is record
      Kind     : R_Kind;
      Anchor   : LF;
      Anchor_V : LF;
      Floor_V  : LF;
   end record;

   --  Walk rearwards from the anchor to X_Goal or to the speed V_Goal:
   --  the location reached and the speed there. The speed is kept
   --  exactly at the thresholds it reaches.
      procedure R_Back (M : R_Model_T; P : R_Profile_T; C : R_Curve;
                     X_Goal, V_Goal : LF; X, V : out LF);

   --  Walk forwards from the anchor to X_Goal or down to V_Goal
      procedure R_Forward (M : R_Model_T; P : R_Profile_T; C : R_Curve;
                        X_Goal, V_Goal : LF; X, V : out LF);

      function R_Speed_At (M : R_Model_T; P : R_Profile_T; C : R_Curve;
                        X : LF) return LF;

      function R_Location_Of (M : R_Model_T; P : R_Profile_T; C : R_Curve;
                           V : LF) return LF;

   --  3.13.9.2.3: dV_ebi / sbi / warning in cm/s, exact
      function R_Margin (Kind : EVC_Limits.Margin_Kind_T; V : LF) return LF;

   ---------------------------------------------------------------------
   --  The kernel against the reference
   ---------------------------------------------------------------------

   Compared      : Natural := 0;
   Unsafe        : Natural := 0;
   --  the largest distance by which a kernel location lies behind the
   --  reference (cm, and relative to the distance from the anchor), and
   --  the largest amount a kernel speed lies below it (cm/s)
   Worst_Loc     : LF := 0.0;
   Worst_Loc_Rel : LF := 0.0;
   Worst_Speed   : LF := 0.0;

   --  A location of a limit or a curve: never beyond the reference (the
   --  float's own error aside), behind it by at most 1 m + 0.5 % of the
   --  distance Span it was computed over
      procedure Compare_Location (What   : String;
                               Kernel : EVC_Fixed.Num;
                               Ref    : LF;
                               Span   : LF);

   --  A speed of a curve or a limit: never above the reference, below by
   --  at most 3 cm/s (0.1 km/h)
      procedure Compare_Speed (What : String; Kernel : EVC_Fixed.Num; Ref : LF);

   type Train_Case is
     (Lambda_60, Lambda_100, Lambda_135, Lambda_180, Lambda_250,
      Freight_P_100, Freight_G_135, Gamma_Train);

   type Gradient_Case is (Flat, Uphill, Downhill, Mixed, Steep);

      function Case_Snapshot (T : Train_Case; G : Gradient_Case)
     return SIn.Snapshot_T;

   --  3.13.8: the curves (EBD of an SvL and of an MRSP target, SBD of an
   --  EOA, GUI), 3.13.9.3: the limits, against the reference
   Sup : SIn.Snapshot_T;

      procedure Sup_Cycle (Dt : Natural := 100);

      procedure Sup_Start (S : SIn.Snapshot_T);

   function Res return SDM.Result_T is (EVC_Core.Supervision);
   function Cmd return BC.Commands_T is (EVC_Core.Brake_Commands);

   --  The train of the scenario at At_Cm (the confidence interval
   --  +/- 10 m), moving ahead at V
      procedure Move (At_Cm : Integer_64; V : SIn.Speed_Cms_T);

   --  MSG_SPEED_STATE of the last Take, field by field
   type Speed_Fields is record
      Found                     : Boolean := False;
      V_Cur, V_Perm, V_Target   : Natural := 0;
      V_Release, V_SBI, V_Wsl   : Natural := 0;
      D_Target                  : Natural := 0;
      Monitoring, Dial, Flags   : Natural := 0;
      Status, MRDT              : Natural := 0;
   end record;

      function Speed_Frame return Speed_Fields;

   --  The TIU output of the last Take: commands + 256 * reasons (u16),
   --  16#FFFF# when there is none
      function TIU_Out return Natural;

   --  The brake field of the MSG_STATUS of the last Take, 16#FFFF# when
   --  there is none
      function Status_Brake return Natural;

      function JRU_Count (Event : Natural) return Natural;

   --  3.13.10.3: ceiling speed monitoring, Tables 5 to 7; the TIU output
   --  and MSG_SPEED_STATE field by field
   generic
      with function Brake_When return Boolean;
      with function Stop_When return Boolean;
   procedure Drive (X      : in out Integer_64;
                    V      : in out SIn.Speed_Cms_T;
                    Decel  : Natural;
                    Cycles : Natural);


   function Never return Boolean is (False);
   function In_TSM return Boolean is (Res.Monitoring = SDM.TSM);

   --  3.13.8.2.1 a), 3.13.10.4.2, .5, .7, Table 16 [1], [3]: an MRSP
   --  target: TSM, the target speed and distance shown, CSM once the max
   --  safe front end passed it
   Mission_Group_M : constant := -12;

      procedure Mission_Track (Q_NVEMRRLS : Natural := 1);

end EVC_Test_Support;
