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

end EVC_Test_Manoeuvre;
