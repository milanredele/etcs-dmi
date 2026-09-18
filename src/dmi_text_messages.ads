--  ETCS DMI
--  Text message store for areas E5-E9 (8.2.3.4) including the system
--  status messages of chapter 15. Messages are kept in two groups
--  (first group: system status + important trackside messages, bold;
--  second group: auxiliary messages), each in reverse chronological
--  order, and rendered as a scrollable list of 5 lines.

package DMI_Text_Messages is

   Max_Text : constant := 80;

   -- Determines the acknowledgement priority class (5.4.1.9.1)
   type Class_T is (Fixed_Text, Plain_Text, System_Status, NTC_Text);

   procedure Put (ID           : Natural;
                  First_Group  : Boolean;
                  Ack_Required : Boolean;
                  Class        : Class_T;
                  Hour, Minute : Natural;
                  Text         : Wide_String);

   procedure Remove (ID : Natural);

   -- Scrolling of the non-acknowledgeable list (8.2.3.4.7 e)
   function Can_Scroll_Up return Boolean;
   function Can_Scroll_Down return Boolean;
   procedure Scroll_Up;
   procedure Scroll_Down;

   -- Acknowledgement handling (8.2.3.4.8, 5.4.1). Every message to be
   -- acknowledged has its own request in the FIFO of DMI_Ack, identified
   -- by the message id. The message presented (alone, 8.2.3.4.8 a) is the
   -- one DMI_Ack currently offers. While any message still has to be
   -- acknowledged the other messages are not shown (5.4.1.10), also when
   -- none is on offer yet (5.4.1.9: earlier requests, the 1 s delay).

   -- A stored message still has to be acknowledged
   function Ack_Pending return Boolean;

   -- The driver acknowledged message ID: it becomes a message that does
   -- not have to be acknowledged (8.2.3.4.8 c)
   procedure Acknowledge (ID : Natural);

   -- Once per DMI cycle, before DMI_Ack.Tick: enters the requests that
   -- DMI_Ack could not take earlier (queue full), oldest message first
   procedure Tick;

   -- Rendering interface: the visible lines after wrapping + scrolling.
   -- Line_Count is the total wrapped line count of the current content.
   Visible_Lines : constant := 5;

   type Line_T is record
      Length      : Natural := 0;
      Text        : Wide_String (1 .. Max_Text);
      Bold        : Boolean := False;
      First_Line  : Boolean := False; -- carries the hh:mm time stamp
      Hour        : Natural := 0;
      Minute      : Natural := 0;
   end record;

   -- Visible line Index in 1 .. Visible_Lines; Valid False past the end
   procedure Get_Visible_Line (Index : Positive;
                               Line  : out Line_T;
                               Valid : out Boolean);

   procedure Reset;

end DMI_Text_Messages;
