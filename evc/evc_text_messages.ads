--  ETCS on-board (EVC)
--  Text messages from the trackside (SUBSET-026 3.12.3; packets 73 and
--  74 of SUBSET-026 v4.0.0, the plain and the fixed text messages) and
--  their display on the DMI (MSG_TEXT, MSG_TEXT_REMOVE).
--
--  A message received with a balise group (Evaluate, the groups taken
--  into account in the cycle) is kept with its conditions (3.12.3.1.9):
--  the class, the text or the number of a fixed text, the start
--  condition (sub-conditions location, mode, level, 3.12.3.4.2), the end
--  condition (location, time, mode, level, 3.12.3.4.3), combined by
--  Q_TEXTDISPLAY (3.12.3.4.3.1: one of them, or all of them; the start
--  sub-conditions fulfilled at the same time, 3.12.3.4.3.1.1, the end
--  ones each once, 3.12.3.4.3.1.2; none: a start at once, an end never,
--  3.12.3.4.3.1.3 and .4) and the confirmation asked (3.12.3.4.3.2,
--  3.12.3.4.7: the acknowledgement ends the display or is a condition of
--  its end; the service or the emergency brake when the end condition is
--  fulfilled before the acknowledgement).
--
--  The end condition is evaluated as soon as the start condition is
--  fulfilled, and a message whose end is fulfilled at once is not
--  displayed (3.12.3.4.4); a message ended is not started again
--  (3.12.3.4.5). The end location is the start location plus
--  L_TEXTDISPLAY (3.12.3.4.6), the location reference of the group when
--  there is no start location. Locations are frame positions of the
--  odometer frame ("estimated" items, against the estimated front end),
--  taken when the message is received (a choice, as in EVC_Procedures).
--
--  A message displayed is sent to the DMI once (MSG_TEXT, with an id of
--  its own below 16#8000#, dmi_protocol.ads), and removed once
--  (MSG_TEXT_REMOVE). The driver's acknowledgement names the id
--  (EVC_Driver_Requests.Text_Acknowledged). A message is taken when the
--  filters of 4.8 accept text information in the level and the mode of
--  the cycle (EVC_Acceptance, Text_Message: EVC_Core says so). The
--  fixed texts (Q_TEXT, 7.5.1.136) are stored in English (3.12.3.3.1:
--  the languages the driver can select; this on-board has one).
--
--  4.10: the text messages are deleted when Stand By, Shunting, Passive
--  Shunting, Sleeping, Non Leading, National System or No Power is
--  entered; 4.12: their brake ("text message not acknowledged") is
--  revoked there too. The report of the acknowledgement to the RBC
--  (3.12.3.5, Q_TEXTREPORT) is phase E5; 3.12.3.5.3 already applies.

pragma Unevaluated_Use_Of_Old (Allow);

with EVC_Bytes;             use EVC_Bytes;
with EVC_Distances;         use EVC_Distances;
with EVC_Modes;             use EVC_Modes;
with EVC_Position;
with EVC_Driver_Requests;
with EVC_Origins;
with EVC_Radio_Info;
with Interfaces;            use Interfaces;

package EVC_Text_Messages
  with SPARK_Mode => On,
       Abstract_State => State,
       Initializes => State
is

   --  Messages kept at the same time (the DMI keeps 12)
   Max_Messages : constant := 8;

   Max_Text : constant := 255;
   subtype Text_T is Byte_Array (1 .. Max_Text);

   --  What the DMI is to be told in the cycle: a message to show (its
   --  id, flags of MSG_TEXT, its text), or the id of one to remove
   type Output_Kind_T is (Show, Remove);
   type Output_T is record
      Kind   : Output_Kind_T := Show;
      Id     : Unsigned_16 := 0;
      Flags  : Byte := 0;
      Length : Natural range 0 .. Max_Text := 0;
      Text   : Text_T := (others => 0);
   end record;

   Max_Outputs : constant := 2 * Max_Messages;

   function Output_Count return Natural
     with Global => State,
          Post => Output_Count'Result <= Max_Outputs;
   function Output (I : Positive) return Output_T
     with Global => State,
          Pre => I <= Output_Count;

   --  The brake of a message not acknowledged before its end
   --  (3.12.3.4.7, released by the acknowledgement, 3.14.1.7.5)
   function Service_Brake return Boolean
     with Global => State;
   function Emergency_Brake return Boolean
     with Global => State;

   --  Messages displayed
   function Displayed return Natural
     with Global => State;

   --  The records of the cycle for the juridical recording (EVC_Ports,
   --  event 24): byte 2 the kind, byte 3 the id mod 256, byte 4 the class
   Max_Events : constant := 8;
   type Event_T is record
      Kind, B3, B4 : Unsigned_8 := 0;
   end record;
   function Event_Count return Natural
     with Global => State,
          Post => Event_Count'Result <= Max_Events;
   function Event (I : Positive) return Event_T
     with Global => State,
          Pre => I <= Event_Count;

   Event_Displayed    : constant := 1;
   Event_Removed      : constant := 2;
   Event_Acknowledged : constant := 3;
   Event_Rejected     : constant := 4;
   Event_Brake        : constant := 5;

   ---------------------------------------------------------------------
   --  Operations
   ---------------------------------------------------------------------

   procedure Clear
     with Global => (Output => State),
          Post => Output_Count = 0 and then not Service_Brake
                  and then not Emergency_Brake;

   --  Phase E5, 3.12.3: the text messages (packets 73, 74) of the radio
   --  messages of the cycle (EVC_Radio_Info, called before the authority
   --  half empties it), referred to the LRBG of their message; stored by
   --  the next Evaluate; from the message First of the table on
   procedure Take_Radio (First : Positive := 1)
     with Global => (In_Out => State,
                     Input  => (EVC_Radio_Info.State, EVC_Origins.State));

   --  One cycle: the messages of the balise groups taken into account
   --  (when Taken: 4.8), the driver's acknowledgements, the start and
   --  end conditions in the mode and level of the cycle with the
   --  estimated front end (a frame position) and the on-board time
   procedure Evaluate (Mode        : Mode_T;
                       Level_Valid : Boolean;
                       Level       : Level_T;
                       Est_Front   : Dist_T;
                       Now_Ms      : Unsigned_64;
                       Taken       : Boolean := True)
     with Global => (In_Out => State,
                     Input  => (EVC_Position.State,
                                EVC_Driver_Requests.State));

   --  The mode machine took the transition From -> To (the end
   --  sub-condition "mode", 4.10, 4.12)
   procedure Mode_Changed (From, To : Mode_T)
     with Global => (In_Out => State);

end EVC_Text_Messages;
