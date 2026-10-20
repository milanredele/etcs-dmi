--  ETCS on-board (EVC)
--  The Train Data of the on-board, implementation.

package body EVC_Train_Data
  with SPARK_Mode => On,
       Refined_State => (State => (Is_Valid, Current, Current_Categories,
                                   SCL_Available, SCL_Known, SCL,
                                   SM_Set, SM_Data, SM_Categories))
is

   Is_Valid           : Boolean := False;
   Current            : Train_Data_T := Default;
   Current_Categories : Categories_T := Default_Categories;
   SCL_Available      : Boolean := False;
   SCL_Known          : Boolean := False;
   SCL                : Consist_T := (others => 0);
   --  the default Train Data of Supervised Manoeuvre (3.18.3.9), in
   --  force when SM_Set; SM_Data.Length follows Consist_Length
   SM_Set             : Boolean := False;
   SM_Data            : Train_Data_T := Default;
   SM_Categories      : Categories_T := Default_Categories;

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
         SM_Data.Length := Consist_Length;
         if C.Front_Max > 0 then
            Is_Valid := False;
         end if;
      end if;
   end Take_Consist;

   function Valid return Boolean is (Is_Valid)
     with Refined_Global => Is_Valid;

   function Data return Train_Data_T is
     (if SM_Set then SM_Data else Current)
     with Refined_Global => (SM_Set, SM_Data, Current);

   function Categories return Categories_T is
     (if SM_Set then SM_Categories else Current_Categories)
     with Refined_Global => (SM_Set, SM_Categories, Current_Categories);

   function Manoeuvre_Set return Boolean is (SM_Set)
     with Refined_Global => SM_Set;

   procedure Clear is
   begin
      Is_Valid := False;
      Current := Default;
      Current_Categories := Default_Categories;
      SCL_Available := False;
      SCL_Known := False;
      SCL := (others => 0);
      SM_Set := False;
      SM_Data := Default;
      SM_Categories := Default_Categories;
   end Clear;

   function Length return EVC_Distances.Length_T is
     (if SM_Set then SM_Data.Length else Current.Length)
     with Refined_Global => (SM_Set, SM_Data, Current);

   procedure Set (D : Train_Data_T; C : Categories_T) is
   begin
      Is_Valid := True;
      Current := D;
      Current_Categories := C;
      SM_Set := False;
   end Set;

   procedure Invalidate is
   begin
      Is_Valid := False;
   end Invalidate;

   procedure Start_Manoeuvre_Set (F : EVC_Config.Fixed_Train_T) is
   begin
      SM_Data :=
        (Length                => Consist_Length,
         Max_Speed             => F.SM_Max_Speed,
         Model                 => F.Model,
         Brake_Percentage      => F.SM_Brake_Percentage,
         Brake_Position        => F.SM_Brake_Position,
         A_Brake_Emergency     => (Count => 0, Steps => (others => (0, 0))),
         A_Brake_Service       => (Count => 0, Steps => (others => (0, 0))),
         A_Brake_Normal        => (Count => 0, Steps => (others => (0, 0))),
         T_Brake_Emergency     => 0,
         T_Brake_Service       => 0,
         Has_Regenerative      => F.Has_Regenerative,
         Has_Eddy_Current      => F.Has_Eddy_Current,
         Has_Magnetic_Shoe     => F.Has_Magnetic_Shoe,
         Has_Electro_Pneumatic => F.Has_Electro_Pneumatic,
         T_Traction_Cut_Off    => F.T_Traction_Cut_Off);
      SM_Categories :=
        (Cant_Deficiency => F.SM_Cant_Deficiency,
         Other           => F.SM_Other,
         Axle_Load       => F.SM_Axle_Load,
         Loading_Gauge   => F.SM_Loading_Gauge,
         Voltages        => F.Voltages,
         Airtight        => F.SM_Airtight);
      SM_Set := True;
      Is_Valid := False;
   end Start_Manoeuvre_Set;

   procedure End_Manoeuvre_Set is
   begin
      SM_Set := False;
   end End_Manoeuvre_Set;

end EVC_Train_Data;
