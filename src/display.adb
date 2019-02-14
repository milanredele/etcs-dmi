pragma Ada_2012;
with Ada.Streams.Stream_IO;
package body Display is

   Relative_Layout : constant Layout_T (Sub_ID_T)
     := (A1 => ((0,0), 54, 54),
         A2 => ((0, 54), 54, 30),
         A3 => ((0, 84), 54, 191),
         A4 => ((0, 84+191), 54, 25),
         B0 => ((15, 25), 250, 250),
         B1 => ((115, 125), 50, 50),
         B2 => ((3, 13), 274, 274),
         B3 => ((122-36, 256), 36, 36),
         B4 => ((122, 256), 36, 36),
         B5 => ((122+36, 256), 36, 36),
         B6 => ((8, 256), 36, 36),
         B7 => ((236, 256), 36, 36),
         C1 => ((54+3*37, 0), 58, 50),
         C2 => ((54, 0), 37, 50),
         C3 => ((54+37, 0), 37, 50),
         C4 => ((54+2*37, 0), 37, 50),
         C5 => ((54+3*37+58, 0), 37, 50),
         C6 => ((54+4*37+58, 0), 37, 50),
         C7 => ((54+5*37+58, 0), 37, 50),
         C8 => ((0, 0), 54, 25),
         C9 => ((0, 25), 54, 25),
         D1 => ((0, 15), 40, 270),
         D2 => ((40, 15), 25, 270),
         D3 => ((40+25, 15), 25, 270),
         D4 => ((40+2*25, 15), 25, 270),
         D5 => ((40+3*25, 15), 18, 270),
         D6 => ((40+3*25+18, 15), 14, 270),
         D7 => ((40+3*25+18+14, 15), 93, 270),
         D8 => ((40+3*25+18+14+93, 15), 6, 270),
         D9 => ((0, 285), 40, 15),
         D10 => ((40, 285), 166, 15),
         D11 => ((40+166, 285), 40, 15),
         D12 => ((0, 0), 40, 15),
         D13 => ((40, 0), 166, 15),
         D14 => ((40+166, 0), 40, 15),
         E1 => ((0, 0), 54, 25),
         E2 => ((0, 25), 54, 25),
         E3 => ((0, 50), 54, 25),
         E4 => ((0, 75), 54, 25),
         E5 => ((54, 0), 234, 20),
         E6 => ((54, 20), 234, 20),
         E7 => ((54, 40), 234, 20),
         E8 => ((54, 60), 234, 20),
         E9 => ((54, 80), 234, 20),
         E10 => ((288, 0), 46, 50),
         E11 => ((288, 50), 46, 50),
         F1 => ((0, 0), 60, 50),
         F2 => ((0, 50), 60, 50),
         F3 => ((0, 100), 60, 50),
         F4 => ((0, 150), 60, 50),
         F5 => ((0, 200), 60, 50),
         F6 => ((0, 250), 60, 50),
         F7 => ((0, 300), 60, 50),
         F8 => ((0, 350), 60, 50),
         F9 => ((0, 400), 60, 50),
         G1 => ((0, 0), 49, 50),
         G2 => ((49, 0), 49, 50),
         G3 => ((98, 0), 49, 50),
         G4 => ((3*49, 0), 49, 50),
         G5 => ((4*49, 0), 50, 50),
         G6 => ((0, 50), 49, 50),
         G7 => ((49, 50), 49, 50),
         G8 => ((98, 50), 49, 50),
         G9 => ((3*49, 50), 49, 50),
         G10 => ((4*49, 50), 50, 50),
         G11 => ((0, 100), 63, 50),
         G12 => ((63, 100), 120, 50),
         G13 => ((183, 100), 63, 50));

   --------------
   -- Get_Area --
   --------------

   function Get_Area (ID: ID_T) return Area_T is

      function Get_Sub_Area (Sub_ID  : Sub_ID_T) return Area_T is
         function Area_With_Absolute_Position (Main, Sub : Area_T) return Area_T is
           (Main.Position + Sub.Position, Sub.Width, Sub.Height);

         Main : constant Area_T := Main_Layout (Sub_To_Main_Map (ID));

      begin
         return Area_With_Absolute_Position (Main, Relative_Layout (Sub_ID));
      end;

      Result : Area_T;
   begin
      case ID is
      when Main_ID_T =>
         Result := Main_Layout (ID);
      when others =>
         Result := Get_Sub_Area (ID);
      end case;
      return Result;
   end Get_Area;

   package body Frame_Buffer is
      function Get_Pixel (X : Area_Width_T;
                          Y : Area_Height_T) return General_Parameters.Color is
        (Buffer (X + Y * Area.Width));

      procedure Set_Pixel (X : Area_Width_T;
                           Y : Area_Height_T;
                           The_Color : General_Parameters.Color) is
      begin
         Buffer (X + Y * Area.Width) := The_Color;
      end Set_Pixel;

      procedure Fill (The_Color : General_Parameters.Color) is
      begin
         for I in Buffer'Range loop
            Buffer (I) := The_Color;
         end loop;
      end Fill;

      procedure Dump (File_Name : String) is
         Output_File : Ada.Streams.Stream_IO.File_Type;
         Output_Stream : Ada.Streams.Stream_IO.Stream_Access;
      begin
         Ada.Streams.Stream_IO.Create (File => Output_File,
                                     Mode => Ada.Streams.Stream_IO.Out_File,
                                     Name => File_Name);
         Output_Stream := Ada.Streams.Stream_IO.Stream (Output_File);

         Buffer_T'Write (Output_Stream, Buffer);

         Ada.Streams.Stream_IO.Close (Output_File);
      end Dump;
   end Frame_Buffer;

end Display;
