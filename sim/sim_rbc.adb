--  ETCS DMI test simulator
--  The scripted RBC, body.

with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Message;
with ETCS_Message_Catalogue; use ETCS_Message_Catalogue;
with ETCS_Track_Packets.P15;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P1;
with ETCS_Variables;         use ETCS_Variables;
with EVC_Ports;              use EVC_Ports;
with EVC_Track;
with Interfaces;             use Interfaces;

package body Sim_RBC is

   use type EVC_Bytes.Byte_Array;
   subtype Byte is EVC_Bytes.Byte;
   subtype Byte_Array is EVC_Bytes.Byte_Array;

   --  M_VERSION of system version 4.0 (7.5.1.79: X in 3 bits, Y in 4)
   Version_4_0 : constant := 2#100_0000#;
   Unknown_LRBG : constant := 16#FF_FFFF#;

   type RBC_State_T is record
      St        : State_T := Idle;
      Session   : Natural := 0;
      NID_C     : Natural := EVC_Track.NID_C;
      NID_RBC   : Natural := 1;
      --  the T_TRAIN of the last message received, and ms since
      Train_T   : Unsigned_64 := 0;
      Since_Ms  : Unsigned_64 := 0;
      Heard     : Boolean := False;
      Stamp     : Unsigned_64 := 0;
      Stamped   : Boolean := False;
      Train_Data_T : Unsigned_64 := 0;
      LRBG      : Unsigned_64 := Unknown_LRBG;
      LRBG_NID_BG : Natural := 0;
      LRBG_Known  : Boolean := False;
   end record;

   RBCs : array (RBC_T) of RBC_State_T;

   --  The queue of RTM inputs: records of a length (u16) and a payload
   Queue_Size : constant := 4096;
   Queue      : Byte_Array (1 .. Queue_Size) := (others => 0);
   Read_At    : Positive := 1;
   Write_At   : Positive := 1;
   Queued     : Natural := 0;

   Taken_N, Errors_N, Answered_N, Dropped_N, Handover_N : Natural := 0;
   Last_NID : Natural := 0;

   --  the message read last (package state: about 1 KB)
   Msg : ETCS_Message.Message_T;
   W   : ETCS_Bits.Writer (ETCS_Bits.Max_Bytes);

   procedure Reset is
   begin
      RBCs := (others => <>);
      RBCs (2).NID_RBC := 2;
      Read_At := 1;
      Write_At := 1;
      Queued := 0;
      Taken_N := 0;
      Errors_N := 0;
      Answered_N := 0;
      Dropped_N := 0;
      Handover_N := 0;
      Last_NID := 0;
   end Reset;

   procedure Set_Identity (RBC : RBC_T; NID_C, NID_RBC : Natural) is
   begin
      RBCs (RBC).NID_C := NID_C;
      RBCs (RBC).NID_RBC := NID_RBC;
   end Set_Identity;

   ---------------------------------------------------------------------
   --  The queue
   ---------------------------------------------------------------------

   procedure Put (Payload : Byte_Array) is
   begin
      if Queued = 0 then
         Read_At := 1;
         Write_At := 1;
      end if;
      if Payload'Length = 0 or else Payload'Length > 16#FFFF#
        or else Write_At + 1 + Payload'Length > Queue_Size
      then
         Dropped_N := Dropped_N + 1;
         return;
      end if;
      Queue (Write_At) := Byte (Payload'Length / 256);
      Queue (Write_At + 1) := Byte (Payload'Length mod 256);
      Queue (Write_At + 2 .. Write_At + 1 + Payload'Length) := Payload;
      Write_At := Write_At + 2 + Payload'Length;
      Queued := Queued + 1;
      Answered_N := Answered_N + 1;
   end Put;

   procedure Next_Input (Buffer : out Byte_Array; Last : out Natural) is
      Length : Natural;
   begin
      Buffer := (others => 0);
      Last := Buffer'First - 1;
      if Queued = 0 then
         return;
      end if;
      Length := Natural (Queue (Read_At)) * 256
                + Natural (Queue (Read_At + 1));
      if Length > Buffer'Length then
         return;
      end if;
      Buffer (Buffer'First .. Buffer'First + Length - 1) :=
        Queue (Read_At + 2 .. Read_At + 1 + Length);
      Last := Buffer'First + Length - 1;
      Read_At := Read_At + 2 + Length;
      Queued := Queued - 1;
   end Next_Input;

   function Pending return Natural is (Queued);

   procedure Event (Session : Natural; E : RTM_Event_T) is
   begin
      Put ((RTM_Tag_Event, Byte (Session mod 256),
            Byte (RTM_Event_T'Pos (E) + 1)));
   end Event;

   ---------------------------------------------------------------------
   --  The messages to the on-board
   ---------------------------------------------------------------------

   --  The N-th field Var of Kind set to V
   procedure Set (Values : in out ETCS_Message.Value_Array;
                  Kind   : Known_Message_T;
                  Var    : Variable_T;
                  V      : Unsigned_64;
                  Nth    : Positive := 1)
   is
      Seen : Natural := 0;
   begin
      for I in 1 .. Field_Count (Kind) loop
         if Fields (Kind) (I) = Var then
            Seen := Seen + 1;
            if Seen = Nth then
               Values (I) := V;
               return;
            end if;
         end if;
      end loop;
   end Set;

   --  3.16.3.2.2: the on-board time estimated, strictly increasing
   function Next_Stamp (R : in out RBC_State_T) return Unsigned_64 is
      S : Unsigned_64 :=
        (if R.Heard then R.Train_T + R.Since_Ms / 10 else 0);
   begin
      if R.Stamped and then S <= R.Stamp then
         S := R.Stamp + 1;
      end if;
      S := S mod 2**32;
      R.Stamp := S;
      R.Stamped := True;
      return S;
   end Next_Stamp;

   --  Packet 15: the EOA at the bench line's EOA from the LRBG, with its
   --  danger point and a release speed of 25 km/h
   procedure Put_MA (R : RBC_State_T; OK : in out Boolean) is
      P : ETCS_Track_Packets.P15.Packet_T;
      LRBG_M : Integer := 0;
      Done : Boolean;
   begin
      for G of EVC_Track.Balise_Groups loop
         if G.NID_BG = R.LRBG_NID_BG then
            LRBG_M := G.At_M;
         end if;
      end loop;
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.V_EMA := 0;
      P.T_EMA := 1023;
      P.N_ITER := 0;
      P.L_ENDSECTION := L_ENDSECTION_T
        (Integer'Max (0, Integer'Min (32_767, EVC_Track.EOA_M - LRBG_M)));
      P.Q_DANGERPOINT := 1;
      P.Has_D_DP := True;
      P.D_DP := 0;
      P.V_RELEASEDP := 5;
      ETCS_Track_Packets.P15.Encode (P, W, Done);
      OK := OK and then Done;
   end Put_MA;

   procedure Send (RBC : RBC_T; NID : Natural; Ack_Of : Unsigned_64 := 0) is
      R    : RBC_State_T renames RBCs (RBC);
      Kind : constant Message_Kind_T :=
        ETCS_Message_Catalogue.Kind (ETCS_Catalogue.Track_To_Train, NID);
      Values : ETCS_Message.Value_Array := (others => 0);
      OK, Done : Boolean;
   begin
      if Kind = Unknown or else R.Session not in 1 .. RTM_Max_Sessions then
         return;
      end if;
      Set (Values, Kind, T_TRAIN, Next_Stamp (R));
      --  NID_LRBG (NID_C, NID_BG; all ones: unknown, 7.5.1.85)
      Set (Values, Kind, NID_C,
           (if R.LRBG_Known then Shift_Right (R.LRBG, 14) else 1023));
      Set (Values, Kind, NID_BG,
           (if R.LRBG_Known then R.LRBG and 16#3FFF# else 16#3FFF#));
      case NID is
         when 32 => Set (Values, Kind, M_VERSION, Version_4_0);
         when 8  => Set (Values, Kind, T_TRAIN, Ack_Of, Nth => 2);
         when 16 => Set (Values, Kind, NID_EM, 1);
         when others => null;
      end case;
      ETCS_Bits.Clear (W);
      ETCS_Message.Write_Fields (W, Kind, Values, OK);
      if NID = 3 then
         Put_MA (R, OK);
      end if;
      ETCS_Message.Finish (W, Done);
      if OK and then Done then
         Put (Byte_Array'(RTM_Tag_Message, Byte (R.Session))
              & ETCS_Bits.Data (W));
      else
         Dropped_N := Dropped_N + 1;
      end if;
   end Send;

   ---------------------------------------------------------------------
   --  The on-board's outputs
   ---------------------------------------------------------------------

   function RBC_Of_Session (S : Natural) return Natural is
   begin
      for R in RBC_T loop
         if RBCs (R).Session = S then
            return Natural (R);
         end if;
      end loop;
      return 0;
   end RBC_Of_Session;

   procedure Request (S : Natural; P : Byte_Array) is
      Code : constant Natural := Natural (P (P'First + 2));
   begin
      if Code = RTM_Request_T'Pos (Request_Set_Up) + 1
        and then P'Length = RTM_Request_Length (Request_Set_Up)
      then
         declare
            NID_C   : constant Natural :=
              Natural (P (P'First + 3)) * 256 + Natural (P (P'First + 4));
            NID_RBC : constant Natural :=
              Natural (P (P'First + 5)) * 256 + Natural (P (P'First + 6));
            Found : Natural := 0;
         begin
            for R in RBC_T loop
               if RBCs (R).NID_C = NID_C and then RBCs (R).NID_RBC = NID_RBC
               then
                  Found := Natural (R);
               end if;
            end loop;
            if Found = 0 then
               --  the bench line has one RBC: RBC 1 takes any identity
               --  no RBC has
               Found := 1;
            end if;
            if RBCs (RBC_T (Found)).Session in 0 | S then
               declare
                  R : RBC_State_T renames RBCs (RBC_T (Found));
               begin
                  R.St := Connected;
                  R.Session := S;
                  R.Heard := False;
                  R.Stamped := False;
               end;
               Event (S, Connection_Set_Up);
            else
               Event (S, Set_Up_Failed);
            end if;
         end;
      elsif Code = RTM_Request_T'Pos (Request_Release) + 1 then
         if RBC_Of_Session (S) > 0 then
            RBCs (RBC_T (RBC_Of_Session (S))).St := Idle;
            RBCs (RBC_T (RBC_Of_Session (S))).Session := 0;
         end if;
         Event (S, Connection_Released);
      elsif Code = RTM_Request_T'Pos (Request_Registration) + 1 then
         Event (S, Registered);
      else
         Errors_N := Errors_N + 1;
      end if;
   end Request;

   --  The LRBG of a position report: packet 0 or 1
   procedure Note_Position (R : in out RBC_State_T) is
      Rd : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
      OK : Boolean;
   begin
      for I in 1 .. Msg.Count loop
         if Msg.Index (I).NID = 0 then
            declare
               P : ETCS_Train_Packets.P0.Packet_T;
            begin
               ETCS_Message.Open_Packet (Msg, I, Rd);
               ETCS_Train_Packets.P0.Decode (Rd, P, OK);
               if OK and then Natural (P.NID_BG) /= 16_383 then
                  R.LRBG := Unsigned_64 (P.NID_C) * 2**14
                            + Unsigned_64 (P.NID_BG);
                  R.LRBG_NID_BG := Natural (P.NID_BG);
                  R.LRBG_Known := True;
               end if;
            end;
         elsif Msg.Index (I).NID = 1 then
            declare
               P : ETCS_Train_Packets.P1.Packet_T;
            begin
               ETCS_Message.Open_Packet (Msg, I, Rd);
               ETCS_Train_Packets.P1.Decode (Rd, P, OK);
               if OK and then Natural (P.NID_BG) /= 16_383 then
                  R.LRBG := Unsigned_64 (P.NID_C) * 2**14
                            + Unsigned_64 (P.NID_BG);
                  R.LRBG_NID_BG := Natural (P.NID_BG);
                  R.LRBG_Known := True;
               end if;
            end;
         end if;
      end loop;
   end Note_Position;

   procedure Message (S : Natural; P : Byte_Array) is
      use type ETCS_Message.Status_T;
      Status : ETCS_Message.Status_T;
      K      : Natural;
   begin
      ETCS_Message.Parse (P (P'First + 2 .. P'Last),
                          ETCS_Catalogue.Train_To_Track,
                          ETCS_Catalogue.RBC, Msg, Status);
      K := RBC_Of_Session (S);
      if Status /= ETCS_Message.Accepted or else K = 0 then
         --  not a message of chapter 8, or none of its session
         Errors_N := Errors_N + 1;
         return;
      end if;
      Last_NID := Natural (P (P'First + 2));
      declare
         RBC : constant RBC_T := RBC_T (K);
         R   : RBC_State_T renames RBCs (RBC);
      begin
         R.Train_T := ETCS_Message.Value (Msg, T_TRAIN);
         R.Since_Ms := 0;
         R.Heard := True;
         case Last_NID is
            when 155 =>
               R.St := Initiating;
               Send (RBC, 32);
            when 159 =>
               R.St := Established;
               Send (RBC, 38);
            when 154 =>
               R.St := Terminating;
            when 129 =>
               R.Train_Data_T := R.Train_T;
               Send (RBC, 8, Ack_Of => R.Train_Data_T);
            when 132 =>
               Note_Position (R);
               Send (RBC, 3);
            when 136 | 157 =>
               Note_Position (R);
            when 156 =>
               R.St := Terminating;
               Send (RBC, 39);
            when others =>
               null;
         end case;
      end;
   end Message;

   procedure Take (Payload : Byte_Array) is
   begin
      Taken_N := Taken_N + 1;
      if Payload'Length < 3
        or else Natural (Payload (Payload'First + 1))
                not in 1 .. RTM_Max_Sessions
      then
         Errors_N := Errors_N + 1;
      elsif Payload (Payload'First) = RTM_Tag_Request then
         Request (Natural (Payload (Payload'First + 1)), Payload);
      elsif Payload (Payload'First) = RTM_Tag_Message then
         Message (Natural (Payload (Payload'First + 1)), Payload);
      else
         Errors_N := Errors_N + 1;
      end if;
   end Take;

   procedure Step (Dt_Ms : Natural) is
   begin
      for R of RBCs loop
         if R.Since_Ms < 2**40 then
            R.Since_Ms := R.Since_Ms + Unsigned_64 (Dt_Ms);
         end if;
      end loop;
   end Step;

   procedure Emergency_Stop (RBC : RBC_T := 1) is
   begin
      if RBCs (RBC).St = Established then
         Send (RBC, 16);
      end if;
   end Emergency_Stop;

   procedure Handover (From, To : RBC_T) is
      pragma Unreferenced (From, To);
   begin
      Handover_N := Handover_N + 1;
   end Handover;

   function State (RBC : RBC_T) return State_T is (RBCs (RBC).St);
   function Session_Of (RBC : RBC_T) return Natural is (RBCs (RBC).Session);
   function Taken return Natural is (Taken_N);
   function Errors return Natural is (Errors_N);
   function Answered return Natural is (Answered_N);
   function Dropped return Natural is (Dropped_N);
   function Last_NID_Taken return Natural is (Last_NID);
   function Handovers_Asked return Natural is (Handover_N);

end Sim_RBC;
