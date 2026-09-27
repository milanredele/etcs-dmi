--  ETCS DMI test simulator
--  A small ERTMS/ATO on-board as the EVC relays it to the DMI
--  (MSG_ATO, DMI 8.5): the ATO selector (SUBSET-026 3.15.11.2), the
--  engagement into Automatic Driving (4.4.16, transitions [80], [53],
--  [33] of 4.6), a journey profile of three stopping points
--  (EVC_Track.Stopping_Points) with dwell times, train hold and doors,
--  the skip stopping point request, and the advice of 4.7.2 in FS:
--  target advice speed, coasting advice and next advice change.
--
--  What SUBSET-125 would decide is reduced to simple rules, see the
--  body. The ATO drives the train in AD; in FS the simulator's
--  automatic driver (EVC_Driver) follows the same advice.

with EVC_Mock;

package EVC_ATO is

   -- The driver's requests (DMI actions 15, 13 and 14)
   -- Arg 1 Stand-by, 2 On (DMI Table 43a); anything else is ignored
   procedure Set_Selector (Arg : Natural);
   -- Arg 1 "ATO engage", 0 "ATO disengage"
   procedure Engage_Request (Arg : Natural);
   -- Arg 1 request the skip of the next stopping point, 0 revoke it
   procedure Skip_Request (Arg : Natural);

   -- Called by EVC_Mock.Step after the train moved: arrival, dwell,
   -- departure, the passing of stopping points, the end of a
   -- disengagement. May change EVC_Mock.Mode (AD <-> FS).
   procedure Update (Dt_S : Float);

   -- The traction / brake demand of the ATO (-100 .. 100): what it
   -- applies in AD, and what the automatic driver follows in FS
   function Demand return Integer;

   -- The ATO selector is "On" and the mode is FS: the automatic driver
   -- of the simulator follows the ATO's advice (EVC_Driver)
   function Advising return Boolean;

   -- 8.5.11: distance from the train front to the next advice change,
   -- 16#FFFF# when there is none (MSG_PLANNING next_advice_dist)
   function Advice_Change_M return Natural;

   -- MSG_ATO; Clock_S is the local time of the day in seconds
   procedure Send (Emit : EVC_Mock.Sink_T; Clock_S : Float);

   procedure Reset;

   -- Introspection for scenario assertions
   function Selector_On return Boolean;
   function At_Stopping_Point return Boolean;
   function Next_Stopping_Point return Positive; -- index, may be past the last

end EVC_ATO;
