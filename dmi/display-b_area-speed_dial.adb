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
with DMI_ATO;
with DMI_Status;
with Font;
with Font.FreeSans_18;
with Supplementary_Driving_Info;
with User_Settings;

package body Display.B_Area.Speed_Dial is

   function Speed_To_Angle (Speed : Speed_T) return Angle
   is
      subtype Max_Speed_T is Speed_T range 140 .. 400;

      function Linear_Scale (From, To : Angle; Max : Max_Speed_T; Min : Speed_T := 0) return Angle is
        (Angle (Float (To - From) * Float (Speed - Min) / Float (Max - Min) + Float (From)));
   begin
      -- DMI 8.2.1.1.4: the dial indicates speeds from 0 km/h to the maximum
      -- of the pre-configured range, and 8.2.1.1.10 defines the mapping used
      -- by B1 and B2 for that range only; 8.2.1.4.4 ends the CSG at +144
      -- degrees. No clause extends the scale, so everything positioned by
      -- this mapping (pointer, CSG, hooks, set speed) rests at the end of
      -- the scale for a speed above the dial maximum. The speed itself is
      -- not altered: colours and the digital values use the real value.
      -- Without this a speed of 158 km/h on the 140 km/h dial already
      -- leaves the range of Angle. Below the guard Speed <= Max holds, so
      -- Linear_Scale yields From .. To, inside Lower_Limit .. Upper_Limit.
      if Speed > Max_Speed_Map (Get_Speed_Dial_Range) then
         return Upper_Limit;
      end if;

      case Get_Speed_Dial_Range is
         when Range_140 | Range_180 | Range_250 =>
            -- DMI 8.2.1.1.14.2 (Range 140)
            -- DMI 8.2.1.1.13.2 (Range 180)
            -- DMI 8.2.1.1.12.2 (Range 250)
            return Linear_Scale (Lower_Limit, Upper_Limit, Max_Speed_Map (Get_Speed_Dial_Range));
         when Range_400 =>
            -- DMI 8.2.1.1.11.2: two linear segments with the break at 200 km/h
            if Speed < 200 then
               return Linear_Scale (Lower_Limit, Threshold_200, 200, 0);
            else
               return Linear_Scale (Threshold_200, Upper_Limit, Max_Speed_Map (Range_400), 200);
            end if;
      end case;
   end Speed_To_Angle;

   ----------------
   -- Cell model --
   ----------------

   -- B0 and B2 are centred in B (6.3.1.2 a, c): their centre is the point
   -- The_Center of area B, the corner that four cells share. Cell (X, Y)
   -- covers [X, X + 1) x [Y, Y + 1), and a shape takes the cells whose
   -- centre (X + 0.5, Y + 0.5) lies inside it. No cell is blended: every
   -- cell gets one colour of Table 4. In this model the ring from radius
   -- 128 to 137 is 9 cells wide (8.2.1.4.6), a disc of radius 25 is 50
   -- cells across (Figure 34) and a rectangle of 6 x 20 cells takes 6 x
   -- 20 cells wherever it lies along a radius at 0, 90 or 180 degrees.

   subtype Column_T is Integer range 0 .. The_Area.Width - 1;
   subtype Row_T    is Integer range 0 .. The_Area.Height - 1;

   Centre_X : constant Float := Float (The_Center.X);
   Centre_Y : constant Float := Float (The_Center.Y);

   -- Offset of the centre of column X (row Y) from the centre of the
   -- dial, East (North) positive
   function East (X : Integer) return Float is
     (Float (X) + 0.5 - Centre_X);
   function North (Y : Integer) return Float is
     (Centre_Y - (Float (Y) + 0.5));

   -- The column (row) of the cell holding the point East (North) of the
   -- centre, kept inside area B so that drawing stays total
   function Column_Of (E : Float) return Column_T is
     (if E + Centre_X < Float (Column_T'First) then Column_T'First
      elsif E + Centre_X >= Float (Column_T'Last) then Column_T'Last
      else Integer (Float'Floor (E + Centre_X)));
   function Row_Of (N : Float) return Row_T is
     (if Centre_Y - N < Float (Row_T'First) then Row_T'First
      elsif Centre_Y - N >= Float (Row_T'Last) then Row_T'Last
      else Integer (Float'Floor (Centre_Y - N)));

   -- A stand-in for the angle of the direction (E, N), clockwise from
   -- the top as the dial counts (8.2.1.1.11.1): it grows with the angle
   -- from -2 (-180 degrees) through 0 (straight up) to 2 (180 degrees),
   -- so comparing it compares angles, without an arc tangent per cell.
   function Pseudo_Angle (E, N : Float) return Float is
      Sum : constant Float := abs E + abs N;
      T   : Float;
   begin
      if Sum = 0.0 then
         return 0.0;
      end if;
      T := E / Sum;
      if N >= 0.0 then
         return T;
      elsif E >= 0.0 then
         return 2.0 - T;
      else
         return -2.0 - T;
      end if;
   end Pseudo_Angle;

   function Pseudo_Angle (A : Angle) return Float is
     (Pseudo_Angle (Sin (Float (A)), Cos (Float (A))));

   -- The cells of the ring Inner <= r < Outer from angle From (included)
   -- clockwise to angle To (excluded). The dial never crosses the bottom
   -- (8.2.1.4.4: -149 .. +144 degrees), so an angle range is an interval.
   procedure Fill_Ring_Sector (From, To     : Angle;
                               Inner, Outer : Radius_T;
                               The_Color    : General_Parameters.Color) is
      Q_From  : constant Float := Pseudo_Angle (From);
      Q_To    : constant Float := Pseudo_Angle (To);
      Inner_2 : constant Float := Float (Inner) ** 2;
      Outer_2 : constant Float := Float (Outer) ** 2;
      N_2     : Float;
      -- half the width of the outer and of the inner circle on a row
      Outer_W, Inner_W : Float;

      procedure Test (X : Column_T; Y : Row_T) is
         R_2 : constant Float := East (X) ** 2 + North (Y) ** 2;
         Q   : Float;
      begin
         if R_2 >= Inner_2 and R_2 < Outer_2 then
            Q := Pseudo_Angle (East (X), North (Y));
            if Q >= Q_From and Q < Q_To then
               B_Buffer.Set_Pixel (X, Y, The_Color);
            end if;
         end if;
      end Test;
   begin
      if To <= From or Outer <= Inner then
         return;
      end if;
      -- Every cell of the ring is tested; the columns looked at on a row
      -- only leave out cells that are certainly outside it.
      for Y in Row_Of (Float (Outer)) .. Row_Of (-Float (Outer)) loop
         N_2 := North (Y) ** 2;
         if N_2 < Outer_2 then
            Outer_W := Sqrt (Outer_2 - N_2);
            Inner_W := (if N_2 < Inner_2 then Sqrt (Inner_2 - N_2) else 0.0);
            for X in Column_Of (-Outer_W) .. Column_Of (-Inner_W) loop
               Test (X, Y);
            end loop;
            for X in Column_Of (Inner_W) .. Column_Of (Outer_W) loop
               Test (X, Y);
            end loop;
         end if;
      end loop;
   end Fill_Ring_Sector;

   -- The cells of the rectangle along the radius at angle At_Angle: from
   -- radius Inner (included) to Outer (excluded) along the radius, and
   -- Width cells across it on the side of the smaller angles, so that
   -- its upper limit is the radius at At_Angle (8.2.1.4.7, 8.2.1.5.4).
   procedure Fill_Radial_Rectangle (At_Angle     : Angle;
                                    Inner, Outer : Radius_T;
                                    Width        : Positive;
                                    The_Color    : General_Parameters.Color) is
      -- unit vectors along the radius (U) and along the scale (V)
      S : constant Float := Sin (Float (At_Angle));
      C : constant Float := Cos (Float (At_Angle));
      W : constant Float := Float (Width);
      -- the corners bound the cells to look at
      E_1 : constant Float := Float (Inner) * S;
      E_2 : constant Float := Float (Outer) * S;
      N_1 : constant Float := Float (Inner) * C;
      N_2 : constant Float := Float (Outer) * C;
      E_Min : constant Float := Float'Min (E_1, E_2) - W * abs C - 1.0;
      E_Max : constant Float := Float'Max (E_1, E_2) + W * abs C + 1.0;
      N_Min : constant Float := Float'Min (N_1, N_2) - W * abs S - 1.0;
      N_Max : constant Float := Float'Max (N_1, N_2) + W * abs S + 1.0;
      U, V  : Float;
   begin
      for Y in Row_Of (N_Max) .. Row_Of (N_Min) loop
         for X in Column_Of (E_Min) .. Column_Of (E_Max) loop
            U := East (X) * S + North (Y) * C;
            V := East (X) * C - North (Y) * S;
            if U >= Float (Inner) and U < Float (Outer)
              and V >= -W and V < 0.0
            then
               B_Buffer.Set_Pixel (X, Y, The_Color);
            end if;
         end loop;
      end loop;
   end Fill_Radial_Rectangle;

   -- The cells of the disc of the given radius around the point E, N
   -- (offsets from the centre of the dial)
   procedure Fill_Disc (E, N      : Float;
                        Radius    : Float;
                        The_Color : General_Parameters.Color) is
   begin
      for Y in Row_Of (N + Radius) .. Row_Of (N - Radius) loop
         for X in Column_Of (E - Radius) .. Column_Of (E + Radius) loop
            if (East (X) - E) ** 2 + (North (Y) - N) ** 2 < Radius ** 2 then
               B_Buffer.Set_Pixel (X, Y, The_Color);
            end if;
         end loop;
      end loop;
   end Fill_Disc;

   procedure Draw_Speed_Indicator_Lines is
      Max        : constant Speed_T := Max_Speed_Map (Get_Speed_Dial_Range);
      Short_Step : constant Speed_T := 10;
      Long_Step  :          Speed_T;

      -- DMI 8.2.1.1.5 a, 8.2.1.1.8: a line 1 cell wide drawn radially from
      -- the limit of B0 towards the centre; one cell for every cell of
      -- its length, taken at the middle of that cell
      procedure Draw_Tick (At_Speed : Speed_T; Length : Radius_T) is
         A : constant Angle := Speed_To_Angle (At_Speed);

         Sin_A : constant Float := Sin (Float (A));
         Cos_A : constant Float := Cos (Float (A));
         R     : Float;
      begin
         for K in 1 .. Length loop
            R := Float (B0_Radius - K) + 0.5;
            B_Buffer.Set_Pixel (Column_Of (R * Sin_A), Row_Of (R * Cos_A),
                                General_Parameters.WHITE);
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
            Draw_Tick (At_Speed => I, Length => Long_Line_Length);
         elsif I rem Short_Step = 0 then
            Draw_Tick (At_Speed => I, Length => Short_Line_Length);
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
      procedure Draw_Number (The_Color : General_Parameters.Color) is
         B6_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (B6);
         The_Number : constant Wide_String := Speed_T'Wide_Image (Get_Speed_Params.Vrelease);
      begin
         B_Buffer.Draw_String (Pen_X      => B6_Area.Position.X + 2,
                               Pen_Y      => B6_Area.Position.Y + B6_Area.Height - 10,
                               The_String => The_Number (2 .. The_Number'Last),
                               The_Size   => 17,
                               The_Color  => The_Color);
      end Draw_Number;

      In_TSM_Or_RSM : constant Boolean := Get_Monitoring_Mode in TSM | RSM;
   begin
      -- DMI 8.2.1.6.5, Table 11
      if not Get_Speed_Params.Vrelease_Exists or not In_TSM_Or_RSM then
         return;
      end if;
      case Supplementary_Driving_Info.Mode is
         when Supplementary_Driving_Info.M_FS
            | Supplementary_Driving_Info.M_SM
            | Supplementary_Driving_Info.M_LS =>
            Draw_Number (General_Parameters.YELLOW);
         when Supplementary_Driving_Info.M_OS =>
            -- shown only if the driver has toggled it on (Table 11 note)
            if User_Settings.Speed_Info_Visible then
               Draw_Number (General_Parameters.YELLOW);
            end if;
         when Supplementary_Driving_Info.M_AD =>
            Draw_Number (General_Parameters.MEDIUM_GREY);
         when others =>
            null;
      end case;
   end Draw_Release_Speed_Digital;

   ----------
   -- Draw --
   ----------

   -- A disc of 10 cells diameter whose centre is on the circle of radius
   -- 111 around the centre of B0, at the given speed
   procedure Draw_Speed_Dot (Speed     : Natural;
                             The_Color : General_Parameters.Color) is
      Value : constant Speed_T := Speed_T (Natural'Min (Speed, 400));
      A     : constant Angle := Speed_To_Angle (Value);
   begin
      Fill_Disc (E         => 111.0 * Sin (Float (A)),
                 N         => 111.0 * Cos (Float (A)),
                 Radius    => 5.0,
                 The_Color => The_Color);
   end Draw_Speed_Dot;

   procedure Draw_Set_Speed is
   begin
      -- DMI 8.2.3.9: white circle, 10 cell diameter, centre on the
      -- radius 111 circle at the Set Speed value, covering the dial
      Draw_Speed_Dot (DMI_Status.Set_Speed, General_Parameters.WHITE);
   end Draw_Set_Speed;

   procedure Draw_Target_Advice_Speed is
   begin
      -- DMI 8.5.9.3 / 8.5.9.4: a medium grey circle, 10 cell diameter,
      -- centre on the radius 111 circle at the target advice speed
      Draw_Speed_Dot (DMI_ATO.Advice_Speed, General_Parameters.MEDIUM_GREY);
   end Draw_Target_Advice_Speed;

   procedure Draw is
   begin
      Draw_Speed_Indicator_Lines;
      Draw_Speed_Indicator_Numbers;
      -- draws nothing where Table 8 gives no colour (8.2.1.2.5)
      Draw_Speed_Pointer;
      Circular_Speed_Gauge.Draw;
      Circular_Speed_Gauge.Draw_Hooks;
      Draw_Release_Speed_Digital;
      -- DMI 8.5.9.5: the target advice speed covers the speed dial and
      -- is covered by the set speed; it is ATO information shown outside
      -- stopping points while the ATO selector is "On" (8.5.1.1,
      -- 8.5.1.2 d)
      if DMI_ATO.Outside_Shown and then DMI_ATO.Advice_Valid then
         Draw_Target_Advice_Speed;
      end if;
      if DMI_Status.Set_Speed_Valid then
         Draw_Set_Speed;
      end if;
   end Draw;

   package body Circular_Speed_Gauge is

      procedure Draw_Lowermost_Part is
      begin
         -- DMI 8.2.1.4.5
         Fill_Ring_Sector (From      => Lowermost_Limit,
                           To        => Lower_Limit,
                           Inner     => B2_Radius_Inner,
                           Outer     => B2_Radius_Outer,
                           The_Color => Lowermost_Part_Color);
      end Draw_Lowermost_Part;

      -- DMI 8.2.1.4.6: 9 cells wide, the ring of B2 (6.3.1.2 c)
      procedure Draw_Thin_CSG (From_Speed, To_Speed : Speed_T;
                               The_Color            : General_Parameters.Color) is
      begin
         Fill_Ring_Sector (From      => Speed_To_Angle (From_Speed),
                           To        => Speed_To_Angle (To_Speed),
                           Inner     => B2_Radius_Inner,
                           Outer     => B2_Radius_Outer,
                           The_Color => The_Color);
      end Draw_Thin_CSG;

      -- DMI 8.2.1.4.8: between the hook and VSBI as wide as the hook, 20
      -- cells from the outer border of the CSG
      procedure Draw_Wide_CSG (From_Speed, To_Speed : Speed_T;
                               The_Color            : General_Parameters.Color) is
      begin
         Fill_Ring_Sector (From      => Speed_To_Angle (From_Speed),
                           To        => Speed_To_Angle (To_Speed),
                           Inner     => Hook_Inner_Radius,
                           Outer     => B2_Radius_Outer,
                           The_Color => The_Color);
      end Draw_Wide_CSG;

      -- DMI 8.2.1.4.7: at Vperm a hook of 6 x 20 cells covering the outer
      -- border of the speed dial, its upper limit at Vperm
      procedure Draw_Hook (At_Speed  : Speed_T;
                           The_Color : General_Parameters.Color) is
      begin
         Fill_Radial_Rectangle (At_Angle  => Speed_To_Angle (At_Speed),
                                Inner     => Hook_Inner_Radius,
                                Outer     => B2_Radius_Outer,
                                Width     => CSG_Hook_Width,
                                The_Color => The_Color);
      end Draw_Hook;

      -- DMI 8.2.1.6.3/.4, Figures 47 and 48: graphical release speed on the
      -- CSG (target at the EOA, Vtarget = 0: Table 9 footnote). Up to the
      -- lower of Vperm and Vrelease the CSG is split: the release speed at
      -- the outer part (5 cells), a 1 cell line in the background colour
      -- and the permitted speed at the inner part (3 cells). Above it the
      -- one that goes further takes the whole 9 cells: the permitted speed
      -- up to Vperm (Figure 47) or the release speed up to Vrelease
      -- (Figure 48). The hook at Vperm is drawn before: in Figure 48 the
      -- release speed display and the line cover its outer part.
      procedure Draw_Release_Graphical (Perm_Color : General_Parameters.Color) is
         Params : constant Speed_Params := Get_Speed_Params;
         Below  : constant Speed_T :=
           Speed_T'Min (Params.Vrelease, Params.Vperm);
         Zero   : constant Angle := Speed_To_Angle (0);
         Split  : constant Angle := Speed_To_Angle (Below);
      begin
         Fill_Ring_Sector (Zero, Split, B2_Radius_Inner, Release_Perm_Outer,
                           Perm_Color);
         Fill_Ring_Sector (Zero, Split, Release_Perm_Outer, Release_Band_Inner,
                           General_Parameters.Background_Color);
         Fill_Ring_Sector (Zero, Split, Release_Band_Inner, B2_Radius_Outer,
                           General_Parameters.MEDIUM_GREY);
         Draw_Thin_CSG (Params.Vrelease, Params.Vperm, Perm_Color);
         Draw_Thin_CSG (Params.Vperm, Params.Vrelease,
                        General_Parameters.MEDIUM_GREY);
      end Draw_Release_Graphical;

      ----------
      -- Draw --
      ----------

      procedure Draw is
         Params : constant Speed_Params := Get_Speed_Params;
         In_AD  : Boolean;
         Mid    : General_Parameters.Color;
         Over   : General_Parameters.Color;

         use type Supplementary_Driving_Info.Mode_T;
      begin
         -- Table 9: the CSG exists only in FS and AD modes
         if Supplementary_Driving_Info.Mode not in
           Supplementary_Driving_Info.M_FS | Supplementary_Driving_Info.M_AD
         then
            return;
         end if;
         In_AD := Supplementary_Driving_Info.Mode = Supplementary_Driving_Info.M_AD;

         -- Table 9 AD rows with IntS are fully "not applicable": no CSG at all
         if In_AD and then Get_Supervision_Status = IntS then
            return;
         end if;

         Draw_Lowermost_Part;

         case Get_Monitoring_Mode is
            when CSM =>
               if Get_CSM_Target_Info then
                  Mid := General_Parameters.WHITE;
                  Draw_Thin_CSG (0, Params.Vtarget, General_Parameters.DARK_GREY);
                  Draw_Thin_CSG (Params.Vtarget, Params.Vperm, Mid);
                  Draw_Hook (Params.Vperm, Mid);
                  Over := (if In_AD then General_Parameters.WHITE
                           else General_Parameters.ORANGE);
               else
                  Mid := General_Parameters.DARK_GREY;
                  Draw_Thin_CSG (0, Params.Vperm, Mid);
                  Draw_Hook (Params.Vperm, Mid);
                  Over := (if In_AD then General_Parameters.DARK_GREY
                           else General_Parameters.ORANGE);
               end if;
               if Get_Supervision_Status in OvS | WaS then
                  Draw_Wide_CSG (Params.Vperm, Params.Vsbi, Over);
               elsif Get_Supervision_Status = IntS then
                  Draw_Wide_CSG (Params.Vperm, Params.Vsbi, General_Parameters.RED);
               end if;

            when TSM =>
               Mid := (if In_AD then General_Parameters.WHITE
                       else General_Parameters.YELLOW);
               -- the hook first: the release speed covers it (Figure 48)
               Draw_Hook (Params.Vperm, Mid);
               if Params.Vrelease_Exists then
                  -- target is an EOA, Vtarget = 0 (Table 9 footnote)
                  Draw_Release_Graphical (Mid);
               else
                  Draw_Thin_CSG (0, Params.Vtarget, General_Parameters.DARK_GREY);
                  Draw_Thin_CSG (Params.Vtarget, Params.Vperm, Mid);
               end if;
               if Get_Supervision_Status in OvS | WaS then
                  Over := (if In_AD then General_Parameters.WHITE
                           else General_Parameters.ORANGE);
                  Draw_Wide_CSG (Params.Vperm, Params.Vsbi, Over);
               elsif Get_Supervision_Status = IntS then
                  Draw_Wide_CSG (Params.Vperm, Params.Vsbi, General_Parameters.RED);
               end if;

            when RSM =>
               -- Table 9 RSM rows: no over-speed band
               Mid := (if In_AD then General_Parameters.WHITE
                       else General_Parameters.YELLOW);
               Draw_Hook (Params.Vperm, Mid);
               if Params.Vrelease_Exists then
                  Draw_Release_Graphical (Mid);
               else
                  Draw_Thin_CSG (0, Params.Vperm, Mid);
               end if;
         end case;
      end Draw;

      ----------------
      -- Draw_Hooks --
      ----------------

      procedure Draw_Hooks is
         Params : constant Speed_Params := Get_Speed_Params;

         use type Supplementary_Driving_Info.Mode_T;

         -- DMI 8.2.1.5.4 / 8.2.1.5.5: a hook of 10 x 20 cells overlapping
         -- the outer border of the speed dial, its upper limit at the speed
         procedure Draw_Basic_Speed_Hook (At_Speed  : Speed_T;
                                          The_Color : General_Parameters.Color) is
         begin
            Fill_Radial_Rectangle (At_Angle  => Speed_To_Angle (At_Speed),
                                   Inner     => Hook_Inner_Radius,
                                   Outer     => B2_Radius_Outer,
                                   Width     => Basic_Speed_Hook_Width,
                                   The_Color => The_Color);
         end Draw_Basic_Speed_Hook;

         Show_Target : Boolean;
      begin
         -- DMI 8.2.1.5.7, Table 10. The mode and the monitoring arrive in
         -- separate messages, so the combinations without a row occur as
         -- well; for them the hooks are not applicable and are not drawn.
         case Supplementary_Driving_Info.Mode is
            when Supplementary_Driving_Info.M_SM
               | Supplementary_Driving_Info.M_OS
               | Supplementary_Driving_Info.M_SR =>
               -- OS and SR only when the driver has toggled the display on
               if Supplementary_Driving_Info.Mode /= Supplementary_Driving_Info.M_SM
                 and then not User_Settings.Speed_Info_Visible
               then
                  return;
               end if;
               -- "RSM (not applicable for SR)"
               if Supplementary_Driving_Info.Mode = Supplementary_Driving_Info.M_SR
                 and then Get_Monitoring_Mode = RSM
               then
                  return;
               end if;
               Show_Target :=
                 (case Get_Monitoring_Mode is
                     when CSM       => Get_CSM_Target_Info,
                     when TSM | RSM => True);
               if Show_Target then
                  Draw_Basic_Speed_Hook (Params.Vtarget, General_Parameters.MEDIUM_GREY);
               end if;
               -- DMI 8.2.1.5.6: the Vperm hook overlays the Vtarget hook
               Draw_Basic_Speed_Hook (Params.Vperm, General_Parameters.WHITE);

            when Supplementary_Driving_Info.M_SH =>
               -- Table 10 has a CSM row only
               if User_Settings.Speed_Info_Visible
                 and then Get_Monitoring_Mode = CSM
               then
                  Draw_Basic_Speed_Hook (Params.Vperm, General_Parameters.WHITE);
               end if;

            when Supplementary_Driving_Info.M_RV =>
               -- Table 10 has a CSM row only
               if Get_Monitoring_Mode = CSM then
                  Draw_Basic_Speed_Hook (Params.Vperm, General_Parameters.WHITE);
               end if;

            when others =>
               null;
         end case;
      end Draw_Hooks;
   end Circular_Speed_Gauge;

end Display.B_Area.Speed_Dial;
