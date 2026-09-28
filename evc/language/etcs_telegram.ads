--  ETCS on-board (EVC)
--  The Eurobalise telegram, SUBSET-026 8.4.2.
--
--  The BTM port delivers the user bits of a telegram (SUBSET-036 decodes
--  the 1023 or 341 bit telegram into 830 or 210 user bits): the header
--  of 8.4.2.1 (50 bits), the packets, packet 255 (7.4.2.39) and the bits
--  after it, which the receiver does not read (7.4.2.39: "the receiver
--  will stop reading the remaining part"). Finish fills them with ones.
--
--  Parse checks the header and indexes the packets without decoding
--  them into records (ETCS_Packet_Index): a telegram is kept as its bits
--  plus the index, and a packet is decoded on demand (Open_Packet, then
--  the Decode of its package). Rejected, by reason (Status_T):
--    - a header of another medium or direction (Q_UPDOWN = 0 down-link,
--      Q_MEDIA = 1 loop), N_PIG above N_TOTAL, M_DUP spare (7.5.1.63);
--    - M_VERSION other than 2.0 .. 2.3 and 3.x (7.5.1.79): X = 0 is
--      ignored (3.17.3.5 a), X = 1 needs chapter 6 (phase E7), 2.4 ..
--      2.15 are not valid, X above 3 is higher than this on-board
--      supports (3.17.3.5 d, e);
--    - a packet that does not fit, an L_PACKET shorter than the header,
--      a known packet that does not decode in its L_PACKET, packet 0 not
--      first (8.4.2.3), a second instance of a packet for the same
--      direction (8.4.1.4, with its exceptions), no packet 255.
--  A packet of an unknown NID_PACKET is passed over by its L_PACKET and
--  counted (Unknown): whether the telegram is then consistent (7.3.3.4,
--  3.17.3.11 a) is decided with the operated system version (E2, E6).

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Bits;         use ETCS_Bits;
with ETCS_Packet_Index; use ETCS_Packet_Index;
with ETCS_Variables;    use ETCS_Variables;

package ETCS_Telegram
  with SPARK_Mode => On
is

   --  The user bits of a short and of a long telegram (SUBSET-036)
   Short_Bits : constant := 210;
   Long_Bits  : constant := 830;
   Max_Bytes  : constant := (Long_Bits + 7) / 8;

   --  8.4.2.1
   Header_Bits : constant := 50;

   --  The most packets a telegram can hold: packet 0 (14 bits, 7.4.2.0)
   --  and packets of 23 bits at least (the header of 7.3.3.2) between
   --  the header and packet 255
   Max_Packets : constant := 1 + (Long_Bits - Header_Bits - 14 - 8) / 23;

   type Header_T is record
      Q_UPDOWN  : Q_UPDOWN_T := 0;
      M_VERSION : M_VERSION_T := 0;
      Q_MEDIA   : Q_MEDIA_T := 0;
      N_PIG     : N_PIG_T := 0;
      N_TOTAL   : N_TOTAL_T := 0;
      M_DUP     : M_DUP_T := 0;
      M_MCOUNT  : M_MCOUNT_T := 0;
      NID_C     : NID_C_T := 0;
      NID_BG    : NID_BG_T := 0;
      Q_LINK    : Q_LINK_T := 0;
   end record;

   type Status_T is
     (Accepted,
      Too_Long,             -- more than Long_Bits, or Data too short
      Truncated,            -- the header or a packet goes past the end
      Bad_Header,
      Unsupported_Version,
      Packet_Structure,
      Duplicate_Packet,
      Too_Many_Packets,
      No_End);              -- no packet 255

   subtype Packet_Count_T is Natural range 0 .. Max_Packets;
   subtype Packet_Index_T is Positive range 1 .. Max_Packets;
   type Index_T is array (Packet_Index_T) of Entry_T;

   type Telegram_T is record
      Header  : Header_T;
      Count   : Packet_Count_T := 0;
      Index   : Index_T;
      --  packets of an unknown NID_PACKET among them
      Unknown : Packet_Count_T := 0;
      --  where packet 255 starts
      End_Bit : Bit_Count := 0;
      Bits    : Natural range 0 .. Long_Bits := 0;
      Data    : Byte_Array (1 .. Max_Bytes) := (others => 0);
   end record;

   --  7.5.1.79: X, the three most significant bits
   function Major (Version : M_VERSION_T) return Natural is
     (Natural (Version) / 16);

   --  The versions whose telegrams this on-board reads: 2.0 .. 2.3, and
   --  3.0 with the reserved (valid) values 3.1 .. 3.15 of 7.5.1.79
   function Supported (Version : M_VERSION_T) return Boolean is
     (Version in 32 .. 35 | 48 .. 63);

   --  The telegram of Bits bits held in Data from its first byte on. The
   --  header is in T whenever it could be read; the index when Status is
   --  Accepted.
   procedure Parse (Data   : Byte_Array;
                    Bits   : Natural;
                    T      : out Telegram_T;
                    Status : out Status_T)
     with Post => (if Status = Accepted
                   then T.Bits = Bits
                        and then (for all I in 1 .. T.Count =>
                                    T.Index (I).Length > 0
                                    and then T.Index (I).Offset
                                             + T.Index (I).Length
                                             <= T.End_Bit)
                        and then T.End_Bit + 8 <= T.Bits);

   --  A reader on packet I of T, at its first bit, limited to its end
   procedure Open_Packet (T : Telegram_T; I : Positive; R : in out Reader)
     with Pre => I <= T.Count;

   ---------------------------------------------------------------------
   --  Building a telegram (tests, the bench)
   ---------------------------------------------------------------------

   procedure Write_Header (W : in out Writer; H : Header_T)
     with Post => (if not Failed (W)
                   then Position (W) = Position (W)'Old + Header_Bits);

   --  Packet 255, then ones up to User_Bits bits (Short_Bits or
   --  Long_Bits); OK when it fits
   procedure Finish (W : in out Writer; User_Bits : Natural; OK : out Boolean)
     with Post => (if OK
                   then not Failed (W) and then Position (W) = User_Bits);

end ETCS_Telegram;
