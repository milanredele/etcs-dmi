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
      Check (V.Full and then V.Count = V.VBC_Max
             and then not V.Covers (300, NID_VBCMK_T
                                          (V.VBC_Max)),
             "vbc: the store is full at" & V.VBC_Max'Image
             & " covers, a new identity ignored (decision)");
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
      V.Clear;
   end Scenario_VBC_Driver;

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

end EVC_Test_VBC;
