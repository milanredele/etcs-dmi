--  ETCS DMI
--  Fixed texts, one table per language.
--
--  The characters above 16#7F# are written in the brackets notation of
--  GNAT ("["E4"]" is a with diaeresis), so that the sources stay ASCII;
--  all of them are ISO 8859-1, which the fonts carry.

pragma Ada_2012;

package body DMI_Texts is

   type Text_Access is access constant Wide_String;
   type Table_T is array (Text_ID) of Text_Access;

   Current : Language_T := Default_Language;

   ---------------------------------------------------------------------
   -- English
   ---------------------------------------------------------------------

   En_Main_Window : aliased constant Wide_String := "Main";
   En_Override_Window : aliased constant Wide_String := "Override";
   En_Data_View : aliased constant Wide_String := "Data view";
   En_Special_Window : aliased constant Wide_String := "Special";
   En_Settings_Window : aliased constant Wide_String := "Settings";
   En_Driver_ID : aliased constant Wide_String := "Driver ID";
   En_Level : aliased constant Wide_String := "Level";
   En_Train_Running_Number : aliased constant Wide_String :=
     "Train running number";
   En_Train_Data : aliased constant Wide_String := "Train data";
   En_Validate_Train_Data : aliased constant Wide_String :=
     "Validate train data";
   En_SR_Speed_Distance : aliased constant Wide_String :=
     "SR speed / distance";
   En_Adhesion : aliased constant Wide_String := "Adhesion";
   En_Volume : aliased constant Wide_String := "Volume";
   En_Brightness : aliased constant Wide_String := "Brightness";
   En_ATO_Selector : aliased constant Wide_String := "ATO selector";
   En_Radio_Data : aliased constant Wide_String := "Radio data";
   En_GSMR_Network_ID : aliased constant Wide_String := "GSM-R network ID";
   En_RBC_Data : aliased constant Wide_String := "RBC data";
   En_Radio_Network_Type : aliased constant Wide_String :=
     "Radio network type";
   En_Mission_One_Radio : aliased constant Wide_String :=
     "Mission with one radio system";
   En_Set_VBC : aliased constant Wide_String := "Set VBC";
   En_Validate_Set_VBC : aliased constant Wide_String := "Validate set VBC";
   En_Remove_VBC : aliased constant Wide_String := "Remove VBC";
   En_Validate_Remove_VBC : aliased constant Wide_String :=
     "Validate remove VBC";
   En_System_Version : aliased constant Wide_String := "System version";
   En_Language : aliased constant Wide_String := "Language";
   En_Start : aliased constant Wide_String := "Start";
   En_Shunting : aliased constant Wide_String := "Shunting";
   En_Exit_Shunting : aliased constant Wide_String := "Exit Shunting";
   En_Non_Leading : aliased constant Wide_String := "Non-Leading";
   En_Maintain_Shunting : aliased constant Wide_String := "Maintain Shunting";
   En_Initiate_SM : aliased constant Wide_String := "Initiate SM";
   En_Continue_SM : aliased constant Wide_String := "Continue in SM";
   En_Exit_SM : aliased constant Wide_String := "Exit SM";
   En_EOA : aliased constant Wide_String := "EOA";
   En_Train_Integrity : aliased constant Wide_String := "Train integrity";
   En_BMM_Inhibition : aliased constant Wide_String :=
     "BMM reaction inhibition";
   En_Revoke_BMM_Inhibition : aliased constant Wide_String :=
     "Revoke BMM reaction inhibition";
   En_ATO : aliased constant Wide_String := "ATO";
   En_Contact_Last_RBC : aliased constant Wide_String := "Contact last RBC";
   En_Use_Short_Number : aliased constant Wide_String := "Use short number";
   En_Enter_RBC_Data : aliased constant Wide_String := "Enter RBC data";
   En_TRN_Button : aliased constant Wide_String := "TRN";
   En_F_Main : aliased constant Wide_String := "Main";
   En_F_Override_1 : aliased constant Wide_String := "Over-";
   En_F_Override_2 : aliased constant Wide_String := "ride";
   En_F_Data_View_1 : aliased constant Wide_String := "Data";
   En_F_Data_View_2 : aliased constant Wide_String := "view";
   En_F_Special : aliased constant Wide_String := "Spec";
   En_Train_Running_Nr : aliased constant Wide_String := "Train running nr";
   En_RBC_ID : aliased constant Wide_String := "RBC ID";
   En_RBC_Phone_Number : aliased constant Wide_String := "RBC phone number";
   En_SR_Speed : aliased constant Wide_String := "SR speed";
   En_SR_Distance : aliased constant Wide_String := "SR distance";
   En_VBC_Code : aliased constant Wide_String := "VBC code";
   En_Validate : aliased constant Wide_String := "Validate";
   En_Train_Category : aliased constant Wide_String := "Train category";
   En_Train_Length : aliased constant Wide_String := "Length (m)";
   En_Brake_Percentage : aliased constant Wide_String := "Brake percentage";
   En_Max_Speed : aliased constant Wide_String := "Max speed (km/h)";
   En_Axle_Load_Category : aliased constant Wide_String :=
     "Axle load category";
   En_Airtight : aliased constant Wide_String := "Airtight";
   En_Loading_Gauge : aliased constant Wide_String := "Loading gauge";
   En_Maximum_Speed : aliased constant Wide_String := "Maximum speed (km/h)";
   En_VBC_Code_Before : aliased constant Wide_String := "VBC #";
   En_VBC_Code_After : aliased constant Wide_String := " set code";
   En_Operated_System_Version : aliased constant Wide_String :=
     "Operated system version";
   En_Yes : aliased constant Wide_String := "Yes";
   En_No : aliased constant Wide_String := "No";
   En_More : aliased constant Wide_String := "More";
   En_Level_0 : aliased constant Wide_String := "Level 0";
   En_Level_1 : aliased constant Wide_String := "Level 1";
   En_Level_2 : aliased constant Wide_String := "Level 2";
   En_Non_Slippery_Rail : aliased constant Wide_String := "Non slippery rail";
   En_Slippery_Rail : aliased constant Wide_String := "Slippery rail";
   En_Stand_By : aliased constant Wide_String := "Stand-by";
   En_ATO_On : aliased constant Wide_String := "On";
   En_Out_Of_GC : aliased constant Wide_String := "Out of GC";
   En_Entry_Complete_Before : aliased constant Wide_String := "";
   En_Entry_Complete_After : aliased constant Wide_String :=
     " entry complete?";
   En_Balise_Read_Error : aliased constant Wide_String := "Balise read error";
   En_Trackside_Malfunction : aliased constant Wide_String :=
     "Trackside malfunction";
   En_Communication_Error : aliased constant Wide_String :=
     "Communication error";
   En_Entering_FS : aliased constant Wide_String := "Entering FS";
   En_Entering_OS : aliased constant Wide_String := "Entering OS";
   En_Entering_SM : aliased constant Wide_String := "Entering SM";
   En_Runaway_Movement : aliased constant Wide_String := "Runaway movement";
   En_SM_Refused : aliased constant Wide_String := "SM refused";
   En_SM_Request_Failed : aliased constant Wide_String := "SM request failed";
   En_SH_Refused : aliased constant Wide_String := "SH refused";
   En_SH_Request_Failed : aliased constant Wide_String := "SH request failed";
   En_Trackside_Not_Compatible : aliased constant Wide_String :=
     "Trackside not compatible";
   En_Train_Data_Changed : aliased constant Wide_String :=
     "Train data changed";
   En_Safe_Consist_Length : aliased constant Wide_String :=
     "Safe consist length no longer available";
   En_Train_Rejected : aliased constant Wide_String := "Train is rejected";
   En_Unauthorized_Passing : aliased constant Wide_String :=
     "Unauthorized passing of EOA / LOA";
   En_No_MA_Level_Transition : aliased constant Wide_String :=
     "No MA received at level transition";
   En_SR_Distance_Exceeded : aliased constant Wide_String :=
     "SR distance exceeded";
   En_SH_Stop_Order : aliased constant Wide_String := "SH stop order";
   En_SR_Stop_Order : aliased constant Wide_String := "SR stop order";
   En_Emergency_Stop : aliased constant Wide_String := "Emergency stop";
   En_RV_Distance_Exceeded : aliased constant Wide_String :=
     "RV distance exceeded";
   En_PT_Distance_Exceeded : aliased constant Wide_String :=
     "PT distance exceeded";
   En_No_Track_Description : aliased constant Wide_String :=
     "No track description";
   En_Route_Loading_Gauge : aliased constant Wide_String :=
     "Route unsuitable - loading gauge";
   En_Route_Traction_System : aliased constant Wide_String :=
     "Route unsuitable - traction system";
   En_Route_Axle_Load : aliased constant Wide_String :=
     "Route unsuitable - axle load category";
   En_FRMCS_Registration_Failed : aliased constant Wide_String :=
     "FRMCS network registration failed";
   En_GSMR_Registration_Failed : aliased constant Wide_String :=
     "GSM-R network registration failed";
   En_NL_No_Longer_Permitted : aliased constant Wide_String :=
     "NL no longer permitted";
   En_Odometer_Impaired : aliased constant Wide_String := "Odometer impaired";
   En_ATO_Needs_Data : aliased constant Wide_String := "ATO needs data";

   English_Texts : aliased constant Table_T :=
     (Main_Window => En_Main_Window'Access,
      Override_Window => En_Override_Window'Access,
      Data_View => En_Data_View'Access,
      Special_Window => En_Special_Window'Access,
      Settings_Window => En_Settings_Window'Access,
      Driver_ID => En_Driver_ID'Access,
      Level => En_Level'Access,
      Train_Running_Number => En_Train_Running_Number'Access,
      Train_Data => En_Train_Data'Access,
      Validate_Train_Data => En_Validate_Train_Data'Access,
      SR_Speed_Distance => En_SR_Speed_Distance'Access,
      Adhesion => En_Adhesion'Access,
      Volume => En_Volume'Access,
      Brightness => En_Brightness'Access,
      ATO_Selector => En_ATO_Selector'Access,
      Radio_Data => En_Radio_Data'Access,
      GSMR_Network_ID => En_GSMR_Network_ID'Access,
      RBC_Data => En_RBC_Data'Access,
      Radio_Network_Type => En_Radio_Network_Type'Access,
      Mission_One_Radio => En_Mission_One_Radio'Access,
      Set_VBC => En_Set_VBC'Access,
      Validate_Set_VBC => En_Validate_Set_VBC'Access,
      Remove_VBC => En_Remove_VBC'Access,
      Validate_Remove_VBC => En_Validate_Remove_VBC'Access,
      System_Version => En_System_Version'Access,
      Language => En_Language'Access,
      Start => En_Start'Access,
      Shunting => En_Shunting'Access,
      Exit_Shunting => En_Exit_Shunting'Access,
      Non_Leading => En_Non_Leading'Access,
      Maintain_Shunting => En_Maintain_Shunting'Access,
      Initiate_SM => En_Initiate_SM'Access,
      Continue_SM => En_Continue_SM'Access,
      Exit_SM => En_Exit_SM'Access,
      EOA => En_EOA'Access,
      Train_Integrity => En_Train_Integrity'Access,
      BMM_Inhibition => En_BMM_Inhibition'Access,
      Revoke_BMM_Inhibition => En_Revoke_BMM_Inhibition'Access,
      ATO => En_ATO'Access,
      Contact_Last_RBC => En_Contact_Last_RBC'Access,
      Use_Short_Number => En_Use_Short_Number'Access,
      Enter_RBC_Data => En_Enter_RBC_Data'Access,
      TRN_Button => En_TRN_Button'Access,
      F_Main => En_F_Main'Access,
      F_Override_1 => En_F_Override_1'Access,
      F_Override_2 => En_F_Override_2'Access,
      F_Data_View_1 => En_F_Data_View_1'Access,
      F_Data_View_2 => En_F_Data_View_2'Access,
      F_Special => En_F_Special'Access,
      Train_Running_Nr => En_Train_Running_Nr'Access,
      RBC_ID => En_RBC_ID'Access,
      RBC_Phone_Number => En_RBC_Phone_Number'Access,
      SR_Speed => En_SR_Speed'Access,
      SR_Distance => En_SR_Distance'Access,
      VBC_Code => En_VBC_Code'Access,
      Validate => En_Validate'Access,
      Train_Category => En_Train_Category'Access,
      Train_Length => En_Train_Length'Access,
      Brake_Percentage => En_Brake_Percentage'Access,
      Max_Speed => En_Max_Speed'Access,
      Axle_Load_Category => En_Axle_Load_Category'Access,
      Airtight => En_Airtight'Access,
      Loading_Gauge => En_Loading_Gauge'Access,
      Maximum_Speed => En_Maximum_Speed'Access,
      VBC_Code_Before => En_VBC_Code_Before'Access,
      VBC_Code_After => En_VBC_Code_After'Access,
      Operated_System_Version => En_Operated_System_Version'Access,
      Yes => En_Yes'Access,
      No => En_No'Access,
      More => En_More'Access,
      Level_0 => En_Level_0'Access,
      Level_1 => En_Level_1'Access,
      Level_2 => En_Level_2'Access,
      Non_Slippery_Rail => En_Non_Slippery_Rail'Access,
      Slippery_Rail => En_Slippery_Rail'Access,
      Stand_By => En_Stand_By'Access,
      ATO_On => En_ATO_On'Access,
      Out_Of_GC => En_Out_Of_GC'Access,
      Entry_Complete_Before => En_Entry_Complete_Before'Access,
      Entry_Complete_After => En_Entry_Complete_After'Access,
      Balise_Read_Error => En_Balise_Read_Error'Access,
      Trackside_Malfunction => En_Trackside_Malfunction'Access,
      Communication_Error => En_Communication_Error'Access,
      Entering_FS => En_Entering_FS'Access,
      Entering_OS => En_Entering_OS'Access,
      Entering_SM => En_Entering_SM'Access,
      Runaway_Movement => En_Runaway_Movement'Access,
      SM_Refused => En_SM_Refused'Access,
      SM_Request_Failed => En_SM_Request_Failed'Access,
      SH_Refused => En_SH_Refused'Access,
      SH_Request_Failed => En_SH_Request_Failed'Access,
      Trackside_Not_Compatible => En_Trackside_Not_Compatible'Access,
      Train_Data_Changed => En_Train_Data_Changed'Access,
      Safe_Consist_Length => En_Safe_Consist_Length'Access,
      Train_Rejected => En_Train_Rejected'Access,
      Unauthorized_Passing => En_Unauthorized_Passing'Access,
      No_MA_Level_Transition => En_No_MA_Level_Transition'Access,
      SR_Distance_Exceeded => En_SR_Distance_Exceeded'Access,
      SH_Stop_Order => En_SH_Stop_Order'Access,
      SR_Stop_Order => En_SR_Stop_Order'Access,
      Emergency_Stop => En_Emergency_Stop'Access,
      RV_Distance_Exceeded => En_RV_Distance_Exceeded'Access,
      PT_Distance_Exceeded => En_PT_Distance_Exceeded'Access,
      No_Track_Description => En_No_Track_Description'Access,
      Route_Loading_Gauge => En_Route_Loading_Gauge'Access,
      Route_Traction_System => En_Route_Traction_System'Access,
      Route_Axle_Load => En_Route_Axle_Load'Access,
      FRMCS_Registration_Failed => En_FRMCS_Registration_Failed'Access,
      GSMR_Registration_Failed => En_GSMR_Registration_Failed'Access,
      NL_No_Longer_Permitted => En_NL_No_Longer_Permitted'Access,
      Odometer_Impaired => En_Odometer_Impaired'Access,
      ATO_Needs_Data => En_ATO_Needs_Data'Access);

   ---------------------------------------------------------------------
   -- German
   ---------------------------------------------------------------------

   De_Main_Window : aliased constant Wide_String := "Hauptmen["FC"]";
   De_Override_Window : aliased constant Wide_String := "["DC"]bersteuern";
   De_Data_View : aliased constant Wide_String := "Datenansicht";
   De_Special_Window : aliased constant Wide_String := "Spezial";
   De_Settings_Window : aliased constant Wide_String := "Einstellungen";
   De_Driver_ID : aliased constant Wide_String := "Tf-Nummer";
   De_Level : aliased constant Wide_String := "Level";
   De_Train_Running_Number : aliased constant Wide_String := "Zugnummer";
   De_Train_Data : aliased constant Wide_String := "Zugdaten";
   De_Validate_Train_Data : aliased constant Wide_String :=
     "Zugdaten best["E4"]tigen";
   De_SR_Speed_Distance : aliased constant Wide_String :=
     "SR-Geschwindigkeit / Weg";
   De_Adhesion : aliased constant Wide_String := "Kraftschluss";
   De_Volume : aliased constant Wide_String := "Lautst["E4"]rke";
   De_Brightness : aliased constant Wide_String := "Helligkeit";
   De_ATO_Selector : aliased constant Wide_String := "ATO-Wahlschalter";
   De_Radio_Data : aliased constant Wide_String := "Funkdaten";
   De_GSMR_Network_ID : aliased constant Wide_String := "GSM-R-Netz-ID";
   De_RBC_Data : aliased constant Wide_String := "RBC-Daten";
   De_Radio_Network_Type : aliased constant Wide_String := "Funknetztyp";
   De_Mission_One_Radio : aliased constant Wide_String :=
     "Fahrt mit einem Funksystem";
   De_Set_VBC : aliased constant Wide_String := "VBC setzen";
   De_Validate_Set_VBC : aliased constant Wide_String :=
     "VBC setzen best["E4"]tigen";
   De_Remove_VBC : aliased constant Wide_String := "VBC entfernen";
   De_Validate_Remove_VBC : aliased constant Wide_String :=
     "VBC entfernen best["E4"]tigen";
   De_System_Version : aliased constant Wide_String := "Systemversion";
   De_Language : aliased constant Wide_String := "Sprache";
   De_Start : aliased constant Wide_String := "Start";
   De_Shunting : aliased constant Wide_String := "Rangieren";
   De_Exit_Shunting : aliased constant Wide_String := "Rangieren beenden";
   De_Non_Leading : aliased constant Wide_String := "Nicht f["FC"]hrend";
   De_Maintain_Shunting : aliased constant Wide_String :=
     "Rangieren beibehalten";
   De_Initiate_SM : aliased constant Wide_String := "SM einleiten";
   De_Continue_SM : aliased constant Wide_String := "Weiter in SM";
   De_Exit_SM : aliased constant Wide_String := "SM beenden";
   De_EOA : aliased constant Wide_String := "EOA";
   De_Train_Integrity : aliased constant Wide_String :=
     "Zugvollst["E4"]ndigkeit";
   De_BMM_Inhibition : aliased constant Wide_String :=
     "BMM-Reaktion unterdr["FC"]cken";
   De_Revoke_BMM_Inhibition : aliased constant Wide_String :=
     "BMM-Unterdr["FC"]ckung aufheben";
   De_ATO : aliased constant Wide_String := "ATO";
   De_Contact_Last_RBC : aliased constant Wide_String := "Letztes RBC anrufen";
   De_Use_Short_Number : aliased constant Wide_String := "Kurzwahl verwenden";
   De_Enter_RBC_Data : aliased constant Wide_String := "RBC-Daten eingeben";
   De_TRN_Button : aliased constant Wide_String := "Zugnr.";
   De_F_Main : aliased constant Wide_String := "Haupt";
   De_F_Override_1 : aliased constant Wide_String := "["DC"]ber-";
   De_F_Override_2 : aliased constant Wide_String := "steuern";
   De_F_Data_View_1 : aliased constant Wide_String := "Daten-";
   De_F_Data_View_2 : aliased constant Wide_String := "ansicht";
   De_F_Special : aliased constant Wide_String := "Spez.";
   De_Train_Running_Nr : aliased constant Wide_String := "Zugnummer";
   De_RBC_ID : aliased constant Wide_String := "RBC-ID";
   De_RBC_Phone_Number : aliased constant Wide_String := "RBC-Rufnummer";
   De_SR_Speed : aliased constant Wide_String := "SR-Geschwindigkeit";
   De_SR_Distance : aliased constant Wide_String := "SR-Weg";
   De_VBC_Code : aliased constant Wide_String := "VBC-Code";
   De_Validate : aliased constant Wide_String := "Best["E4"]tigen";
   De_Train_Category : aliased constant Wide_String := "Zugkategorie";
   De_Train_Length : aliased constant Wide_String := "L["E4"]nge (m)";
   De_Brake_Percentage : aliased constant Wide_String := "Bremshundertstel";
   De_Max_Speed : aliased constant Wide_String := "H["F6"]chstgeschw. (km/h)";
   De_Axle_Load_Category : aliased constant Wide_String := "Achslastklasse";
   De_Airtight : aliased constant Wide_String := "Druckdicht";
   De_Loading_Gauge : aliased constant Wide_String := "Lichtraumprofil";
   De_Maximum_Speed : aliased constant Wide_String :=
     "H["F6"]chstgeschw. (km/h)";
   De_VBC_Code_Before : aliased constant Wide_String := "VBC #";
   De_VBC_Code_After : aliased constant Wide_String := " Setzcode";
   De_Operated_System_Version : aliased constant Wide_String :=
     "Betriebene Systemversion";
   De_Yes : aliased constant Wide_String := "Ja";
   De_No : aliased constant Wide_String := "Nein";
   De_More : aliased constant Wide_String := "Mehr";
   De_Level_0 : aliased constant Wide_String := "Level 0";
   De_Level_1 : aliased constant Wide_String := "Level 1";
   De_Level_2 : aliased constant Wide_String := "Level 2";
   De_Non_Slippery_Rail : aliased constant Wide_String := "Nicht rutschig";
   De_Slippery_Rail : aliased constant Wide_String := "Schiene rutschig";
   De_Stand_By : aliased constant Wide_String := "Bereitschaft";
   De_ATO_On : aliased constant Wide_String := "Ein";
   De_Out_Of_GC : aliased constant Wide_String := "Au["DF"]er GC";
   De_Entry_Complete_Before : aliased constant Wide_String := "Eingabe ";
   De_Entry_Complete_After : aliased constant Wide_String := " beendet?";
   De_Balise_Read_Error : aliased constant Wide_String := "Balisen-Lesefehler";
   De_Trackside_Malfunction : aliased constant Wide_String :=
     "St["F6"]rung der Streckeneinrichtung";
   De_Communication_Error : aliased constant Wide_String :=
     "Kommunikationsfehler";
   De_Entering_FS : aliased constant Wide_String := "["DC"]bergang in FS";
   De_Entering_OS : aliased constant Wide_String := "["DC"]bergang in OS";
   De_Entering_SM : aliased constant Wide_String := "["DC"]bergang in SM";
   De_Runaway_Movement : aliased constant Wide_String :=
     "Unbeabsichtigte Bewegung";
   De_SM_Refused : aliased constant Wide_String := "SM abgelehnt";
   De_SM_Request_Failed : aliased constant Wide_String :=
     "SM-Anforderung fehlgeschlagen";
   De_SH_Refused : aliased constant Wide_String := "SH abgelehnt";
   De_SH_Request_Failed : aliased constant Wide_String :=
     "SH-Anforderung fehlgeschlagen";
   De_Trackside_Not_Compatible : aliased constant Wide_String :=
     "Strecke nicht kompatibel";
   De_Train_Data_Changed : aliased constant Wide_String :=
     "Zugdaten ge["E4"]ndert";
   De_Safe_Consist_Length : aliased constant Wide_String :=
     "Sichere Zugl["E4"]nge nicht mehr verf["FC"]gbar";
   De_Train_Rejected : aliased constant Wide_String := "Zug abgewiesen";
   De_Unauthorized_Passing : aliased constant Wide_String :=
     "Unerlaubte Vorbeifahrt an EOA / LOA";
   De_No_MA_Level_Transition : aliased constant Wide_String :=
     "Keine MA beim Levelwechsel erhalten";
   De_SR_Distance_Exceeded : aliased constant Wide_String :=
     "SR-Weg ["FC"]berschritten";
   De_SH_Stop_Order : aliased constant Wide_String := "SH-Halteauftrag";
   De_SR_Stop_Order : aliased constant Wide_String := "SR-Halteauftrag";
   De_Emergency_Stop : aliased constant Wide_String := "Nothalt";
   De_RV_Distance_Exceeded : aliased constant Wide_String :=
     "RV-Weg ["FC"]berschritten";
   De_PT_Distance_Exceeded : aliased constant Wide_String :=
     "PT-Weg ["FC"]berschritten";
   De_No_Track_Description : aliased constant Wide_String :=
     "Keine Streckenbeschreibung";
   De_Route_Loading_Gauge : aliased constant Wide_String :=
     "Strecke ungeeignet - Lichtraumprofil";
   De_Route_Traction_System : aliased constant Wide_String :=
     "Strecke ungeeignet - Traktionssystem";
   De_Route_Axle_Load : aliased constant Wide_String :=
     "Strecke ungeeignet - Achslastklasse";
   De_FRMCS_Registration_Failed : aliased constant Wide_String :=
     "FRMCS-Netzanmeldung fehlgeschlagen";
   De_GSMR_Registration_Failed : aliased constant Wide_String :=
     "GSM-R-Netzanmeldung fehlgeschlagen";
   De_NL_No_Longer_Permitted : aliased constant Wide_String :=
     "NL nicht mehr zul["E4"]ssig";
   De_Odometer_Impaired : aliased constant Wide_String :=
     "Odometrie beeintr["E4"]chtigt";
   De_ATO_Needs_Data : aliased constant Wide_String :=
     "ATO ben["F6"]tigt Daten";

   German_Texts : aliased constant Table_T :=
     (Main_Window => De_Main_Window'Access,
      Override_Window => De_Override_Window'Access,
      Data_View => De_Data_View'Access,
      Special_Window => De_Special_Window'Access,
      Settings_Window => De_Settings_Window'Access,
      Driver_ID => De_Driver_ID'Access,
      Level => De_Level'Access,
      Train_Running_Number => De_Train_Running_Number'Access,
      Train_Data => De_Train_Data'Access,
      Validate_Train_Data => De_Validate_Train_Data'Access,
      SR_Speed_Distance => De_SR_Speed_Distance'Access,
      Adhesion => De_Adhesion'Access,
      Volume => De_Volume'Access,
      Brightness => De_Brightness'Access,
      ATO_Selector => De_ATO_Selector'Access,
      Radio_Data => De_Radio_Data'Access,
      GSMR_Network_ID => De_GSMR_Network_ID'Access,
      RBC_Data => De_RBC_Data'Access,
      Radio_Network_Type => De_Radio_Network_Type'Access,
      Mission_One_Radio => De_Mission_One_Radio'Access,
      Set_VBC => De_Set_VBC'Access,
      Validate_Set_VBC => De_Validate_Set_VBC'Access,
      Remove_VBC => De_Remove_VBC'Access,
      Validate_Remove_VBC => De_Validate_Remove_VBC'Access,
      System_Version => De_System_Version'Access,
      Language => De_Language'Access,
      Start => De_Start'Access,
      Shunting => De_Shunting'Access,
      Exit_Shunting => De_Exit_Shunting'Access,
      Non_Leading => De_Non_Leading'Access,
      Maintain_Shunting => De_Maintain_Shunting'Access,
      Initiate_SM => De_Initiate_SM'Access,
      Continue_SM => De_Continue_SM'Access,
      Exit_SM => De_Exit_SM'Access,
      EOA => De_EOA'Access,
      Train_Integrity => De_Train_Integrity'Access,
      BMM_Inhibition => De_BMM_Inhibition'Access,
      Revoke_BMM_Inhibition => De_Revoke_BMM_Inhibition'Access,
      ATO => De_ATO'Access,
      Contact_Last_RBC => De_Contact_Last_RBC'Access,
      Use_Short_Number => De_Use_Short_Number'Access,
      Enter_RBC_Data => De_Enter_RBC_Data'Access,
      TRN_Button => De_TRN_Button'Access,
      F_Main => De_F_Main'Access,
      F_Override_1 => De_F_Override_1'Access,
      F_Override_2 => De_F_Override_2'Access,
      F_Data_View_1 => De_F_Data_View_1'Access,
      F_Data_View_2 => De_F_Data_View_2'Access,
      F_Special => De_F_Special'Access,
      Train_Running_Nr => De_Train_Running_Nr'Access,
      RBC_ID => De_RBC_ID'Access,
      RBC_Phone_Number => De_RBC_Phone_Number'Access,
      SR_Speed => De_SR_Speed'Access,
      SR_Distance => De_SR_Distance'Access,
      VBC_Code => De_VBC_Code'Access,
      Validate => De_Validate'Access,
      Train_Category => De_Train_Category'Access,
      Train_Length => De_Train_Length'Access,
      Brake_Percentage => De_Brake_Percentage'Access,
      Max_Speed => De_Max_Speed'Access,
      Axle_Load_Category => De_Axle_Load_Category'Access,
      Airtight => De_Airtight'Access,
      Loading_Gauge => De_Loading_Gauge'Access,
      Maximum_Speed => De_Maximum_Speed'Access,
      VBC_Code_Before => De_VBC_Code_Before'Access,
      VBC_Code_After => De_VBC_Code_After'Access,
      Operated_System_Version => De_Operated_System_Version'Access,
      Yes => De_Yes'Access,
      No => De_No'Access,
      More => De_More'Access,
      Level_0 => De_Level_0'Access,
      Level_1 => De_Level_1'Access,
      Level_2 => De_Level_2'Access,
      Non_Slippery_Rail => De_Non_Slippery_Rail'Access,
      Slippery_Rail => De_Slippery_Rail'Access,
      Stand_By => De_Stand_By'Access,
      ATO_On => De_ATO_On'Access,
      Out_Of_GC => De_Out_Of_GC'Access,
      Entry_Complete_Before => De_Entry_Complete_Before'Access,
      Entry_Complete_After => De_Entry_Complete_After'Access,
      Balise_Read_Error => De_Balise_Read_Error'Access,
      Trackside_Malfunction => De_Trackside_Malfunction'Access,
      Communication_Error => De_Communication_Error'Access,
      Entering_FS => De_Entering_FS'Access,
      Entering_OS => De_Entering_OS'Access,
      Entering_SM => De_Entering_SM'Access,
      Runaway_Movement => De_Runaway_Movement'Access,
      SM_Refused => De_SM_Refused'Access,
      SM_Request_Failed => De_SM_Request_Failed'Access,
      SH_Refused => De_SH_Refused'Access,
      SH_Request_Failed => De_SH_Request_Failed'Access,
      Trackside_Not_Compatible => De_Trackside_Not_Compatible'Access,
      Train_Data_Changed => De_Train_Data_Changed'Access,
      Safe_Consist_Length => De_Safe_Consist_Length'Access,
      Train_Rejected => De_Train_Rejected'Access,
      Unauthorized_Passing => De_Unauthorized_Passing'Access,
      No_MA_Level_Transition => De_No_MA_Level_Transition'Access,
      SR_Distance_Exceeded => De_SR_Distance_Exceeded'Access,
      SH_Stop_Order => De_SH_Stop_Order'Access,
      SR_Stop_Order => De_SR_Stop_Order'Access,
      Emergency_Stop => De_Emergency_Stop'Access,
      RV_Distance_Exceeded => De_RV_Distance_Exceeded'Access,
      PT_Distance_Exceeded => De_PT_Distance_Exceeded'Access,
      No_Track_Description => De_No_Track_Description'Access,
      Route_Loading_Gauge => De_Route_Loading_Gauge'Access,
      Route_Traction_System => De_Route_Traction_System'Access,
      Route_Axle_Load => De_Route_Axle_Load'Access,
      FRMCS_Registration_Failed => De_FRMCS_Registration_Failed'Access,
      GSMR_Registration_Failed => De_GSMR_Registration_Failed'Access,
      NL_No_Longer_Permitted => De_NL_No_Longer_Permitted'Access,
      Odometer_Impaired => De_Odometer_Impaired'Access,
      ATO_Needs_Data => De_ATO_Needs_Data'Access);

   Tables : constant array (Language_T) of access constant Table_T :=
     (English => English_Texts'Access,
      German  => German_Texts'Access);

   function Selected return Language_T is (Current);

   procedure Select_Language (Language : Language_T) is
   begin
      Current := Language;
   end Select_Language;

   function Name (Language : Language_T) return Wide_String is
     (case Language is
         when German  => "Deutsch",
         when English => "English");

   function Code (Language : Language_T) return Code_T is
     (case Language is
         when German  => "de",
         when English => "en");

   function Text (ID : Text_ID; Language : Language_T) return Wide_String is
     (Tables (Language) (ID).all);

   function Text (ID : Text_ID) return Wide_String is (Text (ID, Current));

end DMI_Texts;
