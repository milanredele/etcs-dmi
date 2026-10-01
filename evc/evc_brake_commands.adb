--  ETCS on-board (EVC)
--  Brake command handling, implementation.

package body EVC_Brake_Commands
  with SPARK_Mode => On
is

   --  One protection (3.14.2.4, 3.14.3.2, 4.4.7.1.5.1): watch an unwanted
   --  movement from where it was detected; brake once the train ran
   --  away more than D_NVROLL; release at standstill and after the
   --  acknowledgement (3.14.1.5) and start again (3.14.2.7, 3.14.3.5,
   --  4.4.7.1.5.3)
   procedure Protect (P        : in out Protection_T;
                      Active   : Boolean;
                      Unwanted : Boolean;
                      Allowed  : Boolean;
                      S        : Snapshot_T;
                      Ack      : Boolean)
     with Post => (if P.Braking'Old and then not P.Braking
                   then S.Train.Standstill and then Ack)
   is
      Est   : constant Dist_T := S.Train.Est_Front;
      Doubt : constant Length_T :=
        Abs_Dist (Diff (S.Train.Max_Safe_Front, S.Train.Min_Safe_Front));
   begin
      if P.Braking then
         if S.Train.Standstill and then Ack then
            P := (Watching => False, From => 0, Doubt => 0,
                  Braking => False);
         end if;
         return;
      end if;
      if not Active then
         P.Watching := False;
         return;
      end if;
      if Unwanted and then not P.Watching then
         P.Watching := True;
         P.From := Est;
         P.Doubt := Doubt;
      elsif Allowed then
         --  the train moves the way it may: the unwanted movement ended
         P.Watching := False;
      end if;
      if P.Watching then
         declare
            Moved : constant Length_T :=
              Add (Abs_Dist (Diff (Est, P.From)), Growth (Doubt, P.Doubt));
         begin
            if Moved > S.National.D_NVROLL then
               P.Braking := True;
            end if;
         end;
      end if;
   end Protect;

   ----------
   -- Step --
   ----------

   procedure Step (S      : Snapshot_T;
                   SDM    : EVC_SDM.Result_T;
                   Inputs : Inputs_T;
                   State  : in out State_T;
                   Output : out Commands_T)
   is
      T          : Train_State_T renames S.Train;
      Moving     : constant Boolean :=
        not T.Standstill or else T.Moving_Ahead or else T.Moving_Backwards;
      Supervised : constant Boolean := S.Supervise;
   begin
      --  3.14.2: against the direction controller, where it is known
      --  (3.14.2.1); in neutral no movement is wanted (3.14.2.3)
      Protect
        (State.Roll_Away,
         Active   => (Supervised or else Roll_Away_Mode (Inputs.Mode))
                     and then Inputs.Controller /= Unknown,
         Unwanted => (case Inputs.Controller is
                         when Neutral => Moving,
                         when Forwards => T.Moving_Backwards,
                         when Backwards => T.Moving_Ahead,
                         when Unknown => False),
         Allowed  => (case Inputs.Controller is
                         when Forwards => T.Moving_Ahead,
                         when Backwards => T.Moving_Backwards,
                         when others  => False),
         S        => S,
         Ack      => Inputs.Ack);

      --  3.14.3: against the direction of the MA, when there is one
      --  (3.14.3.1), and in SR against the train orientation (4.4.11.1.3
      --  e); in Post Trip and Reversing the allowed movement is the
      --  reverse one (4.4.14.1.3.1, 4.4.18.1.8: the special cases of
      --  chapter 4), the snapshot's Ahead being the train orientation
      --  without an MA (phase E4)
      Protect
        (State.Direction,
         Active   => ((Supervised or else Direction_Mode (Inputs.Mode))
                      and then (S.MA.Present or else Inputs.Mode = M_SR))
                     or else Inputs.Mode in M_PT | M_RV,
         Unwanted => (if Inputs.Mode in M_PT | M_RV then T.Moving_Ahead
                      else T.Moving_Backwards),
         Allowed  => (if Inputs.Mode in M_PT | M_RV then T.Moving_Backwards
                      else T.Moving_Ahead),
         S        => S,
         Ack      => Inputs.Ack);

      --  4.4.7.1.5: in Stand By no movement at all
      Protect
        (State.Standstill,
         Active   => Inputs.Mode = M_SB and then not Supervised,
         Unwanted => Moving,
         Allowed  => False,
         S        => S,
         Ack      => Inputs.Ack);

      --  3.14.1.2: the service brake alone, not applied: the emergency
      --  brake (released with the service brake command). The train must
      --  decelerate by SB_Failure_Decel_Mms2 once SB_Failure_Time_Ms
      --  passed beyond the build up time of the service brake: 3.14.1.1
      --  leaves the detection to the implementation, the values are the
      --  installation's (EVC_Config)
      if SDM.SB and then not SDM.EB then
         State.SB_Ms := Min (State.SB_Ms + Num (Inputs.Dt_Ms), Max_Time);
         if State.SB_Ms
              > Min (Inputs.T_Bs + Num (S.Extra.Config.SB_Failure_Time_Ms),
                     Max_Time)
           and then Inputs.A_Est
                      > -Num (S.Extra.Config.SB_Failure_Decel_Mms2)
           and then not T.Standstill
         then
            State.SB_Failed := True;
         end if;
      else
         State.SB_Ms := 0;
         State.SB_Failed := False;
      end if;

      Output.Reasons :=
        (Speed_Distance         => SDM.EB or else SDM.SB,
         Service_Brake_Failed   => State.SB_Failed,
         Roll_Away              => State.Roll_Away.Braking,
         Direction              => State.Direction.Braking,
         Standstill_Supervision => State.Standstill.Braking);
      Output.Protection :=
        State.Roll_Away.Braking or else State.Direction.Braking
        or else State.Standstill.Braking;
      Output.EB := SDM.EB or else State.SB_Failed or else Output.Protection;
      Output.SB := SDM.SB;
      Output.TCO := SDM.TCO;
      --  3.14.1.9, 3.14.1.10.1: one acknowledgement for the reasons of
      --  3.14.1.5, asked at standstill
      Output.Ack_Required := Output.Protection and then T.Standstill;
   end Step;

end EVC_Brake_Commands;
