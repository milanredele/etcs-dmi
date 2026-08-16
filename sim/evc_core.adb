--  ETCS DMI test simulator
--  EVC implementation.

pragma Ada_2012;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
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

   Level_Pos      : Natural := 4; -- Level_T'Pos: L1
   Level_Ack_Sent : Boolean := False;
   Level_Ack_Wait : Boolean := False;

   Mode_Ack_Wait  : Boolean := False; -- unused placeholder for OS etc.

   TAF_Requested  : Boolean := False;
   TAF_Answered   : Boolean := False;

   Text_FS_Sent   : Boolean := False;
   Text_LX_Sent   : Boolean := False;

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
   begin
      if The_Monitoring = 2 then
         Flags := Flags or 1; -- vrelease exists
      end if;
      if EVC_Train.Brake_Commanded then
         Flags := Flags or 4;
      end if;
      Put_U16 (Payload, Offset, Unsigned_16 (EVC_Train.Speed_KMH));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Perm_KMH));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Target_KMH));
      Put_U16 (Payload, Offset, Unsigned_16 (V_Rel));
      Put_U16 (Payload, Offset, Unsigned_16 (Natural'Min (V_Perm_KMH + 10, 400)));
      Put_U16 (Payload, Offset, Unsigned_16 (Natural'Min (V_Perm_KMH + 5, 400)));
      Put_U32 (Payload, Offset, Unsigned_32 (D_Target_M));
      Put_U8 (Payload, Offset, Unsigned_8 (The_Monitoring));
      Put_U8 (Payload, Offset, 1); -- 180 km/h dial
      Put_U8 (Payload, Offset, Flags);
      Emit (MSG_SPEED_STATE, Payload);
   end Send_Speed_State;

   procedure Send_Mode_Level (Emit : Sink_T) is
      Payload : Stream_Element_Array (1 .. Mode_Level_Length);
      Offset  : Stream_Element_Offset := Payload'First;
      DMI_Mode : constant Unsigned_8 :=
        (case Mode is
            when SB => 1, when SR => 7, when FS => 2, when TR => 11);
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
      Put_U8 (Payload, Offset, 0); -- bmm
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
      Put_U16 (Payload, Offset, 16#FFFF#); -- no ATO advice
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

   procedure Send_Text (Emit : Sink_T;
                        ID   : Natural;
                        Text : String;
                        First_Group : Boolean;
                        Ack : Boolean) is
      Payload : Stream_Element_Array
        (1 .. Text_Header_Length + Text'Length);
      Offset : Stream_Element_Offset := Payload'First;
      Flags  : Unsigned_8 := 8; -- class: system status
      Seconds : constant Natural := Natural (Clock_S);
   begin
      if Ack then
         Flags := Flags or 1;
      end if;
      if First_Group then
         Flags := Flags or 2;
      end if;
      Put_U16 (Payload, Offset, Unsigned_16 (ID));
      Put_U8 (Payload, Offset, Flags);
      Put_U8 (Payload, Offset, Unsigned_8 ((Seconds / 3600) mod 24));
      Put_U8 (Payload, Offset, Unsigned_8 ((Seconds / 60) mod 60));
      Put_U8 (Payload, Offset, Unsigned_8 (Text'Length));
      for C of Text loop
         Put_U8 (Payload, Offset, Character'Pos (C));
      end loop;
      Emit (MSG_TEXT, Payload);
   end Send_Text;

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
   begin
      Clock_S := Clock_S + Dt_S;
      EVC_Train.Step (Dt_S);
      Position := Natural (EVC_Train.Position_M);

      if Mode = FS then
         Update_Supervision;
      else
         V_Perm_KMH := (if Mode = SR then 40 else 0);
         V_Target_KMH := 0;
         D_Target_M := 0;
         The_Monitoring := 0;
      end if;

      -- level transition announcement and execution
      if Mode = FS then
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
         if not Text_FS_Sent then
            Send_Text (Emit, 1, "Entering FS", True, False);
            Text_FS_Sent := True;
         end if;
         if Position >= LX_From_M and then not Text_LX_Sent then
            Send_Text (Emit, 2, "Level crossing not protected", True, False);
            Text_LX_Sent := True;
         end if;
      end if;

      Send_Speed_State (Emit);
      Send_Mode_Level (Emit);
      Send_Status (Emit);
      Send_Track_Cond (Emit);
      if Mode = FS then
         Send_Planning (Emit);
      end if;
   end Step;

   ---------------------------
   -- Handle_Driver_Action  --
   ---------------------------

   procedure Handle_Driver_Action (Action : Natural; Arg : Natural) is
      pragma Unreferenced (Arg);
   begin
      case Action is
         when 0 =>      -- TAF answered yes
            TAF_Answered := True;
            TAF_Requested := False;
         when 2 =>      -- acknowledgement
            Level_Ack_Wait := False;
         when 5 =>      -- start mission
            if Mode = SB then
               Mode := FS; -- simplified: full MA immediately
            end if;
         when others =>
            null;
      end case;
   end Handle_Driver_Action;

   procedure Reset is
   begin
      Mode := SB;
      The_Monitoring := 0;
      V_Perm_KMH := 0;
      V_Target_KMH := 0;
      D_Target_M := 0;
      Level_Pos := 4;
      Level_Ack_Sent := False;
      Level_Ack_Wait := False;
      Mode_Ack_Wait := False;
      TAF_Requested := False;
      TAF_Answered := False;
      Text_FS_Sent := False;
      Text_LX_Sent := False;
      Clock_S := 8.0 * 3600.0;
      EVC_Train.Reset;
   end Reset;

end EVC_Core;
