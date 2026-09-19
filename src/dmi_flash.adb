--  ETCS DMI
--  Flashing frame phase implementation.

pragma Ada_2012;

package body DMI_Flash is

   Period_Ms : constant := 2 * Toggle_Ms;

   -- Time since the frame appeared, kept within one period
   Elapsed_Ms : Natural range 0 .. Period_Ms - 1 := 0;

   -- Time since the cursor last moved (DMI 10.3.2.3)
   Cursor_Ms : Natural range 0 .. Period_Ms - 1 := 0;

   procedure Restart is
   begin
      Elapsed_Ms := 0;
   end Restart;

   procedure Restart_Cursor is
   begin
      Cursor_Ms := 0;
   end Restart_Cursor;

   procedure Tick (Dt_Ms : Natural) is
      Step : constant Natural := Dt_Ms mod Period_Ms;
   begin
      -- both terms are below Period_Ms: no overflow for any Dt_Ms
      Elapsed_Ms := (Elapsed_Ms + Step) mod Period_Ms;
      Cursor_Ms := (Cursor_Ms + Step) mod Period_Ms;
   end Tick;

   -- DMI 5.1.1.3.2: visible during the first 0.25 s, then not visible
   function Frame_Visible return Boolean is (Elapsed_Ms < Toggle_Ms);

   function Cursor_Visible return Boolean is (Cursor_Ms < Toggle_Ms);

end DMI_Flash;
