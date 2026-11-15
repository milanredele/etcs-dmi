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

   --  3.17.2.3, 3.17.2.5, 3.17.2.6, 3.17.2.7, 3.17.2.8 d): the operated
   --  version in relation to the balise groups, their orders (packet 2)
   procedure Scenario_Version_Balise_Groups;

   --  3.17.2.6, 3.17.3.4.1: the country check against an immediate set of
   --  national values in the same group message
   procedure Scenario_Version_Country_Set;

   --  6.6.1.1, 6.6.2, 6.6.4: the rules of chapter 6 by the operated X and
   --  the supervising RBC (EVC_System_Version.Rules_Of): 1.1 ordered by
   --  a group, an RBC of 2.1 and of 2.3 supervising, 3.0 everywhere;
   --  6.6.3.4.1.2: no acknowledgement awaited from an RBC of 1.1
   procedure Scenario_Version_Rules;

   --  6.6.2.1.3, 6.6.4.1.2: in FS a TSR relocated across a group starts
   --  and ends at its estimated location with X = 2 ordered by a group,
   --  at its max start and min end with X = 3 (3.6.4.2.4 Table 2a)
   procedure Scenario_Version_TSR;

   --  6.6.2.1.4, 6.6.4.1.3: the ASP of every axle load category up to
   --  the train's, the lowest speed, with X = 2 ordered by the group that
   --  carries it; with X = 3 the train's category alone (3.11.4.3)
   procedure Scenario_Version_ASP;
end EVC_Test_Version;
