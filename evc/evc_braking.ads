--  ETCS on-board (EVC)
--  The braking model of the speed and distance monitoring: SUBSET-026
--  3.13.2 (inputs), 3.13.3 with A.3.7 to A.3.9 (conversion models),
--  3.13.5 (the special brakes and the adhesion that apply) and 3.13.6
--  (the safe, expected and normal service decelerations and the brake
--  build up times).
--
--  Build derives, once per cycle, from the snapshot and the status of
--  the special brakes on the train interface, the deceleration models
--  the curves use as step functions of the speed:
--    - A_brake_safe (V) of 3.13.6.2.1.4 for every combination of the
--      special brakes that contribute (regenerative, eddy current,
--      magnetic shoe: 3.13.2.2.3.1.7), the correction factors applied
--      (Kdry_rst and Kwet_rst with M_NVEBCL and M_NVAVADH for braking
--      models, Kv_int and Kr_int for the conversion model);
--    - A_brake_service (V) (3.13.6.3.1.4) and A_brake_normal_service
--      (V) (3.13.6.4.4, with the set and the model of 3.13.2.2.3.1.9
--      and .10) for every combination of regenerative and eddy current
--      brake;
--    - Kn+ and Kn- (3.13.2.2.9.2);
--  and the brake reaction and build up times T_be_react, T_be,
--  T_bs_react, T_bs (3.13.6.2.2.3, 3.13.6.3.2.4) for targets at zero
--  speed and the others (A.3.8.4, A.3.9.4), the rotating masses of
--  3.13.4.3.2 and the A_MAXREDADH that applies (3.13.6.2.1.6).
--  The location dependent parts (gradient, adhesion, inhibition areas)
--  are EVC_Profile; the curves themselves EVC_Curves.
--
--  Units: the decelerations of the models are in Decel_Unit (10 um/s²,
--  1/100 mm/s²), finer than the inputs (mm/s²) so that the rounding of
--  the products with the correction factors stays below one unit; the
--  factors are in millionths (Micro). Rounding: every deceleration and
--  factor is rounded down (at most one unit of error for a model: the
--  products are formed with one division), every time up, so that the
--  curves rearwards of their anchor are never above the exact ones
--  (EVC_Curves adds Forward_Margin forwards). The step boundaries the
--  conversion model computes (V_lim and 100, 120, 150, 180 km/h in
--  cm/s) fall between two integers: the boundary is put on the side
--  that gives the lower deceleration to the speeds in between.

with EVC_Distances;
with EVC_Fixed;             use EVC_Fixed;
with EVC_Supervision_Input; use EVC_Supervision_Input;

use type EVC_Distances.Cm_T;

package EVC_Braking
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------
   --  Step functions of the speed (3.13.2.2.3.1.3, Figure 30)
   ---------------------------------------------------------------------

   Max_Steps : constant := 16;

   --  A deceleration of a model in 1/100 mm/s² (1e-5 m/s²)
   Decel_Unit_Per_Mms2 : constant := 100;
   Max_Model_Decel     : constant := 6_000_000;   -- 60 m/s²
   --  a factor in millionths
   Micro : constant := 1_000_000;

   --  The value of a step: a deceleration (Decel_Unit) or a factor
   --  (Micro)
   subtype Value_T is Num range 0 .. 10_000_000;

   --  Step K holds for Upper (K - 1) < V <= Upper (K), the first from 0,
   --  the last one (Count) open ended: its Upper is not used
   type Step_T is record
      Upper : Speed_T := 0;
      Value : Value_T := 0;
   end record;
   type Step_Array is array (1 .. Max_Steps) of Step_T;
   subtype Step_Count_T is Natural range 0 .. Max_Steps;
   type Steps_T is record
      Count : Step_Count_T := 0;
      Steps : Step_Array := (others => (0, 0));
   end record;

   No_Steps : constant Steps_T := (Count => 0, Steps => (others => (0, 0)));

   --  Beyond the square of any speed
   Infinite_Square : constant := 2**50;

   --  The value of a step function at the speed whose square is W and
   --  the squares that bound the step: W_Lo < W <= W_Hi, or with Rising
   --  (a speed that is about to grow: at a boundary the step above)
   --  W_Lo <= W < W_Hi. W_Lo is -1 below the first step, W_Hi
   --  Infinite_Square above the last.
   type Lookup_T is record
      Value : Value_T;
      W_Lo  : Num;
      W_Hi  : Num;
   end record;

   function Lookup (S : Steps_T; W : Square_T; Rising : Boolean)
     return Lookup_T
     with Post => Lookup'Result.W_Lo in -1 .. Max_Speed * Max_Speed
                  and then Lookup'Result.W_Hi
                             in 0 .. Max_Speed * Max_Speed | Infinite_Square
                  and then (if Rising
                            then Lookup'Result.W_Lo <= W
                                 and then W < Lookup'Result.W_Hi
                            else Lookup'Result.W_Lo < W
                                 and then W <= Lookup'Result.W_Hi);

   function Value_At (S : Steps_T; V : Speed_T) return Value_T is
     (Lookup (S, V * V, False).Value);

   ---------------------------------------------------------------------
   --  The conversion model (3.13.3, A.3.7 to A.3.9)
   ---------------------------------------------------------------------

   --  3.13.3.2.1: the validity limits of the conversion models
   function Conversion_Applicable (T : Train_Data_T) return Boolean;

   subtype Lambda_T is Natural range 0 .. 250;

   --  A.3.7: A_basic (V) for the brake percentage Lambda_O (A.3.7.1: the
   --  percentage itself for the emergency brake, at most 135 for the
   --  service brake)
   function Basic_Deceleration (Lambda_O : Lambda_T) return Steps_T;

   --  V_lim of A.3.7.3, cm/s rounded down (the exact value lies below
   --  the next integer)
   function V_Lim (Lambda_O : Lambda_T) return Speed_T;

   type Times_T is record
      React    : Time_T := 0;   -- T_brake_react
      Build_Up : Time_T := 0;   -- T_brake_build_up, the equivalent one
   end record;

   --  A.3.8, A.3.9: the emergency and service brake times of the
   --  conversion model for a train of Length cm, for targets at zero
   --  speed (T_brake_*_cm0) or not (T_brake_*_cmt)
   function Conversion_Emergency (Position  : Brake_Position_T;
                                  Length    : Num;
                                  Zero_Speed : Boolean) return Times_T
     with Pre => Length in 0 .. 150_000;
   function Conversion_Service (Position  : Brake_Position_T;
                                Length    : Num;
                                Zero_Speed : Boolean) return Times_T
     with Pre => Length in 0 .. 150_000;

   ---------------------------------------------------------------------
   --  Correction factors of the conversion model (3.13.2.3.7, 3.13.6.2.1)
   ---------------------------------------------------------------------

   --  3.13.2.3.7.12: Kr_int (Length) of a set as packet 3 gives it (a
   --  step holds above its Length, the first from 0), in millionths; the
   --  default of A.3.2 for an empty set
   function Kr_Int (Set : Kr_Set_T; Length : Num) return Value_T;

   --  3.13.6.2.1.8.2: A_ebmax, the largest value of the deceleration
   --  model Emergency at the speeds from 0 to V_Max
   function A_Ebmax (Emergency : Steps_T; V_Max : Speed_T) return Value_T;

   --  3.13.2.3.7.11, 3.13.6.2.1.8: Kv_int (V) as a step function of the
   --  speed, in millionths: for a passenger train in P the passenger set
   --  when one is given (between its subsets a and b by A_Ebmax, in
   --  Decel_Unit, 3.13.6.2.1.8.1), else the set for freight trains, else
   --  the default of A.3.2
   function Kv_Int (NV       : National_Values_T;
                    Position : Brake_Position_T;
                    A_Ebmax  : Value_T) return Steps_T;

   ---------------------------------------------------------------------
   --  The model
   ---------------------------------------------------------------------

   type Curve_Set_T is array (Brake_Combination_T) of Steps_T;
   type Brakes_T is array (Special_Brake_T) of Boolean;

   type Model_T is record
      --  a model of the emergency brake exists (3.13.2.2.1.3): the
      --  conversion model applies or braking models were given
      Valid           : Boolean := False;
      --  the conversion model is used (3.13.2.2.1.3, 3.13.3.2.1)
      Conversion      : Boolean := False;
      --  A_brake_safe (V), 3.13.6.2.1.4, by combination of the special
      --  brakes that contribute (bit 0 regenerative, 1 eddy current, 2
      --  magnetic shoe)
      Emergency_Safe  : Curve_Set_T := (others => No_Steps);
      --  A_brake_service (V), 3.13.6.3.1.4, by combination (bit 0
      --  regenerative, 1 eddy current)
      Service         : Curve_Set_T := (others => No_Steps);
      --  A_brake_normal_service (V), 3.13.6.4.4, by the same
      --  combinations; Has_Normal when a normal service model exists
      Normal_Service  : Curve_Set_T := (others => No_Steps);
      Has_Normal      : Boolean := False;
      Kn_Plus         : Steps_T := No_Steps;
      Kn_Minus        : Steps_T := No_Steps;
      --  the special brakes that contribute to the emergency and to the
      --  service brake models outside any inhibition area: the train
      --  has them and their status does not say "not active" (3.13.5.2)
      Emergency_Brakes : Brakes_T := (others => False);
      Service_Brakes   : Brakes_T := (others => False);
      --  3.13.6.2.1.6: A_MAXREDADH for this train (Decel_Unit) and how it
      --  is used
      Redadh_Use      : Redadh_Use_T := No_Limit;
      Redadh          : Value_T := 0;
      --  3.13.6.2.2.3, 3.13.6.3.2.4: T_be_react / T_be and T_bs_react /
      --  T_bs for targets at zero speed and for the others
      Emergency_Zero   : Times_T := (others => <>);
      Emergency_Target : Times_T := (others => <>);
      Service_Zero     : Times_T := (others => <>);
      Service_Target   : Times_T := (others => <>);
      --  3.13.4.3.2: the rotating mass, percent, for uphill and downhill
      M_Rotating_Up   : Natural range 0 .. 100 := 15;
      M_Rotating_Down : Natural range 0 .. 100 := 2;
   end record;

   --  Active: the status of the special brakes on the train interface
   --  (SUBSET-034 2.3.6); Additional: the additional brake status
   --  (2.3.7)
   procedure Build (S          : Snapshot_T;
                    Active     : Brakes_T;
                    Additional : Boolean;
                    Model      : out Model_T);

   --  The inhibitions in force at a location (3.13.5.1, packet 68)
   type Inhibitions_T is array (Brake_Inhibition_T) of Boolean;

   --  The combination of the special brakes that contribute to the
   --  emergency brake (3 bits) or to the service brake (2 bits) where
   --  the inhibitions of Inhibited are in force (3.13.5.1, 3.13.6.2.1.5,
   --  3.13.6.3.1.4)
   function Emergency_Combination (M : Model_T; Inhibited : Inhibitions_T)
     return Brake_Combination_T
   is ((if M.Emergency_Brakes (Regenerative)
          and then not Inhibited (Regenerative_Inhibited) then 1 else 0)
       + (if M.Emergency_Brakes (Eddy_Current)
            and then not Inhibited (Eddy_Current_Emergency_Inhibited)
          then 2 else 0)
       + (if M.Emergency_Brakes (Magnetic_Shoe)
            and then not Inhibited (Magnetic_Shoe_Inhibited)
          then 4 else 0));

   function Service_Combination (M : Model_T; Inhibited : Inhibitions_T)
     return Brake_Combination_T
   is ((if M.Service_Brakes (Regenerative)
          and then not Inhibited (Regenerative_Inhibited) then 1 else 0)
       + (if M.Service_Brakes (Eddy_Current)
            and then not Inhibited (Eddy_Current_Service_Inhibited)
          then 2 else 0));

end EVC_Braking;
