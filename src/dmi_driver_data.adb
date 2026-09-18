--  ETCS DMI
--  Driver data store implementation.

package body DMI_Driver_Data is

   procedure Reset is
   begin
      Driver_ID := (others => <>);
      TRN := (others => <>);
      Train_Length := 0;
      Brake_Pct := 0;
      Max_Speed := 0;
      SR_Speed := 0;
      SR_Dist := 0;
      Driver_ID_Entered := False;
      Level_Entered := False;
      Train_Data_Entered := False;
      TRN_Entered := False;
   end Reset;

end DMI_Driver_Data;
