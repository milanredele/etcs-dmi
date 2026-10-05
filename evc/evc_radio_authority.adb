--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half (see the specification).

with ETCS_Message_Catalogue;
with ETCS_Variables;          use ETCS_Variables;
with EVC_Balise_Groups;
with EVC_Distances;           use EVC_Distances;
with Interfaces;              use Interfaces;

package body EVC_Radio_Authority
  with SPARK_Mode => On,
       Refined_State => (State => (Messages, Held, Stop_Received,
                                   Mode_Changes, Cycles, Radio_MAs))
is

   use type ETCS_Message_Catalogue.Message_Kind_T;

   type Held_T is array (Condition_T) of Boolean;

   Messages      : Natural := 0;
   Held          : Held_T := (others => False);
   Stop_Received : Boolean := False;
   Mode_Changes  : Natural := 0;
   Cycles        : Natural := 0;
   --  the MAs by radio accepted since Clear
   Radio_MAs     : Natural := 0;

   procedure Count (N : in out Natural) is
   begin
      if N < Natural'Last then
         N := N + 1;
      end if;
   end Count;

   function Holds (C : Condition_T) return Boolean is (Held (C))
     with Refined_Global => Held;
   function Unconditional_Stop_Received return Boolean is (Stop_Received)
     with Refined_Global => Stop_Received;
   function Messages_Taken return Natural is (Messages)
     with Refined_Global => Messages;
   function Mode_Changes_Taken return Natural is (Mode_Changes)
     with Refined_Global => Mode_Changes;
   function Cycles_Produced return Natural is (Cycles)
     with Refined_Global => Cycles;
   function Radio_MAs_Accepted return Natural is (Radio_MAs)
     with Refined_Global => Radio_MAs;

   procedure Clear is
   begin
      Messages := 0;
      Held := (others => False);
      Stop_Received := False;
      Mode_Changes := 0;
      Cycles := 0;
      Radio_MAs := 0;
      EVC_Radio_Info.Clear;
   end Clear;

   ---------------------------------------------------------------------
   --  The messages received
   ---------------------------------------------------------------------

   --  The fields of the header of the last message received (8.4.4.6.1)
   function LRBG_Of_Last return EVC_Balise_Groups.Identity_T is
     ((NID_C  => NID_C_T (EVC_Received.Last_Value (NID_C) mod 1024),
       NID_BG => NID_BG_T (EVC_Received.Last_Value (NID_BG) mod 16384)))
     with Global => EVC_Received.Store;

   function Stamp_Of_Last return T_TRAIN_T is
     (T_TRAIN_T (EVC_Received.Last_Value (T_TRAIN) mod 2**32))
     with Global => EVC_Received.Store;

   --  D_REF of message 33 (7.5.1.17), with its Q_SCALE: the distance
   --  from the LRBG to the shifted location reference, signed along the
   --  nominal direction of the LRBG; Valid False for a spare Q_SCALE
   procedure Shift_Of_Last (Shift : out Dist_T; Valid : out Boolean)
     with Global => EVC_Received.Store
   is
      Scale : constant Natural :=
        Natural (EVC_Received.Last_Value (Q_SCALE) mod 4);
      Ref   : constant D_REF_T :=
        To_D_REF (EVC_Received.Last_Value (D_REF) mod 65536);
   begin
      Shift := 0;
      Valid := Scale <= 2;
      if Valid then
         Shift := Scaled (Natural (abs Integer (Ref)), Scale);
         if Ref < 0 then
            Shift := -Shift;
         end if;
      end if;
   end Shift_Of_Last;

   --  3.8.5, 3.8.4.2.1 a), 3.8.4.3.1 a), 3.6.2.2.2 c): the MA of message
   --  3 or 33 (Shifted: 33, its location reference shifted by D_REF), to
   --  the stores of E3 through EVC_Radio_Info: referred to the LRBG it
   --  names (an LRBG the on-board does not know leaves no origin, and
   --  the stored information rejects the MA), its timers started at
   --  the time stamp of the message
   procedure Take_Stored_Information (Shifted : Boolean;
                                      Now_Ms  : EVC_Radio.Time_Ms_T)
     with Global => (Input  => (EVC_Received.Store, EVC_Position.State,
                                EVC_Odometry.State),
                     In_Out => (EVC_Origins.State, EVC_Radio_Info.State))
   is
      Sl    : EVC_Radio_Info.Slot_T;
      Shift : Dist_T := 0;
      Valid : Boolean := True;
   begin
      if Shifted then
         Shift_Of_Last (Shift, Valid);
      end if;
      if Valid then
         EVC_Position.Radio_Origin
           (LRBG_Of_Last, Shifted, Shift, Sl.Origin, Sl.G, Sl.T, Sl.S);
      end if;
      Sl.Start_Ms := EVC_Radio.Time_Of_Stamp (Stamp_Of_Last, Now_Ms);
      EVC_Radio_Info.Put_Last (Sl);
   end Take_Stored_Information;

   procedure Take_Message (S      : EVC_Radio.Session_T;
                           Now_Ms : EVC_Radio.Time_Ms_T)
   is
      pragma Unreferenced (S);
      Kind : constant ETCS_Message_Catalogue.Message_Kind_T :=
        EVC_Received.Last_Kind;
   begin
      Count (Messages);
      if Kind = ETCS_Message_Catalogue.Track_M3 then
         Take_Stored_Information (False, Now_Ms);
      elsif Kind = ETCS_Message_Catalogue.Track_M33 then
         Take_Stored_Information (True, Now_Ms);
      end if;
   end Take_Message;

   ---------------------------------------------------------------------
   --  The cycle
   ---------------------------------------------------------------------

   procedure Evaluate (Ctx : EVC_Radio.Context_T) is
      pragma Unreferenced (Ctx);
   begin
      if EVC_Stored_Information.Radio_MA_Accepted then
         Count (Radio_MAs);
      end if;
      Held := (others => False);
      --  [31] (MA+SSP+gradient are on-board) AND (the train position
      --  confidence interval does not overlap any Mode Profile) AND
      --  (ERTMS/ETCS level is 2)
      Held (C_31) := EVC_Stored_Information.MA_On_Board
                     and then not EVC_Stored_Information.Mode_Profile_Overlap
                     and then EVC_Levels.Valid
                     and then EVC_Levels.Level = L2;
      --  the messages of the cycle were taken by the stored information
      EVC_Radio_Info.Empty;
   end Evaluate;

   procedure Mode_Changed (From, To : Mode_T) is
      pragma Unreferenced (From, To);
   begin
      Count (Mode_Changes);
   end Mode_Changed;

   procedure Produce (Ctx : EVC_Radio.Context_T) is
      pragma Unreferenced (Ctx);
   begin
      Count (Cycles);
   end Produce;

end EVC_Radio_Authority;
