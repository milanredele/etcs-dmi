--  ETCS DMI
--  Text message store for areas E5-E9 (8.2.3.4) including the system
--  status messages of chapter 15. Messages are kept in two groups
--  (first group: system status + important trackside messages, bold;
--  second group: auxiliary messages), each in reverse chronological
--  order, and rendered as a scrollable list of 5 lines.

package DMI_Text_Messages is

   ---------------------------------------------------------------------
   -- Limits. 8.2.3.4 sets none, the storage is static, so there are
   -- two, and both are made visible instead of failing silently.
   --
   -- Text: Max_Text characters. A longer text is cut and its last three
   -- kept characters become "...", so that it does not read as a
   -- complete message. 80 characters are at most 3 of the 5 lines of
   -- E5-E9; this matters for a message to be acknowledged, which is
   -- presented alone with the scroll buttons disabled (8.2.3.4.8 a, b)
   -- and therefore has to fit the area as a whole.
   --
   -- Store: 12 messages. When it is full a new message takes the place
   -- of the oldest message that weighs less or the same, in this order:
   --   1. the oldest second group (auxiliary) message, 8.2.3.4.7 a;
   --   2. for a new first group message or one to be acknowledged: the
   --      oldest first group message.
   -- A message that still waits for its acknowledgement (8.2.3.4.8) is
   -- never given up. So an auxiliary message is dropped when the store
   -- holds nothing but first group and unacknowledged messages, and any
   -- message is dropped when all 12 wait for an acknowledgement. No
   -- first group or acknowledgeable message is ever lost to keep an
   -- older auxiliary one.
   ---------------------------------------------------------------------

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

   -- Scrolling of the non-acknowledgeable list (8.2.3.4.7 e). The
   -- offset is brought back into the list whenever Put or Remove make
   -- the list shorter, so the area never goes blank while there are
   -- messages.
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
