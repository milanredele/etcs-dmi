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
--  Then (phase E3) a train runs over balise groups whose telegrams carry
--  plausible and random packets of the stored information (SSP,
--  gradients, MA, TSR, track conditions, national values...); every
--  cycle the snapshot must hold what EVC_Stored_Information proves.
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
with ETCS_Variables;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Modes;    use EVC_Modes;
with EVC_Distances;
with EVC_Outbox;
with EVC_Ports;    use EVC_Ports;
with EVC_Position;
with EVC_Received;
with EVC_Profiles;
with EVC_Stored_Information;
with EVC_Supervision_Input;
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

   --  The events of the position seen, by kind
   type Kind_Counts is array (EVC_Position.Event_Kind_T) of Natural;
   Position_Events : Kind_Counts := (others => 0);

   ---------------------------------------------------------------------
   --  E3 (profiles): the stored information under random packets of its
   --  kinds, on a train running over balise groups. Every cycle the
   --  MRSP must be sorted and below its sources, the SvL not before the
   --  EOA, no envelope check may fail (the proof says so; this is the
   --  check by execution).
   ---------------------------------------------------------------------

   E3_Kinds : constant array (1 .. 15) of Cat.Known_Kind_T :=
     (Cat.Track_P3, Cat.Track_P12, Cat.Track_P21, Cat.Track_P27,
      Cat.Track_P39, Cat.Track_P51, Cat.Track_P65, Cat.Track_P66,
      Cat.Track_P67, Cat.Track_P68, Cat.Track_P70, Cat.Track_P71,
      Cat.Track_P80, Cat.Track_P88, Cat.Track_P141);

   E3_Cycles     : Natural := 0;
   E3_Messages   : Natural := 0;
   E3_MAs        : Natural := 0;
   E3_Plannings  : Natural := 0;
   E3_Conditions : Natural := 0;

   --  A plausible SSP, gradient profile and MA, so that MAs are accepted
   --  and their timers run
   procedure Plausible (W : in out ETCS_Bits.Writer) is
      S  : ETCS_Track_Packets.P27.Packet_T;
      G  : ETCS_Track_Packets.P21.Packet_T;
      M  : ETCS_Track_Packets.P12.Packet_T;
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
   end Plausible;

   procedure E3_Phase (Runs : Natural) is
      use type EVC_Distances.Cm_T;
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
         if S.MA.Present then
            E3_MAs := E3_MAs + 1;
         end if;
      end Check_Snapshot;
   begin
      for Run in 1 .. Runs loop
         begin
            EVC_Core.Initialise;
            EVC_Core.Handle_Input (TIU, (1, 1));
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

      --  2. one cycle, mostly of 100 ms; sometimes none, sometimes huge
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
               declare
                  use type EVC_Distances.Cm_T;
               begin
                  if EVC_Position.Min_Safe_Front
                       > EVC_Position.Estimated_Front
                    or else EVC_Position.Max_Safe_Front
                              < EVC_Position.Estimated_Front
                  then
                     Violation ("confidence interval not around the "
                                & "estimated front end", Step);
                  end if;
               end;
            end if;
         end if;
      exception
         when E : others =>
            Report ("Tick", E, Step);
            Contain_And_Restart (Step);
      end;

      --  3. the outputs, into a buffer of random size and index; now
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

      --  4. rarely: an internal failure, and later the restart
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
             & "  violations:" & Natural'Image (Violations)
             & "  raised:" & Natural'Image (Raised)
             & "  distinct sites:" & Natural'Image (Site_Count));

   --  E3 (profiles)
   E3_Phase (Steps / 5_000);
   Put_Line ("stored information: cycles:" & Natural'Image (E3_Cycles)
             & "  group messages:" & Natural'Image (E3_Messages)
             & "  cycles with an MA:" & Natural'Image (E3_MAs)
             & "  MSG_PLANNING:" & Natural'Image (E3_Plannings)
             & "  MSG_TRACK_COND:" & Natural'Image (E3_Conditions)
             & "  violations:" & Natural'Image (Violations)
             & "  raised:" & Natural'Image (Raised));
   Ada.Command_Line.Set_Exit_Status
     (if Raised = 0 and then Violations = 0 then Ada.Command_Line.Success
      else Ada.Command_Line.Failure);
end EVC_Fuzz;
