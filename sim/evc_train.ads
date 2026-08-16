--  ETCS DMI test simulator
--  Simple train dynamics: position/speed integration from a traction or
--  brake demand, plus the EVC emergency/service brake override.

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

   function Speed_KMH return Natural;

   procedure Step (Dt_S : Float);

   procedure Reset;

end EVC_Train;
