--  ETCS on-board (EVC)
--  Core of the ETCS on-board, implementation.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Message;
with ETCS_Telegram;
with ETCS_Variables;
with EVC_DMI_Port; use EVC_DMI_Port;
with EVC_Fixed;
with EVC_Limits;
with EVC_Procedure_Transitions;
with Interfaces;   use Interfaces;

package body EVC_Core
  with SPARK_Mode => On,
       Refined_State => (State => (Failed_Flag,
                                   Current_Mode,
                                   Current_Level_Status,
                                   Current_Level,
                                   Cycle_Count,
                                   Clock_Ms,
                                   Reported_Mode,
                                   Latched_Odometer,
                                   Latched_Odometer_Fresh,
                                   Latched_TIU,
                                   Latched_Isolation,
                                   Latched_BTM,
                                   Latched_BTM_Count,
                                   Latched_RTM,
                                   Latched_RTM_Count,
                                   Odometer_Now,
                                   Odometer_Fresh,
                                   Geo_Sent,
                                   TIU_Now,
                                   Isolation_Now,
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
                                   --  the procedures (phase E4)
                                   Proc_Ctx,
                                   Ack_For_Protection,
                                   Status_Rev_Sent))
is

   use type EVC_Bytes.Byte_Array;
   use type ETCS_Message.Status_T;
   use type ETCS_Telegram.Status_T;

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   type TIU_Signals_T is array (TIU_Signal_T) of Boolean;
   type Counts_T is array (Port_T) of Natural;

   Failed_Flag          : Boolean := False;
   Current_Mode         : Mode_T := M_NP;
   Current_Level_Status : Level_Status_T := Unknown;
   Current_Level        : Level_T := L0;
   Cycle_Count          : Cycle_T := 0;
   Clock_Ms             : Time_Ms_T := 0;
   --  The mode last reported to the juridical recording
   Reported_Mode        : Mode_T := M_NP;

   --  Inputs latched by Handle_Input since the last cycle
   Latched_Odometer  : Odometer_Sample_T := Standstill_Sample;
   --  a sample arrived since the last cycle
   Latched_Odometer_Fresh : Boolean := False;
   Latched_TIU       : TIU_Signals_T := (others => False);
   Latched_Isolation : Boolean := False;

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
   Isolation_Now : Boolean := False;

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

   ---------------------------------------------------------------------
   --  The procedures (phase E4, e4/procedures)
   ---------------------------------------------------------------------

   --  The context of the procedures in the cycle (Run_Procedures)
   Proc_Ctx : EVC_Procedures.Context_T;
   --  the acknowledgement of a brake release of the cycle went to the
   --  protections of 3.14.1.5 (EVC_Brake_Commands asked for it)
   Ack_For_Protection : Boolean := False;
   --  the reversing indication sent last (MSG_STATUS)
   Status_Rev_Sent : Boolean := False;

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Mode return Mode_T is (Current_Mode);
   function Level_Status return Level_Status_T is (Current_Level_Status);
   function Level return Level_T is (Current_Level);
   function Failed return Boolean is (Failed_Flag);
   function Cycle return Cycle_T is (Cycle_Count);
   function Time_Ms return Time_Ms_T is (Clock_Ms);
   function Isolation_Requested return Boolean is (Latched_Isolation);
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

   procedure Set_Mode_For_Test (M : Mode_T; L : Level_T) is
   begin
      Current_Mode := M;
      Current_Level_Status := Valid;
      Current_Level := L;
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
      --  5.4.3.2 D2: nothing is stored over No Power in E0, the level
      --  is "unknown" and the start of mission asks the driver for it
      Current_Level_Status := Unknown;
      Current_Level := L0;
      Cycle_Count := 0;
      Clock_Ms := 0;
      Reported_Mode := M_NP;
      Latched_Odometer := Standstill_Sample;
      Latched_Odometer_Fresh := False;
      Latched_TIU := (others => False);
      Latched_Isolation := False;
      Latched_BTM := (others => (Length => 0, Data => (others => 0)));
      Latched_BTM_Count := 0;
      Latched_RTM := (others => (Length => 0, Data => (others => 0)));
      Latched_RTM_Count := 0;
      Odometer_Now := Standstill_Sample;
      Odometer_Fresh := False;
      Geo_Sent := False;
      TIU_Now := (others => False);
      Isolation_Now := False;
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
      Proc_Ctx := (others => <>);
      Ack_For_Protection := False;
      Status_Rev_Sent := False;
      EVC_Procedure_Requests.Clear;
      EVC_Procedures.Clear;
      EVC_Text_Messages.Clear;
      EVC_Received.Clear;
      EVC_Position.Clear;
      --  the installation: the antenna of the configuration
      EVC_Position.Set_Antenna (EVC_Config.Current.Antenna_To_Cab_A,
                                EVC_Config.Current.Antenna_To_Cab_B);
      --  phase E3: nothing stored, the default train
      EVC_Stored_Information.Clear;
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
            --  E0 acts on one driver action: the isolation of the
            --  on-board (4.6.3 condition [1]). The driver's other
            --  actions and data are accepted and left to phase E4.
            if Is_Driver_Action (Payload)
              and then Driver_Action (Payload) = Action_Isolate
            then
               Latched_Isolation := True;
            end if;
            --  3.14.1.5: the release of a brake acknowledged
            if Is_Brake_Release_Ack (Payload) then
               Latched_Brake_Ack := True;
            end if;
            --  phase E4: the driver's actions of the procedures
            --  (interim, EVC_Procedure_Requests)
            EVC_Procedure_Requests.Latch (Payload);
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
                                Isolation_Now, TIU_Value_Now,
                                TIU_Known_Now, Brake_Ack_Now),
                     In_Out => (Latched_Isolation, Latched_Odometer_Fresh,
                                Latched_Brake_Ack,
                                Latched_BTM_Count,
                                Latched_RTM_Count, EVC_Received.Store,
                                EVC_Outbox.Queue, EVC_Position.State,
                                EVC_Procedure_Requests.State,
                                EVC_Procedures.State)),
          Post => Isolation_Now = Latched_Isolation'Old
                  and then not Latched_Isolation
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
      Isolation_Now := Latched_Isolation;
      Latched_Isolation := False;
      --  phase E4: the driver's actions of the procedures
      EVC_Procedure_Requests.Take;

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
               elsif T_Status = ETCS_Telegram.Unsupported_Version
                 --  3.17.3.5, 4.6.3 [65]: the X of M_VERSION, the three
                 --  most significant of the seven bits after Q_UPDOWN
                 --  (the first byte of the telegram), above the 3 of
                 --  this on-board (SUBSET-026 v4.0.0, system version 3.x)
                 and then (Slot.Data (BTM_Stamp_Length + 3) and 16#7F#) / 16
                            > 3
               then
                  EVC_Procedures.Note_Version_Not_Supported;
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

   --  2. Update the position (EVC_Position): the cab status, the
   --  telegrams of the cycle, the odometer sample; its events go to the
   --  JRU. E0's standstill and override speed come from the sample.
   procedure Update_Position
     with Global => (Input  => (Odometer_Now, Odometer_Fresh, TIU_Now,
                                EVC_National_Values.State, Current_Mode,
                                Current_Level, Cycle_Count, Clock_Ms),
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
      EVC_Position.Update
        (Cab_A_Active => TIU_Now (Cab_A_Active),
         Cab_B_Active => TIU_Now (Cab_B_Active),
         Sampled      => Odometer_Fresh,
         Sample       => Odometer_Now,
         Mode         => Current_Mode,
         Level        => Current_Level,
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

   procedure Evaluate_Stored_Information
     with Global => (Input  => (Clock_Ms, Cycle_Count, EVC_Position.State,
                                EVC_Odometry.State, EVC_Train_Data.State,
                                TIU_Now, EVC_Config.State, Current_Mode,
                                EVC_Procedures.State),
                     In_Out => (EVC_Stored_Information.State,
                                EVC_Origins.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                EVC_Outbox.Queue))
   is
      Frame : EVC_DMI_Port.Frame_Buffer_T;
      Last  : Natural;
   begin
      --  phase E4: the mode profile of the mode in use is no temporary
      --  EOA (3.12.4.7); 5.11.2.2 A035: in Trip no MA and no track
      --  description are taken
      EVC_Movement_Authority.Set_Mode_In_Use
        (case Current_Mode is
            when M_OS   => 0,
            when M_SH   => 1,
            when M_LS   => 2,
            when others => 3);
      EVC_Stored_Information.Refuse_Authority (Current_Mode = M_TR);
      --  the mode related speed restriction (3.11.7, 3.11.10:
      --  EVC_Procedures) of the mode of the last cycle; the status of the
      --  special brakes for the speed restrictions to ensure a permitted
      --  braking distance (3.11.11.4)
      EVC_Stored_Information.Evaluate
        (Unsigned_64 (Clock_Ms),
         EVC_Procedures.Mode_Speed
           (Current_Mode, EVC_National_Values.Current.Values),
         Special_Active =>
           (EVC_Supervision_Input.Regenerative =>
              TIU_Now (Regenerative_Brake_Active),
            EVC_Supervision_Input.Eddy_Current =>
              TIU_Now (Eddy_Current_Brake_Active),
            EVC_Supervision_Input.Magnetic_Shoe =>
              TIU_Now (Magnetic_Shoe_Brake_Active),
            EVC_Supervision_Input.Electro_Pneumatic =>
              TIU_Now (EP_Brake_Active)),
         Additional     => TIU_Now (Additional_Brake_Active));
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
                                Current_Mode, Current_Level,
                                Current_Level_Status, EVC_Position.State,
                                EVC_Stored_Information.State),
                     In_Out => (SDM_Work, SDM_State, Brake_State,
                                Brake_Output),
                     Output => (SDM_Result, Speed_State,
                                Ack_For_Protection))
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
            Level_1        => Current_Level_Status = Valid
                              and then Current_Level = L1,
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
      --  the acknowledgement of a release goes first to the protections
      --  of 3.14.1.5 when they ask for it (3.14.1.10)
      Ack_For_Protection := Brake_Ack_Now and then Brake_Output.Ack_Required;
      if Test_Snapshot_Set then
         Run (Test_Snapshot);
      else
         Run (EVC_Stored_Information.Current);
      end if;
   end Monitor_Speed_And_Distance;

   --  The snapshot the speed and distance monitoring read in the cycle
   function Snapshot_In_Use return EVC_Supervision_Input.Snapshot_T is
     (if Test_Snapshot_Set then Test_Snapshot
      else EVC_Stored_Information.Current)
     with Global => (Test_Snapshot, Test_Snapshot_Set,
                     EVC_Stored_Information.State);

   --  4b. Phase E4, the procedures (EVC_Procedures, EVC_Text_Messages):
   --  the context of the cycle, the conditions of 4.6.3 they own; the
   --  trip order of the cycle is taken (3.11.6.4)
   procedure Run_Procedures
     with Global => (Input  => (Current_Mode, Current_Level,
                                Current_Level_Status, TIU_Now,
                                TIU_Value_Now, TIU_Known_Now, Odometer_Now,
                                Brake_Ack_Now, Ack_For_Protection, Clock_Ms,
                                SDM_Result, Test_Snapshot, Test_Snapshot_Set,
                                EVC_Stored_Information.State,
                                EVC_Position.State,
                                EVC_Origins.State, EVC_Track_Description.State,
                                EVC_Procedure_Requests.State,
                                EVC_Train_Data.State),
                     Output => Proc_Ctx,
                     In_Out => (EVC_Procedures.State, EVC_Text_Messages.State,
                                EVC_Movement_Authority.State))
   is
      S : constant EVC_Supervision_Input.Snapshot_T := Snapshot_In_Use;
   begin
      Proc_Ctx :=
        (Mode              => Current_Mode,
         Level_Valid       => Current_Level_Status = Valid,
         Level             => Current_Level,
         --  the level transitions are the modes half's
         Level_Switched    => False,
         Desk_Open         => TIU_Now (Cab_A_Active)
                              or else TIU_Now (Cab_B_Active),
         Passive_Shunting  => TIU_Now (Passive_Shunting_Permitted),
         Controller        =>
           (if not TIU_Known_Now (Direction_Controller)
            then EVC_Brake_Commands.Unknown
            else (case TIU_Value_Now (Direction_Controller) is
                     when 1      => EVC_Brake_Commands.Forwards,
                     when 2      => EVC_Brake_Commands.Backwards,
                     when others => EVC_Brake_Commands.Neutral)),
         Train_Data_Valid  => EVC_Train_Data.Valid,
         --  the train running number is the start of mission's (modes
         --  half): taken as valid until then
         TRN_Valid         => True,
         Speed_Max         =>
           EVC_Supervision_Input.Speed_Cms_T
             (Natural'Min (Natural (Odometer_Now.V_Max),
                           EVC_Supervision_Input.Speed_Cms_T'Last)),
         Antenna_Offset    =>
           EVC_Position.Front_Offset (EVC_Position.Orientation),
         Brake_Release_Ack => Brake_Ack_Now and then not Ack_For_Protection,
         Now_Ms            => Unsigned_64 (Clock_Ms));
      EVC_Procedures.Evaluate (Proc_Ctx, S, SDM_Result);
      EVC_Text_Messages.Evaluate
        (Current_Mode, Current_Level_Status = Valid, Current_Level,
         S.Train.Est_Front, Unsigned_64 (Clock_Ms));
      --  3.11.6.4: the trip order of the cycle was taken
      if EVC_Movement_Authority.Trip_Ordered then
         EVC_Movement_Authority.Clear_Trip_Order;
      end if;
   end Run_Procedures;

   --  SUBSET-026 4.6.3: whether the condition of the transition From ->
   --  To holds in this cycle. E0 evaluates two conditions:
   --    [1]  the driver isolates the ERTMS/ETCS on-board equipment,
   --    [4]  the ERTMS/ETCS on-board equipment is powered: always true
   --         while this code runs, so [29] ("NOT powered") never holds.
   --  Phase E4, interim until the mode machine of the modes half: the
   --  conditions of the procedures (EVC_Procedure_Transitions).
   function Condition_Holds (From, To : Mode_T) return Boolean is
     (case To is
         when M_IS     => Isolation_Now,
         when M_SB     => From = M_NP
                          or else EVC_Procedure_Transitions.Holds (From, To),
         when others => EVC_Procedure_Transitions.Holds (From, To))
     with Global => (Isolation_Now, EVC_Procedures.State);

   --  5. Mode machine: of the transitions of 4.6.2 whose condition
   --  holds, the one of the highest priority (4.6.1.4)
   procedure Run_Mode_Machine
     with Global => (Input  => (Isolation_Now, EVC_Procedures.State),
                     In_Out => Current_Mode),
          Post => (Current_Mode = Current_Mode'Old
                   or else Transition_Exists
                             (Current_Mode'Old, Current_Mode))
                  and then Current_Mode /= M_NP
                  and then (if Current_Mode'Old = M_IS
                            then Current_Mode = M_IS)
                  and then (if Current_Mode'Old = M_NP
                            then Current_Mode = (if Isolation_Now
                                                 then M_IS else M_SB))
   is
      From          : constant Mode_T := Current_Mode;
      Best          : Mode_T := From;
      Best_Priority : Priority_T := No_Transition;
   begin
      for To in Mode_T loop
         if Transitions (From, To) /= No_Transition
           and then Condition_Holds (From, To)
           and then (Best_Priority = No_Transition
                     or else Transitions (From, To) < Best_Priority)
         then
            Best := To;
            Best_Priority := Transitions (From, To);
         end if;
         pragma Loop_Invariant
           (if Best_Priority = No_Transition
            then Best = From
            else Transitions (From, Best) = Best_Priority
                 and then Condition_Holds (From, Best));
         pragma Loop_Invariant
           (if From = M_NP and then To >= M_SB
            then Best_Priority /= No_Transition);
         pragma Loop_Invariant
           (if From = M_NP and then Best_Priority /= No_Transition
            then Best = (if Isolation_Now and then To >= M_IS then M_IS
                         else M_SB));
      end loop;
      Current_Mode := Best;
   end Run_Mode_Machine;

   --  5b. Phase E4: what entering a mode means for the procedures
   --  (EVC_Procedures.Mode_Changed, EVC_Text_Messages.Mode_Changed), the
   --  information they delete (5.11.2.2 A035 on a trip; the rows of 4.10
   --  the procedures need for Staff Responsible after an override,
   --  Shunting and Reversing, until the table of 4.10 of the modes half),
   --  then their brake demand in the mode of the end of the cycle
   procedure Mode_Effects (From : Mode_T)
     with Global => (Input  => (Current_Mode, Proc_Ctx, Test_Snapshot,
                                Test_Snapshot_Set),
                     In_Out => (EVC_Procedures.State, EVC_Text_Messages.State,
                                EVC_Stored_Information.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Description.State))
   is
      S : constant EVC_Supervision_Input.Snapshot_T := Snapshot_In_Use;
   begin
      if Current_Mode /= From then
         EVC_Procedures.Mode_Changed (From, Current_Mode, Proc_Ctx, S);
         EVC_Text_Messages.Mode_Changed (From, Current_Mode);
         if Current_Mode in M_TR | M_SR | M_SH | M_RV then
            EVC_Stored_Information.Delete_Authority_And_Description
              (LX => True);
         end if;
      end if;
      EVC_Procedures.Finish_Cycle (Proc_Ctx, Current_Mode, S);
   end Mode_Effects;

   --  6. Produce the outputs of the cycle
   procedure Produce_Outputs
     with Global => (Input  => (Current_Mode, Current_Level_Status,
                                Current_Level, Cycle_Count, Clock_Ms,
                                Standstill, Below_Override, TIU_Now,
                                EVC_National_Values.State,
                                EVC_Position.State,
                                SDM_Result, Brake_Output, Speed_State,
                                EVC_Procedures.State,
                                EVC_Text_Messages.State),
                     In_Out => (Reported_Mode, Geo_Sent, EVC_Outbox.Queue,
                                Status_Brake_Sent, Status_TTI_Sent,
                                TIU_Sent, TIU_Reasons_Sent,
                                Supervision_Reported, Overrun_Reported,
                                Status_Rev_Sent))
   is
      --  MSG_ONBOARD (dmi_protocol.ads) from what the on-board knows in
      --  E0; the fields of the later phases are 0, "nothing known"
      Train : Bits_T := 0;
      National : Bits_T := National_VBC_Room;  -- E0 stores no VBC
      Onboard : Onboard_T;
      --  phase E4: the brake demands of the procedures and of the text
      --  messages
      D       : constant EVC_Procedures.Brake_Demand_T :=
        EVC_Procedures.Brake_Demand;
      Text_SB : constant Boolean := EVC_Text_Messages.Service_Brake;
      Text_EB : constant Boolean := EVC_Text_Messages.Emergency_Brake;
      Seconds : constant Unsigned_64 := Unsigned_64 (Clock_Ms) / 1000;
   begin
      --  JRU: the mode changed since the last report
      if Current_Mode /= Reported_Mode then
         EVC_Outbox.Put
           (JRU, JRU_Record (JRU_Mode_Change,
                             Mode_T'Pos (Current_Mode),
                             Level_Status_T'Pos (Current_Level_Status),
                             Level_T'Pos (Current_Level)));
         Reported_Mode := Current_Mode;
      end if;

      --  DMI: the mode and the level (4.4.2.1: a clear indication of the
      --  mode when the desk is open)
      --  phase E4: the acknowledgement of a mode the procedures ask
      --  (5.7, 5.9, 5.11, 5.13, 5.19) and "override active" (5.8.3.7)
      if Has_Mode_Code (Current_Mode) then
         EVC_Outbox.Put
           (DMI,
            Mode_Level_Frame
              (Current_Mode, Current_Level_Status, Current_Level,
               Ack      =>
                 (if EVC_Procedures.Ack_Requested
                    and then Has_Mode_Code (EVC_Procedures.Ack_Mode)
                  then Mode_Code (EVC_Procedures.Ack_Mode)
                  else No_Mode_Ack),
               Override => EVC_Procedures.Override_Indicated));
      end if;
      --  phase E4: the system status messages of the procedures (the
      --  reason of a trip, the reverse movement distances)
      for I in 1 .. EVC_Procedures.Status_Event_Count loop
         declare
            E : constant EVC_Procedures.Status_Event_T :=
              EVC_Procedures.Status_Event (I);
         begin
            EVC_Outbox.Put
              (DMI, System_Status_Frame (EVC_Bytes.Byte (E.Entry_Number),
                                         EVC_Bytes.Byte (E.Event)));
         end;
      end loop;
      --  phase E4: the text messages (3.12.3)
      for I in 1 .. EVC_Text_Messages.Output_Count loop
         declare
            O : constant EVC_Text_Messages.Output_T :=
              EVC_Text_Messages.Output (I);
            F : Frame_Buffer_T;
            L : Natural;
         begin
            if EVC_Text_Messages."=" (O.Kind, EVC_Text_Messages.Show) then
               Text_Frame (O.Id, O.Flags,
                           EVC_Bytes.Byte (Seconds / 3600 mod 24),
                           EVC_Bytes.Byte (Seconds / 60 mod 60),
                           O.Text (1 .. O.Length), F, L);
               EVC_Outbox.Put (DMI, F (1 .. L));
            else
               EVC_Outbox.Put (DMI, Text_Remove_Frame (O.Id));
            end if;
         end;
      end loop;
      --  phase E4: the records of the procedures and the text messages
      for I in 1 .. EVC_Procedures.Event_Count loop
         declare
            E : constant EVC_Procedures.Event_T := EVC_Procedures.Event (I);
         begin
            EVC_Outbox.Put (JRU, JRU_Record (JRU_Procedures, E.Kind, E.B3,
                                             E.B4));
         end;
      end loop;
      for I in 1 .. EVC_Text_Messages.Event_Count loop
         declare
            E : constant EVC_Text_Messages.Event_T :=
              EVC_Text_Messages.Event (I);
         begin
            EVC_Outbox.Put (JRU, JRU_Record (JRU_Text_Messages, E.Kind, E.B3,
                                             E.B4));
         end;
      end loop;

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
      if EVC_Procedures.BMM_Inhibited then
         Train := Train or Train_BMM_Inhibition;
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
         --  phase E4: the brakes of the procedures; 3 (DMI 8.2.2.3.4.1)
         --  while only an acknowledgement of a mode or a text is missing
         Brake : constant EVC_Bytes.Byte :=
           (if Brake_Output.Ack_Required or else D.Ack_Required
            then Brake_Ack
            elsif Brake_Output.EB or else Brake_Output.SB or else D.Trip
              or else D.Other
            then Brake_Applied
            elsif D.Ack_Missing or else Text_SB or else Text_EB
            then Brake_Pending_Ack
            else Brake_None);
         TTI   : constant Unsigned_16 :=
           (if SDM_Result.TTI = EVC_SDM.No_TTI then TTI_None
            else Unsigned_16 (SDM_Result.TTI));
         Rev   : constant Boolean := EVC_Procedures.Reversing_Possible;
         Changed : constant Boolean :=
           Brake /= Status_Brake_Sent or else TTI /= Status_TTI_Sent
           or else Rev /= Status_Rev_Sent;
      begin
         if EVC_Position.Geo_Known then
            EVC_Outbox.Put
              (DMI, Status_Frame (Unsigned_32 (EVC_Position.Geo_Metres),
                                  Unsigned_64 (Clock_Ms) / 1000,
                                  Brake, TTI, Rev));
            Geo_Sent := True;
         elsif Geo_Sent or else Changed then
            EVC_Outbox.Put
              (DMI, Status_Frame (Geo_Unknown,
                                  Unsigned_64 (Clock_Ms) / 1000,
                                  Brake, TTI, Rev));
            Geo_Sent := False;
         end if;
         Status_Brake_Sent := Brake;
         Status_TTI_Sent := TTI;
         Status_Rev_Sent := Rev;
      end;

      Onboard :=
        (Data     => (if Current_Level_Status = Valid
                      then Data_Level_Valid else 0)
                     or (if EVC_Position.Status = EVC_Position.Valid
                           and then EVC_Position.LRBG.Valid
                         then Data_Position_Valid else 0),
         Train    => Train,
         National => National,
         --  SUBSET-026 5.4.3.2 S0 (DMI Table 49): the mode is SB, the
         --  desk is open and no session with an RBC exists or is being
         --  established, so the start of mission may begin. E0 has no
         --  cab signals in its scenarios yet and takes the desk as open.
         SoM      => (if Current_Mode = M_SB then SoM_Possible else 0),
         others   => 0);
      EVC_Outbox.Put (DMI, Onboard_Frame (Onboard));

      --  The speed and distance monitoring and the brake commands
      --  (phase E3): MSG_SPEED_STATE every cycle, the JRU records of what
      --  changed, the commands to the train interface
      declare
         Reasons  : EVC_Brake_Commands.Reasons_T renames
           Brake_Output.Reasons;
         Commands : constant EVC_Bytes.Byte :=
           (if Brake_Output.EB or else D.EB or else Text_EB
            then TIU_EBC else 0)
           or (if Brake_Output.SB or else D.SB or else Text_SB
               then TIU_SBC else 0)
           or (if Brake_Output.TCO then TIU_TCO else 0);
         Why      : constant EVC_Bytes.Byte :=
           (if Reasons (EVC_Brake_Commands.Speed_Distance) then 1 else 0)
           or (if Reasons (EVC_Brake_Commands.Service_Brake_Failed)
               then 2 else 0)
           or (if Reasons (EVC_Brake_Commands.Roll_Away) then 4 else 0)
           or (if Reasons (EVC_Brake_Commands.Direction) then 8 else 0)
           or (if Reasons (EVC_Brake_Commands.Standstill_Supervision)
               then 16 else 0)
           --  phase E4: the reasons of the procedures (EVC_Ports)
           or (if D.Trip then TIU_Reason_Trip else 0)
           or (if D.Ack_Missing or else Text_SB or else Text_EB
               then TIU_Reason_Ack_Missing else 0)
           or (if D.Other then TIU_Reason_Procedure else 0);
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
      From : Mode_T;
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
      Run_Procedures;
      From := Current_Mode;
      Run_Mode_Machine;
      Mode_Effects (From);
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
