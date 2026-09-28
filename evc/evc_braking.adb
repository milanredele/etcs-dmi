--  ETCS on-board (EVC)
--  The braking model of the speed and distance monitoring,
--  implementation.

package body EVC_Braking
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------
   --  Step functions
   ---------------------------------------------------------------------

   function Lookup (S : Steps_T; W : Square_T; Rising : Boolean)
     return Lookup_T
   is
      Lo : Num := -1;
   begin
      if S.Count = 0 then
         return (Value => 0, W_Lo => -1, W_Hi => Infinite_Square);
      end if;
      for K in 1 .. S.Count - 1 loop
         pragma Loop_Invariant (Lo in -1 .. Max_Speed * Max_Speed);
         pragma Loop_Invariant (if Rising then Lo <= W else Lo < W);
         declare
            U2 : constant Num := S.Steps (K).Upper * S.Steps (K).Upper;
         begin
            if (if Rising then W < U2 else W <= U2) then
               return (Value => S.Steps (K).Value, W_Lo => Lo, W_Hi => U2);
            end if;
            Lo := Max (Lo, U2);
         end;
      end loop;
      return (Value => S.Steps (S.Count).Value,
              W_Lo  => Lo,
              W_Hi  => Infinite_Square);
   end Lookup;

   --  Append a step; a full function keeps its last step open and gives
   --  it the lower of the two values (the rounding to the safe side)
   procedure Append (S : in out Steps_T; Upper : Speed_T; Value : Value_T)
   is
   begin
      if S.Count < Max_Steps then
         S.Count := S.Count + 1;
         S.Steps (S.Count) := (Upper => Upper, Value => Value);
      else
         S.Steps (Max_Steps).Value :=
           Min (S.Steps (Max_Steps).Value, Value);
      end if;
   end Append;

   --  Value * Factor, Factor in millionths, rounded down
   function Scaled (Value : Value_T; Factor : Value_T) return Value_T is
     (Min (Value * Factor / Micro, Value_T'Last));

   --  R (V) = A (V) * K (V), K in millionths, rounded down, with the steps
   --  of both
   function Product (A, K : Steps_T) return Steps_T is
      R  : Steps_T := No_Steps;
      I  : Step_Count_T := 1;
      J  : Step_Count_T := 1;
   begin
      if A.Count = 0 or else K.Count = 0 then
         return No_Steps;
      end if;
      for Iteration in 1 .. 2 * Max_Steps loop
         pragma Loop_Invariant (I in 1 .. A.Count and then J in 1 .. K.Count);
         declare
            Last_A : constant Boolean := I = A.Count;
            Last_K : constant Boolean := J = K.Count;
            Value  : constant Value_T :=
              Scaled (A.Steps (I).Value, K.Steps (J).Value);
         begin
            if Last_A and then Last_K then
               Append (R, 0, Value);
               exit;
            elsif Last_K
              or else (not Last_A
                       and then A.Steps (I).Upper < K.Steps (J).Upper)
            then
               Append (R, A.Steps (I).Upper, Value);
               I := I + 1;
            elsif Last_A
              or else K.Steps (J).Upper < A.Steps (I).Upper
            then
               Append (R, K.Steps (J).Upper, Value);
               J := J + 1;
            else
               --  the same boundary in both
               Append (R, A.Steps (I).Upper, Value);
               I := I + 1;
               J := J + 1;
            end if;
         end;
      end loop;
      return R;
   end Product;

   --  A constant function
   function Constant_Steps (Value : Value_T) return Steps_T is
     (Count => 1, Steps => (others => (Upper => 0, Value => Value)));

   --  A deceleration curve of the train data (upper bounds, 3.13.2.2.3.1),
   --  mm/s² to Decel_Unit
   function From_Curve (C : Decel_Curve_T) return Steps_T
     with Post => From_Curve'Result.Count = C.Count
   is
      R : Steps_T := No_Steps;
   begin
      for K in 1 .. C.Count loop
         pragma Loop_Invariant (R.Count = K - 1);
         Append (R, Speed_T (C.Steps (K).Speed),
                 Value_T (C.Steps (K).Decel) * Decel_Unit_Per_Mms2);
      end loop;
      return R;
   end From_Curve;

   --  Kv_int from a set of packet 3 (lower bounds, 3.13.2.3.7.11), in
   --  millionths
   function From_Kv (Set : Kv_Set_T) return Steps_T
     with Post => From_Kv'Result.Count = Set.Count
   is
      R : Steps_T := No_Steps;
   begin
      for K in 1 .. Set.Count loop
         pragma Loop_Invariant (R.Count = K - 1);
         Append (R,
                 (if K < Set.Count then Speed_T (Set.Steps (K + 1).Speed)
                  else 0),
                 Value_T (Set.Steps (K).Factor) * 1_000);
      end loop;
      return R;
   end From_Kv;

   ---------------------------------------------------------------------
   --  Conversion model
   ---------------------------------------------------------------------

   --  3.13.3.2.1 a): V <= 200 km/h, i.e. V * 36 <= 200 * 1000 (cm/s)
   function Conversion_Applicable (T : Train_Data_T) return Boolean is
     (T.Model = Lambda
      and then Num (T.Max_Speed) * 36 <= 200_000
      and then T.Brake_Percentage in 30 .. 250
      and then T.Length <= (if T.Brake_Position = Passenger_P
                            then 90_000 else 150_000));

   --  A.3.7.3: V_lim = 16.85 * lambda ** 0.428 km/h, in cm/s rounded
   --  down, for lambda 0 .. 250 (0 for 0). No value lies within 1 cm/s
   --  of 100, 120, 150 or 180 km/h, so the comparisons of A.3.7.5 are
   --  exact on these values (evc_test recomputes the table).
   type V_Lim_Table_T is array (Lambda_T) of Speed_T;
   V_Lim_Table : constant V_Lim_Table_T :=
     (0, 468, 629, 749, 847, 932, 1007, 1076, 1139, 1198,
      1253, 1306, 1355, 1403, 1448, 1491, 1533, 1573, 1612, 1650,
      1687, 1722, 1757, 1791, 1824, 1856, 1887, 1918, 1948, 1977,
      2006, 2035, 2063, 2090, 2117, 2143, 2169, 2195, 2220, 2245,
      2269, 2293, 2317, 2341, 2364, 2387, 2409, 2431, 2453, 2475,
      2497, 2518, 2539, 2560, 2580, 2601, 2621, 2641, 2660, 2680,
      2699, 2719, 2738, 2756, 2775, 2793, 2812, 2830, 2848, 2866,
      2884, 2901, 2919, 2936, 2953, 2970, 2987, 3004, 3020, 3037,
      3053, 3069, 3086, 3102, 3118, 3133, 3149, 3165, 3180, 3196,
      3211, 3226, 3241, 3256, 3271, 3286, 3301, 3316, 3330, 3345,
      3359, 3374, 3388, 3402, 3416, 3430, 3444, 3458, 3472, 3485,
      3499, 3513, 3526, 3540, 3553, 3566, 3580, 3593, 3606, 3619,
      3632, 3645, 3658, 3670, 3683, 3696, 3708, 3721, 3734, 3746,
      3758, 3771, 3783, 3795, 3808, 3820, 3832, 3844, 3856, 3868,
      3880, 3891, 3903, 3915, 3927, 3938, 3950, 3961, 3973, 3984,
      3996, 4007, 4019, 4030, 4041, 4052, 4064, 4075, 4086, 4097,
      4108, 4119, 4130, 4141, 4151, 4162, 4173, 4184, 4194, 4205,
      4216, 4226, 4237, 4247, 4258, 4268, 4279, 4289, 4300, 4310,
      4320, 4330, 4341, 4351, 4361, 4371, 4381, 4391, 4401, 4411,
      4421, 4431, 4441, 4451, 4461, 4471, 4481, 4490, 4500, 4510,
      4519, 4529, 4539, 4548, 4558, 4568, 4577, 4587, 4596, 4605,
      4615, 4624, 4634, 4643, 4652, 4662, 4671, 4680, 4689, 4699,
      4708, 4717, 4726, 4735, 4744, 4753, 4762, 4771, 4780, 4789,
      4798, 4807, 4816, 4825, 4834, 4842, 4851, 4860, 4869, 4878,
      4886, 4895, 4904, 4912, 4921, 4930, 4938, 4947, 4955, 4964,
      4972);

   function V_Lim (Lambda_O : Lambda_T) return Speed_T is
     (V_Lim_Table (Lambda_O));

   --  A.3.7.6: the coefficients a3 .. a0 of AD_n, in 1e-11 m/s²
   type Coefficients_T is array (0 .. 3) of Num;
   type Polynomials_T is array (1 .. 5) of Coefficients_T;
   Polynomials : constant Polynomials_T :=
     (1 => (6_630_000_000, 472_000_000, 6_100_000, -63_000),
      2 => (13_000_000_000, 514_000_000, -454_000, 27_300),
      3 => (4_790_000_000, 581_000_000, -676_000, 5_580),
      4 => (4_800_000_000, 552_000_000, -385_000, 3_000),
      5 => (5_590_000_000, 506_000_000, 166_000, 323));

   --  A.3.7.5: AD_n in Decel_Unit (1e-5 m/s²), rounded down, at least 0
   function AD (N : Positive; L : Lambda_T) return Value_T is
      C : constant Coefficients_T := Polynomials (Integer'Min (N, 5));
      X : constant Num := Num (L);
      P : constant Num :=
        C (0) + C (1) * X + C (2) * X * X + C (3) * X * X * X;
   begin
      return Min (Max (Div_Floor (P, 1_000_000), 0), Max_Model_Decel);
   end AD;

   --  The upper speed limits of AD_1 .. AD_4 (A.3.7.5), km/h
   type Limits_T is array (1 .. 4) of Num;
   Limits_Kmh : constant Limits_T := (100, 120, 150, 180);

   --  A boundary B km/h between a step of value Below and one of value
   --  Above, as an upper bound in cm/s: the speeds between the two
   --  integers around B get the lower of the two values
   function Boundary (B_Kmh : Num; Below, Above : Value_T) return Speed_T
   is (if Below <= Above then Div_Ceil (B_Kmh * 250, 9)
       else Div_Floor (B_Kmh * 250, 9))
     with Pre => B_Kmh in 0 .. 200;

   function Basic_Deceleration (Lambda_O : Lambda_T) return Steps_T is
      R      : Steps_T := No_Steps;
      Vf     : constant Speed_T := V_Lim_Table (Lambda_O);
      --  A.3.7.4: AD_0 = 0.0075 * lambda + 0.076 m/s² (exact in
      --  Decel_Unit)
      AD_0   : constant Value_T := 750 * Num (Lambda_O) + 7_600;
      First  : Boolean := True;   -- the step after AD_0 not placed yet
      Prev   : Value_T := AD_0;
   begin
      --  V_lim is between Vf and Vf + 1; below 100 * 250 / 9 exactly
      --  when Vf * 9 < 100 * 250 (no V_lim lies in between, see the
      --  table)
      for N in 1 .. 5 loop
         declare
            Value : constant Value_T := AD (N, Lambda_O);
            Upper_Kmh : constant Num := (if N <= 4 then Limits_Kmh (N) else 0);
         begin
            --  n is used when its upper limit is above V_lim, n = 5
            --  always (V_lim < 180 km/h for every lambda of the table)
            if N = 5 or else Vf * 9 < Upper_Kmh * 250 then
               if First then
                  --  the end of AD_0 at V_lim
                  Append (R, (if Prev <= Value then Min (Vf + 1, Max_Speed)
                              else Vf),
                          AD_0);
                  First := False;
               end if;
               if N = 5 then
                  Append (R, 0, Value);
               else
                  Prev := Value;
                  Append (R,
                          Boundary (Upper_Kmh, Value, AD (N + 1, Lambda_O)),
                          Value);
               end if;
            end if;
         end;
      end loop;
      return R;
   end Basic_Deceleration;

   --  T = a + b * (L / 100) + c * (L / 100)², L in m, in ms rounded up,
   --  from a, b, c in hundredths and L in cm
   function Basic_Time (A100, B100, C100 : Num; L : Num) return Time_T is
     (Min (Max (Div_Ceil (A100 * 100_000_000 + B100 * L * 10_000
                          + C100 * L * L, 10_000_000), 0), Max_Time))
     with Pre => A100 in -10_000 .. 10_000 and then B100 in 0 .. 10_000
                 and then C100 in 0 .. 10_000 and then L in 0 .. 150_000;

   --  A.3.8.4, A.3.9.4: kto = 1 + Ct, Ct in hundredths (A.3.8.5)
   function With_Kto (T : Time_T; Position : Brake_Position_T)
     return Time_T
   is (Min (Div_Ceil (T * (if Position = Freight_G then 116 else 120), 100),
            Max_Time));

   function Conversion_Emergency (Position   : Brake_Position_T;
                                  Length     : Num;
                                  Zero_Speed : Boolean) return Times_T
   is
      L400  : constant Num := Max (Length, 40_000);
      Basic : Time_T;
   begin
      case Position is
         when Passenger_P =>
            --  A.3.8.1
            Basic := Basic_Time (230, 0, 17, L400);
         when Freight_P =>
            --  A.3.8.2
            Basic := (if Length <= 90_000 then Basic_Time (230, 0, 17, L400)
                      else Basic_Time (-40, 160, 3, Length));
         when Freight_G =>
            --  A.3.8.3
            Basic := (if Length <= 90_000
                      then Basic_Time (1_200, 0, 5, Length)
                      else Basic_Time (-40, 160, 3, Length));
      end case;
      --  A.3.8.6
      return (React    => (case Position is
                              when Passenger_P => 1_420,
                              when Freight_P   => 2_990,
                              when Freight_G   => 9_300),
              Build_Up => (if Zero_Speed then Basic
                           else With_Kto (Basic, Position)));
   end Conversion_Emergency;

   function Conversion_Service (Position   : Brake_Position_T;
                                Length     : Num;
                                Zero_Speed : Boolean) return Times_T
   is
      L400  : constant Num := Max (Length, 40_000);
      Basic : Time_T;
   begin
      case Position is
         when Passenger_P =>
            --  A.3.9.1
            Basic := Basic_Time (300, 150, 10, Length);
         when Freight_P =>
            --  A.3.9.2
            Basic := (if Length <= 90_000 then Basic_Time (300, 277, 0, Length)
                      else Basic_Time (1_050, 32, 18, Length));
         when Freight_G =>
            --  A.3.9.3
            Basic := (if Length <= 90_000 then Basic_Time (300, 277, 0, L400)
                      else Basic_Time (1_050, 32, 18, L400));
      end case;
      --  A.3.9.8
      return (React    => (case Position is
                              when Passenger_P => 1_060,
                              when Freight_P   => 2_070,
                              when Freight_G   => 5_700),
              Build_Up => (if Zero_Speed then Basic
                           else With_Kto (Basic, Position)));
   end Conversion_Service;

   ---------------------------------------------------------------------
   --  Correction factors
   ---------------------------------------------------------------------

   --  A.3.2: the defaults of Kv_int and Kr_int, millionths
   Default_Kv : constant Value_T := 700_000;
   Default_Kr : constant Value_T := 900_000;

   --  3.13.2.3.7.12: Kr_int (L), lower bounds as packet 3 gives them, in
   --  millionths
   function Kr_Int (Set : Kr_Set_T; Length : Num) return Value_T is
      K : Positive range 1 .. Max_Kv_Steps := 1;
   begin
      if Set.Count = 0 then
         return Default_Kr;
      end if;
      for J in 2 .. Set.Count loop
         if Length > Set.Steps (J).Length then
            K := J;
         end if;
      end loop;
      return Value_T (Set.Steps (K).Factor) * 1_000;
   end Kr_Int;

   --  3.13.6.2.1.8.1: Kv_int of a passenger train between the subsets a
   --  and b by A_ebmax, millionths rounded down; the steps are those of
   --  a; the decelerations in Decel_Unit
   function Kv_Passenger (A, B : Kv_Set_T; P12, P23, A_Ebmax : Num)
     return Steps_T
     with Pre => P12 in 0 .. Max_Model_Decel
                 and then P23 in 0 .. Max_Model_Decel
                 and then A_Ebmax in 0 .. Value_T'Last
   is
      R : Steps_T := From_Kv (A);
   begin
      if B.Count /= A.Count or else P23 <= P12 or else A_Ebmax <= P12 then
         return R;
      end if;
      for K in 1 .. R.Count loop
         declare
            Fa : constant Num := Num (A.Steps (K).Factor) * 1_000;
            Fb : constant Num := Num (B.Steps (K).Factor) * 1_000;
         begin
            R.Steps (K).Value :=
              (if A_Ebmax >= P23 then Fb
               else Min (Max (Fa + Div_Floor ((A_Ebmax - P12) * (Fb - Fa),
                                              P23 - P12), 0),
                         Value_T'Last));
         end;
      end loop;
      return R;
   end Kv_Passenger;

   --  3.13.6.2.1.8.2: the largest value of a curve between 0 and V
   function Largest_Below (S : Steps_T; V : Speed_T) return Value_T is
      Best  : Value_T := 0;
      Lower : Speed_T := 0;
   begin
      for K in 1 .. S.Count loop
         if K = 1 or else Lower < V then
            Best := Max (Best, S.Steps (K).Value);
         end if;
         Lower := S.Steps (K).Upper;
      end loop;
      return Best;
   end Largest_Below;

   ---------------------------------------------------------------------
   --  Build
   ---------------------------------------------------------------------

   function Index (Regenerative, Eddy, Magnetic, Ep : Boolean)
     return Combination_T
   is ((if Regenerative then 1 else 0) + (if Eddy then 2 else 0)
       + (if Magnetic then 4 else 0) + (if Ep then 8 else 0));

   function To_Times (B : Build_Up_T) return Times_T is
     (React    => Time_T (B.React),
      Build_Up => Time_T (Integer'Max (B.Build_Up, B.React)));

   procedure Build (S          : Snapshot_T;
                    Active     : Brakes_T;
                    Additional : Boolean;
                    Model      : out Model_T)
   is
      T      : Train_Data_T renames S.Train_Data;
      X      : Train_Data_Extra_T renames S.Extra.Train;
      NV     : National_Values_T renames S.National;
      Config : Onboard_Config_T renames S.Extra.Config;

      --  3.13.2.2.6.2: whether the status of a special brake counts for
      --  the emergency or the service brake models
      function Status_Counts (B : Special_Brake_T; Emergency : Boolean)
        return Boolean
      is (case Config.Special_Brakes (B) is
             when No_Interface          => False,
             when Emergency_Only        => Emergency,
             when Service_Only          => not Emergency,
             when Emergency_And_Service => True);

      function Has (B : Special_Brake_T) return Boolean is
        (case B is
            when Regenerative      => T.Has_Regenerative,
            when Eddy_Current      => T.Has_Eddy_Current,
            when Magnetic_Shoe     => T.Has_Magnetic_Shoe,
            when Electro_Pneumatic => T.Has_Electro_Pneumatic);

      Conversion : constant Boolean := Conversion_Applicable (T);
      Length     : constant Num := Min (Num (T.Length), 150_000);
   begin
      Model := (others => <>);
      Model.Conversion := Conversion;

      for B in Special_Brake_T loop
         Model.Emergency_Brakes (B) :=
           Has (B) and then (not Status_Counts (B, True) or else Active (B));
         Model.Service_Brakes (B) :=
           Has (B) and then (not Status_Counts (B, False) or else Active (B));
      end loop;

      --  3.13.4.3.2
      if X.M_Rotating_Nom > 0 then
         Model.M_Rotating_Up := X.M_Rotating_Nom;
         Model.M_Rotating_Down := X.M_Rotating_Nom;
      end if;

      if Conversion then
         --  3.13.3.3, A.3.7; 3.13.6.2.1.4: A_brake_safe = Kv_int (V) *
         --  Kr_int (L_TRAIN) * A_brake_emergency (V); no special brake
         --  changes these models (3.13.2.2.6.3)
         declare
            Emergency : constant Steps_T :=
              Basic_Deceleration (T.Brake_Percentage);
            Service   : constant Steps_T :=
              Basic_Deceleration (Integer'Min (T.Brake_Percentage, 135));
            A_Ebmax   : constant Value_T :=
              Largest_Below (Emergency, Speed_T (T.Max_Speed));
            --  3.13.6.2.1.8: the set by the brake position; a passenger
            --  set, when given, for passenger trains
            Kv        : constant Steps_T :=
              (if T.Brake_Position = Passenger_P
                 and then NV.Kv_Int_Passenger.Count > 0
               then Kv_Passenger (NV.Kv_Int_Passenger,
                                  S.Extra.National.Kv_Int_Passenger_B,
                                  Num (S.Extra.National.A_NVP12)
                                    * Decel_Unit_Per_Mms2,
                                  Num (S.Extra.National.A_NVP23)
                                    * Decel_Unit_Per_Mms2,
                                  A_Ebmax)
               elsif NV.Kv_Int_Fresh.Count > 0
               then From_Kv (NV.Kv_Int_Fresh)
               else Constant_Steps (Default_Kv));
            Kr        : constant Value_T := Kr_Int (NV.Kr_Int, Length);
            --  Kv_int (V) * Kr_int, then one product: one rounding
            Safe      : constant Steps_T :=
              Product (Emergency, Product (Kv, Constant_Steps (Kr)));
         begin
            Model.Valid := True;
            Model.Emergency_Safe := (others => Safe);
            Model.Service := (others => Service);
            --  3.13.6.2.2.3: T_be = Kt_int * T_brake_emergency, and
            --  likewise the reaction time
            declare
               Kt : constant Factor_T := Factor_T (NV.Kt_Int);

               function With_Kt (Times : Times_T) return Times_T is
                 (React    => Min (Div_Ceil (Times.React * Kt, 1000),
                                   Max_Time),
                  Build_Up => Min (Div_Ceil (Times.Build_Up * Kt, 1000),
                                   Max_Time));
            begin
               Model.Emergency_Zero := With_Kt
                 (Conversion_Emergency (T.Brake_Position, Length, True));
               Model.Emergency_Target := With_Kt
                 (Conversion_Emergency (T.Brake_Position, Length, False));
            end;
            Model.Service_Zero :=
              Conversion_Service (T.Brake_Position, Length, True);
            Model.Service_Target :=
              Conversion_Service (T.Brake_Position, Length, False);
         end;
      else
         --  braking models (3.13.2.2.1.3), with the rolling stock
         --  correction factors (3.13.6.2.1.4)
         declare
            EBCL : constant Natural range 0 .. 9 := NV.M_NVEBCL;
            Avadh : constant Num :=
              Min (Num (NV.M_NVAVADH), 1_000);
         begin
            for C in Brake_Combination_T loop
               declare
                  Emergency : constant Steps_T :=
                    From_Curve (if X.By_Combination
                                then X.A_Emergency_Combination (C)
                                else T.A_Brake_Emergency);
                  Safe : Steps_T := Emergency;
               begin
                  for K in 1 .. Safe.Count loop
                     declare
                        Kdry : constant Num := Num (X.Kdry_Rst (EBCL) (K));
                        Kwet : constant Num := Num (X.Kwet_Rst (K));
                        --  Kwet + M_NVAVADH * (1 - Kwet), exact in
                        --  millionths
                        Wet  : constant Num :=
                          Max (Kwet * 1_000 + Avadh * (1_000 - Kwet), 0);
                        --  Kdry * Wet, millionths rounded down
                        Factor : constant Num :=
                          Min (Kdry * Wet / 1_000, Value_T'Last);
                     begin
                        Safe.Steps (K).Value :=
                          Scaled (Safe.Steps (K).Value, Factor);
                     end;
                  end loop;
                  Model.Emergency_Safe (C) := Safe;
                  Model.Service (C) :=
                    From_Curve (if X.By_Combination
                                then X.A_Service_Combination (C)
                                else T.A_Brake_Service);
               end;
            end loop;
            Model.Valid := T.A_Brake_Emergency.Count > 0
              or else (X.By_Combination
                       and then (for some C in Brake_Combination_T =>
                                   X.A_Emergency_Combination (C).Count > 0));
            --  3.13.6.2.2.3, 3.13.6.3.2.4: the times of the combination
            --  of special brakes in use (Table 4)
            declare
               EB : Brakes_T renames Model.Emergency_Brakes;
               SB : Brakes_T renames Model.Service_Brakes;
               Emergency : constant Times_T :=
                 (if X.By_Combination
                  then To_Times (X.T_Emergency_Combination
                                  (Index (EB (Regenerative),
                                          EB (Eddy_Current),
                                          EB (Magnetic_Shoe),
                                          EB (Electro_Pneumatic))))
                  else To_Times ((React    => X.T_Brake_Emergency_React,
                                  Build_Up => T.T_Brake_Emergency)));
               Service : constant Times_T :=
                 (if X.By_Combination
                  then To_Times (X.T_Service_Combination
                                  (Index (SB (Regenerative),
                                          SB (Eddy_Current),
                                          False,
                                          SB (Electro_Pneumatic))))
                  else To_Times ((React    => X.T_Brake_Service_React,
                                  Build_Up => T.T_Brake_Service)));
            begin
               Model.Emergency_Zero := Emergency;
               Model.Emergency_Target := Emergency;
               Model.Service_Zero := Service;
               Model.Service_Target := Service;
            end;
         end;
      end if;

      --  3.13.6.4: the normal service model, by the set of the brake
      --  position and A_brake_service (V = 0) (3.13.2.2.3.1.9, .10)
      for C in Brake_Combination_T loop
         declare
            Set : constant Normal_Service_Set_T :=
              (if T.Brake_Position = Freight_G then X.Normal_Service_G
               else X.Normal_Service_P);
            A0  : constant Value_T := Value_At (Model.Service (C), 0);
            N   : constant Natural range 0 .. 2 :=
              (if A0 <= Num (X.A_SB01) * Decel_Unit_Per_Mms2 then 0
               elsif A0 <= Num (X.A_SB12) * Decel_Unit_Per_Mms2 then 1
               else 2);
            Chosen : constant Decel_Curve_T :=
              (if Set (N).Count > 0 then Set (N) else T.A_Brake_Normal);
         begin
            Model.Normal_Service (C) := From_Curve (Chosen);
         end;
      end loop;
      Model.Has_Normal :=
        (for all C in Brake_Combination_T =>
           Model.Normal_Service (C).Count > 0);
      Model.Kn_Plus := From_Curve (X.Kn_Plus);
      Model.Kn_Minus := From_Curve (X.Kn_Minus);

      --  3.13.6.2.1.6: A_MAXREDADH by the brake position and the
      --  special or additional brakes independent from the adhesion
      declare
         N : constant Positive range 1 .. 3 :=
           (if T.Brake_Position /= Passenger_P then 3
            elsif Config.Additional_Brake_Allowed and then Additional
            then 1 else 2);
      begin
         Model.Redadh_Use := S.Extra.National.Redadh_Use (N);
         Model.Redadh := Value_T (case N is
                                    when 1 => NV.A_NVMAXREDADH1,
                                    when 2 => NV.A_NVMAXREDADH2,
                                    when 3 => NV.A_NVMAXREDADH3)
                         * Decel_Unit_Per_Mms2;
      end;
   end Build;

end EVC_Braking;
