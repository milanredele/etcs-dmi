--  ETCS on-board (EVC)
--  The Eurobalise telegram, implementation.

with Interfaces;     use Interfaces;
with ETCS_Catalogue; use ETCS_Catalogue;

package body ETCS_Telegram
  with SPARK_Mode => On
is

   --  8.4.1.4.1 to 8.4.1.4.9: the packets a balise group message may
   --  carry more than once for one direction (44, 65, 66, 88, 254, 145,
   --  6; packet 0 is first or nowhere, 8.4.2.3)
   function May_Repeat (NID : NID_PACKET_T) return Boolean is
     (NID in 6 | 44 | 65 | 66 | 88 | 145 | 254);

   -----------
   -- Parse --
   -----------

   procedure Parse (Data   : Byte_Array;
                    Bits   : Natural;
                    T      : out Telegram_T;
                    Status : out Status_T)
   is
      R      : Reader (Max_Bytes);
      V      : Unsigned_64;
      E      : Entry_T;
      Result : Scan_Result_T;
      H      : Header_T renames T.Header;
   begin
      T := (Header => (others => <>),
            Index  => (others => (others => <>)),
            Data   => (others => 0),
            others => 0);
      if Bits > Long_Bits
        or else Data'Length > Max_Bytes
        or else not Holds (Data, Bits)
      then
         Status := Too_Long;
         return;
      end if;
      --  SUBSET-036 4.3.1.2: 210 user bits (short) or 830 (long)
      if Bits not in Short_Bits | Long_Bits then
         Status := Bad_Length;
         return;
      end if;
      Load (R, Data, Bits);
      T.Data (1 .. Data'Length) := Data;
      T.Bits := Bits;

      --  8.4.2.1
      Read (R, 1, V);
      H.Q_UPDOWN := To_Q_UPDOWN (V);
      Read (R, 7, V);
      H.M_VERSION := To_M_VERSION (V);
      Read (R, 1, V);
      H.Q_MEDIA := To_Q_MEDIA (V);
      Read (R, 3, V);
      H.N_PIG := To_N_PIG (V);
      Read (R, 3, V);
      H.N_TOTAL := To_N_TOTAL (V);
      Read (R, 2, V);
      H.M_DUP := To_M_DUP (V);
      Read (R, 8, V);
      H.M_MCOUNT := To_M_MCOUNT (V);
      Read (R, 10, V);
      H.NID_C := To_NID_C (V);
      Read (R, 14, V);
      H.NID_BG := To_NID_BG (V);
      Read (R, 1, V);
      H.Q_LINK := To_Q_LINK (V);
      if Failed (R) then
         Status := Truncated;
         return;
      end if;
      --  up-link (7.5.1.142), balise (7.5.1.119), in its group
      --  (7.5.1.81, 7.5.1.82), M_DUP not spare (7.5.1.63)
      if H.Q_UPDOWN /= 1
        or else H.Q_MEDIA /= 0
        or else Natural (H.N_PIG) > Natural (H.N_TOTAL)
        or else H.M_DUP > 2
      then
         Status := Bad_Header;
         return;
      end if;
      if not Supported (H.M_VERSION) then
         Status := Unsupported_Version;
         return;
      end if;

      --  the packets, to packet 255
      for Step in 1 .. Max_Packets + 1 loop
         pragma Loop_Invariant (T.Bits = Bits);
         pragma Loop_Invariant (Limit (R) = Bits);
         pragma Loop_Invariant (T.Unknown <= T.Count);
         pragma Loop_Invariant
           (for all I in 1 .. T.Count =>
              T.Index (I).Length > 0
              and then T.Index (I).Offset + T.Index (I).Length
                       <= Position (R));
         Scan (Track_To_Train, R, E, Result);
         case Result is
            when End_Of_Data =>
               T.End_Bit := E.Offset;
               Status := Accepted;
               return;
            when Truncated =>
               --  nothing left for a NID_PACKET: packet 255 is missing
               Status := (if E.Offset + 8 > Bits then No_End else Truncated);
               return;
            when Bad_Length | Undecodable =>
               Status := Packet_Structure;
               return;
            when Invalid_Value =>
               Status := Invalid_Value;
               return;
            when Scanned =>
               --  7.4.2: a packet the balise may transmit ("Transmitted
               --  by"; 7.3.3.10)
               if E.Kind /= Unknown and then not Sent_By (E.Kind) (Balise)
               then
                  Status := Wrong_Sender;
                  return;
               end if;
               --  8.4.2.3: packet 0 is the first packet
               if E.Kind = Track_P0 and then T.Count > 0 then
                  Status := Packet_Structure;
                  return;
               end if;
               --  8.4.1.4: one instance per packet type and direction
               if E.Kind /= Unknown and then not May_Repeat (E.NID) then
                  for I in 1 .. T.Count loop
                     if T.Index (I).NID = E.NID
                       and then Same_Direction (T.Index (I).Q_DIR, E.Q_DIR)
                     then
                        Status := Duplicate_Packet;
                        return;
                     end if;
                  end loop;
               end if;
               if T.Count = Max_Packets then
                  Status := Too_Many_Packets;
                  return;
               end if;
               T.Count := T.Count + 1;
               T.Index (T.Count) := E;
               if E.Kind = Unknown then
                  T.Unknown := T.Unknown + 1;
               end if;
         end case;
      end loop;
      Status := Too_Many_Packets;
   end Parse;

   -----------------
   -- Open_Packet --
   -----------------

   procedure Open_Packet (T : Telegram_T; I : Positive; R : in out Reader) is
      E : constant Entry_T := T.Index (I);
   begin
      Load (R, T.Data, T.Bits);
      Seek (R, E.Offset);
      Set_Limit (R, E.Offset + E.Length);
   end Open_Packet;

   ------------------
   -- Write_Header --
   ------------------

   procedure Write_Header (W : in out Writer; H : Header_T) is
   begin
      Write (W, 1, Code (H.Q_UPDOWN));
      Write (W, 7, Code (H.M_VERSION));
      Write (W, 1, Code (H.Q_MEDIA));
      Write (W, 3, Code (H.N_PIG));
      Write (W, 3, Code (H.N_TOTAL));
      Write (W, 2, Code (H.M_DUP));
      Write (W, 8, Code (H.M_MCOUNT));
      Write (W, 10, Code (H.NID_C));
      Write (W, 14, Code (H.NID_BG));
      Write (W, 1, Code (H.Q_LINK));
   end Write_Header;

   ------------
   -- Finish --
   ------------

   procedure Finish (W : in out Writer; User_Bits : Natural; OK : out Boolean)
   is
   begin
      Write (W, 8, 255);
      OK := User_Bits in Short_Bits | Long_Bits
        and then not Failed (W)
        and then Position (W) <= User_Bits;
      if OK then
         Fill (W, User_Bits - Position (W), One => True);
         OK := not Failed (W);
      end if;
   end Finish;

end ETCS_Telegram;
