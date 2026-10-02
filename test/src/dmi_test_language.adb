--  ETCS DMI
--  Body of DMI_Test_Language (see dmi_test_language.ads).

with Ada.Streams;
with DMI_Core;
with DMI_Data_Entry;
with DMI_Data_View;
with DMI_Driver_Data;
with DMI_Protocol;
with DMI_Test_Support;
with DMI_Text_Messages;
with DMI_Texts;
with DMI_Train_Data;
with DMI_Windows;
with Display.Draw;
with EVC_Driver;
with EVC_Mock;
with Font.FreeSans_10;
with Font.FreeSans_12;
with General_Parameters;
with Interfaces;
with Test_Support;
use Test_Support;
use DMI_Test_Support;
use type DMI_Test_Support.Win_U8;

package body DMI_Test_Language is

   package SS renames DMI_Protocol;


   ---------------------------------------------------------------------
   -- Languages (audit GEN-2: DMI 5.5, 11.3.6, Table 36 #1, Table 48,
   -- Table 54 S2): the Language window, every text in the selected
   -- language, the selection kept over a reset, MSG_DRIVER_DATA kind 10
   ---------------------------------------------------------------------

   package TX renames DMI_Texts;

   function Lang_Is (L : TX.Language_T) return Boolean is
     (TX."=" (TX.Selected, L));

   --  The wire bytes of kind 10 after the kind: the ISO 639-1 code
   function Lang_Bytes (Code : String) return Byte_Array is
     ((Character'Pos (Code (Code'First)),
       Character'Pos (Code (Code'First + 1))));

   --  SB, level 1, a standing train whose data are all valid
   procedure Lang_Standstill is
   begin
      Reset;
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit);
      Send_Mode_Level (Mode => 1, Level => 4);
      Win_At_Standstill;
      Drain_Outbox;
   end Lang_Standstill;

   --  Table 54 S1 -> S2: Settings, then the Language window; Key is the
   --  key of the language (1 Deutsch, 2 English, 3 Magyar, Figure 119),
   --  accepted on the input field
   procedure Lang_Select (Key_Number : Positive) is
   begin
      Win_Default;
      Press (610, 240);                          -- F5: Settings
      Win_Menu (1);                              -- SE03: Language
      Key (Key_Number);
      Enter_Single;
   end Lang_Select;

   --  Leave the scenarios in English, whatever happened
   procedure Scenario_Lang_Texts_Fit is
      use type TX.Text_ID;

      function Width (S : Wide_String) return Natural is
        (Display.Draw.String_Width (S, 12));

      --  one line, or the last space that leaves the first line inside
      --  Room and a second line that fits as well
      function Fits (S : Wide_String; Room : Natural) return Boolean is
         Cut : Natural := 0;
      begin
         if Width (S) <= Room then
            return True;
         end if;
         for I in S'Range loop
            if S (I) = ' ' and then Width (S (S'First .. I - 1)) <= Room then
               Cut := I;
            end if;
         end loop;
         return Cut > 0 and then Width (S (Cut + 1 .. S'Last)) <= Room;
      end Fits;

      type ID_List is array (Positive range <>) of TX.Text_ID;

      --  Tables 33 to 37: 153 x 50 buttons, 3 cells of margin a side
      Menu_Labels : constant ID_List :=
        (TX.Start, TX.Driver_ID, TX.Train_Data, TX.Level,
         TX.Train_Running_Number, TX.Shunting, TX.Exit_Shunting,
         TX.Non_Leading, TX.Maintain_Shunting, TX.Radio_Data,
         TX.Initiate_SM, TX.Continue_SM, TX.Exit_SM, TX.EOA, TX.Adhesion,
         TX.SR_Speed_Distance, TX.Train_Integrity, TX.BMM_Inhibition,
         TX.Revoke_BMM_Inhibition, TX.System_Version, TX.Set_VBC,
         TX.Remove_VBC, TX.ATO, TX.Contact_Last_RBC, TX.Use_Short_Number,
         TX.Enter_RBC_Data, TX.Radio_Network_Type, TX.GSMR_Network_ID,
         TX.Mission_One_Radio);
      --  10.3.5.19: 102 x 50 keys
      Key_Labels : constant ID_List :=
        (TX.Yes, TX.No, TX.More, TX.Level_0, TX.Level_1, TX.Level_2,
         TX.Non_Slippery_Rail, TX.Slippery_Rail, TX.Stand_By, TX.ATO_On,
         TX.Out_Of_GC);
      Train_Data_Values : constant ID_List :=
        (TX.Yes, TX.No, TX.Out_Of_GC);
      --  8.6.1: the 60 x 50 buttons F1 to F4, each line on its own
      F_Lines : constant ID_List :=
        (TX.F_Main, TX.F_Override_1, TX.F_Override_2, TX.F_Data_View_1,
         TX.F_Data_View_2, TX.F_Special);
      --  10.3.1.10 / 10.3.3.7 / 10.5.1.7: right aligned 10 (label area)
      --  or 5 (echo, data view) cells left of X 204, inside the window
      Labels : constant ID_List :=
        (TX.Driver_ID, TX.Train_Running_Number, TX.Train_Running_Nr,
         TX.RBC_ID, TX.RBC_Phone_Number, TX.SR_Speed, TX.SR_Distance,
         TX.VBC_Code, TX.Train_Category, TX.Train_Length,
         TX.Brake_Percentage, TX.Max_Speed, TX.Axle_Load_Category,
         TX.Airtight, TX.Loading_Gauge, TX.Maximum_Speed,
         TX.Radio_Network_Type, TX.GSMR_Network_ID,
         TX.Operated_System_Version, TX.Validate);

      --  every character has a glyph in the font it is drawn with, so
      --  that no text shows a replacement box (the Hungarian o and u
      --  with double acute are Latin Extended-A)
      function Has_Glyphs (S : Wide_String; Map : Font.Glyph_Map)
        return Boolean is
        (for all C of S =>
           C in Map'Range and then Font.Defined (Map (C)));

      --  15.1.1.3 / 8.2.3.4: a system status message breaks at its
      --  spaces only when every word fits a line of the text message
      --  area, measured in the bold font they are drawn with (first
      --  group, 8.2.3.4.7 c)
      function Words_Fit (S : Wide_String) return Boolean is
         First : Positive := S'First;
      begin
         for I in S'Range loop
            if S (I) = ' ' or else I = S'Last then
               if Display.Draw.String_Width
                    (S (First .. (if S (I) = ' ' then I - 1 else I)), 12,
                     Bold => True)
                    > DMI_Text_Messages.Line_Width
               then
                  return False;
               end if;
               First := I + 1;
            end if;
         end loop;
         return True;
      end Words_Fit;
   begin
      for L in TX.Language_T loop
         declare
            Name : constant String := TX.Language_T'Image (L);
         begin
            for T in TX.Text_ID loop
               --  the window titles: 30 characters in the window
               --  definitions (DMI_Data_Entry.Max_Label), 3 cells of
               --  indent in the 306 cells of the D/F/G column
               if T <= TX.Language then
                  Check (TX.Text (T, L)'Length
                           <= DMI_Data_Entry.Max_Label
                         and then Width (TX.Text (T, L)) <= 300,
                         "lang: " & Name & " title "
                         & TX.Text_ID'Image (T) & " fits");
               end if;
            end loop;
            for T of Menu_Labels loop
               Check (Fits (TX.Text (T, L), 147),
                      "lang: " & Name & " button " & TX.Text_ID'Image (T)
                      & " fits its 153 cells");
            end loop;
            for T of Key_Labels loop
               Check (Fits (TX.Text (T, L), 96)
                      and then TX.Text (T, L)'Length
                                 <= DMI_Data_Entry.Max_Choice_Label,
                      "lang: " & Name & " key " & TX.Text_ID'Image (T)
                      & " fits its 102 cells");
            end loop;
            --  Table 23: the data part of an input field with a label
            --  is 102 cells, the value indented by 10 (10.3.1.11): the
            --  choices of the train data keyboards that are texts
            for T of Train_Data_Values loop
               Check (Width (TX.Text (T, L)) <= 92,
                      "lang: " & Name & " value " & TX.Text_ID'Image (T)
                      & " fits the data part of its input field");
            end loop;
            for T of F_Lines loop
               Check (Width (TX.Text (T, L)) <= 56,
                      "lang: " & Name & " " & TX.Text_ID'Image (T)
                      & " fits its 60 cells");
            end loop;
            for T of Labels loop
               Check (Width (TX.Text (T, L)) <= 194
                      and then TX.Text (T, L)'Length
                                 <= DMI_Data_Entry.Max_Label,
                      "lang: " & Name & " label " & TX.Text_ID'Image (T)
                      & " fits left of X 204");
            end loop;
            for L2 in TX.Language_T loop
               Check (Fits (TX.Name (L2), 96),
                      "lang: the key of " & TX.Language_T'Image (L2));
            end loop;
            --  10.3.5.7: the question on the 334 cells of A/B/C/E
            Check (Width (TX.Text (TX.Entry_Complete_Before, L)
                          & TX.Text (TX.SR_Speed_Distance, L)
                          & TX.Text (TX.Entry_Complete_After, L)) <= 330,
                   "lang: " & Name & " the longest question fits");
            --  11.3.3.7 a: the 'TRN' button of the Driver ID window,
            --  82 cells, label size 10 (5.1.2.2.3 g); 'Yes' on the 82
            --  cells of the TAF answer (8.2.3.3) and of 10.3.5.10
            Check (Display.Draw.String_Width (TX.Text (TX.TRN_Button, L),
                                              10) <= 78
                   and then Width (TX.Text (TX.Yes, L)) <= 78,
                   "lang: " & Name & " 'TRN' and 'Yes' fit 82 cells");
            --  Table 45 item 15: 'VBC #n set code' with two digits
            Check (Width (TX.Text (TX.VBC_Code_Before, L) & "63"
                          & TX.Text (TX.VBC_Code_After, L)) <= 194,
                   "lang: " & Name & " 'VBC #63 set code' fits left of X 204");
            for T in TX.Balise_Read_Error .. TX.Text_ID'Last loop
               Check (Words_Fit (TX.Text (T, L)),
                      "lang: " & Name & " message " & TX.Text_ID'Image (T)
                      & " breaks at its spaces");
            end loop;
            for T in TX.Text_ID loop
               Check (Has_Glyphs (TX.Text (T, L), Font.FreeSans_12.Glyphs)
                      and then (T /= TX.TRN_Button
                                or else Has_Glyphs (TX.Text (T, L),
                                                    Font.FreeSans_10.Glyphs)),
                      "lang: " & Name & " " & TX.Text_ID'Image (T)
                      & " has a glyph for every character");
            end loop;
            Check (Has_Glyphs (TX.Name (L), Font.FreeSans_12.Glyphs),
                   "lang: the name of " & Name & " has its glyphs");
         end;
      end loop;
      Check (Lang_Is (TX.English) and then TX."=" (TX.Default_Language,
                                                   TX.English),
             "5.5: English is the default language");
   end Scenario_Lang_Texts_Fit;

   -- 11.3.6, Table 36 #1, Table 48, Table 54 S2, MSG_DRIVER_DATA kind 10
   procedure Scenario_Lang_Window is
   begin
      Lang_English;
      Lang_Standstill;
      Press (610, 240);                          -- F5: Settings
      Check (Win_Top_Is (DMI_Windows.W_Settings) and then Win_Enabled (1),
             "Table 36 #1: Language in SB at standstill");
      VBC_Onboard (National => 0, Train => Win_Running);
      Check (not Win_Enabled (1), "Table 36 #1: not in SB while running");
      Send_Mode_Level (Mode => 2, Level => 4);  -- FS
      VBC_Onboard (National => 0, Train => Win_Running);
      Check (Win_Enabled (1), "Table 36 #1: in FS, also while running");
      Send_Mode_Level (Mode => 1, Level => 4);
      VBC_Onboard (National => 0);

      -- Table 54 S1 -> S2: the language window, the selected language
      -- proposed (11.7.1.4)
      Win_Menu (1);
      Check (Win_Top_Is (DMI_Windows.W_Language)
             and then Win_Value = "English",
             "Table 54 S2: the Language window proposes English");
      Check (DMI_Windows.Close_Enabled, "11.7.7.2: [Close] enabled");
      Step;
      Check_Frame ("lang_window");                -- Figure 119
      Key (1);                                    -- Deutsch
      Check (Win_Value = "Deutsch" and then Lang_Is (TX.English),
             "the key enters the language, nothing selected yet");
      Step;
      Check_Frame ("lang_window_deutsch");
      Expect_No_Driver_Data (10, "nothing sent before the entry");
      Enter_Single;
      Check (Lang_Is (TX.German), "5.5: German is selected");
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S2 -> S1, the Settings window");
      Expect_Driver_Data (10, Lang_Bytes ("de"),
                          "kind 10 with the code of the language");
      Step;
      Check_Frame ("lang_settings_de");

      -- the window in German, German proposed; revalidation sends again
      Win_Menu (1);
      Check (Win_Top_Is (DMI_Windows.W_Language)
             and then Win_Value = "Deutsch",
             "11.7.1.4: the selected language is proposed");
      Step;
      Check_Frame ("lang_window_de");
      Enter_Single;
      Check (Lang_Is (TX.German), "revalidated: German stays");
      Expect_Driver_Data (10, Lang_Bytes ("de"),
                          "Table 54 S2: the revalidation is an entry too");

      -- [Close]: nothing changes, nothing is sent
      Win_Menu (1);
      Key (2);
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Settings) and then Lang_Is (TX.German),
             "[Close] of the Language window changes nothing");
      Expect_No_Driver_Data (10, "[Close] sends nothing");

      -- Table 48: the window gives way when 'Language' loses its
      -- conditions (11.7.1.7)
      Win_Menu (1);
      Key (2);
      VBC_Onboard (National => 0, Train => Win_Running);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings) and then Lang_Is (TX.German),
             "Table 48: Language -> the Settings window when running in SB");
      VBC_Onboard (National => 0);

      -- 11.7.1.9: a driver's acknowledgement stops the entry
      Win_Menu (1);
      Key (2);
      Send_Text (92, "Ack me", Ack_Required => True);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings) and then Lang_Is (TX.German),
             "11.7.1.9: the acknowledgement stops the Language window");
      Send_Text_Remove (92);
      for I in 1 .. 30 loop
         Step;
      end loop;
      Drain_Sounds;
      Drain_Outbox;

      -- back to English: kind 10 "en", the windows in English at once
      Win_Menu (1);
      Key (2);
      Enter_Single;
      Check (Lang_Is (TX.English), "English again");
      Expect_Driver_Data (10, Lang_Bytes ("en"), "kind 10 'en'");
      Step;
      Check_Frame ("lang_settings_en_again");
      Lang_English;
   end Scenario_Lang_Window;

   -- 5.5.1.3: the texts of the windows, the buttons, the keys, the input
   -- fields, the echo texts and the data view in German
   procedure Scenario_Lang_German_Windows is
   begin
      Lang_English;
      Lang_Standstill;
      Lang_Select (1);
      Check (Lang_Is (TX.German), "lang: German selected");
      Win_Default;
      Step;
      Check_Frame ("lang_default_de");            -- F1 .. F4

      -- the menu windows, Tables 33 to 35 and 37
      Press (610, 40);                            -- F1: Main
      Step;
      Check_Frame ("lang_main_de");
      Win_Default;
      Press (610, 190);                           -- F4: Special
      Step;
      Check_Frame ("lang_special_de");
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit,
                   Train => Win_Standing or 16#10#);  -- BMM inhibited
      Step;
      Check_Frame ("lang_special_bmm_de");
      VBC_Onboard (National => VBC_Room_Bit or VBC_Stored_Bit);
      Win_Default;
      DMI_Windows.Open (DMI_Windows.W_Main);
      DMI_Windows.Open (DMI_Windows.W_Radio_Data);
      Step;
      Check_Frame ("lang_radio_data_de");
      Win_Default;

      -- the dedicated keyboards: Table 43 on two lines, Table 43a
      Press (610, 190);                           -- F4: Special
      Win_Menu (1);                               -- Adhesion
      Check (Win_Top_Is (DMI_Windows.W_Adhesion)
             and then Win_Value = "Nicht rutschig",
             "lang: the proposed adhesion in German");
      Step;
      Check_Frame ("lang_adhesion_de");
      Key (2);
      Enter_Single;
      Expect_Actions (9, 1, "lang: the adhesion goes to the EVC as before");
      Win_Default;

      -- the train data windows: labels, echo texts, question, [More],
      -- 'Ja' / 'Nein', 'Außerhalb GC' and the validation window
      Press (610, 40);                            -- F1: Main
      Win_Menu (3);                               -- Train data
      Check (Win_Top_Is (DMI_Windows.W_Train_Data),
             "lang: the train data window");
      Step;
      Check_Frame ("lang_train_data_1_de");
      Enter_Train_Data (Length => 450, Brake => 120, Speed => 160);
      Press_Next;
      Enter_Field (2);                            -- select the airtight
      Key (8);                                    -- airtight: Ja
      Step;
      Check_Frame ("lang_train_data_2_de");
      Enter_Field (2);
      Press (167, 440);                           -- entry complete? Ja
      Check (Win_Top_Is (DMI_Windows.W_Train_Data_Validation)
             and then Win_Value = "Ja",
             "lang: the validation window proposes 'Ja'");
      Step;
      Check_Frame ("lang_train_data_validation_de");
      Press (487, 40);                            -- accept 'Ja'
      Check (DMI_Driver_Data.Airtight = DMI_Data_Entry.Yes_Choice
             and then DMI_Train_Data.Airtight_Value = 1,
             "lang: 'Ja' is the choice 'Yes', M_AIRTIGHT fitted");
      Drain_Outbox;
      Win_Default;

      -- the data view (Table 45) and the System version window (Table 46)
      Send_System_Version (2, 1);
      Send_VBC_List ((71951, 321456));            -- 'VBC #n Setzcode'
      Press (610, 140);                           -- F3: Data view
      Check (DMI_Data_View.Title = "Datenansicht (1/2)",
             "lang: the data view title in German");
      Step;
      Check_Frame ("lang_data_view_de");
      Press_Next;
      Check_Frame ("lang_data_view_2_de");
      Win_Default;
      Press (610, 240);                           -- F5: Settings
      Win_Menu (4);                               -- System version
      Step;
      Check_Frame ("lang_system_version_de");
      Win_Close;
      Win_Menu (5);                               -- Set VBC: total grid
      Win_Type ("4711");
      Step;
      Check_Frame ("lang_set_vbc_de");
      Win_Default;

      -- 8.2.3.3: the Track Ahead Free question
      Send_Mode_Level (Mode => 2, Level => 5, TAF => True);
      Step;
      Check_Frame ("lang_taf_de");
      Send_Mode_Level (Mode => 1, Level => 4);
      Lang_English;
      Step;
      Check_Frame ("lang_default_en_again");
   end Scenario_Lang_German_Windows;

   -- 15.1.1.4.2 with 5.5.1.3: the system status messages follow the
   -- selected language, also the ones displayed; a plain text message
   -- of the trackside does not (5.5.1.3)
   procedure Scenario_Lang_Messages is
   begin
      Lang_English;
      SS_Reset (Mode => 2);
      Send_Text (7, "Streckentext bleibt", First_Group => False,
                 HH => 9, MM => 30);
      Send_System_Status (SS.SS_Trackside_Malfunction, 0);
      Send_System_Status (SS.SS_Route_Unsuitable_Traction, 0);
      Step;
      Drain_Sounds;
      Check_Frame ("lang_messages_en");
      Send_Status (HH => 9, MM => 44, SS => 0);
      Lang_Select (1);
      Win_Default;
      Step;
      Drain_Sounds;
      Check (SS_Active (SS.SS_Trackside_Malfunction)
             and then SS_Active (SS.SS_Route_Unsuitable_Traction),
             "lang: the messages stay displayed");
      Check_Frame ("lang_messages_de");           -- 09:41 kept
      Expect_No_Sound ("lang: a new text is no new message (no Sinfo)");

      -- a message that starts now comes in German, and one to be
      -- acknowledged is offered in German
      Send_Mode_Level (Mode => 14, Level => 4);   -- NL
      Send_System_Status (SS.SS_NL_No_Longer_Permitted, 0);
      Step;
      Drain_Sounds;
      Check_Frame ("lang_nl_ack_de");
      Pointer_Down (150, 400);
      Pointer_Up (150, 400);
      Step;
      Drain_Sounds;
      Check (not SS_Active (SS.SS_NL_No_Longer_Permitted),
             "lang: the German message is acknowledged as before");
      Lang_English;
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Lang_Messages;

   -- 5.5 with 5.2.2.2 / 5.2.3.2: the selection is a setting of the DMI
   -- unit and survives a reset and a loss of the EVC link; Table 54 S2
   -- from the Start Up (S1-1): the Driver ID window below comes back in
   -- the new language
   procedure Scenario_Lang_Reset is
   begin
      Lang_English;
      Lang_Standstill;
      Lang_Select (1);
      Win_Default;
      Reset;
      Check (Lang_Is (TX.German), "lang: the selection survives a reset");
      Send_Mode_Level (Mode => 1, Level => 4);
      Win_At_Standstill;
      VBC_Onboard (National => 0);
      Press (610, 240);
      Win_Menu (1);
      Check (Win_Value = "Deutsch",
             "11.7.1.4: after the reset the stored language is proposed");
      Step;
      Check_Frame ("lang_after_reset");
      Win_Default;

      -- the link lost and back: still German
      External_EVC;
      General_Parameters.EVC_Link_Timeout_Ms := 1000;
      Send_Mode_Level (Mode => 1, Level => 4);
      for I in 1 .. 21 loop
         Step;
      end loop;
      Check (DMI_Core.EVC_Link_Lost and then Lang_Is (TX.German),
             "lang: the link loss keeps the selection");
      Send_Mode_Level (Mode => 1, Level => 4);
      External_EVC (False);
      General_Parameters.EVC_Link_Timeout_Ms := 0;

      -- Table 49 S1 -> S1-1 (Settings) -> Table 54 S2: English
      Reset;
      Win_At_Standstill;
      Win_Onboard (Data => 0, SOM => 0);
      Send_Mode_Level (Mode => 1, Level => 0);
      Win_Onboard (Data => 0, SOM => 2);
      Check (Win_Top_Is (DMI_Windows.W_Driver_ID)
             and then DMI_Windows.In_Start_Up,
             "lang: Table 49 S1, the Driver ID window");
      Step;
      Check_Frame ("lang_start_up_driver_id_de");  -- 'Zugnr.'
      Press (599, 440);                           -- settings, S1-1
      Win_Menu (1);
      Key (2);
      Enter_Single;
      Check (Lang_Is (TX.English)
             and then Win_Top_Is (DMI_Windows.W_Settings),
             "lang: English selected from S1-1, back to Settings");
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Driver_ID),
             "lang: [Close] -> S1, the Driver ID window");
      Step;
      Check_Frame ("lang_start_up_driver_id_en");
      Lang_English;
      Reset;
   end Scenario_Lang_Reset;

   -- 11.7.7, Table 54: the steps of the Settings window dialogue
   -- sequence, S2 with the others (S6 and S7 are Scenario_VBC_Settings)
   procedure Scenario_Lang_Settings_Sequence is
      procedure Back_To_S1 (What : String) is
      begin
         Check (DMI_Windows.Close_Enabled,
                "11.7.7.2: [Close] enabled in " & What);
         Win_Close;
         Check (Win_Top_Is (DMI_Windows.W_Settings),
                "Table 54: " & What & " -> S1 by [Close]");
      end Back_To_S1;
   begin
      Lang_English;
      Lang_Standstill;
      Send_ATO (Selector => 1);
      Win_Default;
      Press (610, 240);                           -- S0 -> S1
      Check (Win_Top_Is (DMI_Windows.W_Settings), "Table 54 S0 -> S1");
      Check (DMI_Windows.Close_Enabled, "11.7.7.2: [Close] enabled in S1");
      Win_Menu (1);
      Check (Win_Top_Is (DMI_Windows.W_Language), "Table 54 S1 -> S2");
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S2 revalidated -> S1");
      Win_Menu (1);
      Back_To_S1 ("S2");
      Win_Menu (2);
      Check (Win_Top_Is (DMI_Windows.W_Volume), "Table 54 S1 -> S3");
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S3 revalidated -> S1");
      Win_Menu (2);
      Back_To_S1 ("S3");
      Win_Menu (3);
      Check (Win_Top_Is (DMI_Windows.W_Brightness), "Table 54 S1 -> S4");
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S4 revalidated -> S1");
      Win_Menu (3);
      Back_To_S1 ("S4");
      Win_Menu (4);
      Check (Win_Top_Is (DMI_Windows.W_System_Version),
             "Table 54 S1 -> S5");
      Back_To_S1 ("S5");
      Win_Menu (5);
      Check (Win_Top_Is (DMI_Windows.W_Set_VBC), "Table 54 S1 -> S6-1");
      Back_To_S1 ("S6-1");
      Win_Menu (6);
      Check (Win_Top_Is (DMI_Windows.W_Remove_VBC), "Table 54 S1 -> S7-1");
      Back_To_S1 ("S7-1");
      Win_Menu (7);
      Check (Win_Top_Is (DMI_Windows.W_ATO_Selector)
             and then Win_Value = "Stand-by",
             "Table 54 S1 -> S8, the stored position proposed");
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "Table 54 S8 revalidated -> S1");
      Win_Menu (7);
      Back_To_S1 ("S8");
      Lang_English;
   end Scenario_Lang_Settings_Sequence;

   -- The simulator holds the language the DMI reports (kind 10)
   procedure Scenario_Lang_Simulator is
      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

      procedure Pump_To_EVC is
         use Ada.Streams;
         use DMI_Protocol;
         Buffer : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
         Last   : Stream_Element_Offset;
         Offset : Stream_Element_Offset := Buffer'First;
      begin
         DMI_Core.Take_Outbox (Buffer, Last);
         while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last loop
            declare
               The_Type : constant Msg_Type_T :=
                 Msg_Type_T (Get_U8 (Buffer, Offset));
               Length   : constant Stream_Element_Offset :=
                 Stream_Element_Offset (Get_U32 (Buffer, Offset));
               Next     : constant Stream_Element_Offset := Offset + Length;
            begin
               exit when Next - 1 > Last;
               if The_Type = MSG_DRIVER_DATA then
                  EVC_Mock.Handle_Driver_Data (Buffer (Offset .. Next - 1));
               end if;
               Offset := Next;
            end;
         end loop;
      end Pump_To_EVC;

      procedure Touch (X, Y : Natural) is
      begin
         Pointer_Down (X, Y);
         Pointer_Up (X, Y);
         DMI_Core.Tick (50);
         Pump_To_EVC;
         EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
         Pump_To_EVC;
         Drain_Sounds;
      end Touch;
   begin
      Lang_English;
      Reset;
      EVC_Mock.Reset;
      External_EVC;
      for I in 1 .. 3 loop
         EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
         Pump_To_EVC;
      end loop;
      Check (EVC_Mock.Language_Code = "en", "sim: English at the start");
      Touch (385, 240); Touch (487, 90);       -- Driver ID 1
      Touch (Key_X (1), Key_Y (1)); Touch (487, 90);  -- level 1
      Touch (370, 440);                        -- [Close] the Main window
      Touch (610, 240);                        -- F5: Settings
      Touch (Win_Slot_X (1), Win_Slot_Y (1));  -- Language
      Touch (Key_X (1), Key_Y (1)); Touch (487, 90);  -- Deutsch
      Check (EVC_Mock.Language_Code = "de",
             "sim: the on-board stores the language the driver selected");
      -- malformed kind 10: ignored
      EVC_Mock.Handle_Driver_Data ((10, 16#45#, 16#4E#));
      EVC_Mock.Handle_Driver_Data ((10, 16#65#));
      Check (EVC_Mock.Language_Code = "de", "sim: malformed kind 10 ignored");
      Touch (Win_Slot_X (1), Win_Slot_Y (1));
      Touch (Key_X (2), Key_Y (2)); Touch (487, 90);  -- English
      Check (EVC_Mock.Language_Code = "en", "sim: English again");
      External_EVC (False);
      Lang_English;
      Reset;
   end Scenario_Lang_Simulator;


   ---------------------------------------------------------------------
   -- Hungarian, the third language (DMI 5.5.1.1, 11.3.6.4): the wording
   -- of the MAV ETCS operating instructions, Latin Extended-A glyphs
   ---------------------------------------------------------------------

   -- 11.3.6.4 / Figure 119: three keys, Magyar the third (the order of
   -- the names); Table 54 S2 with kind 10 "hu"
   procedure Scenario_Hu_Language_Window is
   begin
      Lang_English;
      Lang_Standstill;
      Press (610, 240);                          -- F5: Settings
      Win_Menu (1);                              -- Language
      Check (Win_Top_Is (DMI_Windows.W_Language)
             and then Win_Value = "English",
             "hu: the Language window proposes English");
      Key (3);
      Check (Win_Value = "Magyar" and then Lang_Is (TX.English),
             "hu: the third key enters 'Magyar', nothing selected yet");
      Step;
      Check_Frame ("hu_lang_window_magyar");
      Expect_No_Driver_Data (10, "hu: nothing sent before the entry");
      Enter_Single;
      Check (Lang_Is (TX.Hungarian)
             and then Win_Top_Is (DMI_Windows.W_Settings),
             "hu: Hungarian selected, back to the Settings window");
      Check (TX.Code (TX.Hungarian) = "hu"
             and then TX.Name (TX.Hungarian) = "Magyar",
             "hu: ISO 639-1 'hu', named 'Magyar'");
      Expect_Driver_Data (10, Lang_Bytes ("hu"), "hu: kind 10 'hu'");
      Step;
      Check_Frame ("hu_settings");               -- Hangero, Fenyero
      Win_Menu (1);
      Check (Win_Top_Is (DMI_Windows.W_Language)
             and then Win_Value = "Magyar",
             "hu: 11.7.1.4, Magyar proposed");
      Step;
      Check_Frame ("hu_lang_window");            -- title 'Nyelv'
      Win_Close;

      -- the simulator stores the code as it comes
      EVC_Mock.Handle_Driver_Data ((10, Character'Pos ('h'),
                                    Character'Pos ('u')));
      Check (EVC_Mock.Language_Code = "hu",
             "hu: sim, the on-board stores 'hu'");
      EVC_Mock.Handle_Driver_Data ((10, Character'Pos ('e'),
                                    Character'Pos ('n')));
      Lang_English;
   end Scenario_Hu_Language_Window;

   -- 5.5.1.3: the default window, the menus, the keyboards, the data
   -- entry windows with their echo texts, the data view and the System
   -- version window in Hungarian
   procedure Scenario_Hu_Windows is
   begin
      Lang_English;
      Lang_Standstill;
      Lang_Select (3);
      Check (Lang_Is (TX.Hungarian), "hu: Hungarian selected");
      Win_Default;
      Step;
      Check_Frame ("hu_default");                -- F1 .. F4

      -- the menu windows, Tables 33 to 35
      Press (610, 40);                           -- F1: Fomenu
      Step;
      Check_Frame ("hu_main");
      Win_Menu (5);                              -- Szint
      Check (Win_Top_Is (DMI_Windows.W_Level), "hu: the Level window");
      Step;
      Check_Frame ("hu_level");                  -- 'ETCS 1 szint'
      Win_Default;
      Press (610, 90);                           -- F2: Meghaladas
      Step;
      Check_Frame ("hu_override");               -- 'Menetengedely vege'
      Win_Default;
      Press (610, 190);                          -- F4: Kulonleges
      Step;
      Check_Frame ("hu_special");
      Win_Menu (1);                              -- Tapadas
      Check (Win_Top_Is (DMI_Windows.W_Adhesion)
             and then Win_Value = "Nem cs["FA"]sz["F3"]s s["ED"]n",
             "hu: the proposed adhesion in Hungarian");
      Win_Default;

      -- the train data windows: labels, echo texts, the question,
      -- 'Igen' / 'Nem' and the validation window
      Press (610, 40);                           -- F1
      Win_Menu (3);                              -- Vonatadatok
      Check (Win_Top_Is (DMI_Windows.W_Train_Data),
             "hu: the train data window");
      Step;
      Check_Frame ("hu_train_data_1");
      Enter_Train_Data (Length => 450, Brake => 120, Speed => 160);
      Press_Next;
      Enter_Field (2);                           -- select the airtight
      Key (8);                                   -- airtight: Igen
      Step;
      Check_Frame ("hu_train_data_2");
      Enter_Field (2);
      Press (167, 440);                          -- entry complete? Igen
      Check (Win_Top_Is (DMI_Windows.W_Train_Data_Validation)
             and then Win_Value = "Igen",
             "hu: the validation window proposes 'Igen'");
      Step;
      Check_Frame ("hu_train_data_validation");
      Press (487, 40);                           -- accept 'Igen'
      Check (DMI_Driver_Data.Airtight = DMI_Data_Entry.Yes_Choice,
             "hu: 'Igen' is the choice 'Yes'");
      Drain_Outbox;
      Win_Default;

      -- the data view (Table 45) and the System version window
      -- (Table 46): 'Mukodo rendszerverzio' holds u and o with
      -- double acute
      Send_System_Version (2, 1);
      Send_VBC_List ((71951, 321456));
      Press (610, 140);                          -- F3: Adatnezet
      Check (DMI_Data_View.Title = "Adatn["E9"]zet (1/2)",
             "hu: the data view title in Hungarian");
      Step;
      Check_Frame ("hu_data_view");
      Press_Next;
      Check_Frame ("hu_data_view_2");
      Win_Default;
      Press (610, 240);                          -- F5: Beallitasok
      Win_Menu (4);                              -- Rendszerverzio
      Check (TX.Text (TX.Operated_System_Version)
               = "M["0171"]k["F6"]d["0151"] rendszerverzi["F3"]",
             "hu: the text with u and o with double acute");
      Step;
      Check_Frame ("hu_system_version");
      Win_Default;

      -- 8.2.3.3: the Track Ahead Free question, 'Igen'
      Send_Mode_Level (Mode => 2, Level => 5, TAF => True);
      Step;
      Check_Frame ("hu_taf");
      Send_Mode_Level (Mode => 1, Level => 4);
      Lang_English;
      Step;
      Check_Frame ("lang_default_en_again");     -- English unchanged
   end Scenario_Hu_Windows;

   -- 15.1.1.4.2: two catalogue messages and the acknowledgeable 'NL no
   -- longer permitted' in Hungarian, the trackside text as it came
   procedure Scenario_Hu_Messages is
   begin
      Lang_English;
      SS_Reset (Mode => 2);
      Lang_Select (3);
      Win_Default;
      Send_Text (7, "P["E1"]lyasz["F6"]veg marad", First_Group => False,
                 HH => 9, MM => 30);
      Send_System_Status (SS.SS_Trackside_Malfunction, 0);
      Send_System_Status (SS.SS_Route_Unsuitable_Traction, 0);
      Step;
      Drain_Sounds;
      Check (SS_Active (SS.SS_Trackside_Malfunction)
             and then SS_Active (SS.SS_Route_Unsuitable_Traction),
             "hu: the two messages displayed");
      Check_Frame ("hu_messages");
      Send_Mode_Level (Mode => 14, Level => 4);  -- NL
      Send_System_Status (SS.SS_NL_No_Longer_Permitted, 0);
      Step;
      Drain_Sounds;
      Check_Frame ("hu_nl_ack");                 -- 'NL mar nem megengedett'
      Pointer_Down (150, 400);
      Pointer_Up (150, 400);
      Step;
      Drain_Sounds;
      Check (not SS_Active (SS.SS_NL_No_Longer_Permitted),
             "hu: the Hungarian message is acknowledged as before");
      Lang_English;
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Drain_Sounds;
      Drain_Outbox;
   end Scenario_Hu_Messages;

   -- 5.5 with 5.2.2.2: the selection survives a reset; the Start Up
   -- Driver ID window comes in Hungarian ('Vonatszam' on the TRN button)
   procedure Scenario_Hu_Reset is
   begin
      Lang_English;
      Lang_Standstill;
      Lang_Select (3);
      Win_Default;
      Reset;
      Check (Lang_Is (TX.Hungarian), "hu: the selection survives a reset");
      Send_Mode_Level (Mode => 1, Level => 4);
      Win_At_Standstill;
      VBC_Onboard (National => 0);
      Press (610, 240);
      Win_Menu (1);
      Check (Win_Value = "Magyar",
             "hu: after the reset Magyar is proposed");
      Win_Default;
      Reset;
      Win_At_Standstill;
      Win_Onboard (Data => 0, SOM => 0);
      Send_Mode_Level (Mode => 1, Level => 0);
      Win_Onboard (Data => 0, SOM => 2);
      Check (Win_Top_Is (DMI_Windows.W_Driver_ID)
             and then DMI_Windows.In_Start_Up
             and then Lang_Is (TX.Hungarian),
             "hu: Table 49 S1, the Driver ID window, still Hungarian");
      Step;
      Check_Frame ("hu_start_up_driver_id");
      Press (599, 440);                          -- settings, S1-1
      Win_Menu (1);
      Key (2);                                   -- English
      Enter_Single;
      Check (Lang_Is (TX.English), "hu: English again from S1-1");
      Lang_English;
      Reset;
   end Scenario_Hu_Reset;

   -- The same Hungarian texts from the WebAssembly build: the frame
   -- test/wasm/smoke.js renders after the same touches (the wire cycle
   -- of Scenario_Mission) must be this golden, so that the brackets
   -- notation of the Latin Extended-A letters reaches the wasm fonts
   procedure Scenario_Hu_Wasm_Start_Up is
      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;

      procedure Pump_To_EVC is
         use Ada.Streams;
         use DMI_Protocol;
         Buffer : Stream_Element_Array (1 .. DMI_Core.Outbox_Size);
         Last   : Stream_Element_Offset;
         Offset : Stream_Element_Offset := Buffer'First;
      begin
         DMI_Core.Take_Outbox (Buffer, Last);
         while Offset + Stream_Element_Offset (Header_Length) - 1 <= Last loop
            declare
               The_Type : constant Msg_Type_T :=
                 Msg_Type_T (Get_U8 (Buffer, Offset));
               Length   : constant Stream_Element_Offset :=
                 Stream_Element_Offset (Get_U32 (Buffer, Offset));
               Next     : constant Stream_Element_Offset := Offset + Length;
            begin
               exit when Next - 1 > Last;
               if The_Type = MSG_DRIVER_ACTION
                 and then Length = Driver_Action_Length
               then
                  declare
                     Action : constant Interfaces.Unsigned_8 :=
                       Get_U8 (Buffer, Offset);
                     Arg    : constant Interfaces.Unsigned_16 :=
                       Get_U16 (Buffer, Offset);
                  begin
                     EVC_Mock.Handle_Driver_Action
                       (Natural (Action), Natural (Arg));
                  end;
               elsif The_Type = MSG_DRIVER_DATA then
                  EVC_Mock.Handle_Driver_Data (Buffer (Offset .. Next - 1));
               end if;
               Offset := Next;
            end;
         end loop;
      end Pump_To_EVC;

      -- test/wasm/smoke.js press()
      procedure Touch (X, Y : Natural) is
      begin
         EVC_Driver.Auto_Drive;
         EVC_Mock.Step (0.05, Emit'Unrestricted_Access);
         Pointer_Down (X, Y);
         Pointer_Up (X, Y);
         DMI_Core.Tick (50);
         Pump_To_EVC;
         Drain_Sounds;
      end Touch;
   begin
      Lang_English;
      Reset;
      EVC_Mock.Reset;
      External_EVC;
      for I in 1 .. 5 loop
         EVC_Driver.Auto_Drive;
         EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
      end loop;
      Touch (599, 440);                          -- Table 49 S1-1: Settings
      Touch (Win_Slot_X (1), Win_Slot_Y (1));    -- Language
      Touch (Key_X (3), Key_Y (3));              -- Magyar
      Touch (487, 90);                           -- accepted
      Touch (370, 440);                          -- [Close]: S1
      Check (Lang_Is (TX.Hungarian)
             and then Win_Top_Is (DMI_Windows.W_Driver_ID)
             and then EVC_Mock.Language_Code = "hu",
             "hu: selected from the Start Up, the EVC told 'hu'");
      DMI_Core.Render;
      Check_Frame ("hu_wasm_driver_id");
      Touch (599, 440);
      Touch (Win_Slot_X (1), Win_Slot_Y (1));
      Touch (Key_X (2), Key_Y (2));              -- English
      Touch (487, 90);
      Touch (370, 440);
      Check (Lang_Is (TX.English) and then EVC_Mock.Language_Code = "en",
             "hu: English again");
      External_EVC (False);
      Lang_English;
      Reset;
   end Scenario_Hu_Wasm_Start_Up;

   --  SUP-8, 8.2.2.5.3: the TTI arrives in tenths of a second and the
   --  white square takes n x 5 cells for
   --    TdispTTI * (10 - n) / 10 <= TTI < TdispTTI * (10 - (n - 1)) / 10.
   --  With TdispTTI = 14 s every step is 1.4 s long: its lower bound
   --  14 * (10 - n) tenths and its upper bound 14 * (11 - n) - 1 tenths
   --  give the same square, the tenth after it the next one.

end DMI_Test_Language;
