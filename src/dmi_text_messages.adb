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
   end record;

   Messages : array (1 .. Max_Messages) of Message_T;
   Sequence : Natural := 0;

   Scroll_Offset : Natural := 0;

   function To_Ack_Kind (Class : Class_T) return DMI_Ack.Ack_Kind_T is
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

   function Ack_Index return Natural is
   begin
      for I in Messages'Range loop
         if Messages (I).Used and then Messages (I).Ack_Required then
            return I;
         end if;
      end loop;
      return 0;
   end Ack_Index;

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
         return; -- store full
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
         Sequence     => Sequence);
      Messages (Slot).Text (1 .. Len) :=
        Text (Text'First .. Text'First + Len - 1);

      if Ack_Required then
         -- 8.2.3.4.8 / 5.4: offered through the acknowledgement service
         DMI_Ack.Request (To_Ack_Kind (Class));
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
            DMI_Ack.Cancel (To_Ack_Kind (Messages (Slot).Class));
         end if;
         Messages (Slot).Used := False;
      end if;
   end Remove;

   function Can_Scroll_Up return Boolean is
     (Scroll_Offset > 0);

   function Can_Scroll_Down return Boolean is
     (Total_Lines > Scroll_Offset + Visible_Lines);

   procedure Scroll_Up is
   begin
      if Can_Scroll_Up then
         Scroll_Offset := Scroll_Offset - 1;
      end if;
   end Scroll_Up;

   procedure Scroll_Down is
   begin
      if Can_Scroll_Down then
         Scroll_Offset := Scroll_Offset + 1;
      end if;
   end Scroll_Down;

   function Ack_Pending return Boolean is (Ack_Index /= 0);

   function Ack_Class return Class_T is
     (Messages (Ack_Index).Class);

   function Ack_ID return Natural is
     (Messages (Ack_Index).ID);

   procedure Acknowledge is
      Slot : constant Natural := Ack_Index;
   begin
      if Slot /= 0 then
         -- 8.2.3.4.8 c: becomes a normal message, no Sinfo replay
         Messages (Slot).Ack_Required := False;
      end if;
   end Acknowledge;

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
         -- the acknowledgeable message is presented alone, unscrolled
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
