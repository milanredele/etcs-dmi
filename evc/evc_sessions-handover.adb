--  ETCS on-board (EVC)
--  Phase E5 (e5/handover): the RBC/RBC handover of 3.15.1.3 (see the
--  specification).

pragma Unevaluated_Use_Of_Old (Allow);

package body EVC_Sessions.Handover
  with SPARK_Mode => On,
       Refined_State => (State => (Order, Opened, Single, Switch_Next,
                                   Old_S, Old_C, Rear_Watch, Rear_Since,
                                   Rear_Repeats, Forced, TD_To,
                                   TD_Given))
is
   package R renames EVC_Radio;
   use type R.Session_Ref_T;
   use type R.Session_State_T;
   use type R.RBC_Id_T;
   use type R.Time_Ms_T;
   use type EVC_Balise_Groups.Identity_T;

   --  A.3.1 "Waiting time before radio message repetition" and
   --  "Repetition of radio messages" (3.15.1.3.9, decision 4)
   Wait_Ms     : constant := 15_000;
   Max_Repeats : constant := 3;

   type Order_T is record
      Present : Boolean := False;
      --  taken this cycle, the border not given to the position yet
      Fresh   : Boolean := False;
      RBC     : R.RBC_Id_T := R.No_RBC;
      Radio   : NID_RADIO_T := 0;
      Ref     : EVC_Balise_Groups.Identity_T :=
        EVC_Balise_Groups.Unknown_Identity;
      D       : EVC_Distances.Length_T := 0;
   end record;

   Order        : Order_T;
   --  3.15.1.3.1 a): the session with the Accepting RBC asked for
   Opened       : Boolean := False;
   --  3.15.1.3.2: one session; the Accepting RBC's once the other is over
   Single       : Boolean := False;
   --  decision 3: the border reported, the switch in the next cycle
   Switch_Next  : Boolean := False;
   --  3.15.1.3.8: the Handing Over session and contact retained
   Old_S        : R.Session_Ref_T := R.No_Session;
   Old_C        : R.RBC_Contact_T := R.No_Contact;
   --  3.15.1.3.9: the min safe rear end reported at Rear_Since
   Rear_Watch   : Boolean := False;
   Rear_Since   : R.Time_Ms_T := 0;
   Rear_Repeats : Natural range 0 .. Max_Repeats := 0;
   Forced       : Boolean := False;
   --  3.15.1.3.3: the session that is to get the Train Data
   TD_To        : R.Session_Ref_T := R.No_Session;
   TD_Given     : R.Session_Ref_T := R.No_Session;

   procedure Clear is
   begin
      Order := (others => <>);
      Opened := False;
      Single := False;
      Switch_Next := False;
      Old_S := R.No_Session;
      Old_C := R.No_Contact;
      Rear_Watch := False;
      Rear_Since := 0;
      Rear_Repeats := 0;
      Forced := False;
      TD_To := R.No_Session;
      TD_Given := R.No_Session;
   end Clear;

   --  3.15.1.3.2.2: the new order replaces the stored one
   procedure Take_Order (RBC   : EVC_Radio.RBC_Id_T;
                         Radio : NID_RADIO_T;
                         Ref   : EVC_Balise_Groups.Identity_T;
                         D     : EVC_Distances.Length_T)
   is
   begin
      Order := (Present => True, Fresh => True, RBC => RBC,
                Radio   => Radio, Ref => Ref, D => D);
   end Take_Order;

   function Ordered (RBC : EVC_Radio.RBC_Id_T) return Boolean is
     (Order.Present and then Order.RBC = RBC);

   function Order_Stored return Boolean is (Order.Present);

   function Old return EVC_Radio.Session_Ref_T is (Old_S);

   function Old_Contact return EVC_Radio.RBC_Contact_T is (Old_C);

   function Held (S : EVC_Radio.Session_T) return Boolean is
     (R.Accepting = R.Session_Ref_T (S) and then Order.Present);

   function Also_Reported (S : EVC_Radio.Session_T) return Boolean is
     (R.Accepting = R.Session_Ref_T (S) or else Old_S = R.Session_Ref_T (S));

   function Forced_Report (S : EVC_Radio.Session_T) return Boolean is
     (Forced and then Old_S = R.Session_Ref_T (S));

   function Train_Data_To return EVC_Radio.Session_Ref_T is (TD_To);

   procedure Train_Data_Sent is
   begin
      TD_Given := TD_To;
      TD_To := R.No_Session;
   end Train_Data_Sent;

   procedure Produced is
   begin
      Forced := False;
   end Produced;

   --  4.10, 4.8.5.4 b): the order and the role of the Accepting RBC go
   procedure Delete is
      Sv : constant R.Session_Ref_T := R.Supervising;
   begin
      if Order.Present and then R.Accepting /= R.No_Session
        and then R.Roles_Consistent
      then
         R.Set_Roles (Sv, R.No_Session);
      end if;
      Order := (others => <>);
      Opened := False;
      Single := False;
      Switch_Next := False;
      TD_To := R.No_Session;
   end Delete;

   --  The session S, other than the supervising one, set up with the
   --  Accepting RBC becomes the Accepting one (3.15.1.1.6)
   procedure Find_Accepting
     with Global => (In_Out => R.State, Input => Order),
          Post => R.Sessions = R.Sessions'Old
   is
      Sv : constant R.Session_Ref_T := R.Supervising;
      N  : constant R.Session_Count_T := R.Sessions;
   begin
      if not Order.Present or else Sv = R.No_Session
        or else R.Accepting /= R.No_Session
        or else not R.Roles_Consistent
      then
         return;
      end if;
      for S in R.Session_T loop
         pragma Loop_Invariant (R.Supervising = Sv
                                and then R.Roles_Consistent
                                and then R.Sessions = N);
         if R.Usable (S) and then R.Session_Ref_T (S) /= Sv
           and then R.Info (S).State /= R.Idle
           and then R.Info (S).RBC = Order.RBC
           and then R.Accepting = R.No_Session
         then
            R.Set_Roles (Sv, R.Session_Ref_T (S));
         end if;
      end loop;
   end Find_Accepting;

   --  3.15.1.3.1 a), 3.15.1.3.2, 3.15.1.3.2.3: a new order applied: the
   --  border to the position, the session of another Accepting RBC
   --  terminated, the session with the new one asked for
   procedure Apply_Order (Req : in out Request_T)
     with Global => (In_Out => (Order, Opened, Single, Switch_Next, TD_To,
                                R.State, EVC_Position.State),
                     Input  => EVC_Odometry.State),
          Post => R.Sessions = R.Sessions'Old
                  and then EVC_Position.LRBG = EVC_Position.LRBG'Old
                  and then EVC_Position.Orientation
                             = EVC_Position.Orientation'Old
                  and then EVC_Position.Active_Cab
                             = EVC_Position.Active_Cab'Old
                  and then EVC_Position.Status = EVC_Position.Status'Old
                  and then EVC_Position.Doubt_Over
                             = EVC_Position.Doubt_Over'Old
                  and then EVC_Position.Doubt_Under
                             = EVC_Position.Doubt_Under'Old
   is
      Sv : constant R.Session_Ref_T := R.Supervising;
      Ac : constant R.Session_Ref_T := R.Accepting;
      OK : Boolean := True;
   begin
      if Order.Fresh then
         Order.Fresh := False;
         Opened := False;
         Single := False;
         Switch_Next := False;
         if Order.D > 0 then
            --  from a balise group: its own, the LRBG (EVC_Stored_
            --  Information)
            if Order.Ref = EVC_Balise_Groups.Unknown_Identity then
               Order.Ref := EVC_Position.LRBG.Id;
            end if;
            EVC_Position.Set_Border (Order.Ref, Order.D, OK);
         else
            EVC_Position.Delete_Border;
         end if;
         if Ac /= R.No_Session and then R.Roles_Consistent
           and then R.Info (R.Session_T (Ac)).RBC /= Order.RBC
         then
            Req.Stop := True;
            Req.Stop_S := R.Session_T (Ac);
            R.Set_Roles (Sv, R.No_Session);
            TD_To := R.No_Session;
         end if;
         --  decision: a border referred to a group the position does
         --  not keep cannot be supervised: the order is not taken
         if not OK then
            Order := (others => <>);
         end if;
      end if;
      --  a session free for the Accepting RBC, else the next cycle
      --  (decision 1: the one of a former Accepting RBC is terminating)
      if Order.Present and then not Opened
        and then (R.Sessions = 1
                  or else R.In_Session_With (Order.RBC)
                  or else (for some S in R.Session_T =>
                             R.Usable (S) and then R.Info (S).State = R.Idle))
      then
         Opened := True;
         if R.Sessions = 2 then
            if not R.In_Session_With (Order.RBC) then
               Req.Open := True;
               Req.RBC := Order.RBC;
               Req.Radio := Order.Radio;
            end if;
         else
            Single := True;
         end if;
      end if;
   end Apply_Order;

   --  3.15.1.3.5, 3.15.1.3.7, 3.15.1.3.8, 3.17.2.8 c), e): the Accepting
   --  RBC becomes the supervising one, its contact the valid one; the
   --  Handing Over session and contact retained. Without a session with
   --  the Accepting RBC (one session, or not set up) no RBC supervises
   --  until one is established (EVC_Sessions.Take_Version), except with
   --  one session, where the Handing Over one goes on until it ends.
   procedure Switch
     with Global => (In_Out => (Order, Old_S, Old_C, Switch_Next, R.State),
                     Input  => Single),
          Post => R.Sessions = R.Sessions'Old
   is
      Sv : constant R.Session_Ref_T := R.Supervising;
      Ac : constant R.Session_Ref_T := R.Accepting;
   begin
      Old_C := R.Contact;
      Old_S := Sv;
      R.Set_Contact ((Known => True, Valid => True,
                      RBC   => Order.RBC, Radio => Order.Radio));
      if R.Roles_Consistent then
         if Ac /= R.No_Session then
            R.Set_Roles (Ac, R.No_Session);
         elsif not Single then
            R.Set_Roles (R.No_Session, R.No_Session);
         end if;
      end if;
      Order.Present := False;
      Switch_Next := False;
   end Switch;

   --  3.15.1.3.9: after the min safe rear end report, the report again
   --  every Wait_Ms without the order to terminate, Max_Repeats times;
   --  then the session terminated
   procedure Watch_Rear (Now : R.Time_Ms_T; Req : in out Request_T)
     with Global => (In_Out => (Rear_Watch, Rear_Since, Rear_Repeats,
                                Forced),
                     Input  => (Old_S, R.State))
   is
   begin
      if not Rear_Watch then
         return;
      end if;
      if Old_S = R.No_Session
        or else R.Info (R.Session_T (Old_S)).State
                  not in R.Established | R.Connection_Lost
      then
         Rear_Watch := False;
      elsif Now >= Rear_Since and then Now - Rear_Since >= Wait_Ms then
         if Rear_Repeats < Max_Repeats then
            Rear_Repeats := Rear_Repeats + 1;
            Rear_Since := Now;
            Forced := True;
         else
            Req.Stop := True;
            Req.Stop_S := R.Session_T (Old_S);
            Rear_Watch := False;
         end if;
      end if;
   end Watch_Rear;

   procedure Evaluate (Now_Ms : EVC_Radio.Time_Ms_T; Req : out Request_T)
   is
      T : EVC_Position.Triggers_T;
   begin
      Req := (others => <>);
      --  3.15.1.3.8 a): the Handing Over session is over
      if Old_S /= R.No_Session
        and then (not R.Usable (R.Session_T (Old_S))
                  or else R.Info (R.Session_T (Old_S)).State = R.Idle)
      then
         Old_S := R.No_Session;
         Old_C := R.No_Contact;
         --  3.15.1.3.2: now the session with the Accepting RBC
         if Single and then R.Contact.Known then
            Req.Establish := True;
            Req.RBC := R.Contact.RBC;
            Req.Radio := R.Contact.Radio;
            Single := False;
         end if;
      end if;
      Apply_Order (Req);
      Find_Accepting;
      T := EVC_Position.Report_Triggers;
      if Order.Present then
         if Switch_Next or else Order.D = 0 then
            Switch;
         elsif T.Border_Front then
            --  3.15.1.3.1 b), 5.15.1.4
            Req.Report := True;
            Switch_Next := True;
         end if;
      end if;
      if T.Border_Rear and then Old_S /= R.No_Session then
         --  3.15.1.3.1 c)
         Req.Report := True;
         Rear_Watch := True;
         Rear_Since := Now_Ms;
         Rear_Repeats := 0;
      end if;
      Watch_Rear (Now_Ms, Req);
      --  3.15.1.3.3: the Train Data once the session is established
      if R.Accepting /= R.No_Session and then TD_To = R.No_Session
        and then R.Info (R.Session_T (R.Accepting)).State = R.Established
        and then TD_Given /= R.Accepting
      then
         TD_To := R.Accepting;
      end if;
   end Evaluate;

end EVC_Sessions.Handover;
