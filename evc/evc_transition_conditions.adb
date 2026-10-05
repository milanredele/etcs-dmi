--  ETCS on-board (EVC)
--  Phase E4: every condition answers False until the unit that owns it
--  implements it (doc/EVC-PLAN.md §10). The conditions are grouped by
--  their owner: the modes and levels half ("e4/modes": EVC_Driver_Requests
--  and EVC_Train_Inputs, EVC_Levels, EVC_Mission and the stored
--  information, EVC_Odometry), the procedures half (EVC_Procedures, which
--  computes its conditions once per cycle, EVC_Procedures.Evaluate, and
--  every trip condition, those of the levels and of SR included: [39],
--  [42], [67], so that a trip has one reason, 4.4.13.1.3), and those not
--  evaluated (a later phase, not implemented yet, or absent from 4.0.0).
--  Holds dispatches on the group; each group says per condition where it
--  comes from.

with EVC_Modes; use EVC_Modes;

package body EVC_Transition_Conditions
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------
   --  The groups of conditions (4.6.3)
   ---------------------------------------------------------------------

   --  e4/modes: the driver's requests (EVC_Driver_Requests) and the
   --  inputs of the train interface (EVC_Train_Inputs, SUBSET-034): the
   --  isolation (4.4.3), the desks, sleeping (4.4.16), passive shunting
   --  (4.4.20), non leading (4.4.15)
   subtype Train_Interface_Condition_T is Condition_Id_T
     with Static_Predicate =>
       Train_Interface_Condition_T in C_1 | C_2 | C_3 | C_14 | C_26 | C_27
                                     | C_46 | C_47;

   --  e4/modes: the level and its transitions (EVC_Levels, 5.10), with
   --  the MA of the stored information and the Train Data where the
   --  condition names them, the override of EVC_Procedures (5.8) for
   --  [44] and [45]
   subtype Level_Condition_T is Condition_Id_T
     with Static_Predicate =>
       Level_Condition_T in C_21 | C_25 | C_32 | C_44 | C_45 | C_56 | C_77
                           | C_78 | C_79;

   --  e4/modes: the start of mission (EVC_Mission, 5.4.3.2: the modes
   --  proposed to the driver and acknowledged) and the level 1 MA with
   --  valid Train Data ([10])
   subtype Mission_Condition_T is Condition_Id_T
     with Static_Predicate =>
       Mission_Condition_T in C_8 | C_10 | C_58 | C_60;

   --  EVC_Procedures (chapter 5), computed once per cycle:
   --    [5] shunting selected at standstill in level 0, NTC or 1 (5.6)
   --    [7] the trip acknowledged at standstill, level 1 or 2 (5.11)
   --    [9] the indication of a level crossing not protected starts
   --        (5.16.1.4)
   --    [12] the EOA/LOA passed, level 1 (5.11; EVC_SDM.EOA_Passed)
   --    [15] the On Sight acknowledgement (5.9)
   --    [16] the EOA/LOA passed, level 2 (5.11; EVC_SDM.EOA_Passed)
   --    [17] a linking reaction "trip" (5.11, 3.16.2.3)
   --    [18] a trip order of a balise, no override (5.11, 3.11.6.4)
   --    [19] "exit Shunting" at standstill (5.6)
   --    [22] Passive Shunting, a desk opened, stop shunting stored
   --    [23] Passive Shunting, a desk opened (4.4.20.1.8)
   --    [28] the desks closed
   --    [30] the desks closed, passive shunting not permitted
   --    [34] an On Sight area at a level transition (5.9.4)
   --    [37] "override" selected (5.8.2.1)
   --    [39] e4/modes; the trip is EVC_Procedures' (its reason)
   --    [40] an On Sight area overlapped, the furthest (5.9)
   --    [42] e4/modes (the SR distance of EVC_Mission); the trip is
   --         EVC_Procedures' (its reason, the override)
   --    [43] the former EOA passed without override (5.8)
   --    [49] "stop if in shunting", no override (4.4.8.1.1 c)
   --    [50] the Shunting acknowledgement (5.7)
   --    [51] the max safe front end beyond a Shunting area entry (5.7)
   --    [52] a balise group not in the list for the SH area
   --    [54] "stop if in SR", no override (no SR list in level 1)
   --    [59] the reversing acknowledged at standstill (5.13)
   --    [61] a Shunting area at a level transition (5.7)
   --    [62] the trip acknowledged, standstill, level 0, Train Data
   --    [63] the trip acknowledged, standstill, level NTC, Train Data
   --    [65] a telegram of a system version not supported, level 1, 2
   --    [66] a linked group passed in the unexpected direction
   --    [67] e4/modes; the trip is EVC_Procedures' (its reason, the
   --         override)
   --    [68] the trip acknowledged, standstill, level 0/NTC, no data
   --    [69] the estimated front end in rear of the SSP or gradient
   --    [70] the Limited Supervision acknowledgement (5.19)
   --    [71] a Limited Supervision area at a level transition (5.19.4)
   --    [72] a Limited Supervision area overlapped, the furthest (5.19)
   --    [73] an On Sight area, the furthest, not in an LS ack area
   --    [74] a Limited Supervision area, the furthest, not in an OS one
   --    [75] not in an OS ack area, no mode profile overlapped (5.9.6)
   --    [76] not in an LS ack area, no mode profile overlapped (5.19.6)
   --    [82] "exit Supervised Manoeuvre" at standstill (5.21)
   subtype Procedure_Condition_T is Condition_Id_T
     with Static_Predicate =>
       Procedure_Condition_T in C_5 | C_7 | C_9 | C_12 | C_15 | C_16
                               | C_17 | C_18 | C_19 | C_22 | C_23 | C_28
                               | C_30 | C_34 | C_37 | C_39 | C_40 | C_42
                               | C_43 | C_49 | C_50 | C_51 | C_52 | C_54
                               | C_59 | C_61 | C_62 | C_63 | C_65 | C_66
                               | C_67 | C_68 | C_69 | C_70 | C_71 | C_72
                               | C_73 | C_74 | C_75 | C_76 | C_82;

   --  Phase E5 (e5/joint): the radio, level 2. The session and link
   --  half (EVC_Sessions, computed once per cycle by its Evaluate):
   --    [41] T_NVCONTACT passed, reaction "train trip" (3.16.3.4)
   subtype Session_Condition_T is Condition_Id_T
     with Static_Predicate => Session_Condition_T in C_41;

   --  The authority half (EVC_Radio_Authority, computed once per cycle by
   --  its Evaluate):
   --    [6] "Shunting granted by RBC" at standstill, level 2 (5.6)
   --    [11] in RSM, a linked group at or beyond the EOA, level 2 (5.11)
   --    [20] an unconditional emergency stop accepted (3.10)
   --    [31] MA, SSP and gradient on-board, no mode profile, level 2
   --    [36] a group not in the SR list of the RBC, no override (packet
   --         63)
   --    [81] an MA of a Supervised Manoeuvre authorisation (5.21)
   --  and the unconditional emergency stop of [45] (Level_Holds)
   subtype Authority_Condition_T is Condition_Id_T
     with Static_Predicate =>
       Authority_Condition_T in C_6 | C_11 | C_20 | C_31 | C_36 | C_81;

   --  Never true in this on-board:
   --    not implemented yet: [24], [33], [48], [53], [80] (AD, the
   --    ERTMS/ATO on-board); [83] (the safe consist length in front of
   --    the engine: no radio in it, left out of the halves of E5); [35],
   --    [38] (a National System through an STM: NTC is out of scope)
   --    absent from 4.0.0: [55], [57], [64]
   subtype Not_Evaluated_T is Condition_Id_T
     with Static_Predicate =>
       Not_Evaluated_T in C_24 | C_33 | C_35 | C_38 | C_48 | C_53 | C_55
                         | C_57 | C_64 | C_80 | C_83;

   ---------------------------------------------------------------------
   --  The conditions of the modes and levels half (e4/modes)
   ---------------------------------------------------------------------

   --  [1], [2], [3], [14], [26], [27], [46], [47]: the driver's requests
   --  and the train interface (4.4.3, 4.4.15, 4.4.16, 4.4.20)
   function Train_Interface_Holds (C : Train_Interface_Condition_T)
     return Boolean
   is (case C is
          --  the driver's isolation (MSG_DRIVER_ACTION 20)
          when C_1  => EVC_Driver_Requests.Isolation_Selected,
          --  a cab active (SUBSET-034 2.5.1)
          when C_2  => EVC_Train_Inputs.Desk_Open,
          when C_3  => not EVC_Train_Inputs.Sleeping_Requested
                       and then EVC_Odometry.Standstill,
          when C_14 => EVC_Train_Inputs.Sleeping_Requested
                       and then EVC_Odometry.Standstill
                       and then not EVC_Train_Inputs.Desk_Open,
          --  4.4.20.1.6 ("Continue Shunting on desk closure",
          --  EVC_Mission)
          when C_26 => not EVC_Train_Inputs.Desk_Open
                       and then EVC_Mission.Continue_Shunting
                       and then EVC_Train_Inputs.Passive_Shunting_Permitted,
          --  e4/procedures: 4.4.20.1.6 (EVC_Mission, as [26])
          when C_27 => not EVC_Train_Inputs.Desk_Open
                       and then not EVC_Mission.Continue_Shunting,
          when C_46 => EVC_Driver_Requests.Non_Leading_Selected
                       and then EVC_Odometry.Standstill
                       and then EVC_Train_Inputs.Non_Leading_Permitted,
          when C_47 => not EVC_Train_Inputs.Non_Leading_Permitted
                       and then EVC_Odometry.Standstill)
     with Global => (EVC_Driver_Requests.State, EVC_Train_Inputs.State,
                     EVC_Odometry.State, EVC_Mission.State);

   --  [21], [25], [32], [44], [45], [56], [77], [78], [79]: the level
   --  (5.10)
   function Level_Holds (C : Level_Condition_T) return Boolean is
     (case C is
         when C_21 => EVC_Levels.Switched_To (L0),
         when C_25 => (EVC_Levels.Switched_To (L1)
                       or else EVC_Levels.Switched_To (L2))
                      and then EVC_Stored_Information.MA_On_Board
                      and then not EVC_Stored_Information
                                     .Mode_Profile_Overlap,
         when C_32 => EVC_Stored_Information.MA_On_Board
                      and then not EVC_Stored_Information
                                     .Mode_Profile_Overlap
                      and then EVC_Levels.Valid
                      and then EVC_Levels.Level = L1
                      and then not EVC_Movement_Authority.Trip_Ordered,
         --  the override of EVC_Procedures (5.8)
         when C_44 => EVC_Procedures.Override_Active
                      and then EVC_Levels.Switched_To (L1),
         --  the override of EVC_Procedures (5.8), the unconditional
         --  emergency stop of EVC_Radio_Authority (3.10)
         when C_45 => EVC_Procedures.Override_Active
                      and then not EVC_Radio_Authority
                                     .Unconditional_Stop_Received
                      and then EVC_Levels.Switched_To (L2),
         when C_56 => EVC_Levels.Switched_To (NTC),
         when C_77 => EVC_Levels.Switched_To (L0)
                      and then EVC_Train_Data.Valid,
         when C_78 => (EVC_Levels.Switched_To (L0)
                       or else EVC_Levels.Switched_To (NTC))
                      and then not EVC_Train_Data.Valid,
         when C_79 => EVC_Levels.Switched_To (NTC)
                      and then EVC_Train_Data.Valid)
     with Global => (EVC_Levels.State, EVC_Stored_Information.State,
                     EVC_Movement_Authority.State, EVC_Train_Data.State,
                     EVC_Procedures.State, EVC_Radio_Authority.State);

   --  [8], [10], [58], [60]: the start of mission (5.4.3.2) and the MA
   function Mission_Holds (C : Mission_Condition_T) return Boolean is
     (case C is
         --  5.4.3.2 S24, 4.4.14.1.6
         when C_8  => EVC_Mission.Acknowledged (M_SR),
         --  a level 1 MA (no SM authorisation before E5)
         when C_10 => EVC_Train_Data.Valid
                      and then EVC_Stored_Information.MA_On_Board
                      and then not EVC_Stored_Information
                                     .Mode_Profile_Overlap,
         --  5.4.3.2 S22
         when C_58 => EVC_Levels.Valid
                      and then EVC_Levels.Level = NTC
                      and then EVC_Mission.Acknowledged (M_SN),
         --  5.4.3.2 S23
         when C_60 => EVC_Mission.Acknowledged (M_UN))
     with Global => (EVC_Mission.State, EVC_Train_Data.State,
                     EVC_Stored_Information.State, EVC_Levels.State);

   ---------------------------------------------------------------------
   --  The conditions of the two halves of phase E5
   ---------------------------------------------------------------------

   function Session_Holds (C : Session_Condition_T) return Boolean is
     (case C is
         when C_41 => EVC_Sessions.T_NVCONTACT_Trip)
     with Global => EVC_Sessions.State;

   function Authority_Holds (C : Authority_Condition_T) return Boolean is
     (case C is
         when C_6  => EVC_Radio_Authority.Shunting_Granted,
         when C_11 => EVC_Radio_Authority.Group_At_EOA_In_RSM,
         when C_20 => EVC_Radio_Authority.Unconditional_Stop_Accepted,
         when C_31 => EVC_Radio_Authority.MA_On_Board_Level_2,
         when C_36 => EVC_Radio_Authority.Group_Not_In_SR_List,
         when C_81 => EVC_Radio_Authority.SM_Authorised)
     with Global => EVC_Radio_Authority.State;

   -----------
   -- Holds --
   -----------

   function Holds (C : Condition_Id_T) return Boolean is
   begin
      case C is
         when Train_Interface_Condition_T =>
            return Train_Interface_Holds (C);
         when Level_Condition_T =>
            return Level_Holds (C);
         when Mission_Condition_T =>
            return Mission_Holds (C);
         when Procedure_Condition_T =>
            return EVC_Procedures.Condition (C);
         when Session_Condition_T =>
            return Session_Holds (C);
         when Authority_Condition_T =>
            return Authority_Holds (C);
         when C_4 =>
            --  e4/modes: this code runs: the on-board is powered
            return True;
         when C_13 =>
            --  e4/modes: the faults are the host's: EVC_Core.Enter_Failure
            --  takes SF, the cycle does not run after it
            return False;
         when C_29 =>
            --  e4/modes: this code runs: the on-board is powered
            return False;
         when C_84 =>
            --  e4/modes: 3.6.8.4, EVC_Odometry
            return EVC_Odometry.Safety_Exceeded;
         when Not_Evaluated_T =>
            return False;
      end case;
   end Holds;

end EVC_Transition_Conditions;
