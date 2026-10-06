--  ETCS on-board (EVC)
--  Phase E5, the bench: Sim_RBC (see the specification).

with ETCS_Catalogue;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P2;
with ETCS_Variables;
with EVC_Bytes;
with EVC_Core;
with EVC_Ports;           use EVC_Ports;
with EVC_Received;
with EVC_Sessions;
with EVC_Test_Support;    use EVC_Test_Support;
with Interfaces;          use Interfaces;
with Sim_Onboard_Env;
with Sim_RBC;

package body EVC_Test_RBC is

   package MCat renames ETCS_Message_Catalogue;
   use type ETCS_Message.Status_T;
   use type Sim_RBC.State_T;
   use type MCat.Message_Kind_T;
   use type EVC_Bytes.Byte_Array;
   use type ETCS_Variables.NID_PACKET_T;

   --  A train to track message of Kind on session 1, T_TRAIN Stamp,
   --  with a position report (packet 0, LRBG NID_BG 3 of the bench
   --  line's country) when Report; message 159 with its packet 2 (the
   --  system version 4.0)
   function From_Train (Kind   : MCat.Known_Message_T;
                        Stamp  : Unsigned_64;
                        Report : Boolean := False) return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      P  : ETCS_Train_Packets.P0.Packet_T;
      OK : Boolean;
   begin
      V (3) := Stamp;               -- T_TRAIN (8.4.4.7.1)
      V (4) := 76_000;              -- NID_ENGINE
      Start_Message (W, Kind, V);
      if Kind = MCat.Train_M159 then
         declare
            P2 : ETCS_Train_Packets.P2.Packet_T;
         begin
            P2.M_VERSION := 64;
            ETCS_Train_Packets.P2.Encode (P2, W, OK);
            Check (OK, "rbc: packet 2 written");
         end;
      end if;
      if Report then
         P.NID_C := 123;
         P.NID_BG := 3;
         P.Q_SCALE := 1;
         ETCS_Train_Packets.P0.Encode (P, W, OK);
         Check (OK, "rbc: the position report written");
      end if;
      return Byte_Array'(RTM_Tag_Message, 1) & Message_Bytes (W);
   end From_Train;

   procedure Scenario_RBC is
      --  the on-board's request to set up a connection with RBC 1 of
      --  the line (EVC_Ports: NID_C, NID_RBC, NID_RADIO, the system)
      Set_Up  : constant Byte_Array :=
        (RTM_Tag_Request, 1, 1, 0, 123, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0);
      Release : constant Byte_Array := (RTM_Tag_Request, 1, 2);
      Inputs  : array (1 .. 8) of Byte_Array (1 .. 1100);
      Lengths : array (1 .. 8) of Natural := (others => 0);
      N       : Natural := 0;
      Last    : Natural;
      NIDs    : array (1 .. 8) of Natural := (others => 0);
      Stamps  : array (1 .. 8) of Unsigned_64 := (others => 0);
      Messages, Events : Natural := 0;
      Rising  : Boolean := True;
      M       : ETCS_Message.Message_T;
      St      : ETCS_Message.Status_T;
      Has_15  : Boolean := False;

      procedure Drain is
      begin
         loop
            exit when N = Inputs'Last;
            Sim_RBC.Next_Input (Inputs (N + 1), Last);
            exit when Last < 1;
            N := N + 1;
            Lengths (N) := Last;
         end loop;
      end Drain;
   begin
      Sim_RBC.Reset;
      --  3.5.3.4: the connection
      Sim_RBC.Take (Set_Up);
      Drain;
      Check (N = 1 and then Lengths (1) = 3
             and then Inputs (1) (1 .. 3) = Byte_Array'(RTM_Tag_Event, 1, 1)
             and then Sim_RBC.State (1) = Sim_RBC.Connected
             and then Sim_RBC.Session_Of (1) = 1,
             "rbc: a set-up request answered with the event set up in its"
             & " session (3.5.3.4)");
      --  3.5.3.7: the session; 3.8.2: an MA on request; 3.5.5: the end
      Sim_RBC.Take (From_Train (MCat.Train_M155, 1_000));
      Sim_RBC.Step (500);
      Sim_RBC.Take (From_Train (MCat.Train_M159, 1_050));
      Sim_RBC.Take (From_Train (MCat.Train_M132, 1_100, Report => True));
      Sim_RBC.Take (From_Train (MCat.Train_M156, 1_200));
      Sim_RBC.Take (Release);
      Drain;
      Check (Sim_RBC.Errors = 0 and then Sim_RBC.Taken = 6
             and then Sim_RBC.Dropped = 0
             and then Sim_RBC.State (1) = Sim_RBC.Idle
             and then Sim_RBC.Session_Of (1) = 0,
             "rbc: the on-board's outputs read without error, the session"
             & " ended by the release");

      --  the answers decode as an RBC's messages (8.4.4)
      for I in 2 .. N loop
         if Inputs (I) (1) = RTM_Tag_Message then
            ETCS_Message.Parse (Inputs (I) (3 .. Lengths (I)),
                                ETCS_Catalogue.Track_To_Train,
                                ETCS_Catalogue.RBC, M, St);
            if St = ETCS_Message.Accepted then
               Messages := Messages + 1;
               NIDs (Messages) := Natural (Inputs (I) (3));
               Stamps (Messages) :=
                 ETCS_Message.Value (M, ETCS_Variables.T_TRAIN);
               if Messages > 1
                 and then Stamps (Messages) <= Stamps (Messages - 1)
               then
                  Rising := False;
               end if;
               for P in 1 .. M.Count loop
                  if M.Index (P).NID = 15 then
                     Has_15 := True;
                  end if;
               end loop;
            end if;
         else
            Events := Events + 1;
         end if;
      end loop;
      Check (Messages = 4 and then NIDs (1 .. 4) = (32, 38, 3, 39)
             and then Events = 1 and then Has_15,
             "rbc: answered with 32 (155), 38 (159), the MA 3 with packet"
             & " 15 (132), 39 (156), the event released");
      Check (Rising and then Stamps (1) = 1_000 and then Stamps (4) = 1_200,
             "rbc: the time stamps from the train's, rising (3.16.3.2.2,"
             & " 3.16.3.3.2)");

      --  the round trip: the answers through the on-board's RTM port
      EVC_Core.Initialise;
      EVC_Core.Tick (100);
      Take;
      declare
         Taken_Before : constant Natural := EVC_Sessions.Messages_Taken;
         Events_Before : constant Natural := EVC_Sessions.Events_Taken;
      begin
         for I in 1 .. N loop
            Input (RTM, Inputs (I) (1 .. Lengths (I)));
         end loop;
         EVC_Core.Tick (100);
         Take;
         Check (EVC_Core.Accepted (RTM) = N
                and then EVC_Core.Rejected (RTM) = 0
                and then EVC_Received.Message_Count (ETCS_Message.Accepted)
                         = 4
                and then EVC_Sessions.Messages_Taken = Taken_Before + 4
                and then EVC_Sessions.Events_Taken = Events_Before + 2,
                "rbc: its inputs taken by the RTM port, its messages"
                & " accepted by the codec and given to the session half");
      end;

      --  what it cannot read is counted, never raises
      Sim_RBC.Take ((1 => 7));
      Sim_RBC.Take ((RTM_Tag_Message, 5, 155, 0, 0));
      Sim_RBC.Take ((RTM_Tag_Message, 1, 155, 0, 0));   -- truncated
      Sim_RBC.Take ((RTM_Tag_Request, 1, 9));
      Sim_RBC.Emergency_Stop;                          -- no session
      Check (Sim_RBC.Errors = 4 and then Sim_RBC.Pending = 0,
             "rbc: four outputs it cannot read counted, nothing sent");

      --  the bench: off by default; on, the scripted start of mission in
      --  level 2 (Sim_Onboard_Env) sets up the session with RBC 1
      Check (not Sim_Onboard_Env.Radio, "rbc: off on the bench by default");
      Sim_Onboard_Env.Set_Radio (True);
      Sim_Onboard_Env.Reset;
      for K in 1 .. 50 loop
         Sim_Onboard_Env.Step (100);
      end loop;
      Check (Sim_RBC.Errors = 0
             and then Sim_RBC.State (1) = Sim_RBC.Established,
             "rbc: on the bench, the on-board's RTM outputs read without"
             & " error, the session of the start of mission established");
      Sim_Onboard_Env.RBC_Emergency_Stop;
      Check (Sim_RBC.Pending >= 1,
             "rbc: on the bench, the emergency stop queued (message 16)");
      Sim_Onboard_Env.Set_Radio (False);
      Sim_RBC.Reset;
   end Scenario_RBC;

end EVC_Test_RBC;
