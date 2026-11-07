--  ETCS on-board (EVC)
--  The second and third steps of the cycle: the position updated with
--  the cab status and the odometer sample (Update_Position), then the
--  stored information evaluated on it (Evaluate_Stored_Information),
--  with the takes and releases of the held and buffered information in
--  between. Writes EVC_Position, EVC_Stored_Information and what they
--  own; reads the parent's odometer and mode.

pragma Unevaluated_Use_Of_Old (Allow);

private package EVC_Core.Stored
  with SPARK_Mode => On
is

   --  2. Update the position (EVC_Position): the cab status, the
   --  telegrams of the cycle, the odometer sample; its events go to the
   --  JRU. The standstill and the override speed come from the sample.
   --  @req 3.14.3.6, 4.8.3.1.1 Table-footnote [1], 5.8.2.1 a)
   procedure Update_Position
     with Global => (Input  => (Odometer_Now, Odometer_Fresh, TIU_Now,
                                EVC_National_Values.State, Current_Mode,
                                EVC_Levels.State, Clock_Ms,
                                EVC_Train_Inputs.State, EVC_Mission.State,
                                EVC_Train_Data.State, Brake_State),
                     Output => (Standstill, Below_Override),
                     In_Out => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Origins.State, EVC_Outbox.Queue)),
          Post =>
            EVC_Position.Manoeuvre_Orientation
              = EVC_Position.Manoeuvre_Orientation'Old
            and then
            (if EVC_Position.Manoeuvre_Orientation
             then EVC_Position.Orientation = EVC_Position.Orientation'Old)
            and then
            (if EVC_Position.Orientation /= EVC_Position.Orientation'Old
             then EVC_Position.Active_Cab
                    = (if EVC_Position.Orientation = EVC_Distances.Plus
                       then EVC_Position.Cab_A else EVC_Position.Cab_B))
            and then
            (if EVC_Position.LRBG = EVC_Position.LRBG'Old
               and then EVC_Position.Orientation
                          = EVC_Position.Orientation'Old
               and then EVC_Position.Manoeuvre_Orientation
                          = EVC_Position.Manoeuvre_Orientation'Old
             then EVC_Position.Doubt_Over >= EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             >= EVC_Position.Doubt_Under'Old);

   --  The mode related speed restriction (3.11.7, 3.11.10) of the mode
   --  of the last cycle, one source (EVC_Procedures.Mode_Speed): the
   --  national values (A.3.2, packet 3) or the speed of the mode profile
   --  the mode was entered with (3.11.7.1.1), of the reversing
   --  supervision information in RV (3.11.7.1.2), in SR the SR mode speed
   --  limit of EVC_Mission (the driver's or V_NVSTFF), under the override
   --  speed while the override is active
   --  @req 4.4.10.1.2, 4.4.10.1.3
   function Mode_Speed return EVC_Supervision_Input.Speed_Cms_T
     with Global => (Current_Mode, EVC_Mission.State,
                     EVC_National_Values.State, EVC_Procedures.State);

   --  4.4.11.1.6.4: the SR distance that applies, the last received of
   --  the RBC's (message 2) and EVC_Mission's (the national value or the
   --  driver's); [42] its end passed by the estimated front end
   --  @req 4.4.11.1.6.4, 4.4.11.1.6.4 b)
   function SR_Distance return EVC_Odometry.Virtual_T
     with Global => (EVC_Mission.State, EVC_Radio_Authority.State);

   function SR_Distance_Passed return Boolean
     with Global => (EVC_Mission.State, EVC_Radio_Authority.State,
                     EVC_Odometry.State);

   --  4.4.11.1.3 b): the end of the SR distance, a frame position along
   --  the train orientation (the virtual position of 3.6.7)
   function SR_End return EVC_Distances.Dist_T
     with Global => (EVC_Position.State, EVC_Odometry.State,
                     EVC_Mission.State, EVC_Radio_Authority.State);

   procedure Evaluate_Stored_Information
     with Global => (Input  => (Clock_Ms,
                                EVC_Odometry.State, EVC_Train_Data.State,
                                TIU_Now, EVC_Config.State, Current_Mode,
                                EVC_Train_Inputs.State, EVC_Mission.State,
                                SDM_Result,
                                EVC_Radio_Info.State,
                                EVC_Driver_Requests.State, DMI_Restarted),
                     In_Out => (SDM_Work, EVC_Stored_Information.State,
                                EVC_Position.State, EVC_Procedures.State,
                                EVC_Radio.State,
                                EVC_Radio_Authority.State,
                                EVC_Origins.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                EVC_Levels.State, EVC_Sessions.State,
                                EVC_Outbox.Queue, EVC_Text_Messages.State,
                                EVC_LS_Display.State,
                                EVC_System_Version.State, EVC_VBC.State)),
          Post => EVC_Position.Orientation
                    = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  3a. 4.8.3 [1]: the linking held by
   --  Update_Position (its group carries its own level transition order)
   --  judged again now that the stores evaluated that order: taken when
   --  accepted and not kept in the balise transition buffer (the
   --  verdict Keep_Unit_Packets gave it), else dropped
   --  @req 4.8.3.1.1 Table-footnote [1]
   procedure Take_Held_Linking
     with Global => (Input  => (Current_Mode, EVC_Levels.State,
                                EVC_Train_Inputs.State, EVC_Train_Data.State,
                                EVC_Mission.State, EVC_Odometry.State),
                     In_Out => (EVC_Position.State, EVC_Origins.State)),
          Post => EVC_Position.Orientation
                    = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  4.8.3 [1], 4.8.5.5: at the transition to
   --  level 1, the packets of the balise transition buffer the units take
   --  themselves, before the stores' release deletes the sets: the
   --  linking to EVC_Position (it replaces the RBC's now), the reversing
   --  packets 138, 139 to EVC_Procedures, in the order received; the
   --  first Sets sets (the oldest one when the balise and radio sets are
   --  released one by one in the order received, 4.8.5.5)
   --  @req 4.8.3.1.1 Table-footnote [1]
   procedure Release_Unit_Packets (Sets : Natural)
     with Global => (Input  => (EVC_Stored_Information.State,
                                EVC_Origins.State, EVC_Odometry.State),
                     In_Out => (EVC_Position.State, EVC_Procedures.State)),
          Post => EVC_Position.Orientation
                    = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  5a. 4.8.5.5 "at the same time": the level became 2 in
   --  this cycle (by an order of the stored information or at the
   --  location of an announced one, Evaluate_Modes_And_Levels): the
   --  transition buffer released at once, its messages judged in level 2
   --  and taken by the stores before the procedures and the mode machine
   --  of the cycle (an MA kept for the transition: no trip by [39]); at
   --  the transition to level 2 the balise sets of 4.8.3 [2] and the
   --  radio messages one by one in the sequence received across both,
   --  each taken before the next (4.8.5.6 a)); at the transition to
   --  level 1 the balise sets of [1]
   --  @req 4.8.3.1.1 Table-footnote [1], 4.8.5.5, 3.18.4.5.3
   --  @req 4.8.3.1.1 Table-footnote [2]
   procedure Release_Transition_Buffer
     with Global => (Input  => (Clock_Ms, Current_Mode,
                                EVC_Odometry.State, EVC_Train_Data.State,
                                EVC_Train_Inputs.State),
                     In_Out => (Latched_RTM, EVC_Received.Store,
                                EVC_Radio.State,
                                EVC_Mission.State, EVC_Position.State,
                                EVC_Procedures.State,
                                EVC_Text_Messages.State,
                                EVC_LS_Display.State,
                                EVC_Origins.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio_Info.State,
                                EVC_Stored_Information.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                EVC_Levels.State, EVC_Sessions.State)),
          Post => EVC_Position.Orientation
                    = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  2c. 3.4.4.1.1, 4.8.1.6: the linking (packet 5) of the
   --  radio messages of the cycle to the position, before any other
   --  location related information (while the origins of their LRBG
   --  are kept): the RBC's in level 2 (4.8.3), in the modes of the row
   --  Linking of 4.8.4
   procedure Take_Radio_Linking
     with Global => (Input  => (Current_Mode, EVC_Levels.State,
                                EVC_Train_Inputs.State, EVC_Train_Data.State,
                                EVC_Mission.State, EVC_Radio_Info.State,
                                EVC_Origins.State, EVC_Odometry.State),
                     In_Out => EVC_Position.State),
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

   --  5c. Take_Radio_Geo, 3.6.6.4.1, 4.8.3, 4.8.4.2,
   --  4.8.5: the packets 79 of the radio messages of the cycle (and of
   --  those the transition buffer released) to the position, judged in
   --  the level and mode after the transitions of the cycle (4.8.5.5: a
   --  packet kept for the level 2 transition is used at the transition);
   --  then the assignment of a co-ordinate system of the cycle (message
   --  45, 3.4.2.3.3.6)
   --  @req 3.6.6.4.1
   procedure Take_Radio_Geo
     with Global => (Input  => (Current_Mode, EVC_Levels.State,
                                EVC_Train_Inputs.State, EVC_Train_Data.State,
                                EVC_Mission.State, EVC_Radio_Info.State,
                                EVC_Radio.State),
                     Proof_In => EVC_Odometry.State,
                     In_Out => EVC_Position.State),
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

   --  5b. 4.8.3 [2], 4.8.5: the LSSMA display
   --  toggle on order of the RBC held for level 2 (EVC_LS_Display.
   --  Hold_Order) released at the transition (4.8.5.5) and judged in the
   --  mode of the cycle: taken in LS (its timer from the transition,
   --  4.4.19.1.4.2 c), rejected in the other modes (4.8.4.2 [9] [10]:
   --  message 24 carries no mode profile); deleted when level 2 is no
   --  longer announced or no session is established (4.8.5.4 a, c)
   --  @req 4.4.19.1.4.2 c), 4.8.3.1.1 Table-footnote [2]
   procedure Release_LS_Held
     with Global => (Input  => (Clock_Ms, Current_Mode, EVC_Levels.State,
                                EVC_Radio.State),
                     In_Out => EVC_LS_Display.State);

end EVC_Core.Stored;
