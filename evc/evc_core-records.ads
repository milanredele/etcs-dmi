--  ETCS on-board (EVC)
--  The juridical records of the core: the records every step writes
--  through Put_Event and its kin, and the records of the cycle's end
--  (the general, the inputs, the actions and cabs, the juridical
--  flush) that Produce_Outputs calls. Writes EVC_Outbox.Queue and the
--  "reported" state of the parent; reads the rest.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Train_Packets.P0;
with EVC_JRU_Messages;

private package EVC_Core.Records
  with SPARK_Mode => On
is

   --  SUBSET-027 4.2.4.3 and 4.2.4.4: M_BRAKE_COMMAND_STATE of the
   --  emergency and of the service brake command (bits 0 and 1 of the
   --  TIU commands), 4.2.4.43: M_TCO_COMMAND_STATE of the traction cut-off
   --  (bit 2, SUBSET-034 2.4.9), each when it differs from Before.
   --  Decision: at every change of the command sent, the first at the
   --  first command after the power-up (the sequences record 0 at the
   --  release in FS, never at the start); a state never commanded has no
   --  record, as for the brakes
   --  @req 3.20.1.2
   procedure Put_Brake_States (Commands, Before : EVC_Bytes.Byte)
     with Global => (Input => Clock_Ms, In_Out => EVC_Outbox.Queue);

   --  The juridical message of an event of EVC_Ports and its three bytes
   --  (EVC_JRU_Messages.Event_Message), kept with the on-board time of
   --  the event; the message of EVC_JRU_Messages.Paired_Message before
   --  it (a mode change is the general message too, SUBSET-027 4.3.1.1,
   --  before the proprietary one with the level status)
   procedure Put_Event (Event, B2, B3, B4 : EVC_Bytes.Byte)
     with Global => (Input => Clock_Ms, In_Out => EVC_Outbox.Queue);

   --  The juridical message of an event of the mission (EVC_Ports event
   --  41): the train running number (SUBSET-027 4.2.4.49), the SR speed
   --  and distance the driver entered (4.2.4.25; decision: the national
   --  values of an override, 4.4.11.1.3.1 a), are not entered by the
   --  driver and keep the proprietary message) and the Train Data
   --  (4.2.4.2) with their bodies, every other kind as Put_Event
   procedure Put_Mission_Event (E : EVC_Mission.Event_T)
     with Global => (Input  => (Clock_Ms, EVC_Mission.State,
                                EVC_Train_Data.State,
                                EVC_Driver_Requests.State),
                     In_Out => EVC_Outbox.Queue);

   --  The message 13 (SUBSET-027 4.2.4.13) with M_ERROR; decision: the
   --  RBC is the Supervising RBC (EVC_Radio), the error concerns the
   --  safe radio connection with it (3.16.3.1.1.2, 3.16.3.4)
   procedure Put_Radio_Error (M_Error : EVC_Bytes.Byte)
     with Global => (Input  => (Clock_Ms, EVC_Radio.State),
                     In_Out => EVC_Outbox.Queue);

   --  The message 20 (SUBSET-027 4.2.4.20) of the information as
   --  displayed (SDM_Shown_T) in the monitoring and status of the cycle:
   --  V_TARGET and D_TARGET "none" (1023, 32767) where the DMI shows no
   --  target, V_RELEASE "none" while not shown, the speeds at most 600
   procedure Put_SDM (Shown : SDM_Shown_T; Release_Shown : Boolean)
     with Global => (Input  => (Clock_Ms, SDM_Result),
                     In_Out => EVC_Outbox.Queue);

   --  0. The installation configuration loaded or refused since the last
   --  cycle (Configure): event 33 (EVC_Ports)
   procedure Report_Configuration
     with Global => (Input  => (Clock_Ms),
                     In_Out => (EVC_Config.State, EVC_Outbox.Queue)),
          Post => EVC_Config.Current = EVC_Config.Current'Old
                  and then EVC_Config.Loaded = EVC_Config.Loaded'Old;

   --  JRU (SUBSET-027 4.3.1.1): the general message every 5 s, when the
   --  operated system version changes and when the level changes (a
   --  mode change writes it with its event, Put_Event); at the start-up,
   --  the first cycle after Initialise or Power_Up, the information from
   --  the cold movement detector (4.2.4.15: no cold movement, or no
   --  information; a cold movement detected is the position's event 9)
   --  and the brake and traction interface configuration (4.2.4.47).
   --  Decision: "every 5 s" is 5 s after the last general message, so
   --  that two general messages are never more than 5 s apart
   procedure Record_General
     with Global => (Input  => (Clock_Ms, Current_Mode, EVC_Levels.State,
                                EVC_System_Version.State, EVC_Config.State,
                                EVC_Odometry.State),
                     In_Out => (General_Ms, General_Version, General_Level,
                                General_Mode, Started_Up, EVC_Outbox.Queue));

   --  SUBSET-027 4.2.4.23, 4.3.1.1: the message 23 when a system status
   --  message appears or disappears, from the events of the cycle's DMI
   --  frames (EVC_Outbox.Status_Event) and the driver's acknowledgements
   --  of a system status message (16#8000# + its catalogue entry)
   procedure Record_System_Status
     with Global => (Input  => (Clock_Ms, EVC_Driver_Requests.State),
                     In_Out => (EVC_JRU_Records.State, EVC_Outbox.Queue));

   --  8j. JRU (SUBSET-027 4.2.4.11, 4.2.4.38, 4.2.4.45, EVC_JRU_Records):
   --  the driver's actions of the cycle no other event records, the cab
   --  status received from the train interface when it changed, the
   --  items of the information for the external functions (5.20) that
   --  appeared or changed their phase
   procedure Record_Actions_Cabs_Conditions
     with Global => (Input  => (Clock_Ms, TIU_Now,
                                TIU_Known_Now,
                                EVC_Driver_Requests.State,
                                EVC_Stored_Information.State),
                     In_Out => (EVC_JRU_Records.State, EVC_Outbox.Queue));

   --  8k. JRU (SUBSET-027 4.2.4.24, .30 to .32, .39, .48, .50, .51,
   --  EVC_JRU_Records): the sleeping, passive shunting and non leading
   --  inputs and the direction controller of the train interface and the
   --  output permitting remote shunting, the one Send_Remote_Shunting
   --  sent to the train interface this cycle (SH and SM, SUBSET-026
   --  4.4.8.1.4, 4.4.21.1.13), when they change; the RBC contact and
   --  the GSM-R network the driver entered; record 13 with M_ERROR 5,
   --  safe radio connection error, when the reaction to the expiry of
   --  T_NVCONTACT is triggered (SUBSET-026 3.16.3.4)
   procedure Record_Inputs_Radio_Data
     with Global => (Input  => (Clock_Ms, TIU_RS_Sent,
                                TIU_Now, TIU_Known_Now, TIU_Value_Now,
                                EVC_Driver_Requests.State,
                                EVC_Sessions.State, EVC_Radio.State),
                     In_Out => (EVC_JRU_Records.State, EVC_Outbox.Queue));

   --  A location reference of the header of SUBSET-027 4.2.3.5 from the
   --  fields of the position report (EVC_Position.Position_Report)
   function Reference_Of (P : ETCS_Train_Packets.P0.Packet_T)
     return EVC_JRU_Messages.Reference_T
     with Global => null;

   --  The SOLR where it is not the LRBG: its identity, the estimated
   --  front end and the doubts against it in metres, the orientation of
   --  the train and the side of the front end against the SOLR's
   --  direction as the position report codes them against the LRBG
   --  (Q_DIRLRBG, Q_DLRBG, SUBSET-026 7.5.1.104, 7.5.1.106), unknown (2)
   --  where the SOLR has no direction (a single group, 3.4.2.3) or the
   --  train's orientation is not known
   function SOLR_Reference return EVC_JRU_Messages.Reference_T
     with Global => (EVC_Position.State, EVC_Odometry.State);

   --  8m. The juridical messages of the cycle (EVC_Outbox.Flush_JRU) with
   --  the header of SUBSET-027 4.2.3 at the end of the cycle (4.1.1.2:
   --  the position and speed, the operated version, level and mode at
   --  the event, the cycle of the event): the position as the position
   --  report gives it, the LRBG the SOLR (Q_LRBG 1) unless the SOLR is
   --  another group (Q_LRBG 2), V_TRAIN in km/h, the driver ID ("?" x 16
   --  while unknown), NID_ENGINE, M_VERSION, M_LEVEL, M_MODE
   procedure Flush_Juridical
     with Global => (Input  => (Current_Mode, UTC_Known, UTC_Seconds,
                                EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Mission.State,
                                EVC_Radio.State, EVC_System_Version.State),
                     In_Out => EVC_Outbox.Queue);

end EVC_Core.Records;
