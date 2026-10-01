--  ETCS on-board (EVC)
--  The driver's requests and entries from the DMI: MSG_DRIVER_ACTION and
--  MSG_DRIVER_DATA (common/dmi_protocol.ads) decoded into queries named
--  after the actions of the DMI (doc/EVC-PLAN.md §10).
--
--  Like the other inputs of the core, a frame is latched when it
--  arrives (Receive, from EVC_Core.Handle_Input, any number between two
--  cycles) and taken at the first step of the next cycle (Take, from
--  EVC_Core.Read_Ports): every query answers for the frames latched
--  before the last Take, and only for those. Several frames of the
--  same action in one cycle are one request (Selected), with the
--  argument of the last one; several entries of the same data, the
--  last one.
--
--  The package decodes, it does not judge: whether a request is
--  possible in the mode, at the speed and with the data of the cycle is
--  for the unit that acts on it (the start of mission and the levels of
--  EVC_Mission and EVC_Levels, the conditions of 4.6.3). It only checks
--  the shape of what it keeps: a MSG_DRIVER_DATA of a length its kind
--  does not have is ignored (and counted, Ignored), as is an action code
--  above 20 or an acknowledgement of an unknown kind. The ranges of the
--  values (A.3.11, 7.5) are checked by the unit that uses them.
--
--  The package is open ended: the procedures half of E4 adds the
--  queries of its actions (e4/procedures) as further expression
--  functions on Selected, Argument, Acknowledged and Entered.

with EVC_Bytes;  use EVC_Bytes;
with Interfaces; use Interfaces;

package EVC_Driver_Requests
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  MSG_DRIVER_ACTION, action u8 (its position here is its code)
   type Action_T is
     (TAF_Yes,               --  0 track ahead free confirmed
      Speed_Toggle,          --  1
      Acknowledge,           --  2 (DMI 5.4.1, see Ack_Kind_T)
      Tunnel_Toggle,         --  3
      Geo_Toggle,            --  4
      Start,                 --  5 start of mission (5.4.3.2 S20)
      Override,              --  6 override (5.8)
      Shunting,              --  7 shunting (5.6)
      Exit_Shunting,         --  8 exit of shunting (4.6.3 [19])
      Adhesion,              --  9 arg 0 / 1 (3.18.4.6)
      Train_Integrity,       -- 10
      Level,                 -- 11 arg: the level code of the DMI
      Non_Leading,           -- 12 (4.6.3 [46])
      ATO_Engage,            -- 13
      Skip_Stopping_Point,   -- 14
      ATO_Selector,          -- 15
      Main_Window_Button,    -- 16
      Supervised_Manoeuvre,  -- 17 arg 0 initiate, 1 continue, 2 exit
      BMM_Inhibition,        -- 18 arg 0 inhibit, 1 revoke (5.22)
      Maintain_Shunting,     -- 19 (4.4.20.1.5)
      Isolate);              -- 20 (4.6.3 [1])

   --  The kind of an acknowledgement (DMI_Ack.Ack_Kind_T, the arg of
   --  action 2)
   type Ack_Kind_T is
     (Level_Transition,      -- 0
      Mode_Change,           -- 1
      Fixed_Text,            -- 2
      Plain_Text,            -- 3
      System_Status,         -- 4
      Brake_Release,         -- 5
      NTC_Text);             -- 6

   --  MSG_DRIVER_DATA, kind u8 (its position here is its code)
   type Data_Kind_T is
     (Driver_ID,             --  0 len u8, Latin-1
      Train_Running_Number,  --  1 len u8, Latin-1
      Train_Data,            --  2 the seven items of DMI Table 40
      SR_Data,               --  3 speed u16 km/h, distance u16 m
      GSMR_Network,          --  4 len u8, Latin-1
      RBC_Data,              --  5 23 bytes
      Radio_Network_Type,    --  6 type u8
      One_Radio_System,      --  7 choice u8
      Set_VBC,               --  8 code u32
      Remove_VBC,            --  9 code u32
      Language);             -- 10 two letters

   --  A text the driver entered (driver ID, train running number, GSM-R
   --  network): Latin-1 bytes. DMI 11.3.3 and 11.3.8: at most 16
   --  characters; a longer entry is ignored.
   Max_Text : constant := 16;
   subtype Text_Length_T is Natural range 0 .. Max_Text;
   type Text_Bytes_T is array (1 .. Max_Text) of Byte;
   type Text_T is record
      Length : Text_Length_T := 0;
      Chars  : Text_Bytes_T := (others => 0);
   end record;

   --  The Train Data the driver validated (DMI Table 40, the flexible
   --  entry), as the DMI sends them: no value is 16#FF# (16#0000# for
   --  the other international categories)
   type Train_Entry_T is record
      Length_M         : Unsigned_16 := 0;   -- L_TRAIN, m
      Brake_Percentage : Unsigned_16 := 0;   -- %
      Max_Speed_Kmh    : Unsigned_16 := 0;   -- V_MAXTRAIN, km/h
      Cant_Deficiency  : Byte := 16#FF#;     -- NC_CDTRAIN
      Other_Categories : Unsigned_16 := 0;   -- NC_TRAIN bits
      Axle_Load        : Byte := 16#FF#;     -- M_AXLELOADCAT
      Airtight         : Byte := 16#FF#;     -- M_AIRTIGHT
      Loading_Gauge    : Byte := 16#FF#;     -- M_LOADINGGAUGE
   end record;

   --  The SR speed limit (km/h) and distance (m) the driver entered
   --  (4.4.11.1.5)
   type SR_Entry_T is record
      Speed_Kmh  : Unsigned_16 := 0;
      Distance_M : Unsigned_16 := 0;
   end record;

   type Bytes_23_T is array (1 .. 23) of Byte;

   ---------------------------------------------------------------------
   --  The requests of the cycle (taken at the last Take)
   ---------------------------------------------------------------------

   --  The driver selected the action A
   function Selected (A : Action_T) return Boolean
     with Global => State;
   --  Its argument (the last one of the cycle; 0 when not selected)
   function Argument (A : Action_T) return Unsigned_16
     with Global => State;

   --  The driver acknowledged a request of kind K, with the id of its
   --  text message (the last of the cycle; 0 for the other kinds)
   function Acknowledged (K : Ack_Kind_T) return Boolean
     with Global => State;
   function Ack_Id (K : Ack_Kind_T) return Unsigned_16
     with Global => State;

   --  The driver entered data of kind K
   function Entered (K : Data_Kind_T) return Boolean
     with Global => State;

   function Driver_ID return Text_T
     with Global => State;
   function Train_Running_Number return Text_T
     with Global => State;
   function GSMR_Network return Text_T
     with Global => State;
   function Train_Data return Train_Entry_T
     with Global => State;
   function SR_Data return SR_Entry_T
     with Global => State;
   --  RBC data (23 bytes), radio network type, one radio system, VBC
   --  code, language: the bytes after the kind, as they came (E5, E6)
   function RBC_Data return Bytes_23_T
     with Global => State;
   function Data_Byte (K : Data_Kind_T) return Byte
     with Global => State;
   function VBC_Code (K : Data_Kind_T) return Unsigned_32
     with Global => State;

   --  The frames latched since the last Take that asked to isolate the
   --  on-board (EVC_Core.Isolation_Requested)
   function Isolation_Latched return Boolean
     with Global => State;

   --  The MSG_DRIVER_DATA frames of a shape their kind does not have,
   --  since Clear (saturating)
   function Ignored return Natural
     with Global => State;

   --  Named after the DMI actions
   function Isolation_Selected return Boolean is (Selected (Isolate))
     with Global => State;
   function Start_Selected return Boolean is (Selected (Start))
     with Global => State;
   function Non_Leading_Selected return Boolean is (Selected (Non_Leading))
     with Global => State;
   function Level_Selected return Boolean is (Selected (Level))
     with Global => State;
   --  The level code of the DMI (2 level 0, 3 NTC, 4 level 1, 5 level 2)
   function Selected_Level_Code return Unsigned_16 is (Argument (Level))
     with Global => State;
   function Mode_Acknowledged return Boolean is
     (Acknowledged (Mode_Change))
     with Global => State;
   function Level_Acknowledged return Boolean is
     (Acknowledged (Level_Transition))
     with Global => State;
   function Brake_Release_Acknowledged return Boolean is
     (Acknowledged (Brake_Release))
     with Global => State;
   function Maintain_Shunting_Selected return Boolean is
     (Selected (Maintain_Shunting))
     with Global => State;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   --  Power-up: nothing latched, nothing taken
   procedure Clear
     with Global => (Output => State),
          Post => not Isolation_Latched
                  and then (for all A in Action_T => not Selected (A))
                  and then (for all K in Ack_Kind_T => not Acknowledged (K))
                  and then (for all K in Data_Kind_T => not Entered (K));

   --  One frame of the DMI port (any frame: what is not a well formed
   --  MSG_DRIVER_ACTION or MSG_DRIVER_DATA changes nothing), latched for
   --  the next Take
   procedure Receive (Frame : Byte_Array)
     with Global => (In_Out => State),
          Post => (if Isolation_Latched'Old then Isolation_Latched);

   --  The first step of a cycle: the latched frames become the requests
   --  of the cycle, the latch is emptied
   procedure Take
     with Global => (In_Out => State),
          Post => Isolation_Selected = Isolation_Latched'Old
                  and then not Isolation_Latched;

end EVC_Driver_Requests;
