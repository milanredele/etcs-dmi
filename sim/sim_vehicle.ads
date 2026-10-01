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

   procedure Reset;

   --  The TIU output of the on-board: commands and reasons as
   --  EVC_Ports.TIU_Output has them (the reasons u16, one bit each)
   subtype Reasons_T is Interfaces.Unsigned_16;
   procedure Command (Commands : Byte; Reasons : Reasons_T);

   --  Before the vehicle moves: the commands onto EVC_Train (all brakes
   --  when the on-board failed)
   procedure Apply (Onboard_Failed : Boolean);

   --  After the vehicle moved: the brake pressure of now
   procedure Measure;

   procedure Set_Controller (Position : Byte);

   --  The inputs to give the on-board this period (power-up: all of
   --  them; then the ones that changed)
   Max_Inputs : constant := 3;
   type Input_List is array (1 .. Max_Inputs) of TIU_Input_T;
   procedure Take_Inputs (List : out Input_List; Count : out Natural);

   --  State, for the page and the tests
   function Commands return Byte;       -- the last TIU output
   function Reasons return Reasons_T;
   function Brake_Pressure_Kpa return Natural;
   function Controller return Byte;
   function Fail_Safe return Boolean;   -- braking for a failed on-board

end Sim_Vehicle;
