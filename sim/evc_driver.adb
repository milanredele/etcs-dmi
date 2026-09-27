--  ETCS DMI test simulator
--  Automatic driver implementation.

with EVC_ATO;
with EVC_Core;
with EVC_Train;

package body EVC_Driver is

   procedure Auto_Drive is
      use type EVC_Core.Mode_T;
   begin
      if EVC_Core.Mode = EVC_Core.FS then
         if EVC_ATO.Advising then
            -- the driver follows the advice of the ATO (DMI 8.5.9 to
            -- 8.5.11) and stops at its stopping points
            EVC_Train.Demand := EVC_ATO.Demand;
         elsif EVC_Core.Monitoring = 2 then
            EVC_Train.Demand := -100; -- brake to a stand in RSM
         elsif EVC_Train.Speed_KMH + 3 < EVC_Core.Permitted_Speed then
            EVC_Train.Demand := 60;
         elsif EVC_Train.Speed_KMH + 1 >= EVC_Core.Permitted_Speed then
            EVC_Train.Demand := -80;
         else
            EVC_Train.Demand := 0;
         end if;
      end if;
   end Auto_Drive;

end EVC_Driver;
