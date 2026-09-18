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
      Brake_Commanded : Boolean := False);

   -- The same message with the fields exactly as they travel on the wire,
   -- for values the EVC can send but the wrapper above cannot express
   -- (u16 speeds, u32 distance, undefined monitoring/dial codes, all flags)
   procedure Send_Speed_State_Raw
     (V_Cur, V_Perm, V_Target, V_Release, V_Sbi, V_Wsl : Interfaces.Unsigned_16;
      D_Target   : Interfaces.Unsigned_32;
      Monitoring : Interfaces.Unsigned_8;
      Dial_Range : Interfaces.Unsigned_8;
      Flags      : Interfaces.Unsigned_8);

   procedure Send_Mode_Level
     (Mode          : Natural;           -- Mode_T'Pos
      Level         : Natural;           -- Level_T'Pos
      Mode_Ack      : Natural := 16#FF#;
      Level_Ann     : Natural := 16#FF#;
      Level_Ann_Ack : Boolean := False;
      Override      : Boolean := False;
      TAF           : Boolean := False;
      LSSMA         : Natural := 16#FFFF#);

   procedure Send_Status
     (Brake        : Natural := 0;   -- 0 none / 1 shown / 2 ack required
      Radio        : Natural := 0;   -- 0 none / 1 up / 2 lost
      Adhesion     : Boolean := False;
      BMM          : Boolean := False;
      Reversing    : Boolean := False;
      SM_Direction : Natural := 0;   -- 0 none / 1 fwd / 2 bwd
      Set_Speed    : Natural := 16#FFFF#;
      TTI          : Natural := 16#FF#;
      T_Disp_TTI   : Natural := 14;
      Tunnel       : Natural := 0;   -- 0 unknown / 1 active / 2 announced
      Tunnel_Dist  : Natural := 0;
      Geo_Pos      : Natural := 16#7FFF_FFFF#; -- metres; huge = unknown
      Geo_Valid    : Boolean := False;
      HH, MM, SS   : Natural := 0);

   procedure Send_Text (ID           : Natural;
                        Text         : Wide_String;
                        First_Group  : Boolean := False;
                        Ack_Required : Boolean := False;
                        Class        : Natural := 1; -- 0 fixed/1 plain/2 sys/3 NTC
                        HH, MM       : Natural := 0);

   procedure Send_Text_Remove (ID : Natural);

   -- Kinds: 1..37 TC symbol number, 38 LX
   type TC_Array is array (Positive range <>) of Natural;
   procedure Send_Track_Cond (Kinds : TC_Array);

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

   -- Simple boolean check
   procedure Check (Condition : Boolean; What : String);

   -- Print results; returns the exit status (0 = all passed)
   function Summary return Natural;

end Test_Support;
