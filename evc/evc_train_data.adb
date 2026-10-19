--  ETCS on-board (EVC)
--  The Train Data of the on-board, implementation.

package body EVC_Train_Data
  with SPARK_Mode => On,
       Refined_State => (State => (Is_Valid, Current, Current_Categories,
                                   SCL_Available, SCL_Known, SCL))
is

   Is_Valid           : Boolean := False;
   Current            : Train_Data_T := Default;
   Current_Categories : Categories_T := Default_Categories;
   SCL_Available      : Boolean := False;
   SCL_Known          : Boolean := False;
   SCL                : Consist_T := (others => 0);

   function Consist_Available return Boolean is (SCL_Available)
     with Refined_Global => SCL_Available;

   function Consist_Known return Boolean is (SCL_Known)
     with Refined_Global => SCL_Known;

   function Consist return Consist_T is (SCL)
     with Refined_Global => SCL;

   function Consist_Length return EVC_Distances.Length_T is
     (EVC_Distances.Length_T (100 * (SCL.Front_Max + SCL.Rear_Max)))
     with Refined_Global => SCL;

   procedure Take_Consist (Available : Boolean; C : Consist_T) is
   begin
      SCL_Available := Available;
      if Available then
         SCL := C;
         SCL_Known := True;
         if C.Front_Max > 0 then
            Is_Valid := False;
         end if;
      end if;
   end Take_Consist;

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
      SCL_Available := False;
      SCL_Known := False;
      SCL := (others => 0);
   end Clear;

   function Length return EVC_Distances.Length_T is (Current.Length)
     with Refined_Global => Current;

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
