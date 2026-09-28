--  ETCS DMI test simulator
--  The odometer of the ETCS on-board: implementation.

package body Sim_Odometer is

   Million : constant := 1_000_000;

   --  Configuration
   Cfg_Scale : Integer := 1_000;
   Cfg_Noise : Natural := 500;
   Cfg_Bound : Natural := 2_000;
   Cfg_Seed  : Unsigned_32 := 20_260_928;

   --  State
   Random    : Unsigned_32 := 1;
   Old_True, New_True : Integer_64 := 0;  -- antenna, cm
   Old_Meas, New_Meas : Integer_64 := 0;  -- d_est, cm
   Error_Acc : Integer_64 := 0;           -- true error, ppm cm
   Base_True : Integer_64 := 0;
   Over_Acc, Under_Acc : Integer_64 := 0;
   V_Est, V_Min, V_Max : Natural := 0;
   Moving : EVC_Bytes.Byte := 0;

   function Floor_Div (A : Integer_64; B : Positive) return Integer_64 is
     (if A >= 0 then A / Integer_64 (B)
      else -((-A + Integer_64 (B) - 1) / Integer_64 (B)));

   function Ceil_Div (A : Integer_64; B : Positive) return Integer_64 is
     (-Floor_Div (-A, B));

   procedure Configure (Scale_Ppm : Integer := 1_000;
                        Noise_Ppm : Natural := 500;
                        Bound_Ppm : Natural := 2_000;
                        Seed      : Unsigned_32 := 20_260_928)
   is
      --  at most 5 % of true error
      S : constant Integer := Integer'Max (-50_000,
                                          Integer'Min (50_000, Scale_Ppm));
      N : constant Natural := Natural'Min (50_000 - abs S, Noise_Ppm);
      R : constant Natural := abs S + N;
   begin
      Cfg_Scale := S;
      Cfg_Noise := N;
      Cfg_Bound := Natural'Max (Natural'Min (Bound_Ppm, 500_000),
                                R + R / 16 + 1);
      Cfg_Seed := Seed;
   end Configure;

   procedure Reset (True_Cm : Integer_64) is
   begin
      Random := Cfg_Seed;
      Old_True := True_Cm;
      New_True := True_Cm;
      Base_True := True_Cm;
      Old_Meas := 0;
      New_Meas := 0;
      Error_Acc := 0;
      Over_Acc := 0;
      Under_Acc := 0;
      V_Est := 0;
      V_Min := 0;
      V_Max := 0;
      Moving := 0;
   end Reset;

   --  The noise of one period, uniformly in -Cfg_Noise .. Cfg_Noise
   function Next_Noise return Integer is
   begin
      Random := Random * 1_664_525 + 1_013_904_223;
      if Cfg_Noise = 0 then
         return 0;
      end if;
      return Integer (Shift_Right (Random, 8)
                      mod Unsigned_32 (2 * Cfg_Noise + 1))
             - Cfg_Noise;
   end Next_Noise;

   procedure Advance (True_Cm : Integer_64; Speed_Cms : Natural) is
      Rate  : constant Integer := Cfg_Scale + Next_Noise;
      Delta_T : constant Integer_64 := True_Cm - New_True;
      Step  : Integer_64;
      Bound : Integer_64;
      V     : constant Integer_64 := Integer_64 (Natural'Min (Speed_Cms,
                                                              65_535));
      V_Meas, Margin : Integer_64;
   begin
      Old_True := New_True;
      Old_Meas := New_Meas;
      New_True := True_Cm;
      Error_Acc := Error_Acc + Delta_T * Integer_64 (Rate);
      New_Meas := (New_True - Base_True) + Floor_Div (Error_Acc, Million);
      Step := New_Meas - Old_Meas;

      if Delta_T = 0 and then Step = 0 and then V = 0 then
         Moving := 0;
         V_Est := 0;
         V_Min := 0;
         V_Max := 0;
      else
         Moving := (if Delta_T < 0 then 2 else 1);
         Bound := Ceil_Div (abs Step * Integer_64 (Cfg_Bound), Million) + 1;
         Over_Acc := Over_Acc + Bound;
         Under_Acc := Under_Acc + Bound;
         V_Meas := Integer_64'Max
           (0, V + Floor_Div (V * Integer_64 (Rate), Million));
         V_Meas := Integer_64'Min (V_Meas, 65_535);
         Margin := Ceil_Div (V_Meas * Integer_64 (Cfg_Bound), Million) + 1;
         V_Est := Natural (V_Meas);
         V_Min := Natural (Integer_64'Max (0, V_Meas - Margin));
         V_Max := Natural (Integer_64'Min (65_535, V_Meas + Margin));
      end if;
   end Advance;

   function Passed (At_Cm : Integer_64) return Boolean is
     (if New_True > Old_True then At_Cm > Old_True and then At_Cm <= New_True
      elsif New_True < Old_True
      then At_Cm < Old_True and then At_Cm >= New_True
      else False);

   function Stamp (At_Cm : Integer_64) return Unsigned_32 is
      Span : constant Integer_64 := New_True - Old_True;
      D    : Integer_64 := Old_Meas;
   begin
      if Span /= 0 then
         D := Old_Meas + (At_Cm - Old_True) * (New_Meas - Old_Meas) / Span;
      end if;
      return Unsigned_32'Mod (D);
   end Stamp;

   function Sample return Sample_T is
      Result : Sample_T := (others => 0);

      procedure Put (At_Byte : Positive; V : Unsigned_64; Bytes : Positive) is
      begin
         for I in 0 .. Bytes - 1 loop
            Result (At_Byte + I) := EVC_Bytes.Byte_Of (V, I);
         end loop;
      end Put;
   begin
      Put (1, Unsigned_64 (Unsigned_32'Mod (New_Meas)), 4);
      Put (5, Unsigned_64 (Unsigned_32'Mod (Over_Acc)), 4);
      Put (9, Unsigned_64 (Unsigned_32'Mod (Under_Acc)), 4);
      Put (13, Unsigned_64 (V_Est), 2);
      Put (15, Unsigned_64 (V_Min), 2);
      Put (17, Unsigned_64 (V_Max), 2);
      Result (19) := Moving;
      --  cold movement detection not fitted: cold 0, distance 0
      return Result;
   end Sample;

   function D_Est return Integer_64 is (New_Meas);
   function Over return Integer_64 is (Over_Acc);
   function Under return Integer_64 is (Under_Acc);
   function True_Travelled return Integer_64 is (New_True - Base_True);
   function Bound_Ppm return Natural is (Cfg_Bound);

end Sim_Odometer;
