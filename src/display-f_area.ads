--  ETCS DMI
--  Area F: sub-level window selection buttons F1-F5 (8.6.1, Table 18).

with Display.Frame_Buffer;

package Display.F_Area is

   package F_Buffer is new Display.Frame_Buffer (F);

   procedure Draw;

end Display.F_Area;
