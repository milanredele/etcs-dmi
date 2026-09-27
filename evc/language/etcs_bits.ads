--  ETCS on-board (EVC)
--  Bit strings of the ERTMS/ETCS language.
--
--  Telegrams, radio messages and packets are strings of variables of 1
--  to 64 bits (SUBSET-026 7.5), transmitted most significant bit first
--  (7.3.2.10) with no alignment. A Reader reads such a string from bytes
--  that hold it from the most significant bit of the first byte on; a
--  Writer builds one the same way. Both keep their own copy of the bytes
--  (at most Max_Bytes), so that a telegram or message kept in a store is
--  decoded on demand without anything pointing into the store.
--
--  Nothing here raises. An operation that does not fit (a read past the
--  limit, a write past the capacity, a value wider than its field) does
--  nothing but set the Failed flag, which stays set: a decoder reads a
--  whole packet and looks at the flag once at the end.
--
--  Proven: absence of run-time errors, the position never passes the
--  limit, the limit never passes the bytes held (Type_Invariant), and
--  the contracts below.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Bytes;
with Interfaces; use Interfaces;

package ETCS_Bits
  with SPARK_Mode => On, Pure
is

   subtype Byte_Array is EVC_Bytes.Byte_Array;

   --  The longest string: a radio message of L_MESSAGE = 1023 bytes
   --  (7.5.1.48), rounded up
   Max_Bytes : constant := 1024;
   Max_Bits  : constant := 8 * Max_Bytes;

   subtype Byte_Count is Natural range 0 .. Max_Bytes;
   subtype Bit_Count is Natural range 0 .. Max_Bits;

   --  The width of one variable (NID_RADIO, 7.5.1.95, is the widest)
   subtype Width is Positive range 1 .. 64;

   --  Value is a Bits bit unsigned number
   function Fits (Value : Unsigned_64; Bits : Width) return Boolean is
     (Shift_Right (Value, Bits) = 0);

   --  Data holds Bits bits: Bits <= 8 * Data'Length, without overflow
   function Holds (Data : Byte_Array; Bits : Natural) return Boolean is
     (Bits / 8 < Data'Length
      or else (Bits / 8 = Data'Length and then Bits mod 8 = 0));

   ---------------------------------------------------------------------
   --  Reader
   ---------------------------------------------------------------------

   --  Reads bits 0 .. Limit - 1 of its Size bytes, from Position on
   type Reader (Size : Byte_Count) is private
     with Default_Initial_Condition =>
            Position (Reader) = 0
            and then Limit (Reader) = 0
            and then not Failed (Reader);

   function Position (R : Reader) return Bit_Count
     with Post => Position'Result <= Limit (R);

   function Limit (R : Reader) return Bit_Count
     with Post => Limit'Result <= 8 * R.Size;

   --  A read, skip, seek or load did not fit (sticky)
   function Failed (R : Reader) return Boolean;

   function Remaining (R : Reader) return Bit_Count is
     (Limit (R) - Position (R));

   --  Hold the first Bits bits of Data, from its first byte on, and read
   --  them from the start. Fails, and holds nothing, when Data has more
   --  than R.Size bytes or fewer than Bits bits.
   procedure Load (R : in out Reader; Data : Byte_Array; Bits : Natural)
     with Post => Position (R) = 0
                  and then
                  (if Data'Length <= R.Size and then Holds (Data, Bits)
                   then not Failed (R) and then Limit (R) = Bits
                   else Failed (R) and then Limit (R) = 0);

   --  The next Bits bits as an unsigned number
   procedure Read (R : in out Reader; Bits : Width; Value : out Unsigned_64)
     with Post => Fits (Value, Bits)
                  and then Limit (R) = Limit (R)'Old
                  and then
                  (if not Failed (R)'Old and then Bits <= Remaining (R)'Old
                   then not Failed (R)
                        and then Position (R) = Position (R)'Old + Bits
                   else Failed (R)
                        and then Value = 0
                        and then Position (R) = Position (R)'Old);

   --  The next Bits bits into Data, eight by eight from Data'First, the
   --  last byte left aligned and completed with zeros; the bytes after
   --  are zero. Fails when Data is too short for Bits bits.
   procedure Read_Bytes (R    : in out Reader;
                         Bits : Natural;
                         Data : out Byte_Array)
     with Post => Limit (R) = Limit (R)'Old
                  and then
                  (if not Failed (R)'Old
                     and then Bits <= Remaining (R)'Old
                     and then Holds (Data, Bits)
                   then not Failed (R)
                        and then Position (R) = Position (R)'Old + Bits
                   else Failed (R));

   procedure Skip (R : in out Reader; Bits : Natural)
     with Post => Limit (R) = Limit (R)'Old
                  and then
                  (if not Failed (R)'Old and then Bits <= Remaining (R)'Old
                   then not Failed (R)
                        and then Position (R) = Position (R)'Old + Bits
                   else Failed (R) and then Position (R) = Position (R)'Old);

   --  Continue reading at bit To (0 is the first bit held)
   procedure Seek (R : in out Reader; To : Natural)
     with Post => Limit (R) = Limit (R)'Old
                  and then
                  (if not Failed (R)'Old and then To <= Limit (R)
                   then not Failed (R) and then Position (R) = To
                   else Failed (R) and then Position (R) = Position (R)'Old);

   --  Read no further than bit To - 1 (To at most the bits held)
   procedure Set_Limit (R : in out Reader; To : Natural)
     with Post => (if not Failed (R)'Old
                     and then To >= Position (R)'Old
                     and then To <= 8 * R.Size
                   then not Failed (R)
                        and then Limit (R) = To
                        and then Position (R) = Position (R)'Old
                   else Failed (R)
                        and then Limit (R) = Limit (R)'Old
                        and then Position (R) = Position (R)'Old);

   ---------------------------------------------------------------------
   --  Writer
   ---------------------------------------------------------------------

   --  Builds a string of at most 8 * Size bits; Position bits are written
   type Writer (Size : Byte_Count) is private
     with Default_Initial_Condition =>
            Position (Writer) = 0 and then not Failed (Writer);

   function Position (W : Writer) return Bit_Count
     with Post => Position'Result <= 8 * W.Size;

   function Failed (W : Writer) return Boolean;

   --  Bytes holding the Position bits written
   function Byte_Length (W : Writer) return Byte_Count is
     ((Position (W) + 7) / 8)
     with Post => Byte_Length'Result <= W.Size;

   --  Start again, empty
   pragma Warnings (GNATprove, Off, "unused initial value of ""W""",
                    Reason => "in out for the discriminant only");
   procedure Clear (W : in out Writer)
     with Post => Position (W) = 0 and then not Failed (W);
   pragma Warnings (GNATprove, On, "unused initial value of ""W""");

   --  Append Value on Bits bits. Fails when Value does not fit or the
   --  writer is full.
   procedure Write (W : in out Writer; Bits : Width; Value : Unsigned_64)
     with Post => (if not Failed (W)'Old
                     and then Fits (Value, Bits)
                     and then Bits <= 8 * W.Size - Position (W)'Old
                   then not Failed (W)
                        and then Position (W) = Position (W)'Old + Bits
                   else Failed (W) and then Position (W) = Position (W)'Old);

   --  Append the first Bits bits of Data (as Read_Bytes reads them)
   procedure Write_Bytes (W : in out Writer; Bits : Natural; Data : Byte_Array)
     with Post => (if not Failed (W)'Old
                     and then Holds (Data, Bits)
                     and then Bits <= 8 * W.Size - Position (W)'Old
                   then not Failed (W)
                        and then Position (W) = Position (W)'Old + Bits
                   else Failed (W) and then Position (W) = Position (W)'Old);

   --  Append Count bits, all one (One) or all zero
   procedure Fill (W : in out Writer; Count : Natural; One : Boolean)
     with Post => (if not Failed (W)'Old
                     and then Count <= 8 * W.Size - Position (W)'Old
                   then not Failed (W)
                        and then Position (W) = Position (W)'Old + Count
                   else Failed (W) and then Position (W) = Position (W)'Old);

   --  Overwrite the Bits bits written from bit At_Bit on with Value (a
   --  length known at the end, such as L_PACKET or L_MESSAGE)
   procedure Patch (W      : in out Writer;
                    At_Bit : Natural;
                    Bits   : Width;
                    Value  : Unsigned_64)
     with Post => Position (W) = Position (W)'Old
                  and then
                  (if not Failed (W)'Old
                     and then Fits (Value, Bits)
                     and then At_Bit <= Position (W)'Old
                     and then Bits <= Position (W)'Old - At_Bit
                   then not Failed (W)
                   else Failed (W));

   --  The bytes written, the unused bits of the last one zero
   function Data (W : Writer) return Byte_Array
     with Post => Data'Result'First = 1
                  and then Data'Result'Length = Byte_Length (W);

private

   type Reader (Size : Byte_Count) is record
      Bytes    : Byte_Array (1 .. Size) := (others => 0);
      Position : Bit_Count := 0;
      Limit    : Bit_Count := 0;
      Failed   : Boolean := False;
   end record
     with Type_Invariant => Reader.Position <= Reader.Limit
                            and then Reader.Limit <= 8 * Reader.Size;

   type Writer (Size : Byte_Count) is record
      Bytes    : Byte_Array (1 .. Size) := (others => 0);
      Position : Bit_Count := 0;
      Failed   : Boolean := False;
   end record
     with Type_Invariant => Writer.Position <= 8 * Writer.Size;

   function Position (R : Reader) return Bit_Count is (R.Position);
   function Limit (R : Reader) return Bit_Count is (R.Limit);
   function Failed (R : Reader) return Boolean is (R.Failed);

   function Position (W : Writer) return Bit_Count is (W.Position);
   function Failed (W : Writer) return Boolean is (W.Failed);

end ETCS_Bits;
