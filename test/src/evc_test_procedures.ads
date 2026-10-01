--  ETCS on-board (EVC)
--  The scenarios of the procedures of phase E4 (doc/EVC-PLAN.md §10,
--  second half, branch e4/procedures), run by evc_test with its Check.
--
--  Every scenario drives EVC_Core through its ports only: balise
--  telegrams built with Sim_Telegrams on the BTM port, odometer samples
--  of a simple train (an exact odometer with a confidence of 0.5 % of the
--  distance run, a constant speed per step), the cab and the direction
--  controller on the TIU port, the driver's actions as MSG_DRIVER_ACTION
--  frames on the DMI port; and checks what comes out: MSG_MODE_LEVEL
--  (the mode, the acknowledgement asked, "override"), MSG_STATUS (the
--  brake indication, reversing), MSG_SPEED_STATE (the permitted speed),
--  MSG_SYSTEM_STATUS, MSG_TEXT and MSG_TEXT_REMOVE, MSG_ONBOARD, the TIU
--  output (the commands and their reasons) and the JRU records.
--
--  INTERIM: the start of mission is the modes half's (e4/modes); until
--  the merge a scenario starts from the mode and level a start of
--  mission would leave (EVC_Core.Set_Mode_For_Test), with the desk of
--  cab A open. The check names carry the clause numbers, as the
--  scenarios of the earlier phases do; the SUBSET-076 sequence a
--  scenario follows is named in its comment.

generic
   with procedure Check (Condition : Boolean; What : String);
package EVC_Test_Procedures is

   procedure Run;

end EVC_Test_Procedures;
