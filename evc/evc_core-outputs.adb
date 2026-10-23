--  ETCS on-board (EVC)
--  EVC_Core.Outputs, implementation.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Core.Records; use EVC_Core.Records;
with EVC_Core.Modes; use EVC_Core.Modes;

with EVC_JRU_Messages;
with ETCS_Variables;
with ETCS_Catalogue;

with EVC_DMI_Port;

package body EVC_Core.Outputs
  with SPARK_Mode => On
is

   use type EVC_Bytes.Byte_Array;
   use type EVC_Mission.Data_Status_T;
   use type EVC_Radio.Session_Ref_T;

   procedure Record_Mode_Levels_Mission is
   begin
      if Current_Mode /= Reported_Mode then
         Put_Event (JRU_Mode_Change,
                             Mode_T'Pos (Current_Mode),
                             Level_Status_T'Pos (EVC_Levels.Status),
                             Level_T'Pos (EVC_Levels.Level));
         Reported_Mode := Current_Mode;
      end if;
      for I in 1 .. EVC_Levels.Event_Count loop
         declare
            E : constant EVC_Levels.Event_T := EVC_Levels.Event (I);
         begin
            Put_Event (JRU_Levels, E.Kind, E.B3,
                                             E.B4);
         end;
      end loop;
      for I in 1 .. EVC_Mission.Event_Count loop
         declare
            E : constant EVC_Mission.Event_T := EVC_Mission.Event (I);
         begin
            Put_Mission_Event (E);
         end;
      end loop;
   end Record_Mode_Levels_Mission;

   procedure Show_Mode_Indications is
   begin
      --  4.4.15.1.1.3: the driver is informed that the non-leading
      --  operation is no longer permitted and asked to acknowledge it
      --  (the DMI's catalogue entry 35, ended by the acknowledgement)
      if EVC_Mission.NL_No_Longer_Permitted then
         EVC_Outbox.Put (DMI, System_Status_Frame
                                (SS_NL_No_Longer_Permitted,
                                 SS_Event_Start));
      end if;
      --  4.4.9.1.4: in FS, "Entering FS" until SSP and gradient are known
      --  for the whole length of the train (the DMI's catalogue entry 6);
      --  4.4.12.1.7: in OS, "Entering OS" (entry 7) the same (a mode
      --  change ends either on the DMI as well); 4.4.21.1.6: in SM,
      --  "Entering SM" (entry 8) until they are known for the whole length
      --  of the consist (decision: the train's length in SM is the sum of
      --  the max safe consist lengths, 3.18.3.2.4, so the stretch from the
      --  min safe rear end to the estimated front end is the consist's;
      --  4.4.21.1.5 asks nothing more at the entry: the SSP and gradient
      --  of the authorisation start at its LRBG, in front of the front end)
      declare
         Not_Covered : constant Boolean :=
           EVC_Stored_Information.MA_On_Board
           and then not EVC_Stored_Information.Train_Covered;
         Entering    : constant EVC_Bytes.Byte :=
           (if Not_Covered and then Current_Mode = M_FS then SS_Entering_FS
            elsif Not_Covered and then Current_Mode = M_OS
            then SS_Entering_OS
            elsif Not_Covered and then Current_Mode = M_SM
            then SS_Entering_SM
            else 0);
      begin
         if Entering /= Entering_Shown then
            if Entering_Shown /= 0 then
               EVC_Outbox.Put (DMI, System_Status_Frame
                                      (Entering_Shown, SS_Event_End));
            end if;
            if Entering /= 0 then
               EVC_Outbox.Put (DMI, System_Status_Frame
                                      (Entering, SS_Event_Start));
            end if;
            Entering_Shown := Entering;
         end if;
      end;
      --  3.14.2.6, 3.14.3.4, 4.4.7.1.5.4: the driver is shown that the
      --  roll away, the unauthorised direction movement or the standstill
      --  protection commands the brake ("Runaway movement", the DMI's
      --  entry 9, Table 68: 3.14.2.4, 3.14.3.2), until its revocation
      --  (3.14.1.5); the brake of a movement while the driver modifies
      --  or revalidates the Train Data too (3.18.3.3.1: the DMI
      --  specification's table of the system status messages starts
      --  entry 9 by 3.18.3.3.1 as well, ended by 3.14.1.5)
      declare
         Runaway : constant Boolean :=
           Brake_Output.Protection
           or else Brake_Output.Reasons
                     (EVC_Brake_Commands.Data_Entry_Movement);
      begin
         if Runaway /= Runaway_Shown then
            EVC_Outbox.Put (DMI, System_Status_Frame
                                   (SS_Runaway_Movement,
                                    (if Runaway
                                     then SS_Event_Start
                                     else SS_Event_End)));
            Runaway_Shown := Runaway;
         end if;
      end;
      --  3.6.8.5: the driver is informed when the odometer performance
      --  becomes impaired, and as long as it is (3.6.8.6.2); the entry
      --  ends when EVC_Odometry ends the impairment (3.6.8.6, the
      --  catalogue's "end = 3.6.8.6"). 4.5.2 Table: the check of the
      --  odometer accuracy thresholds is a function of SM, FS, AD, LS, SR
      --  and OS only (SUBSET-076 4050200_10 and _11: not shown in UN and
      --  SB)
      declare
         Show : constant Boolean :=
           EVC_Odometry.Impaired
           and then Odometer_Check_Mode (Current_Mode);
      begin
         if Show /= Odometer_Shown then
            EVC_Outbox.Put (DMI, System_Status_Frame
                                   (SS_Odometer_Impaired,
                                    (if Show
                                     then SS_Event_Start else SS_Event_End)));
            Odometer_Shown := Show;
         end if;
      end;
   end Show_Mode_Indications;

   procedure Show_Route_Unsuitable is
      Entry_Of : constant array (0 .. 2) of EVC_Bytes.Byte :=
        (SS_Route_Unsuitable_Gauge, SS_Route_Unsuitable_Axle_Load,
         SS_Route_Unsuitable_Traction);
   begin
      for K in Unsuitable_Shown'Range loop
         pragma Loop_Invariant (True);
         declare
            Show : constant Boolean :=
              EVC_Track_Description.Unsuitable_Kind
                (K, EVC_Train_Data.Categories);
         begin
            if Show /= Unsuitable_Shown (K) then
               EVC_Outbox.Put (DMI, System_Status_Frame
                                      (Entry_Of (K),
                                       (if Show
                                        then SS_Event_Start
                                        else SS_Event_End)));
               Unsuitable_Shown (K) := Show;
            end if;
         end;
      end loop;
   end Show_Route_Unsuitable;

   procedure Show_Trackside_Malfunction is
      use type ETCS_Catalogue.Packet_Kind_T;
      Found : Boolean := False;
   begin
      if Current_Mode in M_NP | M_SF | M_IS
        or else (Current_Mode = M_SB
                 and then EVC_Position.Active_Cab = EVC_Position.No_Cab)
      then
         return;
      end if;
      for G in 1 .. EVC_Position.Taken_Count loop
         pragma Loop_Invariant (True);
         declare
            Tk : constant EVC_Position.Taken_T := EVC_Position.Taken (G);
         begin
            for J in Tk.First .. Tk.First + Tk.Count - 1 loop
               pragma Loop_Invariant (True);
               for P in 1 .. EVC_Position.Taken_Packet_Count (J) loop
                  pragma Loop_Invariant (True);
                  if EVC_Position.Taken_Entry (J, P).Kind
                     = ETCS_Catalogue.Track_P254
                    and then EVC_Position.Valid_For
                               (EVC_Position.Taken_Entry (J, P).Q_DIR,
                                Tk.Group.Orientation, Tk.T)
                  then
                     Found := True;
                  end if;
               end loop;
            end loop;
         end;
      end loop;
      if Found then
         EVC_Outbox.Put (DMI, System_Status_Frame
                                (SS_Trackside_Malfunction, SS_Event_Start));
      end if;
   end Show_Trackside_Malfunction;

   procedure Send_Mode_Level is
   begin
      if Has_Mode_Code (Current_Mode) then
         EVC_Outbox.Put
           (DMI,
            Mode_Level_Frame
              (Current_Mode, EVC_Levels.Status, EVC_Levels.Level,
               Mode_Ack      =>
                 (if EVC_Mission.Proposed
                    and then Has_Mode_Code (EVC_Mission.Proposed_Mode)
                  then Mode_Code (EVC_Mission.Proposed_Mode)
                  elsif EVC_Procedures.Ack_Requested
                    and then Has_Mode_Code (EVC_Procedures.Ack_Mode)
                  then Mode_Code (EVC_Procedures.Ack_Mode)
                  else No_Code),
               Level_Ann     =>
                 (if EVC_Levels.Ack_Asked
                  then Level_Code (Valid, EVC_Levels.Ack_Level)
                  elsif EVC_Levels.Announced
                  then Level_Code (Valid, EVC_Levels.Announced_Level)
                  else No_Code),
               Level_Ann_Ack => EVC_Levels.Ack_Asked,
               Override      => EVC_Procedures.Override_Indicated,
               TAF           => EVC_Radio_Authority.TAF_Shown,
               --  4.4.19.1.4
               LSSMA         => EVC_LS_Display.LSSMA_Kmh));
      end if;
   end Send_Mode_Level;

   procedure Send_Procedure_Messages is
      Seconds : constant Unsigned_64 := Unsigned_64 (Clock_Ms) / 1000;
   begin
      for I in 1 .. EVC_Procedures.Status_Event_Count loop
         declare
            E : constant EVC_Procedures.Status_Event_T :=
              EVC_Procedures.Status_Event (I);
         begin
            EVC_Outbox.Put
              (DMI, System_Status_Frame (EVC_Bytes.Byte (E.Entry_Number),
                                         EVC_Bytes.Byte (E.Event)));
         end;
      end loop;
      --  those of the session half (3.5.3.7 d, 3.16.3.4.4)
      for I in 1 .. EVC_Sessions.Status_Event_Count loop
         declare
            E : constant EVC_Sessions.Status_Event_T :=
              EVC_Sessions.Status_Event (I);
         begin
            EVC_Outbox.Put
              (DMI, System_Status_Frame (EVC_Bytes.Byte (E.Entry_Number),
                                         EVC_Bytes.Byte (E.Event)));
         end;
      end loop;
      --  and the authority half's (5.6.2.2 A220, 5.6.4.1.2)
      if EVC_Radio_Authority.Status_Entry in 1 .. 255 then
         EVC_Outbox.Put
           (DMI, System_Status_Frame
                   (EVC_Bytes.Byte (EVC_Radio_Authority.Status_Entry),
                    EVC_DMI_Port.SS_Event_Start));
      end if;
      for I in 1 .. EVC_Text_Messages.Output_Count loop
         declare
            O : constant EVC_Text_Messages.Output_T :=
              EVC_Text_Messages.Output (I);
            F : Frame_Buffer_T;
            L : Natural;
         begin
            if EVC_Text_Messages."=" (O.Kind, EVC_Text_Messages.Show) then
               Text_Frame (O.Id, O.Flags,
                           EVC_Bytes.Byte (Seconds / 3600 mod 24),
                           EVC_Bytes.Byte (Seconds / 60 mod 60),
                           O.Text (1 .. O.Length), F, L);
               EVC_Outbox.Put (DMI, F (1 .. L));
            else
               EVC_Outbox.Put (DMI, Text_Remove_Frame (O.Id));
            end if;
         end;
      end loop;
   end Send_Procedure_Messages;

   procedure Record_Text_Display (I : Positive) is
      use EVC_JRU_Messages;
      E      : constant EVC_Text_Messages.Event_T :=
        EVC_Text_Messages.Event (I);
      Start  : constant Boolean :=
        E.Kind = EVC_Text_Messages.Event_Displayed;
      Fields : Fields_T := No_Fields;
      Text   : EVC_Text_Messages.Text_T;
      Length : Natural;
   begin
      if not Start and then E.Kind /= EVC_Text_Messages.Event_Removed then
         return;
      end if;
      if E.B4 = 1 then
         Length := EVC_Text_Messages.Event_Length (I);
         EVC_Text_Messages.Event_Text (I, Text);
         Fields (1) := (Value => Unsigned_64 (Length), Bits => 8);
         EVC_Outbox.Put_JRU
           ((if Start then NID_Plain_Start else NID_Plain_Stop),
            Unsigned_64 (Clock_Ms), Fields, Text, 8 * Length);
      else
         Fields (1) :=
           (Value => Unsigned_64 (EVC_Text_Messages.Event_Q_Text (I)),
            Bits  => 8);
         EVC_Outbox.Put_JRU
           ((if Start then NID_Fixed_Start else NID_Fixed_Stop),
            Unsigned_64 (Clock_Ms), Fields, No_Data);
      end if;
   end Record_Text_Display;

   procedure Record_Procedures is
   begin
      for I in 1 .. EVC_Procedures.Event_Count loop
         declare
            E : constant EVC_Procedures.Event_T := EVC_Procedures.Event (I);
         begin
            Put_Event (JRU_Procedures, E.Kind, E.B3,
                                             E.B4);
         end;
      end loop;
      for I in 1 .. EVC_Text_Messages.Event_Count loop
         declare
            E : constant EVC_Text_Messages.Event_T :=
              EVC_Text_Messages.Event (I);
         begin
            Record_Text_Display (I);
            Put_Event (JRU_Text_Messages, E.Kind, E.B3,
                                             E.B4);
         end;
      end loop;
   end Record_Procedures;

   procedure Send_Status (D                : EVC_Procedures.Brake_Demand_T;
                          Text_SB, Text_EB : Boolean) is
      --  the brakes of the procedures; 3 (DMI 8.2.2.3.4.1)
      --  while only an acknowledgement of a level (5.10.4.2), a mode or
      --  a text is missing; in IS the on-board is isolated from the
      --  brakes (4.4.3.1.1)
      Brake : constant EVC_Bytes.Byte :=
        (if Current_Mode = M_IS then Brake_None
         elsif Brake_Output.Ack_Required or else D.Ack_Required
         then Brake_Ack
         elsif Brake_Output.EB or else Brake_Output.SB
           or else Current_Mode = M_SF or else D.Trip or else D.Other
           or else EVC_Sessions.Service_Brake
         then Brake_Applied
         elsif EVC_Levels.Ack_Brake or else D.Ack_Missing
           or else Text_SB or else Text_EB
         then Brake_Ack_Pending
         else Brake_None);
      TTI   : constant Unsigned_16 :=
        (if SDM_Result.TTI = EVC_SDM.No_TTI then TTI_None
         else Unsigned_16 (SDM_Result.TTI));
      Rev   : constant Boolean := EVC_Procedures.Reversing_Possible;
      --  5.18.8: the tunnel stopping area
      Tun   : constant EVC_Track_Conditions.Tunnel_T :=
        EVC_Stored_Information.Tunnel;
      --  3.5.7.1: the indication of the safe radio connection
      Radio : constant EVC_Bytes.Byte :=
        EVC_Sessions.Indication_T'Pos (EVC_Sessions.Indication);
      --  3.18.4.6.2.3: the driver's "slippery rail" (the DMI's ST02)
      Slip  : constant Boolean :=
        EVC_Stored_Information.Driver_Slippery_Rail;
      --  5.22.4.1: the indication of the BTM alarm reaction inhibition
      --  until the procedure is ended (the DMI's ST07)
      BMM   : constant Boolean := EVC_Procedures.BMM_Inhibited;
      --  4.4.21.1.9: the SM authorised direction (the DMI's SM01 / SM02)
      SM    : constant EVC_Bytes.Byte :=
        (if Current_Mode = M_SM
         then EVC_Bytes.Byte (EVC_Position.Manoeuvre_Direction) else 0);
      Changed : constant Boolean :=
        Brake /= Status_Brake_Sent or else TTI /= Status_TTI_Sent
        or else Radio /= Status_Radio_Sent
        or else Rev /= Status_Rev_Sent or else Slip /= Status_Slip_Sent
        or else BMM /= Status_BMM_Sent or else SM /= Status_SM_Sent
        or else EVC_Track_Conditions."/=" (Tun, Status_Tunnel_Sent);
   begin
      if EVC_Position.Geo_Known then
         EVC_Outbox.Put
           (DMI, Status_Frame (Unsigned_32 (EVC_Position.Geo_Metres),
                               Unsigned_64 (Clock_Ms) / 1000,
                               Brake, TTI, Rev,
                               EVC_Bytes.Byte (Tun.State),
                               Unsigned_32 (Tun.Distance_M), Radio,
                               Slip, BMM, SM));
         Geo_Sent := True;
      elsif Geo_Sent or else Changed then
         EVC_Outbox.Put
           (DMI, Status_Frame (Geo_Unknown,
                               Unsigned_64 (Clock_Ms) / 1000,
                               Brake, TTI, Rev,
                               EVC_Bytes.Byte (Tun.State),
                               Unsigned_32 (Tun.Distance_M), Radio,
                               Slip, BMM, SM));
         Geo_Sent := False;
      end if;
      Status_Brake_Sent := Brake;
      Status_TTI_Sent := TTI;
      Status_Rev_Sent := Rev;
      Status_Slip_Sent := Slip;
      Status_BMM_Sent := BMM;
      Status_SM_Sent := SM;
      Status_Tunnel_Sent := Tun;
      Status_Radio_Sent := Radio;
   end Send_Status;

   function Train_Bits return Bits_T is
     ((if Standstill then Train_Standstill else 0)
      or (if Below_Override then Train_Below_Override else 0)
      or (if TIU_Now (Non_Leading_Permitted) then Train_Non_Leading else 0)
      or (if TIU_Now (Passive_Shunting_Permitted)
          then Train_Passive_Shunting else 0)
      or (if EVC_Procedures.BMM_Inhibited then Train_BMM_Inhibition
          else 0));

   function National_Bits return Bits_T is
     ((if EVC_VBC.Full then 0 else National_VBC_Room)
      or (if EVC_VBC.Count > 0 then National_VBC_Stored else 0)
      or (if EVC_National_Values.M_NVDERUN then National_Driver_ID_Running
          else 0)
      or (if EVC_National_Values.Q_NVDRIVER_ADHES then National_Adhesion
          else 0));

   function Session_Byte return EVC_Bytes.Byte is
     (if EVC_Radio.Supervising /= EVC_Radio.No_Session
        and then EVC_Radio.Established
                   (EVC_Radio.Session_T (EVC_Radio.Supervising))
        and then not EVC_Radio.Handover
        and then EVC_Radio.Supervising_Version_Known
        and then Natural (EVC_Radio.Info
                   (EVC_Radio.Session_T (EVC_Radio.Supervising)).Version)
                 > 2#010_0010#
      then Session_Exists + 1
      elsif EVC_Radio.Supervising /= EVC_Radio.No_Session
        and then EVC_Radio.Established
                   (EVC_Radio.Session_T (EVC_Radio.Supervising))
      then Session_Exists
      elsif (for some S in EVC_Radio.Session_T =>
               EVC_Radio.Being_Established (S))
      then Session_Being_Established
      else 0);

   procedure Send_Onboard is
      Onboard : constant Onboard_T :=
        (Data     => (if EVC_Levels.Valid then Data_Level_Valid else 0)
                     or (if EVC_Position.Status = EVC_Position.Valid
                           and then EVC_Position.LRBG.Valid
                         then Data_Position_Valid else 0)
                     --  the data of the start of mission
                     or (if EVC_Mission.Driver_ID_Status = EVC_Mission.Valid
                         then Data_Driver_ID_Valid else 0)
                     or (if EVC_Mission.Train_Data_Status
                              = EVC_Mission.Valid
                         then Data_Train_Data_Valid else 0)
                     or (if EVC_Mission.TRN_Status = EVC_Mission.Valid
                         then Data_TRN_Valid else 0)
                     --  the RBC contact (5.4.3.3)
                     or (if EVC_Radio.Contact.Known
                           and then EVC_Radio.Contact.Valid
                         then Data_RBC_Valid else 0)
                     --  the safe consist length (Table 33 #11)
                     or (if EVC_Train_Data.Consist_Available
                         then Data_Consist_Available else 0)
                     or (if EVC_Train_Data.Consist_Available
                           and then EVC_Train_Data.Consist.Front_Max = 0
                         then Data_Consist_Front_Zero else 0),
         Session  => Session_Byte,
         RBC      => (if EVC_Radio.Train_Data_Acknowledged
                      then RBC_Train_Data_Acked else 0)
                     --  5.11.2.2 D130, S130: the pending emergency stops;
                     --  S120: in PT in level 2, the choices of S140 wait
                     --  for the RBC's acknowledgement of the PT report too
                     --  (decision: the DMI's conditions of Start, Initiate
                     --  SM and Shunting in PT have no term of their own for
                     --  that wait, so it is reported as the pending stop
                     --  that keeps them disabled likewise)
                     or (if EVC_Radio_Authority.Emergency_Stops > 0
                           or else (Current_Mode = M_PT
                                    and then EVC_Levels.Level = L2
                                    and then not EVC_Radio_Authority
                                                 .Trip_Exit_Acknowledged)
                         then RBC_Pending_Stop else 0)
                     --  3.6.5.2.5 Table 2c [3], DMI 11.2.3.5 #3: the train
                     --  length and the under-reading amount within
                     --  L_TRAININT's 32767 m (7.5.1.57)
                     or (if EVC_Train_Data.Valid
                           and then EVC_Position.LRBG.Valid
                           and then EVC_Train_Data.Length <= 32_767 * 100
                           and then EVC_Position.Doubt_Under
                                    <= 32_767 * 100 - EVC_Train_Data.Length
                         then RBC_Length_In_Range else 0),
         --  bits 0-6 the radio networks (3.5.6)
         Radio    => Bits_T (EVC_Sessions.Radio_Bits)
                     or (if EVC_Radio.Contact.Known then Radio_Contact_Known
                         else 0),
         Radio_Wait => (if EVC_Sessions.Registration_Awaited then 2 else 0),
         --  5.4.3.2 D2: the position's status alone, also on an unlinked
         --  group or the SOLR without an LRBG
         Train    => Train_Bits
                     or (if EVC_Position.Status = EVC_Position.Valid
                         then Train_Position_Status_Valid else 0),
         National => National_Bits,
         --  SUBSET-026 5.4.3.2 S0 (DMI Table 49): the mode is SB, the
         --  desk is open and no session with an RBC exists or is being
      --  established, so the start of mission may begin (the desk is
      --  the cab status input, EVC_Mission)
         --  5.17.2.2 S6: the re-entry or re-validation of the Train Data
         --  requested, outside a start of mission (which asks for them)
         SoM      => (if EVC_Mission.SoM_Engaged then SoM_Possible
                      elsif EVC_Procedures.Train_Data_Revalidation
                      then SoM_Train_Data_Then
                      else 0),
      --  the request for shunting of level 2 (5.6.2.2 S050)
         --  (one value: the two do not overlap, the request for shunting
         --  needs the session established); else 5.4.3.2 A31, the
         --  session of the start of mission being opened; else 5.4.3.2
         --  S21 (DMI Table 50 S7), the answer to the MA request of
         --  'Start' (5.11.2.2 S150 too)
         Waiting  => (if EVC_Radio_Authority.SH_Waiting then 4
                      --  5.21.2.2 S050 (DMI Table 54a S1)
                      elsif EVC_Sessions.SM_Waiting then 5
                      elsif EVC_Sessions.SoM_Opening
                      then (if EVC_Sessions.Network_Ready then Waiting_RBC
                            --  5.4.3.2 S4 -> A42, timed out
                            elsif EVC_Sessions.Registration_Timed_Out
                            then 0
                            else Waiting_Registration)
                      elsif EVC_Mission.Waiting_For_RBC then Waiting_Start
                      else 0),
         Answer   => EVC_Bytes.Byte
                       (if EVC_Sessions.SM_Latest then EVC_Sessions.SM_Answer
                        else EVC_Radio_Authority.SH_Answer),
         others   => 0);
   begin
      EVC_Outbox.Put (DMI, Onboard_Frame (Onboard));
   end Send_Onboard;

   procedure Send_Networks is
      Frame : Frame_Buffer_T;
      Last  : Natural;
   begin
      if EVC_Sessions.Networks_List_Due then
         Networks_Frame
           (EVC_Sessions.Networks_Count,
            (Unsigned_32 (EVC_Sessions.Networks_Entry (1)),
             Unsigned_32 (EVC_Sessions.Networks_Entry (2))),
            Frame, Last);
         EVC_Outbox.Put (DMI, Frame (1 .. Last));
      end if;
   end Send_Networks;

   procedure Send_VBC_List is
      Frame : Frame_Buffer_T;
      Last  : Natural;
      Codes : VBC_Codes_T := (others => 0);
      N     : constant Natural := EVC_VBC.Count;
   begin
      if EVC_VBC.List_Due then
         for I in 1 .. N loop
            pragma Loop_Invariant (True);
            Codes (I) := EVC_VBC.Code (EVC_VBC.Item (I));
         end loop;
         VBC_List_Frame (N, Codes, Frame, Last);
         EVC_Outbox.Put (DMI, Frame (1 .. Last));
         EVC_VBC.Mark_Sent;
      end if;
   end Send_VBC_List;

   procedure Send_RBC_Contact is
      use type EVC_Radio.RBC_Id_T;
      use type ETCS_Variables.NID_RADIO_T;
      C     : constant EVC_Radio.RBC_Contact_T := EVC_Radio.Contact;
      Id    : constant Unsigned_32 :=
        Unsigned_32 (C.RBC.NID_C) * 2**14 + Unsigned_32 (C.RBC.NID_RBC);
      Frame : RBC_Contact_Frame_T;
   begin
      if C.Known /= Contact_Sent.Known
        or else C.RBC /= Contact_Sent.RBC
        or else C.Radio /= Contact_Sent.Radio
      then
         RBC_Contact_Frame (Known  => C.Known and then Id <= 16_777_214,
                            RBC_Id =>
                              (if Id <= 16_777_214 then Id else 0),
                            Radio  => Unsigned_64 (C.Radio),
                            Frame  => Frame);
         EVC_Outbox.Put (DMI, Frame);
         Contact_Sent := C;
      end if;
   end Send_RBC_Contact;

   procedure Send_System_Version is
      X : constant EVC_System_Version.Major_T :=
        EVC_System_Version.Operated;
   begin
      if EVC_Bytes.Byte (X) /= Version_Sent then
         EVC_Outbox.Put
           (DMI, System_Version_Frame
              (X => EVC_Bytes.Byte (X),
               Y => EVC_Bytes.Byte (EVC_System_Version.Operated_Y (X))));
         Version_Sent := EVC_Bytes.Byte (X);
      end if;
   end Send_System_Version;

   function TIU_Commands (D                : EVC_Procedures.Brake_Demand_T;
                          Text_SB, Text_EB : Boolean)
     return EVC_Bytes.Byte is
     (if Current_Mode = M_IS then 0
       else (if Brake_Output.EB or else Current_Mode = M_SF
                or else D.EB or else Text_EB
             then TIU_EBC else 0)
            or (if Brake_Output.SB or else EVC_Levels.Ack_Brake
                   or else D.SB or else Text_SB
                then TIU_SBC else 0)
            or (if Brake_Output.TCO then TIU_TCO else 0));

   function TIU_Reasons (D                : EVC_Procedures.Brake_Demand_T;
                         Text_SB, Text_EB : Boolean)
     return TIU_Reasons_T is
     (if Current_Mode = M_IS then 0
       else (if Brake_Output.Reasons (EVC_Brake_Commands.Speed_Distance)
             then TIU_Reason_Speed_Distance else 0)
            or (if Brake_Output.Reasons
                     (EVC_Brake_Commands.Service_Brake_Failed)
                then TIU_Reason_SB_Failed else 0)
            or (if Brake_Output.Reasons (EVC_Brake_Commands.Roll_Away)
                then TIU_Reason_Roll_Away else 0)
            or (if Brake_Output.Reasons (EVC_Brake_Commands.Direction)
                then TIU_Reason_Direction else 0)
            or (if Brake_Output.Reasons
                     (EVC_Brake_Commands.Standstill_Supervision)
                then TIU_Reason_Standstill else 0)
            or (if EVC_Levels.Ack_Brake then TIU_Reason_Level_Ack
                else 0)
            or (if Current_Mode = M_SF then TIU_Reason_Failure else 0)
            or (if D.Trip then TIU_Reason_Trip else 0)
            or (if D.Ack_Missing or else Text_SB or else Text_EB
                then TIU_Reason_Ack_Missing else 0)
            or (if D.Other
                   or else Brake_Output.Reasons
                             (EVC_Brake_Commands.Data_Entry_Movement)
                then TIU_Reason_Procedure else 0));

   procedure Send_Supervision
     (D                : EVC_Procedures.Brake_Demand_T;
      Text_SB, Text_EB : Boolean) is
      Commands : constant EVC_Bytes.Byte :=
        TIU_Commands (D, Text_SB, Text_EB);
      Why      : constant TIU_Reasons_T :=
        TIU_Reasons (D, Text_SB, Text_EB);
      Supervision_Now : constant Unsigned_32 :=
        (if SDM_Result.Active
         then Unsigned_32
                (EVC_SDM.Monitoring_T'Pos (SDM_Result.Monitoring))
              * 65_536
              + Unsigned_32 (EVC_SDM.Status_T'Pos (SDM_Result.Status))
                * 256
              + Unsigned_32 (SDM_Result.MRDT_Id)
         else No_Supervision);
      Overrun  : constant EVC_Bytes.Byte :=
        (if SDM_Result.EOA_Passed then 1 else 0)
        or (if SDM_Result.SvL_Passed then 2 else 0);
      Target_Shown : constant Boolean :=
        Speed_State.Monitoring /= 0
        or else (Speed_State.Flags and Flag_CSM_Target) /= 0;
      Shown_Now : constant SDM_Shown_T :=
        (V_Perm    => Speed_State.V_Perm,
         V_SBI     => Speed_State.V_SBI,
         V_Target  => (if Target_Shown then Speed_State.V_Target else 0),
         V_Release =>
           (if (Speed_State.Flags and Flag_Release_Shown) /= 0
            then Speed_State.V_Release else 0),
         TTI       => Status_TTI_Sent,
         D_Target  =>
           (if Target_Shown
            then Unsigned_32'Min (Speed_State.D_Target, 32_766)
            else 32_767));
   begin
      EVC_Outbox.Put (DMI, Speed_State_Frame (Speed_State));
      if Commands /= TIU_Sent or else Why /= TIU_Reasons_Sent then
         Put_Brake_States (Commands, TIU_Sent);
         Put_Event (JRU_Brake_Commands,
                    Commands
                    or EVC_Bytes.Byte (Shift_Left (Shift_Right (Why, 8),
                                                   3) and 16#F8#),
                    EVC_Bytes.Byte (Why and 16#FF#),
                    EVC_SDM.Status_T'Pos (SDM_Result.Status));
      end if;
      if (Supervision_Now /= Supervision_Reported
          or else Shown_Now /= SDM_Shown_Reported)
        and then SDM_Result.Active
      then
         Put_SDM (Shown_Now,
                  (Speed_State.Flags and Flag_Release_Shown) /= 0);
      end if;
      Supervision_Reported := Supervision_Now;
      SDM_Shown_Reported := Shown_Now;
      for Bit in EVC_Bytes.Byte range 1 .. 2 loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         if (Overrun and Bit) /= 0
           and then (Overrun_Reported and Bit) = 0
         then
            Put_Event (JRU_Overrun, Bit, 0, 0);
         end if;
      end loop;
      Overrun_Reported := Overrun;
      if Commands /= 0 or else Commands /= TIU_Sent
        or else Why /= TIU_Reasons_Sent
      then
         EVC_Outbox.Put (TIU, TIU_Output (Commands, Why));
      end if;
      TIU_Sent := Commands;
      TIU_Reasons_Sent := Why;
   end Send_Supervision;

   procedure Put_I32 (Frame   : in out TIU_TC_Frame_T;
                      Last    : in out Natural;
                      Present : Boolean;
                      V       : EVC_Distances.Dist_T) is
      C : constant Integer_64 :=
        (if Present
         then Integer_64'Max (-(2**31 - 1),
                              Integer_64'Min (Integer_64 (V),
                                              TIU_TC_None - 1))
         else TIU_TC_None);
      U : constant Unsigned_64 :=
        Unsigned_64 (Unsigned_32'Mod (C));
   begin
      for K in 0 .. 3 loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         Frame (Last + 1 + K) := EVC_Bytes.Byte_Of (U, K);
      end loop;
      Last := Last + 4;
   end Put_I32;

   procedure Send_External_Info is
      Info  : constant EVC_Track_Conditions.External_T :=
        EVC_Stored_Information.External_Info;
      Frame : TIU_TC_Frame_T := (others => 0);
      Last  : Natural := TIU_TC_Header_Length;
   begin
      if Info.Count > 0 or else TC_Sent then
         Frame (1) := TIU_TC_Tag;
         Frame (2) := 1;
         Frame (3) := EVC_Bytes.Byte (Natural'Min (Info.Count, TIU_TC_Max));
         for I in 1 .. Natural'Min (Info.Count, TIU_TC_Max) loop
            pragma Loop_Invariant
              (Last = TIU_TC_Header_Length + (I - 1) * TIU_TC_Entry_Length);
            declare
               E : constant EVC_Track_Conditions.External_Item_T :=
                 Info.List (I);
            begin
               Frame (Last + 1) := EVC_Bytes.Byte (E.Kind);
               Frame (Last + 2) := EVC_Bytes.Byte (E.Id);
               Last := Last + 2;
               Put_I32 (Frame, Last, E.Has_Start, E.To_Start);
               Put_I32 (Frame, Last, E.Has_End, E.To_End);
               Frame (Last + 1) := EVC_Bytes.Byte (E.Value mod 256);
               Frame (Last + 2) := EVC_Bytes.Byte (E.Value / 256);
               Last := Last + 2;
            end;
         end loop;
         EVC_Outbox.Put (TIU, Frame (1 .. Last));
      end if;
      TC_Sent := Info.Count > 0;
   end Send_External_Info;

   procedure Send_Remote_Shunting is
      Info : constant EVC_Bytes.Byte :=
        (case Current_Mode is
            when M_SH => TIU_RS_Ready,
            when M_SM =>
               TIU_RS_Ready
               or (if EVC_Position.Manoeuvre_Direction = 2
                   then TIU_RS_Opposite else 0),
            when others => 0);
   begin
      if Info /= TIU_RS_Sent then
         EVC_Outbox.Put (TIU, TIU_RS_Output (Info));
         TIU_RS_Sent := Info;
      end if;
   end Send_Remote_Shunting;

   procedure Send_Radio is
      Mark : constant Natural := EVC_Outbox.Used;
      RBCs : EVC_Outbox.RBC_Ids_T;
   begin
      EVC_Sessions.Produce (Radio_Context);
      EVC_Radio_Authority.Produce (Radio_Context);
      EVC_Radio.Drain;
      for S in RBCs'Range loop
         pragma Loop_Invariant (True);
         RBCs (S) := Unsigned_32 (EVC_Radio.Info (S).RBC.NID_C) * 2**14
                     + Unsigned_32 (EVC_Radio.Info (S).RBC.NID_RBC);
      end loop;
      EVC_Outbox.Put_JRU_Sent (Mark, Unsigned_64 (Clock_Ms), RBCs);
   end Send_Radio;

   procedure Produce_Outputs is
      --  the brake demands of the procedures and of the text
      --  messages (MSG_STATUS and the TIU output)
      D       : constant EVC_Procedures.Brake_Demand_T :=
        EVC_Procedures.Brake_Demand;
      --  with the service brake of the supervision of the safe
      --  radio connection (3.16.3.4.2 b), EVC_Sessions)
      Text_SB : constant Boolean :=
        EVC_Text_Messages.Service_Brake or else EVC_Sessions.Service_Brake;
      Text_EB : constant Boolean := EVC_Text_Messages.Emergency_Brake;
   begin
      Record_Mode_Levels_Mission;   -- JRU 1, 40, 41
      Show_Mode_Indications;        -- DMI MSG_SYSTEM_STATUS
      Show_Route_Unsuitable;        -- DMI MSG_SYSTEM_STATUS
      Show_Trackside_Malfunction;   -- DMI MSG_SYSTEM_STATUS
      Send_Mode_Level;              -- DMI MSG_MODE_LEVEL
      Send_Procedure_Messages;      -- DMI MSG_SYSTEM_STATUS, MSG_TEXT
      Record_Procedures;            -- JRU 23, 24
      Send_Status (D, Text_SB, Text_EB);  -- DMI MSG_STATUS
      Send_Onboard;                 -- DMI MSG_ONBOARD
      Send_Networks;                -- DMI MSG_RADIO_NETWORKS
      Send_VBC_List;                -- DMI MSG_VBC_LIST
      Send_RBC_Contact;             -- DMI MSG_RBC_CONTACT
      Send_System_Version;          -- DMI MSG_SYSTEM_VERSION
      --  DMI MSG_SPEED_STATE, JRU 20 to 22, TIU the commands
      Send_Supervision (D, Text_SB, Text_EB);
      Send_External_Info;           -- TIU the information of 5.20
      Send_Remote_Shunting;         -- TIU remote shunting
      Record_Actions_Cabs_Conditions;  -- JRU 11, 38, 45
      Record_Inputs_Radio_Data;     -- JRU 30, 31, 39, 48, 51, 124, 132
      Send_Radio;                   -- RTM
      Record_General;               -- JRU 1, 15, 47
      Flush_Juridical;              -- JRU, the messages of the cycle
   end Produce_Outputs;

end EVC_Core.Outputs;
