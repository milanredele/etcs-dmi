--  ETCS DMI
--  The store of the pre-configured train types (see the spec).
package body DMI_Train_Types is

   Known : Type_Count_T := 0;
   Types : Type_List_T;

   procedure Set_List (Count : Type_Count_T; List : Type_List_T) is
   begin
      Known := Count;
      Types := List;
   end Set_List;

   procedure Reset is
   begin
      Known := 0;
      Types := (others => <>);
   end Reset;

   function Count return Type_Count_T is (Known);

   function Get (Index : Positive) return Train_Type_T is
     (if Index <= Known then Types (Index) else (others => <>));

end DMI_Train_Types;
