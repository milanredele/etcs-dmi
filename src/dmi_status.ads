--  ETCS DMI
--  Miscellaneous EVC-driven display state of the default window
--  (chapter 8.2.2.3, 8.2.3.5 - 8.2.3.11, 8.4) plus the related driver
--  toggle states.

package DMI_Status is

   type Brake_T is (None, Shown, Shown_Ack_Required);   -- 8.2.2.3
   type Radio_T is (No_Connection, Connection_Up, Connection_Lost); -- 8.4.1
   type Tunnel_T is (Unknown, Active, Announced);       -- 8.2.3.6
   type SM_Direction_T is (None, Forward, Backward);    -- 8.2.3.10

   Brake               : Brake_T := None;
   Radio               : Radio_T := No_Connection;
   Slippery_Rail       : Boolean := False;              -- 8.2.3.7
   BMM_Inhibited       : Boolean := False;              -- 8.2.3.11
   Reversing_Permitted : Boolean := False;              -- 8.4.2
   SM_Direction        : SM_Direction_T := None;

   Set_Speed_Valid : Boolean := False;                  -- 8.2.3.9
   Set_Speed       : Natural := 0;

   -- 8.2.2.5: TTI value is only sent when requested by National Value
   TTI_Valid   : Boolean := False;
   TTI_Seconds : Natural := 0;
   T_Disp_TTI  : Natural := 14;

   Tunnel            : Tunnel_T := Unknown;
   Tunnel_Distance   : Natural := 0;
   Tunnel_Toggled_On : Boolean := False;                -- 8.2.3.6.4

   Geo_Valid      : Boolean := False;                   -- 8.4.4.3
   Geo_Position_M : Natural := 0;
   Geo_Toggled_On : Boolean := False;                   -- 8.4.4.5

   Time_H, Time_M, Time_S : Natural := 0;               -- 8.4.3

   -- Track conditions / level crossing for B3/4/5 (8.2.3.5 / 8.2.3.8):
   -- kept in arrival order; the first three occupy the areas, the rest
   -- wait for a free slot (8.2.3.5.3)
   LX_Kind : constant := 38; -- kinds 1..37 are TC symbols
   type TC_Entry_T is record
      ID   : Natural := 0;
      Kind : Natural range 1 .. 38 := 1;
   end record;
   type TC_List_T is array (1 .. 8) of TC_Entry_T;
   TC_List  : TC_List_T;
   TC_Count : Natural := 0;

   -- Replace the active set, preserving arrival order of known ids
   procedure Reconcile_Track_Conditions (New_List  : TC_List_T;
                                         New_Count : Natural);

   -- Display condition of the TTI per Table 15a (mode, monitoring,
   -- National Value, toggle for OS/SR)
   function TTI_Displayed return Boolean;

   procedure Reset;

end DMI_Status;
