--  ETCS on-board (EVC)
--  The bounded queue of the outputs, implementation.

package body EVC_Outbox
  with SPARK_Mode => On,
       Refined_State => (Queue => (Data, Count, Dropped_Count))
is

   Data          : Byte_Array (1 .. Capacity) := (others => 0);
   Count         : Natural range 0 .. Capacity := 0;
   Dropped_Count : Natural := 0;

   function Used return Natural is (Count)
     with Refined_Global => Count;

   function Dropped return Natural is (Dropped_Count)
     with Refined_Global => Dropped_Count;

   -----------
   -- Clear --
   -----------

   procedure Clear
     with Refined_Global => (Output => (Count, Dropped_Count))
   is
   begin
      Count := 0;
      Dropped_Count := 0;
   end Clear;

   ---------
   -- Put --
   ---------

   procedure Put (Port : Port_T; Payload : Byte_Array)
     with Refined_Global => (In_Out => (Data, Count, Dropped_Count))
   is
      Length : constant Natural := Payload'Length;
   begin
      if Length > Capacity - Record_Header
        or else Count > Capacity - Record_Header - Length
      then
         if Dropped_Count < Natural'Last then
            Dropped_Count := Dropped_Count + 1;
         end if;
         return;
      end if;
      Data (Count + 1) := Port_T'Pos (Port);
      Data (Count + 2) := Byte (Length mod 256);
      Data (Count + 3) := Byte (Length / 256);
      Data (Count + Record_Header + 1 .. Count + Record_Header + Length) :=
        Payload;
      Count := Count + Record_Header + Length;
   end Put;

   ----------
   -- Take --
   ----------

   procedure Take (Buffer : out Byte_Array; Last : out Natural)
     with Refined_Global => (In_Out => (Data, Count))
   is
      Taken  : Natural := 0;  -- bytes moved from Data to Buffer
      Length : Natural;       -- of the record at Data (Taken + 1)
   begin
      Buffer := (others => 0);
      while Count - Taken >= Record_Header loop
         pragma Loop_Invariant (Taken <= Count);
         pragma Loop_Invariant (Taken <= Buffer'Length);
         pragma Loop_Invariant (Count = Count'Loop_Entry);
         pragma Loop_Variant (Increases => Taken);
         Length := Record_Header
                   + Natural (Data (Taken + 2))
                   + 256 * Natural (Data (Taken + 3));
         --  a record that does not fit stays queued, and so do those
         --  behind it: the order of the outputs is kept
         exit when Length > Count - Taken
           or else Length > Buffer'Length - Taken;
         Buffer (Buffer'First + Taken .. Buffer'First + (Taken + Length - 1))
           := Data (Taken + 1 .. Taken + Length);
         Taken := Taken + Length;
      end loop;
      Last := Buffer'First - 1 + Taken;
      if Taken > 0 then
         Data (1 .. Count - Taken) := Data (Taken + 1 .. Count);
         Count := Count - Taken;
      end if;
   end Take;

end EVC_Outbox;
