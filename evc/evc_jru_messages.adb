--  ETCS on-board (EVC)

package body EVC_JRU_Messages
  with SPARK_Mode => On
is

   function Leap (Year : Natural) return Boolean is
     (Year mod 4 = 0 and then (Year mod 100 /= 0 or else Year mod 400 = 0));

   function Month_Days (Year : Natural; Month : Positive) return Positive is
     (case Month is
         when 2 => (if Leap (Year) then 29 else 28),
         when 4 | 6 | 9 | 11 => 30,
         when others => 31);

   procedure Set_Time (H       : in out Header_T;
                       Seconds : Unsigned_32;
                       Ms      : Natural)
   is
      Total : constant Unsigned_64 :=
        Unsigned_64 (Seconds) + Unsigned_64 (Ms / 1000);
      Days  : Natural := Natural (Total / 86_400);
      Rest  : constant Natural := Natural (Total mod 86_400);
      Year  : Natural := 2000;
      Month : Positive := 1;
   begin
      while Year < 2099 loop
         pragma Loop_Invariant (Year in 2000 .. 2098);
         pragma Loop_Variant (Increases => Year);
         exit when Days < (if Leap (Year) then 366 else 365);
         Days := Days - (if Leap (Year) then 366 else 365);
         Year := Year + 1;
      end loop;
      for M in 1 .. 11 loop
         pragma Loop_Invariant (Month = M);
         exit when Days < Month_Days (Year, M);
         Days := Days - Month_Days (Year, M);
         Month := M + 1;
      end loop;
      if Days >= Month_Days (Year, Month) then
         --  beyond 2099: the date unknown (4.2.3.3)
         H.Year := 127;
         H.Month := 15;
         H.Day := 0;
      else
         H.Year := Year - 2000;
         H.Month := Month;
         H.Day := Days + 1;
      end if;
      H.Hour := Rest / 3600;
      H.Minutes := Rest / 60 mod 60;
      H.Seconds := Rest mod 60;
      --  TTS: 50 ms steps (4.2.3.4)
      H.TTS := Ms mod 1000 / 50;
   end Set_Time;

   procedure Put_Bits (Buf   : in out Byte_Array;
                       Pos   : in out Natural;
                       Value : Unsigned_64;
                       Bits  : Width_T)
   is
      Start : constant Natural := Pos;
   begin
      for I in reverse 0 .. Bits - 1 loop
         pragma Loop_Invariant (Pos = Start + (Bits - 1 - I));
         declare
            Index : constant Natural := Buf'First + Pos / 8;
            Mask  : constant Byte := Shift_Left (1, 7 - Pos mod 8);
         begin
            if (Shift_Right (Value, I) and 1) = 1 then
               Buf (Index) := Buf (Index) or Mask;
            else
               Buf (Index) := Buf (Index) and not Mask;
            end if;
         end;
         Pos := Pos + 1;
      end loop;
   end Put_Bits;

   procedure Put_Reference (Buf : in out Byte_Array;
                            Pos : in out Natural;
                            R   : Reference_T)
     with Global => null,
          Pre  => Buf'Length <= 2**16
                  and then Pos <= 8 * Buf'Length
                  and then 75 <= 8 * Buf'Length - Pos,
          Post => Pos = Pos'Old + 75
   is
   begin
      Put_Bits (Buf, Pos, Unsigned_64 (R.Q_Scale), 2);
      Put_Bits (Buf, Pos, Unsigned_64 (R.NID), 24);
      Put_Bits (Buf, Pos, Unsigned_64 (R.D), 15);
      Put_Bits (Buf, Pos, Unsigned_64 (R.Q_Dir), 2);
      Put_Bits (Buf, Pos, Unsigned_64 (R.Q_D), 2);
      Put_Bits (Buf, Pos, Unsigned_64 (R.Over), 15);
      Put_Bits (Buf, Pos, Unsigned_64 (R.Under), 15);
   end Put_Reference;

   procedure Put_Header (Buf : in out Byte_Array;
                         Pos : in out Natural;
                         NID : Byte;
                         H   : Header_T)
   is
   begin
      Put_Bits (Buf, Pos, Unsigned_64 (NID), 8);
      Put_Bits (Buf, Pos, 0, 11);
      Put_Bits (Buf, Pos, Unsigned_64 (H.Year), 7);
      Put_Bits (Buf, Pos, Unsigned_64 (H.Month), 4);
      Put_Bits (Buf, Pos, Unsigned_64 (H.Day), 5);
      Put_Bits (Buf, Pos, Unsigned_64 (H.Hour), 5);
      Put_Bits (Buf, Pos, Unsigned_64 (H.Minutes), 6);
      Put_Bits (Buf, Pos, Unsigned_64 (H.Seconds), 6);
      Put_Bits (Buf, Pos, Unsigned_64 (H.TTS), 5);
      Put_Reference (Buf, Pos, H.SOLR);
      Put_Bits (Buf, Pos, Unsigned_64 (H.Q_LRBG), 2);
      if H.Q_LRBG = 2 then
         Put_Reference (Buf, Pos, H.LRBG);
      end if;
      Put_Bits (Buf, Pos, Unsigned_64 (H.V_Train), 10);
      for I in H.Driver_Id'Range loop
         pragma Loop_Invariant
           (Pos = Pos'Loop_Entry + 8 * (I - H.Driver_Id'First));
         Put_Bits (Buf, Pos, Unsigned_64 (H.Driver_Id (I)), 8);
      end loop;
      Put_Bits (Buf, Pos, Unsigned_64 (H.NID_Engine), 24);
      Put_Bits (Buf, Pos, Unsigned_64 (H.M_Version), 7);
      Put_Bits (Buf, Pos, Unsigned_64 (H.M_Level), 3);
      Put_Bits (Buf, Pos, Unsigned_64 (H.M_Mode), 5);
   end Put_Header;

   procedure Put_Length (Buf : in out Byte_Array; Length : Natural) is
      L : constant Natural := Natural'Min (Length, 2047);
   begin
      Buf (Buf'First + 1) := Byte (L / 8);
      Buf (Buf'First + 2) :=
        (Buf (Buf'First + 2) and 16#1F#) or Byte (L mod 8 * 32);
   end Put_Length;

   function Get_Bits (P      : Byte_Array;
                      At_Bit : Natural;
                      Bits   : Width_T) return Unsigned_64
   is
      V : Unsigned_64 := 0;
   begin
      for I in 0 .. Bits - 1 loop
         pragma Loop_Invariant (True);
         V := Shift_Left (V, 1);
         if At_Bit <= 8 * P'Length - 1 - I
           and then (Shift_Right (P (P'First + (At_Bit + I) / 8),
                                  7 - (At_Bit + I) mod 8) and 1) = 1
         then
            V := V or 1;
         end if;
      end loop;
      return V;
   end Get_Bits;

   --  Get_Bits as a number of at most Max (2**Bits - 1)
   function Get (P : Byte_Array; At_Bit : Natural; Bits : Width_T;
                 Max : Natural) return Natural
     with Pre  => P'Length <= 2**16,
          Post => Get'Result <= Max
   is
      V : constant Unsigned_64 := Get_Bits (P, At_Bit, Bits);
   begin
      if V >= Unsigned_64 (Max) then
         return Max;
      end if;
      return Natural'Min (Natural (V), Max);
   end Get;

   function Is_Message (P : Byte_Array) return Boolean is
     (8 * P'Length >= Min_Header_Bits
      and then Get (P, 8, 11, 2047) = P'Length
      and then (Get (P, 132, 2, 3) /= 2
                or else 8 * P'Length >= Max_Header_Bits));

   function Body_Bit (P : Byte_Array) return Natural is
     (if Get (P, 132, 2, 3) = 2 then Max_Header_Bits else Min_Header_Bits);

   procedure Get_Reference (P : Byte_Array; At_Bit : Natural;
                            R : out Reference_T)
     with Global => null,
          Pre => P'Length <= 2**16 and then At_Bit <= Max_Header_Bits
   is
   begin
      R := (Q_Scale => Get (P, At_Bit, 2, 3),
            NID     => Get (P, At_Bit + 2, 24, 16777215),
            D       => Get (P, At_Bit + 26, 15, 32767),
            Q_Dir   => Get (P, At_Bit + 41, 2, 3),
            Q_D     => Get (P, At_Bit + 43, 2, 3),
            Over    => Get (P, At_Bit + 45, 15, 32767),
            Under   => Get (P, At_Bit + 60, 15, 32767));
   end Get_Reference;

   procedure Get_Header (P : Byte_Array; H : out Header_T) is
      B : Natural;
   begin
      H := (others => <>);
      if not Is_Message (P) then
         return;
      end if;
      H.Year := Get (P, 19, 7, 127);
      H.Month := Get (P, 26, 4, 15);
      H.Day := Get (P, 30, 5, 31);
      H.Hour := Get (P, 35, 5, 31);
      H.Minutes := Get (P, 40, 6, 63);
      H.Seconds := Get (P, 46, 6, 63);
      H.TTS := Get (P, 52, 5, 31);
      Get_Reference (P, 57, H.SOLR);
      H.Q_LRBG := Get (P, 132, 2, 3);
      B := 134;
      if H.Q_LRBG = 2 then
         Get_Reference (P, 134, H.LRBG);
         B := 209;
      end if;
      H.V_Train := Get (P, B, 10, 1023);
      for I in H.Driver_Id'Range loop
         pragma Loop_Invariant (True);
         H.Driver_Id (I) := Byte (Get (P, B + 10 + 8 * (I - 1), 8, 255));
      end loop;
      H.NID_Engine := Get (P, B + 138, 24, 16777215);
      H.M_Version := Get (P, B + 162, 7, 127);
      H.M_Level := Get (P, B + 169, 3, 7);
      H.M_Mode := Get (P, B + 172, 5, 31);
   end Get_Header;

   function View (P : Byte_Array) return View_T is
      B : constant Natural := Body_Bit (P);
      function F (Offset : Natural; Bits : Width_T) return Byte is
        (Byte (Get (P, B + Offset, Bits, 255)))
        with Pre => P'Length <= 2**16 and then Bits <= 8
                    and then Offset <= 64;
      Id : Natural;
   begin
      if not Is_Message (P) then
         return (others => <>);
      end if;
      case P (P'First) is
         when NID_Proprietary =>
            return (F (0, 8), F (8, 8), F (16, 8), F (24, 8));
         when NID_Driver_Actions =>
            return (11, F (0, 8), 0, 0);
         when NID_Radio_Error =>
            return (13, F (24, 8), 0, 0);
         when NID_SDM =>
            return (21, F (0, 2), F (2, 3), 0);
         when NID_RBC_Entry =>
            if F (0, 2) >= 2 then
               Id := Get (P, B + 12, 14, 16383);
               return (124, F (0, 2), Byte (Id / 256), Byte (Id mod 256));
            end if;
            return (124, F (0, 2), 0, 0);
         when NID_Sleeping | NID_Passive_SH | NID_Remote_SH =>
            return (P (P'First), F (0, 1), 0, 0);
         when NID_Non_Leading =>
            return (132, F (0, 1), 0, 0);
         when NID_Direction =>
            return (39, F (0, 2), 0, 0);
         when NID_Cab_Status =>
            return (38, F (0, 1), F (1, 1),
                    (if F (1, 1) = 1 then F (2, 1) else 0));
         when NID_Network =>
            return (48, F (0, 8), F (8, 8), F (16, 8));
         when NID_Telegram =>
            --  the identity of the group from the telegram's header
            --  (SUBSET-026 7.4.2.1: NID_C at bit 25, NID_BG at bit 35)
            Id := Get (P, B + 25, 10, 1023) * 2**14
                  + Get (P, B + 35, 14, 16383);
            return (2, Byte (Id mod 256), Byte (Id / 256 mod 256),
                    Byte (Id / 65536 mod 256));
         when NID_Train_Data =>
            --  event 41 kind 3: L_TRAIN / 100, M_BRAKE_PERCENTAGE / 2
            --  (0 for a gamma train)
            return (41, 3, Byte (Get (P, B + 26, 12, 4095) / 100),
                    (if F (57, 1) = 0 then F (58, 8) / 2 else 0));
         when NID_SR_Data =>
            --  event 41 kind 11: V_SR / 5, D_SR / 100 at most 255
            return (41, 11, Byte (Get (P, B + 17, 10, 1023) / 5),
                    Byte (Natural'Min (Get (P, B, 17, 131_071) / 100,
                                       255)));
         when NID_TRN =>
            --  event 41 kind 2: the number of digits before an F
            Id := 0;
            while Id < 8 and then Get (P, B + 4 * Id, 4, 15) /= 15 loop
               pragma Loop_Invariant (Id < 8);
               pragma Loop_Variant (Increases => Id);
               Id := Id + 1;
            end loop;
            return (41, 2, Byte (Id), 0);
         when NID_Cold_Movement =>
            return (if F (0, 2) = 1 then (9, 1, 0, 0) else (others => <>));
         when NID_Odometer =>
            return (if F (0, 8) in 9 .. 10 then (7, F (0, 8) - 8, 0, 0)
                    else (others => <>));
         when NID_From_RBC =>
            Id := (if 8 * P'Length >= B + 24
                   then (8 * P'Length - B - 24) / 8 else 0);
            return (3, F (24, 8), Byte (Id mod 256), Byte (Id / 256 mod 256));
         when others =>
            return (others => <>);
      end case;
   end View;

   procedure Event_Message (Event      : Byte;
                            B2, B3, B4 : Byte;
                            NID        : out Byte;
                            Fields     : out Fields_T)
   is
      function F (V : Byte; Bits : Natural) return Field_T is
        ((Value => Unsigned_64 (V) and (Shift_Left (1, Bits) - 1),
          Bits  => Bits))
        with Pre => Bits in 1 .. 8;

      --  4.2.4.255: the event and its three bytes
      procedure Proprietary
        with Global => (Input => (Event, B2, B3, B4),
                        Output => NID, In_Out => Fields);
      procedure Proprietary is
      begin
         NID := NID_Proprietary;
         Fields (1) := F (Event, 8);
         Fields (2) := F (B2, 8);
         Fields (3) := F (B3, 8);
         Fields (4) := F (B4, 8);
      end Proprietary;
   begin
      Fields := No_Fields;
      case Event is
         when 11 =>
            NID := NID_Driver_Actions;
            Fields (1) := F (B2, 8);
         when 30 | 31 | 51 | 132 =>
            NID := (if Event = 132 then NID_Non_Leading else Event);
            Fields (1) := F (B2, 1);
         when 39 =>
            NID := NID_Direction;
            Fields (1) := F (B2, 2);
         when 38 =>
            NID := NID_Cab_Status;
            Fields (1) := F (B2, 1);
            Fields (2) := F (B3, 1);
            if B3 = 1 then
               Fields (3) := F (B4, 1);
            end if;
         when 48 =>
            NID := NID_Network;
            Fields (1) := F (B2, 8);
            Fields (2) := F (B3, 8);
            Fields (3) := F (B4, 8);
         when 7 =>
            --  4.2.4.52: M_ERROR 9 the impairment threshold reached, 10
            --  the safety threshold (SUBSET-026 7.5.1.64, 3.6.8.5,
            --  3.6.8.7); back to nominal has no message of its own
            if B2 in 1 .. 2 then
               NID := NID_Odometer;
               Fields (1) := (Value => Unsigned_64 (B2) + 8, Bits => 8);
            else
               Proprietary;
            end if;
         when 9 =>
            --  4.2.4.15: M_COLD_MVT (1 cold movement detected)
            NID := NID_Cold_Movement;
            Fields (1) := F (B2, 2);
         when others =>
            Proprietary;
      end case;
   end Event_Message;

   procedure Paired_Message (Event      : Byte;
                             B2, B3, B4 : Byte;
                             NID        : out Byte;
                             Fields     : out Fields_T)
   is
      Id : constant Unsigned_64 :=
        Unsigned_64 (B2) + 256 * Unsigned_64 (B3)
        + 65_536 * Unsigned_64 (B4);
   begin
      Fields := No_Fields;
      case Event is
         when 1 =>
            NID := NID_General;
         when 5 | 6 | 12 | 13 =>
            --  NID_C, NID_ERRORBG, M_ERROR (4.2.4.12; SUBSET-026
            --  7.5.1.64: 0 linking, 1 a linked group's message, 2 an
            --  unlinked group's message)
            NID := NID_BG_Error;
            Fields (1) := (Value => Shift_Right (Id, 14) and 1023,
                           Bits  => 10);
            Fields (2) := (Value => Id and 16383, Bits => 14);
            Fields (3) := (Value => (if Event = 12 then 1
                                     elsif Event = 13 then 2
                                     else 0),
                           Bits  => 8);
         when others =>
            NID := 0;
      end case;
   end Paired_Message;

end EVC_JRU_Messages;
