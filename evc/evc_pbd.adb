--  ETCS on-board (EVC)
--  The speed restriction to ensure a permitted braking distance,
--  implementation.

with EVC_Curves; use EVC_Curves;
with EVC_Limits; use EVC_Limits;

package body EVC_PBD
  with SPARK_Mode => On
is

   ----------------
   -- Get_Inputs --
   ----------------

   procedure Get_Inputs (S          : Snapshot_T;
                         Active     : Brakes_T;
                         Additional : Boolean;
                         Antenna    : Natural;
                         I          : out Inputs_T)
   is
   begin
      Build (S, Active, Additional, I.Model);
      I.Slippery := S.Adhesion.Driver_Slippery;
      I.Inhibit := S.National.Q_NVINHSMICPERM;
      I.SB_Avail := S.Extra.Config.Service_Brake_Command
                    and then S.National.Q_NVSBTSMPERM;
      I.T_Traction := Time_T (S.Train_Data.T_Traction_Cut_Off);
      I.Antenna := Min (Num (Antenna), Antenna_T'Last);
   end Get_Inputs;

   ---------------
   -- Inputs_Of --
   ---------------

   function Inputs_Of (S          : Snapshot_T;
                       Active     : Brakes_T;
                       Additional : Boolean;
                       Antenna    : Natural) return Inputs_T
   is
      I : Inputs_T;
   begin
      Get_Inputs (S, Active, Additional, Antenna, I);
      return I;
   end Inputs_Of;

   ---------------------
   -- Section_Profile --
   ---------------------

   procedure Section_Profile (I        : Inputs_T;
                              Gradient : Gradient_T;
                              P        : out Profile_T)
   is
      --  3.11.11.4 1st bullet, 3.13.4.3
      A : constant Num :=
        Gradient_Acceleration (Gradient, I.Model.M_Rotating_Up,
                               I.Model.M_Rotating_Down);
   begin
      P := (Count => 1, Points => (others => No_Point));
      --  one segment from the rear end of the axis, open ended
      P.Points (1) := (Start          => <>,
                       Gradient       => Gradient,
                       A_Gradient     => A,
                       Gradient_TSR   => Gradient,
                       A_Gradient_TSR => A,
                       Reduced        => I.Slippery,
                       Inhibited      => (others => False));
   end Section_Profile;

   -----------
   -- Holds --
   -----------

   function Holds (I        : Inputs_T;
                   P        : Profile_T;
                   C        : Condition_T;
                   D_PBD    : PBD_Distance_T;
                   V        : Speed_T) return Boolean
   is
      --  the curve that reaches zero speed at d_PBD
      Curve : constant Curve_T :=
        (Kind     => (if C = Service_SBD then SBD else EBD),
         Anchor   => D_PBD,
         Anchor_W => 0,
         Floor_W  => 0,
         TSR      => False);
      --  3.13.9.2.3, .5 at V_PBD, rounded up
      Kind  : constant Margin_Kind_T := (if C = Emergency then EBI else SBI);
      V1    : constant Speed_T := V + Margin (Kind, V) + 1;
      --  3.13.9.3.3.3, .5 as if the feedback were not implemented; T_bs,
      --  of the targets at zero speed, for T_bs1 as the safe side of
      --  T_bs_reduced
      T_Bs  : constant Time_T :=
        (if I.SB_Avail then I.Model.Service_Zero.Build_Up else 0);
      X     : Num;
   begin
      case C is
         when Emergency | Service_EBD =>
            declare
               Vd0   : constant Speed_T :=
                 (if I.Inhibit then 0 else F41 (V1));
               V_B   : constant Speed_T := V1 + Vd0;
               --  T_traction + T_berem = MAX (T_traction, T_be), T_be of
               --  3.13.6.2.2.3 for a target at zero speed
               T_Rec : constant Time_T :=
                 Max (I.T_Traction, I.Model.Emergency_Zero.Build_Up);
            begin
               --  d_offset + D_bec (+ (V + dV_sbi) T_bs2)
               X := I.Antenna + Travel_Ceil (V_B, T_41)
                    + Travel_Ceil (V_B, T_Rec)
                    + (if C = Service_EBD then Travel_Ceil (V1, T_Bs)
                       else 0);
               return X <= D_PBD
                 and then V_B <= Speed_At (I.Model, P, Curve, X);
            end;
         when Service_SBD =>
            --  d_offset + (V + dV_sbi) T_bs1
            X := I.Antenna + Travel_Ceil (V1, T_41) + Travel_Ceil (V1, T_Bs);
            return X <= D_PBD
              and then V1 <= Speed_At (I.Model, P, Curve, X);
      end case;
   end Holds;

   ------------------
   -- Unrounded_On --
   ------------------

   function Unrounded_On (I        : Inputs_T;
                          P        : Profile_T;
                          C        : Condition_T;
                          D_PBD    : PBD_Distance_T) return Speed_T
   is
      Lo : Speed_T := 0;
      Hi : Speed_T := Top_Speed;
   begin
      --  "if no speed value fulfils the above inequalities": 0
      if not Holds (I, P, C, D_PBD, 0) then
         return 0;
      elsif Holds (I, P, C, D_PBD, Top_Speed) then
         return Top_Speed;
      end if;
      --  Holds at Lo, not at Hi
      for K in 1 .. Iterations loop
         pragma Loop_Invariant (Lo < Hi and then Hi <= Top_Speed);
         exit when Hi - Lo <= 1;
         declare
            Mid : constant Speed_T := (Lo + Hi) / 2;
         begin
            if Holds (I, P, C, D_PBD, Mid) then
               Lo := Mid;
            else
               Hi := Mid;
            end if;
         end;
      end loop;
      return Lo;
   end Unrounded_On;

   ---------------
   -- Unrounded --
   ---------------

   function Unrounded (I        : Inputs_T;
                       C        : Condition_T;
                       D_PBD    : PBD_Distance_T;
                       Gradient : Gradient_T) return Speed_T
   is
      P : Profile_T;
   begin
      Section_Profile (I, Gradient, P);
      return Unrounded_On (I, P, C, D_PBD);
   end Unrounded;

   --------------
   -- Restrict --
   --------------

   procedure Restrict (I        : Inputs_T;
                       D_PBD    : PBD_Distance_T;
                       Gradient : Gradient_T;
                       Service  : Boolean;
                       Work     : in out Profile_T;
                       V        : out Speed_Cms_T)
   is
      U : Speed_T;
      K : Num;
   begin
      if not I.Model.Valid then
         V := 0;
         return;
      end if;
      Section_Profile (I, Gradient, Work);
      if Service then
         --  3.11.11.7: the most restrictive of 3.11.11.8 and 3.11.11.9
         U := Min (Unrounded_On (I, Work, Service_EBD, D_PBD),
                   Unrounded_On (I, Work, Service_SBD, D_PBD));
      else
         --  3.11.11.6
         U := Unrounded_On (I, Work, Emergency, D_PBD);
      end if;
      --  rounded down to a multiple of 5 km/h, then to the cm/s
      K := Cms_To_Kmh_Floor (U) / 5;
      V := Speed_Cms_T (K * 1_250 / 9);
   end Restrict;

   -----------------
   -- Restriction --
   -----------------

   function Restriction (I        : Inputs_T;
                         D_PBD    : PBD_Distance_T;
                         Gradient : Gradient_T;
                         Service  : Boolean) return Speed_Cms_T
   is
      Work : Profile_T;
      V    : Speed_Cms_T;
   begin
      pragma Warnings (GNATprove, Off, """Work"" is set by ""Restrict""*",
                       Reason => "only the speed is kept");
      Restrict (I, D_PBD, Gradient, Service, Work, V);
      pragma Warnings (GNATprove, On, """Work"" is set by ""Restrict""*");
      return V;
   end Restriction;

end EVC_PBD;
