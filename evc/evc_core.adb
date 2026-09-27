--  ETCS on-board (EVC)
--  Core of the ETCS on-board, implementation.

with ETCS_Message;
with ETCS_Telegram;
with ETCS_Variables;
with EVC_DMI_Port; use EVC_DMI_Port;
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
                                   Latched_TIU,
                                   Latched_Isolation,
                                   Latched_BTM,
                                   Latched_BTM_Count,
                                   Latched_RTM,
                                   Latched_RTM_Count,
                                   Odometer_Now,
                                   TIU_Now,
                                   Isolation_Now,
                                   Standstill,
                                   Below_Override,
                                   National_Values,
                                   Accepted_Count,
                                   Rejected_Count,
                                   Overflow_Count))
is

   use type EVC_Bytes.Byte_Array;
   use type ETCS_Message.Status_T;
   use type ETCS_Telegram.Status_T;

   ---------------------------------------------------------------------
   --  National values: those E0 uses. Until the trackside gives others
   --  (packet 3, phase E4) they are the default values of SUBSET-026
   --  A.3.2.
   ---------------------------------------------------------------------

   type National_Values_T is record
      --  V_NVALLOWOVTRP, the speed limit for triggering the override
      V_NVALLOWOVTRP   : Speed_Cms_T;
      --  M_NVDERUN, change of driver ID permitted while running
      M_NVDERUN        : Boolean;
      --  Q_NVDRIVER_ADHES, modification of adhesion factor by driver
      Q_NVDRIVER_ADHES : Boolean;
   end record;

   Default_National_Values : constant National_Values_T :=
     (V_NVALLOWOVTRP   => 0,       -- 0 km/h
      M_NVDERUN        => True,    -- Yes
      Q_NVDRIVER_ADHES => False);  -- Not allowed

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
   TIU_Now       : TIU_Signals_T := (others => False);
   Isolation_Now : Boolean := False;

   --  What the position step knows of the movement (Update_Position):
   --  the train stands still, its speed is not above the limit for
   --  triggering the override function
   Standstill     : Boolean := True;
   Below_Override : Boolean := True;

   National_Values : National_Values_T := Default_National_Values;

   Accepted_Count : Counts_T := (others => 0);
   Rejected_Count : Counts_T := (others => 0);
   Overflow_Count : Counts_T := (others => 0);

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
      Latched_TIU := (others => False);
      Latched_Isolation := False;
      Latched_BTM := (others => (Length => 0, Data => (others => 0)));
      Latched_BTM_Count := 0;
      Latched_RTM := (others => (Length => 0, Data => (others => 0)));
      Latched_RTM_Count := 0;
      Odometer_Now := Standstill_Sample;
      TIU_Now := (others => False);
      Isolation_Now := False;
      Standstill := True;
      Below_Override := True;
      National_Values := Default_National_Values;
      Accepted_Count := (others => 0);
      Rejected_Count := (others => 0);
      Overflow_Count := (others => 0);
      EVC_Received.Clear;
      EVC_Outbox.Clear;
   end Initialise;

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
         when TIU =>
            declare
               Input : constant TIU_Input_T := To_TIU (Payload);
            begin
               Latched_TIU (Input.Signal) := Input.Value;
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

   --  1. Read the ports: take the inputs latched since the last cycle,
   --  parse the telegrams and radio messages (EVC_Received) and record
   --  those accepted on the JRU port
   procedure Read_Ports
     with Global => (Input  => (Latched_Odometer, Latched_TIU, Latched_BTM,
                                Latched_RTM, Cycle_Count, Clock_Ms),
                     Output => (Odometer_Now, TIU_Now, Isolation_Now),
                     In_Out => (Latched_Isolation, Latched_BTM_Count,
                                Latched_RTM_Count, EVC_Received.Store,
                                EVC_Outbox.Queue)),
          Post => Isolation_Now = Latched_Isolation'Old
                  and then not Latched_Isolation
   is
      T_Status : ETCS_Telegram.Status_T;
      M_Status : ETCS_Message.Status_T;
   begin
      Odometer_Now := Latched_Odometer;
      TIU_Now := Latched_TIU;
      Isolation_Now := Latched_Isolation;
      Latched_Isolation := False;

      --  the telegrams in the order the BTM delivered them
      for I in 1 .. Latched_BTM_Count loop
         declare
            Slot : BTM_Slot_T renames Latched_BTM (I);
         begin
            if Valid_BTM (Slot.Data (1 .. Slot.Length)) then
               EVC_Received.Receive_Telegram
                 (Slot.Data (1 .. Slot.Length), T_Status);
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

   --  2. Update the position. Phase E2 brings the train position, its
   --  confidence interval and the balise groups (3.4, 3.6); E0 only
   --  knows whether the train moves.
   procedure Update_Position
     with Global => (Input  => (Odometer_Now, National_Values),
                     Output => (Standstill, Below_Override))
   is
   begin
      Standstill := Odometer_Now.V_Max = 0;
      Below_Override := Odometer_Now.V_Max <= National_Values.V_NVALLOWOVTRP;
   end Update_Position;

   --  3. Evaluate the stored information: the data status changes of
   --  4.10 on a mode transition, the validity of the stored data.
   --  Phase E4; E0 stores nothing but the level, which stays "unknown".
   procedure Evaluate_Stored_Information
     with Global => null
   is
   begin
      null;
   end Evaluate_Stored_Information;

   --  4. Speed and distance monitoring (3.13) and the brake commands
   --  (3.14): phase E3. The Standstill Supervision of SB (4.4.7.1.5)
   --  needs the train position of phase E2.
   procedure Monitor_Speed_And_Distance
     with Global => null
   is
   begin
      null;
   end Monitor_Speed_And_Distance;

   --  SUBSET-026 4.6.3: whether the condition of the transition From ->
   --  To holds in this cycle. E0 evaluates two conditions:
   --    [1]  the driver isolates the ERTMS/ETCS on-board equipment,
   --    [4]  the ERTMS/ETCS on-board equipment is powered: always true
   --         while this code runs, so [29] ("NOT powered") never holds.
   function Condition_Holds (From, To : Mode_T) return Boolean is
     (case To is
         when M_IS     => Isolation_Now,
         when M_SB     => From = M_NP,
         when others => False)
     with Global => Isolation_Now;

   --  5. Mode machine: of the transitions of 4.6.2 whose condition
   --  holds, the one of the highest priority (4.6.1.4)
   procedure Run_Mode_Machine
     with Global => (Input => Isolation_Now, In_Out => Current_Mode),
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

   --  6. Produce the outputs of the cycle
   procedure Produce_Outputs
     with Global => (Input  => (Current_Mode, Current_Level_Status,
                                Current_Level, Cycle_Count, Clock_Ms,
                                Standstill, Below_Override, TIU_Now,
                                National_Values),
                     In_Out => (Reported_Mode, EVC_Outbox.Queue))
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
                             Level_Status_T'Pos (Current_Level_Status),
                             Level_T'Pos (Current_Level)));
         Reported_Mode := Current_Mode;
      end if;

      --  DMI: the mode and the level (4.4.2.1: a clear indication of the
      --  mode when the desk is open)
      if Has_Mode_Code (Current_Mode) then
         EVC_Outbox.Put
           (DMI,
            Mode_Level_Frame
              (Current_Mode, Current_Level_Status, Current_Level));
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
      if National_Values.M_NVDERUN then
         National := National or National_Driver_ID_Running;
      end if;
      if National_Values.Q_NVDRIVER_ADHES then
         National := National or National_Adhesion;
      end if;
      Onboard :=
        (Data     => (if Current_Level_Status = Valid then 4 else 0),
         Train    => Train,
         National => National,
         --  SUBSET-026 5.4.3.2 S0 (DMI Table 49): the mode is SB, the
         --  desk is open and no session with an RBC exists or is being
         --  established, so the start of mission may begin. E0 has no
         --  cab signals in its scenarios yet and takes the desk as open.
         SoM      => (if Current_Mode = M_SB then SoM_Possible else 0),
         others   => 0);
      EVC_Outbox.Put (DMI, Onboard_Frame (Onboard));
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

      Read_Ports;
      Update_Position;
      Evaluate_Stored_Information;
      Monitor_Speed_And_Distance;
      Run_Mode_Machine;
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
