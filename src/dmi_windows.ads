--  ETCS DMI
--  Sub-level windows (chapters 10 and 11, touch screen technology).
--
--  Windows stack over the default window in the D/F column (Table 20:
--  306x450, title 24 cells, [Close] at y 400). Only the top window
--  responds to driver input (5.3.1.1.5). Three window kinds are
--  implemented: menu windows (10.2.1), data entry windows with a numeric
--  keyboard (10.3, simplified: no alphanumeric multi-tap, technical
--  range checks only) and the train data validation window (10.4).

with Display;
with DMI_Buttons;

package DMI_Windows is

   type Window_ID_T is
     (W_Main,        -- 11.2.1
      W_Override,    -- 11.2.2
      W_Data_View,   -- 11.5.1
      W_Special,     -- 11.2.3
      W_Settings,    -- 11.2.4
      W_Driver_ID,   -- 11.3.3
      W_Level,       -- 11.3.2
      W_TRN,         -- 11.3.1
      W_Train_Data,  -- 11.3.9 (fixed train data, numeric items)
      W_Train_Data_Validation, -- 11.4.1
      W_SR_Data,     -- 11.3.10
      W_Adhesion,    -- 11.3.11
      W_Volume,      -- 11.3.7
      W_Brightness); -- 11.3.8

   -- Requests towards the EVC, drained by DMI_Core
   type Action_T is
     (Start_Mission,
      Override_EOA,
      SH_Request,
      Exit_SH,
      Non_Leading,
      Train_Integrity,
      Adhesion_Set,      -- Arg: 1 slippery, 0 non slippery
      Level_Selected,    -- Arg: Level_T'Pos
      Send_Driver_ID,
      Send_TRN,
      Send_Train_Data,
      Send_SR_Data);

   procedure Open (ID : Window_ID_T);
   -- The driver pressed [Close]; ignored where [Close] is disabled
   procedure Close_Top;
   procedure Close_All;
   function Is_Open return Boolean;
   function Top return Window_ID_T
     with Pre => Is_Open;

   -- Start Up dialogue sequence (11.7.2, Table 49). It is engaged by the
   -- on-board conditions of S0, not by a button: DMI_Core calls
   -- Engage_Start_Up when the EVC reports the entry into mode SB and
   -- Abort_Start_Up when SB is left before the sequence reached S10.
   -- The sequence is S1 Driver ID, S2 Level (when the level is not
   -- valid), S10 = S1 of the Main window dialogue sequence (11.7.3).
   procedure Engage_Start_Up;
   procedure Abort_Start_Up;
   function In_Start_Up return Boolean;

   -- 11.7.2.2 / 11.7.3.2: [Close] is disabled before S10 of Start Up
   function Close_Enabled return Boolean;

   -- 11.7.1.9: a data entry or validation window is displayed / stop
   -- the process and present the parent window instead
   function Entry_Open return Boolean;
   procedure Stop_Entry;

   -- The 'Start' request is no longer pending on the EVC side (the mode
   -- changed or the proposed mode was withdrawn): 'Start' can be enabled
   -- again when Table 33 allows it
   procedure Start_Request_Closed;

   function Window_Area return Display.Area_T;
   function Close_Button_Area return Display.Area_T;

   -- Window-internal buttons (menu grid or keyboard keys), for the
   -- button registry of DMI_Core; Index is 1 .. Button_Count
   function Button_Count return Natural;
   function Button_Area (Index : Positive) return Display.Area_T;
   function Button_Enabled (Index : Positive) return Boolean;
   function Button_Kind (Index : Positive) return DMI_Buttons.Kind_T;

   -- A window button was activated
   procedure Button_Pressed (Index : Positive);

   -- Drain pending EVC requests
   function Pop_Action (Action : out Action_T;
                        Arg    : out Natural) return Boolean;

   procedure Render;

end DMI_Windows;
