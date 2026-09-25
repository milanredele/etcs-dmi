--  ETCS DMI
--  System status message catalogue implementation.

pragma Ada_2012;
with DMI_Protocol; use DMI_Protocol;
with DMI_Status;
with DMI_Text_Messages;

package body DMI_System_Status is

   package SDI renames Supplementary_Driving_Info;
   use all type SDI.Mode_T;

   ---------------------------------------------------------------------
   -- Texts, in the case of Tables 68 and 70 (15.1.1.3)
   ---------------------------------------------------------------------

   type Text_T is
     (T_Balise_Read_Error, T_Trackside_Malfunction, T_Communication_Error,
      T_Entering_FS, T_Entering_OS, T_Entering_SM, T_Runaway_Movement,
      T_SM_Refused, T_SM_Request_Failed, T_SH_Refused, T_SH_Request_Failed,
      T_Trackside_Not_Compatible, T_Train_Data_Changed, T_Safe_Consist,
      T_Train_Rejected, T_Unauthorized_Passing, T_No_MA_Level_Transition,
      T_SR_Distance, T_SH_Stop_Order, T_SR_Stop_Order, T_Emergency_Stop,
      T_RV_Distance, T_PT_Distance, T_No_Track_Description,
      T_Route_Loading_Gauge, T_Route_Traction, T_Route_Axle_Load,
      T_FRMCS_Registration, T_GSMR_Registration, T_NL_No_Longer,
      T_Odometer_Impaired, T_ATO_Needs_Data);

   -- Choice: the "–" (en dash) of "Route unsuitable – ..." is not in ISO
   -- 8859-1, the character set of the text messages and of the fonts: it
   -- is written as "-". The missing space of "Route unsuitable –axle
   -- load category" (Table 68, page 315) is taken as a typo.
   function Text_Of (T : Text_T) return Wide_String is
     (case T is
         when T_Balise_Read_Error        => "Balise read error",
         when T_Trackside_Malfunction    => "Trackside malfunction",
         when T_Communication_Error      => "Communication error",
         when T_Entering_FS              => "Entering FS",
         when T_Entering_OS              => "Entering OS",
         when T_Entering_SM              => "Entering SM",
         when T_Runaway_Movement         => "Runaway movement",
         when T_SM_Refused               => "SM refused",
         when T_SM_Request_Failed        => "SM request failed",
         when T_SH_Refused               => "SH refused",
         when T_SH_Request_Failed        => "SH request failed",
         when T_Trackside_Not_Compatible => "Trackside not compatible",
         when T_Train_Data_Changed       => "Train data changed",
         when T_Safe_Consist             =>
            "Safe consist length no longer available",
         when T_Train_Rejected           => "Train is rejected",
         when T_Unauthorized_Passing     =>
            "Unauthorized passing of EOA / LOA",
         when T_No_MA_Level_Transition   =>
            "No MA received at level transition",
         when T_SR_Distance              => "SR distance exceeded",
         when T_SH_Stop_Order            => "SH stop order",
         when T_SR_Stop_Order            => "SR stop order",
         when T_Emergency_Stop           => "Emergency stop",
         when T_RV_Distance              => "RV distance exceeded",
         when T_PT_Distance              => "PT distance exceeded",
         when T_No_Track_Description     => "No track description",
         when T_Route_Loading_Gauge      =>
            "Route unsuitable - loading gauge",
         when T_Route_Traction           =>
            "Route unsuitable - traction system",
         when T_Route_Axle_Load          =>
            "Route unsuitable - axle load category",
         when T_FRMCS_Registration       =>
            "FRMCS network registration failed",
         when T_GSMR_Registration        =>
            "GSM-R network registration failed",
         when T_NL_No_Longer             => "NL no longer permitted",
         when T_Odometer_Impaired        => "Odometer impaired",
         when T_ATO_Needs_Data           => "ATO needs data");

   function ID_Of (T : Text_T) return Natural is
     (System_ID_Base + Text_T'Pos (T));

   ---------------------------------------------------------------------
   -- Modes: the "Table 4.7.2 corresponding row" (15.1.1.2), the columns
   -- marked X or A in SUBSET-026 4.7.2 (pages 57-59). PS has no Mode_T
   -- value; SF and IS are NA in every row, so a change to them ends
   -- every message.
   ---------------------------------------------------------------------

   type Mode_Set_T is array (SDI.Mode_T) of Boolean;

   type Mode_List_T is array (Positive range <>) of SDI.Mode_T;

   function Set (Modes : Mode_List_T) return Mode_Set_T is
      Result : Mode_Set_T := (others => False);
   begin
      for M of Modes loop
         Result (M) := True;
      end loop;
      return Result;
   end Set;

   -- "Brake reason"
   Brake_Modes : constant Mode_Set_T :=
     Set ((M_SB, M_SH, M_SM, M_FS, M_LS, M_SR, M_OS, M_UN, M_TR, M_PT,
           M_SN, M_RV));
   -- "Trip reason"
   Trip_Modes : constant Mode_Set_T := Set ((M_TR, M_PT));
   -- "Trackside malfunction"
   Malfunction_Modes : constant Mode_Set_T :=
     Set ((M_SB, M_SH, M_SM, M_FS, M_AD, M_LS, M_SR, M_OS, M_UN, M_TR,
           M_PT, M_SN, M_RV));
   -- "Shunting / Supervised Manoeuvre (request) refused by / not
   -- answered by RBC", the same four rows
   RBC_Refusal_Modes : constant Mode_Set_T :=
     Set ((M_SB, M_SM, M_FS, M_AD, M_LS, M_SR, M_OS, M_PT));
   -- "Trackside not compatible"
   Not_Compatible_Modes : constant Mode_Set_T :=
     Set ((M_SB, M_SH, M_SM, M_FS, M_AD, M_LS, M_SR, M_OS, M_NL, M_UN,
           M_TR, M_PT, M_SN, M_RV));
   -- "Notification of Train Data change from source different from the
   -- driver"
   Train_Data_Modes : constant Mode_Set_T :=
     Set ((M_SB, M_FS, M_AD, M_LS, M_SR, M_OS, M_UN, M_TR, M_PT, M_SN));
   -- "Train is rejected"
   Rejected_Modes : constant Mode_Set_T := Set ((1 => M_SB));
   -- "Route unsuitability(ies)"
   Route_Modes : constant Mode_Set_T := Set ((M_FS, M_AD, M_LS, M_OS));
   -- "Failed Radio Network registration(s)"
   Radio_Modes : constant Mode_Set_T :=
     Set ((M_SB, M_SM, M_FS, M_AD, M_LS, M_SR, M_OS, M_NL, M_PT));
   -- "Non-leading no longer permitted"
   NL_Modes : constant Mode_Set_T := Set ((1 => M_NL));
   -- "Impairment due to accumulated underestimation / overestimation
   -- ..."
   Odometer_Modes : constant Mode_Set_T :=
     Set ((M_SM, M_FS, M_AD, M_LS, M_SR, M_OS));
   -- "ATO data need"
   ATO_Modes : constant Mode_Set_T :=
     Set ((M_FS, M_AD, M_LS, M_SR, M_OS, M_UN, M_TR, M_PT, M_SN));

   ---------------------------------------------------------------------
   -- The catalogue
   ---------------------------------------------------------------------

   -- "Message displayed for 30 s": not at all, from the start, or from
   -- the event the row names (event 2 of MSG_SYSTEM_STATUS)
   type Timer_T is (No_Timer, From_Start, From_Event);

   -- What the end event of the EVC (event 1) does: nothing (the row
   -- names no end of SUBSET-026), end the message, or end it once it has
   -- been displayed for 30 s ("(if message displayed for 30 s
   -- beforehand)", and the 30 s end "(if ... fulfilled beforehand)")
   type End_Event_T is (Not_Named, Immediate, After_30s);

   type Entry_Def_T is record
      Text        : Text_T;
      Timer       : Timer_T := No_Timer;
      End_Event   : End_Event_T := Immediate;
      -- "As soon as any button in the main window is selected"
      Button_Ends : Boolean := False;
      -- 15.1.1.4.1, "Text acknowledged"
      Acknowledge : Boolean := False;
      Modes       : Mode_Set_T;
   end record;

   -- 15.1.1.6: the EVC reports the revocation of a brake command reason
   -- by a mode change (Table 4.12 of SUBSET-026) as the end event, so
   -- every "Brake reason" entry takes it (Immediate); the two whose row
   -- names the revocation itself wait for the 30 s (After_30s).
   Catalogue : constant array (Entry_T) of Entry_Def_T :=
     (SS_Balise_Read_Error_Brake =>
        (Text => T_Balise_Read_Error, Timer => From_Event,
         Modes => Brake_Modes, others => <>),
      SS_Balise_Read_Error_Trip =>
        (Text => T_Balise_Read_Error, Modes => Trip_Modes, others => <>),
      SS_Trackside_Malfunction =>
        (Text => T_Trackside_Malfunction, Timer => From_Start,
         End_Event => Not_Named, Modes => Malfunction_Modes, others => <>),
      SS_Communication_Error_Brake =>
        (Text => T_Communication_Error, End_Event => After_30s,
         Modes => Brake_Modes, others => <>),
      SS_Communication_Error_Trip =>
        (Text => T_Communication_Error, Modes => Trip_Modes, others => <>),
      SS_Entering_FS =>
        (Text => T_Entering_FS, Modes => Set ((1 => M_FS)), others => <>),
      SS_Entering_OS =>
        (Text => T_Entering_OS, Modes => Set ((1 => M_OS)), others => <>),
      SS_Entering_SM =>
        (Text => T_Entering_SM, Modes => Set ((1 => M_SM)), others => <>),
      SS_Runaway_Movement =>
        (Text => T_Runaway_Movement, Modes => Brake_Modes, others => <>),
      SS_SM_Refused =>
        (Text => T_SM_Refused, End_Event => Not_Named,
         Button_Ends => True, Modes => RBC_Refusal_Modes, others => <>),
      SS_SM_Request_Failed =>
        (Text => T_SM_Request_Failed, End_Event => Not_Named,
         Button_Ends => True, Modes => RBC_Refusal_Modes, others => <>),
      SS_SH_Refused =>
        (Text => T_SH_Refused, End_Event => Not_Named,
         Button_Ends => True, Modes => RBC_Refusal_Modes, others => <>),
      SS_SH_Refused_Trip =>
        (Text => T_SH_Refused, Modes => Trip_Modes, others => <>),
      SS_SH_Request_Failed =>
        (Text => T_SH_Request_Failed, End_Event => Not_Named,
         Button_Ends => True, Modes => RBC_Refusal_Modes, others => <>),
      SS_Trackside_Not_Compatible =>
        (Text => T_Trackside_Not_Compatible, Timer => From_Start,
         End_Event => Not_Named, Modes => Not_Compatible_Modes,
         others => <>),
      SS_Trackside_Not_Compatible_Trip =>
        (Text => T_Trackside_Not_Compatible, Modes => Trip_Modes,
         others => <>),
      SS_Train_Data_Changed =>
        (Text => T_Train_Data_Changed, Timer => From_Event,
         End_Event => Not_Named, Modes => Train_Data_Modes, others => <>),
      SS_Train_Data_Changed_Brake =>
        (Text => T_Train_Data_Changed, Modes => Brake_Modes, others => <>),
      SS_Safe_Consist_Length =>
        (Text => T_Safe_Consist, End_Event => After_30s,
         Modes => Brake_Modes, others => <>),
      SS_Train_Rejected =>
        (Text => T_Train_Rejected, End_Event => Not_Named,
         Button_Ends => True, Modes => Rejected_Modes, others => <>),
      SS_Unauthorized_Passing =>
        (Text => T_Unauthorized_Passing, Modes => Trip_Modes, others => <>),
      SS_No_MA_Level_Transition =>
        (Text => T_No_MA_Level_Transition, Modes => Trip_Modes,
         others => <>),
      SS_SR_Distance_Exceeded =>
        (Text => T_SR_Distance, Modes => Trip_Modes, others => <>),
      SS_SH_Stop_Order =>
        (Text => T_SH_Stop_Order, Modes => Trip_Modes, others => <>),
      SS_SR_Stop_Order =>
        (Text => T_SR_Stop_Order, Modes => Trip_Modes, others => <>),
      SS_Emergency_Stop =>
        (Text => T_Emergency_Stop, Modes => Trip_Modes, others => <>),
      SS_RV_Distance_Exceeded =>
        (Text => T_RV_Distance, Modes => Brake_Modes, others => <>),
      SS_PT_Distance_Exceeded =>
        (Text => T_PT_Distance, Modes => Brake_Modes, others => <>),
      SS_No_Track_Description =>
        (Text => T_No_Track_Description, Modes => Trip_Modes,
         others => <>),
      SS_Route_Unsuitable_Gauge =>
        (Text => T_Route_Loading_Gauge, Modes => Route_Modes, others => <>),
      SS_Route_Unsuitable_Traction =>
        (Text => T_Route_Traction, Modes => Route_Modes, others => <>),
      SS_Route_Unsuitable_Axle_Load =>
        (Text => T_Route_Axle_Load, Modes => Route_Modes, others => <>),
      SS_FRMCS_Registration_Failed =>
        (Text => T_FRMCS_Registration, Button_Ends => True,
         Modes => Radio_Modes, others => <>),
      SS_GSMR_Registration_Failed =>
        (Text => T_GSMR_Registration, Button_Ends => True,
         Modes => Radio_Modes, others => <>),
      SS_NL_No_Longer_Permitted =>
        (Text => T_NL_No_Longer, End_Event => Not_Named,
         Acknowledge => True, Modes => NL_Modes, others => <>),
      SS_Odometer_Impaired =>
        (Text => T_Odometer_Impaired, Modes => Odometer_Modes,
         others => <>),
      SS_ATO_Needs_Data =>
        (Text => T_ATO_Needs_Data, Modes => ATO_Modes, others => <>),
      SS_ATO_Runaway_Movement =>
        (Text => T_Runaway_Movement, Modes => Brake_Modes, others => <>));

   ---------------------------------------------------------------------
   -- State
   ---------------------------------------------------------------------

   type State_T is record
      Active      : Boolean := False;
      -- time displayed since the start, held at Display_Time_Ms
      Since_Start : Natural := 0;
      -- From_Event: the event came, and the time since
      Counting    : Boolean := False;
      Since_Event : Natural := 0;
      -- After_30s: the end event came before the 30 s were over
      End_Pending : Boolean := False;
   end record;

   State : array (Entry_T) of State_T;

   function Text_Active (T : Text_T) return Boolean is
   begin
      for E in Entry_T loop
         if State (E).Active and then Catalogue (E).Text = T then
            return True;
         end if;
      end loop;
      return False;
   end Text_Active;

   -- 15.1.1.7: an entry that ends takes the message with it only when no
   -- other entry of the same text is still displayed
   procedure Finish (E : Entry_T) is
   begin
      State (E) := (others => <>);
      if not Text_Active (Catalogue (E).Text) then
         DMI_Text_Messages.Remove (ID_Of (Catalogue (E).Text));
      end if;
   end Finish;

   procedure Start (E : Entry_T) is
      Def : Entry_Def_T renames Catalogue (E);
   begin
      -- 15.1.1.7: one instance of a message until all the end conditions
      -- are fulfilled. Choice: a start of an entry that is displayed (a
      -- second instance, possibly of another row of it) begins its end
      -- conditions anew, so the message lasts until the later one is
      -- over; the message keeps its place and time stamp and plays no
      -- Sinfo again. The same holds between two entries of one text.
      State (E) := (Active => True, others => <>);
      if not DMI_Text_Messages.Holds (ID_Of (Def.Text)) then
         -- 8.2.3.4.7 a, c: first group, bold; 8.2.3.4.6 b: the local
         -- time of appearance. Sinfo (8.2.3.4.7 h) or the request for
         -- acknowledgement (5.4.1) come with Put.
         DMI_Text_Messages.Put
           (ID           => ID_Of (Def.Text),
            First_Group  => True,
            Ack_Required => Def.Acknowledge,
            Class        => DMI_Text_Messages.System_Status,
            Hour         => DMI_Status.Time_H,
            Minute       => DMI_Status.Time_M,
            Text         => Text_Of (Def.Text));
      end if;
   end Start;

   -- The ends that depend on time
   procedure Check_Timers (E : Entry_T) is
      S   : State_T renames State (E);
      Def : Entry_Def_T renames Catalogue (E);
   begin
      if not S.Active then
         return;
      end if;
      if (Def.Timer = From_Start and then S.Since_Start >= Display_Time_Ms)
        or else (Def.Timer = From_Event and then S.Counting
                 and then S.Since_Event >= Display_Time_Ms)
        or else (Def.End_Event = After_30s and then S.End_Pending
                 and then S.Since_Start >= Display_Time_Ms)
      then
         Finish (E);
      end if;
   end Check_Timers;

   procedure Event (Entry_Raw, Event_Raw : Natural) is
   begin
      if Entry_Raw not in Natural (Entry_T'First) .. Natural (Entry_T'Last)
        or else Event_Raw > 2
      then
         return; -- not in the catalogue, or no such event: ignored
      end if;
      declare
         E   : constant Entry_T := Entry_T (Entry_Raw);
         S   : State_T renames State (E);
         Def : Entry_Def_T renames Catalogue (E);
      begin
         case Event_Raw is
            when 0 =>
               Start (E);
            when 1 =>
               if S.Active then
                  case Def.End_Event is
                     when Not_Named =>
                        null; -- the DMI owns the end of this entry
                     when Immediate =>
                        Finish (E);
                     when After_30s =>
                        S.End_Pending := True;
                        Check_Timers (E);
                  end case;
               end if;
            when others =>
               -- "once 3.14.1.6 is fulfilled", "from the time a train
               -- movement is detected". Choice: the first event counts;
               -- a repetition does not restart the 30 s.
               if S.Active and then Def.Timer = From_Event
                 and then not S.Counting
               then
                  S.Counting := True;
                  S.Since_Event := 0;
               end if;
         end case;
      end;
   end Event;

   procedure Tick (Dt_Ms : Natural) is
      function Add (A : Natural) return Natural is
        (Natural'Min (A, Display_Time_Ms)
         + Natural'Min (Dt_Ms, Display_Time_Ms));
   begin
      -- Choice: the 30 s run whatever else E5-E9 shows meanwhile (a
      -- message to be acknowledged hides the others, 8.2.3.4.8 a)
      for E in Entry_T loop
         if State (E).Active then
            State (E).Since_Start :=
              Natural'Min (Add (State (E).Since_Start), Display_Time_Ms);
            if State (E).Counting then
               State (E).Since_Event :=
                 Natural'Min (Add (State (E).Since_Event), Display_Time_Ms);
            end if;
            Check_Timers (E);
         end if;
      end loop;
   end Tick;

   procedure Mode_Changed (Mode : SDI.Mode_T) is
   begin
      -- 15.1.1.2: a change to a mode in which Table 4.7.2 does not
      -- display the information ends the message. Choice: a start while
      -- the mode is outside the set is displayed all the same (15.1.1.2
      -- assumes it cannot happen; the EVC owns the start condition), and
      -- only a later change of mode ends it.
      for E in Entry_T loop
         if State (E).Active and then not Catalogue (E).Modes (Mode) then
            Finish (E);
         end if;
      end loop;
   end Mode_Changed;

   procedure Main_Window_Button (Ended : out Boolean) is
   begin
      Ended := False;
      for E in Entry_T loop
         if State (E).Active and then Catalogue (E).Button_Ends then
            Finish (E);
            Ended := True;
         end if;
      end loop;
   end Main_Window_Button;

   function Owns (ID : Natural) return Boolean is
     (ID >= System_ID_Base
      and then ID - System_ID_Base <= Text_T'Pos (Text_T'Last));

   procedure Acknowledged (ID : Natural; Number : out Natural) is
   begin
      Number := 0;
      if not Owns (ID) then
         return;
      end if;
      for E in Entry_T loop
         if State (E).Active and then Catalogue (E).Acknowledge
           and then ID_Of (Catalogue (E).Text) = ID
         then
            Number := Natural (E);
            -- Table 68: "Text acknowledged" is the end condition, so
            -- the message is not kept as an ordinary one (8.2.3.4.8 c,
            -- "if the acknowledgement does not lead to the end of
            -- display")
            Finish (E);
         end if;
      end loop;
   end Acknowledged;

   function Active (Number : Entry_T) return Boolean is
     (State (Number).Active);

   procedure Reset is
   begin
      State := (others => (others => <>));
   end Reset;

end DMI_System_Status;
