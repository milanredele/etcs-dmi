--  ETCS DMI
--  Automatic Train Operation information implementation.

package body DMI_ATO is

   procedure Reset is
   begin
      Selector := Unknown;
      Status := No_Status;
      Warning := False;
      At_Stopping_Point := False;
      Accuracy := No_Accuracy;
      Dwell_Valid := False;
      Dwell_S := 0;
      Train_Hold := False;
      Doors := No_Doors;
      Skip := No_Skip;
      Advice_Valid := False;
      Advice_Speed := 0;
      Coasting := False;
      ETA_Valid := False;
      ETA_H := 0;
      ETA_M := 0;
      ETA_S := 0;
      Name_Length := 0;
      Name := (others => ' ');
   end Reset;

end DMI_ATO;
