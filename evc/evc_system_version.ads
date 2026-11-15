--  ETCS on-board (EVC)
--  The operated system version: SUBSET-026 3.17.2 and the envelope of
--  6.4.2, by radio (Follow) and by balise (Take_Balise_Group: 3.17.2.3
--  .. .7, 3.17.3.3 .. .4).
--
--  6.4.2.1, 6.4.2.2: the highest system version this on-board supports
--  is 3.0, so its envelope is the full one, 1.0 up to 3.0: X = 1, 2 and
--  3 (3.17.2.1). 3.17.2.1.1: within one X it operates the highest Y of
--  its envelope, whatever Y the trackside sends: 1.1, 2.3 and 3.0
--  (6.4.1.2: the Y a trackside may use under each X).
--
--  3.17.2.2: one version operated at a time, its X held here. 3.17.2.8:
--  while a communication session is established with the RBC, the RBC's
--  X takes precedence. Decisions (3.17.2.8 a, b, d, e and .8.1 / .8.2),
--  applied by Follow once a cycle (EVC_Sessions.Evaluate):
--    - the RBC's X is operated from the cycle in which the on-board is
--      in level 2 with an established session whose version is known and
--      compatible: at once when already in level 2 (b, start of mission
--      or the RBC's order), at the execution of the transition when
--      entering (a: the cycle after EVC_Levels changed the level);
--    - out of level 2, or without that session (d, e), the operated
--      version is the one last operated: the control in relation to the
--      non-RBC constituents applies again from there (3.17.2.3);
--    - c, the accepting RBC at the border, comes with the handover
--      (3.15.1): the accepting RBC then becomes the supervising one;
--    - .8.1 / .8.2 (the balise group that ordered the transition checked
--      again with the new version): the telegram decoder knows the one
--      layout of 4.0.0, nothing to check again (the layouts of chapter 6
--      are not translated).
--  3.17.2.9: the operated version is kept over No Power (EVC_Retained);
--  3.17.2.9.1: lost, the highest supported one (Restore).
--
--  6.6.2, 6.6.4: the rules that differ from those of 3.0 with X = 1 or
--  X = 2 operated, one record of Booleans (Rules_Of, from the operated X
--  and the supervising RBC's version); the version of an RBC by X and Y
--  (Below) for the clauses of one session's messages.

with ETCS_Variables; use ETCS_Variables;

--  @req 3.17.2.1
package EVC_System_Version
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   pragma Unevaluated_Use_Of_Old (Allow);

   --  3.17.2.1, 6.4.2: the X of the envelope
   subtype Major_T is Natural range 1 .. 3;
   Lowest_X  : constant Major_T := 1;
   --  @req 3.17.3.5 d), 6.4.2.1
   Highest_X : constant Major_T := 3;

   --  7.5.1.79: X, the three most significant bits of M_VERSION
   function Major (V : M_VERSION_T) return Natural is (Natural (V) / 16);

   --  3.5.3.7 d), 3.17.3.7: a version of the trackside is compatible
   --  when its X is in the envelope
   --  @req 3.17.3.7
   function Compatible (V : M_VERSION_T) return Boolean is
     (Major (V) in Lowest_X .. Highest_X);

   --  7.5.1.79: Y, the four least significant bits of M_VERSION
   function Minor (V : M_VERSION_T) return Natural is (Natural (V) mod 16);

   --  The version V is below X.Y: an RBC of 2.0, 2.1 or 2.2 (6.6.4.1.1,
   --  6.6.4.3.1, the tables of 6.6.5.3 to 6.6.5.5) is Major 2 and below
   --  2.3, one of 2.0 or 2.1 (6.6.4.2.2) Major 2 and below 2.2, one
   --  that knows neither Supervised Manoeuvre nor message 38 below 2.3
   function Below (V : M_VERSION_T; X, Y : Natural) return Boolean is
     (Major (V) < X or else (Major (V) = X and then Minor (V) < Y));

   --  3.5.3.7 e), 3.5.4.6: the RBC acknowledges the session established
   --  report (message 38), except an RBC of 1.x or 2.0 .. 2.2, for which
   --  6.5.2.2.2 (X = 2) and 6.5.1.2 (X = 1) replace 3.5.3.7 e) and
   --  3.5.4.6 by 6.5.1.2.1.4 / .5 (no acknowledgement): the on-board
   --  does not await it then (3.5.3.7.4 does not apply; 6.6.3.4.1.2 for
   --  X = 1, applied to 2.0, 2.1 and 2.2 by 6.6.5.3.3, 6.6.5.4.2 and
   --  6.6.5.5.2)
   --  @req 3.5.3.7.4
   --  @req 6.6.3.4.1.2, 6.6.5.3.3, 6.6.5.4.2, 6.6.5.5.2
   function Session_Acknowledged (V : M_VERSION_T) return Boolean is
     (not Below (V, 2, 3));

   --  3.17.2.1.1: the Y operated within X
   --  @req 3.17.2.1.1
   function Operated_Y (X : Major_T) return Natural is
     (case X is when 1 => 1, when 2 => 3, when 3 => 0);

   --  The M_VERSION of X.Y (7.5.1.79)
   function Version_Of (X : Major_T) return M_VERSION_T is
     (M_VERSION_T (X * 16 + Operated_Y (X)));

   --  7.4.3.3 (packet 2 of message 159): the versions of the envelope,
   --  the highest first, then N_ITER more (6.4.2.2: 1.0 up to 3.0)
   Envelope_Count : constant := 7;
   type Envelope_T is array (1 .. Envelope_Count) of M_VERSION_T;
   --  @req 6.4.2.2
   Envelope : constant Envelope_T := (48, 35, 34, 33, 32, 17, 16);

   --  The rules of 6.6.2 and 6.6.4 that differ from those of 3.0, one
   --  Boolean each, named by what it switches: all False with X = 3
   --  operated. Computed once a cycle by Rules_Of from the operated X
   --  and the version of the supervising RBC, passed by the cycle's
   --  steps. Read today: No_Supervised_Manoeuvre
   --  (EVC_Sessions.Manoeuvre.Evaluate); the others are read by nothing
   --  yet and stand with their clause for the units that will apply them.
   --  The clauses of a message's own RBC (6.6.3.4, 6.6.4.3.2, 6.6.5.3 to
   --  6.6.5.5) and of a text's source (6.6.4.2.2) are not here: they are
   --  decided by that session or that text (Below)
   type Rules_T is record
      --  6.6.2.1.1: "the driver acknowledgement as always ending the
      --  text display, regardless of the end condition" (3.12.3.4.7.2)
      Ack_Ends_Text : Boolean := False;
      --  6.6.2.1.2, 6.6.2.2.3 (X = 1), 6.6.4.1.1, 6.6.4.2.1 (X = 2, the
      --  supervising RBC 2.0 .. 2.2): the front end of the train is the
      --  engine's, without the exceptions of 3.6.1.3.4 and 4.4.7.1.6 b)
      Engine_Front : Boolean := False;
      --  6.6.2.1.3, 6.6.4.1.2: in FS and OS a TSR starts and ends at its
      --  estimated location (3.6.4.2 Table 2a, the TSR row)
      TSR_Estimated : Boolean := False;
      --  6.6.2.1.4, 6.6.4.1.3: the most restrictive speed restriction of
      --  any axle load category lower than or equal to the train's, the
      --  categories in ascending order from A (3.11.4.3)
      ASP_Lower_Categories : Boolean := False;
      --  6.6.2.2.1, 6.6.2.2.2: "stop if in SR" trips the train whatever
      --  the list of balises of the RBC (4.4.11.1.3 d), 4.6.3 [54])
      SR_Stop_Always : Boolean := False;
      --  6.6.2.2.4 to 6.6.2.2.6: the sub-condition "Mode = FS" of the
      --  texts across Automatic Driving (4.4.9.1.8, 4.4.16.1.7, .8)
      Texts_FS_Across_AD : Boolean := False;
      --  6.6.2.3.1, 6.6.2.3.2, 6.6.2.3.6, 6.6.2.3.7 (X = 1), 6.6.4.3.1
      --  (X = 2, the supervising RBC 2.0 .. 2.2): no Supervised
      --  Manoeuvre: S10 and S140 do not offer it, 5.4.5.3 k) and 5.21
      --  do not apply
      No_Supervised_Manoeuvre : Boolean := False;
      --  6.6.2.3.3 to 6.6.2.3.5: at the end of mission the RBC's request
      --  to terminate awaited, the 150 repeated (with X = 2 the
      --  session's own RBC decides, 6.6.4.3.2)
      EoM_Awaits_Termination : Boolean := False;
   end record;

   --  The supervising RBC of 2.0, 2.1 or 2.2 (6.6.4.1.1, 6.6.4.2.1,
   --  6.6.4.3.1; one of 2.3 behaves as 3.0): Known, its version V known
   function RBC_2_0_To_2_2 (Known : Boolean; V : M_VERSION_T) return Boolean
   is (Known and then Major (V) = 2 and then Below (V, 2, 3));

   --  6.6.1.1: the rules for the operated X and the supervising RBC
   --  (Known: its version V known)
   function Rules_Of (X : Major_T; Known : Boolean; V : M_VERSION_T)
     return Rules_T
     --  one comparison of the whole record, each component by its
     --  condition
     with Post =>
       Rules_Of'Result
       = (Ack_Ends_Text           => X = 1,
          Engine_Front            =>
            X = 1 or else (X = 2 and then RBC_2_0_To_2_2 (Known, V)),
          TSR_Estimated           => X <= 2,
          ASP_Lower_Categories    => X <= 2,
          SR_Stop_Always          => X = 1,
          Texts_FS_Across_AD      => X = 1,
          No_Supervised_Manoeuvre =>
            X = 1 or else (X = 2 and then RBC_2_0_To_2_2 (Known, V)),
          EoM_Awaits_Termination  => X = 1);

   --  3.17.2.2: the X operated now
   --  @req 3.17.2.2
   function Operated return Major_T
     with Global => State;

   --  The X.Y operated now (3.17.2.1.1)
   function Operated_Version return M_VERSION_T is
     (Version_Of (Operated))
     with Global => State;

   --  3.17.2.8: the operated X is the RBC's (level 2 with an established
   --  session of a compatible version)
   function By_RBC return Boolean
     with Global => State;

   --  3.17.2.9, 3.17.2.9.1: the power-up, with the kept X (Known) or
   --  without it (the highest)
   --  @req 3.17.2.9, 3.17.2.9.1
   procedure Restore (Known : Boolean; X : Natural)
     with Global => (Output => State),
          Post => not By_RBC
                  and then Operated
                    = (if Known and then X in Major_T then X else Highest_X);

   --  3.17.2.3, 3.17.2.5, 3.17.2.6, 3.17.2.7: a balise group message
   --  taken into account, Group_X the highest X of its telegrams; Ordered
   --  when it holds a system version order (packet 2) for the direction
   --  of the train, of version Order; Mismatch the country of the group
   --  not that of the national values in use (3.17.2.6). The order is
   --  executed whatever the group's X; without an order, the group's X
   --  when higher than the operated one (3.17.2.3) or at a mismatch
   --  (3.17.2.6); an X outside the envelope leaves it unchanged
   --  (3.17.2.7). While the RBC governs (3.17.2.8) nothing changes.
   --  3.17.3.3: called for a group message before its packets are taken
   --  (EVC_Stored_Information.Take_Version). Decision (3.17.3.4): called
   --  only for a group message taken into account, after the checks of
   --  Table 17 (EVC_Position, EVC_Balise_Groups), so a message they
   --  reject never changes the version, nothing to revoke; with the one
   --  telegram layout of 4.0.0 those checks do not depend on the version.
   --  @req 3.17.2.3, 3.17.2.5, 3.17.2.6, 3.17.2.7
   --  @req 3.17.3.3, 3.17.3.4
   procedure Take_Balise_Group (Group_X  : Natural;
                                Ordered  : Boolean;
                                Order    : M_VERSION_T;
                                Mismatch : Boolean)
     with Global => (In_Out => State),
          Post => By_RBC = By_RBC'Old
                  and then Operated
                    = (if By_RBC then Operated'Old
                       elsif Ordered then
                         (if Major (Order) in Major_T then Major (Order)
                          else Operated'Old)
                       elsif Group_X in Major_T
                         and then (Mismatch or else Group_X > Operated'Old)
                       then Group_X
                       else Operated'Old);

   --  3.17.2.8.2: the balise group message being taken ordered the
   --  switch from level 2 (an immediate or conditional level transition
   --  order): the RBC no longer takes precedence, so the group's own X
   --  is judged at once by Take_Balise_Group (3.17.2.3, .5, .6), not at
   --  the next group. 3.17.2.8.1, the converse: Follow, later in the
   --  same cycle, operates the RBC's X once the order took the on-board
   --  to level 2. Decision: with the one telegram layout of 4.0.0 the
   --  checks and the evaluation of the group's content do not depend on
   --  the version, so the substitution of both clauses is the operated
   --  version itself; the layouts of chapter 6 are not interpreted
   --  @req 3.17.2.8.1, 3.17.2.8.2
   procedure Release
     with Global => (In_Out => State),
          Post => not By_RBC and then Operated = Operated'Old;

   --  3.17.2.8, once a cycle: Level_2 the level operated, Session a
   --  communication session established with the supervising RBC, whose
   --  version V is known
   --  3.17.3.7: V is the version the RBC gave at the first contact,
   --  checked by EVC_Sessions.Take_Version (3.5.3.7 d)
   --  @req 3.17.2.8, 3.17.2.8 a), 3.17.2.8 b), 3.17.2.8 d)
   --  @req 3.17.3.7
   procedure Follow (Level_2 : Boolean; Session : Boolean; V : M_VERSION_T)
     with Global => (In_Out => State),
          Post => By_RBC = (Level_2 and then Session and then Compatible (V))
                  and then Operated
                    = (if By_RBC then Major (V) else Operated'Old);

end EVC_System_Version;
