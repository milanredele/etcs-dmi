with Ada.Streams;
with Ada.Numerics; use Ada.Numerics;

package Display.B_Area.Speed_Dial is
   
   procedure Draw (Stream : not null access Ada.Streams.Root_Stream_Type'Class);
   

   
private

   type Angle is digits 5 range -Pi .. Pi;
   -- DMI 8.2.1.1.11.1
   Lower_Limit   : constant Angle := Pi * (-144.0) / 180.0;
   Upper_Limit   : constant Angle := Pi * 144.0 / 180.0;
   Threshold_200 : constant Angle := Pi * 48.0 / 180.0;
   
   -- DMI 8.2.1.1.6
   B0_Radius_Inner_Short : constant Radius_T := B0_Radius - 15;
   -- DMI 8.2.1.1.7
   B0_Radius_Inner_Long  : constant Radius_T := B0_Radius - 25;
   
   function Speed_To_Angle (Speed : Speed_T) return Angle;
   
   procedure Draw_Speed_Indicator_Lines;
   
   procedure Draw_Speed_Indicator_Numbers;
   
end Display.B_Area.Speed_Dial;
