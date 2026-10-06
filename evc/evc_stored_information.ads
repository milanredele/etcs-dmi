--  ETCS on-board (EVC)
--  The stored information of the on-board and the snapshot it hands to
--  the supervision (SUBSET-026 3.7, 3.8.4, 3.11, 3.12, 3.13.7): the
--  third step of the cycle, "evaluate stored information" (EVC_Core).
--
--  One cycle (Evaluate):
--    1. the train orientation changed: the TSRs go (3.11.5.10);
--    2. the balise groups the position took into account in this cycle
--       (EVC_Position.Taken), each a message evaluated in its order:
--       the country of the national values (3.18.2.10), then its
--       packets valid for the train (3.6.3.1.3) in this order: national
--       values (3), SSP (27), gradients (21), ASP (51), PBD (52), TSR
--       (65, 66),
--       default gradient (141), track conditions (68, 39, 67), route
--       suitability (70), adhesion (71), level crossings (88), the MA
--       (12) and the mode profile of an MA accepted (80). The stores
--       replace what the new information replaces (3.7.3.1) before the
--       MA of the message is evaluated, and the deletion a shortened MA
--       asks is applied to the information of the earlier messages only
--       (3.8.5.1.5). An MA whose SvL the SSP and the gradients do not
--       cover from the estimated front end is not accepted (3.7.2.3);
--    3. the timers of the MA (3.8.4) and the deletions they ask (A.3.4);
--    4. national values waiting for their location (3.18.2.3);
--    5. what lies more than 300 m in rear of the min safe rear end
--       (A.3.1), and the origins nothing refers to any more;
--  Added by e4/modes: the filters of 4.8 (EVC_Acceptance) in the mode of
--  the Context and the level of EVC_Levels, before an information of a
--  group is taken; the level transition orders (41, 46) first
--  (4.8.1.3: the rest of the message is evaluated with them, an
--  immediate order switches the level at once, EVC_Levels); in the
--  snapshot, the functions of the mode (4.5.2 Figure 1, EVC_Modes): the
--  SSP, the ASP, the LX speed restrictions, the speed restrictions to
--  ensure a permitted braking distance, the signalling related speed
--  restriction, the MA and its temporary targets in the modes with an MA
--  (Track_Speed_Mode, MA_Mode), the TSRs and the gradients where the
--  MRSP is supervised with its curves (TSR_Mode), the maximum train
--  speed (Train_Speed_Mode); Supervise is a mode of TSR_Mode with valid
--  Train Data; the SR distance (Extra.SR_Distance) from the Context.
--
--    6. the snapshot (Current): the train, the Train Data, the national
--       values, the speed restrictions to ensure a permitted braking
--       distance computed (3.11.11.3: the sections received, or all of
--       them when an input of EVC_PBD changed), the MRSP with its TSR
--       flags, the gradient profile with
--       its coverage and the default gradient for TSR (3.13.4.1.3), the
--       MA, the braking inhibitions and the powerless sections, the
--       adhesion, the temporary EOA and SvL, Supervise (an MA and valid
--       Train Data; phase E4 adds the mode) and Extra (the configuration
--       of the on-board, the use of A_NVMAXREDADHn, the trip margin of
--       3.13.9.4.8.2; the rest at its defaults until E4 and E5, see
--       EVC_Supervision_Input);
--    7. the indications of the track conditions and the planning for the
--       DMI (EVC_Core sends them), the records for the juridical
--       recording (Event).
--
--  The MRSP (3.13.7): the lower envelope (EVC_Profiles.Envelope) of the
--  SSP, the ASP, the TSRs, the LX speed restrictions, the speed
--  restrictions to ensure a permitted braking distance (EVC_Track_
--  Description), the signalling related speed restriction (3.11.6, from
--  its reception on), under the ceiling of the maximum train speed
--  (3.11.8, V_MAXTRAIN) and of the mode related speed (the Mode_Speed of
--  the caller: the mode and override speeds of 3.11.7 and 3.11.10 are
--  phase E4). The positions are those of Table 2a ("max" item at a
--  start, "min" item at an end) with the train length where the rear end
--  counts, so that V_MRSP of 3.13.7.2, the lowest over the confidence
--  interval of the front end, is what the supervision reads from it.
--  Evaluate's postcondition states what the SRS asks: the MRSP is sorted
--  in the sense Ahead and never above any of its sources at any position
--  (MRSP_Sources are those sources along Ahead), and the SvL of the MA
--  is never before its EOA.
--
--  The supervision half of phase E3 reads the snapshot with Current in
--  the fourth step of the cycle.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Braking;
with EVC_Config;
with EVC_DMI_Port;
with EVC_Distances;          use EVC_Distances;
with EVC_Levels;
with EVC_Modes;
with EVC_Movement_Authority;
with EVC_National_Values;
with EVC_Odometry;
with EVC_Origins;
with EVC_PBD;
with EVC_Ports;
with EVC_Profile;
with EVC_Position;
with EVC_Profiles;           use EVC_Profiles;
with EVC_Radio_Info;
with EVC_Sessions;
with EVC_Supervision_Input;  use EVC_Supervision_Input;
with EVC_Track_Conditions;
with EVC_Track_Description;
with EVC_Train_Data;
with Interfaces;             use Interfaces;

package EVC_Stored_Information
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   ---------------------------------------------------------------------
   --  Juridical recording (EVC_Ports: event 32, stored information)
   ---------------------------------------------------------------------

   JRU_Event : constant := EVC_Ports.JRU_Stored_Information;

   --  The information (byte 2 of the record)
   Info_National_Values   : constant := 1;
   Info_SSP               : constant := 2;
   Info_Gradients         : constant := 3;
   Info_ASP               : constant := 4;
   Info_TSR               : constant := 5;
   Info_Default_Gradient  : constant := 6;
   Info_MA                : constant := 7;
   Info_Signalling_Speed  : constant := 8;
   Info_Track_Conditions  : constant := 9;
   Info_Traction          : constant := 10;
   Info_Big_Metal_Masses  : constant := 11;
   Info_Route_Suitability : constant := 12;
   Info_Mode_Profile      : constant := 13;
   Info_Level_Crossing    : constant := 14;
   Info_Adhesion          : constant := 15;
   Info_Group             : constant := 16;
   --  the speed restriction to ensure a permitted braking distance
   Info_PBD               : constant := 17;
   --  phase E4: the station platforms (packet 69), the allowed current
   --  consumption (packet 40)
   Info_Platforms         : constant := 18;
   Info_Current           : constant := 19;

   --  The change (byte 3); byte 4 a detail
   Change_Stored     : constant := 1;   -- the message number mod 256
   Change_Deleted    : constant := 2;   -- TSR: the NID_TSR revoked
   Change_Rejected   : constant := 3;   -- MA: not covered (3.7.2.3)
   Change_Section    : constant := 4;   -- MA: the section timed out
   Change_End        : constant := 5;   -- MA: End Section time-out
   Change_Overlap    : constant := 6;   -- MA: overlap time-out
   Change_LOA        : constant := 7;   -- MA: LOA speed time-out
   Change_Shortened  : constant := 8;   -- MA shortened (3.8.5.1.3/4)
   Change_Applicable : constant := 9;   -- national values in use
   Change_Defaults   : constant := 10;  -- national values: defaults
   Change_Trip       : constant := 11;  -- V_MAIN 0, trip order
   --  a group whose information could not be kept (no origin)
   Change_No_Origin  : constant := 12;
   --  added by e4/modes: an information rejected by the filters of 4.8
   --  (byte 2 Info_Group, byte 4 its NID_PACKET)
   Change_Filtered   : constant := 15;
   --  the TSRs deleted with the orientation (3.11.5.10)
   Change_Orientation : constant := 13;
   --  PBD: every section computed again, an input changed (3.11.11.3;
   --  byte 4 the number of sections mod 256)
   Change_Recalculated : constant := 14;

   type Event_T is record
      Info   : Unsigned_8 := 0;
      Change : Unsigned_8 := 0;
      Detail : Unsigned_8 := 0;
   end record;

   Max_Events : constant := 16;

   function Event_Count return Natural
     with Global => State,
          Post => Event_Count'Result <= Max_Events;
   function Event (I : Positive) return Event_T
     with Global => State,
          Pre => I <= Event_Count;

   ---------------------------------------------------------------------
   --  The snapshot and what it was built from
   ---------------------------------------------------------------------

   --  The configuration of this on-board (3.13.2.2.6 to 3.13.2.2.8,
   --  Snapshot_T.Extra.Config) is the installation's, data loaded by
   --  EVC_Core.Configure: EVC_Config.Current.Supervision

   function Current return Snapshot_T
     with Global => State;

   --  The snapshot into S. The on-board takes it this way, into its own
   --  storage: the result of Current is built on the stack of its caller
   --  (over 11 KB), Current is for the contracts and the tests
   procedure Get_Current (S : out Snapshot_T)
     with Global => State,
          Post => S = Current;

   --  The sources of the MRSP along Ahead, its steps along Ahead, and its
   --  ceiling (EVC_Profiles)
   function MRSP_Sources return Elements_T
     with Global => State;
   function MRSP_Steps return Steps_T
     with Global => State;
   function MRSP_Ceiling return Value_T
     with Global => State;

   --  The envelopes whose check failed (none expected), since Clear
   function Envelope_Failures return Natural
     with Global => State;

   --  The groups evaluated since Clear (the number of the last message)
   function Messages return Natural
     with Global => State;

   ---------------------------------------------------------------------
   --  For the DMI
   ---------------------------------------------------------------------

   --  The indications of the track conditions changed in the cycle:
   --  MSG_TRACK_COND is due (never before the first one)
   function Track_Cond_Due return Boolean
     with Global => State;
   function Track_Cond_Count return Natural
     with Global => State,
          Post => Track_Cond_Count'Result <= EVC_DMI_Port.Max_Track_Cond;
   function Track_Cond_List return EVC_DMI_Port.Track_Cond_List_T
     with Global => State;

   --  MSG_PLANNING is due: an MA is supervised and the position is valid
   function Planning_Due return Boolean
     with Global => State;
   function Planning return EVC_DMI_Port.Planning_T
     with Global => State;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   --  Power-up: nothing stored (the Train Data: the default train)
   procedure Clear
     with Global => (Output => (State, EVC_Origins.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                EVC_Train_Data.State)),
          Post => not Current.MA.Present and then not Current.Supervise
                  and then Event_Count = 0 and then not Track_Cond_Due
                  and then not Planning_Due;

   --  The driver's "slippery rail" (3.18.4.6, phase E4)
   procedure Set_Driver_Slippery (Slippery : Boolean)
     with Global => (In_Out => State);

   ---------------------------------------------------------------------
   --  Added by the procedures of phase E4 (e4/procedures)
   ---------------------------------------------------------------------

   --  5.20: the information for an external function of the last
   --  cycle (EVC_Track_Conditions.External), for the train interface
   function External_Info return EVC_Track_Conditions.External_T
     with Global => State;

   --  5.18.8: the tunnel stopping area reported (MSG_STATUS)
   function Tunnel return EVC_Track_Conditions.Tunnel_T
     with Global => State;

   --  The inputs of the speed restrictions to ensure a permitted braking
   --  distance in the last cycle (EVC_PBD)
   function PBD_Inputs return EVC_PBD.Inputs_T
     with Global => State;

   ---------------------------------------------------------------------
   --  Added by e4/modes: the mode of the on-board (4.5.2, 4.8) and what
   --  the conditions of 4.6.3 read of the stored information
   ---------------------------------------------------------------------

   --  What the cycle tells the stored information besides the time: the
   --  mode (the functions of 4.5.2 Figure 1, EVC_Modes; the filter of
   --  4.8.4), the inputs of the exceptions of 4.8.4 (a cab active, a
   --  valid train running number), the SR distance (4.4.11.1.3 b, a
   --  frame position), the antenna... The default is E3's: FS, every
   --  information accepted and used.
   type Mode_Context_T is record
      Mode        : EVC_Modes.Mode_T := EVC_Modes.M_FS;
      Cab_Active  : Boolean := True;
      TRN_Valid   : Boolean := True;
      SR_Distance : Boolean := False;
      SR_End      : Dist_T := 0;
   end record;

   --  4.6.3 [10], [25], [31], [32]: "MA + SSP + gradient are on-board"
   --  (an MA is accepted only when SSP and gradients cover it, 3.7.2.3)
   --  and the train position confidence interval overlaps a mode
   --  profile, as of the last Evaluate
   function MA_On_Board return Boolean
     with Global => State;
   function Mode_Profile_Overlap return Boolean
     with Global => State;
   --  4.4.9.1.4: the SSP and the gradients cover the whole length of the
   --  train (from the min safe rear end to the estimated front end, the
   --  Train Data's length), as of the last Evaluate
   function Train_Covered return Boolean
     with Global => State;

   --  Phase E5: an MA received by radio (EVC_Radio_Info) was accepted
   --  in the last Evaluate
   --  Phase E5, 3.10.2.2: the outcome of the conditional emergency stop
   --  of the radio message I of the cycle (EVC_Radio_Info), as
   --  Q_EMERGENCYSTOP (7.5.1.107): 0 accepted with a new EOA, 1 accepted
   --  without, 3 rejected; 4 when the message has none
   subtype Stop_Outcome_T is Natural range 0 .. 4;
   function Stop_Outcome (I : EVC_Radio_Info.Index_T) return Stop_Outcome_T
     with Global => State;

   function Radio_MA_Accepted return Boolean
     with Global => State;

   --  Phase E5, 3.8.2.5.1: a timer of the MA deleted track description
   --  in the last Evaluate (A.3.4.1.2 c, d, e, n)
   function MA_Timer_Deletion return Boolean
     with Global => State;

   --  One cycle (see above). Mode_Speed: the mode related speed limit
   --  (No_Speed_Limit until phase E4); Special_Active and Additional:
   --  the status of the special brakes and of the additional brake on
   --  the train interface (SUBSET-034 2.3.6, 2.3.7), which the braking
   --  model of the speed restrictions to ensure a permitted braking
   --  distance depends on (3.11.11.4, 3.13.6.2.1)
   --  Phase E4: Virtual_Last, the virtual limits the supervision found
   --  in the last cycle for the indication of the track conditions
   --  (EVC_Track_Conditions, 5.18.4.2, 5.18.8.3)
   --  Work: a work area for the profile of a section of the speed
   --  restrictions to ensure a permitted braking distance (EVC_PBD.
   --  Restrict), its content overwritten; the core lends the profile of
   --  the work area of the supervision, which EVC_SDM.Step builds anew
   --  before it reads it (one cycle at a time: the two never overlap)
   procedure Evaluate (Now_Ms         : Unsigned_64;
                       Mode_Speed     : Speed_Cms_T;
                       Work           : in out EVC_Profile.Profile_T;
                       Special_Active : EVC_Braking.Brakes_T :=
                         (others => False);
                       Additional     : Boolean := False;
                       Context        : Mode_Context_T := (others => <>);
                       Virtual_Last   : Virtual_Limits_T :=
                         (others => <>))
     with Global => (In_Out => (State, EVC_Origins.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                EVC_Levels.State, EVC_Sessions.State),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Train_Data.State, EVC_Config.State,
                                EVC_Radio_Info.State)),
          Post =>
            --  3.13.7: sorted in the sense Ahead, never above a source
            Current.MRSP.Count = MRSP_Steps.Count
            and then Sorted (MRSP_Steps)
            and then Below (MRSP_Steps, MRSP_Sources, 0, MRSP_Ceiling)
            and then (for all K in 1 .. Current.MRSP.Count =>
                        A (Current.Train.Ahead,
                           Current.MRSP.Segments (K).Start)
                          = MRSP_Steps.List (K).Start
                        and then Current.MRSP.Segments (K).Speed
                                   = MRSP_Steps.List (K).Value)
            and then (for all K in 1 .. Current.MRSP.Count - 1 =>
                        A (Current.Train.Ahead,
                           Current.MRSP.Segments (K).Start)
                          < A (Current.Train.Ahead,
                               Current.MRSP.Segments (K + 1).Start))
            --  3.8.4.5: the SvL is never before the EOA
            and then (if Current.MA.Present
                      then A (Current.Train.Ahead, Current.MA.SvL)
                             >= A (Current.Train.Ahead, Current.MA.EOA))
            --  3.11.12: the gradient profile sorted in the sense Ahead
            and then Current.Gradients.Count >= 1
            and then (for all K in 1 .. Current.Gradients.Count - 1 =>
                        A (Current.Train.Ahead,
                           Current.Gradients.Segments (K).Start)
                          < A (Current.Train.Ahead,
                               Current.Gradients.Segments (K + 1).Start));

   --  4.8.5.5 "at the same time" (e5/levels): the radio messages put in
   --  EVC_Radio_Info after Evaluate in this cycle, from the index First
   --  on (the transition buffer released at the transition to level 2,
   --  after the levels), taken as Evaluate takes the cycle's radio
   --  messages, before the procedures and the mode machine of the cycle.
   --  The snapshot (Current) is not built again: the next cycle's.
   procedure Evaluate_Released (First   : Positive;
                                Now_Ms  : Unsigned_64;
                                Context : Mode_Context_T)
     with Global => (In_Out => (State, EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                EVC_Levels.State, EVC_Sessions.State),
                     Input  => (EVC_Origins.State, EVC_Position.State,
                                EVC_Odometry.State, EVC_Train_Data.State,
                                EVC_Radio_Info.State));

end EVC_Stored_Information;
