--  ETCS on-board (EVC)
--  Phase E5 (e5/levels): see the spec.

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P41;
with ETCS_Track_Packets.P138;
with ETCS_Track_Packets.P139;
with ETCS_Variables;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Level_Sessions;
with EVC_Levels;
with EVC_Modes;              use EVC_Modes;
with EVC_Movement_Authority;
with EVC_Position;
with EVC_Procedures;
with EVC_Ports;              use EVC_Ports;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Sessions;
with EVC_Stored_Information;
with EVC_Test_Authority;
with EVC_Test_Support;       use EVC_Test_Support;
with Interfaces;             use Interfaces;
with Sim_Telegrams;

package body EVC_Test_Levels is

   package LS renames EVC_Level_Sessions;
   package RA renames EVC_Radio_Authority;
   package SI renames EVC_Stored_Information;
   use type EVC_Radio.Session_State_T;
   use type LS.Exit_Phase_T;

   --  Packet 41: an order to the level M at D_M metres from the group,
   --  or now (D_M < 0)
   function Order (M : ETCS_Variables.M_LEVELTR_T; D_M : Integer)
     return ETCS_Track_Packets.P41.Packet_T
   is
      P : ETCS_Track_Packets.P41.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_LEVELTR :=
        (if D_M < 0
         then ETCS_Variables.D_LEVELTR_Now_The_Level_Transition
         else ETCS_Variables.D_LEVELTR_T (D_M));
      P.M_LEVELTR := M;
      P.Has_NID_NTC := False;
      P.L_ACKLEVELTR := 0;
      P.N_ITER := 0;
      return P;
   end Order;

   --  The driver selects the level of the DMI code (MSG_DRIVER_ACTION 11)
   procedure Driver_Level (Code : Natural) is
   begin
      Input (DMI, Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (11, Byte (Code),
                                                          0)));
      Stand_X (100);
   end Driver_Level;

   L1_Code : constant := 4;
   L2_Code : constant := 5;

   ---------------------------------------------------------------------
   --  4.8.5.5: an MA of the RBC kept for an announced transition is used
   --  in the cycle of the transition, before its mode machine
   ---------------------------------------------------------------------

   procedure Scenario_L2_Buffer_Same_Cycle is
      Switched_OK : Boolean := False;
      Seen        : Boolean := False;
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_FS, L1);
      Add_Group (Group (10, 100));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_2, 300));
      EVC_Test_Authority.Establish_Session;
      Run_X (15_000);
      Give_Radio_Message (1, EVC_Test_Authority.Radio_MA (10, (600, 400)));
      Stand_X (100);
      Check (RA.Buffered = 1
             and then not EVC_Movement_Authority.MA_Present,
             "levels: the MA of the RBC with level 2 announced kept in the "
             & "transition buffer (4.8.3 [2], 4.8.5.1)");
      --  a cycle a metre up to the transition at 400 m
      for X in 151 .. 460 loop
         Run_X (Integer_64 (X) * 100, 100);
         if not Seen and then EVC_Levels.Level = L2 then
            Seen := True;
            Switched_OK := EVC_Movement_Authority.MA_Present
                           and then RA.Buffered = 0
                           and then EVC_Core.Mode = M_FS;
         end if;
      end loop;
      Check (Seen and then Switched_OK,
             "levels: in the cycle of the transition to level 2 the buffer "
             & "released and its MA taken, no trip by [39] (4.8.5.5 'at "
             & "the same time', 5.10.3.1.4, 4.6.3 [39])");
   end Scenario_L2_Buffer_Same_Cycle;

   ---------------------------------------------------------------------
   --  e5/balise-buffer: 4.8.3 [1], 4.8.5, 5.10.1.7, 5.10.1.8. Level 2 in
   --  FS with the RBC's MA (EOA 1100 m); the group 10 at 100 m announces
   --  level 1 at 600 m; the group 20 at 300 m gives level 1 information
   --  (an MA to 2000 m, its gradient and SSP). Order_2 > 0: the group 30
   --  at 350 m replaces the announcement by one to level 0 at Order_2 m
   ---------------------------------------------------------------------

   procedure Start_L1_Announced_In_L2 (Order_2 : Natural) is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_FS, L2);
      Add_Group (Group (10, 100));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, 500));
      Add_Group (Group (20, 300));
      Carry (Track_N, 0, MA_Of ((1500, 200)));
      Carry (Track_N, 1, Grad ((1 => (0, 0), 2 => (2500, End_Mark))));
      Carry (Track_N, 1, SSP ((1 => (0, 100, False),
                               2 => (2500, End_Mark, False))));
      if Order_2 > 0 then
         Add_Group (Group (30, 350));
         Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_0,
                                   Order_2));
      end if;
      EVC_Test_Authority.Establish_Session;
      Run_X (15_000);
      Give_Radio_Message (1, EVC_Test_Authority.Radio_MA (10, (600, 400)));
      Stand_X (100);
   end Start_L1_Announced_In_L2;

   procedure Scenario_L1_Balise_Buffer is
      EOA_RBC     : Integer_64;
      Seen        : Boolean := False;
      Switched_OK : Boolean := False;
   begin
      Start_L1_Announced_In_L2 (0);
      EOA_RBC := Integer_64 (SI.Current.MA.EOA);
      Run_X (40_000);
      Check (EVC_Levels.L1_Announced and then SI.Balise_Buffered = 1
             and then SI.Current.MA.Present
             and then abs (Integer_64 (SI.Current.MA.EOA) - EOA_RBC) < 1_000
             and then EOA_RBC = 110_000,
             "levels: in level 2 with level 1 announced the MA, gradient "
             & "and SSP of a group kept in the transition buffer, not used "
             & "(4.8.3 [1], 4.8.5.1, 5.10.1.7)");
      for X in 401 .. 650 loop
         Run_X (Integer_64 (X) * 100, 100);
         if not Seen and then EVC_Levels.Level = L1 then
            Seen := True;
            Switched_OK := SI.Balise_Buffered = 0
                           and then EVC_Core.Mode = M_FS;
         end if;
      end loop;
      Check (Seen and then Switched_OK,
             "levels: in the cycle of the transition to level 1 the balise "
             & "buffer released, no trip (4.8.5.5 'at the same time')");
      Check (SI.Current.MA.Present
             and then Integer_64 (SI.Current.MA.EOA) = 200_000,
             "levels: after the transition the MA of the group supervised "
             & "(4.8.5.6 a, b; 5.10.1.7)");
   end Scenario_L1_Balise_Buffer;

   --  SUBSET-076 5100100: level 0 in UN, the group 10 at 50 m announces
   --  level 1 at 250 m, the group 20 at 100 m gives an MA, the group 30
   --  at 150 m orders level 1 now: FS in the cycle after (4.6.3)
   procedure Scenario_L1_Balise_Buffer_From_L0 is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_UN, L0);
      Add_Group (Group (10, 50));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, 250));
      Add_Group (Group (20, 100));
      Carry (Track_N, 0, MA_Of ((1500, 200)));
      Carry (Track_N, 1, Grad ((1 => (0, 0), 2 => (2500, End_Mark))));
      Carry (Track_N, 1, SSP ((1 => (0, 100, False),
                               2 => (2500, End_Mark, False))));
      Add_Group (Group (30, 150));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, -1));
      Run_X (12_000);
      Check (SI.Balise_Buffered = 1 and then not SI.Current.MA.Present,
             "levels: level 0, level 1 announced: the group's MA kept "
             & "(4.8.3 [1])");
      Run_X (20_000);
      Check (EVC_Levels.Level = L1 and then SI.Current.MA.Present
             and then EVC_Core.Mode = M_FS,
             "levels: the immediate order to level 1: the kept MA used, "
             & "FS in the cycle (4.8.5.5, 4.6.3 [25])");
   end Scenario_L1_Balise_Buffer_From_L0;

   --  e5/onboard-gaps (B070), 4.8.3 [1], 4.8.5.5: the packets the units
   --  take themselves, read in level 0 with level 1 announced: the
   --  linking (packet 5, EVC_Position) and the reversing area and
   --  supervision (138, 139, EVC_Procedures) of the group 20 kept with
   --  its MA, taken at the immediate order of the group 30, not before
   procedure Scenario_L1_Balise_Buffer_Units is
      W5, W9 : Writer_T;
      OK     : Boolean;
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_UN, L0);
      Add_Group (Group (10, 50));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, 250));
      Add_Group (With_Links (Group (20, 100),
                             Link_To ((50, 1000), (30, 40))));
      Carry (Track_N, 0, MA_Of ((1500, 200)));
      Carry (Track_N, 1, Grad ((1 => (0, 0), 2 => (2500, End_Mark))));
      Carry (Track_N, 1, SSP ((1 => (0, 100, False),
                               2 => (2500, End_Mark, False))));
      ETCS_Track_Packets.P138.Encode
        (Sim_Telegrams.Reversing_Area (D_M => 100, L_M => 200), W5, OK);
      Finish_Carry (Track_N, 1, W5, OK);
      ETCS_Track_Packets.P139.Encode
        (Sim_Telegrams.Reversing_Supervision (D_M => 150, Kmh => 15), W9,
         OK);
      Finish_Carry (Track_N, 1, W9, OK);
      Add_Group (Group (30, 150));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, -1));
      Run_X (12_000);
      Check (SI.Balise_Buffered = 1
             and then not EVC_Procedures.Reversing_Area_Known
             and then not EVC_Position.Linking.Stored,
             "levels: level 0, level 1 announced: the group's linking and "
             & "reversing area kept, not taken (4.8.3 [1])");
      Run_X (20_000);
      Check (EVC_Levels.Level = L1 and then EVC_Core.Mode = M_FS
             and then EVC_Procedures.Reversing_Area_Known
             and then EVC_Position.Linking.Stored
             and then Natural (EVC_Position.Linking.Ref_Id.NID_BG) = 20,
             "levels: at the transition to level 1 the kept linking and "
             & "reversing area taken (4.8.5.5)");
   end Scenario_L1_Balise_Buffer_Units;

   --  e5/acceptance-gates (B212), 4.8.3 [1]: the group 20 at 100 m
   --  carries its own order to level 1 at 150 m further and a linking:
   --  the order is evaluated first, the linking kept in the transition
   --  buffer with the group's set, not taken by EVC_Position at the
   --  passage; taken once, at the immediate order of the group 30
   procedure Scenario_L1_Order_Own_Group_Linking is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_UN, L0);
      Add_Group (With_Links (Group (20, 100),
                             Link_To ((50, 1000), (30, 40))));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, 150));
      Carry (Track_N, 0, MA_Of ((1500, 200)));
      Carry (Track_N, 1, Grad ((1 => (0, 0), 2 => (2500, End_Mark))));
      Carry (Track_N, 1, SSP ((1 => (0, 100, False),
                               2 => (2500, End_Mark, False))));
      Add_Group (Group (30, 150));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, -1));
      Run_X (12_000);
      Check (EVC_Levels.L1_Announced and then SI.Balise_Buffered = 1
             and then not EVC_Position.Linking.Stored,
             "levels: a linking in the group carrying the order to level 1 "
             & "at a further location kept in the buffer, not taken at "
             & "the passage (4.8.3 [1], B212)");
      Run_X (20_000);
      Check (EVC_Levels.Level = L1 and then EVC_Core.Mode = M_FS
             and then EVC_Position.Linking.Stored
             and then Natural (EVC_Position.Linking.Ref_Id.NID_BG) = 20,
             "levels: at the transition to level 1 the group's own "
             & "linking taken (4.8.5.5, B212)");
   end Scenario_L1_Order_Own_Group_Linking;

   procedure Scenario_L1_Balise_Buffer_Deleted is
   begin
      Start_L1_Announced_In_L2 (3000);
      Run_X (33_000);
      Check (SI.Balise_Buffered = 1,
             "levels: the group's level 1 information kept (4.8.5.1)");
      Run_X (40_000);
      Check (not EVC_Levels.L1_Announced and then SI.Balise_Buffered = 0,
             "levels: the announcement replaced by an order to level 0, "
             & "the transition buffer deleted (4.8.5.4 a)");
      Run_X (70_000);
      Check (EVC_Levels.Level = L2
             and then abs (Integer_64 (SI.Current.MA.EOA) - 110_000) < 1_000,
             "levels: past the old border, level 2 and the RBC's MA kept");
   end Scenario_L1_Balise_Buffer_Deleted;

   ---------------------------------------------------------------------
   --  5.10.3.15: the driver's change of level to 2 and back
   ---------------------------------------------------------------------

   procedure Scenario_L2_Driver_Change is
      R0 : Natural;
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      EVC_Radio.Set_Contact
        ((Known => True, Valid => True,
          RBC   => (NID_C => 123, NID_RBC => 1), Radio => 0));
      Stand_X (100);
      Driver_Level (L2_Code);
      Stand_X (100);
      Check (EVC_Levels.Level = L2 and then LS.Sessions_Ordered = 1
             and then EVC_Radio.Info (1).State /= EVC_Radio.Idle,
             "levels: the driver changes the level to 2 with a valid RBC "
             & "contact: the session established at once (5.10.3.15.2 a, "
             & "3.5.3.4 d)");

      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L2);
      EVC_Test_Authority.Establish_Session;
      R0 := EVC_Sessions.Position_Reports_Sent;
      Driver_Level (L1_Code);
      Stand_X (100);
      Check (EVC_Levels.Level = L1
             and then EVC_Sessions.Position_Reports_Sent > R0
             and then LS.Exit_Phase = LS.Awaiting_Order,
             "levels: the driver changes the level from 2 to 1: the new "
             & "level reported, the order to terminate awaited "
             & "(5.10.3.15.3)");
      Stand_X (15_100);
      Check (LS.Reports_Requested = 1,
             "levels: no order to terminate within 15 s: the position "
             & "report repeated (5.10.3.15.4, A.3.1)");
      for I in 1 .. 3 loop
         Stand_X (15_100);
      end loop;
      Check (LS.Reports_Requested = 3 and then LS.Terminations = 1
             and then LS.Exit_Phase = LS.None
             and then EVC_Radio.Info (1).State /= EVC_Radio.Established,
             "levels: after three repetitions and 15 s without a reply the "
             & "on-board terminates the session (5.10.3.15.4, 3.5.5.1)");
   end Scenario_L2_Driver_Change;

   ---------------------------------------------------------------------
   --  5.10.3.3: the transition from level 2 to level 1 by trackside
   ---------------------------------------------------------------------

   procedure Scenario_L2_Exit_By_Order is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_FS, L2);
      Add_Group (Group (10, 100));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, -1));
      EVC_Test_Authority.Establish_Session;
      Run_X (11_000);
      Check (EVC_Levels.Level = L1 and then LS.Exit_Phase = LS.Border_Ahead
             and then LS.Reports_Requested = 0,
             "levels: the order to level 1 executed, the min safe rear end "
             & "not past the border yet (5.10.3.3.3)");
      Run_X (40_000);
      Check (LS.Reports_Requested = 1
             and then LS.Exit_Phase = LS.Awaiting_Order,
             "levels: the min safe rear end past the border: a position "
             & "report sent to the RBC (5.10.3.3.3)");
      EVC_Radio.Set_State (1, EVC_Radio.Terminating);
      Stand_X (100);
      Check (LS.Exit_Phase = LS.None and then LS.Terminations = 0,
             "levels: the RBC orders the termination: the exit over, no "
             & "repetition (5.10.3.3.4, 5.10.3.3.5)");
   end Scenario_L2_Exit_By_Order;

   --  5.10.3.3.3, 5.10.3.6.2: the report at the border is the leading
   --  engine's; a non-leading engine (NL) passing the border of level 2
   --  with its min safe rear end sends none and awaits no order
   --  (SUBSET-076 4050200_04 step 88)
   procedure Scenario_L2_Exit_In_NL is
   begin
      Start_X;
      Input (TIU, (Byte (TIU_Signal_T'Pos (Non_Leading_Permitted) + 1), 1));
      EVC_Core.Set_Mode_For_Test (M_NL, L2);
      Add_Group (Group (10, 100));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, -1));
      EVC_Test_Authority.Establish_Session;
      Run_X (11_000);
      Check (EVC_Levels.Level = L1 and then LS.Exit_Phase = LS.Border_Ahead,
             "levels NL: the order to level 1 executed, the border ahead");
      Run_X (40_000);
      Check (EVC_Core.Mode = M_NL and then LS.Reports_Requested = 0
               and then LS.Exit_Phase = LS.None,
             "levels NL: the min safe rear end past the border: no position "
             & "report from a non-leading engine (5.10.3.6.2)");
      Input (TIU, (Byte (TIU_Signal_T'Pos (Non_Leading_Permitted) + 1), 0));
   end Scenario_L2_Exit_In_NL;

   --  3.5.3.8 d): the order to level 1 executed while a session is being
   --  established; the min safe rear end past the border aborts it and
   --  releases its safe radio connection
   procedure Scenario_L2_Exit_Aborts_Establishment is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_FS, L2);
      Add_Group (Group (10, 100));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, -1));
      EVC_Sessions.Take_Order
        (Establish => True, RBC => (NID_C => 123, NID_RBC => 1),
         Radio     => 0);
      Run_X (11_000);
      Check (EVC_Levels.Level = L1 and then LS.Exit_Phase = LS.Border_Ahead
             and then EVC_Radio.Being_Established (1),
             "levels: the order to level 1 executed, a session being "
             & "established, the min safe rear end not past the border");
      Run_X (40_000);
      Check (LS.Exit_Phase = LS.None
             and then EVC_Radio.Info (1).State = EVC_Radio.Idle
             and then LS.Reports_Requested = 0,
             "levels: the min safe rear end past the border out of level 2: "
             & "the establishment aborted, its connection released "
             & "(3.5.3.8 d)");
   end Scenario_L2_Exit_Aborts_Establishment;

   --  3.16.3.4.1.1: switched to level 2 with no session established
   --  (no RBC contact: the Radio data awaited): the supervision of the
   --  safe radio connection compares with the time of the switch,
   --  T_NVCONTACT 10 s with train trip as its reaction
   procedure Scenario_L2_Switch_Contact is
      NV : Sim_Telegrams.T3.Packet_T := Sim_Telegrams.National_Values (123);
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      NV.T_NVCONTACT := 10;   -- s
      NV.M_NVCONTACT := 0;    -- train trip
      Add_Group (Group (10, 100));
      Carry (Track_N, 0, NV);
      Run_X (11_000);
      Driver_Level (L2_Code);
      Stand_X (100);
      Check (EVC_Levels.Level = L2 and then EVC_Radio.Info (1).State
               = EVC_Radio.Idle
             and then not EVC_Sessions.T_NVCONTACT_Trip,
             "levels: switched to level 2 without a session, T_NVCONTACT "
             & "not passed since the switch");
      Stand_X (10_500);
      Check (EVC_Sessions.T_NVCONTACT_Trip,
             "levels: T_NVCONTACT passed since the switch to level 2 "
             & "without a message: the reaction (3.16.3.4.1.1)");
   end Scenario_L2_Switch_Contact;

   ---------------------------------------------------------------------
   --  5.10.3.1, 3.4.4.4.3.2: the immediate order to level 2 of a linked
   --  group is carried out only when the group is found in its
   --  expectation window; found 200 m before it, its message is rejected
   --  and the level stays. SUBSET-076 4080455 (Sa03cccdc): BG3d,
   --  announced by the linking of BG1d 300 m after BG2d (450 m, Q_LOCACC
   --  10 m), is placed at 200 m (400 m in _05 to _08)
   ---------------------------------------------------------------------

   procedure Scenario_L2_Order_Linked_Group is
      type Places_T is array (1 .. 2) of Integer_64;
      Places : constant Places_T := (200, 400);
   begin
      for Found_M of Places loop
         Start_X;
         EVC_Core.Set_Mode_For_Test (M_FS, L1);
         Add_Group (With_Links (Group (10, 100), Link_To ((1 => 300),
                                                          (1 => 20))));
         Add_Group (Group (20, Found_M));
         Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_2, -1));
         Run_X ((Found_M + 50) * 100);
         if Found_M = 200 then
            Check (EVC_Levels.Level = L1,
                   "levels: the immediate order of a linked group found "
                   & "before its expectation window: rejected, the level "
                   & "stays (3.4.4.4.3.2)");
         else
            Check (EVC_Levels.Level = L2,
                   "levels: the same group found in its window: the "
                   & "order carried out at once (3.4.4.4.6 a), 5.10.3.1)");
         end if;
      end loop;
   end Scenario_L2_Order_Linked_Group;

   ---------------------------------------------------------------------
   --  5.10.3.15.2 b): the driver's level 2 without the conditions of a),
   --  the session once the driver has entered the Radio data
   ---------------------------------------------------------------------

   use type LS.Await_T;
   use type ETCS_Variables.NID_RBC_T;

   --  MSG_DRIVER_DATA kind 5 (DMI Table 50 S5-1): choice 0 'Enter RBC
   --  data' (RBC 123 / 1, number 0077) or 1 'Contact last RBC'
   function RBC_Data (Choice : Byte) return Byte_Array is
      Res : Byte_Array (1 .. 23) := (others => 0);
      Id  : constant := 123 * 16_384 + 1;
   begin
      Res (1 .. 6) := (5, Choice, Byte (Id mod 256),
                       Byte (Id / 256 mod 256), Byte (Id / 65_536), 0);
      Res (7 .. 11) := (4, Character'Pos ('0'), Character'Pos ('0'),
                        Character'Pos ('7'), Character'Pos ('7'));
      return Frame (EVC_DMI_Port.MSG_DRIVER_DATA, Res);
   end RBC_Data;

   --  A set-up request on the RTM port within N cycles
   function Set_Up_Sent (N : Positive) return Boolean is
   begin
      for I in 1 .. N loop
         Stand;
         for J in 1 .. Radio_Outputs loop
            if Radio_Output (J).Request
              and then Radio_Output (J).Kind
                       = RTM_Request_T'Pos (Request_Set_Up) + 1
            then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Set_Up_Sent;

   procedure Scenario_L2_Radio_Data_No_Contact is
      C : EVC_Radio.RBC_Contact_T;
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      Stand_X (100);
      Driver_Level (L2_Code);
      Stand_X (100);
      Check (EVC_Levels.Level = L2
             and then LS.Radio_Data_Awaited = LS.No_Contact
             and then LS.Sessions_Ordered = 0
             and then EVC_Radio.Info (1).State = EVC_Radio.Idle,
             "levels: level 2 selected without RBC contact: no session, "
             & "the Radio data awaited (5.10.3.15.2 b)");
      Input (DMI, RBC_Data (0));
      Stand_X (100);
      C := EVC_Radio.Contact;
      Check (LS.Sessions_Ordered = 1
             and then LS.Radio_Data_Awaited = LS.Nothing
             and then C.Valid and then C.RBC.NID_RBC = 1
             and then EVC_Radio.Info (1).State /= EVC_Radio.Idle,
             "levels: the driver's RBC data entered: the contact stored, "
             & "the session established (5.10.3.15.2 b)");
   end Scenario_L2_Radio_Data_No_Contact;

   procedure Scenario_L2_Radio_Data_No_Registration is
   begin
      Auto_Register := False;
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      EVC_Radio.Set_Contact
        ((Known => True, Valid => True,
          RBC   => (NID_C => 123, NID_RBC => 1), Radio => 0));
      Stand_X (100);
      Driver_Level (L2_Code);
      Stand_X (100);
      Check (LS.Radio_Data_Awaited = LS.No_Registration
             and then LS.Sessions_Ordered = 0,
             "levels: level 2 selected with a valid contact but no mobile "
             & "registered: the Radio data awaited (5.10.3.15.2 a, b)");
      Input (DMI, RBC_Data (1));
      Stand_X (100);
      Check (LS.Sessions_Ordered = 1
             and then not EVC_Sessions.Network_Ready
             and then not Set_Up_Sent (20),
             "levels: 'Contact last RBC' selected: the session ordered, "
             & "its set-up waits for the registration (5.10.3.15.2 b, "
             & "3.5.6.7)");
      Give_Radio_Event (1, Registered);
      Check (Set_Up_Sent (20),
             "levels: registered: the set-up requested (3.5.6.7)");
      Auto_Register := True;
   end Scenario_L2_Radio_Data_No_Registration;

   procedure Scenario_L2_Radio_Data_Into_TR is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_UN, L0);
      Stand_X (100);
      Driver_Level (L2_Code);
      Stand_X (100);
      Check (EVC_Core.Mode = M_TR
             and then LS.Radio_Data_Awaited = LS.No_Contact,
             "levels: level 0 to 2 by the driver into TR: the Radio data "
             & "awaited (5.10.3.15.2 b)");
      Input (DMI, RBC_Data (0));
      Stand_X (100);
      Check (LS.Sessions_Ordered = 0
             and then LS.Radio_Data_Awaited = LS.No_Contact,
             "levels: in TR the Radio data are not taken (5.10.3.15.2 b, "
             & "the note: the request only in PT)");
      EVC_Core.Set_Mode_For_Test (M_PT, L2);
      Stand_X (100);
      Input (DMI, RBC_Data (0));
      Stand_X (100);
      Check (EVC_Core.Mode = M_PT and then LS.Sessions_Ordered = 1
             and then EVC_Radio.Info (1).State /= EVC_Radio.Idle,
             "levels: in PT the driver's Radio data open the session "
             & "(5.10.3.15.2 b and its note)");
   end Scenario_L2_Radio_Data_Into_TR;

   --  3.6.3.1.4 and its note 3.6.3.1.4.2, 3.4.2.3.2 (e4/gates-levels,
   --  B240): in SR, level 1, no linking, a single balise group has no
   --  co-ordinate system: its order to level 2 at its own location
   --  (D_LEVELTR 0) valid for the nominal direction only is rejected;
   --  the same order valid for both directions is carried out (5.10.1),
   --  the mode stays SR. SUBSET-076 9990500_24 (BG11d) and 5220200_03
   --  (BG1d, the second balise of two missing) expect the nominal one
   --  carried out
   procedure Scenario_SR_Order_Single_Group is
      procedure Pass (Q_DIR : ETCS_Variables.Q_DIR_T; Expect : Level_T;
                      What : String) is
         O : ETCS_Track_Packets.P41.Packet_T :=
           Order (ETCS_Variables.M_LEVELTR_Level_2, 0);
      begin
         Start_X;
         EVC_Core.Set_Mode_For_Test (M_SR, L1);
         Stand_X (100);
         Add_Group (Group (1, 50, Balises => 1));
         O.Q_DIR := Q_DIR;
         Carry (Track_N, 0, O);
         Run_X (10_000);
         Check (EVC_Levels.Level = Expect and then EVC_Core.Mode = M_SR,
                "levels: in SR an order to level 2 by a single balise "
                & "group without co-ordinate system, " & What);
      end Pass;
   begin
      Pass (1, L1, "valid for the nominal direction only: rejected "
            & "(3.6.3.1.4, 3.6.3.1.4.2, B240)");
      Pass (2, L2, "valid for both directions: carried out (3.6.3.1.4, "
            & "5.10.1)");
   end Scenario_SR_Order_Single_Group;


   --  4.8.1.3.1 1) and 2): in level 1 a group carries a level 1 MA
   --  (packet 12 with its gradient and SSP) and an immediate order to
   --  level 2: the MA is judged first in level 1, where it is accepted
   --  (4.8.3, A [4]), and is not judged again in level 2 (where it would
   --  be R [1]); the on-board is in level 2 with that MA. SUBSET-076
   --  3131050_05 and _06 (BG2d at 200 m)
   procedure Scenario_L2_Order_With_L1_MA is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      Stand_X (100);
      Add_Group (Group (1, 50));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_2, -1));
      Carry (Track_N, 0, MA_Of ((1 => 500), 80));
      Carry (Track_N, 0, Grad (((0, 0), (600, End_Mark))));
      Carry (Track_N, 0, SSP (((0, 80, False), (600, End_Mark, False))));
      Run_X (10_000);
      Check (EVC_Levels.Level = L2 and then SI.Current.MA.Present
             and then abs (Integer_64 (SI.Current.MA.EOA) - 55_000) < 1_000,
             "levels: the level 1 MA of the group of an immediate order to "
             & "level 2 judged in level 1 first and kept (4.8.1.3.1 1), "
             & "2), 4.8.3 A [4])");
   end Scenario_L2_Order_With_L1_MA;

   --  4.8.1.3.1 2): in level 0 (UN) a group carries an immediate order to
   --  level 1 and a level 1 MA: stored in level 0 (4.8.3 [1]), taken
   --  again in level 1 at once, the transition makes FS, no trip by
   --  [39]. SUBSET-076 3050300_01 (BG2d at 450 m)
   procedure Scenario_L1_Order_With_L1_MA_In_L0 is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_UN, L0);
      Stand_X (100);
      Add_Group (Group (1, 50));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, -1));
      Carry (Track_N, 0, MA_Of ((1 => 500), 80));
      Carry (Track_N, 0, Grad (((0, 0), (600, End_Mark))));
      Carry (Track_N, 0, SSP (((0, 80, False), (600, End_Mark, False))));
      Run_X (10_000);
      Check (EVC_Levels.Level = L1 and then SI.Current.MA.Present
             and then EVC_Core.Mode = M_FS,
             "levels: the level 1 MA of the group of an immediate order "
             & "from level 0 to level 1 stored in level 0 and taken in "
             & "level 1 at once (4.8.1.3.1 2), 4.8.3 [1]): FS, no trip "
             & "by 4.6.3 [39]");
   end Scenario_L1_Order_With_L1_MA_In_L0;

   --  Message 24 referring to the group NID_BG with the packet 41 P
   function Level_Message (NID_BG : Natural;
                           P      : ETCS_Track_Packets.P41.Packet_T)
     return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
   begin
      V (3) := Unsigned_64
        (EVC_Radio.T_Train_At (Unsigned_64 (EVC_Core.Time_Ms)));
      V (5) := 123;
      V (6) := Unsigned_64 (NID_BG);
      Start_Message (W, ETCS_Message_Catalogue.Track_M24, V);
      ETCS_Track_Packets.P41.Encode (P, W, OK);
      Check (OK, "levels: packet 41 encoded");
      return Message_Bytes (W);
   end Level_Message;

   --  The level transition order of message 24 (8.4.1, 5.10.1.2: the
   --  announcement by the RBC) is taken in level 1; in PT only the
   --  announcement is accepted (4.8.4 [5]), an order now or at distance
   --  0 from the LRBG rejected
   procedure Scenario_Radio_Level_Orders is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_FS, L1);
      Add_Group (Group (10, 100));
      EVC_Test_Authority.Establish_Session;
      Run_X (15_000);
      Stand_X (1_000);
      Give_Radio_Message
        (1, Level_Message (10, Order (ETCS_Variables.M_LEVELTR_Level_2,
                                      500)));
      Stand_X (200);
      Check (EVC_Levels.Announced and then EVC_Levels.Announced_Level = L2,
             "levels: the order to level 2 of message 24 announced in "
             & "level 1 (8.4.1, 5.10.1.2)");
      EVC_Core.Set_Mode_For_Test (M_PT, L2);
      Stand_X (200);
      Give_Radio_Message
        (1, Level_Message (10, Order (ETCS_Variables.M_LEVELTR_Level_1, 0)));
      Stand_X (200);
      Give_Radio_Message
        (1, Level_Message (10, Order (ETCS_Variables.M_LEVELTR_Level_1,
                                      -1)));
      Stand_X (200);
      Check (EVC_Levels.Level = L2
             and then not (EVC_Levels.Announced
                           and then EVC_Levels.Announced_Level = L1),
             "levels: in PT the immediate orders of message 24 rejected "
             & "(4.8.4 [5])");
      Give_Radio_Message
        (1, Level_Message (10, Order (ETCS_Variables.M_LEVELTR_Level_1,
                                      900)));
      Stand_X (200);
      Check (EVC_Levels.Level = L2 and then EVC_Levels.Announced
             and then EVC_Levels.Announced_Level = L1,
             "levels: in PT the announcement accepted (4.8.4 [5])");
   end Scenario_Radio_Level_Orders;

   --  In SH an order at distance 0 from its group is an immediate order,
   --  kept for later (4.8.4 [7]); an announcement is rejected
   procedure Scenario_SH_Order_At_Zero is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SH, L2);
      Add_Group (Group (10, 100));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_1, 0));
      Add_Group (Group (11, 200));
      Carry (Track_N, 0, Order (ETCS_Variables.M_LEVELTR_Level_0, 300));
      Run_X (15_000);
      Check (EVC_Levels.Level = L2 and then EVC_Levels.Deferred,
             "levels: in SH the order at D_LEVELTR 0 kept for later "
             & "(4.8.4 [7])");
      Run_X (25_000);
      Check (EVC_Levels.Level = L2 and then EVC_Levels.Deferred
             and then not EVC_Levels.Order_Pending,
             "levels: in SH the announcement rejected, the kept order "
             & "stays (4.8.4 [7])");
   end Scenario_SH_Order_At_Zero;

end EVC_Test_Levels;
