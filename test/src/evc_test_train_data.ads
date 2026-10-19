--  ETCS on-board (EVC)
--  Phase E6, the Train Data rest: the radio information of a transition
--  deleted at a change of categories (3.18.3.7 b), the track description
--  in rear of a longer train (3.18.3.8), the train running number from
--  the RBC (3.18.4.5), the train position with the engine's length
--  (4.4.6.1.4).
--  Run by evc_test (test/src/evc_test.adb); shared machinery is in
--  EVC_Test_Support.

package EVC_Test_Train_Data is

   --  3.18.3.7 b): a message of the Accepting RBC held in the transition
   --  buffer, deleted when the axle load category changes at standstill
   procedure Scenario_Transition_Deleted;

   --  3.18.3.8: the train length increased: the gradient section that
   --  ends in rear of the former min safe rear end deleted
   procedure Scenario_Longer_Train;

   --  3.18.4.5.3: the train running number from the RBC (packet 140)
   --  taken while the session is established; 3.18.4.5.4.1: not sent
   --  back; the driver's entry after it sent again
   procedure Scenario_RBC_TRN;

   --  4.4.7.1.6, 4.4.8.1.3, 4.4.15.1.3: the engine's front and rear end
   --  are the train's in SB without valid Train Data, in SH and in NL;
   --  the valid Train Data's length in SB and FS
   procedure Scenario_Engine_Length;

end EVC_Test_Train_Data;
