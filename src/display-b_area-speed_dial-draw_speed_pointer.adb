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
   function Pointer_Color return General_Parameters.Color is
      -- DMI 8.2.1.2.5
      Params    : constant Speed_Params := Get_Speed_Params;
      The_Speed : constant Speed_T := Get_Speed;
   begin
      case Supplementary_Driving_Info.Mode is
         when Supplementary_Driving_Info.M_FS | Supplementary_Driving_Info.M_OS =>
            case Get_Monitoring_Mode is
               when CSM =>
                  case Get_Supervision_Status is
                     when NoS =>
                        return General_Parameters.GREY;
                     when OvS | WaS =>
                        return General_Parameters.ORANGE;
                     when IntS =>
                        if The_Speed <= Params.Vperm then
                           return General_Parameters.GREY;
                        else
                           return General_Parameters.RED;
                        end if;
                     when IndS =>
                        raise Program_Error;
                  end case;
               when PIM =>
                  case Get_Supervision_Status is
                     when NoS =>
                        if The_Speed <= Params.Vtarget then
                           return General_Parameters.GREY;
                        else
                           return General_Parameters.WHITE;
                        end if;
                     when OvS | WaS =>
                        return General_Parameters.ORANGE;
                     when IntS =>
                        if The_Speed < Params.Vtarget then
                           return General_Parameters.GREY;
                        elsif The_Speed <= Params.Vperm then
                           return General_Parameters.WHITE;
                        else
                           return General_Parameters.RED;
                        end if;
                     when IndS =>
                        raise Program_Error;
                  end case;
               when TSM =>
                  case Get_Supervision_Status is
                     when NoS =>
                        if The_Speed <= Params.Vtarget then
                           return General_Parameters.GREY;
                        else
                           return General_Parameters.WHITE;
                        end if;
                     when IndS =>
                        return General_Parameters.YELLOW;
                     when OvS | WaS =>
                        return General_Parameters.ORANGE;
                     when IntS =>
                        if The_Speed < Params.Vtarget then
                           return General_Parameters.GREY;
                        elsif The_Speed <= Params.Vperm then
                           return General_Parameters.YELLOW;
                        else
                           return General_Parameters.RED;
                        end if;
                  end case;
               when RSM =>
                  case Get_Supervision_Status is
                     when IndS =>
                        return General_Parameters.YELLOW;
                     when IntS =>
                        if Params.Vrelease_Exists and The_Speed <= Params.Vrelease then
                           return General_Parameters.YELLOW;
                        else
                           return General_Parameters.RED;
                        end if;
                     when others =>
                        raise Program_Error;
                  end case;
            end case;
         when Supplementary_Driving_Info.M_LS =>
            case Get_Monitoring_Mode is
               when CSM =>
                  case Get_Supervision_Status is
                     when NoS =>
                        return General_Parameters.GREY;
                     when OvS | WaS =>
                        return General_Parameters.ORANGE;
                     when IntS =>
                        if The_Speed <= Params.Vperm then
                           return General_Parameters.GREY;
                        else
                           return General_Parameters.RED;
                        end if;
                     when IndS =>
                        raise Program_Error;
                  end case;
               when PIM =>
                  case Get_Supervision_Status is
                     when NoS =>
                        return General_Parameters.GREY;
                     when OvS | WaS =>
                        return General_Parameters.ORANGE;
                     when IntS =>
                        if The_Speed <= Params.Vperm then
                           return General_Parameters.GREY;
                        else
                           return General_Parameters.RED;
                        end if;
                     when IndS =>
                        raise Program_Error;
                  end case;
               when TSM =>
                  case Get_Supervision_Status is
                     when NoS | IndS =>
                        return General_Parameters.GREY;
                     when OvS | WaS =>
                        return General_Parameters.ORANGE;
                     when IntS =>
                        if The_Speed <= Params.Vperm then
                           return General_Parameters.GREY;
                        else
                           return General_Parameters.RED;
                        end if;
                  end case;
               when RSM =>
                  case Get_Supervision_Status is
                     when IndS =>
                        return General_Parameters.YELLOW;
                     when IntS =>
                        if Params.Vrelease_Exists and The_Speed <= Params.Vrelease then
                           return General_Parameters.YELLOW;
                        else
                           return General_Parameters.RED;
                        end if;
                     when others =>
                        raise Program_Error;
                  end case;
            end case;
         when Supplementary_Driving_Info.M_SR | Supplementary_Driving_Info.M_UN =>
            case Get_Monitoring_Mode is
               when CSM =>
                  case Get_Supervision_Status is
                     when NoS =>
                        return General_Parameters.GREY;
                     when OvS | WaS =>
                        return General_Parameters.ORANGE;
                     when IntS =>
                        if The_Speed <= Params.Vperm then
                           return General_Parameters.GREY;
                        else
                           return General_Parameters.RED;
                        end if;
                     when IndS =>
                        raise Program_Error;
                  end case;
               when PIM =>
                  case Get_Supervision_Status is
                     when NoS =>
                        if The_Speed <= Params.Vtarget then
                           return General_Parameters.GREY;
                        else
                           return General_Parameters.WHITE;
                        end if;
                     when OvS | WaS =>
                        return General_Parameters.ORANGE;
                     when IntS =>
                        if The_Speed < Params.Vtarget then
                           return General_Parameters.GREY;
                        elsif The_Speed <= Params.Vperm then
                           return General_Parameters.WHITE;
                        else
                           return General_Parameters.RED;
                        end if;
                     when IndS =>
                        raise Program_Error;
                  end case;
               when TSM =>
                  case Get_Supervision_Status is
                     when NoS =>
                        if The_Speed <= Params.Vtarget then
                           return General_Parameters.GREY;
                        else
                           return General_Parameters.WHITE;
                        end if;
                     when IndS =>
                        return General_Parameters.YELLOW;
                     when OvS | WaS =>
                        return General_Parameters.ORANGE;
                     when IntS =>
                        if The_Speed < Params.Vtarget then
                           return General_Parameters.GREY;
                        elsif The_Speed <= Params.Vperm then
                           return General_Parameters.YELLOW;
                        else
                           return General_Parameters.RED;
                        end if;
                  end case;
               when RSM =>
                  raise Program_Error;
            end case;
         when Supplementary_Driving_Info.M_SH | Supplementary_Driving_Info.M_RV =>
            case Get_Monitoring_Mode is
               when CSM =>
                  case Get_Supervision_Status is
                     when NoS =>
                        return General_Parameters.GREY;
                     when OvS | WaS =>
                        return General_Parameters.ORANGE;
                     when IntS =>
                        if The_Speed <= Params.Vperm then
                           return General_Parameters.GREY;
                        else
                           return General_Parameters.RED;
                        end if;
                     when IndS =>
                        raise Program_Error;
                  end case;
               when others =>
                  raise Program_Error;
            end case;
         when Supplementary_Driving_Info.M_NL | Supplementary_Driving_Info.M_SB | Supplementary_Driving_Info.M_PT =>
            return General_Parameters.GREY;
         when Supplementary_Driving_Info.M_TR =>
            return General_Parameters.RED;
         when others =>
            raise Program_Error;
      end case;
   end Pointer_Color;

   -- DMI 8.2.1.2.3
   -- DMI 8.2.1.2.4
   Radius : constant Radius_T := 25;
   Color  : constant General_Parameters.Color := Pointer_Color;
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
            if (Poly (I).Y < Pixel_Y and Poly (J).Y >= Pixel_Y)
              or (Poly (J).Y < Pixel_Y and Poly (I).Y >= Pixel_Y)
            then
               Node_X (Nodes) := Poly (I).X + Integer
                 (Float(Pixel_Y - Poly (I).Y) / Float(Poly (J).Y - Poly (I).Y) * Float(Poly (J).X - Poly (I).X));
               Nodes := Nodes + 1;
            end if;
            J := I;
         end loop;

         J := Node_X'First;
         while J < Nodes -1 loop
            if Node_X (J) > Node_X (J+1) then
               Swap := Node_X (J);
               Node_X (J) := Node_X (J+1);
               Node_X (J+1) := Swap;
               if J > Node_X'First then J := J + 1; end if;
            else
               J := J + 1;
            end if;
         end loop;

         J := Node_X'First;
         while J < Nodes loop
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
   Fill_Center_Circle;
   Fill_Polygon (Rotate_And_Translate_Poly);
   Draw_Current_Train_Speed_Digital;
end Draw_Speed_Pointer;
