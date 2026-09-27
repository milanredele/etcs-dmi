--  ETCS DMI
--  Radio data implementation.

pragma Ada_2012;

package body DMI_Radio_Data is

   procedure Clear_List_Received is
   begin
      List_Received := False;
   end Clear_List_Received;

   procedure Set_List (Count : Network_Count_T; List : Name_List_T) is
   begin
      Network_Count := Count;
      Networks := List;
      List_Received := True;
   end Set_List;

   procedure Reset is
   begin
      Network_Count := 0;
      Networks := (others => <>);
      List_Received := False;
      GSMR_Network := (others => <>);
      RBC_ID := (others => <>);
      RBC_Phone := (others => <>);
      RBC_Entered := False;
      Last_Choice := Entered;
   end Reset;

end DMI_Radio_Data;
