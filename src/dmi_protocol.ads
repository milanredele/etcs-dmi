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

   -- UI -> DMI
   MSG_POINTER : constant Msg_Type_T := 16#50#;
   --  event u8 (0 down, 1 up, 2 move), x u16, y u16
   Pointer_Length : constant := 5;

   -- DMI -> EVC
   MSG_DRIVER_ACTION : constant Msg_Type_T := 16#40#;
   --  action u8, arg u16
   Driver_Action_Length : constant := 3;

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
