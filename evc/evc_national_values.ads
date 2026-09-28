--  ETCS on-board (EVC)
--  The National Values (SUBSET-026 3.18.2, packet 3 of 7.4.2.3, the
--  default values of A.3.2).
--
--  The store keeps the whole set of the packet in on-board units: the
--  part the supervision reads (National_Values_T of
--  EVC_Supervision_Input) and the rest (T_NVCONTACT and its reaction,
--  M_NVDERUN, Q_NVLOCACC), with the countries or regions (NID_C) it
--  was received for. Until a set is received, and whenever the one in
--  use is found invalid, every value is its default of A.3.2 (3.18.2.5).
--
--  Reception (3.18.2.3): a set given with D_VALIDNV "now" applies at
--  once; otherwise it waits, as the one set not yet applicable, until
--  the estimated front end reaches its location (the "estimated"
--  location item of Table 2a) and then overwrites the values in use
--  whatever their countries (3.18.2.8.1). A new set received deletes
--  the one not yet applicable (3.18.2.9 first bullet).
--
--  Countries (3.18.2.4, 3.18.2.5 second bullet, 3.18.2.10): the NID_C of
--  every balise group taken into account is compared with the
--  countries of the set in use; a group of another country makes the
--  set invalid, and the defaults apply until a set is received again.
--
--  Conversions: speeds of 5 km/h steps to cm/s rounded down, distances
--  with Q_SCALE to cm, times to ms, the factors (M_NVKVINT 0.02,
--  M_NVKRINT, M_NVKTINT and M_NVAVADH 0.05) to thousandths, the
--  decelerations (0.05 m/s²) to mm/s²; "no maximum deceleration"
--  (A_NVMAXREDADHx 61 to 63) is Decel_Mms2_T'Last, an infinite
--  D_NVROLL, D_NVSTFF or T_NVCONTACT the largest value of its type. The
--  steps of Kv_int and Kr_int keep the first Max_Kv_Steps (the SRS
--  allows five, 3.13.2.3.7.11.1 and .12.1).
--
--  Not in phase E3: keeping the set in use over No Power (3.18.2.7,
--  E4 with the storage of 4.11), the subsets of 3.18.2.6 by system
--  version (E6), Q_NVLOCACC in the position (a constant of E2).

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Track_Packets.P3;
with ETCS_Variables;        use ETCS_Variables;
with EVC_Distances;         use EVC_Distances;
with EVC_Profiles;          use EVC_Profiles;
with EVC_Supervision_Input; use EVC_Supervision_Input;

package EVC_National_Values
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   Max_Countries : constant := 32;

   type Countries_T is array (1 .. Max_Countries) of NID_C_T;

   type Set_T is record
      Values           : National_Values_T;
      --  T_NVCONTACT and its reaction (0 trip, 1 service brake, 2 none)
      M_NVCONTACT      : Natural range 0 .. 2 := 2;
      T_NVCONTACT      : Time_Ms_T := Time_Ms_T'Last;
      M_NVDERUN        : Boolean := True;
      Q_NVLOCACC       : Length_T := 1_200;
      --  received from the trackside (not the defaults), for these
      --  countries or regions
      From_Trackside   : Boolean := False;
      Country_Count    : Natural range 0 .. Max_Countries := 0;
      Countries        : Countries_T := (others => 0);
   end record;

   --  A.3.2
   function Kmh_To_Cms (Kmh : Natural) return Speed_Cms_T is
     (Speed_Cms_T (Natural'Min (Kmh, 1_000) * 250 / 9))
     with Pre => Kmh <= 1_000;

   Default_Values : constant National_Values_T :=
     (M_NVEBCL           => 9,
      Q_NVGUIPERM        => False,
      Q_NVSBTSMPERM      => True,
      Q_NVINHSMICPERM    => False,
      Q_NVEMRRLS         => False,          -- only at standstill
      Q_NVSBFBPERM       => False,
      V_NVREL            => 1_111,          -- 40 km/h
      D_NVROLL           => 200,            -- 2 m
      V_NVALLOWOVTRP     => 0,
      V_NVSUPOVTRP       => 833,            -- 30 km/h
      D_NVOVTRP          => 20_000,         -- 200 m
      T_NVOVTRP          => 60_000,         -- 60 s
      D_NVPOTRP          => 20_000,         -- 200 m
      V_NVSHUNT          => 833,            -- 30 km/h
      V_NVSTFF           => 1_111,          -- 40 km/h
      V_NVONSIGHT        => 833,            -- 30 km/h
      V_NVLIMSUPERV      => 2_777,          -- 100 km/h
      V_NVUNFIT          => 2_777,          -- 100 km/h
      D_NVSTFF           => Max_Cm,         -- no default: no limit
      M_NVAVADH          => 0,
      A_NVMAXREDADH1     => 1_000,          -- 1.0 m/s²
      A_NVMAXREDADH2     => 700,
      A_NVMAXREDADH3     => 700,
      Q_NVDRIVER_ADHES   => False,
      --  one step each, valid for every speed and length (A.3.2 note)
      Kv_Int_Fresh       => (Count => 1, Steps => (others => (0, 700))),
      Kv_Int_Passenger   => (Count => 1, Steps => (others => (0, 700))),
      Kr_Int             => (Count => 1, Steps => (others => (0, 900))),
      Kt_Int             => 1_100,
      Kv_Int_Passenger_B => (Count => 1, Steps => (others => (0, 700))),
      A_NVP12            => 0,
      A_NVP23            => 0);

   Default_Set : constant Set_T := (Values => Default_Values, others => <>);

   --  The set in use
   function Current return Set_T
     with Global => State;

   --  A set is waiting for its location, which is Pending_At
   function Pending return Boolean
     with Global => State;
   function Pending_At return Location_T
     with Global => State;

   --  The values E0 used
   function V_NVALLOWOVTRP return Speed_Cms_T is
     (Current.Values.V_NVALLOWOVTRP)
     with Global => State;
   function M_NVDERUN return Boolean is (Current.M_NVDERUN)
     with Global => State;
   function Q_NVDRIVER_ADHES return Boolean is
     (Current.Values.Q_NVDRIVER_ADHES)
     with Global => State;

   --  The set of a packet 3 (conversions above)
   function From_Packet (P : ETCS_Track_Packets.P3.Packet_T) return Set_T
     with Post => From_Packet'Result.From_Trackside;

   --  Power-up: the defaults, nothing waiting
   procedure Clear
     with Global => (Output => State),
          Post => Current = Default_Set and then not Pending;

   --  A packet 3 of a group message: applicable now, or at At_Location
   procedure Receive (P           : ETCS_Track_Packets.P3.Packet_T;
                      Immediate   : Boolean;
                      At_Location : Location_T)
     with Global => (In_Out => State),
          Post => (if Immediate
                   then not Pending and then Current.From_Trackside
                   else Pending and then Pending_At = At_Location);

   --  The set waiting becomes the one in use (3.18.2.8.1)
   procedure Apply_Pending
     with Global => (In_Out => State),
          Post => not Pending;

   --  A balise group of the country NID_C was read: Reverted when the set
   --  in use was not for it and the defaults apply again (3.18.2.10)
   procedure Check_Country (NID_C : NID_C_T; Reverted : out Boolean)
     with Global => (In_Out => State),
          Post => (if Reverted then Current = Default_Set);

end EVC_National_Values;
