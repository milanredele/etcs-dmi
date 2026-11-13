--  ETCS on-board (EVC)
--  The Train Data of the on-board, implementation.

package body EVC_Train_Data
  with SPARK_Mode => On,
       Refined_State => (State => (Is_Valid, Current, Current_Categories,
                                   SCL_Available, SCL_Known, SCL,
                                   SCL_Front_Rose, SM_Set, SM_Data,
                                   SM_Categories, Type_Index, By_Interface))
is

   Is_Valid           : Boolean := False;
   Current            : Train_Data_T := Default;
   Current_Categories : Categories_T := Default_Categories;
   SCL_Available      : Boolean := False;
   SCL_Known          : Boolean := False;
   SCL                : Consist_T := (others => 0);
   SCL_Front_Rose     : Boolean := False;
   --  the default Train Data of Supervised Manoeuvre (3.18.3.9), in
   --  force when SM_Set; SM_Data.Length follows Consist_Length
   SM_Set             : Boolean := False;
   SM_Data            : Train_Data_T := Default;
   SM_Categories      : Categories_T := Default_Categories;
   Type_Index         : Type_Index_T := 0;
   --  the last Stored step took a set of the train interface
   By_Interface       : Boolean := False;

   function Set_By_Interface return Boolean is (By_Interface)
     with Refined_Global => By_Interface;

   function Type_In_Force return Type_Index_T is (Type_Index)
     with Refined_Global => Type_Index;

   function Consist_Available return Boolean is (SCL_Available)
     with Refined_Global => SCL_Available;

   function Consist_Known return Boolean is (SCL_Known)
     with Refined_Global => SCL_Known;

   function Consist return Consist_T is (SCL)
     with Refined_Global => SCL;

   function Consist_Length return EVC_Distances.Length_T is
     (EVC_Distances.Length_T (100 * (SCL.Front_Max + SCL.Rear_Max)))
     with Refined_Global => SCL;

   function Front_Consist_Rose return Boolean is (SCL_Front_Rose)
     with Refined_Global => SCL_Front_Rose;

   procedure No_Consist_Input is
   begin
      SCL_Front_Rose := False;
   end No_Consist_Input;

   procedure Take_Consist (Available : Boolean; C : Consist_T) is
   begin
      SCL_Front_Rose :=
        Is_Valid and then not (SCL_Available and then SCL.Front_Max > 0)
        and then Available and then C.Front_Max > 0;
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
      SCL_Front_Rose := False;
      SM_Set := False;
      SM_Data := Default;
      SM_Categories := Default_Categories;
      Type_Index := 0;
      By_Interface := False;
   end Clear;

   --  decision: the safe consist length is "captured as part of valid
   --  Train Data" when it is available while the Train Data are valid; a
   --  max rear length of 0 (nothing behind the engine) keeps the length
   --  entered, not a train of no length
   function Length return EVC_Distances.Length_T is
     (if SM_Set then SM_Data.Length
      elsif Is_Valid and then SCL_Available and then SCL.Rear_Max > 0
      then EVC_Distances.Length_T (100 * SCL.Rear_Max)
      else Current.Length)
     with Refined_Global => (SM_Set, SM_Data, Current, Is_Valid,
                             SCL_Available, SCL);

   procedure Set (D : Train_Data_T; C : Categories_T; T : Type_Index_T := 0)
   is
   begin
      Is_Valid := True;
      Current := D;
      Current_Categories := C;
      SM_Set := False;
      Type_Index := T;
   end Set;

   procedure Of_Train_Type (T : EVC_Config.Train_Type_T;
                            F : EVC_Config.Fixed_Train_T;
                            D : out Train_Data_T;
                            C : out Categories_T)
   is
   begin
      C := (Cant_Deficiency => T.Cant_Deficiency,
            Other           => T.Other,
            Axle_Load       => T.Axle_Load,
            Loading_Gauge   => T.Loading_Gauge,
            Voltages        => F.Voltages,
            Airtight        => T.Airtight,
            N_Axle          => F.N_Axle);
      D :=
        (Length                => EVC_Distances.Length_T (T.Length_M) * 100,
         Max_Speed             => Speed_Cms_T (T.Max_Speed_Kmh * 250 / 9),
         Model                 => F.Model,
         Brake_Percentage      => T.Brake_Percentage,
         --  7.5.1.84: bit 2 passenger train, bit 1 freight train in G,
         --  bit 0 freight train in P; a passenger train is in P
         Brake_Position        =>
           (if Natural (T.Other) / 4 mod 2 = 1 then Passenger_P
            elsif Natural (T.Other) / 2 mod 2 = 1 then Freight_G
            elsif Natural (T.Other) mod 2 = 1 then Freight_P
            else Passenger_P),
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
      --  decision: the brake percentage of the type is kept for the data
      --  view and the juridical records, but no model is derived from it
      --  for a gamma train: 3.13.2.2.5.1 derives one only with the
      --  conversion model, which EVC_Braking.Conversion_Applicable takes
      --  for Lambda only
      if F.Model = Gamma then
         EVC_Config.Gamma_Models (D);
      end if;
   end Of_Train_Type;

   --  The number of the image's sets flagged as keys
   function Key_Count return Natural
     with Global => EVC_Config.State,
          Post => Key_Count'Result <= EVC_Config.Train_Set_Count
   is
      N : Natural := 0;
   begin
      for J in 1 .. EVC_Config.Train_Set_Count loop
         pragma Loop_Invariant (N < J);
         if EVC_Config.Train_Set (J).Driver_Key then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Key_Count;

   function Driver_Type_Count return Natural is
     (if Key_Count > 0 then Key_Count
      else EVC_Config.Default_Train_Type_Count);

   function Driver_Type (I : Positive) return EVC_Config.Train_Type_T is
      N : Natural := 0;
   begin
      if Key_Count = 0 then
         return EVC_Config.Default_Train_Types (I);
      end if;
      for J in 1 .. EVC_Config.Train_Set_Count loop
         pragma Loop_Invariant (N < J);
         if EVC_Config.Train_Set (J).Driver_Key then
            N := N + 1;
            if N = I then
               return EVC_Config.Train_Set (J).Data;
            end if;
         end if;
      end loop;
      return EVC_Config.Default_Train_Types (1);
   end Driver_Type;

   procedure Take_Configuration_Set (I                  : Positive;
                                     Categories_Changed : out Boolean)
   is
      D : Train_Data_T;
      C : Categories_T;
   begin
      Of_Train_Type (EVC_Config.Train_Set (I).Data, EVC_Config.Current.Train,
                     D, C);
      Categories_Changed :=
        C.Cant_Deficiency /= Current_Categories.Cant_Deficiency
        or else C.Other /= Current_Categories.Other
        or else C.Axle_Load /= Current_Categories.Axle_Load
        or else C.Loading_Gauge /= Current_Categories.Loading_Gauge
        or else C.Voltages /= Current_Categories.Voltages;
      Set (D, C);
      By_Interface := True;
   end Take_Configuration_Set;

   procedure No_Configuration_Set is
   begin
      By_Interface := False;
   end No_Configuration_Set;

   procedure Invalidate is
   begin
      Is_Valid := False;
   end Invalidate;

   procedure Start_Manoeuvre_Set (F : EVC_Config.Fixed_Train_T) is
   begin
      Type_Index := 0;
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
      --  a gamma installation: the models of its gamma train (the
      --  configuration image, format version 2), as
      --  EVC_Mission.Train_Data_Of takes them for the driver's data
      if F.Model = Gamma then
         EVC_Config.Gamma_Models (SM_Data);
      end if;
      SM_Categories :=
        (Cant_Deficiency => F.SM_Cant_Deficiency,
         Other           => F.SM_Other,
         Axle_Load       => F.SM_Axle_Load,
         Loading_Gauge   => F.SM_Loading_Gauge,
         Voltages        => F.Voltages,
         Airtight        => F.SM_Airtight,
         N_Axle          => F.N_Axle);
      SM_Set := True;
      Is_Valid := False;
   end Start_Manoeuvre_Set;

   procedure End_Manoeuvre_Set is
   begin
      SM_Set := False;
   end End_Manoeuvre_Set;

end EVC_Train_Data;
