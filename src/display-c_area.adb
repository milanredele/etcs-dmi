with General_Parameters;
with Supplementary_Driving_Info;
with Symbol;

package body Display.C_Area is

   procedure Draw is
   begin
      C_Buffer.Fill (General_Parameters.Background_Color);
      
      Draw_C1;
      Draw_C7;
   end Draw;
   
   procedure Draw_C1 is
      Position       : constant Position_T := The_C1_Area.Position + (13, 9);
      Position_MO_10 : constant Position_T := The_C1_Area.Position + (6, 2);
      
      procedure DS (The_Symbol : Symbol.T; The_Position : Position_T := Position) renames C_Buffer.Draw_Symbol;
      use Supplementary_Driving_Info;
   begin
      if Acknowledgment_Mode.Valid then
         -- DMI 5.1.1.3.2
         -- this should be called every 250ms
         Flashing_Frame_Displayed  := not Flashing_Frame_Displayed;
         C_Buffer.Draw_Yellow_Frame (The_C1_Area, Flashing_Frame_Displayed);
         
         case Acknowledgment_Mode.Mode is
         when M_LS => DS (Symbol.MO_22);
         when M_OS => DS (Symbol.MO_08);
         when M_SR => C_Buffer.Draw_Symbol (Symbol.MO_10, Position_MO_10);
         when M_SH => DS (Symbol.MO_02);
         when M_UN => DS (Symbol.MO_17);
         when M_TR => DS (Symbol.MO_05);
         when M_RV => DS (Symbol.MO_15);
         when M_SN => DS (Symbol.MO_20);
         end case;
      else
         C_Buffer.Draw_Frame (The_C1_Area);
      end if;
      
   end Draw_C1;
   
   procedure Draw_C7 is
      Position : constant Position_T := The_C7_Area.Position + (2, 9);
   begin
      -- DMI 8.2.3.1.5
      if Supplementary_Driving_Info.Override then
         C_Buffer.Draw_Symbol (Symbol.MO_03, Position);
      end if;
   end Draw_C7;

end Display.C_Area;
