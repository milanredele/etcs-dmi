--  ETCS DMI
--  WebAssembly module of the DMI. The binder runs the elaboration only
--  (adainit); the page then drives the module through the DMI_Wasm
--  exports.

with DMI_Wasm;

procedure DMI_Main is
begin
   DMI_Wasm.Initialise;
end DMI_Main;
