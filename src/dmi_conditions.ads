--  ETCS DMI
--  Enabling conditions of the sub-level window buttons: Table 33 (Main,
--  11.2.1.4), Table 34 (Override, 11.2.2.4), Table 35 (Special,
--  11.2.3.4), Table 36 (Settings, 11.2.4.4) and Table 37 (Radio data,
--  11.2.5.4), plus the on-board state they are written in and the
--  decisions of the dialogue sequences on the radio data.
--
--  Every condition of the four tables names something the on-board
--  equipment knows: the mode, the validity of the stored data, the
--  communication session with the RBC, national values and vehicle
--  inputs. The DMI is told all of it (MSG_ONBOARD, see dmi_protocol.ads)
--  and evaluates the tables literally; it derives nothing and assumes
--  nothing. Until a first MSG_ONBOARD arrives nothing is known, so every
--  condition of this package is False: an unfed DMI offers no button.
--
--  The mode comes from MSG_MODE_LEVEL (Supplementary_Driving_Info), the
--  level from the same message; both are the on-board's.
--
--  One function per row of the tables, named after its window and label.
--  Rows whose button does not exist in DMI_Windows yet (Language, System
--  version, Set / Remove VBC, ATO: other work items of WIN-12) are
--  implemented all the same, so that the table is complete and the
--  button only has to be added.

with Supplementary_Driving_Info;

package DMI_Conditions is

   package SDI renames Supplementary_Driving_Info;

   ---------------------------------------------------------------------
   -- On-board state (MSG_ONBOARD); written by DMI_Core only
   ---------------------------------------------------------------------

   --  Validity of the data stored on-board (SUBSET-026 3.18, 4.10)
   Driver_ID_Valid    : Boolean := False;
   Train_Data_Valid   : Boolean := False;
   Level_Valid        : Boolean := False;
   TRN_Valid          : Boolean := False;
   RBC_Contact_Valid  : Boolean := False;
   Position_Valid     : Boolean := False;  -- valid and referred to an LRBG
   Consist_Length     : Boolean := False;  -- safe consist length available
   Consist_Front_Zero : Boolean := False;  -- ... zero in front of the engine

   --  The communication session with the RBC
   type Session_T is (No_Session,          -- no communication session
                      Establishing,        -- a session is being established
                      Exists,              -- a communication session exists
                      Exists_Above_2_2);   -- ... the only one, RBC X.Y > 2.2
   Session : Session_T := No_Session;

   --  What the RBC answered, what is stored on-board
   Train_Data_Acked    : Boolean := False; -- train data acked by the RBC
   Pending_Stop        : Boolean := False; -- pending emergency stop stored
   RBC_Transition      : Boolean := False; -- RBC transition order stored
   Length_Confirmed    : Boolean := False; -- rear end .. front end within
                                           -- the confirmed train length
   Consist_Length_Acked : Boolean := False; -- SCL sent to and acked by RBC

   --  The vehicle
   Standstill          : Boolean := False;
   Override_Speed_OK   : Boolean := False; -- at or below the "override" limit
   Non_Leading_Signal  : Boolean := False;
   Passive_Shunting    : Boolean := False;
   BMM_Inhibit_Active  : Boolean := False; -- "BTM alarm reaction inhibition"

   --  National values and on-board storage
   NV_Driver_ID_Running : Boolean := False; -- modification while running
   NV_Adhesion          : Boolean := False; -- modification by the driver
   VBC_Room             : Boolean := False; -- capacity not reached
   VBC_Stored           : Boolean := False; -- at least one VBC stored

   --  Start of mission (SUBSET-026 5.4, DMI Table 49)
   type Start_Of_Mission_T is (No_Mission_Start,
                               Awaiting_Session_End,  -- S0
                               Initiated);            -- S0 -> S1
   Start_Of_Mission : Start_Of_Mission_T := No_Mission_Start;

   --  The on-board awaits an answer: Main window with all buttons
   --  disabled and the hour glass ST05 (Table 49 S4 / A31, Table 50 S7,
   --  S8, S9)
   type Waiting_T is (Nothing,
                      Radio_Network,   -- Table 49 S4
                      RBC_Answer,      -- Table 49 A31, Table 50 S8, S9
                      Authorisation,   -- Table 50 S7
                      Shunting_Answer, -- Table 51 S1
                      SM_Answer);      -- Table 54a S1
   Waiting : Waiting_T := Nothing;

   --  A 'Start' request of the driver is pending on the EVC
   Start_Pending : Boolean := False;

   --  Radio data of the on-board (SUBSET-026 3.18.4.3): the Radio
   --  Network type stored on-board (Table 43b) and the radio systems
   --  installed on-board
   type Radio_Type_T is (Type_Unknown, FRMCS, FRMCS_GSMR, GSMR);
   Radio_Type : Radio_Type_T := Type_Unknown;

   type Radio_Installed_T is (None_Installed, FRMCS_Only, GSMR_Only,
                              Both_Installed);
   Radio_Installed : Radio_Installed_T := None_Installed;

   FRMCS_Registered  : Boolean := False; -- to the FRMCS Radio Network
   GSMR_Registered   : Boolean := False; -- >= 1 GSM-R MT to a network
   One_Radio_Yes     : Boolean := False; -- "Perform mission with only
                                         -- one radio system" is Yes
   RBC_Contact_Known : Boolean := False; -- status "valid" or "invalid"

   --  The on-board awaits a step of the GSM-R network selection: the
   --  Radio data window with all buttons disabled and the hour glass
   --  ST05 (Table 49 S3-2-1 / S3-2-3, Table 50 S5-2-1 / S5-2-3)
   type Radio_Wait_T is (No_Radio_Wait,
                         Network_List,          -- S3-2-1, S5-2-1
                         Network_Registration); -- S3-2-3, S5-2-3
   Radio_Wait : Radio_Wait_T := No_Radio_Wait;

   --  The RBC authorised the request for Shunting / for Supervised
   --  Manoeuvre the on-board awaited (Table 51 S1, Table 54a S1)
   Request_Authorised : Boolean := False;

   --  The on-board awaits an answer: the DMI presents the Main window
   --  with all buttons disabled and the hour glass ST05 (Table 49 S0,
   --  S4 and A31; Table 50 S7, S8 and S9)
   function Awaiting_Answer return Boolean;

   procedure Reset;

   ---------------------------------------------------------------------
   -- Hour glass ST05 (11.2.1.6)
   ---------------------------------------------------------------------

   --  First X position inside the window, step and period of 11.2.1.6
   ST05_First_X  : constant := 42;
   ST05_Step     : constant := 26;
   ST05_Move_Ms  : constant := 1000;

   --  Advance the movement of ST05 by Dt_Ms; any Dt_Ms is accepted. The
   --  movement restarts at the first position whenever the waiting state
   --  starts. Radio_Step: the DMI shows the waiting Radio data window
   --  (11.2.5.6, same movement) for a request of its own.
   procedure Tick (Dt_Ms : Natural; Radio_Step : Boolean := False);

   --  X position of ST05 inside the window title area, for a title area
   --  of Area_Width cells and a symbol of Symbol_Width cells. The symbol
   --  starts at ST05_First_X and moves ST05_Step to the right every
   --  second; when it no longer fits it comes back to the first position.
   function ST05_X (Area_Width : Natural; Symbol_Width : Natural)
                    return Natural;

   ---------------------------------------------------------------------
   -- Table 33 - Main window (11.2.1.4)
   ---------------------------------------------------------------------

   function Main_Start return Boolean;              -- #1
   function Main_Driver_ID return Boolean;          -- #2
   function Main_Train_Data return Boolean;         -- #3
   function Main_Level return Boolean;              -- #5
   function Main_TRN return Boolean;                -- #6
   function Main_Shunting return Boolean;           -- #7 'Shunting'
   function Main_Exit_Shunting return Boolean;      -- #7 'Exit Shunting'
   function Main_Non_Leading return Boolean;        -- #8
   function Main_Maintain_Shunting return Boolean;  -- #9
   function Main_Radio_Data return Boolean;         -- #10
   function Main_Initiate_SM return Boolean;        -- #11 'Initiate SM'
   function Main_Continue_SM return Boolean;        -- #11 'Continue in SM'
   function Main_Exit_SM return Boolean;            -- #12

   ---------------------------------------------------------------------
   -- Table 37 - Radio data window (11.2.5.4)
   ---------------------------------------------------------------------

   function Radio_Contact_Last_RBC return Boolean;  -- #1
   function Radio_Use_Short_Number return Boolean;  -- #2
   function Radio_Enter_RBC_Data return Boolean;    -- #3
   function Radio_Network_Type return Boolean;      -- #5
   function Radio_GSMR_Network_ID return Boolean;   -- #6
   function Radio_Mission_One_Radio return Boolean; -- #7 'Mission with
                                                    --    one radio system'

   ---------------------------------------------------------------------
   -- Decisions of the dialogue sequences on the radio data
   ---------------------------------------------------------------------

   --  Table 49 D7 (also S4 -> A31 and Table 50 D5 a to c): the radio
   --  system(s) the stored Radio Network type asks for are registered
   function Radio_Registered return Boolean;

   --  Table 49 D10, Table 50 D9 after A5 / A6: the stored Radio Network
   --  type is FRMCS+GSM-R while both radio systems are installed
   function Both_Radio_Systems return Boolean;

   --  The same with a Radio Network type the driver has just entered
   --  (Table 49 S3-4 -> A41 -> D10, Table 50 S5-4 -> A6 -> D9): the
   --  entered value is the stored one from then on (11.7.1.5)
   function Both_Radio_Systems (Entered : Radio_Type_T) return Boolean;

   --  Table 49 D9: both radio systems as above and either the FRMCS
   --  on-board is registered to the FRMCS Radio Network or at least one
   --  GSM-R Mobile Terminal is registered to a GSM-R Radio Network
   function Mission_With_One_Radio_Possible return Boolean;

   --  Table 49 S3-4 E5, Table 50 S5-4 E1: the driver entered FRMCS or
   --  FRMCS+GSM-R while FRMCS is installed on-board and the FRMCS
   --  on-board is not registered to the FRMCS Radio Network
   function FRMCS_Registration_Missing (Entered : Radio_Type_T)
                                        return Boolean;

   --  11.3.5.4: the RBC data window has the 'RBC phone number' input
   --  field only if the Radio Network type stored on-board is GSM-R or
   --  FRMCS+GSM-R while GSM-R is installed on-board
   function RBC_Phone_Field return Boolean;

   ---------------------------------------------------------------------
   -- Table 34 - Override window (11.2.2.4)
   ---------------------------------------------------------------------

   function Override_EOA return Boolean;            -- #1

   ---------------------------------------------------------------------
   -- Table 35 - Special window (11.2.3.4)
   ---------------------------------------------------------------------

   function Special_Adhesion return Boolean;        -- #1
   function Special_SR_Data return Boolean;         -- #2
   function Special_Train_Integrity return Boolean; -- #3
   function Special_BMM_Inhibit return Boolean;     -- #4 'BMM reaction
                                                    --    inhibition'
   function Special_BMM_Revoke return Boolean;      -- #4 'Revoke ...'

   ---------------------------------------------------------------------
   -- Table 36 - Settings window (11.2.4.4)
   ---------------------------------------------------------------------

   function Settings_Language return Boolean;       -- #1
   function Settings_Volume return Boolean;         -- #2
   function Settings_Brightness return Boolean;     -- #3
   function Settings_System_Version return Boolean; -- #4
   function Settings_Set_VBC return Boolean;        -- #5
   function Settings_Remove_VBC return Boolean;     -- #6
   function Settings_ATO return Boolean;            -- #7

end DMI_Conditions;
