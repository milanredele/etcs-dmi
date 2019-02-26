with Display.B_Area;
with Speed_And_Distance;
with Supervision_Mode;

procedure Dmi is

begin
   Supervision_Mode.Mode := Supervision_Mode.M_FS;
   Speed_And_Distance.Set_Monitoring_Mode (Speed_And_Distance.CSM);
   Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_400);
   Speed_And_Distance.Set_Speed_Params ((Vperm => 120,
                                         Vtarget => 80,
                                         Vwsl => 130,
                                         Visl => 140,
                                         Vsbi => 150,
                                         Vrelease => 40,
                                         Vrelease_Exists => True));
   Speed_And_Distance.Set_Speed (119);
   Display.B_Area.Draw;
   Display.B_Area.B_Buffer.Dump ("b_frame.dmp");
end Dmi;
