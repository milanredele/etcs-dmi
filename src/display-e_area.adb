--  ETCS DMI
--  Area E rendering. Text message content follows in a later phase; the
--  area background and borders (8.1.1.4) are drawn here.

package body Display.E_Area is

   procedure Draw is
   begin
      E_Buffer.Fill (General_Parameters.Background_Color);
   end Draw;

end Display.E_Area;
