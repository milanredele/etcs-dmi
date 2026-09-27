--  ETCS DMI test simulator
--  WebAssembly module of the EVC simulator; see DMI_Main.

with EVC_Wasm;

procedure EVC_Main is
begin
   EVC_Wasm.Reset;
end EVC_Main;
