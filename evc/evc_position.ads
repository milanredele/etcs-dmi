--  ETCS on-board (EVC)
--  The train position (SUBSET-026 3.4, 3.6, 5.12): balise groups,
--  linking, LRBG and SOLR, the confidence interval, relocation, the
--  train orientation, the geographical position and the content of the
--  position report.
--
--  Frame. The position is kept in the frame of the odometer
--  (EVC_Odometry): a balise group that becomes a reference is an anchor
--  (EVC_Location.Anchor_T), its identity, the frame position of its
--  location reference and the confidence of the frame at its detection.
--  The front ends against any reference follow from the anchor, the
--  current frame position and the orientation; a change of reference
--  (relocation, 3.6.4.2) re-anchors and the confidence interval restarts
--  from the location accuracy of the new reference; against a fixed
--  reference and orientation it only widens (Update's postcondition).
--
--  Entry points: Receive_Telegram while EVC_Core reads the ports (the
--  telegrams of the cycle put together into passages over balise groups,
--  EVC_Balise_Groups); Update in the second step of Tick, which writes
--  State in this order:
--    1. the train orientation from the cab status (3.6.1.5: the active
--       cab is the front; with none active, the last one; 5.12.2.5,
--       5.12.4.3);
--    2. the passages ended: every balise of the group read, a balise of
--       another group (3.16.2.2.2 b, c), or Group_End_Cm moved from the
--       last balise (3.16.2.2.2 a; an engineering constant, above the
--       distance between the balises of a group);
--    3. the odometer sample (EVC_Odometry.Apply); the telegrams were
--       placed with the frame before it, so the confidence of their
--       detection is the smaller one and every interval from them wider;
--    4. the end of the passage of the group read last, by distance;
--    5. the window of the expected group: missed when the min safe
--       antenna passed its last possible location plus 1.3 m
--       (3.16.2.3.1.1);
--    6. the geographical position (3.6.6) and the report triggers.
--  The setters below (linking context, train length, report parameters,
--  radio origins and packets) are called by EVC_Core between two Updates.
--
--  End of a passage (Evaluate): the location reference and orientation
--  of the group come from its telegrams (3.4.2). With linking checked
--  (3.4.4.2.1.1): a group marked unlinked becomes an ORBG (3.4.4.4.2.2);
--  the expected group (one window at a time, 3.4.4.4.5) is accepted
--  inside its window (3.4.4.4.3, 3.4.4.4.3.1; an unknown group with
--  repositioning: from the previous linked group, 3.4.4.4.4) and becomes
--  LRBG and SOLR; outside it, it is rejected with the linking reaction
--  (3.4.4.4.3.2, 3.16.2.3.1 a, b), passed in the opposite direction it is
--  rejected with a trip (3.4.4.4.7); the group announced after the
--  expected one requests the reaction (3.16.2.3.1 c) and is checked
--  against its own window (3.4.4.4.6.1); an unknown group with
--  repositioning is accepted per 3.4.4.4.2.1; any other linked group is
--  rejected as unexpected, without reaction (3.4.4.4.2, 3.16.2.4.3).
--  Linking not checked: every group is taken (3.4.4.5.1), becomes the
--  SOLR (3.6.4.2.2 b), LRBG compliant unless unlinked (3.6.2.2.2 a).
--  An accepted group keeps the accuracy of the linking that announced it,
--  else Default_Locacc_Cm (Q_NVLOCACC, A.3.2; 3.6.4.1.3, 3.6.4.1.4); the
--  position becomes valid (3.6.1.4); a single balise group gets the
--  announced orientation (3.4.2.3.2.2); its packets valid for the train
--  orientation (3.6.3.1.3, 3.6.3.1.3.1, 3.6.3.1.4) are taken: packet 5
--  replaces the linking (3.6.4.2.2 a, 3.4.4.4.5.1), packet 79 the
--  geographical position information.
--
--  Reactions: this unit detects and reports, it neither brakes nor
--  changes the mode: the events of a cycle are queries
--  (Linking_Reaction_Requested, Unexpected_Group, Missed_Group, the
--  odometer and position status) and records (Event) for the JRU.
--  Position report (3.6.5): Position_Report fills packet 0 and packet 1
--  (3.4.2.3.3.1 to .5); Report_Triggers are the events of 3.6.5.1.4 the
--  position knows and the parameters of packet 58 (3.6.5.1.5).

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Balise_Groups; use EVC_Balise_Groups;
with EVC_Acceptance;
with EVC_Config;
with EVC_Distances;     use EVC_Distances;
with EVC_Linking;
with EVC_Location;      use EVC_Location;
with EVC_Modes;         use EVC_Modes;
with EVC_Odometry;
with EVC_Origins;
with EVC_Radio_Info;
with EVC_Ports;         use EVC_Ports;
with EVC_Train_Data;
with ETCS_Bits;
with ETCS_Packet_Index;
with ETCS_Telegram;
with ETCS_Track_Packets.P58;
with ETCS_Train_Packets.P0;
with ETCS_Train_Packets.P1;
with ETCS_Variables;    use ETCS_Variables;
with Interfaces;        use Interfaces;

--  @req 3.6.2.2.2 c), 3.6.5.1.4 e), 3.6.5.1.4 k), 3.7.3.1 m), 3.15.1.3.1
--  @req 3.15.1.3.1 c), A.3.3.2, 4.4.6.1.4, 4.4.7.1.6, 4.4.7.1.6 a)
--  @req 4.4.7.1.6 b), 4.4.8.1.3, 4.4.15.1.3, 4.4.20.1.4, 4.8.2.2, 4.8.2.3
--  @req 4.8.3.1.1 Table-footnote [1], 4.8.3.1.1 Table-footnote [2]
--  @req 5.4.3.2 D32, 5.12.2.5, 5.12.4.3, 5.15.1.4
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

   --  Events of a cycle

   --  JRU event code: Event_Code (EVC_Ports)
   type Event_Kind_T is
     (Linking_Reaction,   -- Q_LINKREACTION, cause, link index
      Unexpected_Group,   -- identity
      Missed_Group,       -- identity
      Odometer_Accuracy,  -- 0 nominal, 1 impaired, 2 safety threshold
      Position_Status,    -- Status_T'Pos
      Cold_Movement,      -- 1: a cold movement was detected
      New_LRBG,           -- identity
      Inconsistent_Linked,    -- identity (3.16.2.4: M_ERROR 1)
      Inconsistent_Unlinked); -- identity (3.16.2.5: M_ERROR 2)

   --  The JRU event code of a kind: Event_Kind_T'Pos + 4 up to New_LRBG,
   --  then 12 and 13 (11 is the driver's actions, EVC_JRU_Messages)
   function Event_Code (K : Event_Kind_T) return Unsigned_8 is
     (if K = Inconsistent_Linked then 12
      elsif K = Inconsistent_Unlinked then 13
      else Event_Kind_T'Pos (K) + 4);

   --  The cause of a linking reaction (byte 3 of the record)
   Cause_Early           : constant := 1;  -- 3.16.2.3.1 a)
   Cause_Not_Detected    : constant := 2;  -- 3.16.2.3.1 b)
   Cause_Other_Group     : constant := 3;  -- 3.16.2.3.1 c)
   Cause_Wrong_Direction : constant := 4;  -- 3.4.4.4.7
   Cause_Double_Missed   : constant := 5;  -- 3.16.2.7.1.1
   Cause_Double_Repos    : constant := 6;  -- 3.16.2.7.2.2
   Cause_Inconsistent    : constant := 7;  -- 3.16.2.4.1, 3.16.2.4.4

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
      --  3.15.1.3.1 b), c), 5.15.1.4: the RBC/RBC border (Set_Border)
      --  passed by the max safe front end, by the min safe rear end
      Border_Front       : Boolean := False;
      Border_Rear        : Boolean := False;
   end record;

   No_Triggers : constant Triggers_T := (others => False);

   type Report_Kind_T is (Report_P0, Report_P1);

   --  State

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
   --  for the information they give
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
   --  @req 3.11.11.4 8th bullet
   function Front_Offset (S : Sense_T) return EVC_Config.Antenna_Offset_T
     with Global => State;

   --  The frame position of the estimated front end
   function Front_X return Dist_T
     with Global => (State, EVC_Odometry.State);

   --  Against the LRBG, along the orientation (0 without LRBG): the
   --  estimated front end (3.6.1.3); the odometer's part of the
   --  confidence interval, Q_LOCACC and the over- and under-reading
   --  amounts of 3.6.4.1.5 a) and b), what grows with the distance
   --  travelled (3.6.4.1.2)
   --  @req 3.6.1.6
   function Estimated_Front return Dist_T
     with Global => (State, EVC_Odometry.State);
   function Doubt_Over return Length_T
     with Global => (State, EVC_Odometry.State),
          Post => (if not LRBG.Valid then Doubt_Over'Result = 0);
   function Doubt_Under return Length_T
     with Global => (State, EVC_Odometry.State),
          Post => (if not LRBG.Valid then Doubt_Under'Result = 0);

   --  3.6.4.1.5: gamma times L_TRAINOVER and L_TRAINUNDER, the consist's
   --  terms of the confidence interval (0 when gamma is 0): from the
   --  first Supervised Manoeuvre authorisation to End_Manoeuvre those of
   --  Shift_For_Manoeuvre, before it those of Set_Gamma
   function Gamma_Over return Length_T
     with Global => State;
   function Gamma_Under return Length_T
     with Global => State;

   --  The confidence interval of 3.6.4.1.5 against the LRBG (0 without
   --  LRBG): the odometer's part and the gamma terms
   function Interval_Over return Length_T
     with Global => (State, EVC_Odometry.State),
          Post => Interval_Over'Result
                    = (if LRBG.Valid then Add (Doubt_Over, Gamma_Over)
                       else 0);
   function Interval_Under return Length_T
     with Global => (State, EVC_Odometry.State),
          Post => Interval_Under'Result
                    = (if LRBG.Valid then Add (Doubt_Under, Gamma_Under)
                       else 0);
   --  @req 3.6.4.1.5, 3.6.4.1.5 a), 3.6.4.1.5 b), 3.6.4.1.5 last sentence
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
   --  @req 3.6.1.7
   function Min_Safe_Rear return Dist_T
     with Global => (State, EVC_Odometry.State),
          Post => Min_Safe_Rear'Result <= Min_Safe_Front;
   function Train_Length_Known return Boolean
     with Global => State;
   function Length_Of_Train return Length_T
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
   --  @req 3.6.6.2
   function Geo_Metres return Natural
     with Global => State;

   --  3.6.5
   --  @req 3.6.5.1.4, 3.6.5.1.4 a), 3.6.5.1.4 b), 3.6.5.1.4 g), 3.6.5.1.4 i)
   --  @req 3.6.5.1.4 j)
   function Report_Triggers return Triggers_T
     with Global => State;
   --  @req 3.4.2.3.3.1
   function Report_Kind return Report_Kind_T
     with Global => State;
   function Report_Parameters_Stored return Boolean
     with Global => State;
   --  Read only, for the test runners (the SUBSET-076 reach-point): the
   --  distance, cm, the max safe front end (Front) or the min safe rear
   --  end (not Front) still has to run to the nearest location of
   --  packet 58 (3.6.5.1.5 c) or RBC/RBC border (3.15.1.3.1 b, c) of
   --  that kind not passed yet; Max_Cm when there is none
   function Report_Location_To_Go (Front : Boolean) return Length_T
     with Global => (State, EVC_Odometry.State);

   --  The content of the position report (3.6.5.1.2): packet 0, and
   --  packet 1 for Report_P1. Q_INTEGRITY is "no train integrity
   --  information" (3.6.5.2).
   --  @req 3.6.2.2.2.1, 3.6.5.1.2, 3.6.5.1.2 a), 3.6.5.1.2 b), 3.6.5.1.2 c)
   --  @req 3.6.5.1.2 d), 3.6.5.1.2 e), 3.6.5.1.2 f), 3.6.5.1.2 h)
   --  @req 3.6.5.1.2 i), 3.8.2.1.7
   function Position_Report (Mode : Mode_T; Level : Level_T)
     return ETCS_Train_Packets.P0.Packet_T
     with Global => (State, EVC_Odometry.State);
   --  5.21.2.2 A045: the position report of the Supervised Manoeuvre
   --  request with the safe consist C: the estimated front end the far
   --  end of the consist in front of the engine (the side of its active
   --  cab), or in rear of it when the train orientation is the other
   --  side, its confidence interval widened by the consist's minimum and
   --  maximum (3.6.4.1.5); once the position was shifted to the other end
   --  of the consist (Shift_For_Manoeuvre) the report as it is
   --  @req 5.21.2.2 A045
   function Consist_Report (Mode  : Mode_T;
                            Level : Level_T;
                            C     : EVC_Train_Data.Consist_T)
     return ETCS_Train_Packets.P0.Packet_T
     with Global => (State, EVC_Odometry.State);
   --  @req 3.4.2.3.3.2, 3.4.2.3.3.3
   function Position_Report_2 (Mode : Mode_T; Level : Level_T)
     return ETCS_Train_Packets.P1.Packet_T
     with Global => (State, EVC_Odometry.State);

   --  Operations

   --  A new on-board: nothing known (what is kept over No Power comes
   --  back through Restore below, EVC_Core.Power_Up)
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
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
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
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Status = Status'Old
                  and then Passage_Open = Passage_Open'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  3.16.2.5.1 b): a balise detected whose telegram the BTM could not
   --  decode, and its stamp (EVC_Ports, BTM), for the next Update; a
   --  balise of the group being passed, else of a group of its own
   procedure Receive_Detection (Stamp : Unsigned_32)
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Status = Status'Old
                  and then Passage_Open = Passage_Open'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  3.16.1.1: a telegram the codec refused, of which the header H
   --  could be read, and the stamp of its balise: a balise of its group
   --  read but not compliant, which makes the group's message
   --  inconsistent (EVC_Balise_Groups.Consistent); kept as a telegram of
   --  no bits and no packets
   --  @req 3.16.1.1, 3.16.1.1.1
   --  Compliant: a telegram of a system version this on-board does not
   --  read (3.17), its balise read and its content left out, no
   --  inconsistency
   procedure Receive_Refused (H : ETCS_Telegram.Header_T;
                              Stamp : Unsigned_32;
                              Compliant : Boolean := False)
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Status = Status'Old
                  and then Passage_Open = Passage_Open'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  One cycle (see above). Sample is the odometer sample of the cycle
   --  when Sampled (the same sample may come again: it changes nothing).
   --  @req 3.6.1.5, 3.6.6.4.3, 3.6.8.5, 3.6.8.6.2
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
            Kept_By_Manoeuvre (Orientation'Old)
            and then Cab_One (Cab_A_Active, Cab_B_Active)
            and then Cab_None (Cab_A_Active, Cab_B_Active, Orientation'Old,
                               Orientation_Known'Old)
            and then Manoeuvre_Orientation = Manoeuvre_Orientation'Old
            --  the LRBG changes only at the end of a passage
            and then
            (if Pending_Count'Old = 0 and then not Passage_Open'Old
             then LRBG = LRBG'Old)
            --  3.6.4.1.2: against the same LRBG and orientation the
            --  confidence interval does not shrink
            and then
            (if LRBG = LRBG'Old and then Orientation = Orientation'Old
                                and then Manoeuvre_Orientation
                                           = Manoeuvre_Orientation'Old
             then Doubt_Over >= Doubt_Over'Old
                  and then Doubt_Under >= Doubt_Under'Old)
            and then Pending_Count = 0;

   --  The train length of the valid Train Data, cm
   --  @req 4.4.6.1.4, 4.4.8.1.3, 4.4.20.1.4
   procedure Set_Train_Length (Length : Length_T)
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => Train_Length_Known and then Length_Of_Train = Length
                  and then Active_Cab = Active_Cab'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then LRBG = LRBG'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  3.6.1.5.1: from the first Supervised Manoeuvre authorisation
   --  (Shift_For_Manoeuvre) to the end of the mission or Non Leading
   --  (End_Manoeuvre) the train orientation is that of the last
   --  authorisation, not the active cab's
   function Manoeuvre_Orientation return Boolean
     with Global => State;

   --  4.4.21.1.9, DMI 8.2.3.10: the direction controller position that
   --  moves the train in the direction of the Supervised Manoeuvre
   --  authorisation: 1 forward (the train orientation of the authorisation
   --  is the active cab's side), 2 backward, 0 none (no authorisation's
   --  orientation, or no active cab). Decision: forward and backward
   --  are those of the active cab's direction controller
   --  @req 4.4.21.1.9
   function Manoeuvre_Direction return Natural
     with Global => State,
          Post   => Manoeuvre_Direction'Result <= 2;

   --  3.6.1.5: after Update with the cab inputs A and B, the active cab
   --  defines the orientation (Cab_One), with none (or both, SUBSET-034
   --  2.5.1.4.7) the last active one (Old_O, Old_Known) stays (Cab_None);
   --  3.6.1.5.1: a Supervised Manoeuvre's stays (Kept_By_Manoeuvre)
   function Kept_By_Manoeuvre (Old_O : Sense_T) return Boolean
   is (if Manoeuvre_Orientation then Orientation = Old_O)
     with Global => State;
   function Cab_One (A, B : Boolean) return Boolean
   is (if A /= B
       then (Manoeuvre_Orientation
             or else Orientation = (if A then Plus else Minus))
            and then Orientation_Known
            and then Active_Cab = (if A then Cab_A else Cab_B))
     with Global => State;
   function Cab_None (A, B      : Boolean;
                      Old_O     : Sense_T;
                      Old_Known : Boolean) return Boolean
   is (if A = B
       then Orientation = Old_O and then Orientation_Known = Old_Known
            and then Active_Cab = No_Cab)
     with Global => State;

   --  4.4.21.1.7, 5.21.2.2 A075: a Supervised Manoeuvre authorisation
   --  taken; Opposite: the direction of its MA is opposite to the train
   --  orientation, which turns, and the train position is that of the
   --  other end of the consist C (safe consist length, metres); not
   --  Opposite, the first authorisation moves it to the far end of the
   --  consist in front of the engine (3.18.3.2.5.1), a later one keeps
   --  it: the estimated front end and the confidence interval of 3.6.1.3.4 and
   --  3.6.4.1.5 (gamma 1) in the new orientation. Decision: computed from
   --  the active cab's end of the engine (the estimated front end before
   --  the shift does not yet hold the consist length in front of the
   --  engine, 3.6.1.3.4), it is 4.4.21.1.7 a) to c) for a front end that
   --  does
   --  @req 4.4.21.1.7, 4.4.21.1.7 a), 4.4.21.1.7 b) 1st bullet
   --  @req 4.4.21.1.7 b) 2nd bullet, 4.4.21.1.7 c) 1st bullet
   --  @req 4.4.21.1.7 c) 2nd bullet, 3.18.3.2.5.1
   procedure Shift_For_Manoeuvre (Opposite : Boolean;
                                  C        : EVC_Train_Data.Consist_T)
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => Manoeuvre_Orientation
                  and then Orientation
                           = (if Opposite
                              then EVC_Distances.Opposite (Orientation'Old)
                              else Orientation'Old)
                  and then Active_Cab = Active_Cab'Old
                  and then LRBG = LRBG'Old
                  and then (if not Opposite
                              and then Manoeuvre_Orientation'Old
                            then Doubt_Over = Doubt_Over'Old
                                 and then Doubt_Under = Doubt_Under'Old);

   --  The end of the mission, or Non Leading: the orientation follows
   --  the active cab again and the front end is the engine's
   procedure End_Manoeuvre
     with Global => (In_Out => State),
          Post => not Manoeuvre_Orientation
                  and then Orientation = Orientation'Old
                  and then Active_Cab = Active_Cab'Old
                  and then LRBG = LRBG'Old;

   --  3.6.4.1.5 last sentence: gamma 1 before the first Supervised
   --  Manoeuvre authorisation (On), the terms of the consist C (safe
   --  consist length, metres) in front of the engine when the train
   --  orientation is the active cab's (or no cab is active), in rear of
   --  it when opposite; not On, gamma 0. Once a cycle, after the
   --  orientation of the cycle is decided
   --  @req 3.6.4.1.5 last sentence
   procedure Set_Gamma (On : Boolean; C : EVC_Train_Data.Consist_T)
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => Train_Length_Known = Train_Length_Known'Old
                  and then Length_Of_Train = Length_Of_Train'Old
                  and then Active_Cab = Active_Cab'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then LRBG = LRBG'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  Whether the estimated front end is shifted to the far end of the
   --  consist (Set_Standby_Front, Shift_For_Manoeuvre)
   function Front_Shifted return Boolean
     with Global => State;

   --  3.6.1.3.4, 4.4.7.1.6 b): in Stand-By while no valid Train Data is
   --  available but the safe consist length is (On), the estimated front
   --  end takes into account the nominal consist length of C in front of
   --  the engine when the train orientation is the active cab's (or no
   --  cab is active), in rear of it when opposite (Consist_End, the
   --  confidence interval of 3.6.4.1.5 with it); not On, the front end of
   --  the engine again. From the first Supervised Manoeuvre authorisation
   --  the shift is Shift_For_Manoeuvre's and kept. Once a cycle, after
   --  the orientation of the cycle is decided
   --  @req 4.4.7.1.6 b)
   procedure Set_Standby_Front (On : Boolean; C : EVC_Train_Data.Consist_T)
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => Train_Length_Known = Train_Length_Known'Old
                  and then Length_Of_Train = Length_Of_Train'Old
                  and then Active_Cab = Active_Cab'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then LRBG = LRBG'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old
                  and then (if not Manoeuvre_Orientation
                            then Front_Shifted = On);

   --  No valid Train Data (3.18.3): the min safe rear end is the min safe
   --  front end again and the rear end triggers do not fire
   procedure Unset_Train_Length
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => not Train_Length_Known
                  and then Active_Cab = Active_Cab'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then LRBG = LRBG'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  3.15.1.3.1 b), c) (the RBC/RBC handover): the border
   --  of an RBC transition order, D along the orientation from the
   --  balise group Ref (an anchor the position keeps, as for packet 58).
   --  Its passage by the max safe front end and by the min safe rear end
   --  sets Border_Front and Border_Rear of the triggers once each. OK
   --  False when Ref is none of the anchors.
   --  @req 3.15.1.3.1 b)
   procedure Set_Border (Ref : Identity_T; D : Length_T; OK : out Boolean)
     with Global => (In_Out => State, Input => EVC_Odometry.State),
          Post => LRBG = LRBG'Old and then Orientation = Orientation'Old
                                  and then Manoeuvre_Orientation
                                             = Manoeuvre_Orientation'Old
                  and then Active_Cab = Active_Cab'Old
                  and then Status = Status'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  The border forgotten (the order deleted or executed)
   procedure Delete_Border
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => LRBG = LRBG'Old and then Orientation = Orientation'Old
                                  and then Manoeuvre_Orientation
                                             = Manoeuvre_Orientation'Old
                  and then Active_Cab = Active_Cab'Old
                  and then Status = Status'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  Packet 58 (3.6.5.1.5, 3.6.5.1.7), received by radio
   --  referring to the balise group Ref: one of the anchors the position
   --  keeps (LRBG, SOLR, the LRBGs of 3.6.2.2.2 c). OK False when Ref is
   --  none of them or the packet cannot be used.
   --  @req 3.6.5.1.7
   procedure Set_Report_Parameters
     (P   : ETCS_Track_Packets.P58.Packet_T;
      Ref : Identity_T;
      OK  : out Boolean)
     with Global => (In_Out => State, Input => EVC_Odometry.State),
          Post => LRBG = LRBG'Old and then Orientation = Orientation'Old
                                  and then Manoeuvre_Orientation
                                             = Manoeuvre_Orientation'Old
                  and then Active_Cab = Active_Cab'Old
                  and then Status = Status'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  A position report was sent: the periods restart
   procedure Report_Sent (Now_Ms : Unsigned_64)
     with Global => (In_Out => State, Input => EVC_Odometry.State),
          Post => LRBG = LRBG'Old and then Orientation = Orientation'Old
                                  and then Manoeuvre_Orientation
                                             = Manoeuvre_Orientation'Old
                  and then Active_Cab = Active_Cab'Old
                  and then Status = Status'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  4.9.1.3: the position report parameters are deleted on
   --  entering level 1
   procedure Delete_Report_Parameters
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => not Report_Parameters_Stored
                  and then LRBG = LRBG'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Active_Cab = Active_Cab'Old
                  and then Status = Status'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  3.4.2.3.3.6: the RBC assigns a co-ordinate system to the single
   --  balise group Id, nominal or reverse against the direction
   --  reference of the position report based on two balise groups
   --  (from the previous LRBG towards Id, 3.4.2.3.3.2). Refused (OK
   --  False) when Id was reported with different previous LRBGs
   --  (3.4.2.3.3.7, 3.4.2.3.3.8) or has no direction reference.
   --  @req 3.4.2.3.3.6, 3.4.2.3.3.8
   procedure Assign_Coordinate_System (Id      : Identity_T;
                                       Nominal : Boolean;
                                       OK      : out Boolean)
     with Global => (In_Out => State);

   --  3.6.2.2.2 c), 3.6.4.2.3: the location reference of an
   --  information received by radio, the balise group Id named in the
   --  message (NID_LRBG): the LRBG, the SOLR or one of the last LRBGs
   --  the on-board keeps (the last eight, Max_Recent of the body), its
   --  last passage. Shifted: message 33 (and the emergency stop 15)
   --  shifts it by Shift along the nominal direction of the group
   --  (D_REF, 7.5.1.17), which needs that direction known. The origin of
   --  the stored information (EVC_Origins) allocated for it, referred
   --  to the SOLR as Record_Taken does for a group (3.6.4.2.5); 0 when
   --  Id is none of those groups, a shift has no direction, or the table
   --  is full. G: the orientation of the group, T: the train
   --  orientation, as directions on the axis (the packets valid for the
   --  train are those of Valid_For (Q_DIR, G, T), 3.6.3.1.3); S, the
   --  sense of the distances: the train orientation (Reversed: the
   --  opposite one, a Supervised Manoeuvre authorisation that turns
   --  it, 4.4.21.1.7).
   --  @req 3.6.3.1.3
   procedure Radio_Origin (Id      : Identity_T;
                           Shifted : Boolean;
                           Shift   : Dist_T;
                           Origin  : out EVC_Origins.Count_T;
                           G, T    : out Direction_T;
                           S       : out Sense_T;
                           Reversed : Boolean := False)
     with Global => (Input  => (State, EVC_Odometry.State),
                     In_Out => EVC_Origins.State),
          Post => T = To_Direction (S)
                  and then (if Origin /= 0
                            then EVC_Origins.Get (Origin).Used);

   --  The train position kept over No Power (4.10 column NP "to be
   --  revalidated", 4.11, 3.6.1.3.3; EVC_Retained holds it). Kept when
   --  it refers to an LRBG: the LRBG, Away the frame distance from its
   --  location reference to the train (the frame position minus its X),
   --  its confidence interval folded into its location accuracy (the
   --  frame of the odometer restarts at the power-up, its deviations
   --  with it: the interval is kept, it does not shrink), and the train
   --  orientation. A position referred to unlinked groups only is not
   --  kept (it is deleted over No Power).
   type Kept_Position_T is record
      Known        : Boolean := False;
      LRBG         : Anchor_T;
      Away         : Dist_T := 0;
      Orient       : Sense_T := Plus;
      Orient_Known : Boolean := False;
   end record;

   --  @req 3.6.4.2.2.1
   procedure Keep (K : out Kept_Position_T)
     with Global => (Input => (State, EVC_Odometry.State)),
          Post => (if K.Known then K.LRBG.Valid);

   --  At the power-up, after Clear: the kept position becomes the LRBG
   --  and the SOLR (3.6.4.2.2.1), invalid (3.6.1.3.3), the train at the
   --  kept distance from it in the new frame
   procedure Restore (K : Kept_Position_T)
     with Global => (In_Out => State, Input => EVC_Odometry.State),
          Post => (if K.Known and then K.LRBG.Valid
                   then Status = Invalid and then LRBG.Valid
                        and then LRBG.Id = K.LRBG.Id
                   else Status = Status'Old and then LRBG = LRBG'Old);

   --  4.11.1.1: no cold movement occurred, the kept position is valid
   --  @req 5.4.3.2 A35
   procedure Revalidate
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => (if Status'Old = Invalid then Status = Valid
                   else Status = Status'Old)
                  and then LRBG = LRBG'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Active_Cab = Active_Cab'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  4.10, 4.11: the position becomes invalid, or is deleted
   procedure Invalidate
     with Global => (In_Out => State),
          Post => (if Status'Old = Unknown then Status = Unknown
                   else Status = Invalid);
   --  @req 3.6.2.2.2.1, 5.4.3.2 A24
   procedure Delete_Position
     with Global => (In_Out => State),
          Post => Status = Unknown and then not LRBG.Valid
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Active_Cab = Active_Cab'Old;
   --  3.6.6.9 d)
   --  @req 3.6.6.9 d)
   procedure Delete_Geo
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => not Geo_Known
                  --  nothing else changes (EVC_Core,
                  --  the data of 4.10)
                  and then Status = Status'Old and then LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old
                  and then Active_Cab = Active_Cab'Old;

   --  the linking of packet 5 is accepted (4.8, in
   --  the level and the mode of the on-board) and its consistency is
   --  checked (3.4.4.2.1.1 b, the modes of 4.5.2 Figure 1); both until
   --  EVC_Core sets them. The settings apply from the
   --  next Update. Accept_P79, packet 79
   --  of a balise group accepted (4.8.4.2, e.g. rejected in SH).
   --  4.8.3 [1]: Defer_On_Order,
   --  the linking of a group that carries a level transition order
   --  (packet 41) is held, not taken, until EVC_Core judges it again
   --  after the stores evaluated that order (Take_Held_Linking).
   --  Ignore_Info, 3.14.3.6: the information
   --  of the groups read is ignored (a movement opposite to the
   --  authorised direction): the group still locates the train (3.6),
   --  its packets are neither taken here (5, 79) nor recorded for the
   --  units (not in Taken).
   --  @req 3.14.3.6, 4.5.2.1, 4.5.2.2 Table, 4.5.2.2 Table-footnote {2}
   --  @req 4.5.2.2 Table-footnote {4}, 4.8.4.2 Table
   procedure Set_Linking_Context (Accept_Info, Check : Boolean;
                                  Accept_P79 : Boolean := True;
                                  Defer_On_Order : Boolean := False;
                                  Ignore_Info : Boolean := False)
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => Status = Status'Old and then LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old
                  and then Active_Cab = Active_Cab'Old;

   --  4.8.3 [1]: the linking held by the
   --  cycle's Update (a group with its own level transition order read
   --  with Defer_On_Order) is taken now when Accept_Info (EVC_Core: the
   --  verdict of 4.8 once the stores evaluated the group's order: not
   --  kept in the balise transition buffer), else dropped. Update drops
   --  a linking still held from the cycle before.
   procedure Take_Held_Linking (Accept_Info : Boolean)
     with Global => (In_Out => (State, EVC_Origins.State),
                     Input  => EVC_Odometry.State),
          Post => Status = Status'Old and then LRBG = LRBG'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Active_Cab = Active_Cab'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  4.8.3 [1], 4.8.5.5: the linking (packet 5
   --  in R) of the group Group, its distances along S, read in level 0
   --  or 2 with level 1 announced, kept in the balise transition buffer
   --  and released at the transition to level 1 (EVC_Core): it replaces
   --  the stored linking (the RBC's) now, not before. Decision: taken
   --  only when the SOLR is its group or a group it announces (the
   --  reference of the windows, 3.4.4.4.5.1); the windows already passed
   --  are not supervised (as at the passage of the group).
   --  @req 4.8.3.1.1 Table
   procedure Take_Released_Linking (R     : in out ETCS_Bits.Reader;
                                    Group : Identity_T;
                                    S     : Sense_T)
     with Global => (In_Out => State, Input => EVC_Odometry.State),
          Post => Status = Status'Old and then LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Active_Cab = Active_Cab'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old;

   --  3.6.6.4.1, 4.8.3, 4.8.4.2, 4.8.5:
   --  the packets 79 of the radio messages of the cycle (EVC_Radio_Info,
   --  those whose LRBG was known at reception) in the verdict of the
   --  tables (EVC_Acceptance.Radio_Geo_Verdict). Accepted: taken in the
   --  order of reception, after the one kept for the transition; their
   --  reference groups anchored when they are the LRBG or a group of
   --  the last ones, the others when passed. Stored (4.8.3 [2]): the
   --  last one kept for the level 2 transition (one is enough: a packet
   --  79 replaces the references not yet applicable, 3.6.6.3, so the
   --  sequential re-evaluation of 4.8.5.5 leaves the last). Rejected:
   --  nothing taken, the one kept deleted (4.8.5.4 a: the announcement
   --  is gone; or released in a mode that rejects it).
   --  @req 3.6.6.4.1, 4.8.4.2 Table
   procedure Take_Radio_Geo (Verdict : EVC_Acceptance.Radio_Verdict_T)
     with Global => (In_Out   => State,
                     Input    => EVC_Radio_Info.State,
                     Proof_In => EVC_Odometry.State),
          Post => Status = Status'Old and then LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old
                  and then Active_Cab = Active_Cab'Old;

   --  3.4.4.1.1, 4.8.1.6, 4.8.4: the linking (packet 5) of the
   --  radio messages of the cycle (EVC_Radio_Info: messages 3, 33 and
   --  24), referred to the LRBG the message names (its origin,
   --  Radio_Origin) and valid for the train (Q_DIR, 3.6.3.1.3), taken
   --  when Accepted (4.8.3, 4.8.4 row Linking): it replaces the stored
   --  linking, its windows from the SOLR as Take_Released_Linking does.
   --  Decision: taken when the message's LRBG is the SOLR, or when the
   --  SOLR is one of its linked groups (a message referred to an earlier
   --  LRBG); a location reference ahead of the SOLR (message 33 shifted
   --  forward) is not taken. The country of a first linked group without
   --  Q_NEWCOUNTRY is the SOLR's (the relocated origin keeps no other).
   --  @req 4.8.1.6, 4.8.4.2 Table
   procedure Take_Radio_Linking (Accepted : Boolean)
     with Global => (In_Out => State,
                     Input  => (EVC_Radio_Info.State, EVC_Origins.State,
                                EVC_Odometry.State)),
          Post => Status = Status'Old and then LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old
                  and then Active_Cab = Active_Cab'Old;

   --  4.10: entering a mode deletes the linking
   --  @req 4.10.1.3, 4.10.1.3 a), 4.10.1.3 b), 4.10.1.3 c), 4.10.1.3 d)
   --  @req 4.10.1.3 e), 4.10.1.3 Table, 4.10.1.3 Table-footnote [1]
   procedure Delete_Linking
     with Global => (In_Out => State, Proof_In => EVC_Odometry.State),
          Post => Status = Status'Old and then LRBG = LRBG'Old
                  and then SOLR = SOLR'Old
                  and then Orientation = Orientation'Old
                  and then Manoeuvre_Orientation
                             = Manoeuvre_Orientation'Old
                  and then Orientation_Known = Orientation_Known'Old
                  and then Doubt_Over = Doubt_Over'Old
                  and then Doubt_Under = Doubt_Under'Old
                  and then Active_Cab = Active_Cab'Old;

   --  For the stored information

   --  3.6.3.1: information with this Q_DIR from a group of orientation
   --  G is valid for a train whose direction (orientation, or crossing
   --  direction in SL, PS and SH) is T: nominal when both point the
   --  same way. When one is not known only "both directions" is taken
   --  (3.6.3.1.4).
   --  @req 3.6.3.1.3, 3.6.3.1.4
   function Valid_For (Q_DIR : Q_DIR_T; G, T : Direction_T) return Boolean
   is (case Q_DIR is
          when 2 => True,
          when 1 => G /= Unknown and then T /= Unknown and then G = T,
          when 0 => G /= Unknown and then T /= Unknown and then G /= T,
          when others => False);

   --  3.6.3.1.1 a), 3.6.3.1.3: information of a radio message valid in
   --  the direction Q_DIR of the group Id its header names (NID_LRBG)
   --  is for this train: Valid_For with the orientation of that group
   --  (the LRBG, the SOLR or one of the last LRBGs, as Radio_Origin
   --  finds it) and the train orientation. Decision: with either not
   --  known (a group the on-board does not know, no coordinate system)
   --  the order is taken: 3.6.3.1.4 is read for location based data;
   --  the orders of the session, the network and the RBC transition
   --  concern the train (SUBSET-076 3131100_08, 4100103_28 take them).
   --  @req 3.6.3.1.3
   function Radio_Valid_For (Id : Identity_T; Q_DIR : Q_DIR_T) return Boolean
     with Global => State;

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

   --  @req 3.8.4.2.1 b), 3.8.5.2.2
   type Taken_T is record
      Group    : Anchor_T := (others => <>);
      T        : Direction_T := Unknown;
      S        : Sense_T := Plus;
      Origin   : EVC_Origins.Count_T := 0;
      First    : Positive range 1 .. Max_Taken_Telegrams + 1 := 1;
      Count    : Natural range 0 .. Max_Balises := 0;
      Start_Ms : Unsigned_64 := 0;
      --  3.8.5.2.2: the group met a link announcing an unknown group
      --  with repositioning
      Repositioning : Boolean := False;
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
   --  The M_VERSION of taken telegram J (0 for no such telegram), for
   --  the operated system version (3.17.2.3)
   function Taken_Version (J : Positive) return M_VERSION_T
     with Global => State;
   --  A reader on packet P of taken telegram J
   procedure Open_Taken_Packet (J, P : Positive;
                                R    : in out ETCS_Bits.Reader)
     with Global => State,
          Pre => P <= Taken_Packet_Count (J);

   --  A distance between two balise groups, Known False when the
   --  on-board does not have it
   type Group_Distance_T is record
      Known : Boolean := False;
      D     : Dist_T := 0;
   end record;

   --  3.6.4.2.5 a): the linking distance from group From to group To
   --  along the train orientation, known when both are in the stored
   --  linking chain, From before To, its sense the orientation and no
   --  repositioning between them
   --  @req 3.6.4.2.5 a)
   function Linking_Distance (From, To : Identity_T) return Group_Distance_T
     with Global => State;

end EVC_Position;
