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
--  (M_TRACKCOND 6, 7, 8, 10) and the powerless sections (3, 9, the kind
--  Powerless_Section: the supervision takes them as areas without the
--  regenerative brake when it needs the catenary, 3.12.1.3.3), from the
--  max safe front end at their start to the rear end leaving them.
--
--  The information for an external function of 3.12.1.5 b) and 5.20
--  (added by the procedures of phase E4, External below): for the
--  powerless sections (5.20.2, 5.20.3), the air tightness areas (5.20.4),
--  the special brake inhibitions (5.20.5) and the changes of traction
--  system (5.20.6), from the max safe front end at the point C of the
--  indication (5.18) to the min safe rear end leaving the area, the
--  remaining distances of SUBSET-034 2.3.4, 2.4.1, 2.4.2, 2.4.4 and
--  2.4.7 (positive in rear of the location, 5.20.1.2); and for the
--  station platforms (5.20.8, packet 69) and the changes of allowed
--  current consumption (5.20.7, packet 40), which phase E4 stores here
--  (3.7.3.1 o, p; 3.7.3.2 e), not indicated to the driver (3.12.1.5
--  a), their point C as the others' (5.20.7.3, 5.20.8.3).

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Track_Packets.P39;
with ETCS_Track_Packets.P40;
with ETCS_Track_Packets.P67;
with ETCS_Track_Packets.P68;
with ETCS_Track_Packets.P69;
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

   --  Added by the procedures of phase E4: the station platforms
   --  (packet 69; Value: M_PLATFORM * 4 + Q_PLATFORM) and the changes of
   --  allowed current consumption (packet 40; Value: M_CURRENT, at Start)
   function Platforms return Store_T
     with Global => State;
   function Current_Changes return Store_T
     with Global => State;

   procedure Clear
     with Global => (Output => State),
          Post => Conditions.Count = 0 and then Traction_Changes.Count = 0
                  and then Big_Metal_Masses.Count = 0
                  and then Platforms.Count = 0
                  and then Current_Changes.Count = 0;

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

   --  Added by the procedures of phase E4: packet 69 (3.7.3.1 o, from
   --  the start of its first element; 3.7.3.2 e, Q_TRACKINIT 1, the
   --  initial state from D_TRACKINIT) and packet 40 (3.7.3.1 p, all the
   --  stored ones)
   procedure Take_Platforms (P : ETCS_Track_Packets.P69.Packet_T;
                             M : Message_T;
                             T : Origin_Table_T)
     with Global => (In_Out => State);

   procedure Take_Current (P : ETCS_Track_Packets.P40.Packet_T;
                           M : Message_T)
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

   ---------------------------------------------------------------------
   --  Added by the procedures of phase E4: the information for an
   --  external function (3.12.1.5 b, 5.20, SUBSET-034)
   ---------------------------------------------------------------------

   --  The kinds of information, SUBSET-034: 1 powerless section with
   --  pantograph to be lowered (2.4.2), 2 powerless section with main
   --  power switch to be switched off (2.4.7), 3 air tightness area
   --  (2.4.4), 4 regenerative, 5 eddy current for service braking, 6
   --  eddy current for emergency braking, 7 magnetic shoe brake
   --  inhibition area (2.3.4), 8 change of traction system (2.4.1), 9
   --  change of allowed current consumption (2.4.10), 10 station
   --  platform (2.4.6)
   Ext_Pantograph   : constant := 1;
   Ext_Main_Switch  : constant := 2;
   Ext_Air_Tight    : constant := 3;
   Ext_Regenerative : constant := 4;
   Ext_Eddy_Service : constant := 5;
   Ext_Eddy_Emergency : constant := 6;
   Ext_Magnetic_Shoe  : constant := 7;
   Ext_Traction     : constant := 8;
   Ext_Current      : constant := 9;
   Ext_Platform     : constant := 10;

   --  One item: its kind, the number of the condition (as on the DMI;
   --  a change of traction system 128 + its place, a change of allowed
   --  current consumption 160, a station platform 192 + its place), the
   --  remaining distance (cm, 5.20.1.2: positive in rear) from the train
   --  end concerned to the start (or the location of the change) and to
   --  the end, each when it is generated; Value, for a change of
   --  traction system M_VOLTAGE * 1024 + NID_CTRACTION, for a change of
   --  allowed current consumption M_CURRENT, for a station platform
   --  M_PLATFORM * 4 + Q_PLATFORM (the nominal height, the side
   --  relative to the sense of the track description, which is the
   --  train orientation's when the information was received)
   Max_External : constant := 8;
   type External_Item_T is record
      Kind      : Natural range 0 .. 10 := 0;
      Id        : Natural range 0 .. 255 := 0;
      Has_Start : Boolean := False;
      To_Start  : Dist_T := 0;
      Has_End   : Boolean := False;
      To_End    : Dist_T := 0;
      Value     : Natural range 0 .. 65_535 := 0;
   end record;
   type External_Array is array (1 .. Max_External) of External_Item_T;
   type External_T is record
      Count : Natural range 0 .. Max_External := 0;
      List  : External_Array;
   end record;

   --  5.20.2 to 5.20.6: the items generated now, the nearest first
   procedure External (T     : Origin_Table_T;
                       Train : Train_Frame_T;
                       Info  : out External_T)
     with Global => State;

   --  3.13.2.3.4: the areas of lost braking along Ahead, frame
   --  positions, the end moved by the train Length
   procedure Inhibitions (T      : Origin_Table_T;
                          Ahead  : Sense_T;
                          Length : Length_T;
                          Areas  : out Inhibition_Areas_T)
     with Global => State;

end EVC_Track_Conditions;
