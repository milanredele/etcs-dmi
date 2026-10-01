--  ETCS on-board (EVC)
--  Core of the ETCS on-board, implementation.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Message;
with ETCS_Telegram;
with ETCS_Variables;
with EVC_Acceptance;
with EVC_DMI_Port; use EVC_DMI_Port;
with EVC_Fixed;
with EVC_Limits;
with EVC_Profiles;
with EVC_Transition_Conditions;
with Interfaces;   use Interfaces;

package body EVC_Core
  with SPARK_Mode => On,
       Refined_State => (State => (Failed_Flag,
                                   Current_Mode,
                                   Cycle_Count,
                                   Clock_Ms,
                                   Reported_Mode,
                                   Latched_Odometer,
                                   Latched_Odometer_Fresh,
                                   Latched_TIU,
                                   Latched_BTM,
                                   Latched_BTM_Count,
                                   Latched_RTM,
                                   Latched_RTM_Count,
                                   Odometer_Now,
                                   Odometer_Fresh,
                                   Geo_Sent,
                                   TIU_Now,
                                   Standstill,
                                   Below_Override,
                                   Accepted_Count,
                                   Rejected_Count,
                                   Overflow_Count,
                                   --  the speed and distance monitoring
                                   Latched_TIU_Value,
                                   Latched_TIU_Known,
                                   Latched_Brake_Ack,
                                   TIU_Value_Now,
                                   TIU_Known_Now,
                                   Brake_Ack_Now,
                                   Test_Snapshot,
                                   Test_Snapshot_Set,
                                   SDM_Work,
                                   SDM_State,
                                   SDM_Result,
                                   Brake_State,
                                   Brake_Output,
                                   Speed_State,
                                   Status_Brake_Sent,
                                   Status_TTI_Sent,
                                   TIU_Sent,
                                   TIU_Reasons_Sent,
                                   Supervision_Reported,
                                   Overrun_Reported,
                                   Entering_FS_Shown))
is

   use type EVC_Bytes.Byte_Array;
   use type EVC_Mission.Data_Status_T;
   use type ETCS_Message.Status_T;
   use type ETCS_Telegram.Status_T;

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   type TIU_Signals_T is array (TIU_Signal_T) of Boolean;
   type Counts_T is array (Port_T) of Natural;

   Failed_Flag          : Boolean := False;
   Current_Mode         : Mode_T := M_NP;
   --  (the level and its status are EVC_Levels', phase E4)
   Cycle_Count          : Cycle_T := 0;
   Clock_Ms             : Time_Ms_T := 0;
   --  The mode last reported to the juridical recording
   Reported_Mode        : Mode_T := M_NP;

   --  Inputs latched by Handle_Input since the last cycle
   Latched_Odometer  : Odometer_Sample_T := Standstill_Sample;
   --  a sample arrived since the last cycle
   Latched_Odometer_Fresh : Boolean := False;
   Latched_TIU       : TIU_Signals_T := (others => False);
   --  (the driver's requests are EVC_Driver_Requests', phase E4)

   --  Telegrams and radio messages latched since the last cycle, as
   --  they arrived: at most the telegrams of one balise group (8,
   --  N_TOTAL of 7.5.1.82) and RTM_Latch_Size messages (an engineering
   --  constant); more are dropped and counted (Overflowed)
   BTM_Latch_Size : constant := 8;
   RTM_Latch_Size : constant := 4;

   type BTM_Slot_T is record
      Length : Natural range 0 .. BTM_Max_Length := 0;
      Data   : EVC_Bytes.Byte_Array (1 .. BTM_Max_Length) := (others => 0);
   end record;
   type BTM_Slots_T is array (1 .. BTM_Latch_Size) of BTM_Slot_T;

   type RTM_Slot_T is record
      Length : Natural range 0 .. RTM_Max_Length := 0;
      Data   : EVC_Bytes.Byte_Array (1 .. RTM_Max_Length) := (others => 0);
   end record;
   type RTM_Slots_T is array (1 .. RTM_Latch_Size) of RTM_Slot_T;

   Latched_BTM       : BTM_Slots_T;
   Latched_BTM_Count : Natural range 0 .. BTM_Latch_Size := 0;
   Latched_RTM       : RTM_Slots_T;
   Latched_RTM_Count : Natural range 0 .. RTM_Latch_Size := 0;

   --  The inputs of the current cycle (Read_Ports)
   Odometer_Now  : Odometer_Sample_T := Standstill_Sample;
   Odometer_Fresh : Boolean := False;
   --  a geographical position was sent to the DMI in the last cycle
   Geo_Sent      : Boolean := False;
   TIU_Now       : TIU_Signals_T := (others => False);

   --  What the position step knows of the movement (Update_Position):
   --  the train stands still, its speed is not above the limit for
   --  triggering the override function
   Standstill     : Boolean := True;
   Below_Override : Boolean := True;

   Accepted_Count : Counts_T := (others => 0);
   Rejected_Count : Counts_T := (others => 0);
   Overflow_Count : Counts_T := (others => 0);

   ---------------------------------------------------------------------
   --  Speed and distance monitoring (phase E3, e3/supervision)
   ---------------------------------------------------------------------

   --  The value bytes of the TIU inputs (the direction controller, the
   --  brake pressure) and which signals were ever received, latched and
   --  of the cycle; the driver's acknowledgement of a brake release
   type TIU_Values_T is array (TIU_Signal_T) of EVC_Bytes.Byte;
   Latched_TIU_Value : TIU_Values_T := (others => 0);
   Latched_TIU_Known : TIU_Signals_T := (others => False);
   Latched_Brake_Ack : Boolean := False;
   TIU_Value_Now     : TIU_Values_T := (others => 0);
   TIU_Known_Now     : TIU_Signals_T := (others => False);
   Brake_Ack_Now     : Boolean := False;

   --  The snapshot of the tests (Set_Snapshot_For_Test): once set, the
   --  speed and distance monitoring reads it in place of the snapshot of
   --  the stored information (EVC_Stored_Information.Current, 3.13.2)
   --  in every cycle until Initialise
   No_Snapshot : constant EVC_Supervision_Input.Snapshot_T :=
     (others => <>);
   Test_Snapshot     : EVC_Supervision_Input.Snapshot_T := No_Snapshot;
   Test_Snapshot_Set : Boolean := False;

   --  EVC_SDM's work area and state, its result; the brake commands
   SDM_Work     : EVC_SDM.Work_T;
   SDM_State    : EVC_SDM.State_T;
   SDM_Result   : EVC_SDM.Result_T;
   Brake_State  : EVC_Brake_Commands.State_T;
   Brake_Output : EVC_Brake_Commands.Commands_T;
   --  MSG_SPEED_STATE of the cycle
   Speed_State  : Speed_State_T;

   --  What was sent last: the brake and TTI of MSG_STATUS, the TIU
   --  output, the monitoring / status / MRDT and the overruns recorded
   --  on the JRU
   Status_Brake_Sent    : EVC_Bytes.Byte := Brake_None;
   Status_TTI_Sent      : Unsigned_16 := TTI_None;
   TIU_Sent             : EVC_Bytes.Byte := 0;
   TIU_Reasons_Sent     : EVC_Bytes.Byte := 0;
   No_Supervision       : constant Unsigned_32 := 16#FFFF_FFFF#;
   Supervision_Reported : Unsigned_32 := No_Supervision;
   Overrun_Reported     : EVC_Bytes.Byte := 0;
   --  phase E4: the indication "Entering FS" (4.4.9.1.4) is shown
   Entering_FS_Shown    : Boolean := False;

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Mode return Mode_T is (Current_Mode);
   function Level_Status return Level_Status_T is (EVC_Levels.Status);
   function Level return Level_T is (EVC_Levels.Level);
   function Failed return Boolean is (Failed_Flag);
   function Cycle return Cycle_T is (Cycle_Count);
   function Time_Ms return Time_Ms_T is (Clock_Ms);
   function Isolation_Requested return Boolean is
     (EVC_Driver_Requests.Isolation_Latched);
   function Accepted (Port : Port_T) return Natural is
     (Accepted_Count (Port));
   function Rejected (Port : Port_T) return Natural is
     (Rejected_Count (Port));
   function Overflowed (Port : Port_T) return Natural is
     (Overflow_Count (Port));
   function Configured return Boolean is (EVC_Config.Loaded);
   function Configuration return EVC_Config.Config_T is
     (EVC_Config.Current);
   function Supervision return EVC_SDM.Result_T is (SDM_Result);
   function Brake_Commands return EVC_Brake_Commands.Commands_T is
     (Brake_Output);

   ---------------------------
   -- Set_Snapshot_For_Test --
   ---------------------------

   procedure Set_Snapshot_For_Test (S : EVC_Supervision_Input.Snapshot_T) is
   begin
      Test_Snapshot := S;
      Test_Snapshot_Set := True;
   end Set_Snapshot_For_Test;

   -----------------------
   -- Set_Mode_For_Test --
   -----------------------

   procedure Set_Mode_For_Test (Mode : Mode_T; Level : Level_T) is
   begin
      Current_Mode := Mode;
      EVC_Levels.Set_For_Test (Level);
      EVC_Train_Data.Set (EVC_Train_Data.Default,
                          EVC_Train_Data.Default_Categories);
   end Set_Mode_For_Test;

   procedure Count (Counter : in out Natural) is
   begin
      if Counter < Natural'Last then
         Counter := Counter + 1;
      end if;
   end Count;

   ----------------
   -- Initialise --
   ----------------

   procedure Initialise is
   begin
      Failed_Flag := False;
      --  SUBSET-026 4.4.4.1.1: the equipment is in No Power until it is
      --  powered; the first cycle takes the transition NP -> SB
      Current_Mode := M_NP;
      --  5.4.3.2 D2: nothing is stored over No Power, the level is
      --  "unknown" and the start of mission asks the driver for it
      --  (EVC_Levels.Clear below)
      Cycle_Count := 0;
      Clock_Ms := 0;
      Reported_Mode := M_NP;
      Latched_Odometer := Standstill_Sample;
      Latched_Odometer_Fresh := False;
      Latched_TIU := (others => False);
      Latched_BTM := (others => (Length => 0, Data => (others => 0)));
      Latched_BTM_Count := 0;
      Latched_RTM := (others => (Length => 0, Data => (others => 0)));
      Latched_RTM_Count := 0;
      Odometer_Now := Standstill_Sample;
      Odometer_Fresh := False;
      Geo_Sent := False;
      TIU_Now := (others => False);
      Standstill := True;
      Below_Override := True;
      Accepted_Count := (others => 0);
      Rejected_Count := (others => 0);
      Overflow_Count := (others => 0);
      Latched_TIU_Value := (others => 0);
      Latched_TIU_Known := (others => False);
      Latched_Brake_Ack := False;
      TIU_Value_Now := (others => 0);
      TIU_Known_Now := (others => False);
      Brake_Ack_Now := False;
      Test_Snapshot := No_Snapshot;
      Test_Snapshot_Set := False;
      SDM_Work := (others => <>);
      SDM_State := (others => <>);
      SDM_Result := (others => <>);
      Brake_State := (others => <>);
      Brake_Output := (others => <>);
      Speed_State := (others => <>);
      Status_Brake_Sent := Brake_None;
      Status_TTI_Sent := TTI_None;
      TIU_Sent := 0;
      TIU_Reasons_Sent := 0;
      Supervision_Reported := No_Supervision;
      Overrun_Reported := 0;
      Entering_FS_Shown := False;
      EVC_Received.Clear;
      EVC_Position.Clear;
      --  the installation: the antenna of the configuration
      EVC_Position.Set_Antenna (EVC_Config.Current.Antenna_To_Cab_A,
                                EVC_Config.Current.Antenna_To_Cab_B);
      --  phase E3: nothing stored (phase E4: no valid Train Data)
      EVC_Stored_Information.Clear;
      --  phase E4: no request, no input, the level and the mission data
      --  unknown
      EVC_Driver_Requests.Clear;
      EVC_Train_Inputs.Clear;
      EVC_Levels.Clear;
      EVC_Mission.Clear;
      EVC_Outbox.Clear;
   end Initialise;

   ---------------
   -- Configure --
   ---------------

   procedure Configure (Bytes : EVC_Bytes.Byte_Array) is
   begin
      if Current_Mode = M_NP then
         EVC_Config.Load (Bytes);
      else
         EVC_Config.Refuse (EVC_Config.Refused_In_Service);
      end if;
      EVC_Position.Set_Antenna (EVC_Config.Current.Antenna_To_Cab_A,
                                EVC_Config.Current.Antenna_To_Cab_B);
   end Configure;

   ------------------
   -- Handle_Input --
   ------------------

   procedure Handle_Input (Port : Port_T; Payload : EVC_Bytes.Byte_Array) is
   begin
      if Failed_Flag then
         return;
      end if;
      if not Valid_Input (Port, Payload) then
         Count (Rejected_Count (Port));
         return;
      end if;
      Count (Accepted_Count (Port));
      case Port is
         when Odometer =>
            --  the latest sample of the cycle is the one that counts
            Latched_Odometer := To_Odometer (Payload);
            Latched_Odometer_Fresh := True;
         when TIU =>
            declare
               Input : constant TIU_Input_T := To_TIU (Payload);
            begin
               Latched_TIU (Input.Signal) := Input.Value;
               Latched_TIU_Value (Input.Signal) := TIU_Value (Payload);
               Latched_TIU_Known (Input.Signal) := True;
            end;
         when DMI =>
            --  phase E4: the driver's actions and data, decoded
            --  (EVC_Driver_Requests; the isolation, 4.6.3 condition [1],
            --  among them)
            EVC_Driver_Requests.Receive (Payload);
            --  3.14.1.5: the release of a brake acknowledged
            if Is_Brake_Release_Ack (Payload) then
               Latched_Brake_Ack := True;
            end if;
         when BTM =>
            --  parsed when the ports are read, at the next cycle
            if Latched_BTM_Count < BTM_Latch_Size then
               Latched_BTM_Count := Latched_BTM_Count + 1;
               Latched_BTM (Latched_BTM_Count).Length := Payload'Length;
               Latched_BTM (Latched_BTM_Count).Data (1 .. Payload'Length) :=
                 Payload;
            else
               Count (Overflow_Count (BTM));
            end if;
         when RTM =>
            if Latched_RTM_Count < RTM_Latch_Size then
               Latched_RTM_Count := Latched_RTM_Count + 1;
               Latched_RTM (Latched_RTM_Count).Length := Payload'Length;
               Latched_RTM (Latched_RTM_Count).Data (1 .. Payload'Length) :=
                 Payload;
            else
               Count (Overflow_Count (RTM));
            end if;
         when ATO | JRU =>
            --  no input is valid on these ports (EVC_Ports.Valid_Input)
            null;
      end case;
   end Handle_Input;

   ---------------------------------------------------------------------
   --  The steps of one cycle (doc/EVC-PLAN.md §2), in their order
   ---------------------------------------------------------------------

   --  A record for the juridical recording (EVC_Ports): Event, three
   --  bytes that depend on it, the cycle and the on-board time
   function JRU_Record (Event, B2, B3, B4 : EVC_Bytes.Byte)
     return EVC_Bytes.Byte_Array
   is (Event, B2, B3, B4,
       EVC_Bytes.Byte_Of (Unsigned_64 (Cycle_Count), 0),
       EVC_Bytes.Byte_Of (Unsigned_64 (Cycle_Count), 1),
       EVC_Bytes.Byte_Of (Unsigned_64 (Cycle_Count), 2),
       EVC_Bytes.Byte_Of (Unsigned_64 (Cycle_Count), 3),
       EVC_Bytes.Byte_Of (Unsigned_64 (Clock_Ms), 0),
       EVC_Bytes.Byte_Of (Unsigned_64 (Clock_Ms), 1),
       EVC_Bytes.Byte_Of (Unsigned_64 (Clock_Ms), 2),
       EVC_Bytes.Byte_Of (Unsigned_64 (Clock_Ms), 3),
       EVC_Bytes.Byte_Of (Unsigned_64 (Clock_Ms), 4),
       EVC_Bytes.Byte_Of (Unsigned_64 (Clock_Ms), 5),
       EVC_Bytes.Byte_Of (Unsigned_64 (Clock_Ms), 6),
       EVC_Bytes.Byte_Of (Unsigned_64 (Clock_Ms), 7))
     with Global => (Cycle_Count, Clock_Ms),
          Post => JRU_Record'Result'Length = JRU_Record_Length;

   JRU_Mode_Change : constant := 1;
   JRU_Telegram    : constant := 2;
   JRU_Message     : constant := 3;
   --  the events of the position: 4 .. 10 (EVC_Ports)
   JRU_Position    : constant := 4;

   --  0. The installation configuration loaded or refused since the last
   --  cycle (Configure): event 33 (EVC_Ports)
   procedure Report_Configuration
     with Global => (Input  => (Cycle_Count, Clock_Ms),
                     In_Out => (EVC_Config.State, EVC_Outbox.Queue)),
          Post => EVC_Config.Current = EVC_Config.Current'Old
                  and then EVC_Config.Loaded = EVC_Config.Loaded'Old
   is
      Loaded : constant Boolean :=
        EVC_Config.Last_Status = EVC_Config.Accepted;
   begin
      if EVC_Config.Report_Pending then
         EVC_Outbox.Put
           (JRU, JRU_Record
                   (JRU_Configuration,
                    (if Loaded then 1 else 2),
                    EVC_Config.Status_T'Pos (EVC_Config.Last_Status),
                    EVC_Bytes.Byte
                      (Natural'Min (EVC_Config.Rejections, 255))));
         EVC_Config.Report_Taken;
      end if;
   end Report_Configuration;

   --  1. Read the ports: take the inputs latched since the last cycle,
   --  parse the telegrams and radio messages (EVC_Received) and record
   --  those accepted on the JRU port; hand the telegrams accepted, with
   --  the stamp of their balise, to the position
   procedure Read_Ports
     with Global => (Input  => (Latched_Odometer, Latched_TIU, Latched_BTM,
                                Latched_RTM, Cycle_Count, Clock_Ms,
                                EVC_Odometry.State, Latched_TIU_Value,
                                Latched_TIU_Known),
                     Output => (Odometer_Now, Odometer_Fresh, TIU_Now,
                                TIU_Value_Now,
                                TIU_Known_Now, Brake_Ack_Now,
                                EVC_Train_Inputs.State),
                     In_Out => (Latched_Odometer_Fresh,
                                Latched_Brake_Ack,
                                Latched_BTM_Count,
                                Latched_RTM_Count, EVC_Received.Store,
                                EVC_Outbox.Queue, EVC_Position.State,
                                EVC_Driver_Requests.State,
                                EVC_Levels.State)),
          Post => EVC_Driver_Requests.Isolation_Selected
                    = EVC_Driver_Requests.Isolation_Latched'Old
                  and then not EVC_Driver_Requests.Isolation_Latched
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old
   is
      T_Status : ETCS_Telegram.Status_T;
      M_Status : ETCS_Message.Status_T;
      --  what the telegrams do not change (the position takes them at
      --  its next Update)
      LRBG_0        : constant EVC_Location.Anchor_T := EVC_Position.LRBG
        with Ghost;
      Orientation_0 : constant EVC_Distances.Sense_T :=
        EVC_Position.Orientation
        with Ghost;
      Over_0        : constant EVC_Distances.Length_T :=
        EVC_Position.Doubt_Over
        with Ghost;
      Under_0       : constant EVC_Distances.Length_T :=
        EVC_Position.Doubt_Under
        with Ghost;
   begin
      Odometer_Now := Latched_Odometer;
      Odometer_Fresh := Latched_Odometer_Fresh;
      Latched_Odometer_Fresh := False;
      TIU_Now := Latched_TIU;
      TIU_Value_Now := Latched_TIU_Value;
      TIU_Known_Now := Latched_TIU_Known;
      Brake_Ack_Now := Latched_Brake_Ack;
      Latched_Brake_Ack := False;
      --  phase E4: the driver's requests and the inputs of the train
      --  interface of the cycle; nothing switched the level yet
      EVC_Driver_Requests.Take;
      EVC_Train_Inputs.Set
        (Cab_A            => TIU_Now (Cab_A_Active),
         Cab_B            => TIU_Now (Cab_B_Active),
         Sleeping         => TIU_Now (Sleeping_Requested),
         Passive_Shunting => TIU_Now (Passive_Shunting_Permitted),
         Non_Leading      => TIU_Now (Non_Leading_Permitted));
      EVC_Levels.Begin_Cycle;

      --  the telegrams in the order the BTM delivered them
      for I in 1 .. Latched_BTM_Count loop
         pragma Loop_Invariant
           (EVC_Position.LRBG = LRBG_0
            and then EVC_Position.Orientation = Orientation_0
            and then EVC_Position.Doubt_Over = Over_0
            and then EVC_Position.Doubt_Under = Under_0);
         declare
            Slot : BTM_Slot_T renames Latched_BTM (I);
         begin
            if Valid_BTM_Input (Slot.Data (1 .. Slot.Length)) then
               EVC_Received.Receive_Telegram
                 (BTM_Telegram (Slot.Data (1 .. Slot.Length)), T_Status);
               if T_Status = ETCS_Telegram.Accepted then
                  --  the balise group, NID_C and NID_BG (24 bits)
                  declare
                     H  : constant ETCS_Telegram.Header_T :=
                       EVC_Received.Last_Telegram.Header;
                     Id : constant Unsigned_64 :=
                       ETCS_Variables.Balise_Group_Identity
                         (H.NID_C, H.NID_BG);
                  begin
                     EVC_Outbox.Put
                       (JRU, JRU_Record (JRU_Telegram,
                                         EVC_Bytes.Byte_Of (Id, 0),
                                         EVC_Bytes.Byte_Of (Id, 1),
                                         EVC_Bytes.Byte_Of (Id, 2)));
                  end;
                  EVC_Position.Receive_Telegram
                    (EVC_Received.Last_Telegram,
                     BTM_Stamp (Slot.Data (1 .. Slot.Length)));
               end if;
            end if;
         end;
      end loop;
      Latched_BTM_Count := 0;

      --  the radio messages in the order the RTM delivered them
      for I in 1 .. Latched_RTM_Count loop
         declare
            Slot : RTM_Slot_T renames Latched_RTM (I);
         begin
            if Valid_RTM (Slot.Data (1 .. Slot.Length)) then
               EVC_Received.Receive_Message
                 (Slot.Data (1 .. Slot.Length), M_Status);
               if M_Status = ETCS_Message.Accepted then
                  --  NID_MESSAGE, L_MESSAGE (u16)
                  EVC_Outbox.Put
                    (JRU, JRU_Record (JRU_Message,
                                      Slot.Data (1),
                                      EVC_Bytes.Byte (Slot.Length mod 256),
                                      EVC_Bytes.Byte (Slot.Length / 256)));
               end if;
            end if;
         end;
      end loop;
      Latched_RTM_Count := 0;
   end Read_Ports;

   --  4.8 (phase E4): the context of the filters in the cycle, for the
   --  information the position takes itself (the linking)
   function Acceptance_Context return EVC_Acceptance.Context_T is
     ((Mode             => Current_Mode,
       Level_Valid      => EVC_Levels.Valid,
       Level            => EVC_Levels.Level,
       Cab_Active       => EVC_Train_Inputs.Desk_Open,
       Train_Data_Valid => EVC_Train_Data.Valid,
       TRN_Valid        => EVC_Mission.TRN_Status = EVC_Mission.Valid,
       L1_Announced     => EVC_Levels.L1_Announced,
       Order_In_Message => False,
       Order_Pending    => EVC_Levels.Order_Pending,
       Unlinked_Group   => False))
     with Global => (Current_Mode, EVC_Levels.State, EVC_Train_Inputs.State,
                     EVC_Train_Data.State, EVC_Mission.State);

   --  2. Update the position (EVC_Position): the cab status, the
   --  telegrams of the cycle, the odometer sample; its events go to the
   --  JRU. E0's standstill and override speed come from the sample.
   procedure Update_Position
     with Global => (Input  => (Odometer_Now, Odometer_Fresh, TIU_Now,
                                EVC_National_Values.State, Current_Mode,
                                EVC_Levels.State, Cycle_Count, Clock_Ms,
                                EVC_Train_Inputs.State, EVC_Mission.State,
                                EVC_Train_Data.State),
                     Output => (Standstill, Below_Override),
                     In_Out => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Origins.State, EVC_Outbox.Queue)),
          Post =>
            (if EVC_Position.Orientation /= EVC_Position.Orientation'Old
             then EVC_Position.Active_Cab
                    = (if EVC_Position.Orientation = EVC_Distances.Plus
                       then EVC_Position.Cab_A else EVC_Position.Cab_B))
            and then
            (if EVC_Position.LRBG = EVC_Position.LRBG'Old
               and then EVC_Position.Orientation
                          = EVC_Position.Orientation'Old
             then EVC_Position.Doubt_Over >= EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             >= EVC_Position.Doubt_Under'Old)
   is
   begin
      --  phase E4: the linking accepted by 4.8 and checked in the modes
      --  of 4.5.2 (3.4.4.2.1.1 b)
      EVC_Position.Set_Linking_Context
        (Accept_Info => EVC_Acceptance.Accepted
                          (EVC_Acceptance.Linking, Acceptance_Context),
         Check       => Linking_Check_Mode (Current_Mode));
      EVC_Position.Update
        (Cab_A_Active => TIU_Now (Cab_A_Active),
         Cab_B_Active => TIU_Now (Cab_B_Active),
         Sampled      => Odometer_Fresh,
         Sample       => Odometer_Now,
         Mode         => Current_Mode,
         Level        => EVC_Levels.Level,
         Now_Ms       => Unsigned_64 (Clock_Ms));
      for I in 1 .. EVC_Position.Event_Count loop
         declare
            E : constant EVC_Position.Event_T := EVC_Position.Event (I);
         begin
            EVC_Outbox.Put
              (JRU, JRU_Record (JRU_Position
                                  + EVC_Position.Event_Kind_T'Pos (E.Kind),
                                E.B2, E.B3, E.B4));
         end;
      end loop;
      Standstill := Odometer_Now.V_Max = 0;
      Below_Override :=
        Natural (Odometer_Now.V_Max) <= EVC_National_Values.V_NVALLOWOVTRP;
   end Update_Position;

   --  3. Evaluate the stored information (EVC_Stored_Information, phase
   --  E3): the information of the groups taken into account, its
   --  replacement and deletion, the timers of the MA, the snapshot for
   --  the supervision; its records go to the JRU, the indications of the
   --  track conditions (MSG_TRACK_COND, when they change) and the
   --  planning (MSG_PLANNING, while an MA is supervised) to the DMI. The
   --  data status changes of 4.10 on a mode transition are phase E4.
   JRU_Stored : constant := EVC_Stored_Information.JRU_Event;

   --  The mode related speed restriction (3.11.7) of the modes of this
   --  half, from the national values (A.3.2, packet 3): the SR mode speed
   --  limit (the driver's or V_NVSTFF, EVC_Mission), V_NVSHUNT,
   --  V_NVONSIGHT, V_NVLIMSUPERV, V_NVUNFIT. The speeds a mode profile or
   --  the reversing supervision information give, and the override
   --  related speed of 3.11.10, are the procedures half's
   --  (EVC_Procedures.Mode_Speed, e4/procedures), which replaces this at
   --  the merge.
   function Mode_Speed return EVC_Supervision_Input.Speed_Cms_T is
     (case Current_Mode is
         when M_SR => EVC_Mission.SR_Speed,
         when M_SH => EVC_National_Values.Current.Values.V_NVSHUNT,
         when M_OS => EVC_National_Values.Current.Values.V_NVONSIGHT,
         when M_LS => EVC_National_Values.Current.Values.V_NVLIMSUPERV,
         when M_UN => EVC_National_Values.Current.Values.V_NVUNFIT,
         when others => EVC_Supervision_Input.No_Speed_Limit)
     with Global => (Current_Mode, EVC_Mission.State,
                     EVC_National_Values.State);

   --  4.4.11.1.3 b): the end of the SR distance, a frame position along
   --  the train orientation (the virtual position of 3.6.7)
   function SR_End return EVC_Distances.Dist_T is
     (EVC_Distances.Advance
        (EVC_Position.Front_X, EVC_Position.Orientation,
         EVC_Odometry.Remaining_Estimated (EVC_Mission.SR_Distance)))
     with Global => (EVC_Position.State, EVC_Odometry.State,
                     EVC_Mission.State);

   procedure Evaluate_Stored_Information
     with Global => (Input  => (Clock_Ms, Cycle_Count, EVC_Position.State,
                                EVC_Odometry.State, EVC_Train_Data.State,
                                TIU_Now, EVC_Config.State, Current_Mode,
                                EVC_Train_Inputs.State, EVC_Mission.State),
                     In_Out => (EVC_Stored_Information.State,
                                EVC_Origins.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                EVC_Levels.State,
                                EVC_Outbox.Queue))
   is
      Frame : EVC_DMI_Port.Frame_Buffer_T;
      Last  : Natural;
   begin
      --  the mode related speed restriction (3.11.7, Mode_Speed); the
      --  status of the special brakes for the speed restrictions to
      --  ensure a permitted braking distance (3.11.11.4); the mode and
      --  the inputs of 4.8 and the SR distance (phase E4)
      EVC_Stored_Information.Evaluate
        (Unsigned_64 (Clock_Ms),
         Mode_Speed,
         Special_Active =>
           (EVC_Supervision_Input.Regenerative =>
              TIU_Now (Regenerative_Brake_Active),
            EVC_Supervision_Input.Eddy_Current =>
              TIU_Now (Eddy_Current_Brake_Active),
            EVC_Supervision_Input.Magnetic_Shoe =>
              TIU_Now (Magnetic_Shoe_Brake_Active),
            EVC_Supervision_Input.Electro_Pneumatic =>
              TIU_Now (EP_Brake_Active)),
         Additional     => TIU_Now (Additional_Brake_Active),
         Context        =>
           (Mode        => Current_Mode,
            Cab_Active  => EVC_Train_Inputs.Desk_Open,
            TRN_Valid   => EVC_Mission.TRN_Status = EVC_Mission.Valid,
            SR_Distance => Current_Mode = M_SR
                           and then EVC_Mission.SR_Distance.Active,
            SR_End      => SR_End));
      for I in 1 .. EVC_Stored_Information.Event_Count loop
         declare
            E : constant EVC_Stored_Information.Event_T :=
              EVC_Stored_Information.Event (I);
         begin
            EVC_Outbox.Put (JRU, JRU_Record (JRU_Stored, E.Info, E.Change,
                                             E.Detail));
         end;
      end loop;
      if EVC_Stored_Information.Track_Cond_Due then
         Track_Cond_Frame (EVC_Stored_Information.Track_Cond_Count,
                           EVC_Stored_Information.Track_Cond_List,
                           Frame, Last);
         EVC_Outbox.Put (DMI, Frame (1 .. Last));
      end if;
      if EVC_Stored_Information.Planning_Due then
         Planning_Frame (EVC_Stored_Information.Planning, Frame, Last);
         if Last <= DMI_Max_Length then
            EVC_Outbox.Put (DMI, Frame (1 .. Last));
         end if;
      end if;
   end Evaluate_Stored_Information;

   --  MSG_SPEED_STATE from the result of the speed and distance
   --  monitoring (dmi_protocol.ads: the DMI derives nothing): speeds in
   --  km/h to the nearest, the distance in m rounded down; the dial range
   --  (DMI 8.2.1.1.3, pre-configured on-board) the smallest that shows
   --  the ceiling EBI of the maximum train speed, 180 km/h without train
   --  data
   function To_Speed_State (S : EVC_Supervision_Input.Snapshot_T;
                            R : EVC_SDM.Result_T) return Speed_State_T
   is
      use EVC_Fixed;

      function Kmh (V : Speed_T) return Unsigned_16 is
        (Unsigned_16 (Min (Cms_To_Kmh (V), 65_535)));

      V_Max : constant Speed_T := Speed_T (S.Train_Data.Max_Speed);
      Top   : constant Num :=
        V_Max + EVC_Limits.Margin (EVC_Limits.EBI, V_Max);
      Dial  : constant EVC_Bytes.Byte :=
        (if V_Max = 0 then 1
         elsif Top * 36 <= 140_000 then 0
         elsif Top * 36 <= 180_000 then 1
         elsif Top * 36 <= 250_000 then 2
         else 3);
   begin
      return (V_Cur      => Kmh (R.V_Est),
              V_Perm     => Kmh (R.V_Perm),
              V_Target   => Kmh (R.V_Target),
              V_Release  => Kmh (R.V_Release),
              V_SBI      => Kmh (R.V_SBI),
              V_Wsl      => Kmh (R.V_Warning),
              D_Target   => Unsigned_32 (Min (Max (R.D_Target, 0) / 100,
                                              2**32 - 1)),
              Monitoring => EVC_SDM.Monitoring_T'Pos (R.Monitoring),
              Dial_Range => Dial,
              Flags      => (if R.Release_Shown then Flag_Release_Shown
                             else 0)
                            or (if R.CSM_Target then Flag_CSM_Target
                                else 0),
              Status     => EVC_SDM.Status_T'Pos (R.Status),
              MRDT       => EVC_Bytes.Byte (R.MRDT_Id));
   end To_Speed_State;

   --  4. Speed and distance monitoring (3.13, EVC_SDM) and the brake
   --  commands (3.14, EVC_Brake_Commands) on the snapshot the stored
   --  information built at the third step (or the tests' one), with the
   --  inputs of the train interface and the driver's acknowledgement of
   --  the cycle
   procedure Monitor_Speed_And_Distance (Dt_Ms : Natural)
     with Global => (Input  => (Test_Snapshot, Test_Snapshot_Set, TIU_Now,
                                TIU_Value_Now, TIU_Known_Now, Brake_Ack_Now,
                                Current_Mode, EVC_Levels.State,
                                EVC_Position.State,
                                EVC_Stored_Information.State),
                     In_Out => (SDM_Work, SDM_State, Brake_State),
                     Output => (SDM_Result, Brake_Output, Speed_State))
   is
      procedure Run (S : EVC_Supervision_Input.Snapshot_T) is
         Controller : constant EVC_Brake_Commands.Controller_T :=
           (if not TIU_Known_Now (Direction_Controller)
            then EVC_Brake_Commands.Unknown
            else (case TIU_Value_Now (Direction_Controller) is
                     when 1      => EVC_Brake_Commands.Forwards,
                     when 2      => EVC_Brake_Commands.Backwards,
                     when others => EVC_Brake_Commands.Neutral));
         Inputs : constant EVC_SDM.Inputs_T :=
           (Dt_Ms          => Dt_Ms,
            Special_Active =>
              (EVC_Supervision_Input.Regenerative =>
                 TIU_Now (Regenerative_Brake_Active),
               EVC_Supervision_Input.Eddy_Current =>
                 TIU_Now (Eddy_Current_Brake_Active),
               EVC_Supervision_Input.Magnetic_Shoe =>
                 TIU_Now (Magnetic_Shoe_Brake_Active),
               EVC_Supervision_Input.Electro_Pneumatic =>
                 TIU_Now (EP_Brake_Active)),
            Additional     => TIU_Now (Additional_Brake_Active),
            Pressure_Known => TIU_Known_Now (Brake_Pressure),
            Pressure       => Natural (TIU_Value_Now (Brake_Pressure)) * 4,
            Level_1        => EVC_Levels.Valid
                              and then EVC_Levels.Level = L1,
            Antenna_Offset =>
              Natural (EVC_Position.Front_Offset
                         (EVC_Position.Orientation)));
      begin
         EVC_SDM.Step (S, Inputs, SDM_Work, SDM_State, SDM_Result);
         EVC_Brake_Commands.Step
           (S, SDM_Result,
            (Mode       => Current_Mode,
             Controller => Controller,
             Ack        => Brake_Ack_Now,
             Dt_Ms      => Dt_Ms,
             A_Est      => SDM_State.A_Est,
             T_Bs       => SDM_Work.Model.Service_Target.Build_Up),
            Brake_State, Brake_Output);
         Speed_State := To_Speed_State (S, SDM_Result);
      end Run;
   begin
      if Test_Snapshot_Set then
         Run (Test_Snapshot);
      else
         Run (EVC_Stored_Information.Current);
      end if;
   end Monitor_Speed_And_Distance;

   --  5. The modes and the levels (phase E4): the level transitions and
   --  the driver's level (EVC_Levels, 5.10), the mission data, the start
   --  of mission and the mode proposed to the driver (EVC_Mission, 5.4),
   --  on the requests of the cycle; the desk closed during the start of
   --  mission (A.3.4.1.2 k)
   procedure Evaluate_Modes_And_Levels
     with Global => (Input  => (Current_Mode, Clock_Ms,
                                EVC_Driver_Requests.State,
                                EVC_Train_Inputs.State,
                                EVC_Odometry.State, EVC_Origins.State,
                                EVC_Config.State),
                     In_Out => (EVC_Levels.State, EVC_Mission.State,
                                EVC_National_Values.State,
                                EVC_Train_Data.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_Position.State,
                                EVC_Stored_Information.State)),
          Post => EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old
   is
      Solr  : constant EVC_Location.Anchor_T := EVC_Position.SOLR;
      Valid : constant Boolean :=
        EVC_Position.Status = EVC_Position.Valid and then Solr.Valid;
      NV    : constant EVC_Supervision_Input.National_Values_T :=
        EVC_National_Values.Current.Values;
   begin
      EVC_Levels.Evaluate
        (T            => EVC_Profiles.Origin_Table,
         C            =>
           (Mode           => Current_Mode,
            Standstill     => EVC_Odometry.Standstill,
            Position_Valid => Valid,
            Est_Front      => EVC_Position.Front_X,
            Max_Front      =>
              (if Valid
               then EVC_Distances.Advance
                      (Solr.X, EVC_Position.Orientation,
                       EVC_Position.SOLR_Max_Safe_Front)
               else EVC_Position.Front_X),
            Now_Ms         => Unsigned_64 (Clock_Ms)),
         Driver_Level => EVC_Driver_Requests.Level_Selected,
         Code         => EVC_Driver_Requests.Selected_Level_Code,
         Ack          => EVC_Driver_Requests.Level_Acknowledged);
      EVC_Mission.Evaluate
        ((Mode        => Current_Mode,
          Level_Valid => EVC_Levels.Valid,
          Level       => EVC_Levels.Level,
          Standstill  => EVC_Odometry.Standstill,
          Desk_Open   => EVC_Train_Inputs.Desk_Open,
          Non_Leading => EVC_Train_Inputs.Non_Leading_Permitted,
          Sense       => EVC_Position.Orientation,
          V_NVSTFF    => NV.V_NVSTFF,
          D_NVSTFF    => NV.D_NVSTFF));
      --  A.3.4.1.2 k), column k: what entering SB has not deleted
      --  already (the TSRs, the adhesion, the big metal masses, the level
      --  transition orders, the national values not yet applicable); the
      --  Train Data, the driver ID and the train running number are to be
      --  revalidated (EVC_Mission)
      if EVC_Mission.Desk_Closed_In_SoM then
         EVC_National_Values.Delete_Pending;
         EVC_Track_Description.Delete
           ((Track       => True,
             PBD         => True,
             Suitability => True,
             TSR         => True,
             Adhesion    => True));
         EVC_Movement_Authority.Delete_MA;
         EVC_Track_Conditions.Reset (Rest => True, Horn => True,
                                     BMM => True);
         EVC_Position.Delete_Linking;
         EVC_Stored_Information.Set_Driver_Slippery (False);
         EVC_Levels.Delete_Orders;
      end if;
   end Evaluate_Modes_And_Levels;

   --  Any condition of the list L holds (4.6.1.6: "16, 17, 18" means "16
   --  or 17 or 18")
   function Any_Holds (L : Condition_List_T) return Boolean is
     (for some I in L'Range =>
        L (I) /= 0 and then EVC_Transition_Conditions.Holds (L (I)))
     with Global => (EVC_Driver_Requests.State, EVC_Train_Inputs.State,
                     EVC_Levels.State, EVC_Mission.State,
                     EVC_Odometry.State, EVC_Stored_Information.State,
                     EVC_Movement_Authority.State, EVC_Train_Data.State);

   --  6. Mode machine: of the transitions of 4.6.2 whose condition of
   --  4.6.3 holds (EVC_Modes.Conditions, EVC_Transition_Conditions), the
   --  one of the highest priority (4.6.1.4; of two of the same priority,
   --  which 4.6.1.5 says cannot hold together, the first in the order of
   --  Mode_T). The transition to NP is not looked at: while this code
   --  runs the on-board is powered and [29] does not hold.
   procedure Run_Mode_Machine
     with Global => (Input  => (EVC_Driver_Requests.State,
                                EVC_Train_Inputs.State,
                                EVC_Levels.State, EVC_Mission.State,
                                EVC_Odometry.State,
                                EVC_Stored_Information.State,
                                EVC_Movement_Authority.State,
                                EVC_Train_Data.State),
                     In_Out => Current_Mode),
          Post => (Current_Mode = Current_Mode'Old
                   or else Transition_Exists
                             (Current_Mode'Old, Current_Mode))
                  and then Current_Mode /= M_NP
                  and then (if Current_Mode'Old = M_IS
                            then Current_Mode = M_IS)
                  and then (if Current_Mode'Old = M_NP
                            then Current_Mode =
                                   (if EVC_Driver_Requests.Isolation_Selected
                                    then M_IS else M_SB))
   is
      From          : constant Mode_T := Current_Mode;
      Best          : Mode_T := From;
      Best_Priority : Priority_T := No_Transition;
   begin
      for To in Mode_T loop
         if To /= M_NP
           and then Transitions (From, To) /= No_Transition
           and then (Best_Priority = No_Transition
                     or else Transitions (From, To) < Best_Priority)
           and then Any_Holds (Conditions (From, To))
         then
            Best := To;
            Best_Priority := Transitions (From, To);
         end if;
         pragma Loop_Invariant
           (if Best_Priority = No_Transition
            then Best = From
            else Transitions (From, Best) = Best_Priority
                 and then Best /= M_NP);
         pragma Loop_Invariant
           (if From = M_NP and then To >= M_SB
            then Best_Priority /= No_Transition);
         pragma Loop_Invariant
           (if From = M_NP and then Best_Priority /= No_Transition
            then Best = (if EVC_Driver_Requests.Isolation_Selected
                           and then To >= M_IS
                         then M_IS else M_SB));
      end loop;
      Current_Mode := Best;
   end Run_Mode_Machine;

   --  7. What entering the mode To from From means (phase E4): the data
   --  of 4.10 (the stores, the position, the level, the mission), the
   --  brake command reasons of 4.12 (the speed and distance monitoring,
   --  the protections; the levels' own, EVC_Levels), the end and the
   --  start of mission (5.5.2, 5.4.6)
   procedure Enter_Mode (From, To : Mode_T)
     with Global => (Input  => (EVC_Odometry.State,
                                EVC_National_Values.State,
                                EVC_Train_Inputs.State),
                     In_Out => (EVC_Levels.State, EVC_Mission.State,
                                EVC_Train_Data.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_Position.State,
                                EVC_Stored_Information.State,
                                Brake_State, SDM_State)),
          Post => EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old
   is
      NV : constant EVC_Supervision_Input.National_Values_T :=
        EVC_National_Values.Current.Values;
   begin
      EVC_Levels.Mode_Entered (From, To);
      EVC_Mission.Mode_Entered
        (From, To,
         (Mode        => To,
          Level_Valid => EVC_Levels.Valid,
          Level       => EVC_Levels.Level,
          Standstill  => EVC_Odometry.Standstill,
          Desk_Open   => EVC_Train_Inputs.Desk_Open,
          Non_Leading => EVC_Train_Inputs.Non_Leading_Permitted,
          Sense       => EVC_Position.Orientation,
          V_NVSTFF    => NV.V_NVSTFF,
          D_NVSTFF    => NV.D_NVSTFF));

      --  4.10: the stored information, each with the modes of its row
      EVC_Track_Description.Delete
        ((Track       => To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL
                             | M_NL | M_UN | M_TR | M_SN | M_RV,
          PBD         => To in M_NP | M_SB | M_PS | M_SH | M_SM | M_SR
                             | M_SL | M_NL | M_UN | M_TR | M_SN | M_RV,
          Suitability => To in M_NP | M_SB | M_PS | M_SH | M_SM | M_SR
                             | M_SL | M_NL | M_UN | M_TR | M_SN | M_RV,
          TSR         => To in M_NP | M_SB | M_PS | M_SH | M_SL | M_NL
                             | M_SN | M_RV,
          Adhesion    => To in M_NP | M_SB | M_PS | M_SH | M_SL | M_NL
                             | M_SN));
      --  the MA, the mode profile, the signalling related speed
      --  restriction
      if To in M_NP | M_SB | M_PS | M_SH | M_SM | M_SR | M_SL | M_NL
             | M_UN | M_TR | M_SN | M_RV
      then
         EVC_Movement_Authority.Delete_MA;
      end if;
      EVC_Track_Conditions.Reset
        (Rest   => To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL | M_UN
                       | M_SN | M_RV,
         Horn   => To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL | M_NL
                       | M_UN | M_TR | M_PT | M_SN | M_RV,
         BMM    => To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL | M_RV);
      if To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL | M_NL | M_UN
             | M_TR | M_SN | M_RV
      then
         EVC_Position.Delete_Linking;
      end if;
      if To in M_NP | M_PS | M_SH | M_SL | M_SN | M_RV then
         EVC_Position.Delete_Geo;
      end if;
      --  the adhesion factor from the driver
      if To in M_NP | M_SB | M_PS | M_SH | M_SL | M_NL then
         EVC_Stored_Information.Set_Driver_Slippery (False);
      end if;
      --  (the train position: "D" in SL when invalid, and the deletions
      --  of 5.4.3.2 after E10, E12, E30, E31, E32 when still invalid: the
      --  position of this on-board is never "invalid", nothing is kept
      --  over No Power)

      --  4.12: Speed & Distance monitoring revoked in NP, SB, TR (to be
      --  re-evaluated in the others: the monitoring runs again on the
      --  data of the new mode)
      if To in M_NP | M_SB | M_TR then
         SDM_State.TCO := False;
         SDM_State.SB := False;
         SDM_State.EB := False;
         SDM_State.EB_For_SB := False;
      end if;
      --  4.12: Roll Away Protection revoked in NP, SB, TR, SN; the
      --  Unauthorised Direction Movement Protection in NP, SB, SH, UN, TR,
      --  SN and, from PT, in FS, LS, SR, OS ([1]); the Standstill
      --  Supervision in NP, SH, SM, FS, LS, SR, OS, SL, UN, TR, SN; in IS
      --  the on-board is isolated from the brakes (4.4.3.1.1)
      if To in M_NP | M_SB | M_TR | M_SN | M_IS then
         Brake_State.Roll_Away := (others => <>);
      end if;
      if To in M_NP | M_SB | M_SH | M_UN | M_TR | M_SN | M_IS
        or else (From = M_PT and then To in M_FS | M_LS | M_SR | M_OS)
      then
         Brake_State.Direction := (others => <>);
      end if;
      if To in M_NP | M_SH | M_SM | M_FS | M_LS | M_SR | M_OS | M_SL
             | M_UN | M_TR | M_SN | M_IS
      then
         Brake_State.Standstill := (others => <>);
      end if;
   end Enter_Mode;

   --  JRU events of phase E4 (EVC_Ports): 40 the levels, 41 the mission
   JRU_Levels  : constant := EVC_Ports.JRU_Levels;
   JRU_Mission : constant := EVC_Ports.JRU_Mission;

   --  8. Produce the outputs of the cycle
   procedure Produce_Outputs
     with Global => (Input  => (Current_Mode, Cycle_Count, Clock_Ms,
                                Standstill, Below_Override, TIU_Now,
                                EVC_National_Values.State,
                                EVC_Position.State,
                                SDM_Result, Brake_Output, Speed_State,
                                EVC_Levels.State, EVC_Mission.State,
                                EVC_Train_Data.State,
                                EVC_Stored_Information.State),
                     In_Out => (Reported_Mode, Geo_Sent, EVC_Outbox.Queue,
                                Status_Brake_Sent, Status_TTI_Sent,
                                TIU_Sent, TIU_Reasons_Sent,
                                Supervision_Reported, Overrun_Reported,
                                Entering_FS_Shown))
   is
      --  MSG_ONBOARD (dmi_protocol.ads) from what the on-board knows in
      --  E0; the fields of the later phases are 0, "nothing known"
      Train : Bits_T := 0;
      National : Bits_T := National_VBC_Room;  -- E0 stores no VBC
      Onboard : Onboard_T;
   begin
      --  JRU: the mode changed since the last report
      if Current_Mode /= Reported_Mode then
         EVC_Outbox.Put
           (JRU, JRU_Record (JRU_Mode_Change,
                             Mode_T'Pos (Current_Mode),
                             Level_Status_T'Pos (EVC_Levels.Status),
                             Level_T'Pos (EVC_Levels.Level)));
         Reported_Mode := Current_Mode;
      end if;
      --  JRU: the events of the levels and of the mission (phase E4)
      for I in 1 .. EVC_Levels.Event_Count loop
         declare
            E : constant EVC_Levels.Event_T := EVC_Levels.Event (I);
         begin
            EVC_Outbox.Put (JRU, JRU_Record (JRU_Levels, E.Kind, E.B3,
                                             E.B4));
         end;
      end loop;
      for I in 1 .. EVC_Mission.Event_Count loop
         declare
            E : constant EVC_Mission.Event_T := EVC_Mission.Event (I);
         begin
            EVC_Outbox.Put (JRU, JRU_Record (JRU_Mission, E.Kind, E.B3,
                                             E.B4));
         end;
      end loop;
      --  4.4.15.1.1.3: the driver is informed that the non-leading
      --  operation is no longer permitted and asked to acknowledge it
      --  (the DMI's catalogue entry 35, ended by the acknowledgement)
      if EVC_Mission.NL_No_Longer_Permitted then
         EVC_Outbox.Put (DMI, System_Status_Frame
                                (SS_NL_No_Longer_Permitted,
                                 SS_Event_Start));
      end if;
      --  4.4.9.1.4: in FS, "Entering FS" until SSP and gradient are known
      --  for the whole length of the train (the DMI's catalogue entry 6;
      --  a mode change ends it on the DMI as well)
      declare
         Entering : constant Boolean :=
           Current_Mode = M_FS
           and then EVC_Stored_Information.MA_On_Board
           and then not EVC_Stored_Information.Train_Covered;
      begin
         if Entering /= Entering_FS_Shown then
            EVC_Outbox.Put (DMI, System_Status_Frame
                                   (SS_Entering_FS,
                                    (if Entering then SS_Event_Start
                                     else SS_Event_End)));
            Entering_FS_Shown := Entering;
         end if;
      end;

      --  DMI: the mode and the level (4.4.2.1: a clear indication of the
      --  mode when the desk is open); 4.7.2: the acknowledgement of a mode
      --  proposed (the start of mission, 5.4.3.2 S22 to S24), the level
      --  transition announced (5.10.1.3) and its acknowledgement (5.10.4)
      if Has_Mode_Code (Current_Mode) then
         EVC_Outbox.Put
           (DMI,
            Mode_Level_Frame
              (Current_Mode, EVC_Levels.Status, EVC_Levels.Level,
               Mode_Ack      =>
                 (if EVC_Mission.Proposed
                    and then Has_Mode_Code (EVC_Mission.Proposed_Mode)
                  then Mode_Code (EVC_Mission.Proposed_Mode)
                  else No_Code),
               Level_Ann     =>
                 (if EVC_Levels.Ack_Asked
                  then Level_Code (Valid, EVC_Levels.Ack_Level)
                  elsif EVC_Levels.Announced
                  then Level_Code (Valid, EVC_Levels.Announced_Level)
                  else No_Code),
               Level_Ann_Ack => EVC_Levels.Ack_Asked));
      end if;

      if Standstill then
         Train := Train or Train_Standstill;
      end if;
      if Below_Override then
         Train := Train or Train_Below_Override;
      end if;
      if TIU_Now (Non_Leading_Permitted) then
         Train := Train or Train_Non_Leading;
      end if;
      if TIU_Now (Passive_Shunting_Permitted) then
         Train := Train or Train_Passive_Shunting;
      end if;
      if EVC_National_Values.M_NVDERUN then
         National := National or National_Driver_ID_Running;
      end if;
      if EVC_National_Values.Q_NVDRIVER_ADHES then
         National := National or National_Adhesion;
      end if;
      --  SUBSET-026 3.6.6: the geographical position, while it is known,
      --  and once "unknown" when it stops (the DMI shows it on request);
      --  phase E3: the brake indication (3.14.1.9, 3.14.2.6, 3.14.3.4)
      --  and the time to Indication (3.13.10.3.10), whenever they change
      declare
         --  phase E4: the service brake of 5.10.4.2 is applied because the
         --  acknowledgement of the level is pending; in IS the on-board
         --  is isolated from the brakes (4.4.3.1.1)
         Brake : constant EVC_Bytes.Byte :=
           (if Current_Mode = M_IS then Brake_None
            elsif Brake_Output.Ack_Required then Brake_Ack
            elsif Brake_Output.EB or else Brake_Output.SB
              or else Current_Mode = M_SF
            then Brake_Applied
            elsif EVC_Levels.Ack_Brake then Brake_Ack_Pending
            else Brake_None);
         TTI   : constant Unsigned_16 :=
           (if SDM_Result.TTI = EVC_SDM.No_TTI then TTI_None
            else Unsigned_16 (SDM_Result.TTI));
         Changed : constant Boolean :=
           Brake /= Status_Brake_Sent or else TTI /= Status_TTI_Sent;
      begin
         if EVC_Position.Geo_Known then
            EVC_Outbox.Put
              (DMI, Status_Frame (Unsigned_32 (EVC_Position.Geo_Metres),
                                  Unsigned_64 (Clock_Ms) / 1000,
                                  Brake, TTI));
            Geo_Sent := True;
         elsif Geo_Sent or else Changed then
            EVC_Outbox.Put
              (DMI, Status_Frame (Geo_Unknown,
                                  Unsigned_64 (Clock_Ms) / 1000,
                                  Brake, TTI));
            Geo_Sent := False;
         end if;
         Status_Brake_Sent := Brake;
         Status_TTI_Sent := TTI;
      end;

      Onboard :=
        (Data     => (if EVC_Levels.Valid then Data_Level_Valid else 0)
                     or (if EVC_Position.Status = EVC_Position.Valid
                           and then EVC_Position.LRBG.Valid
                         then Data_Position_Valid else 0)
                     --  phase E4: the data of the start of mission
                     or (if EVC_Mission.Driver_ID_Status = EVC_Mission.Valid
                         then Data_Driver_ID_Valid else 0)
                     or (if EVC_Mission.Train_Data_Status
                              = EVC_Mission.Valid
                         then Data_Train_Data_Valid else 0)
                     or (if EVC_Mission.TRN_Status = EVC_Mission.Valid
                         then Data_TRN_Valid else 0),
         Train    => Train,
         National => National,
         --  SUBSET-026 5.4.3.2 S0 (DMI Table 49): the mode is SB, the
         --  desk is open and no session with an RBC exists or is being
         --  established, so the start of mission may begin (phase E4:
         --  the desk is the cab status input, EVC_Mission)
         SoM      => (if EVC_Mission.SoM_Engaged then SoM_Possible else 0),
         others   => 0);
      EVC_Outbox.Put (DMI, Onboard_Frame (Onboard));

      --  The speed and distance monitoring and the brake commands
      --  (phase E3): MSG_SPEED_STATE every cycle, the JRU records of what
      --  changed, the commands to the train interface
      declare
         Reasons  : EVC_Brake_Commands.Reasons_T renames
           Brake_Output.Reasons;
         --  phase E4: the service brake of 5.10.4.2 (reason bit 5, the
         --  levels); in SF the emergency brake, permanently (4.4.5.1.2,
         --  reason bit 6); in IS no command (4.4.3.1.1)
         Isolated : constant Boolean := Current_Mode = M_IS;
         Failure  : constant Boolean := Current_Mode = M_SF;
         Commands : constant EVC_Bytes.Byte :=
           (if Isolated then 0
            else (if Brake_Output.EB or else Failure then TIU_EBC else 0)
                 or (if Brake_Output.SB or else EVC_Levels.Ack_Brake
                     then TIU_SBC else 0)
                 or (if Brake_Output.TCO then TIU_TCO else 0));
         Why      : constant EVC_Bytes.Byte :=
           (if Isolated then 0
            else (if Reasons (EVC_Brake_Commands.Speed_Distance) then 1
                  else 0)
                 or (if Reasons (EVC_Brake_Commands.Service_Brake_Failed)
                     then 2 else 0)
                 or (if Reasons (EVC_Brake_Commands.Roll_Away) then 4
                     else 0)
                 or (if Reasons (EVC_Brake_Commands.Direction) then 8
                     else 0)
                 or (if Reasons (EVC_Brake_Commands.Standstill_Supervision)
                     then 16 else 0)
                 or (if EVC_Levels.Ack_Brake then 32 else 0)
                 or (if Failure then 64 else 0));
         Supervision_Now : constant Unsigned_32 :=
           (if SDM_Result.Active
            then Unsigned_32
                   (EVC_SDM.Monitoring_T'Pos (SDM_Result.Monitoring))
                 * 65_536
                 + Unsigned_32 (EVC_SDM.Status_T'Pos (SDM_Result.Status))
                   * 256
                 + Unsigned_32 (SDM_Result.MRDT_Id)
            else No_Supervision);
         Overrun  : constant EVC_Bytes.Byte :=
           (if SDM_Result.EOA_Passed then 1 else 0)
           or (if SDM_Result.SvL_Passed then 2 else 0);
      begin
         EVC_Outbox.Put (DMI, Speed_State_Frame (Speed_State));
         if Commands /= TIU_Sent or else Why /= TIU_Reasons_Sent then
            EVC_Outbox.Put
              (JRU, JRU_Record (JRU_Brake_Commands, Commands, Why,
                                EVC_SDM.Status_T'Pos (SDM_Result.Status)));
         end if;
         if Supervision_Now /= Supervision_Reported
           and then SDM_Result.Active
         then
            EVC_Outbox.Put
              (JRU, JRU_Record
                      (JRU_Supervision,
                       EVC_SDM.Monitoring_T'Pos (SDM_Result.Monitoring),
                       EVC_SDM.Status_T'Pos (SDM_Result.Status),
                       EVC_Bytes.Byte (SDM_Result.MRDT_Id)));
         end if;
         Supervision_Reported := Supervision_Now;
         for Bit in EVC_Bytes.Byte range 1 .. 2 loop
            if (Overrun and Bit) /= 0
              and then (Overrun_Reported and Bit) = 0
            then
               EVC_Outbox.Put (JRU, JRU_Record (JRU_Overrun, Bit, 0, 0));
            end if;
         end loop;
         Overrun_Reported := Overrun;
         --  the TIU output: when it changes, and every cycle while a
         --  command is given
         if Commands /= 0 or else Commands /= TIU_Sent
           or else Why /= TIU_Reasons_Sent
         then
            EVC_Outbox.Put (TIU, TIU_Output (Commands, Why));
         end if;
         TIU_Sent := Commands;
         TIU_Reasons_Sent := Why;
      end;
   end Produce_Outputs;

   ----------
   -- Tick --
   ----------

   procedure Tick (Dt_Ms : Natural) is
   begin
      if Failed_Flag then
         return;
      end if;
      Cycle_Count := Cycle_Count + 1;
      Clock_Ms := Clock_Ms + Time_Ms_T (Dt_Ms);

      Report_Configuration;
      Read_Ports;
      Update_Position;
      Evaluate_Stored_Information;
      Monitor_Speed_And_Distance (Dt_Ms);
      Evaluate_Modes_And_Levels;
      declare
         From : constant Mode_T := Current_Mode;
      begin
         Run_Mode_Machine;
         if Current_Mode /= From then
            Enter_Mode (From, Current_Mode);
         end if;
      end;
      Produce_Outputs;
   end Tick;

   ------------------
   -- Take_Outputs --
   ------------------

   procedure Take_Outputs (Buffer : out EVC_Bytes.Byte_Array;
                           Last   : out Natural)
   is
   begin
      if Failed_Flag then
         Buffer := (others => 0);
         Last := Buffer'First - 1;
      else
         EVC_Outbox.Take (Buffer, Last);
      end if;
   end Take_Outputs;

   -------------------
   -- Enter_Failure --
   -------------------

   procedure Enter_Failure is
   begin
      Failed_Flag := True;
      if Transition_Exists (Current_Mode, M_SF) then
         Current_Mode := M_SF;
      end if;
      EVC_Outbox.Clear;
   end Enter_Failure;

end EVC_Core;
