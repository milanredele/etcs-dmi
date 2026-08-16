--  ETCS DMI
--  Area F rendering: the five always-enabled up-type window selection
--  buttons (8.6.1.2 - 8.6.1.7, Table 18).

pragma Ada_2012;
with DMI_Buttons;
with Symbol;

package body Display.F_Area is

   procedure Draw_Window_Button (ID     : Sub_ID_T;
                                 Button : DMI_Buttons.F_Button_T) is
      The_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (ID);
      Pressed  : constant Boolean := DMI_Buttons.Is_Pressed (Button);
      Center_X : constant Width_T := The_Area.Position.X + The_Area.Width / 2;

      procedure Label (Line_1 : Wide_String; Line_2 : Wide_String := "") is
      begin
         if Line_2 = "" then
            F_Buffer.Draw_String (Center_X,
                                  The_Area.Position.Y + The_Area.Height / 2 + 6,
                                  Line_1, 12, General_Parameters.GREY,
                                  F_Buffer.Center);
         else
            F_Buffer.Draw_String (Center_X, The_Area.Position.Y + 22,
                                  Line_1, 12, General_Parameters.GREY,
                                  F_Buffer.Center);
            F_Buffer.Draw_String (Center_X, The_Area.Position.Y + 40,
                                  Line_2, 12, General_Parameters.GREY,
                                  F_Buffer.Center);
         end if;
      end Label;

      use all type DMI_Buttons.Button_ID_T;
   begin
      -- DMI 5.3.2.5: the border disappears while the button is pressed
      if not Pressed then
         F_Buffer.Draw_Button_Frame (The_Area);
      end if;
      case Button is
         when BTN_F1 => Label ("Main");
         when BTN_F2 => Label ("Over-", "ride");
         when BTN_F3 => Label ("Data", "view");
         when BTN_F4 => Label ("Spec");
         when BTN_F5 =>
            F_Buffer.Draw_Symbol
              (Symbol.SE_04,
               The_Area.Position
                 + ((The_Area.Width - Symbol.SE_04.Width) / 2,
                    (The_Area.Height - Symbol.SE_04.Height) / 2));
      end case;
   end Draw_Window_Button;

   procedure Draw is
      use all type DMI_Buttons.Button_ID_T;
   begin
      F_Buffer.Fill (General_Parameters.Background_Color);
      Draw_Window_Button (F1, BTN_F1);
      Draw_Window_Button (F2, BTN_F2);
      Draw_Window_Button (F3, BTN_F3);
      Draw_Window_Button (F4, BTN_F4);
      Draw_Window_Button (F5, BTN_F5);
   end Draw;

end Display.F_Area;
