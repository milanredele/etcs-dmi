--  ETCS DMI
--  Copyright (C) 2019  Milan Redele
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.

separate (Display.B_Area.Speed_Dial)
procedure Draw_Speed_Pointer is
   -- DMI 8.2.1.2.5, Table 8 (v4.0.0) gives the conditions for display and
   -- the colour of the pointer. A combination of mode, monitoring and
   -- supervision status for which the table has no row, or a row of hyphens
   -- only ("not applicable"), has no colour: the pointer is not displayed,
   -- and with it the digital speed, which lives inside the pointer
   -- (8.2.1.3.2). Such combinations do occur: the mode arrives in
   -- MSG_MODE_LEVEL and the monitoring in MSG_SPEED_STATE, so one of them
   -- is always ahead of the other during a transition, and nothing stops
   -- the EVC from sending them. They must never raise.
   type Pointer_Look is record
      Shown : Boolean;
      Color : General_Parameters.Color;
   end record;

   Not_Applicable : constant Pointer_Look :=
     (Shown => False, Color => General_Parameters.GREY);

   function Look_Of_Pointer return Pointer_Look is
      Params    : constant Speed_Params := Get_Speed_Params;
      The_Speed : constant Speed_T := Get_Speed;

      function Show (The_Color : General_Parameters.Color) return Pointer_Look is
        ((Shown => True, Color => The_Color));

      -- Shared row patterns of Table 8. Band columns:
      --   below:  0 <= pointer < Vtarget          (grey in all rows)
      --   mid:    Vtarget <= pointer <= Vperm
      --   over:   pointer > Vperm (CSM/TSM) or > Vrelease (RSM)

      -- "CSM" plain rows (FS/SM/OS, LS, SR/UN, SH/RV all share them)
      function CSM_Plain (Over : General_Parameters.Color)
                          return Pointer_Look is
      begin
         case Get_Supervision_Status is
            when NoS =>
               return Show (General_Parameters.GREY);
            when OvS | WaS =>
               return Show (Over);
            when IntS =>
               if The_Speed <= Params.Vperm then
                  return Show (General_Parameters.GREY);
               else
                  return Show (General_Parameters.RED);
               end if;
            when IndS =>
               -- No IndS row under CSM (IndS does not exist there, 7.2).
               -- Speed_And_Distance.Set_Speed never yields it in CSM.
               return Not_Applicable;
         end case;
      end CSM_Plain;

      -- "CSM (with target information)" and "TSM" rows share their shape;
      -- only the colour of the Vtarget..Vperm band differs.
      function With_Target (Mid, Over, Int_Over : General_Parameters.Color)
                            return Pointer_Look is
      begin
         case Get_Supervision_Status is
            when NoS | IndS =>
               if The_Speed < Params.Vtarget then
                  return Show (General_Parameters.GREY);
               else
                  return Show (Mid);
               end if;
            when OvS | WaS =>
               return Show (Over);
            when IntS =>
               if The_Speed < Params.Vtarget then
                  return Show (General_Parameters.GREY);
               elsif The_Speed <= Params.Vperm then
                  return Show (Mid);
               else
                  return Show (Int_Over);
               end if;
         end case;
      end With_Target;

      function RSM_Row (Base, Int_Over : General_Parameters.Color)
                        return Pointer_Look is
      begin
         case Get_Supervision_Status is
            when IndS =>
               return Show (Base);
            when IntS =>
               if Params.Vrelease_Exists and then The_Speed <= Params.Vrelease then
                  return Show (Base);
               else
                  return Show (Int_Over);
               end if;
            when NoS | OvS | WaS =>
               -- Only IndS and IntS rows under RSM (7.5).
               -- Speed_And_Distance.Set_Speed yields no other status in RSM.
               return Not_Applicable;
         end case;
      end RSM_Row;

      use General_Parameters;
   begin
      case Supplementary_Driving_Info.Mode is
         when Supplementary_Driving_Info.M_FS
            | Supplementary_Driving_Info.M_SM
            | Supplementary_Driving_Info.M_OS =>
            case Get_Monitoring_Mode is
               when CSM =>
                  if Get_CSM_Target_Info then
                     return With_Target (Mid => WHITE, Over => ORANGE, Int_Over => RED);
                  else
                     return CSM_Plain (Over => ORANGE);
                  end if;
               when TSM =>
                  return With_Target (Mid => YELLOW, Over => ORANGE, Int_Over => RED);
               when RSM =>
                  return RSM_Row (Base => YELLOW, Int_Over => RED);
            end case;

         when Supplementary_Driving_Info.M_AD =>
            -- Table 8 AD rows: yellow/orange replaced by white; over-speed in
            -- plain CSM shown grey.
            --
            -- Known issue KI-1 (doc/AUDIT-2026-09.md): the four AD rows with
            -- IntS hold hyphens only. IntS is presumed not applicable in AD
            -- (a brake command ends automatic driving), but this text exempts
            -- AD in TSM alone (7.4.5.1.1), and SUBSET-026 is not checked yet.
            -- Defensive fallback for the presumably unreachable state: the
            -- pointer stays, in the AD base colour grey, so the driver never
            -- loses the current speed. (The CSG is not drawn, Table 9.)
            case Get_Monitoring_Mode is
               when CSM =>
                  if Get_CSM_Target_Info then
                     case Get_Supervision_Status is
                        when NoS | IndS =>
                           return Show (if The_Speed < Params.Vtarget then GREY else WHITE);
                        when OvS | WaS => return Show (WHITE);
                        when IntS      => return Show (GREY);
                     end case;
                  else
                     case Get_Supervision_Status is
                        when NoS | IndS | OvS | WaS => return Show (GREY);
                        when IntS                   => return Show (GREY);
                     end case;
                  end if;
               when TSM =>
                  case Get_Supervision_Status is
                     when NoS | IndS =>
                        return Show (if The_Speed < Params.Vtarget then GREY else WHITE);
                     when OvS | WaS => return Show (WHITE);
                     when IntS      => return Show (GREY);
                  end case;
               when RSM =>
                  case Get_Supervision_Status is
                     when IndS   => return Show (WHITE);
                     when IntS   => return Show (GREY);
                     when others => return Not_Applicable;
                  end case;
            end case;

         when Supplementary_Driving_Info.M_LS =>
            case Get_Monitoring_Mode is
               when CSM =>
                  return CSM_Plain (Over => ORANGE);
               when TSM =>
                  -- LS TSM rows: the Vtarget..Vperm band stays grey
                  return With_Target (Mid => GREY, Over => ORANGE, Int_Over => RED);
               when RSM =>
                  return RSM_Row (Base => YELLOW, Int_Over => RED);
            end case;

         when Supplementary_Driving_Info.M_SR | Supplementary_Driving_Info.M_UN =>
            case Get_Monitoring_Mode is
               when CSM =>
                  if Get_CSM_Target_Info then
                     return With_Target (Mid => WHITE, Over => ORANGE, Int_Over => RED);
                  else
                     return CSM_Plain (Over => ORANGE);
                  end if;
               when TSM =>
                  return With_Target (Mid => YELLOW, Over => ORANGE, Int_Over => RED);
               when RSM =>
                  -- No RSM rows for SR/UN in Table 8
                  return Not_Applicable;
            end case;

         when Supplementary_Driving_Info.M_SH | Supplementary_Driving_Info.M_RV =>
            case Get_Monitoring_Mode is
               when CSM =>
                  return CSM_Plain (Over => ORANGE);
               when TSM | RSM =>
                  -- Only CSM rows for SH/RV in Table 8
                  return Not_Applicable;
            end case;

         when Supplementary_Driving_Info.M_NL
            | Supplementary_Driving_Info.M_SB
            | Supplementary_Driving_Info.M_PT =>
            -- No speed monitoring: pointer considered always below Vperm
            return Show (GREY);

         when Supplementary_Driving_Info.M_TR =>
            -- Emergency brake applied: pointer considered always above Vperm
            return Show (RED);

         when Supplementary_Driving_Info.M_NP
            | Supplementary_Driving_Info.M_SN
            | Supplementary_Driving_Info.M_SF
            | Supplementary_Driving_Info.M_SL
            | Supplementary_Driving_Info.M_IS =>
            -- Table 8 lists no row for NP, SN, SF, SL and IS: no pointer
            return Not_Applicable;
      end case;
   end Look_Of_Pointer;

   -- DMI 8.2.1.2.3
   -- DMI 8.2.1.2.4
   Radius : constant Radius_T := 25;
   Look   : constant Pointer_Look := Look_Of_Pointer;
   Color  : constant General_Parameters.Color := Look.Color;
   A      : constant Angle := Speed_To_Angle (Get_Speed);


   type Point is record
      X, Y : Integer range -500 .. 500;
   end record;
   type Poly_Index_T is range 1 .. 9;
   type Pointer_Poly_T is array (Poly_Index_T) of Point;
   Pointer_Poly : constant Pointer_Poly_T := ((1, -105),
                                              (1, -90),
                                              (4, -82),
                                              (4, -20),
                                              (-4, -20),
                                              (-4, -82),
                                              (-1, -90),
                                              (-1, -105),
                                              (1, -105));
   procedure Fill_Center_Circle is
      R_R  : constant Integer := Radius * Radius;
   begin
      for Y in -Radius .. Radius loop
         for X in -Radius .. Radius loop
            if (X*X + Y*Y) <= R_R then
               B_Buffer.Set_Pixel (X         => X + The_Center.X,
                                   Y         => Y + The_Center.Y,
                                   The_Color => Color);
            end if;
         end loop;
      end loop;
   end Fill_Center_Circle;

   function Rotate_And_Translate_Poly return Pointer_Poly_T is
      function Rotate_Point (P : Point) return Point is
         Cos_A : constant Float := Cos (Float (A));
         Sin_A : constant Float := Sin (Float (A));
      begin
         return (-1 * Integer (Float (P.X) * Cos_A + Float (P.Y) * Sin_A),
                 Integer (Float (-1 * P.X) * Sin_A + Float (P.Y) * Cos_A));
      end;
      Rotated : Pointer_Poly_T;
   begin
      for I in Pointer_Poly'Range loop
         declare
            P : constant Point := Rotate_Point (Pointer_Poly (I));
         begin
            Rotated (I) := (The_Center.X + P.X, The_Center.Y + P.Y);
         end;
      end loop;
      return Rotated;
   end Rotate_And_Translate_Poly;


   procedure Fill_Polygon (Poly : Pointer_Poly_T) is
      Node_X   : array (Pointer_Poly_T'Range) of Integer;
      Swap     : Integer;
      Nodes, J : Poly_Index_T;
      Min_Y    : B_Buffer.Area_Height_T := B_Buffer.Area_Height_T'Last;
      Max_Y    : B_Buffer.Area_Height_T := 0;

      procedure Find_Min_Max_Y is
      begin
         for I in Poly'Range loop
            declare
               Y : constant B_Buffer.Area_Height_T := Poly (I).Y;
            begin
               if Y < Min_Y then
                  Min_Y := Y;
               end if;
               if Y > Max_Y then
                  Max_Y := Y;
               end if;
            end;
         end loop;
      end Find_Min_Max_Y;
   begin
      Find_Min_Max_Y;
      for Pixel_Y in Min_Y .. Max_Y loop
         Nodes := Node_X'First;
         J := Poly'Last - 1;
         for I in Poly'Range loop
            if (Poly (I).Y <= Pixel_Y and Poly (J).Y > Pixel_Y)
              or (Poly (J).Y <= Pixel_Y and Poly (I).Y > Pixel_Y)
            then
               declare
                  Y1 : constant Float := Float (Poly (I).Y);
                  Y2 : constant Float := Float (Poly (J).Y);
                  X1 : constant Float := Float (Poly (I).X);
                  X2 : constant Float := Float (Poly (J).X);
               begin
                  Node_X (Nodes) := Integer (X1 + (Float (Pixel_Y) - Y1) * (X2 - X1) / (Y2 - Y1));
                  Nodes := Nodes + 1;
               end;
            end if;
            J := I;
         end loop;

         J := Node_X'First;
         while J < Nodes - 1 loop
            if Node_X (J) > Node_X (J + 1) then
               Swap := Node_X (J);
               Node_X (J) := Node_X (J + 1);
               Node_X (J + 1) := Swap;
               if J > Node_X'First then
                  J := J - 1;
               else
                  J := J + 1;
               end if;
            else
               J := J + 1;
            end if;
         end loop;

         J := Node_X'First;
         while J < Nodes - 1 loop
            if (Nodes - Node_X'First) mod 2 /= 0 then
               -- parity error! skip this scanline to avoid horizontal artifacts
               exit;
            end if;
            if Node_X (J) < B_Buffer.Area_Width_T'Last then
               if Node_X (J+1) > B_Buffer.Area_Width_T'First then
                  if Node_X (J) < B_Buffer.Area_Width_T'First then
                     Node_X (J) := B_Buffer.Area_Width_T'First;
                  end if;
                  if Node_X (J+1) > B_Buffer.Area_Width_T'Last then
                     Node_X (J+1) := B_Buffer.Area_Width_T'Last;
                  end if;
                  for I in Node_X (J) .. Node_X (J+1) loop
                     B_Buffer.Set_Pixel (X         => I,
                                         Y         => Pixel_Y,
                                         The_Color => Color);
                  end loop;
               end if;
            end if;
            J := J + 2;
         end loop;
      end loop;
   end Fill_Polygon;

   procedure Draw_Current_Train_Speed_Digital is
      B1_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (B1);
      -- DMI 8.2.1.3.3
      First_Digit_X  : constant B_Buffer.Area_Width_T  := B1_Area.Position.X + 2;
      Second_Digit_X : constant B_Buffer.Area_Width_T  := First_Digit_X  + B1_Area.Width / 3;
      Third_Digit_X  : constant B_Buffer.Area_Width_T  := Second_Digit_X + B1_Area.Width / 3;
      Pen_Y          : constant B_Buffer.Area_Height_T := B1_Area.Position.Y + B1_Area.Height / 2 + 9;
      Speed          : constant Speed_T       := Get_Speed;
      Digit_Color    :          General_Parameters.Color;
      subtype Digit is Natural range 0 .. 9;
      First_Digit    : constant Digit := Digit (Speed / 100);
      Second_Digit   : constant Digit := Digit ((Speed rem 100) / 10);
      Third_Digit    : constant Digit := Digit (Speed rem 10);

      use type General_Parameters.Color;

      procedure Draw_Glyph (Pen_X : B_Buffer.Area_Width_T; The_Digit : Digit) is
      begin
         B_Buffer.Draw_Glyph (Pen_X      => Pen_X,
                              Pen_Y      => Pen_Y,
                              The_Glyph  => Font.FreeSans_18.Glyphs (Integer'Wide_Image (The_Digit) (2)),
                              The_Bitmap => Font.FreeSans_18.Bitmap,
                              The_Color  => Digit_Color);
      end Draw_Glyph;
   begin
      if Color = General_Parameters.RED then
         Digit_Color := General_Parameters.WHITE;
      else
         Digit_Color := General_Parameters.BLACK;
      end if;

      if Speed > 99 then
         Draw_Glyph (First_Digit_X, First_Digit);
      end if;
      if Speed > 9 then
         Draw_Glyph (Second_Digit_X, Second_Digit);
      end if;
      Draw_Glyph (Third_Digit_X, Third_Digit);
   end Draw_Current_Train_Speed_Digital;

begin
   if not Look.Shown then
      return;
   end if;
   Fill_Center_Circle;
   Fill_Polygon (Rotate_And_Translate_Poly);
   Draw_Current_Train_Speed_Digital;
end Draw_Speed_Pointer;
