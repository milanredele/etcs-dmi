--  ETCS on-board (EVC)
--  Phase E5 (e5/levels): see the spec.

with ETCS_Track_Packets.P41;
with ETCS_Variables;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Level_Sessions;
with EVC_Levels;
with EVC_Modes;              use EVC_Modes;
with EVC_Movement_Authority;
with EVC_Ports;              use EVC_Ports;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Sessions;
with EVC_Test_Authority;
with EVC_Test_Support;       use EVC_Test_Support;
with Interfaces;             use Interfaces;

package body EVC_Test_Levels is

   package LS renames EVC_Level_Sessions;
   package RA renames EVC_Radio_Authority;
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

end EVC_Test_Levels;
