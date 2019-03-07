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

pragma Ada_2012;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Display;
with Font;
with Font.FreeSans_18;
with Supervision_Mode;
with User_Settings;

package body Display.B_Area.Speed_Dial is

   function Speed_To_Angle (Speed : Speed_T) return Angle
   is
      subtype Max_Speed_T is Speed_T range 140 .. 400;

      function Linear_Scale (From, To : Angle; Max : Max_Speed_T; Min : Speed_T := 0) return Angle is
        (Angle (Float (To - From) * Float (Speed - Min) / Float (Max - Min) + Float (From)));
   begin
      case Get_Speed_Dial_Range is
         when Range_140 | Range_180 | Range_250 =>
            -- DMI 8.2.1.1.14.2
            -- DMI 8.2.1.1.13.2
            -- DMI 8.2.1.1.12.2
            return Linear_Scale (Lower_Limit, Upper_Limit, Max_Speed_Map (Get_Speed_Dial_Range));
         when Range_400 =>
            -- DMI 8.2.1.1.11.2
            if Speed < 200 then
               return Linear_Scale (Lower_Limit, Threshold_200, 200, 0);
            else
               return Linear_Scale (Threshold_200, Upper_Limit, Max_Speed_Map (Range_400), 200);
            end if;
      end case;
   end Speed_To_Angle;

   procedure Draw_Speed_Indicator_Lines is
      Max        : constant Speed_T := Max_Speed_Map (Get_Speed_Dial_Range);
      Short_Step : constant Speed_T := 10;
      Long_Step  :          Speed_T;

      procedure Draw_Tick (At_Speed : Speed_T; Inner_Radius : Radius_T) is
         X :          B_Buffer.Area_Width_T;
         Y :          B_Buffer.Area_Height_T;
         A : constant Angle := Speed_To_Angle (At_Speed);

         Sin_A : constant Float := Sin (Float (A));
         Cos_A : constant Float := Cos (Float (A));
      begin
         for R in Inner_Radius .. B0_Radius loop
            X := The_Center.X + Integer (Float'Rounding ((Float (R) * Sin_A)));
            Y := The_Center.Y - Integer (Float'Rounding ((Float (R) * Cos_A)));
            B_Buffer.Set_Pixel (X, Y, General_Parameters.WHITE);
         end loop;
      end Draw_Tick;
   begin
      case Get_Speed_Dial_Range is
         when Range_400 =>
            -- DMI 8.2.1.1.11.3
            Long_Step := 50;
         when others =>
            -- DMI 8.2.1.1.12.3
            -- DMI 8.2.1.1.13.3
            -- DMI 8.2.1.1.14.3
            Long_Step := 20;
      end case;

      for I in 0 .. Max loop
         if I rem Long_Step = 0 then
            Draw_Tick (At_Speed     => I,
                       Inner_Radius => B0_Radius_Inner_Long);
         elsif I rem Short_Step = 0 then
            Draw_Tick (At_Speed     => I,
                       Inner_Radius => B0_Radius_Inner_Short);
         end if;
      end loop;
   end Draw_Speed_Indicator_Lines;

   procedure Draw_Speed_Indicator_Numbers is
      -- DMI 8.2.1.1.5
      procedure Draw_Number (X      : B_Buffer.Area_Width_T;
                             Y      : B_Buffer.Area_Height_T;
                             Number : Wide_String) is
      begin
         B_Buffer.Draw_String (Pen_X      => X,
                               Pen_Y      => Y,
                               The_String => Number,
                               The_Size   => 16,
                               The_Color  => General_Parameters.WHITE);
      end Draw_Number;
   begin
      case Get_Speed_Dial_Range is
         when Range_140 =>
            -- DMI 8.2.1.1.14.3
            Draw_Number (85, 228, "0");
            Draw_Number (48, 177, "20");
            Draw_Number (55, 117, "40");
            Draw_Number (100, 79, "60");
            Draw_Number (158, 79, "80");
            Draw_Number (193, 121, "100");
            Draw_Number (200, 177, "120");
            Draw_Number (177, 227, "140");
         when Range_180 =>
            -- DMI 8.2.1.1.13.3
            Draw_Number (85, 228, "0");
            Draw_Number (51, 195, "20");
            Draw_Number (46, 142, "40");
            Draw_Number (71,  98, "60");
            Draw_Number (107, 79, "80");
            Draw_Number (150, 79, "100");
            Draw_Number (191, 103, "120");
            Draw_Number (200, 143, "140");
            Draw_Number (194, 190, "160");
            Draw_Number (177, 227, "180");
         when Range_250 =>
            -- DMI 8.2.1.1.12.3
            Draw_Number (85, 228, "0");
            Draw_Number (58, 206, "20");
            Draw_Number (46, 170, "40");
            Draw_Number (48, 135, "60");
            Draw_Number (65, 105, "80");
            Draw_Number (78,  82, "100");
            Draw_Number (113,  73, "120");
            Draw_Number (151,  77, "140");
            Draw_Number (180,  97, "160");
            Draw_Number (192, 124, "180");
            Draw_Number (200, 152, "200");
            Draw_Number (195, 185, "220");
            Draw_Number (189, 216, "240");
         when Range_400 =>
            -- DMI 8.2.1.1.11.3
            Draw_Number (85, 228, "0");
            Draw_Number (46, 167, "50");
            Draw_Number (58, 105, "100");
            Draw_Number (123, 73, "150");
            Draw_Number (185, 105, "200");
            Draw_Number (199, 167, "300");
            Draw_Number (177, 227, "400");
      end case;

   end Draw_Speed_Indicator_Numbers;

   procedure Draw_Speed_Pointer  is separate;

   procedure Draw_Release_Speed_Digital is
      procedure Draw_Number is
         B6_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (B6);
         The_Number : constant Wide_String := Speed_T'Wide_Image (Get_Speed_Params.Vrelease);
      begin
         B_Buffer.Draw_String (Pen_X      => B6_Area.Position.X + 2,
                               Pen_Y      => B6_Area.Position.Y + B6_Area.Height - 10,
                               The_String => The_Number (2 .. The_Number'Last),
                               The_Size   => 17,
                               The_Color  => General_Parameters.MEDIUM_GREY);
      end Draw_Number;
   begin
      -- DMI 8.2.1.6.5
      if not Get_Speed_Params.Vrelease_Exists then
         return;
      end if;
      case Supervision_Mode.Mode is
         when Supervision_Mode.M_FS | Supervision_Mode.M_LS =>
            if Get_Monitoring_Mode /= CSM then
                  Draw_Number;
            end if;
         when Supervision_Mode.M_OS =>
            if User_Settings.Toggle (User_Settings.Release_Speed_Digital)
              and Get_Monitoring_Mode /= CSM
            then
               Draw_Number;
            end if;
         when others =>
            null;
      end case;
   end Draw_Release_Speed_Digital;

   ----------
   -- Draw --
   ----------

   procedure Draw is
   begin
      Draw_Speed_Indicator_Lines;
      Draw_Speed_Indicator_Numbers;
      Draw_Speed_Pointer;
      Circular_Speed_Gauge.Draw;
      Draw_Release_Speed_Digital;
   end Draw;

   package body Circular_Speed_Gauge is
      procedure Draw is
         type Quadrant is (SW, NW, NE, SE);
         -- only correct in a quadrant (due to periodicity)
         procedure Draw_Circle_Sector_Quadrant (From_Angle,  To_Angle  : Angle;
                                                From_Radius, To_Radius : Radius_T;
                                                The_Color              : General_Parameters.Color;
                                                The_Quadrant           : Quadrant) is
            From_R_R : constant Natural := From_Radius**2;
            To_R_R   : constant Natural := To_Radius**2;
            Eps      : constant Angle := 0.001; -- needed for stability
            Tan_From : constant Float := Tan (Float (From_Angle + Eps));
            Tan_To   : constant Float := Tan (Float (To_Angle - Eps));
            -- Computation done in standard Cartesian coordinates
            subtype X_SW is Integer range -To_Radius .. 0;
            subtype Y_SW is Integer range -To_Radius .. 0;
            subtype X_NW is Integer range 0 .. To_Radius;
            subtype Y_NW is Integer range -To_Radius .. 0;
            subtype X_NE is Integer range 0 .. To_Radius;
            subtype Y_NE is Integer range 0 .. To_Radius;
            subtype X_SE is Integer range -To_Radius .. 0;
            subtype Y_SE is Integer range 0 .. To_Radius;

            procedure Fill_If_Needed (X, Y : Integer) is
               Dist_2 : constant Natural := X*X + Y*Y;
            begin
               if Dist_2 <= To_R_R and Dist_2 >= From_R_R then
                  declare
                     The_Tan : constant Float := (Float (Y) + 0.5) / (Float (X) + 0.5);
                  begin
                     if The_Tan <= Tan_To and The_Tan >= Tan_From then
                        -- Axes flipped as needed
                        B_Buffer.Set_Pixel (X         => The_Center.X + Y,
                                            Y         => The_Center.Y - X,
                                            The_Color => The_Color);
                     end if;
                  end;
               end if;
            end;
         begin
            case The_Quadrant is
               when SW =>
                  for Y in Y_SW loop
                     for X in X_SW loop
                        Fill_If_Needed (X, Y);
                     end loop;
                  end loop;
               when NW =>
                  for Y in Y_NW loop
                     for X in X_NW loop
                        Fill_If_Needed (X, Y);
                     end loop;
                  end loop;
               when NE =>
                  for Y in Y_NE loop
                     for X in X_NE loop
                        Fill_If_Needed (X, Y);
                     end loop;
                  end loop;
               when SE =>
                  for Y in Y_SE loop
                     for X in X_SE loop
                        Fill_If_Needed (X, Y);
                     end loop;
                  end loop;
            end case;
         end Draw_Circle_Sector_Quadrant;

         procedure Draw_Circle_Sector (From_Angle,  To_Angle  : Angle;
                                       From_Radius, To_Radius : Radius_T;
                                       The_Color              : General_Parameters.Color) is
            subtype Q_SW is Angle range -Pi .. -Pi/2.0;
            subtype Q_NW is Angle range -Pi/2.0 .. 0.0;
            subtype Q_NE is Angle range 0.0 .. Pi/2.0;
            subtype Q_SE is Angle range Pi/2.0 .. Pi;
            procedure DCSQ (From_Angle, To_Angle : Angle;
                            F_Rad        : Radius_T := From_Radius;
                            To_Rad       : Radius_T := To_Radius;
                            The_Col      : General_Parameters.Color := The_Color;
                            The_Quadrant : Quadrant) renames Draw_Circle_Sector_Quadrant;
         begin

            if From_Angle in Q_SW then
               if To_Angle in Q_SW then
                 DCSQ (From_Angle, To_Angle, The_Quadrant => SW);
               elsif To_Angle in Q_NW then
                  DCSQ (From_Angle, -Pi/2.0, The_Quadrant => SW);
                  DCSQ (-Pi/2.0, To_Angle, The_Quadrant => NW);
               elsif To_Angle in Q_NE then
                  DCSQ (From_Angle, -Pi/2.0, The_Quadrant => SW);
                  DCSQ (-Pi/2.0, 0.0, The_Quadrant => NW);
                  DCSQ (0.0, To_Angle, The_Quadrant => NE);
               elsif To_Angle in Q_SE then
                  DCSQ (From_Angle, -Pi/2.0, The_Quadrant => SW);
                  DCSQ (-Pi/2.0, 0.0, The_Quadrant => NW);
                  DCSQ (0.0, Pi/2.0, The_Quadrant => NE);
                  DCSQ (Pi/2.0, To_Angle, The_Quadrant => SE);
               else
                 raise Program_Error with "Cannot get here";
               end if;
            elsif From_Angle in Q_NW then
               if To_Angle in Q_NW then
                  DCSQ (From_Angle, To_Angle, The_Quadrant => NW);
               elsif To_Angle in Q_NE then
                  DCSQ (From_Angle, 0.0, The_Quadrant => NW);
                  DCSQ (0.0, To_Angle, The_Quadrant => NE);
               elsif To_Angle in Q_SE then
                  DCSQ (From_Angle, 0.0, The_Quadrant => NW);
                  DCSQ (0.0, Pi/2.0, The_Quadrant => NE);
                  DCSQ (Pi/2.0, To_Angle, The_Quadrant => SE);
               else
                 raise Program_Error with "Cannot get here";
               end if;
            elsif From_Angle in Q_NE then
               if To_Angle in Q_NE then
                  DCSQ (From_Angle, To_Angle, The_Quadrant => NE);
               elsif To_Angle in Q_SE then
                  DCSQ (From_Angle, Pi/2.0, The_Quadrant => NE);
                  DCSQ (Pi/2.0, To_Angle, The_Quadrant => SE);
               else
                 raise Program_Error with "Cannot get here";
               end if;
            elsif From_Angle in Q_SE then
               if To_Angle in Q_SE then
                  DCSQ (From_Angle, To_Angle, The_Quadrant => SE);
               else
                 raise Program_Error with "Cannot get here";
               end if;
            else
               raise Program_Error with "Invalid From_Angle";
            end if;

         end Draw_Circle_Sector;

         procedure Draw_Lowermost_Part is
         begin
            Draw_Circle_Sector (From_Angle  => Lowermost_Limit,
                                To_Angle    => Lower_Limit,
                                From_Radius => B2_Radius_Inner,
                                To_Radius   => B2_Radius_Outer,
                                The_Color   => Lowermost_Part_Color);
         end Draw_Lowermost_Part;

         procedure Draw_Thin_CSG (From_Speed, To_Speed : Speed_T;
                                  The_Color            : General_Parameters.Color) is
         begin
            Draw_Circle_Sector (From_Angle  => Speed_To_Angle (From_Speed),
                                To_Angle    => Speed_To_Angle (To_Speed),
                                From_Radius => B2_Radius_Inner,
                                To_Radius   => B2_Radius_Outer,
                                The_Color   => The_Color);
         end Draw_Thin_CSG;

         procedure Draw_Wide_CSG (From_Speed, To_Speed : Speed_T;
                                  The_Color            : General_Parameters.Color) is
         begin
            Draw_Circle_Sector (From_Angle  => Speed_To_Angle (From_Speed),
                                To_Angle    => Speed_To_Angle (To_Speed),
                                From_Radius => Hook_Inner_Radius,
                                To_Radius   => B2_Radius_Outer,
                                The_Color   => The_Color);
         end Draw_Wide_CSG;

         procedure Draw_Hook (At_Speed  : Speed_T;
                              The_Color : General_Parameters.Color) is
            Speed_Angle : constant Angle := Speed_To_Angle (At_Speed);
         begin
            Draw_Circle_Sector (From_Angle  => Speed_Angle - Hook_Width,
                                To_Angle    => Speed_Angle,
                                From_Radius => Hook_Inner_Radius,
                                To_Radius   => B2_Radius_Outer,
                                The_Color   => The_Color);
         end Draw_Hook;

         procedure Draw_Basic_Speed_Hook (At_Speed  : Speed_T;
                                          The_Color : General_Parameters.Color) is
            Speed_Angle : constant Angle := Speed_To_Angle (At_Speed);
         begin
            -- DMI 8.2.1.5.4
            Draw_Circle_Sector (From_Angle  => Speed_Angle - Basic_Speed_Hook_Width,
                                To_Angle    => Speed_Angle,
                                From_Radius => Hook_Inner_Radius,
                                To_Radius   => B2_Radius_Outer,
                                The_Color   => The_Color);
         end Draw_Basic_Speed_Hook;

         Release_Or_Target_Speed : Speed_T;

         Vrelease_Missing_Error : exception;

         use type Supervision_Mode.Mode_T;
      begin
         case Supervision_Mode.Mode is
            when Supervision_Mode.M_FS =>
               -- DMI 8.2.1.4.9
               Draw_Lowermost_Part;
               case Get_Monitoring_Mode is
               when CSM =>
                  Draw_Thin_CSG (0, Get_Speed_Params.Vperm, General_Parameters.DARK_GREY);
                  Draw_Hook (Get_Speed_Params.Vperm, General_Parameters.DARK_GREY);
                  if Get_Supervision_Status in OvS | WaS then
                     Draw_Wide_CSG (Get_Speed_Params.Vperm, Get_Speed_Params.Vsbi, General_Parameters.ORANGE);
                  elsif Get_Supervision_Status = IntS then
                     Draw_Wide_CSG (Get_Speed_Params.Vperm, Get_Speed_Params.Vsbi, General_Parameters.RED);
                  end if;
               when PIM =>
                  if Get_Speed_Params.Vrelease_Exists then
                     Release_Or_Target_Speed := Get_Speed_Params.Vrelease;
                     Draw_Thin_CSG (0, Release_Or_Target_Speed, General_Parameters.MEDIUM_GREY);
                  else
                     Release_Or_Target_Speed := Get_Speed_Params.Vtarget;
                     Draw_Thin_CSG (0, Release_Or_Target_Speed, General_Parameters.DARK_GREY);
                  end if;
                  Draw_Thin_CSG (Release_Or_Target_Speed, Get_Speed_Params.Vperm, General_Parameters.WHITE);
                  Draw_Hook (Get_Speed_Params.Vperm, General_Parameters.WHITE);
                  if Get_Supervision_Status in OvS | WaS then
                     Draw_Wide_CSG (Get_Speed_Params.Vperm, Get_Speed_Params.Vsbi, General_Parameters.ORANGE);
                  elsif Get_Supervision_Status = IntS then
                     Draw_Wide_CSG (Get_Speed_Params.Vperm, Get_Speed_Params.Vsbi, General_Parameters.RED);
                  end if;
               when TSM =>
                  if Get_Speed_Params.Vrelease_Exists then
                     Release_Or_Target_Speed := Get_Speed_Params.Vrelease;
                     Draw_Thin_CSG (0, Release_Or_Target_Speed, General_Parameters.MEDIUM_GREY);
                  else
                     Release_Or_Target_Speed := Get_Speed_Params.Vtarget;
                     Draw_Thin_CSG (0, Release_Or_Target_Speed, General_Parameters.DARK_GREY);
                  end if;
                  if Get_Supervision_Status = NoS then
                     Draw_Thin_CSG (Release_Or_Target_Speed, Get_Speed_Params.Vperm, General_Parameters.WHITE);
                     Draw_Hook (Get_Speed_Params.Vperm, General_Parameters.WHITE);
                  else
                     Draw_Thin_CSG (Release_Or_Target_Speed, Get_Speed_Params.Vperm, General_Parameters.YELLOW);
                     Draw_Hook (Get_Speed_Params.Vperm, General_Parameters.YELLOW);
                  end if;
                  if Get_Supervision_Status in OvS | WaS then
                     Draw_Wide_CSG (Get_Speed_Params.Vperm, Get_Speed_Params.Vsbi, General_Parameters.ORANGE);
                  elsif Get_Supervision_Status = IntS then
                     Draw_Wide_CSG (Get_Speed_Params.Vperm, Get_Speed_Params.Vsbi, General_Parameters.RED);
                  end if;
               when RSM =>
                  if Get_Speed_Params.Vrelease_Exists then
                     Draw_Thin_CSG (0, Get_Speed_Params.Vrelease, General_Parameters.MEDIUM_GREY);
                     Release_Or_Target_Speed := Get_Speed_Params.Vrelease;
                     Draw_Thin_CSG (Release_Or_Target_Speed, Get_Speed_Params.Vperm, General_Parameters.YELLOW);
                     Draw_Hook (Get_Speed_Params.Vperm, General_Parameters.YELLOW);
                  else
                     raise Vrelease_Missing_Error;
                  end if;
               end case;
            when Supervision_Mode.M_OS | Supervision_Mode.M_SR =>
               -- DMI 8.2.1.5.7
               -- Basic Speed Hook
               if User_Settings.Toggle (User_Settings.Basic_Speed_Hook) then
                  if Get_Monitoring_Mode /= CSM then
                     Draw_Basic_Speed_Hook (Get_Speed_Params.Vtarget, General_Parameters.MEDIUM_GREY);
                  end if;
                  -- DMI 8.2.1.5.6
                  Draw_Basic_Speed_Hook (Get_Speed_Params.Vperm, General_Parameters.WHITE);
               end if;
            when Supervision_Mode.M_SH =>
               if User_Settings.Toggle (User_Settings.Basic_Speed_Hook) then
                  Draw_Basic_Speed_Hook (Get_Speed_Params.Vperm, General_Parameters.WHITE);
               end if;
            when Supervision_Mode.M_RV =>
               Draw_Basic_Speed_Hook (Get_Speed_Params.Vperm, General_Parameters.WHITE);
            when others =>
               null;
         end case;

      end Draw;
   end Circular_Speed_Gauge;

end Display.B_Area.Speed_Dial;
