--  ETCS on-board (EVC)
--  The track as the curves see it, implementation.

package body EVC_Profile
  with SPARK_Mode => On
is

   subtype Candidate_Index is Positive range 1 .. Max_Points - 1;
   type Candidates_T is array (Candidate_Index) of Num;

   type Grade_T is record
      Start   : Dist_T;
      Grad    : Gradient_T;
      Covered : Boolean;
   end record;
   type Grades_T is array (1 .. Max_Gradient_Segments) of Grade_T;

   --  An area of the track, ahead coordinates, First <= Last
   type Span_T is record
      First, Last : Dist_T;
   end record;

   function Span (S : Snapshot_T; A, B : Dist_T) return Span_T is
     (First => Min (Ahead_Of (S, A), Ahead_Of (S, B)),
      Last  => Max (Ahead_Of (S, A), Ahead_Of (S, B)));

   -----------
   -- Build --
   -----------

   procedure Build (S     : Snapshot_T;
                    Model : Model_T;
                    Rear  : Dist_T;
                    P     : out Profile_T)
   is
      L : constant Num := Min (Num (S.Train_Data.Length), 1_000_000);

      Grades  : Grades_T :=
        (others => (Start => 0, Grad => 0, Covered => True));
      --  3.13.4.1.3 a): the default gradient for TSR, when one is stored
      Default_TSR : constant Gradient_T :=
        (if S.Gradients.Has_Default_TSR then S.Gradients.Default_TSR
         else 0);
      G_Count : Natural range 0 .. Max_Gradient_Segments := 0;

      Cand    : Candidates_T := (others => 0);
      C_Count : Natural range 0 .. Max_Points - 1 := 0;

      procedure Add (X : Num) is
      begin
         if C_Count < Cand'Last and then X in -Max_Cm + 1 .. Max_Cm then
            C_Count := C_Count + 1;
            Cand (C_Count) := X;
         end if;
      end Add;

      --  3.13.4.2: the lowest gradient met by a fictive train whose
      --  front end is anywhere in [Lo, Hi]: over [Lo - L, Hi]; Other
      --  where the profile gives nothing (3.13.4.1.3)
      function Lowest (Lo, Hi : Num; Other : Gradient_T) return Gradient_T
      is
         Result : Gradient_T := Gradient_T'Last;
         From   : constant Num := Lo - L;
      begin
         if G_Count = 0 or else From < Grades (1).Start then
            Result := Other;
         end if;
         for K in 1 .. G_Count loop
            if Grades (K).Start < Hi
              and then (K = G_Count or else Grades (K + 1).Start > From)
            then
               Result := Integer'Min (Result,
                                      (if Grades (K).Covered
                                       then Grades (K).Grad else Other));
            end if;
         end loop;
         return Result;
      end Lowest;

   begin
      P := (Count => 1, Points => (others => No_Point));

      --  the gradient segments in increasing order (the others ignored)
      for K in 1 .. S.Gradients.Count loop
         declare
            X : constant Num :=
              Ahead_Of (S, S.Gradients.Segments (K).Start);
         begin
            if G_Count = 0 or else X > Grades (G_Count).Start then
               if G_Count < Max_Gradient_Segments then
                  G_Count := G_Count + 1;
                  Grades (G_Count) :=
                    (Start   => X,
                     Grad    => S.Gradients.Segments (K).Gradient,
                     Covered => S.Gradients.Covered (K));
               end if;
            end if;
         end;
      end loop;

      --  the candidate boundaries
      for K in 1 .. G_Count loop
         Add (Grades (K).Start);
         Add (Grades (K).Start + L);
      end loop;
      for K in 1 .. S.Adhesion.Count loop
         declare
            A : constant Span_T :=
              Span (S, S.Adhesion.Areas (K).Start,
                    S.Adhesion.Areas (K).Finish);
         begin
            Add (A.First);
            Add (A.Last + L);
         end;
      end loop;
      for K in 1 .. S.Inhibitions.Count loop
         declare
            A : constant Span_T :=
              Span (S, S.Inhibitions.Areas (K).Start,
                    S.Inhibitions.Areas (K).Finish);
         begin
            if A.Last >= Num (Rear) then
               Add (A.First);
            end if;
         end;
      end loop;

      --  in increasing order (insertion sort)
      for I in 2 .. C_Count loop
         for J in reverse 2 .. I loop
            exit when Cand (J - 1) <= Cand (J);
            declare
               Swap : constant Num := Cand (J);
            begin
               Cand (J) := Cand (J - 1);
               Cand (J - 1) := Swap;
            end;
         end loop;
      end loop;

      --  the segments: a boundary once
      for I in 1 .. C_Count loop
         pragma Loop_Invariant (P.Count <= I);
         if Cand (I) > P.Points (P.Count).Start
           and then Cand (I) <= Max_Cm
         then
            P.Count := P.Count + 1;
            P.Points (P.Count).Start := Cand (I);
         end if;
      end loop;

      --  the attributes of every segment
      for I in 1 .. P.Count loop
         declare
            Lo : constant Num := P.Points (I).Start;
            Hi : constant Num :=
              (if I < P.Count then P.Points (I + 1).Start else Max_Cm);
            --  3.13.4.1.3 b), a)
            G  : constant Gradient_T := Lowest (Lo, Hi, 0);
            GT : constant Gradient_T := Lowest (Lo, Hi, Default_TSR);
            Point : Point_T renames P.Points (I);
         begin
            Point.Gradient := G;
            Point.A_Gradient :=
              Gradient_Acceleration (G, Model.M_Rotating_Up,
                                     Model.M_Rotating_Down);
            --  3.13.4.1.2: compensated for the rotating mass as well
            Point.Gradient_TSR := GT;
            Point.A_Gradient_TSR :=
              Gradient_Acceleration (GT, Model.M_Rotating_Up,
                                     Model.M_Rotating_Down);
            Point.Reduced := S.Adhesion.Driver_Slippery;
            for K in 1 .. S.Adhesion.Count loop
               declare
                  A : constant Span_T :=
                    Span (S, S.Adhesion.Areas (K).Start,
                          S.Adhesion.Areas (K).Finish);
               begin
                  if A.First < Hi and then A.Last + L >= Lo then
                     Point.Reduced := True;
                  end if;
               end;
            end loop;
            Point.Inhibited := (others => False);
            for K in 1 .. S.Inhibitions.Count loop
               declare
                  A : constant Span_T :=
                    Span (S, S.Inhibitions.Areas (K).Start,
                          S.Inhibitions.Areas (K).Finish);
               begin
                  if A.Last >= Num (Rear) and then A.First < Hi then
                     Point.Inhibited (S.Inhibitions.Areas (K).Kind) := True;
                     --  3.13.2.3.4.1, 3.12.1.3.3: no regenerative brake
                     --  in a powerless section when it needs the catenary
                     if S.Inhibitions.Areas (K).Kind = Powerless_Section
                       and then S.Extra.Config.Regenerative_Needs_Catenary
                     then
                        Point.Inhibited (Regenerative_Inhibited) := True;
                     end if;
                  end if;
               end;
            end loop;
         end;
      end loop;
   end Build;

   ----------------
   -- Segment_Of --
   ----------------

   function Segment_Of (P : Profile_T; X : Num) return Point_Index is
   begin
      for I in reverse 2 .. P.Count loop
         if P.Points (I).Start <= X then
            return I;
         end if;
      end loop;
      return 1;
   end Segment_Of;

end EVC_Profile;
