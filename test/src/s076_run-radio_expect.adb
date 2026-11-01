--  ETCS on-board (EVC)
--  The SUBSET-076 runner: an RTM expectation step (host only).
--
--  Judged against the RTM outputs of the step's observation window
--  (S076_Bench.Radio), in any session:
--
--  expect RTM connect / no-connect            a request to set up a safe
--                                             radio connection (or none)
--  expect RTM disconnect / no-disconnect      a request to release it
--  expect RTM registration / no-registration  a request to register to a
--                                             radio network; NID_MN when
--                                             the line gives a number
--  expect RTM message N [packets p ...] F=v   a message N that decodes as
--                                             a train to track message
--                                             (ETCS_Message.Parse) with
--                                             each packet named ("0/1":
--                                             either) and each field
--                                             named with a value (decimal,
--                                             or a bit pattern of 0, 1 and
--                                             x): a field of packet 0, 1
--                                             or 4 (Packet_Field), else
--                                             the message's own; any
--                                             message N of the window
--  expect RTM no-message N                    no message N
--
--  The radio infill request (153) is E7 (3.9); SA-PERMISSION is not in
--  the port. The failure signatures name the message and what is
--  missing only, so that the report counts the sequences waiting for
--  each message of the on-board.

with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Message;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P1;
with ETCS_Train_Packets.P4;
with ETCS_Train_Packets.P10;
with ETCS_Variables;

separate (S076_Run)
function Radio_Expect (St : Step_T) return Judgement_T is
   use type EVC_Ports.RTM_Request_T;
   use type ETCS_Message.Status_T;
   Kind : constant String := W (3);
   Neg  : constant Boolean := Starts (Kind, "no-");
   Base : constant String :=
     (if Neg then Kind (Kind'First + 3 .. Kind'Last) else Kind);

   function Request_Seen (Code : Natural) return Natural is
   begin
      for I in 1 .. B.Radio_Count loop
         if B.Radio (I).Is_Request and then B.Radio (I).Code = Code then
            return I;
         end if;
      end loop;
      return 0;
   end Request_Seen;

   function Request (R : EVC_Ports.RTM_Request_T; What : String)
     return Judgement_T
   is
      Found : constant Natural :=
        Request_Seen (EVC_Ports.RTM_Request_T'Pos (R) + 1);
   begin
      if Neg then
         return Check (Found = 0, "RTM no request " & What, "one");
      elsif Found = 0 then
         return Fail ("not requested");
      end if;
      if R = EVC_Ports.Request_Registration then
         for K in 4 .. Line.Count loop
            declare
               Wd : constant String := W (K);
            begin
               if Starts (Wd, "NID_MN=")
                 and then Wd'Length > 7
                 and then (for all C of Wd (Wd'First + 7 .. Wd'Last) =>
                             C in '0' .. '9')
               then
                  declare
                     D : constant B.Radio_Out_T := B.Radio (Found);
                     V : constant Natural :=
                       (if D.Length >= 3
                        then Natural (D.Data (1)) * 65536
                             + Natural (D.Data (2)) * 256
                             + Natural (D.Data (3))
                        else 0);
                  begin
                     if V /= Natural'Value (Wd (Wd'First + 7 .. Wd'Last))
                     then
                        return Fail ("NID_MN="
                                     & Wd (Wd'First + 7 .. Wd'Last)
                                     & ", got" & Natural'Image (V));
                     end if;
                  end;
               end if;
            end;
         end loop;
      end if;
      return Pass ("RTM request " & What);
   end Request;

   --  Value matches the expected text: decimal, or a pattern of 0, 1, x
   --  (the most significant bit first, as wide as the pattern); Bits: the
   --  field is a set of bits, its 0/1 text always a pattern (the reason
   --  16 of Q_MARQSTREASON is written 10000); Width: the variable's
   --  length, a text of 0 and 1 exactly as long is a pattern too
   --  (Q_STATUSLRBG=10 is 2, unknown, 7.5.1.137: as decimal it would
   --  exceed the variable)
   function Matches (Value : Unsigned_64; Text : String;
                     Judged : out Boolean;
                     Bits   : Boolean := False;
                     Width  : Natural := 0) return Boolean
   is
      T : constant String :=
        (if Text'Length >= 2 and then Text (Text'First) = '<'
           and then Text (Text'Last) = '>'
         then Text (Text'First + 1 .. Text'Last - 1) else Text);
   begin
      Judged := T'Length > 0;
      if not Judged then
         return True;
      elsif (for all C of T => C in '0' .. '1' | 'x' | 'X')
        and then (Bits
                  or else (T'Length > 1 and then T'Length = Width)
                  or else (T'Length > 1 and then (T (T'First) = '0'
                                                  or else Has (T, "x"))))
      then
         for K in T'Range loop
            declare
               Bit : constant Unsigned_64 :=
                 Shift_Right (Value, T'Last - K) and 1;
            begin
               if (T (K) = '0' and then Bit /= 0)
                 or else (T (K) = '1' and then Bit /= 1)
               then
                  return False;
               end if;
            end;
         end loop;
         return True;
      elsif (for all C of T => C in '0' .. '9') and then T'Length <= 18 then
         return Value = Unsigned_64'Value (T);
      end if;
      Judged := False;
      return True;
   end Matches;

   --  A field of a packet of M by name: the position report (0, 1) and
   --  the error report (4) of the train to track messages, the packets
   --  the sequences name with a field (M_ERROR, V_TRAIN, M_LEVEL), and
   --  the safe consist length of messages 131 and 133 (10);
   --  Found False for another field or packet
   procedure Packet_Field (M     : ETCS_Message.Message_T;
                           Name  : String;
                           Got   : out Unsigned_64;
                           Found : out Boolean)
   is
      P0 : ETCS_Train_Packets.P0.Packet_T;
      P1 : ETCS_Train_Packets.P1.Packet_T;
      P4 : ETCS_Train_Packets.P4.Packet_T;
      P10 : ETCS_Train_Packets.P10.Packet_T;
      OK : Boolean;
      procedure Take (V : Unsigned_64) is
      begin
         Got := V;
         Found := True;
      end Take;
   begin
      Got := 0;
      Found := False;
      for I in 1 .. M.Count loop
         declare
            Rd : ETCS_Bits.Reader (ETCS_Message.Max_Bytes);
         begin
            ETCS_Message.Open_Packet (M, I, Rd);
            case M.Index (I).NID is
               when 0 =>
                  ETCS_Train_Packets.P0.Decode (Rd, P0, OK);
                  if not OK then
                     null;
                  elsif Same (Name, "V_TRAIN") then
                     Take (Unsigned_64 (P0.V_TRAIN));
                  elsif Same (Name, "M_LEVEL") then
                     Take (Unsigned_64 (P0.M_LEVEL));
                  elsif Same (Name, "M_MODE") then
                     Take (Unsigned_64 (P0.M_MODE));
                  end if;
               when 1 =>
                  ETCS_Train_Packets.P1.Decode (Rd, P1, OK);
                  if not OK then
                     null;
                  elsif Same (Name, "V_TRAIN") then
                     Take (Unsigned_64 (P1.V_TRAIN));
                  elsif Same (Name, "M_LEVEL") then
                     Take (Unsigned_64 (P1.M_LEVEL));
                  elsif Same (Name, "M_MODE") then
                     Take (Unsigned_64 (P1.M_MODE));
                  end if;
               when 4 =>
                  ETCS_Train_Packets.P4.Decode (Rd, P4, OK);
                  if OK and then Same (Name, "M_ERROR") then
                     Take (Unsigned_64 (P4.M_ERROR));
                  end if;
               when 10 =>
                  ETCS_Train_Packets.P10.Decode (Rd, P10, OK);
                  if not OK then
                     null;
                  elsif Same (Name, "Q_SAFECONSISTLENGTH") then
                     Take (Unsigned_64 (P10.Q_SAFECONSISTLENGTH));
                  elsif not P10.Has_L_CONSISTFRONTENGINENOM then
                     null;
                  elsif Same (Name, "L_CONSISTFRONTENGINENOM") then
                     Take (Unsigned_64 (P10.L_CONSISTFRONTENGINENOM));
                  elsif Same (Name, "L_CONSISTFRONTENGINEMIN") then
                     Take (Unsigned_64 (P10.L_CONSISTFRONTENGINEMIN));
                  elsif Same (Name, "L_CONSISTFRONTENGINEMAX") then
                     Take (Unsigned_64 (P10.L_CONSISTFRONTENGINEMAX));
                  elsif Same (Name, "L_CONSISTREARENGINENOM") then
                     Take (Unsigned_64 (P10.L_CONSISTREARENGINENOM));
                  elsif Same (Name, "L_CONSISTREARENGINEMIN") then
                     Take (Unsigned_64 (P10.L_CONSISTREARENGINEMIN));
                  elsif Same (Name, "L_CONSISTREARENGINEMAX") then
                     Take (Unsigned_64 (P10.L_CONSISTREARENGINEMAX));
                  end if;
               when others =>
                  null;
            end case;
         end;
         exit when Found;
      end loop;
   end Packet_Field;

   --  The expectation against output Found of the window, message Nid
   function One (Nid : String; Found : Positive) return Judgement_T is
      M      : ETCS_Message.Message_T;
      Status : ETCS_Message.Status_T;
   begin
      declare
         D : constant B.Radio_Out_T := B.Radio (Found);
      begin
         ETCS_Message.Parse (D.Data (1 .. D.Length),
                             ETCS_Catalogue.Train_To_Track,
                             ETCS_Catalogue.RBC, M, Status);
      end;
      if Status /= ETCS_Message.Accepted then
         return Fail (Nid & " does not decode ("
                      & ETCS_Message.Status_T'Image (Status) & ")");
      end if;
      declare
         K : Positive := 5;
      begin
         --  packets p ... (up to the first FIELD=value)
         if Line.Count >= 5 and then Same (W (5), "packets") then
            K := 6;
            while K <= Line.Count
              and then Ada.Strings.Fixed.Index (W (K), "=") = 0
            loop
               declare
                  Alts : constant String := W (K);
                  Any  : Boolean := False;
                  From : Positive := Alts'First;
               begin
                  for P in Alts'First .. Alts'Last + 1 loop
                     if P > Alts'Last or else Alts (P) = '/' then
                        if P > From
                          and then (for all C of Alts (From .. P - 1) =>
                                      C in '0' .. '9')
                          and then P - From <= 3
                        then
                           for J in 1 .. M.Count loop
                              if Natural (M.Index (J).NID)
                                 = Natural'Value (Alts (From .. P - 1))
                              then
                                 Any := True;
                              end if;
                           end loop;
                        else
                           Any := True;   -- not a number: not judged
                        end if;
                        From := P + 1;
                     end if;
                  end loop;
                  if not Any then
                     return Fail (Nid & ": packet "
                                  & Alts & " missing");
                  end if;
               end;
               K := K + 1;
            end loop;
         end if;
         --  FIELD=value of the message's own variables
         for F in K .. Line.Count loop
            declare
               Wd : constant String := W (F);
               Eq : constant Natural := Ada.Strings.Fixed.Index (Wd, "=");
               Var : ETCS_Variables.Variable_T;
               Known : Boolean := False;
               Judged : Boolean;
            begin
               if Eq > Wd'First then
                  for V in ETCS_Variables.Variable_T loop
                     if Same (ETCS_Variables.Variable_T'Image (V),
                              Wd (Wd'First .. Eq - 1))
                     then
                        Var := V;
                        Known := True;
                     end if;
                  end loop;
                  if Known then
                     declare
                        Got : Unsigned_64;
                        In_Packet : Boolean;
                     begin
                        --  a packet's field, else the message's own
                        Packet_Field (M, Wd (Wd'First .. Eq - 1),
                                      Got, In_Packet);
                        if not In_Packet then
                           Got := ETCS_Message.Value (M, Var);
                        end if;
                        if not Matches
                                 (Got, Wd (Eq + 1 .. Wd'Last), Judged,
                                  Bits => ETCS_Variables."="
                                            (Var,
                                             ETCS_Variables.Q_MARQSTREASON),
                                  Width => Natural
                                    (ETCS_Variables.Bits (Var)))
                        then
                           return Fail (Nid & ": "
                                        & Wd (Wd'First .. Eq - 1) & "="
                                        & Wd (Eq + 1 .. Wd'Last));
                        elsif not Judged then
                           Note_Gap (Nid & "." & Wd (Wd'First .. Eq - 1));
                        end if;
                     end;
                  else
                     Note_Gap (Nid & "." & Wd (Wd'First .. Eq - 1));
                  end if;
               end if;
            end;
         end loop;
      end;
      return Pass ("RTM message " & Nid);
   end One;

   --  Every message Nid of the window is a candidate: the first that
   --  meets the expectation passes it, else the first one's failure
   --  (a 136 by its period may come before the one of the event); only
   --  those of the session the step's comment names (Named_Session),
   --  not for a JRU record judged by its message
   function Message (Nid : String) return Judgement_T is
      First : Judgement_T;
      Seen  : Boolean := False;
   begin
      if Nid = "153" then
         return NJ (R_Radio_Infill, "RTM message 153 (radio infill request)");
      end if;
      Expect_Session :=
        (if Judging_JRU then 0 else Named_Session (Image (St.Comment)));
      for I in 1 .. B.Radio_Count loop
         if not B.Radio (I).Is_Request and then Img (B.Radio (I).Code) = Nid
           and then (Expect_Session = 0
                     or else B.Radio (I).Session = Expect_Session)
           --  B270: a message sent before the window's input (kept listed
           --  for the positive expectations, Keep_Radio) is no answer to
           --  it: 4080428_01 step 134, the 136 of step 129 before the 38
           and then not (Neg and then B.Radio (I).At_Ms
                                      < Unsigned_64'Max (B.Window_Ms,
                                                         Group_Input_Ms))
           --  a sending an earlier step matched is no candidate
           --  (S076_Run.Matched)
           and then (Neg or else Judging_JRU
                     or else not Was_Matched (B.Radio (I)))
         then
            if Neg then
               return Check (False, "RTM no message " & Nid, "sent");
            end if;
            declare
               J : constant Judgement_T := One (Nid, I);
            begin
               if J.Verdict = Passed and then Judging_JRU then
                  return J;
               elsif J.Verdict = Passed then
                  Matched_Last := Matched_Last mod Max_Matched + 1;
                  Matched (Matched_Last) :=
                    (Session => B.Radio (I).Session,
                     Code    => B.Radio (I).Code,
                     At_Ms   => B.Radio (I).At_Ms);
                  return Pass ("RTM message " & Nid & " sent at t="
                               & Unsigned_64'Image (B.Radio (I).At_Ms)
                               & " ms (session"
                               & Natural'Image (B.Radio (I).Session) & ")");
               elsif not Seen then
                  First := J;
                  Seen := True;
               end if;
            end;
         end if;
      end loop;
      if Neg then
         return Check (True, "RTM no message " & Nid, "sent");
      elsif not Seen and then Expect_Session > 0 then
         return Fail (Nid & " not sent to session"
                      & Natural'Image (Expect_Session) & " ("
                      & (if Expect_Session = RBC_Accepting then "Accepting"
                         else "Handing Over") & " RBC)");
      elsif not Seen then
         return Fail (Nid & " not sent");
      end if;
      return First;
   end Message;
begin
   if Same (Base, "connect") then
      return Request (EVC_Ports.Request_Set_Up, "connect");
   elsif Same (Base, "disconnect") then
      return Request (EVC_Ports.Request_Release, "disconnect");
   elsif Same (Base, "registration") then
      return Request (EVC_Ports.Request_Registration, "registration");
   elsif Same (Base, "message") and then Line.Count >= 4 then
      return Message (W (4));
   end if;
   return NJ (R_Not_Modelled, "RTM " & Kind & " (not in the port)");
end Radio_Expect;
