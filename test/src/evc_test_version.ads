--  ETCS on-board (EVC)
--  Phase E5, the system version of the RBC (e5/version): the part of
--  SUBSET-026 chapter 6 and 3.17 the radio needs (EVC_System_Version,
--  EVC_Sessions.Take_Version / Send_159).

package EVC_Test_Version is

   --  3.5.3.7 d), 3.17.3.7, 6.4.2: an RBC of 2.1, 1.1 and 2.3 is
   --  compatible: 159 with the envelope (7.4.3.3), the operated X
   --  (3.17.2.8 b); 6.5.2.2.2: no acknowledgement awaited from 2.1 or
   --  1.1, awaited from 2.3 (3.5.3.7.4); X = 0: 154, the driver informed,
   --  the session terminated, the version last operated kept
   procedure Scenario_Version_Negotiation;

   --  3.17.2.9: the operated version kept over No Power; 3.17.2.9.1:
   --  lost, the highest supported one
   procedure Scenario_Version_Retained;

end EVC_Test_Version;
