--  ETCS DMI
--  Body of DMI_Test_Messages (see dmi_test_messages.ads).

with DMI_Ack;
with DMI_Driver_Data;
with DMI_Sounds;
with DMI_Test_Support;
with DMI_Text_Messages;
with DMI_Windows;
with Display.Draw;
with Display.Screen;
with General_Parameters;
with Test_Support;
use Test_Support;
use DMI_Test_Support;

package body DMI_Test_Messages is

   procedure Scenario_Text_Unknown_Glyphs is
      function W (Code : Natural) return Wide_Character is
        (Wide_Character'Val (Code));
      Wide_Line : constant Wide_String (1 .. 36) := (others => '@');
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;
      -- Latin-1 accented letters, the characters after 'z'
      Send_Text (1, "Arr" & W (16#EA#) & "t T" & W (16#FC#) & "r Stra"
                    & W (16#DF#) & "e {|}~", HH => 10, MM => 5);
      -- control characters, DEL, NBSP and 16#FF#
      Send_Text (2, "c" & W (16#00#) & W (16#01#) & W (16#0A#) & W (16#1F#)
                    & "d" & W (16#7F#) & W (16#80#) & W (16#A0#)
                    & W (16#FF#) & "e",
                 First_Group => True, Class => 2, HH => 10, MM => 6);
      Drain_Sounds;
      Step;
      Check_Frame ("text_unknown_glyphs");
      -- 36 of the widest glyph are far wider than a line: no raise (the
      -- lines themselves are checked in Scenario_Text_Wrap)
      Send_Text_Remove (1);
      Send_Text_Remove (2);
      Send_Text (3, Wide_Line, HH => 10, MM => 7);
      Drain_Sounds;
      Step;
      Check (True, "over-wide text is drawn without raising");
   end Scenario_Text_Unknown_Glyphs;

   procedure Scenario_Text_Messages is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      -- second group message: silent
      Send_Text (1, "Entering FS", HH => 10, MM => 5);
      Expect_No_Sound ("second group message is silent");
      -- first group message: Sinfo, displayed above the older one
      Send_Text (2, "Balise read error", First_Group => True,
                 Class => 2, HH => 10, MM => 6);
      Expect_Sound (DMI_Sounds.Sinfo, "first group message plays Sinfo");
      Step;
      Check_Frame ("messages_two");

      -- fill beyond five lines and scroll
      Send_Text (3, "Communication error", First_Group => True,
                 Class => 2, HH => 10, MM => 7);
      Send_Text (4, "Trackside malfunction", First_Group => True,
                 Class => 2, HH => 10, MM => 8);
      Send_Text (5, "Runaway movement", First_Group => True,
                 Class => 2, HH => 10, MM => 9);
      Send_Text (6, "No track description", First_Group => True,
                 Class => 2, HH => 10, MM => 10);
      Drain_Sounds;
      Step;
      Check_Frame ("messages_full");
      Pointer_Down (310, 440); Pointer_Up (310, 440); -- E11 scroll down
      Drain_Sounds;
      Step;
      Check_Frame ("messages_scrolled");

      -- acknowledgeable trackside message: presented alone with frame
      Send_Text (7, "Level crossing not protected", Ack_Required => True,
                 Class => 0, HH => 10, MM => 11);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "text ack offer plays Sinfo");
      Check_Frame ("message_ack");
      Pointer_Down (150, 400); -- inside E5-E9
      Expect_Sound (DMI_Sounds.Click, "text ack press clicks");
      Pointer_Up (150, 400);
      Step;
      Check_Frame ("message_acked");
      Send_Text_Remove (7);
      Send_Text_Remove (1);
      Drain_Sounds;
      Step;
      Check_Frame ("messages_removed");
   end Scenario_Text_Messages;

   ---------------------------------------------------------------------
   -- Planning area (8.3)
   ---------------------------------------------------------------------

   -- Acknowledgement FIFO (5.4.1.7, 5.4.1.9, 5.4.1.9.1, 8.2.3.4.8)

   -- Ack_Kind_T'Pos as sent with the acknowledgement (DMI_Protocol)
   ACK_LEVEL : constant := 0;
   ACK_MODE  : constant := 1;
   ACK_FIXED : constant := 2;
   ACK_PLAIN : constant := 3;
   ACK_BRAKE : constant := 5;

   procedure Ack_Reset is
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Outbox;
   end Ack_Reset;

   -- Press the acknowledgement area of this kind of request and let the
   -- DMI handle it
   procedure Ack_Tap (Kind : Natural) is
      X : constant Natural :=
        (case Kind is
            when ACK_LEVEL | ACK_MODE => 190,  -- C1
            when ACK_BRAKE            => 25,   -- C8, extended brake area
            when others               => 150); -- E5-E9
      Y : constant Natural :=
        (case Kind is
            when ACK_LEVEL | ACK_MODE => 340,
            when ACK_BRAKE            => 330,
            when others               => 400);
   begin
      Pointer_Down (X, Y);
      Pointer_Up (X, Y);
      Step;
      Drain_Sounds;
   end Ack_Tap;

   -- 5.4.1.9: nothing is offered for 1 s (20 cycles of 50 ms) after the
   -- last request went; Ack_Tap has used one cycle more
   procedure Ack_Expect_Gap (What : String) is
   begin
      for I in 1 .. 19 loop
         Step;
      end loop;
      Check (not DMI_Ack.Current_Valid, What & ": nothing offered for 1 s");
      Expect_No_Sound (What & ": silent for 1 s");
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, What & ": next offer after 1 s");
   end Ack_Expect_Gap;

   -- ROB-5: two texts of the same class are offered one after the other
   procedure Scenario_Ack_Same_Class is
   begin
      Ack_Reset;
      Send_Text (9, "Entering FS", HH => 11, MM => 0);
      Send_Text (10, "Level crossing not protected", Ack_Required => True,
                 HH => 11, MM => 1);
      Send_Text (11, "Route unsuitable - axle load category",
                 Ack_Required => True, HH => 11, MM => 2);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "first text ack offer plays Sinfo");
      Check (DMI_Ack.Pending_Count = 2, "one request per text message");
      Check_Frame ("ack_fifo_text_first");

      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 10, "first text acknowledged with its id");
      -- 5.4.1.10: the list stays hidden, the second text is not due yet
      Check_Frame ("ack_fifo_text_gap");
      Ack_Expect_Gap ("second text of the same class");
      Check_Frame ("ack_fifo_text_second");

      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 11, "second text acknowledged with its id");
      -- 8.2.3.4.8 c: both are ordinary messages now
      Check (not DMI_Text_Messages.Ack_Pending, "no text left to acknowledge");
      Check_Frame ("ack_fifo_text_done");
   end Scenario_Ack_Same_Class;

   -- GEN-1: order of arrival; 5.4.1.9.1 only for simultaneous requests
   procedure Scenario_Ack_Arrival_Order is
   begin
      Ack_Reset;
      -- three cycles: plain text, brake release, mode change
      Send_Text (20, "Level crossing not protected", Ack_Required => True);
      Step;
      Send_Status (Brake => 2, Radio => 1);
      Step;
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "only the first request is offered");
      Expect_No_Sound ("the later requests wait");

      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 20, "text arrived first");
      Ack_Expect_Gap ("brake release after the text");
      Ack_Tap (ACK_BRAKE);
      Expect_Ack (ACK_BRAKE, 0, "brake release arrived second");
      Ack_Expect_Gap ("mode change after the brake release");
      Ack_Tap (ACK_MODE);
      Expect_Ack (ACK_MODE, 0, "mode change arrived last");

      -- one cycle: brake release, fixed text, mode change and level
      -- transition are queued in the sequence of 5.4.1.9.1
      Ack_Reset;
      Send_Status (Brake => 2, Radio => 1);
      Send_Text (21, "Level crossing not protected", Ack_Required => True,
                 Class => 0);
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6,
                       Level_Ann => 2, Level_Ann_Ack => True);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "simultaneous: one offer");
      Ack_Tap (ACK_LEVEL);
      Expect_Ack (ACK_LEVEL, 0, "simultaneous: level transition first");
      Ack_Expect_Gap ("simultaneous: mode change");
      Ack_Tap (ACK_MODE);
      Expect_Ack (ACK_MODE, 0, "simultaneous: mode change second");
      Ack_Expect_Gap ("simultaneous: fixed text");
      Ack_Tap (ACK_FIXED);
      Expect_Ack (ACK_FIXED, 21, "simultaneous: fixed text third");
      Ack_Expect_Gap ("simultaneous: brake release");
      Ack_Tap (ACK_BRAKE);
      Expect_Ack (ACK_BRAKE, 0, "simultaneous: brake release last");
   end Scenario_Ack_Arrival_Order;

   -- 5.4.1.9: the 1 s also runs after a revoked request
   procedure Scenario_Ack_Revoked is
   begin
      Ack_Reset;
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6);
      Step;
      Expect_Sound (DMI_Sounds.Sinfo, "mode ack offered");
      Send_Text (30, "Level crossing not protected", Ack_Required => True);
      Step;
      Expect_No_Sound ("text waits behind the mode ack");
      -- the EVC withdraws the mode acknowledgement
      Send_Mode_Level (Mode => 2, Level => 4);
      Ack_Expect_Gap ("text after the revoked mode ack");
      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 30, "text acknowledged after the revocation");
   end Scenario_Ack_Revoked;

   -- Removing one message revokes its own request only
   procedure Scenario_Ack_Remove_One is
   begin
      Ack_Reset;
      Send_Text (40, "Level crossing not protected", Ack_Required => True);
      Step;
      Send_Text (41, "Route unsuitable - axle load category",
                 Ack_Required => True);
      Step;
      Drain_Sounds;
      -- the waiting one goes: the offered one stays offered
      Send_Text_Remove (41);
      Step;
      Check (DMI_Ack.Current_Valid and then DMI_Ack.Current_Text_ID = 40,
             "removing the waiting text keeps the offered one");
      Expect_No_Sound ("no new offer after removing the waiting text");
      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 40, "offered text still acknowledgeable");

      Ack_Reset;
      Send_Text (42, "Level crossing not protected", Ack_Required => True);
      Step;
      Send_Text (43, "Route unsuitable - axle load category",
                 Ack_Required => True);
      Step;
      Drain_Sounds;
      -- the offered one goes: the other one follows after 1 s
      Send_Text_Remove (42);
      Ack_Expect_Gap ("text after the removed text");
      Check (DMI_Ack.Current_Valid and then DMI_Ack.Current_Text_ID = 43,
             "the remaining text is offered");
      Check_Frame ("ack_fifo_text_after_removal");
      Ack_Tap (ACK_PLAIN);
      Expect_Ack (ACK_PLAIN, 43, "remaining text acknowledged");
   end Scenario_Ack_Remove_One;

   -- More requests than the queue holds: nothing raises, everything can
   -- still be acknowledged
   procedure Scenario_Ack_Queue_Full is
      type Expected_T is record
         Kind, ID : Natural;
      end record;
      -- 8 texts fill the text slots, the objects use their reserved
      -- slots, the 4 texts that did not fit follow as slots come free
      Expected : constant array (1 .. 15) of Expected_T :=
        ((ACK_PLAIN, 101), (ACK_PLAIN, 102), (ACK_PLAIN, 103),
         (ACK_PLAIN, 104), (ACK_PLAIN, 105), (ACK_PLAIN, 106),
         (ACK_PLAIN, 107), (ACK_PLAIN, 108),
         (ACK_LEVEL, 0), (ACK_MODE, 0), (ACK_BRAKE, 0),
         (ACK_PLAIN, 109), (ACK_PLAIN, 110), (ACK_PLAIN, 111),
         (ACK_PLAIN, 112));
   begin
      Ack_Reset;
      for ID in 101 .. 112 loop
         Send_Text (ID, "Level crossing not protected", Ack_Required => True);
      end loop;
      Step;
      Check (DMI_Ack.Pending_Count = DMI_Ack.Text_Capacity,
             "queue full: text requests limited to the capacity");
      Send_Status (Brake => 2, Radio => 1);
      Send_Mode_Level (Mode => 2, Level => 4, Mode_Ack => 6,
                       Level_Ann => 2, Level_Ann_Ack => True);
      Step;
      Check (DMI_Ack.Pending_Count = DMI_Ack.Text_Capacity + 3,
             "queue full: object requests are never refused");
      Drain_Sounds;

      for I in Expected'Range loop
         if I > Expected'First then
            for J in 1 .. 20 loop
               Step;
            end loop;
            Drain_Sounds;
         end if;
         Ack_Tap (Expected (I).Kind);
         Expect_Ack (Expected (I).Kind, Expected (I).ID,
                     "queue full: acknowledgement" & Natural'Image (I));
      end loop;
      Check (DMI_Ack.Pending_Count = 0
             and then not DMI_Text_Messages.Ack_Pending,
             "queue full: everything was acknowledged");
   end Scenario_Ack_Queue_Full;

   procedure Scenario_Text_Store is
      package TM renames DMI_Text_Messages;

      function Line_Text (Index : Positive) return Wide_String is
         Line  : TM.Line_T;
         Valid : Boolean;
      begin
         TM.Get_Visible_Line (Index, Line, Valid);
         return (if Valid then Line.Text (1 .. Line.Length) else "<none>");
      end Line_Text;

      function Number (N : Natural) return Wide_String is
         Img : constant Wide_String := Natural'Wide_Image (N);
      begin
         return Img (2 .. Img'Last);
      end Number;

      Steps : Natural := 0;
   begin
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);

      -- eight lines, scrolled to the end, then five messages go
      for I in 1 .. 8 loop
         Send_Text (ID => I, Text => "Auxiliary " & Number (I));
      end loop;
      for I in 1 .. 3 loop
         TM.Scroll_Down;
      end loop;
      Check (Line_Text (5) = "Auxiliary 1" and then not TM.Can_Scroll_Down,
             "list scrolled to its end");
      for I in 1 .. 5 loop
         Send_Text_Remove (I);
      end loop;
      Check (Line_Text (1) = "Auxiliary 8"
             and then Line_Text (3) = "Auxiliary 6"
             and then not TM.Can_Scroll_Up
             and then not TM.Can_Scroll_Down,
             "scroll offset follows the removals");
      Drain_Sounds;
      Step;
      Check_Frame ("messages_scroll_clamped");

      -- a first group message, one to be acknowledged and ten auxiliary
      -- ones fill the store of 12; five more auxiliary ones and a first
      -- group one arrive
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Text (ID => 100, Text => "Balise read error", First_Group => True,
                 Class => 2);
      Send_Text (ID => 101, Text => "Acknowledge me", Ack_Required => True);
      for I in 1 .. 10 loop
         Send_Text (ID => I, Text => "Auxiliary " & Number (I));
      end loop;
      for I in 11 .. 15 loop
         Send_Text (ID => I, Text => "Auxiliary " & Number (I));
      end loop;
      Send_Text (ID => 300, Text => "Runaway movement", First_Group => True,
                 Class => 2);
      Step; -- the acknowledgement request is offered on the next cycle
      Check (TM.Ack_Pending and then DMI_Ack.Current_Valid
             and then DMI_Ack.Current_Text_ID = 101,
             "the message to be acknowledged survives a full store");
      Send_Text_Remove (101);
      Check (Line_Text (1) = "Runaway movement"
             and then Line_Text (2) = "Balise read error",
             "first group messages survive and enter a full store");
      Check (Line_Text (3) = "Auxiliary 15"
             and then Line_Text (5) = "Auxiliary 13",
             "new auxiliary messages take the place of the oldest ones");
      Drain_Sounds;
      Step;
      Check_Frame ("messages_store_full");
      while TM.Can_Scroll_Down and then Steps < 100 loop
         TM.Scroll_Down;
         Steps := Steps + 1;
      end loop;
      -- 12 slots, one freed by the removal: 11 lines, the oldest kept
      -- auxiliary message is number 7
      Check (Steps = 6 and then Line_Text (5) = "Auxiliary 7",
             "the oldest auxiliary messages are the ones given up");

      -- nothing but first group messages: an auxiliary one is dropped,
      -- a first group one takes the place of the oldest
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      for I in 1 .. 12 loop
         Send_Text (ID => I, Text => "Important " & Number (I),
                    First_Group => True);
      end loop;
      Send_Text (ID => 400, Text => "Auxiliary late");
      Send_Text (ID => 401, Text => "Important late", First_Group => True);
      Steps := 0;
      while TM.Can_Scroll_Down and then Steps < 100 loop
         TM.Scroll_Down;
         Steps := Steps + 1;
      end loop;
      Check (Steps = 7 and then Line_Text (5) = "Important 2",
             "an auxiliary message never displaces a first group one");
      while TM.Can_Scroll_Up loop
         TM.Scroll_Up;
      end loop;
      Check (Line_Text (1) = "Important late",
             "a first group message displaces the oldest first group one");

      -- the protocol carries 255 characters and all are kept; a longer
      -- text (only a caller inside the DMI can pass one) is cut and
      -- says so
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      declare
         Too_Long : Wide_String (1 .. TM.Max_Text + 45);
      begin
         for I in Too_Long'Range loop
            Too_Long (I) := (if I mod 11 = 0 then ' '
                             else Wide_Character'Val (48 + I mod 10));
         end loop;
         TM.Put (ID => 1, First_Group => False, Ack_Required => False,
                 Class => TM.Plain_Text, Hour => 0, Minute => 0,
                 Text => Too_Long);
      end;
      Steps := 0;
      while TM.Can_Scroll_Down and then Steps < 1000 loop
         TM.Scroll_Down;
         Steps := Steps + 1;
      end loop;
      for I in reverse 1 .. TM.Visible_Lines loop
         declare
            Last : constant Wide_String := Line_Text (I);
         begin
            if Last /= "<none>" then
               Check (Last'Length >= 3
                      and then Last (Last'Last - 2 .. Last'Last) = "...",
                      "a cut text ends in an ellipsis");
               exit;
            end if;
         end;
      end loop;
      Drain_Sounds;
      Step;
   end Scenario_Text_Store;

   procedure Scenario_Ack_And_Windows is
      ACK_MODE_KIND  : constant := 1;
      ACK_PLAIN_KIND : constant := 3;

      function Top_Is (ID : DMI_Windows.Window_ID_T) return Boolean is
        (DMI_Windows.Is_Open
         and then DMI_Windows."=" (DMI_Windows.Top, ID));

      -- 1 s = 20 cycles of 50 ms; the cycle that set the hold was the
      -- first one
      procedure Expect_Shown_After_1_S (What : String) is
      begin
         for I in 1 .. 19 loop
            Step;
         end loop;
         Check (not DMI_Ack.Current_Valid, What & ": nothing offered for 1 s");
         Expect_No_Sound (What & ": silent for 1 s");
         Step;
         Check (DMI_Ack.Current_Valid, What & ": offered after 1 s");
         Expect_Sound (DMI_Sounds.Sinfo, What & ": the offer plays Sinfo");
      end Expect_Shown_After_1_S;
   begin
      Reset;
      Send_Mode_Level (Mode => 1, Level => 0); -- SB: Start Up, S1
      Send_Speed_State (V_Cur => 0, V_Perm => 0, V_Target => 0,
                        V_Release => 0, V_Sbi => 0, V_Wsl => 0,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Drain_Outbox;

      -- 11.7.1.8: required during Start Up, displayed 1 s after its end
      Send_Mode_Level (Mode => 1, Level => 0, Mode_Ack => 7); -- SR
      for I in 1 .. 30 loop
         Step;
      end loop;
      Check (DMI_Ack.Pending_Count = 1 and then not DMI_Ack.Current_Valid,
             "Start Up: the acknowledgement is required but not displayed");
      Expect_No_Sound ("Start Up: no Sinfo for the held acknowledgement");
      Check_Frame ("ack_held_in_startup");
      Pointer_Down (190, 340);   -- C1 is no button now
      Pointer_Up (190, 340);
      Step;
      Expect_No_Ack ("Start Up: nothing to acknowledge in C1");

      Press (385, 240);          -- Driver ID 1
      Press (487, 90);          -- Enter -> Level window
      Check (not DMI_Ack.Current_Valid, "S2: still held");
      Choose_Level;              -- Level 1 -> S10, the Main window
      Check (Top_Is (DMI_Windows.W_Main), "S10 reached");
      Drain_Outbox;
      Expect_Shown_After_1_S ("after Start Up");
      -- 11.2.1.4: no Main window button is enabled under the request
      Check_Frame ("ack_after_startup");
      Press (563, 190);          -- Train running number: disabled
      Check (Top_Is (DMI_Windows.W_Main),
             "no data entry starts while an acknowledgement is required");

      -- 8.2.3.1.4: the Ack-button of MO10 is a delay-type button
      Pointer_Down (190, 340);
      Expect_Sound (DMI_Sounds.Click, "MO10: the press clicks");
      for I in 1 .. 10 loop
         Step;
      end loop;
      Pointer_Up (190, 340);     -- released after 0.5 s
      Step;
      Expect_No_Ack ("MO10: a press shorter than 2 s is no acknowledgement");
      Check (DMI_Ack.Current_Valid, "MO10: still offered");
      Pointer_Down (190, 340);
      for I in 1 .. 40 loop
         Step;
      end loop;
      Pointer_Up (190, 340);     -- released after 2 s
      Step;
      Drain_Sounds;
      Expect_Ack (ACK_MODE_KIND, 0, "MO10: acknowledged by a 2 s press");
      Send_Mode_Level (Mode => 7, Level => 4); -- the EVC switches to SR

      -- 11.7.1.9: a request stops the data entry, the parent window is
      -- displayed and the request appears 1 s afterwards
      Check (Top_Is (DMI_Windows.W_Main), "Main window still open in SR");
      Press (563, 190);          -- Train running number (enabled again)
      Check (Top_Is (DMI_Windows.W_TRN), "TRN window open");
      Press (385, 240);          -- 1
      -- a short text: the picture does not depend on the line wrapping
      Send_Text (20, "SH refused", Ack_Required => True,
                 HH => 11, MM => 1);
      Step;
      Check (Top_Is (DMI_Windows.W_Main),
             "data entry stopped, parent window displayed");
      Check (not DMI_Driver_Data.TRN_Entered, "the stopped entry stores nothing");
      Check_Frame ("ack_stops_entry");
      Expect_Shown_After_1_S ("after the stopped data entry");
      Check_Frame ("ack_after_stopped_entry");
      Pointer_Down (150, 400);   -- E5-E9
      Pointer_Up (150, 400);
      Step;
      Drain_Sounds;
      Expect_Ack (ACK_PLAIN_KIND, 20, "text acknowledged under the Main window");

      -- ... and the validation process, together with its train data
      -- window (SR: the Train data button needs standstill only)
      Press (410, 140);          -- Train data
      Enter_Train_Data (Length => 1, Brake => 1, Speed => 5);
      Press (167, 440);                     -- entry complete? -> validation
      Check (Top_Is (DMI_Windows.W_Train_Data_Validation),
             "validation window open");
      Send_Status (Brake => 2);  -- brake release acknowledgement
      Step;
      Check (Top_Is (DMI_Windows.W_Main),
             "validation stopped, Main window displayed");
      Check (not DMI_Driver_Data.Train_Data_Entered,
             "the stopped validation validates nothing");
      Expect_Shown_After_1_S ("after the stopped validation");
      Drain_Outbox;
   end Scenario_Ack_And_Windows;
   -- SDI-1: lines of the text messages (8.2.3.4.6 c) by cell width and
   -- at word boundaries, the same lines for drawing and for scrolling
   -- (8.2.3.4.7 e), a message to be acknowledged of the greatest length
   -- (8.2.3.4.8 a, b) and texts that must not stop the DMI
   procedure Scenario_Text_Wrap is
      package TM renames DMI_Text_Messages;
      use type General_Parameters.Color;

      function W (Code : Natural) return Wide_Character is
        (Wide_Character'Val (Code));

      function Line_Text (Index : Positive) return Wide_String is
         Line  : TM.Line_T;
         Valid : Boolean;
      begin
         TM.Get_Visible_Line (Index, Line, Valid);
         return (if Valid then Line.Text (1 .. Line.Length) else "<none>");
      end Line_Text;

      function Lines_Shown return Natural is
         Line   : TM.Line_T;
         Valid  : Boolean;
         Result : Natural := 0;
      begin
         for I in 1 .. TM.Visible_Lines loop
            TM.Get_Visible_Line (I, Line, Valid);
            exit when not Valid;
            Result := Result + 1;
         end loop;
         return Result;
      end Lines_Shown;

      -- Every visible line fits the width the text has, measured with
      -- the font it is drawn with (bold for the first group)
      function Lines_Fit return Boolean is
         Line  : TM.Line_T;
         Valid : Boolean;
      begin
         for I in 1 .. TM.Visible_Lines loop
            TM.Get_Visible_Line (I, Line, Valid);
            exit when not Valid;
            if Display.Draw.String_Width
                 (Line.Text (1 .. Line.Length), TM.Text_Size,
                  Bold => Line.Bold) > TM.Line_Width
            then
               return False;
            end if;
         end loop;
         return True;
      end Lines_Fit;

      -- The list from its first to its last line, read by scrolling
      -- line by line: the lines joined by Joint, and their number.
      -- Fits is False if any line seen on the way was too wide.
      Buffer : Wide_String (1 .. 4000);
      Last   : Natural;
      Count  : Natural;
      Fits   : Boolean;

      procedure Read_List (Joint : Wide_String) is
         procedure Add (Text : Wide_String) is
         begin
            if Count > 0 then
               Buffer (Last + 1 .. Last + Joint'Length) := Joint;
               Last := Last + Joint'Length;
            end if;
            Buffer (Last + 1 .. Last + Text'Length) := Text;
            Last := Last + Text'Length;
            Count := Count + 1;
         end Add;
      begin
         Last := 0;
         Count := 0;
         while TM.Can_Scroll_Up loop
            TM.Scroll_Up;
         end loop;
         Fits := Lines_Fit;
         for I in 1 .. Lines_Shown loop
            Add (Line_Text (I));
         end loop;
         while TM.Can_Scroll_Down and then Count < 300 loop
            TM.Scroll_Down;
            Fits := Fits and then Lines_Fit;
            Add (Line_Text (TM.Visible_Lines));
         end loop;
      end Read_List;

      -- No text cell in the margin at the right edge of E5-E9 (absolute
      -- 285 .. 287), which is where an over-wide line would show first
      function Margin_Clear return Boolean is
      begin
         for Y in 365 .. 464 loop
            for X in 54 + TM.Area_Width - TM.Right_Margin
                  .. 54 + TM.Area_Width - 1
            loop
               if Display.Screen.Get_Pixel (X, Y) = General_Parameters.WHITE
               then
                  return False;
               end if;
            end loop;
         end loop;
         return True;
      end Margin_Clear;

      Long_Text : constant Wide_String :=
        "Stop at the next station and wait for the written order of the "
        & "signaller before you proceed towards the junction and report "
        & "your position";

      Long_Word : constant Wide_String :=
        "Donaudampfschifffahrtsgesellschaftskapitaenswitwe";

      -- the greatest length of the protocol and of SUBSET-026 7.5.1.53
      Max_Message : Wide_String (1 .. 255);
      Phrase : constant Wide_String :=
        "Proceed on sight to the next main signal. ";

      Scrolls : Natural := 0;
   begin
      for I in Max_Message'Range loop
         Max_Message (I) := Phrase (Phrase'First + (I - 1) mod Phrase'Length);
      end loop;
      if Max_Message (Max_Message'Last) = ' ' then
         Max_Message (Max_Message'Last) := '.';
      end if;

      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Speed_State (V_Cur => 0, V_Perm => 40, V_Target => 0,
                        V_Release => 0, V_Sbi => 55, V_Wsl => 45,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Drain_Sounds;

      -- the case of the audit: 28 characters that are wider than the
      -- area; regular and bold
      Send_Text (1, "Level crossing not protected", HH => 9, MM => 30);
      Check (Line_Text (1) = "Level crossing not"
             and then Line_Text (2) = "protected"
             and then Line_Text (3) = "<none>",
             "a message wider than the area continues on the next line");
      Send_Text (2, "Level crossing not protected", First_Group => True,
                 HH => 9, MM => 31);
      Check (Line_Text (1) = "Level crossing not"
             and then Line_Text (2) = "protected"
             and then Line_Text (3) = "Level crossing not",
             "the same in bold style");
      Drain_Sounds;
      Step;
      Check (Lines_Fit and then Margin_Clear,
             "the lines stay inside E5-E9");
      Check_Frame ("wrap_level_crossing");

      -- a long message of several words: more lines than the area has,
      -- the list scrolls through the very lines that are drawn
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Text (1, "Entering FS", HH => 9, MM => 32);
      Send_Text (2, Long_Text, HH => 9, MM => 33);
      Check (not TM.Can_Scroll_Up and then TM.Can_Scroll_Down,
             "a message of more than five lines can be scrolled");
      Drain_Sounds;
      Step;
      Check (Margin_Clear, "long message: nothing in the right margin");
      Check_Frame ("wrap_long_top");
      Read_List (Joint => " ");
      Check (Buffer (1 .. Last) = Long_Text & " Entering FS",
             "scrolling line by line shows the whole text, word by word");
      Check (Fits and then Count > TM.Visible_Lines + 1,
             "every line of the long message fits the area");
      Check (not TM.Can_Scroll_Down and then TM.Can_Scroll_Up
             and then Line_Text (TM.Visible_Lines) = "Entering FS",
             "the list ends with the last line of the last message");
      Drain_Sounds;
      Step;
      Check (Margin_Clear, "scrolled: nothing in the right margin");
      Check_Frame ("wrap_long_scrolled");
      -- ROB-8: the long message goes while the list is scrolled to its
      -- end, the offset follows the lines that are left
      Send_Text_Remove (2);
      Check (Line_Text (1) = "Entering FS"
             and then not TM.Can_Scroll_Up
             and then not TM.Can_Scroll_Down,
             "the scroll offset follows the removal of a wrapped message");
      -- the scroll buttons work on the same lines
      Send_Text (3, Long_Text, First_Group => True, HH => 9, MM => 34);
      Drain_Sounds;
      Step; -- the buttons follow the list once per cycle
      while TM.Can_Scroll_Down and then Scrolls < 300 loop
         Pointer_Down (310, 440); Pointer_Up (310, 440); -- E11
         Step;
         Scrolls := Scrolls + 1;
      end loop;
      Read_List (Joint => " ");
      Check (Scrolls = Count - TM.Visible_Lines,
             "the [Down] button scrolls one wrapped line at a time");
      Check (Fits and then Buffer (1 .. Last) = Long_Text & " Entering FS",
             "bold: the whole text, every line inside the area");

      -- a word that is wider than a line is broken, after the words
      -- that fit; nothing is lost
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Text (1, "Halt " & Long_Word, HH => 9, MM => 35);
      Check (Line_Text (1) = "Halt", "the over-long word begins a line");
      Read_List (Joint => "");
      Check (Buffer (1 .. Last) = "Halt" & Long_Word and then Fits
             and then Count >= 3,
             "an over-long word is broken into lines that fit");
      Drain_Sounds;
      Step;
      Check (Margin_Clear, "long word: nothing in the right margin");
      Check_Frame ("wrap_long_word");

      -- a message to be acknowledged of the greatest length: alone, not
      -- scrollable (8.2.3.4.8 a, b), so the fifth line says that the
      -- text goes on
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Text (1, "Entering FS", HH => 9, MM => 36);
      Send_Text (2, Max_Message, Ack_Required => True, Class => 1,
                 HH => 9, MM => 37);
      Drain_Sounds;
      Step;
      declare
         Fifth : constant Wide_String := Line_Text (TM.Visible_Lines);
      begin
         Check (Lines_Shown = TM.Visible_Lines
                and then Fifth'Length > 3
                and then Fifth (Fifth'Last - 2 .. Fifth'Last) = "...",
                "a message to be acknowledged that does not fit ends in an "
                & "ellipsis");
      end;
      Check (Line_Text (1) = "Proceed on sight to the next" and then Lines_Fit,
             "its lines are wrapped like any other");
      Check (Margin_Clear, "ack message: nothing in the right margin");
      Check_Frame ("wrap_ack_max");
      Pointer_Down (310, 440); Pointer_Up (310, 440); -- E11 is disabled
      Step;
      Check (Line_Text (1) = "Proceed on sight to the next",
             "a message to be acknowledged cannot be scrolled");
      Pointer_Down (150, 400); Pointer_Up (150, 400); -- acknowledge
      Drain_Sounds;
      Step;
      Check (not TM.Ack_Pending and then TM.Can_Scroll_Down,
             "once acknowledged the message can be scrolled");
      Read_List (Joint => " ");
      Check (Buffer (1 .. Last) = Max_Message & " Entering FS" and then Fits,
             "all 255 characters are kept and can be read");
      while TM.Can_Scroll_Up loop
         TM.Scroll_Up;
      end loop;
      Drain_Sounds;
      Step;
      Check_Frame ("wrap_ack_max_acked");

      -- texts that must not stop the DMI, as messages and as messages
      -- to be acknowledged: empty, spaces only, one word of the widest
      -- glyph, one of characters without a glyph, spaces around a word
      for Ack in Boolean loop
         Reset;
         Send_Mode_Level (Mode => 2, Level => 4);
         Send_Text (1, "", Ack_Required => Ack);
         Step;
         Check (Lines_Shown = 1 and then Line_Text (1) = "",
                "an empty text is one empty line");
         Send_Text (1, (1 .. 255 => ' '), Ack_Required => Ack);
         Step;
         Check (Lines_Shown = 1 and then Line_Text (1) = "",
                "a text of spaces is one empty line");
         Send_Text (1, (1 .. 255 => '@'), Ack_Required => Ack);
         Step;
         Check (Lines_Shown = TM.Visible_Lines and then Lines_Fit
                and then Margin_Clear,
                "255 of the widest glyph are broken into lines that fit");
         Send_Text (1, (1 .. 255 => W (16#FF#)), Ack_Required => Ack);
         Step;
         Check (Lines_Shown = TM.Visible_Lines and then Lines_Fit
                and then Margin_Clear,
                "255 accented letters are broken the same way");
         -- 16#7F# is a C1 control: no font has a glyph for it, so every
         -- one of them is a replacement box (ROB-2)
         Send_Text (1, (1 .. 255 => W (16#7F#)), Ack_Required => Ack);
         Step;
         Check (Lines_Shown = TM.Visible_Lines and then Lines_Fit
                and then Margin_Clear,
                "255 characters without a glyph are broken the same way");
         Send_Text (1, (1 .. 120 => ' ') & "word" & (1 .. 120 => ' '),
                    Ack_Required => Ack);
         Step;
         Check (Lines_Shown = 1 and then Line_Text (1) = "word",
                "spaces around a word make no lines");
         Send_Text (1, "a  b" & (1 .. 60 => ' ') & "c", Ack_Required => Ack);
         Step;
         Check (Line_Text (1) = "a  b" and then Line_Text (2) = "c"
                and then Lines_Shown = 2,
                "the spaces at a line break are not shown");
      end loop;
      Drain_Sounds;
   end Scenario_Text_Wrap;

   ---------------------------------------------------------------------
   -- Data view window (11.5.1 with Table 45, laid out per 10.5.1): the
   -- items and their order, the two windows with [Previous] / [Next]
   -- (5.3.1.1.6 d/e, 5.3.1.2.1 g), a data part only for a valid value
   -- (10.5.1.4) and the grouping of long data (5.1.5)
   ---------------------------------------------------------------------


end DMI_Test_Messages;
