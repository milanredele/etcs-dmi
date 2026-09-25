--  ETCS DMI
--  Virtual Balise Covers implementation.

package body DMI_VBC is

   procedure Set_List (New_Count : Count_T; New_Codes : Code_List_T) is
   begin
      Known := True;
      Count := New_Count;
      Codes := New_Codes;
   end Set_List;

   procedure Hold (Value : DMI_Driver_Data.Text_Value_T) is
   begin
      Pending := Value;
      Pending_Valid := True;
   end Hold;

   procedure Clear is
   begin
      Pending := (0, (others => ' '));
      Pending_Valid := False;
   end Clear;

   function Pending_Code return Code_T is
      Result : Natural := 0;
   begin
      if not Pending_Valid then
         return 0;
      end if;
      for I in 1 .. Pending.Length loop
         if Pending.Text (I) not in '0' .. '9' then
            return 0;
         end if;
         Result := Result * 10
           + (Wide_Character'Pos (Pending.Text (I))
              - Wide_Character'Pos ('0'));
         --  Result stays at most 10 * Code_Max + 9, far inside Natural
         if Result > Code_Max then
            return 0;
         end if;
      end loop;
      return Result;
   end Pending_Code;

   procedure Reset is
   begin
      Known := False;
      Count := 0;
      Codes := (others => 0);
      Clear;
   end Reset;

end DMI_VBC;
