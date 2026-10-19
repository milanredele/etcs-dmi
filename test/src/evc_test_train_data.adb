--  ETCS on-board (EVC)
--  Phase E6, the Train Data rest (see the specification).

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P131;
with ETCS_Track_Packets.P140;
with ETCS_Train_Packets.P5;
with ETCS_Bits;
with ETCS_Track_Packets.P42;
with ETCS_Variables;
with EVC_Bytes;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Mission;
with EVC_Modes;
with EVC_Ports;           use EVC_Ports;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Test_Modes;
with EVC_Test_Support;    use EVC_Test_Support;
with EVC_Track_Description;
with EVC_Train_Data;
with Interfaces;          use Interfaces;

package body EVC_Test_Train_Data is

   package MCat renames ETCS_Message_Catalogue;
   package R renames EVC_Radio;
   use type R.Session_Ref_T;
   use type EVC_Bytes.Byte_Array;
   use type ETCS_Message.Status_T;
   use type ETCS_Variables.NID_PACKET_T;
   use type ETCS_Variables.M_AXLELOADCAT_T;

   function Now_T return Unsigned_64 is
     ((Unsigned_64 (EVC_Core.Time_Ms) / 10) mod 2**32);

   --  The DMI's frames: a driver action, an acknowledgement, a text
   --  entry, the Train Data (DMI Table 40: length m, 135 %, 160 km/h,
   --  NC_CDTRAIN 130 mm, a passenger train, the axle load category)
   function Action (Code : Natural; Arg : Natural := 0) return Byte_Array is
     (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION,
             (Byte (Code), Byte (Arg mod 256), Byte (Arg / 256))));

   function Ack_Of (Kind : Natural) return Byte_Array is
     (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, Byte (Kind), 0, 0, 0)));

   function Text_Entry (Kind : Natural; Text : String) return Byte_Array is
      B : Byte_Array (1 .. 2 + Text'Length);
   begin
      B (1) := Byte (Kind);
      B (2) := Byte (Text'Length);
      for I in Text'Range loop
         B (3 + I - Text'First) := Character'Pos (Text (I));
      end loop;
      return Frame (EVC_DMI_Port.MSG_DRIVER_DATA, B);
   end Text_Entry;

   function Train_Entry (Length_M : Natural; Axle_Load : Byte := 0)
     return Byte_Array
   is (Frame (EVC_DMI_Port.MSG_DRIVER_DATA,
              Byte_Array'(1 => 2)
              & U16 (Unsigned_16 (Length_M)) & U16 (135) & U16 (160)
              & Byte_Array'(1 => 2) & U16 (4) & Byte_Array'(Axle_Load, 0, 1)));

   procedure Send (Bytes : Byte_Array) is
   begin
      Input (DMI, Bytes);
      Stand_X (100);
   end Send;

   --  Message 24 referred to the group NID_BG (country 123) with packet
   --  131: the RBC transition D_M metres ahead to NID_RBC; without it,
   --  packet 42 with Q_RBC 1 for NID_RBC
   function M24 (NID_BG : Natural; Transition : Boolean;
                 N1, N2 : Natural) return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
   begin
      V (3) := Now_T;
      V (5) := 123;
      V (6) := Unsigned_64 (NID_BG);
      Start_Message (W, MCat.Track_M24, V);
      if Transition then
         ETCS_Track_Packets.P131.Encode
           ((NID_PACKET => 131, Q_DIR => 2, L_PACKET => 0, Q_SCALE => 1,
             D_RBCTR => ETCS_Variables.D_RBCTR_T (N1), NID_C => 5,
             NID_RBC => ETCS_Variables.NID_RBC_T (N2),
             NID_RADIO => 16#0077#, Q_SLEEPSESSION => 0), W, OK);
      else
         ETCS_Track_Packets.P42.Encode
           ((NID_PACKET => 42, Q_DIR => 2, L_PACKET => 0,
             Q_RBC => ETCS_Variables.Q_RBC_T (N1), NID_C => 5,
             NID_RBC => ETCS_Variables.NID_RBC_T (N2),
             NID_RADIO => 16#0077#, Q_SLEEPSESSION => 0), W, OK);
      end if;
      Check (OK, "train data: packet encoded");
      return Message_Bytes (W);
   end M24;

   --  3.5.3.7 b to e for session S: set up, message 32, 38
   procedure Establish (S : Natural) is
      Values : ETCS_Message.Value_Array := (others => 0);
   begin
      Give_Radio_Event (S, Connection_Set_Up);
      Stand;
      Values (3) := Now_T;
      Values (7) := 48;
      Give_Radio_Message (S, Message_Of (MCat.Track_M32, Values));
      Stand;
      Values (3) := Now_T;
      Values (7) := 0;
      Give_Radio_Message (S, Message_Of (MCat.Track_M38, Values));
      Stand;
   end Establish;

   procedure Scenario_Transition_Deleted is
      W  : Writer_T;
      OK : Boolean;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      ETCS_Track_Packets.P42.Encode
        ((NID_PACKET => 42, Q_DIR => 2, L_PACKET => 0, Q_RBC => 1,
          NID_C => 5, NID_RBC => 300, NID_RADIO => 16#0077#,
          Q_SLEEPSESSION => 0), W, OK);
      Finish_Carry (Track_N, 0, W, OK);
      Add_Group (Group (20, 300));
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SR, EVC_Modes.L2);
      Stand;
      Run_X (15_000);
      Establish (1);
      Give_Radio_Message (1, M24 (10, True, 200, 400));
      Stand;
      Establish (2);
      Send (Train_Entry (200));
      Give_Radio_Message (2, M24 (10, False, 1, 400));
      Stand;
      Check (R.Accepting = 2 and then EVC_Radio_Authority.Buffered = 1,
             "train data: a message of the Accepting RBC held (4.8.2.1 c)");
      Send (Train_Entry (200));
      Check (EVC_Radio_Authority.Buffered = 1,
             "train data: the same categories again: the held message "
             & "kept (3.18.3.7)");
      Send (Train_Entry (200, Axle_Load => 2));
      Stand_X (200);
      Check (EVC_Train_Data.Categories.Axle_Load = 2
             and then EVC_Radio_Authority.Buffered = 0,
             "train data: the axle load category changed at standstill: "
             & "the information of the RBC transition deleted "
             & "(3.18.3.7 b)");
   end Scenario_Transition_Deleted;

   procedure Scenario_Longer_Train is
      G0 : Natural;
   begin
      EVC_Test_Modes.Start_E4;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 4));
      Send (Train_Entry (200));
      Send (Text_Entry (1, "5678"));
      Send (Action (5));
      Send (Ack_Of (1));
      Add_Group (Group (10, 50));
      Carry (Track_N, 0, SSP ((1 => (0, 100, True))));
      Carry (Track_N, 0, Grad (((0, 0), (100, 5), (1_000, 0))));
      Carry (Track_N, 1, MA_Of ((1 => 1_000)));
      Speed_Cms := 500;
      while Train_Cm < 40_000 loop
         Step_X (500);
      end loop;
      Speed_Cms := 0;
      Stand_X (2_000);
      G0 := EVC_Track_Description.Gradients_Count;
      Send (Train_Entry (200));
      Stand_X (200);
      Check (G0 = 3 and then EVC_Track_Description.Gradients_Count = G0,
             "train data: the same length again: the gradients kept, got"
             & Img (G0) & Img (EVC_Track_Description.Gradients_Count));
      Send (Train_Entry (400));
      Stand_X (200);
      Check (EVC_Track_Description.Gradients_Count = G0 - 1,
             "train data: the train 200 m longer: the gradient section "
             & "ending 50 m in rear of the former min safe rear end "
             & "deleted (3.18.3.8), got"
             & Img (EVC_Track_Description.Gradients_Count));
   end Scenario_Longer_Train;

   --  The NID_OPERATIONAL of packet 5 in the first message 136 of the
   --  last cycle's RTM outputs (0: none)
   function TRN_In_136 return Unsigned_64 is
      M  : ETCS_Message.Message_T;
      St : ETCS_Message.Status_T;
      P  : ETCS_Train_Packets.P5.Packet_T;
      OK : Boolean;
   begin
      for N in 1 .. Radio_Outputs loop
         if not Radio_Output (N).Request
           and then Radio_Output (N).Kind = 136
         then
            Decode_Radio_Message (N, M, St);
            for I in 1 .. M.Count loop
               if St = ETCS_Message.Accepted and then M.Index (I).NID = 5
               then
                  declare
                     Rd : ETCS_Bits.Reader (ETCS_Message.Max_Bytes);
                  begin
                     ETCS_Message.Open_Packet (M, I, Rd);
                     ETCS_Train_Packets.P5.Decode (Rd, P, OK);
                     if OK then
                        return Unsigned_64 (P.NID_OPERATIONAL);
                     end if;
                  end;
               end if;
            end loop;
         end if;
      end loop;
      return 0;
   end TRN_In_136;

   procedure Scenario_RBC_TRN is
      W, W2 : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      ETCS_Track_Packets.P42.Encode
        ((NID_PACKET => 42, Q_DIR => 2, L_PACKET => 0, Q_RBC => 1,
          NID_C => 5, NID_RBC => 300, NID_RADIO => 16#0077#,
          Q_SLEEPSESSION => 0), W, OK);
      Finish_Carry (Track_N, 0, W, OK);
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SR, EVC_Modes.L2);
      Stand;
      Run_X (15_000);
      Establish (1);
      Input (DMI, Text_Entry (1, "5678"));
      Stand;
      Check (TRN_In_136 = 16#5678_FFFF#,
             "train data: the driver's train running number sent "
             & "(3.18.4.5.4)");
      V (3) := Now_T;
      V (5) := 123;
      V (6) := 10;
      Start_Message (W2, MCat.Track_M24, V);
      ETCS_Track_Packets.P140.Encode
        ((NID_PACKET => 140, Q_DIR => 2, L_PACKET => 0,
          NID_OPERATIONAL => 16#1234_FFFF#), W2, OK);
      Give_Radio_Message (1, Message_Bytes (W2));
      Stand;
      Check (OK and then EVC_Mission.TRN_From_RBC
             and then EVC_Mission.TRN.Length = 4
             and then EVC_Mission.TRN.Chars (1) = Character'Pos ('1')
             and then EVC_Mission.TRN.Chars (4) = Character'Pos ('4'),
             "train data: the train running number of packet 140 taken "
             & "while running (3.18.4.5.3)");
      Stand;
      Check (TRN_In_136 = 0,
             "train data: the RBC's train running number not sent back "
             & "(3.18.4.5.4.1)");
      Input (DMI, Text_Entry (1, "777"));
      Stand;
      Check (not EVC_Mission.TRN_From_RBC
             and then TRN_In_136 = 16#777F_FFFF#,
             "train data: the driver's new entry sent (3.18.4.5.4)");
   end Scenario_RBC_TRN;

end EVC_Test_Train_Data;
