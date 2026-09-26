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
      Given  : constant Natural := Natural'Min (New_Count, New_List'Last);
      Old    : constant Natural := Natural'Min (TC_Count, TC_List'Last);

      -- Index of the first entry with this id in the new set, 0 if none
      function In_New (ID : Natural) return Natural is
      begin
         for I in 1 .. Given loop
            if New_List (I).ID = ID then
               return I;
            end if;
         end loop;
         return 0;
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
      -- keep surviving entries in their existing (arrival) order and in
      -- their area. The id names the object: by choice (the SRS knows no
      -- ids) a kind that changes under one id, e.g. the announcement
      -- TC03 becoming the indication TC01, is the same object and stays
      -- where it is; another id is another object and queues up.
      for I in 1 .. Old loop
         declare
            Index : constant Natural := In_New (TC_List (I).ID);
         begin
            if Index /= 0
              and then not Known (TC_List (I).ID)
              and then Count < Result'Last
            then
               Count := Count + 1;
               Result (Count) := (ID   => TC_List (I).ID,
                                  Kind => New_List (Index).Kind,
                                  Slot => TC_List (I).Slot);
            end if;
         end;
      end loop;
      -- append newcomers in the order the EVC lists them, still waiting
      for I in 1 .. Given loop
         if not Known (New_List (I).ID) and then Count < Result'Last then
            Count := Count + 1;
            Result (Count) := (ID   => New_List (I).ID,
                               Kind => New_List (I).Kind,
                               Slot => 0);
         end if;
      end loop;
      -- 8.2.3.5.3 / 8.2.3.8.3: from left to right, an area that is free
      -- is used by the next object to be displayed, which is by choice
      -- the one that arrived first (the clauses give the waiting objects
      -- no order)
      for Slot in 1 .. TC_Slot_T'Last loop
         declare
            Free : Boolean := True;
         begin
            for I in 1 .. Count loop
               if Result (I).Slot = Slot then
                  if Free then
                     Free := False;
                  else
                     -- cannot happen: never two objects in one area
                     Result (I).Slot := 0;
                  end if;
               end if;
            end loop;
            if Free then
               for I in 1 .. Count loop
                  if Result (I).Slot = 0 then
                     Result (I).Slot := Slot;
                     exit;
                  end if;
               end loop;
            end if;
         end;
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
        or else TTI_Tenths >= 10 * T_Disp_TTI
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

   function TTI_Step return Positive is
     (10 - Natural'Min (9, TTI_Tenths / T_Disp_TTI));

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
      TTI_Tenths := 0;
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
