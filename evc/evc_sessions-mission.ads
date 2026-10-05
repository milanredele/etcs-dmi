--  ETCS on-board (EVC)
--  Phase E5, the session and link half, phase 2 (e5/session-3): the
--  level 2 parts of the start of mission (5.4.3.2: the RBC contact and
--  its status of 5.4.3.3, A31 the session opened, D31 / A32, the SoM
--  position report of D32 / A33 / A34 and the RBC's answers A35, D34 /
--  A24, D35 / A39 / A40), the Train Data sent to the RBC (3.18.3.4,
--  repeated until acknowledged, 3.18.3.4.1 and 3.18.3.4.2) and the end
--  of mission (5.5.3.1.3, 5.5.3.1.4, 5.5.4.1).
--
--  A private child of EVC_Sessions, its state a part of the parent's:
--  the parent calls it from its entry points and does what it asks
--  (Request_T: open or terminate a session, show a status message).
--
--  Decisions (doc/EVC-PLAN.md §13, session and link, phase 2):
--  (1) D7 and the radio networks: the session is opened at D7 (stored
--      level 2, position and level valid) with the stored contact when
--      one is known; with none the driver's entry (S3) opens it. The
--      Radio Network type and registration of D7 / S4 are not modelled
--      (3.5.6 is left): the network is taken as registered.
--  (2) The Train Data of the start of mission go in the SoM position
--      report (A33 / A34, packet 11) when they are valid then; message 8
--      acknowledges them as it does message 129 (D15).
--  (3) Message 8 acknowledges the Train Data when its second T_TRAIN
--      (8.7.4 field 6) is the T_TRAIN of the message that carried them.
--  (4) The Train Data are repeated every 15 s ("waiting time before
--      radio message repetition", A.3.1) until acknowledged, without a
--      limit: an RBC that never acknowledges keeps the train at S11.
--  (5) D34 / D35 "a valid train position referred to an unlinked balise
--      group": the position status is Valid while the report did not say
--      "valid referred to an LRBG" (the status is kept), else it is
--      deleted (A24, A39).
--  (6) N_AXLE of packet 11 is 0 and M_AIRTIGHT 0 (not fitted): the
--      installation data have neither yet (EVC_Config, E6).

with ETCS_Message_Catalogue; use ETCS_Message_Catalogue;
with EVC_Driver_Requests;
with EVC_Levels;
with EVC_Mission;
with EVC_Odometry;
with EVC_Position;
with EVC_Received;
with EVC_Train_Data;

private package EVC_Sessions.Mission
  with SPARK_Mode => On,
       Abstract_State => (State with Part_Of => EVC_Sessions.State)
is

   --  What the parent does for the procedure in the cycle
   type Request_T is record
      --  A31: establish a session with RBC on Radio, the three attempts
      --  of A.3.1 (Capped)
      Open      : Boolean := False;
      RBC       : EVC_Radio.RBC_Id_T := EVC_Radio.No_RBC;
      Radio     : ETCS_Variables.NID_RADIO_T := 0;
      --  A40, 5.5.4.1.1: terminate this session
      Stop      : Boolean := False;
      Session   : EVC_Radio.Session_T := 1;
      --  A40: "Train is rejected" (DMI entry 20) to show
      Rejected  : Boolean := False;
   end record;

   procedure Clear
     with Global => (Output => State);

   --  1. The messages of the procedure received on S (8, 40, 41, 43):
   --  Taken when Kind is one of them
   procedure Take_Answer (S     : EVC_Radio.Session_T;
                          Kind  : Message_Kind_T;
                          Taken : out Boolean)
     with Global => (In_Out => (State, EVC_Radio.State),
                     Input  => (EVC_Received.Store, EVC_Position.State));

   --  5. The steps of the cycle
   procedure Evaluate (Ctx : EVC_Radio.Context_T; Req : out Request_T)
     with Global => (In_Out => (State, EVC_Radio.State),
                     Input  => (EVC_Mission.State, EVC_Levels.State,
                                EVC_Position.State, EVC_Train_Data.State,
                                EVC_Driver_Requests.State));

   --  6. 5.5.2: the end of mission by the mode entered
   procedure Mode_Changed (From, To : EVC_Modes.Mode_T)
     with Global => (In_Out => State,
                     Input  => (EVC_Mission.State, EVC_Radio.State));

   --  8. The messages of the cycle: 157, 129, 150
   procedure Produce (Ctx : EVC_Radio.Context_T)
     with Global => (In_Out => (State, EVC_Radio.State, EVC_Radio.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Train_Data.State));

   --  A35 (the RBC confirmed the position) and A24 / A39 (to delete it)
   --  in this cycle, for EVC_Core (EVC_Position); cleared by Produce
   function Position_Confirmed return Boolean
     with Global => State;
   function Position_To_Delete return Boolean
     with Global => State;

   --  A31 / D31: the session of the start of mission is being opened
   --  (MSG_ONBOARD waiting 2)
   function Opening return Boolean
     with Global => State;

   --  For the tests: the Train Data sent (129 or 157 with packet 11),
   --  the SoM position reports and the End of Mission messages sent
   function Train_Data_Sent return Natural
     with Global => State;
   function Reports_Sent return Natural
     with Global => State;
   function EoM_Sent return Natural
     with Global => State;

end EVC_Sessions.Mission;
