--  ETCS DMI
--  Regression support implementation.

pragma Ada_2012;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Streams; use Ada.Streams;
with Ada.Text_IO; use Ada.Text_IO;
with Display.Screen.Files;
with DMI_Core;
with DMI_Driver_Data;
with DMI_Protocol; use DMI_Protocol;
with EVC_Supervision;
with Interfaces; use Interfaces;
with Supplementary_Driving_Info;

package body Test_Support is

   Failures : Natural := 0;

   -- the wrapper's EVC: supervision status it last sent
   EVC_Status : EVC_Supervision.Status_T := EVC_Supervision.NoS;
   Checks   : Natural := 0;

   ---------------------------------------------------------------------
   -- The wrapper's EVC: on-board state of MSG_ONBOARD
   ---------------------------------------------------------------------

   type Onboard_Model_T is record
      Standstill         : Boolean := True;
      Session            : Natural := 0;
      Train_Data_Acked   : Boolean := False;
      Pending_Stop       : Boolean := False;
      RBC_Transition     : Boolean := False;
      Length_Confirmed   : Boolean := False;
      Consist_Acked      : Boolean := False;
      Position_LRBG      : Boolean := False;
      RBC_Contact        : Boolean := False;
      Consist_Length     : Boolean := False;
      Consist_Front_Zero : Boolean := False;
      Override_Speed     : Boolean := True;
      Non_Leading        : Boolean := False;
      Passive_Shunting   : Boolean := False;
      BMM_Active         : Boolean := False;
      NV_Driver_ID_Running : Boolean := False;
      NV_Adhesion        : Boolean := True;
      VBC_Room           : Boolean := False;
      VBC_Stored         : Boolean := False;
      In_S0              : Boolean := False;
      Waiting            : Natural := 0;
      Start_Pending      : Boolean := False;
      Radio_Type         : Natural := 0;
      Radio_Installed    : Natural := 0;
      FRMCS_Registered   : Boolean := False;
      GSMR_Registered    : Boolean := False;
      One_Radio_Yes      : Boolean := False;
      RBC_Contact_Known  : Boolean := False;
      Radio_Wait         : Natural := 0;
      Authorised         : Boolean := False;
   end record;

   Onboard : Onboard_Model_T;

   -- The last MSG_MODE_LEVEL the wrapper's EVC sent. It is kept because
   -- the EVC resends it when the driver selects a level: the level of
   -- the on-board is the driver's (SUBSET-026 5.4.3.2 S2) and Table 33
   -- asks for its value, so it has to come back from the EVC.
   type Mode_Level_T is record
      Mode          : Natural := 0;
      Level         : Natural := 0;
      Mode_Ack      : Natural := 16#FF#;
      Level_Ann     : Natural := 16#FF#;
      Level_Ann_Ack : Boolean := False;
      Override      : Boolean := False;
      TAF           : Boolean := False;
      LSSMA         : Natural := 16#FFFF#;
      --  the National System's abbreviation (8.2.3.2.9); 0: the 9 byte
      --  form of the message
      Name_Len      : Natural := 0;
      Name          : String (1 .. Mode_Level_Name_Max) := (others => ' ');
   end record;
   Last_ML   : Mode_Level_T;
   -- A mode has been sent since the last Reset: before that the EVC has
   -- said nothing, so there is no start of mission either
   Mode_Sent : Boolean := False;

   ---------------------------------------------------------------------
   -- Outbox of the DMI, accumulated here
   ---------------------------------------------------------------------
   --  The wrapper's EVC has to see the driver's actions (a 'Start'
   --  request stays pending until it answers, Table 33 #1) and the
   --  checks below have to see them too, so the outbox is drained into
   --  this buffer and read from here.

   Outbox      : Stream_Element_Array (1 .. 8 * DMI_Core.Outbox_Size);
   Outbox_Last : Stream_Element_Offset := 0;

   --  Set while a level selection of this pump still has to be reported
   Level_Changed : Boolean := False;

   procedure Scan_Actions (Buffer : Stream_Element_Array;
                           Last   : Stream_Element_Offset) is
      Offset : Stream_Element_Offset := Buffer'First;
   begin
      while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last loop
         declare
            The_Type : constant Msg_Type_T :=
              Msg_Type_T (Get_U8 (Buffer, Offset));
            Length   : constant Stream_Element_Offset :=
              Stream_Element_Offset (Get_U32 (Buffer, Offset));
            Next     : constant Stream_Element_Offset := Offset + Length;
         begin
            exit when Next - 1 > Last;
            if The_Type = MSG_DRIVER_ACTION
              and then Length >= Stream_Element_Offset (Driver_Action_Length)
            then
               declare
                  Action : constant Unsigned_8 := Get_U8 (Buffer, Offset);
                  Arg    : constant Unsigned_16 := Get_U16 (Buffer, Offset);
               begin
                  if Action = 5 then
                     --  start of mission: pending until the EVC answers
                     --  with a mode (Table 33 #1)
                     Onboard.Start_Pending := True;
                  elsif Action = 11 and then Arg in 2 .. 5 then
                     --  the driver selected a level: the on-board stores
                     --  it and reports it back (SUBSET-026 5.4.3.2 S2)
                     Last_ML.Level := Natural (Arg);
                     Level_Changed := True;
                  end if;
               end;
            end if;
            Offset := Next;
         end;
      end loop;
   end Scan_Actions;

   procedure Pump (With_Sounds : Boolean := True) is
      Buffer : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
      Last   : Stream_Element_Offset;
      Room   : Stream_Element_Offset;
   begin
      DMI_Core.Take_Outbox (Buffer, Last, With_Sounds);
      if Last < Buffer'First then
         return;
      end if;
      Scan_Actions (Buffer, Last);
      Room := Stream_Element_Offset'Min (Last, Outbox'Last - Outbox_Last);
      if Room > 0 then
         Outbox (Outbox_Last + 1 .. Outbox_Last + Room) :=
           Buffer (Buffer'First .. Buffer'First + Room - 1);
         Outbox_Last := Outbox_Last + Room;
      end if;
   end Pump;

   --  The scenario runs its own EVC: the wrapper keeps quiet
   External_EVC_Used : Boolean := False;

   --  What was sent last, so that the wrapper only talks when the
   --  picture changes (the scenarios rely on silence to let the link
   --  supervision time out)
   Last_Onboard      : Stream_Element_Array (1 .. Onboard_Length) :=
     (others => 0);
   Last_Onboard_Sent : Boolean := False;

   procedure External_EVC (On : Boolean := True) is
   begin
      External_EVC_Used := On;
   end External_EVC;

   procedure Send_Onboard_Raw
     (Data, Session, RBC, Train, National, SOM, Waiting, Start_Pending
        : Interfaces.Unsigned_8;
      Radio, Radio_Wait, Answer : Interfaces.Unsigned_8 := 0)
   is
      Payload : Stream_Element_Array (1 .. Onboard_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Data);
      Put_U8 (Payload, Offset, Session);
      Put_U8 (Payload, Offset, RBC);
      Put_U8 (Payload, Offset, Train);
      Put_U8 (Payload, Offset, National);
      Put_U8 (Payload, Offset, SOM);
      Put_U8 (Payload, Offset, Waiting);
      Put_U8 (Payload, Offset, Start_Pending);
      Put_U8 (Payload, Offset, Radio);
      Put_U8 (Payload, Offset, Radio_Wait);
      Put_U8 (Payload, Offset, Answer);
      Last_Onboard := Payload;
      Last_Onboard_Sent := True;
      --  the scenario drives MSG_ONBOARD itself from here on
      External_EVC_Used := True;
      DMI_Core.Handle_Message (MSG_ONBOARD, Payload);
   end Send_Onboard_Raw;

   --  Build the message from the model and from what the DMI has sent
   --  this EVC, and hand it to the DMI. Force = False sends it only when
   --  something changed.
   procedure Emit_Onboard (Force : Boolean := True) is
      use type Supplementary_Driving_Info.Mode_T;
      function Flag (Condition : Boolean; Mask : Unsigned_8)
                     return Unsigned_8 is
        (if Condition then Mask else 0);
      In_SB : constant Boolean :=
        Supplementary_Driving_Info.Mode = Supplementary_Driving_Info.M_SB;

      Built  : Stream_Element_Array (1 .. Onboard_Length);
      Offset : Stream_Element_Offset := Built'First;

      procedure Build_Onboard
        (Data, Session, RBC, Train, National, SOM, Waiting, Start_Pending,
         Radio, Radio_Wait, Answer : Unsigned_8) is
      begin
         Put_U8 (Built, Offset, Data);
         Put_U8 (Built, Offset, Session);
         Put_U8 (Built, Offset, RBC);
         Put_U8 (Built, Offset, Train);
         Put_U8 (Built, Offset, National);
         Put_U8 (Built, Offset, SOM);
         Put_U8 (Built, Offset, Waiting);
         Put_U8 (Built, Offset, Start_Pending);
         Put_U8 (Built, Offset, Radio);
         Put_U8 (Built, Offset, Radio_Wait);
         Put_U8 (Built, Offset, Answer);
      end Build_Onboard;
   begin
      if External_EVC_Used
        or else (not Force and then not Last_Onboard_Sent)
      then
         --  the wrapper's EVC does not start talking by itself: before
         --  its first message the link has never been up
         return;
      end if;
      Build_Onboard
        (Data =>
           --  the driver's data the DMI has sent this EVC; the level is
           --  the one the driver selected
           Flag (DMI_Driver_Data.Driver_ID_Entered, 1)
           or Flag (DMI_Driver_Data.Train_Data_Entered, 2)
           or Flag (Last_ML.Level in 2 .. 5, 4)   -- L0, NTC, L1, L2
           or Flag (DMI_Driver_Data.TRN_Entered, 8)
           or Flag (Onboard.RBC_Contact, 16)
           or Flag (Onboard.Position_LRBG, 32)
           or Flag (Onboard.Consist_Length, 64)
           or Flag (Onboard.Consist_Front_Zero, 128),
         Session => Unsigned_8 (Onboard.Session mod 256),
         RBC =>
           Flag (Onboard.Train_Data_Acked, 1)
           or Flag (Onboard.Pending_Stop, 2)
           or Flag (Onboard.RBC_Transition, 4)
           or Flag (Onboard.Length_Confirmed, 8)
           or Flag (Onboard.Consist_Acked, 16),
         Train =>
           Flag (Onboard.Standstill, 1)
           or Flag (Onboard.Override_Speed, 2)
           or Flag (Onboard.Non_Leading, 4)
           or Flag (Onboard.Passive_Shunting, 8)
           or Flag (Onboard.BMM_Active, 16),
         National =>
           Flag (Onboard.NV_Driver_ID_Running, 1)
           or Flag (Onboard.NV_Adhesion, 2)
           or Flag (Onboard.VBC_Room, 4)
           or Flag (Onboard.VBC_Stored, 8),
         --  Table 49 S0: this EVC has no session to wait for unless the
         --  scenario asks for one; the conditions to initiate a start of
         --  mission are fulfilled while the mode it sent is SB
         SOM => (if not Mode_Sent then 0
                 elsif Onboard.In_S0 then 1
                 elsif In_SB then 2 else 0),
         Waiting => Unsigned_8 (Onboard.Waiting mod 256),
         Start_Pending => (if Onboard.Start_Pending then 1 else 0),
         Radio =>
           Unsigned_8 (Onboard.Radio_Type mod 4)
           or Unsigned_8 ((Onboard.Radio_Installed mod 4) * 4)
           or Flag (Onboard.FRMCS_Registered, 16)
           or Flag (Onboard.GSMR_Registered, 32)
           or Flag (Onboard.One_Radio_Yes, 64)
           or Flag (Onboard.RBC_Contact_Known, 128),
         Radio_Wait => Unsigned_8 (Onboard.Radio_Wait mod 256),
         Answer => (if Onboard.Authorised then 1 else 0));
      if Force or else not Last_Onboard_Sent
        or else Built /= Last_Onboard
      then
         Last_Onboard := Built;
         Last_Onboard_Sent := True;
         DMI_Core.Handle_Message (MSG_ONBOARD, Built);
      end if;
   end Emit_Onboard;

   procedure Send_Onboard
     (Standstill       : Boolean := True;
      Session          : Natural := 0;
      Train_Data_Acked : Boolean := False;
      Pending_Stop     : Boolean := False;
      RBC_Transition   : Boolean := False;
      Length_Confirmed : Boolean := False;
      Consist_Acked    : Boolean := False;
      Position_LRBG    : Boolean := False;
      RBC_Contact      : Boolean := False;
      Consist_Length   : Boolean := False;
      Consist_Front_Zero : Boolean := False;
      Override_Speed   : Boolean := True;
      Non_Leading      : Boolean := False;
      Passive_Shunting : Boolean := False;
      BMM_Active       : Boolean := False;
      NV_Driver_ID_Running : Boolean := False;
      NV_Adhesion      : Boolean := True;
      VBC_Room         : Boolean := False;
      VBC_Stored       : Boolean := False;
      In_S0            : Boolean := False;
      Waiting          : Natural := 0;
      Start_Pending    : Boolean := False;
      Radio_Type       : Natural := 0;
      Radio_Installed  : Natural := 0;
      FRMCS_Registered : Boolean := False;
      GSMR_Registered  : Boolean := False;
      One_Radio_Yes    : Boolean := False;
      RBC_Contact_Known : Boolean := False;
      Radio_Wait       : Natural := 0;
      Authorised       : Boolean := False) is
   begin
      Onboard := (Standstill         => Standstill,
                  Session            => Session,
                  Train_Data_Acked   => Train_Data_Acked,
                  Pending_Stop       => Pending_Stop,
                  RBC_Transition     => RBC_Transition,
                  Length_Confirmed   => Length_Confirmed,
                  Consist_Acked      => Consist_Acked,
                  Position_LRBG      => Position_LRBG,
                  RBC_Contact        => RBC_Contact,
                  Consist_Length     => Consist_Length,
                  Consist_Front_Zero => Consist_Front_Zero,
                  Override_Speed     => Override_Speed,
                  Non_Leading        => Non_Leading,
                  Passive_Shunting   => Passive_Shunting,
                  BMM_Active         => BMM_Active,
                  NV_Driver_ID_Running => NV_Driver_ID_Running,
                  NV_Adhesion        => NV_Adhesion,
                  VBC_Room           => VBC_Room,
                  VBC_Stored         => VBC_Stored,
                  In_S0              => In_S0,
                  Waiting            => Waiting,
                  Start_Pending      => Start_Pending,
                  Radio_Type         => Radio_Type,
                  Radio_Installed    => Radio_Installed,
                  FRMCS_Registered   => FRMCS_Registered,
                  GSMR_Registered    => GSMR_Registered,
                  One_Radio_Yes      => One_Radio_Yes,
                  RBC_Contact_Known  => RBC_Contact_Known,
                  Radio_Wait         => Radio_Wait,
                  Authorised         => Authorised);
      External_EVC_Used := False;
      Emit_Onboard;
   end Send_Onboard;

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
      Brake_Commanded : Boolean := False;
      Status          : Integer := -1;
      MRDT            : Natural := 0)
   is
      use type Supplementary_Driving_Info.Mode_T;
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
      if Status in EVC_Supervision.Status_T then
         EVC_Status := Status;
      else
         EVC_Status := EVC_Supervision.Status
           (Monitoring      => Natural'Min (Monitoring, 2),
            Speed           => V_Cur,
            V_Perm          => V_Perm,
            V_Warning       => V_Wsl,
            V_SBI           => V_Sbi,
            V_Release       => V_Release,
            Brake_Commanded => Brake_Commanded,
            In_AD           => Supplementary_Driving_Info.Mode
                                 = Supplementary_Driving_Info.M_AD,
            Previous        => EVC_Status);
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
      Put_U8 (Payload, Offset, Unsigned_8 (EVC_Status));
      Put_U8 (Payload, Offset, Unsigned_8 (MRDT mod 256));
      DMI_Core.Handle_Message (MSG_SPEED_STATE, Payload);
   end Send_Speed_State;

   procedure Reset_EVC_Model is
   begin
      EVC_Status := EVC_Supervision.NoS;
      Onboard := (others => <>);
      Mode_Sent := False;
      Last_ML := (others => <>);
      Level_Changed := False;
      Outbox_Last := 0;
      External_EVC_Used := False;
      Last_Onboard_Sent := False;
   end Reset_EVC_Model;

   procedure Send_Speed_State_Raw
     (V_Cur, V_Perm, V_Target, V_Release, V_Sbi, V_Wsl : Interfaces.Unsigned_16;
      D_Target   : Interfaces.Unsigned_32;
      Monitoring : Interfaces.Unsigned_8;
      Dial_Range : Interfaces.Unsigned_8;
      Flags      : Interfaces.Unsigned_8;
      Status     : Interfaces.Unsigned_8 := 0;
      MRDT       : Interfaces.Unsigned_8 := 0)
   is
      Payload : Stream_Element_Array (1 .. Speed_State_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U16 (Payload, Offset, V_Cur);
      Put_U16 (Payload, Offset, V_Perm);
      Put_U16 (Payload, Offset, V_Target);
      Put_U16 (Payload, Offset, V_Release);
      Put_U16 (Payload, Offset, V_Sbi);
      Put_U16 (Payload, Offset, V_Wsl);
      Put_U32 (Payload, Offset, D_Target);
      Put_U8 (Payload, Offset, Monitoring);
      Put_U8 (Payload, Offset, Dial_Range);
      Put_U8 (Payload, Offset, Flags);
      Put_U8 (Payload, Offset, Status);
      Put_U8 (Payload, Offset, MRDT);
      DMI_Core.Handle_Message (MSG_SPEED_STATE, Payload);
   end Send_Speed_State_Raw;

   --  Put Last_ML on the wire as it stands
   procedure Emit_Mode_Level is
      Payload : Stream_Element_Array
        (1 .. Mode_Level_Length
                + (if Last_ML.Name_Len > 0
                   then 1 + Stream_Element_Offset (Last_ML.Name_Len)
                   else 0));
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Last_ML.Mode));
      Put_U8 (Payload, Offset, Unsigned_8 (Last_ML.Level));
      Put_U8 (Payload, Offset, Unsigned_8 (Last_ML.Mode_Ack));
      Put_U8 (Payload, Offset, Unsigned_8 (Last_ML.Level_Ann));
      Put_U8 (Payload, Offset, (if Last_ML.Level_Ann_Ack then 1 else 0));
      Put_U8 (Payload, Offset, (if Last_ML.Override then 1 else 0));
      Put_U8 (Payload, Offset, (if Last_ML.TAF then 1 else 0));
      Put_U16 (Payload, Offset, Unsigned_16 (Last_ML.LSSMA));
      if Last_ML.Name_Len > 0 then
         Put_U8 (Payload, Offset, Unsigned_8 (Last_ML.Name_Len));
         for C of Last_ML.Name (1 .. Last_ML.Name_Len) loop
            Put_U8 (Payload, Offset, Character'Pos (C));
         end loop;
      end if;
      DMI_Core.Handle_Message (MSG_MODE_LEVEL, Payload);
   end Emit_Mode_Level;

   procedure Send_Mode_Level
     (Mode          : Natural;
      Level         : Natural;
      Mode_Ack      : Natural := 16#FF#;
      Level_Ann     : Natural := 16#FF#;
      Level_Ann_Ack : Boolean := False;
      Override      : Boolean := False;
      TAF           : Boolean := False;
      LSSMA         : Natural := 16#FFFF#;
      National_Name : String := "") is
      Name_Len : constant Natural :=
        Natural'Min (National_Name'Length, Mode_Level_Name_Max);
   begin
      --  the EVC answers a 'Start' request with a new mode
      if Mode_Sent and then Mode /= Last_ML.Mode then
         Onboard.Start_Pending := False;
      end if;
      --  SUBSET-026 4.10.1.3: entering SB the on-board sets the status
      --  of the Driver ID, the train data and the train running number
      --  to "invalid"; the level keeps its status. The wrapper's EVC
      --  owns that status and mirrors it in these flags (see
      --  Emit_Onboard); the DMI does not set it itself.
      if Mode = 1 and then (not Mode_Sent or else Last_ML.Mode /= 1) then
         DMI_Driver_Data.Driver_ID_Entered := False;
         DMI_Driver_Data.Train_Data_Entered := False;
         DMI_Driver_Data.TRN_Entered := False;
      end if;
      Last_ML := (Mode, Level, Mode_Ack, Level_Ann, Level_Ann_Ack,
                  Override, TAF, LSSMA, Name_Len, (others => ' '));
      Last_ML.Name (1 .. Name_Len) :=
        National_Name (National_Name'First
                         .. National_Name'First + Name_Len - 1);
      Mode_Sent := True;
      Emit_Mode_Level;
      --  an EVC sends its on-board state in the same cycle as the mode
      Emit_Onboard;
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

   procedure Send_System_Status (Number : Natural; Event : Natural := 0) is
      Payload : Stream_Element_Array (1 .. System_Status_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Number mod 256));
      Put_U8 (Payload, Offset, Unsigned_8 (Event mod 256));
      DMI_Core.Handle_Message (MSG_SYSTEM_STATUS, Payload);
   end Send_System_Status;

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

   procedure Send_Track_Cond_IDs (Items : TC_Item_Array) is
      Payload : Stream_Element_Array
        (1 .. 1 + Stream_Element_Offset (Items'Length) * 2);
      Offset : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Items'Length));
      for I in Items'Range loop
         Put_U8 (Payload, Offset, Unsigned_8 (Items (I).ID));
         Put_U8 (Payload, Offset, Unsigned_8 (Items (I).Kind));
      end loop;
      DMI_Core.Handle_Message (MSG_TRACK_COND, Payload);
   end Send_Track_Cond_IDs;

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

   procedure Send_ATO
     (Selector     : Natural := 2;
      Status       : Natural := 0;
      Warning      : Boolean := False;
      At_Stop      : Boolean := False;
      Accuracy     : Natural := 0;
      Dwell        : Natural := 16#FFFF#;
      Train_Hold   : Boolean := False;
      Doors        : Natural := 0;
      Skip         : Natural := 0;
      Advice_Speed : Natural := 16#FFFF#;
      Coasting     : Boolean := False;
      ETA_H        : Natural := 16#FF#;
      ETA_M, ETA_S : Natural := 0;
      Name         : String := "";
      Stops        : Stop_Array := (1 .. 0 => 0))
   is
      Payload : Stream_Element_Array
        (1 .. Stream_Element_Offset
                (ATO_Fixed_Length + Name'Length
                 + Stops'Length * ATO_Stop_Entry_Length));
      Offset  : Stream_Element_Offset := Payload'First;

      function B (Flag : Boolean) return Unsigned_8 is
        (if Flag then 1 else 0);
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Selector mod 256));
      Put_U8 (Payload, Offset, Unsigned_8 (Status mod 256));
      Put_U8 (Payload, Offset, B (Warning));
      Put_U8 (Payload, Offset, B (At_Stop));
      Put_U8 (Payload, Offset, Unsigned_8 (Accuracy mod 256));
      Put_U16 (Payload, Offset, Unsigned_16 (Dwell mod 65536));
      Put_U8 (Payload, Offset, B (Train_Hold));
      Put_U8 (Payload, Offset, Unsigned_8 (Doors mod 256));
      Put_U8 (Payload, Offset, Unsigned_8 (Skip mod 256));
      Put_U16 (Payload, Offset, Unsigned_16 (Advice_Speed mod 65536));
      Put_U8 (Payload, Offset, B (Coasting));
      Put_U8 (Payload, Offset, Unsigned_8 (ETA_H mod 256));
      Put_U8 (Payload, Offset, Unsigned_8 (ETA_M mod 256));
      Put_U8 (Payload, Offset, Unsigned_8 (ETA_S mod 256));
      Put_U8 (Payload, Offset, Unsigned_8 (Name'Length mod 256));
      for C of Name loop
         Put_U8 (Payload, Offset, Character'Pos (C));
      end loop;
      Put_U8 (Payload, Offset, Unsigned_8 (Stops'Length mod 256));
      for D of Stops loop
         Put_U16 (Payload, Offset, Unsigned_16 (D mod 65536));
      end loop;
      DMI_Core.Handle_Message (MSG_ATO, Payload);
   end Send_ATO;

   procedure Send_Raw (The_Type : Natural; Bytes : Byte_Array) is
      Payload : Stream_Element_Array (1 .. Bytes'Length);
   begin
      for I in Bytes'Range loop
         Payload (Stream_Element_Offset (I - Bytes'First + 1)) :=
           Stream_Element (Bytes (I) mod 256);
      end loop;
      DMI_Core.Handle_Message (Msg_Type_T (The_Type mod 256), Payload);
   end Send_Raw;

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
      --  the EVC hears the driver's actions of this cycle and answers
      --  with its on-board state, as evc_core does. The sounds stay
      --  where they are: the scenarios check them. A scenario with its
      --  own EVC drains the outbox itself.
      if not External_EVC_Used then
         Pump (With_Sounds => False);
         if Level_Changed then
            Level_Changed := False;
            Emit_Mode_Level;
         end if;
         Emit_Onboard (Force => False);
      end if;
      DMI_Core.Render;
   end Step;

   procedure Check_Frame (Name : String) is
      Path   : constant String := Golden_Dir & Name & ".sha256";
      Actual : constant String := Display.Screen.Files.Digest;

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
         Display.Screen.Files.Dump (Golden_Dir & Name & ".actual");
      end if;
      if Ada.Environment_Variables.Exists ("DUMP") then
         Display.Screen.Files.Dump (Golden_Dir & Name & ".actual");
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

   -- Scan the outbox for acknowledgements (DMI_Protocol: action u8 = 2,
   -- kind u16, id u16)
   procedure Take_Acks (Count : out Natural;
                        Kind  : out Natural;
                        ID    : out Natural;
                        Short : out Boolean)
   is
      Buffer : Stream_Element_Array renames Outbox;
      Last   : Stream_Element_Offset;
      Offset : Stream_Element_Offset := Buffer'First;
   begin
      Count := 0;
      Kind := 0;
      ID := 0;
      Short := False;
      Pump;
      Last := Outbox_Last;
      Outbox_Last := 0;
      while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last loop
         declare
            The_Type : constant Msg_Type_T :=
              Msg_Type_T (Get_U8 (Buffer, Offset));
            Length   : constant Stream_Element_Offset :=
              Stream_Element_Offset (Get_U32 (Buffer, Offset));
            Next     : constant Stream_Element_Offset := Offset + Length;
         begin
            exit when Next - 1 > Last;
            if The_Type = MSG_DRIVER_ACTION
              and then Length >= 1
              and then Buffer (Offset) = 2
            then
               Count := Count + 1;
               if Length = Driver_Ack_Length then
                  Offset := Offset + 1;
                  Kind := Natural (Get_U16 (Buffer, Offset));
                  ID := Natural (Get_U16 (Buffer, Offset));
               else
                  Short := True;
               end if;
            end if;
            Offset := Next;
         end;
      end loop;
   end Take_Acks;

   procedure Drain_Outbox is
      Count, Kind, ID : Natural;
      Short : Boolean;
   begin
      Take_Acks (Count, Kind, ID, Short);
   end Drain_Outbox;

   procedure Expect_Ack (Kind : Natural; ID : Natural; What : String) is
      Count, Got_Kind, Got_ID : Natural;
      Short : Boolean;
   begin
      Checks := Checks + 1;
      Take_Acks (Count, Got_Kind, Got_ID, Short);
      if Count /= 1 then
         Fail (What & ": expected one acknowledgement, got"
               & Natural'Image (Count));
      elsif Short then
         Fail (What & ": acknowledgement without text message id");
      elsif Got_Kind /= Kind or else Got_ID /= ID then
         Fail (What & ": expected ack kind" & Natural'Image (Kind)
               & " id" & Natural'Image (ID) & ", got kind"
               & Natural'Image (Got_Kind) & " id" & Natural'Image (Got_ID));
      else
         Pass (What);
      end if;
   end Expect_Ack;

   procedure Expect_No_Ack (What : String) is
      Count, Got_Kind, Got_ID : Natural;
      Short : Boolean;
   begin
      Checks := Checks + 1;
      Take_Acks (Count, Got_Kind, Got_ID, Short);
      if Count /= 0 then
         Fail (What & ": unexpected acknowledgement, kind"
               & Natural'Image (Got_Kind) & " id" & Natural'Image (Got_ID));
      else
         Pass (What);
      end if;
   end Expect_No_Ack;

   procedure Expect_Actions (Action : Natural;
                             Count  : Natural;
                             What   : String)
   is
      Buffer : Stream_Element_Array renames Outbox;
      Last   : Stream_Element_Offset;
      Offset : Stream_Element_Offset := Buffer'First;
      Found  : Natural := 0;
   begin
      Checks := Checks + 1;
      Pump;
      Last := Outbox_Last;
      Outbox_Last := 0;
      while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last loop
         declare
            The_Type : constant Msg_Type_T :=
              Msg_Type_T (Get_U8 (Buffer, Offset));
            Length   : constant Stream_Element_Offset :=
              Stream_Element_Offset (Get_U32 (Buffer, Offset));
            Next     : constant Stream_Element_Offset := Offset + Length;
         begin
            exit when Next - 1 > Last;
            if The_Type = MSG_DRIVER_ACTION
              and then Length >= 1
              and then Natural (Buffer (Offset)) = Action
            then
               Found := Found + 1;
            end if;
            Offset := Next;
         end;
      end loop;
      if Found = Count then
         Pass (What);
      else
         Fail (What & ": expected" & Natural'Image (Count)
               & " driver action(s)" & Natural'Image (Action)
               & ", got" & Natural'Image (Found));
      end if;
   end Expect_Actions;

   procedure Expect_Action (Action : Natural;
                            Arg    : Natural;
                            What   : String)
   is
      Buffer : Stream_Element_Array renames Outbox;
      Last   : Stream_Element_Offset;
      Offset : Stream_Element_Offset := Buffer'First;
      Found  : Natural := 0;
      Got    : Natural := 0;
   begin
      Checks := Checks + 1;
      Pump;
      Last := Outbox_Last;
      Outbox_Last := 0;
      while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last loop
         declare
            The_Type : constant Msg_Type_T :=
              Msg_Type_T (Get_U8 (Buffer, Offset));
            Length   : constant Stream_Element_Offset :=
              Stream_Element_Offset (Get_U32 (Buffer, Offset));
            Next     : constant Stream_Element_Offset := Offset + Length;
         begin
            exit when Next - 1 > Last;
            if The_Type = MSG_DRIVER_ACTION
              and then Length >= Stream_Element_Offset (Driver_Action_Length)
              and then Natural (Buffer (Offset)) = Action
            then
               Found := Found + 1;
               Got := Natural (Buffer (Offset + 1))
                 + 256 * Natural (Buffer (Offset + 2));
            end if;
            Offset := Next;
         end;
      end loop;
      if Found = 1 and then Got = Arg then
         Pass (What);
      else
         Fail (What & ": expected one driver action" & Natural'Image (Action)
               & " with arg" & Natural'Image (Arg) & ", got"
               & Natural'Image (Found) & " (last arg" & Natural'Image (Got)
               & ")");
      end if;
   end Expect_Action;

   procedure Send_System_Version (X, Y : Natural) is
      Payload : constant Stream_Element_Array :=
        (Stream_Element (X mod 256), Stream_Element (Y mod 256));
   begin
      DMI_Core.Handle_Message (MSG_SYSTEM_VERSION, Payload);
   end Send_System_Version;

   procedure Send_VBC_List (Codes : Code_Array) is
      Payload : Stream_Element_Array
        (1 .. 1 + VBC_Code_Length * Stream_Element_Offset (Codes'Length));
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Codes'Length mod 256));
      for C of Codes loop
         Put_U32 (Payload, Offset, Unsigned_32 (C));
      end loop;
      DMI_Core.Handle_Message (MSG_VBC_LIST, Payload);
   end Send_VBC_List;

   procedure Send_Radio_Networks (Names : String) is
      Payload : Stream_Element_Array (1 .. 2 + 2 * Names'Length);
      Last    : Stream_Element_Offset := 1;  -- the count comes first
      Count   : Natural := 0;
      Start   : Positive := Names'First;
   begin
      if Names'Length > 0 then
         for I in Names'First .. Names'Last + 1 loop
            if I > Names'Last or else Names (I) = ',' then
               Count := Count + 1;
               Last := Last + 1;
               Payload (Last) := Stream_Element (I - Start);
               for C in Start .. I - 1 loop
                  Last := Last + 1;
                  Payload (Last) := Character'Pos (Names (C));
               end loop;
               Start := I + 1;
            end if;
         end loop;
      end if;
      Payload (1) := Stream_Element (Count mod 256);
      DMI_Core.Handle_Message (MSG_RADIO_NETWORKS, Payload (1 .. Last));
   end Send_Radio_Networks;

   --  Walk the messages queued for the EVC since the last check; the
   --  outbox is emptied like by the checks above
   generic
      with procedure Visit (The_Type : Msg_Type_T;
                            Payload  : Stream_Element_Array);
   procedure Walk_Outbox;

   procedure Walk_Outbox is
      Buffer : Stream_Element_Array renames Outbox;
      Last   : Stream_Element_Offset;
      Offset : Stream_Element_Offset := Buffer'First;
   begin
      Pump;
      Last := Outbox_Last;
      Outbox_Last := 0;
      while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last loop
         declare
            The_Type : constant Msg_Type_T :=
              Msg_Type_T (Get_U8 (Buffer, Offset));
            Length   : constant Stream_Element_Offset :=
              Stream_Element_Offset (Get_U32 (Buffer, Offset));
            Next     : constant Stream_Element_Offset := Offset + Length;
         begin
            exit when Next - 1 > Last;
            Visit (The_Type, Buffer (Offset .. Next - 1));
            Offset := Next;
         end;
      end loop;
   end Walk_Outbox;

   procedure Expect_Action_Arg (Action : Natural;
                                Arg    : Natural;
                                What   : String) is
      Found : Natural := 0;
      Args  : Natural := 0;
      Got   : Natural := 0;

      procedure Visit (The_Type : Msg_Type_T;
                       Payload  : Stream_Element_Array) is
         Offset : Stream_Element_Offset := Payload'First;
      begin
         if The_Type = MSG_DRIVER_ACTION
           and then Payload'Length >= Driver_Action_Length
           and then Natural (Payload (Payload'First)) = Action
         then
            Found := Found + 1;
            Offset := Offset + 1;
            Got := Natural (Get_U16 (Payload, Offset));
            if Got = Arg then
               Args := Args + 1;
            end if;
         end if;
      end Visit;

      procedure Walk is new Walk_Outbox (Visit);
   begin
      Checks := Checks + 1;
      Walk;
      if Found = 1 and then Args = 1 then
         Pass (What);
      else
         Fail (What & ": expected one driver action" & Natural'Image (Action)
               & " with arg" & Natural'Image (Arg) & ", got"
               & Natural'Image (Found) & " (last arg" & Natural'Image (Got)
               & ")");
      end if;
   end Expect_Action_Arg;

   procedure Expect_No_Driver_Data (Kind : Natural; What : String) is
      Found : Natural := 0;

      procedure Visit (The_Type : Msg_Type_T;
                       Payload  : Stream_Element_Array) is
      begin
         if The_Type = MSG_DRIVER_DATA
           and then Payload'Length >= 1
           and then Natural (Payload (Payload'First)) = Kind
         then
            Found := Found + 1;
         end if;
      end Visit;

      procedure Walk is new Walk_Outbox (Visit);
   begin
      Checks := Checks + 1;
      Walk;
      if Found = 0 then
         Pass (What);
      else
         Fail (What & ": expected no driver data message of kind"
               & Natural'Image (Kind) & ", got" & Natural'Image (Found));
      end if;
   end Expect_No_Driver_Data;

   procedure Expect_Driver_Data (Kind  : Natural;
                                 Bytes : Byte_Array;
                                 What  : String) is
      Found : Natural := 0;
      Same  : Natural := 0;

      procedure Visit (The_Type : Msg_Type_T;
                       Payload  : Stream_Element_Array) is
      begin
         if The_Type = MSG_DRIVER_DATA
           and then Payload'Length >= 1
           and then Natural (Payload (Payload'First)) = Kind
         then
            Found := Found + 1;
            if Payload'Length = Bytes'Length + 1 then
               declare
                  Equal : Boolean := True;
               begin
                  for I in Bytes'Range loop
                     if Natural (Payload (Payload'First + 1
                                   + Stream_Element_Offset (I - Bytes'First)))
                        /= Bytes (I)
                     then
                        Equal := False;
                     end if;
                  end loop;
                  if Equal then
                     Same := Same + 1;
                  end if;
               end;
            end if;
         end if;
      end Visit;

      procedure Walk is new Walk_Outbox (Visit);
   begin
      Checks := Checks + 1;
      Walk;
      if Found = 1 and then Same = 1 then
         Pass (What);
      else
         Fail (What & ": expected one driver data message of kind"
               & Natural'Image (Kind) & " with the given payload, got"
               & Natural'Image (Found) & " of the kind,"
               & Natural'Image (Same) & " matching");
      end if;
   end Expect_Driver_Data;

   procedure Send_Desk_Input (Input : Natural; Pressed : Natural) is
      Payload : Stream_Element_Array (1 .. Desk_Input_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Input mod 256));
      Put_U8 (Payload, Offset, Unsigned_8 (Pressed mod 256));
      DMI_Core.Handle_Message (MSG_DESK_INPUT, Payload);
   end Send_Desk_Input;

   procedure Expect_Settings (Count      : Natural;
                              Brightness : Natural;
                              Volume     : Natural;
                              Isolated   : Natural;
                              What       : String) is
      Found : Natural := 0;
      Bad   : Natural := 0;
      Got   : Natural := 0;

      procedure Visit (The_Type : Msg_Type_T;
                       Payload  : Stream_Element_Array) is
      begin
         if The_Type = MSG_SETTINGS then
            Found := Found + 1;
            if Payload'Length = Settings_Length then
               Got := 65536 * Natural (Payload (Payload'First))
                 + 256 * Natural (Payload (Payload'First + 1))
                 + Natural (Payload (Payload'First + 2));
            else
               Bad := Bad + 1;
            end if;
         end if;
      end Visit;

      procedure Walk is new Walk_Outbox (Visit);
      Wanted : constant Natural :=
        65536 * Brightness + 256 * Volume + Isolated;
   begin
      Checks := Checks + 1;
      Walk;
      if Found = Count and then Bad = 0
        and then (Count = 0 or else Got = Wanted)
      then
         Pass (What);
      else
         Fail (What & ": expected" & Natural'Image (Count)
               & " MSG_SETTINGS, got" & Natural'Image (Found)
               & " (last" & Natural'Image (Got / 65536)
               & Natural'Image (Got / 256 mod 256)
               & Natural'Image (Got mod 256) & ")");
      end if;
   end Expect_Settings;

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
