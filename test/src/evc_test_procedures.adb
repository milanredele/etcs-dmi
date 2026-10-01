--  ETCS on-board (EVC)
--  The scenarios of the procedures of phase E4, implementation.

with DMI_Protocol;
with EVC_Bytes;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Modes;     use EVC_Modes;
with EVC_Outbox;
with EVC_Ports;     use EVC_Ports;
with Interfaces;    use Interfaces;
with Sim_Telegrams;

package body EVC_Test_Procedures is

   package ST renames Sim_Telegrams;
   use type EVC_Bytes.Byte_Array;

   function Img (N : Integer) return String is (Integer'Image (N));

   ---------------------------------------------------------------------
   --  What the on-board said
   ---------------------------------------------------------------------

   --  The DMI codes of the modes (DMI 13.3 Table 60, EVC_DMI_Port)
   Code_SB : constant := 1;
   Code_FS : constant := 2;
   Code_SM : constant := 4;
   Code_LS : constant := 5;
   Code_OS : constant := 6;
   Code_SR : constant := 7;
   Code_SH : constant := 8;
   Code_UN : constant := 9;
   Code_RV : constant := 10;
   Code_TR : constant := 11;
   Code_PT : constant := 13;
   No_Ack  : constant := 16#FF#;

   Out_Buf  : Byte_Array (1 .. EVC_Outbox.Capacity);
   Out_Last : Natural := 0;

   --  The last MSG_MODE_LEVEL: mode, mode_ack, override
   Mode_Byte     : Natural := 0;
   Ack_Byte      : Natural := No_Ack;
   Override_Byte : Natural := 0;
   --  MSG_SPEED_STATE: the permitted speed, km/h
   V_Perm        : Natural := 0;
   --  MSG_STATUS: brake, reversing (the last one sent)
   Status_Brake  : Natural := 0;
   Reversing     : Natural := 0;
   --  MSG_ONBOARD: train
   Onboard_Train : Natural := 0;
   --  MSG_PLANNING in the last cycle
   Planning_Now  : Boolean := False;
   --  The TIU output (the last one sent)
   TIU_Cmd       : Natural := 0;
   TIU_Why       : Natural := 0;

   --  MSG_SYSTEM_STATUS: the events seen
   type SS_T is record
      Entry_N, Event : Natural := 0;
   end record;
   SS_List : array (1 .. 64) of SS_T;
   SS_N    : Natural := 0;

   --  MSG_TEXT, MSG_TEXT_REMOVE
   type Text_Seen_T is record
      Id, Flags : Natural := 0;
      Len       : Natural := 0;
      Text      : String (1 .. 64) := (others => ' ');
   end record;
   Texts     : array (1 .. 32) of Text_Seen_T;
   Text_N    : Natural := 0;
   Removed   : array (1 .. 32) of Natural := (others => 0);
   Removed_N : Natural := 0;

   --  JRU: the mode changes, the events 23 and 24 by kind (byte 2) with
   --  the last byte 3 of each
   JRU_Modes : Natural := 0;
   JRU_Telegrams : Natural := 0;
   type Kinds_T is array (0 .. 15) of Natural;
   J23       : Kinds_T := (others => 0);
   J23_B3    : Kinds_T := (others => 0);
   J24       : Kinds_T := (others => 0);
   Parse_OK  : Boolean := True;

   procedure Forget is
   begin
      SS_N := 0;
      Text_N := 0;
      Removed_N := 0;
      JRU_Modes := 0;
      JRU_Telegrams := 0;
      J23 := (others => 0);
      J23_B3 := (others => 0);
      J24 := (others => 0);
   end Forget;

   function Seen_SS (Entry_N, Event : Natural) return Boolean is
   begin
      for I in 1 .. SS_N loop
         if SS_List (I).Entry_N = Entry_N
           and then SS_List (I).Event = Event
         then
            return True;
         end if;
      end loop;
      return False;
   end Seen_SS;

   function Removed_Id (Id : Natural) return Boolean is
   begin
      for I in 1 .. Removed_N loop
         if Removed (I) = Id then
            return True;
         end if;
      end loop;
      return False;
   end Removed_Id;

   --  The records of the last Take
   procedure Collect is
      Pos : Natural := 0;
   begin
      Planning_Now := False;
      while Pos + 3 <= Out_Last loop
         declare
            Port : constant Natural := Natural (Out_Buf (Pos + 1));
            Len  : constant Natural :=
              Natural (Out_Buf (Pos + 2)) + 256 * Natural (Out_Buf (Pos + 3));
            F    : constant Natural := Pos + 4;   -- first payload byte

            function P (N : Positive) return Natural is
              (if F + N - 1 <= Out_Last then Natural (Out_Buf (F + N - 1))
               else 0);
         begin
            if Pos + 3 + Len > Out_Last then
               Parse_OK := False;
               exit;
            end if;
            if Port = Port_T'Pos (DMI) and then Len >= 5 then
               case P (1) is
                  when 16#02# =>
                     Mode_Byte := P (6);
                     Ack_Byte := P (8);
                     Override_Byte := P (11);
                  when 16#01# =>
                     V_Perm := P (8) + 256 * P (9);
                  when 16#07# =>
                     Status_Brake := P (6);
                     Reversing := P (10);
                  when 16#0A# =>
                     Onboard_Train := P (9);
                  when 16#06# =>
                     Planning_Now := True;
                  when 16#0C# =>
                     if SS_N < SS_List'Last then
                        SS_N := SS_N + 1;
                        SS_List (SS_N) := (P (6), P (7));
                     end if;
                  when 16#03# =>
                     if Text_N < Texts'Last then
                        Text_N := Text_N + 1;
                        Texts (Text_N).Id := P (6) + 256 * P (7);
                        Texts (Text_N).Flags := P (8);
                        Texts (Text_N).Len := Natural'Min (P (11), 64);
                        for K in 1 .. Texts (Text_N).Len loop
                           Texts (Text_N).Text (K) :=
                             Character'Val (P (11 + K));
                        end loop;
                     end if;
                  when 16#04# =>
                     if Removed_N < Removed'Last then
                        Removed_N := Removed_N + 1;
                        Removed (Removed_N) := P (6) + 256 * P (7);
                     end if;
                  when others =>
                     null;
               end case;
            elsif Port = Port_T'Pos (TIU) and then Len = 2 then
               TIU_Cmd := P (1);
               TIU_Why := P (2);
            elsif Port = Port_T'Pos (JRU) and then Len >= 4 then
               if P (1) = 1 then
                  JRU_Modes := JRU_Modes + 1;
               elsif P (1) = 2 then
                  JRU_Telegrams := JRU_Telegrams + 1;
               elsif P (1) = JRU_Procedures and then P (2) <= 15 then
                  J23 (P (2)) := J23 (P (2)) + 1;
                  J23_B3 (P (2)) := P (3);
               elsif P (1) = JRU_Text_Messages and then P (2) <= 15 then
                  J24 (P (2)) := J24 (P (2)) + 1;
               end if;
            end if;
            Pos := Pos + 3 + Len;
         end;
      end loop;
   end Collect;

   ---------------------------------------------------------------------
   --  The track and the train
   ---------------------------------------------------------------------

   --  The balise antenna, cm of the track, which is the odometer's frame
   --  (an exact odometer); its speed, cm/s, signed
   X_Cm  : Integer_64 := 0;
   V_Cms : Integer := 0;
   Over, Under : Integer_64 := 0;
   --  the odometer's confidence: per mille of the distance run
   Bound : constant := 5;

   --  The antenna is 3 m in rear of the front end (EVC_Config.Default)
   Antenna_M : constant := 3;

   type Group_T is record
      NID    : Natural := 0;
      At_Cm  : Integer_64 := 0;
      T0, T1 : ST.Telegram_T;
   end record;
   Groups  : array (1 .. 16) of Group_T;
   Group_N : Natural := 0;
   Spacing : constant := 300;   -- cm between the two balises of a group

   W        : ST.Writer_T;
   Build_OK : Boolean := True;
   Cur_NID  : Natural := 0;
   Cur_At   : Integer_64 := 0;

   --  A group NID of two balises, balise 0 at At_M (m), its nominal
   --  direction the rising track; its packets (Add) go in balise 0
   procedure Group (NID : Natural; At_M : Integer) is
   begin
      Cur_NID := NID;
      Cur_At := Integer_64 (At_M) * 100;
      ST.Start (W, 123, NID, 0, 2, True, Build_OK);
   end Group;

   procedure Add (P : ST.T3.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T5.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T12.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T21.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T27.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T49.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T73.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T74.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T80.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T132.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T135.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T137.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T138.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;
   procedure Add (P : ST.T139.Packet_T) is
   begin
      ST.Put (W, P, Build_OK);
   end Add;

   --  The group is complete; Version: the M_VERSION of its telegrams
   --  (48 is 3.0 here, 64 a version 4.0 this on-board does not support)
   procedure Close (Version : Natural := 48) is
      G : Group_T;
   begin
      G.NID := Cur_NID;
      G.At_Cm := Cur_At;
      ST.Finish (W, G.T0, Build_OK);
      ST.Start (W, 123, Cur_NID, 1, 2, True, Build_OK);
      ST.Finish (W, G.T1, Build_OK);
      if Version /= 48 then
         --  Q_UPDOWN 1, then the seven bits of M_VERSION
         G.T0.Data (1) := Byte (128 + Version mod 128);
         G.T1.Data (1) := Byte (128 + Version mod 128);
      end if;
      Group_N := Group_N + 1;
      Groups (Group_N) := G;
   end Close;

   ---------------------------------------------------------------------
   --  Inputs and cycles
   ---------------------------------------------------------------------

   procedure Input (Port : Port_T; Bytes : Byte_Array) is
   begin
      EVC_Core.Handle_Input (Port, Bytes);
   end Input;

   function Frame (The_Type : Byte; Payload : Byte_Array) return Byte_Array
   is (Byte_Array'(The_Type, Byte (Payload'Length), 0, 0, 0) & Payload);

   --  A driver's action, arg u16
   procedure Driver (Action : Natural; Arg : Natural := 0) is
   begin
      Input (DMI, Frame (16#40#, (Byte (Action), Byte (Arg mod 256),
                                  Byte (Arg / 256))));
   end Driver;

   --  The driver's acknowledgement of a kind (1 mode, 2 fixed text, 3
   --  plain text, 5 brake release), with the id of a text
   procedure Ack (Kind : Natural; Id : Natural := 0) is
   begin
      Input (DMI, Frame (16#40#, (2, Byte (Kind), 0, Byte (Id mod 256),
                                  Byte (Id / 256))));
   end Ack;

   procedure TIU_In (Signal, Value : Natural) is
   begin
      Input (TIU, (Byte (Signal), Byte (Value)));
   end TIU_In;

   function U32 (V : Integer_64) return Byte_Array is
      U : constant Unsigned_64 := Unsigned_64 (Unsigned_32'Mod (V));
   begin
      return (EVC_Bytes.Byte_Of (U, 0), EVC_Bytes.Byte_Of (U, 1),
              EVC_Bytes.Byte_Of (U, 2), EVC_Bytes.Byte_Of (U, 3));
   end U32;

   function U16 (V : Natural) return Byte_Array is
     (Byte (V mod 256), Byte (V / 256 mod 256));

   procedure Sample is
      V : constant Natural := Natural'Min (abs V_Cms, 65_535);
   begin
      Input (Odometer,
             U32 (X_Cm) & U32 (Over) & U32 (Under)
             & U16 (V) & U16 (V) & U16 (V)
             & Byte_Array'(Byte (if V_Cms > 0 then 1
                                 elsif V_Cms < 0 then 2 else 0), 0)
             & U16 (0));
   end Sample;

   procedure Take is
   begin
      EVC_Core.Take_Outputs (Out_Buf, Out_Last);
      Collect;
   end Take;

   --  One cycle of 100 ms: the train moves by its speed (at most To_Cm,
   --  when given), the balises it passes go to the BTM port in their
   --  order with their stamps, then the odometer sample, then the cycle
   No_Target : constant Integer_64 := Integer_64'Last;

   procedure Cycle (To_Cm : Integer_64 := No_Target) is
      Step  : Integer_64 := Integer_64 (V_Cms) / 10;
      Old_X : constant Integer_64 := X_Cm;
   begin
      if To_Cm /= No_Target then
         if Step > 0 then
            Step := Integer_64'Min (Step, To_Cm - X_Cm);
         elsif Step < 0 then
            Step := Integer_64'Max (Step, To_Cm - X_Cm);
         end if;
      end if;
      declare
         New_X : constant Integer_64 := X_Cm + Step;
         type Crossing_T is record
            P    : Integer_64 := 0;
            G, K : Natural := 0;
         end record;
         List : array (1 .. 32) of Crossing_T;
         N    : Natural := 0;
      begin
         for G in 1 .. Group_N loop
            for K in 0 .. 1 loop
               declare
                  P : constant Integer_64 :=
                    Groups (G).At_Cm + Integer_64 (K) * Spacing;
               begin
                  if (Step > 0 and then P > Old_X and then P <= New_X)
                    or else (Step < 0 and then P < Old_X and then P >= New_X)
                  then
                     N := N + 1;
                     List (N) := (P, G, K);
                  end if;
               end;
            end loop;
         end loop;
         --  in the order of passing
         for I in 2 .. N loop
            for J in reverse 2 .. I loop
               if (if Step > 0 then List (J).P < List (J - 1).P
                   else List (J).P > List (J - 1).P)
               then
                  declare
                     Swap : constant Crossing_T := List (J);
                  begin
                     List (J) := List (J - 1);
                     List (J - 1) := Swap;
                  end;
               end if;
            end loop;
         end loop;
         for I in 1 .. N loop
            Input (BTM, ST.BTM_Payload
                          ((if List (I).K = 0 then Groups (List (I).G).T0
                            else Groups (List (I).G).T1),
                           Unsigned_32'Mod (List (I).P)));
         end loop;
         X_Cm := New_X;
         if Step /= 0 then
            Over := Over + abs Step * Bound / 1000 + 1;
            Under := Under + abs Step * Bound / 1000 + 1;
         end if;
      end;
      Sample;
      EVC_Core.Tick (100);
      Take;
   end Cycle;

   --  km/h to cm/s
   function Cms (Kmh : Integer) return Integer is (Kmh * 250 / 9);

   --  Run the front end to To_M (m) at Kmh (forwards or backwards as To_M
   --  lies), then keep that speed
   procedure Run_Front (To_M : Integer; Kmh : Natural) is
      To : constant Integer_64 := Integer_64 (To_M - Antenna_M) * 100;
   begin
      V_Cms := (if To > X_Cm then Cms (Kmh) else -Cms (Kmh));
      while X_Cm /= To loop
         Cycle (To);
      end loop;
   end Run_Front;

   --  Stand still for Ms
   procedure Stand (Ms : Natural := 300) is
   begin
      V_Cms := 0;
      for I in 1 .. Natural'Max (1, Ms / 100) loop
         Cycle;
      end loop;
   end Stand;

   function Front_M return Integer is
     (Integer (X_Cm / 100) + Antenna_M);

   --  A new scenario: the on-board powered up with cab A active and the
   --  direction controller forwards, the train standing with its front
   --  end at Front_At_M, in mode M and level L
   procedure Begin_Scenario (M : Mode_T; L : Level_T;
                             Front_At_M : Integer := -7) is
   begin
      EVC_Core.Initialise;
      Forget;
      Group_N := 0;
      X_Cm := Integer_64 (Front_At_M - Antenna_M) * 100;
      V_Cms := 0;
      Over := 0;
      Under := 0;
      Mode_Byte := 0;
      Ack_Byte := No_Ack;
      Override_Byte := 0;
      TIU_Cmd := 0;
      TIU_Why := 0;
      Status_Brake := 0;
      Reversing := 0;
      TIU_In (1, 1);
      TIU_In (6, 1);
      Cycle;
      EVC_Core.Set_Mode_For_Test (M, L);
      Cycle;
   end Begin_Scenario;

   --  The usual line: a group at 0 m with the SSP (Kmh to Length_M), the
   --  gradients (level) and the MA of one section ending at EOA_M; other
   --  packets of the scenario are added before Close
   procedure Line_Group (EOA_M : Natural; Length_M : Natural := 2_000;
                         Kmh : Natural := 100; NID : Natural := 1;
                         At_M : Integer := 0) is
   begin
      Group (NID, At_M);
      Add (ST.SSP ((1 => (0, Kmh), 2 => (Length_M, ST.End_Mark))));
      Add (ST.Gradients ((1 => (0, 0), 2 => (Length_M, ST.End_Mark))));
      Add (ST.MA ((1 => EOA_M), V_Main_Kmh => Kmh));
   end Line_Group;

   function EB return Boolean is ((TIU_Cmd mod 2) = 1);
   function SB return Boolean is ((TIU_Cmd / 2) mod 2 = 1);
   function Why (Bit : Byte) return Boolean is
     ((TIU_Why / Natural (Bit)) mod 2 = 1);

   ---------------------------------------------------------------------
   --  Scenarios
   ---------------------------------------------------------------------

   --  The frames the procedures add repeat DMI_Protocol
   pragma Warnings (Off, "condition is always*");
   procedure Scenario_Protocol is
      use DMI_Protocol;
   begin
      Check (Unsigned_8 (MSG_TEXT) = EVC_DMI_Port.MSG_TEXT
             and then Unsigned_8 (MSG_TEXT_REMOVE)
                        = EVC_DMI_Port.MSG_TEXT_REMOVE
             and then Unsigned_8 (MSG_SYSTEM_STATUS)
                        = EVC_DMI_Port.MSG_SYSTEM_STATUS
             and then Text_Header_Length = EVC_DMI_Port.Text_Header_Length
             and then Text_Remove_Length = EVC_DMI_Port.Text_Remove_Length
             and then System_Status_Length
                        = EVC_DMI_Port.System_Status_Length,
             "E4 procedures: MSG_TEXT, MSG_TEXT_REMOVE, MSG_SYSTEM_STATUS "
             & "as dmi_protocol.ads");
   end Scenario_Protocol;
   pragma Warnings (On, "condition is always*");

   --  5.11, train trip at the EOA in level 1 and post trip (SUBSET-076
   --  5110200: the trip, its acknowledgement at standstill, Post Trip,
   --  the reverse movement in PT)
   procedure Scenario_Trip_EOA is
   begin
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 300);
      Close;
      Run_Front (200, 20);
      Check (Mode_Byte = Code_FS and then Planning_Now,
             "5.11 trip: FS under the MA before the EOA");
      --  [12]: the min safe antenna position passes the EOA (the
      --  train ignores the brakes)
      Run_Front (340, 20);
      Check (Mode_Byte = Code_TR,
             "5.11.2.2 A025, 4.6.3 [12]: Trip once the EOA is passed "
             & "(level 1, min safe antenna position)");
      Check (EB and then Why (EVC_Ports.TIU_Reason_Trip),
             "4.4.13.1.2, 3.14.1.3: the emergency brake, reason trip");
      Check (Seen_SS (21, 0),
             "4.4.13.1.3: the reason indicated (Unauthorized passing of "
             & "EOA / LOA)");
      Check (J23 (1) = 1 and then J23_B3 (1) = 1,
             "5.11: JRU event 23, train trip, reason EOA passed");
      Check (Ack_Byte = No_Ack,
             "5.11.2.2 S050: no acknowledgement asked while moving");
      Check (not Planning_Now,
             "5.11.2.2 A035: the MA and the track description deleted");
      Stand;
      Check (Ack_Byte = Code_TR,
             "5.11.2.2 S060, 4.4.13.1.4: the trip acknowledgement at "
             & "standstill");
      Ack (1);
      Cycle;
      Check (Mode_Byte = Code_PT,
             "5.11.2.2 E065 / A105, 4.6.3 [7]: Post Trip after the "
             & "acknowledgement in level 1");
      Check (not EB and then not Why (EVC_Ports.TIU_Reason_Trip),
             "5.11.2.2 A105, 4.4.14.1.2: the emergency brake revoked");
      Check (not Seen_SS (21, 1),
             "4.4.14.1.2.1: the reason of the trip still indicated in PT");
      --  4.4.14.1.3: the reverse movement, D_NVPOTRP 200 m (A.3.2), the
      --  direction controller in reverse
      TIU_In (6, 2);
      Run_Front (Front_M - 150, 10);
      Check (not SB, "4.4.14.1.3: a reverse movement within D_NVPOTRP");
      Run_Front (Front_M - 60, 10);
      Check (SB and then Why (EVC_Ports.TIU_Reason_Procedure)
             and then Seen_SS (28, 0),
             "4.4.14.1.3: the service brake beyond D_NVPOTRP, the reason "
             & "indicated");
      Stand;
      Check (Status_Brake = 2,
             "3.14.1.9: the release asked at standstill (PT distance)");
      Ack (5);
      Cycle;
      Check (not SB and then Seen_SS (28, 1),
             "3.14.1.7.4: released at standstill after acknowledgement");
      Run_Front (Front_M - 2, 5);
      Check (SB, "4.4.14.1.3.2: the service brake again for any further "
             & "reverse movement while the distance is overpassed");
      Stand;
      Ack (5);
      Cycle;
      Check (not SB, "3.14.1.7.4: released again");
      --  4.4.14.1.3.1: the forward movement, unauthorised in PT
      TIU_In (6, 1);
      Run_Front (Front_M + 4, 5);
      Check (EB and then Why (8),
             "4.4.14.1.3.1: the unauthorised direction movement "
             & "protection against a forward movement in PT");
      Stand;
      Ack (5);
      Cycle;
      Check (not EB, "3.14.1.5: released at standstill");
      --  5.8.2.1 b), 5.8.3.1 a): Override from PT, the trip reason ends
      Driver (6);
      Cycle;
      Check (Mode_Byte = Code_SR and then Override_Byte = 1,
             "5.8.3.1 a), 4.6.3 [37]: override from PT to SR, override "
             & "indicated (5.8.3.7)");
      Check (Seen_SS (21, 1),
             "DMI Table 68: the trip reason ends when PT is left");
   end Scenario_Trip_EOA;

   --  5.11, 3.11.6.4: the trip order of a balise (4.6.3 [18]), and its
   --  suppression while override is active (5.8.3.6)
   procedure Scenario_Trip_Order is
   begin
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Close;
      Group (2, 200);
      Add (ST.MA ((1 => 500), V_Main_Kmh => 0));
      Close;
      Run_Front (250, 30);
      Check (Mode_Byte = Code_TR and then J23_B3 (1) = 2
             and then Seen_SS (21, 0),
             "4.6.3 [18], 3.11.6.4: a trip order of a balise (V_MAIN 0) "
             & "trips the train");

      Begin_Scenario (M_FS, L1, Front_At_M => 150);
      Line_Group (EOA_M => 1_000, At_M => 140);
      Close;
      Group (2, 300);
      Add (ST.MA ((1 => 500), V_Main_Kmh => 0));
      Close;
      Run_Front (155, 5);
      Stand;
      Driver (6);
      Cycle;
      Check (Mode_Byte = Code_SR and then Override_Byte = 1
             and then J23 (2) = 1,
             "5.8.2.3, 5.8.3.1 a): override selected at standstill, SR");
      Cycle;
      Check (V_Perm = 30,
             "3.11.10.1, 3.11.7.1: the override speed limit (V_NVSUPOVTRP "
             & "30 km/h) below the SR one (V_NVSTFF 40 km/h)");
      Run_Front (320, 25);
      Check (Mode_Byte = Code_SR,
             "5.8.3.6, 4.6.3 [18]: the trip order ignored while override "
             & "is active");
   end Scenario_Trip_Order;

   --  5.11, 3.16.2.3: the linking reactions (4.6.3 [17]; 3.14.1.6)
   procedure Scenario_Linking is
   begin
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Add (ST.Linking ((1 => 100), (1 => 9), Reaction => 0));
      Close;
      Run_Front (150, 30);
      Check (Mode_Byte = Code_TR and then J23_B3 (1) = 4
             and then Seen_SS (2, 0),
             "4.6.3 [17], 3.16.2.3.1 b): the linked group missed, reaction "
             & "train trip (Balise read error)");
      Stand;
      Ack (1);
      Cycle;
      Check (Mode_Byte = Code_PT, "4.6.3 [7]: PT after the linking trip");

      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Add (ST.Linking ((1 => 100), (1 => 9), Reaction => 1));
      Close;
      Run_Front (150, 30);
      Check (Mode_Byte = Code_FS and then SB
             and then Why (EVC_Ports.TIU_Reason_Procedure),
             "3.14.1.6, 3.16.2.3.1 b): reaction service brake, FS stays");
      Stand;
      Check (not SB, "3.14.1.6: the service brake released at standstill");
   end Scenario_Linking;

   --  4.6.3 [69] and [65]
   procedure Scenario_Track_And_Version is
   begin
      Begin_Scenario (M_FS, L1);
      Group (1, 0);
      Add (ST.SSP ((1 => (100, 100), 2 => (500, ST.End_Mark))));
      Add (ST.Gradients ((1 => (0, 0), 2 => (600, ST.End_Mark))));
      Close;
      Run_Front (20, 20);
      Check (Mode_Byte = Code_TR and then J23_B3 (1) = 10
             and then Seen_SS (29, 0),
             "4.6.3 [69]: the estimated front end in rear of the start of "
             & "the SSP (No track description)");

      Begin_Scenario (M_FS, L1);
      Group (1, 20);
      Close (Version => 64);
      Run_Front (40, 20);
      Check (Mode_Byte = Code_TR and then J23_B3 (1) = 9
             and then Seen_SS (16, 0),
             "4.6.3 [65], 3.17.3.5: a telegram of version X = 4 trips "
             & "(Trackside not compatible)");

      Begin_Scenario (M_UN, L0);
      Group (1, 20);
      Close (Version => 64);
      Run_Front (40, 20);
      Check (Mode_Byte = Code_UN,
             "4.6.3 [65]: not in level 0");
   end Scenario_Track_And_Version;

   --  5.6 shunting initiated by the driver, Passive Shunting entry
   --  conditions (4.4.20.1.6), 3.11.7 (SUBSET-076 5060200)
   procedure Scenario_Shunting_Driver is
   begin
      Begin_Scenario (M_SB, L1);
      Driver (7);
      Cycle;
      Check (Mode_Byte = Code_SH and then Ack_Byte = No_Ack,
             "5.6.2.2 E015 / A050, 4.6.3 [5]: SH at standstill in level 1, "
             & "no acknowledgement");
      Cycle;
      Check (V_Perm = 30,
             "3.11.7.1, 4.4.8.1.1 a): the shunting speed limit V_NVSHUNT");
      Run_Front (5, 10);
      Driver (8);
      Cycle;
      Check (Mode_Byte = Code_SH,
             "4.6.3 [19]: no exit of Shunting while moving");
      Stand;
      Driver (8);
      Cycle;
      Check (Mode_Byte = Code_SB,
             "4.6.3 [19]: exit of Shunting at standstill");
      Driver (7);
      Cycle;
      TIU_In (1, 0);
      Cycle;
      Check (Mode_Byte = Code_SB,
             "4.6.3 [27], 4.4.20.1.6: SH to SB when the desk closes, "
             & """Continue Shunting on desk closure"" not active");
      TIU_In (1, 1);
      Cycle;
      Driver (7);
      Cycle;
      Driver (19);
      Cycle;
      TIU_In (1, 0);
      Cycle;
      Check (Mode_Byte = Code_SB,
             "4.6.3 [30], 4.4.20.1.6: SH to SB when the desk closes, "
             & "passive shunting not permitted");

      Begin_Scenario (M_SB, L2);
      Driver (7);
      Cycle;
      Check (Mode_Byte = Code_SB,
             "5.6.2.2 D020: in level 2 the RBC grants Shunting ([6], phase "
             & "E5), none here");

      Begin_Scenario (M_FS, L1);
      Run_Front (0, 10);
      Driver (7);
      Cycle;
      Check (Mode_Byte = Code_FS,
             "5.6.2.2 S0, 4.6.3 [5]: Shunting only at standstill");
      Stand;
      Driver (7);
      Cycle;
      Check (Mode_Byte = Code_SH, "4.6.3 [5]: FS to SH at standstill");

      Begin_Scenario (M_FS, L1);
      TIU_In (1, 0);
      Cycle;
      Check (Mode_Byte = Code_SB, "4.6.3 [28]: FS to SB, the desk closed");

      Begin_Scenario (M_SM, L2);
      Driver (17, 2);
      Cycle;
      Check (Mode_Byte = Code_SB,
             "4.6.3 [82], 5.21: ""Exit of Supervised Manoeuvre"" at "
             & "standstill");
   end Scenario_Shunting_Driver;

   --  4.4.8.1.1 b) and c): the trips of Shunting (4.6.3 [49], [52]); 5.11
   --  in level 0 ([62])
   procedure Scenario_Shunting_Trips is
   begin
      Begin_Scenario (M_SH, L1);
      Group (5, 50);
      Add (ST.Danger_For_Shunting (Stop => True));
      Close;
      Run_Front (80, 15);
      Check (Mode_Byte = Code_TR and then J23_B3 (1) = 6
             and then Seen_SS (24, 0),
             "4.6.3 [49], 4.4.8.1.1 c): ""stop if in shunting"" trips "
             & "(SH stop order)");
      Stand;
      Ack (1);
      Cycle;
      Check (Mode_Byte = Code_PT, "4.6.3 [7]: PT in level 1");

      Begin_Scenario (M_SH, L0);
      Group (5, 50);
      Add (ST.Danger_For_Shunting (Stop => True));
      Close;
      Run_Front (80, 15);
      Stand;
      Ack (1);
      Cycle;
      Check (Mode_Byte = Code_UN and then Seen_SS (24, 1),
             "5.11.2.2 D085 / A145, 4.6.3 [62]: level 0 with Train Data, "
             & "UN; the reason ends");

      Begin_Scenario (M_SH, L1);
      Group (5, 50);
      Add (ST.Danger_For_Shunting (Stop => False));
      Close;
      Run_Front (80, 15);
      Check (Mode_Byte = Code_SH,
             "4.4.8.1.1 c): ""go if in shunting"" lets the train pass");
   end Scenario_Shunting_Trips;

   --  5.7 entry in Shunting ordered by the trackside (SUBSET-076 5070300)
   procedure Scenario_Shunting_Trackside is
   begin
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Add (ST.Mode_Profile (D_M => 200, M_MAMODE => 1, L_M => 0,
                            Ack_M => 100));
      Add (ST.Shunting_Area_List ((1 => 7)));
      Close;
      Group (7, 300);
      Close;
      Group (8, 400);
      Close;
      Run_Front (90, 20);
      Check (Mode_Byte = Code_FS and then Ack_Byte = No_Ack,
             "5.7.3.2: no request before the acknowledgement area");
      Run_Front (120, 20);
      Check (Ack_Byte = Code_SH,
             "5.7.3.2: the request in the acknowledgement area, at or below "
             & "the shunting speed");
      Ack (1);
      Cycle;
      Check (Mode_Byte = Code_SH and then Ack_Byte = No_Ack and then not SB,
             "5.7.3.5, 4.6.3 [50]: SH at once on the acknowledgement");
      Cycle;
      Check (not Planning_Now,
             "4.10 (SH): the MA deleted, no planning in Shunting");
      Run_Front (350, 20);
      Check (Mode_Byte = Code_SH,
             "4.4.8.1.1 b): a balise group of the list for the SH area "
             & "passed");
      Run_Front (450, 20);
      Check (Mode_Byte = Code_TR and then J23_B3 (1) = 7
             and then Seen_SS (24, 0),
             "4.6.3 [52], 4.4.8.1.1 b): a balise group not in the list "
             & "trips");

      --  too fast for the request; the max safe front end reaches the
      --  area: SH, the request, T_ACK, the service brake
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Add (ST.Mode_Profile (D_M => 200, M_MAMODE => 1, L_M => 0,
                            Ack_M => 100));
      Close;
      Run_Front (170, 40);
      Check (Mode_Byte = Code_FS and then Ack_Byte = No_Ack,
             "5.7.3.2 b): no request above the shunting speed");
      Run_Front (200, 40);
      Check (Mode_Byte = Code_SH and then Ack_Byte = Code_SH,
             "5.7.3.6, 4.6.3 [51]: SH when the max safe front end reaches "
             & "the area, the acknowledgement asked");
      Stand (2_000);
      Check (not Why (EVC_Ports.TIU_Reason_Ack_Missing),
             "5.7.3.7: no brake within T_ACK");
      Stand (3_500);
      Check (SB and then Why (EVC_Ports.TIU_Reason_Ack_Missing),
             "5.7.3.7, 3.14.1.7.3: the service brake after T_ACK");
      Ack (1);
      Cycle;
      Check (not SB and then Ack_Byte = No_Ack,
             "3.14.1.7.3: released by the acknowledgement");
   end Scenario_Shunting_Trackside;

   --  5.9 On Sight (SUBSET-076 5090200)
   procedure Scenario_On_Sight is
   begin
      --  a further location, acknowledged in the rectangle
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Add (ST.Mode_Profile (D_M => 300, M_MAMODE => 0, L_M => 200,
                            Ack_M => 100));
      Close;
      Run_Front (190, 20);
      Check (Ack_Byte = No_Ack, "5.9.3.2 a): no request before the area");
      Run_Front (220, 20);
      Check (Mode_Byte = Code_FS and then Ack_Byte = Code_OS,
             "5.9.3.2: the On Sight request in the rectangle of "
             & "acknowledgement");
      Run_Front (240, 20);
      Check (Ack_Byte = Code_OS, "5.9.3.4: the request is not taken back");
      Ack (1);
      Cycle;
      Check (Mode_Byte = Code_OS and then Ack_Byte = No_Ack,
             "5.9.3.6, 4.6.3 [15]: OS at once on the acknowledgement");
      Cycle;
      Check (V_Perm = 30,
             "3.11.7.1: the On Sight speed limit V_NVONSIGHT (30 km/h)");
      Run_Front (400, 20);
      Check (Mode_Byte = Code_OS and then not EB,
             "3.12.4.7: the beginning of the area no temporary EOA once in "
             & "OS");
      Run_Front (540, 20);
      Check (Mode_Byte = Code_FS,
             "5.9.6.1.1, 4.6.3 [75]: FS once the min safe front end leaves "
             & "the area");

      --  not acknowledged: OS when the area is reached, then T_ACK
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Add (ST.Mode_Profile (D_M => 300, M_MAMODE => 0, L_M => 200,
                            Ack_M => 100, Kmh => 25));
      Close;
      Run_Front (300, 20);
      Check (Mode_Byte = Code_OS and then Ack_Byte = Code_OS,
             "5.9.3.7, 4.6.3 [40]: OS when the max safe front end reaches "
             & "the area, the request displayed");
      Cycle;
      Check (V_Perm = 25,
             "3.11.7.1.1: the speed limit of the mode profile prevails");
      Stand (1_000);
      Check (not SB, "5.9.3.8: no brake within T_ACK");
      Stand (4_500);
      Check (SB and then Why (EVC_Ports.TIU_Reason_Ack_Missing)
             and then Status_Brake = 3,
             "5.9.3.8, 3.14.1.7.3: the service brake after T_ACK (DMI "
             & "brake 3)");
      Ack (1);
      Cycle;
      Check (not SB and then Ack_Byte = No_Ack,
             "3.14.1.7.3: released with the acknowledgement");

      --  the current location, from SR (SUBSET-076 5090200_01 steps 39 to
      --  67)
      Begin_Scenario (M_SR, L1);
      Line_Group (EOA_M => 600, At_M => 100);
      Add (ST.Mode_Profile (D_M => 0, M_MAMODE => 0, L_M => 300,
                            Ack_M => 0));
      Close;
      Run_Front (110, 15);
      Check (Mode_Byte = Code_OS and then Ack_Byte = Code_OS,
             "5.9.2.1, 5.9.2.3, 4.6.3 [40]: OS at once at the balise group, "
             & "the acknowledgement asked");
      Run_Front (130, 15);
      Stand (4_000);
      Check (SB and then Why (EVC_Ports.TIU_Reason_Ack_Missing),
             "5.9.2.4: the service brake when not acknowledged within "
             & "T_ACK");
      Ack (1);
      Cycle;
      Check (Mode_Byte = Code_OS and then not SB,
             "5.9.2.3: acknowledged, OS stays, the brake released");

      --  too fast for the rectangle
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Add (ST.Mode_Profile (D_M => 300, M_MAMODE => 0, L_M => 200,
                            Ack_M => 100));
      Close;
      Run_Front (260, 45);
      Check (Mode_Byte = Code_FS and then Ack_Byte = No_Ack,
             "5.9.3.2 b): no request above the On Sight speed limit");
   end Scenario_On_Sight;

   --  5.19 Limited Supervision (SUBSET-076 5190200)
   procedure Scenario_Limited_Supervision is
   begin
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Add (ST.Mode_Profile (D_M => 300, M_MAMODE => 2, L_M => 200,
                            Ack_M => 100, Kmh => 60));
      Close;
      Run_Front (220, 50);
      Check (Ack_Byte = Code_LS,
             "5.19.3.2: the Limited Supervision request in the rectangle "
             & "(at or below the speed of the mode profile)");
      Ack (1);
      Cycle;
      Check (Mode_Byte = Code_LS,
             "5.19.3.6, 4.6.3 [70]: LS on the acknowledgement");
      Cycle;
      Check (V_Perm = 60,
             "3.11.7.1.1: the LS speed limit of the mode profile");
      Run_Front (540, 50);
      Check (Mode_Byte = Code_FS,
             "5.19.6.1.1, 4.6.3 [76]: FS once the area is left");

      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Add (ST.Mode_Profile (D_M => 300, M_MAMODE => 2, L_M => 200,
                            Ack_M => 50));
      Close;
      Run_Front (300, 40);
      Check (Mode_Byte = Code_LS and then Ack_Byte = Code_LS,
             "5.19.3.7, 4.6.3 [72]: LS when the area is reached, the "
             & "request displayed");
      Cycle;
      Check (V_Perm = 100,
             "3.11.7.1: the national LS speed limit V_NVLIMSUPERV");
      Stand (5_500);
      Check (SB and then Why (EVC_Ports.TIU_Reason_Ack_Missing),
             "5.19.3.8: the service brake after T_ACK");
   end Scenario_Limited_Supervision;

   --  5.8 Override (SUBSET-076 5080300, 5080400)
   procedure Scenario_Override is
   begin
      --  c): the former EOA passed with override active
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 200);
      Close;
      Run_Front (150, 20);
      Stand;
      Driver (6);
      Cycle;
      Check (Mode_Byte = Code_SR and then Override_Byte = 1,
             "5.8.3.1 a), 4.6.3 [37]: SR with override, indicated");
      Run_Front (260, 25);
      Check (Mode_Byte = Code_SR,
             "5.8.3.6: no trip at the former EOA while override is active");
      Check (Override_Byte = 0 and then J23 (3) = 1 and then J23_B3 (3) = 3,
             "5.8.4.1 c): override ends once the former EOA is passed");

      --  a), then [43]
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 200);
      Close;
      Run_Front (150, 20);
      Stand;
      Driver (6);
      Cycle;
      Stand (61_000);
      Check (Override_Byte = 0 and then J23_B3 (3) = 1,
             "5.8.4.1 a): override ends after T_NVOVTRP (60 s)");
      Run_Front (260, 25);
      Check (Mode_Byte = Code_TR and then J23_B3 (1) = 3
             and then Seen_SS (21, 0),
             "4.6.3 [43], 5.8.3.1.2: the former EOA passed without "
             & "override trips");

      --  b): the distance
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 600);
      Close;
      Run_Front (20, 20);
      Stand;
      Driver (6);
      Cycle;
      Run_Front (230, 25);
      Check (Override_Byte = 0 and then J23_B3 (3) = 2,
             "5.8.4.1 b): override ends after D_NVOVTRP (200 m)");

      --  5.8.2.1 a): not while moving above V_NVALLOWOVTRP (0)
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 600);
      Close;
      Run_Front (20, 20);
      Driver (6);
      Cycle;
      Check (Mode_Byte = Code_FS and then Override_Byte = 0,
             "5.8.2.1 a): no override above V_NVALLOWOVTRP");

      --  d), and [54] without it
      Begin_Scenario (M_SR, L1);
      Driver (6);
      Cycle;
      Group (4, 50);
      Add (ST.Stop_If_In_SR (Stop => True));
      Close;
      Group (6, 150);
      Add (ST.Stop_If_In_SR (Stop => True));
      Close;
      Run_Front (80, 20);
      Check (Mode_Byte = Code_SR and then Override_Byte = 0
             and then J23_B3 (3) = 4,
             "5.8.4.1 d): ""stop if in SR"" with override: no trip, "
             & "override ends");
      Run_Front (180, 20);
      Check (Mode_Byte = Code_TR and then J23_B3 (1) = 8
             and then Seen_SS (25, 0),
             "4.6.3 [54]: ""stop if in SR"" without override trips (SR "
             & "stop order)");
   end Scenario_Override;

   --  5.13 Train reversing, 3.15.4 (SUBSET-076 5130000)
   procedure Scenario_Reversing is
   begin
      Begin_Scenario (M_FS, L1);
      Line_Group (EOA_M => 1_000);
      Add (ST.Reversing_Area (D_M => 100, L_M => 200));
      Add (ST.Reversing_Supervision (D_M => 150, Kmh => 15));
      Close;
      Run_Front (200, 20);
      Check (Reversing = 0,
             "3.15.4.7: reversing indicated at standstill only");
      Stand;
      Check (Reversing = 1,
             "5.13.1.3, 3.15.4.7: reversing possible at standstill in the "
             & "area");
      TIU_In (6, 2);
      Cycle;
      Check (Ack_Byte = Code_RV,
             "5.13.1.4: the direction controller in reverse asks for the "
             & "acknowledgement of RV");
      Ack (1);
      Cycle;
      Check (Mode_Byte = Code_RV,
             "5.13.1.5, 4.6.3 [59]: RV on the acknowledgement at standstill");
      Cycle;
      Check (V_Perm = 15,
             "3.11.7.1.2: the RV speed limit from the trackside");
      Run_Front (160, 10);
      Check (not EB, "4.4.18.1.3 b): within the distance to run");
      Run_Front (140, 10);
      Check (EB and then Why (EVC_Ports.TIU_Reason_Procedure)
             and then Seen_SS (27, 0),
             "3.15.4.8, 4.4.18.1.3 b): the emergency brake beyond the "
             & "distance (from the end of the area, 3.15.4.2.1)");
      Stand;
      Ack (5);
      Cycle;
      Check (not EB and then Seen_SS (27, 1),
             "3.14.1.7.1: released at standstill after acknowledgement");
   end Scenario_Reversing;

   --  3.12.3 text messages (SUBSET-076 3120300)
   procedure Scenario_Text_Messages is
      C1, C2, C3, C4 : ST.Text_Conditions_T;
      Fixed_Id : Natural := 0;
   begin
      Begin_Scenario (M_FS, L1);
      C1.D_M := 30;
      C1.L_M := 50;
      C2.T_S := 3;
      C2.Confirm := 2;
      C2.Important := True;
      C3.Start_Mode := 1;   -- On Sight
      C4.D_M := 10;
      C4.L_M := 0;
      --  8.4.1.4: one packet 73 per telegram, so one group each
      Group (1, 20);
      Add (ST.Plain_Text ("Hello", C1));
      Add (ST.Fixed_Text (0, C2));
      Close;
      Group (2, 26);
      Add (ST.Plain_Text ("In OS", C3));
      Close;
      Group (3, 32);
      Add (ST.Plain_Text ("Never", C4));
      Close;
      Run_Front (30, 10);
      Check (JRU_Telegrams = 3, "3.12.3: the groups of the texts read");
      Check (Text_N = 1 and then Texts (1).Flags = 3
             and then Texts (1).Text (1 .. Texts (1).Len)
                        = "Level crossing not protected",
             "3.12.3.3.1, 3.12.3.4.3.1.3: the fixed text at once, important, "
             & "to be acknowledged");
      if Text_N >= 1 then
         Fixed_Id := Texts (1).Id;
      end if;
      Run_Front (55, 10);
      Check (Text_N = 2 and then Texts (2).Text (1 .. Texts (2).Len) = "Hello"
             and then Texts (2).Flags = 4,
             "3.12.3.4.2: the plain text from its start location");
      Check (SB and then Why (EVC_Ports.TIU_Reason_Ack_Missing)
             and then not Removed_Id (Fixed_Id),
             "3.12.3.4.7, 3.12.3.4.7.1: not acknowledged after its 3 s, the "
             & "service brake; still displayed");
      Ack (2, Fixed_Id);
      Cycle;
      Check (not SB and then Removed_Id (Fixed_Id),
             "3.14.1.7.5, 3.12.3.4.3.2 a): the acknowledgement releases the "
             & "brake and ends the display");
      Run_Front (110, 10);
      Check (Text_N = 2 and then Removed_N = 2,
             "3.12.3.4.3, 3.12.3.4.6: the plain text removed L_TEXTDISPLAY "
             & "after its start; 3.12.3.4.2: the OS text not in FS; "
             & "3.12.3.4.4: an end at once, no display");
      Check (J24 (1) = 2 and then J24 (2) = 2 and then J24 (3) = 1
             and then J24 (5) = 1,
             "3.12.3: JRU event 24 (displayed, removed, acknowledged, "
             & "brake)");
   end Scenario_Text_Messages;

   --  5.22 Inhibition of the BTM alarm reaction (SUBSET-076 5220200)
   procedure Scenario_BMM is
   begin
      Begin_Scenario (M_SB, L1);
      Driver (18, 0);
      Cycle;
      Check ((Onboard_Train / 16) mod 2 = 1 and then J23 (9) = 1,
             "5.22.2.1, 5.22.4.1: the inhibition at standstill in SB, "
             & "level 1, indicated");
      Driver (18, 1);
      Cycle;
      Check ((Onboard_Train / 16) mod 2 = 0,
             "5.22.5.1 c): revoked by the driver");

      Begin_Scenario (M_FS, L1);
      Driver (18, 0);
      Cycle;
      Check ((Onboard_Train / 16) mod 2 = 0,
             "5.22.2.1: not in FS");

      Begin_Scenario (M_SH, L1);
      Driver (18, 0);
      Cycle;
      Run_Front (310, 25);
      Check ((Onboard_Train / 16) mod 2 = 0 and then J23 (9) = 2,
             "5.22.5.1 a): ended after the 300 m of A.3.1");
   end Scenario_BMM;

   --  3.11.7: the national values of UN and SR
   procedure Scenario_Mode_Speeds is
   begin
      Begin_Scenario (M_UN, L0);
      Cycle;
      Check (V_Perm = 100, "3.11.7.1: V_NVUNFIT in UN");
      Begin_Scenario (M_SR, L1);
      Cycle;
      Check (V_Perm = 40, "3.11.7.1: V_NVSTFF in SR");
   end Scenario_Mode_Speeds;

   procedure Run is
   begin
      Scenario_Protocol;
      Scenario_Trip_EOA;
      Scenario_Trip_Order;
      Scenario_Linking;
      Scenario_Track_And_Version;
      Scenario_Shunting_Driver;
      Scenario_Shunting_Trips;
      Scenario_Shunting_Trackside;
      Scenario_On_Sight;
      Scenario_Limited_Supervision;
      Scenario_Override;
      Scenario_Reversing;
      Scenario_Text_Messages;
      Scenario_BMM;
      Scenario_Mode_Speeds;
      Check (Build_OK and then Parse_OK,
             "E4 procedures: every telegram built, every output parsed");
   end Run;

end EVC_Test_Procedures;
