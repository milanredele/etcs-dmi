--  ETCS on-board (EVC)
--  The stored information of the on-board, implementation.

with ETCS_Bits;
with ETCS_Catalogue;
with ETCS_Packet_Index;
with ETCS_Track_Packets.P3;
with ETCS_Track_Packets.P12;
with ETCS_Track_Packets.P21;
with ETCS_Track_Packets.P27;
with ETCS_Track_Packets.P39;
with ETCS_Track_Packets.P51;
with ETCS_Track_Packets.P65;
with ETCS_Track_Packets.P66;
with ETCS_Track_Packets.P67;
with ETCS_Track_Packets.P68;
with ETCS_Track_Packets.P70;
with ETCS_Track_Packets.P71;
with ETCS_Track_Packets.P80;
with ETCS_Track_Packets.P88;
with ETCS_Track_Packets.P141;
with ETCS_Variables;         use ETCS_Variables;
with EVC_Location;           use EVC_Location;
with EVC_Ports;

package body EVC_Stored_Information
  with SPARK_Mode => On,
       Refined_State => (State => (Snap, Sources, Steps, Ceiling,
                                   Failures, Msg_Count, Last_Orient,
                                   Orient_Seen, Events, Event_N,
                                   Indicated, Indicated_N, Sent, Sent_N,
                                   Cond_Due, Plan, Plan_Due,
                                   Driver_Slippery))
is

   use type ETCS_Catalogue.Packet_Kind_T;
   use type EVC_Position.Status_T;
   use type EVC_Ports.Movement_T;
   use type EVC_DMI_Port.Track_Cond_Entry_T;

   type Event_Array is array (1 .. Max_Events) of Event_T;

   Snap            : Snapshot_T;
   Sources         : Elements_T;
   Steps           : Steps_T :=
     (Count => 1, List => (others => (Start => Axis_Start, Value => 0)));
   Ceiling         : Value_T := 0;
   Failures        : Natural := 0;
   Msg_Count       : Natural := 0;
   Last_Orient     : Sense_T := Plus;
   Orient_Seen     : Boolean := False;
   Events          : Event_Array;
   Event_N         : Natural range 0 .. Max_Events := 0;
   Indicated       : EVC_DMI_Port.Track_Cond_List_T;
   Indicated_N     : Natural range 0 .. EVC_DMI_Port.Max_Track_Cond := 0;
   Sent            : EVC_DMI_Port.Track_Cond_List_T;
   Sent_N          : Natural range 0 .. EVC_DMI_Port.Max_Track_Cond := 0;
   Cond_Due        : Boolean := False;
   Plan            : EVC_DMI_Port.Planning_T;
   Plan_Due        : Boolean := False;
   Driver_Slippery : Boolean := False;

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Event_Count return Natural is (Event_N)
     with Refined_Global => Event_N;
   function Event (I : Positive) return Event_T is (Events (I))
     with Refined_Global => (Input => Events, Proof_In => Event_N);
   function Current return Snapshot_T is (Snap)
     with Refined_Global => Snap;
   function MRSP_Sources return Elements_T is (Sources)
     with Refined_Global => Sources;
   function MRSP_Steps return Steps_T is (Steps)
     with Refined_Global => Steps;
   function MRSP_Ceiling return Value_T is (Ceiling)
     with Refined_Global => Ceiling;
   function Envelope_Failures return Natural is (Failures)
     with Refined_Global => Failures;
   function Messages return Natural is (Msg_Count)
     with Refined_Global => Msg_Count;
   function Track_Cond_Due return Boolean is (Cond_Due)
     with Refined_Global => Cond_Due;
   function Track_Cond_Count return Natural is (Indicated_N)
     with Refined_Global => Indicated_N;
   function Track_Cond_List return EVC_DMI_Port.Track_Cond_List_T is
     (Indicated)
     with Refined_Global => Indicated;
   function Planning_Due return Boolean is (Plan_Due)
     with Refined_Global => Plan_Due;
   function Planning return EVC_DMI_Port.Planning_T is (Plan)
     with Refined_Global => Plan;

   procedure Record_Event (Info, Change, Detail : Natural)
     with Global => (In_Out => (Events, Event_N))
   is
   begin
      if Event_N < Max_Events then
         Event_N := Event_N + 1;
         Events (Event_N) := (Info   => Unsigned_8 (Info mod 256),
                              Change => Unsigned_8 (Change mod 256),
                              Detail => Unsigned_8 (Detail mod 256));
      end if;
   end Record_Event;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      EVC_Origins.Clear;
      EVC_Track_Description.Clear;
      EVC_Movement_Authority.Clear;
      EVC_Track_Conditions.Clear;
      EVC_National_Values.Clear;
      EVC_Train_Data.Clear;
      Snap := (others => <>);
      Sources := (Count => 0, List => (others => (others => <>)),
                  Lost => 0);
      Steps := (Count => 1,
                List => (others => (Start => Axis_Start, Value => 0)));
      Ceiling := 0;
      Failures := 0;
      Msg_Count := 0;
      Last_Orient := Plus;
      Orient_Seen := False;
      Events := (others => (others => <>));
      Event_N := 0;
      Indicated := (others => (others => <>));
      Indicated_N := 0;
      Sent := (others => (others => <>));
      Sent_N := 0;
      Cond_Due := False;
      Plan := (others => <>);
      Plan_Due := False;
      Driver_Slippery := False;
   end Clear;

   procedure Set_Driver_Slippery (Slippery : Boolean) is
   begin
      Driver_Slippery := Slippery;
   end Set_Driver_Slippery;

   ---------------------------------------------------------------------
   --  The train in the frame
   ---------------------------------------------------------------------

   function Train_Frame return Train_Frame_T
     with Global => (EVC_Position.State, EVC_Odometry.State,
                     EVC_Train_Data.State)
   is
      Solr   : constant EVC_Location.Anchor_T := EVC_Position.SOLR;
      S      : constant Sense_T := EVC_Position.Orientation;
      Front  : constant Dist_T := EVC_Position.Front_X;
      Length : constant Length_T := EVC_Train_Data.Data.Length;
      R      : Train_Frame_T;
   begin
      R.Valid := EVC_Position.Status = EVC_Position.Valid and then Solr.Valid;
      R.Sense := S;
      R.Est_Front := Front;
      if R.Valid then
         R.Min_Front :=
           Advance (Solr.X, S, EVC_Position.SOLR_Min_Safe_Front);
         R.Max_Front :=
           Advance (Solr.X, S, EVC_Position.SOLR_Max_Safe_Front);
      else
         R.Min_Front := Front;
         R.Max_Front := Front;
      end if;
      R.Length := Length;
      R.Min_Rear := Advance (R.Min_Front, Opposite (S), Length);
      R.Speed := Natural (EVC_Odometry.Speed);
      R.Standstill := EVC_Odometry.Standstill;
      return R;
   end Train_Frame;

   ---------------------------------------------------------------------
   --  The deletions an MA operation asks for
   ---------------------------------------------------------------------

   procedure Apply (T : Origin_Table_T;
                    O : EVC_Movement_Authority.Outcome_T)
     with Global => (In_Out => (EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                Events, Event_N))
   is
   begin
      if O.Shortened then
         Record_Event (Info_MA, Change_Shortened, 0);
      end if;
      if O.Section_Expired /= 0 then
         Record_Event (Info_MA, Change_Section, O.Section_Expired);
      end if;
      if O.End_Expired then
         Record_Event (Info_MA, Change_End, 0);
      end if;
      if O.Overlap_Expired then
         Record_Event (Info_MA, Change_Overlap, 0);
      end if;
      if O.LOA_Expired then
         Record_Event (Info_MA, Change_LOA, 0);
      end if;
      if O.Delete then
         --  A.3.4.1.3: gradients, SSP, ASP, route suitability, mode
         --  profile, signalling related speed restriction deleted, track
         --  conditions reset; TSRs, level crossings, adhesion, national
         --  values unchanged; linking (EVC_Position) is phase E4
         EVC_Track_Description.Delete_Beyond
           (T, O.Delete_X, O.Delete_To, O.Delete_Before);
         EVC_Movement_Authority.Delete_Beyond
           (T, O.Delete_X, O.Delete_To, O.Delete_Before);
         EVC_Track_Conditions.Delete_Beyond
           (T, O.Delete_X, O.Delete_To, O.Delete_Before);
      end if;
   end Apply;

   ---------------------------------------------------------------------
   --  The packets of a group message
   ---------------------------------------------------------------------

   subtype Reader_T is ETCS_Bits.Reader (ETCS_Bits.Max_Bytes);

   --  The order in which the packets of a message are evaluated
   type Order_Kind_T is
     (K3, K27, K21, K51, K65, K66, K141, K68, K39, K67, K70, K71, K88,
      K12, K80);

   function Kind_Of (K : Order_Kind_T) return ETCS_Catalogue.Packet_Kind_T is
     (case K is
         when K3   => ETCS_Catalogue.Track_P3,
         when K27  => ETCS_Catalogue.Track_P27,
         when K21  => ETCS_Catalogue.Track_P21,
         when K51  => ETCS_Catalogue.Track_P51,
         when K65  => ETCS_Catalogue.Track_P65,
         when K66  => ETCS_Catalogue.Track_P66,
         when K141 => ETCS_Catalogue.Track_P141,
         when K68  => ETCS_Catalogue.Track_P68,
         when K39  => ETCS_Catalogue.Track_P39,
         when K67  => ETCS_Catalogue.Track_P67,
         when K70  => ETCS_Catalogue.Track_P70,
         when K71  => ETCS_Catalogue.Track_P71,
         when K88  => ETCS_Catalogue.Track_P88,
         when K12  => ETCS_Catalogue.Track_P12,
         when K80  => ETCS_Catalogue.Track_P80);

   procedure Take_Packet (K           : Order_Kind_T;
                          J, P        : Positive;
                          M           : Message_T;
                          T           : Origin_Table_T;
                          Train       : Train_Frame_T;
                          MA_Accepted : in out Boolean)
     with Global => (In_Out => (EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                Events, Event_N),
                     Input  => (EVC_Position.State, EVC_Train_Data.State)),
          Pre => P <= EVC_Position.Taken_Packet_Count (J)
   is
      R  : Reader_T;
      OK : Boolean;
   begin
      EVC_Position.Open_Taken_Packet (J, P, R);
      case K is
         when K3 =>
            declare
               X : ETCS_Track_Packets.P3.Packet_T;
            begin
               ETCS_Track_Packets.P3.Decode (R, X, OK);
               if OK and then X.Q_SCALE <= 2 then
                  --  3.18.2.3: now, or at D_VALIDNV ("estimated" item)
                  EVC_National_Values.Receive
                    (X,
                     Immediate   => X.D_VALIDNV = 32_767 or else M.Origin = 0,
                     At_Location =>
                       At_Offset (M, Scaled (Natural (X.D_VALIDNV),
                                             Natural (X.Q_SCALE))));
                  Record_Event (Info_National_Values, Change_Stored, M.Msg);
               end if;
            end;
         when K27 =>
            declare
               X : ETCS_Track_Packets.P27.Packet_T;
            begin
               ETCS_Track_Packets.P27.Decode (R, X, OK);
               if OK then
                  EVC_Track_Description.Take_SSP
                    (X, M, T, EVC_Train_Data.Categories);
                  Record_Event (Info_SSP, Change_Stored, M.Msg);
               end if;
            end;
         when K21 =>
            declare
               X : ETCS_Track_Packets.P21.Packet_T;
            begin
               ETCS_Track_Packets.P21.Decode (R, X, OK);
               if OK then
                  EVC_Track_Description.Take_Gradients (X, M, T);
                  Record_Event (Info_Gradients, Change_Stored, M.Msg);
               end if;
            end;
         when K51 =>
            declare
               X : ETCS_Track_Packets.P51.Packet_T;
            begin
               ETCS_Track_Packets.P51.Decode (R, X, OK);
               if OK then
                  EVC_Track_Description.Take_ASP
                    (X, M, T, EVC_Train_Data.Categories.Axle_Load);
                  Record_Event (Info_ASP, Change_Stored, M.Msg);
               end if;
            end;
         when K65 =>
            declare
               X : ETCS_Track_Packets.P65.Packet_T;
            begin
               ETCS_Track_Packets.P65.Decode (R, X, OK);
               if OK then
                  EVC_Track_Description.Take_TSR (X, M, T);
                  Record_Event (Info_TSR, Change_Stored,
                                Natural (X.NID_TSR));
               end if;
            end;
         when K66 =>
            declare
               X : ETCS_Track_Packets.P66.Packet_T;
               N : Natural;
            begin
               ETCS_Track_Packets.P66.Decode (R, X, OK);
               if OK then
                  EVC_Track_Description.Revoke_TSR (X, N);
                  if N > 0 then
                     Record_Event (Info_TSR, Change_Deleted,
                                   Natural (X.NID_TSR));
                  end if;
               end if;
            end;
         when K141 =>
            declare
               X : ETCS_Track_Packets.P141.Packet_T;
            begin
               ETCS_Track_Packets.P141.Decode (R, X, OK);
               if OK then
                  EVC_Track_Description.Take_Default_Gradient (X);
                  Record_Event (Info_Default_Gradient, Change_Stored, M.Msg);
               end if;
            end;
         when K68 =>
            declare
               X : ETCS_Track_Packets.P68.Packet_T;
            begin
               ETCS_Track_Packets.P68.Decode (R, X, OK);
               if OK then
                  EVC_Track_Conditions.Take_Conditions (X, M, T);
                  Record_Event (Info_Track_Conditions, Change_Stored, M.Msg);
               end if;
            end;
         when K39 =>
            declare
               X : ETCS_Track_Packets.P39.Packet_T;
            begin
               ETCS_Track_Packets.P39.Decode (R, X, OK);
               if OK then
                  EVC_Track_Conditions.Take_Traction (X, M);
                  Record_Event (Info_Traction, Change_Stored, M.Msg);
               end if;
            end;
         when K67 =>
            declare
               X : ETCS_Track_Packets.P67.Packet_T;
            begin
               ETCS_Track_Packets.P67.Decode (R, X, OK);
               if OK then
                  EVC_Track_Conditions.Take_Big_Metal_Masses (X, M, T);
                  Record_Event (Info_Big_Metal_Masses, Change_Stored, M.Msg);
               end if;
            end;
         when K70 =>
            declare
               X : ETCS_Track_Packets.P70.Packet_T;
            begin
               ETCS_Track_Packets.P70.Decode (R, X, OK);
               if OK then
                  EVC_Track_Description.Take_Suitability (X, M, T);
                  Record_Event (Info_Route_Suitability, Change_Stored,
                                M.Msg);
               end if;
            end;
         when K71 =>
            declare
               X : ETCS_Track_Packets.P71.Packet_T;
            begin
               ETCS_Track_Packets.P71.Decode (R, X, OK);
               if OK then
                  EVC_Track_Description.Take_Adhesion (X, M, T);
                  Record_Event (Info_Adhesion, Change_Stored, M.Msg);
               end if;
            end;
         when K88 =>
            declare
               X : ETCS_Track_Packets.P88.Packet_T;
            begin
               ETCS_Track_Packets.P88.Decode (R, X, OK);
               if OK then
                  EVC_Track_Description.Take_LX (X, M, T);
                  Record_Event (Info_Level_Crossing, Change_Stored,
                                Natural (X.NID_LX));
               end if;
            end;
         when K12 =>
            declare
               X  : ETCS_Track_Packets.P12.Packet_T;
               MA : EVC_Movement_Authority.MA_T;
               O  : EVC_Movement_Authority.Outcome_T;
            begin
               ETCS_Track_Packets.P12.Decode (R, X, OK);
               if OK then
                  --  3.11.6.2: taken as soon as received
                  EVC_Movement_Authority.Take_V_Main (X);
                  if X.V_MAIN = 0 then
                     Record_Event (Info_Signalling_Speed, Change_Trip, 0);
                  else
                     Record_Event (Info_Signalling_Speed, Change_Stored,
                                   Natural (X.V_MAIN));
                  end if;
                  MA := EVC_Movement_Authority.From_Packet (X, M);
                  if MA.Present
                    and then Train.Valid
                    --  3.7.2.3, 3.7.2.3.1
                    and then EVC_Track_Description.Covered
                               (T, MA.Sense, Train.Est_Front,
                                Frame (T,
                                       EVC_Movement_Authority.SvL_Location
                                         (MA),
                                       Estimated_Item))
                  then
                     EVC_Movement_Authority.Accept_MA
                       (MA, T, Train, M.Start_Ms, O);
                     Record_Event (Info_MA, Change_Stored, M.Msg);
                     Apply (T, O);
                     MA_Accepted := True;
                  else
                     Record_Event (Info_MA, Change_Rejected, M.Msg);
                  end if;
               end if;
            end;
         when K80 =>
            declare
               X : ETCS_Track_Packets.P80.Packet_T;
            begin
               ETCS_Track_Packets.P80.Decode (R, X, OK);
               --  3.7.1.1 b): with the MA it belongs to
               if OK and then MA_Accepted then
                  EVC_Movement_Authority.Take_Mode_Profile (X, M);
                  Record_Event (Info_Mode_Profile, Change_Stored, M.Msg);
               end if;
            end;
      end case;
   end Take_Packet;

   --  Group G of the position's last Update, as message number Msg_Count
   procedure Take_Group (G     : Positive;
                         T     : Origin_Table_T;
                         Train : Train_Frame_T)
     with Global => (In_Out => (EVC_Track_Description.State,
                                EVC_Movement_Authority.State,
                                EVC_Track_Conditions.State,
                                EVC_National_Values.State,
                                Events, Event_N, Msg_Count),
                     Input  => (EVC_Position.State, EVC_Train_Data.State)),
          Pre => G <= EVC_Position.Taken_Count
   is
      Tk          : constant EVC_Position.Taken_T := EVC_Position.Taken (G);
      M           : Message_T;
      Reverted    : Boolean;
      MA_Accepted : Boolean := False;
   begin
      if Msg_Count < Natural'Last - 1 then
         Msg_Count := Msg_Count + 1;
      end if;
      M := (Origin   => Tk.Origin,
            Sense    => Tk.S,
            Msg      => Msg_Count,
            Start_Ms => Tk.Start_Ms);
      --  3.18.2.4, 3.18.2.10
      EVC_National_Values.Check_Country (Tk.Group.Id.NID_C, Reverted);
      if Reverted then
         Record_Event (Info_National_Values, Change_Defaults, 0);
      end if;
      if Tk.Origin = 0 then
         Record_Event (Info_Group, Change_No_Origin, 0);
      end if;
      for K in Order_Kind_T loop
         for J in Tk.First .. Tk.First + Tk.Count - 1 loop
            for P in 1 .. EVC_Position.Taken_Packet_Count (J) loop
               declare
                  E : constant ETCS_Packet_Index.Entry_T :=
                    EVC_Position.Taken_Entry (J, P);
               begin
                  if E.Kind = Kind_Of (K)
                    and then EVC_Position.Valid_For
                               (E.Q_DIR, Tk.Group.Orientation, Tk.T)
                  then
                     Take_Packet (K, J, P, M, T, Train, MA_Accepted);
                  end if;
               end;
            end loop;
         end loop;
      end loop;
   end Take_Group;

   ---------------------------------------------------------------------
   --  The snapshot
   ---------------------------------------------------------------------

   --  km/h, rounded, from cm/s
   function Kmh (Cms : Natural) return Natural is
     ((Natural'Min (Cms, 30_000) * 9 + 125) / 250);

   --  A distance ahead of From to X along S, m, 0 behind, at most Max
   function Metres_Ahead (S : Sense_T; From, X : Dist_T; Max : Natural)
     return Natural
   is (if A (S, X) <= A (S, From) then 0
       else Natural (Cm_T'Min (Diff (A (S, X), A (S, From)) / 100,
                               Cm_T (Max))))
     with Pre => Max <= 2**16;

   procedure Build (T          : Origin_Table_T;
                    Train      : Train_Frame_T;
                    Mode_Speed : Speed_Cms_T;
                    Now_Ms     : Unsigned_64)
     with Global => (In_Out => (Snap, Sources, Steps, Ceiling, Failures,
                                Indicated, Indicated_N, Sent, Sent_N,
                                Cond_Due, Plan, Plan_Due,
                                EVC_Track_Conditions.State),
                     Input  => (Driver_Slippery, EVC_Odometry.State,
                                EVC_Train_Data.State,
                                EVC_National_Values.State,
                                EVC_Track_Description.State,
                                EVC_Movement_Authority.State)),
          Post => Snap.MRSP.Count = Steps.Count
                  and then Sorted (Steps)
                  and then Below (Steps, Sources, 0, Ceiling)
                  and then (for all K in 1 .. Snap.MRSP.Count =>
                              A (Snap.Train.Ahead,
                                 Snap.MRSP.Segments (K).Start)
                                = Steps.List (K).Start
                              and then Snap.MRSP.Segments (K).Speed
                                         = Steps.List (K).Value)
                  and then (if Snap.MA.Present
                            then A (Snap.Train.Ahead, Snap.MA.SvL)
                                   >= A (Snap.Train.Ahead, Snap.MA.EOA))
   is
      MA_Now   : constant EVC_Movement_Authority.MA_T :=
        EVC_Movement_Authority.MA;
      Ahead    : constant Sense_T :=
        (if MA_Now.Present then MA_Now.Sense else Train.Sense);
      Data     : constant Train_Data_T := EVC_Train_Data.Data;
      NV       : constant National_Values_T :=
        EVC_National_Values.Current.Values;
      Grad_Src : Elements_T;
      G_Steps  : Steps_T;
      Checked  : Boolean;
      Default_G : constant Gradient_T :=
        (if EVC_Track_Description.Default_Gradient_Known
         then EVC_Track_Description.Default_Gradient else 0);
      Movement : constant EVC_Ports.Movement_T := EVC_Odometry.Movement;
      Towards  : constant Sense_T :=
        (if Movement = EVC_Ports.Towards_Cab_B then Minus else Plus);
      Ind      : EVC_Track_Conditions.Indications_T;
      Orders   : EVC_Track_Conditions.Orders_T;
      MA_R     : Movement_Authority_T;
   begin
      --  the train
      Snap.Train :=
        (Position_Valid   => Train.Valid,
         Ahead            => Ahead,
         Est_Front        => Train.Est_Front,
         Max_Safe_Front   => Train.Max_Front,
         Min_Safe_Front   => Train.Min_Front,
         Speed            => Speed_Cms_T (Natural'Min (Train.Speed,
                                                       Speed_Cms_T'Last)),
         Speed_Max        =>
           Speed_Cms_T (Natural'Min (Natural (EVC_Odometry.Speed_Max),
                                     Speed_Cms_T'Last)),
         Standstill       => Train.Standstill,
         Moving_Ahead     => Movement in EVC_Ports.Towards_Cab_A
                                       | EVC_Ports.Towards_Cab_B
                             and then Towards = Ahead,
         Moving_Backwards => Movement in EVC_Ports.Towards_Cab_A
                                       | EVC_Ports.Towards_Cab_B
                             and then Towards /= Ahead);
      Snap.Train_Data := Data;
      Snap.National := NV;
      Snap.Mode_Speed := Mode_Speed;

      --  the MRSP (3.13.7): the speed restrictions, the signalling
      --  related one (3.11.6.2: from its reception on), under the
      --  maximum train speed (3.11.8) and the mode related speed
      Sources := (Count => 0, List => (others => (others => <>)),
                  Lost => 0);
      EVC_Track_Description.Speed_Elements (T, Ahead, Data.Length, Sources);
      if EVC_Movement_Authority.V_Main_Known and then MA_Now.Sense = Ahead
      then
         Add (Sources, Axis_Start,
              (if EVC_Movement_Authority.V_Main_Open then Max_Cm
               else A (Ahead, Frame (T, EVC_Movement_Authority.V_Main_Finish,
                                     Min_Item))),
              EVC_Movement_Authority.V_Main);
      end if;
      Ceiling := Value_T (Speed_Cms_T'Min (Data.Max_Speed, Mode_Speed));
      Envelope (Sources, Default => No_Speed_Limit, Floor => 0,
                Ceiling => Ceiling, Capacity => Max_Speed_Segments,
                P => Steps, Checked => Checked);
      if not Checked and then Failures < Natural'Last then
         Failures := Failures + 1;
      end if;
      Snap.MRSP.Count := Steps.Count;
      for K in 1 .. Steps.Count loop
         pragma Loop_Invariant
           (Snap.MRSP.Count = Steps.Count
            and then (for all K2 in 1 .. K - 1 =>
                        A (Ahead, Snap.MRSP.Segments (K2).Start)
                          = Steps.List (K2).Start
                        and then Snap.MRSP.Segments (K2).Speed
                                   = Steps.List (K2).Value));
         Snap.MRSP.Segments (K) :=
           (Start => A (Ahead, Steps.List (K).Start),
            Speed => Speed_Cms_T (Steps.List (K).Value));
      end loop;

      --  the gradients (3.11.12): the lowest where elements overlap, the
      --  default gradient for TSR where none is (3.11.12.5)
      Grad_Src := (Count => 0, List => (others => (others => <>)),
                   Lost => 0);
      EVC_Track_Description.Gradient_Elements (T, Ahead, Grad_Src);
      Envelope (Grad_Src, Default => Default_G, Floor => -255,
                Ceiling => 255, Capacity => Max_Gradient_Segments,
                P => G_Steps, Checked => Checked);
      if not Checked and then Failures < Natural'Last then
         Failures := Failures + 1;
      end if;
      Snap.Gradients.Count := G_Steps.Count;
      for K in 1 .. G_Steps.Count loop
         Snap.Gradients.Segments (K) :=
           (Start    => A (Ahead, G_Steps.List (K).Start),
            Gradient => Gradient_T (G_Steps.List (K).Value));
      end loop;

      --  the MA, the braking, the adhesion
      EVC_Movement_Authority.Authority (T, NV.V_NVREL, MA_R);
      Snap.MA := MA_R;
      EVC_Track_Conditions.Inhibitions (T, Ahead, Data.Length,
                                        Snap.Inhibitions);
      Snap.Adhesion := (Count => 0, Areas => (others => (0, 0)),
                        Driver_Slippery => Driver_Slippery);
      EVC_Track_Description.Adhesion_Areas (T, Ahead, Snap.Adhesion);
      Snap.Supervise := MA_R.Present and then EVC_Train_Data.Valid;

      --  the temporary EOA and SvL: the nearest (3.12.2.5)
      declare
         F1, F2   : Boolean;
         E1, E2   : Dist_T;
         S1, S2   : Dist_T;
         Has_SvL  : Boolean;
      begin
         Snap.Temporary := (others => <>);
         EVC_Movement_Authority.Mode_Profile_Target
           (T, Train.Est_Front, F1, E1, Has_SvL, S1);
         EVC_Track_Description.LX_Target
           (T, Ahead, Train.Est_Front, F2, E2, S2);
         if F1 and then (not F2 or else A (Ahead, E1) <= A (Ahead, E2)) then
            Snap.Temporary := (Present => True, EOA => E1,
                               Has_SvL => Has_SvL, SvL => S1);
         elsif F2 then
            Snap.Temporary := (Present => True, EOA => E2,
                               Has_SvL => True, SvL => S2);
         end if;
      end;

      --  the track conditions: MSG_TRACK_COND when they changed
      EVC_Track_Conditions.Evaluate (T, Train, Now_Ms, Ind, Orders);
      Indicated := (others => (others => <>));
      Indicated_N := 0;
      for I in 1 .. Ind.Count loop
         exit when Indicated_N = EVC_DMI_Port.Max_Track_Cond;
         Indicated_N := Indicated_N + 1;
         Indicated (Indicated_N) :=
           (Id   => Unsigned_8 (Ind.List (I).Id),
            Kind => Unsigned_8 (Ind.List (I).Kind));
      end loop;
      Cond_Due := False;
      if Indicated_N /= Sent_N then
         Cond_Due := True;
      else
         for I in 1 .. Indicated_N loop
            if Indicated (I) /= Sent (I) then
               Cond_Due := True;
            end if;
         end loop;
      end if;
      if Cond_Due then
         Sent := Indicated;
         Sent_N := Indicated_N;
      end if;

      --  the planning (DMI 8.3): distances from the estimated front end
      Plan := (others => <>);
      Plan_Due := Snap.Supervise and then Train.Valid;
      if Plan_Due then
         declare
            Front : constant Dist_T := Train.Est_Front;
            EOA   : constant Dist_T := MA_R.EOA;
            MA_M  : constant Natural :=
              Metres_Ahead (Ahead, Front, EOA, 65_534);
         begin
            Plan.MA_Dist := Unsigned_16 (MA_M);
            Plan.Ceiling := Unsigned_16
              (Natural'Min (Kmh (Natural (Lowest
                 (Steps, A (Ahead, Train.Min_Front),
                  A (Ahead, Train.Max_Front)))), 400));
            --  the gradient at the front, then its changes ahead
            Plan.Gradient_Count := 1;
            Plan.Gradients (1) :=
              (Start => 0,
               Value => Integer'Max
                 (-128, Integer'Min
                    (127, Value_At (G_Steps, A (Ahead, Front)))));
            for K in 2 .. G_Steps.Count loop
               exit when Plan.Gradient_Count
                           = EVC_DMI_Port.Max_Planning_Gradients;
               if G_Steps.List (K).Start > A (Ahead, Front)
                 and then Metres_Ahead (Ahead, Front,
                                        A (Ahead, G_Steps.List (K).Start),
                                        65_535) <= 32_000
               then
                  Plan.Gradient_Count := Plan.Gradient_Count + 1;
                  Plan.Gradients (Plan.Gradient_Count) :=
                    (Start => Unsigned_16
                       (Metres_Ahead (Ahead, Front,
                                      A (Ahead, G_Steps.List (K).Start),
                                      32_000)),
                     Value => Integer'Max
                       (-128, Integer'Min (127, G_Steps.List (K).Value)));
               end if;
            end loop;
            --  the MRSP ahead up to the EOA, then the EOA or the LOA
            for K in 2 .. Steps.Count loop
               exit when Plan.Speed_Count
                           = EVC_DMI_Port.Max_Planning_Speeds - 1;
               declare
                  D : constant Natural :=
                    Metres_Ahead (Ahead, Front,
                                  A (Ahead, Steps.List (K).Start), 65_535);
               begin
                  if Steps.List (K).Start > A (Ahead, Front)
                    and then D < MA_M and then D <= 32_000
                  then
                     Plan.Speed_Count := Plan.Speed_Count + 1;
                     Plan.Speeds (Plan.Speed_Count) :=
                       (Dist  => Unsigned_16 (D),
                        Speed => Unsigned_16
                          (Natural'Min (Kmh (Steps.List (K).Value), 400)));
                  end if;
               end;
            end loop;
            if MA_M <= 32_000
              and then Plan.Speed_Count < EVC_DMI_Port.Max_Planning_Speeds
            then
               Plan.Speed_Count := Plan.Speed_Count + 1;
               Plan.Speeds (Plan.Speed_Count) :=
                 (Dist  => Unsigned_16 (MA_M),
                  Speed => Unsigned_16
                    (Natural'Min (Kmh (MA_R.LOA_Speed), 400)));
            end if;
            --  the orders of the track conditions ahead
            for I in 1 .. Orders.Count loop
               exit when Plan.Order_Count = EVC_DMI_Port.Max_Planning_Orders;
               declare
                  D : constant Natural :=
                    Metres_Ahead (Ahead, Front, Orders.List (I).At_X, 65_535);
               begin
                  if D <= 32_000 then
                     Plan.Order_Count := Plan.Order_Count + 1;
                     Plan.Orders (Plan.Order_Count) :=
                       (Symbol => Unsigned_8 (Orders.List (I).Symbol),
                        Dist   => Unsigned_16 (D));
                  end if;
               end;
            end loop;
         end;
      end if;
   end Build;

   --------------
   -- Evaluate --
   --------------

   procedure Evaluate (Now_Ms : Unsigned_64; Mode_Speed : Speed_Cms_T) is
      T     : constant Origin_Table_T := Origin_Table;
      Train : constant Train_Frame_T := Train_Frame;
      O     : EVC_Movement_Authority.Outcome_T;
      Marks : Origin_Marks_T := (others => False);
   begin
      Event_N := 0;

      --  1. 3.11.5.10
      if EVC_Position.Orientation_Known then
         if Orient_Seen and then EVC_Position.Orientation /= Last_Orient
           and then EVC_Track_Description.TSR.Count > 0
         then
            EVC_Track_Description.Delete_TSRs;
            Record_Event (Info_TSR, Change_Orientation, 0);
         end if;
         Last_Orient := EVC_Position.Orientation;
         Orient_Seen := True;
      end if;

      --  2. the groups of the cycle
      for G in 1 .. EVC_Position.Taken_Count loop
         Take_Group (G, T, Train);
      end loop;

      --  3. the timers of the MA
      EVC_Movement_Authority.Supervise (T, Train, Now_Ms, O);
      Apply (T, O);

      --  4. 3.18.2.3: the national values waiting for their location
      if EVC_National_Values.Pending and then Train.Valid then
         declare
            L : constant Location_T := EVC_National_Values.Pending_At;
            S : constant Sense_T :=
              (if L.Origin /= 0 and then T (L.Origin).Used
               then T (L.Origin).Sense else Train.Sense);
         begin
            if A (S, Train.Est_Front)
               >= A (S, Frame (T, L, Estimated_Item))
            then
               EVC_National_Values.Apply_Pending;
               Record_Event (Info_National_Values, Change_Applicable, 0);
            end if;
         end;
      end if;

      --  5. A.3.1: behind the train; the origins no longer used
      if Train.Valid then
         EVC_Track_Description.Delete_Behind (T, Train.Min_Rear);
         EVC_Movement_Authority.Delete_Behind
           (T, Train.Min_Rear, EVC_Track_Description.Keep_In_Rear);
         EVC_Track_Conditions.Delete_Behind
           (T, Train.Min_Rear, EVC_Track_Description.Keep_In_Rear);
      end if;
      EVC_Track_Description.Mark (Marks);
      EVC_Movement_Authority.Mark (Marks);
      EVC_Track_Conditions.Mark (Marks);
      if EVC_National_Values.Pending then
         Mark (EVC_National_Values.Pending_At, Marks);
      end if;
      for I in EVC_Origins.Index_T loop
         if EVC_Origins.Get (I).Used and then not Marks (I) then
            EVC_Origins.Release (I);
         end if;
      end loop;

      --  6., 7.
      Build (T, Train, Mode_Speed, Now_Ms);
   end Evaluate;

end EVC_Stored_Information;
