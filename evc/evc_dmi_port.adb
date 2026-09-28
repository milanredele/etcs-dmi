--  ETCS on-board (EVC)
--  The DMI port, implementation.

package body EVC_DMI_Port
  with SPARK_Mode => On
is

   ----------------------
   -- Mode_Level_Frame --
   ----------------------

   function Mode_Level_Frame (Mode   : Mode_T;
                              Status : Level_Status_T;
                              Level  : Level_T) return Mode_Level_Frame_T
   is
     (MSG_MODE_LEVEL,
      Mode_Level_Length, 0, 0, 0,     -- length u32
      Mode_Code (Mode),               -- mode
      Level_Code (Status, Level),     -- level
      16#FF#,                         -- mode_ack: none
      16#FF#,                         -- level_ann: none
      0,                              -- level_ann_ack
      0,                              -- override
      0,                              -- taf
      16#FF#, 16#FF#);                -- lssma: not shown

   -------------------
   -- Onboard_Frame --
   -------------------

   function Onboard_Frame (Onboard : Onboard_T) return Onboard_Frame_T is
     (MSG_ONBOARD,
      Onboard_Length, 0, 0, 0,        -- length u32
      Onboard.Data,
      Onboard.Session,
      Onboard.RBC,
      Onboard.Train,
      Onboard.National,
      Onboard.SoM,
      Onboard.Waiting,
      Onboard.Start_Pending,
      Onboard.Radio,
      Onboard.Radio_Wait,
      Onboard.Answer);

   ------------------
   -- Status_Frame --
   ------------------

   function Status_Frame (Geo : Unsigned_32; Seconds : Unsigned_64)
     return Status_Frame_T
   is
     (MSG_STATUS,
      Status_Length, 0, 0, 0,         -- length u32
      0,                              -- brake: none
      0,                              -- radio: no connection
      0,                              -- adhesion
      0,                              -- bmm
      0,                              -- reversing
      0,                              -- sm_direction
      16#FF#, 16#FF#,                 -- set_speed: none
      16#FF#, 16#FF#,                 -- tti: none
      14,                             -- t_disp_tti
      0,                              -- tunnel: unknown
      0, 0, 0, 0,                     -- tunnel_dist
      Byte (Geo and 16#FF#),          -- geo_pos u32
      Byte (Shift_Right (Geo, 8) and 16#FF#),
      Byte (Shift_Right (Geo, 16) and 16#FF#),
      Byte (Shift_Right (Geo, 24)),
      Byte (Seconds / 3600 mod 24),   -- hour
      Byte (Seconds / 60 mod 60),     -- minute
      Byte (Seconds mod 60));         -- second

   -----------------------
   -- Speed_State_Frame --
   -----------------------

   function Speed_State_Frame (S : Speed_State_T) return Speed_State_Frame_T
   is
     (MSG_SPEED_STATE,
      Speed_State_Length, 0, 0, 0,    -- length u32
      Byte (S.V_Cur and 16#FF#), Byte (Shift_Right (S.V_Cur, 8)),
      Byte (S.V_Perm and 16#FF#), Byte (Shift_Right (S.V_Perm, 8)),
      Byte (S.V_Target and 16#FF#), Byte (Shift_Right (S.V_Target, 8)),
      Byte (S.V_Release and 16#FF#), Byte (Shift_Right (S.V_Release, 8)),
      Byte (S.V_SBI and 16#FF#), Byte (Shift_Right (S.V_SBI, 8)),
      Byte (S.V_Wsl and 16#FF#), Byte (Shift_Right (S.V_Wsl, 8)),
      Byte (S.D_Target and 16#FF#),
      Byte (Shift_Right (S.D_Target, 8) and 16#FF#),
      Byte (Shift_Right (S.D_Target, 16) and 16#FF#),
      Byte (Shift_Right (S.D_Target, 24)),
      S.Monitoring,
      S.Dial_Range,
      S.Flags,
      S.Status,
      S.MRDT);

   ------------------
   -- Status_Frame --
   ------------------

   function Status_Frame (Geo     : Unsigned_32;
                          Seconds : Unsigned_64;
                          Brake   : Byte;
                          TTI     : Unsigned_16) return Status_Frame_T
   is
     (MSG_STATUS,
      Status_Length, 0, 0, 0,         -- length u32
      Brake,                          -- brake
      0,                              -- radio: no connection
      0,                              -- adhesion
      0,                              -- bmm
      0,                              -- reversing
      0,                              -- sm_direction
      16#FF#, 16#FF#,                 -- set_speed: none
      Byte (TTI and 16#FF#),          -- tti u16
      Byte (Shift_Right (TTI, 8)),
      14,                             -- t_disp_tti
      0,                              -- tunnel: unknown
      0, 0, 0, 0,                     -- tunnel_dist
      Byte (Geo and 16#FF#),          -- geo_pos u32
      Byte (Shift_Right (Geo, 8) and 16#FF#),
      Byte (Shift_Right (Geo, 16) and 16#FF#),
      Byte (Shift_Right (Geo, 24)),
      Byte (Seconds / 3600 mod 24),   -- hour
      Byte (Seconds / 60 mod 60),     -- minute
      Byte (Seconds mod 60));         -- second

end EVC_DMI_Port;
