--  ETCS on-board (EVC)
--  Runner of the ERTMSFormalSpecs test frames (host only).
--
--  test/efs/*.scn are the functional test frames of ERTMSFormalSpecs
--  (EFS, an executable model of SUBSET-026 3.4.0, EUPL v1.1) as
--  test/tools/efs_frames.py translates them (format in its header). This
--  runner replays the translated actions on a state of its own in the
--  units of EFS, and checks the translated expectations of the E3
--  supervision family against the SPARK units of the on-board:
--    - the ceiling speed margins dV_warning, dV_sbi, dV_ebi (V):
--      EVC_Limits.Margin (the frames have none; kept for later ones);
--    - the braking models (BrakingModelFunction, A_brake_emergency /
--      _service / _normal_service / _safe (V, d), Kdry_rst, Kwet_rst,
--      A_MAXREDADH, Kn+ / Kn-, T_be, T_bs, the conversion model and its
--      limits): EVC_Braking.Build on a Snapshot_T made from the state,
--      Basic_Deceleration, Conversion_*, Kr_Int, Kv_Int, A_Ebmax, with
--      the location dependent parts through EVC_Profile.Build;
--    - A_gradient (d): EVC_Profile;
--    - the target terms T_traction, T_berem, V_delta1, V_delta2, V_bec
--      and D_bec (EVC_Limits.Bec, the function EBD_Limits uses), with
--      the inputs of Terms_T as EVC_SDM makes them (V_delta0, A_est1,
--      A_est2 and T_bs1 / T_bs2 themselves are computed inside EVC_SDM:
--      skipped).
--  Everything else is counted as skipped, with the reason: the
--  expectations kept verbatim, those after an untranslated action or a
--  telegram that changes the state they read (a "taint" line), those
--  whose function has no counterpart the runner calls. The SSP, TSR and
--  MRSP of the telegrams (expect SSP / TSR / MRSP / ceiling_P) need the
--  stored information with the balise group of reference of EFS: they
--  are translated and skipped, for phase E4.
--
--  The comparison rule. The value of EFS is converted into the unit of
--  ours (Decel_Unit, 1e-5 m/s², for the decelerations of the models and
--  the gradient; 0.001 for the factors; ms for times; cm/s for speeds;
--  cm for distances) without rounding; the check passes when our value
--  is at most one unit of our resolution away AND on the safe side:
--    - not above the value of EFS: every deceleration (the braking
--      models, A_brake_*, A_MAXREDADH, A_ebmax, A_gradient), the factors
--      Kdry_rst, Kwet_rst, Kv_int, Kr_int, the ceiling margins (a lower
--      margin intervenes earlier);
--    - not below: the times (T_be, T_bs, T_brake_*, T_traction,
--      T_berem), the speed and distance terms of the curves (V_delta0,
--      V_delta1, V_delta2, A_est1, A_est2, V_bec, D_bec);
--    - either side: the correction factors Kn+ and Kn- (the normal
--      service brake, not safety relevant: 3.13.6.4), the speeds of the
--      steps of the conversion model (EVC_Braking puts a boundary on the
--      side of the lower deceleration, which may be either);
--    - booleans (a brake in use, the conversion model applicable) are
--      equal or not.
--  A bound (<, >, <=, >=, "in") passes when our value is within one unit
--  of it. An expectation after an "xfail" line is a known difference
--  (the table of efs_frames.py): its failure counts as expected, its
--  success as a failure (the difference is gone: update the table).
--
--  How the state of EFS becomes ours (the interpretation, by quantity):
--    - a braking model of EFS gives (SpeedStep, Acceleration) per step,
--      SpeedStep the lower bound (BrakingModelFunction takes the step
--      whose SpeedStep <= V); ours (Decel_Curve_T) gives the upper
--      bounds: step k of EFS ends at SpeedStep (k + 1). The values
--      differ only at a speed that is a step boundary (3.13.2.2.3.1.3
--      has the step below the boundary; EFS the step above);
--    - Kv_int and Kr_int of EFS give (SpeedStep / LengthStep, value),
--      the value applying up to and including the step (EFS
--      Kv_intFunction, Kr_intFunction); ours (packet 3) give the lower
--      bounds, exclusive: the value k of EFS applies from step k - 1;
--    - the models of EFS are by combination of special brakes; ours too
--      (Train_Data_Extra_T.By_Combination), but ours keeps one set of
--      Kdry_rst / Kwet_rst while EFS has one per combination
--      (3.13.2.2.9.1.2): the runner gives ours the set of the
--      combination in use without inhibitions;
--    - a special brake whose interface is "none" in EFS is not fitted
--      (Has_* False), else fitted with the interface of Table 3;
--    - the traction cut-off time of EFS is Coefficient * A_est +
--      Constant of its traction model, given to ours as train data;
--    - T_brake_emergency / _service of EFS (3.4.0: one equivalent time)
--      are our build up times with a reaction time of 0;
--    - V_delta1 and V_delta2 of EFS are in m/s (A_est times a time, not
--      converted into km/h like its other speeds).
--  A failure of a function of the speed is evaluated again 1 cm/s above
--  the speed; when it passes there, the runner says that the speed is a
--  step boundary (the known difference of 3.13.2.2.3.1.3).
--
--  Usage:  obj/evc_efs_test            all of test/efs/*.scn
--          obj/evc_efs_test DIR        the scenarios of DIR
--          VERBOSE=1 obj/evc_efs_test  every check, not only failures
--  Exit status 1 when a check fails. When the folder is missing the
--  runner says so and succeeds: test/efs/ is optional (its README).

pragma Ada_2012;
with Ada.Characters.Handling;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Text_IO;            use Ada.Text_IO;
with EVC_Braking;            use EVC_Braking;
with EVC_Curves;
with EVC_Distances;          use EVC_Distances;
with EVC_Fixed;              use EVC_Fixed;
with EVC_Limits;
with EVC_National_Values;
with EVC_Profile;
with EVC_Supervision_Input;  use EVC_Supervision_Input;
with Scn_Reader;             use Scn_Reader;

procedure EVC_EFS_Test is

   Verbose : constant Boolean :=
     Ada.Environment_Variables.Exists ("VERBOSE");

   subtype Real is Scn_Reader.Real;
   Inf : constant Real := Real'Last;

   --  Words of a line, numbers: Scn_Reader (Word_T, Words_T, Line_T,
   --  Split, Word, Rest, Field, Valid, To_Real). Field is renamed here:
   --  "use Scn_Reader" and "use Ada.Text_IO" both make a "Field" visible
   --  (the function and Ada.Text_IO's column type), so the bare name is
   --  ambiguous without it (GNAT calls the renaming itself "redundant",
   --  which it is not: removing it does not compile).
   pragma Warnings (Off, "redundant renaming");
   function Field (S : String; K : Positive; Delims : String := ":=@+")
     return String renames Scn_Reader.Field;
   pragma Warnings (On, "redundant renaming");

   --  Rounded to the nearest integer, clamped
   function Round (X : Real; Lo, Hi : Num) return Num is
   begin
      if X /= X or else X >= Real (Hi) then
         return Hi;
      elsif X <= Real (Lo) then
         return Lo;
      else
         return Num (Real'Floor (X + 0.5));
      end if;
   end Round;

   --  Down, clamped
   function Floor (X : Real; Lo, Hi : Num) return Num is
   begin
      if X /= X or else X >= Real (Hi) then
         return Hi;
      elsif X <= Real (Lo) then
         return Lo;
      else
         return Num (Real'Floor (X));
      end if;
   end Floor;

   --  km/h -> cm/s, rounded down (step boundaries and the speeds at
   --  which a function is evaluated alike, so that they meet)
   function Cms (Kmh : Real) return Num is
     (Floor (Kmh * 250.0 / 9.0 + 1.0E-9, 0, 30_000));

   ---------------------------------------------------------------------
   --  The state, in the units of EFS
   ---------------------------------------------------------------------

   type Brake_Name_T is (Regenerative, Eddy_Current, Magnetic_Shoe, Ep);
   type Interface_T is (None, EB, SB, Both);

   type Step_R is record
      Speed : Real := Inf;     -- EFS SpeedStep (lower bound), km/h
      Value : Real := 0.0;     -- m/s² or factor
   end record;
   type EFS_Steps is array (0 .. 6) of Step_R;
   Default_Model : constant EFS_Steps :=
     (0 => (0.0, 1.0), others => (Inf, 0.0));

   type Model_Set is array (Brake_Combination_T) of EFS_Steps;
   type Factors_R is array (0 .. 6) of Real;
   type Kdry_R is array (Brake_Combination_T, 0 .. 9) of Factors_R;
   type Kwet_R is array (Brake_Combination_T) of Factors_R;
   type Times_R is array (Combination_T) of Real;
   type BNS_R is array (Boolean, 0 .. 2) of EFS_Steps;   -- True: P
   type Iface_R is array (Brake_Name_T) of Interface_T;
   type Bool_R is array (Brake_Name_T) of Boolean;

   --  Kv / Kr of EFS: (upper bound, value A, value B)
   type NV_Step is record
      Upper : Real := Inf;
      A, B  : Real := 0.0;
   end record;
   type NV_Steps is array (0 .. 4) of NV_Step;
   type NV_Set is record
      Count : Natural range 0 .. 5 := 0;
      S     : NV_Steps;
   end record;

   Max_Items : constant := 32;
   type TC_Kind is (TC_Regenerative, TC_Eddy_SB, TC_Eddy_EB, TC_Magnetic,
                    TC_Powerless, TC_Other);
   type Area_R is record
      Kind          : TC_Kind := TC_Other;
      From, Length  : Real := 0.0;   -- m
      Value         : Real := 0.0;   -- gradient per mille, or 0 / 1
      Indefinite    : Boolean := False;
   end record;
   type Area_Array is array (1 .. Max_Items) of Area_R;
   type Areas_R is record
      Count : Natural range 0 .. Max_Items := 0;
      A     : Area_Array;
   end record;

   type Area_Name is (Train, NV, Track, Odo, MA);
   type Taint_R is array (Area_Name) of Boolean;

   type State_R is record
      Length, V_Max            : Real := 0.0;
      Lambda                   : Real := -1.0;      -- -1: not given
      Position                 : Brake_Position_T := Passenger_P;
      M_Rotating               : Real := -1.0;      -- -1: not given
      Iface                    : Iface_R := (others => None);
      SB_Command, SB_Feedback  : Boolean := False;
      TCO                      : Boolean := False;
      Traction_Coef, Traction_Const : Real := 0.0;
      EB_Empty, SB_Empty       : Boolean := False;
      EB, SB                   : Model_Set := (others => Default_Model);
      Kdry                     : Kdry_R := (others => (others =>
                                                         (others => 1.0)));
      Kwet                     : Kwet_R := (others => (others => 1.0));
      T_EB, T_SB               : Times_R := (others => 0.0);
      T_EB_Empty, T_SB_Empty   : Boolean := False;
      NSB_Empty                : Boolean := False;
      A_SB01, A_SB12           : Real := -1.0;
      NSB                      : BNS_R := (others => (others =>
                                                        Default_Model));
      Kn_Plus, Kn_Minus        : EFS_Steps := (others => (Inf, 0.0));
      Active                   : Bool_R := (others => True);
      Additional               : Boolean := True;
      Additional_Allowed       : Boolean := False;
      --  national values
      NV                       : National_Values_T;
      Kr, Kv_Freight, Kv_Passenger : NV_Set;
      A_NVP12, A_NVP23         : Real := 0.0;
      Kv_Given                 : Boolean := False;
      --  track
      Conditions, Gradients, Adhesion : Areas_R;
      Driver_Slippery          : Boolean := False;
      --  odometry
      Speed, Accel, Odo_Position : Real := 0.0;
      V_Ura, V_Ora, D_Ura, D_Ora : Real := 0.0;
      Target_Speed             : Real := 0.0;
   end record;

   St    : State_R;
   Taint : Taint_R := (others => False);
   Initialised : Boolean := False;

   ---------------------------------------------------------------------
   --  Counters
   ---------------------------------------------------------------------

   Max_Reasons : constant := 64;
   type Reason_R is record
      Text  : String (1 .. 60) := (others => ' ');
      Count : Natural := 0;
   end record;
   type Reasons_T is array (1 .. Max_Reasons) of Reason_R;
   Reasons : Reasons_T;

   type Counts_R is record
      Checks, Failures, Xfails, Skipped : Natural := 0;
   end record;
   Total, Frame : Counts_R;

   procedure Skip (Why : String) is
      T : String (1 .. 60) := (others => ' ');
      N : constant Natural := Natural'Min (Why'Length, 60);
   begin
      T (1 .. N) := Why (Why'First .. Why'First + N - 1);
      Frame.Skipped := Frame.Skipped + 1;
      for R of Reasons loop
         if R.Count = 0 then
            R := (T, 1);
            return;
         elsif R.Text = T then
            R.Count := R.Count + 1;
            return;
         end if;
      end loop;
   end Skip;

   Frame_Name : String (1 .. 80) := (others => ' ');
   Frame_Len  : Natural := 0;
   Where      : String (1 .. 160) := (others => ' ');
   Where_Len  : Natural := 0;

   procedure Set_Where (S : String) is
      N : constant Natural := Natural'Min (S'Length, Where'Length);
   begin
      Where (1 .. N) := S (S'First .. S'First + N - 1);
      Where_Len := N;
   end Set_Where;

   ---------------------------------------------------------------------
   --  Actions
   ---------------------------------------------------------------------

   function Brake_Of (S : String; Ok : out Boolean) return Brake_Name_T is
   begin
      Ok := True;
      if S = "regenerative" then
         return Regenerative;
      elsif S = "eddy_current" then
         return Eddy_Current;
      elsif S = "magnetic_shoe" then
         return Magnetic_Shoe;
      elsif S = "ep" then
         return Ep;
      end if;
      Ok := False;
      return Regenerative;
   end Brake_Of;

   function Bool_Of (S : String) return Boolean is
   begin
      if S = "true" or else S = "1" then
         return True;
      elsif S = "false" or else S = "0" then
         return False;
      end if;
      Valid := False;
      return False;
   end Bool_Of;

   function Comb_Of (S : String; Last : Natural) return Natural is
      R : constant Real := To_Real (S);
   begin
      if not Valid or else R < 0.0 or else R > Real (Last)
        or else R /= Real'Floor (R)
      then
         Valid := False;
         return 0;
      end if;
      return Natural (R);
   end Comb_Of;

   --  "k:speed:value" words from word K on into steps (EFS order)
   procedure Read_Steps (L : Line_T; K : Positive; S : out EFS_Steps) is
   begin
      S := (others => (Inf, 0.0));
      for I in K .. L.Count loop
         declare
            W : constant String := Word (L, I);
            J : constant Natural := Comb_Of (Field (W, 1), 6);
         begin
            exit when not Valid;
            S (J) := (To_Real (Field (W, 2)), To_Real (Field (W, 3)));
         end;
      end loop;
   end Read_Steps;

   procedure Read_Factors (L : Line_T; K : Positive; F : in out Factors_R)
   is
   begin
      for I in K .. L.Count loop
         declare
            W : constant String := Word (L, I);
            J : constant Natural := Comb_Of (Field (W, 1), 6);
         begin
            exit when not Valid;
            F (J) := To_Real (Field (W, 2));
         end;
      end loop;
   end Read_Factors;

   procedure Read_NV_Set (L : Line_T; K : Positive; Two : Boolean;
                          S : out NV_Set) is
   begin
      S := (Count => 0, S => (others => <>));
      for I in K .. L.Count loop
         declare
            W : constant String := Word (L, I);
            J : constant Natural := Comb_Of (Field (W, 1), 4);
         begin
            exit when not Valid;
            S.S (J) := (Upper => To_Real (Field (W, 2)),
                        A     => To_Real (Field (W, 3)),
                        B     => (if Two then To_Real (Field (W, 4))
                                  else 0.0));
            S.Count := Natural'Max (S.Count, J + 1);
         end;
      end loop;
   end Read_NV_Set;

   procedure Read_Areas (L : Line_T; Kind : Character; A : out Areas_R) is
   begin
      A := (Count => 0, A => (others => <>));
      for I in 3 .. L.Count loop
         exit when A.Count = Max_Items;
         declare
            W : constant String := Word (L, I);
            R : Area_R;
         begin
            case Kind is
               when 'c' =>   -- kind@from+length
                  declare
                     K : constant String := Field (W, 1);
                  begin
                     R.Kind :=
                       (if K = "regenerative" then TC_Regenerative
                        elsif K = "eddy_current_sb" then TC_Eddy_SB
                        elsif K = "eddy_current_eb" then TC_Eddy_EB
                        elsif K = "magnetic_shoe" then TC_Magnetic
                        elsif K'Length > 9
                          and then K (K'First .. K'First + 8) = "powerless"
                        then TC_Powerless
                        else TC_Other);
                     R.From := To_Real (Field (W, 2));
                     R.Length := To_Real (Field (W, 3));
                  end;
               when 'g' =>   -- from:gradient
                  R.From := To_Real (Field (W, 1));
                  if Field (W, 2) = "indefinite" then
                     R.Indefinite := True;
                  else
                     R.Value := To_Real (Field (W, 2));
                  end if;
               when others =>   -- from+length:M_ADHESION
                  R.From := To_Real (Field (W, 1));
                  R.Length := To_Real (Field (W, 2));
                  R.Value := To_Real (Field (W, 3));
            end case;
            A.Count := A.Count + 1;
            A.A (A.Count) := R;
         end;
      end loop;
   end Read_Areas;

   function Milli (X : Real) return Natural is
     (Natural (Round (X * 1000.0, 0, 2_000)));

   --  NA (A_NVP12, A_NVP23 not given) is 0: the subset a of Kv_int
   procedure NV_Scalar (Key : String; Value : String) is
      V : constant Real := (if Value = "na" then 0.0 else To_Real (Value));
      N : National_Values_T renames St.NV;
      function Cms_Of (X : Real) return Speed_Cms_T is
        (Speed_Cms_T (Cms (X)));
   begin
      if not Valid then
         return;
      end if;
      if Key = "M_NVEBCL" then
         N.M_NVEBCL := Natural (Round (V, 0, 9));
      elsif Key = "M_NVAVADH" then
         N.M_NVAVADH := Milli (V);
      elsif Key = "A_NVMAXREDADH1" then
         N.A_NVMAXREDADH1 := Decel_Mms2_T (Round (V * 1000.0, 0, 30_000));
      elsif Key = "A_NVMAXREDADH2" then
         N.A_NVMAXREDADH2 := Decel_Mms2_T (Round (V * 1000.0, 0, 30_000));
      elsif Key = "A_NVMAXREDADH3" then
         N.A_NVMAXREDADH3 := Decel_Mms2_T (Round (V * 1000.0, 0, 30_000));
      elsif Key = "Kt_int" then
         N.Kt_Int := Milli (V);
      elsif Key = "Q_NVINHSMICPERM" then
         N.Q_NVINHSMICPERM := V = 1.0;
      elsif Key = "Q_NVGUIPERM" then
         N.Q_NVGUIPERM := V = 1.0;
      elsif Key = "Q_NVSBFBPERM" then
         N.Q_NVSBFBPERM := V = 1.0;
      elsif Key = "Q_NVSBTSMPERM" then
         N.Q_NVSBTSMPERM := V = 1.0;
      elsif Key = "Q_NVEMRRLS" then
         N.Q_NVEMRRLS := V = 1.0;
      elsif Key = "Q_NVDRIVER_ADHES" then
         N.Q_NVDRIVER_ADHES := V = 1.0;
      elsif Key = "V_NVREL" then
         N.V_NVREL := Cms_Of (V);
      elsif Key = "A_NVP12" then
         St.A_NVP12 := V;
      elsif Key = "A_NVP23" then
         St.A_NVP23 := V;
      end if;
      --  the others are outside what the runner checks
   end NV_Scalar;

   procedure Do_Set (L : Line_T) is
      Key : constant String := Word (L, 2);
      A3  : constant String := Word (L, 3);
      Ok  : Boolean;
   begin
      Valid := True;
      if Key = "train.length" then
         St.Length := To_Real (A3);
      elsif Key = "train.v_max" then
         St.V_Max := To_Real (A3);
      elsif Key = "train.lambda" then
         St.Lambda := (if A3 = "na" then -1.0 else To_Real (A3));
      elsif Key = "train.brake_position" then
         St.Position := (if A3 = "freight_p" then Freight_P
                         elsif A3 = "freight_g" then Freight_G
                         else Passenger_P);
      elsif Key = "train.m_rotating_nom" then
         St.M_Rotating := (if A3 = "na" then -1.0 else To_Real (A3));
      elsif Key = "train.interface" then
         declare
            B : constant Brake_Name_T := Brake_Of (A3, Ok);
            V : constant String := Word (L, 4);
         begin
            if Ok then
               St.Iface (B) := (if V = "eb" then EB elsif V = "sb" then SB
                                elsif V = "both" then Both else None);
            end if;
         end;
      elsif Key = "train.sb_command" then
         St.SB_Command := Bool_Of (A3);
      elsif Key = "train.sb_feedback" then
         St.SB_Feedback := Bool_Of (A3);
      elsif Key = "train.traction_cut_off" then
         St.TCO := Bool_Of (A3);
      elsif Key = "train.traction_model" then
         St.Traction_Coef := To_Real (A3);
         St.Traction_Const := To_Real (Word (L, 4));
      elsif Key = "train.eb_models" or else Key = "train.sb_models" then
         declare
            Empty : constant Boolean := A3 = "empty";
         begin
            if Key = "train.eb_models" then
               St.EB := (others => Default_Model);
               St.EB_Empty := Empty;
               St.Kdry := (others => (others => (others => 1.0)));
               St.Kwet := (others => (others => 1.0));
            else
               St.SB := (others => Default_Model);
               St.SB_Empty := Empty;
            end if;
         end;
      elsif Key = "train.eb_model" or else Key = "train.sb_model" then
         declare
            C : constant Natural := Comb_Of (A3, 7);
            S : EFS_Steps;
         begin
            Read_Steps (L, 4, S);
            if Valid then
               if Key = "train.eb_model" then
                  St.EB (C) := S;
                  St.EB_Empty := False;
               else
                  St.SB (C) := S;
                  St.SB_Empty := False;
               end if;
            end if;
         end;
      elsif Key = "train.eb_step" or else Key = "train.sb_step" then
         declare
            C : constant Natural := Comb_Of (A3, 7);
            K : constant Natural := Comb_Of (Word (L, 4), 6);
            S : constant Step_R :=
              (To_Real (Word (L, 5)), To_Real (Word (L, 6)));
         begin
            if Valid then
               if Key = "train.eb_step" then
                  St.EB (C) (K) := S;
               else
                  St.SB (C) (K) := S;
               end if;
            end if;
         end;
      elsif Key = "train.kdry" then
         declare
            C  : constant Natural := Comb_Of (A3, 7);
            CL : constant Natural := Comb_Of (Word (L, 4), 9);
         begin
            if Valid then
               Read_Factors (L, 5, St.Kdry (C, CL));
            end if;
         end;
      elsif Key = "train.kwet" then
         declare
            C : constant Natural := Comb_Of (A3, 7);
         begin
            if Valid then
               Read_Factors (L, 4, St.Kwet (C));
            end if;
         end;
      elsif Key = "train.t_brake_emergency"
        or else Key = "train.t_brake_service"
      then
         declare
            E : constant Boolean := Key = "train.t_brake_emergency";
         begin
            if A3 = "clear" or else A3 = "empty" then
               if E then
                  St.T_EB := (others => 0.0);
                  St.T_EB_Empty := A3 = "empty";
               else
                  St.T_SB := (others => 0.0);
                  St.T_SB_Empty := A3 = "empty";
               end if;
            else
               declare
                  C : constant Natural := Comb_Of (A3, 15);
                  T : constant Real := To_Real (Word (L, 4));
               begin
                  if Valid then
                     if E then
                        St.T_EB (C) := T;
                        St.T_EB_Empty := False;
                     else
                        St.T_SB (C) := T;
                        St.T_SB_Empty := False;
                     end if;
                  end if;
               end;
            end if;
         end;
      elsif Key = "train.nsb" then
         St.NSB := (others => (others => Default_Model));
         St.A_SB01 := -1.0;
         St.A_SB12 := -1.0;
         St.NSB_Empty := A3 = "empty";
      elsif Key = "train.nsb_a_sb01" then
         St.A_SB01 := To_Real (A3);
      elsif Key = "train.nsb_a_sb12" then
         St.A_SB12 := To_Real (A3);
      elsif Key = "train.nsb_model" then
         declare
            P : constant Boolean := A3 = "p";
            K : constant Natural := Comb_Of (Word (L, 4), 2);
            S : EFS_Steps;
         begin
            Read_Steps (L, 5, S);
            if Valid then
               St.NSB (P, K) := S;
               St.NSB_Empty := False;
            end if;
         end;
      elsif Key = "train.kn_plus" or else Key = "train.kn_minus" then
         declare
            S : EFS_Steps := (others => (Inf, 0.0));
         begin
            if A3 /= "clear" then
               Read_Steps (L, 3, S);
            end if;
            if Valid then
               if Key = "train.kn_plus" then
                  St.Kn_Plus := S;
               else
                  St.Kn_Minus := S;
               end if;
            end if;
         end;
      elsif Key = "train.data_state" then
         null;   -- the functions of EFS compute regardless
      elsif Key = "tiu.active" then
         declare
            B : constant Brake_Name_T := Brake_Of (A3, Ok);
         begin
            if Ok then
               St.Active (B) := Bool_Of (Word (L, 4));
            end if;
         end;
      elsif Key = "tiu.additional" then
         St.Additional := Bool_Of (A3);
      elsif Key = "config.additional_brake_allowed" then
         St.Additional_Allowed := Bool_Of (A3);
      elsif Key = "nv" then
         if A3 = "defaults" then
            St.NV := EVC_National_Values.Default_Values;
            St.Kr := (Count => 0, S => (others => <>));
            St.Kv_Freight := (Count => 0, S => (others => <>));
            St.Kv_Passenger := (Count => 0, S => (others => <>));
            St.A_NVP12 := 0.0;
            St.A_NVP23 := 0.0;
         elsif A3 = "Kr_int" then
            Read_NV_Set (L, 4, False, St.Kr);
         elsif A3 = "Kv_int_freight" then
            Read_NV_Set (L, 4, False, St.Kv_Freight);
         elsif A3 = "Kv_int_passenger" then
            Read_NV_Set (L, 4, True, St.Kv_Passenger);
         elsif A3 = "data_state" or else A3 = "countries"
           or else A3 = "start" or else A3 = "stop"
         then
            null;   -- where and whether they apply: EFS sets them valid
         else
            NV_Scalar (A3, Word (L, 4));
         end if;
      elsif Key = "track_conditions" then
         Read_Areas (L, 'c', St.Conditions);
      elsif Key = "gradients" then
         Read_Areas (L, 'g', St.Gradients);
      elsif Key = "adhesion" then
         Read_Areas (L, 'a', St.Adhesion);
      elsif Key = "adhesion.driver_slippery" then
         St.Driver_Slippery := Bool_Of (A3);
      elsif Key = "tsrs" then
         Taint (Track) := Taint (Track) or else L.Count > 2;
      elsif Key = "odo.speed" then
         St.Speed := To_Real (A3);
      elsif Key = "odo.accel" then
         St.Accel := To_Real (A3);
      elsif Key = "odo.position" then
         St.Odo_Position := To_Real (A3);
      elsif Key = "odo.accuracy" then
         for I in 3 .. L.Count loop
            declare
               W : constant String := Word (L, I);
               F : constant String := Field (W, 1);
               V : constant Real := To_Real (Field (W, 2));
            begin
               if F = "D_ura" then
                  St.D_Ura := V;
               elsif F = "D_ora" then
                  St.D_Ora := V;
               elsif F = "V_ura" then
                  St.V_Ura := V;
               elsif F = "V_ora" then
                  St.V_Ora := V;
               end if;
            end;
         end loop;
      elsif Key = "ma.target_speed" then
         St.Target_Speed := To_Real (A3);
      else
         --  a key this runner does not know: its expectations may read
         --  it
         Valid := False;
      end if;
      if not Valid then
         Taint := (others => True);
         if Verbose then
            Put_Line ("  taint (not understood): " & L.Text);
         end if;
      end if;
   end Do_Set;

   ---------------------------------------------------------------------
   --  The state as ours
   ---------------------------------------------------------------------

   --  A model of EFS as a Decel_Curve_T (mm/s²): step k ends where step
   --  k + 1 of EFS starts
   function Curve_Of (S : EFS_Steps; Scale : Real := 1000.0)
     return Decel_Curve_T
   is
      R : Decel_Curve_T;
   begin
      for K in S'Range loop
         exit when S (K).Speed = Inf or else R.Count = Max_Curve_Steps;
         R.Count := R.Count + 1;
         R.Steps (R.Count) :=
           (Speed => Speed_Cms_T
                       (if K < S'Last and then S (K + 1).Speed /= Inf
                        then Cms (S (K + 1).Speed) else 0),
            Decel => Decel_Mms2_T (Round (S (K).Value * Scale, 0, 30_000)));
      end loop;
      return R;
   end Curve_Of;

   function Special (B : Brake_Name_T) return Special_Brake_T is
     (case B is
         when Regenerative  => EVC_Supervision_Input.Regenerative,
         when Eddy_Current  => EVC_Supervision_Input.Eddy_Current,
         when Magnetic_Shoe => EVC_Supervision_Input.Magnetic_Shoe,
         when Ep            => Electro_Pneumatic);

   function Active_Brakes return Brakes_T is
      R : Brakes_T;
   begin
      for B in Brake_Name_T loop
         R (Special (B)) := St.Active (B);
      end loop;
      return R;
   end Active_Brakes;

   --  EFS ContributionOfSpecialBrakeIsTakenIntoAccount: the additional
   --  brakes active and a special brake active (SUBSET-034 2.3.7, the
   --  status ours reads)
   function Additional return Boolean is
     (St.Additional and then (for some B in Brake_Name_T => St.Active (B)));

   --  An NV set of EFS as a Kv / Kr set of ours: the value k of EFS
   --  applies above the upper bound k - 1
   function Kv_Set (S : NV_Set; B : Boolean) return Kv_Set_T is
      R : Kv_Set_T;
   begin
      for K in 0 .. S.Count - 1 loop
         exit when R.Count = Max_Kv_Steps;
         if K > 0 and then S.S (K - 1).Upper = Inf then
            exit;
         end if;
         R.Count := R.Count + 1;
         R.Steps (R.Count) :=
           (Speed  => Speed_Cms_T (if K = 0 then 0
                                   else Cms (S.S (K - 1).Upper)),
            Factor => Milli (if B then S.S (K).B else S.S (K).A));
      end loop;
      return R;
   end Kv_Set;

   function Kr_Set (S : NV_Set) return Kr_Set_T is
      R : Kr_Set_T;
   begin
      for K in 0 .. S.Count - 1 loop
         exit when R.Count = Max_Kv_Steps;
         if K > 0 and then S.S (K - 1).Upper = Inf then
            exit;
         end if;
         R.Count := R.Count + 1;
         R.Steps (R.Count) :=
           (Length => (if K = 0 then 0
                       else Length_T (Round (S.S (K - 1).Upper * 100.0, 0,
                                             Max_Cm))),
            Factor => Milli (S.S (K).A));
      end loop;
      return R;
   end Kr_Set;

   function Cm_Of (M : Real) return Dist_T is
     (Dist_T (Round (M * 100.0, -Max_Cm, Max_Cm)));

   type Options_R is record
      Kdry_One, Kwet_One : Boolean := False;   -- the factors 1.00
      Kdry_Comb          : Brake_Combination_T := 0;
   end record;

   Sn : Snapshot_T;

   procedure Make_Snapshot (O : Options_R) is
      T : Train_Data_T renames Sn.Train_Data;
      X : Train_Data_Extra_T renames Sn.Extra.Train;
      C : Onboard_Config_T renames Sn.Extra.Config;
   begin
      Sn := (others => <>);
      T.Length := Length_T (Round (St.Length * 100.0, 0, 150_000));
      T.Max_Speed := Speed_Cms_T (Cms (St.V_Max));
      T.Model := (if St.EB_Empty then Lambda else Gamma);
      T.Brake_Percentage :=
        (if St.Lambda < 0.0 or else St.Lambda > 250.0 then 0
         else Natural (Round (St.Lambda, 0, 250)));
      T.Brake_Position := St.Position;
      X.By_Combination := True;
      for K in Brake_Combination_T loop
         X.A_Emergency_Combination (K) := Curve_Of (St.EB (K));
         X.A_Service_Combination (K) := Curve_Of (St.SB (K));
      end loop;
      T.A_Brake_Emergency := X.A_Emergency_Combination (0);
      T.A_Brake_Service := X.A_Service_Combination (0);
      for K in Combination_T loop
         X.T_Emergency_Combination (K) :=
           (React => 0, Build_Up => Time_Ms_T (Round (St.T_EB (K) * 1000.0,
                                                      0, 3_600_000)));
         X.T_Service_Combination (K) :=
           (React => 0, Build_Up => Time_Ms_T (Round (St.T_SB (K) * 1000.0,
                                                      0, 3_600_000)));
      end loop;
      T.T_Brake_Emergency := X.T_Emergency_Combination (0).Build_Up;
      T.T_Brake_Service := X.T_Service_Combination (0).Build_Up;
      for EBCL in 0 .. 9 loop
         for K in 0 .. 6 loop
            X.Kdry_Rst (EBCL) (K + 1) :=
              (if O.Kdry_One then 1_000
               else Milli (St.Kdry (O.Kdry_Comb, EBCL) (K)));
         end loop;
      end loop;
      for K in 0 .. 6 loop
         X.Kwet_Rst (K + 1) :=
           (if O.Kwet_One then 1_000 else Milli (St.Kwet (O.Kdry_Comb) (K)));
      end loop;
      --  3.13.2.2.3.1.9, .10: the normal service sets
      if not St.NSB_Empty then
         for K in 0 .. 2 loop
            X.Normal_Service_P (K) := Curve_Of (St.NSB (True, K));
            X.Normal_Service_G (K) := Curve_Of (St.NSB (False, K));
         end loop;
      end if;
      X.A_SB01 := Decel_Mms2_T (Round (St.A_SB01 * 1000.0, 0, 30_000));
      X.A_SB12 := Decel_Mms2_T (Round (St.A_SB12 * 1000.0, 0, 30_000));
      X.Kn_Plus := Curve_Of (St.Kn_Plus);
      X.Kn_Minus := Curve_Of (St.Kn_Minus);
      X.M_Rotating_Nom :=
        (if St.M_Rotating < 0.0 or else St.M_Rotating > 100.0 then 0
         else Natural (Round (St.M_Rotating, 0, 100)));
      --  the special brakes (Table 3)
      T.Has_Regenerative := St.Iface (Regenerative) /= None;
      T.Has_Eddy_Current := St.Iface (Eddy_Current) /= None;
      T.Has_Magnetic_Shoe := St.Iface (Magnetic_Shoe) /= None;
      T.Has_Electro_Pneumatic := St.Iface (Ep) /= None;
      for B in Brake_Name_T loop
         C.Special_Brakes (Special (B)) :=
           (case St.Iface (B) is
               when None => No_Interface,
               when EB   => Emergency_Only,
               when SB   => Service_Only,
               when Both => Emergency_And_Service);
      end loop;
      C.Service_Brake_Command := St.SB_Command;
      C.Service_Brake_Feedback := St.SB_Feedback;
      C.Traction_Cut_Off := St.TCO;
      C.Additional_Brake_Allowed := St.Additional_Allowed;
      T.T_Traction_Cut_Off :=
        Time_Ms_T (Round ((St.Traction_Coef * St.Accel + St.Traction_Const)
                          * 1000.0, 0, 3_600_000));
      --  national values
      Sn.National := St.NV;
      if St.Kr.Count > 0 then
         Sn.National.Kr_Int := Kr_Set (St.Kr);
      end if;
      if St.Kv_Freight.Count > 0 then
         Sn.National.Kv_Int_Fresh := Kv_Set (St.Kv_Freight, False);
      end if;
      if St.Kv_Passenger.Count > 0 then
         Sn.National.Kv_Int_Passenger := Kv_Set (St.Kv_Passenger, False);
         Sn.National.Kv_Int_Passenger_B := Kv_Set (St.Kv_Passenger, True);
      end if;
      Sn.National.A_NVP12 :=
        Decel_Mms2_T (Round (St.A_NVP12 * 1000.0, 0, 30_000));
      Sn.National.A_NVP23 :=
        Decel_Mms2_T (Round (St.A_NVP23 * 1000.0, 0, 30_000));
      --  the track: the frame of EFS, ahead = Plus
      Sn.Train.Ahead := Plus;
      Sn.Train.Position_Valid := True;
      Sn.Train.Est_Front := Cm_Of (St.Odo_Position);
      Sn.Train.Max_Safe_Front := Sn.Train.Est_Front;
      Sn.Train.Min_Safe_Front := Sn.Train.Est_Front;
      Sn.Train.Speed := Speed_Cms_T (Cms (St.Speed));
      for I in 1 .. St.Conditions.Count loop
         declare
            A : Area_R renames St.Conditions.A (I);
         begin
            if A.Kind /= TC_Other
              and then Sn.Inhibitions.Count < Max_Inhibition_Areas
            then
               Sn.Inhibitions.Count := Sn.Inhibitions.Count + 1;
               Sn.Inhibitions.Areas (Sn.Inhibitions.Count) :=
                 (Kind   => (case A.Kind is
                                when TC_Regenerative => Regenerative_Inhibited,
                                when TC_Eddy_SB =>
                                   Eddy_Current_Service_Inhibited,
                                when TC_Eddy_EB =>
                                   Eddy_Current_Emergency_Inhibited,
                                when TC_Magnetic => Magnetic_Shoe_Inhibited,
                                when others => Powerless_Section),
                  Start  => Cm_Of (A.From),
                  Finish => Cm_Of (A.From + A.Length));
            end if;
         end;
      end loop;
      for I in 1 .. St.Gradients.Count loop
         declare
            A : Area_R renames St.Gradients.A (I);
            G : Gradient_Profile_T renames Sn.Gradients;
         begin
            if G.Count < Max_Gradient_Segments then
               G.Count := G.Count + 1;
               G.Segments (G.Count) :=
                 (Start    => Cm_Of (A.From),
                  Gradient => (if A.Indefinite then 0
                               else Gradient_T (Round (A.Value, -255, 255))));
               G.Covered (G.Count) := not A.Indefinite;
            end if;
         end;
      end loop;
      for I in 1 .. St.Adhesion.Count loop
         declare
            A : Area_R renames St.Adhesion.A (I);
         begin
            --  M_ADHESION 0: slippery rail
            if A.Value = 0.0 and then Sn.Adhesion.Count < Max_Adhesion_Areas
            then
               Sn.Adhesion.Count := Sn.Adhesion.Count + 1;
               Sn.Adhesion.Areas (Sn.Adhesion.Count) :=
                 (Cm_Of (A.From), Cm_Of (A.From + A.Length));
            end if;
         end;
      end loop;
      Sn.Adhesion.Driver_Slippery := St.Driver_Slippery;
   end Make_Snapshot;

   Model : Model_T;
   P     : EVC_Profile.Profile_T;

   procedure Build (O : Options_R) is
   begin
      Make_Snapshot (O);
      EVC_Braking.Build (Sn, Active_Brakes, Additional, Model);
   end Build;

   No_Inhibitions : constant Inhibitions_T := (others => False);

   --  The combination of special brakes in use without inhibitions
   function Combination_In_Use return Brake_Combination_T is
      O : Options_R;
   begin
      O.Kdry_One := True;
      O.Kwet_One := True;
      Build (O);
      return Emergency_Combination (Model, No_Inhibitions);
   end Combination_In_Use;

   --  Built with the factors of EFS for the combination in use
   procedure Build_Safe is
      O : Options_R;
   begin
      O.Kdry_Comb := Combination_In_Use;
      Build (O);
   end Build_Safe;

   --  The inhibitions at d (m), through the profile
   function Inhibited_At (D : Real) return Inhibitions_T is
   begin
      EVC_Profile.Build (Sn, Model, -Max_Cm / 2, P);
      return P.Points (EVC_Profile.Segment_Of (P, Cm_Of (D))).Inhibited;
   end Inhibited_At;

   ---------------------------------------------------------------------
   --  Expectations
   ---------------------------------------------------------------------

   type Side_T is (Lower_Safe, Higher_Safe, Either, Exact);
   type Result_T is record
      Known  : Boolean := False;   -- ours computed
      Ours   : Real := 0.0;        -- in our unit
      Scale  : Real := 1.0;        -- our unit per unit of EFS
      Side   : Side_T := Exact;
      Why    : String (1 .. 60) := (others => ' ');
   end record;

   function Not_Run (Why : String) return Result_T is
      R : Result_T;
      N : constant Natural := Natural'Min (Why'Length, 60);
   begin
      R.Why (1 .. N) := Why (Why'First .. Why'First + N - 1);
      return R;
   end Not_Run;

   function Got (Ours : Num; Scale : Real; Side : Side_T) return Result_T is
      R : Result_T;
   begin
      R.Known := True;
      R.Ours := Real (Ours);
      R.Scale := Scale;
      R.Side := Side;
      return R;
   end Got;

   Decel_Scale : constant Real := 100_000.0;   -- Decel_Unit per m/s²

   function Needs (A : Area_Name) return Boolean is (Taint (A));

   --  The speed a step function is evaluated at is moved by this many
   --  cm/s to tell a failure at a step boundary (Check)
   Speed_Offset : Num range 0 .. 1 := 0;

   --  The value of a step function at V km/h
   function At_Speed (S : Steps_T; V : Real) return Num is
     (Value_At (S, Min (Cms (V) + Speed_Offset, Max_Speed)));

   --  (d) the terms of the EBI of a target (EVC_Limits.Bec), with the
   --  inputs of ours as EVC_SDM gives them: V_delta0 the under-reading
   --  amount of the speed unless inhibited (3.13.9.3.2.1), A_est1 the
   --  acceleration, not below 0, A_est2 the same up to 0.4 m/s²
   --  (3.13.9.3.2.8, .9), T_be of the target (3.4.0 has no reduced time),
   --  T_bs2 the service brake time when the service brake is used
   --  (3.13.9.3.3.3); Vest / Vtarget as given, else the estimated speed
   --  and the target speed of the expectation
   function Target_Term (F : String; V1, V2 : Real) return Result_T is
      With_V : constant Boolean := F = "Vbec" or else F = "Dbec";
      V_Est  : constant Real := (if With_V then V1 else St.Speed);
      V_Tgt  : constant Real := (if With_V then V2 else V1);
      Terms  : EVC_Limits.Terms_T;
      A1     : constant Num := Round (St.Accel * 1000.0, 0, 30_000);
   begin
      if F = "Vdelta0" or else F = "Aest1" or else F = "Aest2" then
         return Not_Run ("computed inside EVC_SDM / an input of ours");
      end if;
      Build_Safe;
      if not Model.Valid then
         return Not_Run ("no emergency brake model");
      end if;
      declare
         Zero : constant Boolean := V_Tgt = 0.0;
         E    : constant Times_T :=
           (if Zero then Model.Emergency_Zero else Model.Emergency_Target);
         S    : constant Times_T :=
           (if Zero then Model.Service_Zero else Model.Service_Target);
      begin
         Terms.V := Cms (V_Est);
         Terms.V_Delta0 :=
           (if Sn.National.Q_NVINHSMICPERM then 0
            else Round (St.V_Ura * 250.0 / 9.0 + 0.4999, 0, Max_Speed));
         Terms.A_Est1 := A1;
         Terms.A_Est2 := Min (A1, 400);
         Terms.T_Be := E.Build_Up;
         Terms.T_Bs2 :=
           (if Sn.Extra.Config.Service_Brake_Command
              and then Sn.National.Q_NVSBTSMPERM
            then S.Build_Up else 0);
         Terms.T_Bs1 := Terms.T_Bs2;
         Terms.TCO := Sn.Extra.Config.Traction_Cut_Off;
         Terms.T_Traction_Cut_Off :=
           Time_T (Sn.Train_Data.T_Traction_Cut_Off);
      end;
      declare
         B : constant EVC_Limits.Bec_T :=
           EVC_Limits.Bec (Terms, Cms (V_Tgt));
      begin
         if F = "T_traction" then
            return Got (B.T_Traction, 1000.0, Higher_Safe);
         elsif F = "T_berem" then
            return Got (B.T_Berem, 1000.0, Higher_Safe);
         --  V_delta1 and V_delta2 of EFS are m/s (A_est times a time,
         --  not converted into km/h like its other speeds)
         elsif F = "Vdelta1" then
            return Got (B.V_Delta1, 100.0, Higher_Safe);
         elsif F = "Vdelta2" then
            return Got (B.V_Delta2, 100.0, Higher_Safe);
         elsif F = "Vbec" then
            return Got (B.V_Bec, 250.0 / 9.0, Higher_Safe);
         else
            return Got (B.D_Bec, 100.0, Higher_Safe);
         end if;
      end;
   end Target_Term;

   --  An argument: a number, or a name (0.0, Valid kept)
   function Arg (S : String) return Real is
     (if S'Length > 0 and then S (S'First) in '0' .. '9' | '-' | '.'
      then To_Real (S) else 0.0);

   function Evaluate (L : Line_T; Last : Natural) return Result_T is
      F  : constant String := Word (L, 2);
      A1 : constant String := (if Last >= 3 then Word (L, 3) else "");
      A2 : constant String := (if Last >= 4 then Word (L, 4) else "");
      V1 : constant Real := Arg (A1);
      V2 : constant Real := Arg (A2);
   begin
      if not Valid then
         return Not_Run ("invalid arguments");
      end if;

      --  (a) the ceiling margins
      if F = "dV_warning" or else F = "dV_sbi" or else F = "dV_ebi" then
         return Got (EVC_Limits.Margin
                       ((if F = "dV_warning" then EVC_Limits.Warning
                         elsif F = "dV_sbi" then EVC_Limits.SBI
                         else EVC_Limits.EBI), Cms (V1)),
                     250.0 / 9.0, Lower_Safe);
      end if;

      --  (b) the braking models
      if F = "braking_model" or else F = "brake_used" then
         if Needs (Train) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         declare
            O : Options_R;
         begin
            O.Kdry_One := True;
            O.Kwet_One := True;
            Build (O);
         end;
         if F = "brake_used" then
            declare
               Ok : Boolean;
               B  : constant Brake_Name_T := Brake_Of (A2, Ok);
            begin
               if not Ok then
                  return Not_Run ("invalid arguments");
               end if;
               return Got ((if (if A1 = "eb"
                                then Model.Emergency_Brakes (Special (B))
                                else Model.Service_Brakes (Special (B)))
                            then 1 else 0), 1.0, Exact);
            end;
         end if;
         declare
            C : constant Brake_Combination_T :=
              (if A1 = "eb" then Emergency_Combination (Model, No_Inhibitions)
               else Service_Combination (Model, No_Inhibitions));
            S : constant Steps_T :=
              (if A1 = "eb" then Model.Emergency_Safe (C)
               elsif A1 = "sb" then Model.Service (C)
               else Model.Normal_Service (C));
         begin
            return Got (At_Speed (S, V2), Decel_Scale, Lower_Safe);
         end;
      end if;

      if F = "A_brake_emergency" or else F = "A_brake_service"
        or else F = "A_brake_normal_service" or else F = "A_brake_safe"
      then
         if Needs (Train) or else Needs (Track)
           or else (F = "A_brake_safe" and then Needs (NV))
         then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         if F = "A_brake_safe" then
            Build_Safe;
         else
            declare
               O : Options_R;
            begin
               O.Kdry_One := True;
               O.Kwet_One := True;
               Build (O);
            end;
         end if;
         if not Model.Valid then
            return Not_Run ("no emergency brake model");
         end if;
         declare
            I : constant Inhibitions_T := Inhibited_At (V2);
            S : constant Steps_T :=
              (if F = "A_brake_emergency" or else F = "A_brake_safe"
               then Model.Emergency_Safe (Emergency_Combination (Model, I))
               elsif F = "A_brake_service"
               then Model.Service (Service_Combination (Model, I))
               else Model.Normal_Service (Service_Combination (Model, I)));
         begin
            return Got (At_Speed (S, V1), Decel_Scale, Lower_Safe);
         end;
      end if;

      --  the deceleration of the EBD (A_safe), SBD (A_expected), GUI
      --  (A_normal_service) at d, with the gradient and the reduced
      --  adhesion (EVC_Curves.Deceleration), for a target not due to a
      --  TSR
      if F = "A_safe" or else F = "A_expected"
        or else F = "A_normal_service"
      then
         if Needs (Train) or else Needs (Track) or else Needs (NV) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         Build_Safe;
         if not Model.Valid then
            return Not_Run ("no emergency brake model");
         end if;
         EVC_Profile.Build (Sn, Model, -Max_Cm / 2, P);
         declare
            V : constant Speed_T := Min (Cms (V1) + Speed_Offset, Max_Speed);
         begin
            return Got (EVC_Curves.Deceleration
                          (Model, P,
                           (if F = "A_safe" then EVC_Curves.EBD
                            elsif F = "A_expected" then EVC_Curves.SBD
                            else EVC_Curves.GUI),
                           False, EVC_Profile.Segment_Of (P, Cm_Of (V2)),
                           V * V, False).A,
                        Decel_Scale, Lower_Safe);
         end;
      end if;

      if F = "Kdry_rst" or else F = "Kwet_rst" then
         if Needs (Train) or else Needs (NV) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         --  A_brake_safe / A_brake_emergency with the other factor 1.00
         --  (and M_NVAVADH 0 for Kwet_rst): the factor of the step at V
         declare
            O    : Options_R;
            Comb : constant Brake_Combination_T := Combination_In_Use;
            Raw  : Num;
         begin
            O.Kdry_One := True;
            O.Kwet_One := True;
            Build (O);
            if not Model.Valid or else Model.Conversion then
               return Not_Run ("no braking model");
            end if;
            Raw := At_Speed (Model.Emergency_Safe (Comb), V1);
            O.Kdry_Comb := Comb;
            O.Kdry_One := F = "Kwet_rst";
            O.Kwet_One := F = "Kdry_rst";
            Make_Snapshot (O);
            if F = "Kwet_rst" then
               Sn.National.M_NVAVADH := 0;
            end if;
            EVC_Braking.Build (Sn, Active_Brakes, Additional, Model);
            if Raw <= 0 then
               return Not_Run ("zero deceleration");
            end if;
            return
              (Known => True,
               Ours  => Real (At_Speed (Model.Emergency_Safe (Comb), V1))
                        / Real (Raw) * 1000.0,
               Scale => 1000.0, Side => Lower_Safe, Why => (others => ' '));
         end;
      end if;

      if F = "Kv_int" or else F = "Kr_int" or else F = "A_ebmax" then
         if Needs (Train) or else Needs (NV) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         Build_Safe;
         --  3.13.6.2.1.8: Kv_int and A_ebmax are those of the conversion
         --  model: the basic deceleration of the brake percentage when
         --  one is given (EFS A_ebmax, whatever the braking models)
         declare
            Emergency : constant Steps_T :=
              (if St.Lambda in 0.0 .. 250.0
               then Basic_Deceleration (Sn.Train_Data.Brake_Percentage)
               else Model.Emergency_Safe
                      (Emergency_Combination (Model, No_Inhibitions)));
            Ebmax : constant Value_T :=
              A_Ebmax (Emergency, Speed_T (Sn.Train_Data.Max_Speed));
         begin
            if F = "A_ebmax" then
               return Got (Ebmax, Decel_Scale, Lower_Safe);
            elsif F = "Kr_int" then
               return Got (Kr_Int (Sn.National.Kr_Int,
                                   Round (V1 * 100.0, 0, 150_000)),
                           1_000_000.0, Lower_Safe);
            else
               return Got (At_Speed (Kv_Int (Sn.National,
                                             Sn.Train_Data.Brake_Position,
                                             Ebmax), V1),
                           1_000_000.0, Lower_Safe);
            end if;
         end;
      end if;

      if F = "A_MAXREDADH" then
         if Needs (Train) or else Needs (NV) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         Build_Safe;
         if Model.Redadh_Use /= Limit then
            return Not_Run ("A_NVMAXREDADH without a limit");
         end if;
         return Got (Model.Redadh, Decel_Scale, Lower_Safe);
      end if;

      if F = "conversion_used" then
         if Needs (Train) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         Make_Snapshot ((others => <>));
         Sn.Train_Data.Model := Lambda;
         if St.Lambda < 0.0 then
            Sn.Train_Data.Brake_Percentage := 0;
         end if;
         return Got ((if Conversion_Applicable (Sn.Train_Data) then 1 else 0),
                     1.0, Exact);
      end if;

      if F = "cm_A_brake_emergency" or else F = "cm_A_brake_service"
        or else F = "cm_eb_step" or else F = "cm_sb_step"
      then
         if Needs (Train) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         if St.Lambda < 0.0 or else St.Lambda > 250.0 then
            return Not_Run ("no brake percentage");
         end if;
         declare
            EB     : constant Boolean :=
              F = "cm_A_brake_emergency" or else F = "cm_eb_step";
            Lambda : constant Lambda_T :=
              Lambda_T (Round (St.Lambda, 0, (if EB then 250 else 135)));
            S      : constant Steps_T := Basic_Deceleration (Lambda);
         begin
            if F = "cm_A_brake_emergency" or else F = "cm_A_brake_service" then
               return Got (At_Speed (S, V1), Decel_Scale, Lower_Safe);
            end if;
            --  step K of EFS (lower bounds from 0) is step K + 1 of ours;
            --  its SpeedStep the upper bound of our step K
            declare
               K : constant Natural := Comb_Of (A1, 6);
            begin
               if not Valid or else S.Count = 0 then
                  return Not_Run ("invalid arguments");
               end if;
               if A2 = "speed" then
                  if K = 0 then
                     return Got (0, 250.0 / 9.0, Either);
                  elsif K >= S.Count then
                     return (Known => True, Ours => Inf, Scale => 1.0,
                             Side => Exact, Why => (others => ' '));
                  end if;
                  return Got (S.Steps (K).Upper, 250.0 / 9.0, Either);
               end if;
               return Got (S.Steps (Natural'Min (K + 1, S.Count)).Value,
                           Decel_Scale, Lower_Safe);
            end;
         end;
      end if;

      if F = "T_brake_emergency_cm0" or else F = "T_brake_emergency_cmt"
        or else F = "T_brake_service_cm0" or else F = "T_brake_service_cmt"
      then
         if Needs (Train) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         declare
            Length : constant Num := Round (St.Length * 100.0, 0, 150_000);
            Zero   : constant Boolean :=
              F (F'Last - 2 .. F'Last) = "cm0";
            T      : constant Times_T :=
              (if F'Length > 10
                 and then F (F'First .. F'First + 9) = "T_brake_em"
               then Conversion_Emergency (St.Position, Length, Zero)
               else Conversion_Service (St.Position, Length, Zero));
         begin
            return Got (T.Build_Up, 1000.0, Higher_Safe);
         end;
      end if;

      if F = "T_be" or else F = "T_bs" or else F = "T_brake_emergency"
        or else F = "T_brake_service"
      then
         if Needs (Train) or else Needs (NV) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         Build_Safe;
         if (F = "T_brake_emergency" or else F = "T_brake_service")
           and then Model.Conversion
         then
            return Not_Run ("conversion model");
         end if;
         declare
            Zero : constant Boolean :=
              (F = "T_be" or else F = "T_bs") and then V1 = 0.0;
            T    : constant Times_T :=
              (if F = "T_be" or else F = "T_brake_emergency"
               then (if Zero then Model.Emergency_Zero
                     else Model.Emergency_Target)
               else (if Zero then Model.Service_Zero
                     else Model.Service_Target));
         begin
            return Got (T.Build_Up, 1000.0, Higher_Safe);
         end;
      end if;

      if F = "Kn_plus" or else F = "Kn_minus" then
         if Needs (Train) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         Build_Safe;
         return Got (At_Speed ((if F = "Kn_plus" then Model.Kn_Plus
                                else Model.Kn_Minus), V1),
                     Decel_Scale, Either);
      end if;

      if F = "A_gradient" then
         if Needs (Train) or else Needs (Track) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         Build_Safe;
         EVC_Profile.Build (Sn, Model, -Max_Cm / 2, P);
         return Got (P.Points (EVC_Profile.Segment_Of (P, Cm_Of (V1)))
                       .A_Gradient, Decel_Scale, Lower_Safe);
      end if;

      --  (d) the target terms
      if F = "T_traction" or else F = "T_berem" or else F = "Vdelta0"
        or else F = "Vdelta1" or else F = "Vdelta2" or else F = "Aest1"
        or else F = "Aest2" or else F = "Vbec" or else F = "Dbec"
      then
         if Needs (Train) or else Needs (NV) or else Needs (Odo) then
            return Not_Run ("after an untranslated action or a telegram");
         end if;
         return Target_Term (F, V1, V2);
      end if;

      if F = "ceiling_P" or else F = "SSP" or else F = "TSR"
        or else F = "MRSP"
      then
         return Not_Run ("SSP / TSR / MRSP: stored information (c)");
      end if;
      if F = "T_bs1" or else F = "T_bs2" or else F = "T_warning"
        or else F = "T_traction_cut_off"
      then
         return Not_Run ("computed inside EVC_SDM / an input of ours");
      end if;
      return Not_Run ("no counterpart: " & F);
   end Evaluate;

   ---------------------------------------------------------------------
   --  Checking an expectation
   ---------------------------------------------------------------------

   Pending_Xfail : Boolean := False;

   function Image (X : Real) return String is
      S : constant String := Real'Image (X);
   begin
      return Ada.Strings.Fixed.Trim (S, Ada.Strings.Both);
   end Image;

   function Value_Of (S : String) return Real is
   begin
      if S = "true" then
         return 1.0;
      elsif S = "false" then
         return 0.0;
      end if;
      return To_Real (S);
   end Value_Of;

   --  The comparison rule (see the header): our value O against the value
   --  E1 (and E2 for "in") of EFS in its unit
   function Passes (R : Result_T; O : Real; Op : String; E1, E2 : Real)
     return Boolean
   is
      Lo  : constant Real := (if E1 = Inf then Inf else E1 * R.Scale);
      Hi  : constant Real := (if E2 = Inf then Inf else E2 * R.Scale);
      Eps : constant Real :=
        (if E1 = Inf then 0.0 else 1.0E-6 * Real'Max (1.0, abs Lo));
   begin
      if E1 = Inf or else O = Inf then
         return Op = "==" and then E1 = Inf and then O = Inf;
      elsif Op = "==" then
         case R.Side is
            when Lower_Safe =>
               return O <= Lo + Eps and then O >= Lo - 1.0 - Eps;
            when Higher_Safe =>
               return O >= Lo - Eps and then O <= Lo + 1.0 + Eps;
            when Either =>
               return abs (O - Lo) <= 1.0 + Eps;
            when Exact =>
               return abs (O - Lo) <= Eps;
         end case;
      elsif Op = ">" or else Op = ">=" then
         return O >= Lo - 1.0 - Eps;
      elsif Op = "<" or else Op = "<=" then
         return O <= Lo + 1.0 + Eps;
      else
         return O >= Lo - 1.0 - Eps and then O <= Hi + 1.0 + Eps;
      end if;
   end Passes;

   procedure Check (L : Line_T) is
      Op_At : Natural := 0;
      Xfail : constant Boolean := Pending_Xfail;
   begin
      Pending_Xfail := False;
      if Word (L, 2) = "efs:" then
         Skip ("verbatim (not translated)");
         return;
      end if;
      for I in 3 .. L.Count loop
         declare
            W : constant String := Word (L, I);
         begin
            if W = "==" or else W = "<" or else W = ">" or else W = "<="
              or else W = ">=" or else W = "in"
            then
               Op_At := I;
               exit;
            end if;
         end;
      end loop;
      if Op_At = 0 or else Op_At = L.Count then
         Skip ("invalid expect line");
         return;
      end if;
      Valid := True;
      declare
         Op  : constant String := Word (L, Op_At);
         E1  : constant Real := Value_Of (Word (L, Op_At + 1));
         E2  : constant Real :=
           (if Op = "in" then Value_Of (Word (L, Op_At + 2)) else 0.0);
      begin
         if not Valid then
            Skip ("invalid expect line");
            return;
         end if;
         declare
            R    : constant Result_T := Evaluate (L, Op_At - 1);
            Pass : Boolean;
            O    : Real;
         begin
            if not R.Known then
               Skip (Ada.Strings.Fixed.Trim (R.Why, Ada.Strings.Right));
               return;
            end if;
            O := R.Ours;
            Pass := Passes (R, O, Op, E1, E2);
            Frame.Checks := Frame.Checks + 1;
            if Pass and then not Xfail then
               if Verbose then
                  Put_Line ("  ok   " & Rest (L, 2));
               end if;
            elsif not Pass and then Xfail then
               Frame.Xfails := Frame.Xfails + 1;
               if Verbose then
                  Put_Line ("  xfail " & Rest (L, 2) & "  ours "
                            & Image (O / R.Scale));
               end if;
            else
               Frame.Failures := Frame.Failures + 1;
               Put_Line ("FAIL " & Frame_Name (1 .. Frame_Len) & " | "
                         & Where (1 .. Where_Len));
               Put_Line ("     " & Rest (L, 2) & "  ours "
                         & (if O = Inf then "inf" else Image (O / R.Scale))
                         & (if Xfail then "  (xfail: passes now)" else ""));
               --  a step function one cm/s above the speed: passes there
               --  when the speed is a step boundary
               if not Pass then
                  Speed_Offset := 1;
                  declare
                     R2 : constant Result_T := Evaluate (L, Op_At - 1);
                  begin
                     Speed_Offset := 0;
                     if R2.Known and then R2.Ours /= O
                       and then Passes (R2, R2.Ours, Op, E1, E2)
                     then
                        Put_Line ("     (1 cm/s above the speed ours is "
                                  & Image (R2.Ours / R2.Scale)
                                  & ": the speed is a step boundary)");
                     end if;
                  end;
               end if;
            end if;
         end;
      end;
   end Check;
   ---------------------------------------------------------------------
   --  A scenario file
   ---------------------------------------------------------------------

   Case_Name : String (1 .. 80) := (others => ' ');
   Case_Len  : Natural := 0;

   procedure On_Line (L : Line_T; Line_No : Positive) is
      pragma Unreferenced (Line_No);
   begin
      declare
         K : constant String := Word (L, 1);
      begin
         if K = "frame" then
            declare
               N : constant String := Rest (L, 2);
               M : constant Natural := Natural'Min (N'Length, 80);
            begin
               Frame_Name (1 .. M) := N (N'First .. N'First + M - 1);
               Frame_Len := M;
            end;
         elsif K = "case" then
            declare
               N : constant String := Rest (L, 2);
               M : constant Natural := Natural'Min (N'Length, 80);
            begin
               Case_Name (1 .. M) := N (N'First .. N'First + M - 1);
               Case_Len := M;
            end;
         elsif K = "step" then
            Set_Where (Case_Name (1 .. Case_Len) & " | " & Rest (L, 2));
         elsif K = "init" then
            St := (others => <>);
            St.NV := EVC_National_Values.Default_Values;
            Valid := True;
            St.Odo_Position := To_Real (Word (L, 2));
            Taint := (others => not Valid);
            Initialised := True;
         elsif K = "set" then
            Do_Set (L);
         elsif K = "telegram" then
            --  not executed: the stored information would change (track
            --  description, national values, MA)
            Taint (Track) := True;
            Taint (NV) := True;
            Taint (MA) := True;
         elsif K = "taint" then
            for I in 2 .. L.Count loop
               for A in Area_Name loop
                  if Ada.Characters.Handling.To_Lower (Area_Name'Image (A))
                    = Word (L, I)
                  then
                     Taint (A) := True;
                  end if;
               end loop;
            end loop;
         elsif K = "xfail" then
            Pending_Xfail := True;
         elsif K = "expect" then
            if not Initialised then
               Pending_Xfail := False;
               Skip ("before the test environment");
            else
               Check (L);
            end if;
         end if;
         --  sequence, sub, clause, call, end, efs:, comments: nothing
      end;
   exception
      when others =>
         Skip ("invalid line");
         Taint := (others => True);
   end On_Line;

   procedure Run_File (Path : String) is
      Ok : Boolean;
   begin
      Frame := (others => 0);
      Frame_Len := 0;
      Case_Len := 0;
      Where_Len := 0;
      Initialised := False;
      Pending_Xfail := False;
      Taint := (others => True);
      Scn_Reader.Read_File (Path, On_Line'Access, Ok);
      if not Ok then
         Put_Line ("evc_efs_test: " & Path & " unreadable, skipped");
         return;
      end if;
      Put_Line (Frame_Name (1 .. Frame_Len) & ":" & Frame.Checks'Image
                & " checks," & Frame.Failures'Image & " failures,"
                & Frame.Xfails'Image & " expected differences,"
                & Frame.Skipped'Image & " skipped");
      Total.Checks := Total.Checks + Frame.Checks;
      Total.Failures := Total.Failures + Frame.Failures;
      Total.Xfails := Total.Xfails + Frame.Xfails;
      Total.Skipped := Total.Skipped + Frame.Skipped;
   end Run_File;

   ---------------------------------------------------------------------
   --  Main
   ---------------------------------------------------------------------

   Dir : constant String :=
     (if Ada.Command_Line.Argument_Count >= 1
      then Ada.Command_Line.Argument (1) else "test/efs");

   Paths : Scn_Reader.Paths_T;
   Count : Natural := 0;

   use Ada.Directories;
begin
   if not Exists (Dir) or else Kind (Dir) /= Directory then
      Put_Line ("evc_efs_test: " & Dir & " absent, skipped");
      return;
   end if;
   Scn_Reader.List_Scn_Files (Dir, Recurse => False,
                              Paths => Paths, Count => Count);
   for I in 1 .. Count loop
      Run_File (Paths (I).S (1 .. Paths (I).N));
   end loop;

   --  the reasons of the skipped expectations, the most frequent first
   for I in 2 .. Max_Reasons loop
      for J in reverse 2 .. I loop
         exit when Reasons (J - 1).Count >= Reasons (J).Count;
         declare
            T : constant Reason_R := Reasons (J);
         begin
            Reasons (J) := Reasons (J - 1);
            Reasons (J - 1) := T;
         end;
      end loop;
   end loop;
   Put_Line ("skipped, by reason:");
   for R of Reasons loop
      exit when R.Count = 0;
      Put_Line ("  " & R.Count'Image & "  "
                & Ada.Strings.Fixed.Trim (R.Text, Ada.Strings.Right));
   end loop;
   Put_Line ("expected differences (xfail):" & Total.Xfails'Image);
   Put_Line ("evc_efs_test:" & Total.Checks'Image & " checks,"
             & Total.Failures'Image & " failures," & Total.Skipped'Image
             & " skipped");
   if Total.Failures > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end EVC_EFS_Test;
