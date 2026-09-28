--  ETCS on-board (EVC)
--  Headless golden runner for EVC_Core. Drives the on-board in process
--  and compares what it outputs against test/golden/evc/*.sha256: a
--  golden is the SHA-256 of the output bytes (the records of
--  EVC_Outbox, every port) taken since the start of a named checkpoint.
--  Besides the digests the scenarios decode what matters (the mode byte
--  the DMI gets, the counts of rejected inputs, ...).
--
--  The scenarios of phase E1 test the language (evc/language): every
--  packet of the catalogue encoded and decoded (boundaries and random
--  valid packets, with the coverage of every condition and loop),
--  telegrams and radio messages built, parsed, damaged, and received by
--  the core on the BTM and RTM ports.
--
--  The scenarios of phase E2 drive the train position with a small track
--  model (balise groups with positions, sizes, linking, geographical
--  information) and a simulated odometer with a chosen error model: first
--  group, linking with its windows, missed, early, unexpected and
--  wrongly oriented groups, single balise groups and the report on two
--  groups, the geographical position on the DMI, odometer accuracy,
--  cold movement, orientation from the cab, virtual positions, report
--  triggers, round trips of the position report packets.
--
--  One scenario runs the whole chain: the DMI port of EVC_Core into
--  DMI_Core, and the picture is compared pixel by pixel with the one
--  EVC_Mock draws at start, itself checked against the DMI golden
--  test/golden/mission_sb.sha256 (read only, never recorded from here).
--
--  Usage:  obj/evc_test            compare against goldens
--          UPDATE=1 obj/evc_test   (re)record the goldens of test/golden/evc
--          VERBOSE=1 obj/evc_test  list passing checks too

pragma Ada_2012;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Streams;  use Ada.Streams;
with Ada.Text_IO;  use Ada.Text_IO;
with GNAT.SHA256;
with DMI_Core;
with DMI_Protocol;
with DMI_Status;
with Display.Screen;
with Display.Screen.Files;
with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Language_Random;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Telegram;
with ETCS_Track_Packets.P0;
with ETCS_Track_Packets.P2;
with ETCS_Track_Packets.P5;
with ETCS_Track_Packets.P21;
with ETCS_Track_Packets.P16;
with ETCS_Track_Packets.P45;
with ETCS_Track_Packets.P58;
with ETCS_Track_Packets.P65;
with ETCS_Track_Packets.P73;
with ETCS_Track_Packets.P79;
with ETCS_Track_Packets.P140;
with ETCS_Track_Packets.P3;
with ETCS_Track_Packets.P12;
with ETCS_Track_Packets.P27;
with ETCS_Track_Packets.P39;
with ETCS_Track_Packets.P51;
with ETCS_Track_Packets.P66;
with ETCS_Track_Packets.P67;
with ETCS_Track_Packets.P68;
with ETCS_Track_Packets.P70;
with ETCS_Track_Packets.P71;
with ETCS_Track_Packets.P80;
with ETCS_Track_Packets.P88;
with ETCS_Track_Packets.P141;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P1;
with ETCS_Train_Packets.P4;
with ETCS_Variables;
with EVC_Bytes;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Distances;
with EVC_Driver;
with EVC_Linking;
with EVC_Location;
with EVC_Mock;
with EVC_Modes;    use EVC_Modes;
with EVC_Odometry;
with EVC_Outbox;
with EVC_Ports;    use EVC_Ports;
with EVC_Position;
with EVC_Received;
with EVC_Movement_Authority;
with EVC_National_Values;
with EVC_Origins;
with EVC_Profiles;
with EVC_Stored_Information;
with EVC_Supervision_Input;
with EVC_Track_Conditions;
with EVC_Track_Description;
with EVC_Train_Data;
with General_Parameters;
with Interfaces;   use Interfaces;

procedure EVC_Test is

   use type EVC_Core.Cycle_T;
   use type EVC_Core.Time_Ms_T;
   use type EVC_Bytes.Byte_Array;

   ---------------------------------------------------------------------
   --  Results
   ---------------------------------------------------------------------

   Checks   : Natural := 0;
   Failures : Natural := 0;

   Golden_Dir     : constant String := "test/golden/evc/";
   DMI_Golden_Dir : constant String := "test/golden/";

   function Updating return Boolean is
     (Ada.Environment_Variables.Exists ("UPDATE"));

   procedure Check (Condition : Boolean; What : String) is
   begin
      Checks := Checks + 1;
      if Condition then
         if Ada.Environment_Variables.Exists ("VERBOSE") then
            Put_Line ("pass: " & What);
         end if;
      else
         Failures := Failures + 1;
         Put_Line ("FAIL: " & What);
      end if;
   end Check;

   function Read_Line (Path : String) return String is
      F : File_Type;
   begin
      Open (F, In_File, Path);
      declare
         Line : constant String := Get_Line (F);
      begin
         Close (F);
         return Line;
      end;
   end Read_Line;

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

   procedure Reset_Capture is
   begin
      Capture_Last := 0;
   end Reset_Capture;

   procedure Take is
      Count : Natural;
   begin
      EVC_Core.Take_Outputs (Out_Buf, Out_Last);
      Count := Natural'Min (Out_Last, Capture'Last - Capture_Last);
      Capture (Capture_Last + 1 .. Capture_Last + Count) :=
        Out_Buf (1 .. Count);
      Capture_Last := Capture_Last + Count;
      Parsed := Parse;
   end Take;

   function Digest (Data : Byte_Array) return String is
      Text : String (1 .. Data'Length);
   begin
      for I in Text'Range loop
         Text (I) := Character'Val (Data (Data'First + I - 1));
      end loop;
      return GNAT.SHA256.Digest (Text);
   end Digest;

   --  A digest against test/golden/evc/<Name>.sha256
   procedure Check_Digest (Name : String; Actual : String) is
      Path : constant String := Golden_Dir & Name & ".sha256";
   begin
      if Updating then
         Ada.Directories.Create_Path (Golden_Dir);
         declare
            F : File_Type;
         begin
            Create (F, Out_File, Path);
            Put_Line (F, Actual);
            Close (F);
         end;
         Put_Line ("recorded: " & Name);
         Checks := Checks + 1;
      elsif not Ada.Directories.Exists (Path) then
         Check (False, "golden missing: " & Name & " (run with UPDATE=1)");
      else
         Check (Read_Line (Path) = Actual, "golden " & Name);
      end if;
   end Check_Digest;

   --  The digest of the capture against test/golden/evc/<Name>.sha256
   procedure Check_Golden (Name : String) is
   begin
      Check_Digest (Name, Digest (Capture (1 .. Capture_Last)));
   end Check_Golden;

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
   function Parse return Boolean is
      Pos    : Natural := 0;
      Length : Natural;
   begin
      Rec_Count := 0;
      while Pos < Out_Last loop
         if Out_Last - Pos < EVC_Outbox.Record_Header
           or else Natural (Out_Buf (Pos + 1)) > Port_T'Pos (Port_T'Last)
           or else Rec_Count = Recs'Last
         then
            return False;
         end if;
         Length := Natural (Out_Buf (Pos + 2))
                   + 256 * Natural (Out_Buf (Pos + 3));
         if Length > Out_Last - Pos - EVC_Outbox.Record_Header then
            return False;
         end if;
         Rec_Count := Rec_Count + 1;
         Recs (Rec_Count) :=
           (Port  => Port_T'Val (Out_Buf (Pos + 1)),
            First => Pos + 4,
            Last  => Pos + 3 + Length);
         Pos := Pos + 3 + Length;
      end loop;
      return True;
   end Parse;

   function Rec_Length (I : Positive) return Natural is
     (Recs (I).Last - Recs (I).First + 1);

   --  Byte N (1 = first) of the payload of record I
   function Byte_At (I : Positive; N : Positive) return Natural is
     (Natural (Out_Buf (Recs (I).First + N - 1)));

   --  The DMI record of this message type in the last Take; 0 if none
   function Find_DMI (The_Type : Byte) return Natural is
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = DMI and then Rec_Length (I) >= 1
           and then Out_Buf (Recs (I).First) = The_Type
         then
            return I;
         end if;
      end loop;
      return 0;
   end Find_DMI;

   function Count_Port (Port : Port_T) return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = Port then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Port;

   --  The mode code of the MSG_MODE_LEVEL of the last Take (payload byte
   --  1, after the 5 byte frame header), 16#FFFF# when there is none
   function DMI_Mode_Byte return Natural is
      I : constant Natural := Find_DMI (EVC_DMI_Port.MSG_MODE_LEVEL);
   begin
      return (if I = 0 then 16#FFFF# else Byte_At (I, 6));
   end DMI_Mode_Byte;

   function DMI_Level_Byte return Natural is
      I : constant Natural := Find_DMI (EVC_DMI_Port.MSG_MODE_LEVEL);
   begin
      return (if I = 0 then 16#FFFF# else Byte_At (I, 7));
   end DMI_Level_Byte;

   --  Field N (1 = data .. 11 = answer) of the MSG_ONBOARD of the last
   --  Take
   function Onboard_Field (N : Positive) return Natural is
      I : constant Natural := Find_DMI (EVC_DMI_Port.MSG_ONBOARD);
   begin
      return (if I = 0 then 16#FFFF# else Byte_At (I, 5 + N));
   end Onboard_Field;

   function Img (N : Natural) return String is (Natural'Image (N));

   ---------------------------------------------------------------------
   --  Inputs
   ---------------------------------------------------------------------

   procedure Input (Port : Port_T; Bytes : Byte_Array) is
   begin
      EVC_Core.Handle_Input (Port, Bytes);
   end Input;

   --  A DMI protocol frame
   function Frame (The_Type : Byte; Payload : Byte_Array) return Byte_Array
   is
      L : constant Natural := Payload'Length;
   begin
      return Byte_Array'(The_Type,
                         Byte (L mod 256), Byte (L / 256 mod 256), 0, 0)
             & Payload;
   end Frame;

   --  A 32 bit field, little endian, two's complement
   function U32 (V : Integer_64) return Byte_Array is
      U : constant Unsigned_64 := Unsigned_64 (Unsigned_32'Mod (V));
   begin
      return (EVC_Bytes.Byte_Of (U, 0), EVC_Bytes.Byte_Of (U, 1),
              EVC_Bytes.Byte_Of (U, 2), EVC_Bytes.Byte_Of (U, 3));
   end U32;

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
     return Byte_Array
   is
      Length : constant Natural := (N_Bits + 7) / 8 + Extra;
      Result : Byte_Array (1 .. 6 + Length) := (others => 16#A5#);
   begin
      Result (1 .. 4) := (0, 0, 0, 0);
      Result (5) := Byte (N_Bits mod 256);
      Result (6) := Byte (N_Bits / 256 mod 256);
      return Result;
   end BTM_Payload;

   --  A radio message whose L_MESSAGE says L_Message and whose length is
   --  Length
   function RTM_Payload (L_Message : Natural; Length : Natural)
     return Byte_Array
   is
      Result : Byte_Array (1 .. Length) := (others => 0);
   begin
      if Length >= 1 then
         Result (1) := 24;  -- NID_MESSAGE
      end if;
      if Length >= 3 then
         Result (2) := Byte (L_Message / 4 mod 256);
         Result (3) := Byte ((L_Message mod 4) * 64);
      end if;
      return Result;
   end RTM_Payload;

   Isolate : constant Byte_Array :=
     Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (20, 0, 0));

   ---------------------------------------------------------------------
   --  Scenarios
   ---------------------------------------------------------------------

   --  The constants the on-board repeats from common/dmi_protocol.ads
   --  The constants are static: the compiler knows the outcome, the
   --  runner reports it
   pragma Warnings (Off, "condition is always*");
   procedure Scenario_Protocol_Constants is
      use DMI_Protocol;
   begin
      Check (Unsigned_8 (MSG_MODE_LEVEL) = EVC_DMI_Port.MSG_MODE_LEVEL
             and then Unsigned_8 (MSG_ONBOARD) = EVC_DMI_Port.MSG_ONBOARD
             and then Unsigned_8 (MSG_STATUS) = EVC_DMI_Port.MSG_STATUS
             and then Unsigned_8 (MSG_DRIVER_ACTION)
                        = EVC_DMI_Port.MSG_DRIVER_ACTION
             and then Unsigned_8 (MSG_DRIVER_DATA)
                        = EVC_DMI_Port.MSG_DRIVER_DATA,
             "message types equal DMI_Protocol");
      Check (Mode_Level_Length = EVC_DMI_Port.Mode_Level_Length
             and then Onboard_Length = EVC_DMI_Port.Onboard_Length
             and then Status_Length = EVC_DMI_Port.Status_Length
             and then Driver_Action_Length
                        = EVC_DMI_Port.Driver_Action_Length
             and then Driver_Ack_Length = EVC_DMI_Port.Driver_Ack_Length
             and then Header_Length = EVC_DMI_Port.Header_Length,
             "message lengths equal DMI_Protocol");
   end Scenario_Protocol_Constants;
   pragma Warnings (On, "condition is always*");

   --  Power-up: NP until the first cycle, then SB and the DMI messages
   --  of SB every cycle (SUBSET-026 4.4.4.1.1, 4.6.2 NP -> SB [4])
   procedure Scenario_Power_Up is
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      Check (EVC_Core.Mode = M_NP, "power-up: mode NP before any cycle");
      Take;
      Check (Out_Last = 0, "power-up: nothing output before any cycle");

      EVC_Core.Tick (100);
      Check (EVC_Core.Mode = M_SB, "power-up: SB after the first cycle");
      Check (EVC_Core.Cycle = 1 and then EVC_Core.Time_Ms = 100,
             "power-up: cycle 1 at 100 ms");
      Take;
      Check (Parsed, "power-up: whole records");
      Check (Rec_Count = 3, "power-up: three records, got" & Img (Rec_Count));
      if Rec_Count = 3 then
         Check (Recs (1).Port = JRU and then Rec_Length (1) = 16
                and then Byte_At (1, 1) = 1
                and then Byte_At (1, 2) = Mode_T'Pos (M_SB)
                and then Byte_At (1, 5) = 1        -- cycle
                and then Byte_At (1, 9) = 100,     -- time, ms
                "power-up: JRU records the change to SB");
         Check (Recs (2).Port = DMI and then Recs (3).Port = DMI,
                "power-up: then two DMI frames");
      end if;
      Check (DMI_Mode_Byte = 1, "power-up: MSG_MODE_LEVEL mode SB (1), got"
             & Img (DMI_Mode_Byte));
      Check (DMI_Level_Byte = 0,
             "power-up: MSG_MODE_LEVEL level unknown (0)");
      Check (Onboard_Field (6) = 2,
             "power-up: MSG_ONBOARD som 2, start of mission possible");
      Check (Onboard_Field (4) = 3,
             "power-up: MSG_ONBOARD standstill, below override speed");
      Check_Golden ("power_up_cycle_1");

      Reset_Capture;
      for I in 2 .. 5 loop
         EVC_Core.Tick (100);
         Take;
         Check (Parsed and then Rec_Count = 2
                and then Count_Port (DMI) = 2
                and then DMI_Mode_Byte = 1,
                "power-up: cycle" & Img (I) & " sends SB to the DMI only");
      end loop;
      Check (EVC_Core.Mode = M_SB and then EVC_Core.Cycle = 5,
             "power-up: SB after 5 cycles");
      Check_Golden ("power_up_cycles_2_5");
   end Scenario_Power_Up;

   --  Malformed payloads on every port are counted and ignored: the
   --  outputs are those of an on-board that received nothing
   procedure Scenario_Malformed is
      Reference : Byte_Array (1 .. EVC_Outbox.Capacity);
      Ref_Last  : Natural;
      Sent      : Natural := 0;

      procedure Bad (Port : Port_T; Bytes : Byte_Array; What : String) is
         Before : constant Natural := EVC_Core.Rejected (Port);
      begin
         Input (Port, Bytes);
         Sent := Sent + 1;
         Check (EVC_Core.Rejected (Port) = Before + 1,
                "malformed " & Port_T'Image (Port) & " rejected: " & What);
      end Bad;

      Odo_Ok : constant Byte_Array :=
        Odometer_Payload (100, 0, 0, 500, 400, 600, 1);
   begin
      EVC_Core.Initialise;
      EVC_Core.Tick (100);
      EVC_Core.Take_Outputs (Reference, Ref_Last);

      EVC_Core.Initialise;
      Reset_Capture;
      for P in Port_T loop
         Bad (P, (1 .. 0 => 0), "empty");
         Bad (P, (1 .. 1100 => 16#FF#), "1100 bytes");
      end loop;
      --  BTM
      Bad (BTM, BTM_Payload (49), "49 bits, shorter than the header");
      Bad (BTM, BTM_Payload (50), "50 bits, the header alone");
      Bad (BTM, BTM_Payload (209), "209 bits");
      Bad (BTM, BTM_Payload (211), "211 bits");
      Bad (BTM, BTM_Payload (829), "829 bits");
      Bad (BTM, BTM_Payload (831), "831 bits");
      Bad (BTM, BTM_Payload (210, 1), "one byte too many");
      Bad (BTM, BTM_Payload (210, -1), "one byte short");
      Bad (BTM, (1 => 50), "one byte");
      Bad (BTM, (0, 0, 0, 0), "a stamp without a telegram");
      Bad (BTM, BTM_Payload (210) (1 .. 5), "a stamp and one byte");
      --  RTM
      Bad (RTM, RTM_Payload (0, 2), "2 bytes");
      Bad (RTM, RTM_Payload (10, 9), "L_MESSAGE 10, 9 bytes");
      Bad (RTM, RTM_Payload (9, 10), "L_MESSAGE 9, 10 bytes");
      --  Odometer
      Bad (Odometer, Odo_Ok (1 .. 21), "21 bytes");
      Bad (Odometer, Odo_Ok & Byte_Array'(1 => 0), "23 bytes");
      Bad (Odometer, Odometer_Payload (100, 0, 0, 500, 400, 600, 0),
           "standstill with a speed");
      Bad (Odometer, Odometer_Payload (100, 0, 0, 0, 0, 1, 0),
           "standstill with a max speed");
      Bad (Odometer, Odometer_Payload (-5, 0, 0, 500, 400, 600, 1, 0, 5),
           "no cold movement information but a distance");
      Bad (Odometer, Odometer_Payload (100, 0, 0, 700, 400, 600, 1),
           "v_est above v_max");
      Bad (Odometer, Odometer_Payload (100, 0, 0, 300, 400, 600, 1),
           "v_est below v_min");
      Bad (Odometer, Odometer_Payload (100, 0, 0, 500, 400, 600, 4),
           "movement 4");
      Bad (Odometer, Odometer_Payload (100, 0, 0, 500, 400, 600, 1, 2),
           "cold 2");
      --  TIU
      Bad (TIU, (1 => 1), "one byte");
      Bad (TIU, (0, 1), "signal 0");
      Bad (TIU, (6, 1), "signal 6");
      Bad (TIU, (5, 2), "value 2");
      Bad (TIU, (1, 1, 0), "three bytes");
      --  DMI
      Bad (DMI, (16#40#, 3, 0, 0), "a header of 4 bytes");
      Bad (DMI, (16#40#, 4, 0, 0, 0, 20, 0, 0), "length field 4, 3 bytes");
      Bad (DMI, (16#40#, 3, 0, 0, 1, 20, 0, 0), "length field above 2**24");
      Bad (DMI, Frame (16#40#, (20, 0, 0, 0, 0)),
           "isolation in the long form of an acknowledgement");
      Bad (DMI, Frame (16#40#, (2, 1, 0)), "acknowledgement, short form");
      Bad (DMI, Frame (16#40#, (20, 0)), "driver action of 2 bytes");
      Bad (DMI, Frame (16#41#, (1 .. 0 => 0)), "empty driver data");
      Bad (DMI, Frame (16#02#, (1, 0, 255, 255, 0, 0, 0, 255, 255)),
           "MSG_MODE_LEVEL, a message for the DMI");
      Bad (DMI, Frame (16#51#, (0, 1)), "MSG_DESK of the bench");
      Bad (DMI, Frame (16#41#, (1 .. 600 => 1)), "driver data of 600 bytes");
      --  ATO and JRU take no input at all
      Bad (ATO, (1, 2, 3), "three bytes");
      Bad (JRU, (1 .. 16 => 0), "a JRU record");

      Check (not EVC_Core.Isolation_Requested,
             "malformed: no isolation request");
      for P in Port_T loop
         Check (EVC_Core.Accepted (P) = 0,
                "malformed: nothing accepted on " & Port_T'Image (P));
      end loop;
      Check (EVC_Core.Mode = M_NP, "malformed: still NP before the cycle");

      EVC_Core.Tick (100);
      Take;
      Check (EVC_Core.Mode = M_SB, "malformed: SB after the cycle");
      Check (Out_Last = Ref_Last
             and then Out_Buf (1 .. Out_Last) = Reference (1 .. Ref_Last),
             "malformed: outputs as without inputs (" & Img (Sent)
             & " inputs)");
      Check_Golden ("malformed_ignored");
   end Scenario_Malformed;

   --  Valid inputs are accepted; E0 uses the odometer (standstill), the
   --  TIU signals of MSG_ONBOARD and the isolation, nothing else
   procedure Scenario_Valid_Inputs is
      Shifted : Byte_Array (1000 .. 1032);
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      Input (BTM, BTM_Payload (210));
      Input (BTM, BTM_Payload (830));
      Shifted := BTM_Payload (210);
      Input (BTM, Shifted);                 -- index not starting at 1
      Input (RTM, RTM_Payload (3, 3));
      Input (RTM, RTM_Payload (1023, 1023));
      Input (Odometer, Odometer_Payload (-200, 0, 0, 0, 0, 0, 0));
      Input (Odometer, Odometer_Payload (5000, 10, 10, 1000, 990, 1010,
                                         1));
      Input (TIU, (5, 1));                  -- non leading permitted
      Input (TIU, (4, 1));                  -- passive shunting permitted
      Input (TIU, (4, 0));                  -- ... withdrawn
      Input (DMI, Frame (16#40#, (1, 0, 0)));           -- speed toggle
      Input (DMI, Frame (16#40#, (2, 1, 0, 0, 0)));     -- acknowledgement
      Input (DMI, Frame (16#41#, (10, Character'Pos ('e'),
                                  Character'Pos ('n'))));  -- language
      Check (EVC_Core.Accepted (BTM) = 3 and then EVC_Core.Accepted (RTM) = 2
             and then EVC_Core.Accepted (Odometer) = 2
             and then EVC_Core.Accepted (TIU) = 3
             and then EVC_Core.Accepted (DMI) = 3,
             "valid: every input accepted");
      Check ((for all P in Port_T => EVC_Core.Rejected (P) = 0),
             "valid: nothing rejected");
      Check (not EVC_Core.Isolation_Requested,
             "valid: no isolation request");

      EVC_Core.Tick (100);
      Take;
      Check (EVC_Core.Mode = M_SB, "valid: SB");
      --  the train moves (the last sample): no standstill, above the
      --  override limit of 0 km/h; the non leading input is on
      Check (Onboard_Field (4) = 4,
             "valid: MSG_ONBOARD train = non leading only, got"
             & Img (Onboard_Field (4)));
      Input (Odometer, Odometer_Payload (5000, 10, 10, 0, 0, 0, 0));
      EVC_Core.Tick (100);
      Take;
      Check (Onboard_Field (4) = 7,
             "valid: standstill again, got" & Img (Onboard_Field (4)));
      Check_Golden ("valid_inputs");
   end Scenario_Valid_Inputs;

   --  The driver isolates the on-board (4.6.3 [1]): IS from any mode,
   --  with priority over NP -> SB, and nothing leaves IS (4.4.3.1.3)
   procedure Scenario_Isolation is
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      EVC_Core.Tick (100);
      Take;
      Input (DMI, Isolate);
      Check (EVC_Core.Isolation_Requested and then EVC_Core.Mode = M_SB,
             "isolation: latched, applied at the next cycle");
      EVC_Core.Tick (100);
      Take;
      Check (EVC_Core.Mode = M_IS, "isolation: SB -> IS");
      Check (Parsed and then Count_Port (JRU) = 1 and then DMI_Mode_Byte = 17,
             "isolation: JRU event and MSG_MODE_LEVEL mode IS (17)");
      Input (DMI, Isolate);
      for I in 1 .. 3 loop
         EVC_Core.Tick (100);
         Take;
      end loop;
      Check (EVC_Core.Mode = M_IS and then DMI_Mode_Byte = 17,
             "isolation: IS stays");
      Check_Golden ("isolation");

      --  isolated before the first cycle: NP -> IS (p1) wins over NP ->
      --  SB (p2)
      EVC_Core.Initialise;
      Input (DMI, Isolate);
      EVC_Core.Tick (100);
      Check (EVC_Core.Mode = M_IS, "isolation: NP -> IS before NP -> SB");
      EVC_Core.Initialise;
      Check (EVC_Core.Mode = M_NP and then not EVC_Core.Isolation_Requested,
             "isolation: only Initialise leaves IS");
   end Scenario_Isolation;

   --  Time: a cycle of 0 ms and cycles of the largest step
   procedure Scenario_Time is
   begin
      EVC_Core.Initialise;
      EVC_Core.Tick (0);
      Check (EVC_Core.Cycle = 1 and then EVC_Core.Time_Ms = 0,
             "time: a cycle of 0 ms is a cycle");
      Check (EVC_Core.Mode = M_SB, "time: SB after a cycle of 0 ms");
      EVC_Core.Tick (Natural'Last);
      EVC_Core.Tick (Natural'Last);
      Check (EVC_Core.Time_Ms = 2 * EVC_Core.Time_Ms_T (Natural'Last),
             "time: two cycles of Natural'Last ms add up");
      for I in 1 .. 10_000 loop
         EVC_Core.Tick (Natural'Last);
         Take;
      end loop;
      Check (EVC_Core.Cycle = 10_003
             and then EVC_Core.Time_Ms
                        = 10_002 * EVC_Core.Time_Ms_T (Natural'Last),
             "time: 10 000 more cycles of Natural'Last ms");
      Check (Parsed and then DMI_Mode_Byte = 1,
             "time: still SB on the DMI");
   end Scenario_Time;

   --  The outbox: nobody takes the outputs, it fills and drops whole
   --  records; small buffers get whole records only
   procedure Scenario_Outbox is
      Small  : Byte_Array (1 .. 20);
      Tiny   : Byte_Array (1 .. 10);
      Offset : Byte_Array (50 .. 149);
      Null_Buffer : Byte_Array (1 .. 0);
      Last   : Natural;
   begin
      EVC_Core.Initialise;
      for I in 1 .. 1_000 loop
         EVC_Core.Tick (100);
      end loop;
      Check (EVC_Outbox.Used <= EVC_Outbox.Capacity
             and then EVC_Outbox.Dropped > 0,
             "outbox: full after 1000 cycles, records dropped:"
             & Img (EVC_Outbox.Dropped));
      Take;
      Check (Parsed and then Out_Last > EVC_Outbox.Capacity - 36
             and then Out_Last <= EVC_Outbox.Capacity,
             "outbox: whole records, " & Img (Rec_Count) & " records in"
             & Img (Out_Last) & " bytes");
      Check (EVC_Outbox.Used = 0, "outbox: empty after a full take");

      EVC_Core.Tick (100);  -- 17 + 19 bytes
      EVC_Core.Take_Outputs (Tiny, Last);
      Check (Last = 0, "outbox: no record fits 10 bytes");
      EVC_Core.Take_Outputs (Small, Last);
      Check (Last = 17 and then Small (1) = Port_T'Pos (DMI)
             and then Small (4) = EVC_DMI_Port.MSG_MODE_LEVEL,
             "outbox: 20 bytes take the MSG_MODE_LEVEL record");
      EVC_Core.Take_Outputs (Null_Buffer, Last);
      Check (Last = 0, "outbox: a null buffer takes nothing");
      EVC_Core.Take_Outputs (Offset, Last);
      Check (Last = 68 and then Offset (53) = EVC_DMI_Port.MSG_ONBOARD,
             "outbox: a buffer from index 50 takes the MSG_ONBOARD record");
      EVC_Core.Take_Outputs (Offset, Last);
      Check (Last = 49, "outbox: then nothing is left");
   end Scenario_Outbox;

   --  Enter_Failure: silent until Initialise
   procedure Scenario_Failure is
   begin
      EVC_Core.Initialise;
      for I in 1 .. 3 loop
         EVC_Core.Tick (100);
      end loop;
      Check (EVC_Outbox.Used > 0, "failure: outputs pending");
      EVC_Core.Enter_Failure;
      Check (EVC_Core.Failed and then EVC_Core.Mode = M_SF,
             "failure: failed, mode SF (SB -> SF, 4.6.3 [13])");
      Take;
      Check (Out_Last = 0, "failure: the pending outputs are dropped");
      Input (DMI, Isolate);
      Input (TIU, (5, 1));
      for I in 1 .. 10 loop
         EVC_Core.Tick (100);
         Take;
         Check (Out_Last = 0, "failure: silent in cycle" & Img (I));
      end loop;
      Check (EVC_Core.Cycle = 3 and then EVC_Core.Mode = M_SF
             and then EVC_Core.Accepted (DMI) = 0
             and then EVC_Core.Accepted (TIU) = 0,
             "failure: inputs and time are ignored");
      EVC_Core.Enter_Failure;
      Check (EVC_Core.Failed, "failure: a second failure changes nothing");

      EVC_Core.Initialise;
      Check (not EVC_Core.Failed and then EVC_Core.Mode = M_NP,
             "failure: Initialise restarts");
      EVC_Core.Tick (100);
      Take;
      Check (Parsed and then DMI_Mode_Byte = 1, "failure: SB after restart");

      --  isolated, the on-board stays in IS (no transition IS -> SF)
      Input (DMI, Isolate);
      EVC_Core.Tick (100);
      EVC_Core.Enter_Failure;
      Check (EVC_Core.Mode = M_IS, "failure: in IS the mode stays IS");
      EVC_Core.Initialise;
   end Scenario_Failure;

   --  The whole chain: EVC_Core's DMI port into DMI_Core, against the
   --  picture EVC_Mock draws at start. Both run five cycles of 100 ms,
   --  the DMI's Tick after the EVC's, as dmi_test Scenario_Mission does
   --  before its golden "mission_sb" (the Driver ID window of Table 49
   --  S1 over the SB default window).
   --
   --  The mock sends much more every step (speed, status, track
   --  conditions, VBC list, system version, ATO, bench messages). The
   --  on-board sends MSG_MODE_LEVEL and MSG_ONBOARD only, and that is
   --  enough for this picture, with one difference, a decision: E1. The
   --  mock reports its radio connection as up from the start (MSG_STATUS
   --  radio 1, ST03 in E1, DMI 8.4.1); the on-board has no session with
   --  an RBC in SB after power-up and shows no symbol. Every pixel
   --  outside E1 must be the same, and the DMI must hold "no connection".
   procedure Scenario_End_To_End is
      use type General_Parameters.Color;
      use type DMI_Status.Radio_T;

      Outbox : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
      O_Last : Stream_Element_Offset;
      Frames : Natural := 0;

      subtype X_T is Natural range 0 .. 639;
      subtype Y_T is Natural range 0 .. 479;
      type Frame_T is array (X_T, Y_T) of General_Parameters.Color;
      Mock_Frame : Frame_T;

      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

      procedure Feed_DMI is
      begin
         Take;
         if not Parsed then
            Check (False, "end to end: whole records");
            return;
         end if;
         for I in 1 .. Rec_Count loop
            if Recs (I).Port = DMI and then Rec_Length (I) >= 5 then
               declare
                  First   : constant Natural := Recs (I).First;
                  Payload : Stream_Element_Array
                    (1 .. Stream_Element_Offset (Rec_Length (I) - 5));
               begin
                  for K in Payload'Range loop
                     Payload (K) := Stream_Element
                       (Out_Buf (First + 4 + Natural (K)));
                  end loop;
                  DMI_Core.Handle_Message
                    (DMI_Protocol.Msg_Type_T (Out_Buf (First)), Payload);
                  Frames := Frames + 1;
               end;
            end if;
         end loop;
      end Feed_DMI;

      --  What the DMI sends goes back to the on-board, frame by frame
      procedure Pump_To_EVC is
         Pos : Stream_Element_Offset := Outbox'First;
         Len : Stream_Element_Offset;
      begin
         DMI_Core.Take_Outbox (Outbox, O_Last, With_Sounds => False);
         while O_Last - Pos + 1 >= 5 loop
            Len := 5 + Stream_Element_Offset (Outbox (Pos + 1))
                   + 256 * Stream_Element_Offset (Outbox (Pos + 2));
            exit when Pos + Len - 1 > O_Last;
            declare
               Bytes : Byte_Array (1 .. Natural (Len));
            begin
               for K in Bytes'Range loop
                  Bytes (K) :=
                    Byte (Outbox (Pos + Stream_Element_Offset (K) - 1));
               end loop;
               EVC_Core.Handle_Input (DMI, Bytes);
            end;
            Pos := Pos + Len;
         end loop;
      end Pump_To_EVC;

      Golden  : constant String := DMI_Golden_Dir & "mission_sb.sha256";
      Timeout : constant Natural := General_Parameters.EVC_Link_Timeout_Ms;
      E1      : constant Display.Area_T :=
        Display.Get_Sub_Area_With_Relative_Position (Display.E1);
      E       : constant Display.Area_T := Display.Get_Area (Display.E);
      E1_X    : constant Natural := E.Position.X + E1.Position.X;
      E1_Y    : constant Natural := E.Position.Y + E1.Position.Y;
      Outside : Natural := 0;
      Inside  : Natural := 0;
   begin
      --  1. EVC_Mock, as dmi_test runs it (whose Reset also turns the
      --     link supervision off)
      DMI_Core.Initialise;
      General_Parameters.EVC_Link_Timeout_Ms := 0;
      EVC_Mock.Reset;
      for I in 1 .. 5 loop
         EVC_Driver.Auto_Drive;
         EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
      end loop;
      DMI_Core.Render;
      General_Parameters.EVC_Link_Timeout_Ms := Timeout;
      if not Ada.Directories.Exists (Golden) then
         Check (False, "end to end: DMI golden missing: " & Golden);
      else
         Check (Read_Line (Golden) = Display.Screen.Files.Digest,
                "end to end: EVC_Mock draws mission_sb as recorded");
      end if;
      for X in X_T loop
         for Y in Y_T loop
            Mock_Frame (X, Y) := Display.Screen.Get_Pixel (X, Y);
         end loop;
      end loop;

      --  2. the on-board, the link supervised
      DMI_Core.Initialise;
      EVC_Core.Initialise;
      for I in 1 .. 5 loop
         EVC_Core.Tick (100);
         Feed_DMI;
         DMI_Core.Tick (100);
         Pump_To_EVC;
      end loop;
      DMI_Core.Render;
      Check (Frames = 10, "end to end: two frames per cycle reach the DMI");
      Check (not DMI_Core.EVC_Link_Lost, "end to end: the DMI hears the EVC");
      Check (EVC_Core.Rejected (DMI) = 0,
             "end to end: the on-board accepts what the DMI sends");
      Check_Digest ("end_to_end_sb", Display.Screen.Files.Digest);

      for X in X_T loop
         for Y in Y_T loop
            if Display.Screen.Get_Pixel (X, Y) /= Mock_Frame (X, Y) then
               if X in E1_X .. E1_X + E1.Width - 1
                 and then Y in E1_Y .. E1_Y + E1.Height - 1
               then
                  Inside := Inside + 1;
               else
                  Outside := Outside + 1;
               end if;
            end if;
         end loop;
      end loop;
      Check (Outside = 0,
             "end to end: the picture of the mock outside E1, pixels"
             & " different:" & Img (Outside));
      Check (Inside > 0
             and then DMI_Status.Radio = DMI_Status.No_Connection,
             "end to end: E1 differs, no radio connection (" & Img (Inside)
             & " pixels of ST03)");
      if Ada.Environment_Variables.Exists ("DUMP") then
         Ada.Directories.Create_Path (Golden_Dir);
         Display.Screen.Files.Dump (Golden_Dir & "end_to_end_sb.actual");
      end if;
   end Scenario_End_To_End;

   ---------------------------------------------------------------------
   --  E1: the ERTMS/ETCS language (evc/language)
   ---------------------------------------------------------------------

   package Cat renames ETCS_Catalogue;
   package Tel renames ETCS_Telegram;
   package Msg renames ETCS_Message;
   package MCat renames ETCS_Message_Catalogue;
   package Rnd renames ETCS_Language_Random;
   package T0 renames ETCS_Track_Packets.P0;
   package T2 renames ETCS_Track_Packets.P2;
   package T5 renames ETCS_Track_Packets.P5;
   package T21 renames ETCS_Track_Packets.P21;
   package T45 renames ETCS_Track_Packets.P45;
   package T65 renames ETCS_Track_Packets.P65;
   package T73 renames ETCS_Track_Packets.P73;
   package T140 renames ETCS_Track_Packets.P140;
   package R0 renames ETCS_Train_Packets.P0;
   package R4 renames ETCS_Train_Packets.P4;

   use type Cat.Packet_Kind_T;
   use type MCat.Message_Kind_T;
   use type Tel.Status_T;
   use type Msg.Status_T;
   use type Rnd.Result_T;
   use type Rnd.Count_Mode_T;
   use type Tel.Header_T;
   use type T5.Packet_T;
   use type T21.Packet_T;
   use type T65.Packet_T;
   use type R0.Packet_T;
   use type ETCS_Variables.M_VERSION_T;
   use type ETCS_Variables.NID_PACKET_T;

   subtype Writer_T is ETCS_Bits.Writer (ETCS_Bits.Max_Bytes);
   subtype Reader_T is ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);

   --  Bit N (0 first) of Data
   function Bit_Of (Data : Byte_Array; N : Natural) return Natural is
     (Natural (Shift_Right (Data (Data'First + N / 8), 7 - N mod 8) and 1));

   --  Overwrite Bits bits of Data from bit Offset on with Value
   procedure Set_Bits (Data   : in out Byte_Array;
                       Offset : Natural;
                       Bits   : Positive;
                       Value  : Unsigned_64)
   is
   begin
      for I in 0 .. Bits - 1 loop
         declare
            N    : constant Natural := Offset + I;
            Mask : constant Byte := Shift_Left (1, 7 - N mod 8);
            J    : constant Positive := Data'First + N / 8;
         begin
            if (Shift_Right (Value, Bits - 1 - I) and 1) = 1 then
               Data (J) := Data (J) or Mask;
            else
               Data (J) := Data (J) and not Mask;
            end if;
         end;
      end loop;
   end Set_Bits;

   --  The BTM payload of a telegram of Bits bits (EVC_Ports), its
   --  balise detected at the odometer reading Stamp
   function BTM_Of (Data  : Byte_Array;
                    Bits  : Natural;
                    Stamp : Integer_64 := 0) return Byte_Array
   is
      Length : constant Natural := (Bits + 7) / 8;
      Result : Byte_Array (1 .. 2 + Length) := (others => 0);
   begin
      Result (1) := Byte (Bits mod 256);
      Result (2) := Byte (Bits / 256);
      Result (3 .. 2 + Length) := Data (Data'First .. Data'First + Length - 1);
      return U32 (Stamp) & Result;
   end BTM_Of;

   --  A telegram header: version 3.0, first balise of a group of two
   function Header (Version : ETCS_Variables.M_VERSION_T := 48)
     return Tel.Header_T
   is (Q_UPDOWN  => 1,
       M_VERSION => Version,
       Q_MEDIA   => 0,
       N_PIG     => 0,
       N_TOTAL   => 1,
       M_DUP     => 0,
       M_MCOUNT  => 7,
       NID_C     => 123,
       NID_BG    => 4567,
       Q_LINK    => 1);

   --  Sample packets
   function Linking return T5.Packet_T is
      L : T5.Packet_T;
   begin
      L.Q_DIR := 1;
      L.Q_SCALE := 1;
      L.D_LINK := 1500;
      L.Q_NEWCOUNTRY := 1;
      L.Has_NID_C := True;
      L.NID_C := 99;
      L.NID_BG := 321;
      L.Q_LINKORIENTATION := 1;
      L.Q_LINKREACTION := 2;
      L.Q_LOCACC := 12;
      L.N_ITER := 2;
      L.D_LINK_List (1).D_LINK := 800;
      L.D_LINK_List (1).NID_BG := 322;
      L.D_LINK_List (1).Q_LINKREACTION := 1;
      L.D_LINK_List (1).Q_LOCACC := 5;
      L.D_LINK_List (2).D_LINK := 32767;
      L.D_LINK_List (2).Q_NEWCOUNTRY := 1;
      L.D_LINK_List (2).Has_NID_C := True;
      L.D_LINK_List (2).NID_C := 1023;
      L.D_LINK_List (2).NID_BG := 16383;
      L.D_LINK_List (2).Q_LINKORIENTATION := 1;
      L.D_LINK_List (2).Q_LOCACC := 63;
      return L;
   end Linking;

   function Gradient (Q_DIR : ETCS_Variables.Q_DIR_T := 1)
     return T21.Packet_T
   is
      G : T21.Packet_T;
   begin
      G.Q_DIR := Q_DIR;
      G.Q_SCALE := 1;
      G.D_GRADIENT := 100;
      G.Q_GDIR := 1;
      G.G_A := 5;
      G.N_ITER := 1;
      G.D_GRADIENT_List (1).D_GRADIENT := 200;
      G.D_GRADIENT_List (1).G_A := 255;
      return G;
   end Gradient;

   function TSR (Id    : ETCS_Variables.NID_TSR_T;
                 V_TSR : ETCS_Variables.V_TSR_T := 16) return T65.Packet_T
   is
      T : T65.Packet_T;
   begin
      T.Q_DIR := 2;
      T.Q_SCALE := 1;
      T.NID_TSR := Id;
      T.D_TSR := 1000;
      T.L_TSR := 500;
      T.Q_FRONT := 1;
      T.V_TSR := V_TSR;
      return T;
   end TSR;

   function Position_Report return R0.Packet_T is
      P : R0.Packet_T;
   begin
      P.Q_SCALE := 1;
      P.NID_C := 123;
      P.NID_BG := 4567;
      P.D_LRBG := 250;
      P.Q_DIRLRBG := 1;
      P.Q_DLRBG := 1;
      P.L_DOUBTOVER := 10;
      P.L_DOUBTUNDER := 12;
      P.Q_INTEGRITY := 1;
      P.Has_L_TRAININT := True;
      P.L_TRAININT := 400;
      P.V_TRAIN := 16;
      P.Q_DIRTRAIN := 1;
      P.M_MODE := 0;
      P.M_LEVEL := 2;
      return P;
   end Position_Report;

   --  Appending packets; every encode must succeed
   Encodes_OK : Boolean := True;

   procedure Put (W : in out Writer_T; P : T5.Packet_T) is
      OK : Boolean;
   begin
      T5.Encode (P, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put;

   procedure Put (W : in out Writer_T; P : T21.Packet_T) is
      OK : Boolean;
   begin
      T21.Encode (P, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put;

   procedure Put (W : in out Writer_T; P : T65.Packet_T) is
      OK : Boolean;
   begin
      T65.Encode (P, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put;

   procedure Put (W : in out Writer_T; P : R0.Packet_T) is
      OK : Boolean;
   begin
      R0.Encode (P, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put;

   procedure Put_VBC_Marker (W : in out Writer_T) is
      M  : T0.Packet_T;
      OK : Boolean;
   begin
      M.NID_VBCMK := 17;
      T0.Encode (M, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put_VBC_Marker;

   procedure Put_Version_Order
     (W       : in out Writer_T;
      Version : ETCS_Variables.M_VERSION_T := 48)
   is
      V  : T2.Packet_T;
      OK : Boolean;
   begin
      V.Q_DIR := 2;
      V.M_VERSION := Version;
      T2.Encode (V, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put_Version_Order;

   procedure Put_Error (W : in out Writer_T; Error : Natural) is
      E  : R4.Packet_T;
      OK : Boolean;
   begin
      E.M_ERROR := ETCS_Variables.M_ERROR_T (Error);
      R4.Encode (E, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put_Error;

   --  A random valid packet of a kind (the generated test helper)
   procedure Put_Random (W : in out Writer_T; Kind : Cat.Known_Kind_T) is
      OK : Boolean;
   begin
      Rnd.Write_Random (Kind, Rnd.Min_Values, Rnd.One_Item, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put_Random;

   --  A packet of an NID_PACKET no catalogue has, with the standard
   --  header and Extra bits of data
   procedure Put_Unknown (W     : in out Writer_T;
                          NID   : Natural;
                          Track : Boolean;
                          Extra : Natural)
   is
   begin
      ETCS_Bits.Write (W, 8, Unsigned_64 (NID));
      if Track then
         ETCS_Bits.Write (W, 2, 1);
      end if;
      ETCS_Bits.Write
        (W, 13, Unsigned_64 ((if Track then 23 else 21) + Extra));
      ETCS_Bits.Fill (W, Extra, One => True);
   end Put_Unknown;

   function Telegram_Status (W : Writer_T) return Tel.Status_T is
      T      : Tel.Telegram_T;
      Status : Tel.Status_T;
   begin
      Tel.Parse (ETCS_Bits.Data (W), ETCS_Bits.Position (W), T, Status);
      return Status;
   end Telegram_Status;

   --  Every packet of the catalogue: encode, decode, compare. The
   --  boundaries (every value at its minimum or its maximum, loops of 0,
   --  1 and the maximum items) and random valid packets (the property
   --  test); then every condition must have been met holding and not,
   --  every loop with 0, 1 and (outermost loops) the maximum items.
   procedure Scenario_Packet_Round_Trips is
      Random_Trips : constant := 400;
      Result       : Rnd.Result_T;
      Bits         : Natural;
      Trips        : Natural := 0;
      Too_Long     : Natural := 0;
   begin
      Rnd.Reset (20260927);
      Rnd.Clear_Coverage;
      for K in Cat.Known_Kind_T loop
         declare
            Bad  : Natural := 0;
            Name : constant String := Cat.Known_Kind_T'Image (K);
         begin
            for V in Rnd.Min_Values .. Rnd.Max_Values loop
               for C in Rnd.No_Items .. Rnd.Max_Items loop
                  Rnd.Round_Trip (K, V, C, Result, Bits);
                  Trips := Trips + 1;
                  if Result = Rnd.Too_Long and then C = Rnd.Max_Items then
                     Too_Long := Too_Long + 1;
                  elsif Result /= Rnd.Passed then
                     Bad := Bad + 1;
                     Put_Line ("  " & Name & " " & Rnd.Value_Mode_T'Image (V)
                               & " " & Rnd.Count_Mode_T'Image (C) & ": "
                               & Rnd.Result_T'Image (Result));
                  end if;
               end loop;
            end loop;
            for I in 1 .. Random_Trips loop
               Rnd.Round_Trip (K, Rnd.Random_Values, Rnd.Random_Items,
                               Result, Bits);
               Trips := Trips + 1;
               if Result = Rnd.Too_Long then
                  Too_Long := Too_Long + 1;
               elsif Result /= Rnd.Passed then
                  Bad := Bad + 1;
                  if Bad <= 3 then
                     Put_Line ("  " & Name & " random: "
                               & Rnd.Result_T'Image (Result));
                  end if;
               end if;
            end loop;
            Check (Bad = 0, "round trip " & Name & " " & Cat.Name (K)
                   & ": boundaries and" & Img (Random_Trips) & " random");
         end;
      end loop;
      for C in 1 .. Rnd.Condition_Count loop
         Check (Rnd.Condition_Seen (C, True)
                and then Rnd.Condition_Seen (C, False),
                "round trip, condition held and not: "
                & Rnd.Condition_Name (C));
      end loop;
      for L in 1 .. Rnd.Loop_Count loop
         Check (Rnd.Loop_Seen (L, Rnd.None)
                and then Rnd.Loop_Seen (L, Rnd.One)
                and then (Rnd.Loop_Depth (L) > 1
                          or else Rnd.Loop_Seen (L, Rnd.Maximum)),
                "round trip, loop of 0, 1 and the maximum items: "
                & Rnd.Loop_Name (L));
      end loop;
      Put_Line ("  round trips:" & Img (Trips) & ", longer than a packet"
                & " can be (encode refuses):" & Img (Too_Long));
   end Scenario_Packet_Round_Trips;

   --  The Eurobalise telegram (8.4.2)
   procedure Scenario_Telegram is
      W      : Writer_T;
      T      : Tel.Telegram_T;
      Status : Tel.Status_T;
      OK     : Boolean;
   begin
      --  a long telegram: packet 0, 5, 21, two 65 (8.4.1.4.2), 255, ones
      Tel.Write_Header (W, Header);
      Put_VBC_Marker (W);
      Put (W, Linking);
      Put (W, Gradient);
      Put (W, TSR (1));
      Put (W, TSR (2));
      Tel.Finish (W, Tel.Long_Bits, OK);
      Check (OK and then Encodes_OK and then ETCS_Bits.Position (W) = 830,
             "telegram: built, 830 user bits");
      Tel.Parse (ETCS_Bits.Data (W), ETCS_Bits.Position (W), T, Status);
      Check (Status = Tel.Accepted, "telegram: accepted, got "
             & Tel.Status_T'Image (Status));
      Check (T.Header = Header, "telegram: the header of 8.4.2.1");
      Check (T.Count = 5 and then T.Unknown = 0
             and then T.Index (1).Kind = Cat.Track_P0
             and then T.Index (2).NID = 5
             and then T.Index (3).NID = 21
             and then T.Index (4).NID = 65
             and then T.Index (5).NID = 65
             and then T.Index (1).Offset = Tel.Header_Bits
             and then T.Index (1).Length = 14,
             "telegram: index of the five packets");
      declare
         All_Ones : Boolean := True;
      begin
         for N in T.End_Bit + 8 .. 829 loop
            All_Ones := All_Ones and then Bit_Of (T.Data, N) = 1;
         end loop;
         Check (All_Ones, "telegram: ones after packet 255");
      end;
      --  decoded on demand from the index
      declare
         R  : Reader_T;
         L  : T5.Packet_T;
         G  : T21.Packet_T;
         S  : T65.Packet_T;
         Expected_L : T5.Packet_T := Linking;
         Expected_G : T21.Packet_T := Gradient;
         Expected_S : T65.Packet_T := TSR (2);
         OK_L, OK_G, OK_S : Boolean;
      begin
         Tel.Open_Packet (T, 2, R);
         T5.Decode (R, L, OK_L);
         Tel.Open_Packet (T, 3, R);
         T21.Decode (R, G, OK_G);
         Tel.Open_Packet (T, 5, R);
         T65.Decode (R, S, OK_S);
         Expected_L.L_PACKET := L.L_PACKET;
         Expected_G.L_PACKET := G.L_PACKET;
         Expected_S.L_PACKET := S.L_PACKET;
         Check (OK_L and then L = Expected_L
                and then Natural (L.L_PACKET) = T.Index (2).Length,
                "telegram: packet 5 decoded as encoded");
         Check (OK_G and then G = Expected_G,
                "telegram: packet 21 decoded as encoded");
         Check (OK_S and then S = Expected_S,
                "telegram: second packet 65 decoded as encoded");
      end;

      --  a short telegram (210 user bits)
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header);
      Put_Version_Order (W);
      Tel.Finish (W, Tel.Short_Bits, OK);
      Tel.Parse (ETCS_Bits.Data (W), ETCS_Bits.Position (W), T, Status);
      Check (OK and then Status = Tel.Accepted and then T.Bits = 210
             and then T.Count = 1 and then T.Index (1).NID = 2,
             "telegram: short telegram, 210 bits");
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header);
      Put (W, Linking);
      Put (W, Gradient);
      Put (W, Gradient (Q_DIR => 0));
      Tel.Finish (W, Tel.Short_Bits, OK);
      Check (not OK, "telegram: too much for a short telegram");

      --  an unknown packet is passed over by its L_PACKET
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header);
      Put_Unknown (W, 200, Track => True, Extra => 17);
      Put (W, Gradient);
      Tel.Finish (W, Tel.Long_Bits, OK);
      Tel.Parse (ETCS_Bits.Data (W), ETCS_Bits.Position (W), T, Status);
      Check (Status = Tel.Accepted and then T.Count = 2
             and then T.Unknown = 1
             and then T.Index (1).Kind = Cat.Unknown
             and then T.Index (1).Length = 40
             and then T.Index (2).Kind = Cat.Track_P21,
             "telegram: unknown packet 200 skipped by L_PACKET");
      declare
         R        : Reader_T;
         G        : T21.Packet_T;
         Expected : T21.Packet_T := Gradient;
      begin
         Tel.Open_Packet (T, 2, R);
         T21.Decode (R, G, OK);
         Expected.L_PACKET := G.L_PACKET;
         Check (OK and then G = Expected,
                "telegram: the packet after the unknown one decodes");
      end;

      --  the M_VERSION of 7.5.1.79: 2.0 .. 2.3 and 3.x
      for V in ETCS_Variables.M_VERSION_T loop
         ETCS_Bits.Clear (W);
         Tel.Write_Header (W, Header (V));
         Put (W, Gradient);
         Tel.Finish (W, Tel.Long_Bits, OK);
         Status := Telegram_Status (W);
         if V in 32 .. 35 | 48 .. 63 then
            Check (Status = Tel.Accepted,
                   "telegram: M_VERSION" & V'Image & " accepted");
         elsif V in 0 | 16 | 17 | 36 | 64 | 127 then
            Check (Status = Tel.Unsupported_Version,
                   "telegram: M_VERSION" & V'Image & " rejected");
         else
            Check (Status = Tel.Unsupported_Version,
                   "telegram: M_VERSION" & V'Image & " rejected");
         end if;
      end loop;

      --  the header of 8.4.2.1
      declare
         procedure Bad_Header (H : Tel.Header_T; What : String) is
         begin
            ETCS_Bits.Clear (W);
            Tel.Write_Header (W, H);
            Put (W, Gradient);
            Tel.Finish (W, Tel.Long_Bits, OK);
            Status := Telegram_Status (W);
            Check (Status = Tel.Bad_Header,
                   "telegram: bad header, " & What & ", got "
                   & Tel.Status_T'Image (Status));
         end Bad_Header;
         H : Tel.Header_T := Header;
      begin
         H.Q_UPDOWN := 0;
         Bad_Header (H, "down-link");
         H := Header;
         H.Q_MEDIA := 1;
         Bad_Header (H, "loop");
         H := Header;
         H.N_PIG := 2;
         Bad_Header (H, "N_PIG above N_TOTAL");
         H := Header;
         H.M_DUP := 3;
         Bad_Header (H, "M_DUP spare");
      end;

      --  no packet 255: the packets end at the end of the telegram, or
      --  7 bits before it
      declare
         procedure No_End (Left : Natural) is
         begin
            ETCS_Bits.Clear (W);
            Tel.Write_Header (W, Header);
            Put (W, Gradient);
            Put_Unknown (W, 200, Track => True,
                         Extra => Tel.Long_Bits - Left
                                  - ETCS_Bits.Position (W) - 23);
            ETCS_Bits.Fill (W, Left, One => True);
            Check (ETCS_Bits.Position (W) = Tel.Long_Bits
                   and then Telegram_Status (W) = Tel.No_End,
                   "telegram: no packet 255," & Left'Image & " bits left");
         end No_End;
      begin
         No_End (0);
         No_End (7);
      end;

      --  8.4.2.3: packet 0 is the first packet
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header);
      Put (W, Gradient);
      Put_VBC_Marker (W);
      Tel.Finish (W, Tel.Long_Bits, OK);
      Check (Telegram_Status (W) = Tel.Packet_Structure,
             "telegram: packet 0 not first");

      --  8.4.1.4: one instance per packet and direction
      declare
         procedure Pair (A, B : ETCS_Variables.Q_DIR_T;
                         Expected : Tel.Status_T;
                         What : String) is
         begin
            ETCS_Bits.Clear (W);
            Tel.Write_Header (W, Header);
            Put (W, Gradient (A));
            Put (W, Gradient (B));
            Tel.Finish (W, Tel.Long_Bits, OK);
            Check (Telegram_Status (W) = Expected, "telegram: " & What);
         end Pair;
      begin
         Pair (1, 1, Tel.Duplicate_Packet, "packet 21 twice, nominal");
         Pair (1, 2, Tel.Duplicate_Packet, "packet 21 nominal and both");
         Pair (1, 0, Tel.Accepted, "packet 21 nominal and reverse");
      end;

      --  more than Long_Bits, data shorter than the bits
      Check (Telegram_Status (W) = Tel.Accepted, "telegram: reference");
      declare
         D : constant Byte_Array := ETCS_Bits.Data (W);
      begin
         Tel.Parse (D, 831, T, Status);
         Check (Status = Tel.Too_Long, "telegram: 831 bits");
         Tel.Parse (D (D'First .. D'First + 10), 100, T, Status);
         Check (Status = Tel.Too_Long, "telegram: 100 bits in 11 bytes");
      end;
   end Scenario_Telegram;

   --  A telegram cut at every bit, and L_PACKET made inconsistent
   procedure Scenario_Telegram_Damaged is
      W      : Writer_T;
      T      : Tel.Telegram_T;
      Status : Tel.Status_T;
      OK     : Boolean;
      Bits   : Natural;
      Wrong  : Natural := 0;
   begin
      Tel.Write_Header (W, Header);
      Put (W, Gradient);
      Put (W, Linking);
      Tel.Finish (W, Tel.Long_Bits, OK);
      Bits := ETCS_Bits.Position (W);
      Tel.Parse (ETCS_Bits.Data (W), Bits, T, Status);
      Check (OK and then Status = Tel.Accepted,
             "damaged: the whole telegram is accepted");
      declare
         Data : constant Byte_Array := ETCS_Bits.Data (W);
      begin
         --  every length but 210 is not a telegram (SUBSET-036 4.3.1.2);
         --  at 210 bits the packets go past the end
         for B in 0 .. Bits - 1 loop
            Tel.Parse (Data (Data'First .. Data'First + (B + 7) / 8 - 1), B,
                       T, Status);
            if Status /= (if B = Tel.Short_Bits then Tel.Truncated
                          else Tel.Bad_Length)
            then
               Wrong := Wrong + 1;
            end if;
         end loop;
         Check (Wrong = 0, "damaged: cut at every one of" & Img (Bits)
                & " bits, never accepted");

         --  L_PACKET of packet 21 (bits 60 .. 72) one more, one less,
         --  shorter than the header, beyond the telegram
         Tel.Parse (Data, Bits, T, Status);
         declare
            L : constant Unsigned_64 := Unsigned_64 (T.Index (1).Length);
            procedure Try (Value : Unsigned_64; Expected : Tel.Status_T) is
               D : Byte_Array := Data;
            begin
               Set_Bits (D, Tel.Header_Bits + 10, 13, Value);
               Tel.Parse (D, Bits, T, Status);
               Check (Status = Expected, "damaged: L_PACKET" & Value'Image
                      & " for" & L'Image & ", got "
                      & Tel.Status_T'Image (Status));
            end Try;
         begin
            Try (L + 1, Tel.Packet_Structure);
            Try (L - 1, Tel.Packet_Structure);
            Try (10, Tel.Packet_Structure);
            Try (8191, Tel.Truncated);
         end;
      end;
   end Scenario_Telegram_Damaged;

   --  A message: Write_Fields with values that fit every variable
   function Values_For (Kind : MCat.Known_Message_T) return Msg.Value_Array
   is
      use ETCS_Variables;
      V : Msg.Value_Array := (others => 0);
   begin
      for I in 3 .. MCat.Field_Count (Kind) loop
         V (I) :=
           (case MCat.Fields (Kind) (I) is
               when T_TRAIN    => 1000 + Unsigned_64 (I),
               when M_ACK      => 1,
               when NID_C      => 5,
               when NID_BG     => 77,
               when NID_ENGINE => 424242,
               when others     => Unsigned_64 (I mod 2));
      end loop;
      return V;
   end Values_For;

   procedure Start (W : in out Writer_T; Kind : MCat.Known_Message_T) is
      OK : Boolean;
   begin
      ETCS_Bits.Clear (W);
      Msg.Write_Fields (W, Kind, Values_For (Kind), OK);
      Encodes_OK := Encodes_OK and then OK;
   end Start;

   function Message_Status
     (W         : in out Writer_T;
      Direction : Cat.Direction_T := Cat.Track_To_Train;
      Sender    : Cat.Sender_T := Cat.RBC) return Msg.Status_T
   is
      M      : Msg.Message_T;
      Status : Msg.Status_T;
      OK     : Boolean;
   begin
      Msg.Finish (W, OK);
      Encodes_OK := Encodes_OK and then OK;
      Msg.Parse (ETCS_Bits.Data (W), Direction, Sender, M, Status);
      return Status;
   end Message_Status;

   --  The radio message (8.4.4) and the message list (8.5 to 8.7)
   procedure Scenario_Message is
      W      : Writer_T;
      M      : Msg.Message_T;
      Status : Msg.Status_T;
      OK     : Boolean;
      Track  : constant Cat.Direction_T := Cat.Track_To_Train;
      Train  : constant Cat.Direction_T := Cat.Train_To_Track;
   begin
      Check (MCat.Kind (Track, 24) = MCat.Track_M24
             and then MCat.Kind (Train, 136) = MCat.Train_M136
             and then MCat.Kind (Track, 1) = MCat.Unknown
             and then MCat.Kind (Train, 24) = MCat.Unknown,
             "message: the list of 8.5");
      --  constants of the generated catalogue: the compiler knows them
      pragma Warnings (Off, "condition*");
      Check (MCat.Field_Count (MCat.Track_M38) = 4
             and then MCat.Field_Count (MCat.Track_M24) = 6
             and then MCat.Field_Count (MCat.Train_M146) = 5,
             "message: 38 has no NID_LRBG (8.7.16), 146 two T_TRAIN");
      pragma Warnings (On, "condition*");

      --  24 General message: optional packets, 65 twice (8.4.1.4.2)
      Start (W, MCat.Track_M24);
      Put (W, Gradient);
      Put (W, TSR (1));
      Put (W, TSR (2));
      Put (W, Linking);
      Msg.Finish (W, OK);
      Msg.Parse (ETCS_Bits.Data (W), Track, Cat.RBC, M, Status);
      Check (OK and then Encodes_OK and then Status = Msg.Accepted,
             "message 24: accepted, got " & Msg.Status_T'Image (Status));
      Check (M.Kind = MCat.Track_M24 and then M.Count = 4
             and then M.Length = ETCS_Bits.Byte_Length (W)
             and then Msg.Value (M, ETCS_Variables.T_TRAIN) = 1003
             and then Msg.Value (M, ETCS_Variables.NID_BG) = 77
             and then Msg.Value (M, ETCS_Variables.L_MESSAGE)
                      = Unsigned_64 (M.Length),
             "message 24: header and index");
      declare
         R        : Reader_T;
         L        : T5.Packet_T;
         Expected : T5.Packet_T := Linking;
      begin
         Msg.Open_Packet (M, 4, R);
         T5.Decode (R, L, OK);
         Expected.L_PACKET := L.L_PACKET;
         Check (OK and then L = Expected, "message 24: packet 5 decoded");
      end;

      --  a packet an RBC does not send (12), one 24 may not carry (15),
      --  twice a packet without repeat
      Start (W, MCat.Track_M24);
      Put_Random (W, Cat.Track_P12);
      Check (Message_Status (W) = Msg.Wrong_Sender,
             "message 24: packet 12 not from an RBC");
      Start (W, MCat.Track_M24);
      Put_Random (W, Cat.Track_P15);
      Check (Message_Status (W) = Msg.Packet_Not_Allowed,
             "message 24: packet 15 not allowed");
      Start (W, MCat.Track_M24);
      Put (W, Gradient);
      Put (W, Gradient);
      Check (Message_Status (W) = Msg.Duplicate_Packet,
             "message 24: packet 21 twice");
      --  an unknown packet: passed over where optional packets may come
      Start (W, MCat.Track_M24);
      Put_Unknown (W, 200, Track => True, Extra => 9);
      Put (W, Gradient);
      Msg.Finish (W, OK);
      Msg.Parse (ETCS_Bits.Data (W), Track, Cat.RBC, M, Status);
      Check (Status = Msg.Accepted and then M.Unknown = 1
             and then M.Count = 2,
             "message 24: unknown packet 200 passed over");
      Start (W, MCat.Track_M38);
      Put_Unknown (W, 200, Track => True, Extra => 9);
      Check (Message_Status (W) = Msg.Packet_Not_Allowed,
             "message 38: no packet at all");

      --  3 Movement Authority: packet 15 mandatory, first
      Start (W, MCat.Track_M3);
      Put (W, Gradient);
      Check (Message_Status (W) = Msg.Missing_Packet,
             "message 3: packet 15 missing");
      Start (W, MCat.Track_M3);
      Put_Random (W, Cat.Track_P15);
      Put (W, Gradient);
      Check (Message_Status (W) = Msg.Accepted,
             "message 3: packet 15, then 21");
      Start (W, MCat.Track_M3);
      Put (W, Gradient);
      Put_Random (W, Cat.Track_P15);
      Check (Message_Status (W) = Msg.Missing_Packet,
             "message 3: packet 15 not first");

      --  38: four fields, no packet
      Start (W, MCat.Track_M38);
      Msg.Finish (W, OK);
      Msg.Parse (ETCS_Bits.Data (W), Track, Cat.RBC, M, Status);
      Check (Status = Msg.Accepted and then M.Count = 0
             and then M.Length = 7
             and then Msg.Value (M, ETCS_Variables.NID_BG) = 0,
             "message 38: 7 bytes, no NID_LRBG");

      --  train to track: 136 with its position report and options
      Start (W, MCat.Train_M136);
      Put (W, Position_Report);
      Put_Error (W, 3);
      Put_Random (W, Cat.Train_P44);
      Put_Random (W, Cat.Train_P44);
      Msg.Finish (W, OK);
      Msg.Parse (ETCS_Bits.Data (W), Train, Cat.RBC, M, Status);
      Check (Status = Msg.Accepted and then M.Count = 4
             and then Msg.Value (M, ETCS_Variables.NID_ENGINE) = 424242,
             "message 136: packets 0, 4, 44 twice (8.4.1.5.1)");
      declare
         R        : Reader_T;
         P        : R0.Packet_T;
         Expected : R0.Packet_T := Position_Report;
      begin
         Msg.Open_Packet (M, 1, R);
         R0.Decode (R, P, OK);
         Expected.L_PACKET := P.L_PACKET;
         Check (OK and then P = Expected,
                "message 136: the position report decoded");
      end;
      Start (W, MCat.Train_M136);
      Put_Random (W, Cat.Train_P1);
      Check (Message_Status (W, Train) = Msg.Accepted,
             "message 136: packet 1 for the position report");
      Start (W, MCat.Train_M136);
      Put_Error (W, 3);
      Check (Message_Status (W, Train) = Msg.Missing_Packet,
             "message 136: no position report");
      Start (W, MCat.Train_M136);
      Put (W, Position_Report);
      Put_Error (W, 3);
      Put_Error (W, 4);
      Check (Message_Status (W, Train) = Msg.Duplicate_Packet,
             "message 136: packet 4 twice (8.4.1.5)");
      Start (W, MCat.Train_M146);
      Check (Message_Status (W, Train) = Msg.Accepted,
             "message 146: no position report (8.4.4.7.2)");
      Start (W, MCat.Train_M129);
      Put (W, Position_Report);
      Check (Message_Status (W, Train) = Msg.Missing_Packet,
             "message 129: packet 11 missing");

      --  L_MESSAGE, NID_MESSAGE, cut messages
      Start (W, MCat.Track_M24);
      Put (W, Gradient);
      Put (W, Linking);
      Msg.Finish (W, OK);
      declare
         Data  : constant Byte_Array := ETCS_Bits.Data (W);
         Wrong : Natural := 0;
         Cut   : Natural := 0;
      begin
         declare
            D : Byte_Array := Data;
         begin
            Set_Bits (D, 8, 10, Unsigned_64 (D'Length + 1));
            Msg.Parse (D, Track, Cat.RBC, M, Status);
            Check (Status = Msg.Bad_Length, "message: L_MESSAGE too long");
            D := Data;
            Set_Bits (D, 0, 8, 1);
            Msg.Parse (D, Track, Cat.RBC, M, Status);
            Check (Status = Msg.Unknown_Message, "message: NID_MESSAGE 1");
         end;
         for K in 0 .. Data'Length - 1 loop
            declare
               D : Byte_Array := Data (Data'First .. Data'First + K - 1);
            begin
               if K >= 3 then
                  Set_Bits (D, 8, 10, Unsigned_64 (K));
               end if;
               Msg.Parse (D, Track, Cat.RBC, M, Status);
               if Status = Msg.Accepted then
                  --  only where a packet ends on the cut
                  Cut := Cut + 1;
                  if M.Count >= 2 then
                     Wrong := Wrong + 1;
                  end if;
               end if;
            end;
         end loop;
         --  a cut just after a packet (padding below 8 bits) is a
         --  shorter message, with fewer packets
         Check (Wrong = 0, "message: cut at every one of"
                & Img (Data'Length) & " bytes, never whole ("
                & Img (Cut) & " cuts after a packet)");
      end;
   end Scenario_Message;

   --  8.4.2 and SUBSET-036 4.3.1.2: a telegram has 210 or 830 user bits
   procedure Scenario_Telegram_Length is
      W      : Writer_T;
      T      : Tel.Telegram_T;
      Status : Tel.Status_T;
      OK     : Boolean;
   begin
      Tel.Write_Header (W, Header);
      Put_Version_Order (W);
      Tel.Finish (W, Tel.Short_Bits, OK);
      declare
         Data : constant Byte_Array := ETCS_Bits.Data (W);
      begin
         for Bits in 209 .. 211 loop
            Tel.Parse (Data, Bits, T, Status);
            Check (Status = (if Bits = 210 then Tel.Accepted
                             else Tel.Bad_Length),
                   "length: short telegram read as" & Img (Bits)
                   & " bits, got " & Tel.Status_T'Image (Status));
         end loop;
      end;
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header);
      Put (W, Linking);
      Tel.Finish (W, Tel.Long_Bits, OK);
      declare
         Data : constant Byte_Array := ETCS_Bits.Data (W);
      begin
         for Bits in 829 .. 830 loop
            Tel.Parse (Data, Bits, T, Status);
            Check (Status = (if Bits = 830 then Tel.Accepted
                             else Tel.Bad_Length),
                   "length: long telegram read as" & Img (Bits)
                   & " bits, got " & Tel.Status_T'Image (Status));
         end loop;
      end;
      --  the builder: 210 or 830 only
      for Bits in 209 .. 211 loop
         ETCS_Bits.Clear (W);
         Tel.Write_Header (W, Header);
         Tel.Finish (W, Bits, OK);
         Check (OK = (Bits = 210), "length: Finish at" & Img (Bits)
                & " bits " & (if OK then "builds" else "refuses"));
      end loop;
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header);
      Tel.Finish (W, 300, OK);
      Check (not OK, "length: Finish at 300 bits refuses");
   end Scenario_Telegram_Length;

   --  SUBSET-026 3.16.1.1.1: a spare value of a variable is not
   --  compliant, the telegram or message is rejected (Invalid_Value).
   --  Spare values above the largest one (Q_SCALE 7.5.1.129, V_TSR
   --  7.5.1.173, Q_LINKREACTION 7.5.1.117, Q_DIR 7.5.1.103), between the
   --  defined ones (M_MODETEXTDISPLAY 7.5.1.73, M_VERSION 7.5.1.79), of
   --  bitsets (M_LINEGAUGE 7.5.1.67.1, M_LINEAXLELOADCAT 7.5.1.67.2,
   --  NC_TRAIN 7.5.1.84) and of BCD numbers (NID_MN 7.5.1.91.1,
   --  NID_OPERATIONAL 7.5.1.92, NID_RADIO 7.5.1.95)
   procedure Scenario_Spare_Values is
      use ETCS_Variables;
      W  : Writer_T;
      OK : Boolean;

      --  A long telegram of one packet written by Put_It
      generic
         with procedure Put_It (W : in out Writer_T);
      function Telegram_Of return Tel.Status_T;
      function Telegram_Of return Tel.Status_T is
      begin
         ETCS_Bits.Clear (W);
         Tel.Write_Header (W, Header);
         Put_It (W);
         Tel.Finish (W, Tel.Long_Bits, OK);
         return Telegram_Status (W);
      end Telegram_Of;

      procedure Expect (Status   : Tel.Status_T;
                        Expected : Tel.Status_T;
                        What     : String) is
      begin
         Check (Status = Expected, "spare: " & What & ", got "
                & Tel.Status_T'Image (Status));
      end Expect;

      --  the packet under test, set before each Telegram_Of
      G    : T21.Packet_T;
      L    : T5.Packet_T;
      S    : T65.Packet_T;
      Text : T73.Packet_T;
      Net  : T45.Packet_T;
      Ver  : M_VERSION_T;

      procedure Put_G (W : in out Writer_T) is
      begin
         Put (W, G);
      end Put_G;
      procedure Put_L (W : in out Writer_T) is
      begin
         Put (W, L);
      end Put_L;
      procedure Put_S (W : in out Writer_T) is
      begin
         Put (W, S);
      end Put_S;
      procedure Put_Text (W : in out Writer_T) is
         Done : Boolean;
      begin
         T73.Encode (Text, W, Done);
         Encodes_OK := Encodes_OK and then Done;
      end Put_Text;
      procedure Put_Net (W : in out Writer_T) is
         Done : Boolean;
      begin
         T45.Encode (Net, W, Done);
         Encodes_OK := Encodes_OK and then Done;
      end Put_Net;
      procedure Put_Ver (W : in out Writer_T) is
      begin
         Put_Version_Order (W, Ver);
      end Put_Ver;
      procedure Put_Unknown_Dir (W : in out Writer_T) is
      begin
         ETCS_Bits.Write (W, 8, 200);
         ETCS_Bits.Write (W, 2, 3);        -- Q_DIR spare
         ETCS_Bits.Write (W, 13, 40);
         ETCS_Bits.Fill (W, 17, One => True);
      end Put_Unknown_Dir;

      function G_Status is new Telegram_Of (Put_G);
      function L_Status is new Telegram_Of (Put_L);
      function S_Status is new Telegram_Of (Put_S);
      function Text_Status is new Telegram_Of (Put_Text);
      function Net_Status is new Telegram_Of (Put_Net);
      function Ver_Status is new Telegram_Of (Put_Ver);
      function Unknown_Status is new Telegram_Of (Put_Unknown_Dir);

      --  Valid_Code through a variable, so that the compiler does not
      --  fold the constants
      Code : Unsigned_64;
      function Valid (Var : Variable_T; Value : Unsigned_64) return Boolean
      is
      begin
         Code := Value;
         return Valid_Code (Var, Code);
      end Valid;

      type U64_Array is array (Positive range <>) of Unsigned_64;
   begin
      Encodes_OK := True;
      --  above the largest value, in the packet, in a loop item
      G := Gradient;
      Expect (G_Status, Tel.Accepted, "packet 21, Q_SCALE 1");
      G.Q_SCALE := 3;
      Expect (G_Status, Tel.Invalid_Value, "packet 21, Q_SCALE 3");
      G := Gradient (Q_DIR => 3);
      Expect (G_Status, Tel.Invalid_Value, "packet 21, Q_DIR 3");
      S := TSR (1, V_TSR => 120);
      Expect (S_Status, Tel.Accepted, "packet 65, V_TSR 120 (600 km/h)");
      S := TSR (1, V_TSR => 121);
      Expect (S_Status, Tel.Invalid_Value, "packet 65, V_TSR 121");
      L := Linking;
      L.D_LINK_List (2).Q_LINKREACTION := 3;
      Expect (L_Status, Tel.Invalid_Value,
              "packet 5, Q_LINKREACTION 3 in the second item");
      L := Linking;
      L.D_LINK_List (3).Q_LINKREACTION := 3;
      Expect (L_Status, Tel.Accepted,
              "packet 5, Q_LINKREACTION 3 after the last item (not sent)");
      Expect (Unknown_Status, Tel.Invalid_Value,
              "unknown packet 200, Q_DIR 3");

      --  between the defined values
      Text.Q_DIR := 1;
      for V in M_MODETEXTDISPLAY_T loop
         Text.M_MODETEXTDISPLAY := V;
         Expect (Text_Status,
                 (if V in 9 .. 11 | 13 then Tel.Invalid_Value
                  else Tel.Accepted),
                 "packet 73, M_MODETEXTDISPLAY" & V'Image);
      end loop;
      Text.M_MODETEXTDISPLAY := 0;
      Text.M_MODETEXTDISPLAY_2 := 13;
      Expect (Text_Status, Tel.Invalid_Value,
              "packet 73, the second M_MODETEXTDISPLAY 13");
      for V in M_VERSION_T range 16 .. 50 loop
         Ver := V;
         Expect (Ver_Status,
                 (if V in 18 .. 31 | 36 .. 47 then Tel.Invalid_Value
                  else Tel.Accepted),
                 "packet 2, M_VERSION" & V'Image);
      end loop;

      --  BCD: NID_MN of packet 45, present when Q_NETWORKTYPE is 1 or 2
      Net.Q_DIR := 1;
      Net.Q_NETWORKTYPE := 1;
      Net.Has_NID_MN := True;
      Net.NID_MN := 16#123456#;
      Expect (Net_Status, Tel.Accepted, "packet 45, NID_MN 123456");
      Net.NID_MN := 16#1234FF#;
      Expect (Net_Status, Tel.Accepted, "packet 45, NID_MN 1234FF");
      Net.NID_MN := 16#FFFFFF#;
      Expect (Net_Status, Tel.Accepted,
              "packet 45, NID_MN FFFFFF (no digit, not spare)");
      Net.NID_MN := 16#12A456#;
      Expect (Net_Status, Tel.Invalid_Value, "packet 45, NID_MN digit A");
      Net.NID_MN := 16#1234E5#;
      Expect (Net_Status, Tel.Invalid_Value, "packet 45, NID_MN digit E");
      Net.NID_MN := 16#12F456#;
      Expect (Net_Status, Tel.Invalid_Value,
              "packet 45, NID_MN a digit after F");
      Net.Q_NETWORKTYPE := 0;
      Net.Has_NID_MN := False;
      Expect (Net_Status, Tel.Accepted,
              "packet 45, NID_MN absent (Q_NETWORKTYPE 0)");

      --  the other codes, by the variables
      Check (Valid (NID_OPERATIONAL, 16#1234_5678#)
             and then Valid (NID_OPERATIONAL, 16#1234_FFFF#)
             and then Valid (NID_OPERATIONAL, 16#9FFF_FFFF#)
             and then not Valid (NID_OPERATIONAL, 16#FFFF_FFFF#)
             and then not Valid (NID_OPERATIONAL, 16#1234_B678#)
             and then not Valid (NID_OPERATIONAL, 16#1234_F678#),
             "spare: NID_OPERATIONAL, digits A .. E, F only at the end,"
             & " FFFF FFFF");
      Check (Valid (NID_RADIO, 16#FFFF_FFFF_FFFF_FFFF#)
             and then Valid (NID_RADIO, 16#0036_1234_5678_FFFF#)
             and then Valid (NID_RADIO, 16#9999_9999_9999_9999#)
             and then not Valid (NID_RADIO, 16#0036_1234_5678_FFFE#)
             and then not Valid (NID_RADIO, 16#C036_1234_5678_FFFF#)
             and then not Valid (NID_RADIO, 16#F036_1234_5678_FFFF#),
             "spare: NID_RADIO, digits A .. E not used, FFFF FFFF FFFF"
             & " FFFF the short number");
      Check (not Valid (M_LINEGAUGE, 0) and then Valid (M_LINEGAUGE, 1)
             and then Valid (M_LINEGAUGE, 15)
             and then not Valid (M_LINEGAUGE, 16)
             and then not Valid (M_LINEGAUGE, 128),
             "spare: M_LINEGAUGE 0 and bits 4 .. 7");
      Check (not Valid (M_LINEAXLELOADCAT, 0)
             and then Valid (M_LINEAXLELOADCAT, 8191)
             and then not Valid (M_LINEAXLELOADCAT, 8192)
             and then not Valid (M_LINEAXLELOADCAT, 32768),
             "spare: M_LINEAXLELOADCAT 0 and bits 13 .. 15");
      Check (Valid (NC_TRAIN, 0) and then Valid (NC_TRAIN, 7)
             and then not Valid (NC_TRAIN, 8)
             and then not Valid (NC_TRAIN, 16384),
             "spare: NC_TRAIN bits 3 .. 14");
      Check (not Valid (M_MODE, 18) and then Valid (M_MODE, 17)
             and then not Valid (V_TSR, 127) and then Valid (T_TRAIN, 0)
             and then not Valid (Q_SCALE, 4),
             "spare: above the largest value, and a code wider than the"
             & " variable");

      --  a message variable: M_VERSION of message 32, Q_SCALE of 2
      declare
         V : Msg.Value_Array := Values_For (MCat.Track_M32);
      begin
         for Version in Unsigned_64 range 17 .. 49 loop
            V (7) := Version;
            ETCS_Bits.Clear (W);
            Msg.Write_Fields (W, MCat.Track_M32, V, OK);
            Check (Message_Status (W)
                   = (if Version in 18 .. 31 | 36 .. 47
                      then Msg.Invalid_Value else Msg.Accepted),
                   "spare: message 32, M_VERSION" & Version'Image);
         end loop;
         V := Values_For (MCat.Track_M2);
         V (7) := 3;
         ETCS_Bits.Clear (W);
         Msg.Write_Fields (W, MCat.Track_M2, V, OK);
         Check (Message_Status (W) = Msg.Invalid_Value,
                "spare: message 2, Q_SCALE 3");
      end;
      --  a packet of a message: NID_OPERATIONAL of packet 140 in 24
      declare
         P : T140.Packet_T;
      begin
         P.Q_DIR := 1;
         for Id of U64_Array'(16#1234_FFFF#, 16#FFFF_FFFF#, 16#12D4_FFFF#)
         loop
            P.NID_OPERATIONAL := NID_OPERATIONAL_T (Id);
            Start (W, MCat.Track_M24);
            T140.Encode (P, W, OK);
            Encodes_OK := Encodes_OK and then OK;
            Check (Message_Status (W)
                   = (if Id = 16#1234_FFFF# then Msg.Accepted
                      else Msg.Invalid_Value),
                   "spare: message 24, packet 140, NID_OPERATIONAL"
                   & Id'Image);
         end loop;
      end;
      Check (Encodes_OK, "spare: every packet encodes");
   end Scenario_Spare_Values;

   --  7.4.2 "Transmitted by", 8.5.3: what the sender may send. The
   --  packets a balise does not transmit (13 by a loop; 15, 57, 58, 63,
   --  64, 140 by an RBC; 143 by an RIU) are rejected in a telegram and
   --  accepted in a radio message of their sender; message 37 comes
   --  from an RIU only
   procedure Scenario_Senders is
      W      : Writer_T;
      OK     : Boolean;
      Status : Msg.Status_T;
      type Kind_Array is array (Positive range <>) of Cat.Known_Kind_T;
      Not_Balise : constant Kind_Array :=
        (Cat.Track_P13, Cat.Track_P15, Cat.Track_P57, Cat.Track_P58,
         Cat.Track_P63, Cat.Track_P64, Cat.Track_P140, Cat.Track_P143);
   begin
      Encodes_OK := True;
      for K of Not_Balise loop
         ETCS_Bits.Clear (W);
         Tel.Write_Header (W, Header);
         Put_Random (W, K);
         Tel.Finish (W, Tel.Long_Bits, OK);
         Check (OK and then Telegram_Status (W) = Tel.Wrong_Sender,
                "sender: packet" & Cat.NID_Of (K)'Image
                & " in a balise telegram rejected");
      end loop;
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header);
      Put_Random (W, Cat.Track_P5);
      Tel.Finish (W, Tel.Long_Bits, OK);
      Check (Telegram_Status (W) = Tel.Accepted,
             "sender: packet 5 (any sender) in a balise telegram");

      --  15 first in message 3, then 57, 58, 64, 140; 63 in 2
      Start (W, MCat.Track_M3);
      for K of Not_Balise (2 .. 7) loop
         if K /= Cat.Track_P63 then
            Put_Random (W, K);
         end if;
      end loop;
      Status := Message_Status (W);
      Check (Status = Msg.Accepted,
             "sender: packets 15, 57, 58, 64, 140 in message 3 from an"
             & " RBC, got " & Msg.Status_T'Image (Status));
      Start (W, MCat.Track_M2);
      Put_Random (W, Cat.Track_P63);
      Check (Message_Status (W) = Msg.Accepted,
             "sender: packet 63 in message 2 from an RBC");
      Start (W, MCat.Track_M24);
      Put_Random (W, Cat.Track_P143);
      Check (Message_Status (W, Sender => Cat.RIU) = Msg.Accepted,
             "sender: packet 143 in message 24 from an RIU");
      Start (W, MCat.Track_M24);
      Put_Random (W, Cat.Track_P143);
      Check (Message_Status (W) = Msg.Wrong_Sender,
             "sender: packet 143 in message 24 from an RBC");
      Start (W, MCat.Track_M24);
      Put_Random (W, Cat.Track_P57);
      Check (Message_Status (W, Sender => Cat.RIU) = Msg.Wrong_Sender,
             "sender: packet 57 in message 24 from an RIU");
      Start (W, MCat.Track_M24);
      Put_Random (W, Cat.Track_P13);
      Check (Message_Status (W) = Msg.Wrong_Sender,
             "sender: packet 13 (a loop's) in message 24 from an RBC");

      --  8.5.3: message 37 (infill MA) by an RIU only
      Start (W, MCat.Track_M37);
      Put_Random (W, Cat.Track_P136);
      Put_Random (W, Cat.Track_P12);
      Check (Message_Status (W, Sender => Cat.RIU) = Msg.Accepted,
             "sender: message 37 from an RIU");
      Start (W, MCat.Track_M37);
      Put_Random (W, Cat.Track_P136);
      Put_Random (W, Cat.Track_P12);
      Check (Message_Status (W) = Msg.Wrong_Sender,
             "sender: message 37 from an RBC");
      Start (W, MCat.Track_M3);
      Put_Random (W, Cat.Track_P15);
      Check (Message_Status (W, Sender => Cat.RIU) = Msg.Wrong_Sender,
             "sender: message 3 from an RIU");
      --  train to track: the receiver (8.5.2), message 153 to an RIU
      Start (W, MCat.Train_M153);
      Put (W, Position_Report);
      Check (Message_Status (W, Cat.Train_To_Track, Cat.RBC)
             = Msg.Wrong_Sender,
             "sender: message 153 (radio infill request) to an RBC");
      Check (Encodes_OK, "sender: every packet encodes");
   end Scenario_Senders;

   --  The core: telegrams and messages through the BTM and RTM ports
   procedure Scenario_Received is
      W      : Writer_T;
      OK     : Boolean;
      Before : Natural;
      Id     : constant Unsigned_64 :=
        ETCS_Variables.Balise_Group_Identity (123, 4567);

      function JRU_Event (Event : Natural) return Natural is
      begin
         for I in 1 .. Rec_Count loop
            if Recs (I).Port = JRU and then Byte_At (I, 1) = Event then
               return I;
            end if;
         end loop;
         return 0;
      end JRU_Event;

      function Rejected_Telegrams return Natural is
         N : Natural := 0;
      begin
         for S in Tel.Status_T loop
            if S /= Tel.Accepted then
               N := N + EVC_Received.Telegram_Count (S);
            end if;
         end loop;
         return N;
      end Rejected_Telegrams;
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      EVC_Core.Tick (100);
      Take;
      Check (not EVC_Received.Has_Telegram
             and then not EVC_Received.Has_Message,
             "received: nothing after power-up");

      --  a telegram
      Tel.Write_Header (W, Header);
      Put (W, Linking);
      Put (W, Gradient);
      Tel.Finish (W, Tel.Long_Bits, OK);
      Input (BTM, BTM_Of (ETCS_Bits.Data (W), ETCS_Bits.Position (W)));
      Check (not EVC_Received.Has_Telegram,
             "received: the telegram waits for the cycle");
      EVC_Core.Tick (100);
      Take;
      Check (EVC_Received.Has_Telegram
             and then EVC_Received.Telegram_Count (Tel.Accepted) = 1
             and then EVC_Received.Last_Telegram.Count = 2
             and then EVC_Received.Last_Telegram.Header = Header,
             "received: the telegram is kept");
      declare
         I : constant Natural := JRU_Event (2);
      begin
         Check (I /= 0 and then Rec_Length (I) = JRU_Record_Length
                and then Byte_At (I, 2) = Natural (Id and 16#FF#)
                and then Byte_At (I, 3) = Natural (Shift_Right (Id, 8)
                                                    and 16#FF#)
                and then Byte_At (I, 4) = Natural (Shift_Right (Id, 16)),
                "received: JRU event 2, the balise group");
      end;
      declare
         R        : Reader_T;
         L        : T5.Packet_T;
         Expected : T5.Packet_T := Linking;
      begin
         EVC_Received.Open_Telegram_Packet (1, R);
         T5.Decode (R, L, OK);
         Expected.L_PACKET := L.L_PACKET;
         Check (OK and then L = Expected,
                "received: packet 1 of the telegram decodes on demand");
      end;

      --  a radio message
      Start (W, MCat.Track_M24);
      Put (W, TSR (5));
      Msg.Finish (W, OK);
      Input (RTM, ETCS_Bits.Data (W));
      EVC_Core.Tick (100);
      Take;
      Check (EVC_Received.Has_Message
             and then EVC_Received.Message_Count (Msg.Accepted) = 1
             and then EVC_Received.Last_Message.Kind = MCat.Track_M24
             and then EVC_Received.Last_Message.Count = 1,
             "received: the message is kept");
      declare
         I : constant Natural := JRU_Event (3);
      begin
         Check (I /= 0 and then Byte_At (I, 2) = 24
                and then Byte_At (I, 3) = ETCS_Bits.Byte_Length (W),
                "received: JRU event 3, NID_MESSAGE and L_MESSAGE");
      end;
      Check_Golden ("received_telegram_message");

      --  rejections, counted by reason; the last accepted one stays
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header (16));
      Put (W, Gradient);
      Tel.Finish (W, Tel.Long_Bits, OK);
      Input (BTM, BTM_Of (ETCS_Bits.Data (W), ETCS_Bits.Position (W)));
      EVC_Core.Tick (100);
      Take;
      Check (EVC_Received.Telegram_Count (Tel.Unsupported_Version) = 1
             and then EVC_Received.Last_Telegram.Count = 2
             and then JRU_Event (2) = 0,
             "received: version 1.0 rejected and counted");
      Input (RTM, RTM_Payload (5, 5));
      EVC_Core.Tick (100);
      Check (EVC_Received.Message_Count (Msg.Truncated) = 1
             and then EVC_Received.Last_Message.Count = 1,
             "received: a message of 5 bytes, truncated");

      --  a long telegram cut at every bit from the header on, through
      --  the port: the port takes 210 bits only (a short telegram, whose
      --  packets then go past the end), the others are not of its shape
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header);
      Put (W, Gradient);
      Put (W, Linking);
      Tel.Finish (W, Tel.Long_Bits, OK);
      Before := Rejected_Telegrams;
      declare
         Data        : constant Byte_Array := ETCS_Bits.Data (W);
         Bits        : constant Natural := ETCS_Bits.Position (W);
         Port_Before : constant Natural := EVC_Core.Rejected (BTM);
      begin
         for B in Tel.Header_Bits .. Bits - 1 loop
            Input (BTM, BTM_Of (Data, B));
            EVC_Core.Tick (100);
            Take;
         end loop;
         Check (Rejected_Telegrams - Before = 1
                and then EVC_Received.Telegram_Count (Tel.Truncated) = 1
                and then EVC_Core.Rejected (BTM) - Port_Before
                         = Bits - Tel.Header_Bits - 1
                and then EVC_Received.Telegram_Count (Tel.Accepted) = 1,
                "received: cut at every bit from 50 to" & Img (Bits - 1)
                & ", every one rejected (210 by the parser, the others"
                & " by the port)");
      end;

      --  a spare value (3.16.1.1.1), and what only an RIU sends: counted,
      --  not kept
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header);
      Put (W, TSR (7, V_TSR => 121));
      Tel.Finish (W, Tel.Long_Bits, OK);
      Input (BTM, BTM_Of (ETCS_Bits.Data (W), ETCS_Bits.Position (W)));
      Start (W, MCat.Track_M37);
      Put_Random (W, Cat.Track_P136);
      Put_Random (W, Cat.Track_P12);
      Msg.Finish (W, OK);
      Input (RTM, ETCS_Bits.Data (W));
      Start (W, MCat.Track_M24);
      Put (W, TSR (5, V_TSR => 127));
      Msg.Finish (W, OK);
      Input (RTM, ETCS_Bits.Data (W));
      EVC_Core.Tick (100);
      Take;
      Check (EVC_Received.Telegram_Count (Tel.Invalid_Value) = 1
             and then EVC_Received.Last_Telegram.Count = 2
             and then EVC_Received.Message_Count (Msg.Wrong_Sender) = 1
             and then EVC_Received.Message_Count (Msg.Invalid_Value) = 1
             and then EVC_Received.Last_Message.Kind = MCat.Track_M24
             and then EVC_Received.Last_Message.Count = 1
             and then JRU_Event (2) = 0 and then JRU_Event (3) = 0,
             "received: V_TSR spare in a telegram and in a message,"
             & " message 37 from the RBC session: counted, not kept");

      --  more than a balise group in one cycle
      ETCS_Bits.Clear (W);
      Tel.Write_Header (W, Header);
      Put (W, Gradient);
      Tel.Finish (W, Tel.Long_Bits, OK);
      for I in 1 .. 9 loop
         Input (BTM, BTM_Of (ETCS_Bits.Data (W), ETCS_Bits.Position (W)));
      end loop;
      EVC_Core.Tick (100);
      Take;
      Check (EVC_Core.Overflowed (BTM) = 1
             and then EVC_Received.Telegram_Count (Tel.Accepted) = 9,
             "received: 9 telegrams in a cycle, 8 kept, 1 dropped");
      EVC_Core.Initialise;
      Check (not EVC_Received.Has_Telegram
             and then EVC_Received.Telegram_Count (Tel.Accepted) = 0,
             "received: Initialise forgets");
   end Scenario_Received;

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

   package Pos renames EVC_Position;
   package Odo renames EVC_Odometry;
   package T58 renames ETCS_Track_Packets.P58;
   package T79 renames ETCS_Track_Packets.P79;
   package T16 renames ETCS_Track_Packets.P16;
   package R1 renames ETCS_Train_Packets.P1;

   use type EVC_Distances.Cm_T;
   use type EVC_Distances.Sense_T;
   use type EVC_Distances.Direction_T;
   use type Pos.Status_T;
   use type Pos.Report_Kind_T;
   use type Pos.Cab_T;
   use type Odo.Cold_T;
   use type R1.Packet_T;
   use type ETCS_Variables.NID_BG_T;
   use type ETCS_Variables.Q_LINKREACTION_T;
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
   use type EVC_Location.Anchor_T;

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

   procedure Add_Group (G : Group_Def) is
   begin
      Track_N := Track_N + 1;
      Track (Track_N) := G;
   end Add_Group;

   function Balise_At (G : Group_Def; K : Natural) return Integer_64 is
     (if G.Reversed then G.At_Cm - Integer_64 (K) * Spacing
      else G.At_Cm + Integer_64 (K) * Spacing);

   --  The telegram of balise K (N_PIG) of G, with the BTM stamp
   function Telegram_Of (G : Group_Def; K : Natural; Stamp : Integer_64)
     return Byte_Array
   is
      W  : Writer_T;
      OK : Boolean;
      H  : constant Tel.Header_T :=
        (Q_UPDOWN  => 1,
         M_VERSION => 48,
         Q_MEDIA   => 0,
         N_PIG     => ETCS_Variables.N_PIG_T (K),
         N_TOTAL   => ETCS_Variables.N_TOTAL_T (G.Balises - 1),
         M_DUP     => (if G.Dup_1_2 and then K = 0 then 1
                       elsif G.Dup_1_2 and then K = 1 then 2
                       else 0),
         M_MCOUNT  => 7,
         NID_C     => 123,
         NID_BG    => G.NID_BG,
         Q_LINK    => (if G.Linked then 1 else 0));
   begin
      Tel.Write_Header (W, H);
      if G.Has_Linking then
         Put (W, G.Linking);
      end if;
      if G.Has_Geo then
         T79.Encode (G.Geo, W, OK);
         Encodes_OK := Encodes_OK and then OK;
      end if;
      if G.Reposition then
         declare
            P : T16.Packet_T;
         begin
            P.Q_DIR := 2;
            P.Q_SCALE := 1;
            P.L_SECTION := 100;
            T16.Encode (P, W, OK);
            Encodes_OK := Encodes_OK and then OK;
         end;
      end if;
      Tel.Finish (W, Tel.Long_Bits, OK);
      Encodes_OK := Encodes_OK and then OK;
      return BTM_Of (ETCS_Bits.Data (W), ETCS_Bits.Position (W), Stamp);
   end Telegram_Of;

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
   Geo_Seen  : Unsigned_32 := 0;
   Geo_Count : Natural := 0;

   procedure Forget is
   begin
      JRU_Seen := (others => 0);
      Seen := Pos.No_Triggers;
      Geo_Count := 0;
   end Forget;

   procedure Collect is
      T : constant Pos.Triggers_T := Pos.Report_Triggers;
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = JRU and then Byte_At (I, 1) <= 15 then
            JRU_Seen (Byte_At (I, 1)) := JRU_Seen (Byte_At (I, 1)) + 1;
            for B in 2 .. 4 loop
               JRU_Last (Byte_At (I, 1), B) := Byte_At (I, B);
            end loop;
         elsif Recs (I).Port = DMI and then Rec_Length (I) = 28
           and then Byte_At (I, 1) = Natural (EVC_DMI_Port.MSG_STATUS)
         then
            Geo_Count := Geo_Count + 1;
            Geo_Seen := Unsigned_32 (Byte_At (I, 22))
              + 256 * (Unsigned_32 (Byte_At (I, 23))
                       + 256 * (Unsigned_32 (Byte_At (I, 24))
                                + 256 * Unsigned_32 (Byte_At (I, 25))));
         end if;
      end loop;
      Seen :=
        (Standstill_Reached => Seen.Standstill_Reached
                               or else T.Standstill_Reached,
         Mode_Changed       => Seen.Mode_Changed or else T.Mode_Changed,
         Level_Changed      => Seen.Level_Changed or else T.Level_Changed,
         Standstill_Left    => Seen.Standstill_Left or else T.Standstill_Left,
         LRBG_Passed        => Seen.LRBG_Passed or else T.LRBG_Passed,
         Periodic_Time      => Seen.Periodic_Time or else T.Periodic_Time,
         Periodic_Distance  => Seen.Periodic_Distance
                               or else T.Periodic_Distance,
         Location_Passed    => Seen.Location_Passed
                               or else T.Location_Passed,
         Immediate          => Seen.Immediate or else T.Immediate);
   end Collect;

   --  The odometer sample of now
   procedure Sample (Moving : Integer) is
      V : constant Unsigned_16 := (if Moving = 0 then 0 else Speed_Cms);
   begin
      Input (Odometer,
             Odometer_Payload (Odo_D, Odo_Over, Odo_Under, V, V, V,
                               (if Moving > 0 then 1
                                elsif Moving < 0 then 2 else 0),
                               Cold_Byte, Cold_Distance));
   end Sample;

   procedure Cycle is
   begin
      EVC_Core.Tick (100);
      Take;
      Collect;
   end Cycle;

   --  A new track, the train at Start_Cm, the odometer reading Start_Cm,
   --  one sample at standstill (the frame starts there), cab A active
   procedure Start_Track (Start_Cm : Integer_64 := 0) is
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      Forget;
      Track_N := 0;
      Train_Cm := Start_Cm;
      Odo_D := Start_Cm;
      Odo_Over := 0;
      Odo_Under := 0;
      Error_Per_Mille := 0;
      Bound_Per_Mille := 20;
      Speed_Cms := 1000;
      Cold_Byte := 0;
      Cold_Distance := 0;
      Input (TIU, (1, 1));
      Sample (0);
      Cycle;
   end Start_Track;

   --  One step of Step_Cm (signed): the balises crossed, then the sample
   procedure Step (Step_Cm : Integer_64) is
      Old_Train : constant Integer_64 := Train_Cm;
      Old_D     : constant Integer_64 := Odo_D;
      New_Train : constant Integer_64 := Train_Cm + Step_Cm;
      Measured  : constant Integer_64 :=
        Step_Cm * (1000 + Error_Per_Mille) / 1000;
      type Crossing is record
         At_Cm : Integer_64;
         G, K  : Natural;
      end record;
      List : array (1 .. 64) of Crossing;
      N    : Natural := 0;

      function Crossed (P : Integer_64) return Boolean is
        (if Step_Cm > 0 then P > Old_Train and then P <= New_Train
         else P < Old_Train and then P >= New_Train);
   begin
      for G in 1 .. Track_N loop
         for K in 0 .. Track (G).Balises - 1 loop
            if Track (G).Skip /= K + 1
              and then Crossed (Balise_At (Track (G), K))
            then
               N := N + 1;
               List (N) := (Balise_At (Track (G), K), G, K);
            end if;
         end loop;
      end loop;
      --  in the order of passing
      for I in 2 .. N loop
         for J in reverse 2 .. I loop
            if (Step_Cm > 0 and then List (J).At_Cm < List (J - 1).At_Cm)
              or else (Step_Cm < 0
                       and then List (J).At_Cm > List (J - 1).At_Cm)
            then
               declare
                  Swap : constant Crossing := List (J);
               begin
                  List (J) := List (J - 1);
                  List (J - 1) := Swap;
               end;
            end if;
         end loop;
      end loop;
      for I in 1 .. N loop
         Input (BTM, Telegram_Of
                       (Track (List (I).G), List (I).K,
                        Old_D + (List (I).At_Cm - Old_Train) * Measured
                                / Step_Cm));
      end loop;
      Train_Cm := New_Train;
      Odo_D := Odo_D + Measured;
      Odo_Over := Odo_Over + abs Measured * Bound_Per_Mille / 1000;
      Odo_Under := Odo_Under + abs Measured * Bound_Per_Mille / 1000;
      Sample ((if Step_Cm > 0 then 1 elsif Step_Cm < 0 then -1 else 0));
      Cycle;
   end Step;

   --  Move to the track position To_Cm in steps of Step_Cm, then stand
   procedure Run_To (To_Cm : Integer_64; Step_Cm : Integer_64 := 1000) is
   begin
      while Train_Cm /= To_Cm loop
         Step (if To_Cm > Train_Cm
               then Integer_64'Min (Step_Cm, To_Cm - Train_Cm)
               else -Integer_64'Min (Step_Cm, Train_Cm - To_Cm));
      end loop;
   end Run_To;

   procedure Stand is
   begin
      Sample (0);
      Cycle;
   end Stand;

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
                     Nominal  : Boolean := True) return T5.Packet_T
   is
      L : T5.Packet_T;
   begin
      L.Q_DIR := 1;
      L.Q_SCALE := 1;
      L.D_LINK := ETCS_Variables.D_LINK_T (D_Links (D_Links'First));
      L.NID_BG := ETCS_Variables.NID_BG_T (NIDs (NIDs'First));
      L.Q_LINKORIENTATION := (if Nominal then 1 else 0);
      L.Q_LINKREACTION := ETCS_Variables.Q_LINKREACTION_T (Reaction);
      L.Q_LOCACC := ETCS_Variables.Q_LOCACC_T (Locacc);
      L.N_ITER := ETCS_Variables.N_ITER_T (D_Links'Length - 1);
      for I in 1 .. D_Links'Length - 1 loop
         L.D_LINK_List (I).D_LINK :=
           ETCS_Variables.D_LINK_T (D_Links (D_Links'First + I));
         L.D_LINK_List (I).NID_BG :=
           ETCS_Variables.NID_BG_T (NIDs (NIDs'First + I));
         L.D_LINK_List (I).Q_LINKORIENTATION := (if Nominal then 1 else 0);
         L.D_LINK_List (I).Q_LINKREACTION :=
           ETCS_Variables.Q_LINKREACTION_T (Reaction);
         L.D_LINK_List (I).Q_LOCACC := ETCS_Variables.Q_LOCACC_T (Locacc);
      end loop;
      return L;
   end Link_To;

   function Group (NID : Natural; At_M : Integer_64;
                   Balises : Positive := 2) return Group_Def
   is
      G : Group_Def;
   begin
      G.NID_BG := ETCS_Variables.NID_BG_T (NID);
      G.At_Cm := At_M * 100;
      G.Balises := Balises;
      return G;
   end Group;

   function With_Links (G : Group_Def; L : T5.Packet_T) return Group_Def is
      R : Group_Def := G;
   begin
      R.Has_Linking := True;
      R.Linking := L;
      return R;
   end With_Links;

   --  Packet 0 and 1 through the encoder and back
   function Round_Trip (P : R0.Packet_T) return Boolean is
      W  : Writer_T;
      R  : Reader_T;
      D  : R0.Packet_T;
      OK : Boolean;
      E  : R0.Packet_T := P;
   begin
      R0.Encode (P, W, OK);
      if not OK then
         return False;
      end if;
      ETCS_Bits.Load (R, ETCS_Bits.Data (W), ETCS_Bits.Position (W));
      R0.Decode (R, D, OK);
      E.L_PACKET := D.L_PACKET;
      return OK and then D = E;
   end Round_Trip;

   function Round_Trip (P : R1.Packet_T) return Boolean is
      W  : Writer_T;
      R  : Reader_T;
      D  : R1.Packet_T;
      OK : Boolean;
      E  : R1.Packet_T := P;
   begin
      R1.Encode (P, W, OK);
      if not OK then
         return False;
      end if;
      ETCS_Bits.Load (R, ETCS_Bits.Data (W), ETCS_Bits.Position (W));
      R1.Decode (R, D, OK);
      E.L_PACKET := D.L_PACKET;
      return OK and then D = E;
   end Round_Trip;

   --  The first balise group passed: the position becomes valid, the
   --  group the LRBG and the SOLR (3.6.1.4, 3.6.2.2.2 a, 3.6.4.2.2 b),
   --  the confidence interval from Q_NVLOCACC and the odometer
   --  (3.6.4.1.3, 3.6.4.1.5); the position report (3.6.5.1.2)
   procedure Scenario_Position_First_Group is
      P : R0.Packet_T;
   begin
      Start_Track;
      Add_Group (Group (10, 100));
      Check (Pos.Status = Pos.Unknown and then not Pos.LRBG.Valid,
             "first group: position unknown before");
      Check (Pos.Report_Kind = Pos.Report_P0
             and then Pos.Position_Report (M_SB, L1).NID_BG = 16383
             and then Pos.Position_Report (M_SB, L1).D_LRBG = 32767,
             "first group: LRBG unknown in the report (3.6.2.2.2.1)");
      Run_To (10_000);
      Check (Pos.Status = Pos.Unknown and then Pos.Passage_Open,
             "first group: balise 1 read, the passage is open");
      Run_To (20_000);
      Check (Pos.Status = Pos.Valid, "first group: position valid");
      Check (Pos.LRBG.Valid and then Pos.LRBG.Id.NID_BG = 10
             and then Pos.LRBG.X = 10_000
             and then Pos.LRBG.Orientation = EVC_Distances.Plus
             and then Pos.LRBG.Locacc = 1_200,
             "first group: LRBG, its location reference, orientation, "
             & "Q_NVLOCACC");
      Check (Pos.SOLR = Pos.LRBG, "first group: the SOLR is the LRBG");
      Check (Pos.Estimated_Front = 10_300,
             "first group: estimated front end 100 m + antenna 3 m, got"
             & EVC_Distances.Cm_T'Image (Pos.Estimated_Front));
      --  2 % of 110 m since the sample before the detection
      Check (Pos.Doubt_Over = 1_420 and then Pos.Doubt_Under = 1_420,
             "first group: confidence 12 m + 2.2 m, got"
             & EVC_Distances.Cm_T'Image (Pos.Doubt_Over));
      Check (Pos.Min_Safe_Front = 10_300 - 1_420
             and then Pos.Max_Safe_Front = 10_300 + 1_420,
             "first group: min and max safe front ends");
      Check (JRU_Seen (10) = 1 and then JRU_Id (10) = Id (10)
             and then JRU_Seen (8) = 1 and then JRU_Last (8, 2) = 1,
             "first group: JRU new LRBG and position valid");
      Check (Seen.LRBG_Passed and then not Seen.Location_Passed,
             "first group: report trigger 3.6.5.1.4 j)");
      Check (Onboard_Field (1) = 32,
             "first group: MSG_ONBOARD position valid, got"
             & Img (Onboard_Field (1)));
      Stand;
      Check (Pos.Report_Triggers.Standstill_Reached,
             "first group: standstill reached (3.6.5.1.4 a)");
      P := Pos.Position_Report (M_SB, L1);
      Check (P.NID_C = 123 and then P.NID_BG = 10 and then P.Q_SCALE = 0
             and then P.D_LRBG = 1_030
             and then P.L_DOUBTOVER = 142 and then P.L_DOUBTUNDER = 142
             and then P.Q_DIRLRBG = 1 and then P.Q_DLRBG = 1
             and then P.Q_DIRTRAIN = 1 and then P.V_TRAIN = 127
             and then P.M_MODE = 6 and then P.M_LEVEL = 2
             and then P.Q_INTEGRITY = 0,
             "first group: packet 0");
      Check (Round_Trip (P), "first group: packet 0 round trip");
      Step (1_000);
      Check (Pos.Report_Triggers.Standstill_Left
             and then Pos.Position_Report (M_SB, L1).V_TRAIN = 7,
             "first group: standstill left, 36 km/h reported as 7");
      Check_Golden ("position_first_group");
   end Scenario_Position_First_Group;

   --  Linked groups with their windows met (3.4.4.4.3, 3.4.4.4.6 a):
   --  each becomes LRBG and SOLR with the accuracy of the linking
   --  (3.6.4.1.3); a location item of packet 58 follows by the linking
   --  distance (3.6.4.2.5 a), and its "max" location passes
   procedure Scenario_Linking is
      P58 : T58.Packet_T;
      OK  : Boolean;
      Fired_At : Integer_64 := 0;
   begin
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30))));
      Add_Group (Group (20, 600));
      Add_Group (Group (30, 1000, 3));
      Run_To (15_000);
      Check (Pos.Linking.Stored and then Pos.Linking.Count = 2
             and then Pos.Linking.Expected = 1
             and then EVC_Linking.Checked (Pos.Linking),
             "linking: stored, the window of the first group supervised");
      P58.Q_SCALE := 1;
      P58.T_CYCLOC := 255;
      P58.D_CYCLOC := 32_767;
      P58.M_LOC := 2;
      P58.N_ITER := 1;
      P58.D_LOC_List (1) := (D_LOC => 800, Q_LGTLOC => 1);
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Check (OK and then Pos.Report_Parameters_Stored,
             "linking: packet 58 against the LRBG");
      Pos.Set_Report_Parameters (P58, (123, 999), OK);
      Check (not OK, "linking: packet 58 against an unknown group refused");
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Forget;
      Run_To (65_000);
      Check (Pos.LRBG.Id.NID_BG = 20 and then Pos.LRBG.Locacc = 500
             and then Pos.SOLR.Id.NID_BG = 20
             and then Pos.Linking.Expected = 2
             and then Pos.Linking.Solr = 1,
             "linking: the second group, LRBG and SOLR, Q_LOCACC 5 m");
      Check (not Seen.LRBG_Passed,
             "linking: M_LOC 2, no report at the LRBG (3.6.5.1.5 d)");
      Check (Pos.Doubt_Over = 500 + 120,
             "linking: the confidence restarts from the new LRBG, got"
             & EVC_Distances.Cm_T'Image (Pos.Doubt_Over));
      --  the location, 800 m from the first group, is 300 m from the
      --  second; it passes when the max safe front end reaches it
      while Train_Cm < 95_000 and then Fired_At = 0 loop
         Step (1_000);
         if Pos.Report_Triggers.Location_Passed then
            Fired_At := Train_Cm;
         end if;
      end loop;
      Check (Fired_At = 89_000,
             "linking: the max safe front end passes the location at 890 m"
             & " (relocated by the linking distance), got"
             & Integer_64'Image (Fired_At));
      Run_To (110_000);
      Check (Pos.LRBG.Id.NID_BG = 30 and then Pos.Linking.Expected = 3
             and then not EVC_Linking.Checked (Pos.Linking),
             "linking: the third group, linking no longer checked");
      Check (JRU_Seen (4) = 0 and then JRU_Seen (5) = 0
             and then JRU_Seen (6) = 0,
             "linking: no reaction, nothing unexpected, nothing missed");
      Check (Pos.Doubt_Over = 500 + 220,
             "linking: confidence against the third group");
      Check_Golden ("position_linking");
   end Scenario_Linking;

   --  A linked group missed (3.16.2.3.1 b, 3.16.2.3.1.1), one detected
   --  in rear of its window (a), one of a later group (c), a group not
   --  in the linking (3.4.4.4.2), one passed the wrong way (3.4.4.4.7)
   procedure Scenario_Linking_Errors is
      Missed_At : Integer_64 := 0;
   begin
      --  missed: announced at 600 m with 5 m, nothing there
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30))));
      Add_Group (Group (30, 1000));
      Run_To (20_000);
      while Train_Cm < 70_000 and then Missed_At = 0 loop
         Step (1_000);
         if Pos.Missed_Group_Found then
            Missed_At := Train_Cm;
            Check (Pos.Linking_Reaction_Requested and then Pos.Reaction = 1,
                   "missed: service brake requested (Q_LINKREACTION 1)");
         end if;
      end loop;
      --  min safe antenna = (X - 100 m) - 12 m - 2 % of (X - 90 m) above
      --  605 m + 1.3 m
      Check (Missed_At = 63_000,
             "missed: detected at 630 m, got" & Integer_64'Image (Missed_At));
      Check (JRU_Seen (6) = 1 and then JRU_Id (6) = Id (20)
             and then JRU_Seen (4) = 1 and then JRU_Last (4, 2) = 1
             and then JRU_Last (4, 3) = Pos.Cause_Not_Detected
             and then JRU_Last (4, 4) = 1,
             "missed: JRU missed group and linking reaction");
      Check (Pos.Linking.Expected = 2 and then Pos.LRBG.Id.NID_BG = 10,
             "missed: the next window, the LRBG stays");
      Run_To (105_000);
      Check (Pos.LRBG.Id.NID_BG = 30, "missed: the next group accepted");

      --  in rear of its window: at 400 m instead of 600 m +- 5 m
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30), 5, 0)));
      Add_Group (Group (20, 400));
      Run_To (45_000);
      Check (Pos.LRBG.Id.NID_BG = 10 and then JRU_Seen (4) = 1
             and then JRU_Last (4, 2) = 0
             and then JRU_Last (4, 3) = Pos.Cause_Early,
             "early: rejected, train trip requested (3.16.2.3.1 a)");

      --  the group announced after the expected one comes first (c,
      --  3.4.4.4.6.1): it is checked against its own window
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30), 5, 2)));
      --  30, announced at 1000 m, lies inside the window of 20
      Add_Group (Group (30, 602));
      Run_To (65_000);
      Check (JRU_Seen (4) = 2 and then JRU_Last (4, 3) = Pos.Cause_Early
             and then Pos.LRBG.Id.NID_BG = 10,
             "other group: reaction c) for 20, then 30 early in its own "
             & "window");

      --  a linked group not in the linking information (3.4.4.4.2)
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30))));
      Add_Group (Group (90, 300));
      Add_Group (Group (20, 600));
      Run_To (35_000);
      Check (JRU_Seen (5) = 1 and then JRU_Id (5) = Id (90)
             and then JRU_Seen (4) = 0
             and then Pos.LRBG.Id.NID_BG = 10,
             "unexpected: rejected without reaction (3.16.2.4.3)");
      Run_To (65_000);
      Check (Pos.LRBG.Id.NID_BG = 20, "unexpected: the expected one next");

      --  unlinked groups are taken into account, not LRBG (3.4.4.4.2.2)
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30))));
      Add_Group (Group (80, 300));
      Track (2).Linked := False;
      Run_To (35_000);
      Check (Pos.LRBG.Id.NID_BG = 10 and then Pos.Unlinked_ORBG (1).Valid
             and then Pos.Unlinked_ORBG (1).Id.NID_BG = 80
             and then Pos.SOLR.Id.NID_BG = 10 and then JRU_Seen (5) = 0,
             "unlinked: an ORBG, neither LRBG nor SOLR");

      --  passed in the unexpected direction (3.4.4.4.7)
      Start_Track;
      Add_Group (With_Links (Group (10, 100), Link_To ((500, 400),
                                                       (20, 30), 5, 2)));
      Add_Group (Group (20, 600));
      Track (2).Reversed := True;
      Track (2).At_Cm := 60_300;
      Run_To (65_000);
      Check (JRU_Seen (4) = 1 and then JRU_Last (4, 2) = 0
             and then JRU_Last (4, 3) = Pos.Cause_Wrong_Direction
             and then Pos.LRBG.Id.NID_BG = 10,
             "wrong direction: rejected, trip requested");
      Check_Golden ("position_linking_errors");
   end Scenario_Linking_Errors;

   --  Single balise groups: orientation from linking (3.4.2.3.2.2), the
   --  report based on two groups (3.4.2.3.3.1 to .4), the assignment by
   --  the RBC (3.4.2.3.3.6, .8); duplicated balises (3.4.2.2.1.1,
   --  3.4.2.4.1)
   procedure Scenario_Single_Balise is
      P  : R1.Packet_T;
      OK : Boolean;
   begin
      Start_Track;
      Add_Group (With_Links (Group (10, 100),
                             Link_To ((1 => 200), (1 => 15))));
      Add_Group (Group (15, 300, 1));
      Add_Group (Group (30, 500, 1));
      --  a single group behind 30, not read on the way there
      Add_Group (Group (20, 520, 1));
      Track (4).Skip := 1;
      Run_To (35_000);
      Check (Pos.LRBG.Id.NID_BG = 15
             and then Pos.LRBG.Orientation = EVC_Distances.Plus
             and then Pos.Report_Kind = Pos.Report_P0,
             "single: co-ordinate system from the linking (3.4.2.3.2.2)");
      Run_To (55_000);
      Check (Pos.LRBG.Id.NID_BG = 30
             and then Pos.LRBG.Orientation = EVC_Distances.Unknown
             and then Pos.Previous_LRBG.Id.NID_BG = 15
             and then Pos.Report_Kind = Pos.Report_P1,
             "single: no co-ordinate system, report on two groups");
      P := Pos.Position_Report_2 (M_SB, L1);
      Check (P.NID_BG = 30 and then P.NID_BG_PRVLRBG = 15
             and then P.Q_DIRLRBG = 1 and then P.Q_DLRBG = 1
             and then P.Q_DIRTRAIN = 1 and then P.D_LRBG = 530,
             "single: directions against prev -> LRBG (3.4.2.3.3.2)");
      Check (Round_Trip (P), "single: packet 1 round trip");
      Pos.Assign_Coordinate_System ((123, 30), False, OK);
      Check (OK and then Pos.LRBG.Orientation = EVC_Distances.Minus
             and then Pos.Report_Kind = Pos.Report_P0
             and then Pos.Position_Report (M_SB, L1).Q_DIRLRBG = 0,
             "single: the RBC assigns reverse (3.4.2.3.3.6)");

      --  back over 20 only: passed against the direction 30 was passed
      --  in, the previous LRBG is unknown (3.4.2.3.3.4)
      Track (4).Skip := 0;
      Run_To (51_000);
      Check (Pos.LRBG.Id.NID_BG = 20 and then not Pos.Previous_LRBG.Valid,
             "single: passed the other way, previous LRBG unknown");
      P := Pos.Position_Report_2 (M_SB, L1);
      Check (P.NID_BG_PRVLRBG = 16383 and then P.Q_DIRLRBG = 2
             and then P.Q_DLRBG = 2 and then P.Q_DIRTRAIN = 2,
             "single: directions unknown (3.4.2.3.3.3)");
      --  back over 30: now after 20, another previous LRBG
      Run_To (45_000);
      Check (Pos.LRBG.Id.NID_BG = 30
             and then Pos.Previous_LRBG.Id.NID_BG = 20,
             "single: 30 again, after 20");
      Pos.Assign_Coordinate_System ((123, 30), True, OK);
      Check (not OK, "single: reported with different previous LRBGs, "
             & "assignment refused (3.4.2.3.3.7, 3.4.2.3.3.8)");

      --  duplicated balises, balise 1 not read: balise 2 is the location
      --  reference, the group has no orientation of its own
      Start_Track;
      Add_Group (Group (40, 100));
      Track (1).Dup_1_2 := True;
      Track (1).Skip := 1;
      Run_To (11_000);
      Check (Pos.Passage_Open, "duplicate: waits for the other balise");
      Run_To (30_000);
      Check (Pos.LRBG.Id.NID_BG = 40 and then Pos.LRBG.X = 10_300
             and then Pos.LRBG.Orientation = EVC_Distances.Unknown,
             "duplicate: balise 2 is the location reference (3.4.2.2.1.1),"
             & " a single balise group (3.4.2.4.1)");
      Check_Golden ("position_single_balise");
   end Scenario_Single_Balise;

   --  3.6.6: the geographical position from packet 79
   procedure Scenario_Geo is
      G : T79.Packet_T;
   begin
      Start_Track;
      G.Q_DIR := 1;
      G.Q_SCALE := 1;
      G.NID_BG := 10;
      G.D_POSOFF := 50;
      G.Q_MPOSITION := 1;
      G.M_POSITION := 42_000;
      G.N_ITER := 1;
      G.Q_NEWCOUNTRY_List (1).NID_BG := 11;
      G.Q_NEWCOUNTRY_List (1).D_POSOFF := 0;
      G.Q_NEWCOUNTRY_List (1).Q_MPOSITION := 0;
      G.Q_NEWCOUNTRY_List (1).M_POSITION := 50_000;
      Add_Group (Group (10, 100));
      Track (1).Has_Geo := True;
      Track (1).Geo := G;
      Add_Group (Group (11, 300));
      Run_To (14_000);
      Check (not Pos.Geo_Known and then Geo_Count = 0,
             "geo: not before the offset (3.6.6.4.2)");
      Run_To (15_000);
      Check (Pos.Geo_Known and then Pos.Geo_Metres = 42_003,
             "geo: 42 003 m at the reference + 3 m, got"
             & Natural'Image (Pos.Geo_Metres));
      Run_To (20_000);
      Check (Pos.Geo_Metres = 42_053 and then Geo_Seen = 42_053,
             "geo: 42 053 m, on the DMI (MSG_STATUS)");
      Run_To (40_000);
      Check (Pos.Geo_Metres = 50_000 - 103,
             "geo: the second reference, counting down, got"
             & Natural'Image (Pos.Geo_Metres));
      Pos.Delete_Geo;
      Geo_Count := 0;
      Stand;
      Check (Geo_Count = 1 and then Geo_Seen = 16#FFFF_FFFF#,
             "geo: once unknown when it stops");
      Stand;
      Check (Geo_Count = 1, "geo: then nothing");
      Check_Golden ("position_geo");
   end Scenario_Geo;

   --  3.6.8, A.3.1: odometer accuracy impaired, safety threshold
   procedure Scenario_Odometer_Accuracy is
      Impaired_At : Integer_64 := 0;
      Nominal_At  : Integer_64 := 0;
   begin
      Start_Track;
      Bound_Per_Mille := 60;
      while Impaired_At = 0 and then Train_Cm < 600_000 loop
         Step (1_000);
         if Odo.Impaired then
            Impaired_At := Train_Cm;
         end if;
      end loop;
      Check (Impaired_At = 420_000,
             "odometer: 6 % impaired after 4200 m (250 m), got"
             & Integer_64'Image (Impaired_At));
      Check (JRU_Seen (7) = 1 and then JRU_Last (7, 2) = 1
             and then not Odo.Safety_Exceeded,
             "odometer: JRU impaired");
      Run_To (500_000);
      Bound_Per_Mille := 10;
      while Nominal_At = 0 and then Train_Cm < 2_000_000 loop
         Step (1_000);
         if not Odo.Impaired then
            Nominal_At := Train_Cm;
         end if;
      end loop;
      --  the window falls below 255 m after 10 intervals, then 5000 m
      Check (Nominal_At = 1_090_000,
             "odometer: nominal again after 5000 m below the accuracy "
             & "(3.6.8.6), got" & Integer_64'Image (Nominal_At));
      Check (JRU_Seen (7) = 2 and then JRU_Last (7, 2) = 0,
             "odometer: JRU nominal");

      Start_Track;
      Bound_Per_Mille := 350;
      Run_To (430_000);
      Check (Odo.Safety_Exceeded and then Odo.Impaired
             and then JRU_Last (7, 2) = 2,
             "odometer: 35 % exceeds the safety threshold at 4300 m");
      Run_To (429_000);
      Check (Odo.Safety_Exceeded, "odometer: safety threshold latched");
   end Scenario_Odometer_Accuracy;

   --  3.15.8: cold movement at power-up
   procedure Scenario_Cold_Movement is
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      Forget;
      Check (Odo.Cold = Odo.Cold_Unknown, "cold: unknown before a sample");
      Input (Odometer, Odometer_Payload (0, 0, 0, 0, 0, 0, 0, 1, 250));
      Cycle;
      Check (Odo.Cold = Odo.Cold_Movement and then JRU_Seen (9) = 1,
             "cold: 2.5 m moved in No Power is a cold movement");
      Input (Odometer, Odometer_Payload (0, 0, 0, 0, 0, 0, 0, 1, 0));
      Cycle;
      Check (Odo.Cold = Odo.Cold_Movement and then JRU_Seen (9) = 1,
             "cold: read once, at power-up");

      EVC_Core.Initialise;
      Forget;
      Input (Odometer, Odometer_Payload (0, 0, 0, 0, 0, 0, 0, 1, 200));
      Cycle;
      Check (Odo.Cold = Odo.No_Cold_Movement and then JRU_Seen (9) = 0,
             "cold: 2 m allowed (3.15.8.1.1)");

      EVC_Core.Initialise;
      Forget;
      Input (Odometer, Odometer_Payload (0, 0, 0, 0, 0, 0, 0, 0, 0));
      Cycle;
      Check (Odo.Cold = Odo.Cold_Not_Available and then JRU_Seen (9) = 0,
             "cold: information not available (3.15.8.3)");
   end Scenario_Cold_Movement;

   --  3.6.1.5, 5.12.2.5: the active cab defines the orientation; the
   --  front end and the report follow from the previous data
   procedure Scenario_Orientation is
      P : R0.Packet_T;
   begin
      Start_Track;
      Add_Group (Group (10, 100));
      Run_To (15_000);
      Stand;
      Check (Pos.Orientation = EVC_Distances.Plus
             and then Pos.Orientation_Known
             and then Pos.Active_Cab = Pos.Cab_A
             and then Pos.Estimated_Front = 5_300,
             "orientation: cab A, front 53 m ahead of the LRBG");
      Input (TIU, (1, 0));
      Stand;
      Check (Pos.Orientation = EVC_Distances.Plus
             and then Pos.Active_Cab = Pos.No_Cab,
             "orientation: no cab active, the last active one stays");
      Input (TIU, (2, 1));
      Stand;
      Check (Pos.Orientation = EVC_Distances.Minus
             and then Pos.Active_Cab = Pos.Cab_B
             and then Pos.Estimated_Front = -3_300,
             "orientation: cab B, its end 33 m in rear of the LRBG, got"
             & EVC_Distances.Cm_T'Image (Pos.Estimated_Front));
      P := Pos.Position_Report (M_SB, L1);
      Check (P.Q_DIRLRBG = 0 and then P.Q_DLRBG = 1 and then P.D_LRBG = 330,
             "orientation: reverse against the LRBG, front on its "
             & "nominal side");
      Input (TIU, (1, 1));
      Stand;
      Check (Pos.Orientation = EVC_Distances.Minus
             and then Pos.Active_Cab = Pos.No_Cab,
             "orientation: both cabs active, nothing changes");
      Input (TIU, (1, 0));
      Step (-2_000);
      Check (Pos.Estimated_Front = -1_300
             and then Pos.Position_Report (M_SB, L1).Q_DIRTRAIN = 0,
             "orientation: moving towards cab B, reverse against the LRBG");
      Check_Golden ("position_orientation");
   end Scenario_Orientation;

   --  3.6.7: distances not referred to balise groups
   procedure Scenario_Virtual is
      V : Odo.Virtual_T;
   begin
      Start_Track;
      Run_To (10_000);
      V := Odo.Start_Virtual (5_000, EVC_Distances.Plus);
      Run_To (12_000);
      Check (Odo.Remaining_Estimated (V) = 3_000
             and then Odo.Remaining_Max_Safe (V) = 3_000 - 40
             and then Odo.Remaining_Min_Safe (V) = 3_000 + 40,
             "virtual: remaining distances (3.6.7.3)");
      Check (Odo.Away (V, EVC_Distances.Plus) = 2_000
             and then Odo.Away (V, EVC_Distances.Minus) = 0
             and then Odo.Away (V, EVC_Distances.Unknown) = 2_000,
             "virtual: travelled away (3.6.7.2)");
      Odo.Set_Distance (V, 8_000);
      Check (Odo.Remaining_Estimated (V) = 6_000,
             "virtual: new national value, same start (3.6.7.5)");
      Run_To (11_000);
      Check (Odo.Away (V, EVC_Distances.Unknown) = 1_000
             and then Odo.Remaining_Estimated (V) = 7_000,
             "virtual: back");
   end Scenario_Virtual;

   --  3.6.5.1.4, 3.6.5.1.5: report triggers
   procedure Scenario_Report_Triggers is
      P58   : T58.Packet_T;
      OK    : Boolean;
      Times : Natural := 0;
      Dists : Natural := 0;
   begin
      Start_Track;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 500));
      Run_To (15_000);
      P58.Q_SCALE := 1;
      P58.T_CYCLOC := 2;
      P58.D_CYCLOC := 50;
      P58.M_LOC := 0;
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Stand;
      Check (OK and then Pos.Report_Triggers.Immediate,
             "triggers: M_LOC 0, immediately (3.6.5.1.5 e)");
      Forget;
      for I in 1 .. 40 loop
         Step (500);
         Times := Times + (if Pos.Report_Triggers.Periodic_Time then 1
                           else 0);
         Dists := Dists + (if Pos.Report_Triggers.Periodic_Distance then 1
                           else 0);
      end loop;
      Check (Times = 2 and then Dists = 4,
             "triggers: every 2 s and every 50 m in 4 s and 200 m, got"
             & Img (Times) & Img (Dists));
      Check (not Seen.LRBG_Passed,
             "triggers: M_LOC 0 is not every LRBG");
      P58.M_LOC := 1;
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Forget;
      Run_To (52_000);
      Check (Seen.LRBG_Passed, "triggers: M_LOC 1, the LRBG (3.6.5.1.5 d)");
      Input (DMI, Isolate);
      Stand;
      Stand;
      Check (Pos.Report_Triggers.Mode_Changed,
             "triggers: the mode changed (3.6.5.1.4 b)");
   end Scenario_Report_Triggers;

   --  3.6.1.7: the min safe rear end with the train length
   --  3.6.4.2.5 c) then b): a "max" location item of packet 58 referred
   --  to a group, relocated without linking to the next SOLR by the
   --  travelled distance, then with linking widened by twice the
   --  accuracy of its former reference
   procedure Scenario_Relocation is
      P58      : T58.Packet_T;
      OK       : Boolean;
      Fired_At : Integer_64 := 0;

      procedure Until_Passed (Limit : Integer_64) is
      begin
         Fired_At := 0;
         while Train_Cm < Limit and then Fired_At = 0 loop
            Step (1_000);
            if Pos.Report_Triggers.Location_Passed then
               Fired_At := Train_Cm;
            end if;
         end loop;
      end Until_Passed;
   begin
      P58.Q_SCALE := 1;
      P58.T_CYCLOC := 255;
      P58.D_CYCLOC := 32_767;
      P58.M_LOC := 2;
      P58.N_ITER := 1;

      --  c): at 500 m, 400 m from the first group; the max safe front
      --  end against the second group reaches it where it would against
      --  the first (3.6.4.2.5.4)
      Start_Track;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 300));
      Run_To (15_000);
      P58.D_LOC_List (1) := (D_LOC => 400, Q_LGTLOC => 1);
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Until_Passed (60_000);
      Check (OK and then Pos.SOLR.Id.NID_BG = 20 and then Fired_At = 48_000,
             "relocation c): the location passed at 480 m, got"
             & Integer_64'Image (Fired_At));

      --  then b): at 900 m; the second group links the third
      Start_Track;
      Add_Group (Group (10, 100));
      Add_Group (With_Links (Group (20, 300), Link_To ((1 => 300),
                                                        (1 => 30))));
      Add_Group (Group (30, 600));
      Run_To (15_000);
      P58.D_LOC_List (1) := (D_LOC => 800, Q_LGTLOC => 1);
      Pos.Set_Report_Parameters (P58, (123, 10), OK);
      Until_Passed (100_000);
      Check (OK and then Pos.SOLR.Id.NID_BG = 30
             and then Pos.LRBG.Locacc = 500
             and then Fired_At = 86_000,
             "relocation b): the linking distance plus twice 12 m, passed "
             & "at 860 m, got" & Integer_64'Image (Fired_At));
   end Scenario_Relocation;

   --  3.4.4.4.2.1, 3.4.4.4.4: a group announced with an unknown identity
   --  and repositioning information
   procedure Scenario_Repositioning is
      L : T5.Packet_T := Link_To ((1 => 500), (1 => 16383));
   begin
      L.D_LINK := 500;
      Start_Track;
      Add_Group (With_Links (Group (10, 100), L));
      Add_Group (Group (55, 400));
      Track (2).Reposition := True;
      Run_To (45_000);
      Check (Pos.LRBG.Id.NID_BG = 55 and then Pos.LRBG.Locacc = 500
             and then JRU_Seen (5) = 0 and then JRU_Seen (4) = 0,
             "repositioning: the group with packet 16 accepted in the "
             & "window from the previous group on");

      Start_Track;
      Add_Group (With_Links (Group (10, 100), L));
      Add_Group (Group (56, 400));
      Run_To (45_000);
      Check (Pos.LRBG.Id.NID_BG = 10 and then JRU_Seen (5) = 1
             and then JRU_Id (5) = Id (56),
             "repositioning: without packet 16 the group is rejected");

      Start_Track;
      Add_Group (With_Links (Group (10, 100), L));
      Add_Group (Group (57, 400, 1));
      Track (2).Reposition := True;
      Run_To (45_000);
      Check (Pos.LRBG.Id.NID_BG = 10 and then JRU_Seen (5) = 1,
             "repositioning: a single balise group is rejected (a)");
   end Scenario_Repositioning;

   --  3.6.6.4.3: announced references deleted on a change of orientation
   procedure Scenario_Geo_Orientation is
      G : T79.Packet_T;
   begin
      Start_Track;
      G.Q_DIR := 1;
      G.Q_SCALE := 1;
      G.Q_NEWCOUNTRY := 0;
      G.NID_BG := 11;
      G.M_POSITION := 50_000;
      Add_Group (Group (10, 100));
      Track (1).Has_Geo := True;
      Track (1).Geo := G;
      Add_Group (Group (11, 300));
      Run_To (15_000);
      Input (TIU, (1, 0));
      Input (TIU, (2, 1));
      Stand;
      Input (TIU, (2, 0));
      Input (TIU, (1, 1));
      Run_To (35_000);
      Check (not Pos.Geo_Known and then Geo_Count = 0,
             "geo: the announced reference deleted with the orientation");
   end Scenario_Geo_Orientation;

   procedure Scenario_Rear_End is
   begin
      Start_Track;
      Add_Group (Group (10, 100));
      Run_To (50_000);
      Check (not Pos.Train_Length_Known
             and then Pos.Min_Safe_Rear = Pos.Min_Safe_Front,
             "rear end: no train length");
      Pos.Set_Train_Length (20_000);
      Check (Pos.Min_Safe_Rear = Pos.Min_Safe_Front - 20_000,
             "rear end: the min safe front end minus 200 m");
   end Scenario_Rear_End;

   ---------------------------------------------------------------------
   --  E3 (profiles): the stored information
   ---------------------------------------------------------------------

   --  The track of E2 carries more packets: the bits of Extras (G, K)
   --  go into the telegram of balise K of group G, after what
   --  Telegram_Of writes; Country (G) is the NID_C of its telegrams

   package SI   renames EVC_Stored_Information;
   package TD   renames EVC_Track_Description;
   package MAu  renames EVC_Movement_Authority;
   package TCo  renames EVC_Track_Conditions;
   package NVa  renames EVC_National_Values;
   package Prof renames EVC_Profiles;
   package Loc  renames EVC_Location;
   package SIn  renames EVC_Supervision_Input;
   package T3   renames ETCS_Track_Packets.P3;
   package T12  renames ETCS_Track_Packets.P12;
   package T27  renames ETCS_Track_Packets.P27;
   package T39  renames ETCS_Track_Packets.P39;
   package T51  renames ETCS_Track_Packets.P51;
   package T66  renames ETCS_Track_Packets.P66;
   package T67  renames ETCS_Track_Packets.P67;
   package T68  renames ETCS_Track_Packets.P68;
   package T70  renames ETCS_Track_Packets.P70;
   package T71  renames ETCS_Track_Packets.P71;
   package T80  renames ETCS_Track_Packets.P80;
   package T88  renames ETCS_Track_Packets.P88;
   package T141 renames ETCS_Track_Packets.P141;

   use type SIn.Release_Speed_Kind_T;
   use type SIn.National_Values_T;
   use type SIn.Kv_Step_T;
   use type SIn.Kr_Step_T;
   use type SIn.Brake_Inhibition_T;
   use type ETCS_Variables.M_MAMODE_T;

   type Extra_T is record
      Bits : Natural := 0;
      Data : Byte_Array (1 .. 128) := (others => 0);
   end record;
   Extras  : array (1 .. Max_Groups, 0 .. 1) of Extra_T;
   Country : array (1 .. Max_Groups) of ETCS_Variables.NID_C_T :=
     (others => 123);

   --  The bits of W appended to Extras (G, K); a telegram holds 772 bits
   --  of packets (830 less the header and packet 255)
   procedure Carry_Writer (G : Positive; K : Natural; W : Writer_T) is
      Acc : Writer_T;
   begin
      if Extras (G, K).Bits > 0 then
         ETCS_Bits.Write_Bytes (Acc, Extras (G, K).Bits, Extras (G, K).Data);
      end if;
      ETCS_Bits.Write_Bytes (Acc, ETCS_Bits.Position (W), ETCS_Bits.Data (W));
      Encodes_OK := Encodes_OK and then not ETCS_Bits.Failed (Acc)
                    and then ETCS_Bits.Position (Acc) <= 772;
      declare
         D : constant Byte_Array := ETCS_Bits.Data (Acc);
      begin
         Extras (G, K).Bits := ETCS_Bits.Position (Acc);
         Extras (G, K).Data := (others => 0);
         Extras (G, K).Data (1 .. D'Length) := D;
      end;
   end Carry_Writer;

   procedure Finish_Carry (G : Positive; K : Natural; W : Writer_T;
                           OK : Boolean) is
   begin
      Encodes_OK := Encodes_OK and then OK;
      Carry_Writer (G, K, W);
   end Finish_Carry;

   procedure Carry (G : Positive; K : Natural; P : T3.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T3.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T12.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T12.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T21.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T21.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T27.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T27.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T39.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T39.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T51.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T51.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T65.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T65.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T66.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T66.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T67.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T67.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T68.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T68.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T70.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T70.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T71.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T71.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T80.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T80.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T88.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T88.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T141.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T141.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;

   --  Telegram_Of with the extras of the group
   function Telegram_X (G : Positive; K : Natural; Stamp : Integer_64)
     return Byte_Array
   is
      D  : constant Group_Def := Track (G);
      W  : Writer_T;
      OK : Boolean;
      H  : constant Tel.Header_T :=
        (Q_UPDOWN  => 1,
         M_VERSION => 48,
         Q_MEDIA   => 0,
         N_PIG     => ETCS_Variables.N_PIG_T (K),
         N_TOTAL   => ETCS_Variables.N_TOTAL_T (D.Balises - 1),
         M_DUP     => 0,
         M_MCOUNT  => 7,
         NID_C     => Country (G),
         NID_BG    => D.NID_BG,
         Q_LINK    => (if D.Linked then 1 else 0));
   begin
      Tel.Write_Header (W, H);
      if D.Has_Linking then
         Put (W, D.Linking);
      end if;
      if K <= 1 and then Extras (G, K).Bits > 0 then
         ETCS_Bits.Write_Bytes (W, Extras (G, K).Bits, Extras (G, K).Data);
      end if;
      Tel.Finish (W, Tel.Long_Bits, OK);
      Encodes_OK := Encodes_OK and then OK;
      return BTM_Of (ETCS_Bits.Data (W), ETCS_Bits.Position (W), Stamp);
   end Telegram_X;

   --  What the E3 runs saw: the last MSG_TRACK_COND and MSG_PLANNING, the
   --  JRU records of the stored information by information and change
   TC_Payload   : Byte_Array (1 .. 64) := (others => 0);
   TC_Length    : Natural := 0;
   TC_Frames    : Natural := 0;
   Plan_Payload : Byte_Array (1 .. 512) := (others => 0);
   Plan_Length  : Natural := 0;
   Plan_Frames  : Natural := 0;
   type SI_Seen_T is array (0 .. 16, 0 .. 13) of Natural;
   SI_Seen      : SI_Seen_T := (others => (others => 0));
   SI_Detail    : SI_Seen_T := (others => (others => 0));

   procedure Collect_E3 is
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = DMI and then Rec_Length (I) > 5
           and then Byte_At (I, 1) = Natural (EVC_DMI_Port.MSG_TRACK_COND)
         then
            TC_Length := Rec_Length (I) - 5;
            for N in 1 .. Natural'Min (TC_Length, TC_Payload'Length) loop
               TC_Payload (N) := Byte (Byte_At (I, 5 + N));
            end loop;
            TC_Frames := TC_Frames + 1;
         elsif Recs (I).Port = DMI and then Rec_Length (I) > 5
           and then Byte_At (I, 1) = Natural (EVC_DMI_Port.MSG_PLANNING)
         then
            Plan_Length := Rec_Length (I) - 5;
            for N in 1 .. Natural'Min (Plan_Length, Plan_Payload'Length) loop
               Plan_Payload (N) := Byte (Byte_At (I, 5 + N));
            end loop;
            Plan_Frames := Plan_Frames + 1;
         elsif Recs (I).Port = JRU
           and then Byte_At (I, 1) = SI.JRU_Event
           and then Byte_At (I, 2) <= 16 and then Byte_At (I, 3) <= 13
         then
            SI_Seen (Byte_At (I, 2), Byte_At (I, 3)) :=
              SI_Seen (Byte_At (I, 2), Byte_At (I, 3)) + 1;
            SI_Detail (Byte_At (I, 2), Byte_At (I, 3)) := Byte_At (I, 4);
         end if;
      end loop;
   end Collect_E3;

   procedure Cycle_X is
   begin
      Cycle;
      Collect_E3;
   end Cycle_X;

   --  Step of E2 with the telegrams of Telegram_X
   procedure Step_X (Step_Cm : Integer_64) is
      Old_Train : constant Integer_64 := Train_Cm;
      Old_D     : constant Integer_64 := Odo_D;
      New_Train : constant Integer_64 := Train_Cm + Step_Cm;
      Measured  : constant Integer_64 :=
        Step_Cm * (1000 + Error_Per_Mille) / 1000;
      type Crossing is record
         At_Cm : Integer_64;
         G, K  : Natural;
      end record;
      List : array (1 .. 64) of Crossing;
      N    : Natural := 0;

      function Crossed (P : Integer_64) return Boolean is
        (if Step_Cm > 0 then P > Old_Train and then P <= New_Train
         else P < Old_Train and then P >= New_Train);
   begin
      for G in 1 .. Track_N loop
         for K in 0 .. Track (G).Balises - 1 loop
            if Crossed (Balise_At (Track (G), K)) then
               N := N + 1;
               List (N) := (Balise_At (Track (G), K), G, K);
            end if;
         end loop;
      end loop;
      for I in 2 .. N loop
         for J in reverse 2 .. I loop
            if (Step_Cm > 0 and then List (J).At_Cm < List (J - 1).At_Cm)
              or else (Step_Cm < 0
                       and then List (J).At_Cm > List (J - 1).At_Cm)
            then
               declare
                  Swap : constant Crossing := List (J);
               begin
                  List (J) := List (J - 1);
                  List (J - 1) := Swap;
               end;
            end if;
         end loop;
      end loop;
      for I in 1 .. N loop
         Input (BTM, Telegram_X
                       (List (I).G, List (I).K,
                        Old_D + (List (I).At_Cm - Old_Train) * Measured
                                / Step_Cm));
      end loop;
      Train_Cm := New_Train;
      Odo_D := Odo_D + Measured;
      Odo_Over := Odo_Over + abs Measured * Bound_Per_Mille / 1000;
      Odo_Under := Odo_Under + abs Measured * Bound_Per_Mille / 1000;
      Sample ((if Step_Cm > 0 then 1 elsif Step_Cm < 0 then -1 else 0));
      Cycle_X;
   end Step_X;

   procedure Run_X (To_Cm : Integer_64; Step_Cm : Integer_64 := 1000) is
   begin
      while Train_Cm /= To_Cm loop
         Step_X (if To_Cm > Train_Cm
                 then Integer_64'Min (Step_Cm, To_Cm - Train_Cm)
                 else -Integer_64'Min (Step_Cm, Train_Cm - To_Cm));
      end loop;
   end Run_X;

   --  Standing for Ms
   procedure Stand_X (Ms : Natural) is
   begin
      for I in 1 .. Ms / 100 loop
         Sample (0);
         Cycle_X;
      end loop;
   end Stand_X;

   procedure Start_X is
   begin
      Start_Track;
      Extras := (others => (others => <>));
      Country := (others => 123);
      TC_Length := 0;
      TC_Frames := 0;
      Plan_Length := 0;
      Plan_Frames := 0;
      SI_Seen := (others => (others => 0));
      SI_Detail := (others => (others => 0));
   end Start_X;

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

   function SSP (L : Profile_List) return T27.Packet_T is
      P : T27.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_STATIC := ETCS_Variables.D_STATIC_T (L (L'First).D_M);
      P.V_STATIC := V_Static (L (L'First).Value);
      P.Q_FRONT := (if L (L'First).Delay_Length then 0 else 1);
      P.N_ITER := 0;
      P.N_ITER_2 := ETCS_Variables.N_ITER_T (L'Length - 1);
      for I in 1 .. L'Length - 1 loop
         P.D_STATIC_List (I).D_STATIC :=
           ETCS_Variables.D_STATIC_T (L (L'First + I).D_M);
         P.D_STATIC_List (I).V_STATIC := V_Static (L (L'First + I).Value);
         P.D_STATIC_List (I).Q_FRONT :=
           (if L (L'First + I).Delay_Length then 0 else 1);
      end loop;
      return P;
   end SSP;

   type Grad_Item is record
      D_M   : Natural;
      Value : Integer;
   end record;
   type Grad_List is array (Positive range <>) of Grad_Item;

   function Grad (L : Grad_List) return T21.Packet_T is
      P : T21.Packet_T;

      procedure Set (V : Integer; Q : out ETCS_Variables.Q_GDIR_T;
                     G : out ETCS_Variables.G_A_T) is
      begin
         if V = End_Mark then
            Q := 1;
            G := 255;
         else
            Q := (if V >= 0 then 1 else 0);
            G := ETCS_Variables.G_A_T (abs V);
         end if;
      end Set;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_GRADIENT := ETCS_Variables.D_GRADIENT_T (L (L'First).D_M);
      Set (L (L'First).Value, P.Q_GDIR, P.G_A);
      P.N_ITER := ETCS_Variables.N_ITER_T (L'Length - 1);
      for I in 1 .. L'Length - 1 loop
         P.D_GRADIENT_List (I).D_GRADIENT :=
           ETCS_Variables.D_GRADIENT_T (L (L'First + I).D_M);
         Set (L (L'First + I).Value, P.D_GRADIENT_List (I).Q_GDIR,
              P.D_GRADIENT_List (I).G_A);
      end loop;
      return P;
   end Grad;

   --  An MA of sections of these lengths (m), the last the End Section;
   --  no timer, no danger point, no overlap
   function MA_Of (Lengths : Nat_List; V_Main_Kmh : Natural := 120)
     return T12.Packet_T
   is
      P : T12.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.V_MAIN := ETCS_Variables.V_MAIN_T (V_Main_Kmh / 5);
      P.V_EMA := 0;
      P.T_EMA := 1023;
      P.N_ITER := ETCS_Variables.N_ITER_T (Lengths'Length - 1);
      for I in 1 .. Lengths'Length - 1 loop
         P.L_SECTION_List (I).L_SECTION :=
           ETCS_Variables.L_SECTION_T (Lengths (Lengths'First + I - 1));
      end loop;
      P.L_ENDSECTION :=
        ETCS_Variables.L_ENDSECTION_T (Lengths (Lengths'Last));
      return P;
   end MA_Of;

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

   function MRSP_Is (Starts : I64_List; Speeds : Nat_List) return Boolean
   is
      M : constant SIn.Speed_Profile_T := SI.Current.MRSP;
   begin
      if M.Count /= Starts'Length then
         return False;
      end if;
      for K in 1 .. M.Count loop
         if (K > 1 and then Integer_64 (M.Segments (K).Start)
                              /= Starts (Starts'First + K - 1))
           or else M.Segments (K).Speed /= Speeds (Speeds'First + K - 1)
         then
            return False;
         end if;
      end loop;
      return True;
   end MRSP_Is;

   --  3.13.7: no step of the MRSP above a source it overlaps, checked on
   --  the steps and the sources the stored information exposes
   function MRSP_Below_Sources return Boolean is
      P : constant Prof.Steps_T := SI.MRSP_Steps;
      E : constant Prof.Elements_T := SI.MRSP_Sources;
   begin
      return Prof.Sorted (P)
        and then Prof.Below (P, E, 0, SI.MRSP_Ceiling)
        and then SI.Envelope_Failures = 0;
   end MRSP_Below_Sources;

   --  Field access of the last MSG_PLANNING payload
   function Plan_U16 (Offset : Natural) return Natural is
     (Natural (Plan_Payload (Offset + 1))
      + 256 * Natural (Plan_Payload (Offset + 2)));

   --  The last MSG_TRACK_COND shows this symbol
   function TC_Shows (Kind : Natural) return Boolean is
   begin
      if TC_Length = 0 then
         return False;
      end if;
      for I in 1 .. Natural (TC_Payload (1)) loop
         if 1 + 2 * I <= TC_Length
           and then Natural (TC_Payload (1 + 2 * I)) = Kind
         then
            return True;
         end if;
      end loop;
      return False;
   end TC_Shows;

   ---------------------------------------------------------------------
   --  Scenarios
   ---------------------------------------------------------------------

   --  The frames the on-board adds for E3 repeat DMI_Protocol
   pragma Warnings (Off, "condition is always*");
   procedure Scenario_E3_Protocol is
      use DMI_Protocol;
      P : EVC_DMI_Port.Planning_T;
      F : EVC_DMI_Port.Frame_Buffer_T;
      L : Natural;
      C : EVC_DMI_Port.Track_Cond_List_T := (others => (0, 0));
   begin
      Check (Unsigned_8 (MSG_TRACK_COND) = EVC_DMI_Port.MSG_TRACK_COND
             and then Unsigned_8 (MSG_PLANNING) = EVC_DMI_Port.MSG_PLANNING
             and then Track_Cond_Entry_Length = 2
             and then Planning_Gradient_Entry_Length = 3
             and then Planning_Speed_Entry_Length = 4
             and then Planning_Order_Entry_Length = 3,
             "E3: MSG_TRACK_COND and MSG_PLANNING equal DMI_Protocol");
      P.MA_Dist := 1234;
      P.Ceiling := 160;
      P.Gradient_Count := 2;
      P.Gradients (1) := (0, 5);
      P.Gradients (2) := (300, -8);
      P.Speed_Count := 1;
      P.Speeds (1) := (1234, 0);
      P.Order_Count := 1;
      P.Orders (1) := (2, 700);
      EVC_DMI_Port.Planning_Frame (P, F, L);
      Check (L = 5 + 8 + 1 + 6 + 1 + 4 + 1 + 3
             and then F (1) = EVC_DMI_Port.MSG_PLANNING
             and then Natural (F (2)) = L - 5
             and then F (6) = 16#D2# and then F (7) = 16#04#     -- 1234
             and then F (8) = 16#FF# and then F (9) = 16#FF#     -- none
             and then F (12) = 160
             and then F (14) = 2
             and then F (15) = 0 and then F (17) = 5
             and then F (18) = 16#2C# and then F (19) = 1        -- 300
             and then F (20) = 248                               -- -8
             and then F (21) = 1
             and then F (26) = 1 and then F (27) = 2
             and then F (28) = 16#BC# and then F (29) = 2,       -- 700
             "E3: MSG_PLANNING laid out as DMI_Protocol says");
      C (1) := (7, 3);
      C (2) := (9, 38);
      EVC_DMI_Port.Track_Cond_Frame (2, C, F, L);
      Check (L = 10 and then F (1) = EVC_DMI_Port.MSG_TRACK_COND
             and then F (2) = 5 and then F (6) = 2
             and then F (7) = 7 and then F (8) = 3
             and then F (9) = 9 and then F (10) = 38,
             "E3: MSG_TRACK_COND laid out as DMI_Protocol says");
   end Scenario_E3_Protocol;
   pragma Warnings (On, "condition is always*");

   --  3.11.3.2.3, 3.11.3.2.6: the SSP category of the train
   procedure Scenario_SSP_Categories is
      C : constant EVC_Train_Data.Categories_T :=
        EVC_Train_Data.Default_Categories;   -- 130 mm, passenger
      D : TD.Diff_Array := (others => (others => <>));
      Basic : constant ETCS_Variables.V_STATIC_T := 28;   -- 140 km/h
   begin
      Check (TD.Train_Speed (Basic, 0, D, C) = 3_888,
             "SSP category: the basic SSP without specific ones");
      D (1) := (Q_DIFF => 0, NC => 2, V_DIFF => 30);
      Check (TD.Train_Speed (Basic, 1, D, C) = 4_166,
             "SSP category: the cant deficiency of the train (a)");
      D (1) := (Q_DIFF => 0, NC => 0, V_DIFF => 24);
      D (2) := (Q_DIFF => 0, NC => 1, V_DIFF => 26);
      D (3) := (Q_DIFF => 0, NC => 5, V_DIFF => 32);
      Check (TD.Train_Speed (Basic, 3, D, C) = 3_611,
             "SSP category: the highest cant deficiency below (b)");
      D (1) := (Q_DIFF => 0, NC => 5, V_DIFF => 32);
      Check (TD.Train_Speed (Basic, 1, D, C) = 3_888,
             "SSP category: only higher ones, the basic SSP (c)");
      D (1) := (Q_DIFF => 2, NC => 2, V_DIFF => 20);
      Check (TD.Train_Speed (Basic, 1, D, C) = 2_777,
             "SSP category: an other specific category of the train that "
             & "does not replace, the lowest (3.11.3.2.6)");
      D (1) := (Q_DIFF => 1, NC => 2, V_DIFF => 32);
      Check (TD.Train_Speed (Basic, 1, D, C) = 4_444,
             "SSP category: an other specific category that replaces");
      D (1) := (Q_DIFF => 1, NC => 0, V_DIFF => 10);
      Check (TD.Train_Speed (Basic, 1, D, C) = 3_888,
             "SSP category: other categories of other trains ignored "
             & "(3.11.3.2.5)");
   end Scenario_SSP_Categories;

   --  3.11.3, 3.11.12, 3.6.4.2.3: the SSP and the gradients of a group
   --  as offsets from its location reference, in the frame; the MRSP
   --  with the train length delay (3.11.3.1.3), the gradient profile
   procedure Scenario_SSP_Gradients is
      S : Prof.Store_T := TD.SSP;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, True), 2 => (1000, 80, True),
                         3 => (500, 120, False))));
      Carry (1, 1, Grad ((1 => (0, 5), 2 => (2000, -3))));
      Run_X (15_000);
      S := TD.SSP;
      Check (SI.Messages = 1 and then S.Count = 3
             and then TD.Gradients.Count = 2,
             "SSP: three elements and two gradients stored");
      Check (Est (S.List (1).Start) = 10_000
             and then Est (S.List (2).Start) = 110_000
             and then Est (S.List (3).Start) = 160_000
             and then S.List (3).Open
             and then Min_X (S.List (2).Start) = 110_000
             and then Max_X (S.List (2).Start) = 110_000,
             "SSP: the element starts at the offsets from the location "
             & "reference in the frame (3.6.4.2.3), items equal");
      Check (MRSP_Is ((0, 10_000, 110_000, 180_000),
                      (4_444, 2_777, 2_222, 3_333)),
             "MRSP: V_MAXTRAIN, then the SSP, 80 km/h up to its end plus "
             & "the train length (3.11.3.1.3, 3.13.7)");
      Check (SI.Current.Gradients.Count = 3
             and then SI.Current.Gradients.Segments (2).Start = 10_000
             and then SI.Current.Gradients.Segments (2).Gradient = 5
             and then SI.Current.Gradients.Segments (3).Start = 210_000
             and then SI.Current.Gradients.Segments (3).Gradient = -3,
             "gradients: the profile in the frame (3.11.12)");
      Check (not SI.Current.MA.Present and then not SI.Current.Supervise
             and then Plan_Frames = 0,
             "no MA: nothing supervised, no planning");
      Check (SI_Seen (SI.Info_SSP, SI.Change_Stored) = 1
             and then SI_Seen (SI.Info_Gradients, SI.Change_Stored) = 1,
             "JRU: SSP and gradients stored");
      Check (MRSP_Below_Sources,
             "MRSP: sorted, never above a source (proved; checked)");
      Check (SI.Current.Train.Position_Valid
             and then SI.Current.Train.Ahead = EVC_Distances.Plus
             and then Integer_64 (SI.Current.Train.Est_Front) = 15_300,
             "snapshot: the train, the estimated front end in the frame");
   end Scenario_SSP_Gradients;

   --  3.7.3.1 a): a new SSP replaces the stored one from its start; the
   --  relocation by travelled distance (3.6.4.2.5 c, no linking) widens
   --  the min and max items of the older one
   procedure Scenario_SSP_Replacement is
      S : Prof.Store_T := TD.SSP;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 600));
      Carry (1, 0, SSP ((1 => (0, 100, True), 2 => (1000, 80, True),
                         3 => (500, 120, False))));
      Carry (2, 0, SSP ((1 => (200, 60, False))));
      Run_X (65_000);
      S := TD.SSP;
      Check (SI.Messages = 2 and then S.Count = 2
             and then Est (S.List (1).Finish) = 80_000
             and then not S.List (1).Open
             and then Est (S.List (2).Start) = 80_000 and then S.List (2).Open,
             "SSP replaced from the start of the new one (3.7.3.1 a)");
      Check (Max_X (S.List (1).Start) < Est (S.List (1).Start)
             and then Min_X (S.List (1).Start) > Est (S.List (1).Start)
             and then Max_X (S.List (2).Start) = Est (S.List (2).Start),
             "SSP: relocated by the travelled distance, the max and min "
             & "items of the older one apart (3.6.4.2.5 c)");
      Check (SI.Current.MRSP.Count = 3
             and then Integer_64 (SI.Current.MRSP.Segments (2).Start)
                        = Max_X (S.List (1).Start)
             and then SI.Current.MRSP.Segments (2).Speed = 2_777
             and then SI.Current.MRSP.Segments (3).Start = 80_000
             and then SI.Current.MRSP.Segments (3).Speed = 1_666,
             "MRSP: the older SSP from its max item, the new one from its "
             & "start");
      Check (MRSP_Below_Sources, "MRSP below its sources after relocation");
   end Scenario_SSP_Replacement;

   --  3.11.5: TSRs by identity, non revocable ones, revocation without
   --  train length delay, deletion with the orientation (3.11.5.10)
   procedure Scenario_TSR is
      function TSR_At (Id : Natural; D_M, L_M, Kmh : Natural;
                       Delay_L : Boolean) return T65.Packet_T
      is
         P : T65.Packet_T;
      begin
         P.Q_DIR := 1;
         P.Q_SCALE := 1;
         P.NID_TSR := ETCS_Variables.NID_TSR_T (Id);
         P.D_TSR := ETCS_Variables.D_TSR_T (D_M);
         P.L_TSR := ETCS_Variables.L_TSR_T (L_M);
         P.Q_FRONT := (if Delay_L then 0 else 1);
         P.V_TSR := ETCS_Variables.V_TSR_T (Kmh / 5);
         return P;
      end TSR_At;
      Revoke : T66.Packet_T;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 200));
      Add_Group (Group (30, 300));
      Add_Group (Group (40, 350));
      Carry (1, 0, SSP ((1 => (0, 160, False))));
      Carry (1, 0, TSR_At (5, 300, 100, 40, True));
      Carry (1, 1, TSR_At (255, 600, 50, 60, False));
      Carry (1, 1, TSR_At (255, 700, 20, 30, False));
      Run_X (15_000);
      Check (TD.TSR.Count = 3, "TSR: three stored");
      Check (SI.Current.MRSP.Segments (2).Start = 40_000
             and then SI.Current.MRSP.Segments (2).Speed = 1_111
             and then SI.Current.MRSP.Segments (3).Start = 70_000
             and then SI.Current.MRSP.Segments (3).Speed = 1_666
             and then SI.Current.MRSP.Segments (4).Start = 75_000
             and then SI.Current.MRSP.Segments (5).Start = 80_000
             and then SI.Current.MRSP.Segments (5).Speed = 833
             and then SI.Current.MRSP.Segments (6).Start = 82_000,
             "TSR: in the MRSP, the delayed one to its end plus the train "
             & "length (3.11.5.3)");
      --  the same identity again, elsewhere (3.11.5.9)
      Revoke.Q_DIR := 1;
      Revoke.NID_TSR := 5;
      Carry (2, 0, TSR_At (5, 50, 20, 70, False));
      Carry (3, 0, Revoke);
      Revoke.NID_TSR := 255;
      Carry (4, 0, Revoke);
      Run_X (25_000);
      Check (TD.TSR.Count = 3 and then Est (TD.TSR.List (3).Start) = 25_000
             and then TD.TSR.List (3).Id = 5,
             "TSR: the one of the same identity replaced (3.11.5.9)");
      Run_X (32_000);
      Check (TD.TSR.Count = 2
             and then SI_Seen (SI.Info_TSR, SI.Change_Deleted) = 1
             and then SI_Detail (SI.Info_TSR, SI.Change_Deleted) = 5,
             "TSR: revoked at once by its identity (3.11.5.5)");
      Run_X (37_000);
      Check (TD.TSR.Count = 2,
             "TSR: a non revocable one is not revoked (3.11.5.8, 7.5.1.99)");
      Check (MRSP_Below_Sources, "MRSP below its sources with TSRs");
      --  the orientation changes: every TSR goes (3.11.5.10)
      Input (TIU, (1, 0));
      Input (TIU, (2, 1));
      Stand;
      Collect_E3;
      Check (TD.TSR.Count = 0
             and then SI_Seen (SI.Info_TSR, SI.Change_Orientation) = 1,
             "TSR: deleted when the orientation changes (3.11.5.10)");
   end Scenario_TSR;

   --  3.8.3, 3.8.4.5, 3.7.2.3: an MA of level 1 accepted when the SSP
   --  and the gradients cover it, its EOA, SvL and release speed in the
   --  frame; the planning to the DMI
   procedure Scenario_MA is
      M : T12.Packet_T := MA_Of ((300, 400));
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 200));
      --  no gradient: the MA is not accepted (3.7.2.3)
      Carry (1, 0, SSP ((1 => (0, 100, True))));
      Carry (1, 1, M);
      M.Q_DANGERPOINT := 1;
      M.Has_D_DP := True;
      M.D_DP := 50;
      M.V_RELEASEDP := 8;
      M.Q_OVERLAP := 1;
      M.Has_D_STARTOL := True;
      M.D_STARTOL := 150;
      M.T_OL := 30;
      M.D_OL := 100;
      M.V_RELEASEOL := 6;
      Carry (2, 0, SSP ((1 => (0, 100, True))));
      Carry (2, 0, Grad ((1 => (0, 0))));
      Carry (2, 1, M);
      Run_X (11_000);
      Check (not SI.Current.MA.Present
             and then SI_Seen (SI.Info_MA, SI.Change_Rejected) = 1
             and then SI_Seen (SI.Info_Signalling_Speed, SI.Change_Stored)
                        = 1,
             "MA: not accepted, the gradients do not cover it (3.7.2.3); "
             & "its V_MAIN is (3.11.6.2)");
      Run_X (21_000);
      Check (SI.Current.MA.Present and then SI.Current.Supervise
             and then SI.Current.MA.EOA = 90_000
             and then SI.Current.MA.SvL = 100_000
             and then SI.Current.MA.LOA_Speed = 0
             and then SI.Current.MA.Release_Speed.Kind = SIn.Fixed
             and then SI.Current.MA.Release_Speed.Speed = 833,
             "MA: EOA at the end of the End Section, SvL the end of the "
             & "overlap with its release speed (3.8.4.5.1 a)");
      Check (MAu.MA.Count = 2 and then MAu.V_Main = 3_333,
             "MA: two sections, V_MAIN 120 km/h");
      Check (SI.Current.MRSP.Count = 2
             and then SI.Current.MRSP.Segments (1).Speed = 3_333
             and then SI.Current.MRSP.Segments (2).Speed = 2_777,
             "MRSP: the signalling related speed restriction from its "
             & "reception, under V_MAXTRAIN (3.11.6.2, 3.11.8)");
      Check (Plan_Frames > 0 and then Plan_U16 (0) = (90_000 - 21_300) / 100
             and then Plan_U16 (2) = 16#FFFF#
             and then Plan_U16 (6) = 100
             and then Natural (Plan_Payload (9)) = 1      -- gradients
             and then Plan_U16 (9) = 0
             and then Natural (Plan_Payload (12)) = 0
             and then Natural (Plan_Payload (13)) = 1     -- speeds: the EOA
             and then Plan_U16 (13) = 687
             and then Plan_U16 (15) = 0
             and then Natural (Plan_Payload (18)) = 0,    -- orders
             "planning: the EOA, the ceiling speed, the gradient, the EOA "
             & "as a zero target (DMI 8.3)");
      Check_Golden ("profiles_ma_planning");
      Check (MRSP_Below_Sources, "MRSP below its sources with an MA");
   end Scenario_MA;

   --  3.8.4.2: a section time-out withdraws the EOA to the entry of the
   --  section, the national release speed applies, the information
   --  beyond is deleted (A.3.4.1.3 [1])
   procedure Scenario_Section_Timer is
      M : T12.Packet_T := MA_Of ((300, 400));
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      M.L_ENDSECTION := 400;
      M.Q_SECTIONTIMER := 1;
      M.Has_T_SECTIONTIMER := True;
      M.T_SECTIONTIMER := 20;
      M.D_SECTIONTIMERSTOPLOC := 50;
      Carry (1, 1, M);
      Run_X (15_000);
      Check (SI.Current.MA.EOA = 80_000
             and then SI.Current.MA.Release_Speed.Kind = SIn.None,
             "section timer: the MA, no release speed at the end of the "
             & "End Section (3.13.9.4.4)");
      Stand_X (19_000);
      Check (SI.Current.MA.EOA = 80_000, "section timer: running");
      Stand_X (2_000);
      Check (SI.Current.MA.EOA = 40_000 and then SI.Current.MA.SvL = 40_000
             and then SI.Current.MA.Release_Speed.Kind = SIn.Fixed
             and then SI.Current.MA.Release_Speed.Speed = 1_111
             and then SI_Seen (SI.Info_MA, SI.Change_Section) = 1
             and then SI_Detail (SI.Info_MA, SI.Change_Section) = 2,
             "section timer over: EOA and SvL at the entry of the section, "
             & "the national release speed (3.8.4.2.2)");
      Check (TD.SSP.Count = 1 and then not TD.SSP.List (1).Open
             and then Est (TD.SSP.List (1).Finish) = 40_000,
             "section timer over: the SSP deleted beyond the new SvL "
             & "(A.3.4.1.3 [1])");
   end Scenario_Section_Timer;

   --  3.8.4.2.3: a section timer stops when the min safe front end
   --  passes its stop location
   procedure Scenario_Section_Timer_Stopped is
      M : T12.Packet_T := MA_Of ((300, 400));
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      M.L_SECTION_List (1).Q_SECTIONTIMER := 1;
      M.L_SECTION_List (1).Has_T_SECTIONTIMER := True;
      M.L_SECTION_List (1).T_SECTIONTIMER := 10;
      M.L_SECTION_List (1).D_SECTIONTIMERSTOPLOC := 100;
      Carry (1, 1, M);
      Run_X (25_000);
      Check (MAu.MA.Sections (1).Stopped,
             "section timer stopped by the min safe front end (3.8.4.2.3)");
      Stand_X (15_000);
      Check (SI.Current.MA.EOA = 80_000
             and then SI_Seen (SI.Info_MA, SI.Change_Section) = 0,
             "section timer stopped: no time-out");
      --  back in rear of the stop location, then standstill
      Run_X (17_000);
      Check (SI.Current.MA.EOA = 80_000,
             "section timer: moving back, nothing before the standstill");
      Stand;
      Collect_E3;
      Check (SI.Current.MA.EOA = 10_000
             and then SI_Seen (SI.Info_MA, SI.Change_Section) = 1
             and then SI_Detail (SI.Info_MA, SI.Change_Section) = 1,
             "section timer: back in rear of its stop location at "
             & "standstill, timed out (3.8.4.2.4)");
   end Scenario_Section_Timer_Stopped;

   --  3.8.4.4: the overlap timer starts with the max safe front end at
   --  its start location; a standstill after it (3.8.4.4.3) deletes the
   --  overlap: the SvL is the danger point with its release speed
   procedure Scenario_Overlap_Timer is
      M : T12.Packet_T := MA_Of ((700, 100));
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      M.Q_DANGERPOINT := 1;
      M.Has_D_DP := True;
      M.D_DP := 50;
      M.V_RELEASEDP := 126;
      M.Q_OVERLAP := 1;
      M.Has_D_STARTOL := True;
      M.D_STARTOL := 300;
      M.T_OL := 1023;
      M.D_OL := 100;
      M.V_RELEASEOL := 127;
      Carry (1, 1, M);
      Run_X (40_000);
      Check (SI.Current.MA.SvL = 100_000
             and then SI.Current.MA.Release_Speed.Kind = SIn.Fixed
             and then SI.Current.MA.Release_Speed.Speed = 1_111
             and then not MAu.MA.OL_Timer.Running,
             "overlap: the SvL, the national release speed (V_RELEASEOL "
             & "127), the timer not started");
      Run_X (60_000);
      Check (MAu.MA.OL_Timer.Running and then MAu.MA.Has_OL,
             "overlap timer started by the max safe front end (3.8.4.4.1)");
      Stand;
      Collect_E3;
      Check (not MAu.MA.Has_OL
             and then SI.Current.MA.SvL = 95_000
             and then SI.Current.MA.Release_Speed.Kind
                        = SIn.Calculated_On_Board
             and then SI_Seen (SI.Info_MA, SI.Change_Overlap) = 1,
             "overlap deleted at standstill even with an infinite time-out "
             & "(3.8.4.4.3): the danger point is the SvL (3.8.4.5.1 b)");
   end Scenario_Overlap_Timer;

   --  3.8.4.1: the End Section timer, and its time-out withdrawing the
   --  EOA to the train (A.3.4.1.3 [11]) with the deletion beyond the max
   --  safe front end [10]
   procedure Scenario_End_Section_Timer is
      M       : T12.Packet_T := MA_Of ((300, 400));
      Started : Unsigned_64;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 530));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      M.Q_ENDTIMER := 1;
      M.Has_T_ENDTIMER := True;
      M.T_ENDTIMER := 5;
      M.D_ENDTIMERSTARTLOC := 300;
      Carry (1, 1, M);
      --  the same MA again from a group beyond the start location
      M.N_ITER := 0;
      M.L_ENDSECTION := 270;
      Carry (2, 1, M);
      Run_X (45_000);
      Check (not MAu.MA.End_Timer.Running,
             "End Section timer: not started before its start location");
      Run_X (52_000);
      Check (MAu.MA.End_Timer.Running,
             "End Section timer started by the max safe front end "
             & "(3.8.4.1.1)");
      Started := MAu.MA.End_Timer.Started;
      Run_X (55_000);
      Check (SI_Seen (SI.Info_MA, SI.Change_Stored) = 2
             and then MAu.MA.End_Timer.Running
             and then MAu.MA.End_Timer.Started = Started
             and then MAu.MA.Msg = 2,
             "End Section timer: a new MA with its start location passed "
             & "keeps it running (3.8.4.1.4)");
      Stand_X (6_000);
      Check (MAu.MA.Withdrawn
             and then Integer_64 (SI.Current.MA.EOA) = 55_300
             and then SI.Current.MA.SvL
                        = SI.Current.Train.Max_Safe_Front
             and then SI.Current.MA.Release_Speed.Kind = SIn.None
             and then SI_Seen (SI.Info_MA, SI.Change_End) = 1,
             "End Section time-out: EOA at the estimated front end, SvL at "
             & "the max safe front end, no release speed (3.8.4.1.2, "
             & "A.3.4.1.3 [11])");
      Check (TD.SSP.Count = 1 and then not TD.SSP.List (1).Open
             and then Est (TD.SSP.List (1).Finish)
                        = Integer_64 (SI.Current.MA.SvL),
             "End Section time-out: the SSP deleted beyond the max safe "
             & "front end (A.3.4.1.3 [10])");
   end Scenario_End_Section_Timer;

   --  3.8.4.3: the LOA speed timer; 3.8.4.1.3: an End Section timer
   --  start location already passed when the MA is received
   procedure Scenario_LOA_Timer is
      M : T12.Packet_T := MA_Of ((500, 300));
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      M.V_EMA := 8;
      M.T_EMA := 5;
      Carry (1, 1, M);
      Run_X (15_000);
      Check (SI.Current.MA.LOA_Speed = 1_111
             and then SI.Current.MA.Release_Speed.Kind = SIn.None
             and then SI.Current.MA.SvL = SI.Current.MA.EOA,
             "LOA: the target speed, no SvL and no release speed "
             & "(3.8.4.5.2, 3.13.9.4.4)");
      Stand_X (6_000);
      Check (SI.Current.MA.LOA_Speed = 0
             and then SI_Seen (SI.Info_MA, SI.Change_LOA) = 1,
             "LOA speed time-out: the LOA becomes an EOA (3.8.4.3.2)");

      Start_X;
      Add_Group (Group (10, 100));
      M := MA_Of ((300, 400));
      M.Q_ENDTIMER := 1;
      M.Has_T_ENDTIMER := True;
      M.T_ENDTIMER := 60;
      M.D_ENDTIMERSTARTLOC := 700;
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 1, M);
      Run_X (15_000);
      Check (MAu.MA.Withdrawn
             and then SI_Seen (SI.Info_MA, SI.Change_End) = 1,
             "End Section timer start location passed at reception: over "
             & "at once (3.8.4.1.3)");

      Start_X;
      Add_Group (Group (10, 100));
      M := MA_Of ((300, 400));
      M.Q_OVERLAP := 1;
      M.Has_D_STARTOL := True;
      M.D_STARTOL := 750;
      M.T_OL := 60;
      M.D_OL := 100;
      M.V_RELEASEOL := 4;
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 1, M);
      Run_X (15_000);
      Check (not MAu.MA.Has_OL and then SI.Current.MA.SvL = 80_000
             and then SI_Seen (SI.Info_MA, SI.Change_Overlap) = 1,
             "Overlap timer start location passed at reception: over at "
             & "once, the SvL at the EOA (3.8.4.4.4)");
   end Scenario_LOA_Timer;

   --  3.8.5.1.3, A.3.4.1.3 [1], 3.8.5.1.5: a shortened MA deletes the
   --  information stored before it beyond its SvL, not what came with it
   procedure Scenario_MA_Shortening is
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 300));
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 1, MA_Of ((300, 400)));
      Carry (2, 0, Grad ((1 => (0, 2), 2 => (1000, End_Mark))));
      Carry (2, 1, MA_Of ((1 => 200)));
      Run_X (15_000);
      Check (SI.Current.MA.EOA = 80_000, "shortening: the first MA");
      Run_X (31_000);
      Check (SI.Current.MA.EOA = 50_000
             and then SI_Seen (SI.Info_MA, SI.Change_Shortened) = 1,
             "shortening: a closer SvL (3.8.5.1.3)");
      Check (TD.SSP.Count = 1 and then not TD.SSP.List (1).Open
             and then Est (TD.SSP.List (1).Finish) = 50_000,
             "shortening: the SSP stored before deleted beyond the SvL "
             & "(A.3.4.1.3 [1])");
      Check (TD.Gradients.Count = 2
             and then Est (TD.Gradients.List (2).Finish) = 130_000,
             "shortening: the gradients of the same message kept "
             & "(3.8.5.1.5)");
   end Scenario_MA_Shortening;

   --  3.18.2: national values, now or at a location, the countries;
   --  A.3.2 defaults; the packet converted
   procedure Scenario_National_Values is
      P : T3.Packet_T;
      S : NVa.Set_T;
   begin
      P.Q_DIR := 2;
      P.Q_SCALE := 1;
      P.D_VALIDNV := 32_767;
      P.NID_C := 123;
      P.N_ITER := 1;
      P.NID_C_List (1) := 124;
      P.V_NVSHUNT := 8;
      P.V_NVSTFF := 8;
      P.V_NVONSIGHT := 6;
      P.V_NVLIMSUPERV := 20;
      P.V_NVUNFIT := 20;
      P.V_NVREL := 10;
      P.D_NVROLL := 5;
      P.Q_NVSBTSMPERM := 1;
      P.Q_NVEMRRLS := 1;
      P.Q_NVGUIPERM := 1;
      P.V_NVALLOWOVTRP := 2;
      P.V_NVSUPOVTRP := 6;
      P.D_NVOVTRP := 200;
      P.T_NVOVTRP := 60;
      P.D_NVPOTRP := 200;
      P.M_NVCONTACT := 1;
      P.T_NVCONTACT := 30;
      P.M_NVDERUN := 1;
      P.D_NVSTFF := 32_767;
      P.Q_NVDRIVER_ADHES := 1;
      P.A_NVMAXREDADH1 := 20;
      P.A_NVMAXREDADH2 := 63;
      P.A_NVMAXREDADH3 := 14;
      P.Q_NVLOCACC := 10;
      P.M_NVAVADH := 10;
      P.M_NVEBCL := 5;
      P.Q_NVKINT := 1;
      P.Has_Q_NVKVINTSET := True;
      P.Q_NVKVINTSET := 1;
      P.Has_A_NVP12 := True;
      P.A_NVP12 := 16;
      P.A_NVP23 := 20;
      P.V_NVKVINT := 0;
      P.M_NVKVINT := 35;
      P.Has_M_NVKVINT_2 := True;
      P.M_NVKVINT_2 := 40;
      P.N_ITER_2 := 1;
      P.V_NVKVINT_List (1) :=
        (V_NVKVINT => 20, M_NVKVINT => 30, Has_M_NVKVINT_2 => True,
         M_NVKVINT_2 => 35);
      P.N_ITER_3 := 1;
      P.Q_NVKVINTSET_List (1).Q_NVKVINTSET := 0;
      P.Q_NVKVINTSET_List (1).V_NVKVINT := 0;
      P.Q_NVKVINTSET_List (1).M_NVKVINT := 45;
      P.L_NVKRINT := 4;
      P.M_NVKRINT := 18;
      P.N_ITER_4 := 1;
      P.L_NVKRINT_List (1) := (L_NVKRINT => 7, M_NVKRINT => 16);
      P.M_NVKTINT := 22;
      S := NVa.From_Packet (P);
      Check (S.Values.V_NVSHUNT = 1_111 and then S.Values.V_NVREL = 1_388
             and then S.Values.D_NVROLL = 500
             and then S.Values.Q_NVEMRRLS and then S.Values.Q_NVGUIPERM
             and then S.Values.T_NVOVTRP = 60_000
             and then S.Values.D_NVSTFF = EVC_Distances.Max_Cm
             and then S.Values.A_NVMAXREDADH1 = 1_000
             and then S.Values.A_NVMAXREDADH2 = SIn.Decel_Mms2_T'Last
             and then S.Values.M_NVAVADH = 500
             and then S.Values.M_NVEBCL = 5
             and then S.Q_NVLOCACC = 1_000
             and then S.M_NVCONTACT = 1 and then S.T_NVCONTACT = 30_000
             and then S.Country_Count = 2 and then S.Countries (2) = 124,
             "national values: the packet in on-board units");
      Check (S.Values.Kv_Int_Passenger.Count = 2
             and then S.Values.Kv_Int_Passenger.Steps (1).Factor = 700
             and then S.Values.Kv_Int_Passenger.Steps (2) = (2_777, 600)
             and then S.Values.Kv_Int_Passenger_B.Steps (1).Factor = 800
             and then S.Values.Kv_Int_Passenger_B.Steps (2).Factor = 700
             and then S.Values.Kv_Int_Fresh.Steps (1).Factor = 900
             and then S.Values.A_NVP12 = 800 and then S.Values.A_NVP23 = 1_000
             and then S.Values.Kr_Int.Count = 2
             and then S.Values.Kr_Int.Steps (1) = (10_000, 900)
             and then S.Values.Kr_Int.Steps (2) = (30_000, 800)
             and then S.Values.Kt_Int = 1_100,
             "national values: the integrated correction factors");

      Start_X;
      Check (SI.Current.National = NVa.Default_Values
             and then Onboard_Field (5) / 2 mod 2 = 0,
             "national values: the defaults of A.3.2 at power-up");
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 200));
      Add_Group (Group (30, 600));
      Add_Group (Group (40, 700));
      Carry (1, 0, P);
      P.D_VALIDNV := 200;
      P.V_NVREL := 12;
      Carry (2, 0, P);
      Country (4) := 200;
      Run_X (15_000);
      Check (SI.Current.National.V_NVREL = 1_388
             and then Onboard_Field (5) / 2 mod 2 = 1,
             "national values: applicable at once (D_VALIDNV now), the "
             & "driver's adhesion on the DMI");
      Run_X (35_000);
      Check (SI.Current.National.V_NVREL = 1_388 and then NVa.Pending,
             "national values: waiting for their location (3.18.2.3)");
      Run_X (40_500);
      Check (SI.Current.National.V_NVREL = 1_666 and then not NVa.Pending
             and then SI_Seen (SI.Info_National_Values,
                               SI.Change_Applicable) = 1,
             "national values: applicable when the estimated front end "
             & "reaches D_VALIDNV (3.18.2.3)");
      Run_X (65_000);
      Check (SI.Current.National.V_NVREL = 1_666,
             "national values: a group of a country of the set (124... "
             & "123) changes nothing");
      Run_X (75_000);
      Check (SI.Current.National = NVa.Default_Values
             and then SI_Seen (SI.Info_National_Values,
                               SI.Change_Defaults) = 1,
             "national values: a group of another country, the defaults "
             & "(3.18.2.5, 3.18.2.10)");
   end Scenario_National_Values;

   --  3.12.1, 5.18: track conditions stored, indicated on the DMI
   --  (MSG_TRACK_COND), in the planning, and the braking areas
   procedure Scenario_Track_Conditions is
      C  : T68.Packet_T;
      Tr : T39.Packet_T;
      B  : T67.Packet_T;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      C.Q_DIR := 1;
      C.Q_SCALE := 1;
      C.Q_TRACKINIT := 0;
      C.Has_D_TRACKCOND := True;
      C.D_TRACKCOND := 1000;      -- 1100 m
      C.L_TRACKCOND := 200;
      C.M_TRACKCOND := 3;         -- powerless section, lower pantograph
      C.N_ITER := 1;
      C.D_TRACKCOND_List (1) :=
        (D_TRACKCOND => 1300, L_TRACKCOND => 100, M_TRACKCOND => 6);
      Tr.Q_DIR := 1;
      Tr.Q_SCALE := 1;
      Tr.D_TRACTION := 1500;      -- 1600 m
      Tr.M_VOLTAGE := 3;
      Tr.Has_NID_CTRACTION := True;
      Tr.NID_CTRACTION := 7;
      B.Q_DIR := 1;
      B.Q_SCALE := 1;
      B.D_TRACKCOND := 300;
      B.L_TRACKCOND := 50;
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 0, C);
      Carry (1, 1, MA_Of ((1 => 3000)));
      Carry (1, 1, Tr);
      Carry (1, 1, B);
      Run_X (15_000);
      Check (TCo.Conditions.Count = 2 and then TCo.Traction_Changes.Count = 1
             and then TCo.Big_Metal_Masses.Count = 1
             and then Est (TCo.Conditions.List (2).Start) = 240_000
             and then TCo.Traction_Changes.List (1).Value = 3 * 1_024 + 7,
             "track conditions: stored (3.12.1)");
      Check (TC_Frames = 0, "track conditions: nothing indicated yet");
      Check (SI.Current.Inhibitions.Count = 2
             and then SI.Current.Inhibitions.Areas (1).Kind
                        = SIn.Regenerative_Inhibited
             and then SI.Current.Inhibitions.Areas (1).Start = 110_000
             and then SI.Current.Inhibitions.Areas (1).Finish = 150_000
             and then SI.Current.Inhibitions.Areas (2).Start = 240_000,
             "track conditions: the areas without regenerative brake, to "
             & "their end plus the train length (3.13.2.3.4)");
      Check (Natural (Plan_Payload (13)) = 1
             and then Natural (Plan_Payload (18)) = 4
             and then Natural (Plan_Payload (19)) = 2
             and then Plan_U16 (19) = (110_000 - 15_300) / 100,
             "planning: the orders of the track conditions ahead (lower "
             & "and raise pantograph, regenerative brake, DC 3 kV)");
      Run_X (100_000, 1000);
      Check (TC_Shows (3), "5.18.2.2: lower pantograph announced (TC03)");
      Run_X (112_000, 1000);
      Check (TC_Shows (1) and then not TC_Shows (3),
             "5.18.2.3: pantograph lowered (TC01)");
      Run_X (135_000, 1000);
      Check (TC_Shows (5), "5.18.2.5: raise pantograph (TC05)");
      Run_X (160_000, 1000);
      Stand_X (6_000);
      Check (not TC_Shows (5),
             "5.18.2.6: raise pantograph removed 5 s after the rear end");
      Check (TC_Shows (30) or else TC_Shows (29),
             "5.18.10: the change of traction system (TC30, TC29)");
      Run_X (200_000, 1000);
      Stand_X (6_000);
      Check (not TC_Shows (29) and then not TC_Shows (30),
             "5.18.10.6: the new traction system removed 5 s after the "
             & "rear end");
      Run_X (232_000, 1000);
      Check (TC_Shows (18),
             "5.18.7.3: inhibition of the regenerative brake announced");
      Run_X (250_000, 1000);
      Check (TC_Shows (17), "5.18.7.4: regenerative brake inhibited");
      Check_Golden ("profiles_track_conditions");
   end Scenario_Track_Conditions;

   --  3.12.2, 3.12.4, 3.12.5, 3.11.4, 3.13.2.3.5, 3.11.12.5: route
   --  suitability, mode profile, level crossing, ASP, adhesion, default
   --  gradient for TSR
   procedure Scenario_Other_Profiles is
      RS : T70.Packet_T;
      MP : T80.Packet_T;
      LX : T88.Packet_T;
      AS : T51.Packet_T;
      AD : T71.Packet_T;
      DG : T141.Packet_T;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 200));
      RS.Q_DIR := 1;
      RS.Q_SCALE := 1;
      RS.Has_D_SUITABILITY := True;
      RS.D_SUITABILITY := 500;
      RS.Q_SUITABILITY := 0;
      RS.Has_M_LINEGAUGE := True;
      RS.M_LINEGAUGE := 3;
      RS.N_ITER := 1;
      RS.D_SUITABILITY_List (1).D_SUITABILITY := 300;
      RS.D_SUITABILITY_List (1).Q_SUITABILITY := 1;
      RS.D_SUITABILITY_List (1).Has_M_LINEAXLELOADCAT := True;
      RS.D_SUITABILITY_List (1).M_LINEAXLELOADCAT := 16#0101#;
      MP.Q_DIR := 1;
      MP.Q_SCALE := 1;
      MP.D_MAMODE := 900;
      MP.M_MAMODE := 0;
      MP.V_MAMODE := 127;
      MP.L_MAMODE := 200;
      MP.L_ACKMAMODE := 100;
      MP.Q_MAMODE := 1;
      LX.Q_DIR := 1;
      LX.Q_SCALE := 1;
      LX.NID_LX := 3;
      LX.D_LX := 400;
      LX.L_LX := 20;
      LX.Q_LXSTATUS := 1;
      LX.Has_V_LX := True;
      LX.V_LX := 4;
      LX.Q_STOPLX := 1;
      LX.Has_L_STOPLX := True;
      LX.L_STOPLX := 30;
      AS.Q_DIR := 1;
      AS.Q_SCALE := 1;
      AS.Q_TRACKINIT := 0;
      AS.Has_D_AXLELOAD := True;
      AS.D_AXLELOAD := 200;
      AS.L_AXLELOAD := 100;
      AS.Q_FRONT := 1;
      AS.N_ITER := 2;
      AS.M_AXLELOADCAT_List (1) := (M_AXLELOADCAT => 0, V_AXLELOAD => 12);
      AS.M_AXLELOADCAT_List (2) := (M_AXLELOADCAT => 4, V_AXLELOAD => 8);
      AS.N_ITER_2 := 1;
      AS.D_AXLELOAD_List (1).D_AXLELOAD := 300;
      AS.D_AXLELOAD_List (1).L_AXLELOAD := 100;
      AS.D_AXLELOAD_List (1).N_ITER := 1;
      AS.D_AXLELOAD_List (1).M_AXLELOADCAT_List (1) :=
        (M_AXLELOADCAT => 4, V_AXLELOAD => 6);
      AD.Q_DIR := 1;
      AD.Q_SCALE := 1;
      AD.D_ADHESION := 100;
      AD.L_ADHESION := 300;
      AD.M_ADHESION := 0;
      DG.Q_DIR := 1;
      DG.Q_GDIR := 0;
      DG.G_TSR := 7;
      Carry (1, 0, SSP ((1 => (0, 100, False))));
      Carry (1, 0, RS);
      Carry (1, 0, LX);
      Carry (1, 1, AS);
      Carry (1, 1, AD);
      Carry (1, 1, DG);
      Carry (1, 1, MP);           -- no MA in the message: ignored
      Run_X (15_000);
      Check (TD.Suitability (1).Used and then TD.Suitability (2).Used
             and then TD.Suitability (1).Kind = 0
             and then TD.Suitability (2).Kind = 1
             and then TD.Suitability (2).Value = 16#0101#
             and then Est (TD.Suitability (2).At_Loc) = 90_000,
             "route suitability: stored (3.12.2; the check is E4/E6)");
      Check (not MAu.Mode_Profiles (1).Used,
             "mode profile: not taken without its MA (3.7.1.1 b)");
      Check (TD.LX (1).Used and then not TD.LX (1).Protected_LX
             and then TD.LX (1).Speed = 555 and then TD.LX (1).Stop_Required,
             "level crossing: stored (3.12.5)");
      Check (TD.ASP.Count = 1 and then Est (TD.ASP.List (1).Start) = 30_000
             and then TD.ASP.List (1).Value = 1_666,
             "ASP: the speed of the train's axle load category "
             & "(3.11.4.3), nothing where it is not listed");
      Check (SI.Current.Adhesion.Count = 1
             and then SI.Current.Adhesion.Areas (1).Start = 20_000
             and then SI.Current.Adhesion.Areas (1).Finish = 50_000,
             "adhesion: a slippery rail area (3.13.2.3.5)");
      Check (SI.Current.Gradients.Count = 1
             and then SI.Current.Gradients.Segments (1).Gradient = -7,
             "default gradient for TSR where no gradient is known "
             & "(3.11.12.5)");
      Check (SI.Current.MRSP.Segments (2).Start = 10_000
             and then SI.Current.MRSP.Segments (3).Start = 30_000
             and then SI.Current.MRSP.Segments (3).Speed = 1_666
             and then SI.Current.MRSP.Segments (5).Start = 50_000
             and then SI.Current.MRSP.Segments (5).Speed = 555
             and then SI.Current.MRSP.Segments (6).Start = 52_000,
             "MRSP: the ASP and the LX speed restriction (3.11.9)");
      Check (SI.Current.Temporary.Present
             and then SI.Current.Temporary.EOA = 50_000
             and then SI.Current.Temporary.Has_SvL,
             "level crossing not protected: its start a temporary EOA and "
             & "SvL (3.12.5.8)");
      Check (MRSP_Below_Sources, "MRSP below its sources, all kinds");

      --  a new route suitability of one type replaces that type only
      RS.N_ITER := 0;
      RS.D_SUITABILITY := 100;
      RS.M_LINEGAUGE := 1;
      Carry (2, 0, RS);
      Carry (2, 0, Grad ((1 => (0, 0))));
      Carry (2, 0, SSP ((1 => (0, 100, False))));
      Carry (2, 1, MA_Of ((1 => 500)));
      Carry (2, 1, MP);
      Run_X (25_000);
      Check (TD.Suitability (1).Used and then TD.Suitability (1).Value = 1
             and then TD.Suitability (2).Used
             and then TD.Suitability (2).Kind = 1,
             "route suitability: a type replaced, the others kept "
             & "(3.7.3.1 h, j)");
      Check (MAu.Mode_Profiles (1).Used
             and then MAu.Mode_Profiles (1).Mode = 0
             and then Est (MAu.Mode_Profiles (1).Start) = 110_000
             and then Est (MAu.Mode_Profiles (1).Ack_Start) = 100_000,
             "mode profile: stored with its MA (3.12.4)");
      Check (Integer_64 (SI.Current.Temporary.EOA)
               = Max_X (TD.LX (1).Start)
             and then SI.Current.Temporary.SvL = SI.Current.Temporary.EOA,
             "temporary EOA: the nearest (the LX before the mode profile); "
             & "its SvL, the max item moved by the relocation, and the EOA "
             & "not beyond it");

      --  3.7.3.2 b) to d): the initial states resumed from D_TRACKINIT
      declare
         C : T68.Packet_T;
      begin
         Add_Group (Group (30, 260));
         Add_Group (Group (40, 280));
         AS := (NID_PACKET => 51, Q_DIR => 1, Q_SCALE => 1,
                Q_TRACKINIT => 1, Has_D_TRACKINIT => True, D_TRACKINIT => 0,
                others => <>);
         RS := (NID_PACKET => 70, Q_DIR => 1, Q_SCALE => 1,
                Q_TRACKINIT => 1, Has_D_TRACKINIT => True, D_TRACKINIT => 0,
                others => <>);
         C.Q_DIR := 1;
         C.Q_SCALE := 1;
         C.Q_TRACKINIT := 0;
         C.Has_D_TRACKCOND := True;
         C.D_TRACKCOND := 400;
         C.L_TRACKCOND := 100;
         C.M_TRACKCOND := 0;
         Carry (3, 0, C);
         C := (NID_PACKET => 68, Q_DIR => 1, Q_SCALE => 1,
               Q_TRACKINIT => 1, Has_D_TRACKINIT => True, D_TRACKINIT => 0,
               others => <>);
         Carry (4, 0, AS);
         Carry (4, 0, RS);
         Carry (4, 1, C);
      end;
      Run_X (27_000);
      Check (TCo.Conditions.Count = 1, "track conditions: one stored");
      Run_X (35_000);
      Check (TD.ASP.Count = 0
             and then not TD.Suitability (1).Used
             and then not TD.Suitability (2).Used
             and then TCo.Conditions.Count = 0,
             "initial states resumed from D_TRACKINIT: ASP, route "
             & "suitability, track conditions (3.7.3.2 b, c, d)");
   end Scenario_Other_Profiles;

   --  A.3.1: the information 300 m in rear of the min safe rear end is
   --  deleted, and its origin released
   procedure Scenario_Rear_Deletion is
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, False), 2 => (100, 80, False),
                         3 => (100, 60, False))));
      Run_X (15_000);
      Check (TD.SSP.Count = 3 and then EVC_Origins.Used_Count = 1,
             "rear: stored, one origin");
      Run_X (70_000, 2000);
      Check (TD.SSP.Count = 3, "rear: kept up to 300 m in rear");
      Run_X (80_000, 2000);
      Check (TD.SSP.Count = 2,
             "rear: an element 300 m behind the min safe rear end deleted "
             & "(A.3.1)");
   end Scenario_Rear_Deletion;

begin
   Scenario_Protocol_Constants;
   Scenario_Power_Up;
   Scenario_Malformed;
   Scenario_Valid_Inputs;
   Scenario_Isolation;
   Scenario_Time;
   Scenario_Outbox;
   Scenario_Failure;
   Scenario_End_To_End;
   Scenario_Packet_Round_Trips;
   Scenario_Telegram;
   Scenario_Telegram_Damaged;
   Scenario_Message;
   Scenario_Telegram_Length;
   Scenario_Spare_Values;
   Scenario_Senders;
   Scenario_Received;
   Scenario_Position_First_Group;
   Scenario_Linking;
   Scenario_Linking_Errors;
   Scenario_Single_Balise;
   Scenario_Geo;
   Scenario_Odometer_Accuracy;
   Scenario_Cold_Movement;
   Scenario_Orientation;
   Scenario_Virtual;
   Scenario_Report_Triggers;
   Scenario_Rear_End;
   Scenario_Relocation;
   Scenario_Repositioning;
   Scenario_Geo_Orientation;
   Check (Encodes_OK, "E2: every telegram of the track encoded");
   Scenario_E3_Protocol;
   Scenario_SSP_Categories;
   Scenario_SSP_Gradients;
   Scenario_SSP_Replacement;
   Scenario_TSR;
   Scenario_MA;
   Scenario_Section_Timer;
   Scenario_Section_Timer_Stopped;
   Scenario_Overlap_Timer;
   Scenario_End_Section_Timer;
   Scenario_LOA_Timer;
   Scenario_MA_Shortening;
   Scenario_National_Values;
   Scenario_Track_Conditions;
   Scenario_Other_Profiles;
   Scenario_Rear_Deletion;
   Check (Encodes_OK, "E3: every telegram of the track encoded");

   Put_Line ("checks:" & Natural'Image (Checks)
             & "  failures:" & Natural'Image (Failures));
   Ada.Command_Line.Set_Exit_Status
     (if Failures = 0 then Ada.Command_Line.Success
      else Ada.Command_Line.Failure);
end EVC_Test;
