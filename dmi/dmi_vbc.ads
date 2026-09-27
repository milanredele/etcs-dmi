--  ETCS DMI
--  Virtual Balise Covers (DMI 11.3.12, 11.3.13, 11.4.2, 11.4.3, Table
--  45; SUBSET-026 3.15.9): the VBCs stored on-board as the EVC reports
--  them (MSG_VBC_LIST), for the Data view window, and the code of the
--  Set VBC / Remove VBC entry / validation process that is running.
--
--  The VBCs themselves are the on-board's: the DMI sends what the driver
--  validated (MSG_DRIVER_DATA kinds 8 and 9) and shows the list the EVC
--  reports back; it never changes the list itself. Static storage only.

with DMI_Driver_Data;
with DMI_Protocol;

package DMI_VBC is

   Max_Stored : constant := DMI_Protocol.VBC_List_Max;
   Code_Max   : constant := DMI_Protocol.VBC_Code_Max;

   subtype Code_T is Natural range 0 .. Code_Max;
   subtype Count_T is Natural range 0 .. Max_Stored;
   subtype Index_T is Positive range 1 .. Max_Stored;

   type Code_List_T is array (Index_T) of Code_T;

   ---------------------------------------------------------------------
   -- The VBCs stored on-board (MSG_VBC_LIST), by their set code
   ---------------------------------------------------------------------

   --  False until the first list arrives: nothing is known then, and
   --  the Data view shows no VBC item
   Known : Boolean := False;
   Count : Count_T := 0;
   Codes : Code_List_T := (others => 0);

   --  Store a list; the caller (DMI_Core) has checked the message
   procedure Set_List (New_Count : Count_T; New_Codes : Code_List_T);

   ---------------------------------------------------------------------
   -- The running entry / validation process (Table 54 S6-1 / S6-2 and
   -- S7-1 / S7-2)
   ---------------------------------------------------------------------

   --  11.7.1.6.2: pressing 'Yes' of the Set VBC or Remove VBC window
   --  does no action on the VBCs stored on-board; the entered value waits
   --  here for the validation window. Table 54 S6-1 / S7-1 entered from
   --  S6-2 / S7-2 propose it again; entered from S1 they propose nothing
   --  (Clear).
   Pending : DMI_Driver_Data.Text_Value_T;
   Pending_Valid : Boolean := False;

   procedure Hold (Value : DMI_Driver_Data.Text_Value_T);
   procedure Clear;

   --  The pending value as a code; a value that is not a number within
   --  0 .. Code_Max (the entry window's technical range check keeps it
   --  there) gives 0 (total, never raises)
   function Pending_Code return Code_T;

   procedure Reset;

end DMI_VBC;
