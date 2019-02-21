with Ada.Numerics; use Ada.Numerics;
with Speed_And_Distance; use Speed_And_Distance;

package Display.B_Area.Speed_Dial is
   
   procedure Draw;
   
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
   
   -- procedure Draw_Speed_Indicator_Numbers;
   
   procedure Draw_Speed_Pointer;
   
   package Circular_Speed_Gauge is
      -- DMI 8.2.1.4.4
      Lowermost_Limit      : constant Angle := Pi * (-149.0) / 180.0;
      -- DMI 8.2.1.4.5
      Lowermost_Part_Color : constant General_Parameters.Color := General_Parameters.DARK_GREY;
      -- DMI 8.2.1.4.7
      Hook_Width           : constant Angle := Pi * 2.8 / 180.0; -- 6 pixels are 2.8 degrees
      Hook_Inner_Radius    : constant Radius_T := B2_Radius_Outer - 20;
      
      procedure Draw;
   end Circular_Speed_Gauge;
   
end Display.B_Area.Speed_Dial;
