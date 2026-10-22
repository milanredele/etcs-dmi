--  ETCS on-board (EVC)
--  The fifth step of the cycle: the levels and the mission, the radio
--  halves, the procedures, then the mode machine (Run_Mode_Machine)
--  and what entering a mode means (Enter_Mode, the deletions, the
--  brake reasons, the train length), the manoeuvre adjustment and the
--  data kept over No Power. Writes the parent's mode and the state of
--  the units of chapter 4 and 5.

pragma Unevaluated_Use_Of_Old (Allow);

private package EVC_Core.Modes
  with SPARK_Mode => On
is

   --  5. The modes and the levels: the level transitions and
   --  the driver's level (EVC_Levels, 5.10), the mission data, the start
   --  of mission and the mode proposed to the driver (EVC_Mission, 5.4),
   --  on the requests of the cycle; the desk closed during the start of
   --  mission (A.3.4.1.2 k)
   --  @req A.3.4.1.3, A.3.4.1.3 a), A.3.4.1.3 b), A.3.4.1.3 c), A.3.4.1.3 d)
   --  @req A.3.4.1.3 Table
   procedure Evaluate_Modes_And_Levels
     with Global => (Input  => (EVC_Radio.State, EVC_Radio_Authority.State,
                                Current_Mode, Clock_Ms,
                                EVC_Driver_Requests.State,
                                EVC_Train_Inputs.State,
                                EVC_Odometry.State, EVC_Origins.State,
                                EVC_Config.State, EVC_Procedures.State),
                     In_Out => (EVC_Levels.State, EVC_Mission.State,
                                EVC_National_Values.State,
                                EVC_Train_Data.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_Position.State,
                                EVC_Stored_Information.State)),
          Post => EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  The context of the cycle for the halves of the radio
   function Radio_Context return EVC_Radio.Context_T
     with Global => (Current_Mode, Clock_Ms, EVC_Track_Conditions.State);

   --  5d. After the levels and the mission: the session and
   --  link half, then the authority half (the sessions, the reports and
   --  requests to make, the conditions of 4.6.3 they own)
   --  @req 3.6.2.2.2.1, 5.4.3.2 A24, 5.4.3.2 A39
   procedure Evaluate_Radio
     with Global => (Input  => (Current_Mode, Clock_Ms,
                                EVC_National_Values.State,
                                EVC_Odometry.State,
                                EVC_Stored_Information.State,
                                EVC_Levels.State, SDM_Result,
                                EVC_Movement_Authority.State,
                                EVC_Driver_Requests.State,
                                EVC_Train_Inputs.State,
                                EVC_Procedures.State,
                                EVC_Mission.State, EVC_Train_Data.State,
                                EVC_Config.State,
                                EVC_Track_Conditions.State),
                     In_Out => (EVC_Sessions.State, EVC_Radio.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio_Info.State, EVC_Position.State,
                                EVC_Level_Sessions.State,
                                EVC_System_Version.State)),
          Post => EVC_Position.Orientation = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  --  A24, A39 delete the position (its LRBG no longer
                  --  valid): the interval of 3.6.4.1.2 starts again
                  and then (if EVC_Position.LRBG = EVC_Position.LRBG'Old
                            then EVC_Position.Doubt_Over
                                   = EVC_Position.Doubt_Over'Old
                                 and then EVC_Position.Doubt_Under
                                   = EVC_Position.Doubt_Under'Old
                            else not EVC_Position.LRBG.Valid);

   --  7d. The mode changed, to the radio (after the mode machine)
   procedure Radio_Mode_Changed (From, To : Mode_T)
     with Global => (In_Out => (EVC_Sessions.State, EVC_Radio.State,
                                EVC_Radio_Authority.State),
                     Input  => EVC_Mission.State);

   --  5e. The procedures (EVC_Procedures, EVC_Text_Messages), after
   --  the levels and the mission: the context of the cycle, the
   --  conditions of 4.6.3 they own
   --  @req 4.4.11.1.6.5
   procedure Run_Procedures
     with Global => (Input  => (EVC_Radio.State,
                                Current_Mode, TIU_Value_Now, TIU_Known_Now,
                                Odometer_Now, Brake_Ack_Now,
                                Ack_For_Protection, Clock_Ms,
                                SDM_Result, Test_Snapshot_Set,
                                EVC_Stored_Information.State,
                                EVC_Position.State,
                                EVC_Origins.State,
                                EVC_Driver_Requests.State,
                                EVC_Train_Data.State,
                                EVC_Track_Conditions.State,
                                EVC_Levels.State,
                                EVC_Train_Inputs.State,
                                EVC_Odometry.State,
                                EVC_Movement_Authority.State,
                                EVC_National_Values.State),
                     Output => Proc_Ctx,
                     In_Out => (Snapshot, EVC_Radio_Authority.State,
                                EVC_Procedures.State, EVC_Text_Messages.State,
                                EVC_Track_Description.State,
                                EVC_Mission.State,
                                Config_Last, Config_Seen));

   --  Any condition of the list L holds (4.6.1.6: "16, 17, 18" means "16
   --  or 17 or 18")
   function Any_Holds (L : Condition_List_T) return Boolean
     with Global => (EVC_Driver_Requests.State, EVC_Train_Inputs.State,
                     EVC_Levels.State, EVC_Mission.State,
                     EVC_Odometry.State, EVC_Stored_Information.State,
                     EVC_Movement_Authority.State, EVC_Train_Data.State,
                     EVC_Procedures.State, EVC_Sessions.State,
                     EVC_Radio_Authority.State);

   --  6. Mode machine: of the transitions of 4.6.2 whose condition of
   --  4.6.3 holds (EVC_Modes.Conditions, EVC_Transition_Conditions), the
   --  one of the highest priority (4.6.1.4; of two of the same priority,
   --  which 4.6.1.5 says cannot hold together, the first in the order of
   --  Mode_T). The transition to NP is not looked at: while this code
   --  runs the on-board is powered and [29] does not hold.
   --  @req 4.6.2 Table, 5.4.3.2 D2, 5.4.3.2 D3, 5.4.3.2 D10, 5.4.3.2 D12
   --  @req 5.4.3.2 S0, 5.4.3.2 S1, 5.4.3.2 S2, 5.4.3.2 S12, 5.4.3.2 S13
   --  @req 5.4.3.2 S20, 5.4.3.2 S22, 5.4.3.2 S23, 5.4.3.2 S24, 5.4.5.3 b)
   --  @req 5.4.5.3 c), 5.4.5.3 d), 5.4.5.3 e), 5.4.5.3 f), 5.4.5.3 h)
   --  @req 5.4.5.3 h) 1st bullet, 5.4.5.3 h) 2nd bullet, 5.4.5.3 h) 3rd bullet
   --  @req 5.4.5.3 h) 5th bullet
   procedure Run_Mode_Machine
     with Global => (Input  => (EVC_Driver_Requests.State,
                                EVC_Train_Inputs.State,
                                EVC_Levels.State, EVC_Mission.State,
                                EVC_Odometry.State,
                                EVC_Stored_Information.State,
                                EVC_Movement_Authority.State,
                                EVC_Train_Data.State,
                                EVC_Procedures.State,
                                EVC_Sessions.State,
                                EVC_Radio_Authority.State),
                     In_Out => Current_Mode),
          Post => (Current_Mode = Current_Mode'Old
                   or else Transition_Exists
                             (Current_Mode'Old, Current_Mode))
                  and then Current_Mode /= M_NP
                  and then (if Current_Mode'Old = M_IS
                            then Current_Mode = M_IS)
                  and then (if Current_Mode'Old = M_NP
                            then Current_Mode =
                                   (if EVC_Driver_Requests.Isolation_Selected
                                    then M_IS else M_SB));

   --  7a. 4.10: the stored information deleted on entering the mode To,
   --  each with the modes of its row (the track description, the MA, the
   --  mode profile and the signalling related speed restriction, the
   --  track conditions, the linking, the geographical position, the
   --  adhesion factor from the driver); the reference and the confidence
   --  interval of the position stay
   procedure Delete_On_Mode_Entry (To : Mode_T)
     with Global => (In_Out   => (EVC_Track_Description.State,
                                  EVC_Movement_Authority.State,
                                  EVC_Track_Conditions.State,
                                  EVC_Position.State,
                                  EVC_Stored_Information.State),
                     Proof_In => EVC_Odometry.State),
          Post => EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  7b. 4.12: the brake command reasons revoked on entering the mode To
   --  from From: the speed and distance monitoring, the roll away, the
   --  unauthorised direction movement and the standstill protections
   --  (3.14.2, 3.14.3)
   procedure Revoke_Brake_Reasons (From, To : Mode_T)
     with Global => (In_Out => (Brake_State, SDM_State, EVC_Sessions.State));

   --  7. What entering the mode To from From means: the data
   --  of 4.10 (the stores, the position, the level, the mission, the
   --  information of the procedures and the text messages), the brake
   --  command reasons of 4.12 (the speed and distance monitoring, the
   --  protections; the levels' own, EVC_Levels; the procedures' and the
   --  text messages' own), the end and the start of mission (5.5.2,
   --  5.4.6), the trip and its reason (5.11, EVC_Procedures)
   --  @req 3.6.6.9 d), 3.14.1.11, 4.3.1.6, 4.10.1.3, 4.10.1.3 a), 4.10.1.3 b)
   --  @req 4.10.1.3 c), 4.10.1.3 d), 4.10.1.3 e), 4.10.1.3 Table
   --  @req 4.10.1.3 Table-footnote [1], 4.12.1.2, 4.12.1.2 a), 4.12.1.2 b)
   --  @req 4.12.1.2 c), 4.12.1.2 d), 4.12.1.2 e), 4.12.1.2 Table
   --  @req 4.12.1.2 Table-footnote [1], 4.12.1.2 Table-footnote [2]
   --  @req 5.4.5.3 g)
   procedure Enter_Mode (From, To : Mode_T)
     with Global => (Input  => (EVC_Radio.State,
                                EVC_Odometry.State,
                                EVC_National_Values.State,
                                EVC_Train_Inputs.State,
                                EVC_Radio_Authority.State,
                                Proc_Ctx, Test_Snapshot_Set),
                     In_Out => (Snapshot, EVC_Sessions.State,
                                EVC_Procedures.State, EVC_Text_Messages.State,
                                EVC_Levels.State, EVC_Mission.State,
                                EVC_Train_Data.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_Position.State,
                                EVC_Stored_Information.State,
                                Brake_State, SDM_State)),
          Post => EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  7g. The train length of the valid Train Data to the position
   --  (3.6.1.7, 3.18.3): the min safe rear end and its triggers (packet 58
   --  rear locations, 3.6.5.1.5 c; the RBC/RBC border passed by the rear
   --  end, 3.15.1.3.1 c) need it; no valid Train Data, no rear end. Once
   --  per cycle, after everything that sets or invalidates the Train Data
   --  (the driver's entry in EVC_Mission, a mode entered)
   --  (and 3.18.3.2.5.1: with the default Train Data of Supervised
   --  Manoeuvre, the length of the safe consist, EVC_Train_Data.Length;
   --  and 4.4.7.1.6 b): in SB without valid Train Data with the safe
   --  consist length, the length of 3.6.1.7 by the orientation, decision:
   --  from the engine's front end, which 3.6.1.3.4's consist in front
   --  does not move yet, the rear end on the safe side by the nominal
   --  length in front); the gamma terms of the confidence interval
   --  (3.6.4.1.5), which leave the odometer's part, Doubt_Over and
   --  Doubt_Under, unchanged
   --  @req 4.4.6.1.4, 4.4.7.1.6, 4.4.8.1.3, 4.4.15.1.3, 4.4.20.1.4
   --  @req 4.4.7.1.6 b), 3.6.1.7 1st bullet, 3.6.1.7 2nd bullet
   --  @req 3.18.3.2.5.1, 3.6.4.1.5 last sentence
   procedure Sync_Train_Length
     with Global => (Input    => (EVC_Train_Data.State, Current_Mode,
                                  EVC_Config.State, EVC_Sessions.State),
                     In_Out   => EVC_Position.State,
                     Proof_In => EVC_Odometry.State),
          Post   => EVC_Position.Active_Cab = EVC_Position.Active_Cab'Old
                    and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                    and then EVC_Position.Manoeuvre_Orientation
                               = EVC_Position.Manoeuvre_Orientation'Old
                    and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                    and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                    and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  7e. Finish_Procedures, after the mode machine: the brake demand of
   --  the procedures in the mode of the end of the cycle
   --  (EVC_Procedures.Finish_Cycle);
   --  3.11.6.4: a trip order (V_MAIN 0) is used in the cycle in level 1
   --  (the trip [18], inhibited by the override, 5.8.3.6), and kept in
   --  the other levels until the level switches to 1 ([67])
   procedure Finish_Procedures
     with Global => (Input  => (Current_Mode, Proc_Ctx, Test_Snapshot_Set,
                                EVC_Stored_Information.State,
                                EVC_Levels.State),
                     In_Out => (Snapshot, EVC_Procedures.State,
                                EVC_Movement_Authority.State));

   --  2a. 5.21.2.2 A075, 3.6.1.5.1, 3.7.3.4: a Supervised Manoeuvre
   --  authorisation taken in this cycle fixes the train orientation;
   --  when its MA is in the opposite direction, the position is shifted
   --  to the other end of the consist and the location based information
   --  stored before is deleted (its own MA, gradient and SSP are taken
   --  after, by Evaluate_Stored_Information); 3.7.3.4 a), the same
   --  direction: nothing else (3.7.3.1); A095, the train position reported
   --  to the RBC. The orientation follows the cab again once the mission
   --  has ended or continues in Non Leading.
   --  Decision: the location based information of 3.7.3.4 b) is that of
   --  4.10's rows (the track description, the MA, the track conditions,
   --  the linking, the geographical position) and, by 3.6.1.1 a) and the
   --  table of 3.6.4.2.4, the level transition orders (with the table of
   --  priorities not yet applicable, A.3.4.1.2 k)'s deletion) and the RBC
   --  transition order
   --  @req 3.7.3.4, 3.7.3.4 a), 3.7.3.4 b), 5.21.2.2 A075, 5.21.2.2 A095
   procedure Adjust_For_Manoeuvre
     with Global => (Input    => (Current_Mode, EVC_Mission.State,
                                  EVC_Radio_Authority.State,
                                  EVC_Config.State),
                     Proof_In => EVC_Odometry.State,
                     In_Out   => (EVC_Train_Data.State,
                                  EVC_Track_Description.State,
                                  EVC_Movement_Authority.State,
                                  EVC_Track_Conditions.State,
                                  EVC_Position.State, EVC_Sessions.State,
                                  EVC_Levels.State, EVC_Radio.State)),
          Post => (if EVC_Position.Orientation
                        /= EVC_Position.Orientation'Old
                   then EVC_Position.Manoeuvre_Orientation)
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then
                  (if EVC_Position.Orientation
                        = EVC_Position.Orientation'Old
                     and then EVC_Position.Manoeuvre_Orientation
                                = EVC_Position.Manoeuvre_Orientation'Old
                   then EVC_Position.Doubt_Over
                          = EVC_Position.Doubt_Over'Old
                        and then EVC_Position.Doubt_Under
                                   = EVC_Position.Doubt_Under'Old);

   --  2b. 4.11.1.1, 4.11.1.3: the data kept over No Power, once the cold
   --  movement detection is known after the power-up: no cold movement,
   --  the train position and the level become valid; a cold movement
   --  detected or the information not available, the table of priority
   --  of the trackside supported levels is deleted and the rest stays
   --  invalid until validated otherwise (the start of mission);
   --  no cold movement, the RBC contact too
   procedure Revalidate_Kept
     with Global => (Input  => EVC_Odometry.State,
                     In_Out => (Kept_Pending, EVC_Levels.State,
                                EVC_Position.State, EVC_Radio.State)),
          Post => EVC_Position.Orientation = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  7c. 5.4.3.2 S22, S23, S24 (after E30, E31, E32), 5.4.5.3 a), f), g)
   --  and the table of 5.4.3.3: the start of mission leaves Stand By to
   --  SN, UN, SR (also by override), NL or SH: a position still invalid
   --  is deleted (an invalid position is one kept over No Power, always
   --  referred to an LRBG: EVC_Position.Keep); so is it on entering
   --  Sleeping from any mode (4.10.1.3 Table, column SL, note [1])
   --  @req 4.10.1.3 Table-footnote [1]
   procedure Delete_Invalid_Position (From, To : Mode_T)
     with Global => (In_Out   => EVC_Position.State,
                     Proof_In => EVC_Odometry.State),
          Post => EVC_Position.Orientation = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then (if EVC_Position.LRBG = EVC_Position.LRBG'Old
                            then EVC_Position.Doubt_Over
                                   = EVC_Position.Doubt_Over'Old
                                 and then EVC_Position.Doubt_Under
                                   = EVC_Position.Doubt_Under'Old
                            else not EVC_Position.LRBG.Valid);

   --  9. 4.10 column NP: what is kept over No Power, as it is at the end of
   --  each cycle (EVC_Retained)
   --  @req 3.17.2.9, 3.18.2.7, 3.15.9.5
   procedure Save_Retained
     with Global => (Input  => (EVC_Levels.State, EVC_Position.State,
                                EVC_Odometry.State, EVC_Radio.State,
                                EVC_System_Version.State,
                                EVC_National_Values.State,
                                EVC_VBC.State),
                     Output => EVC_Retained.State);

end EVC_Core.Modes;
