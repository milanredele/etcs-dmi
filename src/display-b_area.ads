with Display.Frame_Buffer;

package Display.B_Area is
   
   package B_Buffer is new Display.Frame_Buffer (B);
   
   -- Draw the current state
   procedure Draw;
   
private
   
   The_Area   : constant Area_T := Get_Area (B);
   The_Center : constant Position_T := (The_Area.Width  / 2,
                                        The_Area.Height / 2);

   subtype Radius_T is Natural range 0 .. 137;
   -- DMI 6.3.1.2.a
   B0_Radius : constant Radius_T := 125;
   -- DMI 6.3.1.2.c
   B2_Radius_Inner : constant Radius_T := 128;
   B2_Radius_Outer : constant Radius_T := 137;
   
end Display.B_Area;
