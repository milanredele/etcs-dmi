with Display.B_Area;
with Speed_And_Distance;

procedure Dmi is

begin
   Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_250);
   Speed_And_Distance.Set_Speed_Params ((Vperm => 120,
                                         Vtarget => 80,
                                         Vwsl => 130,
                                         Visl => 140,
                                         Vsbi => 150,
                                         Vrelease => 40));
   Speed_And_Distance.Set_Speed (90);
   Display.B_Area.Draw;
   Display.B_Area.B_Buffer.Dump ("b_frame.dmp");
end Dmi;
