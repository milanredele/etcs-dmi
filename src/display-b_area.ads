package Display.B_Area is
   
   package B_Buffer is new Frame_Buffer (B);
   
   type Speed_T is digits 4 range 0.0 .. 400.0;

   type Speed_Params is
      record
         Vcurrent, Vperm, Vtarget, Vsbi, Vrelease : Speed_T;
      end record;
   
   -- Draw the current state
   procedure Draw;
   
   -- Set the current speed
   procedure Set_Speed (Speed : Speed_Params);

private
   
   The_Area : constant Area_T := Get_Area (B);
   The_Speed : Speed_Params;
   The_Center : constant Position_T := (The_Area.Position.X + The_Area.Width  / 2,
                                        The_Area.Position.Y + The_Area.Height / 2);

   subtype Radius_T is Natural range 0 .. 137;
   -- DMI 6.3.1.2.a
   B0_Radius : constant Radius_T := 125;
   -- DMI 6.3.1.2.c
   B2_Radius_Inner : constant Radius_T := 128;
   B2_Radius_Outer : constant Radius_T := 137;
   
end Display.B_Area;
