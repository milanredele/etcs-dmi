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
--     EVC -> DMI : SPEED_STATE, MODE_LEVEL
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
   --  flags u8 (bit0 vrelease_exists, bit1 csm_target_info,
   --            bit2 brake_commanded)
   Speed_State_Length : constant := 19;

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
   --  speed profile count u8, per entry: dist u16, speed u16
   --  order count u8, per entry: symbol u8 (PL number), dist u16

   MSG_STATUS : constant Msg_Type_T := 16#07#;
   --  brake u8 (0 none, 1 shown, 2 shown + ack required),
   --  radio u8 (0 no connection, 1 up, 2 lost/failed),
   --  adhesion u8 (bool slippery), bmm u8 (bool), reversing u8 (bool),
   --  sm_direction u8 (0 none, 1 forward, 2 backward),
   --  set_speed u16 (16#FFFF# none),
   --  tti u8 (seconds, 16#FF# none), t_disp_tti u8 (seconds),
   --  tunnel u8 (0 unknown, 1 active, 2 announced), tunnel_dist u32,
   --  geo_pos u32 (m, 16#FFFF_FFFF# unknown),
   --  hour u8, minute u8, second u8
   Status_Length : constant := 22;

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
   --  action u8, arg u16
   --  actions: 0 TAF yes, 1 speed toggle, 2 ack (arg Ack_Kind'Pos),
   --  3 tunnel toggle, 4 geo toggle, 5 start mission, 6 override EOA,
   --  7 shunting request, 8 exit shunting, 9 adhesion (arg 0/1),
   --  10 train integrity confirmed, 11 level selected (arg Level_T'Pos),
   --  12 non-leading
   Driver_Action_Length : constant := 3;

   MSG_DRIVER_DATA : constant Msg_Type_T := 16#41#;
   --  kind u8, then:
   --   0 driver id  : len u8, Latin-1 bytes
   --   1 TRN        : len u8, Latin-1 bytes
   --   2 train data : length u16, brake percentage u16, max speed u16
   --   3 SR data    : speed u16, distance u16

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
