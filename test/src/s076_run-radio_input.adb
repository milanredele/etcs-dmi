--  ETCS on-board (EVC)
--  The SUBSET-076 runner: an RTM input step (host only).
--
--  The RBC of the sequence is a script: the step gives the on-board what
--  the sequence says the RBC (or Euroradio) does, on the RTM port in the
--  format of EVC_Ports (phase E5: a tagged message, an event of the safe
--  radio connection), in session Radio_Session.
--
--  input RTM connect       SA-CONNECT.Confirm: the event "set up". The
--                          bench gives it at the step whether or not the
--                          on-board asked for a connection (the step
--                          before, "expect RTM connect", judges the
--                          request; an on-board that did not ask must
--                          ignore the confirmation).
--  input RTM disconnect    SA-DISCONNECT.Indication: "released" when the
--                          on-board asked for the release or sent the
--                          termination of the session (message 156,
--                          3.5.5), else "lost" (3.5.4.1, the network or
--                          the RBC ended it).
--  input RTM registration  SA-REGISTRATION.Indication: "registered"
--                          (3.5.6).
--  input RTM permission    SA-PERMISSION: not in the port (not modelled).
--  input RTM message N     the "message" block of the step (its var
--                          rows), with its time stamps set as an RBC
--                          sets them (below). Message 37 is from an RIU
--                          (radio infill, 3.9, E7).
--
--  The time stamps (3.16.3.2.2, 3.16.3.3.1/2): the RBC estimates the
--  on-board time from the T_TRAIN of the last message the on-board sent
--  in the session plus the time since the bench took it, never in
--  advance of the real on-board time, and always above the stamp of its
--  previous message. Before the on-board sent anything in the session
--  the stamp of the block is used (0 in the corpus), then one more each
--  message. The T_TRAIN of the message answered (8.6: messages 4 and 5
--  answer 131, 7 answers 133, 8 answers 129, 27 and 28 answer 130) is
--  the T_TRAIN of the last such message the on-board sent in the
--  session; the block's value when it sent none.
--
--  Held (Hold_Mode, S076_Run.Hold_Answer): the message is built before
--  its step, stamped for the time it is to be given, and held by the
--  bench until then; its step passes as given earlier, or gives it at
--  once when the hold has not fired yet.

separate (S076_Run)
function Radio_Input (St : Step_T) return Judgement_T is
   use type B.Byte_Array;
   Kind : constant String := W (3);

   --  The session this step is for. One RBC: session 1, as always. A
   --  handover shows a second RBC and the sequence tells the two apart
   --  only by the order of events (SUBSET-076 gives no RBC identity on
   --  its steps): a connection is the answer to the request the on-board
   --  made in a session that has no connection; the termination
   --  messages (24 with packet 42, and 39 after 156) and a disconnect go
   --  to the session they belong to; any other message goes to the
   --  session set up last. With one session alive this is session 1.
   function Route return Positive is
      Other : constant Positive := 3 - RBC_Current;
      Set_Up : constant Natural :=
        EVC_Ports.RTM_Request_T'Pos (EVC_Ports.Request_Set_Up) + 1;
      Release : constant Natural :=
        EVC_Ports.RTM_Request_T'Pos (EVC_Ports.Request_Release) + 1;
      Both : constant Boolean := RBC_Alive (1) and then RBC_Alive (2);
      Nid : constant String := W (4);
      Has_42 : Boolean := False;
   begin
      if Same (Kind, "connect") then
         for Cand in 1 .. 2 loop
            if not RBC_Alive (Cand) and then B.Last_Request (Cand) = Set_Up
            then
               return Cand;
            end if;
         end loop;
         return Radio_Session;
      elsif Same (Kind, "disconnect") then
         for Cand in 1 .. 2 loop
            if RBC_Alive (Cand)
              and then (B.Last_Request (Cand) = Release
                        or else B.T_Train_Of (Cand, 156) >= 0)
            then
               return Cand;
            end if;
         end loop;
         return (if Both then Other else RBC_Current);
      elsif not Same (Kind, "message") or else not Both then
         return RBC_Current;
      elsif Nid = "39" then
         return (if B.T_Train_Of (Other, 156) >= 0 then Other
                 else RBC_Current);
      end if;
      for I in 1 .. Seq.Message_Count loop
         if Seq.Messages (I).Step = St.Number then
            for K in 1 .. Seq.Messages (I).Packet_Count loop
               Has_42 := Has_42 or else Seq.Messages (I).Packets (K) = 42;
            end loop;
         end if;
      end loop;
      return (if Nid = "24" and then Has_42 then Other else RBC_Current);
   end Route;

   S    : constant Positive := Route;

   procedure Event (E : EVC_Ports.RTM_Event_T) is
   begin
      B.RTM_Input ((EVC_Ports.RTM_Tag_Event, Unsigned_8 (S),
                    Unsigned_8 (EVC_Ports.RTM_Event_T'Pos (E) + 1)));
   end Event;

   procedure Put_Bits (Data : in out B.Byte_Array; At_Bit, Width : Natural;
                       Value : Unsigned_64) is
   begin
      for K in 0 .. Width - 1 loop
         declare
            Bit  : constant Natural := At_Bit + K;
            Byte : constant Natural := Data'First + Bit / 8;
            Mask : constant Unsigned_8 := Shift_Right (16#80#, Bit mod 8);
         begin
            exit when Byte > Data'Last;
            if (Shift_Right (Value, Width - 1 - K) and 1) = 1 then
               Data (Byte) := Data (Byte) or Mask;
            else
               Data (Byte) := Data (Byte) and not Mask;
            end if;
         end;
      end loop;
   end Put_Bits;

   --  The L_MESSAGE of message I of the sequence, its bytes: the 10 bits
   --  after the 8 of NID_MESSAGE (8.4.4.2)
   function L_Message (I : Positive) return Natural is
     (Natural (Seq.Messages (I).Data (2)) * 4
      + Natural (Seq.Messages (I).Data (3)) / 64);

   --  Whether a packet the step's input line names ("packets 15 21 27
   --  5 57", an alternative as "72/73") is absent from message I
   function Packet_Missing (I : Positive) return Boolean is
      M : Message_T renames Seq.Messages (I);
      K : Positive := 6;

      function Present (Nid : String) return Boolean is
        (for some J in 1 .. M.Packet_Count =>
            Img (Natural (M.Packets (J))) = Nid);

      --  whether no alternative of word Word ("72/73") is present
      function Absent (Word : String) return Boolean is
         From : Positive := Word'First;
      begin
         for C in Word'Range loop
            if Word (C) = '/' or else C = Word'Last then
               if Present (Word (From .. (if Word (C) = '/' then C - 1
                                          else C)))
               then
                  return False;
               end if;
               From := C + 1;
            end if;
         end loop;
         return True;
      end Absent;
   begin
      if W (5) /= "packets" then
         return False;
      end if;
      while W (K) /= "" and then not Has (W (K), "=") loop
         if Absent (W (K)) then
            return True;
         end if;
         K := K + 1;
      end loop;
      return False;
   end Packet_Missing;

   function Get_Bits (Data : B.Byte_Array; At_Bit, Width : Natural)
     return Unsigned_64
   is
      V : Unsigned_64 := 0;
   begin
      for K in 0 .. Width - 1 loop
         declare
            Bit  : constant Natural := At_Bit + K;
            Byte : constant Natural := Data'First + Bit / 8;
         begin
            V := V * 2;
            if Byte <= Data'Last
              and then (Shift_Right (Data (Byte), 7 - Bit mod 8) and 1) = 1
            then
               V := V + 1;
            end if;
         end;
      end loop;
      return V;
   end Get_Bits;

   function Answered (Nid : Natural) return Natural is
     (case Nid is
         when 4 | 5   => 131,
         when 7       => 133,
         when 8       => 129,
         when 27 | 28 => 130,
         when others  => 0);
   --  4.8.4 [1]: the message 6 of step J is the negative case, not
   --  more recent than the trip: its own comment says so, or a later
   --  step of the same test case says that the recognition "with a more
   --  recent time stamp is not true" (4080455_04 step 111, case 4080455
   --  7; the message 6 of step 105 is the one of the positive case
   --  4080455_03, T_TRAIN 0 like every message 6 of the corpus)
   function Negative_Exit (J : Positive) return Boolean is
      Sj : Step_T renames Seq.Steps (J);
   begin
      if Has (Image (Sj.Comment), "not more recent")
        or else Has (Image (Sj.Comment), "older than")
      then
         return True;
      end if;
      for I in J + 1 .. Seq.Step_Count loop
         exit when Seq.Steps (I).Case_Feature /= Sj.Case_Feature
           or else Seq.Steps (I).Case_No /= Sj.Case_No;
         if Has (Image (Seq.Steps (I).Comment),
                 "with a more recent time stamp is not true")
         then
            return True;
         end if;
      end loop;
      return False;
   end Negative_Exit;

   --  the index of this step in the sequence
   function This_Step return Natural is
   begin
      for I in 1 .. Seq.Step_Count loop
         if Seq.Steps (I).Line_No = St.Line_No then
            return I;
         end if;
      end loop;
      return 0;
   end This_Step;

   function Exit_Not_More_Recent return Boolean is
     (This_Step > 0 and then Negative_Exit (This_Step));

   --  the RBC messages of the steps after this one that come before a
   --  negative message 6 (Negative_Exit), -1 when no negative message 6
   --  follows before the next message 6 or the end: 0 for the message 6
   --  itself
   function Messages_Before_Negative_Exit return Integer is
      N : Natural := 0;
   begin
      if This_Step = 0 then
         return -1;
      end if;
      for I in This_Step .. Seq.Step_Count loop
         declare
            L : constant String := Image (Seq.Steps (I).Line);
         begin
            if L = "input RTM message 6" then
               return (if Negative_Exit (I) then N else -1);
            elsif I > This_Step and then Has (L, "input RTM message ")
              and then not Has (L, "input RTM message 37")
            then
               N := N + 1;
            end if;
         end;
      end loop;
      return -1;
   end Messages_Before_Negative_Exit;

   --  the on-board's T_TRAIN at the entry into TR as the RBC estimates
   --  it, from the bench time of the JRU's event 1 and the last on-board
   --  stamp Last of the session; -1 before a trip
   function Trip_Stamp (Last : Integer_64) return Integer_64 is
     (if B.Trip_Ms > 0 and then Last >= 0
      then Last + (Integer_64 (B.Trip_Ms)
                   - Integer_64 (B.Last_Sent_Ms (S))) / 10
      else -1);
begin
   if Same (Kind, "connect") then
      --  a new connection: a new session, whose time stamps start again
      RBC_Stamp_Given := False;
      RBC_Alive (S) := True;
      RBC_Current := S;
      Event (EVC_Ports.Connection_Set_Up);
      return Pass ("RTM connection set up (session" & Natural'Image (S)
                   & ")");
   elsif Same (Kind, "disconnect") then
      if B.Last_Request (S) = EVC_Ports.RTM_Request_T'Pos
                                (EVC_Ports.Request_Release) + 1
        or else B.T_Train_Of (S, 156) >= 0
      then
         Event (EVC_Ports.Connection_Released);
         RBC_Alive (S) := False;
         if RBC_Alive (3 - S) then
            RBC_Current := 3 - S;
         end if;
         return Pass ("RTM connection released");
      end if;
      RBC_Alive (S) := False;
      if RBC_Alive (3 - S) then
         RBC_Current := 3 - S;
      end if;
      Event (EVC_Ports.Connection_Lost);
      return Pass ("RTM connection lost");
   elsif Same (Kind, "registration") then
      Event (EVC_Ports.Registered);
      return Pass ("RTM registered to the network");
   elsif not Same (Kind, "message") then
      return NJ (R_Not_Modelled, "RTM " & Kind & " (not in the port)");
   end if;

   declare
      Nid : constant String := W (4);
      Msg : Natural := 0;
   begin
      if Nid = "37" then
         return NJ (R_Radio_Infill, "RTM message 37 from an RIU");
      end if;
      --  a message the bench holds for this step (Hold_Answer): given
      --  already within the waiting time, else given now
      if not Hold_Mode and then Hold_Number = St.Number then
         Hold_Number := 0;
         B.Cancel_RTM_Hold;
         if B.RTM_Hold_Given then
            RBC_Given_Ms := B.RTM_Hold_Given_Ms;
            return Pass ("RTM message " & Nid & " given earlier, at t="
                         & Unsigned_64'Image (B.RTM_Hold_Given_Ms)
                         & " ms, within the waiting time (A.3.1)");
         end if;
      end if;
      for I in 1 .. Seq.Message_Count loop
         if Seq.Messages (I).Step = St.Number
           and then Img (Seq.Messages (I).NID) = Nid
         then
            Msg := I;
         end if;
      end loop;
      if Msg = 0 then
         return NJ (R_Extractor, "RTM message " & Nid & ": no message block");
      elsif not Seq.Messages (Msg).Has_Bits then
         return NJ (R_Extractor, "RTM message " & Nid
                    & " refused by the extractor");
      elsif (Seq.Messages (Msg).Bits + 7) / 8 < L_Message (Msg)
        and then Packet_Missing (Msg)
      then
         --  8.4.4.2: L_MESSAGE, the 10 bits after NID_MESSAGE, counts
         --  the message's bytes; fewer bits than that, with a packet the
         --  step names absent, are a message truncated by the extraction
         --  (3131100_02 step 71: 253 bits for 57 bytes, packets 5 and 57
         --  missing), not given to the on-board, which would refuse it
         --  (8.4.4.2.1) and fail a later step for the sequence's data;
         --  decision: a short message with all its packets is given (the
         --  wrong L_MESSAGE of 8040400_01 step 65 is the step's purpose)
         return NJ (R_S076_Defect, "RTM message " & Nid & " of"
                    & Natural'Image (Seq.Messages (Msg).Bits)
                    & " bits for L_MESSAGE"
                    & Natural'Image (L_Message (Msg))
                    & " (truncated in the extraction)");
      elsif Seq.Messages (Msg).NID = 38 and then L_Message (Msg) /= 7 then
         --  8.7.16: message 38 is NID_MESSAGE, L_MESSAGE, T_TRAIN and
         --  M_ACK, 51 bits in 7 bytes; a 38 of another length is the
         --  layout of system version 2 (NID_LRBG after M_ACK, 75 bits,
         --  L_MESSAGE 10), which the on-board refuses (8.4.4.2.1, M_ERROR
         --  3), so the session established report stays unacknowledged
         --  and the session ends 30 s later (3.5.3.7.4.1), failing a
         --  later step for the sequence's data. Only the SV30 corpus
         --  carries 38s: 631 of 7 bytes and 3 of 10 (3130700_07 step 65,
         --  3130700_08 step 68, 4080421_03 step 207; ERA's step lists
         --  give the same fields), each blocked here
         return NJ (R_S076_Defect, "RTM message 38 with L_MESSAGE"
                    & Natural'Image (L_Message (Msg))
                    & " (8.7.16: 7 bytes; the layout of system version 2,"
                    & " with NID_LRBG)");
      end if;
      declare
         M     : Message_T renames Seq.Messages (Msg);
         Bytes : constant Natural := (M.Bits + 7) / 8;
         Data  : B.Byte_Array (1 .. Bytes);
         Stamp : Unsigned_64;
         Last  : constant Integer_64 := B.Last_T_Train (S);
      begin
         for K in 1 .. Bytes loop
            Data (K) := M.Data (K);
         end loop;
         if M.T_Train_Count >= 1 then
            if Last >= 0 then
               Stamp := Unsigned_64 (Last)
                 + ((if Hold_Mode then Hold_Fire_Ms else B.Time_Ms)
                    - B.Last_Sent_Ms (S)) / 10;
            else
               Stamp := Get_Bits (Data, M.T_Train_At (1), 32);
            end if;
            if RBC_Stamp_Given and then Stamp <= RBC_Stamp then
               Stamp := RBC_Stamp + 1;
            end if;
            if M.NID /= 6
              and then (Trim (St.Mode_Before) = "TR"
                        or else Trim (St.Mode_Before) = "PT")
            then
               --  4.8.4 [1], the negative case: a message the RBC sends
               --  after the trip and before a recognition of the exit
               --  from TR that is not more recent than the trip
               --  (4080455_04 step 82, then step 105) is stamped below
               --  the trip too, so that the message 6 fits between it
               --  and the trip (3.16.3.3.3); decision: the RBC stamps by
               --  the last on-board message it knows, the one before the
               --  trip, as low as its own sequence allows; every such
               --  message, N of them after this one, a stamp each
               declare
                  N   : constant Integer := Messages_Before_Negative_Exit;
                  Cap : constant Integer_64 :=
                    Trip_Stamp (Last) - 2 - Integer_64 (Integer'Max (N, 0));
               begin
                  if N >= 0 and then Cap > 0 and then Stamp > Unsigned_64 (Cap)
                    and then (not RBC_Stamp_Given
                              or else Integer_64 (RBC_Stamp) + 1 <= Cap)
                  then
                     Stamp := (if RBC_Stamp_Given then RBC_Stamp + 1
                               else Unsigned_64 (Cap));
                  end if;
               end;
            end if;
            if M.NID = 6 and then Exit_Not_More_Recent then
               --  4.8.4 [1], the negative case: the recognition of the
               --  exit from TR stamped before the trip (the on-board's
               --  T_TRAIN at the entry into TR, estimated as the RBC
               --  estimates it, from the bench time of the JRU's event
               --  1), above the RBC's previous message where that one
               --  came before the trip (3.16.3.3.3); decision: the RBC
               --  sent a message in TR (4080455_04 step 82), so the
               --  stamp is one below the trip and older than it, the
               --  message to be rejected either way
               declare
                  T : constant Integer_64 := Trip_Stamp (Last);
               begin
                  if RBC_Stamp_Given
                    and then (T < 0 or else Integer_64 (RBC_Stamp) + 1 < T)
                  then
                     Stamp := RBC_Stamp + 1;
                  elsif T > 0 then
                     Stamp := Unsigned_64 (T - 1);
                  else
                     Stamp := Get_Bits (Data, M.T_Train_At (1), 32);
                  end if;
               end;
            end if;
            Stamp := Stamp mod 2**32;
            if RBC_Stamp_Given and then RBC_Stamp > 0
              and then Has (Image (St.Comment), "smaller than the time stamp")
            then
               --  3160300.1: the step asks for a stamp older than the
               --  previous message's (3.16.3.3.3); the next keeps rising
               Put_Bits (Data, M.T_Train_At (1), 32, RBC_Stamp - 1);
            else
               Put_Bits (Data, M.T_Train_At (1), 32, Stamp);
               RBC_Stamp := Stamp;
               RBC_Stamp_Given := True;
            end if;
         end if;
         if M.T_Train_Count >= 2 and then Answered (M.NID) > 0
           and then B.T_Train_Of (S, Answered (M.NID)) >= 0
         then
            --  the answered request's T_TRAIN as the second stamp; one
            --  less when the step asks for a stamp that "does not match
            --  the time stamp of the last sent request" (the message is
            --  to be rejected, e.g. 4.8.4 [14]): the sequences give no
            --  data for it
            Put_Bits (Data, M.T_Train_At (2), 32,
                      (Unsigned_64 (B.T_Train_Of (S, Answered (M.NID)))
                       + (if Has (Image (St.Comment),
                                  "does not match the time stamp of the "
                                  & "last sent request")
                          then 2**32 - 1 else 0)) mod 2**32);
         end if;
         if Hold_Mode then
            B.Hold_RTM (B.Byte_Array'(EVC_Ports.RTM_Tag_Message,
                                      Unsigned_8 (S)) & Data,
                        Hold_Fire_Ms);
            Hold_Number := St.Number;
            return Pass ("RTM message " & Nid & " held");
         end if;
         RBC_Given_Ms := B.Time_Ms;
         B.RTM_Input (B.Byte_Array'(EVC_Ports.RTM_Tag_Message,
                                    Unsigned_8 (S)) & Data);
         return Pass ("RTM message " & Nid & " given (session"
                      & Natural'Image (S) & ")");
      end;
   end;
end Radio_Input;
