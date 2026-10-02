with EVC_Test_Support;  use EVC_Test_Support;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with EVC_Brake_Commands;
with EVC_Braking;
with EVC_Bytes;
with EVC_Curves;
with EVC_DMI_Port;
with EVC_Distances;
with EVC_Fixed;
with EVC_Limits;
with EVC_Ports;
with EVC_Profile;
with EVC_SDM;
with EVC_Supervision_Input;
with Interfaces;

package body EVC_Test_Supervision is

   package SIn renames EVC_Supervision_Input;
   package SDM renames EVC_SDM;
   package BC renames EVC_Brake_Commands;

   use type EVC_Distances.Cm_T;
   use type EVC_Bytes.Byte_Array;
   use type SIn.Release_Speed_Kind_T;
   use type SIn.Brake_Inhibition_T;
   use type SIn.Redadh_Use_T;
   use type SIn.Brake_Position_T;
   use type SDM.Monitoring_T;
   use type SDM.Status_T;
   use type EVC_Limits.Margin_Kind_T;
   use Ada.Text_IO;
   use EVC_Ports;
   use Interfaces;

   procedure Scenario_SDM_Precision is
      use EVC_Fixed;
      Far : constant EVC_Distances.Dist_T := -EVC_Distances.Max_Cm + 1;
   begin
      for T in Train_Case loop
         for G in Gradient_Case loop
            declare
               S   : constant SIn.Snapshot_T := Case_Snapshot (T, G);
               M   : EVC_Braking.Model_T;
               P   : EVC_Profile.Profile_T;
               RM  : R_Model_T;
               RP  : R_Profile_T;
               Tag : constant String :=
                 Train_Case'Image (T) & " " & Gradient_Case'Image (G);
               SvL : constant EVC_Distances.Dist_T := 500_000;
               MT  : constant EVC_Distances.Dist_T := 300_000;
               V_T : constant Speed_T := Speed_T (Cms (80.0));
               A_W : constant Speed_T :=
                 Speed_T'Min (V_T + EVC_Limits.Margin (EVC_Limits.EBI, V_T),
                              Max_Speed);
               Curves : constant array (1 .. 4) of EVC_Curves.Curve_T :=
                 ((EVC_Curves.EBD, SvL, 0, 0, False),
                  (EVC_Curves.EBD, MT, A_W * A_W, V_T * V_T, False),
                  (EVC_Curves.SBD, SvL, 0, 0, False),
                  (EVC_Curves.GUI, SvL, 0, 0, False));
               R_Curves : constant array (1 .. 4) of R_Curve :=
                 ((R_EBD, LF (SvL), 0.0, 0.0),
                  (R_EBD, LF (MT), LF (A_W), LF (V_T)),
                  (R_SBD, LF (SvL), 0.0, 0.0),
                  (R_GUI, LF (SvL), 0.0, 0.0));
               Speeds : constant array (1 .. 5) of LF :=
                 (20.0, 50.0, 90.0, 120.0, 150.0);
               Backs  : constant array (1 .. 5) of LF :=
                 (0.0, 10_000.0, 80_000.0, 200_000.0, 400_000.0);
            begin
               EVC_Braking.Build (S, (others => False), False, M);
               EVC_Profile.Build (S, M, Far, P);
               RM := R_Model (S);
               RP := R_Profile (S, RM);
               for K in Curves'Range loop
                  if K /= 4 or else T = Gamma_Train then
                     for V of Speeds loop
                        declare
                           Vc : constant Speed_T := Speed_T (Cms (V));
                           Kx : constant Num :=
                             EVC_Curves.Location_Of (M, P, Curves (K), Vc,
                                                     Far);
                           Rx : constant LF :=
                             R_Location_Of (RM, RP, R_Curves (K), LF (Vc));
                        begin
                           if Rx > -1.0E11 then
                              Compare_Location
                                (Tag & " curve" & Img (K) & " location of"
                                 & Img_LF (V) & " km/h", Kx, Rx,
                                 R_Curves (K).Anchor - Rx);
                           else
                              --  never reached rearwards: behind Stop
                              Check (Kx < Far, Tag & " curve" & Img (K)
                                     & " never reaches" & Img_LF (V)
                                     & " km/h");
                           end if;
                        end;
                     end loop;
                     for B of Backs loop
                        declare
                           X  : constant Num := Curves (K).Anchor - Num (B);
                           Kv : constant Speed_T :=
                             EVC_Curves.Speed_At (M, P, Curves (K), X);
                           Rv : constant LF :=
                             R_Speed_At (RM, RP, R_Curves (K), LF (X));
                        begin
                           Compare_Speed
                             (Tag & " curve" & Img (K) & " speed at"
                              & Img_LF (B / 100.0) & " m before", Kv, Rv);
                        end;
                     end loop;
                     --  beyond the anchor (the MRSP target's EBD falls to
                     --  its foot)
                     declare
                        X  : constant Num := Curves (K).Anchor + 5_000;
                        Kv : constant Speed_T :=
                          EVC_Curves.Speed_At (M, P, Curves (K), X);
                        Rv : constant LF :=
                          R_Speed_At (RM, RP, R_Curves (K), LF (X));
                     begin
                        Compare_Speed (Tag & " curve" & Img (K)
                                       & " speed 50 m beyond", Kv, Rv);
                     end;
                  end if;
               end loop;

               --  the conversion model (A.3.7) at every speed step
               if T /= Gamma_Train then
                  for V in 0 .. 60 loop
                     declare
                        Vc : constant Speed_T := Speed_T (V * 100);
                     begin
                        --  (in 1e-5 m/s²: at most 3 units, 0.03 mm/s²,
                        --  below)
                        Compare_Speed
                          (Tag & " A_brake_safe at" & Img (V * 100),
                           EVC_Braking.Value_At (M.Emergency_Safe (0), Vc),
                           100.0 * R_Safe (RM, LF (Vc), False));
                     end;
                  end loop;
               end if;

               --  3.13.9.3: the limits of the SvL and of the EOA
               for V of Speeds loop
                  for A in 0 .. 1 loop
                     declare
                        Vc    : constant Speed_T := Speed_T (Cms (V));
                        Times : constant EVC_Braking.Times_T :=
                          M.Emergency_Zero;
                        Serv  : constant EVC_Braking.Times_T :=
                          M.Service_Zero;
                        Terms : constant EVC_Limits.Terms_T :=
                          (V        => Vc,
                           V_Delta0 => (if A = 1 then EVC_Limits.F41 (Vc)
                                        else 0),
                           A_Est1   => (if A = 1 then 300 else 0),
                           A_Est2   => (if A = 1 then 300 else 0),
                           T_Be     => Times.Build_Up,
                           T_Bs1    => Serv.Build_Up,
                           T_Bs2    => Serv.Build_Up,
                           T_Ind    => EVC_Fixed.Max
                                         (EVC_Fixed.Div_Ceil
                                            (8 * Serv.Build_Up, 10), 5_000)
                                       + 4_000,
                           TCO      => True,
                           T_Traction_Cut_Off => 1_000);
                        L : constant EVC_Limits.Limits_T :=
                          EVC_Limits.EBD_Limits
                            (M, P, Curves (1), 0, SvL, False, Curves (4),
                             Terms, 0, Far);
                        E : constant EVC_Limits.Limits_T :=
                          EVC_Limits.EOA_Limits
                            (M, P, Curves (3), False, Curves (4), Terms, 0,
                             Far);
                        --  the reference formulas (3.13.9.3.2 to .6)
                        Vr    : constant LF := LF (Vc);
                        Vd0   : constant LF := LF (Terms.V_Delta0);
                        T_Tr  : constant LF :=
                          LF'Max (1.0 - (2.0 + LF (Serv.Build_Up) / 1000.0),
                                  0.0);
                        T_Rem : constant LF :=
                          LF'Max (LF (Times.Build_Up) / 1000.0 - T_Tr, 0.0);
                        A1    : constant LF := LF (Terms.A_Est1) / 10.0;
                        Vd1   : constant LF := A1 * T_Tr;
                        Vd2   : constant LF := A1 * T_Rem;
                        V_Bec : constant LF := Vr + Vd0 + Vd1 + Vd2;
                        D_Bec : constant LF :=
                          (Vr + Vd0 + Vd1 / 2.0) * T_Tr
                          + (Vr + Vd0 + Vd1 + Vd2 / 2.0) * T_Rem;
                        R_EBI : constant LF :=
                          R_Location_Of (RM, RP, R_Curves (1), V_Bec) - D_Bec;
                        R_SBI : constant LF :=
                          R_EBI - Vr * LF (Serv.Build_Up) / 1000.0;
                        R_P   : constant LF :=
                          LF'Min (R_SBI - Vr * 4.0, LF (SvL));
                        R_SBI1 : constant LF :=
                          R_Location_Of (RM, RP, R_Curves (3), Vr)
                          - Vr * LF (Serv.Build_Up) / 1000.0;
                        Span  : constant LF := LF (SvL) - R_EBI;
                     begin
                        if R_EBI > -1.0E11 then
                           Compare_Location (Tag & " EBI at" & Img_LF (V),
                                             L.EBI, R_EBI, Span);
                           Compare_Location (Tag & " SBI2 at" & Img_LF (V),
                                             L.SBI, R_SBI, Span);
                           Compare_Location (Tag & " W at" & Img_LF (V),
                                             L.W, R_SBI - Vr * 2.0, Span);
                           Compare_Location (Tag & " P at" & Img_LF (V),
                                             L.P, R_P, Span);
                           Compare_Location
                             (Tag & " I at" & Img_LF (V), L.I,
                              R_P - Vr * LF (Terms.T_Ind) / 1000.0, Span);
                        end if;
                        if R_SBI1 > -1.0E11 then
                           Compare_Location
                             (Tag & " SBI1 at" & Img_LF (V), E.SBI, R_SBI1,
                              LF (SvL) - R_SBI1);
                        end if;
                        Check (EVC_Limits.Ordered (L)
                               and then EVC_Limits.Ordered (E),
                               Tag & " limits ordered at" & Img_LF (V));
                     end;
                  end loop;
               end loop;
            end;
         end loop;
      end loop;

      --  3.13.9.2: the ceiling margins
      for V in 0 .. 300 loop
         declare
            Vc : constant Speed_T := Speed_T (Cms (LF (V)));
         begin
            for K in EVC_Limits.Margin_Kind_T loop
               Compare_Speed ("margin " & EVC_Limits.Margin_Kind_T'Image (K)
                              & " at" & Img (V) & " km/h",
                              EVC_Limits.Margin (K, Vc),
                              R_Margin (K, LF (Vc)));
            end loop;
            Check (EVC_Limits.Margin (EVC_Limits.Warning, Vc)
                   <= EVC_Limits.Margin (EVC_Limits.SBI, Vc)
                   and then EVC_Limits.Margin (EVC_Limits.SBI, Vc)
                            <= EVC_Limits.Margin (EVC_Limits.EBI, Vc),
                   "dV_warning <= dV_sbi <= dV_ebi at" & Img (V) & " km/h");
         end;
      end loop;

      --  A.3.7.3: V_lim of the table
      for L in 0 .. 250 loop
         declare
            use Ada.Numerics.Long_Elementary_Functions;
            Exact : constant LF :=
              (if L = 0 then 0.0
               else 16.85 * LF (L) ** 0.428 * 250.0 / 9.0);
            Table : constant Speed_T := EVC_Braking.V_Lim (L);
         begin
            Check (LF (Table) <= Exact and then Exact < LF (Table) + 1.0,
                   "V_lim of" & Img (L) & " %");
         end;
      end loop;

      --  A.3.8, A.3.9: the build up times of the conversion model
      for Pos in SIn.Brake_Position_T loop
         for L_M in 0 .. 15 loop
            declare
               Len  : constant EVC_Fixed.Num := EVC_Fixed.Num (L_M * 10_000);
               Lm   : constant LF := LF (L_M) * 100.0;
               function Basic (A, B, C : LF; L : LF) return LF is
                 (A + B * (L / 100.0) + C * (L / 100.0) ** 2);
               EB   : constant LF :=
                 (case Pos is
                     when SIn.Passenger_P =>
                       Basic (2.30, 0.0, 0.17, LF'Max (400.0, Lm)),
                     when SIn.Freight_P =>
                       (if Lm <= 900.0
                        then Basic (2.30, 0.0, 0.17, LF'Max (400.0, Lm))
                        else Basic (-0.40, 1.60, 0.03, Lm)),
                     when SIn.Freight_G =>
                       (if Lm <= 900.0 then Basic (12.00, 0.0, 0.05, Lm)
                        else Basic (-0.40, 1.60, 0.03, Lm)));
               SB   : constant LF :=
                 (case Pos is
                     when SIn.Passenger_P => Basic (3.00, 1.50, 0.10, Lm),
                     when SIn.Freight_P =>
                       (if Lm <= 900.0 then Basic (3.00, 2.77, 0.0, Lm)
                        else Basic (10.50, 0.32, 0.18, Lm)),
                     when SIn.Freight_G =>
                       (if Lm <= 900.0
                        then Basic (3.00, 2.77, 0.0, LF'Max (400.0, Lm))
                        else Basic (10.50, 0.32, 0.18, LF'Max (400.0, Lm))));
               Kto  : constant LF :=
                 (if Pos = SIn.Freight_G then 1.16 else 1.20);
               E0   : constant EVC_Braking.Times_T :=
                 EVC_Braking.Conversion_Emergency (Pos, Len, True);
               ET   : constant EVC_Braking.Times_T :=
                 EVC_Braking.Conversion_Emergency (Pos, Len, False);
               S0   : constant EVC_Braking.Times_T :=
                 EVC_Braking.Conversion_Service (Pos, Len, True);
               ST   : constant EVC_Braking.Times_T :=
                 EVC_Braking.Conversion_Service (Pos, Len, False);
               Tag  : constant String :=
                 SIn.Brake_Position_T'Image (Pos) & Img (L_M * 100) & " m";

               function Near (Kernel : EVC_Fixed.Num; Ref_S : LF)
                 return Boolean
               is (LF (Kernel) >= Ref_S * 1000.0 - 0.001
                   and then LF (Kernel) < Ref_S * 1000.0 + 1.0);
            begin
               Check (Near (E0.Build_Up, EB) and then Near (ET.Build_Up,
                                                            EB * Kto),
                      "A.3.8 " & Tag);
               Check (Near (S0.Build_Up, SB) and then Near (ST.Build_Up,
                                                            SB * Kto),
                      "A.3.9 " & Tag);
               Check (E0.React = (case Pos is when SIn.Passenger_P => 1_420,
                                              when SIn.Freight_P => 2_990,
                                              when SIn.Freight_G => 9_300)
                      and then S0.React
                               = (case Pos is
                                     when SIn.Passenger_P => 1_060,
                                     when SIn.Freight_P => 2_070,
                                     when SIn.Freight_G => 5_700),
                      "A.3.8.6, A.3.9.8 " & Tag);
            end;
         end loop;
      end loop;

      Check (Unsafe = 0, "reference: nothing on the unsafe side");
      Put_Line ("  reference: " & Img (Compared) & " values compared, "
                & "locations behind by at most" & Img_LF (Worst_Loc)
                & " cm (" & Img_LF (Worst_Loc_Rel * 1000.0)
                & " per mille beyond 1 cm), speeds below by at most"
                & Img_LF (Worst_Speed) & " cm/s");
   end Scenario_SDM_Precision;

   ---------------------------------------------------------------------
   --  Scenarios through EVC_Core, the snapshot set directly
   ---------------------------------------------------------------------

   procedure Scenario_SDM_Ceiling is
      S : SIn.Snapshot_T := Base_Snapshot;
      F : Speed_Fields;
   begin
      Place (S, 100_000, Cms (120.0));
      Sup_Start (S);
      Check (Res.Active and then Res.Monitoring = SDM.CSM
             and then Res.Status = SDM.NoS and then not Cmd.EB
             and then not Cmd.SB,
             "CSM: 120 km/h under 140 is Normal, no command");
      F := Speed_Frame;
      Check (F.Found and then F.V_Cur = 120 and then F.V_Perm = 140
             and then F.V_Target = 0 and then F.V_Release = 0
             and then F.V_Wsl = 145 and then F.V_SBI = 147
             and then F.D_Target = 0 and then F.Monitoring = 0
             and then F.Dial = 1 and then F.Flags = 0
             and then F.Status = 0,
             "CSM: MSG_SPEED_STATE 120 / 140, warning 145, SBI 147 (146.85)"
             & ", dial 180 km/h");
      Check (TIU_Out = 16#FFFF#, "CSM: no TIU output without a command");

      Move (100_300, Cms (143.0));
      Sup_Cycle;
      Check (Res.Status = SDM.OvS and then not Cmd.SB,
             "CSM t2: 143 km/h is Overspeed");
      Move (100_600, Cms (146.0));
      Sup_Cycle;
      Check (Res.Status = SDM.WaS and then not Cmd.SB and then not Cmd.TCO,
             "CSM t3: 146 km/h (above 145) is Warning");
      Check (JRU_Count (EVC_Ports.JRU_Supervision) = 1,
             "CSM: the JRU records the change of status");
      Move (100_900, Cms (148.0));
      Sup_Cycle;
      Check (Res.Status = SDM.IntS and then Cmd.SB and then not Cmd.EB,
             "CSM t4: 148 km/h (above 146.85) commands the service brake");
      Check (TIU_Out = 2 + 256 * 1,
             "CSM: TIU output SBC, reason speed and distance monitoring");
      Check (Status_Brake = 1, "CSM: MSG_STATUS shows the brake");
      Check (JRU_Count (EVC_Ports.JRU_Brake_Commands) = 1,
             "CSM: the JRU records the brake command");
      Move (101_200, Cms (151.0));
      Sup_Cycle;
      Check (Res.Status = SDM.IntS and then Cmd.SB and then Cmd.EB,
             "CSM t5: 151 km/h (above 149.75) commands the emergency brake");
      Check (Speed_Frame.Status = 4 and then Speed_Frame.V_SBI = 147,
             "CSM: Intervention on the DMI with the SBI speed");
      Move (101_500, Cms (139.0));
      Sup_Cycle;
      Check (Res.Status = SDM.IntS and then not Cmd.SB and then Cmd.EB,
             "CSM r1: at 139 km/h the service brake is revoked, the "
             & "emergency brake only at standstill (Q_NVEMRRLS = 0)");
      Move (101_600, 0);
      Sup_Cycle;
      Check (Res.Status = SDM.NoS and then not Cmd.EB and then not Cmd.SB,
             "CSM r0: at standstill everything is revoked");
      Check (TIU_Out = 0, "CSM: the TIU output says so once");
      Sup_Cycle;
      Check (TIU_Out = 16#FFFF#, "CSM: then nothing on the TIU");

      --  Q_NVEMRRLS = 1: the emergency brake revoked with the Permitted
      --  speed
      S.National.Q_NVEMRRLS := True;
      Place (S, 100_000, Cms (151.0));
      Sup_Start (S);
      Check (Cmd.EB and then Res.Status = SDM.IntS,
             "CSM, first cycle: 151 km/h gives Intervention at once "
             & "(3.13.10.3.5)");
      Move (100_300, Cms (140.0));
      Sup_Cycle;
      Check (not Cmd.EB and then Res.Status = SDM.NoS,
             "CSM r1: Q_NVEMRRLS = 1 revokes the emergency brake at 140");

      --  no service brake interface: the emergency brake instead
      --  (3.13.10.2.3), revoked like the service brake (3.13.10.2.4)
      S := Base_Snapshot;
      S.Extra.Config.Service_Brake_Command := False;
      Place (S, 100_000, Cms (148.0));
      Sup_Start (S);
      Check (Cmd.EB and then not Cmd.SB and then Res.Status = SDM.IntS,
             "3.13.10.2.3: no service brake, the emergency brake instead");
      Move (100_300, Cms (140.0));
      Sup_Cycle;
      Check (not Cmd.EB and then Res.Status = SDM.NoS,
             "3.13.10.2.4: revoked as the service brake would be");

      --  no ceiling speed, no monitoring (Stand By, nothing stored)
      S := Base_Snapshot;
      S.Supervise := False;
      Place (S, 0, 0);
      Sup_Start (S);
      F := Speed_Frame;
      Check (not Res.Active and then F.Found and then F.V_Perm = 0
             and then F.Status = 0 and then F.Dial = 1,
             "no ceiling speed: nothing supervised, v_perm 0 as the mock");

      --  the dial range from V_MAXTRAIN (DMI 8.2.1.1.3)
      S := Base_Snapshot;
      Place (S, 0, 0);
      S.Train_Data.Max_Speed := Cms (130.0);
      Sup_Start (S);
      Check (Speed_Frame.Dial = 0, "dial 140 for a train of 130 km/h");
      S.Train_Data.Max_Speed := Cms (230.0);
      Sup_Start (S);
      Check (Speed_Frame.Dial = 2, "dial 250 for a train of 230 km/h");
      S.Train_Data.Max_Speed := Cms (240.0);
      Sup_Start (S);
      Check (Speed_Frame.Dial = 3, "dial 400 for a train of 240 km/h "
             & "(the EBI of 255 km/h is beyond 250)");
      S.Train_Data.Max_Speed := Cms (300.0);
      Sup_Start (S);
      Check (Speed_Frame.Dial = 3, "dial 400 for a train of 300 km/h");
   end Scenario_SDM_Ceiling;

   --  3.13.10.4: target speed monitoring to an EOA at constant speed:
   --  Indication, Overspeed, Warning with the traction cut-off,
   --  Intervention with the service brake, in this order (Tables 9, 12);
   --  then the driver brakes and the commands are revoked (Table 11)
   procedure Scenario_SDM_Approach is
      S       : SIn.Snapshot_T := Base_Snapshot;
      X       : Integer_64 := 0;
      V       : SIn.Speed_Cms_T := Cms (120.0);
      Seen    : array (1 .. 16) of SDM.Status_T := (others => SDM.NoS);
      N_Seen  : Natural := 0;
      Last    : SDM.Status_T := SDM.NoS;
      TSM_At  : Integer_64 := -1;
      TCO_At  : Integer_64 := -1;
      SB_At   : Integer_64 := -1;
      Ind_Before : Natural := 0;
      D_Prev  : Natural := Natural'Last;
      D_Falls : Boolean := True;
      Braking : Boolean := False;
   begin
      Give_MA (S, 5_000, 200);
      Place (S, X, V);
      Sup_Start (S);
      for Step in 1 .. 3_000 loop
         exit when V = 0;
         if Braking then
            V := SIn.Speed_Cms_T'Max (Integer (V) - 10, 0);  -- 1 m/s²
         end if;
         X := X + Integer_64 (V) / 10;
         Move (X, V);
         Sup_Cycle;
         if Res.Monitoring = SDM.CSM and then Res.Indication then
            Ind_Before := Ind_Before + 1;
         end if;
         if Res.Monitoring = SDM.TSM and then TSM_At < 0 then
            TSM_At := X;
         end if;
         if Res.Status /= Last then
            if N_Seen < Seen'Last then
               N_Seen := N_Seen + 1;
               Seen (N_Seen) := Res.Status;
            end if;
            Last := Res.Status;
         end if;
         if Cmd.TCO and then TCO_At < 0 then
            TCO_At := X;
         end if;
         if Cmd.SB and then SB_At < 0 then
            SB_At := X;
            Braking := True;
         end if;
         if Res.Monitoring = SDM.TSM then
            if Speed_Frame.D_Target > D_Prev and then not Braking then
               D_Falls := False;
            end if;
            D_Prev := Speed_Frame.D_Target;
         end if;
      end loop;
      Check (TSM_At > 0 and then Ind_Before > 0,
             "approach: CSM with the first Indication location shown, then"
             & " TSM from" & Integer_64'Image (TSM_At / 100) & " m");
      Check (N_Seen >= 4 and then Seen (1) = SDM.IndS
             and then Seen (2) = SDM.OvS and then Seen (3) = SDM.WaS
             and then Seen (4) = SDM.IntS,
             "approach: Indication, Overspeed, Warning, Intervention in "
             & "that order (Table 12)");
      Check (TCO_At > 0 and then SB_At > TCO_At,
             "approach: the traction cut-off at W (" & Integer_64'Image
               (TCO_At / 100) & " m), the service brake at SBI1 ("
             & Integer_64'Image (SB_At / 100) & " m)");
      Check (D_Falls, "approach: the distance to target falls");
      Check (X < 500_000 and then not Cmd.SB and then not Cmd.EB
             and then Res.Status = SDM.IndS,
             "approach: braked to a stop before the EOA at"
             & Integer_64'Image (X / 100) & " m, the commands revoked (r1,"
             & " r3), Indication");
      Check (Speed_Frame.V_Target = 0 and then Speed_Frame.Monitoring = 1,
             "approach: MSG_SPEED_STATE target speed 0 in TSM");
   end Scenario_SDM_Approach;

   --  3.13.9.4, 3.13.10.5: release speed monitoring with a release speed
   --  of 40 km/h: entered at the RSM start, the release speed shown,
   --  Intervention above it (Table 13), revoked at standstill only
   --  (Table 14)
   procedure Scenario_SDM_Release is
      S   : SIn.Snapshot_T := Base_Snapshot;
      X   : Integer_64 := 300_000;
      V   : SIn.Speed_Cms_T := Cms (60.0);
      RSM_At : Integer_64 := -1;
      F   : Speed_Fields;
   begin
      Give_MA (S, 5_000, 100, SIn.Fixed, Cms (40.0));
      Place (S, X, V);
      Sup_Start (S);
      for Step in 1 .. 5_000 loop
         --  the driver keeps 3 km/h below the displayed Permitted speed
         declare
            P : constant SIn.Speed_Cms_T :=
              SIn.Speed_Cms_T
                (EVC_Fixed.Max (Res.V_Perm - EVC_Fixed.Num (Cms (3.0)), 0));
         begin
            if Res.Monitoring = SDM.RSM then
               V := Cms (35.0);
            elsif V > P then
               V := SIn.Speed_Cms_T'Max (Integer (V) - 8, Integer (P));
            end if;
         end;
         X := X + Integer_64 (V) / 10;
         Move (X, V);
         Sup_Cycle;
         if Res.Monitoring = SDM.RSM and then RSM_At < 0 then
            RSM_At := X;
            F := Speed_Frame;
         end if;
         exit when RSM_At > 0 and then X > RSM_At + 2_000;
      end loop;
      Check (RSM_At > 0 and then RSM_At < 500_000,
             "release: RSM entered at" & Integer_64'Image (RSM_At / 100)
             & " m, before the EOA");
      Check (F.Monitoring = 2 and then F.V_Release = 40
             and then F.Flags mod 2 = 1 and then F.Status = 1,
             "release: MSG_SPEED_STATE RSM, release speed 40 shown, "
             & "Indication");
      Check (Res.Release_Exists and then not Cmd.EB,
             "release: 35 km/h under the release speed, no command");
      Move (X + 100, Cms (42.0));
      Sup_Cycle;
      Check (Cmd.EB and then Res.Status = SDM.IntS,
             "release t2: 42 km/h is above the release speed: EB");
      Move (X + 200, Cms (30.0));
      Sup_Cycle;
      Check (Cmd.EB and then Res.Status = SDM.IntS,
             "release: the EB stays below the release speed (Table 14)");
      Move (X + 250, 0);
      Sup_Cycle;
      Check (not Cmd.EB and then Res.Status = SDM.IndS
             and then Res.Monitoring = SDM.RSM,
             "release r0: revoked at standstill, Indication, still RSM");
      Check (Speed_Frame.D_Target > 0
             and then Speed_Frame.D_Target <= 5_000 - Natural (X / 100),
             "release: the distance to the EOA shown");
   end Scenario_SDM_Release;

   --  3.14.2, 3.14.3, 4.4.7.1.5: the protections, released at standstill
   --  after the acknowledgement (3.14.1.5, 3.14.1.9)
   procedure Scenario_SDM_Protections is
      S   : SIn.Snapshot_T := Base_Snapshot;
      Ack : constant Byte_Array :=
        Frame (EVC_DMI_Port.MSG_DRIVER_ACTION, (2, 5, 0, 0, 0));

      --  3.14.2.6, 3.14.3.4: "Runaway movement" (the DMI's entry 9)
      --  started and ended on the DMI port
      Runaway_Started, Runaway_Ended : Natural := 0;

      procedure Scan is
      begin
         for I in 1 .. Rec_Count loop
            if Recs (I).Port = DMI and then Rec_Length (I) = 7
              and then Byte_At (I, 1) = 16#0C# and then Byte_At (I, 6) = 9
            then
               if Byte_At (I, 7) = 0 then
                  Runaway_Started := Runaway_Started + 1;
               elsif Byte_At (I, 7) = 1 then
                  Runaway_Ended := Runaway_Ended + 1;
               end if;
            end if;
         end loop;
      end Scan;

      procedure Roll (From : Integer_64; Metres : Natural;
                      Backwards : Boolean) is
         X : Integer_64 := From;
      begin
         for I in 1 .. Metres * 2 loop
            X := X + (if Backwards then -50 else 50);
            Place (Sup, X, 500);
            Sup.Train.Moving_Ahead := not Backwards;
            Sup.Train.Moving_Backwards := Backwards;
            Sup_Cycle;
            Scan;
         end loop;
      end Roll;

      procedure Stop_And_Ack (Expect_Release : Boolean; What : String) is
      begin
         Place (Sup, Integer_64 (Sup.Train.Est_Front), 0);
         Sup_Cycle;
         Scan;
         Check (Cmd.EB and then Cmd.Ack_Required and then Status_Brake = 2,
                What & ": at standstill the acknowledgement is asked");
         Input (DMI, Ack);
         Sup_Cycle;
         Scan;
         Check (Cmd.EB /= Expect_Release,
                What & ": released after the acknowledgement");
      end Stop_And_Ack;
   begin
      --  roll away: the direction controller forward, the train rolls
      --  backwards
      Place (S, 100_000, 0);
      Sup_Start (S);
      Input (TIU, (6, 1));
      Roll (100_000, 1, True);
      Check (not Cmd.EB, "roll away: 1 m, under D_NVROLL (2 m)");
      Roll (Integer_64 (Sup.Train.Est_Front), 2, True);
      Check (Cmd.EB and then Cmd.Reasons (BC.Roll_Away)
             and then TIU_Out = 1 + 256 * 4,
             "roll away: beyond 2 m the emergency brake (TIU reason 4)");
      Check (Runaway_Started = 1 and then Runaway_Ended = 0,
             "roll away: 3.14.2.6, the driver is shown the protection's "
             & "brake: 'Runaway movement' (the DMI's entry 9; found by "
             & "SUBSET-076 4120100_10)");
      Stop_And_Ack (True, "roll away");
      Check (Runaway_Ended = 1,
             "roll away: 'Runaway movement' ends with the brake (3.14.1.5)");
      Roll (Integer_64 (Sup.Train.Est_Front), 3, False);
      Check (not Cmd.EB, "roll away: forwards is allowed");
      Input (TIU, (6, 0));
      Roll (Integer_64 (Sup.Train.Est_Front), 3, False);
      Check (Cmd.EB and then Cmd.Reasons (BC.Roll_Away),
             "roll away: in neutral no movement (3.14.2.3)");
      Stop_And_Ack (True, "roll away, neutral");

      --  unauthorised direction: an MA ahead, the train moves backwards
      Runaway_Started := 0;
      Runaway_Ended := 0;
      S := Base_Snapshot;
      Give_MA (S, 5_000);
      Place (S, 100_000, 0);
      Sup_Start (S);
      Roll (100_000, 3, True);
      Check (Cmd.EB and then Cmd.Reasons (BC.Direction)
             and then not Cmd.Reasons (BC.Roll_Away),
             "direction: a movement against the MA beyond 2 m brakes");
      Check (Runaway_Started = 1,
             "direction: 3.14.3.4, 'Runaway movement' while the brake is "
             & "commanded");
      --  the acknowledgement before standstill does nothing
      Input (DMI, Ack);
      Roll (Integer_64 (Sup.Train.Est_Front), 1, True);
      Check (Cmd.EB, "direction: the acknowledgement counts at standstill "
             & "only");
      Stop_And_Ack (True, "direction");

      --  standstill supervision in Stand By (nothing supervised)
      S := Base_Snapshot;
      S.Supervise := False;
      Place (S, 100_000, 0);
      Sup_Start (S);
      Roll (100_000, 3, False);
      Check (Cmd.EB and then Cmd.Reasons (BC.Standstill_Supervision),
             "standstill supervision: 3 m in SB brakes");
      Stop_And_Ack (True, "standstill supervision");
   end Scenario_SDM_Protections;

   --  Drive the scenario's train from X at V (cm/s) for up to Cycles
   --  cycles of 100 ms, decelerating by Decel cm/s per cycle once
   --  Brake_When holds, until Stop_When holds
   procedure Scenario_SDM_MRSP_Target is
      S     : SIn.Snapshot_T := Base_Snapshot;
      X     : Integer_64 := 0;
      V     : SIn.Speed_Cms_T := Cms (135.0);
      MRDT0 : Natural;
      D0    : Natural;

      function Below_78 return Boolean is (Sup.Train.Speed <= Cms (78.0));
      function Past return Boolean is (X > 310_000);
      procedure To_TSM is new Drive (Never, In_TSM);
      procedure Slow is new Drive (In_TSM, Below_78);
      procedure Pass is new Drive (Never, Past);
   begin
      S.MRSP := (Count => 2,
                 Segments => (1 => (0, Cms (140.0)),
                              2 => (300_000, Cms (80.0)),
                              others => (0, SIn.No_Speed_Limit)),
                 others   => <>);
      Place (S, X, V);
      Sup_Start (S);
      MRDT0 := Speed_Frame.MRDT;
      Check (Res.Monitoring = SDM.CSM and then Res.Indication,
             "MRSP target: CSM, the first Indication location known");
      To_TSM (X, V, 0, 3_000);
      Check (Res.Monitoring = SDM.TSM and then Res.Status = SDM.IndS
             and then X < 300_000,
             "MRSP target: TSM from" & Integer_64'Image (X / 100) & " m");
      D0 := Speed_Frame.D_Target;
      Check (Speed_Frame.V_Target = 80 and then Speed_Frame.MRDT /= MRDT0
             and then Speed_Frame.Monitoring = 1
             and then D0 > 0 and then D0 < 3_000 - Natural (X / 100),
             "MRSP target: the MRDT is new, target speed 80, distance"
             & Img (D0) & " m to its P location");
      Slow (X, V, 5, 3_000);
      Check (Res.Monitoring = SDM.TSM and then not Cmd.SB
             and then not Cmd.EB
             and then Res.Status in SDM.IndS | SDM.OvS,
             "MRSP target: braking at 0.5 m/s² keeps below intervention");
      Pass (X, V, 0, 3_000);
      Check (Res.Monitoring = SDM.CSM and then Res.V_MRSP = EVC_Fixed.Num (Cms (80.0))
             and then Speed_Frame.V_Perm = 80,
             "MRSP target: passed by the max safe front end, CSM at 80");
   end Scenario_SDM_MRSP_Target;

   --  3.13.8.2.1 b), 3.13.9.4.4: the LOA, no release speed; 3.13.10.2.6
   --  a): the overrun of the LOA
   procedure Scenario_SDM_LOA is
      S : SIn.Snapshot_T := Base_Snapshot;
      X : Integer_64 := 0;
      V : SIn.Speed_Cms_T := Cms (120.0);

      function Past return Boolean is (X > 402_000);
      procedure To_TSM is new Drive (Never, In_TSM);
      procedure Slow is new Drive (In_TSM, Past);
   begin
      Give_MA (S, 4_000, 0, SIn.Fixed, Cms (40.0), LOA_Kmh => 60.0);
      Place (S, X, V);
      Sup_Start (S);
      To_TSM (X, V, 0, 3_000);
      Check (Res.Monitoring = SDM.TSM and then Speed_Frame.V_Target = 60
             and then not Res.Release_Exists,
             "LOA: TSM to the LOA speed, no release speed (3.13.9.4.4)");
      V := Cms (58.0);
      Slow (X, V, 0, 5_000);
      Check (Res.EOA_Passed,
             "LOA: the min safe front end passed the LOA (3.13.10.2.6 a)");
   end Scenario_SDM_LOA;

   --  3.13.9.4.8: the release speed calculated on-board, against the
   --  reference; 3.13.9.4.9: limited by an MRSP element
   procedure Scenario_SDM_Calculated_Release is
      use EVC_Fixed;
      S : SIn.Snapshot_T := Base_Snapshot;
   begin
      Give_MA (S, 5_000, 50, SIn.Calculated_On_Board);
      Place (S, 100_000, Cms (100.0));
      Sup_Start (S);
      declare
         --  the reference: V + Vd0 = V_EBD (d_trip + (V + Vd0) *
         --  (T_traction + T_berem)), level 2, T_traction the cut-off
         --  time (as not implemented), T_berem = T_be - T_traction
         RM   : constant R_Model_T := R_Model (Sup);
         RP   : constant R_Profile_T := R_Profile (Sup, RM);
         SvL  : constant R_Curve := (R_EBD, 505_000.0, 0.0, 0.0);
         Trip : constant LF := 500_000.0 + 2_000.0;
         T_Be : constant LF :=
           LF (EVC_Braking.Conversion_Emergency
                 (SIn.Passenger_P, 40_000, True).Build_Up) * 1.1 / 1000.0;
         Lo   : LF := 0.0;
         Hi   : LF := 20_000.0;
         Kernel : constant Num := Res.V_Release;
      begin
         for I in 1 .. 60 loop
            declare
               Mid : constant LF := (Lo + Hi) / 2.0;
               Vd0 : constant LF :=
                 LF'Max ((64_000.0 + 36.0 * Mid) / 1692.0, 2.0 / 0.036);
               X   : constant LF :=
                 Trip + (Mid + Vd0) * (1.0 + LF'Max (T_Be - 1.0, 0.0));
            begin
               if Mid + Vd0 <= R_Speed_At (RM, RP, SvL, X) then
                  Lo := Mid;
               else
                  Hi := Mid;
               end if;
            end;
         end loop;
         Check (Res.Release_Exists and then LF (Kernel) <= Lo
                and then Lo - LF (Kernel) <= 28.0,
                "calculated release speed" & Img_LF (Kmh_Of (Kernel))
                & " km/h, the reference" & Img_LF (Lo * 0.036)
                & " km/h (within 1 km/h, not above)");
      end;
      --  3.13.9.4.9: an MRSP element of 15 km/h before the EOA, an SvL
      --  far enough for a higher release speed
      Give_MA (S, 5_000, 300, SIn.Calculated_On_Board);
      Place (S, 100_000, Cms (100.0));
      Sup_Start (S);
      Check (Res.V_Release > EVC_Fixed.Num (Cms (15.0)),
             "calculated release speed with an overlap of 300 m:"
             & Img_LF (Kmh_Of (Res.V_Release)) & " km/h");
      S.MRSP := (Count => 2,
                 Segments => (1 => (0, Cms (140.0)),
                              2 => (490_000, Cms (15.0)),
                              others => (0, SIn.No_Speed_Limit)),
                 others   => <>);
      Place (S, 100_000, Cms (100.0));
      Sup_Start (S);
      Check (Res.V_Release = EVC_Fixed.Num (Cms (15.0)),
             "calculated release speed limited by the MRSP to 15 km/h,"
             & " got" & Img_LF (Kmh_Of (Res.V_Release)) & " km/h");
   end Scenario_SDM_Calculated_Release;

   --  3.13.11: the perturbation location of the EOA / SvL and the MA
   --  request location, passed before the TSM
   procedure Scenario_SDM_Perturbation is
      S  : SIn.Snapshot_T := Base_Snapshot;
      X  : Integer_64 := 0;
      V  : constant SIn.Speed_Cms_T := Cms (100.0);
      Requested_At : Integer_64 := -1;
   begin
      Give_MA (S, 5_000, 100);
      S.Extra.T_MAR := 10_000;
      Place (S, X, V);
      Sup_Start (S);
      Check (Res.Perturbation and then Res.Perturbation_X < 500_000
             and then Res.Perturbation_X > 0 and then not Res.MA_Request,
             "perturbation: the location at"
             & Integer_64'Image (Integer_64 (Res.Perturbation_X) / 100)
             & " m, not passed at 0 m");
      for Step in 1 .. 3_000 loop
         exit when Res.Monitoring = SDM.TSM;
         X := X + Integer_64 (V) / 10;
         Move (X, V);
         Sup_Cycle;
         if Res.MA_Request and then Requested_At < 0 then
            Requested_At := X;
         end if;
      end loop;
      Check (Requested_At > 0 and then Res.Monitoring = SDM.TSM,
             "perturbation: the MA request location passed at"
             & Integer_64'Image (Requested_At / 100)
             & " m, before the TSM at" & Integer_64'Image (X / 100) & " m");
   end Scenario_SDM_Perturbation;

   --  A.3.10: the service brake feedback reduces and locks T_bs1 and
   --  T_bs2: the service brake comes later; the displayed P never grows
   procedure Scenario_SDM_Feedback is
      Base : SIn.Snapshot_T := Base_Snapshot;

      --  where the service brake is commanded at 120 km/h, with the
      --  brake pipe at Pressure kPa in target speed monitoring
      function SB_Location (Feedback : Boolean; Pressure : Natural;
                            P_Grows  : out Boolean) return Integer_64
      is
         X      : Integer_64 := 0;
         V      : constant SIn.Speed_Cms_T := Cms (120.0);
         Last_P : Natural := Natural'Last;
      begin
         P_Grows := False;
         Base.Extra.Config.Service_Brake_Feedback := Feedback;
         Base.National.Q_NVSBFBPERM := Feedback;
         Place (Base, X, V);
         Sup_Start (Base);
         Input (TIU, (12, 125));   -- 500 kPa
         for Step in 1 .. 4_000 loop
            if Res.Monitoring = SDM.TSM then
               Input (TIU, (12, EVC_Bytes.Byte (Pressure / 4)));
               if Speed_Frame.V_Perm > Last_P then
                  P_Grows := True;
               end if;
               Last_P := Speed_Frame.V_Perm;
            end if;
            X := X + Integer_64 (V) / 10;
            Move (X, V);
            Sup_Cycle;
            if Cmd.SB then
               return X;
            end if;
         end loop;
         return -1;
      end SB_Location;

      Grows : Boolean;
      pragma Warnings (Off, Grows);  --  set, not read, after the
      --  third call below, in the original file too -- its size
      --  alone kept GNAT's flow analysis from reaching this far
      Plain, Reduced, Locked : Integer_64;
   begin
      Give_MA (Base, 5_000, 200);
      Plain := SB_Location (False, 500, Grows);
      Check (not Grows, "feedback: the displayed P never grows without it");
      Reduced := SB_Location (True, 460, Grows);
      Check (not Grows, "feedback: the displayed P never grows (A.3.10)");
      Locked := SB_Location (True, 400, Grows);
      Check (Plain > 0 and then Reduced > Plain and then Locked > Reduced,
             "feedback: the service brake at" & Integer_64'Image
               (Plain / 100) & " m without feedback," & Integer_64'Image
               (Reduced / 100) & " m with 460 kPa (T_bs reduced),"
             & Integer_64'Image (Locked / 100) & " m with 400 kPa (locked)");
   end Scenario_SDM_Feedback;

   --  3.13.8.5, 3.13.9.3.5.4: the guidance curve moves P (and I) earlier
   procedure Scenario_SDM_GUI is
      S : SIn.Snapshot_T := Case_Snapshot (Gamma_Train, Flat);

      function TSM_From (GUI : Boolean) return Integer_64 is
         X : Integer_64 := 0;
         V : constant SIn.Speed_Cms_T := Cms (140.0);
      begin
         S.National.Q_NVGUIPERM := GUI;
         S.MRSP.Segments (1).Speed := Cms (160.0);
         Place (S, X, V);
         Sup_Start (S);
         for Step in 1 .. 4_000 loop
            exit when Res.Monitoring = SDM.TSM;
            X := X + Integer_64 (V) / 10;
            Move (X, V);
            Sup_Cycle;
         end loop;
         return X;
      end TSM_From;

      Without, With_GUI : Integer_64;
   begin
      Give_MA (S, 6_000, 200);
      Without := TSM_From (False);
      With_GUI := TSM_From (True);
      Check (With_GUI < Without,
             "GUI: the Indication from" & Integer_64'Image (With_GUI / 100)
             & " m with the guidance curve," & Integer_64'Image
               (Without / 100) & " m without");
   end Scenario_SDM_GUI;

   --  3.13.5, 3.13.6.2.1.3, .6, 3.13.10.3.9, .10: reduced adhesion, the
   --  A_MAXREDADH limit, target information and TTI in CSM
   procedure Scenario_SDM_Adhesion is
      S : SIn.Snapshot_T := Base_Snapshot;

      function TSM_From return Integer_64 is
         X : Integer_64 := 0;
         V : constant SIn.Speed_Cms_T := Cms (100.0);
      begin
         Place (S, X, V);
         Sup_Start (S);
         for Step in 1 .. 4_000 loop
            exit when Res.Monitoring = SDM.TSM;
            X := X + Integer_64 (V) / 10;
            Move (X, V);
            Sup_Cycle;
         end loop;
         return X;
      end TSM_From;

      Dry, Slippery : Integer_64;
      TTI_Seen      : Natural := 0;
      TTI_Falls     : Boolean := True;
      Last_TTI      : Natural := Natural'Last;
      X             : Integer_64 := 0;
      V             : constant SIn.Speed_Cms_T := Cms (100.0);
   begin
      Give_MA (S, 5_000, 200);
      Dry := TSM_From;
      --  the driver's slippery rail: A_NVMAXREDADH2 (passenger, no
      --  additional brake) of 0.4 m/s² limits the safe deceleration
      S.Adhesion.Driver_Slippery := True;
      S.National.A_NVMAXREDADH2 := 400;
      Slippery := TSM_From;
      Check (Slippery < Dry,
             "adhesion: the Indication from" & Integer_64'Image
               (Slippery / 100) & " m on slippery rail," & Integer_64'Image
               (Dry / 100) & " m on dry rail");

      --  62: the time to Indication in CSM (3.13.10.3.10)
      S.Extra.National.Redadh_Use (2) := SIn.Time_To_Indication;
      Place (S, X, V);
      Sup_Start (S);
      for Step in 1 .. 4_000 loop
         exit when Res.Monitoring = SDM.TSM;
         if Res.TTI /= SDM.No_TTI then
            TTI_Seen := TTI_Seen + 1;
            if Res.TTI > Last_TTI then
               TTI_Falls := False;
            end if;
            Last_TTI := Res.TTI;
         end if;
         X := X + Integer_64 (V) / 10;
         Move (X, V);
         Sup_Cycle;
      end loop;
      Check (TTI_Seen in 100 .. 150 and then TTI_Falls,
             "adhesion: the TTI shown for the last 14 s before the "
             & "Indication (" & Img (TTI_Seen) & " cycles), falling");

      --  61: target information in CSM (3.13.10.3.9)
      S.Extra.National.Redadh_Use (2) := SIn.Target_Information;
      Place (S, 100_000, V);
      Sup_Start (S);
      Check (Res.Monitoring = SDM.CSM and then Res.CSM_Target
             and then Speed_Frame.Flags / 2 mod 2 = 1
             and then Speed_Frame.D_Target in 3_900 .. 4_000,
             "adhesion: the target information in CSM, distance"
             & Img (Speed_Frame.D_Target) & " m");
   end Scenario_SDM_Adhesion;

   --  3.13.2.2.3.1.7, 3.13.2.2.6, 3.13.5.1, .2: special brakes, their
   --  status and the inhibition areas change A_brake_emergency (V, d)
   procedure Scenario_SDM_Special_Brakes is
      use EVC_Fixed;
      S   : SIn.Snapshot_T := Case_Snapshot (Gamma_Train, Flat);
      Far : constant EVC_Distances.Dist_T := -EVC_Distances.Max_Cm + 1;
      SvL : constant EVC_Curves.Curve_T := (EVC_Curves.EBD, 500_000, 0, 0, False);

      function Speed_1000 (Active : Boolean) return Speed_T is
         M : EVC_Braking.Model_T;
         P : EVC_Profile.Profile_T;
      begin
         EVC_Braking.Build (S, (SIn.Regenerative => Active, others => False),
                            False, M);
         EVC_Profile.Build (S, M, Far, P);
         return EVC_Curves.Speed_At (M, P, SvL, 400_000);
      end Speed_1000;

      Plain, Regen, Inhibited, Inactive : Speed_T;
   begin
      Plain := Speed_1000 (True);
      S.Train_Data.Has_Regenerative := True;
      S.Extra.Config.Special_Brakes (SIn.Regenerative) :=
        SIn.Emergency_And_Service;
      S.Extra.Train.By_Combination := True;
      for C in SIn.Brake_Combination_T loop
         S.Extra.Train.A_Emergency_Combination (C) :=
           S.Train_Data.A_Brake_Emergency;
         S.Extra.Train.A_Service_Combination (C) :=
           S.Train_Data.A_Brake_Service;
      end loop;
      --  the regenerative brake adds 0.2 m/s² to the emergency brake
      for K in 1 .. 3 loop
         S.Extra.Train.A_Emergency_Combination (1).Steps (K).Decel :=
           S.Train_Data.A_Brake_Emergency.Steps (K).Decel + 200;
      end loop;
      Regen := Speed_1000 (True);
      Inactive := Speed_1000 (False);
      S.Inhibitions := (Count => 1,
                        Areas => (1 => (SIn.Regenerative_Inhibited, 450_000,
                                        470_000),
                                  others => (SIn.Regenerative_Inhibited,
                                             0, 0)));
      Inhibited := Speed_1000 (True);
      Check (Regen > Plain and then Inactive = Plain
             and then Inhibited < Regen and then Inhibited > Plain,
             "special brakes: EBD 1 km before the SvL" & Img (Natural (Plain))
             & " cm/s, with the regenerative brake" & Img (Natural (Regen))
             & ", inhibited from 50 m before the SvL"
             & Img (Natural (Inhibited)) & ", not active"
             & Img (Natural (Inactive)));
   end Scenario_SDM_Special_Brakes;

   --  3.13.10.4.2: masking; two targets close to each other, the second
   --  of a lower speed masked by the first: the MRDT is the second
   procedure Scenario_SDM_Masking is
      S : SIn.Snapshot_T := Base_Snapshot;
      X : Integer_64 := 0;
      V : SIn.Speed_Cms_T := Cms (135.0);
      procedure To_TSM is new Drive (Never, In_TSM);
   begin
      S.MRSP := (Count => 2,
                 Segments => (1 => (0, Cms (140.0)),
                              2 => (300_000, Cms (100.0)),
                              others => (0, SIn.No_Speed_Limit)),
                 others   => <>);
      Give_MA (S, 3_300, 50);
      Place (S, X, V);
      Sup_Start (S);
      To_TSM (X, V, 0, 3_000);
      Check (Res.Monitoring = SDM.TSM and then Speed_Frame.V_Target = 0,
             "masking: the EOA, masked by the 100 km/h target 300 m "
             & "before it, is the MRDT (target speed 0)");

      S.MRSP.Segments (2).Start := 100_000;
      Give_MA (S, 5_000, 50);
      X := 0;
      V := Cms (135.0);
      Place (S, X, V);
      Sup_Start (S);
      To_TSM (X, V, 0, 3_000);
      Check (Res.Monitoring = SDM.TSM and then Speed_Frame.V_Target = 100,
             "masking: with the EOA far behind, the 100 km/h target is "
             & "the MRDT");
   end Scenario_SDM_Masking;

   --  3.13.8.2.1 d), 3.13.10.4.13.1: the end of the SR distance
   procedure Scenario_SDM_SR is
      S : SIn.Snapshot_T := Base_Snapshot;
      X : Integer_64 := 0;
      V : SIn.Speed_Cms_T := Cms (40.0);
      procedure To_TSM is new Drive (Never, In_TSM);
   begin
      S.MRSP.Segments (1).Speed := Cms (40.0);
      S.Extra.SR_Distance := True;
      S.Extra.SR_End := 50_000;
      Place (S, X, V);
      Sup_Start (S);
      To_TSM (X, V, 0, 2_000);
      Check (Res.Monitoring = SDM.TSM and then Speed_Frame.V_Target = 0
             and then Speed_Frame.D_Target <= 500 - Natural (X / 100),
             "SR distance: TSM to its end, target speed 0");
   end Scenario_SDM_SR;

   ---------------------------------------------------------------------
   --  The seams of the two halves of E3, on the supervision's side
   ---------------------------------------------------------------------

   --  3.13.4.1.3: where the gradient profile gives nothing, the default
   --  gradient for TSR for a target due to a TSR, else 0; 3.13.1.5: the
   --  temporary EOA and SvL (3.12.4.7, 3.12.5.8), with no release speed;
   --  3.13.2.3.4.1: a powerless section without the regenerative brake
   --  (3.12.1.3.3)
   procedure Scenario_SDM_Seams is
      S : SIn.Snapshot_T;
      X : Integer_64;
      V : SIn.Speed_Cms_T;
      procedure To_TSM is new Drive (Never, In_TSM);

      --  where TSM to the 80 km/h restriction at 3 km begins
      function TSM_From (TSR, Default, Covered : Boolean) return Integer_64
      is
      begin
         S := Base_Snapshot;
         S.MRSP := (Count    => 2,
                    Segments => (1 => (0, Cms (140.0)),
                                 2 => (300_000, Cms (80.0)),
                                 others => (0, SIn.No_Speed_Limit)),
                    TSR      => (2 => TSR, others => False));
         S.Gradients.Count := 2;
         S.Gradients.Segments (1) := (Start => -100_000, Gradient => 0);
         S.Gradients.Segments (2) := (Start => 100_000, Gradient => 0);
         S.Gradients.Covered (2) := Covered;
         S.Gradients.Has_Default_TSR := Default;
         S.Gradients.Default_TSR := -30;
         X := 0;
         V := Cms (135.0);
         Place (S, X, V);
         Sup_Start (S);
         To_TSM (X, V, 0, 3_000);
         return X;
      end TSM_From;

      Plain, Due, No_Default, Covered : Integer_64;

      --  where TSM to an end of authority at 5 km begins, with a
      --  temporary EOA at 3 km and its SvL 100 m further (Has_SvL)
      function EOA_TSM_From (Temporary, Has_SvL : Boolean;
                             LOA : Boolean := False) return Integer_64
      is
      begin
         S := Base_Snapshot;
         if LOA then
            Give_MA (S, 5_000, LOA_Kmh => 60.0);
         else
            Give_MA (S, 5_000, 200, SIn.Fixed, Cms (40.0));
         end if;
         if Temporary then
            S.Temporary := (Present => True, EOA => 300_000,
                            Has_SvL => Has_SvL, SvL => 310_000);
         end if;
         X := 0;
         V := Cms (100.0);
         Place (S, X, V);
         Sup_Start (S);
         To_TSM (X, V, 0, 5_000);
         return X;
      end EOA_TSM_From;

      MA_Only, Tmp, Tmp_No_SvL, Tmp_LOA : Integer_64;
      Release_MA, Release_Tmp, Release_No_SvL : Boolean;
      Target_LOA : Natural;

      Model : EVC_Braking.Model_T;
      P     : EVC_Profile.Profile_T;
      In_Area, Outside : EVC_Profile.Point_T;
   begin
      Plain := TSM_From (TSR => False, Default => True, Covered => False);
      Due := TSM_From (TSR => True, Default => True, Covered => False);
      No_Default :=
        TSM_From (TSR => True, Default => False, Covered => False);
      Covered := TSM_From (TSR => True, Default => True, Covered => True);
      Check (Plain > 0 and then Due > 0 and then Due < Plain
             and then No_Default = Plain and then Covered = Plain,
             "3.13.4.1.3: TSM to a TSR from" & Integer_64'Image (Due / 100)
             & " m with the downhill default gradient where the profile "
             & "gives nothing, from" & Integer_64'Image (Plain / 100)
             & " m for the same restriction not due to a TSR, without a "
             & "default gradient, or where the profile covers the track");

      MA_Only := EOA_TSM_From (Temporary => False, Has_SvL => False);
      Release_MA := Res.Release_Exists;
      Tmp := EOA_TSM_From (Temporary => True, Has_SvL => True);
      Release_Tmp := Res.Release_Exists;
      Check (Tmp > 0 and then Tmp < MA_Only
             and then Speed_Frame.V_Target = 0
             and then Speed_Frame.D_Target < 3_000 - Natural (Tmp / 100)
             and then Release_MA and then not Release_Tmp,
             "3.13.1.5: the temporary EOA and SvL are the closer ones (TSM "
             & "from" & Integer_64'Image (Tmp / 100) & " m, not"
             & Integer_64'Image (MA_Only / 100) & " m), with no release "
             & "speed (3.12.4.7, 3.12.5.8)");
      Tmp_No_SvL := EOA_TSM_From (Temporary => True, Has_SvL => False);
      Release_No_SvL := Res.Release_Exists;
      Check (Tmp_No_SvL > 0 and then Tmp_No_SvL < MA_Only
             and then Release_No_SvL,
             "3.12.4.7.1: a temporary EOA without a temporary SvL: the SvL "
             & "of the MA and its release speed hold");
      Tmp_LOA := EOA_TSM_From (Temporary => True, Has_SvL => True,
                               LOA => True);
      Target_LOA := Speed_Frame.V_Target;
      Check (Tmp_LOA > 0 and then Target_LOA = 0,
             "3.13.1.5: beside an LOA the temporary EOA is a target of "
             & "speed 0");

      --  the powerless section: a train with a regenerative brake that
      --  needs the catenary
      S := Base_Snapshot;
      S.Train_Data.Has_Regenerative := True;
      S.Inhibitions.Count := 1;
      S.Inhibitions.Areas (1) :=
        (Kind => SIn.Powerless_Section, Start => 100_000, Finish => 200_000);
      EVC_Braking.Build (S, (others => True), False, Model);
      EVC_Profile.Build (S, Model, 0, P);
      In_Area := P.Points (EVC_Profile.Segment_Of (P, 150_000));
      Outside := P.Points (EVC_Profile.Segment_Of (P, 50_000));
      Check (In_Area.Inhibited (SIn.Regenerative_Inhibited)
             and then In_Area.Inhibited (SIn.Powerless_Section)
             and then not Outside.Inhibited (SIn.Regenerative_Inhibited)
             and then EVC_Braking.Emergency_Combination
                        (Model, In_Area.Inhibited) mod 2 = 0
             and then EVC_Braking.Emergency_Combination
                        (Model, Outside.Inhibited) mod 2 = 1,
             "3.13.2.3.4.1: no regenerative brake in the powerless section "
             & "(3.12.1.3.3)");
      S.Extra.Config.Regenerative_Needs_Catenary := False;
      EVC_Profile.Build (S, Model, 0, P);
      In_Area := P.Points (EVC_Profile.Segment_Of (P, 150_000));
      Check (not In_Area.Inhibited (SIn.Regenerative_Inhibited),
             "3.12.1.3.3: a regenerative brake independent from the "
             & "catenary is kept");
   end Scenario_SDM_Seams;

   ---------------------------------------------------------------------
   --  The mission of the mock (dmi_test Scenario_Mission) with the
   --  on-board's speed and distance monitoring
   ---------------------------------------------------------------------

   --  The track of sim/evc_track.ads for the on-board: one balise group
   --  12 m in rear of the start of the mission (its balises at -12 m and
   --  -9 m, read before the mission starts) with the national values
   --  (packet 3: those of A.3.2 but Q_NVEMRRLS = 1, an emergency brake the
   --  mock's train does not obey is revoked with the Permitted speed
   --  instead of staying until a standstill that does not come; the
   --  mission keeps 1, the bench runs 0, and the Scenario_EMRRLS_*
   --  scenarios at the end run this track with both values), the SSP
   --  (27: 140, 100 from 4 km, 120 from 7 km, to 10.5 km, no train length
   --  delay as the mock has none), the gradients (21: 5, -8 from 2 km, 0
   --  from 5 km, 12 from 8 km, to 10.5 km) and the MA (12: V_MAIN 140
   --  km/h, the EOA at 10 km, a danger point there with a release speed of
   --  25 km/h: the mock has no SvL, the SvL is the EOA). The packets are
   --  those of the first group of the bench (Sim_Trackside), built by
   --  Sim_Telegrams, but for Q_NVEMRRLS and the linking the bench adds.
   --  The train data of the mission (passenger, 400 m, 135 %, 140 km/h, a
   --  traction cut-off time of 1 s; data entry is phase E4) go straight
   --  to the store.

end EVC_Test_Supervision;
