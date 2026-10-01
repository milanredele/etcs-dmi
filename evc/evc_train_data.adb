--  ETCS on-board (EVC)
--  The Train Data of the on-board, implementation.

package body EVC_Train_Data
  with SPARK_Mode => On,
       Refined_State => (State => (Is_Valid, Current, Current_Categories))
is

   Is_Valid           : Boolean := False;
   Current            : Train_Data_T := Default;
   Current_Categories : Categories_T := Default_Categories;

   function Valid return Boolean is (Is_Valid)
     with Refined_Global => Is_Valid;

   function Data return Train_Data_T is (Current)
     with Refined_Global => Current;

   function Categories return Categories_T is (Current_Categories)
     with Refined_Global => Current_Categories;

   procedure Clear is
   begin
      Is_Valid := False;
      Current := Default;
      Current_Categories := Default_Categories;
   end Clear;

   procedure Set (D : Train_Data_T; C : Categories_T) is
   begin
      Is_Valid := True;
      Current := D;
      Current_Categories := C;
   end Set;

   procedure Invalidate is
   begin
      Is_Valid := False;
   end Invalidate;

end EVC_Train_Data;
