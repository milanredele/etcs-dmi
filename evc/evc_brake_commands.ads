--  ETCS on-board (EVC)
--  Brake command handling and the protection against undesirable train
--  movements: SUBSET-026 3.14.1 (the brake commands, their reasons and
--  their release conditions), 3.14.2 (roll away protection), 3.14.3
--  (unauthorised direction movement protection) and the standstill
--  supervision of Stand By (4.4.7.1.5), which 3.14.1.5 releases the same
--  way.
--
--  Step combines, once per cycle, the commands of the speed and distance
--  monitoring (EVC_SDM, 3.13.10) with the brake reasons of this unit into
--  the commands to the train interface (SUBSET-034 2.3.1 service brake,
--  2.3.3 emergency brake, 2.4.9 traction cut-off) and says what the
--  driver is to be shown (the brake applied, the acknowledgement asked
--  at standstill, 3.14.1.9). The brake reasons of trip, linking, radio,
--  reversing, train data, acknowledgements and consist length (3.14.1.3,
--  3.14.1.6 to 3.14.1.7.6) come with the modes and procedures of the
--  later phases; the mode change handling of 3.14.1.11 with 4.12 (E4).
--
--  The protections supervise the distance run away from where the
--  unwanted movement was detected: the change of the estimated front
--  end plus the growth of the confidence interval since (3.6.7: the
--  distance is measured with the odometer's accuracy), against
--  D_NVROLL. Until the mode machine of E4, "a mode with speed and
--  distance monitoring" is the snapshot's Supervise (EVC_SDM): the roll
--  away protection and the unauthorised direction movement protection
--  run under it (and in the other modes of 4.5.2 Figure 1 that have
--  them), the standstill supervision in Stand By without it.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Distances;         use EVC_Distances;
with EVC_Fixed;             use EVC_Fixed;
with EVC_Modes;             use EVC_Modes;
with EVC_SDM;
with EVC_Supervision_Input; use EVC_Supervision_Input;

package EVC_Brake_Commands
  with SPARK_Mode => On
is

   --  The brake reasons of this phase
   type Reason_T is
     (Speed_Distance,          -- 3.13.10 (3.14.1.4)
      Service_Brake_Failed,    -- 3.14.1.2
      Roll_Away,               -- 3.14.2, released per 3.14.1.5
      Direction,               -- 3.14.3, released per 3.14.1.5
      Standstill_Supervision); -- 4.4.7.1.5, released per 3.14.1.5
   type Reasons_T is array (Reason_T) of Boolean;

   --  SUBSET-034 2.5.2: the direction controller of the active desk
   type Controller_T is (Unknown, Neutral, Forwards, Backwards);

   --  One protection of 3.14.2, 3.14.3 or 4.4.7.1.5
   type Protection_T is record
      --  an unwanted movement was detected at From, with the confidence
      --  interval Doubt then (frame positions)
      Watching : Boolean := False;
      From     : Dist_T := 0;
      Doubt    : Length_T := 0;
      --  the brake is commanded, until standstill and acknowledgement
      Braking  : Boolean := False;
   end record;

   type State_T is record
      Roll_Away   : Protection_T;
      Direction   : Protection_T;
      Standstill  : Protection_T;
      --  3.14.1.2: how long the service brake alone has been commanded
      SB_Ms       : Time_T := 0;
      SB_Failed   : Boolean := False;
   end record;

   type Inputs_T is record
      Mode       : Mode_T := M_SB;
      Controller : Controller_T := Unknown;
      --  the driver acknowledged the release of the brake (DMI 5.4.1,
      --  acknowledgement kind 5)
      Ack        : Boolean := False;
      Dt_Ms      : Natural := 0;
      --  the measured acceleration (EVC_SDM), mm/s²
      A_Est      : Accel_T := 0;
      --  the expected brake build up time of the service brake, T_bs
      --  (EVC_Braking)
      T_Bs       : Time_T := 0;
   end record;

   type Commands_T is record
      EB, SB, TCO  : Boolean := False;
      Reasons      : Reasons_T := (others => False);
      --  a brake of 3.14.1.5 waits, at standstill, for the driver's
      --  acknowledgement (3.14.1.9)
      Ack_Required : Boolean := False;
      --  3.14.2.6, 3.14.3.4, 4.4.7.1.5.4: a protection commands the brake
      Protection   : Boolean := False;
   end record;

   --  The modes of 4.5.2 Figure 1 in which the protections run
   function Roll_Away_Mode (M : Mode_T) return Boolean is
     (M in M_SH | M_SM | M_FS | M_AD | M_LS | M_SR | M_OS | M_UN | M_PT
         | M_RV);
   function Direction_Mode (M : Mode_T) return Boolean is
     (M in M_SM | M_FS | M_AD | M_LS | M_SR | M_OS | M_PT | M_RV);

   procedure Step (S      : Snapshot_T;
                   SDM    : EVC_SDM.Result_T;
                   Inputs : Inputs_T;
                   State  : in out State_T;
                   Output : out Commands_T)
     with Post =>
       --  3.14.1.4: the commands of the speed and distance monitoring
       --  are given; 3.14.1.2: the emergency brake when the service brake
       --  failed
       (if SDM.EB then Output.EB)
       and then (if SDM.SB then Output.SB)
       and then (if SDM.TCO then Output.TCO)
       and then (if State.SB_Failed then Output.EB)
       --  3.14.1.5: a protection's brake is released only at standstill
       --  and after the acknowledgement
       and then (if State.Roll_Away.Braking'Old
                   and then not State.Roll_Away.Braking
                 then S.Train.Standstill and then Inputs.Ack)
       and then (if State.Direction.Braking'Old
                   and then not State.Direction.Braking
                 then S.Train.Standstill and then Inputs.Ack)
       and then (if State.Standstill.Braking'Old
                   and then not State.Standstill.Braking
                 then S.Train.Standstill and then Inputs.Ack)
       and then (if State.Roll_Away.Braking or else State.Direction.Braking
                   or else State.Standstill.Braking
                 then Output.EB);

end EVC_Brake_Commands;
