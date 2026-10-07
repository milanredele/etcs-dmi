with EVC_Acceptance;
with EVC_Config;
with EVC_Modes;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Radio;
with EVC_Sessions;
with EVC_Test_Modes;
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

end EVC_Test_Network;
