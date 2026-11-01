--  ETCS on-board (EVC)
--  Phase E6, the Virtual Balise Cover: SUBSET-026 3.15.9 (EVC_VBC, the
--  cover in EVC_Core.Read_Telegrams, packet 6 in
--  EVC_Stored_Information.Take_VBC_Orders, the DMI's list).

package EVC_Test_VBC is

   --  3.15.9.4, 3.15.9.5 a) b) c) d), 3.15.9.6: the store, its periods
   --  and its country check
   procedure Scenario_VBC_Store;

   --  3.15.9.2, 3.15.9.5: the driver's Set VBC and Remove VBC in SB, the
   --  national bits of MSG_ONBOARD, MSG_VBC_LIST, the covers kept over No
   --  Power
   procedure Scenario_VBC_Driver;

   --  SUBSET-040 4.5.1.2 and 4.3.2.1 w), 3.15.9.4, 3.15.9.5: the rooms of
   --  20 covers set by the driver and 10 ordered by trackside, apart; the
   --  national bit 2 from the driver's room; the 30 kept over No Power
   procedure Scenario_VBC_Rooms;

   --  3.15.9.3 a), b), 3.15.9.3.1: a covered telegram is not received
   --  (only its juridical record); packet 6 sets and removes a cover;
   --  3.15.9.5 d) a group of another country deletes it
   procedure Scenario_VBC_Cover;

   --  3.15.9.5 b), 3.18.5.1: the validity period is calendar time on the
   --  on-board's clock; a cover of one day set with UTC known is deleted
   --  at the power-up two days later; without the clock after the
   --  power-up the time left with power on is the fallback
   procedure Scenario_VBC_Clock;

end EVC_Test_VBC;
