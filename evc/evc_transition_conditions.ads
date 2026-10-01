--  ETCS on-board (EVC)
--  The conditions of the mode transitions, SUBSET-026 4.6.3, as one
--  identifier each. EVC_Modes.Transitions says which condition allows
--  which transition with which priority; this package says whether a
--  condition holds in the current cycle. Each condition is evaluated by
--  the unit that owns the state it speaks about (the position, the
--  stored information, the supervision, the driver's requests, the
--  train interface); Holds dispatches to it. A condition that is not
--  implemented yet returns False and says so in its arm.
--
--  The texts are quoted from the table of 4.6.3 (SUBSET-026-4 v4.0.0,
--  pages 49 to 51); {n} refers to the notes below the table.

with EVC_Driver_Requests;
with EVC_Levels;
with EVC_Mission;
with EVC_Movement_Authority;
with EVC_Odometry;
with EVC_Procedures;
with EVC_Stored_Information;
with EVC_Train_Data;
with EVC_Train_Inputs;

package EVC_Transition_Conditions
  with SPARK_Mode => On
is

   subtype Condition_Id_T is Positive range 1 .. 84;

   --  [1]
   --    The driver isolates the ERTMS/ETCS on-board equipment.
   C_1 : constant Condition_Id_T := 1;

   --  [2]
   --    (a desk is open)
   C_2 : constant Condition_Id_T := 2;

   --  [3]
   --    (The sleeping input information is set to "Sleeping not requested"
   --    is received any more) AND (train is at standstill)
   C_3 : constant Condition_Id_T := 3;

   --  [4]
   --    The ERTMS/ETCS on-board equipment is powered.
   C_4 : constant Condition_Id_T := 4;

   --  [5]
   --    (train is at standstill) AND (ERTMS/ETCS level is 0 or NTC or 1)
   --    AND (driver selects Shunting mode)
   C_5 : constant Condition_Id_T := 5;

   --  [6]
   --    (train is at standstill) AND (ERTMS/ETCS level is 2) AND
   --    (reception of the information “Shunting granted by RBC”, due to a
   --    Shunting request from the driver)
   C_6 : constant Condition_Id_T := 6;

   --  [7]
   --    (the driver acknowledges the train trip) AND (the train is at
   --    standstill) AND (the ERTMS/ETCS level is different from 0, NTC)
   C_7 : constant Condition_Id_T := 7;

   --  [8]
   --    (Staff Responsible mode is proposed to the driver) AND (driver
   --    acknowledges){4}
   C_8 : constant Condition_Id_T := 8;

   --  [9]
   --    (MA+SSP+gradient are on-board) AND (the ERTMS/ETCS on-board
   --    equipment starts to indicate to the driver that an unprotected LX
   --    is being approached (see clause 5.16.1.4))
   C_9 : constant Condition_Id_T := 9;

   --  [10]
   --    (valid Train Data is stored on board) AND (MA (excluding with
   --    Supervised Manoeuvre authorisation) + SSP +gradient are on-board)
   --    AND (the train position confidence interval does not overlap any
   --    Mode Profile)
   C_10 : constant Condition_Id_T := 10;

   --  [11]
   --    (While being in release speed monitoring, the on-board receives a
   --    balise group whose first possible location is known by linking
   --    information to be in rear of the EOA by a distance shorter than
   --    the distance between the active Eurobalise antenna and the front
   --    end of the train, at the EOA or in advance of the EOA) AND
   --    (ERTMS/ETCS level is 2).
   C_11 : constant Condition_Id_T := 11;

   --  [12]
   --    (The train/engine overpasses the EOA/LOA with its min safe antenna
   --    position) AND (ERTMS/ETCS level is 1)see {9} here under
   C_12 : constant Condition_Id_T := 12;

   --  [13]
   --    The ERTMS/ETCS on-board equipment detects a fault that affects
   --    safety
   C_13 : constant Condition_Id_T := 13;

   --  [14]
   --    (The sleeping input information is set to "Sleeping requested")
   --    AND (train is at standstill) AND (all desks connected to the
   --    ERTMS/ETCS on-board equipment are closed)
   C_14 : constant Condition_Id_T := 14;

   --  [15]
   --    (An ackn. request for On Sight is displayed to the driver) AND
   --    (the driver acknowledges)see {1} here under
   C_15 : constant Condition_Id_T := 15;

   --  [16]
   --    (The train/engine overpasses the EOA/LOA with its min safe front
   --    end) AND (ERTMS/ETCS level is 2).see {9} here under
   C_16 : constant Condition_Id_T := 16;

   --  [17]
   --    The onboard reacts according to a linking reaction set to “trip”.
   C_17 : constant Condition_Id_T := 17;

   --  [18]
   --    (the train/engine receives and uses a trip order given by balise)
   --    AND (override is not active)
   C_18 : constant Condition_Id_T := 18;

   --  [19]
   --    (driver selects “exit Shunting”) AND (train is at standstill).
   C_19 : constant Condition_Id_T := 19;

   --  [20]
   --    (unconditional emergency stop message is accepted)
   C_20 : constant Condition_Id_T := 20;

   --  [21]
   --    (ERTMS/ETCS level switches to 0)see {2} here under
   C_21 : constant Condition_Id_T := 21;

   --  [22]
   --    (a desk is open) AND (”Stop Shunting on desk opening” information
   --    is stored onboard)
   C_22 : constant Condition_Id_T := 22;

   --  [23]
   --    (a desk is open) AND (no ”Stop Shunting on desk opening”
   --    information is stored onboard)
   C_23 : constant Condition_Id_T := 23;

   --  [24]
   --    (MA+SSP+gradient are on-board) AND (the ERTMS/ETCS on-board
   --    equipment commands the service brake or the emergency brake)
   C_24 : constant Condition_Id_T := 24;

   --  [25]
   --    (ERTMS/ETCS level switches to 1 or 2) AND (MA+SSP+gradient are on-
   --    board) AND (the train position confidence interval does not
   --    overlap any Mode Profile)
   C_25 : constant Condition_Id_T := 25;

   --  [26]
   --    (desks are closed) AND (”Continue Shunting on desk closure”
   --    function is active) AND (The passive shunting input information is
   --    set to "Passive shunting permitted")
   C_26 : constant Condition_Id_T := 26;

   --  [27]
   --    (desks are closed) AND (”Continue Shunting on desk closure”
   --    function is not active)
   C_27 : constant Condition_Id_T := 27;

   --  [28]
   --    (desks are closed)
   C_28 : constant Condition_Id_T := 28;

   --  [29]
   --    the ERTMS/ETCS on-board equipment is NOT powered
   C_29 : constant Condition_Id_T := 29;

   --  [30]
   --    (desks are closed) AND (The passive shunting input information is
   --    set to "Passive shunting not permitted")
   C_30 : constant Condition_Id_T := 30;

   --  [31]
   --    (MA+SSP+gradient are on-board) AND (the train position confidence
   --    interval does not overlap any Mode Profile) AND (ERTMS/ETCS level
   --    is 2)
   C_31 : constant Condition_Id_T := 31;

   --  [32]
   --    (MA+SSP+gradient are on-board) AND (the train position confidence
   --    interval does not overlap any Mode Profile) AND (ERTMS/ETCS level
   --    is 1) AND (no trip order is given by balise)
   C_32 : constant Condition_Id_T := 32;

   --  [33]
   --    (MA+SSP+gradient are on-board) AND (the AD mode is no longer
   --    requested by the ERTMS/ATO on-board,see {10} here under)
   C_33 : constant Condition_Id_T := 33;

   --  [34]
   --    (A Mode Profile defining an On Sight area is on-board) AND (The
   --    train position confidence interval overlaps this On Sight area)
   --    AND (Starting from the min safe front end of the train this On
   --    Sight area is the furthest area that the train position confidence
   --    interval overlaps within the Mode Profile) AND (The ERTMS/ETCS
   --    level switches to 1 or 2)
   C_34 : constant Condition_Id_T := 34;

   --  [35]
   --    (driver selects Shunting mode) AND (The ERTMS/ETCS on-board
   --    equipment is interfaced to the National System through an STM) AND
   --    (a National Trip Procedure is active,see {8} here under)
   C_35 : constant Condition_Id_T := 35;

   --  [36]
   --    (the identity of the overpassed balise group is not in the list of
   --    expected balises related to SR mode) AND (override is not active).
   C_36 : constant Condition_Id_T := 36;

   --  [37]
   --    (driver selects “override”) AND (train speed is under or equal to
   --    the speed limit for triggering the “override” function)see {3}
   --    here under
   C_37 : constant Condition_Id_T := 37;

   --  [38]
   --    (The ERTMS/ETCS on-board equipment is interfaced to the National
   --    System through an STM) AND (The ERTMS/ETCS level switches to 0,1
   --    or 2) AND (a National Trip Procedure is active)see {8} here under
   C_38 : constant Condition_Id_T := 38;

   --  [39]
   --    (The ERTMS/ETCS level switches to 1 or 2) AND (no MA has been
   --    accepted)
   C_39 : constant Condition_Id_T := 39;

   --  [40]
   --    (A Mode Profile defining an On Sight area is on-board) AND (The
   --    train position confidence interval overlaps this On Sight area)
   --    AND (Starting from the min safe front end of the train this On
   --    Sight area is the furthest area that the train position confidence
   --    interval overlaps within the Mode Profile)
   C_40 : constant Condition_Id_T := 40;

   --  [41]
   --    (T_NVCONTACT is passed) AND (associated reaction is “train trip”)
   C_41 : constant Condition_Id_T := 41;

   --  [42]
   --    (The train/engine overpasses the SR distance with its estimated
   --    front end) AND (override is not active)
   C_42 : constant Condition_Id_T := 42;

   --  [43]
   --    (The train/engine overpasses the former EOA/LOA (when Override was
   --    activated) with the min safe antenna position) AND (override is
   --    not active),see {3} and {9} here under
   C_43 : constant Condition_Id_T := 43;

   --  [44]
   --    (“override” function is active) AND (ERTMS/ETCS level switches to
   --    1)see {3} here under
   C_44 : constant Condition_Id_T := 44;

   --  [45]
   --    (“override” function is active) AND (no unconditional emergency
   --    stop message has been received) AND (ERTMS/ETCS level switches to
   --    2)see {3} here under
   C_45 : constant Condition_Id_T := 45;

   --  [46]
   --    (Driver selects NON LEADING) AND (train is at standstill) AND (The
   --    non-leading input information is set to "Non-leading permitted")
   C_46 : constant Condition_Id_T := 46;

   --  [47]
   --    (The non-leading input information is set to "Non-leading not
   --    permitted") AND (train is at standstill)
   C_47 : constant Condition_Id_T := 47;

   --  [48]
   --    (MA+SSP+gradient are on-board) AND (SSP and gradient are no longer
   --    known for the whole length of the train)
   C_48 : constant Condition_Id_T := 48;

   --  [49]
   --    (reception of information “stop if in shunting”) AND (override is
   --    not active)
   C_49 : constant Condition_Id_T := 49;

   --  [50]
   --    (An ackn. request for Shunting is displayed to the driver) AND
   --    (the driver acknowledges)see {5} here under
   C_50 : constant Condition_Id_T := 50;

   --  [51]
   --    (A Mode Profile defining a Shunting area is on-board) AND (The max
   --    safe front end of the train is in advance of the entry of the
   --    Shunting area)
   C_51 : constant Condition_Id_T := 51;

   --  [52]
   --    (the identity of the overpassed balise group is not in the list of
   --    expected balise groups related to SH mode) AND (override is not
   --    active).
   C_52 : constant Condition_Id_T := 52;

   --  [53]
   --    (MA+SSP+gradient are on-board) AND (the driver selects "ATO
   --    disengage" or sets the ATO selector to "Stand-by")
   C_53 : constant Condition_Id_T := 53;

   --  [54]
   --    (reception of information “stop if in Staff Responsible”) AND (no
   --    list of expected balise groups related to SR mode has been
   --    received or the list of expected balise groups related to SR mode
   --    does not include the identity of the overpassed balise group) AND
   --    (override is not active)
   C_54 : constant Condition_Id_T := 54;

   --  [55]
   --    not in the table of 4.0.0 (the identifier is skipped on the PDF
   --    page); never used by EVC_Modes.Transitions
   C_55 : constant Condition_Id_T := 55;

   --  [56]
   --    (the ERTMS/ETCS level switches to “NTC”)
   C_56 : constant Condition_Id_T := 56;

   --  [57]
   --    not in the table of 4.0.0 (the identifier is skipped on the PDF
   --    page); never used by EVC_Modes.Transitions
   C_57 : constant Condition_Id_T := 57;

   --  [58]
   --    (the ERTMS/ETCS level is “NTC”) AND (an acknowledgement request
   --    for SN mode is displayed to the driver) AND (the driver
   --    acknowledges)
   C_58 : constant Condition_Id_T := 58;

   --  [59]
   --    (train is at standstill) AND (driver has acknowledged the
   --    reversing)see {6} here under
   C_59 : constant Condition_Id_T := 59;

   --  [60]
   --    (an acknowledgement request for UN mode is displayed to the
   --    driver) AND (the driver acknowledges)
   C_60 : constant Condition_Id_T := 60;

   --  [61]
   --    (A Mode Profile defining a Shunting area is on-board) AND (The max
   --    safe front end of the train is in advance of the entry of the
   --    Shunting area) AND (The ERTMS/ETCS level switches to 1 or 2)
   C_61 : constant Condition_Id_T := 61;

   --  [62]
   --    (the driver acknowledges the train trip) AND (the train is at
   --    standstill) AND (the ERTMS/ETCS level is 0) AND (valid Train Data
   --    is on-board)
   C_62 : constant Condition_Id_T := 62;

   --  [63]
   --    (the driver acknowledges the train trip) AND (the train is at
   --    standstill) AND (the ERTMS/ETCS level is NTC) AND (valid Train
   --    Data is on-board)
   C_63 : constant Condition_Id_T := 63;

   --  [64]
   --    not in the table of 4.0.0 (the identifier is skipped on the PDF
   --    page); never used by EVC_Modes.Transitions
   C_64 : constant Condition_Id_T := 64;

   --  [65]
   --    (The system version number X of a received balise telegram is
   --    greater than the highest version number X supported by the on-
   --    board equipment) AND (ERTMS/ETCS level is 1 or 2)
   C_65 : constant Condition_Id_T := 65;

   --  [66]
   --    The expected balise group referred in the linking information with
   --    an ID not set to “unknown” is passed in the unexpected direction
   C_66 : constant Condition_Id_T := 66;

   --  [67]
   --    (The ERTMS/ETCS level switches to level 1) AND (a trip order has
   --    been received) AND (override is not active)
   C_67 : constant Condition_Id_T := 67;

   --  [68]
   --    (the driver acknowledges the train trip) AND (the train is at
   --    standstill) AND (the ERTMS/ETCS level is 0 or NTC) AND (no valid
   --    Train Data is on-board)
   C_68 : constant Condition_Id_T := 68;

   --  [69]
   --    Estimated train front end is in rear of the start location of
   --    either SSP or gradient profile stored on-board
   C_69 : constant Condition_Id_T := 69;

   --  [70]
   --    (An ackn. request for Limited Supervision is displayed to the
   --    driver) AND (the driver acknowledges)see {7} here under
   C_70 : constant Condition_Id_T := 70;

   --  [71]
   --    (A Mode Profile defining a Limited Supervision area is on-board)
   --    AND (The train position confidence interval overlaps this Limited
   --    Supervision area) AND (Starting from the min safe front end of the
   --    train this Limited Supervision area is the furthest area that the
   --    train position confidence interval overlaps within the Mode
   --    Profile) AND (The ERTMS/ETCS level switches to 1 or 2)
   C_71 : constant Condition_Id_T := 71;

   --  [72]
   --    (A Mode Profile defining a Limited Supervision area is on-board)
   --    AND (The train position confidence interval overlaps this Limited
   --    Supervision area) AND (Starting from the min safe front end of the
   --    train this Limited Supervision area is the furthest area that the
   --    train position confidence interval overlaps within the Mode
   --    Profile).
   C_72 : constant Condition_Id_T := 72;

   --  [73]
   --    (A Mode Profile defining an On Sight area is on-board) AND (The
   --    train position confidence interval overlaps this On Sight area)
   --    AND (The estimated front end of the train is not inside an LS
   --    acknowledgement area) AND (Starting from the min safe front end of
   --    the train this On Sight area is the furthest area that the train
   --    position confidence interval overlaps within the Mode Profile)
   C_73 : constant Condition_Id_T := 73;

   --  [74]
   --    (A Mode Profile defining a Limited Supervision area is on-board)
   --    AND (The train position confidence interval overlaps this Limited
   --    Supervision area) AND (The estimated front end of the train is not
   --    inside an OS acknowledgement area) AND (Startingfrom the min safe
   --    front end of the train this Limited Supervision area is the
   --    furthest area that the train position confidence interval overlaps
   --    within the Mode Profile)
   C_74 : constant Condition_Id_T := 74;

   --  [75]
   --    (The estimated front end of the train is not inside an OS
   --    acknowledgement area) AND (The train position confidence interval
   --    does not overlap any Mode Profile)
   C_75 : constant Condition_Id_T := 75;

   --  [76]
   --    (The estimated front end of the train is not inside an LS
   --    acknowledgement area) AND (The train position confidence interval
   --    does not overlap any Mode Profile)
   C_76 : constant Condition_Id_T := 76;

   --  [77]
   --    (the ERTMS/ETCS level switches to 0) AND (valid Train Data is on-
   --    board)
   C_77 : constant Condition_Id_T := 77;

   --  [78]
   --    (the ERTMS/ETCS level switches to 0 or NTC) AND (no valid Train
   --    Data is on-board)
   C_78 : constant Condition_Id_T := 78;

   --  [79]
   --    (the ERTMS/ETCS level switches to NTC) AND (valid Train Data is
   --    on-board)
   C_79 : constant Condition_Id_T := 79;

   --  [80]
   --    (The AD mode is requested by the ERTMS/ATO on-board,see {10} here
   --    under) AND (SSP and gradient are known for the whole length of the
   --    train) AND (the ERTMS/ETCS on-board equipment does not command the
   --    service brake) AND (the ERTMS/ETCS on-board equipment does not
   --    command the emergency brake) AND (the driver selects "ATO engage")
   C_80 : constant Condition_Id_T := 80;

   --  [81]
   --    An MA, which is included in a “Supervised Manoeuvre authorisation”
   --    due to a Supervised Manoeuvre request by the driver, is received
   --    from the RBC
   C_81 : constant Condition_Id_T := 81;

   --  [82]
   --    (driver selects “Exit of Supervised Manoeuvre”) AND (train is at
   --    standstill).
   C_82 : constant Condition_Id_T := 82;

   --  [83]
   --    (valid Train Data is stored on-board) AND (The safe consist length
   --    in front the engine becomes different from zero)
   C_83 : constant Condition_Id_T := 83;

   --  [84]
   --    The accumulated underestimation/overestimation in measuring the
   --    movements over a defined total distance exceeds the safety
   --    threshold
   C_84 : constant Condition_Id_T := 84;

   --  True when the condition holds in the current cycle. The modes
   --  and levels (e4/modes) read the driver's requests, the inputs of
   --  the train interface, the level, the mission data, the odometer, the
   --  stored information and the Train Data; the procedures
   --  (e4/procedures) evaluate theirs in EVC_Procedures (Evaluate, once
   --  per cycle before the mode machine; every trip condition is theirs,
   --  so that the trip has one reason, 4.4.13.1.3). [1], [4] and [29]
   --  are stated (the transitions out of No Power that EVC_Core.Tick
   --  proves).
   function Holds (C : Condition_Id_T) return Boolean
     with Global => (Input => (EVC_Driver_Requests.State,
                               EVC_Train_Inputs.State,
                               EVC_Levels.State,
                               EVC_Mission.State,
                               EVC_Odometry.State,
                               EVC_Stored_Information.State,
                               EVC_Movement_Authority.State,
                               EVC_Train_Data.State,
                               EVC_Procedures.State)),
          Post => (if C = C_1
                   then Holds'Result
                          = EVC_Driver_Requests.Isolation_Selected)
                  and then (if C = C_4 then Holds'Result)
                  and then (if C = C_29 then not Holds'Result);

end EVC_Transition_Conditions;
