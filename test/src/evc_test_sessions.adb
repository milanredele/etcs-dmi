--  ETCS on-board (EVC)
--  Phase E5, the session and link half (see the specification).

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P42;
with ETCS_Variables;
with DMI_Protocol;
with EVC_Config;
with EVC_DMI_Port;
with EVC_Core;
with EVC_Modes;
with EVC_Procedures;
with EVC_Ports;           use EVC_Ports;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Sessions;
with EVC_Test_Support;    use EVC_Test_Support;
with Interfaces;          use Interfaces;
with Sim_Telegrams;

package body EVC_Test_Sessions is

   package MCat renames ETCS_Message_Catalogue;
   package R renames EVC_Radio;
   package TP42 renames ETCS_Track_Packets.P42;
   use type ETCS_Message.Status_T;
   use type ETCS_Message_Catalogue.Message_Kind_T;
   use type EVC_Modes.Mode_T;
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
      Check (Radio_Outputs = 1 and then Is_Message (1, 159)
             and then St = ETCS_Message.Accepted and then M.Count = 1
             and then R.Info (1).State = R.Established
             and then R.Info (1).Version = 48
             and then R.Supervising = 1 and then R.In_Communication,
             "session: the system version 3.0, established, message 159 "
             & "with packet 2 (3.5.3.7 d), the supervising RBC");

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
      EVC_Config.Set_Radio_For_Test ((Sessions => 1));
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
      Check (R.Info (1).State = R.Established and then Radio_Outputs = 0,
             "session: set up again within the session (3.5.4.3)");
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

end EVC_Test_Sessions;
