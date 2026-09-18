--  ETCS DMI test simulator
--  Train dynamics implementation.

package body EVC_Train is

   function Speed_KMH return Natural is
     (Natural (Speed_MS * 3.6));

   procedure Step (Dt_S : Float) is
      Accel : Float;
   begin
      if Brake_Commanded then
         Accel := -EVC_Brake_MS2;
      elsif Demand >= 0 then
         Accel := Float (Demand) / 100.0 * Max_Traction_MS2;
      else
         Accel := Float (Demand) / 100.0 * Max_Brake_MS2;
      end if;

      Speed_MS := Speed_MS + Accel * Dt_S;
      if Speed_MS < 0.0 then
         Speed_MS := 0.0;
      end if;
      Position_M := Position_M + Speed_MS * Dt_S;
   end Step;

   procedure Reset is
   begin
      Demand := 0;
      Brake_Commanded := False;
      Position_M := 0.0;
      Speed_MS := 0.0;
   end Reset;

end EVC_Train;
