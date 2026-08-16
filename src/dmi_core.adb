--  ETCS DMI
--  Core message handling and rendering.

pragma Ada_2012;

with Display.A_Area;
with Display.B_Area;
with Display.C_Area;
with Display.D_Area;
with DMI_Buttons;
with DMI_Sounds;
with Speed_And_Distance;
with Supplementary_Driving_Info;
with Track_Ahead_Free;
with User_Settings;
with Interfaces; use Interfaces;

package body DMI_Core is

   package SDI renames Supplementary_Driving_Info;

   -- Combined area A + B: the touch sensitive surface of the speed
   -- information toggling function (8.2.2.4.2)
   function A_B_Area return Display.Area_T is
      A : constant Display.Area_T := Display.Get_Area (Display.A);
      B : constant Display.Area_T := Display.Get_Area (Display.B);
   begin
      return (A.Position, A.Width + B.Width, A.Height);
   end A_B_Area;

   -- Driver action identifiers (MSG_DRIVER_ACTION)
   ACTION_TAF_YES      : constant Unsigned_8 := 0;
   ACTION_SPEED_TOGGLE : constant Unsigned_8 := 1;

   procedure Queue_Driver_Action (Action : Unsigned_8;
                                  Arg    : Unsigned_16 := 0) is
      Payload : Stream_Element_Array (1 .. Driver_Action_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Action);
      Put_U16 (Payload, Offset, Arg);
      Queue_Message (MSG_DRIVER_ACTION, Payload);
   end Queue_Driver_Action;

   -- Keep the button registry in sync with the displayed state
   procedure Update_Buttons is
      use type SDI.Mode_T;
   begin
      if Track_Ahead_Free.Show then
         DMI_Buttons.Set_Active (DMI_Buttons.BTN_TAF_Yes,
                                 Display.D_Area.TAF_Answer_Area,
                                 DMI_Buttons.Up_Type);
      else
         DMI_Buttons.Set_Inactive (DMI_Buttons.BTN_TAF_Yes);
      end if;

      -- DMI 8.2.2.4.2/.4: A/B sensitive only in the Table 15 modes
      if SDI.Mode in SDI.M_OS | SDI.M_SR | SDI.M_SH then
         DMI_Buttons.Set_Active (DMI_Buttons.BTN_Speed_Toggle,
                                 A_B_Area,
                                 DMI_Buttons.Up_Type);
      else
         DMI_Buttons.Set_Inactive (DMI_Buttons.BTN_Speed_Toggle);
      end if;
   end Update_Buttons;

   Outbox        : Stream_Element_Array (1 .. 1024);
   Outbox_Filled : Stream_Element_Offset := 0;

   ----------------
   -- Initialise --
   ----------------

   procedure Initialise is
   begin
      SDI.Mode := SDI.M_SB;
      SDI.Acknowledgment_Mode := (Valid => False);
      SDI.Override := False;
      SDI.Level := SDI.Unknown;
      SDI.Level_Announcement := (Valid => False);
      User_Settings.Speed_Info_Visible := False;
      Track_Ahead_Free.Show := False;
      Speed_And_Distance.Set_Monitoring_Mode (Speed_And_Distance.CSM);
      Speed_And_Distance.Set_Seed_Dial_Range (Speed_And_Distance.Range_180);
      Speed_And_Distance.Set_Speed_Params ((Vperm => 0,
                                            Vtarget => 0,
                                            Vwsl => 0,
                                            Vsbi => 0,
                                            Vrelease => 0,
                                            Vrelease_Exists => False));
      Speed_And_Distance.Set_Speed (0);
      Speed_And_Distance.Set_Distance_To_Target (0);
      Speed_And_Distance.Set_LSSMA (0, Valid => False);
   end Initialise;

   -----------------------
   -- Message appliers  --
   -----------------------

   procedure Apply_Speed_State (Payload : Stream_Element_Array) is
      use Speed_And_Distance;

      Offset : Stream_Element_Offset := Payload'First;

      function Next_Speed return Speed_T is
         Raw : constant Unsigned_16 := Get_U16 (Payload, Offset);
      begin
         return Speed_T (Unsigned_16'Min (Raw, 400));
      end Next_Speed;

      V_Cur      : constant Speed_T := Next_Speed;
      V_Perm     : constant Speed_T := Next_Speed;
      V_Target   : constant Speed_T := Next_Speed;
      V_Release  : constant Speed_T := Next_Speed;
      V_Sbi      : constant Speed_T := Next_Speed;
      V_Wsl      : constant Speed_T := Next_Speed;
      D_Target   : constant Unsigned_32 := Get_U32 (Payload, Offset);
      Monitoring : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Dial_Range : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Flags      : constant Unsigned_8 := Get_U8 (Payload, Offset);
   begin
      case Monitoring is
         when 0      => Set_Monitoring_Mode (CSM);
         when 1      => Set_Monitoring_Mode (TSM);
         when others => Set_Monitoring_Mode (RSM);
      end case;
      Set_CSM_Target_Info ((Flags and 2) /= 0);

      Set_Speed_Params ((Vperm    => V_Perm,
                         Vtarget  => V_Target,
                         Vwsl     => V_Wsl,
                         Vsbi     => V_Sbi,
                         Vrelease => V_Release,
                         Vrelease_Exists => (Flags and 1) /= 0));
      Set_Speed (V_Cur);

      Set_Distance_To_Target
        (Distance_T (Unsigned_32'Min (D_Target, 90000)));

      case Dial_Range is
         when 0      => Set_Seed_Dial_Range (Range_140);
         when 1      => Set_Seed_Dial_Range (Range_180);
         when 2      => Set_Seed_Dial_Range (Range_250);
         when others => Set_Seed_Dial_Range (Range_400);
      end case;
   end Apply_Speed_State;

   procedure Apply_Mode_Level (Payload : Stream_Element_Array) is
      Offset : Stream_Element_Offset := Payload'First;

      Mode_Raw      : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Level_Raw     : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Mode_Ack      : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Level_Ann     : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Level_Ann_Ack : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Override      : constant Unsigned_8 := Get_U8 (Payload, Offset);
      TAF           : constant Unsigned_8 := Get_U8 (Payload, Offset);
      LSSMA         : constant Unsigned_16 := Get_U16 (Payload, Offset);

      function Valid_Mode (Raw : Unsigned_8) return Boolean is
        (Natural (Raw) <= SDI.Mode_T'Pos (SDI.Mode_T'Last));

      function Valid_Level (Raw : Unsigned_8) return Boolean is
        (Natural (Raw) <= SDI.Level_T'Pos (SDI.Level_T'Last));

      Old_Mode : constant SDI.Mode_T := SDI.Mode;
      use type SDI.Mode_T;
   begin
      if Valid_Mode (Mode_Raw) then
         SDI.Mode := SDI.Mode_T'Val (Mode_Raw);
      end if;

      if SDI.Mode /= Old_Mode then
         -- DMI 8.2.2.4.5: entering a Table 15 mode toggles the objects off
         if SDI.Mode in SDI.M_OS | SDI.M_SR | SDI.M_SH then
            User_Settings.Speed_Info_Visible := False;
         end if;
         -- a continuous warning sound cannot outlive entering AD
         if SDI.Mode = SDI.M_AD then
            DMI_Sounds.Play (DMI_Sounds.S2_Warning_Stop);
         end if;
      end if;

      if Valid_Level (Level_Raw) then
         SDI.Level := SDI.Level_T'Val (Level_Raw);
      end if;

      if Mode_Ack /= 16#FF#
        and then Valid_Mode (Mode_Ack)
        and then SDI.Mode_T'Val (Mode_Ack) in SDI.Acknowledgment_Mode_T
      then
         SDI.Acknowledgment_Mode :=
           (Valid => True, Mode => SDI.Mode_T'Val (Mode_Ack));
      else
         SDI.Acknowledgment_Mode := (Valid => False);
      end if;

      if Level_Ann /= 16#FF# and then Valid_Level (Level_Ann) then
         SDI.Level_Announcement :=
           (Valid        => True,
            Level        => SDI.Level_T'Val (Level_Ann),
            Ack_Required => Level_Ann_Ack /= 0);
      else
         SDI.Level_Announcement := (Valid => False);
      end if;

      SDI.Override := Override /= 0;
      Track_Ahead_Free.Show := TAF /= 0;

      if LSSMA = 16#FFFF# then
         Speed_And_Distance.Set_LSSMA (0, Valid => False);
      else
         Speed_And_Distance.Set_LSSMA
           (Speed_And_Distance.Speed_T (Unsigned_16'Min (LSSMA, 400)),
            Valid => True);
      end if;
   end Apply_Mode_Level;

   --------------------
   -- Handle_Message --
   --------------------

   procedure Apply_Pointer (Payload : Stream_Element_Array) is
      Offset : Stream_Element_Offset := Payload'First;
      Event  : constant Unsigned_8 := Get_U8 (Payload, Offset);
      X      : constant Unsigned_16 := Get_U16 (Payload, Offset);
      Y      : constant Unsigned_16 := Get_U16 (Payload, Offset);
      Kind   : DMI_Buttons.Pointer_Event_T;
   begin
      case Event is
         when 0      => Kind := DMI_Buttons.Down;
         when 1      => Kind := DMI_Buttons.Up;
         when others => Kind := DMI_Buttons.Move;
      end case;
      DMI_Buttons.Pointer_Event (Kind, Natural (X), Natural (Y));
   end Apply_Pointer;

   procedure Handle_Message (The_Type : Msg_Type_T;
                             Payload  : Stream_Element_Array) is
   begin
      case The_Type is
         when MSG_SPEED_STATE =>
            if Payload'Length = Speed_State_Length then
               Apply_Speed_State (Payload);
            end if;
         when MSG_MODE_LEVEL =>
            if Payload'Length = Mode_Level_Length then
               Apply_Mode_Level (Payload);
            end if;
         when MSG_POINTER =>
            if Payload'Length = Pointer_Length then
               Update_Buttons; -- make sure hit testing sees current state
               Apply_Pointer (Payload);
            end if;
         when others =>
            null; -- unknown or not for us; ignore
      end case;
   end Handle_Message;

   ----------
   -- Tick --
   ----------

   procedure Tick (Dt_Ms : Natural) is
      ID : DMI_Buttons.Button_ID_T;
      use all type DMI_Buttons.Button_ID_T;
   begin
      Update_Buttons;
      DMI_Buttons.Tick (Dt_Ms);
      while DMI_Buttons.Pop_Activation (ID) loop
         case ID is
            when BTN_TAF_Yes =>
               -- 8.2.3.3: the driver confirms the track ahead is free;
               -- the EVC decides when the question disappears
               Queue_Driver_Action (ACTION_TAF_YES);
            when BTN_Speed_Toggle =>
               -- 8.2.2.4: toggle all concerned objects for this mode
               User_Settings.Speed_Info_Visible :=
                 not User_Settings.Speed_Info_Visible;
               Queue_Driver_Action
                 (ACTION_SPEED_TOGGLE,
                  (if User_Settings.Speed_Info_Visible then 1 else 0));
         end case;
      end loop;
   end Tick;

   ------------
   -- Render --
   ------------

   procedure Render is
   begin
      Display.B_Area.Draw;
      Display.A_Area.Draw;
      Display.C_Area.Draw;
      Display.D_Area.Draw;
   end Render;

   -------------------
   -- Queue_Message --
   -------------------

   procedure Queue_Message (The_Type : Msg_Type_T;
                            Payload  : Stream_Element_Array) is
      Needed : constant Stream_Element_Offset :=
        Header_Length + Payload'Length;
      Offset : Stream_Element_Offset := Outbox_Filled + 1;
   begin
      if Outbox_Filled + Needed > Outbox'Last then
         return; -- queue full; drop (test tooling only)
      end if;
      Put_Header (Outbox, Offset, The_Type, Payload'Length);
      Outbox (Offset .. Offset + Payload'Length - 1) := Payload;
      Outbox_Filled := Outbox_Filled + Needed;
   end Queue_Message;

   ------------------
   -- Flush_Outbox --
   ------------------

   procedure Flush_Outbox
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class) is
      The_Sound : DMI_Sounds.Sound_T;
   begin
      while DMI_Sounds.Pop (The_Sound) loop
         declare
            Payload : Stream_Element_Array (1 .. Sound_Length);
            Offset  : Stream_Element_Offset := Payload'First;
         begin
            Put_U8 (Payload, Offset,
                    Unsigned_8 (DMI_Sounds.Sound_T'Pos (The_Sound)));
            Queue_Message (MSG_SOUND, Payload);
         end;
      end loop;
      if Outbox_Filled > 0 then
         Ada.Streams.Write (Stream.all, Outbox (1 .. Outbox_Filled));
         Outbox_Filled := 0;
      end if;
   end Flush_Outbox;

end DMI_Core;
