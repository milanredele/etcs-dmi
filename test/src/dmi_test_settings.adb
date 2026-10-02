--  ETCS DMI
--  Body of DMI_Test_Settings (see dmi_test_settings.ads).

with Ada.Streams;
with DMI_Core;
with DMI_Protocol;
with DMI_Test_Support;
with DMI_Windows;
with EVC_Mock;
with General_Parameters;
with Interfaces;
with Supplementary_Driving_Info;
with Test_Support;
use Test_Support;
use DMI_Test_Support;
use type DMI_Test_Support.Win_U8;

package body DMI_Test_Settings is

   procedure Scenario_Win_Main_Menu is
      --  level 2 with what Table 33 #11 asks for: the position referred
      --  to an LRBG (bit 5) and the safe consist length information, zero
      --  in front of the engine (bits 6, 7)
      Data_SM : constant Win_U8 := Win_Data_All or 16#E0#;
   begin
      Reset;
      Win_Onboard;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Win_At_Standstill;
      Win_Open_Main;
      Check (Win_Top_Is (DMI_Windows.W_Main), "win: the Main window");

      -- #10 Radio data
      Check (Win_Enabled (10),
             "Table 33 #10: Radio data in SB at standstill with valid data");
      Win_Onboard (Data => 16#0B#);             -- level not valid
      Check (not Win_Enabled (10), "Table 33 #10: not without a valid level");
      Win_Onboard (Train => Win_Running);
      Check (not Win_Enabled (10), "Table 33 #10: not while running");
      Win_Onboard;

      -- #9 Maintain Shunting, #7 Exit Shunting in SH
      Check (not Win_Enabled (9), "Table 33 #9: no Maintain Shunting in SB");
      Check (not Win_Enabled (12), "Table 33 #12: no Exit SM outside SM");
      Send_Mode_Level (Mode => 8, Level => 4); -- SH
      Win_Onboard;
      Check (not Win_Enabled (9),
             "Table 33 #9: SH without the passive shunting signal");
      Check (Win_Enabled (7), "Table 33 #7: 'Exit Shunting' in SH");
      Win_Onboard (Train => Win_Standing or 16#08#);
      Check (Win_Enabled (9),
             "Table 33 #9: Maintain Shunting with the passive shunting"
             & " signal");
      Step;
      Check_Frame ("win_main_sh");
      Win_Onboard (Train => Win_Running or 16#08#);
      Check (not Win_Enabled (7),
             "Table 33 #7: no Exit Shunting while running");
      Check (Win_Enabled (9), "Table 33 #9: Maintain Shunting while running");
      Drain_Outbox;
      Win_Menu_Long (9);
      Expect_Actions (19, 1, "Maintain Shunting is sent (action 19)");
      Check (not DMI_Windows.Is_Open,
             "Table 50 S1: Maintain Shunting -> the default window");

      Win_Onboard (Train => Win_Standing);
      Win_Open_Main;
      Drain_Outbox;
      Win_Menu_Long (7);
      Expect_Actions (8, 1, "'Exit Shunting' is sent (action 8)");
      Check (not DMI_Windows.Is_Open,
             "Table 50 S1: Exit Shunting -> S0 of Start Up (default window)");
      Send_Mode_Level (Mode => 1, Level => 4); -- the EVC: SB
      Win_Onboard (Data => 16#04#, SOM => 2);  -- start of mission
      Check (DMI_Windows.In_Start_Up
             and then Win_Top_Is (DMI_Windows.W_Driver_ID),
             "after Exit Shunting the EVC engages Start Up (S0 -> S1)");
      Win_Onboard (SOM => 0);                   -- ends it again
      Check (not DMI_Windows.Is_Open, "the Start Up sequence is aborted");

      -- #11 Initiate SM: level 2, a session with an RBC above 2.2
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Win_Onboard (Data => Data_SM, Session => 3);
      Win_Open_Main;
      Check (Win_Enabled (11), "Table 33 #11: Initiate SM in SB, level 2");
      Win_Onboard (Data => Data_SM, Session => 2);
      Check (not Win_Enabled (11),
             "Table 33 #11: not without an RBC above system version 2.2");
      Win_Onboard (Data => Data_SM, Session => 3, RBC => 16#04#);
      Check (not Win_Enabled (11),
             "Table 33 #11: not with an RBC transition order stored");
      Win_Onboard (Data => Win_Data_All or 16#20#, Session => 3);
      Check (not Win_Enabled (11),
             "Table 33 #11: not without safe consist length information");
      Win_Onboard (Data => Win_Data_All or 16#C0#, Session => 3);
      Check (not Win_Enabled (11),
             "Table 33 #11: not without a position referred to an LRBG");
      Win_Onboard (Data => Data_SM, Session => 3);
      Step;
      Check_Frame ("win_main_initiate_sm");

      Drain_Outbox;
      Win_Menu_Long (11);
      Expect_Action_Arg (17, 0, "'Initiate SM' is sent (action 17, arg 0)");
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 54a S1: the Main window stays");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 5);
      Check (DMI_Windows.Waiting_Displayed
             and then not Win_Enabled (11) and then not Win_Enabled (2),
             "Table 54a S1: all buttons disabled while the RBC is asked");
      Check (not DMI_Windows.Close_Enabled,
             "11.7.8.2: [Close] is disabled in S1");
      Step;
      Check_Frame ("win_sm_waiting");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 0, Answer => 0);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.Waiting_Displayed,
             "Table 54a S1: 'SM refused' -> S0, the Main window");

      Drain_Outbox;
      Win_Menu_Long (11);
      Expect_Action_Arg (17, 0, "'Initiate SM' again");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 5);
      Send_Mode_Level (Mode => 4, Level => 5); -- SM
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 0, Answer => 1);
      Check (not DMI_Windows.Is_Open,
             "Table 54a S1: the SM authorisation -> the default window");

      -- #11 Continue in SM and #12 Exit SM in SM
      Win_Open_Main;
      Check (Win_Enabled (11), "Table 33 #11: 'Continue in SM' in SM");
      Check (Win_Enabled (12), "Table 33 #12: Exit SM in SM at standstill");
      Step;
      Check_Frame ("win_main_sm");
      Drain_Outbox;
      Win_Menu_Long (11);
      Expect_Action_Arg (17, 1, "'Continue in SM' is sent (action 17, arg 1)");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 5);
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 0, Answer => 1);
      Check (not DMI_Windows.Is_Open,
             "Table 54a S1: authorised in SM, the answer and not the mode"
             & " leads to the default window");
      Win_Open_Main;
      Win_Onboard (Data => Data_SM, Session => 3, Train => Win_Running);
      Check (not Win_Enabled (12), "Table 33 #12: no Exit SM while running");
      Win_Onboard (Data => Data_SM, Session => 3);
      Drain_Outbox;
      Win_Menu_Long (12);
      Expect_Action_Arg (17, 2, "'Exit SM' is sent (action 17, arg 2)");
      Check (not DMI_Windows.Is_Open,
             "Table 50 S1: Exit SM -> S0 of Start Up (default window)");

      -- Shunting in level 2 asks the RBC (Table 51 D1 -> S1)
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Win_Onboard (Data => Data_SM, Session => 3);
      Win_Open_Main;
      Drain_Outbox;
      Win_Menu_Long (7);
      Expect_Actions (7, 1, "the request for shunting is sent");
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 51 D1: level 2 -> S1, the Main window stays");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 4);
      Check (DMI_Windows.Waiting_Displayed
             and then not DMI_Windows.Close_Enabled,
             "Table 51 S1 / 11.7.4.2: all buttons and [Close] disabled");
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 0);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.Waiting_Displayed,
             "Table 51 S1: 'Shunting Refused' -> S0, the Main window");
      Win_Menu_Long (7);
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 4);
      Send_Mode_Level (Mode => 8, Level => 5); -- SH
      Win_Onboard (Data => Data_SM, Session => 3, Waiting => 0, Answer => 1);
      Check (not DMI_Windows.Is_Open,
             "Table 51 S1: 'Shunting Authorised' -> the default window");

      -- Shunting in level 1 goes at once (Table 51 D1)
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Win_Onboard;
      Win_Open_Main;
      Drain_Outbox;
      Win_Menu_Long (7);
      Expect_Actions (7, 1, "the request for shunting in level 1");
      Check (not DMI_Windows.Is_Open,
             "Table 51 D1: level 1 -> the default window");
      Drain_Outbox;
   end Scenario_Win_Main_Menu;

   ---------------------------------------------------------------------
   -- Table 35 #4 (BMM reaction inhibition) and Table 36 (symbols)
   ---------------------------------------------------------------------

   procedure Scenario_Win_Special_Settings is
   begin
      Reset;
      Win_Onboard;
      Send_Mode_Level (Mode => 1, Level => 4); -- SB, level 1
      Win_At_Standstill;
      Win_Default;
      Press (610, 190);                         -- F4: Special
      Check (Win_Top_Is (DMI_Windows.W_Special), "win: the Special window");
      Check (Win_Enabled (4),
             "Table 35 #4: BMM reaction inhibition in SB, level 1");
      Drain_Outbox;
      Win_Menu (4);
      Expect_Action_Arg (18, 0,
                         "'BMM reaction inhibition' is sent (action 18, 0)");
      Check (not DMI_Windows.Is_Open,
             "Table 53 S1: -> the default window (ST07 is the EVC's)");

      Win_Onboard (Train => Win_Standing or 16#10#); -- inhibition active
      Press (610, 190);
      Check (Win_Enabled (4),
             "Table 35 #4: 'Revoke BMM reaction inhibition' when active");
      Step;
      Check_Frame ("win_special_bmm_revoke");
      Drain_Outbox;
      Win_Menu (4);
      Expect_Action_Arg (18, 1, "'Revoke ...' is sent (action 18, arg 1)");
      Check (not DMI_Windows.Is_Open, "Table 53 S1: -> the default window");

      Press (610, 190);
      Send_Mode_Level (Mode => 1, Level => 2); -- level 0
      Win_Onboard;
      Check (not Win_Enabled (4), "Table 35 #4: not in level 0");
      Send_Mode_Level (Mode => 7, Level => 5); -- SR, level 2
      Win_Onboard (Data => 0);
      Check (Win_Enabled (4),
             "Table 35 #4: in SR without the SB conditions on the data");
      Win_Onboard (Data => 0, Train => Win_Running);
      Check (not Win_Enabled (4), "Table 35 #4: not while running");

      -- Table 36: the symbols SE03, SE02, SE01; disabled in SB while
      -- running, drawn dark grey
      Send_Mode_Level (Mode => 1, Level => 4);
      Win_Onboard (Train => Win_Running);
      Win_Default;
      Press (610, 240);                         -- F5: Settings
      Check (Win_Top_Is (DMI_Windows.W_Settings), "win: the Settings window");
      Check (not Win_Enabled (2) and then not Win_Enabled (3),
             "Table 36 #2, #3: disabled in SB while running");
      Step;
      Check_Frame ("win_settings_disabled");
      Win_Onboard;
      Win_Menu (2);
      Check (Win_Top_Is (DMI_Windows.W_Volume), "Table 36 #2: SE02 -> Volume");
      Win_Close;
      Win_Menu (3);
      Check (Win_Top_Is (DMI_Windows.W_Brightness),
             "Table 36 #3: SE01 -> Brightness");
      Win_Default;
      Drain_Outbox;
   end Scenario_Win_Special_Settings;

   ---------------------------------------------------------------------
   -- Table 37 and the Radio data part of the Main window dialogue
   -- sequence (Table 50 S1 -> S5-1 .. S5-4, S5-2-x, A5 / A6 / A7, D9,
   -- S10, S4 -> D5) and Table 48
   ---------------------------------------------------------------------

   procedure Scenario_Win_Radio_Data is
      Data_Valid : constant Win_U8 := Win_Data_All or 16#10#; -- + RBC info

      procedure Radio (R : Win_U8; Data : Win_U8 := Data_Valid;
                       Radio_Wait : Win_U8 := 0) is
      begin
         Win_Onboard (Data => Data, Radio => R, Radio_Wait => Radio_Wait);
      end Radio;

      procedure Open_Radio_Data is
      begin
         Win_Open_Main;
         Win_Menu (10);
      end Open_Radio_Data;
   begin
      Reset;
      Radio (Win_Radio_GSMR);
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2
      Win_At_Standstill;
      Open_Radio_Data;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 50 S1 -> S5-1: the Radio data window");
      Check (Win_Enabled (1) and then Win_Enabled (2) and then Win_Enabled (3)
             and then Win_Enabled (5) and then Win_Enabled (6),
             "Table 37 #1, #2, #3, #5, #6: GSM-R registered, level 2");
      Check (not Win_Enabled (7),
             "Table 37 #7: no mission with one radio system with GSM-R only");
      Check (DMI_Windows.Close_Enabled, "11.7.3.2: [Close] in S5-1");
      Step;
      Check_Frame ("win_radio_data");

      -- Table 37, row by row
      Radio (Win_GSMR or Win_Only_GSMR or Win_Known);
      Check (not Win_Enabled (1) and then not Win_Enabled (2)
             and then not Win_Enabled (3),
             "Table 37 #1 .. #3: nothing without a registered GSM-R MT");
      Check (Win_Enabled (5) and then Win_Enabled (6),
             "Table 37 #5, #6: no registration needed");
      Radio (Win_GSMR or Win_Only_GSMR or Win_GSMR_Reg);
      Check (not Win_Enabled (1) and then Win_Enabled (3),
             "Table 37 #1: 'Contact last RBC' needs RBC contact information");
      Radio (Win_FRMCS or Win_Only_FRMCS or Win_FRMCS_Reg or Win_Known);
      Check (Win_Enabled (1) and then Win_Enabled (3)
             and then not Win_Enabled (2) and then not Win_Enabled (6),
             "Table 37: FRMCS registered: #1, #3, no short number, no GSM-R");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_FRMCS_Reg or Win_Known);
      Check (not Win_Enabled (1) and then not Win_Enabled (3),
             "Table 37 #1, #3: both systems need both registrations");
      Check (Win_Enabled (7),
             "Table 37 #7: one registration of two -> one radio system");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_FRMCS_Reg or Win_Known
             or Win_One_Yes);
      Check (Win_Enabled (1) and then Win_Enabled (3)
             and then not Win_Enabled (2),
             "Table 37 #1, #3: ... or one of them with 'one radio system'");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_One_Yes);
      Check (Win_Enabled (2),
             "Table 37 #2: short number with GSM-R and 'one radio system'");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_FRMCS_Reg);
      Check (not Win_Enabled (7),
             "Table 37 #7: not with both registrations");
      Send_Mode_Level (Mode => 1, Level => 4); -- level 1
      Radio (Win_Radio_GSMR);
      Check (not Win_Enabled (1) and then not Win_Enabled (2)
             and then not Win_Enabled (3) and then Win_Enabled (5)
             and then Win_Enabled (6),
             "Table 37: in level 1 only the radio network type and ID");
      Send_Mode_Level (Mode => 4, Level => 5); -- SM
      Radio (Win_Radio_GSMR);
      Check (not Win_Enabled (5) and then Win_Enabled (6),
             "Table 37 #5 not in SM, #6 in SM");
      Send_Mode_Level (Mode => 1, Level => 5);
      Radio (Win_Radio_GSMR, Data => Win_Data_All and 16#0E#);
      Check (not Win_Enabled (5) and then not Win_Enabled (6),
             "Table 37 #5, #6: not without a valid Driver ID");
      Radio (Win_Radio_GSMR);

      -- S5-1: 'Contact last RBC' and 'Use short number' -> S8
      Drain_Outbox;
      Win_Menu (1);
      Expect_Driver_Data (5, Win_RBC_Bytes (1, 0, ""),
                          "'Contact last RBC': kind 5, choice 1");
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 50 S5-1 -> S8: the Main window");
      Win_Onboard (Data => Data_Valid, Radio => Win_Radio_GSMR, Waiting => 2);
      Check (DMI_Windows.Waiting_Displayed,
             "Table 50 S8: the EVC awaits the RBC");
      Radio (Win_Radio_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Main), "Table 50 D3 / D4 -> S1");
      Win_Menu (10);
      Drain_Outbox;
      Win_Menu (2);
      Expect_Driver_Data (5, Win_RBC_Bytes (2, 0, ""),
                          "'Use short number': kind 5, choice 2");

      -- S5-3: the RBC data window
      Win_Menu (10);
      Win_Menu (3);
      Check (Win_Top_Is (DMI_Windows.W_RBC_Data),
             "Table 50 S5-1 -> S5-3: the RBC data window");
      Check (Win_Value (1) = "" and then Win_Value (2) = "",
             "11.7.1.4: nothing entered on this DMI, nothing proposed");
      Win_Type ("16777215");
      Enter_Field (1);
      Check (not Win_Enabled (17),
             "RBC ID above 16 777 214 fails the technical range (A.3.11)");
      for I in 1 .. 8 loop
         Key (10);                              -- [Delete]
      end loop;
      Win_Type ("1234567");
      Enter_Field (1);
      Win_Type ("0123456789012345");
      Enter_Field (2);
      Step;
      Check_Frame ("win_rbc_data");
      Drain_Outbox;
      Press (167, 440);                         -- RBC data entry complete? Yes
      Expect_Driver_Data (5, Win_RBC_Bytes (0, 1234567, "0123456789012345"),
                          "the RBC data: kind 5, choice 0, id, phone");
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 50 S5-3 'Yes' -> S8: the Main window");
      Win_Menu (10);
      Win_Menu (3);
      Check (Win_Value (1) = "1234567"
             and then Win_Value (2) = "0123456789012345",
             "11.7.1.4: the RBC data held are proposed");
      -- Table 48: the RBC data window gives way to its parent
      Radio (Win_Radio_GSMR, Data => Win_Data_All and 16#0E#);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 48: RBC data -> the Radio data window when 'Enter RBC"
             & " data' loses its conditions");
      Radio (Win_Radio_GSMR);

      -- 11.3.5.4: no phone number field with FRMCS alone
      Radio (Win_FRMCS or Win_Only_FRMCS or Win_FRMCS_Reg or Win_Known);
      Win_Menu (3);
      Step;
      Check_Frame ("win_rbc_data_frmcs");
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "11.7.3.2: [Close] of S5-3 goes back to S5-1");

      -- S5-4: the Radio network type window
      Radio (Win_Radio_GSMR);
      Win_Menu (5);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Network_Type)
             and then Win_Value = "GSM-R",
             "Table 50 S5-4: the stored type GSM-R is proposed");
      Step;
      Check_Frame ("win_radio_network_type");
      Drain_Outbox;
      Key (2);
      Enter_Single;
      Expect_Driver_Data (6, (1 => 2), "FRMCS+GSM-R: kind 6, value 2");
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 50 S5-4 E2 (FRMCS not installed) -> S5-1");
      -- E1 -> A6 -> D9: FRMCS installed, not registered
      Radio (Win_GSMR or Win_Both or Win_GSMR_Reg or Win_Known);
      Win_Menu (5);
      Key (2);
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 50 S5-4 E1 -> A6 -> D9 (both systems) -> S5-1");
      Win_Menu (5);
      Drain_Outbox;
      Key (1);
      Enter_Single;
      Expect_Driver_Data (6, (1 => 1), "FRMCS: kind 6, value 1");
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 50 S5-4 E1 -> A6 -> D9 (FRMCS alone) -> S1");

      -- S5-2-1 .. S5-2-3: the GSM-R network ID
      Radio (Win_Radio_GSMR);
      Win_Menu (10);
      Drain_Outbox;
      Win_Menu_Long (6);
      Expect_Driver_Data (4, (1 => 0),
                          "'GSM-R network ID': kind 4 without a name");
      Check (DMI_Windows.Radio_Step_Displayed
             and then not Win_Enabled (1) and then not Win_Enabled (5),
             "Table 50 S5-2-1: all buttons disabled at once");
      Check (not DMI_Windows.Close_Enabled,
             "11.7.3.2: [Close] is disabled in S5-2-1");
      Step;
      Check_Frame ("win_radio_data_st05");
      Radio (Win_Radio_GSMR, Radio_Wait => 1);
      Send_Radio_Networks ("GSMR-A,GSMR-B,Telecom X");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "S5-2-1: the list waits for the EVC to end the step");
      Send_Raw (16#0D#, (2, 3, 65, 66, 67));   -- truncated: ignored
      Radio (Win_Radio_GSMR, Radio_Wait => 0);
      Check (Win_Top_Is (DMI_Windows.W_GSMR_Network),
             "Table 50 S5-2-1 -> S5-2-2: the GSM-R network ID window");
      Check (DMI_Windows.Close_Enabled, "11.7.3.2: [Close] in S5-2-2");
      Check (Win_Value = "", "no network selected on this DMI yet");
      Step;
      Check_Frame ("win_gsmr_network");
      Drain_Outbox;
      Key (2);
      Enter_Single;
      Expect_Driver_Data (4, Win_Name_Bytes ("GSMR-B"),
                          "the selected network: kind 4 with its name");
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.Radio_Step_Displayed,
             "Table 50 S5-2-2 -> S5-2-3: the Radio data window waits");
      Radio (Win_Radio_GSMR);
      Check (DMI_Windows.Radio_Step_Displayed,
             "S5-2-3 lasts until the EVC reported the registration");
      Radio (Win_Radio_GSMR, Radio_Wait => 2);
      Check (DMI_Windows.Radio_Step_Displayed, "S5-2-3 while the EVC waits");
      Radio (Win_Radio_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then not DMI_Windows.Radio_Step_Displayed
             and then Win_Enabled (1),
             "Table 50 S5-2-3 -> S5-1 once registered");
      Win_Menu_Long (6);
      Send_Radio_Networks ("GSMR-A,GSMR-B,Telecom X");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_GSMR_Network)
             and then Win_Value = "GSMR-B",
             "11.7.1.4: the network selected before is proposed");
      Win_Close;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then not DMI_Windows.Radio_Step_Displayed,
             "[Close] of S5-2-2 goes back to S5-1");
      -- A5 -> D9: an empty list
      Win_Menu_Long (6);
      Send_Radio_Networks ("");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 50 A5 -> D9 (GSM-R alone) -> S1");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_Known);
      Win_Menu (10);
      Win_Menu_Long (6);
      Send_Radio_Networks ("");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then not DMI_Windows.Radio_Step_Displayed,
             "Table 50 A5 -> D9 (both systems) -> S5-1");

      -- A7 -> S10: the Mission with one radio system window
      Win_Menu (7);
      Check (Win_Top_Is (DMI_Windows.W_One_Radio) and then Win_Value = "",
             "Table 50 S10: no value proposed");
      Step;
      Check_Frame ("win_one_radio");
      Drain_Outbox;
      Key (8);                                  -- 'Yes'
      Enter_Single;
      Expect_Driver_Data (7, (1 => 1), "'Yes': kind 7, value 1");
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 50 S10 'Yes' -> S5-1");
      Win_Menu (7);
      Drain_Outbox;
      Key (7);                                  -- 'No'
      Enter_Single;
      Expect_Driver_Data (7, (1 => 0), "'No': kind 7, value 0");
      Check (Win_Top_Is (DMI_Windows.W_Main), "Table 50 S10 'No' -> S1");

      -- Table 50 S4 -> D5: level 2 entered from the Main window
      Radio (Win_Radio_GSMR);
      Win_Menu (5);
      Choose_Level (2);
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 50 D5: valid RBC contact information, registered -> S8");
      Radio (Win_Radio_GSMR, Data => Win_Data_All);
      Win_Menu (5);
      Choose_Level (2);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data),
             "Table 50 D5: without valid RBC contact information -> S5-1");
      Win_Default;
      Drain_Outbox;
   end Scenario_Win_Radio_Data;

   ---------------------------------------------------------------------
   -- The radio steps of the Start Up dialogue sequence (Table 49 S2 ->
   -- S3-1 .. S3-4, S3-2-x, A29 / A41 / A43 -> D10, S5, D7 -> S4 -> D9)
   ---------------------------------------------------------------------

   procedure Scenario_Win_Start_Up_Radio is
      --  the Driver ID is valid once entered, the level is not
      Data_ID : constant Win_U8 := 16#01#;

      procedure Radio (R : Win_U8; Data : Win_U8 := Data_ID or 16#04#;
                       SOM : Win_U8 := 2; Radio_Wait : Win_U8 := 0;
                       Waiting : Win_U8 := 0) is
      begin
         Win_Onboard (Data => Data, SOM => SOM, Radio => R,
                      Radio_Wait => Radio_Wait, Waiting => Waiting);
      end Radio;

      --  S0 -> S1 -> S2 -> S3-1 with the radio byte R
      procedure To_S3_1 (R : Win_U8) is
      begin
         Win_Onboard (Data => 0, SOM => 0, Radio => R);
         Send_Mode_Level (Mode => 1, Level => 0); -- SB, level unknown
         Win_Onboard (Data => 0, SOM => 2, Radio => R);
         Press (385, 240); Press (487, 90);    -- Driver ID 1
         Radio (R, Data => Data_ID);
         Choose_Level (2);
         Send_Mode_Level (Mode => 1, Level => 5);
         Radio (R);
      end To_S3_1;
   begin
      Reset;
      Win_At_Standstill;
      To_S3_1 (Win_Radio_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "Table 49 S2 level 2 -> S3-1: the Radio data window");
      Check (not DMI_Windows.Close_Enabled,
             "11.7.2.2: [Close] is disabled in S3-1");
      Step;
      Check_Frame ("win_startup_radio_data");

      -- S3-3 and S3-4 can be closed (11.7.2.2)
      Win_Menu (3);
      Check (Win_Top_Is (DMI_Windows.W_RBC_Data)
             and then DMI_Windows.Close_Enabled,
             "Table 49 S3-3: the RBC data window, [Close] enabled");
      Win_Close;
      Win_Menu (5);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Network_Type)
             and then DMI_Windows.Close_Enabled,
             "Table 49 S3-4: the Radio network type window, [Close] enabled");
      Key (3);
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "Table 49 S3-4 E6 -> S3-1");

      -- S3-2-1 .. S3-2-3
      Win_Menu_Long (6);
      Check (DMI_Windows.Radio_Step_Displayed
             and then not DMI_Windows.Close_Enabled,
             "Table 49 S3-2-1: hour glass, [Close] disabled");
      Send_Radio_Networks ("GSMR-A,GSMR-B,Telecom X");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_GSMR_Network)
             and then DMI_Windows.Close_Enabled,
             "Table 49 S3-2-2, [Close] enabled (11.7.2.2)");
      Key (1);
      Enter_Single;
      Radio (Win_Radio_GSMR, Radio_Wait => 2);
      Check (DMI_Windows.Radio_Step_Displayed
             and then not DMI_Windows.Close_Enabled,
             "Table 49 S3-2-3: hour glass, [Close] disabled");
      Radio (Win_Radio_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then not DMI_Windows.Radio_Step_Displayed
             and then DMI_Windows.In_Start_Up,
             "Table 49 S3-2-3 -> S3-1");

      -- A29 -> D10 -> S10
      Win_Menu_Long (6);
      Send_Radio_Networks ("");
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 A29 -> D10 (GSM-R alone) -> S10");

      -- S3-1 'Contact last RBC' -> A31
      To_S3_1 (Win_Radio_GSMR);
      Drain_Outbox;
      Win_Menu (1);
      Expect_Driver_Data (5, Win_RBC_Bytes (1, 0, ""),
                          "S3-1 'Contact last RBC': kind 5, choice 1");
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S3-1 -> A31: the Main window");
      Radio (Win_Radio_GSMR, Waiting => 2);
      Check (DMI_Windows.Waiting_Displayed, "Table 49 A31: hour glass");
      Radio (Win_Radio_GSMR);
      Check (Win_Top_Is (DMI_Windows.W_Main), "Table 49 D31 .. -> S10");

      -- S3-4 E5 -> A41 -> D10
      To_S3_1 (Win_GSMR or Win_Both or Win_GSMR_Reg);
      Win_Menu (5);
      Key (1);                                  -- FRMCS, not registered
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S3-4 E5 -> A41 -> D10 (FRMCS alone) -> S10");
      To_S3_1 (Win_GSMR or Win_Both or Win_GSMR_Reg);
      Win_Menu (5);
      Key (2);                                  -- FRMCS+GSM-R
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "Table 49 S3-4 E5 -> A41 -> D10 (both systems) -> S3-1");

      -- A43 -> S5: E3, E2
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg);
      Win_Menu (7);
      Check (Win_Top_Is (DMI_Windows.W_One_Radio)
             and then DMI_Windows.In_Start_Up
             and then not DMI_Windows.Close_Enabled,
             "Table 49 A43 -> S5, [Close] disabled (11.7.2.2)");
      Key (8);
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "Table 49 S5 E3 ('Yes', RBC contact not valid) -> S3-1");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_One_Yes,
             Data => Data_ID or 16#14#);
      Win_Menu (7);
      Key (8);
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S5 E2 ('Yes', RBC contact valid) -> A31");

      -- D7 -> S4 -> A42 -> D9 -> S5 -> E4
      Win_Onboard (Data => 0, SOM => 0);
      Send_Mode_Level (Mode => 1, Level => 5); -- SB, level 2 stored
      Radio (Win_FRMCS_GSMR or Win_Both, Data => 16#04#, SOM => 2);
      Press (385, 240); Press (487, 90);    -- Driver ID 1
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "Table 49 D2 / D3 level 2 -> D7 -> S4: the Main window");
      Radio (Win_FRMCS_GSMR or Win_Both, Waiting => 1);
      Check (DMI_Windows.Waiting_Displayed, "Table 49 S4: hour glass");
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg);
      Check (Win_Top_Is (DMI_Windows.W_One_Radio)
             and then DMI_Windows.In_Start_Up
             and then not DMI_Windows.Close_Enabled,
             "Table 49 S4 -> A42 -> D9 -> S5");
      Step;
      Check_Frame ("win_startup_s5");
      Key (7);
      Enter_Single;
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S5 E4 ('No') -> S10");

      -- D7 -> S4 -> A31: the registration completes, no S5
      Win_Onboard (Data => 0, SOM => 0);
      Radio (Win_FRMCS_GSMR or Win_Both, Data => 16#04#, SOM => 2);
      Press (385, 240); Press (487, 90);
      Radio (Win_FRMCS_GSMR or Win_Both, Waiting => 1);
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_FRMCS_Reg,
             Waiting => 2);
      Radio (Win_FRMCS_GSMR or Win_Both or Win_GSMR_Reg or Win_FRMCS_Reg);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.In_Start_Up,
             "Table 49 S4 -> A31 -> S10: no S5 once registered");
      Drain_Outbox;
   end Scenario_Win_Start_Up_Radio;

   ---------------------------------------------------------------------
   -- The simulator answers the radio data (sim/evc_mock.adb): the list
   -- of GSM-R networks, the registration and a session with its RBC
   ---------------------------------------------------------------------

   procedure Scenario_Win_Simulator is
      use type EVC_Mock.Mode_T;

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

      procedure Sim_Step is
      begin
         EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
         DMI_Core.Tick (100);
         Pump_To_EVC;
         Drain_Sounds;
      end Sim_Step;

      procedure Touch (X, Y : Natural; Hold : Natural := 0) is
      begin
         EVC_Mock.Step (0.05, Emit'Unrestricted_Access);
         Pointer_Down (X, Y);
         for I in 1 .. Hold loop
            DMI_Core.Tick (50);
         end loop;
         Pointer_Up (X, Y);
         DMI_Core.Tick (50);
         Pump_To_EVC;
         Drain_Sounds;
      end Touch;

      procedure Run (Steps : Natural) is
      begin
         for I in 1 .. Steps loop
            Sim_Step;
         end loop;
      end Run;
   begin
      Reset;
      EVC_Mock.Reset;
      External_EVC;
      Run (3);
      Touch (385, 240); Touch (487, 90);       -- Driver ID 1
      Run (2);
      Touch (Key_X (2), Key_Y (2)); Touch (487, 90);  -- level 2
      Run (2);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then DMI_Windows.In_Start_Up,
             "sim: level 2 in Start Up -> S3-1");

      -- the GSM-R network ID: list, selection, registration
      Touch (Win_Slot_X (6), Win_Slot_Y (6), Hold => 41);
      Run (5);
      Check (DMI_Windows.Radio_Step_Displayed,
             "sim: the on-board acquires the list (S3-2-1)");
      Run (20);
      Check (Win_Top_Is (DMI_Windows.W_GSMR_Network),
             "sim: the list arrives (S3-2-2)");
      Touch (Key_X (1), Key_Y (1)); Touch (487, 90);
      Run (5);
      Check (DMI_Windows.Radio_Step_Displayed,
             "sim: the Mobile Terminal registers (S3-2-3)");
      Run (20);
      Check (Win_Top_Is (DMI_Windows.W_Radio_Data)
             and then not DMI_Windows.Radio_Step_Displayed,
             "sim: registered, back to S3-1");

      -- 'Use short number' -> A31, the session opens
      Touch (Win_Slot_X (2), Win_Slot_Y (2));
      Run (5);
      Check (DMI_Windows.Waiting_Displayed,
             "sim: the on-board contacts the RBC (A31)");
      Run (20);
      Check (Win_Top_Is (DMI_Windows.W_Main)
             and then not DMI_Windows.Waiting_Displayed,
             "sim: the session is open (S10)");

      -- Initiate SM: the RBC authorises it
      Touch (Win_Slot_X (11), Win_Slot_Y (11), Hold => 41);
      Run (5);
      Check (DMI_Windows.Waiting_Displayed, "sim: the RBC is asked for SM");
      Run (20);
      Check (EVC_Mock.Mode = EVC_Mock.SM and then not DMI_Windows.Is_Open,
             "sim: SM authorised -> the default window");
      DMI_Core.Render;
      Check_Frame ("win_sim_sm");

      -- Exit SM -> SB -> Start Up
      Touch (610, 40);
      Touch (Win_Slot_X (12), Win_Slot_Y (12), Hold => 41);
      Run (3);
      Check (EVC_Mock.Mode = EVC_Mock.SB and then DMI_Windows.In_Start_Up,
             "sim: Exit SM -> SB, Start Up engaged");
      External_EVC (False);
   end Scenario_Win_Simulator;

   ---------------------------------------------------------------------
   -- GEN-3, GEN-10, GEN-11: the devices of the DMI unit. The luminance
   -- and the volume take effect in the UI (MSG_SETTINGS) and are kept
   -- over a reset (5.2.2, 5.2.3); the desk keys for the Settings window
   -- (8.6.1.6) and the isolation (5.6.1.1, MSG_DESK_INPUT); the mode IS
   -- (8.2.3.1.2.2)
   ---------------------------------------------------------------------

   -- The scenarios below change the stored luminance and volume; they
   -- leave them as they found them
   HW_Saved_Luminance : General_Parameters.Display_Luminance_T;
   HW_Saved_Volume    : General_Parameters.Loudspeaker_Volume_T;

   procedure HW_Save is
   begin
      HW_Saved_Luminance := General_Parameters.Display_Luminance;
      HW_Saved_Volume := General_Parameters.Loudspeaker_Volume;
   end HW_Save;

   procedure HW_Restore is
   begin
      General_Parameters.Display_Luminance := HW_Saved_Luminance;
      General_Parameters.Loudspeaker_Volume := HW_Saved_Volume;
      General_Parameters.EVC_Link_Timeout_Ms := 0;
   end HW_Restore;

   -- 5.2.2 / 5.2.3: the values the windows propose after a change and
   -- after a reset, and what the UI is told
   procedure Scenario_HW_Settings_Stored is
      use type General_Parameters.Display_Luminance_T;
      use type General_Parameters.Loudspeaker_Volume_T;
   begin
      HW_Save;
      -- 5.2.2.2 / 5.2.3.2: nothing stored yet, the median of the range
      General_Parameters.Display_Luminance := 5;
      General_Parameters.Loudspeaker_Volume := 5;
      Reset;
      -- FS at standstill: Volume and Brightness enabled (Table 36)
      Send_Mode_Level (Mode => 2, Level => 4);
      Win_At_Standstill;
      Step;
      Expect_Settings (1, 5, 5, 0,
                       "MSG_SETTINGS once after Initialise and the start "
                       & "of the EVC link");
      Step;
      Expect_Settings (0, 0, 0, 0, "nothing changed: nothing sent");

      -- the Volume window proposes the stored value; the driver chooses
      -- the lowest level
      Press (610, 240);                        -- F5: Settings
      Win_Menu (2);                            -- Volume
      Check (Win_Top_Is (DMI_Windows.W_Volume), "hw: the Volume window");
      Check (Win_Value = "5", "11.7.1.4: the median volume is proposed");
      Key (1);                                 -- level 0
      Enter_Single;
      Check (General_Parameters.Loudspeaker_Volume = 0,
             "11.7.1.5: the accepted volume is stored");
      Expect_Settings (1, 5, 0, 0, "5.2.3.1: the UI learns the new volume");

      Win_Menu (3);                            -- Brightness
      Check (Win_Top_Is (DMI_Windows.W_Brightness),
             "hw: the Brightness window");
      Check (Win_Value = "5", "11.7.1.4: the median luminance is proposed");
      Key (3);                                 -- level 2
      Enter_Single;
      Check (General_Parameters.Display_Luminance = 2,
             "11.7.1.5: the accepted luminance is stored");
      Expect_Settings (1, 2, 0, 0,
                       "5.2.2.1: the UI learns the new luminance");

      -- revalidation of the same value: nothing new for the UI
      Win_Menu (3);
      Enter_Single;
      Expect_Settings (0, 0, 0, 0, "the same luminance again: not sent");
      Win_Default;

      -- the reset of the DMI (a new mission, a restart of its software):
      -- the values are the DMI unit's and stay (5.2.2.2, 5.2.3.2)
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);
      Win_At_Standstill;
      Step;
      Check (General_Parameters.Display_Luminance = 2
             and then General_Parameters.Loudspeaker_Volume = 0,
             "5.2.2.2 / 5.2.3.2: the stored values survive a reset");
      Expect_Settings (1, 2, 0, 0,
                       "after a restart the UI is told the stored values");
      Press (610, 240);                        -- F5: Settings
      Win_Menu (2);
      Check (Win_Value = "0",
             "11.7.1.4: after the reset the stored volume is proposed");
      Step;
      Check_Frame ("hw_volume_after_reset");
      Win_Close;
      Win_Menu (3);
      Check (Win_Value = "2",
             "11.7.1.4: after the reset the stored luminance is proposed");
      Step;
      Check_Frame ("hw_brightness_after_reset");
      Win_Default;

      -- the EVC link: its return after a loss tells the UI again (a UI
      -- may have (re)connected with it); the loss keeps the values
      -- (the wrapper's EVC keeps quiet, so that the link times out)
      External_EVC;
      General_Parameters.EVC_Link_Timeout_Ms := 1000;
      Send_Mode_Level (Mode => 1, Level => 4);
      Expect_Settings (0, 0, 0, 0, "hw: the link is up, nothing new");
      for I in 1 .. 21 loop
         Step;
      end loop;
      Check (DMI_Core.EVC_Link_Lost, "hw: the EVC link is lost");
      Check (General_Parameters.Display_Luminance = 2
             and then General_Parameters.Loudspeaker_Volume = 0,
             "the link loss keeps the stored values");
      Expect_Settings (0, 0, 0, 0, "the loss itself sends nothing");
      Send_Mode_Level (Mode => 1, Level => 4);
      Check (not DMI_Core.EVC_Link_Lost, "hw: the EVC is back");
      Expect_Settings (1, 2, 0, 0, "the EVC link restarts: told again");
      Send_Mode_Level (Mode => 1, Level => 4);
      Expect_Settings (0, 0, 0, 0, "and not on every EVC message");

      -- the UI message waits in DMI_Core rather than being dropped when
      -- the caller only takes the driver's actions
      General_Parameters.Loudspeaker_Volume := 7;
      Step;                                    -- takes actions only
      Expect_Settings (1, 2, 7, 0, "the change waits for the UI");
      HW_Restore;
      Reset;
      Drain_Outbox;
   end Scenario_HW_Settings_Stored;

   -- 8.6.1.6: the desk key for the Settings window
   procedure Scenario_HW_Desk_Settings is
      use DMI_Protocol;
   begin
      Reset;
      Step;
      -- 8.6.1.7: an up-type button: nothing on the way down
      Send_Desk_Input (DESK_SETTINGS, 1);
      Step;
      Check (not DMI_Windows.Is_Open, "8.6.1.7: nothing while held down");
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "8.6.1.6: the desk key opens the Settings window");
      Check_Frame ("hw_desk_settings");
      Expect_No_Sound ("the desk key plays no click (5.3.2.2.1 b)");

      -- a window is displayed: only it responds (5.3.1.1.5)
      Send_Desk_Input (DESK_SETTINGS, 1);
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Win_Close;
      Check (not DMI_Windows.Is_Open,
             "the key over the Settings window stacks nothing");
      Press (610, 40);                         -- F1: Main
      Send_Desk_Input (DESK_SETTINGS, 1);
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Main),
             "5.3.1.1.5: over the Main window the key is ignored");
      Win_Default;

      -- pressed on the default window, released over another window
      Send_Desk_Input (DESK_SETTINGS, 1);
      Press (610, 140);                        -- F3: Data view
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Data_View),
             "released over the Data view: ignored");
      Win_Default;
      -- pressed over a window, released on the default window
      Press (610, 40);                         -- F1: Main
      Send_Desk_Input (DESK_SETTINGS, 1);
      Win_Default;
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (not DMI_Windows.Is_Open,
             "pressed over the Main window: ignored when released");
      -- up without down
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (not DMI_Windows.Is_Open, "a key up alone does nothing");

      -- a window that cannot be left: Start Up before S10 (11.7.2.2)
      Send_Mode_Level (Mode => 2, Level => 4);
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Check (DMI_Windows.In_Start_Up
             and then Win_Top_Is (DMI_Windows.W_Driver_ID),
             "hw: Start Up with the Driver ID window");
      Send_Desk_Input (DESK_SETTINGS, 1);
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (DMI_Windows.In_Start_Up
             and then Win_Top_Is (DMI_Windows.W_Driver_ID),
             "11.7.2 / 5.3.1.1.5: Start Up is not left for Settings");
      Send_Mode_Level (Mode => 16, Level => 4); -- SL ends Start Up
      Step;
      Check (not DMI_Windows.Is_Open, "hw: the default window again");

      -- the key works in any mode on the default window (8.6.1.4),
      -- also while the EVC link is lost (SF)
      General_Parameters.EVC_Link_Timeout_Ms := 1000;
      Send_Mode_Level (Mode => 2, Level => 4);
      for I in 1 .. 21 loop
         Step;
      end loop;
      Check (DMI_Core.EVC_Link_Lost, "hw: SF, the link is lost");
      Send_Desk_Input (DESK_SETTINGS, 1);
      Send_Desk_Input (DESK_SETTINGS, 0);
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "8.6.1.4: the Settings window in SF too");
      General_Parameters.EVC_Link_Timeout_Ms := 0;
      Reset;

      -- malformed input: the whole message is ignored
      Send_Raw (16#52#, (1 => 1));
      Send_Raw (16#52#, (1 => 1, 2 => 0, 3 => 0));
      Send_Raw (16#52#, (1 .. 0 => 0));
      Step;
      Check (not DMI_Windows.Is_Open, "wrong lengths are ignored");
      Send_Desk_Input (DESK_SETTINGS, 1);
      Send_Raw (16#52#, (1 => 1, 2 => 1, 3 => 7));
      Send_Desk_Input (DESK_SETTINGS, 2);      -- neither down nor up
      Send_Desk_Input (DESK_SETTINGS, 255);
      Step;
      Check (not DMI_Windows.Is_Open,
             "a pressed byte other than 0 / 1 is ignored");
      Send_Desk_Input (DESK_SETTINGS, 0);      -- the real release
      Step;
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "the key stays pressed through ignored messages");
      Win_Default;
      for Input of Byte_Array'(0, 3, 4, 127, 255) loop
         Send_Desk_Input (Input, 1);
         Send_Desk_Input (Input, 0);
      end loop;
      Step;
      Check (not DMI_Windows.Is_Open, "unknown desk inputs are ignored");
      Expect_Actions (20, 0, "and send nothing to the EVC");
      Drain_Sounds;
   end Scenario_HW_Desk_Settings;

   -- 5.6.1.1: the means to isolate the on-board, a delay-type desk key;
   -- 8.2.3.1.2.2: the mode IS is indicated by the isolation device
   procedure Scenario_HW_Isolation is
      use DMI_Protocol;
      use type Supplementary_Driving_Info.Mode_T;

      procedure Hold (Steps : Natural) is
      begin
         Send_Desk_Input (DESK_ISOLATION, 1);
         for I in 1 .. Steps loop
            Step;
         end loop;
         Send_Desk_Input (DESK_ISOLATION, 0);
         Step;
      end Hold;
   begin
      HW_Save;
      General_Parameters.Display_Luminance := 5;
      General_Parameters.Loudspeaker_Volume := 5;
      Reset;
      Send_Mode_Level (Mode => 2, Level => 4);  -- FS, L1
      Send_Speed_State (V_Cur => 80, V_Perm => 120, V_Target => 0,
                        V_Release => 0, V_Sbi => 135, V_Wsl => 125,
                        D_Target => 0, Monitoring => 0, Dial_Range => 1,
                        Vrelease_Exists => False);
      Step;
      Drain_Sounds;
      Expect_Settings (1, 5, 5, 0, "hw: not isolated");

      -- 5.3.2.6.6: released before 2 s, no activation
      Hold (39);                               -- 1.95 s
      Expect_Actions (20, 0, "5.3.2.6.6: less than 2 s: no isolation");
      -- held for 2 s: the activation when the key comes up
      Send_Desk_Input (DESK_ISOLATION, 1);
      for I in 1 .. 45 loop
         Step;
      end loop;
      Expect_Actions (20, 0, "5.3.2.6.6: nothing while still held");
      Send_Desk_Input (DESK_ISOLATION, 0);
      Step;
      Expect_Action (20, 0, "5.6.1.1: the isolation request to the EVC");
      Expect_No_Sound ("the desk key plays no click (5.3.2.2.1 b)");

      -- SUBSET-026 4.7.2: in every mode and whatever window is shown
      Press (610, 240);                        -- F5: Settings
      Hold (40);
      Expect_Action (20, 0, "isolation over the Settings window");
      Check (Win_Top_Is (DMI_Windows.W_Settings),
             "the window is not affected");
      Win_Default;
      -- a key down repeated keeps the timer running
      Send_Desk_Input (DESK_ISOLATION, 1);
      for I in 1 .. 20 loop
         Step;
      end loop;
      Send_Desk_Input (DESK_ISOLATION, 1);
      for I in 1 .. 20 loop
         Step;
      end loop;
      Send_Desk_Input (DESK_ISOLATION, 0);
      Step;
      Expect_Action (20, 0, "a repeated key down does not restart it");
      Send_Mode_Level (Mode => 1, Level => 4);  -- SB: Start Up
      Step;
      Check (DMI_Windows.In_Start_Up, "hw: Start Up");
      Hold (40);
      Expect_Action (20, 0, "isolation during Start Up");
      Send_Mode_Level (Mode => 16, Level => 4); -- SL
      Hold (40);
      Expect_Action (20, 0, "isolation in SL");

      -- the EVC reports IS: B7 shows no symbol (8.2.3.1.2 has none),
      -- the isolation device indicates it (8.2.3.1.2.2)
      Send_Mode_Level (Mode => 17, Level => 4); -- IS
      Step;
      Check (Supplementary_Driving_Info.Mode = Supplementary_Driving_Info.M_IS,
             "hw: the mode IS is taken over");
      Check_Frame ("hw_mode_is");
      Expect_Settings (1, 5, 5, 1,
                       "8.2.3.1.2.2: the isolation device lights up");
      Step;
      Expect_Settings (0, 0, 0, 0, "and stays lit, nothing new");
      -- the isolation key stays available in IS (4.7.2: X in IS)
      Hold (40);
      Expect_Action (20, 0, "the key in IS too");
      -- leaving IS (the special procedure of SUBSET-026 4.4.3.1.3 is
      -- outside the DMI; the EVC reports another mode)
      Send_Mode_Level (Mode => 1, Level => 4);
      Step;
      Expect_Settings (1, 5, 5, 0, "the indication goes out");
      -- the link loss shows SF: no longer IS
      Send_Mode_Level (Mode => 17, Level => 4);
      Step;
      Expect_Settings (1, 5, 5, 1, "hw: IS again");
      General_Parameters.EVC_Link_Timeout_Ms := 1000;
      for I in 1 .. 21 loop
         Step;
      end loop;
      Check (DMI_Core.EVC_Link_Lost, "hw: the link is lost");
      Expect_Settings (1, 5, 5, 0, "SF is shown instead of IS");
      General_Parameters.EVC_Link_Timeout_Ms := 0;

      -- a DMI reset forgets a key held down
      Reset;
      Send_Desk_Input (DESK_ISOLATION, 1);
      for I in 1 .. 41 loop
         Step;
      end loop;
      DMI_Core.Initialise;
      Send_Desk_Input (DESK_ISOLATION, 0);
      Step;
      Expect_Actions (20, 0, "Initialise releases the desk keys");
      -- malformed: the key down of a wrong length is not a key down
      Send_Raw (16#52#, (1 => 2, 2 => 1, 3 => 0));
      for I in 1 .. 41 loop
         Step;
      end loop;
      Send_Desk_Input (DESK_ISOLATION, 0);
      Step;
      Expect_Actions (20, 0, "a key down of a wrong length is ignored");
      Drain_Sounds;
      HW_Restore;
      Reset;
      Drain_Outbox;
   end Scenario_HW_Isolation;

   -- The simulator's on-board takes the isolation request (action 20)
   -- and reports IS; no other request leaves it (SUBSET-026 4.4.3.1.3)
   procedure Scenario_HW_Simulator_Isolation is
      use type EVC_Mock.Mode_T;
      use type Supplementary_Driving_Info.Mode_T;

      procedure Emit (The_Type : DMI_Protocol.Msg_Type_T;
                      Payload  : Ada.Streams.Stream_Element_Array) is
      begin
         DMI_Core.Handle_Message (The_Type, Payload);
      end Emit;
   begin
      Reset;
      EVC_Mock.Reset;
      External_EVC;
      EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
      Check (Supplementary_Driving_Info.Mode = Supplementary_Driving_Info.M_SB,
             "sim: SB");
      EVC_Mock.Handle_Driver_Action (20, 0);
      EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
      Check (EVC_Mock.Mode = EVC_Mock.Isolation
             and then Supplementary_Driving_Info.Mode
                        = Supplementary_Driving_Info.M_IS,
             "sim: action 20 -> IS, reported to the DMI");
      EVC_Mock.Handle_Driver_Action (7, 0);      -- shunting
      EVC_Mock.Handle_Driver_Action (5, 0);      -- start of mission
      EVC_Mock.Step (0.1, Emit'Unrestricted_Access);
      Check (EVC_Mock.Mode = EVC_Mock.Isolation,
             "sim: no transition from IS");
      EVC_Mock.Reset;
      Check (EVC_Mock.Mode = EVC_Mock.SB, "sim: the reset leaves IS");
      External_EVC (False);
      Reset;
      Drain_Outbox;
   end Scenario_HW_Simulator_Isolation;

end DMI_Test_Settings;
