with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P15;
with ETCS_Track_Packets.P49;
with ETCS_Track_Packets.P80;
with ETCS_Variables;
with EVC_Core;
with EVC_Radio;
with EVC_Ports;              use EVC_Ports;
with EVC_Modes;              use EVC_Modes;
with EVC_Test_Authority;
with EVC_Test_Support;       use EVC_Test_Support;
with Interfaces;             use Interfaces;

package body EVC_Test_Shapes is

   package MCat renames ETCS_Message_Catalogue;
   package T15 renames ETCS_Track_Packets.P15;
   package T49 renames ETCS_Track_Packets.P49;
   package T80 renames ETCS_Track_Packets.P80;

   --  Message 3 from the LRBG 10: an MA of 2000 m, flat, 100 km/h, an SH
   --  mode profile from SH_At_M (m from the LRBG) and, with List, the
   --  list of balise groups for the SH area (packet 49)
   function MA_With_SH (SH_At_M : Natural; List : Nat_List) return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
      A  : T15.Packet_T;
      S  : T27.Packet_T := SSP ((1 => (0, 100, False)));
      G  : T21.Packet_T := Grad ((1 => (0, 0)));
      M  : T80.Packet_T;
      L  : T49.Packet_T;
   begin
      V (3) := Unsigned_64 (EVC_Radio.T_Train_At (Unsigned_64 (EVC_Core.Time_Ms)));
      V (5) := 123;
      V (6) := 10;
      Start_Message (W, MCat.Track_M3, V);
      A.Q_DIR := 1;
      A.Q_SCALE := 1;
      A.T_EMA := 1023;
      A.L_ENDSECTION := 2000;
      T15.Encode (A, W, OK);
      Check (OK, "shapes: packet 15 encoded");
      S.Q_DIR := 1;
      G.Q_DIR := 1;
      T21.Encode (G, W, OK);
      Check (OK, "shapes: packet 21 encoded");
      T27.Encode (S, W, OK);
      Check (OK, "shapes: packet 27 encoded");
      M.Q_DIR := 1;
      M.Q_SCALE := 1;
      M.D_MAMODE := ETCS_Variables.D_MAMODE_T (SH_At_M);
      M.M_MAMODE := 1;
      M.V_MAMODE := 127;
      T80.Encode (M, W, OK);
      Check (OK, "shapes: packet 80 encoded");
      L.Q_DIR := 1;
      L.N_ITER := ETCS_Variables.N_ITER_T (List'Length);
      for I in List'Range loop
         L.Q_NEWCOUNTRY_List (I - List'First + 1).NID_BG :=
           ETCS_Variables.NID_BG_T (List (I));
      end loop;
      T49.Encode (L, W, OK);
      Check (OK, "shapes: packet 49 encoded");
      return Message_Bytes (W);
   end MA_With_SH;

   procedure Scenario_Radio_SH_List is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, L2);
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 700));
      Add_Group (Group (30, 900));
      EVC_Test_Authority.Establish_Session;
      Run_X (15_000);
      Give_Radio_Message (1, MA_With_SH (400, (1 => 20)));
      Stand_X (500);
      Check (EVC_Core.Mode = M_FS,
             "shunting by radio: FS before the SH area of the mode profile");
      Run_X (60_000);
      Check (EVC_Core.Mode = M_SH,
             "shunting by radio: SH at the area of the mode profile "
             & "(4.6.3 [51]), got " & Mode_T'Image (EVC_Core.Mode));
      Run_X (80_000);
      Check (EVC_Core.Mode = M_SH,
             "4.4.8.1.1 b), 4.4.8.1.8: a group of the list sent by radio "
             & "with the MA passed in SH");
      Run_X (100_000);
      Check (EVC_Core.Mode = M_TR,
             "4.4.8.1.1 b), 4.4.8.1.8, 4.6.3 [52]: a group not in the list "
             & "sent by radio with the MA trips");
   end Scenario_Radio_SH_List;

end EVC_Test_Shapes;
