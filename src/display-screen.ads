--  ETCS DMI
--  Single full-screen frame buffer (DMI 5.2.1.2: 640 x 480 cell grid).
--
--  All areas and windows draw into this one buffer through absolute
--  coordinates; Display.Frame_Buffer instances are thin per-area adapters
--  on top of it. One byte per cell holding the Color index.

with Ada.Streams;
with System;

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

   -- Raw copy of the colour index buffer to the stream, row major, one
   -- byte per pixel
   procedure Write_Raw (Stream : not null access Ada.Streams.Root_Stream_Type'Class);

   -- The colour index buffer itself: Frame_Size bytes at Frame_Address.
   -- Hosts that map the display directly (WebAssembly page, memory
   -- mapped display driver) read it in place; the regression tools hash
   -- and dump it (Display.Screen.Files).
   Frame_Size : constant Natural :=
     General_Parameters.Display_Resolution.Width *
     General_Parameters.Display_Resolution.Height;

   function Frame_Address return System.Address;

end Display.Screen;
