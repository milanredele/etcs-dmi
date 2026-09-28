--  ETCS DMI test simulator
--  Simple train dynamics: position/speed integration from a traction or
--  brake demand, plus the EVC emergency/service brake override.
--
--  Two on-boards command this train. EVC_Mock sets Brake_Commanded,
--  which applies EVC_Brake_MS2 at once. The ETCS on-board of evc/ acts
--  through its train interface (SUBSET-034; Sim_Vehicle): the emergency
--  brake, the service brake and the traction cut-off below. Their
--  brakes build up linearly to the full deceleration in their build-up
--  time and release the same way; the stronger of the driver's brake
--  and the commanded one acts, and traction is cut off while any is
--  commanded. The mock never sets them, so its train runs exactly as it
--  always did.

package EVC_Train is

   -- Driver demand: -100 (full brake) .. 100 (full traction)
   Demand : Integer range -100 .. 100 := 0;

   -- EVC brake command overrides the driver demand
   Brake_Commanded : Boolean := False;

   Position_M  : Float := 0.0;
   Speed_MS    : Float := 0.0; -- m/s

   Max_Traction_MS2 : constant Float := 0.5;
   Max_Brake_MS2    : constant Float := 1.0;
   EVC_Brake_MS2    : constant Float := 1.0;

   -- The commands of the ETCS on-board's train interface (SUBSET-034
   -- 2.3.3 EBC, 2.3.1 SBC, 2.4.9 TCO)
   EB_Commanded     : Boolean := False;
   SB_Commanded     : Boolean := False;
   Traction_Cut_Off : Boolean := False;

   -- The brakes of the vehicle: full deceleration (m/s2, on the level)
   -- and build-up time (s, from the command to the full effort)
   Emergency_Brake_MS2 : constant Float := 1.2;
   Service_Brake_MS2   : constant Float := 0.9;
   EB_Build_Up_S       : constant Float := 1.0;
   SB_Build_Up_S       : constant Float := 2.0;

   -- The effort of each brake now, 0.0 (released) .. 1.0 (full)
   function EB_Effort return Float;
   function SB_Effort return Float;

   function Speed_KMH return Natural;

   procedure Step (Dt_S : Float);

   procedure Reset;

end EVC_Train;
