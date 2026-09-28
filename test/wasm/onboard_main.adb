--  ETCS on-board (EVC)
--  WebAssembly module of the ETCS on-board in its bench environment; see
--  DMI_Main and Onboard_Wasm.

with Onboard_Wasm;
--  __multi3, which the on-board's checked 64-bit multiplications call on
--  wasm32 (see there)
with Wasm_Int128;
pragma Unreferenced (Wasm_Int128);

procedure Onboard_Main is
begin
   Onboard_Wasm.Reset;
end Onboard_Main;
