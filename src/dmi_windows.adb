--  ETCS DMI
--  Window manager implementation.

pragma Ada_2012;
with Display.Draw;
with Display.Screen;
with DMI_Buttons;
with General_Parameters;
with Symbol;

package body DMI_Windows is

   use Display;

   -- Touch screen: the window covers the D + F columns of the layout
   -- (Table 20: 306 cells wide, title at the top, close button at y 400)
   Origin : constant Position_T := Get_Area (D).Position; -- (334, 15)

   The_Window_Area : constant Area_T := (Origin, 306, 450);

   Title_Height : constant := 24; -- DMI 5.3.1.2.2

   Stack : array (1 .. 8) of Window_ID_T;
   Depth : Natural := 0;

   procedure Open (ID : Window_ID_T) is
   begin
      if Depth < Stack'Last then
         Depth := Depth + 1;
         Stack (Depth) := ID;
      end if;
   end Open;

   procedure Close_Top is
   begin
      if Depth > 0 then
         Depth := Depth - 1;
      end if;
   end Close_Top;

   procedure Close_All is
   begin
      Depth := 0;
   end Close_All;

   function Is_Open return Boolean is (Depth > 0);

   function Top return Window_ID_T is (Stack (Depth));

   function Window_Area return Display.Area_T is (The_Window_Area);

   function Close_Button_Area return Display.Area_T is
     ((Origin + (0, 400), 82, 50));

   function Title (ID : Window_ID_T) return Wide_String is
     (case ID is
         when W_Main      => "Main",
         when W_Override  => "Override",
         when W_Data_View => "Data view",
         when W_Special   => "Special",
         when W_Settings  => "Settings");

   procedure Render is
   begin
      if Depth = 0 then
         return;
      end if;

      -- window background
      Screen.Fill_Area (The_Window_Area, General_Parameters.Background_Color);

      -- DMI 5.3.1.2: title area, black background, grey label
      Screen.Fill_Area ((Origin, The_Window_Area.Width, Title_Height),
                        General_Parameters.BLACK);
      Draw.Draw_String (Pen_X      => Origin.X + 3,
                        Pen_Y      => Origin.Y + Title_Height - 6,
                        The_String => Title (Stack (Depth)),
                        The_Size   => 12,
                        The_Color  => General_Parameters.GREY);

      -- [Close] button (up-type, NA11)
      declare
         Close_Area : constant Area_T := Close_Button_Area;
         Pressed    : constant Boolean :=
           DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_Window_Close);
      begin
         if not Pressed then
            Draw.Draw_Button_Frame (Close_Area);
         end if;
         Draw.Draw_Symbol
           (Symbol.NA_11,
            Close_Area.Position
              + ((Close_Area.Width - Symbol.NA_11.Width) / 2,
                 (Close_Area.Height - Symbol.NA_11.Height) / 2));
      end;
   end Render;

end DMI_Windows;
