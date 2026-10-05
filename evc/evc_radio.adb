--  ETCS on-board (EVC)
--  The radio communication shared by the halves of phase E5,
--  implementation: the table and the outbox (see the specification).

package body EVC_Radio
  with SPARK_Mode => On,
       Refined_State => (State => (Count_Of_Sessions, Table, Supervising_S,
                                   Accepting_S, Contact_Info, Network_Info),
                         Queue => (Data, Used, Refused_Count))
is

   type Table_T is array (Session_T) of Session_Info_T;

   Count_Of_Sessions : Session_Count_T := Max_Sessions;
   Table             : Table_T := (others => No_Info);
   Supervising_S     : Session_Ref_T := No_Session;
   Accepting_S       : Session_Ref_T := No_Session;
   Contact_Info      : RBC_Contact_T := No_Contact;
   Network_Info      : Network_T;

   Data          : EVC_Bytes.Byte_Array (1 .. Queue_Capacity) :=
     (others => 0);
   Used          : Natural range 0 .. Queue_Capacity := 0;
   Refused_Count : Natural := 0;

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Sessions return Session_Count_T is (Count_Of_Sessions)
     with Refined_Global => Count_Of_Sessions;
   function Info (S : Session_T) return Session_Info_T is (Table (S))
     with Refined_Global => Table;
   function Supervising return Session_Ref_T is (Supervising_S)
     with Refined_Global => Supervising_S;
   function Accepting return Session_Ref_T is (Accepting_S)
     with Refined_Global => Accepting_S;
   function Contact return RBC_Contact_T is (Contact_Info)
     with Refined_Global => Contact_Info;
   function Network return Network_T is (Network_Info)
     with Refined_Global => Network_Info;
   function Queued return Natural is (Used)
     with Refined_Global => Used;
   function Refused return Natural is (Refused_Count)
     with Refined_Global => Refused_Count;

   ---------------------------------------------------------------------
   --  EVC_Core
   ---------------------------------------------------------------------

   procedure Clear (N : Session_Count_T) is
   begin
      Count_Of_Sessions := N;
      Table := (others => No_Info);
      Supervising_S := No_Session;
      Accepting_S := No_Session;
      Contact_Info := No_Contact;
      Network_Info := (Known => False, NID_MN => 0, Registered => False);
      Data := (others => 0);
      Used := 0;
      Refused_Count := 0;
   end Clear;

   procedure Restore_Contact (C : RBC_Contact_T) is
   begin
      Contact_Info := C;
      Contact_Info.Valid := False;
   end Restore_Contact;

   ---------------------------------------------------------------------
   --  EVC_Sessions
   ---------------------------------------------------------------------

   procedure Set_State (S : Session_T; To : Session_State_T) is
   begin
      Table (S).State := To;
   end Set_State;

   procedure Set_Peer (S : Session_T; RBC : RBC_Id_T; Radio : NID_RADIO_T)
   is
   begin
      Table (S).RBC := RBC;
      Table (S).Radio := Radio;
   end Set_Peer;

   procedure Set_Version (S : Session_T; Version : M_VERSION_T) is
   begin
      Table (S).Version_Known := True;
      Table (S).Version := Version;
   end Set_Version;

   procedure Note_Received (S       : Session_T;
                            T_Train : T_TRAIN_T;
                            Now_Ms  : Time_Ms_T)
   is
   begin
      Table (S).Received := True;
      Table (S).Last_Received := T_Train;
      Table (S).Received_Ms := Now_Ms;
   end Note_Received;

   procedure Reset_Session (S : Session_T) is
   begin
      Table (S) := No_Info;
   end Reset_Session;

   procedure Set_Roles (Supervising, Accepting : Session_Ref_T) is
   begin
      Supervising_S := Supervising;
      Accepting_S := Accepting;
   end Set_Roles;

   procedure Set_Contact (C : RBC_Contact_T) is
   begin
      Contact_Info := C;
   end Set_Contact;

   procedure Set_Network (N : Network_T) is
   begin
      Network_Info := N;
   end Set_Network;

   ---------------------------------------------------------------------
   --  The outbox
   ---------------------------------------------------------------------

   procedure Count_Refusal
     with Global => (In_Out => Refused_Count)
   is
   begin
      if Refused_Count < Natural'Last then
         Refused_Count := Refused_Count + 1;
      end if;
   end Count_Refusal;

   --  Room for an output of Length bytes (with its record header)
   function Room (Length : Natural) return Boolean is
     (Length <= Queue_Capacity - Queue_Header
      and then Used <= Queue_Capacity - Queue_Header - Length)
     with Global => Used;

   --  The record header of an output of Length bytes, at Used
   procedure Put_Header (Length : Positive)
     with Global => (In_Out => Data, Input => Used),
          Pre => Room (Length)
   is
   begin
      Data (Used + 1) := EVC_Bytes.Byte (Length mod 256);
      Data (Used + 2) := EVC_Bytes.Byte (Length / 256);
   end Put_Header;

   function T_Train_Of (Message : EVC_Bytes.Byte_Array) return T_TRAIN_T
   is
      V : Unsigned_64 := 0;
   begin
      if Message'Length < 7 then
         return 0;
      end if;
      --  bytes 3 to 7 hold the bits 16 to 55 of the message
      for I in 2 .. 6 loop
         pragma Loop_Invariant (V < 2**(8 * (I - 2)));
         V := V * 256 + Unsigned_64 (Message (Message'First + I));
      end loop;
      return T_TRAIN_T (Shift_Right (V, 6) and 16#FFFF_FFFF#);
   end T_Train_Of;

   procedure Send (S : Session_T; Message : EVC_Bytes.Byte_Array) is
      Length : constant Positive := RTM_Tagged_Header + Message'Length;
   begin
      if not Usable (S) or else not Room (Length) then
         Count_Refusal;
         return;
      end if;
      Put_Header (Length);
      Data (Used + Queue_Header + 1) := RTM_Tag_Message;
      Data (Used + Queue_Header + 2) := EVC_Bytes.Byte (S);
      Data (Used + Queue_Header + RTM_Tagged_Header + 1
            .. Used + Queue_Header + Length) := Message;
      Used := Used + Queue_Header + Length;
      Table (S).Sent := True;
      Table (S).Last_Sent := T_Train_Of (Message);
   end Send;

   --  Queue a request of Length bytes, its fixed part filled in, the
   --  rest from Tail
   procedure Put_Request (S       : Session_T;
                          Request : RTM_Request_T;
                          Tail    : EVC_Bytes.Byte_Array)
     with Global => (In_Out => (Data, Used, Refused_Count),
                     Input  => Count_Of_Sessions),
          Pre  => Tail'Length = RTM_Request_Length (Request) - 3,
          Post => Used >= Used'Old
   is
      Length : constant Positive := RTM_Request_Length (Request);
   begin
      if Natural (S) > Count_Of_Sessions or else not Room (Length) then
         Count_Refusal;
         return;
      end if;
      Put_Header (Length);
      Data (Used + Queue_Header + 1) := RTM_Tag_Request;
      Data (Used + Queue_Header + 2) := EVC_Bytes.Byte (S);
      Data (Used + Queue_Header + 3) :=
        EVC_Bytes.Byte (RTM_Request_T'Pos (Request) + 1);
      Data (Used + Queue_Header + 4 .. Used + Queue_Header + Length) := Tail;
      Used := Used + Queue_Header + Length;
   end Put_Request;

   function Byte_Of (V : Unsigned_64; N : Natural) return EVC_Bytes.Byte is
     (EVC_Bytes.Byte (Shift_Right (V, 8 * N) and 16#FF#))
     with Pre => N < 8;

   procedure Request_Set_Up (S     : Session_T;
                             RBC   : RBC_Id_T;
                             Radio : NID_RADIO_T;
                             FRMCS : Boolean)
   is
      C : constant Unsigned_64 := Unsigned_64 (RBC.NID_C);
      R : constant Unsigned_64 := Unsigned_64 (RBC.NID_RBC);
      N : constant Unsigned_64 := Unsigned_64 (Radio);
   begin
      Put_Request
        (S, Request_Set_Up,
         (Byte_Of (C, 0), Byte_Of (C, 1),
          Byte_Of (R, 0), Byte_Of (R, 1),
          Byte_Of (N, 0), Byte_Of (N, 1), Byte_Of (N, 2), Byte_Of (N, 3),
          Byte_Of (N, 4), Byte_Of (N, 5), Byte_Of (N, 6), Byte_Of (N, 7),
          (if FRMCS then 1 else 0)));
   end Request_Set_Up;

   procedure Request_Release (S : Session_T) is
      None : constant EVC_Bytes.Byte_Array (1 .. 0) := (others => 0);
   begin
      Put_Request (S, Request_Release, None);
   end Request_Release;

   procedure Request_Registration (S : Session_T; NID_MN : NID_MN_T) is
      M : constant Unsigned_64 := Unsigned_64 (NID_MN);
   begin
      Put_Request (S, Request_Registration,
                   (Byte_Of (M, 0), Byte_Of (M, 1), Byte_Of (M, 2)));
   end Request_Registration;

   procedure Drain is
      Pos    : Natural := 0;   -- bytes of Data moved
      Length : Natural;        -- of the output at Data (Pos + 3)
   begin
      while Used - Pos > Queue_Header loop
         pragma Loop_Invariant (Pos <= Used);
         pragma Loop_Invariant (Used = Used'Loop_Entry);
         pragma Loop_Variant (Increases => Pos);
         Length := Natural (Data (Pos + 1))
                   + 256 * Natural (Data (Pos + 2));
         --  every record Send and Put_Request queue is whole: a record
         --  that is not (none) empties the outbox rather than jam it
         if Length = 0
           or else Length > Max_Payload (RTM)
           or else Length > Used - Pos - Queue_Header
         then
            Pos := Used;
            exit;
         end if;
         --  the rest waits for the next cycle, in its order
         exit when EVC_Outbox.Used
                     > EVC_Outbox.Capacity - EVC_Outbox.Record_Header
                       - Length;
         EVC_Outbox.Put
           (RTM, Data (Pos + Queue_Header + 1 .. Pos + Queue_Header + Length));
         Pos := Pos + Queue_Header + Length;
      end loop;
      if Pos > 0 then
         Data (1 .. Used - Pos) := Data (Pos + 1 .. Used);
         Used := Used - Pos;
      end if;
   end Drain;

end EVC_Radio;
