with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Track_Packets.P45;
with EVC_Acceptance;
with EVC_Radio_Acceptance;
with EVC_Test_Authority;
with Interfaces;          use Interfaces;
with EVC_Config;
with EVC_Modes;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Radio;
with EVC_Sessions;
with EVC_Test_Modes;
with EVC_Train_Data;
with EVC_Bytes;
with EVC_Test_Support;    use EVC_Test_Support;
with ETCS_Variables;
with EVC_Ports;           use EVC_Ports;

package body EVC_Test_Network is

   package R renames EVC_Radio;
   use type ETCS_Variables.NID_MN_T;

   --  The DMI's frames (dmi_protocol.ads): a driver action, a text entry
   --  (kind 0 driver ID, 4 GSM-R network), the RBC data (kind 5)
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

   function RBC_Entry return Byte_Array is
      Res : Byte_Array (1 .. 23) := (others => 0);
      Id  : constant := 5 * 16_384 + 300;
   begin
      Res (1 .. 6) := (5, 0, Byte (Id mod 256), Byte (Id / 256 mod 256),
                       Byte (Id / 65_536), 0);
      Res (7 .. 11) := (4, Character'Pos ('0'), Character'Pos ('0'),
                        Character'Pos ('7'), Character'Pos ('7'));
      return Frame (EVC_DMI_Port.MSG_DRIVER_DATA, Res);
   end RBC_Entry;

   procedure Send (Bytes : Byte_Array) is
   begin
      Input (DMI, Bytes);
      Stand;
   end Send;

   --  The byte K (frame order from 1, the type first) of the last
   --  cycle's frame of type T, 16#FF# when none
   function DMI_Byte (T : Byte; K : Positive) return Natural is
     (if Find_DMI (T) = 0 then 16#FF# else Byte_At (Find_DMI (T), K));

   --  The MSG_RADIO_NETWORKS of the last cycle names A, then B if given
   function Networks_Are (A : String; B : String := "") return Boolean is
      I     : constant Natural :=
        Find_DMI (EVC_DMI_Port.MSG_RADIO_NETWORKS);
      Count : constant Natural := (if B = "" then 1 else 2);
      function Name_At (K : Positive; S : String) return Boolean is
        (Byte_At (I, K) = S'Length
         and then (for all J in S'Range =>
                     Byte_At (I, K + 1 + J - S'First)
                       = Character'Pos (S (J))));
   begin
      return I /= 0 and then Byte_At (I, 6) = Count
        and then Name_At (7, A)
        and then (B = "" or else Name_At (8 + A'Length, B));
   end Networks_Are;

   --  A MSG_SYSTEM_STATUS of catalogue entry E, event Ev (0 start, 1
   --  end) in the last cycle
   function Status_Shown (E, Ev : Natural) return Boolean is
     (for some I in 1 .. Rec_Count =>
        Recs (I).Port = DMI and then Rec_Length (I) = 7
        and then Byte_At (I, 1) = 16#0C#
        and then Byte_At (I, 6) = E and then Byte_At (I, 7) = Ev);

   --  MSG_ONBOARD waiting (byte 12): 1 registration, 2 the RBC
   function Waiting return Natural is
     (DMI_Byte (EVC_DMI_Port.MSG_ONBOARD, 12));

   --  A level 2 start of mission up to the driver's RBC contact (S1, S2,
   --  S3), one session, default network 262
   procedure SoM_To_S3 is
   begin
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 76_000, Default_MN => 16#262FFF#,
          others => <>));
      EVC_Test_Modes.Start_E4;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 5));
      Send (RBC_Entry);
   end SoM_To_S3;

   --  B007, DMI 11.7.1.4: the RBC contact stored on-board goes to the
   --  DMI (MSG_RBC_CONTACT) when it changes, so that the RBC data window
   --  proposes it: RBC ID 5 * 16384 + 300 (NID_C above the 14 bits of
   --  NID_RBC, DMI 11.3.5.3.1), phone 0077 (NID_RADIO, 7.5.1.95)
   procedure Scenario_RBC_Contact_To_DMI is
      Id : constant := 5 * 16_384 + 300;
   begin
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 76_000, Default_MN => 16#262FFF#,
          others => <>));
      EVC_Test_Modes.Start_E4;
      Send (Text_Entry (0, "1234"));
      Check (Find_DMI (EVC_DMI_Port.MSG_RBC_CONTACT) = 0,
             "RBC contact to the DMI: nothing sent while none is stored "
             & "(B007)");
      Send (Action (11, 5));
      Send (RBC_Entry);
      Check (DMI_Byte (EVC_DMI_Port.MSG_RBC_CONTACT, 6) = 1
             and then DMI_Byte (EVC_DMI_Port.MSG_RBC_CONTACT, 7) = Id mod 256
             and then DMI_Byte (EVC_DMI_Port.MSG_RBC_CONTACT, 8)
                        = Id / 256 mod 256
             and then DMI_Byte (EVC_DMI_Port.MSG_RBC_CONTACT, 9) = Id / 65_536
             and then DMI_Byte (EVC_DMI_Port.MSG_RBC_CONTACT, 11) = 4
             and then DMI_Byte (EVC_DMI_Port.MSG_RBC_CONTACT, 12)
                        = Character'Pos ('0')
             and then DMI_Byte (EVC_DMI_Port.MSG_RBC_CONTACT, 15)
                        = Character'Pos ('7')
             and then DMI_Byte (EVC_DMI_Port.MSG_RBC_CONTACT, 16) = 0,
             "RBC contact to the DMI: the contact the driver entered is "
             & "sent as stored, RBC ID and the phone digits (DMI 11.7.1.4, "
             & "B007)");
      Stand;
      Check (Find_DMI (EVC_DMI_Port.MSG_RBC_CONTACT) = 0,
             "RBC contact to the DMI: sent once, not again while it does "
             & "not change (B007)");
   end Scenario_RBC_Contact_To_DMI;

   procedure Scenario_Network_List is
   begin
      SoM_To_S3;
      Send (Text_Entry (4, ""));
      Check (Networks_Are ("262")
             and then DMI_Byte (EVC_DMI_Port.MSG_ONBOARD, 15) = 0,
             "network list: the driver elects to modify the GSM-R network: "
             & "the list offers the default network (3.18.4.3.6.2)");
      Stand;
      Check (Find_DMI (EVC_DMI_Port.MSG_RADIO_NETWORKS) = 0,
             "network list: sent once (3.18.4.3.6.2)");
      Send (Text_Entry (4, "123"));
      Check (R.Network.NID_MN = 16#123FFF#,
             "network list: the driver selects 123 (3.18.4.3.6.2)");
      Stand;
      Send (Text_Entry (4, ""));
      Check (Networks_Are ("262", "123"),
             "network list: the default and the stored network "
             & "(3.18.4.3.6.2, e5/registration-2)");
      --  4.8.3 / 4.8.4: the Radio Network transition order (packet 45)
      Check (EVC_Acceptance.Accepted
               (EVC_Acceptance.Network_Order,
                (Mode => EVC_Modes.M_SH, Level_Valid => True,
                 Level => EVC_Modes.L0, others => <>))
             and then EVC_Acceptance.Accepted
               (EVC_Acceptance.Network_Order,
                (Mode => EVC_Modes.M_SB, Cab_Active => True, others => <>))
             and then not EVC_Acceptance.Accepted
               (EVC_Acceptance.Network_Order,
                (Mode => EVC_Modes.M_SB, others => <>)),
             "packet 45: accepted in every level (4.8.3) and in SH (4.8.4), "
             & "in SB only with a cab active (4.8.4 [2])");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Network_List;

   procedure Scenario_Network_S4_Timeout is
      use type EVC_Core.Time_Ms_T;
      Start : EVC_Core.Time_Ms_T;
      Shown : Boolean := False;
   begin
      Auto_Register := False;
      SoM_To_S3;
      Start := EVC_Core.Time_Ms;
      Check (Waiting = 1,
             "S4: no mobile registered, the start of mission waits for the "
             & "registration (5.4.3.2 S4)");
      while EVC_Core.Time_Ms - Start < 39_000 loop
         Stand;
      end loop;
      Check (Waiting = 1
             and then not Status_Shown
                            (EVC_DMI_Port.SS_GSMR_Registration_Failed, 0),
             "S4: still waiting before the time of A.3.1 (5.4.3.2 S4)");
      for I in 1 .. 100 loop
         Stand;
         Shown := Status_Shown (EVC_DMI_Port.SS_GSMR_Registration_Failed, 0);
         exit when Shown;
      end loop;
      Check (Shown and then Waiting = 0
             and then EVC_Core.Time_Ms - Start in 39_000 .. 40_000,
             "S4 E7 -> A42: 40 s after the order of the power-up (A.3.1) "
             & "the registration failed, entry 34, the wait ended "
             & "(D9 -> S10)");
      --  3.18.4.3.6.1 b): the attempt aborted; the driver's network
      --  ordered and awaited (radio_wait 2)
      Send (Text_Entry (4, "262"));
      Stand;
      Check (DMI_Byte (EVC_DMI_Port.MSG_ONBOARD, 15) = 2
             and then not EVC_Sessions.Registration_Timed_Out,
             "A43: the driver's network orders the registration again "
             & "(5.4.3.2 S3 / S4, 3.18.4.3.6.2)");
      Give_Radio_Event (1, Registered);
      Stand;
      Send (RBC_Entry);
      Check (Waiting = 2,
             "S4 E6 -> A31: registered, the RBC data validated (S3 E5): "
             & "the session is opened at once");
      Auto_Register := True;
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Network_S4_Timeout;

   procedure Scenario_Network_FRMCS is
      use type EVC_Core.Time_Ms_T;
      Start : EVC_Core.Time_Ms_T;
      Shown, GSMR_Shown : Boolean := False;

      --  stand until entry 33 is shown or 3 s have passed
      procedure Await_FRMCS_Failure is
      begin
         Shown := False;
         GSMR_Shown := False;
         for I in 1 .. 30 loop
            Stand;
            Shown := Status_Shown (EVC_DMI_Port.SS_FRMCS_Registration_Failed,
                                   0);
            GSMR_Shown := GSMR_Shown
              or else Status_Shown
                        (EVC_DMI_Port.SS_GSMR_Registration_Failed, 0);
            exit when Shown;
         end loop;
      end Await_FRMCS_Failure;
   begin
      --  FRMCS the only radio system, the type FRMCS (5.4.3.2 S4 1st)
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 76_000, Systems => EVC_Config.FRMCS_Only,
          Default_Type => EVC_Config.FRMCS, others => <>));
      EVC_Test_Modes.Start_E4;
      Give_Radio_Event (1, FRMCS_Not_Registered);
      Start := EVC_Core.Time_Ms;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 5));
      Send (RBC_Entry);
      Check (Waiting = 1 and then not EVC_Sessions.Network_Ready,
             "FRMCS alone: reported connected, not registered: the start "
             & "of mission waits at S4 (5.4.3.2 S4, 3.5.6.7 a))");
      while EVC_Core.Time_Ms - Start < 38_000 loop
         Stand;
      end loop;
      Check (Waiting = 1
             and then not Status_Shown
                            (EVC_DMI_Port.SS_FRMCS_Registration_Failed, 0),
             "FRMCS alone: still waiting before the time of A.3.1");
      Await_FRMCS_Failure;
      Check (Shown and then not GSMR_Shown and then Waiting = 0
             and then EVC_Core.Time_Ms - Start in 39_000 .. 41_000,
             "S4 E71 -> A42: 40 s after the FRMCS on-board was detected "
             & "connected (A.3.1), FRMCS network registration failed, "
             & "entry 33, not the GSM-R one; the wait ended");
      Give_Radio_Event (2, FRMCS_Registered);
      Stand;
      Check (EVC_Sessions.Network_Ready
             and then not EVC_Sessions.Registration_Timed_Out
             and then EVC_Sessions.Radio_Bits / 16 mod 2 = 1,
             "FRMCS alone: event 7 on any session byte, registered: the "
             & "set-up allowed (3.5.6.7 a)), MSG_ONBOARD radio bit 4");
      --  both systems, the type FRMCS+GSM-R (5.4.3.2 S4 2nd): the GSM-R
      --  mobile registered (Auto_Register), FRMCS not
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 76_000,
          Systems => EVC_Config.Both_Systems,
          Default_Type => EVC_Config.FRMCS_GSMR,
          Default_MN => 16#262FFF#));
      EVC_Test_Modes.Start_E4;
      Give_Radio_Event (1, FRMCS_Not_Registered);
      Start := EVC_Core.Time_Ms;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 5));
      Send (RBC_Entry);
      while EVC_Core.Time_Ms - Start < 38_000 loop
         Stand;
      end loop;
      Check (Waiting = 1 and then not EVC_Sessions.Network_Ready
             and then EVC_Sessions.Radio_Bits / 32 mod 2 = 1,
             "both systems: the GSM-R mobile registered, FRMCS not: S4 "
             & "still waits for both (E62), 3.5.6.7 b) holds the set-up");
      Await_FRMCS_Failure;
      Check (Shown and then not GSMR_Shown and then Waiting = 0,
             "S4 E72 -> A42: 40 s after the GSM-R order, the failed "
             & "registration is FRMCS's alone, entry 33");
      Give_Radio_Event (1, FRMCS_Registered);
      Stand;
      Check (EVC_Sessions.Network_Ready,
             "both systems: both registered, the set-up allowed "
             & "(3.5.6.7 b))");
      --  GSM-R alone: the FRMCS reports are not judged
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 76_000,
          Systems => EVC_Config.GSMR_Only,
          Default_Type => EVC_Config.FRMCS_GSMR,
          Default_MN => 16#262FFF#));
      EVC_Test_Modes.Start_E4;
      Give_Radio_Event (1, FRMCS_Registered);
      Stand;
      Check (EVC_Sessions.Radio_Bits / 16 mod 2 = 0,
             "GSM-R alone: an FRMCS report does not count (3.5.6.7 d))");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Network_FRMCS;

   procedure Scenario_Network_S4_Without_Contact is
      use type EVC_Core.Time_Ms_T;
      Start : EVC_Core.Time_Ms_T;
      Waited : EVC_Core.Time_Ms_T;
      FRMCS_Shown, GSMR_Shown : Boolean;

      --  the start of mission to S4 by D7 as 3050600_06 reaches it: a
      --  level transition to level 2 by balise in SB, the RBC contact
      --  unknown, the Driver ID entered; Start is the power-up (the
      --  GSM-R order and the FRMCS detection)
      procedure To_S4 (Systems : EVC_Config.Radio_Systems_T;
                       T       : EVC_Config.Network_Type_T) is
      begin
         EVC_Config.Set_Radio_For_Test
           ((Sessions => 1, Engine_Id => 76_000, Systems => Systems,
             Default_Type => T, Default_MN => 16#262FFF#));
         EVC_Test_Modes.Start_E4;
         if EVC_Config."/=" (Systems, EVC_Config.GSMR_Only) then
            Give_Radio_Event (1, FRMCS_Not_Registered);
         end if;
         Start := EVC_Core.Time_Ms;
         Add_Group (Group (10, 20));
         Run_X (5_000, 100);
         Stand;
         Send (Action (11, 5));
         Send (Text_Entry (0, "1234"));
      end To_S4;

      --  stand until a registration failure is shown or 45 s from Start
      procedure Await_Failure is
      begin
         FRMCS_Shown := False;
         GSMR_Shown := False;
         while EVC_Core.Time_Ms - Start < 45_000 loop
            Stand;
            FRMCS_Shown := FRMCS_Shown
              or else Status_Shown
                        (EVC_DMI_Port.SS_FRMCS_Registration_Failed, 0);
            GSMR_Shown := GSMR_Shown
              or else Status_Shown
                        (EVC_DMI_Port.SS_GSMR_Registration_Failed, 0);
            exit when FRMCS_Shown or else GSMR_Shown;
         end loop;
         Waited := EVC_Core.Time_Ms - Start;
      end Await_Failure;
   begin
      --  both systems, FRMCS+GSM-R: the GSM-R mobile registered
      --  (Auto_Register), FRMCS reported not registered
      To_S4 (EVC_Config.Both_Systems, EVC_Config.FRMCS_GSMR);
      Check (not R.Contact.Known and then EVC_Sessions.SoM_Awaiting_Registration
             and then Waiting = 1,
             "S4 by D7 without a contact, both systems: the registration "
             & "awaited (5.4.3.2 D7 -> S4), got waiting" & Waiting'Image);
      Await_Failure;
      Check (FRMCS_Shown and then not GSMR_Shown and then Waiting = 0
             and then EVC_Sessions.Registration_Timed_Out
             and then Waited in 39_000 .. 41_000,
             "S4 by D7 without a contact, both systems: E72 -> A42 40 s "
             & "after the GSM-R order of the power-up (A.3.1), FRMCS "
             & "network registration failed, entry 33, the wait ended; at"
             & Waited'Image & " ms " & FRMCS_Shown'Image
             & GSMR_Shown'Image);
      --  FRMCS the only system, the type FRMCS
      To_S4 (EVC_Config.FRMCS_Only, EVC_Config.FRMCS);
      Check (EVC_Sessions.SoM_Awaiting_Registration and then Waiting = 1,
             "S4 by D7 without a contact, FRMCS alone: the registration "
             & "awaited (5.4.3.2 D7 -> S4)");
      Await_Failure;
      Check (FRMCS_Shown and then not GSMR_Shown and then Waiting = 0
             and then Waited in 39_000 .. 41_000,
             "S4 by D7 without a contact, FRMCS alone: E71 -> A42 40 s "
             & "after the FRMCS on-board was detected connected (A.3.1), "
             & "entry 33; at" & Waited'Image & " ms");
      --  GSM-R the only system, no mobile registered
      Auto_Register := False;
      To_S4 (EVC_Config.GSMR_Only, EVC_Config.GSMR);
      Check (EVC_Sessions.SoM_Awaiting_Registration and then Waiting = 1,
             "S4 by D7 without a contact, GSM-R alone: the registration "
             & "awaited (5.4.3.2 D7 -> S4)");
      Await_Failure;
      Check (GSMR_Shown and then not FRMCS_Shown and then Waiting = 0
             and then Waited in 39_000 .. 41_000,
             "S4 by D7 without a contact, GSM-R alone: E7 -> A42 40 s "
             & "after the order of the power-up (A.3.1), GSM-R network "
             & "registration failed, entry 34; at" & Waited'Image & " ms");
      Auto_Register := True;
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Network_S4_Without_Contact;

   procedure Scenario_Network_Type_At_S3 is
      use type EVC_Core.Time_Ms_T;
      Start  : EVC_Core.Time_Ms_T;
      Shown  : Boolean := False;
      Early  : Boolean := False;
      Waited : EVC_Core.Time_Ms_T;

      --  the driver's Radio Network type (DMI Table 43b: 1 FRMCS,
      --  2 FRMCS+GSM-R, 3 GSM-R), kind 6 of MSG_DRIVER_DATA
      function Type_Entry (T : Natural) return Byte_Array is
        (Frame (EVC_DMI_Port.MSG_DRIVER_DATA, (6, Byte (T))));

      --  both systems, the stored type FRMCS+GSM-R, the GSM-R mobile
      --  registered (Auto_Register), FRMCS reported not registered at
      --  Start; the Driver ID, then level 2: S3 (the contact unknown)
      procedure To_S3 is
      begin
         EVC_Config.Set_Radio_For_Test
           ((Sessions => 1, Engine_Id => 76_000,
             Systems => EVC_Config.Both_Systems,
             Default_Type => EVC_Config.FRMCS_GSMR,
             Default_MN => 16#262FFF#));
         EVC_Test_Modes.Start_E4;
         Give_Radio_Event (1, FRMCS_Not_Registered);
         Start := EVC_Core.Time_Ms;
         Send (Text_Entry (0, "1234"));
         Send (Action (11, 5));
      end To_S3;
   begin
      To_S3;
      Check (Waiting = 0 and then not EVC_Sessions.SoM_Awaiting_Registration,
             "S3 reached, the contact unknown: no wait yet");
      Send (Type_Entry (2));
      Check (Waiting = 1 and then EVC_Sessions.SoM_Awaiting_Registration
             and then not Status_Shown
                            (EVC_DMI_Port.SS_FRMCS_Registration_Failed, 0),
             "S3 E4: FRMCS+GSM-R entered, FRMCS installed and not "
             & "registered: the registration awaited (hour glass), not yet "
             & "considered failed (5.4.3.2 S3, A.3.1), got waiting"
             & Waiting'Image);
      while EVC_Core.Time_Ms - Start < 45_000 loop
         Stand;
         Shown := Status_Shown
                    (EVC_DMI_Port.SS_FRMCS_Registration_Failed, 0);
         Early := Early or else (Shown and then Waiting = 1);
         exit when Shown;
      end loop;
      Waited := EVC_Core.Time_Ms - Start;
      Check (Shown and then not Early and then Waiting = 0
             and then not EVC_Sessions.SoM_Awaiting_Registration
             and then Waited in 39_000 .. 41_000,
             "S3 E4 -> A41: 40 s after the FRMCS detection (A.3.1), FRMCS "
             & "network registration failed, entry 33; D8 -> S3, the wait "
             & "ended; at" & Waited'Image & " ms");
      Send (Type_Entry (2));
      Check (Status_Shown (EVC_DMI_Port.SS_FRMCS_Registration_Failed, 0)
             and then Waiting = 0,
             "S3 E4 again after the time of A.3.1: A41 at once, no wait");
      Send (Type_Entry (3));
      Check (Waiting = 0 and then not EVC_Sessions.SoM_Awaiting_Registration
             and then not Status_Shown
                            (EVC_DMI_Port.SS_FRMCS_Registration_Failed, 0),
             "S3: GSM-R entered, no E4");
      --  the registration achieved during the wait: back to S3, silent
      To_S3;
      Send (Type_Entry (1));
      Check (Waiting = 1, "S3 E4: FRMCS entered, the wait");
      Give_Radio_Event (1, FRMCS_Registered);
      Stand;
      Check (Waiting = 0 and then not EVC_Sessions.SoM_Awaiting_Registration
             and then not Status_Shown
                            (EVC_DMI_Port.SS_FRMCS_Registration_Failed, 0),
             "S3 E4: the FRMCS registration achieved within the time: the "
             & "wait ends, no A41");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Network_Type_At_S3;

   --  Message 24, or K, (T_TRAIN now) with packet 45: GSM-R, network MN
   function M24_With_45
     (MN : ETCS_Variables.NID_MN_T;
      K  : ETCS_Message_Catalogue.Known_Message_T :=
        ETCS_Message_Catalogue.Track_M24) return Byte_Array
   is
      W  : Writer_T;
      V  : ETCS_Message.Value_Array := (others => 0);
      P  : ETCS_Track_Packets.P45.Packet_T;
      OK : Boolean;
   begin
      V (3) := Unsigned_64 (EVC_Radio.T_Train_At
                              (Unsigned_64 (EVC_Core.Time_Ms)));
      Start_Message (W, K, V);
      P.Q_DIR := 2;
      P.Q_NETWORKTYPE := 2;
      P.Has_NID_MN := True;
      P.NID_MN := MN;
      ETCS_Track_Packets.P45.Encode (P, W, OK);
      Check (OK, "radio order: packet 45 encoded");
      return Message_Bytes (W);
   end M24_With_45;

   procedure Scenario_Network_Radio_Order is
      package RA renames EVC_Radio_Acceptance;
      use type RA.Verdict_T;
      function V (M : EVC_Modes.Mode_T; Cab, Exit_TR : Boolean := False;
                  L : EVC_Modes.Level_T := EVC_Modes.L1) return Boolean
      is (RA.Verdict (RA.Network_Order,
                      (Mode => M, Cab_Active => Cab, Level_Valid => True,
                       Level => L, Trip_Exit_Known => Exit_TR,
                       others => <>)) = RA.Accepted);
   begin
      --  4.8.3 (from RBC: A in every level), 4.8.4 the row of the Radio
      --  Network transition order
      Check (V (EVC_Modes.M_SH) and then V (EVC_Modes.M_SM)
             and then V (EVC_Modes.M_FS, L => EVC_Modes.L0)
             and then V (EVC_Modes.M_RV) and then V (EVC_Modes.M_SN)
             and then not V (EVC_Modes.M_NP, True)
             and then not V (EVC_Modes.M_SF, True)
             and then not V (EVC_Modes.M_IS, True),
             "radio order: packet 45 by radio accepted in every level and "
             & "mode but NP, SF, IS (4.8.3, 4.8.4)");
      Check (V (EVC_Modes.M_SB, True) and then not V (EVC_Modes.M_SB)
             and then V (EVC_Modes.M_PT, Exit_TR => True, L => EVC_Modes.L2)
             and then not V (EVC_Modes.M_PT, L => EVC_Modes.L2)
             and then not V (EVC_Modes.M_PT, Exit_TR => True),
             "radio order: in SB only with a cab active (4.8.4 [2]), in PT "
             & "only after the recognition of the exit from TR in level 2, "
             & "not in level 1 ([1])");
      --  through the ports: SB, a cab active, the session of the
      --  supervising RBC established
      SoM_To_S3;
      EVC_Test_Authority.Establish_Session;
      Give_Radio_Message (1, M24_With_45 (16#456FFF#));
      Stand;
      Check (R.Network.NID_MN = 16#456FFF#,
             "radio order: message 24 with packet 45 in SB, a cab active: "
             & "the network ordered (3.5.6.1 c, 4.8.4 [2])");
      --  4.8.4 [13]: packet 45 of an SM authorisation (message 4)
      --  rejected with it; this on-board takes no message 4 (5.21, SM
      --  mode not implemented): its packet 45 is never taken
      Give_Radio_Message
        (1, M24_With_45 (16#789FFF#, ETCS_Message_Catalogue.Track_M4));
      Stand;
      Check (R.Network.NID_MN = 16#456FFF#,
             "radio order: message 4 (SM authorisation) not taken, nor a "
             & "packet 45 in it (4.8.4 [13])");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Network_Radio_Order;

   procedure Scenario_Network_Level_1 is
      use type EVC_Modes.Mode_T, EVC_Modes.Level_T, R.Session_State_T;
      use type EVC_Bytes.Byte_Array;
      Train : constant Byte_Array :=
        Frame (EVC_DMI_Port.MSG_DRIVER_DATA,
               Byte_Array'(1 => 2) & U16 (200) & U16 (135) & U16 (160)
               & Byte_Array'(1 => 2) & U16 (4) & Byte_Array'(0, 0, 1));
   begin
      EVC_Config.Set_Radio_For_Test
        ((Sessions => 1, Engine_Id => 76_000, Default_MN => 16#262FFF#,
          others => <>));
      EVC_Test_Modes.Start_E4;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, 4));
      Check (EVC_Core.Mode = EVC_Modes.M_SB
             and then EVC_Core.Level = EVC_Modes.L1
             and then not R.Contact.Known
             and then R.Info (1).State = R.Idle,
             "network level 1: S10 in level 1, no RBC contact, no session");

      --  S10: the RBC contact entered is not taken, no session opened
      Send (RBC_Entry);
      Stand;
      Check (not R.Contact.Known and then R.Info (1).State = R.Idle,
             "network level 1: at S10 the RBC data are not taken in level "
             & "1, no session (5.4.5.3 j) 2nd bullet)");
      --  the Radio Network is
      Send (Text_Entry (4, "123"));
      Check (R.Network.NID_MN = 16#123FFF#,
             "network level 1: at S10 the driver's Radio Network taken "
             & "(5.4.5.3 j) 2nd bullet, 3.18.4.3.6)");

      --  S20 alike
      Send (Train);
      Send (Text_Entry (1, "5678"));
      Send (RBC_Entry);
      Send (Text_Entry (4, "456"));
      Check (EVC_Core.Mode = EVC_Modes.M_SB
             and then EVC_Train_Data.Valid
             and then not R.Contact.Known and then R.Info (1).State = R.Idle
             and then R.Network.NID_MN = 16#456FFF#,
             "network level 1: at S20 the Radio Network taken, the RBC "
             & "data not (5.4.5.3 j) 2nd bullet)");
      EVC_Config.Set_Radio_For_Test (EVC_Config.Default_Radio);
   end Scenario_Network_Level_1;

end EVC_Test_Network;
