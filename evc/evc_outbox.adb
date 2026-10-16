--  ETCS on-board (EVC)
--  The bounded queue of the outputs, implementation.

package body EVC_Outbox
  with SPARK_Mode => On,
       Refined_State => (Queue => (Data, Count, Dropped_Count,
                                   Kept, Kept_Count, Lost_Count, Msg))
is

   Data          : Byte_Array (1 .. Capacity) := (others => 0);
   Count         : Natural range 0 .. Capacity := 0;
   Dropped_Count : Natural := 0;

   --  The juridical messages kept, each: NID_MESSAGE u8, the time of its
   --  event u64 (little endian), the length in bits of its complementary
   --  part u16, that part bit-packed
   Kept_Header : constant := 11;
   Kept        : Byte_Array (1 .. JRU_Capacity) := (others => 0);
   Kept_Count  : Natural range 0 .. JRU_Capacity := 0;
   Lost_Count  : Natural := 0;
   --  The message Flush_JRU builds
   Msg : Byte_Array (1 .. EVC_JRU_Messages.Max_Length) := (others => 0);

   function Used return Natural is (Count)
     with Refined_Global => Count;

   function Dropped return Natural is (Dropped_Count)
     with Refined_Global => Dropped_Count;

   procedure Clear
     with Refined_Global => (Output => (Count, Dropped_Count,
                                        Kept_Count, Lost_Count))
   is
   begin
      Count := 0;
      Dropped_Count := 0;
      Kept_Count := 0;
      Lost_Count := 0;
   end Clear;

   function JRU_Kept return Natural is (Kept_Count)
     with Refined_Global => Kept_Count;

   function JRU_Lost return Natural is (Lost_Count)
     with Refined_Global => Lost_Count;

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

   procedure Put_JRU (NID      : Byte;
                      Clock_Ms : Unsigned_64;
                      Fields   : EVC_JRU_Messages.Fields_T;
                      Data     : Byte_Array;
                      Data_Bits : Natural := Natural'Last)
     with Refined_Global => (In_Out => (Kept, Kept_Count, Lost_Count))
   is
      use EVC_JRU_Messages;
      D_Bits : constant Natural := Natural'Min (Data_Bits, 8 * Data'Length);
      Bits : Natural := D_Bits;
      Pos  : Natural;
   begin
      for I in Fields'Range loop
         pragma Loop_Invariant (Bits <= D_Bits + 64 * (I - 1));
         Bits := Bits + Fields (I).Bits;
      end loop;
      if Kept_Count > JRU_Capacity - Kept_Header - (Bits + 7) / 8 then
         if Lost_Count < Natural'Last then
            Lost_Count := Lost_Count + 1;
         end if;
         return;
      end if;
      Kept (Kept_Count + 1) := NID;
      for I in 0 .. 7 loop
         pragma Loop_Invariant (True);
         Kept (Kept_Count + 2 + I) :=
           Byte (Shift_Right (Clock_Ms, 8 * I) and 16#FF#);
      end loop;
      Kept (Kept_Count + 10) := Byte (Bits mod 256);
      Kept (Kept_Count + 11) := Byte (Bits / 256);
      Pos := 8 * (Kept_Count + Kept_Header);
      for I in Fields'Range loop
         pragma Loop_Invariant (Pos <= 8 * Kept'Length);
         if Fields (I).Bits > 0
           and then Pos <= 8 * Kept'Length - Fields (I).Bits
         then
            Put_Bits (Kept, Pos, Fields (I).Value, Fields (I).Bits);
         end if;
      end loop;
      for K in 0 .. D_Bits - 1 loop
         pragma Loop_Invariant (Pos <= 8 * Kept'Length);
         if Pos < 8 * Kept'Length then
            Put_Bits (Kept, Pos, Get_Bits (Data, K, 1), 1);
         end if;
      end loop;
      Kept_Count := Kept_Count + Kept_Header + (Bits + 7) / 8;
   end Put_JRU;

   --  The message of the kept entry at Kept (At_Byte + 1) in Msg (1 ..
   --  Length), with H and the time of its event
   procedure Build_JRU (At_Byte     : Natural;
                        H           : EVC_JRU_Messages.Header_T;
                        UTC_Known   : Boolean;
                        UTC_Seconds : Unsigned_32;
                        Length      : out Natural)
     with Global => (Input => Kept, Output => Msg),
          Pre  => At_Byte <= JRU_Capacity - Kept_Header,
          Post => Length <= Msg'Length
   is
      use EVC_JRU_Messages;
      Bits  : constant Natural :=
        Natural (Kept (At_Byte + 10)) + 256 * Natural (Kept (At_Byte + 11));
      Clock : Unsigned_64 := 0;
      Head  : Header_T := H;
      Pos   : Natural := 0;
      From  : constant Natural := 8 * (At_Byte + Kept_Header);
      Start : Natural;
      Last  : Natural;
   begin
      for I in reverse 0 .. 7 loop
         pragma Loop_Invariant (True);
         Clock := Clock * 256 + Unsigned_64 (Kept (At_Byte + 2 + I));
      end loop;
      if UTC_Known then
         Set_Time (Head, UTC_Seconds,
                   Natural (Clock mod Unsigned_64 (Natural'Last)));
      end if;
      Msg := (others => 0);
      Put_Header (Msg, Pos, Kept (At_Byte + 1), Head);
      Start := Pos;
      Last := Natural'Min (Bits, 8 * Msg'Length - Start);
      for I in 0 .. Last - 1 loop
         pragma Loop_Invariant (Pos = Start + I);
         Put_Bits (Msg, Pos, Get_Bits (Kept, From + I, 1), 1);
      end loop;
      Length := (Pos + 7) / 8;
      Put_Length (Msg, Length);
   end Build_JRU;

   procedure Flush_JRU (H           : EVC_JRU_Messages.Header_T;
                        UTC_Known   : Boolean;
                        UTC_Seconds : Unsigned_32)
     with Refined_Global => (In_Out => (Data, Count, Dropped_Count,
                                        Kept, Kept_Count, Msg))
   is
      Done   : Natural := 0;   -- bytes of Kept written
      Size   : Natural;        -- of the entry at Kept (Done + 1)
      Length : Natural;
   begin
      while Kept_Count - Done >= Kept_Header loop
         pragma Loop_Invariant (Done <= Kept_Count);
         pragma Loop_Invariant (Kept_Count = Kept_Count'Loop_Entry);
         pragma Loop_Variant (Increases => Done);
         Size := Kept_Header
                 + (Natural (Kept (Done + 10))
                    + 256 * Natural (Kept (Done + 11)) + 7) / 8;
         exit when Size > Kept_Count - Done;
         Build_JRU (Done, H, UTC_Known, UTC_Seconds, Length);
         exit when Length > Capacity - Record_Header
           or else Count > Capacity - Record_Header - Length;
         Put (JRU, Msg (1 .. Length));
         Done := Done + Size;
      end loop;
      if Done > 0 then
         Kept (1 .. Kept_Count - Done) := Kept (Done + 1 .. Kept_Count);
         Kept_Count := Kept_Count - Done;
      end if;
   end Flush_JRU;

end EVC_Outbox;
