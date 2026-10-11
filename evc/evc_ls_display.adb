with EVC_Distances;

package body EVC_LS_Display
  with SPARK_Mode => On,
       Refined_State => (State => (Marker, Pending, Pending_Start,
                                   Pending_Delay, On, Immediate,
                                   Shown_Kmh))
is

   use EVC_Supervision_Input;
   use type EVC_Distances.Cm_T;

   Marker        : Boolean := False;
   Pending       : Boolean := False;
   Pending_Start : Unsigned_64 := 0;
   Pending_Delay : Delay_S_T := 0;
   On            : Boolean := False;
   --  4.4.19.1.4.6: an order of this cycle displayed the LSSMA at once
   Immediate     : Boolean := False;
   Shown_Kmh     : Unsigned_16 := No_LSSMA;

   function Marker_Stored return Boolean is (Marker)
     with Refined_Global => Marker;
   function Order_Pending return Boolean is (Pending)
     with Refined_Global => Pending;
   function Toggled_On return Boolean is (On)
     with Refined_Global => On;
   function LSSMA_Kmh return Unsigned_16 is (Shown_Kmh)
     with Refined_Global => Shown_Kmh;

   procedure Clear
     with Refined_Global => (Output => (Marker, Pending, Pending_Start,
                                        Pending_Delay, On, Immediate,
                                        Shown_Kmh))
   is
   begin
      Marker := False;
      Pending := False;
      Pending_Start := 0;
      Pending_Delay := 0;
      On := False;
      Immediate := False;
      Shown_Kmh := No_LSSMA;
   end Clear;

   --  7.4.2.37.4
   procedure Take_Marker
     with Refined_Global => (Output => Marker)
   is
   begin
      Marker := True;
   end Take_Marker;

   --  4.4.19.1.4.8
   procedure Delete_Marker
     with Refined_Global => (Output => Marker)
   is
   begin
      Marker := False;
   end Delete_Marker;

   --  4.4.19.1.4.2 to 4.4.19.1.4.5
   procedure Take_Order (On       : Boolean;
                         Delay_S  : Delay_S_T;
                         Start_Ms : Unsigned_64;
                         Now_Ms   : Unsigned_64)
     with Refined_Global => (Output => (Pending, Pending_Start,
                                        Pending_Delay, Immediate,
                                        EVC_LS_Display.On))
   is
   begin
      --  4.4.19.1.4.4: a pending toggle on order is deleted
      Pending := False;
      Pending_Start := Start_Ms;
      Pending_Delay := Delay_S;
      Immediate := False;
      if not On then
         --  4.4.19.1.4.5 b)
         EVC_LS_Display.On := False;
      elsif Elapsed (Start_Ms, Now_Ms, Delay_S) then
         --  4.4.19.1.4.3 at once
         EVC_LS_Display.On := True;
         Immediate := True;
      else
         --  4.4.19.1.4.2, 4.4.19.1.4.5 a)
         EVC_LS_Display.On := False;
         Pending := True;
      end if;
   end Take_Order;

   --  4.4.19.1.4.6, 4.10
   procedure Mode_Changed (From, To : Mode_T)
     with Refined_Global => (In_Out => (Pending, On),
                             Input  => Immediate)
   is
   begin
      if To not in M_LS | M_PT then
         Pending := False;
         On := False;
      elsif To = M_LS and then From /= M_LS and then not Immediate then
         On := False;
      end if;
   end Mode_Changed;

   --  4.4.19.1.4 a) and b)
   function LSSMA (S : Snapshot_T) return Speed_Cms_T is
      Ahead  : constant EVC_Distances.Sense_T := S.Train.Ahead;
      X_Min  : constant EVC_Distances.Dist_T :=
        EVC_Distances.Along (Ahead, S.Train.Min_Safe_Front);
      X_EOA  : constant EVC_Distances.Dist_T :=
        EVC_Distances.Along (Ahead, S.MA.EOA);
      Lowest : Speed_Cms_T := Speed_Cms_T'Min (S.MA.LOA_Speed, S.Mode_Speed);
   begin
      for K in 1 .. S.MRSP.Count loop
         pragma Loop_Invariant (Lowest <= S.MA.LOA_Speed);
         --  element K runs from its start to the start of the next one;
         --  the first one also before its start
         if (K = 1
             or else EVC_Distances.Along
                       (Ahead, S.MRSP.Segments (K).Start) < X_EOA)
           and then (K = S.MRSP.Count
                     or else EVC_Distances.Along
                               (Ahead, S.MRSP.Segments (K + 1).Start)
                             > X_Min)
         then
            Lowest := Speed_Cms_T'Min (Lowest, S.MRSP.Segments (K).Speed);
         end if;
      end loop;
      return Lowest;
   end LSSMA;

   --  4.4.19.1.4.3, 4.4.19.1.4.7, 4.4.19.1.4
   procedure Step (S      : Snapshot_T;
                   Mode   : Mode_T;
                   Now_Ms : Unsigned_64)
     with Refined_Global => (Input  => (Marker, Pending_Start,
                                        Pending_Delay),
                             In_Out => (Pending, On),
                             Output => (Immediate, Shown_Kmh))
   is
      V    : Speed_Cms_T;
      Show : Boolean;
   begin
      --  4.4.19.1.4.3
      if Pending and then Elapsed (Pending_Start, Now_Ms, Pending_Delay)
      then
         Pending := False;
         On := True;
      end if;
      Immediate := False;
      Shown_Kmh := No_LSSMA;
      if Mode /= M_LS or else not S.MA.Present
        or else not S.Train.Position_Valid
      then
         return;
      end if;
      V := LSSMA (S);
      if Marker then
         Show := On;
      else
         --  4.4.19.1.4.7 a) and b)
         Show := S.MA.LOA_Speed < S.Mode_Speed
                 and then V < S.Train_Data.Max_Speed;
      end if;
      if Show then
         --  cm/s to km/h, rounded down
         Shown_Kmh := Unsigned_16 (V * 36 / 1_000);
      end if;
   end Step;

end EVC_LS_Display;
