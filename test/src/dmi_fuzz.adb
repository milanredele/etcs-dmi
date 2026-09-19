--  ETCS DMI
--  Robustness fuzzer: feeds the DMI core with pseudo random protocol
--  messages, pointer events and ticks and renders after every step.
--  Nothing the EVC or the touch screen can send may raise: the embedded
--  and WebAssembly runtimes cannot propagate exceptions, so every raise
--  there stops the display (PLAN.md §7 P0).
--
--  Three kinds of messages are generated: fields inside their documented
--  domains, the documented length with random bytes, and random length
--  with random bytes. Every exception is caught here (native runtime),
--  reported once per distinct site with the message that triggered it,
--  and the DMI is re-initialised.
--
--  Usage:  obj/dmi_fuzz [steps [seed]]      default 60000 steps, seed 1
--  Exit status 1 when anything raised.

pragma Ada_2012;
with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Streams;  use Ada.Streams;
with Ada.Text_IO;  use Ada.Text_IO;
with DMI_Core;
with DMI_Protocol; use DMI_Protocol;
with Interfaces;   use Interfaces;

procedure DMI_Fuzz is

   ---------------------------------------------------------------------
   -- Pseudo random numbers (xorshift32): reproducible from the seed
   ---------------------------------------------------------------------

   State : Unsigned_32 := 1;

   function Next return Unsigned_32 is
   begin
      State := State xor Shift_Left (State, 13);
      State := State xor Shift_Right (State, 17);
      State := State xor Shift_Left (State, 5);
      return State;
   end Next;

   -- uniform in Low .. High
   function Pick (Low, High : Natural) return Natural is
     (Low + Natural (Next mod Unsigned_32 (High - Low + 1)));

   function Chance (Percent : Natural) return Boolean is
     (Pick (1, 100) <= Percent);

   ---------------------------------------------------------------------
   -- Message under construction
   ---------------------------------------------------------------------

   Buffer : Stream_Element_Array (1 .. 512);
   Last   : Stream_Element_Offset := 0;

   procedure U8 (V : Natural) is
      Offset : Stream_Element_Offset := Last + 1;
   begin
      Put_U8 (Buffer, Offset, Unsigned_8 (V mod 256));
      Last := Offset - 1;
   end U8;

   procedure U16 (V : Natural) is
      Offset : Stream_Element_Offset := Last + 1;
   begin
      Put_U16 (Buffer, Offset, Unsigned_16 (V mod 65536));
      Last := Offset - 1;
   end U16;

   procedure U32 (V : Unsigned_32) is
      Offset : Stream_Element_Offset := Last + 1;
   begin
      Put_U32 (Buffer, Offset, V);
      Last := Offset - 1;
   end U32;

   procedure Random_Bytes (Count : Natural) is
   begin
      for I in 1 .. Count loop
         U8 (Pick (0, 255));
      end loop;
   end Random_Bytes;

   -- a value that is usually in the domain and sometimes at its edges
   function Speed return Natural is
     (case Pick (1, 10) is
         when 1      => 0,
         when 2      => 400,
         when others => Pick (0, 400));

   function Optional (Low, High, None : Natural) return Natural is
     (if Chance (40) then None else Pick (Low, High));

   ---------------------------------------------------------------------
   -- In-domain generators, one per message (see dmi_protocol.ads)
   ---------------------------------------------------------------------

   EVC_Types : constant array (1 .. 7) of Msg_Type_T :=
     (MSG_SPEED_STATE, MSG_MODE_LEVEL, MSG_TEXT, MSG_TEXT_REMOVE,
      MSG_TRACK_COND, MSG_PLANNING, MSG_STATUS);

   procedure Build_In_Domain (The_Type : Msg_Type_T) is
   begin
      Last := 0;
      if The_Type = MSG_SPEED_STATE then
         for I in 1 .. 6 loop
            U16 (Speed);
         end loop;
         U32 (Unsigned_32 (Pick (0, 90_000)));
         U8 (Pick (0, 2));
         U8 (Pick (0, 3));
         U8 (Pick (0, 7));
         U8 (Pick (0, 4));   -- status
         U8 (Pick (0, 255)); -- mrdt
      elsif The_Type = MSG_MODE_LEVEL then
         U8 (Pick (0, 17));
         U8 (Pick (0, 5));
         U8 (Optional (5, 12, 16#FF#));
         U8 (Optional (2, 5, 16#FF#));
         U8 (Pick (0, 1));
         U8 (Pick (0, 1));
         U8 (Pick (0, 1));
         U16 (Optional (0, 400, 16#FFFF#));
      elsif The_Type = MSG_TEXT then
         declare
            -- up to the greatest length, any byte, words of any width
            Length : constant Natural := Pick (0, 255);
         begin
            U16 (Pick (0, 20));
            U8 (Pick (0, 15));
            U8 (Pick (0, 23));
            U8 (Pick (0, 59));
            U8 (Length);
            for I in 1 .. Length loop
               U8 (if Pick (0, 5) = 0 then Character'Pos (' ')
                   else Pick (0, 255));
            end loop;
         end;
      elsif The_Type = MSG_TEXT_REMOVE then
         U16 (Pick (0, 20));
      elsif The_Type = MSG_TRACK_COND then
         declare
            Count : constant Natural := Pick (0, 8);
         begin
            U8 (Count);
            for I in 1 .. Count loop
               U8 (Pick (0, 255));
               U8 (Pick (1, 38));
            end loop;
         end;
      elsif The_Type = MSG_PLANNING then
         declare
            Count : Natural;
            Dist  : Natural;
         begin
            U16 (Pick (0, 65_534));
            U16 (Optional (0, 40_000, 16#FFFF#));
            U16 (Optional (0, 40_000, 16#FFFF#));
            U16 (Speed);
            Count := Pick (0, 12);
            U8 (Count);
            Dist := 0;
            for I in 1 .. Count loop
               U16 (Dist);
               U8 (Pick (0, 255));
               Dist := Natural'Min (Dist + Pick (1, 6_000), 65_000);
            end loop;
            Count := Pick (0, 14);
            U8 (Count);
            Dist := 0;
            for I in 1 .. Count loop
               Dist := Natural'Min (Dist + Pick (1, 6_000), 65_000);
               U16 (Dist);
               U16 (if Chance (10) then 16#8000# else Speed);
            end loop;
            Count := Pick (0, 16);
            U8 (Count);
            for I in 1 .. Count loop
               U8 (Pick (1, 37));
               U16 (Pick (0, 40_000));
            end loop;
         end;
      elsif The_Type = MSG_STATUS then
         U8 (Pick (0, 2));
         U8 (Pick (0, 2));
         U8 (Pick (0, 1));
         U8 (Pick (0, 1));
         U8 (Pick (0, 1));
         U8 (Pick (0, 2));
         U16 (Optional (0, 400, 16#FFFF#));
         U8 (Optional (0, 30, 16#FF#));
         U8 (Pick (1, 30));
         U8 (Pick (0, 2));
         U32 (Unsigned_32 (Pick (0, 90_000)));
         U32 (if Chance (30) then 16#FFFF_FFFF#
              else Unsigned_32 (Pick (0, 9_999_999)));
         U8 (Pick (0, 23));
         U8 (Pick (0, 59));
         U8 (Pick (0, 59));
      end if;
   end Build_In_Domain;

   function Documented_Length (The_Type : Msg_Type_T) return Natural is
     (if    The_Type = MSG_SPEED_STATE then Speed_State_Length
      elsif The_Type = MSG_MODE_LEVEL  then Mode_Level_Length
      elsif The_Type = MSG_TEXT_REMOVE then Text_Remove_Length
      elsif The_Type = MSG_STATUS      then Status_Length
      elsif The_Type = MSG_POINTER     then Pointer_Length
      else  Pick (0, 120)); -- variable length messages

   ---------------------------------------------------------------------
   -- Failure bookkeeping: one report per distinct raise site
   ---------------------------------------------------------------------

   Max_Sites : constant := 64;
   subtype Site_Text is String (1 .. 120);
   type Site_T is record
      Text  : Site_Text := (others => ' ');
      Count : Natural := 0;
   end record;
   Sites      : array (1 .. Max_Sites) of Site_T;
   Site_Count : Natural := 0;
   Raised     : Natural := 0;

   Hex : constant String := "0123456789abcdef";

   procedure Report (Where    : String;
                     E        : Ada.Exceptions.Exception_Occurrence;
                     The_Type : Msg_Type_T;
                     With_Msg : Boolean;
                     Step     : Natural) is
      Info : constant String :=
        Where & ": " & Ada.Exceptions.Exception_Name (E) & " "
        & Ada.Exceptions.Exception_Message (E);
      Key  : Site_Text := (others => ' ');
   begin
      Raised := Raised + 1;
      Key (1 .. Natural'Min (Info'Length, Key'Length)) :=
        Info (Info'First .. Info'First + Natural'Min (Info'Length, Key'Length) - 1);
      for I in 1 .. Site_Count loop
         if Sites (I).Text = Key then
            Sites (I).Count := Sites (I).Count + 1;
            return;
         end if;
      end loop;
      if Site_Count < Max_Sites then
         Site_Count := Site_Count + 1;
         Sites (Site_Count) := (Text => Key, Count => 1);
      end if;
      Put_Line ("RAISED at step" & Natural'Image (Step) & " in " & Info);
      if With_Msg then
         Put ("   last message: type" & Msg_Type_T'Image (The_Type)
              & " length" & Stream_Element_Offset'Image (Last) & " :");
         for I in 1 .. Stream_Element_Offset'Min (Last, 48) loop
            Put (' ' & Hex (Natural (Buffer (I)) / 16 + 1)
                 & Hex (Natural (Buffer (I)) mod 16 + 1));
         end loop;
         New_Line;
      end if;
   end Report;

   ---------------------------------------------------------------------

   -- After a raise the host puts the DMI into its failure presentation;
   -- that path must never raise itself. Then start over.
   procedure Contain_And_Restart (Step : Natural) is
   begin
      DMI_Core.Enter_Failure;
      DMI_Core.Render;
      DMI_Core.Initialise;
   exception
      when E : others =>
         Report ("failure presentation", E, 0, False, Step);
         DMI_Core.Initialise;
   end Contain_And_Restart;

   Steps    : Natural := 60_000;
   The_Type : Msg_Type_T := 0;
   Outbox   : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
   Out_Last : Stream_Element_Offset;

begin
   if Ada.Command_Line.Argument_Count >= 1 then
      Steps := Natural'Value (Ada.Command_Line.Argument (1));
   end if;
   if Ada.Command_Line.Argument_Count >= 2 then
      State := Unsigned_32'Value (Ada.Command_Line.Argument (2));
      if State = 0 then
         State := 1;
      end if;
   end if;

   DMI_Core.Initialise;

   for Step in 1 .. Steps loop
      -- 1. one stimulus
      declare
         Kind : constant Natural := Pick (1, 100);
      begin
         if Kind <= 45 then
            The_Type := EVC_Types (Pick (EVC_Types'First, EVC_Types'Last));
            Build_In_Domain (The_Type);
         elsif Kind <= 60 then
            -- documented length, random content
            The_Type := EVC_Types (Pick (EVC_Types'First, EVC_Types'Last));
            Last := 0;
            Random_Bytes (Documented_Length (The_Type));
         elsif Kind <= 70 then
            -- any type, any length, any content
            The_Type := Msg_Type_T (Pick (0, 255));
            Last := 0;
            Random_Bytes (Pick (0, 300));
         else
            -- touch screen: mostly on the screen, sometimes anywhere
            The_Type := MSG_POINTER;
            Last := 0;
            U8 (if Chance (95) then Pick (0, 2) else Pick (0, 255));
            if Chance (95) then
               U16 (Pick (0, 639));
               U16 (Pick (0, 479));
            else
               U16 (Pick (0, 65_535));
               U16 (Pick (0, 65_535));
            end if;
         end if;
         begin
            DMI_Core.Handle_Message (The_Type, Buffer (1 .. Last));
         exception
            when E : others =>
               Report ("Handle_Message", E, The_Type, True, Step);
               Contain_And_Restart (Step);
         end;
      end;

      -- 2. time passes; now and then long enough for the link supervision
      begin
         DMI_Core.Tick (if Chance (2) then 1_000 else Pick (0, 200));
      exception
         when E : others =>
            Report ("Tick", E, The_Type, True, Step);
            Contain_And_Restart (Step);
      end;

      -- 3. the picture
      begin
         DMI_Core.Render;
      exception
         when E : others =>
            Report ("Render", E, The_Type, True, Step);
            Contain_And_Restart (Step);
      end;

      -- 4. what the DMI wants to send
      begin
         DMI_Core.Take_Outbox (Outbox, Out_Last);
      exception
         when E : others =>
            Report ("Take_Outbox", E, The_Type, False, Step);
            Contain_And_Restart (Step);
      end;
   end loop;

   New_Line;
   for I in 1 .. Site_Count loop
      Put_Line (Natural'Image (Sites (I).Count) & " x  " & Sites (I).Text);
   end loop;
   Put_Line ("steps:" & Natural'Image (Steps) & "  raised:"
             & Natural'Image (Raised) & "  distinct sites:"
             & Natural'Image (Site_Count));
   Ada.Command_Line.Set_Exit_Status
     (if Raised = 0 then Ada.Command_Line.Success
      else Ada.Command_Line.Failure);
end DMI_Fuzz;
