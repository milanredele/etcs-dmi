--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half (EVC_Radio_Authority): the
--  radio messages of the cycle whose information goes to the stores of
--  phase E3 (EVC_Stored_Information), as the balise groups the position
--  took into account go there (EVC_Position.Taken).
--
--  EVC_Radio_Authority.Take_Message (step 1 of the cycle) puts here a
--  message the session half passed (4.8 is its verdict) that carries
--  stored information: the movement authority (messages 3 and 33, packet
--  15 with its optional packets), with the origin of its location
--  reference (the LRBG it names, 3.6.2.2.2 c; shifted by D_REF for
--  message 33, 3.6.4.2.3), the directions that select the packets valid
--  for the train (3.6.3.1.3) and the time its timers start from
--  (3.8.4.2.1 a, 3.8.4.3.1 a: the time stamp of the message). The stored
--  information takes them in its Evaluate (step 3), after the groups;
--  EVC_Radio_Authority.Evaluate (step 5) empties the table.
--
--  A leaf: EVC_Stored_Information reads it without depending on
--  EVC_Radio_Authority, which reads the stored information.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Bits;
with ETCS_Message;
with ETCS_Message_Catalogue;
with ETCS_Packet_Index;
with EVC_Distances;     use EVC_Distances;
with EVC_Origins;
with EVC_Received;
with Interfaces;        use Interfaces;

package EVC_Radio_Info
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  An engineering constant: the messages with stored information
   --  taken in one cycle (each about 1.6 KB of static storage); one
   --  more in the same cycle is refused and counted (Refused)
   Max_Messages : constant := 2;
   subtype Count_T is Natural range 0 .. Max_Messages;
   subtype Index_T is Count_T range 1 .. Max_Messages;

   --  What the stored information does with a message besides its
   --  packets (3.10.2.2: the conditional emergency stop, message 15; 3.8.6:
   --  the proposed shortened MA, message 9)
   type Action_T is (Packets, Conditional_Stop, Shortening);

   --  How a message is to be taken
   type Slot_T is record
      Action     : Action_T := Packets;
      Origin     : EVC_Origins.Count_T := 0;
      G, T       : Direction_T := Unknown;
      S          : Sense_T := Plus;
      Start_Ms   : Unsigned_64 := 0;
      --  3.10.2.4: an MA is rejected after an accepted emergency stop
      --  not revoked yet
      MA_Allowed : Boolean := True;
      --  Conditional_Stop: the stop location, from the location
      --  reference along S (3.10.2.2)
      Stop_D     : Dist_T := 0;
   end record;

   function Count return Count_T
     with Global => State;
   function Slot (I : Index_T) return Slot_T
     with Global => State,
          Pre => I <= Count;
   function Kind (I : Index_T) return ETCS_Message_Catalogue.Message_Kind_T
     with Global => State,
          Pre => I <= Count;
   --  The packets of message I and their index entries
   function Packet_Count (I : Index_T) return ETCS_Message.Packet_Count_T
     with Global => State,
          Pre => I <= Count;
   function Packet_Entry (I : Index_T; P : Positive)
     return ETCS_Packet_Index.Entry_T
     with Global => State,
          Pre => I <= Count and then P <= Packet_Count (I);
   --  A reader on packet P of message I
   procedure Open_Packet (I : Index_T;
                          P : Positive;
                          R : in out ETCS_Bits.Reader)
     with Global => State,
          Pre => I <= Count and then P <= Packet_Count (I);

   --  3.13.11.8, 3.8.2.2.1 a): T_MAR of the MA request parameters
   --  (packet 57) in ms, 0 when none is stored or it asks no request
   --  (the snapshot's Extra.T_MAR, built by the stored information)
   Max_T_MAR_Ms : constant := 255_000;

   function T_MAR_Ms return Unsigned_64
     with Global => State,
          Post => T_MAR_Ms'Result <= Max_T_MAR_Ms;

   procedure Set_T_MAR (Ms : Unsigned_64)
     with Global => (In_Out => State),
          Pre  => Ms <= Max_T_MAR_Ms,
          Post => T_MAR_Ms = Ms;

   --  Messages refused for want of room since Clear (saturating)
   function Refused return Natural
     with Global => State;

   --  Power-up: nothing
   procedure Clear
     with Global => (Output => State),
          Post => Count = 0 and then Refused = 0 and then T_MAR_Ms = 0;

   --  The cycle's messages taken: the table empty
   procedure Empty
     with Global => (In_Out => State),
          Post => Count = 0;

   --  The last message EVC_Received accepted, copied in place, with how
   --  to take it; refused (counted) when the table is full
   procedure Put_Last (S : Slot_T)
     with Global => (In_Out => State, Input => EVC_Received.Store),
          Post => Count >= Count'Old;

end EVC_Radio_Info;
