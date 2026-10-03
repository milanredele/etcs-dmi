--  ETCS on-board (EVC)
--  The train position, implementation.

with ETCS_Catalogue;
with ETCS_Track_Packets.P5;
with ETCS_Track_Packets.P79;
with EVC_Bytes;

package body EVC_Position
  with SPARK_Mode => On,
       Refined_State => (State => (Orient,
                                   Orient_Known,
                                   Cab_In,
                                   Pos_Status,
                                   Reported_Status,
                                   LRBG_A,
                                   Prev_A,
                                   SOLR_A,
                                   Recent,
                                   Recent_Next,
                                   Unlinked,
                                   Unlinked_Next,
                                   Seq_Counter,
                                   Links,
                                   Passage,
                                   Pending,
                                   Pending_Stamp,
                                   Pending_N,
                                   Events,
                                   Event_N,
                                   Reaction_Flag,
                                   Reaction_Value,
                                   Unexpected_Flag,
                                   Missed_Flag,
                                   Odo_Reported,
                                   Cold_Reported,
                                   Geo_Refs,
                                   Geo_Current,
                                   Geo_Value,
                                   Geo_Valid,
                                   Params_Stored,
                                   T_Cycloc_Ms,
                                   D_Cycloc,
                                   M_Loc,
                                   Locations,
                                   Last_Report_Ms,
                                   Now_Seen,
                                   Last_Report_Travel,
                                   Immediate_Pending,
                                   Triggers,
                                   Last_Standstill,
                                   Last_Mode,
                                   Last_Level,
                                   Mode_Seen,
                                   Train_Length,
                                   Length_Known,
                                   Taken_List,
                                   Taken_N,
                                   Taken_Tels,
                                   Taken_Tel_N,
                                   Passage_Ms,
                                   Previous_Ms,
                                   Antenna_Offset,
                                   Accept_Linking,
                                   Check_Linking))
is

   use type ETCS_Catalogue.Packet_Kind_T;
   use type EVC_Odometry.Cold_T;

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   --  3.6.2.2.2 c): the LRBGs last passed, with what the position report
   --  based on two balise groups needs (3.4.2.3.3)
   Max_Recent : constant := 8;
   type Recent_T is record
      A          : Anchor_T := (others => <>);
      Prev_Known : Boolean := False;
      Prev_Id    : Identity_T := (others => <>);
      --  the direction reference: from the previous LRBG towards A
      Dref       : Direction_T := Unknown;
      --  3.4.2.3.3.7: reported with different previous LRBGs
      Ambiguous  : Boolean := False;
   end record;
   subtype Recent_Index_T is Positive range 1 .. Max_Recent;
   type Recent_Array_T is array (Recent_Index_T) of Recent_T;
   --  (the elements of the cleared lists below: (others => No_X) is
   --  built in place, (others => (others => <>)) in a temporary on the
   --  stack)
   No_Recent : constant Recent_T := (others => <>);
   No_Anchor : constant Anchor_T := (others => <>);

   --  3.6.1.3: the last two unlinked groups passed are ORBGs
   type Unlinked_Array_T is array (1 .. 2) of Anchor_T;

   subtype Pending_Index_T is Positive range 1 .. Max_Pending;
   type Pending_T is array (Pending_Index_T) of ETCS_Telegram.Telegram_T;
   type Stamps_T is array (Pending_Index_T) of Unsigned_32;

   type Events_T is array (1 .. Max_Events) of Event_T;
   No_Event : constant Event_T := (others => <>);

   --  3.6.6: a track kilometre reference
   Max_Geo : constant := 32;
   type Geo_Ref_T is record
      Valid    : Boolean := False;
      Id       : Identity_T := (others => <>);
      --  D_POSOFF, along Sense from the location reference of the group
      Offset   : Length_T := 0;
      Sense    : Sense_T := Plus;
      --  Q_MPOSITION 1: counting upwards in the nominal direction
      Same     : Boolean := True;
      Value    : M_POSITION_T := 0;
      --  the reference group was passed
      Anchored : Boolean := False;
      Ref      : Anchor_T := (others => <>);
   end record;
   type Geo_Array_T is array (1 .. Max_Geo) of Geo_Ref_T;
   No_Geo_Ref : constant Geo_Ref_T := (others => <>);

   --  3.6.5.1.5 c): locations where to report
   Max_Locations : constant := 31;
   type Locations_T is array (1 .. Max_Locations) of Item_T;
   No_Item : constant Item_T := (others => <>);

   --  The installation: the antenna from the cab A end (Plus) and from
   --  the cab B end (Minus), cm (EVC_Config, Set_Antenna)
   type Offsets_T is array (Sense_T) of EVC_Config.Antenna_Offset_T;
   Antenna_Offset     : Offsets_T :=
     (Plus  => EVC_Config.Default.Antenna_To_Cab_A,
      Minus => EVC_Config.Default.Antenna_To_Cab_B);

   --  Added by e4/modes (Set_Linking_Context): packet 5 is accepted
   --  (4.8), the linking consistency is checked (3.4.4.2.1.1 b)
   Accept_Linking     : Boolean := True;
   Check_Linking      : Boolean := True;

   Orient             : Sense_T := Plus;
   Orient_Known       : Boolean := False;
   Cab_In             : Cab_T := No_Cab;
   Pos_Status         : Status_T := Unknown;
   Reported_Status    : Status_T := Unknown;
   LRBG_A             : Anchor_T;
   Prev_A             : Anchor_T;
   SOLR_A             : Anchor_T;
   Recent             : Recent_Array_T;
   Recent_Next        : Recent_Index_T := 1;
   Unlinked           : Unlinked_Array_T;
   Unlinked_Next      : Positive range 1 .. 2 := 1;
   Seq_Counter        : Natural := 0;
   Links              : EVC_Linking.Linking_T;
   Passage            : Passage_T;
   Pending            : Pending_T;
   Pending_Stamp      : Stamps_T := (others => 0);
   Pending_N          : Natural range 0 .. Max_Pending := 0;
   Events             : Events_T;
   Event_N            : Natural range 0 .. Max_Events := 0;
   Reaction_Flag      : Boolean := False;
   Reaction_Value     : Q_LINKREACTION_T := 2;
   Unexpected_Flag    : Boolean := False;
   Missed_Flag        : Boolean := False;
   Odo_Reported       : Unsigned_8 := 0;
   Cold_Reported      : Boolean := False;
   Geo_Refs           : Geo_Array_T;
   Geo_Current        : Geo_Ref_T;
   Geo_Value          : Natural := 0;
   Geo_Valid          : Boolean := False;
   Params_Stored      : Boolean := False;
   T_Cycloc_Ms        : Unsigned_64 := 0;   -- 0: not periodically
   D_Cycloc           : Length_T := 0;      -- 0: not periodically
   M_Loc              : M_LOC_T := 2;
   Locations          : Locations_T;
   Last_Report_Ms     : Unsigned_64 := 0;
   --  the time of the last Update
   Now_Seen           : Unsigned_64 := 0;
   Last_Report_Travel : Length_T := 0;
   Immediate_Pending  : Boolean := False;
   Triggers           : Triggers_T := No_Triggers;
   Last_Standstill    : Boolean := True;
   Last_Mode          : Mode_T := M_NP;
   Last_Level         : Level_T := L0;
   Mode_Seen          : Boolean := False;
   Train_Length       : Length_T := 0;
   Length_Known       : Boolean := False;

   --  The groups taken into account in the last Update and the telegrams
   --  of their passages (phase E3)
   type Taken_Array_T is array (1 .. Max_Taken) of Taken_T;
   No_Taken : constant Taken_T := (others => <>);
   type Taken_Tels_T is
     array (1 .. Max_Taken_Telegrams) of ETCS_Telegram.Telegram_T;
   Taken_List  : Taken_Array_T;
   Taken_N     : Natural range 0 .. Max_Taken := 0;
   Taken_Tels  : Taken_Tels_T;
   Taken_Tel_N : Natural range 0 .. Max_Taken_Telegrams := 0;
   --  the Start_Ms of the open passage, and the time of the Update
   --  before the current one
   Passage_Ms  : Unsigned_64 := 0;
   Previous_Ms : Unsigned_64 := 0;

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Status return Status_T is (Pos_Status)
     with Refined_Global => Pos_Status;
   function Orientation return Sense_T is (Orient)
     with Refined_Global => Orient;
   function Orientation_Known return Boolean is (Orient_Known)
     with Refined_Global => Orient_Known;
   function Active_Cab return Cab_T is (Cab_In)
     with Refined_Global => Cab_In;
   function LRBG return Anchor_T is (LRBG_A)
     with Refined_Global => LRBG_A;
   function Previous_LRBG return Anchor_T is (Prev_A)
     with Refined_Global => Prev_A;
   function SOLR return Anchor_T is (SOLR_A)
     with Refined_Global => SOLR_A;
   function Unlinked_ORBG (I : Positive) return Anchor_T is (Unlinked (I))
     with Refined_Global => Unlinked;
   function Linking return EVC_Linking.Linking_T is (Links)
     with Refined_Global => Links;
   function Pending_Count return Natural is (Pending_N)
     with Refined_Global => Pending_N;
   function Passage_Open return Boolean is (Passage.Open)
     with Refined_Global => Passage;
   function Train_Length_Known return Boolean is (Length_Known)
     with Refined_Global => Length_Known;
   function Event_Count return Natural is (Event_N)
     with Refined_Global => Event_N;
   function Event (I : Positive) return Event_T is (Events (I))
     with Refined_Global => (Input => Events, Proof_In => Event_N);
   function Linking_Reaction_Requested return Boolean is (Reaction_Flag)
     with Refined_Global => Reaction_Flag;
   function Reaction return Q_LINKREACTION_T is (Reaction_Value)
     with Refined_Global => Reaction_Value;
   function Unexpected_Group_Found return Boolean is (Unexpected_Flag)
     with Refined_Global => Unexpected_Flag;
   function Missed_Group_Found return Boolean is (Missed_Flag)
     with Refined_Global => Missed_Flag;
   function Geo_Known return Boolean is (Geo_Valid)
     with Refined_Global => Geo_Valid;
   function Geo_Metres return Natural is (Geo_Value)
     with Refined_Global => Geo_Value;
   function Report_Triggers return Triggers_T is (Triggers)
     with Refined_Global => Triggers;
   function Report_Parameters_Stored return Boolean is (Params_Stored)
     with Refined_Global => Params_Stored;

   --  3.4.2.3.3.1: the LRBG has no co-ordinate system
   function Report_Kind return Report_Kind_T is
     (if LRBG_A.Valid and then LRBG_A.Orientation = Unknown
      then Report_P1 else Report_P0)
     with Refined_Global => LRBG_A;

   function Front_Offset (S : Sense_T) return EVC_Config.Antenna_Offset_T
   is
     (Antenna_Offset (S))
     with Refined_Global => Antenna_Offset;

   function Front_X return Dist_T is
     (Advance (EVC_Odometry.Position, Orient, Antenna_Offset (Orient)))
     with Refined_Global => (Orient, Antenna_Offset, EVC_Odometry.State);

   --  Against an anchor, along the orientation
   function Front_From (A : Anchor_T) return Dist_T is
     (Estimated (A, Orient, Front_X))
     with Global => (Orient, Antenna_Offset, EVC_Odometry.State);

   function Over_From (A : Anchor_T) return Length_T is
     (EVC_Location.Doubt_Over
        (A, Orient, EVC_Odometry.Low, EVC_Odometry.High))
     with Global => (Orient, EVC_Odometry.State);

   function Under_From (A : Anchor_T) return Length_T is
     (EVC_Location.Doubt_Under
        (A, Orient, EVC_Odometry.Low, EVC_Odometry.High))
     with Global => (Orient, EVC_Odometry.State);

   function Estimated_Front return Dist_T is
     (if LRBG_A.Valid then Front_From (LRBG_A) else 0)
     with Refined_Global => (LRBG_A, Orient, Antenna_Offset,
                             EVC_Odometry.State);

   function Doubt_Over return Length_T is
     (if LRBG_A.Valid then Over_From (LRBG_A) else 0)
     with Refined_Global => (LRBG_A, Orient, EVC_Odometry.State);

   function Doubt_Under return Length_T is
     (if LRBG_A.Valid then Under_From (LRBG_A) else 0)
     with Refined_Global => (LRBG_A, Orient, EVC_Odometry.State);

   function Min_Safe_Front return Dist_T is
     (Min_Safe (Estimated_Front, Doubt_Over))
     with Refined_Global => (LRBG_A, Orient, Antenna_Offset,
                             EVC_Odometry.State);

   function Max_Safe_Front return Dist_T is
     (Max_Safe (Estimated_Front, Doubt_Under))
     with Refined_Global => (LRBG_A, Orient, Antenna_Offset,
                             EVC_Odometry.State);

   function SOLR_Estimated_Front return Dist_T is
     (if SOLR_A.Valid then Front_From (SOLR_A) else 0)
     with Refined_Global => (SOLR_A, Orient, Antenna_Offset,
                             EVC_Odometry.State);

   function SOLR_Min_Safe_Front return Dist_T is
     (Min_Safe (SOLR_Estimated_Front,
                (if SOLR_A.Valid then Over_From (SOLR_A) else 0)))
     with Refined_Global => (SOLR_A, Orient, Antenna_Offset,
                             EVC_Odometry.State);

   function SOLR_Max_Safe_Front return Dist_T is
     (Max_Safe (SOLR_Estimated_Front,
                (if SOLR_A.Valid then Under_From (SOLR_A) else 0)))
     with Refined_Global => (SOLR_A, Orient, Antenna_Offset,
                             EVC_Odometry.State);

   function Min_Safe_Rear return Dist_T is
     (if Length_Known then Diff (Min_Safe_Front, Train_Length)
      else Min_Safe_Front)
     with Refined_Global => (LRBG_A, Orient, Length_Known, Train_Length,
                             Antenna_Offset, EVC_Odometry.State);

   --  3.6.4.1.2: against the same anchor the interval only widens when
   --  the frame deviations grow
   procedure Lemma_Doubts_Grow (A : Anchor_T; S : Sense_T;
                                Low_1, High_1, Low_2, High_2 : Length_T)
     with Ghost,
          Global => null,
          Pre => Low_2 >= Low_1 and then High_2 >= High_1,
          Post => EVC_Location.Doubt_Over (A, S, Low_2, High_2)
                    >= EVC_Location.Doubt_Over (A, S, Low_1, High_1)
                  and then EVC_Location.Doubt_Under (A, S, Low_2, High_2)
                             >= EVC_Location.Doubt_Under
                                  (A, S, Low_1, High_1);

   -----------------------
   -- Lemma_Doubts_Grow --
   -----------------------

   procedure Lemma_Doubts_Grow (A : Anchor_T; S : Sense_T;
                                Low_1, High_1, Low_2, High_2 : Length_T)
   is
   begin
      pragma Assert (Growth (Low_2, A.Low) >= Growth (Low_1, A.Low));
      pragma Assert (Growth (High_2, A.High) >= Growth (High_1, A.High));
      pragma Assert (Rear_Growth (A, S, Low_2, High_2)
                     >= Rear_Growth (A, S, Low_1, High_1));
      pragma Assert (Front_Growth (A, S, Low_2, High_2)
                     >= Front_Growth (A, S, Low_1, High_1));
   end Lemma_Doubts_Grow;

   ---------------------------------------------------------------------
   --  Events
   ---------------------------------------------------------------------

   procedure Put_Event (Kind : Event_Kind_T; B2, B3, B4 : Unsigned_8)
   is
   begin
      if Event_N < Max_Events then
         Event_N := Event_N + 1;
         Events (Event_N) := (Kind => Kind, B2 => B2, B3 => B3, B4 => B4);
      end if;
   end Put_Event;

   procedure Put_Identity_Event (Kind : Event_Kind_T; Id : Identity_T)
   is
      C : constant Unsigned_64 := Code (Id);
   begin
      Put_Event (Kind, EVC_Bytes.Byte_Of (C, 0), EVC_Bytes.Byte_Of (C, 1),
                 EVC_Bytes.Byte_Of (C, 2));
   end Put_Identity_Event;

   --  3.16.2.3.1, 3.4.4.4.7: the reaction of link Index is requested
   procedure Request_Reaction (Value : Q_LINKREACTION_T;
                               Cause : Unsigned_8;
                               Index : Natural)
   is
   begin
      if not Reaction_Flag or else Value < Reaction_Value then
         Reaction_Value := Value;
      end if;
      Reaction_Flag := True;
      Put_Event (Linking_Reaction, Unsigned_8 (Value), Cause,
                 Unsigned_8 (Natural'Min (Index, 255)));
   end Request_Reaction;

   ---------------------------------------------------------------------
   --  Relocation
   ---------------------------------------------------------------------

   --  The linking distance from the group Id to link K of the chain,
   --  when both are in it and no repositioning lies between them
   procedure Link_Distance (Id    : Identity_T;
                            K     : EVC_Linking.Link_Count_T;
                            S     : Sense_T;
                            Known : out Boolean;
                            D     : out Dist_T)
   is
      I : EVC_Linking.Link_Count_T;
   begin
      Known := False;
      D := 0;
      if not Links.Stored or else K = 0 or else K > Links.Count
        or else S /= Links.Sense
      then
         return;
      end if;
      if Id = Links.Ref_Id then
         I := 0;
      else
         I := EVC_Linking.Find (Links, Id, 1);
         if I = 0 then
            return;
         end if;
      end if;
      if I < K and then not EVC_Linking.Repositioning_Between (Links, I, K)
      then
         Known := True;
         D := EVC_Linking.Distance (Links, K)
              - EVC_Linking.Distance (Links, I);
      end if;
   end Link_Distance;

   --  3.6.4.2.5: an item to the SOLR
   procedure Relocate_Item (Item : in out Item_T)
   is
      Known : Boolean;
      D     : Dist_T;
      K     : EVC_Linking.Link_Count_T := 0;
   begin
      if not Item.Valid or else not SOLR_A.Valid then
         return;
      end if;
      if Links.Stored and then SOLR_A.Id /= Links.Ref_Id then
         K := EVC_Linking.Find (Links, SOLR_A.Id, 1);
      end if;
      Link_Distance (Item.Ref.Id, K, Item.Sense, Known, D);
      Relocate (Item, SOLR_A, Known, D,
                EVC_Odometry.Low, EVC_Odometry.High);
   end Relocate_Item;

   --  3.6.4.2.2: A becomes the SOLR, every item follows (3.6.4.2.5)
   procedure Set_SOLR (A : Anchor_T; Link_Index : EVC_Linking.Link_Count_T)
     with Post => SOLR_A = A
   is
   begin
      SOLR_A := A;
      if Links.Stored and then Link_Index /= 0 then
         Links.Solr := Link_Index;
      end if;
      for I in Locations'Range loop
         pragma Loop_Invariant (SOLR_A = A);
         Relocate_Item (Locations (I));
      end loop;
      --  the origins of the stored information (phase E3) likewise
      for I in EVC_Origins.Index_T loop
         pragma Loop_Invariant (SOLR_A = A);
         declare
            O : EVC_Origins.Origin_T := EVC_Origins.Get (I);
         begin
            if O.Used then
               Relocate_Item (O.Est);
               Relocate_Item (O.Min);
               Relocate_Item (O.Max);
               EVC_Origins.Put (I, O);
            end if;
         end;
      end loop;
   end Set_SOLR;

   ---------------------------------------------------------------------
   --  LRBG
   ---------------------------------------------------------------------

   --  The entry of the ring of the last passage of group Id, 0 for none.
   --  A group passed again after another one (the train came back, or
   --  passed it the other way) is in the ring twice, and the ring wraps:
   --  it is read from its oldest entry (Recent_Next) to its newest, the
   --  last match wins (3.6.1.3: the position in relation to a reference
   --  group is that of its last passage).
   function Latest (Id : Identity_T) return Natural
     with Post => Latest'Result <= Max_Recent
   is
      Found : Natural range 0 .. Max_Recent := 0;
      I     : Recent_Index_T := Recent_Next;
   begin
      for K in Recent_Index_T loop
         --  not unrolled by the proof, Found's range is its type's
         pragma Loop_Invariant (True);
         if Recent (I).A.Valid and then Recent (I).A.Id = Id then
            Found := I;
         end if;
         I := (if I = Max_Recent then 1 else I + 1);
      end loop;
      return Found;
   end Latest;

   --  3.6.2.2.2 a): A, LRBG compliant, was passed. After it the LRBG is
   --  the group just passed.
   procedure Set_LRBG (A : Anchor_T)
     with Pre => A.Valid,
          Post => LRBG_A.Valid
                  and then LRBG_A.Id = A.Id
                  and then LRBG_A.X = A.X
                  and then LRBG_A.Seq = A.Seq
   is
      New_A : Anchor_T := A;
      Entry_R : Recent_T;
   begin
      if LRBG_A.Valid and then LRBG_A.Id = A.Id then
         --  the same group again (3.4.2.3.3.5): the LRBG and the
         --  previous LRBG stay, a co-ordinate system given before stays
         if New_A.Orientation = Unknown then
            New_A.Orientation := LRBG_A.Orientation;
         end if;
         LRBG_A := New_A;
      else
         --  3.4.2.3.3.4: a single balise group passed in the direction
         --  opposite to the one the LRBG was passed in: no previous LRBG
         if A.Orientation = Unknown
           and then A.Crossing /= Unknown
           and then LRBG_A.Crossing /= Unknown
           and then A.Crossing /= LRBG_A.Crossing
         then
            Prev_A := (others => <>);
         else
            Prev_A := LRBG_A;
         end if;
         LRBG_A := New_A;
         Entry_R :=
           (A          => New_A,
            Prev_Known => Prev_A.Valid,
            Prev_Id    => Prev_A.Id,
            Dref       => (if not Prev_A.Valid or else Prev_A.X = New_A.X
                           then Unknown
                           elsif New_A.X > Prev_A.X then Plus
                           else Minus),
            Ambiguous  => False);
         --  3.4.2.3.3.7: the same group with another previous LRBG
         for I in Recent_Index_T loop
            --  not unrolled by the proof, nothing needed after the loop
            pragma Loop_Invariant (True);
            if Recent (I).A.Valid and then Recent (I).A.Id = A.Id
              and then (Recent (I).Ambiguous
                        or else Recent (I).Prev_Known /= Entry_R.Prev_Known
                        or else Recent (I).Prev_Id /= Entry_R.Prev_Id)
            then
               Entry_R.Ambiguous := True;
            end if;
         end loop;
         Recent (Recent_Next) := Entry_R;
         Recent_Next :=
           (if Recent_Next = Max_Recent then 1 else Recent_Next + 1);
      end if;
      Put_Identity_Event (New_LRBG, A.Id);
      --  3.6.5.1.4 j), 3.6.5.1.5 d)
      if not Params_Stored or else M_Loc = 1 then
         Triggers.LRBG_Passed := True;
      end if;
   end Set_LRBG;

   ---------------------------------------------------------------------
   --  Linking windows
   ---------------------------------------------------------------------

   type Window_Result_T is (Inside, Early, Late);

   --  The first and last possible locations of link E, against the SOLR
   --  along the linking (3.4.4.4.3.1, 3.4.4.4.4)
   function Window_First (E : EVC_Linking.Link_Index_T) return Dist_T
   is (if Links.Links (E).Known_Id
       then Diff (Links.Links (E).D
                    - EVC_Linking.Distance (Links, Links.Solr),
                  Links.Links (E).Locacc)
       --  repositioning: from the previous linked group on
       else EVC_Linking.Distance (Links, E - 1)
            - EVC_Linking.Distance (Links, Links.Solr))
     with Pre => E <= Links.Count;

   function Window_Last (E : EVC_Linking.Link_Index_T) return Dist_T
   is (Sum (Links.Links (E).D - EVC_Linking.Distance (Links, Links.Solr),
            Links.Links (E).Locacc))
     with Pre => E <= Links.Count;

   --  The safe antenna positions against the SOLR along the linking, at
   --  frame position X with the frame deviations Low, High
   procedure Antenna (X : Dist_T; Low, High : Length_T;
                      Min, Max : out Dist_T)
     with Post => Min <= Max
   is
      S   : constant Sense_T := Links.Sense;
      Est : constant Dist_T := Estimated (SOLR_A, S, X);
   begin
      Min := Min_Safe (Est, EVC_Location.Doubt_Over (SOLR_A, S, Low, High));
      Max := Max_Safe (Est, EVC_Location.Doubt_Under (SOLR_A, S, Low, High));
   end Antenna;

   function Check_Window (E : EVC_Linking.Link_Index_T; R : Reading_T)
     return Window_Result_T
     with Pre => E <= Links.Count
   is
      Min, Max : Dist_T;
   begin
      Antenna (R.X, R.Low, R.High, Min, Max);
      if Max < Window_First (E) then
         return Early;
      elsif Min > Window_Last (E) then
         return Late;
      else
         return Inside;
      end if;
   end Check_Window;

   --  The end of the window of link E has been reached (plus the margin
   --  of 3.16.2.3.1.1 when Margin)
   function Window_Passed (E : EVC_Linking.Link_Index_T; Margin : Boolean)
     return Boolean
   is (Min_Safe
         (Estimated (SOLR_A, Links.Sense, EVC_Odometry.Position),
          EVC_Location.Doubt_Over (SOLR_A, Links.Sense,
                                   EVC_Odometry.Low, EVC_Odometry.High))
       > (if Margin then Sum (Window_Last (E), Missed_Margin_Cm)
          else Window_Last (E)))
     with Pre => E <= Links.Count;

   --  3.4.4.4.6: stop supervising the window of the expected group
   procedure Next_Window
     with Post => Links.Count = Links.Count'Old
                  and then Links.Stored = Links.Stored'Old
   is
   begin
      if Links.Expected <= Links.Count then
         Links.Expected := Links.Expected + 1;
      end if;
   end Next_Window;

   --  3.16.2.3.1 b), 3.16.2.3.1.1: the expected groups whose windows
   --  were passed without their location reference
   procedure Supervise_Windows
   is
   begin
      for Step in 1 .. EVC_Linking.Max_Links loop
         exit when not Check_Linking or else not EVC_Linking.Checked (Links);
         declare
            E : constant EVC_Linking.Link_Index_T := Links.Expected;
            L : constant EVC_Linking.Link_T := Links.Links (E);
         begin
            exit when not Window_Passed (E, Margin => True);
            Missed_Flag := True;
            Put_Identity_Event
              (Missed_Group, (if L.Known_Id then L.Id else Unknown_Identity));
            Request_Reaction (L.Reaction, Cause_Not_Detected, E);
            Next_Window;
         end;
      end loop;
   end Supervise_Windows;

   ---------------------------------------------------------------------
   --  Geographical position (3.6.6)
   ---------------------------------------------------------------------

   --  3.6.6.7: a reference group without co-ordinate system is ignored
   procedure Anchor_Geo (A : Anchor_T)
   is
   begin
      for I in Geo_Refs'Range loop
         if Geo_Refs (I).Valid and then not Geo_Refs (I).Anchored
           and then Geo_Refs (I).Id = A.Id
         then
            if A.Orientation = Unknown then
               Geo_Refs (I).Valid := False;
            else
               Geo_Refs (I).Anchored := True;
               Geo_Refs (I).Ref := A;
            end if;
         end if;
      end loop;
   end Anchor_Geo;

   --  Packet 79 from the group A (3.6.6.3: it replaces the references
   --  not yet applicable; 3.6.6.4 b, c)
   procedure Take_Geo (P : ETCS_Track_Packets.P79.Packet_T;
                       A : Anchor_T;
                       S : Sense_T)
   is
      Scale   : constant Natural := Natural (P.Q_SCALE);
      Country : NID_C_T := A.Id.NID_C;
      N       : Natural := 0;

      procedure Put (New_Country : Boolean;
                     NID_C       : NID_C_T;
                     NID_BG      : NID_BG_T;
                     D_POSOFF    : D_POSOFF_T;
                     Q_MPOSITION : Q_MPOSITION_T;
                     M_POSITION  : M_POSITION_T)
        with Pre => Valid_Scale (Scale) and then N < Max_Geo,
             Post => N = N'Old + 1
      is
      begin
         if New_Country then
            Country := NID_C;
         end if;
         N := N + 1;
         Geo_Refs (N) :=
           (Valid    => True,
            Id       => (NID_C => Country, NID_BG => NID_BG),
            Offset   => Scaled (Natural (D_POSOFF), Scale),
            Sense    => S,
            Same     => Q_MPOSITION = 1,
            Value    => M_POSITION,
            Anchored => False,
            Ref      => (others => <>));
      end Put;
   begin
      if not Valid_Scale (Scale) then
         return;
      end if;
      Geo_Refs := (others => No_Geo_Ref);
      Put (P.Q_NEWCOUNTRY = 1, P.NID_C, P.NID_BG, P.D_POSOFF,
           P.Q_MPOSITION, P.M_POSITION);
      for K in 1 .. Natural (P.N_ITER) loop
         pragma Loop_Invariant (N = K);
         Put (P.Q_NEWCOUNTRY_List (K).Q_NEWCOUNTRY = 1,
              P.Q_NEWCOUNTRY_List (K).NID_C,
              P.Q_NEWCOUNTRY_List (K).NID_BG,
              P.Q_NEWCOUNTRY_List (K).D_POSOFF,
              P.Q_NEWCOUNTRY_List (K).Q_MPOSITION,
              P.Q_NEWCOUNTRY_List (K).M_POSITION);
      end loop;
      --  3.6.6.4 b): the group that sent the information
      Anchor_Geo (A);
   end Take_Geo;

   --  The geographical position against the reference G, m (negative
   --  below the track kilometre 0)
   function Geo_Of (G : Geo_Ref_T) return Cm_T
   is
      Km_X   : constant Dist_T := Advance (G.Ref.X, G.Sense, G.Offset);
      --  along the nominal direction of the reference group
      Nom    : constant Sense_T :=
        (if G.Ref.Orientation = Minus then Minus else Plus);
      Travel : constant Dist_T := Between (Nom, Km_X, Front_X);
   begin
      --  3.6.6.5, Figure 16
      return Cm_T (G.Value) + (if G.Same then Travel / 100
                               else -(Travel / 100));
   end Geo_Of;

   --  3.6.6.4.2, 3.6.6.9: the references that become applicable, the
   --  calculation from the applicable one
   procedure Update_Geo
   is
      V : Cm_T;
   begin
      for I in Geo_Refs'Range loop
         if Geo_Refs (I).Valid and then Geo_Refs (I).Anchored
           and then Between (Geo_Refs (I).Sense, Geo_Refs (I).Ref.X, Front_X)
                    >= Geo_Refs (I).Offset
         then
            --  3.6.6.9 a), 3.6.6.9.1: it replaces the applicable one
            Geo_Current := Geo_Refs (I);
            Geo_Refs (I).Valid := False;
         end if;
      end loop;
      if Geo_Current.Valid
        and then Geo_Current.Value = M_POSITION_No_More_Geographical_Position
      then
         --  3.6.6.9 b): told not to continue
         Geo_Current.Valid := False;
      end if;
      Geo_Valid := False;
      Geo_Value := 0;
      if Geo_Current.Valid then
         V := Geo_Of (Geo_Current);
         if V < 0 then
            --  3.6.6.9 c)
            Geo_Current.Valid := False;
         else
            Geo_Valid := True;
            Geo_Value := Natural (Cm_T'Min (V, Cm_T (Natural'Last)));
         end if;
      end if;
   end Update_Geo;

   ---------------------------------------------------------------------
   --  End of a passage
   ---------------------------------------------------------------------

   --  The group has packet 16 (repositioning) valid for T
   function Has_Repositioning (G, T : Direction_T) return Boolean
   is
   begin
      for I in 1 .. Passage.Count loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         for J in 1 .. Passage.Telegrams (I).Count loop
            if Passage.Telegrams (I).Index (J).Kind
                 = ETCS_Catalogue.Track_P16
              and then Valid_For (Passage.Telegrams (I).Index (J).Q_DIR, G, T)
            then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Has_Repositioning;

   --  The packets 5 and 79 of the accepted group A valid for T; the
   --  sense of their distances is S. The last valid one of each counts.
   procedure Take_Packets (A : Anchor_T; T : Direction_T; S : Sense_T)
   is
      R     : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
      OK    : Boolean;
      New_L : EVC_Linking.Linking_T;
      Found : Boolean := False;
   begin
      for I in 1 .. Passage.Count loop
         for J in 1 .. Passage.Telegrams (I).Count loop
            declare
               E : constant ETCS_Packet_Index.Entry_T :=
                 Passage.Telegrams (I).Index (J);
            begin
               if Valid_For (E.Q_DIR, A.Orientation, T) then
                  if E.Kind = ETCS_Catalogue.Track_P5
                    and then Accept_Linking
                  then
                     declare
                        P : ETCS_Track_Packets.P5.Packet_T;
                        L : EVC_Linking.Linking_T;
                     begin
                        ETCS_Telegram.Open_Packet
                          (Passage.Telegrams (I), J, R);
                        ETCS_Track_Packets.P5.Decode (R, P, OK);
                        if OK then
                           EVC_Linking.From_Packet (P, A.Id, S, L, OK);
                           if OK then
                              New_L := L;
                              Found := True;
                           end if;
                        end if;
                     end;
                  elsif E.Kind = ETCS_Catalogue.Track_P79 then
                     declare
                        P : ETCS_Track_Packets.P79.Packet_T;
                     begin
                        ETCS_Telegram.Open_Packet
                          (Passage.Telegrams (I), J, R);
                        ETCS_Track_Packets.P79.Decode (R, P, OK);
                        if OK then
                           Take_Geo (P, A, S);
                        end if;
                     end;
                  end if;
               end if;
            end;
         end loop;
      end loop;
      if Found then
         --  3.4.4.4.5.1: the first window whose end is not reached; the
         --  group is the reference of the linking and the SOLR
         --  (3.6.4.2.2 a)
         Links := New_L;
         Set_SOLR (A, 0);
         for Step in 1 .. EVC_Linking.Max_Links loop
            exit when not EVC_Linking.Checked (Links)
              or else not Window_Passed (Links.Expected, Margin => False);
            Next_Window;
         end loop;
      end if;
   end Take_Packets;

   --  The group A was taken into account: its origin for the stored
   --  information, referred to the SOLR (3.6.4.2.5: information of a
   --  group that is not the SOLR is relocated when it is evaluated), and
   --  the telegrams of its passage
   procedure Record_Taken (A : Anchor_T; T : Direction_T; S : Sense_T)
     with Pre => Passage.Count >= 1,
          Post => SOLR_A = SOLR_A'Old and then LRBG_A = LRBG_A'Old
   is
      I : EVC_Origins.Count_T;
   begin
      if Taken_N = Max_Taken
        or else Taken_Tel_N + Passage.Count > Max_Taken_Telegrams
      then
         return;
      end if;
      EVC_Origins.Allocate (A, S, I);
      if I /= 0 and then SOLR_A.Valid and then SOLR_A.Id /= A.Id then
         declare
            O : EVC_Origins.Origin_T := EVC_Origins.Get (I);
         begin
            Relocate_Item (O.Est);
            Relocate_Item (O.Min);
            Relocate_Item (O.Max);
            EVC_Origins.Put (I, O);
         end;
      end if;
      Taken_N := Taken_N + 1;
      Taken_List (Taken_N) :=
        (Group    => A,
         T        => T,
         S        => S,
         Origin   => I,
         First    => Taken_Tel_N + 1,
         Count    => Passage.Count,
         Start_Ms => Passage_Ms);
      for K in 1 .. Passage.Count loop
         pragma Loop_Invariant (Taken_Tel_N + Passage.Count - K + 1
                                <= Max_Taken_Telegrams);
         Taken_Tel_N := Taken_Tel_N + 1;
         Taken_Tels (Taken_Tel_N) := Passage.Telegrams (K);
      end loop;
   end Record_Taken;

   --  The passage is over: accept or reject its group (see the spec)
   procedure Evaluate (Mode : Mode_T)
     with Pre => Passage.Open and then Passage.Count >= 1,
          Post => not Passage.Open
   is
      G           : constant Geometry_T := Geometry (Passage);
      Id          : constant Identity_T := Passage.Id;
      Taken      : Boolean := False;
      Compliant   : Boolean := False;
      To_SOLR     : Boolean := False;
      Orient_G    : Direction_T := G.Orientation;
      Link_Index  : EVC_Linking.Link_Count_T := 0;
      Locacc      : Length_T := Default_Locacc_Cm;
      --  the direction of the train for the validity of the packets
      --  (3.6.3.1.3, 3.6.3.1.3.1) and the sense of their distances
      T           : Direction_T;
      S           : Sense_T;

      --  The expected link E was met inside its window
      procedure Accept_Link (E : EVC_Linking.Link_Index_T)
        with Pre => E <= Links.Count
      is
         L : constant EVC_Linking.Link_T := Links.Links (E);
      begin
         Taken := True;
         Compliant := True;
         To_SOLR := True;
         Link_Index := E;
         Locacc := L.Locacc;
         if Orient_G = Unknown then
            --  3.4.2.3.2.2: the linking assigns the co-ordinate system
            Orient_G := To_Direction
              (if L.Nominal then Links.Sense else Opposite (Links.Sense));
         end if;
         Next_Window;
      end Accept_Link;

      --  The group against the expected link E (known identity)
      procedure Against (E : EVC_Linking.Link_Index_T)
        with Pre => E <= Links.Count
      is
         L : constant EVC_Linking.Link_T := Links.Links (E);
      begin
         case Check_Window (E, G.Reference) is
            when Inside =>
               if G.Orientation /= Unknown
                 and then Same (G.Orientation, Links.Sense) /= L.Nominal
               then
                  --  3.4.4.4.7: rejected, and the train tripped
                  Request_Reaction (0, Cause_Wrong_Direction, E);
                  Next_Window;
               else
                  Accept_Link (E);
               end if;
            when Early =>
               Request_Reaction (L.Reaction, Cause_Early, E);
               Next_Window;
            when Late =>
               Request_Reaction (L.Reaction, Cause_Not_Detected, E);
               Next_Window;
         end case;
      end Against;

   begin
      Passage.Open := False;
      if not G.Has_Reference then
         --  the group cannot be located (the consistency of its message
         --  is phase E6); its window, if any, runs on
         return;
      end if;

      if Mode in M_SL | M_PS | M_SH then
         T := G.Crossing;
      else
         T := (if Orient_Known then To_Direction (Orient) else Unknown);
      end if;
      S := (if T = Minus then Minus
            elsif T = Plus then Plus
            else Orient);

      if not Check_Linking or else not EVC_Linking.Checked (Links) then
         --  3.4.4.5.1, 3.6.4.2.2 b), 3.6.2.2.2 a) second bullet
         Taken := True;
         Compliant := Passage.Linked;
         To_SOLR := True;
         if Links.Stored then
            Link_Index := EVC_Linking.Find (Links, Id, 1);
            if Link_Index /= 0 then
               --  3.6.4.1.3: announced by the linking stored
               Locacc := Links.Links (Link_Index).Locacc;
               if Orient_G = Unknown then
                  Orient_G := To_Direction
                    (if Links.Links (Link_Index).Nominal then Links.Sense
                     else Opposite (Links.Sense));
               end if;
            end if;
         end if;
      elsif not Passage.Linked then
         --  3.4.4.4.2.2: taken into account, an ORBG
         Taken := True;
      elsif SOLR_A.Valid and then Id = SOLR_A.Id then
         --  the SOLR read again: its window is no longer supervised
         null;
      else
         declare
            E : constant EVC_Linking.Link_Index_T := Links.Expected;
            L : constant EVC_Linking.Link_T := Links.Links (E);
         begin
            if not L.Known_Id then
               --  3.4.4.4.2.1
               if G.Orientation /= Unknown
                 and then Has_Repositioning (G.Orientation, T)
                 and then Same (G.Orientation, Links.Sense) = L.Nominal
               then
                  case Check_Window (E, G.Reference) is
                     when Inside =>
                        Accept_Link (E);
                     when Early =>
                        Request_Reaction (L.Reaction, Cause_Early, E);
                        Next_Window;
                     when Late =>
                        Request_Reaction (L.Reaction, Cause_Not_Detected, E);
                        Next_Window;
                  end case;
               else
                  Unexpected_Flag := True;
                  Put_Identity_Event (Unexpected_Group, Id);
               end if;
            elsif L.Id = Id then
               Against (E);
            elsif E < Links.Count
              and then Links.Links (E + 1).Known_Id
              and then Links.Links (E + 1).Id = Id
            then
               --  3.16.2.3.1 c), 3.4.4.4.6.1: the next one
               Request_Reaction (L.Reaction, Cause_Other_Group, E);
               Next_Window;
               Against (E + 1);
            elsif EVC_Linking.Find (Links, Id, E + 1) /= 0 then
               --  a group announced later still: c) for the expected one,
               --  and this one is not expected (3.4.4.4.3.2)
               Request_Reaction (L.Reaction, Cause_Other_Group, E);
               Next_Window;
            elsif EVC_Linking.Find (Links, Id, 1) /= 0 then
               --  announced before: its window is no longer supervised
               null;
            else
               --  3.4.4.4.2: not in the linking information
               Unexpected_Flag := True;
               Put_Identity_Event (Unexpected_Group, Id);
            end if;
         end;
      end if;

      if not Taken then
         return;
      end if;

      if Seq_Counter < Natural'Last then
         Seq_Counter := Seq_Counter + 1;
      end if;
      declare
         A : constant Anchor_T :=
           (Valid       => True,
            Id          => Id,
            X           => G.Reference.X,
            Low         => G.Reference.Low,
            High        => G.Reference.High,
            Locacc      => Locacc,
            Orientation => Orient_G,
            Crossing    => G.Crossing,
            Linked      => Passage.Linked,
            Seq         => Seq_Counter);
      begin
         if To_SOLR then
            Set_SOLR (A, Link_Index);
         end if;
         if Compliant then
            Set_LRBG (A);
         else
            Unlinked (Unlinked_Next) := A;
            Unlinked_Next := (if Unlinked_Next = 1 then 2 else 1);
         end if;
         --  3.6.1.4
         Pos_Status := Valid;
         --  3.6.6.4.2: a geographical reference group detected
         Anchor_Geo (A);
         Take_Packets (A, T, S);
         Record_Taken (A, T, S);
      end;
   end Evaluate;

   ---------------------------------------------------------------------
   --  Report triggers (3.6.5.1.4, 3.6.5.1.5)
   ---------------------------------------------------------------------

   procedure Evaluate_Triggers (Mode : Mode_T; Level : Level_T)
   is
      Standstill : constant Boolean := EVC_Odometry.Standstill;
   begin
      if Standstill and then not Last_Standstill then
         Triggers.Standstill_Reached := True;
      elsif Last_Standstill and then not Standstill then
         Triggers.Standstill_Left := True;
      end if;
      Last_Standstill := Standstill;
      if Mode_Seen then
         Triggers.Mode_Changed := Mode /= Last_Mode;
         Triggers.Level_Changed := Level /= Last_Level;
      end if;
      Last_Mode := Mode;
      Last_Level := Level;
      Mode_Seen := True;
      if Immediate_Pending then
         Triggers.Immediate := True;
         Immediate_Pending := False;
      end if;

      --  c): the max safe front end, the min safe rear end passed
      for I in Locations'Range loop
         if Locations (I).Valid then
            declare
               It   : constant Item_T := Locations (I);
               Est  : constant Dist_T :=
                 Estimated (It.Ref, It.Sense, Front_X);
               Low  : constant Length_T := EVC_Odometry.Low;
               High : constant Length_T := EVC_Odometry.High;
            begin
               if It.Kind = Max_Item then
                  if Max_Safe (Est, EVC_Location.Doubt_Under
                                      (It.Ref, It.Sense, Low, High))
                     >= It.D
                  then
                     Triggers.Location_Passed := True;
                     Locations (I).Valid := False;
                  end if;
               elsif Length_Known
                 and then Diff (Min_Safe (Est, EVC_Location.Doubt_Over
                                                 (It.Ref, It.Sense,
                                                  Low, High)),
                                Train_Length) >= It.D
               then
                  Triggers.Location_Passed := True;
                  Locations (I).Valid := False;
               end if;
            end;
         end if;
      end loop;
   end Evaluate_Triggers;

   procedure Evaluate_Periods (Now_Ms : Unsigned_64)
   is
   begin
      --  a) and b)
      if T_Cycloc_Ms > 0 and then Now_Ms - Last_Report_Ms >= T_Cycloc_Ms
      then
         Triggers.Periodic_Time := True;
         Last_Report_Ms := Now_Ms;
      end if;
      if D_Cycloc > 0
        and then Growth (EVC_Odometry.Travelled, Last_Report_Travel)
                 >= D_Cycloc
      then
         Triggers.Periodic_Distance := True;
         Last_Report_Travel := EVC_Odometry.Travelled;
      end if;
   end Evaluate_Periods;

   ---------------------------------------------------------------------
   --  For the stored information
   ---------------------------------------------------------------------

   function Taken_Count return Natural is (Taken_N)
     with Refined_Global => Taken_N;

   function Taken (I : Positive) return Taken_T is (Taken_List (I))
     with Refined_Global => (Input => Taken_List, Proof_In => Taken_N);

   function Taken_Packet_Count (J : Positive) return Natural is
     (if J <= Taken_Tel_N then Taken_Tels (J).Count else 0)
     with Refined_Global => (Taken_Tels, Taken_Tel_N);

   function Taken_Entry (J, P : Positive) return ETCS_Packet_Index.Entry_T
   is (Taken_Tels (J).Index (P))
     with Refined_Global => (Input => Taken_Tels, Proof_In => Taken_Tel_N);

   procedure Open_Taken_Packet (J, P : Positive;
                                R    : in out ETCS_Bits.Reader)
     with Refined_Global => (Input => Taken_Tels, Proof_In => Taken_Tel_N)
   is
   begin
      ETCS_Telegram.Open_Packet (Taken_Tels (J), P, R);
   end Open_Taken_Packet;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   procedure Clear
   is
   begin
      EVC_Odometry.Clear;
      Antenna_Offset := (Plus  => EVC_Config.Default.Antenna_To_Cab_A,
                         Minus => EVC_Config.Default.Antenna_To_Cab_B);
      Orient := Plus;
      Orient_Known := False;
      Cab_In := No_Cab;
      Pos_Status := Unknown;
      Reported_Status := Unknown;
      LRBG_A := (others => <>);
      Prev_A := (others => <>);
      SOLR_A := (others => <>);
      Recent := (others => No_Recent);
      Recent_Next := 1;
      Unlinked := (others => No_Anchor);
      Unlinked_Next := 1;
      Seq_Counter := 0;
      Links := (others => <>);
      Accept_Linking := True;
      Check_Linking := True;
      Passage := (others => <>);
      Passage.Open := False;
      Pending := (others => ETCS_Telegram.No_Telegram);
      Pending_Stamp := (others => 0);
      Pending_N := 0;
      Events := (others => No_Event);
      Event_N := 0;
      Reaction_Flag := False;
      Reaction_Value := 2;
      Unexpected_Flag := False;
      Missed_Flag := False;
      Odo_Reported := 0;
      Cold_Reported := False;
      Geo_Refs := (others => No_Geo_Ref);
      Geo_Current := (others => <>);
      Geo_Value := 0;
      Geo_Valid := False;
      Params_Stored := False;
      T_Cycloc_Ms := 0;
      D_Cycloc := 0;
      M_Loc := 2;
      Locations := (others => No_Item);
      Last_Report_Ms := 0;
      Now_Seen := 0;
      Last_Report_Travel := 0;
      Immediate_Pending := False;
      Triggers := No_Triggers;
      Last_Standstill := True;
      Last_Mode := M_NP;
      Last_Level := L0;
      Mode_Seen := False;
      Train_Length := 0;
      Length_Known := False;
      Taken_List := (others => No_Taken);
      Taken_N := 0;
      Taken_Tels := (others => ETCS_Telegram.No_Telegram);
      Taken_Tel_N := 0;
      Passage_Ms := 0;
      Previous_Ms := 0;
   end Clear;

   procedure Receive_Telegram (T : ETCS_Telegram.Telegram_T;
                               Stamp : Unsigned_32)
   is
   begin
      if Pending_N < Max_Pending then
         Pending_N := Pending_N + 1;
         Pending (Pending_N) := T;
         Pending_Stamp (Pending_N) := Stamp;
      end if;
   end Receive_Telegram;

   ------------
   -- Update --
   ------------

   procedure Update (Cab_A_Active : Boolean;
                     Cab_B_Active : Boolean;
                     Sampled      : Boolean;
                     Sample       : Odometer_Sample_T;
                     Mode         : Mode_T;
                     Level        : Level_T;
                     Now_Ms       : Unsigned_64)
   is
      New_Orient : Sense_T;
      Odo_Code   : Unsigned_8;
      Low_0      : constant Length_T := EVC_Odometry.Low with Ghost;
      High_0     : constant Length_T := EVC_Odometry.High with Ghost;
   begin
      Previous_Ms := Now_Seen;
      Now_Seen := Now_Ms;
      Taken_N := 0;
      Taken_Tel_N := 0;
      Event_N := 0;
      Reaction_Flag := False;
      Reaction_Value := 2;
      Unexpected_Flag := False;
      Missed_Flag := False;
      Triggers := No_Triggers;

      --  1. 3.6.1.5 (SUBSET-034 2.5.1: one input per cab)
      if Cab_A_Active /= Cab_B_Active then
         New_Orient := (if Cab_A_Active then Plus else Minus);
         Cab_In := (if Cab_A_Active then Cab_A else Cab_B);
         if Orient_Known and then New_Orient /= Orient then
            --  3.6.6.4.3: the announced references are deleted
            Geo_Refs := (others => No_Geo_Ref);
         end if;
         Orient := New_Orient;
         Orient_Known := True;
      else
         Cab_In := No_Cab;
      end if;

      --  2. the telegrams of the cycle, placed on the frame as it was
      for I in 1 .. Pending_N loop
         pragma Loop_Invariant
           (EVC_Odometry.Low = Low_0 and then EVC_Odometry.High = High_0
            and then Orient = Orient'Loop_Entry
            and then Orient_Known = Orient_Known'Loop_Entry
            and then Cab_In = Cab_In'Loop_Entry);
         declare
            T : ETCS_Telegram.Telegram_T renames Pending (I);
            R : constant Reading_T :=
              (N_PIG  => T.Header.N_PIG,
               M_DUP  => T.Header.M_DUP,
               X      => EVC_Odometry.To_Frame (Pending_Stamp (I)),
               Low    => EVC_Odometry.Low,
               High   => EVC_Odometry.High,
               Motion => EVC_Odometry.Last_Direction);
         begin
            if Passage.Open and then Passage.Id /= Identity (T.Header) then
               --  3.16.2.2.2 c): a balise of another group
               if Passage.Count >= 1 then
                  Evaluate (Mode);
               end if;
               Passage.Open := False;
            end if;
            if not Passage.Open then
               Start (Passage, T, R);
               Passage_Ms := Previous_Ms;
            elsif Passage.Count < Max_Balises
              and then not Has (Passage, R.N_PIG)
            then
               Add (Passage, T, R);
            end if;
            if Passage.Open and then Passage.Count >= 1
              and then Complete (Passage)
            then
               Evaluate (Mode);
            end if;
         end;
      end loop;
      Pending_N := 0;

      --  3. the odometer
      if Sampled then
         EVC_Odometry.Apply (Sample);
      end if;
      Odo_Code := (if EVC_Odometry.Safety_Exceeded then 2
                   elsif EVC_Odometry.Impaired then 1 else 0);
      if Odo_Code /= Odo_Reported then
         Put_Event (Odometer_Accuracy, Odo_Code, 0, 0);
         Odo_Reported := Odo_Code;
      end if;
      --  3.15.8: a cold movement detected is recorded once (whether the
      --  information is available is EVC_Odometry.Cold; its use for the
      --  stored information, 4.11, is phase E4)
      if not Cold_Reported
        and then EVC_Odometry.Cold /= EVC_Odometry.Cold_Unknown
      then
         if EVC_Odometry.Cold = EVC_Odometry.Cold_Movement then
            Put_Event (Cold_Movement, 1, 0, 0);
         end if;
         Cold_Reported := True;
      end if;

      --  4. 3.16.2.2.2 a): the train went on beyond the group
      if Passage.Open and then Passage.Count >= 1
        and then Abs_Dist (Diff (EVC_Odometry.Position,
                                 Geometry (Passage).Last_X))
                 > Group_End_Cm
      then
         Evaluate (Mode);
      end if;

      --  5. the window of the expected group
      if not Passage.Open then
         Supervise_Windows;
      end if;

      --  6.
      Update_Geo;
      Evaluate_Triggers (Mode, Level);
      Evaluate_Periods (Now_Ms);
      if Pos_Status /= Reported_Status then
         Put_Event (Position_Status, Status_T'Pos (Pos_Status), 0, 0);
         Reported_Status := Pos_Status;
      end if;
      --  3.6.4.1.2: the frame deviations only grew in this cycle
      pragma Assert (EVC_Odometry.Low >= Low_0
                     and then EVC_Odometry.High >= High_0);
      Lemma_Doubts_Grow
        (LRBG_A, Orient, Low_0, High_0,
         EVC_Odometry.Low, EVC_Odometry.High);
   end Update;

   -----------------
   -- Set_Antenna --
   -----------------

   procedure Set_Antenna (To_Cab_A, To_Cab_B : EVC_Config.Antenna_Offset_T)
   is
   begin
      Antenna_Offset := (Plus => To_Cab_A, Minus => To_Cab_B);
   end Set_Antenna;

   ----------------------
   -- Set_Train_Length --
   ----------------------

   procedure Set_Train_Length (Length : Length_T)
   is
   begin
      Train_Length := Length;
      Length_Known := True;
   end Set_Train_Length;

   ---------------------------
   -- Set_Report_Parameters --
   ---------------------------

   procedure Set_Report_Parameters
     (P   : ETCS_Track_Packets.P58.Packet_T;
      Ref : Identity_T;
      OK  : out Boolean)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      A     : Anchor_T;
      D     : Length_T := 0;
   begin
      OK := False;
      if not Valid_Scale (Scale) or else P.M_LOC > 2 then
         return;
      end if;
      if LRBG_A.Valid and then LRBG_A.Id = Ref then
         A := LRBG_A;
      elsif SOLR_A.Valid and then SOLR_A.Id = Ref then
         A := SOLR_A;
      else
         --  3.6.2.2.2 c): one of the last LRBGs; its last passage
         declare
            Found : constant Natural := Latest (Ref);
         begin
            if Found = 0 then
               return;
            end if;
            A := Recent (Found).A;
         end;
      end if;
      OK := True;
      Params_Stored := True;
      T_Cycloc_Ms := (if P.T_CYCLOC = T_CYCLOC_Infinite then 0
                      else Unsigned_64 (P.T_CYCLOC) * 1000);
      D_Cycloc := (if P.D_CYCLOC = D_CYCLOC_The_Train_Has_Not then 0
                   else Scaled (Natural (P.D_CYCLOC), Scale));
      M_Loc := P.M_LOC;
      Immediate_Pending := P.M_LOC = 0;
      Last_Report_Ms := Now_Seen;
      Last_Report_Travel := EVC_Odometry.Travelled;
      Locations := (others => No_Item);
      for K in 1 .. Natural (P.N_ITER) loop
         pragma Loop_Invariant (D <= Cm_T (K - 1) * 32_767 * 1000);
         D := D + Scaled (Natural (P.D_LOC_List (K).D_LOC), Scale);
         --  Table 2a: "min" for the min safe rear end, "max" for the max
         --  safe front end
         Locations (K) :=
           (Valid        => True,
            Kind         => (if P.D_LOC_List (K).Q_LGTLOC = 1 then Max_Item
                             else Min_Item),
            Ref          => A,
            Sense        => Orient,
            D            => D,
            Last_C       => False,
            Last_C_Later => False);
         --  3.6.4.2.5: referred to the SOLR at once
         Relocate_Item (Locations (K));
      end loop;
   end Set_Report_Parameters;

   -----------------
   -- Report_Sent --
   -----------------

   procedure Report_Sent (Now_Ms : Unsigned_64)
   is
   begin
      Last_Report_Ms := Now_Ms;
      Last_Report_Travel := EVC_Odometry.Travelled;
   end Report_Sent;

   ------------------------------
   -- Assign_Coordinate_System --
   ------------------------------

   procedure Assign_Coordinate_System (Id      : Identity_T;
                                       Nominal : Boolean;
                                       OK      : out Boolean)
   is
      Found : Natural := 0;
      G     : Direction_T;
   begin
      OK := False;
      for I in Recent_Index_T loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         if Recent (I).A.Valid and then Recent (I).A.Id = Id
           and then Recent (I).Ambiguous
         then
            --  3.4.2.3.3.8
            return;
         end if;
      end loop;
      --  the direction reference of the last report based on the group
      --  (3.4.2.3.3.6)
      Found := Latest (Id);
      if Found = 0 or else Recent (Found).Dref = Unknown then
         return;
      end if;
      G := (if Nominal then Recent (Found).Dref
            elsif Recent (Found).Dref = Plus then Minus
            else Plus);
      --  the orientation is the group's, every passage kept of it
      for I in Recent_Index_T loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         if Recent (I).A.Valid and then Recent (I).A.Id = Id then
            Recent (I).A.Orientation := G;
         end if;
      end loop;
      if LRBG_A.Valid and then LRBG_A.Id = Id then
         LRBG_A.Orientation := G;
      end if;
      if SOLR_A.Valid and then SOLR_A.Id = Id then
         SOLR_A.Orientation := G;
      end if;
      OK := True;
   end Assign_Coordinate_System;

   ----------------
   -- Invalidate --
   ----------------

   procedure Invalidate
   is
   begin
      if Pos_Status /= Unknown then
         Pos_Status := Invalid;
      end if;
   end Invalidate;

   ---------------------
   -- Delete_Position --
   ---------------------

   procedure Delete_Position
   is
   begin
      Pos_Status := Unknown;
      LRBG_A := (others => <>);
      Prev_A := (others => <>);
      SOLR_A := (others => <>);
      Recent := (others => No_Recent);
      Unlinked := (others => No_Anchor);
   end Delete_Position;

   -------------------------
   -- Set_Linking_Context --
   -------------------------

   procedure Set_Linking_Context (Accept_Info, Check : Boolean) is
   begin
      Accept_Linking := Accept_Info;
      Check_Linking := Check;
   end Set_Linking_Context;

   --------------------
   -- Delete_Linking --
   --------------------

   procedure Delete_Linking is
   begin
      Links := (others => <>);
   end Delete_Linking;

   ----------------
   -- Delete_Geo --
   ----------------

   procedure Delete_Geo
   is
   begin
      Geo_Refs := (others => No_Geo_Ref);
      Geo_Current := (others => <>);
      Geo_Value := 0;
      Geo_Valid := False;
   end Delete_Geo;

   ---------------------------------------------------------------------
   --  Position report (3.6.5.1.2)
   ---------------------------------------------------------------------

   --  The resolution (Q_SCALE) at which the three distances fit, and a
   --  distance at it: rounded down for the estimated distance, up for
   --  the confidence interval
   function Scale_For (D, Over, Under : Length_T) return Natural is
     (if D <= 327_660 and then Over <= 327_660 and then Under <= 327_660
      then 0
      elsif D <= 3_276_600 and then Over <= 3_276_600
        and then Under <= 3_276_600
      then 1
      else 2);

   function Unit (Q_SCALE : Natural) return Cm_T is
     (case Q_SCALE is when 0 => 10, when 1 => 100, when others => 1000);

   function Down (D : Length_T; Q_SCALE : Natural) return Natural is
     (Natural (Cm_T'Min (D / Unit (Q_SCALE), 32_767)));

   function Up (D : Length_T; Q_SCALE : Natural) return Natural is
     (Natural (Cm_T'Min ((D + Unit (Q_SCALE) - 1) / Unit (Q_SCALE),
                         32_767)));

   --  7.5.1.? M_MODE of the modes, M_LEVEL of the levels
   function M_Mode_Of (Mode : Mode_T) return M_MODE_T is
     (case Mode is
         when M_FS => 0,  when M_OS => 1,  when M_SR => 2,  when M_SH => 3,
         when M_UN => 4,  when M_SL => 5,  when M_SB | M_NP => 6,
         when M_TR => 7,  when M_PT => 8,  when M_SF => 9,  when M_IS => 10,
         when M_NL => 11, when M_LS => 12, when M_SN => 13, when M_RV => 14,
         when M_PS => 15, when M_AD => 16, when M_SM => 17);

   function M_Level_Of (Level : Level_T) return M_LEVEL_T is
     (case Level is
         when L0 => 0, when NTC => 1, when L1 => 2, when L2 => 3);

   --  V_TRAIN (7.5.1.172): 5 km/h steps, 127 at standstill
   function V_Train_Of return V_TRAIN_T is
     (if EVC_Odometry.Standstill then V_TRAIN_Standstill
      else V_TRAIN_T (Natural'Min
                        (Natural (EVC_Odometry.Speed) * 36 / 5000, 120)))
     with Global => EVC_Odometry.State;

   --  Q_ values of a direction D against the reference direction G
   function Q_Of (D, G : Direction_T) return Natural is
     (if D = Unknown or else G = Unknown then 2
      elsif D = G then 1
      else 0);

   --  The common part of the two reports, against the direction
   --  reference G (the LRBG orientation, or for packet 1 the direction
   --  from the previous LRBG)
   procedure Fill (G         : Direction_T;
                   Q_SCALE   : out Q_SCALE_T;
                   D_LRBG    : out D_LRBG_T;
                   Q_DIRLRBG : out Q_DIRLRBG_T;
                   Q_DLRBG   : out Q_DLRBG_T;
                   Over      : out L_DOUBTOVER_T;
                   Under     : out L_DOUBTUNDER_T;
                   Q_DIRTRAIN : out Q_DIRTRAIN_T)
   is
      Est : constant Dist_T := Estimated_Front;
      O   : constant Length_T := Doubt_Over;
      U   : constant Length_T := Doubt_Under;
      Q   : constant Natural := Scale_For (Abs_Dist (Est), O, U);
      --  the estimated front end on the nominal side of G
      Side : constant Direction_T :=
        (if Est >= 0 then To_Direction (Orient)
         else To_Direction (Opposite (Orient)));
   begin
      Q_SCALE := Q_SCALE_T (Q);
      D_LRBG := D_LRBG_T (Down (Abs_Dist (Est), Q));
      Over := L_DOUBTOVER_T (Up (O, Q));
      Under := L_DOUBTUNDER_T (Up (U, Q));
      Q_DIRLRBG := Q_DIRLRBG_T
        (Q_Of ((if Orient_Known then To_Direction (Orient) else Unknown), G));
      Q_DLRBG := Q_DLRBG_T (Q_Of (Side, G));
      Q_DIRTRAIN := Q_DIRTRAIN_T (Q_Of (EVC_Odometry.Last_Direction, G));
   end Fill;

   function Position_Report (Mode : Mode_T; Level : Level_T)
     return ETCS_Train_Packets.P0.Packet_T
   is
      P : ETCS_Train_Packets.P0.Packet_T;
   begin
      P.M_MODE := M_Mode_Of (Mode);
      P.M_LEVEL := M_Level_Of (Level);
      P.Has_NID_NTC := Level = NTC;
      P.V_TRAIN := V_Train_Of;
      P.Q_INTEGRITY := 0;
      if not LRBG_A.Valid then
         --  3.6.2.2.2.1: LRBG "unknown"
         P.Q_SCALE := 1;
         P.NID_C := 0;
         P.NID_BG := Unknown_Identity.NID_BG;
         P.D_LRBG := D_LRBG_Unknown_Or_Greater_Than;
         P.Q_DIRLRBG := 2;
         P.Q_DLRBG := 2;
         P.L_DOUBTOVER := L_DOUBTOVER_Unknown_Or_Greater_Than;
         P.L_DOUBTUNDER := L_DOUBTUNDER_Unknown_Or_Greater_Than;
         P.Q_DIRTRAIN := 2;
      else
         P.NID_C := LRBG_A.Id.NID_C;
         P.NID_BG := LRBG_A.Id.NID_BG;
         Fill (LRBG_A.Orientation, P.Q_SCALE, P.D_LRBG, P.Q_DIRLRBG,
               P.Q_DLRBG, P.L_DOUBTOVER, P.L_DOUBTUNDER, P.Q_DIRTRAIN);
      end if;
      return P;
   end Position_Report;

   function Position_Report_2 (Mode : Mode_T; Level : Level_T)
     return ETCS_Train_Packets.P1.Packet_T
   is
      P : ETCS_Train_Packets.P1.Packet_T;
      --  3.4.2.3.3.2: the direction reference, from the previous LRBG
      --  towards the LRBG; 3.4.2.3.3.3: unknown without previous LRBG
      Dref : constant Direction_T :=
        (if not Prev_A.Valid or else Prev_A.X = LRBG_A.X then Unknown
         elsif LRBG_A.X > Prev_A.X then Plus
         else Minus);
   begin
      P.M_MODE := M_Mode_Of (Mode);
      P.M_LEVEL := M_Level_Of (Level);
      P.Has_NID_NTC := Level = NTC;
      P.V_TRAIN := V_Train_Of;
      P.Q_INTEGRITY := 0;
      P.NID_C := LRBG_A.Id.NID_C;
      P.NID_BG := (if LRBG_A.Valid then LRBG_A.Id.NID_BG
                   else Unknown_Identity.NID_BG);
      P.NID_C_PRVLRBG := (if Prev_A.Valid then Prev_A.Id.NID_C else 0);
      P.NID_BG_PRVLRBG := (if Prev_A.Valid then Prev_A.Id.NID_BG
                           else Unknown_Identity.NID_BG);
      Fill (Dref, P.Q_SCALE, P.D_LRBG, P.Q_DIRLRBG, P.Q_DLRBG,
            P.L_DOUBTOVER, P.L_DOUBTUNDER, P.Q_DIRTRAIN);
      return P;
   end Position_Report_2;

end EVC_Position;
