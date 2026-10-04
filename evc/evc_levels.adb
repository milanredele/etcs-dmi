--  ETCS on-board (EVC)
--  The level and the level transitions, implementation.

with ETCS_Variables; use ETCS_Variables;
with EVC_Location;   use EVC_Location;

package body EVC_Levels
  with SPARK_Mode => On,
       Refined_State => (State => (Current, Current_Status, Switched_N,
                                   Applicable, Order, Kept, Kept_Due,
                                   Pending, Pending_Level, Pending_Since,
                                   Brake, Events, Event_N))
is

   --  An announcement: the transition at a location
   type Order_T is record
      Stored     : Boolean := False;
      Target     : Level_T := L0;
      Table      : Priority_Table_T;   -- not yet applicable
      At_Loc     : Location_T;          -- the transition location
      Ack_Loc    : Location_T;          -- the acknowledgement area
      Sense      : Sense_T := Plus;     -- of the distances
      Ack_Needed : Boolean := False;
      Ack_Shown  : Boolean := False;
      Acked      : Boolean := False;
      --  received, the acknowledgement area not looked at yet: Acked
      --  from a former order stands only if the max safe front end is
      --  in the area upon the receipt (5.10.4.1.3)
      Fresh      : Boolean := False;
   end record;

   --  An immediate or conditional order kept in SH, PS or SM
   type Kept_T is record
      Stored      : Boolean := False;
      Conditional : Boolean := False;
      Table       : Priority_Table_T;
   end record;

   type Event_Array is array (1 .. Max_Events) of Event_T;

   Current        : Level_T := L0;
   Current_Status : Level_Status_T := Unknown;
   Switched_N     : Boolean := False;
   Applicable     : Priority_Table_T;
   Order          : Order_T;
   Kept           : Kept_T;
   --  a mode other than SH, PS, SM was entered: the kept order is due
   Kept_Due       : Boolean := False;
   --  5.10.4.2: asked after the transition, not acknowledged yet
   Pending        : Boolean := False;
   Pending_Level  : Level_T := L0;
   Pending_Since  : Unsigned_64 := 0;
   Brake          : Boolean := False;
   Events         : Event_Array;
   Event_N        : Natural range 0 .. Max_Events := 0;

   ---------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------

   function Selected (T : Priority_Table_T) return Positive is
   begin
      for I in 1 .. T.Count loop
         --  not unrolled by the proof, nothing needed after the loop
         pragma Loop_Invariant (True);
         if Available (T.List (I).Level) then
            return I;
         end if;
      end loop;
      return T.Count;
   end Selected;

   function Level return Level_T is (Current)
     with Refined_Global => Current;
   function Status return Level_Status_T is (Current_Status)
     with Refined_Global => Current_Status;
   function Switched return Boolean is (Switched_N)
     with Refined_Global => Switched_N;
   function Order_Pending return Boolean is (Order.Stored)
     with Refined_Global => Order;
   function Announced return Boolean is
     (Order.Stored
      and then (Order.Target /= Current or else Current_Status /= Valid))
     with Refined_Global => (Order, Current, Current_Status);
   function Announced_Level return Level_T is (Order.Target)
     with Refined_Global => Order;
   function Ack_Asked return Boolean is
     (Pending or else (Order.Stored and then Order.Ack_Shown
                       and then not Order.Acked))
     with Refined_Global => (Pending, Order);
   function Ack_Level return Level_T is
     (if Pending then Pending_Level else Order.Target)
     with Refined_Global => (Pending, Pending_Level, Order);
   function Ack_Brake return Boolean is (Brake)
     with Refined_Global => Brake;
   function Deferred return Boolean is (Kept.Stored)
     with Refined_Global => Kept;
   function Table return Priority_Table_T is (Applicable)
     with Refined_Global => Applicable;
   function Event_Count return Natural is (Event_N)
     with Refined_Global => Event_N;
   function Event (I : Positive) return Event_T is (Events (I))
     with Refined_Global => (Input => Events, Proof_In => Event_N);

   procedure Put_Event (Kind, B3, B4 : Natural)
     with Global => (In_Out => (Events, Event_N))
   is
   begin
      if Event_N < Max_Events then
         Event_N := Event_N + 1;
         Events (Event_N) := (Kind => Unsigned_8 (Kind mod 256),
                              B3   => Unsigned_8 (B3 mod 256),
                              B4   => Unsigned_8 (B4 mod 256));
      end if;
   end Put_Event;

   ---------------------------------------------------------------------
   --  Clear, Begin_Cycle
   ---------------------------------------------------------------------

   procedure Clear is
   begin
      Current := L0;
      Current_Status := Unknown;
      Switched_N := False;
      Applicable := (others => <>);
      Order := (others => <>);
      Kept := (others => <>);
      Kept_Due := False;
      Pending := False;
      Pending_Level := L0;
      Pending_Since := 0;
      Brake := False;
      Events := (others => (others => <>));
      Event_N := 0;
   end Clear;

   procedure Begin_Cycle is
   begin
      Switched_N := False;
      Event_N := 0;
   end Begin_Cycle;

   ---------------------------------------------------------------------
   --  Tables
   ---------------------------------------------------------------------

   function Level_Of (M : M_LEVELTR_T) return Level_T is
     (case M is
         when 0 => L0,
         when 1 => NTC,
         when 2 => L1,
         --  4 .. 7 are spare: a packet with one is not taken (Valid)
         when others => L2);

   procedure Add (T : in out Priority_Table_T; E : Priority_Entry_T) is
   begin
      if T.Count < Max_Priorities then
         T.Count := T.Count + 1;
         T.List (T.Count) := E;
      end if;
   end Add;

   function Table_Of (P : ETCS_Track_Packets.P41.Packet_T)
     return Priority_Table_T
     with Pre => P.Q_SCALE <= 2,
          Post => Table_Of'Result.Count >= 1
   is
      T : Priority_Table_T;
   begin
      Add (T, (Level      => Level_Of (P.M_LEVELTR),
               NTC        => (if P.Has_NID_NTC then Natural (P.NID_NTC)
                              else 0),
               Ack_Length => Scaled (Natural (P.L_ACKLEVELTR),
                                     Natural (P.Q_SCALE))));
      for I in 1 .. Natural (P.N_ITER) loop
         pragma Loop_Invariant (T.Count >= 1);
         Add (T, (Level      => Level_Of (P.M_LEVELTR_List (I).M_LEVELTR),
                  NTC        => (if P.M_LEVELTR_List (I).Has_NID_NTC
                                 then Natural (P.M_LEVELTR_List (I).NID_NTC)
                                 else 0),
                  Ack_Length =>
                    Scaled (Natural (P.M_LEVELTR_List (I).L_ACKLEVELTR),
                            Natural (P.Q_SCALE))));
      end loop;
      return T;
   end Table_Of;

   function Table_Of (P : ETCS_Track_Packets.P46.Packet_T)
     return Priority_Table_T
     with Post => Table_Of'Result.Count >= 1
   is
      T : Priority_Table_T;
   begin
      Add (T, (Level      => Level_Of (P.M_LEVELTR),
               NTC        => (if P.Has_NID_NTC then Natural (P.NID_NTC)
                              else 0),
               Ack_Length => 0));
      for I in 1 .. Natural (P.N_ITER) loop
         pragma Loop_Invariant (T.Count >= 1);
         Add (T, (Level      => Level_Of (P.M_LEVELTR_List (I).M_LEVELTR),
                  NTC        => (if P.M_LEVELTR_List (I).Has_NID_NTC
                                 then Natural (P.M_LEVELTR_List (I).NID_NTC)
                                 else 0),
                  Ack_Length => 0));
      end loop;
      return T;
   end Table_Of;

   ---------------------------------------------------------------------
   --  The transition
   ---------------------------------------------------------------------

   --  The acknowledgement of a transition to To in the mode M (5.10.4.1,
   --  5.10.4.1.1)
   function Ack_For (To : Level_T; M : Mode_T) return Boolean is
     (M /= M_NL
      and then Ack_Needed ((if Current_Status = Valid then Current else L0),
                           To)
      and then (To /= Current or else Current_Status /= Valid))
     with Global => (Current, Current_Status);

   --  Carry out the transition to To (Cause: see Event_Switched), with
   --  the acknowledgement asked after it when Ack
   procedure Switch (To    : Level_T;
                     Cause : Natural;
                     Ack   : Boolean;
                     Now   : Unsigned_64)
     with Global => (In_Out => (Current, Current_Status, Switched_N,
                                Pending, Pending_Level, Pending_Since,
                                Events, Event_N)),
          Post => Current = To and then Current_Status = Valid
   is
   begin
      if To /= Current or else Current_Status /= Valid then
         Switched_N := True;
         Put_Event (Event_Switched, Level_T'Pos (To), Cause);
      end if;
      Current := To;
      Current_Status := Valid;
      if Ack then
         Pending := True;
         Pending_Level := To;
         Pending_Since := Now;
         Put_Event (Event_Ack_Asked, Level_T'Pos (To), 1);
      end if;
   end Switch;

   --  An immediate order to the table T (Cause 1, 3 or 4); Ack_Given: the
   --  driver acknowledged an announcement to the same level not executed
   --  yet (5.10.4.1.4)
   procedure Immediate (T         : Priority_Table_T;
                        Cause     : Natural;
                        Ack_Given : Boolean;
                        C         : Context_T)
     with Global => (In_Out => (Current, Current_Status, Switched_N,
                                Pending, Pending_Level, Pending_Since,
                                Events, Event_N),
                     Output => Applicable),
          Pre => T.Count >= 1
   is
      To : constant Level_T := T.List (Selected (T)).Level;
   begin
      Switch (To, Cause, Ack_For (To, C.Mode) and then not Ack_Given,
              C.Now_Ms);
      Applicable := T;
   end Immediate;

   ----------------
   -- Take_Order --
   ----------------

   procedure Take_Order (P : ETCS_Track_Packets.P41.Packet_T;
                         M : Message_T;
                         C : Context_T)
   is
   begin
      --  3.16.1.1.1: a spare value (the telegram parser checks it too)
      if P.Q_SCALE > 2 or else not ETCS_Track_Packets.P41.Valid (P) then
         return;
      end if;
      declare
         T  : constant Priority_Table_T := Table_Of (P);
         E  : constant Priority_Entry_T := T.List (Selected (T));
         To : constant Level_T := E.Level;
         Now_Order : constant Boolean :=
           P.D_LEVELTR = D_LEVELTR_Now_The_Level_Transition;
         --  5.10.4.1.3, 5.10.4.1.4: the driver acknowledged an order to
         --  the same level not executed yet
         Same_Acked : constant Boolean :=
           Order.Stored and then Order.Target = To and then Order.Acked;
      begin
         if C.Mode in M_SH | M_PS | M_SM then
            --  4.8.4 [7]: only the immediate order, kept for later
            if Now_Order then
               Kept := (Stored => True, Conditional => False, Table => T);
               Put_Event (Event_Stored, Level_T'Pos (To), 2);
            end if;
            return;
         end if;
         if Order.Stored then
            --  5.10.1.6, 5.10.2.10 a)
            Put_Event (Event_Deleted, Level_T'Pos (Order.Target), 2);
            Order := (others => <>);
         end if;
         if Now_Order then
            Immediate (T, 1, Same_Acked, C);
         elsif M.Origin /= 0 then
            declare
               D : constant Length_T :=
                 Scaled (Natural (P.D_LEVELTR), Natural (P.Q_SCALE));
            begin
               Order :=
                 (Stored     => True,
                  Target     => To,
                  Table      => T,
                  At_Loc     => At_Offset (M, D),
                  Ack_Loc    => At_Offset (M, Diff (D, E.Ack_Length)),
                  Sense      => M.Sense,
                  Ack_Needed => Ack_For (To, C.Mode),
                  Ack_Shown  => False,
                  Acked      => Same_Acked,
                  Fresh      => True);
               Put_Event (Event_Stored, Level_T'Pos (To), 1);
            end;
         end if;
      end;
   end Take_Order;

   ----------------------
   -- Take_Conditional --
   ----------------------

   procedure Conditional (T : Priority_Table_T; Cause : Natural;
                          C : Context_T)
     with Global => (In_Out => (Current, Current_Status, Switched_N,
                                Pending, Pending_Level, Pending_Since,
                                Events, Event_N),
                     Output => Applicable),
          Pre => T.Count >= 1
   is
   begin
      if Current_Status = Valid and then Contains (T, Current) then
         --  5.10.3.14.2, 5.10.3.14.4
         Applicable := T;
      else
         --  5.10.3.14.3
         Immediate (T, Cause, False, C);
      end if;
   end Conditional;

   procedure Take_Conditional (P : ETCS_Track_Packets.P46.Packet_T;
                               C : Context_T)
   is
      T : constant Priority_Table_T := Table_Of (P);
   begin
      if not ETCS_Track_Packets.P46.Valid (P) then
         return;
      elsif C.Mode in M_SH | M_PS | M_SM then
         Kept := (Stored => True, Conditional => True, Table => T);
         Put_Event (Event_Stored, Level_T'Pos (T.List (Selected (T)).Level),
                    2);
      else
         Conditional (T, 3, C);
      end if;
   end Take_Conditional;

   --------------
   -- Evaluate --
   --------------

   --  X along S has reached or passed the location item L
   function Passed (T : Origin_Table_T; S : Sense_T; X : Dist_T;
                    L : Location_T) return Boolean
   is (A (S, X) >= A (S, Frame (T, L, Estimated_Item)));

   procedure Evaluate (T            : Origin_Table_T;
                       C            : Context_T;
                       Driver_Level : Boolean;
                       Code         : Unsigned_16;
                       Ack          : Boolean)
   is
   begin
      --  1. the driver's level: in the start of mission (5.4.3.2 S2),
      --  else at standstill (5.10.3.15.1) in the modes where the DMI
      --  offers it (4.7.2: SB, FS, AD, LS, SR, OS, NL, UN, SN)
      if Driver_Level and then Code in 2 .. 5
        and then C.Standstill
        and then C.Mode in M_SB | M_FS | M_AD | M_LS | M_SR | M_OS | M_NL
                         | M_UN | M_SN
      then
         if Order.Stored then
            --  5.10.1.6.1, 5.10.2.10 b)
            Put_Event (Event_Deleted, Level_T'Pos (Order.Target), 0);
            Order := (others => <>);
         end if;
         Switch (Level_T'Val (Natural (Code) - 2), 0, False, C.Now_Ms);
      end if;

      --  2. an order kept in SH, PS or SM, once another mode is entered
      if Kept.Stored and then Kept_Due
        and then C.Mode not in M_SH | M_PS | M_SM
      then
         if Kept.Table.Count >= 1 then
            if Kept.Conditional then
               Conditional (Kept.Table, 4, C);
            else
               Immediate (Kept.Table, 4, False, C);
            end if;
         end if;
         Kept := (others => <>);
         Kept_Due := False;
      end if;

      --  3. the announcement: the acknowledgement area (5.10.4.1 a), not
      --  in SB, 5.10.4.1.2), the transition location (5.10.1.5)
      if Order.Stored and then C.Position_Valid then
         --  5.10.4.1.3: the acknowledgement of a former order to the
         --  same level is kept only when the condition a) is fulfilled
         --  upon the receipt; else the driver is asked again
         if Order.Fresh then
            Order.Fresh := False;
            if Order.Acked
              and then not Passed (T, Order.Sense, C.Max_Front,
                                   Order.Ack_Loc)
            then
               Order.Acked := False;
            end if;
         end if;
         if Order.Ack_Needed and then not Order.Ack_Shown
           and then C.Mode /= M_SB
           and then Passed (T, Order.Sense, C.Max_Front, Order.Ack_Loc)
         then
            Order.Ack_Shown := True;
            if not Order.Acked then
               Put_Event (Event_Ack_Asked, Level_T'Pos (Order.Target), 0);
            end if;
         end if;
         if Passed (T, Order.Sense, C.Est_Front, Order.At_Loc) then
            declare
               To    : constant Level_T := Order.Target;
               Table : constant Priority_Table_T := Order.Table;
               Ack   : constant Boolean :=
                 Order.Ack_Needed and then not Order.Acked
                 and then (C.Mode /= M_SB or else To /= Current
                           or else Current_Status /= Valid);
            begin
               Order := (others => <>);
               Switch (To, 2, Ack, C.Now_Ms);
               Applicable := Table;
            end;
         end if;
      end if;

      --  4. the driver's acknowledgement (5.10.4.1)
      if Ack then
         if Order.Stored and then Order.Ack_Shown and then not Order.Acked
         then
            Order.Acked := True;
            Put_Event (Event_Acked, Level_T'Pos (Order.Target), 0);
         elsif Pending then
            Pending := False;
            Put_Event (Event_Acked, Level_T'Pos (Pending_Level), 1);
            if Brake then
               Brake := False;
               Put_Event (Event_Brake, 0, 0);
            end if;
         end if;
      end if;

      --  5. 5.10.4.2: not acknowledged within T_ACK after the transition
      if Pending and then not Brake
        and then C.Now_Ms >= Pending_Since
        and then C.Now_Ms - Pending_Since >= T_ACK_Ms
      then
         Brake := True;
         Put_Event (Event_Brake, 1, 0);
      end if;
   end Evaluate;

   ------------------
   -- Mode_Entered --
   ------------------

   procedure Mode_Entered (From, To : Mode_T) is
      pragma Unreferenced (From);
   begin
      --  4.10: the level transition announcement and the table of
      --  priority not yet applicable are deleted
      if Order.Stored
        and then To in M_NP | M_SB | M_SH | M_SM | M_SR | M_SL | M_NL
                     | M_UN | M_SN | M_RV
      then
         Put_Event (Event_Deleted, Level_T'Pos (Order.Target), 1);
         Order := (others => <>);
      end if;
      --  4.10: an immediate or conditional order kept is deleted in these
      --  modes, and evaluated once another mode than SH, PS, SM is
      --  entered (4.4.8.1.5, 4.4.20.1.11, 4.4.21.1.11)
      if Kept.Stored then
         if To in M_SM | M_FS | M_AD | M_LS | M_SR | M_OS | M_UN | M_PT
                | M_SN | M_RV
         then
            Put_Event (Event_Deleted,
                       Level_T'Pos (Kept.Table.List (1).Level), 1);
            Kept := (others => <>);
            Kept_Due := False;
         elsif To not in M_SH | M_PS | M_SM then
            Kept_Due := True;
         end if;
      end if;
      --  4.12: the brake reasons "Change to level 0 / NTC not
      --  acknowledged" are revoked
      if Pending
        and then ((Pending_Level = L0
                   and then To in M_NP | M_SB | M_SH | M_FS | M_LS | M_SR
                                | M_OS | M_TR | M_SN)
                  or else
                  (Pending_Level = NTC
                   and then To in M_NP | M_SB | M_SH | M_FS | M_LS | M_SR
                                | M_OS | M_UN | M_TR | M_PT))
      then
         Pending := False;
         if Brake then
            Brake := False;
            Put_Event (Event_Brake, 0, 1);
         end if;
      end if;
   end Mode_Entered;

   -------------------
   -- Delete_Orders --
   -------------------

   procedure Delete_Orders is
   begin
      if Order.Stored then
         Put_Event (Event_Deleted, Level_T'Pos (Order.Target), 1);
      end if;
      Order := (others => <>);
      Kept := (others => <>);
      Kept_Due := False;
   end Delete_Orders;

   procedure Restore (L : Level_T; T : Priority_Table_T) is
   begin
      Current := L;
      Current_Status := Invalid;
      Applicable := T;
      Switched_N := False;
   end Restore;

   procedure Revalidate is
   begin
      if Current_Status = Invalid then
         Current_Status := Valid;
      end if;
   end Revalidate;

   procedure Delete_Table is
   begin
      Applicable := (others => <>);
   end Delete_Table;

   procedure Set_For_Test (L : Level_T) is
   begin
      Current := L;
      Current_Status := Valid;
   end Set_For_Test;

   ----------
   -- Mark --
   ----------

   procedure Mark (Marks : in out Origin_Marks_T) is
   begin
      if Order.Stored then
         Mark (Order.At_Loc, Marks);
         Mark (Order.Ack_Loc, Marks);
      end if;
   end Mark;

end EVC_Levels;
