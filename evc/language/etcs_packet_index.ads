--  ETCS on-board (EVC)
--  The index of the packets of a telegram or a radio message.
--
--  A telegram (SUBSET-026 8.4.2) or a radio message (8.4.4) is kept as
--  its bits plus an index: for every packet its NID_PACKET, kind, first
--  bit and length. The bits stay where they are; a packet is decoded on
--  demand from them into its record, on the stack (doc/EVC-PLAN.md §2,
--  the memory model of the codec).
--
--  Scan reads the header of the next packet (7.3.3.2), checks that the
--  packet is complete, that a known packet decodes in exactly its
--  L_PACKET bits and that its variables hold values of 7.5, not spare
--  ones (3.16.1.1.1: the use of a spare value is not compliant), and
--  passes over it; an unknown packet is passed over by its L_PACKET
--  (7.3.3.4 leaves the reaction to the caller). Packet 0
--  of the track to train direction has no L_PACKET (7.3.3.5): its length
--  is what it decodes to. Packet 255 of that direction ends the string
--  (7.4.2.39).

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Bits;      use ETCS_Bits;
with ETCS_Catalogue; use ETCS_Catalogue;
with ETCS_Variables; use ETCS_Variables;

package ETCS_Packet_Index
  with SPARK_Mode => On
is

   type Entry_T is record
      NID    : NID_PACKET_T := 0;
      Kind   : Packet_Kind_T := Unknown;
      --  Q_DIR of a track to train packet with the standard header, 0
      --  otherwise
      Q_DIR  : Q_DIR_T := 0;
      Offset : Bit_Count := 0;   -- its first bit in the string
      Length : Bit_Count := 0;   -- its bits
   end record;
   No_Entry : constant Entry_T := (others => <>);

   type Scan_Result_T is
     (Scanned,       -- a packet: E describes it, R is after it
      End_Of_Data,   -- packet 255 (track to train) at E.Offset
      Truncated,     -- the header or the packet goes past the limit
      Bad_Length,    -- L_PACKET shorter than the header
      Undecodable,   -- a known packet that does not decode in L_PACKET
      Invalid_Value);  -- a known packet with a spare value (3.16.1.1.1)

   procedure Scan (Direction : Direction_T;
                   R         : in out Reader;
                   E         : out Entry_T;
                   Result    : out Scan_Result_T)
     with Post => E.Offset = Position (R)'Old
                  and then Limit (R) = Limit (R)'Old
                  and then
                  (if Result = End_Of_Data then E.Offset + 8 <= Limit (R))
                  and then
                  (if Result = Scanned
                   then not Failed (R)
                        and then E.Length > 0
                        and then E.Offset + E.Length = Position (R));

   --  8.4.1.4: two packets of the same type are for the same direction
   --  when their Q_DIR are equal or one of them is "both directions"
   function Same_Direction (A, B : Q_DIR_T) return Boolean is
     (A = B or else A = 2 or else B = 2);  -- 2: both (7.5.1.103)

end ETCS_Packet_Index;
