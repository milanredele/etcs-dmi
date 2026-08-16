--  ETCS DMI
--  Single full-screen frame buffer (DMI 5.2.1.2: 640 x 480 cell grid).
--
--  All areas and windows draw into this one buffer through absolute
--  coordinates; Display.Frame_Buffer instances are thin per-area adapters
--  on top of it. One byte per cell holding the Color index.

with Ada.Streams;

package Display.Screen is

   subtype Screen_X_T is Width_T;
   subtype Screen_Y_T is Height_T;

   function Get_Pixel (X : Screen_X_T; Y : Screen_Y_T)
                       return General_Parameters.Color with Inline;

   procedure Set_Pixel (X : Screen_X_T;
                        Y : Screen_Y_T;
                        The_Color : General_Parameters.Color) with Inline;

   procedure Fill (The_Color : General_Parameters.Color);

   procedure Fill_Area (The_Area : Area_T; The_Color : General_Parameters.Color);

   -- Send the whole screen as one MSG_FRAME to the stream
   procedure Write (Stream : not null access Ada.Streams.Root_Stream_Type'Class);

   -- Raw dump of the colour index buffer, row major; used for golden
   -- frame regression tests
   procedure Dump (File_Name : String);

   -- Compare the screen against a previously dumped file; True on match
   function Matches_Dump (File_Name : String) return Boolean;

end Display.Screen;
