--  ETCS DMI test simulator
--  Simple automatic driver: holds a few km/h below the permitted speed
--  and brakes to a stand once in release speed monitoring. With the
--  ATO selector "On" in FS it follows the advice of the ATO (EVC_ATO);
--  in AD the ATO drives and this driver does nothing. Shared by the
--  live simulator, the WebAssembly build and the regression runner.

package EVC_Driver is

   -- Set EVC_Train.Demand from the current supervision state
   procedure Auto_Drive;

   -- The same driver on the ETCS on-board of evc/ (Sim_Onboard_Env),
   -- from what its DMI shows (MSG_SPEED_STATE: the speed, the permitted
   -- speed, the monitoring) and whether its train interface commands a
   -- brake. With a permitted speed it drives as Auto_Drive does (the SR
   -- mode speed limit after the start of mission, phase E4); without one
   -- (Stand By) it keeps the train at a stand; while a brake is commanded
   -- it takes the traction off.
   procedure Auto_Drive_Onboard (V_Cur_KMH       : Natural;
                                 V_Perm_KMH      : Natural;
                                 Monitoring      : Natural;
                                 Brake_Commanded : Boolean);

end EVC_Driver;
