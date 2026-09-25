--  ETCS DMI
--  Area G rendering: local time in G13 (8.4.3), geographical position
--  in G12 (8.4.4) and the ATO information in G1-G5 (8.5).

pragma Ada_2012;
with Display.Draw;
with DMI_ATO;
with DMI_Buttons;
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

   ---------------------------------------------------------------------
   -- ATO information (8.5)
   ---------------------------------------------------------------------

   -- 5.1.6.3: a symbol is centred in its area
   procedure Draw_Centred (Sym : Symbol.T; In_Area : Sub_ID_T) is
      The_Area : constant Area_T :=
        Get_Sub_Area_With_Relative_Position (In_Area);
   begin
      G_Buffer.Draw_Symbol
        (Sym, The_Area.Position + ((The_Area.Width - Sym.Width) / 2,
                                   (The_Area.Height - Sym.Height) / 2));
   end Draw_Centred;

   -- 5.3.2.5: an enabled button that is not pressed has the 'lifted'
   -- border; pressed, it loses it and the layer border of the area shows
   procedure Draw_Button (In_Area : Sub_ID_T;
                          Button  : DMI_Buttons.Button_ID_T) is
   begin
      if not DMI_Buttons.Is_Pressed (Button) then
         G_Buffer.Draw_Button_Frame
           (Get_Sub_Area_With_Relative_Position (In_Area));
      end if;
   end Draw_Button;

   -- 8.5.2: ATO01 .. ATO05 in G1; G1 is the engage / disengage button
   -- while ATO02, ATO03 or ATO04 is displayed (8.5.2.5 / 8.5.2.6)
   procedure Draw_ATO_Status is
      use all type DMI_ATO.Status_T;
   begin
      case DMI_ATO.Status is
         when No_Status   => return;
         when Selected    => Draw_Centred (Symbol.ATO_01, G1);
         when Ready       => Draw_Centred (Symbol.ATO_02, G1);
         when Engaged     => Draw_Centred (Symbol.ATO_03, G1);
         when Disengaging => Draw_Centred (Symbol.ATO_04, G1);
         when Failure     => Draw_Centred (Symbol.ATO_05, G1);
      end case;
      if DMI_ATO.Engage_Button then
         Draw_Button (G1, DMI_Buttons.BTN_ATO_Engage);
      end if;
   end Draw_ATO_Status;

   -- 8.5.4: stopping accuracy in G2
   procedure Draw_Accuracy is
      use all type DMI_ATO.Accuracy_T;
   begin
      case DMI_ATO.Accuracy is
         when No_Accuracy => null;
         when Overshoot   => Draw_Centred (Symbol.ATO_06, G2);
         when Undershoot  => Draw_Centred (Symbol.ATO_07, G2);
         when Accurate    => Draw_Centred (Symbol.ATO_08, G2);
      end case;
   end Draw_Accuracy;

   function Image (N : Natural) return Wide_String is
      Img : constant Wide_String := Natural'Wide_Image (N);
   begin
      return Img (2 .. Img'Last);
   end Image;

   -- 8.5.5: remaining dwell time in G3, or ATO09 for "Train hold"
   procedure Draw_Dwell_Time is
      G3_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (G3);
      Right   : constant Natural := G3_Area.Position.X + G3_Area.Width;
      -- 8.5.5.6: vertically centred; the minutes and the seconds up to
      -- 59 s are 12 cells high (5.1.2.2.3 d), so the base line is 6
      -- cells below the middle
      Base_Y  : constant Natural :=
        G3_Area.Position.Y + G3_Area.Height / 2 + 6;
      Seconds : constant Natural := DMI_ATO.Dwell_S mod 60;
      Minutes : constant Natural := DMI_ATO.Dwell_S / 60;
   begin
      if DMI_ATO.Train_Hold then
         -- 8.5.5.7. Choice: "Train hold" takes the place of the dwell
         -- time, both being in G3
         Draw_Centred (Symbol.ATO_09, G3);
      elsif DMI_ATO.Dwell_Valid then
         if DMI_ATO.Dwell_S <= 59 then
            -- 8.5.5.4: '[s]s', right aligned with an indent of 18 cells
            G_Buffer.Draw_String
              (Pen_X => Right - 18, Pen_Y => Base_Y,
               The_String => Image (Seconds),
               The_Size => 12,
               The_Color => General_Parameters.GREY,
               The_Alignment => G_Buffer.Right);
         else
            -- 8.5.5.5: '[m]m:ss', right aligned with an indent of 11
            -- cells; 5.1.2.2.3 d / e: the minutes 12 cells, the seconds
            -- 10 cells. Choice: the separator goes with the seconds
            -- (Figure 93b)
            declare
               Secs : constant Wide_String :=
                 ":" & (if Seconds < 10 then "0" else "") & Image (Seconds);
            begin
               G_Buffer.Draw_String
                 (Pen_X => Right - 11, Pen_Y => Base_Y,
                  The_String => Secs,
                  The_Size => 10,
                  The_Color => General_Parameters.GREY,
                  The_Alignment => G_Buffer.Right);
               G_Buffer.Draw_String
                 (Pen_X => Right - 11 - Display.Draw.String_Width (Secs, 10),
                  Pen_Y => Base_Y,
                  The_String => Image (Minutes),
                  The_Size => 12,
                  The_Color => General_Parameters.GREY,
                  The_Alignment => G_Buffer.Right);
            end;
         end if;
      end if;
   end Draw_Dwell_Time;

   -- 8.5.6: door information in G4
   procedure Draw_Doors is
      use all type DMI_ATO.Doors_T;
   begin
      case DMI_ATO.Doors is
         when No_Doors      => null;
         when Open_Both     => Draw_Centred (Symbol.ATO_10, G4);
         when Open_Left     => Draw_Centred (Symbol.ATO_11, G4);
         when Open_Right    => Draw_Centred (Symbol.ATO_12, G4);
         when Doors_Open    => Draw_Centred (Symbol.ATO_13, G4);
         when Close_Request => Draw_Centred (Symbol.ATO_14, G4);
         when Closing       => Draw_Centred (Symbol.ATO_15, G4);
         when Doors_Closed  => Draw_Centred (Symbol.ATO_16, G4);
      end case;
   end Draw_Doors;

   -- G2, G3 and G4 drawn as one area (Figure 93k)
   function G2_G4 return Area_T is
     ((Get_Sub_Area_With_Relative_Position (G2).Position,
       Get_Sub_Area_With_Relative_Position (G2).Width
         + Get_Sub_Area_With_Relative_Position (G3).Width
         + Get_Sub_Area_With_Relative_Position (G4).Width,
       Get_Sub_Area_With_Relative_Position (G2).Height));

   -- 8.5.7: the name of the next stopping point on a first text line and
   -- its estimated arrival time 'hh:mm:ss' on a second one, each
   -- horizontally centred in G2/G3/G4 (8.5.7.5), in grey at 12 cells
   -- (5.1.3.4, 5.1.2.2.3 h). Choice: the base lines are 22 and 40 cells
   -- below the top of the area, the two lines centred as a block as in
   -- Figures 93c and 93e (the line spacing of two heights of 5.1.3.5
   -- does not leave room for two lines in 50 cells). A name wider than
   -- the area is left aligned with the indent of 5.1.3.2 and cut at the
   -- border.
   procedure Draw_Next_Stopping_Point is
      The_Area : constant Area_T := G2_G4;
      Center_X : constant Natural :=
        The_Area.Position.X + The_Area.Width / 2;
      Name     : constant Wide_String :=
        DMI_ATO.Name (1 .. DMI_ATO.Name_Length);
   begin
      if Name'Length > 0 then
         if Display.Draw.String_Width (Name, 12) <= The_Area.Width - 6 then
            G_Buffer.Draw_String
              (Pen_X => Center_X, Pen_Y => The_Area.Position.Y + 22,
               The_String => Name,
               The_Size => 12,
               The_Color => General_Parameters.GREY,
               The_Alignment => G_Buffer.Center);
         else
            G_Buffer.Draw_String_Clipped
              (Pen_X => The_Area.Position.X + 3,
               Pen_Y => The_Area.Position.Y + 22,
               The_String => Name,
               The_Size => 12,
               The_Color => General_Parameters.GREY,
               The_Clip => (The_Area.Position + (1, 1),
                            The_Area.Width - 2, The_Area.Height - 2));
         end if;
      end if;
      if DMI_ATO.ETA_Valid then
         G_Buffer.Draw_String
           (Pen_X => Center_X, Pen_Y => The_Area.Position.Y + 40,
            The_String => Two (DMI_ATO.ETA_H) & ":" & Two (DMI_ATO.ETA_M)
                          & ":" & Two (DMI_ATO.ETA_S),
            The_Size => 12,
            The_Color => General_Parameters.GREY,
            The_Alignment => G_Buffer.Center);
      end if;
   end Draw_Next_Stopping_Point;

   -- 8.5.8: skip stopping point status in G5, a delay-type button while
   -- ATO17 or ATO19 is displayed (8.5.8.5)
   procedure Draw_Skip is
      use all type DMI_ATO.Skip_T;
   begin
      case DMI_ATO.Skip is
         when No_Skip      => return;
         when Inactive     => Draw_Centred (Symbol.ATO_17, G5);
         when By_Trackside => Draw_Centred (Symbol.ATO_18, G5);
         when By_Driver    => Draw_Centred (Symbol.ATO_19, G5);
      end case;
      if DMI_ATO.Skip_Button then
         Draw_Button (G5, DMI_Buttons.BTN_ATO_Skip);
      end if;
   end Draw_Skip;

   procedure Draw_ATO is
   begin
      -- 8.1.1.4 b: G1 .. G5 are areas of layer -1. Choice: their borders
      -- are drawn while they can show ATO information (8.5.1.1); with
      -- the selector at Stand-by the area stays as it was before ATO.
      -- G2/G3/G4 are one area for the next stopping point (Figure 93k).
      G_Buffer.Draw_Frame (Get_Sub_Area_With_Relative_Position (G1));
      if DMI_ATO.At_Stopping_Point then
         G_Buffer.Draw_Frame (Get_Sub_Area_With_Relative_Position (G2));
         G_Buffer.Draw_Frame (Get_Sub_Area_With_Relative_Position (G3));
         G_Buffer.Draw_Frame (Get_Sub_Area_With_Relative_Position (G4));
      else
         G_Buffer.Draw_Frame (G2_G4);
      end if;
      G_Buffer.Draw_Frame (Get_Sub_Area_With_Relative_Position (G5));

      -- 8.5.1.2 a
      Draw_ATO_Status;
      if DMI_ATO.At_Stopping_Point then
         -- 8.5.1.2 c
         Draw_Accuracy;
         Draw_Dwell_Time;
         Draw_Doors;
      else
         -- 8.5.1.2 d
         Draw_Next_Stopping_Point;
         Draw_Skip;
      end if;
   end Draw_ATO;

   procedure Draw is
   begin
      G_Buffer.Fill (General_Parameters.Background_Color);
      Draw_Local_Time;
      Draw_Geo_Position;
      -- 8.5.1.1: only if the ATO selector is set to "On"
      if DMI_ATO.Displayed then
         Draw_ATO;
      end if;
   end Draw;

end Display.G_Area;
