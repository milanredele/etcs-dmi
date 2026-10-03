--  ETCS on-board (EVC)
--  One passage over a balise group, implementation.

package body EVC_Balise_Groups
  with SPARK_Mode => On
is

   -----------
   -- Start --
   -----------

   procedure Start (P : out Passage_T;
                    T : ETCS_Telegram.Telegram_T;
                    R : Reading_T)
   is
   begin
      --  component by component: the aggregate of the whole passage,
      --  which reads the parameters, was built in a temporary (4.6 KB)
      --  and copied
      P := (others => <>);
      P.Open := True;
      P.Id := Identity (T.Header);
      P.N_TOTAL := T.Header.N_TOTAL;
      P.Linked := T.Header.Q_LINK = 1;
      P.Count := 1;
      for I in Slot_T loop
         pragma Loop_Invariant
           (P.Open and then P.Count = 1
            and then P.Id = Identity (T.Header));
         P.Readings (I) := R;
         P.Telegrams (I) := T;
      end loop;
   end Start;

   ---------
   -- Add --
   ---------

   procedure Add (P : in out Passage_T;
                  T : ETCS_Telegram.Telegram_T;
                  R : Reading_T)
   is
   begin
      P.Count := P.Count + 1;
      P.Readings (P.Count) := R;
      P.Telegrams (P.Count) := T;
   end Add;

   --------------
   -- Geometry --
   --------------

   function Geometry (P : Passage_T) return Geometry_T is
      G      : Geometry_T;
      First  : Slot_T := 1;   -- the lowest balise number read
      Last   : Slot_T := 1;   -- the highest
      Ref_1  : Natural := 0;  -- balise 1
      Ref_2  : Natural := 0;  -- balise 2, duplicate of balise 1
   begin
      for I in 1 .. P.Count loop
         pragma Loop_Invariant (First <= P.Count and then Last <= P.Count);
         pragma Loop_Invariant (Ref_1 <= P.Count and then Ref_2 <= P.Count);
         if P.Readings (I).N_PIG < P.Readings (First).N_PIG then
            First := I;
         end if;
         if P.Readings (I).N_PIG > P.Readings (Last).N_PIG then
            Last := I;
         end if;
         if P.Readings (I).N_PIG = 0 and then Ref_1 = 0 then
            Ref_1 := I;
         end if;
         --  M_DUP 2: "this balise is a duplicate of the previous balise"
         if P.Readings (I).N_PIG = 1 and then P.Readings (I).M_DUP = 2
           and then Ref_2 = 0
         then
            Ref_2 := I;
         end if;
      end loop;

      if Ref_1 /= 0 then
         G.Has_Reference := True;
         G.Reference := P.Readings (Ref_1);
      elsif Ref_2 /= 0 then
         G.Has_Reference := True;
         G.Reference := P.Readings (Ref_2);
         G.Duplicate_Reference := True;
      end if;

      --  3.4.2.2.2: nominal is the direction of increasing numbers
      declare
         A : constant Reading_T := P.Readings (First);
         B : constant Reading_T := P.Readings (Last);
      begin
         if A.N_PIG /= B.N_PIG and then A.X /= B.X then
            G.Orientation := (if B.X > A.X then Plus else Minus);
         end if;
      end;

      --  the order of passing, else the movement at the detection
      declare
         A : constant Reading_T := P.Readings (1);
         B : constant Reading_T := P.Readings (P.Count);
      begin
         if B.X > A.X then
            G.Crossing := Plus;
         elsif B.X < A.X then
            G.Crossing := Minus;
         else
            G.Crossing := B.Motion;
         end if;
         G.Last_X := B.X;
      end;
      return G;
   end Geometry;

end EVC_Balise_Groups;
