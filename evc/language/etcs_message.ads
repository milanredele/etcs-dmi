--  ETCS on-board (EVC)
--  The Euroradio message, SUBSET-026 8.4.4.
--
--  The RTM port delivers a radio message as its bytes: NID_MESSAGE,
--  L_MESSAGE (its length in bytes, 7.5.1.48), T_TRAIN, then track to
--  train M_ACK and NID_LRBG (8.4.4.6.1, message 38 without NID_LRBG),
--  train to track NID_ENGINE (8.4.4.7.1), then the variables of the
--  message, its packets and the padding to a whole byte (8.4.4.5).
--
--  Parse reads the variables of the message (ETCS_Message_Catalogue:
--  the message list of 8.5 to 8.7 as data) and indexes its packets
--  without decoding them into records, as ETCS_Telegram does: the
--  mandatory packets first, in their order (8.4.1.2), then the optional
--  ones of 8.4.4.4 in any order (8.4.1.3). Rejected, by reason:
--    - L_MESSAGE other than the length received (8.4.4.2.1);
--    - an NID_MESSAGE not listed for the direction (8.4.4.1.1);
--    - a message this sender does not send (8.5.3 "Transmitted by":
--      message 37 by an RIU only, the others by an RBC, some by both;
--      train to track, 8.5.2 "Transmitted to", the receiver);
--    - a spare value of a variable of the message or of a known packet,
--      or a spare Q_DIR of an unknown packet (3.16.1.1.1: not compliant
--      with the ETCS specifications; the reaction is 3.16.2 / 3.16.3,
--      later phases);
--    - the message ends within its variables or a packet;
--    - an L_PACKET shorter than the header, a known packet that does
--      not decode in its L_PACKET;
--    - a mandatory packet missing or not in its place;
--    - a known packet this sender does not transmit (the "Transmitted
--      by" / "Transmitted to" of 7.4.2 / 7.4.3);
--    - a packet the message may not carry, or not from this sender
--      (message 24);
--    - a second instance of a packet (8.4.1.4 for a direction, 8.4.1.5),
--      except where the rule allows several.
--  A packet of an unknown NID_PACKET, in a message that may carry
--  optional packets, is passed over by its L_PACKET and counted
--  (3.17.3.11 c; whether it is acceptable depends on the system version
--  of the session, phase E5). More than 8 bits after the last packet are
--  a packet; fewer are the padding.

pragma Unevaluated_Use_Of_Old (Allow);

with Interfaces;             use Interfaces;
with ETCS_Bits;              use ETCS_Bits;
with ETCS_Catalogue;         use ETCS_Catalogue;
with ETCS_Message_Catalogue; use ETCS_Message_Catalogue;
with ETCS_Packet_Index;      use ETCS_Packet_Index;
with ETCS_Variables;         use ETCS_Variables;

package ETCS_Message
  with SPARK_Mode => On
is

   --  L_MESSAGE has 10 bits (7.5.1.48)
   Max_Bytes : constant := 1023;

   --  The most packets kept in the index of one message (engineering
   --  constant: a message of more is rejected, Too_Many_Packets)
   Max_Packets : constant := 64;

   type Status_T is
     (Accepted,
      Bad_Length,           -- L_MESSAGE is not the length received
      Unknown_Message,
      Truncated,            -- the variables or a packet go past the end
      Packet_Structure,
      Missing_Packet,
      Packet_Not_Allowed,
      Duplicate_Packet,
      Too_Many_Packets,
      Invalid_Value,        -- a spare value (3.16.1.1.1)
      Wrong_Sender);        -- a message or packet not from this sender

   --  The values of the variables of a message, as coded: Values (I) is
   --  the variable Fields (Kind) (I)
   type Value_Array is array (Field_Index_T) of Unsigned_64;

   subtype Packet_Count_T is Natural range 0 .. Max_Packets;
   subtype Packet_Index_T is Positive range 1 .. Max_Packets;
   type Index_T is array (Packet_Index_T) of Entry_T;

   type Message_T is record
      Direction : Direction_T := Track_To_Train;
      Kind      : Message_Kind_T := Unknown;
      Values    : Value_Array := (others => 0);
      Count     : Packet_Count_T := 0;
      Index     : Index_T := (others => No_Entry);
      --  packets of an unknown NID_PACKET among them
      Unknown   : Packet_Count_T := 0;
      Length    : Natural range 0 .. Max_Bytes := 0;   -- bytes
      Data      : Byte_Array (1 .. Max_Bytes) := (others => 0);
   end record;

   --  The message in Data, received on a session with Sender (RBC or
   --  RIU; for a train to track message, the receiver)
   procedure Parse (Data      : Byte_Array;
                    Direction : Direction_T;
                    Sender    : Sender_T;
                    M         : out Message_T;
                    Status    : out Status_T)
     with Post => (if Status = Accepted
                   then M.Kind /= Unknown
                        and then M.Length = Data'Length
                        and then (for all I in 1 .. M.Count =>
                                    Within (M, I)));

   --  Packet I lies within the message
   function Within (M : Message_T; I : Positive) return Boolean is
     (I <= Max_Packets
      and then M.Index (I).Length > 0
      and then M.Index (I).Offset + M.Index (I).Length <= 8 * M.Length);

   --  The value of the first field of the message that is Var (the
   --  header of 8.4.4.6.1 / 8.4.4.7.1 or a variable of the message), 0
   --  when the message has none
   function Value (M : Message_T; Var : Variable_T) return Unsigned_64;

   --  A reader on packet I of M, at its first bit, limited to its end
   procedure Open_Packet (M : Message_T; I : Positive; R : in out Reader)
     with Pre => I <= M.Count;

   ---------------------------------------------------------------------
   --  Building a message (the on-board's train to track messages, the
   --  tests)
   ---------------------------------------------------------------------

   --  NID_MESSAGE of Kind, L_MESSAGE to be patched by Finish, then
   --  Values (3 ..) for the other fields of Kind
   procedure Write_Fields (W      : in out Writer;
                           Kind   : Known_Message_T;
                           Values : Value_Array;
                           OK     : out Boolean)
     with Post => (if OK then not Failed (W));

   --  The padding to a whole byte (8.4.4.5), then L_MESSAGE; W holds the
   --  message from its first bit on
   procedure Finish (W : in out Writer; OK : out Boolean)
     with Post => (if OK then not Failed (W) and then Position (W) mod 8 = 0);

end ETCS_Message;
