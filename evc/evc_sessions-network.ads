--  ETCS on-board (EVC)
--  Phase E5, the session and link half (e5/registration): the radio
--  networks of 3.5.6 and the radio data the driver enters (3.18.4.3.6,
--  5.4.3.2 S3 / S5, DMI 11.3.15, 11.3.16).
--
--  A private child of EVC_Sessions, its state a part of the parent's.
--  The Radio Network type and the GSM-R network identity stored are
--  EVC_Radio.Network (memorized over No Power by EVC_Core, 3.5.6.2);
--  this unit is their writer and holds the registration of each
--  session's GSM-R Mobile Terminal from the port's events 5 / 6.
--
--  Decisions (doc/EVC-PLAN.md §13, radio network registration):
--  (1) A session of the RTM port is one GSM-R Mobile Terminal: the
--      registration is ordered per session (Request_Registration) and
--      the events 5 / 6 of a session are its mobile's.
--  (2) FRMCS (3.5.6.1.2, 3.5.6.1.3): the port reports no FRMCS
--      registration yet, so the FRMCS on-board counts as not
--      registered; a configuration with FRMCS and a stored type that
--      needs it sets up no connection (3.5.6.7 a / b) until the port
--      brings that report.
--  (3) 3.5.6.1 a): the power-up registration is ordered whenever GSM-R
--      is installed, whatever the type stored, to the stored identity
--      or the configured default (3.5.6.3).
--  (4) 3.5.6.5 / 3.5.6.6: a registration ordered for a mobile whose
--      session is not Idle waits until it is (the session terminated,
--      the connection released); the mobile counts as registered to
--      its former network until its request is sent.
--  (5) 3.5.6.7 is applied to every set-up request, not only to the
--      trackside's orders: D7 / S4 of 5.4.3.2 and 5.10.3.15.2 a) / b)
--      wait for the same conditions, so the start of mission and the
--      driver's level 2 hold their request until the mobile is
--      registered. With "mission with only one radio system" either
--      system registered is enough (3.5.6.7 c).
--  (6) The list of networks (3.18.4.3.6.2): the port offers none, so it
--      is empty (5.4.3.2 S3 E3 -> A29: "GSM-R network registration
--      failed"); a network the driver names (six digits at most, the
--      NID_MN digits) is ordered as entered.

with ETCS_Variables;
with EVC_Config;
with EVC_Driver_Requests;
with EVC_Received;

private package EVC_Sessions.Network
  with SPARK_Mode => On,
       Abstract_State => (State with Part_Of => EVC_Sessions.State)
is

   procedure Clear
     with Global => (Output => State);

   --  The port's event 5 (Registered True) or 6 for the mobile of S
   procedure Take_Event (S : EVC_Radio.Session_T; Registered : Boolean)
     with Global => (In_Out => (State, EVC_Radio.State));

   --  3.5.6.1 c), 3.5.6.5: a Radio Network transition order (packet 45:
   --  Q_NETWORKTYPE, NID_MN when the type is 1 or 2), applied by the
   --  next Evaluate (the last one of a cycle wins)
   procedure Take_Order (Q_Type : Natural;
                         NID_MN : ETCS_Variables.NID_MN_T)
     with Global => (In_Out => State);

   --  Packet 45 of the radio message just received (EVC_Received)
   procedure Take_Radio_Order
     with Global => (In_Out => State,
                     Input  => EVC_Received.Store);

   --  The cycle: the defaults of the configuration and the power-up
   --  registration (3.5.6.1 a, 3.5.6.3, 3.5.6.4), the driver's radio
   --  data (3.18.4.3.6). Stop: terminate the sessions and abort the
   --  attempts (3.18.4.3.6.1); Failed: show "GSM-R network
   --  registration failed" (5.4.3.2 A29)
   procedure Evaluate (Stop, Failed : out Boolean)
     with Global => (In_Out => (State, EVC_Radio.State),
                     Input  => (EVC_Config.State,
                                EVC_Driver_Requests.State));

   --  The registration requests due (3.5.6.5, 3.5.6.6)
   procedure Produce
     with Global => (In_Out => (State, EVC_Radio.State, EVC_Radio.Queue));

   --  3.5.6.7: the registration conditions hold, a safe radio connection
   --  may be requested
   function Ready return Boolean
     with Global => (State, EVC_Radio.State);

   --  MSG_ONBOARD radio bits 0-6 (common/dmi_protocol.ads)
   function Radio_Bits return Natural
     with Global => (State, EVC_Radio.State),
          Post => Radio_Bits'Result < 128;

   --  radio_wait 2: a network the driver selected, its registration
   --  awaited
   function Selection_Awaited return Boolean
     with Global => State;

   --  3.18.4.3.6.2 (e5/registration-2): the list of GSM-R networks is
   --  due in this cycle (MSG_RADIO_NETWORKS); the networks it offers,
   --  the default network of the configuration and the stored one when
   --  different (decision 6 of e5/registration: the port offers none),
   --  each named by at least one digit
   function List_Due return Boolean
     with Global => State;
   function Offered_Count return Natural
     with Global => (State, EVC_Radio.State),
          Post => Offered_Count'Result <= 2;
   function Offered (I : Positive) return ETCS_Variables.NID_MN_T
     with Global => (State, EVC_Radio.State),
          Pre => I <= 2;

end EVC_Sessions.Network;
