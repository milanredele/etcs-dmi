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
--  Phase E2: MSG_STATUS, for the geographical position (SUBSET-026
--  3.6.6), in every cycle while it is known and once when it stops.

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
   MSG_STATUS        : constant Byte := 16#07#;
   MSG_ONBOARD       : constant Byte := 16#0A#;
   Mode_Level_Length : constant := 9;
   Status_Length     : constant := 23;
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

   --  "None" in the code fields of MSG_MODE_LEVEL (mode_ack, level_ann)
   No_Code : constant Byte := 16#FF#;

   --  MSG_MODE_LEVEL: the mode and the level; phase E4: the
   --  acknowledgement of a mode (Mode_Ack: the code of the mode, No_Code
   --  none; the start of mission's proposal, 5.4.3.2, or the request of
   --  a procedure, 5.7, 5.9, 5.11, 5.13, 5.19), the level announced
   --  (Level_Ann: the code of the level, No_Code none) and whether its
   --  acknowledgement is asked (5.10), "override active" (5.8.3.7); no
   --  TAF request, no LSSMA (phase E5)
   function Mode_Level_Frame (Mode          : Mode_T;
                              Status        : Level_Status_T;
                              Level         : Level_T;
                              Mode_Ack      : Byte := No_Code;
                              Level_Ann     : Byte := No_Code;
                              Level_Ann_Ack : Boolean := False;
                              Override      : Boolean := False)
     return Mode_Level_Frame_T
   with Pre => Has_Mode_Code (Mode),
        Post => Mode_Level_Frame'Result (1) = MSG_MODE_LEVEL
                and then Mode_Level_Frame'Result (6) = Mode_Code (Mode)
                and then Mode_Level_Frame'Result (7)
                           = Level_Code (Status, Level)
                and then Mode_Level_Frame'Result (8) = Mode_Ack
                and then Mode_Level_Frame'Result (9) = Level_Ann;

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

   --  Bits of Data
   Data_Level_Valid    : constant Bits_T := 4;
   Data_Position_Valid : constant Bits_T := 32;  -- valid, referred to an LRBG
   --  added by e4/modes
   Data_Driver_ID_Valid  : constant Bits_T := 1;
   Data_Train_Data_Valid : constant Bits_T := 2;
   Data_TRN_Valid        : constant Bits_T := 8;
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

   subtype Status_Frame_T is Byte_Array (1 .. Header_Length + Status_Length);

   --  No geographical position (geo_pos)
   Geo_Unknown : constant Unsigned_32 := 16#FFFF_FFFF#;

   --  MSG_STATUS as far as the on-board knows it in phase E2: no brake
   --  command, no radio connection, no adhesion, BMM, reversing or SM
   --  indication, no set speed, no TTI (TdispTTI 14 s, SUBSET-026
   --  A.3.1), no tunnel; the geographical position Geo in m; the time of
   --  the on-board clock, Seconds since power-up, as EVC_Mock does (the
   --  clock of 3.20 is later)
   function Status_Frame (Geo : Unsigned_32; Seconds : Unsigned_64)
     return Status_Frame_T
     with Post => Status_Frame'Result (1) = MSG_STATUS;

   ---------------------------------------------------------------------
   --  Phase E3 (profiles): the planning and the track conditions
   ---------------------------------------------------------------------

   MSG_TRACK_COND : constant Byte := 16#05#;
   MSG_PLANNING   : constant Byte := 16#06#;

   subtype Frame_Buffer_T is Byte_Array (1 .. Max_Frame_Length);

   --  MSG_TRACK_COND: count u8, then per entry id u8, kind u8 (TC symbol
   --  number 1 .. 37, 38 the level crossing)
   Max_Track_Cond : constant := 16;
   type Track_Cond_Entry_T is record
      Id   : Byte := 0;
      Kind : Byte := 0;
   end record;
   type Track_Cond_List_T is array (1 .. Max_Track_Cond)
     of Track_Cond_Entry_T;

   procedure Track_Cond_Frame (Count  : Natural;
                               List   : Track_Cond_List_T;
                               Frame  : out Frame_Buffer_T;
                               Last   : out Natural)
     with Pre => Count <= Max_Track_Cond,
          Post => Last = Header_Length + 1 + 2 * Count
                  and then Frame (1) = MSG_TRACK_COND;

   --  MSG_PLANNING (dmi_protocol.ads): four u16 (the distance to the
   --  end of the MA in m, the indication marker, the next advice change,
   --  the ceiling speed in km/h), then the gradients (start u16 m, value
   --  i8 per mille), the speed profile (distance u16 m, speed u16 km/h,
   --  bit 15 for the target of the indication marker) and the orders
   --  (symbol u8, distance u16 m), each list after its count u8
   Max_Planning_Gradients : constant := 64;
   Max_Planning_Speeds    : constant := 32;
   Max_Planning_Orders    : constant := 32;
   No_Distance            : constant Unsigned_16 := 16#FFFF#;

   type Planning_Gradient_T is record
      Start : Unsigned_16 := 0;
      Value : Integer range -128 .. 127 := 0;
   end record;
   type Planning_Speed_T is record
      Dist  : Unsigned_16 := 0;
      Speed : Unsigned_16 := 0;
   end record;
   type Planning_Order_T is record
      Symbol : Byte := 0;
      Dist   : Unsigned_16 := 0;
   end record;
   type Planning_Gradients_T is array (1 .. Max_Planning_Gradients)
     of Planning_Gradient_T;
   type Planning_Speeds_T is array (1 .. Max_Planning_Speeds)
     of Planning_Speed_T;
   type Planning_Orders_T is array (1 .. Max_Planning_Orders)
     of Planning_Order_T;

   type Planning_T is record
      MA_Dist         : Unsigned_16 := 0;
      Indication_Dist : Unsigned_16 := No_Distance;
      Advice_Dist     : Unsigned_16 := No_Distance;
      Ceiling         : Unsigned_16 := 0;
      Gradient_Count  : Natural range 0 .. Max_Planning_Gradients := 0;
      Gradients       : Planning_Gradients_T;
      Speed_Count     : Natural range 0 .. Max_Planning_Speeds := 0;
      Speeds          : Planning_Speeds_T;
      Order_Count     : Natural range 0 .. Max_Planning_Orders := 0;
      Orders          : Planning_Orders_T;
   end record;

   function Planning_Length (P : Planning_T) return Natural is
     (8 + 1 + 3 * P.Gradient_Count + 1 + 4 * P.Speed_Count
      + 1 + 3 * P.Order_Count);

   procedure Planning_Frame (P     : Planning_T;
                             Frame : out Frame_Buffer_T;
                             Last  : out Natural)
     with Post => Last = Header_Length + Planning_Length (P)
                  and then Frame (1) = MSG_PLANNING;

   ---------------------------------------------------------------------
   --  Added by supervision (phase E3): MSG_SPEED_STATE, the fields of
   --  MSG_STATUS of the speed and distance monitoring and of the brake
   --  command handling, the driver's acknowledgement of a brake release
   ---------------------------------------------------------------------

   MSG_SPEED_STATE    : constant Byte := 16#01#;
   Speed_State_Length : constant := 21;

   --  MSG_SPEED_STATE, field by field as dmi_protocol.ads defines it:
   --  speeds in km/h, the distance to target in m, monitoring 0 CSM / 1
   --  TSM / 2 RSM, dial range 0 .. 3 (140 / 180 / 250 / 400 km/h), flags
   --  (bit 0 the release speed is shown, bit 1 target information in
   --  CSM), status 0 NoS .. 4 IntS, MRDT the number of the most relevant
   --  displayed target
   type Speed_State_T is record
      V_Cur, V_Perm, V_Target, V_Release, V_SBI, V_Wsl : Unsigned_16 := 0;
      D_Target   : Unsigned_32 := 0;
      Monitoring : Byte := 0;
      Dial_Range : Byte := 1;
      Flags      : Byte := 0;
      Status     : Byte := 0;
      MRDT       : Byte := 0;
   end record;

   Flag_Release_Shown : constant Byte := 1;
   Flag_CSM_Target    : constant Byte := 2;

   subtype Speed_State_Frame_T is
     Byte_Array (1 .. Header_Length + Speed_State_Length);

   function Speed_State_Frame (S : Speed_State_T) return Speed_State_Frame_T
     with Post => Speed_State_Frame'Result (1) = MSG_SPEED_STATE;

   --  MSG_STATUS brake: 0 none, 1 the on-board commands a brake (DMI
   --  8.2.2.3.x, ST01), 2 and asks the driver to acknowledge its release
   --  (SUBSET-026 3.14.1.9)
   Brake_None    : constant Byte := 0;
   Brake_Applied : constant Byte := 1;
   Brake_Ack     : constant Byte := 2;
   --  phase E4: applied because a requested acknowledgement of a level, a
   --  mode or a text message is pending (its release comes with that
   --  acknowledgement, dmi_protocol.ads; 3.14.1.7.2, 3.14.1.7.3,
   --  3.14.1.7.5)
   Brake_Ack_Pending : constant Byte := 3;

   --  No time to Indication (tti)
   TTI_None : constant Unsigned_16 := 16#FFFF#;

   --  MSG_STATUS with the brake indication and the time to Indication
   --  (tenths of a second) of the supervision (phase E3); phase E4: the
   --  reversing indication (3.15.4.7) and the tunnel stopping area
   --  (5.18.8: tunnel 0 none / unknown, 1 active, 2 announced; its
   --  distance, m); the other fields as Status_Frame
   function Status_Frame (Geo         : Unsigned_32;
                          Seconds     : Unsigned_64;
                          Brake       : Byte;
                          TTI         : Unsigned_16;
                          Reversing   : Boolean := False;
                          Tunnel      : Byte := 0;
                          Tunnel_Dist : Unsigned_32 := 0)
     return Status_Frame_T
     with Post => Status_Frame'Result (1) = MSG_STATUS;

   --  The acknowledgement kind of a brake release (DMI_Ack, the arg of
   --  MSG_DRIVER_ACTION 2)
   Ack_Brake_Release : constant := 5;

   --  A valid MSG_DRIVER_ACTION that acknowledges a brake release
   function Is_Brake_Release_Ack (Frame : Byte_Array) return Boolean is
     (Frame'Length = Header_Length + Driver_Ack_Length
      and then Frame (Frame'First) = MSG_DRIVER_ACTION
      and then Frame (Frame'First + Header_Length) = Action_Ack
      and then Get_U16 (Frame, Frame'First + Header_Length + 1)
                 = Ack_Brake_Release);

   ---------------------------------------------------------------------
   --  Phase E4 (e4/modes, e4/procedures): MSG_SYSTEM_STATUS, the text
   --  messages (MSG_TEXT, MSG_TEXT_REMOVE), the BTM alarm reaction
   --  inhibition in MSG_ONBOARD
   ---------------------------------------------------------------------

   --  MSG_SYSTEM_STATUS (dmi_protocol.ads), an event of a system status
   --  message of the catalogue of the DMI's chapter 15: entry u8 (the
   --  catalogue number, SS_* below as dmi_protocol.ads has them), event
   --  u8 (0 start, 1 end, 2 the event that starts the 30 s of an entry)
   MSG_SYSTEM_STATUS    : constant Byte := 16#0C#;
   System_Status_Length : constant := 2;
   SS_Event_Start       : constant Byte := 0;
   SS_Event_End         : constant Byte := 1;
   SS_Event_Timer       : constant Byte := 2;

   --  The entries the on-board reports (the catalogue of dmi_protocol.ads;
   --  evc_test checks that the numbers are the same)
   SS_Balise_Read_Error_Trip        : constant := 2;   -- [17], [66]
   SS_Entering_FS                   : constant := 6;   -- 4.4.9.1.4
   SS_Entering_OS                   : constant := 7;   -- 4.4.12.1.7
   SS_Trackside_Not_Compatible_Trip : constant := 16;  -- [65]
   SS_Train_Data_Changed            : constant := 17;  -- 5.17.2.2 A1
   SS_Train_Data_Changed_Brake      : constant := 18;  -- 5.17.2.2 S2, S4
   SS_Unauthorized_Passing          : constant := 21;  -- [12] [16] [18] [43]
   SS_No_MA_Level_Transition        : constant := 22;  -- [39], [67]
   SS_SR_Distance_Exceeded          : constant := 23;  -- [42]
   SS_SH_Stop_Order                 : constant := 24;  -- [49], [52]
   SS_SR_Stop_Order                 : constant := 25;  -- [54]
   SS_RV_Distance_Exceeded          : constant := 27;  -- 3.15.4.8
   SS_PT_Distance_Exceeded          : constant := 28;  -- 4.4.14.1.3
   SS_No_Track_Description          : constant := 29;  -- [69]
   SS_NL_No_Longer_Permitted        : constant := 35;  -- 4.4.15.1.1.3

   subtype System_Status_Frame_T is
     Byte_Array (1 .. Header_Length + System_Status_Length);

   function System_Status_Frame (Entry_Number, Event : Byte)
     return System_Status_Frame_T
   is ((MSG_SYSTEM_STATUS, System_Status_Length, 0, 0, 0,
        Entry_Number, Event));

   --  MSG_TEXT: id u16, flags u8 (bit 0 ack required, bit 1 first group,
   --  bits 2-3 class: 0 fixed text, 1 plain text), hour u8, minute u8,
   --  length u8, the text (Latin-1); MSG_TEXT_REMOVE: id u16
   MSG_TEXT           : constant Byte := 16#03#;
   MSG_TEXT_REMOVE    : constant Byte := 16#04#;
   Text_Header_Length : constant := 6;
   Text_Remove_Length : constant := 2;
   Text_Ack_Required  : constant Byte := 1;
   Text_First_Group   : constant Byte := 2;
   Text_Class_Plain   : constant Byte := 4;
   Max_Text_Length    : constant := 255;

   procedure Text_Frame (Id     : Unsigned_16;
                         Flags  : Byte;
                         Hour   : Byte;
                         Minute : Byte;
                         Text   : Byte_Array;
                         Frame  : out Frame_Buffer_T;
                         Last   : out Natural)
     with Pre => Text'Length <= Max_Text_Length,
          Post => Last = Header_Length + Text_Header_Length + Text'Length
                  and then Frame (1) = MSG_TEXT;

   subtype Text_Remove_Frame_T is
     Byte_Array (1 .. Header_Length + Text_Remove_Length);

   function Text_Remove_Frame (Id : Unsigned_16) return Text_Remove_Frame_T
   is ((MSG_TEXT_REMOVE, Text_Remove_Length, 0, 0, 0,
        Byte (Id and 16#FF#), Byte (Shift_Right (Id, 8))));

   --  MSG_ONBOARD train bit 4: the "BTM alarm reaction inhibition"
   --  function is active (5.22.4.1)
   Train_BMM_Inhibition : constant Bits_T := 16;

end EVC_DMI_Port;
