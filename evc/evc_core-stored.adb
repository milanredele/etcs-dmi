--  ETCS on-board (EVC)
--  EVC_Core.Stored, implementation.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Core.Records; use EVC_Core.Records;
with EVC_Core.Inputs; use EVC_Core.Inputs;

with EVC_Fixed;
with EVC_DMI_Port;
with EVC_Acceptance;
with ETCS_Message;
with ETCS_Catalogue;
with ETCS_Bits;

package body EVC_Core.Stored
  with SPARK_Mode => On
is

   use type EVC_Bytes.Byte_Array;
   use type EVC_Mission.Data_Status_T;
   use type ETCS_Message.Status_T;

   procedure Update_Position is
   begin
      --  the linking accepted by 4.8 and checked in the modes
      --  of 4.5.2 (3.4.4.2.1.1 b)
      EVC_Position.Set_Linking_Context
        (Accept_Info => EVC_Acceptance.Accepted
                          (EVC_Acceptance.Linking, Acceptance_Context)
                        --  4.8.3 [1]: kept in the balise
                        --  transition buffer instead, taken at the
                        --  transition (Release_Unit_Packets)
                        and then not EVC_Acceptance.Stored
                                       (EVC_Acceptance.Linking,
                                        Acceptance_Context),
         Check       => Linking_Check_Mode (Current_Mode),
         --  4.8.4.2: packet 79 of a balise group in the mode's column
         Accept_P79  => EVC_Acceptance.Accepted
                          (EVC_Acceptance.Geographical_Position,
                           Acceptance_Context),
         --  4.8.3 [1]: a group's own order
         --  to level 1 at a further location would make its linking
         --  stored: held until the stores evaluated the order
         --  (Take_Held_Linking)
         Defer_On_Order => EVC_Acceptance.Stored
                             (EVC_Acceptance.Linking, Ordered_Context),
         --  3.14.3.6: the information of the
         --  groups read during a movement opposite to the authorised
         --  direction is ignored. Decision: that movement is the one the
         --  unauthorised direction protection watches or brakes for
         --  (3.14.3.2, EVC_Brake_Commands, from the cycle before: a group
         --  read in the cycle the movement is first detected still counts)
         Ignore_Info    => Brake_State.Direction.Watching
                           or else Brake_State.Direction.Braking);
      EVC_Position.Update
        (Cab_A_Active => TIU_Now (Cab_A_Active),
         Cab_B_Active => TIU_Now (Cab_B_Active),
         Sampled      => Odometer_Fresh,
         Sample       => Odometer_Now,
         Mode         => Current_Mode,
         Level        => EVC_Levels.Level,
         Now_Ms       => Unsigned_64 (Clock_Ms));
      for I in 1 .. EVC_Position.Event_Count loop
         declare
            E : constant EVC_Position.Event_T := EVC_Position.Event (I);
         begin
            Put_Event (EVC_Position.Event_Code (E.Kind), E.B2, E.B3, E.B4);
         end;
      end loop;
      Standstill := Odometer_Now.V_Max = 0;
      --  5.8.2.1 a): "the train speed" is the estimated speed, the one
      --  shown to the driver and used for the speed monitoring
      --  (3.13.10.2.1), not its upper bound V_max
      Below_Override :=
        Natural (Odometer_Now.V_Est) <= EVC_National_Values.V_NVALLOWOVTRP;
   end Update_Position;

   function Mode_Speed return EVC_Supervision_Input.Speed_Cms_T is
     (EVC_Procedures.Mode_Speed
        (Current_Mode, EVC_National_Values.Current.Values,
         EVC_Mission.SR_Speed));

   function SR_Distance return EVC_Odometry.Virtual_T is
     (EVC_Radio_Authority.SR_Distance_Of (EVC_Mission.SR_Distance));

   function SR_Distance_Passed return Boolean is
     (SR_Distance.Active
      and then EVC_Odometry.Remaining_Estimated (SR_Distance) < 0);

   function SR_End return EVC_Distances.Dist_T is
     (EVC_Distances.Advance
        (EVC_Position.Front_X, EVC_Position.Orientation,
         EVC_Odometry.Remaining_Estimated (SR_Distance)));

   procedure Evaluate_Stored_Information is
      Frame : EVC_DMI_Port.Frame_Buffer_T;
      Last  : Natural;
   begin
      --  3.12.3: the text messages of the radio messages, while
      --  the origins of their LRBG are kept
      EVC_Text_Messages.Take_Radio;
      --  3.18.4.6.2.1: the driver's adhesion choice
      EVC_Stored_Information.Take_Driver_Adhesion;
      --  the mode profile of the mode in use is no temporary
      --  EOA (3.12.4.7)
      EVC_Movement_Authority.Set_Mode_In_Use
        (case Current_Mode is
            when M_OS   => 0,
            when M_SH   => 1,
            when M_LS   => 2,
            when others => 3);
      --  the mode related speed restriction (3.11.7, Mode_Speed); the
      --  status of the special brakes for the speed restrictions to
      --  ensure a permitted braking distance (3.11.11.4); the mode and
      --  the inputs of 4.8 and the SR distance (in Trip, 4.8.4
      --  refuses the MA and the track description, 5.11.2.2 A035); the
      --  virtual limits of the last cycle (5.18.4.2, 5.18.8.3)
      --  the profile of the work area of the supervision (EVC_SDM.Step
      --  builds it anew before it reads it) as the work area of the PBD
      EVC_Stored_Information.Evaluate
        (Unsigned_64 (Clock_Ms),
         Mode_Speed,
         Work           => SDM_Work.Profile,
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
         Context        =>
           (Mode        => Current_Mode,
            Cab_Active  => EVC_Train_Inputs.Desk_Open,
            TRN_Valid   => EVC_Mission.TRN_Status = EVC_Mission.Valid,
            SR_Distance => Current_Mode = M_SR
                           and then SR_Distance.Active,
            SR_End      => SR_End),
         Virtual_Last   => SDM_Result.Virtual);
      --  3.18.3.7 a): after the Train Data entered in the last cycle
      EVC_Stored_Information.Train_Data_Shortening
        (EVC_Mission.Categories_Changed);
      --  3.18.3.7 b): the radio information held for a transition
      if EVC_Mission.Categories_Changed and then EVC_Odometry.Standstill then
         EVC_Radio_Authority.Delete_Transition_Information;
      end if;
      for I in 1 .. EVC_Stored_Information.Event_Count loop
         declare
            E : constant EVC_Stored_Information.Event_T :=
              EVC_Stored_Information.Event (I);
         begin
            Put_Event (JRU_Stored, E.Info, E.Change,
                                             E.Detail);
         end;
      end loop;
      if EVC_Stored_Information.Track_Cond_Due then
         Track_Cond_Frame (EVC_Stored_Information.Track_Cond_Count,
                           EVC_Stored_Information.Track_Cond_List,
                           Frame, Last);
         EVC_Outbox.Put (DMI, Frame (1 .. Last));
      end if;
      --  3.15.10.3.1: the first Indication location of the last cycle's
      --  supervision, in Ceiling Speed monitoring only (3.15.10.1)
      EVC_Stored_Information.Set_Planning_Indication
        (SDM_Result.Active and then SDM_Result.Indication
           and then SDM_Result.Monitoring in EVC_SDM.CSM,
         Natural (EVC_Fixed.Num'Max
           (0, EVC_Fixed.Num'Min (SDM_Result.Indication_D, 6_553_400))));
      if EVC_Stored_Information.Planning_Due then
         Planning_Frame (EVC_Stored_Information.Planning, Frame, Last);
         if Last <= DMI_Max_Length then
            EVC_Outbox.Put (DMI, Frame (1 .. Last));
         end if;
      end if;
   end Evaluate_Stored_Information;

   procedure Take_Held_Linking is
   begin
      EVC_Position.Take_Held_Linking
        (Accept_Info => EVC_Acceptance.Accepted
                          (EVC_Acceptance.Linking, Acceptance_Context)
                        and then not EVC_Acceptance.Stored
                                       (EVC_Acceptance.Linking,
                                        Acceptance_Context));
   end Take_Held_Linking;

   procedure Release_Unit_Packets is
      pragma Warnings
        (GNATprove, Off, """R"" is set by * but not used after*",
         Reason => "the reader of one packet is not used after it");
      R : ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);
      K : ETCS_Catalogue.Packet_Kind_T;
      O0 : constant EVC_Distances.Sense_T := EVC_Position.Orientation;
      C0 : constant EVC_Position.Cab_T := EVC_Position.Active_Cab;
      L0 : constant EVC_Location.Anchor_T := EVC_Position.LRBG;
      DO0 : constant EVC_Distances.Length_T := EVC_Position.Doubt_Over;
      DU0 : constant EVC_Distances.Length_T := EVC_Position.Doubt_Under;
      M0 : constant Boolean := EVC_Position.Manoeuvre_Orientation;
      use type ETCS_Catalogue.Packet_Kind_T;
   begin
      for S in 1 .. EVC_Stored_Information.Balise_Buffered loop
         pragma Loop_Invariant
           (EVC_Position.Orientation = O0
            and then EVC_Position.Manoeuvre_Orientation = M0
            and then EVC_Position.Active_Cab = C0
            and then EVC_Position.LRBG = L0
            and then EVC_Position.Doubt_Over = DO0
            and then EVC_Position.Doubt_Under = DU0);
         for P in 1 .. EVC_Stored_Information.Balise_Set_Packets (S) loop
            pragma Loop_Invariant
              (EVC_Position.Orientation = O0
               and then EVC_Position.Manoeuvre_Orientation = M0
               and then EVC_Position.Active_Cab = C0
               and then EVC_Position.LRBG = L0
               and then EVC_Position.Doubt_Over = DO0
               and then EVC_Position.Doubt_Under = DU0);
            K := EVC_Stored_Information.Balise_Set_Kind (S, P);
            if K in ETCS_Catalogue.Track_P5 | ETCS_Catalogue.Track_P138
                  | ETCS_Catalogue.Track_P139
            then
               EVC_Stored_Information.Open_Balise_Packet (S, P, R);
               if K = ETCS_Catalogue.Track_P5 then
                  EVC_Position.Take_Released_Linking
                    (R, EVC_Stored_Information.Balise_Set_Group (S),
                     EVC_Stored_Information.Balise_Set_Sense (S));
               else
                  EVC_Procedures.Take_Released
                    (K, R, EVC_Stored_Information.Balise_Set_X (S),
                     EVC_Stored_Information.Balise_Set_Sense (S));
               end if;
            end if;
         end loop;
      end loop;
   end Release_Unit_Packets;

   procedure Release_Transition_Buffer is
      First    : constant Positive := EVC_Radio_Info.Count + 1;
      M_Status  : ETCS_Message.Status_T;
      S         : RTM_Session_T;
      Last      : Natural;
      Accepting : Boolean;
      Part      : Boolean;

      Ctx      : constant EVC_Stored_Information.Mode_Context_T :=
        (Mode        => Current_Mode,
         Cab_Active  => EVC_Train_Inputs.Desk_Open,
         TRN_Valid   => EVC_Mission.TRN_Status = EVC_Mission.Valid,
         SR_Distance => Current_Mode = M_SR and then SR_Distance.Active,
         SR_End      => SR_End);
   begin
      --  4.8.5.5: the sets of balise groups kept for
      --  the transition to level 1 (4.8.3 [1]), released and taken in
      --  the cycle of the transition as the radio ones in level 2
      if EVC_Levels.Switched_To (L1)
        and then EVC_Stored_Information.Balise_Buffered > 0
      then
         Release_Unit_Packets;
         EVC_Stored_Information.Release_Balise_Buffer
           (Unsigned_64 (Clock_Ms), Ctx);
      end if;
      if not EVC_Levels.Switched_To (L2)
        or else EVC_Radio_Authority.Buffered = 0
      then
         return;
      end if;
      EVC_Radio_Authority.Release_At_Transition;
      for I in 1 .. EVC_Radio_Authority.Buffer_Size loop
         pragma Loop_Invariant (True);
         exit when not EVC_Radio_Authority.Has_Released;
         Accepting := EVC_Radio_Authority.Released_Accepting;
         Part := EVC_Radio_Authority.Released_Part;
         EVC_Radio_Authority.Take_Released (S, Latched_RTM (1).Data, Last);
         EVC_Received.Receive_Message (Latched_RTM (1).Data (1 .. Last),
                                       M_Status);
         if M_Status = ETCS_Message.Accepted then
            --  4.8.2.1 c) exception 2: the Accepting RBC's; 4.8.5.2.1 the
            --  set of a general message
            EVC_Radio_Authority.Take_Message (S, Unsigned_64 (Clock_Ms),
                                              Accepting, Part);

            --  3.18.4.5.3: packet 140
            EVC_Mission.Take_RBC_TRN (Current_Mode);
         end if;
      end loop;
      EVC_Text_Messages.Take_Radio (First);
      EVC_Stored_Information.Evaluate_Released
        (First, Unsigned_64 (Clock_Ms), Ctx);
   end Release_Transition_Buffer;

   procedure Take_Radio_Linking is
      C : constant EVC_Acceptance.Context_T := Acceptance_Context;
   begin
      EVC_Position.Take_Radio_Linking
        (C.Level_Valid and then C.Level = L2
         and then EVC_Acceptance.Third_Filter (EVC_Acceptance.Linking, C));
   end Take_Radio_Linking;

   procedure Take_Radio_Geo is
   begin
      EVC_Position.Take_Radio_Geo
        (EVC_Acceptance.Radio_Geo_Verdict
           (Acceptance_Context,
            L2_Announced => EVC_Levels.Announced
                            and then EVC_Levels.Announced_Level = L2,
            --  4.8.5.4 c)
            Session_Up   => (for some S in EVC_Radio.Session_T =>
                               EVC_Radio.Established (S))));
   end Take_Radio_Geo;

   procedure Release_LS_Held is
   begin
      if not EVC_LS_Display.Order_Held then
         return;
      end if;
      if EVC_Levels.Switched_To (L2) then
         EVC_LS_Display.Release_Held (Take   => Current_Mode = M_LS,
                                      Now_Ms => Unsigned_64 (Clock_Ms));
      elsif not (EVC_Levels.Announced
                 and then EVC_Levels.Announced_Level = L2)
        or else not (for some S in EVC_Radio.Session_T =>
                       EVC_Radio.Established (S))
      then
         EVC_LS_Display.Release_Held (Take   => False,
                                      Now_Ms => Unsigned_64 (Clock_Ms));
      end if;
   end Release_LS_Held;

end EVC_Core.Stored;
