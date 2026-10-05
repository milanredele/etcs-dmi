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

separate (S076_Run)
function Radio_Input (St : Step_T) return Judgement_T is
   use type B.Byte_Array;
   Kind : constant String := W (3);
   S    : constant Positive := Radio_Session;

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
begin
   if Handover_Step > 0 and then St.Number > Handover_Step then
      return NJ (R_Handover, "RTM " & Kind & " after the RBC transition"
                 & " order");
   end if;
   if Same (Kind, "connect") then
      --  a new connection: a new session, whose time stamps start again
      RBC_Stamp_Given := False;
      Event (EVC_Ports.Connection_Set_Up);
      return Pass ("RTM connection set up (session" & Natural'Image (S)
                   & ")");
   elsif Same (Kind, "disconnect") then
      if B.Last_Request (S) = EVC_Ports.RTM_Request_T'Pos
                                (EVC_Ports.Request_Release) + 1
        or else B.T_Train_Of (S, 156) >= 0
      then
         Event (EVC_Ports.Connection_Released);
         return Pass ("RTM connection released");
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
                 + (B.Time_Ms - B.Last_Sent_Ms (S)) / 10;
            else
               Stamp := Get_Bits (Data, M.T_Train_At (1), 32);
            end if;
            if RBC_Stamp_Given and then Stamp <= RBC_Stamp then
               Stamp := RBC_Stamp + 1;
            end if;
            Stamp := Stamp mod 2**32;
            Put_Bits (Data, M.T_Train_At (1), 32, Stamp);
            RBC_Stamp := Stamp;
            RBC_Stamp_Given := True;
         end if;
         if M.T_Train_Count >= 2 and then Answered (M.NID) > 0
           and then B.T_Train_Of (S, Answered (M.NID)) >= 0
         then
            Put_Bits (Data, M.T_Train_At (2), 32,
                      Unsigned_64 (B.T_Train_Of (S, Answered (M.NID))));
         end if;
         B.RTM_Input (B.Byte_Array'(EVC_Ports.RTM_Tag_Message,
                                    Unsigned_8 (S)) & Data);
         return Pass ("RTM message " & Nid & " given (session"
                      & Natural'Image (S) & ")");
      end;
   end;
end Radio_Input;
