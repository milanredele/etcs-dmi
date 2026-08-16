--  ETCS DMI
--  Core message handling and rendering.

pragma Ada_2012;

with Display.A_Area;
with Display.B_Area;
with Display.C_Area;
with Display.D_Area;
with Speed_And_Distance;
with Supplementary_Driving_Info;
with Track_Ahead_Free;
with User_Settings;
with Interfaces; use Interfaces;

package body DMI_Core is

   package SDI renames Supplementary_Driving_Info;

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
      User_Settings.Toggle := (others => False);
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
   begin
      if Valid_Mode (Mode_Raw) then
         SDI.Mode := SDI.Mode_T'Val (Mode_Raw);
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
         when others =>
            null; -- unknown or not for us; ignore
      end case;
   end Handle_Message;

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
   begin
      if Outbox_Filled > 0 then
         Ada.Streams.Write (Stream.all, Outbox (1 .. Outbox_Filled));
         Outbox_Filled := 0;
      end if;
   end Flush_Outbox;

end DMI_Core;
