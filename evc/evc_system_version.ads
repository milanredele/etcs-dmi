--  ETCS on-board (EVC)
--  The operated system version: SUBSET-026 3.17.2 and the envelope of
--  6.4.2 (phase E5 brings the part of chapter 6 the radio needs; the
--  rest, the balise side of 3.17.2.3 .. .7 and 3.17.3.3 .. .4, is E6 /
--  E7).
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
--      non-RBC constituents applies again from there (3.17.2.3, E6 / E7);
--    - c, the accepting RBC at the border, comes with the handover
--      (3.15.1): the accepting RBC then becomes the supervising one;
--    - .8.1 / .8.2 (the balise group that ordered the transition checked
--      again with the new version): the telegram decoder knows one layout
--      of 4.0.0 today, nothing to check again; E7 with the layouts of
--      chapter 6.
--  3.17.2.9: the operated version is kept over No Power (EVC_Retained);
--  3.17.2.9.1: lost, the highest supported one (Restore).

with ETCS_Variables; use ETCS_Variables;

package EVC_System_Version
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   pragma Unevaluated_Use_Of_Old (Allow);

   --  3.17.2.1, 6.4.2: the X of the envelope
   subtype Major_T is Natural range 1 .. 3;
   Lowest_X  : constant Major_T := 1;
   Highest_X : constant Major_T := 3;

   --  7.5.1.79: X, the three most significant bits of M_VERSION
   function Major (V : M_VERSION_T) return Natural is (Natural (V) / 16);

   --  3.5.3.7 d), 3.17.3.7: a version of the trackside is compatible
   --  when its X is in the envelope
   function Compatible (V : M_VERSION_T) return Boolean is
     (Major (V) in Lowest_X .. Highest_X);

   --  3.5.3.7 e), 3.5.4.6: the RBC acknowledges the session established
   --  report (message 38), except an RBC of 1.x or 2.0 .. 2.2, for which
   --  6.5.2.2.2 (X = 2) and 6.5.1.2 (X = 1) replace 3.5.3.7 e) and
   --  3.5.4.6 by 6.5.1.2.1.4 / .5 (no acknowledgement): the on-board
   --  does not await it then (3.5.3.7.4 does not apply)
   function Session_Acknowledged (V : M_VERSION_T) return Boolean is
     (Major (V) >= 3 or else (Major (V) = 2 and then Natural (V) mod 16 >= 3));

   --  3.17.2.1.1: the Y operated within X
   function Operated_Y (X : Major_T) return Natural is
     (case X is when 1 => 1, when 2 => 3, when 3 => 0);

   --  The M_VERSION of X.Y (7.5.1.79)
   function Version_Of (X : Major_T) return M_VERSION_T is
     (M_VERSION_T (X * 16 + Operated_Y (X)));

   --  7.4.3.3 (packet 2 of message 159): the versions of the envelope,
   --  the highest first, then N_ITER more (6.4.2.2: 1.0 up to 3.0)
   Envelope_Count : constant := 7;
   type Envelope_T is array (1 .. Envelope_Count) of M_VERSION_T;
   Envelope : constant Envelope_T := (48, 35, 34, 33, 32, 17, 16);

   --  3.17.2.2: the X operated now
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
   procedure Restore (Known : Boolean; X : Natural)
     with Global => (Output => State),
          Post => not By_RBC
                  and then Operated
                    = (if Known and then X in Major_T then X else Highest_X);

   --  3.17.2.8, once a cycle: Level_2 the level operated, Session a
   --  communication session established with the supervising RBC, whose
   --  version V is known
   procedure Follow (Level_2 : Boolean; Session : Boolean; V : M_VERSION_T)
     with Global => (In_Out => State),
          Post => By_RBC = (Level_2 and then Session and then Compatible (V))
                  and then Operated
                    = (if By_RBC then Major (V) else Operated'Old);

end EVC_System_Version;
