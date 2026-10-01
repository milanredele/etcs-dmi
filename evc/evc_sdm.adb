--  ETCS on-board (EVC)
--  Speed and distance monitoring, implementation.
--
--  Decisions where 3.13 leaves a choice or where this phase has less
--  than the SRS assumes (each stated where it is applied):
--    - the MRSP before its first element takes the speed of the first
--      element (the stored information starts it at or behind the
--      train);
--    - T_be_reduced and T_bs_reduced (A.3.12, EVC_Build_Up) are those
--      of the train's current speed for every target; the locations
--      calculated in advance (the RSM start, the release speed, the
--      perturbation location) take T_be as 3.13.9.4 and 3.13.11 say or
--      as the safe side;
--    - a service brake commanded in ceiling speed monitoring and carried
--      into release speed monitoring is revoked at the release speed
--      (3.13.10.6.2 gives no revocation for it there, 3.13.10.6.4 revokes
--      the one of target speed monitoring at once);
--    - an Intervention status without any brake command (only after
--      3.13.10.6.4 revoked the service brake) becomes the status of the
--      monitoring without intervention (3.13.10.2.5);
--    - the list of supervised targets is "updated" (Table 16 [4], [5])
--      when its content differs from the last cycle's;
--    - the acceleration of the train is measured from the estimated
--      speed of successive cycles, filtered with a time constant of 1 s.

with EVC_Build_Up;
with EVC_Curves; use EVC_Curves;
with EVC_Limits; use EVC_Limits;

package body EVC_SDM
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------
   --  The context of a cycle
   ---------------------------------------------------------------------

   --  Locations of limits and distances between them
   subtype Loc_T is Num range -8 * Max_Cm .. 8 * Max_Cm;

   type Ctx_T is record
      X_Est, X_Max, X_Min : Dist_T := 0;
      --  locations of limits behind Stop are only known to be behind
      Stop        : Dist_T := 0;
      V           : Speed_T := 0;
      V_Ura       : Speed_T := 0;
      A1          : Decel_T := 0;   -- A_est1
      A2          : Decel_T := 0;   -- A_est2
      V_MRSP      : Speed_T := 0;
      M_W         : Speed_T := 0;   -- V_MRSP + dV_warning (V_MRSP)
      M_SBI       : Speed_T := 0;   -- V_MRSP + dV_sbi (V_MRSP)
      M_EBI       : Speed_T := 0;   -- V_MRSP + dV_ebi (V_MRSP)
      Standstill  : Boolean := True;
      --  3.13.10.4.9: the service brake command available for use
      SB_Avail    : Boolean := False;
      --  A.3.10.2: the service brake feedback available for use, and its
      --  state in this cycle
      Feedback    : Boolean := False;
      Fb_Active   : Boolean := False;
      Fb_Locked   : Boolean := False;
      Fb_Ratio    : Factor_T := 1_000;
      --  3.13.8.5.2: the guidance curves are computed
      GUI         : Boolean := False;
      --  3.13.9.3.2.1: the compensation of the speed inaccuracy inhibited
      Inhibit     : Boolean := False;
      TCO         : Boolean := True;
      T_TCO       : Time_T := 0;
      --  3.13.9.4: the release speed, and its value in Tables 9 and 11
      --  (3.13.10.4.13: 0 when none or not below V_MRSP)
      Release     : Speed_T := 0;
      Has_Release : Boolean := False;
      V_Rel_Table : Speed_T := 0;
      --  3.13.9.4.8.2: the trip location of the EOA, and whether the
      --  release speed is calculated on-board
      Trip        : Loc_T := 0;
      Calculated  : Boolean := False;
      SvL         : Dist_T := 0;
      --  A.3.12.1.4: the conversion model with Kt_int = 0
      Kt_Zero     : Boolean := False;
   end record;

   --  The time margins of a target (3.13.6.2.2.3, 3.13.6.3.2.4)
   type Times4_T is record
      Be_React, Be, Bs_React, Bs : Time_T := 0;
   end record;

   function Times_Of (M : Model_T; T : Target_T) return Times4_T is
     (if T.Speed = 0
      then (Be_React => M.Emergency_Zero.React,
            Be       => M.Emergency_Zero.Build_Up,
            Bs_React => M.Service_Zero.React,
            Bs       => M.Service_Zero.Build_Up)
      else (Be_React => M.Emergency_Target.React,
            Be       => M.Emergency_Target.Build_Up,
            Bs_React => M.Service_Target.React,
            Bs       => M.Service_Target.Build_Up));

   type Service_T is record
      Bs1, Bs2 : Time_T := 0;
   end record;

   --  3.13.9.3.3.3 to .5 and A.3.10.4: T_bs1 and T_bs2 of a target with
   --  T_bs and T_bs_reduced; Indication: for the Indication limit
   --  (3.13.9.3.6.5)
   function Service_Times (C          : Ctx_T;
                           Bs         : Time_T;
                           Bs_Reduced : Time_T;
                           Indication : Boolean) return Service_T
   is
      T1 : Time_T;
   begin
      if not C.SB_Avail then
         return (0, 0);
      elsif not C.Feedback then
         --  3.13.9.3.3.3
         return (Bs_Reduced, Bs_Reduced);
      elsif Indication then
         return (Bs, Bs);
      end if;
      if C.Fb_Locked then
         T1 := 0;
      elsif C.Fb_Active then
         T1 := Min (Div_Ceil (Bs * C.Fb_Ratio, 1_000), Bs);
      else
         T1 := Bs;
      end if;
      --  A.3.10.4 (T_bs2 not below T_bs2_locked once reduced) and
      --  3.13.9.3.3.4.1
      return (T1, Max (T1, T_Bs2_Locked));
   end Service_Times;

   --  3.13.9.3.6.2, .4: T_indication
   function T_Indication (C : Ctx_T; Bs : Time_T) return Time_T is
     (if C.Feedback then 5_000 + T_Driver
      else Min (Max (Div_Ceil (8 * Bs, 10), 5_000) + T_Driver, Max_Time));

   --  3.13.8.3.1 to .3: the EBD of a target
   function EBD_Of (T : Target_T) return Curve_T is
     (case T.Kind is
         when MRSP_Target | LOA_Target =>
           (Kind     => EBD,
            Anchor   => T.Location,
            Anchor_W => Square (Min (T.Speed + Margin (EBI, T.Speed),
                                     Max_Speed)),
            --  (T.Speed squared, which the anchor's square is never
            --  below)
            Floor_W  => Min (Square (T.Speed),
                             Square (Min (T.Speed + Margin (EBI, T.Speed),
                                          Max_Speed))),
            TSR      => T.TSR),
         when EOA_Target | SR_Target =>
           (Kind => EBD, Anchor => T.Location, Anchor_W => 0,
            Floor_W => 0, TSR => False))
     with Post => EBD_Of'Result.Floor_W <= EBD_Of'Result.Anchor_W;

   --  A.3.12.2.7, .8: T_traction_max
   function T_Traction_Max (C : Ctx_T; Times : Times4_T) return Time_T is
     (if C.TCO
      then Max (C.T_TCO - (T_Warning
                           + (if C.SB_Avail then Times.Bs_React else 0)), 0)
      else C.T_TCO);

   ---------------------------------------------------------------------
   --  The reduced brake build up times of a target (A.3.12)
   ---------------------------------------------------------------------

   type Reduced_T is record
      Be : Time_T := 0;   -- T_be_reduced
      Bs : Time_T := 0;   -- T_bs_reduced
   end record;

   --  For the EBD part of a target (the SvL of an EOA target), or with
   --  EOA_Part for its EOA, at the speed V
   function Reduced_Of (Work       : Work_T;
                        C          : Ctx_T;
                        T          : Target_T;
                        V          : Speed_T;
                        In_Advance : Boolean;
                        EOA_Part   : Boolean) return Reduced_T
   is
      Times : constant Times4_T := Times_Of (Work.Model, T);
      Vd0   : constant Speed_T :=
        (if C.Inhibit then 0 elsif In_Advance then F41 (V) else C.V_Ura);
      A1    : constant Decel_T := (if In_Advance then 0 else C.A1);
      A2    : constant Decel_T := (if In_Advance then 0 else C.A2);
      --  A.3.12.2.6 to .8
      T_Min : constant Time_T :=
        (if C.TCO
         then Max (C.T_TCO - (T_Warning
                              + (if C.SB_Avail then Times.Bs else 0)), 0)
         else C.T_TCO);
      T_Max : constant Time_T := T_Traction_Max (C, Times);
      --  A.3.12.2.2: V_bec with T_be (the longest traction time: the
      --  widest range of speeds)
      V_Bec : constant Speed_T :=
        Min (Max (V + Vd0 + Min (Gain_Ceil (A1, T_Max), Max_Speed),
                  T.Speed)
             + Min (Gain_Ceil (A2, Max (Times.Be - T_Max, 0)), Max_Speed),
             Max_Speed);
      Zero  : constant Boolean := T.Kind in EOA_Target | SR_Target;
      Ext   : constant Extremes_T :=
        Extremes (Work.Model, Work.Profile, T.TSR, C.X_Est,
                  (if EOA_Part then T.EOA else T.Location), C.X_Min,
                  V_EB_Lo => (if Zero then 0 else T.Speed),
                  V_EB_Hi => V_Bec,
                  V_SB_Lo => (if Zero then 0 else T.Speed),
                  V_SB_Hi => V);
      Input : constant EVC_Build_Up.Input_T :=
        (Kind           => (if EOA_Part then EVC_Build_Up.EOA_Target
                            elsif Zero then EVC_Build_Up.Zero_Target
                            else EVC_Build_Up.Speed_Target),
         V_Est          => V,
         V_Delta0       => Vd0,
         V_Target       => T.Speed,
         A_Est1         => A1,
         A_Est2         => A2,
         T_Be_React     => Times.Be_React,
         T_Be           => Times.Be,
         T_Bs_React     => Times.Bs_React,
         T_Bs           => Times.Bs,
         T_Traction     => T_Max,
         T_Traction_Min => T_Min,
         T_Traction_Max => T_Max,
         A_EB           => Ext.A_EB,
         A_Safe_Max     => Ext.A_Safe_Max,
         A_SB           => Ext.A_SB,
         A_Expected_Max => Ext.A_Expected_Max,
         Kt_Zero        => C.Kt_Zero);
   begin
      return (Be => EVC_Build_Up.T_Be_Reduced (Input),
              --  3.13.6.3.2.5: T_bs with the service brake feedback
              Bs => (if C.Feedback then Times.Bs
                     else EVC_Build_Up.T_Bs_Reduced (Input)));
   end Reduced_Of;

   ---------------------------------------------------------------------
   --  The limits of a target at a speed
   ---------------------------------------------------------------------

   type Eval_T is record
      L        : Limits_T;   -- the EBD based limits (the SvL of an EOA)
      E        : Limits_T;   -- the EOA
      P_Target : Num := 0;   -- 3.13.9.3.5.9 for MRSP and LOA targets
      --  A.3.13: a build up time of the target is reduced
      Reduced  : Boolean := False;
   end record;

   --  V_Delta0 and the accelerations: the ones of the train, or those of
   --  a location calculated in advance (zero acceleration, the speed
   --  accuracy of SUBSET-041 at V)
   function Terms_Of (C          : Ctx_T;
                      V          : Speed_T;
                      Times      : Times4_T;
                      Red        : Reduced_T;
                      Indication : Boolean;
                      In_Advance : Boolean) return Terms_T
   is
      Serv : constant Service_T :=
        Service_Times (C, Times.Bs, Red.Bs, Indication);
   begin
      return (V        => V,
              V_Delta0 => (if C.Inhibit then 0
                           elsif In_Advance then F41 (V)
                           else C.V_Ura),
              A_Est1   => (if In_Advance then 0 else C.A1),
              A_Est2   => (if In_Advance then 0 else C.A2),
              T_Be     => Red.Be,
              T_Bs1    => Serv.Bs1,
              T_Bs2    => Serv.Bs2,
              T_Ind    => T_Indication (C, Red.Bs),
              TCO      => C.TCO,
              T_Traction_Cut_Off => C.T_TCO);
   end Terms_Of;

   function Evaluate (Work       : Work_T;
                      C          : Ctx_T;
                      T          : Target_T;
                      V          : Speed_T;
                      In_Advance : Boolean) return Eval_T
     with Pre => C.Stop > -Max_Cm,
          Post => Ordered (Evaluate'Result.L)
                  and then Ordered (Evaluate'Result.E)
                  and then Evaluate'Result.L.I in Location_T
                  and then Evaluate'Result.L.Curve in Location_T
                  and then Evaluate'Result.E.I in Location_T
                  and then Evaluate'Result.E.Curve in Location_T
                  and then Evaluate'Result.P_Target in Location_T
   is
      Times : constant Times4_T := Times_Of (Work.Model, T);
      Red_L : constant Reduced_T :=
        Reduced_Of (Work, C, T, V, In_Advance, EOA_Part => False);
      Red_E : constant Reduced_T :=
        (if T.Kind = EOA_Target
         then Reduced_Of (Work, C, T, V, In_Advance, EOA_Part => True)
         else Red_L);
      Terms : constant Terms_T :=
        Terms_Of (C, V, Times, Red_L, False, In_Advance);
      Terms_E : constant Terms_T :=
        Terms_Of (C, V, Times, Red_E, False, In_Advance);
      Curve : constant Curve_T := EBD_Of (T);
      Serv  : constant Service_T :=
        Service_Times (C, Times.Bs, Red_L.Bs, False);
      R     : Eval_T;
      GUI_Curve : Curve_T;
   begin
      R.Reduced :=
        Red_L.Be < Times.Be
        or else (C.SB_Avail and then not C.Feedback
                 and then (Red_L.Bs < Times.Bs or else Red_E.Bs < Times.Bs));
      if T.Kind in MRSP_Target | LOA_Target then
         R.P_Target :=
           P_At_Target
             (Work.Model, Work.Profile, Curve, T.Speed, T.Location,
              (if C.Inhibit then 0 else F41 (T.Speed)),
              Times.Be_React,
              T_Traction_Max (C, Times),
              (if C.SB_Avail and then not C.Feedback then Times.Bs_React
               else Serv.Bs2),
              C.Stop);
         --  3.13.8.5.2 b): the foot of the GUI is that location
         GUI_Curve := (Kind     => GUI,
                       Anchor   => Clamp (R.P_Target),
                       Anchor_W => Square (T.Speed),
                       Floor_W  => Square (T.Speed),
                       TSR      => T.TSR);
      else
         R.P_Target := T.Location;
         GUI_Curve := (Kind => GUI, Anchor => T.Location, Anchor_W => 0,
                       Floor_W => 0, TSR => T.TSR);
      end if;
      R.L := EBD_Limits (Work.Model, Work.Profile, Curve, T.Speed,
                         T.Location, C.GUI, GUI_Curve, Terms, C.X_Max,
                         C.Stop);
      if T.Kind = EOA_Target then
         R.E := EOA_Limits
           (Work.Model, Work.Profile,
            (Kind => SBD, Anchor => T.EOA, Anchor_W => 0, Floor_W => 0,
             TSR => T.TSR),
            C.GUI,
            (Kind => GUI, Anchor => T.EOA, Anchor_W => 0, Floor_W => 0,
             TSR => T.TSR),
            Terms_E, C.X_Est, C.Stop);
      else
         R.E := R.L;
      end if;

      --  3.13.9.3.6.5: with the service brake feedback the Indication
      --  limit is calculated with T_bs1 = T_bs2 = T_bs (taken no later
      --  than P)
      if C.Feedback and then C.SB_Avail then
         declare
            Terms_I : constant Terms_T :=
              Terms_Of (C, V, Times, Red_L, True, In_Advance);
            Terms_IE : constant Terms_T :=
              Terms_Of (C, V, Times, Red_E, True, In_Advance);
            I_L : constant Limits_T :=
              EBD_Limits (Work.Model, Work.Profile, Curve, T.Speed,
                          T.Location, C.GUI, GUI_Curve, Terms_I, C.X_Max,
                          C.Stop);
         begin
            R.L.I := Min (I_L.I, R.L.P);
            if T.Kind = EOA_Target then
               declare
                  I_E : constant Limits_T := EOA_Limits
                    (Work.Model, Work.Profile,
                     (Kind => SBD, Anchor => T.EOA, Anchor_W => 0,
                      Floor_W => 0, TSR => T.TSR),
                     C.GUI,
                     (Kind => GUI, Anchor => T.EOA, Anchor_W => 0,
                      Floor_W => 0, TSR => T.TSR),
                     Terms_IE, C.X_Est, C.Stop);
               begin
                  R.E.I := Min (I_E.I, R.E.P);
               end;
            else
               R.E := R.L;
            end if;
         end;
      end if;
      return R;
   end Evaluate;

   ---------------------------------------------------------------------
   --  The conditions of Tables 8 to 11 for one target
   ---------------------------------------------------------------------

   type Flags_T is record
      Ind, Ovs, Was, SB, EB : Boolean := False;
      --  a revocation condition (r1 or r3) holds for the target
      Rev        : Boolean := False;
      --  3.13.10.4.2: the target is a concerned target, with its P
      Concerned  : Boolean := False;
      V_P0       : Speed_T := Max_Speed;
      --  Table 16 [1]: the Indication location passed (and without the
      --  SvL and the targets between the trip location and it)
      Passed_I   : Boolean := False;
      Passed_I_B : Boolean := False;
   end record;

   function Flags_Of (C       : Ctx_T;
                      T       : Target_T;
                      R       : Eval_T;
                      Between : Boolean) return Flags_T
   is
      V   : constant Speed_T := C.V;
      VM  : constant Speed_T := C.V_MRSP;
      L   : Limits_T renames R.L;
      E   : Limits_T renames R.E;
      F   : Flags_T;
   begin
      case T.Kind is
         when MRSP_Target | LOA_Target =>
            if T.Speed < VM then
               --  Table 8, Table 10
               declare
                  Vt     : constant Speed_T := T.Speed;
                  In_TS  : constant Boolean := Vt < V and then V <= VM;
               begin
                  F.Ind := In_TS and then L.I < C.X_Max
                           and then C.X_Max <= L.P;                    -- t3
                  F.Ovs := (In_TS and then C.X_Max > L.P)              -- t4
                           or else (VM < V and then V <= C.M_W
                                    and then C.X_Max <= L.W);          -- t6
                  F.Was := (Vt + Margin (Warning, Vt) < V
                            and then V <= C.M_W
                            and then C.X_Max > L.W)                    -- t7
                           or else (C.M_W < V and then V <= C.M_SBI
                                    and then C.X_Max <= L.SBI);        -- t9
                  F.SB  := (Vt + Margin (SBI, Vt) < V
                            and then V <= C.M_SBI
                            and then C.X_Max > L.SBI)                  -- t10
                           or else (C.M_SBI < V and then V <= C.M_EBI
                                    and then C.X_Max <= L.EBI);        -- t12
                  F.EB  := (Vt + Margin (EBI, Vt) < V
                            and then V <= C.M_EBI
                            and then C.X_Max > L.EBI);                 -- t13
                  F.Rev := V <= Vt                                     -- r1
                           or else (V <= VM and then C.X_Max <= L.P);  -- r3
                  F.Concerned := C.X_Max > L.I and then V >= Vt;
                  F.V_P0 := L.V_P;
                  F.Passed_I := Vt < V and then C.X_Max > L.I;
                  F.Passed_I_B := F.Passed_I and then not Between;
               end;
            else
               --  3.13.10.4.10.1: no condition for a target not below
               --  V_MRSP; it does not prevent a revocation where the
               --  ceiling does not
               F.Rev := V <= VM;
            end if;

         when EOA_Target | SR_Target =>
            --  Table 9, Table 11 (3.13.10.4.13.1: the SR end as an SvL,
            --  without the EOA)
            declare
               Vr    : constant Speed_T :=
                 (if T.Kind = EOA_Target then C.V_Rel_Table else 0);
               EOA   : constant Boolean := T.Kind = EOA_Target;
               I_P   : constant Boolean :=
                 C.X_Max > L.I or else (EOA and then C.X_Est > E.I);
               P_P   : constant Boolean :=
                 C.X_Max > L.P or else (EOA and then C.X_Est > E.P);
               W_P   : constant Boolean :=
                 C.X_Max > L.W or else (EOA and then C.X_Est > E.W);
               S_P   : constant Boolean :=
                 C.X_Max > L.SBI or else (EOA and then C.X_Est > E.SBI);
               E_P   : constant Boolean := C.X_Max > L.EBI;
               Eq    : constant Boolean := V = Vr;
               In_TS : constant Boolean := Vr < V and then V <= VM;
            begin
               F.Ind := (Eq and then I_P)                              -- t0
                        or else (In_TS and then I_P and then not P_P); -- t3
               F.Ovs := (Eq and then P_P)                              -- t1
                        or else (In_TS and then P_P)                   -- t4
                        or else (VM < V and then V <= C.M_W
                                 and then not W_P);                    -- t6
               F.Was := (Eq and then W_P)                              -- t2
                        or else (Vr < V and then V <= C.M_W
                                 and then W_P)                         -- t7
                        or else (C.M_W < V and then V <= C.M_SBI
                                 and then not S_P);                    -- t9
               F.SB  := (Vr < V and then V <= C.M_SBI and then S_P)    -- t10
                        or else (C.M_SBI < V and then V <= C.M_EBI
                                 and then not E_P);                    -- t12
               F.EB  := Vr < V and then V <= C.M_EBI and then E_P;     -- t13
               F.Rev := V <= Vr                                        -- r1
                        or else (V <= VM and then not P_P);            -- r3
               F.Concerned := I_P;
               F.V_P0 :=
                 Min ((if EOA and then C.X_Est > E.I then E.V_P
                       else Max_Speed),
                      (if C.X_Max > L.I then L.V_P else Max_Speed));
               F.Passed_I := V > 0 and then I_P;
               F.Passed_I_B := False;
            end;
      end case;
      --  t15 of Tables 8 and 9
      if V > C.M_EBI then
         F.EB := True;
      end if;
      return F;
   end Flags_Of;

   ---------------------------------------------------------------------
   --  The targets
   ---------------------------------------------------------------------

   function Same (A, B : Target_T) return Boolean is
     (A.Kind = B.Kind and then A.Location = B.Location
      and then A.Speed = B.Speed
      and then (A.Kind /= EOA_Target or else A.EOA = B.EOA));

   --  A digest of a target for the signature of the list
   function Digest (T : Target_T) return Num is
     ((Target_Kind_T'Pos (T.Kind) + 1) * 1_000_003
      + (T.Location mod 1_000_000_007) * 31
      + (T.EOA mod 1_000_000_007) * 7
      + T.Speed);

   ---------------------------------------------------------------------
   --  The service brake feedback (A.3.10)
   ---------------------------------------------------------------------

   --  Returns, besides the state, whether the displayed values are to be
   --  locked (A.3.10.4: the feedback reduced T_bs1)
   procedure Update_Feedback (F            : in out Feedback_T;
                              S            : Snapshot_T;
                              Inputs       : Inputs_T;
                              Target_Or_RSM : Boolean;
                              Ratio        : out Factor_T;
                              Lock         : out Boolean)
   is
      Config    : Onboard_Config_T renames S.Extra.Config;
      Available : constant Boolean :=
        Config.Service_Brake_Feedback and then S.National.Q_NVSBFBPERM
        and then Inputs.Pressure_Known;
      Dt        : constant Time_T := Min (Num (Inputs.Dt_Ms), Max_Time);
      P         : Num;   -- tenths of kPa
   begin
      Ratio := 1_000;
      Lock := False;
      if not Available then
         F.Active := False;
         F.Locked := False;
         F.Ratio_Prev := 1_000;
         return;
      end if;
      --  A.3.10.3: a brake cylinder pressure as a fictive brake pipe
      --  pressure, p = 500 - p_cylinder / k1; p limited to 550 kPa
      if Config.Feedback_From_Cylinder then
         P := 5_000 - Div_Floor (Num (Inputs.Pressure) * 10_000,
                                 Num (Config.K1_Milli));
      else
         P := Num (Inputs.Pressure) * 10;
      end if;
      P := Max (Min (P, 5_500), 0);

      --  the reference pressure p0: the first value between 400 and
      --  550 kPa stable within 20 kPa for 3 s, then adapted once a
      --  second (A.3.10.4, table of conditions)
      if not F.P0_Known then
         if P < F.Window_Lo or else P > F.Window_Hi then
            F.Window_Lo := Max (P - 200, 0);
            F.Window_Hi := Min (P + 200, 11_000);
            F.Window_Ms := 0;
         else
            F.Window_Ms := Min (F.Window_Ms + Dt, Max_Time);
            if F.Window_Ms >= 3_000 and then P in 4_000 .. 5_500 then
               F.P0 := P;
               F.P0_Known := True;
               F.Adapt_Ms := 0;
            end if;
         end if;
      else
         F.Adapt_Ms := Min (F.Adapt_Ms + Dt, Max_Time);
         for Second in 1 .. 10 loop
            exit when F.Adapt_Ms < 1_000;
            F.Adapt_Ms := F.Adapt_Ms - 1_000;
            if P > F.P0 then
               F.P0 := Min (F.P0 + 15, 5_500);         -- b)
            elsif P < F.P0 and then P > F.P0 - 300 then
               F.P0 := Max (F.P0 - 5, 0);              -- d)
            end if;
         end loop;
      end if;

      if not Target_Or_RSM or else not F.P0_Known then
         F.Active := False;
         F.Locked := False;
         F.Ratio_Prev := 1_000;
         return;
      end if;

      declare
         P1 : constant Num := F.P0 - 300;
         P2 : constant Num := F.P0 - 600;
         P3 : constant Num := F.P0 - 1_500;
      begin
         if F.Locked then
            Ratio := 0;
         elsif P > P2 then
            if F.Active or else P <= P1 then
               F.Active := True;
               --  T_bs_feedback / T_bs = (p - p3) / (p0 - p3), rounded up
               Ratio := Min (Div_Ceil ((P - P3) * 1_000, F.P0 - P3), 1_000);
            end if;
         else
            F.Locked := True;
            F.Active := True;
            Ratio := 0;
         end if;
      end;
      if F.Active and then Ratio < F.Ratio_Prev then
         Lock := True;
      end if;
      F.Ratio_Prev := Ratio;
   end Update_Feedback;

   ---------------------------------------------------------------------
   --  Release speed (3.13.9.4)
   ---------------------------------------------------------------------

   --  3.13.9.4.8: the EBD based targets the calculated release speed
   --  looks at: the SvL and the targets between the trip location of the
   --  EOA and the SvL
   function Between (C : Ctx_T; T : Target_T) return Boolean is
     (C.Calculated and then T.Kind = MRSP_Target
      and then T.Location > C.Trip and then T.Location <= C.SvL);

   --  3.13.9.4.8.2: the release speed of one target: the largest speed V
   --  (above the target speed) with V <= V_EBD (d_tripEOA + alpha * D41
   --  + D_bec) - V_delta0rsob, found by bisection (Release_Iterations
   --  steps; the right hand side falls when V grows, 3.13.9.4.8.2.2
   --  leaves the method open). The fixed point lies within 1 cm/s,
   --  inside the 1 km/h of the inequality.
   Release_Iterations : constant := 16;

   function Release_Of (Work   : Work_T;
                        C      : Ctx_T;
                        T      : Target_T;
                        Alpha  : Boolean) return Speed_T
   is
      Times : constant Times4_T := Times_Of (Work.Model, T);
      Curve : constant Curve_T := EBD_Of (T);
      --  T_traction and T_berem as in 3.13.9.3.2 with the traction
      --  cut-off taken as not implemented and T_be not reduced
      T_Tr  : constant Time_T := C.T_TCO;
      T_Rem : constant Time_T := Max (Times.Be - T_Tr, 0);

      function Fits (V : Speed_T) return Boolean is
         Vd0 : constant Num :=
           (if C.Inhibit then 0 else Max (F41 (V), C.V_Ura));
         V0  : constant Speed_T := Min (V + Vd0, Max_Speed);
         D41 : constant Num :=
           (if Alpha then Travel_Ceil (V0, T_41) else 0);
         Dbec : constant Num :=
           Travel_Ceil (V0, Min (T_Tr + T_Rem, Max_Time));
         X   : constant Num := Min (C.Trip + Min (D41 + Dbec, Max_Cm), Max_Cm);
      begin
         return V + Vd0 <= Speed_At (Work.Model, Work.Profile, Curve,
                                     Max (X, -Max_Cm));
      end Fits;

      Lo : Speed_T := T.Speed;
      Hi : Speed_T := 30_001;
   begin
      if Lo >= Hi - 1 or else not Fits (Lo + 1) then
         return Lo;
      end if;
      Lo := Lo + 1;
      for Step in 1 .. Release_Iterations loop
         pragma Loop_Invariant (Lo < Hi);
         exit when Hi - Lo <= 1;
         declare
            Mid : constant Speed_T := Lo + (Hi - Lo) / 2;
         begin
            if Fits (Mid) then
               Lo := Mid;
            else
               Hi := Mid;
            end if;
         end;
      end loop;
      return Lo;
   end Release_Of;

   --  3.13.9.4.8: the most restrictive of the release speeds of the SvL
   --  and of the targets between the trip location and the SvL
   function Calculated_Release (Work  : Work_T;
                                C     : Ctx_T;
                                Alpha : Boolean) return Speed_T
   is
      Best : Speed_T := Max_Speed;
   begin
      for K in 1 .. Work.Count loop
         declare
            T : constant Target_T := Work.Targets (K);
         begin
            if T.Kind = EOA_Target or else Between (C, T) then
               Best := Min (Best, Release_Of (Work, C, T, Alpha));
            end if;
         end;
      end loop;
      return (if Best = Max_Speed then 0 else Best);
   end Calculated_Release;

   --  3.13.9.4.6, .7: the start location of the release speed monitoring
   --  for the release speed V_r: SBI1 (V_r) of the EOA, and the most
   --  restrictive SBI2 (V_r) of the SvL and, calculated on-board, of the
   --  targets between the trip location and the SvL
   type RSM_Start_T is record
      SBI1     : Loc_T := 0;
      SBI2     : Loc_T := 0;
      Start    : Loc_T := 0;
      From_SBD : Boolean := True;
   end record;

   function RSM_Start (Work : Work_T; C : Ctx_T; EOA_T : Target_T;
                       V_R  : Speed_T) return RSM_Start_T
     with Pre => C.Stop > -Max_Cm
   is
      R     : RSM_Start_T;
      Vd0   : constant Speed_T := (if C.Inhibit then 0 else F41 (V_R));
      V1    : constant Speed_T := Min (V_R + Vd0, Max_Speed);
      Times : constant Times4_T := Times_Of (Work.Model, EOA_T);
      Serv  : constant Service_T :=
        Service_Times (C, Times.Bs, Times.Bs, False);
      EOA_SBD : constant Curve_T :=
        (Kind => SBD, Anchor => EOA_T.EOA, Anchor_W => 0, Floor_W => 0,
         TSR => False);
      MR    : Num := Max_Cm + Max_Forward;
   begin
      R.SBI1 := Location_Of (Work.Model, Work.Profile, EOA_SBD, V_R, C.Stop)
                - Travel_Ceil (V_R, Serv.Bs1);
      for K in 1 .. Work.Count loop
         pragma Loop_Invariant (MR in -4 * Max_Cm .. Max_Cm + Max_Forward);
         declare
            T : constant Target_T := Work.Targets (K);
         begin
            if T.Kind = EOA_Target or else Between (C, T) then
               declare
                  Tt    : constant Times4_T := Times_Of (Work.Model, T);
                  St    : constant Service_T :=
                    Service_Times (C, Tt.Bs, Tt.Bs, False);
                  Terms : constant Terms_T :=
                    (V => V_R, V_Delta0 => Vd0, A_Est1 => 0, A_Est2 => 0,
                     T_Be => Tt.Be, T_Bs1 => St.Bs1, T_Bs2 => St.Bs2,
                     T_Ind => 0, TCO => C.TCO,
                     T_Traction_Cut_Off => C.T_TCO);
                  T_Tr  : constant Time_T := T_Traction (Terms, St.Bs2);
                  T_Rem : constant Time_T := Max (Tt.Be - T_Tr, 0);
                  SBI2  : constant Num :=
                    Location_Of (Work.Model, Work.Profile, EBD_Of (T), V1,
                                 C.Stop)
                    - Travel_Ceil (V1, Min (T_Rem + T_Tr, Max_Time))
                    - Travel_Ceil (V_R, St.Bs2);
               begin
                  MR := Min (MR, SBI2);
               end;
            end if;
         end;
      end loop;
      R.SBI2 := MR;
      if MR - R.SBI1 >= C.X_Max - C.X_Est then
         R.Start := R.SBI1;
         R.From_SBD := True;
      else
         R.Start := MR;
         R.From_SBD := False;
      end if;
      return R;
   end RSM_Start;

   ---------------------------------------------------------------------
   --  Perturbation location (3.13.11)
   ---------------------------------------------------------------------

   --  3.13.11.3, .4, .7: the Indication location for the speed of an
   --  MRSP element (zero acceleration, the speed accuracy of SUBSET-041,
   --  no effect of the service brake feedback, T_be not reduced), from
   --  the EBD of the SvL or LOA or from the SBD of the EOA
   function Indication_For (Work    : Work_T;
                            C       : Ctx_T;
                            T       : Target_T;
                            V       : Speed_T;
                            Use_SBD : Boolean) return Num
   is
      Times : constant Times4_T := Times_Of (Work.Model, T);
      Bs    : constant Time_T := (if C.SB_Avail then Times.Bs else 0);
      Terms : constant Terms_T :=
        (V => V, V_Delta0 => (if C.Inhibit then 0 else F41 (V)),
         A_Est1 => 0, A_Est2 => 0, T_Be => Times.Be, T_Bs1 => Bs,
         T_Bs2 => Bs, T_Ind => T_Indication (C, Times.Bs), TCO => C.TCO,
         T_Traction_Cut_Off => C.T_TCO);
      Far   : constant Dist_T := -Max_Cm + 1;
      No_GUI : constant Curve_T :=
        (Kind => GUI, Anchor => T.Location, Anchor_W => 0, Floor_W => 0,
         TSR => T.TSR);
   begin
      if Use_SBD then
         return EOA_Limits
           (Work.Model, Work.Profile,
            (Kind => SBD, Anchor => T.EOA, Anchor_W => 0, Floor_W => 0,
             TSR => T.TSR),
            False, No_GUI, Terms, C.X_Est, Far).I;
      else
         return EBD_Limits
           (Work.Model, Work.Profile, EBD_Of (T), T.Speed, T.Location,
            False, No_GUI, Terms, C.X_Max, Far).I;
      end if;
   end Indication_For;

   --  3.13.11.5, .6, .7.1: the perturbation location of the SvL, the EOA
   --  (Use_SBD) or the LOA
   procedure Perturbation_Of (Work    : Work_T;
                              C       : Ctx_T;
                              T       : Target_T;
                              Use_SBD : Boolean;
                              Found   : out Boolean;
                              X       : out Num)
   is
      LOA        : constant Boolean := T.Kind = LOA_Target;
      Prev_Valid : Boolean := False;
      Prev_I     : Num := 0;
      Prev_B     : Num := 0;
   begin
      Found := False;
      X := 0;
      for N in 1 .. Work.Elements loop
         declare
            V_N  : constant Speed_T := Work.MRSP (N).Speed;
         begin
            if LOA and then V_N < T.Speed then
               --  3.13.11.7.1 a), b)
               Prev_Valid := False;
            else
               declare
                  I_N : constant Num :=
                    Indication_For (Work, C, T, V_N, Use_SBD);
                  A_N : constant Num := Work.MRSP (N).Start;
                  B_N : constant Num :=
                    (if N < Work.Elements then Work.MRSP (N + 1).Start
                     else Max_Cm + Max_Forward);
               begin
                  --  3.13.11.6 with the element before
                  if Prev_Valid and then Prev_I > Prev_B and then I_N < Prev_B
                  then
                     Found := True;
                     X := Prev_B;
                     exit;
                  end if;
                  --  3.13.11.5
                  if A_N < I_N and then I_N <= B_N then
                     Found := True;
                     X := I_N;
                     exit;
                  end if;
                  Prev_Valid := True;
                  Prev_I := I_N;
                  Prev_B := B_N;
               end;
            end if;
         end;
      end loop;
      if LOA then
         --  3.13.11.7.1.1, .2
         if not Found or else X > T.Location then
            X := T.Location;
         end if;
         Found := True;
      end if;
   end Perturbation_Of;

   ---------------------------------------------------------------------
   --  Step
   ---------------------------------------------------------------------

   Max_Concerned : constant := 16;

   procedure Step (S       : Snapshot_T;
                   Inputs  : Inputs_T;
                   Work    : in out Work_T;
                   State   : in out State_T;
                   Result  : out Result_T)
   is
      NV     : National_Values_T renames S.National;
      Config : Onboard_Config_T renames S.Extra.Config;
      C      : Ctx_T;
      --  the emergency brake command on entry, for the proof of the
      --  revocation (the postcondition)
      EB_In  : constant Boolean := State.EB with Ghost;

      procedure Deactivate is
      begin
         State.Active := False;
         State.Monitoring := CSM;
         State.Status := NoS;
         State.TCO := False;
         State.SB := False;
         State.EB := False;
         State.EB_For_SB := False;
         State.MRDT_Valid := False;
         State.Lock_P := False;
         State.Lock_SBI := False;
         State.Lock_D := False;
         State.Feedback.Active := False;
         State.Feedback.Locked := False;
         State.Feedback.Ratio_Prev := 1_000;
         State.Signature := 0;
         State.Active_Display := False;
         State.Target_Count := 0;
      end Deactivate;

      --  the EOA target (0: none), and the target that is the MRDT
      EOA_Index  : Natural range 0 .. Max_Targets := 0;
      --  the SvL of the EOA target is a temporary one: no release speed
      --  (3.12.4.7, 3.12.5.8)
      Temporary_SvL : Boolean := False;
      --  phase E4, 5.16: the EOA of the EOA target is the start of the
      --  level crossing of S.LX
      LX_Here       : Boolean := False;

      --  release speed monitoring (3.13.9.4.6)
      Start      : RSM_Start_T;
      Cond_2     : Boolean := False;

      --  what the targets give (3.13.10.4.10 to .15, 3.13.10.6.1)
      Trig_Ind, Trig_Ovs, Trig_Was, Trig_SB, Trig_EB : Boolean := False;
      Rev_All    : Boolean;
      Passed_I   : Boolean := False;
      Passed_I_B : Boolean := False;
      V_P_Min    : Num;
      V_SBI_Min  : Num;
      RSM_V_P    : Num := Max_Speed;
      RSM_V_SBI  : Num := Max_Speed;
      Ind_Found  : Boolean := False;
      Ind_D      : Num := 0;
      Ind_Target : Natural range 0 .. Max_Targets := 0;
      MRDT_Here  : Boolean := False;
      Signature  : Num := 0;
      --  A.3.13: a build up time of some target is reduced
      Pawl       : Boolean := False;
      MRDT_Changed : Boolean := False;

      type Concerned_T is record
         Index : Positive range 1 .. Max_Targets := 1;
         V_P0  : Speed_T := 0;
      end record;
      type Concerned_Array is array (1 .. Max_Concerned) of Concerned_T;
      Concerned  : Concerned_Array := (others => (1, 0));
      N_Concerned : Natural range 0 .. Max_Concerned := 0;

      Mon        : Monitoring_T;
      Status     : Status_T;
      Brake      : Boolean;
      Rel        : Speed_T;

   begin
      Result := (others => <>);
      Work.Count := 0;
      Work.Elements := 0;

      ------------------------------------------------------------------
      --  The train
      ------------------------------------------------------------------

      if S.Train.Position_Valid then
         C.X_Est := EVC_Profile.Ahead_Of (S, S.Train.Est_Front);
         C.X_Max := Max (EVC_Profile.Ahead_Of (S, S.Train.Max_Safe_Front),
                         C.X_Est);
         C.X_Min := Min (EVC_Profile.Ahead_Of (S, S.Train.Min_Safe_Front),
                         C.X_Est);
      end if;
      C.Stop := Max (C.X_Est, -Max_Cm + 1);
      C.V := Speed_T (S.Train.Speed);
      C.V_Ura := Max (Speed_T (S.Train.Speed_Max) - C.V, 0);
      C.Standstill := S.Train.Standstill;
      Result.V_Est := C.V;

      --  the measured acceleration (filtered, 1 s)
      if not State.Active then
         State.A_Est := 0;
      elsif Inputs.Dt_Ms > 0 then
         declare
            Dt  : constant Num := Min (Num (Inputs.Dt_Ms), 1_000);
            Raw : constant Num :=
              Max (Min (Div_Floor ((C.V - State.V_Prev) * 10_000,
                                   Min (Num (Inputs.Dt_Ms), 2**40)),
                        Max_Accel), -Max_Accel);
         begin
            State.A_Est :=
              Max (Min (State.A_Est
                        + Div_Floor ((Raw - State.A_Est) * Dt, 1_000),
                        Max_Accel), -Max_Accel);
         end;
      end if;
      State.V_Prev := C.V;
      --  3.13.9.3.2.8, .9
      C.A1 := Max (State.A_Est, 0);
      C.A2 := Min (Max (State.A_Est, 0), 400);

      ------------------------------------------------------------------
      --  The braking model and the track (3.13.2 to 3.13.6)
      ------------------------------------------------------------------

      EVC_Braking.Build (S, Inputs.Special_Active, Inputs.Additional,
                         Work.Model);
      EVC_Profile.Build
        (S, Work.Model,
         Clamp (C.X_Min - Min (Num (S.Train_Data.Length), Max_Cm)),
         Work.Profile);

      ------------------------------------------------------------------
      --  The MRSP and V_MRSP (3.13.7.2)
      ------------------------------------------------------------------

      for K in 1 .. S.MRSP.Count loop
         pragma Loop_Invariant (Work.Elements < K);
         declare
            X  : constant Dist_T :=
              EVC_Profile.Ahead_Of (S, S.MRSP.Segments (K).Start);
            Vk : constant Speed_T :=
              Min (Num (S.MRSP.Segments (K).Speed), Num (S.Mode_Speed));
         begin
            if Work.Elements = 0
              or else X > Work.MRSP (Work.Elements).Start
            then
               Work.Elements := Work.Elements + 1;
               --  due to a TSR unless the mode related speed is lower
               Work.MRSP (Work.Elements) :=
                 (Start => X, Speed => Vk,
                  TSR   => S.MRSP.TSR (K)
                           and then Vk = Num (S.MRSP.Segments (K).Speed));
            end if;
         end;
      end loop;

      declare
         Ceiling : Speed_T := Speed_T (S.Mode_Speed);
      begin
         for K in 1 .. Work.Elements loop
            --  the elements between the min and the max safe front end;
            --  the first one also before its start (see the header)
            if not S.Train.Position_Valid
              or else ((K = 1 or else Work.MRSP (K).Start <= C.X_Max)
                       and then (K = Work.Elements
                                 or else Work.MRSP (K + 1).Start > C.X_Min))
            then
               Ceiling := Min (Ceiling, Work.MRSP (K).Speed);
            end if;
         end loop;
         C.V_MRSP := Ceiling;
      end;

      if not ((S.Supervise and then Work.Elements > 0)
              or else S.Mode_Speed < No_Speed_Limit)
      then
         --  no ceiling speed: nothing is supervised
         Deactivate;
         State.V_MRSP := 0;
         Result.V_Est := C.V;
         return;
      end if;

      C.M_EBI := Min (C.V_MRSP + Margin (EBI, C.V_MRSP), Max_Speed);
      C.M_SBI := Min (C.V_MRSP + Margin (SBI, C.V_MRSP), C.M_EBI);
      C.M_W := Min (C.V_MRSP + Margin (Warning, C.V_MRSP), C.M_SBI);
      Result.Active := True;
      Result.V_MRSP := C.V_MRSP;

      ------------------------------------------------------------------
      --  The supervised targets (3.13.8.2)
      ------------------------------------------------------------------

      if S.Supervise and then S.Train.Position_Valid then
         --  a) the MRSP elements lower than V_MRSP in advance of the max
         --  safe front end (3.13.8.2.3: the passed ones are gone)
         for K in 1 .. Work.Elements loop
            pragma Loop_Invariant (Work.Count < K);
            if Work.MRSP (K).Start > C.X_Max
              and then Work.MRSP (K).Speed < C.V_MRSP
            then
               Work.Count := Work.Count + 1;
               Work.Targets (Work.Count) :=
                 (Kind     => MRSP_Target,
                  Location => Work.MRSP (K).Start,
                  EOA      => 0,
                  Speed    => Work.MRSP (K).Speed,
                  TSR      => Work.MRSP (K).TSR);
            end if;
         end loop;
         pragma Assert (Work.Count <= Max_Speed_Segments);
         --  b) the LOA, c) the EOA and the SvL. 3.13.1.5: the EOA and the
         --  SvL are the closest of those of the MA and of the temporary
         --  EOA and SvL (3.12.2.5: the start of a mode profile, 3.12.4.7,
         --  or of a level crossing not protected, 3.12.5.8), which have no
         --  release speed: a temporary SvL supervised takes the release
         --  speed away; without a temporary SvL the SvL of the MA holds
         --  (3.12.4.7.1). An LOA stays a target beside a temporary EOA.
         declare
            Tmp   : Temporary_Target_T renames S.Temporary;
            T_EOA : constant Dist_T := EVC_Profile.Ahead_Of (S, Tmp.EOA);
            T_SvL : constant Dist_T :=
              (if Tmp.Has_SvL
               then Max (EVC_Profile.Ahead_Of (S, Tmp.SvL), T_EOA)
               else T_EOA);
            EOA   : Dist_T := T_EOA;
            SvL   : Dist_T := T_SvL;
            Has_EOA : Boolean := Tmp.Present;
         begin
            if S.MA.Present then
               if S.MA.LOA_Speed > 0 then
                  declare
                     LOA : constant Dist_T :=
                       EVC_Profile.Ahead_Of (S, S.MA.EOA);
                  begin
                     Work.Count := Work.Count + 1;
                     Work.Targets (Work.Count) :=
                       (Kind     => LOA_Target,
                        Location => LOA,
                        EOA      => LOA,
                        Speed    => Speed_T (S.MA.LOA_Speed),
                        TSR      => False);
                  end;
                  Temporary_SvL := Tmp.Present;
               else
                  EOA := EVC_Profile.Ahead_Of (S, S.MA.EOA);
                  SvL := Max (EVC_Profile.Ahead_Of (S, S.MA.SvL), EOA);
                  if Tmp.Present then
                     EOA := Min (EOA, T_EOA);
                     if Tmp.Has_SvL and then T_SvL < SvL then
                        SvL := T_SvL;
                        Temporary_SvL := True;
                     end if;
                     SvL := Max (SvL, EOA);
                  end if;
                  Has_EOA := True;
               end if;
            else
               Temporary_SvL := Tmp.Present;
            end if;
            if Has_EOA then
               Work.Count := Work.Count + 1;
               Work.Targets (Work.Count) :=
                 (Kind => EOA_Target, Location => SvL, EOA => EOA,
                  Speed => 0, TSR => False);
               EOA_Index := Work.Count;
               C.SvL := SvL;
               LX_Here := S.LX.Present and then Tmp.Present
                          and then EOA = T_EOA;
            end if;
         end;
         --  d) the end of the SR distance
         if S.Extra.SR_Distance then
            Work.Count := Work.Count + 1;
            Work.Targets (Work.Count) :=
              (Kind     => SR_Target,
               Location => EVC_Profile.Ahead_Of (S, S.Extra.SR_End),
               EOA      => 0,
               Speed    => 0,
               TSR      => False);
         end if;
      end if;

      for K in 1 .. Work.Count loop
         pragma Loop_Invariant (Signature in 0 .. 1_000_000_000_038);
         Signature := (Signature * 31 + Digest (Work.Targets (K)))
                      mod 1_000_000_000_039;
      end loop;

      ------------------------------------------------------------------
      --  The context
      ------------------------------------------------------------------

      C.SB_Avail := Config.Service_Brake_Command and then NV.Q_NVSBTSMPERM;
      C.GUI := NV.Q_NVGUIPERM and then Work.Model.Has_Normal;
      C.Inhibit := NV.Q_NVINHSMICPERM;
      C.Kt_Zero := Work.Model.Conversion and then NV.Kt_Int = 0;
      C.TCO := Config.Traction_Cut_Off;
      C.T_TCO := Time_T (S.Train_Data.T_Traction_Cut_Off);

      declare
         Ratio : Factor_T;
         Lock  : Boolean;
      begin
         Update_Feedback (State.Feedback, S, Inputs,
                          State.Active and then State.Monitoring /= CSM,
                          Ratio, Lock);
         C.Feedback := Config.Service_Brake_Feedback
                       and then NV.Q_NVSBFBPERM
                       and then Inputs.Pressure_Known
                       and then State.Feedback.P0_Known;
         C.Fb_Active := State.Feedback.Active;
         C.Fb_Locked := State.Feedback.Locked;
         C.Fb_Ratio := Ratio;
         if Lock then
            State.Lock_P := True;
            State.Lock_SBI := True;
            State.Lock_D := True;
         end if;
      end;

      ------------------------------------------------------------------
      --  The release speed (3.13.9.4)
      ------------------------------------------------------------------

      if EOA_Index > 0 then
         declare
            T : constant Target_T := Work.Targets (EOA_Index);
         begin
            --  3.13.9.4.8.2: d_tripEOA (alpha: level 1)
            C.Trip :=
              Num (T.EOA)
              + (if Inputs.Level_1 then Num (Inputs.Antenna_Offset) else 0)
              + Min (Max (Num (S.Extra.Trip_Margin), C.X_Max - C.X_Min),
                     Max_Cm);
            case (if Temporary_SvL then None
                  else S.MA.Release_Speed.Kind) is
               when None =>
                  null;
               when Fixed =>
                  --  3.13.9.4.3 a), c) (the national value is given as
                  --  the value)
                  C.Release := Speed_T (S.MA.Release_Speed.Speed);
               when Calculated_On_Board =>
                  C.Calculated := True;
                  C.Release := Calculated_Release (Work, C, Inputs.Level_1);
            end case;
            if C.Release > 0 then
               Start := RSM_Start (Work, C, T, C.Release);
               --  3.13.9.4.9: not above an MRSP element between the
               --  presumed start of the release speed monitoring, less
               --  the confidence interval, and the trip location
               declare
                  From  : constant Num := Start.Start - (C.X_Max - C.X_Min);
                  Limit : Speed_T := C.Release;
               begin
                  for K in 1 .. Work.Elements loop
                     if Work.MRSP (K).Start <= C.Trip
                       and then (K = Work.Elements
                                 or else Work.MRSP (K + 1).Start > From)
                     then
                        Limit := Min (Limit, Work.MRSP (K).Speed);
                     end if;
                  end loop;
                  if Limit < C.Release then
                     C.Release := Limit;
                     if C.Release > 0 then
                        Start := RSM_Start (Work, C, T, C.Release);
                     end if;
                  end if;
               end;
            end if;
            C.Has_Release := C.Release > 0;
         end;
      end if;
      --  3.13.10.4.13
      C.V_Rel_Table :=
        (if C.Has_Release and then C.Release < C.V_MRSP then C.Release
         else 0);
      Rel := (if C.Has_Release then C.Release else 0);
      --  Table 16 [2]: the start of the release speed monitoring passed
      Cond_2 := C.Has_Release
                and then ((Start.From_SBD and then C.X_Est > Start.Start)
                          or else (not Start.From_SBD
                                   and then C.X_Max > Start.Start));

      ------------------------------------------------------------------
      --  Every target (3.13.10.4.10 to .15, 3.13.10.3.8, 3.13.10.4.3,
      --  .4)
      ------------------------------------------------------------------

      Rev_All := C.V <= C.V_MRSP;
      V_P_Min := C.V_MRSP;
      V_SBI_Min := C.M_SBI;
      for K in 1 .. Work.Count loop
         pragma Loop_Invariant (V_P_Min in 0 .. Max_Speed
                                and then V_SBI_Min in 0 .. Max_Speed
                                and then RSM_V_P in 0 .. Max_Speed
                                and then RSM_V_SBI in 0 .. Max_Speed
                                and then Ind_Target < K
                                and then (if Rev_All
                                          then C.V <= C.V_MRSP)
                                and then (if Ind_Found
                                          then Ind_D in -16 * Max_Cm
                                                        .. 16 * Max_Cm));
         declare
            T : constant Target_T := Work.Targets (K);
            R : constant Eval_T := Evaluate (Work, C, T, C.V, False);
            F : constant Flags_T := Flags_Of (C, T, R, Between (C, T));
            --  the distances to the Indication locations of the target
            --  (3.13.10.3.8)
            D1, D2 : Num := 0;
            N_D    : Natural range 0 .. 2 := 0;
         begin
            Trig_Ind := Trig_Ind or else F.Ind;
            Trig_Ovs := Trig_Ovs or else F.Ovs;
            Trig_Was := Trig_Was or else F.Was;
            Trig_SB := Trig_SB or else F.SB;
            Trig_EB := Trig_EB or else F.EB;
            Rev_All := Rev_All and then F.Rev;
            Passed_I := Passed_I or else F.Passed_I;
            Passed_I_B := Passed_I_B or else F.Passed_I_B;
            Pawl := Pawl or else R.Reduced;
            MRDT_Here := MRDT_Here
                         or else (State.MRDT_Valid
                                  and then Same (T, State.MRDT));

            --  3.13.10.4.3, .4: the displayed P and SBI speeds
            case T.Kind is
               when MRSP_Target | LOA_Target | SR_Target =>
                  V_P_Min := Min (V_P_Min, R.L.V_P);
                  V_SBI_Min := Min (V_SBI_Min, R.L.V_SBI);
               when EOA_Target =>
                  V_P_Min := Min (V_P_Min, Min (R.E.V_P, R.L.V_P));
                  V_SBI_Min :=
                    Min (V_SBI_Min, Min (Max (R.E.V_SBI, Rel),
                                         Max (R.L.V_SBI, Rel)));
                  --  3.13.10.5.3
                  RSM_V_P := Min (R.E.V_P, R.L.V_P);
                  RSM_V_SBI := Min (Max (R.E.V_SBI, Rel),
                                    Max (R.L.V_SBI, Rel));
            end case;

            --  3.13.10.3.8: the first Indication location
            if T.Kind in MRSP_Target | LOA_Target then
               if T.Speed < C.V_MRSP and then T.Speed < C.V
                 and then (C.V >= Rel or else not Between (C, T))
               then
                  D1 := R.L.I - C.X_Max;
                  N_D := 1;
               end if;
            elsif T.Kind = SR_Target then
               D1 := R.L.I - C.X_Max;
               N_D := 1;
            elsif C.V >= Rel then
               D1 := R.E.I - C.X_Est;
               D2 := R.L.I - C.X_Max;
               N_D := 2;
            else
               D1 := Start.SBI1 - C.X_Est;
               D2 := Start.SBI2 - C.X_Max;
               N_D := 2;
            end if;
            for J in 1 .. N_D loop
               pragma Loop_Invariant
                 (Ind_Target <= K
                  and then (if Ind_Found
                            then Ind_D in -16 * Max_Cm .. 16 * Max_Cm));
               declare
                  D : constant Num := (if J = 1 then D1 else D2);
               begin
                  if not Ind_Found or else D < Ind_D then
                     Ind_Found := True;
                     Ind_D := D;
                     Ind_Target := K;
                  end if;
               end;
            end loop;

            --  3.13.10.4.2: the concerned targets
            if F.Concerned and then (T.Kind not in MRSP_Target | LOA_Target
                                     or else T.Speed < C.V_MRSP)
            then
               if N_Concerned < Max_Concerned then
                  N_Concerned := N_Concerned + 1;
                  Concerned (N_Concerned) := (Index => K, V_P0 => F.V_P0);
               else
                  --  full: the one with the highest P gives way
                  declare
                     Worst : Positive range 1 .. Max_Concerned := 1;
                  begin
                     for J in 2 .. Max_Concerned loop
                        if Concerned (J).V_P0 > Concerned (Worst).V_P0 then
                           Worst := J;
                        end if;
                     end loop;
                     if F.V_P0 < Concerned (Worst).V_P0 then
                        Concerned (Worst) := (Index => K, V_P0 => F.V_P0);
                     end if;
                  end;
               end if;
            end if;
         end;
      end loop;
      Result.Indication := Ind_Found;
      Result.Indication_D := (if Ind_Found then Max (Ind_D, 0) else 0);

      --  phase E4, 5.16.3.2: stopping in rear of the level crossing not
      --  required, the location of the Permitted speed supervision limit
      --  for V_LX (3.13.9.3.5.11, .12: the formulas of V_est with V_LX)
      --  of its start as EOA (SBI1, the estimated front end) and as SvL
      --  (SBI2, the max safe front end), the most restrictive of the two
      if LX_Here and then EOA_Index > 0 and then not S.LX.Stop then
         declare
            V_LX : constant Speed_T := Speed_T (S.LX.Speed);
            R    : constant Eval_T :=
              Evaluate (Work, C, Work.Targets (EOA_Index), V_LX, False);
            By_E : constant Boolean := R.E.SBI - C.X_Est <= R.L.SBI - C.X_Max;
            P    : constant Num := (if By_E then R.E.P else R.L.P);
         begin
            Result.LX_Release :=
              C.V <= V_LX
              and then (if By_E then C.X_Est >= R.E.P else C.X_Max >= R.L.P);
            Result.LX_From := Along (S.Train.Ahead, Clamp (P));
         end;
      end if;

      ------------------------------------------------------------------
      --  The type of monitoring (3.13.10.6, Table 16)
      ------------------------------------------------------------------

      declare
         --  [1]
         Cond_1 : constant Boolean :=
           (not C.Standstill and then Passed_I
            and then (not C.Has_Release or else C.V >= C.Release))
           or else (C.Has_Release and then C.V < C.Release
                    and then Passed_I_B);
         Updated : constant Boolean :=
           Signature /= State.Signature
           or else Work.Count /= State.Target_Count;
         Old_Mon : constant Monitoring_T := State.Monitoring;
      begin
         if not State.Active then
            --  3.13.10.3.5, 3.13.10.4.16, 3.13.10.5.6: the first type
            --  entered, from the Normal status
            Mon := (if Cond_2 then RSM elsif Cond_1 then TSM else CSM);
            State.Status := NoS;
         else
            Mon := Old_Mon;
            case Old_Mon is
               when CSM =>
                  if Cond_2 then
                     Mon := RSM;                                   -- [2]
                  elsif Cond_1 then
                     Mon := TSM;                                   -- [1]
                  end if;
               when TSM =>
                  if Cond_2 then
                     Mon := RSM;                                   -- [2]
                  elsif not MRDT_Here and then not Cond_1 then
                     Mon := CSM;                                   -- [3]
                  elsif C.V_MRSP /= State.V_MRSP
                    and then State.MRDT.Speed >= C.V_MRSP
                    and then not Cond_1
                  then
                     Mon := CSM;                                   -- [6]
                  end if;
               when RSM =>
                  if not C.Has_Release then
                     --  the release speed is gone with the MA
                     Mon := (if Cond_1 then TSM else CSM);
                  elsif not MRDT_Here and then not Cond_1
                    and then not Cond_2
                  then
                     Mon := CSM;                                   -- [3]
                  elsif Updated and then Cond_1 and then not Cond_2 then
                     Mon := TSM;                                   -- [4]
                  end if;
            end case;
            --  3.13.10.6.3, .4
            if Old_Mon = TSM and then Mon /= TSM then
               State.TCO := False;
               if Mon = RSM then
                  State.SB := False;
                  State.EB_For_SB := False;
               end if;
            end if;
            if Mon = CSM and then Old_Mon /= CSM then
               State.MRDT_Valid := False;
            end if;
         end if;
         if Mon /= Old_Mon or else not State.Active then
            --  A.3.10.4: the initial values
            State.Feedback.Active := False;
            State.Feedback.Locked := False;
            State.Feedback.Ratio_Prev := 1_000;
            State.Lock_P := False;
            State.Lock_SBI := False;
            State.Lock_D := False;
         end if;
         State.Signature := Signature;
         State.Target_Count := Work.Count;
      end;
      State.Active := True;
      State.Monitoring := Mon;

      ------------------------------------------------------------------
      --  The commands (Tables 5, 6, 8 to 11, 13, 14; 3.13.10.2.3, .4)
      ------------------------------------------------------------------

      case Mon is
         when CSM =>
            --  Table 6: r1, r0
            if C.V <= C.V_MRSP then
               State.SB := False;
               State.EB_For_SB := False;
               if NV.Q_NVEMRRLS then
                  State.EB := False;
               end if;
            end if;
            if C.Standstill then
               State.EB := False;
            end if;
            --  Table 5: t4, t5
            if C.V > C.M_SBI then
               if Config.Service_Brake_Command then
                  State.SB := True;
               else
                  State.EB_For_SB := True;
               end if;
            end if;
            if C.V > C.M_EBI then
               State.EB := True;
               Result.EB_Triggered := True;
            end if;
            State.TCO := False;

         when TSM =>
            --  Tables 10, 11: r1, r3 for every target; r0
            if Rev_All then
               State.TCO := False;
               State.SB := False;
               State.EB_For_SB := False;
               if NV.Q_NVEMRRLS then
                  State.EB := False;
               end if;
            end if;
            if C.Standstill then
               State.EB := False;
            end if;
            --  Tables 8, 9: for at least one target (3.13.10.4.14)
            if Trig_Was and then Config.Traction_Cut_Off then
               State.TCO := True;
            end if;
            if Trig_SB then
               if C.SB_Avail then
                  State.SB := True;
               else
                  State.EB_For_SB := True;
               end if;
            end if;
            if Trig_EB then
               State.EB := True;
               Result.EB_Triggered := True;
            end if;

         when RSM =>
            --  Table 14: r0
            if C.Standstill then
               State.EB := False;
            end if;
            if C.V <= C.Release then
               State.SB := False;
               State.EB_For_SB := False;
            end if;
            --  Table 13: t2
            if C.V > C.Release then
               State.EB := True;
               Result.EB_Triggered := True;
            end if;
            State.TCO := False;
      end case;
      pragma Assert (if EB_In and then not State.EB
                     then C.Standstill
                          or else (Mon /= RSM and then C.V <= C.V_MRSP));
      Brake := State.SB or else State.EB or else State.EB_For_SB;

      ------------------------------------------------------------------
      --  The supervision status (Tables 7, 12, 15)
      ------------------------------------------------------------------

      Status := State.Status;
      case Mon is
         when CSM =>
            case Status is
               when NoS | IndS =>
                  Status := (if C.V > C.M_SBI then IntS
                             elsif C.V > C.M_W then WaS
                             elsif C.V > C.V_MRSP then OvS
                             else NoS);
               when OvS =>
                  if C.V > C.M_SBI then
                     Status := IntS;
                  elsif C.V > C.M_W then
                     Status := WaS;
                  elsif C.V <= C.V_MRSP then
                     Status := NoS;
                  end if;
               when WaS =>
                  if C.V > C.M_SBI then
                     Status := IntS;
                  elsif C.V <= C.V_MRSP then
                     Status := NoS;
                  end if;
               when IntS =>
                  if (C.V <= C.V_MRSP or else C.Standstill)
                    and then not Brake
                  then
                     Status := NoS;
                  end if;
            end case;

         when TSM =>
            case Status is
               when NoS | IndS =>
                  --  3.13.10.4.17: the Normal status is not used
                  Status := (if Trig_SB or else Trig_EB then IntS
                             elsif Trig_Was then WaS
                             elsif Trig_Ovs then OvS
                             else IndS);
               when OvS =>
                  if Trig_SB or else Trig_EB then
                     Status := IntS;
                  elsif Trig_Was then
                     Status := WaS;
                  elsif Rev_All then
                     Status := IndS;
                  end if;
               when WaS =>
                  if Trig_SB or else Trig_EB then
                     Status := IntS;
                  elsif Rev_All then
                     Status := IndS;
                  end if;
               when IntS =>
                  if (Rev_All or else C.Standstill) and then not Brake then
                     Status := IndS;
                  end if;
            end case;

         when RSM =>
            case Status is
               when NoS | IndS | OvS | WaS =>
                  Status := (if C.V > C.Release then IntS else IndS);
               when IntS =>
                  if C.Standstill and then not Brake then
                     Status := IndS;
                  end if;
            end case;
      end case;
      --  no Intervention status without a brake command (see the header)
      if Status = IntS and then not Brake then
         Status := (if Mon = CSM then NoS else IndS);
      end if;
      pragma Assert (if Status = IntS then Brake);
      pragma Assert
        (Brake = (State.SB or else State.EB or else State.EB_For_SB));
      State.Status := Status;
      State.V_MRSP := C.V_MRSP;

      ------------------------------------------------------------------
      --  The most relevant displayed target (3.13.10.4.2, .5; RSM: the
      --  EOA; 3.13.10.3.9)
      ------------------------------------------------------------------

      declare
         Candidate : Natural range 0 .. Max_Targets := 0;
      begin
         if Mon = TSM and then N_Concerned > 0 then
            declare
               Chosen  : array (1 .. Max_Concerned) of Boolean :=
                 (others => False);
               Current : Positive range 1 .. Max_Concerned := 1;
            begin
               --  step 0: the lowest P
               for J in 2 .. N_Concerned loop
                  if Concerned (J).V_P0 < Concerned (Current).V_P0 then
                     Current := J;
                  end if;
               end loop;
               Chosen (Current) := True;
               --  steps 1 .. n: a masked target of a lower speed
               for Round in 1 .. Max_Concerned loop
                  declare
                     Tk   : constant Target_T :=
                       Work.Targets (Concerned (Current).Index);
                     Next : Natural range 0 .. Max_Concerned := 0;
                     Best : Num := 0;
                  begin
                     exit when Tk.Speed = 0;   -- 3.13.10.4.2.3
                     declare
                        Pk : constant Num :=
                          Evaluate (Work, C, Tk, Tk.Speed, False).L.P;
                     begin
                        for J in 1 .. N_Concerned loop
                           declare
                              Tj : constant Target_T :=
                                Work.Targets (Concerned (J).Index);
                           begin
                              if not Chosen (J) and then Tj.Speed < Tk.Speed
                              then
                                 declare
                                    Rj : constant Eval_T :=
                                      Evaluate (Work, C, Tj, Tk.Speed, False);
                                    Ij : constant Num :=
                                      (if Tj.Kind = EOA_Target
                                       then Min (Rj.E.I, Rj.L.I)
                                       else Rj.L.I);
                                 begin
                                    if Ij < Pk
                                      and then (Next = 0 or else Ij < Best)
                                    then
                                       Next := J;
                                       Best := Ij;
                                    end if;
                                 end;
                              end if;
                           end;
                        end loop;
                     end;
                     exit when Next = 0;
                     Current := Next;
                     Chosen (Current) := True;
                  end;
               end loop;
               Candidate := Concerned (Current).Index;
            end;
         elsif Mon = RSM then
            Candidate := EOA_Index;
         end if;

         if Mon /= CSM then
            if State.MRDT_Valid and then MRDT_Here then
               --  3.13.10.4.5: kept, unless a target of no higher speed
               --  is selected
               if Candidate > 0
                 and then not Same (Work.Targets (Candidate), State.MRDT)
                 and then Work.Targets (Candidate).Speed <= State.MRDT.Speed
               then
                  State.MRDT := Work.Targets (Candidate);
                  State.MRDT_Id := (State.MRDT_Id + 1) mod 256;
                  MRDT_Changed := True;
               end if;
            elsif Candidate > 0 then
               State.MRDT := Work.Targets (Candidate);
               State.MRDT_Valid := True;
               State.MRDT_Id := (State.MRDT_Id + 1) mod 256;
               MRDT_Changed := True;
            else
               State.MRDT_Valid := False;
            end if;
         end if;
      end;

      ------------------------------------------------------------------
      --  What the driver is shown (3.13.10.3 to 3.13.10.5)
      ------------------------------------------------------------------

      declare
         V_Perm  : Num;
         V_SBI   : Num;
         D       : Num := 0;
         Show_T  : Boolean := False;
         T_Shown : Target_T;
         Reduced : constant Boolean :=
           S.Adhesion.Driver_Slippery
           or else Work.Profile.Points
                     (Segment_Of (Work.Profile, C.X_Est)).Reduced;
      begin
         case Mon is
            when CSM =>
               --  3.13.10.3.1, .2
               V_Perm := C.V_MRSP;
               V_SBI := C.M_SBI;
               --  3.13.10.3.9, .10: under reduced adhesion, when
               --  A_MAXREDADH asks for it
               if Reduced and then Ind_Found and then Ind_Target > 0 then
                  if Work.Model.Redadh_Use = Target_Information then
                     Show_T := True;
                     T_Shown := Work.Targets (Ind_Target);
                     Result.CSM_Target := True;
                  elsif Work.Model.Redadh_Use = Time_To_Indication
                    and then C.V > 0
                  then
                     declare
                        TTI : constant Num :=
                          Div_Floor (Max (Ind_D, 0) * 10, C.V);
                     begin
                        if TTI < T_Disp_TTI / 100 then
                           Result.TTI := Natural (TTI);
                        end if;
                     end;
                  end if;
               end if;
            when TSM =>
               --  3.13.10.4.3, .4
               V_Perm := V_P_Min;
               V_SBI := V_SBI_Min;
               if State.MRDT_Valid then
                  Show_T := True;
                  T_Shown := State.MRDT;
               end if;
            when RSM =>
               --  3.13.10.5.1 to .3
               V_Perm := RSM_V_P;
               V_SBI := Max (RSM_V_SBI, C.Release);
               if EOA_Index > 0 then
                  Show_T := True;
                  T_Shown := Work.Targets (EOA_Index);
               end if;
         end case;

         if Show_T then
            --  3.13.10.4.6 to .8, 3.13.10.5.2
            case T_Shown.Kind is
               when EOA_Target =>
                  D := Max (Min (T_Shown.EOA - C.X_Est,
                                 T_Shown.Location - C.X_Max), 0);
                  Result.Release_Shown := C.Has_Release;
               when SR_Target =>
                  D := Max (T_Shown.Location - C.X_Max, 0);
               when MRSP_Target | LOA_Target =>
                  D := Max (Evaluate (Work, C, T_Shown, C.V, False).P_Target
                            - C.X_Max, 0);
            end case;
            Result.V_Target := T_Shown.Speed;
         end if;

         --  3.13.10.4.8.1, A.3.13: while a build up time is reduced the
         --  displayed P and SBI do not increase (the pawl; released with a
         --  new MRDT)
         if Mon /= CSM and then Pawl and then not MRDT_Changed
           and then State.Active_Display
         then
            V_Perm := Min (V_Perm, State.Shown_P);
            V_SBI := Min (V_SBI, State.Shown_SBI);
         end if;

         --  3.13.10.4.8.1, A.3.10: locked values do not increase
         if State.Lock_P then
            if V_Perm < State.Shown_P then
               State.Lock_P := False;
            else
               V_Perm := State.Shown_P;
            end if;
         end if;
         if State.Lock_SBI then
            if V_SBI < State.Shown_SBI then
               State.Lock_SBI := False;
            else
               V_SBI := State.Shown_SBI;
            end if;
         end if;
         if State.Lock_D then
            if D < State.Shown_D then
               State.Lock_D := False;
            else
               D := State.Shown_D;
            end if;
         end if;

         Result.V_SBI := Min (Max (V_SBI, 0), Max_Speed);
         Result.V_Warning :=
           (if Mon = CSM then Min (C.M_W, Result.V_SBI) else Result.V_SBI);
         Result.V_Perm := Min (Max (V_Perm, 0), Result.V_Warning);
         Result.D_Target := Min (D, Max_Cm);
         State.Shown_P := Result.V_Perm;
         State.Shown_SBI := Result.V_SBI;
         State.Shown_D := Result.D_Target;
         State.Active_Display := Mon /= CSM;
      end;

      --  phase E4, 5.16.1.4 a): the EOA target of the level crossing is
      --  the most relevant displayed target
      Result.LX_MRDT :=
        LX_Here and then EOA_Index > 0 and then Mon /= CSM
        and then State.MRDT_Valid
        and then Same (State.MRDT, Work.Targets (EOA_Index));

      Result.Monitoring := Mon;
      Result.Status := Status;
      Result.Release_Exists := C.Has_Release;
      Result.V_Release := Rel;
      Result.MRDT_Id := State.MRDT_Id;
      Result.TCO := State.TCO;
      Result.SB := State.SB;
      Result.EB := State.EB or else State.EB_For_SB;
      pragma Assert (if Result.Status = IntS
                     then Result.SB or else Result.EB);
      pragma Assert (if EB_In and then not State.EB
                     then S.Train.Standstill
                          or else (Result.Monitoring /= RSM
                                   and then Result.V_Est <= Result.V_MRSP));

      ------------------------------------------------------------------
      --  The EOA, LOA and SvL passed (3.13.10.2.6 a, 3.13.10.2.7), the
      --  perturbation location (3.13.11)
      ------------------------------------------------------------------

      declare
         EOA_Passed : Boolean := False;
         SvL_Passed : Boolean := False;
         Pert       : Boolean := False;
         Pert_X     : Num := 0;
         MA_Req     : Boolean := False;
      begin
         for K in 1 .. Work.Count loop
            declare
               T : constant Target_T := Work.Targets (K);
            begin
               if T.Kind in EOA_Target | LOA_Target then
                  EOA_Passed :=
                    (if Inputs.Level_1
                     then C.X_Min - Num (Inputs.Antenna_Offset) > T.EOA
                     else C.X_Min > T.EOA);
               end if;
               if T.Kind = EOA_Target then
                  SvL_Passed := C.X_Max > T.Location;
               end if;
               if T.Kind in EOA_Target | LOA_Target
                 and then S.Extra.T_MAR > 0
               then
                  declare
                     Found_S, Found_E : Boolean;
                     X_S, X_E         : Num;
                     Lead             : constant Num :=
                       Travel_Ceil (C.M_W, Time_T (S.Extra.T_MAR));
                  begin
                     Perturbation_Of (Work, C, T, False, Found_S, X_S);
                     if T.Kind = EOA_Target then
                        Perturbation_Of (Work, C, T, True, Found_E, X_E);
                     else
                        Found_E := False;
                        X_E := 0;
                     end if;
                     Pert := Found_S or else Found_E;
                     Pert_X := (if Found_S then X_S else X_E);
                     --  3.13.11.8
                     MA_Req :=
                       (Found_S and then C.X_Max > X_S - Lead)
                       or else (Found_E and then C.X_Est > X_E - Lead);
                     --  3.13.11.9
                     if Work.Elements > 0
                       and then Speed_At (Work.Model, Work.Profile, EBD_Of (T),
                                          Work.MRSP (1).Start)
                                < Work.MRSP (1).Speed
                     then
                        MA_Req := True;
                     end if;
                  end;
               end if;
            end;
         end loop;
         Result.EOA_Passed := EOA_Passed;
         Result.SvL_Passed := SvL_Passed;
         Result.Perturbation := Pert;
         Result.Perturbation_X := Pert_X;
         Result.MA_Request := MA_Req;
      end;
   end Step;

end EVC_SDM;
