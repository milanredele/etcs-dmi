--  ETCS on-board (EVC)
--  Phase E5, the session and link half (see the specification).

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P15;
with ETCS_Track_Packets.P42;
with ETCS_Track_Packets.P58;
with ETCS_Track_Packets.P74;
with ETCS_Train_Packets.P4;
with ETCS_Bits;
with ETCS_Variables;
with DMI_Protocol;
with EVC_Config;
with EVC_DMI_Port;
with EVC_Core;
with EVC_Bytes;
with EVC_Mission;
with EVC_National_Values;
with EVC_Modes;
with EVC_Position;
with EVC_Train_Data;
with EVC_Distances;
with EVC_Procedures;
with EVC_Ports;           use EVC_Ports;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Sessions;
with EVC_Track_Conditions;
with EVC_Test_Modes;
with EVC_Test_Authority;
with EVC_Test_Support;    use EVC_Test_Support;
with Interfaces;          use Interfaces;
with Sim_Telegrams;

package body EVC_Test_Sessions is

   use type EVC_Bytes.Byte_Array;

   package MCat renames ETCS_Message_Catalogue;
   package R renames EVC_Radio;
   package TP42 renames ETCS_Track_Packets.P42;
   use type ETCS_Message.Status_T;
   use type ETCS_Message_Catalogue.Message_Kind_T;
   use type EVC_Modes.Mode_T;
   use type EVC_Position.Status_T;
   use type R.Session_State_T;
   use type R.Session_Ref_T;
   use type R.Session_Info_T;
   use type R.RBC_Id_T;
   use type ETCS_Variables.NID_RBC_T;
   use type ETCS_Variables.NID_RADIO_T;
   use type ETCS_Variables.M_VERSION_T;
   use type ETCS_Variables.NID_PACKET_T;

   --  A group NID at At_M metres with a session management order
   --  (packet 42): Q_RBC 1 establish, 0 terminate, with RBC NID_RBC
   procedure Order_Group (NID : Natural; At_M : Integer_64;
                          Q_RBC : Natural; NID_RBC : Natural)
   is
      P  : TP42.Packet_T;
      W  : Writer_T;
      OK : Boolean;
   begin
      Add_Group (Group (NID, At_M));
      P.Q_DIR := 2;
      P.Q_RBC := ETCS_Variables.Q_RBC_T (Q_RBC);
      P.NID_C := 5;
      P.NID_RBC := ETCS_Variables.NID_RBC_T (NID_RBC);
      --  7.5.1.95: BCD digits
      P.NID_RADIO := 16#0077#;
      TP42.Encode (P, W, OK);
      Finish_Carry (Track_N, 0, W, OK);
   end Order_Group;

   --  T_TRAIN of the on-board time now (10 ms, 7.5.1.152), plus D
   function Now_T (D : Unsigned_64 := 0) return Unsigned_64 is
     ((Unsigned_64 (EVC_Core.Time_Ms) / 10 + D) mod 2**32);

   --  A track to train message of Kind with T_TRAIN T, M_ACK Ack and the
   --  variable I (from 5 on) set to V
   function Msg (Kind : MCat.Known_Message_T;
                 T    : Unsigned_64;
                 Ack  : Unsigned_64 := 0;
                 I    : Positive := 5;
                 V    : Unsigned_64 := 0) return Byte_Array
   is
      Values : ETCS_Message.Value_Array := (others => 0);
   begin
      Values (3) := T;
      Values (4) := Ack;
      if I > 4 then
         Values (I) := V;
      end if;
      return Message_Of (Kind, Values);
   end Msg;

   --  The N-th RTM output is the message NID on session S
   function Is_Message (N : Positive; NID : Natural; S : Natural := 1)
     return Boolean
   is (N <= Radio_Outputs
       and then not Radio_Output (N).Request
       and then Radio_Output (N).Session = S
       and then Radio_Output (N).Kind = NID);

   --  The N-th RTM output is the request Code (1 set-up, 2 release)
   function Is_Request (N : Positive; Code : Natural; S : Natural := 1)
     return Boolean
   is (N <= Radio_Outputs
       and then Radio_Output (N).Request
       and then Radio_Output (N).Session = S
       and then Radio_Output (N).Kind = Code);

   --  The safe radio connection of S set up, the system version V of the
   --  RBC (message 32) and the acknowledgement 38 (3.5.3.7 b to e)
   procedure Establish (S : Natural; V : Unsigned_64 := 48) is
   begin
      Give_Radio_Event (S, Connection_Set_Up);
      Stand;
      Give_Radio_Message (S, Msg (MCat.Track_M32, Now_T, 0, 7, V));
      Stand;
      if V = 48 then
         Give_Radio_Message (S, Msg (MCat.Track_M38, Now_T));
         Stand;
      end if;
   end Establish;

   --  The RBC acknowledges (message 8, 8.7.4) the Train Data of the
   --  N-th RTM output (129 or 157) on S: its second T_TRAIN is theirs
   procedure Ack_Train_Data (N : Positive; S : Natural := 1) is
      M  : ETCS_Message.Message_T;
      St : ETCS_Message.Status_T;
   begin
      Decode_Radio_Message (N, M, St);
      --  8.7.4 field 6, the catalogue's seventh value (NID_LRBG is
      --  NID_C and NID_BG)
      Give_Radio_Message (S, Msg (MCat.Track_M8, Now_T, 0, 7, M.Values (3)));
      Stand;
   end Ack_Train_Data;

   --  The radio byte of the MSG_STATUS of the last cycle (3.5.7.1: 0 no
   --  connection, 1 up, 2 lost / set-up failed), 16#FF# when none
   function Radio_Byte return Natural is
     (if Find_DMI (EVC_DMI_Port.MSG_STATUS) = 0 then 16#FF#
      else Byte_At (Find_DMI (EVC_DMI_Port.MSG_STATUS), 7));

   --  A MSG_SYSTEM_STATUS of catalogue entry E, event Ev (0 start, 1
   --  end) in the last cycle
   function Status_Shown (E, Ev : Natural) return Boolean is
     (for some I in 1 .. Rec_Count =>
        Recs (I).Port = DMI and then Rec_Length (I) = 7
        and then Byte_At (I, 1) = 16#0C#
        and then Byte_At (I, 6) = E and then Byte_At (I, 7) = Ev);

   --  The catalogue entries the session half reports repeat
   --  DMI_Protocol (static: the comparison is known at compile time)
   pragma Warnings (Off, "condition is always*");
   procedure Check_Catalogue is
   begin
      Check (EVC_DMI_Port.SS_Trackside_Not_Compatible
               = DMI_Protocol.SS_Trackside_Not_Compatible
             and then EVC_DMI_Port.SS_Communication_Error_Trip
                        = DMI_Protocol.SS_Communication_Error_Trip
             and then EVC_DMI_Port.SS_Communication_Error_Brake
                        = DMI_Protocol.SS_Communication_Error_Brake,
             "session: the catalogue entries 4, 5, 15 as dmi_protocol.ads");
   end Check_Catalogue;
   pragma Warnings (On, "condition is always*");

   procedure Scenario_Session_Establish is
      M      : ETCS_Message.Message_T;
      St     : ETCS_Message.Status_T;
      Taken  : Natural;
   begin
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Order_Group (20, 300, Q_RBC => 0, NID_RBC => 300);
      Run_X (15_000);
      Check (R.Info (1).State = R.Connecting
             and then R.Info (1).RBC = (NID_C => 5, NID_RBC => 300)
             and then R.Info (1).Radio = 16#0077#
             and then R.Info (2).State = R.Idle
             and then R.Contact.Known and then R.Contact.Valid
             and then R.Contact.RBC.NID_RBC = 300,
             "session: a balise group orders a session (3.5.3.4 b), the "
             & "safe radio connection requested (3.5.3.7 a), the RBC "
             & "contact stored (4.10.1.4.2 b)");

      Give_Radio_Event (1, Set_Up_Failed);
      Stand;
      Check (Radio_Outputs = 1 and then Is_Request (1, 1)
             and then Request_Byte (1, 3) = 300 mod 256,
             "session: the set-up failed, requested again at once "
             & "(3.5.3.7 a)");

      Give_Radio_Event (1, Connection_Set_Up);
      Stand;
      Check (Radio_Outputs = 1 and then Is_Message (1, 155)
             and then R.Info (1).State = R.Initiating,
             "session: connection set up, message 155 (3.5.3.7 b)");

      Give_Radio_Message (1, Msg (MCat.Track_M32, Now_T, 0, 7, 48));
      Stand;
      Decode_Radio_Message (1, M, St);
      Check (Radio_Outputs = 3 and then Is_Message (1, 159)
             and then St = ETCS_Message.Accepted and then M.Count = 1
             and then R.Info (1).State = R.Established
             and then R.Info (1).Version = 48
             and then R.Supervising = 1 and then R.In_Communication,
             "session: the system version 3.0, established, message 159 "
             & "with packet 2 (3.5.3.7 d), the supervising RBC");
      Decode_Radio_Message (2, M, St);
      Check (Is_Message (2, 129) and then St = ETCS_Message.Accepted
             and then M.Count = 2
             and then not R.Train_Data_Acknowledged,
             "session: the session established with valid Train Data: "
             & "message 129 with packets 0 and 11 (3.18.3.4)");
      Decode_Radio_Message (3, M, St);
      Check (Is_Message (3, 136) and then St = ETCS_Message.Accepted
             and then M.Count = 1,
             "session: the session established, a position report "
             & "(3.6.5.1.4 h)");
      Ack_Train_Data (2);
      Check (R.Train_Data_Acknowledged and then Radio_Outputs = 0,
             "session: the Train Data acknowledged by message 8 "
             & "(3.18.3.4.1)");

      --  3.5.3.7.4: no acknowledgement within 15 s: 159 once again
      Sample (0);
      EVC_Core.Tick (15_000);
      Take;
      Check (Radio_Outputs = 1 and then Is_Message (1, 159),
             "session: 159 repeated after 15 s without 38 (3.5.3.7.4)");
      Give_Radio_Message (1, Msg (MCat.Track_M38, Now_T));
      Stand;
      Sample (0);
      EVC_Core.Tick (15_000);
      Take;
      Check (Radio_Outputs = 0 and then R.Info (1).State = R.Established,
             "session: acknowledged by 38, nothing more (3.5.3.7 e)");

      --  3.16.3.3.3: time stamps; 3.16.3.5: the acknowledgement 146
      Taken := EVC_Radio_Authority.Messages_Taken;
      Give_Radio_Message (1, Msg (MCat.Track_M24, Now_T (5), Ack => 1));
      Give_Radio_Message (1, Msg (MCat.Track_M24, Now_T (5), Ack => 1));
      Give_Radio_Message (1, Msg (MCat.Track_M24, Now_T (4), Ack => 1));
      Stand;
      Decode_Radio_Message (1, M, St);
      Check (EVC_Radio_Authority.Messages_Taken = Taken + 1
             and then Radio_Outputs = 2 and then Is_Message (1, 146)
             and then Is_Message (2, 136)
             and then St = ETCS_Message.Accepted
             and then M.Values (5) = Now_T (5) - 10,
             "session: a message not newer than the last is ignored "
             & "(3.16.3.3.3), the one taken acknowledged by 146 with its "
             & "time stamp (3.16.3.5), the rejection reported by 136 "
             & "(3.16.3.1.1.2)");

      --  3.5.5: terminated by order of a balise group
      Run_X (35_000);
      Check (R.Info (1).State = R.Terminating,
             "session: a balise group orders the termination, 156 sent "
             & "(3.5.5.1 a, 3.5.5.2 a)");
      Sample (0);
      EVC_Core.Tick (15_000);
      Take;
      Check (Radio_Outputs = 1 and then Is_Message (1, 156),
             "session: 156 repeated after 15 s (3.5.5.3.1)");
      Taken := EVC_Radio_Authority.Messages_Taken;
      Give_Radio_Message (1, Msg (MCat.Track_M24, Now_T (1)));
      Give_Radio_Message (1, Msg (MCat.Track_M39, Now_T (2)));
      Stand;
      Check (EVC_Radio_Authority.Messages_Taken = Taken
             and then Radio_Outputs = 1 and then Is_Request (1, 2)
             and then R.Info (1) = R.No_Info
             and then R.Supervising = R.No_Session,
             "session: after 156 only 39 is taken (3.5.5.6); terminated, "
             & "the connection released (3.5.5.2 c)");
   end Scenario_Session_Establish;

   procedure Scenario_Session_Lost_Version is
   begin
      EVC_Config.Set_Radio_For_Test ((Sessions => 1, others => <>));
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Order_Group (20, 300, Q_RBC => 1, NID_RBC => 301);
      Run_X (15_000);
      Establish (1);
      Check (R.Sessions = 1 and then R.Info (1).State = R.Established,
             "session: one session by configuration, established");

      --  3.5.4: lost, set up again at once, kept 5 minutes
      Give_Radio_Event (1, Connection_Lost);
      Stand;
      Check (R.Info (1).State = R.Connection_Lost
             and then R.Established (1)
             and then Radio_Outputs = 1 and then Is_Request (1, 1),
             "session: the connection lost, the session kept, set-up "
             & "requested (3.5.4.1, 3.5.4.2)");
      Give_Radio_Event (1, Connection_Set_Up);
      Stand;
      Check (R.Info (1).State = R.Established and then Radio_Outputs = 1
             and then Is_Message (1, 129),
             "session: set up again within the session (3.5.4.3), the "
             & "Train Data not acknowledged sent again (3.18.3.4.2)");
      Give_Radio_Event (1, Connection_Lost);
      Stand;
      Sample (0);
      EVC_Core.Tick (300_000);
      Take;
      Check (R.Info (1).State = R.Connecting
             and then Radio_Outputs = 2 and then Is_Request (1, 2)
             and then Is_Request (2, 1),
             "session: not set up within 5 minutes: terminated "
             & "(3.5.4.2.1) and a new one established (3.5.3.4 f)");

      --  3.5.3.7 d): no compatible version (X = 4, above the envelope
      --  1 .. 3 of 6.4.2, EVC_System_Version)
      Establish (1, V => 64);
      Check (Radio_Outputs = 2 and then Is_Message (1, 154)
             and then Is_Message (2, 156)
             and then R.Info (1).State = R.Terminating,
             "session: version 4.0 not compatible: 154, then terminated "
             & "(156) (3.5.3.7 d)");
      Check (Status_Shown (EVC_DMI_Port.SS_Trackside_Not_Compatible, 0),
             "session: the driver informed: ""Trackside not compatible"" "
             & "(3.5.3.7 d) second bullet, DMI entry 15)");
      Give_Radio_Message (1, Msg (MCat.Track_M39, Now_T (1)));
      Stand;
      Check (R.Info (1).State = R.Idle and then Is_Request (1, 2),
             "session: terminated, released (3.5.5.2 c)");

      --  3.5.3.5.2, 3.5.3.5.2.1: with one session, an order for another
      --  RBC terminates the session first
      Run_X (35_000);
      Check (R.Info (1).State = R.Connecting
             and then R.Info (1).RBC.NID_RBC = 301,
             "session: ordered with RBC 301");
      Establish (1);
      Order_Group (30, 400, Q_RBC => 1, NID_RBC => 302);
      Run_X (45_000);
      Check (R.Info (1).State = R.Terminating
             and then R.Info (1).RBC.NID_RBC = 301
             and then R.Info (2).State = R.Idle,
             "session: one session: the order for RBC 302 terminates the "
             & "one with 301 first (3.5.3.5.2)");
      Give_Radio_Message (1, Msg (MCat.Track_M39, Now_T (1)));
      Stand;
      Check (R.Info (1).State = R.Connecting
             and then R.Info (1).RBC.NID_RBC = 302
             and then Is_Request (1, 2) and then Is_Request (2, 1),
             "session: then the one with 302 (3.5.3.5.2.1)");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
      EVC_Core.Initialise;
   end Scenario_Session_Lost_Version;

   procedure Scenario_Session_NVCONTACT is
      NV : Sim_Telegrams.T3.Packet_T := Sim_Telegrams.National_Values (123);
   begin
      Start_X;
      NV.T_NVCONTACT := 10;   -- s
      NV.M_NVCONTACT := 0;    -- train trip
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Carry (Track_N, 1, NV);
      Run_X (15_000);
      Establish (1);
      Stand;
      Check (R.In_Communication and then not EVC_Sessions.T_NVCONTACT_Trip
             and then EVC_Core.Mode = EVC_Modes.M_FS,
             "link: in communication, T_NVCONTACT 10 s not passed");
      Sample (0);
      EVC_Core.Tick (11_000);
      Take;
      Check (EVC_Sessions.T_NVCONTACT_Trip
             and then EVC_Core.Mode = EVC_Modes.M_TR,
             "link: no message for more than T_NVCONTACT, reaction train "
             & "trip: TR (3.16.3.4.1, 4.6.3 [41])");
      Collect;
      Check (JRU_Last (13, 2) = 5,
             "link: the reaction recorded, JRU record 13 with M_ERROR 5, "
             & "safe radio connection error (SUBSET-027 4.2.4.13)");
      Check (EVC_Procedures."=" (EVC_Procedures.Trip_Reason,
                                 EVC_Procedures.Communication_Lost)
             and then Status_Shown (EVC_DMI_Port.SS_Communication_Error_Trip,
                                    0),
             "link: the driver informed: ""Communication error"", the "
             & "reason of the trip (3.16.3.4.4, 4.4.13.1.3, DMI entry 5)");
      Sample (0);
      EVC_Core.Tick (60_000);
      Take;
      Check (R.Info (1).State = R.Connection_Lost
             and then Is_Request (1, 2) and then Is_Request (2, 1),
             "link: 60 s later the connection released and set up again, "
             & "the session kept (3.16.3.4.3)");
      Give_Radio_Event (1, Connection_Set_Up);
      Give_Radio_Message (1, Msg (MCat.Track_M24, Now_T (1)));
      Stand;
      Check (R.Info (1).State = R.Established
             and then not EVC_Sessions.T_NVCONTACT_Trip,
             "link: set up again, a new message: supervised again");
   end Scenario_Session_NVCONTACT;

   --  3.16.3.4.2 b): the reaction "apply service brake", its indication
   --  (3.16.3.4.4) and its release (3.14.1.7, 3.16.3.4.5 a)
   procedure Scenario_Session_NVCONTACT_Brake is
      NV     : Sim_Telegrams.T3.Packet_T :=
        Sim_Telegrams.National_Values (123);
      Starts : constant Natural :=
        SS_Seen (EVC_DMI_Port.SS_Communication_Error_Brake);
      Ended  : Boolean := False;
   begin
      Start_X;
      NV.T_NVCONTACT := 5;    -- s
      NV.M_NVCONTACT := 1;    -- service brake
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Carry (Track_N, 1, NV);
      Run_X (15_000);
      Establish (1);
      Run_X (30_000, 200);    -- 7.5 s at 72 km/h
      Check (EVC_Sessions.Service_Brake
             and then not EVC_Sessions.T_NVCONTACT_Trip
             and then Last_Brake = Natural (EVC_DMI_Port.Brake_Applied)
             and then SS_Seen (EVC_DMI_Port.SS_Communication_Error_Brake)
                        = Starts + 1,
             "link: T_NVCONTACT passed while running, reaction service "
             & "brake (3.16.3.4.2 b), the driver informed (3.16.3.4.4, "
             & "DMI entry 4)");
      --  4.12.1.2 Table, "Check safe radio connection (T_NVCONTACT)"
      EVC_Sessions.Revoke_Contact_Brake (EVC_Modes.M_FS);
      Check (EVC_Sessions.Service_Brake,
             "4.12.1.2 b): the T_NVCONTACT brake maintained entering FS");
      EVC_Sessions.Revoke_Contact_Brake (EVC_Modes.M_UN);
      Check (not EVC_Sessions.Service_Brake,
             "4.12.1.2 a): the T_NVCONTACT brake revoked entering UN");
      Give_Radio_Message (1, Msg (MCat.Track_M24, Now_T (1)));
      Stand;
      Check (not EVC_Sessions.Service_Brake
             and then Status_Shown
                        (EVC_DMI_Port.SS_Communication_Error_Brake, 1),
             "link: a new message releases the service brake (3.14.1.7), "
             & "its indication ends");
      Run_X (45_000, 200);
      Check (EVC_Sessions.Service_Brake,
             "link: T_NVCONTACT passed again: the service brake");
      for K in 1 .. 30 loop
         Stand;
         Ended := Ended
           or else Status_Shown (EVC_DMI_Port.SS_Communication_Error_Brake,
                                 1);
         exit when not EVC_Sessions.Service_Brake;
      end loop;
      Check (not EVC_Sessions.Service_Brake and then Ended
             and then EVC_Core.Mode /= EVC_Modes.M_TR,
             "link: released at standstill (3.14.1.7, 3.16.3.4.5 a)");
   end Scenario_Session_NVCONTACT_Brake;

   --  3.5.7: the indication of the safe radio connection (Tables 1, 2)
   procedure Scenario_Session_Indication is
      use type EVC_Sessions.Indication_T;
   begin
      Check_Catalogue;
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Order_Group (20, 300, Q_RBC => 0, NID_RBC => 300);
      Order_Group (30, 500, Q_RBC => 1, NID_RBC => 301);
      Order_Group (40, 700, Q_RBC => 0, NID_RBC => 301);
      Run_X (15_000);
      --  MSG_STATUS is sent when a field changes (EVC_Core.Send_Status)
      Check (EVC_Sessions.Indication = EVC_Sessions.No_Connection
             and then Radio_Byte in 0 | 16#FF#,
             "indication: set-up requested: ""No Connection"" (3.5.7.1)");
      Give_Radio_Event (1, Set_Up_Failed);
      Stand;
      Sample (0);
      EVC_Core.Tick (45_000);
      Take;
      Check (EVC_Sessions.Indication = EVC_Sessions.Connection_Lost
             and then Radio_Byte = 2,
             "indication: not set up within the connection status timer "
             & "(45 s, A.3.1): ""Connection Lost/Set-Up failed"" (3.5.7.3, "
             & "Table 2 [2])");
      Give_Radio_Event (1, Connection_Set_Up);
      Stand;
      Check (EVC_Sessions.Indication = EVC_Sessions.Connection_Up
             and then Radio_Byte = 1,
             "indication: set up: ""Connection Up"" (Table 2 [4])");
      Give_Radio_Message (1, Msg (MCat.Track_M32, Now_T, 0, 7, 48));
      Stand;
      Give_Radio_Message (1, Msg (MCat.Track_M38, Now_T));
      Stand;
      Give_Radio_Event (1, Connection_Lost);
      Stand;
      Check (EVC_Sessions.Indication = EVC_Sessions.Connection_Up
             and then Is_Request (1, 1),
             "indication: lost, set up again: still ""Connection Up"" "
             & "while the timer runs (3.5.7.2.1, 3.5.7.3 b)");
      Sample (0);
      EVC_Core.Tick (45_000);
      Take;
      Check (EVC_Sessions.Indication = EVC_Sessions.Connection_Lost
             and then Radio_Byte = 2,
             "indication: the timer expires: ""Connection Lost/Set-Up "
             & "failed"" (Table 2 [2])");
      Give_Radio_Event (1, Connection_Set_Up);
      Stand;
      Check (EVC_Sessions.Indication = EVC_Sessions.Connection_Up,
             "indication: set up again: ""Connection Up""");
      Run_X (35_000);
      Give_Radio_Message (1, Msg (MCat.Track_M39, Now_T (1)));
      Stand;
      Check (EVC_Sessions.Indication = EVC_Sessions.No_Connection
             and then Radio_Byte = 0,
             "indication: terminated and released: ""No Connection"" "
             & "(Table 2 [5])");
      Run_X (55_000);
      Sample (0);
      EVC_Core.Tick (45_000);
      Take;
      Check (EVC_Sessions.Indication = EVC_Sessions.Connection_Lost
             and then R.Info (1).State = R.Connecting,
             "indication: a new session not set up in 45 s: ""Connection "
             & "Lost/Set-Up failed""");
      Run_X (75_000);
      Check (EVC_Sessions.Indication = EVC_Sessions.No_Connection
             and then R.Info (1).State = R.Idle,
             "indication: the requests stopped, no start of mission: "
             & """No Connection"" (3.5.7.4, Table 2 [3])");
   end Scenario_Session_Indication;

   --  3.5.4.4, 3.5.7.5 Table 2 [7], 3.12.1.2.1.5 (e5/onboard-misc, B271):
   --  the connection lost while the engine overlaps an announced radio
   --  hole: "No Connection" and no attempt to set it up again before the
   --  engine has left the hole, then the attempts as in 3.5.4.2
   procedure Scenario_Session_Radio_Hole is
      use type EVC_Sessions.Indication_T;
      C   : T68.Packet_T;
      Any : Boolean := False;

      function Requested return Boolean is
        (for some N in 1 .. Radio_Outputs => Is_Request (N, 1));

      --  Steps of 10 m, Any: a set-up request on the way
      procedure Go (Steps : Natural) is
      begin
         Any := False;
         for I in 1 .. Steps loop
            Step_X (1000);
            Any := Any or else Requested;
         end loop;
      end Go;
   begin
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      --  the group at 200 m announces a radio hole from 300 m to 500 m
      Add_Group (Group (20, 200));
      C.Q_DIR := 2;
      C.Q_SCALE := 1;
      C.Q_TRACKINIT := 0;
      C.Has_D_TRACKCOND := True;
      C.D_TRACKCOND := 100;
      C.L_TRACKCOND := 200;
      C.M_TRACKCOND := 4;
      Carry (Track_N, 0, C);
      Run_X (15_000);
      Establish (1);
      Check (EVC_Sessions.Indication = EVC_Sessions.Connection_Up
             and then not EVC_Track_Conditions.Engine_In_Radio_Hole,
             "radio hole: the session set up before the hole");
      Run_X (35_000);
      Check (EVC_Track_Conditions.Engine_In_Radio_Hole
             and then EVC_Sessions.Indication = EVC_Sessions.Connection_Up,
             "radio hole: the engine overlaps the announced radio hole "
             & "(3.12.1.2.1.5), the connection still up");
      Give_Radio_Event (1, Connection_Lost);
      Stand;
      Check (EVC_Sessions.Indication = EVC_Sessions.No_Connection
             and then R.Info (1).State = R.Connection_Lost
             and then not Requested,
             "radio hole: the connection lost in it: ""No Connection"" "
             & "(Table 2 [7]), no attempt to set it up again (3.5.4.4)");
      Go (14);
      Check (not Any and then EVC_Track_Conditions.Engine_In_Radio_Hole,
             "radio hole: no attempt while the engine overlaps it");
      Go (4);
      Check (Any and then not EVC_Track_Conditions.Engine_In_Radio_Hole,
             "radio hole: set up again once the engine has left it "
             & "(3.5.4.4)");
      Give_Radio_Event (1, Connection_Set_Up);
      Stand;
      Check (EVC_Sessions.Indication = EVC_Sessions.Connection_Up
             and then R.Info (1).State = R.Established,
             "radio hole: the connection up again (Table 2 [4])");
   end Scenario_Session_Radio_Hole;

   ---------------------------------------------------------------------
   --  Phase 2 (e5/session-3): the level 2 start and end of mission
   ---------------------------------------------------------------------

   --  The DMI's frames (dmi_protocol.ads): a driver action, a text entry
   --  (kind 0 driver ID, 1 train running number), the Train Data of
   --  Table 40 (kind 2), the RBC data (kind 5: choice, RBC ID u32, the
   --  phone number's length and 16 digits)
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

   function Train_Entry return Byte_Array is
     (Frame (EVC_DMI_Port.MSG_DRIVER_DATA,
             Byte_Array'(1 => 2) & U16 (200) & U16 (135) & U16 (160)
             & Byte_Array'(1 => 2) & U16 (4) & Byte_Array'(0, 0, 1)));

   function RBC_Entry (Choice : Natural; Id : Unsigned_32; Phone : String)
     return Byte_Array
   is
      Res : Byte_Array (1 .. 23) := (others => 0);
   begin
      Res (1) := 5;
      Res (2) := Byte (Choice);
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

   --  The byte K (dmi_protocol.ads order from 1) of the MSG_ONBOARD of the
   --  last cycle: 6 data, 7 session, 8 rbc, 12 waiting, 14 radio
   function Onboard_Byte (K : Positive) return Natural is
     (if Find_DMI (EVC_DMI_Port.MSG_ONBOARD) = 0 then 16#FF#
      else Byte_At (Find_DMI (EVC_DMI_Port.MSG_ONBOARD), K));

   --  The RTM output that is the message NID (0: none)
   function Output_Of (NID : Natural) return Natural is
   begin
      for N in 1 .. Radio_Outputs loop
         if Is_Message (N, NID) then
            return N;
         end if;
      end loop;
      return 0;
   end Output_Of;

   --  A level 2 start of mission up to the driver's RBC contact (S1, S2,
   --  S3), one session
   procedure SoM_To_S3 is
   begin
      EVC_Config.Set_Radio_For_Test ((Sessions => 1, Engine_Id => 76_000, others => <>));
      EVC_Test_Modes.Start_E4;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 5));
      Send (RBC_Entry (0, 5 * 16_384 + 300, "0077"));
   end SoM_To_S3;

   --  e5/registration: the radio networks (3.5.6) in a level 2 start of
   --  mission, one session, the mobile answering by hand
   function Request_Of (Code : Natural) return Boolean is
     (for some N in 1 .. Radio_Outputs => Is_Request (N, Code));

   procedure Scenario_Session_Registration is
      use type ETCS_Variables.NID_MN_T;
      use type EVC_Config.Network_Type_T;
   begin
      Auto_Register := False;
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 76_000, others => <>));
      EVC_Test_Modes.Start_E4;
      Check (R.Network.NID_MN = 0 and then not R.Network.Registered
             and then R.Network.Net_Type = EVC_Config.GSMR
             and then Onboard_Byte (14) = 3 + 4 * 3,
             "registration: at power-up ordered to the default network "
             & "(3.5.6.1 a, 3.5.6.3), the type the configured default "
             & "(3.5.6.4); MSG_ONBOARD radio: GSM-R, both systems, none "
             & "registered");
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 5));
      Send (RBC_Entry (0, 5 * 16_384 + 300, "0077"));
      Check (R.Info (1).State = R.Connecting and then not Request_Of (1)
             and then Onboard_Byte (12) = 1,
             "registration: no mobile registered, no set-up request "
             & "(3.5.6.7 d); the start of mission waits (5.4.3.2 S4, "
             & "MSG_ONBOARD waiting 1)");
      Give_Radio_Event (1, Registration_Failed);
      Stand;
      Check (Status_Shown (EVC_DMI_Port.SS_GSMR_Registration_Failed, 0)
             and then not Request_Of (1),
             "registration: failed, the driver informed (5.4.3.2 A29 / "
             & "A42), still no set-up (3.5.6.7)");
      Give_Radio_Event (1, Registered);
      Stand;
      Check (Request_Of (1) and then Onboard_Byte (12) = 2
             and then Onboard_Byte (14) = 3 + 4 * 3 + 32 + 128,
             "registration: registered, the order kept is executed "
             & "(3.5.6.7; 5.4.3.2 S4 E6 -> A31); radio bit5");
      --  3.5.6.1 b), 3.18.4.3.6.1 b), 3.18.4.3.6.3 b): the driver's
      --  GSM-R network
      Send (Text_Entry (4, "262"));
      Check (R.Info (1).State /= R.Connecting
             and then R.Contact.Known and then not R.Contact.Valid
             and then R.Network.NID_MN = 16#262FFF#
             and then Onboard_Byte (15) = 2,
             "registration: the driver selects network 262: the session "
             & "terminated, the contact invalid, radio_wait 2 "
             & "(3.18.4.3.6.1 b, 3.18.4.3.6.3 b)");
      for I in 1 .. 30 loop
         exit when Request_Of (3);
         Stand;
      end loop;
      Check (Request_Of (3),
             "registration: ordered to 262 once the session is over "
             & "(3.5.6.1 b, 3.18.4.3.6.2)");
      Give_Radio_Event (1, Registered);
      Stand;
      Check (Onboard_Byte (15) = 0,
             "registration: done, radio_wait 0");
      --  3.18.4.3.6, DMI 11.3.15 / 11.3.16: the type and one system
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_DATA, (6, 2)));
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_DATA, (7, 1)));
      Check (R.Network.Net_Type = EVC_Config.FRMCS_GSMR
             and then Onboard_Byte (14) = 2 + 4 * 3 + 32 + 64 + 128
             and then EVC_Sessions.Network_Ready,
             "registration: FRMCS+GSM-R, mission with one radio system: "
             & "one system registered is enough (3.5.6.7 c)");
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_DATA, (7, 0)));
      Check (not EVC_Sessions.Network_Ready,
             "registration: FRMCS+GSM-R with both systems and FRMCS not "
             & "registered: no set-up (3.5.6.7 b)");
      --  3.5.6.1 c), 3.5.6.5: the trackside's Radio Network transition
      --  order (packet 45), the session idle
      EVC_Sessions.Take_Network_Order (2, 16#123FFF#);
      Stand;
      Check (R.Network.Net_Type = EVC_Config.GSMR
             and then R.Network.NID_MN = 16#123FFF#
             and then Request_Of (3) and then not R.Network.Registered,
             "registration: a Radio Network transition order stored and "
             & "the mobile ordered to it at once (3.5.6.5)");
      Auto_Register := True;
      --  the radio configuration of the scenarios after this one
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Session_Registration;

   procedure Scenario_Session_SoM_Level_2 is
      M  : ETCS_Message.Message_T;
      St : ETCS_Message.Status_T;
      N  : Natural;
   begin
      SoM_To_S3;
      Check (R.Contact.Known and then R.Contact.Valid
             and then R.Contact.RBC = (NID_C => 5, NID_RBC => 300)
             and then R.Contact.Radio = 16#0077_FFFF_FFFF_FFFF#
             and then R.Info (1).State = R.Connecting
             and then Is_Request (1, 1)
             and then Onboard_Byte (12) = 2 and then Onboard_Byte (7) = 1
             and then Onboard_Byte (6) / 16 mod 2 = 1,
             "SoM L2: the RBC contact entered by the driver (5.4.3.2 S3) "
             & "valid (5.4.3.3), the session opened (A31), the DMI waits "
             & "for the RBC (MSG_ONBOARD waiting 2)");
      Give_Radio_Event (1, Connection_Set_Up);
      Stand;
      Give_Radio_Message (1, Msg (MCat.Track_M32, Now_T, 0, 7, 48));
      Stand;
      N := Output_Of (157);
      if N > 0 then
         Decode_Radio_Message (N, M, St);
      end if;
      Check (N > 0 and then St = ETCS_Message.Accepted
             and then M.Values (5) = 2 and then M.Count = 1
             and then M.Values (4) = 76_000
             and then Onboard_Byte (12) = 0 and then Onboard_Byte (7) = 2,
             "SoM L2: the session open (D31, D32), the SoM position report "
             & "157 'no position referred to an LRBG' (Q_STATUS 2, A34) "
             & "without Train Data, NID_ENGINE of the configuration");
      Give_Radio_Message (1, Msg (MCat.Track_M38, Now_T));
      Stand;
      Give_Radio_Message (1, Msg (MCat.Track_M41, Now_T));
      Stand;
      Check (EVC_Sessions.SoM_Reports_Sent = 1,
             "SoM L2: the train accepted (A23, D34), S10");

      --  S12: the Train Data validated, sent (3.18.3.4), repeated, then
      --  acknowledged (S11 -> S20)
      Send (Train_Entry);
      N := Output_Of (129);
      Check (N > 0 and then not R.Train_Data_Acknowledged,
             "SoM L2: the Train Data validated in the session: 129 "
             & "(3.18.3.4, 5.4.3.2 E16)");
      Sample (0);
      EVC_Core.Tick (15_000);
      Take;
      N := Output_Of (129);
      Check (N > 0, "SoM L2: 129 repeated without acknowledgement "
             & "(A.3.1, decision 4)");
      Ack_Train_Data (N);
      Check (R.Train_Data_Acknowledged and then Onboard_Byte (8) mod 2 = 1,
             "SoM L2: acknowledged by 8 (3.18.3.4.1, D15 / S11, MSG_ONBOARD "
             & "rbc bit0)");
      Sample (0);
      EVC_Core.Tick (15_000);
      Take;
      Check (Output_Of (129) = 0, "SoM L2: not repeated once acknowledged");

      --  S20 -> S21: 'Start' with a session open proposes no mode
      Send (Text_Entry (1, "5678"));
      Send (Action (5));
      Check (R.In_Communication and then not EVC_Mission.Proposed,
             "SoM L2: 'Start' with a session open goes to S21 (5.4.5.3 h): "
             & "no Staff Responsible proposed");
   end Scenario_Session_SoM_Level_2;

   ---------------------------------------------------------------------
   --  e5/sr-proposal: the RBC's answer to 'Start' in level 2
   ---------------------------------------------------------------------

   --  Message 2, the SR authorisation, with the LRBG unknown (the
   --  position of the start of mission) and D_SR D metres; T_TRAIN
   --  Earlier units of 10 ms before now (e5/same-cycle: a message 2 and a
   --  message 3 of one cycle need increasing stamps, 3.16.3.3.3)
   function SR_Authorisation (D       : Unsigned_64;
                              Earlier : Unsigned_64 := 0) return Byte_Array
   is
      V : ETCS_Message.Value_Array := (others => 0);
   begin
      V (3) := Now_T (2**32 - Earlier);
      V (5) := 1023;
      V (6) := 16_383;
      V (7) := 1;
      V (8) := D;
      return Message_Of (MCat.Track_M2, V);
   end SR_Authorisation;

   --  5.4.3.2 S21, E26 -> S24, E32: 'Start' in level 2 with the session
   --  established and the Train Data acknowledged sends the MA request
   --  and waits (DMI Table 50 S7: MSG_ONBOARD waiting 3); the SR
   --  authorisation (message 2) is E26: Staff Responsible proposed as in
   --  level 1 (S24), the driver's acknowledgement (E32) gives SR (4.6.3
   --  [8]). A message 2 without a 'Start' waiting proposes nothing
   --  (decision of e5/sr-proposal). E29 (an MA allowing FS) is covered by
   --  the mode change ending the wait and by Scenario_Bench_Level_2
   procedure Scenario_SoM_L2_SR_Proposal is
      N : Natural;
   begin
      SoM_To_S3;
      Establish (1);
      Give_Radio_Message (1, Msg (MCat.Track_M41, Now_T));
      Stand;
      Send (Train_Entry);
      N := Output_Of (129);
      if N > 0 then
         Ack_Train_Data (N);
      end if;
      Send (Text_Entry (1, "5678"));
      Check (N > 0 and then R.Train_Data_Acknowledged
             and then EVC_Core.Mode = EVC_Modes.M_SB,
             "SR proposal: the level 2 start of mission at S20");

      --  decision: message 2 before 'Start' proposes nothing
      Give_Radio_Message (1, SR_Authorisation (500));
      Stand;
      Check (not EVC_Mission.Proposed
             and then not EVC_Mission.Waiting_For_RBC,
             "SR proposal: an SR authorisation without 'Start' waiting "
             & "proposes nothing (5.4.3.2: S24 from S21 only)");

      --  S20 -> S21: the MA request, the DMI waits (Table 50 S7)
      Send (Action (5));
      Check (EVC_Mission.Waiting_For_RBC and then not EVC_Mission.Proposed
             and then EVC_Radio_Authority.MA_Request_Reasons mod 2 = 1
             and then Onboard_Byte (12) = 3,
             "SR proposal: 'Start' in level 2 sends the MA request and "
             & "waits (5.4.3.2 S21; MSG_ONBOARD waiting 3, DMI Table 50 S7)");

      --  E26 -> S24: SR proposed, the wait over
      Give_Radio_Message (1, SR_Authorisation (500));
      Stand;
      Check (EVC_Mission.Proposed
             and then EVC_Mission.Proposed_Mode = EVC_Modes.M_SR
             and then not EVC_Mission.Waiting_For_RBC
             and then Onboard_Byte (12) = 0
             and then EVC_Core.Mode = EVC_Modes.M_SB,
             "SR proposal: the SR authorisation (message 2, E26) proposes "
             & "Staff Responsible (5.4.3.2 S24), the DMI waits no more");

      --  E32: the driver's acknowledgement, SR
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 1, 0, 0, 0)));
      Stand;
      Check (EVC_Core.Mode = EVC_Modes.M_SR and then not EVC_Mission.Proposed
             and then EVC_Radio_Authority.RBC_SR_Given,
             "SR proposal: acknowledged (E32), the mission starts in SR "
             & "(4.6.3 [8]) with the RBC's SR distance (4.4.11.1.6.4 b)");
   end Scenario_SoM_L2_SR_Proposal;

   --  e5/mode-proposal: message 3 referring to the group NID_BG of
   --  country 123: an MA of 2000 m (packet 15), its gradient and SSP,
   --  and, when Mode is not negative, a mode profile (packet 80) of
   --  M_MAMODE Mode (0 OS, 1 SH, 2 LS) from D metres, 500 m long, at
   --  30 km/h, with an acknowledgement area of 100 m
   function MA_With_Profile (NID_BG : Natural;
                             Mode   : Integer;
                             D      : Natural) return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
      P  : ETCS_Track_Packets.P15.Packet_T;
      M  : T80.Packet_T;
   begin
      V (3) := Now_T;
      V (5) := 123;
      V (6) := Unsigned_64 (NID_BG);
      Start_Message (W, MCat.Track_M3, V);
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.L_ENDSECTION := 2000;
      ETCS_Track_Packets.P15.Encode (P, W, OK);
      Check (OK, "mode proposal: packet 15 encoded");
      T21.Encode (Grad ((1 => (0, 0))), W, OK);
      T27.Encode (SSP ((1 => (0, 100, False))), W, OK);
      if Mode >= 0 then
         M.Q_DIR := 1;
         M.Q_SCALE := 1;
         M.D_MAMODE := ETCS_Variables.D_MAMODE_T (D);
         M.M_MAMODE := ETCS_Variables.M_MAMODE_T (Mode);
         M.V_MAMODE := 6;
         M.L_MAMODE := 500;
         M.L_ACKMAMODE := 100;
         T80.Encode (M, W, OK);
         Check (OK, "mode proposal: packet 80 encoded");
      end if;
      return Message_Bytes (W);
   end MA_With_Profile;

   --  e5/mode-proposal: the level 2 start of mission of
   --  Scenario_SoM_L2_SR_Proposal up to S20 (Train Data acknowledged,
   --  train running number entered), the train standing at 10 m, past the
   --  group 10 at 5 m (its position valid, the LRBG known to the RBC)
   procedure SoM_L2_At_S20 is
      N : Natural;
   begin
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 76_000, others => <>));
      EVC_Test_Modes.Start_E4;
      Add_Group (Group (10, 20));
      Run_X (5_000, 100);
      Stand;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 5));
      Send (RBC_Entry (0, 5 * 16_384 + 300, "0077"));
      --  A33: the position reported valid, S10 without an answer of
      --  the RBC (a message 41, A23, would delete it: D34, A24)
      Establish (1);
      Stand;
      Send (Train_Entry);
      N := Output_Of (129);
      if N > 0 then
         Ack_Train_Data (N);
      end if;
      Send (Text_Entry (1, "5678"));
      Check (EVC_Position."=" (EVC_Position.Status, EVC_Position.Valid),
             "mode proposal: the position valid in SB");
      Check (N > 0 and then R.Train_Data_Acknowledged
             and then EVC_Core.Mode = EVC_Modes.M_SB,
             "mode proposal: the level 2 start of mission at S20");
   end SoM_L2_At_S20;

   --  5.4.3.2 S21, E27 -> S25, E33: 'Start' in level 2, an MA with a
   --  mode profile On Sight at the train's position proposes On Sight;
   --  the driver's acknowledgement gives OS (4.6.3 [15]).
   --  The proposal is the acknowledgement the procedures ask in SB in
   --  level 2 (EVC_Procedures.Profiles_Step, 5.7.4.1); it ends the wait
   procedure Scenario_SoM_L2_Mode_Proposal is
   begin
      SoM_L2_At_S20;
      Send (Action (5));
      Check (EVC_Mission.Waiting_For_RBC,
             "mode proposal: 'Start' in level 2 waits (5.4.3.2 S21)");
      Give_Radio_Message (1, MA_With_Profile (10, 0, 0));
      Stand;
      --  the request is raised after EVC_Mission.Evaluate in the cycle
      --  of the MA (EVC_Core.Run_Procedures): the wait ends at the next
      Stand;
      Check (EVC_Procedures.Ack_Requested
             and then EVC_Procedures.Ack_Mode = EVC_Modes.M_OS
             and then not EVC_Mission.Waiting_For_RBC
             and then EVC_Core.Mode = EVC_Modes.M_SB,
             "mode proposal: an MA with an On Sight profile at the train "
             & "(E27) proposes On Sight (5.4.3.2 S25)");
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 1, 0, 0, 0)));
      Stand;
      Check (EVC_Core.Mode = EVC_Modes.M_OS
             and then not EVC_Procedures.Ack_Requested,
             "mode proposal: acknowledged (E33), the mission starts in OS "
             & "(4.6.3 [15])");
   end Scenario_SoM_L2_Mode_Proposal;

   --  5.4.3.2 S21, E26 / E27 (decision of e5/same-cycle): 'Start' in
   --  level 2, then a message 2 and an MA with an On Sight profile at the
   --  train delivered in one cycle. The message 2 proposes SR in that
   --  cycle; the MA's acknowledgement request comes in the next and
   --  withdraws the SR proposal: On Sight is proposed (S25), not SR
   procedure Scenario_SoM_L2_Same_Cycle is
   begin
      SoM_L2_At_S20;
      Send (Action (5));
      Check (EVC_Mission.Waiting_For_RBC,
             "same cycle: 'Start' in level 2 waits (5.4.3.2 S21)");
      Give_Radio_Message (1, SR_Authorisation (500, Earlier => 1));
      Give_Radio_Message (1, MA_With_Profile (10, 0, 0));
      Stand;
      Check (EVC_Mission.Proposed
             and then EVC_Mission.Proposed_Mode = EVC_Modes.M_SR
             and then EVC_Radio_Authority.Radio_MAs_Accepted = 1,
             "same cycle: the message 2 proposes SR in its cycle, the MA "
             & "accepted after the mission's evaluation (E26 before E27)");
      Stand;
      Check (EVC_Procedures.Ack_Requested
             and then EVC_Procedures.Ack_Mode = EVC_Modes.M_OS
             and then not EVC_Mission.Proposed
             and then not EVC_Mission.Waiting_For_RBC
             and then EVC_Core.Mode = EVC_Modes.M_SB,
             "same cycle: a message 2 and an MA with an On Sight profile "
             & "in one cycle propose On Sight, not SR (5.4.3.2 E27 / S25)");
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 1, 0, 0, 0)));
      Stand;
      Check (EVC_Core.Mode = EVC_Modes.M_OS
             and then not EVC_Procedures.Ack_Requested
             and then not EVC_Mission.Proposed,
             "same cycle: acknowledged, the mission starts in OS "
             & "(4.6.3 [15])");
   end Scenario_SoM_L2_Same_Cycle;

   --  5.4.3.2 S21, E27 -> S25, E33 with a Limited Supervision profile
   --  (packet 80 M_MAMODE 2) at the train's position: Limited Supervision
   --  proposed, the acknowledgement gives LS (4.6.3 [70])
   procedure Scenario_SoM_L2_Mode_Proposal_LS is
   begin
      SoM_L2_At_S20;
      Send (Action (5));
      Give_Radio_Message (1, MA_With_Profile (10, 2, 0));
      Stand;
      Stand;
      Check (EVC_Procedures.Ack_Requested
             and then EVC_Procedures.Ack_Mode = EVC_Modes.M_LS
             and then not EVC_Mission.Waiting_For_RBC
             and then not EVC_Mission.Proposed
             and then EVC_Core.Mode = EVC_Modes.M_SB,
             "mode proposal: an MA with a Limited Supervision profile at "
             & "the train (E27) proposes Limited Supervision (5.4.3.2 S25)");
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 1, 0, 0, 0)));
      Stand;
      Check (EVC_Core.Mode = EVC_Modes.M_LS,
             "mode proposal: acknowledged (E33), Limited Supervision "
             & "(4.6.3 [70])");
   end Scenario_SoM_L2_Mode_Proposal_LS;

   --  5.4.3.2 S21, E27 -> S25, E33 with a Shunting profile (packet 80
   --  M_MAMODE 1) at the train's position: Shunting proposed, the
   --  acknowledgement gives SH (4.6.3 [50])
   procedure Scenario_SoM_L2_Mode_Proposal_SH is
   begin
      SoM_L2_At_S20;
      Send (Action (5));
      Give_Radio_Message (1, MA_With_Profile (10, 1, 0));
      Stand;
      Stand;
      Check (EVC_Procedures.Ack_Requested
             and then EVC_Procedures.Ack_Mode = EVC_Modes.M_SH
             and then not EVC_Mission.Waiting_For_RBC
             and then EVC_Core.Mode = EVC_Modes.M_SB,
             "mode proposal: an MA with a Shunting profile at the train "
             & "(E27) proposes Shunting (5.4.3.2 S25)");
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 1, 0, 0, 0)));
      Stand;
      Check (EVC_Core.Mode = EVC_Modes.M_SH,
             "mode proposal: acknowledged (E33), Shunting (4.6.3 [50])");
   end Scenario_SoM_L2_Mode_Proposal_SH;

   --  5.4.3.2 S21, E29: an MA without a mode profile gives FS, nothing
   --  proposed
   procedure Scenario_SoM_L2_MA_Without_Profile is
   begin
      SoM_L2_At_S20;
      Send (Action (5));
      Give_Radio_Message (1, MA_With_Profile (10, -1, 0));
      Stand;
      Stand;
      Check (EVC_Core.Mode = EVC_Modes.M_FS
             and then not EVC_Procedures.Ack_Requested
             and then not EVC_Mission.Proposed
             and then not EVC_Mission.Waiting_For_RBC,
             "mode proposal: an MA without a mode profile (E29) gives FS, "
             & "nothing proposed (5.4.3.2 S21)");
   end Scenario_SoM_L2_MA_Without_Profile;

   --  Up to 5.11.2.2 S150 in level 2: the start of mission of
   --  SoM_L2_At_S20 to SR (no MA on-board), a trip acknowledged (PT, the test entry of the
   --  core), the exit from TR recognised by the RBC (message 6, E125),
   --  then 'Start': the MA request and the wait (S140 b, S150)
   procedure PT_L2_At_S150 is
   begin
      SoM_L2_At_S20;
      Send (Action (5));
      Give_Radio_Message (1, SR_Authorisation (500));
      Stand;
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 1, 0, 0, 0)));
      Stand;
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_PT, EVC_Modes.L2);
      Stand;
      Give_Radio_Message (1, Msg (MCat.Track_M6, Now_T));
      Stand;
      Send (Action (5));
      Check (EVC_Core.Mode = EVC_Modes.M_PT
             and then EVC_Mission.Waiting_For_RBC,
             "PT level 2: 'Start' after message 6 waits for the RBC "
             & "(5.11.2.2 S150)");
   end PT_L2_At_S150;

   --  5.11.2.2 S150 a) -> S160: in PT level 2, the SR authorisation
   --  (message 2) proposes SR, the acknowledgement gives SR (4.6.3 [8])
   procedure Scenario_PT_L2_SR_Proposal is
   begin
      PT_L2_At_S150;
      Give_Radio_Message (1, SR_Authorisation (500));
      Stand;
      Check (EVC_Mission.Proposed
             and then EVC_Mission.Proposed_Mode = EVC_Modes.M_SR
             and then not EVC_Mission.Waiting_For_RBC,
             "PT level 2: message 2 proposes SR (5.11.2.2 S150 a), S160)");
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 1, 0, 0, 0)));
      Stand;
      Check (EVC_Core.Mode = EVC_Modes.M_SR,
             "PT level 2: acknowledged, SR (4.6.3 [8])");
   end Scenario_PT_L2_SR_Proposal;

   --  5.11.2.2 S150 b) -> S170: in PT level 2, an MA with an On Sight
   --  profile at the train's position proposes On Sight (the request of
   --  EVC_Procedures.Profiles_Step, 5.7.4.1), the acknowledgement gives OS
   --  (4.6.3 [15])
   procedure Scenario_PT_L2_Mode_Proposal is
   begin
      PT_L2_At_S150;
      Give_Radio_Message (1, MA_With_Profile (10, 0, 0));
      Stand;
      Stand;
      Check (EVC_Procedures.Ack_Requested
             and then EVC_Procedures.Ack_Mode = EVC_Modes.M_OS
             and then not EVC_Mission.Waiting_For_RBC
             and then EVC_Core.Mode = EVC_Modes.M_PT,
             "PT level 2: an MA with an On Sight profile proposes On Sight "
             & "(5.11.2.2 S150 b), S170)");
      Send (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 1, 0, 0, 0)));
      Stand;
      Check (EVC_Core.Mode = EVC_Modes.M_OS,
             "PT level 2: acknowledged, OS (4.6.3 [15])");
   end Scenario_PT_L2_Mode_Proposal;

   procedure Scenario_Session_SoM_Failures is
   begin
      --  A31 / D31 / A32: three failed attempts (A.3.1)
      SoM_To_S3;
      for I in 1 .. 3 loop
         Give_Radio_Event (1, Set_Up_Failed);
         Stand;
      end loop;
      Check (R.Info (1).State = R.Idle and then Onboard_Byte (12) = 0
             and then Radio_Byte = 2,
             "SoM L2: the session could not be opened after three attempts "
             & "(A32, A.3.1): the driver informed (3.5.7), S10");
      Check (EVC_Sessions."=" (EVC_Sessions.Indication, EVC_Sessions.Connection_Lost),
             "SoM L2: the final attempt to set up the safe radio "
             & "connection failed in a start of mission: ""Connection "
             & "Lost/Set-Up failed"" (3.5.7.5, Table 2 [1])");

      --  A38, D35, A39, A40: the train rejected
      SoM_To_S3;
      Establish (1);
      Give_Radio_Message (1, Msg (MCat.Track_M40, Now_T));
      Stand;
      Check (Output_Of (156) > 0 and then Status_Shown (20, 0),
             "SoM L2: the train rejected (A38): the session terminated "
             & "(156) and 'Train is rejected' shown (A40)");
      --  e5/session-4: the deletion applied by EVC_Core.Evaluate_Radio
      Check (EVC_Position.Status = EVC_Position.Unknown
             and then not EVC_Position.LRBG.Valid,
             "SoM L2: the train rejected, the position deleted (D35, A39)");
   end Scenario_Session_SoM_Failures;

   procedure Scenario_Session_EoM is
   begin
      --  a mission in level 1 with a session: the desk closed, SB: End
      --  of Mission (5.5.2.1.1, 5.5.3.1.3), no repetition (desk closed)
      EVC_Config.Set_Radio_For_Test ((Sessions => 1, Engine_Id => 0, others => <>));
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Run_X (15_000);
      Establish (1);
      Input (TIU, (Byte (TIU_Signal_T'Pos (Cab_A_Active) + 1), 0));
      Stand;
      declare
         N  : constant Natural := Output_Of (150);
         M  : ETCS_Message.Message_T;
         St : ETCS_Message.Status_T := ETCS_Message.Truncated;
      begin
         if N > 0 then
            Decode_Radio_Message (N, M, St);
         end if;
         Check (EVC_Sessions.EoM_Sent = 1 and then N > 0
                and then St = ETCS_Message.Accepted
                and then M.Values (5) = 0,
                "EoM: the mode SB entered with a session: message 150 "
                & "(5.5.3.1.3), Q_DESK 0 the desk closed (8.6.10, "
                & "7.5.1.102.2)");
      end;
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Session_EoM;

   ---------------------------------------------------------------------
   --  Phase 3 (e5/session-4): the position reports of 3.6.5
   ---------------------------------------------------------------------

   --  Message 24 referred to the group NID_BG of country 123 with packet
   --  58: every T_CYC s, no distance period, M_LOC (7.5.1.69)
   function Report_Parameters (NID_BG : Natural; T_Cyc : Natural;
                               M_LOC  : Natural) return Byte_Array
   is
      P  : ETCS_Track_Packets.P58.Packet_T;
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
   begin
      V (3) := Now_T;
      V (5) := 123;
      V (6) := Unsigned_64 (NID_BG);
      Start_Message (W, MCat.Track_M24, V);
      P.Q_DIR := 2;
      P.Q_SCALE := 1;
      P.T_CYCLOC := ETCS_Variables.T_CYCLOC_T (T_Cyc);
      P.D_CYCLOC := 32_767;    -- 7.5.1.18: no distance period
      P.M_LOC := ETCS_Variables.M_LOC_T (M_LOC);
      ETCS_Track_Packets.P58.Encode (P, W, OK);
      Check (OK, "reports: packet 58 encoded");
      return Message_Bytes (W);
   end Report_Parameters;

   --  Message 24 referred to the group NID_BG of country 123 with packet
   --  42: Q_RBC 0, terminate the session (3.5.5.1 a)
   function Terminate_Order (NID_BG : Natural) return Byte_Array is
      P  : TP42.Packet_T;
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
   begin
      V (3) := Now_T;
      V (5) := 123;
      V (6) := Unsigned_64 (NID_BG);
      Start_Message (W, MCat.Track_M24, V);
      P.Q_DIR := 2;
      P.Q_RBC := 0;
      P.NID_C := 5;
      P.NID_RBC := 300;
      P.NID_RADIO := 16#0077#;
      TP42.Encode (P, W, OK);
      Check (OK, "reports: packet 42 encoded");
      return Message_Bytes (W);
   end Terminate_Order;

   procedure Scenario_Session_Reports is
      N : Natural;
   begin
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Add_Group (Group (20, 300));
      Add_Group (Group (30, 500));
      Run_X (15_000);
      Check (EVC_Sessions.Position_Reports_Sent = 0,
             "reports: none without a session (3.6.5.1.4 a, i, j)");
      Establish (1);
      Check (EVC_Sessions.Position_Reports_Sent = 1,
             "reports: the session established, one report (3.6.5.1.4 "
             & "h)");
      N := EVC_Sessions.Position_Reports_Sent;
      Run_X (35_000);
      Stand_X (2_000);
      Check (EVC_Sessions.Position_Reports_Sent = N + 3,
             "reports: standstill left, the LRBG passed without "
             & "parameters, standstill reached (3.6.5.1.4 i, j, a), got"
             & Img (EVC_Sessions.Position_Reports_Sent - N));

      Give_Radio_Message (1, Report_Parameters (20, 5, 2));
      Stand;
      N := EVC_Sessions.Position_Reports_Sent;
      Stand_X (12_000);
      Check (EVC_Sessions.Report_Parameters_Taken = 1
             and then EVC_Sessions.Position_Reports_Sent = N + 2,
             "reports: packet 58 referred to the LRBG, every 5 s: two "
             & "reports in 12 s (3.6.5.1.5 a, 3.6.5.1.7)");
      --  7.5.1.153: T_CYCLOC 255, no time period
      Give_Radio_Message (1, Report_Parameters (20, 255, 2));
      Stand;
      N := EVC_Sessions.Position_Reports_Sent;
      Run_X (55_000);
      Stand_X (2_000);
      Check (EVC_Sessions.Report_Parameters_Taken = 2
             and then EVC_Sessions.Position_Reports_Sent = N + 2,
             "reports: new parameters replace the old (3.6.5.1.7); with "
             & "parameters stored the passage of an LRBG is not reported "
             & "(3.6.5.1.4 j), standstill left and reached are, got"
             & Img (EVC_Sessions.Position_Reports_Sent - N));

      --  4.5.2, "Report Train Position": in Shunting neither standstill
      --  left or reached nor what the RBC requested is reported
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SH, EVC_Modes.L2);
      Stand;
      N := EVC_Sessions.Position_Reports_Sent;
      Run_X (8_000);
      Stand_X (2_000);
      Check (EVC_Core.Mode = EVC_Modes.M_SH
             and then EVC_Sessions.Position_Reports_Sent = N,
             "reports: none in Shunting for standstill left and reached "
             & "(4.5.2 table, rows 3.6.5.1.4 a, i), got"
             & Img (EVC_Sessions.Position_Reports_Sent - N));

      --  4.8.4, "Position Report parameters" (e5/radio-items, B211):
      --  rejected in SH (SUBSET-076 4080428_01 step 99)
      N := EVC_Sessions.Report_Parameters_Taken;
      Give_Radio_Message (1, Report_Parameters (20, 5, 2));
      Stand;
      Check (EVC_Sessions.Report_Parameters_Taken = N,
             "reports: packet 58 received in Shunting is rejected (4.8.4, "
             & "Position Report parameters: R in SH)");

      --  3.5.5.1 a): the order to terminate by radio
      Give_Radio_Message (1, Terminate_Order (30));
      Stand;
      Check (Output_Of (156) > 0,
             "reports: packet 42 Q_RBC 0 by radio, the session terminated "
             & "(3.5.5.1 a): 156");
   end Scenario_Session_Reports;

   --  The RTM outputs after From that are message 136 on session 1 with
   --  packet 4: their count, the M_ERROR of the last
   procedure Error_Reports (From  : Natural;
                            Count : out Natural;
                            Error : out Natural)
   is
      M  : ETCS_Message.Message_T;
      St : ETCS_Message.Status_T;
      P  : ETCS_Train_Packets.P4.Packet_T;
      OK : Boolean;
   begin
      Count := 0;
      Error := 999;
      for N in From + 1 .. Radio_Outputs loop
         if Is_Message (N, 136) then
            Decode_Radio_Message (N, M, St);
            for I in 1 .. M.Count loop
               if St = ETCS_Message.Accepted and then M.Index (I).NID = 4
               then
                  declare
                     Rd : ETCS_Bits.Reader (ETCS_Message.Max_Bytes);
                  begin
                     ETCS_Message.Open_Packet (M, I, Rd);
                     ETCS_Train_Packets.P4.Decode (Rd, P, OK);
                     if OK then
                        Count := Count + 1;
                        Error := Natural (P.M_ERROR);
                     end if;
                  end;
               end if;
            end loop;
         end if;
      end loop;
   end Error_Reports;

   --  Runs to To_Cm a cycle at a time; of the last 136 sent on the way:
   --  the NID of its first packet (0 or 1; 999 without one) and, for
   --  packet 1, its NID_PRVLRBG's NID_BG
   procedure Run_Reports (To_Cm : Integer_64;
                          First : out Natural;
                          Prev  : out Natural)
   is
      M  : ETCS_Message.Message_T;
      St : ETCS_Message.Status_T;
      P  : R1.Packet_T;
      OK : Boolean;
   begin
      First := 999;
      Prev := 999;
      while Train_Cm < To_Cm loop
         Run_X (Integer_64'Min (Train_Cm + 1000, To_Cm));
         for N in 1 .. Radio_Outputs loop
            if Is_Message (N, 136) then
               Decode_Radio_Message (N, M, St);
               if St = ETCS_Message.Accepted and then M.Count >= 1 then
                  First := Natural (M.Index (1).NID);
                  Prev := 999;
                  if First = 1 then
                     declare
                        Rd : ETCS_Bits.Reader (ETCS_Message.Max_Bytes);
                     begin
                        ETCS_Message.Open_Packet (M, 1, Rd);
                        R1.Decode (Rd, P, OK);
                        Prev := (if OK then Natural (P.NID_BG_PRVLRBG)
                                 else 999);
                     end;
                  end if;
               end if;
            end if;
         end loop;
      end loop;
   end Run_Reports;

   --  e5/report-packet: the packet of a 136 after a single balise group.
   --  3.4.2.3.2.2, 3.4.4.4: a linked single group gets its orientation
   --  from the linking, the report is packet 0; 3.4.2.3.3.1, .2: an
   --  unlinked one, the previous LRBG known, packet 1 with that previous
   --  LRBG (the case of SUBSET-076 5150400_02 step 71, BG2d)
   --  Message 24 referred to the group NID_BG with packet 74, the fixed
   --  text to acknowledge from the group on, its report of the driver's
   --  acknowledgement (Report) to the RBC NID_RBC of country 5
   function M24_Text (NID_BG : Natural; Report : Boolean;
                      Id, NID_RBC : Natural) return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
      P  : ETCS_Track_Packets.P74.Packet_T;
   begin
      V (3) := Now_T;
      V (5) := 123;
      V (6) := Unsigned_64 (NID_BG);
      Start_Message (W, MCat.Track_M24, V);
      P.Q_DIR := 2;
      P.Q_SCALE := 1;
      P.Q_TEXT := 1;
      P.L_TEXTDISPLAY := 1000;
      P.T_TEXTDISPLAY := 1023;
      P.M_MODETEXTDISPLAY := 15;
      P.M_LEVELTEXTDISPLAY := 4;
      P.M_MODETEXTDISPLAY_2 := 15;
      P.M_LEVELTEXTDISPLAY_2 := 4;
      P.Q_TEXTCONFIRM := 1;
      P.Has_Q_CONFTEXTDISPLAY := True;
      if Report then
         P.Q_TEXTREPORT := 1;
         P.Has_NID_TEXTMESSAGE := True;
         P.NID_TEXTMESSAGE := ETCS_Variables.NID_TEXTMESSAGE_T (Id);
         P.NID_C := 5;
         P.NID_RBC := ETCS_Variables.NID_RBC_T (NID_RBC);
      end if;
      ETCS_Track_Packets.P74.Encode (P, W, OK);
      Check (OK, "text report: packet 74 encoded");
      return Message_Bytes (W);
   end M24_Text;

   --  The driver acknowledges the text of on-board identifier Id (Table
   --  40, kind 2: a fixed text)
   procedure Ack_Text (Id : Natural) is
   begin
      Send (Frame (16#40#, (2, 2, 0, Byte (Id), 0)));
   end Ack_Text;

   procedure Scenario_Text_Ack_Report is
      M  : ETCS_Message.Message_T;
      St : ETCS_Message.Status_T;
      N  : Natural;
   begin
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Run_X (15_000);
      Establish (1);
      Give_Radio_Message (1, M24_Text (10, True, 7, 300));
      Stand;
      Give_Radio_Message (1, M24_Text (10, False, 0, 300));
      Stand;
      Give_Radio_Message (1, M24_Text (10, True, 9, 301));
      Stand;
      Ack_Text (1);
      N := Output_Of (158);
      if N > 0 then
         Decode_Radio_Message (N, M, St);
      end if;
      Check (N > 0 and then St = ETCS_Message.Accepted
             and then M.Values (5) = 7 and then M.Count = 1,
             "text report: the acknowledgement reported to the RBC of the "
             & "request, message 158 with NID_TEXTMESSAGE and packet 0 "
             & "(3.12.3.5.2, 8.6.16)");
      Ack_Text (2);
      Check (Output_Of (158) = 0,
             "text report: no report requested, no message 158");
      Ack_Text (3);
      Check (Output_Of (158) = 0,
             "text report: no session with the RBC of the request, no "
             & "message 158 (3.12.3.5.2, decision)");
   end Scenario_Text_Ack_Report;

   procedure Scenario_Report_Packet is
      First, Prev : Natural;
   begin
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Add_Group (With_Links (Group (20, 300),
                             Link_To ((1 => 200), (1 => 30))));
      Add_Group (Group (30, 500, 1));
      Add_Group (Group (40, 700, 1));
      Run_X (15_000);
      Establish (1);
      Run_X (40_000);
      Run_Reports (55_000, First, Prev);
      Check (Natural (EVC_Position.LRBG.Id.NID_BG) = 30 and then First = 0,
             "report packet: a linked single group, packet 0 "
             & "(3.4.2.3.2.2, 3.4.4.4), got" & Img (First));
      Run_Reports (75_000, First, Prev);
      Check (Natural (EVC_Position.LRBG.Id.NID_BG) = 40 and then First = 1
             and then Prev = 30,
             "report packet: an unlinked single group, packet 1 with the "
             & "previous LRBG (3.4.2.3.3.1, 3.4.2.3.3.2), got"
             & Img (First) & Img (Prev));
   end Scenario_Report_Packet;

   procedure Scenario_Session_Error_Report is
      Count, Error, Recorded : Natural := 0;
      T : Unsigned_64;

      --  Two cycles, the error reports of each added up
      procedure Step is
         C, E : Natural;
      begin
         for K in 1 .. 2 loop
            Stand;
            Error_Reports (0, C, E);
            Count := Count + C;
            Recorded := Recorded + JRU_Count (13);
            if C > 0 then
               Error := E;
            end if;
         end loop;
      end Step;
   begin
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Run_X (15_000);
      Establish (1);
      T := Now_T (100);
      Give_Radio_Message (1, Msg (MCat.Track_M24, T));
      Step;
      Check (Count = 0,
             "error report: none for a consistent message 24, got"
             & Img (Count));
      --  3.16.3.3.3: a stamp not above the last one, the message rejected
      Give_Radio_Message (1, Msg (MCat.Track_M24, T));
      Step;
      Check (Count = 1 and then Error = 4,
             "error report: the stamp not above the last (3.16.3.3.3), "
             & "one 136 with packet 4 M_ERROR 4 (3.16.3.1.1 b, "
             & "3.16.3.1.1.2, 7.4.3.4, 7.5.1.64), got" & Img (Count)
             & Img (Error));
      Give_Radio_Message (1, Msg (MCat.Track_M24, T - 1));
      Give_Radio_Message (1, Msg (MCat.Track_M24, T - 2));
      Step;
      Check (Count = 3 and then Error = 4,
             "error report: once per inconsistent message, two in one "
             & "cycle reported in two messages (3.16.3.1.1.2), got"
             & Img (Count));
      Check (Recorded = 3,
             "error report: each recorded as JRU record 13, got"
             & Img (Recorded));
      --  3.17.3.11 b): an unknown NID_MESSAGE is no consistency error,
      --  nothing reported
      declare
         M : Byte_Array := Msg (MCat.Track_M24, T + 5);
      begin
         M (M'First) := 255;
         Give_Radio_Message (1, M);
      end;
      Step;
      Check (Count = 3 and then Recorded = 3,
             "error report: none for an unknown NID_MESSAGE (3.17.3.11 b), "
             & "got" & Img (Count) & Img (Recorded));
      --  3.16.1.1.1, 3.16.3.1.1 c): a message the codec refuses (a spare
      --  value, Q_DIR 3 in a packet), M_ERROR 3
      declare
         W : Writer_T;
         V : ETCS_Message.Value_Array := (others => 0);
      begin
         V (3) := T + 10;
         Start_Message (W, MCat.Track_M24, V);
         ETCS_Bits.Write (W, 8, 200);   -- NID_PACKET
         ETCS_Bits.Write (W, 2, 3);     -- Q_DIR spare
         ETCS_Bits.Write (W, 13, 40);   -- L_PACKET
         ETCS_Bits.Fill (W, 17, One => True);
         Give_Radio_Message (1, Message_Bytes (W));
      end;
      Step;
      Check (Count = 4 and then Error = 3 and then Recorded = 4,
             "error report: a message refused by the codec, packet 4 "
             & "M_ERROR 3 (3.16.1.1, 3.16.3.1.1, 7.5.1.64) and JRU record "
             & "13, got" & Img (Count) & Img (Error) & Img (Recorded));
      --  e5/reports-136, 3.16.1.1: a packet chapter 7 does not define
      --  (NID_PACKET 155, which the codec skips by its L_PACKET) makes the
      --  message not compliant: M_ERROR 3 (SUBSET-076 7040200_03 step 65)
      declare
         W : Writer_T;
         V : ETCS_Message.Value_Array := (others => 0);
      begin
         V (3) := T + 20;
         Start_Message (W, MCat.Track_M24, V);
         ETCS_Bits.Write (W, 8, 155);   -- NID_PACKET
         ETCS_Bits.Write (W, 2, 0);     -- Q_DIR
         ETCS_Bits.Write (W, 13, 31);   -- L_PACKET
         ETCS_Bits.Write (W, 8, 0);
         Give_Radio_Message (1, Message_Bytes (W));
      end;
      Step;
      Check (Count = 5 and then Error = 3 and then Recorded = 5,
             "error report: a message with a packet chapter 7 does not "
             & "define, packet 4 M_ERROR 3 (3.16.1.1, 3.16.3.1.1.2), got"
             & Img (Count) & Img (Error) & Img (Recorded));
   end Scenario_Session_Error_Report;

   --  e5/jru-radio, SUBSET-027 record 9 (the on-board's JRU event 3):
   --  every message received (3.16.3.1.1.2) recorded once, at reception,
   --  used or not, consistent or not (SUBSET-076 4080436_01 step 70)
   procedure Scenario_Session_JRU_Received is
      Received, Refused : Natural := 0;
      T : Unsigned_64;

      --  Two cycles, the records of each added up
      procedure Step is
      begin
         Received := 0;
         Refused := 0;
         for K in 1 .. 2 loop
            Stand;
            Received := Received + JRU_Count (3);
            Refused := Refused + JRU_Count (13);
         end loop;
      end Step;

      procedure Expect (Text : String; R, E : Natural) is
      begin
         Check (Received = R and then Refused = E,
                "JRU message from the RBC: " & Text & ", record 9 (event 3)"
                & " and 13 expected" & Img (R) & Img (E) & ", got"
                & Img (Received) & Img (Refused));
      end Expect;
   begin
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Run_X (15_000);
      Establish (1);
      T := Now_T (100);
      --  message 24 without M_ACK: received, not used by any consumer
      Give_Radio_Message (1, Msg (MCat.Track_M24, T));
      Step;
      Expect ("a message 24 without effect", 1, 0);
      --  message 24 with M_ACK, taken and answered by 146: no second record
      Give_Radio_Message (1, Msg (MCat.Track_M24, T + 10, Ack => 1));
      Step;
      Expect ("a message 24 taken by a consumer", 1, 0);
      --  3.16.3.3.3: the stamp not above the last, refused after reception
      Give_Radio_Message (1, Msg (MCat.Track_M24, T));
      Step;
      Expect ("a message refused by its time stamp", 1, 1);
      --  3.17.3.11 b): an unknown NID_MESSAGE (254) recorded, not
      --  reported (SUBSET-076 8040400_01 step 64)
      declare
         M : Byte_Array := Msg (MCat.Track_M24, T + 20);
      begin
         M (M'First) := 254;
         Give_Radio_Message (1, M);
      end;
      Step;
      Expect ("an unknown message (254)", 1, 0);
      --  two messages in one cycle: two records
      Give_Radio_Message (1, Msg (MCat.Track_M24, T + 30));
      Give_Radio_Message (1, Msg (MCat.Track_M24, T + 40));
      Step;
      Expect ("two messages", 2, 0);
   end Scenario_Session_JRU_Received;

   --  3.6.1.7, 3.18.3 (tenth round): the train length of the valid Train
   --  Data reaches the position once per cycle (EVC_Core
   --  Sync_Train_Length), so that the min safe rear end and its triggers
   --  (3.6.5.1.5 c, 3.15.1.3.1 c) exist in service, not only in the tests
   --  of EVC_Position; a fresh on-board without Train Data knows none
   procedure Scenario_Train_Length_To_Position is
      use type EVC_Distances.Cm_T;
   begin
      SoM_L2_At_S20;
      Stand;
      Check (EVC_Position.Train_Length_Known
             and then EVC_Position.Length_Of_Train = EVC_Train_Data.Length
             and then EVC_Train_Data.Length > 0,
             "train length: the valid Train Data's length known to the "
             & "position (3.6.1.7)");
      Check (EVC_Position.Min_Safe_Rear
               = EVC_Position.Min_Safe_Front - EVC_Train_Data.Length,
             "train length: the min safe rear end behind the front by it");
      EVC_Test_Modes.Start_E4;
      Stand;
      Check (not EVC_Position.Train_Length_Known,
             "train length: none without valid Train Data");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Train_Length_To_Position;

   --  3.5.3.4 c), 4.5.2, 4.8.4 [3] (e5/mode-change-session): in level 2,
   --  Shunting, a group's packet 42 stores the RBC contact without a
   --  session; Exit Shunting to SB is a mode change to report: the
   --  session is set up, then the position report goes. Without a
   --  contact nothing is requested.
   procedure Scenario_Session_Mode_Change is
      N : Natural;
   begin
      for With_Contact in reverse Boolean loop
         Start_X;
         if With_Contact then
            Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
         else
            Add_Group (Group (10, 100));
         end if;
         EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SH, EVC_Modes.L2);
         Run_X (15_000);
         Stand_X (2_000);
         Check (EVC_Core.Mode = EVC_Modes.M_SH
                and then R.Info (1).State = R.Idle
                and then R.Contact.Known = With_Contact,
                "mode change session: in SH the packet 42 stores the "
                & "contact, no session (4.8.4 [3]), contact "
                & Boolean'Image (With_Contact) & " "
                & EVC_Modes.Mode_T'Image (EVC_Core.Mode) & " "
                & R.Session_State_T'Image (R.Info (1).State) & " "
                & Boolean'Image (R.Contact.Known));
         N := EVC_Sessions.Position_Reports_Sent;
         Send (Action (8));
         Stand;
         Check (EVC_Core.Mode = EVC_Modes.M_SB
                and then (R.Info (1).State = R.Connecting) = With_Contact,
                "mode change session: Exit Shunting to SB in level 2 "
                & "(4.5.2: reported), the set-up requested with a stored "
                & "contact only (3.5.3.4 c), contact "
                & Boolean'Image (With_Contact));
         if With_Contact then
            Establish (1);
            Check (EVC_Sessions.Position_Reports_Sent > N,
                   "mode change session: the session established, the "
                   & "position report sent (3.6.5.1.4 b, h)");
         end if;
      end loop;
   end Scenario_Session_Mode_Change;

   --  3.5.3.7 a): the session of a mode change to report (3.5.3.4 c) is
   --  given up after the third failed set-up of its safe radio connection
   --  (A.3.1), no start of mission ongoing: "No Connection" (3.5.7.5
   --  Table 2 [3], not [1])
   procedure Scenario_Session_Mode_Change_Capped is
      use type EVC_Sessions.Indication_T;
   begin
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SH, EVC_Modes.L2);
      Run_X (15_000);
      Stand_X (2_000);
      Send (Action (8));
      Stand;
      for I in 1 .. 2 loop
         Give_Radio_Event (1, Set_Up_Failed);
         Stand;
      end loop;
      Check (R.Info (1).State = R.Connecting,
             "mode change capped: after two failed set-ups of the safe "
             & "radio connection a third requested (3.5.3.7 a)");
      Give_Radio_Event (1, Set_Up_Failed);
      Stand;
      Check (R.Info (1).State = R.Idle
             and then EVC_Sessions.Indication = EVC_Sessions.No_Connection,
             "mode change capped: the session of 3.5.3.4 c) given up after "
             & "the third failed set-up (3.5.3.7 a, A.3.1), No Connection "
             & "(Table 2 [3]) "
             & R.Session_State_T'Image (R.Info (1).State));
   end Scenario_Session_Mode_Change_Capped;

   --  3.5.4.5: a message to send while the safe radio connection is lost
   --  is considered as sent: the position report requested then is
   --  neither given to the RTM port nor kept for the reconnection
   procedure Scenario_Session_Lost_Send is
      N : Natural;
   begin
      EVC_Config.Set_Radio_For_Test ((Sessions => 1, others => <>));
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Run_X (15_000);
      Establish (1);
      Give_Radio_Event (1, Connection_Lost);
      Stand;
      N := EVC_Sessions.Position_Reports_Sent;
      EVC_Sessions.Request_Position_Report;
      Stand;
      Check (R.Info (1).State = R.Connection_Lost
             and then EVC_Sessions.Position_Reports_Sent = N
             and then not (for some I in 1 .. Radio_Outputs =>
                             Is_Message (I, 136)),
             "lost send: the position report due while the safe radio "
             & "connection is lost is not given to the port (3.5.4.5)");
      Give_Radio_Event (1, Connection_Set_Up);
      Stand;
      Check (R.Info (1).State = R.Established
             and then EVC_Sessions.Position_Reports_Sent = N,
             "lost send: considered as sent, it is not sent after the "
             & "connection is set up again (3.5.4.5) "
             & Natural'Image (EVC_Sessions.Position_Reports_Sent - N));
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Session_Lost_Send;

   --  The release of the safe radio connection of S requested in the
   --  last cycle
   function Released (S : Natural := 1) return Boolean is
     (for some N in 1 .. Radio_Outputs => Is_Request (N, 2, S));

   --  3.5.3.8 a): the driver closes the desk during a level 2 start of
   --  mission while its session is being established: the establishment
   --  aborted, the safe radio connection released
   procedure Scenario_Session_Abort_Desk is
   begin
      SoM_To_S3;
      Check (R.Being_Established (1),
             "abort desk: the session of the start of mission being "
             & "established");
      Input (TIU, (Byte (TIU_Signal_T'Pos (Cab_A_Active) + 1), 0));
      Stand;
      Check (R.Info (1).State = R.Idle and then Released,
             "abort desk: the desk closed during the start of mission: "
             & "the establishment aborted, the connection released "
             & "(3.5.3.8 a)");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Session_Abort_Desk;

   --  3.5.3.8 b): End of Mission (the desk closed in level 1) while a
   --  session ordered by a balise group is being established
   procedure Scenario_Session_Abort_EoM is
   begin
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 0, others => <>));
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Run_X (15_000);
      Check (R.Being_Established (1),
             "abort EoM: the session ordered by the group being "
             & "established");
      Input (TIU, (Byte (TIU_Signal_T'Pos (Cab_A_Active) + 1), 0));
      Stand;
      Check (R.Info (1).State = R.Idle and then Released
             and then EVC_Sessions.EoM_Sent = 0,
             "abort EoM: End of Mission: the establishment aborted, the "
             & "connection released, no 150 (3.5.3.8 b)");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Session_Abort_EoM;

   --  3.5.3.11: the driver selects the EIRENE short number in a level 2
   --  start of mission: the stored RBC ID and phone number not used
   procedure Scenario_Session_Short_Number is
      Stored : constant R.RBC_Contact_T :=
        (Known => True, Valid => True,
         RBC   => (NID_C => 5, NID_RBC => 300),
         Radio => 16#0077_FFFF_FFFF_FFFF#);
   begin
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 76_000, others => <>));
      EVC_Test_Modes.Start_E4;
      R.Set_Contact (Stored);
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 5));
      Send (RBC_Entry (2, 0, ""));
      Check (R.Being_Established (1)
             and then R.Info (1).RBC = R.No_RBC
             and then R.Info (1).Radio = ETCS_Variables.NID_RADIO_T'Last
             and then R.Contact.RBC = Stored.RBC,
             "short number: the session set up with the EIRENE short "
             & "number, not the stored RBC ID and number, which stay "
             & "(3.5.3.11)");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Session_Short_Number;

   --  3.5.3.4 g): a level 2 start of mission during which no session
   --  could be established (three failed attempts) completed: the mode
   --  change out of SB (EVC_Sessions.Mode_Changed, as EVC_Core calls it)
   --  establishes the session with the stored contact
   procedure Scenario_Session_SoM_Completed is
   begin
      SoM_To_S3;
      for I in 1 .. 3 loop
         Give_Radio_Event (1, Set_Up_Failed);
         Stand;
      end loop;
      Check (R.Info (1).State = R.Idle and then R.Contact.Valid,
             "SoM completed: no session after three attempts, the "
             & "entered contact valid");
      EVC_Sessions.Mode_Changed (EVC_Modes.M_SB, EVC_Modes.M_SR);
      Stand;
      Check (R.Being_Established (1)
             and then R.Info (1).RBC = (NID_C => 5, NID_RBC => 300),
             "SoM completed: the start of mission completed in level 2 "
             & "without a session: the session established (3.5.3.4 g)");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Session_SoM_Completed;

   --  3.5.3.8 g), 3.5.3.4 e): a session ordered by a balise group is
   --  being established when the engine reaches an announced
   --  radio hole: aborted, its connection released; established again
   --  once the engine has left the hole
   procedure Scenario_Session_Hole_Rows is
      C       : T68.Packet_T;
      Any_Rel : Boolean := False;
      Any_Req : Boolean := False;
   begin
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 0, others => <>));
      Start_X;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Add_Group (Group (20, 200));
      C.Q_DIR := 2;
      C.Q_SCALE := 1;
      C.Q_TRACKINIT := 0;
      C.Has_D_TRACKCOND := True;
      C.D_TRACKCOND := 100;
      C.L_TRACKCOND := 200;
      C.M_TRACKCOND := 4;
      Carry (Track_N, 0, C);
      Run_X (15_000);
      Check (R.Being_Established (1)
             and then not EVC_Track_Conditions.Engine_In_Radio_Hole,
             "hole rows: the session ordered at 100 m being established "
             & "before the hole");
      for I in 1 .. 30 loop
         Step_X (1000);
         Any_Rel := Any_Rel or else Released;
         exit when EVC_Track_Conditions.Engine_In_Radio_Hole;
      end loop;
      Check (EVC_Track_Conditions.Engine_In_Radio_Hole
             and then R.Info (1).State = R.Idle and then Any_Rel,
             "hole rows: the engine front end at the start of the radio "
             & "hole: the establishment aborted, the connection released "
             & "(3.5.3.8 g)");
      --  the run goes on in level 2 (3.5.3.4 e is a level 2 condition;
      --  the group's packet 68 is read in level 1)
      EVC_Core.Set_Mode_For_Test (EVC_Core.Mode, EVC_Modes.L2);
      for I in 1 .. 40 loop
         Step_X (1000);
         Any_Req := Any_Req
           or else (for some N in 1 .. Radio_Outputs => Is_Request (N, 1));
         exit when not EVC_Track_Conditions.Engine_In_Radio_Hole;
      end loop;
      Check (not EVC_Track_Conditions.Engine_In_Radio_Hole
             and then Any_Req and then R.Being_Established (1),
             "hole rows: the engine has left the radio hole: the session "
             & "established again in level 2 (3.5.3.4 e)");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Session_Hole_Rows;

   --  3.5.3.4 h): in level 2 outside the start of mission the driver
   --  selects another RBC's contact in the Radio data window: the
   --  session with it established (the one with the former RBC
   --  terminated, 3.5.3.5.2); the same RBC again: no second session
   --  (3.5.3.4.1)
   procedure Scenario_Session_Driver_Contact is
      Other : constant R.RBC_Id_T := (NID_C => 5, NID_RBC => 301);
   begin
      Start_X;
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_FS, EVC_Modes.L2);
      EVC_Test_Authority.Establish_Session;
      Send (RBC_Entry (0, 5 * 16_384 + 301, "0078"));
      Check (R.In_Session_With (Other)
             and then (for some S in R.Session_T =>
                         R.Being_Established (S)
                         and then R.Info (S).RBC = Other)
             and then R.Info (1).State = R.Terminating,
             "driver contact: the RBC contact selected in level 2 outside "
             & "the start of mission: the session with it being "
             & "established, the former one terminated (3.5.3.4 h)");
      Send (RBC_Entry (0, 5 * 16_384 + 301, "0078"));
      Check ((for all S in R.Session_T =>
                (if R.Info (S).RBC = Other
                 then R.Info (S).State /= R.Idle)),
             "driver contact: the same contact again: no second session "
             & "(3.5.3.4.1)");
   end Scenario_Session_Driver_Contact;


   --  3.16.3.4.1.3: T_NVCONTACT 10 s, train trip as its reaction;
   --  no supervision while the engine overlaps an announced radio hole;
   --  after it, until a new message, the time the engine left the hole
   --  is the reference
   procedure Scenario_Session_Hole_Contact is
      NV : Sim_Telegrams.T3.Packet_T := Sim_Telegrams.National_Values (123);
      C  : T68.Packet_T;
   begin
      Start_X;
      NV.T_NVCONTACT := 10;   -- s
      NV.M_NVCONTACT := 0;    -- train trip
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Carry (Track_N, 1, NV);
      Add_Group (Group (20, 200));
      C.Q_DIR := 2;
      C.Q_SCALE := 1;
      C.Q_TRACKINIT := 0;
      C.Has_D_TRACKCOND := True;
      C.D_TRACKCOND := 100;
      C.L_TRACKCOND := 200;
      C.M_TRACKCOND := 4;
      Carry (Track_N, 0, C);
      Run_X (15_000);
      Establish (1);
      Run_X (35_000);
      Sample (0);
      EVC_Core.Tick (11_000);
      Take;
      Check (EVC_Track_Conditions.Engine_In_Radio_Hole
             and then not EVC_Sessions.T_NVCONTACT_Trip,
             "hole contact: no message for more than T_NVCONTACT while the "
             & "engine overlaps the radio hole: no reaction (3.16.3.4.1.3)");
      for I in 1 .. 40 loop
         Step_X (1000);
         exit when not EVC_Track_Conditions.Engine_In_Radio_Hole;
      end loop;
      Check (not EVC_Track_Conditions.Engine_In_Radio_Hole
             and then not EVC_Sessions.T_NVCONTACT_Trip,
             "hole contact: out of the hole, the latest message older than "
             & "T_NVCONTACT: no reaction, the time of leaving the hole is "
             & "the reference (3.16.3.4.1.3)");
      Sample (0);
      EVC_Core.Tick (11_000);
      Take;
      Check (EVC_Sessions.T_NVCONTACT_Trip,
             "hole contact: T_NVCONTACT after leaving the hole without a "
             & "message: the trip (3.16.3.4.1.3, 3.16.3.4.2 a)");
      Give_Radio_Message (1, Msg (MCat.Track_M24, Now_T (1)));
      Stand;
   end Scenario_Session_Hole_Contact;

   --  3.16.3.3.2: two messages of one cycle, the acknowledgement 146 of
   --  a message 24 with M_ACK and the Train Data 129, carry different
   --  time stamps; the acknowledgement 8 of the 129 is matched on the
   --  stamp it was sent with
   procedure Scenario_Session_Stamp_Increment is
      M   : ETCS_Message.Message_T;
      St  : ETCS_Message.Status_T;
      N9  : Natural;
      N6  : Natural;
      T9  : Unsigned_64 := 0;
      T6  : Unsigned_64 := 0;
   begin
      SoM_To_S3;
      Give_Radio_Event (1, Connection_Set_Up);
      Stand;
      Give_Radio_Message (1, Msg (MCat.Track_M32, Now_T, 0, 7, 48));
      Stand;
      Give_Radio_Message (1, Msg (MCat.Track_M38, Now_T));
      Stand;
      Give_Radio_Message (1, Msg (MCat.Track_M41, Now_T));
      Stand;
      Give_Radio_Message (1, Msg (MCat.Track_M24, Now_T, 1));
      Send (Train_Entry);
      N9 := Output_Of (129);
      N6 := Output_Of (146);
      if N9 > 0 then
         Decode_Radio_Message (N9, M, St);
         T9 := M.Values (3);
      end if;
      if N6 > 0 then
         Decode_Radio_Message (N6, M, St);
         T6 := M.Values (3);
      end if;
      Check (N9 > 0 and then N6 > 0 and then T9 /= T6
             and then (T9 = T6 + 1 or else T6 = T9 + 1)
             and then Unsigned_64 (R.Info (1).Last_Sent)
                      = Unsigned_64'Max (T9, T6),
             "stamps: 146 and 129 of one cycle one unit apart, the "
             & "second above the first (3.16.3.3.2)");
      Ack_Train_Data (N9);
      Check (R.Train_Data_Acknowledged,
             "stamps: the 8 with the stamp the 129 was sent with "
             & "acknowledges it (3.16.3.3.2, 3.18.3.4.1)");
   end Scenario_Session_Stamp_Increment;

   --  3.16.3.4.5 a), 3.14.1.7: the service brake of T_NVCONTACT stays
   --  when national values with a longer T_NVCONTACT are taken while it
   --  is applied; a new message releases it
   procedure Scenario_Session_NVCONTACT_Values is
      NV  : Sim_Telegrams.T3.Packet_T := Sim_Telegrams.National_Values (123);
      NV2 : Sim_Telegrams.T3.Packet_T := Sim_Telegrams.National_Values (123);
   begin
      Start_X;
      NV.T_NVCONTACT := 5;    -- s
      NV.M_NVCONTACT := 1;    -- service brake
      NV2.T_NVCONTACT := 60;
      NV2.M_NVCONTACT := 1;
      Order_Group (10, 100, Q_RBC => 1, NID_RBC => 300);
      Carry (Track_N, 1, NV);
      Add_Group (Group (11, 320));
      Carry (Track_N, 1, NV2);
      Run_X (15_000);
      Establish (1);
      Run_X (30_000, 200);
      Check (EVC_Sessions.Service_Brake,
             "link values: T_NVCONTACT 5 s passed, the service brake");
      Run_X (34_000, 200);
      Check (EVC_National_Values.Current.T_NVCONTACT = 60_000,
             "link values: T_NVCONTACT 60 s taken at 320 m");
      Check (EVC_Sessions.Service_Brake,
             "link values: T_NVCONTACT 60 s taken at 320 m, the service "
             & "brake kept until standstill or a new message (3.16.3.4.5 "
             & "a, 3.14.1.7)");
      Give_Radio_Message (1, Msg (MCat.Track_M24, Now_T (1)));
      Stand;
      Check (not EVC_Sessions.Service_Brake,
             "link values: a new message releases it (3.14.1.7)");
   end Scenario_Session_NVCONTACT_Values;

end EVC_Test_Sessions;
