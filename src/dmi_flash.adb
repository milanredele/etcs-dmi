--  ETCS DMI
--  Flashing frame phase implementation.

pragma Ada_2012;

package body DMI_Flash is

   Period_Ms : constant := 2 * Toggle_Ms;

   -- Time since the frame appeared, kept within one period
   Elapsed_Ms : Natural range 0 .. Period_Ms - 1 := 0;

   procedure Restart is
   begin
      Elapsed_Ms := 0;
   end Restart;

   procedure Tick (Dt_Ms : Natural) is
   begin
      -- both terms are below Period_Ms: no overflow for any Dt_Ms
      Elapsed_Ms := (Elapsed_Ms + Dt_Ms mod Period_Ms) mod Period_Ms;
   end Tick;

   -- DMI 5.1.1.3.2: visible during the first 0.25 s, then not visible
   function Frame_Visible return Boolean is (Elapsed_Ms < Toggle_Ms);

end DMI_Flash;
