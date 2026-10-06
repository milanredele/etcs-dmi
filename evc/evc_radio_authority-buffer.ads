--  ETCS on-board (EVC)
--  Phase E5, the authority by radio half: the state of the acceptance of
--  radio information (4.8, the tables in EVC_Radio_Acceptance): the
--  context of the tables and the transition buffer of 4.8.5. Part of
--  EVC_Radio_Authority.State.

pragma Unevaluated_Use_Of_Old (Allow);
with ETCS_Message_Catalogue;
with EVC_Bytes;
with EVC_Ports;
with EVC_Radio;
with EVC_Radio_Acceptance; use EVC_Radio_Acceptance;

private package EVC_Radio_Authority.Buffer
  with SPARK_Mode => On,
       Abstract_State => (State with Part_Of => EVC_Radio_Authority.State)
is

   ---------------------------------------------------------------------
   --  The state: the context of the last cycle, the transition buffer
   ---------------------------------------------------------------------

   --  4.8.5.1: three sets of information (messages)
   Buffer_Size : constant := EVC_Radio_Authority.Buffer_Size;
   subtype Buffered_T is Natural range 0 .. Buffer_Size;

   --  The context as of the last EVC_Radio_Authority.Evaluate (the mode
   --  as of the last change of mode): the messages of a cycle are judged
   --  before its levels and modes (EVC_Core.Tick, step 1)
   function Context return Context_T
     with Global => State;

   --  4.8 for the last message received, of kind K
   function Judge (K : ETCS_Message_Catalogue.Message_Kind_T)
     return Verdict_T is (Verdict (Info_Of (K), Context))
     with Global => State;

   --  The messages in the transition buffer, and whether they are being
   --  released (4.8.5.5)
   function Buffered return Buffered_T
     with Global => State;
   function Has_Released return Boolean
     with Global => State;

   --  Power-up: the context of NP, the buffer empty
   procedure Clear
     with Global => (Output => State),
          Post => Buffered = 0 and then not Has_Released;

   --  5. The context of the cycle; 4.8.5.4 a), c): the buffer deleted
   --  when no level 2 transition is announced any more and the level is
   --  not 2, a message of a session no longer established deleted;
   --  4.8.5.5: the level is 2, the buffer released (in the order of
   --  reception, EVC_Core.Read_Released_Messages of the next cycle)
   procedure Update (C : Context_T)
     with Global => (In_Out => State, Input => EVC_Radio.State),
          Post => Context = C;

   --  4.8.5.5 (e5/levels): the level became 2 in this cycle: the buffer
   --  released at once, the context of the judgement in level 2
   procedure Release_At_Transition
     with Global => (In_Out => State),
          Post => Buffered = Buffered'Old
                  and then Has_Released = (Buffered > 0)
                  and then Context.Level_Valid
                  and then Context.Level = L2;

   --  1. 4.8.5.1, 4.8.5.3: the message Data received on the session S,
   --  judged Stored, kept; the oldest one replaced when the buffer is full
   procedure Store (S : EVC_Radio.Session_T; Data : EVC_Bytes.Byte_Array)
     with Global => (In_Out => State),
          Pre  => EVC_Ports.Valid_RTM (Data),
          Post => Buffered >= 1;

   --  1d. The oldest message released, into Data (Data'First .. Last),
   --  with its session; out of the buffer
   procedure Take_Released (S    : out EVC_Radio.Session_T;
                            Data : in out EVC_Bytes.Byte_Array;
                            Last : out Natural)
     with Global => (In_Out => State),
          Pre  => Has_Released
                  and then Data'Length >= EVC_Ports.RTM_Max_Length
                  and then Data'Last < Positive'Last,
          Post => Last in Data'Range
                  and then EVC_Ports.Valid_RTM (Data (Data'First .. Last))
                  and then Buffered < Buffered'Old;

end EVC_Radio_Authority.Buffer;
