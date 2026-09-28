--  ETCS on-board (EVC)
--  Locations of the stored information and lower envelopes,
--  implementation.

package body EVC_Profiles
  with SPARK_Mode => On
is

   ------------------
   -- Origin_Table --
   ------------------

   function Origin_Table return Origin_Table_T is
      T : Origin_Table_T := (others => (others => <>));
   begin
      for I in EVC_Origins.Index_T loop
         declare
            O : constant EVC_Origins.Origin_T := EVC_Origins.Get (I);
         begin
            if O.Used then
               T (I) :=
                 (Used  => True,
                  Sense => O.Est.Sense,
                  Est   => Advance (O.Est.Ref.X, O.Est.Sense, O.Est.D),
                  Min   => Advance (O.Min.Ref.X, O.Min.Sense, O.Min.D),
                  Max   => Advance (O.Max.Ref.X, O.Max.Sense, O.Max.D));
            end if;
         end;
      end loop;
      return T;
   end Origin_Table;

   ------------
   -- Append --
   ------------

   procedure Append (St : in out Store_T; E : Stored_T) is
   begin
      if St.Count = Max_Stored then
         if St.Lost < Natural'Last then
            St.Lost := St.Lost + 1;
         end if;
         return;
      end if;
      St.Count := St.Count + 1;
      St.List (St.Count) := E;
   end Append;

   ------------
   -- Remove --
   ------------

   procedure Remove (St : in out Store_T; I : Positive) is
   begin
      for K in I .. St.Count - 1 loop
         St.List (K) := St.List (K + 1);
      end loop;
      St.Count := St.Count - 1;
   end Remove;

   ----------------
   -- Cut_Beyond --
   ----------------

   procedure Cut_Beyond (St         : in out Store_T;
                         T          : Origin_Table_T;
                         X          : Dist_T;
                         To         : Location_T;
                         Before_Msg : Natural)
   is
      S : constant Sense_T := St.Sense;
      I : Natural := 1;
   begin
      while I <= St.Count loop
         pragma Loop_Invariant
           (I >= 1 and then St.Sense = S
            and then St.Count <= St.Count'Loop_Entry);
         pragma Loop_Variant (Decreases => St.Count - I);
         if St.List (I).Msg >= Before_Msg then
            I := I + 1;
         elsif A (S, Frame (T, St.List (I).Start, Estimated_Item))
                 >= A (S, X)
         then
            Remove (St, I);
         else
            if St.List (I).Open
              or else A (S, Frame (T, St.List (I).Finish, Estimated_Item))
                        > A (S, X)
            then
               St.List (I).Finish := To;
               St.List (I).Open := False;
            end if;
            I := I + 1;
         end if;
      end loop;
   end Cut_Beyond;

   ----------------
   -- Cut_Behind --
   ----------------

   procedure Cut_Behind (St   : in out Store_T;
                         T    : Origin_Table_T;
                         Rear : Dist_T;
                         Keep : Length_T)
   is
      S     : constant Sense_T := St.Sense;
      Limit : constant Dist_T := Diff (A (S, Rear), Keep);
      I     : Natural := 1;
   begin
      while I <= St.Count loop
         pragma Loop_Invariant
           (I >= 1 and then St.Sense = S
            and then St.Count <= St.Count'Loop_Entry);
         pragma Loop_Variant (Decreases => St.Count - I);
         if not St.List (I).Open
           and then A (S, Frame (T, St.List (I).Finish, Min_Item)) < Limit
         then
            Remove (St, I);
         else
            I := I + 1;
         end if;
      end loop;
   end Cut_Behind;

   ------------
   -- Covers --
   ------------

   function Covers (St : Store_T; T : Origin_Table_T; From, To : Dist_T)
     return Boolean
   is
      S     : constant Sense_T := St.Sense;
      Reach : Dist_T := A (S, From);
      Goal  : constant Dist_T := A (S, To);
      Moved : Boolean;
   begin
      --  extend the reach by any element across it, until it gets to the
      --  goal or no element moves it (at most one pass per element)
      for Pass in 1 .. St.Count + 1 loop
         exit when Reach >= Goal;
         Moved := False;
         for I in 1 .. St.Count loop
            declare
               E  : Stored_T renames St.List (I);
               B  : constant Dist_T :=
                 A (S, Frame (T, E.Start, Estimated_Item));
               F  : constant Dist_T :=
                 (if E.Open then Max_Cm
                  else A (S, Frame (T, E.Finish, Estimated_Item)));
            begin
               if B <= Reach and then F > Reach then
                  Reach := F;
                  Moved := True;
               end if;
            end;
         end loop;
         exit when not Moved;
      end loop;
      return Reach >= Goal;
   end Covers;

   ----------
   -- Mark --
   ----------

   procedure Mark (L : Location_T; Marks : in out Origin_Marks_T) is
   begin
      if L.Origin /= 0 then
         Marks (L.Origin) := True;
      end if;
   end Mark;

   procedure Mark (St : Store_T; Marks : in out Origin_Marks_T) is
   begin
      for I in 1 .. St.Count loop
         Mark (St.List (I).Start, Marks);
         Mark (St.List (I).Finish, Marks);
      end loop;
   end Mark;

   ---------
   -- Add --
   ---------

   procedure Add (E : in out Elements_T;
                  Start, Finish : Dist_T;
                  Value : Value_T)
   is
   begin
      if Start >= Finish then
         return;
      end if;
      if E.Count = Max_Elements then
         if E.Lost < Natural'Last then
            E.Lost := E.Lost + 1;
         end if;
         return;
      end if;
      E.Count := E.Count + 1;
      E.List (E.Count) := (Start => Start, Finish => Finish, Value => Value);
   end Add;

   --------------
   -- Value_At --
   --------------

   function Value_At (P : Steps_T; X : Dist_T) return Value_T is
      V : Value_T := P.List (1).Value;
   begin
      for K in 2 .. P.Count loop
         exit when P.List (K).Start > X;
         V := P.List (K).Value;
      end loop;
      return V;
   end Value_At;

   ------------
   -- Lowest --
   ------------

   function Lowest (P : Steps_T; From, To : Dist_T) return Value_T is
      V : Value_T := Value_At (P, From);
   begin
      for K in 1 .. P.Count loop
         if P.List (K).Start <= To and then Step_End (P, K) > From then
            V := Value_T'Min (V, P.List (K).Value);
         end if;
      end loop;
      return V;
   end Lowest;

   --------------
   -- Envelope --
   --------------

   procedure Envelope (E        : in out Elements_T;
                       Default  : Value_T;
                       Floor    : Value_T;
                       Ceiling  : Value_T;
                       Capacity : Positive;
                       P        : out Steps_T;
                       Checked  : out Boolean)
   is
      Max_Breaks : constant := 2 * Max_Elements + 1;
      type Break_Array is array (1 .. Max_Breaks) of Dist_T;

      B  : Break_Array := (others => Axis_Start);
      NB : Natural range 0 .. Max_Breaks := 1;

      --  X into the sorted breakpoints B (1 .. NB), once
      procedure Insert (X : Dist_T)
        with Pre => NB in 1 .. Max_Breaks - 1,
             Post => NB in NB'Old .. NB'Old + 1
      is
         J : Positive := 1;
      begin
         while J <= NB and then B (J) < X loop
            pragma Loop_Invariant (J <= NB);
            J := J + 1;
         end loop;
         if J <= NB and then B (J) = X then
            return;
         end if;
         --  B (J .. NB) one place up
         for K in reverse J .. NB loop
            B (K + 1) := B (K);
         end loop;
         B (J) := X;
         NB := NB + 1;
      end Insert;

      Fallback : constant Steps_T :=
        (Count => 1, List => (others => (Start => Axis_Start,
                                         Value => Floor)));
      OK : Boolean := True;
   begin
      --  the elements below the Floor raised to it
      for I in 1 .. E.Count loop
         pragma Loop_Invariant
           (E.Count = E.Count'Loop_Entry
            and then (for all J in 1 .. E.Count =>
                        E.List (J).Start = E.List'Loop_Entry (J).Start
                        and then E.List (J).Finish
                                   = E.List'Loop_Entry (J).Finish)
            and then (for all J in 1 .. I - 1 =>
                        E.List (J).Value
                          = Value_T'Max (E.List'Loop_Entry (J).Value,
                                         Floor))
            and then (for all J in I .. E.Count =>
                        E.List (J).Value = E.List'Loop_Entry (J).Value));
         E.List (I).Value := Value_T'Max (E.List (I).Value, Floor);
      end loop;

      --  the breakpoints: the start of the axis and every element bound
      for I in 1 .. E.Count loop
         pragma Loop_Invariant (NB in 1 .. 2 * I - 1);
         Insert (E.List (I).Start);
         --  an element to the end of the axis (open ended) leaves no
         --  step there
         if E.List (I).Finish < Max_Cm then
            Insert (E.List (I).Finish);
         end if;
      end loop;

      --  the value on each breakpoint, equal neighbours merged, the
      --  steps beyond the capacity folded into the last one
      P := (Count => 0, List => (others => (Start => Axis_Start,
                                              Value => Floor)));
      for J in 1 .. NB loop
         pragma Loop_Invariant (P.Count <= Capacity);
         pragma Loop_Invariant (if J > 1 then P.Count >= 1);
         declare
            X       : constant Dist_T := B (J);
            V       : Value_T := Default;
            Covered : Boolean := False;
         begin
            for I in 1 .. E.Count loop
               if E.List (I).Start <= X and then X < E.List (I).Finish then
                  V := (if Covered then Value_T'Min (V, E.List (I).Value)
                        else E.List (I).Value);
                  Covered := True;
               end if;
            end loop;
            V := Value_T'Min (V, Ceiling);
            if P.Count = 0 then
               P.Count := 1;
               P.List (1) := (Start => X, Value => V);
            elsif V /= P.List (P.Count).Value then
               if P.Count < Capacity then
                  P.Count := P.Count + 1;
                  P.List (P.Count) := (Start => X, Value => V);
               else
                  P.List (P.Count).Value :=
                    Value_T'Min (P.List (P.Count).Value, V);
               end if;
            end if;
         end;
      end loop;

      --  the check of the postcondition
      if P.Count = 0 or else P.List (1).Start /= Axis_Start then
         OK := False;
      end if;
      if OK then
         for K in 1 .. P.Count - 1 loop
            if P.List (K).Start >= P.List (K + 1).Start then
               OK := False;
               exit;
            end if;
            pragma Loop_Invariant
              (for all K2 in 1 .. K =>
                 P.List (K2).Start < P.List (K2 + 1).Start);
         end loop;
      end if;
      if OK then
         for K in 1 .. P.Count loop
            if P.List (K).Value not in Floor .. Ceiling then
               OK := False;
               exit;
            end if;
            pragma Loop_Invariant
              (for all K2 in 1 .. K => P.List (K2).Value in Floor .. Ceiling);
         end loop;
      end if;
      if OK then
         for I in 1 .. E.Count loop
            for K in 1 .. P.Count loop
               if Overlaps (P, K, E.List (I))
                 and then P.List (K).Value > E.List (I).Value
               then
                  OK := False;
                  exit;
               end if;
               pragma Loop_Invariant
                 (for all K2 in 1 .. K =>
                    (if Overlaps (P, K2, E.List (I))
                     then P.List (K2).Value <= E.List (I).Value));
            end loop;
            exit when not OK;
            pragma Loop_Invariant
              (for all I2 in 1 .. I =>
                 (for all K2 in 1 .. P.Count =>
                    (if Overlaps (P, K2, E.List (I2))
                     then P.List (K2).Value <= E.List (I2).Value)));
         end loop;
      end if;

      Checked := OK;
      if not OK then
         P := Fallback;
      end if;
   end Envelope;

end EVC_Profiles;
