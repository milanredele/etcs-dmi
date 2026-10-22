--  ETCS on-board (EVC)
--  EVC_Core.Modes, implementation.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Core.Inputs; use EVC_Core.Inputs;
with EVC_Core.Stored; use EVC_Core.Stored;
with EVC_Core.Monitoring; use EVC_Core.Monitoring;

with EVC_Transition_Conditions;
with EVC_Profiles;
with EVC_Acceptance;

package body EVC_Core.Modes
  with SPARK_Mode => On
is

   use type EVC_Mission.Data_Status_T;

   procedure Evaluate_Modes_And_Levels is
      Solr  : constant EVC_Location.Anchor_T := EVC_Position.SOLR;
      Valid : constant Boolean :=
        EVC_Position.Status = EVC_Position.Valid and then Solr.Valid;
      NV    : constant EVC_Supervision_Input.National_Values_T :=
        EVC_National_Values.Current.Values;
   begin
      EVC_Levels.Evaluate
        (T            => EVC_Profiles.Origin_Table,
         C            =>
           (Mode           => Current_Mode,
            Standstill     => EVC_Odometry.Standstill,
            Position_Valid => Valid,
            Est_Front      => EVC_Position.Front_X,
            Max_Front      =>
              (if Valid
               then EVC_Distances.Advance
                      (Solr.X, EVC_Position.Orientation,
                       EVC_Position.SOLR_Max_Safe_Front)
               else EVC_Position.Front_X),
            Now_Ms         => Unsigned_64 (Clock_Ms)),
         Driver_Level => EVC_Driver_Requests.Level_Selected,
         Code         => EVC_Driver_Requests.Selected_Level_Code,
         Ack          => EVC_Driver_Requests.Level_Acknowledged);
      EVC_Mission.Evaluate
        ((Mode        => Current_Mode,
          Level_Valid => EVC_Levels.Valid,
          Level       => EVC_Levels.Level,
          Standstill  => EVC_Odometry.Standstill,
          Desk_Open   => EVC_Train_Inputs.Desk_Open,
          Non_Leading => EVC_Train_Inputs.Non_Leading_Permitted,
          Sense       => EVC_Position.Orientation,
          V_NVSTFF    => NV.V_NVSTFF,
          D_NVSTFF    => NV.D_NVSTFF,
          In_Communication => EVC_Radio.In_Communication,
          SR_Authorisations => EVC_Radio_Authority.SR_Authorisations,
          Profile_Ack => EVC_Procedures.Ack_Requested,
          Radio_MAs => EVC_Radio_Authority.Radio_MAs_Accepted,
          ID_Running => EVC_National_Values.M_NVDERUN));
      --  5.4.3.3 "Following D2": the stored position invalid or unknown,
      --  the level valid -> invalid (the D2 of the start of mission)
      if EVC_Mission.D2_Passed and then not Valid then
         EVC_Levels.Invalidate;
      end if;
      --  A.3.4.1.2 k), column k: what entering SB has not deleted
      --  already (the TSRs, the adhesion, the big metal masses, the level
      --  transition orders, the national values not yet applicable); the
      --  Train Data, the driver ID and the train running number are to be
      --  revalidated (EVC_Mission)
      if EVC_Mission.Desk_Closed_In_SoM then
         EVC_National_Values.Delete_Pending;
         EVC_Track_Description.Delete
           ((Track       => True,
             PBD         => True,
             Suitability => True,
             TSR         => True,
             Adhesion    => True));
         EVC_Movement_Authority.Delete_MA;
         EVC_Track_Conditions.Reset (Rest => True, Horn => True,
                                     BMM => True);
         EVC_Position.Delete_Linking;
         EVC_Stored_Information.Set_Driver_Slippery (False);
         EVC_Levels.Delete_Orders;
      end if;
   end Evaluate_Modes_And_Levels;

   function Radio_Context return EVC_Radio.Context_T is
     ((Mode       => Current_Mode, Now_Ms => Unsigned_64 (Clock_Ms),
       Radio_Hole => EVC_Track_Conditions.Engine_In_Radio_Hole));

   procedure Evaluate_Radio is
   begin
      --  the sessions of the level transitions (5.10.3)
      EVC_Level_Sessions.Evaluate (Current_Mode, Unsigned_64 (Clock_Ms));
      EVC_Sessions.Evaluate (Radio_Context);
      --  5.4.3.2 A35: the RBC confirmed the reported position
      --  A24, A39: the RBC's answer (41 with the train
      --  unknown, 40) deletes it (EVC_Sessions.Mission, decision 5;
      --  like Delete_Invalid_Position)
      if EVC_Sessions.Position_Confirmed then
         EVC_Position.Revalidate;
      elsif EVC_Sessions.Position_To_Delete then
         EVC_Position.Delete_Position;
      end if;
      EVC_Radio_Authority.Evaluate
        (Radio_Context,
         (MA_Request => SDM_Result.MA_Request,
          Start      => EVC_Driver_Requests.Start_Selected,
          Desk_Open  => EVC_Train_Inputs.Desk_Open,
          Proposal_In_Rear => SDM_Result.Proposal_In_Rear,
          Proposal_Covered => EVC_Stored_Information.Proposal_Covered,
          --  the driver's SR entry as EVC_Mission takes it (4.4.11.1.5)
          SR_Entered =>
            EVC_Driver_Requests.Entered (EVC_Driver_Requests.SR_Data)
            and then Current_Mode = M_SR
            and then EVC_Odometry.Standstill
            and then EVC_Driver_Requests.SR_Data.Speed_Kmh in 5 .. 600,
          Override_Active => EVC_Procedures.Override_Active,
          Shunting_Selected => EVC_Driver_Requests.Shunting_Selected,
          Standstill => EVC_Odometry.Standstill,
          Cab_Active => EVC_Train_Inputs.Desk_Open,
          Train_Data_Valid => EVC_Train_Data.Valid,
          TRN_Valid => EVC_Mission.TRN_Status = EVC_Mission.Valid,
          --  4.8.3 [3]: Train Data sent and their
          --  acknowledgement (message 8) not received yet. Decision: the
          --  second bullet (values changed) is taken as any Train Data
          --  sent again: the on-board does not compare the four values
          Train_Data_Unacked => EVC_Sessions.Train_Data_Awaited,
          TAF_Confirmed =>
            EVC_Driver_Requests.Selected (EVC_Driver_Requests.TAF_Yes)));
   end Evaluate_Radio;

   procedure Radio_Mode_Changed (From, To : Mode_T) is
   begin
      EVC_Sessions.Mode_Changed (From, To);
      EVC_Radio_Authority.Mode_Changed (From, To);
   end Radio_Mode_Changed;

   procedure Run_Procedures is
      --  the snapshot in use, taken by the first statement
      S : EVC_Supervision_Input.Snapshot_T renames Snapshot;
      --  5.17.2.2 S0 -> D0: the train configuration changed
      Config : constant EVC_Bytes.Byte :=
        TIU_Value_Now (Train_Configuration);
      Config_Changed : constant Boolean :=
        TIU_Known_Now (Train_Configuration) and then Config_Seen
        and then Config /= Config_Last;
   begin
      Take_Snapshot;
      if TIU_Known_Now (Train_Configuration) then
         Config_Last := Config;
         Config_Seen := True;
      end if;
      Proc_Ctx :=
        (Mode              => Current_Mode,
         Level_Valid       => EVC_Levels.Valid,
         Level             => EVC_Levels.Level,
         --  the level transitions of the cycle (EVC_Levels, 5.10)
         Level_Switched    => EVC_Levels.Switched_To (L1)
                              or else EVC_Levels.Switched_To (L2),
         Switched_To_L1    => EVC_Levels.Switched_To (L1),
         Desk_Open         => EVC_Train_Inputs.Desk_Open,
         Passive_Shunting  => EVC_Train_Inputs.Passive_Shunting_Permitted,
         Controller        => Controller_Now,
         Train_Data_Valid  => EVC_Train_Data.Valid,
         --  the train running number of the start of mission (5.4.2)
         TRN_Valid         => EVC_Mission.TRN_Status = EVC_Mission.Valid,
         Speed_Est         =>
           EVC_Supervision_Input.Speed_Cms_T
             (Natural'Min (Natural (Odometer_Now.V_Est),
                           EVC_Supervision_Input.Speed_Cms_T'Last)),
         Antenna_Offset    =>
           EVC_Position.Front_Offset (EVC_Position.Orientation),
         Brake_Release_Ack => Brake_Ack_Now and then not Ack_For_Protection,
         Now_Ms            => Unsigned_64 (Clock_Ms),
         TD_Change         => Config_Changed,
         TD_Validation     => (Config and TIU_Config_Validation) /= 0,
         TD_Category       => (Config and TIU_Config_Category) /= 0,
         SR_Distance_Passed => SR_Distance_Passed,
         SR_Listed         => EVC_Radio_Authority.Groups_Passed_Listed,
         --  the start of mission's proposal comes first (EVC_Mission)
         Mode_Ack          => EVC_Driver_Requests.Mode_Acknowledged
                              and then not EVC_Mission.Ack_Taken,
         Filters           => Acceptance_Context);
      EVC_Procedures.Evaluate (Proc_Ctx, S, SDM_Result);
      --  4.4.11.1.6.5, 4.4.11.1.3.1 a): "Override" selected in SR: the SR
      --  speed limit and distance of the driver are deleted, the national
      --  values apply, the distance counted from here (EVC_Mission)
      if EVC_Procedures.Condition (37) then
         EVC_Radio_Authority.Override_Selected;
      end if;
      if Current_Mode = M_SR and then EVC_Procedures.Condition (37) then
         EVC_Mission.Override_In_SR
           ((Mode        => Current_Mode,
             Level_Valid => EVC_Levels.Valid,
             Level       => EVC_Levels.Level,
             Standstill  => EVC_Odometry.Standstill,
             Desk_Open   => EVC_Train_Inputs.Desk_Open,
             Non_Leading => EVC_Train_Inputs.Non_Leading_Permitted,
             Sense       => EVC_Position.Orientation,
             V_NVSTFF    => EVC_National_Values.Current.Values.V_NVSTFF,
             D_NVSTFF    => EVC_National_Values.Current.Values.D_NVSTFF,
          In_Communication => EVC_Radio.In_Communication,
          --  read by EVC_Mission.Evaluate only
          SR_Authorisations => 0,
          Profile_Ack => False,
          Radio_MAs => 0,
          ID_Running => True));
      end if;
      EVC_Text_Messages.Evaluate
        (Current_Mode, EVC_Levels.Valid, EVC_Levels.Level,
         S.Train.Est_Front, Unsigned_64 (Clock_Ms),
         Taken  => EVC_Acceptance.Accepted (EVC_Acceptance.Text_Message,
                                            Acceptance_Context));
   end Run_Procedures;

   function Any_Holds (L : Condition_List_T) return Boolean is
     (for some I in L'Range =>
        L (I) /= 0 and then EVC_Transition_Conditions.Holds (L (I)));

   procedure Run_Mode_Machine is
      From          : constant Mode_T := Current_Mode;
      Best          : Mode_T := From;
      Best_Priority : Priority_T := No_Transition;
   begin
      for To in Mode_T loop
         if To /= M_NP
           and then Transitions (From, To) /= No_Transition
           and then (Best_Priority = No_Transition
                     or else Transitions (From, To) < Best_Priority)
           and then Any_Holds (Conditions (From, To))
         then
            Best := To;
            Best_Priority := Transitions (From, To);
         end if;
         pragma Loop_Invariant
           (if Best_Priority = No_Transition
            then Best = From
            else Transitions (From, Best) = Best_Priority
                 and then Best /= M_NP);
         pragma Loop_Invariant
           (if From = M_NP and then To >= M_SB
            then Best_Priority /= No_Transition);
         pragma Loop_Invariant
           (if From = M_NP and then Best_Priority /= No_Transition
            then Best = (if EVC_Driver_Requests.Isolation_Selected
                           and then To >= M_IS
                         then M_IS else M_SB));
      end loop;
      Current_Mode := Best;
   end Run_Mode_Machine;

   procedure Delete_On_Mode_Entry (To : Mode_T) is
   begin
      EVC_Track_Description.Delete
        ((Track       => To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL
                             | M_NL | M_UN | M_TR | M_SN | M_RV,
          PBD         => To in M_NP | M_SB | M_PS | M_SH | M_SM | M_SR
                             | M_SL | M_NL | M_UN | M_TR | M_SN | M_RV,
          Suitability => To in M_NP | M_SB | M_PS | M_SH | M_SM | M_SR
                             | M_SL | M_NL | M_UN | M_TR | M_SN | M_RV,
          TSR         => To in M_NP | M_SB | M_PS | M_SH | M_SL | M_NL
                             | M_SN | M_RV,
          Adhesion    => To in M_NP | M_SB | M_PS | M_SH | M_SL | M_NL
                             | M_SN));
      --  the MA, the mode profile, the signalling related speed
      --  restriction; SM is entered only by [81], with the MA of the
      --  Supervised Manoeuvre authorisation accepted in the cycle (its
      --  row: "U" in SM, "D" in the other modes but PT; the MA it
      --  replaced went with its mode profile, 3.12.4.3)
      if To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL | M_NL
             | M_UN | M_TR | M_SN | M_RV
      then
         EVC_Movement_Authority.Delete_MA;
      end if;
      EVC_Track_Conditions.Reset
        (Rest   => To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL | M_UN
                       | M_SN | M_RV,
         Horn   => To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL | M_NL
                       | M_UN | M_TR | M_PT | M_SN | M_RV,
         BMM    => To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL | M_RV);
      if To in M_NP | M_SB | M_PS | M_SH | M_SR | M_SL | M_NL | M_UN
             | M_TR | M_SN | M_RV
      then
         EVC_Position.Delete_Linking;
      end if;
      if To in M_NP | M_PS | M_SH | M_SL | M_SN | M_RV then
         EVC_Position.Delete_Geo;
      end if;
      --  the adhesion factor from the driver
      if To in M_NP | M_SB | M_PS | M_SH | M_SL | M_NL then
         EVC_Stored_Information.Set_Driver_Slippery (False);
      end if;
      --  (the train position: "D" in SL when invalid, and the deletions
      --  of 5.4.3.2 after E10, E12, E30, E31, E32 when still invalid: the
      --  position of this on-board is never "invalid", nothing is kept
      --  over No Power)
   end Delete_On_Mode_Entry;

   procedure Revoke_Brake_Reasons (From, To : Mode_T) is
   begin
      --  4.12: Speed & Distance monitoring revoked in NP, SB, TR (to be
      --  re-evaluated in the others: the monitoring runs again on the
      --  data of the new mode)
      if To in M_NP | M_SB | M_TR then
         SDM_State.TCO := False;
         SDM_State.SB := False;
         SDM_State.EB := False;
         SDM_State.EB_For_SB := False;
      elsif To /= From then
         SDM_State.Reevaluate := True;
      end if;
      --  4.12: Roll Away Protection revoked in NP, SB, TR, SN; the
      --  Unauthorised Direction Movement Protection in NP, SB, SH, UN, TR,
      --  SN and, from PT, in FS, LS, SR, OS ([1]); the Standstill
      --  Supervision in NP, SH, SM, FS, LS, SR, OS, SL, UN, TR, SN; in IS
      --  the on-board is isolated from the brakes (4.4.3.1.1)
      if To in M_NP | M_SB | M_TR | M_SN | M_IS then
         Brake_State.Roll_Away := (others => <>);
      end if;
      if To in M_NP | M_SB | M_SH | M_UN | M_TR | M_SN | M_IS
        or else (From = M_PT and then To in M_FS | M_LS | M_SR | M_OS)
      then
         Brake_State.Direction := (others => <>);
      end if;
      if To in M_NP | M_SH | M_SM | M_FS | M_LS | M_SR | M_OS | M_SL
             | M_UN | M_TR | M_SN | M_IS
      then
         Brake_State.Standstill := (others => <>);
      end if;
      --  the brake of a movement while the driver modifies the Train Data
      --  (3.18.3.3.1) in NP, SB, SH (4.12.1.2) and IS
      if To in M_NP | M_SB | M_SH | M_IS then
         Brake_State.Data_Entry := False;
      end if;
      --  the service brake of T_NVCONTACT revoked in NP, SB, SH, SR, UN,
      --  TR, SN (4.12.1.2 Table)
      EVC_Sessions.Revoke_Contact_Brake (To);
   end Revoke_Brake_Reasons;

   procedure Enter_Mode (From, To : Mode_T) is
      NV : constant EVC_Supervision_Input.National_Values_T :=
        EVC_National_Values.Current.Values;
   begin
      --  the procedures and the text messages first: the trip and its
      --  reason, the requests for acknowledgement, their information of
      --  4.10 (the stop shunting on desk opening, the list of balise
      --  groups for the SH area, the reversing information, the text
      --  messages) and their brakes of 4.12
      Take_Snapshot;
      EVC_Procedures.Mode_Changed (From, To, Proc_Ctx, Snapshot);
      EVC_Text_Messages.Mode_Changed (From, To);
      EVC_Levels.Mode_Entered (From, To);
      EVC_Mission.Mode_Entered
        (From, To,
         (Mode        => To,
          Level_Valid => EVC_Levels.Valid,
          Level       => EVC_Levels.Level,
          Standstill  => EVC_Odometry.Standstill,
          Desk_Open   => EVC_Train_Inputs.Desk_Open,
          Non_Leading => EVC_Train_Inputs.Non_Leading_Permitted,
          Sense       => EVC_Position.Orientation,
          V_NVSTFF    => NV.V_NVSTFF,
          D_NVSTFF    => NV.D_NVSTFF,
          In_Communication => EVC_Radio.In_Communication,
          --  read by EVC_Mission.Evaluate only
          SR_Authorisations => 0,
          Profile_Ack => False,
          Radio_MAs => 0,
          ID_Running => True));
      Delete_On_Mode_Entry (To);
      Revoke_Brake_Reasons (From, To);
   end Enter_Mode;

   procedure Sync_Train_Length is
      --  the front and rear end of the engine are the train's
      Engine : constant Boolean :=
        Current_Mode in M_SL | M_SH | M_NL | M_PS
        or else (Current_Mode = M_SB and then not EVC_Train_Data.Valid
                 and then not EVC_Train_Data.Manoeuvre_Set);
      Length : constant EVC_Distances.Length_T :=
        (if Engine then EVC_Config.Current.Train.Engine_Length
         else EVC_Train_Data.Length);
   begin
      if Engine or else EVC_Train_Data.Valid
        or else EVC_Train_Data.Manoeuvre_Set
      then
         if not EVC_Position.Train_Length_Known
           or else EVC_Position.Length_Of_Train /= Length
         then
            EVC_Position.Set_Train_Length (Length);
         end if;
      elsif EVC_Position.Train_Length_Known then
         EVC_Position.Unset_Train_Length;
      end if;
      --  3.6.4.1.5 last sentence: gamma 1 in Stand-By without valid Train
      --  Data with the safe consist length, and while a Supervised
      --  Manoeuvre request awaits its answer (decision: with the safe
      --  consist length last received, the one the request carried);
      --  from the first authorisation the term is the position's own
      EVC_Position.Set_Gamma
        (On => not EVC_Position.Manoeuvre_Orientation
               and then EVC_Train_Data.Consist_Known
               and then ((Current_Mode = M_SB
                          and then not EVC_Train_Data.Valid
                          and then EVC_Train_Data.Consist_Available)
                         or else EVC_Sessions.SM_Waiting),
         C  => EVC_Train_Data.Consist);
   end Sync_Train_Length;

   procedure Finish_Procedures is
   begin
      Take_Snapshot;
      EVC_Procedures.Finish_Cycle (Proc_Ctx, Current_Mode, Snapshot);
      if EVC_Movement_Authority.Trip_Ordered
        and then EVC_Levels.Valid and then EVC_Levels.Level = L1
      then
         EVC_Movement_Authority.Clear_Trip_Order;
      end if;
   end Finish_Procedures;

   procedure Adjust_For_Manoeuvre is
   begin
      if EVC_Radio_Authority.SM_Taken then
         if EVC_Radio_Authority.SM_Opposite then
            EVC_Track_Description.Delete ((others => True));
            EVC_Movement_Authority.Delete_MA;
            EVC_Track_Conditions.Reset
              (Rest => True, Horn => True, BMM => True);
            EVC_Position.Delete_Linking;
            EVC_Position.Delete_Geo;
         end if;
         EVC_Sessions.Request_Position_Report;
         EVC_Position.Shift_For_Manoeuvre
           (EVC_Radio_Authority.SM_Opposite, EVC_Train_Data.Consist);
         if not EVC_Train_Data.Manoeuvre_Set then
            EVC_Train_Data.Start_Manoeuvre_Set (EVC_Config.Current.Train);
         end if;
      elsif Current_Mode = M_NL or else not EVC_Mission.Mission then
         if EVC_Position.Manoeuvre_Orientation then
            EVC_Position.End_Manoeuvre;
         end if;
         if EVC_Train_Data.Manoeuvre_Set then
            EVC_Train_Data.End_Manoeuvre_Set;
         end if;
      end if;
   end Adjust_For_Manoeuvre;

   procedure Revalidate_Kept is
      use type EVC_Odometry.Cold_T;
   begin
      if Kept_Pending
        and then EVC_Odometry.Cold /= EVC_Odometry.Cold_Unknown
      then
         if EVC_Odometry.Cold = EVC_Odometry.No_Cold_Movement then
            EVC_Levels.Revalidate;
            EVC_Position.Revalidate;
            EVC_Radio.Revalidate_Contact;
         else
            EVC_Levels.Delete_Table;
         end if;
         Kept_Pending := False;
      end if;
   end Revalidate_Kept;

   procedure Delete_Invalid_Position (From, To : Mode_T) is
   begin
      if ((From = M_SB and then To in M_SN | M_UN | M_SR | M_NL | M_SH)
          or else To = M_SL)
        and then EVC_Position.Status = EVC_Position.Invalid
        and then EVC_Position.LRBG.Valid
      then
         EVC_Position.Delete_Position;
      end if;
   end Delete_Invalid_Position;

   procedure Save_Retained is
      --  every field is set below
      K : EVC_Retained.Kept_T;
   begin
      K.Saved := True;
      K.Level_Known := EVC_Levels.Status /= Unknown;
      K.Level := EVC_Levels.Level;
      K.Table := EVC_Levels.Table;
      EVC_Position.Keep (K.Position);
      --  the RBC contact information (EVC_Sessions writes it)
      K.RBC := EVC_Radio.Contact;
      --  3.5.6.2
      K.Network := EVC_Radio.Network;
      --  3.17.2.9: the system version operated
      K.Version_Known := True;
      K.Operated_X := EVC_System_Version.Operated;
      --  3.18.2.7: the national values applicable
      EVC_National_Values.Keep (K.National);
      --  3.15.9.5
      EVC_VBC.Keep (K.VBC);
      EVC_Retained.Save (K);
   end Save_Retained;

end EVC_Core.Modes;
