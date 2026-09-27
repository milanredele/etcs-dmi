--  ETCS DMI
--  Area G: geographical position (8.4.4), local time (8.4.3) and, with
--  ATO, the areas G1-G10 (8.5).

with Display.Frame_Buffer;

package Display.G_Area is

   package G_Buffer is new Display.Frame_Buffer (G);

   procedure Draw;

end Display.G_Area;
