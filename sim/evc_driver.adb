--  ETCS DMI test simulator
--  Automatic driver implementation.

with EVC_Core;
with EVC_Train;

package body EVC_Driver is

   procedure Auto_Drive is
      use type EVC_Core.Mode_T;
   begin
      if EVC_Core.Mode = EVC_Core.FS then
         if EVC_Core.Monitoring = 2 then
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
