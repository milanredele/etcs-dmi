--  ETCS DMI
--  Body of DMI_Test_Planning (see dmi_test_planning.ads).

with DMI_ATO;
with DMI_Planning;
with DMI_Test_Support;
with Display.Screen;
with General_Parameters;
with Test_Support;
use Test_Support;
use DMI_Test_Support;

package body DMI_Test_Planning is

   procedure Scenario_Planning is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4); -- FS
      Send_Speed_State (V_Cur => 100, V_Perm => 140, V_Target => 0,
                        V_Release => 0, V_Sbi => 155, V_Wsl => 145,
                        D_Target => 2500, Monitoring => 0, Dial_Range => 2,
                        Vrelease_Exists => False);
      -- MA 2.5 km, indication at 1.2 km, gradients, two speed drops and
      -- a zero speed target, pantograph + neutral section announcements
      Send_Planning
        (MA_Dist    => 2500,
         Ceiling    => 140,
         Indication => 1200,
         Gradients  => (0, 12, 800, -5, 1800, 0),
         Speeds     => (1000, 70, 0,  1700, 40, 0,  2500, 0, 1),
         Orders     => (2, 600,  5, 1500));
      Drain_Sounds;
      Step;
      Check_Frame ("planning_fs");

      -- zoom out to 0-8000 and back in twice to 0-2000
      Pointer_Down (350, 20); Pointer_Up (350, 20);   -- D12 scale down
      Drain_Sounds;
      Step;
      Check_Frame ("planning_8000");
      Pointer_Down (350, 300); Pointer_Up (350, 300); -- D9 scale up
      Pointer_Down (350, 300); Pointer_Up (350, 300);
      Drain_Sounds;
      Step;
      Check_Frame ("planning_2000");

      -- AD mode: indication marker and PL37 in white
      Send_Mode_Level (Mode => 3, Level => 4);
      Drain_Sounds;
      Step;
      Check_Frame ("planning_ad");

      -- OS mode: hidden until toggled on (8.3.1.1 c)
      Send_Mode_Level (Mode => 6, Level => 4);
      Drain_Sounds;
      Step;
      Check_Frame ("planning_os_off");
      Pointer_Down (150, 150); Pointer_Up (150, 150); -- A/B toggle
      Drain_Sounds;
      Step;
      Check_Frame ("planning_os_on");
   end Scenario_Planning;

   ---------------------------------------------------------------------
   -- Windows and the start-up dialogue sequence (10, 11.7.2)
   ---------------------------------------------------------------------

   procedure Scenario_Planning_Zoom_Areas is
      use type DMI_Planning.Range_Index_T;

      procedure Tap (X, Y : Natural) is
      begin
         Pointer_Down (X, Y); Pointer_Up (X, Y);
         Step;
         Drain_Sounds;
      end Tap;
   begin
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 2500, Ceiling => 140,
                     Gradients => (0, 12),
                     Speeds => (1 => 2500, 2 => 0, 3 => 0));
      Drain_Sounds;
      Step;
      Check (DMI_Planning.Current_Range = 3, "zoom areas: starts at 0-4000");

      Tap (350, 320); -- 5 cells below area D: was sensitive before PLN-1
      Tap (350, 315);
      Check (DMI_Planning.Current_Range = 3,
             "8.3.10.4: nothing below D9 is sensitive");
      Tap (350, 284); -- 16 cells above D9
      Tap (374, 290); -- right of the 40 cell width
      Check (DMI_Planning.Current_Range = 3,
             "8.3.10.4: the sensitive area of D9 is 40x30");
      Tap (350, 285); -- 15 cells above D9: the first sensitive row
      Check (DMI_Planning.Current_Range = 2,
             "8.3.10.4: 15 cells above D9 are sensitive");
      Tap (373, 314); -- last cell of D9 itself
      Check (DMI_Planning.Current_Range = 1, "8.3.10.4: D9 is sensitive");
      Step;
      Check_Frame ("planning_zoom_1000");

      Tap (350, 45);  -- 16 cells below D12
      Tap (374, 40);
      Check (DMI_Planning.Current_Range = 1,
             "8.3.10.5: the sensitive area of D12 is 40x30");
      Tap (373, 44);  -- 15 cells below D12: the last sensitive row
      Check (DMI_Planning.Current_Range = 2,
             "8.3.10.5: 15 cells below D12 are sensitive");
      Tap (334, 15);  -- first cell of D12 itself
      Check (DMI_Planning.Current_Range = 3, "8.3.10.5: D12 is sensitive");
   end Scenario_Planning_Zoom_Areas;

   -- PLN-2: 8.3.5.6 gives '+' to an uphill and '-' to a downhill
   -- gradient; a zero gradient has no sign, only its number.
   procedure Scenario_Planning_Zero_Gradient is
   begin
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 4000, Ceiling => 140,
                     Gradients => (0, 0,  500, 5,  1000, 0,  1200, -5,
                                   2000, 0),
                     Speeds => (1 => 4000, 2 => 0, 3 => 0));
      Drain_Sounds;
      Step;
      Check_Frame ("planning_zero_gradient");
   end Scenario_Planning_Zero_Gradient;

   -- PLN-3: 8.3.7.5 to 8.3.7.9 with both examples of Figure 80.
   procedure Scenario_Planning_PASP is
   begin
      -- 140/130/120/110/60 and the zero speed target: 130, 120 and 110 share
      -- the 3/4 quarter, 60 (42 %) takes the 1/4 one, the zero speed target
      -- ends the PASP. 8.3.7.5 and 8.3.7.6 follow from the quarters of
      -- 8.3.7.7, nothing is counted.
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 3000, Ceiling => 140,
                     Speeds => (500, 130, 0,  1000, 120, 0,  1500, 110, 0,
                                2000, 60, 0,  3000, 0, 0));
      Drain_Sounds;
      Step;
      Check_Frame ("planning_pasp_three");

      -- the three widths of 8.3.7.7/.8, and a PASP that ends with a
      -- movement authority which has no zero speed target
      Send_Planning (MA_Dist => 3000, Ceiling => 140,
                     Speeds => (500, 105, 0,  1000, 70, 0,  1500, 40, 0,
                                2000, 20, 0));
      Step;
      Check_Frame ("planning_pasp_quarters");

      -- Figure 80 left: 160, then 120, 80, 60, 40 and an increase to 140
      -- which does not widen the diagram
      Planning_Reset (V_Perm => 160);
      Send_Planning (MA_Dist => 4000, Ceiling => 160,
                     Speeds => (300, 120, 0,  800, 80, 0,  1400, 60, 0,
                                1900, 40, 0,  2600, 140, 0));
      Drain_Sounds;
      Step;
      Check_Frame ("planning_pasp_fig80_left");

      -- Figure 80 right: 160, the indication target 80, increases to 120
      -- and 140, then the zero speed target
      Send_Planning (MA_Dist => 3200, Ceiling => 160, Indication => 400,
                     Speeds => (900, 80, 1,  1800, 120, 0,  2400, 140, 0,
                                3200, 0, 0));
      Step;
      Check_Frame ("planning_pasp_fig80_right");

      -- 8.3.7.9: after an increase a further decrease is not shown, the
      -- zero speed target is
      Send_Planning (MA_Dist => 3200, Ceiling => 160,
                     Speeds => (500, 100, 0,  1000, 140, 0,  1600, 30, 0,
                                2400, 0, 0));
      Step;
      Check_Frame ("planning_pasp_after_increase");
   end Scenario_Planning_PASP;

   -- PLN-4: 8.3.4.2 (and 8.3.5.2, 8.3.6.2, 8.3.7.2): within the movement
   -- authority and up to the first target at zero speed.
   procedure Scenario_Planning_Order_Limit is
   begin
      -- no zero speed target (LOA): the end of the movement authority
      -- limits; the order at 2000 m is shown, the one at 2600 m is not
      Planning_Reset (V_Perm => 140);
      Send_Planning (MA_Dist => 2000, Ceiling => 140,
                     Gradients => (0, 3),
                     Speeds => (1 => 2000, 2 => 80, 3 => 0),
                     Orders => (2, 600,  5, 2000,  9, 2600,  7, 3500));
      Drain_Sounds;
      Step;
      Check (DMI_Planning.Order_Count = 4,
             "order limit: the orders beyond the MA are valid and stored");
      Check_Frame ("planning_orders_ma_limit");

      -- a zero speed target before the end of the movement authority
      -- limits orders, gradient profile and discontinuities alike
      Send_Planning (MA_Dist => 3000, Ceiling => 140,
                     Gradients => (0, 3,  1000, -4,  2000, 6),
                     Speeds => (800, 70, 0,  1500, 0, 0,  2200, 100, 0),
                     Orders => (2, 600,  5, 1500,  9, 1800,  7, 2600));
      Step;
      Check_Frame ("planning_zero_target_limit");
   end Scenario_Planning_Order_Limit;
   ---------------------------------------------------------------------
   -- Acknowledgements against the Start Up sequence and open data entry
   -- / validation windows (audit WIN-3: 5.4.1.11, 11.7.1.8, 11.7.1.9,
   -- 11.2.1.4) and the delay-type acknowledgement of MO10 (audit SDI-3:
   -- 8.2.3.1.4)
   ---------------------------------------------------------------------

   function Pixel_Is (X, Y : Natural; C : General_Parameters.Color)
                      return Boolean is
      use type General_Parameters.Color;
   begin
      return Display.Screen.Get_Pixel (X, Y) = C;
   end Pixel_Is;

   PF_Grey   : General_Parameters.Color renames General_Parameters.GREY;
   PF_Black  : General_Parameters.Color renames General_Parameters.BLACK;
   PF_Shadow : General_Parameters.Color renames General_Parameters.SHADOW;
   PF_Medium : General_Parameters.Color renames
     General_Parameters.MEDIUM_GREY;
   PF_Dark   : General_Parameters.Color renames General_Parameters.DARK_GREY;
   PF_Back   : General_Parameters.Color renames
     General_Parameters.Background_Color;

   --  8.2.2.1: FS, TSM, the distance to target D (Table 13: bar shown)
   procedure PF_Show_Distance (D : Natural) is
   begin
      Send_Speed_State (V_Cur => 60, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => D, Monitoring => 1, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
   end PF_Show_Distance;

   procedure Scenario_PF_Distance_Bar is
      --  A3 is at (0, 99) of the screen (A at (0,15), A3 at (0,84) in A)
      A3_Y  : constant := 99;
      Bar_X : constant := 33;               -- a column of the bar 29-38

      type Line_T is record
         Metres : Natural;
         X      : Natural;
         Y      : Integer;
         Long   : Boolean;
      end record;
      --  8.2.2.1.4 Table 12
      Table_12 : constant array (1 .. 11) of Line_T :=
        ((1000, 12, -1, True), (900, 16, 6, False), (800, 16, 13, False),
         (700, 16, 22, False), (600, 16, 32, False), (500, 12, 45, True),
         (400, 16, 59, False), (300, 16, 79, False), (200, 16, 105, False),
         (100, 16, 152, False), (0, 12, 185, True));

      function Line_OK (L : Line_T) return Boolean is
         Length : constant Natural := (if L.Long then 13 else 9);
         Width  : constant Natural := (if L.Long then 2 else 1);
         Top    : constant Natural := A3_Y + L.Y;
      begin
         for Row in Top .. Top + Width - 1 loop
            for X in L.X .. L.X + Length - 1 loop
               if not Pixel_Is (X, Row, PF_Grey) then
                  return False;
               end if;
            end loop;
            if Pixel_Is (L.X - 1, Row, PF_Grey)
              or else Pixel_Is (L.X + Length, Row, PF_Grey)
            then
               return False;
            end if;
         end loop;
         return not Pixel_Is (L.X + 1, Top - 1, PF_Grey)
           and then not Pixel_Is (L.X + 1, Top + Width, PF_Grey);
      end Line_OK;

      --  8.2.2.1.6: the bar stands on the bottom edge of row 185 of A3,
      --  its top row is Top (of A3), columns 29-38
      function Bar_Top_Is (Top : Natural) return Boolean is
        (Pixel_Is (Bar_X, A3_Y + Top, PF_Grey)
         and then not Pixel_Is (Bar_X, A3_Y + Top - 1, PF_Grey)
         and then Pixel_Is (Bar_X, A3_Y + 185, PF_Grey)
         and then not Pixel_Is (Bar_X, A3_Y + 186, PF_Grey)
         and then Pixel_Is (29, A3_Y + 185, PF_Grey)
         and then Pixel_Is (38, A3_Y + 185, PF_Grey)
         and then not Pixel_Is (28, A3_Y + 185, PF_Grey)
         and then not Pixel_Is (39, A3_Y + 185, PF_Grey));
   begin
      Lang_English;
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      PF_Show_Distance (0);
      for L of Table_12 loop
         Check (Line_OK (L),
                "pf: Table 12 line of" & Natural'Image (L.Metres)
                & " m at its cells");
      end loop;
      Check (not Pixel_Is (Bar_X, A3_Y + 185, PF_Grey),
             "pf: 0 m shows no bar");
      Check_Frame ("pf_a3_0");

      --  at each distance of Table 12 the bar reaches the row below the
      --  top row of its indicator line
      for L of Table_12 loop
         if L.Metres > 0 then
            PF_Show_Distance (L.Metres);
            Check (Bar_Top_Is (L.Y + 1),
                   "pf: the bar for" & Natural'Image (L.Metres)
                   & " m ends below row" & Integer'Image (L.Y));
         end if;
      end loop;

      PF_Show_Distance (10);                 -- linear: 3.3 cells, 4 shown
      Check (Bar_Top_Is (182), "pf: 10 m is a bar of 4 cells");
      Check_Frame ("pf_a3_10");
      PF_Show_Distance (100);
      Check (Bar_Top_Is (153), "pf: 100 m is a bar of 33 cells");
      Check_Frame ("pf_a3_100");
      --  262 m is at 87.9999 on the logarithmic scale: 98 cells
      PF_Show_Distance (262);
      Check (Bar_Top_Is (88), "pf: 262 m is a bar of 98 cells");
      Check_Frame ("pf_a3_262");
      PF_Show_Distance (1000);
      Check (Bar_Top_Is (0), "pf: 1000 m is a bar of 186 cells");
      Check_Frame ("pf_a3_1000");
      PF_Show_Distance (5000);               -- 8.2.2.1.6: shows 1000 m
      Check (Bar_Top_Is (0), "pf: 5000 m shows as 1000 m");
      Check_Frame ("pf_a3_5000");
      Reset;
   end Scenario_PF_Distance_Bar;

   --  8.2.3.3: the question box at (335, 65) .. (578, 114), each part
   --  with its own medium grey input field border (8.2.3.3.14)
   procedure Scenario_PF_TAF is
      Row : constant := 90;
   begin
      Lang_English;
      Reset;
      Send_Mode_Level (Mode => 2, Level => 5, TAF => True);
      Step;
      Check (Pixel_Is (334, Row, PF_Black)
             and then Pixel_Is (579, Row, PF_Shadow),
             "pf: TAF keeps the border of D");
      Check (Pixel_Is (335, Row, PF_Medium)
             and then Pixel_Is (336, Row, PF_Dark)
             and then Pixel_Is (495, Row, PF_Dark)
             and then Pixel_Is (496, Row, PF_Medium),
             "pf: the question part 335-496 has its own border");
      Check (Pixel_Is (497, Row, PF_Medium)
             and then Pixel_Is (578, Row, PF_Medium)
             and then Pixel_Is (400, 65, PF_Medium)
             and then Pixel_Is (400, 114, PF_Medium)
             and then Pixel_Is (400, 64, PF_Back)
             and then Pixel_Is (400, 115, PF_Back),
             "pf: the question box is 244x50 at (335, 65)");
      Check_Frame ("pf_taf");
      --  5.3.2.5.3: pressed, 'Yes' is dark grey inside its border
      Pointer_Down (537, Row);
      Step;
      Check (Pixel_Is (497, Row, PF_Medium)
             and then Pixel_Is (498, Row, PF_Dark)
             and then Pixel_Is (577, Row, PF_Dark)
             and then Pixel_Is (578, Row, PF_Medium)
             and then Pixel_Is (520, 65, PF_Medium)
             and then Pixel_Is (520, 114, PF_Medium),
             "pf: the pressed 'Yes' shows its own border");
      Check_Frame ("pf_taf_pressed");
      Pointer_Up (537, Row);
      Step;
      Drain_Sounds;
      Drain_Outbox;
      Reset;
   end Scenario_PF_TAF;

   --  5.3.2.5.5 a: a disabled E10/E11 is an enabled button with NA15 /
   --  NA16, so it keeps the lifted border, touched or not; the corners of
   --  the border as Figure 60 draws them
   procedure Scenario_PF_Scroll_Disabled is
      function Lifted (X0, Y0 : Natural) return Boolean is
        (Pixel_Is (X0, Y0, PF_Black)
         and then Pixel_Is (X0 + 1, Y0, PF_Black)
         and then Pixel_Is (X0 + 44, Y0, PF_Black)
         and then Pixel_Is (X0 + 45, Y0, PF_Shadow)
         and then Pixel_Is (X0 + 1, Y0 + 1, PF_Shadow)
         and then Pixel_Is (X0 + 43, Y0 + 1, PF_Shadow)
         and then Pixel_Is (X0 + 44, Y0 + 1, PF_Black)
         and then Pixel_Is (X0 + 1, Y0 + 47, PF_Shadow)
         and then Pixel_Is (X0, Y0 + 48, PF_Black)
         and then Pixel_Is (X0 + 1, Y0 + 48, PF_Black)
         and then Pixel_Is (X0 + 44, Y0 + 48, PF_Black)
         and then Pixel_Is (X0, Y0 + 49, PF_Shadow)
         and then Pixel_Is (X0 + 44, Y0 + 49, PF_Shadow)
         and then Pixel_Is (X0 + 45, Y0 + 49, PF_Shadow));
   begin
      Lang_English;
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Step;
      Check (Lifted (288, 365) and then Lifted (288, 415),
             "pf: disabled E10 and E11 keep the lifted border");
      Check (Pixel_Is (311, 390, PF_Dark)
             and then Pixel_Is (311, 440, PF_Dark),
             "pf: E10 / E11 show the dark grey NA15 / NA16");
      Check_Frame ("pf_e10_e11_disabled");
      Pointer_Down (311, 390);
      Step;
      Check (Lifted (288, 365), "pf: touching a disabled E10 keeps it");
      Pointer_Up (311, 390);
      Step;
      Drain_Sounds;
      Reset;
   end Scenario_PF_Scroll_Disabled;

   --  8.1.1.4 b: G1-G5 are areas of layer -1 with their borders in every
   --  default window; without ATO (8.5.1.1) there is nothing else in them.
   --  5.1.1.1.2 with Figure 50: the shadow lines take the bottom left and
   --  top right corners of an area border.
   procedure Scenario_PF_G_Empty is
      function Bordered_Empty (X0, W : Natural) return Boolean is
      begin
         if not (Pixel_Is (X0, 315, PF_Black)
                 and then Pixel_Is (X0 + W - 2, 315, PF_Black)
                 and then Pixel_Is (X0 + W - 1, 315, PF_Shadow)
                 and then Pixel_Is (X0, 363, PF_Black)
                 and then Pixel_Is (X0, 364, PF_Shadow)
                 and then Pixel_Is (X0 + W - 1, 364, PF_Shadow))
         then
            return False;
         end if;
         for Y in 316 .. 363 loop
            for X in X0 + 1 .. X0 + W - 2 loop
               if not Pixel_Is (X, Y, PF_Back) then
                  return False;
               end if;
            end loop;
         end loop;
         return True;
      end Bordered_Empty;
   begin
      Lang_English;
      Reset;
      --  SR, and the ATO on-board reports with the selector at Stand-by:
      --  8.5.1.1 shows nothing of it
      Send_Mode_Level (Mode => 7, Level => 4);
      Send_ATO (Selector => 1, Status => 2, Skip => 1, Name => "Hbf",
                ETA_H => 12, ETA_M => 30);
      Step;
      Drain_Sounds;
      Check (not DMI_ATO.Displayed, "pf: no ATO information");
      for I in 0 .. 3 loop
         Check (Bordered_Empty (334 + 49 * I, 49),
                "pf: G" & Integer'Image (I + 1) & " bordered and empty");
      end loop;
      Check (Bordered_Empty (530, 50), "pf: G5 bordered and empty");
      Check (Pixel_Is (0, 15, PF_Black)
             and then Pixel_Is (53, 15, PF_Shadow)
             and then Pixel_Is (0, 67, PF_Black)
             and then Pixel_Is (0, 68, PF_Shadow),
             "pf: A1 border corners as in Figure 50");
      Check_Frame ("pf_g_empty");
      Reset;
   end Scenario_PF_G_Empty;


end DMI_Test_Planning;
