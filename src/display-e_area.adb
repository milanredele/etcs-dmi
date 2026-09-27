--  ETCS DMI
--  Area E rendering: safe radio connection in E1 (8.4.1) and the text
--  message list in E5-E9 with its scroll buttons in E10/E11 (8.2.3.4).

pragma Ada_2012;
with DMI_Ack;
with DMI_Buttons;
with DMI_Flash;
with DMI_Status;
with DMI_Text_Messages;
with Symbol;

package body Display.E_Area is

   E5_E9 : constant Area_T :=
     (Get_Sub_Area_With_Relative_Position (E5).Position,
      DMI_Text_Messages.Area_Width, 100);

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

      Time_X   : constant Width_T := E5_E9.Position.X + Time_Indent; -- 5.1.3.2
      -- text begins after the hh:mm stamp plus a 10 cell separation
      -- (8.2.3.4.6 b); continuation lines align with the text
      -- (8.2.3.4.6 c). DMI_Text_Messages wraps the lines to the width
      -- that is left; should a line be wider all the same, it is
      -- clipped to E5-E9 (8.2.3.4.2) and never reaches E10/E11.
      Text_X   : constant Width_T := E5_E9.Position.X + Text_Indent;

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
               -- 8.2.3.4.6 b, 5.1.2.2.3 f: the local time in 10 cells.
               -- The ':' is a glyph of FreeSans_10 since the fonts carry
               -- the whole printable ISO 8859-1 (GEN-7); it used to be
               -- drawn as two cells by hand.
               E_Buffer.Draw_String
                 (Time_X, Base_Y,
                  Two (Line.Hour) & ":" & Two (Line.Minute),
                  10, General_Parameters.WHITE);
            end if;
            if Line.Length > 0 then
               -- 8.2.3.4.7 c: the first group in bold characters
               E_Buffer.Draw_String_Clipped
                 (Text_X, Base_Y, Line.Text (1 .. Line.Length),
                  Text_Size, General_Parameters.WHITE, E5_E9,
                  Bold => Line.Bold);
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
         E_Buffer.Draw_Yellow_Frame (E5_E9, DMI_Flash.Frame_Visible);
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
         -- 5.3.2.7.7: NA15/NA16 replace NA13/NA14 while disabled
         Sym : constant Symbol.T :=
           (if Enabled then Enabled_Symbol else Disabled_Symbol);
      begin
         -- 5.3.2.5.2/.3: an enabled button is lifted unless pressed;
         -- 5.3.2.5.5 a: a disabled button is shown as an enabled one with
         -- its specific symbol, so it keeps the border
         if not (Enabled and then Pressed) then
            E_Buffer.Draw_Button_Frame (The_Area);
         end if;
         E_Buffer.Draw_Symbol
           (Sym,
            The_Area.Position
              + ((The_Area.Width - Sym.Width) / 2,
                 (The_Area.Height - Sym.Height) / 2));
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
