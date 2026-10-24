--  ETCS on-board (EVC)
--  EVC_Core.Records, implementation.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Balise_Groups;

package body EVC_Core.Records
  with SPARK_Mode => On
is

   use type EVC_Mission.Data_Status_T;

   procedure Put_Brake_States (Commands, Before : EVC_Bytes.Byte) is
      use EVC_JRU_Messages;
   begin
      for Bit in 0 .. 2 loop
         pragma Loop_Invariant (True);
         if (Shift_Right (Commands xor Before, Bit) and 1) /= 0 then
            EVC_Outbox.Put_JRU
              ((case Bit is
                  when 0      => NID_EB_State,
                  when 1      => NID_SB_State,
                  when others => NID_TCO_State),
               Unsigned_64 (Clock_Ms),
               (1      => (Value => Unsigned_64
                                      (Shift_Right (Commands, Bit) and 1),
                           Bits  => 1),
                others => (Value => 0, Bits => 0)),
               No_Data);
         end if;
      end loop;
   end Put_Brake_States;

   procedure Put_Consist (Available : Boolean;
                          C         : EVC_Train_Data.Consist_T)
   is
      use EVC_JRU_Messages;
      function L (V : EVC_Train_Data.Consist_Length_T) return Field_T is
        ((Value => Unsigned_64 (V), Bits => 12));
   begin
      if Available then
         EVC_Outbox.Put_JRU
           (NID_Consist, Unsigned_64 (Clock_Ms),
            (1      => (Value => 1, Bits => 1),
             2      => L (C.Front_Nom),
             3      => L (C.Front_Min),
             4      => L (C.Front_Max),
             5      => L (C.Rear_Nom),
             6      => L (C.Rear_Min),
             7      => L (C.Rear_Max),
             others => (Value => 0, Bits => 0)),
            No_Data);
      else
         EVC_Outbox.Put_JRU
           (NID_Consist, Unsigned_64 (Clock_Ms),
            (1      => (Value => 0, Bits => 1),
             others => (Value => 0, Bits => 0)),
            No_Data);
      end if;
   end Put_Consist;

   procedure Put_Event (Event, B2, B3, B4 : EVC_Bytes.Byte) is
      NID    : EVC_Bytes.Byte;
      Fields : EVC_JRU_Messages.Fields_T;
   begin
      EVC_JRU_Messages.Paired_Message (Event, B2, B3, B4, NID, Fields);
      if NID /= 0 then
         EVC_Outbox.Put_JRU (NID, Unsigned_64 (Clock_Ms), Fields, No_Data);
      end if;
      EVC_JRU_Messages.Event_Message (Event, B2, B3, B4, NID, Fields);
      EVC_Outbox.Put_JRU (NID, Unsigned_64 (Clock_Ms), Fields, No_Data);
   end Put_Event;

   procedure Put_Mission_Event (E : EVC_Mission.Event_T) is
      use EVC_JRU_Messages;
      SR   : constant EVC_Driver_Requests.SR_Entry_T :=
        EVC_Driver_Requests.SR_Data;
      Body_Buf  : EVC_JRU_Records.Body_T;
      Body_Bits : Natural;
   begin
      if E.Kind = EVC_Mission.Event_TRN then
         EVC_Outbox.Put_JRU (NID_TRN, Unsigned_64 (Clock_Ms),
                  (1      => (Value => Unsigned_64
                                (EVC_JRU_Records.TRN_Code (EVC_Mission.TRN)),
                              Bits  => 32),
                   others => (Value => 0, Bits => 0)),
                  No_Data);
      elsif E.Kind = EVC_Mission.Event_SR_Data
        and then EVC_Driver_Requests.Entered (EVC_Driver_Requests.SR_Data)
      then
         EVC_Outbox.Put_JRU (NID_SR_Data, Unsigned_64 (Clock_Ms),
                  (1      => (Value => Unsigned_64 (SR.Distance_M),
                              Bits  => 17),
                   2      => (Value => Unsigned_64 (SR.Speed_Kmh),
                              Bits  => 10),
                   others => (Value => 0, Bits => 0)),
                  No_Data);
      elsif E.Kind = EVC_Mission.Event_Train_Data then
         EVC_JRU_Records.Train_Data_Body
           (EVC_Train_Data.Data, EVC_Train_Data.Categories,
            Body_Buf, Body_Bits);
         EVC_Outbox.Put_JRU (NID_Train_Data, Unsigned_64 (Clock_Ms), No_Fields,
                  Body_Buf, Body_Bits);
      else
         Put_Event (EVC_Ports.JRU_Mission, E.Kind, E.B3, E.B4);
      end if;
   end Put_Mission_Event;

   procedure Put_Radio_Error (M_Error : EVC_Bytes.Byte) is
      R : constant EVC_Radio.RBC_Id_T := EVC_Radio.Supervising_RBC;
      F : EVC_JRU_Messages.Fields_T := EVC_JRU_Messages.No_Fields;
   begin
      F (1) := (Unsigned_64 (R.NID_C), 10);
      F (2) := (Unsigned_64 (R.NID_RBC), 14);
      F (3) := (Unsigned_64 (M_Error), 8);
      EVC_Outbox.Put_JRU (EVC_JRU_Messages.NID_Radio_Error,
                          Unsigned_64 (Clock_Ms), F, No_Data);
   end Put_Radio_Error;

   procedure Put_SDM (Shown : SDM_Shown_T; Release_Shown : Boolean) is
      function V (S : Unsigned_16) return Unsigned_64 is
        (Unsigned_64 (Unsigned_16'Min (S, 600)));
      F : EVC_JRU_Messages.Fields_T := EVC_JRU_Messages.No_Fields;
      No_Target : constant Boolean := Shown.D_Target >= 32_767;
   begin
      F (1) := (EVC_SDM.Monitoring_T'Pos (SDM_Result.Monitoring), 2);
      F (2) := (EVC_SDM.Status_T'Pos (SDM_Result.Status), 3);
      F (3) := (V (Shown.V_Perm), 10);
      F (4) := (V (Shown.V_SBI), 10);
      F (5) := ((if No_Target then 1023 else V (Shown.V_Target)), 10);
      F (6) := ((if No_Target then 32_767
                 else Unsigned_64 (Shown.D_Target)), 15);
      F (7) := ((if Release_Shown then V (Shown.V_Release) else 1023), 10);
      F (8) := (Unsigned_64 (Unsigned_16'Min (Shown.TTI, 15)), 4);
      EVC_Outbox.Put_JRU (EVC_JRU_Messages.NID_SDM, Unsigned_64 (Clock_Ms),
                          F, No_Data);
   end Put_SDM;

   procedure Report_Configuration is
      Loaded : constant Boolean :=
        EVC_Config.Last_Status = EVC_Config.Accepted;
   begin
      if EVC_Config.Report_Pending then
         Put_Event (JRU_Configuration,
                    (if Loaded then 1 else 2),
                    EVC_Config.Status_T'Pos (EVC_Config.Last_Status),
                    EVC_Bytes.Byte
                      (Natural'Min (EVC_Config.Rejections, 255)));
         EVC_Config.Report_Taken;
      end if;
   end Report_Configuration;

   procedure Record_General is
      use EVC_JRU_Messages;
      Version : constant Natural :=
        Natural (EVC_System_Version.Operated_Version);
      F       : Fields_T;
      use type EVC_Odometry.Cold_T;
   begin
      if not Started_Up then
         Started_Up := True;
         if EVC_Odometry.Cold /= EVC_Odometry.Cold_Movement then
            F := No_Fields;
            F (1) := (Value => (if EVC_Odometry.Cold
                                     = EVC_Odometry.No_Cold_Movement
                                then 0 else 2),
                      Bits  => 2);
            EVC_Outbox.Put_JRU (NID_Cold_Movement, Unsigned_64 (Clock_Ms),
                                F, No_Data);
         end if;
         EVC_JRU_Records.Interface_Fields
           (EVC_Config.Current.Supervision, F);
         EVC_Outbox.Put_JRU (NID_Brake_Config, Unsigned_64 (Clock_Ms), F,
                             No_Data);
      end if;
      if Current_Mode /= General_Mode then
         General_Ms := Clock_Ms;
      elsif Clock_Ms - General_Ms >= 5_000
        or else Version /= General_Version
        or else EVC_Levels.Level /= General_Level
      then
         EVC_Outbox.Put_JRU (NID_General, Unsigned_64 (Clock_Ms), No_Fields,
                             No_Data);
         General_Ms := Clock_Ms;
      end if;
      General_Mode := Current_Mode;
      General_Version := Version;
      General_Level := EVC_Levels.Level;
   end Record_General;

   procedure Record_System_Status is
      package DR renames EVC_Driver_Requests;
      SS      : constant DR.Ack_Kind_T := DR.System_Status;
      Changed : Boolean := False;
      F       : EVC_JRU_Messages.Fields_T := EVC_JRU_Messages.No_Fields;
   begin
      for I in 1 .. EVC_Outbox.Status_Count loop
         pragma Loop_Invariant (True);
         declare
            E : constant EVC_Outbox.Status_Event_T :=
              EVC_Outbox.Status_Event (I);
         begin
            EVC_JRU_Records.System_Status (E.Entry_Number, E.Event, Changed);
         end;
      end loop;
      EVC_Outbox.Clear_Status;
      --  the ends the DMI owns alone, reported by it (MSG_STATUS_ENDED)
      for I in 1 .. DR.Status_End_Count loop
         pragma Loop_Invariant (True);
         EVC_JRU_Records.System_Status (DR.Status_End (I), 1, Changed);
      end loop;
      if DR.Acknowledged (SS)
        and then DR.Ack_Id (SS) in 16#8000# .. 16#80FF#
      then
         EVC_JRU_Records.System_Status_Acknowledged
           (EVC_Bytes.Byte (DR.Ack_Id (SS) - 16#8000#), Changed);
      end if;
      if Changed then
         F (1) := (Value => Unsigned_64 (EVC_JRU_Records.Status_Shown),
                   Bits  => 31);
         EVC_Outbox.Put_JRU (EVC_JRU_Messages.NID_System_Status,
                             Unsigned_64 (Clock_Ms), F,
                             No_Data);
      end if;
   end Record_System_Status;

   procedure Record_Actions_Cabs_Conditions is
      use EVC_Driver_Requests;
      use EVC_JRU_Records;
      Code    : EVC_Bytes.Byte;
      Changed : Boolean;
      TC      : TC_Changes_T;
      Body_Buf  : Body_T;
      Body_Bits : Natural;
   begin
      for A in Action_T loop
         pragma Loop_Invariant (True);
         if Selected (A) then
            Code := Action_Code (A, Argument (A));
            if Code /= EVC_JRU_Records.No_Code then
               Put_Event (JRU_Driver_Action, Code, 0, 0);
            end if;
         end if;
      end loop;
      for K in Ack_Kind_T loop
         pragma Loop_Invariant (True);
         if Acknowledged (K) then
            Code := Ack_Code (K, Ack_Id (K));
            if Code /= EVC_JRU_Records.No_Code then
               Put_Event (JRU_Driver_Action, Code, 0, 0);
            end if;
         end if;
      end loop;
      for K in Data_Kind_T loop
         pragma Loop_Invariant (True);
         if Entered (K)
           and then Data_Code (K, Data_Byte (K)) /= EVC_JRU_Records.No_Code
         then
            Put_Event (JRU_Driver_Action, Data_Code (K, Data_Byte (K)), 0, 0);
         end if;
      end loop;
      Record_System_Status;
      Cab_Status (TIU_Now (Cab_A_Active), TIU_Now (Cab_B_Active),
                  TIU_Known_Now (Cab_A_Active)
                  or else TIU_Known_Now (Cab_B_Active),
                  Changed);
      if Changed then
         Put_Event (JRU_Cab_Status,
                             (if TIU_Now (Cab_A_Active) then 1 else 0), 1,
                             (if TIU_Now (Cab_B_Active) then 1 else 0));
      end if;
      Track_Conditions (EVC_Stored_Information.External_Info, TC);
      if TC.Count > 0 then
         EVC_JRU_Records.Track_Conditions_Body
           (EVC_Stored_Information.External_Info, Body_Buf, Body_Bits);
         EVC_Outbox.Put_JRU (EVC_JRU_Messages.NID_Track_Conds,
                             Unsigned_64 (Clock_Ms),
                             EVC_JRU_Messages.No_Fields,
                             Body_Buf, Body_Bits);
      end if;
      for I in 1 .. TC.Count loop
         pragma Loop_Invariant (True);
         Put_Event (JRU_Track_Conditions, TC.List (I).TI,
                             TC.List (I).Phase, TC.List (I).Id);
      end loop;
   end Record_Actions_Cabs_Conditions;

   procedure Record_Inputs_Radio_Data is
      use EVC_Driver_Requests;
      use EVC_JRU_Records;
      function Flag (S : TIU_Signal_T) return Input_Value_T is
        (if not TIU_Known_Now (S) then No_Value
         elsif TIU_Now (S) then 1 else 0)
        with Global => (TIU_Now, TIU_Known_Now);
      Now : constant Input_Values_T :=
        (Sleeping         => Flag (Sleeping_Requested),
         Passive_Shunting => Flag (Passive_Shunting_Permitted),
         Non_Leading      => Flag (Non_Leading_Permitted),
         Direction        =>
           (if TIU_Known_Now (Direction_Controller)
            then Direction_Code (Natural (TIU_Value_Now
                                            (Direction_Controller)))
            else No_Value),
         --  SUBSET-027 4.2.4.50: message 50 at the first value received
         --  and at each change
         Integrity        =>
           (if TIU_Known_Now (Train_Integrity)
            then Integrity_Code (Natural (TIU_Value_Now (Train_Integrity)))
            else No_Value),
         Remote_Shunting  =>
           (if (TIU_RS_Sent and EVC_Ports.TIU_RS_Ready) /= 0
            then 1 else 0));
      Changes : Input_Changes_T;
      RBC     : constant Bytes_23_T := EVC_Driver_Requests.RBC_Data;
      Q       : constant EVC_Bytes.Byte := RBC_Entry_Code (RBC (1));
      MN      : MN_Bytes_T;
      F       : EVC_JRU_Messages.Fields_T;
      V       : Natural;
      Changed : Boolean;
   begin
      Inputs (Now, Changes);
      for I in Input_T loop
         pragma Loop_Invariant (True);
         if Changes (I) then
            Put_Event (Input_Event (I),
                                EVC_Bytes.Byte (Now (I)), 0, 0);
         end if;
      end loop;
      if Entered (EVC_Driver_Requests.RBC_Data)
        and then Q /= EVC_JRU_Records.No_Code
      then
         RBC_Entry_Fields (RBC, Q, F);
         EVC_Outbox.Put_JRU (EVC_JRU_Messages.NID_RBC_Entry,
                             Unsigned_64 (Clock_Ms), F, No_Data);
      end if;
      if Entered (GSMR_Network) then
         MN := MN_Code (EVC_Driver_Requests.GSMR_Network);
         Put_Event (48, MN (1), MN (2), MN (3));
      end if;
      if EVC_Sessions.Contact_Error then
         Put_Radio_Error (5);
      end if;
      LSSMA ((if EVC_LS_Display.LSSMA_Kmh = EVC_LS_Display.No_LSSMA
              then V_LSSMA_None
              else Natural (EVC_LS_Display.LSSMA_Kmh)),
             V, Changed);
      if Changed then
         EVC_Outbox.Put_JRU
           (EVC_JRU_Messages.NID_LSSMA, Unsigned_64 (Clock_Ms),
            (1      => (Value => Unsigned_64 (V), Bits => 10),
             others => (Value => 0, Bits => 0)),
            No_Data);
      end if;
   end Record_Inputs_Radio_Data;

   function Reference_Of (P : ETCS_Train_Packets.P0.Packet_T)
     return EVC_JRU_Messages.Reference_T is
     (Q_Scale => Natural (P.Q_SCALE),
       NID     => Natural (P.NID_C) * 2**14 + Natural (P.NID_BG),
       D       => Natural (P.D_LRBG),
       Q_Dir   => Natural (P.Q_DIRLRBG),
       Q_D     => Natural (P.Q_DLRBG),
       Over    => Natural (P.L_DOUBTOVER),
       Under   => Natural (P.L_DOUBTUNDER));

   function SOLR_Reference return EVC_JRU_Messages.Reference_T is
      use type EVC_Distances.Direction_T;
      S   : constant EVC_Location.Anchor_T := EVC_Position.SOLR;
      Est : constant EVC_Distances.Dist_T :=
        EVC_Position.SOLR_Estimated_Front;
      Orient : constant EVC_Distances.Sense_T := EVC_Position.Orientation;
      Known  : constant Boolean := EVC_Position.Orientation_Known
                                   and then S.Orientation
                                            /= EVC_Distances.Unknown;
      --  2 unknown, 1 nominal when D is the SOLR's direction, 0 reverse
      function Q (D : EVC_Distances.Direction_T) return Natural is
        (if not Known then 2 elsif D = S.Orientation then 1 else 0);
      function M (D : EVC_Distances.Cm_T) return Natural is
        (Natural (EVC_Distances.Cm_T'Min ((abs D + 99) / 100, 32_767)))
        with Pre => D in -2 * EVC_Distances.Max_Cm .. 2 * EVC_Distances.Max_Cm;
   begin
      return (Q_Scale => 1,
              NID     => Natural (S.Id.NID_C) * 2**14
                         + Natural (S.Id.NID_BG),
              D       => M (Est),
              Q_Dir   => Q (EVC_Distances.To_Direction (Orient)),
              Q_D     => Q (EVC_Distances.To_Direction
                              (if Est >= 0 then Orient
                               else EVC_Distances.Opposite (Orient))),
              Over    => M (EVC_Position.SOLR_Max_Safe_Front - Est),
              Under   => M (Est - EVC_Position.SOLR_Min_Safe_Front));
   end SOLR_Reference;

   procedure Flush_Juridical is
      use type EVC_Balise_Groups.Identity_T;
      P : constant ETCS_Train_Packets.P0.Packet_T :=
        EVC_Position.Position_Report (Current_Mode, EVC_Levels.Level);
      L : constant EVC_Location.Anchor_T := EVC_Position.LRBG;
      S : constant EVC_Location.Anchor_T := EVC_Position.SOLR;
      H : EVC_JRU_Messages.Header_T;
   begin
      if L.Valid and then S.Valid and then S.Id /= L.Id then
         H.Q_LRBG := 2;
         H.SOLR := SOLR_Reference;
         H.LRBG := Reference_Of (P);
      elsif L.Valid then
         H.Q_LRBG := 1;
         H.SOLR := Reference_Of (P);
      elsif S.Valid then
         H.SOLR := SOLR_Reference;
      end if;
      H.V_Train :=
        (if EVC_Odometry.Standstill then 1023
         else Natural'Min (Natural (EVC_Odometry.Speed) * 36 / 1000, 600));
      if EVC_Mission.Driver_ID_Status /= EVC_Mission.Unknown then
         for I in H.Driver_Id'Range loop
            pragma Loop_Invariant (True);
            H.Driver_Id (I) := EVC_Mission.Driver_ID.Chars (I);
         end loop;
      end if;
      H.NID_Engine := Natural (EVC_Radio.Engine_Id);
      H.M_Version := Natural (EVC_System_Version.Operated_Version);
      H.M_Level := Natural (P.M_LEVEL);
      H.M_Mode := Natural (P.M_MODE);
      EVC_Outbox.Flush_JRU (H, UTC_Known, UTC_Seconds);
   end Flush_Juridical;

end EVC_Core.Records;
