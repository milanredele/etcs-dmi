--  ETCS DMI test simulator
--  A scripted RBC behind the RTM port of the ETCS on-board (phase E5),
--  in the format of EVC_Ports (doc/EVC-PLAN.md §13 "Joint: outcome"):
--  it reads the on-board's RTM outputs (Take: a tagged train to track
--  message, a request to the radio) and queues the RTM inputs it answers
--  with (Next_Input: tagged track to train messages, connection events)
--  for the on-board's next cycle.
--
--  What it does, from the RBC's side of SUBSET-026:
--    - the safe radio connection (3.5.3.4, 3.5.5): a request to set up
--      is answered with the event "set up" in the session of the
--      request when an RBC has the identity asked for (RBC 1 also takes
--      a request for an identity no RBC has: the bench line has one
--      RBC), else "set-up failed"; a release with "released"; a
--      registration to the network with "registered";
--    - the session (3.5.3.7): message 155 answered with 32 (system
--      version 3.0 of SUBSET-026 4.0.0), 159 with 38, 154 ends it; Train Data (129, 5.4,
--      5.17) acknowledged with message 8; the SoM position report (157,
--      5.4.3.2 S10) answered with 41 "train accepted"; the termination
--      (156, 3.5.5) acknowledged with 39;
--    - an MA on request (132, 3.8.2): message 3 with packet 15, the
--      end of authority at the bench line's EOA (EVC_Track.EOA_M) with
--      its danger point and a release speed of 25 km/h, referred to the
--      last LRBG the train reported (packet 0 or 1 of 136 or 157);
--    - an unconditional emergency stop on command (message 16, 3.10).
--  A second RBC (RBC 2) exists for the handover of 3.15.1; Handover is
--  the interface only so far (counted, nothing sent).
--
--  The time stamps (3.16.3.2.2, 3.16.3.3.1/2): the on-board time
--  estimated from the T_TRAIN of the last message received plus the
--  time since, never in advance of it, strictly increasing; message 8
--  carries the T_TRAIN of the Train Data acknowledged.
--
--  Builds for the wasm32 light runtime: no allocation, no file, no
--  exception; any input is validated (a payload it cannot read is
--  counted in Errors, never raises).

with EVC_Bytes;

package Sim_RBC is

   type RBC_T is range 1 .. 2;
   type State_T is (Idle, Connected, Initiating, Established, Terminating);

   --  Both RBCs idle, no session, nothing queued; RBC 1 is (EVC_Track's
   --  country, NID_RBC 1), RBC 2 (the same country, NID_RBC 2)
   procedure Reset;
   procedure Set_Identity (RBC : RBC_T; NID_C, NID_RBC : Natural);

   --  An RTM output of the on-board (the payload of its RTM record)
   procedure Take (Payload : EVC_Bytes.Byte_Array);

   --  Time passes (one cycle of the bench)
   procedure Step (Dt_Ms : Natural);

   --  The next RTM input for the on-board, Last < Buffer'First when none
   --  (or when Buffer is too short: it stays queued)
   procedure Next_Input (Buffer : out EVC_Bytes.Byte_Array;
                         Last   : out Natural);
   function Pending return Natural;

   --  On command (a button of the page): message 16, unconditional
   --  emergency stop, in the session of RBC when it is established
   procedure Emergency_Stop (RBC : RBC_T := 1);

   --  The handover of 3.15.1 from From to To: the interface only so far
   procedure Handover (From, To : RBC_T);

   --  Observation
   function State (RBC : RBC_T) return State_T;
   function Session_Of (RBC : RBC_T) return Natural;   -- 0 none
   function Taken return Natural;     -- outputs of the on-board read
   function Errors return Natural;    -- outputs it could not read
   function Answered return Natural;  -- inputs queued
   function Dropped return Natural;   -- inputs lost for lack of room
   function Last_NID_Taken return Natural;
   function Handovers_Asked return Natural;

end Sim_RBC;
