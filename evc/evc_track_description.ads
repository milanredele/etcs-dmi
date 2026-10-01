--  ETCS on-board (EVC)
--  The track description the on-board stores (SUBSET-026 3.7, 3.11,
--  3.12.2, 3.12.5): static speed profile (packet 27), gradients (21),
--  axle load speed profile (51), the speed restriction to ensure a
--  permitted braking distance (52), temporary speed restrictions (65,
--  66), the default gradient for TSR (141), level crossings (88),
--  adhesion (71) and route suitability (70).
--
--  Every location is an offset from the origin of the group message
--  that gave it (EVC_Profiles), so that relocation (3.6.4.2.5) moves the
--  information with its reference. A profile of one message is a list
--  of elements [start, end) with a value; the last element of a
--  continuous profile is open ended unless the packet ends it
--  (3.6.3.2.2 d): V_STATIC 127, G_A 255.
--
--  Replacement (3.7.3.1): a new SSP, gradient profile or adhesion
--  information replaces the stored one from the start location of the
--  new information (a, b, l), a new ASP or PBD information from the
--  start of its first element (c, d): the stored elements beyond it go,
--  the element across it ends there (Cut_Beyond on the "estimated"
--  items). Its "min" and "max" items stay those of the two locations,
--  so that when a relocation by 3.6.4.2.5 b) or c) made them differ,
--  the envelope of the MRSP and of the gradients takes the lowest of
--  both over the distance between them: 3.7.3.1.1 to 3.7.3.1.4 follow
--  from Table 2a. New route suitability data of a type replaces all of
--  that type (h, i, j). A TSR replaces the one of the same identity
--  unless it is not revocable (3.11.5.9); an LX information replaces
--  the one of the same identity (3.12.5.3). Q_TRACKINIT resumes the
--  initial state from D_TRACKINIT (3.7.3.2 a, b, d).
--
--  The speed restriction to ensure a permitted braking distance (3.11.11,
--  packet 52): a section is an element [D_PBDSR, D_PBDSR + L_PBDSR) of
--  the store PBD, front end only (Table 2a: its end is a "min" item,
--  3.13.7.2), keeping its order (the permitted braking distance in Id,
--  cm, its gradient and brake: Stored_T); its Value, the speed V_PBD,
--  is computed by EVC_PBD in Compute_PBD, which the stored information
--  calls every cycle before the MRSP: the sections not computed yet, or
--  all of them when the inputs of the computation changed (3.11.11.3).
--  Until the first packet 52 (and beyond its sections) there is no
--  restriction (3.11.11.11).
--
--  Gaps in the continuous profiles, the SSP and the gradients (3.6.3.2.2
--  a, d: every value holds up to the next change; 3.6.4.2.6; 3.11.12.2:
--  the gradient profile gives a value for each location of the track it
--  covers). An element runs from the "max" item of its start to the
--  "min" item of its end; where a relocation by 3.6.4.2.5 c) put the
--  "max" item of a change ahead of its "min" item (the new reference
--  less accurate than the former one), the element before the change
--  and the one after it leave a gap. The gap lies inside the profile,
--  so it is covered: for the gradients it is not a location of
--  3.13.4.1.3, for the SSP the MRSP does not fall back to the maximum
--  train speed there. Table 2a places the change inside the gap:
--  - gradients, by the curve (the EBD: a change to a lower value at the
--    "max" item, to a higher one at the "min" item; the SBD and the GUI:
--    the "estimated" item), so that every curve reads one of the two
--    neighbouring gradients there;
--  - the SSP (3.13.7.2 with 3.11.2.2 a): a change to a lower speed at
--    its "max" item, the far end of the gap, a change to a higher speed
--    at its "min" item, the near end, so that read literally the higher
--    neighbour would hold over the gap (3.6.4.2.5.4: relocation c) does
--    not change what is compared with the min and max safe front ends).
--  The one gradient profile and the one MRSP of the snapshot take the
--  lower of the two neighbours over the whole gap (Add_Gaps, for both
--  profiles), never above what any curve or Table 2a reads there: the
--  safe side on a downhill and for the speed, as the rules 3.6.4.2.6
--  and 3.7.3.1.1 are where the elements overlap ("the lowest parts").
--  Where the rear end counts (Q_FRONT, 3.11.3.1.3) the element before
--  the change ends a train length later, and the gap, if any, begins
--  there. The start and the end of a profile are left as they are.
--
--  Train categories (3.11.3.2.3, 3.11.3.2.6): the speed of each SSP
--  element is chosen for the train when the packet is received (a change
--  of the categories at standstill deletes the SSP, A.3.4.1.2 j, E4).
--  The ASP takes the speed of the train's axle load category (3.11.4.3);
--  an element without it restricts nothing.
--
--  Not here: the comparison of route suitability with the train data
--  and its reaction (3.12.2.3, 3.12.2.4, phases E4 and E6), the
--  inhibition of revocable TSRs from balises by the RBC (3.11.5.12 to
--  .14, E5).

pragma Unevaluated_Use_Of_Old (Allow);

with ETCS_Track_Packets.P21;
with ETCS_Track_Packets.P27;
with ETCS_Track_Packets.P51;
with ETCS_Track_Packets.P52;
with ETCS_Track_Packets.P65;
with ETCS_Track_Packets.P66;
with ETCS_Track_Packets.P70;
with ETCS_Track_Packets.P71;
with ETCS_Track_Packets.P88;
with ETCS_Track_Packets.P141;
with ETCS_Variables;        use ETCS_Variables;
with EVC_Distances;         use EVC_Distances;
with EVC_PBD;
with EVC_Profiles;          use EVC_Profiles;
with EVC_Supervision_Input; use EVC_Supervision_Input;
with EVC_Train_Data;

package EVC_Track_Description
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  A.3.1: information more than this in rear of the min safe rear end
   --  is deleted
   Keep_In_Rear : constant Length_T := 30_000;

   function SSP return Store_T
     with Global => State;
   function Gradients return Store_T
     with Global => State;
   function ASP return Store_T
     with Global => State;
   --  Id: NID_TSR
   function TSR return Store_T
     with Global => State;
   --  Value 0: a slippery rail area
   function Adhesion_Store return Store_T
     with Global => State;
   --  The sections of the speed restriction to ensure a permitted braking
   --  distance: Value V_PBD (cm/s) once Noted, Id the permitted braking
   --  distance (cm), Gradient, Service
   function PBD return Store_T
     with Global => State;

   --  3.11.12.5, 3.11.12.6: the default gradient for TSR
   function Default_Gradient_Known return Boolean
     with Global => State;
   function Default_Gradient return Gradient_T
     with Global => State;

   --  Level crossings (packet 88)
   Max_LX : constant := 16;
   type LX_T is record
      Used          : Boolean := False;
      Id            : NID_LX_T := 0;
      Start         : Location_T;
      Finish        : Location_T;
      Protected_LX  : Boolean := True;
      Speed         : Speed_Cms_T := 0;       -- V_LX, not protected
      Stop_Required : Boolean := False;
      Stop_Length   : Length_T := 0;          -- L_STOPLX
      Msg           : Natural := 0;
   end record;
   type LX_Array_T is array (1 .. Max_LX) of LX_T;

   function LX return LX_Array_T
     with Global => State;
   function LX_Sense return Sense_T
     with Global => State;

   --  Route suitability data (packet 70): at a location, a type
   --  (Q_SUITABILITY 0 loading gauge, 1 axle load, 2 traction system)
   --  and its value (M_LINEGAUGE, M_LINEAXLELOADCAT, M_VOLTAGE)
   Max_Suitability : constant := 32;
   type Suitability_T is record
      Used     : Boolean := False;
      At_Loc   : Location_T;
      Kind     : Natural range 0 .. 2 := 0;
      Value    : Natural range 0 .. 65_535 := 0;
      Traction : NID_CTRACTION_T := 0;
      Msg      : Natural := 0;
   end record;
   type Suitability_Array_T is array (1 .. Max_Suitability) of Suitability_T;

   function Suitability return Suitability_Array_T
     with Global => State;

   --  Information that found no room in its store, since Clear
   function Lost return Natural
     with Global => State;

   ---------------------------------------------------------------------
   --  Reception: packets of a group message M (M.Origin /= 0)
   ---------------------------------------------------------------------

   procedure Clear
     with Global => (Output => State),
          Post => SSP.Count = 0 and then Gradients.Count = 0
                  and then ASP.Count = 0 and then TSR.Count = 0
                  and then PBD.Count = 0
                  and then not Default_Gradient_Known;

   --  The speed of an SSP element for the train (3.11.3.2.3, 3.11.3.2.6)
   type Diff_T is record
      Q_DIFF : Q_DIFF_T := 0;
      NC     : Natural range 0 .. 15 := 0;   -- NC_CDDIFF or NC_DIFF
      V_DIFF : V_DIFF_T := 0;
   end record;
   type Diff_Array is array (1 .. 31) of Diff_T;

   function Train_Speed (V_STATIC : V_STATIC_T;
                         N        : Natural;
                         Diffs    : Diff_Array;
                         C        : EVC_Train_Data.Categories_T)
     return Speed_Cms_T
     with Pre => N <= 31;

   procedure Take_SSP (P : ETCS_Track_Packets.P27.Packet_T;
                       M : Message_T;
                       T : Origin_Table_T;
                       C : EVC_Train_Data.Categories_T)
     with Global => (In_Out => State);

   procedure Take_Gradients (P : ETCS_Track_Packets.P21.Packet_T;
                             M : Message_T;
                             T : Origin_Table_T)
     with Global => (In_Out => State);

   procedure Take_ASP (P    : ETCS_Track_Packets.P51.Packet_T;
                       M    : Message_T;
                       T    : Origin_Table_T;
                       Axle : M_AXLELOADCAT_T)
     with Global => (In_Out => State);

   --  3.11.11.2, 3.7.3.1 d), 3.7.3.2 a)
   procedure Take_PBD (P : ETCS_Track_Packets.P52.Packet_T;
                       M : Message_T;
                       T : Origin_Table_T)
     with Global => (In_Out => State);

   --  3.11.11.3: V_PBD of the sections not computed yet (every section
   --  with All_Sections: the inputs changed), from the inputs I; Computed
   --  the number of sections computed
   procedure Compute_PBD (I            : EVC_PBD.Inputs_T;
                          All_Sections : Boolean;
                          Computed     : out Natural)
     with Global => (In_Out => State),
          Post => (for all K in 1 .. PBD.Count => PBD.List (K).Noted);

   procedure Take_TSR (P : ETCS_Track_Packets.P65.Packet_T;
                       M : Message_T;
                       T : Origin_Table_T)
     with Global => (In_Out => State);

   --  3.11.5.5, 3.11.5.8: the TSRs of the identity go, at once and
   --  without delay for the train length; a non revocable one (NID_TSR
   --  255) stays
   procedure Revoke_TSR (P       : ETCS_Track_Packets.P66.Packet_T;
                         Revoked : out Natural)
     with Global => (In_Out => State),
          Post => TSR.Count = TSR.Count'Old - Revoked;

   procedure Take_Default_Gradient (P : ETCS_Track_Packets.P141.Packet_T)
     with Global => (In_Out => State),
          Post => Default_Gradient_Known;

   procedure Take_LX (P : ETCS_Track_Packets.P88.Packet_T;
                      M : Message_T;
                      T : Origin_Table_T)
     with Global => (In_Out => State);

   procedure Take_Adhesion (P : ETCS_Track_Packets.P71.Packet_T;
                            M : Message_T;
                            T : Origin_Table_T)
     with Global => (In_Out => State);

   procedure Take_Suitability (P : ETCS_Track_Packets.P70.Packet_T;
                               M : Message_T;
                               T : Origin_Table_T)
     with Global => (In_Out => State);

   ---------------------------------------------------------------------
   --  Deletion
   ---------------------------------------------------------------------

   --  A.3.4.1.3 [1] and [10]: the gradients, the SSP, the ASP, the PBD
   --  information and the route suitability data of the messages before
   --  Before_Msg, from the frame position X (the location To) on; TSRs,
   --  level crossings, the adhesion and the default gradient are
   --  unchanged
   procedure Delete_Beyond (T          : Origin_Table_T;
                            X          : Dist_T;
                            To         : Location_T;
                            Before_Msg : Natural)
     with Global => (In_Out => State);

   --  A.3.1: what ends more than Keep_In_Rear behind the min safe rear
   --  end Rear
   procedure Delete_Behind (T : Origin_Table_T; Rear : Dist_T)
     with Global => (In_Out => State);

   --  3.11.5.10: the orientation changed, every TSR is deleted
   procedure Delete_TSRs
     with Global => (In_Out => State),
          Post => TSR.Count = 0;

   --  Added by the procedures of phase E4 (e4/procedures): the track
   --  description of 3.7.1.1 c) the procedures delete, the SSP, the
   --  gradients, the ASP, the speed restriction to ensure a permitted
   --  braking distance and the route suitability data, and with LX the
   --  level crossings (5.11.2.2 A035: on a train trip all of it but the
   --  track conditions, which EVC_Track_Conditions keeps; 4.10 deletes
   --  the level crossings with it). The TSRs, the default gradient for
   --  TSR and the adhesion stay.
   procedure Delete_Description (LX : Boolean)
     with Global => (In_Out => State),
          Post => SSP.Count = 0 and then Gradients.Count = 0
                  and then ASP.Count = 0 and then PBD.Count = 0;

   procedure Mark (Marks : in out Origin_Marks_T)
     with Global => State;

   ---------------------------------------------------------------------
   --  For the snapshot
   ---------------------------------------------------------------------

   --  The speed restrictions (SSP, ASP, TSR, LX not protected, PBD SR:
   --  3.11.2 a, b, c, i, k) as elements along Ahead, their end moved by
   --  Length where the rear end counts (3.11.3.1.3, 3.11.4.6, 3.11.5.3;
   --  the PBD SR by the front end only, Table 2a), with the gaps a
   --  relocation leaves between two SSP elements filled with the lower
   --  one (see the header)
   procedure Speed_Elements (T      : Origin_Table_T;
                             Ahead  : Sense_T;
                             Length : Length_T;
                             E      : in out Elements_T)
     with Global => State,
          Post => E.Count >= E.Count'Old;

   --  3.13.4.1.3 a): a TSR, as an element of Speed_Elements, overlaps
   --  [From, To) along Ahead with a speed at most V (a step of the MRSP
   --  of that speed is then due to a TSR)
   function TSR_Limits (T      : Origin_Table_T;
                        Ahead  : Sense_T;
                        Length : Length_T;
                        From   : Cm_T;
                        To     : Cm_T;
                        V      : Value_T) return Boolean
     with Global => State;

   --  The gradient profile as elements along Ahead (signed per mille),
   --  with the gaps a relocation leaves between two of them filled with
   --  the lower one (see the header)
   procedure Gradient_Elements (T     : Origin_Table_T;
                                Ahead : Sense_T;
                                E     : in out Elements_T)
     with Global => State;

   --  3.13.2.3.5: the slippery rail areas, frame positions
   procedure Adhesion_Areas (T     : Origin_Table_T;
                             Ahead : Sense_T;
                             Areas : in out Adhesion_T)
     with Global => State;

   --  3.7.2.3: the SSP and the gradients cover From .. To (frame
   --  positions along Ahead)
   function Covered (T : Origin_Table_T; Ahead : Sense_T; From, To : Dist_T)
     return Boolean
     with Global => State;

   --  3.12.5.8: the start of the nearest level crossing not protected
   --  that the estimated front end Front has not reached, a temporary
   --  EOA and SvL (Found False when none)
   procedure LX_Target (T     : Origin_Table_T;
                        Ahead : Sense_T;
                        Front : Dist_T;
                        Found : out Boolean;
                        EOA   : out Dist_T;
                        SvL   : out Dist_T)
     with Global => State;

end EVC_Track_Description;
