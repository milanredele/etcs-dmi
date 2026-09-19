--  ETCS DMI
--  Window system implementation.

pragma Ada_2012;
with Display.Draw;
with Display.Screen;
with DMI_Ack;
with DMI_Conditions;
with DMI_Data_Entry;
with DMI_Data_View;
with DMI_Driver_Data;
with DMI_Status;
with DMI_Train_Data;
with General_Parameters;
with Supplementary_Driving_Info;
with Symbol;

package body DMI_Windows is

   use Display;

   Origin : constant Position_T := Get_Area (D).Position; -- (334, 15)

   The_Window_Area : constant Area_T := (Origin, 306, 450);

   Title_Height : constant := 24; -- DMI 5.3.1.2.2

   type Window_Kind_T is (Menu, Data_Entry, Validation, View);

   Stack : array (1 .. 8) of Window_ID_T;
   Depth : Natural := 0;

   package SDI renames Supplementary_Driving_Info;

   -- Start Up dialogue sequence (11.7.2.4, Table 49): S1 Driver ID -> D2
   -- -> S2 Level -> S10, which is S1 of the Main window dialogue sequence
   -- (11.7.3.3, Table 50). True from S1 until S10 is reached.
   Sequence_Active : Boolean := False;

   -- Start of mission state of the last MSG_ONBOARD (Onboard_State_Changed)
   Last_SOM : DMI_Conditions.Start_Of_Mission_T :=
     DMI_Conditions.No_Mission_Start;

   -- The Main window is on display because the on-board awaits an
   -- answer (Table 49 S0, S4, A31; Table 50 S7, S8, S9): all its buttons
   -- are disabled and the hour glass ST05 runs in the title area
   Waiting_Window : Boolean := False;

   -- What was awaited when the waiting window went up; Table 50 S7 ends
   -- in the default window, the other steps in the Main window
   Waiting_Kind : DMI_Conditions.Waiting_T := DMI_Conditions.Nothing;

   ---------------------------------------------------------------------
   -- Outbound action queue
   ---------------------------------------------------------------------

   type Queued_Action_T is record
      Action : Action_T := Action_T'First;
      Arg    : Natural := 0;
   end record;
   Actions : array (1 .. 8) of Queued_Action_T;
   Action_Count : Natural := 0;

   procedure Queue (Action : Action_T; Arg : Natural := 0) is
   begin
      if Action_Count < Actions'Last then
         Action_Count := Action_Count + 1;
         Actions (Action_Count) := (Action, Arg);
      end if;
   end Queue;

   function Pop_Action (Action : out Action_T;
                        Arg    : out Natural) return Boolean is
   begin
      Action := Action_T'First;
      Arg := 0;
      if Action_Count = 0 then
         return False;
      end if;
      Action := Actions (1).Action;
      Arg := Actions (1).Arg;
      Actions (1 .. Action_Count - 1) := Actions (2 .. Action_Count);
      Action_Count := Action_Count - 1;
      return True;
   end Pop_Action;

   ---------------------------------------------------------------------
   -- Window definitions
   ---------------------------------------------------------------------

   -- 11.3.2.1, 11.3.7.1, 11.3.8.1, 11.3.11.1: Level, Volume, Brightness
   -- and Adhesion are data entry windows on the half grid array with a
   -- single input field and a dedicated keyboard, not menu windows
   function Kind_Of (ID : Window_ID_T) return Window_Kind_T is
     (case ID is
         when W_Main | W_Override | W_Special | W_Settings => Menu,
         when W_Driver_ID | W_TRN | W_Train_Data | W_SR_Data
            | W_Level | W_Adhesion | W_Volume | W_Brightness => Data_Entry,
         when W_Train_Data_Validation => Validation,
         when W_Data_View => View);

   function Title (ID : Window_ID_T) return Wide_String is
     (case ID is
         when W_Main       => "Main",
         when W_Override   => "Override",
         when W_Data_View  => DMI_Data_View.Title,
         when W_Special    => "Special",
         when W_Settings   => "Settings",
         when W_Driver_ID  => "Driver ID",
         when W_Level      => "Level",
         when W_TRN        => "Train running number",
         when W_Train_Data => "Train data",
         when W_Train_Data_Validation => "Validate train data",
         when W_SR_Data    => "SR speed / distance",
         when W_Adhesion   => "Adhesion",
         when W_Volume     => "Volume",
         when W_Brightness => "Brightness");

   function Pad (S : Wide_String) return Wide_String is
      Result : Wide_String (1 .. 16) := (others => ' ');
   begin
      Result (1 .. S'Length) := S;
      return Result;
   end Pad;

   -- Menu window buttons; empty label = slot not present
   Max_Menu : constant := 10;
   type Label_T is record
      Text    : Wide_String (1 .. 16) := (others => ' ');
      Used    : Boolean := False;
      Enabled : Boolean := True;
      Delayed : Boolean := False; -- delay-type button (11.2.1.4)
   end record;
   type Menu_Def_T is array (1 .. Max_Menu) of Label_T;

   function B (S : Wide_String;
               Enabled : Boolean := True;
               Delayed : Boolean := False) return Label_T is
     ((Text => Pad (S), Used => True, Enabled => Enabled, Delayed => Delayed));

   No_Button : constant Label_T := (others => <>);

   function Static_Menu_Def (ID : Window_ID_T) return Menu_Def_T is
   begin
      case ID is
         when W_Main =>
            -- 11.2.1.4, Table 33; 11.2.1.5 names the delay type buttons.
            -- Rows #9 and #10 have no window or driver action behind
            -- them yet (P3, audit WIN-12 / WIN-13): their condition is
            -- in DMI_Conditions but the button stays disabled, a dead
            -- button being worse than a missing one (implementation
            -- choice). The same for rows #11 and #12, which have no
            -- button at all yet.
            return (1 => B ("Start",
                            Enabled => DMI_Conditions.Main_Start),
                    2 => B ("Driver ID",
                            Enabled => DMI_Conditions.Main_Driver_ID),
                    3 => B ("Train data",
                            Enabled => DMI_Conditions.Main_Train_Data),
                    4 => No_Button,
                    5 => B ("Level",
                            Enabled => DMI_Conditions.Main_Level),
                    6 => B ("Train run. nr",
                            Enabled => DMI_Conditions.Main_TRN),
                    7 => B ("Shunting",
                            Enabled => DMI_Conditions.Main_Shunting,
                            Delayed => True),
                    8 => B ("Non-Leading",
                            Enabled => DMI_Conditions.Main_Non_Leading,
                            Delayed => True),
                    9 => B ("Maint. Shunt.",
                            Enabled => False, Delayed => True),
                    10 => B ("Radio data", Enabled => False));
         when W_Override =>
            -- 11.2.2.4, Table 34
            return (1 => B ("EOA", Enabled => DMI_Conditions.Override_EOA),
                    others => No_Button);
         when W_Special =>
            -- 11.2.3.4, Table 35; 11.2.3.5: 'Train integrity' is a delay
            -- type button. Row #4 (BMM reaction inhibition) has no
            -- button yet (P3, audit WIN-13).
            return (1 => B ("Adhesion",
                            Enabled => DMI_Conditions.Special_Adhesion),
                    2 => B ("SR speed/dist.",
                            Enabled => DMI_Conditions.Special_SR_Data),
                    3 => B ("Train integrity",
                            Enabled =>
                              DMI_Conditions.Special_Train_Integrity,
                            Delayed => True),
                    others => No_Button);
         when W_Settings =>
            -- 11.2.4.4, Table 36. Language, System version and the two
            -- VBC rows have no window yet (P3, audit WIN-12): disabled,
            -- as for the Main window above.
            return (1 => B ("Language", Enabled => False),
                    2 => B ("Volume",
                            Enabled => DMI_Conditions.Settings_Volume),
                    3 => B ("Brightness",
                            Enabled => DMI_Conditions.Settings_Brightness),
                    4 => B ("System version", Enabled => False),
                    others => No_Button);
         when others =>
            return (others => No_Button);
      end case;
   end Static_Menu_Def;

   function Menu_Def (ID : Window_ID_T) return Menu_Def_T is
      Result : Menu_Def_T := Static_Menu_Def (ID);
   begin
      -- 11.2.1.4, 11.2.2.4, 11.2.3.4, 11.2.4.4: the buttons of these
      -- windows are enabled only while no driver's acknowledgement is
      -- required (displayed or waiting, 5.4.1.9); so no data entry can be
      -- started under a pending acknowledgement (5.4.1.11).
      -- Table 49 S0, S4 and A31 and Table 50 S7, S8 and S9 ask for the
      -- Main window "with all buttons disabled" while the on-board
      -- awaits an answer.
      if ID in W_Main | W_Override | W_Special | W_Settings
        and then (DMI_Ack.Pending_Count > 0
                  or else (ID = W_Main and then Waiting_Window))
      then
         for I in Result'Range loop
            Result (I).Enabled := False;
         end loop;
      end if;
      return Result;
   end Menu_Def;

   ---------------------------------------------------------------------
   -- Geometry
   ---------------------------------------------------------------------

   function Window_Area return Display.Area_T is (The_Window_Area);

   function Close_Button_Area return Display.Area_T is
     ((Origin + (0, 400), 82, 50));

   ---------------------------------------------------------------------
   -- Driver ID window in the step S1 (11.3.3.5 to 11.3.3.7)
   ---------------------------------------------------------------------

   -- In the step S1 of the Start Up dialogue sequence the Driver ID
   -- window also presents a 'settings' button with the symbol SE04 and a
   -- 'train running number' button with the label 'TRN'. These are
   -- objects of the Driver ID window of chapter 11, not of the generic
   -- data entry engine of chapter 10, so they live here and take the
   -- button indices that follow the engine's.
   TRN_Extra      : constant := 1;
   Settings_Extra : constant := 2;
   Extra_Count    : constant := 2;

   function In_Step_S1 return Boolean is
     (Sequence_Active and then Depth > 0
      and then Stack (Depth) = W_Driver_ID);

   -- 11.3.3.7 a: 'TRN' at (142,400), 11.3.3.6 a: 'settings' at (224,400),
   -- both 82 x 50 cells inside the D/F/G area
   function Extra_Area (Which : Positive) return Area_T is
     (if Which = TRN_Extra then (Origin + (142, 400), 82, 50)
      else (Origin + (224, 400), 82, 50));

   -- Table 20: menu buttons 153x50 in two columns from y 50
   function Menu_Button_Area (Index : Positive) return Area_T is
     ((Origin + (((Index - 1) mod 2) * 153, 50 + ((Index - 1) / 2) * 50),
       153, 50));

   function Button_Count return Natural is
   begin
      if Depth = 0 then
         return 0;
      end if;
      case Kind_Of (Stack (Depth)) is
         when Menu                    => return Max_Menu;
         when Data_Entry | Validation =>
            return DMI_Data_Entry.Button_Count
              + (if In_Step_S1 then Extra_Count else 0);
         when View                    => return DMI_Data_View.Button_Count;
      end case;
   end Button_Count;

   -- The index of the extra Driver ID button, 0 when Index is one of the
   -- data entry engine's own
   function Extra_Index (Index : Positive) return Natural is
     (if In_Step_S1 and then Index > DMI_Data_Entry.Button_Count
      then Index - DMI_Data_Entry.Button_Count else 0);

   function Button_Area (Index : Positive) return Display.Area_T is
   begin
      case Kind_Of (Stack (Depth)) is
         when Menu => return Menu_Button_Area (Index);
         when Data_Entry | Validation =>
            if Extra_Index (Index) > 0 then
               return Extra_Area (Extra_Index (Index));
            end if;
            return DMI_Data_Entry.Button_Area (Index);
         when View => return DMI_Data_View.Button_Area (Index);
      end case;
   end Button_Area;

   function Button_Enabled (Index : Positive) return Boolean is
   begin
      case Kind_Of (Stack (Depth)) is
         when Menu =>
            declare
               Def : constant Menu_Def_T := Menu_Def (Stack (Depth));
            begin
               return Def (Index).Used and then Def (Index).Enabled;
            end;
         when Data_Entry | Validation =>
            -- 11.3.3.5 names no condition for the two buttons of S1
            if Extra_Index (Index) > 0 then
               return True;
            end if;
            return DMI_Data_Entry.Button_Enabled (Index);
         when View =>
            return DMI_Data_View.Button_Enabled (Index);
      end case;
   end Button_Enabled;

   function Button_Kind (Index : Positive) return DMI_Buttons.Kind_T is
   begin
      case Kind_Of (Stack (Depth)) is
         when Menu =>
            declare
               Def : constant Menu_Def_T := Menu_Def (Stack (Depth));
            begin
               return (if Def (Index).Delayed then DMI_Buttons.Delay_Type
                       else DMI_Buttons.Up_Type);
            end;
         when Data_Entry | Validation =>
            -- 11.3.3.5 does not give a button type; both open a window,
            -- as the up-type buttons of a menu window do (implementation
            -- choice)
            if Extra_Index (Index) > 0 then
               return DMI_Buttons.Up_Type;
            end if;
            return DMI_Data_Entry.Button_Kind (Index);
         when View =>
            return DMI_Buttons.Up_Type;
      end case;
   end Button_Kind;

   ---------------------------------------------------------------------
   -- Stack handling
   ---------------------------------------------------------------------

   ---------------------------------------------------------------------
   -- Windows with a dedicated keyboard on the half grid array (audit
   -- WIN-10): Level (11.3.2), Adhesion (11.3.11), Volume (11.3.7) and
   -- Brightness (11.3.8). Each has a single input field with only the
   -- data part (10.3.1.7) and a list of predefined choices; the driver
   -- accepts the choice on the input field, which completes the entry
   -- (10.3.1.22, 10.6.1.2 a).
   ---------------------------------------------------------------------

   -- Table 38: the buttons 1, 2 and 4 are reserved for the ERTMS/ETCS
   -- levels 1, 2 and 0; the button 3 is empty; the NTC levels follow
   -- from the button 5. 11.3.2.6: the labels of the NTC levels are the
   -- abbreviations of the National Systems, whose definition is outside
   -- the scope of the specification; this DMI knows one NTC level
   -- (Supplementary_Driving_Info.Level_T) and labels it 'NTC'.
   Level_Choice_Count : constant := 5;
   Level_Of_Choice : constant array (1 .. Level_Choice_Count) of Natural :=
     (1 => SDI.Level_T'Pos (SDI.L1),
      2 => SDI.Level_T'Pos (SDI.L2),
      3 => 0,                          -- Table 38: no button
      4 => SDI.Level_T'Pos (SDI.L0),
      5 => SDI.Level_T'Pos (SDI.NTC));

   -- 11.3.2.7 / 11.3.2.8: only the buttons of the levels contained in
   -- the table of priority of trackside supported levels, or, when that
   -- table is not available on board, of the levels of the default list
   -- of levels configured on-board, are enabled. Neither list is carried
   -- by MSG_ONBOARD (see the report), so the DMI holds the default list
   -- of 11.3.2.8 as its own configuration: every level it can name.
   Default_Level_List : constant array (1 .. Level_Choice_Count) of Boolean :=
     (1 => True, 2 => True, 3 => False, 4 => True, 5 => True);

   function Level_Label (Pos : Natural) return Wide_String is
     (if Pos = SDI.Level_T'Pos (SDI.L0) then "Level 0"
      elsif Pos = SDI.Level_T'Pos (SDI.NTC) then "NTC"
      elsif Pos = SDI.Level_T'Pos (SDI.L1) then "Level 1"
      elsif Pos = SDI.Level_T'Pos (SDI.L2) then "Level 2"
      else "");

   -- 5.1.4.1: the level of the volume and of the luminance as a number
   function Level_Number (N : Natural) return Wide_String is
      Img : constant Wide_String := Natural'Wide_Image (N);
   begin
      return Img (2 .. Img'Last);
   end Level_Number;

   function Dedicated_Def (ID : Window_ID_T)
                           return DMI_Data_Entry.Window_Def_T is
      use DMI_Data_Entry;
      Result  : Window_Def_T;
      Choices : Choice_Set_T := No_Choices;
      Value   : DMI_Driver_Data.Text_Value_T;
      Chosen  : Natural := 0;

      -- 11.7.1.4: entering the window the value stored on board is
      -- presented to the driver
      procedure Propose (Index : Natural) is
      begin
         if Index not in 1 .. Choices.Count then
            return;
         end if;
         Chosen := Index;
         Value.Length := DMI_Data_Entry.Max_Choice_Label;
         Value.Text (1 .. Value.Length) := Choices.List (Index).Label;
         while Value.Length > 0 and then Value.Text (Value.Length) = ' ' loop
            Value.Length := Value.Length - 1;
         end loop;
      end Propose;
   begin
      case ID is
         when W_Level =>
            -- Table 38, with 11.3.2.7 / 11.3.2.8 for the enabling
            for I in 1 .. Level_Choice_Count loop
               Add_Choice (Choices, Level_Label (Level_Of_Choice (I)),
                           Enabled => Default_Level_List (I));
            end loop;
            -- the level the on-board reports is the level stored there
            if SDI.Level in SDI.L0 | SDI.NTC | SDI.L1 | SDI.L2 then
               for I in 1 .. Level_Choice_Count loop
                  if Level_Of_Choice (I) = SDI.Level_T'Pos (SDI.Level) then
                     Propose (I);
                  end if;
               end loop;
            end if;
         when W_Adhesion =>
            -- Table 43
            Add_Choice (Choices, "Non slippery rail");
            Add_Choice (Choices, "Slippery rail");
            -- 11.7.1.4: the adhesion the on-board holds is what
            -- MSG_STATUS reports as the slippery rail state (8.2.3.7)
            Propose (if DMI_Status.Slippery_Rail then 2 else 1);
         when W_Volume | W_Brightness =>
            -- 11.3.7.4.1 / 11.3.8.4.1: the definition of the keyboard is
            -- an implementation issue and the note offers "several
            -- buttons for different levels" as one example; the eleven
            -- levels of General_Parameters take the keys 1 to 11
            -- (implementation choice: one key per level leaves a data
            -- value in the input field, which a pair of '-' / '+'
            -- buttons would not)
            for I in 0 .. 10 loop
               Add_Choice (Choices, Level_Number (I));
            end loop;
            if ID = W_Volume then
               Propose
                 (Natural (General_Parameters.Loudspeaker_Volume) + 1);
            else
               Propose
                 (Natural (General_Parameters.Display_Luminance) + 1);
            end if;
         when others =>
            null;
      end case;
      Result.Title := Window_Title (Title (ID));
      Result.Field_Count := 1;
      Result.Fields (1) :=
        Field (Title (ID), DMI_Data_Entry.Max_Choice_Label,
               Keyboard => Dedicated,
               Proposed => Value,
               Choices  => Choices,
               Proposed_Choice => Chosen);
      return Result;
   end Dedicated_Def;

   -- The definition the data entry engine works on (10.3, 10.4); the
   -- proposed values are the stored ones (11.7.1.4)
   function Entry_Def (ID : Window_ID_T) return DMI_Data_Entry.Window_Def_T is
      use DMI_Driver_Data;
      use DMI_Data_Entry;

      function Image_Value (N : Natural) return Text_Value_T is
         Img : constant Wide_String := Natural'Wide_Image (N);
         R   : Text_Value_T;
      begin
         if N > 0 then
            R.Length := Img'Length - 1;
            R.Text (1 .. R.Length) := Img (2 .. Img'Last);
         end if;
         return R;
      end Image_Value;

      -- 10.3.4.1.2: the permitted ranges and resolutions are configured
      -- in the on-board and the protocol does not carry them, so the DMI
      -- holds what the specifications state for the data themselves:
      -- the technical rules are the ranges and resolutions of the
      -- ERTMS/ETCS variables of SUBSET-026 chapter 7. An operational
      -- range is an operating rule and belongs to the on-board too; the
      -- only one the DMI can state by itself is that zero is not a
      -- nominal value for a train length, a brake percentage or a
      -- maximum speed (implementation choice, see the report).
      TRN_Rule : constant Check_Rule_T :=       -- NID_OPERATIONAL, 7.5.1.92
        (Defined => True, Min => 0, Max => 99_999_999, Resolution => 1);

      Result : Window_Def_T;
   begin
      Result.Title := Window_Title (Title (ID));
      case ID is
         when W_Driver_ID =>
            -- 11.3.3.4: the keyboard associated to the Driver ID is an
            -- alphanumeric keyboard (10.3.5.17, multi-tap per 10.3.2.5).
            -- No range or resolution is specified for it; SUBSET-026
            -- A.3.11 (via 3.18.4.1.4) limits it to 1 to 16 alphanumeric
            -- characters, which is the length of the input field.
            Result.Field_Count := 1;
            Result.Fields (1) := Field ("Driver ID", Max_Field_Len,
                                        Keyboard => Alphanumeric,
                                        Proposed => Driver_ID);
         when W_TRN =>
            -- 11.3.1
            Result.Field_Count := 1;
            Result.Fields (1) := Field ("Train running nr", 8,
                                        Proposed => TRN,
                                        Technical => TRN_Rule);
         when W_Train_Data =>
            -- 11.3.9: the topic spans the windows its items need and
            -- lives in DMI_Train_Data (11.7.1.6.1: the values are stored
            -- only when the validation window is left with 'Yes')
            return DMI_Train_Data.Window_Def
              (DMI_Train_Data.Current_Window);
         when W_Level | W_Adhesion | W_Volume | W_Brightness =>
            -- 11.3.2, 11.3.7, 11.3.8, 11.3.11: half grid array, a single
            -- input field with only the data part and a dedicated
            -- keyboard (Dedicated_Def above)
            return Dedicated_Def (ID);
         when W_SR_Data =>
            -- 11.3.10.1: likewise on the total grid array
            Result.Layout := Total_Grid;
            Result.Field_Count := 2;
            Result.Fields (1) :=
              Field ("SR speed", 3, Proposed => Image_Value (SR_Speed));
            Result.Fields (2) :=
              Field ("SR distance", 5, Proposed => Image_Value (SR_Dist));
         when W_Train_Data_Validation =>
            -- 11.4.1 with 11.4.1.3: the echo texts of the train data
            -- window(s), built by DMI_Train_Data
            return DMI_Train_Data.Validation_Def;
         when others =>
            null;
      end case;
      return Result;
   end Entry_Def;

   -- 10.6.1.1 with 10.6.1.3: the train data entry / validation process
   -- starts with the first train data window and runs while one of the
   -- two window kinds of the topic is displayed
   procedure Sync_Train_Data_Process is
   begin
      if Depth = 0
        or else Stack (Depth) not in W_Train_Data | W_Train_Data_Validation
      then
         DMI_Train_Data.End_Process;
      end if;
   end Sync_Train_Data_Process;

   procedure Open (ID : Window_ID_T) is
   begin
      if Depth < Stack'Last then
         if ID = W_Train_Data and then not DMI_Train_Data.In_Progress then
            DMI_Train_Data.Start_Process;
         end if;
         Depth := Depth + 1;
         Stack (Depth) := ID;
         if Kind_Of (ID) in Data_Entry | Validation then
            DMI_Data_Entry.Open (Entry_Def (ID));
         elsif Kind_Of (ID) = View then
            --  The window opens on its first window (5.3.1.1.9)
            DMI_Data_View.Reset;
         end if;
      end if;
   end Open;

   -- Back to the parent window
   procedure Pop is
   begin
      if Depth > 0 then
         Depth := Depth - 1;
         -- 10.6.1.1 / 10.6.1.3 e: leaving the validation window for a
         -- reason other than accepting 'Yes' stops the data entry /
         -- validation process of the topic; the data entry window that
         -- becomes displayed again starts a new one, with the stored
         -- values proposed (11.7.1.4). The engine holds one process at
         -- a time, which is what the window stack needs here. The train
         -- data topic keeps its own values while its process runs
         -- (Table 50 S3-1 entered from S3-2).
         Sync_Train_Data_Process;
         if Depth > 0
           and then Kind_Of (Stack (Depth)) in Data_Entry | Validation
         then
            DMI_Data_Entry.Open (Entry_Def (Stack (Depth)));
         end if;
      end if;
   end Pop;

   procedure To_Default_Window is
   begin
      Depth := 0;
      Sequence_Active := False;
      Waiting_Window := False;
      DMI_Train_Data.End_Process;
   end To_Default_Window;

   -- 11.7.2.2: [Close] is disabled in the windows presented before S10
   -- (S1 Driver ID and S2 Level), except in the steps S1-1, S1-2,
   -- S3-2-2, S3-3 and S3-4. Of those S1-1 (Settings) and S1-2 (Train
   -- running number) exist: they are the windows the Driver ID window is
   -- the parent of (11.6.1.2), i.e. everything the driver opens above
   -- it, S1 being the only Start Up step with a window below another.
   -- 11.7.3.2: [Close] is enabled in the Main window sequence except
   -- S5-2-1, S5-2-3, S7, S8 and S9, the steps waiting for the radio
   -- network or the RBC: of those S7, S8 and S9 exist, as the Main
   -- window the EVC asks for while it awaits an answer.
   function Close_Enabled return Boolean is
     (not Waiting_Window
      and then (not Sequence_Active or else Depth > 1));

   procedure Close_Top is
   begin
      if Close_Enabled then
         Pop;
      end if;
   end Close_Top;

   procedure Close_All is
   begin
      To_Default_Window;
      Action_Count := 0;
      Waiting_Kind := DMI_Conditions.Nothing;
      Last_SOM := DMI_Conditions.No_Mission_Start;
   end Close_All;

   -- Table 49 S10: the Start Up sequence ends in S1 of the Main window
   -- dialogue sequence
   procedure Reach_S10 is
   begin
      To_Default_Window;
      Open (W_Main);
   end Reach_S10;

   procedure Engage_Start_Up is
   begin
      -- SUBSET-026 4.10.1.3: entering SB the Driver ID, the train data
      -- and the train running number are to be revalidated (status
      -- "invalid"), the level keeps its status. The status of the data
      -- stored on-board belongs to the on-board (11.7.1.3) and the EVC
      -- reports it (MSG_ONBOARD, DMI_Conditions); the DMI does not set
      -- it here any more. The stored values stay and are proposed in the
      -- windows (11.7.1.4).
      To_Default_Window;
      -- Table 49 S1
      Sequence_Active := True;
      Open (W_Driver_ID);
   end Engage_Start_Up;

   procedure Abort_Start_Up is
   begin
      -- The specification does not say what happens to the sequence when
      -- the start of mission ends before S10 (SB is left, e.g. to SL or
      -- SF). Implementation choice: the sequence ends with the default
      -- window, so that its windows with the disabled [Close] cannot stay.
      if Sequence_Active then
         To_Default_Window;
      end if;
   end Abort_Start_Up;

   function In_Start_Up return Boolean is (Sequence_Active);

   function Waiting_Displayed return Boolean is (Waiting_Window);

   -- The windows of Table 48 that take data: the data entry windows of
   -- 11.3 and the validation window of 11.4
   function Is_Entry_Window (ID : Window_ID_T) return Boolean is
     (Kind_Of (ID) in Data_Entry | Validation);

   function Entry_Open return Boolean is
     (Depth > 0 and then Is_Entry_Window (Stack (Depth)));

   procedure Stop_Entry is
   begin
      -- 11.7.1.9: the values of the input fields are dropped with the
      -- window; the validation window goes with its train data window
      while Depth > 0 and then Is_Entry_Window (Stack (Depth)) loop
         Pop;
      end loop;
   end Stop_Entry;

   -- Only the on-board knows the conditions of Table 49 S0 and the steps
   -- in which it awaits an answer; the EVC reports them (MSG_ONBOARD)
   -- and this is where they take effect. The start of mission engages
   -- the sequence on the change to "initiated", not on every message.
   procedure Onboard_State_Changed is
      use DMI_Conditions;
   begin
      -- Table 49 S0 / S4 / A31 and Table 50 S7 / S8 / S9: the Main
      -- window with all buttons disabled and the hour glass ST05
      if Awaiting_Answer then
         if not Waiting_Window then
            To_Default_Window;
            Open (W_Main);
            Waiting_Window := True;
         end if;
         Waiting_Kind := Waiting;
      elsif Waiting_Window then
         Waiting_Window := False;
         -- Table 50 S7 ends in the default window when the MA or the SR
         -- authorisation arrives; Table 49 S4 / A31 and Table 50 S8 / S9
         -- end in the Main window (S10 / S1), which stays open
         if Waiting_Kind = Authorisation then
            To_Default_Window;
         end if;
         Waiting_Kind := Nothing;
      end if;

      if Start_Of_Mission = Initiated and then Last_SOM /= Initiated then
         Engage_Start_Up;                                  -- S0 -> S1
      elsif Start_Of_Mission = No_Mission_Start
        and then Last_SOM /= No_Mission_Start
      then
         Abort_Start_Up;
      end if;
      Last_SOM := Start_Of_Mission;
   end Onboard_State_Changed;

   -- 11.7.1.7, Table 48: the button whose enabling conditions decide
   -- whether the displayed data entry / validation window may stay. The
   -- windows of Table 48 that do not exist yet (Radio network type,
   -- GSM-R network ID, Mission with one radio system, RBC data,
   -- Language, ATO selector) are P3 (audit WIN-12).
   function Window_Condition (ID : Window_ID_T) return Boolean is
     (case ID is
         when W_TRN        => DMI_Conditions.Main_TRN,
         when W_Driver_ID  => DMI_Conditions.Main_Driver_ID,
         when W_Level      => DMI_Conditions.Main_Level,
         when W_Train_Data | W_Train_Data_Validation =>
           DMI_Conditions.Main_Train_Data,
         when W_SR_Data    => DMI_Conditions.Special_SR_Data,
         when W_Adhesion   => DMI_Conditions.Special_Adhesion,
         when W_Volume     => DMI_Conditions.Settings_Volume,
         when W_Brightness => DMI_Conditions.Settings_Brightness,
         when others       => True);  -- not a window of Table 48

   procedure Check_Enabling_Conditions is
   begin
      -- "After the Start Up dialogue sequence": during it the steps of
      -- Table 49 decide which window is shown
      if Sequence_Active or else Depth = 0 then
         return;
      end if;
      if not Window_Condition (Stack (Depth)) then
         Stop_Entry;
      end if;
   end Check_Enabling_Conditions;

   function Is_Open return Boolean is (Depth > 0);

   function Top return Window_ID_T is (Stack (Depth));

   ---------------------------------------------------------------------
   -- Behaviour
   ---------------------------------------------------------------------

   -- The driver accepted the predefined choice of one of the four half
   -- grid array windows with a dedicated keyboard (audit WIN-10). The
   -- choice number is the row of Table 38 / Table 43 / the level of the
   -- volume or the luminance; 10.6.1.2 a: accepting the value leaves the
   -- window, which ends the data entry process of the topic.
   procedure Dedicated_Completed (ID : Window_ID_T) is
      use General_Parameters;
      Chosen : constant Natural := DMI_Data_Entry.Choice_Number (1);
   begin
      if Chosen = 0 then
         return;
      end if;
      case ID is
         when W_Level =>
            if Chosen <= Level_Choice_Count
              and then Level_Of_Choice (Chosen) > 0
            then
               DMI_Driver_Data.Level_Entered := True;
               Queue (Level_Selected, Level_Of_Choice (Chosen));
               Pop;
               if Sequence_Active then
                  -- Table 49 S2: level 0, 1 or NTC -> S10; level 2 ->
                  -- S3-1 Radio data window, which does not exist yet
                  -- (P3, audit WIN-12): skipped to S10
                  Reach_S10;
               end if;
               -- Table 50 S4: back to S1, the Main window (level 2:
               -- D5 -> S8 / S5-1 skipped likewise)
            end if;
         when W_Adhesion =>
            -- Table 43: 1 non slippery rail, 2 slippery rail
            Queue (Adhesion_Set, (if Chosen = 2 then 1 else 0));
            Pop;
         when W_Volume =>
            -- the choices are the levels 0 .. 10 in order (the range
            -- check is defensive: the engine never reports a choice the
            -- list does not hold). GEN-3: the value is not applied to
            -- the sound output yet (P4).
            if Chosen - 1
                 in Natural (Loudspeaker_Volume_T'First)
                 .. Natural (Loudspeaker_Volume_T'Last)
            then
               Loudspeaker_Volume := Loudspeaker_Volume_T (Chosen - 1);
               Pop;
            end if;
         when W_Brightness =>
            if Chosen - 1
                 in Natural (Display_Luminance_T'First)
                 .. Natural (Display_Luminance_T'Last)
            then
               Display_Luminance := Display_Luminance_T (Chosen - 1);
               Pop;
            end if;
         when others =>
            null;
      end case;
   end Dedicated_Completed;

   procedure Entry_Completed is
      use DMI_Driver_Data;
      ID : constant Window_ID_T := Stack (Depth);
   begin
      case ID is
         when W_Driver_ID =>
            Driver_ID := DMI_Data_Entry.Value (1);
            Driver_ID_Entered := True;
            Queue (Send_Driver_ID);
            Pop;
            if Sequence_Active then
               -- Table 49 E1 -> D2: "if both the stored position and the
               -- stored level are valid". The status of the data stored
               -- on-board is the on-board's (11.7.1.3) and the EVC
               -- reports it (MSG_ONBOARD, DMI_Conditions). The DMI is
               -- not told the status of the position, so D2 is decided
               -- on the level alone (implementation choice). D3 with
               -- level 2 -> D7 -> A31 / S4: the radio network and RBC
               -- steps do not exist yet (P3, audit WIN-11 / WIN-12) and
               -- are skipped to S10.
               if DMI_Conditions.Level_Valid
                 and then SDI.Level in SDI.L0 | SDI.NTC | SDI.L1 | SDI.L2
               then
                  Reach_S10;
               else
                  Open (W_Level);
               end if;
            end if;
            -- Table 50 S2: back to S1, the Main window below
         when W_TRN =>
            TRN := DMI_Data_Entry.Value (1);
            TRN_Entered := True;
            Queue (Send_TRN);
            -- Table 50 S6 and S3-3 -> D1: back to S1, the Main window
            -- (D2, D8 and S9, waiting for the RBC, are skipped: P3). The
            -- mission start is the driver's: 'Start' in the Main window.
            Pop;
         when W_Train_Data =>
            -- Table 50 S3-1 with 11.7.1.6.1: pressing the 'Yes' button
            -- of the question does not touch the train data stored on
            -- board; the entered values stay with the running process
            DMI_Train_Data.Capture (DMI_Train_Data.Current_Window);
            -- 10.6 / 11.4.1: entered data must be validated (-> S3-2)
            Open (W_Train_Data_Validation);
         when W_SR_Data =>
            SR_Speed := DMI_Data_Entry.Number (1);
            SR_Dist := DMI_Data_Entry.Number (2);
            Queue (Send_SR_Data);
            Pop;
         when W_Level | W_Adhesion | W_Volume | W_Brightness =>
            Dedicated_Completed (ID);
         when others =>
            null;
      end case;
   end Entry_Completed;

   procedure Menu_Pressed (Index : Positive) is
      ID : constant Window_ID_T := Stack (Depth);
   begin
      case ID is
         when W_Main =>
            case Index is
               when 1 => -- Start
                  -- Table 50 S1: with level 0, 1 or NTC back to the
                  -- default window; with level 2 D7 -> S7 waits for the
                  -- RBC with the hour glass, which the EVC asks for
                  -- (MSG_ONBOARD, waiting = 3). 'Start' stays dead until
                  -- the EVC says the request is answered.
                  if DMI_Conditions.Main_Start then
                     Queue (Start_Mission);
                     To_Default_Window;
                  end if;
               when 2 => Open (W_Driver_ID);
               when 3 => Open (W_Train_Data);
               when 5 => Open (W_Level);
               when 6 => Open (W_TRN);
               when 7 => Queue (SH_Request); Pop;
               when 8 => Queue (Non_Leading); Pop;
               when others => null;
            end case;
         when W_Override =>
            if Index = 1 then
               Queue (Override_EOA);
               Pop;
            end if;
         when W_Special =>
            case Index is
               when 1 => Open (W_Adhesion);
               when 2 => Open (W_SR_Data);
               when 3 => Queue (Train_Integrity); Pop;
               when others => null;
            end case;
         when W_Settings =>
            case Index is
               when 2 => Open (W_Volume);
               when 3 => Open (W_Brightness);
               when others => null;
            end case;
         when others =>
            null;
      end case;
   end Menu_Pressed;

   -- 11.4.1, 10.6.1.3 a: the process ends when the driver accepts the
   -- value 'Yes' in the input field of the validation window
   procedure Validation_Completed is
      use DMI_Driver_Data;
      V : constant Text_Value_T := DMI_Data_Entry.Value (1);
   begin
      if V.Length = 3 and then V.Text (1 .. 3) = "Yes" then
         -- 11.7.1.6.1: only now do the entered values replace the train
         -- data stored on board
         DMI_Train_Data.Store;
         Queue (Send_Train_Data);
         Pop; -- validation
         Pop; -- train data entry
         -- Table 50 D6: "if Train running number is valid" the procedure
         -- goes to D1 -> S1 Main window, otherwise the train running
         -- number is requested next (S3-3). The status is the on-board's
         -- (11.7.1.3), reported by the EVC (MSG_ONBOARD).
         if not DMI_Conditions.TRN_Valid then
            Open (W_TRN);
         end if;
      else
         -- Table 50 S3-2: back to S3-1, the first train data window,
         -- with the data values of the previous S3-1 proposed
         DMI_Train_Data.Restart_At_First;
         Pop;
      end if;
   end Validation_Completed;

   -- Tables 22 and 23: the driver pressed [Previous] or [Next] of a
   -- topic that spans several windows. The train data is the only such
   -- topic here; its values are read back before the window changes, so
   -- that the running process keeps them (Table 50 S3-1).
   procedure Page_Requested is
      Wanted : constant Natural := DMI_Data_Entry.Take_Page_Request;
   begin
      if Wanted = 0 or else Depth = 0
        or else Stack (Depth) /= W_Train_Data
      then
         return;
      end if;
      DMI_Train_Data.Capture (DMI_Train_Data.Current_Window);
      DMI_Train_Data.Go_To (Wanted);
      DMI_Data_Entry.Open (Entry_Def (W_Train_Data));
   end Page_Requested;

   procedure Button_Pressed (Index : Positive) is
      Kind : Window_Kind_T;
   begin
      if Depth = 0 then
         return;
      end if;
      Kind := Kind_Of (Stack (Depth));
      case Kind is
         when Menu =>
            Menu_Pressed (Index);
         when Data_Entry | Validation =>
            if Extra_Index (Index) > 0 then
               -- Table 49 S1: the settings button leads to S1-1, the
               -- train running number button to S1-2; the Driver ID
               -- window is the parent of both (11.6.1.2), so they stack
               -- over it and their [Close] comes back to S1
               if Extra_Index (Index) = TRN_Extra then
                  Open (W_TRN);
               else
                  Open (W_Settings);
               end if;
               return;
            end if;
            DMI_Data_Entry.Press (Index);
            if DMI_Data_Entry.Take_Completion then
               if Kind = Validation then
                  Validation_Completed;
               else
                  Entry_Completed;
               end if;
            else
               --  Tables 22 and 23: [Previous] / [Next] open another
               --  window of the same topic (own helper)
               Page_Requested;
            end if;
         when View =>
            DMI_Data_View.Button_Pressed (Index);
      end case;
   end Button_Pressed;

   ---------------------------------------------------------------------
   -- Rendering
   ---------------------------------------------------------------------

   procedure Draw_Title (ID : Window_ID_T) is
   begin
      Screen.Fill_Area ((Origin, The_Window_Area.Width, Title_Height),
                        General_Parameters.BLACK);
      Draw.Draw_String (Pen_X      => Origin.X + 3,
                        Pen_Y      => Origin.Y + Title_Height - 6,
                        The_String => Title (ID),
                        The_Size   => 12,
                        The_Color  => General_Parameters.GREY);
      -- 11.2.1.6: while the on-board exchanges messages with the RBC
      -- (see 11.7) the hour glass ST05 is shown vertically centered in
      -- the 'Main' window title area, from X 42, moving 26 cells to the
      -- right every second and starting over when it no longer fits
      if Waiting_Window and then ID = W_Main then
         Draw.Draw_Symbol
           (Symbol.ST_05,
            Origin + (DMI_Conditions.ST05_X (The_Window_Area.Width,
                                             Symbol.ST_05.Width),
                      (Title_Height - Symbol.ST_05.Height) / 2));
      end if;
   end Draw_Title;

   procedure Draw_Close (Pressed : Boolean) is
      Close_Area : constant Area_T := Close_Button_Area;
      -- 5.3.2.5.5 a: the disabled [Close] shows NA12 (chapter 13)
      Enabled    : constant Boolean := Close_Enabled;
      Width      : constant Natural :=
        (if Enabled then Symbol.NA_11.Width else Symbol.NA_12.Width);
      Height     : constant Natural :=
        (if Enabled then Symbol.NA_11.Height else Symbol.NA_12.Height);
      Position   : constant Position_T :=
        Close_Area.Position
          + ((Close_Area.Width - Width) / 2, (Close_Area.Height - Height) / 2);
   begin
      if not Pressed then
         Draw.Draw_Button_Frame (Close_Area);
      end if;
      if Enabled then
         Draw.Draw_Symbol (Symbol.NA_11, Position);
      else
         Draw.Draw_Symbol (Symbol.NA_12, Position);
      end if;
   end Draw_Close;

   procedure Draw_Labelled_Button (The_Area : Area_T;
                                   Label    : Wide_String;
                                   Enabled  : Boolean;
                                   Pressed  : Boolean) is
   begin
      if not Pressed then
         Draw.Draw_Button_Frame (The_Area);
      end if;
      -- 5.3.2.5.5 / 10.2.1.4: disabled labels in dark grey
      Draw.Draw_String
        (Pen_X => The_Area.Position.X + The_Area.Width / 2,
         Pen_Y => The_Area.Position.Y + The_Area.Height / 2 + 6,
         The_String => Label,
         The_Size => 12,
         The_Color => (if Enabled then General_Parameters.GREY
                       else General_Parameters.DARK_GREY),
         The_Alignment => Draw.Center);
   end Draw_Labelled_Button;

   function Trim (S : Wide_String) return Wide_String is
      Last : Natural := S'Last;
   begin
      while Last >= S'First and then S (Last) = ' ' loop
         Last := Last - 1;
      end loop;
      return S (S'First .. Last);
   end Trim;

   function Pressed (Index : Positive) return Boolean is
     (DMI_Buttons.Is_Pressed
        (DMI_Buttons.Button_ID_T'Val
           (DMI_Buttons.Button_ID_T'Pos (DMI_Buttons.BTN_Menu_1) + Index - 1)));

   procedure Draw_Menu (ID : Window_ID_T) is
      Def : constant Menu_Def_T := Menu_Def (ID);
   begin
      for I in Def'Range loop
         if Def (I).Used then
            Draw_Labelled_Button (Menu_Button_Area (I),
                                  Trim (Def (I).Text),
                                  Def (I).Enabled,
                                  Def (I).Enabled and then Pressed (I));
         end if;
      end loop;
   end Draw_Menu;

   -- 11.3.3.5: the 'settings' button with the symbol SE04 and the 'train
   -- running number' button with the label 'TRN' of the step S1
   procedure Draw_Driver_ID_Extras is
      First : constant Positive := DMI_Data_Entry.Button_Count + 1;

      procedure Frame (The_Area : Area_T; Index : Positive) is
      begin
         if not Pressed (Index) then
            Draw.Draw_Button_Frame (The_Area);
         end if;
      end Frame;

      TRN_Area  : constant Area_T := Extra_Area (TRN_Extra);
      Set_Area  : constant Area_T := Extra_Area (Settings_Extra);
   begin
      Frame (TRN_Area, First + TRN_Extra - 1);
      -- 5.1.2.2.3 g: the label of the Train running number is 10 cells
      Draw.Draw_String
        (Pen_X => TRN_Area.Position.X + TRN_Area.Width / 2,
         Pen_Y => TRN_Area.Position.Y + TRN_Area.Height / 2 + 5,
         The_String => "TRN",
         The_Size => 10,
         The_Color => General_Parameters.GREY,
         The_Alignment => Draw.Center);
      Frame (Set_Area, First + Settings_Extra - 1);
      -- 5.1.6.3: a symbol is centred in its area
      Draw.Draw_Symbol
        (Symbol.SE_04,
         Set_Area.Position + ((Set_Area.Width - Symbol.SE_04.Width) / 2,
                              (Set_Area.Height - Symbol.SE_04.Height) / 2));
   end Draw_Driver_ID_Extras;

   procedure Draw_Text_Line (Line : Natural; Text : Wide_String) is
   begin
      Draw.Draw_String
        (Pen_X => Origin.X + 6,
         Pen_Y => Origin.Y + 50 + Line * 24,
         The_String => Text,
         The_Size => 12,
         The_Color => General_Parameters.GREY);
   end Draw_Text_Line;

   function Num_Image (N : Natural) return Wide_String is
      Img : constant Wide_String := Natural'Wide_Image (N);
   begin
      return Img (2 .. Img'Last);
   end Num_Image;


   procedure Render is
      ID : Window_ID_T;
   begin
      if Depth = 0 then
         return;
      end if;
      ID := Stack (Depth);

      case Kind_Of (ID) is
         when Menu | View =>
            Screen.Fill_Area (The_Window_Area,
                              General_Parameters.Background_Color);
            Draw_Title (ID);
         when Data_Entry | Validation =>
            -- 10.3.7 / 10.4.3: the layers of the entry windows; the
            -- engine covers its own area and draws its own title
            Screen.Fill_Area (DMI_Data_Entry.Covered_Area,
                              General_Parameters.Background_Color);
            DMI_Data_Entry.Render;
      end case;
      Draw_Close (DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_Window_Close));

      case Kind_Of (ID) is
         when Menu => Draw_Menu (ID);
         when View =>
            --  11.5.1: the items, the paging and the [Previous] /
            --  [Next] buttons are in DMI_Data_View
            DMI_Data_View.Render
              (Previous_Pressed => Pressed (DMI_Data_View.Previous_Button),
               Next_Pressed     => Pressed (DMI_Data_View.Next_Button));
         when Data_Entry | Validation =>
            if In_Step_S1 then
               Draw_Driver_ID_Extras;
            end if;
      end case;
   end Render;

end DMI_Windows;
