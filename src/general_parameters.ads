with Ada.Streams;

package General_Parameters is
   
   -- DMI 5.2.1.2
   type Display_Resolution_T is 
      record
         Width : Positive range 640 .. Positive'Last;
         Height : Positive range 480 .. Positive'Last;
      end record;
   
   Display_Resolution : constant Display_Resolution_T := (Width => 640,
                                                          Height => 480);
   
   -- DMI 5.2.1.3
   type Color is (WHITE, BLACK, GREY, MEDIUM_GREY, DARK_GREY, DARK_BLUE,
                  SHADOW, YELLOW, ORANGE, RED, PASP_DARK, PASP_LIGHT);
   
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
   Background_Color : constant RGB := RGB_Colors (DARK_BLUE);
   
   -- DMI 5.2.2
   type Display_Luminance_T is range 0 .. 10;
   -- DMI 5.2.2.2
   Display_Luminance : constant Display_Luminance_T := 5;
   
   -- DMI 5.2.3
   type Loudspeaker_Volume_T is range 0 .. 10;
   -- DMI 5.2.3.2
   Loudspeaker_Volume : constant Loudspeaker_Volume_T := 5;
   
   -- DMI 8.2.1.1.3
   type Speed_Dial_Range_T is (Range_140, Range_180, Range_250, Range_400);
   Speed_Dial_Range : constant Speed_Dial_Range_T := Range_180;
   
end General_Parameters;
