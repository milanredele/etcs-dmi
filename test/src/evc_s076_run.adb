--  ETCS on-board (EVC)
--  Runner of the SUBSET-076 test sequences against the on-board (host
--  only): see S076_Main for the usage and S076_Run for how a sequence
--  is replayed and judged.

pragma Ada_2012;
with S076_Main;

procedure EVC_S076_Run is
begin
   S076_Main.Run;
end EVC_S076_Run;
