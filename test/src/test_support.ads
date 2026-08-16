--  ETCS DMI
--  Support for the headless regression runner: drives DMI_Core directly
--  (no sockets), captures golden frames and checks sounds/actions.
--
--  Golden frames live in test/golden/*.frame . Run with UPDATE=1 in the
--  environment to (re)record them instead of comparing.

with DMI_Sounds;

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

   procedure Send_Mode_Level
     (Mode          : Natural;           -- Mode_T'Pos
      Level         : Natural;           -- Level_T'Pos
      Mode_Ack      : Natural := 16#FF#;
      Level_Ann     : Natural := 16#FF#;
      Level_Ann_Ack : Boolean := False;
      Override      : Boolean := False;
      TAF           : Boolean := False;
      LSSMA         : Natural := 16#FFFF#);

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

   -- Simple boolean check
   procedure Check (Condition : Boolean; What : String);

   -- Print results; returns the exit status (0 = all passed)
   function Summary return Natural;

end Test_Support;
