with Interfaces;            use Interfaces;
with EVC_Test_Support;      use EVC_Test_Support;
with EVC_Modes;             use EVC_Modes;
with EVC_LS_Display;        use EVC_LS_Display;
with EVC_Supervision_Input; use EVC_Supervision_Input;
with ETCS_Track_Packets.P41;
with ETCS_Track_Packets.P80;
with ETCS_Track_Packets.P180;
with ETCS_Track_Packets.P181;
with ETCS_Variables;
with EVC_Core;
with EVC_Levels;
with EVC_Test_Authority;

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

   --  Packet 41: an order to level 1 at D_M metres from the group
   function L1_Order (D_M : Natural) return ETCS_Track_Packets.P41.Packet_T
   is
      P : ETCS_Track_Packets.P41.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_LEVELTR := ETCS_Variables.D_LEVELTR_T (D_M);
      P.M_LEVELTR := ETCS_Variables.M_LEVELTR_Level_1;
      P.Has_NID_NTC := False;
      P.L_ACKLEVELTR := 0;
      P.N_ITER := 0;
      return P;
   end L1_Order;

   --  Packet 180 in the group G: toggle on (Delay_S) or off
   procedure Carry_180 (G : Positive; K : Natural; On : Boolean;
                        Delay_S : Natural)
   is
      P  : ETCS_Track_Packets.P180.Packet_T;
      W  : Writer_T;
      OK : Boolean;
   begin
      P.Q_DIR := 1;
      P.Q_LSSMA := (if On then 1 else 0);
      P.Has_T_LSSMA := On;
      P.T_LSSMA := ETCS_Variables.T_LSSMA_T (Delay_S);
      ETCS_Track_Packets.P180.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry_180;

   --  Packet 80: a Limited Supervision section from D m, 300 m long
   function LS_Profile (D : Natural := 200)
     return ETCS_Track_Packets.P80.Packet_T
   is
      P : ETCS_Track_Packets.P80.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_MAMODE := ETCS_Variables.D_MAMODE_T (D);
      P.M_MAMODE := ETCS_Variables.M_MAMODE_Limited_Supervision;
      P.V_MAMODE := 8;
      P.L_MAMODE := 300;
      P.L_ACKMAMODE := 100;
      P.Q_MAMODE := 0;
      P.N_ITER := 0;
      return P;
   end LS_Profile;

   --  Level 2 in FS with the RBC's MA (EOA 1100 m); the group 10 at
   --  100 m announces level 1 at 600 m; the group 20 at 300 m gives an
   --  MA to 2000 m and a toggle on order with a time-out of 5 s. The
   --  train stands 10 s after the group: an order taken at the group
   --  (4.4.19.1.4.2 b) would have reached its time-out before the
   --  transition; kept in the buffer its timer starts at the transition
   --  (c)
   procedure Scenario_LS_Order_Buffered is
      Seen       : Boolean := False;
      At_Switch  : Boolean := False;
   begin
      EVC_LS_Display.Clear;
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_FS, L2);
      Add_Group (Group (10, 100));
      Carry (Track_N, 0, L1_Order (500));
      Add_Group (Group (20, 300));
      Carry (Track_N, 0, MA_Of ((1500, 200)));
      --  4.8.4.2 [9] (B093): in FS the order needs the LS area of a mode
      --  profile of the same message around the train (500 to 800 m)
      Carry (Track_N, 0, LS_Profile);
      Carry (Track_N, 1, Grad ((1 => (0, 0), 2 => (2500, End_Mark))));
      Carry (Track_N, 1, SSP ((1 => (0, 100, False),
                               2 => (2500, End_Mark, False))));
      Carry_180 (Track_N, 1, On => True, Delay_S => 5);
      EVC_Test_Authority.Establish_Session;
      Run_X (15_000);
      Give_Radio_Message (1, EVC_Test_Authority.Radio_MA (10, (600, 400)));
      Stand_X (100);
      Run_X (40_000);
      Stand_X (10_000);
      Check (EVC_Levels.L1_Announced and then not Order_Pending
             and then not Toggled_On,
             "4.4.19.1.4.2 c, 4.8.3 [1]: the toggle on order kept in the "
             & "transition buffer, its timer not running");
      for X in 401 .. 650 loop
         Run_X (Integer_64 (X) * 100, 100);
         if not Seen and then EVC_Levels.Level = L1 then
            Seen := True;
            At_Switch := Order_Pending and then not Toggled_On;
         end if;
      end loop;
      Check (Seen and then At_Switch,
             "4.4.19.1.4.2 c: the timer started at the level transition");
      Stand_X (5_000);
      Check (Toggled_On and then not Order_Pending,
             "4.4.19.1.4.3: toggled on at the transition + T_LSSMA");
   end Scenario_LS_Order_Buffered;

   --  Packet 181 in the group G
   procedure Carry_181 (G : Positive; K : Natural) is
      P  : ETCS_Track_Packets.P181.Packet_T;
      W  : Writer_T;
      OK : Boolean;
   begin
      P.Q_DIR := 1;
      ETCS_Track_Packets.P181.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry_181;

   --  Level 1 in FS; the group 10 at 100 m gives an MA with an LS mode
   --  profile, the group 20 at 600 m the same with packet 181
   procedure Scenario_LS_Marker_Deleted is
      procedure MA_Group (NID : Natural; At_M : Integer_64) is
      begin
         Add_Group (Group (NID, At_M));
         Carry (Track_N, 0, MA_Of ((1500, 200)));
         Carry (Track_N, 0, LS_Profile);
         Carry (Track_N, 1, Grad ((1 => (0, 0), 2 => (2500, End_Mark))));
         Carry (Track_N, 1, SSP ((1 => (0, 100, False),
                                  2 => (2500, End_Mark, False))));
      end MA_Group;
   begin
      EVC_LS_Display.Clear;
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_FS, L1);
      MA_Group (10, 100);
      MA_Group (20, 600);
      Carry_181 (Track_N, 1);
      Take_Marker;
      Run_X (15_000);
      Check (not Marker_Stored,
             "4.4.19.1.4.8: the marker deleted by an LS mode profile "
             & "received without it");
      Take_Marker;
      Run_X (65_000);
      Check (Marker_Stored,
             "4.4.19.1.4.8: kept with packet 181 in the same group");
   end Scenario_LS_Marker_Deleted;

   --  4.8.4.2 [9] (B093): level 1 in FS; the toggle on order of packet
   --  180 in a group with an MA and no mode profile (group 10 at 100 m),
   --  with an LS area ahead of the train's confidence interval (group 20
   --  at 300 m, the area from 500 m), with an LS area around the train
   --  (group 30 at 600 m, the area from 600 m)
   procedure Scenario_LS_Order_Area is
      procedure Order_Group (NID : Natural; At_M : Integer_64;
                             Profile : Boolean; D : Natural) is
      begin
         Add_Group (Group (NID, At_M));
         Carry (Track_N, 0, MA_Of ((1500, 200)));
         if Profile then
            Carry (Track_N, 0, LS_Profile (D));
         end if;
         Carry (Track_N, 1, Grad ((1 => (0, 0), 2 => (2500, End_Mark))));
         Carry (Track_N, 1, SSP ((1 => (0, 100, False),
                                  2 => (2500, End_Mark, False))));
         Carry_180 (Track_N, 1, On => True, Delay_S => 30);
      end Order_Group;
   begin
      EVC_LS_Display.Clear;
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_FS, L1);
      Order_Group (10, 100, False, 0);
      Order_Group (20, 300, True, 200);
      Order_Group (30, 600, True, 0);
      Run_X (15_000);
      Check (not Order_Pending and then not Toggled_On,
             "4.8.4.2 [9]: in FS the toggle on order without a mode "
             & "profile in its message rejected");
      Run_X (35_000);
      Check (not Order_Pending and then not Toggled_On,
             "4.8.4.2 [9]: rejected, the LS area of its message not "
             & "overlapped by the confidence interval");
      Run_X (65_000);
      Check (Order_Pending or else Toggled_On,
             "4.8.4.2 [9]: taken, the train inside the LS area of a mode "
             & "profile of its message, the furthest it overlaps");
   end Scenario_LS_Order_Area;

end EVC_Test_LS;
