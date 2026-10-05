--  ETCS on-board (EVC)
--  Phase E5, the session and link half (see the specification).

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P42;
with ETCS_Track_Packets.P58;
with ETCS_Variables;
with DMI_Protocol;
with EVC_Config;
with EVC_DMI_Port;
with EVC_Core;
with EVC_Bytes;
with EVC_Mission;
with EVC_Modes;
with EVC_Position;
with EVC_Procedures;
with EVC_Ports;           use EVC_Ports;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Sessions;
with EVC_Test_Modes;
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
             and then Radio_Outputs = 1 and then Is_Message (1, 146)
             and then St = ETCS_Message.Accepted
             and then M.Values (5) = Now_T (5) - 10,
             "session: a message not newer than the last is ignored "
             & "(3.16.3.3.3), the one taken acknowledged by 146 with its "
             & "time stamp (3.16.3.5)");

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

      --  3.5.3.7 d): no compatible version
      Establish (1, V => 32);
      Check (Radio_Outputs = 2 and then Is_Message (1, 154)
             and then Is_Message (2, 156)
             and then R.Info (1).State = R.Terminating,
             "session: version 2.0 not compatible: 154, then terminated "
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
      EVC_Config.Set_Radio_For_Test ((Sessions => 1, Engine_Id => 76_000));
      EVC_Test_Modes.Start_E4;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 5));
      Send (RBC_Entry (0, 5 * 16_384 + 300, "0077"));
   end SoM_To_S3;

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
      EVC_Config.Set_Radio_For_Test ((Sessions => 1, Engine_Id => 0));
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

      --  3.5.5.1 a): the order to terminate by radio
      Give_Radio_Message (1, Terminate_Order (30));
      Stand;
      Check (Output_Of (156) > 0,
             "reports: packet 42 Q_RBC 0 by radio, the session terminated "
             & "(3.5.5.1 a): 156");
   end Scenario_Session_Reports;

end EVC_Test_Sessions;
