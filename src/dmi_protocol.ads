--  ETCS DMI
--  Protocol v2 for EVC <-> DMI <-> test UI communication.
--
--  Every message is framed as:
--     type    : 1 byte
--     length  : 4 bytes, little endian (payload length in bytes)
--     payload : <length> bytes
--  Transport integrity is provided by TCP; there is no per-frame CRC.
--
--  Message directions:
--     EVC -> DMI : SPEED_STATE, MODE_LEVEL, ONBOARD
--     UI  -> DMI : POINTER
--     DMI -> EVC : DRIVER_ACTION
--     DMI -> UI  : FRAME, SOUND
--
--  All multi-byte fields are little endian.

with Ada.Streams; use Ada.Streams;
with Interfaces;  use Interfaces;

package DMI_Protocol is

   type Msg_Type_T is new Unsigned_8;

   -- EVC -> DMI
   MSG_SPEED_STATE : constant Msg_Type_T := 16#01#;
   --  v_cur u16, v_perm u16, v_target u16, v_release u16, v_sbi u16,
   --  v_wsl u16, d_target u32, monitoring u8 (0 CSM / 1 TSM / 2 RSM),
   --  dial_range u8 (0..3 -> 140/180/250/400),
   --  flags u8 (bit0 vrelease_exists, bit1 csm_target_info),
   --  status u8 (0 NoS / 1 IndS / 2 OvS / 3 WaS / 4 IntS): the supervision
   --  status is a result of the on-board speed and distance monitoring
   --  (DMI 7.1.1.1), the DMI does not derive it,
   --  mrdt u8: identity of the most relevant displayed target, any value;
   --  a change while in TSM is a change of MRDT (DMI 7.4.1.1)
   Speed_State_Length : constant := 21;

   MSG_MODE_LEVEL : constant Msg_Type_T := 16#02#;
   --  mode u8 (Mode_T'Pos), level u8 (Level_T'Pos),
   --  mode_ack u8 (16#FF# none, else Mode_T'Pos),
   --  level_ann u8 (16#FF# none, else Level_T'Pos), level_ann_ack u8 (bool),
   --  override u8 (bool), taf u8 (bool), lssma u16 (16#FFFF# not shown)
   Mode_Level_Length : constant := 9;

   MSG_TEXT : constant Msg_Type_T := 16#03#;
   --  id u16, flags u8 (bit0 ack_required, bit1 first_group/bold,
   --  bits2-3 class: 0 fixed text, 1 plain text, 2 system status, 3 NTC),
   --  hour u8, minute u8, length u8, text bytes (Latin-1)
   --  MSG_TEXT carries the free texts: the fixed and plain text messages
   --  of the trackside. The system status messages of chapter 15 come as
   --  MSG_SYSTEM_STATUS. Class 2 is still accepted, and such a message is
   --  a first group message whatever bit1 says (8.2.3.4.7 a: the first
   --  group contains the system status messages).
   --  The length covers L_TEXT of SUBSET-026 7.5.1.53 (0 .. 255) and the
   --  DMI keeps all of it. Limit of the DMI (DMI_Text_Messages): 12
   --  messages are stored, see there for what gives way when the store
   --  is full.
   Text_Header_Length : constant := 6;

   MSG_TEXT_REMOVE : constant Msg_Type_T := 16#04#;
   --  id u16
   Text_Remove_Length : constant := 2;

   MSG_TRACK_COND : constant Msg_Type_T := 16#05#;
   --  count u8, then per entry: id u8, kind u8
   --  kind: 1..37 = TC symbol number, 38 = LX01 level crossing
   Track_Cond_Entry_Length : constant := 2;

   MSG_PLANNING : constant Msg_Type_T := 16#06#;
   --  ma_dist u16 (m; end of MA / first zero-speed target),
   --  indication_dist u16 (16#FFFF# none),
   --  next_advice_dist u16 (16#FFFF# none),
   --  ceiling_speed u16 (km/h at current front),
   --  gradient count u8, per entry: start u16, value i8 (permille)
   --  speed profile count u8, per entry: dist u16,
   --    speed u16 (bits 0-14 km/h, bit 15 target of the indication marker)
   --  order count u8, per entry: symbol u8 (PL number), dist u16
   --  The length must be exactly what the three counts describe; any
   --  other message is ignored as a whole, as is one with a ceiling
   --  speed above 400 km/h.
   --  Limits of the DMI (DMI_Planning): 64 gradients, 32 speed profile
   --  entries, 32 orders, distances up to 32000 m (the longest range, DMI
   --  8.3.3.4), speeds up to 400 km/h. Gradients and speed profile
   --  entries must come by ascending distance. A profile is cut at the
   --  first entry that breaks these rules or finds no room: the DMI
   --  draws it up to there and nothing beyond, so send the nearest
   --  entries first and no more than the limits. Orders may come in any
   --  order; unknown symbols are left out, and of more than 32 orders
   --  the nearest 32 are kept.
   Planning_Gradient_Entry_Length : constant := 3;
   Planning_Speed_Entry_Length    : constant := 4;
   Planning_Order_Entry_Length    : constant := 3;

   MSG_STATUS : constant Msg_Type_T := 16#07#;
   --  brake u8 (0 none, 1 shown, 2 shown + ack required, 3 shown, applied
   --  because a requested acknowledgement of a level, a mode or a text
   --  message is pending: its release comes with that acknowledgement and
   --  plays no Sinfo, DMI 8.2.2.3.4.1 / 8.2.2.3.6),
   --  radio u8 (0 no connection, 1 up, 2 lost/failed),
   --  adhesion u8 (bool slippery), bmm u8 (bool), reversing u8 (bool),
   --  sm_direction u8 (0 none, 1 forward, 2 backward),
   --  set_speed u16 (16#FFFF# none),
   --  tti u8 (seconds, 16#FF# none), t_disp_tti u8 (seconds),
   --  tunnel u8 (0 unknown, 1 active, 2 announced), tunnel_dist u32,
   --  geo_pos u32 (m, 16#FFFF_FFFF# unknown),
   --  hour u8, minute u8, second u8
   Status_Length : constant := 22;

   MSG_ONBOARD : constant Msg_Type_T := 16#0A#;
   --  On-board state the DMI cannot know but needs for the enabling
   --  conditions of the sub-level window buttons (DMI 11.2.1.4 Table 33,
   --  11.2.2.4 Table 34, 11.2.3.4 Table 35, 11.2.4.4 Table 36) and for
   --  the dialogue sequences of 11.7. It is the on-board's own data
   --  status (SUBSET-026 3.18, 4.10), its session with the RBC and the
   --  inputs of the vehicle; the DMI evaluates the tables, it does not
   --  guess the values. Every byte value is defined here; a value not
   --  listed takes the "nothing known" reading of its field.
   --
   --  data u8: validity of the stored data as the EVC sees it
   --    bit0 Driver ID is valid, bit1 Train data are valid,
   --    bit2 ERTMS/ETCS level is valid, bit3 Train running number is
   --    valid, bit4 RBC contact information is valid,
   --    bit5 the train position is valid and is referred to an LRBG,
   --    bit6 safe consist length information is available,
   --    bit7 the safe consist length values in front of the engine are
   --         equal to zero
   --  session u8: the communication session with the RBC
   --    0 no communication session exists, 1 a session is being
   --    established, 2 a communication session exists, 3 a session
   --    exists and it is the only one with a supervising RBC certified
   --    with a system version X.Y > 2.2 (Table 33 #11); any other value
   --    is read as 0
   --  rbc u8: what the RBC has answered / what is stored on-board
   --    bit0 Train data acknowledged by the RBC, bit1 a pending
   --    emergency stop is stored on-board, bit2 an RBC transition order
   --    is stored on-board, bit3 the distance between the current min
   --    safe rear end and the current estimated front end does not
   --    exceed the range of the confirmed train length information,
   --    bit4 safe consist length information has been sent to the RBC
   --    and has been acknowledged by it
   --  train u8: the state of the vehicle
   --    bit0 the train is at standstill, bit1 the train speed is under
   --    or equal to the speed limit for triggering the "override"
   --    function, bit2 the "non leading" input signal is received,
   --    bit3 the "passive shunting" input signal is received,
   --    bit4 the "BTM alarm reaction inhibition" function is active
   --  national u8: national values and on-board storage
   --    bit0 modification of Driver ID while running is allowed,
   --    bit1 modification of adhesion factor by driver is allowed,
   --    bit2 the maximum on-board storage capacity of VBC set by the
   --    driver is not reached, bit3 at least one VBC is stored on-board
   --  som u8: start of mission (SUBSET-026 5.4, DMI Table 49)
   --    0 no start of mission is going on,
   --    1 the cab is active and the mode is SB but a communication
   --      session is still established or is being established (S0),
   --    2 all conditions to initiate a start of mission are fulfilled:
   --      the Start Up dialogue sequence is engaged (S0 -> S1). The DMI
   --      engages it on the change to 2, not on every message.
   --    any other value is read as 0
   --  waiting u8: the on-board awaits an answer and the DMI shows the
   --    Main window with all buttons disabled and the hour glass ST05
   --    (11.2.1.6)
   --    0 nothing is awaited,
   --    1 the registration to the radio network(s) (Table 49 S4),
   --    2 an answer from the RBC (Table 49 A31, Table 50 S8 and S9):
   --      the Main window stays when it ends (S10 / S1),
   --    3 the MA or the SR authorisation after 'Start' (Table 50 S7):
   --      the default window is shown when it ends,
   --    any other non-zero value is read as 2
   --  start_pending u8: non-zero while a 'Start' request of the driver
   --    is pending on the EVC. Only the EVC knows when its answer (a new
   --    mode, or a mode proposed for acknowledgement) is out; 'Start' is
   --    dead meanwhile so that one press is one request (Table 33 #1).
   Onboard_Length : constant := 8;

   MSG_SYSTEM_STATUS : constant Msg_Type_T := 16#0C#;
   --  An event of a system status message of the catalogue of chapter 15
   --  (Tables 68 and 70). The EVC detects the SUBSET-026 conditions and
   --  reports them; the DMI owns the rest (DMI_System_Status): the text
   --  and its case (15.1.1.3), the first group / bold (8.2.3.4.7 a), the
   --  acknowledgement (15.1.1.4), the time stamp (its clock, MSG_STATUS),
   --  the 30 s timers, the end by a button of the Main window, the end by
   --  a mode change (15.1.1.2) and the single instance (15.1.1.7).
   --    entry u8: catalogue entry number, one of the SS_* below; any
   --      other value: the message is ignored
   --    event u8: 0 start: the start condition of a row of the entry is
   --                fulfilled (a start while the entry is displayed is a
   --                second instance, 15.1.1.7);
   --              1 end: the end condition of SUBSET-026 that the entry
   --                names is fulfilled, and, for the entries of a brake
   --                command reason, that reason is revoked by a mode
   --                change as per 4.12.1.2 (15.1.1.6). Ignored by the
   --                entries whose end the DMI owns alone (Trackside
   --                malfunction, Train is rejected, ...).
   --              2 the event that starts the 30 s of an entry "displayed
   --                for 30 s once / from ...": 3.14.1.6 fulfilled (SS 1),
   --                a train movement is detected (SS 17). Ignored by the
   --                other entries.
   --              any other value: the message is ignored
   --  An end or an intermediate event for an entry that is not displayed
   --  is ignored. The catalogue entries: a row group of Table 68 / 70
   --  with the same text, end condition and Table 4.7.2 row of
   --  SUBSET-026 (start conditions in brackets):
   SS_Balise_Read_Error_Brake : constant := 1;
   --  "Balise read error" (3.16.2.4.4.3, 3.16.2.5.3, 3.16.2.6.1,
   --  3.16.2.7.1.1, 3.16.2.7.2.2): 30 s from event 2 (3.14.1.6)
   SS_Balise_Read_Error_Trip : constant := 2;
   --  "Balise read error" (4.6.3 [17], [66]): end = PT mode left,
   --  4.6.3 [62], [63], [68]
   SS_Trackside_Malfunction : constant := 3;
   --  (3.16.2.4.9): 30 s from the start
   SS_Communication_Error_Brake : constant := 4;
   --  "Communication error" (3.16.3.4.1): end = 3.14.1.7 or the brake
   --  command reason revoked (4.12.1.2), not before 30 s displayed
   SS_Communication_Error_Trip : constant := 5; -- (4.6.3 [41])
   SS_Entering_FS : constant := 6; -- (4.4.9.1.4): end = 4.4.9.1.4
   SS_Entering_OS : constant := 7; -- (4.4.12.1.7): end = 4.4.12.1.7
   SS_Entering_SM : constant := 8; -- (4.4.21.1.6): end = 4.4.21.1.6
   SS_Runaway_Movement : constant := 9;
   --  (3.14.2.4, 3.14.3.2, 3.14.4.2 and 3.14.4.5, 3.18.3.3.1,
   --  4.4.11.1.5.1): end = 3.14.1.5
   SS_SM_Refused : constant := 10;        -- (5.21.2 A220): Main window
   SS_SM_Request_Failed : constant := 11; -- (5.21.4.1): Main window
   SS_SH_Refused : constant := 12;        -- (5.6.2 A220): Main window
   SS_SH_Refused_Trip : constant := 13;   -- (4.6.3 [35]): end = [63]
   SS_SH_Request_Failed : constant := 14; -- (5.6.4.1.2): Main window
   SS_Trackside_Not_Compatible : constant := 15;
   --  (3.5.3.7 d) 2nd bullet): 30 s from the start
   SS_Trackside_Not_Compatible_Trip : constant := 16; -- (4.6.3 [65])
   SS_Train_Data_Changed : constant := 17;
   --  (5.17.2.2 A1): 30 s from event 2 (a train movement is detected)
   SS_Train_Data_Changed_Brake : constant := 18;
   --  (5.17.2.2 S2, S4): end = 5.17.2.2 S3 (E3), S5 (E5)
   SS_Safe_Consist_Length : constant := 19;
   --  "Safe consist length no longer available" (4.4.21.1.12): end =
   --  3.14.1.7.6 or the brake command reason revoked (4.12.1.2), not
   --  before 30 s displayed
   SS_Train_Rejected : constant := 20;    -- (5.4.3.2 A40): Main window
   SS_Unauthorized_Passing : constant := 21;
   --  "Unauthorized passing of EOA / LOA" (4.6.3 [11], [12], [16], [18],
   --  [43])
   SS_No_MA_Level_Transition : constant := 22; -- (4.6.3 [39], [67])
   SS_SR_Distance_Exceeded : constant := 23;   -- (4.6.3 [42])
   SS_SH_Stop_Order : constant := 24;          -- (4.6.3 [49], [52])
   SS_SR_Stop_Order : constant := 25;
   --  (4.6.3 [36], 4.6.3 [54] (X >= 2), 6.6.2.2.2 (X = 1))
   SS_Emergency_Stop : constant := 26;         -- (4.6.3 [20])
   SS_RV_Distance_Exceeded : constant := 27;
   --  (3.15.4.8, 4.4.18.1.4): end = 3.14.1.7.1
   SS_PT_Distance_Exceeded : constant := 28;
   --  (4.4.14.1.3, 4.4.14.1.3.2): end = 3.14.1.7.4
   SS_No_Track_Description : constant := 29;   -- (4.6.3 [69])
   SS_Route_Unsuitable_Gauge : constant := 30;
   --  (3.12.2.3 a)): end = route suitability data deleted (A.3.4,
   --  3.7.3.2 d), 3.7.3.1 h) with 3.12.2.3 a) not fulfilled)
   SS_Route_Unsuitable_Traction : constant := 31; -- (3.12.2.3 b)), idem
   SS_Route_Unsuitable_Axle_Load : constant := 32; -- (3.12.2.3 c)), idem
   SS_FRMCS_Registration_Failed : constant := 33;
   --  (5.4.3.2 A41, A42, A43): end = the driver elects to perform the
   --  mission with only one radio system, or Main window
   SS_GSMR_Registration_Failed : constant := 34;
   --  (5.4.3.2 A29, A42, A43): idem
   SS_NL_No_Longer_Permitted : constant := 35;
   --  (4.4.15.1.1.3): to be acknowledged (15.1.1.4.1), ends when
   --  acknowledged
   SS_Odometer_Impaired : constant := 36;      -- (3.6.8.5): end = 3.6.8.6
   SS_ATO_Needs_Data : constant := 37;
   --  Table 70 (SUBSET-125 7.14.2.13): end = 7.14.2.14
   SS_ATO_Runaway_Movement : constant := 38;
   --  "Runaway movement", Table 70 (SUBSET-125 7.14.2.18): end = 7.14.2.18
   --  The trip reason entries (2, 5, 13, 16, 21 .. 26, 29) end with
   --  "PT mode left, 4.6.3 [62], [63]" and [68] where the row says so.
   --  "Main window": ends as soon as any button of the Main window is
   --  selected, which the DMI detects and reports (driver action 16).
   --  Not in the catalogue: "[name of NTC] brake demand" (Table 68) and
   --  Table 69, which need the name of a National System (15.1.1.5): NTC
   --  is out of scope.
   System_Status_Length : constant := 2;

   -- EVC simulator -> UI (visualization; the DMI ignores these)
   MSG_TRACK_LAYOUT : constant Msg_Type_T := 16#08#;
   --  eoa u32, release_speed u8,
   --  mrsp count u8, per entry: start u32, speed u16
   --  gradient count u8, per entry: start u32, value i8 (permille)
   --  condition count u8, per entry: symbol u8 (TC number),
   --    announce u32, start u32, end u32
   --  lx_from u32, lx_at u32,
   --  tunnel_announce u32, tunnel_start u32, tunnel_end u32,
   --  level_ann u32, level_transition u32, taf u32
   --  (all distances in metres from the mission start)

   MSG_SIM_STATE : constant Msg_Type_T := 16#09#;
   --  position u32 (m), speed u16 (km/h),
   --  mode u8 (0 SB / 1 SR / 2 FS / 3 TR),
   --  monitoring u8 (0 CSM / 1 TSM / 2 RSM),
   --  demand i8 (-100..100), brake_commanded u8
   Sim_State_Length : constant := 10;

   -- UI -> DMI
   MSG_POINTER : constant Msg_Type_T := 16#50#;
   --  event u8 (0 down, 1 up, 2 move), x u16, y u16
   Pointer_Length : constant := 5;

   -- UI -> EVC simulator
   MSG_DESK : constant Msg_Type_T := 16#51#;
   --  demand i8 (-100 full brake .. 100 full traction), auto_drive u8
   Desk_Length : constant := 2;

   -- DMI -> EVC
   MSG_DRIVER_ACTION : constant Msg_Type_T := 16#40#;
   --  action u8, arg u16; action 2 (ack) only: followed by id u16
   --  actions: 0 TAF yes, 1 speed toggle, 2 ack (see below),
   --  3 tunnel toggle, 4 geo toggle, 5 start mission, 6 override EOA,
   --  7 shunting request, 8 exit shunting, 9 adhesion (arg 0/1),
   --  10 train integrity confirmed, 11 level selected (arg Level_T'Pos),
   --  12 non-leading,
   --  16 a button of the Main window was selected (arg 0): sent when the
   --     selection ends a displayed system status message whose end
   --     condition is "as soon as any button in the main window is
   --     selected" (Table 68, MSG_SYSTEM_STATUS), before the action of
   --     the button itself, so that the on-board applies that end too;
   --     not sent when no such message is displayed
   Driver_Action_Length : constant := 3;
   --  Action 2, the driver's acknowledgement (DMI 5.4.1), names the one
   --  request it answers. Its payload is Driver_Ack_Length bytes:
   --    action u8 = 2,
   --    arg u16   = kind (DMI_Ack.Ack_Kind_T'Pos): 0 level transition,
   --                1 mode change, 2 fixed text message, 3 plain text
   --                message, 4 system status message, 5 brake release,
   --                6 NTC text message,
   --    id u16    = for kinds 2, 3, 4 and 6 the id of the acknowledged
   --                text message as given in MSG_TEXT; 0 otherwise.
   --                A system status message of MSG_SYSTEM_STATUS (kind 4)
   --                is named by 16#8000# + its catalogue entry number
   --                (SS_*), so an EVC that still sends MSG_TEXT class 2
   --                messages to be acknowledged keeps their ids below
   --                16#8000# to tell the two apart.
   --  All other actions keep the Driver_Action_Length payload. A receiver
   --  accepts both lengths and ignores an action 2 of the short form
   --  (it does not say what was acknowledged).
   Driver_Ack_Length : constant := 5;

   MSG_DRIVER_DATA : constant Msg_Type_T := 16#41#;
   --  kind u8, then:
   --   0 driver id  : len u8, Latin-1 bytes
   --   1 TRN        : len u8, Latin-1 bytes
   --   2 train data : the seven items of the flexible train data entry
   --                  (DMI 11.3.9.6 b, Table 40), sent once the driver
   --                  validated them (DMI 11.7.1.6.1):
   --                    length u16 (m, L_TRAIN),
   --                    brake percentage u16 (%),
   --                    max speed u16 (km/h, V_MAXTRAIN),
   --                    train category cd u8 (NC_CDTRAIN, SUBSET-026
   --                      7.5.1.82.2), 16#FF# no value,
   --                    train category other u16 (NC_TRAIN, 7.5.1.84,
   --                      a bit set; 0 no value),
   --                    axle load category u8 (M_AXLELOADCAT, 7.5.1.62),
   --                      16#FF# no value,
   --                    airtight u8 (M_AIRTIGHT, 7.5.1.61), 16#FF# no
   --                      value,
   --                    loading gauge u8 (M_LOADINGGAUGE, 7.5.1.68),
   --                      16#FF# no value
   --   3 SR data    : speed u16, distance u16
   Driver_Data_Train_Length : constant := 13;

   -- DMI -> UI
   MSG_FRAME : constant Msg_Type_T := 16#60#;
   --  x u16, y u16, w u16, h u16, pixels w*h bytes (colour indices)

   MSG_SOUND : constant Msg_Type_T := 16#61#;
   --  sound u8 (0 click, 1 sinfo, 2 s1, 3 s2 start, 4 s2 stop)
   Sound_Length : constant := 1;

   Header_Length : constant := 5;

   -- Little endian primitives over Stream_Element_Array; Offset always
   -- points at the next element to read or write and is advanced.

   procedure Put_U8 (Buffer : in out Stream_Element_Array;
                     Offset : in out Stream_Element_Offset;
                     Value  : Unsigned_8);

   procedure Put_U16 (Buffer : in out Stream_Element_Array;
                      Offset : in out Stream_Element_Offset;
                      Value  : Unsigned_16);

   procedure Put_U32 (Buffer : in out Stream_Element_Array;
                      Offset : in out Stream_Element_Offset;
                      Value  : Unsigned_32);

   function Get_U8 (Buffer : Stream_Element_Array;
                    Offset : in out Stream_Element_Offset) return Unsigned_8;

   function Get_U16 (Buffer : Stream_Element_Array;
                     Offset : in out Stream_Element_Offset) return Unsigned_16;

   function Get_U32 (Buffer : Stream_Element_Array;
                     Offset : in out Stream_Element_Offset) return Unsigned_32;

   procedure Put_Header (Buffer   : in out Stream_Element_Array;
                         Offset   : in out Stream_Element_Offset;
                         The_Type : Msg_Type_T;
                         Length   : Natural);

end DMI_Protocol;
