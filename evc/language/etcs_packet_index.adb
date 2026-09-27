--  ETCS on-board (EVC)
--  The index of the packets of a telegram or a radio message,
--  implementation.

with Interfaces; use Interfaces;

package body ETCS_Packet_Index
  with SPARK_Mode => On
is

   ----------
   -- Scan --
   ----------

   procedure Scan (Direction : Direction_T;
                   R         : in out Reader;
                   E         : out Entry_T;
                   Result    : out Scan_Result_T)
   is
      Start  : constant Bit_Count := Position (R);
      V      : Unsigned_64;
      Length : Natural;
      OK     : Boolean;
   begin
      E := (Offset => Start, others => <>);
      if Failed (R) or else Remaining (R) < 8 then
         Result := Truncated;
         return;
      end if;
      Read (R, 8, V);
      E.NID := To_NID_PACKET (V);
      E.Kind := Kind (Direction, Natural (E.NID));

      --  7.4.2.39: the end of the information
      if Direction = Track_To_Train and then E.NID = 255 then
         E.Length := 8;
         Result := End_Of_Data;
         return;
      end if;

      --  7.3.3.5: a packet without L_PACKET is as long as it decodes
      if E.Kind /= Unknown and then not Has_Length (E.Kind) then
         declare
            Probe : Reader := R;
         begin
            Seek (Probe, Start);
            Check (E.Kind, Probe, OK);
            if OK
              and then Position (Probe) > Start
              and then Position (Probe) <= Limit (R)
            then
               E.Length := Position (Probe) - Start;
            end if;
         end;
         if E.Length = 0 then
            Result := Truncated;
         else
            Seek (R, Start + E.Length);
            Result := (if Failed (R) then Truncated else Scanned);
         end if;
         return;
      end if;

      --  7.3.3.2: NID_PACKET, Q_DIR (track to train), L_PACKET
      if Direction = Track_To_Train then
         Read (R, 2, V);
         E.Q_DIR := To_Q_DIR (V);
      end if;
      Read (R, 13, V);
      if Failed (R) then
         Result := Truncated;
         return;
      end if;
      Length := Natural (V);
      if Length < Header_Bits (Direction) then
         Result := Bad_Length;
         return;
      end if;
      if Length > Limit (R) - Start then
         Result := Truncated;
         return;
      end if;
      E.Length := Length;

      --  a known packet decodes in exactly its L_PACKET bits: checked on
      --  a copy of the reader limited to the packet
      if E.Kind /= Unknown then
         declare
            Probe : Reader := R;
         begin
            Seek (Probe, Start);
            Set_Limit (Probe, Start + Length);
            pragma Warnings (GNATprove, Off, "*set by ""Check"" but not used",
                             Reason => "only whether the packet decodes");
            Check (E.Kind, Probe, OK);
            pragma Warnings (GNATprove, On, "*set by ""Check"" but not used");
         end;
         if not OK then
            Result := Undecodable;
            return;
         end if;
      end if;

      Seek (R, Start + Length);
      Result := (if Failed (R) then Truncated else Scanned);
   end Scan;

end ETCS_Packet_Index;
