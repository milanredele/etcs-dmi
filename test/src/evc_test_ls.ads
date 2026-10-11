--  Phase E4 (e4/ls-display): the LSSMA display of Limited Supervision,
--  SUBSET-026 4.4.19.1.4 to 4.4.19.1.4.8 (EVC_LS_Display)
package EVC_Test_LS is

   procedure Scenario_LS_Display;

   --  e4/ls-display-2 (B091): 4.4.19.1.4.2 c), 4.8.3 [1], 4.8.5.6: the
   --  toggle on order of a group kept in the level transition buffer
   procedure Scenario_LS_Order_Buffered;

   --  e4/ls-display-2 (B090): 4.4.19.1.4.8, the marker deleted by an LS
   --  mode profile without packet 181 in the same group
   procedure Scenario_LS_Marker_Deleted;

end EVC_Test_LS;
