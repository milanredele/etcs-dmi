--  ETCS on-board (EVC)
--  Skeleton of phase E4: every condition answers False until the unit
--  that owns it implements it (doc/EVC-PLAN.md §10). An arm names its
--  owner when it is implemented. The arms of the procedures half
--  (e4/procedures) read EVC_Procedures.Condition, computed once per
--  cycle by EVC_Procedures.Evaluate.

package body EVC_Transition_Conditions
  with SPARK_Mode => On
is

   function Holds (C : Condition_Id_T) return Boolean is
   begin
      case C is
         when C_1 =>
            return False;  --  not implemented yet
         when C_2 =>
            return False;  --  not implemented yet
         when C_3 =>
            return False;  --  not implemented yet
         when C_4 =>
            return False;  --  not implemented yet
         when C_5 =>
            --  EVC_Procedures: shunting selected at standstill in level 0, NTC
            --  or 1 (5.6)
            return EVC_Procedures.Condition (5);
         when C_6 =>
            return False;  --  level 2, the RBC: phase E5 (EVC_Procedures)
         when C_7 =>
            --  EVC_Procedures: the trip acknowledged at standstill, level 1 or
            --  2 (5.11)
            return EVC_Procedures.Condition (7);
         when C_8 =>
            return False;  --  not implemented yet
         when C_9 =>
            --  the LX indication of 5.16 (EVC_Procedures): not yet
            return False;
         when C_10 =>
            return False;  --  not implemented yet
         when C_11 =>
            return False;  --  level 2, the RBC: phase E5 (EVC_Procedures)
         when C_12 =>
            --  EVC_Procedures: the EOA/LOA passed, level 1 (5.11;
            --  EVC_SDM.EOA_Passed)
            return EVC_Procedures.Condition (12);
         when C_13 =>
            return False;  --  not implemented yet
         when C_14 =>
            return False;  --  not implemented yet
         when C_15 =>
            --  EVC_Procedures: the On Sight acknowledgement (5.9)
            return EVC_Procedures.Condition (15);
         when C_16 =>
            --  EVC_Procedures: the EOA/LOA passed, level 2 (5.11;
            --  EVC_SDM.EOA_Passed)
            return EVC_Procedures.Condition (16);
         when C_17 =>
            --  EVC_Procedures: a linking reaction "trip" (5.11, 3.16.2.3)
            return EVC_Procedures.Condition (17);
         when C_18 =>
            --  EVC_Procedures: a trip order of a balise, no override (5.11,
            --  3.11.6.4)
            return EVC_Procedures.Condition (18);
         when C_19 =>
            --  EVC_Procedures: "exit Shunting" at standstill (5.6)
            return EVC_Procedures.Condition (19);
         when C_20 =>
            return False;  --  the emergency stop of the RBC: phase E5
         when C_21 =>
            return False;  --  not implemented yet
         when C_22 =>
            --  EVC_Procedures: Passive Shunting, a desk opened, stop shunting
            --  stored
            return EVC_Procedures.Condition (22);
         when C_23 =>
            --  EVC_Procedures: Passive Shunting, a desk opened (4.4.20.1.8)
            return EVC_Procedures.Condition (23);
         when C_24 =>
            return False;  --  not implemented yet
         when C_25 =>
            return False;  --  not implemented yet
         when C_26 =>
            return False;  --  not implemented yet
         when C_27 =>
            --  EVC_Procedures: Shunting, the desks closed, no "continue"
            --  (4.4.20.1.6)
            return EVC_Procedures.Condition (27);
         when C_28 =>
            --  EVC_Procedures: the desks closed
            return EVC_Procedures.Condition (28);
         when C_29 =>
            return False;  --  not implemented yet
         when C_30 =>
            --  EVC_Procedures: the desks closed, passive shunting not
            --  permitted
            return EVC_Procedures.Condition (30);
         when C_31 =>
            return False;  --  not implemented yet
         when C_32 =>
            return False;  --  not implemented yet
         when C_33 =>
            return False;  --  not implemented yet
         when C_34 =>
            --  EVC_Procedures: an On Sight area at a level transition (5.9.4)
            return EVC_Procedures.Condition (34);
         when C_35 =>
            return False;  --  not implemented yet
         when C_36 =>
            return False;  --  not implemented yet
         when C_37 =>
            --  EVC_Procedures: "override" selected (5.8.2.1)
            return EVC_Procedures.Condition (37);
         when C_38 =>
            return False;  --  not implemented yet
         when C_39 =>
            return False;  --  not implemented yet
         when C_40 =>
            --  EVC_Procedures: an On Sight area overlapped, the furthest (5.9)
            return EVC_Procedures.Condition (40);
         when C_41 =>
            return False;  --  T_NVCONTACT, the RBC: phase E5
         when C_42 =>
            return False;  --  not implemented yet
         when C_43 =>
            --  EVC_Procedures: the former EOA passed without override (5.8)
            return EVC_Procedures.Condition (43);
         when C_44 =>
            return False;  --  not implemented yet
         when C_45 =>
            return False;  --  not implemented yet
         when C_46 =>
            return False;  --  not implemented yet
         when C_47 =>
            return False;  --  not implemented yet
         when C_48 =>
            return False;  --  not implemented yet
         when C_49 =>
            --  EVC_Procedures: "stop if in shunting", no override (4.4.8.1.1
            --  c)
            return EVC_Procedures.Condition (49);
         when C_50 =>
            --  EVC_Procedures: the Shunting acknowledgement (5.7)
            return EVC_Procedures.Condition (50);
         when C_51 =>
            --  EVC_Procedures: the max safe front end beyond a Shunting area
            --  entry (5.7)
            return EVC_Procedures.Condition (51);
         when C_52 =>
            --  EVC_Procedures: a balise group not in the list for the SH area
            return EVC_Procedures.Condition (52);
         when C_53 =>
            return False;  --  not implemented yet
         when C_54 =>
            --  EVC_Procedures: "stop if in SR", no override (no SR list in
            --  level 1)
            return EVC_Procedures.Condition (54);
         when C_55 =>
            return False;  --  absent from 4.0.0
         when C_56 =>
            return False;  --  not implemented yet
         when C_57 =>
            return False;  --  absent from 4.0.0
         when C_58 =>
            return False;  --  not implemented yet
         when C_59 =>
            --  EVC_Procedures: the reversing acknowledged at standstill (5.13)
            return EVC_Procedures.Condition (59);
         when C_60 =>
            return False;  --  not implemented yet
         when C_61 =>
            --  EVC_Procedures: a Shunting area at a level transition (5.7)
            return EVC_Procedures.Condition (61);
         when C_62 =>
            --  EVC_Procedures: the trip acknowledged, standstill, level 0,
            --  Train Data
            return EVC_Procedures.Condition (62);
         when C_63 =>
            --  EVC_Procedures: the trip acknowledged, standstill, level NTC,
            --  Train Data
            return EVC_Procedures.Condition (63);
         when C_64 =>
            return False;  --  absent from 4.0.0
         when C_65 =>
            --  EVC_Procedures: a telegram of a system version not supported,
            --  level 1, 2
            return EVC_Procedures.Condition (65);
         when C_66 =>
            --  EVC_Procedures: a linked group passed in the unexpected
            --  direction
            return EVC_Procedures.Condition (66);
         when C_67 =>
            return False;  --  not implemented yet
         when C_68 =>
            --  EVC_Procedures: the trip acknowledged, standstill, level 0/NTC,
            --  no data
            return EVC_Procedures.Condition (68);
         when C_69 =>
            --  EVC_Procedures: the estimated front end in rear of the SSP or
            --  gradient
            return EVC_Procedures.Condition (69);
         when C_70 =>
            --  EVC_Procedures: the Limited Supervision acknowledgement (5.19)
            return EVC_Procedures.Condition (70);
         when C_71 =>
            --  EVC_Procedures: a Limited Supervision area at a level
            --  transition (5.19.4)
            return EVC_Procedures.Condition (71);
         when C_72 =>
            --  EVC_Procedures: a Limited Supervision area overlapped, the
            --  furthest (5.19)
            return EVC_Procedures.Condition (72);
         when C_73 =>
            --  EVC_Procedures: an On Sight area, the furthest, not in an LS
            --  ack area
            return EVC_Procedures.Condition (73);
         when C_74 =>
            --  EVC_Procedures: a Limited Supervision area, the furthest, not
            --  in an OS one
            return EVC_Procedures.Condition (74);
         when C_75 =>
            --  EVC_Procedures: not in an OS ack area, no mode profile
            --  overlapped (5.9.6)
            return EVC_Procedures.Condition (75);
         when C_76 =>
            --  EVC_Procedures: not in an LS ack area, no mode profile
            --  overlapped (5.19.6)
            return EVC_Procedures.Condition (76);
         when C_77 =>
            return False;  --  not implemented yet
         when C_78 =>
            return False;  --  not implemented yet
         when C_79 =>
            return False;  --  not implemented yet
         when C_80 =>
            return False;  --  not implemented yet
         when C_81 =>
            return False;  --  the SM authorisation of the RBC: phase E5
         when C_82 =>
            --  EVC_Procedures: "exit Supervised Manoeuvre" at standstill
            --  (5.21)
            return EVC_Procedures.Condition (82);
         when C_83 =>
            return False;  --  not implemented yet
         when C_84 =>
            return False;  --  not implemented yet
      end case;
   end Holds;

end EVC_Transition_Conditions;
