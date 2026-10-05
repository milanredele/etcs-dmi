--  ETCS on-board (EVC)
--  Phase E5, the radio (see the specification).

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Variables;
with EVC_Config;
with EVC_Core;
with EVC_Modes;
with EVC_Ports;           use EVC_Ports;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Received;
with EVC_Sessions;
with EVC_Test_Support;    use EVC_Test_Support;
with Interfaces;          use Interfaces;

package body EVC_Test_Radio is

   package MCat renames ETCS_Message_Catalogue;
   use type ETCS_Message.Status_T;
   use type ETCS_Message_Catalogue.Message_Kind_T;
   use type ETCS_Variables.NID_RADIO_T;
   use type ETCS_Variables.T_TRAIN_T;
   use type EVC_Modes.Mode_T;
   use type EVC_Radio.RBC_Id_T;
   use type EVC_Radio.Session_Info_T;

   --  The joint: the port and the stubs. A connection event and messages
   --  go in (untagged, tagged on each session), nothing comes out, the
   --  halves are given what the port carried; inputs of a wrong shape
   --  are refused. Then the outbox: a message and the requests of the
   --  test leave on the RTM port and decode. The RBC contact information
   --  is kept over No Power, to be revalidated (4.10, 4.11). The
   --  single-session configuration (EVC_Config.Radio_Config_T, decision 2
   --  of doc/EVC-PLAN.md §13) is accepted and refuses what is sent on
   --  session 2.
   procedure Scenario_Radio_Joint is
      --  message 24 (general): no effect in either half (message 16
      --  would trip the train, 3.10.2.3)
      M24 : constant Byte_Array := Message_Of (MCat.Track_M24);
      --  the same, one time stamp later (3.16.3.3.3, e5/session)
      M24_Later : constant Byte_Array :=
        Message_Of (MCat.Track_M24, (3 => 1, others => 0));
      V   : ETCS_Message.Value_Array := (others => 0);
      M   : ETCS_Message.Message_T;
      S   : ETCS_Message.Status_T;
      Bad : Natural;
   begin
      EVC_Core.Initialise;
      EVC_Core.Tick (100);
      Take;
      Check (EVC_Radio.Sessions = 2
             and then EVC_Radio.Info (1) = EVC_Radio.No_Info
             and then not EVC_Radio.In_Communication,
             "radio: two sessions by default, none established");

      Give_Radio_Event (1, Connection_Set_Up);
      Input (RTM, M24);                        -- untagged: session 1
      Give_Radio_Message (1, M24_Later);
      Give_Radio_Message (2, M24);
      Bad := EVC_Core.Rejected (RTM);
      Give_Radio_Event (3, Connection_Lost);   -- no session 3
      Input (RTM, (RTM_Tag_Event, 1, 7));      -- no event 7
      Give_Radio_Message (0, M24);             -- no session 0
      Input (RTM, (RTM_Tag_Request, 1, 2));    -- a request is an output
      Check (EVC_Core.Rejected (RTM) = Bad + 4
             and then EVC_Core.Accepted (RTM) = 4
             and then EVC_Core.Overflowed (RTM) = 0,
             "radio: the port takes the event and the three messages,"
             & " refuses four inputs of a wrong shape");
      EVC_Core.Tick (100);
      Take;
      Check (Parsed and then Radio_Outputs = 0,
             "radio: nothing leaves on the RTM port (the stubs)");
      Check (EVC_Sessions.Events_Taken = 1
             and then EVC_Sessions.Messages_Taken = 3
             and then EVC_Radio_Authority.Messages_Taken = 3
             and then EVC_Received.Message_Count (ETCS_Message.Accepted) = 3,
             "radio: the event and the messages reach the session half,"
             & " the messages it passes the authority half");
      Check (EVC_Sessions.Cycles_Produced = 2
             and then EVC_Radio_Authority.Cycles_Produced = 2
             and then EVC_Sessions.Mode_Changes_Taken = 1
             and then EVC_Radio_Authority.Mode_Changes_Taken = 1
             and then EVC_Core.Mode = EVC_Modes.M_SB,
             "radio: the halves run every cycle, hear NP -> SB");

      --  the outbox: 156 Termination of a communication session, T_TRAIN
      --  1234, and the requests, as the halves will queue them
      V (3) := 1234;
      EVC_Radio.Send (1, Message_Of (MCat.Train_M156, V));
      EVC_Radio.Request_Set_Up (2, (NID_C => 5, NID_RBC => 300),
                                16#1234_5678_9ABC_DEF0#, False);
      EVC_Radio.Request_Release (1);
      EVC_Radio.Request_Registration (2, 16#ABCDEF#);
      Check (EVC_Radio.Info (1).Sent
             and then EVC_Radio.Info (1).Last_Sent = 1234,
             "radio: Send keeps T_TRAIN of the message sent (3.16.3)");
      EVC_Core.Tick (100);
      Take;
      Decode_Radio_Message (1, M, S);
      Check (Parsed and then Radio_Outputs = 4
             and then not Radio_Output (1).Request
             and then Radio_Output (1).Session = 1
             and then Radio_Output (1).Kind = 156
             and then S = ETCS_Message.Accepted
             and then M.Kind = MCat.Train_M156
             and then ETCS_Message.Value (M, ETCS_Variables.T_TRAIN) = 1234,
             "radio: message 156 on session 1 leaves and decodes");
      Check (Radio_Output (2).Request and then Radio_Output (2).Session = 2
             and then Radio_Output (2).Kind = 1
             and then Rec_Length (Radio_Output (2).Rec) = 16
             and then Request_Byte (2, 1) = 5
             and then Request_Byte (2, 2) = 0
             and then Request_Byte (2, 3) = 300 mod 256
             and then Request_Byte (2, 4) = 1
             and then Request_Byte (2, 5) = 16#F0#
             and then Request_Byte (2, 12) = 16#12#
             and then Request_Byte (2, 13) = 0,
             "radio: the set-up request (RBC, number, GSM-R)");
      Check (Radio_Output (3).Request and then Radio_Output (3).Kind = 2
             and then Rec_Length (Radio_Output (3).Rec) = 3
             and then Radio_Output (4).Kind = 3
             and then Request_Byte (4, 1) = 16#EF#
             and then Request_Byte (4, 3) = 16#AB#
             and then EVC_Radio.Queued = 0 and then EVC_Radio.Refused = 0,
             "radio: the release and the registration requests");

      --  4.10, 4.11: the RBC contact kept over No Power, invalid
      EVC_Radio.Set_Contact ((Known => True, Valid => True,
                              RBC   => (NID_C => 7, NID_RBC => 42),
                              Radio => 99));
      EVC_Core.Tick (100);
      EVC_Core.Power_Up;
      Check (EVC_Radio.Contact.Known and then not EVC_Radio.Contact.Valid
             and then EVC_Radio.Contact.RBC = (NID_C => 7, NID_RBC => 42)
             and then EVC_Radio.Contact.Radio = 99,
             "radio: the RBC contact kept over No Power, to be revalidated");
      EVC_Core.Initialise;
      Check (not EVC_Radio.Contact.Known,
             "radio: a new on-board has no RBC contact");

      --  one session only, by configuration
      EVC_Config.Set_Radio_For_Test ((Sessions => 1, others => <>));
      EVC_Core.Initialise;
      Check (EVC_Radio.Sessions = 1
             and then EVC_Radio.Usable (1) and then not EVC_Radio.Usable (2)
             and then EVC_Core.Configuration.Radio.Sessions = 1,
             "radio: the single-session configuration is accepted");
      EVC_Core.Tick (100);
      Give_Radio_Message (2, M24);
      EVC_Radio.Send (2, Message_Of (MCat.Train_M156, V));
      EVC_Radio.Request_Set_Up (2, (NID_C => 5, NID_RBC => 300), 1, True);
      EVC_Radio.Send (1, Message_Of (MCat.Train_M156, V));
      EVC_Core.Tick (100);
      Take;
      Check (EVC_Radio.Refused = 2 and then Radio_Outputs = 1
             and then Radio_Output (1).Session = 1
             and then EVC_Sessions.Messages_Taken = 1,
             "radio: one session: session 2 refused when sending, its"
             & " messages handed to the session half to judge");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
      EVC_Core.Initialise;
      Check (EVC_Radio.Sessions = 2, "radio: back to two sessions");
   end Scenario_Radio_Joint;

end EVC_Test_Radio;
