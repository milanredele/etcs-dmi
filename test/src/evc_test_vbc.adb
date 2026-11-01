--  ETCS on-board (EVC)
--  Phase E6, the Virtual Balise Cover (see the specification).

with ETCS_Track_Packets.P0;
with ETCS_Track_Packets.P6;
with ETCS_Variables;      use ETCS_Variables;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Modes;           use EVC_Modes;
with EVC_Ports;           use EVC_Ports;
with EVC_Position;
with EVC_Test_Modes;
with EVC_Test_Support;    use EVC_Test_Support;
with EVC_VBC;
with Interfaces;          use Interfaces;

package body EVC_Test_VBC is

   package V renames EVC_VBC;

   Day : constant := V.Day_Ms;

   procedure Scenario_VBC_Store is
   begin
      V.Clear;
      V.Expire (0);
      V.Set (123, 5, 2);
      Check (V.Covers (123, 5) and then V.Count = 1
             and then V.Item (1).Left = 2 * Day,
             "vbc: set, its period from now in days (3.15.9.6)");
      V.Expire (Day);
      V.Set (123, 5, 3);
      Check (V.Count = 1 and then V.Item (1).Left = 3 * Day,
             "vbc: the same identity replaces the cover and its period "
             & "(3.15.9.4)");
      V.Set (124, 5, 1);
      Check (V.Count = 2 and then V.Covers (124, 5)
             and then not V.Covers (124, 6),
             "vbc: the identity is the marker with the country "
             & "(3.15.9.1 a)");
      V.Expire (2 * Day);
      Check (not V.Covers (124, 5) and then V.Covers (123, 5),
             "vbc: deleted when its period has elapsed (3.15.9.5 b)");
      V.Remove (123, 5);
      Check (V.Count = 0, "vbc: removed (3.15.9.5 a), c)");
      V.Set (123, 1, 9);
      V.Set (200, 2, 9);
      V.Check_Country (123);
      Check (V.Covers (123, 1) and then not V.Covers (200, 2),
             "vbc: a group of another country deletes the cover "
             & "(3.15.9.5 d)");
      for I in 1 .. V.VBC_Max loop
         V.Set (300, NID_VBCMK_T (I), 1);
      end loop;
      Check (V.Full and then V.Count = V.Driver_Max
             and then not V.Covers (300, NID_VBCMK_T
                                          (V.VBC_Max)),
             "vbc: the driver's room is full at" & V.Driver_Max'Image
             & " covers, a new identity ignored (SUBSET-040 4.5.1.2)");
      Check (V.Code (V.Item (1)) = 1 + 123 * 64 + 9 * 65_536,
             "vbc: the set code of DMI 11.3.12.5");
      V.Clear;
   end Scenario_VBC_Store;

   --  MSG_DRIVER_DATA kind 8 (Set VBC) or 9 (Remove VBC) with Code
   function VBC_Entry (Kind : Byte; Code : Unsigned_32) return Byte_Array is
     (Frame (EVC_DMI_Port.MSG_DRIVER_DATA,
             (Kind, Byte (Code and 255),
              Byte (Shift_Right (Code, 8) and 255),
              Byte (Shift_Right (Code, 16) and 255),
              Byte (Shift_Right (Code, 24)))));

   procedure Scenario_VBC_Driver is
      I : Natural;
   begin
      EVC_Test_Modes.Start_E4;
      Check (Onboard_Field (5) mod 16 / 4 = 1,
             "vbc: MSG_ONBOARD room for a VBC, none stored (national "
             & "bits 2, 3)");
      --  NID_VBCMK 5, NID_C 123, T_VBC 3 (DMI 11.3.12.5)
      Input (DMI, VBC_Entry (8, 5 + 123 * 64 + 3 * 65_536));
      Stand;
      I := Find_DMI (EVC_DMI_Port.MSG_VBC_LIST);
      Check (V.Covers (123, 5) and then V.Item (1).T_VBC = 3,
             "vbc: set by the driver in SB (3.15.9.2)");
      Check (JRU_Field (28, 0, 6) = 5 and then JRU_Field (28, 6, 10) = 123
             and then JRU_Field (28, 16, 8) = 3,
             "vbc: SUBSET-027 4.2.4.28 VBC set by the driver, NID_VBCMK, "
             & "NID_C, T_VBC");
      Check (I > 0 and then Byte_At (I, 6) = 1
             and then Byte_At (I, 7) = Natural ((5 + 123 * 64) mod 256),
             "vbc: MSG_VBC_LIST with the cover's set code");
      Check (Onboard_Field (5) mod 16 / 4 = 3,
             "vbc: MSG_ONBOARD a VBC stored (national bit 3)");
      EVC_Core.Power_Up;
      Check (V.Covers (123, 5),
             "vbc: kept over No Power, applicable again (3.15.9.5)");
      EVC_Test_Modes.Start_E4;
      --  the remove code: NID_C in the 10 low bits (DMI 11.3.13.5)
      Input (DMI, VBC_Entry (9, 123 + 5 * 1024));
      Stand;
      Check (not V.Covers (123, 5) and then V.Count = 0,
             "vbc: removed by the driver (3.15.9.5 c)");
      Check (JRU_Field (29, 0, 10) = 123 and then JRU_Field (29, 10, 6) = 5,
             "vbc: SUBSET-027 4.2.4.29 VBC removed by the driver, NID_C, "
             & "NID_VBCMK");
      V.Clear;
   end Scenario_VBC_Driver;

   procedure Scenario_VBC_Rooms is
      use type V.Origin_T;
      I : Natural;
   begin
      EVC_Test_Modes.Start_E4;
      V.Clear;
      for I in 1 .. V.Trackside_Max + 1 loop
         V.Order (200, NID_VBCMK_T (I), 7);
      end loop;
      Check (V.Count_Of (V.Trackside) = V.Trackside_Max
             and then not V.Covers (200, NID_VBCMK_T (V.Trackside_Max + 1))
             and then V.Count_Of (V.Driver) = 0 and then not V.Full,
             "vbc: 10 covers ordered by trackside, the 11th ignored, the "
             & "driver's room untouched (SUBSET-040 4.3.2.1 w), 3.15.9.5)");
      for I in 1 .. V.Driver_Max + 1 loop
         V.Set (100, NID_VBCMK_T (I), 5);
      end loop;
      Check (V.Count_Of (V.Driver) = V.Driver_Max and then V.Full
             and then not V.Covers (100, NID_VBCMK_T (V.Driver_Max + 1))
             and then V.Count = V.VBC_Max,
             "vbc: 20 covers set by the driver beside trackside's 10, the "
             & "21st refused (SUBSET-040 4.5.1.2)");
      V.Remove (200, 1);
      V.Order (200, 40, 7);
      Check (V.Covers (200, 40) and then V.Count = V.VBC_Max,
             "vbc: a trackside order taken while the driver's room is "
             & "full");
      V.Order (100, 1, 9);
      Check (V.Count_Of (V.Driver) = V.Driver_Max
             and then V.Count_Of (V.Trackside) = V.Trackside_Max
             and then V.Item (V.Trackside_Max + 1).Marker = 1
             and then V.Item (V.Trackside_Max + 1).T_VBC = 9
             and then V.Item (V.Trackside_Max + 1).Origin = V.Driver,
             "vbc: trackside's VBC of a driver's identity replaces it in "
             & "the driver's room (3.15.9.4, decision)");
      Stand;
      Check (Onboard_Field (5) mod 16 / 4 = 2,
             "vbc: MSG_ONBOARD no room for the driver, VBCs stored "
             & "(national bits 2, 3)");
      I := Find_DMI (EVC_DMI_Port.MSG_VBC_LIST);
      --  the last of the store: NID_VBCMK 20, NID_C 100 (DMI 11.3.12.5)
      Check (I > 0 and then Byte_At (I, 6) = V.VBC_Max
             and then Byte_At (I, 7 + 4 * (V.VBC_Max - 1))
                        = Natural ((20 + 100 * 64) mod 256),
             "vbc: MSG_VBC_LIST with the 30 covers of both rooms");
      EVC_Core.Power_Up;
      Check (V.Count = V.VBC_Max
             and then V.Count_Of (V.Driver) = V.Driver_Max
             and then V.Full and then V.Covers (200, 40),
             "vbc: the 30 covers and their rooms kept over No Power "
             & "(3.15.9.5)");
      V.Clear;
   end Scenario_VBC_Rooms;

   --  Group G's balises carry the VBC marker M (packet 0, first, 8.4.2.3)
   procedure Mark (G : Positive; M : NID_VBCMK_T) is
      P  : ETCS_Track_Packets.P0.Packet_T;
      OK : Boolean;
   begin
      P.NID_VBCMK := M;
      for K in 0 .. 1 loop
         declare
            W : Writer_T;
         begin
            ETCS_Track_Packets.P0.Encode (P, W, OK);
            Finish_Carry (G, K, W, OK);
         end;
      end loop;
   end Mark;

   --  Group G orders the cover (C, M) set for T days or removed
   procedure Order (G : Positive; Set : Boolean;
                    C : NID_C_T;
                    M : NID_VBCMK_T;
                    T : T_VBC_T := 0)
   is
      P  : ETCS_Track_Packets.P6.Packet_T;
      W  : Writer_T;
      OK : Boolean;
   begin
      P.Q_DIR := 2;
      P.Q_VBCO := (if Set then 1 else 0);
      P.NID_VBCMK := M;
      P.NID_C := C;
      P.Has_T_VBC := Set;
      P.T_VBC := T;
      ETCS_Track_Packets.P6.Encode (P, W, OK);
      Finish_Carry (G, 0, W, OK);
   end Order;

   procedure Scenario_VBC_Cover is
      Records : Natural;
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      Stand_X (100);
      V.Set (123, 5, 10);
      Add_Group (Group (1, 50));
      Mark (1, 5);
      Add_Group (Group (2, 150));
      Add_Group (Group (3, 250));
      Order (3, True, 123, 7, 2);
      Order (3, False, 123, 5);
      Add_Group (Group (4, 350));
      Mark (4, 7);
      Add_Group (Group (5, 450));
      Country (5) := 124;
      Add_Group (Group (6, 550));
      Mark (6, 7);
      Records := JRU_Seen (2);
      Run_X (10_000);
      Check (not EVC_Position.LRBG.Valid,
             "vbc: the covered group is not received (3.15.9.3 a)");
      Check (JRU_Seen (2) >= Records + 2,
             "vbc: its telegrams are recorded as juridical data "
             & "(3.15.9.3 a), 3.20)");
      Run_X (20_000);
      Check (EVC_Position.LRBG.Valid
             and then EVC_Position.LRBG.Id.NID_BG = 2,
             "vbc: a group without the marker is received");
      Run_X (30_000);
      Check (V.Covers (123, 7) and then not V.Covers (123, 5),
             "vbc: packet 6 sets one cover and removes another "
             & "(3.15.9.4, 3.15.9.5 a)");
      Run_X (40_000);
      Check (EVC_Position.LRBG.Id.NID_BG = 3,
             "vbc: the group with the marker of the new cover is not "
             & "received");
      Run_X (50_000);
      Check (not V.Covers (123, 7),
             "vbc: a group of another country deletes the cover "
             & "(3.15.9.5 d)");
      Run_X (60_000);
      Check (EVC_Position.LRBG.Id.NID_BG = 6,
             "vbc: without a cover the marker is ignored and the group "
             & "received (4.8.2.3)");
      V.Clear;
   end Scenario_VBC_Cover;

   procedure Scenario_VBC_Clock is
      --  2026-01-01 00:00:00 UTC, seconds since 2000-01-01
      UTC_0 : constant Unsigned_32 := 820_540_800;
      Days_2 : constant Unsigned_32 := 2 * 86_400;
   begin
      for With_Clock in Boolean loop
         EVC_Test_Modes.Start_E4;
         EVC_Core.Set_UTC (UTC_0);
         --  NID_VBCMK 5, NID_C 123, T_VBC 1 (DMI 11.3.12.5)
         Input (DMI, VBC_Entry (8, 5 + 123 * 64 + 1 * 65_536));
         Stand;
         Check (V.Covers (123, 5), "vbc clock: a cover of one day set");
         EVC_Core.Power_Up;
         if With_Clock then
            EVC_Core.Set_UTC (UTC_0 + Days_2);
         end if;
         Stand;
         if With_Clock then
            Check (not V.Covers (123, 5),
                   "vbc clock: two days later by the clock at the "
                   & "power-up, the period of one day has elapsed and the "
                   & "cover is deleted (3.15.9.5 b), 3.18.5.1)");
         else
            Check (V.Covers (123, 5),
                   "vbc clock: no clock after the power-up, the time "
                   & "left with power on keeps the cover");
         end if;
         V.Clear;
      end loop;
   end Scenario_VBC_Clock;

end EVC_Test_VBC;
