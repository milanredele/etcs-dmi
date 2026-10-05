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
--                                             either) and each field of
--                                             the message named with a
--                                             value (decimal, or a bit
--                                             pattern of 0, 1 and x)
--  expect RTM no-message N                    no message N
--
--  The radio infill request (153) is E7 (3.9); SA-PERMISSION is not in
--  the port. The failure signatures name the message and what is
--  missing only, so that the report counts the sequences waiting for
--  each message of the on-board.

with ETCS_Catalogue;
with ETCS_Message;
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
   --  (the most significant bit first, as wide as the pattern)
   function Matches (Value : Unsigned_64; Text : String;
                     Judged : out Boolean) return Boolean
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
        and then (T'Length > 1 and then (T (T'First) = '0'
                                         or else Has (T, "x")))
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

   function Message (Nid : String) return Judgement_T is
      Found  : Natural := 0;
      M      : ETCS_Message.Message_T;
      Status : ETCS_Message.Status_T;
   begin
      if Nid = "153" then
         return NJ (R_Radio_Infill, "RTM message 153 (radio infill request)");
      end if;
      for I in 1 .. B.Radio_Count loop
         if not B.Radio (I).Is_Request and then Img (B.Radio (I).Code) = Nid
         then
            Found := I;
            exit;
         end if;
      end loop;
      if Neg then
         return Check (Found = 0, "RTM no message " & Nid, "sent");
      elsif Found = 0 then
         return Fail (Nid & " not sent");
      end if;
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
                        Got : constant Unsigned_64 :=
                          ETCS_Message.Value (M, Var);
                     begin
                        if not Matches (Got, Wd (Eq + 1 .. Wd'Last), Judged)
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
   end Message;
begin
   if Handover_Step > 0 and then St.Number > Handover_Step then
      return NJ (R_Handover, "RTM " & Kind & " after the RBC transition"
                 & " order");
   elsif Same (Base, "connect") then
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
