--  ETCS DMI
--  Text message store implementation.

pragma Ada_2012;
with Display.Draw;
with DMI_Ack;
with DMI_Sounds;

package body DMI_Text_Messages is

   Max_Messages : constant := 12;

   -- Stands for a character that is not ISO 8859-1: no font has a glyph
   -- for it, so it is drawn as the replacement box
   No_Glyph : constant Character := Character'Val (16#7F#);

   Ellipsis : constant Wide_String := "...";

   type Message_T is record
      Used         : Boolean := False;
      ID           : Natural := 0;
      First_Group  : Boolean := False;
      Ack_Required : Boolean := False;
      Class        : Class_T := Plain_Text;
      Hour         : Natural := 0;
      Minute       : Natural := 0;
      Length       : Natural := 0;
      Text         : String (1 .. Max_Text); -- ISO 8859-1
      Lines        : Positive := 1; -- Count_Lines, kept by Put
      Sequence     : Natural := 0; -- arrival order
      -- Ack_Required only: DMI_Ack was full and has not taken the
      -- request of this message yet (see Tick)
      Ack_Waiting  : Boolean := False;
   end record;

   Messages : array (1 .. Max_Messages) of Message_T;
   Sequence : Natural := 0;

   Scroll_Offset : Natural := 0;

   function To_Ack_Kind (Class : Class_T) return DMI_Ack.Text_Kind_T is
     (case Class is
         when Fixed_Text    => DMI_Ack.Fixed_Text,
         when Plain_Text    => DMI_Ack.Plain_Text,
         when System_Status => DMI_Ack.System_Status,
         when NTC_Text      => DMI_Ack.NTC_Text);

   function Find (ID : Natural) return Natural is
   begin
      for I in Messages'Range loop
         if Messages (I).Used and then Messages (I).ID = ID then
            return I;
         end if;
      end loop;
      return 0;
   end Find;

   -- The message presented for acknowledgement: the one the
   -- acknowledgement service is offering (5.4.1.7), 0 if none
   function Ack_Index return Natural is
      Slot : Natural;
   begin
      if DMI_Ack.Current_Valid
        and then DMI_Ack.Current_Kind in DMI_Ack.Text_Kind_T
      then
         Slot := Find (DMI_Ack.Current_Text_ID);
         if Slot /= 0 and then Messages (Slot).Ack_Required then
            return Slot;
         end if;
      end if;
      return 0;
   end Ack_Index;

   -- 8.2.3.4.8 / 5.4.1.9: every message has its own request
   procedure Request_Ack (Slot : Positive) is
      Accepted : Boolean;
   begin
      DMI_Ack.Request_Text_Ack
        (To_Ack_Kind (Messages (Slot).Class), Messages (Slot).ID, Accepted);
      Messages (Slot).Ack_Waiting := not Accepted;
   end Request_Ack;

   ---------------------------------------------------------------------
   -- Wrapped line model of the non-ack list (or the single ack message)
   ---------------------------------------------------------------------

   -- 8.2.3.4.6 c, the rules are in the specification of this package.
   -- Everything here is total: any byte string gives at least one line,
   -- every line but an empty only one takes at least one character, and
   -- no index leaves 1 .. M.Length.

   function To_Wide (C : Character) return Wide_Character is
     (Wide_Character'Val (Character'Pos (C)));

   -- Cells the character takes when drawn, a replacement box included
   function Cells (C : Character) return Natural is
     (Display.Draw.String_Width ((1 => To_Wide (C)), Text_Size));

   function Limit (M : Message_T) return Natural is
     (if M.First_Group then Line_Width - Bold_Extra else Line_Width);

   -- First character that is not a space from From on, or M.Length + 1
   function Skip_Spaces (M : Message_T; From : Positive) return Positive is
      I : Positive := From;
   begin
      while I <= M.Length and then M.Text (I) = ' ' loop
         I := I + 1;
      end loop;
      return I;
   end Skip_Spaces;

   -- The line that begins at From, which is in 1 .. M.Length and not a
   -- space: it ends at To >= From, the next one begins at Next, or
   -- there is none if Next > M.Length
   procedure Next_Line (M    : Message_T;
                        From : Positive;
                        To   : out Positive;
                        Next : out Positive)
   is
      Width      : Natural := 0;
      Last_Space : Natural := 0; -- last space of this line so far
      I          : Positive := From;
   begin
      loop
         if I > M.Length then
            To := M.Length;
            Next := I;
            exit;
         end if;
         if I - From >= Max_Line
           or else Width + Cells (M.Text (I)) > Limit (M)
         then
            -- the line is full before character I
            if M.Text (I) = ' ' then
               To := I - 1;
               Next := I;
            elsif Last_Space /= 0 then
               To := Last_Space - 1;
               Next := Last_Space + 1;
            elsif I > From then
               To := I - 1; -- a word wider than the line is broken
               Next := I;
            else
               To := I; -- not even one character fits: it is clipped
               Next := I + 1;
            end if;
            exit;
         end if;
         if M.Text (I) = ' ' then
            Last_Space := I;
         end if;
         Width := Width + Cells (M.Text (I));
         I := I + 1;
      end loop;
      -- To >= From here: M.Text (From) is not a space, so Last_Space is
      -- behind From when set. No line ends with a space.
      while To > From and then M.Text (To) = ' ' loop
         To := To - 1;
      end loop;
      Next := Skip_Spaces (M, Next);
   end Next_Line;

   function Count_Lines (M : Message_T) return Positive is
      From   : Positive := Skip_Spaces (M, 1);
      To     : Positive;
      Result : Natural := 0;
   begin
      while From <= M.Length loop
         Next_Line (M, From, To, From);
         Result := Result + 1;
      end loop;
      return Natural'Max (Result, 1);
   end Count_Lines;

   function Lines_Of (M : Message_T) return Positive is (M.Lines);

   -- Line L of M, which is in 1 .. Lines_Of (M). Cut: the line is the
   -- last one that can be shown; if M goes on it ends in "...".
   procedure Get_Line (M    : Message_T;
                       L    : Positive;
                       Cut  : Boolean;
                       Line : out Line_T)
   is
      From  : Positive := Skip_Spaces (M, 1);
      To    : Natural := 0;
      Next  : Positive := From;
      Width : Natural := 0;
   begin
      Line := (Length     => 0,
               Text       => (others => ' '),
               Bold       => M.First_Group,
               First_Line => L = 1,
               Hour       => M.Hour,
               Minute     => M.Minute);
      if From > M.Length then
         return; -- the one empty line of an empty text
      end if;
      for K in 1 .. L loop
         exit when Next > M.Length; -- cannot happen for L <= Lines_Of (M)
         From := Next;
         Next_Line (M, From, To, Next);
      end loop;
      -- Next_Line gives at most Max_Line characters
      for I in From .. Natural'Min (To, From + Max_Line - 1) loop
         Line.Length := Line.Length + 1;
         Line.Text (Line.Length) := To_Wide (M.Text (I));
         Width := Width + Cells (M.Text (I));
      end loop;
      if Cut and then Next <= M.Length then
         -- room for the ellipsis, which does not follow a space
         while Line.Length > 0
           and then (Width + Display.Draw.String_Width (Ellipsis, Text_Size)
                       > Limit (M)
                     or else Line.Text (Line.Length) = ' ')
         loop
            Width := Width - Display.Draw.String_Width
              (Line.Text (Line.Length .. Line.Length), Text_Size);
            Line.Length := Line.Length - 1;
         end loop;
         Line.Text (Line.Length + 1 .. Line.Length + Ellipsis'Length) :=
           Ellipsis;
         Line.Length := Line.Length + Ellipsis'Length;
      end if;
   end Get_Line;

   type TC_Order is array (1 .. Max_Messages) of Natural;

   -- Ordering per 8.2.3.4.7: first group above second group, newest on
   -- top within a group. Returns the message indices in display order.
   procedure Display_Order (Order : out TC_Order; Count : out Natural) is
      procedure Add_Group (First_Group : Boolean) is
         Best : Natural;
      begin
         -- insertion by descending sequence number
         loop
            Best := 0;
            for I in Messages'Range loop
               if Messages (I).Used
                 and then Messages (I).First_Group = First_Group
               then
                  declare
                     Already : Boolean := False;
                  begin
                     for J in 1 .. Count loop
                        if Order (J) = I then
                           Already := True;
                        end if;
                     end loop;
                     if not Already
                       and then (Best = 0
                                 or else Messages (I).Sequence >
                                         Messages (Best).Sequence)
                     then
                        Best := I;
                     end if;
                  end;
               end if;
            end loop;
            exit when Best = 0;
            Count := Count + 1;
            Order (Count) := Best;
         end loop;
      end Add_Group;
   begin
      Count := 0;
      Add_Group (True);
      Add_Group (False);
   end Display_Order;

   function Total_Lines return Natural is
      Order : TC_Order;
      Count : Natural;
      Result : Natural := 0;
   begin
      Display_Order (Order, Count);
      for I in 1 .. Count loop
         Result := Result + Lines_Of (Messages (Order (I)));
      end loop;
      return Result;
   end Total_Lines;

   ---------------------------------------------------------------------

   -- 8.2.3.4.7 e: the list scrolls line by line and not around, so the
   -- offset must stay within the list. It is checked again whenever the
   -- list may have become shorter; otherwise a removal while scrolled
   -- down leaves lines, or the whole area, blank although there are
   -- messages to show.
   procedure Clamp_Scroll is
      Total : constant Natural := Total_Lines;
      Max_Offset : constant Natural :=
        (if Total > Visible_Lines then Total - Visible_Lines else 0);
   begin
      if Scroll_Offset > Max_Offset then
         Scroll_Offset := Max_Offset;
      end if;
   end Clamp_Scroll;

   -- Store full (the policy is described in the specification): the
   -- slot of the oldest message that may be given up for a new one of
   -- this kind, or 0
   function Victim (First_Group, Ack_Required : Boolean) return Natural is
      function Oldest (In_First_Group : Boolean) return Natural is
         Best : Natural := 0;
      begin
         for I in Messages'Range loop
            if Messages (I).Used
              and then not Messages (I).Ack_Required
              and then Messages (I).First_Group = In_First_Group
              and then (Best = 0
                        or else Messages (I).Sequence <
                                Messages (Best).Sequence)
            then
               Best := I;
            end if;
         end loop;
         return Best;
      end Oldest;

      Slot : Natural := Oldest (In_First_Group => False);
   begin
      if Slot = 0 and then (First_Group or else Ack_Required) then
         Slot := Oldest (In_First_Group => True);
      end if;
      return Slot;
   end Victim;

   procedure Put (ID           : Natural;
                  First_Group  : Boolean;
                  Ack_Required : Boolean;
                  Class        : Class_T;
                  Hour, Minute : Natural;
                  Text         : Wide_String)
   is
      Slot : Natural := Find (ID);
      Len  : constant Natural := Natural'Min (Text'Length, Max_Text);
   begin
      if Slot = 0 then
         for I in Messages'Range loop
            if not Messages (I).Used then
               Slot := I;
               exit;
            end if;
         end loop;
      end if;
      if Slot = 0 then
         Slot := Victim (First_Group, Ack_Required);
      end if;
      if Slot = 0 then
         return; -- nothing in the store may be given up for this one
      end if;

      if Messages (Slot).Used
        and then Messages (Slot).Ack_Required
        and then not (Ack_Required and then Messages (Slot).Class = Class)
      then
         -- the message is replaced by one that needs no acknowledgement
         -- or another kind of it: the old request is revoked
         DMI_Ack.Cancel_Text (ID);
      end if;

      Sequence := Sequence + 1;
      Messages (Slot) :=
        (Used         => True,
         ID           => ID,
         First_Group  => First_Group,
         Ack_Required => Ack_Required,
         Class        => Class,
         Hour         => Hour,
         Minute       => Minute,
         Length       => Len,
         Text         => (others => ' '),
         Lines        => 1,
         Sequence     => Sequence,
         Ack_Waiting  => False);
      for I in 1 .. Len loop
         declare
            C : constant Wide_Character := Text (Text'First + (I - 1));
         begin
            Messages (Slot).Text (I) :=
              (if Wide_Character'Pos (C) <= 16#FF#
               then Character'Val (Wide_Character'Pos (C))
               else No_Glyph);
         end;
      end loop;
      if Text'Length > Max_Text then
         -- a cut text must not read as a complete one
         Messages (Slot).Text (Max_Text - 2 .. Max_Text) := "...";
      end if;
      -- 8.2.3.4.6 c: the one line count behind scrolling and drawing
      Messages (Slot).Lines := Count_Lines (Messages (Slot));
      Clamp_Scroll;

      if Ack_Required then
         -- 8.2.3.4.8 / 5.4: offered through the acknowledgement service
         Request_Ack (Slot);
      elsif First_Group then
         -- 8.2.3.4.7 h: Sinfo for a new first group message
         DMI_Sounds.Play (DMI_Sounds.Sinfo);
      end if;
   end Put;

   procedure Remove (ID : Natural) is
      Slot : constant Natural := Find (ID);
   begin
      if Slot /= 0 then
         if Messages (Slot).Ack_Required then
            -- only the request of this message is revoked
            DMI_Ack.Cancel_Text (ID);
         end if;
         Messages (Slot).Used := False;
         Clamp_Scroll;
      end if;
   end Remove;

   function Can_Scroll_Up return Boolean is
     (Scroll_Offset > 0);

   function Can_Scroll_Down return Boolean is
     (Total_Lines > Scroll_Offset + Visible_Lines);

   procedure Scroll_Up is
   begin
      Clamp_Scroll;
      if Can_Scroll_Up then
         Scroll_Offset := Scroll_Offset - 1;
      end if;
   end Scroll_Up;

   procedure Scroll_Down is
   begin
      Clamp_Scroll;
      if Can_Scroll_Down then
         Scroll_Offset := Scroll_Offset + 1;
      end if;
   end Scroll_Down;

   function Ack_Pending return Boolean is
   begin
      for M of Messages loop
         if M.Used and then M.Ack_Required then
            return True;
         end if;
      end loop;
      return False;
   end Ack_Pending;

   procedure Acknowledge (ID : Natural) is
      Slot : constant Natural := Find (ID);
   begin
      if Slot /= 0 then
         -- 8.2.3.4.8 c: becomes a normal message, no Sinfo replay
         Messages (Slot).Ack_Required := False;
         Messages (Slot).Ack_Waiting := False;
      end if;
   end Acknowledge;

   procedure Tick is
      Best : Natural;
   begin
      loop
         Best := 0;
         for I in Messages'Range loop
            if Messages (I).Used
              and then Messages (I).Ack_Required
              and then Messages (I).Ack_Waiting
              and then (Best = 0
                        or else Messages (I).Sequence <
                                Messages (Best).Sequence)
            then
               Best := I;
            end if;
         end loop;
         exit when Best = 0;
         Request_Ack (Best);
         exit when Messages (Best).Ack_Waiting; -- still no room
      end loop;
   end Tick;

   procedure Get_Visible_Line (Index : Positive;
                               Line  : out Line_T;
                               Valid : out Boolean)
   is
      Order : TC_Order;
      Count : Natural;
      Skip  : Natural;
      Wanted : Natural;
   begin
      Line := (others => <>);
      Valid := False;

      if Ack_Pending then
         -- 8.2.3.4.8 a: the message on offer is presented alone,
         -- unscrolled. 5.4.1.10: nothing else is shown while a message
         -- to be acknowledged waits for its turn (5.4.1.9).
         if Ack_Index = 0 then
            return;
         end if;
         declare
            M : Message_T renames Messages (Ack_Index);
         begin
            if Index <= Natural'Min (Lines_Of (M), Visible_Lines) then
               -- it cannot be scrolled (8.2.3.4.8 b): what does not fit
               -- is announced by an ellipsis, see Line_T
               Get_Line (M, Index, Cut => Index = Visible_Lines, Line => Line);
               Valid := True;
            end if;
         end;
         return;
      end if;

      Display_Order (Order, Count);
      Skip := Scroll_Offset;
      Wanted := Index;
      for I in 1 .. Count loop
         declare
            M : Message_T renames Messages (Order (I));
         begin
            if Skip >= Lines_Of (M) then
               Skip := Skip - Lines_Of (M);
            elsif Wanted > Lines_Of (M) - Skip then
               Wanted := Wanted - (Lines_Of (M) - Skip);
               Skip := 0;
            else
               Get_Line (M, Skip + Wanted, Cut => False, Line => Line);
               Valid := True;
               return;
            end if;
         end;
      end loop;
   end Get_Visible_Line;

   procedure Reset is
   begin
      for M of Messages loop
         M.Used := False;
      end loop;
      Sequence := 0;
      Scroll_Offset := 0;
   end Reset;

end DMI_Text_Messages;
