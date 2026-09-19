--  ETCS DMI
--  Enabling conditions implementation. Each function is the row of its
--  table, written in the order of the specification text; the mode sets
--  and the level values are copied from it literally.

pragma Ada_2012;

package body DMI_Conditions is

   use type SDI.Mode_T;
   use type SDI.Level_T;

   ---------------------------------------------------------------------
   -- Shorthands for the phrases the four tables are built from
   ---------------------------------------------------------------------

   --  "(communication session exists)"
   function Session_Exists return Boolean is
     (Session in Exists | Exists_Above_2_2);

   --  "(no communication session exists)"
   function No_Session_Exists return Boolean is (Session = No_Session);

   --  "(only one communication session with a supervising RBC certified
   --  with a system version X.Y > 2.2 exists)"
   function Session_Above_2_2 return Boolean is
     (Session = Exists_Above_2_2);

   --  "(ERTMS/ETCS level is 2)"
   function Level_Is_2 return Boolean is (SDI.Level = SDI.L2);

   ---------------------------------------------------------------------
   -- Table 33 - Main window (11.2.1.4)
   ---------------------------------------------------------------------

   --  #1 Start. 'Start' is dead while the EVC has not answered the
   --  request: one press is one request (the EVC reports it, the DMI
   --  does not latch it).
   function Main_Start return Boolean is
   begin
      if Start_Pending then
         return False;
      end if;
      return
        (Standstill and then SDI.Mode = SDI.M_SB
         and then Driver_ID_Valid and then Train_Data_Valid
         and then Level_Valid and then TRN_Valid
         and then (SDI.Level in SDI.L0 | SDI.NTC | SDI.L1
                   or else (Level_Is_2 and then Session_Exists
                            and then Train_Data_Acked)
                   or else (Level_Is_2 and then No_Session_Exists)))
        or else
        (Standstill and then SDI.Mode = SDI.M_PT
         and then Train_Data_Valid
         and then (SDI.Level = SDI.L1
                   or else (Level_Is_2 and then Session_Exists
                            and then not Pending_Stop)))
        or else
        (SDI.Mode = SDI.M_SR and then Level_Is_2 and then Session_Exists);
   end Main_Start;

   --  #2 Driver ID
   function Main_Driver_ID return Boolean is
     ((Standstill and then SDI.Mode = SDI.M_SB
       and then Driver_ID_Valid and then Level_Valid)
      or else
      ((NV_Driver_ID_Running or else Standstill)
       and then SDI.Mode in SDI.M_SH | SDI.M_FS | SDI.M_AD | SDI.M_SM
                          | SDI.M_LS | SDI.M_SR | SDI.M_OS | SDI.M_NL
                          | SDI.M_UN | SDI.M_SN));

   --  #3 Train data
   function Main_Train_Data return Boolean is
     (Standstill and then Driver_ID_Valid and then Level_Valid
      and then SDI.Mode in SDI.M_SB | SDI.M_FS | SDI.M_AD | SDI.M_LS
                         | SDI.M_SR | SDI.M_OS | SDI.M_UN | SDI.M_SN
      and then (not Consist_Length or else Consist_Front_Zero));

   --  #5 Level
   function Main_Level return Boolean is
     (Standstill and then Driver_ID_Valid
      and then SDI.Mode in SDI.M_SB | SDI.M_FS | SDI.M_AD | SDI.M_LS
                         | SDI.M_SR | SDI.M_OS | SDI.M_NL | SDI.M_UN
                         | SDI.M_SN);

   --  #6 Train running number
   function Main_TRN return Boolean is
     ((Standstill and then SDI.Mode = SDI.M_SB
       and then Driver_ID_Valid and then Level_Valid)
      or else
      SDI.Mode in SDI.M_FS | SDI.M_AD | SDI.M_SM | SDI.M_LS | SDI.M_SR
                | SDI.M_OS | SDI.M_NL | SDI.M_UN | SDI.M_SN);

   --  #7 Shunting
   function Main_Shunting return Boolean is
     ((Standstill and then Driver_ID_Valid
       and then SDI.Mode in SDI.M_SB | SDI.M_FS | SDI.M_AD | SDI.M_SM
                          | SDI.M_LS | SDI.M_SR | SDI.M_OS | SDI.M_UN
                          | SDI.M_SN
       and then Level_Valid
       and then (SDI.Level in SDI.L0 | SDI.L1 | SDI.NTC
                 or else (Level_Is_2 and then Session_Exists)))
      or else
      (Standstill and then SDI.Mode = SDI.M_PT
       and then (SDI.Level = SDI.L1
                 or else (Level_Is_2 and then Session_Exists
                          and then not Pending_Stop))));

   --  #7 Exit Shunting
   function Main_Exit_Shunting return Boolean is
     (Standstill and then SDI.Mode = SDI.M_SH);

   --  #8 Non-Leading
   function Main_Non_Leading return Boolean is
     (Standstill and then Driver_ID_Valid and then Level_Valid
      and then SDI.Mode in SDI.M_SB | SDI.M_SH | SDI.M_FS | SDI.M_AD
                         | SDI.M_SM | SDI.M_LS | SDI.M_SR | SDI.M_OS
      and then Non_Leading_Signal);

   --  #9 Maintain Shunting
   function Main_Maintain_Shunting return Boolean is
     (SDI.Mode = SDI.M_SH and then Passive_Shunting);

   --  #10 Radio data
   function Main_Radio_Data return Boolean is
     (Standstill and then Driver_ID_Valid and then Level_Valid
      and then SDI.Mode in SDI.M_SB | SDI.M_FS | SDI.M_AD | SDI.M_SM
                         | SDI.M_LS | SDI.M_SR | SDI.M_OS | SDI.M_NL
                         | SDI.M_PT | SDI.M_UN | SDI.M_SN);

   --  #11 Initiate SM
   function Main_Initiate_SM return Boolean is
     ((Standstill and then SDI.Mode = SDI.M_SB and then Driver_ID_Valid
       and then Consist_Length and then Level_Valid and then Level_Is_2
       and then not RBC_Transition and then Session_Above_2_2
       and then Position_Valid)
      or else
      (Standstill and then SDI.Mode = SDI.M_PT and then Train_Data_Valid
       and then Consist_Length and then Level_Is_2
       and then not RBC_Transition and then Session_Above_2_2
       and then Position_Valid and then not Pending_Stop)
      or else
      (Standstill
       and then SDI.Mode in SDI.M_FS | SDI.M_AD | SDI.M_LS | SDI.M_OS
                          | SDI.M_SR
       and then Consist_Length and then Level_Is_2
       and then not RBC_Transition and then Session_Above_2_2));

   --  #11 Continue in SM
   function Main_Continue_SM return Boolean is
     ((Standstill and then SDI.Mode = SDI.M_SM and then Consist_Length
       and then Session_Above_2_2)
      or else
      (Standstill and then SDI.Mode = SDI.M_PT
       and then not Train_Data_Valid and then Consist_Length
       and then Level_Is_2 and then Session_Above_2_2
       and then not Pending_Stop));

   --  #12 Exit SM
   function Main_Exit_SM return Boolean is
     (Standstill and then SDI.Mode = SDI.M_SM);

   ---------------------------------------------------------------------
   -- Table 34 - Override window (11.2.2.4)
   ---------------------------------------------------------------------

   --  #1 EOA
   function Override_EOA return Boolean is
     (Override_Speed_OK
      and then
        (SDI.Mode in SDI.M_FS | SDI.M_AD | SDI.M_LS | SDI.M_SR | SDI.M_OS
                   | SDI.M_UN | SDI.M_SN | SDI.M_SH
         or else
         (SDI.Mode = SDI.M_SB and then Driver_ID_Valid
          and then Train_Data_Valid and then TRN_Valid
          and then Level_Valid and then Level_Is_2)
         or else
         (SDI.Mode = SDI.M_PT and then Train_Data_Valid
          and then TRN_Valid)));

   ---------------------------------------------------------------------
   -- Table 35 - Special window (11.2.3.4)
   ---------------------------------------------------------------------

   --  #1 Adhesion
   function Special_Adhesion return Boolean is
     ((Standstill and then SDI.Mode = SDI.M_SB and then NV_Adhesion
       and then Driver_ID_Valid and then Train_Data_Valid
       and then Level_Valid)
      or else
      (NV_Adhesion
       and then SDI.Mode in SDI.M_FS | SDI.M_AD | SDI.M_SM | SDI.M_LS
                          | SDI.M_SR | SDI.M_OS | SDI.M_UN | SDI.M_SN));

   --  #2 SR speed / distance
   function Special_SR_Data return Boolean is
     (Standstill and then SDI.Mode = SDI.M_SR);

   --  #3 Train integrity
   function Special_Train_Integrity return Boolean is
     ((Standstill
       and then SDI.Mode in SDI.M_SB | SDI.M_FS | SDI.M_AD | SDI.M_LS
                          | SDI.M_SR | SDI.M_OS | SDI.M_UN | SDI.M_PT
                          | SDI.M_SN
       and then Driver_ID_Valid
       and then Train_Data_Valid and then Train_Data_Acked
       and then Session_Exists
       and then Level_Valid and then Position_Valid
       and then Length_Confirmed)
      or else
      (Standstill and then SDI.Mode = SDI.M_SM
       and then Consist_Length_Acked and then Session_Exists
       and then Length_Confirmed)
      or else
      (Standstill and then SDI.Mode = SDI.M_SB and then Driver_ID_Valid
       and then Level_Valid and then not Train_Data_Valid
       and then Consist_Length_Acked and then Session_Exists
       and then Position_Valid and then Length_Confirmed));

   --  #4 BMM reaction inhibition
   function BMM_Rows return Boolean is
     ((Standstill and then SDI.Mode = SDI.M_SB and then Driver_ID_Valid
       and then Level_Valid and then SDI.Level in SDI.L1 | SDI.L2)
      or else
      (Standstill and then SDI.Mode in SDI.M_SR | SDI.M_SH
       and then SDI.Level in SDI.L1 | SDI.L2));

   function Special_BMM_Inhibit return Boolean is
     (BMM_Rows and then not BMM_Inhibit_Active);

   --  #4 Revoke BMM reaction inhibition
   function Special_BMM_Revoke return Boolean is
     (BMM_Rows and then BMM_Inhibit_Active);

   ---------------------------------------------------------------------
   -- Table 36 - Settings window (11.2.4.4)
   ---------------------------------------------------------------------

   --  Rows #1, #2, #3, #4 and #7 share one condition
   function Settings_Rows return Boolean is
     ((Standstill and then SDI.Mode = SDI.M_SB)
      or else
      SDI.Mode in SDI.M_SH | SDI.M_FS | SDI.M_AD | SDI.M_SM | SDI.M_LS
                | SDI.M_SR | SDI.M_OS | SDI.M_NL | SDI.M_UN | SDI.M_TR
                | SDI.M_PT | SDI.M_SN | SDI.M_RV);

   function Settings_Language return Boolean is (Settings_Rows);
   function Settings_Volume return Boolean is (Settings_Rows);
   function Settings_Brightness return Boolean is (Settings_Rows);
   function Settings_System_Version return Boolean is (Settings_Rows);
   function Settings_ATO return Boolean is (Settings_Rows);

   --  #5 Set VBC
   function Settings_Set_VBC return Boolean is
     (Standstill and then SDI.Mode = SDI.M_SB and then VBC_Room);

   --  #6 Remove VBC
   function Settings_Remove_VBC return Boolean is
     (Standstill and then SDI.Mode = SDI.M_SB and then VBC_Stored);

   ---------------------------------------------------------------------
   -- Hour glass ST05 (11.2.1.6)
   ---------------------------------------------------------------------

   --  Time since the waiting state started. It is kept below one hour:
   --  the symbol can skip one position at that wrap, which needs the
   --  on-board to await one answer for an hour.
   Wrap_Ms    : constant := 3_600_000;
   Elapsed_Ms : Natural range 0 .. Wrap_Ms - 1 := 0;

   function Awaiting_Answer return Boolean is
     (Waiting /= Nothing
      or else Start_Of_Mission = Awaiting_Session_End);

   procedure Tick (Dt_Ms : Natural) is
   begin
      if not Awaiting_Answer then
         Elapsed_Ms := 0;
      else
         --  both terms are below Wrap_Ms: no overflow for any Dt_Ms
         Elapsed_Ms := (Elapsed_Ms + Dt_Ms mod Wrap_Ms) mod Wrap_Ms;
      end if;
   end Tick;

   function ST05_X (Area_Width : Natural; Symbol_Width : Natural)
                    return Natural is
      --  cells left of the first position for the symbol to move into
      Room  : constant Natural :=
        (if Area_Width > ST05_First_X + Symbol_Width
         then Area_Width - ST05_First_X - Symbol_Width else 0);
      --  how many positions show the symbol inside the title area
      Count : constant Positive := Room / ST05_Step + 1;
   begin
      return ST05_First_X
        + ST05_Step * ((Elapsed_Ms / ST05_Move_Ms) mod Count);
   end ST05_X;

   ---------------------------------------------------------------------

   procedure Reset is
   begin
      Driver_ID_Valid      := False;
      Train_Data_Valid     := False;
      Level_Valid          := False;
      TRN_Valid            := False;
      RBC_Contact_Valid    := False;
      Position_Valid       := False;
      Consist_Length       := False;
      Consist_Front_Zero   := False;
      Session              := No_Session;
      Train_Data_Acked     := False;
      Pending_Stop         := False;
      RBC_Transition       := False;
      Length_Confirmed     := False;
      Consist_Length_Acked := False;
      Standstill           := False;
      Override_Speed_OK    := False;
      Non_Leading_Signal   := False;
      Passive_Shunting     := False;
      BMM_Inhibit_Active   := False;
      NV_Driver_ID_Running := False;
      NV_Adhesion          := False;
      VBC_Room             := False;
      VBC_Stored           := False;
      Start_Of_Mission     := No_Mission_Start;
      Waiting              := Nothing;
      Start_Pending        := False;
      Elapsed_Ms           := 0;
   end Reset;

end DMI_Conditions;
