with Ada.Streams;
with Ada.Numerics; use Ada.Numerics;

package Display.B.Speed_Dial is
   
   type T is private;
   
   procedure Show (Speed  : T;
                   Stream : not null access Ada.Streams.Root_Stream_Type'Class);
   
private
   type T is null record;
   
   type Angle is digits 5 range -Pi .. Pi;
   -- DMI 8.2.1.1.11.1
   Lower_Limit   : constant Angle := Pi * (-144.0) / 180.0;
   Upper_Limit   : constant Angle := Pi * 144.0 / 180.0;
   Threshold_200 : constant Angle := Pi * 48.0 / 180.0;

end Display.B.Speed_Dial;
