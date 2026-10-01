--  ETCS on-board (EVC)
--  The ports of the on-board and the shape of what travels on them.
--
--  Everything the on-board exchanges with the world is a byte payload on
--  one of these ports (doc/EVC-PLAN.md §2): the hosted, wasm and target
--  glue only moves bytes. Multi-byte fields are little endian, read and
--  written byte by byte (EVC_Bytes).
--
--  Payload shapes. A payload of any other shape is rejected by
--  Valid_Input, and the on-board ignores it.
--
--  BTM (in): one Eurobalise telegram after the decoding of SUBSET-036,
--     with the place where its balise was detected:
--     stamp i32, the location of the balise in the frame of the
--     odometer (the d_est the odometer had when the antenna passed the
--     centre of the balise, cm, same wrapping counter as d_est below);
--     then the telegram:
--     n_bits u16, then the n_bits user bits, the first bit (Q_UPDOWN,
--     SUBSET-026 8.4.2.1) in the most significant bit of the first
--     byte, packed into (n_bits + 7) / 8 bytes. The length must be
--     exactly that. n_bits is BTM_Short_Bits (210, a short telegram) or
--     BTM_Long_Bits (830, a long one): SUBSET-036 4.3.1.2.
--     The core parses the telegram at the next cycle (ETCS_Telegram,
--     EVC_Received) and hands it with its stamp to the position
--     (EVC_Position): the stamp places the balise, hence the balise
--     group, on the odometer frame (SUBSET-026 3.6.4.1.1 a).
--  RTM (in): one radio message of SUBSET-026 chapter 8 as its bytes,
--     most significant bit first: NID_MESSAGE (8 bits), L_MESSAGE (10
--     bits, 7.5.1.48: the length of the message in bytes), ... The
--     payload length must equal L_MESSAGE. The core parses it at the next
--     cycle as a track to train message (ETCS_Message, EVC_Received).
--  Odometer (in, Odometer_Length bytes): one sample of the odometry.
--     The sensors and their fusion are outside this project
--     (doc/EVC-PLAN.md §1); the sample carries what SUBSET-026 3.6.4,
--     3.6.8 and 3.15.8 need from them, with the accuracy of SUBSET-041
--     5.3.1 as the odometer's own statement:
--     d_est i32: the distance travelled, cm, in the frame of the
--        odometer: it grows when the engine moves towards its cab A end
--        and falls when it moves towards cab B. A counter that wraps:
--        the on-board only uses the difference between two samples,
--        modulo 2**32 (a movement of less than 21 000 km between two
--        samples).
--     over u32, under u32: the over-reading and the under-reading
--        amounts (SUBSET-041 5.3.1.1) accumulated over every movement
--        since the odometer started, cm, wrapping counters that never
--        fall: between two samples the travelled distance was at least
--        |d_est change| - (over change) and at most |d_est change| +
--        (under change). This is the separate accumulation of
--        overestimation and underestimation of SUBSET-026 3.6.8.1; it
--        includes the error in the detection of a balise (3.6.4.1.1 a,
--        SUBSET-041 5.3.1.1 notes).
--     v_est u16, v_min u16, v_max u16: the speed and its confidence
--        interval (SUBSET-041 5.3.1.2), cm/s, v_min <= v_est <= v_max.
--     movement u8: 0 standstill (then the three speeds are 0), 1 moving
--        towards cab A, 2 moving towards cab B, 3 moving, direction not
--        known.
--     cold u8, cold_distance u16: the cold movement detection of
--        3.15.8, read at power-up. cold 0: the information is not
--        available (3.15.8.3: no detection fitted, or it could not
--        work during the No Power period; cold_distance is then 0);
--        1: available, and cold_distance is the largest distance, cm,
--        the engine was moved away from its position when No Power was
--        entered (saturating at 65 535). The on-board applies the 2 m
--        of 3.15.8.1.1 itself.
--  TIU (in, TIU_Length bytes): one signal of the train interface, among
--     the inputs the conditions of SUBSET-026 4.6.3 name and the cab
--     status of SUBSET-034 2.5.1: signal u8 (1 cab A active, 2 cab B
--     active: one input per cab, "cab active" is "desk open"; 3 sleeping
--     requested [3] [14], 4 passive shunting permitted [26], 5 non
--     leading permitted [46]; 6 to 12, of the speed and distance
--     monitoring, at the end of this package; 13 the train
--     configuration, phase E4, there too), value u8 (0 or 1). The
--     active cab gives the train orientation (SUBSET-026 3.6.1.5,
--     EVC_Position). The TIU output is at the end of this package.
--  DMI (in and out): one frame of the DMI protocol v2
--     (common/dmi_protocol.ads): type u8, length u32, payload. See
--     EVC_DMI_Port for the frames the on-board accepts and sends.
--  ATO (in and out): no payload is defined in E0; every input is
--     rejected. The ERTMS/ATO on-board comes to this port later.
--  JRU (out only, JRU_Record_Length bytes): an event for the juridical
--     recording (SUBSET-027 is outside this project): event u8, three
--     bytes of the event, cycle u32, time u64 (on-board time in ms).
--     Events: 1 mode change (mode u8 EVC_Modes.Mode_T'Pos, level status
--     u8 Level_Status_T'Pos, level u8 Level_T'Pos); 2 telegram accepted
--     (NID_C * 2**14 + NID_BG, u24, the balise group); 3 radio message
--     accepted (NID_MESSAGE u8, L_MESSAGE u16); the events of the
--     position (EVC_Position.Event_Kind_T): 4 linking reaction
--     (Q_LINKREACTION u8, cause u8, index u8 of the balise group in the
--     linking information); 5 unexpected balise group (u24 identity); 6
--     missed balise group (u24 identity); 7 odometer accuracy (u8 0
--     nominal, 1 impaired, 2 safety threshold exceeded); 8 status of the
--     train position (u8 0 unknown, 1 valid, 2 invalid); 9 cold movement
--     (u8 1: detected at power-up); 10 new LRBG
--     (u24 identity); the events of the supervision, 20 to 22, of the
--     stored information, 32, and of the installation configuration, 33,
--     at the end of this package (11 to 19 and 23 to 31 are free).
--     Every input is rejected.

with EVC_Bytes;
with EVC_DMI_Port;
with Interfaces; use Interfaces;

package EVC_Ports
  with SPARK_Mode => On, Pure
is

   type Port_T is (BTM, RTM, Odometer, TIU, DMI, ATO, JRU);

   subtype Byte is EVC_Bytes.Byte;
   subtype Byte_Array is EVC_Bytes.Byte_Array;

   BTM_Short_Bits  : constant := 210;
   BTM_Long_Bits   : constant := 830;
   --  the telegram part: n_bits and the bits
   BTM_Telegram_Max_Length : constant := 2 + (BTM_Long_Bits + 7) / 8;
   --  the detection stamp in front of the telegram
   BTM_Stamp_Length : constant := 4;
   BTM_Max_Length  : constant := BTM_Stamp_Length + BTM_Telegram_Max_Length;
   RTM_Min_Length  : constant := 3;     -- NID_MESSAGE and L_MESSAGE
   RTM_Max_Length  : constant := 1023;  -- L_MESSAGE is 10 bits
   Odometer_Length : constant := 22;
   TIU_Length      : constant := 2;
   --  the longest TIU output: the track conditions of phase E4 (below)
   TIU_Out_Max_Length : constant := 3 + 8 * 12;
   DMI_Max_Length  : constant := EVC_DMI_Port.Max_Frame_Length;
   JRU_Record_Length : constant := 16;

   --  The largest payload of one input or output on each port
   Max_Payload : constant array (Port_T) of Natural :=
     (BTM      => BTM_Max_Length,
      RTM      => RTM_Max_Length,
      Odometer => Odometer_Length,
      TIU      => TIU_Out_Max_Length,
      DMI      => DMI_Max_Length,
      ATO      => 0,
      JRU      => JRU_Record_Length);

   Largest_Payload : constant := RTM_Max_Length;

   ---------------------------------------------------------------------
   --  Shapes
   ---------------------------------------------------------------------

   --  SUBSET-036: a telegram of n_bits user bits, 210 or 830, in
   --  (n_bits + 7) / 8 bytes behind its count (the telegram part of a
   --  BTM input, which EVC_Received parses)
   function Valid_BTM (Payload : Byte_Array) return Boolean is
     (Payload'Length in 2 + (BTM_Short_Bits + 7) / 8
                          .. BTM_Telegram_Max_Length
      and then EVC_Bytes.Get_U16 (Payload, Payload'First)
                 in BTM_Short_Bits | BTM_Long_Bits
      and then Payload'Length
                 = 2 + (Natural (EVC_Bytes.Get_U16 (Payload, Payload'First))
                        + 7) / 8);

   --  A BTM input: the detection stamp, then a telegram
   function Valid_BTM_Input (Payload : Byte_Array) return Boolean is
     (Payload'Length > BTM_Stamp_Length
      and then Valid_BTM
                 (Payload (Payload'First + BTM_Stamp_Length
                           .. Payload'Last)));

   --  The telegram part of a valid BTM input
   function BTM_Telegram (Payload : Byte_Array) return Byte_Array is
     (Payload (Payload'First + BTM_Stamp_Length .. Payload'Last))
     with Pre => Valid_BTM_Input (Payload),
          Post => Valid_BTM (BTM_Telegram'Result);

   --  The detection stamp of a BTM input: the odometer's d_est when the
   --  balise was passed
   function BTM_Stamp (Payload : Byte_Array) return Unsigned_32 is
     (EVC_Bytes.Get_U32 (Payload, Payload'First))
     with Pre => Payload'Length > BTM_Stamp_Length;

   --  SUBSET-026 7.5.1.48: L_MESSAGE, bits 8 .. 17 of the message, is
   --  its length in bytes
   function Valid_RTM (Payload : Byte_Array) return Boolean is
     (Payload'Length in RTM_Min_Length .. RTM_Max_Length
      and then Natural (Payload (Payload'First + 1)) * 4
                 + Natural (Payload (Payload'First + 2)) / 64
               = Payload'Length);

   --  Speeds, cm/s
   type Speed_Cms_T is range 0 .. 2**16 - 1;

   --  The movement the odometer sees (the byte "movement")
   type Movement_T is
     (Standstill,       -- 0: the three speeds are 0
      Towards_Cab_A,    -- 1: d_est grows
      Towards_Cab_B,    -- 2: d_est falls
      Moving_Unknown);  -- 3: moving, direction not known

   function U32_At (Payload : Byte_Array; Offset : Natural)
     return Unsigned_32
   is (EVC_Bytes.Get_U32 (Payload, Payload'First + Offset))
     with Pre => Payload'Length = Odometer_Length and then Offset <= 8;

   function U16_At (Payload : Byte_Array; Offset : Natural)
     return Unsigned_16
   is (EVC_Bytes.Get_U16 (Payload, Payload'First + Offset))
     with Pre => Payload'Length = Odometer_Length and then Offset <= 20;

   function Speed_At (Payload : Byte_Array; Offset : Natural)
     return Speed_Cms_T
   is (Speed_Cms_T (U16_At (Payload, Offset)))
     with Pre => Payload'Length = Odometer_Length and then Offset <= 16;

   function Valid_Odometer (Payload : Byte_Array) return Boolean is
     (Payload'Length = Odometer_Length
      and then Speed_At (Payload, 14) <= Speed_At (Payload, 12)
      and then Speed_At (Payload, 12) <= Speed_At (Payload, 16)
      and then Payload (Payload'First + 18) <= 3
      --  at standstill the speed is zero
      and then (if Payload (Payload'First + 18) = 0
                then Speed_At (Payload, 16) = 0)
      and then Payload (Payload'First + 19) <= 1
      --  no cold movement information, no distance
      and then (if Payload (Payload'First + 19) = 0
                then U16_At (Payload, 20) = 0));

   function Valid_TIU (Payload : Byte_Array) return Boolean is
     (Payload'Length = TIU_Length
      and then Payload (Payload'First) in 1 .. 13
      --  the direction controller has three positions, the brake
      --  pressure and the train configuration (phase E4) are numbers,
      --  every other signal is 0 or 1
      and then (case Payload (Payload'First) is
                   when 6      => Payload (Payload'First + 1) <= 2,
                   when 12 | 13 => True,
                   when others => Payload (Payload'First + 1) <= 1));

   --  True when Payload has the documented shape of an input on Port
   function Valid_Input (Port : Port_T; Payload : Byte_Array) return Boolean
   is (case Port is
          when BTM      => Valid_BTM_Input (Payload),
          when RTM      => Valid_RTM (Payload),
          when Odometer => Valid_Odometer (Payload),
          when TIU      => Valid_TIU (Payload),
          when DMI      => EVC_DMI_Port.Valid_Input_Frame (Payload),
          --  no input is defined on these ports (see above)
          when ATO | JRU => False);

   ---------------------------------------------------------------------
   --  Decoded inputs
   ---------------------------------------------------------------------

   --  One odometer sample. The counters are kept as they came, the
   --  on-board takes their differences (EVC_Odometry).
   type Odometer_Sample_T is record
      D_Est, Over, Under  : Unsigned_32;
      V_Est, V_Min, V_Max : Speed_Cms_T;
      Movement            : Movement_T;
      Cold_Available      : Boolean;
      Cold_Distance       : Unsigned_16;
   end record;

   --  Nothing measured
   Standstill_Sample : constant Odometer_Sample_T :=
     (D_Est | Over | Under  => 0,
      V_Est | V_Min | V_Max => 0,
      Movement              => Standstill,
      Cold_Available        => False,
      Cold_Distance         => 0);

   function To_Odometer (Payload : Byte_Array) return Odometer_Sample_T is
     (D_Est          => U32_At (Payload, 0),
      Over           => U32_At (Payload, 4),
      Under          => U32_At (Payload, 8),
      V_Est          => Speed_At (Payload, 12),
      V_Min          => Speed_At (Payload, 14),
      V_Max          => Speed_At (Payload, 16),
      Movement       => Movement_T'Val (Payload (Payload'First + 18)),
      Cold_Available => Payload (Payload'First + 19) = 1,
      Cold_Distance  => U16_At (Payload, 20))
     with Pre => Valid_Odometer (Payload);

   --  SUBSET-034 2.5.1: one cab status input per cab ("cab active" is
   --  "desk open" in SUBSET-026); the others are conditions of 4.6.3
   type TIU_Signal_T is
     (Cab_A_Active,
      Cab_B_Active,
      Sleeping_Requested,
      Passive_Shunting_Permitted,
      Non_Leading_Permitted,
      --  added by supervision (see the end of this package)
      Direction_Controller,
      Regenerative_Brake_Active,
      Eddy_Current_Brake_Active,
      Magnetic_Shoe_Brake_Active,
      EP_Brake_Active,
      Additional_Brake_Active,
      Brake_Pressure,
      --  added by the procedures of phase E4 (see the end of this
      --  package)
      Train_Configuration);

   type TIU_Input_T is record
      Signal : TIU_Signal_T;
      Value  : Boolean;
   end record;

   function To_TIU (Payload : Byte_Array) return TIU_Input_T is
     (Signal => TIU_Signal_T'Val (Payload (Payload'First) - 1),
      Value  => Payload (Payload'First + 1) = 1)
     with Pre => Valid_TIU (Payload);

   ---------------------------------------------------------------------
   --  JRU, phase E3 (profiles): event 32, a change of the stored
   --  information (EVC_Stored_Information). Byte 2 the information: 1
   --  national values, 2 SSP, 3 gradients, 4 axle load speed profile,
   --  5 TSR, 6 default gradient for TSR, 7 movement authority, 8
   --  signalling related speed restriction, 9 track conditions, 10
   --  change of traction system, 11 big metal masses, 12 route
   --  suitability, 13 mode profile, 14 level crossing, 15 adhesion, 16
   --  a balise group, 17 speed restriction to ensure a permitted braking
   --  distance, 18 station platforms and 19 allowed current consumption
   --  (phase E4). Byte 3 the change: 1 stored (byte 4: the number of
   --  the group message mod 256; a TSR its NID_TSR, an LX its NID_LX,
   --  V_MAIN its value), 2 deleted or revoked (byte 4: the NID_TSR), 3
   --  rejected (an MA its SSP and gradients do not cover, 3.7.2.3), 4
   --  section time-out (byte 4: the section), 5 End Section time-out, 6
   --  overlap time-out, 7 LOA speed time-out, 8 MA shortened, 9 national
   --  values applicable, 10 national values back to the defaults, 11
   --  trip order (V_MAIN 0), 12 the information of a group could not be
   --  kept (no origin left), 13 TSRs deleted with the orientation, 14
   --  the speed restrictions to ensure a permitted braking distance
   --  computed again, an input changed (3.11.11.3; byte 4: the number of
   --  sections).
   ---------------------------------------------------------------------

   JRU_Stored_Information : constant := 32;

   ---------------------------------------------------------------------
   --  Added by supervision (phase E3, SUBSET-026 3.13 and 3.14)
   ---------------------------------------------------------------------

   --  TIU inputs 6 to 12 (SUBSET-034):
   --     6 the direction controller of the active desk (2.5.2): value 0
   --       neutral, 1 forward, 2 reverse; unknown until the first input
   --       (then the roll away protection does not run, 3.14.2.1);
   --     7 regenerative, 8 eddy current, 9 magnetic shoe, 10 Ep brake
   --       active (the special brake status, 2.3.6), 11 additional brake
   --       active (2.3.7): value 0 or 1, "not active" until an input;
   --     12 the brake pressure (2.3.2, the service brake feedback of
   --       3.13.2.2.7.3 and A.3.10): value in units of 4 kPa (0 .. 1020
   --       kPa); unknown until the first input.

   --  The raw value byte of a TIU input
   function TIU_Value (Payload : Byte_Array) return Byte is
     (Payload (Payload'First + 1))
     with Pre => Valid_TIU (Payload);

   --  TIU output (TIU_Output_Length bytes), the commands to the train
   --  (SUBSET-034 2.3.3 emergency brake command EBC, 2.3.1 service brake
   --  command SBC, 2.4.9 traction cut-off TCO): commands u8 (bit 0 EBC
   --  "emergency brake commanded", bit 1 SBC "service brake commanded",
   --  bit 2 TCO "cut off traction"; a bit at 0 is the other value of the
   --  signal), reasons u16 little endian (why the brakes are commanded,
   --  one bit per reason: bit 0 the speed and distance monitoring,
   --  3.13.10; bit 1 the service brake failed, 3.14.1.2; bit 2 roll away
   --  protection, 3.14.2; bit 3 unauthorised direction movement
   --  protection, 3.14.3; bit 4 standstill supervision, 4.4.7.1.5; phase
   --  E4: bit 5 the service brake of a level transition not acknowledged,
   --  3.14.1.7.2, 5.10.4.2; bit 6 the emergency brake that System Failure
   --  commands permanently, 4.4.5.1.2, entered by 4.6.3 [84] (a failure of
   --  the host is EVC_Core.Enter_Failure, which falls silent); bit 7 the
   --  train trip, 3.14.1.3, 4.4.13.1.2; bit 8 an acknowledgement of a
   --  mode or of a text message ordered by trackside missing, 3.14.1.7.3,
   --  3.14.1.7.5; bit 9 another brake reason of the procedures: the
   --  service brake of a linking reaction 3.14.1.6, the reverse movement
   --  distances of PT and RV 3.14.1.7.1 and 3.14.1.7.4, the Train Data
   --  changed by another source 5.17.2.2 S2, S4). Sent when it changes
   --  and in every cycle while a command is given; the train interface is
   --  fail safe (EVC_Core.Enter_Failure: silence applies the emergency
   --  brake). Its first byte is never TIU_TC_Tag (the second TIU output,
   --  at the end of this package, which a host tells apart by it:
   --  Is_TIU_TC_Output).
   TIU_Output_Length : constant := 3;
   TIU_EBC : constant Byte := 1;
   TIU_SBC : constant Byte := 2;
   TIU_TCO : constant Byte := 4;

   subtype TIU_Reasons_T is Unsigned_16;
   TIU_Reason_Speed_Distance : constant TIU_Reasons_T := 1;
   TIU_Reason_SB_Failed      : constant TIU_Reasons_T := 2;
   TIU_Reason_Roll_Away      : constant TIU_Reasons_T := 4;
   TIU_Reason_Direction      : constant TIU_Reasons_T := 8;
   TIU_Reason_Standstill     : constant TIU_Reasons_T := 16;
   TIU_Reason_Level_Ack      : constant TIU_Reasons_T := 32;
   TIU_Reason_Failure        : constant TIU_Reasons_T := 64;
   TIU_Reason_Trip           : constant TIU_Reasons_T := 128;
   TIU_Reason_Ack_Missing    : constant TIU_Reasons_T := 256;
   TIU_Reason_Procedure      : constant TIU_Reasons_T := 512;

   subtype TIU_Output_T is Byte_Array (1 .. TIU_Output_Length);

   function TIU_Output (Commands : Byte; Reasons : TIU_Reasons_T)
     return TIU_Output_T is
     ((1 => Commands,
       2 => Byte (Reasons and 16#FF#),
       3 => Byte (Shift_Right (Reasons, 8))));

   --  JRU events of the supervision (the record of the header):
   --     20 brake commands changed: byte 2 the commands of the TIU
   --        output (bits 0 to 2) with the reasons bits 8 to 12 in its bits
   --        3 to 7 (phase E4), byte 3 the reasons bits 0 to 7, byte 4 the
   --        supervision status (Status_T'Pos);
   --     21 speed and distance monitoring changed: monitoring u8 (0 CSM,
   --        1 TSM, 2 RSM), status u8 (0 NoS .. 4 IntS), MRDT u8 (the
   --        number of the most relevant displayed target);
   --     22 overrun: u8 1 the min safe front end (level 2) or the min
   --        safe antenna position (level 1) passed the EOA or the LOA
   --        (3.13.10.2.6 a, 3.13.10.2.7: the trip of E4), 2 the max safe
   --        front end passed the SvL.
   JRU_Brake_Commands : constant := 20;
   JRU_Supervision    : constant := 21;
   JRU_Overrun        : constant := 22;

   ---------------------------------------------------------------------
   --  Added with the installation configuration (e3/config)
   ---------------------------------------------------------------------

   --  JRU event 33, the installation configuration (EVC_Config), recorded
   --  at the first cycle after EVC_Core.Configure: u8 1 the image was
   --  loaded and is the configuration now, 2 it was refused and the
   --  previous configuration stays; u8 the outcome (EVC_Config.Status_T
   --  'Pos: 0 accepted, 1 truncated, 2 bad magic, 3 bad version, 4 bad
   --  length, 5 bad CRC, 6 a field out of range, 7 Table 3 of
   --  3.13.2.2.6.1 violated, 8 refused because the on-board is not in
   --  No Power); u8 the images refused since the start, saturating at
   --  255.
   JRU_Configuration : constant := 33;

   ---------------------------------------------------------------------
   --  Added by phase E4 (modes and levels, e4/modes; procedures,
   --  e4/procedures)
   ---------------------------------------------------------------------

   --  JRU event 40, the levels (EVC_Levels: the kinds of byte 2 and the
   --  bytes 3 and 4 are listed there): a level switched, an order stored
   --  or deleted, the acknowledgement of a level transition asked or
   --  given, the service brake of 5.10.4.2.
   --  JRU event 41, the mission (EVC_Mission): the driver ID, the train
   --  running number, the Train Data and the SR data entered or refused,
   --  'Start', a mode proposed and acknowledged, the start of mission
   --  engaged or ended, a mission started or ended (5.4.6, 5.5).
   --  Event 32, change 15: an information of a group rejected by the
   --  filters of 4.8 (EVC_Stored_Information).
   JRU_Levels  : constant := 40;
   JRU_Mission : constant := 41;

   --  JRU event 23, the procedures (EVC_Procedures: byte 2 the kind,
   --  bytes 3 and 4 its details, see Event_Trip .. Event_PT_Distance
   --  there); JRU event 24, the text messages (EVC_Text_Messages: byte 2
   --  1 displayed, 2 removed, 3 acknowledged, 4 rejected (3.12.3.5.3),
   --  5 its brake commanded; byte 3 the id of MSG_TEXT mod 256, byte 4
   --  the class, 0 fixed, 1 plain)
   JRU_Procedures    : constant := 23;
   JRU_Text_Messages : constant := 24;

   --  TIU input 13, the train data from the train interface (SUBSET-034
   --  2.6.3, 2.6.4: "other train data information", the "type of train
   --  configuration" of 2.6.4.2), for the procedure "Changing Train Data
   --  from sources different from the driver" (SUBSET-026 5.17): value
   --  u8, bits 0 to 5 the train configuration, bit 6 the Train Data it
   --  changes need the driver's validation (5.17.2.2 D0), bit 7 they
   --  concern the train category, the axle load category, the traction
   --  systems accepted or the loading gauge (D1); which data a
   --  configuration changes, and whether they need validation, is the
   --  specific train implementation's (D0), which this input states.
   --  A value that differs from the last one received is a change of
   --  input information (E0); the first one after power-up is not.
   TIU_Config_Validation : constant Byte := 64;
   TIU_Config_Category   : constant Byte := 128;

   --  The second TIU output, the information for an external function
   --  related to the track conditions (SUBSET-026 3.12.1.5 b, 5.20;
   --  SUBSET-034 2.3.4 special brake inhibition area, 2.4.1 change of
   --  traction system, 2.4.2 powerless section with pantograph to be
   --  lowered, 2.4.4 air tightness area, 2.4.7 powerless section with
   --  main power switch to be switched off), TIU_TC_Header_Length +
   --  count * TIU_TC_Entry_Length bytes (its first byte, the tag, tells
   --  it from the commands): tag u8 TIU_TC_Tag, version u8 1, count u8 (0 ..
   --  TIU_TC_Max), then per item: kind u8 (1 pantograph, 2 main power
   --  switch, 3 air tightness, 4 regenerative brake, 5 eddy current
   --  brake for service braking, 6 eddy current brake for emergency
   --  braking, 7 magnetic shoe brake, 8 change of traction system, 9
   --  change of allowed current consumption (2.4.10), 10 station
   --  platform (2.4.6)), id
   --  u8 (the number of the condition, as on the DMI: the same area
   --  keeps it), to_start i32 and to_end i32 (the remaining distances in
   --  cm of SUBSET-034, 5.20.1.2: positive while the train end is in rear
   --  of the location; TIU_TC_None when not generated: 5.20.2.4 ...),
   --  value u16 (a change of traction system: M_VOLTAGE * 1024 +
   --  NID_CTRACTION; of allowed current consumption: M_CURRENT; a station
   --  platform: M_PLATFORM * 4 + Q_PLATFORM, its height and its side;
   --  0 otherwise). Sent in every cycle while an item is
   --  generated, and once with count 0 when the last one ends (5.20.2.5,
   --  5.20.2.8 ...); the nearest items first, at most TIU_TC_Max.
   TIU_TC_Tag           : constant Byte := 16#54#;
   TIU_TC_Header_Length : constant := 3;
   TIU_TC_Entry_Length  : constant := 12;
   TIU_TC_Max           : constant := 8;
   TIU_TC_None          : constant := 16#7FFF_FFFF#;

   --  A TIU output (of the on-board) is the track condition output
   --  rather than the commands
   function Is_TIU_TC_Output (Payload : Byte_Array) return Boolean is
     (Payload'Length >= TIU_TC_Header_Length
      and then Payload (Payload'First) = TIU_TC_Tag);

end EVC_Ports;
