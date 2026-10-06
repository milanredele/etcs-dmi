--  ETCS on-board (EVC)
--  Phase E5 (e5/levels): the sessions of the level transitions to and
--  from level 2 (5.10.3); see the spec.

with EVC_Distances; use EVC_Distances;

package body EVC_Level_Sessions
  with SPARK_Mode => On,
       Refined_State => (State => (Was_L2, Phase, Start_Odo, Since,
                                   Repeats, N_Ordered, N_Requested,
                                   N_Terminated))
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

   function Exit_Phase return Exit_Phase_T is (Phase)
     with Refined_Global => Phase;
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
                                        N_Terminated))
   is
   begin
      Was_L2 := False;
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

   --  5.10.3.15.2 a), 3.5.3.4 d): the driver changed the level to 2
   procedure Driver_To_L2 (Mode : Mode_T)
     with Global => (In_Out => (EVC_Sessions.State, N_Ordered),
                     Input  => R.State),
          Post => EVC_Sessions.Has_Released = EVC_Sessions.Has_Released'Old
   is
      C : constant R.RBC_Contact_T := R.Contact;
   begin
      --  decision: in SB the start of mission opens it (5.4.3.2 D7)
      if Mode /= M_SB and then C.Known and then C.Valid then
         EVC_Sessions.Take_Order (Establish => True, RBC => C.RBC,
                                  Radio => C.Radio);
         Bump (N_Ordered);
      end if;
   end Driver_To_L2;

   procedure Evaluate (Mode : Mode_T; Now_Ms : Unsigned_64)
     with Refined_Global => (In_Out => (Was_L2, Phase, Start_Odo, Since,
                                        Repeats, N_Ordered, N_Requested,
                                        N_Terminated, EVC_Sessions.State),
                             Input  => (EVC_Levels.State, R.State,
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
      elsif Was_L2 and then EVC_Levels.Switched and then Supervised then
         Repeats := 0;
         if By_Driver then
            --  5.10.3.15.3: the level change reported (3.6.5.1.4)
            Phase := Awaiting_Order;
            Since := Now_Ms;
         else
            Phase := Border_Ahead;
            Start_Odo := EVC_Odometry.Position;
         end if;
      end if;
      Was_L2 := In_L2;
      case Phase is
         when None =>
            null;
         when Border_Ahead =>
            if not Supervised then
               Phase := None;
            elsif Border_Passed then
               Request_Report;
               Phase := Awaiting_Order;
               Since := Now_Ms;
            end if;
         when Awaiting_Order =>
            Await_Order (Now_Ms);
      end case;
   end Evaluate;

end EVC_Level_Sessions;
