with EVC_Test_Support;  use EVC_Test_Support;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Streams;
with DMI_Core;
with DMI_Protocol;
with DMI_Status;
with Display.Screen.Files;
with Display.Screen;
with EVC_Bytes;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Driver;
with EVC_Mock;
with EVC_Modes;
with EVC_Outbox;
with EVC_Ports;
with General_Parameters;
with Interfaces;

package body EVC_Test_Core is

   use type EVC_Bytes.Byte_Array;
   use type EVC_Core.Cycle_T;
   use type EVC_Core.Time_Ms_T;
   use Ada.Streams;
   use EVC_Modes;
   use EVC_Ports;
   use Interfaces;

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
      --  e5/registration: and the registration of the two GSM-R mobiles
      --  (3.5.6.1 a)
      Check (Rec_Count = 6, "power-up: six records, got" & Img (Rec_Count));
      if Rec_Count = 6 then
         Check (Recs (1).Port = JRU and then Rec_Length (1) = 16
                and then Byte_At (1, 1) = 1
                and then Byte_At (1, 2) = Mode_T'Pos (M_SB)
                and then Byte_At (1, 5) = 1        -- cycle
                and then Byte_At (1, 9) = 100,     -- time, ms
                "power-up: JRU records the change to SB");
         Check (Recs (2).Port = DMI and then Recs (3).Port = DMI
                and then Recs (4).Port = DMI,
                "power-up: then three DMI frames");
         Check (Recs (5).Port = RTM and then Recs (6).Port = RTM
                and then Radio_Output (1).Request
                and then Radio_Output (1).Kind = 3
                and then Radio_Output (2).Session = 2,
                "power-up: then the registration of each mobile to the "
                & "GSM-R network (3.5.6.1 a, 3.5.6.3)");
      end if;
      Check (DMI_Mode_Byte = 1, "power-up: MSG_MODE_LEVEL mode SB (1), got"
             & Img (DMI_Mode_Byte));
      Check (DMI_Level_Byte = 0,
             "power-up: MSG_MODE_LEVEL level unknown (0)");
      --  phase E4: the start of mission is engaged with a desk open
      --  (5.4.3.2 S0), and no cab status input came
      Check (Onboard_Field (6) = 0,
             "power-up: MSG_ONBOARD som 0, no desk open (5.4.3.2 S0)");
      Check (Onboard_Field (4) = 3,
             "power-up: MSG_ONBOARD standstill, below override speed");
      Check_Golden ("power_up_cycle_1");

      Reset_Capture;
      for I in 2 .. 5 loop
         EVC_Core.Tick (100);
         Take;
         Check (Parsed and then Rec_Count = 3
                and then Count_Port (DMI) = 3
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
      Bad (TIU, (14, 1), "signal 14");
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

      EVC_Core.Tick (100);  -- 17 + 19 + 29 bytes
      EVC_Core.Take_Outputs (Tiny, Last);
      Check (Last = 0, "outbox: no record fits 10 bytes");
      EVC_Core.Take_Outputs (Small, Last);
      Check (Last = 17 and then Small (1) = Port_T'Pos (DMI)
             and then Small (4) = EVC_DMI_Port.MSG_MODE_LEVEL,
             "outbox: 20 bytes take the MSG_MODE_LEVEL record");
      EVC_Core.Take_Outputs (Null_Buffer, Last);
      Check (Last = 0, "outbox: a null buffer takes nothing");
      EVC_Core.Take_Outputs (Offset, Last);
      Check (Last = 97 and then Offset (53) = EVC_DMI_Port.MSG_ONBOARD
             and then Offset (72) = EVC_DMI_Port.MSG_SPEED_STATE,
             "outbox: a buffer from index 50 takes the MSG_ONBOARD and the"
             & " MSG_SPEED_STATE records");
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

      --  2. the on-board, the link supervised; the desk of cab A open
      --  (phase E4: the start of mission is engaged with a desk open,
      --  5.4.3.2 S0, which EVC_Mock takes for granted)
      DMI_Core.Initialise;
      EVC_Core.Initialise;
      EVC_Core.Handle_Input (TIU, (1, 1));
      for I in 1 .. 5 loop
         EVC_Core.Tick (100);
         Feed_DMI;
         DMI_Core.Tick (100);
         Pump_To_EVC;
      end loop;
      DMI_Core.Render;
      Check (Frames = 15,
             "end to end: three frames per cycle reach the DMI");
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

end EVC_Test_Core;
