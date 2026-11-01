--  ETCS on-board (EVC)
--  The Virtual Balise Covers stored on-board (see the specification)

with ETCS_Bits;

package body EVC_VBC
  with SPARK_Mode => On,
       Refined_State => (State => (Store, Last_Ms, UTC_Known_Now, UTC_Now_S,
                                   Due))
is

   Store   : Cover_List_T := (others => (others => <>));
   --  the clock of the last Expire (0 after Clear and Restore: the clock
   --  of EVC_Core starts again at the power-up)
   Last_Ms : Unsigned_64 := 0;
   --  the calendar clock of the last Expire, when it reported (unknown
   --  after Clear and Restore)
   UTC_Known_Now : Boolean := False;
   UTC_Now_S     : Unsigned_64 := 0;
   --  the store changed since the DMI's list was sent
   Due     : Boolean := False;

   function List_Due return Boolean is (Due)
     with Refined_Global => Due;

   procedure Mark_Sent is
   begin
      Due := False;
   end Mark_Sent;

   function Count return Natural is
   begin
      return N : Natural := 0 do
         for I in Store'Range loop
            pragma Loop_Invariant (N < I);
            if Store (I).Used then
               N := N + 1;
            end if;
         end loop;
      end return;
   end Count;

   function Count_Of (Origin : Origin_T) return Natural is
   begin
      return N : Natural := 0 do
         for I in Store'Range loop
            pragma Loop_Invariant (N < I);
            if Store (I).Used and then Store (I).Origin = Origin then
               N := N + 1;
            end if;
         end loop;
      end return;
   end Count_Of;

   function Full return Boolean is
     (Count_Of (Driver) >= Driver_Max)
     with Refined_Global => Store;

   --  The I-th used slot
   function Item (I : Positive) return Cover_T is
      N : Natural := 0;
   begin
      for S in Store'Range loop
         pragma Loop_Invariant (N < S);
         if Store (S).Used then
            N := N + 1;
            if N = I then
               return Store (S);
            end if;
         end if;
      end loop;
      return (others => <>);
   end Item;

   function Covers (NID_C : NID_C_T; Marker : NID_VBCMK_T) return Boolean is
     (for some C of Store =>
        C.Used and then C.NID_C = NID_C and then C.Marker = Marker)
     with Refined_Global => Store;

   procedure Clear is
   begin
      Store := (others => (others => <>));
      Last_Ms := 0;
      UTC_Known_Now := False;
      UTC_Now_S := 0;
      --  the DMI starts with no VBC listed
      Due := False;
   end Clear;

   --  A VBC given from Origin: the same identity replaced in its room,
   --  its period from now (3.15.9.4, 3.15.9.6); a new identity in a free
   --  slot while the room of Origin is not full, else ignored
   procedure Put
     (Origin : Origin_T; NID_C : NID_C_T; Marker : NID_VBCMK_T; T : T_VBC_T)
   with Global => (Input  => (UTC_Known_Now, UTC_Now_S),
                   In_Out => (Store, Due))
   is
      End_UTC : constant Unsigned_64 :=
        (if UTC_Known_Now then UTC_Now_S + Unsigned_64 (T) * Day_S else 0);
      Room : constant Natural :=
        (case Origin is
            when Driver    => Driver_Max,
            when Trackside => Trackside_Max);
      Free : Natural := 0;
   begin
      for I in Store'Range loop
         pragma Loop_Invariant (Free < I);
         if Store (I).Used
           and then Store (I).NID_C = NID_C
           and then Store (I).Marker = Marker
         then
            Store (I) :=
              (Used => True, NID_C => NID_C, Marker => Marker, T_VBC => T,
               Left => Unsigned_64 (T) * Day_Ms, End_UTC => End_UTC,
               Origin => Store (I).Origin);
            Due := True;
            return;
         elsif not Store (I).Used and then Free = 0 then
            Free := I;
         end if;
      end loop;
      if Free in Store'Range and then Count_Of (Origin) < Room then
         Store (Free) :=
           (Used => True, NID_C => NID_C, Marker => Marker, T_VBC => T,
            Left => Unsigned_64 (T) * Day_Ms, End_UTC => End_UTC,
            Origin => Origin);
         Due := True;
      end if;
   end Put;

   procedure Set (NID_C : NID_C_T; Marker : NID_VBCMK_T; T : T_VBC_T) is
   begin
      Put (Driver, NID_C, Marker, T);
   end Set;

   procedure Order (NID_C : NID_C_T; Marker : NID_VBCMK_T; T : T_VBC_T) is
   begin
      Put (Trackside, NID_C, Marker, T);
   end Order;

   procedure Remove (NID_C : NID_C_T; Marker : NID_VBCMK_T) is
   begin
      for I in Store'Range loop
         if Store (I).NID_C = NID_C and then Store (I).Marker = Marker then
            Due := Due or else Store (I).Used;
            Store (I) := (others => <>);
         end if;
         pragma Loop_Invariant
           (for all J in 1 .. I =>
              not (Store (J).Used
                   and then Store (J).NID_C = NID_C
                   and then Store (J).Marker = Marker));
      end loop;
   end Remove;

   procedure Expire (Now_Ms    : Unsigned_64;
                     UTC_Known : Boolean := False;
                     UTC_Now   : Unsigned_64 := 0)
   is
      Elapsed : constant Unsigned_64 :=
        (if Now_Ms >= Last_Ms then Now_Ms - Last_Ms else 0);
   begin
      for I in Store'Range loop
         pragma Loop_Invariant (True);
         if Store (I).Used then
            if (if UTC_Known and then Store (I).End_UTC /= 0
                then Store (I).End_UTC <= UTC_Now
                else Store (I).Left <= Elapsed)
            then
               Store (I) := (others => <>);
               Due := True;
            elsif Store (I).Left <= Elapsed then
               Store (I).Left := 0;
            else
               Store (I).Left := Store (I).Left - Elapsed;
            end if;
         end if;
      end loop;
      Last_Ms := Now_Ms;
      UTC_Known_Now := UTC_Known;
      UTC_Now_S := (if UTC_Known then UTC_Now else 0);
   end Expire;

   procedure Check_Country (NID_C : NID_C_T) is
   begin
      for I in Store'Range loop
         pragma Loop_Invariant (True);
         if Store (I).Used and then Store (I).NID_C /= NID_C then
            Store (I) := (others => <>);
            Due := True;
         end if;
      end loop;
   end Check_Country;

   --  The bits of a telegram from its header on: NID_C at bit 25 (after
   --  Q_UPDOWN, M_VERSION, Q_MEDIA, N_PIG, N_TOTAL, M_DUP, M_MCOUNT,
   --  7.3.2), the first packet at bit 50. 8.4.2.4: M_VERSION 1.0 has no
   --  marker; 1.1 has packet 200 (Q_DIR and L_PACKET before NID_VBCMK,
   --  anywhere in the telegram); every other version packet 0 first
   --  (8.4.2.3); X = 0 is not read at all (3.17.3.5 a)
   function Covered (Telegram : EVC_Bytes.Byte_Array) return Boolean is
      Max_Telegram : constant := 128;
      R       : ETCS_Bits.Reader (Max_Telegram);
      Version : Unsigned_64;
      Country : Unsigned_64;
      NID     : Unsigned_64;
      Marker  : Unsigned_64;
      Length  : Unsigned_64;
   begin
      if Count = 0
        or else Telegram'Length < 3
        or else Telegram'Length > Max_Telegram
        or else Telegram'First > Positive'Last - 2
      then
         return False;
      end if;
      ETCS_Bits.Load
        (R, Telegram (Telegram'First + 2 .. Telegram'Last),
         8 * (Telegram'Length - 2));
      ETCS_Bits.Skip (R, 1);
      ETCS_Bits.Read (R, 7, Version);
      ETCS_Bits.Skip (R, 17);
      ETCS_Bits.Read (R, 10, Country);
      ETCS_Bits.Skip (R, 15);
      if ETCS_Bits.Failed (R) or else Version / 16 = 0 or else Version = 16
      then
         return False;
      elsif Version = 17 then
         for P in 1 .. 64 loop
            pragma Loop_Invariant (True);
            ETCS_Bits.Read (R, 8, NID);
            ETCS_Bits.Skip (R, 2);
            ETCS_Bits.Read (R, 13, Length);
            if ETCS_Bits.Failed (R) or else NID = 255 or else Length < 23
            then
               return False;
            elsif NID = 200 then
               ETCS_Bits.Read (R, 6, Marker);
               return not ETCS_Bits.Failed (R)
                 and then Covers (NID_C_T (Country), NID_VBCMK_T (Marker));
            end if;
            ETCS_Bits.Skip (R, Natural (Length) - 23);
         end loop;
         return False;
      else
         ETCS_Bits.Read (R, 8, NID);
         ETCS_Bits.Read (R, 6, Marker);
         return not ETCS_Bits.Failed (R)
           and then NID = 0
           and then Covers (NID_C_T (Country), NID_VBCMK_T (Marker));
      end if;
   end Covered;

   procedure Keep (K : out Kept_T) is
   begin
      K := (Covers => Store);
   end Keep;

   procedure Restore (K : Kept_T) is
   begin
      Store := K.Covers;
      Last_Ms := 0;
      UTC_Known_Now := False;
      UTC_Now_S := 0;
      Due := (for some C of Store => C.Used);
   end Restore;

end EVC_VBC;
