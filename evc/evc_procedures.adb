--  ETCS on-board (EVC)
--  The procedures of chapter 5 of the second half of phase E4,
--  implementation.

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Packet_Index;
with ETCS_Track_Packets.P12;
with ETCS_Track_Packets.P49;
with ETCS_Track_Packets.P132;
with ETCS_Track_Packets.P135;
with ETCS_Track_Packets.P137;
with ETCS_Track_Packets.P138;
with ETCS_Track_Packets.P139;
with ETCS_Variables;         use ETCS_Variables;
with EVC_Balise_Groups;      use EVC_Balise_Groups;
with EVC_DMI_Port;
with EVC_Location;           use EVC_Location;
with EVC_Profiles;           use EVC_Profiles;

package body EVC_Procedures
  with SPARK_Mode => On,
       Refined_State =>
         (State => (Conds, Pending, Reason, Version_Seen, Ctx,
                    Orientation_Now, Ovr, Ovr_Since, Ovr_Run, Ovr_Last,
                    Ovr_Selected_Now, Ovr_For_Trips, Ovr_In_SR, Former,
                    Former_X,
                    Former_S,
                    Former_Passed, Ack_On, Ack_M, Ack_After, Ack_Since,
                    Ack_SB, Ack_V, Acked_Now, Acked_M, Profile_Info,
                    Use_V, PT_Start, PT_Sense, PT_Over, PT_SB,
                    Stop_On_Desk, SH_List_Known, SH_List_N, SH_List,
                    Now_Flags, Rev, Rev_Possible, RV_Over,
                    RV_EB, BMM_On, BMM_From, Link_SB, Demand, Demand_Sent,
                    Status_N, Status_List, Event_N, Events,
                    TD_Step, TD_Then_Revalidate, TD_Revalidate,
                    TD_Moving_Due, SH_Profile_Seen))
is

   ---------------------------------------------------------------------
   --  Constants
   ---------------------------------------------------------------------

   --  A.3.1: the driver acknowledgement time of the level and mode
   --  transitions (T_ACK)
   T_Ack_Ms : constant := 5_000;

   --  A.3.1: the distance of metal immunity set by procedure in level 1
   --  or 2 (5.22.5.1 a)
   BMM_Distance_Cm : constant := 30_000;

   --  The catalogue of the system status messages (dmi_protocol.ads,
   --  MSG_SYSTEM_STATUS)
   SS_Balise_Read_Error_Brake       : constant :=
     EVC_DMI_Port.SS_Balise_Read_Error_Brake;
   SS_Balise_Read_Error_Trip        : constant :=
     EVC_DMI_Port.SS_Balise_Read_Error_Trip;
   SS_Trackside_Not_Compatible_Trip : constant :=
     EVC_DMI_Port.SS_Trackside_Not_Compatible_Trip;
   SS_Unauthorized_Passing          : constant :=
     EVC_DMI_Port.SS_Unauthorized_Passing;
   SS_No_MA_Level_Transition        : constant :=
     EVC_DMI_Port.SS_No_MA_Level_Transition;
   SS_SR_Distance_Exceeded          : constant :=
     EVC_DMI_Port.SS_SR_Distance_Exceeded;
   SS_SH_Stop_Order                 : constant :=
     EVC_DMI_Port.SS_SH_Stop_Order;
   SS_SR_Stop_Order                 : constant :=
     EVC_DMI_Port.SS_SR_Stop_Order;
   SS_RV_Distance_Exceeded          : constant :=
     EVC_DMI_Port.SS_RV_Distance_Exceeded;
   SS_PT_Distance_Exceeded          : constant :=
     EVC_DMI_Port.SS_PT_Distance_Exceeded;
   SS_No_Track_Description          : constant :=
     EVC_DMI_Port.SS_No_Track_Description;
   SS_Train_Data_Changed            : constant :=
     EVC_DMI_Port.SS_Train_Data_Changed;
   SS_Train_Data_Changed_Brake      : constant :=
     EVC_DMI_Port.SS_Train_Data_Changed_Brake;

   --  4.4.13.1.3: the system status message that indicates the reason
   --  of the trip (DMI Table 68)
   function Trip_Entry (R : Trip_Reason_T) return Natural is
     (case R is
         when No_Trip                       => 0,
         when EOA_Passed | Trip_Order | Former_EOA_Passed =>
            SS_Unauthorized_Passing,
         when Linking_Error | Wrong_Direction => SS_Balise_Read_Error_Trip,
         when SH_Stop_Order | SH_Balise_Not_Listed => SS_SH_Stop_Order,
         --  [36]: the DMI entry of "stop if in SR" (a decision: Table 68
         --  of the DMI has no entry of its own for it)
         when SR_Stop_Order | SR_Balise_Not_Listed => SS_SR_Stop_Order,
         when Version_Not_Supported         =>
            SS_Trackside_Not_Compatible_Trip,
         when No_Track_Description          => SS_No_Track_Description,
         when SR_Distance_Passed            => SS_SR_Distance_Exceeded,
         when No_MA_Level_Switch            => SS_No_MA_Level_Transition,
         when Communication_Lost            =>
            EVC_DMI_Port.SS_Communication_Error_Trip);

   --  The reason of the trip of a condition of 4.6.3 (No_Trip for one
   --  that is not a trip condition of this unit)
   function Reason_Of (C : Natural) return Trip_Reason_T is
     (case C is
         when 12 | 16  => EOA_Passed,
         when 18       => Trip_Order,
         when 43       => Former_EOA_Passed,
         when 17       => Linking_Error,
         when 66       => Wrong_Direction,
         when 49       => SH_Stop_Order,
         when 52       => SH_Balise_Not_Listed,
         when 54       => SR_Stop_Order,
         when 65       => Version_Not_Supported,
         when 69       => No_Track_Description,
         when 42       => SR_Distance_Passed,
         when 39 | 67  => No_MA_Level_Switch,
         when 41       => Communication_Lost,
         when 36       => SR_Balise_Not_Listed,
         when others   => No_Trip);

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   type Conds_T is array (Condition_T) of Boolean;
   Conds : Conds_T := (others => False);

   --  The trip condition found in the cycle, the trip in force
   Pending : Trip_Reason_T := No_Trip;
   Reason  : Trip_Reason_T := No_Trip;
   --  4.6.3 [65] noted in the cycle (Note_Version_Not_Supported)
   Version_Seen : Boolean := False;

   --  The context of the last Evaluate, the orientation of the train
   Ctx             : Context_T;
   Orientation_Now : Sense_T := Plus;

   --  Override (5.8): active, since when, the distance run since, the
   --  estimated front end of the last cycle; selected in the cycle
   Ovr              : Boolean := False;
   Ovr_Since        : Unsigned_64 := 0;
   Ovr_Run          : Length_T := 0;
   Ovr_Last         : Dist_T := 0;
   Ovr_Selected_Now : Boolean := False;
   --  5.8.4.2: the trips of the cycle see the override as it was before
   --  the information of the balise groups ended it
   Ovr_For_Trips    : Boolean := False;
   --  5.8.4.1 h): the override was selected in SR, its SR distance
   --  supervised before overriding
   Ovr_In_SR        : Boolean := False;
   --  5.8.3.1.1: the former EOA/LOA (a frame position along Former_S),
   --  and whether the min safe antenna position is beyond it
   Former        : Boolean := False;
   Former_X      : Dist_T := 0;
   Former_S      : Sense_T := Plus;
   Former_Passed : Boolean := False;

   --  The request for the acknowledgement of a mode: displayed, for the
   --  mode Ack_M, after the transition (the T_ACK of 5.7.3.7, 5.9.2.4,
   --  5.9.3.8, 5.19.2.4, 5.19.3.8 runs from Ack_Since), the service brake
   --  of 3.14.1.7.3 commanded, the V_MAMODE of the mode profile asked
   Ack_On    : Boolean := False;
   Ack_M     : Mode_T := M_OS;
   Ack_After : Boolean := False;
   Ack_Since : Unsigned_64 := 0;
   Ack_SB    : Boolean := False;
   Ack_V     : Natural range 0 .. 127 := 127;
   --  acknowledged in the cycle, and for which mode
   Acked_Now : Boolean := False;
   Acked_M   : Mode_T := M_OS;

   --  The mode profile against the train position (3.12.4, Evaluate):
   --  the furthest area the confidence interval overlaps (its mode
   --  M_MAMODE 0 OS, 1 SH, 2 LS; 3 none) and its V_MAMODE, the
   --  shunting area reached ([51]) and its V_MAMODE, the estimated front
   --  end inside an OS or an LS acknowledgement area, any area overlapped
   type Profile_Info_T is record
      Furthest   : Natural range 0 .. 3 := 3;
      Furthest_V : Natural range 0 .. 127 := 127;
      SH_Reached : Boolean := False;
      SH_V       : Natural range 0 .. 127 := 127;
      In_OS_Ack  : Boolean := False;
      In_LS_Ack  : Boolean := False;
      Any        : Boolean := False;
   end record;
   Profile_Info : Profile_Info_T;

   --  3.11.7.1.1: the V_MAMODE of the mode profile the mode in use was
   --  entered with (127: the national value)
   Use_V : Natural range 0 .. 127 := 127;

   --  Post trip (4.4.14.1.3): where the reverse movement is counted
   --  from, along the orientation then; the distance overpassed, the
   --  service brake commanded (3.14.1.7.4)
   PT_Start : Dist_T := 0;
   PT_Sense : Sense_T := Plus;
   PT_Over  : Boolean := False;
   PT_SB    : Boolean := False;

   --  Shunting: "Stop Shunting on desk opening" stored (packet 135,
   --  4.4.20.1.8), the list of balise groups for the SH area (packet 49,
   --  4.4.8.1.1 b); "Continue Shunting on desk closure" (4.4.20.1.5) is
   --  EVC_Mission's
   Max_SH_List : constant := 32;
   type Id_List_T is array (1 .. Max_SH_List) of Identity_T;
   Stop_On_Desk  : Boolean := False;
   SH_List_Known : Boolean := False;
   SH_List_N     : Natural range 0 .. Max_SH_List := 0;
   SH_List       : Id_List_T := (others => (others => <>));
   --  3.12.4.4: an SH mode profile was stored in the last cycle
   SH_Profile_Seen : Boolean := False;

   --  What the balise groups of the cycle said
   type Now_Flags_T is record
      --  packet 132 "stop if in shunting", packet 137 "stop if in SR"
      SH_Stop     : Boolean := False;
      SR_Stop     : Boolean := False;
      --  a group not in the list of balise groups for the SH area
      SH_Unlisted : Boolean := False;
      --  a group with an MA without a signalling related speed
      --  restriction of value zero (5.8.4.1 e)
      Proceed     : Boolean := False;
      --  the linking reactions of the cycle (3.16.2.3, 3.4.4.4.7)
      Link_Trip   : Boolean := False;
      Wrong_Dir   : Boolean := False;
      Link_SB     : Boolean := False;
   end record;
   Now_Flags : Now_Flags_T;

   --  Reversing (3.15.4, packets 138 and 139): the area (frame
   --  positions along Sense), the supervision information, the limit of
   --  the reverse movement (Ref less Distance along Sense, 3.15.4.2.1)
   type Reversing_T is record
      Area      : Boolean := False;
      Sense     : Sense_T := Plus;
      Start     : Dist_T := 0;
      Finish    : Dist_T := 0;
      Sup       : Boolean := False;
      Infinite  : Boolean := False;
      Distance  : Length_T := 0;
      Speed     : Speed_Cms_T := 0;
   end record;
   Rev          : Reversing_T;
   Rev_Possible : Boolean := False;
   RV_Over      : Boolean := False;
   RV_EB        : Boolean := False;

   --  5.22: the inhibition of the BTM alarm reaction, from where
   BMM_On   : Boolean := False;
   BMM_From : Dist_T := 0;

   --  3.14.1.6: the service brake of a linking reaction, to standstill
   Link_SB : Boolean := False;

   --  5.17: Train Data changed by another source. The step of the
   --  procedure (5.17.2.2: S1 waiting for the end of the trip, S2 / S4
   --  the service brake until standstill, S3 / S5 the acknowledgement of
   --  the brake command), whether S6 follows the release (A6) rather
   --  than A7 (A5), the re-validation requested (S6), and the event 2 of
   --  "Train data changed" (its 30 s from a train movement) due
   type TD_Step_T is (TD_Idle, TD_Wait_Trip, TD_Brake, TD_Ack);
   TD_Step            : TD_Step_T := TD_Idle;
   TD_Then_Revalidate : Boolean := False;
   TD_Revalidate      : Boolean := False;
   TD_Moving_Due      : Boolean := False;

   --  The brake demand, and the one recorded last
   Demand      : Brake_Demand_T;
   Demand_Sent : Brake_Demand_T;

   type Status_List_T is array (1 .. Max_Status_Events) of Status_Event_T;
   Status_N    : Natural range 0 .. Max_Status_Events := 0;
   Status_List : Status_List_T := (others => (others => <>));

   type Event_List_T is array (1 .. Max_Events) of Event_T;
   Event_N : Natural range 0 .. Max_Events := 0;
   Events  : Event_List_T := (others => (others => <>));

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Condition (C : Condition_T) return Boolean is (Conds (C))
     with Refined_Global => Conds;
   function Trip_Reason return Trip_Reason_T is (Reason)
     with Refined_Global => Reason;
   function Override_Active return Boolean is (Ovr)
     with Refined_Global => Ovr;
   function Ack_Requested return Boolean is (Ack_On)
     with Refined_Global => Ack_On;
   function Ack_Mode return Mode_T is (Ack_M)
     with Refined_Global => Ack_M;
   --  5.8.3.7.1, 5.8.3.7.2: not in level NTC
   function Override_Indicated return Boolean is
     (Ovr and then not (Ctx.Level_Valid and then Ctx.Level = NTC))
     with Refined_Global => (Ovr, Ctx);
   function Reversing_Possible return Boolean is (Rev_Possible)
     with Refined_Global => Rev_Possible;
   function Train_Data_Revalidation return Boolean is (TD_Revalidate)
     with Refined_Global => TD_Revalidate;
   function BMM_Inhibited return Boolean is (BMM_On)
     with Refined_Global => BMM_On;
   function Status_Event_Count return Natural is (Status_N)
     with Refined_Global => Status_N;
   function Status_Event (I : Positive) return Status_Event_T is
     (Status_List (I))
     with Refined_Global => (Input => Status_List, Proof_In => Status_N);
   function Brake_Demand return Brake_Demand_T is
     ((EB           => Demand.EB or else Demand.Trip,
       SB           => Demand.SB,
       Trip         => Demand.Trip,
       Ack_Missing  => Demand.Ack_Missing,
       Other        => Demand.Other,
       Ack_Required => Demand.Ack_Required))
     with Refined_Global => Demand;
   function Event_Count return Natural is (Event_N)
     with Refined_Global => Event_N;
   function Event (I : Positive) return Event_T is (Events (I))
     with Refined_Global => (Input => Events, Proof_In => Event_N);

   --  3.11.7.1.1: a V_MAMODE, or the national value for 127
   function Profile_Speed (V : Natural; National : Speed_Cms_T)
     return Speed_Cms_T
   is (if V >= 127 then National else Speed_Cms_T (V5_To_Cms (V)));

   function Mode_Speed (M        : Mode_T;
                        NV       : National_Values_T;
                        SR_Speed : Speed_Cms_T) return Speed_Cms_T
     with Refined_Global => (Use_V, Rev, Ovr, Ctx)
   is
      Base : constant Speed_Cms_T :=
        (case M is
            when M_SH   => Profile_Speed (Use_V, NV.V_NVSHUNT),
            when M_OS   => Profile_Speed (Use_V, NV.V_NVONSIGHT),
            when M_LS   => Profile_Speed (Use_V, NV.V_NVLIMSUPERV),
            when M_SR   => SR_Speed,
            when M_UN   => NV.V_NVUNFIT,
            --  3.11.7.1.2: from the trackside only
            when M_RV   => (if Rev.Sup then Rev.Speed else 0),
            when others => No_Speed_Limit);
   begin
      --  3.11.10.1, 5.8.3.6: in levels 0, 1 and 2
      if Ovr and then not (Ctx.Level_Valid and then Ctx.Level = NTC) then
         return Speed_Cms_T'Min (Base, NV.V_NVSUPOVTRP);
      end if;
      return Base;
   end Mode_Speed;

   ---------------------------------------------------------------------
   --  Records
   ---------------------------------------------------------------------

   procedure Record_Event (Kind, B3, B4 : Natural)
     with Global => (In_Out => (Events, Event_N))
   is
   begin
      if Event_N < Max_Events then
         Event_N := Event_N + 1;
         Events (Event_N) :=
           (Kind => Unsigned_8 (Kind mod 256),
            B3   => Unsigned_8 (B3 mod 256),
            B4   => Unsigned_8 (B4 mod 256));
      end if;
   end Record_Event;

   procedure Status (Entry_Number : Natural; Event : Natural)
     with Global => (In_Out => (Status_List, Status_N)),
          Pre => Event <= 2
   is
   begin
      if Entry_Number in 1 .. 255 and then Status_N < Max_Status_Events then
         Status_N := Status_N + 1;
         Status_List (Status_N) :=
           (Entry_Number => Entry_Number, Event => Event);
      end if;
   end Status;

   ---------------------------------------------------------------------
   --  Clear
   ---------------------------------------------------------------------

   procedure Clear is
   begin
      Conds := (others => False);
      Pending := No_Trip;
      Reason := No_Trip;
      Version_Seen := False;
      Ctx := (others => <>);
      Orientation_Now := Plus;
      Ovr := False;
      Ovr_Since := 0;
      Ovr_Run := 0;
      Ovr_Last := 0;
      Ovr_Selected_Now := False;
      Ovr_For_Trips := False;
      Ovr_In_SR := False;
      Former := False;
      Former_X := 0;
      Former_S := Plus;
      Former_Passed := False;
      Ack_On := False;
      Ack_M := M_OS;
      Ack_After := False;
      Ack_Since := 0;
      Ack_SB := False;
      Ack_V := 127;
      Acked_Now := False;
      Acked_M := M_OS;
      Profile_Info := (others => <>);
      Use_V := 127;
      PT_Start := 0;
      PT_Sense := Plus;
      PT_Over := False;
      PT_SB := False;
      Stop_On_Desk := False;
      SH_List_Known := False;
      SH_List_N := 0;
      SH_List := (others => (others => <>));
      SH_Profile_Seen := False;
      Now_Flags := (others => <>);
      Rev := (others => <>);
      Rev_Possible := False;
      RV_Over := False;
      RV_EB := False;
      BMM_On := False;
      BMM_From := 0;
      Link_SB := False;
      Demand := (others => <>);
      Demand_Sent := (others => <>);
      Status_N := 0;
      Status_List := (others => (others => <>));
      Event_N := 0;
      Events := (others => (others => <>));
      TD_Step := TD_Idle;
      TD_Then_Revalidate := False;
      TD_Revalidate := False;
      TD_Moving_Due := False;
   end Clear;

   procedure Note_Version_Not_Supported is
   begin
      Version_Seen := True;
   end Note_Version_Not_Supported;

   procedure Train_Data_Revalidated is
   begin
      if TD_Revalidate then
         TD_Revalidate := False;
         --  A7
         Record_Event (Event_Train_Data, 6, 0);
      end if;
   end Train_Data_Revalidated;

   ---------------------------------------------------------------------
   --  1. The packets of the balise groups of the cycle
   ---------------------------------------------------------------------

   subtype Reader_T is ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);

   --  4.8: the kind of information of a packet of this unit (the list
   --  of balise groups for the SH area comes with the MA)
   function Info_Of (Kind : ETCS_Catalogue.Packet_Kind_T)
     return EVC_Acceptance.Info_T
   is (case Kind is
          when ETCS_Catalogue.Track_P132 => EVC_Acceptance.Danger_For_SH,
          when ETCS_Catalogue.Track_P135 => EVC_Acceptance.Stop_SH_On_Desk,
          when ETCS_Catalogue.Track_P137 => EVC_Acceptance.Stop_If_In_SR,
          when ETCS_Catalogue.Track_P138 => EVC_Acceptance.Reversing_Area,
          when ETCS_Catalogue.Track_P139 =>
             EVC_Acceptance.Reversing_Supervision,
          when ETCS_Catalogue.Track_P12  => EVC_Acceptance.Signalling_Speed,
          when others => EVC_Acceptance.Movement_Authority);

   --  A distance of the group message of the group taken Tk, from its
   --  location reference along its sense, as a frame position (from the
   --  anchor of the group: its origin of EVC_Origins may be released in
   --  the cycle when no store refers to it)
   function At_D (Tk : EVC_Position.Taken_T; D : Length_T) return Dist_T is
     (Advance (Tk.Group.X, Tk.S, D));

   --  Packet 132, danger for Shunting information (7.4.2.28; 4.4.8.1.1
   --  c): Q_ASPECT "stop if in SH"
   procedure Take_P132 (R : in out Reader_T)
     with Global => (In_Out => (Now_Flags, Events, Event_N))
   is
      X  : ETCS_Track_Packets.P132.Packet_T;
      OK : Boolean;
   begin
      ETCS_Track_Packets.P132.Decode (R, X, OK);
      if OK and then X.Q_ASPECT = 0 then
         Now_Flags.SH_Stop := True;
         Record_Event (Event_Shunting, 3, 0);
      end if;
   end Take_P132;

   --  Packet 135, stop Shunting on desk opening (7.4.2.31; 4.6.3 [22],
   --  [23])
   procedure Take_P135 (R : in out Reader_T)
     with Global => (In_Out => (Stop_On_Desk, Events, Event_N))
   is
      pragma Warnings
        (GNATprove, Off, """X"" is set by ""Decode"" but not used*",
         Reason => "the packet has no variable besides its header");
      X  : ETCS_Track_Packets.P135.Packet_T;
      OK : Boolean;
   begin
      ETCS_Track_Packets.P135.Decode (R, X, OK);
      if OK then
         Stop_On_Desk := True;
         Record_Event (Event_Shunting, 1, 0);
      end if;
   end Take_P135;

   --  Packet 49, the list of balise groups for the SH area (7.4.2.12;
   --  4.4.8.1.1 b), of the group taken Tk (its country unless an item
   --  gives another)
   procedure Take_P49 (R : in out Reader_T; Tk : EVC_Position.Taken_T)
     with Global => (In_Out => (SH_List_Known, SH_List_N, SH_List, Events,
                                Event_N))
   is
      X  : ETCS_Track_Packets.P49.Packet_T;
      OK : Boolean;
      C  : NID_C_T := Tk.Group.Id.NID_C;
   begin
      ETCS_Track_Packets.P49.Decode (R, X, OK);
      if OK then
         --  4.4.8.1.1 b): a new list replaces the stored one; an
         --  empty list lets no group pass
         SH_List_Known := True;
         SH_List_N := 0;
         SH_List := (others => (others => <>));
         for I in 1 .. Natural (X.N_ITER) loop
            pragma Loop_Invariant (SH_List_N <= I - 1);
            declare
               It : ETCS_Track_Packets.P49.Q_NEWCOUNTRY_Item renames
                 X.Q_NEWCOUNTRY_List (I);
            begin
               if It.Q_NEWCOUNTRY = 1 then
                  C := It.NID_C;
               end if;
               SH_List_N := SH_List_N + 1;
               SH_List (SH_List_N) := (NID_C => C, NID_BG => It.NID_BG);
            end;
         end loop;
         Record_Event (Event_Shunting, 2, SH_List_N);
      end if;
   end Take_P49;

   --  5.6.2.2 A050 in level 2: the list of balise groups for the SH area
   --  of the RBC's authorisation (message 28) replaces the stored one;
   --  without one none is kept
   procedure Take_Radio_SH_List
     with Global => (Input  => EVC_Radio_Authority.State,
                     Output => (SH_List_Known, SH_List_N, SH_List))
   is
   begin
      SH_List_Known := EVC_Radio_Authority.SH_List_Given;
      SH_List_N := 0;
      SH_List := (others => (others => <>));
      for I in 1 .. EVC_Radio_Authority.SH_List_Count loop
         pragma Loop_Invariant (SH_List_N = I - 1);
         SH_List_N := SH_List_N + 1;
         SH_List (SH_List_N) := EVC_Radio_Authority.SH_List_Item (I);
      end loop;
   end Take_Radio_SH_List;

   --  Packet 137, stop if in Staff Responsible (7.4.2.33; 4.6.3 [54],
   --  5.8.3.1.3 a)
   procedure Take_P137 (R : in out Reader_T)
     with Global => (In_Out => Now_Flags)
   is
      X  : ETCS_Track_Packets.P137.Packet_T;
      OK : Boolean;
   begin
      ETCS_Track_Packets.P137.Decode (R, X, OK);
      if OK and then X.Q_SRSTOP = 0 then
         Now_Flags.SR_Stop := True;
      end if;
   end Take_P137;

   --  Packet 12, the level 1 MA (7.4.2.3): a proceed aspect, V_MAIN not
   --  0, ends the override (5.8.4.1 e)
   procedure Take_P12 (R : in out Reader_T)
     with Global => (In_Out => Now_Flags)
   is
      X  : ETCS_Track_Packets.P12.Packet_T;
      OK : Boolean;
   begin
      ETCS_Track_Packets.P12.Decode (R, X, OK);
      if OK and then X.V_MAIN /= 0 then
         Now_Flags.Proceed := True;
      end if;
   end Take_P12;

   --  Packet 138, the reversing area information (7.4.2.34; 3.15.4.1.1:
   --  a new area replaces the stored one), from the group taken Tk
   procedure Take_P138 (R : in out Reader_T; Tk : EVC_Position.Taken_T)
     with Global => (In_Out => (Rev, Events, Event_N))
   is
      X  : ETCS_Track_Packets.P138.Packet_T;
      OK : Boolean;
   begin
      ETCS_Track_Packets.P138.Decode (R, X, OK);
      --  3.15.4.1.1: a new area replaces the stored one
      if OK and then X.Q_SCALE <= 2 then
         declare
            S0 : constant Length_T :=
              Scaled (Natural (X.D_STARTREVERSE), Natural (X.Q_SCALE));
            L  : constant Length_T :=
              Scaled (Natural (X.L_REVERSEAREA), Natural (X.Q_SCALE));
         begin
            Rev.Area := True;
            Rev.Sense := Tk.S;
            Rev.Start := At_D (Tk, S0);
            Rev.Finish := At_D (Tk, Add (S0, L));
            Record_Event (Event_Reversing, 1, 0);
         end;
      end if;
   end Take_P138;

   --  Packet 139, the reversing supervision information (7.4.2.35;
   --  3.15.4.3: replaces the distance and the speed)
   procedure Take_P139 (R : in out Reader_T)
     with Global => (In_Out => (Rev, Events, Event_N))
   is
      X  : ETCS_Track_Packets.P139.Packet_T;
      OK : Boolean;
   begin
      ETCS_Track_Packets.P139.Decode (R, X, OK);
      --  3.15.4.3: replaces the distance and the speed
      if OK and then X.Q_SCALE <= 2 then
         Rev.Sup := True;
         Rev.Infinite := X.D_REVERSE = D_REVERSE_Infinite;
         Rev.Distance :=
           Scaled (Natural (X.D_REVERSE), Natural (X.Q_SCALE));
         Rev.Speed := Speed_Cms_T (V5_To_Cms (Natural (X.V_REVERSE)));
         Record_Event (Event_Reversing, 2, 0);
      end if;
   end Take_P139;

   --  Packet P of the telegram J of the group taken Tk, of kind Kind (one
   --  of the packets of this unit): decoded and taken
   procedure Take_Packet (Kind : ETCS_Catalogue.Packet_Kind_T;
                          J, P : Positive;
                          Tk   : EVC_Position.Taken_T)
     with Global => (Input  => EVC_Position.State,
                     In_Out => (Now_Flags, Stop_On_Desk, SH_List_Known,
                                SH_List_N, SH_List, Rev, Events, Event_N)),
          Pre => P <= EVC_Position.Taken_Packet_Count (J)
   is
      pragma Warnings
        (GNATprove, Off, """R"" is set by * but not used after*",
         Reason => "the reader of one packet is not used after it");
      R  : Reader_T;
      use type ETCS_Catalogue.Packet_Kind_T;
   begin
      EVC_Position.Open_Taken_Packet (J, P, R);
      if Kind = ETCS_Catalogue.Track_P132 then
         Take_P132 (R);
      elsif Kind = ETCS_Catalogue.Track_P135 then
         Take_P135 (R);
      elsif Kind = ETCS_Catalogue.Track_P49 then
         Take_P49 (R, Tk);
      elsif Kind = ETCS_Catalogue.Track_P137 then
         Take_P137 (R);
      elsif Kind = ETCS_Catalogue.Track_P12 then
         Take_P12 (R);
      elsif Kind = ETCS_Catalogue.Track_P138 then
         Take_P138 (R, Tk);
      elsif Kind = ETCS_Catalogue.Track_P139 then
         Take_P139 (R);
      end if;
   end Take_Packet;

   procedure Take_Packets (C : Context_T)
     with Global => (Input  => EVC_Position.State,
                     In_Out => (Now_Flags, Stop_On_Desk, SH_List_Known,
                                SH_List_N, SH_List, Rev, Events, Event_N))
   is
      use type ETCS_Catalogue.Packet_Kind_T;
   begin
      for G in 1 .. EVC_Position.Taken_Count loop
         declare
            Tk     : constant EVC_Position.Taken_T := EVC_Position.Taken (G);
            Listed : Boolean := False;
         begin
            --  4.4.8.1.1 b): in Shunting, a group not in the list of
            --  balise groups for the SH area (with no list, every group
            --  may be passed)
            if C.Mode = M_SH and then SH_List_Known then
               for I in 1 .. SH_List_N loop
                  if SH_List (I) = Tk.Group.Id then
                     Listed := True;
                  end if;
               end loop;
               if not Listed then
                  Now_Flags.SH_Unlisted := True;
               end if;
            end if;
            for J in Tk.First .. Tk.First + Tk.Count - 1 loop
               for P in 1 .. EVC_Position.Taken_Packet_Count (J) loop
                  declare
                     E : constant ETCS_Packet_Index.Entry_T :=
                       EVC_Position.Taken_Entry (J, P);
                  begin
                     if E.Kind in ETCS_Catalogue.Track_P132
                                | ETCS_Catalogue.Track_P135
                                | ETCS_Catalogue.Track_P49
                                | ETCS_Catalogue.Track_P137
                                | ETCS_Catalogue.Track_P12
                                | ETCS_Catalogue.Track_P138
                                | ETCS_Catalogue.Track_P139
                       and then EVC_Position.Valid_For
                                  (E.Q_DIR, Tk.Group.Orientation, Tk.T)
                       --  4.8 (EVC_Acceptance)
                       and then EVC_Acceptance.Accepted
                                  (Info_Of (E.Kind), C.Filters)
                     then
                        Take_Packet (E.Kind, J, P, Tk);
                     end if;
                  end;
               end loop;
            end loop;
         end;
      end loop;
   end Take_Packets;

   --  The linking reactions of the cycle (EVC_Position events, 3.16.2.3,
   --  3.4.4.4.7)
   procedure Linking_Events
     with Global => (Input  => EVC_Position.State,
                     In_Out => Now_Flags)
   is
      use type EVC_Position.Event_Kind_T;
   begin
      for I in 1 .. EVC_Position.Event_Count loop
         declare
            E : constant EVC_Position.Event_T := EVC_Position.Event (I);
         begin
            if E.Kind = EVC_Position.Linking_Reaction then
               if E.B3 = EVC_Position.Cause_Wrong_Direction then
                  Now_Flags.Wrong_Dir := True;
               elsif E.B2 = Unsigned_8 (Q_LINKREACTION_Train_Trip) then
                  Now_Flags.Link_Trip := True;
               elsif E.B2 = Unsigned_8 (Q_LINKREACTION_Apply_Service_Brake)
               then
                  Now_Flags.Link_SB := True;
               end if;
            end if;
         end;
      end loop;
   end Linking_Events;

   ---------------------------------------------------------------------
   --  2. Override (5.8)
   ---------------------------------------------------------------------

   --  5.8.2.1: the driver may select "Override"
   function Override_Allowed (C : Context_T; NV : National_Values_T)
     return Boolean
   is (C.Speed_Max <= NV.V_NVALLOWOVTRP
       and then (C.Mode in M_FS | M_AD | M_LS | M_OS | M_SR | M_SH | M_UN
                         | M_PT | M_SN
                 or else (C.Mode = M_SB and then C.Level_Valid
                          and then C.Level = L2))
       and then (C.Mode = M_SH
                 or else (C.Train_Data_Valid and then C.TRN_Valid)));

   procedure End_Override (Why : Natural)
     with Global => (In_Out => (Ovr, Events, Event_N))
   is
   begin
      if Ovr then
         Ovr := False;
         Record_Event (Event_Override_End, Why, 0);
      end if;
   end End_Override;

   --  The min safe antenna position along Former_S beyond the former EOA
   function Beyond_Former (S : Snapshot_T; Antenna : Length_T)
     return Boolean
   is (A (Former_S, Advance (S.Train.Min_Safe_Front, Opposite (Former_S),
                             Antenna))
       > A (Former_S, Former_X))
     with Global => (Former_S, Former_X);

   procedure Override_Step (C : Context_T; S : Snapshot_T)
     with Global => (Input  => (Orientation_Now, EVC_Driver_Requests.State,
                                Now_Flags),
                     Output => (Ovr_Selected_Now, Ovr_For_Trips),
                     In_Out => (Ovr, Ovr_Since, Ovr_Run, Ovr_Last, Ovr_In_SR,
                                Former, Former_X,
                                Former_S, Former_Passed, Events, Event_N,
                                Conds, Pending))
   is
      NV : National_Values_T renames S.National;
      Was_Active : constant Boolean := Ovr;
      Crossed    : Boolean := False;
   begin
      Ovr_Selected_Now := False;
      --  5.8.2.3: triggered when selected
      if EVC_Driver_Requests.Override_Selected
        and then Override_Allowed (C, NV)
      then
         Record_Event (Event_Override_Start, (if Ovr then 1 else 0), 0);
         --  5.8.3.9: selected again, the time and the distance restart
         Ovr := True;
         Ovr_Since := C.Now_Ms;
         Ovr_Run := 0;
         Ovr_Last := S.Train.Est_Front;
         Ovr_Selected_Now := True;
         --  5.8.4.1 h): the SR distance of SR, supervised before
         Ovr_In_SR := C.Mode = M_SR;
         --  5.8.3.1.1, 5.8.3.1.2: the former EOA/LOA, unless already in
         --  SR; 5.8.1.9: the temporary EOA when it is closer
         if C.Mode in M_FS | M_AD | M_LS | M_OS then
            if S.MA.Present then
               Former := True;
               Former_S := S.Train.Ahead;
               Former_X := S.MA.EOA;
               if S.Temporary.Present
                 and then A (Former_S, S.Temporary.EOA)
                          < A (Former_S, Former_X)
               then
                  Former_X := S.Temporary.EOA;
               end if;
               Former_Passed := Beyond_Former (S, C.Antenna_Offset);
            end if;
         elsif C.Mode in M_SB | M_PT then
            --  the current position of the train front (or, without a
            --  valid position, a zero distance from it: the same here,
            --  the frame position of the estimated front end)
            Former := True;
            Former_S := Orientation_Now;
            Former_X := S.Train.Est_Front;
            Former_Passed := False;
         end if;
      end if;

      Ovr_For_Trips := Ovr;

      --  5.8.3.1.3 a): "stop if in SR" read, the former EOA/LOA deleted
      if Now_Flags.SR_Stop then
         Former := False;
         Former_Passed := False;
      end if;

      --  [43]: the former EOA overpassed with the min safe antenna
      --  position (a crossing in this cycle), the override not active
      if Former then
         declare
            Beyond : constant Boolean := Beyond_Former (S, C.Antenna_Offset);
         begin
            Crossed := Beyond and then not Former_Passed;
            Former_Passed := Beyond;
         end;
      end if;
      if Crossed and then not Was_Active and then C.Mode = M_SR then
         Conds (43) := True;
         if Pending = No_Trip then
            Pending := Former_EOA_Passed;
         end if;
      end if;

      --  5.8.4.1: the end of the override
      if Ovr and then not Ovr_Selected_Now then
         Ovr_Run := Add (Ovr_Run,
                         Abs_Dist (Diff (S.Train.Est_Front, Ovr_Last)));
         Ovr_Last := S.Train.Est_Front;
         if C.Now_Ms >= Ovr_Since
           and then C.Now_Ms - Ovr_Since
                      > Unsigned_64 (NV.T_NVOVTRP)
         then
            End_Override (1);                                  -- a)
         elsif Ovr_Run > NV.D_NVOVTRP then
            End_Override (2);                                  -- b)
         elsif C.Mode not in M_UN | M_SN then
            --  5.8.4.1.1: in UN and SN only a) and b)
            if Crossed then
               End_Override (3);                               -- c)
            elsif Now_Flags.SR_Stop or else Now_Flags.SH_Stop then
               End_Override (4);                               -- d)
            elsif Now_Flags.Proceed then
               End_Override (5);                               -- e)
            elsif Now_Flags.SH_Unlisted then
               End_Override (7);                               -- g)
            elsif Ovr_In_SR and then C.SR_Distance_Passed then
               End_Override (8);                               -- h)
            end if;
         end if;
      end if;
   end Override_Step;

   ---------------------------------------------------------------------
   --  3. The mode profile against the train position (3.12.4)
   ---------------------------------------------------------------------

   --  The mode of 4.3.2 an M_MAMODE asks
   function Mode_Of (M : M_MAMODE_T) return Mode_T is
     (case M is
         when 0      => M_OS,
         when 1      => M_SH,
         when others => M_LS);

   --  The national speed limit of the mode of a mode profile
   function National_Of (M : M_MAMODE_T; NV : National_Values_T)
     return Speed_Cms_T
   is (case M is
          when 0      => NV.V_NVONSIGHT,
          when 1      => NV.V_NVSHUNT,
          when others => NV.V_NVLIMSUPERV);

   --  A request for the acknowledgement of mode M before reaching its
   --  area ("rectangle", 5.7.3.2, 5.9.3.2, 5.19.3.2) is possible in the
   --  current mode: the transitions [50], [15], [70] from it
   function Rectangle_From (Current, M : Mode_T) return Boolean is
     (case M is
         when M_OS   => Current in M_FS | M_AD | M_LS,
         when M_LS   => Current in M_FS | M_AD | M_OS,
         when M_SH   => Current in M_FS | M_AD | M_LS | M_OS,
         when others => False);

   procedure Profiles_Step (C : Context_T; S : Snapshot_T)
     with Global => (Input  => (EVC_Movement_Authority.State,
                                EVC_Origins.State),
                     Output => Profile_Info,
                     In_Out => (Ack_On, Ack_M, Ack_After,
                                Ack_Since, Ack_V, Events, Event_N))
   is
      --  the mode profiles and the MA are read in place, not copied
      function P (I : Positive) return EVC_Movement_Authority.Mode_Profile_T
      is (EVC_Movement_Authority.Mode_Profile (I))
        with Pre => I <= EVC_Movement_Authority.Max_Mode_Profiles;
      T     : constant Origin_Table_T := Origin_Table;
      Sn    : constant Sense_T := EVC_Movement_Authority.MA_Sense;
      Est   : constant Dist_T := A (Sn, S.Train.Est_Front);
      Mn    : constant Dist_T := A (Sn, S.Train.Min_Safe_Front);
      Mx    : constant Dist_T := A (Sn, S.Train.Max_Safe_Front);
      Best  : Dist_T := -Max_Cm;
      Info  : Profile_Info_T;
   begin
      if EVC_Movement_Authority.MA_Present and then S.Train.Position_Valid
      then
         for I in 1 .. EVC_Movement_Authority.Max_Mode_Profiles loop
            --  not unrolled by the proof, nothing needed after the loop
            pragma Loop_Invariant (True);
            if P (I).Used then
               declare
                  St : constant Dist_T :=
                    A (Sn, Frame (T, P (I).Start, Estimated_Item));
                  Fi : constant Dist_T :=
                    A (Sn, Frame (T, P (I).Finish, Estimated_Item));
                  Ak : constant Dist_T :=
                    A (Sn, Frame (T, P (I).Ack_Start, Estimated_Item));
                  --  3.12.4.5, 3.12.4.6: the beginning against the max
                  --  safe front end, the end against the min safe front
                  --  end; a shunting area has no end (3.12.4.2)
                  Overlap : constant Boolean :=
                    Mx >= St and then (P (I).Open or else Mn < Fi);
                  In_Ack  : constant Boolean := Est > Ak and then Est < St;
                  M       : constant Mode_T := Mode_Of (P (I).Mode);
               begin
                  if Overlap then
                     Info.Any := True;
                     if St > Best then
                        Best := St;
                        Info.Furthest := Natural (P (I).Mode);
                        Info.Furthest_V := Natural (P (I).Speed);
                     end if;
                  end if;
                  if P (I).Mode = 1 and then Mx >= St then
                     Info.SH_Reached := True;
                     Info.SH_V := Natural (P (I).Speed);
                  end if;
                  if In_Ack then
                     if P (I).Mode = 0 then
                        Info.In_OS_Ack := True;
                     elsif P (I).Mode = 2 then
                        Info.In_LS_Ack := True;
                     end if;
                  end if;
                  --  the request for acknowledgement in the rectangle:
                  --  the estimated front end closer to the beginning than
                  --  L_ACKMAMODE and the speed not above the speed limit
                  --  of the mode; once displayed it is not taken back
                  if In_Ack and then not Ack_On and then C.Mode /= M
                    and then Rectangle_From (C.Mode, M)
                    and then S.Train.Speed
                               <= Profile_Speed
                                    (Natural (P (I).Speed),
                                     National_Of (P (I).Mode, S.National))
                  then
                     Ack_On := True;
                     Ack_M := M;
                     Ack_After := False;
                     Ack_Since := C.Now_Ms;
                     Ack_V := Natural (P (I).Speed);
                     Record_Event (Event_Ack_Request, Mode_T'Pos (M), 0);
                  end if;
               end;
            end if;
         end loop;
         --  5.7.4.1, 5.9.5.1, 5.19.5.1: in SB or PT in level 2, an area
         --  the train is already in asks for the acknowledgement first
         if C.Mode in M_SB | M_PT and then C.Level_Valid
           and then C.Level = L2 and then not Ack_On
           and then (Info.Furthest <= 2 or else Info.SH_Reached)
         then
            Ack_On := True;
            Ack_M := (if Info.SH_Reached then M_SH
                      else Mode_Of (M_MAMODE_T (Info.Furthest)));
            Ack_After := False;
            Ack_Since := C.Now_Ms;
            Ack_V := (if Info.SH_Reached then Info.SH_V
                      else Info.Furthest_V);
            Record_Event (Event_Ack_Request, Mode_T'Pos (Ack_M), 0);
         end if;
      end if;
      Profile_Info := Info;
   end Profiles_Step;

   ---------------------------------------------------------------------
   --  4. Trip conditions (5.11, 4.6.3)
   ---------------------------------------------------------------------

   procedure Trip_Step (C : Context_T; S : Snapshot_T; SDM : EVC_SDM.Result_T)
     with Global => (Input  => (EVC_Movement_Authority.State,
                                EVC_Track_Description.State,
                                EVC_Origins.State, Now_Flags,
                                Ovr_For_Trips, Version_Seen),
                     In_Out => (Conds, Pending))
   is
      In_L1 : constant Boolean := C.Level_Valid and then C.Level = L1;
      In_L2 : constant Boolean := C.Level_Valid and then C.Level = L2;

      --  5.8.3.6: the train trip is inhibited while the override
      --  function is active (as it was before the information of the
      --  balise groups of the cycle ended it, 5.8.4.2)
      procedure Trip (Id : Condition_T; R : Trip_Reason_T)
        with Global => (In_Out => (Conds, Pending),
                        Input  => Ovr_For_Trips)
      is
      begin
         if not Ovr_For_Trips then
            Conds (Id) := True;
            if Pending = No_Trip then
               Pending := R;
            end if;
         end if;
      end Trip;
   begin
      --  [12], [16] (and {9}: the temporary EOA, EVC_SDM's targets)
      if SDM.EOA_Passed then
         if In_L1 then
            Trip (12, EOA_Passed);
         elsif In_L2 then
            Trip (16, EOA_Passed);
         end if;
      end if;
      --  [17], [66]
      if Now_Flags.Link_Trip then
         Trip (17, Linking_Error);
      end if;
      if Now_Flags.Wrong_Dir then
         Trip (66, Wrong_Direction);
      end if;
      --  [18]: 3.11.6.4, the trip order of a balise
      if EVC_Movement_Authority.Trip_Ordered then
         Trip (18, Trip_Order);
      end if;
      --  [49], [52]
      if Now_Flags.SH_Stop then
         Trip (49, SH_Stop_Order);
      end if;
      if Now_Flags.SH_Unlisted then
         Trip (52, SH_Balise_Not_Listed);
      end if;
      --  [54]: "stop if in SR", unless the group is in the list of
      --  expected balise groups in SR of the RBC (4.4.11.1.3 d)
      if Now_Flags.SR_Stop and then not C.SR_Listed then
         Trip (54, SR_Stop_Order);
      end if;
      --  [65]
      if Version_Seen and then (In_L1 or else In_L2) then
         Trip (65, Version_Not_Supported);
      end if;
      --  [42] (the SR distance of EVC_Mission, 4.4.11.1.3 b)
      if C.Mode = M_SR and then C.SR_Distance_Passed then
         Trip (42, SR_Distance_Passed);
      end if;
      --  [67]: the level switches to 1 with a trip order received;
      --  [39]: to 1 or 2 without an MA (5.10, EVC_Levels). [39] has no
      --  override in its text: the override does not inhibit it
      if C.Switched_To_L1 and then EVC_Movement_Authority.Trip_Ordered then
         Trip (67, No_MA_Level_Switch);
      end if;
      if C.Level_Switched and then not EVC_Movement_Authority.MA_Present
      then
         Conds (39) := True;
         if Pending = No_Trip then
            Pending := No_MA_Level_Switch;
         end if;
      end if;
      --  [69]
      if C.Mode in M_FS | M_AD | M_LS | M_OS | M_SM then
         declare
            T : constant Origin_Table_T := Origin_Table;
         begin
            --  [69]: the estimated front end in rear of the start of a
            --  profile (the SSP or the gradients) stored on-board
            if EVC_Track_Description.Before_Profiles (T, S.Train.Est_Front)
            then
               Trip (69, No_Track_Description);
            end if;
         end;
      end if;
   end Trip_Step;

   ---------------------------------------------------------------------
   --  5. Post trip, reversing, BTM alarm reaction inhibition
   ---------------------------------------------------------------------

   procedure Post_Trip_Step (C : Context_T; S : Snapshot_T)
     with Global => (In_Out => (PT_Over, PT_SB, Status_List, Status_N,
                                Events, Event_N),
                     Input  => (PT_Start, PT_Sense))
   is
      Limit : constant Dist_T :=
        Diff (A (PT_Sense, PT_Start), S.National.D_NVPOTRP);
   begin
      if C.Mode /= M_PT then
         return;
      end if;
      --  4.4.14.1.3: the reverse movement over D_NVPOTRP from where PT
      --  was entered, counted opposite to the train orientation
      PT_Over := A (PT_Sense, S.Train.Est_Front) < Limit;
      --  3.14.1.7.4: released at standstill after acknowledgement
      if PT_SB and then S.Train.Standstill and then C.Brake_Release_Ack then
         PT_SB := False;
         Status (SS_PT_Distance_Exceeded, 1);
      end if;
      --  4.4.14.1.3, 4.4.14.1.3.2: overpassed, and any further movement
      --  opposite to the orientation while it is
      if PT_Over and then not PT_SB and then not S.Train.Standstill
        and then S.Train.Moving_Backwards
      then
         PT_SB := True;
         Status (SS_PT_Distance_Exceeded, 0);
         Record_Event (Event_PT_Distance, 1, 0);
      end if;
   end Post_Trip_Step;

   procedure Reversing_Step (C : Context_T; S : Snapshot_T)
     with Global => (Input  => (Rev, Orientation_Now),
                     In_Out => (Rev_Possible, RV_Over, RV_EB, Ack_On, Ack_M,
                                Ack_After, Ack_Since, Status_List, Status_N,
                                Events, Event_N))
   is
      use type EVC_Brake_Commands.Controller_T;
      Est : constant Dist_T := A (Rev.Sense, S.Train.Est_Front);
      Was : constant Boolean := Rev_Possible;
   begin
      --  5.13.1.3, 3.15.4.4, 3.15.4.7: at standstill with the front end
      --  inside the area, in a mode the transition [59] leaves
      Rev_Possible :=
        C.Mode in M_FS | M_AD | M_LS | M_OS
        and then Rev.Area and then Rev.Sup
        and then Rev.Sense = Orientation_Now
        and then S.Train.Standstill
        and then Est >= A (Rev.Sense, Rev.Start)
        and then Est <= A (Rev.Sense, Rev.Finish);
      if Rev_Possible and then not Was then
         Record_Event (Event_Reversing, 3, 0);
      end if;
      --  5.13.1.4: the driver's intention, the direction controller in
      --  reverse
      if Rev_Possible and then not Ack_On
        and then C.Controller = EVC_Brake_Commands.Backwards
      then
         Ack_On := True;
         Ack_M := M_RV;
         Ack_After := False;
         Ack_Since := C.Now_Ms;
         Record_Event (Event_Ack_Request, Mode_T'Pos (M_RV), 0);
      end if;
      --  4.4.18.1.3 b), 3.15.4.8: in RV, the end of the distance to run
      --  (3.15.4.2.1: from the end of the area) passed by the front end
      if C.Mode = M_RV then
         RV_Over :=
           Rev.Sup and then not Rev.Infinite
           and then Est < Diff (A (Rev.Sense, Rev.Finish), Rev.Distance);
         --  3.14.1.7.1: released when the distance is no longer
         --  overpassed, or at standstill after acknowledgement
         if RV_EB
           and then (not RV_Over
                     or else (S.Train.Standstill
                              and then C.Brake_Release_Ack))
         then
            RV_EB := False;
            Status (SS_RV_Distance_Exceeded, 1);
         end if;
         --  4.4.18.1.4: and again for any further reverse movement
         if RV_Over and then not RV_EB and then not S.Train.Standstill
           and then S.Train.Moving_Backwards
         then
            RV_EB := True;
            Status (SS_RV_Distance_Exceeded, 0);
            Record_Event (Event_Reversing, 4, 0);
         end if;
      end if;
   end Reversing_Step;

   procedure BMM_Step (C : Context_T; S : Snapshot_T)
     with Global => (Input  => (EVC_Driver_Requests.State,
                                EVC_Track_Conditions.State,
                                EVC_Origins.State),
                     In_Out => (BMM_On, BMM_From, Events, Event_N))
   is
      --  5.22.5.2.1: a BMM track condition starting within the 300 m
      --  ahead of where the procedure was triggered (along the sense of
      --  its store; one in which the train stood then starts in rear)
      --  shortens the distance to its start
      function BMM_Area_Reached (Front : Dist_T) return Boolean
        with Global => (Input => (EVC_Track_Conditions.State,
                                  EVC_Origins.State, BMM_From))
      is
         --  the store of the big metal masses is read in place
         Sn : constant Sense_T := EVC_Track_Conditions.BMM_Sense;
         T  : constant Origin_Table_T := Origin_Table;
         F  : constant Dist_T := A (Sn, BMM_From);
         Cur : constant Dist_T := A (Sn, Front);
      begin
         for I in 1 .. EVC_Track_Conditions.BMM_Count loop
            declare
               X : constant Dist_T :=
                 A (Sn, Frame (T, EVC_Track_Conditions.BMM_Item (I).Start,
                               Estimated_Item));
            begin
               if X > F and then Diff (X, F) <= BMM_Distance_Cm
                 and then Cur >= X
               then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end BMM_Area_Reached;
   begin
      --  5.22.2.1: at standstill, in level 1 or 2, in SB, SH or SR
      if EVC_Driver_Requests.BMM_Inhibition_Selected and then not BMM_On
        and then S.Train.Standstill
        and then C.Level_Valid and then C.Level in L1 | L2
        and then C.Mode in M_SB | M_SH | M_SR
      then
         BMM_On := True;
         BMM_From := S.Train.Est_Front;
         Record_Event (Event_BMM, 1, 0);
      elsif BMM_On then
         --  5.22.5.1 a) in either direction (5.22.5.2), c)
         if EVC_Driver_Requests.BMM_Revoke_Selected
           or else Abs_Dist (Diff (S.Train.Est_Front, BMM_From))
                     > BMM_Distance_Cm
           or else BMM_Area_Reached (S.Train.Est_Front)
         then
            BMM_On := False;
            Record_Event (Event_BMM, 0, 0);
         end if;
      end if;
   end BMM_Step;

   ---------------------------------------------------------------------
   --  Changing Train Data from sources different from the driver (5.17)
   ---------------------------------------------------------------------

   --  S6: the driver requested to re-enter or re-validate the data
   procedure TD_Request_Revalidation
     with Global => (Output => TD_Revalidate,
                     In_Out => (Events, Event_N))
   is
   begin
      TD_Revalidate := True;
      Record_Event (Event_Train_Data, 5, 0);
   end TD_Request_Revalidation;

   procedure Train_Data_Step (C : Context_T; S : Snapshot_T)
     with Global => (In_Out => (TD_Step, TD_Then_Revalidate, TD_Revalidate,
                                TD_Moving_Due, Status_List, Status_N,
                                Events, Event_N))
   is
      Standstill : constant Boolean := S.Train.Standstill;

      --  A1, then A7
      procedure Inform
        with Global => (Output => TD_Moving_Due,
                        In_Out => (Status_List, Status_N, Events, Event_N))
      is
      begin
         Status (SS_Train_Data_Changed, 0);
         Record_Event (Event_Train_Data, 2, 0);
         TD_Moving_Due := True;
         Record_Event (Event_Train_Data, 6, 0);
      end Inform;

      --  S2, S4: the service brake and the reason indicated
      procedure Brake (Then_Revalidate : Boolean)
        with Global => (Output => (TD_Step, TD_Then_Revalidate),
                        In_Out => (Status_List, Status_N, Events, Event_N))
      is
      begin
         TD_Step := TD_Brake;
         TD_Then_Revalidate := Then_Revalidate;
         Status (SS_Train_Data_Changed_Brake, 0);
         Record_Event (Event_Train_Data, 3, 0);
      end Brake;
   begin
      --  "Train data changed" is displayed for 30 s from a train
      --  movement (DMI Table 68: event 2)
      if TD_Moving_Due and then not Standstill then
         Status (SS_Train_Data_Changed, 2);
         TD_Moving_Due := False;
      end if;
      --  the re-validation is no longer asked once no valid Train Data
      --  are stored (they are entered again anyway)
      if TD_Revalidate and then not C.Train_Data_Valid then
         TD_Revalidate := False;
      end if;
      --  E2, E4: at standstill, the acknowledgement asked (S3, S5)
      if TD_Step = TD_Brake and then Standstill then
         TD_Step := TD_Ack;
      end if;
      --  E3, E5: acknowledged, the brake released (A5, A6), then A7 or S6
      if TD_Step = TD_Ack and then C.Brake_Release_Ack then
         TD_Step := TD_Idle;
         Status (SS_Train_Data_Changed_Brake, 1);
         Record_Event (Event_Train_Data, 4, 0);
         if TD_Then_Revalidate then
            TD_Request_Revalidation;
         else
            Record_Event (Event_Train_Data, 6, 0);
         end if;
      end if;
      --  S0, E0 (5.17.1.3: not in RV)
      if C.TD_Change and then C.Train_Data_Valid and then TD_Step = TD_Idle
        and then C.Mode in M_FS | M_AD | M_LS | M_OS | M_SR | M_SB | M_SN
                         | M_UN | M_TR | M_PT
      then
         Record_Event (Event_Train_Data, 1, 0);
         if C.TD_Validation then
            --  D2
            if C.Mode in M_TR | M_PT then
               TD_Step := TD_Wait_Trip;                    -- S1
            elsif Standstill then
               TD_Request_Revalidation;                    -- D9, S6
            else
               Brake (Then_Revalidate => True);            -- S4
            end if;
         elsif not C.TD_Category then
            Inform;                                        -- D1, A1
         elsif C.Mode in M_SB | M_PT | M_UN | M_SN | M_SR | M_TR then
            --  D3; D5: the MA and track description of an RBC (level 2,
            --  phase E5) are not stored
            Inform;                                        -- A1
         elsif Standstill then
            Inform;                                        -- D7, A1
         else
            Brake (Then_Revalidate => False);              -- S2
         end if;
      end if;
   end Train_Data_Step;

   ---------------------------------------------------------------------
   --  6. Passing a level crossing not protected (5.16)
   ---------------------------------------------------------------------

   --  The level crossing of the temporary EOA and SvL (Snapshot_T.LX):
   --  the substitution of its start by its speed restriction (5.16.2.1
   --  stopped in the stopping area, from the estimated front end;
   --  5.16.3.2 at the location of the Permitted speed supervision limit
   --  for V_LX, which EVC_SDM finds), the driver informed (5.16.1.4: the
   --  temporary EOA or SvL the most relevant displayed target, or the
   --  substitution) and 4.6.3 [9] when the indication starts
   procedure LX_Step (C : Context_T; S : Snapshot_T; SDM : EVC_SDM.Result_T)
     with Global => (In_Out => (EVC_Track_Description.State, Conds))
   is
      I   : constant Natural := S.LX.Index;
      Was : Boolean;
   begin
      if not S.LX.Present or else I not in 1 .. EVC_Track_Description.Max_LX
        or else C.Mode not in M_FS | M_AD | M_LS | M_OS | M_SM
      then
         return;
      end if;
      Was := EVC_Track_Description.LX_Item (I).Indicated;
      if S.LX.Stop then
         if S.Train.Standstill
           and then A (S.Train.Ahead, S.Train.Est_Front)
                      >= A (S.Train.Ahead, S.LX.Stop_From)
         then
            EVC_Track_Description.Release_LX (I, S.Train.Est_Front);
         end if;
      elsif SDM.LX_Release then
         EVC_Track_Description.Release_LX (I, SDM.LX_From);
      end if;
      if SDM.LX_MRDT then
         EVC_Track_Description.Indicate_LX (I);
      end if;
      --  [9]
      if not Was and then EVC_Track_Description.LX_Item (I).Indicated
        and then S.MA.Present
      then
         Conds (9) := True;
      end if;
   end LX_Step;

   ---------------------------------------------------------------------
   --  Evaluate
   ---------------------------------------------------------------------

   --  6. The conditions of 4.6.3 of this half that the steps of the
   --  cycle do not set themselves ([9] LX_Step, the trips Trip_Step):
   --  the driver's selections and acknowledgements, the desks, the mode
   --  profile (3.12.4), the level switched (5.10); Standstill: the train
   --  is at standstill
   procedure Set_Conditions (C : Context_T; Standstill : Boolean)
     with Global => (Input  => (Acked_Now, Acked_M, Stop_On_Desk,
                                Ovr_Selected_Now, Profile_Info,
                                EVC_Driver_Requests.State),
                     In_Out => Conds)
   is
      L_Valid : constant Boolean := C.Level_Valid;
   begin
      --  [5]
      Conds (5) := Standstill and then L_Valid
                   and then C.Level in L0 | NTC | L1
                   and then EVC_Driver_Requests.Shunting_Selected;
      --  [6]: level 2, the RBC (phase E5)
      --  [7], [62], [63], [68]: the train trip acknowledged
      declare
         Trip_Ack : constant Boolean :=
           Acked_Now and then Acked_M = M_TR and then Standstill;
      begin
         Conds (7) := Trip_Ack and then L_Valid and then C.Level in L1 | L2;
         Conds (62) := Trip_Ack and then L_Valid and then C.Level = L0
                       and then C.Train_Data_Valid;
         Conds (63) := Trip_Ack and then L_Valid and then C.Level = NTC
                       and then C.Train_Data_Valid;
         Conds (68) := Trip_Ack and then L_Valid
                       and then C.Level in L0 | NTC
                       and then not C.Train_Data_Valid;
      end;
      --  [9]: LX_Step; [11]: level 2 (phase E5)
      --  [15], [50], [70]: the acknowledgement of a request displayed
      Conds (15) := Acked_Now and then Acked_M = M_OS;
      Conds (50) := Acked_Now and then Acked_M = M_SH;
      Conds (70) := Acked_Now and then Acked_M = M_LS;
      --  [19]
      Conds (19) := EVC_Driver_Requests.Exit_Shunting_Selected
                    and then Standstill;
      --  [20]: the unconditional emergency stop (radio, phase E5)
      --  [22], [23]: Passive Shunting, a desk opened
      Conds (22) := C.Desk_Open and then Stop_On_Desk;
      Conds (23) := C.Desk_Open and then not Stop_On_Desk;
      --  [28], [30]: the desks closed ([26], [27] read "Continue
      --  Shunting on desk closure", EVC_Mission: EVC_Transition_Conditions)
      Conds (28) := not C.Desk_Open;
      Conds (30) := not C.Desk_Open and then not C.Passive_Shunting;
      --  [37]: "override" selected (Override_Step: 5.8.2.1)
      Conds (37) := Ovr_Selected_Now;
      --  [40], [72], [73], [74], [75], [76], [51] and those with the
      --  level transition, [34], [61], [71]
      Conds (40) := Profile_Info.Furthest = 0;
      Conds (72) := Profile_Info.Furthest = 2;
      Conds (73) := Profile_Info.Furthest = 0
                    and then not Profile_Info.In_LS_Ack;
      Conds (74) := Profile_Info.Furthest = 2
                    and then not Profile_Info.In_OS_Ack;
      Conds (75) := not Profile_Info.In_OS_Ack and then not Profile_Info.Any;
      Conds (76) := not Profile_Info.In_LS_Ack and then not Profile_Info.Any;
      Conds (51) := Profile_Info.SH_Reached;
      Conds (34) := Conds (40) and then C.Level_Switched;
      Conds (61) := Conds (51) and then C.Level_Switched;
      Conds (71) := Conds (72) and then C.Level_Switched;
      --  [59]: the reversing acknowledged at standstill
      Conds (59) := Acked_Now and then Acked_M = M_RV and then Standstill;
      --  [81]: the SM authorisation of the RBC (phase E5)
      --  [82]
      Conds (82) := EVC_Driver_Requests.Exit_SM_Selected
                    and then Standstill;

   end Set_Conditions;

   procedure Evaluate (C   : Context_T;
                       S   : Snapshot_T;
                       SDM : EVC_SDM.Result_T)
   is
      Standstill : constant Boolean := S.Train.Standstill;
   begin
      Ctx := C;
      Conds := (others => False);
      Pending := No_Trip;
      Event_N := 0;
      Status_N := 0;
      Now_Flags := (others => <>);
      Acked_Now := False;
      Orientation_Now := EVC_Position.Orientation;

      --  1.
      Take_Packets (C);
      --  3.12.4.4: the SH mode profile deleted for another reason than
      --  entering SH (a new MA, 3.12.4.3; a shortening), the list of
      --  balise groups for the SH area goes with it
      declare
         --  (EVC_Movement_Authority.SH_Profile: the profiles not copied)
         Now_SH : constant Boolean := EVC_Movement_Authority.SH_Profile;
      begin
         if SH_Profile_Seen and then not Now_SH and then C.Mode /= M_SH then
            SH_List_Known := False;
            SH_List_N := 0;
         end if;
         SH_Profile_Seen := Now_SH;
      end;
      Linking_Events;
      if Now_Flags.Link_SB
        and then C.Mode in M_FS | M_AD | M_LS | M_OS | M_SM
      then
         --  3.16.2.3.1, 3.14.1.6: the service brake to standstill;
         --  3.16.2.6.1: the driver is informed that the intervention is
         --  due to a data consistency problem with the expected group
         --  ("Balise read error", the DMI's entry 1)
         if not Link_SB then
            Status (SS_Balise_Read_Error_Brake, 0);
         end if;
         Link_SB := True;
      end if;
      --  2.
      Override_Step (C, S);
      --  3.
      Profiles_Step (C, S);
      --  the driver acknowledges the request displayed
      if Ack_On and then C.Mode_Ack then
         Acked_Now := True;
         Acked_M := Ack_M;
         Ack_On := False;
         --  3.14.1.7.3: the brake of the missing acknowledgement is
         --  released with it
         Ack_SB := False;
         Record_Event (Event_Ack_Given, Mode_T'Pos (Acked_M), 0);
      end if;
      --  4.
      Trip_Step (C, S, SDM);
      --  5.
      Post_Trip_Step (C, S);
      Reversing_Step (C, S);
      BMM_Step (C, S);
      LX_Step (C, S, SDM);
      Train_Data_Step (C, S);

      --  6. The conditions of 4.6.3 of this half
      Set_Conditions (C, Standstill);

      Version_Seen := False;
   end Evaluate;

   ---------------------------------------------------------------------
   --  Mode_Changed
   ---------------------------------------------------------------------

   --  TR entered from From (5.11.2.2 A025): the trip and its reason
   --  (4.4.13.1.3): the first condition of the transition taken that
   --  held, else the first trip condition found in the cycle; its system
   --  status message (DMI Table 68); the override ends (5.8.4.1 i); no
   --  request for acknowledgement
   procedure Enter_Trip (From : Mode_T)
     with Global => (Input  => (Conds, Pending, EVC_Sessions.State,
                                EVC_Radio_Authority.State),
                     Output => Ack_On,
                     In_Out => (Reason, Status_List, Status_N, Ovr, Events,
                                Event_N))
   is
      L : constant Condition_List_T := Conditions (From, M_TR);
      R : Trip_Reason_T := No_Trip;
   begin
      for I in L'Range loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         --  phase E5: [41] is the session half's (EVC_Sessions)
         if R = No_Trip and then L (I) in Condition_T
           and then (Conds (L (I))
                     or else (L (I) = 41
                              and then EVC_Sessions.T_NVCONTACT_Trip)
                     --  [36] is the authority half's
                     or else (L (I) = 36
                              and then EVC_Radio_Authority
                                         .Group_Not_In_SR_List))
         then
            R := Reason_Of (L (I));
         end if;
      end loop;
      if R = No_Trip then
         R := Pending;
      end if;
      if R /= No_Trip then
         Reason := R;
      end if;
      Status (Trip_Entry (Reason), 0);
      Record_Event (Event_Trip, Trip_Reason_T'Pos (Reason), 0);
      --  5.8.4.1 i)
      End_Override (9);
      Ack_On := False;
   end Enter_Trip;

   --  OS, LS or SH (To) entered: the override ends (5.8.4.1 i); the speed
   --  of the mode profile, of the acknowledgement or of the area
   --  (3.12.4); entered by the order of the trackside, the
   --  acknowledgement is asked now (5.7.2.3, 5.9.2.3, 5.19.2.3)
   procedure Enter_Profile_Mode (To : Mode_T; C : Context_T)
     with Global => (Input  => (Acked_Now, Acked_M, Conds, Profile_Info,
                                EVC_Radio_Authority.State),
                     Output => Use_V,
                     In_Out => (Ovr, Ack_On, Ack_M, Ack_After, Ack_Since,
                                Ack_V, SH_List_Known, SH_List_N, SH_List,
                                Events, Event_N))
   is
   begin
      End_Override (9);
      if Acked_Now and then Acked_M = To then
         --  [15], [50], [70]: entered with the acknowledgement
         Use_V := Ack_V;
      elsif To = M_SH and then not Conds (51) and then not Conds (61)
      then
         --  [5], [23], [68] (the driver, Passive Shunting, the
         --  trip): no acknowledgement, the national value
         Use_V := 127;
         if Conds (5) then
            --  5.6.2.2 A050: the list of the SH area is deleted
            --  (level 0 or 1: no new one)
            SH_List_Known := False;
            SH_List_N := 0;
         elsif EVC_Radio_Authority.Shunting_Granted then
            --  [6], level 2: deleted or replaced by the list of the
            --  authorisation (EVC_Radio_Authority, packet 49)
            Take_Radio_SH_List;
         end if;
      else
         --  [40], [72], [73], [74], [51], [34], [61], [71]: entered
         --  by the order of the trackside, the acknowledgement is
         --  asked now (5.7.2.3, 5.7.3.6, 5.9.2.3, 5.9.3.7,
         --  5.19.2.3, 5.19.3.7); 5.9.2.7, 5.19.2.7 do not apply as
         --  the mode was another one
         Use_V := (if To = M_SH then Profile_Info.SH_V
                   else Profile_Info.Furthest_V);
         Ack_On := True;
         Ack_M := To;
         Ack_After := True;
         Ack_Since := C.Now_Ms;
         Ack_V := Use_V;
         Record_Event (Event_Ack_Request, Mode_T'Pos (To), 1);
      end if;
   end Enter_Profile_Mode;

   --  The mode From left for To: PT or TR (the trip reason no longer
   --  indicated, DMI Table 68; 4.12: the reverse movement distance of PT
   --  revoked), RV (4.12), SR (5.8.3.1.3 b: the former EOA/LOA deleted)
   procedure Leave_Mode (From, To : Mode_T)
     with Global => (In_Out => (Reason, Status_List, Status_N, PT_SB,
                                PT_Over, RV_EB, RV_Over, Former,
                                Former_Passed))
   is
   begin
      if From = M_PT or else (From = M_TR and then To /= M_PT) then
         --  the trip reason is no longer indicated (DMI Table 68: "PT
         --  mode left", [62], [63], [68]); 4.12: the reverse movement
         --  distance of PT revoked
         Status (Trip_Entry (Reason), 1);
         Reason := No_Trip;
         if PT_SB then
            Status (SS_PT_Distance_Exceeded, 1);
         end if;
         PT_SB := False;
         PT_Over := False;
      end if;
      if From = M_RV then
         if RV_EB then
            Status (SS_RV_Distance_Exceeded, 1);
         end if;
         RV_EB := False;
         RV_Over := False;
      end if;
      --  5.8.3.1.3 b)
      if From = M_SR then
         Former := False;
         Former_Passed := False;
      end if;
   end Leave_Mode;

   --  The change of Train Data (5.17) on entering To: 4.12, its brake
   --  while running revoked; 5.17.2.2 E1, D4, the trip procedure exited
   procedure Train_Data_Mode_Entered (To : Mode_T)
     with Global => (In_Out => (TD_Step, TD_Revalidate, Status_List,
                                Status_N, Events, Event_N))
   is
   begin
      --  4.12: the brake of a change of Train Data while running is
      --  revoked on entering NP, SB, SH, SM, SL, NL, maintained otherwise
      if TD_Step in TD_Brake | TD_Ack
        and then To in M_NP | M_SB | M_SH | M_SM | M_SL | M_NL
      then
         TD_Step := TD_Idle;
         Status (SS_Train_Data_Changed_Brake, 1);
      end if;

      --  5.17.2.2 E1, D4: the trip procedure exited, the re-validation
      --  (S6) in FS, LS, OS, SR, SN, UN; in SH the Train Data are invalid
      --  already (4.6.3 [68]): the procedure ends
      if TD_Step = TD_Wait_Trip and then To not in M_TR | M_PT then
         TD_Step := TD_Idle;
         if To in M_FS | M_LS | M_OS | M_SR | M_SN | M_UN then
            TD_Request_Revalidation;
         end if;
      end if;
   end Train_Data_Mode_Entered;

   --  The information of this unit deleted on entering To (4.10: "Stop
   --  Shunting on desk opening", the list of balise groups for the SH
   --  area, the reversing information; 5.22.5.1 b: the big metal masses
   --  inhibition; 4.12: the brake of the linking inconsistency, revoked
   --  on NP and SB)
   procedure Delete_On_Mode_Entry (To : Mode_T)
     with Global => (Output => Rev_Possible,
                     In_Out => (Stop_On_Desk, SH_List_Known, SH_List_N,
                                Rev, BMM_On, Link_SB, Events, Event_N))
   is
   begin
      --  4.10: "Stop Shunting on desk opening", the list of balise groups
      --  for the SH area, the reversing information
      if To in M_NP | M_SB | M_SM | M_SL then
         Stop_On_Desk := False;
      end if;
      if To in M_NP | M_SB | M_SM | M_SR | M_SL | M_NL | M_UN | M_TR | M_SN
             | M_RV
      then
         SH_List_Known := False;
         SH_List_N := 0;
      end if;
      if To in M_NP | M_SB | M_PS | M_SH | M_SM | M_SR | M_SL | M_NL | M_UN
             | M_TR | M_SN
      then
         Rev := (others => <>);
      end if;
      Rev_Possible := False;

      --  5.22.5.1 b)
      if BMM_On and then To not in M_SB | M_SH | M_SR then
         BMM_On := False;
         Record_Event (Event_BMM, 0, 0);
      end if;
      --  4.12: the linking inconsistency revoked on NP and SB
      if To in M_NP | M_SB then
         Link_SB := False;
      end if;
   end Delete_On_Mode_Entry;

   procedure Mode_Changed (From, To : Mode_T; C : Context_T;
                           S : Snapshot_T)
   is
   begin
      --  The request for acknowledgement of the mode left, and its brake
      --  (4.12: "mode change to OS / SH / LS not acknowledged" revoked
      --  on leaving the mode); a request for another mode ends with a
      --  transition elsewhere
      if Ack_On and then (Ack_After or else Ack_M /= To) then
         Ack_On := False;
      end if;
      Ack_SB := False;
      Ack_After := False;

      --  The mode entered
      case To is
         when M_TR =>
            Enter_Trip (From);
         when M_PT =>
            --  4.4.14.1.3: the reverse movement is counted from here
            PT_Start := S.Train.Est_Front;
            PT_Sense := Orientation_Now;
            PT_Over := False;
            PT_SB := False;
         when M_OS | M_LS | M_SH =>
            Enter_Profile_Mode (To, C);
         when M_RV =>
            RV_Over := False;
            RV_EB := False;
         when others =>
            null;
      end case;

      --  The mode left
      Leave_Mode (From, To);
      Train_Data_Mode_Entered (To);
      Delete_On_Mode_Entry (To);

      if To = M_TR then
         Demand.EB := True;
         Demand.Trip := True;
      end if;
   end Mode_Changed;

   ---------------------------------------------------------------------
   --  Finish_Cycle
   ---------------------------------------------------------------------

   procedure Finish_Cycle (C : Context_T; Mode : Mode_T; S : Snapshot_T) is
   begin
      --  5.11.2.2 S060, 4.4.13.1.4: the acknowledgement of the trip is
      --  asked once the train is at standstill
      if Mode = M_TR and then S.Train.Standstill
        and then not (Ack_On and then Ack_M = M_TR)
      then
         Ack_On := True;
         Ack_M := M_TR;
         Ack_After := False;
         Ack_Since := C.Now_Ms;
         Record_Event (Event_Ack_Request, Mode_T'Pos (M_TR), 0);
      end if;
      --  T_ACK after the transition: the service brake until the driver
      --  acknowledges (3.14.1.7.3)
      if Ack_On and then Ack_After and then Ack_M = Mode and then not Ack_SB
        and then C.Now_Ms >= Ack_Since
        and then C.Now_Ms - Ack_Since >= T_Ack_Ms
      then
         Ack_SB := True;
      end if;
      --  3.14.1.6: released at standstill; the message stays 30 s from
      --  then (the DMI's entry 1, event 2)
      if Link_SB and then S.Train.Standstill then
         Link_SB := False;
         Status (SS_Balise_Read_Error_Brake, 2);
      end if;
      Demand :=
        (EB           => Mode = M_TR or else RV_EB,
         SB           => Ack_SB or else PT_SB or else Link_SB
                         or else TD_Step in TD_Brake | TD_Ack,
         Trip         => Mode = M_TR,
         Ack_Missing  => Ack_SB,
         Other        => PT_SB or else RV_EB or else Link_SB
                         or else TD_Step in TD_Brake | TD_Ack,
         Ack_Required => S.Train.Standstill
                         and then (PT_SB or else RV_EB
                                   or else TD_Step = TD_Ack));
      if Demand.EB /= Demand_Sent.EB or else Demand.SB /= Demand_Sent.SB then
         Record_Event (Event_Brake, Boolean'Pos (Demand.EB),
                       Boolean'Pos (Demand.SB));
      end if;
      Demand_Sent := Demand;
   end Finish_Cycle;

end EVC_Procedures;
