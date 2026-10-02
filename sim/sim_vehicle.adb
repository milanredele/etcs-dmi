--  ETCS DMI test simulator
--  The train interface of the bench: implementation.

with EVC_Train;

package body Sim_Vehicle is

   use type EVC_Bytes.Byte;

   Last_Commands : Byte := 0;
   Last_Reasons  : Reasons_T := 0;
   Failed_Safe   : Boolean := False;
   Pressure      : Natural := 500;   -- kPa
   The_Controller : Byte := Forwards;
   The_Cab        : Cab_T := Cab_A;
   The_Sleeping   : Boolean := False;
   The_Passive_Shunting : Boolean := False;
   The_Non_Leading       : Boolean := False;
   The_Train_Config      : Byte := 0;

   TC_Buffer : TIU_TC_Array := (others => 0);
   TC_Filled : Natural := 0;

   --  What the on-board was last told (Natural'Last: nothing yet)
   Sent_Pressure   : Natural := Natural'Last;
   Sent_Controller : Natural := Natural'Last;
   Sent_Cab        : Cab_T := No_Cab;
   Cab_Sent        : Boolean := False;
   Sent_Sleeping, Sent_Passive_Shunting, Sent_Non_Leading : Boolean := False;
   Sleeping_Sent, Passive_Shunting_Sent, Non_Leading_Sent : Boolean := False;
   Sent_Train_Config : Natural := Natural'Last;

   procedure Reset is
   begin
      Last_Commands := 0;
      Last_Reasons := 0;
      Failed_Safe := False;
      Pressure := 500;
      The_Controller := Forwards;
      The_Cab := Cab_A;
      The_Sleeping := False;
      The_Passive_Shunting := False;
      The_Non_Leading := False;
      The_Train_Config := 0;
      TC_Buffer := (others => 0);
      TC_Filled := 0;
      Sent_Pressure := Natural'Last;
      Sent_Controller := Natural'Last;
      Sent_Cab := No_Cab;
      Cab_Sent := False;
      Sent_Sleeping := False;
      Sleeping_Sent := False;
      Sent_Passive_Shunting := False;
      Passive_Shunting_Sent := False;
      Sent_Non_Leading := False;
      Non_Leading_Sent := False;
      Sent_Train_Config := Natural'Last;
   end Reset;

   procedure Command (Commands : Byte; Reasons : Reasons_T) is
   begin
      Last_Commands := Commands;
      Last_Reasons := Reasons;
   end Command;

   procedure Command_TC (Payload : TIU_TC_Array; Length : Natural) is
   begin
      TC_Buffer := Payload;
      TC_Filled := Natural'Min (Length, TIU_TC_Max_Length);
   end Command_TC;

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

   procedure Set_Cab (Cab : Cab_T) is
   begin
      The_Cab := Cab;
   end Set_Cab;

   procedure Set_Controller (Position : Byte) is
   begin
      if Position <= Backwards then
         The_Controller := Position;
      end if;
   end Set_Controller;

   procedure Set_Sleeping (On : Boolean) is
   begin
      The_Sleeping := On;
   end Set_Sleeping;

   procedure Set_Passive_Shunting (On : Boolean) is
   begin
      The_Passive_Shunting := On;
   end Set_Passive_Shunting;

   procedure Set_Non_Leading (On : Boolean) is
   begin
      The_Non_Leading := On;
   end Set_Non_Leading;

   procedure Set_Train_Configuration (Value : Byte) is
   begin
      The_Train_Config := Value;
   end Set_Train_Configuration;

   procedure Take_Inputs (List : out Input_List; Count : out Natural) is
      Units : constant Natural := Pressure / 4;

      procedure Push (Signal : Byte; Value : Byte) is
      begin
         if Count < Max_Inputs then
            Count := Count + 1;
            List (Count) := (Signal, Value);
         end if;
      end Push;
   begin
      List := (others => (0, 0));
      Count := 0;
      if Sent_Cab /= The_Cab or else not Cab_Sent then
         --  one input per cab (SUBSET-034 2.5.1): the inactive cab is
         --  told too, so that "no cab active" is unambiguous
         if The_Cab /= Sent_Cab then
            if Sent_Cab = Cab_A then Push (1, 0); end if;
            if Sent_Cab = Cab_B then Push (2, 0); end if;
            if The_Cab = Cab_A then Push (1, 1); end if;
            if The_Cab = Cab_B then Push (2, 1); end if;
         elsif not Cab_Sent then
            Push (1, (if The_Cab = Cab_A then 1 else 0));
            Push (2, (if The_Cab = Cab_B then 1 else 0));
         end if;
         Sent_Cab := The_Cab;
         Cab_Sent := True;
      end if;
      if Sent_Controller /= Natural (The_Controller) then
         Push (6, The_Controller);
         Sent_Controller := Natural (The_Controller);
      end if;
      if Sent_Pressure /= Units then
         Push (12, Byte (Natural'Min (255, Units)));
         Sent_Pressure := Units;
      end if;
      if not Sleeping_Sent or else Sent_Sleeping /= The_Sleeping then
         Push (3, (if The_Sleeping then 1 else 0));
         Sent_Sleeping := The_Sleeping;
         Sleeping_Sent := True;
      end if;
      if not Passive_Shunting_Sent
        or else Sent_Passive_Shunting /= The_Passive_Shunting
      then
         Push (4, (if The_Passive_Shunting then 1 else 0));
         Sent_Passive_Shunting := The_Passive_Shunting;
         Passive_Shunting_Sent := True;
      end if;
      if not Non_Leading_Sent or else Sent_Non_Leading /= The_Non_Leading
      then
         Push (5, (if The_Non_Leading then 1 else 0));
         Sent_Non_Leading := The_Non_Leading;
         Non_Leading_Sent := True;
      end if;
      if Sent_Train_Config /= Natural (The_Train_Config) then
         Push (13, The_Train_Config);
         Sent_Train_Config := Natural (The_Train_Config);
      end if;
   end Take_Inputs;

   function Commands return Byte is (Last_Commands);
   function Reasons return Reasons_T is (Last_Reasons);
   function Brake_Pressure_Kpa return Natural is (Pressure);
   function Controller return Byte is (The_Controller);
   function Fail_Safe return Boolean is (Failed_Safe);
   function Cab return Cab_T is (The_Cab);
   function Sleeping return Boolean is (The_Sleeping);
   function Passive_Shunting return Boolean is (The_Passive_Shunting);
   function Non_Leading return Boolean is (The_Non_Leading);
   function Train_Configuration return Byte is (The_Train_Config);
   function TC_Length return Natural is (TC_Filled);
   function TC_Payload return TIU_TC_Array is (TC_Buffer);

end Sim_Vehicle;
