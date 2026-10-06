--  ETCS DMI test simulator
--  The environment of the ETCS on-board (EVC_Core, evc/) on the bench:
--  the trackside (Sim_Trackside), the vehicle (EVC_Train with the train
--  interface of Sim_Vehicle), the odometer (Sim_Odometer), the JRU sink
--  (Sim_JRU) and the driver (the desk or EVC_Driver.Auto_Drive_Onboard).
--  The wasm module onboard.wasm (test/wasm/onboard_wasm), the hosted main
--  obj/evc_onboard (ports/hosted/evc.adb) and evc_test run the on-board
--  in it; they only move the bytes of the DMI link.
--
--  One Step (Dt_Ms) is one cycle of the on-board:
--    1. the driver sets the demand, from what the on-board's DMI frames
--       of the last cycle said (speed, permitted speed, monitoring) and
--       its brake commands;
--    2. the vehicle moves (EVC_Train), obeying the commands of the last
--       TIU output, or the emergency brake if the on-board failed;
--    3. the odometer samples the movement of the balise antenna (in
--       rear of the cab A end by the antenna of the configuration,
--       EVC_Core.Configuration, 3 m by default: the train runs cab A
--       first); every balise the antenna passed goes to the BTM port
--       with its stamp, in the order of passing, then the odometer
--       sample, then the TIU inputs that changed;
--    4. EVC_Core.Tick;
--    5. the outputs: the DMI frames are queued for Take_DMI (and read
--       for step 1), the TIU output goes to the vehicle, the JRU records
--       to Sim_JRU.
--  Frames from the DMI (Receive, any chunking) go to the on-board's DMI
--  port as they arrive and are read at its next cycle; MSG_DESK (the
--  desk of the TCP bench) sets the desk here. The brake release the
--  on-board asks for (MSG_STATUS brake 2, 3.14.1.9) is acknowledged on
--  the DMI, which sends MSG_DRIVER_ACTION 2 kind 5; the scenarios
--  without a DMI send Brake_Release_Ack themselves when Ack_Requested.
--
--  Everything that reaches a port is integer: the vehicle integrates in
--  Float (EVC_Train), its position and speed are quantised to cm and
--  cm/s with Float'Floor at the boundary, and the odometer, the
--  balises and the TIU work on those integers. The only Float
--  operations are IEEE single +, -, *, / and comparisons, correctly
--  rounded on every target (no library function, no fused multiply-add
--  at -O0 natively or in wasm32), so the native and the wasm builds
--  feed the on-board the same bytes (test/wasm/onboard_smoke.js).

with Ada.Streams; use Ada.Streams;
with EVC_Track;
with Sim_Vehicle;

package Sim_Onboard_Env is

   --  The balise antenna of the vehicle, cm in rear of its cab A end:
   --  the installation the on-board is configured with
   --  (EVC_Core.Configuration, EVC_Config)
   function Antenna_To_Cab_A_Cm return Integer;

   --  The train's front end at power-up (m): its antenna 1 m in rear of
   --  the first balise of the first group
   function Start_Front_M return Float is
     (Float (EVC_Track.Balise_Groups (1).At_M) - 1.0
      + Float (Antenna_To_Cab_A_Cm) / 100.0);

   --  Power-up of the on-board and of the vehicle, the train at
   --  Start_Front_M, the desk on auto drive, the track of the last
   --  Set_Track_Preset (Default, until the page or a host calls it)
   procedure Reset;

   --  The track of the next Reset (EVC_Track.Preset_T): the default
   --  mission (the acceptance run, the native golden) or the bench
   --  page's alternate "features" track (Sim_Trackside, EVC_Track)
   procedure Set_Track_Preset (Preset : EVC_Track.Preset_T);
   function Track_Preset return EVC_Track.Preset_T;

   --  The driver desk: traction/brake demand in -100 .. 100, or the
   --  automatic driver
   procedure Set_Desk (Demand : Integer; Auto : Boolean);

   --  The train interface inputs besides the desk demand (Sim_Vehicle):
   --  the cab, the direction controller, sleeping requested, passive
   --  shunting and non leading permitted, the train configuration (TIU
   --  input 13)
   procedure Set_Cab (Cab : Sim_Vehicle.Cab_T);
   procedure Set_Controller (Position : Sim_Vehicle.Byte);
   procedure Set_Sleeping (On : Boolean);
   procedure Set_Passive_Shunting (On : Boolean);
   procedure Set_Non_Leading (On : Boolean);
   procedure Set_Train_Configuration (Value : Sim_Vehicle.Byte);

   --  Phase E5: the scripted RBC (Sim_RBC) behind the RTM port, off by
   --  default (the bench mission and its golden do not change): when
   --  on, the on-board's RTM outputs go to Sim_RBC and its answers to
   --  the RTM port before each cycle; Reset keeps the switch and resets
   --  the RBC. RBC_Emergency_Stop: message 16 from the RBC (a button)
   --  With the radio on, the driver's start of mission is that of level 2
   --  (SoM_L2_Frame), scripted here: a scripted driver like the automatic
   --  one of the desk, so that the page, onboard_smoke.js and evc_test
   --  give the on-board the same bytes at the same cycles
   procedure Set_Radio (On : Boolean);
   function Radio return Boolean;
   procedure RBC_Emergency_Stop;

   --  Bytes from the DMI
   procedure Receive (Data : Stream_Element_Array);

   --  One cycle
   procedure Step (Dt_Ms : Natural);

   --  The DMI frames of the on-board since the last call, whole; those
   --  that do not fit stay queued
   procedure Take_DMI (Buffer : out Stream_Element_Array;
                       Last   : out Stream_Element_Offset);

   --  Containment (EVC_Core.Enter_Failure): the host calls it when a
   --  call into the on-board failed (a trap in wasm, an exception
   --  natively); the on-board falls silent and the vehicle brakes
   procedure Enter_Failure;
   function Failed return Boolean;

   --  The driver's acknowledgement of a brake release, as the DMI sends
   --  it (MSG_DRIVER_ACTION, action 2, kind 5, no id)
   Brake_Release_Ack : constant Stream_Element_Array :=
     (16#40#, 5, 0, 0, 0, 2, 5, 0, 0, 0);

   --  Phase E4: the driver's start of mission in level 1 (SUBSET-026
   --  5.4.3.2), as the DMI sends it at the end of each step of its
   --  start-up dialogue (DMI 11.7.2, Table 49): the driver ID "1234"
   --  (S1), level 1 (S2, MSG_DRIVER_ACTION 11, the level code 4), the
   --  Train Data of the train of the line (S12: 200 m, 135 %, 160 km/h,
   --  cant deficiency 130 mm, passenger train, axle load A, not airtight,
   --  loading gauge G1: the default train of EVC_Train_Data), the train
   --  running number "5678" (S13), 'Start' (S20) and the acknowledgement
   --  of Staff Responsible (S24, MSG_DRIVER_ACTION 2, kind 1). The
   --  scenarios without a DMI send step K after cycle K
   --  (test/src/evc_test.adb Scenario_Bench_Onboard and
   --  test/wasm/onboard_smoke.js, which must send the same bytes).
   SoM_Steps : constant := 6;
   function SoM_Frame (K : Positive) return Stream_Element_Array
     with Pre => K <= SoM_Steps;

   --  Phase E5: the driver's start of mission in level 2 (5.4.3.2), the
   --  frames of Scenario_Session_SoM_Level_2 (test/src/
   --  evc_test_sessions.adb): the driver ID "1234" (S1), level 2 (S2,
   --  MSG_DRIVER_ACTION 11, the level code 5), the RBC contact entered
   --  (S3: RBC 1 of Sim_RBC, NID_C of the line, NID_RBC 1, phone "0077"),
   --  the Train Data (S12) as in level 1, the train running number (S13)
   --  'Start' (S20) and the acknowledgement of Staff Responsible (S24,
   --  when the RBC gives an SR authorisation). Step K goes once the on-board answered step K - 1
   --  in its MSG_ONBOARD (SoM_L2_Ready): the driver ID valid, the level
   --  valid, the session established and nothing awaited, the Train Data
   --  acknowledged by the RBC, the train running number valid, SR to
   --  acknowledge (MSG_MODE_LEVEL mode_ack). With the
   --  radio on, Step sends them itself (Set_Radio); SoM_L2_Sent counts
   --  them.
   SoM_L2_Steps : constant := 7;
   function SoM_L2_Frame (K : Positive) return Stream_Element_Array
     with Pre => K <= SoM_L2_Steps;
   function SoM_L2_Ready (K : Positive) return Boolean
     with Pre => K <= SoM_L2_Steps;
   function SoM_L2_Sent return Natural;

   --  MSG_ONBOARD of the last cycle: data, session, rbc, waiting
   --  (dmi_protocol.ads); 0 before the first one
   function Onboard_Data return Natural;
   function Onboard_Session return Natural;
   function Onboard_RBC return Natural;
   function Onboard_Waiting return Natural;

   ---------------------------------------------------------------------
   --  What the on-board said last (its DMI frames) and the vehicle
   ---------------------------------------------------------------------

   --  MSG_MODE_LEVEL: the mode code (DMI Table 60) and the level code;
   --  255 before the first frame
   function Mode_Code return Natural;
   function Level_Code return Natural;
   --  MSG_SPEED_STATE (km/h), monitoring 0 CSM / 1 TSM / 2 RSM, status
   --  0 NoS .. 4 IntS
   function V_Cur_KMH return Natural;
   function V_Perm_KMH return Natural;
   function Monitoring return Natural;
   function Status return Natural;
   --  MSG_STATUS brake: 0 none, 1 applied, 2 acknowledgement asked
   function Brake_Indication return Natural;
   function Ack_Requested return Boolean;

   --  The vehicle: front end (m, rounded down), speed (km/h)
   function Position_M return Integer;
   function Speed_KMH return Natural;

   --  Balises detected, DMI bytes dropped because nobody took them
   function Balises_Read return Natural;
   function Dropped_DMI return Natural;

   --  The balise groups of the active track preset (m of their first
   --  balise), for the page's track strip: Sim_Trackside's own table,
   --  not EVC_Track.Balise_Groups directly, which is the default's
   function Group_Count return Natural;
   function Group_At (Index : Positive) return Integer
     with Pre => Index <= Group_Count;

   --  The second TIU output (5.20), as Sim_Vehicle has it, for the page
   function TC_Length return Natural;
   function TC_Payload return Sim_Vehicle.TIU_TC_Array;

   --  MSG_SIM_STATE for the page's track strip (dmi_protocol.ads): the
   --  position (m, 0 in rear of the mission start), the speed, the mode
   --  in the strip's numbering (0 SB / 1 SR / 2 FS / 3 TR / 4 AD / 5 SH
   --  / 6 SM / 7 IS, 255 another one), the monitoring, the demand, a
   --  brake commanded
   procedure Sim_State_Payload (Buffer : out Stream_Element_Array;
                                Last   : out Stream_Element_Offset)
     with Pre => Buffer'Length >= 10;

end Sim_Onboard_Env;
