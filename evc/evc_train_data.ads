--  ETCS on-board (EVC)
--  The Train Data of the on-board (SUBSET-026 3.18.3), as far as the
--  stored information and the supervision use them.
--
--  Phase E3 had no data entry: the store held a documented default
--  train, valid from power-up. Phase E4 (e4/modes) fills it from the DMI
--  (the Train Data entry of the Start of Mission, 5.4, EVC_Mission)
--  through Set and Invalidate, and starts invalid (4.10); E6 adds the
--  data view and the other sources (5.17 is the procedures half's).
--
--  The default train (Default below): a passenger train in brake
--  position "Passenger train in P" with 135 % brake percentage (lambda
--  model, conversion model of 3.13.3), 200 m long, 160 km/h, cant
--  deficiency 130 mm (NC_CDTRAIN 2) and the "other international"
--  category "Passenger train" (NC_TRAIN bit 2), axle load category A,
--  loading gauge G1, traction system AC 25 kV 50 Hz, no special brake,
--  a traction cut-off time of 1 s.

with ETCS_Variables;        use ETCS_Variables;
with EVC_Supervision_Input; use EVC_Supervision_Input;

package EVC_Train_Data
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  The train categories of 3.11.3.3 and the route suitability data of
   --  3.12.2.3 (the parts of the Train Data the stored information uses)
   type Categories_T is record
      --  the one "Cant Deficiency" train category (3.11.3.3.2)
      Cant_Deficiency : NC_CDTRAIN_T := 2;
      --  the "other international" train categories (NC_TRAIN bits)
      Other           : NC_TRAIN_T := 4;
      Axle_Load       : M_AXLELOADCAT_T := 0;
      Loading_Gauge   : M_LOADINGGAUGE_T := 1;
      --  the traction systems accepted by the engine (M_VOLTAGE)
      Voltages        : Natural range 0 .. 2**16 - 1 := 2;  -- bit 1: AC 25
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

   --  The Train Data are valid (3.18.3; E4: validated by the driver)
   function Valid return Boolean
     with Global => State;

   function Data return Train_Data_T
     with Global => State;

   function Categories return Categories_T
     with Global => State;

   --  Power-up: no valid Train Data (4.10: deleted in No Power; phase
   --  E4, e4/modes: the driver enters them in the start of mission,
   --  EVC_Mission). Data keeps the default train as the values of the
   --  invalid set, which nothing supervises (EVC_Stored_Information:
   --  Supervise needs valid Train Data).
   procedure Clear
     with Global => (Output => State),
          Post => not Valid and then Data = Default
                  and then Categories = Default_Categories;

   --  New Train Data (phase E4)
   procedure Set (D : Train_Data_T; C : Categories_T)
     with Global => (Output => State),
          Post => Valid and then Data = D and then Categories = C;

   --  The Train Data are no longer valid (phase E4)
   procedure Invalidate
     with Global => (In_Out => State),
          Post => not Valid;

end EVC_Train_Data;
