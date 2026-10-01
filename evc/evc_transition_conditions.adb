--  ETCS on-board (EVC)
--  Phase E4: every condition answers False until the unit that owns it
--  implements it (doc/EVC-PLAN.md §10). An arm names its owner when it
--  is implemented: "e4/modes" the modes and levels half (EVC_Levels,
--  EVC_Mission, EVC_Driver_Requests, EVC_Train_Inputs and the stored
--  information); the conditions of the procedures half still answer
--  False in this branch.

with EVC_Modes; use EVC_Modes;

package body EVC_Transition_Conditions
  with SPARK_Mode => On
is

   --  5.8 (override, the procedures half, e4/procedures): until the merge
   --  the override function is never active here
   function Override_Active return Boolean is (False)
     with Global => null;

   function Holds (C : Condition_Id_T) return Boolean is
   begin
      case C is
         when C_1 =>
            --  e4/modes: the driver's isolation (MSG_DRIVER_ACTION 20)
            return EVC_Driver_Requests.Isolation_Selected;
         when C_2 =>
            --  e4/modes: a cab active (SUBSET-034 2.5.1)
            return EVC_Train_Inputs.Desk_Open;
         when C_3 =>
            --  e4/modes
            return not EVC_Train_Inputs.Sleeping_Requested
              and then EVC_Odometry.Standstill;
         when C_4 =>
            --  e4/modes: this code runs: the on-board is powered
            return True;
         when C_5 =>
            return False;  --  not implemented yet
         when C_6 =>
            return False;  --  not implemented yet
         when C_7 =>
            return False;  --  not implemented yet
         when C_8 =>
            --  e4/modes: 5.4.3.2 S24, 4.4.14.1.6
            return EVC_Mission.Acknowledged (M_SR);
         when C_9 =>
            return False;  --  not implemented yet
         when C_10 =>
            --  e4/modes: a level 1 MA (no SM authorisation before E5)
            return EVC_Train_Data.Valid
              and then EVC_Stored_Information.MA_On_Board
              and then not EVC_Stored_Information.Mode_Profile_Overlap;
         when C_11 =>
            return False;  --  not implemented yet
         when C_12 =>
            return False;  --  not implemented yet
         when C_13 =>
            --  e4/modes: the faults are the host's: EVC_Core.Enter_Failure
            --  takes SF, the cycle does not run after it
            return False;
         when C_14 =>
            --  e4/modes
            return EVC_Train_Inputs.Sleeping_Requested
              and then EVC_Odometry.Standstill
              and then not EVC_Train_Inputs.Desk_Open;
         when C_15 =>
            return False;  --  not implemented yet
         when C_16 =>
            return False;  --  not implemented yet
         when C_17 =>
            return False;  --  not implemented yet
         when C_18 =>
            return False;  --  not implemented yet
         when C_19 =>
            return False;  --  not implemented yet
         when C_20 =>
            return False;  --  not implemented yet
         when C_21 =>
            --  e4/modes
            return EVC_Levels.Switched_To (L0);
         when C_22 =>
            return False;  --  not implemented yet
         when C_23 =>
            return False;  --  not implemented yet
         when C_24 =>
            return False;  --  not implemented yet
         when C_25 =>
            --  e4/modes
            return (EVC_Levels.Switched_To (L1)
                    or else EVC_Levels.Switched_To (L2))
              and then EVC_Stored_Information.MA_On_Board
              and then not EVC_Stored_Information.Mode_Profile_Overlap;
         when C_26 =>
            return False;  --  not implemented yet
         when C_27 =>
            return False;  --  not implemented yet
         when C_28 =>
            return False;  --  not implemented yet
         when C_29 =>
            --  e4/modes: this code runs: the on-board is powered
            return False;
         when C_30 =>
            return False;  --  not implemented yet
         when C_31 =>
            return False;  --  not implemented yet
         when C_32 =>
            --  e4/modes
            return EVC_Stored_Information.MA_On_Board
              and then not EVC_Stored_Information.Mode_Profile_Overlap
              and then EVC_Levels.Valid
              and then EVC_Levels.Level = L1
              and then not EVC_Movement_Authority.Trip_Ordered;
         when C_33 =>
            return False;  --  not implemented yet
         when C_34 =>
            return False;  --  not implemented yet
         when C_35 =>
            return False;  --  not implemented yet
         when C_36 =>
            return False;  --  not implemented yet
         when C_37 =>
            return False;  --  not implemented yet
         when C_38 =>
            return False;  --  not implemented yet
         when C_39 =>
            --  e4/modes
            return (EVC_Levels.Switched_To (L1)
                    or else EVC_Levels.Switched_To (L2))
              and then not EVC_Movement_Authority.MA.Present;
         when C_40 =>
            return False;  --  not implemented yet
         when C_41 =>
            return False;  --  not implemented yet
         when C_42 =>
            --  e4/modes
            return EVC_Mission.SR_Distance_Passed
              and then not Override_Active;
         when C_43 =>
            return False;  --  not implemented yet
         when C_44 =>
            --  e4/modes
            return Override_Active
              and then EVC_Levels.Switched_To (L1);
         when C_45 =>
            --  e4/modes: no unconditional emergency stop before E5
            return Override_Active
              and then EVC_Levels.Switched_To (L2);
         when C_46 =>
            --  e4/modes
            return EVC_Driver_Requests.Non_Leading_Selected
              and then EVC_Odometry.Standstill
              and then EVC_Train_Inputs.Non_Leading_Permitted;
         when C_47 =>
            --  e4/modes
            return not EVC_Train_Inputs.Non_Leading_Permitted
              and then EVC_Odometry.Standstill;
         when C_48 =>
            return False;  --  not implemented yet
         when C_49 =>
            return False;  --  not implemented yet
         when C_50 =>
            return False;  --  not implemented yet
         when C_51 =>
            return False;  --  not implemented yet
         when C_52 =>
            return False;  --  not implemented yet
         when C_53 =>
            return False;  --  not implemented yet
         when C_54 =>
            return False;  --  not implemented yet
         when C_55 =>
            return False;  --  absent from 4.0.0
         when C_56 =>
            --  e4/modes
            return EVC_Levels.Switched_To (NTC);
         when C_57 =>
            return False;  --  absent from 4.0.0
         when C_58 =>
            --  e4/modes: 5.4.3.2 S22
            return EVC_Levels.Valid
              and then EVC_Levels.Level = NTC
              and then EVC_Mission.Acknowledged (M_SN);
         when C_59 =>
            return False;  --  not implemented yet
         when C_60 =>
            --  e4/modes: 5.4.3.2 S23
            return EVC_Mission.Acknowledged (M_UN);
         when C_61 =>
            return False;  --  not implemented yet
         when C_62 =>
            return False;  --  not implemented yet
         when C_63 =>
            return False;  --  not implemented yet
         when C_64 =>
            return False;  --  absent from 4.0.0
         when C_65 =>
            return False;  --  not implemented yet
         when C_66 =>
            return False;  --  not implemented yet
         when C_67 =>
            --  e4/modes
            return EVC_Levels.Switched_To (L1)
              and then EVC_Movement_Authority.Trip_Ordered
              and then not Override_Active;
         when C_68 =>
            return False;  --  not implemented yet
         when C_69 =>
            return False;  --  not implemented yet
         when C_70 =>
            return False;  --  not implemented yet
         when C_71 =>
            return False;  --  not implemented yet
         when C_72 =>
            return False;  --  not implemented yet
         when C_73 =>
            return False;  --  not implemented yet
         when C_74 =>
            return False;  --  not implemented yet
         when C_75 =>
            return False;  --  not implemented yet
         when C_76 =>
            return False;  --  not implemented yet
         when C_77 =>
            --  e4/modes
            return EVC_Levels.Switched_To (L0)
              and then EVC_Train_Data.Valid;
         when C_78 =>
            --  e4/modes
            return (EVC_Levels.Switched_To (L0)
                    or else EVC_Levels.Switched_To (NTC))
              and then not EVC_Train_Data.Valid;
         when C_79 =>
            --  e4/modes
            return EVC_Levels.Switched_To (NTC)
              and then EVC_Train_Data.Valid;
         when C_80 =>
            return False;  --  not implemented yet
         when C_81 =>
            return False;  --  not implemented yet
         when C_82 =>
            return False;  --  not implemented yet
         when C_83 =>
            return False;  --  not implemented yet
         when C_84 =>
            --  e4/modes: 3.6.8.4, EVC_Odometry
            return EVC_Odometry.Safety_Exceeded;
      end case;
   end Holds;

end EVC_Transition_Conditions;
