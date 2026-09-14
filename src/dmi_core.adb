--  ETCS DMI
--  Core message handling and rendering.

pragma Ada_2012;

with Display.A_Area;
with Display.B_Area;
with Display.C_Area;
with Display.D_Area;
with Display.E_Area;
with Display.F_Area;
with Display.G_Area;
with Display.Screen;
with DMI_Ack;
with DMI_Buttons;
with DMI_Driver_Data;
with DMI_Planning;
with DMI_Sounds;
with DMI_Status;
with DMI_Text_Messages;
with DMI_Windows;
with General_Parameters;
with Speed_And_Distance;
with Supplementary_Driving_Info;
with Track_Ahead_Free;
with User_Settings;
with Interfaces; use Interfaces;

package body DMI_Core is

   package SDI renames Supplementary_Driving_Info;

   use type Display.Position_T;

   -- Combined area A + B: the touch sensitive surface of the speed
   -- information toggling function (8.2.2.4.2)
   function A_B_Area return Display.Area_T is
      A : constant Display.Area_T := Display.Get_Area (Display.A);
      B : constant Display.Area_T := Display.Get_Area (Display.B);
   begin
      return (A.Position, A.Width + B.Width, A.Height);
   end A_B_Area;

   -- Driver action identifiers (MSG_DRIVER_ACTION)
   ACTION_TAF_YES       : constant Unsigned_8 := 0;
   ACTION_SPEED_TOGGLE  : constant Unsigned_8 := 1;
   ACTION_ACK           : constant Unsigned_8 := 2; -- arg: Ack_Kind_T'Pos
   ACTION_TUNNEL_TOGGLE : constant Unsigned_8 := 3;
   ACTION_GEO_TOGGLE    : constant Unsigned_8 := 4;

   -- Transition tracking for Sinfo rules
   TTI_Was_Displayed : Boolean := False;

   procedure Queue_Driver_Action (Action : Unsigned_8;
                                  Arg    : Unsigned_16 := 0) is
      Payload : Stream_Element_Array (1 .. Driver_Action_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Action);
      Put_U16 (Payload, Offset, Arg);
      Queue_Message (MSG_DRIVER_ACTION, Payload);
   end Queue_Driver_Action;

   -- Keep the button registry in sync with the displayed state.
   -- DMI 5.3.1.1.5: while a sub-level window is open, only that window
   -- responds to driver input.
   procedure Update_Buttons is
      use type SDI.Mode_T;
      use all type DMI_Buttons.Button_ID_T;
      use all type DMI_Ack.Ack_Kind_T;

      Window_Open : constant Boolean := DMI_Windows.Is_Open;
   begin
      if not Window_Open and then Track_Ahead_Free.Show then
         DMI_Buttons.Set_Active (BTN_TAF_Yes,
                                 Display.D_Area.TAF_Answer_Area,
                                 DMI_Buttons.Up_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_TAF_Yes);
      end if;

      -- DMI 8.2.2.4.2/.4: A/B sensitive only in the Table 15 modes
      if not Window_Open and then SDI.Mode in SDI.M_OS | SDI.M_SR | SDI.M_SH then
         DMI_Buttons.Set_Active (BTN_Speed_Toggle, A_B_Area,
                                 DMI_Buttons.Up_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_Speed_Toggle);
      end if;

      -- DMI 5.4.1.4: the area displaying the acknowledgement becomes the
      -- ack button. Acknowledgements stay available with a window open
      -- (they are offered on the default window; a pending ack while a
      -- window is open closes it per Table 48 -- simplified here by
      -- keeping the ack button active).
      if DMI_Ack.Current_Valid then
         DMI_Buttons.Set_Active
           (BTN_Ack,
            (case DMI_Ack.Current_Kind is
                when Level_Transition | Mode_Change =>
                   Display.C_Area.C1_Absolute_Area,
                when Brake_Release =>
                   -- 8.2.2.3.5: extended over C8, C9 and E1
                   Display.C_Area.Brake_Ack_Area,
                when Fixed_Text | Plain_Text | System_Status | NTC_Text =>
                   -- 8.2.3.4.8 b: the full E5-E9 block
                   (Display.Get_Area (Display.E).Position + (54, 0), 234, 100)),
            DMI_Buttons.Up_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_Ack);
      end if;

      -- Text message scrolling (8.2.3.4.7 e/f); disabled buttons do not
      -- react (5.3.2.7.5); scroll buttons are down-type with repeat
      -- (5.3.2.7.2)
      if not Window_Open
        and then not DMI_Text_Messages.Ack_Pending
        and then DMI_Text_Messages.Can_Scroll_Up
      then
         DMI_Buttons.Set_Active (BTN_Msg_Up,
                                 Display.Get_Area (Display.E10),
                                 DMI_Buttons.Down_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_Msg_Up);
      end if;
      if not Window_Open
        and then not DMI_Text_Messages.Ack_Pending
        and then DMI_Text_Messages.Can_Scroll_Down
      then
         DMI_Buttons.Set_Active (BTN_Msg_Down,
                                 Display.Get_Area (Display.E11),
                                 DMI_Buttons.Down_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_Msg_Down);
      end if;

      -- Tunnel stopping area toggle (8.2.3.6.4/.10)
      if not Window_Open
        and then DMI_Status."/=" (DMI_Status.Tunnel, DMI_Status.Unknown)
      then
         DMI_Buttons.Set_Active (BTN_Tunnel_Toggle,
                                 Display.C_Area.Tunnel_Toggle_Area,
                                 DMI_Buttons.Up_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_Tunnel_Toggle);
      end if;

      -- Planning area zoom (8.3.10): sensitive areas 40x30, D9 extended
      -- upwards and D12 downwards; disabled at the range ends (5.3.2.7.5)
      if not Window_Open and then DMI_Planning.Displayed
        and then DMI_Planning.Can_Zoom_In
      then
         DMI_Buttons.Set_Active
           (BTN_Zoom_In,
            (Display.Get_Area (Display.D9).Position + (0, 0), 40, 30),
            DMI_Buttons.Up_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_Zoom_In);
      end if;
      if not Window_Open and then DMI_Planning.Displayed
        and then DMI_Planning.Can_Zoom_Out
      then
         DMI_Buttons.Set_Active
           (BTN_Zoom_Out,
            (Display.Get_Area (Display.D12).Position, 40, 30),
            DMI_Buttons.Up_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_Zoom_Out);
      end if;

      -- Geographical position toggle (8.4.4.4/.10)
      if not Window_Open and then DMI_Status.Geo_Valid then
         DMI_Buttons.Set_Active (BTN_Geo_Toggle,
                                 Display.Get_Area (Display.G12),
                                 DMI_Buttons.Up_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_Geo_Toggle);
      end if;

      -- DMI 8.6.1: window selection buttons, always enabled on the
      -- default window
      if not Window_Open then
         for B in DMI_Buttons.F_Button_T loop
            DMI_Buttons.Set_Active
              (B,
               Display.Get_Area
                 (case B is
                     when BTN_F1 => Display.F1,
                     when BTN_F2 => Display.F2,
                     when BTN_F3 => Display.F3,
                     when BTN_F4 => Display.F4,
                     when others => Display.F5),
               DMI_Buttons.Up_Type);
         end loop;
         DMI_Buttons.Set_Inactive (BTN_Window_Close);
         for B in DMI_Buttons.Menu_Button_T loop
            DMI_Buttons.Set_Inactive (B);
         end loop;
      else
         for B in DMI_Buttons.F_Button_T loop
            DMI_Buttons.Set_Inactive (B);
         end loop;
         DMI_Buttons.Set_Active (BTN_Window_Close,
                                 DMI_Windows.Close_Button_Area,
                                 DMI_Buttons.Up_Type);
         -- window-internal buttons (menu grid / keyboard / validation)
         declare
            Count : constant Natural := DMI_Windows.Button_Count;
            Index : Natural := 1;
         begin
            for B in DMI_Buttons.Menu_Button_T loop
               if Index <= Count
                 and then DMI_Windows.Button_Enabled (Index)
               then
                  DMI_Buttons.Set_Active
                    (B, DMI_Windows.Button_Area (Index),
                     DMI_Windows.Button_Kind (Index));
               else
                  DMI_Buttons.Set_Inactive (B);
               end if;
               Index := Index + 1;
            end loop;
         end;
      end if;
   end Update_Buttons;

   -- Translate queued window actions into protocol messages
   procedure Drain_Window_Actions is
      use all type DMI_Windows.Action_T;
      use DMI_Driver_Data;

      Action : DMI_Windows.Action_T;
      Arg    : Natural;

      procedure Send_Text_Data (Kind : Unsigned_8;
                                Value : Text_Value_T) is
         Payload : Stream_Element_Array
           (1 .. 2 + Stream_Element_Offset (Value.Length));
         Offset : Stream_Element_Offset := Payload'First;
      begin
         Put_U8 (Payload, Offset, Kind);
         Put_U8 (Payload, Offset, Unsigned_8 (Value.Length));
         for I in 1 .. Value.Length loop
            Put_U8 (Payload, Offset,
                    Unsigned_8 (Wide_Character'Pos (Value.Text (I)) mod 256));
         end loop;
         Queue_Message (MSG_DRIVER_DATA, Payload);
      end Send_Text_Data;

      procedure Send_Numeric_Data (Kind : Unsigned_8; A, B, C : Natural;
                                   Count : Positive) is
         Payload : Stream_Element_Array
           (1 .. 1 + Stream_Element_Offset (Count) * 2);
         Offset : Stream_Element_Offset := Payload'First;
      begin
         Put_U8 (Payload, Offset, Kind);
         Put_U16 (Payload, Offset, Unsigned_16 (Natural'Min (A, 65535)));
         if Count >= 2 then
            Put_U16 (Payload, Offset, Unsigned_16 (Natural'Min (B, 65535)));
         end if;
         if Count >= 3 then
            Put_U16 (Payload, Offset, Unsigned_16 (Natural'Min (C, 65535)));
         end if;
         Queue_Message (MSG_DRIVER_DATA, Payload);
      end Send_Numeric_Data;

      ACTION_START           : constant Unsigned_8 := 5;
      ACTION_OVERRIDE        : constant Unsigned_8 := 6;
      ACTION_SH_REQUEST      : constant Unsigned_8 := 7;
      ACTION_EXIT_SH         : constant Unsigned_8 := 8;
      ACTION_ADHESION        : constant Unsigned_8 := 9;
      ACTION_TRAIN_INTEGRITY : constant Unsigned_8 := 10;
      ACTION_LEVEL_SELECTED  : constant Unsigned_8 := 11;
      ACTION_NON_LEADING     : constant Unsigned_8 := 12;
   begin
      while DMI_Windows.Pop_Action (Action, Arg) loop
         case Action is
            when Start_Mission =>
               Queue_Driver_Action (ACTION_START);
            when Override_EOA =>
               Queue_Driver_Action (ACTION_OVERRIDE);
            when SH_Request =>
               Queue_Driver_Action (ACTION_SH_REQUEST);
            when Exit_SH =>
               Queue_Driver_Action (ACTION_EXIT_SH);
            when Non_Leading =>
               Queue_Driver_Action (ACTION_NON_LEADING);
            when Train_Integrity =>
               Queue_Driver_Action (ACTION_TRAIN_INTEGRITY);
            when Adhesion_Set =>
               Queue_Driver_Action (ACTION_ADHESION, Unsigned_16 (Arg));
            when Level_Selected =>
               Queue_Driver_Action (ACTION_LEVEL_SELECTED, Unsigned_16 (Arg));
            when Send_Driver_ID =>
               Send_Text_Data (0, Driver_ID);
            when Send_TRN =>
               Send_Text_Data (1, TRN);
            when Send_Train_Data =>
               Send_Numeric_Data (2, Train_Length, Brake_Pct, Max_Speed, 3);
            when Send_SR_Data =>
               Send_Numeric_Data (3, SR_Speed, SR_Dist, 0, 2);
         end case;
      end loop;
   end Drain_Window_Actions;

   Outbox        : Stream_Element_Array (1 .. Outbox_Size);
   Outbox_Filled : Stream_Element_Offset := 0;

   -- EVC link supervision (General_Parameters.EVC_Link_Timeout_Ms)
   EVC_Heard    : Boolean := False; -- supervision arms with the first message
   Link_Lost    : Boolean := False;
   Since_EVC_Ms : Natural := 0;

   -----------------
   -- Reset_State --
   -----------------

   -- Forget everything the EVC and the driver provided
   procedure Reset_State is
   begin
      DMI_Ack.Reset;
      DMI_Driver_Data.Reset;
      DMI_Planning.Reset;
      DMI_Status.Reset;
      DMI_Text_Messages.Reset;
      DMI_Windows.Close_All;
      TTI_Was_Displayed := False;
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
   end Reset_State;

   ----------------
   -- Initialise --
   ----------------

   procedure Initialise is
   begin
      Reset_State;
      EVC_Heard := False;
      Link_Lost := False;
      Since_EVC_Ms := 0;
   end Initialise;

   ---------------------
   -- Link supervision --
   ---------------------

   procedure Enter_Link_Lost is
   begin
      Reset_State;
      SDI.Mode := SDI.M_SF; -- 8.2.3.1.2: MO18 in B7
      Link_Lost := True;
   end Enter_Link_Lost;

   procedure Note_EVC_Message is
   begin
      EVC_Heard := True;
      Since_EVC_Ms := 0;
      Link_Lost := False; -- the messages rebuild the picture
   end Note_EVC_Message;

   function EVC_Link_Lost return Boolean is (Link_Lost);

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
      Set_Brake_Commanded ((Flags and 4) /= 0);

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

      -- Mode acknowledgement request (edge into the ack service)
      if Mode_Ack /= 16#FF#
        and then Valid_Mode (Mode_Ack)
        and then SDI.Mode_T'Val (Mode_Ack) in SDI.Acknowledgment_Mode_T
      then
         if not SDI.Acknowledgment_Mode.Valid
           or else SDI.Acknowledgment_Mode.Mode /= SDI.Mode_T'Val (Mode_Ack)
         then
            DMI_Ack.Request_Mode_Ack (SDI.Mode_T'Val (Mode_Ack));
         end if;
         SDI.Acknowledgment_Mode :=
           (Valid => True, Mode => SDI.Mode_T'Val (Mode_Ack));
      else
         if SDI.Acknowledgment_Mode.Valid then
            DMI_Ack.Cancel (DMI_Ack.Mode_Change);
         end if;
         SDI.Acknowledgment_Mode := (Valid => False);
      end if;

      -- Level announcement; with acknowledgement it goes through the ack
      -- service (only L0 and NTC have ack symbols in v4.0.0)
      if Level_Ann /= 16#FF# and then Valid_Level (Level_Ann) then
         declare
            New_Level : constant SDI.Level_T := SDI.Level_T'Val (Level_Ann);
            With_Ack  : constant Boolean :=
              Level_Ann_Ack /= 0 and then New_Level in SDI.L0 | SDI.NTC;
            use type SDI.Level_T;
         begin
            if With_Ack
              and then not (SDI.Level_Announcement.Valid
                            and then SDI.Level_Announcement.Ack_Required
                            and then SDI.Level_Announcement.Level = New_Level)
            then
               DMI_Ack.Request_Level_Ack (New_Level);
            elsif not With_Ack
              and then SDI.Level_Announcement.Valid
              and then SDI.Level_Announcement.Ack_Required
            then
               DMI_Ack.Cancel (DMI_Ack.Level_Transition);
            end if;
            SDI.Level_Announcement :=
              (Valid        => True,
               Level        => New_Level,
               Ack_Required => With_Ack);
         end;
      else
         if SDI.Level_Announcement.Valid
           and then SDI.Level_Announcement.Ack_Required
         then
            DMI_Ack.Cancel (DMI_Ack.Level_Transition);
         end if;
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

   procedure Apply_Text (Payload : Stream_Element_Array) is
      Offset : Stream_Element_Offset := Payload'First;
      ID     : constant Unsigned_16 := Get_U16 (Payload, Offset);
      Flags  : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Hour   : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Minute : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Length : constant Unsigned_8 := Get_U8 (Payload, Offset);

      Class : constant DMI_Text_Messages.Class_T :=
        (case Shift_Right (Flags, 2) and 3 is
            when 0      => DMI_Text_Messages.Fixed_Text,
            when 1      => DMI_Text_Messages.Plain_Text,
            when 2      => DMI_Text_Messages.System_Status,
            when others => DMI_Text_Messages.NTC_Text);

      Text : Wide_String (1 .. Natural (Length));
   begin
      if Payload'Length /= Text_Header_Length + Natural (Length) then
         return;
      end if;
      for I in Text'Range loop
         Text (I) := Wide_Character'Val (Natural (Get_U8 (Payload, Offset)));
      end loop;
      DMI_Text_Messages.Put
        (ID           => Natural (ID),
         First_Group  => (Flags and 2) /= 0,
         Ack_Required => (Flags and 1) /= 0,
         Class        => Class,
         Hour         => Natural (Hour),
         Minute       => Natural (Minute),
         Text         => Text);
   end Apply_Text;

   procedure Apply_Track_Cond (Payload : Stream_Element_Array) is
      Offset : Stream_Element_Offset := Payload'First;
      Count  : constant Unsigned_8 := Get_U8 (Payload, Offset);
      List   : DMI_Status.TC_List_T;
      Used   : Natural := 0;
   begin
      if Payload'Length /= 1 + Natural (Count) * Track_Cond_Entry_Length then
         return;
      end if;
      for I in 1 .. Natural (Count) loop
         declare
            ID   : constant Unsigned_8 := Get_U8 (Payload, Offset);
            Kind : constant Unsigned_8 := Get_U8 (Payload, Offset);
         begin
            if Kind in 1 .. DMI_Status.LX_Kind
              and then Used < List'Last
            then
               Used := Used + 1;
               List (Used) := (ID => Natural (ID), Kind => Natural (Kind));
            end if;
         end;
      end loop;
      DMI_Status.Reconcile_Track_Conditions (List, Used);
   end Apply_Track_Cond;

   procedure Apply_Status (Payload : Stream_Element_Array) is
      use DMI_Status;
      Offset : Stream_Element_Offset := Payload'First;

      Brake_Raw  : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Radio_Raw  : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Adhesion   : constant Unsigned_8 := Get_U8 (Payload, Offset);
      BMM        : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Reversing  : constant Unsigned_8 := Get_U8 (Payload, Offset);
      SM_Dir     : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Set_Spd    : constant Unsigned_16 := Get_U16 (Payload, Offset);
      TTI        : constant Unsigned_8 := Get_U8 (Payload, Offset);
      T_Disp     : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Tunnel_Raw : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Tun_Dist   : constant Unsigned_32 := Get_U32 (Payload, Offset);
      Geo_Pos    : constant Unsigned_32 := Get_U32 (Payload, Offset);
      Hour       : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Minute     : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Second     : constant Unsigned_8 := Get_U8 (Payload, Offset);

      Old_Brake : constant Brake_T := Brake;
      New_Brake : constant Brake_T :=
        (case Brake_Raw is
            when 0      => None,
            when 1      => Shown,
            when others => Shown_Ack_Required);
      use type SDI.Mode_T;
   begin
      Brake := New_Brake;
      if New_Brake /= Old_Brake then
         case New_Brake is
            when Shown_Ack_Required =>
               -- 8.2.2.3.4 / 5.4: brake release acknowledgement
               DMI_Ack.Request (DMI_Ack.Brake_Release);
            when None =>
               if Old_Brake = Shown_Ack_Required then
                  DMI_Ack.Cancel (DMI_Ack.Brake_Release);
               elsif Old_Brake = Shown then
                  -- 8.2.2.3.6: released without driver acknowledgement
                  DMI_Sounds.Play (DMI_Sounds.Sinfo);
               end if;
            when Shown =>
               if Old_Brake = Shown_Ack_Required then
                  DMI_Ack.Cancel (DMI_Ack.Brake_Release);
               end if;
         end case;
      end if;

      Radio :=
        (case Radio_Raw is
            when 1      => Connection_Up,
            when 2      => Connection_Lost,
            when others => No_Connection);
      Slippery_Rail := Adhesion /= 0;
      BMM_Inhibited := BMM /= 0;
      Reversing_Permitted := Reversing /= 0;
      SM_Direction :=
        (case SM_Dir is
            when 1      => Forward,
            when 2      => Backward,
            when others => None);

      Set_Speed_Valid := Set_Spd /= 16#FFFF#;
      Set_Speed := Natural (Unsigned_16'Min (Set_Spd, 400));

      TTI_Valid := TTI /= 16#FF#;
      TTI_Seconds := Natural (TTI);
      if T_Disp > 0 then
         T_Disp_TTI := Natural (T_Disp);
      end if;

      declare
         Old_Tunnel : constant Tunnel_T := Tunnel;
      begin
         Tunnel :=
           (case Tunnel_Raw is
               when 1      => Active,
               when 2      => Announced,
               when others => Unknown);
         -- 8.2.3.6.3: state is only meaningful while known
         if Tunnel = Unknown and Old_Tunnel /= Unknown then
            Tunnel_Toggled_On := False;
         end if;
      end;
      Tunnel_Distance := Natural (Unsigned_32'Min (Tun_Dist, 99999));

      Geo_Valid := Geo_Pos /= 16#FFFF_FFFF#;
      if Geo_Valid then
         Geo_Position_M := Natural (Unsigned_32'Min (Geo_Pos, 999_999_999));
      end if;

      Time_H := Natural (Hour) mod 24;
      Time_M := Natural (Minute) mod 60;
      Time_S := Natural (Second) mod 60;

      -- 8.2.2.5.7: Sinfo when the TTI appears, unless in AD
      if DMI_Status.TTI_Displayed and not TTI_Was_Displayed then
         if SDI.Mode /= SDI.M_AD then
            DMI_Sounds.Play (DMI_Sounds.Sinfo);
         end if;
      end if;
      TTI_Was_Displayed := DMI_Status.TTI_Displayed;
   end Apply_Status;

   procedure Apply_Planning (Payload : Stream_Element_Array) is
      use DMI_Planning;
      Offset : Stream_Element_Offset := Payload'First;

      MA     : Unsigned_16;
      Ind    : Unsigned_16;
      Advice : Unsigned_16;
      Ceil   : Unsigned_16;
      Count  : Unsigned_8;

      Remaining : Stream_Element_Offset;
   begin
      if Payload'Length < 9 then
         return;
      end if;
      MA := Get_U16 (Payload, Offset);
      Ind := Get_U16 (Payload, Offset);
      Advice := Get_U16 (Payload, Offset);
      Ceil := Get_U16 (Payload, Offset);

      -- gradients
      Count := Get_U8 (Payload, Offset);
      Remaining := Payload'Last - Offset + 1;
      if Remaining < Stream_Element_Offset (Count) * 3 then
         return;
      end if;
      Gradient_Count := Natural'Min (Natural (Count), Max_Gradients);
      for I in 1 .. Natural (Count) loop
         declare
            Start : constant Unsigned_16 := Get_U16 (Payload, Offset);
            Raw   : constant Unsigned_8 := Get_U8 (Payload, Offset);
            Value : constant Integer :=
              (if Raw >= 128 then Integer (Raw) - 256 else Integer (Raw));
         begin
            if I <= Max_Gradients then
               Gradients (I) := (Start_M => Natural (Start), Value => Value);
            end if;
         end;
      end loop;

      -- speed profile discontinuities
      if Offset > Payload'Last then
         return;
      end if;
      Count := Get_U8 (Payload, Offset);
      Remaining := Payload'Last - Offset + 1;
      if Remaining < Stream_Element_Offset (Count) * 4 then
         return;
      end if;
      Speed_Count := Natural'Min (Natural (Count), Max_Speeds);
      for I in 1 .. Natural (Count) loop
         declare
            Dist : constant Unsigned_16 := Get_U16 (Payload, Offset);
            Spd  : constant Unsigned_16 := Get_U16 (Payload, Offset);
         begin
            if I <= Max_Speeds then
               Speeds (I) :=
                 (Dist_M        => Natural (Dist),
                  Speed         => Natural (Spd and 16#7FFF#),
                  Is_Ind_Target => (Spd and 16#8000#) /= 0);
            end if;
         end;
      end loop;

      -- orders and announcements
      if Offset > Payload'Last then
         return;
      end if;
      Count := Get_U8 (Payload, Offset);
      Remaining := Payload'Last - Offset + 1;
      if Remaining < Stream_Element_Offset (Count) * 3 then
         return;
      end if;
      Order_Count := Natural'Min (Natural (Count), Max_Orders);
      for I in 1 .. Natural (Count) loop
         declare
            Sym  : constant Unsigned_8 := Get_U8 (Payload, Offset);
            Dist : constant Unsigned_16 := Get_U16 (Payload, Offset);
         begin
            if I <= Max_Orders and then Sym in 1 .. 37 then
               Orders (I) := (Symbol_Kind => Natural (Sym),
                              Dist_M      => Natural (Dist));
            end if;
         end;
      end loop;

      MA_Dist_M := Natural (MA);
      Indication_Valid := Ind /= 16#FFFF#;
      Indication_Dist_M := Natural (Ind and 16#7FFF#);
      Advice_Valid := Advice /= 16#FFFF#;
      Advice_Dist_M := Natural (Advice and 16#7FFF#);
      Ceiling_Speed := Natural (Ceil);
      Valid := True;
   end Apply_Planning;

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
      if The_Type in MSG_SPEED_STATE | MSG_MODE_LEVEL | MSG_TEXT
                   | MSG_TEXT_REMOVE | MSG_TRACK_COND | MSG_STATUS
                   | MSG_PLANNING
      then
         Note_EVC_Message;
      end if;

      case The_Type is
         when MSG_SPEED_STATE =>
            if Payload'Length = Speed_State_Length then
               Apply_Speed_State (Payload);
            end if;
         when MSG_MODE_LEVEL =>
            if Payload'Length = Mode_Level_Length then
               Apply_Mode_Level (Payload);
            end if;
         when MSG_TEXT =>
            if Payload'Length >= Text_Header_Length then
               Apply_Text (Payload);
            end if;
         when MSG_TEXT_REMOVE =>
            if Payload'Length = Text_Remove_Length then
               declare
                  Offset : Stream_Element_Offset := Payload'First;
               begin
                  DMI_Text_Messages.Remove (Natural (Get_U16 (Payload, Offset)));
               end;
            end if;
         when MSG_TRACK_COND =>
            if Payload'Length >= 1 then
               Apply_Track_Cond (Payload);
            end if;
         when MSG_STATUS =>
            if Payload'Length = Status_Length then
               Apply_Status (Payload);
            end if;
         when MSG_PLANNING =>
            Apply_Planning (Payload);
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
      if EVC_Heard and then not Link_Lost
        and then General_Parameters.EVC_Link_Timeout_Ms > 0
      then
         Since_EVC_Ms := Since_EVC_Ms + Dt_Ms;
         if Since_EVC_Ms >= General_Parameters.EVC_Link_Timeout_Ms then
            Enter_Link_Lost;
         end if;
      end if;

      DMI_Ack.Tick (Dt_Ms);
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

            when BTN_Ack =>
               if DMI_Ack.Current_Valid then
                  Queue_Driver_Action
                    (ACTION_ACK,
                     Unsigned_16
                       (DMI_Ack.Ack_Kind_T'Pos (DMI_Ack.Current_Kind)));
                  if DMI_Ack.Current_Kind in
                    DMI_Ack.Fixed_Text | DMI_Ack.Plain_Text
                    | DMI_Ack.System_Status | DMI_Ack.NTC_Text
                  then
                     DMI_Text_Messages.Acknowledge;
                  end if;
                  DMI_Ack.Acknowledge_Current;
               end if;

            when BTN_Msg_Up =>
               DMI_Text_Messages.Scroll_Up;

            when BTN_Msg_Down =>
               DMI_Text_Messages.Scroll_Down;

            when BTN_Tunnel_Toggle =>
               DMI_Status.Tunnel_Toggled_On :=
                 not DMI_Status.Tunnel_Toggled_On;
               Queue_Driver_Action
                 (ACTION_TUNNEL_TOGGLE,
                  (if DMI_Status.Tunnel_Toggled_On then 1 else 0));

            when BTN_Geo_Toggle =>
               DMI_Status.Geo_Toggled_On := not DMI_Status.Geo_Toggled_On;
               Queue_Driver_Action
                 (ACTION_GEO_TOGGLE,
                  (if DMI_Status.Geo_Toggled_On then 1 else 0));

            when BTN_Zoom_In =>
               DMI_Planning.Zoom_In;

            when BTN_Zoom_Out =>
               DMI_Planning.Zoom_Out;

            when BTN_F1 => DMI_Windows.Open (DMI_Windows.W_Main);
            when BTN_F2 => DMI_Windows.Open (DMI_Windows.W_Override);
            when BTN_F3 => DMI_Windows.Open (DMI_Windows.W_Data_View);
            when BTN_F4 => DMI_Windows.Open (DMI_Windows.W_Special);
            when BTN_F5 => DMI_Windows.Open (DMI_Windows.W_Settings);

            when BTN_Window_Close =>
               DMI_Windows.Close_Top;

            when DMI_Buttons.Menu_Button_T =>
               DMI_Windows.Button_Pressed
                 (DMI_Buttons.Button_ID_T'Pos (ID)
                  - DMI_Buttons.Button_ID_T'Pos (DMI_Buttons.BTN_Menu_1) + 1);
               -- the window content changed; re-register its buttons
               Update_Buttons;
         end case;
      end loop;
      Drain_Window_Actions;
   end Tick;

   ------------
   -- Render --
   ------------

   procedure Render is
   begin
      -- planning area Y/Z strips stay background (touch screen layout)
      Display.Screen.Fill_Area (Display.Get_Area (Display.Y),
                                General_Parameters.Background_Color);
      Display.Screen.Fill_Area (Display.Get_Area (Display.Z),
                                General_Parameters.Background_Color);

      Display.B_Area.Draw;
      Display.A_Area.Draw;
      Display.C_Area.Draw;
      Display.D_Area.Draw;
      Display.E_Area.Draw;
      Display.F_Area.Draw;
      Display.G_Area.Draw;

      -- sub-level windows draw over the D/F/G area (5.3.1.1.5)
      DMI_Windows.Render;
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

   -- Move the pending sounds into the outbox
   procedure Collect_Sounds is
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
   end Collect_Sounds;

   procedure Flush_Outbox
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class) is
   begin
      Collect_Sounds;
      if Outbox_Filled > 0 then
         Ada.Streams.Write (Stream.all, Outbox (1 .. Outbox_Filled));
         Outbox_Filled := 0;
      end if;
   end Flush_Outbox;

   -----------------
   -- Take_Outbox --
   -----------------

   procedure Take_Outbox (Buffer : out Stream_Element_Array;
                          Last   : out Stream_Element_Offset) is
      Count : Stream_Element_Offset;
   begin
      Collect_Sounds;
      Count := Stream_Element_Offset'Min (Outbox_Filled, Buffer'Length);
      Buffer (Buffer'First .. Buffer'First + Count - 1) := Outbox (1 .. Count);
      Last := Buffer'First + Count - 1;
      Outbox_Filled := 0;
   end Take_Outbox;

end DMI_Core;
