--  ETCS DMI
--  Text message store for areas E5-E9 (8.2.3.4) including the system
--  status messages of chapter 15. Messages are kept in two groups
--  (first group: system status + important trackside messages, bold;
--  second group: auxiliary messages), each in reverse chronological
--  order, and rendered as a scrollable list of 5 lines.

with Font;

package DMI_Text_Messages is

   ---------------------------------------------------------------------
   -- Limits. 8.2.3.4 sets none for the store and the storage is static,
   -- so the limit is made visible instead of failing silently.
   --
   -- Text: Max_Text characters, the longest text the trackside can send
   -- (SUBSET-026 7.5.1.53, L_TEXT = 0 .. 255) and the longest the
   -- protocol carries (length u8), so no text of the EVC is ever cut.
   -- The characters are ISO 8859-1 (SUBSET-026 7.5.1.174, X_TEXT) and are
   -- stored as such, one byte each: 12 x 255 = 3060 bytes of text. A
   -- character above 16#FF# cannot come from the EVC; Put stores it as
   -- one the fonts have no glyph for (drawn as a box). A longer text, as
   -- only a caller inside the DMI can pass, is cut and its last three
   -- kept characters become "...", so that it does not read as a
   -- complete message.
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

   Max_Text : constant := 255;

   -- Determines the acknowledgement priority class (5.4.1.9.1)
   type Class_T is (Fixed_Text, Plain_Text, System_Status, NTC_Text);

   procedure Put (ID           : Natural;
                  First_Group  : Boolean;
                  Ack_Required : Boolean;
                  Class        : Class_T;
                  Hour, Minute : Natural;
                  Text         : Wide_String);

   procedure Remove (ID : Natural);

   -- The store holds message ID
   function Holds (ID : Natural) return Boolean;

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

   ---------------------------------------------------------------------
   -- Lines (8.2.3.4.6 c). A message that does not fit one of the areas
   -- E5 .. E9 continues in the next one. Figure 62 breaks between words
   -- ("Unauthorised passing of" / "EOA / LOA"), so:
   --   * a line takes as many whole words as fit Line_Width cells,
   --     measured with the glyphs that are drawn (a character without a
   --     glyph counts as its replacement box);
   --   * the spaces at a break are not shown: no line begins or ends
   --     with a space (also the first one);
   --   * a word wider than a whole line is broken where the line is full
   --     (spec silent, choice); only spaces separate words;
   --   * a line never takes more than Max_Line characters, whatever the
   --     font says, so that a line always fits Line_T;
   --   * a text that is empty or holds spaces only is one empty line
   --     (the time stamp is still shown).
   -- Scrolling (8.2.3.4.7 e) and the visible lines count the same lines.
   --
   -- Layout of a line, in cells from the left edge of E5 .. E9 (234
   -- wide): the time stamp after the indent of 5.1.3.2, the text 10 cells
   -- behind the stamp (8.2.3.4.6 b) and, a choice the specification does
   -- not make, the same indent of 3 cells kept free at the right edge.
   -- That keeps the text clear of the 2 cell yellow frame of 5.4.1.5.
   ---------------------------------------------------------------------

   Area_Width   : constant := 234;
   Time_Indent  : constant := 3;
   -- "hh:mm" in size 10 (5.1.2.2.3 f): four digits of 7 cells and the
   -- ':' of 3, as Font.FreeSans_10 advances them
   Stamp_Width  : constant := 7 + 7 + 3 + 7 + 7;
   Text_Indent  : constant := Time_Indent + Stamp_Width + 10;
   Right_Margin : constant := 3;
   Line_Width   : constant := Area_Width - Text_Indent - Right_Margin;

   -- 5.1.2.2.3: character height of the text messages
   Text_Size : constant Font.Size_T := 12;

   -- The bold style of the first group (8.2.3.4.7 c) is drawn as a
   -- double strike, one cell wider than the regular text
   Bold_Extra : constant := 1;

   Max_Line : constant := 64;

   -- Rendering interface: the visible lines after wrapping + scrolling.
   Visible_Lines : constant := 5;

   -- A message to be acknowledged is presented alone and cannot be
   -- scrolled (8.2.3.4.8 a, b: E10 and E11 show NA15 and NA16), and the
   -- specification does not say what happens to one of more than
   -- Visible_Lines lines. Choice: its first lines are shown and the last
   -- visible one ends in "..." (hence the 3 extra characters of a line);
   -- once acknowledged it is an ordinary message (8.2.3.4.8 c) and can
   -- be read as a whole by scrolling.
   type Line_T is record
      Length      : Natural := 0;
      Text        : Wide_String (1 .. Max_Line + 3);
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
