--  ETCS on-board (EVC)
--  WebAssembly host interface of the on-board: implementation.

with Ada.Streams;  use Ada.Streams;
with DMI_Protocol; use DMI_Protocol;
with EVC_Track;
with Sim_JRU;
with Sim_Odometer;
with Sim_Onboard_Env;
with Sim_Trackside;
with Sim_Vehicle;

package body Onboard_Wasm is

   package Env renames Sim_Onboard_Env;

   Rx : Stream_Element_Array (1 .. 4096);
   Tx : Stream_Element_Array (1 .. 16_384 + 512);

   Layout_Countdown : Natural := 0;

   Text : String (1 .. Sim_JRU.Max_Text);

   procedure Reset is
   begin
      Env.Reset;
      Layout_Countdown := 0;
   end Reset;

   function Rx_Buffer return System.Address is (Rx'Address);
   function Rx_Capacity return Unsigned_32 is (Rx'Length);

   procedure Receive (Length : Unsigned_32) is
   begin
      if Length in 1 .. Rx'Length then
         Env.Receive (Rx (1 .. Stream_Element_Offset (Length)));
      end if;
   end Receive;

   procedure Set_Desk (Demand : Integer_32; Auto_Drive : Integer_32) is
   begin
      Env.Set_Desk
        (Integer (Integer_32'Max (-100, Integer_32'Min (100, Demand))),
         Auto_Drive /= 0);
   end Set_Desk;

   procedure Step (Dt_Ms : Unsigned_32) is
   begin
      Env.Step (Natural (Unsigned_32'Min (Dt_Ms, 60_000)));
   end Step;

   function Tx_Buffer return System.Address is (Tx'Address);

   function Transmit return Unsigned_32 is
      Last    : Stream_Element_Offset;
      Payload : Stream_Element_Array (1 .. 256);
      P_Last  : Stream_Element_Offset;

      procedure Add (The_Type : Msg_Type_T) is
         Offset : Stream_Element_Offset := Last + 1;
      begin
         if Last + Header_Length + P_Last <= Tx'Last then
            Put_Header (Tx, Offset, The_Type, Natural (P_Last));
            Tx (Offset .. Offset + P_Last - 1) := Payload (1 .. P_Last);
            Last := Offset + P_Last - 1;
         end if;
      end Add;
   begin
      Env.Take_DMI (Tx (1 .. 16_384), Last);
      Env.Sim_State_Payload (Payload, P_Last);
      Add (MSG_SIM_STATE);
      if Layout_Countdown = 0 then
         Sim_Trackside.Layout_Payload (Payload, P_Last);
         Add (MSG_TRACK_LAYOUT);
         Layout_Countdown := 20; -- roughly every 2 s at 10 Hz
      else
         Layout_Countdown := Layout_Countdown - 1;
      end if;
      return Unsigned_32 (Last);
   end Transmit;

   procedure Enter_Failure is
   begin
      Env.Enter_Failure;
   end Enter_Failure;

   function Failed return Integer_32 is (if Env.Failed then 1 else 0);

   procedure Set_Odometer (Scale_Ppm : Integer_32;
                           Noise_Ppm : Integer_32;
                           Bound_Ppm : Integer_32)
   is
      function Clip (V : Integer_32) return Integer is
        (Integer (Integer_32'Max (-1_000_000,
                                  Integer_32'Min (1_000_000, V))));
   begin
      Sim_Odometer.Configure
        (Scale_Ppm => Clip (Scale_Ppm),
         Noise_Ppm => Natural (Integer'Max (0, Clip (Noise_Ppm))),
         Bound_Ppm => Natural (Integer'Max (0, Clip (Bound_Ppm))));
   end Set_Odometer;

   function Ack_Requested return Integer_32 is
     (if Env.Ack_Requested then 1 else 0);

   function Mode return Integer_32 is (Integer_32 (Env.Mode_Code));
   function Level return Integer_32 is (Integer_32 (Env.Level_Code));

   function TIU_Commands return Integer_32 is
     (Integer_32 (Sim_Vehicle.Commands));
   function TIU_Reasons return Integer_32 is
     (Integer_32 (Sim_Vehicle.Reasons));
   function Brake_Pressure return Integer_32 is
     (Integer_32 (Sim_Vehicle.Brake_Pressure_Kpa));
   function Controller return Integer_32 is
     (Integer_32 (Sim_Vehicle.Controller));
   function Fail_Safe return Integer_32 is
     (if Sim_Vehicle.Fail_Safe then 1 else 0);

   function Position return Integer_32 is (Integer_32 (Env.Position_M));
   function Speed return Integer_32 is (Integer_32 (Env.Speed_KMH));

   function Group_Count return Integer_32 is
     (EVC_Track.Balise_Groups'Length);
   function Group_At (Index : Integer_32) return Integer_32 is
     (if Index in 1 .. EVC_Track.Balise_Groups'Length
      then Integer_32 (EVC_Track.Balise_Groups (Integer (Index)).At_M)
      else 0);

   function JRU_Count return Integer_32 is
     (Integer_32 (Natural'Min (Sim_JRU.Count, Natural (Integer_32'Last))));
   function JRU_Available return Integer_32 is
     (Integer_32 (Sim_JRU.Available));

   function JRU_Describe (Age : Integer_32) return Integer_32 is
      Last : Natural;
   begin
      if Age < 0 or else Integer (Age) >= Sim_JRU.Available then
         return 0;
      end if;
      Sim_JRU.Describe (Sim_JRU.Get (Natural (Age)), Text, Last);
      return Integer_32 (Last);
   end JRU_Describe;

   function Text_Buffer return System.Address is (Text'Address);

end Onboard_Wasm;
