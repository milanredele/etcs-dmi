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
--  version; this one accepts version 1 only.
--
--  The state: the configuration in use (Current, the Default until an
--  image is loaded), whether an image was loaded, the images refused,
--  and the report of the last load for the juridical recording, which
--  EVC_Core writes at its next cycle (EVC_Ports, event 33). The state
--  survives EVC_Core.Initialise, as the installation does a power-up.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Bytes;             use EVC_Bytes;
with EVC_Distances;         use EVC_Distances;
with EVC_Ports;
with EVC_Supervision_Input; use EVC_Supervision_Input;
with Interfaces;            use Interfaces;

package EVC_Config
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  The balise antenna from an end of the engine, cm
   subtype Antenna_Offset_T is Length_T range 0 .. 100_000;

   --  Added by e4/modes: the fixed Train Data of the vehicle, the part
   --  of the Train Data of 3.18.3.2 that the driver does not enter (DMI
   --  Table 40 has length, brake percentage, maximum speed, categories,
   --  axle load, airtight and loading gauge), installation data
   --  (3.13.2.2.9.1.1). EVC_Mission builds the Train Data from the
   --  driver's entry and these. Not in the byte image of format version
   --  1: Decoded gives the defaults below (the train of E3), until a
   --  format version brings them with the train data view of E6 (the
   --  gamma models, the correction factors and the rotating mass of
   --  EVC_Supervision_Input.Train_Data_Extra_T go there too).
   type Fixed_Train_T is record
      --  the braking model (3.13.2.2.2): the lambda model only, the
      --  curves of the gamma model are not installation data here yet
      Model                 : Brake_Model_T := Lambda;
      --  the special brakes the vehicle has (3.13.2.2.6)
      Has_Regenerative      : Boolean := False;
      Has_Eddy_Current      : Boolean := False;
      Has_Magnetic_Shoe     : Boolean := False;
      Has_Electro_Pneumatic : Boolean := False;
      --  the traction cut-off time (3.13.2.2.8.2), ms
      T_Traction_Cut_Off    : Time_Ms_T := 1_000;
      --  the traction systems accepted by the engine (M_VOLTAGE bits,
      --  3.18.3.2 i): bit 1 AC 25 kV 50 Hz
      Voltages              : Natural range 0 .. 2**16 - 1 := 2;
   end record;

   Default_Fixed_Train : constant Fixed_Train_T := (others => <>);

   --  Added by e5/joint: the radio of the vehicle (3.5.2.4: "at least
   --  two" communication sessions through GSM-R; decision 2 of
   --  doc/EVC-PLAN.md §13: two are the default, one the degraded case
   --  of an on-board that handles a single session, 3.5.3.5.2.1,
   --  3.15.1.3.2.4). EVC_Radio takes it at the power-up. Not in the
   --  byte image of format version 1, as Fixed_Train_T: Decoded gives
   --  the default; the tests select one session with Set_Radio_For_Test
   --  until a format version brings it.
   subtype Radio_Sessions_T is
     Positive range 1 .. EVC_Ports.RTM_Max_Sessions;

   type Radio_Config_T is record
      Sessions : Radio_Sessions_T := EVC_Ports.RTM_Max_Sessions;
   end record;

   Default_Radio : constant Radio_Config_T := (others => <>);

   type Config_T is record
      Supervision      : Onboard_Config_T;
      Antenna_To_Cab_A : Antenna_Offset_T := 300;
      Antenna_To_Cab_B : Antenna_Offset_T := 1_700;
      --  added by e4/modes (see Fixed_Train_T)
      Train            : Fixed_Train_T;
      --  added by e5/joint (see Radio_Config_T)
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
   function Valid (C : Config_T) return Boolean is
     (for all B in Special_Brake_T =>
        Table_3 (B, C.Supervision.Special_Brakes (B)));

   --  The distance from the end of the engine the orientation S points
   --  to, to the antenna (3.6.1.3.4)
   function Front_Offset (C : Config_T; S : Sense_T) return Length_T is
     (if S = Plus then C.Antenna_To_Cab_A else C.Antenna_To_Cab_B);

   --  The configuration when no image was given: the choices of phase
   --  E3 (a service brake command with the feedback from the main brake
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

   ---------------------------------------------------------------------
   --  The byte image
   ---------------------------------------------------------------------

   Format_Version : constant := 1;
   Image_Length   : constant := 36;
   --  the bytes the CRC covers
   CRC_Offset     : constant := 32;
   subtype Image_T is Byte_Array (1 .. Image_Length);

   --  The outcome of a decoding (and of a load: Refused_In_Service is
   --  EVC_Core's, an image offered while the on-board runs)
   type Status_T is
     (Accepted,
      Truncated,           -- shorter than its header or its length
      Bad_Magic,
      Bad_Version,         -- a format version other than 1
      Bad_Length,          -- the length field is not that of version 1
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

   ---------------------------------------------------------------------
   --  The configuration in use
   ---------------------------------------------------------------------

   function Current return Config_T
     with Global => State,
          Post => Valid (Current'Result);

   --  A valid image was loaded since the start (else Current is Default)
   function Loaded return Boolean
     with Global => State;

   --  The images refused since the start (saturating)
   function Rejections return Natural
     with Global => State;

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

   --  The report was recorded
   procedure Report_Taken
     with Global => (In_Out => State),
          Post => Current = Current'Old
                  and then Loaded = Loaded'Old
                  and then not Report_Pending;

end EVC_Config;
