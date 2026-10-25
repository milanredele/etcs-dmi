--  ETCS on-board (EVC)
--  The last step of the cycle, Produce_Outputs: the DMI frames (the
--  mode and level, the status, the on-board data, the texts and
--  indications), the TIU outputs, the radio messages drained to the
--  RTM port and the juridical records of the cycle's end. Writes
--  EVC_Outbox.Queue and the parent's "sent" state.

pragma Unevaluated_Use_Of_Old (Allow);

private package EVC_Core.Outputs
  with SPARK_Mode => On
is

   --  8a. JRU: the mode changed since the last report (event 1); the
   --  events of the levels (5.10, event 40) and of the mission (5.4,
   --  5.5, event 41) of the cycle
   procedure Record_Mode_Levels_Mission
     with Global => (Input  => (Current_Mode, Clock_Ms,
                                EVC_Levels.State, EVC_Mission.State,
                                EVC_Train_Data.State,
                                EVC_Driver_Requests.State),
                     In_Out => (Reported_Mode, EVC_Outbox.Queue));

   --  8b. DMI: the system status messages of the modes and of the
   --  protections of 3.14 (MSG_SYSTEM_STATUS): 4.4.15.1.1.3 the
   --  non-leading operation no longer permitted, 4.4.9.1.4 "Entering FS",
   --  4.4.12.1.7 "Entering OS"; 3.14.2.6, 3.14.3.4, 4.4.7.1.5.4 "Runaway
   --  movement"; 3.6.8.5, 3.6.8.6.2 "Odometer impaired"
   --  @req 3.6.8.5, 3.6.8.6.2, 3.18.3.3.1
   procedure Show_Mode_Indications
     with Global => (Input  => (Current_Mode, Brake_Output,
                                EVC_Mission.State, EVC_Odometry.State,
                                EVC_Stored_Information.State),
                     In_Out => (Entering_Shown, Runaway_Shown,
                                Odometer_Shown, EVC_Outbox.Queue));

   --  8b'. DMI: 3.12.2.4, the driver informed about every unsuitability
   --  of the route suitability data stored (the system status messages
   --  "Route unsuitable", 3.12.2.3 a) to c)), until its data are deleted
   --  @req 3.12.2.4
   procedure Show_Route_Unsuitable
     with Global => (Input  => (EVC_Track_Description.State,
                                EVC_Train_Data.State),
                     In_Out => (Unsuitable_Shown, EVC_Outbox.Queue));

   --  8b''. DMI: 3.16.2.4.9, the driver informed ("Trackside malfunction",
   --  the DMI's catalogue entry 3, 30 s from its start) when a balise
   --  group message taken in the cycle holds "default balise information"
   --  (packet 254). Decision: A.3.3.3, the message consistent (a group
   --  taken by EVC_Position is), the packet valid for the train's
   --  direction (Q_DIR) and accepted by the filters: 4.8.3 in every
   --  level, 4.8.4 not in NP, SF and IS, in SB only with a cab active
   --  (footnote [2]); the rest of the message is used as it is
   --  (3.16.2.4.9 asks only for the driver's information)
   --  @req 3.16.2.4.9
   procedure Show_Trackside_Malfunction
     with Global => (Input  => (Current_Mode, EVC_Position.State),
                     In_Out => EVC_Outbox.Queue);

   --  8c. DMI: the mode and the level (MSG_MODE_LEVEL; 4.4.2.1: a clear
   --  indication of the mode when the desk is open); 4.7.2: the
   --  acknowledgement of a mode proposed (the start of mission, 5.4.3.2
   --  S22 to S24) or asked by a procedure (5.7, 5.9, 5.11, 5.13, 5.19; the
   --  start of mission's first, which takes the driver's acknowledgement
   --  first), the level transition announced (5.10.1.3) and its
   --  acknowledgement (5.10.4), "override active" (5.8.3.7)
   --  @req 4.4.19.1.4
   procedure Send_Mode_Level
     with Global => (Input  => (Current_Mode, EVC_Levels.State,
                                EVC_Mission.State, EVC_Procedures.State,
                                EVC_Radio_Authority.State,
                                EVC_LS_Display.State),
                     In_Out => EVC_Outbox.Queue);

   --  8d. DMI: the system status messages of the procedures
   --  (the reason of a trip, 5.11; the reverse movement distances, 5.13;
   --  5.17), the text messages (3.12.3: shown with the hour and the
   --  minute of the on-board time, or removed)
   procedure Send_Procedure_Messages
     with Global => (Input  => (Clock_Ms, EVC_Procedures.State,
                                EVC_Text_Messages.State,
                                EVC_Sessions.State,
                                EVC_Radio_Authority.State),
                     In_Out => EVC_Outbox.Queue);

   --  The SUBSET-027 message of the I-th text message record of the
   --  cycle when it is the start or the stop of a display: 16 and 17
   --  with Q_TEXT for a fixed text, 18 and 19 with L_TEXT and X_TEXT for
   --  a plain one (4.2.4.16 to 4.2.4.19); the record 255 of event 24
   --  follows it with the message's id and the other kinds (4.1.1.5)
   procedure Record_Text_Display (I : Positive)
     with Global => (Input  => (Clock_Ms, EVC_Text_Messages.State),
                     In_Out => EVC_Outbox.Queue),
          Pre => I <= EVC_Text_Messages.Event_Count;

   --  8e. JRU: the records of the procedures of chapter 5
   --  (event 23) and of the text messages (3.12.3, event 24)
   procedure Record_Procedures
     with Global => (Input  => (Clock_Ms, EVC_Procedures.State,
                                EVC_Text_Messages.State),
                     In_Out => EVC_Outbox.Queue);

   --  8f. DMI: MSG_STATUS. SUBSET-026 3.6.6: the geographical position,
   --  while it is known, and once "unknown" when it stops (the DMI shows
   --  it on request); the brake indication (3.14.1.9, 3.14.2.6,
   --  3.14.3.4) and the time to Indication (3.13.10.3.10), whenever they
   --  change; the reversing possible (5.13), the tunnel stopping area
   --  (5.18.8). D, Text_SB, Text_EB: the brake demands of the procedures
   --  and of the text messages
   --  @req 3.5.7.1, 5.22.4.1
   procedure Send_Status (D                : EVC_Procedures.Brake_Demand_T;
                          Text_SB, Text_EB : Boolean)
     with Global => (Input  => (Current_Mode, Clock_Ms, Brake_Output,
                                SDM_Result, EVC_Levels.State,
                                EVC_Procedures.State,
                                EVC_Stored_Information.State,
                                EVC_Position.State, EVC_Sessions.State),
                     In_Out => (Geo_Sent, Status_Brake_Sent,
                                Status_TTI_Sent, Status_Rev_Sent,
                                Status_Slip_Sent, Status_BMM_Sent,
                                Status_SM_Sent,
                                Status_Tunnel_Sent, Status_Radio_Sent,
                                EVC_Outbox.Queue));

   --  The train bits of MSG_ONBOARD (dmi_protocol.ads): standstill and
   --  the speed not above the limit for triggering the override (5.8,
   --  Update_Position), the non-leading and passive shunting inputs
   --  (4.4.15, 4.4.20), the "BTM alarm reaction inhibition" (5.22.4.1)
   function Train_Bits return Bits_T
     with Global => (Standstill, Below_Override, TIU_Now,
                     EVC_Procedures.State);

   --  The national bits of MSG_ONBOARD: the room for a VBC and a VBC
   --  stored (3.15.9, DMI Table 36 #5, #6), the driver
   --  ID changeable while running (M_NVDERUN) and the adhesion by the
   --  driver (Q_NVDRIVER_ADHES), A.3.2
   function National_Bits return Bits_T
     with Global => (EVC_National_Values.State, EVC_VBC.State);

   --  The session byte of MSG_ONBOARD: a session established with the
   --  supervising RBC (2), or one being established (1, 3.5.3.8)
   --  and 3 when that session is the only one and the RBC's system version
   --  is above 2.2 (M_VERSION 2#010_0010#; DMI Table 33 #11)
   function Session_Byte return EVC_Bytes.Byte
     with Global => EVC_Radio.State;

   --  8g. DMI: MSG_ONBOARD (dmi_protocol.ads) every cycle, from what the
   --  on-board knows: the validity of the level, the position and the
   --  data of the start of mission (5.4), the train and national bits;
   --  the fields of the later phases are 0, "nothing known"
   --  @req 5.4.3.2 S21, 5.4.3.2 D2, 5.17.2.2 S6, 5.11.2.2 D130, 5.11.2.2 S130
   --  @req 5.11.2.2 S140
   procedure Send_Onboard
     with Global => (Input  => (Current_Mode, Standstill, Below_Override,
                                 TIU_Now,
                                EVC_Procedures.State,
                                EVC_National_Values.State,
                                EVC_Levels.State, EVC_Position.State,
                                EVC_Mission.State, EVC_Train_Data.State,
                                EVC_Radio_Authority.State,
                                EVC_Radio.State, EVC_Sessions.State,
                                EVC_Odometry.State, EVC_VBC.State),
                     In_Out => EVC_Outbox.Queue);

   --  SUBSET-026 3.18.4.3.6.2: the list of GSM-R
   --  networks offered to the driver, in the cycle the driver elected
   --  to modify the network (DMI MSG_RADIO_NETWORKS)
   --  @req 3.18.4.3.6.2
   procedure Send_Networks
     with Global => (Input  => (EVC_Radio.State, EVC_Sessions.State),
                     In_Out => EVC_Outbox.Queue);

   --  3.15.9: the Virtual Balise Covers stored, to the DMI's data view
   --  when the store changed (DMI MSG_VBC_LIST, DMI Table 45)
   procedure Send_VBC_List
     with Global => (In_Out => (EVC_VBC.State, EVC_Outbox.Queue));

   --  DMI 11.7.1.4: the RBC contact stored on-board (3.18.4.3,
   --  EVC_Radio.Contact), sent to the DMI when it changes (from none
   --  stored at the power-up), so that the RBC data window proposes it
   --  (the DMI opens the window itself: the on-board does not learn
   --  when). Its status
   --  goes with MSG_ONBOARD; a change of the status alone is not sent.
   --  Decision: NID_C 1023 with NID_RBC 16383 ("contact last known RBC",
   --  7.5.1.96) is no RBC ID the window can show (16 777 215, above
   --  A.3.11): sent as no contact stored
   --  @req 3.18.6.1
   procedure Send_RBC_Contact
     with Global => (Input  => EVC_Radio.State,
                     In_Out => (Contact_Sent, EVC_Outbox.Queue));

   --  3.18.6.1: the Driver ID, the train running number, the Train
   --  Data and the GSM-R network ID stored on-board, sent to the DMI when
   --  any of them changes (the first cycle included), so that its data
   --  view shows them whoever wrote them (the driver, the RBC, the train
   --  interface, the store over No Power) and after a restart of the
   --  DMI; their status goes with MSG_ONBOARD
   --  @req 3.18.6.1
   procedure Send_Stored_Values
     with Global => (Input  => (EVC_Mission.State, EVC_Train_Data.State,
                                EVC_Radio.State),
                     In_Out => (Stored_Sent, Values_Sent,
                                EVC_Outbox.Queue));

   --  MSG_SYSTEM_VERSION: the operated system version X.Y (3.17.2.1.1)
   --  for the DMI's System version window (DMI 11.5.2), sent at the
   --  start and again when the operated X changes (Y follows from X)
   procedure Send_System_Version
     with Global => (Input  => EVC_System_Version.State,
                     In_Out => (Version_Sent, EVC_Outbox.Queue));

   --  The commands of the TIU output (EVC_Ports): the speed and distance
   --  monitoring and the protections (3.13, 3.14); the service brake of
   --  5.10.4.2 (the levels), in SF the emergency brake,
   --  permanently (4.4.5.1.2), the brakes of the procedures and of the
   --  text messages (D, Text_SB, Text_EB); in IS no command (4.4.3.1.1)
   function TIU_Commands (D                : EVC_Procedures.Brake_Demand_T;
                          Text_SB, Text_EB : Boolean)
     return EVC_Bytes.Byte
     with Global => (Current_Mode, Brake_Output, EVC_Levels.State);

   --  The reasons of the TIU output, each its bit (EVC_Ports), the same
   --  sources as TIU_Commands; none in IS (4.4.3.1.1)
   function TIU_Reasons (D                : EVC_Procedures.Brake_Demand_T;
                         Text_SB, Text_EB : Boolean)
     return TIU_Reasons_T
     with Global => (Current_Mode, Brake_Output, EVC_Levels.State);

   --  8h. The speed and distance monitoring and the brake commands
   --  (3.13, 3.14): MSG_SPEED_STATE every cycle; the JRU records
   --  of what changed (events 20 the brake commands, 21 the supervision
   --  or any of the information displayed to the driver (record 20 of
   --  SUBSET-027 4.2.3, 4.2.4.20; at most one a cycle), 22 an overrun of
   --  the EOA or the SvL); the commands to the train
   --  interface (the TIU output) when they change, and every cycle while
   --  a command is given. D, Text_SB, Text_EB: as Send_Status.
   procedure Send_Supervision
     (D                : EVC_Procedures.Brake_Demand_T;
      Text_SB, Text_EB : Boolean)
     with Global => (Input  => (Current_Mode, Clock_Ms,
                                SDM_Result, Brake_Output, Speed_State,
                                Status_TTI_Sent, EVC_Levels.State),
                     In_Out => (TIU_Sent, TIU_Reasons_Sent,
                                Supervision_Reported, SDM_Shown_Reported,
                                Overrun_Reported, EVC_Outbox.Queue));

   --  5.20.2.4: a distance, cm, within the i32 range below TIU_TC_None,
   --  or TIU_TC_None when Present is False, little endian at Last + 1
   procedure Put_I32 (Frame   : in out TIU_TC_Frame_T;
                      Last    : in out Natural;
                      Present : Boolean;
                      V       : EVC_Distances.Dist_T)
     with Global => null,
          Pre  => Last <= TIU_Out_Max_Length - 4,
          Post => Last = Last'Old + 4;

   --  8i. TIU (5.20): the information for an external function
   --  (EVC_Ports, the TIU track condition output), every cycle while an
   --  item is generated and once when none is any more
   procedure Send_External_Info
     with Global => (Input  => EVC_Stored_Information.State,
                     In_Out => (TC_Sent, EVC_Outbox.Queue));

   --  8j. TIU: the remote shunting information (EVC_Ports.TIU_RS_Tag),
   --  when it changes: in Shunting the on-board is ready for remote
   --  shunting (4.4.8.1.4); in Supervised Manoeuvre too, with the engine
   --  orientation the same as or opposite to the direction of its
   --  Movement Authority (4.4.21.1.13: the train orientation of the
   --  authorisation against the active cab's side,
   --  EVC_Position.Manoeuvre_Direction; no active cab, "the same").
   --  Decision: the mode is the condition, the clauses name none other
   --  @req 4.4.8.1.4, 4.4.21.1.13
   procedure Send_Remote_Shunting
     with Global => (Input  => (Current_Mode, EVC_Position.State),
                     In_Out => (TIU_RS_Sent, EVC_Outbox.Queue));

   --  8l. RTM: the messages and requests of the session half,
   --  then of the authority half (EVC_Radio.Send), moved to the RTM port
   --  as far as they fit (EVC_Radio.Drain)
   procedure Send_Radio
     with Global => (Input  => (Current_Mode, Clock_Ms,
                                EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Train_Data.State,
                                EVC_Track_Conditions.State,
                                EVC_Text_Messages.State, EVC_Mission.State),
                     In_Out => (EVC_Sessions.State,
                                EVC_Radio_Authority.State, EVC_Radio.State,
                                EVC_Radio.Queue, EVC_Outbox.Queue));

   --  8. Produce the outputs of the cycle, port by port in this order
   --  (the goldens are their byte stream)
   --  @req 3.6.6.1, 4.4.2.1, 4.4.5.1.2
   procedure Produce_Outputs
     with Global => (Input  => (Current_Mode, Clock_Ms,
                                UTC_Known, UTC_Seconds,
                                EVC_System_Version.State, EVC_Config.State,
                                Standstill, Below_Override, TIU_Now,
                                TIU_Known_Now, TIU_Value_Now,
                                EVC_National_Values.State,
                                EVC_Position.State,
                                SDM_Result, Brake_Output, Speed_State,
                                EVC_Levels.State, EVC_Mission.State,
                                EVC_Train_Data.State,
                                EVC_Stored_Information.State,
                                EVC_Procedures.State,
                                EVC_Text_Messages.State,
                                EVC_LS_Display.State,
                                EVC_Driver_Requests.State,
                                EVC_Odometry.State,
                                EVC_Track_Conditions.State,
                                EVC_Track_Description.State),
                     In_Out => (Reported_Mode, Geo_Sent, EVC_Outbox.Queue,
                                General_Ms, General_Version, General_Level,
                                General_Mode, Started_Up,
                                EVC_JRU_Records.State,
                                Status_Brake_Sent, Status_TTI_Sent,
                                TIU_Sent, TIU_Reasons_Sent, TIU_RS_Sent,
                                Supervision_Reported, SDM_Shown_Reported,
                                Overrun_Reported,
                                Entering_Shown, Runaway_Shown,
                                Odometer_Shown, Unsuitable_Shown,
                                Status_Rev_Sent, Status_Slip_Sent,
                                Status_BMM_Sent, Status_SM_Sent,
                                Status_Tunnel_Sent,
                                Status_Radio_Sent, TC_Sent, EVC_Sessions.State,
                                Contact_Sent, Version_Sent,
                                Stored_Sent, Values_Sent,
                                EVC_Radio_Authority.State,
                                EVC_Radio.State, EVC_Radio.Queue,
                                EVC_VBC.State));

end EVC_Core.Outputs;
