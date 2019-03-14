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

with Ada.Streams;

package General_Parameters is
   
   -- DMI 5.2.1.2
   type Display_Resolution_T is 
      record
         Width : Integer range 640 .. 4096;
         Height : Integer range 480 .. 4096;
      end record;
   
   Display_Resolution : constant Display_Resolution_T := (Width => 640,
                                                          Height => 480);
   
   -- DMI 5.2.1.3
   type Color is (WHITE, BLACK, GREY, MEDIUM_GREY, DARK_GREY, DARK_BLUE,
                  SHADOW, YELLOW, ORANGE, RED, PASP_DARK, PASP_LIGHT);
   for Color'Size use 8;
   
   procedure Write_Color
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  Color);
   
   for Color'Write use Write_Color;
   
   type Pixel_T is mod 2**8;
   
   type RGB is
      record
         R, G, B : Pixel_T;
      end record;
   
   procedure Write_RGB 
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      Item   : in  RGB);
   
   for RGB'Write use Write_RGB;
   
   type RGB_Colors_T is array (Color) of RGB;
   
   -- DMI 5.2.1.3.1
   RGB_Colors : constant RGB_Colors_T 
     := (WHITE       => (255, 255, 255),
         BLACK       => (0, 0, 0),
         GREY        => (195, 195, 195),
         MEDIUM_GREY => (150, 150, 150),
         DARK_GREY   => (85, 85, 85),
         DARK_BLUE   => (3, 17, 34),
         SHADOW      => (8, 24, 57),
         YELLOW      => (223, 223, 0),
         ORANGE      => (234, 145, 0),
         RED         => (191, 0, 2),
         PASP_DARK   => (33, 49, 74),
         PASP_LIGHT  => (41, 74, 107));
   
  
   -- DMI 5.2.1.3.3
   Background_Color : constant Color := DARK_BLUE;
   
   -- DMI 5.2.2
   type Display_Luminance_T is range 0 .. 10;
   -- DMI 5.2.2.2
   Display_Luminance : constant Display_Luminance_T := 5;
   
   -- DMI 5.2.3
   type Loudspeaker_Volume_T is range 0 .. 10;
   -- DMI 5.2.3.2
   Loudspeaker_Volume : constant Loudspeaker_Volume_T := 5;
   
   
   

end General_Parameters;
