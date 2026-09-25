--  ETCS DMI
--  Radio data (DMI 11.2.5, 11.3.4, 11.3.5, 11.3.15, 11.3.16; SUBSET-026
--  3.18.4.3): the list of GSM-R Radio Networks the on-board offers
--  (MSG_RADIO_NETWORKS) and the radio data the driver entered on this
--  DMI, kept to be proposed again (11.7.1.4) and to be reported to the
--  EVC (MSG_DRIVER_DATA kinds 4 to 7).
--
--  The status of the data stored on-board is the on-board's (11.7.1.3)
--  and comes with MSG_ONBOARD (DMI_Conditions). Static storage only.

with DMI_Driver_Data;
with DMI_Protocol;

package DMI_Radio_Data is

   ---------------------------------------------------------------------
   -- The alphanumeric list of available and allowed GSM-R networks
   -- (11.3.4.4, SUBSET-026 3.18.4.3.6.2)
   ---------------------------------------------------------------------

   Max_Networks : constant := DMI_Protocol.Radio_Networks_Max;
   Max_Name     : constant := DMI_Protocol.Radio_Network_Name_Max;

   subtype Network_Count_T is Natural range 0 .. Max_Networks;
   subtype Network_Index_T is Positive range 1 .. Max_Networks;

   --  Latin-1 names, as they came from the EVC
   type Name_T is record
      Length : Natural range 0 .. Max_Name := 0;
      Text   : Wide_String (1 .. Max_Name) := (others => ' ');
   end record;

   type Name_List_T is array (Network_Index_T) of Name_T;

   Network_Count : Network_Count_T := 0;
   Networks      : Name_List_T;

   --  A list arrived since the last Clear_List_Received
   List_Received : Boolean := False;

   procedure Clear_List_Received;

   --  Store a list; the caller (DMI_Core) has checked the message
   procedure Set_List (Count : Network_Count_T; List : Name_List_T);

   ---------------------------------------------------------------------
   -- Radio data entered on this DMI
   ---------------------------------------------------------------------

   --  11.3.4: the GSM-R network ID the driver selected last (a name of
   --  the list); empty when none was selected on this DMI
   GSMR_Network : Name_T;

   --  11.3.5: RBC ID (0 .. 16 777 214, SUBSET-026 A.3.11) and RBC phone
   --  number (16 digits of NID_RADIO, 7.5.1.95) as entered
   RBC_ID       : DMI_Driver_Data.Text_Value_T;
   RBC_Phone    : DMI_Driver_Data.Text_Value_T;
   RBC_Entered  : Boolean := False;

   --  How the driver chose the RBC contact information (Table 49 S3-1,
   --  Table 50 S5-1), as MSG_DRIVER_DATA kind 5 reports it
   type RBC_Choice_T is (Entered, Contact_Last_RBC, Use_Short_Number);

   procedure Reset;

end DMI_Radio_Data;
