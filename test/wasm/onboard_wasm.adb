--  ETCS on-board (EVC)
--  WebAssembly host interface of the on-board: implementation.

with Ada.Streams;  use Ada.Streams;
with DMI_Protocol; use DMI_Protocol;
with EVC_Bytes;
with EVC_Config;
with EVC_Core;
with EVC_Track;
with Sim_JRU;
with Sim_Odometer;
with Sim_Onboard_Env;
with Sim_RBC;
with Sim_Trackside;
with Sim_Vehicle;

package body Onboard_Wasm is

   package Env renames Sim_Onboard_Env;

   Rx : Stream_Element_Array (1 .. 4096);
   Tx : Stream_Element_Array (1 .. 16_384 + 512);

   Layout_Countdown : Natural := 0;

   Text : String (1 .. Sim_JRU.Max_Text);

   --  The second TIU output (5.20), refreshed at every Transmit
   TC_Buf : EVC_Bytes.Byte_Array (1 .. Sim_Vehicle.TIU_TC_Max_Length) :=
     (others => 0);
   TC_Len : Natural := 0;

   procedure Reset is
   begin
      Env.Reset;
      Layout_Countdown := 0;
      TC_Buf := (others => 0);
      TC_Len := 0;
   end Reset;

   procedure Set_Track_Preset (Preset : Integer_32) is
   begin
      Env.Set_Track_Preset
        (if Preset = 1 then EVC_Track.Features else EVC_Track.Default);
   end Set_Track_Preset;

   procedure Set_Radio (On : Integer_32) is
   begin
      Env.Set_Radio (On = 1);
   end Set_Radio;

   procedure RBC_Emergency_Stop is
   begin
      Env.RBC_Emergency_Stop;
   end RBC_Emergency_Stop;

   function SoM_L2_Sent return Integer_32 is
     (Integer_32 (Env.SoM_L2_Sent));
   function Session return Integer_32 is
     (Integer_32 (Natural'Min (Env.Onboard_Session, 255)));
   function RBC_State return Integer_32 is
     (Sim_RBC.State_T'Pos (Sim_RBC.State (1)));

   procedure Set_Cab (Cab : Integer_32) is
   begin
      Env.Set_Cab
        ((case Cab is
             when 1 => Sim_Vehicle.Cab_A,
             when 2 => Sim_Vehicle.Cab_B,
             when others => Sim_Vehicle.No_Cab));
   end Set_Cab;

   procedure Set_Controller (Position : Integer_32) is
   begin
      if Position in 0 .. 2 then
         Env.Set_Controller (Sim_Vehicle.Byte (Position));
      end if;
   end Set_Controller;

   procedure Set_Sleeping (On : Integer_32) is
   begin
      Env.Set_Sleeping (On /= 0);
   end Set_Sleeping;

   procedure Set_Passive_Shunting (On : Integer_32) is
   begin
      Env.Set_Passive_Shunting (On /= 0);
   end Set_Passive_Shunting;

   procedure Set_Non_Leading (On : Integer_32) is
   begin
      Env.Set_Non_Leading (On /= 0);
   end Set_Non_Leading;

   procedure Set_Train_Configuration (Value : Integer_32) is
   begin
      if Value in 0 .. 255 then
         Env.Set_Train_Configuration (Sim_Vehicle.Byte (Value));
      end if;
   end Set_Train_Configuration;

   function Configure (Length : Unsigned_32) return Integer_32 is
      N     : constant Natural :=
        Natural (Unsigned_32'Min (Length, Rx'Length));
      Image : EVC_Bytes.Byte_Array (1 .. N);
   begin
      for I in Image'Range loop
         Image (I) := EVC_Bytes.Byte (Rx (Stream_Element_Offset (I)));
      end loop;
      EVC_Core.Configure (Image);
      return (if EVC_Config."=" (EVC_Config.Last_Status,
                                 EVC_Config.Accepted)
              then 1 else 0);
   end Configure;

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
      TC_Len := Env.TC_Length;
      TC_Buf := Env.TC_Payload;
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

   function Group_Count return Integer_32 is (Integer_32 (Env.Group_Count));
   function Group_At (Index : Integer_32) return Integer_32 is
     (if Index in 1 .. Integer_32 (Env.Group_Count)
      then Integer_32 (Env.Group_At (Integer (Index)))
      else 0);

   function TC_Buffer return System.Address is (TC_Buf'Address);
   function TC_Length return Integer_32 is (Integer_32 (TC_Len));

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
