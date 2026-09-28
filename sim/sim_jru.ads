--  ETCS DMI test simulator
--  The juridical recorder of the bench: the records the ETCS on-board
--  puts on its JRU port (EVC_Ports: event u8, three bytes, cycle u32,
--  time u64) kept in a ring for the page and the tests, and a short
--  text of each (the events EVC_Ports and EVC_Stored_Information
--  document). SUBSET-027 is outside the project: this is a sink, not a
--  recorder.

with EVC_Bytes;
with Interfaces; use Interfaces;

package Sim_JRU is

   Capacity : constant := 64;

   type Record_T is record
      Event      : EVC_Bytes.Byte := 0;
      B2, B3, B4 : EVC_Bytes.Byte := 0;
      Cycle      : Unsigned_32 := 0;
      Time_Ms    : Unsigned_64 := 0;
   end record;

   procedure Reset;

   --  One JRU output of the on-board; a payload of another length than
   --  EVC_Ports.JRU_Record_Length is counted and dropped
   procedure Put (Payload : EVC_Bytes.Byte_Array);

   --  Records received since Reset (saturating), and of them the ones
   --  still in the ring
   function Count return Natural;
   function Available return Natural;
   function Malformed return Natural;

   --  Records of an event number since Reset (saturating)
   function Count_Of (Event : EVC_Bytes.Byte) return Natural;

   --  Age 0 is the newest record; Age < Available
   function Get (Age : Natural) return Record_T;

   --  "12.3 s  mode SB, level unknown": the time and what happened
   Max_Text : constant := 96;
   procedure Describe (R    : Record_T;
                       Text : out String;
                       Last : out Natural)
     with Pre => Text'Length >= Max_Text;

end Sim_JRU;
