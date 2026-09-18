--  ETCS DMI
--  Text message store implementation.

pragma Ada_2012;
with DMI_Ack;
with DMI_Sounds;

package body DMI_Text_Messages is

   Max_Messages : constant := 12;
   -- Approximation of the number of 12-cell proportional characters
   -- fitting a 234 cell line after the 3 cell indent and time stamp
   Wrap_Columns : constant := 36;

   type Message_T is record
      Used         : Boolean := False;
      ID           : Natural := 0;
      First_Group  : Boolean := False;
      Ack_Required : Boolean := False;
      Class        : Class_T := Plain_Text;
      Hour         : Natural := 0;
      Minute       : Natural := 0;
      Length       : Natural := 0;
      Text         : Wide_String (1 .. Max_Text);
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

   function Lines_Of (M : Message_T) return Natural is
     (if M.Length = 0 then 1 else (M.Length + Wrap_Columns - 1) / Wrap_Columns);

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
         Sequence     => Sequence,
         Ack_Waiting  => False);
      Messages (Slot).Text (1 .. Len) :=
        Text (Text'First .. Text'First + Len - 1);
      if Text'Length > Max_Text then
         -- a cut text must not read as a complete one
         Messages (Slot).Text (Max_Text - 2 .. Max_Text) := "...";
      end if;
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
            L : constant Natural := Index;
         begin
            if L <= Lines_Of (M) then
               declare
                  From : constant Natural := (L - 1) * Wrap_Columns + 1;
                  To   : constant Natural :=
                    Natural'Min (M.Length, L * Wrap_Columns);
               begin
                  if To >= From or else L = 1 then
                     Line.Length := (if To >= From then To - From + 1 else 0);
                     Line.Text (1 .. Line.Length) := M.Text (From .. To);
                     Line.Bold := M.First_Group;
                     Line.First_Line := L = 1;
                     Line.Hour := M.Hour;
                     Line.Minute := M.Minute;
                     Valid := True;
                  end if;
               end;
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
            for L in 1 .. Lines_Of (M) loop
               if Skip > 0 then
                  Skip := Skip - 1;
               elsif Wanted > 1 then
                  Wanted := Wanted - 1;
               else
                  declare
                     From : constant Natural := (L - 1) * Wrap_Columns + 1;
                     To   : constant Natural :=
                       Natural'Min (M.Length, L * Wrap_Columns);
                  begin
                     Line.Length := (if To >= From then To - From + 1 else 0);
                     Line.Text (1 .. Line.Length) := M.Text (From .. To);
                     Line.Bold := M.First_Group;
                     Line.First_Line := L = 1;
                     Line.Hour := M.Hour;
                     Line.Minute := M.Minute;
                     Valid := True;
                  end;
                  return;
               end if;
            end loop;
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
