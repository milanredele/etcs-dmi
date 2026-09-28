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
with ETCS_Track_Packets.P45;
with ETCS_Track_Packets.P65;
with ETCS_Track_Packets.P73;
with ETCS_Track_Packets.P140;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P4;
with ETCS_Variables;
with EVC_Bytes;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Driver;
with EVC_Mock;
with EVC_Modes;    use EVC_Modes;
with EVC_Outbox;
with EVC_Ports;    use EVC_Ports;
with EVC_Received;
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

   --  An odometer sample (EVC_Ports)
   function Odometer_Payload
     (D_Est, D_Min, D_Max : Integer_32;
      V_Est, V_Min, V_Max : Unsigned_16;
      Direction           : Byte) return Byte_Array
   is
      function U32 (V : Integer_32) return Byte_Array is
         U : constant Unsigned_64 :=
           Unsigned_64 (Unsigned_32'Mod (Integer_64 (V)));
      begin
         return (EVC_Bytes.Byte_Of (U, 0), EVC_Bytes.Byte_Of (U, 1),
                 EVC_Bytes.Byte_Of (U, 2), EVC_Bytes.Byte_Of (U, 3));
      end U32;
      function U16 (V : Unsigned_16) return Byte_Array is
        (Byte (V mod 256), Byte (V / 256));
   begin
      return U32 (D_Est) & U32 (D_Min) & U32 (D_Max)
             & U16 (V_Est) & U16 (V_Min) & U16 (V_Max)
             & Byte_Array'(1 => Direction);
   end Odometer_Payload;

   --  A telegram of N_Bits bits, with Extra bytes more or fewer than its
   --  shape asks for
   function BTM_Payload (N_Bits : Natural; Extra : Integer := 0)
     return Byte_Array
   is
      Length : constant Natural := (N_Bits + 7) / 8 + Extra;
      Result : Byte_Array (1 .. 2 + Length) := (others => 16#A5#);
   begin
      Result (1) := Byte (N_Bits mod 256);
      Result (2) := Byte (N_Bits / 256 mod 256);
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
             and then Unsigned_8 (MSG_DRIVER_ACTION)
                        = EVC_DMI_Port.MSG_DRIVER_ACTION
             and then Unsigned_8 (MSG_DRIVER_DATA)
                        = EVC_DMI_Port.MSG_DRIVER_DATA,
             "message types equal DMI_Protocol");
      Check (Mode_Level_Length = EVC_DMI_Port.Mode_Level_Length
             and then Onboard_Length = EVC_DMI_Port.Onboard_Length
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
        Odometer_Payload (100, 90, 110, 500, 400, 600, 1);
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
      --  RTM
      Bad (RTM, RTM_Payload (0, 2), "2 bytes");
      Bad (RTM, RTM_Payload (10, 9), "L_MESSAGE 10, 9 bytes");
      Bad (RTM, RTM_Payload (9, 10), "L_MESSAGE 9, 10 bytes");
      --  Odometer
      Bad (Odometer, Odo_Ok (1 .. 18), "18 bytes");
      Bad (Odometer, Odo_Ok & Byte_Array'(1 => 0), "20 bytes");
      Bad (Odometer, Odometer_Payload (100, 101, 110, 500, 400, 600, 1),
           "d_min above d_est");
      Bad (Odometer, Odometer_Payload (100, 90, 99, 500, 400, 600, 1),
           "d_max below d_est");
      Bad (Odometer, Odometer_Payload (-5, 0, 10, 500, 400, 600, 1),
           "d_min above a negative d_est");
      Bad (Odometer, Odometer_Payload (100, 90, 110, 700, 400, 600, 1),
           "v_est above v_max");
      Bad (Odometer, Odometer_Payload (100, 90, 110, 300, 400, 600, 1),
           "v_est below v_min");
      Bad (Odometer, Odometer_Payload (100, 90, 110, 500, 400, 600, 3),
           "direction 3");
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
      Shifted : Byte_Array (1000 .. 1028);
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      Input (BTM, BTM_Payload (210));
      Input (BTM, BTM_Payload (830));
      Shifted := BTM_Payload (210);
      Input (BTM, Shifted);                 -- index not starting at 1
      Input (RTM, RTM_Payload (3, 3));
      Input (RTM, RTM_Payload (1023, 1023));
      Input (Odometer, Odometer_Payload (-200, -210, -190, 0, 0, 0, 0));
      Input (Odometer, Odometer_Payload (5000, 4990, 5010, 1000, 990, 1010,
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
      Input (Odometer, Odometer_Payload (5000, 4990, 5010, 0, 0, 0, 1));
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

   --  The BTM payload of a telegram of Bits bits (EVC_Ports)
   function BTM_Of (Data : Byte_Array; Bits : Natural) return Byte_Array is
      Length : constant Natural := (Bits + 7) / 8;
      Result : Byte_Array (1 .. 2 + Length) := (others => 0);
   begin
      Result (1) := Byte (Bits mod 256);
      Result (2) := Byte (Bits / 256);
      Result (3 .. 2 + Length) := Data (Data'First .. Data'First + Length - 1);
      return Result;
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

   Put_Line ("checks:" & Natural'Image (Checks)
             & "  failures:" & Natural'Image (Failures));
   Ada.Command_Line.Set_Exit_Status
     (if Failures = 0 then Ada.Command_Line.Success
      else Ada.Command_Line.Failure);
end EVC_Test;
