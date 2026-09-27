--  ETCS on-board (EVC)
--  Bit strings of the ERTMS/ETCS language, implementation.
--
--  Bit N of a string (0 is the first) is bit 7 - N mod 8 of byte
--  N / 8 + 1, bit 7 being the most significant (SUBSET-026 7.3.2.10).

package body ETCS_Bits
  with SPARK_Mode => On
is

   --  Bit N of Bytes, as 0 or 1
   function Bit_At (Bytes : Byte_Array; N : Natural) return Unsigned_64 is
     (Unsigned_64 (Shift_Right (Bytes (Bytes'First + N / 8), 7 - N mod 8)
                   and 1))
     with Pre  => Bytes'First = 1 and then N / 8 < Bytes'Length,
          Post => Bit_At'Result <= 1;

   --  Bytes with bit N set to Bit (0 or 1)
   procedure Set_Bit (Bytes : in out Byte_Array; N : Natural; Bit : Boolean)
     with Pre => Bytes'First = 1 and then N / 8 < Bytes'Length
   is
      Mask : constant EVC_Bytes.Byte := Shift_Left (1, 7 - N mod 8);
      I    : constant Positive := Bytes'First + N / 8;
   begin
      if Bit then
         Bytes (I) := Bytes (I) or Mask;
      else
         Bytes (I) := Bytes (I) and not Mask;
      end if;
   end Set_Bit;

   ---------------------------------------------------------------------
   --  Reader
   ---------------------------------------------------------------------

   ----------
   -- Load --
   ----------

   procedure Load (R : in out Reader; Data : Byte_Array; Bits : Natural) is
   begin
      R.Position := 0;
      if Data'Length <= R.Size and then Holds (Data, Bits) then
         R.Bytes := (others => 0);
         R.Bytes (1 .. Data'Length) := Data;
         R.Limit := Bits;
         R.Failed := False;
      else
         R.Limit := 0;
         R.Failed := True;
      end if;
   end Load;

   ----------
   -- Read --
   ----------

   procedure Read (R : in out Reader; Bits : Width; Value : out Unsigned_64)
   is
   begin
      Value := 0;
      if R.Failed or else Bits > R.Limit - R.Position then
         R.Failed := True;
         return;
      end if;
      for I in 1 .. Bits loop
         Value :=
           Shift_Left (Value, 1) or Bit_At (R.Bytes, R.Position + I - 1);
         pragma Loop_Invariant (Shift_Right (Value, I) = 0);
      end loop;
      R.Position := R.Position + Bits;
   end Read;

   ----------------
   -- Read_Bytes --
   ----------------

   procedure Read_Bytes (R    : in out Reader;
                         Bits : Natural;
                         Data : out Byte_Array)
   is
   begin
      Data := (others => 0);
      if R.Failed
        or else Bits > R.Limit - R.Position
        or else not Holds (Data, Bits)
      then
         R.Failed := True;
         return;
      end if;
      for I in 0 .. Bits - 1 loop
         pragma Loop_Invariant (R.Position + Bits <= R.Limit);
         if Bit_At (R.Bytes, R.Position + I) = 1 then
            Data (Data'First + I / 8) :=
              Data (Data'First + I / 8) or Shift_Left (1, 7 - I mod 8);
         end if;
      end loop;
      R.Position := R.Position + Bits;
   end Read_Bytes;

   ----------
   -- Skip --
   ----------

   procedure Skip (R : in out Reader; Bits : Natural) is
   begin
      if R.Failed or else Bits > R.Limit - R.Position then
         R.Failed := True;
      else
         R.Position := R.Position + Bits;
      end if;
   end Skip;

   ----------
   -- Seek --
   ----------

   procedure Seek (R : in out Reader; To : Natural) is
   begin
      if R.Failed or else To > R.Limit then
         R.Failed := True;
      else
         R.Position := To;
      end if;
   end Seek;

   ---------------
   -- Set_Limit --
   ---------------

   procedure Set_Limit (R : in out Reader; To : Natural) is
   begin
      if R.Failed or else To < R.Position or else To > 8 * R.Size then
         R.Failed := True;
      else
         R.Limit := To;
      end if;
   end Set_Limit;

   ---------------------------------------------------------------------
   --  Writer
   ---------------------------------------------------------------------

   -----------
   -- Clear --
   -----------

   procedure Clear (W : in out Writer) is
   begin
      W.Bytes := (others => 0);
      W.Position := 0;
      W.Failed := False;
   end Clear;

   -----------
   -- Write --
   -----------

   procedure Write (W : in out Writer; Bits : Width; Value : Unsigned_64) is
   begin
      if W.Failed
        or else not Fits (Value, Bits)
        or else Bits > 8 * W.Size - W.Position
      then
         W.Failed := True;
         return;
      end if;
      for I in 1 .. Bits loop
         pragma Loop_Invariant (W.Position + Bits <= 8 * W.Size);
         Set_Bit (W.Bytes, W.Position + I - 1,
                  (Shift_Right (Value, Bits - I) and 1) = 1);
      end loop;
      W.Position := W.Position + Bits;
   end Write;

   -----------------
   -- Write_Bytes --
   -----------------

   procedure Write_Bytes (W : in out Writer; Bits : Natural; Data : Byte_Array)
   is
   begin
      if W.Failed
        or else not Holds (Data, Bits)
        or else Bits > 8 * W.Size - W.Position
      then
         W.Failed := True;
         return;
      end if;
      for I in 0 .. Bits - 1 loop
         pragma Loop_Invariant (W.Position + Bits <= 8 * W.Size);
         Set_Bit (W.Bytes, W.Position + I,
                  (Shift_Right (Data (Data'First + I / 8), 7 - I mod 8)
                   and 1) = 1);
      end loop;
      W.Position := W.Position + Bits;
   end Write_Bytes;

   ----------
   -- Fill --
   ----------

   procedure Fill (W : in out Writer; Count : Natural; One : Boolean) is
   begin
      if W.Failed or else Count > 8 * W.Size - W.Position then
         W.Failed := True;
         return;
      end if;
      for I in 0 .. Count - 1 loop
         pragma Loop_Invariant (W.Position + Count <= 8 * W.Size);
         Set_Bit (W.Bytes, W.Position + I, One);
      end loop;
      W.Position := W.Position + Count;
   end Fill;

   -----------
   -- Patch --
   -----------

   procedure Patch (W      : in out Writer;
                    At_Bit : Natural;
                    Bits   : Width;
                    Value  : Unsigned_64)
   is
   begin
      if W.Failed
        or else not Fits (Value, Bits)
        or else At_Bit > W.Position
        or else Bits > W.Position - At_Bit
      then
         W.Failed := True;
         return;
      end if;
      for I in 1 .. Bits loop
         pragma Loop_Invariant (At_Bit + Bits <= W.Position);
         Set_Bit (W.Bytes, At_Bit + I - 1,
                  (Shift_Right (Value, Bits - I) and 1) = 1);
      end loop;
   end Patch;

   ----------
   -- Data --
   ----------

   function Data (W : Writer) return Byte_Array is
      Length : constant Byte_Count := (W.Position + 7) / 8;
      Result : Byte_Array (1 .. Length) := W.Bytes (1 .. Length);
   begin
      --  the bits of the last byte after Position are zero
      if W.Position mod 8 /= 0 then
         Result (Length) :=
           Result (Length)
           and Shift_Left (16#FF#, 8 - W.Position mod 8);
      end if;
      return Result;
   end Data;

end ETCS_Bits;
