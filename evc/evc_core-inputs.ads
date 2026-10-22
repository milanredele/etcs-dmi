--  ETCS on-board (EVC)
--  The first step of the cycle: what the hosts latched since the last
--  cycle (Latch_RTM, Latch_SCL from Handle_Input) is read by Read_Ports
--  in the order the ports delivered it: the telegrams to the position,
--  the radio events and messages to the sessions, the released messages
--  to the authority, the driver's VBC requests. Writes the latched
--  slots and counters of the parent, EVC_Received, EVC_Position,
--  EVC_Sessions and what the ports' readers own.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Acceptance;
private package EVC_Core.Inputs
  with SPARK_Mode => On
is

   --  An RTM input of the documented shape (EVC_Ports): a connection
   --  event or a message, latched with its session for the next cycle
   procedure Latch_RTM (Payload : EVC_Bytes.Byte_Array)
     with Global => (In_Out => (Latched_RTM, Latched_RTM_Count,
                                Latched_Events, Latched_Event_Count,
                                Overflow_Count)),
          Pre => Valid_RTM_Input (Payload);

   --  A TIU input of the safe consist length, latched for Read_Ports
   --  (its lengths when available, EVC_Ports.Valid_TIU_SCL)
   procedure Latch_SCL (Payload : EVC_Bytes.Byte_Array)
     with Global => (Output => Latched_SCL_Fresh, In_Out => Latched_SCL),
          Pre => Valid_TIU_SCL (Payload);

   --  1b. The telegrams latched since the last cycle, in the order the
   --  BTM delivered them: parsed (EVC_Received, chapter 7, 8), those
   --  accepted recorded on the JRU port (event 2, the balise group,
   --  NID_C and NID_BG) and handed, with the stamp of their balise, to
   --  the position (EVC_Position, 3.6, which takes them at its next
   --  Update: the reference and the confidence interval do not change
   --  here); 3.17.3.5, 4.6.3 [65]: a telegram of a system version not
   --  supported noted for the procedures. 3.17.3.5: X = 0 (a) and an X of
   --  the envelope without a layout (c: X = 1, chapter 6) refused by the
   --  decoder, their content left out, no reaction; X above the highest
   --  (d, e) the trip of [65] in levels 1 and 2 only (EVC_Procedures).
   --  3.17.3.11 a): an unknown packet passed over by the decoder.
   --  Decision (3.17.3.5 b): the lowest X of the envelope is 1, so no X
   --  other than 0 is below it.
   --  @req 3.17.3.5, 3.17.3.5 a), 3.17.3.5 c), 3.17.3.5 d), 3.17.3.5 e)
   --  @req 3.17.3.11 a)
   procedure Read_Telegrams
     with Global => (Input  => (Latched_BTM, Clock_Ms,
                                EVC_Odometry.State, EVC_VBC.State),
                     In_Out => (Latched_BTM_Count, EVC_Received.Store,
                                EVC_Outbox.Queue, EVC_Position.State,
                                EVC_Procedures.State)),
          Post => EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  1c. The connection events of the RTM port latched since the last
   --  cycle, in their order, to the session and link half
   procedure Read_Radio_Events
     with Global => (Input  => (Latched_Events, Clock_Ms),
                     In_Out => (Latched_Event_Count, EVC_Sessions.State,
                                EVC_Radio.State));

   --  The message 9 (SUBSET-027 4.2.4.9): the RBC of the session and the
   --  message as received
   procedure Put_From_RBC (Slot : RTM_Slot_T)
     with Global => (Input  => (Clock_Ms, EVC_Radio.State),
                     In_Out => EVC_Outbox.Queue);

   --  JRU record 13 (EVC_JRU_Records) for a radio
   --  message found inconsistent and reported (3.16.3.1.1.2)
   --  @req 3.16.3.1.1.2
   procedure Record_Radio_Error
     with Global => (Input  => (EVC_Sessions.State, EVC_Radio.State,
                                Clock_Ms),
                     In_Out => EVC_Outbox.Queue);

   --  1d. The radio messages latched since the last cycle, in the order
   --  the RTM delivered them: recorded on the JRU port (event 3:
   --  NID_MESSAGE, L_MESSAGE), parsed (EVC_Received, chapter 8)
   --  and given, with their session, to the session and link half; the
   --  messages it passes go on to the authority half
   --  @req 3.6.5.1.4 l), 3.16.3.1.1.2, 3.17.3.11, 3.17.3.11 b), 3.17.3.11 c)
   procedure Read_Radio_Messages
     with Global => (Input  => (Latched_RTM, Clock_Ms, Current_Mode,
                                EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State),
                     In_Out => (Latched_RTM_Count, EVC_Received.Store,
                                EVC_Mission.State,
                                EVC_Outbox.Queue, EVC_Sessions.State,
                                EVC_Radio.State,
                                EVC_Radio_Authority.State,
                                EVC_Origins.State, EVC_Radio_Info.State));

   --  1e. 4.8.5: the messages the transition buffer of the
   --  session half releases, parsed again (in the first slot of the
   --  latch, free now) and given to the authority half as received in
   --  this cycle; at most RTM_Latch_Size in a cycle
   --  @req 4.8.5.5, 4.8.5.6 a), 3.18.4.5.3
   procedure Read_Released_Messages
     with Global => (Input  => (Clock_Ms, EVC_Position.State,
                                EVC_Odometry.State, Current_Mode),
                     In_Out => (Latched_RTM, EVC_Received.Store,
                                EVC_Mission.State,
                                EVC_Sessions.State,
                                EVC_Radio_Authority.State,
                                EVC_Origins.State, EVC_Radio_Info.State));

   --  1a. The Virtual Balise Covers of the cycle, before the telegrams:
   --  the periods elapsed (3.15.9.5 b), from the reception or the entry,
   --  3.15.9.6), then the driver's Set VBC and Remove VBC (DMI 11.3.12.5,
   --  11.3.13.5: the codes split as MSG_DRIVER_DATA carries them), each
   --  with its juridical record (SUBSET-027 4.2.4.28, 4.2.4.29: the code
   --  entered, also when the mode does not take it).
   --  Decision (3.15.9.2): taken in SB only, the mode of the start of
   --  mission where the DMI offers them (DMI Table 36 #5, #6).
   --  @req 3.15.9.2, 3.15.9.5 c)
   procedure Take_VBC_Requests
     with Global => (Input  => (Clock_Ms, Current_Mode,
                                EVC_Driver_Requests.State),
                     In_Out => (EVC_VBC.State, EVC_Outbox.Queue));

   --  1. Read the ports: take the inputs latched since the last cycle,
   --  parse the telegrams and radio messages (EVC_Received) and record
   --  those accepted on the JRU port; hand the telegrams accepted, with
   --  the stamp of their balise, to the position
   procedure Read_Ports
     with Global => (Input  => (Latched_Odometer, Latched_TIU, Latched_BTM,
                                Latched_SCL, Clock_Ms, Current_Mode,
                                EVC_Odometry.State, Latched_TIU_Value,
                                Latched_TIU_Known, Latched_Events),
                     Output => (Odometer_Now, Odometer_Fresh, TIU_Now,
                                TIU_Value_Now,
                                TIU_Known_Now, Brake_Ack_Now,
                                EVC_Train_Inputs.State),
                     In_Out => (Latched_Odometer_Fresh,
                                Latched_Brake_Ack, Latched_Integrity,
                                Latched_SCL_Fresh, EVC_Train_Data.State,
                                Latched_BTM_Count,
                                Latched_RTM, Latched_RTM_Count,
                                Latched_Event_Count, EVC_Received.Store,
                                EVC_Outbox.Queue, EVC_Position.State,
                                EVC_Driver_Requests.State, EVC_Mission.State,
                                EVC_Levels.State, EVC_Procedures.State,
                                EVC_Sessions.State, EVC_Radio.State,
                                EVC_Radio_Authority.State,
                                EVC_Origins.State, EVC_Radio_Info.State,
                                EVC_VBC.State)),
          Post => EVC_Driver_Requests.Isolation_Selected
                    = EVC_Driver_Requests.Isolation_Latched'Old
                  and then not EVC_Driver_Requests.Isolation_Latched
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Manoeuvre_Orientation
                             = EVC_Position.Manoeuvre_Orientation'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  4.8: the context of the filters in the cycle, for the
   --  information the position takes itself (the linking) and the
   --  information of the procedures and the text messages
   function Acceptance_Context return EVC_Acceptance.Context_T
     with Global => (Current_Mode, EVC_Levels.State, EVC_Train_Inputs.State,
                     EVC_Train_Data.State, EVC_Mission.State);

   --  4.8.3 [1]: the context of a group
   --  whose own packet 41 orders level 1 at a further location
   function Ordered_Context return EVC_Acceptance.Context_T
     with Global => (Current_Mode, EVC_Levels.State, EVC_Train_Inputs.State,
                     EVC_Train_Data.State, EVC_Mission.State);

end EVC_Core.Inputs;
