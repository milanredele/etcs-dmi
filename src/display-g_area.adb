--  ETCS DMI
--  Area G rendering. Local time / geographical position content follows
--  in a later phase; background and borders (8.1.1.4) are drawn here.

package body Display.G_Area is

   procedure Draw is
   begin
      G_Buffer.Fill (General_Parameters.Background_Color);
   end Draw;

end Display.G_Area;
