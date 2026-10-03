--  ETCS on-board (EVC)
--  The speed restriction to ensure a permitted braking distance, PBD SR
--  (SUBSET-026 3.11.11): the speed V_PBD a section of packet 52 asks
--  for, from its permitted braking distance d_PBD, its gradient and the
--  brake that is to achieve it (Q_PBDSR). The store of the sections and
--  their place in the MRSP are EVC_Track_Description and
--  EVC_Stored_Information; this unit computes, with the braking model
--  and the curves of the supervision (EVC_Braking, EVC_Profile,
--  EVC_Curves, EVC_Limits), which it only calls.
--
--  The inputs (Inputs_T, 3.11.11.4): the braking model of the train
--  (Train Data, national values, the status of the special brakes on
--  the train interface), with the single gradient of the section
--  compensated for the rotating mass (3.13.4.3) and without the
--  adhesion profiles, the brake inhibitions and the powerless sections
--  given by trackside (a profile of one segment; the driver's slippery
--  rail, 3.13.5.4, is kept: it is not given by trackside); the
--  estimated acceleration zero; V_delta0 = f41 of SUBSET-041 5.3.1.2
--  unless Q_NVINHSMICPERM inhibits it; the travelled distance from the
--  balise, L_antenna-front + T41 (SUBSET-041 5.2.1.1) times the speed;
--  T_bs1 and T_bs2 as if the service brake feedback were not
--  implemented (3.13.9.3.3.3, .5), T_traction as if the traction cut-off
--  were not implemented (3.13.9.3.2.3 b). EVC_Stored_Information keeps
--  the inputs of the last computation and has every section computed
--  again when they change (3.11.11.3).
--
--  The distances d of 3.11.11.6 to .9 are counted from the balise
--  (3.11.11.5): the EBD and the SBD reach zero speed at d_PBD. For a
--  speed V (cm/s), the conditions are, with dV = dV_ebi (3.13.9.2.3) for
--  the emergency brake and dV_sbi (3.13.9.2.5) for the service brake:
--    - EB (3.11.11.6): V + dV + V_delta0 <= V_EBD (d_offset + D_bec),
--      d_offset + D_bec <= d_PBD, with D_bec = (V + dV + V_delta0)
--      (T_traction + T_berem), d_offset = L_antenna-front + T41 (V + dV
--      + V_delta0);
--    - SB, from the EBD (3.11.11.8): the same with dV_sbi and the
--      distance (V + dV) T_bs2 added to the location of V_EBD;
--    - SB, from the SBD (3.11.11.9): V + dV <= V_SBD (d_offset + (V +
--      dV) T_bs1), d_offset + (V + dV) T_bs1 <= d_PBD, with d_offset =
--      L_antenna-front + T41 (V + dV).
--  The inequality "ABS {..} <= 1 km/h" of the SRS is met at the largest
--  speed V* whose left hand side does not exceed the right hand side:
--  "the exact" V_PBD is V* rounded down to a multiple of 5 km/h (the
--  most restrictive of the EBD and the SBD ones for the service brake,
--  3.11.11.7), 0 when no speed fulfils the inequalities.
--
--  Integers and rounding. Every term is taken on the side that makes
--  the condition harder: dV is the margin of EVC_Limits (rounded down)
--  plus 1 cm/s, f41 is rounded up, the distances are rounded up, the
--  curves are the ones of EVC_Curves (never above the exact curves
--  rearwards of their anchor) and T_bs1 is T_bs (T_bs_reduced of
--  A.3.12, which 3.13.9.3.3.3 names, is never longer). A speed that
--  meets the conditions in the integers therefore meets the exact ones;
--  the conditions only get harder as V grows, so the largest speed the
--  bisection finds (Unrounded) is never above V*, and its rounding down
--  to 5 km/h (in cm/s, rounded down) never above the exact V_PBD.
--  Measured by evc_test against a floating point reference of the
--  formulas (Scenario_PBD_Precision). Cost: Iterations curve speeds per
--  condition (twice for the service brake), only when a section is
--  received or the inputs change.

with EVC_Braking;           use EVC_Braking;
with EVC_Distances;         use EVC_Distances;
with EVC_Fixed;             use EVC_Fixed;
with EVC_Profile;           use EVC_Profile;
with EVC_Supervision_Input; use EVC_Supervision_Input;

package EVC_PBD
  with SPARK_Mode => On
is

   --  SUBSET-041 5.2.1.1: the delay between the last balise of a group
   --  and the brake command (T41), ms
   T_41 : constant := 1_000;

   --  The largest speed the bisection looks at: 600 km/h, cm/s
   Top_Speed : constant := 16_667;

   --  The bisection: 2**Iterations > Top_Speed
   Iterations : constant := 15;

   --  A permitted braking distance, cm (D_PBD: 327.67 km at most)
   subtype PBD_Distance_T is Num range 0 .. 40_000_000;

   subtype Antenna_T is Num range 0 .. 100_000;

   --  What the speed restriction depends on besides the section (3.11.11.3:
   --  when one of them changes, the restrictions are computed again)
   type Inputs_T is record
      Model      : Model_T := (others => <>);
      --  3.13.5.4: slippery rail selected by the driver
      Slippery   : Boolean := False;
      --  3.13.9.3.2.1: Q_NVINHSMICPERM, V_delta0 = 0
      Inhibit    : Boolean := False;
      --  3.13.9.3.3.5: the service brake command available for use
      --  (the configuration and Q_NVSBTSMPERM, as EVC_SDM)
      SB_Avail   : Boolean := False;
      --  3.13.9.3.2.3 b): T_traction_cut_off
      T_Traction : Time_T := 0;
      --  L_antenna-front, cm
      Antenna    : Antenna_T := 0;
   end record;

   --  The inputs from the Train Data, the national values and the
   --  configuration of the snapshot S, the status of the special brakes
   --  (Active, Additional: SUBSET-034 2.3.6, 2.3.7) and the distance from
   --  the active antenna to the front end, into I (the on-board's way:
   --  an Inputs_T, 7 KB, returned by a function is built on the stack of
   --  its caller; Inputs_Of is for the tests)
   procedure Get_Inputs (S          : Snapshot_T;
                         Active     : Brakes_T;
                         Additional : Boolean;
                         Antenna    : Natural;
                         I          : out Inputs_T);
   function Inputs_Of (S          : Snapshot_T;
                       Active     : Brakes_T;
                       Additional : Boolean;
                       Antenna    : Natural) return Inputs_T;

   --  The profile of a section into P: its gradient everywhere,
   --  compensated for the rotating mass, no reduced adhesion but the
   --  driver's, no inhibition
   procedure Section_Profile (I        : Inputs_T;
                              Gradient : Gradient_T;
                              P        : out Profile_T)
     with Post => P.Count = 1;

   --  3.11.11.6 (Emergency), 3.11.11.8 (Service_EBD), 3.11.11.9
   --  (Service_SBD)
   type Condition_T is (Emergency, Service_EBD, Service_SBD);

   --  The condition C holds for the speed V in the integers (see above)
   function Holds (I        : Inputs_T;
                   P        : Profile_T;
                   C        : Condition_T;
                   D_PBD    : PBD_Distance_T;
                   V        : Speed_T) return Boolean
     with Pre => V <= Top_Speed;

   --  The largest speed of 0 .. Top_Speed for which C holds, cm/s, 0 when
   --  none; before the rounding to 5 km/h. Unrounded_On: on the profile P
   --  of the section (Section_Profile); Unrounded builds it.
   function Unrounded_On (I        : Inputs_T;
                          P        : Profile_T;
                          C        : Condition_T;
                          D_PBD    : PBD_Distance_T) return Speed_T
     with Post => Unrounded_On'Result <= Top_Speed;
   function Unrounded (I        : Inputs_T;
                       C        : Condition_T;
                       D_PBD    : PBD_Distance_T;
                       Gradient : Gradient_T) return Speed_T
     with Post => Unrounded'Result <= Top_Speed;

   --  3.11.11.6, 3.11.11.7: V_PBD, cm/s, a multiple of 5 km/h rounded
   --  down to the cm/s; 0 without a model of the emergency brake
   --  (3.13.2.2.1.3: nothing is known to fulfil the inequalities).
   --  Restrict builds the profile of the section in Work, a work area of
   --  the caller whose content it overwrites (the on-board's way: the
   --  profile, 17 KB, is not built on the stack; EVC_Track_Description.
   --  Compute_PBD); Restriction, for the tests, in a local one.
   procedure Restrict (I        : Inputs_T;
                       D_PBD    : PBD_Distance_T;
                       Gradient : Gradient_T;
                       Service  : Boolean;
                       Work     : in out Profile_T;
                       V        : out Speed_Cms_T)
     with Post => V <= Top_Speed;
   function Restriction (I        : Inputs_T;
                         D_PBD    : PBD_Distance_T;
                         Gradient : Gradient_T;
                         Service  : Boolean) return Speed_Cms_T
     with Post => Restriction'Result <= Top_Speed;

end EVC_PBD;
