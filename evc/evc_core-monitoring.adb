--  ETCS on-board (EVC)
--  EVC_Core.Monitoring, implementation.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Profiles;
with EVC_Limits;
with EVC_Fixed;
with EVC_BTM_Alarm;

package body EVC_Core.Monitoring
  with SPARK_Mode => On
is

   function To_Speed_State (S : EVC_Supervision_Input.Snapshot_T;
                            R : EVC_SDM.Result_T) return Speed_State_T
   is
      use EVC_Fixed;

      function Kmh (V : Speed_T) return Unsigned_16 is
        (Unsigned_16 (Min (Cms_To_Kmh (V), 65_535)));

      V_Max : constant Speed_T := Speed_T (S.Train_Data.Max_Speed);
      Top   : constant Num :=
        V_Max + EVC_Limits.Margin (EVC_Limits.EBI, V_Max);
      Dial  : constant EVC_Bytes.Byte :=
        (if V_Max = 0 then 1
         elsif Top * 36 <= 140_000 then 0
         elsif Top * 36 <= 180_000 then 1
         elsif Top * 36 <= 250_000 then 2
         else 3);
   begin
      return (V_Cur      => Kmh (R.V_Est),
              V_Perm     => Kmh (R.V_Perm),
              V_Target   => Kmh (R.V_Target),
              V_Release  => Kmh (R.V_Release),
              V_SBI      => Kmh (R.V_SBI),
              V_Wsl      => Kmh (R.V_Warning),
              D_Target   => Unsigned_32 (Min (Max (R.D_Target, 0) / 100,
                                              2**32 - 1)),
              Monitoring => EVC_SDM.Monitoring_T'Pos (R.Monitoring),
              Dial_Range => Dial,
              Flags      => (if R.Release_Shown then Flag_Release_Shown
                             else 0)
                            or (if R.CSM_Target then Flag_CSM_Target
                                else 0),
              Status     => EVC_SDM.Status_T'Pos (R.Status),
              MRDT       => EVC_Bytes.Byte (R.MRDT_Id));
   end To_Speed_State;

   procedure Take_Snapshot is
   begin
      if not Test_Snapshot_Set then
         EVC_Stored_Information.Get_Current (Snapshot);
      end if;
   end Take_Snapshot;

   procedure Monitor_Speed_And_Distance (Dt_Ms : Natural) is
      procedure Run (S : EVC_Supervision_Input.Snapshot_T) is
         Controller : constant EVC_Brake_Commands.Controller_T :=
           Controller_Now;
         Inputs : constant EVC_SDM.Inputs_T :=
           (Dt_Ms          => Dt_Ms,
            Special_Active =>
              (EVC_Supervision_Input.Regenerative =>
                 TIU_Now (Regenerative_Brake_Active),
               EVC_Supervision_Input.Eddy_Current =>
                 TIU_Now (Eddy_Current_Brake_Active),
               EVC_Supervision_Input.Magnetic_Shoe =>
                 TIU_Now (Magnetic_Shoe_Brake_Active),
               EVC_Supervision_Input.Electro_Pneumatic =>
                 TIU_Now (EP_Brake_Active)),
            Additional     => TIU_Now (Additional_Brake_Active),
            Pressure_Known => TIU_Known_Now (Brake_Pressure),
            Pressure       => Natural (TIU_Value_Now (Brake_Pressure)) * 4,
            Level_1        => EVC_Levels.Valid
                              and then EVC_Levels.Level = L1,
            Antenna_Offset =>
              Natural (EVC_Position.Front_Offset
                         (EVC_Position.Orientation)),
            --  4.4.18.1.6: in RV the emergency brake for the SBI
            EB_Instead_Of_SB => Current_Mode = M_RV);
      begin
         EVC_SDM.Step (S, Inputs, SDM_Work, SDM_State, SDM_Result);
         EVC_Brake_Commands.Step
           (S, SDM_Result,
            (Mode       => Current_Mode,
             Controller => Controller,
             Ack        => Brake_Ack_Now,
             Dt_Ms      => Dt_Ms,
             A_Est      => SDM_State.A_Est,
             T_Bs       => SDM_Work.Model.Service_Target.Build_Up,
             Modifying_Data   => EVC_Mission.Modifying_Train_Data,
             Entering_SR_Data => EVC_Mission.Entering_SR_Data),
            Brake_State, Brake_Output);
         Speed_State := To_Speed_State (S, SDM_Result);
      end Run;
   begin
      --  the acknowledgement of a release goes first to the protections
      --  of 3.14.1.5 when they ask for it (3.14.1.10)
      Ack_For_Protection := Brake_Ack_Now and then Brake_Output.Ack_Required;
      Take_Snapshot;
      Run (Snapshot);
   end Monitor_Speed_And_Distance;

   procedure Supervise_BTM_Alarm is
   begin
      if not Latched_BTM_Alarm then
         BTM_Alarm_Run := (others => <>);
         EVC_Procedures.Set_BTM_Alarm_Failure (False);
         return;
      end if;
      if not BTM_Alarm_Run.Active then
         BTM_Alarm_Run :=
           EVC_Odometry.Start_Virtual (EVC_BTM_Alarm.Immunity_Distance_Cm,
                                       EVC_Position.Orientation);
      end if;
      EVC_Procedures.Set_BTM_Alarm_Failure
        (EVC_BTM_Alarm.Reaction
          (Raised    => True,
           Level     => Proc_Ctx.Level,
           Mode      => Current_Mode,
           Inhibited => EVC_Procedures.BMM_Inhibited,
           Over_BMM  =>
             EVC_Track_Conditions.BMM_At_Antenna
               (EVC_Profiles.Origin_Table,
                (Valid     => Snapshot.Train.Position_Valid,
                 Sense     => EVC_Position.Orientation,
                 Est_Front => Snapshot.Train.Est_Front,
                 Min_Front => Snapshot.Train.Min_Safe_Front,
                 Max_Front => Snapshot.Train.Max_Safe_Front,
                 others    => <>),
                Proc_Ctx.Antenna_Offset),
           Moved     =>
             EVC_Odometry.Away (BTM_Alarm_Run, EVC_Distances.Unknown)));
   end Supervise_BTM_Alarm;

end EVC_Core.Monitoring;
