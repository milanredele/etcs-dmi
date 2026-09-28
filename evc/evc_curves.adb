--  ETCS on-board (EVC)
--  The brake deceleration curves, implementation.

with EVC_Supervision_Input; use EVC_Supervision_Input;

package body EVC_Curves
  with SPARK_Mode => On
is

   ------------------
   -- Deceleration --
   ------------------

   function Deceleration (M      : Model_T;
                          P      : Profile_T;
                          Kind   : Kind_T;
                          Seg    : Point_Index;
                          W      : Square_T;
                          Rising : Boolean) return Decel_Step_T
   is
      Pt : Point_T renames P.Points (Seg);
   begin
      case Kind is
         when EBD =>
            --  3.13.6.2.1.3: A_safe = A_brake_safe (V, d), limited to
            --  A_MAXREDADH under reduced adhesion when it limits, plus
            --  A_gradient (d)
            declare
               L : constant Lookup_T :=
                 Lookup (M.Emergency_Safe
                           (Emergency_Combination (M, Pt.Inhibited)),
                         W, Rising);
               A : Num := L.Value;
            begin
               if Pt.Reduced and then M.Redadh_Use = Limit then
                  A := Min (A, M.Redadh);
               end if;
               return (A => A + Pt.A_Gradient, W_Lo => L.W_Lo,
                       W_Hi => L.W_Hi);
            end;
         when SBD =>
            --  3.13.6.3.1.3: A_expected = A_brake_service (V, d) +
            --  A_gradient (d)
            declare
               L : constant Lookup_T :=
                 Lookup (M.Service (Service_Combination (M, Pt.Inhibited)),
                         W, Rising);
            begin
               return (A => L.Value + Pt.A_Gradient, W_Lo => L.W_Lo,
                       W_Hi => L.W_Hi);
            end;
         when GUI =>
            --  3.13.6.4.3: A_normal_service = A_brake_normal_service (V,
            --  d) + A_gradient (d) - Kn (V) * grad (d) / 1000, Kn+ uphill
            --  and Kn- downhill, the product rounded up
            declare
               L  : constant Lookup_T :=
                 Lookup (M.Normal_Service
                           (Service_Combination (M, Pt.Inhibited)),
                         W, Rising);
               K  : constant Lookup_T :=
                 Lookup ((if Pt.Gradient > 0 then M.Kn_Plus
                          else M.Kn_Minus), W, Rising);
               Kn : constant Num := Min (K.Value, Max_Model_Decel);
            begin
               return (A    => L.Value + Pt.A_Gradient
                                 - Div_Ceil (Kn * Num (Pt.Gradient), 1000),
                       W_Lo => Max (L.W_Lo, K.W_Lo),
                       W_Hi => Min (L.W_Hi, K.W_Hi));
            end;
      end case;
   end Deceleration;

   --  The change of W = v² along D cm at the deceleration A (1e-5 m/s²,
   --  a positive A gives a gain): A * D / 500, rounded down, exactly
   function Gain (A : Walk_Accel_T; D : Num) return Num is
     (A * (D / 500) + Div_Floor (A * (D mod 500), 500))
     with Pre  => D in 0 .. 2**43,
          Post => (if A >= 0 then Gain'Result >= 0 else Gain'Result <= 0);

   --  Forwards the curve must fall at least as fast as the exact one: the
   --  deceleration, rounded down by EVC_Braking and EVC_Profile by at
   --  most three units and between the integers around a step boundary,
   --  is taken this much higher (0.1 mm/s² and 0.02 %)
   function Forward (A : Walk_Accel_T) return Walk_Accel_T is
     (Min (A + 10 + abs A / 5_000, Walk_Accel_T'Last));

   --  The end of a segment (its start is Points (Seg).Start)
   function Segment_End (P : Profile_T; Seg : Point_Index) return Num is
     (if Seg < P.Count then P.Points (Seg + 1).Start else Max_Cm)
     with Pre => Seg <= P.Count;

   ---------------
   -- Walk_Back --
   ---------------

   --  Follow the curve rearwards from (X, W) until X reaches X_Goal or W
   --  reaches W_Goal. Done is False when the iterations ran out first.
   procedure Walk_Back (M      : Model_T;
                        P      : Profile_T;
                        Kind   : Kind_T;
                        X      : in out Num;
                        W      : in out Num;
                        X_Goal : Num;
                        W_Goal : Num;
                        Done   : out Boolean)
     with Pre  => X in -Max_Cm .. Max_Cm
                  and then X_Goal in -Max_Cm .. X
                  and then W in 0 .. Max_Square
                  and then W_Goal in 0 .. Infinite_Square,
          Post => X in X_Goal .. X'Old
                  and then W in 0 .. Max_Square
                  and then (if Done then X = X_Goal or else W >= W_Goal)
   is
      Seg : Point_Index := Segment_Of (P, X);
   begin
      Done := False;
      for Iteration in 1 .. Max_Iterations loop
         pragma Loop_Invariant (X in X_Goal .. X'Loop_Entry);
         pragma Loop_Invariant (W in 0 .. Max_Square);
         pragma Loop_Invariant (Seg <= P.Count);
         if W >= W_Goal or else X = X_Goal then
            Done := True;
            exit;
         end if;
         declare
            Seg_Lo : constant Num :=
              Min (Max (P.Points (Seg).Start, X_Goal), X);
            Up     : constant Decel_Step_T :=
              Deceleration (M, P, Kind, Seg, W, Rising => True);
            Down   : constant Decel_Step_T :=
              Deceleration (M, P, Kind, Seg, W, Rising => False);
            Next   : Boolean := False;   -- the segment ends here
         begin
            if Up.A > 0 then
               --  the speed grows rearwards up to the next step (or the
               --  goal); the location where it gets there rounded
               --  rearwards, the gain along a whole piece rounded down
               declare
                  Top  : constant Num := Min (Min (Up.W_Hi, W_Goal),
                                              Max_Square);
                  Need : constant Num :=
                    (if Top > W then Div_Ceil ((Top - W) * 500, Up.A)
                     else 0);
               begin
                  if X - Need > Seg_Lo then
                     X := X - Need;
                     W := Max (Top, W);
                  else
                     W := Min (W + Gain (Up.A, X - Seg_Lo), Max (Top, W));
                     X := Seg_Lo;
                     Next := True;
                  end if;
               end;
            elsif Down.A < 0 and then W > 0 then
               --  the speed falls rearwards (a downhill gradient the
               --  brake does not overcome) down to the step below; the
               --  location rounded forwards, the loss rounded up
               declare
                  Bottom : constant Num := Max (Down.W_Lo, 0);
                  Need   : constant Num :=
                    (if W > Bottom
                     then Div_Floor ((W - Bottom) * 500, -Down.A) else 0);
               begin
                  if X - Need > Seg_Lo then
                     X := X - Need;
                     W := Min (Bottom, W);
                  else
                     W := Max (W + Gain (Down.A, X - Seg_Lo),
                               Min (Bottom, W));
                     X := Seg_Lo;
                     Next := True;
                  end if;
               end;
            else
               --  the deceleration is zero, or the steps above and below
               --  disagree: the speed stays through the segment
               X := Seg_Lo;
               Next := True;
            end if;
            if Next and then X = P.Points (Seg).Start and then Seg > 1 then
               Seg := Seg - 1;
            end if;
         end;
      end loop;
   end Walk_Back;

   ------------------
   -- Walk_Forward --
   ------------------

   --  Follow the curve forwards from (X, W) until X reaches X_Goal or W
   --  falls to W_Goal
   procedure Walk_Forward (M      : Model_T;
                           P      : Profile_T;
                           Kind   : Kind_T;
                           X      : in out Num;
                           W      : in out Num;
                           X_Goal : Num;
                           W_Goal : Num;
                           Done   : out Boolean)
     with Pre  => X in -Max_Cm .. Max_Cm
                  and then X_Goal in X .. Max_Cm + Max_Forward
                  and then W in 0 .. Max_Square
                  and then W_Goal in 0 .. Max_Square,
          Post => X in X'Old .. X_Goal
                  and then W in 0 .. Max_Square
                  and then (if Done then X = X_Goal or else W <= W_Goal)
   is
      Seg : Point_Index := Segment_Of (P, X);
   begin
      Done := False;
      for Iteration in 1 .. Max_Iterations loop
         pragma Loop_Invariant (X in X'Loop_Entry .. X_Goal);
         pragma Loop_Invariant (W in 0 .. Max_Square);
         pragma Loop_Invariant (Seg <= P.Count);
         if W <= W_Goal or else X = X_Goal then
            Done := True;
            exit;
         end if;
         if X >= Segment_End (P, Seg) and then Seg < P.Count then
            Seg := Seg + 1;
         else
            declare
               Seg_Hi : constant Num :=
                 Max (Min (Segment_End (P, Seg), X_Goal), X);
               Up_D   : constant Decel_Step_T :=
                 Deceleration (M, P, Kind, Seg, W, Rising => True);
               Down_D : constant Decel_Step_T :=
                 Deceleration (M, P, Kind, Seg, W, Rising => False);
               Up     : constant Decel_Step_T :=
                 (A => Forward (Up_D.A), W_Lo => Up_D.W_Lo,
                  W_Hi => Up_D.W_Hi);
               Down   : constant Decel_Step_T :=
                 (A => Forward (Down_D.A), W_Lo => Down_D.W_Lo,
                  W_Hi => Down_D.W_Hi);
            begin
               if X >= Seg_Hi then
                  --  the last segment, open ended, reaches X_Goal
                  X := X_Goal;
               elsif Down.A > 0 then
                  --  the speed falls forwards down to the step below or
                  --  the goal: the location rounded rearwards, the loss
                  --  rounded up
                  declare
                     Bottom : constant Num := Max (Max (Down.W_Lo, 0),
                                                   W_Goal);
                     Need   : constant Num :=
                       (if W > Bottom
                        then Div_Floor ((W - Bottom) * 500, Down.A) else 0);
                  begin
                     if X + Need < Seg_Hi then
                        X := X + Need;
                        W := Min (Bottom, W);
                     else
                        W := Max (W + Gain (-Down.A, Seg_Hi - X),
                                  Min (Bottom, W));
                        X := Seg_Hi;
                     end if;
                  end;
               elsif Up.A < 0 then
                  --  the speed grows forwards (braking lost to a downhill
                  --  gradient): the location rounded forwards, the gain
                  --  rounded down
                  declare
                     Top  : constant Num := Min (Up.W_Hi, Max_Square);
                     Need : constant Num :=
                       (if Top > W then Div_Ceil ((Top - W) * 500, -Up.A)
                        else 0);
                  begin
                     if X + Need < Seg_Hi then
                        X := X + Need;
                        W := Max (Top, W);
                     else
                        W := Min (W + Gain (-Up.A, Seg_Hi - X),
                                  Max (Top, W));
                        X := Seg_Hi;
                     end if;
                  end;
               else
                  X := Seg_Hi;
               end if;
            end;
         end if;
      end loop;
   end Walk_Forward;

   --------------
   -- Speed_At --
   --------------

   function Speed_At (M : Model_T;
                      P : Profile_T;
                      C : Curve_T;
                      X : Num) return Speed_T
   is
      Here : Num := C.Anchor;
      W    : Num := C.Anchor_W;
      Done : Boolean;
   begin
      if X <= C.Anchor then
         Walk_Back (M, P, C.Kind, Here, W, X, Infinite_Square, Done);
         --  out of iterations: the lowest speed is the safe answer
         return (if Done and then Here = X then Speed_Of (W) else 0);
      else
         Walk_Forward (M, P, C.Kind, Here, W, X, C.Floor_W, Done);
         return (if Done and then Here <= X then Speed_Of (Max (W, C.Floor_W))
                 else Speed_Of (C.Floor_W));
      end if;
   end Speed_At;

   -----------------
   -- Location_Of --
   -----------------

   function Location_Of (M    : Model_T;
                         P    : Profile_T;
                         C    : Curve_T;
                         V    : Speed_T;
                         Stop : Num) return Num
   is
      Wanted : constant Square_T := V * V;
      Here   : Num := C.Anchor;
      W      : Num := C.Anchor_W;
      Done   : Boolean;
   begin
      if Wanted >= C.Anchor_W then
         if Stop > C.Anchor then
            return Stop - 1;
         end if;
         Walk_Back (M, P, C.Kind, Here, W, Stop, Wanted, Done);
         return (if Done and then W >= Wanted then Here else Stop - 1);
      else
         Walk_Forward (M, P, C.Kind, Here, W, C.Anchor + Max_Forward,
                       Max (Wanted, C.Floor_W), Done);
         return (if Done and then W <= Max (Wanted, C.Floor_W) then Here
                 else C.Anchor);
      end if;
   end Location_Of;

end EVC_Curves;
