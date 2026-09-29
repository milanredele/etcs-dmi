--  ETCS on-board (EVC)
--  The supervision limits, implementation.

package body EVC_Limits
  with SPARK_Mode => On
is

   ------------
   -- Margin --
   ------------

   --  A.3.1, tenths of km/h: dV_min, dV_max, V_min, V_max
   type Margin_Values_T is record
      D_Min, D_Max, V_Min, V_Max : Num;
   end record;
   type Margin_Table_T is array (Margin_Kind_T) of Margin_Values_T;
   Margins : constant Margin_Table_T :=
     (Warning => (40, 50, 1_100, 1_400),
      SBI     => (55, 100, 1_100, 2_100),
      EBI     => (75, 150, 1_100, 2_100));

   --  dV = min (dV_min + C * (V - V_min), dV_max) above V_min, with C =
   --  (dV_max - dV_min) / (V_max - V_min); V in cm/s is 0.36 V tenths of
   --  km/h, a tenth of km/h 25 / 9 cm/s: one division, rounded down
   function Margin (Kind : Margin_Kind_T; V : Speed_T) return Speed_T is
      C   : constant Margin_Values_T := Margins (Kind);
      R   : constant Num := C.V_Max - C.V_Min;
      Cap : constant Num := Div_Floor (C.D_Max * 25, 9);
   begin
      if 36 * V <= 100 * C.V_Min then
         return Div_Floor (C.D_Min * 25, 9);
      else
         return Min (Div_Floor ((C.D_Min * R * 100
                                 + (36 * V - 100 * C.V_Min)
                                   * (C.D_Max - C.D_Min)) * 25,
                                900 * R),
                     Cap);
      end if;
   end Margin;

   ---------
   -- F41 --
   ---------

   --  2 km/h below 30 km/h, then linearly up to 12 km/h at 500 km/h:
   --  (640 + 0.36 V) / 470 km/h = (64 000 + 36 V) / 1692 cm/s
   function F41 (V : Speed_T) return Speed_T is
     (Div_Ceil (Max (64_000 + 36 * V, 94_000), 1_692));

   ---------
   -- Bec --
   ---------

   function Bec (Terms : Terms_T; V_Target : Speed_T) return Bec_T is
      V      : constant Speed_T := Terms.V;
      --  3.13.9.3.2.3, .6
      T_Tr   : constant Time_T := T_Traction (Terms, Terms.T_Bs2);
      T_Rem  : constant Time_T := Max (Terms.T_Be - T_Tr, 0);
      --  3.13.9.3.2.10: V_delta1, V_delta2, V_bec, D_bec (in half cm/s
      --  before the division, rounded up)
      Vd1    : constant Speed_T :=
        Min (Gain_Ceil (Terms.A_Est1, T_Tr), Max_Speed);
      Vd2    : constant Speed_T :=
        Min (Gain_Ceil (Terms.A_Est2, T_Rem), Max_Speed);
      V0     : constant Num := V + Terms.V_Delta0;
   begin
      --  (the speeds are below 5 * Max_Speed and the times below Max_Time:
      --  the distances below 2 * 10**9 cm, the bound never applies)
      return (T_Traction => T_Tr,
              T_Berem    => T_Rem,
              V_Delta1   => Vd1,
              V_Delta2   => Vd2,
              V_Bec      => Max (V0 + Vd1, V_Target) + Vd2,
              D_Bec      =>
                Min (Div_Ceil (Max (2 * V0 + Vd1, 2 * V_Target) * T_Tr
                               + (2 * Max (V0 + Vd1, V_Target) + Vd2)
                                 * T_Rem,
                               2_000),
                     Distance_Bound),
              --  3.13.9.3.3.8: D_bedisplay
              D_Disp     =>
                Min (Div_Ceil ((2 * V0 + Vd1) * T_Tr
                               + (2 * (V0 + Vd1) + Vd2) * T_Rem, 2_000),
                     Distance_Bound));
   end Bec;

   ----------------
   -- EBD_Limits --
   ----------------

   function EBD_Limits (M        : Model_T;
                        P        : Profile_T;
                        EBD      : Curve_T;
                        V_Target : Speed_T;
                        D_Target : Dist_T;
                        With_GUI : Boolean;
                        GUI      : Curve_T;
                        Terms    : Terms_T;
                        X_Max    : Dist_T;
                        Stop     : Dist_T) return Limits_T
   is
      V      : constant Speed_T := Terms.V;
      B      : constant Bec_T := Bec (Terms, V_Target);
      V_Bec  : constant Num := B.V_Bec;
      D_Bec  : constant Num := B.D_Bec;
      D_Disp : constant Num := B.D_Disp;
      Deltas : constant Num := Terms.V_Delta0 + B.V_Delta1 + B.V_Delta2;
      L      : Limits_T;
   begin
      --  3.13.9.3.2.12: d_EBI = d_EBD (V_bec) - D_bec; a V_bec no curve
      --  reaches is behind Stop
      L.Curve := (if V_Bec > Max_Speed then Stop - 1
                  else Location_Of (M, P, EBD, V_Bec, Stop));
      L.EBI := L.Curve - D_Bec;
      --  3.13.9.3.3.2: SBI2
      L.SBI := L.EBI - Travel_Ceil (V, Terms.T_Bs2);
      --  3.13.9.3.4.1: W
      L.W := L.SBI - Travel_Ceil (V, T_Warning);
      --  3.13.9.3.5.1, .4: P, from SBI2 with T_driver (the part T_warning
      --  of it taken from W, which rounds rearwards)
      if With_GUI then
         L.P := Min (L.W - Travel_Ceil (V, T_Driver - T_Warning),
                     Location_Of (M, P, GUI, V, Stop));
      else
         L.P := Min (L.W - Travel_Ceil (V, T_Driver - T_Warning),
                     D_Target);
      end if;
      --  3.13.9.3.6.1: I
      L.I := L.P - Travel_Ceil (V, Terms.T_Ind);

      --  3.13.9.3.5.7, .8 and 3.13.9.3.3.8: the P and SBI2 speeds
      --  displayed for the max safe front end (the target speed beyond
      --  the foot, which Speed_At gives)
      declare
         X_P   : constant Num :=
           Min (X_Max + Travel_Ceil (V, Min (T_Driver + Terms.T_Bs2,
                                             Max_Time))
                + D_Disp, Max_Cm);
         X_S   : constant Num :=
           Min (X_Max + Travel_Ceil (V, Terms.T_Bs2) + D_Disp, Max_Cm);
         V_EBD : constant Num := Speed_At (M, P, EBD, X_P) - Deltas;
         V_P   : constant Num :=
           (if With_GUI
            then Max (Min (V_EBD, Speed_At (M, P, GUI, X_Max)), V_Target)
            else Max (V_EBD, V_Target));
      begin
         L.V_P := Min (V_P, Max_Speed);
         L.V_SBI :=
           Min (Max (Speed_At (M, P, EBD, X_S) - Deltas,
                     V_Target + Margin (SBI, V_Target)),
                Max_Speed);
      end;
      return L;
   end EBD_Limits;

   ----------------
   -- EOA_Limits --
   ----------------

   function EOA_Limits (M        : Model_T;
                        P        : Profile_T;
                        SBD      : Curve_T;
                        With_GUI : Boolean;
                        GUI      : Curve_T;
                        Terms    : Terms_T;
                        X_Est    : Dist_T;
                        Stop     : Dist_T) return Limits_T
   is
      V : constant Speed_T := Terms.V;
      L : Limits_T;
   begin
      --  3.13.9.3.3.1: SBI1 = d_SBD (V_est) - V_est * T_bs1; the EOA has
      --  no EBI of its own (EBI is kept at the SBD for the order)
      L.Curve := Location_Of (M, P, SBD, V, Stop);
      L.EBI := L.Curve;
      L.SBI := L.Curve - Travel_Ceil (V, Terms.T_Bs1);
      --  3.13.9.3.4.1, 3.13.9.3.5.1, .4, 3.13.9.3.6.1
      L.W := L.SBI - Travel_Ceil (V, T_Warning);
      if With_GUI then
         L.P := Min (L.W - Travel_Ceil (V, T_Driver - T_Warning),
                     Location_Of (M, P, GUI, V, Stop));
      else
         L.P := L.W - Travel_Ceil (V, T_Driver - T_Warning);
      end if;
      L.I := L.P - Travel_Ceil (V, Terms.T_Ind);

      --  3.13.9.3.5.5, .6 and 3.13.9.3.3.7: the P and SBI1 speeds for
      --  the estimated front end (0 beyond the EOA, which Speed_At gives)
      declare
         X_P : constant Num :=
           Min (X_Est + Travel_Ceil (V, Min (T_Driver + Terms.T_Bs1,
                                             Max_Time)), Max_Cm);
         X_S : constant Num :=
           Min (X_Est + Travel_Ceil (V, Terms.T_Bs1), Max_Cm);
         V_P : constant Num :=
           (if With_GUI
            then Min (Speed_At (M, P, SBD, X_P), Speed_At (M, P, GUI, X_Est))
            else Speed_At (M, P, SBD, X_P));
      begin
         L.V_P := V_P;
         L.V_SBI := Speed_At (M, P, SBD, X_S);
      end;
      return L;
   end EOA_Limits;

   -----------------
   -- P_At_Target --
   -----------------

   function P_At_Target (M          : Model_T;
                         P          : Profile_T;
                         EBD        : Curve_T;
                         V_Target   : Speed_T;
                         D_Target   : Dist_T;
                         V_Delta0t  : Speed_T;
                         T_Be_React : Time_T;
                         T_Traction_Max : Time_T;
                         T_Bs_Foot  : Time_T;
                         Stop       : Dist_T) return Num
   is
      V1    : constant Num := V_Target + V_Delta0t;
      --  3.13.9.3.5.10: T_berem_min = MAX (T_be_react - T_traction_max, 0)
      T_Rem : constant Time_T := Max (T_Be_React - T_Traction_Max, 0);
      Loc   : constant Num :=
        (if V1 > Max_Speed then Stop - 1
         else Location_Of (M, P, EBD, V1, Stop));
      EBI   : Num;
   begin
      if V1 > Max_Speed then
         EBI := Loc;
      else
         EBI := Loc - Travel_Ceil (V1, Min (T_Rem + T_Traction_Max, Max_Time));
      end if;
      return Min (EBI - Travel_Ceil (V_Target, Min (T_Driver + T_Bs_Foot,
                                                    Max_Time)),
                  D_Target);
   end P_At_Target;

end EVC_Limits;
