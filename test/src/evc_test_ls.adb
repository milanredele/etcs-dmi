with Interfaces;            use Interfaces;
with EVC_Test_Support;      use EVC_Test_Support;
with EVC_Modes;             use EVC_Modes;
with EVC_LS_Display;        use EVC_LS_Display;
with EVC_Supervision_Input; use EVC_Supervision_Input;

package body EVC_Test_LS is

   --  A snapshot: the min safe front end at 100 m, an EOA at 1000 m, the
   --  MRSP 100 km/h, 40 km/h from 500 m, 20 km/h from 1200 m (beyond the
   --  EOA), the LS mode speed limit 60 km/h, the train's 160 km/h
   S : Snapshot_T;

   procedure Prepare (LOA_Speed : Speed_Cms_T) is
   begin
      S := (others => <>);
      S.Train.Position_Valid := True;
      S.Train.Min_Safe_Front := 10_000;
      S.MA := (Present => True, EOA => 100_000, SvL => 100_000,
               LOA_Speed => LOA_Speed, Release_Speed => (others => <>));
      S.MRSP.Count := 3;
      S.MRSP.Segments (1) := (Start => 0, Speed => 2_778);
      S.MRSP.Segments (2) := (Start => 50_000, Speed => 1_111);
      S.MRSP.Segments (3) := (Start => 120_000, Speed => 556);
      S.Mode_Speed := 1_667;
      S.Train_Data.Max_Speed := 4_445;
   end Prepare;

   procedure Scenario_LS_Display is
   begin
      EVC_LS_Display.Clear;
      Prepare (LOA_Speed => 1_389);   -- an LOA at 50 km/h
      --  4.4.19.1.4 a) and b): the 40 km/h before the LOA (50 km/h), not
      --  the 20 km/h beyond it
      Check (LSSMA (S) = 1_111, "4.4.19.1.4 a: lowest MRSP element to LOA");
      Prepare (LOA_Speed => 0);
      Check (LSSMA (S) = 0, "4.4.19.1.4 b: target speed 0 at an EOA");
      Prepare (LOA_Speed => 1_389);

      --  4.4.19.1.4.7: no marker, the LOA speed below the LS limit and
      --  the LSSMA below the train's maximum: shown in LS only
      Step (S, M_FS, 1_000);
      Check (LSSMA_Kmh = No_LSSMA, "4.4.19.1.4: not shown outside LS");
      Step (S, M_LS, 1_000);
      Check (LSSMA_Kmh = 39, "4.4.19.1.4.7: shown without marker, 39 km/h");

      --  7.4.2.37.4: the marker; 4.4.19.1.4.2 b): the timer started at
      --  the balise (10 s), the time-out 5 s
      Take_Marker;
      Take_Order (On => True, Delay_S => 5, Start_Ms => 10_000,
                  Now_Ms => 11_000);
      Step (S, M_LS, 11_000);
      Check (Order_Pending and then LSSMA_Kmh = No_LSSMA,
             "4.4.19.1.4.2: pending, not shown with the marker");
      --  4.4.19.1.4.4: a new order replaces the pending one (20 s)
      Take_Order (On => True, Delay_S => 5, Start_Ms => 20_000,
                  Now_Ms => 20_000);
      Step (S, M_LS, 16_000);
      Check (LSSMA_Kmh = No_LSSMA, "4.4.19.1.4.4: the first order deleted");
      Step (S, M_LS, 25_000);
      Check (Toggled_On and then LSSMA_Kmh = 39,
             "4.4.19.1.4.3: shown when the timer reaches the time-out");

      --  4.4.19.1.4.5 a): a new toggle on order not fulfilled at once
      Take_Order (On => True, Delay_S => 3, Start_Ms => 30_000,
                  Now_Ms => 30_000);
      Step (S, M_LS, 30_000);
      Check (not Toggled_On and then LSSMA_Kmh = No_LSSMA,
             "4.4.19.1.4.5 a: toggled off by a new order");
      --  4.4.19.1.4.2 a): by radio, the timer at the time stamp, already
      --  past the time-out: shown at once
      Take_Order (On => True, Delay_S => 2, Start_Ms => 31_000,
                  Now_Ms => 34_000);
      Step (S, M_LS, 34_000);
      Check (LSSMA_Kmh = 39, "4.4.19.1.4.2 a: from the time stamp");
      --  4.4.19.1.4.5 b)
      Take_Order (On => False, Delay_S => 0, Start_Ms => 35_000,
                  Now_Ms => 35_000);
      Step (S, M_LS, 35_000);
      Check (LSSMA_Kmh = No_LSSMA, "4.4.19.1.4.5 b: toggled off");

      --  4.4.19.1.4.6: entering LS toggles off; 4.10: leaving deletes
      Take_Order (On => True, Delay_S => 0, Start_Ms => 36_000,
                  Now_Ms => 36_000);
      Step (S, M_LS, 36_000);
      Mode_Changed (M_OS, M_LS);
      Check (not Toggled_On, "4.4.19.1.4.6: toggled off entering LS");
      Take_Order (On => True, Delay_S => 9, Start_Ms => 37_000,
                  Now_Ms => 37_000);
      Mode_Changed (M_LS, M_FS);
      Check (not Order_Pending, "4.10: the order deleted leaving LS");

      --  4.4.19.1.4.8
      Delete_Marker;
      Check (not Marker_Stored, "4.4.19.1.4.8: the marker deleted");
   end Scenario_LS_Display;

end EVC_Test_LS;
