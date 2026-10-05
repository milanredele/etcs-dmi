--  ETCS on-board (EVC)
--  The test bench of the SUBSET-076 runner (host only): the on-board
--  (EVC_Core) with the DMI (DMI_Core) in the loop, a train that moves on
--  a straight track, and the capture of everything the on-board outputs.
--
--  One cycle (Cycle_Ms) is: the odometer sample of the train, the
--  balises the antenna passed during the cycle (BTM, stamped with the
--  odometer reading at the balise), the on-board's Tick, its outputs
--  taken (the DMI frames handed to DMI_Core, the TIU and JRU records
--  captured), the DMI's Tick, and the frames the DMI queued for the
--  on-board (MSG_DRIVER_ACTION, MSG_DRIVER_DATA) handed to the
--  on-board's DMI port for its next cycle. The driver acts on the DMI's
--  touch screen (Touch), as the bench page does: the frames the
--  on-board gets are the ones the DMI's dialogues send.
--
--  The track coordinate is the sequence's distance column, cm. The
--  train's reference point is its antenna; the odometer counts from the
--  track origin, moving towards cab A increases it. The odometer is
--  exact; its stated accuracy (over / under) is Accuracy_Per_Mille of
--  the distance travelled.
--
--  The observations: the last value of each DMI frame (the state "at
--  the end"), the same reduced to flags OR-ed over the cycles of the
--  observation window (New_Window starts one: "seen since the input"),
--  the TIU commands, the track condition output, and the JRU records and
--  text / system status events of the window as lists.

pragma Ada_2012;
with Interfaces; use Interfaces;
with EVC_Bytes;

package S076_Bench is

   Cycle_Ms : constant := 100;
   Accuracy_Per_Mille : constant := 10;

   subtype Byte_Array is EVC_Bytes.Byte_Array;

   ---------------------------------------------------------------------
   --  Power and time
   ---------------------------------------------------------------------

   --  Nothing powered, the train at the origin, at standstill, cabs
   --  closed, nothing captured
   procedure Reset;

   --  The on-board and the DMI are powered up (EVC_Core.Initialise,
   --  DMI_Core.Initialise; nothing is kept over No Power)
   procedure Power_On;
   --  Powered down: no cycle of the on-board until Power_On
   procedure Power_Off;
   function Powered return Boolean;
   --  A safety critical fault of the on-board (EVC_Core.Enter_Failure)
   procedure Fault;

   --  Ms of cycles (rounded up to whole cycles): the train moves at its
   --  speed
   procedure Run (Ms : Natural);
   procedure Cycle;
   function Time_Ms return Unsigned_64;

   ---------------------------------------------------------------------
   --  The train
   ---------------------------------------------------------------------

   function Position return Integer_64;      -- the antenna, cm
   function Speed return Natural;            -- cm/s
   --  +1 towards growing distances (cab A ahead), -1 the other way
   function Direction return Integer;
   procedure Set_Speed (Cms : Natural);
   procedure Set_Direction (Dir : Integer);

   --  Move to the track position To_Cm (cm) at Cms (at least 1 cm/s),
   --  in whole cycles; stops at the cycle that reaches it. Max_Ms bounds
   --  the time (a target the train cannot reach in that time is not
   --  reached). The speed after is Cms.
   procedure Move_To (To_Cm : Integer_64; Cms : Positive;
                      Max_Ms : Natural := 3_600_000);

   --  A balise at the track position At_Cm with its telegram of Bits
   --  bits (Data, the first bit in the msb of the first byte): delivered
   --  on the BTM when the antenna passes it, stamped with the odometer
   --  reading at the balise. Cleared when passed.
   procedure Place_Balise (At_Cm : Integer_64; Bits : Natural;
                           Data : Byte_Array);
   function Balises_Pending return Natural;

   --  The on-board's train position quantities (EVC_Position): the
   --  confidence interval over / under the estimated position, cm; the
   --  front end offset of the antenna, cm
   function Doubt_Over return Integer_64;
   function Doubt_Under return Integer_64;
   function Front_Offset return Integer_64;

   ---------------------------------------------------------------------
   --  Other inputs
   ---------------------------------------------------------------------

   --  A TIU input (EVC_Ports: signal 1 .. 13, value)
   procedure TIU_Input (Signal : Natural; Value : Natural);
   --  A frame to the on-board's DMI port (as if from the DMI)
   procedure DMI_Frame (Frame : Byte_Array);
   --  The odometer's stated accuracy per mille from now on
   procedure Set_Accuracy (Per_Mille : Natural);
   --  The odometer states Extra_Cm more over- and under-reading at its
   --  next sample (a degraded measurement)
   procedure Odometer_Error (Extra_Cm : Natural);

   --  The driver touches the DMI screen at X, Y: pointer down, Hold_Ms
   --  of cycles (at least one), pointer up, one cycle
   procedure Touch (X, Y : Natural; Hold_Ms : Natural := 0);

   ---------------------------------------------------------------------
   --  Observations
   ---------------------------------------------------------------------

   --  A new observation window: the flags and lists below restart
   procedure New_Window;
   function Window_Cycles return Natural;

   No_Value : constant := 16#FF#;

   type Bit_Array_T is array (0 .. 63) of Boolean;

   --  The state shown by the on-board's last frames (DMI codes of
   --  dmi_protocol.ads, No_Value when none)
   type State_T is record
      Mode, Level, Mode_Ack, Level_Ann : Natural := No_Value;
      Level_Ann_Ack, Override, TAF     : Boolean := False;
      LSSMA    : Natural := 16#FFFF#;
      --  MSG_ONBOARD
      Onboard  : Byte_Array (1 .. 11) := (others => 0);
      Has_Onboard : Boolean := False;
      --  MSG_STATUS
      Brake, Radio : Natural := 0;
      Adhesion, Reversing, BMM : Boolean := False;
      Tunnel   : Natural := 0;
      Geo_Known : Boolean := False;
      --  MSG_SPEED_STATE
      Has_Speed : Boolean := False;
      V_Cur, V_Perm, V_Target, V_Release, V_SBI, V_Wsl : Natural := 0;
      D_Target : Natural := 0;
      Monitoring, Sup_Status, Flags : Natural := 0;
      --  MSG_PLANNING
      Has_Planning : Boolean := False;
      Plan_MA, Ceiling : Natural := 0;
      Gradients, Speeds, Orders : Natural := 0;
      Indication : Boolean := False;
      --  MSG_TRACK_COND: the kinds shown (1 .. 37 TC, 38 LX)
      TC : Bit_Array_T := (others => False);
      --  MSG_SYSTEM_VERSION
      SV_X, SV_Y : Natural := No_Value;
      --  the TIU commands (EBC, SBC, TCO) and reasons
      EBC, SBC, TCO : Boolean := False;
      Reasons  : Natural := 0;
      --  the track condition output (5.20): the kinds generated
      TIU_TC : Bit_Array_T := (others => False);
   end record;

   function State return State_T;

   --  The flags of the window: a value was shown in at least one cycle
   type Seen_T is record
      Mode, Mode_Ack, Level, Level_Ann, Level_Ann_Ack :
        Bit_Array_T := (others => False);
      Override, Brake_Shown, Brake_Ack, EBC, SBC, TCO,
        Not_EBC, Not_SBC, Not_TCO, Speed_Shown, Planning_Shown,
        Indication, Gradients, Geo, Reversing, Adhesion, Radio_Up,
        Radio_Lost, TAF :
        Boolean := False;
      TC, TIU_TC : Bit_Array_T := (others => False);
   end record;

   function Seen return Seen_T;

   --  JRU records of the window: event and its three bytes
   type JRU_Record_T is record
      Event, B2, B3, B4 : Natural := 0;
      --  event 20: byte 2 of the event 20 before it (the commands)
      Prev : Natural := 0;
   end record;
   Max_JRU : constant := 2048;
   function JRU_Count return Natural;
   function JRU (I : Positive) return JRU_Record_T;
   --  the mode of the last JRU event 1 since the power-up, the level
   --  status and level of the last event 1 or event 40 kind 1 (EVC_Modes
   --  positions), No_Value before any
   function JRU_Mode return Natural;
   function JRU_Level_Status return Natural;
   function JRU_Level return Natural;
   --  the monitoring and the status of the last JRU event 21 since the
   --  power-up (0 CSM, NoS before any)
   function JRU_Monitoring return Natural;
   function JRU_Sup_Status return Natural;
   --  an LRBG known: a JRU event 10 since the power-up and no event 8
   --  "position unknown" after it
   function JRU_LRBG_Known return Boolean;
   --  the phase of the last JRU event 45 of M_TRACKCOND_TI TI since the
   --  power-up (EVC_JRU_Records: 0 start ahead, 1 inside, 2 end passed),
   --  -1 before any
   function JRU_TC_Phase (TI : Natural) return Integer;

   --  Text and system status events of the window
   type Text_Event_T is record
      Remove   : Boolean := False;  -- MSG_TEXT_REMOVE
      Id       : Natural := 0;
      Class    : Natural := 0;      -- 0 fixed, 1 plain, 2 system status
      Ack      : Boolean := False;
   end record;
   Max_Events : constant := 256;
   function Text_Count return Natural;
   function Text (I : Positive) return Text_Event_T;

   type SS_Event_T is record
      Entry_Number, Event : Natural := 0;
   end record;
   function SS_Count return Natural;
   function SS (I : Positive) return SS_Event_T;

   --  DMI frames the DMI sent to the on-board in the window
   function DMI_Sent return Natural;

   ---------------------------------------------------------------------
   --  The radio: the RTM port in the format of EVC_Ports (phase E5)
   ---------------------------------------------------------------------

   --  An RTM input as the port takes it (a tagged message, an event)
   procedure RTM_Input (Payload : Byte_Array);

   --  An RTM output of the window: a train to track message of a
   --  session (Code its NID_MESSAGE, Data the message from its first
   --  byte) or a request to the radio (Code EVC_Ports.RTM_Request_T'Pos
   --  + 1, Data the bytes after the code); Length 0 for a payload that
   --  is neither
   Max_Radio_Bytes : constant := 256;
   type Radio_Out_T is record
      Session    : Natural := 0;
      Is_Request : Boolean := False;
      Code       : Natural := 0;
      Length     : Natural := 0;
      Data       : Byte_Array (1 .. Max_Radio_Bytes) := (others => 0);
   end record;
   Max_Radio : constant := 256;
   function Radio_Count return Natural;
   function Radio (I : Positive) return Radio_Out_T;

   --  Since the power-up: the T_TRAIN of the last message the on-board
   --  sent in Session, and the bench time it was taken (-1 when none);
   --  the T_TRAIN of the last message of NID_MESSAGE Nid in Session (-1
   --  when none); the last request of Session (0 none, else the code)
   function Last_T_Train (Session : Positive) return Integer_64;
   function Last_Sent_Ms (Session : Positive) return Unsigned_64;
   function T_Train_Of (Session : Positive; Nid : Natural) return Integer_64;
   function Last_Request (Session : Positive) return Natural;

end S076_Bench;
