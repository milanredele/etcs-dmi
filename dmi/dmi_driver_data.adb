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
      Train_Category := 0;
      Axle_Load := 0;
      Airtight := 0;
      Loading_Gauge := 0;
      SR_Speed := 0;
      SR_Dist := 0;
      Driver_ID_Entered := False;
      Level_Entered := False;
      Train_Data_Entered := False;
      TRN_Entered := False;
      Onboard_Values_Known := False;
      Onboard_Driver_ID := (others => <>);
      Onboard_TRN := (others => <>);
      Onboard_Long_Known := False;
      Onboard_Train_Valid := False;
      Onboard_Length := 0;
      Onboard_Brake_Pct := 0;
      Onboard_Max_Speed := 0;
      Onboard_Category := 0;
      Onboard_Axle_Load := 0;
      Onboard_Airtight := 0;
      Onboard_Gauge := 0;
      Onboard_Network := (others => <>);
   end Reset;

end DMI_Driver_Data;
