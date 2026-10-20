--  ETCS on-board (EVC)
--  The tolerance of big metal masses (SUBSET-026 3.15.7): when the BTM
--  alarm, the "integrity check alarm of balise transmission" of the BTM
--  port (EVC_Ports), is ignored and when the on-board reacts to it.
--
--  EVC_Core keeps the alarm of the port, the distance travelled since it
--  was raised (EVC_Odometry.Virtual_T, 3.6.7.1 d) and the reaction; this
--  unit holds the rules, as functions of the cycle's level, mode, the
--  inhibition of 5.22 (EVC_Procedures.BMM_Inhibited) and the big metal
--  masses at the antenna (EVC_Track_Conditions.BMM_At_Antenna).
--
--  The reaction (3.15.7.6, 3.15.7.6.1: left to the implementation).
--  Decision: the service brake, commanded while the alarm persists and
--  is not ignored, released when it ends or comes to be ignored (the
--  driver may then select the inhibition of 5.22 at standstill in SB,
--  SH or SR, level 1 or 2), with the brake indication of the other
--  service brake demands (MSG_STATUS, the TIU); the trip was not taken
--  because the alarm is a fault of the balise transmission, not a danger
--  point passed, and the service brake brings the train to the
--  standstill the inhibition asks for.

with EVC_Distances; use EVC_Distances;
with EVC_Modes;     use EVC_Modes;

package EVC_BTM_Alarm
  with SPARK_Mode => On, Pure
is

   --  A.3.1: the distance of metal immunity in levels 0 / NTC, 300 m
   --  @req 3.6.7.1 d)
   Immunity_Distance_Cm : constant Length_T := 300_00;

   --  Decision: no reaction in the modes in which this on-board does not
   --  command the brakes on its own supervision (NP, SF, IS, SL, NL, PS:
   --  4.4.x, the brakes are the leading engine's or already applied)
   function Passive_Mode (Mode : Mode_T) return Boolean is
     (Mode in M_NP | M_SF | M_IS | M_SL | M_NL | M_PS);

   --  3.15.7.2: in levels 0 / NTC, ignored over the immunity distance
   --  (Moved: travelled since the alarm was raised, either direction);
   --  3.15.7.4: in levels 1 / 2, ignored under the inhibition of 5.22
   --  (Inhibited) or in SB; 3.15.7.5: in all levels over a big metal
   --  mass at the antenna (Over_BMM)
   --  @req 3.15.7.2, 3.15.7.4, 3.15.7.5
   function Ignored (Level     : Level_T;
                     Mode      : Mode_T;
                     Inhibited : Boolean;
                     Over_BMM  : Boolean;
                     Moved     : Length_T) return Boolean
   is (Over_BMM
       or else Passive_Mode (Mode)
       or else (case Level is
                   when L0 | NTC => Moved <= Immunity_Distance_Cm,
                   when L1 | L2  => Inhibited or else Mode = M_SB));

   --  3.15.7.2, 3.15.7.6: the safety reaction, the alarm raised and not
   --  ignored
   --  @req 3.15.7.6, 5.22.4.2
   function Reaction (Raised    : Boolean;
                      Level     : Level_T;
                      Mode      : Mode_T;
                      Inhibited : Boolean;
                      Over_BMM  : Boolean;
                      Moved     : Length_T) return Boolean
   is (Raised
       and then not Ignored (Level, Mode, Inhibited, Over_BMM, Moved));

end EVC_BTM_Alarm;
