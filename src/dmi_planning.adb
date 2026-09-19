--  ETCS DMI
--  Planning area rendering (DMI 8.3). All geometry from the SRS: the
--  distance scale mapping of 8.3.3.3/Table 17, the layering of 8.3.2
--  (PASP, distance scale, advice marker, indication marker, then
--  orders/gradient/discontinuities).

pragma Ada_2012;
with Ada.Numerics.Elementary_Functions;
with Display.D_Area; use Display.D_Area;
with Display; use Display;
with General_Parameters;
with Supplementary_Driving_Info;
with Symbol;
with Track_Ahead_Free;
with User_Settings;

package body DMI_Planning is

   package SDI renames Supplementary_Driving_Info;

   -- Area D sub-area geometry (6.3.1.4), relative to D
   D2_X : constant := 40;   -- columns D2/D3/D4 start, 25 cells each
   D5_X : constant := 115;  -- gradient, 18 wide
   D6_X : constant := 133;  -- 14 wide
   D7_X : constant := 147;  -- 93 wide
   D7_W : constant := 93;
   D8_X : constant := 240;  -- 6 wide
   Top_Y    : constant := 15;
   Bottom_Y : constant := 284;

   Scale_Zero_Y   : constant := 283; -- Table 17, 1st line
   Scale_Second_Y : constant := 250; -- 2nd line (R/40)
   Scale_Top_Y    : constant := 21;  -- 9th line (R)

   -- cells per decade of the log segment (8.3.3.3 + Table 17)
   K_Log : constant Float := 229.0 / 1.6020599913; -- 229 / log10(40)

   function Can_Zoom_In return Boolean is
     (Current_Range > Range_Index_T'First);

   function Can_Zoom_Out return Boolean is
     (Current_Range < Range_Index_T'Last);

   procedure Zoom_In is
   begin
      if Can_Zoom_In then
         Current_Range := Current_Range - 1;
      end if;
   end Zoom_In;

   procedure Zoom_Out is
   begin
      if Can_Zoom_Out then
         Current_Range := Current_Range + 1;
      end if;
   end Zoom_Out;

   function Displayed return Boolean is
      use type SDI.Mode_T;
   begin
      if not Valid then
         return False;
      end if;
      case SDI.Mode is
         when SDI.M_FS | SDI.M_SM | SDI.M_AD =>
            return True;
         when SDI.M_OS =>
            -- 8.3.1.1 c
            return User_Settings.Speed_Info_Visible
              and then not Track_Ahead_Free.Show;
         when others =>
            return False;
      end case;
   end Displayed;

   -- Distance to a D-relative Y row per 8.3.3.3; distances beyond the
   -- range map above the scale and are reported as Top_Y - 1 (clipped)
   function Y_Of (Dist_M : Natural) return Integer is
      use Ada.Numerics.Elementary_Functions;
      R     : constant Natural := Range_Max (Current_Range);
      D_Lin : constant Float := Float (R) / 40.0;
   begin
      if Dist_M <= 0 then
         return Scale_Zero_Y;
      elsif Float (Dist_M) <= D_Lin then
         return Scale_Zero_Y
           - Integer (Float'Rounding (33.0 * Float (Dist_M) / D_Lin));
      elsif Dist_M >= R then
         return (if Dist_M = R then Scale_Top_Y else Top_Y - 1);
      else
         return Scale_Second_Y
           - Integer (Float'Rounding
                        (K_Log * Log (Float (Dist_M) / D_Lin, 10.0)));
      end if;
   end Y_Of;

   procedure Fill_Rect (X, Y : Integer; W, H : Natural;
                        Color : General_Parameters.Color) is
      Y_From : constant Integer := Integer'Max (Y, Top_Y);
      Y_To   : constant Integer := Integer'Min (Y + H - 1, Bottom_Y);
   begin
      for Row in Y_From .. Y_To loop
         for Col in X .. X + W - 1 loop
            D_Buffer.Set_Pixel (Col, Row, Color);
         end loop;
      end loop;
   end Fill_Rect;

   -- 8.3.4.2, 8.3.5.2, 8.3.6.2, 8.3.7.2: every object is displayed
   -- "within the movement authority and up to the first target at zero
   -- speed, if any". The first target at zero speed is the first speed
   -- discontinuity to 0 km/h; it normally is the end of the movement
   -- authority, the nearer of the two is the limit.
   function Display_Limit_M return Natural is
   begin
      for I in 1 .. Speed_Count loop
         if Speeds (I).Speed = 0 then
            return Natural'Min (Speeds (I).Dist_M, MA_Dist_M);
         end if;
      end loop;
      return MA_Dist_M;
   end Display_Limit_M;

   ---------------------------------------------------------------------
   -- PASP (8.3.7)
   ---------------------------------------------------------------------

   procedure Draw_PASP is
      function Width_Of (Speed : Natural) return Natural is
         Percent : Natural;
      begin
         -- 8.3.7.7: fixed quarters relative to the ceiling speed
         if Ceiling_Speed = 0 then
            return 0;
         end if;
         Percent := Speed * 100 / Ceiling_Speed;
         if Speed = 0 then
            return 0;
         elsif Percent >= 100 then
            return D7_W;
         elsif Percent >= 75 then
            return D7_W * 3 / 4;
         elsif Percent >= 50 then
            return D7_W / 2;
         else
            return D7_W / 4;
         end if;
      end Width_Of;

      -- 8.3.7.5: a discontinuity counts when it is a decrease to a speed
      -- above zero and below the ceiling speed at the train front
      Max_Restrictions : constant := 3;

      Seg_Start    : Natural := 0;
      Seg_Speed    : Natural := Ceiling_Speed; -- what the diagram shows
      Prev_Speed   : Natural := Ceiling_Speed; -- what the profile says
      Restrictions : Natural := 0;
      Increased    : Boolean := False;
   begin
      -- 8.3.7.10: PASP background over D7-D8
      Fill_Rect (D7_X, Top_Y, D7_W + 6, Bottom_Y - Top_Y + 1,
                 General_Parameters.PASP_DARK);

      for I in 1 .. Speed_Count + 1 loop
         declare
            -- the last segment ends with the movement authority, or
            -- where a cut speed profile stops being known (Speed_End_M)
            Seg_End : constant Natural :=
              (if I <= Speed_Count
               then Natural'Min (Speeds (I).Dist_M, MA_Dist_M)
               else Natural'Min (Speed_End_M, MA_Dist_M));
            W : constant Natural := Width_Of (Seg_Speed);
         begin
            if Seg_End > Seg_Start and then W > 0 then
               declare
                  Y_High : constant Integer := Y_Of (Seg_End);
                  Y_Low  : constant Integer := Y_Of (Seg_Start);
               begin
                  Fill_Rect (D7_X, Y_High, W, Natural'Max (0, Y_Low - Y_High + 1),
                             General_Parameters.PASP_LIGHT);
               end;
            end if;
            exit when I > Speed_Count or else Seg_End >= MA_Dist_M;
            if Speeds (I).Speed = 0 then
               -- 8.3.7.6, 8.3.7.9: the first target at zero speed is
               -- always shown; the PASP ends there (8.3.7.2)
               Seg_Speed := 0;
            elsif Speeds (I).Speed > Prev_Speed then
               -- 8.3.7.9: after an increase (PL21, 8.3.6.4) only the zero
               -- speed target may still shorten the diagram. The increase
               -- itself does not widen it: 8.3.7.7 changes the width for
               -- decreases only, and both examples of Figure 80 keep the
               -- width through the increases.
               Increased := True;
            elsif Speeds (I).Speed < Prev_Speed
              and then Speeds (I).Speed < Ceiling_Speed
              and then not Increased
              and then Restrictions < Max_Restrictions
            then
               -- 8.3.7.5: up to 3 restrictive discontinuities, 8.3.7.7
               Restrictions := Restrictions + 1;
               Seg_Speed := Speeds (I).Speed;
            end if;
            -- Implementation choice: a decrease that 8.3.7.5 or 8.3.7.9
            -- leaves out changes nothing, the diagram keeps its width up
            -- to the zero speed target or the end of the movement
            -- authority (8.3.7.2). Every discontinuity counts towards
            -- the three of 8.3.7.5, also one that stays in the same
            -- quarter as the one before it (the clause counts
            -- discontinuities, not widths). 8.3.6 still shows every
            -- discontinuity with its symbol and speed.
            Prev_Speed := Speeds (I).Speed;
            Seg_Start := Seg_End;
            exit when Seg_Speed = 0;
         end;
      end loop;
   end Draw_PASP;

   ---------------------------------------------------------------------
   -- Distance scale (8.3.3)
   ---------------------------------------------------------------------

   procedure Draw_Scale is
      R : constant Natural := Range_Max (Current_Range);
      type Line_T is record
         Y     : Natural;
         Wide  : Boolean;
         Label : Natural; -- 0 = unlabelled (except the zero line)
      end record;
      Lines : constant array (1 .. 9) of Line_T :=
        ((283, True,  0), (250, False, 0), (206, False, 0),
         (182, False, 0), (164, False, 0), (150, True,  R / 8),
         (107, False, R / 4), (64, False, R / 2), (21, True, R));
   begin
      for I in Lines'Range loop
         declare
            L     : Line_T renames Lines (I);
            Color : constant General_Parameters.Color :=
              (if L.Wide then General_Parameters.MEDIUM_GREY
               else General_Parameters.DARK_GREY);
         begin
            Fill_Rect (D2_X, L.Y, 200, (if L.Wide then 2 else 1), Color);
            -- 8.3.3.6: numbers medium grey, right aligned in D1,
            -- vertically centred on the line (labels on lines 1,6,7,8,9)
            if L.Wide or else L.Label > 0 then
               declare
                  Img : constant Wide_String := Natural'Wide_Image (L.Label);
               begin
                  D_Buffer.Draw_String
                    (Pen_X => 38,
                     Pen_Y => L.Y + 5,
                     The_String => Img (2 .. Img'Last),
                     The_Size => 10,
                     The_Color => General_Parameters.MEDIUM_GREY,
                     The_Alignment => D_Buffer.Right);
               end;
            end if;
         end;
      end loop;
   end Draw_Scale;

   ---------------------------------------------------------------------
   -- Markers (8.3.8, 8.5.11)
   ---------------------------------------------------------------------

   procedure Draw_Advice_Marker is
      Y : constant Integer := Y_Of (Advice_Dist_M);
   begin
      -- 8.5.11.3: five 10 cell grey dashes separated by 10 cells
      if Y - 1 >= Top_Y then
         for Dash in 0 .. 4 loop
            Fill_Rect (D7_X + Dash * 20, Y - 1, 10, 2,
                       General_Parameters.GREY);
         end loop;
      end if;
   end Draw_Advice_Marker;

   procedure Draw_Indication_Marker is
      use type SDI.Mode_T;
      Y : constant Integer := Y_Of (Indication_Dist_M);
      Color : constant General_Parameters.Color :=
        (if SDI.Mode = SDI.M_AD then General_Parameters.WHITE
         else General_Parameters.YELLOW); -- 8.3.8.2/.2.1
   begin
      if Y - 1 >= Top_Y then
         Fill_Rect (D7_X, Y - 1, D7_W, 2, Color);
      end if;
   end Draw_Indication_Marker;

   ---------------------------------------------------------------------
   -- Orders and announcements (8.3.4)
   ---------------------------------------------------------------------

   function PL_Symbol (Kind : Natural) return Symbol.T is
     (case Kind is
         when 1  => Symbol.PL_01, when 2  => Symbol.PL_02,
         when 3  => Symbol.PL_03, when 4  => Symbol.PL_04,
         when 5  => Symbol.PL_05, when 6  => Symbol.PL_06,
         when 7  => Symbol.PL_07, when 8  => Symbol.PL_08,
         when 9  => Symbol.PL_09, when 10 => Symbol.PL_10,
         when 11 => Symbol.PL_11, when 12 => Symbol.PL_12,
         when 13 => Symbol.PL_13, when 14 => Symbol.PL_14,
         when 15 => Symbol.PL_15, when 16 => Symbol.PL_16,
         when 17 => Symbol.PL_17, when 18 => Symbol.PL_18,
         when 19 => Symbol.PL_19, when 20 => Symbol.PL_20,
         when 21 => Symbol.PL_21, when 22 => Symbol.PL_22,
         when 23 => Symbol.PL_23, when 24 => Symbol.PL_24,
         when 25 => Symbol.PL_25, when 26 => Symbol.PL_26,
         when 27 => Symbol.PL_27, when 28 => Symbol.PL_28,
         when 29 => Symbol.PL_29, when 30 => Symbol.PL_30,
         when 31 => Symbol.PL_31, when 32 => Symbol.PL_32,
         when 33 => Symbol.PL_33, when 34 => Symbol.PL_34,
         when 35 => Symbol.PL_35, when 36 => Symbol.PL_36,
         when others => Symbol.PL_37);

   procedure Draw_Orders is
      -- 8.3.4.23: adjacent symbols in different columns; 8.3.4.24: the
      -- closest symbol on top. Orders are drawn farthest first, columns
      -- assigned round robin in distance order.
      Sorted : Order_List_T := Orders;
      Count  : constant Natural := Order_Count;
      Limit  : constant Natural := Display_Limit_M;
   begin
      -- insertion sort by ascending distance
      for I in 2 .. Count loop
         declare
            Tmp : constant Order_T := Sorted (I);
            J   : Natural := I;
         begin
            while J > 1 and then Sorted (J - 1).Dist_M > Tmp.Dist_M loop
               Sorted (J) := Sorted (J - 1);
               J := J - 1;
            end loop;
            Sorted (J) := Tmp;
         end;
      end loop;

      for I in reverse 1 .. Count loop
         declare
            Column : constant Natural := (I - 1) mod 3; -- D2/D3/D4
            Sym    : constant Symbol.T := PL_Symbol (Sorted (I).Symbol_Kind);
            Y      : constant Integer := Y_Of (Sorted (I).Dist_M);
            X      : constant Natural :=
              D2_X + Column * 25 + (25 - Sym.Width) / 2;
         begin
            -- 8.3.4.2: only within the movement authority and up to the
            -- first target at zero speed. The orders left out are the
            -- farthest ones, so the columns of the others do not move.
            -- 8.3.4.22: bottom of the symbol at the announcement distance
            if Sorted (I).Dist_M <= Limit
              and then Y - Sym.Height + 1 >= Top_Y and then Y <= Bottom_Y
            then
               D_Buffer.Draw_Symbol (Sym, (X, Y - Sym.Height + 1));
            end if;
         end;
      end loop;
   end Draw_Orders;

   ---------------------------------------------------------------------
   -- Gradient profile (8.3.5)
   ---------------------------------------------------------------------

   procedure Draw_Sign (X, Y : Natural; Positive_Sign : Boolean;
                        Color : General_Parameters.Color) is
   begin
      -- 5x5 cell +/- drawn directly (FreeSans_10 has digits only)
      Fill_Rect (X - 2, Y, 5, 1, Color);
      if Positive_Sign then
         Fill_Rect (X, Y - 2, 1, 5, Color);
      end if;
   end Draw_Sign;

   procedure Draw_Gradient is
      Limit : constant Natural := Display_Limit_M; -- 8.3.5.2
   begin
      for I in 1 .. Gradient_Count loop
         declare
            -- 8.3.5.5: the length of the rectangle is the length of
            -- the element. The last one ends with the movement authority
            -- or the first target at zero speed (8.3.5.2), or where a cut
            -- profile stops being known (Gradient_End_M): it is not
            -- stretched over elements that were left out.
            Seg_End : constant Natural :=
              (if I < Gradient_Count
               then Natural'Min (Gradients (I + 1).Start_M, Limit)
               else Natural'Min (Gradient_End_M, Limit));
            Value    : constant Integer := Gradients (I).Value;
            Downhill : constant Boolean := Value < 0;
            Y_High   : constant Integer :=
              Integer'Max (Top_Y, Y_Of (Seg_End));
            Y_Low    : constant Integer := Y_Of (Gradients (I).Start_M);
            Height   : constant Integer := Y_Low - Y_High + 1;
            Body_Col : constant General_Parameters.Color :=
              (if Downhill then General_Parameters.DARK_GREY
               else General_Parameters.GREY);
            Char_Col : constant General_Parameters.Color :=
              (if Downhill then General_Parameters.WHITE
               else General_Parameters.BLACK);
            Line_Col : constant General_Parameters.Color :=
              (if Downhill then General_Parameters.GREY
               else General_Parameters.WHITE);
            Center_X : constant Natural := D5_X + 9;
         begin
            exit when Gradients (I).Start_M >= Limit;
            if Height > 2 then
               -- 8.3.5.8: body
               Fill_Rect (D5_X, Y_High, 18, Height, Body_Col);
               -- 8.3.5.9/.10: 1 cell top and left line
               Fill_Rect (D5_X, Y_High, 18, 1, Line_Col);
               Fill_Rect (D5_X, Y_High, 1, Height, Line_Col);
               -- 8.3.5.11: 1 cell black bottom line
               Fill_Rect (D5_X, Y_Low, 18, 1, General_Parameters.BLACK);

               -- 8.3.5.6: signs top and bottom when tall enough: '+' for
               -- an uphill and '-' for a downhill gradient. The clause
               -- gives a zero gradient no sign, so it gets none.
               if Height >= 16 and then Value /= 0 then
                  Draw_Sign (Center_X, Y_High + 4, Value > 0, Char_Col);
                  Draw_Sign (Center_X, Y_Low - 4, Value > 0, Char_Col);
               end if;
               -- 8.3.5.7: value in the middle when tall enough.
               -- Implementation choice: a zero gradient shows its "0"
               -- under the same condition (8.3.5.8 speaks of "sign and/or
               -- number" in black for uphill and zero gradients; 8.3.5.7
               -- itself only covers a number next to a sign).
               if Height >= 30 then
                  declare
                     Img : constant Wide_String :=
                       Natural'Wide_Image (abs Value);
                  begin
                     D_Buffer.Draw_String
                       (Pen_X => Center_X,
                        Pen_Y => (Y_High + Y_Low) / 2 + 5,
                        The_String => Img (2 .. Img'Last),
                        The_Size => 10,
                        The_Color => Char_Col,
                        The_Alignment => D_Buffer.Center);
                  end;
               end if;
            end if;
         end;
      end loop;
   end Draw_Gradient;

   ---------------------------------------------------------------------
   -- Speed profile discontinuities (8.3.6)
   ---------------------------------------------------------------------

   procedure Draw_Speed_Discontinuities is
      use type SDI.Mode_T;

      procedure Draw_One (Disc : Speed_Disc_T; Previous_Speed : Natural) is
         Increase : constant Boolean := Disc.Speed > Previous_Speed;
         In_AD    : constant Boolean := SDI.Mode = SDI.M_AD;
         Sym : constant Symbol.T :=
           (if Increase then Symbol.PL_21
            elsif Disc.Is_Ind_Target and then Indication_Valid then
              (if In_AD then Symbol.PL_37 else Symbol.PL_23)
            else Symbol.PL_22);
         Y : constant Integer := Y_Of (Disc.Dist_M);
         -- 8.3.6.5: symbol centred on the D6/D7 boundary, the bottom of its
         -- horizontal line at the discontinuity location. The line is at
         -- the bottom of PL21 (rows 16 and 17 of 20) and at the top of
         -- PL22, PL23 and PL37 (rows 2 and 3).
         Line_Row : constant Integer := (if Increase then 17 else 3);
         Sym_Y    : constant Integer := Y - Line_Row;
         X : constant Integer := D7_X - Sym.Width / 2;
         Number_Color : constant General_Parameters.Color :=
           (if Disc.Is_Ind_Target and then Indication_Valid then
              (if In_AD then General_Parameters.WHITE
               else General_Parameters.YELLOW)
            else General_Parameters.GREY);
         Img : constant Wide_String := Natural'Wide_Image (Disc.Speed);
      begin
         if Sym_Y < Top_Y or else Y > Bottom_Y then
            return;
         end if;
         D_Buffer.Draw_Symbol (Sym, (X, Sym_Y));
         -- 8.3.6.7/.8: numbers left aligned in D7, 11 cell indent
         D_Buffer.Draw_String
           (Pen_X => D7_X + 11,
            Pen_Y => (if Increase then Y else Y + 10),
            The_String => Img (2 .. Img'Last),
            The_Size => 10,
            The_Color => Number_Color);
      end Draw_One;

      Limit : constant Natural := Display_Limit_M; -- 8.3.6.2

   begin
      -- 8.3.6.9: PL21 under PL22 under PL23: draw increases first, then
      -- plain decreases, then the indication target
      for Pass in 1 .. 3 loop
         declare
            Prev : Natural := Ceiling_Speed;
         begin
            for I in 1 .. Speed_Count loop
               declare
                  Disc     : Speed_Disc_T renames Speeds (I);
                  Increase : constant Boolean := Disc.Speed > Prev;
                  Is_Ind   : constant Boolean :=
                    Disc.Is_Ind_Target and then Indication_Valid;
               begin
                  exit when Disc.Dist_M > Limit;
                  if (Pass = 1 and then Increase)
                    or else (Pass = 2 and then not Increase and then not Is_Ind)
                    or else (Pass = 3 and then not Increase and then Is_Ind)
                  then
                     Draw_One (Disc, Prev);
                  end if;
                  Prev := Disc.Speed;
               end;
            end loop;
         end;
      end loop;
   end Draw_Speed_Discontinuities;

   ---------------------------------------------------------------------
   -- Zoom buttons (8.3.10)
   ---------------------------------------------------------------------

   procedure Draw_Zoom_Buttons is
      D9_Area  : constant Area_T := Get_Sub_Area_With_Relative_Position (D9);
      D12_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (D12);

      procedure Draw_Button (The_Area : Area_T;
                             Enabled  : Boolean;
                             Enabled_Symbol, Disabled_Symbol : Symbol.T) is
         Sym : constant Symbol.T :=
           (if Enabled then Enabled_Symbol else Disabled_Symbol);
      begin
         D_Buffer.Draw_Symbol
           (Sym, The_Area.Position + ((The_Area.Width - Sym.Width) / 2,
                                      (The_Area.Height - Sym.Height) / 2));
      end Draw_Button;
   begin
      Draw_Button (D9_Area, Can_Zoom_In, Symbol.NA_03, Symbol.NA_05);
      Draw_Button (D12_Area, Can_Zoom_Out, Symbol.NA_04, Symbol.NA_06);
   end Draw_Zoom_Buttons;

   ------------
   -- Render --
   ------------

   procedure Render is
   begin
      -- 8.3.2.1 / 8.5.11.5 layering, back to front
      Draw_PASP;
      Draw_Scale;
      if Advice_Valid then
         Draw_Advice_Marker;
      end if;
      if Indication_Valid then
         Draw_Indication_Marker;
      end if;
      Draw_Orders;
      Draw_Gradient;
      Draw_Speed_Discontinuities;
      Draw_Zoom_Buttons;
   end Render;

   ---------------------------------------------------------------------
   -- Update interface
   ---------------------------------------------------------------------

   -- a cut profile takes no further elements
   Gradients_Cut : Boolean := False;
   Speeds_Cut    : Boolean := False;

   procedure Begin_Update is
   begin
      Gradient_Count := 0;
      Speed_Count := 0;
      Order_Count := 0;
      Gradient_End_M := Distance_T'Last;
      Speed_End_M := Distance_T'Last;
      Orders_Left_Out := 0;
      Gradients_Cut := False;
      Speeds_Cut := False;
   end Begin_Update;

   procedure Add_Gradient (Start_M : Natural; Value : Integer) is
      Previous : constant Distance_T :=
        (if Gradient_Count = 0 then 0
         else Gradients (Gradient_Count).Start_M);
   begin
      if Gradients_Cut then
         return;
      end if;
      if Start_M < Previous then
         Gradients_Cut := True;
         Gradient_End_M := Previous;
      elsif Gradient_Count = Max_Gradients
        or else Start_M > Max_Range_M
        or else Value not in Gradient_Value_T
      then
         Gradients_Cut := True;
         Gradient_End_M := Natural'Min (Start_M, Distance_T'Last);
      else
         Gradient_Count := Gradient_Count + 1;
         Gradients (Gradient_Count) := (Start_M => Start_M, Value => Value);
      end if;
   end Add_Gradient;

   procedure Add_Speed (Dist_M, Speed : Natural; Is_Ind_Target : Boolean) is
      Previous : constant Distance_T :=
        (if Speed_Count = 0 then 0 else Speeds (Speed_Count).Dist_M);
   begin
      if Speeds_Cut then
         return;
      end if;
      if Dist_M < Previous then
         Speeds_Cut := True;
         Speed_End_M := Previous;
      elsif Speed_Count = Max_Speeds
        or else Dist_M > Max_Range_M
        or else Speed > Max_Speed_Kmh
      then
         Speeds_Cut := True;
         Speed_End_M := Natural'Min (Dist_M, Distance_T'Last);
      else
         Speed_Count := Speed_Count + 1;
         Speeds (Speed_Count) := (Dist_M        => Dist_M,
                                  Speed         => Speed,
                                  Is_Ind_Target => Is_Ind_Target);
      end if;
   end Add_Speed;

   procedure Add_Order (Symbol_Kind, Dist_M : Natural) is
      Farthest : Positive := 1;
   begin
      -- the count only moves together with a filled slot, so a left out
      -- element can never show the stale content of its slot
      if not Is_Order_Symbol (Symbol_Kind) or else Dist_M > Max_Range_M then
         return;
      end if;
      if Order_Count < Max_Orders then
         Order_Count := Order_Count + 1;
         Orders (Order_Count) := (Symbol_Kind => Symbol_Kind,
                                  Dist_M      => Dist_M);
         return;
      end if;
      Orders_Left_Out := Orders_Left_Out + 1;
      for I in 2 .. Max_Orders loop
         if Orders (I).Dist_M > Orders (Farthest).Dist_M then
            Farthest := I;
         end if;
      end loop;
      if Dist_M < Orders (Farthest).Dist_M then
         Orders (Farthest) := (Symbol_Kind => Symbol_Kind,
                               Dist_M      => Dist_M);
      end if;
   end Add_Order;

   procedure Reset is
   begin
      Valid := False;
      MA_Dist_M := 0;
      Indication_Valid := False;
      Advice_Valid := False;
      Ceiling_Speed := 0;
      Gradient_Count := 0;
      Speed_Count := 0;
      Order_Count := 0;
      Gradient_End_M := Distance_T'Last;
      Speed_End_M := Distance_T'Last;
      Orders_Left_Out := 0;
      Gradients_Cut := False;
      Speeds_Cut := False;
      Current_Range := 3;
   end Reset;

end DMI_Planning;
