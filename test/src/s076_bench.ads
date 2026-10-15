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
with EVC_Config;
with S076_Sequences;

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
   --  The radio systems the on-board installs at the next Power_On
   --  (EVC_Config.Radio_Config_T.Systems); kept over Reset
   procedure Set_Radio_Systems (Systems : EVC_Config.Radio_Systems_T);
   --  Powered down: no cycle of the on-board until Power_On
   procedure Power_Off;
   function Powered return Boolean;
   --  A safety critical fault of the on-board (EVC_Core.Enter_Failure)
   procedure Fault;

   --  Ms of cycles (rounded up to whole cycles): the train moves at its
   --  speed
   procedure Run (Ms : Natural);
   procedure Cycle;
   --  B224: one cycle at the train's speed that moves the train by
   --  Distance_Cm (the last cycle before a location: the speed kept, not
   --  the distance left reported as the speed for one cycle, a dip that
   --  swings the on-board's acceleration estimate and with it every limit
   --  by A_est2 over T_berem, 3.13.9.3.2.9; the cycle keeps its length:
   --  a shorter one shifts the on-board's timing)
   procedure Cycle (Distance_Cm : Integer_64);
   function Time_Ms return Unsigned_64;

   ---------------------------------------------------------------------
   --  The train
   ---------------------------------------------------------------------

   function Position return Integer_64;      -- the antenna, cm
   function Speed return Natural;            -- cm/s
   --  +1 towards growing distances (cab A ahead), -1 the other way
   function Direction return Integer;
   --  B262: the speed the driver asks for. A lower one, or any while the
   --  train is not braked and not regaining its speed after a brake, is
   --  the train's speed at once (a step); a higher one while the
   --  on-board commands a brake, or while the train regains its speed
   --  after one, is where the ramp of the braking model ends
   procedure Set_Speed (Cms : Natural);
   procedure Set_Direction (Dir : Integer);

   --  B262, the braking model: after each cycle, while the on-board
   --  commands the emergency (service) brake the train decelerates at
   --  the emergency (service) deceleration of the conversion model of
   --  SUBSET-026 A.3.7 for the brake percentage Lambda (A.3.7.1: the
   --  service brake at min (Lambda, 135)), down to standstill; once the
   --  brake is released it accelerates back to the speed asked for at
   --  Regain_Mms2 (a ramp: a step swings the on-board's acceleration
   --  estimate, B195). Lambda 0: no braking model (the train keeps its
   --  speed under a brake command, as the bench did before B262)
   procedure Set_Brake_Percentage (Lambda : Natural);
   --  B262: without the service brake (a sequence whose comment says the
   --  SB must be disabled in the laboratory, to reach the EBI), the
   --  braking model acts under the emergency brake only
   procedure Set_Service_Brake (On : Boolean);
   --  B262: a speed the sequence imposes (an ODO speed step: the steps
   --  that provoke a brake on purpose put the train above the SBI or the
   --  EBI) is the train's at once, whatever the brake; the braking model
   --  acts on it from the next cycle
   procedure Force_Speed (Cms : Natural);
   Regain_Mms2 : constant := 300;
   --  True while the train is below the speed asked for because of a
   --  brake (braked, or regaining its speed)
   function Braked return Boolean;
   --  True once a brake that lowered the train under the speed forced
   --  last (Force_Speed) was released: that speed was the sequence's
   --  provocation of the brake, spent by it (the chart's speed applies
   --  again); False again at the next Force_Speed
   function Forced_Spent return Boolean;

   --  B261: the distance (m) the EBD of the conversion model (A.3.7:
   --  A_basic for the brake percentage Lambda, 10 .. 250, else 100) takes
   --  from From_Kmh down to To_Kmh on a flat track, with the integrated
   --  correction factors in force (EVC_National_Values: Kv_int by
   --  A_ebmax for a maximum speed of 200 km/h, 3.13.6.2.1.8, Kr_int for
   --  Length_M, 3.13.2.3.7.12); Position 1 passenger in P, 2 freight in
   --  P, 3 freight in G (the workbook's)
   --  B370: on the workbook's gradient profile Grades (flat when it has
   --  no boundary): the deceleration of each speed step with the
   --  acceleration of the lowest gradient under the train at its distance
   --  from the target (3.13.4.2, 3.13.4.3 with the rotating masses of
   --  A.3.1, 15 % uphill and 2 % downhill)
   --  With_Bec: plus the distance run at From_Kmh (V_bec) during
   --  T_be_reduced (3.13.9.3.2.6, 3.13.9.3.2.10 with A_est 0 and the
   --  traction time inside T_be_react), whose ramp of A.3.12 depends on
   --  A_EB, the least EBD deceleration from To_Kmh to From_Kmh, and so
   --  on Lambda (A.3.12.2.2, .3)
   function Ebd_Distance (Lambda, Position, Length_M : Natural;
                          From_Kmh, To_Kmh : Long_Float;
                          Grades : S076_Sequences.Grades_T := (others => <>);
                          With_Bec : Boolean := False)
                          return Long_Float;

   --  B300: the service brake terms of a target at V_Kmh on a flat track:
   --  the distance (m) the SBD of the conversion model takes from V_Kmh
   --  down to To_Kmh (A.3.7.1: A_basic for min (Lambda, 135), no
   --  correction factor) and T_bs_reduced (s) of the target (A.3.12 with
   --  A_SB and A_expected_max of that SBD between To_Kmh and V_Kmh, T_bs
   --  and T_bs_react of A.3.9, at zero target speed for To_Kmh 0, which
   --  is the EOA's: EVC_Build_Up.T_Bs_Reduced). The SBI1 of an EOA lies
   --  D_Sbd + V * T_Bs from it (3.13.9.3.3.1), the SBI2 of an EBD based
   --  target V * T_Bs before its EBI (3.13.9.3.3.2)
   type Sbd_Terms_T is record
      D_Sbd : Long_Float := 0.0;
      T_Bs  : Long_Float := 0.0;
   end record;
   --  B370: Grades as for Ebd_Distance, in the SBD and in the
   --  decelerations of T_bs_reduced
   function Sbd_Terms (Lambda, Position, Length_M : Natural;
                       V_Kmh, To_Kmh : Long_Float;
                       Grades : S076_Sequences.Grades_T := (others => <>))
                       return Sbd_Terms_T;
   --  B370: the acceleration due to the gradient (m/s2, negative
   --  downhill) of a train of Length_M whose front is Before_M before the
   --  target of the profile Grades; 0 without a profile
   function Grade_Acceleration (Grades : S076_Sequences.Grades_T;
                                Before_M : Long_Float; Length_M : Natural)
                                return Long_Float;
   --  B262:the speed a brake does not take the train below (cm/s,
   --  at most the speed asked for): while the runner drives the train to
   --  a location the sequence says it reaches, a crawl (the sequences'
   --  trains brake more gently than the conversion model and still move
   --  where ours would have stopped: 4120100_03 reads a group 2 m on
   --  under the runaway EB); 0 otherwise. Reset sets 0
   procedure Set_Brake_Floor (Cms : Natural);

   --  Move to the track position To_Cm (cm) at Cms (at least 1 cm/s),
   --  in whole cycles; stops at the cycle that reaches it. Max_Ms bounds
   --  the time (a target the train cannot reach in that time is not
   --  reached). The speed after is Cms, the braking model applying
   --  (Set_Speed); a train held at standstill by a brake for 10 s stops
   --  trying.
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
   --  The odometer states the speed accuracy of SUBSET-041 5.3.1.2
   --  (V_max = V_est + f41, V_min = V_est - f41) from now on, or the
   --  exact speed (V_max = V_min = V_est), as after Reset (B191)
   procedure Set_Speed_Accuracy (On : Boolean);
   --  The odometer states Extra_Cm more over- and under-reading at its
   --  next sample (a degraded measurement)
   procedure Odometer_Error (Extra_Cm : Natural);

   --  The driver touches the DMI screen at X, Y: pointer down, Hold_Ms
   --  of cycles (at least one), pointer up, one cycle
   procedure Touch (X, Y : Natural; Hold_Ms : Natural := 0);

   ---------------------------------------------------------------------
   --  Observations
   ---------------------------------------------------------------------

   --  A new observation window: the flags and lists below restart;
   --  with Keep_Radio the radio messages sent stay listed (an RBC's
   --  message given while the on-board's answers to the one before are
   --  still expected: the sequences record either order)
   procedure New_Window (Keep_Radio : Boolean := False);
   --  B270: the time the window was opened (Keep_Radio keeps the radio
   --  outputs of before it listed, sent before this time)
   function Window_Ms return Unsigned_64;
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

   --  The changes of the on-board's supervision (EVC_Core.Supervision)
   --  cycle by cycle since Reset, the last Max_Changes kept (B172): the
   --  status entered (Indication, Overspeed, Warning, Intervention) and
   --  the service brake, emergency brake and traction cut-off commands
   --  set. The distances count from the on-board's own estimated front
   --  end to the target shown in the cycle (EVC_SDM.Result_T.Target_X,
   --  Target_EOA and X_Est are all in the on-board's ahead coordinates,
   --  so no conversion to the bench's track coordinate is needed; the
   --  max safe front end is Doubt_Over ahead of the estimated one)
   type Change_Kind_T is
     (To_Indication, To_Overspeed, To_Warning, To_Intervention,
      SB_On, EB_On, TCO_On);
   type Change_T is record
      Kind      : Change_Kind_T := To_Indication;
      Time_Ms   : Natural := 0;
      Track_Cm  : Integer_64 := 0;  -- the antenna, track coordinate
      V_Est     : Natural := 0;     -- cm/s
      Shown     : Boolean := False; -- a target shown
      V_Target  : Natural := 0;     -- cm/s
      EOA_Kind  : Boolean := False; -- the target shown is an EOA target
      D_Loc     : Integer_64 := 0;  -- Target_X - X_Est, cm
      D_EOA     : Integer_64 := 0;  -- Target_EOA - X_Est, cm
      Over      : Integer_64 := 0;  -- Doubt_Over, cm
   end record;
   Max_Changes : constant := 32;
   function Change_Count return Natural;  -- at most Max_Changes
   --  the I-th latest change (1 the latest)
   function Change (I : Positive) return Change_T
     with Pre => I <= Change_Count;
   --  the same quantities in the last cycle (Kind meaningless)
   function Current return Change_T;

   --  The flags of the window: a value was shown in at least one cycle
   type Seen_T is record
      Mode, Mode_Ack, Level, Level_Ann, Level_Ann_Ack :
        Bit_Array_T := (others => False);
      Override, Brake_Shown, Brake_Ack, EBC, SBC, TCO,
        Not_EBC, Not_SBC, Not_TCO, Speed_Shown, Planning_Shown,
        Indication, Gradients, Geo, Reversing, Adhesion, Radio_Up,
        Radio_Lost, TAF, LSSMA_Changed :
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
   --  the identity of the LRBG of the last JRU event 10 and of the balise
   --  group of the last event 2 (a telegram accepted), NID_C * 2**14 +
   --  NID_BG, No_Value before any
   function JRU_LRBG_Id return Natural;
   function JRU_Last_BG_Id return Natural;
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
      --  B270: the bench's time it was sent, ms
      At_Ms      : Unsigned_64 := 0;
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
