--  ETCS DMI
--  The fixed texts the DMI displays, in every language it holds (5.5).
--
--  5.5.1.3: the labels of the buttons, the window titles, the labels of
--  the input fields, the echo texts, the data view items and the text
--  messages (except the plain text messages of the trackside) are
--  displayed in the selected language. Every such text of the DMI is one
--  Text_ID here, with one table per language; nothing under dmi/ draws
--  a word of its own. What stays out: values (the train categories
--  'PASS 1' .. of Table 41, the axle load categories, the loading
--  gauges G1 .. GC, the radio network types, the level 'NTC' that stands
--  for the abbreviation of a National System, numbers), and the texts
--  that reach the DMI as text (the EVC's text messages, the GSM-R
--  network names, the National System name).
--
--  5.5.1.1: the languages pre-configured on-board are English, the
--  default, German and Hungarian, all complete. The fonts carry ISO
--  8859-1 and Latin Extended-A (Font), which cover them: Hungarian
--  needs o and u with double acute (16#150#, 16#151#, 16#170#,
--  16#171#) besides the accented letters of Latin-1.
--
--  The Hungarian wording is the one of the MAV ETCS operating
--  instructions (doc/national-instructions/etcs_uzemeltetesi_utasitas.pdf,
--  body and appendices 1 and 3) wherever the document names the thing;
--  the texts it does not name are translated in its register and marked
--  "Choice:" in the table, the short forms it forces (a button, an F
--  button) "Short form:" with the full term.
--
--  The selection is a setting of the DMI unit, kept like the luminance
--  and the volume (5.2.2.2, 5.2.3.2): DMI_Core.Initialise and a loss of
--  the EVC link leave it alone. The Language window (11.3.6) changes it.
--
--  Static storage only: every text is an aliased constant and the
--  tables hold access values to them; no allocation.

package DMI_Texts
  with Preelaborate
is

   -- 11.3.6.4 / Figure 119: the keys of the Language window show the
   -- languages in their own language, in the order of their names
   -- (Deutsch, English, Magyar), which is the order of this type
   type Language_T is (German, English, Hungarian);

   Default_Language : constant Language_T := English;

   function Selected return Language_T;

   -- The driver selected a language (11.3.6): every text displayed from
   -- now on is in that language
   procedure Select_Language (Language : Language_T);

   -- 11.3.6.4: the name of the language in that language
   function Name (Language : Language_T) return Wide_String;

   -- ISO 639-1 code of the language, as MSG_DRIVER_DATA kind 10 carries
   -- it (dmi_protocol.ads)
   subtype Code_T is String (1 .. 2);
   function Code (Language : Language_T) return Code_T;

   type Text_ID is
     (
      -- Window titles (11.2.x.2, 11.3.x.2, 11.4.x.2, 11.5.x.2); most of
      -- them are also the label of the button that opens the window
      -- (Tables 33 to 37) or a data view item (Table 45)
      Main_Window, Override_Window, Data_View, Special_Window,
      Settings_Window, Driver_ID, Level, Train_Running_Number, Train_Data,
      Validate_Train_Data, SR_Speed_Distance, Adhesion, Volume, Brightness,
      ATO_Selector, Radio_Data, GSMR_Network_ID, RBC_Data,
      Radio_Network_Type, Mission_One_Radio, Set_VBC, Validate_Set_VBC,
      Remove_VBC, Validate_Remove_VBC, System_Version, Language,

      -- Button labels of Tables 33 to 37 that are no window title, and
      -- the 'TRN' button of the Driver ID window (11.3.3.7 a)
      Start, Shunting, Exit_Shunting, Non_Leading, Maintain_Shunting,
      Initiate_SM, Continue_SM, Exit_SM, EOA, Train_Integrity,
      BMM_Inhibition, Revoke_BMM_Inhibition, ATO, Contact_Last_RBC,
      Use_Short_Number, Enter_RBC_Data, TRN_Button,

      -- The buttons F1 to F4 of the default window (8.6.1.2 to 8.6.1.5),
      -- on one line or on two
      F_Main, F_Override_1, F_Override_2, F_Data_View_1, F_Data_View_2,
      F_Special,

      -- Labels of input fields and of their echo texts (10.3.1.10,
      -- 10.3.3); Table 40 and the data view items 4 to 10 of Table 45
      Train_Running_Nr, RBC_ID, RBC_Phone_Number, SR_Speed, SR_Distance,
      VBC_Code, Validate, Train_Category, Train_Length, Brake_Percentage,
      Max_Speed, Axle_Load_Category, Airtight, Loading_Gauge,

      -- Data view items (Tables 45, 46) that are no input field label;
      -- 'VBC #n set code' is VBC_Code_Before, n, VBC_Code_After
      Maximum_Speed, VBC_Code_Before, VBC_Code_After,
      Operated_System_Version,

      -- Keys of the dedicated keyboards (10.3.5.18, 10.3.5.19, Tables 38,
      -- 42, 43, 43a), the 'Yes' of 8.2.3.3, and the question of 10.3.5.7:
      -- Entry_Complete_Before, the window title, Entry_Complete_After
      Yes, No, More, Level_0, Level_1, Level_2, Non_Slippery_Rail,
      Slippery_Rail, Stand_By, ATO_On, Out_Of_GC, Entry_Complete_Before,
      Entry_Complete_After,

      -- System status messages (chapter 15, Tables 68 and 70); the
      -- English ones keep the case of the tables (15.1.1.3), the others
      -- follow the selected language (15.1.1.4.2)
      Balise_Read_Error, Trackside_Malfunction, Communication_Error,
      Entering_FS, Entering_OS, Entering_SM, Runaway_Movement, SM_Refused,
      SM_Request_Failed, SH_Refused, SH_Request_Failed,
      Trackside_Not_Compatible, Train_Data_Changed, Safe_Consist_Length,
      Train_Rejected, Unauthorized_Passing, No_MA_Level_Transition,
      SR_Distance_Exceeded, SH_Stop_Order, SR_Stop_Order, Emergency_Stop,
      RV_Distance_Exceeded, PT_Distance_Exceeded, No_Track_Description,
      Route_Loading_Gauge, Route_Traction_System, Route_Axle_Load,
      FRMCS_Registration_Failed, GSMR_Registration_Failed,
      NL_No_Longer_Permitted, Odometer_Impaired, ATO_Needs_Data);

   -- The text in the selected language
   function Text (ID : Text_ID) return Wide_String;

   -- The text in the given language
   function Text (ID : Text_ID; Language : Language_T) return Wide_String;

end DMI_Texts;
