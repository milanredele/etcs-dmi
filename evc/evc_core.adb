--  ETCS on-board (EVC)
--  Core of the ETCS on-board, implementation.

pragma Unevaluated_Use_Of_Old (Allow);

with Interfaces;   use Interfaces;

with EVC_Core.Records; use EVC_Core.Records;
with EVC_Core.Inputs; use EVC_Core.Inputs;
with EVC_Core.Stored; use EVC_Core.Stored;
with EVC_Core.Monitoring; use EVC_Core.Monitoring;
with EVC_Core.Modes; use EVC_Core.Modes;
with EVC_Core.Outputs; use EVC_Core.Outputs;

with ETCS_Variables;

package body EVC_Core
  with SPARK_Mode => On,
       Refined_State => (State => (Failed_Flag,
                                   Kept_Pending,
                                   Current_Mode,
                                   Cycle_Count,
                                   Clock_Ms, UTC_Known, UTC_Seconds,
                                   Reported_Mode,
                                   General_Ms, General_Version,
                                   General_Level, General_Mode, Started_Up,
                                   Latched_Odometer,
                                   Latched_Odometer_Fresh,
                                   Latched_TIU, Latched_Integrity,
                                   Latched_SCL, Latched_SCL_Fresh,
                                   Latched_BTM,
                                   Latched_BTM_Count,
                                   Latched_BTM_Alarm, BTM_Alarm_Run,
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
                                   TIU_RS_Sent,
                                   Supervision_Reported,
                                   SDM_Shown_Reported,
                                   Overrun_Reported,
                                   Entering_Shown,
                                   Runaway_Shown,
                                   Odometer_Shown,
                                   Unsuitable_Shown,
                                 --  the procedures
                                   Proc_Ctx,
                                   Ack_For_Protection,
                                   Status_Rev_Sent, Status_Slip_Sent,
                                   Status_BMM_Sent, Status_SM_Sent,
                                   Status_Tunnel_Sent,
                                   Status_Radio_Sent,
                                   TC_Sent, Contact_Sent, Version_Sent,
                                   Types_Sent,
                                   Stored_Sent, Values_Sent,
                                   Config_Last, Config_Seen))
is

   use type EVC_Bytes.Byte_Array;

   function Controller_Now return EVC_Brake_Commands.Controller_T is
     (if not TIU_Known_Now (Direction_Controller)
      then EVC_Brake_Commands.Unknown
      else (case TIU_Value_Now (Direction_Controller) is
               when 1      => EVC_Brake_Commands.Forwards,
               when 2      => EVC_Brake_Commands.Backwards,
               when others => EVC_Brake_Commands.Neutral));

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

   procedure Set_UTC (Seconds : Interfaces.Unsigned_32) is
   begin
      UTC_Known := True;
      UTC_Seconds := Seconds;
   end Set_UTC;

   procedure Set_Snapshot_For_Test (S : EVC_Supervision_Input.Snapshot_T) is
   begin
      Snapshot := S;
      Test_Snapshot_Set := True;
   end Set_Snapshot_For_Test;

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
          In_Communication => EVC_Radio.In_Communication,
          --  read by EVC_Mission.Evaluate only
          SR_Authorisations => 0,
          Profile_Ack => False,
          Radio_MAs => 0,
          ID_Running => True));
   end Set_Mode_For_Test;

   procedure Count (Counter : in out Natural) is
   begin
      if Counter < Natural'Last then
         Counter := Counter + 1;
      end if;
   end Count;

   --  The fields of MSG_STATUS sent last: none yet (Start)
   procedure Reset_Status_Sent
     with Global => (Output => (Status_Rev_Sent, Status_Slip_Sent,
                                Status_BMM_Sent, Status_SM_Sent,
                                Status_Tunnel_Sent, Status_Radio_Sent))
   is
   begin
      Status_Rev_Sent := False;
      Status_Slip_Sent := False;
      Status_BMM_Sent := False;
      Status_SM_Sent := 0;
      Status_Tunnel_Sent := (others => <>);
      Status_Radio_Sent := 0;
   end Reset_Status_Sent;

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
      UTC_Known := False;
      UTC_Seconds := 0;
      Reported_Mode := M_NP;
      General_Ms := 0;
      General_Version := 0;
      General_Level := L0;
      General_Mode := M_NP;
      Started_Up := False;
      Latched_Odometer := Standstill_Sample;
      Latched_Odometer_Fresh := False;
      Latched_TIU := (others => False);
      Latched_Integrity := 0;
      Latched_SCL := (others => 0);
      Latched_SCL_Fresh := False;
      Latched_BTM := (others => (Length => 0, Data => (others => 0)));
      Latched_BTM_Count := 0;
      Latched_BTM_Alarm := False;
      BTM_Alarm_Run := (others => <>);
      Latched_RTM := (others => (Session => 1, Length => 0,
                                 Data => (others => 0)));
      Latched_RTM_Count := 0;
      Latched_Events := (others => (Session => 1,
                                    Event => Connection_Set_Up,
                                    RBC => EVC_Radio.No_RBC));
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
      TIU_RS_Sent := 0;
      Supervision_Reported := No_Supervision;
      SDM_Shown_Reported := No_SDM_Shown;
      Overrun_Reported := 0;
      Entering_Shown := 0;
      Runaway_Shown := False;
      Odometer_Shown := False;
      Unsuitable_Shown := (others => False);
      Proc_Ctx := (others => <>);
      Ack_For_Protection := False;
      Reset_Status_Sent;
      TC_Sent := False;
      Contact_Sent := EVC_Radio.No_Contact;
      Version_Sent := 16#FF#;
      Types_Sent := False;
      Stored_Sent := False;
      Values_Sent := (others => 0);
      EVC_JRU_Records.Reset;
      Config_Last := 0;
      Config_Seen := False;
      EVC_Received.Clear;
      EVC_Position.Clear;
      --  the installation: the antenna of the configuration
      EVC_Position.Set_Antenna (EVC_Config.Current.Antenna_To_Cab_A,
                                EVC_Config.Current.Antenna_To_Cab_B);
      --  nothing stored, no valid Train Data
      EVC_Stored_Information.Clear;
      --  no request, no input, the level and the mission data unknown
      EVC_Driver_Requests.Clear;
      EVC_Train_Inputs.Clear;
      EVC_Levels.Clear;
      EVC_Mission.Clear;
      --  no procedure running, no text message
      EVC_Procedures.Clear;
      EVC_Text_Messages.Clear;
      --  4.4.19.1.4: no marker, no order, no LSSMA shown
      EVC_LS_Display.Clear;
      --  no session, no contact, the sessions of the installation
      --  (EVC_Config: two, or one)
      EVC_Radio.Clear
        (EVC_Config.Current.Radio.Sessions,
         ETCS_Variables.NID_ENGINE_T (EVC_Config.Current.Radio.Engine_Id));
      EVC_Sessions.Clear;
      EVC_Level_Sessions.Clear;
      EVC_Radio_Authority.Clear;
      --  3.15.9: no Virtual Balise Cover (Power_Up restores them)
      EVC_VBC.Clear;
      EVC_Outbox.Clear;
   end Start;

   procedure Initialise is
   begin
      Start;
      EVC_Retained.Erase;
      --  3.17.2.9.1: nothing kept, the highest supported version
      EVC_System_Version.Restore (False, 0);
   end Initialise;

   procedure Power_Up is
      K : EVC_Retained.Kept_T;
   begin
      EVC_Retained.Load (K);
      Start;
      --  3.17.2.9, 3.17.2.9.1: the version operated before No Power, or
      --  the highest supported one when it is lost
      EVC_System_Version.Restore (K.Saved and then K.Version_Known,
                                  K.Operated_X);
      --  4.10 column NP, 4.11: the kept data, invalid; 3.6.4.2.2.1 the
      --  SOLR is the kept LRBG
      if K.Saved then
         if K.Level_Known then
            EVC_Levels.Restore (K.Level, K.Table);
         end if;
         EVC_Position.Restore (K.Position);
         --  3.18.2.7: the national values applicable before No Power
         --  (Start deleted the set not yet applicable, 3.18.2.9)
         EVC_National_Values.Restore (K.National);
         --  3.15.9.5: the Virtual Balise Covers, applicable again
         EVC_VBC.Restore (K.VBC);
         --  the RBC contact information, to be revalidated
         EVC_Radio.Restore_Contact (K.RBC);
         --  3.5.6.2: the network memorized, no mobile
         --  registered (EVC_Sessions.Network orders the registration)
         EVC_Radio.Set_Network ((Known      => K.Network.Known,
                                 NID_MN     => K.Network.NID_MN,
                                 Registered => False,
                                 Type_Known => K.Network.Type_Known,
                                 Net_Type   => K.Network.Net_Type));
         Kept_Pending := True;
      end if;
   end Power_Up;

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
               if Input.Signal = Train_Integrity then
                  Latched_Integrity := TIU_Value (Payload) + 1;
               elsif Input.Signal = Safe_Consist_Length then
                  Latch_SCL (Payload);
               end if;
            end;
         when DMI =>
            --  the driver's actions and data, decoded
            --  (EVC_Driver_Requests; the isolation, 4.6.3 condition [1],
            --  among them)
            EVC_Driver_Requests.Receive (Payload);
            --  3.14.1.5: the release of a brake acknowledged
            if Is_Brake_Release_Ack (Payload) then
               Latched_Brake_Ack := True;
            end if;
         when BTM =>
            --  parsed when the ports are read, at the next cycle; the
            --  alarm is a state (EVC_Ports)
            if Valid_BTM_Alarm (Payload) then
               Latched_BTM_Alarm := BTM_Alarm_On (Payload);
            elsif Latched_BTM_Count < BTM_Latch_Size then
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

   procedure Tick (Dt_Ms : Natural) is
      L_0 : constant EVC_Location.Anchor_T := EVC_Position.LRBG with Ghost;
      O_0 : constant EVC_Distances.Sense_T := EVC_Position.Orientation
        with Ghost;
      M_0 : constant Boolean := EVC_Position.Manoeuvre_Orientation
        with Ghost;
      Over_0  : constant EVC_Distances.Length_T := EVC_Position.Doubt_Over
        with Ghost;
      Under_0 : constant EVC_Distances.Length_T := EVC_Position.Doubt_Under
        with Ghost;
   begin
      if Failed_Flag then
         return;
      end if;
      Cycle_Count := Cycle_Count + 1;
      Clock_Ms := Clock_Ms + Time_Ms_T (Dt_Ms);

      Report_Configuration;
      Read_Ports;
      Update_Position;
      Adjust_For_Manoeuvre;
      --  3.6.4.1.2 up to here: against the same LRBG, orientation and
      --  Supervised Manoeuvre the odometer's part of the confidence
      --  interval did not shrink
      pragma Assert
        (if EVC_Position.LRBG = L_0
           and then EVC_Position.Orientation = O_0
           and then EVC_Position.Manoeuvre_Orientation = M_0
         then EVC_Position.Doubt_Over >= Over_0
              and then EVC_Position.Doubt_Under >= Under_0);
      Revalidate_Kept;
      Take_Radio_Linking;
      Evaluate_Stored_Information;
      Take_Held_Linking;
      Monitor_Speed_And_Distance (Dt_Ms);
      Evaluate_Modes_And_Levels;
      Release_Transition_Buffer;
      Release_LS_Held;
      Take_Radio_Geo;
      --  5.17.2.2 S6 -> A7: the Train Data validated by the driver end the
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
            --  4.4.19.1.4.6, 4.10
            EVC_LS_Display.Mode_Changed (From, Current_Mode);
         end if;
      end;
      Finish_Procedures;
      Supervise_BTM_Alarm;
      Sync_Train_Length;
      --  4.4.19.1.4: the LSSMA of the cycle's snapshot in its mode
      EVC_LS_Display.Step (Snapshot, Current_Mode, Unsigned_64 (Clock_Ms));
      Produce_Outputs;
      Save_Retained;
   end Tick;

   procedure Take_Outputs (Buffer : out EVC_Bytes.Byte_Array;
                           Last   : out Natural)
   is
   begin
      --  after Enter_Failure the outbox holds at most the record of the
      --  fault: the cycle and the inputs put nothing more
      EVC_Outbox.Take (Buffer, Last);
   end Take_Outputs;

   procedure Enter_Failure is
   begin
      Failed_Flag := True;
      if Transition_Exists (Current_Mode, M_SF) then
         Current_Mode := M_SF;
      end if;
      EVC_Outbox.Clear;
      if Current_Mode in M_SL | M_NL | M_PS then
         Record_Fault;
      end if;
   end Enter_Failure;

end EVC_Core;
