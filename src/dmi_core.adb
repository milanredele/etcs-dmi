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
with DMI_ATO;
with DMI_Buttons;
with DMI_Conditions;
with DMI_Data_Entry;
with DMI_Driver_Data;
with DMI_Flash;
with DMI_Planning;
with DMI_Radio_Data;
with DMI_Sounds;
with DMI_Status;
with DMI_System_Status;
with DMI_System_Version;
with DMI_Text_Messages;
with DMI_Train_Data;
with DMI_VBC;
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
   ACTION_ACK           : constant Unsigned_8 := 2; -- see Queue_Driver_Ack
   ACTION_TUNNEL_TOGGLE : constant Unsigned_8 := 3;
   ACTION_GEO_TOGGLE    : constant Unsigned_8 := 4;
   ACTION_ATO_ENGAGE    : constant Unsigned_8 := 13;
   ACTION_ATO_SKIP      : constant Unsigned_8 := 14;
   -- a button of the Main window ended a system status message
   ACTION_MAIN_WINDOW_BUTTON : constant Unsigned_8 := 16;
   -- DMI 5.6.1.1: the desk isolation key (MSG_DESK_INPUT input 2)
   ACTION_ISOLATE : constant Unsigned_8 := 20;

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

   -- The acknowledgement names the request it answers: the kind and,
   -- for a text message, the message id (0 otherwise)
   procedure Queue_Driver_Ack (Kind    : DMI_Ack.Ack_Kind_T;
                               Text_ID : Natural) is
      Payload : Stream_Element_Array (1 .. Driver_Ack_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, ACTION_ACK);
      Put_U16 (Payload, Offset, Unsigned_16 (DMI_Ack.Ack_Kind_T'Pos (Kind)));
      Put_U16 (Payload, Offset, Unsigned_16 (Text_ID mod 2 ** 16));
      Queue_Message (MSG_DRIVER_ACTION, Payload);
   end Queue_Driver_Ack;

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
      -- ack button. The acknowledgement areas are outside the window
      -- column D/F/G, so the button stays available under a menu window.
      -- No request is displayed during the Start Up sequence or over a
      -- data entry / validation window (11.7.1.8, 11.7.1.9, see Tick).
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
            -- 5.4.1.3: up-type unless stated otherwise; 8.2.3.1.4: with
            -- MO10 (acknowledgement for SR) a delay-type button
            -- (5.3.2.6.6, DMI_Buttons)
            (if DMI_Ack.Current_Kind = Mode_Change
               and then DMI_Ack.Current_Mode = SDI.M_SR
             then DMI_Buttons.Delay_Type
             else DMI_Buttons.Up_Type));
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
                                 DMI_Buttons.Down_Repeat_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_Msg_Up);
      end if;
      if not Window_Open
        and then not DMI_Text_Messages.Ack_Pending
        and then DMI_Text_Messages.Can_Scroll_Down
      then
         DMI_Buttons.Set_Active (BTN_Msg_Down,
                                 Display.Get_Area (Display.E11),
                                 DMI_Buttons.Down_Repeat_Type);
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

      -- Planning area zoom (8.3.10): sensitive areas 40x30; disabled at
      -- the range ends (5.3.2.7.5). D9 is the bottom left corner of area
      -- D and D12 the top left one (Figure 85), so both enlargements
      -- reach into D1 and stay inside area D.
      if not Window_Open and then DMI_Planning.Displayed
        and then DMI_Planning.Can_Zoom_In
      then
         -- 8.3.10.4: enlarged by 15 cells above D9
         declare
            D9_Pos : constant Display.Position_T :=
              Display.Get_Area (Display.D9).Position;
         begin
            DMI_Buttons.Set_Active
              (BTN_Zoom_In,
               ((D9_Pos.X, D9_Pos.Y - 15), 40, 30),
               DMI_Buttons.Up_Type);
         end;
      else
         DMI_Buttons.Set_Inactive (BTN_Zoom_In);
      end if;
      if not Window_Open and then DMI_Planning.Displayed
        and then DMI_Planning.Can_Zoom_Out
      then
         -- 8.3.10.5: enlarged by 15 cells below D12
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

      -- DMI 8.5.2.5 / 8.5.2.6: G1 is the ATO engage button while ATO02
      -- is displayed and the ATO disengage button while ATO03 or ATO04
      -- is displayed, an enabled up-type button
      if not Window_Open and then DMI_ATO.Engage_Button then
         DMI_Buttons.Set_Active (BTN_ATO_Engage,
                                 Display.Get_Area (Display.G1),
                                 DMI_Buttons.Up_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_ATO_Engage);
      end if;

      -- DMI 8.5.8.5: G5 is an enabled delay-type button to request or
      -- revoke the skip stopping point while ATO17 or ATO19 is displayed
      if not Window_Open and then DMI_ATO.Skip_Button then
         DMI_Buttons.Set_Active (BTN_ATO_Skip,
                                 Display.Get_Area (Display.G5),
                                 DMI_Buttons.Delay_Type);
      else
         DMI_Buttons.Set_Inactive (BTN_ATO_Skip);
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
         -- 11.7.2.2: [Close] is disabled during the Start Up sequence
         if DMI_Windows.Close_Enabled then
            DMI_Buttons.Set_Active (BTN_Window_Close,
                                    DMI_Windows.Close_Button_Area,
                                    DMI_Buttons.Up_Type);
         else
            DMI_Buttons.Set_Inactive (BTN_Window_Close);
         end if;
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

      --  The train data of the flexible train data entry (DMI 11.3.9,
      --  Table 40); the four items of a dedicated keyboard go as the
      --  ERTMS/ETCS variables of SUBSET-026 chapter 7
      procedure Send_Train_Data_Msg is
         Payload : Stream_Element_Array
           (1 .. Stream_Element_Offset (Driver_Data_Train_Length));
         Offset  : Stream_Element_Offset := Payload'First;

         function Byte (Value : Natural) return Unsigned_8 is
           (Unsigned_8 (Natural'Min (Value, 255)));
      begin
         Put_U8 (Payload, Offset, 2);
         Put_U16 (Payload, Offset,
                  Unsigned_16 (Natural'Min (Train_Length, 65535)));
         Put_U16 (Payload, Offset,
                  Unsigned_16 (Natural'Min (Brake_Pct, 65535)));
         Put_U16 (Payload, Offset,
                  Unsigned_16 (Natural'Min (Max_Speed, 65535)));
         Put_U8 (Payload, Offset, Byte (DMI_Train_Data.Category_CD));
         Put_U16 (Payload, Offset,
                  Unsigned_16 (Natural'Min (DMI_Train_Data.Category_Other,
                                            65535)));
         Put_U8 (Payload, Offset, Byte (DMI_Train_Data.Axle_Load_Value));
         Put_U8 (Payload, Offset, Byte (DMI_Train_Data.Airtight_Value));
         Put_U8 (Payload, Offset, Byte (DMI_Train_Data.Gauge_Value));
         Queue_Message (MSG_DRIVER_DATA, Payload);
      end Send_Train_Data_Msg;

      ACTION_START           : constant Unsigned_8 := 5;
      ACTION_OVERRIDE        : constant Unsigned_8 := 6;
      ACTION_SH_REQUEST      : constant Unsigned_8 := 7;
      ACTION_EXIT_SH         : constant Unsigned_8 := 8;
      ACTION_ADHESION        : constant Unsigned_8 := 9;
      ACTION_TRAIN_INTEGRITY : constant Unsigned_8 := 10;
      ACTION_LEVEL_SELECTED  : constant Unsigned_8 := 11;
      ACTION_NON_LEADING     : constant Unsigned_8 := 12;
      ACTION_ATO_SELECTOR    : constant Unsigned_8 := 15;
      ACTION_SM              : constant Unsigned_8 := 17;
      ACTION_BMM_INHIBITION  : constant Unsigned_8 := 18;
      ACTION_MAINTAIN_SH     : constant Unsigned_8 := 19;

      --  MSG_DRIVER_DATA kind 4: the GSM-R network ID, or no name when
      --  the driver elects to modify it (dmi_protocol.ads)
      procedure Send_GSMR_Network_Msg (Selected : Boolean) is
         Name : constant DMI_Radio_Data.Name_T :=
           (if Selected then DMI_Radio_Data.GSMR_Network
            else (Length => 0, Text => (others => ' ')));
         Payload : Stream_Element_Array
           (1 .. 2 + Stream_Element_Offset (Name.Length));
         Offset : Stream_Element_Offset := Payload'First;
      begin
         Put_U8 (Payload, Offset, 4);
         Put_U8 (Payload, Offset, Unsigned_8 (Name.Length));
         for I in 1 .. Name.Length loop
            Put_U8 (Payload, Offset,
                    Unsigned_8 (Wide_Character'Pos (Name.Text (I)) mod 256));
         end loop;
         Queue_Message (MSG_DRIVER_DATA, Payload);
      end Send_GSMR_Network_Msg;

      --  MSG_DRIVER_DATA kind 5: the RBC contact information
      procedure Send_RBC_Data_Msg (Choice : Natural) is
         use DMI_Radio_Data;
         Payload : Stream_Element_Array
           (1 .. Stream_Element_Offset (Driver_Data_RBC_Length));
         Offset  : Stream_Element_Offset := Payload'First;
         Entered_Data : constant Boolean :=
           Choice = RBC_Choice_T'Pos (DMI_Radio_Data.Entered);
         --  the phone number: its digits only, at most 16
         Phone  : Stream_Element_Array (1 .. RBC_Phone_Max) :=
           (others => 0);
         Count  : Natural := 0;
         ID     : Natural := 0;
      begin
         if Entered_Data then
            for I in 1 .. RBC_Phone.Length loop
               if RBC_Phone.Text (I) in '0' .. '9'
                 and then Count < RBC_Phone_Max
               then
                  Count := Count + 1;
                  Phone (Stream_Element_Offset (Count)) :=
                    Stream_Element (Wide_Character'Pos (RBC_Phone.Text (I)));
               end if;
            end loop;
            --  the value as entered, with the range of the input field
            --  (0 .. 16 777 214, digits only; anything else counts 0)
            for I in 1 .. RBC_ID.Length loop
               if RBC_ID.Text (I) in '0' .. '9' and then ID <= 16_777_214
               then
                  ID := ID * 10
                    + (Wide_Character'Pos (RBC_ID.Text (I))
                       - Wide_Character'Pos ('0'));
               end if;
            end loop;
            ID := Natural'Min (ID, 16_777_214);
         end if;
         Put_U8 (Payload, Offset, 5);
         Put_U8 (Payload, Offset, Unsigned_8 (Choice mod 256));
         Put_U32 (Payload, Offset, Unsigned_32 (ID));
         Put_U8 (Payload, Offset, Unsigned_8 (Count));
         for B of Phone loop
            Put_U8 (Payload, Offset, Unsigned_8 (B));
         end loop;
         Queue_Message (MSG_DRIVER_DATA, Payload);
      end Send_RBC_Data_Msg;

      --  MSG_DRIVER_DATA kinds 8 and 9: the validated VBC code
      procedure Send_VBC_Msg (Kind : Unsigned_8; Code : Natural) is
         Payload : Stream_Element_Array
           (1 .. Stream_Element_Offset (Driver_Data_VBC_Length));
         Offset  : Stream_Element_Offset := Payload'First;
      begin
         Put_U8 (Payload, Offset, Kind);
         Put_U32 (Payload, Offset,
                  Unsigned_32 (Natural'Min (Code, VBC_Code_Max)));
         Queue_Message (MSG_DRIVER_DATA, Payload);
      end Send_VBC_Msg;

      --  MSG_DRIVER_DATA kinds 6 and 7: one byte
      procedure Send_Byte_Data (Kind : Unsigned_8; Value : Natural) is
         Payload : Stream_Element_Array
           (1 .. Stream_Element_Offset (Driver_Data_Byte_Length));
         Offset  : Stream_Element_Offset := Payload'First;
      begin
         Put_U8 (Payload, Offset, Kind);
         Put_U8 (Payload, Offset, Unsigned_8 (Value mod 256));
         Queue_Message (MSG_DRIVER_DATA, Payload);
      end Send_Byte_Data;
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
               Send_Train_Data_Msg;
            when Send_SR_Data =>
               Send_Numeric_Data (3, SR_Speed, SR_Dist, 0, 2);
            when ATO_Selector_Set =>
               Queue_Driver_Action (ACTION_ATO_SELECTOR, Unsigned_16 (Arg));
            when Send_GSMR_Network =>
               Send_GSMR_Network_Msg (Selected => Arg /= 0);
            when Send_RBC_Data =>
               Send_RBC_Data_Msg (Arg);
            when Send_Radio_Network_Type =>
               Send_Byte_Data (6, Arg);
            when Send_Mission_One_Radio =>
               Send_Byte_Data (7, Arg);
            when SM_Request =>
               Queue_Driver_Action (ACTION_SM, Unsigned_16 (Arg mod 3));
            when BMM_Inhibition =>
               Queue_Driver_Action (ACTION_BMM_INHIBITION,
                                    Unsigned_16 (Arg mod 2));
            when Maintain_SH =>
               Queue_Driver_Action (ACTION_MAINTAIN_SH);
            when Send_Set_VBC =>
               Send_VBC_Msg (8, Arg);
            when Send_Remove_VBC =>
               Send_VBC_Msg (9, Arg);
         end case;
      end loop;
   end Drain_Window_Actions;

   Outbox        : Stream_Element_Array (1 .. Outbox_Size);
   Outbox_Filled : Stream_Element_Offset := 0;

   -- DMI 8.2.2.3.4.1 / 8.2.2.3.6: a brake intervention caused by a pending
   -- acknowledgement of a level, a mode or a text message is released by
   -- that acknowledgement, and then no Sinfo is played. Only the EVC knows
   -- why it brakes, so it says so (MSG_STATUS, brake = 3); the last cause
   -- reported before the release counts.
   Brake_For_Pending_Ack : Boolean := False;

   -- Internal failure containment, see Enter_Failure
   Has_Failed : Boolean := False;

   -- EVC link supervision (General_Parameters.EVC_Link_Timeout_Ms)
   EVC_Heard    : Boolean := False; -- supervision arms with the first message
   Link_Lost    : Boolean := False;
   Since_EVC_Ms : Natural := 0;

   -- The keys of the DMI unit on the driver's desk (MSG_DESK_INPUT).
   -- They belong to the DMI unit, not to the EVC's picture: a link loss
   -- does not release them, DMI_Core.Initialise does.
   --  8.6.1.6 / 8.6.1.7: the Settings key is an up-type button; it went
   --  down while the default window was displayed
   Desk_Settings_Down : Boolean := False;
   --  5.6.1.1 / 5.3.2.6.6: the isolation key is a delay-type button;
   --  it has been held for Desk_Isolation_Ms (saturating)
   Desk_Isolation_Down : Boolean := False;
   Desk_Isolation_Ms   : Natural := 0;
   Delay_Type_Ms       : constant := 2_000; -- 5.3.2.6.6: 2 seconds

   -- MSG_SETTINGS: the values the UI was told last, and whether it must
   -- be told again although nothing changed (DMI_Core.Initialise, the
   -- EVC link (re)starts: a UI may have (re)connected with it)
   Settings_Due   : Boolean := True;
   Sent_Luminance : General_Parameters.Display_Luminance_T :=
     General_Parameters.Display_Luminance_T'First;
   Sent_Volume    : General_Parameters.Loudspeaker_Volume_T :=
     General_Parameters.Loudspeaker_Volume_T'First;
   Sent_Isolated  : Boolean := False;

   -----------------
   -- Reset_State --
   -----------------

   -- Forget everything the EVC and the driver provided
   procedure Reset_State is
   begin
      Brake_For_Pending_Ack := False;
      DMI_Ack.Reset;
      DMI_ATO.Reset;
      DMI_Sounds.Set_ATO_Warning (False);
      DMI_Conditions.Reset;
      DMI_Driver_Data.Reset;
      DMI_Radio_Data.Reset;
      DMI_Planning.Reset;
      DMI_Status.Reset;
      DMI_System_Status.Reset;
      DMI_System_Version.Reset;
      DMI_Text_Messages.Reset;
      DMI_VBC.Reset;
      DMI_Windows.Close_All;
      TTI_Was_Displayed := False;
      SDI.Mode := SDI.M_SB;
      SDI.Acknowledgment_Mode := (Valid => False);
      SDI.Override := False;
      SDI.Level := SDI.Unknown;
      SDI.Level_Announcement := (Valid => False);
      SDI.National_Name := (others => <>);
      User_Settings.Speed_Info_Visible := False;
      Track_Ahead_Free.Show := False;
      Speed_And_Distance.Reset;
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
      Has_Failed := False;
      Reset_State;
      EVC_Heard := False;
      Link_Lost := False;
      Since_EVC_Ms := 0;
      Desk_Settings_Down := False;
      Desk_Isolation_Down := False;
      Desk_Isolation_Ms := 0;
      -- DMI 5.2.2.2 / 5.2.3.2: the luminance and the volume are not reset
      -- here. They are settings of the DMI unit stored on board
      -- (General_Parameters), not data of the mission: the last stored
      -- values are used again, and the Volume and Brightness windows
      -- propose them (11.7.1.4). Before the driver stored any, they are
      -- the median of the range. The UI is told them once more.
      Settings_Due := True;
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
      -- the link (re)starts: tell the UI the settings again (MSG_SETTINGS)
      if not EVC_Heard or else Link_Lost then
         Settings_Due := True;
      end if;
      EVC_Heard := True;
      Since_EVC_Ms := 0;
      Link_Lost := False; -- the messages rebuild the picture
   end Note_EVC_Message;

   function EVC_Link_Lost return Boolean is (Link_Lost);

   -------------------
   -- Enter_Failure --
   -------------------

   procedure Enter_Failure is
   begin
      -- only plain assignments: the state may be inconsistent and must
      -- not be walked
      Has_Failed := True;
      Outbox_Filled := 0;
   end Enter_Failure;

   function Failed return Boolean is (Has_Failed);

   -----------------------
   -- Message appliers  --
   -----------------------

   procedure Apply_Speed_State (Payload : Stream_Element_Array) is
      use Speed_And_Distance;

      Offset : Stream_Element_Offset := Payload'First;

      -- The wire carries u16 speeds and a u32 distance, the model types
      -- are narrower, and a failed range check cannot be handled here
      -- (no exception propagation on the target): every field is clamped
      -- before it is converted. The speeds stop at Speed_T'Last, the
      -- maximum of the largest dial (DMI 8.2.1.1.3 a); the specification
      -- defines no presentation for a speed beyond every dial. Speeds
      -- above the configured dial are kept: the dial mapping rests them at
      -- the end of the scale (Speed_Dial.Speed_To_Angle) while the digital
      -- values show them.
      function Next_Speed return Speed_T is
         Raw : constant Unsigned_16 := Get_U16 (Payload, Offset);
      begin
         return Speed_T (Unsigned_16'Min (Raw, Unsigned_16 (Speed_T'Last)));
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
      Status     : constant Unsigned_8 := Get_U8 (Payload, Offset);
      MRDT       : constant Unsigned_8 := Get_U8 (Payload, Offset);
   begin
      Set_CSM_Target_Info ((Flags and 2) /= 0);
      Set_Speed_Params ((Vperm    => V_Perm,
                         Vtarget  => V_Target,
                         Vwsl     => V_Wsl,
                         Vsbi     => V_Sbi,
                         Vrelease => V_Release,
                         Vrelease_Exists => (Flags and 1) /= 0));
      Set_Speed (V_Cur);

      -- Monitoring and status are taken as a pair; Set_Supervision makes
      -- it one that exists (chapter 7), whatever is sent. Undefined codes
      -- fall to the most restrictive presentation.
      Set_Supervision
        ((case Monitoring is
             when 0      => CSM,
             when 1      => TSM,
             when others => RSM),
         (case Status is
             when 0      => NoS,
             when 1      => IndS,
             when 2      => OvS,
             when 3      => WaS,
             when others => IntS),
         MRDT_T (MRDT));

      -- DMI 8.2.2.2.4 / 8.2.2.2.6: the distance to target digital shows up
      -- to 5 digits, rounded to 10 m, so Distance_T'Last (99990 m) is the
      -- largest value that can be presented; longer distances show it.
      -- The bar has its own limit of 1000 m (8.2.2.1.6).
      Set_Distance_To_Target
        (Distance_T (Unsigned_32'Min (D_Target, Unsigned_32 (Distance_T'Last))));

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

      -- DMI 11.7.2.4 Table 49 S0 -> S1: the Start Up dialogue sequence is
      -- engaged when the conditions to initiate a start of mission are
      -- fulfilled. They are the on-board's (SUBSET-026 5.4.1.2) and the
      -- EVC reports them in MSG_ONBOARD; the mode alone does not engage
      -- the sequence (it cannot: S0 waits in SB for a communication
      -- session to end).

      if SDI.Mode /= Old_Mode then
         -- DMI 8.2.2.4.5: entering a Table 15 mode toggles the objects off
         if SDI.Mode in SDI.M_OS | SDI.M_SR | SDI.M_SH then
            User_Settings.Speed_Info_Visible := False;
         end if;
         -- S2 depends on the mode (unless in AD, DMI 7.2.3.3 / 7.4.4.3)
         Speed_And_Distance.Mode_Changed;
         -- 15.1.1.2: the system status messages that the new mode does
         -- not display end
         DMI_System_Status.Mode_Changed (SDI.Mode);
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

      -- DMI 8.2.3.2.9: the abbreviation of the National System, when the
      -- message carries one (Handle_Message checked its length); the
      -- short form means "no name"
      SDI.National_Name := (others => <>);
      if Offset <= Payload'Last then
         declare
            Len : constant Natural :=
              Natural'Min (Natural (Get_U8 (Payload, Offset)),
                           SDI.National_Name_Max);
         begin
            for I in 1 .. Len loop
               exit when Offset > Payload'Last;
               SDI.National_Name.Text (I) :=
                 Wide_Character'Val (Natural (Get_U8 (Payload, Offset)));
               SDI.National_Name.Length := I;
            end loop;
         end;
      end if;
   end Apply_Mode_Level;

   -- MSG_MODE_LEVEL is the fixed part alone, or the fixed part, name_len
   -- and exactly name_len bytes of a name that is not too long
   -- (dmi_protocol.ads)
   function Mode_Level_Length_OK (Payload : Stream_Element_Array)
                                  return Boolean is
      Name_Len : Natural;
   begin
      if Payload'Length = Mode_Level_Length then
         return True;
      elsif Payload'Length < Mode_Level_Length + 1 then
         return False;
      end if;
      Name_Len :=
        Natural (Payload (Payload'First + Mode_Level_Length));
      return Name_Len <= Mode_Level_Name_Max
        and then Payload'Length
                   = Stream_Element_Offset (Mode_Level_Length + 1 + Name_Len);
   end Mode_Level_Length_OK;

   --  MSG_VBC_LIST: the VBCs stored on-board, by their set code. The
   --  whole message is checked before anything is taken
   --  (dmi_protocol.ads).
   procedure Apply_VBC_List (Payload : Stream_Element_Array) is
      Offset : Stream_Element_Offset := Payload'First;
      Count  : Natural;
      Codes  : DMI_VBC.Code_List_T := (others => 0);
   begin
      if Payload'Length < 1
        or else Payload'Length > 1 + VBC_List_Max * VBC_Code_Length
      then
         return;
      end if;
      Count := Natural (Get_U8 (Payload, Offset));
      if Count > VBC_List_Max
        or else Payload'Length
                  /= Stream_Element_Offset (1 + Count * VBC_Code_Length)
      then
         return;
      end if;
      for I in 1 .. Count loop
         declare
            Code : constant Unsigned_32 := Get_U32 (Payload, Offset);
         begin
            if Code > VBC_Code_Max then
               return;
            end if;
            Codes (I) := Natural (Code);
         end;
      end loop;
      DMI_VBC.Set_List (Count, Codes);
   end Apply_VBC_List;

   --  MSG_ONBOARD: the on-board state behind the enabling conditions of
   --  Tables 33 to 36 and behind the dialogue sequences of 11.7. Every
   --  byte value is accepted; a code outside the documented ones takes
   --  the reading given in dmi_protocol.ads.
   procedure Apply_Onboard (Payload : Stream_Element_Array) is
      use DMI_Conditions;
      Offset : Stream_Element_Offset := Payload'First;

      Data     : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Session_Raw : constant Unsigned_8 := Get_U8 (Payload, Offset);
      RBC      : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Train    : constant Unsigned_8 := Get_U8 (Payload, Offset);
      National : constant Unsigned_8 := Get_U8 (Payload, Offset);
      SOM      : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Wait_Raw : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Start    : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Radio    : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Radio_Wait_Raw : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Answer   : constant Unsigned_8 := Get_U8 (Payload, Offset);

      function Bit (Byte : Unsigned_8; Index : Natural) return Boolean is
        ((Byte and Shift_Left (Unsigned_8'(1), Index)) /= 0);
   begin
      DMI_Conditions.Driver_ID_Valid    := Bit (Data, 0);
      DMI_Conditions.Train_Data_Valid   := Bit (Data, 1);
      DMI_Conditions.Level_Valid        := Bit (Data, 2);
      DMI_Conditions.TRN_Valid          := Bit (Data, 3);
      DMI_Conditions.RBC_Contact_Valid  := Bit (Data, 4);
      DMI_Conditions.Position_Valid     := Bit (Data, 5);
      DMI_Conditions.Consist_Length     := Bit (Data, 6);
      DMI_Conditions.Consist_Front_Zero := Bit (Data, 7);

      DMI_Conditions.Session :=
        (case Session_Raw is
            when 1      => Establishing,
            when 2      => Exists,
            when 3      => Exists_Above_2_2,
            when others => No_Session);

      DMI_Conditions.Train_Data_Acked     := Bit (RBC, 0);
      DMI_Conditions.Pending_Stop         := Bit (RBC, 1);
      DMI_Conditions.RBC_Transition       := Bit (RBC, 2);
      DMI_Conditions.Length_Confirmed     := Bit (RBC, 3);
      DMI_Conditions.Consist_Length_Acked := Bit (RBC, 4);

      DMI_Conditions.Standstill         := Bit (Train, 0);
      DMI_Conditions.Override_Speed_OK  := Bit (Train, 1);
      DMI_Conditions.Non_Leading_Signal := Bit (Train, 2);
      DMI_Conditions.Passive_Shunting   := Bit (Train, 3);
      DMI_Conditions.BMM_Inhibit_Active := Bit (Train, 4);

      DMI_Conditions.NV_Driver_ID_Running := Bit (National, 0);
      DMI_Conditions.NV_Adhesion          := Bit (National, 1);
      DMI_Conditions.VBC_Room             := Bit (National, 2);
      DMI_Conditions.VBC_Stored           := Bit (National, 3);

      DMI_Conditions.Start_Of_Mission :=
        (case SOM is
            when 1      => Awaiting_Session_End,
            when 2      => Initiated,
            when others => No_Mission_Start);

      DMI_Conditions.Waiting :=
        (case Wait_Raw is
            when 0      => Nothing,
            when 1      => Radio_Network,
            when 3      => Authorisation,
            when 4      => Shunting_Answer,
            when 5      => SM_Answer,
            when others => RBC_Answer);

      DMI_Conditions.Start_Pending := Start /= 0;

      --  every value of the two bit fields is defined
      DMI_Conditions.Radio_Type :=
        Radio_Type_T'Val (Natural (Radio and 3));
      DMI_Conditions.Radio_Installed :=
        Radio_Installed_T'Val (Natural (Shift_Right (Radio, 2) and 3));
      DMI_Conditions.FRMCS_Registered  := Bit (Radio, 4);
      DMI_Conditions.GSMR_Registered   := Bit (Radio, 5);
      DMI_Conditions.One_Radio_Yes     := Bit (Radio, 6);
      DMI_Conditions.RBC_Contact_Known := Bit (Radio, 7);

      DMI_Conditions.Radio_Wait :=
        (case Radio_Wait_Raw is
            when 0      => No_Radio_Wait,
            when 1      => Network_List,
            when others => Network_Registration);

      DMI_Conditions.Request_Authorised := Answer = 1;

      DMI_Windows.Onboard_State_Changed;
   end Apply_Onboard;

   --  MSG_RADIO_NETWORKS: the list of GSM-R networks for the GSM-R
   --  network ID window. The whole message is checked before anything
   --  is taken (dmi_protocol.ads): a count above the limit, a name
   --  length of 0 or above the limit, or a length that is not exactly
   --  what the count and the names describe drop the message.
   procedure Apply_Radio_Networks (Payload : Stream_Element_Array) is
      use DMI_Radio_Data;
      Offset : Stream_Element_Offset := Payload'First;
      Count  : Natural;
      List   : Name_List_T;
   begin
      if Payload'Length < 1
        or else Payload'Length > Radio_Networks_Max_Length
      then
         return;
      end if;
      Count := Natural (Get_U8 (Payload, Offset));
      if Count > Max_Networks then
         return;
      end if;
      for I in 1 .. Count loop
         if Offset > Payload'Last then
            return;
         end if;
         declare
            Len : constant Natural := Natural (Get_U8 (Payload, Offset));
         begin
            if Len = 0 or else Len > Max_Name
              or else Payload'Last - Offset + 1
                        < Stream_Element_Offset (Len)
            then
               return;
            end if;
            List (I).Length := Len;
            for C in 1 .. Len loop
               List (I).Text (C) :=
                 Wide_Character'Val (Natural (Get_U8 (Payload, Offset)));
            end loop;
         end;
      end loop;
      if Offset /= Payload'Last + 1 then
         return;  -- bytes beyond the described list
      end if;
      Set_List (Count, List);
      DMI_Windows.Radio_Networks_Received;
   end Apply_Radio_Networks;

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
      use type DMI_Text_Messages.Class_T;
   begin
      if Payload'Length /= Text_Header_Length + Natural (Length) then
         return;
      end if;
      for I in Text'Range loop
         Text (I) := Wide_Character'Val (Natural (Get_U8 (Payload, Offset)));
      end loop;
      DMI_Text_Messages.Put
        (ID           => Natural (ID),
         -- 8.2.3.4.7 a: the first group contains the system status
         -- messages, so the flag is not asked for them (SDI-9)
         First_Group  => (Flags and 2) /= 0
                         or else Class = DMI_Text_Messages.System_Status,
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
               -- the area is decided by DMI_Status (8.2.3.5.3)
               List (Used) := (ID   => Natural (ID),
                               Kind => Natural (Kind),
                               Slot => 0);
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
            when 1 | 3  => Shown,
            when others => Shown_Ack_Required);
      Old_For_Pending_Ack : constant Boolean := Brake_For_Pending_Ack;
      use type SDI.Mode_T;
   begin
      Brake := New_Brake;
      if New_Brake /= Old_Brake then
         case New_Brake is
            when Shown_Ack_Required =>
               -- 8.2.2.3.4 / 5.4: brake release acknowledgement
               DMI_Ack.Request_Brake_Release_Ack;
            when None =>
               if Old_Brake = Shown_Ack_Required then
                  DMI_Ack.Cancel (DMI_Ack.Brake_Release);
               elsif Old_Brake = Shown and then not Old_For_Pending_Ack then
                  -- 8.2.2.3.6: released without any driver's
                  -- acknowledgement, "on ST01 or on any other DMI object"
                  DMI_Sounds.Play (DMI_Sounds.Sinfo);
               end if;
            when Shown =>
               if Old_Brake = Shown_Ack_Required then
                  DMI_Ack.Cancel (DMI_Ack.Brake_Release);
               end if;
         end case;
      end if;
      Brake_For_Pending_Ack := Brake_Raw = 3;

      Radio :=
        (case Radio_Raw is
            when 1      => Connection_Up,
            when 2      => Connection_Lost,
            when others => No_Connection);
      Slippery_Rail := Adhesion /= 0;
      BMM_Inhibited := BMM /= 0;
      Reversing_Permitted := Reversing /= 0;
      declare
         Old_Direction : constant SM_Direction_T := SM_Direction;
      begin
         SM_Direction :=
           (case SM_Dir is
               when 1      => Forward,
               when 2      => Backward,
               when others => None);
         -- 8.2.3.10.4: Sinfo when the authorised direction changes (from
         -- one direction to the other; its appearing and its removal are
         -- not a change of direction)
         if SM_Direction /= Old_Direction
           and then SM_Direction /= None
           and then Old_Direction /= None
         then
            DMI_Sounds.Play (DMI_Sounds.Sinfo);
         end if;
      end;

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

   -- The planning message has a variable length and its content is
   -- under the control of the sender. It is decoded in two passes: the
   -- first one only walks the three counted lists and proves that the
   -- counts describe the payload exactly, the second one reads the
   -- values. A message that fails the first pass, or whose header is not
   -- valid, is ignored as a whole and the planning information stays as
   -- it was; nothing is read beyond the payload and nothing is half
   -- updated. The elements are checked one by one in DMI_Planning.
   procedure Apply_Planning (Payload : Stream_Element_Array) is
      use DMI_Planning;

      Header_Size : constant := 8; -- four u16
      Entry_Size  : constant array (1 .. 3) of Stream_Element_Offset :=
        (Planning_Gradient_Entry_Length,
         Planning_Speed_Entry_Length,
         Planning_Order_Entry_Length);

      function Well_Formed return Boolean is
         Left : Stream_Element_Offset := Payload'Length;
      begin
         if Left < Header_Size then
            return False;
         end if;
         Left := Left - Header_Size;
         for List in Entry_Size'Range loop
            if Left < 1 then
               return False; -- the count itself is missing
            end if;
            declare
               Count : constant Stream_Element_Offset :=
                 Stream_Element_Offset
                   (Payload (Payload'Last - Left + 1));
            begin
               Left := Left - 1;
               if Left < Count * Entry_Size (List) then
                  return False; -- count larger than the payload
               end if;
               Left := Left - Count * Entry_Size (List);
            end;
         end loop;
         return Left = 0; -- no unexplained bytes after the last list
      end Well_Formed;

      Offset : Stream_Element_Offset := Payload'First;

      MA     : Unsigned_16;
      Ind    : Unsigned_16;
      Advice : Unsigned_16;
      Ceil   : Unsigned_16;
      Count  : Unsigned_8;
   begin
      if not Well_Formed then
         return;
      end if;
      MA := Get_U16 (Payload, Offset);
      Ind := Get_U16 (Payload, Offset);
      Advice := Get_U16 (Payload, Offset);
      Ceil := Get_U16 (Payload, Offset);
      if Natural (Ceil) > Max_Speed_Kmh then
         return; -- no such ceiling speed (8.2.1.1.3); 8.3.7.7 needs it
      end if;

      Begin_Update;

      -- gradients
      Count := Get_U8 (Payload, Offset);
      for I in 1 .. Natural (Count) loop
         declare
            Start : constant Unsigned_16 := Get_U16 (Payload, Offset);
            Raw   : constant Unsigned_8 := Get_U8 (Payload, Offset);
            Value : constant Integer :=
              (if Raw >= 128 then Integer (Raw) - 256 else Integer (Raw));
         begin
            Add_Gradient (Natural (Start), Value);
         end;
      end loop;

      -- speed profile discontinuities
      Count := Get_U8 (Payload, Offset);
      for I in 1 .. Natural (Count) loop
         declare
            Dist : constant Unsigned_16 := Get_U16 (Payload, Offset);
            Spd  : constant Unsigned_16 := Get_U16 (Payload, Offset);
         begin
            Add_Speed (Dist_M        => Natural (Dist),
                       Speed         => Natural (Spd and 16#7FFF#),
                       Is_Ind_Target => (Spd and 16#8000#) /= 0);
         end;
      end loop;

      -- orders and announcements
      Count := Get_U8 (Payload, Offset);
      for I in 1 .. Natural (Count) loop
         declare
            Sym  : constant Unsigned_8 := Get_U8 (Payload, Offset);
            Dist : constant Unsigned_16 := Get_U16 (Payload, Offset);
         begin
            Add_Order (Natural (Sym), Natural (Dist));
         end;
      end loop;

      -- 16#FFFF# means none; every other value is a distance and is not
      -- folded into a shorter one: beyond the range it is simply not
      -- on the scale
      MA_Dist_M := Natural (MA);
      Indication_Valid := Ind /= 16#FFFF#;
      Indication_Dist_M := Natural (Ind);
      Advice_Valid := Advice /= 16#FFFF#;
      Advice_Dist_M := Natural (Advice);
      Ceiling_Speed := Natural (Ceil);
      Valid := True;
   end Apply_Planning;

   --  MSG_ATO: the information of the ERTMS/ATO on-board (DMI 8.5) and
   --  the ATO selector position. The length is checked against the two
   --  counts (name, stopping points) before anything is read; a message
   --  that does not match is ignored as a whole and the information
   --  stays as it was. Every byte value is accepted; a code outside the
   --  documented ones takes the reading given in dmi_protocol.ads.
   procedure Apply_ATO (Payload : Stream_Element_Array) is
      use DMI_ATO;

      function Well_Formed return Boolean is
         Name_Length : Stream_Element_Offset;
         Count       : Stream_Element_Offset;
      begin
         if Payload'Length < ATO_Fixed_Length then
            return False;
         end if;
         Name_Length := Stream_Element_Offset
           (Payload (Payload'First + ATO_Header_Length - 1));
         if Name_Length > ATO_Max_Name
           or else Payload'Length < ATO_Fixed_Length + Name_Length
         then
            return False;
         end if;
         Count := Stream_Element_Offset
           (Payload (Payload'First + ATO_Header_Length + Name_Length));
         return Payload'Length
           = ATO_Fixed_Length + Name_Length + Count * ATO_Stop_Entry_Length;
      end Well_Formed;

      Offset : Stream_Element_Offset := Payload'First;

      function Flag return Boolean is (Get_U8 (Payload, Offset) /= 0);
   begin
      if not Well_Formed then
         return;
      end if;
      declare
         Selector_Raw : constant Unsigned_8 := Get_U8 (Payload, Offset);
         Status_Raw   : constant Unsigned_8 := Get_U8 (Payload, Offset);
         Warning_Now  : constant Boolean := Flag;
         Location_Raw : constant Unsigned_8 := Get_U8 (Payload, Offset);
         Accuracy_Raw : constant Unsigned_8 := Get_U8 (Payload, Offset);
         Dwell_Raw    : constant Unsigned_16 := Get_U16 (Payload, Offset);
         Hold_Now     : constant Boolean := Flag;
         Doors_Raw    : constant Unsigned_8 := Get_U8 (Payload, Offset);
         Skip_Raw     : constant Unsigned_8 := Get_U8 (Payload, Offset);
         Advice_Raw   : constant Unsigned_16 := Get_U16 (Payload, Offset);
         Coasting_Now : constant Boolean := Flag;
         Hour         : constant Unsigned_8 := Get_U8 (Payload, Offset);
         Minute       : constant Unsigned_8 := Get_U8 (Payload, Offset);
         Second       : constant Unsigned_8 := Get_U8 (Payload, Offset);
         Length       : constant Unsigned_8 := Get_U8 (Payload, Offset);
         Count        : Unsigned_8;
      begin
         Selector :=
           (case Selector_Raw is
               when 1      => Stand_By,
               when 2      => On,
               when others => Unknown);
         Status :=
           (case Status_Raw is
               when 1      => Selected,
               when 2      => Ready,
               when 3      => Engaged,
               when 4      => Disengaging,
               when 5      => Failure,
               when others => No_Status);
         Warning := Warning_Now;
         At_Stopping_Point := Location_Raw = 1;
         Accuracy :=
           (case Accuracy_Raw is
               when 1      => Overshoot,
               when 2      => Undershoot,
               when 3      => Accurate,
               when others => No_Accuracy);
         Dwell_Valid := Natural (Dwell_Raw) <= Max_Dwell_S;
         Dwell_S := (if Dwell_Valid then Natural (Dwell_Raw) else 0);
         Train_Hold := Hold_Now;
         Doors :=
           (case Doors_Raw is
               when 1      => Open_Both,
               when 2      => Open_Left,
               when 3      => Open_Right,
               when 4      => Doors_Open,
               when 5      => Close_Request,
               when 6      => Closing,
               when 7      => Doors_Closed,
               when others => No_Doors);
         Skip :=
           (case Skip_Raw is
               when 1      => Inactive,
               when 2      => By_Trackside,
               when 3      => By_Driver,
               when others => No_Skip);
         Advice_Valid := Advice_Raw <= 400;
         Advice_Speed := (if Advice_Valid then Natural (Advice_Raw) else 0);
         Coasting := Coasting_Now;
         ETA_Valid := Hour <= 23 and then Minute <= 59 and then Second <= 59;
         ETA_H := (if ETA_Valid then Natural (Hour) else 0);
         ETA_M := (if ETA_Valid then Natural (Minute) else 0);
         ETA_S := (if ETA_Valid then Natural (Second) else 0);
         -- Well_Formed: Length <= ATO_Max_Name = Max_Name
         Name_Length := Natural'Min (Natural (Length), Max_Name);
         Name := (others => ' ');
         for I in 1 .. Name_Length loop
            Name (I) := Wide_Character'Val (Natural (Get_U8 (Payload, Offset)));
         end loop;

         -- 8.5.3: the stopping points replace the previous ones
         Count := Get_U8 (Payload, Offset);
         DMI_Planning.Clear_Stopping_Points;
         for I in 1 .. Natural (Count) loop
            DMI_Planning.Add_Stopping_Point
              (Natural (Get_U16 (Payload, Offset)));
         end loop;
      end;
      -- 8.5.1.7: S2 while the ERTMS/ATO on-board requests the warning
      -- sound. Choice: it is not gated on the ATO selector; a warning
      -- the on-board requests is never suppressed by the DMI.
      DMI_Sounds.Set_ATO_Warning (DMI_ATO.Warning);
   end Apply_ATO;

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

   -- MSG_DESK_INPUT: the keys of the DMI unit on the driver's desk
   procedure Apply_Desk_Input (Payload : Stream_Element_Array) is
      Offset  : Stream_Element_Offset := Payload'First;
      Input   : constant Unsigned_8 := Get_U8 (Payload, Offset);
      Pressed : constant Unsigned_8 := Get_U8 (Payload, Offset);
   begin
      if Pressed > 1 then
         return; -- neither down nor up: nothing known, ignored
      end if;
      case Input is
         when DESK_SETTINGS =>
            -- 8.6.1.6: the desk button for the Settings window, with the
            -- rules of the F5 button (8.6.1.4, 8.6.1.7): it is a button
            -- of the default window, an up-type button. While a
            -- sub-level window is displayed only that window responds to
            -- the driver (5.3.1.1.5), so the key does nothing then; this
            -- covers the windows that cannot be left (Start Up before
            -- S10, 11.7.2.2; the waiting steps, 11.7.3.2) and the data
            -- entry processes (11.7.1), which the key never interrupts.
            -- Choice: the key opens the window when it comes up, like
            -- the up-type F5 (5.3.2.6.2), and only when the default
            -- window was displayed both when it went down and when it
            -- came up. No 'click' sound: the key itself gives the
            -- tactile feedback (5.3.2.2.1 b).
            if Pressed = 1 then
               Desk_Settings_Down := not DMI_Windows.Is_Open;
            else
               if Desk_Settings_Down and then not DMI_Windows.Is_Open then
                  DMI_Windows.Open (DMI_Windows.W_Settings);
               end if;
               Desk_Settings_Down := False;
            end if;
         when DESK_ISOLATION =>
            -- 5.6.1.1: the means to isolate the on-board equipment. Its
            -- location and form are implementation dependent
            -- (5.6.1.1.1); SUBSET-026 4.7.1.3 makes the device part of
            -- the DMI and 4.7.2 offers the input in every mode, also
            -- while the desk is closed (4.4.7.1.4). Choice: a key on the
            -- desk rather than a button on the screen, so that it does
            -- not depend on the window displayed, and a delay-type key
            -- (5.3.2.6.6: released after at least 2 s) because the
            -- isolation cannot be undone from the DMI (SUBSET-026
            -- 4.4.3.1.3). The EVC decides; the DMI shows the mode it
            -- reports.
            if Pressed = 1 then
               if not Desk_Isolation_Down then
                  Desk_Isolation_Down := True;
                  Desk_Isolation_Ms := 0;
               end if;
            else
               if Desk_Isolation_Down
                 and then Desk_Isolation_Ms >= Delay_Type_Ms
               then
                  Queue_Driver_Action (ACTION_ISOLATE);
               end if;
               Desk_Isolation_Down := False;
               Desk_Isolation_Ms := 0;
            end if;
         when others =>
            null; -- reserved inputs: ignored
      end case;
   end Apply_Desk_Input;

   procedure Handle_Message (The_Type : Msg_Type_T;
                             Payload  : Stream_Element_Array) is
   begin
      if Has_Failed then
         return;
      end if;

      if The_Type in MSG_SPEED_STATE | MSG_MODE_LEVEL | MSG_TEXT
                   | MSG_TEXT_REMOVE | MSG_TRACK_COND | MSG_STATUS
                   | MSG_PLANNING | MSG_ONBOARD | MSG_ATO
                   | MSG_SYSTEM_STATUS | MSG_RADIO_NETWORKS
                   | MSG_SYSTEM_VERSION | MSG_VBC_LIST
      then
         Note_EVC_Message;
      end if;

      case The_Type is
         when MSG_SPEED_STATE =>
            if Payload'Length = Speed_State_Length then
               Apply_Speed_State (Payload);
            end if;
         when MSG_MODE_LEVEL =>
            if Mode_Level_Length_OK (Payload) then
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
         when MSG_ONBOARD =>
            if Payload'Length = Onboard_Length then
               Apply_Onboard (Payload);
            end if;
         when MSG_PLANNING =>
            Apply_Planning (Payload);
         when MSG_ATO =>
            Apply_ATO (Payload);
         when MSG_SYSTEM_STATUS =>
            if Payload'Length = System_Status_Length then
               declare
                  Offset : Stream_Element_Offset := Payload'First;
                  Number : constant Unsigned_8 := Get_U8 (Payload, Offset);
                  Event  : constant Unsigned_8 := Get_U8 (Payload, Offset);
               begin
                  DMI_System_Status.Event (Natural (Number), Natural (Event));
               end;
            end if;
         when MSG_RADIO_NETWORKS =>
            Apply_Radio_Networks (Payload);
         when MSG_SYSTEM_VERSION =>
            if Payload'Length = System_Version_Length then
               DMI_System_Version.Set
                 (Natural (Payload (Payload'First)),
                  Natural (Payload (Payload'First + 1)));
            end if;
         when MSG_VBC_LIST =>
            Apply_VBC_List (Payload);
         when MSG_POINTER =>
            if Payload'Length = Pointer_Length then
               Update_Buttons; -- make sure hit testing sees current state
               Apply_Pointer (Payload);
            end if;
         when MSG_DESK_INPUT =>
            if Payload'Length = Desk_Input_Length then
               Apply_Desk_Input (Payload);
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
      if Has_Failed then
         return;
      end if;

      -- 5.3.2.6.6: the time the desk isolation key is held
      if Desk_Isolation_Down then
         Desk_Isolation_Ms :=
           Natural'Min (Delay_Type_Ms,
                        Desk_Isolation_Ms
                        + Natural'Min (Delay_Type_Ms, Dt_Ms));
      end if;

      if EVC_Heard and then not Link_Lost
        and then General_Parameters.EVC_Link_Timeout_Ms > 0
      then
         Since_EVC_Ms := Since_EVC_Ms + Dt_Ms;
         if Since_EVC_Ms >= General_Parameters.EVC_Link_Timeout_Ms then
            Enter_Link_Lost;
         end if;
      end if;

      -- chapter 15: the 30 s of the system status messages, before the
      -- text message store enters its waiting requests
      DMI_System_Status.Tick (Dt_Ms);
      DMI_Text_Messages.Tick;
      -- DMI 11.2.1.6: movement of the hour glass ST05
      DMI_Conditions.Tick
        (Dt_Ms, Radio_Step => DMI_Windows.Radio_Step_Displayed);
      -- DMI 11.7.1.7 and Table 48: an enabling condition of an open data
      -- entry / validation window that is not fulfilled anymore stops
      -- the process and shows the parent window
      DMI_Windows.Check_Enabling_Conditions;
      -- DMI 5.1.1.3.2: before DMI_Ack.Tick, which restarts the phase for
      -- a request it displays now
      DMI_Flash.Tick (Dt_Ms);
      -- DMI 10.3.2.5 a: the 2 s delay of the multi-tap keyboards, before
      -- the button activations of this tick are processed
      DMI_Data_Entry.Tick (Dt_Ms);
      declare
         -- DMI 11.7.1.8: an acknowledgement required during the Start Up
         -- dialogue sequence is displayed 1 s after its end
         Hold : Boolean := DMI_Windows.In_Start_Up;
      begin
         -- DMI 11.7.1.9 (5.4.1.11): after Start Up a required
         -- acknowledgement stops the data entry / validation process, the
         -- parent window is displayed and the acknowledgement appears 1 s
         -- afterwards. The reverse case cannot arise: the buttons leading
         -- to a data entry window are disabled while an acknowledgement
         -- is required (11.2.1.4 and following, DMI_Windows.Menu_Def).
         if not Hold and then DMI_Ack.Pending_Count > 0
           and then DMI_Windows.Entry_Open
         then
            DMI_Windows.Stop_Entry;
            Hold := True;
         end if;
         DMI_Ack.Tick (Dt_Ms, Hold);
      end;
      Update_Buttons;
      DMI_Buttons.Tick (Dt_Ms);
      while DMI_Buttons.Pop_Activation (ID) loop
         -- Table 68: "as soon as any button in the main window is
         -- selected" ends a system status message; [Close] is a button of
         -- the window too. The on-board learns it (action 16) before the
         -- request of the button itself.
         if ID in BTN_Window_Close | DMI_Buttons.Menu_Button_T
           and then DMI_Windows.Is_Open
           and then DMI_Windows."=" (DMI_Windows.Top, DMI_Windows.W_Main)
         then
            declare
               Ended : Boolean;
            begin
               DMI_System_Status.Main_Window_Button (Ended);
               if Ended then
                  Queue_Driver_Action (ACTION_MAIN_WINDOW_BUTTON);
               end if;
            end;
         end if;
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
                  declare
                     Kind    : constant DMI_Ack.Ack_Kind_T :=
                       DMI_Ack.Current_Kind;
                     Is_Text : constant Boolean :=
                       Kind in DMI_Ack.Text_Kind_T;
                     -- message ids are u16 on the wire (MSG_TEXT)
                     Text_ID : constant Natural :=
                       (if Is_Text then DMI_Ack.Current_Text_ID else 0);
                     Catalogue : constant Boolean :=
                       Is_Text and then DMI_System_Status.Owns (Text_ID);
                     Number : Natural := 0;
                  begin
                     if Is_Text then
                        -- 8.2.3.4.8 c: this message, not another one
                        DMI_Text_Messages.Acknowledge (Text_ID);
                     end if;
                     if Catalogue then
                        -- "Text acknowledged" ends it (Table 68)
                        DMI_System_Status.Acknowledged (Text_ID, Number);
                     end if;
                     -- the EVC learns exactly what was acknowledged: a
                     -- catalogue message by its entry number
                     -- (dmi_protocol.ads, MSG_DRIVER_ACTION)
                     Queue_Driver_Ack
                       (Kind,
                        (if Catalogue then 16#8000# + Number mod 16#8000#
                         else Text_ID));
                     DMI_Ack.Acknowledge_Current;
                  end;
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

            when BTN_ATO_Engage =>
               -- 8.5.2.5 / 8.5.2.6: the request the displayed status
               -- stands for; nothing when the button is gone meanwhile
               if DMI_ATO.Engage_Button then
                  Queue_Driver_Action
                    (ACTION_ATO_ENGAGE,
                     (if DMI_ATO.Engage_Requested then 1 else 0));
               end if;

            when BTN_ATO_Skip =>
               -- 8.5.8.5: request (ATO17) or revoke (ATO19) the skip
               if DMI_ATO.Skip_Button then
                  Queue_Driver_Action
                    (ACTION_ATO_SKIP,
                     (if DMI_ATO.Skip_Requested then 1 else 0));
               end if;

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
      if Has_Failed then
         Display.Screen.Fill (General_Parameters.Background_Color);
         Display.B_Area.Draw_Failure;
         return;
      end if;

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

   -- Queue MSG_SETTINGS when the UI must learn the settings: they
   -- changed since it was told, or it must be told again. It waits for
   -- room in the outbox rather than being dropped.
   procedure Collect_Settings is
      use type General_Parameters.Display_Luminance_T;
      use type General_Parameters.Loudspeaker_Volume_T;
      use type SDI.Mode_T;
      Luminance : constant General_Parameters.Display_Luminance_T :=
        General_Parameters.Display_Luminance;
      Volume    : constant General_Parameters.Loudspeaker_Volume_T :=
        General_Parameters.Loudspeaker_Volume;
      -- 8.2.3.1.2.2: the mode IS is indicated by the isolation device
      Isolated  : constant Boolean := SDI.Mode = SDI.M_IS;
   begin
      if (Settings_Due
          or else Luminance /= Sent_Luminance
          or else Volume /= Sent_Volume
          or else Isolated /= Sent_Isolated)
        and then Outbox_Filled + Header_Length + Settings_Length
                   <= Outbox'Last
      then
         declare
            Payload : Stream_Element_Array (1 .. Settings_Length);
            Offset  : Stream_Element_Offset := Payload'First;
         begin
            Put_U8 (Payload, Offset, Unsigned_8 (Luminance));
            Put_U8 (Payload, Offset, Unsigned_8 (Volume));
            Put_U8 (Payload, Offset, (if Isolated then 1 else 0));
            Queue_Message (MSG_SETTINGS, Payload);
         end;
         Sent_Luminance := Luminance;
         Sent_Volume := Volume;
         Sent_Isolated := Isolated;
         Settings_Due := False;
      end if;
   end Collect_Settings;

   -- Move the pending sounds into the outbox
   procedure Collect_Sounds is
      The_Sound : DMI_Sounds.Sound_T;
   begin
      -- a sound is only taken when the outbox has room for it, so that
      -- it waits in DMI_Sounds instead of being dropped by
      -- Queue_Message; this matters for the S2 stop (14.3.3.2)
      while Outbox_Filled + Header_Length + Sound_Length <= Outbox'Last
        and then DMI_Sounds.Pop (The_Sound)
      loop
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
      -- the settings first: a new volume applies to the sounds after it
      Collect_Settings;
      Collect_Sounds;
      if Outbox_Filled > 0 then
         Ada.Streams.Write (Stream.all, Outbox (1 .. Outbox_Filled));
         Outbox_Filled := 0;
      end if;
   end Flush_Outbox;

   -----------------
   -- Take_Outbox --
   -----------------

   procedure Take_Outbox (Buffer      : out Stream_Element_Array;
                          Last        : out Stream_Element_Offset;
                          With_Sounds : Boolean := True) is
      Count : Stream_Element_Offset;
   begin
      if With_Sounds then
         Collect_Settings;
         Collect_Sounds;
      end if;
      Count := Stream_Element_Offset'Min (Outbox_Filled, Buffer'Length);
      Buffer (Buffer'First .. Buffer'First + Count - 1) := Outbox (1 .. Count);
      Last := Buffer'First + Count - 1;
      Outbox_Filled := 0;
   end Take_Outbox;

end DMI_Core;
