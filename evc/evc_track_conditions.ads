--  ETCS on-board (EVC)
--  Track conditions (SUBSET-026 3.12.1; packets 68, 39 and 67) and their
--  indication to the driver (5.18).
--
--  Storage. The track conditions of packet 68 are areas [start, end)
--  with their type M_TRACKCOND; the change of traction system of packet
--  39 a location with the voltage and the country of the traction
--  system; the big metal masses of packet 67 areas. Replacement
--  (3.7.3.1): packet 68 replaces the stored conditions of its types
--  from the start of its first element (g), or resumes the initial
--  states from D_TRACKINIT (Q_TRACKINIT 1, 3.7.3.2 c); packet 39 replaces
--  every stored change of traction system (e); packet 67 the big metal
--  masses from its first element (f). With no track condition stored
--  the initial states hold (3.12.1.6): nothing is indicated, no brake is
--  inhibited.
--
--  Evaluation (3.12.1.2.1): the start of an area against the max safe
--  front end, its end against the min safe rear end, except the end of
--  a powerless section against the min safe front end (3.12.1.2.1.3),
--  sound horn and radio hole against the estimated front end
--  (3.12.1.2.1.4; for the radio hole the estimated position of the
--  engine, 3.12.1.2.1.5, is taken as the estimated front end).
--
--  Indication (3.12.1.5 a, 5.18): the symbols of DMI 8.2.3.5 for the
--  area B3 to B5 (MSG_TRACK_COND) and the forthcoming orders of DMI
--  8.3.4 for the planning (MSG_PLANNING). The announcement starts at a
--  point C in rear of the start that the on-board chooses from "the
--  time necessary for performing the required actions and the current
--  train speed" (5.18.2.2.1): Announce_Time_Ms at the current speed, at
--  least Announce_Min_Cm; for the horn the 4 s of A.3.1. The symbols
--  after the end ("raise pantograph", "end of neutral section", "open
--  air conditioning intake", "new traction system") stay 5 s after the
--  min safe rear end passed it (A.3.1). Whether an order is executed
--  automatically or by the driver is application dependent (5.18.2.2.2):
--  Automatic below chooses; this on-board asks the driver. Not
--  indicated: station platforms, allowed current consumption and big
--  metal masses (3.12.1.5 a); the tunnel stopping area, shown on the
--  driver's request with the SBD of 5.18.8.3 (phase E4). The non
--  stopping area is announced and shown from point C to the min safe
--  rear end leaving it; the virtual SBI limits of 5.18.4.2 need the
--  supervision (phase E4).
--
--  Braking (3.13.2.3.4): the areas where a special brake is inhibited
--  (M_TRACKCOND 6, 7, 8, 10) and the powerless sections (3, 9), taken as
--  areas without the regenerative brake (3.12.1.3.3: a regenerative
--  brake that needs the catenary), from the max safe front end at their
--  start to the rear end leaving them.
--
--  The information for an external function of 3.12.1.5 b) and 5.20 is
--  phase E4.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Track_Packets.P39;
with ETCS_Track_Packets.P67;
with ETCS_Track_Packets.P68;
with EVC_Distances;         use EVC_Distances;
with EVC_Profiles;          use EVC_Profiles;
with EVC_Supervision_Input; use EVC_Supervision_Input;
with Interfaces;            use Interfaces;

package EVC_Track_Conditions
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  5.18.2.2.2: orders executed automatically (True) or by the driver
   Automatic : constant Boolean := False;

   Announce_Time_Ms : constant := 10_000;
   Announce_Min_Cm  : constant := 10_000;
   Horn_Time_Ms     : constant := 4_000;   -- A.3.1
   After_End_Ms     : constant := 5_000;   -- A.3.1

   --  Value: M_TRACKCOND; Id: the number of the condition on the DMI
   function Conditions return Store_T
     with Global => State;
   --  Value: M_VOLTAGE * 1024 + NID_CTRACTION, at Start
   function Traction_Changes return Store_T
     with Global => State;
   function Big_Metal_Masses return Store_T
     with Global => State;

   procedure Clear
     with Global => (Output => State),
          Post => Conditions.Count = 0 and then Traction_Changes.Count = 0
                  and then Big_Metal_Masses.Count = 0;

   procedure Take_Conditions (P : ETCS_Track_Packets.P68.Packet_T;
                              M : Message_T;
                              T : Origin_Table_T)
     with Global => (In_Out => State);

   procedure Take_Traction (P : ETCS_Track_Packets.P39.Packet_T;
                            M : Message_T)
     with Global => (In_Out => State);

   procedure Take_Big_Metal_Masses (P : ETCS_Track_Packets.P67.Packet_T;
                                    M : Message_T;
                                    T : Origin_Table_T)
     with Global => (In_Out => State);

   --  A.3.4.1.3 [1], [10]: the track conditions are reset beyond X
   procedure Delete_Beyond (T          : Origin_Table_T;
                            X          : Dist_T;
                            To         : Location_T;
                            Before_Msg : Natural)
     with Global => (In_Out => State);

   procedure Delete_Behind (T : Origin_Table_T; Rear : Dist_T;
                            Keep : Length_T)
     with Global => (In_Out => State);

   procedure Mark (Marks : in out Origin_Marks_T)
     with Global => State;

   ---------------------------------------------------------------------
   --  Indication and braking
   ---------------------------------------------------------------------

   --  One symbol in B3 to B5: the number of the condition, the symbol
   --  (TC01 .. TC37 as 1 .. 37, the LX as 38: MSG_TRACK_COND)
   Max_Indications : constant := 16;
   type Indication_T is record
      Id   : Natural range 0 .. 255 := 0;
      Kind : Natural range 0 .. 38 := 0;
   end record;
   type Indication_Array is array (1 .. Max_Indications) of Indication_T;
   type Indications_T is record
      Count : Natural range 0 .. Max_Indications := 0;
      List  : Indication_Array;
   end record;

   --  One forthcoming order in the planning: the symbol (PL01 .. PL36 as
   --  1 .. 36) at a frame position ("estimated" item)
   Max_Orders : constant := 32;
   type Order_T is record
      Symbol : Natural range 0 .. 40 := 0;
      At_X   : Dist_T := 0;
   end record;
   type Order_Array is array (1 .. Max_Orders) of Order_T;
   type Orders_T is record
      Count : Natural range 0 .. Max_Orders := 0;
      List  : Order_Array;
   end record;

   --  The indications and orders of now; notes when the min safe rear
   --  end passes the end of a condition (for the 5 s of A.3.1)
   procedure Evaluate (T      : Origin_Table_T;
                       Train  : Train_Frame_T;
                       Now_Ms : Unsigned_64;
                       Ind    : out Indications_T;
                       Orders : out Orders_T)
     with Global => (In_Out => State);

   --  3.13.2.3.4: the areas of lost braking along Ahead, frame
   --  positions, the end moved by the train Length
   procedure Inhibitions (T      : Origin_Table_T;
                          Ahead  : Sense_T;
                          Length : Length_T;
                          Areas  : out Inhibition_Areas_T)
     with Global => State;

end EVC_Track_Conditions;
