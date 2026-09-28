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
--  BTM (in): one Eurobalise telegram after the decoding of SUBSET-036:
--     n_bits u16, then the n_bits user bits, the first bit (Q_UPDOWN,
--     SUBSET-026 8.4.2.1) in the most significant bit of the first
--     byte, packed into (n_bits + 7) / 8 bytes. The length must be
--     exactly that. n_bits is BTM_Short_Bits (210, a short telegram) or
--     BTM_Long_Bits (830, a long one): SUBSET-036 4.3.1.2.
--     The core parses it at the next cycle (ETCS_Telegram, EVC_Received).
--  RTM (in): one radio message of SUBSET-026 chapter 8 as its bytes,
--     most significant bit first: NID_MESSAGE (8 bits), L_MESSAGE (10
--     bits, 7.5.1.48: the length of the message in bytes), ... The
--     payload length must equal L_MESSAGE. The core parses it at the next
--     cycle as a track to train message (ETCS_Message, EVC_Received).
--  Odometer (in, Odometer_Length bytes): one sample of the odometry
--     (SUBSET-041 is outside this project, doc/EVC-PLAN.md §1):
--     d_est i32, d_min i32, d_max i32 (travelled distance and its
--     confidence interval, cm, two's complement, d_min <= d_est <=
--     d_max), v_est u16, v_min u16, v_max u16 (speed and its interval,
--     cm/s, v_min <= v_est <= v_max), direction u8 (0 unknown, 1
--     nominal, 2 reverse). Phase E2 builds the train position on it.
--  TIU (in, TIU_Length bytes): one signal of the train interface, among
--     the inputs the conditions of SUBSET-026 4.6.3 name: signal u8 (1
--     cab A active, 2 cab B active, 3 sleeping requested [3] [14], 4
--     passive shunting permitted [26], 5 non leading permitted [46]),
--     value u8 (0 or 1).
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
--     accepted (NID_MESSAGE u8, L_MESSAGE u16). Every input is rejected.

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
   BTM_Max_Length  : constant := 2 + (BTM_Long_Bits + 7) / 8;
   RTM_Min_Length  : constant := 3;     -- NID_MESSAGE and L_MESSAGE
   RTM_Max_Length  : constant := 1023;  -- L_MESSAGE is 10 bits
   Odometer_Length : constant := 19;
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
   --  (n_bits + 7) / 8 bytes behind its count
   function Valid_BTM (Payload : Byte_Array) return Boolean is
     (Payload'Length in 2 + (BTM_Short_Bits + 7) / 8 .. BTM_Max_Length
      and then EVC_Bytes.Get_U16 (Payload, Payload'First)
                 in BTM_Short_Bits | BTM_Long_Bits
      and then Payload'Length
                 = 2 + (Natural (EVC_Bytes.Get_U16 (Payload, Payload'First))
                        + 7) / 8);

   --  SUBSET-026 7.5.1.48: L_MESSAGE, bits 8 .. 17 of the message, is
   --  its length in bytes
   function Valid_RTM (Payload : Byte_Array) return Boolean is
     (Payload'Length in RTM_Min_Length .. RTM_Max_Length
      and then Natural (Payload (Payload'First + 1)) * 4
                 + Natural (Payload (Payload'First + 2)) / 64
               = Payload'Length);

   type Distance_Cm_T is range -2**31 .. 2**31 - 1;
   type Speed_Cms_T is range 0 .. 2**16 - 1;
   type Direction_T is (Unknown_Direction, Nominal, Reverse_Direction);

   --  A 32 bit field read as two's complement
   function To_Distance (Value : Unsigned_32) return Distance_Cm_T is
     (if Value < 2**31
      then Distance_Cm_T (Value)
      else Distance_Cm_T (Long_Long_Integer (Value) - 2**32));

   function Distance_At (Payload : Byte_Array; Offset : Natural)
     return Distance_Cm_T
   is (To_Distance (EVC_Bytes.Get_U32 (Payload, Payload'First + Offset)))
     with Pre => Payload'Length = Odometer_Length and then Offset <= 8;

   function Speed_At (Payload : Byte_Array; Offset : Natural)
     return Speed_Cms_T
   is (Speed_Cms_T (EVC_Bytes.Get_U16 (Payload, Payload'First + Offset)))
     with Pre => Payload'Length = Odometer_Length and then Offset <= 16;

   function Valid_Odometer (Payload : Byte_Array) return Boolean is
     (Payload'Length = Odometer_Length
      and then Distance_At (Payload, 4) <= Distance_At (Payload, 0)
      and then Distance_At (Payload, 0) <= Distance_At (Payload, 8)
      and then Speed_At (Payload, 14) <= Speed_At (Payload, 12)
      and then Speed_At (Payload, 12) <= Speed_At (Payload, 16)
      and then Payload (Payload'First + 18) <= 2);

   function Valid_TIU (Payload : Byte_Array) return Boolean is
     (Payload'Length = TIU_Length
      and then Payload (Payload'First) in 1 .. 5
      and then Payload (Payload'First + 1) <= 1);

   --  True when Payload has the documented shape of an input on Port
   function Valid_Input (Port : Port_T; Payload : Byte_Array) return Boolean
   is (case Port is
          when BTM      => Valid_BTM (Payload),
          when RTM      => Valid_RTM (Payload),
          when Odometer => Valid_Odometer (Payload),
          when TIU      => Valid_TIU (Payload),
          when DMI      => EVC_DMI_Port.Valid_Input_Frame (Payload),
          --  no input is defined on these ports (see above)
          when ATO | JRU => False);

   ---------------------------------------------------------------------
   --  Decoded inputs
   ---------------------------------------------------------------------

   type Odometer_Sample_T is record
      D_Est, D_Min, D_Max : Distance_Cm_T;
      V_Est, V_Min, V_Max : Speed_Cms_T;
      Direction           : Direction_T;
   end record;

   --  At standstill, nothing known of the distance
   Standstill_Sample : constant Odometer_Sample_T :=
     (D_Est | D_Min | D_Max => 0,
      V_Est | V_Min | V_Max => 0,
      Direction => Unknown_Direction);

   function To_Odometer (Payload : Byte_Array) return Odometer_Sample_T is
     (D_Est     => Distance_At (Payload, 0),
      D_Min     => Distance_At (Payload, 4),
      D_Max     => Distance_At (Payload, 8),
      V_Est     => Speed_At (Payload, 12),
      V_Min     => Speed_At (Payload, 14),
      V_Max     => Speed_At (Payload, 16),
      Direction => Direction_T'Val (Payload (Payload'First + 18)))
     with Pre => Valid_Odometer (Payload);

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

end EVC_Ports;
