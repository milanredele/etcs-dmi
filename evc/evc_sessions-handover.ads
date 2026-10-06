--  ETCS on-board (EVC)
--  Phase E5 (e5/handover): the RBC/RBC handover of 3.15.1.3 and 5.15.1,
--  the on-board's half. The RBC transition order (packet 131, by balise
--  or by the supervising RBC) is kept here; the session with the
--  Accepting RBC is opened beside the Handing Over one (3.15.1.3.1 a),
--  3.5.3.5.2.1), it gets the Train Data (3.15.1.3.3) and the position
--  reports (3.15.1.3.4); at the border (the max safe front end, 5.15.1.4)
--  or at once (an order with D_RBCTR 0) the Accepting RBC becomes the
--  supervising one and its contact the valid one (3.15.1.3.5, .7); the
--  Handing Over session is retained (3.15.1.3.8) until its RBC
--  terminates it, or until the reports of 3.15.1.3.9 run out.
--
--  A private child of EVC_Sessions, its state a part of the parent's.
--  The parent applies the requests (Open, Establish, Terminate_Session
--  are its own); EVC_Position watches the border (Set_Border); the
--  messages of the Accepting RBC before the switch go to the transition
--  buffer of the authority half (4.8.2.1 c), 4.8.5.2), released when the
--  roles change.
--
--  Decisions (doc/EVC-PLAN.md §13, "RBC handover"):
--  (1) A new order replaces the stored one (3.15.1.3.2.2). With another
--      Accepting RBC while the second session is in use by the current
--      Accepting RBC, that session is terminated (3.15.1.3.2.3) and the
--      new one opened once it is free (Open waits, Pending).
--  (2) One session only (EVC_Config Radio.Sessions = 1): the exception
--      of 3.15.1.3.2; the session with the Accepting RBC is set up once
--      the Handing Over one is over after the border (the GSM-R
--      conditions a) to d) taken as fulfilled; 3.5.6.6 is the radio
--      network registration's).
--  (3) The switch takes place in the cycle after the border: the border
--      report of that cycle went to both RBCs (3.15.1.3.5).
--  (4) 3.15.1.3.9 uses the fixed values of A.3.1 the parent uses for
--      the radio messages: 15 s, 3 repetitions.
--  (5) The order is deleted per 4.10 by the parent's callers (Delete);
--      a session with the Accepting RBC that is no longer one keeps
--      running until its RBC or a later order ends it.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Variables;     use ETCS_Variables;
with EVC_Balise_Groups;
with EVC_Distances;
with EVC_Odometry;
with EVC_Position;

private package EVC_Sessions.Handover
  with SPARK_Mode => On,
       Abstract_State => (State with Part_Of => EVC_Sessions.State)
is

   procedure Clear
     with Global => (Output => State);

   --  3.15.1.3.1, 3.15.1.3.2.2: an RBC transition order: the Accepting
   --  RBC and its number, the border D from the group Ref (D 0: at once,
   --  3.15.1.3.7)
   procedure Take_Order (RBC   : EVC_Radio.RBC_Id_T;
                         Radio : NID_RADIO_T;
                         Ref   : EVC_Balise_Groups.Identity_T;
                         D     : EVC_Distances.Length_T)
     with Global => (In_Out => State);

   --  4.10 (the rows of the RBC transition order): the order deleted;
   --  4.8.5.4 b) follows (the Accepting role cleared)
   procedure Delete
     with Global => (In_Out => (State, EVC_Radio.State)),
          Post => EVC_Radio.Sessions = EVC_Radio.Sessions'Old;

   --  4.8.3 [14], 3.5.3.5.2.1: RBC is the Accepting RBC of the order
   function Ordered (RBC : EVC_Radio.RBC_Id_T) return Boolean
     with Global => State;

   --  A stored order (for the tests)
   function Order_Stored return Boolean
     with Global => State;

   --  3.15.1.3.5, 3.15.1.3.8: the Handing Over session retained after
   --  the switch (No_Session when none)
   function Old return EVC_Radio.Session_Ref_T
     with Global => State;

   --  3.15.1.3.8: the contact of the Handing Over RBC retained
   function Old_Contact return EVC_Radio.RBC_Contact_T
     with Global => State;

   --  4.8.2.1 c), 3.15.1.3.6: a message on S is the Accepting RBC's
   --  while the Handing Over RBC supervises
   function Held (S : EVC_Radio.Session_T) return Boolean
     with Global => (State, EVC_Radio.State);

   --  What the parent does for the handover
   type Request_T is record
      --  3.15.1.3.1 a): a session with RBC, the other one kept
      Open      : Boolean := False;
      --  3.15.1.3.2: the session with RBC (one session only)
      Establish : Boolean := False;
      RBC       : EVC_Radio.RBC_Id_T := EVC_Radio.No_RBC;
      Radio     : NID_RADIO_T := 0;
      --  3.15.1.3.2.3, 3.15.1.3.9: terminate the session Stop_S
      Stop      : Boolean := False;
      Stop_S    : EVC_Radio.Session_T := 1;
      --  3.15.1.3.1 b), c): a position report to the RBCs
      Report    : Boolean := False;
   end record;

   --  5a. the order applied, the roles, the border, the switch
   procedure Evaluate (Now_Ms : EVC_Radio.Time_Ms_T; Req : out Request_T)
     with Global => (In_Out => (State, EVC_Radio.State, EVC_Position.State),
                     Input  => EVC_Odometry.State),
          Post => EVC_Radio.Sessions = EVC_Radio.Sessions'Old
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.Status = EVC_Position.Status'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old;

   --  3.15.1.3.4: the sessions that get the position reports beside the
   --  supervising one; 3.15.1.3.9: a report to the Handing Over RBC
   function Also_Reported (S : EVC_Radio.Session_T) return Boolean
     with Global => (State, EVC_Radio.State);
   function Forced_Report (S : EVC_Radio.Session_T) return Boolean
     with Global => State;

   --  3.15.1.3.3: the session that is to get the Train Data (none: 0),
   --  and that it got them
   function Train_Data_To return EVC_Radio.Session_Ref_T
     with Global => State;
   procedure Train_Data_Sent
     with Global => (In_Out => State);

   --  8k. the reports of the cycle went out
   procedure Produced
     with Global => (In_Out => State);

end EVC_Sessions.Handover;
