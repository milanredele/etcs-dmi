--  ETCS DMI test simulator
--  The environment of the ETCS on-board: implementation.

with DMI_Link;
with DMI_Protocol; use DMI_Protocol;
with EVC_Bytes;
with EVC_Core;
with EVC_Driver;
with EVC_Outbox;
with EVC_Ports;
with EVC_Train;
with Interfaces;   use Interfaces;
with Sim_JRU;
with Sim_Odometer;
with Sim_RBC;
with Sim_Telegrams;
with Sim_Trackside;

package body Sim_Onboard_Env is

   use type EVC_Track.Preset_T;

   subtype Byte is EVC_Bytes.Byte;

   --  The DMI frames of the on-board, until Take_DMI
   Tx        : Stream_Element_Array (1 .. 16_384);
   Tx_Filled : Stream_Element_Offset := 0;
   Dropped   : Natural := 0;

   --  The desk
   Desk_Demand : Integer range -100 .. 100 := 0;
   Auto        : Boolean := True;

   --  The track of the next Reset (Set_Track_Preset)
   Preset : EVC_Track.Preset_T := EVC_Track.Default;

   --  What the on-board said last
   Shown_Mode, Shown_Level : Natural := 255;
   Shown_V_Cur, Shown_V_Perm, Shown_Monitoring, Shown_Status : Natural := 0;
   Shown_Brake : Natural := 0;
   Detected    : Natural := 0;
   --  MSG_ONBOARD: data, session, rbc, waiting
   Shown_Data, Shown_Session, Shown_RBC, Shown_Waiting : Natural := 0;
   --  MSG_MODE_LEVEL mode_ack: the mode to acknowledge, 16#FF# none
   Shown_Mode_Ack : Natural := 16#FF#;

   --  The scripted start of mission in level 2: the steps sent
   L2_Sent : Natural := 0;

   Outputs : EVC_Bytes.Byte_Array (1 .. EVC_Outbox.Capacity);

   function Inc (N : Natural) return Natural is
     (if N < Natural'Last then N + 1 else N);

   --  The vehicle, quantised: the antenna (cm of the track) and the speed
   --  (cm/s)
   function Antenna_To_Cab_A_Cm return Integer is
     (Integer (EVC_Core.Configuration.Antenna_To_Cab_A));

   function Antenna_Cm return Integer_64 is
     (Integer_64 (Float'Floor (EVC_Train.Position_M * 100.0))
      - Integer_64 (Antenna_To_Cab_A_Cm));

   function Speed_Cms return Natural is
     (Natural (Float'Floor (Float'Min (655.35, EVC_Train.Speed_MS)
                            * 100.0)));

   ---------------------------------------------------------------------
   --  From the DMI
   ---------------------------------------------------------------------

   procedure Handle (The_Type : Msg_Type_T;
                     Payload  : Stream_Element_Array)
   is
      Offset : Stream_Element_Offset := Payload'First;
   begin
      if The_Type = MSG_DESK then
         if Payload'Length = Desk_Length then
            declare
               Demand : constant Unsigned_8 := Get_U8 (Payload, Offset);
               On     : constant Unsigned_8 := Get_U8 (Payload, Offset);
               Value  : constant Integer :=
                 (if Demand >= 128 then Integer (Demand) - 256
                  else Integer (Demand));
            begin
               Set_Desk (Value, On /= 0);
            end;
         end if;
      elsif Payload'Length <= EVC_Ports.DMI_Max_Length - Header_Length then
         declare
            Frame  : EVC_Bytes.Byte_Array
              (1 .. Header_Length + Natural (Payload'Length));
            Header : Stream_Element_Array (1 .. Header_Length);
            At_H   : Stream_Element_Offset := Header'First;
         begin
            Put_Header (Header, At_H, The_Type, Payload'Length);
            for I in Header'Range loop
               Frame (Natural (I)) := Byte (Header (I));
            end loop;
            for I in Payload'Range loop
               Frame (Header_Length + Natural (I - Payload'First) + 1) :=
                 Byte (Payload (I));
            end loop;
            EVC_Core.Handle_Input (EVC_Ports.DMI, Frame);
         end;
      end if;
   end Handle;

   package Link is new DMI_Link (Handle, Capacity => 4096);

   Radio_On : Boolean := False;

   procedure Set_Radio (On : Boolean) is
   begin
      Radio_On := On;
   end Set_Radio;

   function Radio return Boolean is (Radio_On);

   procedure RBC_Emergency_Stop is
   begin
      if Radio_On then
         Sim_RBC.Emergency_Stop;
      end if;
   end RBC_Emergency_Stop;

   --  The answers of the RBC for the on-board's next cycle
   procedure Give_RTM_Inputs is
      Buffer : EVC_Bytes.Byte_Array (1 .. EVC_Ports.RTM_Input_Max_Length);
      Last   : Natural;
   begin
      for I in 1 .. 64 loop
         Sim_RBC.Next_Input (Buffer, Last);
         exit when Last < Buffer'First;
         EVC_Core.Handle_Input (EVC_Ports.RTM, Buffer (1 .. Last));
      end loop;
   end Give_RTM_Inputs;

   procedure Receive (Data : Stream_Element_Array) is
   begin
      Link.Feed (Data);
   end Receive;

   procedure Set_Desk (Demand : Integer; Auto : Boolean) is
   begin
      Sim_Onboard_Env.Auto := Auto;
      if Demand in -100 .. 100 then
         Desk_Demand := Demand;
      end if;
   end Set_Desk;

   procedure Set_Track_Preset (Preset : EVC_Track.Preset_T) is
   begin
      Sim_Onboard_Env.Preset := Preset;
   end Set_Track_Preset;

   function Track_Preset return EVC_Track.Preset_T is (Preset);

   procedure Set_Cab (Cab : Sim_Vehicle.Cab_T) is
   begin
      Sim_Vehicle.Set_Cab (Cab);
   end Set_Cab;

   procedure Set_Controller (Position : Sim_Vehicle.Byte) is
   begin
      Sim_Vehicle.Set_Controller (Position);
   end Set_Controller;

   procedure Set_Sleeping (On : Boolean) is
   begin
      Sim_Vehicle.Set_Sleeping (On);
   end Set_Sleeping;

   procedure Set_Passive_Shunting (On : Boolean) is
   begin
      Sim_Vehicle.Set_Passive_Shunting (On);
   end Set_Passive_Shunting;

   procedure Set_Non_Leading (On : Boolean) is
   begin
      Sim_Vehicle.Set_Non_Leading (On);
   end Set_Non_Leading;

   procedure Set_Train_Configuration (Value : Sim_Vehicle.Byte) is
   begin
      Sim_Vehicle.Set_Train_Configuration (Value);
   end Set_Train_Configuration;

   ---------------------------------------------------------------------
   --  From the on-board
   ---------------------------------------------------------------------

   --  One DMI frame of the on-board: queued, and read for the driver
   procedure Take_Frame (Frame : EVC_Bytes.Byte_Array) is
      N : constant Stream_Element_Offset :=
        Stream_Element_Offset (Frame'Length);

      function U16 (At_Payload : Natural) return Natural is
        (Natural (Frame (Frame'First + Header_Length + At_Payload))
         + 256 * Natural (Frame (Frame'First + Header_Length
                                 + At_Payload + 1)));
   begin
      if Tx_Filled + N <= Tx'Last then
         for I in 0 .. N - 1 loop
            Tx (Tx_Filled + 1 + I) :=
              Stream_Element (Frame (Frame'First + Natural (I)));
         end loop;
         Tx_Filled := Tx_Filled + N;
      else
         Dropped := Inc (Dropped);
      end if;
      if Frame'Length < Header_Length + 1 then
         return;
      end if;
      case Frame (Frame'First) is
         when 16#01# =>   -- MSG_SPEED_STATE
            if Frame'Length >= Header_Length + 21 then
               Shown_V_Cur := U16 (0);
               Shown_V_Perm := U16 (2);
               Shown_Monitoring :=
                 Natural (Frame (Frame'First + Header_Length + 16));
               Shown_Status :=
                 Natural (Frame (Frame'First + Header_Length + 19));
            end if;
         when 16#02# =>   -- MSG_MODE_LEVEL
            if Frame'Length >= Header_Length + 2 then
               Shown_Mode := Natural (Frame (Frame'First + Header_Length));
               Shown_Level :=
                 Natural (Frame (Frame'First + Header_Length + 1));
            end if;
            if Frame'Length >= Header_Length + 3 then
               Shown_Mode_Ack :=
                 Natural (Frame (Frame'First + Header_Length + 2));
            end if;
         when 16#07# =>   -- MSG_STATUS
            Shown_Brake := Natural (Frame (Frame'First + Header_Length));
         when 16#0A# =>   -- MSG_ONBOARD
            if Frame'Length >= Header_Length + 7 then
               Shown_Data := Natural (Frame (Frame'First + Header_Length));
               Shown_Session :=
                 Natural (Frame (Frame'First + Header_Length + 1));
               Shown_RBC := Natural (Frame (Frame'First + Header_Length + 2));
               Shown_Waiting :=
                 Natural (Frame (Frame'First + Header_Length + 6));
            end if;
         when others =>
            null;
      end case;
   end Take_Frame;

   --  The records of EVC_Outbox: port u8, length u16, payload
   procedure Collect_Outputs is
      Last : Natural;
      Pos  : Natural := Outputs'First;
      Length : Natural;
   begin
      EVC_Core.Take_Outputs (Outputs, Last);
      while Last >= Pos
        and then Last - Pos + 1 >= EVC_Outbox.Record_Header
      loop
         Length := Natural (Outputs (Pos + 1))
                   + 256 * Natural (Outputs (Pos + 2));
         exit when Pos + EVC_Outbox.Record_Header + Length - 1 > Last;
         declare
            Payload : EVC_Bytes.Byte_Array renames
              Outputs (Pos + EVC_Outbox.Record_Header
                       .. Pos + EVC_Outbox.Record_Header + Length - 1);
         begin
            case Outputs (Pos) is
               when EVC_Ports.Port_T'Pos (EVC_Ports.DMI) =>
                  Take_Frame (Payload);
               when EVC_Ports.Port_T'Pos (EVC_Ports.TIU) =>
                  if EVC_Ports.Is_TIU_TC_Output (Payload) then
                     --  the second TIU output (5.20, track conditions)
                     declare
                        TC : Sim_Vehicle.TIU_TC_Array := (others => 0);
                     begin
                        for I in Payload'Range loop
                           exit when I - Payload'First + 1
                                       > Sim_Vehicle.TIU_TC_Max_Length;
                           TC (I - Payload'First + 1) := Payload (I);
                        end loop;
                        Sim_Vehicle.Command_TC
                          (TC, Natural'Min (Length,
                                           Sim_Vehicle.TIU_TC_Max_Length));
                     end;
                  elsif Length = EVC_Ports.TIU_Output_Length then
                     Sim_Vehicle.Command
                       (Payload (Payload'First),
                        Sim_Vehicle.Reasons_T (Payload (Payload'First + 1))
                        + 256 * Sim_Vehicle.Reasons_T
                                  (Payload (Payload'First + 2)));
                  end if;
               when EVC_Ports.Port_T'Pos (EVC_Ports.JRU) =>
                  Sim_JRU.Put (Payload);
               when EVC_Ports.Port_T'Pos (EVC_Ports.RTM) =>
                  if Radio_On then
                     Sim_RBC.Take (Payload);
                  end if;
               when others =>
                  null;
            end case;
         end;
         Pos := Pos + EVC_Outbox.Record_Header + Length;
      end loop;
   end Collect_Outputs;

   ---------------------------------------------------------------------
   --  The cycle
   ---------------------------------------------------------------------

   procedure Give_TIU_Inputs is
      List  : Sim_Vehicle.Input_List;
      Count : Natural;
   begin
      Sim_Vehicle.Take_Inputs (List, Count);
      for I in 1 .. Count loop
         EVC_Core.Handle_Input (EVC_Ports.TIU, List (I));
      end loop;
   end Give_TIU_Inputs;

   procedure Reset is
   begin
      Sim_Trackside.Build (Preset);
      EVC_Core.Initialise;
      EVC_Train.Reset;
      EVC_Train.Position_M := Start_Front_M;
      Sim_Vehicle.Reset;
      Sim_JRU.Reset;
      Sim_RBC.Reset;
      Sim_Odometer.Reset (Antenna_Cm);
      Link.Reset;
      Tx_Filled := 0;
      Dropped := 0;
      Desk_Demand := 0;
      Auto := True;
      Shown_Mode := 255;
      Shown_Level := 255;
      Shown_V_Cur := 0;
      Shown_V_Perm := 0;
      Shown_Monitoring := 0;
      Shown_Status := 0;
      Shown_Brake := 0;
      Detected := 0;
      Shown_Data := 0;
      Shown_Session := 0;
      Shown_RBC := 0;
      Shown_Waiting := 0;
      Shown_Mode_Ack := 16#FF#;
      L2_Sent := 0;
      --  power-up: the cab, the controller, the brake pressure, and the
      --  odometer at standstill
      Sim_Vehicle.Measure;
      Give_TIU_Inputs;
      EVC_Core.Handle_Input (EVC_Ports.Odometer, Sim_Odometer.Sample);
   end Reset;

   procedure Step (Dt_Ms : Natural) is
      Failed_Now : constant Boolean := EVC_Core.Failed;
      Braking    : constant Boolean :=
        (Sim_Vehicle.Commands
         and (EVC_Ports.TIU_EBC or EVC_Ports.TIU_SBC)) /= 0;
   begin
      --  1. the driver
      if Auto then
         EVC_Driver.Auto_Drive_Onboard
           (V_Cur_KMH       => Shown_V_Cur,
            V_Perm_KMH      => Shown_V_Perm,
            Monitoring      => Shown_Monitoring,
            Brake_Commanded => Braking or else Failed_Now);
      else
         EVC_Train.Demand := Desk_Demand;
      end if;

      --  2. the vehicle
      Sim_Vehicle.Apply (Failed_Now);
      EVC_Train.Step (Float (Natural'Min (Dt_Ms, 60_000)) / 1000.0);
      Sim_Vehicle.Measure;

      --  3. the odometer, the balises passed, the sample, the TIU
      Sim_Odometer.Advance (Antenna_Cm, Speed_Cms);
      --  (the balises are in the order of the track, the train runs
      --  towards rising positions only: the order of passing)
      for B in Sim_Trackside.Balise_Index loop
         declare
            At_Cm : constant Integer_64 := Sim_Trackside.Balise_At_Cm (B);
         begin
            if Sim_Odometer.Passed (At_Cm) then
               EVC_Core.Handle_Input
                 (EVC_Ports.BTM,
                  Sim_Telegrams.BTM_Payload
                    (Sim_Trackside.Telegram (B),
                     Sim_Odometer.Stamp (At_Cm)));
               Detected := Inc (Detected);
            end if;
         end;
      end loop;
      EVC_Core.Handle_Input (EVC_Ports.Odometer, Sim_Odometer.Sample);
      Give_TIU_Inputs;
      if Radio_On then
         Sim_RBC.Step (Dt_Ms);
         Give_RTM_Inputs;
      end if;

      --  4. the on-board
      EVC_Core.Tick (Dt_Ms);

      --  5. its outputs
      Collect_Outputs;

      --  6. the scripted start of mission in level 2, a step once the
      --  on-board answered the one before (read at its next cycle)
      if Radio_On and then L2_Sent < SoM_L2_Steps
        and then SoM_L2_Ready (L2_Sent + 1)
      then
         L2_Sent := L2_Sent + 1;
         Receive (SoM_L2_Frame (L2_Sent));
      end if;
   end Step;

   procedure Take_DMI (Buffer : out Stream_Element_Array;
                       Last   : out Stream_Element_Offset)
   is
      --  whole frames only
      Count : Stream_Element_Offset := 0;
      Pos   : Stream_Element_Offset := Tx'First;
      Size  : Stream_Element_Offset;
   begin
      Buffer := (others => 0);
      while Pos + Header_Length - 1 <= Tx_Filled loop
         declare
            At_L : Stream_Element_Offset := Pos + 1;
         begin
            Size := Header_Length
              + Stream_Element_Offset (Get_U32 (Tx, At_L));
            exit when Pos + Size - 1 > Tx_Filled
              or else Count + Size > Buffer'Length;
         end;
         Count := Count + Size;
         Pos := Pos + Size;
      end loop;
      Buffer (Buffer'First .. Buffer'First + Count - 1) := Tx (1 .. Count);
      Last := Buffer'First + Count - 1;
      --  what stays queued moves to the front
      Tx (1 .. Tx_Filled - Count) := Tx (Count + 1 .. Tx_Filled);
      Tx_Filled := Tx_Filled - Count;
   end Take_DMI;

   procedure Enter_Failure is
   begin
      EVC_Core.Enter_Failure;
   end Enter_Failure;

   function SoM_Frame (K : Positive) return Stream_Element_Array is
     (case K is
         --  MSG_DRIVER_DATA kind 0, the driver ID
         when 1 => (16#41#, 6, 0, 0, 0, 0, 4,
                    Character'Pos ('1'), Character'Pos ('2'),
                    Character'Pos ('3'), Character'Pos ('4')),
         --  MSG_DRIVER_ACTION 11, level 1
         when 2 => (16#40#, 3, 0, 0, 0, 11, 4, 0),
         --  MSG_DRIVER_DATA kind 2, the Train Data
         when 3 => (16#41#, 13, 0, 0, 0, 2,
                    200, 0,       -- 200 m
                    135, 0,       -- 135 %
                    160, 0,       -- 160 km/h
                    2,            -- NC_CDTRAIN 130 mm
                    4, 0,         -- NC_TRAIN passenger train
                    0, 0, 1),     -- axle load A, not airtight, G1
         --  MSG_DRIVER_DATA kind 1, the train running number
         when 4 => (16#41#, 6, 0, 0, 0, 1, 4,
                    Character'Pos ('5'), Character'Pos ('6'),
                    Character'Pos ('7'), Character'Pos ('8')),
         --  MSG_DRIVER_ACTION 5, 'Start'
         when 5 => (16#40#, 3, 0, 0, 0, 5, 0, 0),
         --  MSG_DRIVER_ACTION 2, kind 1: the mode acknowledged
         when others => (16#40#, 5, 0, 0, 0, 2, 1, 0, 0, 0));

   function SoM_L2_Frame (K : Positive) return Stream_Element_Array is
     (case K is
         --  MSG_DRIVER_ACTION 11, level 2
         when 2 => (16#40#, 3, 0, 0, 0, 11, 5, 0),
         --  MSG_DRIVER_DATA kind 5, the RBC contact entered (choice 0):
         --  NID_C * 2**14 + NID_RBC u32, the phone number "0077"
         when 3 => (16#41#, 23, 0, 0, 0, 5, 0,
                    Stream_Element ((EVC_Track.NID_C * 16_384 + 1) mod 256),
                    Stream_Element ((EVC_Track.NID_C * 16_384 + 1) / 256
                                    mod 256),
                    Stream_Element ((EVC_Track.NID_C * 16_384 + 1)
                                    / 65_536),
                    0, 4,
                    Character'Pos ('0'), Character'Pos ('0'),
                    Character'Pos ('7'), Character'Pos ('7'),
                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
         --  the Train Data, the train running number, 'Start' of level 1
         when 4 => SoM_Frame (3),
         when 5 => SoM_Frame (4),
         when 6 => SoM_Frame (5),
         --  the acknowledgement of Staff Responsible
         when 7 => SoM_Frame (6),
         --  the driver ID
         when others => SoM_Frame (1));

   function SoM_L2_Ready (K : Positive) return Boolean is
     (case K is
         when 1 => Shown_Mode /= 255,
         --  the driver ID valid
         when 2 => Shown_Data mod 2 = 1,
         --  the level valid
         when 3 => Shown_Data / 4 mod 2 = 1,
         --  the session established, nothing awaited
         when 4 => Shown_Session >= 2 and then Shown_Waiting = 0,
         --  the Train Data acknowledged by the RBC
         when 5 => Shown_RBC mod 2 = 1,
         --  the train running number valid
         when 6 => Shown_Data / 8 mod 2 = 1,
         --  SR to acknowledge (DMI Table 60 code 7): the RBC's SR
         --  authorisation (message 2, 5.4.3.2 S23 / S24)
         when others => Shown_Mode_Ack = 7);

   function SoM_L2_Sent return Natural is (L2_Sent);
   function Onboard_Data return Natural is (Shown_Data);
   function Onboard_Session return Natural is (Shown_Session);
   function Onboard_RBC return Natural is (Shown_RBC);
   function Onboard_Waiting return Natural is (Shown_Waiting);

   function Failed return Boolean is (EVC_Core.Failed);

   function Mode_Code return Natural is (Shown_Mode);
   function Level_Code return Natural is (Shown_Level);
   function V_Cur_KMH return Natural is (Shown_V_Cur);
   function V_Perm_KMH return Natural is (Shown_V_Perm);
   function Monitoring return Natural is (Shown_Monitoring);
   function Status return Natural is (Shown_Status);
   function Brake_Indication return Natural is (Shown_Brake);
   function Ack_Requested return Boolean is (Shown_Brake = 2);
   function Position_M return Integer is
     (Integer (Float'Floor (EVC_Train.Position_M)));
   function Speed_KMH return Natural is (EVC_Train.Speed_KMH);
   function Balises_Read return Natural is (Detected);
   function Dropped_DMI return Natural is (Dropped);

   function Group_Count return Natural is
     ((if Preset = EVC_Track.Features
       then EVC_Track.Balise_Groups_Features'Length
       else EVC_Track.Balise_Groups'Length));
   function Group_At (Index : Positive) return Integer is
     ((if Preset = EVC_Track.Features
       then EVC_Track.Balise_Groups_Features (Index).At_M
       else EVC_Track.Balise_Groups (Index).At_M));

   function TC_Length return Natural is (Sim_Vehicle.TC_Length);
   function TC_Payload return Sim_Vehicle.TIU_TC_Array is
     (Sim_Vehicle.TC_Payload);

   procedure Sim_State_Payload (Buffer : out Stream_Element_Array;
                                Last   : out Stream_Element_Offset)
   is
      Offset : Stream_Element_Offset := Buffer'First;
      Demand : constant Integer := EVC_Train.Demand;
      Strip_Mode : constant Unsigned_8 :=
        (case Shown_Mode is
            when 1  => 0,   -- SB
            when 7  => 1,   -- SR
            when 2  => 2,   -- FS
            when 11 => 3,   -- TR
            when 3  => 4,   -- AD
            when 8  => 5,   -- SH
            when 4  => 6,   -- SM
            when 17 => 7,   -- IS
            when others => 255);
   begin
      Buffer := (others => 0);
      Put_U32 (Buffer, Offset,
               Unsigned_32 (Natural'Max (0, Position_M)));
      Put_U16 (Buffer, Offset, Unsigned_16 (Natural'Min (Speed_KMH, 65_535)));
      Put_U8 (Buffer, Offset, Strip_Mode);
      Put_U8 (Buffer, Offset, Unsigned_8 (Natural'Min (Shown_Monitoring, 255)));
      Put_U8 (Buffer, Offset,
              (if Demand < 0 then Unsigned_8 (256 + Demand)
               else Unsigned_8 (Demand)));
      Put_U8 (Buffer, Offset,
              (if Sim_Vehicle.Fail_Safe
                 or else (Sim_Vehicle.Commands
                          and (EVC_Ports.TIU_EBC or EVC_Ports.TIU_SBC)) /= 0
               then 1 else 0));
      Last := Offset - 1;
   end Sim_State_Payload;

end Sim_Onboard_Env;
