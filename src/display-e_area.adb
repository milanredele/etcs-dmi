--  ETCS DMI
--  Area E rendering: safe radio connection in E1 (8.4.1) and the text
--  message list in E5-E9 with its scroll buttons in E10/E11 (8.2.3.4).

pragma Ada_2012;
with DMI_Ack;
with DMI_Buttons;
with DMI_Status;
with DMI_Text_Messages;
with Symbol;

package body Display.E_Area is

   E5_E9 : constant Area_T :=
     (Get_Sub_Area_With_Relative_Position (E5).Position, 234, 100);

   procedure Draw_Radio is
      -- DMI 8.4.1: E1 shows ST03 / ST04 / nothing
      Position : constant Position_T :=
        Get_Sub_Area_With_Relative_Position (E1).Position + (1, 2);
   begin
      case DMI_Status.Radio is
         when DMI_Status.Connection_Up =>
            E_Buffer.Draw_Symbol (Symbol.ST_03, Position);
         when DMI_Status.Connection_Lost =>
            E_Buffer.Draw_Symbol (Symbol.ST_04, Position);
         when DMI_Status.No_Connection =>
            null;
      end case;
   end Draw_Radio;

   procedure Draw_Messages is
      use DMI_Text_Messages;

      Time_X   : constant Width_T := E5_E9.Position.X + 3; -- 5.1.3.2
      -- text begins after the hh:mm stamp plus a 10 cell separation
      -- (8.2.3.4.6 b); continuation lines align with the text
      Text_X   : constant Width_T := Time_X + 40;

      Line  : Line_T;
      Valid : Boolean;

      function Two (N : Natural) return Wide_String is
         Img : constant Wide_String := Natural'Wide_Image (N mod 100);
      begin
         return (if N < 10 then "0" & Img (2 .. Img'Last)
                 else Img (2 .. Img'Last));
      end Two;
   begin
      for I in 1 .. Visible_Lines loop
         Get_Visible_Line (I, Line, Valid);
         exit when not Valid;
         declare
            Base_Y : constant Height_T := E5_E9.Position.Y + (I - 1) * 20 + 16;
         begin
            if Line.First_Line then
               -- FreeSans_10 carries digits only: the ':' is drawn as
               -- two cells (font regeneration with ttf2ada pending)
               E_Buffer.Draw_String
                 (Time_X, Base_Y, Two (Line.Hour),
                  10, General_Parameters.WHITE);
               E_Buffer.Set_Pixel (Time_X + 13, Base_Y - 6,
                                   General_Parameters.WHITE);
               E_Buffer.Set_Pixel (Time_X + 13, Base_Y - 2,
                                   General_Parameters.WHITE);
               E_Buffer.Draw_String
                 (Time_X + 16, Base_Y, Two (Line.Minute),
                  10, General_Parameters.WHITE);
            end if;
            if Line.Length > 0 then
               E_Buffer.Draw_String
                 (Text_X, Base_Y, Line.Text (1 .. Line.Length),
                  12, General_Parameters.WHITE);
               if Line.Bold then
                  -- bold style approximated by a 1 cell double strike
                  E_Buffer.Draw_String
                    (Text_X + 1, Base_Y, Line.Text (1 .. Line.Length),
                     12, General_Parameters.WHITE);
               end if;
            end if;
         end;
      end loop;

      -- 8.2.3.4.8 b / 5.4.1.5: flashing frame around the whole list area
      -- while a text message acknowledgement is offered
      if DMI_Ack.Current_Valid
        and then DMI_Ack.Current_Kind in
          DMI_Ack.Fixed_Text | DMI_Ack.Plain_Text
          | DMI_Ack.System_Status | DMI_Ack.NTC_Text
      then
         E_Buffer.Draw_Yellow_Frame (E5_E9, General_Parameters.Flash_On);
      end if;
   end Draw_Messages;

   procedure Draw_Scroll_Buttons is
      use DMI_Text_Messages;
      E10_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (E10);
      E11_Area : constant Area_T := Get_Sub_Area_With_Relative_Position (E11);

      procedure Draw_Button (The_Area : Area_T;
                             Enabled  : Boolean;
                             Pressed  : Boolean;
                             Enabled_Symbol  : Symbol.T;
                             Disabled_Symbol : Symbol.T) is
      begin
         if Enabled then
            if not Pressed then
               E_Buffer.Draw_Button_Frame (The_Area);
            end if;
            E_Buffer.Draw_Symbol
              (Enabled_Symbol,
               The_Area.Position
                 + ((The_Area.Width - Enabled_Symbol.Width) / 2,
                    (The_Area.Height - Enabled_Symbol.Height) / 2));
         else
            -- 5.3.2.7.5/.7: disabled scroll buttons show NA15/NA16
            E_Buffer.Draw_Symbol
              (Disabled_Symbol,
               The_Area.Position
                 + ((The_Area.Width - Disabled_Symbol.Width) / 2,
                    (The_Area.Height - Disabled_Symbol.Height) / 2));
         end if;
      end Draw_Button;

      Ack_Shown : constant Boolean := Ack_Pending;
   begin
      Draw_Button (E10_Area,
                   Enabled => Can_Scroll_Up and not Ack_Shown,
                   Pressed => DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_Msg_Up),
                   Enabled_Symbol  => Symbol.NA_13,
                   Disabled_Symbol => Symbol.NA_15);
      Draw_Button (E11_Area,
                   Enabled => Can_Scroll_Down and not Ack_Shown,
                   Pressed => DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_Msg_Down),
                   Enabled_Symbol  => Symbol.NA_14,
                   Disabled_Symbol => Symbol.NA_16);
   end Draw_Scroll_Buttons;

   procedure Draw is
   begin
      E_Buffer.Fill (General_Parameters.Background_Color);
      Draw_Radio;
      Draw_Messages;
      Draw_Scroll_Buttons;
   end Draw;

end Display.E_Area;
