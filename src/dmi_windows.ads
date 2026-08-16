--  ETCS DMI
--  Sub-level window manager per DMI 5.3.1: windows stack over the default
--  window; only the newest window responds to driver input (5.3.1.1.5).
--  Touch screen technology: sub-level windows occupy the D/F/G area and
--  follow the menu window layout of Table 20.

with Display;

package DMI_Windows is

   type Window_ID_T is (W_Main,       -- 11.2.1
                        W_Override,   -- 11.2.2
                        W_Data_View,  -- 11.5.1
                        W_Special,    -- 11.2.3
                        W_Settings);  -- 11.2.4

   procedure Open (ID : Window_ID_T);

   procedure Close_Top;

   procedure Close_All;

   function Is_Open return Boolean;

   function Top return Window_ID_T
     with Pre => Is_Open;

   -- Absolute layout of the current window (Table 20)
   function Window_Area return Display.Area_T;
   function Close_Button_Area return Display.Area_T;

   -- Draw the top window (no-op when no window is open)
   procedure Render;

end DMI_Windows;
