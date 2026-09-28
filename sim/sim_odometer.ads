--  ETCS DMI test simulator
--  The odometer of the ETCS on-board on the bench: from the true
--  movement of the balise antenna it makes the samples of the odometer
--  port (EVC_Ports, 22 bytes) and the detection stamps of the balises.
--
--  Error model, in integers (ppm of the distance, cm, cm/s). Each period
--  the measured distance is the true one times (1 + scale + noise):
--  scale is a constant error (a wrong wheel diameter, a slip or slide
--  that lasts; default +1000 ppm, over-reading), noise is drawn per
--  period, uniformly in -Noise .. +Noise ppm (default 500) from a fixed
--  seed. The error is accumulated exactly (in ppm cm) and the reading is
--  its floor in cm, so no rounding drifts. The odometer states its
--  accuracy honestly: over- and under-reading each grow by
--  ceil (Bound * |measured step|) + 1 cm per moving period (default
--  Bound 2000 ppm, the "2 per mille" of the configuration), which is
--  never less than the true error of any interval: Configure keeps
--  Bound >= R + R / 16 + 1 for R = |scale| + noise (at most 5 %). The
--  speed has the same error, its interval the same bound plus 1 cm/s.
--  The cold movement detection is not fitted (cold 0).
--
--  Everything here is integer: the true movement is quantised to cm
--  and cm/s by the caller (Sim_Onboard_Env) before it reaches this unit,
--  so the bytes on the ports are the same on every target.

with EVC_Bytes;
with EVC_Ports;
with Interfaces; use Interfaces;

package Sim_Odometer is

   subtype Sample_T is EVC_Bytes.Byte_Array (1 .. EVC_Ports.Odometer_Length);

   --  Scale and Noise are the true error, Bound the stated accuracy
   --  (all ppm); Seed starts the noise. Takes effect at Reset.
   procedure Configure (Scale_Ppm : Integer := 1_000;
                        Noise_Ppm : Natural := 500;
                        Bound_Ppm : Natural := 2_000;
                        Seed      : Unsigned_32 := 20_260_928);

   --  Power-up: the antenna truly at True_Cm, the reading d_est 0, the
   --  counters 0, standstill
   procedure Reset (True_Cm : Integer_64);

   --  One period: the antenna is now truly at True_Cm and moves at
   --  Speed_Cms (>= 0) in the sense of its position
   procedure Advance (True_Cm : Integer_64; Speed_Cms : Natural);

   --  The reading (d_est, wrapping) the odometer had when the antenna
   --  was truly at At_Cm, a place passed during the last period: the
   --  stamp of a balise detected there
   function Stamp (At_Cm : Integer_64) return Unsigned_32;

   --  Whether At_Cm was passed during the last period (the previous
   --  place excluded, the new one included)
   function Passed (At_Cm : Integer_64) return Boolean;

   --  The sample of the last period
   function Sample return Sample_T;

   --  For the tests and the page: the reading, the counters, the true
   --  distance run since Reset (cm)
   function D_Est return Integer_64;
   function Over return Integer_64;
   function Under return Integer_64;
   function True_Travelled return Integer_64;
   function Bound_Ppm return Natural;

end Sim_Odometer;
