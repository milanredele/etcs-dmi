--  ETCS on-board (EVC)
--  the sessions of the level transitions to and
--  from level 2 (5.10.3); see the spec.

with ETCS_Variables;
with EVC_Distances; use EVC_Distances;

package body EVC_Level_Sessions
  with SPARK_Mode => On,
       Refined_State => (State => (Was_L2, Phase, Start_Odo, Since,
                                   Repeats, N_Ordered, N_Requested,
                                   N_Terminated, Awaited))
is
   package R renames EVC_Radio;
   use type R.Session_Ref_T;
   use type R.Session_State_T;

   Was_L2       : Boolean := False;
   Phase        : Exit_Phase_T := None;
   Start_Odo    : Dist_T := 0;
   Since        : Unsigned_64 := 0;
   Repeats      : Natural range 0 .. Max_Repeats := 0;
   N_Ordered    : Natural := 0;
   N_Requested  : Natural := 0;
   N_Terminated : Natural := 0;
   Awaited      : Await_T := Nothing;

   function Exit_Phase return Exit_Phase_T is (Phase)
     with Refined_Global => Phase;
   function Radio_Data_Awaited return Await_T is (Awaited)
     with Refined_Global => Awaited;
   function Sessions_Ordered return Natural is (N_Ordered)
     with Refined_Global => N_Ordered;
   function Reports_Requested return Natural is (N_Requested)
     with Refined_Global => N_Requested;
   function Terminations return Natural is (N_Terminated)
     with Refined_Global => N_Terminated;

   procedure Bump (N : in out Natural) is
   begin
      if N < Natural'Last then
         N := N + 1;
      end if;
   end Bump;

   procedure Clear
     with Refined_Global => (Output => (Was_L2, Phase, Start_Odo, Since,
                                        Repeats, N_Ordered, N_Requested,
                                        N_Terminated, Awaited))
   is
   begin
      Was_L2 := False;
      Awaited := Nothing;
      Phase := None;
      Start_Odo := 0;
      Since := 0;
      Repeats := 0;
      N_Ordered := 0;
      N_Requested := 0;
      N_Terminated := 0;
   end Clear;

   --  The cause of the last switch of the cycle (EVC_Levels event 1,
   --  byte 4): 0 the driver
   function By_Driver return Boolean
     with Global => EVC_Levels.State
   is
      Driver : Boolean := False;
   begin
      for I in 1 .. EVC_Levels.Event_Count loop
         pragma Loop_Invariant (True);
         if EVC_Levels.Event (I).Kind = EVC_Levels.Event_Switched then
            Driver := EVC_Levels.Event (I).B4 = 0;
         end if;
      end loop;
      return Driver;
   end By_Driver;

   --  The session of the supervising RBC is established (the termination
   --  not ordered yet)
   function Supervised return Boolean is
     (R.Supervising /= R.No_Session
      and then R.Info (R.Session_T (R.Supervising)).State = R.Established)
     with Global => R.State;

   --  5.10.3.3.3, 5.10.3.6.2, 5.10.3.10.3: the min safe rear end has
   --  passed the border (decision: see the spec)
   function Border_Passed return Boolean
     with Global => (Input => (Start_Odo, EVC_Odometry.State,
                               EVC_Position.State, EVC_Train_Data.State))
   is
      Run  : constant Cm_T := abs (EVC_Odometry.Position - Start_Odo);
      Need : constant Cm_T :=
        Clamp (EVC_Train_Data.Data.Length + EVC_Position.Doubt_Under);
   begin
      return Run >= Need;
   end Border_Passed;

   procedure Request_Report
     with Global => (In_Out => (EVC_Sessions.State, N_Requested)),
          Post => EVC_Sessions.Has_Released = EVC_Sessions.Has_Released'Old
   is
   begin
      EVC_Sessions.Request_Position_Report;
      Bump (N_Requested);
   end Request_Report;

   --  5.10.3.3.5, 5.10.3.6.5, 5.10.3.10.6, 5.10.3.15.4: the repetitions,
   --  then the termination by the on-board
   --  @req 5.10.3.15.4
   procedure Await_Order (Now_Ms : Unsigned_64)
     with Global => (In_Out => (Phase, Since, Repeats, N_Requested,
                                N_Terminated, EVC_Sessions.State),
                     Input  => R.State),
          Post => EVC_Sessions.Has_Released = EVC_Sessions.Has_Released'Old
   is
   begin
      if not Supervised then
         Phase := None;
      elsif Now_Ms >= Since and then Now_Ms - Since >= Repeat_Wait_Ms then
         if Repeats < Max_Repeats then
            Request_Report;
            Repeats := Repeats + 1;
            Since := Now_Ms;
         else
            --  3.5.5.1: the on-board terminates the session
            EVC_Sessions.Take_Order
              (Establish => False,
               RBC       => R.Info (R.Session_T (R.Supervising)).RBC,
               Radio     => 0);
            Bump (N_Terminated);
            Phase := None;
         end if;
      end if;
   end Await_Order;

   --  5.10.3.15.2 a), 3.5.3.4 d): the driver changed the level to 2;
   --  b) the Radio data awaited when a) does not hold: no valid RBC
   --  contact, or not registered to the stored network type (3.5.6.7,
   --  EVC_Sessions.Network_Ready: the conditions of a) as 3.5.6.7 reads
   --  them, GSM-R only; decision 2 of e5/registration in the plan)
   --  @req 5.10.3.15.2, 5.10.3.15.2 a), 5.10.3.15.2 a) 1st bullet
   --  @req 5.10.3.15.2 a) 2nd bullet, 5.10.3.15.2 a) 3rd bullet
   procedure Driver_To_L2 (Mode : Mode_T)
     with Global => (In_Out => (EVC_Sessions.State, N_Ordered),
                     Output => Awaited,
                     Input  => R.State),
          Post => EVC_Sessions.Has_Released = EVC_Sessions.Has_Released'Old
   is
      C : constant R.RBC_Contact_T := R.Contact;
   begin
      Awaited := Nothing;
      if Mode = M_SB then
         --  decision: in SB the start of mission opens it (5.4.3.2 D7)
         null;
      elsif not (C.Known and then C.Valid) then
         Awaited := No_Contact;
      elsif not EVC_Sessions.Network_Ready then
         Awaited := No_Registration;
      else
         EVC_Sessions.Take_Order (Establish => True, RBC => C.RBC,
                                  Radio => C.Radio);
         Bump (N_Ordered);
      end if;
   end Driver_To_L2;

   --  5.10.3.15.2 b): while the Radio data are awaited, the driver's
   --  RBC data (DMI Table 50 S5-1, the same window as 5.4.3.2 S3) give
   --  the session order; its set-up waits for the registration in the
   --  session half (3.5.6.7). Decisions: the selection is forgotten
   --  when level 2 is left, once the session of the supervising RBC is
   --  established, and in SB (the start of mission's, 5.4.3.2 D7), SL,
   --  PS, SF, IS and NP (no session of this train's own); the note of
   --  b): in TR the data are not taken (the DMI offers the Radio data
   --  window from PT on, Table 50 D5 exception), the selection is kept
   --  3.5.3.4 h): outside the start of mission (not in SB) in level 2,
   --  the RBC contact the driver selects in the Radio data window
   --  establishes the session the same way, awaited or not (with the
   --  same RBC as a session established or being established: none,
   --  3.5.3.4.1; with another: that one terminated, Establish)
   --  @req 5.10.3.15.2 b), 3.5.3.4 h)
   procedure Take_Radio_Data (Mode : Mode_T; In_L2 : Boolean)
     with Global => (In_Out => (Awaited, N_Ordered, EVC_Sessions.State,
                                R.State),
                     Input  => EVC_Driver_Requests.State),
          Post => EVC_Sessions.Has_Released = EVC_Sessions.Has_Released'Old
   is
      Found : Boolean;
      RBC   : R.RBC_Id_T;
      Radio : ETCS_Variables.NID_RADIO_T;
   begin
      if Awaited /= Nothing
        and then (not In_L2 or else Supervised
                  or else Mode in M_SB | M_SL | M_PS | M_SF | M_IS | M_NP)
      then
         Awaited := Nothing;
      elsif In_L2
        and then Mode not in M_SB | M_SL | M_PS | M_SF | M_IS | M_NP | M_TR
        and then EVC_Driver_Requests.Entered (EVC_Driver_Requests.RBC_Data)
      then
         EVC_Sessions.Take_Radio_Data (Found, RBC, Radio);
         if Found then
            EVC_Sessions.Take_Order (Establish => True, RBC => RBC,
                                     Radio => Radio);
            Bump (N_Ordered);
            Awaited := Nothing;
         end if;
      end if;
   end Take_Radio_Data;

   procedure Evaluate (Mode : Mode_T; Now_Ms : Unsigned_64)
     with Refined_Global => (In_Out => (Was_L2, Phase, Start_Odo, Since,
                                        Repeats, N_Ordered, N_Requested,
                                        N_Terminated, Awaited,
                                        EVC_Sessions.State, R.State),
                             Input  => (EVC_Levels.State,
                                        EVC_Driver_Requests.State,
                                        EVC_Odometry.State,
                                        EVC_Position.State,
                                        EVC_Train_Data.State))
   is
      In_L2 : constant Boolean :=
        EVC_Levels.Valid and then EVC_Levels.Level = L2;
   begin
      if In_L2 then
         Phase := None;
         if not Was_L2 and then EVC_Levels.Switched and then By_Driver then
            Driver_To_L2 (Mode);
         end if;
      elsif Was_L2 and then EVC_Levels.Switched then
         Repeats := 0;
         if By_Driver then
            --  5.10.3.15.3: the level change reported (3.6.5.1.4)
            if Supervised then
               Phase := Awaiting_Order;
               Since := Now_Ms;
            end if;
         else
            Phase := Border_Ahead;
            Start_Odo := EVC_Odometry.Position;
         end if;
      end if;
      Take_Radio_Data (Mode, In_L2);
      Was_L2 := In_L2;
      case Phase is
         when None =>
            null;
         when Border_Ahead =>
            if Border_Passed then
               --  3.5.3.8 d): a session being established is aborted;
               --  the supervising one reports the border
               EVC_Sessions.Abort_Establishment;
               if Supervised then
                  Request_Report;
                  Phase := Awaiting_Order;
                  Since := Now_Ms;
               else
                  Phase := None;
               end if;
            end if;
         when Awaiting_Order =>
            Await_Order (Now_Ms);
      end case;
   end Evaluate;

end EVC_Level_Sessions;
