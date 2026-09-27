--  ETCS DMI test simulator
--  Simple automatic driver: holds a few km/h below the permitted speed
--  and brakes to a stand once in release speed monitoring. With the
--  ATO selector "On" in FS it follows the advice of the ATO (EVC_ATO);
--  in AD the ATO drives and this driver does nothing. Shared by the
--  live simulator, the WebAssembly build and the regression runner.

package EVC_Driver is

   -- Set EVC_Train.Demand from the current supervision state
   procedure Auto_Drive;

end EVC_Driver;
