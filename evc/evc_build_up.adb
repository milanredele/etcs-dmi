--  ETCS on-board (EVC)
--  The reduced brake build up times, implementation.

package body EVC_Build_Up
  with SPARK_Mode => On
is

   --  The bounds within which the formulas are evaluated
   subtype G_Time  is Num range 0 .. 60_000;          -- ms
   subtype G_Ramp  is Num range 1_000 .. 120_000;     -- ms
   subtype G_Decel is Num range 1_000 .. 1_000_000;   -- 1e-5 m/s²
   subtype G_Accel is Num range 0 .. 100_000;         -- 1e-5 m/s²
   subtype G_Speed is Num range 0 .. 120_000_000;     -- 1/1000 cm/s

   --  The square root rounded up
   function Sqrt_Ceil (X : Num) return Num is
     (if Sqrt_Floor (X) * Sqrt_Floor (X) < X then Sqrt_Floor (X) + 1
      else Sqrt_Floor (X))
     with Pre  => X in 0 .. 2**62,
          Post => Sqrt_Ceil'Result in 0 .. 2**31 + 1;

   --  Products of bounded factors, for the proof: X * Y <= XM * YM
   procedure Lemma_Mul_17_44 (X, Y, XM, YM : Num)
     with Ghost, Global => null,
          Pre  => XM in 0 .. 2**17 and then YM in 0 .. 2**44
                  and then X in 0 .. XM and then Y in 0 .. YM,
          Post => X * Y in 0 .. XM * YM;
   procedure Lemma_Mul_20_41 (X, Y, XM, YM : Num)
     with Ghost, Global => null,
          Pre  => XM in 0 .. 2**20 and then YM in 0 .. 2**41
                  and then X in 0 .. XM and then Y in 0 .. YM,
          Post => X * Y in 0 .. XM * YM;

   procedure Lemma_Mul_17_44 (X, Y, XM, YM : Num) is
   begin
      pragma Assert (X * Y <= XM * Y);
      pragma Assert (XM * Y <= XM * YM);
   end Lemma_Mul_17_44;

   procedure Lemma_Mul_20_41 (X, Y, XM, YM : Num) is
   begin
      pragma Assert (X * Y <= XM * Y);
      pragma Assert (XM * Y <= XM * YM);
   end Lemma_Mul_20_41;

   --  A * T / 1000: the speed (1/1000 cm/s) gained at A (1e-5 m/s²)
   --  during T ms, rounded up or down
   function Gain_Up (A : G_Accel; T : Num) return Num is
     (Div_Ceil (A * T, 1_000))
     with Pre => T in 0 .. 240_000;
   function Gain_Down (A : G_Accel; T : Num) return Num is
     (Div_Floor (A * T, 1_000))
     with Pre => T in 0 .. 240_000;

   ------------------
   -- T_Be_Reduced --
   ------------------

   function T_Be_Reduced (I : Input_T) return Time_T is
   begin
      --  A.3.12.1.4, .5, and the bounds of the evaluation
      if I.Kind = EOA_Target or else I.Kt_Zero
        or else I.T_Be_React > I.T_Be
        or else I.T_Traction >= I.T_Be
        or else I.T_Be > G_Time'Last
        or else 2 * (I.T_Be - I.T_Be_React) < G_Ramp'First
        or else I.A_EB not in G_Decel
        or else I.A_Safe_Max not in G_Decel
        or else I.T_Traction_Max > 2 * I.T_Be - I.T_Be_React
        or else I.T_Traction_Min > G_Time'Last
        or else I.A_Est1 > 1_000 or else I.A_Est2 > 1_000
      then
         return I.T_Be;
      end if;

      declare
         --  A.3.12.2.1: t2be; the ramp T_be_incr
         Tr    : constant G_Time := I.T_Be_React;
         T2    : constant Num := 2 * I.T_Be - I.T_Be_React;
         Incr  : constant G_Ramp := T2 - Tr;
         Ttm   : constant G_Time := Min (I.T_Traction_Max, G_Time'Last);
         Ttn   : constant G_Time := I.T_Traction_Min;
         A1    : constant G_Accel := I.A_Est1 * 100;
         A2    : constant G_Accel := I.A_Est2 * 100;
         AEB   : constant G_Decel := I.A_EB;
         ASM   : constant G_Decel := I.A_Safe_Max;
         V0    : constant G_Speed := (I.V_Est + I.V_Delta0) * 1_000;
         Vt    : constant G_Speed := I.V_Target * 1_000;
         Vt_Cm : constant Num := I.V_Target;
         V_T1, V_T2 : Num;
      begin
         --  A.3.12.3.1: V_t1be, rounded up
         V_T1 := V0 + Gain_Up (A1, Min (Ttm, Tr))
                 + Gain_Up (A2, Max (Tr - Ttm, 0));
         if (I.Kind = Speed_Target and then V_T1 <= Vt)      -- A.3.12.3.2
           or else (I.Kind = Zero_Target and then V_T1 = 0)  -- A.3.12.3.3
         then
            return Tr;
         end if;

         --  A.3.12.4.1: V_t2be, rounded up
         V_T2 := Max (0, V0 + Gain_Up (A1, Ttm) + Gain_Up (A2, T2 - Ttm)
                         - Div_Floor (AEB * Incr, 2_000));
         if (I.Kind = Speed_Target and then V_T2 >= Vt)      -- A.3.12.4.2
           or else (I.Kind = Zero_Target and then V_T2 > 0)  -- A.3.12.4.3
         then
            return I.T_Be;
         end if;

         declare
            --  Every intermediate value is checked against a bound far
            --  beyond what the ranges above can give; beyond it (never in
            --  practice) the result is T_be. The products then provably
            --  fit in 64 bits.
            Big   : constant := 1_000_000_000_000;         -- 1e12
            DV    : constant Num := Max (0, V0 - Vt);
            --  (A1 - A2) Ttm and (A1 - A2) Ttn as speeds, rounded up
            G_M, G_N   : Num;
            R_T, B, Q_B, T_E, D, T_Dist : Num;
            C1, Q, C2, H, B3, C3, B4, P4, C4, B5, P5, C5 : Num;
         begin
            G_M := (if A1 >= A2 then Gain_Up (A1 - A2, Ttm)
                    else -Gain_Down (A2 - A1, Ttm));
            G_N := (if A1 >= A2 then Gain_Up (A1 - A2, Ttn)
                    else -Gain_Down (A2 - A1, Ttn));
            if G_M not in -Big .. Big or else G_N not in -Big .. Big then
               return I.T_Be;
            end if;

            --  A.3.12.5.1: t2be_enough, rounded up
            R_T := Div_Ceil (A2 * Incr, AEB);
            B := DV + G_M + Gain_Up (A2, Tr);
            if R_T not in 0 .. 100_000_000 or else B not in 0 .. Big then
               return I.T_Be;
            end if;
            Lemma_Mul_17_44 (Incr, 2 * B, G_Ramp'Last, 2 * Big);
            Q_B := Div_Ceil (Incr * (2 * B), AEB);
            if Q_B not in 0 .. 1_000_000_000_000_000 then
               return I.T_Be;
            end if;
            T_E := Min (Tr + R_T + Sqrt_Ceil (R_T * R_T + Q_B * 1_000), T2);
            if T_E not in 0 .. G_Ramp'Last then
               return I.T_Be;
            end if;

            --  A.3.12.6.1: D_t2be_enough, 1e-6 cm, rounded up
            C1 := (if A2 >= A1 then Div_Ceil ((A2 - A1) * Ttm * Ttm, 2_000)
                   else -Div_Floor ((A1 - A2) * Ttm * Ttm, 2_000));
            Q := Div_Ceil (AEB * Tr * Tr, Incr);
            H := Div_Floor (AEB * Tr * Tr, 2_000 * Incr);
            B4 := A2 + Div_Ceil (AEB * Tr, Incr);
            B5 := Div_Floor (AEB * T_E, Incr);
            if C1 not in -Big * 1_000 .. Big * 1_000
              or else Q not in 0 .. Big * 10
              or else H not in 0 .. Big
              or else B4 not in 0 .. 100_000_000
              or else B5 not in 0 .. 100_000_000
            then
               return I.T_Be;
            end if;
            C2 := Div_Ceil (Q * Tr, 6_000);
            B3 := V0 + G_M - H;
            C3 := B3 * T_E;
            if C3 not in -Big * 1_000_000 .. Big * 1_000_000 then
               return I.T_Be;
            end if;
            Lemma_Mul_17_44 (T_E, B4, G_Ramp'Last, 100_000_000);
            P4 := B4 * T_E;
            Lemma_Mul_17_44 (T_E, P4, G_Ramp'Last, 12_000_000_000_000);
            C4 := Div_Ceil (P4 * T_E, 2_000);
            Lemma_Mul_17_44 (T_E, B5, G_Ramp'Last, 100_000_000);
            P5 := B5 * T_E;
            Lemma_Mul_17_44 (T_E, P5, G_Ramp'Last, 12_000_000_000_000);
            C5 := Div_Floor (P5 * T_E, 6_000);
            D := C1 + C2 + C3 + C4 - C5;
            if D not in 0 .. 100_000_000_000_000 then
               return I.T_Be;
            end if;

            --  A.3.12.7.1: t_be_enough_step_dist, rounded up
            if A2 = 0 then
               if V0 = 0 then
                  return I.T_Be;
               end if;
               declare
                  --  V_target² / (2 A_safe_max): (cm/s)² over 1e-5 m/s²
                  --  gives 1e3 cm, 1e9 of our distance unit
                  Stop_Q : constant Num :=
                    Div_Ceil (Vt_Cm * Vt_Cm * 1_000_000, 2 * ASM);
               begin
                  if Stop_Q not in 0 .. Big * 10 then
                     return I.T_Be;
                  end if;
                  T_Dist := Div_Ceil (D + Stop_Q * 1_000, V0)
                            - Div_Floor (V0 * 1_000, 2 * ASM);
               end;
            else
               declare
                  --  t_X, negative, rounded up
                  T_X   : constant Num := -Div_Floor ((V0 + G_N) * 1_000, A2);
                  --  (A1 - A2) Ttn² / A2 + 2 D / A2, ms², rounded up
                  P_N   : constant Num := (A1 - A2) * Ttn;
                  X1    : constant Num :=
                    Div_Ceil (P_N * Ttn + 2_000 * D, A2);
                  --  A_safe_max / (A_safe_max + A2), millionths, up
                  Ratio : constant Num :=
                    Div_Ceil (ASM * 1_000_000, ASM + A2);
                  --  V_target² / (A2 (A_safe_max + A2)) in ms²
                  S2_Q  : constant Num :=
                    Div_Ceil (Div_Ceil (Vt_Cm * Vt_Cm * 1_000_000, A2),
                              ASM + A2);
                  S1    : Num;
               begin
                  if T_X not in -1_000_000_000 .. 1_000_000_000
                    or else X1 not in -Big * 1_000_000 .. Big * 1_000_000
                    or else Ratio not in 0 .. 1_000_000
                    or else S2_Q not in 0 .. Big
                  then
                     return I.T_Be;
                  end if;
                  S1 := T_X * T_X + X1;
                  if S1 not in 0 .. Big then
                     return I.T_Be;
                  end if;
                  Lemma_Mul_20_41 (Ratio, S1, 1_000_000, Big);
                  T_Dist := T_X
                    + Sqrt_Ceil (Div_Ceil (S1 * Ratio, 1_000_000)
                                 + S2_Q * 1_000_000);
               end;
            end if;

            --  A.3.12.8.1
            return Max (Tr, Min (Max (Div_Ceil (Tr + T_E, 2), T_Dist),
                                 I.T_Be));
         end;
      end;
   end T_Be_Reduced;

   ------------------
   -- T_Bs_Reduced --
   ------------------

   function T_Bs_Reduced (I : Input_T) return Time_T is
   begin
      if I.T_Bs_React > I.T_Bs
        or else I.T_Bs > G_Time'Last
        or else 2 * (I.T_Bs - I.T_Bs_React) < G_Ramp'First
        or else I.A_SB not in G_Decel
        or else I.A_Expected_Max not in G_Decel
      then
         return I.T_Bs;
      end if;

      declare
         Tr    : constant G_Time := I.T_Bs_React;
         T2    : constant Num := 2 * I.T_Bs - I.T_Bs_React;
         Incr  : constant G_Ramp := T2 - Tr;
         ASB   : constant G_Decel := I.A_SB;
         AEM   : constant G_Decel := I.A_Expected_Max;
         Vm    : constant G_Speed := I.V_Est * 1_000;
         Vt    : constant G_Speed := I.V_Target * 1_000;
         Vt_Cm : constant Num := I.V_Target;
         V_T2  : Num;
      begin
         --  A.3.12.3.4, .5
         if (I.Kind = Speed_Target and then I.V_Est <= I.V_Target)
           or else (I.Kind /= Speed_Target and then I.V_Est = 0)
         then
            return Tr;
         end if;

         --  A.3.12.4.4: V_t2bs, rounded up; A.3.12.4.5, .6
         V_T2 := Max (0, Vm - Div_Floor (ASB * Incr, 2_000));
         if (I.Kind = Speed_Target and then V_T2 >= Vt)
           or else (I.Kind /= Speed_Target and then V_T2 > 0)
         then
            return I.T_Bs;
         end if;

         declare
            --  A.3.12.5.2: t2bs_enough, rounded up
            DV   : constant Num := Max (0, Vm - Vt);
            T_E  : constant Num :=
              Min (Tr + Sqrt_Ceil (Div_Ceil (2 * Incr * DV, ASB) * 1_000),
                   T2);
            TT, B5, P5, D, Stop_Q, T_Dist : Num;
         begin
            --  A.3.12.6.2: D_t2bs_enough, 1e-6 cm, rounded up (the
            --  bounds as in T_Be_Reduced)
            TT := T_E - Tr;
            if T_E not in 0 .. G_Ramp'Last or else TT not in 0 .. Incr then
               return I.T_Bs;
            end if;
            B5 := Div_Floor (ASB * TT, Incr);
            if B5 not in 0 .. G_Decel'Last then
               return I.T_Bs;
            end if;
            P5 := B5 * TT;
            D := Vm * T_E - Div_Floor (P5 * TT, 6_000);
            Stop_Q := Div_Ceil (Vt_Cm * Vt_Cm * 1_000_000, 2 * AEM);
            if D not in -1_000_000_000_000_000 .. 1_000_000_000_000_000
              or else Stop_Q not in 0 .. 10_000_000_000_000
            then
               return I.T_Bs;
            end if;
            --  A.3.12.7.2 (V_est > 0 here), rounded up
            T_Dist := Div_Ceil (Max (D, 0) + Stop_Q * 1_000, Vm)
                      - Div_Floor (Vm * 1_000, 2 * AEM);
            --  A.3.12.8.1
            return Max (Tr, Min (Max (Div_Ceil (Tr + T_E, 2), T_Dist),
                                 I.T_Bs));
         end;
      end;
   end T_Bs_Reduced;

end EVC_Build_Up;
