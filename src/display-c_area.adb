with General_Parameters;
with Supplementary_Driving_Info;
with Symbol;

package body Display.C_Area is

   procedure Draw is
   begin
      C_Buffer.Fill (General_Parameters.Background_Color);
      
      Draw_C1;
      Draw_C7;
      Draw_C8;
   end Draw;
   
   procedure Draw_C1 is
      Position       : constant Position_T := The_C1_Area.Position + (13, 9);
      Position_MO_10 : constant Position_T := The_C1_Area.Position + (6, 2);
      Position_Level : constant Position_T := The_C1_Area.Position + (3, 14);
      
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
         when M_SR => DS (Symbol.MO_10, Position_MO_10);
         when M_SH => DS (Symbol.MO_02);
         when M_UN => DS (Symbol.MO_17);
         when M_TR => DS (Symbol.MO_05);
         when M_RV => DS (Symbol.MO_15);
         when M_SN => DS (Symbol.MO_20);
         end case;
      else
         C_Buffer.Draw_Frame (The_C1_Area);
         -- DMI 8.2.3.2.6
         if Level_Announcement.Valid then
            if Level_Announcement.Ack_Required then
               -- DMI 8.2.3.2.8
               case Level_Announcement.Level is
                  when L0 =>  DS (Symbol.LE_07, Position_Level);
                  when NTC => DS (Symbol.LE_09, Position_Level);
                  when L1 =>  DS (Symbol.LE_11, Position_Level);
                  when L2 =>  DS (Symbol.LE_13, Position_Level);
                  when L3 =>  DS (Symbol.LE_15, Position_Level);
                  when others => 
                     null;
               end case;
            else
               -- DMI 8.2.3.2.7
               case Level_Announcement.Level is
               when L0 =>  DS (Symbol.LE_06, Position_Level);
               when NTC => DS (Symbol.LE_08, Position_Level);
               when L1 =>  DS (Symbol.LE_10, Position_Level);
               when L2 =>  DS (Symbol.LE_12, Position_Level);
               when L3 =>  DS (Symbol.LE_14, Position_Level);
               when others => 
                  null;
               end case;
            end if;
         end if;
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
   
   procedure Draw_C8 is
      Position : constant Position_T := The_C8_Area.Position + (1, 2);
      procedure DS (The_Symbol : Symbol.T; The_Position : Position_T := Position) renames C_Buffer.Draw_Symbol;
      use Supplementary_Driving_Info;
   begin
      case Level is
         -- DMI 8.2.3.2.2
         when L0 =>  DS (Symbol.LE_01);
         when NTC => DS (Symbol.LE_02);
         when L1 =>  DS (Symbol.LE_03);
         when L2 =>  DS (Symbol.LE_04);
         when L3 =>  DS (Symbol.LE_05);
         when others => 
            -- DMI 8.2.3.2.3
            null;
      end case;
   end Draw_C8;

end Display.C_Area;
