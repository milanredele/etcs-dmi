--  ETCS DMI
--  The catalogue of the system status messages (chapter 15, Tables 68
--  and 70) and their life on the DMI.
--
--  Ownership. The EVC detects the conditions of SUBSET-026 (the start
--  condition of a row, the end events it names, the revocation of a
--  brake command reason) and reports them as events (MSG_SYSTEM_STATUS,
--  see dmi_protocol.ads). The DMI owns everything else and holds it
--  here, per catalogue entry:
--    * the text and its case (15.1.1.3), in the selected language
--      (15.1.1.4.2, DMI_Texts);
--    * first group, bold (8.2.3.4.7 a), class system status (5.4.1.9.1);
--    * not to be acknowledged, except "NL no longer permitted"
--      (15.1.1.4, 15.1.1.4.1), which ends when acknowledged;
--    * the time stamp: the local time of the DMI (MSG_STATUS) when the
--      message appears (8.2.3.4.6 b);
--    * "Message displayed for 30 s", counted from the start or from the
--      event the row names;
--    * "As soon as any button in the main window is selected";
--    * the end by a mode change (15.1.1.2): the modes of the Table 4.7.2
--      row of SUBSET-026 that the entry names;
--    * a single instance per message (15.1.1.7).
--  The storage is static: one state record per catalogue entry.

with Supplementary_Driving_Info;

package DMI_System_Status is

   -- Catalogue entry numbers, DMI_Protocol.SS_*
   type Entry_T is range 1 .. 38;

   -- Ids of the catalogue messages in DMI_Text_Messages: above every id
   -- that MSG_TEXT can give (u16), one per text, so that two entries with
   -- the same text share one displayed instance (15.1.1.7)
   System_ID_Base : constant := 16#1_0000#;

   -- 15.1.1.1: "Message displayed for 30 s"
   Display_Time_Ms : constant := 30_000;

   -- MSG_SYSTEM_STATUS: Entry_Raw and Event_Raw as received. A value
   -- that is not an entry number or not an event is ignored.
   procedure Event (Entry_Raw, Event_Raw : Natural);

   -- Once per DMI cycle: the 30 s timers
   procedure Tick (Dt_Ms : Natural);

   -- The mode changed to Mode (15.1.1.2)
   procedure Mode_Changed (Mode : Supplementary_Driving_Info.Mode_T);

   -- The driver selected a button of the Main window. Ends the entries
   -- whose end condition is that selection; True when at least one ended
   -- (DMI_Core then reports it to the EVC, driver action 16).
   procedure Main_Window_Button (Ended : out Boolean);

   -- ID is a message of this catalogue in DMI_Text_Messages
   function Owns (ID : Natural) return Boolean;

   -- The driver acknowledged the catalogue message ID (Owns (ID)):
   -- Number is the entry it answers (for the EVC, 0 if none), and the
   -- message ends ("Text acknowledged", Table 68)
   procedure Acknowledged (ID : Natural; Number : out Natural);

   -- The driver selected another language (DMI_Texts): the messages of
   -- this catalogue that are displayed take its texts (15.1.1.4.2)
   procedure Language_Changed;

   -- Test and diagnosis: the entry is displayed (started, not ended)
   function Active (Number : Entry_T) return Boolean;

   procedure Reset;

end DMI_System_Status;
