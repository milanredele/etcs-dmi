--  ETCS on-board (EVC)
--  The train position (SUBSET-026 3.4, 3.6, 5.12): balise groups,
--  linking, LRBG and SOLR, the confidence interval, relocation, the
--  train orientation, the geographical position and the content of the
--  position report.
--
--  Frame. The position is kept in the frame of the odometer
--  (EVC_Odometry): a balise group that becomes a reference is an anchor
--  (EVC_Location.Anchor_T), its identity plus the frame position of its
--  location reference and the confidence of the frame at its detection.
--  The estimated front end, the min and max safe front ends against the
--  LRBG, the SOLR or any other reference follow from the anchor, the
--  current frame position and the current orientation; a change of
--  reference (relocation, 3.6.4.2) re-anchors, and the confidence
--  interval restarts from the location accuracy of the new reference.
--  Against a fixed reference and orientation it only widens (Update's
--  postcondition): the odometer's deviations never decrease.
--
--  One cycle (Update, called by EVC_Core in the second step of Tick):
--    1. the train orientation from the cab status inputs (3.6.1.5: the
--       active cab is the front; with none active, the last one). It
--       changes with the cab status only (postcondition), and the front
--       position follows by itself from the anchors (5.12.2.5,
--       5.12.4.3). The desk closure and the modes of 5.12 are phase E4.
--    2. the telegrams of the cycle (Receive_Telegram, called while the
--       ports are read) are put together into passages over balise
--       groups (EVC_Balise_Groups). A passage ends when every balise of
--       the group was read, when a balise of another group comes
--       (3.16.2.2.2 b, c), or when the train has moved Group_End_Cm
--       from the last balise read (3.16.2.2.2 a; an engineering
--       constant, above the distance between the balises of a group).
--    3. the odometer sample of the cycle (EVC_Odometry.Apply). The
--       telegrams were placed with the frame before it: the confidence
--       of their detection is then the smaller one, and every interval
--       measured from them the wider one.
--    4. the end of the passage of the group read last, by distance.
--    5. the expectation window of the expected balise group: missed
--       when the min safe antenna position has passed its last possible
--       location plus 1.3 m (3.16.2.3.1.1).
--    6. the geographical position (3.6.6) and the report triggers.
--
--  End of a passage (Evaluate). The location reference and the
--  orientation of the group come from its telegrams (3.4.2). With
--  linking consistency checked (3.4.4.2.1.1; the mode condition b) is
--  phase E4, E2 checks whenever linking is stored):
--    - a group marked as unlinked is taken into account (3.4.4.4.2.2),
--      it becomes an ORBG, not the LRBG;
--    - the expected group (3.4.4.4.1, one window at a time, 3.4.4.4.5)
--      is accepted when its location reference was detected inside its
--      window (3.4.4.4.3: from the max safe antenna position passing the
--      first possible location to the min safe antenna position passing
--      the last one, both from D_LINK and Q_LOCACC, 3.4.4.4.3.1; for an
--      unknown group with repositioning the first possible location is
--      the previous linked group, 3.4.4.4.4); it becomes LRBG and SOLR,
--      and the next window is supervised (3.4.4.4.6 a). Detected in rear
--      of or beyond its window, it is rejected (3.4.4.4.3.2) and the
--      linking reaction of the expected group is requested (3.16.2.3.1
--      a, b); passed in the direction opposite to the announced one, it
--      is rejected and a train trip is requested (3.4.4.4.7);
--    - the group announced after the expected one: the linking reaction
--      of the expected group is requested (3.16.2.3.1 c) and the group
--      is checked against its own window (3.4.4.4.6.1);
--    - an unknown group expected with repositioning: a linked group is
--      accepted only when its own balises give its orientation, it has
--      packet 16 valid for the train orientation and it is crossed in
--      the announced direction (3.4.4.4.2.1);
--    - any other group marked as linked is rejected, and reported as an
--      unexpected balise group without reaction (3.4.4.4.2, 3.16.2.4.3).
--  With linking not checked every group is taken into account (3.4.4.5.1)
--  and becomes the SOLR (3.6.4.2.2 b); it is LRBG compliant unless it is
--  marked as unlinked (3.6.2.2.2 a).
--  An accepted group: its location accuracy is that of the linking
--  which announced it, else Default_Locacc_Cm (Q_NVLOCACC, A.3.2), and
--  is not changed afterwards (3.6.4.1.3, 3.6.4.1.4). The position becomes
--  valid (3.6.1.4). A single balise group gets the orientation the
--  linking announced (3.4.2.3.2.2). Its packets valid for the train
--  orientation (3.6.3.1.3; the crossing direction in SL, PS and SH,
--  3.6.3.1.3.1; only those for both directions when the orientation of
--  the group is not known, 3.6.3.1.4) are then taken: packet 5 replaces
--  the linking (the group is its reference and the SOLR, 3.6.4.2.2 a;
--  the first window supervised is the first whose end is not reached,
--  3.4.4.4.5.1), packet 79 the geographical position information.
--
--  Reactions: E2 detects and reports, it neither brakes nor changes the
--  mode. The events of a cycle are queries (Linking_Reaction_Requested,
--  Unexpected_Group, Missed_Group, the odometer and position status) and
--  records (Event) that EVC_Core writes to the JRU; phases E3 and E4 act
--  on them.
--
--  Position report (3.6.5): Position_Report fills packet 0 and, when the
--  LRBG is a single balise group without co-ordinate system, packet 1
--  with the previous LRBG (3.4.2.3.3.1 to .5); Report_Triggers are the
--  events of 3.6.5.1.4 the position knows and the parameters of packet
--  58 (3.6.5.1.5, Set_Report_Parameters). Sending is phase E5.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Balise_Groups; use EVC_Balise_Groups;
with EVC_Config;
with EVC_Distances;     use EVC_Distances;
with EVC_Linking;
with EVC_Location;      use EVC_Location;
with EVC_Modes;         use EVC_Modes;
with EVC_Odometry;
with EVC_Origins;
with EVC_Ports;         use EVC_Ports;
with ETCS_Bits;
with ETCS_Packet_Index;
with ETCS_Telegram;
with ETCS_Track_Packets.P58;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P1;
with ETCS_Variables;    use ETCS_Variables;
with Interfaces;        use Interfaces;

package EVC_Position
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  The installation of the engine, the balise antenna from each end
   --  (3.6.1.3.4: the front end is the end of the engine the train
   --  orientation points to), is data: EVC_Config.Config_T, which
   --  EVC_Core hands over with Set_Antenna (Clear takes the antenna of
   --  EVC_Config.Default).

   --  A passage over a group ends this far from its last balise: an
   --  engineering constant of the trackside, not of the vehicle (above
   --  the largest distance between two balises of a group that the
   --  dimensioning rules of the trackside allow), so it stays a constant
   Group_End_Cm : constant := 1_500;

   --  A.3.2: Q_NVLOCACC, default location accuracy of a balise group
   Default_Locacc_Cm : constant := 1_200;

   --  3.16.2.3.1.1: a location reference not detected at all
   Missed_Margin_Cm : constant := 130;

   --  Telegrams of one cycle (the BTM latch of EVC_Core)
   Max_Pending : constant := 8;

   type Status_T is (Unknown, Valid, Invalid);

   --  The cab status inputs of the cycle: one cab active, or not
   type Cab_T is (No_Cab, Cab_A, Cab_B);

   ---------------------------------------------------------------------
   --  Events of a cycle
   ---------------------------------------------------------------------

   --  JRU event code: Event_Kind_T'Pos + 4 (EVC_Ports)
   type Event_Kind_T is
     (Linking_Reaction,   -- Q_LINKREACTION, cause, link index
      Unexpected_Group,   -- identity
      Missed_Group,       -- identity
      Odometer_Accuracy,  -- 0 nominal, 1 impaired, 2 safety threshold
      Position_Status,    -- Status_T'Pos
      Cold_Movement,      -- 1: a cold movement was detected
      New_LRBG);          -- identity

   --  The cause of a linking reaction (byte 3 of the record)
   Cause_Early           : constant := 1;  -- 3.16.2.3.1 a)
   Cause_Not_Detected    : constant := 2;  -- 3.16.2.3.1 b)
   Cause_Other_Group     : constant := 3;  -- 3.16.2.3.1 c)
   Cause_Wrong_Direction : constant := 4;  -- 3.4.4.4.7

   type Event_T is record
      Kind       : Event_Kind_T := Linking_Reaction;
      B2, B3, B4 : Unsigned_8 := 0;
   end record;

   Max_Events : constant := 16;

   --  The reasons of 3.6.5.1.4 and 3.6.5.1.5 to send a position report
   --  that arose in the cycle
   type Triggers_T is record
      Standstill_Reached : Boolean := False;  -- 3.6.5.1.4 a)
      Mode_Changed       : Boolean := False;  -- b)
      Level_Changed      : Boolean := False;  -- g)
      Standstill_Left    : Boolean := False;  -- i)
      LRBG_Passed        : Boolean := False;  -- j), 3.6.5.1.5 d)
      Periodic_Time      : Boolean := False;  -- 3.6.5.1.5 a)
      Periodic_Distance  : Boolean := False;  -- b)
      Location_Passed    : Boolean := False;  -- c)
      Immediate          : Boolean := False;  -- e)
   end record;

   No_Triggers : constant Triggers_T := (others => False);

   type Report_Kind_T is (Report_P0, Report_P1);

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   function Status return Status_T
     with Global => State;

   --  3.6.1.5: Plus when cab A is (or was last) active, Minus for cab B
   function Orientation return Sense_T
     with Global => State;
   --  a cab was active since power-up
   function Orientation_Known return Boolean
     with Global => State;
   --  the cab status inputs of the last cycle
   function Active_Cab return Cab_T
     with Global => State;

   function LRBG return Anchor_T
     with Global => State;
   function Previous_LRBG return Anchor_T
     with Global => State;
   function SOLR return Anchor_T
     with Global => State;

   --  3.6.1.3: the last two groups marked as unlinked passed, ORBGs
   --  for the information they give (phase E3)
   function Unlinked_ORBG (I : Positive) return Anchor_T
     with Global => State,
          Pre => I <= 2;

   --  The stored linking information
   function Linking return EVC_Linking.Linking_T
     with Global => State;

   function Pending_Count return Natural
     with Global => State,
          Post => Pending_Count'Result <= Max_Pending;
   function Passage_Open return Boolean
     with Global => State;

   --  The distance from the end of the engine the orientation points to,
   --  to the antenna (the installation, Set_Antenna)
   function Front_Offset (S : Sense_T) return EVC_Config.Antenna_Offset_T
     with Global => State;

   --  The frame position of the estimated front end
   function Front_X return Dist_T
     with Global => (State, EVC_Odometry.State);

   --  Against the LRBG, along the orientation (0 without LRBG): the
   --  estimated front end (3.6.1.3), the confidence interval (3.6.4.1.5)
   function Estimated_Front return Dist_T
     with Global => (State, EVC_Odometry.State);
   function Doubt_Over return Length_T
     with Global => (State, EVC_Odometry.State);
   function Doubt_Under return Length_T
     with Global => (State, EVC_Odometry.State);
   function Min_Safe_Front return Dist_T
     with Global => (State, EVC_Odometry.State),
          Post => Min_Safe_Front'Result <= Estimated_Front;
   function Max_Safe_Front return Dist_T
     with Global => (State, EVC_Odometry.State),
          Post => Max_Safe_Front'Result >= Estimated_Front;

   --  The same against the SOLR, the reference of the supervision
   function SOLR_Estimated_Front return Dist_T
     with Global => (State, EVC_Odometry.State);
   function SOLR_Min_Safe_Front return Dist_T
     with Global => (State, EVC_Odometry.State),
          Post => SOLR_Min_Safe_Front'Result <= SOLR_Estimated_Front;
   function SOLR_Max_Safe_Front return Dist_T
     with Global => (State, EVC_Odometry.State),
          Post => SOLR_Max_Safe_Front'Result >= SOLR_Estimated_Front;

   --  3.6.1.7: the min safe rear end against the LRBG, with the train
   --  length of the valid Train Data (Set_Train_Length); the min safe
   --  front end while no length is known
   function Min_Safe_Rear return Dist_T
     with Global => (State, EVC_Odometry.State),
          Post => Min_Safe_Rear'Result <= Min_Safe_Front;
   function Train_Length_Known return Boolean
     with Global => State;

   --  The events of the last cycle
   function Event_Count return Natural
     with Global => State,
          Post => Event_Count'Result <= Max_Events;
   function Event (I : Positive) return Event_T
     with Global => State,
          Pre => I <= Event_Count;

   --  A linking reaction was requested in the last cycle, and the most
   --  restrictive one (train trip 0 before service brake 1)
   function Linking_Reaction_Requested return Boolean
     with Global => State;
   function Reaction return Q_LINKREACTION_T
     with Global => State;
   function Unexpected_Group_Found return Boolean
     with Global => State;
   function Missed_Group_Found return Boolean
     with Global => State;

   --  3.6.6: the geographical position of the estimated front end, m
   function Geo_Known return Boolean
     with Global => State;
   function Geo_Metres return Natural
     with Global => State;

   --  3.6.5
   function Report_Triggers return Triggers_T
     with Global => State;
   function Report_Kind return Report_Kind_T
     with Global => State;
   function Report_Parameters_Stored return Boolean
     with Global => State;

   --  The content of the position report (3.6.5.1.2): packet 0, and
   --  packet 1 for Report_P1. Q_INTEGRITY is "no train integrity
   --  information" (3.6.5.2, phase E5).
   function Position_Report (Mode : Mode_T; Level : Level_T)
     return ETCS_Train_Packets.P0.Packet_T
     with Global => (State, EVC_Odometry.State);
   function Position_Report_2 (Mode : Mode_T; Level : Level_T)
     return ETCS_Train_Packets.P1.Packet_T
     with Global => (State, EVC_Odometry.State);

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   --  Power-up: nothing known (the position is not kept over No Power
   --  in E2; the stored information of 4.10 is phase E4)
   procedure Clear
     with Global => (Output => (State, EVC_Odometry.State)),
          Post => Status = Unknown
                  and then not LRBG.Valid
                  and then not SOLR.Valid
                  and then not Orientation_Known
                  and then Pending_Count = 0
                  and then not Passage_Open
                  and then Event_Count = 0
                  and then not Geo_Known
                  and then Front_Offset (Plus)
                             = EVC_Config.Default.Antenna_To_Cab_A
                  and then Front_Offset (Minus)
                             = EVC_Config.Default.Antenna_To_Cab_B;

   --  The installation (EVC_Config: Antenna_To_Cab_A, Antenna_To_Cab_B):
   --  the balise antenna from the cab A end and from the cab B end of
   --  the engine, cm. The positions of the front end against every
   --  reference follow at once; nothing else changes.
   procedure Set_Antenna (To_Cab_A, To_Cab_B : EVC_Config.Antenna_Offset_T)
     with Global => (In_Out => State),
          Post => Front_Offset (Plus) = To_Cab_A
                  and then Front_Offset (Minus) = To_Cab_B
                  and then Status = Status'Old
                  and then LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Pending_Count = Pending_Count'Old
                  and then Passage_Open = Passage_Open'Old
                  and then Event_Count = Event_Count'Old
                  and then Geo_Known = Geo_Known'Old;

   --  An accepted telegram and the stamp of its balise, for the next
   --  Update; dropped when Max_Pending are waiting
   procedure Receive_Telegram (T : ETCS_Telegram.Telegram_T;
                               Stamp : Unsigned_32)
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Status = Status'Old
                  and then Passage_Open = Passage_Open'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  One cycle (see above). Sample is the odometer sample of the cycle
   --  when Sampled (the same sample may come again: it changes nothing).
   procedure Update (Cab_A_Active : Boolean;
                     Cab_B_Active : Boolean;
                     Sampled      : Boolean;
                     Sample       : Odometer_Sample_T;
                     Mode         : Mode_T;
                     Level        : Level_T;
                     Now_Ms       : Unsigned_64)
     with Global => (In_Out => (State, EVC_Odometry.State,
                                EVC_Origins.State)),
          Post =>
            --  3.6.1.5: the active cab defines the orientation, with none
            --  (or both, SUBSET-034 2.5.1.4.7) the last active one stays
            (if Cab_A_Active and then not Cab_B_Active
             then Orientation = Plus and then Orientation_Known
                  and then Active_Cab = Cab_A)
            and then
            (if Cab_B_Active and then not Cab_A_Active
             then Orientation = Minus and then Orientation_Known
                  and then Active_Cab = Cab_B)
            and then
            (if Cab_A_Active = Cab_B_Active
             then Orientation = Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Active_Cab = No_Cab)
            --  the LRBG changes only at the end of a passage
            and then
            (if Pending_Count'Old = 0 and then not Passage_Open'Old
             then LRBG = LRBG'Old)
            --  3.6.4.1.2: against the same LRBG and orientation the
            --  confidence interval does not shrink
            and then
            (if LRBG = LRBG'Old and then Orientation = Orientation'Old
             then Doubt_Over >= Doubt_Over'Old
                  and then Doubt_Under >= Doubt_Under'Old)
            and then Pending_Count = 0;

   --  The train length of the valid Train Data (phase E4), cm
   procedure Set_Train_Length (Length : Length_T)
     with Global => (In_Out => State);

   --  Packet 58 (3.6.5.1.5, 3.6.5.1.7), received by radio (phase E5)
   --  referring to the balise group Ref: one of the anchors the position
   --  keeps (LRBG, SOLR, the LRBGs of 3.6.2.2.2 c). OK False when Ref is
   --  none of them or the packet cannot be used.
   procedure Set_Report_Parameters
     (P   : ETCS_Track_Packets.P58.Packet_T;
      Ref : Identity_T;
      OK  : out Boolean)
     with Global => (In_Out => State, Input => EVC_Odometry.State);

   --  A position report was sent (phase E5): the periods restart
   procedure Report_Sent (Now_Ms : Unsigned_64)
     with Global => (In_Out => State, Input => EVC_Odometry.State);

   --  3.4.2.3.3.6: the RBC assigns a co-ordinate system to the single
   --  balise group Id, nominal or reverse against the direction
   --  reference of the position report based on two balise groups
   --  (from the previous LRBG towards Id, 3.4.2.3.3.2). Refused (OK
   --  False) when Id was reported with different previous LRBGs
   --  (3.4.2.3.3.7, 3.4.2.3.3.8) or has no direction reference.
   procedure Assign_Coordinate_System (Id      : Identity_T;
                                       Nominal : Boolean;
                                       OK      : out Boolean)
     with Global => (In_Out => State);

   --  Phase E4 (4.10, 4.11): the position becomes invalid, or is deleted
   procedure Invalidate
     with Global => (In_Out => State),
          Post => (if Status'Old = Unknown then Status = Unknown
                   else Status = Invalid);
   procedure Delete_Position
     with Global => (In_Out => State),
          Post => Status = Unknown and then not LRBG.Valid;
   --  3.6.6.9 d)
   procedure Delete_Geo
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => not Geo_Known
                  --  added by e4/modes: nothing else changes (EVC_Core,
                  --  the data of 4.10)
                  and then Status = Status'Old and then LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old
                  and then Active_Cab = Active_Cab'Old;

   --  Added by e4/modes: the linking of packet 5 is accepted (4.8, in
   --  the level and the mode of the on-board) and its consistency is
   --  checked (3.4.4.2.1.1 b, the modes of 4.5.2 Figure 1); both until
   --  EVC_Core sets them, as in phase E2. The settings apply from the
   --  next Update.
   procedure Set_Linking_Context (Accept_Info, Check : Boolean)
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => Status = Status'Old and then LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old
                  and then Active_Cab = Active_Cab'Old;
   --  4.10: entering a mode deletes the linking
   procedure Delete_Linking
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => Status = Status'Old and then LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old
                  and then Active_Cab = Active_Cab'Old;

   ---------------------------------------------------------------------
   --  For the stored information (phase E3)
   ---------------------------------------------------------------------

   --  3.6.3.1: information with this Q_DIR from a group of orientation
   --  G is valid for a train whose direction (orientation, or crossing
   --  direction in SL, PS and SH) is T: nominal when both point the
   --  same way. When one is not known only "both directions" is taken
   --  (3.6.3.1.4).
   function Valid_For (Q_DIR : Q_DIR_T; G, T : Direction_T) return Boolean
   is (case Q_DIR is
          when 2 => True,
          when 1 => G /= Unknown and then T /= Unknown and then G = T,
          when 0 => G /= Unknown and then T /= Unknown and then G /= T,
          when others => False);

   --  The balise groups taken into account in the last Update, in their
   --  order, with the telegrams of their passage: the stored information
   --  (EVC_Stored_Information, third step of the cycle) takes their
   --  packets valid for T (Valid_For with the orientation of the group),
   --  distances along S from the group's location reference, which is
   --  the origin Origin (EVC_Origins, allocated and, when the group is not
   --  the SOLR, relocated to the SOLR when the group was taken; 0 when
   --  the table was full). Start_Ms is the time of the cycle before the
   --  one that read the first balise of the passage: at or before the
   --  passage over it (3.8.4.2.1 b, 3.8.4.3.1 b).
   Max_Taken           : constant := Max_Pending + 1;
   Max_Taken_Telegrams : constant := 2 * Max_Balises;

   type Taken_T is record
      Group    : Anchor_T;
      T        : Direction_T := Unknown;
      S        : Sense_T := Plus;
      Origin   : EVC_Origins.Count_T := 0;
      First    : Positive range 1 .. Max_Taken_Telegrams + 1 := 1;
      Count    : Natural range 0 .. Max_Balises := 0;
      Start_Ms : Unsigned_64 := 0;
   end record;

   function Taken_Count return Natural
     with Global => State,
          Post => Taken_Count'Result <= Max_Taken;
   function Taken (I : Positive) return Taken_T
     with Global => State,
          Pre => I <= Taken_Count;

   --  The packets of taken telegram J (0 for no such telegram)
   function Taken_Packet_Count (J : Positive) return Natural
     with Global => State,
          Post => Taken_Packet_Count'Result <= ETCS_Telegram.Max_Packets;
   function Taken_Entry (J, P : Positive) return ETCS_Packet_Index.Entry_T
     with Global => State,
          Pre => P <= Taken_Packet_Count (J);
   --  A reader on packet P of taken telegram J
   procedure Open_Taken_Packet (J, P : Positive;
                                R    : in out ETCS_Bits.Reader)
     with Global => State,
          Pre => P <= Taken_Packet_Count (J);

end EVC_Position;
