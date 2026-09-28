--  ETCS on-board (EVC)
--  What the on-board received from the track: the last telegram and the
--  last radio message it accepted, and the rejections by reason.
--
--  EVC_Core hands over the BTM and RTM inputs of a cycle at Read_Ports.
--  A telegram is parsed by ETCS_Telegram, a radio message by
--  ETCS_Message; each is kept as its bits plus the index of its packets
--  (the memory model of doc/EVC-PLAN.md §2: a packet is decoded on
--  demand, Open_*_Packet then the Decode of its package). Phase E1 keeps
--  the last accepted one of each; what the on-board does with them is
--  phases E2 to E6.
--
--  The radio messages are taken as coming from an RBC: the session
--  management of phase E5 will tell an RBC from an RIU. Until then a
--  message or packet only an RIU sends is rejected (Wrong_Sender).
--
--  Every rejection reason is counted, among them a spare value of a
--  variable (Invalid_Value, SUBSET-026 3.16.1.1.1: the information is
--  not kept; the reaction of 3.16.2 / 3.16.3 is a later phase).

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Bits;
with ETCS_Message;
with ETCS_Telegram;
with EVC_Bytes;
with EVC_Ports;

package EVC_Received
  with SPARK_Mode => On,
       Abstract_State => Store,
       Initializes => Store
is

   use type ETCS_Message.Status_T;
   use type ETCS_Telegram.Status_T;

   --  Nothing received, nothing counted
   procedure Clear
     with Global => (Output => Store),
          Post => not Has_Telegram
                  and then not Has_Message
                  and then (for all S in ETCS_Telegram.Status_T =>
                              Telegram_Count (S) = 0)
                  and then (for all S in ETCS_Message.Status_T =>
                              Message_Count (S) = 0);

   --  A BTM input of the documented shape (EVC_Ports: n_bits u16, then
   --  the bits): parse it, count it by status, keep it when accepted
   procedure Receive_Telegram (Payload : EVC_Bytes.Byte_Array;
                               Status  : out ETCS_Telegram.Status_T)
     with Global => (In_Out => Store),
          Pre => EVC_Ports.Valid_BTM (Payload),
          Post => (if Status = ETCS_Telegram.Accepted then Has_Telegram)
                  and then (if Has_Telegram'Old then Has_Telegram)
                  and then Has_Message = Has_Message'Old;

   --  An RTM input of the documented shape (a radio message, track to
   --  train): parse it, count it by status, keep it when accepted
   procedure Receive_Message (Payload : EVC_Bytes.Byte_Array;
                              Status  : out ETCS_Message.Status_T)
     with Global => (In_Out => Store),
          Pre => EVC_Ports.Valid_RTM (Payload),
          Post => (if Status = ETCS_Message.Accepted then Has_Message)
                  and then (if Has_Message'Old then Has_Message)
                  and then Has_Telegram = Has_Telegram'Old;

   --  Telegrams and messages received with this status since Clear
   --  (saturating)
   function Telegram_Count (S : ETCS_Telegram.Status_T) return Natural
     with Global => Store;
   function Message_Count (S : ETCS_Message.Status_T) return Natural
     with Global => Store;

   function Has_Telegram return Boolean
     with Global => Store;
   function Has_Message return Boolean
     with Global => Store;

   --  The last telegram and message accepted (empty ones before)
   function Last_Telegram return ETCS_Telegram.Telegram_T
     with Global => Store;
   function Last_Message return ETCS_Message.Message_T
     with Global => Store;

   --  A reader on packet I of the last telegram or message accepted
   procedure Open_Telegram_Packet (I : Positive;
                                   R : in out ETCS_Bits.Reader)
     with Global => Store,
          Pre => I <= Last_Telegram.Count;
   procedure Open_Message_Packet (I : Positive;
                                  R : in out ETCS_Bits.Reader)
     with Global => Store,
          Pre => I <= Last_Message.Count;

end EVC_Received;
