--  ETCS on-board (EVC)
--  Text messages from the trackside, implementation.

with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Packet_Index;
with ETCS_Track_Packets.P73;
with ETCS_Track_Packets.P74;
with ETCS_Variables;   use ETCS_Variables;

package body EVC_Text_Messages
  with SPARK_Mode => On,
       Refined_State => (State => (Messages, Next_Id, Outputs, Output_N,
                                   Events, Event_N, Last_Level_Valid,
                                   Last_Level))
is

   No_Mode  : constant := 15;   -- M_MODETEXTDISPLAY: no sub-condition
   No_Level : constant := 4;    -- M_LEVELTEXTDISPLAY: no sub-condition

   type Message_T is record
      Used       : Boolean := False;
      Id         : Unsigned_16 := 0;
      Plain      : Boolean := False;
      Important  : Boolean := False;
      --  Q_TEXTDISPLAY 1: all the sub-conditions
      All_Of     : Boolean := False;
      --  the start sub-conditions
      Has_Start_X : Boolean := False;
      Start_X    : Dist_T := 0;
      Sense      : Sense_T := Plus;
      Start_Mode : Natural range 0 .. 15 := No_Mode;
      Start_Level : Natural range 0 .. 7 := No_Level;
      --  the end sub-conditions
      Has_End_X  : Boolean := False;
      End_X      : Dist_T := 0;
      Has_Time   : Boolean := False;
      Time_Ms    : Natural := 0;
      End_Mode   : Natural range 0 .. 15 := No_Mode;
      End_Level  : Natural range 0 .. 7 := No_Level;
      --  Q_TEXTCONFIRM, Q_CONFTEXTDISPLAY 0 (the acknowledgement ends
      --  the display), Q_TEXTREPORT and NID_TEXTMESSAGE
      Confirm    : Natural range 0 .. 3 := 0;
      Ack_Ends   : Boolean := True;
      Report     : Boolean := False;
      Report_Id  : Natural := 0;
      Length     : Natural range 0 .. Max_Text := 0;
      Text       : Text_T := (others => 0);
      --  what happened
      Started    : Boolean := False;
      Start_Ms   : Unsigned_64 := 0;
      Shown      : Boolean := False;
      Loc_Done   : Boolean := False;
      Time_Done  : Boolean := False;
      Mode_Done  : Boolean := False;
      Level_Done : Boolean := False;
      Ended      : Boolean := False;
      Acked      : Boolean := False;
      Brake_SB   : Boolean := False;
      Brake_EB   : Boolean := False;
   end record;

   type Message_Array is array (1 .. Max_Messages) of Message_T;
   type Output_Array is array (1 .. Max_Outputs) of Output_T;
   type Event_Array is array (1 .. Max_Events) of Event_T;

   Messages : Message_Array;
   Next_Id  : Unsigned_16 := 1;
   Outputs  : Output_Array;
   Output_N : Natural range 0 .. Max_Outputs := 0;
   Events   : Event_Array;
   Event_N  : Natural range 0 .. Max_Events := 0;
   --  the level of the last cycle (the end sub-condition "level")
   Last_Level_Valid : Boolean := False;
   Last_Level       : Level_T := L0;

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Output_Count return Natural is (Output_N)
     with Refined_Global => Output_N;
   function Output (I : Positive) return Output_T is (Outputs (I))
     with Refined_Global => (Input => Outputs, Proof_In => Output_N);

   function Service_Brake return Boolean is
     (for some I in Messages'Range =>
        Messages (I).Used and then Messages (I).Brake_SB)
     with Refined_Global => Messages;

   function Emergency_Brake return Boolean is
     (for some I in Messages'Range =>
        Messages (I).Used and then Messages (I).Brake_EB)
     with Refined_Global => Messages;

   function Displayed return Natural
     with Refined_Global => Messages
   is
      N : Natural range 0 .. Max_Messages := 0;
   begin
      for I in Messages'Range loop
         pragma Loop_Invariant (N < I);
         if Messages (I).Used and then Messages (I).Shown then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Displayed;

   function Event_Count return Natural is (Event_N)
     with Refined_Global => Event_N;
   function Event (I : Positive) return Event_T is (Events (I))
     with Refined_Global => (Input => Events, Proof_In => Event_N);

   ---------------------------------------------------------------------
   --  Helpers
   ---------------------------------------------------------------------

   procedure Record_Event (Kind : Natural; M : Message_T)
     with Global => (In_Out => (Events, Event_N))
   is
   begin
      if Event_N < Max_Events then
         Event_N := Event_N + 1;
         Events (Event_N) :=
           (Kind => Unsigned_8 (Kind mod 256),
            B3   => Unsigned_8 (M.Id mod 256),
            B4   => (if M.Plain then 1 else 0));
      end if;
   end Record_Event;

   procedure Put_Output (O : Output_T)
     with Global => (In_Out => (Outputs, Output_N))
   is
   begin
      if Output_N < Max_Outputs then
         Output_N := Output_N + 1;
         Outputs (Output_N) := O;
      end if;
   end Put_Output;

   --  M_MODETEXTDISPLAY (7.5.1.73) names Mode
   function Names (Code : Natural; Mode : Mode_T) return Boolean is
     (case Code is
         when 0  => Mode = M_FS,
         when 1  => Mode = M_OS,
         when 2  => Mode = M_SR,
         when 3  => Mode = M_AD,
         when 4  => Mode = M_UN,
         when 5  => Mode = M_SM,
         when 6  => Mode = M_SB,
         when 7  => Mode = M_TR,
         when 8  => Mode = M_PT,
         when 12 => Mode = M_LS,
         when 14 => Mode = M_RV,
         when others => False);

   --  M_LEVELTEXTDISPLAY (7.5.1.66) names the level
   function Names_Level (Code : Natural; Valid : Boolean; Level : Level_T)
     return Boolean
   is (Valid
       and then (case Code is
                    when 0      => Level = L0,
                    when 1      => Level = NTC,
                    when 2      => Level = L1,
                    when 3      => Level = L2,
                    when others => False));

   --  Remove message I: from the DMI when it was shown
   procedure Remove (I : Positive)
     with Global => (In_Out => (Messages, Outputs, Output_N, Events,
                                Event_N)),
          Pre => I <= Max_Messages
   is
   begin
      if Messages (I).Used and then Messages (I).Shown then
         Put_Output ((Kind => Remove, Id => Messages (I).Id, others => <>));
         Record_Event (Event_Removed, Messages (I));
      end if;
      Messages (I) := (others => <>);
   end Remove;

   ---------------------------------------------------------------------
   --  Reception
   ---------------------------------------------------------------------

   --  A message decoded, its common part: Q_SCALE, the location
   --  reference of the group (frame position of its origin T at offset
   --  0) and the sense of its distances
   procedure Store (New_M : Message_T)
     with Global => (In_Out => (Messages, Next_Id, Outputs, Output_N,
                                Events, Event_N))
   is
      Slot : Natural := 0;
      M    : Message_T := New_M;
   begin
      --  3.12.3.5.3: a message with a request to report the
      --  acknowledgement and the identifier of one not acknowledged yet
      if M.Report then
         for I in Messages'Range loop
            if Messages (I).Used and then Messages (I).Report
              and then Messages (I).Report_Id = M.Report_Id
              and then not Messages (I).Acked
            then
               Record_Event (Event_Rejected, M);
               return;
            end if;
         end loop;
      end if;
      for I in Messages'Range loop
         if not Messages (I).Used then
            Slot := I;
            exit;
         end if;
      end loop;
      if Slot = 0 then
         --  no room: the oldest one not displayed gives way, else the
         --  first one
         Slot := 1;
         for I in Messages'Range loop
            if not Messages (I).Shown then
               Slot := I;
               exit;
            end if;
         end loop;
         Remove (Slot);
      end if;
      M.Used := True;
      M.Id := Next_Id;
      Next_Id := (if Next_Id >= 16#7FFF# then 1 else Next_Id + 1);
      Messages (Slot) := M;
   end Store;

   --  The conditions common to packets 73 and 74
   procedure Conditions
     (M        : in out Message_T;
      X0       : Dist_T;
      S        : Sense_T;
      Scale    : Natural;
      Class    : Q_TEXTCLASS_T;
      Display  : Q_TEXTDISPLAY_T;
      D        : D_TEXTDISPLAY_T;
      Mode_1   : M_MODETEXTDISPLAY_T;
      Level_1  : M_LEVELTEXTDISPLAY_T;
      L        : L_TEXTDISPLAY_T;
      T        : T_TEXTDISPLAY_T;
      Mode_2   : M_MODETEXTDISPLAY_T;
      Level_2  : M_LEVELTEXTDISPLAY_T;
      Confirm  : Q_TEXTCONFIRM_T;
      Conf     : Q_CONFTEXTDISPLAY_T;
      Report   : Q_TEXTREPORT_T;
      Id       : NID_TEXTMESSAGE_T)
     with Pre => Scale <= 2
   is
      Start : constant Length_T :=
        (if D = D_TEXTDISPLAY_No_Location_Sub_Condition then 0
         else Scaled (Natural (D), Scale));
   begin
      M.Important := Class = 1;
      M.All_Of := Display = 1;
      M.Sense := S;
      M.Has_Start_X := D /= D_TEXTDISPLAY_No_Location_Sub_Condition;
      M.Start_X := Advance (X0, S, Start);
      M.Start_Mode := Natural (Mode_1);
      M.Start_Level := Natural (Level_1);
      M.Has_End_X := L /= L_TEXTDISPLAY_No_Location_Sub_Condition;
      if M.Has_End_X then
         --  3.12.3.4.6: from the start location
         M.End_X := Advance (M.Start_X, S, Scaled (Natural (L), Scale));
      end if;
      M.Has_Time := T /= T_TEXTDISPLAY_No_Time_Sub_Condition;
      M.Time_Ms := (if M.Has_Time then Natural (T) * 1_000 else 0);
      M.End_Mode := Natural (Mode_2);
      M.End_Level := Natural (Level_2);
      M.Confirm := Natural (Confirm);
      M.Ack_Ends := Confirm = 0 or else Conf = 0;
      M.Report := Confirm /= 0 and then Report = 1;
      M.Report_Id := Natural (Id);
   end Conditions;

   subtype Reader_T is ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);

   --  The fixed texts of Q_TEXT (7.5.1.136), English
   LX_Text  : constant String := "Level crossing not protected";
   Ack_Text : constant String := "Acknowledgement";

   procedure Put_Text (M : in out Message_T; S : String)
     with Pre => S'Length <= Max_Text
   is
      N : Natural range 0 .. Max_Text := 0;
   begin
      for I in S'Range loop
         pragma Loop_Invariant (N = I - S'First);
         N := N + 1;
         M.Text (N) := Character'Pos (S (I));
      end loop;
      M.Length := N;
   end Put_Text;

   --  The location reference of a group taken is the frame position of
   --  its anchor (EVC_Location.Anchor_T.X): the origin of the group in
   --  EVC_Origins is released in the cycle when no store of the stored
   --  information refers to it, and the text messages keep frame
   --  positions of their own
   procedure Take_Groups
     with Global => (Input  => EVC_Position.State,
                     In_Out => (Messages, Next_Id, Outputs, Output_N,
                                Events, Event_N))
   is
      use type ETCS_Catalogue.Packet_Kind_T;
   begin
      for G in 1 .. EVC_Position.Taken_Count loop
         declare
            Tk : constant EVC_Position.Taken_T := EVC_Position.Taken (G);
            X0 : constant Dist_T := Tk.Group.X;
         begin
            for J in Tk.First .. Tk.First + Tk.Count - 1 loop
               for P in 1 .. EVC_Position.Taken_Packet_Count (J) loop
                  declare
                     E  : constant ETCS_Packet_Index.Entry_T :=
                       EVC_Position.Taken_Entry (J, P);
                     pragma Warnings
                       (GNATprove, Off,
                        """R"" is set by ""Decode"" but not used after*",
                        Reason => "the reader of one packet");
                     R  : Reader_T;
                     OK : Boolean;
                     M  : Message_T;
                  begin
                     if E.Kind in ETCS_Catalogue.Track_P73
                                        | ETCS_Catalogue.Track_P74
                       and then EVC_Position.Valid_For
                                  (E.Q_DIR, Tk.Group.Orientation, Tk.T)
                     then
                        EVC_Position.Open_Taken_Packet (J, P, R);
                        if E.Kind = ETCS_Catalogue.Track_P73 then
                           declare
                              X : ETCS_Track_Packets.P73.Packet_T;
                           begin
                              ETCS_Track_Packets.P73.Decode (R, X, OK);
                              if OK and then X.Q_SCALE <= 2 then
                                 Conditions
                                   (M, X0, Tk.S, Natural (X.Q_SCALE),
                                    X.Q_TEXTCLASS, X.Q_TEXTDISPLAY,
                                    X.D_TEXTDISPLAY, X.M_MODETEXTDISPLAY,
                                    X.M_LEVELTEXTDISPLAY, X.L_TEXTDISPLAY,
                                    X.T_TEXTDISPLAY, X.M_MODETEXTDISPLAY_2,
                                    X.M_LEVELTEXTDISPLAY_2, X.Q_TEXTCONFIRM,
                                    X.Q_CONFTEXTDISPLAY, X.Q_TEXTREPORT,
                                    X.NID_TEXTMESSAGE);
                                 M.Plain := True;
                                 M.Length := Natural (X.L_TEXT);
                                 for K in 1 .. Natural (X.L_TEXT) loop
                                    M.Text (K) := Byte (X.X_TEXT_List (K));
                                 end loop;
                                 Store (M);
                              end if;
                           end;
                        else
                           declare
                              X : ETCS_Track_Packets.P74.Packet_T;
                           begin
                              ETCS_Track_Packets.P74.Decode (R, X, OK);
                              if OK and then X.Q_SCALE <= 2
                                and then X.Q_TEXT <= 1
                              then
                                 Conditions
                                   (M, X0, Tk.S, Natural (X.Q_SCALE),
                                    X.Q_TEXTCLASS, X.Q_TEXTDISPLAY,
                                    X.D_TEXTDISPLAY, X.M_MODETEXTDISPLAY,
                                    X.M_LEVELTEXTDISPLAY, X.L_TEXTDISPLAY,
                                    X.T_TEXTDISPLAY, X.M_MODETEXTDISPLAY_2,
                                    X.M_LEVELTEXTDISPLAY_2, X.Q_TEXTCONFIRM,
                                    X.Q_CONFTEXTDISPLAY, X.Q_TEXTREPORT,
                                    X.NID_TEXTMESSAGE);
                                 M.Plain := False;
                                 Put_Text (M, (if X.Q_TEXT = 0 then LX_Text
                                               else Ack_Text));
                                 Store (M);
                              end if;
                           end;
                        end if;
                     end if;
                  end;
               end loop;
            end loop;
         end;
      end loop;
   end Take_Groups;

   ---------------------------------------------------------------------
   --  Clear, Evaluate, Mode_Changed
   ---------------------------------------------------------------------

   procedure Clear is
   begin
      Messages := (others => (others => <>));
      Next_Id := 1;
      Outputs := (others => (others => <>));
      Output_N := 0;
      Events := (others => (others => <>));
      Event_N := 0;
      Last_Level_Valid := False;
      Last_Level := L0;
   end Clear;

   function Flags_Of (M : Message_T) return Byte is
     ((if M.Confirm /= 0 then 1 else 0)
      or (if M.Important then 2 else 0)
      or (if M.Plain then 4 else 0));

   procedure Evaluate (Mode        : Mode_T;
                       Level_Valid : Boolean;
                       Level       : Level_T;
                       Est_Front   : Dist_T;
                       Now_Ms      : Unsigned_64)
   is
      Level_Left : constant Boolean :=
        Last_Level_Valid
        and then (not Level_Valid or else Level /= Last_Level);
   begin
      Output_N := 0;
      Event_N := 0;
      Take_Groups;

      for I in Messages'Range loop
         declare
            M : Message_T := Messages (I);
         begin
            if M.Used then
               --  the driver's acknowledgement (3.12.3.4.3.2, 3.14.1.7.5)
               if M.Shown and then M.Confirm /= 0 and then not M.Acked
                 and then EVC_Procedure_Requests.Text_Acknowledged (M.Id)
               then
                  M.Acked := True;
                  M.Brake_SB := False;
                  M.Brake_EB := False;
                  Record_Event (Event_Acknowledged, M);
               end if;

               --  the start condition (3.12.3.4.2, 3.12.3.4.3.1.1, .3)
               if not M.Started then
                  declare
                     Loc   : constant Boolean :=
                       M.Has_Start_X
                       and then Along (M.Sense, Est_Front)
                                >= Along (M.Sense, M.Start_X);
                     Md    : constant Boolean :=
                       M.Start_Mode /= No_Mode
                       and then Names (M.Start_Mode, Mode);
                     Lv    : constant Boolean :=
                       M.Start_Level /= No_Level
                       and then Names_Level (M.Start_Level, Level_Valid,
                                             Level);
                     Any_Used : constant Boolean :=
                       M.Has_Start_X or else M.Start_Mode /= No_Mode
                       or else M.Start_Level /= No_Level;
                  begin
                     if not Any_Used then
                        M.Started := True;
                     elsif M.All_Of then
                        M.Started :=
                          (Loc or else not M.Has_Start_X)
                          and then (Md or else M.Start_Mode = No_Mode)
                          and then (Lv or else M.Start_Level = No_Level);
                     else
                        M.Started := Loc or else Md or else Lv;
                     end if;
                     if M.Started then
                        M.Start_Ms := Now_Ms;
                     end if;
                  end;
               end if;

               --  the end condition (3.12.3.4.3, 3.12.3.4.3.1.2, .4),
               --  evaluated as soon as the start one is fulfilled
               if M.Started and then not M.Ended then
                  if M.Has_End_X
                    and then Along (M.Sense, Est_Front)
                             >= Along (M.Sense, M.End_X)
                  then
                     M.Loc_Done := True;
                  end if;
                  if M.Has_Time and then Now_Ms >= M.Start_Ms
                    and then Now_Ms - M.Start_Ms
                               >= Unsigned_64 (M.Time_Ms)
                  then
                     M.Time_Done := True;
                  end if;
                  if M.End_Level /= No_Level and then Level_Left
                    and then Names_Level (M.End_Level, Last_Level_Valid,
                                          Last_Level)
                  then
                     M.Level_Done := True;
                  end if;
                  declare
                     Used : constant Boolean :=
                       M.Has_End_X or else M.Has_Time
                       or else M.End_Mode /= No_Mode
                       or else M.End_Level /= No_Level;
                  begin
                     if Used then
                        if M.All_Of then
                           M.Ended :=
                             (M.Loc_Done or else not M.Has_End_X)
                             and then (M.Time_Done or else not M.Has_Time)
                             and then (M.Mode_Done
                                       or else M.End_Mode = No_Mode)
                             and then (M.Level_Done
                                       or else M.End_Level = No_Level);
                        else
                           M.Ended := M.Loc_Done or else M.Time_Done
                                      or else M.Mode_Done
                                      or else M.Level_Done;
                        end if;
                     end if;
                  end;
                  --  3.12.3.4.4: no display when ended at once
                  if M.Ended and then not M.Shown then
                     M := (others => <>);
                  elsif not M.Shown then
                     M.Shown := True;
                     declare
                        O : Output_T :=
                          (Kind   => Show,
                           Id     => M.Id,
                           Flags  => Flags_Of (M),
                           Length => M.Length,
                           Text   => M.Text);
                     begin
                        O.Length := M.Length;
                        Put_Output (O);
                     end;
                     Record_Event (Event_Displayed, M);
                  end if;
                  --  3.12.3.4.7: the brake when the end comes before the
                  --  acknowledgement
                  if M.Used and then M.Ended and then M.Confirm >= 2
                    and then not M.Acked
                    and then not (M.Brake_SB or else M.Brake_EB)
                  then
                     M.Brake_SB := M.Confirm = 2;
                     M.Brake_EB := M.Confirm = 3;
                     Record_Event (Event_Brake, M);
                  end if;
               end if;
               Messages (I) := M;

               --  the end of the display: the end condition, and the
               --  acknowledgement asked (3.12.3.4.7.1), or the
               --  acknowledgement alone (3.12.3.4.3.2 a)
               if Messages (I).Used and then Messages (I).Shown
                 and then ((Messages (I).Ended
                            and then (Messages (I).Confirm = 0
                                      or else Messages (I).Acked))
                           or else (Messages (I).Acked
                                    and then Messages (I).Ack_Ends))
               then
                  Remove (I);
               end if;
            end if;
         end;
      end loop;
      Last_Level_Valid := Level_Valid;
      Last_Level := Level;
   end Evaluate;

   procedure Mode_Changed (From, To : Mode_T) is
   begin
      for I in Messages'Range loop
         if Messages (I).Used then
            --  4.10: deleted (and 4.12: their brake revoked)
            if To in M_NP | M_SB | M_PS | M_SH | M_SL | M_NL | M_SN then
               Remove (I);
            else
               --  the end sub-condition "mode": a transition from it
               if Messages (I).Started
                 and then Messages (I).End_Mode /= No_Mode
                 and then Names (Messages (I).End_Mode, From)
               then
                  Messages (I).Mode_Done := True;
               end if;
            end if;
         end if;
      end loop;
   end Mode_Changed;

end EVC_Text_Messages;
