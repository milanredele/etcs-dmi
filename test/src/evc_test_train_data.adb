--  ETCS on-board (EVC)
--  Phase E6, the Train Data rest (see the specification).

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P131;
with ETCS_Track_Packets.P140;
with ETCS_Train_Packets.P5;
with ETCS_Bits;
with ETCS_Track_Packets.P42;
with ETCS_Track_Packets.P41;
with ETCS_Variables;
with EVC_Bytes;
with EVC_Config;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Mission;
with EVC_Modes;
with EVC_Levels;
with EVC_Ports;           use EVC_Ports;
with EVC_Position;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Test_Authority;
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

   --  The Train Data of the fixed entry (DMI 11.3.9.6 a): the items of
   --  a train type and its index (MSG_DRIVER_DATA kind 2, 14 bytes)
   function Type_Entry (Index : Byte; Length_M, Brake, Speed : Natural;
                        Other : Natural) return Byte_Array
   is (Frame (EVC_DMI_Port.MSG_DRIVER_DATA,
              Byte_Array'(1 => 2)
              & U16 (Unsigned_16 (Length_M)) & U16 (Unsigned_16 (Brake))
              & U16 (Unsigned_16 (Speed))
              & Byte_Array'(1 => 0) & U16 (Unsigned_16 (Other))
              & Byte_Array'(0, 0, 1, Index)));

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

   --  3.5.3.7 b to e for session S: set up, message 32, 38; the first
   --  session acknowledges the Train Data sent after its message 32
   --  (message 8), as an RBC does before it orders a handover (4.8.3 [3]
   --  rejects the order before)
   procedure Establish (S : Natural) is
      Values : ETCS_Message.Value_Array := (others => 0);
      M      : ETCS_Message.Message_T;
      St     : ETCS_Message.Status_T;
   begin
      Give_Radio_Event (S, Connection_Set_Up);
      Stand;
      Values (3) := Now_T;
      Values (7) := 48;
      Give_Radio_Message (S, Message_Of (MCat.Track_M32, Values));
      Stand;
      for N in 1 .. Radio_Outputs loop
         Decode_Radio_Message (N, M, St);
         if S = 1 and then ETCS_Message."=" (St, ETCS_Message.Accepted)
           and then MCat."=" (M.Kind, MCat.Train_M129)
           and then Radio_Output (N).Session = 1
         then
            Values (3) := Now_T;
            Values (7) := M.Values (3);
            Give_Radio_Message (S, Message_Of (MCat.Track_M8, Values));
            Stand;
            exit;
         end if;
      end loop;
      Values := (others => 0);
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

   procedure Scenario_TIU_Categories is
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
      Input (TIU, (13, 1));
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
             "train data from the train interface: a message of the "
             & "Accepting RBC held (4.8.2.1 c)");
      Input (TIU, (13, 2));
      Stand_X (200);
      Check (EVC_Radio_Authority.Buffered = 1,
             "train data from the train interface: another configuration "
             & "without the categories (5.17.2.2 D1 -> A1): the held "
             & "message kept");
      Input (TIU, (13, 128 + 3));
      Stand_X (200);
      Check (EVC_Radio_Authority.Buffered = 0,
             "train data from the train interface: the categories changed "
             & "at standstill in SR, no MA of the RBC stored (5.17.2.2 D3, "
             & "D5 -> A1, A7): the information of the RBC transition "
             & "deleted (3.18.3.7 b)");
   end Scenario_TIU_Categories;

   --  An image of format version 5 with two sets: configuration 5, a
   --  freight train of 600 m at 100 km/h (other categories 2, axle load
   --  6, loading gauge 2), and configuration 6, a train of 400 m at 120
   --  km/h of the categories of Train_Entry
   procedure Load_Sets is
      T   : EVC_Config.Train_Set_Table_T := EVC_Config.No_Train_Sets;
      Img : EVC_Config.Max_Image_T;
      L   : Natural;
   begin
      T.Count := 2;
      T.Sets (1) :=
        (Configuration => 5,
         Driver_Key    => False,
         Data          =>
           (Name => "Freight         ", Name_Length => 7, Length_M => 600,
            Brake_Percentage => 80, Max_Speed_Kmh => 100,
            Cant_Deficiency => 2, Other => 2, Axle_Load => 6, Airtight => 0,
            Loading_Gauge => 2));
      T.Sets (2) :=
        (Configuration => 6,
         Driver_Key    => False,
         Data          =>
           (Name => "Long            ", Name_Length => 4, Length_M => 400,
            Brake_Percentage => 135, Max_Speed_Kmh => 120,
            Cant_Deficiency => 2, Other => 4, Axle_Load => 0, Airtight => 0,
            Loading_Gauge => 1));
      EVC_Config.Encode_V5 (EVC_Config.Default, EVC_Config.No_Gamma, T, Img,
                            L);
      EVC_Config.Load (Img (1 .. L));
      Check (EVC_Config.Train_Set_Count = 2,
             "train data from the train interface: the sets loaded");
   end Load_Sets;

   --  Standing N cycles: the messages 129 sent in them
   function Sent_129 (N : Positive) return Natural is
      M     : ETCS_Message.Message_T;
      St    : ETCS_Message.Status_T;
      Count : Natural := 0;
   begin
      for K in 1 .. N loop
         Stand;
         for I in 1 .. Radio_Outputs loop
            Decode_Radio_Message (I, M, St);
            if ETCS_Message."=" (St, ETCS_Message.Accepted)
              and then MCat."=" (M.Kind, MCat.Train_M129)
            then
               Count := Count + 1;
            end if;
         end loop;
      end loop;
      return Count;
   end Sent_129;

   procedure Scenario_TIU_Set is
      W  : Writer_T;
      OK : Boolean;
      N  : Natural;
      G0 : Natural;
   begin
      Load_Sets;
      Start_X;
      Add_Group (Group (10, 100));
      ETCS_Track_Packets.P42.Encode
        ((NID_PACKET => 42, Q_DIR => 2, L_PACKET => 0, Q_RBC => 1,
          NID_C => 5, NID_RBC => 300, NID_RADIO => 16#0077#,
          Q_SLEEPSESSION => 0), W, OK);
      Finish_Carry (Track_N, 0, W, OK);
      Add_Group (Group (20, 300));
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SR, EVC_Modes.L2);
      Input (TIU, (13, 1));
      Stand;
      Run_X (15_000);
      Establish (1);
      Give_Radio_Message (1, M24 (10, True, 200, 400));
      Stand;
      Establish (2);
      Send (Train_Entry (200));
      Give_Radio_Message (2, M24 (10, False, 1, 400));
      Stand;
      Check (R.Accepting = 2 and then EVC_Radio_Authority.Buffered = 1
             and then Natural (EVC_Train_Data.Length) = 20_000,
             "train data from the train interface: a message of the "
             & "Accepting RBC held (4.8.2.1 c), the driver's 200 m");
      Input (TIU, (13, 6));
      N := Sent_129 (10);
      Check (EVC_Train_Data.Valid and then Natural (EVC_Train_Data.Length) = 40_000
             and then Natural (EVC_Train_Data.Data.Max_Speed) = 3_333
             and then Natural (EVC_Train_Data.Categories.Other) = 4,
             "train data from the train interface: the configuration 6 "
             & "without the validation and the category bits (5.17.2.2 "
             & "D1 -> A1, A7): its set's 400 m and 120 km/h taken "
             & "(SUBSET-034 2.6.4.1)");
      Check (N = 2,
             "train data from the train interface: the changed set sent to "
             & "both RBCs of the established sessions (3.18.3.4), got"
             & Img (N));
      Check (EVC_Radio_Authority.Buffered = 1,
             "train data from the train interface: the set's categories "
             & "those before: the held message kept (3.18.3.7)");
      Input (TIU, (13, 7));
      N := Sent_129 (10);
      Check (Natural (EVC_Train_Data.Length) = 40_000 and then N = 0,
             "train data from the train interface: the configuration 7 "
             & "has no set: the Train Data unchanged, nothing sent "
             & "(SUBSET-034 2.6.4.4)");
      Input (TIU, (13, 5));
      Stand_X (200);
      Check (Natural (EVC_Train_Data.Length) = 60_000
             and then Natural (EVC_Train_Data.Categories.Axle_Load) = 6
             and then EVC_Radio_Authority.Buffered = 0,
             "train data from the train interface: the configuration 5, its "
             & "set of other categories, axle load and loading gauge, the "
             & "category bit not set: the categories changed at standstill "
             & "by the set, the information of the RBC transition deleted "
             & "(3.18.3.7 b)");
      --  3.18.3.8: a train of the driver's 200 m running, then the set
      --  of 400 m at standstill
      EVC_Test_Modes.Start_E4;
      Input (TIU, (13, 1));
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
      Input (TIU, (13, 6));
      Stand_X (200);
      Check (G0 = 3 and then Natural (EVC_Train_Data.Length) = 40_000
             and then EVC_Track_Description.Gradients_Count = G0 - 1,
             "train data from the train interface: the set of the "
             & "configuration 6 200 m longer than the driver's train: the "
             & "gradient section ending 50 m in rear of the former min safe "
             & "rear end deleted (3.18.3.8), got" & Img (G0)
             & Img (EVC_Track_Description.Gradients_Count));
      EVC_Config.Load (EVC_Config.Encode (EVC_Config.Default));
   end Scenario_TIU_Set;

   --  The TIU frame of an available safe consist length (EVC_Ports signal
   --  15): the lengths in front of the engine (nominal, min, max), then
   --  in rear of it, metres
   function Consist_Frame (F_Nom, F_Min, F_Max, R_Nom, R_Min, R_Max : Natural)
     return Byte_Array
   is
      L     : constant array (0 .. 5) of Natural :=
        (F_Nom, F_Min, F_Max, R_Nom, R_Min, R_Max);
      Frame : Byte_Array (1 .. TIU_SCL_Length) := (others => 0);
   begin
      Frame (1) := 15;
      Frame (2) := 1;
      for K in L'Range loop
         Frame (3 + 2 * K) := Byte (L (K) mod 256);
         Frame (4 + 2 * K) := Byte (L (K) / 256);
      end loop;
      return Frame;
   end Consist_Frame;

   --  3.18.3.8 second case: no valid Train Data (a length in front of the
   --  engine, 3.18.3.5 a), the safe consist length in rear of the engine
   --  increased (the orientation the active cab's)
   procedure Longer_Consist is
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
      --  no valid Train Data before the input, so that 4.6.3 [83] does
      --  not take the train to Stand-By, which deletes the gradients
      EVC_Train_Data.Invalidate;
      EVC_Core.Handle_Input (TIU, Consist_Frame (10, 9, 11, 100, 98, 102));
      Stand_X (300);
      G0 := EVC_Track_Description.Gradients_Count;
      Check (not EVC_Train_Data.Valid and then G0 = 3,
             "safe consist length: no valid Train Data, the gradients kept, "
             & "got" & Img (G0));
      EVC_Core.Handle_Input (TIU, Consist_Frame (10, 9, 11, 300, 298, 302));
      Stand_X (300);
      Check (EVC_Track_Description.Gradients_Count = G0 - 1,
             "safe consist length: 200 m longer in rear of the engine "
             & "without valid Train Data: the gradient section ending "
             & "in rear of the former min safe rear end deleted (3.18.3.8), "
             & "got" & Img (EVC_Track_Description.Gradients_Count));
   end Longer_Consist;

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
      Longer_Consist;
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

   procedure Scenario_Engine_Length is
      Engine : constant Natural :=
        Natural (EVC_Config.Current.Train.Engine_Length);
      function Length return Natural is
        (if EVC_Position.Train_Length_Known
         then Natural (EVC_Position.Length_Of_Train) else 0);
   begin
      EVC_Test_Modes.Start_E4;
      Stand_X (200);
      Check (Length = Engine,
             "engine length: SB without valid Train Data (4.4.7.1.6), got"
             & Img (Length));
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 4));
      Send (Train_Entry (300));
      Stand_X (200);
      Check (Length = 30_000,
             "engine length: SB with valid Train Data, their length "
             & "(4.4.7.1.6 a), got" & Img (Length));
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SH, EVC_Modes.L1);
      Stand_X (200);
      Check (Length = Engine,
             "engine length: SH, the engine's (4.4.8.1.3), got"
             & Img (Length));
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_NL, EVC_Modes.L1);
      Stand_X (200);
      Check (Length = Engine,
             "engine length: NL, the engine's (4.4.15.1.3), got"
             & Img (Length));
   end Scenario_Engine_Length;

   procedure Scenario_Released_TRN is
      P : ETCS_Track_Packets.P41.Packet_T;
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_FS, EVC_Modes.L1);
      Add_Group (Group (10, 100));
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_LEVELTR := 300;
      P.M_LEVELTR := ETCS_Variables.M_LEVELTR_Level_2;
      P.Has_NID_NTC := False;
      P.L_ACKLEVELTR := 0;
      P.N_ITER := 0;
      Carry (Track_N, 0, P);
      EVC_Test_Authority.Establish_Session;
      Run_X (15_000);
      Give_Radio_Message
        (1, EVC_Test_Authority.Radio_MA_TRN (10, (600, 400),
                                             16#4321_FFFF#));
      Stand_X (100);
      Check (EVC_Radio_Authority.Buffered = 1
             and then not EVC_Mission.TRN_From_RBC,
             "train data: packet 140 of an MA with level 2 announced kept "
             & "in the transition buffer (4.8.5.1), not taken yet");
      for X in 151 .. 460 loop
         Run_X (Integer_64 (X) * 100, 100);
      end loop;
      Check (EVC_Modes."=" (EVC_Levels.Level, EVC_Modes.L2)
             and then EVC_Mission.TRN_From_RBC
             and then EVC_Mission.TRN.Length = 4
             and then EVC_Mission.TRN.Chars (1) = Character'Pos ('4'),
             "train data: packet 140 of the released message taken "
             & "(3.18.4.5.3, 4.8.5.5)");
   end Scenario_Released_TRN;

   procedure Scenario_Train_Type is
      function Length return Natural is
        (Natural (EVC_Train_Data.Data.Length));
   begin
      EVC_Test_Modes.Start_E4;
      Stand_X (200);
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 4));
      --  the passenger type of EVC_Config.Default_Train_Types
      Input (DMI, Type_Entry (2, 200, 135, 160, 4));
      Cycle_X;
      --  MSG_STORED_VALUES: train_valid at 40, the type at 70 (after the
      --  header of 5 and the payload's 64 bytes before it)
      Check (DMI_Byte (EVC_DMI_Port.MSG_STORED_VALUES, 40) = 1
             and then DMI_Byte (EVC_DMI_Port.MSG_STORED_VALUES, 70) = 2,
             "train type: MSG_STORED_VALUES carries the type in force 2 "
             & "(DMI Table 44 item 3), got"
             & DMI_Byte (EVC_DMI_Port.MSG_STORED_VALUES, 70)'Image);
      Stand_X (100);
      Check (EVC_Train_Data.Valid and then Length = 20_000
             and then EVC_Train_Data.Type_In_Force = 2,
             "train type: the passenger type's Train Data in force with "
             & "their type (DMI 11.3.9.6 a, 3.18.3.2.1), length"
             & Img (Length) & " type"
             & Img (EVC_Train_Data.Type_In_Force));
      --  the short form, without the type: entered item by item
      Send (Train_Entry (300));
      Check (EVC_Train_Data.Valid and then Length = 30_000
             and then EVC_Train_Data.Type_In_Force = 0
             and then DMI_Byte (EVC_DMI_Port.MSG_STORED_VALUES, 70) /= 2,
             "train type: an entry item by item has no type in force, type"
             & Img (EVC_Train_Data.Type_In_Force));
      --  an index above the installation's types: refused
      Send (Type_Entry (3, 200, 135, 160, 4));
      Check (Length = 30_000 and then EVC_Train_Data.Type_In_Force = 0,
             "train type: an index above the types is refused, length"
             & Img (Length));
      --  the passenger data named as the locomotive: refused
      Send (Type_Entry (1, 200, 135, 160, 4));
      Check (Length = 30_000 and then EVC_Train_Data.Type_In_Force = 0,
             "train type: data differing from the type's are refused, "
             & "length" & Img (Length));
      --  the locomotive type itself
      Send (Type_Entry (1, 20, 100, 80, 0));
      Check (Length = 2_000 and then EVC_Train_Data.Type_In_Force = 1,
             "train type: the locomotive type in force, length"
             & Img (Length) & " type"
             & Img (EVC_Train_Data.Type_In_Force));
   end Scenario_Train_Type;

   procedure Scenario_Driver_ID_Characters is
      use type EVC_Mission.Data_Status_T;
      --  the stored driver ID is Text
      function Stored (Text : String) return Boolean is
        (EVC_Mission.Driver_ID_Status = EVC_Mission.Valid
         and then EVC_Mission.Driver_ID.Length = Text'Length
         and then (for all I in Text'Range =>
                     EVC_Mission.Driver_ID.Chars (I - Text'First + 1)
                     = Character'Pos (Text (I))));
   begin
      EVC_Test_Modes.Start_E4;
      Stand_X (200);
      Send (Text_Entry (0, "0123456789abcdef"));
      Check (Stored ("0123456789abcdef"),
             "driver ID: 16 characters from 0 to 9 and a to z taken "
             & "(A.3.11)");
      Send (Text_Entry (0, "xyz9"));
      Check (Stored ("xyz9"), "driver ID: changed at standstill");
      Send (Text_Entry (0, "0123456789abcdefg"));
      Check (Stored ("xyz9"),
             "driver ID: 17 characters refused, the stored one kept "
             & "(A.3.11)");
      Send (Text_Entry (0, "ABC1"));
      Check (Stored ("xyz9"),
             "driver ID: capital letters refused (A.3.11: a to z)");
      Send (Text_Entry (0, "ab 12"));
      Check (Stored ("xyz9"), "driver ID: a space refused (A.3.11)");
      Send (Text_Entry (0, "ab-12"));
      Check (Stored ("xyz9"),
             "driver ID: a sign refused (A.3.11: 0 to 9 and a to z)");
   end Scenario_Driver_ID_Characters;

end EVC_Test_Train_Data;
