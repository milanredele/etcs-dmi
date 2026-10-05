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
                                   Kept_Pending,
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
                                   Latched_Events,
                                   Latched_Event_Count,
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
                                   Snapshot,
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
                                   Entering_Shown,
                                   Runaway_Shown,
                                   --  the procedures (phase E4)
                                   Proc_Ctx,
                                   Ack_For_Protection,
                                   Status_Rev_Sent, Status_Tunnel_Sent,
                                   Status_Radio_Sent,
                                   TC_Sent,
                                   Config_Last, Config_Seen))
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
   --  4.11.1.1: data kept over No Power wait for the cold movement
   --  detection (Power_Up)
   Kept_Pending         : Boolean := False;
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

   --  phase E5: a message with its session (1 for a message without a
   --  tag, EVC_Ports)
   type RTM_Slot_T is record
      Session : RTM_Session_T := 1;
      Length  : Natural range 0 .. RTM_Max_Length := 0;
      Data    : EVC_Bytes.Byte_Array (1 .. RTM_Max_Length) := (others => 0);
   end record;
   type RTM_Slots_T is array (1 .. RTM_Latch_Size) of RTM_Slot_T;

   --  phase E5: the connection events of the RTM port latched since the
   --  last cycle (as many as messages)
   type Event_Slot_T is record
      Session : RTM_Session_T := 1;
      Event   : RTM_Event_T := Connection_Set_Up;
   end record;
   type Event_Slots_T is array (1 .. RTM_Latch_Size) of Event_Slot_T;

   Latched_BTM       : BTM_Slots_T;
   Latched_BTM_Count : Natural range 0 .. BTM_Latch_Size := 0;
   Latched_RTM       : RTM_Slots_T;
   Latched_RTM_Count : Natural range 0 .. RTM_Latch_Size := 0;
   Latched_Events      : Event_Slots_T;
   Latched_Event_Count : Natural range 0 .. RTM_Latch_Size := 0;

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

   --  The direction controller of the active desk in the cycle (TIU
   --  input 6, EVC_Ports: 0 neutral, 1 forward, 2 reverse), unknown until
   --  its first input; one reading for the supervision (roll away and
   --  reverse movement protection, 3.14.2, 3.14.3) and the procedures
   function Controller_Now return EVC_Brake_Commands.Controller_T is
     (if not TIU_Known_Now (Direction_Controller)
      then EVC_Brake_Commands.Unknown
      else (case TIU_Value_Now (Direction_Controller) is
               when 1      => EVC_Brake_Commands.Forwards,
               when 2      => EVC_Brake_Commands.Backwards,
               when others => EVC_Brake_Commands.Neutral))
     with Global => (TIU_Value_Now, TIU_Known_Now);

   --  The snapshot the speed and distance monitoring and the procedures
   --  read: the snapshot of the tests (Set_Snapshot_For_Test), once set,
   --  in every cycle until Initialise, else the one of the stored
   --  information (EVC_Stored_Information, 3.13.2), taken by Take_Snapshot
   --  where it is read. It is package state and goes by reference to its
   --  readers: a function returning it would build a copy of over 11 KB
   --  on the stack of every caller.
   Snapshot          : EVC_Supervision_Input.Snapshot_T;
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
   TIU_Reasons_Sent     : TIU_Reasons_T := 0;
   No_Supervision       : constant Unsigned_32 := 16#FFFF_FFFF#;
   Supervision_Reported : Unsigned_32 := No_Supervision;
   Overrun_Reported     : EVC_Bytes.Byte := 0;
   --  phase E4: the indication "Entering FS" (4.4.9.1.4) or "Entering
   --  OS" (4.4.12.1.7) shown: its catalogue entry, 0 none
   Entering_Shown       : EVC_Bytes.Byte := 0;
   --  3.14.2.6, 3.14.3.4, 4.4.7.1.5.4: "Runaway movement" shown (the DMI's
   --  catalogue entry 9) while a protection commands the brake
   Runaway_Shown        : Boolean := False;

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
   --  the tunnel stopping area sent last (MSG_STATUS, 5.18.8)
   Status_Tunnel_Sent : EVC_Track_Conditions.Tunnel_T;
   --  the radio indication sent last (MSG_STATUS, 3.5.7, phase E5)
   Status_Radio_Sent : EVC_Bytes.Byte := 0;
   --  5.20: an item of the information for an external function was
   --  sent in the last cycle (the TIU track condition output)
   TC_Sent : Boolean := False;
   --  5.17: the train configuration of the train interface seen last
   --  (EVC_Ports, TIU input 13), whether one was seen since power-up
   Config_Last : EVC_Bytes.Byte := 0;
   Config_Seen : Boolean := False;

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
      Snapshot := S;
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
      EVC_Mission.Set_For_Test
        (Mode,
         (Mode        => Mode,
          Level_Valid => True,
          Level       => Level,
          Standstill  => EVC_Odometry.Standstill,
          Desk_Open   => False,
          Non_Leading => False,
          Sense       => EVC_Position.Orientation,
          V_NVSTFF    => EVC_National_Values.Current.Values.V_NVSTFF,
          D_NVSTFF    => EVC_National_Values.Current.Values.D_NVSTFF,
          Session_Open => EVC_Radio.In_Communication));
   end Set_Mode_For_Test;

   procedure Count (Counter : in out Natural) is
   begin
      if Counter < Natural'Last then
         Counter := Counter + 1;
      end if;
   end Count;

   --  The power-up of Initialise and Power_Up: everything cleared but the
   --  store of the data kept over No Power
   procedure Start is
   begin
      Failed_Flag := False;
      Kept_Pending := False;
      --  SUBSET-026 4.4.4.1.1: the equipment is in No Power until it is
      --  powered; the first cycle takes the transition NP -> SB
      Current_Mode := M_NP;
      --  a new on-board: nothing is stored, the level is "unknown" and
      --  the start of mission asks the driver for it (EVC_Levels.Clear
      --  below, 5.4.3.2 D2); the store of the data kept over No Power is
      --  empty (Power_Up keeps them)
      Cycle_Count := 0;
      Clock_Ms := 0;
      Reported_Mode := M_NP;
      Latched_Odometer := Standstill_Sample;
      Latched_Odometer_Fresh := False;
      Latched_TIU := (others => False);
      Latched_BTM := (others => (Length => 0, Data => (others => 0)));
      Latched_BTM_Count := 0;
      Latched_RTM := (others => (Session => 1, Length => 0,
                                 Data => (others => 0)));
      Latched_RTM_Count := 0;
      Latched_Events := (others => (Session => 1,
                                    Event => Connection_Set_Up));
      Latched_Event_Count := 0;
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
      Snapshot := (others => <>);
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
      Entering_Shown := 0;
      Runaway_Shown := False;
      Proc_Ctx := (others => <>);
      Ack_For_Protection := False;
      Status_Rev_Sent := False;
      Status_Tunnel_Sent := (others => <>);
      Status_Radio_Sent := 0;
      TC_Sent := False;
      EVC_JRU_Records.Reset;
      Config_Last := 0;
      Config_Seen := False;
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
      --  phase E4: no procedure running, no text message
      EVC_Procedures.Clear;
      EVC_Text_Messages.Clear;
      --  phase E5: no session, no contact, the sessions of the
      --  installation (EVC_Config: two, or one)
      EVC_Radio.Clear (EVC_Config.Current.Radio.Sessions);
      EVC_Sessions.Clear;
      EVC_Radio_Authority.Clear;
      EVC_Outbox.Clear;
   end Start;

   ----------------
   -- Initialise --
   ----------------

   procedure Initialise is
   begin
      Start;
      EVC_Retained.Erase;
   end Initialise;

   --------------
   -- Power_Up --
   --------------

   procedure Power_Up is
      K : EVC_Retained.Kept_T;
   begin
      EVC_Retained.Load (K);
      Start;
      --  4.10 column NP, 4.11: the kept data, invalid; 3.6.4.2.2.1 the
      --  SOLR is the kept LRBG
      if K.Saved then
         if K.Level_Known then
            EVC_Levels.Restore (K.Level, K.Table);
         end if;
         EVC_Position.Restore (K.Position);
         --  phase E5: the RBC contact information, to be revalidated
         EVC_Radio.Restore_Contact (K.RBC);
         Kept_Pending := True;
      end if;
   end Power_Up;

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

   --  An RTM input of the documented shape (EVC_Ports): a connection
   --  event or a message, latched with its session for the next cycle
   procedure Latch_RTM (Payload : EVC_Bytes.Byte_Array)
     with Global => (In_Out => (Latched_RTM, Latched_RTM_Count,
                                Latched_Events, Latched_Event_Count,
                                Overflow_Count)),
          Pre => Valid_RTM_Input (Payload)
   is
      S : constant RTM_Session_T := RTM_Session (Payload);
   begin
      if Valid_RTM_Event (Payload) then
         if Latched_Event_Count < RTM_Latch_Size then
            Latched_Event_Count := Latched_Event_Count + 1;
            Latched_Events (Latched_Event_Count) :=
              (Session => S, Event => RTM_Event (Payload));
         else
            Count (Overflow_Count (RTM));
         end if;
      elsif Latched_RTM_Count < RTM_Latch_Size then
         declare
            --  the message: after the tag and the session when tagged
            First : constant Positive :=
              (if Payload (Payload'First) < RTM_Tag_First then Payload'First
               else Payload'First + RTM_Tagged_Header);
            Length : constant Natural := Payload'Last - First + 1;
         begin
            pragma Assert
              (Valid_RTM (Payload (First .. Payload'Last)));
            Latched_RTM_Count := Latched_RTM_Count + 1;
            Latched_RTM (Latched_RTM_Count).Session := S;
            Latched_RTM (Latched_RTM_Count).Length := Length;
            Latched_RTM (Latched_RTM_Count).Data (1 .. Length) :=
              Payload (First .. Payload'Last);
         end;
      else
         Count (Overflow_Count (RTM));
      end if;
   end Latch_RTM;

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
            Latch_RTM (Payload);
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

   --  1a. The telegrams latched since the last cycle, in the order the
   --  BTM delivered them: parsed (EVC_Received, chapter 7, 8), those
   --  accepted recorded on the JRU port (event 2, the balise group,
   --  NID_C and NID_BG) and handed, with the stamp of their balise, to
   --  the position (EVC_Position, 3.6, which takes them at its next
   --  Update: the reference and the confidence interval do not change
   --  here); 3.17.3.5, 4.6.3 [65]: a telegram of a system version not
   --  supported noted for the procedures
   procedure Read_Telegrams
     with Global => (Input  => (Latched_BTM, Cycle_Count, Clock_Ms,
                                EVC_Odometry.State),
                     In_Out => (Latched_BTM_Count, EVC_Received.Store,
                                EVC_Outbox.Queue, EVC_Position.State,
                                EVC_Procedures.State)),
          Post => EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old
   is
      T_Status : ETCS_Telegram.Status_T;
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
   end Read_Telegrams;

   --  1b. Phase E5: the connection events of the RTM port latched since
   --  the last cycle, in their order, to the session and link half
   procedure Read_Radio_Events
     with Global => (Input  => (Latched_Events, Clock_Ms),
                     In_Out => (Latched_Event_Count, EVC_Sessions.State,
                                EVC_Radio.State))
   is
   begin
      for I in 1 .. Latched_Event_Count loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         EVC_Sessions.Take_Event (Latched_Events (I).Session,
                                  Latched_Events (I).Event,
                                  EVC_Radio.Time_Ms_T (Clock_Ms));
      end loop;
      Latched_Event_Count := 0;
   end Read_Radio_Events;

   --  1c. The radio messages latched since the last cycle, in the order
   --  the RTM delivered them: parsed (EVC_Received, chapter 8), those
   --  accepted recorded on the JRU port (event 3: NID_MESSAGE, L_MESSAGE)
   --  and given, with their session, to the session and link half; the
   --  messages it passes go on to the authority half (phase E5)
   procedure Read_Radio_Messages
     with Global => (Input  => (Latched_RTM, Cycle_Count, Clock_Ms),
                     In_Out => (Latched_RTM_Count, EVC_Received.Store,
                                EVC_Outbox.Queue, EVC_Sessions.State,
                                EVC_Radio.State,
                                EVC_Radio_Authority.State))
   is
      use type EVC_Sessions.Verdict_T;
      M_Status : ETCS_Message.Status_T;
      Verdict  : EVC_Sessions.Verdict_T;
   begin
      for I in 1 .. Latched_RTM_Count loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
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
                  EVC_Sessions.Take_Message
                    (Slot.Session, EVC_Radio.Time_Ms_T (Clock_Ms), Verdict);
                  if Verdict = EVC_Sessions.Pass then
                     EVC_Radio_Authority.Take_Message (Slot.Session);
                  end if;
               end if;
            end if;
         end;
      end loop;
      Latched_RTM_Count := 0;
   end Read_Radio_Messages;

   --  1d. Phase E5, 4.8.5: the messages the transition buffer of the
   --  session half releases, parsed again (in the first slot of the
   --  latch, free now) and given to the authority half as received in
   --  this cycle; at most RTM_Latch_Size in a cycle
   procedure Read_Released_Messages
     with Global => (In_Out => (Latched_RTM, EVC_Received.Store,
                                EVC_Sessions.State,
                                EVC_Radio_Authority.State))
   is
      M_Status : ETCS_Message.Status_T;
      S        : RTM_Session_T;
      Last     : Natural;
   begin
      for I in 1 .. RTM_Latch_Size loop
         pragma Loop_Invariant (True);
         exit when not EVC_Sessions.Has_Released;
         EVC_Sessions.Take_Released (S, Latched_RTM (1).Data, Last);
         EVC_Received.Receive_Message (Latched_RTM (1).Data (1 .. Last),
                                       M_Status);
         if M_Status = ETCS_Message.Accepted then
            EVC_Radio_Authority.Take_Message (S);
         end if;
      end loop;
   end Read_Released_Messages;

   --  1. Read the ports: take the inputs latched since the last cycle,
   --  parse the telegrams and radio messages (EVC_Received) and record
   --  those accepted on the JRU port; hand the telegrams accepted, with
   --  the stamp of their balise, to the position
   procedure Read_Ports
     with Global => (Input  => (Latched_Odometer, Latched_TIU, Latched_BTM,
                                Cycle_Count, Clock_Ms,
                                EVC_Odometry.State, Latched_TIU_Value,
                                Latched_TIU_Known, Latched_Events),
                     Output => (Odometer_Now, Odometer_Fresh, TIU_Now,
                                TIU_Value_Now,
                                TIU_Known_Now, Brake_Ack_Now,
                                EVC_Train_Inputs.State),
                     In_Out => (Latched_Odometer_Fresh,
                                Latched_Brake_Ack,
                                Latched_BTM_Count,
                                Latched_RTM, Latched_RTM_Count,
                                Latched_Event_Count, EVC_Received.Store,
                                EVC_Outbox.Queue, EVC_Position.State,
                                EVC_Driver_Requests.State,
                                EVC_Levels.State, EVC_Procedures.State,
                                EVC_Sessions.State,
                                EVC_Radio_Authority.State)),
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
      Read_Telegrams;
      Read_Radio_Events;
      Read_Radio_Messages;
      Read_Released_Messages;
   end Read_Ports;

   --  4.8 (phase E4): the context of the filters in the cycle, for the
   --  information the position takes itself (the linking) and the
   --  information of the procedures and the text messages
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

   --  The mode related speed restriction (3.11.7, 3.11.10) of the mode
   --  of the last cycle, one source (EVC_Procedures.Mode_Speed): the
   --  national values (A.3.2, packet 3) or the speed of the mode profile
   --  the mode was entered with (3.11.7.1.1), of the reversing
   --  supervision information in RV (3.11.7.1.2), in SR the SR mode speed
   --  limit of EVC_Mission (the driver's or V_NVSTFF), under the override
   --  speed while the override is active
   function Mode_Speed return EVC_Supervision_Input.Speed_Cms_T is
     (EVC_Procedures.Mode_Speed
        (Current_Mode, EVC_National_Values.Current.Values,
         EVC_Mission.SR_Speed))
     with Global => (Current_Mode, EVC_Mission.State,
                     EVC_National_Values.State, EVC_Procedures.State);

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
                                EVC_Train_Inputs.State, EVC_Mission.State,
                                EVC_Procedures.State, SDM_Result),
                     In_Out => (SDM_Work, EVC_Stored_Information.State,
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
      --  phase E4: the mode profile of the mode in use is no temporary
      --  EOA (3.12.4.7)
      EVC_Movement_Authority.Set_Mode_In_Use
        (case Current_Mode is
            when M_OS   => 0,
            when M_SH   => 1,
            when M_LS   => 2,
            when others => 3);
      --  the mode related speed restriction (3.11.7, Mode_Speed); the
      --  status of the special brakes for the speed restrictions to
      --  ensure a permitted braking distance (3.11.11.4); the mode and
      --  the inputs of 4.8 and the SR distance (phase E4; in Trip, 4.8.4
      --  refuses the MA and the track description, 5.11.2.2 A035); the
      --  virtual limits of the last cycle (5.18.4.2, 5.18.8.3)
      --  the profile of the work area of the supervision (EVC_SDM.Step
      --  builds it anew before it reads it) as the work area of the PBD
      EVC_Stored_Information.Evaluate
        (Unsigned_64 (Clock_Ms),
         Mode_Speed,
         Work           => SDM_Work.Profile,
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
            SR_End      => SR_End),
         Virtual_Last   => SDM_Result.Virtual);
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

   --  The snapshot in use (Snapshot): the stored information's one, taken
   --  in place, unless the tests set theirs
   procedure Take_Snapshot
     with Global => (Input  => (Test_Snapshot_Set,
                                EVC_Stored_Information.State),
                     In_Out => Snapshot)
   is
   begin
      if not Test_Snapshot_Set then
         EVC_Stored_Information.Get_Current (Snapshot);
      end if;
   end Take_Snapshot;

   --  4. Speed and distance monitoring (3.13, EVC_SDM) and the brake
   --  commands (3.14, EVC_Brake_Commands) on the snapshot the stored
   --  information built at the third step (or the tests' one), with the
   --  inputs of the train interface and the driver's acknowledgement of
   --  the cycle
   procedure Monitor_Speed_And_Distance (Dt_Ms : Natural)
     with Global => (Input  => (Test_Snapshot_Set, TIU_Now,
                                TIU_Value_Now, TIU_Known_Now, Brake_Ack_Now,
                                Current_Mode, EVC_Levels.State,
                                EVC_Position.State,
                                EVC_Stored_Information.State),
                     In_Out => (Snapshot, SDM_Work, SDM_State, Brake_State,
                                Brake_Output),
                     Output => (SDM_Result, Speed_State,
                                Ack_For_Protection))
   is
      procedure Run (S : EVC_Supervision_Input.Snapshot_T) is
         Controller : constant EVC_Brake_Commands.Controller_T :=
           Controller_Now;
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
                         (EVC_Position.Orientation)),
            --  4.4.18.1.6: in RV the emergency brake for the SBI
            EB_Instead_Of_SB => Current_Mode = M_RV);
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
      Take_Snapshot;
      Run (Snapshot);
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
          D_NVSTFF    => NV.D_NVSTFF,
          Session_Open => EVC_Radio.In_Communication));
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

   --  Phase E5: the context of the cycle for the halves of the radio
   function Radio_Context return EVC_Radio.Context_T is
     ((Mode => Current_Mode, Now_Ms => Unsigned_64 (Clock_Ms)))
     with Global => (Current_Mode, Clock_Ms);

   --  5a. Phase E5, after the levels and the mission: the session and
   --  link half, then the authority half (the sessions, the reports and
   --  requests to make, the conditions of 4.6.3 they own)
   procedure Evaluate_Radio
     with Global => (Input  => (Current_Mode, Clock_Ms),
                     In_Out => (EVC_Sessions.State,
                                EVC_Radio_Authority.State))
   is
   begin
      EVC_Sessions.Evaluate (Radio_Context);
      EVC_Radio_Authority.Evaluate (Radio_Context);
   end Evaluate_Radio;

   --  6b. Phase E5: the mode changed (after the mode machine)
   procedure Radio_Mode_Changed (From, To : Mode_T)
     with Global => (In_Out => (EVC_Sessions.State,
                                EVC_Radio_Authority.State))
   is
   begin
      EVC_Sessions.Mode_Changed (From, To);
      EVC_Radio_Authority.Mode_Changed (From, To);
   end Radio_Mode_Changed;

   --  5b. Phase E4, the procedures (EVC_Procedures, EVC_Text_Messages),
   --  after the levels and the mission: the context of the cycle, the
   --  conditions of 4.6.3 they own
   procedure Run_Procedures
     with Global => (Input  => (Current_Mode, TIU_Value_Now, TIU_Known_Now,
                                Odometer_Now, Brake_Ack_Now,
                                Ack_For_Protection, Clock_Ms,
                                SDM_Result, Test_Snapshot_Set,
                                EVC_Stored_Information.State,
                                EVC_Position.State,
                                EVC_Origins.State,
                                EVC_Driver_Requests.State,
                                EVC_Train_Data.State,
                                EVC_Track_Conditions.State,
                                EVC_Levels.State,
                                EVC_Train_Inputs.State,
                                EVC_Odometry.State,
                                EVC_Movement_Authority.State,
                                EVC_National_Values.State),
                     Output => Proc_Ctx,
                     In_Out => (Snapshot,
                                EVC_Procedures.State, EVC_Text_Messages.State,
                                EVC_Track_Description.State,
                                EVC_Mission.State,
                                Config_Last, Config_Seen))
   is
      --  the snapshot in use, taken by the first statement
      S : EVC_Supervision_Input.Snapshot_T renames Snapshot;
      --  5.17.2.2 E0: the train configuration changed
      Config : constant EVC_Bytes.Byte :=
        TIU_Value_Now (Train_Configuration);
      Config_Changed : constant Boolean :=
        TIU_Known_Now (Train_Configuration) and then Config_Seen
        and then Config /= Config_Last;
   begin
      Take_Snapshot;
      if TIU_Known_Now (Train_Configuration) then
         Config_Last := Config;
         Config_Seen := True;
      end if;
      Proc_Ctx :=
        (Mode              => Current_Mode,
         Level_Valid       => EVC_Levels.Valid,
         Level             => EVC_Levels.Level,
         --  the level transitions of the cycle (EVC_Levels, 5.10)
         Level_Switched    => EVC_Levels.Switched_To (L1)
                              or else EVC_Levels.Switched_To (L2),
         Switched_To_L1    => EVC_Levels.Switched_To (L1),
         Desk_Open         => EVC_Train_Inputs.Desk_Open,
         Passive_Shunting  => EVC_Train_Inputs.Passive_Shunting_Permitted,
         Controller        => Controller_Now,
         Train_Data_Valid  => EVC_Train_Data.Valid,
         --  the train running number of the start of mission (5.4.2)
         TRN_Valid         => EVC_Mission.TRN_Status = EVC_Mission.Valid,
         Speed_Max         =>
           EVC_Supervision_Input.Speed_Cms_T
             (Natural'Min (Natural (Odometer_Now.V_Max),
                           EVC_Supervision_Input.Speed_Cms_T'Last)),
         Antenna_Offset    =>
           EVC_Position.Front_Offset (EVC_Position.Orientation),
         Brake_Release_Ack => Brake_Ack_Now and then not Ack_For_Protection,
         Now_Ms            => Unsigned_64 (Clock_Ms),
         TD_Change         => Config_Changed,
         TD_Validation     => (Config and TIU_Config_Validation) /= 0,
         TD_Category       => (Config and TIU_Config_Category) /= 0,
         SR_Distance_Passed => EVC_Mission.SR_Distance_Passed,
         --  the start of mission's proposal comes first (EVC_Mission)
         Mode_Ack          => EVC_Driver_Requests.Mode_Acknowledged
                              and then not EVC_Mission.Ack_Taken,
         Filters           => Acceptance_Context);
      EVC_Procedures.Evaluate (Proc_Ctx, S, SDM_Result);
      --  4.4.11.1.6.5, 4.4.11.1.3.1 a): "Override" selected in SR: the SR
      --  speed limit and distance of the driver are deleted, the national
      --  values apply, the distance counted from here (EVC_Mission)
      if Current_Mode = M_SR and then EVC_Procedures.Condition (37) then
         EVC_Mission.Override_In_SR
           ((Mode        => Current_Mode,
             Level_Valid => EVC_Levels.Valid,
             Level       => EVC_Levels.Level,
             Standstill  => EVC_Odometry.Standstill,
             Desk_Open   => EVC_Train_Inputs.Desk_Open,
             Non_Leading => EVC_Train_Inputs.Non_Leading_Permitted,
             Sense       => EVC_Position.Orientation,
             V_NVSTFF    => EVC_National_Values.Current.Values.V_NVSTFF,
             D_NVSTFF    => EVC_National_Values.Current.Values.D_NVSTFF,
          Session_Open => EVC_Radio.In_Communication));
      end if;
      EVC_Text_Messages.Evaluate
        (Current_Mode, EVC_Levels.Valid, EVC_Levels.Level,
         S.Train.Est_Front, Unsigned_64 (Clock_Ms),
         Taken  => EVC_Acceptance.Accepted (EVC_Acceptance.Text_Message,
                                            Acceptance_Context));
   end Run_Procedures;

   --  Any condition of the list L holds (4.6.1.6: "16, 17, 18" means "16
   --  or 17 or 18")
   function Any_Holds (L : Condition_List_T) return Boolean is
     (for some I in L'Range =>
        L (I) /= 0 and then EVC_Transition_Conditions.Holds (L (I)))
     with Global => (EVC_Driver_Requests.State, EVC_Train_Inputs.State,
                     EVC_Levels.State, EVC_Mission.State,
                     EVC_Odometry.State, EVC_Stored_Information.State,
                     EVC_Movement_Authority.State, EVC_Train_Data.State,
                     EVC_Procedures.State, EVC_Sessions.State,
                     EVC_Radio_Authority.State);

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
                                EVC_Train_Data.State,
                                EVC_Procedures.State,
                                EVC_Sessions.State,
                                EVC_Radio_Authority.State),
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

   --  7a. 4.10: the stored information deleted on entering the mode To,
   --  each with the modes of its row (the track description, the MA, the
   --  mode profile and the signalling related speed restriction, the
   --  track conditions, the linking, the geographical position, the
   --  adhesion factor from the driver); the reference and the confidence
   --  interval of the position stay
   procedure Delete_On_Mode_Entry (To : Mode_T)
     with Global => (In_Out   => (EVC_Track_Description.State,
                                  EVC_Movement_Authority.State,
                                  EVC_Track_Conditions.State,
                                  EVC_Position.State,
                                  EVC_Stored_Information.State),
                     Proof_In => EVC_Odometry.State),
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
   begin
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
   end Delete_On_Mode_Entry;

   --  7b. 4.12: the brake command reasons revoked on entering the mode To
   --  from From: the speed and distance monitoring, the roll away, the
   --  unauthorised direction movement and the standstill protections
   --  (3.14.2, 3.14.3)
   procedure Revoke_Brake_Reasons (From, To : Mode_T)
     with Global => (In_Out => (Brake_State, SDM_State))
   is
   begin
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
   end Revoke_Brake_Reasons;

   --  7. What entering the mode To from From means (phase E4): the data
   --  of 4.10 (the stores, the position, the level, the mission, the
   --  information of the procedures and the text messages), the brake
   --  command reasons of 4.12 (the speed and distance monitoring, the
   --  protections; the levels' own, EVC_Levels; the procedures' and the
   --  text messages' own), the end and the start of mission (5.5.2,
   --  5.4.6), the trip and its reason (5.11, EVC_Procedures)
   procedure Enter_Mode (From, To : Mode_T)
     with Global => (Input  => (EVC_Odometry.State,
                                EVC_National_Values.State,
                                EVC_Train_Inputs.State,
                                Proc_Ctx, Test_Snapshot_Set),
                     In_Out => (Snapshot,
                                EVC_Procedures.State, EVC_Text_Messages.State,
                                EVC_Levels.State, EVC_Mission.State,
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
      --  the procedures and the text messages first: the trip and its
      --  reason, the requests for acknowledgement, their information of
      --  4.10 (the stop shunting on desk opening, the list of balise
      --  groups for the SH area, the reversing information, the text
      --  messages) and their brakes of 4.12
      Take_Snapshot;
      EVC_Procedures.Mode_Changed (From, To, Proc_Ctx, Snapshot);
      EVC_Text_Messages.Mode_Changed (From, To);
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
          D_NVSTFF    => NV.D_NVSTFF,
          Session_Open => EVC_Radio.In_Communication));
      Delete_On_Mode_Entry (To);
      Revoke_Brake_Reasons (From, To);
   end Enter_Mode;

   --  7b. After the mode machine: the brake demand of the procedures in
   --  the mode of the end of the cycle (EVC_Procedures.Finish_Cycle);
   --  3.11.6.4: a trip order (V_MAIN 0) is used in the cycle in level 1
   --  (the trip [18], inhibited by the override, 5.8.3.6), and kept in
   --  the other levels until the level switches to 1 ([67])
   procedure Finish_Procedures
     with Global => (Input  => (Current_Mode, Proc_Ctx, Test_Snapshot_Set,
                                EVC_Stored_Information.State,
                                EVC_Levels.State),
                     In_Out => (Snapshot, EVC_Procedures.State,
                                EVC_Movement_Authority.State))
   is
   begin
      Take_Snapshot;
      EVC_Procedures.Finish_Cycle (Proc_Ctx, Current_Mode, Snapshot);
      if EVC_Movement_Authority.Trip_Ordered
        and then EVC_Levels.Valid and then EVC_Levels.Level = L1
      then
         EVC_Movement_Authority.Clear_Trip_Order;
      end if;
   end Finish_Procedures;

   --  JRU events of phase E4 (EVC_Ports): 40 the levels, 41 the mission
   --  (the modes and levels), 23 the procedures, 24 the text messages
   JRU_Levels  : constant := EVC_Ports.JRU_Levels;
   JRU_Mission : constant := EVC_Ports.JRU_Mission;

   ---------------------------------------------------------------------
   --  8. The outputs of the cycle (Produce_Outputs), in the order they
   --  are sent: the order of the records within a cycle is part of the
   --  goldens
   ---------------------------------------------------------------------

   --  8a. JRU: the mode changed since the last report (event 1); the
   --  events of the levels (5.10, event 40) and of the mission (5.4,
   --  5.5, event 41) of the cycle (phase E4)
   procedure Record_Mode_Levels_Mission
     with Global => (Input  => (Current_Mode, Cycle_Count, Clock_Ms,
                                EVC_Levels.State, EVC_Mission.State),
                     In_Out => (Reported_Mode, EVC_Outbox.Queue))
   is
   begin
      if Current_Mode /= Reported_Mode then
         EVC_Outbox.Put
           (JRU, JRU_Record (JRU_Mode_Change,
                             Mode_T'Pos (Current_Mode),
                             Level_Status_T'Pos (EVC_Levels.Status),
                             Level_T'Pos (EVC_Levels.Level)));
         Reported_Mode := Current_Mode;
      end if;
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
   end Record_Mode_Levels_Mission;

   --  8b. DMI: the system status messages of the modes and of the
   --  protections of 3.14 (MSG_SYSTEM_STATUS): 4.4.15.1.1.3 the
   --  non-leading operation no longer permitted, 4.4.9.1.4 "Entering FS",
   --  4.4.12.1.7 "Entering OS"; 3.14.2.6, 3.14.3.4, 4.4.7.1.5.4 "Runaway
   --  movement"
   procedure Show_Mode_Indications
     with Global => (Input  => (Current_Mode, Brake_Output,
                                EVC_Mission.State,
                                EVC_Stored_Information.State),
                     In_Out => (Entering_Shown, Runaway_Shown,
                                EVC_Outbox.Queue))
   is
   begin
      --  4.4.15.1.1.3: the driver is informed that the non-leading
      --  operation is no longer permitted and asked to acknowledge it
      --  (the DMI's catalogue entry 35, ended by the acknowledgement)
      if EVC_Mission.NL_No_Longer_Permitted then
         EVC_Outbox.Put (DMI, System_Status_Frame
                                (SS_NL_No_Longer_Permitted,
                                 SS_Event_Start));
      end if;
      --  4.4.9.1.4: in FS, "Entering FS" until SSP and gradient are known
      --  for the whole length of the train (the DMI's catalogue entry 6);
      --  4.4.12.1.7: in OS, "Entering OS" (entry 7) the same (a mode
      --  change ends either on the DMI as well)
      declare
         Not_Covered : constant Boolean :=
           EVC_Stored_Information.MA_On_Board
           and then not EVC_Stored_Information.Train_Covered;
         Entering    : constant EVC_Bytes.Byte :=
           (if Not_Covered and then Current_Mode = M_FS then SS_Entering_FS
            elsif Not_Covered and then Current_Mode = M_OS
            then SS_Entering_OS
            else 0);
      begin
         if Entering /= Entering_Shown then
            if Entering_Shown /= 0 then
               EVC_Outbox.Put (DMI, System_Status_Frame
                                      (Entering_Shown, SS_Event_End));
            end if;
            if Entering /= 0 then
               EVC_Outbox.Put (DMI, System_Status_Frame
                                      (Entering, SS_Event_Start));
            end if;
            Entering_Shown := Entering;
         end if;
      end;
      --  3.14.2.6, 3.14.3.4, 4.4.7.1.5.4: the driver is shown that the
      --  roll away, the unauthorised direction movement or the standstill
      --  protection commands the brake ("Runaway movement", the DMI's
      --  entry 9, Table 68: 3.14.2.4, 3.14.3.2), until its revocation
      --  (3.14.1.5)
      if Brake_Output.Protection /= Runaway_Shown then
         EVC_Outbox.Put (DMI, System_Status_Frame
                                (SS_Runaway_Movement,
                                 (if Brake_Output.Protection
                                  then SS_Event_Start else SS_Event_End)));
         Runaway_Shown := Brake_Output.Protection;
      end if;
   end Show_Mode_Indications;

   --  8c. DMI: the mode and the level (MSG_MODE_LEVEL; 4.4.2.1: a clear
   --  indication of the mode when the desk is open); 4.7.2: the
   --  acknowledgement of a mode proposed (the start of mission, 5.4.3.2
   --  S22 to S24) or asked by a procedure (5.7, 5.9, 5.11, 5.13, 5.19; the
   --  start of mission's first, which takes the driver's acknowledgement
   --  first), the level transition announced (5.10.1.3) and its
   --  acknowledgement (5.10.4), "override active" (5.8.3.7)
   procedure Send_Mode_Level
     with Global => (Input  => (Current_Mode, EVC_Levels.State,
                                EVC_Mission.State, EVC_Procedures.State),
                     In_Out => EVC_Outbox.Queue)
   is
   begin
      if Has_Mode_Code (Current_Mode) then
         EVC_Outbox.Put
           (DMI,
            Mode_Level_Frame
              (Current_Mode, EVC_Levels.Status, EVC_Levels.Level,
               Mode_Ack      =>
                 (if EVC_Mission.Proposed
                    and then Has_Mode_Code (EVC_Mission.Proposed_Mode)
                  then Mode_Code (EVC_Mission.Proposed_Mode)
                  elsif EVC_Procedures.Ack_Requested
                    and then Has_Mode_Code (EVC_Procedures.Ack_Mode)
                  then Mode_Code (EVC_Procedures.Ack_Mode)
                  else No_Code),
               Level_Ann     =>
                 (if EVC_Levels.Ack_Asked
                  then Level_Code (Valid, EVC_Levels.Ack_Level)
                  elsif EVC_Levels.Announced
                  then Level_Code (Valid, EVC_Levels.Announced_Level)
                  else No_Code),
               Level_Ann_Ack => EVC_Levels.Ack_Asked,
               Override      => EVC_Procedures.Override_Indicated));
      end if;
   end Send_Mode_Level;

   --  8d. DMI (phase E4): the system status messages of the procedures
   --  (the reason of a trip, 5.11; the reverse movement distances, 5.13;
   --  5.17), the text messages (3.12.3: shown with the hour and the
   --  minute of the on-board time, or removed)
   procedure Send_Procedure_Messages
     with Global => (Input  => (Clock_Ms, EVC_Procedures.State,
                                EVC_Text_Messages.State),
                     In_Out => EVC_Outbox.Queue)
   is
      Seconds : constant Unsigned_64 := Unsigned_64 (Clock_Ms) / 1000;
   begin
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
   end Send_Procedure_Messages;

   --  8e. JRU (phase E4): the records of the procedures of chapter 5
   --  (event 23) and of the text messages (3.12.3, event 24)
   procedure Record_Procedures
     with Global => (Input  => (Cycle_Count, Clock_Ms, EVC_Procedures.State,
                                EVC_Text_Messages.State),
                     In_Out => EVC_Outbox.Queue)
   is
   begin
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
   end Record_Procedures;

   --  8f. DMI: MSG_STATUS. SUBSET-026 3.6.6: the geographical position,
   --  while it is known, and once "unknown" when it stops (the DMI shows
   --  it on request); phase E3: the brake indication (3.14.1.9, 3.14.2.6,
   --  3.14.3.4) and the time to Indication (3.13.10.3.10), whenever they
   --  change; phase E4: the reversing possible (5.13), the tunnel
   --  stopping area (5.18.8). D, Text_SB, Text_EB: the brake demands of
   --  the procedures and of the text messages (phase E4)
   procedure Send_Status (D                : EVC_Procedures.Brake_Demand_T;
                          Text_SB, Text_EB : Boolean)
     with Global => (Input  => (Current_Mode, Clock_Ms, Brake_Output,
                                SDM_Result, EVC_Levels.State,
                                EVC_Procedures.State,
                                EVC_Stored_Information.State,
                                EVC_Position.State),
                     In_Out => (Geo_Sent, Status_Brake_Sent,
                                Status_TTI_Sent, Status_Rev_Sent,
                                Status_Tunnel_Sent, Status_Radio_Sent,
                                EVC_Outbox.Queue))
   is
      --  phase E4: the brakes of the procedures; 3 (DMI 8.2.2.3.4.1)
      --  while only an acknowledgement of a level (5.10.4.2), a mode or
      --  a text is missing; in IS the on-board is isolated from the
      --  brakes (4.4.3.1.1)
      Brake : constant EVC_Bytes.Byte :=
        (if Current_Mode = M_IS then Brake_None
         elsif Brake_Output.Ack_Required or else D.Ack_Required
         then Brake_Ack
         elsif Brake_Output.EB or else Brake_Output.SB
           or else Current_Mode = M_SF or else D.Trip or else D.Other
         then Brake_Applied
         elsif EVC_Sessions.Service_Brake then Brake_Applied
         elsif EVC_Levels.Ack_Brake or else D.Ack_Missing
           or else Text_SB or else Text_EB
         then Brake_Ack_Pending
         else Brake_None);
      TTI   : constant Unsigned_16 :=
        (if SDM_Result.TTI = EVC_SDM.No_TTI then TTI_None
         else Unsigned_16 (SDM_Result.TTI));
      Rev   : constant Boolean := EVC_Procedures.Reversing_Possible;
      --  phase E4, 5.18.8: the tunnel stopping area
      Tun   : constant EVC_Track_Conditions.Tunnel_T :=
        EVC_Stored_Information.Tunnel;
      --  phase E5, 3.5.7: the safe radio connection (EVC_Sessions)
      Radio : constant EVC_Bytes.Byte :=
        EVC_Bytes.Byte (EVC_Sessions.Indication);
      Changed : constant Boolean :=
        Brake /= Status_Brake_Sent or else TTI /= Status_TTI_Sent
        or else Rev /= Status_Rev_Sent
        or else EVC_Track_Conditions."/=" (Tun, Status_Tunnel_Sent)
        or else Radio /= Status_Radio_Sent;
   begin
      if EVC_Position.Geo_Known then
         EVC_Outbox.Put
           (DMI, Status_Frame (Unsigned_32 (EVC_Position.Geo_Metres),
                               Unsigned_64 (Clock_Ms) / 1000,
                               Brake, TTI, Rev,
                               EVC_Bytes.Byte (Tun.State),
                               Unsigned_32 (Tun.Distance_M), Radio));
         Geo_Sent := True;
      elsif Geo_Sent or else Changed then
         EVC_Outbox.Put
           (DMI, Status_Frame (Geo_Unknown,
                               Unsigned_64 (Clock_Ms) / 1000,
                               Brake, TTI, Rev,
                               EVC_Bytes.Byte (Tun.State),
                               Unsigned_32 (Tun.Distance_M), Radio));
         Geo_Sent := False;
      end if;
      Status_Brake_Sent := Brake;
      Status_TTI_Sent := TTI;
      Status_Rev_Sent := Rev;
      Status_Tunnel_Sent := Tun;
      Status_Radio_Sent := Radio;
   end Send_Status;

   --  The train bits of MSG_ONBOARD (dmi_protocol.ads): standstill and
   --  the speed not above the limit for triggering the override (5.8,
   --  Update_Position), the non-leading and passive shunting inputs
   --  (4.4.15, 4.4.20), the "BTM alarm reaction inhibition" (5.22.4.1)
   function Train_Bits return Bits_T is
     ((if Standstill then Train_Standstill else 0)
      or (if Below_Override then Train_Below_Override else 0)
      or (if TIU_Now (Non_Leading_Permitted) then Train_Non_Leading else 0)
      or (if TIU_Now (Passive_Shunting_Permitted)
          then Train_Passive_Shunting else 0)
      or (if EVC_Procedures.BMM_Inhibited then Train_BMM_Inhibition
          else 0))
     with Global => (Standstill, Below_Override, TIU_Now,
                     EVC_Procedures.State);

   --  The national bits of MSG_ONBOARD: no VBC stored (E0), the driver
   --  ID changeable while running (M_NVDERUN) and the adhesion by the
   --  driver (Q_NVDRIVER_ADHES), A.3.2
   function National_Bits return Bits_T is
     (National_VBC_Room
      or (if EVC_National_Values.M_NVDERUN then National_Driver_ID_Running
          else 0)
      or (if EVC_National_Values.Q_NVDRIVER_ADHES then National_Adhesion
          else 0))
     with Global => EVC_National_Values.State;

   --  8g. DMI: MSG_ONBOARD (dmi_protocol.ads) every cycle, from what the
   --  on-board knows: the validity of the level, the position and the
   --  data of the start of mission (5.4), the train and national bits;
   --  the fields of the later phases are 0, "nothing known"
   procedure Send_Onboard
     with Global => (Input  => (Standstill, Below_Override, TIU_Now,
                                EVC_Procedures.State,
                                EVC_National_Values.State,
                                EVC_Levels.State, EVC_Position.State,
                                EVC_Mission.State, EVC_Train_Data.State),
                     In_Out => EVC_Outbox.Queue)
   is
      Onboard : constant Onboard_T :=
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
                         then Data_TRN_Valid else 0)
                     --  phase E5: the RBC contact information
                     or (if EVC_Radio.Contact.Known
                           and then EVC_Radio.Contact.Valid
                         then Data_RBC_Valid else 0),
         --  phase E5: the session, the Train Data acknowledged, an
         --  answer of the RBC awaited in the start of mission
         Session  => EVC_Bytes.Byte (EVC_Sessions.Session_Code),
         RBC      => (if EVC_Sessions.Train_Data_Acknowledged
                      then RBC_TD_Acknowledged else 0),
         Waiting  => (if EVC_Sessions.Awaiting_RBC
                        and then EVC_Mission.SoM_Engaged
                      then 2 else 0),
         Train    => Train_Bits,
         National => National_Bits,
         --  SUBSET-026 5.4.3.2 S0 (DMI Table 49): the mode is SB, the
         --  desk is open and no session with an RBC exists or is being
         --  established, so the start of mission may begin (phase E4:
         --  the desk is the cab status input, EVC_Mission)
         SoM      => (if EVC_Mission.SoM_Engaged then SoM_Possible else 0),
         others   => 0);
   begin
      EVC_Outbox.Put (DMI, Onboard_Frame (Onboard));
   end Send_Onboard;

   --  The commands of the TIU output (EVC_Ports): phase E3 the speed and
   --  distance monitoring and the protections (3.13, 3.14); phase E4 the
   --  service brake of 5.10.4.2 (the levels), in SF the emergency brake,
   --  permanently (4.4.5.1.2), the brakes of the procedures and of the
   --  text messages (D, Text_SB, Text_EB); in IS no command (4.4.3.1.1)
   function TIU_Commands (D                : EVC_Procedures.Brake_Demand_T;
                          Text_SB, Text_EB : Boolean)
     return EVC_Bytes.Byte
   is (if Current_Mode = M_IS then 0
       else (if Brake_Output.EB or else Current_Mode = M_SF
                or else D.EB or else Text_EB
             then TIU_EBC else 0)
            or (if Brake_Output.SB or else EVC_Levels.Ack_Brake
                   or else D.SB or else Text_SB
                   or else EVC_Sessions.Service_Brake
                then TIU_SBC else 0)
            or (if Brake_Output.TCO then TIU_TCO else 0))
     with Global => (Current_Mode, Brake_Output, EVC_Levels.State,
                     EVC_Sessions.State);

   --  The reasons of the TIU output, each its bit (EVC_Ports), the same
   --  sources as TIU_Commands; none in IS (4.4.3.1.1)
   function TIU_Reasons (D                : EVC_Procedures.Brake_Demand_T;
                         Text_SB, Text_EB : Boolean)
     return TIU_Reasons_T
   is (if Current_Mode = M_IS then 0
       else (if Brake_Output.Reasons (EVC_Brake_Commands.Speed_Distance)
             then TIU_Reason_Speed_Distance else 0)
            or (if Brake_Output.Reasons
                     (EVC_Brake_Commands.Service_Brake_Failed)
                then TIU_Reason_SB_Failed else 0)
            or (if Brake_Output.Reasons (EVC_Brake_Commands.Roll_Away)
                then TIU_Reason_Roll_Away else 0)
            or (if Brake_Output.Reasons (EVC_Brake_Commands.Direction)
                then TIU_Reason_Direction else 0)
            or (if Brake_Output.Reasons
                     (EVC_Brake_Commands.Standstill_Supervision)
                then TIU_Reason_Standstill else 0)
            or (if EVC_Levels.Ack_Brake then TIU_Reason_Level_Ack
                else 0)
            or (if Current_Mode = M_SF then TIU_Reason_Failure else 0)
            or (if D.Trip then TIU_Reason_Trip else 0)
            or (if D.Ack_Missing or else Text_SB or else Text_EB
                then TIU_Reason_Ack_Missing else 0)
            or (if D.Other then TIU_Reason_Procedure else 0))
     with Global => (Current_Mode, Brake_Output, EVC_Levels.State);

   --  8h. The speed and distance monitoring and the brake commands
   --  (phase E3, 3.13, 3.14): MSG_SPEED_STATE every cycle; the JRU records
   --  of what changed (events 20 the brake commands, 21 the supervision,
   --  22 an overrun of the EOA or the SvL); the commands to the train
   --  interface (the TIU output) when they change, and every cycle while
   --  a command is given. D, Text_SB, Text_EB: as Send_Status.
   procedure Send_Supervision
     (D                : EVC_Procedures.Brake_Demand_T;
      Text_SB, Text_EB : Boolean)
     with Global => (Input  => (Current_Mode, Cycle_Count, Clock_Ms,
                                SDM_Result, Brake_Output, Speed_State,
                                EVC_Levels.State),
                     In_Out => (TIU_Sent, TIU_Reasons_Sent,
                                Supervision_Reported, Overrun_Reported,
                                EVC_Outbox.Queue))
   is
      Commands : constant EVC_Bytes.Byte :=
        TIU_Commands (D, Text_SB, Text_EB);
      Why      : constant TIU_Reasons_T :=
        TIU_Reasons (D, Text_SB, Text_EB);
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
           (JRU, JRU_Record
                   (JRU_Brake_Commands,
                    Commands
                    or EVC_Bytes.Byte (Shift_Left (Shift_Right (Why, 8),
                                                   3) and 16#F8#),
                    EVC_Bytes.Byte (Why and 16#FF#),
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
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         if (Overrun and Bit) /= 0
           and then (Overrun_Reported and Bit) = 0
         then
            EVC_Outbox.Put (JRU, JRU_Record (JRU_Overrun, Bit, 0, 0));
         end if;
      end loop;
      Overrun_Reported := Overrun;
      if Commands /= 0 or else Commands /= TIU_Sent
        or else Why /= TIU_Reasons_Sent
      then
         EVC_Outbox.Put (TIU, TIU_Output (Commands, Why));
      end if;
      TIU_Sent := Commands;
      TIU_Reasons_Sent := Why;
   end Send_Supervision;

   --  The second TIU output, the information for an external function
   --  (5.20, EVC_Ports): header, then per item kind, id, the distances to
   --  its start and its end, its value
   subtype TIU_TC_Frame_T is EVC_Bytes.Byte_Array (1 .. TIU_Out_Max_Length);

   --  5.20.2.4: a distance, cm, within the i32 range below TIU_TC_None,
   --  or TIU_TC_None when Present is False, little endian at Last + 1
   procedure Put_I32 (Frame   : in out TIU_TC_Frame_T;
                      Last    : in out Natural;
                      Present : Boolean;
                      V       : EVC_Distances.Dist_T)
     with Global => null,
          Pre  => Last <= TIU_Out_Max_Length - 4,
          Post => Last = Last'Old + 4
   is
      C : constant Integer_64 :=
        (if Present
         then Integer_64'Max (-(2**31 - 1),
                              Integer_64'Min (Integer_64 (V),
                                              TIU_TC_None - 1))
         else TIU_TC_None);
      U : constant Unsigned_64 :=
        Unsigned_64 (Unsigned_32'Mod (C));
   begin
      for K in 0 .. 3 loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         Frame (Last + 1 + K) := EVC_Bytes.Byte_Of (U, K);
      end loop;
      Last := Last + 4;
   end Put_I32;

   --  8i. TIU (phase E4, 5.20): the information for an external function
   --  (EVC_Ports, the TIU track condition output), every cycle while an
   --  item is generated and once when none is any more
   procedure Send_External_Info
     with Global => (Input  => EVC_Stored_Information.State,
                     In_Out => (TC_Sent, EVC_Outbox.Queue))
   is
      Info  : constant EVC_Track_Conditions.External_T :=
        EVC_Stored_Information.External_Info;
      Frame : TIU_TC_Frame_T := (others => 0);
      Last  : Natural := TIU_TC_Header_Length;
   begin
      if Info.Count > 0 or else TC_Sent then
         Frame (1) := TIU_TC_Tag;
         Frame (2) := 1;
         Frame (3) := EVC_Bytes.Byte (Natural'Min (Info.Count, TIU_TC_Max));
         for I in 1 .. Natural'Min (Info.Count, TIU_TC_Max) loop
            pragma Loop_Invariant
              (Last = TIU_TC_Header_Length + (I - 1) * TIU_TC_Entry_Length);
            declare
               E : constant EVC_Track_Conditions.External_Item_T :=
                 Info.List (I);
            begin
               Frame (Last + 1) := EVC_Bytes.Byte (E.Kind);
               Frame (Last + 2) := EVC_Bytes.Byte (E.Id);
               Last := Last + 2;
               Put_I32 (Frame, Last, E.Has_Start, E.To_Start);
               Put_I32 (Frame, Last, E.Has_End, E.To_End);
               Frame (Last + 1) := EVC_Bytes.Byte (E.Value mod 256);
               Frame (Last + 2) := EVC_Bytes.Byte (E.Value / 256);
               Last := Last + 2;
            end;
         end loop;
         EVC_Outbox.Put (TIU, Frame (1 .. Last));
      end if;
      TC_Sent := Info.Count > 0;
   end Send_External_Info;

   --  8j. JRU (SUBSET-027 4.2.4.11, 4.2.4.38, 4.2.4.45, EVC_JRU_Records):
   --  the driver's actions of the cycle no other event records, the cab
   --  status received from the train interface when it changed, the
   --  items of the information for the external functions (5.20) that
   --  appeared or changed their phase
   procedure Record_Actions_Cabs_Conditions
     with Global => (Input  => (Cycle_Count, Clock_Ms, TIU_Now,
                                TIU_Known_Now,
                                EVC_Driver_Requests.State,
                                EVC_Stored_Information.State),
                     In_Out => (EVC_JRU_Records.State, EVC_Outbox.Queue))
   is
      use EVC_Driver_Requests;
      use EVC_JRU_Records;
      Code    : EVC_Bytes.Byte;
      Changed : Boolean;
      TC      : TC_Changes_T;
   begin
      for A in Action_T loop
         pragma Loop_Invariant (True);
         if Selected (A) then
            Code := Action_Code (A, Argument (A));
            if Code /= EVC_JRU_Records.No_Code then
               EVC_Outbox.Put
                 (JRU, JRU_Record (JRU_Driver_Action, Code, 0, 0));
            end if;
         end if;
      end loop;
      for K in Ack_Kind_T loop
         pragma Loop_Invariant (True);
         if Acknowledged (K) then
            Code := Ack_Code (K, Ack_Id (K));
            if Code /= EVC_JRU_Records.No_Code then
               EVC_Outbox.Put
                 (JRU, JRU_Record (JRU_Driver_Action, Code, 0, 0));
            end if;
         end if;
      end loop;
      for K in Data_Kind_T loop
         pragma Loop_Invariant (True);
         if Entered (K)
           and then Data_Code (K) /= EVC_JRU_Records.No_Code
         then
            EVC_Outbox.Put
              (JRU, JRU_Record (JRU_Driver_Action, Data_Code (K), 0, 0));
         end if;
      end loop;
      Cab_Status (TIU_Now (Cab_A_Active), TIU_Now (Cab_B_Active),
                  TIU_Known_Now (Cab_A_Active)
                  or else TIU_Known_Now (Cab_B_Active),
                  Changed);
      if Changed then
         EVC_Outbox.Put
           (JRU, JRU_Record (JRU_Cab_Status,
                             (if TIU_Now (Cab_A_Active) then 1 else 0), 1,
                             (if TIU_Now (Cab_B_Active) then 1 else 0)));
      end if;
      Track_Conditions (EVC_Stored_Information.External_Info, TC);
      for I in 1 .. TC.Count loop
         pragma Loop_Invariant (True);
         EVC_Outbox.Put
           (JRU, JRU_Record (JRU_Track_Conditions, TC.List (I).TI,
                             TC.List (I).Phase, TC.List (I).Id));
      end loop;
   end Record_Actions_Cabs_Conditions;

   --  8k. RTM (phase E5): the messages and requests of the session half,
   --  then of the authority half (EVC_Radio.Send), moved to the RTM port
   --  as far as they fit (EVC_Radio.Drain)
   procedure Send_Radio
     with Global => (Input  => (Current_Mode, Clock_Ms),
                     In_Out => (EVC_Sessions.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio.Queue, EVC_Outbox.Queue))
   is
   begin
      EVC_Sessions.Produce (Radio_Context);
      --  3.5.3.7 d), 5.4.3.2 A40, 3.16.3.4.4: the driver informed
      for I in 1 .. EVC_Sessions.Info_Count loop
         pragma Loop_Invariant (True);
         EVC_Outbox.Put (DMI, System_Status_Frame
                                (EVC_Bytes.Byte'Mod
                                   (EVC_Sessions.Info_Code (I)),
                                 SS_Event_Start));
      end loop;
      EVC_Radio_Authority.Produce (Radio_Context);
      EVC_Radio.Drain;
   end Send_Radio;

   --  8. Produce the outputs of the cycle, port by port in this order
   --  (the goldens are their byte stream)
   procedure Produce_Outputs
     with Global => (Input  => (Current_Mode, Cycle_Count, Clock_Ms,
                                Standstill, Below_Override, TIU_Now,
                                TIU_Known_Now,
                                EVC_National_Values.State,
                                EVC_Position.State,
                                SDM_Result, Brake_Output, Speed_State,
                                EVC_Levels.State, EVC_Mission.State,
                                EVC_Train_Data.State,
                                EVC_Stored_Information.State,
                                EVC_Procedures.State,
                                EVC_Text_Messages.State,
                                EVC_Driver_Requests.State),
                     In_Out => (Reported_Mode, Geo_Sent, EVC_Outbox.Queue,
                                EVC_JRU_Records.State,
                                Status_Brake_Sent, Status_TTI_Sent,
                                TIU_Sent, TIU_Reasons_Sent,
                                Supervision_Reported, Overrun_Reported,
                                Entering_Shown, Runaway_Shown,
                                Status_Rev_Sent, Status_Tunnel_Sent,
                                Status_Radio_Sent,
                                TC_Sent, EVC_Sessions.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio.Queue))
   is
      --  phase E4: the brake demands of the procedures and of the text
      --  messages (MSG_STATUS and the TIU output)
      D       : constant EVC_Procedures.Brake_Demand_T :=
        EVC_Procedures.Brake_Demand;
      Text_SB : constant Boolean := EVC_Text_Messages.Service_Brake;
      Text_EB : constant Boolean := EVC_Text_Messages.Emergency_Brake;
   begin
      Record_Mode_Levels_Mission;   -- JRU 1, 40, 41
      Show_Mode_Indications;        -- DMI MSG_SYSTEM_STATUS
      Send_Mode_Level;              -- DMI MSG_MODE_LEVEL
      Send_Procedure_Messages;      -- DMI MSG_SYSTEM_STATUS, MSG_TEXT
      Record_Procedures;            -- JRU 23, 24
      Send_Status (D, Text_SB, Text_EB);  -- DMI MSG_STATUS
      Send_Onboard;                 -- DMI MSG_ONBOARD
      --  DMI MSG_SPEED_STATE, JRU 20 to 22, TIU the commands
      Send_Supervision (D, Text_SB, Text_EB);
      Send_External_Info;           -- TIU the information of 5.20
      Record_Actions_Cabs_Conditions;  -- JRU 11, 38, 45
      Send_Radio;                   -- RTM (phase E5)
   end Produce_Outputs;

   --  4.11.1.1, 4.11.1.3: the data kept over No Power, once the cold
   --  movement detection is known after the power-up: no cold movement,
   --  the train position and the level become valid; a cold movement
   --  detected or the information not available, the table of priority
   --  of the trackside supported levels is deleted and the rest stays
   --  invalid until validated otherwise (the start of mission)
   procedure Revalidate_Kept
     with Global => (Input  => EVC_Odometry.State,
                     In_Out => (Kept_Pending, EVC_Levels.State,
                                EVC_Position.State)),
          Post => EVC_Position.Orientation = EVC_Position.Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old
   is
      use type EVC_Odometry.Cold_T;
   begin
      if Kept_Pending
        and then EVC_Odometry.Cold /= EVC_Odometry.Cold_Unknown
      then
         if EVC_Odometry.Cold = EVC_Odometry.No_Cold_Movement then
            EVC_Levels.Revalidate;
            EVC_Position.Revalidate;
         else
            EVC_Levels.Delete_Table;
         end if;
         Kept_Pending := False;
      end if;
   end Revalidate_Kept;

   --  5.4.3.2 S22, S23, S24 (after E30, E31, E32), 5.4.5.3 a), f), g)
   --  and the table of 5.4.3.3: the start of mission leaves Stand By to
   --  SN, UN, SR (also by override), NL or SH: a position still invalid
   --  is deleted (an invalid position is one kept over No Power, always
   --  referred to an LRBG: EVC_Position.Keep)
   procedure Delete_Invalid_Position (From, To : Mode_T)
     with Global => (In_Out   => EVC_Position.State,
                     Proof_In => EVC_Odometry.State),
          Post => EVC_Position.Orientation = EVC_Position.Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then (if EVC_Position.LRBG = EVC_Position.LRBG'Old
                            then EVC_Position.Doubt_Over
                                   = EVC_Position.Doubt_Over'Old
                                 and then EVC_Position.Doubt_Under
                                   = EVC_Position.Doubt_Under'Old
                            else not EVC_Position.LRBG.Valid)
   is
   begin
      if From = M_SB
        and then To in M_SN | M_UN | M_SR | M_NL | M_SH
        and then EVC_Position.Status = EVC_Position.Invalid
        and then EVC_Position.LRBG.Valid
      then
         EVC_Position.Delete_Position;
      end if;
   end Delete_Invalid_Position;

   --  4.10 column NP: what is kept over No Power, as it is at the end of
   --  each cycle (EVC_Retained)
   procedure Save_Retained
     with Global => (Input  => (EVC_Levels.State, EVC_Position.State,
                                EVC_Odometry.State, EVC_Radio.State),
                     Output => EVC_Retained.State)
   is
      --  every field is set below (phase E5 the last one, the RBC)
      K : EVC_Retained.Kept_T;
   begin
      K.Saved := True;
      K.Level_Known := EVC_Levels.Status /= Unknown;
      K.Level := EVC_Levels.Level;
      K.Table := EVC_Levels.Table;
      EVC_Position.Keep (K.Position);
      --  phase E5: the RBC contact information (EVC_Sessions writes it)
      K.RBC := EVC_Radio.Contact;
      EVC_Retained.Save (K);
   end Save_Retained;

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
      Revalidate_Kept;
      Evaluate_Stored_Information;
      Monitor_Speed_And_Distance (Dt_Ms);
      Evaluate_Modes_And_Levels;
      --  5.17.2.2 E6: the Train Data validated by the driver end the
      --  re-validation the procedures asked
      if EVC_Mission.Train_Data_Validated then
         EVC_Procedures.Train_Data_Revalidated;
      end if;
      Evaluate_Radio;
      Run_Procedures;
      declare
         From : constant Mode_T := Current_Mode;
      begin
         Run_Mode_Machine;
         if Current_Mode /= From then
            Enter_Mode (From, Current_Mode);
            Delete_Invalid_Position (From, Current_Mode);
            Radio_Mode_Changed (From, Current_Mode);
         end if;
      end;
      Finish_Procedures;
      Produce_Outputs;
      Save_Retained;
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
