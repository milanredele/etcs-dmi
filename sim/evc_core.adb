--  ETCS DMI test simulator
--  EVC implementation.

pragma Ada_2012;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with EVC_ATO;
with EVC_Supervision;
with EVC_Track; use EVC_Track;
with EVC_Train;
with Interfaces; use Interfaces;

package body EVC_Core is

   -- Supervision model (constant deceleration braking curves)
   A_Brake : constant Float := 0.8;  -- m/s^2 service braking curve

   The_Monitoring : Natural := 0;
   V_Perm_KMH     : Natural := 0;
   V_Target_KMH   : Natural := 0;
   D_Target_M     : Natural := 0;

   -- Supervision status sent to the DMI, and the identity of the most
   -- relevant displayed target (a counter: a new target location is a
   -- new MRDT, DMI 7.4.1.1)
   The_Status     : EVC_Supervision.Status_T := EVC_Supervision.NoS;
   MRDT_At_M      : Natural := 0;
   MRDT_ID        : Unsigned_8 := 0;

   -- Level_T'Pos. Unknown (0) until the driver selects the level in the
   -- start-up dialogue (SUBSET-026 5.4.3.2 S2); the demo track is a level
   -- 1 line with a transition to level 2
   Level_Unknown  : constant := 0;
   Level_Pos      : Natural := Level_Unknown;
   Level_Ack_Sent : Boolean := False;
   Level_Ack_Wait : Boolean := False;

   Mode_Ack_Wait  : Boolean := False; -- unused placeholder for OS etc.

   -- Status of the driver's data stored on-board (SUBSET-026 3.18): the
   -- simulator sets it from MSG_DRIVER_DATA and reports it in
   -- MSG_ONBOARD, which is where the DMI takes the enabling conditions
   -- of Tables 33 to 36 from. Entering SB invalidates them again
   -- (4.10.1.3), here: at Reset, the only way into SB.
   Driver_ID_Valid  : Boolean := False;
   Train_Data_Valid : Boolean := False;
   TRN_Valid        : Boolean := False;

   -- A 'Start' request that has not been answered yet. This simulator
   -- answers within the same call, so it is never reported as pending.
   Start_Pending    : Boolean := False;

   ---------------------------------------------------------------------
   -- Radio data and RBC (SUBSET-026 3.18.4.3, 5.4.3.2 S3/S4; DMI 11.2.5,
   -- Tables 37, 49 and 50). The demo line has a GSM-R network and no
   -- FRMCS network: the on-board has both radio systems installed, its
   -- GSM-R Mobile Terminal registers, its FRMCS never does. So the
   -- Radio Network type FRMCS+GSM-R leads the DMI through A41 back to
   -- the Radio data window with 'Mission with one radio system' on
   -- offer, and GSM-R (the stored type at start) works directly.
   ---------------------------------------------------------------------

   Radio_Type       : Natural := 3;      -- 1 FRMCS, 2 FRMCS+GSM-R, 3 GSM-R
   GSMR_Registered  : Boolean := True;
   One_Radio_Yes    : Boolean := False;
   RBC_Contact_Known : Boolean := False; -- status "valid" or "invalid"
   RBC_Contact_Valid : Boolean := False;
   Session_Open     : Boolean := False;  -- a session with a 2.2+ RBC
   Train_Data_Acked : Boolean := False;
   BMM_Inhibited    : Boolean := False;  -- SUBSET-026 5.22

   --  What the on-board is busy with, reported in MSG_ONBOARD (waiting
   --  and radio_wait) until the timer runs out, then answered
   type Busy_T is (Idle,
                   Opening_Session,     -- waiting 2 (Table 49 A31, 50 S8)
                   Acquiring_Networks,  -- radio_wait 1 (S3-2-1 / S5-2-1)
                   Registering_GSMR,    -- radio_wait 2 (S3-2-3 / S5-2-3)
                   Shunting_Request,    -- waiting 4 (Table 51 S1)
                   SM_Request);         -- waiting 5 (Table 54a S1)
   Busy       : Busy_T := Idle;
   Authorised : Boolean := False;  -- the RBC's answer (MSG_ONBOARD)
   Busy_Timer : Float := 0.0;
   Busy_Time  : constant Float := 2.0;  -- seconds, for the bench to show

   --  The list of GSM-R networks is sent once, when Acquiring_Networks
   --  ends (before radio_wait goes back to 0, dmi_protocol.ads)
   Networks_Due : Boolean := False;

   TAF_Requested  : Boolean := False;
   TAF_Answered   : Boolean := False;

   ---------------------------------------------------------------------
   -- Virtual Balise Covers (SUBSET-026 3.15.9; DMI 11.3.12, 11.3.13).
   -- The on-board keeps them by their set code (DMI 11.3.12.5: NID_VBCMK
   -- in bits 0-5, NID_C in bits 6-15, T_VBC above); the VBC identity is
   -- NID_VBCMK and NID_C (3.15.9.1 a), the low 16 bits. The simulator
   -- stores at most VBC_Capacity of them (its "maximum on-board storage
   -- capacity of VBC set by driver", DMI Table 36 #5), retains them over
   -- a Reset as over No Power (3.15.9.5) and starts with the VBC of DMI
   -- Figure 134, so that 'Remove VBC' is on offer at once. Validity
   -- periods do not elapse here.
   ---------------------------------------------------------------------

   VBC_Capacity : constant := 4;
   VBC_Count    : Natural range 0 .. VBC_Capacity := 1;
   VBC_Codes    : array (1 .. VBC_Capacity) of Natural :=
     (1 => 71_951, others => 0);

   function VBC_Identity (Set_Code : Natural) return Natural is
     (Set_Code mod 65_536);

   --  The operated system version (SUBSET-026 3.17.2), which this
   --  simulator does not negotiate: its line and its RBC are version 3.0
   --  (DMI Figure 135)
   System_Version_X : constant := 3;
   System_Version_Y : constant := 0;

   --  The abbreviation of the National System of level NTC (DMI
   --  8.2.3.2.9), reported with the level when the driver selected NTC
   --  (the demo line itself has no NTC area); PZB, one of the two systems
   --  of the example of LE02a
   National_Name : constant String := "PZB";
   Level_NTC     : constant := 3;  -- Level_T'Pos (NTC)

   -- "Entering FS" (DMI Table 68): the DMI owns the system status
   -- message, this EVC reports the condition of SUBSET-026 4.4.9.1.4 (in
   -- FS, SSP and gradient not known for the whole length of the train)
   -- as its start and its end (MSG_SYSTEM_STATUS)
   Train_Length_M  : constant := 200;
   FS_Entry_Started : Boolean := False;
   FS_Entry_Ended   : Boolean := False;
   FS_Entry_From_M  : Natural := 0;

   Clock_S        : Float := 8.0 * 3600.0; -- 08:00:00 local time

   function Monitoring return Natural is (The_Monitoring);
   function Permitted_Speed return Natural is (V_Perm_KMH);
   function Mode_Ack_Pending return Boolean is (Mode_Ack_Wait);

   function KMH_To_MS (V : Natural) return Float is (Float (V) / 3.6);
   function MS_To_KMH (V : Float) return Natural is
     (Natural (Float'Max (0.0, V) * 3.6));

   -- Permitted speed from the braking curve to (Target_V at Target_D)
   function Curve_Speed (Position : Float;
                         Target_D : Natural;
                         Target_V : Natural) return Float is
      Dist : constant Float := Float (Target_D) - Position;
   begin
      if Dist <= 0.0 then
         return KMH_To_MS (Target_V);
      end if;
      return Sqrt (KMH_To_MS (Target_V) ** 2 + 2.0 * A_Brake * Dist);
   end Curve_Speed;

   ---------------------------------------------------------------------
   -- Message builders
   ---------------------------------------------------------------------

   procedure Send_Speed_State (Emit : Sink_T) is
      Payload : Stream_Element_Array (1 .. Speed_State_Length);
      Offset  : Stream_Element_Offset := Payload'First;
      Flags   : Unsigned_8 := 0;
      V_Rel   : constant Natural :=
        (if The_Monitoring = 2 then Release_Speed else 0);
      V_SBI_KMH     : constant Natural := Natural'Min (V_Perm_KMH + 10, 400);
      V_Warning_KMH : constant Natural := Natural'Min (V_Perm_KMH + 5, 400);
   begin
      if The_Monitoring = 2 then
         Flags := Flags or 1; -- vrelease exists
      end if;
      The_Status := EVC_Supervision.Status
        (Monitoring      => The_Monitoring,
         Speed           => EVC_Train.Speed_KMH,
         V_Perm          => V_Perm_KMH,
         V_Warning       => V_Warning_KMH,
         V_SBI           => V_SBI_KMH,
         V_Release       => V_Rel,
         Brake_Commanded => EVC_Train.Brake_Commanded,
         In_AD           => Mode = AD,
         Previous        => The_Status);
      Put_U16 (Payload, Offset, Unsigned_16 (EVC_Train.Speed_KMH));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Perm_KMH));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Target_KMH));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Rel));
      Put_U16 (Payload, Offset, Unsigned_16 (V_SBI_KMH));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Warning_KMH));
      Put_U32 (Payload, Offset, Unsigned_32 (D_Target_M));
      Put_U8 (Payload, Offset, Unsigned_8 (The_Monitoring));
      Put_U8 (Payload, Offset, 1); -- 180 km/h dial
      Put_U8 (Payload, Offset, Flags);
      Put_U8 (Payload, Offset, Unsigned_8 (The_Status));
      Put_U8 (Payload, Offset, MRDT_ID);
      Emit (MSG_SPEED_STATE, Payload);
   end Send_Speed_State;

   procedure Send_Mode_Level (Emit : Sink_T) is
      --  in level NTC the name of the National System follows the fixed
      --  part (dmi_protocol.ads); otherwise the 9 byte form
      Name_Len : constant Natural :=
        (if Level_Pos = Level_NTC then National_Name'Length else 0);
      Payload : Stream_Element_Array
        (1 .. Mode_Level_Length
                + (if Name_Len > 0
                   then 1 + Stream_Element_Offset (Name_Len) else 0));
      Offset  : Stream_Element_Offset := Payload'First;
      DMI_Mode : constant Unsigned_8 :=
        (case Mode is
            when SB => 1, when SR => 7, when FS => 2, when TR => 11,
            when AD => 3, when SH => 8, when SM => 4,
            when Isolation => 17);
      Ann     : Unsigned_8 := 16#FF#;
      Ann_Ack : Unsigned_8 := 0;
   begin
      if Level_Ack_Wait then
         Ann := 5; -- L2 announced
         Ann_Ack := 1;
      end if;
      Put_U8 (Payload, Offset, DMI_Mode);
      Put_U8 (Payload, Offset, Unsigned_8 (Level_Pos));
      Put_U8 (Payload, Offset, 16#FF#); -- no mode ack in this scenario
      Put_U8 (Payload, Offset, Ann);
      Put_U8 (Payload, Offset, Ann_Ack);
      Put_U8 (Payload, Offset, 0); -- override
      Put_U8 (Payload, Offset,
              (if TAF_Requested and not TAF_Answered then 1 else 0));
      Put_U16 (Payload, Offset, 16#FFFF#); -- no LSSMA
      if Name_Len > 0 then
         Put_U8 (Payload, Offset, Unsigned_8 (Name_Len));
         for C of National_Name loop
            Put_U8 (Payload, Offset, Character'Pos (C));
         end loop;
      end if;
      Emit (MSG_MODE_LEVEL, Payload);
   end Send_Mode_Level;

   procedure Send_Status (Emit : Sink_T) is
      Payload : Stream_Element_Array (1 .. Status_Length);
      Offset  : Stream_Element_Offset := Payload'First;
      Position : constant Natural := Natural (EVC_Train.Position_M);
      Tunnel_State : Unsigned_8 := 0;
      Tunnel_Dist  : Unsigned_32 := 0;
      Seconds : constant Natural := Natural (Clock_S);
   begin
      if Position in Tunnel_Start_M .. Tunnel_End_M then
         Tunnel_State := 1;
      elsif Position >= Tunnel_Announce_M and Position < Tunnel_Start_M then
         Tunnel_State := 2;
         Tunnel_Dist := Unsigned_32 (Tunnel_Start_M - Position);
      end if;
      Put_U8 (Payload, Offset,
              (if EVC_Train.Brake_Commanded then 1 else 0));
      Put_U8 (Payload, Offset, 1); -- radio up
      Put_U8 (Payload, Offset, 0); -- adhesion
      Put_U8 (Payload, Offset, (if BMM_Inhibited then 1 else 0)); -- ST07
      Put_U8 (Payload, Offset, 0); -- reversing
      Put_U8 (Payload, Offset, 0); -- sm direction
      Put_U16 (Payload, Offset, 16#FFFF#); -- no set speed
      Put_U8 (Payload, Offset, 16#FF#); -- no TTI (CSM pre-indication only)
      Put_U8 (Payload, Offset, 14);
      Put_U8 (Payload, Offset, Tunnel_State);
      Put_U32 (Payload, Offset, Tunnel_Dist);
      Put_U32 (Payload, Offset, Unsigned_32 (Position + 42_000));
      Put_U8 (Payload, Offset, Unsigned_8 ((Seconds / 3600) mod 24));
      Put_U8 (Payload, Offset, Unsigned_8 ((Seconds / 60) mod 60));
      Put_U8 (Payload, Offset, Unsigned_8 (Seconds mod 60));
      Emit (MSG_STATUS, Payload);
   end Send_Status;

   --  The on-board state behind the enabling conditions of Tables 33 to
   --  37 and behind the dialogue sequences (see dmi_protocol.ads and
   --  DMI_Conditions). What this simulator does not model is reported
   --  as "not there": no pending emergency stop, no RBC transition
   --  order, no "non leading" or "passive shunting" desk
   --  inputs. Its RBC is a timer (Busy above): a session opens after
   --  Busy_Time once the driver gave the RBC contact information in
   --  level 2, and it answers a request for shunting or for Supervised
   --  Manoeuvre likewise.
   procedure Send_Onboard (Emit : Sink_T) is
      Payload : Stream_Element_Array (1 .. Onboard_Length);
      Offset  : Stream_Element_Offset := Payload'First;
      Data    : Unsigned_8 := 0;
      RBC     : Unsigned_8 := 0;
      Train   : Unsigned_8 := 0;
      Radio   : Unsigned_8;
   begin
      if Driver_ID_Valid then
         Data := Data or 1;
      end if;
      if Train_Data_Valid then
         Data := Data or 2;
      end if;
      if Level_Pos /= Level_Unknown then
         Data := Data or 4;  -- the level is the driver's (5.4.3.2 S2)
      end if;
      if TRN_Valid then
         Data := Data or 8;
      end if;
      if RBC_Contact_Valid then
         Data := Data or 16;
      end if;
      if Session_Open then
         Data := Data or 32;  -- the RBC confirmed the position (A35)
      end if;
      --  safe consist length information from the train interface, the
      --  engine in front (so 'Train data' stays on offer, Table 33 #3)
      Data := Data or 64 or 128;

      if Train_Data_Acked then
         RBC := RBC or 1;
      end if;

      if EVC_Train.Speed_KMH = 0 then
         Train := Train or 1;  -- standstill
      end if;
      --  the simulator has no national value V_NVALLOWOVTRP: 30 km/h
      --  stands in for the speed limit that triggers the "override"
      if EVC_Train.Speed_KMH <= 30 then
         Train := Train or 2;
      end if;
      if BMM_Inhibited then
         Train := Train or 16;
      end if;

      --  radio: the stored type, both systems installed (3), the GSM-R
      --  Mobile Terminal's registration, never FRMCS
      Radio := Unsigned_8 (Radio_Type mod 4) or (3 * 4);
      if GSMR_Registered then
         Radio := Radio or 32;
      end if;
      if One_Radio_Yes then
         Radio := Radio or 64;
      end if;
      if RBC_Contact_Known then
         Radio := Radio or 128;
      end if;

      Put_U8 (Payload, Offset, Data);
      Put_U8 (Payload, Offset, (if Session_Open then 3 else 0));
      Put_U8 (Payload, Offset, RBC);
      Put_U8 (Payload, Offset, Train);
      --  national: adhesion may be modified (NV, bit 1), the VBC store
      --  has room (bit 2), at least one VBC is stored (bit 3)
      Put_U8 (Payload, Offset,
              2 or (if VBC_Count < VBC_Capacity then 4 else 0)
                or (if VBC_Count > 0 then 8 else 0));
      --  Table 49 S0: the cab is active and the mode is SB, and no
      --  session has to end first, so the conditions to initiate a start
      --  of mission are fulfilled as long as the mode is SB
      Put_U8 (Payload, Offset, (if Mode = SB then 2 else 0));
      Put_U8 (Payload, Offset,
              (case Busy is
                  when Opening_Session  => 2,
                  when Shunting_Request => 4,
                  when SM_Request       => 5,
                  when others           => 0));
      Put_U8 (Payload, Offset, (if Start_Pending then 1 else 0));
      Put_U8 (Payload, Offset, Radio);
      Put_U8 (Payload, Offset,
              (case Busy is
                  when Acquiring_Networks => 1,
                  when Registering_GSMR   => 2,
                  when others             => 0));
      Put_U8 (Payload, Offset, (if Authorised then 1 else 0));
      Emit (MSG_ONBOARD, Payload);
   end Send_Onboard;

   --  MSG_VBC_LIST: the VBCs stored on-board, by their set code
   procedure Send_VBC_List (Emit : Sink_T) is
      Payload : Stream_Element_Array
        (1 .. 1 + Stream_Element_Offset (VBC_Count * VBC_Code_Length));
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (VBC_Count));
      for I in 1 .. VBC_Count loop
         Put_U32 (Payload, Offset, Unsigned_32 (VBC_Codes (I)));
      end loop;
      Emit (MSG_VBC_LIST, Payload);
   end Send_VBC_List;

   --  MSG_SYSTEM_VERSION: the operated system version
   procedure Send_System_Version (Emit : Sink_T) is
      Payload : Stream_Element_Array (1 .. System_Version_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, System_Version_X);
      Put_U8 (Payload, Offset, System_Version_Y);
      Emit (MSG_SYSTEM_VERSION, Payload);
   end Send_System_Version;

   --  A VBC entered by the driver (MSG_DRIVER_DATA kind 8): 3.15.9.4, one
   --  with the identity of a stored VBC replaces it; otherwise it is
   --  added while there is room (the DMI offers 'Set VBC' only then)
   procedure Set_VBC (Code : Natural) is
   begin
      for I in 1 .. VBC_Count loop
         if VBC_Identity (VBC_Codes (I)) = VBC_Identity (Code) then
            VBC_Codes (I) := Code;
            return;
         end if;
      end loop;
      if VBC_Count < VBC_Capacity then
         VBC_Count := VBC_Count + 1;
         VBC_Codes (VBC_Count) := Code;
      end if;
   end Set_VBC;

   --  A VBC removed by the driver (kind 9, 3.15.9.5 c): the remove code
   --  has NID_C in bits 0-9 and NID_VBCMK in bits 10-15 (DMI 11.3.13.5);
   --  a code that names no stored VBC changes nothing
   procedure Remove_VBC (Code : Natural) is
      Identity : constant Natural :=
        (Code / 1024) mod 64 + (Code mod 1024) * 64;
   begin
      for I in 1 .. VBC_Count loop
         if VBC_Identity (VBC_Codes (I)) = Identity then
            VBC_Codes (I .. VBC_Count - 1) := VBC_Codes (I + 1 .. VBC_Count);
            VBC_Count := VBC_Count - 1;
            return;
         end if;
      end loop;
   end Remove_VBC;

   --  MSG_RADIO_NETWORKS: the GSM-R networks of Figure 117
   procedure Send_Radio_Networks (Emit : Sink_T) is
      Names   : constant String := "GSMR-AGSMR-BTelecom X";
      Lengths : constant array (1 .. 3) of Natural := (6, 6, 9);
      Payload : Stream_Element_Array (1 .. 1 + 3 + Names'Length);
      Offset  : Stream_Element_Offset := Payload'First;
      From    : Positive := Names'First;
   begin
      Put_U8 (Payload, Offset, Lengths'Length);
      for L of Lengths loop
         Put_U8 (Payload, Offset, Unsigned_8 (L));
         for C of Names (From .. From + L - 1) loop
            Put_U8 (Payload, Offset, Character'Pos (C));
         end loop;
         From := From + L;
      end loop;
      Emit (MSG_RADIO_NETWORKS, Payload);
   end Send_Radio_Networks;

   --  SUBSET-026 4.10.1.3: entering SB the driver's data are to be
   --  revalidated, the level keeps its status
   procedure Enter_SB is
   begin
      Mode := SB;
      Driver_ID_Valid := False;
      Train_Data_Valid := False;
      TRN_Valid := False;
   end Enter_SB;

   --  The answer to what the on-board was busy with
   procedure Busy_Done is
   begin
      case Busy is
         when Opening_Session =>
            Session_Open := True;
            --  3.18.4.3.4: a session opened with the short number or the
            --  last RBC stores the RBC contact information as valid
            RBC_Contact_Valid := True;
            RBC_Contact_Known := True;
            Train_Data_Acked := Train_Data_Valid;
         when Acquiring_Networks =>
            Networks_Due := True;
         when Registering_GSMR =>
            GSMR_Registered := True;
         when Shunting_Request =>
            Mode := SH;  -- 'Shunting Authorised'
            Authorised := True;
         when SM_Request =>
            Mode := SM;  -- 'Supervised Manoeuvre Authorisation'
            Authorised := True;
         when Idle =>
            null;
      end case;
      Busy := Idle;
   end Busy_Done;

   procedure Start_Busy (What : Busy_T) is
   begin
      Busy := What;
      Authorised := False;
      Busy_Timer := Busy_Time;
   end Start_Busy;

   procedure Send_Track_Cond (Emit : Sink_T) is
      Position : constant Natural := Natural (EVC_Train.Position_M);
      Entries  : Stream_Element_Array (1 .. 1 + 8 * 2);
      Offset   : Stream_Element_Offset := Entries'First + 1;
      Count    : Unsigned_8 := 0;
   begin
      for I in Conditions'Range loop
         declare
            C : Condition_T renames Conditions (I);
         begin
            if Position in C.Announce_M .. C.Start_M - 1 then
               Put_U8 (Entries, Offset, Unsigned_8 (I));
               Put_U8 (Entries, Offset, Unsigned_8 (C.Announce_Symbol));
               Count := Count + 1;
            elsif Position in C.Start_M .. C.End_M then
               Put_U8 (Entries, Offset, Unsigned_8 (I));
               Put_U8 (Entries, Offset, Unsigned_8 (C.Active_Symbol));
               Count := Count + 1;
            end if;
         end;
      end loop;
      if Position in LX_From_M .. LX_At_M then
         Put_U8 (Entries, Offset, 100);
         Put_U8 (Entries, Offset, 38); -- LX kind
         Count := Count + 1;
      end if;
      Entries (Entries'First) := Stream_Element (Count);
      Emit (MSG_TRACK_COND,
            Entries (Entries'First .. Offset - 1));
   end Send_Track_Cond;

   procedure Send_Planning (Emit : Sink_T) is
      Position : constant Natural := Natural (EVC_Train.Position_M);

      function Ahead (M : Natural) return Natural is
        (if M > Position then M - Position else 0);

      MA_Left : constant Natural := Ahead (EOA_M);

      Payload : Stream_Element_Array (1 .. 128);
      Offset  : Stream_Element_Offset := Payload'First;

      G_Count_Off : Stream_Element_Offset;
      S_Count_Off : Stream_Element_Offset;
      O_Count_Off : Stream_Element_Offset;
      Count       : Unsigned_8;

      -- indication distance from the braking curve towards the current
      -- most restrictive target
      Ind_Dist : Unsigned_16 := 16#FFFF#;
   begin
      if The_Monitoring = 0 and then MA_Left > 0 then
         -- distance where the curve to the EOA equals the current MRSP
         declare
            V : constant Float := KMH_To_MS (MRSP_At (Position));
            D : constant Float :=
              Float (EOA_M) - (V * V - KMH_To_MS (0) ** 2) / (2.0 * A_Brake);
         begin
            if D > EVC_Train.Position_M then
               Ind_Dist := Unsigned_16 (Natural (D) - Position);
            end if;
         end;
      end if;

      Put_U16 (Payload, Offset, Unsigned_16 (Natural'Min (MA_Left, 65534)));
      Put_U16 (Payload, Offset, Ind_Dist);
      -- DMI 8.5.11: the next advice change of the ATO (FS only)
      Put_U16 (Payload, Offset,
               Unsigned_16 (Natural'Min (EVC_ATO.Advice_Change_M, 65535)));
      Put_U16 (Payload, Offset, Unsigned_16 (MRSP_At (Position)));

      -- gradients ahead
      G_Count_Off := Offset;
      Put_U8 (Payload, Offset, 0);
      Count := 0;
      for Seg of Gradients loop
         if Seg.Start_M + 1 > Position or else Seg.Start_M = 0 then
            declare
               Start : constant Natural :=
                 (if Seg.Start_M > Position then Seg.Start_M - Position else 0);
               Value : constant Integer := Seg.Value;
            begin
               Put_U16 (Payload, Offset, Unsigned_16 (Start));
               Put_U8 (Payload, Offset,
                       (if Value < 0 then Unsigned_8 (256 + Value)
                        else Unsigned_8 (Value)));
               Count := Count + 1;
            end;
         end if;
      end loop;
      Payload (G_Count_Off) := Stream_Element (Count);

      -- MRSP discontinuities ahead + EOA as zero target
      S_Count_Off := Offset;
      Put_U8 (Payload, Offset, 0);
      Count := 0;
      for Seg of MRSP loop
         if Seg.Start_M > Position then
            Put_U16 (Payload, Offset, Unsigned_16 (Seg.Start_M - Position));
            Put_U16 (Payload, Offset, Unsigned_16 (Seg.Speed));
            Count := Count + 1;
         end if;
      end loop;
      if MA_Left > 0 then
         Put_U16 (Payload, Offset, Unsigned_16 (Natural'Min (MA_Left, 65534)));
         Put_U16 (Payload, Offset, 16#8000#); -- 0 km/h, indication target
         Count := Count + 1;
      end if;
      Payload (S_Count_Off) := Stream_Element (Count);

      -- planning orders from the track conditions
      O_Count_Off := Offset;
      Put_U8 (Payload, Offset, 0);
      Count := 0;
      for C of Conditions loop
         if C.Start_M > Position then
            Put_U8 (Payload, Offset, Unsigned_8 (C.PL_Symbol));
            Put_U16 (Payload, Offset, Unsigned_16 (C.Start_M - Position));
            Count := Count + 1;
         end if;
      end loop;
      Payload (O_Count_Off) := Stream_Element (Count);

      Emit (MSG_PLANNING, Payload (Payload'First .. Offset - 1));
   end Send_Planning;

   -- MSG_SYSTEM_STATUS: Number is a catalogue entry (DMI_Protocol.SS_*),
   -- Event 0 start, 1 end, 2 the event that starts the 30 s
   procedure Send_System_Status (Emit   : Sink_T;
                                 Number : Natural;
                                 Event  : Natural) is
      Payload : Stream_Element_Array (1 .. System_Status_Length);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U8 (Payload, Offset, Unsigned_8 (Number));
      Put_U8 (Payload, Offset, Unsigned_8 (Event));
      Emit (MSG_SYSTEM_STATUS, Payload);
   end Send_System_Status;

   ---------------------------------------------------------------------
   -- Visualization messages for the browser (MSG_TRACK_LAYOUT is
   -- resent every couple of seconds so late joining browsers catch up)
   ---------------------------------------------------------------------

   procedure Send_Sim_State (Emit : Sink_T) is
      Payload : Stream_Element_Array (1 .. Sim_State_Length);
      Offset  : Stream_Element_Offset := Payload'First;
      Demand  : constant Integer := EVC_Train.Demand;
   begin
      Put_U32 (Payload, Offset, Unsigned_32 (Natural (EVC_Train.Position_M)));
      Put_U16 (Payload, Offset, Unsigned_16 (EVC_Train.Speed_KMH));
      Put_U8 (Payload, Offset, Unsigned_8 (Mode_T'Pos (Mode)));
      Put_U8 (Payload, Offset, Unsigned_8 (The_Monitoring));
      Put_U8 (Payload, Offset,
              (if Demand < 0 then Unsigned_8 (256 + Demand)
               else Unsigned_8 (Demand)));
      Put_U8 (Payload, Offset,
              (if EVC_Train.Brake_Commanded then 1 else 0));
      Emit (MSG_SIM_STATE, Payload);
   end Send_Sim_State;

   procedure Send_Track_Layout (Emit : Sink_T) is
      Payload : Stream_Element_Array (1 .. 256);
      Offset  : Stream_Element_Offset := Payload'First;
   begin
      Put_U32 (Payload, Offset, Unsigned_32 (EOA_M));
      Put_U8 (Payload, Offset, Unsigned_8 (Release_Speed));

      Put_U8 (Payload, Offset, MRSP'Length);
      for Seg of MRSP loop
         Put_U32 (Payload, Offset, Unsigned_32 (Seg.Start_M));
         Put_U16 (Payload, Offset, Unsigned_16 (Seg.Speed));
      end loop;

      Put_U8 (Payload, Offset, Gradients'Length);
      for Seg of Gradients loop
         Put_U32 (Payload, Offset, Unsigned_32 (Seg.Start_M));
         Put_U8 (Payload, Offset,
                 (if Seg.Value < 0 then Unsigned_8 (256 + Seg.Value)
                  else Unsigned_8 (Seg.Value)));
      end loop;

      Put_U8 (Payload, Offset, Conditions'Length);
      for C of Conditions loop
         Put_U8 (Payload, Offset, Unsigned_8 (C.Announce_Symbol));
         Put_U32 (Payload, Offset, Unsigned_32 (C.Announce_M));
         Put_U32 (Payload, Offset, Unsigned_32 (C.Start_M));
         Put_U32 (Payload, Offset, Unsigned_32 (C.End_M));
      end loop;

      Put_U32 (Payload, Offset, Unsigned_32 (LX_From_M));
      Put_U32 (Payload, Offset, Unsigned_32 (LX_At_M));
      Put_U32 (Payload, Offset, Unsigned_32 (Tunnel_Announce_M));
      Put_U32 (Payload, Offset, Unsigned_32 (Tunnel_Start_M));
      Put_U32 (Payload, Offset, Unsigned_32 (Tunnel_End_M));
      Put_U32 (Payload, Offset, Unsigned_32 (Level_Ann_M));
      Put_U32 (Payload, Offset, Unsigned_32 (Level_Transition_M));
      Put_U32 (Payload, Offset, Unsigned_32 (TAF_M));

      Emit (MSG_TRACK_LAYOUT, Payload (Payload'First .. Offset - 1));
   end Send_Track_Layout;

   Layout_Countdown : Natural := 0;

   ---------------------------------------------------------------------
   -- Supervision update
   ---------------------------------------------------------------------

   procedure Update_Supervision is
      Position : constant Float := EVC_Train.Position_M;
      Pos_N    : constant Natural := Natural (Position);
      MRSP_Here : constant Natural := MRSP_At (Pos_N);

      Best_V  : Float := KMH_To_MS (MRSP_Here);
      Best_TV : Natural := MRSP_Here;
      Best_TD : Natural := 0;
      Curve   : Float;
   begin
      -- most restrictive of: MRSP here, curves to MRSP decreases, curve
      -- to the EOA
      for Seg of MRSP loop
         if Seg.Start_M > Pos_N and then Seg.Speed < MRSP_Here then
            Curve := Curve_Speed (Position, Seg.Start_M, Seg.Speed);
            if Curve < Best_V then
               Best_V := Curve;
               Best_TV := Seg.Speed;
               Best_TD := Seg.Start_M;
            end if;
         end if;
      end loop;
      Curve := Curve_Speed (Position, EOA_M, 0);
      if Curve < Best_V then
         Best_V := Curve;
         Best_TV := 0;
         Best_TD := EOA_M;
      end if;

      V_Perm_KMH := Natural'Min (MS_To_KMH (Best_V), MRSP_Here);
      V_Target_KMH := Best_TV;
      if Best_TD /= MRDT_At_M then
         MRDT_At_M := Best_TD;
         MRDT_ID := MRDT_ID + 1;
      end if;
      D_Target_M := (if Best_TD > Pos_N then Best_TD - Pos_N else 0);

      -- monitoring type; RSM once the braking curve to the EOA is at or
      -- below the release speed
      if Best_TV = 0
        and then Curve_Speed (Position, EOA_M, 0) <= KMH_To_MS (Release_Speed)
      then
         The_Monitoring := 2;
         V_Perm_KMH := Natural'Min (V_Perm_KMH, Release_Speed);
      elsif V_Perm_KMH < MRSP_Here then
         The_Monitoring := 1; -- TSM: a target constrains the speed
      else
         The_Monitoring := 0;
      end if;

      -- brake intervention above SBI, released at or below permitted
      if EVC_Train.Speed_KMH > V_Perm_KMH + 10 then
         EVC_Train.Brake_Commanded := True;
      elsif EVC_Train.Speed_KMH <= V_Perm_KMH then
         EVC_Train.Brake_Commanded := False;
      end if;
   end Update_Supervision;

   ----------
   -- Step --
   ----------

   procedure Step (Dt_S : Float; Emit : Sink_T) is
      Position : Natural;
      -- the events of this cycle, sent after the mode
      FS_Entry_Start : Boolean := False;
      FS_Entry_End   : Boolean := False;
   begin
      Clock_S := Clock_S + Dt_S;
      -- SUBSET-026 4.4.16.3.2: in AD the ERTMS/ATO on-board acts on the
      -- traction and the brakes instead of the driver
      if Mode = AD then
         EVC_Train.Demand := EVC_ATO.Demand;
      end if;
      EVC_Train.Step (Dt_S);
      Position := Natural (EVC_Train.Position_M);
      EVC_ATO.Update (Dt_S);

      if Busy /= Idle then
         Busy_Timer := Busy_Timer - Dt_S;
         if Busy_Timer <= 0.0 then
            Busy_Done;
         end if;
      end if;
      if Networks_Due then
         Send_Radio_Networks (Emit);
         Networks_Due := False;
      end if;

      if Mode in FS | AD then
         Update_Supervision;
      else
         --  SR: 40 km/h; SH and SM: 30 km/h, standing in for the
         --  national values V_NVSHUNT and the SM ceiling speed
         V_Perm_KMH := (case Mode is
                           when SR      => 40,
                           when SH | SM => 30,
                           when others  => 0);
         V_Target_KMH := 0;
         D_Target_M := 0;
         The_Monitoring := 0;
      end if;

      -- level transition announcement and execution
      if Mode in FS | AD then
         if Position >= Level_Ann_M and then Position < Level_Transition_M
           and then not Level_Ack_Sent
         then
            Level_Ack_Wait := True;
            Level_Ack_Sent := True;
         end if;
         if Position >= Level_Transition_M then
            Level_Pos := 5; -- L2
            Level_Ack_Wait := False;
         end if;
         if Position >= TAF_M and then not TAF_Answered then
            TAF_Requested := True;
         end if;
         -- SUBSET-026 4.4.9.1.4 / DMI Table 68: "Entering FS" from the
         -- entry in FS until SSP and gradient are known for the whole
         -- length of the train, here: until the train has run its own
         -- length in FS. (The level crossing needs no text: DMI
         -- 8.2.3.8.4 asks for the symbol LX01 only.)
         if not FS_Entry_Started then
            FS_Entry_Started := True;
            FS_Entry_Start := True;
            FS_Entry_From_M := Position;
         elsif not FS_Entry_Ended
           and then Position >= FS_Entry_From_M + Train_Length_M
         then
            FS_Entry_Ended := True;
            FS_Entry_End := True;
         end if;
      end if;

      Send_Speed_State (Emit);
      Send_Mode_Level (Emit);
      if FS_Entry_Start then
         Send_System_Status (Emit, SS_Entering_FS, 0);
      elsif FS_Entry_End then
         Send_System_Status (Emit, SS_Entering_FS, 1);
      end if;
      Send_Onboard (Emit);
      Send_VBC_List (Emit);
      Send_System_Version (Emit);
      Send_Status (Emit);
      Send_Track_Cond (Emit);
      if Mode in FS | AD then
         Send_Planning (Emit);
      end if;
      EVC_ATO.Send (Emit, Clock_S);

      Send_Sim_State (Emit);
      if Layout_Countdown = 0 then
         Send_Track_Layout (Emit);
         Layout_Countdown := 20; -- roughly every 2 s at 10 Hz
      else
         Layout_Countdown := Layout_Countdown - 1;
      end if;
   end Step;

   ---------------------------
   -- Handle_Driver_Action  --
   ---------------------------

   procedure Handle_Driver_Action (Action : Natural;
                                   Arg    : Natural;
                                   ID     : Natural := 0) is
      -- this scenario sends no text message to be acknowledged
      pragma Unreferenced (ID);
   begin
      --  SUBSET-026 4.4.3.1.3: no transition from IS is specified; the
      --  special operating procedure that leaves it is the reset
      if Mode = Isolation then
         return;
      end if;
      case Action is
         when 0 =>      -- TAF answered yes
            TAF_Answered := True;
            TAF_Requested := False;
         when 2 =>      -- acknowledgement; Arg names what was acknowledged
            if Arg = 0 then -- level transition
               Level_Ack_Wait := False;
            end if;
         when 5 =>      -- start mission (SUBSET-026 5.4.3.2 S20)
            -- the DMI offers 'Start' once the driver's data are valid
            -- (DMI Table 33); the level is what this EVC checks itself
            Start_Pending := True;
            if Mode = SB and then Level_Pos /= Level_Unknown then
               Mode := FS; -- simplified: full MA immediately
            end if;
            -- answered within the call, so nothing stays pending: the
            -- mode is the answer, or the request is refused outright
            Start_Pending := False;
         when 11 =>     -- level selected; Arg is Level_T'Pos (L0 .. L2)
            if Mode = SB and then Arg in 2 .. 5 then
               Level_Pos := Arg;
            end if;
         when 13 =>     -- ATO engage (1) / disengage (0), DMI 8.5.2
            EVC_ATO.Engage_Request (Arg);
         when 14 =>     -- skip stopping point request / revoke, 8.5.8
            EVC_ATO.Skip_Request (Arg);
         when 15 =>     -- ATO selector position, DMI 11.3.14
            EVC_ATO.Set_Selector (Arg);
         when 16 =>     -- a Main window button ended a system status
            null;       -- message; this simulator starts none of those
         when 7 =>      -- request for shunting (SUBSET-026 5.6)
            if EVC_Train.Speed_KMH = 0 and then Mode /= SH then
               if Level_Pos = 5 then
                  if Session_Open then
                     Start_Busy (Shunting_Request);  -- asks the RBC
                  end if;
               else
                  Mode := SH;  -- level 0 / 1: at once (DMI Table 51 D1)
               end if;
            end if;
         when 8 =>      -- exit shunting: SB (4.6.3 [19])
            if Mode = SH and then EVC_Train.Speed_KMH = 0 then
               Enter_SB;
            end if;
         when 17 =>     -- Supervised Manoeuvre (SUBSET-026 5.21)
            if EVC_Train.Speed_KMH = 0 then
               if Arg = 2 then
                  if Mode = SM then
                     Enter_SB;  -- 'Exit SM'
                  end if;
               elsif Arg <= 1 and then Level_Pos = 5 and then Session_Open
                 and then Mode /= SM
               then
                  Start_Busy (SM_Request);
               end if;
            end if;
         when 18 =>     -- BMM reaction inhibition (SUBSET-026 5.22)
            BMM_Inhibited := Arg = 0;
         when 19 =>     -- maintain shunting: no passive shunting input
            null;
         when 20 =>     -- isolation (SUBSET-026 4.6.3 condition [1]),
                        -- from every mode (4.6.2): the on-board is
                        -- physically isolated from the brakes (4.4.3.1.1)
                        -- and has no more responsibility (4.4.3.3.2)
            Mode := Isolation;
            Busy := Idle;
            Authorised := False;
            Start_Pending := False;
            EVC_Train.Brake_Commanded := False;
            EVC_Train.Demand := 0;
         when others =>
            null;
      end case;
   end Handle_Driver_Action;

   procedure Handle_Driver_Data (Payload : Stream_Element_Array) is
      Offset : Stream_Element_Offset := Payload'First;
      Kind   : Unsigned_8;
   begin
      if Payload'Length < 1 then
         return;
      end if;
      Kind := Get_U8 (Payload, Offset);
      --  The values themselves are not used by this simulator; what
      --  matters is that the on-board now holds them and their status
      --  becomes "valid". The length of each kind is checked so that a
      --  truncated message changes nothing.
      case Kind is
         when 0 =>      -- driver id: len u8, bytes
            if Payload'Length >= 2
              and then Natural (Payload'Length) =
                         2 + Natural (Payload (Payload'First + 1))
            then
               Driver_ID_Valid := True;
            end if;
         when 1 =>      -- train running number: len u8, bytes
            if Payload'Length >= 2
              and then Natural (Payload'Length) =
                         2 + Natural (Payload (Payload'First + 1))
            then
               TRN_Valid := True;
            end if;
         when 2 =>      -- train data: the seven items of DMI Table 40
            if Payload'Length = Driver_Data_Train_Length then
               Train_Data_Valid := True;
               Train_Data_Acked := Session_Open;
            end if;
         when 4 =>      -- GSM-R network ID: len u8, bytes
            if Payload'Length >= 2
              and then Natural (Payload'Length) =
                         2 + Natural (Payload (Payload'First + 1))
            then
               --  3.18.4.3.6.1 b: the session ends in both cases
               Session_Open := False;
               Train_Data_Acked := False;
               if Payload'Length = 2 then
                  --  3.18.4.3.6.2: acquire the list of networks
                  Start_Busy (Acquiring_Networks);
               else
                  --  3.18.4.3.6.3 b: the RBC contact information becomes
                  --  invalid; the Mobile Terminal registers anew
                  RBC_Contact_Valid := False;
                  GSMR_Registered := False;
                  Start_Busy (Registering_GSMR);
               end if;
            end if;
         when 5 =>      -- RBC data (DMI_Protocol.Driver_Data_RBC_Length)
            if Payload'Length = Driver_Data_RBC_Length then
               declare
                  Choice : constant Unsigned_8 :=
                    Unsigned_8 (Payload (Payload'First + 1));
               begin
                  if Choice = 0 then
                     RBC_Contact_Valid := True;
                     RBC_Contact_Known := True;
                  end if;
                  if Choice <= 2 and then Level_Pos = 5 then
                     --  A31 / S8: the on-board contacts the RBC
                     Start_Busy (Opening_Session);
                  end if;
               end;
            end if;
         when 6 =>      -- Radio network type u8
            if Payload'Length = Driver_Data_Byte_Length
              and then Payload (Payload'First + 1) in 1 .. 3
              and then Natural (Payload (Payload'First + 1)) /= Radio_Type
            then
               --  3.18.4.3.6.1 a / 3.18.4.3.6.3 a
               Radio_Type := Natural (Payload (Payload'First + 1));
               Session_Open := False;
               Train_Data_Acked := False;
               RBC_Contact_Valid := False;
            end if;
         when 7 =>      -- Mission with one radio system u8
            if Payload'Length = Driver_Data_Byte_Length then
               One_Radio_Yes := Payload (Payload'First + 1) = 1;
            end if;
         when 8 | 9 =>  -- Set VBC / Remove VBC: code u32
            if Payload'Length = Driver_Data_VBC_Length then
               declare
                  Code : constant Unsigned_32 := Get_U32 (Payload, Offset);
               begin
                  if Code <= VBC_Code_Max and then Mode = SB then
                     if Kind = 8 then
                        Set_VBC (Natural (Code));
                     else
                        Remove_VBC (Natural (Code));
                     end if;
                  end if;
               end;
            end if;
         when others => -- 3 SR data and anything else: no data status
            null;
      end case;
   end Handle_Driver_Data;

   procedure Reset is
   begin
      Mode := SB;
      --  SUBSET-026 4.10.1.3: in SB the driver's data are to be
      --  revalidated; the level keeps its status, which is unknown here
      Driver_ID_Valid := False;
      Train_Data_Valid := False;
      TRN_Valid := False;
      Start_Pending := False;
      Radio_Type := 3;
      GSMR_Registered := True;
      One_Radio_Yes := False;
      RBC_Contact_Known := False;
      RBC_Contact_Valid := False;
      Session_Open := False;
      Train_Data_Acked := False;
      BMM_Inhibited := False;
      Busy := Idle;
      Authorised := False;
      Busy_Timer := 0.0;
      Networks_Due := False;
      The_Monitoring := 0;
      V_Perm_KMH := 0;
      V_Target_KMH := 0;
      D_Target_M := 0;
      The_Status := EVC_Supervision.NoS;
      MRDT_At_M := 0;
      MRDT_ID := 0;
      Level_Pos := Level_Unknown;
      Level_Ack_Sent := False;
      Level_Ack_Wait := False;
      Mode_Ack_Wait := False;
      TAF_Requested := False;
      TAF_Answered := False;
      FS_Entry_Started := False;
      FS_Entry_Ended := False;
      FS_Entry_From_M := 0;
      Clock_S := 8.0 * 3600.0;
      EVC_Train.Reset;
      EVC_ATO.Reset;
   end Reset;

end EVC_Core;
