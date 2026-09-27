--  ETCS on-board (EVC)
--  The DMI port: frames of the DMI protocol v2.
--
--  The protocol is defined in common/dmi_protocol.ads, which the DMI and
--  the simulators use. That package works on Ada.Streams and is not
--  SPARK, so the on-board keeps common/ out and frames the few messages
--  it exchanges here, byte by byte. The constants below repeat those of
--  DMI_Protocol; evc_test checks that they are equal.
--
--  A frame is: type u8, length u32 (little endian, the payload length),
--  payload. On the DMI port one input or one output is one frame.
--
--  Inputs the on-board accepts in phase E0 (Valid_Input_Frame):
--    MSG_DRIVER_ACTION with the Driver_Action_Length payload (any action
--      but 2) or the Driver_Ack_Length payload (action 2 only);
--    MSG_DRIVER_DATA with a payload of at least one byte (the kind).
--  Every other frame, and a frame whose length field does not match its
--  size, is rejected.
--
--  Outputs of phase E0: MSG_MODE_LEVEL and MSG_ONBOARD, every cycle.

with EVC_Bytes; use EVC_Bytes;
with EVC_Modes; use EVC_Modes;
with Interfaces; use Interfaces;

package EVC_DMI_Port
  with SPARK_Mode => On, Pure
is

   Header_Length    : constant := 5;
   Max_Frame_Length : constant := 512;

   --  EVC -> DMI
   MSG_MODE_LEVEL    : constant Byte := 16#02#;
   MSG_ONBOARD       : constant Byte := 16#0A#;
   Mode_Level_Length : constant := 9;
   Onboard_Length    : constant := 11;

   --  DMI -> EVC
   MSG_DRIVER_ACTION    : constant Byte := 16#40#;
   MSG_DRIVER_DATA      : constant Byte := 16#41#;
   Driver_Action_Length : constant := 3;
   Driver_Ack_Length    : constant := 5;

   --  Driver actions (MSG_DRIVER_ACTION) the on-board uses
   Action_Ack     : constant Byte := 2;
   --  the driver isolates the on-board: SUBSET-026 4.6.3 condition [1]
   Action_Isolate : constant Byte := 20;

   function Valid_Input_Frame (Frame : Byte_Array) return Boolean is
     (Frame'Length in Header_Length .. Max_Frame_Length
      and then Get_U32 (Frame, Frame'First + 1)
                 = Unsigned_32 (Frame'Length - Header_Length)
      and then
        (case Frame (Frame'First) is
            when MSG_DRIVER_ACTION =>
              (Frame'Length = Header_Length + Driver_Action_Length
               and then Frame (Frame'First + Header_Length) /= Action_Ack)
              or else
              (Frame'Length = Header_Length + Driver_Ack_Length
               and then Frame (Frame'First + Header_Length) = Action_Ack),
            when MSG_DRIVER_DATA =>
               Frame'Length > Header_Length,
            when others => False));

   function Is_Driver_Action (Frame : Byte_Array) return Boolean is
     (Frame'Length > Header_Length
      and then Frame (Frame'First) = MSG_DRIVER_ACTION);

   --  The action code of a valid MSG_DRIVER_ACTION frame
   function Driver_Action (Frame : Byte_Array) return Byte is
     (Frame (Frame'First + Header_Length))
     with Pre => Valid_Input_Frame (Frame) and then Is_Driver_Action (Frame);

   ---------------------------------------------------------------------
   --  Outputs
   ---------------------------------------------------------------------

   --  The code of a mode on the wire: its position in DMI 13.3 Table 60
   --  (dmi/supplementary_driving_info.ads). Passive Shunting has none:
   --  the desks are closed in M_PS and the DMI shows nothing.
   function Has_Mode_Code (Mode : Mode_T) return Boolean is (Mode /= M_PS);

   function Mode_Code (Mode : Mode_T) return Byte is
     (case Mode is
         when M_NP => 0,  when M_SB => 1,  when M_FS => 2,  when M_AD => 3,
         when M_SM => 4,  when M_LS => 5,  when M_OS => 6,  when M_SR => 7,
         when M_SH => 8,  when M_UN => 9,  when M_RV => 10, when M_TR => 11,
         when M_SN => 12, when M_PT => 13, when M_NL => 14, when M_SF => 15,
         when M_SL => 16, when M_IS => 17, when M_PS => 16#FF#)
     with Pre => Has_Mode_Code (Mode);

   --  The code of the level on the wire (DMI 8.2.3.2, the order of
   --  Supplementary_Driving_Info.Level_T): 0 unknown, 1 invalid, 2 level
   --  0, 3 NTC, 4 level 1, 5 level 2
   function Level_Code (Status : Level_Status_T; Level : Level_T) return Byte
   is (case Status is
          when Unknown => 0,
          when Invalid => 1,
          when Valid   => 2 + Level_T'Pos (Level));

   subtype Mode_Level_Frame_T is
     Byte_Array (1 .. Header_Length + Mode_Level_Length);

   --  MSG_MODE_LEVEL: the mode and the level, no acknowledgement asked,
   --  no level announced, no override, no TAF request, no LSSMA
   function Mode_Level_Frame (Mode   : Mode_T;
                              Status : Level_Status_T;
                              Level  : Level_T) return Mode_Level_Frame_T
   with Pre => Has_Mode_Code (Mode),
        Post => Mode_Level_Frame'Result (1) = MSG_MODE_LEVEL
                and then Mode_Level_Frame'Result (6) = Mode_Code (Mode)
                and then Mode_Level_Frame'Result (7)
                           = Level_Code (Status, Level);

   --  MSG_ONBOARD, field by field as dmi_protocol.ads defines it
   subtype Bits_T is Byte;
   type Onboard_T is record
      Data          : Bits_T := 0;  -- validity of the stored data
      Session       : Byte := 0;    -- 0 none .. 3
      RBC           : Bits_T := 0;
      Train         : Bits_T := 0;  -- the state of the vehicle
      National      : Bits_T := 0;  -- national values, VBC store
      SoM           : Byte := 0;    -- 0 none, 1 S0, 2 SoM possible
      Waiting       : Byte := 0;
      Start_Pending : Byte := 0;
      Radio         : Bits_T := 0;
      Radio_Wait    : Byte := 0;
      Answer        : Byte := 0;
   end record;

   --  Bits of Train
   Train_Standstill      : constant Bits_T := 1;
   Train_Below_Override  : constant Bits_T := 2;
   Train_Non_Leading     : constant Bits_T := 4;
   Train_Passive_Shunting : constant Bits_T := 8;
   --  Bits of National
   National_Driver_ID_Running : constant Bits_T := 1;
   National_Adhesion          : constant Bits_T := 2;
   National_VBC_Room          : constant Bits_T := 4;
   National_VBC_Stored        : constant Bits_T := 8;
   --  SoM
   SoM_Possible : constant Byte := 2;

   subtype Onboard_Frame_T is Byte_Array (1 .. Header_Length + Onboard_Length);

   function Onboard_Frame (Onboard : Onboard_T) return Onboard_Frame_T
     with Post => Onboard_Frame'Result (1) = MSG_ONBOARD;

end EVC_DMI_Port;
