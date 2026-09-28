--  ETCS on-board (EVC)
--  The 128-bit multiplication of compiler-rt for the wasm32 modules.
--
--  The on-board computes in 64-bit integers with overflow checks. On
--  wasm32, LLVM lowers a checked 64-bit multiplication to a 128-bit one
--  and calls the compiler-rt helper __multi3, which the modules do not
--  link (-nostdlib: the AdaWebPack runtime has no compiler-rt). This is
--  that helper, in the wasm32 C ABI of an __int128 function: the result
--  through a pointer to 16 bytes (low half first), each operand as two
--  i64 (low, high). Only modular 64-bit multiplications and shifts, which
--  wasm32 has as instructions, so it never calls itself.

with Interfaces; use Interfaces;
with System;

package Wasm_Int128 is

   procedure Multi3 (Result     : System.Address;
                     A_Lo, A_Hi : Unsigned_64;
                     B_Lo, B_Hi : Unsigned_64)
     with Export, Convention => C, Link_Name => "__multi3";

end Wasm_Int128;
