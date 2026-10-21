--  ETCS on-board (EVC)
--  The fourth step of the cycle: the speed and distance monitoring and
--  the brake command handling on the snapshot of the stored
--  information (Monitor_Speed_And_Distance), and the BTM alarm's
--  distance (Supervise_BTM_Alarm). Writes the parent's snapshot, SDM
--  and brake state.

pragma Unevaluated_Use_Of_Old (Allow);

private package EVC_Core.Monitoring
  with SPARK_Mode => On
is

   --  MSG_SPEED_STATE from the result of the speed and distance
   --  monitoring (dmi_protocol.ads: the DMI derives nothing): speeds in
   --  km/h to the nearest, the distance in m rounded down; the dial range
   --  (DMI 8.2.1.1.3, pre-configured on-board) the smallest that shows
   --  the ceiling EBI of the maximum train speed, 180 km/h without train
   --  data
   function To_Speed_State (S : EVC_Supervision_Input.Snapshot_T;
                            R : EVC_SDM.Result_T) return Speed_State_T
;

   --  The snapshot in use (Snapshot): the stored information's one, taken
   --  in place, unless the tests set theirs
   procedure Take_Snapshot
     with Global => (Input  => (Test_Snapshot_Set,
                                EVC_Stored_Information.State),
                     In_Out => Snapshot);

   --  4. Speed and distance monitoring (3.13, EVC_SDM) and the brake
   --  commands (3.14, EVC_Brake_Commands) on the snapshot the stored
   --  information built at the third step (or the tests' one), with the
   --  inputs of the train interface and the driver's acknowledgement of
   --  the cycle
   procedure Monitor_Speed_And_Distance (Dt_Ms : Natural)
     with Global => (Input  => (Test_Snapshot_Set, TIU_Now,
                                TIU_Value_Now, TIU_Known_Now, Brake_Ack_Now,
                                Current_Mode, EVC_Levels.State,
                                EVC_Position.State, EVC_Mission.State,
                                EVC_Stored_Information.State),
                     In_Out => (Snapshot, SDM_Work, SDM_State, Brake_State,
                                Brake_Output),
                     Output => (SDM_Result, Speed_State,
                                Ack_For_Protection));

   --  7f. 3.15.7: the safety reaction to the BTM alarm of the port, after
   --  the procedures and the mode machine (the inhibition of 5.22 and the
   --  mode of the cycle): decision (3.15.7.6.1), the reaction is a fault
   --  that affects safety, 4.6.3 [13] in the next cycle's mode machine
   --  (EVC_Procedures.BTM_Alarm_Failure), System Failure with its
   --  emergency brake (4.4.5.1.2), which the on-board keeps cycling to
   --  command and show. The distance of 3.15.7.2 is counted from where
   --  the alarm was raised (3.6.7.1 d), in either direction; it starts
   --  again with the next alarm
   --  @req 3.15.7.2, 3.15.7.4, 3.15.7.5, 3.15.7.6, 3.6.7.1 d), 5.22.4.2
   procedure Supervise_BTM_Alarm
     with Global => (Input  => (Latched_BTM_Alarm, Current_Mode, Proc_Ctx,
                                Snapshot, EVC_Track_Conditions.State,
                                EVC_Origins.State, EVC_Position.State,
                                EVC_Odometry.State),
                     In_Out => (BTM_Alarm_Run, EVC_Procedures.State));

end EVC_Core.Monitoring;
