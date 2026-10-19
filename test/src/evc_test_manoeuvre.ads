--  ETCS on-board (EVC) regression: Supervised Manoeuvre (SUBSET-026
--  4.4.21, 5.21) and the safe consist length it needs (3.18.3.2 b)

package EVC_Test_Manoeuvre is

   --  3.18.3.2 b) 1st bullet: the safe consist length of the TIU
   --  (EVC_Ports signal 15) taken, its frame checked; 3.18.3.2.5 kept
   --  when it becomes unavailable; 3.18.3.5 a) b) no valid Train Data
   --  and no driver entry with a length in front of the engine;
   --  3.18.3.2.4 the train length of the consist; the MSG_ONBOARD bits
   --  of DMI Table 33 #11
   procedure Scenario_Safe_Consist;

   --  5.21.2.2 S0 to S050, E215 / A220, 5.21.4.1: the request for
   --  Supervised Manoeuvre (message 131), the answer matched by its time
   --  stamp (4.8.4 [14]), SM refused, the repetitions without an answer
   procedure Scenario_SM_Request;

   --  5.21.2.2 E115, D080, A050, 4.6.3 [81], 4.8.3 / 4.8.4: message 4
   --  answering the request authorises SM
   procedure Scenario_SM_Authorisation;

end EVC_Test_Manoeuvre;
