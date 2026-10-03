--  ETCS on-board (EVC)
--  The Euroradio message, implementation.

package body ETCS_Message
  with SPARK_Mode => On
is

   -----------
   -- Value --
   -----------

   function Value (M : Message_T; Var : Variable_T) return Unsigned_64 is
   begin
      if M.Kind /= Unknown then
         for I in 1 .. Field_Count (M.Kind) loop
            pragma Loop_Invariant (True);  --  nothing needed after the loop
            if Fields (M.Kind) (I) = Var then
               return M.Values (I);
            end if;
         end loop;
      end if;
      return 0;
   end Value;

   --  The packet NID_PACKET = NID is the one of Rule
   function Matches (Rule : Rule_T; NID : NID_PACKET_T) return Boolean is
     (Natural (Rule.First) = Natural (NID)
      or else Natural (Rule.Second) = Natural (NID));

   -----------
   -- Parse --
   -----------

   procedure Parse (Data      : Byte_Array;
                    Direction : Direction_T;
                    Sender    : Sender_T;
                    M         : out Message_T;
                    Status    : out Status_T)
   is
      R         : Reader (Max_Bytes);
      V         : Unsigned_64;
      E         : Entry_T;
      Result    : Scan_Result_T;
      K         : Message_Kind_T;
      First     : Rule_Index_T;
      Last      : Natural;
      Mandatory : Natural;   -- the next rule to look at as mandatory
      Expect    : Natural;   -- the rule of the next packet, 0 if optional
      Found     : Natural;
      Optionals : Boolean := False;
      Repeat    : Boolean;
   begin
      M := (Direction => Direction,
            Kind      => Unknown,
            Values    => (others => 0),
            Index     => (others => (others => <>)),
            Data      => (others => 0),
            others    => 0);
      if Data'Length > Max_Bytes then
         Status := Bad_Length;
         return;
      end if;
      Load (R, Data, 8 * Data'Length);
      M.Data (1 .. Data'Length) := Data;
      M.Length := Data'Length;

      --  NID_MESSAGE, L_MESSAGE (8.4.4.2)
      Read (R, 8, V);
      M.Values (1) := V;
      K := Kind (Direction, Natural (V));
      Read (R, 10, V);
      M.Values (2) := V;
      if Failed (R) then
         Status := Truncated;
         return;
      end if;
      if Natural (V) /= Data'Length then
         Status := Bad_Length;
         return;
      end if;
      if K = Unknown then
         Status := Unknown_Message;
         return;
      end if;
      M.Kind := K;
      --  8.5.3 "Transmitted by" (8.5.2 "Transmitted to")
      if not Sent_By (K) (Sender) then
         Status := Wrong_Sender;
         return;
      end if;

      --  the other variables of the message, header included
      for I in 3 .. Field_Count (K) loop
         pragma Loop_Invariant (Limit (R) = 8 * Data'Length);
         Read (R, Bits (Fields (K) (I)), V);
         M.Values (I) := V;
      end loop;
      if Failed (R) then
         Status := Truncated;
         return;
      end if;
      --  3.16.1.1.1: no spare value
      for I in 1 .. Field_Count (K) loop
         pragma Loop_Invariant (True);  --  nothing needed after the loop
         if not Valid_Code (Fields (K) (I), M.Values (I)) then
            Status := Invalid_Value;
            return;
         end if;
      end loop;

      --  the rules of its packets
      First := First_Rule (K);
      Last := Natural'Min (First + Rule_Count (K) - 1, Total_Rules);
      for J in First .. Last loop
         if Rules (J).Optional then
            Optionals := True;
         end if;
      end loop;

      Mandatory := First;
      for Step in 1 .. Max_Packets + 1 loop
         pragma Loop_Invariant (M.Kind = K and then M.Length = Data'Length);
         pragma Loop_Invariant (Limit (R) = 8 * M.Length);
         pragma Loop_Invariant (M.Unknown <= M.Count);
         pragma Loop_Invariant (Mandatory >= First);
         pragma Loop_Invariant
           (for all I in 1 .. M.Count =>
              M.Index (I).Length > 0
              and then M.Index (I).Offset + M.Index (I).Length
                       <= Position (R));
         Expect :=
           (if Mandatory <= Last and then not Rules (Mandatory).Optional
            then Mandatory else 0);
         --  what is left is the padding (8.4.4.5)
         if Remaining (R) < 8 then
            Status := (if Expect /= 0 then Missing_Packet else Accepted);
            return;
         end if;
         Scan (Direction, R, E, Result);
         case Result is
            when End_Of_Data =>
               --  packet 255 is not a packet of radio messages
               Status := Packet_Not_Allowed;
               return;
            when Truncated =>
               Status := Truncated;
               return;
            when Bad_Length | Undecodable =>
               Status := Packet_Structure;
               return;
            when Invalid_Value =>
               Status := Invalid_Value;
               return;
            when Scanned =>
               --  7.4.2 "Transmitted by", 7.4.3 "Transmitted to"
               if E.Kind /= Unknown
                 and then not ETCS_Catalogue.Sent_By (E.Kind) (Sender)
               then
                  Status := Wrong_Sender;
                  return;
               end if;
               if Expect /= 0 then
                  --  8.4.1.2: the mandatory packets in their order
                  if not Matches (Rules (Expect), E.NID) then
                     Status := Missing_Packet;
                     return;
                  end if;
                  Repeat := Rules (Expect).Repeat;
                  Mandatory := Mandatory + 1;
               else
                  Found := 0;
                  for J in First .. Last loop
                     if Rules (J).Optional
                       and then Matches (Rules (J), E.NID)
                       and then Rules (J).From (Sender)
                     then
                        Found := J;
                        exit;
                     end if;
                  end loop;
                  if Found /= 0 then
                     Repeat := Rules (Found).Repeat;
                  elsif E.Kind = Unknown and then Optionals then
                     Repeat := True;
                  else
                     Status := Packet_Not_Allowed;
                     return;
                  end if;
               end if;
               --  8.4.1.4, 8.4.1.5: one instance (per direction), unless
               --  the rule allows several
               if not Repeat then
                  for I in 1 .. M.Count loop
                     if M.Index (I).NID = E.NID
                       and then Same_Direction (M.Index (I).Q_DIR, E.Q_DIR)
                     then
                        Status := Duplicate_Packet;
                        return;
                     end if;
                  end loop;
               end if;
               if M.Count = Max_Packets then
                  Status := Too_Many_Packets;
                  return;
               end if;
               M.Count := M.Count + 1;
               M.Index (M.Count) := E;
               if E.Kind = Unknown then
                  M.Unknown := M.Unknown + 1;
               end if;
         end case;
      end loop;
      Status := Too_Many_Packets;
   end Parse;

   -----------------
   -- Open_Packet --
   -----------------

   procedure Open_Packet (M : Message_T; I : Positive; R : in out Reader) is
      E : constant Entry_T := M.Index (I);
   begin
      Load (R, M.Data (1 .. M.Length), 8 * M.Length);
      Seek (R, E.Offset);
      Set_Limit (R, E.Offset + E.Length);
   end Open_Packet;

   ------------------
   -- Write_Fields --
   ------------------

   procedure Write_Fields (W      : in out Writer;
                           Kind   : Known_Message_T;
                           Values : Value_Array;
                           OK     : out Boolean)
   is
   begin
      Write (W, 8, Unsigned_64 (ETCS_Message_Catalogue.NID_Of (Kind)));
      Write (W, 10, 0);
      for I in 3 .. Field_Count (Kind) loop
         pragma Loop_Invariant (True);  --  nothing needed after the loop
         Write (W, Bits (Fields (Kind) (I)), Values (I));
      end loop;
      OK := not Failed (W);
   end Write_Fields;

   ------------
   -- Finish --
   ------------

   procedure Finish (W : in out Writer; OK : out Boolean) is
   begin
      if Position (W) mod 8 /= 0 then
         Fill (W, 8 - Position (W) mod 8, One => False);
      end if;
      OK := not Failed (W)
        and then Position (W) mod 8 = 0
        and then Position (W) / 8 <= Max_Bytes;
      if OK then
         Patch (W, 8, 10, Unsigned_64 (Position (W) / 8));
         OK := not Failed (W);
      end if;
   end Finish;

end ETCS_Message;
