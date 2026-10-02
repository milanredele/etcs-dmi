--  ETCS on-board (EVC)
--  WebAssembly host interface of the ETCS on-board of evc/ in the
--  environment of the bench (sim/sim_onboard_env.ads): the third module
--  of the page, onboard.wasm, in place of the simulator evc.wasm. Same
--  shape as EVC_Wasm: the page steps it and moves protocol frames between
--  this module and the DMI module through its simulated wire; the driver
--  desk and the track strip are local. The exports after Transmit show
--  the page what the on-board did (mode and level, train interface,
--  JRU).

with Interfaces; use Interfaces;
with System;

package Onboard_Wasm is

   -- Power-up of the on-board and of its train
   procedure Reset
     with Export, Convention => C, Link_Name => "onboard_reset";

   -- The installation configuration (evc/evc_config.ads, data and not
   -- code): the host writes its byte image (test/wasm/onboard.cfg, made
   -- by test/tools/evc_config.py) at Rx_Buffer and calls Configure with
   -- its length, before Reset. 1 when the on-board took it, 0 when it
   -- refused it (a bad image, or the on-board not in No Power: only
   -- before the first Step after the module was loaded or Reset); the
   -- on-board records either on its JRU at its next cycle
   function Configure (Length : Unsigned_32) return Integer_32
     with Export, Convention => C, Link_Name => "onboard_configure";

   -- Receive path (frames from the DMI): the host writes up to
   -- Rx_Capacity bytes at Rx_Buffer and calls Receive with the count
   function Rx_Buffer return System.Address
     with Export, Convention => C, Link_Name => "onboard_rx_buffer";
   function Rx_Capacity return Unsigned_32
     with Export, Convention => C, Link_Name => "onboard_rx_capacity";
   procedure Receive (Length : Unsigned_32)
     with Export, Convention => C, Link_Name => "onboard_receive";

   -- Driver desk: traction/brake demand in -100 .. 100, automatic
   -- driving overrides the demand while enabled
   procedure Set_Desk (Demand : Integer_32; Auto_Drive : Integer_32)
     with Export, Convention => C, Link_Name => "onboard_set_desk";

   -- The track of the next Reset (0 the default mission, the acceptance
   -- run and the native golden; 1 the alternate "features" track:
   -- EVC_Track.Preset_T); a host calls it before Reset
   procedure Set_Track_Preset (Preset : Integer_32)
     with Export, Convention => C, Link_Name => "onboard_set_track_preset";

   -- The train interface inputs besides the desk (Sim_Vehicle,
   -- SUBSET-034 2.5.1, 2.6.4.2): the cab (0 none, 1 A, 2 B; one desk
   -- open at a time), the direction controller of the active cab (0
   -- neutral, 1 forwards, 2 backwards), sleeping requested, passive
   -- shunting and non leading permitted, the train configuration of
   -- TIU input 13 (phase E4, a raw byte: bits 0-5 the configuration,
   -- bit 6 "needs validation", bit 7 "train category etc.", 5.17.2.2)
   procedure Set_Cab (Cab : Integer_32)
     with Export, Convention => C, Link_Name => "onboard_set_cab";
   procedure Set_Controller (Position : Integer_32)
     with Export, Convention => C, Link_Name => "onboard_set_controller";
   procedure Set_Sleeping (On : Integer_32)
     with Export, Convention => C, Link_Name => "onboard_set_sleeping";
   procedure Set_Passive_Shunting (On : Integer_32)
     with Export, Convention => C,
          Link_Name => "onboard_set_passive_shunting";
   procedure Set_Non_Leading (On : Integer_32)
     with Export, Convention => C, Link_Name => "onboard_set_non_leading";
   procedure Set_Train_Configuration (Value : Integer_32)
     with Export, Convention => C,
          Link_Name => "onboard_set_train_configuration";

   -- One cycle of the on-board and its environment, Dt_Ms milliseconds
   procedure Step (Dt_Ms : Unsigned_32)
     with Export, Convention => C, Link_Name => "onboard_step";

   -- Transmit path: Transmit fills Tx_Buffer with the on-board's DMI
   -- frames and the track strip frames (MSG_SIM_STATE every cycle,
   -- MSG_TRACK_LAYOUT every 2 s) and returns the byte count
   function Tx_Buffer return System.Address
     with Export, Convention => C, Link_Name => "onboard_tx_buffer";
   function Transmit return Unsigned_32
     with Export, Convention => C, Link_Name => "onboard_transmit";

   -- Containment: the wasm runtime cannot propagate exceptions, a raise
   -- inside the on-board (or its environment) traps. The host catches
   -- the trap and calls Enter_Failure (EVC_Core.Enter_Failure): the
   -- on-board falls silent, the train interface applies the emergency
   -- brake, the DMI shows SF when its link supervision expires. Stepping
   -- goes on (the train brakes to a stand) until Reset.
   procedure Enter_Failure
     with Export, Convention => C, Link_Name => "onboard_enter_failure";
   function Failed return Integer_32
     with Export, Convention => C, Link_Name => "onboard_failed";

   -- The odometer's true error and stated accuracy (ppm), from the next
   -- Reset (Sim_Odometer.Configure)
   procedure Set_Odometer (Scale_Ppm : Integer_32;
                           Noise_Ppm : Integer_32;
                           Bound_Ppm : Integer_32)
     with Export, Convention => C, Link_Name => "onboard_set_odometer";

   -- 1 while the on-board asks the driver to acknowledge a brake release
   -- (MSG_STATUS brake 2)
   function Ack_Requested return Integer_32
     with Export, Convention => C, Link_Name => "onboard_ack_requested";

   -- MSG_MODE_LEVEL: mode (DMI Table 60 code) and level code, 255 none
   function Mode return Integer_32
     with Export, Convention => C, Link_Name => "onboard_mode";
   function Level return Integer_32
     with Export, Convention => C, Link_Name => "onboard_level";

   -- The train interface: the last TIU output (commands: bit 0 EB, bit 1
   -- SB, bit 2 TCO; reasons: bit 0 supervision, 1 SB failed, 2 roll
   -- away, 3 direction, 4 standstill), the brake pipe pressure (kPa),
   -- the direction controller (0 neutral, 1 forwards, 2 backwards), 1
   -- while braking for a failed on-board
   function TIU_Commands return Integer_32
     with Export, Convention => C, Link_Name => "onboard_tiu_commands";
   function TIU_Reasons return Integer_32
     with Export, Convention => C, Link_Name => "onboard_tiu_reasons";

   -- The second TIU output (5.20, track conditions): the raw bytes at
   -- TC_Buffer (tag, version, count, items as EVC_Ports documents),
   -- TC_Length of them
   function TC_Buffer return System.Address
     with Export, Convention => C, Link_Name => "onboard_tiu_tc_buffer";
   function TC_Length return Integer_32
     with Export, Convention => C, Link_Name => "onboard_tiu_tc_length";
   function Brake_Pressure return Integer_32
     with Export, Convention => C, Link_Name => "onboard_brake_pressure";
   function Controller return Integer_32
     with Export, Convention => C, Link_Name => "onboard_controller";
   function Fail_Safe return Integer_32
     with Export, Convention => C, Link_Name => "onboard_fail_safe";

   -- The train: front end (m, may be negative before the start), speed
   function Position return Integer_32
     with Export, Convention => C, Link_Name => "onboard_position";
   function Speed return Integer_32
     with Export, Convention => C, Link_Name => "onboard_speed";

   -- The balise groups of the line (m of their first balise)
   function Group_Count return Integer_32
     with Export, Convention => C, Link_Name => "onboard_group_count";
   function Group_At (Index : Integer_32) return Integer_32
     with Export, Convention => C, Link_Name => "onboard_group_at";

   -- The JRU sink: records since Reset; Describe (Age) writes the text of
   -- a record (Age 0 the newest, below Jru_Available) at Text_Buffer and
   -- returns its length
   function JRU_Count return Integer_32
     with Export, Convention => C, Link_Name => "onboard_jru_count";
   function JRU_Available return Integer_32
     with Export, Convention => C, Link_Name => "onboard_jru_available";
   function JRU_Describe (Age : Integer_32) return Integer_32
     with Export, Convention => C, Link_Name => "onboard_jru_describe";
   function Text_Buffer return System.Address
     with Export, Convention => C, Link_Name => "onboard_text_buffer";

end Onboard_Wasm;
