--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half: the stubs of the joint (see
--  the specification). They count the messages they are given and
--  decide nothing: nothing is sent, no condition holds.

package body EVC_Radio_Authority
  with SPARK_Mode => On,
       Refined_State => (State => (Messages, Held, Stop_Received,
                                   Mode_Changes, Cycles))
is

   type Held_T is array (Condition_T) of Boolean;

   Messages      : Natural := 0;
   Held          : Held_T := (others => False);
   Stop_Received : Boolean := False;
   Mode_Changes  : Natural := 0;
   Cycles        : Natural := 0;

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

   procedure Clear is
   begin
      Messages := 0;
      Held := (others => False);
      Stop_Received := False;
      Mode_Changes := 0;
      Cycles := 0;
   end Clear;

   procedure Take_Message (S : EVC_Radio.Session_T) is
      pragma Unreferenced (S);
   begin
      Count (Messages);
   end Take_Message;

   procedure Evaluate (Ctx : EVC_Radio.Context_T) is
      pragma Unreferenced (Ctx);
   begin
      Held := (others => False);
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
