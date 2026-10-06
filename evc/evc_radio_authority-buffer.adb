--  ETCS on-board (EVC)
--  Phase E5, the state of the acceptance of radio information (see the
--  specification).

package body EVC_Radio_Authority.Buffer
  with SPARK_Mode => On,
       Refined_State => (State => (Ctx, Slots, Count, Releasing))
is
   use type EVC_Radio.Session_Ref_T;

   subtype Data_T is EVC_Bytes.Byte_Array (1 .. EVC_Ports.RTM_Max_Length);

   type Slot_T is record
      Session : EVC_Radio.Session_T := 1;
      Length  : Natural range 0 .. EVC_Ports.RTM_Max_Length := 0;
      Data    : Data_T := (others => 0);
   end record;

   --  the oldest first
   type Slots_T is array (1 .. Buffer_Size) of Slot_T;

   function Valid_Slot (X : Slot_T) return Boolean is
     (X.Length >= EVC_Ports.RTM_Min_Length
      and then EVC_Ports.Valid_RTM (X.Data (1 .. X.Length)));

   Ctx       : Context_T := (others => <>);
   Slots     : Slots_T := (others => (others => <>));
   Count     : Buffered_T := 0;
   Releasing : Boolean := False;

   function Context return Context_T is (Ctx)
     with Refined_Global => Ctx;

   function Buffered return Buffered_T is (Count)
     with Refined_Global => Count;

   function Has_Released return Boolean is (Releasing and then Count > 0)
     with Refined_Global => (Releasing, Count);

   procedure Clear
     with Refined_Global => (Output => (Ctx, Slots, Count, Releasing))
   is
   begin
      Ctx := (others => <>);
      Slots := (others => (others => <>));
      Count := 0;
      Releasing := False;
   end Clear;

   --  4.8.5.4 c): the messages of a session no longer established go, the
   --  others keep their order; 4.8.5.4 b) (e5/handover): also those of a
   --  session that is neither the Supervising nor the Accepting RBC's
   --  (the RBC transition order deleted or replaced)
   procedure Drop_Ended
     with Global => (In_Out => (Slots, Count), Input => EVC_Radio.State)
   is
      Kept : Buffered_T := 0;
   begin
      for I in 1 .. Buffer_Size loop
         pragma Loop_Invariant (Kept < I and then Kept <= Count'Loop_Entry);
         if I <= Count and then EVC_Radio.Established (Slots (I).Session)
           and then (EVC_Radio.Supervising
                       = EVC_Radio.Session_Ref_T (Slots (I).Session)
                     or else EVC_Radio.Accepting
                       = EVC_Radio.Session_Ref_T (Slots (I).Session)
                     or else EVC_Radio.Supervising = EVC_Radio.No_Session)
         then
            Kept := Kept + 1;
            Slots (Kept) := Slots (I);
         end if;
      end loop;
      Count := Kept;
   end Drop_Ended;

   --  4.8.5.4 a), c), 4.8.5.5
   procedure Update (C : Context_T)
     with Refined_Global => (Output => (Ctx, Releasing),
                             In_Out => (Slots, Count),
                             Input  => EVC_Radio.State)
   is
      Level_2 : constant Boolean := C.Level_Valid and then C.Level = L2;
   begin
      Ctx := C;
      if not Level_2 and then not C.L2_Announced then
         Count := 0;                                       -- a)
      end if;
      Drop_Ended;                                          -- c)
      --  4.8.5.5; 4.8.5.2 (e5/handover): not while the Accepting RBC
      --  does not supervise yet
      Releasing := Level_2 and then Count > 0
                     and then not EVC_Radio.Handover;
   end Update;

   procedure Release_At_Transition
     with Refined_Global => (In_Out => Ctx, Input => Count,
                             Output => Releasing)
   is
   begin
      Ctx.Level_Valid := True;
      Ctx.Level := L2;
      Releasing := Count > 0;
   end Release_At_Transition;

   procedure Store (S : EVC_Radio.Session_T; Data : EVC_Bytes.Byte_Array)
     with Refined_Global => (In_Out => (Slots, Count))
   is
   begin
      if Count = Buffer_Size then
         --  4.8.5.3: the oldest replaced
         for I in 1 .. Buffer_Size - 1 loop
            pragma Loop_Invariant (True);
            Slots (I) := Slots (I + 1);
         end loop;
         Count := Buffer_Size - 1;
      end if;
      Count := Count + 1;
      Slots (Count) := (Session => S, Length => Data'Length, Data => <>);
      Slots (Count).Data (1 .. Data'Length) := Data;
   end Store;

   procedure Take_Released (S    : out EVC_Radio.Session_T;
                            Data : in out EVC_Bytes.Byte_Array;
                            Last : out Natural)
     with Refined_Global => (In_Out => (Slots, Count, Releasing))
   is
      X : Slot_T renames Slots (1);
   begin
      S := X.Session;
      if Valid_Slot (X) then
         Data (Data'First .. Data'First + X.Length - 1) :=
           X.Data (1 .. X.Length);
         Last := Data'First + X.Length - 1;
      else
         --  not reached (Store keeps valid messages): an empty message 24
         Data (Data'First .. Data'First + 2) := (24, 0, 192);
         Last := Data'First + 2;
      end if;
      for I in 1 .. Buffer_Size - 1 loop
         pragma Loop_Invariant (True);
         Slots (I) := Slots (I + 1);
      end loop;
      Count := Count - 1;
      Releasing := Count > 0;
   end Take_Released;

end EVC_Radio_Authority.Buffer;
