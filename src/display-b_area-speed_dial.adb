pragma Ada_2012;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Display;

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

   procedure Draw_Speed_Pointer is
      -- DMI 8.2.1.2.3
      -- DMI 8.2.1.2.4
      Radius              : constant Radius_T := 25;
      Color               : constant General_Parameters.Color := General_Parameters.GREY;
      A                   : constant Angle := Speed_To_Angle (Get_Speed);


      type Point is record
         X, Y : Integer;
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
      end;

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

   begin
      Fill_Center_Circle;
      Fill_Polygon (Rotate_And_Translate_Poly);
   end Draw_Speed_Pointer;

   ----------
   -- Draw --
   ----------

   procedure Draw is
   begin
      Draw_Speed_Indicator_Lines;
      Draw_Speed_Pointer;
   end Draw;

end Display.B_Area.Speed_Dial;
