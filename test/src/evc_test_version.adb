--  ETCS on-board (EVC)
--  Phase E5, the system version of the RBC (see the specification).

with ETCS_Bits;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P2;
with ETCS_Track_Packets.P3;
with ETCS_Track_Packets.P3_V1_0;
with ETCS_Telegram;
with ETCS_Track_Packets.P41;
with ETCS_Track_Packets.P65;
with ETCS_Train_Packets.P2;
with ETCS_Variables;
with EVC_Config;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Modes;           use EVC_Modes;
with EVC_National_Values;
with EVC_Ports;           use EVC_Ports;
with EVC_Position;
with EVC_Radio;
with EVC_Received;
with EVC_Stored_Information;
with EVC_Supervision_Input;
with EVC_System_Version;
with EVC_Track_Description;
with EVC_Train_Data;
with EVC_Test_Modes;
with EVC_Test_Support;    use EVC_Test_Support;
with Interfaces;          use Interfaces;

package body EVC_Test_Version is

   package MCat renames ETCS_Message_Catalogue;
   package R renames EVC_Radio;
   package SV renames EVC_System_Version;
   use type ETCS_Message.Status_T;
   use type ETCS_Variables.M_VERSION_T;
   use type ETCS_Variables.N_ITER_T;
   use type ETCS_Train_Packets.P2.M_VERSION_Array;
   use type R.Session_State_T;

   --  T_TRAIN of the on-board time now (10 ms, 7.5.1.152)
   function Now_T return Unsigned_64 is
     ((Unsigned_64 (EVC_Core.Time_Ms) / 10) mod 2**32);

   --  A track to train message of Kind, T_TRAIN now, variable I set to V
   function Msg (Kind : MCat.Known_Message_T;
                 I    : Positive := 5;
                 V    : Unsigned_64 := 0) return Byte_Array
   is
      Values : ETCS_Message.Value_Array := (others => 0);
   begin
      Values (3) := Now_T;
      Values (I) := V;
      return Message_Of (Kind, Values);
   end Msg;

   --  The RTM output that is the message NID on session 1 (0: none)
   function Output_Of (NID : Natural) return Natural is
   begin
      for N in 1 .. Radio_Outputs loop
         if not Radio_Output (N).Request
           and then Radio_Output (N).Session = 1
           and then Radio_Output (N).Kind = NID
         then
            return N;
         end if;
      end loop;
      return 0;
   end Output_Of;

   --  The DMI's frames (dmi_protocol.ads): a driver action, a text entry,
   --  the RBC data (kind 5: choice, RBC ID u32, the phone number)
   function Action (Code : Natural; Arg : Natural := 0) return Byte_Array is
     (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION,
             (Byte (Code), Byte (Arg mod 256), Byte (Arg / 256))));

   function Text_Entry (Kind : Natural; Text : String) return Byte_Array is
      Res : Byte_Array (1 .. 2 + Text'Length);
   begin
      Res (1) := Byte (Kind);
      Res (2) := Byte (Text'Length);
      for I in Text'Range loop
         Res (3 + I - Text'First) := Character'Pos (Text (I));
      end loop;
      return Frame (EVC_DMI_Port.MSG_DRIVER_DATA, Res);
   end Text_Entry;

   function RBC_Entry (Id : Unsigned_32; Phone : String) return Byte_Array
   is
      Res : Byte_Array (1 .. 23) := (others => 0);
   begin
      Res (1) := 5;
      Res (3) := Byte (Id and 255);
      Res (4) := Byte (Shift_Right (Id, 8) and 255);
      Res (5) := Byte (Shift_Right (Id, 16) and 255);
      Res (6) := Byte (Shift_Right (Id, 24));
      Res (7) := Byte (Phone'Length);
      for I in Phone'Range loop
         Res (8 + I - Phone'First) := Character'Pos (Phone (I));
      end loop;
      return Frame (EVC_DMI_Port.MSG_DRIVER_DATA, Res);
   end RBC_Entry;

   procedure Send (Bytes : Byte_Array) is
   begin
      Input (DMI, Bytes);
      Stand;
   end Send;

   --  A level 2 start of mission up to the session with RBC 300: the
   --  driver ID, level 2, the RBC contact, the safe radio connection set
   --  up, then the system version V of the RBC (message 32)
   procedure Open_With (V : Unsigned_64) is
   begin
      EVC_Config.Set_Radio_For_Test ((Sessions => 1, Engine_Id => 76_000, others => <>));
      EVC_Test_Modes.Start_E4;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 5));
      Send (RBC_Entry (5 * 16_384 + 300, "0077"));
      Give_Radio_Event (1, Connection_Set_Up);
      Stand;
      Give_Radio_Message (1, Msg (MCat.Track_M32, 7, V));
      Stand;
   end Open_With;

   --  The packet 2 of the 159 sent (7.4.3.3)
   function Envelope_Sent return ETCS_Train_Packets.P2.Packet_T is
      N  : constant Natural := Output_Of (159);
      M  : ETCS_Message.Message_T;
      St : ETCS_Message.Status_T;
      Rd : ETCS_Bits.Reader (ETCS_Message.Max_Bytes);
      P  : ETCS_Train_Packets.P2.Packet_T;
      OK : Boolean;
   begin
      if N = 0 then
         return P;
      end if;
      Decode_Radio_Message (N, M, St);
      if St /= ETCS_Message.Accepted or else M.Count /= 1 then
         return P;
      end if;
      ETCS_Message.Open_Packet (M, 1, Rd);
      ETCS_Train_Packets.P2.Decode (Rd, P, OK);
      return P;
   end Envelope_Sent;

   procedure Scenario_Version_Negotiation is
      P : ETCS_Train_Packets.P2.Packet_T;
   begin
      --  2.1: compatible (6.4.2.2), 159 with the envelope, the RBC's X
      --  operated in level 2 (3.17.2.8 b)
      Open_With (2 * 16 + 1);
      P := Envelope_Sent;
      Check (Output_Of (159) > 0 and then Output_Of (154) = 0
             and then P.M_VERSION = 48 and then P.N_ITER = 6
             and then P.M_VERSION_List (1 .. 6) = (35, 34, 33, 32, 17, 16),
             "version: RBC 2.1 compatible: 159 with packet 2, 3.0 then "
             & "2.3, 2.2, 2.1, 2.0, 1.1, 1.0 (3.5.3.7 d, 6.4.2.2, 7.4.3.3)");
      Check (R.Info (1).State = R.Established
             and then SV.Operated = 2 and then SV.By_RBC
             and then SV.Operated_Version = 16#23#,
             "version: in level 2 the RBC's X operated at once, as 2.3 "
             & "(3.17.2.8 b, 3.17.2.1.1)");
      Stand_X (32_000);
      Check (R.Info (1).State = R.Established and then Output_Of (159) = 0
             and then Output_Of (156) = 0,
             "version: no acknowledgement awaited from a 2.1 RBC, the "
             & "session kept (6.5.2.2.2, 6.5.1.2.1.4: 3.5.3.7.4 not "
             & "applied)");

      --  1.1: compatible, X = 1 operated
      Open_With (1 * 16 + 1);
      Check (Output_Of (159) > 0 and then SV.Operated = 1
             and then SV.Operated_Version = 16#11#,
             "version: RBC 1.1 compatible: 159, X = 1 operated "
             & "(3.17.2.1, 6.4.2.2)");

      --  2.3: the acknowledgement of 3.5.3.7 e) awaited
      Open_With (2 * 16 + 3);
      Stand_X (32_000);
      Check (R.Info (1).State /= R.Established,
             "version: RBC 2.3 without acknowledgement: 159 again, then "
             & "the session terminated (3.5.3.7.4, .4.1; 6.5.2.2.2 not "
             & "for 2.3)");

      --  0.0: no compatible version: 154, the driver informed, the
      --  session terminated (3.5.3.7 d) second bullet); the version last
      --  operated stays (3.17.2.8 d, e: the RBC no longer takes
      --  precedence)
      Open_With (2 * 16 + 2);
      Give_Radio_Message (1, Msg (MCat.Track_M32, 7, 0));
      Stand;
      Check (Output_Of (154) > 0 and then R.Info (1).State = R.Terminating,
             "version: RBC 0.0 in the session (3.5.4.7) not compatible: "
             & "154, terminated (3.5.3.7 d, 3.17.3.7)");
      Stand;
      Check (not SV.By_RBC and then SV.Operated = 2,
             "version: no session, the version last operated (2) kept "
             & "(3.17.2.8 d, e)");
      EVC_Core.Initialise;
   end Scenario_Version_Negotiation;

   procedure Scenario_Version_Retained is
   begin
      Open_With (2 * 16 + 2);
      Check (SV.Operated = 2, "version: RBC 2.2, X = 2 operated");
      EVC_Core.Power_Up;
      Check (SV.Operated = 2 and then not SV.By_RBC,
             "version: the operated version kept over No Power "
             & "(3.17.2.9)");
      EVC_Core.Initialise;
      EVC_Core.Power_Up;
      Check (SV.Operated = SV.Highest_X,
             "version: the store lost: the highest supported version, "
             & "3 (3.17.2.9.1)");
   end Scenario_Version_Retained;

   --  A balise group NID at At_M metres whose telegrams carry M_VERSION
   --  Tel, with a system version order (packet 2) to Order when Ordered
   procedure Add_Version_Group (NID : Natural; At_M : Integer_64;
                                Tel : ETCS_Variables.M_VERSION_T;
                                Ordered : Boolean := False;
                                Order : ETCS_Variables.M_VERSION_T := 0)
   is
      P  : ETCS_Track_Packets.P2.Packet_T;
      W  : Writer_T;
      OK : Boolean;
   begin
      Add_Group (Group (NID, At_M));
      Version (Track_N) := Tel;
      if Ordered then
         P.Q_DIR := 2;
         P.L_PACKET := 0;
         P.M_VERSION := Order;
         ETCS_Track_Packets.P2.Encode (P, W, OK);
         Finish_Carry (Track_N, 0, W, OK);
      end if;
   end Add_Version_Group;

   --  Packet 41: an immediate order to the level L alone
   function Level_Now (L : ETCS_Variables.M_LEVELTR_T)
     return ETCS_Track_Packets.P41.Packet_T
   is
      P : ETCS_Track_Packets.P41.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_LEVELTR := ETCS_Variables.D_LEVELTR_Now_The_Level_Transition;
      P.M_LEVELTR := L;
      P.Has_NID_NTC := False;
      P.NID_NTC := 0;
      P.L_ACKLEVELTR := 0;
      P.N_ITER := 0;
      return P;
   end Level_Now;

   --  3.17.2.8.1, 3.17.2.8.2: a switch to and from level 2 ordered by
   --  a group of 3.0, the session with an RBC of 2.1 established
   procedure Version_Level_Switch is
   begin
      Open_With (16#21#);
      EVC_Core.Set_Mode_For_Test (M_SR, L2);
      Stand_X (100);
      Add_Version_Group (1, 50, 16#30#);
      Carry (Track_N, 0, Level_Now (ETCS_Variables.M_LEVELTR_Level_1));
      Check (SV.By_RBC and then SV.Operated = 2,
             "version: in level 2 the RBC's X 2 governs (3.17.2.8 b)");
      Run_X (10_000);
      Check (EVC_Core.Level = L1 and then not SV.By_RBC
             and then SV.Operated = 3,
             "version: the group of 3.0 that orders level 1 now: its X "
             & "judged at once, 3 operated (3.17.2.8.2, 3.17.2.3)");

      Open_With (16#21#);
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      Stand_X (100);
      Add_Version_Group (1, 50, 16#30#);
      Carry (Track_N, 0, Level_Now (ETCS_Variables.M_LEVELTR_Level_2));
      Check (not SV.By_RBC and then SV.Operated = 2,
             "version: in level 1 the session's RBC does not govern, the "
             & "version last operated kept (3.17.2.8 d)");
      Run_X (10_000);
      Check (EVC_Core.Level = L2 and then SV.By_RBC
             and then SV.Operated = 2,
             "version: the group of 3.0 that orders level 2 now: the "
             & "RBC's X 2 operated, not the group's 3 (3.17.2.8 a, "
             & "3.17.2.8.1)");
      EVC_Core.Initialise;
   end Version_Level_Switch;

   --  3.17.2.3, 3.17.3.5 d): a telegram of 4.0, above the envelope, is
   --  ignored: the X of the group is that of its other telegram
   procedure Version_Ignored is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      Stand_X (100);
      Add_Version_Group (1, 50, 16#30#, True, 16#21#);
      Add_Version_Group (2, 150, 16#30#);
      Version_Second (Track_N) := 16#40#;
      Run_X (10_000);
      Check (SV.Operated = 2, "version: ordered to 2.1 (3.17.2.5)");
      Run_X (20_000);
      Check (SV.Operated = 3,
             "version: a group of a 3.0 and a 4.0 telegram: the 4.0 one "
             & "ignored (3.17.3.5 d), the group's X is 3 and raises the "
             & "operated X (3.17.2.3)");
      EVC_Core.Initialise;
   end Version_Ignored;

   --  3.17.2.3, 3.17.2.5, 3.17.2.7, 3.17.2.8 d): the operated version
   --  in relation to the balise groups, in level 1
   procedure Scenario_Version_Balise_Groups is
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      Stand_X (100);
      Add_Version_Group (1, 50, 16#21#);
      Add_Version_Group (2, 150, 16#30#, True, 16#21#);
      Add_Version_Group (3, 250, 16#21#, True, 16#10#);
      Add_Version_Group (4, 350, 16#21#);
      Add_Version_Group (5, 450, 16#30#);
      Run_X (10_000);
      Check (SV.Operated = 3,
             "version: a group of 2.1 does not lower the operated 3.0 "
             & "(3.17.2.3: only a higher X)");
      Run_X (20_000);
      Check (SV.Operated = 2,
             "version: the order of packet 2 to 2.1 in a group of 3.0 "
             & "executed at once (3.17.2.5)");
      Run_X (30_000);
      Check (SV.Operated = 1,
             "version: the order to 1.0 in a group of 2.1 executed, "
             & "lower than the group's X (3.17.2.5, 3.17.2.5.1)");
      Run_X (40_000);
      Check (SV.Operated = 2,
             "version: after the order, a group of 2.1 raises the operated "
             & "X to 2 (3.17.2.3 applies again, 3.17.2.5)");
      Run_X (50_000);
      Check (SV.Operated = 3,
             "version: a group of 3.0 raises it to 3 (3.17.2.3)");
      SV.Take_Balise_Group (3, True, 16#40#, False);
      Check (SV.Operated = 3,
             "version: an order to an X outside the envelope leaves the "
             & "operated version unchanged (3.17.2.7)");
      SV.Take_Balise_Group (1, False, 0, True);
      Check (SV.Operated = 1,
             "version: at a country mismatch the group's X is operated, "
             & "even lower (3.17.2.6)");
      SV.Follow (True, True, 16#22#);
      SV.Take_Balise_Group (3, True, 16#10#, False);
      Check (SV.Operated = 2,
             "version: while the RBC's X governs, neither the groups nor "
             & "their orders change it (3.17.2.8)");
      SV.Follow (False, False, 16#22#);
      SV.Take_Balise_Group (3, False, 0, False);
      Check (SV.Operated = 3,
             "version: out of level 2 the control by the groups applies "
             & "again (3.17.2.8 d)");
      Version_Ignored;
      Version_Level_Switch;
   end Scenario_Version_Balise_Groups;

   --  3.17.2.6, 3.17.3.4.1: the country check of the operated version
   --  judged against a set of national values applicable immediately
   --  carried by the same group message, in level 1
   procedure Scenario_Version_Country_Set is
      use type ETCS_Variables.NID_C_T;
      P : ETCS_Track_Packets.P3.Packet_T;
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      Stand_X (100);
      P.Q_DIR := 2;
      P.Q_SCALE := 1;
      P.D_VALIDNV := 32_767;
      P.NID_C := 123;
      Add_Version_Group (1, 50, 16#30#);
      Carry (Track_N, 0, P);
      Add_Version_Group (2, 150, 16#21#);
      Country (Track_N) := 77;
      P.NID_C := 5;
      P.N_ITER := 1;
      P.NID_C_List (1) := 77;
      Carry (Track_N, 0, P);
      Add_Version_Group (3, 250, 16#21#);
      Country (Track_N) := 9;
      Run_X (10_000);
      Check (SV.Operated = 3
             and then EVC_National_Values.Current.Countries (1) = 123,
             "version: the set of 123 applicable now, no mismatch");
      Run_X (20_000);
      Check (SV.Operated = 3,
             "version: a group of country 77 carrying an immediate set "
             & "that lists 77 is no country mismatch (3.17.2.6, 3.17.3.4.1)");
      Check (EVC_National_Values.Current.Countries (2) = 77,
             "version: the set of the group of 77 in use");
      Run_X (30_000);
      Check (SV.Operated = 2,
             "version: a group of country 9 without a set is a mismatch, "
             & "its X operated (3.17.2.6)");
   end Scenario_Version_Country_Set;

   --  The rules of the cycle as EVC_Core.Modes computes them
   function Rules return SV.Rules_T is
     (SV.Rules_Of (SV.Operated, R.Supervising_Version_Known,
                   (if R.Supervising_Version_Known
                    then R.Info (R.Session_T (R.Supervising)).Version
                    else 0)));

   procedure Scenario_Version_Rules is
      use type SV.Rules_T;
   begin
      Check (SV.Below (16#22#, 2, 3) and then not SV.Below (16#23#, 2, 3)
             and then SV.Below (16#11#, 2, 2)
             and then SV.Below (16#21#, 2, 2)
             and then not SV.Below (16#22#, 2, 2)
             and then not SV.Below (16#30#, 2, 3),
             "version rules: 2.2 and 1.1 below 2.3, 2.1 below 2.2, 2.2 "
             & "not, 3.0 not below 2.3 (7.5.1.79)");

      --  X = 1 by a group's order in level 1, no RBC: every rule of 6.6.2
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      Stand_X (100);
      Add_Version_Group (1, 50, 16#30#, True, 16#11#);
      Run_X (10_000);
      Check (SV.Operated = 1 and then not R.Supervising_Version_Known
             and then Rules = (others => True),
             "version rules: 1.1 ordered by a group (3.17.2.5), every "
             & "exception of 6.6.2 applies (6.6.2.1.1 to 6.6.2.3.7)");
      EVC_Core.Initialise;

      --  X = 2 with an RBC of 2.1 supervising: 6.6.4.1.1 to 6.6.4.3.1
      Open_With (16#21#);
      Check (SV.Operated = 2
             and then Rules = (Engine_Front | TSR_Estimated
                               | ASP_Lower_Categories
                               | No_Supervised_Manoeuvre => True,
                               others => False),
             "version rules: an RBC of 2.1 supervising, X = 2: the engine's "
             & "front, the TSR at its estimated location, the ASP of the "
             & "lower categories, no Supervised Manoeuvre (6.6.4.1.1 to "
             & "6.6.4.3.1)");

      --  X = 2 with an RBC of 2.3: only the two rules of X = 2 itself
      Open_With (16#23#);
      Check (SV.Operated = 2
             and then Rules = (TSR_Estimated | ASP_Lower_Categories => True,
                               others => False),
             "version rules: an RBC of 2.3 supervising: the TSR and ASP "
             & "rules of X = 2 alone (6.6.4.1.2, 6.6.4.1.3; 6.6.4.1.1, "
             & ".2.1, .3.1 only for 2.0 .. 2.2)");

      --  3.0 everywhere: none
      Open_With (16#30#);
      Check (SV.Operated = 3 and then Rules = (others => False),
             "version rules: an RBC of 3.0 supervising, X = 3: no rule of "
             & "chapter 6");

      --  6.6.3.4.1.2: an RBC of 1.1, no acknowledgement of the 159
      --  awaited, the session kept
      Open_With (16#11#);
      Stand_X (32_000);
      Check (R.Info (1).State = R.Established and then Output_Of (156) = 0
             and then SV.Operated = 1,
             "version rules: no acknowledgement awaited from an RBC of 1.1, "
             & "the session kept (6.6.3.4.1.2: 3.5.3.7.4, .4.1 not applied)");
      EVC_Core.Initialise;
   end Scenario_Version_Rules;

   --  3.17.3.5 c), 6.6.3.1: a group of 1.0 carrying a packet 5, whose
   --  layout is that of 4.0.0, and a packet 3 in its layout of X = 1:
   --  the telegrams are read, the linking taken, the national values of
   --  the old layout not (their translation, 6.6.3.2, not built)
   procedure Scenario_Version_Telegram_Read is
      use type EVC_National_Values.Set_T;
      P      : ETCS_Track_Packets.P3_V1_0.Packet_T;
      W      : Writer_T;
      OK     : Boolean;
      Before : constant EVC_National_Values.Set_T :=
        EVC_National_Values.Current;
      Refused  : Natural;
      Accepted : Natural;
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (M_SR, L1);
      Stand_X (100);
      Refused :=
        EVC_Received.Telegram_Count (ETCS_Telegram.Unsupported_Version);
      Accepted := EVC_Received.Telegram_Count (ETCS_Telegram.Accepted);
      Add_Group (With_Links (Group (1, 50), Link_To ((1 => 100), (1 => 2))));
      Version (Track_N) := 16#10#;
      P.Q_DIR := 2;
      P.Q_SCALE := 1;
      P.D_VALIDNV := 32_767;
      P.V_NVSHUNT := 6;
      ETCS_Track_Packets.P3_V1_0.Encode (P, W, OK);
      Finish_Carry (Track_N, 0, W, OK);
      Add_Group (Group (2, 150));
      Version (Track_N) := 16#10#;
      Run_X (10_000);
      Check (EVC_Received.Telegram_Count (ETCS_Telegram.Unsupported_Version)
             = Refused
             and then EVC_Received.Telegram_Count (ETCS_Telegram.Accepted)
                      = Accepted + 2
             and then EVC_Received.Last_Telegram.Header.M_VERSION = 16#10#,
             "version telegram: the two telegrams of 1.0 read, not refused "
             & "(3.17.3.5 c)");
      Check (EVC_Position.Linking.Stored
             and then Natural (EVC_Position.Linking.Ref_Id.NID_BG) = 1,
             "version telegram: the linking of the group of 1.0 taken "
             & "(6.6.3.1.2: packet 5 of X = 1 is that of 4.0.0)");
      Check (EVC_National_Values.Current = Before,
             "version telegram: the national values of the layout of "
             & "X = 1 not taken (6.6.3.2: their translation not built)");
      Check (SV.Operated = 3,
             "version telegram: a group of 1.0 does not lower the operated "
             & "3.0 (3.17.2.3: only a higher X)");
      EVC_Core.Initialise;
   end Scenario_Version_Telegram_Read;

   --  The start and end (cm along the line) of the MRSP's segment of
   --  40 km/h after a TSR of 100 m at 300 m from the first group of two,
   --  the train in FS past the second (a relocation by 3.6.4.2.5 c), the
   --  first group ordering 2.0 when Order
   procedure TSR_Run (Order : Boolean; S, F : out Integer_64) is
      P : ETCS_Track_Packets.P65.Packet_T;
   begin
      S := -1;
      F := -1;
      Start_X;
      Add_Version_Group (10, 100, 16#30#, Order, 16#20#);
      Add_Version_Group (20, 200, (if Order then 16#20# else 16#30#));
      Carry (1, 0, SSP ((1 => (0, 160, False))));
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.NID_TSR := 9;
      P.D_TSR := 300;
      P.L_TSR := 100;
      P.Q_FRONT := 1;
      P.V_TSR := 8;
      Carry (1, 0, P);
      Run_X (25_000);
      declare
         Snap : constant EVC_Supervision_Input.Snapshot_T :=
           EVC_Stored_Information.Current;
      begin
         for K in 1 .. Snap.MRSP.Count loop
            if Snap.MRSP.Segments (K).Speed = 1_111
              and then K < Snap.MRSP.Count
            then
               S := Integer_64 (Snap.MRSP.Segments (K).Start);
               F := Integer_64 (Snap.MRSP.Segments (K + 1).Start);
            end if;
         end loop;
      end;
   end TSR_Run;

   procedure Scenario_Version_TSR is
      S3, F3, S2, F2 : Integer_64;
   begin
      TSR_Run (False, S3, F3);
      Check (SV.Operated = 3 and then S3 > 0 and then S3 < 40_000
             and then F3 > 50_000,
             "version TSR: X = 3, from its max start to its min end "
             & "(3.6.4.2.4 Table 2a)");
      TSR_Run (True, S2, F2);
      Check (SV.Operated = 2 and then Rules.TSR_Estimated
             and then S2 = 40_000 and then F2 = 50_000,
             "version TSR: X = 2 ordered by a group, from its estimated "
             & "start to its estimated end in FS (6.6.4.1.2, 6.6.2.1.3)");
      EVC_Core.Initialise;
   end Scenario_Version_TSR;

   --  The ASP taken from a group's packet 51 (the first group orders 2.0
   --  when Order) by a train of category C2 (4): a first element of
   --  A 60, B1 40, C2 50 and C4 30 km/h, a second of A 60 alone; Count
   --  and V the ASP elements stored and the first one's speed (cm/s)
   procedure ASP_Run (Order : Boolean; Count, V : out Natural) is
      P   : T51.Packet_T;
      Cat : EVC_Train_Data.Categories_T;
   begin
      Start_X;
      Cat := EVC_Train_Data.Categories;
      Cat.Axle_Load := 4;
      EVC_Train_Data.Set (EVC_Train_Data.Data, Cat);
      Add_Version_Group (10, 100, 16#30#, Order, 16#20#);
      Add_Version_Group (20, 200, (if Order then 16#20# else 16#30#));
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.Q_TRACKINIT := 0;
      P.Has_D_AXLELOAD := True;
      P.D_AXLELOAD := 200;
      P.L_AXLELOAD := 100;
      P.Q_FRONT := 1;
      P.N_ITER := 4;
      P.M_AXLELOADCAT_List (1) := (M_AXLELOADCAT => 0, V_AXLELOAD => 12);
      P.M_AXLELOADCAT_List (2) := (M_AXLELOADCAT => 2, V_AXLELOAD => 8);
      P.M_AXLELOADCAT_List (3) := (M_AXLELOADCAT => 4, V_AXLELOAD => 10);
      P.M_AXLELOADCAT_List (4) := (M_AXLELOADCAT => 6, V_AXLELOAD => 6);
      P.N_ITER_2 := 1;
      P.D_AXLELOAD_List (1).D_AXLELOAD := 300;
      P.D_AXLELOAD_List (1).L_AXLELOAD := 100;
      P.D_AXLELOAD_List (1).Q_FRONT := 1;
      P.D_AXLELOAD_List (1).N_ITER := 1;
      P.D_AXLELOAD_List (1).M_AXLELOADCAT_List (1) :=
        (M_AXLELOADCAT => 0, V_AXLELOAD => 12);
      Carry (2, 0, P);
      Run_X (25_000);
      Count := EVC_Track_Description.ASP.Count;
      V := (if Count > 0 then Natural (EVC_Track_Description.ASP.List (1).Value)
            else 0);
   end ASP_Run;

   procedure Scenario_Version_ASP is
      C3, V3, C2, V2 : Natural;
   begin
      ASP_Run (False, C3, V3);
      Check (SV.Operated = 3 and then C3 = 1 and then V3 > 1_111
             and then V3 < 1_666,
             "version ASP: X = 3, the speed of the train's category C2 "
             & "alone, no element where it is not listed (3.11.4.3)");
      ASP_Run (True, C2, V2);
      Check (SV.Operated = 2 and then C2 = 2 and then V2 = 1_111,
             "version ASP: X = 2 ordered by the group, the lowest speed of "
             & "the categories up to C2 (B1 40 km/h, not C4), an element of "
             & "A alone taken (6.6.4.1.3, 6.6.2.1.4)");
      EVC_Core.Initialise;
   end Scenario_Version_ASP;

end EVC_Test_Version;
