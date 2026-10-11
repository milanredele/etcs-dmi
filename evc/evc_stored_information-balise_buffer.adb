--  ETCS on-board (EVC)
--  Phase E5 (e5/balise-buffer): see the spec.

package body EVC_Stored_Information.Balise_Buffer
  with SPARK_Mode => On,
       Refined_State => (State => (Sets, N))
is

   type Kinds_T is array (1 .. Max_Set_Packets)
     of ETCS_Catalogue.Packet_Kind_T;
   type Bits_T is array (1 .. Max_Set_Packets) of ETCS_Bits.Bit_Count;

   type Set_T is record
      Info    : Set_Info_T := (others => <>);
      Kinds   : Kinds_T := (others => ETCS_Catalogue.Unknown);
      Offsets : Bits_T := (others => 0);
      Lengths : Bits_T := (others => 0);
      Used    : Natural range 0 .. Set_Bytes := 0;
      Data    : ETCS_Bits.Byte_Array (1 .. Set_Bytes) := (others => 0);
   end record;

   type Sets_T is array (1 .. Max_Sets) of Set_T;

   Sets : Sets_T := (others => (others => <>));
   N    : Natural range 0 .. Max_Sets := 0;

   function Count return Natural is (N)
     with Refined_Global => N;

   function Info (S : Positive) return Set_Info_T is (Sets (S).Info)
     with Refined_Global => (Input => Sets, Proof_In => N);

   function Kind (S, P : Positive) return ETCS_Catalogue.Packet_Kind_T is
     (Sets (S).Kinds (P))
     with Refined_Global => (Input => Sets, Proof_In => N);

   No_Set : constant Set_T := (others => <>);

   procedure Clear
     with Refined_Global => (Output => (Sets, N))
   is
   begin
      Sets := (others => No_Set);
      N := 0;
   end Clear;

   ----------------
   -- Delete_All --
   ----------------

   --  4.8.5.4
   procedure Delete_All
     with Refined_Global => (Output => N)
   is
   begin
      N := 0;
   end Delete_All;

   -------------
   -- New_Set --
   -------------

   --  4.8.5.1, 4.8.5.3
   procedure New_Set (I : Set_Info_T)
     with Refined_Global => (In_Out => (Sets, N))
   is
   begin
      if N = Max_Sets then
         for S in 1 .. Max_Sets - 1 loop
            pragma Loop_Invariant (True);
            Sets (S) := Sets (S + 1);
         end loop;
         N := Max_Sets - 1;
      end if;
      N := N + 1;
      Sets (N).Info := I;
      Sets (N).Used := 0;
   end New_Set;

   ----------------
   -- Add_Packet --
   ----------------

   procedure Add_Packet (K : ETCS_Catalogue.Packet_Kind_T;
                         R : in out ETCS_Bits.Reader)
     with Refined_Global => (In_Out => Sets, Input => N)
   is
      Len   : constant ETCS_Bits.Bit_Count := ETCS_Bits.Remaining (R);
      Bytes : constant Natural := (Len + 7) / 8;
   begin
      if N = 0 or else Len = 0
        or else Sets (N).Info.Count = Max_Set_Packets
        or else Bytes > Set_Bytes - Sets (N).Used
      then
         return;
      end if;
      declare
         Used : constant Natural := Sets (N).Used;
         P    : constant Positive := Sets (N).Info.Count + 1;
      begin
         ETCS_Bits.Read_Bytes
           (R, Len, Sets (N).Data (Used + 1 .. Used + Bytes));
         if ETCS_Bits.Failed (R) then
            return;
         end if;
         Sets (N).Kinds (P) := K;
         Sets (N).Offsets (P) := 8 * Used;
         Sets (N).Lengths (P) := Len;
         Sets (N).Used := Used + Bytes;
         Sets (N).Info.Count := P;
      end;
   end Add_Packet;

   ----------
   -- Open --
   ----------

   procedure Open (S, P : Positive; R : in out ETCS_Bits.Reader)
     with Refined_Global => (Input => Sets, Proof_In => N)
   is
      Off : constant ETCS_Bits.Bit_Count := Sets (S).Offsets (P);
   begin
      ETCS_Bits.Load (R, Sets (S).Data, 8 * Set_Bytes);
      ETCS_Bits.Seek (R, Off);
      ETCS_Bits.Set_Limit (R, Off + Sets (S).Lengths (P));
   end Open;

end EVC_Stored_Information.Balise_Buffer;
