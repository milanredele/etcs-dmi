--  ETCS on-board (EVC)
--  Phase E5, the session and link half: the train integrity information
--  reported to the RBC (3.6.5.2): its status of Table 2b, moved by the
--  conditions of Table 2c, and the confirmed train length (Figure 15)
--  of the position reports (packets 0 and 1, Q_INTEGRITY, L_TRAININT).
--
--  A private child of EVC_Sessions, its state a part of the parent's.
--
--  Decisions:
--  (1) The external source is the TIU input "train integrity" (EVC_Ports
--      signal 14, value 0 unknown, 1 confirmed, 2 lost); each input is
--      a reception of that information (Table 2c [3], [4], [6]) and the
--      time the train was last known to be integer is the cycle of the
--      reception (3.6.5.2.4.1 leaves it to the source).
--  (2) The safe consist length and Supervised Manoeuvre are not
--      modelled: the train length is the one of valid Train Data, [2] and
--      [3] take their second alternative, [10] never holds; the "new
--      Train Data pending the driver's validation" is never pending.
--  (3) [2] asks also the position valid and referred to an LRBG
--      (3.6.5.2.7: no confirmed length can be reported without it, the
--      DMI's enabling condition of the button asks it).
--  (4) A reverse movement ([8]) is a movement of the cycle towards the
--      cab that is not active; the travel since the time the train was
--      last known to be integer is counted towards the active cab (both
--      senses when no cab is active).
--  (5) The confirmed length is rounded up to the metre (the rear end
--      the RBC derives is then the safer one) and capped at 32767 m
--      (7.5.1.57) for the driver's confirmation, which [9] does not end.

with EVC_Distances;
with EVC_Driver_Requests;
with EVC_Odometry;
with EVC_Position;
with EVC_Radio;
with EVC_Train_Data;

--  @req 3.6.5.2.2, 3.6.5.2.3, 3.6.5.2.3 a), 3.6.5.2.3 a) 1st bullet
--  @req 3.6.5.2.3 a) 2nd bullet, 3.6.5.2.3 a) 3rd bullet
--  @req 3.6.5.2.3 a) 4th bullet, 3.6.5.2.3 b), 3.6.5.2.4, 3.6.5.2.5
--  @req 3.6.5.2.5 Table 2b, 3.6.5.2.6, 3.6.5.1.4 c), 3.6.5.1.4 d)
private package EVC_Sessions.Integrity
  with SPARK_Mode => On,
       Abstract_State => (State with Part_Of => EVC_Sessions.State)
is
   --  Table 2b, coded as Q_INTEGRITY (7.5.1.112)
   type Status_T is (No_Information, By_External, By_Driver, Lost);

   --  The values of the TIU input "train integrity"
   Input_Unknown   : constant := 0;
   Input_Confirmed : constant := 1;
   Input_Lost      : constant := 2;

   --  The longest confirmed train length L_TRAININT codes, in cm
   Max_Length : constant EVC_Distances.Length_T := 32_767 * 100;

   procedure Clear
     with Global => (Output => State);

   --  An input "train integrity" of the TIU, for the next Evaluate
   procedure Take_Input (Value : Natural)
     with Global => (In_Out => State);

   --  The conditions of Table 2c in the cycle, after the session's
   --  establishment (3.6.5.2.6); Report: 3.6.5.1.4 c) or d) happened
   procedure Evaluate (Report : out Boolean)
     with Global => (In_Out => State,
                     Input  => (EVC_Radio.State, EVC_Position.State,
                                EVC_Odometry.State, EVC_Train_Data.State,
                                EVC_Driver_Requests.State));

   function Status return Status_T
     with Global => State;

   --  Q_INTEGRITY of the position report
   function Q_Integrity return Natural
     with Global => State,
          Post => Q_Integrity'Result <= 3;

   --  L_TRAININT of the position report, in metres (Figure 15)
   function Confirmed_Length return Natural
     with Global => (State, EVC_Odometry.State, EVC_Position.State),
          Post => Confirmed_Length'Result <= 32_767;

   --  A position report with this information was sent (Table 2c [5])
   procedure Reported
     with Global => (In_Out => State);

end EVC_Sessions.Integrity;
