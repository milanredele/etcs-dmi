--  ETCS on-board (EVC)
--  The DMI port, implementation.

package body EVC_DMI_Port
  with SPARK_Mode => On
is

   ----------------------
   -- Mode_Level_Frame --
   ----------------------

   function Mode_Level_Frame (Mode          : Mode_T;
                              Status        : Level_Status_T;
                              Level         : Level_T;
                              Mode_Ack      : Byte := No_Code;
                              Level_Ann     : Byte := No_Code;
                              Level_Ann_Ack : Boolean := False;
                              Override      : Boolean := False)
     return Mode_Level_Frame_T
   is
     (MSG_MODE_LEVEL,
      Mode_Level_Length, 0, 0, 0,     -- length u32
      Mode_Code (Mode),               -- mode
      Level_Code (Status, Level),     -- level
      Mode_Ack,                       -- mode_ack
      Level_Ann,                      -- level_ann
      (if Level_Ann_Ack then 1 else 0),  -- level_ann_ack
      (if Override then 1 else 0),    -- override
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

   ---------------------------------------------------------------------
   --  Phase E3 (profiles)
   ---------------------------------------------------------------------

   --  A u16 at Frame (I .. I + 1), little endian
   procedure Put_U16 (Frame : in out Frame_Buffer_T;
                      I     : Positive;
                      V     : Unsigned_16)
     with Pre => I in 2 .. Max_Frame_Length - 1,
          Post => Frame (1) = Frame'Old (1)
   is
   begin
      Frame (I) := Byte (V and 16#FF#);
      Frame (I + 1) := Byte (Shift_Right (V, 8));
   end Put_U16;

   --  The frame header: type, payload length u32
   procedure Put_Header (Frame  : in out Frame_Buffer_T;
                         Kind   : Byte;
                         Length : Natural)
     with Pre => Length <= Max_Frame_Length,
          Post => Frame (1) = Kind
   is
   begin
      Frame (1) := Kind;
      Frame (2) := Byte (Length mod 256);
      Frame (3) := Byte (Length / 256);
      Frame (4) := 0;
      Frame (5) := 0;
   end Put_Header;

   ----------------------
   -- Track_Cond_Frame --
   ----------------------

   procedure Track_Cond_Frame (Count  : Natural;
                               List   : Track_Cond_List_T;
                               Frame  : out Frame_Buffer_T;
                               Last   : out Natural)
   is
   begin
      Frame := (others => 0);
      Put_Header (Frame, MSG_TRACK_COND, 1 + 2 * Count);
      Frame (6) := Byte (Count);
      for I in 1 .. Count loop
         pragma Loop_Invariant (Frame (1) = MSG_TRACK_COND);
         Frame (5 + 2 * I) := List (I).Id;
         Frame (6 + 2 * I) := List (I).Kind;
      end loop;
      Last := Header_Length + 1 + 2 * Count;
   end Track_Cond_Frame;

   --------------------
   -- Planning_Frame --
   --------------------

   procedure Planning_Frame (P     : Planning_T;
                             Frame : out Frame_Buffer_T;
                             Last  : out Natural)
   is
      I : Positive := Header_Length + 1;
   begin
      Frame := (others => 0);
      Put_Header (Frame, MSG_PLANNING, Planning_Length (P));
      Put_U16 (Frame, I, P.MA_Dist);
      Put_U16 (Frame, I + 2, P.Indication_Dist);
      Put_U16 (Frame, I + 4, P.Advice_Dist);
      Put_U16 (Frame, I + 6, P.Ceiling);
      I := I + 8;
      Frame (I) := Byte (P.Gradient_Count);
      I := I + 1;
      for K in 1 .. P.Gradient_Count loop
         pragma Loop_Invariant
           (I = Header_Length + 10 + 3 * (K - 1)
            and then Frame (1) = MSG_PLANNING);
         Put_U16 (Frame, I, P.Gradients (K).Start);
         Frame (I + 2) :=
           Byte ((P.Gradients (K).Value + 256) mod 256);
         I := I + 3;
      end loop;
      Frame (I) := Byte (P.Speed_Count);
      I := I + 1;
      for K in 1 .. P.Speed_Count loop
         pragma Loop_Invariant
           (I = Header_Length + 11 + 3 * P.Gradient_Count + 4 * (K - 1)
            and then Frame (1) = MSG_PLANNING);
         Put_U16 (Frame, I, P.Speeds (K).Dist);
         Put_U16 (Frame, I + 2, P.Speeds (K).Speed);
         I := I + 4;
      end loop;
      Frame (I) := Byte (P.Order_Count);
      I := I + 1;
      for K in 1 .. P.Order_Count loop
         pragma Loop_Invariant
           (I = Header_Length + 12 + 3 * P.Gradient_Count
                + 4 * P.Speed_Count + 3 * (K - 1)
            and then Frame (1) = MSG_PLANNING);
         Frame (I) := P.Orders (K).Symbol;
         Put_U16 (Frame, I + 1, P.Orders (K).Dist);
         I := I + 3;
      end loop;
      Last := Header_Length + Planning_Length (P);
   end Planning_Frame;

   ---------------------------------------------------------------------
   --  Phase E3 (supervision)
   ---------------------------------------------------------------------

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

   ---------------------------------------------------------------------
   --  Phase E3 (supervision), phase E4 (the procedures)
   ---------------------------------------------------------------------

   ------------------
   -- Status_Frame --
   ------------------

   function Status_Frame (Geo         : Unsigned_32;
                          Seconds     : Unsigned_64;
                          Brake       : Byte;
                          TTI         : Unsigned_16;
                          Reversing   : Boolean := False;
                          Tunnel      : Byte := 0;
                          Tunnel_Dist : Unsigned_32 := 0;
                          Radio       : Byte := 0)
     return Status_Frame_T
   is
     (MSG_STATUS,
      Status_Length, 0, 0, 0,         -- length u32
      Brake,                          -- brake
      Radio,                          -- radio (phase E5)
      0,                              -- adhesion
      0,                              -- bmm
      (if Reversing then 1 else 0),   -- reversing
      0,                              -- sm_direction
      16#FF#, 16#FF#,                 -- set_speed: none
      Byte (TTI and 16#FF#),          -- tti u16
      Byte (Shift_Right (TTI, 8)),
      14,                             -- t_disp_tti
      Tunnel,                         -- tunnel
      Byte (Tunnel_Dist and 16#FF#),  -- tunnel_dist u32
      Byte (Shift_Right (Tunnel_Dist, 8) and 16#FF#),
      Byte (Shift_Right (Tunnel_Dist, 16) and 16#FF#),
      Byte (Shift_Right (Tunnel_Dist, 24)),
      Byte (Geo and 16#FF#),          -- geo_pos u32
      Byte (Shift_Right (Geo, 8) and 16#FF#),
      Byte (Shift_Right (Geo, 16) and 16#FF#),
      Byte (Shift_Right (Geo, 24)),
      Byte (Seconds / 3600 mod 24),   -- hour
      Byte (Seconds / 60 mod 60),     -- minute
      Byte (Seconds mod 60));         -- second

   procedure Text_Frame (Id     : Unsigned_16;
                         Flags  : Byte;
                         Hour   : Byte;
                         Minute : Byte;
                         Text   : Byte_Array;
                         Frame  : out Frame_Buffer_T;
                         Last   : out Natural)
   is
      First : constant Positive := Header_Length + Text_Header_Length + 1;
   begin
      Frame := (others => 0);
      Put_Header (Frame, MSG_TEXT, Text_Header_Length + Text'Length);
      Put_U16 (Frame, Header_Length + 1, Id);
      Frame (Header_Length + 3) := Flags;
      Frame (Header_Length + 4) := Hour;
      Frame (Header_Length + 5) := Minute;
      Frame (Header_Length + 6) := Byte (Text'Length);
      for I in 0 .. Text'Length - 1 loop
         pragma Loop_Invariant (Frame (1) = MSG_TEXT);
         Frame (First + I) := Text (Text'First + I);
      end loop;
      Last := Header_Length + Text_Header_Length + Text'Length;
   end Text_Frame;

end EVC_DMI_Port;
