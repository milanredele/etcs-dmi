--  ETCS on-board (EVC)
--  EVC_Core.Inputs, implementation.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Core.Records; use EVC_Core.Records;

with EVC_JRU_Messages;
with ETCS_Variables;
with ETCS_Telegram;
with ETCS_Message;

package body EVC_Core.Inputs
  with SPARK_Mode => On
is

   use type EVC_Bytes.Byte_Array;
   use type EVC_Mission.Data_Status_T;
   use type ETCS_Message.Status_T;
   use type ETCS_Telegram.Status_T;

   procedure Latch_RTM (Payload : EVC_Bytes.Byte_Array) is
      S : constant RTM_Session_T := RTM_Session (Payload);
   begin
      if Valid_RTM_Event (Payload) then
         if Latched_Event_Count < RTM_Latch_Size then
            Latched_Event_Count := Latched_Event_Count + 1;
            Latched_Events (Latched_Event_Count) :=
              (Session => S, Event => RTM_Event (Payload),
               RBC     =>
                 (if RTM_Event_Has_RBC (Payload)
                  then (NID_C   => ETCS_Variables.NID_C_T
                                       (RTM_Event_NID_C (Payload)),
                        NID_RBC => ETCS_Variables.NID_RBC_T
                                       (RTM_Event_NID_RBC (Payload)))
                  else EVC_Radio.No_RBC));
         else
            Count (Overflow_Count (RTM));
         end if;
      elsif Latched_RTM_Count < RTM_Latch_Size then
         declare
            --  the message: after the tag and the session when tagged
            First : constant Positive :=
              (if Payload (Payload'First) < RTM_Tag_First then Payload'First
               else Payload'First + RTM_Tagged_Header);
            Length : constant Natural := Payload'Last - First + 1;
         begin
            pragma Assert
              (Valid_RTM_Frame (Payload (First .. Payload'Last)));
            Latched_RTM_Count := Latched_RTM_Count + 1;
            Latched_RTM (Latched_RTM_Count).Session := S;
            Latched_RTM (Latched_RTM_Count).Length := Length;
            Latched_RTM (Latched_RTM_Count).Data (1 .. Length) :=
              Payload (First .. Payload'Last);
         end;
      else
         Count (Overflow_Count (RTM));
      end if;
   end Latch_RTM;

   procedure Latch_SCL (Payload : EVC_Bytes.Byte_Array) is
      subtype L is EVC_Train_Data.Consist_Length_T;
   begin
      Latched_SCL_Fresh := True;
      if Payload (Payload'First + 1) = 1 then
         Latched_SCL :=
           (Front_Nom => L (SCL_At (Payload, 2)),
            Front_Min => L (SCL_At (Payload, 4)),
            Front_Max => L (SCL_At (Payload, 6)),
            Rear_Nom  => L (SCL_At (Payload, 8)),
            Rear_Min  => L (SCL_At (Payload, 10)),
            Rear_Max  => L (SCL_At (Payload, 12)));
      end if;
   end Latch_SCL;

   procedure Read_Telegrams is
      T_Status : ETCS_Telegram.Status_T;
      --  what the telegrams do not change (the position takes them at
      --  its next Update)
      LRBG_0        : constant EVC_Location.Anchor_T := EVC_Position.LRBG
        with Ghost;
      Orientation_0 : constant EVC_Distances.Sense_T :=
        EVC_Position.Orientation
        with Ghost;
      Over_0        : constant EVC_Distances.Length_T :=
        EVC_Position.Doubt_Over
        with Ghost;
      Under_0       : constant EVC_Distances.Length_T :=
        EVC_Position.Doubt_Under
        with Ghost;
      Fixed_0       : constant Boolean := EVC_Position.Manoeuvre_Orientation
        with Ghost;
   begin
      for I in 1 .. Latched_BTM_Count loop
         pragma Loop_Invariant
           (EVC_Position.LRBG = LRBG_0
            and then EVC_Position.Orientation = Orientation_0
            and then EVC_Position.Manoeuvre_Orientation = Fixed_0
            and then EVC_Position.Doubt_Over = Over_0
            and then EVC_Position.Doubt_Under = Under_0);
         declare
            Slot : BTM_Slot_T renames Latched_BTM (I);
         begin
            if Valid_BTM_Input (Slot.Data (1 .. Slot.Length))
              and then EVC_VBC.Covered
                         (BTM_Telegram (Slot.Data (1 .. Slot.Length)))
            then
               --  3.15.9.3 a), b), 3.15.9.3.1, 4.8.2.3: a telegram under a
               --  Virtual Balise Cover is not received, before any check
               --  of its version: only the juridical data record it (3.20,
               --  SUBSET-027 4.2.4.6)
               EVC_Outbox.Put_JRU
                 (EVC_JRU_Messages.NID_Telegram, Unsigned_64 (Clock_Ms),
                  EVC_JRU_Messages.No_Fields,
                  Slot.Data (BTM_Stamp_Length + 3 .. Slot.Length),
                  Natural (Slot.Data (BTM_Stamp_Length + 1))
                  + 256 * Natural (Slot.Data (BTM_Stamp_Length + 2)));
            elsif Valid_BTM_Input (Slot.Data (1 .. Slot.Length)) then
               EVC_Received.Receive_Telegram
                 (BTM_Telegram (Slot.Data (1 .. Slot.Length)), T_Status);
               --  SUBSET-027 4.2.4.6, 4.3.1.1: every telegram received,
               --  accepted or not, as received, its bits after their
               --  count (EVC_Ports, BTM)
               EVC_Outbox.Put_JRU
                 (EVC_JRU_Messages.NID_Telegram, Unsigned_64 (Clock_Ms),
                  EVC_JRU_Messages.No_Fields,
                  Slot.Data (BTM_Stamp_Length + 3 .. Slot.Length),
                  Natural (Slot.Data (BTM_Stamp_Length + 1))
                  + 256 * Natural (Slot.Data (BTM_Stamp_Length + 2)));
               if T_Status /= ETCS_Telegram.Accepted
                 and then EVC_Received.Header_Read (T_Status)
               then
                  --  3.16.1.1: a balise of its group read, not compliant;
                  --  of a version not read, its content left out (3.17)
                  EVC_Position.Receive_Refused
                    (EVC_Received.Refused_Header,
                     BTM_Stamp (Slot.Data (1 .. Slot.Length)),
                     Compliant =>
                       T_Status = ETCS_Telegram.Unsupported_Version);
               end if;
               if T_Status = ETCS_Telegram.Accepted then
                  EVC_Position.Receive_Telegram
                    (EVC_Received.Last_Telegram,
                     BTM_Stamp (Slot.Data (1 .. Slot.Length)));
               elsif T_Status = ETCS_Telegram.Unsupported_Version
                 --  3.17.3.5, 4.6.3 [65]: the X of M_VERSION, the three
                 --  most significant of the seven bits after Q_UPDOWN
                 --  (the first byte of the telegram), above the highest
                 --  X of the envelope (EVC_System_Version, 6.4.2.1)
                 and then (Slot.Data (BTM_Stamp_Length + 3) and 16#7F#) / 16
                            > Unsigned_8 (EVC_System_Version.Highest_X)
               then
                  EVC_Procedures.Note_Version_Not_Supported;
               end if;
            elsif Valid_BTM_Detection (Slot.Data (1 .. Slot.Length)) then
               --  3.16.2.5.1 b): a balise detected, no telegram decoded
               EVC_Position.Receive_Detection
                 (BTM_Stamp (Slot.Data (1 .. Slot.Length)));
            end if;
         end;
      end loop;
      Latched_BTM_Count := 0;
   end Read_Telegrams;

   procedure Read_Radio_Events is
   begin
      for I in 1 .. Latched_Event_Count loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         EVC_Sessions.Take_Event (Latched_Events (I).Session,
                                  Latched_Events (I).Event,
                                  Unsigned_64 (Clock_Ms),
                                  Latched_Events (I).RBC);
      end loop;
      Latched_Event_Count := 0;
   end Read_Radio_Events;

   procedure Put_From_RBC (Slot : RTM_Slot_T) is
      R : constant EVC_Radio.RBC_Id_T := EVC_Radio.Info (Slot.Session).RBC;
      F : EVC_JRU_Messages.Fields_T := EVC_JRU_Messages.No_Fields;
   begin
      F (1) := (Unsigned_64 (R.NID_C), 10);
      F (2) := (Unsigned_64 (R.NID_RBC), 14);
      EVC_Outbox.Put_JRU (EVC_JRU_Messages.NID_From_RBC,
                          Unsigned_64 (Clock_Ms), F,
                          Slot.Data (1 .. Slot.Length));
   end Put_From_RBC;

   procedure Record_Radio_Error is
   begin
      if EVC_Sessions.Error_Noted then
         Put_Radio_Error (EVC_Bytes.Byte (EVC_Sessions.Error_Noted_Code));
      end if;
   end Record_Radio_Error;

   procedure Read_Radio_Messages is
      use type EVC_Sessions.Verdict_T;
      M_Status : ETCS_Message.Status_T;
      Verdict  : EVC_Sessions.Verdict_T;
   begin
      for I in 1 .. Latched_RTM_Count loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         declare
            Slot : RTM_Slot_T renames Latched_RTM (I);
         begin
            if Valid_RTM (Slot.Data (1 .. Slot.Length)) then
               --  the message from the RBC (SUBSET-027 record
               --  9) recorded at reception, whatever its later use: one
               --  record per message the RTM port delivers with a
               --  consistent L_MESSAGE (7.5.1.48). Decision: "received"
               --  is what the Euroradio delivers (3.16.3.1.1.2 speaks of
               --  an inconsistent message "received"), so a message the
               --  codec refuses (3.16.1.1, 3.16.3.1.1 c; a spare value, an
               --  unknown NID_MESSAGE such as 254), one with an undefined
               --  packet and one the time stamp check refuses later
               --  (3.16.3.3.3) are recorded too, the refusal by a JRU 13
               --  with M_ERROR after it; so is a frame whose length
               --  disagrees with L_MESSAGE (below).
               --  NID_MESSAGE, L_MESSAGE (u16)
               Put_From_RBC (Slot);
               EVC_Received.Receive_Message
                 (Slot.Data (1 .. Slot.Length), M_Status);
               if M_Status = ETCS_Message.Accepted
                 and then EVC_Received.Last_Unknown_Packets > 0
               then
                  --  3.16.1.1, 3.16.3.1.1.2: a packet
                  --  chapter 7 does not define makes the message not
                  --  compliant: reported (M_ERROR 3), not used.
                  --  decision on the order of the checks of
                  --  3.16.3.1.1: the general criteria of 3.16.1.1 come
                  --  first, before the time stamp check b) of
                  --  EVC_Sessions.Take_Message: a message both stale and
                  --  with an undefined packet is reported once, M_ERROR 3.
                  --  (3160300_01 SV21 expects 4 because its packet 72 is
                  --  defined in system version 2 by chapter 6, 6.6.5.2.3,
                  --  which this on-board does not translate)
                  EVC_Sessions.Take_Inconsistent (Slot.Session);
                  Record_Radio_Error;
               elsif M_Status = ETCS_Message.Accepted then
                  EVC_Sessions.Take_Message
                    (Slot.Session, Unsigned_64 (Clock_Ms), Verdict);
                  Record_Radio_Error;
                  --  4.8.3 [2], 4.8.5.1: kept in the transition buffer of
                  --  the authority half, or taken
                  if Verdict = EVC_Sessions.Ignore then
                     null;
                  elsif Verdict = EVC_Sessions.Buffered
                    or else EVC_Radio_Authority.To_Buffer
                  then
                     --  also the Accepting RBC's (4.8.5.2)
                     EVC_Radio_Authority.Store_Message
                       (Slot.Session, Slot.Data (1 .. Slot.Length),
                        Accepting => Verdict = EVC_Sessions.Buffered);
                  else
                     --  4.8.5.2.1: the packets on the rows R [2] kept as a
                     --  set, the others taken
                     EVC_Radio_Authority.Keep_Level_2_Part
                       (Slot.Session, Slot.Data (1 .. Slot.Length));
                     EVC_Radio_Authority.Take_Message
                       (Slot.Session, Unsigned_64 (Clock_Ms));
                     --  3.18.4.5.3: packet 140
                     EVC_Mission.Take_RBC_TRN (Current_Mode);
                  end if;
               elsif M_Status = ETCS_Message.Unknown_Message then
                  --  3.17.3.11 b): an unknown NID_MESSAGE is not a message
                  --  data consistency error; recorded above (record 9),
                  --  its content ignored, nothing reported. Decision: for
                  --  an RBC of any version, since this on-board cannot
                  --  tell a message of a higher Y from a spare value of
                  --  its own (the conformance test's reading); a spare
                  --  value of a known message stays an error (3.16.1.1.1)
                  null;
               else
                  --  3.16.3.1.1 c), 3.16.3.1.1.2
                  EVC_Sessions.Take_Inconsistent (Slot.Session);
                  Record_Radio_Error;
               end if;
            else
               --  8.4.4.2.1, 3.16.3.1.1 c): the length received differs
               --  from L_MESSAGE. Recorded as received (record 9: its
               --  NID_MESSAGE and the length received, not L_MESSAGE),
               --  not parsed, reported inconsistent (M_ERROR 3)
               Put_From_RBC (Slot);
               EVC_Sessions.Take_Inconsistent (Slot.Session);
               Record_Radio_Error;
            end if;
         end;
      end loop;
      Latched_RTM_Count := 0;
   end Read_Radio_Messages;

   procedure Read_Released_Messages is
      M_Status  : ETCS_Message.Status_T;
      S         : RTM_Session_T;
      Last      : Natural;
      Accepting : Boolean;
      Part      : Boolean;
   begin
      for I in 1 .. RTM_Latch_Size loop

         pragma Loop_Invariant (True);
         exit when not EVC_Sessions.Has_Released;
         EVC_Sessions.Take_Released (S, Latched_RTM (1).Data, Last);
         EVC_Received.Receive_Message (Latched_RTM (1).Data (1 .. Last),
                                       M_Status);
         if M_Status = ETCS_Message.Accepted then
            EVC_Radio_Authority.Take_Message (S, Unsigned_64 (Clock_Ms));
            --  3.18.4.5.3: packet 140
            EVC_Mission.Take_RBC_TRN (Current_Mode);
         end if;
      end loop;
      --  4.8.5.5: the transition buffer of the authority half released
      --  (the level became 2 in the last cycle), in the order of reception
      for I in 1 .. EVC_Radio_Authority.Buffer_Size loop
         pragma Loop_Invariant (True);
         exit when not EVC_Radio_Authority.Has_Released;
         Accepting := EVC_Radio_Authority.Released_Accepting;
         Part := EVC_Radio_Authority.Released_Part;
         EVC_Radio_Authority.Take_Released (S, Latched_RTM (1).Data, Last);
         EVC_Received.Receive_Message (Latched_RTM (1).Data (1 .. Last),
                                       M_Status);
         if M_Status = ETCS_Message.Accepted then
            --  4.8.2.1 c) exception 2: the Accepting RBC's
            EVC_Radio_Authority.Take_Message (S, Unsigned_64 (Clock_Ms),
                                              Accepting, Part);
            EVC_Mission.Take_RBC_TRN (Current_Mode);
         end if;
      end loop;
   end Read_Released_Messages;

   procedure Take_VBC_Requests is
      use EVC_Driver_Requests;
      use ETCS_Variables;
      Code : Unsigned_32;
      NID_C : Unsigned_64;
      Marker : Unsigned_64;
   begin
      EVC_VBC.Expire (Unsigned_64 (Clock_Ms));
      if Entered (Set_VBC) then
         Code := VBC_Code (Set_VBC);
         NID_C := Unsigned_64 (Shift_Right (Code, 6) and 16#3FF#);
         Marker := Unsigned_64 (Code and 16#3F#);
         EVC_Outbox.Put_JRU
           (EVC_JRU_Messages.NID_VBC_Set, Unsigned_64 (Clock_Ms),
            (1      => (Value => Marker, Bits => 6),
             2      => (Value => NID_C, Bits => 10),
             3      => (Value => Unsigned_64 (Shift_Right (Code, 16)
                                              and 16#FF#),
                        Bits  => 8),
             others => (Value => 0, Bits => 0)),
            No_Data);
         if Current_Mode = M_SB then
            EVC_VBC.Set
              (NID_C  => NID_C_T (NID_C),
               Marker => NID_VBCMK_T (Marker),
               T      => T_VBC_T (Shift_Right (Code, 16) and 16#FF#));
         end if;
      end if;
      if Entered (Remove_VBC) then
         Code := VBC_Code (Remove_VBC);
         NID_C := Unsigned_64 (Code and 16#3FF#);
         Marker := Unsigned_64 (Shift_Right (Code, 10) and 16#3F#);
         EVC_Outbox.Put_JRU
           (EVC_JRU_Messages.NID_VBC_Removed, Unsigned_64 (Clock_Ms),
            (1      => (Value => NID_C, Bits => 10),
             2      => (Value => Marker, Bits => 6),
             others => (Value => 0, Bits => 0)),
            No_Data);
         if Current_Mode = M_SB then
            EVC_VBC.Remove
              (NID_C  => NID_C_T (NID_C),
               Marker => NID_VBCMK_T (Marker));
         end if;
      end if;
   end Take_VBC_Requests;

   procedure Read_Ports is
   begin
      Odometer_Now := Latched_Odometer;
      Odometer_Fresh := Latched_Odometer_Fresh;
      Latched_Odometer_Fresh := False;
      TIU_Now := Latched_TIU;
      TIU_Value_Now := Latched_TIU_Value;
      TIU_Known_Now := Latched_TIU_Known;
      Brake_Ack_Now := Latched_Brake_Ack;
      Latched_Brake_Ack := False;
      --  3.6.5.2.5 Table 2c [3], [4], [6]: the train integrity of the TIU
      if Latched_Integrity > 0 then
         EVC_Sessions.Take_Integrity_Input
           (Natural (Latched_Integrity) - 1);
      end if;
      Latched_Integrity := 0;
      --  3.18.3.2 b) 1st bullet: the safe consist length of the TIU
      if Latched_SCL_Fresh then
         EVC_Train_Data.Take_Consist
           (Latched_TIU (Safe_Consist_Length), Latched_SCL);
         Put_Consist (Latched_TIU (Safe_Consist_Length), Latched_SCL);
      end if;
      Latched_SCL_Fresh := False;
      --  the driver's requests and the inputs of the train interface of
      --  the cycle; nothing switched the level yet
      EVC_Driver_Requests.Take;
      EVC_Train_Inputs.Set
        (Cab_A            => TIU_Now (Cab_A_Active),
         Cab_B            => TIU_Now (Cab_B_Active),
         Sleeping         => TIU_Now (Sleeping_Requested),
         Passive_Shunting => TIU_Now (Passive_Shunting_Permitted),
         Non_Leading      => TIU_Now (Non_Leading_Permitted));
      EVC_Levels.Begin_Cycle;
      Take_VBC_Requests;
      Read_Telegrams;
      Read_Radio_Events;
      Read_Radio_Messages;
      Read_Released_Messages;
   end Read_Ports;

   function Acceptance_Context return EVC_Acceptance.Context_T is
     ((Mode             => Current_Mode,
       Level_Valid      => EVC_Levels.Valid,
       Level            => EVC_Levels.Level,
       Cab_Active       => EVC_Train_Inputs.Desk_Open,
       Train_Data_Valid => EVC_Train_Data.Valid,
       TRN_Valid        => EVC_Mission.TRN_Status = EVC_Mission.Valid,
       L1_Announced     => EVC_Levels.L1_Announced,
       L2_Announced     => EVC_Levels.Announced
                           and then EVC_Levels.Announced_Level = L2,
       Order_In_Message => False,
       Order_Pending    => EVC_Levels.Order_Pending,
       Unlinked_Group   => False,
       Infill           => False));

   function Ordered_Context return EVC_Acceptance.Context_T is
     ((Mode             => Current_Mode,
       Level_Valid      => EVC_Levels.Valid,
       Level            => EVC_Levels.Level,
       Cab_Active       => EVC_Train_Inputs.Desk_Open,
       Train_Data_Valid => EVC_Train_Data.Valid,
       TRN_Valid        => EVC_Mission.TRN_Status = EVC_Mission.Valid,
       L1_Announced     => True,
       L2_Announced     => False,
       Order_In_Message => True,
       Order_Pending    => True,
       Unlinked_Group   => False,
       Infill           => False));

end EVC_Core.Inputs;
