--  ETCS on-board (EVC)
--  The 128-bit multiplication of compiler-rt: implementation.

package body Wasm_Int128 is

   procedure Multi3 (Result     : System.Address;
                     A_Lo, A_Hi : Unsigned_64;
                     B_Lo, B_Hi : Unsigned_64)
   is
      type Pair is record
         Lo, Hi : Unsigned_64;
      end record
        with Convention => C;
      R : Pair
        with Import, Address => Result;

      Mask : constant Unsigned_64 := 16#FFFF_FFFF#;
      A0   : constant Unsigned_64 := A_Lo and Mask;
      A1   : constant Unsigned_64 := Shift_Right (A_Lo, 32);
      B0   : constant Unsigned_64 := B_Lo and Mask;
      B1   : constant Unsigned_64 := Shift_Right (B_Lo, 32);
      P00  : constant Unsigned_64 := A0 * B0;
      P01  : constant Unsigned_64 := A0 * B1;
      P10  : constant Unsigned_64 := A1 * B0;
      P11  : constant Unsigned_64 := A1 * B1;
      --  below 3 * 2**32: no carry is lost
      Mid  : constant Unsigned_64 :=
        Shift_Right (P00, 32) + (P01 and Mask) + (P10 and Mask);
   begin
      --  the full product of the low halves, then the cross terms of the
      --  high halves (modulo 2**128, as __multi3)
      R.Lo := (P00 and Mask) or Shift_Left (Mid, 32);
      R.Hi := P11 + Shift_Right (P01, 32) + Shift_Right (P10, 32)
              + Shift_Right (Mid, 32)
              + A_Lo * B_Hi + A_Hi * B_Lo;
   end Multi3;

end Wasm_Int128;
