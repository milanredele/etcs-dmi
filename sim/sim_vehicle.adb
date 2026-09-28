--  ETCS DMI test simulator
--  The train interface of the bench: implementation.

with EVC_Train;

package body Sim_Vehicle is

   use type EVC_Bytes.Byte;

   Last_Commands : Byte := 0;
   Last_Reasons  : Byte := 0;
   Failed_Safe   : Boolean := False;
   Pressure      : Natural := 500;   -- kPa
   The_Controller : Byte := Forwards;

   --  What the on-board was last told (Natural'Last: nothing yet)
   Sent_Pressure   : Natural := Natural'Last;
   Sent_Controller : Natural := Natural'Last;
   Sent_Cab        : Boolean := False;

   procedure Reset is
   begin
      Last_Commands := 0;
      Last_Reasons := 0;
      Failed_Safe := False;
      Pressure := 500;
      The_Controller := Forwards;
      Sent_Pressure := Natural'Last;
      Sent_Controller := Natural'Last;
      Sent_Cab := False;
   end Reset;

   procedure Command (Commands, Reasons : Byte) is
   begin
      Last_Commands := Commands;
      Last_Reasons := Reasons;
   end Command;

   procedure Apply (Onboard_Failed : Boolean) is
   begin
      Failed_Safe := Onboard_Failed;
      EVC_Train.EB_Commanded :=
        Onboard_Failed or else (Last_Commands and EVC_Ports.TIU_EBC) /= 0;
      EVC_Train.SB_Commanded := (Last_Commands and EVC_Ports.TIU_SBC) /= 0;
      EVC_Train.Traction_Cut_Off :=
        Onboard_Failed or else (Last_Commands and EVC_Ports.TIU_TCO) /= 0;
   end Apply;

   procedure Measure is
      Driver : constant Float :=
        (if EVC_Train.Demand < 0 then Float (-EVC_Train.Demand) / 100.0
         else 0.0);
      Service : constant Float := Float'Max (Driver, EVC_Train.SB_Effort);
      Kpa : constant Float :=
        (500.0 - 150.0 * Float'Min (1.0, Service))
        * (1.0 - Float'Min (1.0, EVC_Train.EB_Effort));
   begin
      --  quantised before it reaches a port
      Pressure := Natural (Float'Floor (Float'Max (0.0,
                                                   Float'Min (500.0, Kpa))));
   end Measure;

   procedure Set_Controller (Position : Byte) is
   begin
      if Position <= Backwards then
         The_Controller := Position;
      end if;
   end Set_Controller;

   procedure Take_Inputs (List : out Input_List; Count : out Natural) is
      Units : constant Natural := Pressure / 4;
   begin
      List := (others => (0, 0));
      Count := 0;
      if not Sent_Cab then
         Count := Count + 1;
         List (Count) := (1, 1);             -- cab A active
         Sent_Cab := True;
      end if;
      if Sent_Controller /= Natural (The_Controller) then
         Count := Count + 1;
         List (Count) := (6, The_Controller);
         Sent_Controller := Natural (The_Controller);
      end if;
      if Sent_Pressure /= Units then
         Count := Count + 1;
         List (Count) := (12, Byte (Natural'Min (255, Units)));
         Sent_Pressure := Units;
      end if;
   end Take_Inputs;

   function Commands return Byte is (Last_Commands);
   function Reasons return Byte is (Last_Reasons);
   function Brake_Pressure_Kpa return Natural is (Pressure);
   function Controller return Byte is (The_Controller);
   function Fail_Safe return Boolean is (Failed_Safe);

end Sim_Vehicle;
