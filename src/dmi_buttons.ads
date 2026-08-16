--  ETCS DMI
--  Button engine per DMI 5.3.2: up-type, down-type and delay-type buttons
--  and touch sensitive areas, driven by pointer events from the UI.

with Display;

package DMI_Buttons is

   type Button_ID_T is (BTN_TAF_Yes,       -- 8.2.3.3 "Yes" answer
                        BTN_Speed_Toggle); -- 8.2.2.4 sensitive area A/B

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
