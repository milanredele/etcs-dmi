--  ETCS DMI
--  Support for the headless regression runner: drives DMI_Core directly
--  (no sockets), captures golden frames and checks sounds/actions.
--
--  Golden frames live in test/golden/*.frame . Run with UPDATE=1 in the
--  environment to (re)record them instead of comparing.

with DMI_Sounds;
with Interfaces;

package Test_Support is

   -- Wrappers building protocol v2 payloads and feeding DMI_Core

   procedure Send_Speed_State
     (V_Cur, V_Perm, V_Target, V_Release, V_Sbi, V_Wsl : Natural;
      D_Target        : Natural;
      Monitoring      : Natural;  -- 0 CSM / 1 TSM / 2 RSM
      Dial_Range      : Natural;  -- 0..3
      Vrelease_Exists : Boolean;
      CSM_Target_Info : Boolean := False;
      Brake_Commanded : Boolean := False;
      Status          : Integer := -1;  -- 0 NoS .. 4 IntS; -1: see below
      MRDT            : Natural := 0);
   -- With Status = -1 the wrapper acts as the EVC: it determines the status
   -- from the speeds, the brake command and its previous result
   -- (EVC_Supervision). Reset_EVC_Model forgets the previous result.

   procedure Reset_EVC_Model;

   -- The same message with the fields exactly as they travel on the wire,
   -- for values the EVC can send but the wrapper above cannot express
   -- (u16 speeds, u32 distance, undefined monitoring/dial codes, all flags)
   procedure Send_Speed_State_Raw
     (V_Cur, V_Perm, V_Target, V_Release, V_Sbi, V_Wsl : Interfaces.Unsigned_16;
      D_Target   : Interfaces.Unsigned_32;
      Monitoring : Interfaces.Unsigned_8;
      Dial_Range : Interfaces.Unsigned_8;
      Flags      : Interfaces.Unsigned_8;
      Status     : Interfaces.Unsigned_8 := 0;
      MRDT       : Interfaces.Unsigned_8 := 0);

   procedure Send_Mode_Level
     (Mode          : Natural;           -- Mode_T'Pos
      Level         : Natural;           -- Level_T'Pos
      Mode_Ack      : Natural := 16#FF#;
      Level_Ann     : Natural := 16#FF#;
      Level_Ann_Ack : Boolean := False;
      Override      : Boolean := False;
      TAF           : Boolean := False;
      LSSMA         : Natural := 16#FFFF#;
      --  8.2.3.2.9: the abbreviation of the National System; "" sends
      --  the 9 byte form ("no name"), a longer one is cut to the maximum
      National_Name : String := "");

   procedure Send_Status
     (Brake        : Natural := 0;   -- 0 none / 1 shown / 2 ack required /
                                     -- 3 shown, for a pending acknowledgement
      Radio        : Natural := 0;   -- 0 none / 1 up / 2 lost
      Adhesion     : Boolean := False;
      BMM          : Boolean := False;
      Reversing    : Boolean := False;
      SM_Direction : Natural := 0;   -- 0 none / 1 fwd / 2 bwd
      Set_Speed    : Natural := 16#FFFF#;
      TTI          : Natural := 16#FFFF#; -- tenths of a second
      T_Disp_TTI   : Natural := 14;       -- seconds
      Tunnel       : Natural := 0;   -- 0 unknown / 1 active / 2 announced
      Tunnel_Dist  : Natural := 0;
      Geo_Pos      : Natural := 16#7FFF_FFFF#; -- metres; huge = unknown
      Geo_Valid    : Boolean := False;
      HH, MM, SS   : Natural := 0);

   -- MSG_ONBOARD, the on-board state behind the enabling conditions of
   -- Tables 33 to 36 (DMI_Conditions). The wrapper acts as the EVC and
   -- holds this state: Send_Onboard changes it and sends it, and every
   -- Step and Send_Mode_Level send it again, the way an EVC repeats it
   -- every cycle. The validity of the driver's data is not a parameter:
   -- the wrapper's EVC has exactly what the DMI sent it
   -- (MSG_DRIVER_DATA, mirrored by DMI_Driver_Data), and entering SB
   -- invalidates it (SUBSET-026 4.10.1.3). The defaults are a standing
   -- train whose on-board knows nothing of an RBC, which is what the
   -- older scenarios assume.
   procedure Send_Onboard
     (Standstill       : Boolean := True;
      Session          : Natural := 0;   -- 0 none / 1 establishing /
                                         -- 2 exists / 3 exists, RBC > 2.2
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
      In_S0            : Boolean := False; -- Table 49 S0: a session is
                                           -- still up, Start Up waits
      Waiting          : Natural := 0;   -- 0 none / 1 radio network /
                                         -- 2 an RBC answer / 3 the MA /
                                         -- 4 shunting / 5 SM answer
      Start_Pending    : Boolean := False;
      --  the radio data (byte 9) and radio_wait (byte 10); the default
      --  is an on-board that reports no radio data at all
      Radio_Type       : Natural := 0;   -- 0 unknown / 1 FRMCS /
                                         -- 2 FRMCS+GSM-R / 3 GSM-R
      Radio_Installed  : Natural := 0;   -- 0 none / 1 FRMCS / 2 GSM-R /
                                         -- 3 both
      FRMCS_Registered : Boolean := False;
      GSMR_Registered  : Boolean := False;
      One_Radio_Yes    : Boolean := False;
      RBC_Contact_Known : Boolean := False;
      Radio_Wait       : Natural := 0;   -- 0 none / 1 list / 2 registration
      Authorised       : Boolean := False); -- answer (byte 11)

   -- The scenario brings its own EVC (EVC_Core) and sends MSG_ONBOARD
   -- itself: the wrapper stops sending its model. Reset_EVC_Model turns
   -- it off again.
   procedure External_EVC (On : Boolean := True);

   -- The same message with the eight bytes exactly as they travel on the
   -- wire, for values the wrapper above cannot express. It takes the
   -- on-board state over: the wrapper stops sending its own model until
   -- the next Send_Onboard (or Reset_EVC_Model).
   procedure Send_Onboard_Raw
     (Data, Session, RBC, Train, National, SOM, Waiting, Start_Pending
        : Interfaces.Unsigned_8;
      Radio, Radio_Wait, Answer : Interfaces.Unsigned_8 := 0);

   -- MSG_SYSTEM_VERSION: the operated system version X.Y (any byte
   -- values, for the "not known" ones too)
   procedure Send_System_Version (X, Y : Natural);

   -- MSG_VBC_LIST: the set codes of the VBCs stored on-board
   type Code_Array is array (Positive range <>) of Natural;
   procedure Send_VBC_List (Codes : Code_Array);

   -- MSG_RADIO_NETWORKS with the names separated by ',' ("" is the empty
   -- list)
   procedure Send_Radio_Networks (Names : String);

   procedure Send_Text (ID           : Natural;
                        Text         : Wide_String;
                        First_Group  : Boolean := False;
                        Ack_Required : Boolean := False;
                        Class        : Natural := 1; -- 0 fixed/1 plain/2 sys/3 NTC
                        HH, MM       : Natural := 0);

   procedure Send_Text_Remove (ID : Natural);

   -- MSG_SYSTEM_STATUS: an event of a catalogue entry (DMI_Protocol.SS_*;
   -- Event 0 start, 1 end, 2 the event that starts the 30 s)
   procedure Send_System_Status (Number : Natural; Event : Natural := 0);

   -- Kinds: 1..37 TC symbol number, 38 LX
   type TC_Array is array (Positive range <>) of Natural;
   procedure Send_Track_Cond (Kinds : TC_Array);

   -- The same with the object ids chosen by the caller
   type TC_Item is record
      ID   : Natural; -- 0 .. 255
      Kind : Natural; -- 0 .. 255
   end record;
   type TC_Item_Array is array (Positive range <>) of TC_Item;
   procedure Send_Track_Cond_IDs (Items : TC_Item_Array);

   type Gradient_Array is array (Positive range <>) of Integer;
   -- Gradients: pairs (start_m, permille); Speeds: triples
   -- (dist_m, km/h, ind_target 0/1); Orders: pairs (PL number, dist_m)
   procedure Send_Planning
     (MA_Dist    : Natural;
      Ceiling    : Natural;
      Indication : Natural := 16#FFFF#;
      Advice     : Natural := 16#FFFF#;
      Gradients  : Gradient_Array := (1 .. 0 => 0);
      Speeds     : Gradient_Array := (1 .. 0 => 0);
      Orders     : Gradient_Array := (1 .. 0 => 0));

   -- MSG_ATO (dmi_protocol.ads), the information of the ERTMS/ATO
   -- on-board of DMI 8.5 and the ATO selector position. The defaults
   -- are the selector "On" with nothing else known; Stops are the
   -- distances of the stopping points in metres.
   type Stop_Array is array (Positive range <>) of Natural;
   procedure Send_ATO
     (Selector     : Natural := 2;        -- 1 Stand-by / 2 On
      Status       : Natural := 0;        -- 0 none / 1 .. 5 ATO01 .. 05
      Warning      : Boolean := False;
      At_Stop      : Boolean := False;    -- location: at a stopping point
      Accuracy     : Natural := 0;        -- 0 none / 1 .. 3 ATO06 .. 08
      Dwell        : Natural := 16#FFFF#; -- seconds
      Train_Hold   : Boolean := False;
      Doors        : Natural := 0;        -- 0 none / 1 .. 7 ATO10 .. 16
      Skip         : Natural := 0;        -- 0 none / 1 .. 3 ATO17 .. 19
      Advice_Speed : Natural := 16#FFFF#; -- km/h
      Coasting     : Boolean := False;
      ETA_H        : Natural := 16#FF#;   -- 16#FF#: no arrival time
      ETA_M, ETA_S : Natural := 0;
      Name         : String := "";
      Stops        : Stop_Array := (1 .. 0 => 0));

   -- Any message type with any payload, byte by byte (each 0 .. 255),
   -- for malformed and hostile input
   type Byte_Array is array (Positive range <>) of Natural;
   procedure Send_Raw (The_Type : Natural; Bytes : Byte_Array);

   procedure Pointer_Down (X, Y : Natural);
   procedure Pointer_Up (X, Y : Natural);

   -- Render one frame (with a 50 ms tick)
   procedure Step;

   -- Compare the screen against test/golden/<Name>.frame, or record it
   -- when UPDATE=1; failures are counted and reported by Summary
   procedure Check_Frame (Name : String);

   -- The next queued sound must be exactly this one
   procedure Expect_Sound (The_Sound : DMI_Sounds.Sound_T;
                           What      : String);

   -- No sounds may be pending
   procedure Expect_No_Sound (What : String);

   procedure Drain_Sounds;

   -- Forget the messages queued for the EVC so far. Like the two checks
   -- below this empties the DMI outbox, which also takes the pending
   -- sounds with it: check the sounds first.
   procedure Drain_Outbox;

   -- The messages queued for the EVC since the last call must hold
   -- exactly one acknowledgement (MSG_DRIVER_ACTION, action 2, long
   -- form) naming this kind (DMI_Ack.Ack_Kind_T'Pos) and text message id
   procedure Expect_Ack (Kind : Natural; ID : Natural; What : String);

   -- ... must hold no acknowledgement
   procedure Expect_No_Ack (What : String);

   -- The messages queued for the EVC since the last call must hold
   -- exactly Count driver actions (MSG_DRIVER_ACTION) with this action
   -- code; empties the outbox like the checks above
   procedure Expect_Actions (Action : Natural;
                             Count  : Natural;
                             What   : String);

   -- ... must hold exactly one driver action with this action code, and
   -- its argument must be Arg; empties the outbox like the checks above
   procedure Expect_Action (Action : Natural;
                            Arg    : Natural;
                            What   : String);
   -- its argument must be Arg
   procedure Expect_Action_Arg (Action : Natural;
                                Arg    : Natural;
                                What   : String);

   -- ... must hold exactly one MSG_DRIVER_DATA of this kind, and its
   -- payload after the kind byte must be Bytes
   procedure Expect_Driver_Data (Kind  : Natural;
                                 Bytes : Byte_Array;
                                 What  : String);

   -- MSG_DESK_INPUT: a key of the DMI unit on the desk goes down
   -- (Pressed = 1) or comes up (0); DMI_Protocol.DESK_*
   procedure Send_Desk_Input (Input : Natural; Pressed : Natural);

   -- The messages queued since the last call (sounds included) must
   -- hold exactly Count MSG_SETTINGS, the last one with these values
   -- (not checked when Count is 0); empties the outbox like the checks
   -- above
   procedure Expect_Settings (Count      : Natural;
                              Brightness : Natural;
                              Volume     : Natural;
                              Isolated   : Natural;
                              What       : String);
   -- ... must hold no MSG_DRIVER_DATA of this kind
   procedure Expect_No_Driver_Data (Kind : Natural; What : String);

   -- Simple boolean check
   procedure Check (Condition : Boolean; What : String);

   -- Print results; returns the exit status (0 = all passed)
   function Summary return Natural;

end Test_Support;
