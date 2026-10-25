--  ETCS on-board (EVC)
--  The installation configuration of the on-board: what SUBSET-026 lets
--  the engineering of the on-board define for the vehicle it is fitted
--  to, as data and not as code. The same build of the on-board runs on
--  any vehicle; the configuration comes with the installation (a file
--  on the host, a block of flash on the target, a file of the bench
--  page) as a byte image, which EVC_Core.Configure loads.
--
--  Config_T (every value the SRS allows is accepted, the ranges below
--  are those of the SRS or of the installation):
--    Supervision  the configuration the speed and distance monitoring
--                 and the brake command handling read (the snapshot's
--                 Extra.Config, EVC_Supervision_Input.Onboard_Config_T):
--      service brake command implemented       3.13.2.2.7.1
--      service brake feedback implemented      3.13.2.2.7.2
--      the feedback from the brake cylinder    3.13.2.2.7.3, A.3.10.3
--      k1, thousandths, 1.000 to 5.000         A.3.10.3 ("normally
--                                              between 2.0 and 2.7")
--      traction cut-off command implemented    3.13.2.2.8.1
--      the interface with each special brake   3.13.2.2.6.1, Table 3
--      additional brake contribution allowed   3.13.2.2.6.4
--      the regenerative brake needs the
--      catenary (inhibited in a powerless
--      section)                                3.12.1.3.3
--      service brake failure: time beyond
--      T_bs, 0 to 60 s, and the deceleration
--      that counts as braking, 0 to 3 m/s²     3.14.1.2 (3.14.1.1)
--    Antenna_To_Cab_A, Antenna_To_Cab_B
--                 the balise antenna from each end of the engine, cm,
--                 0 to 1 km: the front end is the end the orientation
--                 points to (3.6.1.3.4), the balises are detected at the
--                 antenna (3.6.4.1.1 a, 3.13.10.2.7; the permitted
--                 braking distance of 3.11.11, EVC_PBD).
--
--  The ranges are those of the subtypes of the fields, which the decoder
--  checks. Valid enforces Table 3 of 3.13.2.2.6.1: for each special
--  brake the possibilities marked "x" (PDF page 122 of SUBSET-026-3
--  v4.0.0):
--                        no interface  EB only  SB only  both
--    regenerative             x           x        x       x
--    eddy current             x           x        x       x
--    magnetic shoe            x           x
--    Ep brake                 x                    x       x
--  An interface the table does not allow makes the configuration
--  invalid.
--
--  The byte image, format version 1, Image_Length (36) bytes; multi-byte
--  fields little endian, read and written byte by byte (EVC_Bytes):
--    offset size
--     0     4   magic "EVCF" (16#45# 16#56# 16#43# 16#46#)
--     4     2   format version u16 = 1
--     6     2   length u16 = 36, the whole image with its CRC
--     8     1   service brake command         0 / 1
--     9     1   service brake feedback        0 / 1
--    10     1   feedback from the cylinder    0 / 1
--    11     1   traction cut-off              0 / 1
--    12     2   k1 u16, thousandths           1000 .. 5000
--    14     1   regenerative brake interface  0 no interface,
--    15     1   eddy current brake interface  1 emergency brake model
--    16     1   magnetic shoe brake interface   only, 2 service brake
--    17     1   Ep brake interface              model only, 3 both
--    18     1   additional brake allowed      0 / 1
--    19     1   regenerative needs catenary   0 / 1
--    20     4   antenna to cab A u32, cm      0 .. 100_000
--    24     4   antenna to cab B u32, cm      0 .. 100_000
--    28     2   SB failure time u16, ms       0 .. 60_000
--    30     2   SB failure deceleration u16,  0 .. 3_000
--               mm/s²
--    32     4   CRC-32 u32 of bytes 0 .. 31: the CRC of IEEE 802.3
--               (polynomial 16#04C1_1DB7#, reflected 16#EDB8_8320#,
--               initial value and final xor 16#FFFF_FFFF#; the CRC of
--               zlib, Python's binascii.crc32; "123456789" gives
--               16#CBF4_3926#)
--  The bytes after the length are ignored: a block of flash larger than
--  the image can be handed over whole. A later format gets a new
--  version; versions 1 and 2 are accepted, the version decides the
--  length.
--
--  The byte image, format version 2 (Encode_V2): the bytes 0 to 31 of
--  version 1 (the version 2, the length L, 38 to Max_Image_Length 1248),
--  then the train, then the CRC-32 at L - 4 of the bytes 0 .. L - 5:
--    32     1   braking model                 0 lambda (the conversion
--               (Fixed_Train_T.Model)           model of the brake
--                                               percentage), 1 gamma
--    33     1   the special brakes the        bit 0 regenerative,
--               vehicle has (Fixed_Train_T)   bit 1 eddy current,
--               3.13.2.2.6                    bit 2 magnetic shoe,
--                                             bit 3 Ep; 0 .. 15
--    34     4   (lambda) the CRC: L = 38
--  A gamma train (Gamma_T), from 34 on, field after field:
--           2   T_brake_react emergency, ms   0 .. 60_000 (3.13.2.2.3.2)
--           2   T_brake_build_up emergency    0 .. 60_000
--           2   T_brake_react service, ms     0 .. 60_000
--           2   T_brake_build_up service      0 .. 60_000
--           c   A_brake_emergency (V)         a curve of 1 to 8 steps
--           c   A_brake_service (V)           a curve of 1 to 8 steps
--           c   A_brake_normal_service (V)    a curve of 0 to 8 steps
--                                             (used when no set below)
--         160   Kdry_rst (V, EBCL), 3.13.2.2.9.1: for M_NVEBCL 0 to 9,
--               8 u16 each, one per step of A_brake_emergency (the
--               steps beyond its count unused), thousandths 0 .. 2_000
--          16   Kwet_rst (V): 8 u16, thousandths 0 .. 2_000
--           c   Kn+ (V), 3.13.2.2.9.2         a curve of 0 to 8 steps,
--           c   Kn- (V)                       mm/s² per unit of gradient
--           1   M_rotating_nom, % 3.13.2.2.10 0 .. 100 (0: not given,
--                                             A.3.1 applies)
--           1   normal service sets           0 none, 1 given:
--           4     A_SB01, A_SB12 u16, mm/s²   0 .. 30_000 (3.13.2.2.3.1.10)
--          6c     A_brake_normal_service_0 .. _2 in G, then in P
--                 (3.13.2.2.3.1.9 a) and b), each 0 to 8 steps
--           1   by combination of special     0 no (the models above
--               brakes in use                   for every combination),
--                                             1 yes:
--          8c     A_brake_emergency (V) for the combinations 0 .. 7 of
--                 regenerative (bit 0), eddy current (bit 1) and
--                 magnetic shoe (bit 2) brake (3.13.2.2.3.1.7), each 1 to
--                 8 steps
--          8c     A_brake_service (V) for the same combinations
--          64     T_brake_react, T_brake_build_up emergency, u16 ms 0 ..
--                 60_000, for the combinations 0 .. 15 of the four (bit
--                 3 Ep, 3.13.2.2.3.2.8 Table 4)
--          64     the same for the service brake
--           4   CRC-32
--  A curve c: a count byte n, then n steps of (u16 speed, cm/s 0 ..
--  30_000, u16 deceleration, mm/s² 0 .. 30_000), the speeds strictly
--  rising: the deceleration of a step applies up to its speed, the last
--  step open ended (3.13.2.2.3.1.3, .4); 1 + 4 n bytes. A field out of
--  its range or a count out of its range is Bad_Field; fields that end
--  before or run past the CRC are Bad_Length.
--
--  The state: the configuration in use (Current, the Default until an
--  image is loaded), whether an image was loaded, the images refused,
--  and the report of the last load for the juridical recording, which
--  EVC_Core writes at its next cycle (EVC_Ports, event 33). The state
--  survives EVC_Core.Initialise, as the installation does a power-up.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Variables;        use ETCS_Variables;
with EVC_Bytes;             use EVC_Bytes;
with EVC_Distances;         use EVC_Distances;
with EVC_Ports;
with EVC_Supervision_Input; use EVC_Supervision_Input;
with Interfaces;            use Interfaces;

--  @req 3.13.2.2.6.1, 3.13.2.2.6.4, 3.13.2.2.7.1, 3.13.2.2.7.2, 3.13.2.2.8.1
--  @req 3.14.1.2, A.3.10.3
package EVC_Config
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  The balise antenna from an end of the engine, cm
   subtype Antenna_Offset_T is Length_T range 0 .. 100_000;

   --  the fixed Train Data of the vehicle, the part
   --  of the Train Data of 3.18.3.2 that the driver does not enter (DMI
   --  Table 40 has length, brake percentage, maximum speed, categories,
   --  axle load, airtight and loading gauge), installation data
   --  (3.13.2.2.9.1.1). EVC_Mission builds the Train Data from the
   --  driver's entry and these. The image of format version 2 carries
   --  the braking model and the special brakes; the other fields are
   --  the defaults below in both versions (the default train). The
   --  models and factors of a gamma train are Gamma_T, beside.
   type Fixed_Train_T is record
      --  the braking model (3.13.2.2.2): the conversion model of the
      --  brake percentage the driver enters (Lambda), or the braking
      --  models of the installation (Gamma, Gamma_T)
      Model                 : Brake_Model_T := Lambda;
      --  the special brakes the vehicle has (3.13.2.2.6)
      Has_Regenerative      : Boolean := False;
      Has_Eddy_Current      : Boolean := False;
      Has_Magnetic_Shoe     : Boolean := False;
      Has_Electro_Pneumatic : Boolean := False;
      --  the traction cut-off time (3.13.2.2.2.1), ms
      T_Traction_Cut_Off    : Time_Ms_T := 1_000;
      --  the traction systems accepted by the engine (M_VOLTAGE bits,
      --  3.18.3.2 i): bit 1 AC 25 kV 50 Hz
      Voltages              : Natural range 0 .. 2**16 - 1 := 2;
      --  the length of the engine, cm: its front and rear end are the
      --  train's in SL, SB without valid Train Data, SH, NL and PS
      --  (4.4.6.1.4, 4.4.7.1.6, 4.4.8.1.3, 4.4.15.1.3, 4.4.20.1.4);
      --  decision: 20 m, a locomotive, until a format version of the
      --  image carries it
      Engine_Length         : Length_T range 100 .. 10_000 := 2_000;
      --  the number of axles of the train (3.18.3.2 k), N_AXLE of packet
      --  11 (3.18.3.4 i). Decision: an installation datum, the axles of
      --  the engine: the consist's are not known to the on-board without
      --  an input (the DMI's Train Data window has no field for them, the
      --  train interface no signal); 4, a locomotive, until a format
      --  version of the image carries it
      N_Axle                : N_AXLE_T := 4;
      --  3.18.3.9: the default Train Data of a mission in Supervised
      --  Manoeuvre, every item of 3.18.3.2 but the length b) (the
      --  braking model, the special brakes, the traction cut-off time
      --  and the traction systems are the fixed values above).
      --  Decision: a shunting locomotive, until a format version of the
      --  image carries them: 80 km/h, brake percentage 100 in position
      --  "Passenger train in P", cant deficiency 80 mm (NC_CDTRAIN 0), no
      --  "other international" category, axle load category A, loading
      --  gauge G1, no airtight system
      SM_Max_Speed          : Speed_Cms_T := 2_222;
      SM_Brake_Percentage   : Natural range 10 .. 250 := 100;
      SM_Brake_Position     : Brake_Position_T := Passenger_P;
      SM_Cant_Deficiency    : NC_CDTRAIN_T := 0;
      SM_Other              : NC_TRAIN_T := 0;
      SM_Axle_Load          : M_AXLELOADCAT_T := 0;
      SM_Loading_Gauge      : M_LOADINGGAUGE_T := 1;
      SM_Airtight           : M_AIRTIGHT_T := 0;
   end record;

   Default_Fixed_Train : constant Fixed_Train_T := (others => <>);

   --  A pre-configured train type of the fixed Train Data entry (DMI
   --  11.3.9.6 a: "a combination of all train data", the key of the
   --  dedicated keyboard of Table 39): its name (DMI 11.3.9.8.2 leaves
   --  the naming outside the specification) and the items of the
   --  driver's entry (DMI Table 40) in the codes of MSG_DRIVER_DATA kind
   --  2; the braking model, the special brakes, the traction cut-off
   --  time and the traction systems are those of Fixed_Train_T.
   Train_Types_Max     : constant := 8;
   Train_Type_Name_Max : constant := 16;
   type Train_Type_T is record
      Name             : String (1 .. Train_Type_Name_Max) := (others => ' ');
      Name_Length      : Natural range 1 .. Train_Type_Name_Max := 1;
      Length_M         : Natural range 1 .. 4_095 := 20;
      Brake_Percentage : Natural range 10 .. 250 := 100;
      Max_Speed_Kmh    : Natural range 0 .. 600 := 80;
      Cant_Deficiency  : NC_CDTRAIN_T := 0;
      Other            : NC_TRAIN_T := 0;
      Axle_Load        : M_AXLELOADCAT_T := 0;
      Airtight         : M_AIRTIGHT_T := 0;
      Loading_Gauge    : M_LOADINGGAUGE_T := 1;
   end record;
   type Train_Type_List_T is array (1 .. Train_Types_Max) of Train_Type_T;

   --  The train types of the installation (3.18.3.2.1: the Train Data
   --  may come from pre-configured values). Decision: two, until a
   --  format version of the image carries them: "Locomotive", the
   --  shunting locomotive of the Supervised Manoeuvre defaults above
   --  (20 m, the engine's length, 100 %, 80 km/h, no category, axle
   --  load A, gauge G1, not airtight) and "Passenger", a passenger train
   --  of 200 m (PASS 1: NC_CDTRAIN 0, the passenger bit of NC_TRAIN),
   --  135 %, 160 km/h, axle load A, gauge G1, not airtight.
   Default_Train_Type_Count : constant := 2;
   --  @req 3.18.3.2
   Default_Train_Types : constant Train_Type_List_T :=
     (1      => (Name        => "Locomotive      ",
                 Name_Length => 10,
                 others      => <>),
      2      => (Name             => "Passenger       ",
                 Name_Length      => 9,
                 Length_M         => 200,
                 Brake_Percentage => 135,
                 Max_Speed_Kmh    => 160,
                 Other            => 4,
                 others           => <>),
      others => (others => <>));

   --  the radio of the vehicle (3.5.2.4: "at least
   --  two" communication sessions through GSM-R; decision 2 of
   --  doc/EVC-PLAN.md §13: two are the default, one the degraded case
   --  of an on-board that handles a single session, 3.5.3.5.2.1,
   --  3.15.1.3.2.4). EVC_Radio takes it at the power-up. Not in the
   --  byte image of format version 1, as Fixed_Train_T: Decoded gives
   --  the default; the tests select one session with Set_Radio_For_Test
   --  until a format version brings it.
   subtype Radio_Sessions_T is
     Positive range 1 .. EVC_Ports.RTM_Max_Sessions;

   --  the ETCS identity of the on-board,
   --  NID_ENGINE of the train to track messages (7.5.1.86, 8.4.4.7.1),
   --  24 bits; 0 until a format version of the image carries it (the
   --  tests and the SUBSET-076 bench set it with Set_Radio_For_Test)
   subtype Engine_Id_T is Natural range 0 .. 2**24 - 1;

   --  the radio systems installed
   --  on-board (3.5.6.7, 5.4.3.2 D7), the Radio Network type
   --  (Q_NETWORKTYPE 0 FRMCS, 1 FRMCS+GSM-R, 2 GSM-R, 7.5.1.120.1) used
   --  while none was memorized (3.5.6.4) and the default GSM-R Radio
   --  Network identity (NID_MN, 7.5.1.91.1: up to six digits, one per
   --  nibble, left adjusted, F the filler) of 3.5.6.3. Not in the image
   --  of format version 1: both systems, GSM-R, NID_MN 0 ("000000")
   type Radio_Systems_T is (FRMCS_Only, GSMR_Only, Both_Systems);
   type Network_Type_T is (FRMCS, FRMCS_GSMR, GSMR);
   subtype Network_Id_T is Natural range 0 .. 2**24 - 1;

   --  @req 3.5.2.4, 3.5.6.3, 3.5.6.4
   type Radio_Config_T is record
      Sessions     : Radio_Sessions_T := EVC_Ports.RTM_Max_Sessions;
      Engine_Id    : Engine_Id_T := 0;
      Systems      : Radio_Systems_T := Both_Systems;
      Default_Type : Network_Type_T := GSMR;
      Default_MN   : Network_Id_T := 0;
   end record;

   Default_Radio : constant Radio_Config_T := (others => <>);

   type Config_T is record
      Supervision      : Onboard_Config_T;
      Antenna_To_Cab_A : Antenna_Offset_T := 300;
      Antenna_To_Cab_B : Antenna_Offset_T := 1_700;
      --  (see Fixed_Train_T)
      Train            : Fixed_Train_T;
      --  (see Radio_Config_T)
      Radio            : Radio_Config_T;
   end record;

   --  3.13.2.2.6.1 Table 3: the interface I is a possibility for the
   --  special brake B
   function Table_3 (B : Special_Brake_T; I : Special_Brake_Interface_T)
     return Boolean
   is (case B is
          when Regenerative | Eddy_Current => True,
          when Magnetic_Shoe     => I in No_Interface | Emergency_Only,
          when Electro_Pneumatic => I /= Emergency_Only);

   --  A configuration: its fields are in the ranges of their subtypes
   --  (the decoder checks every field of an image against them before
   --  it builds one), and every special brake has an interface Table 3
   --  allows
   --  @req 3.13.2.2.6.1 Table 3
   function Valid (C : Config_T) return Boolean is
     (for all B in Special_Brake_T =>
        Table_3 (B, C.Supervision.Special_Brakes (B)));

   --  The distance from the end of the engine the orientation S points
   --  to, to the antenna (3.6.1.3.4)
   function Front_Offset (C : Config_T; S : Sense_T) return Length_T is
     (if S = Plus then C.Antenna_To_Cab_A else C.Antenna_To_Cab_B);

   --  The configuration when no image was given: the default choices
   --  (a service brake command with the feedback from the main brake
   --  pipe, the traction cut-off, the status of every special brake
   --  counting for both brake models except the magnetic shoe brake,
   --  which Table 3 allows for the emergency brake model only, the
   --  additional brake not independent from the adhesion, a regenerative
   --  brake that needs the catenary), the service brake failure after
   --  T_bs + 2 s without 0.1 m/s² of deceleration, the antenna 3 m from
   --  cab A and 17 m from cab B
   Default : constant Config_T :=
     (Supervision      =>
        (Service_Brake_Command       => True,
         Service_Brake_Feedback      => True,
         Feedback_From_Cylinder      => False,
         K1_Milli                    => 2_500,
         Traction_Cut_Off            => True,
         Special_Brakes              =>
           (Regenerative      => Emergency_And_Service,
            Eddy_Current      => Emergency_And_Service,
            Magnetic_Shoe     => Emergency_Only,
            Electro_Pneumatic => Emergency_And_Service),
         Additional_Brake_Allowed    => False,
         Regenerative_Needs_Catenary => True,
         SB_Failure_Time_Ms          => 2_000,
         SB_Failure_Decel_Mms2       => 100),
      Antenna_To_Cab_A => 300,
      Antenna_To_Cab_B => 1_700,
      Train            => Default_Fixed_Train,
      Radio            => Default_Radio);

   --  The byte image

   --  the highest format version accepted (1 and 2 are)
   Format_Version : constant := 2;
   --  version 1: its length and the bytes its CRC covers
   Image_Length   : constant := 36;
   CRC_Offset     : constant := 32;
   subtype Image_T is Byte_Array (1 .. Image_Length);
   --  version 2: the shortest image (a lambda train) and the longest (a
   --  gamma train with every step function at 8 steps, the normal
   --  service sets and the models by combination)
   Min_Image_V2_Length : constant := 38;
   Max_Image_Length    : constant := 1_248;
   subtype Max_Image_T is Byte_Array (1 .. Max_Image_Length);

   --  the braking models of a gamma train (3.13.2.2.3, 3.13.2.2.9,
   --  3.13.2.2.10), installation data (3.18.3.2.1): the models of the
   --  Train Data and the rest of EVC_Supervision_Input.Train_Data_Extra_T
   --  @req 3.18.3.2 c) 4th bullet, 3.18.3.2 c) 5th bullet
   type Gamma_T is record
      A_Brake_Emergency : Decel_Curve_T := No_Decel_Curve;
      A_Brake_Service   : Decel_Curve_T := No_Decel_Curve;
      A_Brake_Normal    : Decel_Curve_T := No_Decel_Curve;
      --  the equivalent brake build up times, ms (the reaction times
      --  are in Extra)
      T_Brake_Emergency : Time_Ms_T := 0;
      T_Brake_Service   : Time_Ms_T := 0;
      Extra             : Train_Data_Extra_T := (others => <>);
   end record;

   No_Gamma : constant Gamma_T := (others => <>);

   --  The outcome of a decoding (and of a load: Refused_In_Service is
   --  EVC_Core's, an image offered while the on-board runs)
   type Status_T is
     (Accepted,
      Truncated,           -- shorter than its header or its length
      Bad_Magic,
      Bad_Version,         -- a format version other than 1 and 2
      --  the length field is not that of the version, or the fields of
      --  version 2 do not end at the CRC
      Bad_Length,
      Bad_CRC,
      Bad_Field,           -- a field out of its range
      Table_3_Violated,    -- 3.13.2.2.6.1
      Refused_In_Service); -- not in No Power (EVC_Core.Configure)

   --  CRC-32 of IEEE 802.3 (see above)
   function CRC_32 (Data : Byte_Array) return Unsigned_32;

   type Decoded_T is record
      Status : Status_T := Truncated;
      Config : Config_T := Default;
   end record;

   --  The image in Bytes: Accepted and its configuration, which is then
   --  valid, or why not (and Default). Never fails, whatever the bounds
   --  of Bytes.
   function Decoded (Bytes : Byte_Array) return Decoded_T
     with Post => Decoded'Result.Status /= Refused_In_Service
                  and then (if Decoded'Result.Status = Accepted
                            then Valid (Decoded'Result.Config));

   procedure Decode (Bytes  : Byte_Array;
                     Config : out Config_T;
                     OK     : out Boolean)
     with Post => OK = (Decoded (Bytes).Status = Accepted)
                  and then Config = Decoded (Bytes).Config
                  and then (if OK then Valid (Config));

   --  The image of C (for the tools and the tests; Decoded gives C back
   --  when C is valid)
   function Encode (C : Config_T) return Image_T;

   --  The image of format version 2 of C and, when C.Train.Model is
   --  Gamma, of the gamma train G, in Image (1 .. Length), the rest 0
   --  (for the bench and the tests; Decoded gives C back, and a load
   --  G, when C is valid and G within the ranges of the layout above)
   procedure Encode_V2 (C      : Config_T;
                        G      : Gamma_T;
                        Image  : out Max_Image_T;
                        Length : out Natural)
     with Post => Length in Min_Image_V2_Length .. Max_Image_Length;

   --  The configuration in use

   function Current return Config_T
     with Global => State,
          Post => Valid (Current'Result);

   --  the radio part of Current, without copying the
   --  whole configuration
   function Current_Radio return Radio_Config_T
     with Global => State,
          Post => Current_Radio'Result = Current.Radio;

   --  A valid image was loaded since the start (else Current is Default)
   function Loaded return Boolean
     with Global => State;

   --  The images refused since the start (saturating)
   function Rejections return Natural
     with Global => State;

   --  The braking models of the gamma train of the configuration in use
   --  into the Train Data D (its other fields kept): the models and the
   --  equivalent build up times, none when the image gave no gamma train
   --  @req 3.18.3.2 c)
   procedure Gamma_Models (D : in out Train_Data_T)
     with Global => (Input => State),
          Post => D.Model = D.Model'Old
                  and then D.Length = D.Length'Old
                  and then D.Max_Speed = D.Max_Speed'Old
                  and then D.Brake_Percentage = D.Brake_Percentage'Old;

   --  The rest of the gamma train of the configuration in use (the
   --  reaction times, the correction factors, the normal service sets,
   --  the rotating mass, the models by combination), the defaults when
   --  the image gave no gamma train; read in place, not returned
   --  @req 3.18.3.2 c) 4th bullet, 3.18.3.2 c) 5th bullet
   procedure Gamma_Extra (X : out Train_Data_Extra_T)
     with Global => (Input => State);

   --  A load or a refusal waits to be recorded (EVC_Core), with its
   --  outcome
   function Report_Pending return Boolean
     with Global => State;
   function Last_Status return Status_T
     with Global => State;

   --  Load the image in Bytes: when it is valid it becomes Current,
   --  otherwise nothing but the count of refusals changes
   procedure Load (Bytes : Byte_Array)
     with Global => (In_Out => State),
          Post => (if Decoded (Bytes).Status = Accepted
                   then Current = Decoded (Bytes).Config and then Loaded
                   else Current = Current'Old
                        and then Loaded = Loaded'Old)
                  and then Report_Pending
                  and then Last_Status = Decoded (Bytes).Status;

   --  Refuse an image for a reason outside it (Why)
   procedure Refuse (Why : Status_T)
     with Global => (In_Out => State),
          Pre  => Why /= Accepted,
          Post => Current = Current'Old
                  and then Loaded = Loaded'Old
                  and then Report_Pending
                  and then Last_Status = Why;

   --  For the tests of the hosts, not for an on-board in service: the
   --  radio of the configuration in use becomes R (a field the image of
   --  format version 1 does not carry, Radio_Config_T); everything else
   --  stays. EVC_Radio takes it at the next power-up of EVC_Core.
   procedure Set_Radio_For_Test (R : Radio_Config_T)
     with Global => (In_Out => State),
          Post => Current.Radio = R
                  and then Current.Supervision = Current.Supervision'Old
                  and then Current.Antenna_To_Cab_A
                             = Current.Antenna_To_Cab_A'Old
                  and then Current.Antenna_To_Cab_B
                             = Current.Antenna_To_Cab_B'Old
                  and then Current.Train = Current.Train'Old
                  and then Loaded = Loaded'Old
                  and then Report_Pending = Report_Pending'Old;

   --  For the tests of the hosts, not for an on-board in service: the
   --  traction systems the engine accepts (Fixed_Train_T.Voltages, the
   --  M_VOLTAGE bits; bit 0 an engine able to run on a line not fitted
   --  with any traction system, 3.12.2.3.1) of the configuration in use
   --  become V; everything else stays. EVC_Mission takes them into the
   --  next Train Data.
   procedure Set_Voltages_For_Test (V : Natural)
     with Global => (In_Out => State),
          Pre  => V <= 2**16 - 1,
          Post => Current.Train.Voltages = V
                  and then Current.Radio = Current.Radio'Old
                  and then Current.Supervision = Current.Supervision'Old
                  and then Loaded = Loaded'Old
                  and then Report_Pending = Report_Pending'Old;

   --  The report was recorded
   procedure Report_Taken
     with Global => (In_Out => State),
          Post => Current = Current'Old
                  and then Loaded = Loaded'Old
                  and then not Report_Pending;

end EVC_Config;
