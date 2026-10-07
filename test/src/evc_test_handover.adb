--  ETCS on-board (EVC)
--  Phase E5 (e5/handover): the RBC/RBC handover (see the specification).

with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P42;
with ETCS_Track_Packets.P131;
with ETCS_Track_Packets.P74;
with ETCS_Variables;
with EVC_Config;
with EVC_Core;
with EVC_Modes;
with EVC_Ports;           use EVC_Ports;
with EVC_Radio;
with EVC_Radio_Authority;
with EVC_Sessions;
with EVC_Text_Messages;
with EVC_Test_Support;    use EVC_Test_Support;
with Interfaces;          use Interfaces;

package body EVC_Test_Handover is

   package MCat renames ETCS_Message_Catalogue;
   package R renames EVC_Radio;
   use type R.Session_State_T;
   use type R.Session_Ref_T;
   use type ETCS_Variables.NID_RBC_T;

   function Now_T return Unsigned_64 is
     ((Unsigned_64 (EVC_Core.Time_Ms) / 10) mod 2**32);

   function P131 (D_M : Natural; NID_RBC : Natural)
     return ETCS_Track_Packets.P131.Packet_T
   is ((NID_PACKET     => 131,
        Q_DIR          => 2,
        L_PACKET       => 0,
        Q_SCALE        => 1,
        D_RBCTR        => ETCS_Variables.D_RBCTR_T (D_M),
        NID_C          => 5,
        NID_RBC        => ETCS_Variables.NID_RBC_T (NID_RBC),
        NID_RADIO      => 16#0077#,
        Q_SLEEPSESSION => 0));

   function P42 (Q_RBC, NID_RBC : Natural)
     return ETCS_Track_Packets.P42.Packet_T
   is ((NID_PACKET     => 42,
        Q_DIR          => 2,
        L_PACKET       => 0,
        Q_RBC          => ETCS_Variables.Q_RBC_T (Q_RBC),
        NID_C          => 5,
        NID_RBC        => ETCS_Variables.NID_RBC_T (NID_RBC),
        NID_RADIO      => 16#0077#,
        Q_SLEEPSESSION => 0));

   --  Message 24 referred to the group NID_BG (country 123) with packet
   --  131 (D_M metres, NID_RBC) or packet 42 (Q_RBC, NID_RBC)
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
         ETCS_Track_Packets.P131.Encode (P131 (N1, N2), W, OK);
      else
         ETCS_Track_Packets.P42.Encode (P42 (N1, N2), W, OK);
      end if;
      Check (OK, "handover: packet encoded");
      return Message_Bytes (W);
   end M24;

   --  The messages NID sent on session S
   function Sent (NID : Natural; S : Natural) return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. Radio_Outputs loop
         if not Radio_Output (I).Request
           and then Radio_Output (I).Session = S
           and then Radio_Output (I).Kind = NID
         then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Sent;

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

   --  A group NID at At_M metres with packet 42 Q_RBC 1 for RBC 300
   procedure Order_Group (NID : Natural; At_M : Integer_64) is
      W  : Writer_T;
      OK : Boolean;
   begin
      Add_Group (Group (NID, At_M));
      ETCS_Track_Packets.P42.Encode (P42 (1, 300), W, OK);
      Finish_Carry (Track_N, 0, W, OK);
   end Order_Group;

   procedure Scenario_Handover_Radio is
      R1, R2 : Natural;
   begin
      Start_X;
      Order_Group (10, 100);
      Add_Group (Group (20, 300));
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SR, EVC_Modes.L2);
      Stand;
      Run_X (15_000);
      Establish (1);
      Check (R.Supervising = 1 and then R.Info (1).State = R.Established,
             "handover: the session with the Handing Over RBC 300");

      --  3.15.1.3.1 a), 3.5.3.5.2.1: the order by radio (border 200 m
      --  after the group 10, at 300 m) opens the second session, the
      --  first one kept
      Give_Radio_Message (1, M24 (10, True, 200, 400));
      Stand;
      Check (R.Info (2).State = R.Connecting
             and then R.Info (2).RBC.NID_RBC = 400
             and then R.Info (1).State = R.Established,
             "handover: the order, the session with the Accepting RBC 400 "
             & "set up beside the other (3.15.1.3.1 a, 3.5.3.5.2.1)");
      R1 := EVC_Sessions.Train_Data_Sent;
      Establish (2);
      Check (R.Accepting = 2 and then R.Supervising = 1,
             "handover: the roles, 400 accepting (3.15.1.1.6)");
      Check (EVC_Sessions.Train_Data_Sent = R1 + 1,
             "handover: the Train Data to the Accepting RBC once its "
             & "session is established (3.15.1.3.3)");

      --  3.15.1.3.6, 4.8.2.1 c), 4.8.5.2: kept until the switch
      Give_Radio_Message (2, M24 (10, False, 1, 400));
      Stand;
      Check (EVC_Radio_Authority.Buffered = 1
             and then R.Info (1).State = R.Established,
             "handover: a message of the Accepting RBC stored, its "
             & "session management order kept no effect on the other "
             & "(4.8.5.2, 4.8.3 [14])");

      --  3.15.1.3.4: reports to both while both are connected
      R1 := EVC_Sessions.Position_Reports_Sent;
      Run_X (25_000);
      Stand;
      R2 := EVC_Sessions.Position_Reports_Sent;
      Check (R2 - R1 >= 2 and then (R2 - R1) mod 2 = 0,
             "handover: each report (standstill left and reached, the LRBG "
             & "passed) to both RBCs (3.15.1.3.4), got" & Img (R2 - R1));

      --  3.15.1.3.1 b), 3.15.1.3.5, 3.15.1.3.7, 5.15.1.4: the border
      R2 := EVC_Sessions.Position_Reports_Sent;
      Run_X (32_000);
      Stand;
      Check (EVC_Sessions.Position_Reports_Sent > R2,
             "handover: the border passed by the max safe front end "
             & "reported (3.15.1.3.1 b)");
      Check (R.Supervising = 2 and then R.Accepting = R.No_Session
             and then R.Contact.RBC.NID_RBC = 400
             and then R.Info (1).State = R.Established,
             "handover: 400 supervises, its contact substituted, the "
             & "session with 300 retained (3.15.1.3.5, .7, .8)");
      Check (EVC_Radio_Authority.Buffered = 0,
             "handover: the transition buffer released at the switch "
             & "(4.8.5.2)");

      --  3.15.1.3.5: from 300 only the order to terminate
      Give_Radio_Message (1, M24 (20, False, 0, 300));
      Stand;
      Check (Sent (156, 1) = 1 and then Sent (156, 2) = 0
             and then R.Info (2).State = R.Established,
             "handover: 300 terminates its session, the one with 400 "
             & "goes on (3.15.1.3.5, 3.5.5.1 a)");

      --  3.15.1.3.2.2, 3.15.1.3.2.3: a new order replaces the stored one
      Give_Radio_Message (2, M24 (20, True, 900, 500));
      Stand;
      Give_Radio_Message (2, M24 (20, True, 900, 600));
      Stand;
      Check (R.Info (1).RBC.NID_RBC /= 500
             or else R.Info (1).State /= R.Connecting,
             "handover: the order to 500 replaced by the one to 600 "
             & "(3.15.1.3.2.2)");
   end Scenario_Handover_Radio;

   procedure Scenario_Handover_Balise is
      W  : Writer_T;
      OK : Boolean;
   begin
      EVC_Config.Set_Radio_For_Test ((Sessions => 1, others => <>));
      Start_X;
      Order_Group (10, 100);
      --  Se3765f9b: packet 131 at once and packet 42 for the Accepting
      --  RBC in one group
      Add_Group (Group (20, 300));
      ETCS_Track_Packets.P131.Encode (P131 (0, 400), W, OK);
      ETCS_Track_Packets.P42.Encode (P42 (1, 400), W, OK);
      Finish_Carry (Track_N, 0, W, OK);
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SR, EVC_Modes.L2);
      Stand;
      Run_X (15_000);
      Establish (1);
      Run_X (32_000);
      Stand;
      Check (Sent (156, 1) = 0 and then R.Info (1).State = R.Established
             and then R.Info (1).RBC.NID_RBC = 300,
             "handover: 131 and 42 for the Accepting RBC in one group do "
             & "not terminate the session (4.8.3 [14], Se3765f9b)");
      Check (R.Contact.RBC.NID_RBC = 400,
             "handover: an order at once substitutes the contact "
             & "(3.15.1.3.7)");
      --  3.15.1.3.2: one session: the Accepting RBC's after the other
      Give_Radio_Message (1, M24 (20, False, 0, 300));
      Stand;
      Give_Radio_Message (1, Message_Of (MCat.Track_M39,
                                         (3 => Now_T, others => 0)));
      Stand;
      Stand;
      Check (R.Info (1).RBC.NID_RBC = 400
             and then R.Info (1).State /= R.Idle,
             "handover: one session, the one with 400 once the one with "
             & "300 is over (3.15.1.3.2)");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
      EVC_Core.Initialise;
   end Scenario_Handover_Balise;

   --  Message 24 referred to the group NID_BG with packet 74: a fixed
   --  text from the group on 1000 m, no other condition
   function M24_Text (NID_BG : Natural) return Byte_Array is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
   begin
      V (3) := Now_T;
      V (5) := 123;
      V (6) := Unsigned_64 (NID_BG);
      Start_Message (W, MCat.Track_M24, V);
      ETCS_Track_Packets.P74.Encode
        ((Q_DIR => 2, Q_SCALE => 1, L_TEXTDISPLAY => 1000,
          T_TEXTDISPLAY => 1023,
          M_MODETEXTDISPLAY => 15, M_LEVELTEXTDISPLAY => 4,
          M_MODETEXTDISPLAY_2 => 15, M_LEVELTEXTDISPLAY_2 => 4,
          others => <>), W, OK);
      Check (OK, "handover: packet 74 encoded");
      return Message_Bytes (W);
   end M24_Text;

   --  S776cef6c: a text message of the Accepting RBC before the switch
   procedure Scenario_Handover_Text is
   begin
      Start_X;
      Order_Group (10, 100);
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SR, EVC_Modes.L2);
      Stand;
      Run_X (15_000);
      Establish (1);
      Give_Radio_Message (1, M24 (10, True, 200, 400));
      Stand;
      Establish (2);
      Check (R.Accepting = 2, "handover text: 400 accepting");

      --  4.8.2.1 c), 3.15.1.3.6: stored until the switch, not shown
      Give_Radio_Message (2, M24_Text (10));
      Stand;
      Check (EVC_Radio_Authority.Buffered = 1
             and then EVC_Text_Messages.Displayed = 0,
             "handover text: the fixed text of the Accepting RBC stored, "
             & "not shown before the switch (4.8.2.1 c, 3.15.1.3.6)");

      --  3.15.1.3.5, 4.8.5.2, 3.12.3: released at the switch and shown
      Run_X (32_000);
      Stand;
      Check (R.Supervising = 2 and then EVC_Radio_Authority.Buffered = 0
             and then EVC_Text_Messages.Displayed = 1,
             "handover text: released at the switch, the text of 400 "
             & "shown (4.8.5.2, 3.12.3)");
   end Scenario_Handover_Text;

   procedure Scenario_Handover_Deletion is
   begin
      Start_X;
      Order_Group (10, 100);
      Add_Group (Group (20, 300));
      EVC_Core.Set_Mode_For_Test (EVC_Modes.M_SR, EVC_Modes.L2);
      Stand;
      Run_X (15_000);
      Establish (1);
      Give_Radio_Message (1, M24 (10, True, 200, 400));
      Stand;
      Establish (2);
      Run_X (32_000);
      Stand;
      Check (R.Supervising = 2 and then R.Info (1).State = R.Established
             and then EVC_Sessions.Handing_Over_Retained,
             "handover deletion: switched, the contact of 300 retained "
             & "(3.15.1.3.8)");

      --  3.5.3.4 f), 3.15.1.3.8.1: the session with 300 lost and not set
      --  up again in time: a new one with the retained contact, beside
      --  the one with the supervising 400
      Give_Radio_Event (1, Connection_Lost);
      Stand_X (301_000);
      Check (R.Info (1).RBC.NID_RBC = 300
             and then R.Info (1).State /= R.Idle
             and then R.Supervising = 2
             and then R.Info (2).State = R.Established,
             "handover deletion: the Handing Over session set up again with "
             & "the retained contact, the supervising one kept (3.5.3.4 f)");

      --  4.10: entering OS keeps the order (U), entering SR deletes it,
      --  with it the retained contact (3.15.1.3.8 b)
      EVC_Sessions.Mode_Changed (EVC_Modes.M_SR, EVC_Modes.M_OS);
      Check (EVC_Sessions.Handing_Over_Retained,
             "handover deletion: kept when entering OS (4.10)");
      EVC_Sessions.Mode_Changed (EVC_Modes.M_OS, EVC_Modes.M_SR);
      Check (not EVC_Sessions.Handing_Over_Retained
             and then R.Supervising = 2,
             "handover deletion: the retained contact deleted with the "
             & "order when entering SR (4.10, 3.15.1.3.8 b)");
   end Scenario_Handover_Deletion;

end EVC_Test_Handover;
