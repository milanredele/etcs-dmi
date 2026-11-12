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

   --  4.6.3 [83], 4.6.2: the safe consist length in front of the engine
   --  becoming different from zero with valid Train Data: to Stand-By
   --  from SR and from Unfitted, the Train Data invalid (3.18.3.5 a));
   --  without valid Train Data, or a length in rear only, no transition
   procedure Scenario_Consist_To_Stand_By;

   --  3.18.3.10: in level 2 with a session, the length in front of the
   --  engine that brings SB by [83] from FS is sent by message 133 once
   --  in SB
   procedure Scenario_Consist_To_Stand_By_L2;

   --  5.21.2.2 S0 to S050, E215 / A220, 5.21.4.1: the request for
   --  Supervised Manoeuvre (message 131), the answer matched by its time
   --  stamp (4.8.4 [14]), SM refused, the repetitions without an answer
   procedure Scenario_SM_Request;

   --  5.21.2.2 E115, D080, A050, 4.6.3 [81], 4.8.3 / 4.8.4: message 4
   --  answering the request authorises SM
   procedure Scenario_SM_Authorisation;

   --  3.18.3.9, 3.18.3.2.4: the default Train Data in SM
   procedure Scenario_SM_Default_Data;

   --  4.4.21.1.5, 4.4.21.1.6: "Entering SM" while the SSP and gradient do
   --  not cover the consist
   procedure Scenario_SM_Entering;

   --  3.18.3.10: the safe consist length information for SM
   procedure Scenario_SM_Consist_Info;

   --  3.6.5.2.5 Table 2c with Supervised Manoeuvre: [10] an SM
   --  authorisation changing the train orientation, from "confirmed by
   --  external source" to "no information"; [3] not after it until the
   --  driver confirms; [3] with the safe consist length only once its
   --  information for SM (133) is acknowledged (3.18.3.10.1)
   procedure Scenario_SM_Integrity;

   --  3.15.1.3.3: message 133 to the Accepting RBC in SM
   procedure Scenario_SM_Handover;

   --  4.4.21.1.9: the SM authorised direction to the DMI
   procedure Scenario_SM_Direction;
   procedure Scenario_SM_Brake_Reasons;

   --  4.8.4 [1]: in PT the exit from TR with a more recent time stamp
   procedure Scenario_SM_Post_Trip;

   --  5.4.3.2 S10: in the Start of Mission in level 2 the driver selects
   --  SM (E34), refused by the RBC back to S10 (E35), then authorised
   procedure Scenario_SM_Start_Of_Mission;

   --  3.6.4.1.5 last sentence: gamma 1 in Stand-By without valid Train
   --  Data with the safe consist length, in a Supervised Manoeuvre
   --  request and from the first authorisation to Non Leading
   procedure Scenario_SM_Gamma;

   --  4.4.21.1.13, 4.4.8.1.4: the TIU output "ready for remote shunting"
   --  with the engine orientation against the MA's direction
   procedure Scenario_SM_Remote_Shunting;
   procedure Scenario_SM_Consist_Rejects;

end EVC_Test_Manoeuvre;
