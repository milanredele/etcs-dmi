--  ETCS on-board (EVC)
--  Phase E5, the session and link half: the stubs of the joint (see the
--  specification). They count what they are given and decide nothing:
--  every verdict is Pass, nothing is buffered or sent, no condition
--  holds.

package body EVC_Sessions
  with SPARK_Mode => On,
       Refined_State => (State => (Events, Messages, Held_Back, Held,
                                   Mode_Changes, Cycles))
is

   type Held_T is array (Condition_T) of Boolean;

   Events   : Natural := 0;
   Messages : Natural := 0;
   --  the messages waiting in the transition buffer (none in the stub)
   Held_Back : Natural := 0;
   Held     : Held_T := (others => False);
   Mode_Changes : Natural := 0;
   Cycles       : Natural := 0;

   procedure Count (N : in out Natural) is
   begin
      if N < Natural'Last then
         N := N + 1;
      end if;
   end Count;

   function Has_Released return Boolean is (Held_Back > 0)
     with Refined_Global => Held_Back;
   function Holds (C : Condition_T) return Boolean is (Held (C))
     with Refined_Global => Held;
   function Events_Taken return Natural is (Events)
     with Refined_Global => Events;
   function Messages_Taken return Natural is (Messages)
     with Refined_Global => Messages;
   function Mode_Changes_Taken return Natural is (Mode_Changes)
     with Refined_Global => Mode_Changes;
   function Cycles_Produced return Natural is (Cycles)
     with Refined_Global => Cycles;

   procedure Clear is
   begin
      Events := 0;
      Messages := 0;
      Held_Back := 0;
      Held := (others => False);
      Mode_Changes := 0;
      Cycles := 0;
   end Clear;

   procedure Take_Event (S     : EVC_Radio.Session_T;
                         Event : EVC_Ports.RTM_Event_T)
   is
      pragma Unreferenced (S, Event);
   begin
      Count (Events);
   end Take_Event;

   procedure Take_Message (S       : EVC_Radio.Session_T;
                           Verdict : out Verdict_T)
   is
      pragma Unreferenced (S);
   begin
      Count (Messages);
      Verdict := Pass;
   end Take_Message;

   procedure Take_Released (S    : out EVC_Radio.Session_T;
                            Data : out EVC_Bytes.Byte_Array;
                            Last : out Natural)
   is
   begin
      --  the stub holds nothing: an empty message (NID_MESSAGE 0,
      --  L_MESSAGE 3), which the codec rejects
      S := 1;
      Data := (others => 0);
      Data (Data'First + 2) := 192;
      Last := Data'First + 2;
      if Held_Back > 0 then
         Held_Back := Held_Back - 1;
      end if;
   end Take_Released;

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

end EVC_Sessions;
