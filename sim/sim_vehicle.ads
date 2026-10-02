--  ETCS DMI test simulator
--  The train interface (TIU, SUBSET-034) between the ETCS on-board and
--  the vehicle of the bench (EVC_Train).
--
--  Inputs to the on-board (EVC_Ports TIU signals): cab A active (the
--  desk of cab A is open from power-up, so the train runs cab A first
--  and the odometer counts up), the direction controller of that desk
--  (forwards; SUBSET-034 2.5.2) and the brake pressure (2.3.2) of the
--  main brake pipe: 500 kPa released, 350 kPa at a full service brake,
--  0 with the emergency brake, in between with the efforts of the
--  brakes (quantised to the 4 kPa of the port). A signal goes to the
--  on-board at power-up and whenever it changes.
--
--  Output of the on-board (EVC_Ports.TIU_Output): the emergency brake,
--  the service brake and the traction cut-off commands act on EVC_Train
--  (its brakes build up and release in their own times; see there). The
--  train interface is fail safe: an on-board that failed (EVC_Core.Failed)
--  falls silent, and the vehicle applies the emergency brake.

with EVC_Bytes;
with EVC_Ports;
with Interfaces;

package Sim_Vehicle is

   subtype Byte is EVC_Bytes.Byte;
   subtype TIU_Input_T is EVC_Bytes.Byte_Array (1 .. EVC_Ports.TIU_Length);

   --  Controller positions (the value of TIU signal 6)
   Neutral   : constant Byte := 0;
   Forwards  : constant Byte := 1;
   Backwards : constant Byte := 2;

   --  Cab status (TIU signals 1 and 2: "cab active" is "desk open"; a
   --  real desk cannot have both cabs active at once, which the bench
   --  enforces at the setter)
   type Cab_T is (No_Cab, Cab_A, Cab_B);

   procedure Reset;

   --  The TIU output of the on-board: commands and reasons as
   --  EVC_Ports.TIU_Output has them (the reasons u16, one bit each)
   subtype Reasons_T is Interfaces.Unsigned_16;
   procedure Command (Commands : Byte; Reasons : Reasons_T);

   --  The second TIU output (5.20, tag EVC_Ports.TIU_TC_Tag): the raw
   --  bytes, for the page to decode (test/tools/evc_dump.py shows the
   --  same shape); at most EVC_Ports.TIU_Out_Max_Length bytes
   TIU_TC_Max_Length : constant := EVC_Ports.TIU_Out_Max_Length;
   subtype TIU_TC_Array is EVC_Bytes.Byte_Array (1 .. TIU_TC_Max_Length);
   procedure Command_TC (Payload : TIU_TC_Array; Length : Natural);

   --  Before the vehicle moves: the commands onto EVC_Train (all brakes
   --  when the on-board failed)
   procedure Apply (Onboard_Failed : Boolean);

   --  After the vehicle moved: the brake pressure of now
   procedure Measure;

   --  The desk and the train interface inputs the bench exposes besides
   --  the demand slider and auto drive (SUBSET-034 2.5.1, 2.6.4.2): the
   --  cab, the direction controller, sleeping requested [3] [14],
   --  passive shunting permitted [26], non leading permitted [46], and
   --  the train configuration of TIU input 13 (phase E4, 5.17). Every
   --  setter takes effect at the next Take_Inputs.
   procedure Set_Cab (Cab : Cab_T);
   procedure Set_Controller (Position : Byte);
   procedure Set_Sleeping (On : Boolean);
   procedure Set_Passive_Shunting (On : Boolean);
   procedure Set_Non_Leading (On : Boolean);
   procedure Set_Train_Configuration (Value : Byte);

   --  The inputs to give the on-board this period (power-up: all of
   --  them; then the ones that changed)
   Max_Inputs : constant := 8;
   type Input_List is array (1 .. Max_Inputs) of TIU_Input_T;
   procedure Take_Inputs (List : out Input_List; Count : out Natural);

   --  State, for the page and the tests
   function Commands return Byte;       -- the last TIU output
   function Reasons return Reasons_T;
   function Brake_Pressure_Kpa return Natural;
   function Controller return Byte;
   function Fail_Safe return Boolean;   -- braking for a failed on-board
   function Cab return Cab_T;
   function Sleeping return Boolean;
   function Passive_Shunting return Boolean;
   function Non_Leading return Boolean;
   function Train_Configuration return Byte;

   --  The last track condition output (5.20), for the page
   function TC_Length return Natural;
   function TC_Payload return TIU_TC_Array;

end Sim_Vehicle;
