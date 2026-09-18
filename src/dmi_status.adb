--  ETCS DMI
--  Status state implementation.

pragma Ada_2012;
with Speed_And_Distance;
with Supplementary_Driving_Info;
with User_Settings;

package body DMI_Status is

   package SDI renames Supplementary_Driving_Info;

   procedure Reconcile_Track_Conditions (New_List  : TC_List_T;
                                         New_Count : Natural) is
      Result : TC_List_T;
      Count  : Natural := 0;

      function In_New (ID : Natural) return Boolean is
      begin
         for I in 1 .. New_Count loop
            if New_List (I).ID = ID then
               return True;
            end if;
         end loop;
         return False;
      end In_New;

      function Known (ID : Natural) return Boolean is
      begin
         for I in 1 .. Count loop
            if Result (I).ID = ID then
               return True;
            end if;
         end loop;
         return False;
      end Known;
   begin
      -- keep surviving entries in their existing (arrival) order
      for I in 1 .. TC_Count loop
         if In_New (TC_List (I).ID) and then Count < Result'Last then
            Count := Count + 1;
            Result (Count) := TC_List (I);
         end if;
      end loop;
      -- append newcomers in the order the EVC lists them
      for I in 1 .. New_Count loop
         if not Known (New_List (I).ID) and then Count < Result'Last then
            Count := Count + 1;
            Result (Count) := New_List (I);
         end if;
      end loop;
      TC_List := Result;
      TC_Count := Count;
   end Reconcile_Track_Conditions;

   function TTI_Displayed return Boolean is
      use type Speed_And_Distance.Monitoring_T;
      use type SDI.Mode_T;
   begin
      -- Table 15a: CSM only, in FS/AD/SM always, in OS/SR when toggled
      -- on; TTI value present only when requested by National Value and
      -- below TdispTTI (EVC side)
      if not TTI_Valid
        or else TTI_Seconds >= T_Disp_TTI
        or else Speed_And_Distance.Get_Monitoring_Mode /= Speed_And_Distance.CSM
      then
         return False;
      end if;
      case SDI.Mode is
         when SDI.M_FS | SDI.M_AD | SDI.M_SM =>
            return True;
         when SDI.M_OS | SDI.M_SR =>
            return User_Settings.Speed_Info_Visible;
         when others =>
            return False;
      end case;
   end TTI_Displayed;

   procedure Reset is
   begin
      Brake := None;
      Radio := No_Connection;
      Slippery_Rail := False;
      BMM_Inhibited := False;
      Reversing_Permitted := False;
      SM_Direction := None;
      Set_Speed_Valid := False;
      Set_Speed := 0;
      TTI_Valid := False;
      TTI_Seconds := 0;
      T_Disp_TTI := 14;
      Tunnel := Unknown;
      Tunnel_Distance := 0;
      Tunnel_Toggled_On := False;
      Geo_Valid := False;
      Geo_Position_M := 0;
      Geo_Toggled_On := False;
      Time_H := 0;
      Time_M := 0;
      Time_S := 0;
      TC_Count := 0;
   end Reset;

end DMI_Status;
