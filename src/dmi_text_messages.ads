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

   -- Acknowledgement handling (8.2.3.4.8): while a message requires an
   -- acknowledgement it is presented alone
   function Ack_Pending return Boolean;
   function Ack_Class return Class_T;
   function Ack_ID return Natural;
   procedure Acknowledge;

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
