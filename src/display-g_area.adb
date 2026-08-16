--  ETCS DMI
--  Area G rendering: local time in G13 (8.4.3) and geographical
--  position in G12 (8.4.4).

pragma Ada_2012;
with DMI_Status;
with Symbol;

package body Display.G_Area is

   function Two (N : Natural) return Wide_String is
      Img : constant Wide_String := Natural'Wide_Image (N mod 100);
   begin
      return (if N mod 100 < 10 then "0" & Img (2 .. Img'Last)
              else Img (2 .. Img'Last));
   end Two;

   procedure Draw_Local_Time is
      G13_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (G13);
   begin
      -- DMI 8.4.3.4: grey, single line, hh:mm:ss, 24 h
      G_Buffer.Draw_String
        (Pen_X => G13_Area.Position.X + 3,
         Pen_Y => G13_Area.Position.Y + G13_Area.Height / 2 + 6,
         The_String => Two (DMI_Status.Time_H) & ":"
                       & Two (DMI_Status.Time_M) & ":"
                       & Two (DMI_Status.Time_S),
         The_Size => 12,
         The_Color => General_Parameters.GREY);
   end Draw_Local_Time;

   procedure Draw_Geo_Position is
      G12_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (G12);
      Center_X : constant Width_T := G12_Area.Position.X + G12_Area.Width / 2;
      Center_Y : constant Height_T :=
        G12_Area.Position.Y + G12_Area.Height / 2 + 6;
   begin
      -- DMI 8.4.4: only when the position is known by the onboard
      if not DMI_Status.Geo_Valid then
         return;
      end if;
      if not DMI_Status.Geo_Toggled_On then
         -- 8.4.4.6: DR03 while toggled off
         G_Buffer.Draw_Symbol
           (Symbol.DR_03,
            G12_Area.Position + ((G12_Area.Width - Symbol.DR_03.Width) / 2,
                                 (G12_Area.Height - Symbol.DR_03.Height) / 2));
      else
         -- 8.4.4.8/.9: grey background, black centred value, a space
         -- between the kilometre (12 cells) and metre (10 cells) parts
         G_Buffer.Fill_Area (G12_Area, General_Parameters.GREY);
         declare
            KM : constant Wide_String :=
              Natural'Wide_Image (DMI_Status.Geo_Position_M / 1000);
            M  : constant Wide_String :=
              Natural'Wide_Image (DMI_Status.Geo_Position_M mod 1000);
         begin
            G_Buffer.Draw_String
              (Pen_X => Center_X - 4,
               Pen_Y => Center_Y,
               The_String => KM (2 .. KM'Last),
               The_Size => 12,
               The_Color => General_Parameters.BLACK,
               The_Alignment => G_Buffer.Right);
            G_Buffer.Draw_String
              (Pen_X => Center_X + 4,
               Pen_Y => Center_Y,
               The_String => M (2 .. M'Last),
               The_Size => 10,
               The_Color => General_Parameters.BLACK);
         end;
      end if;
   end Draw_Geo_Position;

   procedure Draw is
   begin
      G_Buffer.Fill (General_Parameters.Background_Color);
      Draw_Local_Time;
      Draw_Geo_Position;
   end Draw;

end Display.G_Area;
