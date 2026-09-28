--  ETCS on-board (EVC)
--  Speed and distance monitoring: SUBSET-026 3.13.8.2 (the supervised
--  targets), 3.13.9.4 (release speed), 3.13.10 (ceiling, target and
--  release speed monitoring, the supervision statuses and the commands
--  to the train interface, Tables 5 to 16, the most relevant displayed
--  target and what the driver is shown), 3.13.11 (perturbation
--  location), with the service brake feedback of A.3.10.
--
--  Step runs once per cycle, at the fourth step of EVC_Core.Tick, on the
--  snapshot of the stored information. It keeps its state in a State_T
--  the core holds (no package state) and returns a Result_T: the
--  commands of the speed and distance monitoring (traction cut-off,
--  service brake, emergency brake, 3.13.10.2.2: each held until its
--  revocation condition), the monitoring and status, and the values of
--  MSG_SPEED_STATE. EVC_Brake_Commands combines the commands with the
--  other brake reasons of 3.14.
--
--  The monitoring runs when the snapshot gives a ceiling speed (an MRSP
--  under Supervise, or a mode related speed); the targets are
--  supervised with Supervise and a valid train position. Until the mode
--  machine of phase E4, Supervise stands for "a mode with speed and
--  distance monitoring" (4.5.2 Figure 1).

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Braking;           use EVC_Braking;
with EVC_Distances;         use EVC_Distances;
with EVC_Fixed;             use EVC_Fixed;
with EVC_Profile;           use EVC_Profile;
with EVC_Supervision_Input; use EVC_Supervision_Input;

package EVC_SDM
  with SPARK_Mode => On
is

   type Monitoring_T is (CSM, TSM, RSM);
   type Status_T is (NoS, IndS, OvS, WaS, IntS);

   --  3.13.8.2.1: a) an MRSP element, b) the LOA, c) the EOA with the
   --  SvL (one target: Tables 9 and 11 take them together), d) the end
   --  of the SR distance
   type Target_Kind_T is (MRSP_Target, LOA_Target, EOA_Target, SR_Target);

   --  Location: the MRSP element start, the LOA, the SvL, the SR end;
   --  EOA: the EOA of an EOA_Target (ahead coordinates, EVC_Profile)
   type Target_T is record
      Kind     : Target_Kind_T := MRSP_Target;
      Location : Dist_T := 0;
      EOA      : Dist_T := 0;
      Speed    : Speed_T := 0;
   end record;

   ---------------------------------------------------------------------
   --  Inputs besides the snapshot
   ---------------------------------------------------------------------

   type Inputs_T is record
      Dt_Ms          : Natural := 0;
      --  SUBSET-034 2.3.6, 2.3.7: the status of the special brakes
      Special_Active : Brakes_T := (others => True);
      Additional     : Boolean := False;
      --  SUBSET-034 2.3.2: the brake pressure, kPa, when acquired
      Pressure_Known : Boolean := False;
      Pressure       : Natural range 0 .. 1_100 := 0;
      --  the level is 1 (alpha of 3.13.9.4.8.2, 3.13.10.2.7)
      Level_1        : Boolean := False;
      --  the distance from the active antenna to the front end
      Antenna_Offset : Natural range 0 .. 100_000 := 0;
   end record;

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   --  A.3.10: the service brake feedback
   type Feedback_T is record
      P0_Known     : Boolean := False;
      P0           : Num range 0 .. 11_000 := 5_000;   -- tenths of kPa
      Window_Lo    : Num range 0 .. 11_000 := 0;       -- 3 s stability
      Window_Hi    : Num range 0 .. 11_000 := 0;
      Window_Ms    : Time_T := 0;
      Adapt_Ms     : Time_T := 0;
      Active       : Boolean := False;   -- Q_feedback_active
      Locked       : Boolean := False;   -- Q_Tbslocked
      --  the reduction of T_bs (thousandths) in the last cycle, for the
      --  display locks
      Ratio_Prev   : Factor_T := 1_000;
   end record;

   type State_T is record
      Active      : Boolean := False;   -- the monitoring ran last cycle
      Monitoring  : Monitoring_T := CSM;
      Status      : Status_T := NoS;
      --  the commands in force (3.13.10.2.2); EB_For_SB: the emergency
      --  brake commanded instead of the service brake (3.13.10.2.3)
      TCO         : Boolean := False;
      SB          : Boolean := False;
      EB          : Boolean := False;
      EB_For_SB   : Boolean := False;
      --  3.13.10.4.5: the MRDT, and the number the DMI knows it by
      MRDT_Valid  : Boolean := False;
      MRDT        : Target_T;
      MRDT_Id     : Natural range 0 .. 255 := 0;
      --  3.13.10.6.1 Table 16: the list of targets and V_MRSP of the
      --  last cycle, to see their updates
      Signature   : Num := 0;
      Target_Count : Natural := 0;
      V_MRSP      : Speed_T := 0;
      --  the measured acceleration, mm/s², and the last speed
      V_Prev      : Speed_T := 0;
      A_Est       : Accel_T := 0;
      Feedback    : Feedback_T;
      --  3.13.10.4.8.1, A.3.10, A.3.13: the values displayed last, and
      --  whether they may not increase
      Shown_P     : Speed_T := 0;
      Shown_SBI   : Speed_T := 0;
      Shown_D     : Num := 0;
      Lock_P      : Boolean := False;
      Lock_SBI    : Boolean := False;
      Lock_D      : Boolean := False;
      --  the values shown last were of TSM or RSM (A.3.13)
      Active_Display : Boolean := False;
   end record;

   ---------------------------------------------------------------------
   --  Result
   ---------------------------------------------------------------------

   No_TTI : constant := 16#FFFF#;

   type Result_T is record
      --  the monitoring runs (a ceiling speed is known)
      Active         : Boolean := False;
      Monitoring     : Monitoring_T := CSM;
      Status         : Status_T := NoS;
      --  the commands (3.13.10.3.3, 3.13.10.4.10, 3.13.10.5.4)
      TCO            : Boolean := False;
      SB             : Boolean := False;
      EB             : Boolean := False;
      --  an emergency brake triggering condition holds in this cycle
      EB_Triggered   : Boolean := False;
      --  what the driver is shown (3.13.10.3 to 3.13.10.5), cm/s and cm
      V_Est          : Speed_T := 0;
      V_MRSP         : Speed_T := 0;
      V_Perm         : Speed_T := 0;
      V_Warning      : Speed_T := 0;
      V_SBI          : Speed_T := 0;
      V_Target       : Speed_T := 0;
      V_Release      : Speed_T := 0;
      Release_Exists : Boolean := False;
      Release_Shown  : Boolean := False;
      D_Target       : Num := 0;
      --  3.13.10.3.9: target information in ceiling speed monitoring
      CSM_Target     : Boolean := False;
      MRDT_Id        : Natural range 0 .. 255 := 0;
      --  3.13.10.3.10: time to Indication, tenths of a second, or No_TTI
      TTI            : Natural range 0 .. No_TTI := No_TTI;
      --  3.13.10.3.8: the distance to the first Indication location, cm,
      --  when there is one
      Indication     : Boolean := False;
      Indication_D   : Num := 0;
      --  3.13.10.2.6 a), 3.13.10.2.7: the min safe front end (level 2)
      --  or the min safe antenna position (level 1) passed the EOA or the
      --  LOA; the max safe front end passed the SvL
      EOA_Passed     : Boolean := False;
      SvL_Passed     : Boolean := False;
      --  3.13.11: the perturbation location (ahead coordinates) and
      --  whether the location to request an MA (3.13.11.8) was passed
      Perturbation   : Boolean := False;
      Perturbation_X : Num := 0;
      MA_Request     : Boolean := False;
   end record;

   ---------------------------------------------------------------------
   --  The work area of a cycle, rebuilt by every Step (the core keeps it
   --  in static memory, not on the stack)
   ---------------------------------------------------------------------

   Max_Targets : constant := Max_Speed_Segments + 2;
   subtype Target_Count_T is Natural range 0 .. Max_Targets;
   type Target_Array is array (1 .. Max_Targets) of Target_T;

   --  The MRSP in ahead coordinates: element K from Starts (K) to Starts
   --  (K + 1), the last one open ended, the elements before the first in
   --  the snapshot's order that do not start further ahead left out
   type Element_T is record
      Start : Dist_T := 0;
      Speed : Speed_T := 0;
   end record;
   type Element_Array is array (1 .. Max_Speed_Segments) of Element_T;

   type Work_T is record
      Model    : Model_T;
      Profile  : Profile_T;
      Count    : Target_Count_T := 0;
      Targets  : Target_Array := (others => <>);
      Elements : Natural range 0 .. Max_Speed_Segments := 0;
      MRSP     : Element_Array := (others => <>);
   end record;

   procedure Step (S       : Snapshot_T;
                   Inputs  : Inputs_T;
                   Work    : in out Work_T;
                   State   : in out State_T;
                   Result  : out Result_T)
     with Post =>
       --  3.13.10.2.5: the Intervention status is left only once no
       --  brake command is applied, and it never stands without one
       (if Result.Status = IntS then Result.SB or else Result.EB)
       --  the emergency brake is commanded whenever one of its
       --  triggering conditions holds (Tables 5, 8, 9, 13)
       and then (if Result.EB_Triggered then Result.EB)
       --  and revoked only at standstill or, outside release speed
       --  monitoring, when the speed is back at or below V_MRSP (Tables
       --  6, 10, 11, 14), unless nothing is supervised any more (the
       --  mode, 3.14.1.11, E4)
       and then (if State.EB'Old and then not State.EB
                 then not Result.Active
                      or else S.Train.Standstill
                      or else (Result.Monitoring /= RSM
                               and then Result.V_Est <= Result.V_MRSP))
       --  release speed monitoring only with a release speed
       and then (if Result.Monitoring = RSM then Result.Release_Exists)
       --  the speeds shown are ordered
       and then Result.V_Perm <= Result.V_Warning
       and then Result.V_Warning <= Result.V_SBI
       and then Result.SB = State.SB
       and then Result.EB = (State.EB or else State.EB_For_SB);

end EVC_SDM;
