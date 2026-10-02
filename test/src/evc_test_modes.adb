with EVC_Test_Support;  use EVC_Test_Support;
with ETCS_Track_Packets.P41;
with ETCS_Track_Packets.P46;
with ETCS_Variables;
with EVC_Bytes;
with EVC_Core;
with EVC_DMI_Port;
with EVC_Modes;
with EVC_Ports;
with EVC_Stored_Information;
with Interfaces;
with Sim_Telegrams;

package body EVC_Test_Modes is

   package SI renames EVC_Stored_Information;
   package TP41 renames ETCS_Track_Packets.P41;
   package TP46 renames ETCS_Track_Packets.P46;

   use type EVC_Bytes.Byte_Array;
   use type ETCS_Variables.M_LEVELTR_T;
   use EVC_Modes;
   use EVC_Ports;
   use Interfaces;

   ---------------------------------------------------------------------
   --  Phase E4, modes and levels (e4/modes): the mode machine of 4.6, the
   --  start of mission of 5.4 in levels 0, 1, NTC (and 2 without a
   --  radio), the level transitions of 5.10, the acceptance of 4.8, the
   --  data of 4.10 and A.3.4, the DMI of 4.7. Every scenario drives the
   --  on-board through its ports (the DMI's frames of
   --  common/dmi_protocol.ads, the TIU inputs, the odometer, the
   --  telegrams of Telegram_X) and checks what it outputs.
   ---------------------------------------------------------------------


   --  MSG_MODE_LEVEL of the last Take, payload byte N: 1 mode, 2 level,
   --  3 mode to acknowledge, 4 level announced, 5 its acknowledgement
   --  asked; 16#FFFF# when there is none
   function ML (N : Positive) return Natural is
      I : constant Natural := Find_DMI (EVC_DMI_Port.MSG_MODE_LEVEL);
   begin
      return (if I = 0 then 16#FFFF# else Byte_At (I, 5 + N));
   end ML;

   --  The DMI codes (dmi_protocol.ads, DMI 13.3 Table 60, 8.2.3.2)
   SB_Code : constant := 1;
   FS_Code : constant := 2;
   SR_Code : constant := 7;
   UN_Code : constant := 9;
   TR_Code : constant := 11;
   SN_Code : constant := 12;
   NL_Code : constant := 14;
   SF_Code : constant := 15;
   SL_Code : constant := 16;
   IS_Code : constant := 17;
   No_Code : constant := 16#FF#;
   L0_Code  : constant := 2;
   NTC_Code : constant := 3;
   L1_Code  : constant := 4;
   L2_Code  : constant := 5;

   --  The mode of the last JRU record of event 1 (EVC_Modes.Mode_T'Pos):
   --  the mode in every mode, also in PS, which the DMI does not show
   function JRU_Mode return Natural is (JRU_Last (1, 2));

   --  The DMI's frames to the on-board
   function Action (Code : Natural; Arg : Natural := 0) return Byte_Array is
     (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION,
             (Byte (Code), Byte (Arg mod 256), Byte (Arg / 256))));

   function Ack_Of (Kind : Natural; Id : Natural := 0) return Byte_Array is
     (Frame (EVC_DMI_Port.MSG_DRIVER_ACTION,
             (2, Byte (Kind), 0, Byte (Id mod 256), Byte (Id / 256))));

   function Text_Entry (Kind : Natural; Text : String) return Byte_Array is
      R : Byte_Array (1 .. 2 + Text'Length);
   begin
      R (1) := Byte (Kind);
      R (2) := Byte (Text'Length);
      for I in Text'Range loop
         R (3 + I - Text'First) := Character'Pos (Text (I));
      end loop;
      return Frame (EVC_DMI_Port.MSG_DRIVER_DATA, R);
   end Text_Entry;

   --  MSG_DRIVER_DATA kind 2 (DMI Table 40): length m, brake percentage,
   --  maximum speed km/h, NC_CDTRAIN 130 mm, a passenger train, axle
   --  load A, not airtight, loading gauge G1
   function Train_Entry (Length_M, Percent, Kmh : Natural)
     return Byte_Array
   is (Frame (EVC_DMI_Port.MSG_DRIVER_DATA,
              Byte_Array'(1 => 2)
              & U16 (Unsigned_16 (Length_M)) & U16 (Unsigned_16 (Percent))
              & U16 (Unsigned_16 (Kmh)) & Byte_Array'(1 => 2)
              & U16 (4) & Byte_Array'(0, 0, 1)));

   --  MSG_DRIVER_DATA kind 3: the SR speed limit and distance
   function SR_Entry (Kmh, Distance_M : Natural) return Byte_Array is
     (Frame (EVC_DMI_Port.MSG_DRIVER_DATA,
             Byte_Array'(1 => 3) & U16 (Unsigned_16 (Kmh))
             & U16 (Unsigned_16 (Distance_M))));

   --  A TIU input (EVC_Ports): signal, value
   procedure Signal (S : TIU_Signal_T; On : Boolean) is
   begin
      Input (TIU, (Byte (TIU_Signal_T'Pos (S) + 1), (if On then 1 else 0)));
   end Signal;

   --  Packet 41: an order to the levels L (M_LEVELTR, the first of the
   --  highest priority) at D_M m from the group, or now, with an
   --  acknowledgement area Ack_M m long
   type Level_List is array (Positive range <>) of ETCS_Variables.M_LEVELTR_T;
   Order_Now : constant Integer := -1;

   function Order_41 (L : Level_List; D_M : Integer; Ack_M : Natural := 0)
     return TP41.Packet_T
   is
      P : TP41.Packet_T;
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.D_LEVELTR :=
        (if D_M = Order_Now
         then ETCS_Variables.D_LEVELTR_Now_The_Level_Transition
         else ETCS_Variables.D_LEVELTR_T (D_M));
      P.M_LEVELTR := L (L'First);
      P.Has_NID_NTC := L (L'First) = 1;
      P.NID_NTC := 0;
      P.L_ACKLEVELTR := ETCS_Variables.L_ACKLEVELTR_T (Ack_M);
      P.N_ITER := ETCS_Variables.N_ITER_T (L'Length - 1);
      for I in 1 .. L'Length - 1 loop
         P.M_LEVELTR_List (I) :=
           (M_LEVELTR    => L (L'First + I),
            Has_NID_NTC  => L (L'First + I) = 1,
            NID_NTC      => 0,
            L_ACKLEVELTR => ETCS_Variables.L_ACKLEVELTR_T (Ack_M));
      end loop;
      return P;
   end Order_41;

   --  Packet 46: the conditional order to the levels L
   function Order_46 (L : Level_List) return TP46.Packet_T is
      P : TP46.Packet_T;
   begin
      P.Q_DIR := 1;
      P.M_LEVELTR := L (L'First);
      P.Has_NID_NTC := L (L'First) = 1;
      P.NID_NTC := 0;
      P.N_ITER := ETCS_Variables.N_ITER_T (L'Length - 1);
      for I in 1 .. L'Length - 1 loop
         P.M_LEVELTR_List (I) :=
           (M_LEVELTR   => L (L'First + I),
            Has_NID_NTC => L (L'First + I) = 1,
            NID_NTC     => 0);
      end loop;
      return P;
   end Order_46;

   Lv_0 : constant ETCS_Variables.M_LEVELTR_T :=
     ETCS_Variables.M_LEVELTR_Level_0;
   Lv_1 : constant ETCS_Variables.M_LEVELTR_T :=
     ETCS_Variables.M_LEVELTR_Level_1;
   Lv_2 : constant ETCS_Variables.M_LEVELTR_T :=
     ETCS_Variables.M_LEVELTR_Level_2;

   --  A new track as Start_X, the on-board after its power-up in Stand
   --  By (4.4.7.1.2), cab A active unless Cab is False: no mission data,
   --  no valid level (nothing is kept over No Power)
   procedure Start_E4 (Cab : Boolean := True) is
   begin
      EVC_Core.Initialise;
      Reset_Capture;
      Forget;
      Track_N := 0;
      Train_Cm := 0;
      Odo_D := 0;
      Odo_Over := 0;
      Odo_Under := 0;
      Error_Per_Mille := 0;
      Bound_Per_Mille := 20;
      Speed_Cms := 1000;
      Cold_Byte := 0;
      Cold_Distance := 0;
      Extras := (others => (others => <>));
      Country := (others => 123);
      TC_Length := 0;
      TC_Frames := 0;
      Plan_Length := 0;
      Plan_Frames := 0;
      SI_Seen := (others => (others => 0));
      SI_Detail := (others => (others => 0));
      E4_Seen := (others => (others => 0));
      E4_B3 := (others => (others => 0));
      E4_B4 := (others => (others => 0));
      SS_Seen := (others => 0);
      SS_Ended := (others => 0);
      Last_Brake := 0;
      Last_TIU := 0;
      if Cab then
         Signal (Cab_A_Active, True);
      end if;
      Sample (0);
      Cycle_X;
   end Start_E4;

   --  One standing cycle after an input
   procedure Send (Bytes : Byte_Array) is
   begin
      Input (DMI, Bytes);
      Stand_X (100);
   end Send;

   --  The driver's start of mission at standstill (5.4.3.2), a step a
   --  cycle: the driver ID (S1), the level (S2, its DMI code), the Train
   --  Data (S12), the train running number (S13), 'Start' (S20)
   procedure Driver_SoM (Level_Code : Natural) is
   begin
      Send (Text_Entry (0, "1234"));
      Send (Action (11, Level_Code));
      Send (Train_Entry (200, 135, 160));
      Send (Text_Entry (1, "5678"));
      Send (Action (5));
   end Driver_SoM;

   --  The start of mission to its mode: the proposal acknowledged
   procedure Mission (Level_Code : Natural) is
   begin
      Start_E4;
      Driver_SoM (Level_Code);
      Send (Ack_Of (1));
   end Mission;

   --  A group at At_M m with an SSP of 100 km/h, a flat gradient and an
   --  MA of Lengths (m) from it
   procedure Group_With_MA (NID : Natural; At_M : Integer_64;
                            Lengths : Nat_List) is
   begin
      Add_Group (Group (NID, At_M));
      Carry (Track_N, 0, SSP ((1 => (0, 100, True))));
      Carry (Track_N, 0, Grad ((1 => (0, 0))));
      Carry (Track_N, 1, MA_Of (Lengths));
   end Group_With_MA;

   --  4.6.2 Figure 2 as data: a list of conditions exactly where the
   --  table has a priority, only identifiers of 4.6.3 (not 55, 57, 64,
   --  absent in 4.0.0); the transitions of the modes and levels half
   procedure Scenario_E4_Tables is
      Bad : Natural := 0;
   begin
      for F in Mode_T loop
         for T in Mode_T loop
            declare
               L : constant Condition_List_T := Conditions (F, T);
               Any : Boolean := False;
            begin
               for I in L'Range loop
                  if L (I) /= 0 then
                     Any := True;
                     if L (I) in 55 | 57 | 64 then
                        Bad := Bad + 1;
                     end if;
                  end if;
               end loop;
               if Any /= Transition_Exists (F, T) then
                  Bad := Bad + 1;
               end if;
            end;
         end loop;
      end loop;
      Check (Bad = 0,
             "4.6.2: the conditions of 4.6.3 exactly where Figure 2 has a "
             & "transition, none of 55, 57, 64 (absent in 4.0.0)");
      Check (Transition_Exists (M_SB, M_SR) and then Transition_Exists
               (M_FS, M_UN) and then not Transition_Exists (M_IS, M_SB)
             and then Transitions (M_NP, M_IS) < Transitions (M_NP, M_SB),
             "4.6.2: SB -> SR, FS -> UN; nothing leaves IS (4.4.3.1.3); "
             & "NP -> IS before NP -> SB (4.6.1.4)");
   end Scenario_E4_Tables;

   --  5.4.3.2 in level 1: S0, S1, S2, S12, S13, S20, S24; 4.6.3 [8]; the
   --  mission (5.4.6.1); SR (4.4.11); FS on the first MA (4.6.3 [32]).
   --  The steps in the order of SUBSET-076 5040300_01 (SV30): cab A,
   --  driver ID, level 1, Train Data, train running number, 'Start', SR
   --  acknowledged
   procedure Scenario_E4_SoM_Level_1 is
   begin
      Start_E4;
      Check (ML (1) = SB_Code and then ML (2) = 0 and then ML (3) = No_Code
             and then Onboard_Field (6) = 2 and then Onboard_Field (1) = 0,
             "SoM: Stand By, level unknown, the start of mission engaged "
             & "with the desk open (4.4.7.1.2, 5.4.3.2 S0, D2)");
      Send (Action (5));
      Check (ML (3) = No_Code and then E4_Seen (41, 5) = 1
             and then E4_B3 (41, 5) = 0,
             "SoM: 'Start' without the mission data is refused (5.4.3.2 "
             & "S20, 5.4.5.3 h)");
      Send (Text_Entry (1, "12A"));
      Check (Onboard_Field (1) / 8 mod 2 = 0 and then E4_Seen (41, 4) = 1
             and then E4_B3 (41, 4) = 1,
             "SoM: a train running number of other than 1 to 8 digits is "
             & "refused (A.3.11, 7.5.1.98)");
      Send (Train_Entry (200, 300, 160));
      Check (Onboard_Field (1) / 2 mod 2 = 0 and then E4_Seen (41, 4) = 2
             and then E4_B3 (41, 4) = 2,
             "SoM: Train Data with a brake percentage of 300 are refused "
             & "(A.3.11)");
      Driver_SoM (L1_Code);
      Check (Onboard_Field (1) = 1 + 2 + 4 + 8 and then ML (2) = L1_Code,
             "SoM: the driver ID, the Train Data, level 1, the train "
             & "running number valid (5.4.3.2 S1, S2, S12, S13; MSG_ONBOARD)");
      Check (ML (1) = SB_Code and then ML (3) = SR_Code
             and then E4_Seen (41, 6) = 1
             and then E4_B3 (41, 6) = Mode_T'Pos (M_SR),
             "SoM: 'Start' in level 1 asks to acknowledge SR (5.4.3.2 S20 "
             & "c, S24; 4.7.2 'Ackn of Staff Resp. mode')");
      Send (Ack_Of (1));
      Check (ML (1) = SR_Code and then ML (3) = No_Code
             and then Onboard_Field (6) = 0
             and then E4_Seen (41, 9) = 1
             and then E4_B3 (41, 9) = Mode_T'Pos (M_SR)
             and then JRU_Mode = Mode_T'Pos (M_SR),
             "SoM: SR acknowledged, the mission starts in SR (4.6.3 [8], "
             & "5.4.6.1), the start of mission ends (5.4.3.2.1)");
      --  the supervision runs before the mode machine (doc/EVC-PLAN.md
      --  §2): the ceiling of the new mode from the next cycle on
      Stand_X (100);
      Check (Speed_Frame.V_Perm = 40,
             "SR: the SR mode speed limit is V_NVSTFF, 40 km/h (4.4.11.1.3 "
             & "a, 4.4.11.1.6.2), got" & Img (Speed_Frame.V_Perm));
      Group_With_MA (10, 100, (500, 400));
      Run_X (11_000);
      Stand_X (100);
      Check (ML (1) = FS_Code and then Plan_Frames > 0
             and then Speed_Frame.V_Perm = 100,
             "FS at the MA of level 1 with its SSP and gradients (4.6.3 "
             & "[32], 4.4.9.1.1), the planning shown (4.7.2)");
      Check (E4_Seen (41, 10) = 0 and then Last_TIU / 256 mod 2 = 0,
             "SR -> FS ends no mission (5.5.2)");
      Check (SS_Seen (6) = 1 and then SS_Ended (6) = 0,
             "FS: SSP and gradient from the group on, not for the whole "
             & "train: 'Entering FS' (4.4.9.1.4, MSG_SYSTEM_STATUS 6)");
      Run_X (30_000);
      Check (SS_Ended (6) = 0, "FS: 'Entering FS' while the rear end is "
             & "in rear of the group");
      Run_X (35_000);
      Check (SS_Ended (6) = 1 and then ML (1) = FS_Code,
             "FS: 'Entering FS' ends once SSP and gradient are known for "
             & "the whole length of the train, 200 m (4.4.9.1.4)");
   end Scenario_E4_SoM_Level_1;

   --  5.4.3.2 S22, S23, 5.4.5.3 h (level 2 without a session): the mode
   --  proposed after 'Start' in levels 0, NTC and 2; UN (4.4.10), SN
   --  (4.4.17); 4.6.3 [58], [60]
   procedure Scenario_E4_SoM_Other_Levels is
   begin
      Start_E4;
      Driver_SoM (L0_Code);
      Check (ML (2) = L0_Code and then ML (3) = UN_Code,
             "SoM: 'Start' in level 0 asks to acknowledge UN (5.4.3.2 S23)");
      Send (Ack_Of (1));
      Check (ML (1) = UN_Code and then E4_B3 (41, 9) = Mode_T'Pos (M_UN),
             "SoM: UN acknowledged, the mission starts in UN (4.6.3 [60], "
             & "5.4.6.1)");
      Stand_X (100);
      Check (Speed_Frame.V_Perm = 100,
             "UN: the ceiling speed is the lower of V_NVUNFIT 100 km/h and "
             & "V_MAXTRAIN 160 km/h (4.4.10.1.2), got"
             & Img (Speed_Frame.V_Perm));

      Start_E4;
      Driver_SoM (NTC_Code);
      Check (ML (2) = NTC_Code and then ML (3) = SN_Code,
             "SoM: 'Start' in level NTC asks to acknowledge SN (5.4.3.2 "
             & "S22)");
      Send (Ack_Of (1));
      Check (ML (1) = SN_Code,
             "SoM: SN acknowledged in level NTC (4.6.3 [58])");

      Start_E4;
      Driver_SoM (L2_Code);
      Check (ML (2) = L2_Code and then ML (3) = SR_Code,
             "SoM: 'Start' in level 2 without a session asks to "
             & "acknowledge SR (5.4.5.3 h, 5th bullet; the radio is E5)");

      --  an acknowledgement of another kind is not the mode's
      Send (Ack_Of (0));
      Check (ML (1) = SB_Code and then ML (3) = SR_Code,
             "SoM: an acknowledgement of a level transition does not "
             & "acknowledge the mode proposed");
   end Scenario_E4_SoM_Other_Levels;

   --  4.4.11.1.5: the driver's SR speed limit and distance at standstill;
   --  4.4.11.1.3 b), 4.4.11.1.3.1 b): the distance from the entry; 4.6.3
   --  [42]: beyond it, Trip
   procedure Scenario_E4_SR_Distance is
      TR_At : Integer_64 := -1;
   begin
      Mission (L1_Code);
      Send (SR_Entry (30, 150));
      Stand_X (100);
      Check (Speed_Frame.V_Perm = 30 and then E4_Seen (41, 11) = 1,
             "SR: the driver's SR speed limit 30 km/h applies (4.4.11.1.5, "
             & "4.4.11.1.6.3), got" & Img (Speed_Frame.V_Perm));
      Speed_Cms := 500;
      while Train_Cm < 30_000 and then TR_At < 0 loop
         Step_X (500);
         if ML (1) = TR_Code then
            TR_At := Train_Cm;
         end if;
      end loop;
      Check (TR_At > 15_000 and then TR_At <= 16_000,
             "SR: the estimated front end beyond the SR distance of 150 m "
             & "trips the train (4.6.3 [42]) at"
             & Integer_64'Image (TR_At) & " cm");

      --  the entry is refused while moving or out of SR
      Mission (L1_Code);
      Speed_Cms := 500;
      Feed_X (500);
      Input (DMI, SR_Entry (25, 100));
      Sample (1);
      Cycle_X;
      Check (E4_Seen (41, 4) = 1 and then E4_B3 (41, 4) = 3
             and then Speed_Frame.V_Perm = 40,
             "SR: the SR data entered while moving are refused "
             & "(4.4.11.1.5: only at standstill)");
   end Scenario_E4_SR_Distance;

   --  5.10: an announcement to level 0 with its acknowledgement area
   --  (5.10.1.3, 5.10.4.1 a), the transition at the location (5.10.1.5)
   --  with FS -> UN (4.6.3 [21]) and its deletions (4.10), the service
   --  brake after T_ACK (5.10.4.2) released by the acknowledgement; then
   --  an immediate order back to level 1 with an MA in the same message
   --  (4.8.1.3, 4.6.3 [25])
   procedure Scenario_E4_Level_Transition_0 is
      Asked_At, Switched_At : Integer_64 := -1;
   begin
      Mission (L1_Code);
      Group_With_MA (10, 100, (900, 400));
      Add_Group (Group (20, 300));
      Carry (2, 0, Order_41 ((1 => Lv_0), 400, Ack_M => 150));
      Run_X (31_000);
      Check (ML (1) = FS_Code and then ML (4) = L0_Code
             and then ML (5) = 0 and then E4_Seen (40, 2) = 1,
             "level: the announcement of level 0 is stored and shown "
             & "(5.10.1.3, 4.7.2 'Level transition announcement')");
      while Train_Cm < 80_000 and then Switched_At < 0 loop
         Step_X (500);
         if Asked_At < 0 and then ML (5) = 1 then
            Asked_At := Train_Cm;
         end if;
         if ML (2) = L0_Code then
            Switched_At := Train_Cm;
         end if;
      end loop;
      --  the acknowledgement area starts 150 m in rear of 700 m: the max
      --  safe front end (the antenna 3 m behind the front, 20 per mille
      --  of over-reading) passes 550 m before the antenna does
      Check (Asked_At > 50_000 and then Asked_At < 55_000,
             "level: the acknowledgement asked when the max safe front end "
             & "enters the area (5.10.4.1 a) at"
             & Integer_64'Image (Asked_At) & " cm");
      Check (Switched_At > 69_000 and then Switched_At <= 70_000
             and then ML (1) = UN_Code and then ML (5) = 1
             and then E4_B3 (40, 1) = Level_T'Pos (L0)
             and then E4_B4 (40, 1) = 2,
             "level: level 0 at the transition location, passed by the "
             & "estimated front end (5.10.1.5), FS -> UN (4.6.3 [21]), the "
             & "acknowledgement still asked, at"
             & Integer_64'Image (Switched_At) & " cm");
      Stand_X (100);
      Check (Plan_Frames > 0 and then Find_DMI (EVC_DMI_Port.MSG_PLANNING) = 0
             and then Speed_Frame.V_Perm = 100,
             "level: UN deletes the MA and the track description (4.10), "
             & "no planning, the ceiling V_NVUNFIT (4.4.10.1.2)");
      Stand_X (5_000);
      Check (Last_TIU = 2 + 256 * 32 and then Last_Brake = 3
             and then E4_Seen (40, 6) = 1,
             "level: not acknowledged within T_ACK, the service brake "
             & "(5.10.4.2), MSG_STATUS brake 3: released with the "
             & "acknowledgement");
      Send (Ack_Of (0));
      Check (Last_TIU = 0 and then ML (5) = 0 and then ML (4) = No_Code
             and then Last_Brake = 0 and then E4_Seen (40, 5) = 1,
             "level: the acknowledgement releases the service brake");

      --  back to level 1: an immediate order with an MA, SSP and
      --  gradients in the same message (4.8.1.3: evaluated in level 1)
      Group_With_MA (30, 900, (900, 400));
      Carry (Track_N, 0, Order_41 ((1 => Lv_1), Order_Now));
      Run_X (91_000);
      Check (ML (2) = L1_Code and then ML (1) = FS_Code
             and then ML (5) = 0,
             "level: an immediate order to level 1 with an MA: UN -> FS "
             & "(4.6.3 [25]), no acknowledgement (5.10.4.1 table)");
   end Scenario_E4_Level_Transition_0;

   --  5.10.4.1.3: a new announcement to the level of one the driver
   --  acknowledged keeps the acknowledgement only when its area is
   --  entered upon the receipt; an area ahead asks again (found by
   --  SUBSET-076 5100400_09)
   procedure Scenario_E4_Level_Ack_Again is
      Asked_Again : Boolean := False;
   begin
      Mission (L1_Code);
      Group_With_MA (10, 100, (900, 400));
      Add_Group (Group (20, 300));
      Carry (2, 0, Order_41 ((1 => Lv_0), 600, Ack_M => 300));
      Add_Group (Group (30, 650));
      Carry (3, 0, Order_41 ((1 => Lv_0), 250, Ack_M => 150));
      Add_Group (Group (40, 800));
      Carry (4, 0, Order_41 ((1 => Lv_0), 100, Ack_M => 150));
      Run_X (61_000);
      Check (ML (5) = 1,
             "level: the acknowledgement asked in the area at 600 m "
             & "(5.10.4.1 a)");
      Send (Ack_Of (0));
      Run_X (70_000);
      Check (ML (5) = 0,
             "level: acknowledged; the new announcement at 650 m to the "
             & "same level, its area at 750 m, asks nothing yet");
      while Train_Cm < 79_000 loop
         Step_X (500);
         Asked_Again := Asked_Again or else ML (5) = 1;
      end loop;
      Check (Asked_Again,
             "level: its area entered after the receipt asks the driver "
             & "again (5.10.4.1.3 applies only to an area entered upon the "
             & "receipt)");
      Send (Ack_Of (0));
      Run_X (85_000);
      Check (ML (5) = 0 and then ML (2) = L1_Code,
             "level: the announcement at 800 m, its area already entered, "
             & "asks nothing again (5.10.4.1.3)");
   end Scenario_E4_Level_Ack_Again;

   --  5.10.3.14: the conditional order; 4.6.3 [39]: level 1 without an
   --  MA trips; 5.10.2.4, 5.10.2.7: the level selected from the table
   procedure Scenario_E4_Level_Orders is
   begin
      Mission (L0_Code);
      Add_Group (Group (10, 100));
      Carry (1, 0, Order_46 ((Lv_0, Lv_1)));
      Add_Group (Group (20, 200));
      Carry (2, 0, Order_46 ((1 => Lv_1)));
      Run_X (11_000);
      Check (ML (2) = L0_Code and then ML (1) = UN_Code,
             "level: a conditional order that lists the current level "
             & "changes nothing (5.10.3.14.2)");
      Run_X (21_000);
      Check (ML (2) = L1_Code and then ML (1) = TR_Code
             and then E4_B4 (40, 1) = 3,
             "level: one that does not, as an immediate order "
             & "(5.10.3.14.3); level 1 without an MA: Trip (4.6.3 [39])");

      Mission (L1_Code);
      Group_With_MA (10, 100, (900, 400));
      Add_Group (Group (20, 200));
      Carry (2, 0, Order_41 ((Lv_2, Lv_1), Order_Now));
      Add_Group (Group (30, 300));
      Carry (3, 0, Order_41 ((Lv_2, Lv_0), 300, Ack_M => 100));
      Run_X (21_000);
      Check (ML (2) = L1_Code and then ML (1) = FS_Code,
             "level: of levels 2 and 1 the on-board selects level 1, "
             & "level 2 is not available without a radio (5.10.2.4, "
             & "5.10.2.4.1)");
      Run_X (31_000);
      Check (ML (4) = L0_Code,
             "level: of levels 2 and 0 the one available, level 0, "
             & "announced (5.10.2.4, 5.10.2.6)");
      Stand_X (100);
      Send (Action (11, L1_Code));
      Check (ML (4) = No_Code and then E4_Seen (40, 3) = 1
             and then E4_B4 (40, 3) = 0,
             "level: the driver's level at standstill deletes the order "
             & "(5.10.1.6.1, 5.10.3.15.1)");

      Mission (L1_Code);
      Group_With_MA (10, 100, (900, 400));
      Add_Group (Group (20, 200));
      Carry (2, 0, Order_41 ((1 => Lv_2), Order_Now));
      Run_X (21_000);
      Check (ML (2) = L2_Code,
             "level: none of the levels available, the transition to the "
             & "one of the lowest priority, level 2 (5.10.2.7)");
   end Scenario_E4_Level_Orders;

   --  4.8: the first filter (level), the third (mode); JRU event 32,
   --  change 15, the packet rejected
   procedure Scenario_E4_Acceptance is
      Rejected : Natural;
   begin
      --  in level 0 (UN) the SSP and the gradients of a balise group are
      --  rejected (4.8.3 [1] does not apply: no order to level 1)
      Mission (L0_Code);
      Add_Group (Group (10, 100));
      Carry (1, 0, SSP ((1 => (0, 100, True))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Run_X (11_000);
      Rejected := SI_Seen (SI.Info_Group, SI.Change_Filtered);
      Check (Rejected = 2,
             "acceptance: SSP and gradients of a balise group are rejected "
             & "in level 0 (4.8.3), got" & Img (Rejected));

      --  in SB, without valid Train Data, the MA is rejected (4.8.4 [4])
      Start_E4;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, L1_Code));
      Group_With_MA (10, 100, (900, 400));
      Run_X (11_000);
      Check (SI_Seen (SI.Info_Group, SI.Change_Filtered) = 3
             and then ML (1) = SB_Code,
             "acceptance: in SB without valid Train Data the SSP, the "
             & "gradients and the MA are rejected (4.8.4 [4])");

      --  with valid Train Data and train running number accepted, and SB
      --  -> FS (4.6.3 [10])
      Start_E4;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, L1_Code));
      Send (Train_Entry (200, 135, 160));
      Send (Text_Entry (1, "5678"));
      Group_With_MA (10, 100, (900, 400));
      Run_X (11_000);
      Check (ML (1) = FS_Code
             and then SI_Seen (SI.Info_Group, SI.Change_Filtered) = 0,
             "acceptance: in SB with valid Train Data and train running "
             & "number the MA is accepted (4.8.4 [4], [11]): SB -> FS "
             & "(4.6.3 [10])");

      --  every desk closed: nothing but the levels' and the national
      --  values' with a cab active (4.8.4 [2])
      Start_E4 (Cab => False);
      Add_Group (Group (10, 100));
      Carry (1, 0, Sim_Telegrams.National_Values (123));
      Run_X (11_000);
      Check (SI_Seen (SI.Info_Group, SI.Change_Filtered) = 1
             and then SI_Detail (SI.Info_Group, SI.Change_Filtered) = 3,
             "acceptance: in SB with no desk open the national values are "
             & "rejected (4.8.4 [2])");
   end Scenario_E4_Acceptance;

   --  4.6.3 [14], [3], [2]: Sleeping; [46], [47]: Non Leading with
   --  4.4.15.1.1.3; [1]: isolation from a mission
   procedure Scenario_E4_SL_NL_IS is
   begin
      Start_E4 (Cab => False);
      Check (ML (1) = SB_Code and then Onboard_Field (6) = 0,
             "SL: Stand By, no desk open: no start of mission (5.4.3.2 S0)");
      Signal (Sleeping_Requested, True);
      Stand_X (100);
      Check (ML (1) = SL_Code,
             "SL: sleeping requested at standstill with the desks closed "
             & "(4.6.3 [14], 4.4.6.1.5)");
      Signal (Sleeping_Requested, False);
      Stand_X (100);
      Check (ML (1) = SB_Code,
             "SL: sleeping no longer requested at standstill: SB (4.6.3 "
             & "[3], 4.4.6.1.8)");
      Signal (Sleeping_Requested, True);
      Stand_X (100);
      Signal (Cab_A_Active, True);
      Stand_X (100);
      Check (ML (1) = SB_Code and then Onboard_Field (6) = 2,
             "SL: a desk opened: SB (4.6.3 [2], 4.4.6.1.7), the start of "
             & "mission engaged");

      Start_E4;
      Send (Action (12));
      Check (ML (1) = SB_Code,
             "NL: not without the non-leading input (4.6.3 [46], "
             & "4.4.15.1.1.2)");
      Signal (Non_Leading_Permitted, True);
      Send (Action (12));
      Check (ML (1) = NL_Code and then E4_B3 (41, 9) = Mode_T'Pos (M_NL)
             and then Speed_Frame.V_Perm = 0,
             "NL: selected at standstill with the input: the mission starts "
             & "in NL (4.6.3 [46], 5.4.3.2 S10 E10, 5.4.6.1), no "
             & "supervision (4.4.15.1.2)");
      Signal (Non_Leading_Permitted, False);
      Stand_X (100);
      Check (SS_Seen (35) = 1 and then ML (1) = SB_Code
             and then E4_Seen (41, 10) = 1,
             "NL: the input lost: the driver informed (4.4.15.1.1.3, "
             & "MSG_SYSTEM_STATUS 35), SB at standstill (4.6.3 [47]), the "
             & "end of mission (5.5.2.1.1)");

      Mission (L0_Code);
      Send (Isolate);
      Check (ML (1) = IS_Code and then Last_TIU = 0,
             "IS: the driver isolates the on-board in UN (4.6.3 [1]), no "
             & "brake command (4.4.3.1.1)");
      Signal (Cab_A_Active, False);
      Signal (Sleeping_Requested, True);
      Stand_X (500);
      Check (ML (1) = IS_Code, "IS: nothing leaves Isolation (4.4.3.1.3)");
   end Scenario_E4_SL_NL_IS;

   --  4.6.3 [84] (3.6.8.4): the odometer's safety threshold exceeded:
   --  System Failure, the emergency brake permanently (4.4.5.1.2)
   procedure Scenario_E4_Odometer_Failure is
      SF_At : Integer_64 := -1;
   begin
      Mission (L1_Code);
      Bound_Per_Mille := 350;
      while Train_Cm < 500_000 and then SF_At < 0 loop
         Step_X (1_000);
         if ML (1) = SF_Code then
            SF_At := Train_Cm;
         end if;
      end loop;
      Check (SF_At = 430_000 and then Last_TIU = 1 + 256 * 64
             and then Last_Brake = 1,
             "SF: the safety threshold of the odometer exceeded at 4300 m "
             & "(3.6.8.4, 4.6.3 [84]): the emergency brake (4.4.5.1.2), at"
             & Integer_64'Image (SF_At) & " cm");
      Stand_X (300);
      Check (ML (1) = SF_Code and then Last_TIU = 1 + 256 * 64,
             "SF: permanently");
   end Scenario_E4_Odometer_Failure;

   --  A.3.4.1.2 k): the desk closed during the start of mission; 4.10:
   --  the data of SB
   procedure Scenario_E4_Desk_Closed is
   begin
      Start_E4;
      Send (Text_Entry (0, "1234"));
      Send (Action (11, L1_Code));
      Send (Train_Entry (200, 135, 160));
      Send (Text_Entry (1, "5678"));
      Check (Onboard_Field (1) = 15 and then Onboard_Field (6) = 2,
             "desk: the mission data entered in the start of mission");
      Signal (Cab_A_Active, False);
      Stand_X (100);
      Check (Onboard_Field (6) = 0 and then Onboard_Field (1) = 4,
             "desk: closed during the start of mission: the driver ID, the "
             & "Train Data and the train running number to be revalidated, "
             & "the level kept (A.3.4.1.3 column k, 5.4.3.2.1)");
      Signal (Cab_A_Active, True);
      Send (Action (5));
      Check (Onboard_Field (6) = 2 and then ML (3) = No_Code,
             "desk: opened again, the start of mission engaged, 'Start' "
             & "needs the data revalidated (5.4.3.2 S1)");
      Send (Text_Entry (0, "1234"));
      Send (Train_Entry (200, 135, 160));
      Send (Action (5));
      Check (ML (3) = SR_Code,
             "desk: revalidated, 'Start' proposes SR again (5.4.3.2 S24)");
   end Scenario_E4_Desk_Closed;

   --  4.4.20.1.5 to 4.4.20.1.7, 4.6.3 [26]: "Continue Shunting on desk
   --  closure" (SH itself is the procedures half's: Set_Mode_For_Test)
   procedure Scenario_E4_Continue_Shunting is
   begin
      Start_E4;
      EVC_Core.Set_Mode_For_Test (M_SH, L1);
      Stand_X (100);
      Send (Action (19));
      Check (E4_Seen (41, 12) = 1 and then E4_B3 (41, 12) = 1,
             "PS: 'Continue Shunting on desk closure' in SH (4.4.20.1.5)");
      Signal (Passive_Shunting_Permitted, True);
      Signal (Cab_A_Active, False);
      Stand_X (100);
      Check (JRU_Mode = Mode_T'Pos (M_PS)
             and then Find_DMI (EVC_DMI_Port.MSG_MODE_LEVEL) = 0
             and then E4_Seen (41, 12) = 2,
             "PS: the desk closed with the passive shunting input: PS "
             & "(4.6.3 [26], 4.4.20.1.6), the function ended (4.4.20.1.7); "
             & "no MSG_MODE_LEVEL: the DMI has no PS");
   end Scenario_E4_Continue_Shunting;

end EVC_Test_Modes;
