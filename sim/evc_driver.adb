--  ETCS DMI test simulator
--  Automatic driver implementation.

with EVC_ATO;
with EVC_Mock;
with EVC_Train;

package body EVC_Driver is

   procedure Auto_Drive is
      use type EVC_Mock.Mode_T;
   begin
      if EVC_Mock.Mode = EVC_Mock.FS then
         if EVC_ATO.Advising then
            -- the driver follows the advice of the ATO (DMI 8.5.9 to
            -- 8.5.11) and stops at its stopping points
            EVC_Train.Demand := EVC_ATO.Demand;
         elsif EVC_Mock.Monitoring = 2 then
            EVC_Train.Demand := -100; -- brake to a stand in RSM
         elsif EVC_Train.Speed_KMH + 3 < EVC_Mock.Permitted_Speed then
            EVC_Train.Demand := 60;
         elsif EVC_Train.Speed_KMH + 1 >= EVC_Mock.Permitted_Speed then
            EVC_Train.Demand := -80;
         else
            EVC_Train.Demand := 0;
         end if;
      end if;
   end Auto_Drive;

   procedure Auto_Drive_Onboard (V_Cur_KMH       : Natural;
                                 V_Perm_KMH      : Natural;
                                 Monitoring      : Natural;
                                 Brake_Commanded : Boolean)
   is
   begin
      if Brake_Commanded then
         EVC_Train.Demand := 0;
      elsif Monitoring = 2 then
         EVC_Train.Demand := -100; -- brake to a stand in RSM
      elsif V_Perm_KMH = 0 then
         --  no permitted speed (Stand By, before the start of mission):
         --  the train stays where it is
         EVC_Train.Demand := (if V_Cur_KMH > 0 then -30 else 0);
      elsif V_Cur_KMH + 3 < V_Perm_KMH then
         EVC_Train.Demand := 60;
      elsif V_Cur_KMH + 1 >= V_Perm_KMH then
         EVC_Train.Demand := -80;
      else
         EVC_Train.Demand := 0;
      end if;
   end Auto_Drive_Onboard;

end EVC_Driver;
