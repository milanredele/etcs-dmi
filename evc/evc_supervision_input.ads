--  ETCS on-board (EVC)
--  What the speed and distance monitoring works on: the inputs of
--  SUBSET-026 3.13.2, as the stored information of the on-board hands
--  them to the supervision once per cycle.
--
--  This package is the boundary between the two halves of phase E3
--  (doc/EVC-PLAN.md §7):
--    - the stored information (SSP, ASP, TSR, gradients, MA, track
--      conditions, adhesion, national values, train data: 3.7, 3.8.4,
--      3.11, 3.12, 3.13.7) fills a Snapshot_T at the third step of the
--      cycle ("evaluate stored information");
--    - the supervision (3.13.2 to 3.13.6, 3.13.8 to 3.13.11, 3.14)
--      reads it at the fourth step and computes the limits, the
--      supervision status and the brake commands.
--  Types only, no state. Distances are positions in the odometer frame
--  (EVC_Distances, cm); "ahead" is the sense of Ahead. Speeds are cm/s,
--  accelerations mm/s², times ms, gradients per mille. Integers only:
--  the curves of 3.13 are computed in fixed point (plan §3).
--  The owner of a type is the half that produces it; the other half
--  may add what it needs, additively, and says so here.
--  Added by supervision: Supervision_Extra_T and the Extra component of
--  Snapshot_T (the train data, national values and configuration 3.13
--  and 3.14 need beyond the first version of this interface).
--
--  Conventions the supervision reads into the types (e3/supervision):
--  a Decel_Curve_T of Count steps gives Decel (K) for Speed (K - 1) <
--  V <= Speed (K), the first step from 0 and the last one open ended
--  (3.13.2.2.3.1.3 and .4), Count = 0 is no model; a Kv_Set_T and a
--  Kr_Set_T as packet 3 gives them: step K from its Speed (Length) K,
--  exclusive, to the next one, inclusive, the first from 0 and the last
--  open ended (3.13.2.3.7.11, .12, 7.5.1.175 V_NVKVINT), and an empty
--  set is the default of A.3.2 (Kv_int 0.7, Kr_int 0.9); Q_NVEMRRLS
--  True is the
--  value 1 of 7.5.1.123 (revoke the emergency brake when the Permitted
--  speed is no longer exceeded), False the value 0 (at standstill, the
--  default of A.3.2); A_NVMAXREDADHn is used as National_Extra_T says.

with EVC_Distances; use EVC_Distances;

package EVC_Supervision_Input
  with SPARK_Mode => On, Pure
is

   ---------------------------------------------------------------------
   --  Physical quantities
   ---------------------------------------------------------------------

   --  cm/s; 600 km/h is 16_667. V_ variables of 7.5 are km/h in 5 km/h
   --  steps and convert exactly.
   subtype Speed_Cms_T is Natural range 0 .. 30_000;
   No_Speed_Limit : constant Speed_Cms_T := Speed_Cms_T'Last;

   --  mm/s²; A_ variables of 7.5 are 0.05 m/s² steps (50 mm/s²)
   subtype Accel_Mms2_T is Integer range -30_000 .. 30_000;
   subtype Decel_Mms2_T is Accel_Mms2_T range 0 .. Accel_Mms2_T'Last;

   subtype Time_Ms_T is Natural range 0 .. 3_600_000;

   --  per mille, signed: uphill positive (G_A with Q_GDIR, 7.5.1.27)
   subtype Gradient_T is Integer range -255 .. 255;

   --  0 .. 1000 of a factor (Kdry_rst, Kwet_rst, Kv_int, Kr_int, Kt_int
   --  of 3.13.6 are given to 0.01 or better; 1000 = 1.00)
   subtype Factor_Milli_T is Natural range 0 .. 2_000;

   ---------------------------------------------------------------------
   --  Profiles along the track: piecewise constant from a start
   --  position, in the sense Ahead, the last segment open ended
   ---------------------------------------------------------------------

   Max_Speed_Segments    : constant := 256;
   Max_Gradient_Segments : constant := 128;

   type Speed_Segment_T is record
      Start : Dist_T;
      Speed : Speed_Cms_T;
   end record;
   type Speed_Segment_Array is
     array (Positive range 1 .. Max_Speed_Segments) of Speed_Segment_T;
   --  The MRSP (3.13.7): the most restrictive of SSP, ASP, TSR, LX,
   --  train, mode, override and signalling related restrictions, per
   --  position, with the front end / rear end handling (3.11.2, 3.11.3)
   --  already applied by the stored information
   type Speed_Profile_T is record
      Count    : Natural range 0 .. Max_Speed_Segments := 0;
      Segments : Speed_Segment_Array :=
        (others => (Start => 0, Speed => No_Speed_Limit));
   end record;

   type Gradient_Segment_T is record
      Start    : Dist_T;
      Gradient : Gradient_T;
   end record;
   type Gradient_Segment_Array is
     array (Positive range 1 .. Max_Gradient_Segments)
     of Gradient_Segment_T;
   type Gradient_Profile_T is record
      Count    : Natural range 0 .. Max_Gradient_Segments := 0;
      Segments : Gradient_Segment_Array :=
        (others => (Start => 0, Gradient => 0));
   end record;

   ---------------------------------------------------------------------
   --  The movement authority as the supervision sees it (3.8.3, 3.8.4,
   --  3.13.8.1): EOA and SvL positions in the frame, LOA speed, release
   --  speed. Section and overlap timers are handled by the stored
   --  information, which moves EOA / SvL when they elapse.
   ---------------------------------------------------------------------

   type Release_Speed_Kind_T is (None, Fixed, Calculated_On_Board);

   type Release_Speed_T is record
      Kind  : Release_Speed_Kind_T := None;
      Speed : Speed_Cms_T := 0;  -- with Fixed
   end record;

   type Movement_Authority_T is record
      Present       : Boolean := False;
      EOA           : Dist_T := 0;   -- end of authority (front end)
      SvL           : Dist_T := 0;   -- supervised location, >= EOA ahead
      LOA_Speed     : Speed_Cms_T := 0;  -- 0: the target is an EOA
      Release_Speed : Release_Speed_T;
   end record;

   ---------------------------------------------------------------------
   --  Track conditions that change the braking (3.13.5, 3.12.1,
   --  packet 68) and the adhesion (3.13.5, packet 71, the driver)
   ---------------------------------------------------------------------

   type Brake_Inhibition_T is
     (Regenerative_Inhibited,
      Eddy_Current_Service_Inhibited,
      Eddy_Current_Emergency_Inhibited,
      Magnetic_Shoe_Inhibited);

   Max_Inhibition_Areas : constant := 32;

   type Inhibition_Area_T is record
      Kind   : Brake_Inhibition_T;
      Start  : Dist_T;
      Finish : Dist_T;
   end record;
   type Inhibition_Area_Array is
     array (Positive range 1 .. Max_Inhibition_Areas) of Inhibition_Area_T;
   type Inhibition_Areas_T is record
      Count : Natural range 0 .. Max_Inhibition_Areas := 0;
      Areas : Inhibition_Area_Array :=
        (others => (Regenerative_Inhibited, 0, 0));
   end record;

   Max_Adhesion_Areas : constant := 32;

   type Adhesion_Area_T is record
      Start  : Dist_T;
      Finish : Dist_T;
   end record;
   type Adhesion_Area_Array is
     array (Positive range 1 .. Max_Adhesion_Areas) of Adhesion_Area_T;
   --  Reduced adhesion areas from the trackside and the driver's
   --  "slippery rail" (3.13.5.4, Q_NVDRIVER_ADHES)
   type Adhesion_T is record
      Count           : Natural range 0 .. Max_Adhesion_Areas := 0;
      Areas           : Adhesion_Area_Array := (others => (0, 0));
      Driver_Slippery : Boolean := False;
   end record;

   ---------------------------------------------------------------------
   --  Train data for the braking model (3.13.2.2, 3.18.3)
   ---------------------------------------------------------------------

   Max_Curve_Steps : constant := 8;

   --  A deceleration as a step function of the speed: below Speed (k)
   --  the deceleration is Decel (k); steps in rising speed order
   type Curve_Step_T is record
      Speed : Speed_Cms_T;
      Decel : Decel_Mms2_T;
   end record;
   type Curve_Step_Array is
     array (Positive range 1 .. Max_Curve_Steps) of Curve_Step_T;
   type Decel_Curve_T is record
      Count : Natural range 0 .. Max_Curve_Steps := 0;
      Steps : Curve_Step_Array := (others => (0, 0));
   end record;

   type Brake_Model_T is (Lambda, Gamma);

   --  Lambda: brake percentage and brake position (3.13.3); Gamma:
   --  the deceleration curves and build-up times (3.13.2.2.7 ff.)
   type Brake_Position_T is
     (Passenger_P, Freight_P, Freight_G);

   type Train_Data_T is record
      Length              : Length_T := 0;         -- L_TRAIN
      Max_Speed           : Speed_Cms_T := 0;      -- V_MAXTRAIN
      Model               : Brake_Model_T := Lambda;
      --  Lambda
      Brake_Percentage    : Natural range 0 .. 250 := 0;
      Brake_Position      : Brake_Position_T := Passenger_P;
      --  Gamma (3.13.2.2.7 to 3.13.2.2.9)
      A_Brake_Emergency   : Decel_Curve_T;
      A_Brake_Service     : Decel_Curve_T;
      A_Brake_Normal      : Decel_Curve_T;
      T_Brake_Emergency   : Time_Ms_T := 0;
      T_Brake_Service     : Time_Ms_T := 0;
      --  Special brakes the train has (3.13.2.2.6): their contribution
      --  is lost inside the matching inhibition area
      Has_Regenerative    : Boolean := False;
      Has_Eddy_Current    : Boolean := False;
      Has_Magnetic_Shoe   : Boolean := False;
      Has_Electro_Pneumatic : Boolean := False;
      --  Traction cut-off (3.13.2.2.6.x)
      T_Traction_Cut_Off  : Time_Ms_T := 0;
   end record;

   ---------------------------------------------------------------------
   --  National values used by the supervision (packet 3, defaults of
   --  A.3.2). The stored information keeps the whole packet; this is
   --  the part the supervision reads.
   ---------------------------------------------------------------------

   Max_Kv_Steps : constant := 8;

   type Kv_Step_T is record
      Speed  : Speed_Cms_T;
      Factor : Factor_Milli_T;
   end record;
   type Kv_Step_Array is array (Positive range 1 .. Max_Kv_Steps) of Kv_Step_T;
   type Kv_Set_T is record
      Count : Natural range 0 .. Max_Kv_Steps := 0;
      Steps : Kv_Step_Array := (others => (0, 1_000));
   end record;

   type Kr_Step_T is record
      Length : Length_T;
      Factor : Factor_Milli_T;
   end record;
   type Kr_Step_Array is array (Positive range 1 .. Max_Kv_Steps) of Kr_Step_T;
   type Kr_Set_T is record
      Count : Natural range 0 .. Max_Kv_Steps := 0;
      Steps : Kr_Step_Array := (others => (0, 1_000));
   end record;

   type National_Values_T is record
      M_NVEBCL         : Natural range 0 .. 9 := 9;   -- confidence level
      Q_NVGUIPERM      : Boolean := False;   -- guidance curve permitted
      Q_NVSBTSMPERM    : Boolean := True;    -- SB in target speed monitoring
      Q_NVINHSMICPERM  : Boolean := False;   -- inhibition of the SB when EB
      Q_NVEMRRLS       : Boolean := False;   -- EB revocable at standstill
      Q_NVSBFBPERM     : Boolean := False;   -- service brake feedback
      V_NVREL          : Speed_Cms_T := 0;   -- release speed by default
      D_NVROLL         : Length_T := 0;      -- roll away distance
      V_NVALLOWOVTRP   : Speed_Cms_T := 0;
      V_NVSUPOVTRP     : Speed_Cms_T := 0;
      D_NVOVTRP        : Length_T := 0;
      T_NVOVTRP        : Time_Ms_T := 0;
      D_NVPOTRP        : Length_T := 0;
      V_NVSHUNT        : Speed_Cms_T := 0;
      V_NVSTFF         : Speed_Cms_T := 0;
      V_NVONSIGHT      : Speed_Cms_T := 0;
      V_NVLIMSUPERV    : Speed_Cms_T := 0;
      V_NVUNFIT        : Speed_Cms_T := 0;
      D_NVSTFF         : Length_T := 0;
      M_NVAVADH        : Factor_Milli_T := 0;
      A_NVMAXREDADH1   : Decel_Mms2_T := 0;
      A_NVMAXREDADH2   : Decel_Mms2_T := 0;
      A_NVMAXREDADH3   : Decel_Mms2_T := 0;
      Q_NVDRIVER_ADHES : Boolean := False;
      Kv_Int_Fresh     : Kv_Set_T;   -- freight trains in P, or all trains
      Kv_Int_Passenger : Kv_Set_T;   -- when Q_NVKVINTSET gives two sets
      Kr_Int           : Kr_Set_T;
      Kt_Int           : Factor_Milli_T := 1_000;
      --  added by profiles: the second subset of the passenger set of
      --  Kv_int (3.13.2.3.7.11.4 to .6: Kv_Int_Passenger is subset "a",
      --  for a maximum emergency brake deceleration up to A_NVP12, this
      --  one subset "b", from A_NVP23), and the two limits. A step of a
      --  Kv_Set_T holds from its Speed up to the next step's (M_NVKVINT
      --  of 7.5.1.75.4), a Kr_Step_T likewise from its Length.
      Kv_Int_Passenger_B : Kv_Set_T;
      A_NVP12          : Decel_Mms2_T := 0;
      A_NVP23          : Decel_Mms2_T := 0;
   end record;

   ---------------------------------------------------------------------
   --  The train as the position of phase E2 gives it (3.6.1, 3.6.4)
   ---------------------------------------------------------------------

   type Train_State_T is record
      Position_Valid   : Boolean := False;
      Ahead            : Sense_T := Plus;   -- sense of the movement authority
      Est_Front        : Dist_T := 0;
      Max_Safe_Front   : Dist_T := 0;
      Min_Safe_Front   : Dist_T := 0;
      Speed            : Speed_Cms_T := 0;  -- estimated
      Speed_Max        : Speed_Cms_T := 0;  -- upper bound of the odometer
      Standstill       : Boolean := True;
      Moving_Ahead     : Boolean := False;  -- in the sense Ahead
      Moving_Backwards : Boolean := False;
   end record;

   ---------------------------------------------------------------------
   --  Added by profiles: the temporary EOA and SvL (3.12.2.5), distinct
   --  from those of the MA, with no release speed: the start of a mode
   --  profile (3.12.4.7) and of a level crossing not protected
   --  (3.12.5.8); the nearest of them. Has_SvL False: no temporary SvL
   --  (3.12.4.7.1), the SvL of the MA holds. SvL >= EOA ahead.
   ---------------------------------------------------------------------

   type Temporary_Target_T is record
      Present : Boolean := False;
      EOA     : Dist_T := 0;
      Has_SvL : Boolean := False;
      SvL     : Dist_T := 0;
   end record;

   ---------------------------------------------------------------------
   --  Added by supervision (e3/supervision): what 3.13 and 3.14 read
   --  beyond the types above. The stored information fills them from
   --  the train data, the national values and the configuration of the
   --  on-board; their defaults are the values of A.3.2 or "not fitted",
   --  so a snapshot that leaves them alone is valid.
   ---------------------------------------------------------------------

   --  3.13.2.2.6 (SUBSET-034 2.3.6): the special brakes
   type Special_Brake_T is
     (Regenerative, Eddy_Current, Magnetic_Shoe, Electro_Pneumatic);

   --  3.13.2.2.6.1 Table 3: whether an interface with the special brake
   --  exists and which brake models its status affects
   type Special_Brake_Interface_T is
     (No_Interface, Emergency_Only, Service_Only, Emergency_And_Service);
   type Special_Brake_Interfaces_T is
     array (Special_Brake_T) of Special_Brake_Interface_T;

   --  The configuration of the on-board (3.13.2.2.6 to 3.13.2.2.8)
   type Onboard_Config_T is record
      --  3.13.2.2.7.1: a service brake interface commands a full
      --  service brake
      Service_Brake_Command    : Boolean := True;
      --  3.13.2.2.7.2: the service brake feedback (the brake pressure
      --  of SUBSET-034 2.3.2) is acquired; A.3.10.3: from the brake
      --  cylinder instead of the main brake pipe, with the constant k1
      --  (in thousandths)
      Service_Brake_Feedback   : Boolean := False;
      Feedback_From_Cylinder   : Boolean := False;
      K1_Milli                 : Positive range 1_000 .. 5_000 := 2_500;
      --  3.13.2.2.8.1: the traction cut-off command is implemented
      Traction_Cut_Off         : Boolean := True;
      Special_Brakes           : Special_Brake_Interfaces_T :=
        (others => No_Interface);
      --  3.13.2.2.6.4: the contribution of a special or additional brake
      --  independent from the adhesion may select A_NVMAXREDADH1
      Additional_Brake_Allowed : Boolean := False;
   end record;

   --  A combination of special brakes in use: bit 0 regenerative, bit 1
   --  eddy current, bit 2 magnetic shoe, bit 3 Ep brake. The models of
   --  the deceleration depend on the first three (3.13.2.2.3.1.7), the
   --  brake build up times on all four (3.13.2.2.3.2.8, Table 4).
   subtype Combination_T is Natural range 0 .. 15;
   subtype Brake_Combination_T is Combination_T range 0 .. 7;
   type Combination_Curves_T is
     array (Brake_Combination_T) of Decel_Curve_T;

   --  A brake reaction time and an equivalent brake build up time
   --  (3.13.2.2.3.2.3, 3.13.2.2.3.2.4)
   type Build_Up_T is record
      React    : Time_Ms_T := 0;
      Build_Up : Time_Ms_T := 0;
   end record;
   type Combination_Times_T is array (Combination_T) of Build_Up_T;

   --  A factor per step of a deceleration curve (the steps of
   --  A_brake_emergency, 3.13.2.2.9.1.3 and 3.13.2.2.9.1.5)
   type Factor_Steps_T is array (1 .. Max_Curve_Steps) of Factor_Milli_T;
   --  Kdry_rst by confidence level (M_NVEBCL 0 .. 9)
   type Kdry_T is array (0 .. 9) of Factor_Steps_T;

   --  3.13.2.2.3.1.9: a set of three normal service models, chosen by
   --  A_brake_service (V = 0) against A_SB01 and A_SB12
   type Normal_Service_Set_T is array (0 .. 2) of Decel_Curve_T;

   type Train_Data_Extra_T is record
      --  3.13.2.2.3.2.3 a): the brake reaction times of the braking
      --  models (Train_Data_T has the equivalent build up times)
      T_Brake_Emergency_React : Time_Ms_T := 0;
      T_Brake_Service_React   : Time_Ms_T := 0;
      --  3.13.2.2.9.1: the rolling stock correction factors, one set for
      --  every deceleration model (the default: 1.00, no correction)
      Kdry_Rst                : Kdry_T := (others => (others => 1_000));
      Kwet_Rst                : Factor_Steps_T := (others => 1_000);
      --  3.13.2.2.9.2: Kn+ and Kn-, mm/s² per unit of gradient (the
      --  deceleration Kn * grad / 1000 of 3.13.6.4.3)
      Kn_Plus                 : Decel_Curve_T;
      Kn_Minus                : Decel_Curve_T;
      --  3.13.2.2.3.1.9 a) and b), 3.13.2.2.3.1.10; an empty set takes
      --  Train_Data_T.A_Brake_Normal
      Normal_Service_G        : Normal_Service_Set_T;
      Normal_Service_P        : Normal_Service_Set_T;
      A_SB01                  : Decel_Mms2_T := 0;
      A_SB12                  : Decel_Mms2_T := 0;
      --  3.13.2.2.10.1: the nominal rotating mass, percent of the train
      --  weight; 0 when not given (A.3.1 M_rotating_max and _min apply)
      M_Rotating_Nom          : Natural range 0 .. 100 := 0;
      --  3.13.2.2.3.1.7, 3.13.2.2.3.2.8: the models by combination of
      --  the special brakes in use; when False the single models of
      --  Train_Data_T apply to every combination
      By_Combination          : Boolean := False;
      A_Emergency_Combination : Combination_Curves_T;
      A_Service_Combination   : Combination_Curves_T;
      T_Emergency_Combination : Combination_Times_T;
      T_Service_Combination   : Combination_Times_T;
   end record;

   --  A_NVMAXREDADHn (7.5.0.1 to 7.5.0.3): a deceleration limit, or one
   --  of the special values 61 (no limit, target information in CSM), 62
   --  (no limit, time to Indication in CSM) and 63 (no limit, nothing
   --  more displayed)
   type Redadh_Use_T is
     (Limit, Target_Information, Time_To_Indication, No_Limit);
   type Redadh_Uses_T is array (1 .. 3) of Redadh_Use_T;

   type National_Extra_T is record
      --  3.13.2.3.7.11.4: the subset b of the Kv_int of conventional
      --  passenger trains and the pivot decelerations; A_NVP12 =
      --  A_NVP23 = 0 when Q_NVKVINTSET gives a single set
      Kv_Int_Passenger_B : Kv_Set_T;
      A_NVP12            : Decel_Mms2_T := 0;
      A_NVP23            : Decel_Mms2_T := 0;
      --  how A_NVMAXREDADH1 .. 3 are used (National_Values_T holds the
      --  limits): A.3.2 gives limits (1.0, 0.7, 0.7 m/s²)
      Redadh_Use         : Redadh_Uses_T := (others => Limit);
   end record;

   type Supervision_Extra_T is record
      Config         : Onboard_Config_T;
      Train          : Train_Data_Extra_T;
      National       : National_Extra_T;
      --  3.13.9.4.8.2: the train position confidence interval predicted
      --  at the EOA, 2 * Q_LOCACC of the reference balise group + 10 m +
      --  10 % of its distance to the EOA (with the SM term when beta =
      --  1); the on-board takes the larger of it and the current one
      Trip_Margin    : Length_T := 0;
      --  3.13.11.8: T_MAR of the MA request parameters (packet 57, E5);
      --  0 when none is stored
      T_MAR          : Time_Ms_T := 0;
      --  3.13.2.3.6.1 b), 3.13.8.2.1 d): the end of the maximum
      --  permitted distance to run in Staff Responsible (E4)
      SR_Distance    : Boolean := False;
      SR_End         : Dist_T := 0;
   end record;

   ---------------------------------------------------------------------
   --  Everything the supervision reads in one cycle
   ---------------------------------------------------------------------

   type Snapshot_T is record
      Train        : Train_State_T;
      Train_Data   : Train_Data_T;
      National     : National_Values_T;
      MRSP         : Speed_Profile_T;
      Gradients    : Gradient_Profile_T;
      MA           : Movement_Authority_T;
      Inhibitions  : Inhibition_Areas_T;
      Adhesion     : Adhesion_T;
      --  Mode related ceiling speed (3.11.7), No_Speed_Limit when the
      --  mode has none; the mode machine of E4 sets it
      Mode_Speed   : Speed_Cms_T := No_Speed_Limit;
      --  Train data valid and the supervision may run (4.5.2, E4);
      --  until E4 the stored information sets it when an MA is present
      Supervise    : Boolean := False;
      --  added by profiles: the temporary EOA and SvL (see above)
      Temporary    : Temporary_Target_T;
      --  added by supervision: the train data, national values and
      --  on-board configuration 3.13 and 3.14 read beyond the components
      --  above (Supervision_Extra_T below); the defaults are the A.3.2
      --  values or "not fitted"
      Extra        : Supervision_Extra_T;
   end record;

end EVC_Supervision_Input;
