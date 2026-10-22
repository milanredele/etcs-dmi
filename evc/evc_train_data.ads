--  ETCS on-board (EVC)
--  The Train Data of the on-board (SUBSET-026 3.18.3), as far as the
--  stored information and the supervision use them.
--
--  The store starts invalid (4.10) and is filled from the DMI (the Train
--  Data entry of the Start of Mission, 5.4, EVC_Mission) through Set and
--  Invalidate; a change from another source is EVC_Procedures' (5.17).
--  The data view is not taken.
--
--  The default train (Default below): a passenger train in brake
--  position "Passenger train in P" with 135 % brake percentage (lambda
--  model, conversion model of 3.13.3), 200 m long, 160 km/h, cant
--  deficiency 130 mm (NC_CDTRAIN 2) and the "other international"
--  category "Passenger train" (NC_TRAIN bit 2), axle load category A,
--  loading gauge G1, traction system AC 25 kV 50 Hz, no special brake,
--  a traction cut-off time of 1 s.

with ETCS_Variables;        use ETCS_Variables;
with EVC_Config;
with EVC_Distances;         use type EVC_Distances.Cm_T;
with EVC_Supervision_Input; use EVC_Supervision_Input;

--  @req 3.18.3.4 a), 3.18.3.4 b), 3.18.3.4 c), 3.18.3.4 d), 3.18.3.4 e)
--  @req 3.18.3.4 f), 3.18.3.4 g), 3.18.3.4 h)
package EVC_Train_Data
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  The train categories of 3.11.3.3 and the route suitability data of
   --  3.12.2.3 (the parts of the Train Data the stored information uses)
   --  @req 3.11.3.3.2
   type Categories_T is record
      --  the one "Cant Deficiency" train category (3.11.3.3.2)
      Cant_Deficiency : NC_CDTRAIN_T := 2;
      --  the "other international" train categories (NC_TRAIN bits)
      Other           : NC_TRAIN_T := 4;
      Axle_Load       : M_AXLELOADCAT_T := 0;
      Loading_Gauge   : M_LOADINGGAUGE_T := 1;
      --  the traction systems accepted by the engine (M_VOLTAGE)
      Voltages        : Natural range 0 .. 2**16 - 1 := 2;  -- bit 1: AC 25
      --  the train is fitted with an airtight system (3.18.3.2 h)
      Airtight        : M_AIRTIGHT_T := 0;
   end record;

   Default_Categories : constant Categories_T := (others => <>);

   Default : constant Train_Data_T :=
     (Length                => 20_000,     -- 200 m
      Max_Speed             => 4_444,      -- 160 km/h (floor, cm/s)
      Model                 => Lambda,
      Brake_Percentage      => 135,
      Brake_Position        => Passenger_P,
      A_Brake_Emergency     => (Count => 0, Steps => (others => (0, 0))),
      A_Brake_Service       => (Count => 0, Steps => (others => (0, 0))),
      A_Brake_Normal        => (Count => 0, Steps => (others => (0, 0))),
      T_Brake_Emergency     => 0,
      T_Brake_Service       => 0,
      Has_Regenerative      => False,
      Has_Eddy_Current      => False,
      Has_Magnetic_Shoe     => False,
      Has_Electro_Pneumatic => False,
      T_Traction_Cut_Off    => 1_000);

   --  The Train Data are valid (3.18.3: validated by the driver)
   function Valid return Boolean
     with Global => State;

   function Data return Train_Data_T
     with Global => State;
   --  The train length of the Train Data (L_TRAIN, cm), without the record;
   --  3.18.3.2.4: with the safe consist length captured as part of valid
   --  Train Data, the max safe consist length in rear of the engine
   --  @req 3.18.3.2.4
   function Length return EVC_Distances.Length_T
     with Global => State;

   function Categories return Categories_T
     with Global => State;

   --  The safe consist length of an external source (3.18.3.2 b) 1st
   --  bullet, the TIU input of EVC_Ports): the nominal, minimum and
   --  maximum consist length in front of the engine (the side of its
   --  active cab) and in rear of it, metres (the range of packet 10)
   subtype Consist_Length_T is Natural range 0 .. 4095;
   type Consist_T is record
      Front_Nom, Front_Min, Front_Max : Consist_Length_T := 0;
      Rear_Nom, Rear_Min, Rear_Max    : Consist_Length_T := 0;
   end record;

   --  The safe consist length information is available now (the last
   --  input said so)
   function Consist_Available return Boolean
     with Global => State;

   --  A safe consist length was received in this mission (kept when the
   --  information becomes unavailable, 3.18.3.2.5)
   function Consist_Known return Boolean
     with Global => State;

   --  The safe consist length last received
   function Consist return Consist_T
     with Global => State;

   --  3.18.3.5: available, with a length in front of the engine
   function Consist_In_Front return Boolean is
     (Consist_Available and then Consist.Front_Max > 0)
     with Global => State;

   --  3.18.3.5 b): the driver may enter, modify or revalidate Train Data
   --  @req 3.18.3.5 b)
   function Entry_Possible return Boolean is (not Consist_In_Front)
     with Global => State;

   --  3.18.3.2.4: the train length when no valid Train Data is
   --  available but the safe consist length is (the max safe consist
   --  lengths in front of and in rear of the engine), cm
   function Consist_Length return EVC_Distances.Length_T
     with Global => State;

   --  A safe consist length input (EVC_Ports TIU signal 15): available
   --  with its lengths, or not available (the lengths kept, 3.18.3.2.5).
   --  3.18.3.5 a): with a length in front of the engine, no valid Train
   --  Data
   --  @req 3.18.3.2 b) 1st bullet, 3.18.3.2.5, 3.18.3.5, 3.18.3.5 a)
   procedure Take_Consist (Available : Boolean; C : Consist_T)
     with Global => (In_Out => State),
          Post => Manoeuvre_Set = Manoeuvre_Set'Old
                  and then Consist_Available = Available
                  and then (if Consist_In_Front then not Valid);

   --  Power-up: no valid Train Data (4.10: deleted in No Power; the
   --  driver enters them in the start of mission, EVC_Mission). Data
   --  keeps the default train as the values of the
   --  invalid set, which nothing supervises (EVC_Stored_Information:
   --  Supervise needs valid Train Data).
   procedure Clear
     with Global => (Output => State),
          Post => not Valid and then Data = Default
                  and then Categories = Default_Categories
                  and then not Consist_Available
                  and then not Consist_Known
                  and then not Manoeuvre_Set;

   --  New Train Data
   procedure Set (D : Train_Data_T; C : Categories_T)
     with Global => (In_Out => State),
          Post => Valid and then Data = D and then Categories = C
                  and then not Manoeuvre_Set;

   --  The Train Data are no longer valid
   procedure Invalidate
     with Global => (In_Out => State),
          Post => Manoeuvre_Set = Manoeuvre_Set'Old and then not Valid;

   --  3.18.3.9: the default Train Data of Supervised Manoeuvre are in
   --  force (Data, Length and Categories return them, Valid is False)
   function Manoeuvre_Set return Boolean
     with Global => State;

   --  3.18.3.9: the first Supervised Manoeuvre authorisation received:
   --  the configured default set of F in force, no valid Train Data;
   --  3.18.3.2.4: its train length is the sum of the max safe consist
   --  lengths in front of and in rear of the engine (Consist_Length,
   --  following a later safe consist length input)
   --  @req 3.18.3.9, 3.18.3.2.4
   procedure Start_Manoeuvre_Set (F : EVC_Config.Fixed_Train_T)
     with Global => (In_Out => State),
          Post => Manoeuvre_Set and then not Valid
                  and then Length = Consist_Length;

   --  3.18.3.9: the mission ended or continued in Non Leading: the
   --  default set no longer in force (the Train Data stay not valid)
   procedure End_Manoeuvre_Set
     with Global => (In_Out => State),
          Post => Valid = Valid'Old and then not Manoeuvre_Set;

end EVC_Train_Data;
