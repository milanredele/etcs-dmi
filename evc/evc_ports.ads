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
--     leading permitted [46]), value u8 (0 or 1). The active cab gives
--     the train orientation (SUBSET-026 3.6.1.5, EVC_Position).
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
--     (u24 identity). Every input is rejected.

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
   DMI_Max_Length  : constant := EVC_DMI_Port.Max_Frame_Length;
   JRU_Record_Length : constant := 16;

   --  The largest payload of one input or output on each port
   Max_Payload : constant array (Port_T) of Natural :=
     (BTM      => BTM_Max_Length,
      RTM      => RTM_Max_Length,
      Odometer => Odometer_Length,
      TIU      => TIU_Length,
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
      and then Payload (Payload'First) in 1 .. 5
      and then Payload (Payload'First + 1) <= 1);

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
      Non_Leading_Permitted);

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
   --  a balise group. Byte 3 the change: 1 stored (byte 4: the number of
   --  the group message mod 256; a TSR its NID_TSR, an LX its NID_LX,
   --  V_MAIN its value), 2 deleted or revoked (byte 4: the NID_TSR), 3
   --  rejected (an MA its SSP and gradients do not cover, 3.7.2.3), 4
   --  section time-out (byte 4: the section), 5 End Section time-out, 6
   --  overlap time-out, 7 LOA speed time-out, 8 MA shortened, 9 national
   --  values applicable, 10 national values back to the defaults, 11
   --  trip order (V_MAIN 0), 12 the information of a group could not be
   --  kept (no origin left), 13 TSRs deleted with the orientation.
   ---------------------------------------------------------------------

   JRU_Stored_Information : constant := 32;

end EVC_Ports;
