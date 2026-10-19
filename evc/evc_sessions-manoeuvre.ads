--  ETCS on-board (EVC)
--  Phase E6, the session and link half: the procedure Supervised
--  Manoeuvre of 5.21 up to the RBC's answer (S0, E015, A045 the request,
--  message 131, S050 the wait with the repetitions of 5.21.4.1, the
--  answers 4 and 5 matched by their time stamp, 4.8.4 [14], A220 "SM
--  refused"). What message 4 authorises (the MA, C_81, the mode) is the
--  authority half's (EVC_Radio_Authority).
--
--  A private child of EVC_Sessions, its state a part of the parent's:
--  the parent calls it from its entry points and shows the system
--  status messages it asks for.
--
--  Decisions:
--  (1) S0 without a communication session with the Supervising RBC: the
--      request fails at once ("SM request failed"), as the request for
--      shunting of 5.6 does.
--  (2) A045: the position report is packet 0 of the on-board's position
--      (its front end as the train position has it); packet 12 with the
--      Train Data of the on-board (EVC_Train_Data) as the default Train
--      Data for Supervised Manoeuvre, sent when the mode is not SM (the
--      installation has no default set of its own yet).
--  (3) A mode change while the answer is awaited ends the request
--      without an indication (S0 holds no more).
--  (4) The answer byte of MSG_ONBOARD is this procedure's from a request
--      for Supervised Manoeuvre until the driver selects Shunting (the
--      DMI reads it in the frame that ends the wait 5).

with ETCS_Message_Catalogue; use ETCS_Message_Catalogue;
with EVC_Driver_Requests;
with EVC_Levels;
with EVC_Odometry;
with EVC_Position;
with EVC_Received;
with EVC_Train_Data;

--  @req 5.21.2.2 S0, 5.21.2.2 A045, 5.21.2.2 S050, 5.21.4.1
private package EVC_Sessions.Manoeuvre
  with SPARK_Mode => On,
       Abstract_State => (State with Part_Of => EVC_Sessions.State)
is

   procedure Clear
     with Global => (Output => State);

   --  S0, E015: the driver's selection of the cycle starts the request
   --  (Order_Stored: an RBC transition order is stored); S050, 5.21.4.1:
   --  the repetitions and their end. Status: the DMI system status entry
   --  to show (0 none)
   --  @req 4.4.21.1.3
   procedure Evaluate (Ctx          : EVC_Radio.Context_T;
                       Order_Stored : Boolean;
                       Status       : out Natural)
     with Global => (In_Out => State,
                     Input  => (EVC_Radio.State, EVC_Levels.State,
                                EVC_Position.State, EVC_Odometry.State,
                                EVC_Train_Data.State,
                                EVC_Driver_Requests.State)),
          Post => Status <= 255;

   --  4.8.4 [14], S050 E115 / E215: message 4 or 5 (Kind) of session S
   --  answers the pending request when its second T_TRAIN is the time
   --  stamp of the request (Matched); Refused: message 5, the driver to
   --  be told (A220); one not matched is not taken, nor its packet 45
   --  @req 4.8.4.2 Table-footnote [13], 4.8.4.2 Table-footnote [14]
   procedure Take_Answer (S       : EVC_Radio.Session_T;
                          Kind    : Message_Kind_T;
                          Matched : out Boolean;
                          Refused : out Boolean)
     with Global => (In_Out => State, Input => EVC_Received.Store),
          Post => (if Refused then Matched);

   --  (3)
   procedure Mode_Changed
     with Global => (In_Out => State);

   --  A045: message 131 when due
   procedure Produce (Ctx : EVC_Radio.Context_T)
     with Global => (In_Out => (State, EVC_Radio.State, EVC_Radio.Queue),
                     Input  => (EVC_Position.State, EVC_Odometry.State,
                                EVC_Levels.State, EVC_Train_Data.State));

   --  S050: the answer is awaited (MSG_ONBOARD waiting 5)
   function Waiting return Boolean
     with Global => State;

   --  the outcome of the last request: 1 authorised, 0 not; Latest: the
   --  last request of the driver was this one (decision 4)
   function Answer return Natural
     with Global => State,
          Post => Answer'Result <= 1;
   function Latest return Boolean
     with Global => State;

   --  the requests sent (message 131, repetitions included)
   function Sent_Count return Natural
     with Global => State;

end EVC_Sessions.Manoeuvre;
