--  ETCS on-board (EVC)
--  The mission data and the start and end of mission in levels 0, 1 and
--  NTC: SUBSET-026 5.4 (the start of mission), 5.5 (the end of
--  mission), the data of 5.4.2 the driver enters (driver ID, train
--  running number, Train Data), the acknowledgements of the modes the
--  start of mission proposes (4.6.3 [8], [58], [60]) and the data of the
--  mode Staff Responsible (4.4.11: the SR mode speed limit and the SR
--  distance, 4.6.3 [42]).
--
--  Data statuses (5.4.2.1): unknown, invalid, valid. Nothing is kept
--  over No Power (EVC_Core: Initialise is a cold start), so every datum
--  starts unknown; an entry makes it valid; entering a mode makes it
--  invalid or unknown as 4.10 says (Mode_Entered: driver ID and train
--  running number "TBR" in SB, deleted in SL; Train Data "TBR" in SB,
--  SH, SM and NL).
--
--  Start of mission (5.4.3.2). The procedure is engaged (S0) while the
--  mode is SB with a desk open (no communication session exists in
--  levels 0, 1, NTC: the RBC parts are phase E5); its steps are the
--  DMI's dialogue (DMI 11.7.2, Table 49), so the on-board takes the
--  driver's entries when they come and answers 'Start' (S20):
--    - the driver ID (S1, and 5.4.5.3 b), the train running number (S1,
--      S13, 5.4.5.3 c), the Train Data (S12, 5.4.5.3 d) are taken in the
--      modes where 4.7.2 makes them available; the level (S2) is
--      EVC_Levels';
--    - 'Start' with the driver ID, the level and the Train Data valid
--      (5.4.5.3 h: 'Start' at S10 needs valid Train Data, not a train
--      running number): level 1 proposes Staff Responsible
--      (S24), level 0 Unfitted (S23), level NTC National System (S22);
--      level 2 sends an MA request to the RBC (S21, E5): until E5 the
--      on-board has no session and proposes Staff Responsible as
--      5.4.5.3 h) says for level 2 without a session;
--    - the driver's acknowledgement of the proposed mode is the
--      condition [8], [60] or [58] of 4.6.3 (Acknowledged).
--  In Post Trip, 'Start' in level 1 proposes Staff Responsible
--  (4.4.14.1.6). A proposal ends when a mode is entered, when the
--  procedure ends (5.4.3.2.1: the desk is closed) or when the driver
--  enters data again.
--  The desk closed during the start of mission (A.3.4.1.2 k): the
--  driver ID, the train running number and the Train Data are to be
--  revalidated, the other deletions of the column k are EVC_Core's
--  (Desk_Closed_In_SoM).
--
--  Train Data (3.18.3, 5.4.3.2 S12): the flexible entry of DMI Table 40
--  with the installation's fixed Train Data (EVC_Config.Fixed_Train_T);
--  the brake position from the "other international" train category
--  (7.5.1.84: passenger train, freight train in P, in G); an entry out
--  of the ranges of the variables of 7.5 (L_TRAIN, V_MAXTRAIN, NC_CDTRAIN,
--  NC_TRAIN, M_AXLELOADCAT, M_AIRTIGHT, M_LOADINGGAUGE) or of A.3.11
--  (the brake percentage, 10 to 250) is refused, and the Train Data
--  keep their status. 16#FF# ("no value") keeps the installation's
--  value of a category.
--
--  End of mission (5.5.2): entering SB from FS, AD, LS, OS, SM, UN, NL,
--  SR, PT, RV or SN, or SH from FS, AD, LS, OS, SR, SM, SN or UN (from
--  PT: when a mission was going on). Its first step is the deletions of
--  4.10; the RBC session steps are E5.
--
--  Staff Responsible (4.4.11.1.3, 4.4.11.1.6.2, 4.4.11.1.6.3): entering
--  SR the national values V_NVSTFF and D_NVSTFF apply, the distance
--  counted from the entry (4.4.11.1.3.1 a, the virtual position of
--  3.6.7, EVC_Odometry); the driver's entry at standstill in SR (kind 3,
--  4.4.11.1.5) replaces both and restarts the distance (4.4.11.1.3.1 b).
--  The estimated front end beyond the end of the distance is the
--  condition [42] (with the override of 5.8, EVC_Procedures, not
--  active; the trip is EVC_Procedures', which reports its reason).

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Config;
with EVC_Driver_Requests;   use EVC_Driver_Requests;
with EVC_Distances;         use EVC_Distances;
with EVC_Modes;             use EVC_Modes;
with EVC_Odometry;
with EVC_Supervision_Input; use EVC_Supervision_Input;
with EVC_Train_Data;
with Interfaces;            use Interfaces;

package EVC_Mission
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  5.4.2.1
   type Data_Status_T is (Unknown, Invalid, Valid);

   function Driver_ID_Status return Data_Status_T
     with Global => State;
   function Driver_ID return Text_T
     with Global => State;
   function TRN_Status return Data_Status_T
     with Global => State;
   --  the train running number (NID_OPERATIONAL, up to 8 digits)
   function TRN return Text_T
     with Global => State;
   --  The status of the Train Data (EVC_Train_Data keeps them and their
   --  validity; unknown until the first entry)
   function Train_Data_Status return Data_Status_T
     with Global => (State, EVC_Train_Data.State);

   --  5.4.3.2 S0: the start of mission is engaged
   function SoM_Engaged return Boolean
     with Global => State;
   --  5.4.6: a mission is going on
   function Mission return Boolean
     with Global => State;

   --  A mode proposed to the driver for acknowledgement (5.4.3.2 S22,
   --  S23, S24; 4.4.14.1.6), and the driver's acknowledgement of it in
   --  the cycle (4.6.3 [8], [58], [60])
   function Proposed return Boolean
     with Global => State;
   function Proposed_Mode return Mode_T
     with Global => State;
   function Acknowledged (M : Mode_T) return Boolean
     with Global => State;
   --  The driver's acknowledgement of a mode change of the cycle was the
   --  start of mission's (the procedures do not take it,
   --  e4/integration)
   function Ack_Taken return Boolean
     with Global => State;
   --  5.4.3.2 S21, 5.11.2.2 S150: 'Start' in level 2 sent the MA request
   --  and waits for the RBC's answer (DMI Table 50 S7: MSG_ONBOARD
   --  "waiting" 3)
   function Waiting_For_RBC return Boolean
     with Global => State;

   --  The driver validated Train Data in this cycle (5.4.3.2 S12; the
   --  re-validation of 5.17.2.2 E6, EVC_Procedures)
   function Train_Data_Validated return Boolean
     with Global => State;

   --  The desk was closed in this cycle during the start of mission
   --  (A.3.4.1.2 k)
   function Desk_Closed_In_SoM return Boolean
     with Global => State;

   --  Staff Responsible: the SR mode speed limit, the SR distance
   function SR_Speed return Speed_Cms_T
     with Global => State;
   function SR_Distance return EVC_Odometry.Virtual_T
     with Global => State;
   --  [42]: the estimated front end passed the end of the SR distance
   function SR_Distance_Passed return Boolean
     with Global => (State, EVC_Odometry.State);

   --  4.4.20.1.5 to 4.4.20.1.7: the function "Continue Shunting on desk
   --  closure", enabled by the driver in SH (MSG_DRIVER_ACTION 19), active
   --  until SH is left (4.6.3 [26], [27])
   function Continue_Shunting return Boolean
     with Global => State;

   --  4.4.15.1.1.3: in NL, the non-leading input became "Non-leading not
   --  permitted" in this cycle (the driver is informed, EVC_Core)
   function NL_No_Longer_Permitted return Boolean
     with Global => State;

   ---------------------------------------------------------------------
   --  Juridical recording (EVC_Ports, event 41: the mission): kind
   --  (byte 2), two bytes
   ---------------------------------------------------------------------

   --  1 driver ID entered (its length), 2 train running number entered,
   --  3 Train Data entered (the length in m / 100, the brake
   --  percentage / 2), 4 an entry refused (the kind of MSG_DRIVER_DATA),
   --  5 'Start' (1 a mode proposed, 0 refused), 6 a mode proposed
   --  (EVC_Modes.Mode_T'Pos), 7 acknowledged (the mode), 8 start of
   --  mission engaged (1) or ended (0), 9 mission started (the mode),
   --  10 end of mission (the mode), 11 SR speed and distance entered
   --  (km/h / 5, m / 100 saturated at 255), 12 "Continue Shunting on desk
   --  closure" enabled (1) or ended (0), 13 non-leading no longer
   --  permitted in NL
   Event_Driver_ID  : constant := 1;
   Event_TRN        : constant := 2;
   Event_Train_Data : constant := 3;
   Event_Refused    : constant := 4;
   Event_Start      : constant := 5;
   Event_Proposed   : constant := 6;
   Event_Acked      : constant := 7;
   Event_SoM        : constant := 8;
   Event_Mission    : constant := 9;
   Event_EoM        : constant := 10;
   Event_SR_Data    : constant := 11;
   Event_Continue   : constant := 12;
   Event_NL_Lost    : constant := 13;

   type Event_T is record
      Kind, B3, B4 : Unsigned_8 := 0;
   end record;
   Max_Events : constant := 8;
   function Event_Count return Natural
     with Global => State,
          Post => Event_Count'Result <= Max_Events;
   function Event (I : Positive) return Event_T
     with Global => State,
          Pre => I <= Event_Count;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   type Context_T is record
      Mode        : Mode_T := M_SB;
      Level_Valid : Boolean := False;
      Level       : Level_T := L0;
      Standstill  : Boolean := True;
      Desk_Open   : Boolean := False;
      --  the non-leading input (4.4.15.1.1.3)
      Non_Leading : Boolean := False;
      --  the train orientation (the sense of the SR distance, 3.6.7)
      Sense       : Sense_T := Plus;
      --  the national values of SR (A.3.2, packet 3)
      V_NVSTFF    : Speed_Cms_T := 0;
      D_NVSTFF    : Length_T := Max_Cm;
      --  added by e5/session-3: the session with the supervising RBC is
      --  established (EVC_Radio.In_Communication; 5.4.5.3 h)
      In_Communication : Boolean := False;
      --  added by e5/sr-proposal: the SR authorisations (message 2) taken
      --  since the power-up (EVC_Radio_Authority.SR_Authorisations); a
      --  change while 'Start' waits at S21 / S150 is E26 (5.4.3.2,
      --  5.11.2.2)
      SR_Authorisations : Natural := 0;
      --  added by e5/mode-proposal-2: the acknowledgement of a mode
      --  profile at the train's position asked in SB / PT in level 2
      --  (EVC_Procedures.Ack_Requested, 5.7.4.1, 5.9.5.1, 5.19.5.1): an MA
      --  with a mode profile while 'Start' waits is E27 (5.4.3.2) / S150
      --  b) (5.11.2.2)
      Profile_Ack : Boolean := False;
   end record;

   --  Power-up: every datum unknown, no mission
   procedure Clear
     with Global => (Output => State, Proof_In => EVC_Train_Data.State),
          Post => Driver_ID_Status = Unknown and then TRN_Status = Unknown
                  and then Train_Data_Status = Unknown
                  and then not Proposed and then not Mission
                  and then not SoM_Engaged and then Event_Count = 0;

   --  One cycle, the driver's requests of the cycle (EVC_Driver_Requests)
   --  in the context C: the entries, 'Start', the acknowledgements, the
   --  start of mission, the SR distance
   procedure Evaluate (C : Context_T)
     with Global => (In_Out => (State, EVC_Train_Data.State),
                     Input  => (EVC_Driver_Requests.State,
                                EVC_Odometry.State, EVC_Config.State));

   --  4.4.11.1.6.5, 4.4.11.1.3.1 a): "Override" selected in SR: the SR
   --  mode speed limit and the SR distance the driver entered are
   --  deleted, the national values of C apply, the SR distance counted
   --  from now (event 11 with the national values)
   procedure Override_In_SR (C : Context_T)
     with Global => (In_Out => State, Input => EVC_Odometry.State);

   --  For the tests of the hosts (EVC_Core.Set_Mode_For_Test): the mode
   --  is set to M without a transition; in SR the SR mode speed limit and
   --  the SR distance of the national values apply from here, as on
   --  entering SR (4.4.11.1.3.1 a). No event is recorded.
   procedure Set_For_Test (M : Mode_T; C : Context_T)
     with Global => (In_Out => State, Input => EVC_Odometry.State);

   --  The mode machine took the transition From -> To (4.10, 5.4.6,
   --  5.5.2, 4.4.11)
   procedure Mode_Entered (From, To : Mode_T; C : Context_T)
     with Global => (In_Out => (State, EVC_Train_Data.State),
                     Input  => EVC_Odometry.State),
          Post => not Proposed;

end EVC_Mission;
