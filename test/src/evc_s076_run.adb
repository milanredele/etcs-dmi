--  ETCS on-board (EVC)
--  Runner of the SUBSET-076 test sequences against the on-board (host
--  only). See S076_Run for how a sequence is replayed and judged.
--
--  Usage:  obj/evc_s076_run            the fixture test/s076-sample, then
--                                      the corpus of $S076_CHECKOUT, else
--                                      ../etcs-subset076
--          obj/evc_s076_run NAME|PATH  one sequence, VERBOSE=1 for a line
--                                      per step

pragma Ada_2012;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Text_IO;     use Ada.Text_IO;
with S076_Run;        use S076_Run;
with S076_Sequences;  use S076_Sequences;

procedure EVC_S076_Run is
   Verbose : constant Boolean :=
     Ada.Environment_Variables.Exists ("VERBOSE");
   Ok : Boolean;
begin
   if Ada.Command_Line.Argument_Count >= 1 then
      declare
         Path : constant String := Ada.Command_Line.Argument (1);
      begin
         if not Ada.Directories.Exists (Path) then
            Put_Line ("evc_s076_run: " & Path & " not found");
            Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
            return;
         end if;
         Read (Path, Ok);
         Run_Loaded (Verbose);
         Put_Line (Image (Loaded.Name) & ": " & Outcome_T'Image (Outcome)
                   & " at step" & Natural'Image (Outcome_Step));
      end;
   end if;
end EVC_S076_Run;
