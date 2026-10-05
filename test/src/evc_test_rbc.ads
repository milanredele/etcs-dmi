--  ETCS on-board (EVC)
--  Phase E5, the bench: the scripted RBC of sim/ (Sim_RBC) against the
--  on-board, through the RTM port in the format of EVC_Ports.
--
--  Scenario_RBC: Sim_RBC reads the on-board's outputs (a request to set
--  up a connection, the session messages 155 and 159, an MA request 132
--  with its position report, the termination 156, the release) without
--  error and answers as an RBC (3.5.3.4 the connection, 3.5.3.7 the
--  session with 32 and 38, 3.8.2 the MA 3 with packet 15 referred to
--  the LRBG reported, 3.5.5 the acknowledgement 39 and the release); its
--  answers, given to the on-board's RTM port, are accepted by the port
--  and the codec (ETCS_Message, 8.4.4) and reach the halves of E5 (stubs
--  on this branch: what they do with them is tested once they exist);
--  the time stamps rise (3.16.3.3.2). Inputs of a wrong shape are
--  counted, never raise. Wired into Sim_Onboard_Env behind its switch,
--  off by default.

package EVC_Test_RBC is

   procedure Scenario_RBC;

end EVC_Test_RBC;
