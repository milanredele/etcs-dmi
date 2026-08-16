--  ETCS DMI
--  Regression support implementation.

pragma Ada_2012;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Streams; use Ada.Streams;
with Ada.Text_IO; use Ada.Text_IO;
with Display.Screen;
with DMI_Core;
with DMI_Protocol; use DMI_Protocol;
with Interfaces; use Interfaces;

package body Test_Support is

   Failures : Natural := 0;
   Checks   : Natural := 0;

   Golden_Dir : constant String := "test/golden/";

   function Updating return Boolean is
     (Ada.Environment_Variables.Exists ("UPDATE"));

   procedure Fail (What : String) is
   begin
      Failures := Failures + 1;
      Put_Line ("FAIL: " & What);
   end Fail;

   procedure Pass (What : String) is
   begin
      if Ada.Environment_Variables.Exists ("VERBOSE") then
         Put_Line ("pass: " & What);
      end if;
   end Pass;

   procedure Send_Speed_State
     (V_Cur, V_Perm, V_Target, V_Release, V_Sbi, V_Wsl : Natural;
      D_Target        : Natural;
      Monitoring      : Natural;
      Dial_Range      : Natural;
      Vrelease_Exists : Boolean;
      CSM_Target_Info : Boolean := False;
      Brake_Commanded : Boolean := False)
   is
      Payload : Stream_Element_Array (1 .. Speed_State_Length);
      Offset  : Stream_Element_Offset := Payload'First;
      Flags   : Unsigned_8 := 0;
   begin
      if Vrelease_Exists then
         Flags := Flags or 1;
      end if;
      if CSM_Target_Info then
         Flags := Flags or 2;
      end if;
      if Brake_Commanded then
         Flags := Flags or 4;
      end if;
      Put_U16 (Payload, Offset, Unsigned_16 (V_Cur));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Perm));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Target));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Release));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Sbi));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Wsl));
      Put_U32 (Payload, Offset, Unsigned_32 (D_Target));
      Put_U8 (Payload, Offset, Unsigned_8 (Monitoring));
      Put_U8 (Payload, Offset, Unsigned_8 (Dial_Range));
      Put_U8 (Payload, Offset, Flags);
      DMI_Core.Handle_Message (MSG_SPEED_STATE, Payload);
   end Send_Speed_State;

   procedure Send_Mode_Level
     (Mode          : Natural;
      Level         : Natural;
      Mode_Ack      : Natural := 16#FF#;
      Level_Ann     : Natural := 16#FF#;
      Level_Ann_Ack : Boolean := False;
      Override      : Boolean := False;
      TAF           : Boolean := False;
      LSSMA         : Natural := 16#FFFF#)
   is
      Payload : Stream_Element_Array (1 .. Mode_Level_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Mode));
      Put_U8 (Payload, Offset, Unsigned_8 (Level));
      Put_U8 (Payload, Offset, Unsigned_8 (Mode_Ack));
      Put_U8 (Payload, Offset, Unsigned_8 (Level_Ann));
      Put_U8 (Payload, Offset, (if Level_Ann_Ack then 1 else 0));
      Put_U8 (Payload, Offset, (if Override then 1 else 0));
      Put_U8 (Payload, Offset, (if TAF then 1 else 0));
      Put_U16 (Payload, Offset, Unsigned_16 (LSSMA));
      DMI_Core.Handle_Message (MSG_MODE_LEVEL, Payload);
   end Send_Mode_Level;

   procedure Send_Status
     (Brake        : Natural := 0;
      Radio        : Natural := 0;
      Adhesion     : Boolean := False;
      BMM          : Boolean := False;
      Reversing    : Boolean := False;
      SM_Direction : Natural := 0;
      Set_Speed    : Natural := 16#FFFF#;
      TTI          : Natural := 16#FF#;
      T_Disp_TTI   : Natural := 14;
      Tunnel       : Natural := 0;
      Tunnel_Dist  : Natural := 0;
      Geo_Pos      : Natural := 16#7FFF_FFFF#;
      Geo_Valid    : Boolean := False;
      HH, MM, SS   : Natural := 0)
   is
      Payload : Stream_Element_Array (1 .. Status_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Brake));
      Put_U8 (Payload, Offset, Unsigned_8 (Radio));
      Put_U8 (Payload, Offset, (if Adhesion then 1 else 0));
      Put_U8 (Payload, Offset, (if BMM then 1 else 0));
      Put_U8 (Payload, Offset, (if Reversing then 1 else 0));
      Put_U8 (Payload, Offset, Unsigned_8 (SM_Direction));
      Put_U16 (Payload, Offset, Unsigned_16 (Set_Speed));
      Put_U8 (Payload, Offset, Unsigned_8 (TTI));
      Put_U8 (Payload, Offset, Unsigned_8 (T_Disp_TTI));
      Put_U8 (Payload, Offset, Unsigned_8 (Tunnel));
      Put_U32 (Payload, Offset, Unsigned_32 (Tunnel_Dist));
      Put_U32 (Payload, Offset,
               (if Geo_Valid then Unsigned_32 (Geo_Pos)
                else 16#FFFF_FFFF#));
      Put_U8 (Payload, Offset, Unsigned_8 (HH));
      Put_U8 (Payload, Offset, Unsigned_8 (MM));
      Put_U8 (Payload, Offset, Unsigned_8 (SS));
      DMI_Core.Handle_Message (MSG_STATUS, Payload);
   end Send_Status;

   procedure Send_Text (ID           : Natural;
                        Text         : Wide_String;
                        First_Group  : Boolean := False;
                        Ack_Required : Boolean := False;
                        Class        : Natural := 1;
                        HH, MM       : Natural := 0)
   is
      Payload : Stream_Element_Array
        (1 .. Text_Header_Length + Text'Length);
      Offset : Stream_Element_Offset := Payload'First;
      Flags  : Unsigned_8 := Unsigned_8 (Class) * 4;
   begin
      if Ack_Required then
         Flags := Flags or 1;
      end if;
      if First_Group then
         Flags := Flags or 2;
      end if;
      Put_U16 (Payload, Offset, Unsigned_16 (ID));
      Put_U8 (Payload, Offset, Flags);
      Put_U8 (Payload, Offset, Unsigned_8 (HH));
      Put_U8 (Payload, Offset, Unsigned_8 (MM));
      Put_U8 (Payload, Offset, Unsigned_8 (Text'Length));
      for C of Text loop
         Put_U8 (Payload, Offset,
                 Unsigned_8 (Wide_Character'Pos (C) mod 256));
      end loop;
      DMI_Core.Handle_Message (MSG_TEXT, Payload);
   end Send_Text;

   procedure Send_Text_Remove (ID : Natural) is
      Payload : Stream_Element_Array (1 .. Text_Remove_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U16 (Payload, Offset, Unsigned_16 (ID));
      DMI_Core.Handle_Message (MSG_TEXT_REMOVE, Payload);
   end Send_Text_Remove;

   procedure Send_Track_Cond (Kinds : TC_Array) is
      Payload : Stream_Element_Array
        (1 .. 1 + Stream_Element_Offset (Kinds'Length) * 2);
      Offset : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Kinds'Length));
      for I in Kinds'Range loop
         Put_U8 (Payload, Offset, Unsigned_8 (I)); -- id
         Put_U8 (Payload, Offset, Unsigned_8 (Kinds (I)));
      end loop;
      DMI_Core.Handle_Message (MSG_TRACK_COND, Payload);
   end Send_Track_Cond;

   procedure Send_Planning
     (MA_Dist    : Natural;
      Ceiling    : Natural;
      Indication : Natural := 16#FFFF#;
      Advice     : Natural := 16#FFFF#;
      Gradients  : Gradient_Array := (1 .. 0 => 0);
      Speeds     : Gradient_Array := (1 .. 0 => 0);
      Orders     : Gradient_Array := (1 .. 0 => 0))
   is
      G_Count : constant Natural := Gradients'Length / 2;
      S_Count : constant Natural := Speeds'Length / 3;
      O_Count : constant Natural := Orders'Length / 2;
      Payload : Stream_Element_Array
        (1 .. Stream_Element_Offset (11 + G_Count * 3 + S_Count * 4 + O_Count * 3));
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U16 (Payload, Offset, Unsigned_16 (MA_Dist));
      Put_U16 (Payload, Offset, Unsigned_16 (Indication));
      Put_U16 (Payload, Offset, Unsigned_16 (Advice));
      Put_U16 (Payload, Offset, Unsigned_16 (Ceiling));
      Put_U8 (Payload, Offset, Unsigned_8 (G_Count));
      for I in 0 .. G_Count - 1 loop
         Put_U16 (Payload, Offset,
                  Unsigned_16 (Gradients (Gradients'First + I * 2)));
         declare
            V : constant Integer := Gradients (Gradients'First + I * 2 + 1);
         begin
            Put_U8 (Payload, Offset,
                    (if V < 0 then Unsigned_8 (256 + V) else Unsigned_8 (V)));
         end;
      end loop;
      Put_U8 (Payload, Offset, Unsigned_8 (S_Count));
      for I in 0 .. S_Count - 1 loop
         Put_U16 (Payload, Offset,
                  Unsigned_16 (Speeds (Speeds'First + I * 3)));
         Put_U16 (Payload, Offset,
                  Unsigned_16 (Speeds (Speeds'First + I * 3 + 1))
                  or (if Speeds (Speeds'First + I * 3 + 2) /= 0
                      then 16#8000# else 0));
      end loop;
      Put_U8 (Payload, Offset, Unsigned_8 (O_Count));
      for I in 0 .. O_Count - 1 loop
         Put_U8 (Payload, Offset,
                 Unsigned_8 (Orders (Orders'First + I * 2)));
         Put_U16 (Payload, Offset,
                  Unsigned_16 (Orders (Orders'First + I * 2 + 1)));
      end loop;
      DMI_Core.Handle_Message (MSG_PLANNING, Payload);
   end Send_Planning;

   procedure Send_Pointer (Event : Natural; X, Y : Natural) is
      Payload : Stream_Element_Array (1 .. Pointer_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Event));
      Put_U16 (Payload, Offset, Unsigned_16 (X));
      Put_U16 (Payload, Offset, Unsigned_16 (Y));
      DMI_Core.Handle_Message (MSG_POINTER, Payload);
   end Send_Pointer;

   procedure Pointer_Down (X, Y : Natural) is
   begin
      Send_Pointer (0, X, Y);
   end Pointer_Down;

   procedure Pointer_Up (X, Y : Natural) is
   begin
      Send_Pointer (1, X, Y);
   end Pointer_Up;

   procedure Step is
   begin
      DMI_Core.Tick (50);
      DMI_Core.Render;
   end Step;

   procedure Check_Frame (Name : String) is
      Path   : constant String := Golden_Dir & Name & ".sha256";
      Actual : constant String := Display.Screen.Digest;

      function Stored return String is
         F : File_Type;
      begin
         Open (F, In_File, Path);
         declare
            Line : constant String := Get_Line (F);
         begin
            Close (F);
            return Line;
         end;
      end Stored;
   begin
      Checks := Checks + 1;
      if Updating then
         Ada.Directories.Create_Path (Golden_Dir);
         declare
            F : File_Type;
         begin
            Create (F, Out_File, Path);
            Put_Line (F, Actual);
            Close (F);
         end;
         Put_Line ("recorded: " & Name);
      elsif not Ada.Directories.Exists (Path) then
         Fail ("golden frame missing: " & Name & " (run with UPDATE=1)");
      elsif Stored = Actual then
         Pass ("frame " & Name);
      else
         Fail ("frame differs: " & Name);
         Display.Screen.Dump (Golden_Dir & Name & ".actual");
      end if;
   end Check_Frame;

   procedure Expect_Sound (The_Sound : DMI_Sounds.Sound_T;
                           What      : String) is
      use type DMI_Sounds.Sound_T;
      Got : DMI_Sounds.Sound_T;
   begin
      Checks := Checks + 1;
      if not DMI_Sounds.Pop (Got) then
         Fail (What & ": expected sound "
               & DMI_Sounds.Sound_T'Image (The_Sound) & ", queue empty");
      elsif Got /= The_Sound then
         Fail (What & ": expected sound "
               & DMI_Sounds.Sound_T'Image (The_Sound) & ", got "
               & DMI_Sounds.Sound_T'Image (Got));
      else
         Pass (What);
      end if;
   end Expect_Sound;

   procedure Expect_No_Sound (What : String) is
      Got : DMI_Sounds.Sound_T;
   begin
      Checks := Checks + 1;
      if DMI_Sounds.Pop (Got) then
         Fail (What & ": unexpected sound " & DMI_Sounds.Sound_T'Image (Got));
      else
         Pass (What);
      end if;
   end Expect_No_Sound;

   procedure Drain_Sounds is
      Got : DMI_Sounds.Sound_T;
   begin
      while DMI_Sounds.Pop (Got) loop
         null;
      end loop;
   end Drain_Sounds;

   procedure Check (Condition : Boolean; What : String) is
   begin
      Checks := Checks + 1;
      if Condition then
         Pass (What);
      else
         Fail (What);
      end if;
   end Check;

   function Summary return Natural is
   begin
      Put_Line ("checks:" & Natural'Image (Checks)
                & "  failures:" & Natural'Image (Failures));
      return (if Failures = 0 then 0 else 1);
   end Summary;

end Test_Support;
