--  ETCS DMI
--  Copyright (C) 2019  Milan Redele
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.

with DMI_Buttons;
with DMI_Planning;
with Symbol;
with Track_Ahead_Free;

package body Display.D_Area is

   function TAF_Answer_Area return Area_T is
     ((The_Area.Position + Track_Ahead_Free_Area.Position
         + (TAF_Question_Width, 0),
       Track_Ahead_Free_Area.Width - TAF_Question_Width,
       Track_Ahead_Free_Area.Height));

   procedure Draw_Track_Ahead_Free is
      -- DMI 8.2.3.3
      Question_Area : constant Area_T  := (Track_Ahead_Free_Area.Position,
                                           TAF_Question_Width,
                                           Track_Ahead_Free_Area.Height);
      Answer_Area   : constant Area_T  := (Track_Ahead_Free_Area.Position + (TAF_Question_Width, 0),
                                           Track_Ahead_Free_Area.Width - TAF_Question_Width,
                                           Track_Ahead_Free_Area.Height);
      Pressed       : constant Boolean :=
        DMI_Buttons.Is_Pressed (DMI_Buttons.BTN_TAF_Yes);
   begin
      D_Buffer.Fill_Area (Question_Area, General_Parameters.DARK_GREY);
      -- DMI 5.3.2.5: pressed buttons lose their lifted appearance
      D_Buffer.Fill_Area (Answer_Area,
                          (if Pressed then General_Parameters.DARK_GREY
                           else General_Parameters.MEDIUM_GREY));
      -- DMI 8.2.3.3.14
      D_Buffer.Draw_Input_Field_Frame (Track_Ahead_Free_Area);
      D_Buffer.Draw_Symbol (Symbol.DR_02, Question_Area.Position + (42, 2));
      D_Buffer.Draw_String (Pen_X         => Answer_Area.Position.X + Answer_Area.Width / 2,
                            Pen_Y         => Answer_Area.Position.Y + 30,
                            The_String    => "Yes",
                            The_Size      => 12,
                            The_Color     => General_Parameters.BLACK,
                            The_Alignment => D_Buffer.Center);
   end Draw_Track_Ahead_Free;
   
   procedure Draw is
   begin
      D_Buffer.Fill (General_Parameters.Background_Color);
      if DMI_Planning.Displayed then
         DMI_Planning.Render;
      end if;
      -- the TAF question box overlays the planning information
      if Track_Ahead_Free.Show then
         Draw_Track_Ahead_Free;
      end if;
   end Draw;

end Display.D_Area;
