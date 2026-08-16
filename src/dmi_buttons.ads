--  ETCS DMI
--  Button engine per DMI 5.3.2: up-type, down-type and delay-type buttons
--  and touch sensitive areas, driven by pointer events from the UI.

with Display;

package DMI_Buttons is

   type Button_ID_T is (BTN_TAF_Yes,       -- 8.2.3.3 "Yes" answer
                        BTN_Speed_Toggle,  -- 8.2.2.4 sensitive area A/B
                        BTN_Ack,           -- 5.4.1.4 acknowledgement area
                        BTN_Msg_Up,        -- 8.2.3.4.7 f scroll up (E10)
                        BTN_Msg_Down,      -- 8.2.3.4.7 f scroll down (E11)
                        BTN_Tunnel_Toggle, -- 8.2.3.6.4 sensitive C2/C3/C4
                        BTN_Geo_Toggle,    -- 8.4.4.4 sensitive G12
                        BTN_Zoom_In,       -- 8.3.10.2 [Scale Up] (D9)
                        BTN_Zoom_Out,      -- 8.3.10.3 [Scale Down] (D12)
                        BTN_F1,            -- 8.6.1 window selection
                        BTN_F2,
                        BTN_F3,
                        BTN_F4,
                        BTN_F5,
                        BTN_Window_Close,  -- 5.3.2.7 [Close]
                        BTN_Menu_1,        -- 10.2.1 menu window buttons
                        BTN_Menu_2,
                        BTN_Menu_3,
                        BTN_Menu_4,
                        BTN_Menu_5,
                        BTN_Menu_6,
                        BTN_Menu_7,
                        BTN_Menu_8,
                        BTN_Menu_9,
                        BTN_Menu_10,
                        BTN_Menu_11,
                        BTN_Menu_12);

   subtype Menu_Button_T is Button_ID_T range BTN_Menu_1 .. BTN_Menu_12;
   subtype F_Button_T is Button_ID_T range BTN_F1 .. BTN_F5;

   type Kind_T is (Up_Type, Down_Type, Delay_Type); -- DMI 5.3.2.6

   type Pointer_Event_T is (Down, Up, Move);

   -- Register/refresh a button with its absolute touch sensitive area.
   -- Buttons not set active do not react to the pointer.
   procedure Set_Active (ID       : Button_ID_T;
                         The_Area : Display.Area_T;
                         Kind     : Kind_T);

   procedure Set_Inactive (ID : Button_ID_T);

   procedure Pointer_Event (Event : Pointer_Event_T;
                            X, Y  : Natural);

   -- Advance time dependent behaviour (down-type repeat, delay-type
   -- timing); Dt_Ms is the elapsed time since the last call
   procedure Tick (Dt_Ms : Natural);

   -- Pressed state for rendering (DMI 5.3.2.5; delay-type toggles its
   -- pressed rendering every 0.25 s per 5.3.2.6.6)
   function Is_Pressed (ID : Button_ID_T) return Boolean;

   -- Take the next queued button activation; False when none pending
   function Pop_Activation (ID : out Button_ID_T) return Boolean;

end DMI_Buttons;
