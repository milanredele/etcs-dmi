--  ETCS on-board (EVC)
--  Robustness fuzzer: feeds EVC_Core with pseudo random inputs on every
--  port, cycles of random length and takes of random buffers. Nothing
--  may raise: the embedded and WebAssembly runtimes cannot propagate
--  exceptions (doc/EVC-PLAN.md §2; the proof of evc/prove.sh says the
--  same, this is the check by execution).
--
--  Three kinds of inputs are generated: the documented shape of the port
--  with random fields, the documented length with random bytes, and a
--  random length with random bytes; the index of a payload does not
--  always start at 1. On the BTM and RTM ports the shaped inputs are
--  often real telegrams and radio messages of random valid packets
--  (ETCS_Language_Random), sometimes damaged (bits flipped, cut). Every
--  telegram and message the core accepts must decode, packet by packet,
--  without a spare value. Every exception is caught here (native runtime),
--  reported once per distinct site, and the on-board is re-initialised.
--  Besides, after every step the outputs must be whole records and the
--  mode must follow the contracts of EVC_Core (a violation is counted).
--
--  Then (phase E3, stored information) a train runs over balise groups
--  whose telegrams carry plausible and random packets of the stored
--  information (SSP, gradients, MA, TSR, track conditions, national
--  values, permitted braking distances...); every cycle the snapshot
--  must hold what EVC_Stored_Information proves, and every speed
--  restriction to ensure a permitted braking distance must be the one
--  of the inputs of the cycle (3.11.11.3).
--  Phase E3, supervision: now and then a random snapshot of the stored
--  information (EVC_Core.Set_Snapshot_For_Test): profiles of random
--  sizes and orders, random train data, national values, MA, areas and
--  train state; the train then moves a little every cycle. After every
--  cycle the supervision must be consistent with its limits: no
--  Intervention status without a brake command, no release speed
--  monitoring without a release speed, the displayed speeds ordered (P
--  <= W <= SBI), the emergency brake of the speed and distance
--  monitoring on the train interface, and above the ceiling EBI in CSM
--  the emergency brake.
--
--  The installation configuration (EVC_Config): now and then an image
--  to EVC_Core.Configure in the run above, and a phase of power-ups each
--  with random, damaged and random-field images: the configuration is
--  always valid, the image decoded when it is accepted in No Power, the
--  previous one otherwise, the position takes its antenna.
--
--  Usage:  obj/evc_fuzz [steps [seed]]      default 1000000 steps, seed 1
--  Exit status 1 when anything raised or a check was violated.

pragma Ada_2012;
with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;  use Ada.Text_IO;
with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Language_Random;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Telegram;
with ETCS_Track_Packets.P5;
with ETCS_Track_Packets.P12;
with ETCS_Track_Packets.P21;
with ETCS_Track_Packets.P27;
with ETCS_Track_Packets.P52;
with ETCS_Variables;
with EVC_Brake_Commands;
with EVC_Bytes;
with EVC_Config;
with EVC_Core;
with EVC_Distances;
with EVC_DMI_Port;
with EVC_Limits;
with EVC_Modes;    use EVC_Modes;
with EVC_Outbox;
with EVC_PBD;
with EVC_Ports;    use EVC_Ports;
with EVC_Position;
with EVC_Received;
with EVC_Profiles;
with EVC_SDM;
with EVC_Stored_Information;
with EVC_Supervision_Input;
with EVC_Track_Description;
with Interfaces;   use Interfaces;

procedure EVC_Fuzz is

   ---------------------------------------------------------------------
   --  Pseudo random numbers (xorshift32): reproducible from the seed
   ---------------------------------------------------------------------

   State : Unsigned_32 := 1;

   function Next return Unsigned_32 is
   begin
      State := State xor Shift_Left (State, 13);
      State := State xor Shift_Right (State, 17);
      State := State xor Shift_Left (State, 5);
      return State;
   end Next;

   --  uniform in Low .. High
   function Pick (Low, High : Natural) return Natural is
     (Low + Natural (Next mod (Unsigned_32 (High - Low) + 1)));

   function Chance (Percent : Natural) return Boolean is
     (Pick (1, 100) <= Percent);

   function Random_Byte return Byte is (Byte (Next mod 256));

   ---------------------------------------------------------------------
   --  Input under construction
   ---------------------------------------------------------------------

   Buffer : Byte_Array (1 .. 1200);
   Last   : Natural := 0;

   procedure Add (V : Natural) is
   begin
      Last := Last + 1;
      Buffer (Last) := Byte (V mod 256);
   end Add;

   procedure Add_U16 (V : Natural) is
   begin
      Add (V mod 256);
      Add (V / 256 mod 256);
   end Add_U16;

   procedure Add_U32 (V : Unsigned_32) is
   begin
      Add_U16 (Natural (V and 16#FFFF#));
      Add_U16 (Natural (Shift_Right (V, 16)));
   end Add_U32;

   procedure Random_Bytes (Count : Natural) is
   begin
      for I in 1 .. Count loop
         Add (Natural (Random_Byte));
      end loop;
   end Random_Bytes;

   ---------------------------------------------------------------------
   --  Telegrams and radio messages of random valid packets
   ---------------------------------------------------------------------

   package Cat renames ETCS_Catalogue;
   package MCat renames ETCS_Message_Catalogue;
   package Rnd renames ETCS_Language_Random;
   use type Cat.Direction_T;

   W : ETCS_Bits.Writer (ETCS_Bits.Max_Bytes);

   --  the over and under counters of the odometer samples
   Odo_Over, Odo_Under : Unsigned_32 := 0;

   --  A random packet of the direction (not 0 or 255 of the track),
   --  mostly one the sender transmits
   function Random_Kind (Direction : Cat.Direction_T;
                         Sender    : Cat.Sender_T)
     return Cat.Known_Kind_T
   is
      First : constant Natural := Cat.Known_Kind_T'Pos (Cat.Known_Kind_T'First);
      Count : constant Natural :=
        Cat.Known_Kind_T'Pos (Cat.Known_Kind_T'Last) - First;
      Any   : constant Boolean := Chance (10);
      K     : Cat.Known_Kind_T;
   begin
      loop
         K := Cat.Known_Kind_T'Val (First + Pick (0, Count));
         exit when Cat.Direction_Of (K) = Direction
           and then not (Direction = Cat.Track_To_Train
                         and then Cat.NID_Of (K) in 0 | 255)
           and then (Any or else Cat.Sent_By (K) (Sender));
      end loop;
      return K;
   end Random_Kind;

   procedure Random_Packets (Direction : Cat.Direction_T;
                             Sender    : Cat.Sender_T;
                             Count     : Natural)
   is
      OK : Boolean;
   begin
      for I in 1 .. Count loop
         Rnd.Write_Random (Random_Kind (Direction, Sender),
                           (if Chance (50) then Rnd.Random_Values
                            else Rnd.Min_Values),
                           (if Chance (50) then Rnd.Random_Items
                            else Rnd.One_Item),
                           W, OK);
         exit when not OK;
      end loop;
   end Random_Packets;

   --  Flip a few bits of Buffer (1 .. Last) from bit From_Bit on, or none
   procedure Damage (From_Bit : Natural) is
   begin
      if Last > From_Bit / 8 and then Chance (40) then
         for I in 1 .. Pick (1, 3) loop
            declare
               N : constant Natural := Pick (From_Bit, 8 * Last - 1);
            begin
               Buffer (1 + N / 8) :=
                 Buffer (1 + N / 8) xor Shift_Left (1, 7 - N mod 8);
            end;
         end loop;
      end if;
   end Damage;

   --  The detection stamp of a balise: near the last odometer reading
   --  sent, else anywhere
   Last_D_Est : Unsigned_32 := 0;

   procedure Add_Stamp is
   begin
      Add_U32 (if Chance (80)
               then Last_D_Est - 500 + Unsigned_32 (Pick (0, 1_000))
               else Next);
   end Add_Stamp;

   --  A telegram in the BTM shape: stamp, n_bits, then the bits
   procedure Telegram is
      --  a few groups, so that linking meets the groups it announces
      Total : constant Natural := Pick (0, 7);
      H : constant ETCS_Telegram.Header_T :=
        (Q_UPDOWN  => (if Chance (95) then 1 else 0),
         M_VERSION => (if Chance (90) then 48
                       else ETCS_Variables.M_VERSION_T (Pick (0, 127))),
         Q_MEDIA   => 0,
         N_PIG     => ETCS_Variables.N_PIG_T (Pick (0, Total)),
         N_TOTAL   => ETCS_Variables.N_TOTAL_T (Total),
         M_DUP     => ETCS_Variables.M_DUP_T (if Chance (80) then 0
                                               else Pick (0, 2)),
         M_MCOUNT  => ETCS_Variables.M_MCOUNT_T (Pick (0, 255)),
         NID_C     => ETCS_Variables.NID_C_T (if Chance (70) then 1
                                               else Pick (0, 1023)),
         NID_BG    => ETCS_Variables.NID_BG_T (if Chance (70) then Pick (0, 7)
                                                else Pick (0, 16383)),
         Q_LINK    => ETCS_Variables.Q_LINK_T (Pick (0, 1)));
      OK   : Boolean;
      Bits : Natural;
   begin
      ETCS_Bits.Clear (W);
      ETCS_Telegram.Write_Header (W, H);
      if Chance (30) then
         --  linking to the few groups, along a short chain
         declare
            L : ETCS_Track_Packets.P5.Packet_T;
         begin
            L.Q_DIR := ETCS_Variables.Q_DIR_T (Pick (0, 2));
            L.Q_SCALE := ETCS_Variables.Q_SCALE_T (Pick (0, 2));
            L.D_LINK := ETCS_Variables.D_LINK_T (Pick (0, 300));
            L.NID_BG := ETCS_Variables.NID_BG_T
              (if Chance (90) then Pick (0, 7) else 16383);
            L.Q_LINKORIENTATION := ETCS_Variables.Q_LINKORIENTATION_T
              (Pick (0, 1));
            L.Q_LINKREACTION := ETCS_Variables.Q_LINKREACTION_T (Pick (0, 2));
            L.Q_LOCACC := ETCS_Variables.Q_LOCACC_T (Pick (0, 63));
            L.N_ITER := ETCS_Variables.N_ITER_T (Pick (0, 4));
            for I in 1 .. Natural (L.N_ITER) loop
               L.D_LINK_List (I).D_LINK :=
                 ETCS_Variables.D_LINK_T (Pick (0, 300));
               L.D_LINK_List (I).NID_BG :=
                 ETCS_Variables.NID_BG_T (Pick (0, 7));
               L.D_LINK_List (I).Q_LINKORIENTATION :=
                 ETCS_Variables.Q_LINKORIENTATION_T (Pick (0, 1));
               L.D_LINK_List (I).Q_LINKREACTION :=
                 ETCS_Variables.Q_LINKREACTION_T (Pick (0, 2));
               L.D_LINK_List (I).Q_LOCACC :=
                 ETCS_Variables.Q_LOCACC_T (Pick (0, 63));
            end loop;
            ETCS_Track_Packets.P5.Encode (L, W, OK);
         end;
      end if;
      Random_Packets (Cat.Track_To_Train, Cat.Balise, Pick (0, 3));
      ETCS_Telegram.Finish
        (W, (if Chance (50) then ETCS_Telegram.Long_Bits
             else ETCS_Telegram.Short_Bits), OK);
      if not OK then
         ETCS_Bits.Clear (W);
         ETCS_Telegram.Write_Header (W, H);
         ETCS_Telegram.Finish (W, ETCS_Telegram.Short_Bits, OK);
      end if;
      Bits := ETCS_Bits.Position (W);
      if Chance (10) then
         Bits := Pick (ETCS_Telegram.Header_Bits, Bits);   -- cut
      elsif Chance (10) then
         Bits := BTM_Short_Bits;   -- a long telegram read as a short one
      end if;
      declare
         Data : constant Byte_Array := ETCS_Bits.Data (W);
      begin
         Add_Stamp;
         Add_U16 (Bits);
         for I in 1 .. (Bits + 7) / 8 loop
            Add (Natural (Data (I)));
         end loop;
      end;
      Damage (48);
   end Telegram;

   --  A track to train radio message of the list; Last = 0 for a train
   --  to track message
   procedure Message is
      K  : constant MCat.Known_Message_T :=
        MCat.Known_Message_T'Val
          (Pick (MCat.Known_Message_T'Pos (MCat.Known_Message_T'First),
                 MCat.Known_Message_T'Pos (MCat.Known_Message_T'Last)));
      V  : ETCS_Message.Value_Array := (others => 0);
      OK : Boolean;
   begin
      if MCat.Direction_Of (K) /= Cat.Track_To_Train then
         return;
      end if;
      for I in 3 .. MCat.Field_Count (K) loop
         V (I) := Unsigned_64 (Next)
           and (Shift_Left (1, Natural'Min
                  (32, ETCS_Variables.Bits (MCat.Fields (K) (I)))) - 1);
      end loop;
      ETCS_Bits.Clear (W);
      ETCS_Message.Write_Fields (W, K, V, OK);
      Random_Packets (Cat.Track_To_Train, Cat.RBC, Pick (0, 3));
      ETCS_Message.Finish (W, OK);
      if not OK then
         return;
      end if;
      declare
         Data : constant Byte_Array := ETCS_Bits.Data (W);
      begin
         for I in Data'Range loop
            Add (Natural (Data (I)));
         end loop;
      end;
      Damage (18);
   end Message;

   --  The documented length of an input on Port (0 where none)
   function Documented_Length (Port : Port_T) return Natural is
     (case Port is
         when BTM      => BTM_Stamp_Length + 2
                          + ((if Chance (50) then BTM_Short_Bits
                              else BTM_Long_Bits) + 7) / 8,
         when RTM      => Pick (RTM_Min_Length, 64),
         when Odometer => Odometer_Length,
         when TIU      => TIU_Length,
         when DMI      => EVC_DMI_Port.Header_Length
                          + EVC_DMI_Port.Driver_Action_Length,
         when ATO | JRU => Pick (0, 32));

   --  The documented shape with random fields
   procedure Shaped (Port : Port_T) is
   begin
      case Port is
         when BTM =>
            if Chance (60) then
               Telegram;
               return;
            end if;
            declare
               Bits : constant Natural :=
                 (if Chance (90)
                  then (if Chance (50) then BTM_Short_Bits else BTM_Long_Bits)
                  else Pick (0, 65_535));
            begin
               Add_Stamp;
               Add_U16 (Bits);
               Random_Bytes (Natural'Min ((Bits + 7) / 8, 1000));
            end;
         when RTM =>
            if Chance (60) then
               Message;
               if Last > 0 then
                  return;
               end if;
            end if;
            declare
               Length : constant Natural := Pick (RTM_Min_Length, 1023);
            begin
               Add (Pick (0, 255));
               Add (Length / 4);
               Add ((Length mod 4) * 64 + Pick (0, 63));
               Random_Bytes (Length - 3);
            end;
         when Odometer =>
            --  mostly a train that moves on from the last sample, its
            --  over and under counters growing (now and then going back,
            --  or jumping anywhere)
            declare
               Step : constant Unsigned_32 := Unsigned_32 (Pick (0, 5_000));
               D    : constant Unsigned_32 :=
                 (if Chance (85)
                  then (if Chance (70) then Last_D_Est + Step
                        else Last_D_Est - Step)
                  else Next);
               V    : constant Natural :=
                 (if Chance (20) then 0 else Pick (0, 65_535));
               Move : constant Natural :=
                 (if V = 0 and then Chance (80) then 0
                  elsif Chance (90) then Pick (1, 3)
                  else Pick (0, 255));
            begin
               Last_D_Est := D;
               Odo_Over := (if Chance (95)
                            then Odo_Over + Step / Unsigned_32 (Pick (5, 40))
                            else Next);
               Odo_Under := (if Chance (95)
                             then Odo_Under + Step / Unsigned_32 (Pick (5, 40))
                             else Next);
               Add_U32 (D);
               Add_U32 (Odo_Over);
               Add_U32 (Odo_Under);
               Add_U16 (V);
               Add_U16 (if Chance (80) then V / 2 else Pick (0, 65_535));
               Add_U16 (if Chance (80) then V else Pick (0, 65_535));
               Add (Move);
               if Chance (80) then
                  Add (Pick (0, 1));
                  Add_U16 (Pick (0, 400));
               else
                  Add (0);
                  Add_U16 (0);
               end if;
            end;
         when TIU =>
            --  the cab status signals (1, 2) more often than the others
            Add (if Chance (50) then Pick (1, 2)
                 elsif Chance (80) then Pick (1, 5) else Pick (0, 255));
            Add (if Chance (90) then Pick (0, 1) else Pick (0, 255));
         when DMI =>
            declare
               The_Type : constant Natural :=
                 (case Pick (1, 10) is
                     when 1 .. 5 => 16#40#,
                     when 6 .. 8 => 16#41#,
                     when others => Pick (0, 255));
               Length   : constant Natural :=
                 (if The_Type = 16#40# and then Chance (80)
                  then (if Chance (80) then 3 else 5)
                  else Pick (0, 40));
            begin
               Add (The_Type);
               Add_U32 (if Chance (95) then Unsigned_32 (Length)
                        else Next);
               if The_Type = 16#40# and then Length >= 1 then
                  --  isolation now and then, the other actions else
                  Add (if Chance (2) then 20 else Pick (0, 22));
                  Random_Bytes (Length - 1);
               else
                  Random_Bytes (Length);
               end if;
            end;
         when ATO | JRU =>
            Random_Bytes (Pick (0, 32));
      end case;
   end Shaped;

   ---------------------------------------------------------------------
   --  Reporting (as dmi_fuzz)
   ---------------------------------------------------------------------

   Raised     : Natural := 0;
   Violations : Natural := 0;

   Max_Sites  : constant := 32;
   subtype Site_Text is String (1 .. 160);
   type Site is record
      Text  : Site_Text;
      Count : Natural;
   end record;
   Sites      : array (1 .. Max_Sites) of Site;
   Site_Count : Natural := 0;

   procedure Report (Where : String;
                     E     : Ada.Exceptions.Exception_Occurrence;
                     Step  : Natural) is
      Info : constant String :=
        Where & ": " & Ada.Exceptions.Exception_Name (E) & " "
        & Ada.Exceptions.Exception_Message (E);
      Key  : Site_Text := (others => ' ');
      N    : constant Natural := Natural'Min (Info'Length, Key'Length);
   begin
      Raised := Raised + 1;
      Key (1 .. N) := Info (Info'First .. Info'First + N - 1);
      for I in 1 .. Site_Count loop
         if Sites (I).Text = Key then
            Sites (I).Count := Sites (I).Count + 1;
            return;
         end if;
      end loop;
      if Site_Count < Max_Sites then
         Site_Count := Site_Count + 1;
         Sites (Site_Count) := (Text => Key, Count => 1);
      end if;
      Put_Line ("RAISED at step" & Natural'Image (Step) & " in " & Info);
   end Report;

   procedure Violation (What : String; Step : Natural) is
   begin
      Violations := Violations + 1;
      if Violations <= 20 then
         Put_Line ("VIOLATION at step" & Natural'Image (Step) & ": " & What);
      end if;
   end Violation;

   --  Every packet of the last telegram and message accepted decodes and
   --  holds no spare value
   Telegrams_Seen : Natural := 0;
   Messages_Seen  : Natural := 0;
   Checked        : Natural := 0;

   function Decodes return Boolean is
      use type Cat.Packet_Kind_T;
      R     : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
      OK    : Boolean;
      Valid : Boolean;
   begin
      if EVC_Received.Telegram_Count (ETCS_Telegram.Accepted)
           /= Telegrams_Seen
      then
         Telegrams_Seen :=
           EVC_Received.Telegram_Count (ETCS_Telegram.Accepted);
         declare
            T : constant ETCS_Telegram.Telegram_T :=
              EVC_Received.Last_Telegram;
         begin
            for I in 1 .. T.Count loop
               if T.Index (I).Kind /= Cat.Unknown then
                  EVC_Received.Open_Telegram_Packet (I, R);
                  Cat.Check (T.Index (I).Kind, R, OK, Valid);
                  Checked := Checked + 1;
                  if not (OK and then Valid) then
                     return False;
                  end if;
               end if;
            end loop;
         end;
      end if;
      if EVC_Received.Message_Count (ETCS_Message.Accepted)
           /= Messages_Seen
      then
         Messages_Seen := EVC_Received.Message_Count (ETCS_Message.Accepted);
         declare
            M : constant ETCS_Message.Message_T := EVC_Received.Last_Message;
         begin
            for I in 1 .. M.Count loop
               if M.Index (I).Kind /= Cat.Unknown then
                  EVC_Received.Open_Message_Packet (I, R);
                  Cat.Check (M.Index (I).Kind, R, OK, Valid);
                  Checked := Checked + 1;
                  if not (OK and then Valid) then
                     return False;
                  end if;
               end if;
            end loop;
         end;
      end if;
      return True;
   end Decodes;

   --  After a raise the host contains the failure; that path must never
   --  raise itself. Then start over.
   procedure Contain_And_Restart (Step : Natural) is
   begin
      EVC_Core.Enter_Failure;
      EVC_Core.Initialise;
      Telegrams_Seen := 0;
      Messages_Seen := 0;
   exception
      when E : others =>
         Report ("failure containment", E, Step);
         EVC_Core.Initialise;
   end Contain_And_Restart;

   --  The outputs are whole records of a known port and a length within
   --  the maximum of that port
   function Whole_Records (Data : Byte_Array) return Boolean is
      Pos    : Natural := Data'First;
      Length : Natural;
   begin
      while Pos <= Data'Last loop
         if Data'Last - Pos + 1 < EVC_Outbox.Record_Header
           or else Natural (Data (Pos)) > Port_T'Pos (Port_T'Last)
         then
            return False;
         end if;
         Length := Natural (Data (Pos + 1)) + 256 * Natural (Data (Pos + 2));
         if Length > Max_Payload (Port_T'Val (Data (Pos)))
           or else Length > Data'Last - Pos + 1 - EVC_Outbox.Record_Header
         then
            return False;
         end if;
         Pos := Pos + EVC_Outbox.Record_Header + Length;
      end loop;
      return True;
   end Whole_Records;

   ---------------------------------------------------------------------
   --  Random snapshots of the stored information (phase E3)
   ---------------------------------------------------------------------

   package SI renames EVC_Supervision_Input;
   use type EVC_Distances.Cm_T;
   use type EVC_SDM.Monitoring_T;
   use type EVC_SDM.Status_T;

   Snapshot     : SI.Snapshot_T;
   Snapshot_Set : Boolean := False;
   Snapshots    : Natural := 0;
   Supervised   : Natural := 0;

   function Pick_Cm (Low, High : Integer) return EVC_Distances.Cm_T is
     (EVC_Distances.Cm_T (Low) + EVC_Distances.Cm_T (Next mod Unsigned_32
                                                     (High - Low + 1)));

   function Random_Curve return SI.Decel_Curve_T is
      C : SI.Decel_Curve_T;
      V : Natural := 0;
   begin
      C.Count := Pick (0, SI.Max_Curve_Steps);
      for K in 1 .. C.Count loop
         V := (if Chance (90) then Natural'Min (V + Pick (0, 3_000), 30_000)
               else Pick (0, 30_000));
         C.Steps (K) := (Speed => V, Decel => Pick (0, 3_000));
      end loop;
      return C;
   end Random_Curve;

   function Random_Kv return SI.Kv_Set_T is
      K : SI.Kv_Set_T;
      V : Natural := 0;
   begin
      K.Count := (if Chance (50) then 0 else Pick (1, SI.Max_Kv_Steps));
      for I in 1 .. K.Count loop
         K.Steps (I) := (Speed => V, Factor => Pick (0, 2_000));
         V := Natural'Min (V + Pick (0, 4_000), 30_000);
      end loop;
      return K;
   end Random_Kv;

   procedure Random_Snapshot is
      S     : SI.Snapshot_T;
      Big   : constant Boolean := Chance (3);
      X     : EVC_Distances.Cm_T;
      Speed : Natural;
   begin
      S.Supervise := Chance (85);
      S.Mode_Speed :=
        (if Chance (15) then Pick (0, SI.No_Speed_Limit)
         else SI.No_Speed_Limit);
      X := Pick_Cm (-1_000_000, 1_000_000);
      Speed := (if Chance (20) then 0 else Pick (0, 8_000));
      S.Train :=
        (Position_Valid   => Chance (92),
         Ahead            => (if Chance (80) then EVC_Distances.Plus
                              else EVC_Distances.Minus),
         Est_Front        => X,
         Max_Safe_Front   => X + Pick_Cm (0, 5_000),
         Min_Safe_Front   => X - Pick_Cm (0, 5_000),
         Speed            => Speed,
         Speed_Max        => Natural'Min (Speed + Pick (0, 300), 30_000),
         Standstill       => Speed = 0,
         Moving_Ahead     => Speed > 0 and then Chance (90),
         Moving_Backwards => Chance (5));
      S.Train_Data.Length := Pick_Cm (0, 200_000);
      S.Train_Data.Max_Speed := Pick (0, 30_000);
      S.Train_Data.Model := (if Chance (60) then SI.Lambda else SI.Gamma);
      S.Train_Data.Brake_Percentage := Pick (0, 250);
      S.Train_Data.Brake_Position :=
        SI.Brake_Position_T'Val (Pick (0, 2));
      S.Train_Data.A_Brake_Emergency := Random_Curve;
      S.Train_Data.A_Brake_Service := Random_Curve;
      S.Train_Data.A_Brake_Normal := Random_Curve;
      S.Train_Data.T_Brake_Emergency := Pick (0, 60_000);
      S.Train_Data.T_Brake_Service := Pick (0, 60_000);
      S.Train_Data.T_Traction_Cut_Off := Pick (0, 10_000);
      S.Train_Data.Has_Regenerative := Chance (30);
      S.Train_Data.Has_Eddy_Current := Chance (20);
      S.Train_Data.Has_Magnetic_Shoe := Chance (20);
      S.Train_Data.Has_Electro_Pneumatic := Chance (20);

      S.National.M_NVEBCL := Pick (0, 9);
      S.National.Q_NVGUIPERM := Chance (30);
      S.National.Q_NVSBTSMPERM := Chance (80);
      S.National.Q_NVEMRRLS := Chance (50);
      S.National.Q_NVSBFBPERM := Chance (30);
      S.National.Q_NVINHSMICPERM := Chance (20);
      S.National.D_NVROLL := Pick_Cm (0, 1_000);
      S.National.M_NVAVADH := Pick (0, 1_000);
      S.National.A_NVMAXREDADH1 := Pick (0, 3_000);
      S.National.A_NVMAXREDADH2 := Pick (0, 3_000);
      S.National.A_NVMAXREDADH3 := Pick (0, 3_000);
      S.National.Kv_Int_Fresh := Random_Kv;
      S.National.Kv_Int_Passenger := Random_Kv;
      S.National.Kt_Int := Pick (0, 2_000);
      S.National.Kr_Int.Count := Pick (0, 2);
      for I in 1 .. S.National.Kr_Int.Count loop
         S.National.Kr_Int.Steps (I) :=
           (Length => Pick_Cm (0, 100_000), Factor => Pick (0, 2_000));
      end loop;

      --  the MRSP: mostly a few elements in order, now and then many or
      --  out of order
      S.MRSP.Count := (if Big then Pick (0, SI.Max_Speed_Segments)
                       else Pick (0, 8));
      declare
         Start : EVC_Distances.Cm_T := X - Pick_Cm (0, 500_000);
      begin
         for K in 1 .. S.MRSP.Count loop
            S.MRSP.Segments (K) :=
              (Start => Start, Speed => Pick (0, 10_000));
            S.MRSP.TSR (K) := Chance (20);
            Start := (if Chance (95) then Start + Pick_Cm (1, 300_000)
                      else Pick_Cm (-2_000_000, 2_000_000));
         end loop;
      end;
      S.Gradients.Count := (if Big then Pick (0, SI.Max_Gradient_Segments)
                            else Pick (0, 6));
      declare
         Start : EVC_Distances.Cm_T := X - Pick_Cm (0, 500_000);
      begin
         S.Gradients.Has_Default_TSR := Chance (40);
         S.Gradients.Default_TSR := Pick (0, 510) - 255;
         for K in 1 .. S.Gradients.Count loop
            S.Gradients.Segments (K) :=
              (Start => Start, Gradient => Pick (0, 510) - 255);
            S.Gradients.Covered (K) := Chance (85);
            Start := Start + Pick_Cm (1, 300_000);
         end loop;
      end;
      if Chance (70) then
         declare
            EOA : constant EVC_Distances.Cm_T :=
              X + Pick_Cm (-100_000, 2_000_000);
         begin
            S.MA :=
              (Present       => True,
               EOA           => EOA,
               SvL           => (if Chance (90) then EOA + Pick_Cm (0, 50_000)
                                 else EOA - Pick_Cm (0, 50_000)),
               LOA_Speed     => (if Chance (20) then Pick (0, 8_000) else 0),
               Release_Speed =>
                 (Kind  => SI.Release_Speed_Kind_T'Val (Pick (0, 2)),
                  Speed => Pick (0, 3_000)));
         end;
      end if;
      S.Inhibitions.Count := Pick (0, (if Big then 32 else 3));
      for K in 1 .. S.Inhibitions.Count loop
         S.Inhibitions.Areas (K) :=
           (Kind   => SI.Brake_Inhibition_T'Val
                        (Pick (0, SI.Brake_Inhibition_T'Pos
                                    (SI.Brake_Inhibition_T'Last))),
            Start  => X + Pick_Cm (-100_000, 1_000_000),
            Finish => X + Pick_Cm (-100_000, 1_000_000));
      end loop;
      S.Adhesion.Count := Pick (0, (if Big then 32 else 2));
      for K in 1 .. S.Adhesion.Count loop
         S.Adhesion.Areas (K) :=
           (Start  => X + Pick_Cm (-100_000, 1_000_000),
            Finish => X + Pick_Cm (-100_000, 1_000_000));
      end loop;
      S.Adhesion.Driver_Slippery := Chance (10);
      --  a temporary EOA and SvL (3.13.1.5)
      if Chance (25) then
         declare
            E : constant EVC_Distances.Cm_T :=
              X + Pick_Cm (-10_000, 1_500_000);
         begin
            S.Temporary :=
              (Present => True,
               EOA     => E,
               Has_SvL => Chance (70),
               SvL     => (if Chance (90) then E + Pick_Cm (0, 30_000)
                           else E - Pick_Cm (0, 30_000)));
         end;
      end if;

      S.Extra.Config.Service_Brake_Command := Chance (85);
      S.Extra.Config.Service_Brake_Feedback := Chance (30);
      S.Extra.Config.Feedback_From_Cylinder := Chance (30);
      S.Extra.Config.K1_Milli := Pick (1_000, 5_000);
      S.Extra.Config.Traction_Cut_Off := Chance (70);
      for B in SI.Special_Brake_T loop
         S.Extra.Config.Special_Brakes (B) :=
           SI.Special_Brake_Interface_T'Val (Pick (0, 3));
      end loop;
      S.Extra.Config.Additional_Brake_Allowed := Chance (30);
      S.Extra.Config.Regenerative_Needs_Catenary := Chance (70);
      S.Extra.Train.T_Brake_Emergency_React := Pick (0, 20_000);
      S.Extra.Train.T_Brake_Service_React := Pick (0, 20_000);
      S.Extra.Train.Kn_Plus := Random_Curve;
      S.Extra.Train.Kn_Minus := Random_Curve;
      S.Extra.Train.Normal_Service_P (Pick (0, 2)) := Random_Curve;
      S.Extra.Train.M_Rotating_Nom := (if Chance (50) then 0
                                       else Pick (0, 100));
      S.Extra.Train.By_Combination := Chance (20);
      for C in SI.Brake_Combination_T loop
         S.Extra.Train.A_Emergency_Combination (C) := Random_Curve;
         S.Extra.Train.A_Service_Combination (C) := Random_Curve;
      end loop;
      S.Extra.National.Redadh_Use (Pick (1, 3)) :=
        SI.Redadh_Use_T'Val (Pick (0, 3));
      S.National.A_NVP12 := Pick (0, 3_000);
      S.National.A_NVP23 := Pick (0, 3_000);
      S.National.Kv_Int_Passenger_B := Random_Kv;
      S.Extra.Trip_Margin := Pick_Cm (0, 10_000);
      S.Extra.T_MAR := (if Chance (30) then Pick (0, 60_000) else 0);
      S.Extra.SR_Distance := Chance (10);
      S.Extra.SR_End := X + Pick_Cm (-10_000, 500_000);
      Snapshot := S;
      Snapshot_Set := True;
      Snapshots := Snapshots + 1;
   end Random_Snapshot;

   --  The train of the snapshot runs on for a cycle
   procedure Move_On is
      T : SI.Train_State_T renames Snapshot.Train;
      Dv : constant Integer := Pick (0, 60) - 30;
      V  : constant Natural :=
        Natural'Max (Natural'Min (T.Speed + Dv, 30_000), 0);
      D  : constant EVC_Distances.Cm_T := EVC_Distances.Cm_T (V / 10);
   begin
      T.Speed := V;
      T.Speed_Max := Natural'Min (V + Pick (0, 100), 30_000);
      T.Standstill := V = 0;
      T.Moving_Ahead := V > 0;
      T.Est_Front := EVC_Distances.Clamp (T.Est_Front + D);
      T.Max_Safe_Front := EVC_Distances.Clamp (T.Max_Safe_Front + D);
      T.Min_Safe_Front := EVC_Distances.Clamp (T.Min_Safe_Front + D);
   end Move_On;

   --  The supervision after a cycle, against its limits
   procedure Check_Supervision (Step : Natural) is
      R : constant EVC_SDM.Result_T := EVC_Core.Supervision;
      B : constant EVC_Brake_Commands.Commands_T :=
        EVC_Core.Brake_Commands;
   begin
      if R.Active then
         Supervised := Supervised + 1;
      end if;
      if R.Status = EVC_SDM.IntS and then not (R.SB or else R.EB) then
         Violation ("Intervention without a brake command", Step);
      end if;
      if R.Monitoring = EVC_SDM.RSM and then not R.Release_Exists then
         Violation ("release speed monitoring without a release speed",
                    Step);
      end if;
      if R.V_Perm > R.V_Warning or else R.V_Warning > R.V_SBI then
         Violation ("displayed speeds not ordered", Step);
      end if;
      if (R.EB and then not B.EB) or else (R.SB and then not B.SB) then
         Violation ("a command of the supervision not on the TIU", Step);
      end if;
      if R.Active and then R.Monitoring = EVC_SDM.CSM
        and then R.V_Est
                 > R.V_MRSP + EVC_Limits.Margin (EVC_Limits.EBI, R.V_MRSP)
        and then not B.EB
      then
         Violation ("above the ceiling EBI without the emergency brake",
                    Step);
      end if;
      if R.EB_Triggered and then not R.EB then
         Violation ("an emergency brake trigger without the command", Step);
      end if;
   end Check_Supervision;

   --  The events of the position seen, by kind
   type Kind_Counts is array (EVC_Position.Event_Kind_T) of Natural;
   Position_Events : Kind_Counts := (others => 0);

   ---------------------------------------------------------------------
   --  E3 (profiles): the stored information under random packets of its
   --  kinds, on a train running over balise groups. Every cycle the
   --  MRSP must be sorted and below its sources, the SvL not before the
   --  EOA, no envelope check may fail (the proof says so; this is the
   --  check by execution), no gradient where the profile gives nothing;
   --  the supervision on this snapshot is checked as on the random ones.
   ---------------------------------------------------------------------

   E3_Kinds : constant array (1 .. 16) of Cat.Known_Kind_T :=
     (Cat.Track_P3, Cat.Track_P12, Cat.Track_P21, Cat.Track_P27,
      Cat.Track_P39, Cat.Track_P51, Cat.Track_P52, Cat.Track_P65,
      Cat.Track_P66, Cat.Track_P67, Cat.Track_P68, Cat.Track_P70,
      Cat.Track_P71, Cat.Track_P80, Cat.Track_P88, Cat.Track_P141);

   E3_Cycles     : Natural := 0;
   E3_Messages   : Natural := 0;
   E3_MAs        : Natural := 0;
   E3_Plannings  : Natural := 0;
   E3_Conditions : Natural := 0;
   E3_PBD        : Natural := 0;
   E3_PBD_Check  : Natural := 0;

   --  A plausible SSP, gradient profile and MA, so that MAs are accepted
   --  and their timers run, and now and then a plausible packet 52
   procedure Plausible (W : in out ETCS_Bits.Writer) is
      S  : ETCS_Track_Packets.P27.Packet_T;
      G  : ETCS_Track_Packets.P21.Packet_T;
      M  : ETCS_Track_Packets.P12.Packet_T;
      B  : ETCS_Track_Packets.P52.Packet_T;
      OK : Boolean;
   begin
      S.Q_DIR := ETCS_Variables.Q_DIR_T (Pick (0, 2));
      S.Q_SCALE := 1;
      S.D_STATIC := ETCS_Variables.D_STATIC_T (Pick (0, 50));
      S.V_STATIC := ETCS_Variables.V_STATIC_T (Pick (4, 40));
      S.Q_FRONT := ETCS_Variables.Q_FRONT_T (Pick (0, 1));
      S.N_ITER_2 := ETCS_Variables.N_ITER_T (Pick (0, 3));
      for I in 1 .. Natural (S.N_ITER_2) loop
         S.D_STATIC_List (I).D_STATIC :=
           ETCS_Variables.D_STATIC_T (Pick (0, 800));
         S.D_STATIC_List (I).V_STATIC :=
           ETCS_Variables.V_STATIC_T (if Chance (10) then 127
                                      else Pick (4, 40));
         S.D_STATIC_List (I).Q_FRONT := ETCS_Variables.Q_FRONT_T (Pick (0, 1));
      end loop;
      ETCS_Track_Packets.P27.Encode (S, W, OK);
      G.Q_DIR := S.Q_DIR;
      G.Q_SCALE := 1;
      G.D_GRADIENT := ETCS_Variables.D_GRADIENT_T (Pick (0, 50));
      G.Q_GDIR := ETCS_Variables.Q_GDIR_T (Pick (0, 1));
      G.G_A := ETCS_Variables.G_A_T (Pick (0, 30));
      ETCS_Track_Packets.P21.Encode (G, W, OK);
      M.Q_DIR := S.Q_DIR;
      M.Q_SCALE := 1;
      M.V_MAIN := ETCS_Variables.V_MAIN_T (Pick (0, 40));
      M.V_EMA := ETCS_Variables.V_EMA_T (if Chance (20) then Pick (1, 20)
                                         else 0);
      M.T_EMA := ETCS_Variables.T_EMA_T (Pick (0, 1023));
      M.N_ITER := ETCS_Variables.N_ITER_T (Pick (0, 2));
      for I in 1 .. Natural (M.N_ITER) loop
         M.L_SECTION_List (I).L_SECTION :=
           ETCS_Variables.L_SECTION_T (Pick (1, 800));
         if Chance (50) then
            M.L_SECTION_List (I).Q_SECTIONTIMER := 1;
            M.L_SECTION_List (I).Has_T_SECTIONTIMER := True;
            M.L_SECTION_List (I).T_SECTIONTIMER :=
              ETCS_Variables.T_SECTIONTIMER_T (Pick (0, 30));
            M.L_SECTION_List (I).D_SECTIONTIMERSTOPLOC :=
              ETCS_Variables.D_SECTIONTIMERSTOPLOC_T (Pick (0, 800));
         end if;
      end loop;
      M.L_ENDSECTION := ETCS_Variables.L_ENDSECTION_T (Pick (1, 800));
      if Chance (50) then
         M.Q_ENDTIMER := 1;
         M.Has_T_ENDTIMER := True;
         M.T_ENDTIMER := ETCS_Variables.T_ENDTIMER_T (Pick (0, 30));
         M.D_ENDTIMERSTARTLOC :=
           ETCS_Variables.D_ENDTIMERSTARTLOC_T (Pick (0, 800));
      end if;
      if Chance (50) then
         M.Q_DANGERPOINT := 1;
         M.Has_D_DP := True;
         M.D_DP := ETCS_Variables.D_DP_T (Pick (0, 100));
         M.V_RELEASEDP := ETCS_Variables.V_RELEASEDP_T
           (if Chance (50) then Pick (0, 20) else Pick (126, 127));
      end if;
      if Chance (50) then
         M.Q_OVERLAP := 1;
         M.Has_D_STARTOL := True;
         M.D_STARTOL := ETCS_Variables.D_STARTOL_T (Pick (0, 800));
         M.T_OL := ETCS_Variables.T_OL_T (Pick (0, 1023));
         M.D_OL := ETCS_Variables.D_OL_T (Pick (0, 200));
         M.V_RELEASEOL := ETCS_Variables.V_RELEASEOL_T
           (if Chance (50) then Pick (0, 20) else Pick (126, 127));
      end if;
      ETCS_Track_Packets.P12.Encode (M, W, OK);
      if Chance (30) then
         B.Q_DIR := S.Q_DIR;
         B.Q_SCALE := 1;
         if Chance (10) then
            B.Q_TRACKINIT := 1;
            B.Has_D_TRACKINIT := True;
            B.D_TRACKINIT := ETCS_Variables.D_TRACKINIT_T (Pick (0, 800));
         else
            B.Q_TRACKINIT := 0;
            B.Has_D_PBD := True;
            B.D_PBD := ETCS_Variables.D_PBD_T (Pick (0, 3_000));
            B.Q_GDIR := ETCS_Variables.Q_GDIR_T (Pick (0, 1));
            B.G_PBDSR := ETCS_Variables.G_PBDSR_T (Pick (0, 40));
            B.Q_PBDSR := ETCS_Variables.Q_PBDSR_T (Pick (0, 1));
            B.D_PBDSR := ETCS_Variables.D_PBDSR_T (Pick (0, 800));
            B.L_PBDSR := ETCS_Variables.L_PBDSR_T (Pick (0, 800));
            B.N_ITER := ETCS_Variables.N_ITER_T (Pick (0, 3));
            for I in 1 .. Natural (B.N_ITER) loop
               B.D_PBD_List (I) :=
                 (D_PBD   => ETCS_Variables.D_PBD_T (Pick (0, 3_000)),
                  Q_GDIR  => ETCS_Variables.Q_GDIR_T (Pick (0, 1)),
                  G_PBDSR => ETCS_Variables.G_PBDSR_T (Pick (0, 255)),
                  Q_PBDSR => ETCS_Variables.Q_PBDSR_T (Pick (0, 1)),
                  D_PBDSR => ETCS_Variables.D_PBDSR_T (Pick (0, 800)),
                  L_PBDSR => ETCS_Variables.L_PBDSR_T (Pick (0, 800)));
            end loop;
         end if;
         ETCS_Track_Packets.P52.Encode (B, W, OK);
      end if;
   end Plausible;

   procedure E3_Phase (Runs : Natural) is
      Odo_D   : Unsigned_32 := 0;
      Over    : Unsigned_32 := 0;
      Under   : Unsigned_32 := 0;
      Next_BG : Unsigned_32 := 0;
      Out_B   : Byte_Array (1 .. EVC_Outbox.Capacity);
      O_Last  : Natural;
      Id      : Natural := 0;

      procedure Odometer_Sample (Moving : Boolean) is
         V : constant Natural := (if Moving then 1_000 else 0);
      begin
         Last := 0;
         Add_U32 (Odo_D);
         Add_U32 (Over);
         Add_U32 (Under);
         Add_U16 (V);
         Add_U16 (V);
         Add_U16 (V);
         Add (if Moving then 1 else 0);
         Add (0);
         Add_U16 (0);
         EVC_Core.Handle_Input (Odometer, Buffer (1 .. Last));
      end Odometer_Sample;

      --  One balise of a group of Total + 1, detected at Stamp
      procedure Balise (N_PIG, Total : Natural; Stamp : Unsigned_32) is
         H : constant ETCS_Telegram.Header_T :=
           (Q_UPDOWN  => 1,
            M_VERSION => 48,
            Q_MEDIA   => 0,
            N_PIG     => ETCS_Variables.N_PIG_T (N_PIG),
            N_TOTAL   => ETCS_Variables.N_TOTAL_T (Total),
            M_DUP     => 0,
            M_MCOUNT  => 1,
            NID_C     => ETCS_Variables.NID_C_T (if Chance (95) then 1
                                                  else Pick (0, 3)),
            NID_BG    => ETCS_Variables.NID_BG_T (Id),
            Q_LINK    => 0);
         OK : Boolean;
      begin
         ETCS_Bits.Clear (W);
         ETCS_Telegram.Write_Header (W, H);
         if Chance (40) then
            Plausible (W);
         end if;
         for I in 1 .. Pick (0, 3) loop
            Rnd.Write_Random (E3_Kinds (Pick (1, E3_Kinds'Last)),
                              (if Chance (50) then Rnd.Random_Values
                               else Rnd.Min_Values),
                              (if Chance (50) then Rnd.Random_Items
                               else Rnd.One_Item),
                              W, OK);
            exit when not OK;
         end loop;
         ETCS_Telegram.Finish (W, ETCS_Telegram.Long_Bits, OK);
         if not OK then
            ETCS_Bits.Clear (W);
            ETCS_Telegram.Write_Header (W, H);
            ETCS_Telegram.Finish (W, ETCS_Telegram.Long_Bits, OK);
         end if;
         declare
            Data : constant Byte_Array := ETCS_Bits.Data (W);
            Bits : constant Natural := ETCS_Bits.Position (W);
         begin
            Last := 0;
            Add_U32 (Stamp);
            Add_U16 (Bits);
            for I in 1 .. (Bits + 7) / 8 loop
               Add (Natural (Data (I)));
            end loop;
            EVC_Core.Handle_Input (BTM, Buffer (1 .. Last));
         end;
      end Balise;

      procedure Check_Snapshot (Step : Natural) is
         use EVC_Profiles;
         S : constant EVC_Supervision_Input.Snapshot_T :=
           EVC_Stored_Information.Current;
      begin
         E3_Cycles := E3_Cycles + 1;
         if not Sorted (EVC_Stored_Information.MRSP_Steps)
           or else not Below (EVC_Stored_Information.MRSP_Steps,
                              EVC_Stored_Information.MRSP_Sources, 0,
                              EVC_Stored_Information.MRSP_Ceiling)
         then
            Violation ("E3: the MRSP not sorted or above a source", Step);
         end if;
         if EVC_Stored_Information.Envelope_Failures /= 0 then
            Violation ("E3: an envelope check failed", Step);
         end if;
         if S.MA.Present
           and then A (S.Train.Ahead, S.MA.SvL) < A (S.Train.Ahead, S.MA.EOA)
         then
            Violation ("E3: the SvL before the EOA", Step);
         end if;
         for K in 1 .. S.MRSP.Count - 1 loop
            if A (S.Train.Ahead, S.MRSP.Segments (K).Start)
               >= A (S.Train.Ahead, S.MRSP.Segments (K + 1).Start)
            then
               Violation ("E3: the MRSP not sorted ahead", Step);
            end if;
         end loop;
         for K in 1 .. S.Gradients.Count loop
            if not S.Gradients.Covered (K)
              and then S.Gradients.Segments (K).Gradient /= 0
            then
               Violation ("E3: a gradient where the profile gives nothing",
                          Step);
            end if;
         end loop;
         --  3.11.11.3: every section computed, and (checked now and then,
         --  the computation is long) with the inputs of this cycle
         declare
            P : constant Store_T := EVC_Track_Description.PBD;
         begin
            E3_PBD := E3_PBD + P.Count;
            for K in 1 .. P.Count loop
               if not P.List (K).Noted
                 or else P.List (K).Value not in 0 .. EVC_PBD.Top_Speed
               then
                  Violation ("E3: a PBD section not computed", Step);
               elsif Chance (2) then
                  E3_PBD_Check := E3_PBD_Check + 1;
                  if P.List (K).Value
                     /= EVC_PBD.Restriction
                          (EVC_Stored_Information.PBD_Inputs,
                           EVC_Distances.Cm_T'Min
                             (EVC_PBD.PBD_Distance_T'Last,
                              EVC_Distances.Cm_T (P.List (K).Id)),
                           Integer'Max (-255, Integer'Min
                             (255, P.List (K).Gradient)),
                           P.List (K).Service)
                  then
                     Violation ("E3: a PBD speed not the one of the inputs "
                                & "of the cycle (3.11.11.3)", Step);
                  end if;
               end if;
            end loop;
         end;
         if S.MA.Present then
            E3_MAs := E3_MAs + 1;
         end if;
      end Check_Snapshot;
   begin
      for Run in 1 .. Runs loop
         begin
            EVC_Core.Initialise;
            EVC_Core.Handle_Input (TIU, (1, 1));
            --  phase E4: the stored information in FS, level 1, with the
            --  default train (as evc_test runs the scenarios of E3)
            EVC_Core.Set_Mode_For_Test (M_FS, L1);
            Odo_D := Next;
            Over := 0;
            Under := 0;
            Next_BG := Odo_D + Unsigned_32 (Pick (1_000, 30_000));
            for Step in 1 .. Pick (50, 400) loop
               declare
                  Move : constant Unsigned_32 :=
                    (if Chance (10) then 0
                     else Unsigned_32 (Pick (100, 3_000)));
               begin
                  --  the groups passed in the move
                  while Move > 0 and then Next_BG - Odo_D <= Move loop
                     Id := (Id + 1) mod 16_000;
                     declare
                        Total : constant Natural := Pick (0, 1);
                     begin
                        for B in 0 .. Total loop
                           Balise (B, Total, Next_BG + Unsigned_32 (B * 300));
                        end loop;
                     end;
                     E3_Messages := E3_Messages + 1;
                     Next_BG := Next_BG + Unsigned_32 (Pick (5_000, 60_000));
                  end loop;
                  Odo_D := Odo_D + Move;
                  Over := Over + Move / 50;
                  Under := Under + Move / 50;
                  Odometer_Sample (Move > 0);
                  EVC_Core.Tick (100);
                  EVC_Core.Take_Outputs (Out_B, O_Last);
                  if not Whole_Records (Out_B (1 .. O_Last)) then
                     Violation ("E3: not whole records", Step);
                  end if;
                  --  MSG_PLANNING and MSG_TRACK_COND seen
                  declare
                     Pos : Natural := 1;
                  begin
                     while Pos + 3 <= O_Last loop
                        if Out_B (Pos) = Byte (Port_T'Pos (DMI))
                          and then Out_B (Pos + 3)
                                     = EVC_DMI_Port.MSG_PLANNING
                        then
                           E3_Plannings := E3_Plannings + 1;
                        elsif Out_B (Pos) = Byte (Port_T'Pos (DMI))
                          and then Out_B (Pos + 3)
                                     = EVC_DMI_Port.MSG_TRACK_COND
                        then
                           E3_Conditions := E3_Conditions + 1;
                        end if;
                        Pos := Pos + EVC_Outbox.Record_Header
                               + Natural (Out_B (Pos + 1))
                               + 256 * Natural (Out_B (Pos + 2));
                     end loop;
                  end;
                  Check_Snapshot (Step);
                  --  the supervision on the snapshot of the stored
                  --  information
                  Check_Supervision (Step);
               end;
            end loop;
         exception
            when E : others =>
               Report ("E3 stored information", E, Run);
               Contain_And_Restart (Run);
         end;
      end loop;
   end E3_Phase;

   Steps : Natural := 1_000_000;
   Port  : Port_T := BTM;

   ---------------------------------------------------------------------
   --  The installation configuration (EVC_Config, EVC_Core.Configure):
   --  random images, damaged images and images of random configurations
   ---------------------------------------------------------------------

   Config_Images   : Natural := 0;
   Config_Accepted : Natural := 0;
   type Status_Counts_T is array (EVC_Config.Status_T) of Natural;
   Config_Status   : Status_Counts_T := (others => 0);

   --  An image in Buffer (1 .. Last): random bytes, the default image
   --  damaged (resealed or not), or the image of a random configuration
   --  with random field bytes (Table 3 and the ranges not respected)
   procedure Config_Image is
      D : constant EVC_Config.Image_T :=
        EVC_Config.Encode (EVC_Config.Default);

      procedure Reseal is
         C : constant Unsigned_32 :=
           EVC_Config.CRC_32 (Buffer (1 .. EVC_Config.CRC_Offset));
      begin
         if Last >= EVC_Config.Image_Length then
            for N in 0 .. 3 loop
               Buffer (EVC_Config.CRC_Offset + 1 + N) :=
                 EVC_Bytes.Byte_Of (Unsigned_64 (C), N);
            end loop;
         end if;
      end Reseal;
   begin
      Last := 0;
      case Pick (1, 4) is
         when 1 =>
            Random_Bytes (Pick (0, 80));
         when 2 =>
            for B of D loop
               Add (Natural (B));
            end loop;
            for K in 1 .. Pick (1, 3) loop
               Buffer (Pick (1, D'Length)) := Random_Byte;
            end loop;
            if Chance (70) then
               Reseal;
            end if;
            Last := Pick (0, D'Length + 8);
         when 3 =>
            --  a random configuration in the ranges of its fields, its
            --  special brake interfaces not always allowed by Table 3
            declare
               C : EVC_Config.Config_T;
               S : EVC_Supervision_Input.Onboard_Config_T renames
                 C.Supervision;
            begin
               S.Service_Brake_Command := Chance (50);
               S.Service_Brake_Feedback := Chance (50);
               S.Feedback_From_Cylinder := Chance (50);
               S.K1_Milli := Pick (1_000, 5_000);
               S.Traction_Cut_Off := Chance (50);
               for B in S.Special_Brakes'Range loop
                  S.Special_Brakes (B) :=
                    EVC_Supervision_Input.Special_Brake_Interface_T'Val
                      (Pick (0, 3));
               end loop;
               S.Additional_Brake_Allowed := Chance (50);
               S.Regenerative_Needs_Catenary := Chance (50);
               S.SB_Failure_Time_Ms := Pick (0, 60_000);
               S.SB_Failure_Decel_Mms2 := Pick (0, 3_000);
               C.Antenna_To_Cab_A := EVC_Config.Antenna_Offset_T
                 (Pick (0, 100_000));
               C.Antenna_To_Cab_B := EVC_Config.Antenna_Offset_T
                 (Pick (0, 100_000));
               for B of EVC_Config.Encode (C) loop
                  Add (Natural (B));
               end loop;
            end;
         when others =>
            for B of D loop
               Add (Natural (B));
            end loop;
            --  the fields, each a small random value or random bytes
            for Offset in 8 .. EVC_Config.CRC_Offset - 1 loop
               Buffer (Offset + 1) :=
                 (if Chance (50) then Byte (Pick (0, 4)) else Random_Byte);
            end loop;
            --  plausible values of the wide fields now and then
            if Chance (50) then
               Buffer (13 .. 14) :=
                 (Byte (Pick (0, 255)), Byte (Pick (3, 19)));
               Buffer (21 .. 24) := (Random_Byte, Byte (Pick (0, 1)), 0, 0);
               Buffer (25 .. 28) := (Random_Byte, Byte (Pick (0, 1)), 0, 0);
               Buffer (29 .. 30) := (Random_Byte, Byte (Pick (0, 234)));
               Buffer (31 .. 32) := (Random_Byte, Byte (Pick (0, 11)));
            end if;
            Reseal;
      end case;
   end Config_Image;

   --  Configure with the image of Buffer, at index First; the contract of
   --  EVC_Core.Configure checked by execution
   procedure Try_Configure (Step : Natural) is
      First   : constant Positive :=
        (if Chance (80) then 1 else Pick (1, 1_000_000));
      Payload : constant Byte_Array (First .. First + Last - 1) :=
        Buffer (1 .. Last);
      Before  : constant EVC_Config.Config_T := EVC_Core.Configuration;
      In_NP   : constant Boolean := EVC_Core.Mode = M_NP;
      R       : constant EVC_Config.Decoded_T :=
        EVC_Config.Decoded (Payload);
      use type EVC_Config.Config_T;
      use type EVC_Config.Status_T;
   begin
      EVC_Core.Configure (Payload);
      Config_Images := Config_Images + 1;
      Config_Status (EVC_Config.Last_Status) :=
        Config_Status (EVC_Config.Last_Status) + 1;
      if not EVC_Config.Valid (EVC_Core.Configuration) then
         Violation ("Configure: the configuration is not valid", Step);
      end if;
      if In_NP and then R.Status = EVC_Config.Accepted then
         Config_Accepted := Config_Accepted + 1;
         if EVC_Core.Configuration /= R.Config
           or else not EVC_Core.Configured
         then
            Violation ("Configure: a valid image is not the configuration",
                       Step);
         end if;
      elsif EVC_Core.Configuration /= Before then
         Violation ("Configure: a refused image changed the configuration",
                    Step);
      end if;
      if EVC_Position.Front_Offset (EVC_Distances.Plus)
           /= EVC_Core.Configuration.Antenna_To_Cab_A
        or else EVC_Position.Front_Offset (EVC_Distances.Minus)
                  /= EVC_Core.Configuration.Antenna_To_Cab_B
      then
         Violation ("Configure: the position has another antenna", Step);
      end if;
   exception
      when E : others =>
         Report ("Configure", E, Step);
         Contain_And_Restart (Step);
   end Try_Configure;

   --  Runs power-ups, each with an image in No Power and a few cycles
   procedure Config_Phase (Runs : Natural) is
      Out_B  : Byte_Array (1 .. EVC_Outbox.Capacity);
      O_Last : Natural;
   begin
      for Run in 1 .. Runs loop
         begin
            EVC_Core.Initialise;
            for K in 1 .. Pick (1, 3) loop
               Config_Image;
               Try_Configure (Run);
            end loop;
            for K in 1 .. Pick (1, 5) loop
               EVC_Core.Tick (100);
               EVC_Core.Take_Outputs (Out_B, O_Last);
               if not Whole_Records (Out_B (1 .. O_Last)) then
                  Violation ("configuration: not whole records", Run);
               end if;
            end loop;
         exception
            when E : others =>
               Report ("configuration phase", E, Run);
               Contain_And_Restart (Run);
         end;
      end loop;
      --  back to the default
      EVC_Core.Initialise;
      EVC_Core.Configure (EVC_Config.Encode (EVC_Config.Default));
   end Config_Phase;

begin
   if Ada.Command_Line.Argument_Count >= 1 then
      Steps := Natural'Value (Ada.Command_Line.Argument (1));
   end if;
   if Ada.Command_Line.Argument_Count >= 2 then
      State := Unsigned_32'Value (Ada.Command_Line.Argument (2));
      if State = 0 then
         State := 1;
      end if;
   end if;

   EVC_Core.Initialise;

   for Step in 1 .. Steps loop
      --  1. a few inputs on random ports
      for I in 1 .. Pick (0, 4) loop
         Port := Port_T'Val (Pick (0, Port_T'Pos (Port_T'Last)));
         Last := 0;
         case Pick (1, 3) is
            when 1 => Shaped (Port);
            when 2 => Random_Bytes (Documented_Length (Port));
            when others => Random_Bytes (Pick (0, Buffer'Last));
         end case;
         declare
            --  the payload, now and then at another index than 1
            First   : constant Positive :=
              (if Chance (90) then 1 else Pick (1, 1_000_000));
            Payload : constant Byte_Array (First .. First + Last - 1) :=
              Buffer (1 .. Last);
            Isolation_Before : constant Boolean :=
              EVC_Core.Isolation_Requested;
            Mode_Before : constant Mode_T := EVC_Core.Mode;
         begin
            EVC_Core.Handle_Input (Port, Payload);
            if EVC_Core.Mode /= Mode_Before
              or else (Isolation_Before
                       and then not EVC_Core.Isolation_Requested)
            then
               Violation ("Handle_Input changed the mode", Step);
            end if;
         exception
            when E : others =>
               Report ("Handle_Input " & Port_T'Image (Port), E, Step);
               Contain_And_Restart (Step);
         end;
      end loop;

      --  1b. rarely an image of the installation configuration (in No
      --  Power after a restart, refused otherwise)
      if Chance (1) then
         Config_Image;
         Try_Configure (Step);
      end if;

      --  2. the stored information: now and then a new random snapshot,
      --  the train of the last one moving on
      if Chance (2) then
         Random_Snapshot;
      elsif Snapshot_Set then
         Move_On;
      end if;
      if Snapshot_Set then
         begin
            EVC_Core.Set_Snapshot_For_Test (Snapshot);
         exception
            when E : others =>
               Report ("Set_Snapshot_For_Test", E, Step);
               Contain_And_Restart (Step);
         end;
      end if;

      --  3. one cycle, mostly of 100 ms; sometimes none, sometimes huge
      declare
         Mode_Before : constant Mode_T := EVC_Core.Mode;
         Isolation   : constant Boolean := EVC_Core.Isolation_Requested;
         Failed      : constant Boolean := EVC_Core.Failed;
      begin
         if Chance (97) then
            EVC_Core.Tick (case Pick (1, 20) is
                              when 1      => 0,
                              when 2      => Natural'Last,
                              when 3      => Pick (0, Natural'Last),
                              when others => 100);
            if not Failed then
               if EVC_Core.Mode = M_NP then
                  Violation ("NP after a cycle", Step);
               end if;
               if EVC_Core.Mode /= Mode_Before
                 and then not Transition_Exists (Mode_Before, EVC_Core.Mode)
               then
                  Violation ("a transition 4.6.2 does not have", Step);
               end if;
               if Mode_Before = M_NP
                 and then EVC_Core.Mode /= (if Isolation then M_IS else M_SB)
               then
                  Violation ("the mode after NP", Step);
               end if;
               if not Decodes then
                  Violation ("an accepted packet does not decode", Step);
               end if;
               for I in 1 .. EVC_Position.Event_Count loop
                  declare
                     K : constant EVC_Position.Event_Kind_T :=
                       EVC_Position.Event (I).Kind;
                  begin
                     Position_Events (K) := Position_Events (K) + 1;
                  end;
               end loop;
               if EVC_Position.Min_Safe_Front
                    > EVC_Position.Estimated_Front
                 or else EVC_Position.Max_Safe_Front
                           < EVC_Position.Estimated_Front
               then
                  Violation ("confidence interval not around the "
                             & "estimated front end", Step);
               end if;
               Check_Supervision (Step);
            end if;
         end if;
      exception
         when E : others =>
            Report ("Tick", E, Step);
            Contain_And_Restart (Step);
      end;

      --  4. the outputs, into a buffer of random size and index; now
      --     and then nobody takes them for a while
      if Chance (80) then
         declare
            First  : constant Positive :=
              (if Chance (80) then 1 else Pick (1, 1_000_000));
            Size   : constant Natural :=
              (if Chance (70) then EVC_Outbox.Capacity
               else Pick (0, 3 * EVC_Outbox.Capacity / 2));
            Output : Byte_Array (First .. First + Size - 1);
            O_Last : Natural;
         begin
            EVC_Core.Take_Outputs (Output, O_Last);
            if O_Last < First - 1 or else O_Last > Output'Last then
               Violation ("Take_Outputs: Last out of the buffer", Step);
            elsif not Whole_Records (Output (First .. O_Last)) then
               Violation ("Take_Outputs: not whole records", Step);
            elsif EVC_Core.Failed and then O_Last /= First - 1 then
               Violation ("Take_Outputs: output after a failure", Step);
            end if;
         exception
            when E : others =>
               Report ("Take_Outputs", E, Step);
               Contain_And_Restart (Step);
         end;
      end if;

      --  5. rarely: an internal failure, and later the restart
      if Chance (1) and then Chance (10) then
         begin
            if EVC_Core.Failed then
               EVC_Core.Initialise;
               Telegrams_Seen := 0;
               Messages_Seen := 0;
            else
               EVC_Core.Enter_Failure;
            end if;
         exception
            when E : others =>
               Report ("Enter_Failure / Initialise", E, Step);
               Contain_And_Restart (Step);
         end;
      end if;
   end loop;

   New_Line;
   Put ("position events:");
   for K in EVC_Position.Event_Kind_T loop
      Put (" " & EVC_Position.Event_Kind_T'Image (K)
           & Natural'Image (Position_Events (K)));
   end loop;
   New_Line;
   for I in 1 .. Site_Count loop
      Put_Line (Natural'Image (Sites (I).Count) & " x  " & Sites (I).Text);
   end loop;
   Put_Line ("steps:" & Natural'Image (Steps)
             & "  cycles:" & EVC_Core.Cycle_T'Image (EVC_Core.Cycle)
             & "  accepted (since the last restart):"
             & Natural'Image (EVC_Core.Accepted (BTM)
                              + EVC_Core.Accepted (RTM)
                              + EVC_Core.Accepted (Odometer)
                              + EVC_Core.Accepted (TIU)
                              + EVC_Core.Accepted (DMI))
             & "  telegrams accepted:"
             & Natural'Image (EVC_Received.Telegram_Count
                                (ETCS_Telegram.Accepted))
             & "  messages accepted:"
             & Natural'Image (EVC_Received.Message_Count
                                (ETCS_Message.Accepted))
             & "  packets decoded:" & Natural'Image (Checked)
             & "  snapshots:" & Natural'Image (Snapshots)
             & "  cycles supervised:" & Natural'Image (Supervised)
             & "  violations:" & Natural'Image (Violations)
             & "  raised:" & Natural'Image (Raised)
             & "  distinct sites:" & Natural'Image (Site_Count));

   --  the installation configuration
   Config_Phase (Steps / 20);
   Put ("configuration: images:" & Natural'Image (Config_Images)
        & "  accepted:" & Natural'Image (Config_Accepted) & " ");
   for S in EVC_Config.Status_T loop
      Put (" " & EVC_Config.Status_T'Image (S)
           & Natural'Image (Config_Status (S)));
   end loop;
   Put_Line ("  violations:" & Natural'Image (Violations)
             & "  raised:" & Natural'Image (Raised));

   --  E3 (profiles)
   E3_Phase (Steps / 5_000);
   Put_Line ("stored information: cycles:" & Natural'Image (E3_Cycles)
             & "  group messages:" & Natural'Image (E3_Messages)
             & "  cycles with an MA:" & Natural'Image (E3_MAs)
             & "  MSG_PLANNING:" & Natural'Image (E3_Plannings)
             & "  MSG_TRACK_COND:" & Natural'Image (E3_Conditions)
             & "  PBD sections:" & Natural'Image (E3_PBD)
             & " (checked:" & Natural'Image (E3_PBD_Check) & ")"
             & "  violations:" & Natural'Image (Violations)
             & "  raised:" & Natural'Image (Raised));
   Ada.Command_Line.Set_Exit_Status
     (if Raised = 0 and then Violations = 0 then Ada.Command_Line.Success
      else Ada.Command_Line.Failure);
end EVC_Fuzz;
