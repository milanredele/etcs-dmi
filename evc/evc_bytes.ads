--  ETCS on-board (EVC)
--  Bytes and little endian fields.
--
--  Multi-byte fields on every port of the on-board are little endian and
--  are read and written byte by byte, never by overlay: the target
--  (TMS570) is big endian and the host is not.

with Interfaces; use Interfaces;

package EVC_Bytes
  with SPARK_Mode => On, Pure
is

   subtype Byte is Unsigned_8;
   type Byte_Array is array (Positive range <>) of Byte;

   function Get_U16 (Data : Byte_Array; Index : Positive) return Unsigned_16
   is (Unsigned_16 (Data (Index))
       or Shift_Left (Unsigned_16 (Data (Index + 1)), 8))
     with Pre => Index >= Data'First and then Index < Data'Last;

   function Get_U32 (Data : Byte_Array; Index : Positive) return Unsigned_32
   is (Unsigned_32 (Data (Index))
       or Shift_Left (Unsigned_32 (Data (Index + 1)), 8)
       or Shift_Left (Unsigned_32 (Data (Index + 2)), 16)
       or Shift_Left (Unsigned_32 (Data (Index + 3)), 24))
     with Pre => Index >= Data'First
                 and then Index <= Data'Last
                 and then Data'Last - Index >= 3;

   --  Byte N (0 is the least significant) of Value
   function Byte_Of (Value : Unsigned_64; N : Natural) return Byte is
     (Byte (Shift_Right (Value, 8 * N) and 16#FF#))
     with Pre => N <= 7;

end EVC_Bytes;
