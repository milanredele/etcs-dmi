with Ada.Directories;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Streams.Stream_IO;
with Ada.Streams;
with Ada.Text_IO;
with ETCS_Catalogue;
with ETCS_Telegram;
with ETCS_Track_Packets.P16;
with EVC_Distances;
with EVC_Stored_Information;
with EVC_Track;
with EVC_Train_Data;
with GNAT.SHA256;
with Sim_Telegrams;
with Sim_Trackside;

package body EVC_Test_Support is

   package Tel renames ETCS_Telegram;
   package T16 renames ETCS_Track_Packets.P16;
   package SI renames EVC_Stored_Information;

   use type EVC_Distances.Cm_T;
   use type EVC_Distances.Sense_T;
   use Ada.Text_IO;
   use Ada.Streams;

   procedure Check (Condition : Boolean; What : String) is
   begin
      Checks := Checks + 1;
      if Condition then
         if Ada.Environment_Variables.Exists ("VERBOSE") then
            Put_Line ("pass: " & What);
         end if;
      else
         Failures := Failures + 1;
         Put_Line ("FAIL: " & What);
      end if;
   end Check;
   function Read_Line (Path : String) return String is
      F : File_Type;
   begin
      Open (F, In_File, Path);
      declare
         Line : constant String := Get_Line (F);
      begin
         Close (F);
         return Line;
      end;
   end Read_Line;
   procedure Reset_Capture is
   begin
      Capture_Last := 0;
   end Reset_Capture;
   procedure Take is
      Count : Natural;
   begin
      EVC_Core.Take_Outputs (Out_Buf, Out_Last);
      Count := Natural'Min (Out_Last, Capture'Last - Capture_Last);
      Capture (Capture_Last + 1 .. Capture_Last + Count) :=
        Out_Buf (1 .. Count);
      Capture_Last := Capture_Last + Count;
      Parsed := Parse;
      if Auto_Register then
         for N in 1 .. Radio_Outputs loop
            if Radio_Output (N).Request
              and then Radio_Output (N).Kind
                       = EVC_Ports.RTM_Request_T'Pos
                           (EVC_Ports.Request_Registration) + 1
            then
               Give_Radio_Event (Radio_Output (N).Session,
                                 EVC_Ports.Registered);
            end if;
         end loop;
      end if;
   end Take;
   function Digest (Data : Byte_Array) return String is
      Text : String (1 .. Data'Length);
   begin
      for I in Text'Range loop
         Text (I) := Character'Val (Data (Data'First + I - 1));
      end loop;
      return GNAT.SHA256.Digest (Text);
   end Digest;
   procedure Check_Digest (Name : String; Actual : String) is
      Path : constant String := Golden_Dir & Name & ".sha256";
   begin
      if Updating then
         Ada.Directories.Create_Path (Golden_Dir);
         declare
            F : File_Type;
         begin
            Create (F, Out_File, Path);
            Put_Line (F, Actual);
            Close (F);
         end;
         Put_Line ("recorded: " & Name);
         Checks := Checks + 1;
      elsif not Ada.Directories.Exists (Path) then
         Check (False, "golden missing: " & Name & " (run with UPDATE=1)");
      else
         Check (Read_Line (Path) = Actual, "golden " & Name);
      end if;
   end Check_Digest;
   procedure Check_Golden (Name : String) is
   begin
      if Ada.Environment_Variables.Exists ("EVC_DUMP") then
         declare
            package SIO renames Ada.Streams.Stream_IO;
            Dir  : constant String :=
              Ada.Environment_Variables.Value ("EVC_DUMP");
            F    : SIO.File_Type;
            Data : Stream_Element_Array
              (1 .. Stream_Element_Offset (Capture_Last));
         begin
            for I in Data'Range loop
               Data (I) := Stream_Element (Capture (Natural (I)));
            end loop;
            Ada.Directories.Create_Path (Dir);
            SIO.Create (F, SIO.Out_File, Dir & "/" & Name & ".bin");
            SIO.Write (F, Data);
            SIO.Close (F);
         end;
      end if;
      Check_Digest (Name, Digest (Capture (1 .. Capture_Last)));
   end Check_Golden;
   function Parse return Boolean is
      Pos    : Natural := 0;
      Length : Natural;
   begin
      Rec_Count := 0;
      while Pos < Out_Last loop
         if Out_Last - Pos < EVC_Outbox.Record_Header
           or else Natural (Out_Buf (Pos + 1)) > Port_T'Pos (Port_T'Last)
           or else Rec_Count = Recs'Last
         then
            return False;
         end if;
         Length := Natural (Out_Buf (Pos + 2))
                   + 256 * Natural (Out_Buf (Pos + 3));
         if Length > Out_Last - Pos - EVC_Outbox.Record_Header then
            return False;
         end if;
         Rec_Count := Rec_Count + 1;
         Recs (Rec_Count) :=
           (Port  => Port_T'Val (Out_Buf (Pos + 1)),
            First => Pos + 4,
            Last  => Pos + 3 + Length);
         Pos := Pos + 3 + Length;
      end loop;
      return True;
   end Parse;
   function Find_DMI (The_Type : Byte) return Natural is
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = DMI and then Rec_Length (I) >= 1
           and then Out_Buf (Recs (I).First) = The_Type
         then
            return I;
         end if;
      end loop;
      return 0;
   end Find_DMI;
   function Count_Port (Port : Port_T) return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = Port then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Port;
   function DMI_Mode_Byte return Natural is
      I : constant Natural := Find_DMI (EVC_DMI_Port.MSG_MODE_LEVEL);
   begin
      return (if I = 0 then 16#FFFF# else Byte_At (I, 6));
   end DMI_Mode_Byte;
   function DMI_Level_Byte return Natural is
      I : constant Natural := Find_DMI (EVC_DMI_Port.MSG_MODE_LEVEL);
   begin
      return (if I = 0 then 16#FFFF# else Byte_At (I, 7));
   end DMI_Level_Byte;
   function Onboard_Field (N : Positive) return Natural is
      I : constant Natural := Find_DMI (EVC_DMI_Port.MSG_ONBOARD);
   begin
      return (if I = 0 then 16#FFFF# else Byte_At (I, 5 + N));
   end Onboard_Field;
   procedure Input (Port : Port_T; Bytes : Byte_Array) is
   begin
      EVC_Core.Handle_Input (Port, Bytes);
   end Input;
   function U32 (V : Integer_64) return Byte_Array is
      U : constant Unsigned_64 := Unsigned_64 (Unsigned_32'Mod (V));
   begin
      return (EVC_Bytes.Byte_Of (U, 0), EVC_Bytes.Byte_Of (U, 1),
              EVC_Bytes.Byte_Of (U, 2), EVC_Bytes.Byte_Of (U, 3));
   end U32;
   function BTM_Payload (N_Bits : Natural; Extra : Integer := 0)
     return Byte_Array
   is
      Length : constant Natural := (N_Bits + 7) / 8 + Extra;
      Result : Byte_Array (1 .. 6 + Length) := (others => 16#A5#);
   begin
      Result (1 .. 4) := (0, 0, 0, 0);
      Result (5) := Byte (N_Bits mod 256);
      Result (6) := Byte (N_Bits / 256 mod 256);
      return Result;
   end BTM_Payload;
   function RTM_Payload (L_Message : Natural; Length : Natural)
     return Byte_Array
   is
      Result : Byte_Array (1 .. Length) := (others => 0);
   begin
      if Length >= 1 then
         Result (1) := 24;  -- NID_MESSAGE
      end if;
      if Length >= 3 then
         Result (2) := Byte (L_Message / 4 mod 256);
         Result (3) := Byte ((L_Message mod 4) * 64);
      end if;
      return Result;
   end RTM_Payload;
   function BTM_Of (Data  : Byte_Array;
                    Bits  : Natural;
                    Stamp : Integer_64 := 0) return Byte_Array
   is
      Length : constant Natural := (Bits + 7) / 8;
      Result : Byte_Array (1 .. 2 + Length) := (others => 0);
   begin
      Result (1) := Byte (Bits mod 256);
      Result (2) := Byte (Bits / 256);
      Result (3 .. 2 + Length) := Data (Data'First .. Data'First + Length - 1);
      return U32 (Stamp) & Result;
   end BTM_Of;
   procedure Put (W : in out Writer_T; P : T5.Packet_T) is
      OK : Boolean;
   begin
      T5.Encode (P, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put;
   procedure Put (W : in out Writer_T; P : T21.Packet_T) is
      OK : Boolean;
   begin
      T21.Encode (P, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put;
   procedure Put (W : in out Writer_T; P : T65.Packet_T) is
      OK : Boolean;
   begin
      T65.Encode (P, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put;
   procedure Put (W : in out Writer_T; P : R0.Packet_T) is
      OK : Boolean;
   begin
      R0.Encode (P, W, OK);
      Encodes_OK := Encodes_OK and then OK;
   end Put;
   procedure Add_Group (G : Group_Def) is
   begin
      Track_N := Track_N + 1;
      Track (Track_N) := G;
   end Add_Group;
   function Telegram_Of (G : Group_Def; K : Natural; Stamp : Integer_64)
     return Byte_Array
   is
      W  : Writer_T;
      OK : Boolean;
      H  : constant Tel.Header_T :=
        (Q_UPDOWN  => 1,
         M_VERSION => 48,
         Q_MEDIA   => 0,
         N_PIG     => ETCS_Variables.N_PIG_T (K),
         N_TOTAL   => ETCS_Variables.N_TOTAL_T (G.Balises - 1),
         M_DUP     => (if G.Dup_1_2 and then K = 0 then 1
                       elsif G.Dup_1_2 and then K = 1 then 2
                       else 0),
         M_MCOUNT  => 7,
         NID_C     => 123,
         NID_BG    => G.NID_BG,
         Q_LINK    => (if G.Linked then 1 else 0));
   begin
      Tel.Write_Header (W, H);
      if G.Has_Linking then
         Put (W, G.Linking);
      end if;
      if G.Has_Geo then
         T79.Encode (G.Geo, W, OK);
         Encodes_OK := Encodes_OK and then OK;
      end if;
      if G.Reposition then
         declare
            P : T16.Packet_T;
         begin
            P.Q_DIR := 2;
            P.Q_SCALE := 1;
            P.L_SECTION := 100;
            T16.Encode (P, W, OK);
            Encodes_OK := Encodes_OK and then OK;
         end;
      end if;
      Tel.Finish (W, Tel.Long_Bits, OK);
      Encodes_OK := Encodes_OK and then OK;
      return BTM_Of (ETCS_Bits.Data (W), ETCS_Bits.Position (W), Stamp);
   end Telegram_Of;
   procedure Forget is
   begin
      JRU_Seen := (others => 0);
      Seen := Pos.No_Triggers;
      Geo_Count := 0;
      Geo_Seen := EVC_DMI_Port.Geo_Unknown;
   end Forget;
   procedure Collect is
      T : constant Pos.Triggers_T := Pos.Report_Triggers;
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = JRU and then Byte_At (I, 1) <= 15 then
            JRU_Seen (Byte_At (I, 1)) := JRU_Seen (Byte_At (I, 1)) + 1;
            for B in 2 .. 4 loop
               JRU_Last (Byte_At (I, 1), B) := Byte_At (I, B);
            end loop;
         elsif Recs (I).Port = DMI and then Rec_Length (I) = 28
           and then Byte_At (I, 1) = Natural (EVC_DMI_Port.MSG_STATUS)
         then
            --  the frames of the geographical position: a position, or
            --  the first "unknown" after one (from E3 MSG_STATUS also
            --  comes when the brake indication or the time to Indication
            --  changes: those frames are not counted)
            declare
               Geo : constant Unsigned_32 :=
                 Unsigned_32 (Byte_At (I, 22))
                 + 256 * (Unsigned_32 (Byte_At (I, 23))
                          + 256 * (Unsigned_32 (Byte_At (I, 24))
                                   + 256 * Unsigned_32 (Byte_At (I, 25))));
            begin
               if Geo /= EVC_DMI_Port.Geo_Unknown
                 or else Geo_Seen /= EVC_DMI_Port.Geo_Unknown
               then
                  Geo_Count := Geo_Count + 1;
                  Geo_Seen := Geo;
               end if;
            end;
         end if;
      end loop;
      Seen :=
        (Standstill_Reached => Seen.Standstill_Reached
                               or else T.Standstill_Reached,
         Mode_Changed       => Seen.Mode_Changed or else T.Mode_Changed,
         Level_Changed      => Seen.Level_Changed or else T.Level_Changed,
         Standstill_Left    => Seen.Standstill_Left or else T.Standstill_Left,
         LRBG_Passed        => Seen.LRBG_Passed or else T.LRBG_Passed,
         Periodic_Time      => Seen.Periodic_Time or else T.Periodic_Time,
         Periodic_Distance  => Seen.Periodic_Distance
                               or else T.Periodic_Distance,
         Location_Passed    => Seen.Location_Passed
                               or else T.Location_Passed,
         Immediate          => Seen.Immediate or else T.Immediate);
   end Collect;
   procedure Sample (Moving : Integer) is
      V : constant Unsigned_16 := (if Moving = 0 then 0 else Speed_Cms);
   begin
      Input (Odometer,
             Odometer_Payload (Odo_D, Odo_Over, Odo_Under, V, V, V,
                               (if Moving > 0 then 1
                                elsif Moving < 0 then 2 else 0),
                               Cold_Byte, Cold_Distance));
   end Sample;
   procedure Cycle is
   begin
      EVC_Core.Tick (100);
      Take;
      Collect;
   end Cycle;
   procedure Start_Track (Start_Cm : Integer_64 := 0) is
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      Forget;
      Track_N := 0;
      Train_Cm := Start_Cm;
      Odo_D := Start_Cm;
      Odo_Over := 0;
      Odo_Under := 0;
      Error_Per_Mille := 0;
      Bound_Per_Mille := 20;
      Speed_Cms := 1000;
      Cold_Byte := 0;
      Cold_Distance := 0;
      Input (TIU, (1, 1));
      Sample (0);
      Cycle;
      EVC_Core.Set_Mode_For_Test (Legacy_Mode, L1);
   end Start_Track;
   procedure Step (Step_Cm : Integer_64) is
      Old_Train : constant Integer_64 := Train_Cm;
      Old_D     : constant Integer_64 := Odo_D;
      New_Train : constant Integer_64 := Train_Cm + Step_Cm;
      Measured  : constant Integer_64 :=
        Step_Cm * (1000 + Error_Per_Mille) / 1000;
      type Crossing is record
         At_Cm : Integer_64;
         G, K  : Natural;
      end record;
      List : array (1 .. 64) of Crossing;
      N    : Natural := 0;

      function Crossed (P : Integer_64) return Boolean is
        (if Step_Cm > 0 then P > Old_Train and then P <= New_Train
         else P < Old_Train and then P >= New_Train);
   begin
      for G in 1 .. Track_N loop
         for K in 0 .. Track (G).Balises - 1 loop
            if Track (G).Skip /= K + 1
              and then Crossed (Balise_At (Track (G), K))
            then
               N := N + 1;
               List (N) := (Balise_At (Track (G), K), G, K);
            end if;
         end loop;
      end loop;
      --  in the order of passing
      for I in 2 .. N loop
         for J in reverse 2 .. I loop
            if (Step_Cm > 0 and then List (J).At_Cm < List (J - 1).At_Cm)
              or else (Step_Cm < 0
                       and then List (J).At_Cm > List (J - 1).At_Cm)
            then
               declare
                  Swap : constant Crossing := List (J);
               begin
                  List (J) := List (J - 1);
                  List (J - 1) := Swap;
               end;
            end if;
         end loop;
      end loop;
      for I in 1 .. N loop
         Input (BTM, Telegram_Of
                       (Track (List (I).G), List (I).K,
                        Old_D + (List (I).At_Cm - Old_Train) * Measured
                                / Step_Cm));
      end loop;
      Train_Cm := New_Train;
      Odo_D := Odo_D + Measured;
      Odo_Over := Odo_Over + abs Measured * Bound_Per_Mille / 1000;
      Odo_Under := Odo_Under + abs Measured * Bound_Per_Mille / 1000;
      Sample ((if Step_Cm > 0 then 1 elsif Step_Cm < 0 then -1 else 0));
      Cycle;
   end Step;
   procedure Run_To (To_Cm : Integer_64; Step_Cm : Integer_64 := 1000) is
   begin
      while Train_Cm /= To_Cm loop
         Step (if To_Cm > Train_Cm
               then Integer_64'Min (Step_Cm, To_Cm - Train_Cm)
               else -Integer_64'Min (Step_Cm, Train_Cm - To_Cm));
      end loop;
   end Run_To;
   procedure Stand is
   begin
      Sample (0);
      Cycle;
   end Stand;
   function Link_To (D_Links  : Nat_List;
                     NIDs     : Nat_List;
                     Locacc   : Natural := 5;
                     Reaction : Natural := 1;
                     Nominal  : Boolean := True) return T5.Packet_T
   is
      L : T5.Packet_T;
   begin
      L.Q_DIR := 1;
      L.Q_SCALE := 1;
      L.D_LINK := ETCS_Variables.D_LINK_T (D_Links (D_Links'First));
      L.NID_BG := ETCS_Variables.NID_BG_T (NIDs (NIDs'First));
      L.Q_LINKORIENTATION := (if Nominal then 1 else 0);
      L.Q_LINKREACTION := ETCS_Variables.Q_LINKREACTION_T (Reaction);
      L.Q_LOCACC := ETCS_Variables.Q_LOCACC_T (Locacc);
      L.N_ITER := ETCS_Variables.N_ITER_T (D_Links'Length - 1);
      for I in 1 .. D_Links'Length - 1 loop
         L.D_LINK_List (I).D_LINK :=
           ETCS_Variables.D_LINK_T (D_Links (D_Links'First + I));
         L.D_LINK_List (I).NID_BG :=
           ETCS_Variables.NID_BG_T (NIDs (NIDs'First + I));
         L.D_LINK_List (I).Q_LINKORIENTATION := (if Nominal then 1 else 0);
         L.D_LINK_List (I).Q_LINKREACTION :=
           ETCS_Variables.Q_LINKREACTION_T (Reaction);
         L.D_LINK_List (I).Q_LOCACC := ETCS_Variables.Q_LOCACC_T (Locacc);
      end loop;
      return L;
   end Link_To;
   function Group (NID : Natural; At_M : Integer_64;
                   Balises : Positive := 2) return Group_Def
   is
      G : Group_Def;
   begin
      G.NID_BG := ETCS_Variables.NID_BG_T (NID);
      G.At_Cm := At_M * 100;
      G.Balises := Balises;
      return G;
   end Group;
   function With_Links (G : Group_Def; L : T5.Packet_T) return Group_Def is
      R : Group_Def := G;
   begin
      R.Has_Linking := True;
      R.Linking := L;
      return R;
   end With_Links;
   function Round_Trip (P : R0.Packet_T) return Boolean is
      W  : Writer_T;
      R  : Reader_T;
      D  : R0.Packet_T;
      OK : Boolean;
      E  : R0.Packet_T := P;
   begin
      R0.Encode (P, W, OK);
      if not OK then
         return False;
      end if;
      ETCS_Bits.Load (R, ETCS_Bits.Data (W), ETCS_Bits.Position (W));
      R0.Decode (R, D, OK);
      E.L_PACKET := D.L_PACKET;
      return OK and then D = E;
   end Round_Trip;
   function Round_Trip (P : R1.Packet_T) return Boolean is
      W  : Writer_T;
      R  : Reader_T;
      D  : R1.Packet_T;
      OK : Boolean;
      E  : R1.Packet_T := P;
   begin
      R1.Encode (P, W, OK);
      if not OK then
         return False;
      end if;
      ETCS_Bits.Load (R, ETCS_Bits.Data (W), ETCS_Bits.Position (W));
      R1.Decode (R, D, OK);
      E.L_PACKET := D.L_PACKET;
      return OK and then D = E;
   end Round_Trip;
   procedure Carry_Writer (G : Positive; K : Natural; W : Writer_T) is
      Acc : Writer_T;
   begin
      if Extras (G, K).Bits > 0 then
         ETCS_Bits.Write_Bytes (Acc, Extras (G, K).Bits, Extras (G, K).Data);
      end if;
      ETCS_Bits.Write_Bytes (Acc, ETCS_Bits.Position (W), ETCS_Bits.Data (W));
      Encodes_OK := Encodes_OK and then not ETCS_Bits.Failed (Acc)
                    and then ETCS_Bits.Position (Acc) <= 772;
      declare
         D : constant Byte_Array := ETCS_Bits.Data (Acc);
      begin
         Extras (G, K).Bits := ETCS_Bits.Position (Acc);
         Extras (G, K).Data := (others => 0);
         Extras (G, K).Data (1 .. D'Length) := D;
      end;
   end Carry_Writer;
   procedure Finish_Carry (G : Positive; K : Natural; W : Writer_T;
                           OK : Boolean) is
   begin
      Encodes_OK := Encodes_OK and then OK;
      Carry_Writer (G, K, W);
   end Finish_Carry;
   procedure Carry (G : Positive; K : Natural; P : T3.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T3.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T12.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T12.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T21.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T21.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T27.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T27.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T39.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T39.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T51.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T51.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T52.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T52.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T65.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T65.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T66.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T66.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T67.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T67.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T68.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T68.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T70.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T70.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T71.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T71.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T80.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T80.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T88.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T88.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : T141.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      T141.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : TP41.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      TP41.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   procedure Carry (G : Positive; K : Natural; P : TP46.Packet_T) is
      W : Writer_T; OK : Boolean;
   begin
      TP46.Encode (P, W, OK);
      Finish_Carry (G, K, W, OK);
   end Carry;
   function Telegram_X (G : Positive; K : Natural; Stamp : Integer_64)
     return Byte_Array
   is
      D  : constant Group_Def := Track (G);
      W  : Writer_T;
      OK : Boolean;
      H  : constant Tel.Header_T :=
        (Q_UPDOWN  => 1,
         M_VERSION => 48,
         Q_MEDIA   => 0,
         N_PIG     => ETCS_Variables.N_PIG_T (K),
         N_TOTAL   => ETCS_Variables.N_TOTAL_T (D.Balises - 1),
         M_DUP     => 0,
         M_MCOUNT  => 7,
         NID_C     => Country (G),
         NID_BG    => D.NID_BG,
         Q_LINK    => (if D.Linked then 1 else 0));
   begin
      Tel.Write_Header (W, H);
      if D.Has_Linking then
         Put (W, D.Linking);
      end if;
      if K <= 1 and then Extras (G, K).Bits > 0 then
         ETCS_Bits.Write_Bytes (W, Extras (G, K).Bits, Extras (G, K).Data);
      end if;
      Tel.Finish (W, Tel.Long_Bits, OK);
      Encodes_OK := Encodes_OK and then OK;
      return BTM_Of (ETCS_Bits.Data (W), ETCS_Bits.Position (W), Stamp);
   end Telegram_X;
   procedure Collect_E3 is
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = DMI and then Rec_Length (I) > 5
           and then Byte_At (I, 1) = Natural (EVC_DMI_Port.MSG_TRACK_COND)
         then
            TC_Length := Rec_Length (I) - 5;
            for N in 1 .. Natural'Min (TC_Length, TC_Payload'Length) loop
               TC_Payload (N) := Byte (Byte_At (I, 5 + N));
            end loop;
            TC_Frames := TC_Frames + 1;
         elsif Recs (I).Port = DMI and then Rec_Length (I) > 5
           and then Byte_At (I, 1) = Natural (EVC_DMI_Port.MSG_PLANNING)
         then
            Plan_Length := Rec_Length (I) - 5;
            for N in 1 .. Natural'Min (Plan_Length, Plan_Payload'Length) loop
               Plan_Payload (N) := Byte (Byte_At (I, 5 + N));
            end loop;
            Plan_Frames := Plan_Frames + 1;
         elsif Recs (I).Port = JRU
           and then Byte_At (I, 1) = SI.JRU_Event
           and then Byte_At (I, 2) <= 17 and then Byte_At (I, 3) <= 15
         then
            SI_Seen (Byte_At (I, 2), Byte_At (I, 3)) :=
              SI_Seen (Byte_At (I, 2), Byte_At (I, 3)) + 1;
            SI_Detail (Byte_At (I, 2), Byte_At (I, 3)) := Byte_At (I, 4);
         end if;
      end loop;
   end Collect_E3;
   procedure Collect_E4 is
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = JRU and then Byte_At (I, 1) in 40 .. 41
           and then Byte_At (I, 2) <= 15
         then
            E4_Seen (Byte_At (I, 1), Byte_At (I, 2)) :=
              E4_Seen (Byte_At (I, 1), Byte_At (I, 2)) + 1;
            E4_B3 (Byte_At (I, 1), Byte_At (I, 2)) := Byte_At (I, 3);
            E4_B4 (Byte_At (I, 1), Byte_At (I, 2)) := Byte_At (I, 4);
         elsif Recs (I).Port = JRU and then Byte_At (I, 1) = 11
           and then Byte_At (I, 2) <= 63
         then
            JRU_Actions (Byte_At (I, 2)) := JRU_Actions (Byte_At (I, 2)) + 1;
         elsif Recs (I).Port = JRU and then Byte_At (I, 1) = 38 then
            JRU_Cabs := JRU_Cabs + 1;
            JRU_Cab_Last := Byte_At (I, 2) + 2 * Byte_At (I, 4);
         elsif Recs (I).Port = JRU and then Byte_At (I, 1) = 45
           and then Byte_At (I, 2) <= 15
         then
            JRU_TCs (Byte_At (I, 2)) := JRU_TCs (Byte_At (I, 2)) + 1;
            JRU_TC_Phase (Byte_At (I, 2)) := Byte_At (I, 3);
         elsif Recs (I).Port = DMI and then Rec_Length (I) = 7
           and then Byte_At (I, 1) = 16#0C# and then Byte_At (I, 6) <= 63
           and then Byte_At (I, 7) = 0
         then
            SS_Seen (Byte_At (I, 6)) := SS_Seen (Byte_At (I, 6)) + 1;
         elsif Recs (I).Port = DMI and then Rec_Length (I) = 7
           and then Byte_At (I, 1) = 16#0C# and then Byte_At (I, 6) <= 63
           and then Byte_At (I, 7) = 1
         then
            SS_Ended (Byte_At (I, 6)) := SS_Ended (Byte_At (I, 6)) + 1;
         elsif Recs (I).Port = DMI and then Rec_Length (I) = 28
           and then Byte_At (I, 1) = Natural (EVC_DMI_Port.MSG_STATUS)
         then
            Last_Brake := Byte_At (I, 6);
         elsif Recs (I).Port = TIU
           and then Rec_Length (I) = EVC_Ports.TIU_Output_Length
           and then Byte_At (I, 1) /= Natural (EVC_Ports.TIU_TC_Tag)
         then
            Last_TIU := Byte_At (I, 1)
                        + 256 * (Byte_At (I, 2) + 256 * Byte_At (I, 3));
         end if;
      end loop;
   end Collect_E4;
   procedure Cycle_X is
   begin
      Cycle;
      Collect_E3;
      Collect_E4;
   end Cycle_X;
   procedure Feed_X (Step_Cm : Integer_64) is
      Old_Train : constant Integer_64 := Train_Cm;
      Old_D     : constant Integer_64 := Odo_D;
      New_Train : constant Integer_64 := Train_Cm + Step_Cm;
      Measured  : constant Integer_64 :=
        Step_Cm * (1000 + Error_Per_Mille) / 1000;
      type Crossing is record
         At_Cm : Integer_64;
         G, K  : Natural;
      end record;
      List : array (1 .. 64) of Crossing;
      N    : Natural := 0;

      function Crossed (P : Integer_64) return Boolean is
        (if Step_Cm > 0 then P > Old_Train and then P <= New_Train
         else P < Old_Train and then P >= New_Train);
   begin
      for G in 1 .. Track_N loop
         for K in 0 .. Track (G).Balises - 1 loop
            if Crossed (Balise_At (Track (G), K)) then
               N := N + 1;
               List (N) := (Balise_At (Track (G), K), G, K);
            end if;
         end loop;
      end loop;
      for I in 2 .. N loop
         for J in reverse 2 .. I loop
            if (Step_Cm > 0 and then List (J).At_Cm < List (J - 1).At_Cm)
              or else (Step_Cm < 0
                       and then List (J).At_Cm > List (J - 1).At_Cm)
            then
               declare
                  Swap : constant Crossing := List (J);
               begin
                  List (J) := List (J - 1);
                  List (J - 1) := Swap;
               end;
            end if;
         end loop;
      end loop;
      for I in 1 .. N loop
         Input (BTM, Telegram_X
                       (List (I).G, List (I).K,
                        Old_D + (List (I).At_Cm - Old_Train) * Measured
                                / Step_Cm));
      end loop;
      Train_Cm := New_Train;
      Odo_D := Odo_D + Measured;
      Odo_Over := Odo_Over + abs Measured * Bound_Per_Mille / 1000;
      Odo_Under := Odo_Under + abs Measured * Bound_Per_Mille / 1000;
   end Feed_X;
   procedure Step_X (Step_Cm : Integer_64) is
   begin
      Feed_X (Step_Cm);
      Sample ((if Step_Cm > 0 then 1 elsif Step_Cm < 0 then -1 else 0));
      Cycle_X;
   end Step_X;
   procedure Run_X (To_Cm : Integer_64; Step_Cm : Integer_64 := 1000) is
   begin
      while Train_Cm /= To_Cm loop
         Step_X (if To_Cm > Train_Cm
                 then Integer_64'Min (Step_Cm, To_Cm - Train_Cm)
                 else -Integer_64'Min (Step_Cm, Train_Cm - To_Cm));
      end loop;
   end Run_X;
   procedure Stand_X (Ms : Natural) is
   begin
      for I in 1 .. Ms / 100 loop
         Sample (0);
         Cycle_X;
      end loop;
   end Stand_X;
   procedure Start_X (Start_Cm : Integer_64 := 0) is
   begin
      Start_Track (Start_Cm);
      Extras := (others => (others => <>));
      Country := (others => 123);
      TC_Length := 0;
      TC_Frames := 0;
      Plan_Length := 0;
      Plan_Frames := 0;
      SI_Seen := (others => (others => 0));
      SI_Detail := (others => (others => 0));
   end Start_X;
   function SSP (L : Profile_List) return T27.Packet_T is
      P : T27.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_STATIC := ETCS_Variables.D_STATIC_T (L (L'First).D_M);
      P.V_STATIC := V_Static (L (L'First).Value);
      P.Q_FRONT := (if L (L'First).Delay_Length then 0 else 1);
      P.N_ITER := 0;
      P.N_ITER_2 := ETCS_Variables.N_ITER_T (L'Length - 1);
      for I in 1 .. L'Length - 1 loop
         P.D_STATIC_List (I).D_STATIC :=
           ETCS_Variables.D_STATIC_T (L (L'First + I).D_M);
         P.D_STATIC_List (I).V_STATIC := V_Static (L (L'First + I).Value);
         P.D_STATIC_List (I).Q_FRONT :=
           (if L (L'First + I).Delay_Length then 0 else 1);
      end loop;
      return P;
   end SSP;
   function Grad (L : Grad_List) return T21.Packet_T is
      P : T21.Packet_T;

      procedure Set (V : Integer; Q : out ETCS_Variables.Q_GDIR_T;
                     G : out ETCS_Variables.G_A_T) is
      begin
         if V = End_Mark then
            Q := 1;
            G := 255;
         else
            Q := (if V >= 0 then 1 else 0);
            G := ETCS_Variables.G_A_T (abs V);
         end if;
      end Set;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_GRADIENT := ETCS_Variables.D_GRADIENT_T (L (L'First).D_M);
      Set (L (L'First).Value, P.Q_GDIR, P.G_A);
      P.N_ITER := ETCS_Variables.N_ITER_T (L'Length - 1);
      for I in 1 .. L'Length - 1 loop
         P.D_GRADIENT_List (I).D_GRADIENT :=
           ETCS_Variables.D_GRADIENT_T (L (L'First + I).D_M);
         Set (L (L'First + I).Value, P.D_GRADIENT_List (I).Q_GDIR,
              P.D_GRADIENT_List (I).G_A);
      end loop;
      return P;
   end Grad;
   function MA_Of (Lengths : Nat_List; V_Main_Kmh : Natural := 120)
     return T12.Packet_T
   is
      P : T12.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.V_MAIN := ETCS_Variables.V_MAIN_T (V_Main_Kmh / 5);
      P.V_EMA := 0;
      P.T_EMA := 1023;
      P.N_ITER := ETCS_Variables.N_ITER_T (Lengths'Length - 1);
      for I in 1 .. Lengths'Length - 1 loop
         P.L_SECTION_List (I).L_SECTION :=
           ETCS_Variables.L_SECTION_T (Lengths (Lengths'First + I - 1));
      end loop;
      P.L_ENDSECTION :=
        ETCS_Variables.L_ENDSECTION_T (Lengths (Lengths'Last));
      return P;
   end MA_Of;
   function MRSP_Is (Starts : I64_List; Speeds : Nat_List) return Boolean
   is
      M : constant SIn.Speed_Profile_T := SI.Current.MRSP;
   begin
      if M.Count /= Starts'Length then
         return False;
      end if;
      for K in 1 .. M.Count loop
         if (K > 1 and then Integer_64 (M.Segments (K).Start)
                              /= Starts (Starts'First + K - 1))
           or else M.Segments (K).Speed /= Speeds (Speeds'First + K - 1)
         then
            return False;
         end if;
      end loop;
      return True;
   end MRSP_Is;
   function MRSP_Below_Sources return Boolean is
      P : constant Prof.Steps_T := SI.MRSP_Steps;
      E : constant Prof.Elements_T := SI.MRSP_Sources;
   begin
      return Prof.Sorted (P)
        and then Prof.Below (P, E, 0, SI.MRSP_Ceiling)
        and then SI.Envelope_Failures = 0;
   end MRSP_Below_Sources;
   function TC_Shows (Kind : Natural) return Boolean is
   begin
      if TC_Length = 0 then
         return False;
      end if;
      for I in 1 .. Natural (TC_Payload (1)) loop
         if 1 + 2 * I <= TC_Length
           and then Natural (TC_Payload (1 + 2 * I)) = Kind
         then
            return True;
         end if;
      end loop;
      return False;
   end TC_Shows;
   function Img_LF (X : LF) return String is
      Scaled : constant Integer_64 := Integer_64 (LF'Rounding (X * 100.0));
      Sign   : constant String := (if Scaled < 0 then "-" else "");
      A      : constant Integer_64 := abs Scaled;
      Frac   : constant String := Integer_64'Image (100 + A mod 100);
   begin
      return Sign & Integer_64'Image (A / 100) & "." & Frac (3 .. 4);
   end Img_LF;
   function Base_Snapshot return SIn.Snapshot_T is
      S : SIn.Snapshot_T;
   begin
      S.Supervise := True;
      S.Train := (Position_Valid   => True,
                  Ahead            => EVC_Distances.Plus,
                  Est_Front        => 0,
                  Max_Safe_Front   => 0,
                  Min_Safe_Front   => 0,
                  Speed            => 0,
                  Speed_Max        => 0,
                  Standstill       => True,
                  Moving_Ahead     => False,
                  Moving_Backwards => False);
      S.Train_Data.Length := 40_000;
      S.Train_Data.Max_Speed := Cms (140.0);
      S.Train_Data.Model := SIn.Lambda;
      S.Train_Data.Brake_Percentage := 135;
      S.Train_Data.Brake_Position := SIn.Passenger_P;
      S.Train_Data.T_Traction_Cut_Off := 1_000;
      S.National.Q_NVSBTSMPERM := True;
      S.National.Q_NVEMRRLS := False;
      S.National.Q_NVGUIPERM := False;
      S.National.Q_NVSBFBPERM := False;
      S.National.Q_NVINHSMICPERM := False;
      S.National.V_NVREL := Cms (40.0);
      S.National.D_NVROLL := 200;
      S.National.M_NVAVADH := 0;
      S.National.M_NVEBCL := 9;
      S.National.A_NVMAXREDADH1 := 1_000;
      S.National.A_NVMAXREDADH2 := 700;
      S.National.A_NVMAXREDADH3 := 700;
      S.National.Kt_Int := 1_100;
      S.MRSP.Count := 1;
      S.MRSP.Segments (1) := (Start => 0, Speed => Cms (140.0));
      return S;
   end Base_Snapshot;
   procedure Place (S     : in out SIn.Snapshot_T;
                    At_Cm : Integer_64;
                    V     : SIn.Speed_Cms_T;
                    Doubt : Integer_64 := 1_000) is
   begin
      S.Train.Est_Front := EVC_Distances.Cm_T (At_Cm);
      S.Train.Max_Safe_Front := EVC_Distances.Cm_T (At_Cm + Doubt);
      S.Train.Min_Safe_Front := EVC_Distances.Cm_T (At_Cm - Doubt);
      S.Train.Speed := V;
      S.Train.Speed_Max := V;
      S.Train.Standstill := V = 0;
      S.Train.Moving_Ahead := V > 0;
      S.Train.Moving_Backwards := False;
   end Place;
   procedure Give_MA (S       : in out SIn.Snapshot_T;
                      EOA_M   : Natural;
                      Over_M  : Natural := 0;
                      Release : SIn.Release_Speed_Kind_T := SIn.None;
                      V_Rel   : SIn.Speed_Cms_T := 0;
                      LOA_Kmh : LF := 0.0) is
   begin
      S.MA := (Present       => True,
               EOA           => EVC_Distances.Metres (EOA_M),
               SvL           => EVC_Distances.Metres (EOA_M + Over_M),
               LOA_Speed     => (if LOA_Kmh > 0.0 then Cms (LOA_Kmh) else 0),
               Release_Speed => (Kind => Release, Speed => V_Rel));
   end Give_MA;
   procedure R_Add (F : in out R_Fn; Upper, Value : LF) is
   begin
      F.Count := F.Count + 1;
      F.S (F.Count) := (Upper, Value);
   end R_Add;
   function R_Eval (F : R_Fn; V : LF; Rising : Boolean) return LF is
   begin
      if F.Count = 0 then
         return 0.0;
      end if;
      for K in 1 .. F.Count - 1 loop
         if (if Rising then V < F.S (K).Upper else V <= F.S (K).Upper) then
            return F.S (K).Value;
         end if;
      end loop;
      return F.S (F.Count).Value;
   end R_Eval;
   function R_Basic (Lambda_O : Natural) return R_Fn is
      use Ada.Numerics.Long_Elementary_Functions;
      L    : constant LF := LF (Lambda_O);
      V_Lim : constant LF := 16.85 * L ** 0.428 * 250.0 / 9.0;
      type Coefs is array (0 .. 3) of LF;
      C    : constant array (1 .. 5) of Coefs :=
        ((0.0663, 4.72E-03, 6.10E-05, -6.30E-07),
         (0.1300, 5.14E-03, -4.54E-06, 2.73E-07),
         (0.0479, 5.81E-03, -6.76E-06, 5.58E-08),
         (0.0480, 5.52E-03, -3.85E-06, 3.00E-08),
         (0.0559, 5.06E-03, 1.66E-06, 3.23E-09));
      Lim  : constant array (1 .. 4) of LF := (100.0, 120.0, 150.0, 180.0);
      F    : R_Fn;
   begin
      R_Add (F, V_Lim, (0.0075 * L + 0.076) * 1000.0);
      for N in 1 .. 5 loop
         declare
            AD : constant LF :=
              (C (N) (0) + C (N) (1) * L + C (N) (2) * L * L
               + C (N) (3) * L * L * L) * 1000.0;
         begin
            if N = 5 then
               R_Add (F, R_Inf, AD);
            elsif Lim (N) * 250.0 / 9.0 > V_Lim then
               R_Add (F, Lim (N) * 250.0 / 9.0, AD);
            end if;
         end;
      end loop;
      return F;
   end R_Basic;
   function R_Curve_Of (C : SIn.Decel_Curve_T) return R_Fn is
      F : R_Fn;
   begin
      for K in 1 .. C.Count loop
         R_Add (F, (if K < C.Count then LF (C.Steps (K).Speed) else R_Inf),
                LF (C.Steps (K).Decel));
      end loop;
      return F;
   end R_Curve_Of;
   function R_Model (S : SIn.Snapshot_T) return R_Model_T is
      M : R_Model_T;
      T : SIn.Train_Data_T renames S.Train_Data;
   begin
      M.Up := (if S.Extra.Train.M_Rotating_Nom > 0
               then LF (S.Extra.Train.M_Rotating_Nom) else 15.0);
      M.Down := (if S.Extra.Train.M_Rotating_Nom > 0
                 then LF (S.Extra.Train.M_Rotating_Nom) else 2.0);
      M.Kn_Plus := R_Curve_Of (S.Extra.Train.Kn_Plus);
      M.Kn_Minus := R_Curve_Of (S.Extra.Train.Kn_Minus);
      M.Normal := R_Curve_Of (T.A_Brake_Normal);
      if T.Model = SIn.Lambda then
         M.Lambda := True;
         M.Safe := R_Basic (T.Brake_Percentage);
         M.Service := R_Basic (Integer'Min (T.Brake_Percentage, 135));
         declare
            Set : constant SIn.Kv_Set_T := S.National.Kv_Int_Fresh;
         begin
            if Set.Count = 0 then
               R_Add (M.Kv, R_Inf, 0.7);
            else
               for K in 1 .. Set.Count loop
                  R_Add (M.Kv, (if K < Set.Count
                                then LF (Set.Steps (K + 1).Speed)
                                else R_Inf),
                         LF (Set.Steps (K).Factor) / 1000.0);
               end loop;
            end if;
         end;
         M.Kr := (if S.National.Kr_Int.Count = 0 then 0.9
                  else LF (S.National.Kr_Int.Steps (1).Factor) / 1000.0);
      else
         M.Lambda := False;
         M.Safe := R_Curve_Of (T.A_Brake_Emergency);
         M.Service := R_Curve_Of (T.A_Brake_Service);
         for K in 1 .. T.A_Brake_Emergency.Count loop
            R_Add (M.Kdry, M.Safe.S (K).Upper,
                   LF (S.Extra.Train.Kdry_Rst (S.National.M_NVEBCL) (K))
                   / 1000.0);
            R_Add (M.Kwet, M.Safe.S (K).Upper,
                   LF (S.Extra.Train.Kwet_Rst (K)) / 1000.0);
         end loop;
         M.Avadh := LF (S.National.M_NVAVADH) / 1000.0;
      end if;
      return M;
   end R_Model;
   function R_Profile (S : SIn.Snapshot_T; M : R_Model_T) return R_Profile_T
   is
      P    : R_Profile_T;
      L    : constant LF := LF (S.Train_Data.Length);
      N    : constant Natural := S.Gradients.Count;
      Cand : array (1 .. 2 * SIn.Max_Gradient_Segments + 1) of LF;
      NC   : Natural := 0;

      function G_Start (K : Positive) return LF is
        (LF (S.Gradients.Segments (K).Start));

      function Lowest (Lo, Hi : LF) return LF is
         R : LF := 1000.0;
      begin
         if N = 0 or else Lo - L < G_Start (1) then
            R := 0.0;
         end if;
         for K in 1 .. N loop
            if G_Start (K) < Hi
              and then (K = N or else G_Start (K + 1) > Lo - L)
            then
               R := LF'Min (R, LF (S.Gradients.Segments (K).Gradient));
            end if;
         end loop;
         return R;
      end Lowest;
   begin
      for K in 1 .. N loop
         NC := NC + 1;
         Cand (NC) := G_Start (K);
         NC := NC + 1;
         Cand (NC) := G_Start (K) + L;
      end loop;
      for I in 2 .. NC loop
         for J in reverse 2 .. I loop
            exit when Cand (J - 1) <= Cand (J);
            declare
               X : constant LF := Cand (J);
            begin
               Cand (J) := Cand (J - 1);
               Cand (J - 1) := X;
            end;
         end loop;
      end loop;
      P.Count := 1;
      P.Points (1).Start := -R_Inf;
      for I in 1 .. NC loop
         if Cand (I) > P.Points (P.Count).Start then
            P.Count := P.Count + 1;
            P.Points (P.Count).Start := Cand (I);
         end if;
      end loop;
      for I in 1 .. P.Count loop
         declare
            Hi : constant LF :=
              (if I < P.Count then P.Points (I + 1).Start else R_Inf);
            G  : constant LF := Lowest (P.Points (I).Start, Hi);
         begin
            P.Points (I).Gradient := G;
            P.Points (I).A_Grad :=
              9810.0 * G / (1000.0 + 10.0 * (if G > 0.0 then M.Up
                                              else M.Down));
         end;
      end loop;
      return P;
   end R_Profile;
   function R_Accel (M : R_Model_T; P : R_Profile_T; K : R_Kind;
                     Seg : Positive; V : LF; Rising : Boolean) return LF
   is
      G : constant LF := P.Points (Seg).Gradient;
   begin
      case K is
         when R_EBD =>
            return R_Safe (M, V, Rising) + P.Points (Seg).A_Grad;
         when R_SBD =>
            return R_Eval (M.Service, V, Rising) + P.Points (Seg).A_Grad;
         when R_GUI =>
            return R_Eval (M.Normal, V, Rising) + P.Points (Seg).A_Grad
              - R_Eval ((if G > 0.0 then M.Kn_Plus else M.Kn_Minus),
                        V, Rising) * G / 1000.0;
      end case;
   end R_Accel;
   function R_Next_Up (M : R_Model_T; V : LF) return LF is
      R : LF := R_Inf;

      procedure Look (F : R_Fn) is
      begin
         for K in 1 .. F.Count - 1 loop
            if F.S (K).Upper > V then
               R := LF'Min (R, F.S (K).Upper);
            end if;
         end loop;
      end Look;
   begin
      Look (M.Safe);
      Look (M.Service);
      Look (M.Normal);
      Look (M.Kv);
      Look (M.Kdry);
      Look (M.Kwet);
      Look (M.Kn_Plus);
      Look (M.Kn_Minus);
      return R;
   end R_Next_Up;
   function R_Next_Down (M : R_Model_T; V : LF) return LF is
      R : LF := 0.0;

      procedure Look (F : R_Fn) is
      begin
         for K in 1 .. F.Count - 1 loop
            if F.S (K).Upper < V then
               R := LF'Max (R, F.S (K).Upper);
            end if;
         end loop;
      end Look;
   begin
      Look (M.Safe);
      Look (M.Service);
      Look (M.Normal);
      Look (M.Kv);
      Look (M.Kdry);
      Look (M.Kwet);
      Look (M.Kn_Plus);
      Look (M.Kn_Minus);
      return R;
   end R_Next_Down;
   function R_Segment (P : R_Profile_T; X : LF) return Positive is
   begin
      for I in reverse 2 .. P.Count loop
         if P.Points (I).Start <= X then
            return I;
         end if;
      end loop;
      return 1;
   end R_Segment;
   function R_Segment_Below (P : R_Profile_T; X : LF) return Positive is
   begin
      for I in reverse 2 .. P.Count loop
         if P.Points (I).Start < X then
            return I;
         end if;
      end loop;
      return 1;
   end R_Segment_Below;
   procedure R_Back (M : R_Model_T; P : R_Profile_T; C : R_Curve;
                     X_Goal, V_Goal : LF; X, V : out LF) is
      use Ada.Numerics.Long_Elementary_Functions;
      Vh   : LF := C.Anchor_V;
      W    : LF := C.Anchor_V ** 2;
      W_G  : constant LF := V_Goal ** 2;
      Here : LF := C.Anchor;
   begin
      for Iteration in 1 .. 100_000 loop
         exit when W >= W_G or else Here <= X_Goal;
         declare
            Seg : constant Positive := R_Segment_Below (P, Here);
            Lo  : constant LF := LF'Max (P.Points (Seg).Start, X_Goal);
            A_U : constant LF := R_Accel (M, P, C.Kind, Seg, Vh, True);
            A_D : constant LF := R_Accel (M, P, C.Kind, Seg, Vh, False);
         begin
            if A_U > 0.0 then
               declare
                  Top_V : constant LF := LF'Min (R_Next_Up (M, Vh), V_Goal);
                  Need  : constant LF := (Top_V ** 2 - W) * 5.0 / A_U;
               begin
                  if Here - Need > Lo then
                     Here := Here - Need;
                     W := Top_V ** 2;
                     Vh := Top_V;
                  else
                     W := W + A_U * (Here - Lo) / 5.0;
                     Vh := Sqrt (W);
                     Here := Lo;
                  end if;
               end;
            elsif A_D < 0.0 and then W > 0.0 then
               declare
                  Bottom_V : constant LF := R_Next_Down (M, Vh);
                  Need     : constant LF :=
                    (W - Bottom_V ** 2) * 5.0 / (-A_D);
               begin
                  if Here - Need > Lo then
                     Here := Here - Need;
                     W := Bottom_V ** 2;
                     Vh := Bottom_V;
                  else
                     W := LF'Max (W + A_D * (Here - Lo) / 5.0,
                                  Bottom_V ** 2);
                     Vh := Sqrt (W);
                     Here := Lo;
                  end if;
               end;
            else
               Here := Lo;
            end if;
         end;
      end loop;
      X := Here;
      V := Vh;
   end R_Back;
   procedure R_Forward (M : R_Model_T; P : R_Profile_T; C : R_Curve;
                        X_Goal, V_Goal : LF; X, V : out LF) is
      use Ada.Numerics.Long_Elementary_Functions;
      Vh   : LF := C.Anchor_V;
      W    : LF := C.Anchor_V ** 2;
      W_G  : constant LF := V_Goal ** 2;
      Here : LF := C.Anchor;
   begin
      for Iteration in 1 .. 100_000 loop
         exit when W <= W_G or else Here >= X_Goal;
         declare
            Seg : Positive := R_Segment (P, Here);
         begin
            if Seg < P.Count and then Here >= P.Points (Seg + 1).Start then
               Seg := Seg + 1;
            end if;
            declare
               Hi  : constant LF :=
                 LF'Min ((if Seg < P.Count then P.Points (Seg + 1).Start
                          else R_Inf), X_Goal);
               A_U : constant LF := R_Accel (M, P, C.Kind, Seg, Vh, True);
               A_D : constant LF := R_Accel (M, P, C.Kind, Seg, Vh, False);
            begin
               if A_D > 0.0 then
                  declare
                     Bottom_V : constant LF :=
                       LF'Max (R_Next_Down (M, Vh), V_Goal);
                     Need     : constant LF :=
                       (W - Bottom_V ** 2) * 5.0 / A_D;
                  begin
                     if Here + Need < Hi then
                        Here := Here + Need;
                        W := Bottom_V ** 2;
                        Vh := Bottom_V;
                     else
                        W := LF'Max (W - A_D * (Hi - Here) / 5.0,
                                     Bottom_V ** 2);
                        Vh := Sqrt (W);
                        Here := Hi;
                     end if;
                  end;
               elsif A_U < 0.0 then
                  declare
                     Top_V : constant LF := R_Next_Up (M, Vh);
                     Need  : constant LF := (Top_V ** 2 - W) * 5.0 / (-A_U);
                  begin
                     if Here + Need < Hi then
                        Here := Here + Need;
                        W := Top_V ** 2;
                        Vh := Top_V;
                     else
                        W := LF'Min (W - A_U * (Hi - Here) / 5.0,
                                     Top_V ** 2);
                        Vh := Sqrt (W);
                        Here := Hi;
                     end if;
                  end;
               else
                  Here := Hi;
               end if;
            end;
         end;
      end loop;
      X := Here;
      V := Vh;
   end R_Forward;
   function R_Speed_At (M : R_Model_T; P : R_Profile_T; C : R_Curve;
                        X : LF) return LF
   is
      Xr, Vr : LF;
   begin
      if X <= C.Anchor then
         R_Back (M, P, C, X, R_Inf, Xr, Vr);
         return Vr;
      else
         R_Forward (M, P, C, X, C.Floor_V, Xr, Vr);
         return LF'Max (Vr, C.Floor_V);
      end if;
   end R_Speed_At;
   function R_Location_Of (M : R_Model_T; P : R_Profile_T; C : R_Curve;
                           V : LF) return LF
   is
      Xr, Vr : LF;
   begin
      if V >= C.Anchor_V then
         R_Back (M, P, C, -R_Inf, V, Xr, Vr);
      else
         R_Forward (M, P, C, R_Inf, LF'Max (V, C.Floor_V), Xr, Vr);
      end if;
      return Xr;
   end R_Location_Of;
   function R_Margin (Kind : EVC_Limits.Margin_Kind_T; V : LF) return LF is
      D_Min : constant LF := (case Kind is when EVC_Limits.Warning => 4.0,
                                           when EVC_Limits.SBI => 5.5,
                                           when EVC_Limits.EBI => 7.5);
      D_Max : constant LF := (case Kind is when EVC_Limits.Warning => 5.0,
                                           when EVC_Limits.SBI => 10.0,
                                           when EVC_Limits.EBI => 15.0);
      V_Max : constant LF := (if Kind = EVC_Limits.Warning then 140.0
                              else 210.0);
      Kmh   : constant LF := V * 0.036;
      D     : constant LF :=
        (if Kmh <= 110.0 then D_Min
         else LF'Min (D_Min + (D_Max - D_Min) / (V_Max - 110.0)
                              * (Kmh - 110.0), D_Max));
   begin
      return D / 0.036;
   end R_Margin;
   procedure Compare_Location (What   : String;
                               Kernel : EVC_Fixed.Num;
                               Ref    : LF;
                               Span   : LF) is
      D : constant LF := Ref - LF (Kernel);
   begin
      Compared := Compared + 1;
      if D < -0.01 then
         Unsafe := Unsafe + 1;
         Check (False, What & ": beyond the reference by" & Img_LF (-D)
                & " cm");
      else
         Check (D <= 100.0 + 0.005 * abs Span,
                What & ": behind the reference by" & Img_LF (D)
                & " cm over" & Img_LF (Span) & " cm");
      end if;
      Worst_Loc := LF'Max (Worst_Loc, D);
      if abs Span > 10_000.0 then
         Worst_Loc_Rel := LF'Max (Worst_Loc_Rel, (D - 1.0) / abs Span);
      end if;
   end Compare_Location;
   procedure Compare_Speed (What : String; Kernel : EVC_Fixed.Num; Ref : LF)
   is
      D : constant LF := Ref - LF (Kernel);
   begin
      Compared := Compared + 1;
      if D < -0.01 then
         Unsafe := Unsafe + 1;
         Check (False, What & ": above the reference by" & Img_LF (-D)
                & " cm/s");
      else
         Check (D <= 3.0, What & ": below the reference by" & Img_LF (D)
                & " cm/s");
      end if;
      Worst_Speed := LF'Max (Worst_Speed, D);
   end Compare_Speed;
   function Case_Snapshot (T : Train_Case; G : Gradient_Case)
     return SIn.Snapshot_T
   is
      S : SIn.Snapshot_T := Base_Snapshot;
   begin
      S.Train_Data.Max_Speed := Cms (160.0);
      case T is
         when Lambda_60 =>
            S.Train_Data.Brake_Percentage := 60;
         when Lambda_100 =>
            S.Train_Data.Brake_Percentage := 100;
         when Lambda_135 =>
            S.Train_Data.Brake_Percentage := 135;
         when Lambda_180 =>
            S.Train_Data.Brake_Percentage := 180;
            --  a Kv_int set with speed steps (packet 3)
            S.National.Kv_Int_Fresh :=
              (Count => 3,
               Steps => (1 => (0, 750), 2 => (Cms (80.0), 700),
                         3 => (Cms (150.0), 650), others => (0, 1_000)));
         when Lambda_250 =>
            S.Train_Data.Brake_Percentage := 250;
            S.Train_Data.Max_Speed := Cms (200.0);
         when Freight_P_100 =>
            S.Train_Data.Brake_Percentage := 100;
            S.Train_Data.Brake_Position := SIn.Freight_P;
            S.Train_Data.Length := 60_000;
            S.Train_Data.Max_Speed := Cms (100.0);
         when Freight_G_135 =>
            S.Train_Data.Brake_Percentage := 135;
            S.Train_Data.Brake_Position := SIn.Freight_G;
            S.Train_Data.Length := 120_000;
            S.Train_Data.Max_Speed := Cms (100.0);
         when Gamma_Train =>
            S.Train_Data.Model := SIn.Gamma;
            S.Train_Data.A_Brake_Emergency :=
              (Count => 3,
               Steps => (1 => (Cms (100.0), 1_050), 2 => (Cms (160.0), 900),
                         3 => (0, 780), others => (0, 0)));
            S.Train_Data.A_Brake_Service :=
              (Count => 2,
               Steps => (1 => (Cms (120.0), 800), 2 => (0, 700),
                         others => (0, 0)));
            S.Train_Data.A_Brake_Normal :=
              (Count => 2,
               Steps => (1 => (Cms (90.0), 550), 2 => (0, 500),
                         others => (0, 0)));
            S.Train_Data.T_Brake_Emergency := 3_000;
            S.Train_Data.T_Brake_Service := 4_000;
            S.Extra.Train.T_Brake_Emergency_React := 1_000;
            S.Extra.Train.T_Brake_Service_React := 1_500;
            S.Extra.Train.Kdry_Rst (9) := (940, 910, 880, others => 1_000);
            S.Extra.Train.Kwet_Rst := (820, 800, 790, others => 1_000);
            S.Extra.Train.Kn_Plus :=
              (Count => 2, Steps => (1 => (Cms (100.0), 40),
                                     2 => (0, 30), others => (0, 0)));
            S.Extra.Train.Kn_Minus :=
              (Count => 1, Steps => (1 => (0, 50), others => (0, 0)));
            S.National.M_NVAVADH := 500;
      end case;
      case G is
         when Flat =>
            null;
         when Uphill =>
            S.Gradients := (Count => 1, Segments => (1 => (0, 10),
                                                    others => (0, 0)),
                            others => <>);
         when Downhill =>
            S.Gradients := (Count => 1, Segments => (1 => (0, -15),
                                                    others => (0, 0)),
                            others => <>);
         when Mixed =>
            S.Gradients :=
              (Count => 4,
               Segments => (1 => (-100_000, 5), 2 => (150_000, -20),
                            3 => (280_000, 8), 4 => (420_000, -3),
                            others => (0, 0)),
               others   => <>);
         when Steep =>
            S.Gradients :=
              (Count => 3,
               Segments => (1 => (-100_000, 0), 2 => (200_000, -40),
                            3 => (350_000, 0), others => (0, 0)),
               others   => <>);
      end case;
      return S;
   end Case_Snapshot;
   procedure Sup_Cycle (Dt : Natural := 100) is
   begin
      EVC_Core.Set_Snapshot_For_Test (Sup);
      EVC_Core.Tick (Dt);
      Take;
   end Sup_Cycle;
   procedure Sup_Start (S : SIn.Snapshot_T) is
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      Sup := S;
      Sup_Cycle;
   end Sup_Start;
   procedure Move (At_Cm : Integer_64; V : SIn.Speed_Cms_T) is
   begin
      Place (Sup, At_Cm, V);
   end Move;
   function Speed_Frame return Speed_Fields is
      I : constant Natural := Find_DMI (EVC_DMI_Port.MSG_SPEED_STATE);

      function W (N : Positive) return Natural is
        (Byte_At (I, N) + 256 * Byte_At (I, N + 1));
   begin
      if I = 0 or else Rec_Length (I) /= 26 then
         return (others => <>);
      end if;
      return (Found      => True,
              V_Cur      => W (6),
              V_Perm     => W (8),
              V_Target   => W (10),
              V_Release  => W (12),
              V_SBI      => W (14),
              V_Wsl      => W (16),
              D_Target   => W (18) + 65_536 * W (20),
              Monitoring => Byte_At (I, 22),
              Dial       => Byte_At (I, 23),
              Flags      => Byte_At (I, 24),
              Status     => Byte_At (I, 25),
              MRDT       => Byte_At (I, 26));
   end Speed_Frame;
   function TIU_Out return Natural is
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = TIU
           and then Rec_Length (I) = EVC_Ports.TIU_Output_Length
           and then Byte_At (I, 1) /= Natural (EVC_Ports.TIU_TC_Tag)
         then
            return Byte_At (I, 1)
                   + 256 * (Byte_At (I, 2) + 256 * Byte_At (I, 3));
         end if;
      end loop;
      return 16#FFFF#;
   end TIU_Out;
   function Status_Brake return Natural is
      I : constant Natural := Find_DMI (EVC_DMI_Port.MSG_STATUS);
   begin
      return (if I = 0 then 16#FFFF# else Byte_At (I, 6));
   end Status_Brake;
   function JRU_Count (Event : Natural) return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = JRU and then Byte_At (I, 1) = Event then
            N := N + 1;
         end if;
      end loop;
      return N;
   end JRU_Count;
   procedure Drive (X      : in out Integer_64;
                    V      : in out SIn.Speed_Cms_T;
                    Decel  : Natural;
                    Cycles : Natural)
   is
      Braking : Boolean := False;
   begin
      for Step in 1 .. Cycles loop
         exit when Stop_When;
         if not Braking and then Brake_When then
            Braking := True;
         end if;
         if Braking then
            V := SIn.Speed_Cms_T'Max (Integer (V) - Decel, 0);
         end if;
         X := X + Integer_64 (V) / 10;
         Move (X, V);
         Sup_Cycle;
      end loop;
   end Drive;
   procedure Mission_Track (Q_NVEMRRLS : Natural := 1) is
      D    : SIn.Train_Data_T := EVC_Train_Data.Default;
      From : constant Integer := -Mission_Group_M;
      package ST renames Sim_Telegrams;
   begin
      Add_Group (Group (1, Mission_Group_M));
      Carry (1, 0, ST.National_Values (123, Q_NVEMRRLS => Q_NVEMRRLS));
      Carry (1, 0, ST.SSP ((1 => (0, EVC_Track.MRSP (1).Speed),
                            2 => (EVC_Track.MRSP (2).Start_M + From,
                                  EVC_Track.MRSP (2).Speed),
                            3 => (EVC_Track.MRSP (3).Start_M
                                    - EVC_Track.MRSP (2).Start_M,
                                  EVC_Track.MRSP (3).Speed),
                            4 => (Sim_Trackside.Profiles_End_M
                                    - EVC_Track.MRSP (3).Start_M,
                                  ST.End_Mark))));
      Carry (1, 1, ST.Gradients
                     ((1 => (0, EVC_Track.Gradients (1).Value),
                       2 => (EVC_Track.Gradients (2).Start_M + From,
                             EVC_Track.Gradients (2).Value),
                       3 => (EVC_Track.Gradients (3).Start_M
                               - EVC_Track.Gradients (2).Start_M,
                             EVC_Track.Gradients (3).Value),
                       4 => (EVC_Track.Gradients (4).Start_M
                               - EVC_Track.Gradients (3).Start_M,
                             EVC_Track.Gradients (4).Value),
                       5 => (Sim_Trackside.Profiles_End_M
                               - EVC_Track.Gradients (4).Start_M,
                             ST.End_Mark))));
      Carry (1, 1, ST.MA ((1 => EVC_Track.EOA_M + From), V_Main_Kmh => 140,
                          Release_Kmh => EVC_Track.Release_Speed));
      D.Length := 40_000;
      D.Max_Speed := Cms (140.0);
      D.Brake_Percentage := 135;
      D.Brake_Position := SIn.Passenger_P;
      D.T_Traction_Cut_Off := 1_000;
      EVC_Train_Data.Set (D, EVC_Train_Data.Default_Categories);
   end Mission_Track;

   ---------------------------------------------------------------------
   --  Phase E5: the RTM port
   ---------------------------------------------------------------------

   procedure Give_Radio_Message (Session : Natural; Message : Byte_Array)
   is
   begin
      Input (RTM, RTM_Tagged (Session, Message));
   end Give_Radio_Message;

   procedure Give_Radio_Event (Session : Natural;
                               Event   : EVC_Ports.RTM_Event_T)
   is
   begin
      Input (RTM, RTM_Event_Input (Session, Event));
   end Give_Radio_Event;

   procedure Start_Message (W      : in out Writer_T;
                            Kind   : ETCS_Message_Catalogue.Known_Message_T;
                            Values : ETCS_Message.Value_Array)
   is
      OK : Boolean;
   begin
      ETCS_Bits.Clear (W);
      ETCS_Message.Write_Fields (W, Kind, Values, OK);
      Check (OK, "radio: the fields of the message written");
   end Start_Message;

   function Message_Bytes (W : in out Writer_T) return Byte_Array is
      OK : Boolean;
   begin
      ETCS_Message.Finish (W, OK);
      Check (OK, "radio: the message finished");
      return ETCS_Bits.Data (W);
   end Message_Bytes;

   function Message_Of (Kind   : ETCS_Message_Catalogue.Known_Message_T;
                        Values : ETCS_Message.Value_Array :=
                          (others => 0))
     return Byte_Array
   is
      W : Writer_T;
   begin
      Start_Message (W, Kind, Values);
      return Message_Bytes (W);
   end Message_Of;

   function Radio_Outputs return Natural is (Count_Port (RTM));

   function Radio_Output (N : Positive) return Radio_Output_T is
      Seen : Natural := 0;
   begin
      for I in 1 .. Rec_Count loop
         if Recs (I).Port = RTM and then Rec_Length (I) >= 3 then
            Seen := Seen + 1;
            if Seen = N then
               return (Rec     => I,
                       Request => Byte_At (I, 1)
                                    = Natural (EVC_Ports.RTM_Tag_Request),
                       Session => Byte_At (I, 2),
                       Kind    => Byte_At (I, 3));
            end if;
         end if;
      end loop;
      return (others => <>);
   end Radio_Output;

   procedure Decode_Radio_Message (N      : Positive;
                                   M      : out ETCS_Message.Message_T;
                                   Status : out ETCS_Message.Status_T)
   is
      O : constant Radio_Output_T := Radio_Output (N);
   begin
      if O.Rec = 0 or else O.Request then
         M := (others => <>);
         Status := ETCS_Message.Unknown_Message;
         return;
      end if;
      ETCS_Message.Parse
        (Out_Buf (Recs (O.Rec).First + 2 .. Recs (O.Rec).Last),
         ETCS_Catalogue.Train_To_Track, ETCS_Catalogue.RBC, M, Status);
   end Decode_Radio_Message;

   function Request_Byte (N : Positive; K : Positive) return Natural is
      O : constant Radio_Output_T := Radio_Output (N);
   begin
      if O.Rec = 0 or else not O.Request or else Rec_Length (O.Rec) < 3 + K
      then
         return 16#FFFF#;
      end if;
      return Byte_At (O.Rec, 3 + K);
   end Request_Byte;

end EVC_Test_Support;
