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

end EVC_DMI_Port;
