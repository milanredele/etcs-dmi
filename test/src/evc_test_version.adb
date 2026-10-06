--  ETCS on-board (EVC)
--  Phase E5, the system version of the RBC (see the specification).

with ETCS_Bits;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Train_Packets.P2;
with ETCS_Variables;
with EVC_Config;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Ports;           use EVC_Ports;
with EVC_Radio;
with EVC_System_Version;
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

end EVC_Test_Version;
