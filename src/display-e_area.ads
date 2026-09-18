--  ETCS DMI
--  Area E: text messages (8.2.3.4) and monitoring information (8.4.1).

with Display.Frame_Buffer;

package Display.E_Area is

   package E_Buffer is new Display.Frame_Buffer (E);

   procedure Draw;

end Display.E_Area;
