with EVC_Test_Support;  use EVC_Test_Support;
with Ada.Text_IO;
with ETCS_Track_Packets.P52;
with ETCS_Variables;
with EVC_Distances;
with EVC_Fixed;
with EVC_Limits;
with EVC_PBD;
with EVC_Profiles;
with EVC_Stored_Information;
with EVC_Supervision_Input;
with EVC_Track_Description;
with EVC_Train_Data;
with Interfaces;

package body EVC_Test_PBD is

   package SI renames EVC_Stored_Information;
   package TD renames EVC_Track_Description;
   package Prof renames EVC_Profiles;
   package SIn renames EVC_Supervision_Input;
   package T52 renames ETCS_Track_Packets.P52;

   use type EVC_Distances.Cm_T;
   use type EVC_Limits.Margin_Kind_T;
   use Ada.Text_IO;
   use Interfaces;


   ---------------------------------------------------------------------
   --  E3 after the integration: the speed restriction to ensure a
   --  permitted braking distance (3.11.11, packet 52, EVC_PBD) and the
   --  gaps of the gradient profile (3.11.12.2)
   ---------------------------------------------------------------------

   --  SUBSET-041 5.3.1.2: f41 (V), cm/s, exact
   function R_F41 (V : LF) return LF is
      Kmh : constant LF := V * 0.036;
   begin
      return (if Kmh <= 30.0 then 2.0
              else 2.0 + (Kmh - 30.0) * 10.0 / 470.0) / 0.036;
   end R_F41;

   --  3.11.11.6, .8, .9 in floating point: the condition C holds at the
   --  speed V (cm/s) for the permitted braking distance D (cm), the
   --  times of the model (T_be, T_bs) as the kernel has them
   function R_PBD_Holds (RM : R_Model_T;
                         RP : R_Profile_T;
                         I  : EVC_PBD.Inputs_T;
                         C  : EVC_PBD.Condition_T;
                         D  : LF;
                         V  : LF) return Boolean
   is
      use type EVC_PBD.Condition_T;
      T41   : constant LF := 1.0;
      T_Be  : constant LF := LF (I.Model.Emergency_Zero.Build_Up) / 1000.0;
      T_Bs  : constant LF :=
        (if I.SB_Avail then LF (I.Model.Service_Zero.Build_Up) / 1000.0
         else 0.0);
      T_Tr  : constant LF := LF (I.T_Traction) / 1000.0;
      Ant   : constant LF := LF (I.Antenna);
      Curve : constant R_Curve :=
        ((if C = EVC_PBD.Service_SBD then R_SBD else R_EBD), D, 0.0, 0.0);
   begin
      if C = EVC_PBD.Service_SBD then
         declare
            V1 : constant LF := V + R_Margin (EVC_Limits.SBI, V);
            X  : constant LF := Ant + V1 * T41 + V1 * T_Bs;
         begin
            return X <= D and then V1 <= R_Speed_At (RM, RP, Curve, X);
         end;
      else
         declare
            V1  : constant LF :=
              V + R_Margin ((if C = EVC_PBD.Emergency then EVC_Limits.EBI
                             else EVC_Limits.SBI), V);
            Vd0 : constant LF := (if I.Inhibit then 0.0 else R_F41 (V1));
            Vb  : constant LF := V1 + Vd0;
            X   : constant LF :=
              Ant + Vb * T41 + Vb * (T_Tr + LF'Max (T_Be - T_Tr, 0.0))
              + (if C = EVC_PBD.Service_EBD then V1 * T_Bs else 0.0);
         begin
            return X <= D and then Vb <= R_Speed_At (RM, RP, Curve, X);
         end;
      end if;
   end R_PBD_Holds;

   --  The largest speed of 0 .. 600 km/h for which the condition holds
   function R_PBD (RM : R_Model_T;
                   RP : R_Profile_T;
                   I  : EVC_PBD.Inputs_T;
                   C  : EVC_PBD.Condition_T;
                   D  : LF) return LF
   is
      Lo : LF := 0.0;
      Hi : LF := LF (EVC_PBD.Top_Speed);
   begin
      if not R_PBD_Holds (RM, RP, I, C, D, Lo) then
         return 0.0;
      elsif R_PBD_Holds (RM, RP, I, C, D, Hi) then
         return Hi;
      end if;
      for K in 1 .. 60 loop
         declare
            Mid : constant LF := (Lo + Hi) / 2.0;
         begin
            if R_PBD_Holds (RM, RP, I, C, D, Mid) then
               Lo := Mid;
            else
               Hi := Mid;
            end if;
         end;
      end loop;
      return Lo;
   end R_PBD;

   --  V_PBD in cm/s, the multiple of 5 km/h at or below V (3.11.11.6)
   function Five_Below (V : LF) return LF is
     (LF'Floor (V * 0.036 / 5.0 + 1.0E-9) * 5.0 / 0.036);

   --  A speed of the store is a multiple of 5 km/h, rounded down to the
   --  cm/s
   function Multiple_Of_5 (V : Integer) return Boolean is
     (for some K in 0 .. 120 => V = K * 1_250 / 9);

   --  3.11.11: the kernel's V_PBD against the reference, for the trains
   --  of Scenario_SDM_Precision, gradients uphill and downhill, the
   --  emergency and the service brake, short and long distances
   procedure Scenario_PBD_Precision is
      use EVC_Fixed;
      Grads    : constant array (1 .. 5) of SIn.Gradient_T :=
        (0, 10, -15, -30, 25);
      Dists    : constant array (1 .. 6) of Natural :=
        (2, 150, 400, 900, 2_000, 6_000);
      N        : Natural := 0;
      Unsafe_N : Natural := 0;
      Equal    : Natural := 0;
      Zeros    : Natural := 0;
      Worst    : LF := 0.0;
   begin
      for T in Train_Case loop
         for G of Grads loop
            declare
               S   : SIn.Snapshot_T := Case_Snapshot (T, Flat);
               I   : EVC_PBD.Inputs_T;
               RM  : R_Model_T;
               RP  : R_Profile_T;
            begin
               S.Gradients :=
                 (Count    => 1,
                  Segments => (1 => (-10_000_000, G), others => (0, 0)),
                  others   => <>);
               I := EVC_PBD.Inputs_Of (S, (others => False), False, 250);
               RM := R_Model (S);
               RP := R_Profile (S, RM);
               for D_M of Dists loop
                  declare
                     D   : constant Num := Num (D_M) * 100;
                     Tag : constant String :=
                       Train_Case'Image (T) & Integer'Image (G)
                       & " per mille," & Img (D_M) & " m";
                     R   : array (EVC_PBD.Condition_T) of LF;
                  begin
                     for C in EVC_PBD.Condition_T loop
                        declare
                           K : constant Speed_T :=
                             EVC_PBD.Unrounded (I, C, D, G);
                        begin
                           R (C) := R_PBD (RM, RP, I, C, LF (D));
                           N := N + 1;
                           if LF (K) > R (C) + 0.01 then
                              Unsafe_N := Unsafe_N + 1;
                           end if;
                           Worst := LF'Max (Worst, R (C) - LF (K));
                           Check (LF (K) <= R (C) + 0.01
                                  and then R (C) - LF (K) <= 10.0,
                                  "PBD " & Tag & " "
                                  & EVC_PBD.Condition_T'Image (C) & ":"
                                  & Img (Natural (K)) & " cm/s, the "
                                  & "reference" & Img_LF (R (C)));
                        end;
                     end loop;
                     for Service in Boolean loop
                        declare
                           K  : constant Natural :=
                             EVC_PBD.Restriction (I, D, G, Service);
                           RV : constant LF :=
                             Five_Below
                               (if Service
                                then LF'Min (R (EVC_PBD.Service_EBD),
                                             R (EVC_PBD.Service_SBD))
                                else R (EVC_PBD.Emergency));
                        begin
                           Check (LF (K) <= RV + 0.01
                                  and then LF (K) >= RV - 140.0
                                  and then Multiple_Of_5 (K),
                                  "V_PBD " & Tag & " service "
                                  & Boolean'Image (Service) & ":" & Img (K)
                                  & " cm/s, the reference" & Img_LF (RV));
                           if Natural (LF'Floor (RV)) = K then
                              Equal := Equal + 1;
                           end if;
                           if K = 0 then
                              Zeros := Zeros + 1;
                           end if;
                        end;
                     end loop;
                  end;
               end loop;
            end;
         end loop;
      end loop;
      Check (Unsafe_N = 0, "PBD: never above the reference");
      Put_Line ("  PBD:" & Img (N) & " speeds compared with the reference, "
                & "below it by at most" & Img_LF (Worst) & " cm/s; V_PBD"
                & Img (Equal) & " of" & Img (N / 3 * 2) & " equal to the "
                & "reference, the others one step of 5 km/h below;"
                & Img (Zeros) & " zero (no speed fulfils)");
   end Scenario_PBD_Precision;

   --  Packet 52 of these sections: the distance from the previous start
   --  (m; the first from the location reference), the length (m), the
   --  permitted braking distance (m), the gradient (per mille, signed)
   --  and the brake
   type PBD_Item is record
      D_M     : Natural;
      L_M     : Natural;
      PBD_M   : Natural;
      G       : Integer;
      Service : Boolean := False;
   end record;
   type PBD_List is array (Positive range <>) of PBD_Item;

   function PBD_Of (L : PBD_List) return T52.Packet_T is
      P : T52.Packet_T;
      F : PBD_Item renames L (L'First);
   begin
      P.Q_DIR := 1;
      P.Q_SCALE := 1;
      P.Q_TRACKINIT := 0;
      P.Has_D_PBD := True;
      P.D_PBD := ETCS_Variables.D_PBD_T (F.PBD_M);
      P.Q_GDIR := (if F.G >= 0 then 1 else 0);
      P.G_PBDSR := ETCS_Variables.G_PBDSR_T (abs F.G);
      P.Q_PBDSR := (if F.Service then 1 else 0);
      P.D_PBDSR := ETCS_Variables.D_PBDSR_T (F.D_M);
      P.L_PBDSR := ETCS_Variables.L_PBDSR_T (F.L_M);
      P.N_ITER := ETCS_Variables.N_ITER_T (L'Length - 1);
      for I in 1 .. L'Length - 1 loop
         declare
            X : PBD_Item renames L (L'First + I);
         begin
            P.D_PBD_List (I) :=
              (D_PBD   => ETCS_Variables.D_PBD_T (X.PBD_M),
               Q_GDIR  => (if X.G >= 0 then 1 else 0),
               G_PBDSR => ETCS_Variables.G_PBDSR_T (abs X.G),
               Q_PBDSR => (if X.Service then 1 else 0),
               D_PBDSR => ETCS_Variables.D_PBDSR_T (X.D_M),
               L_PBDSR => ETCS_Variables.L_PBDSR_T (X.L_M));
         end;
      end loop;
      return P;
   end PBD_Of;

   --  V_PBD with the inputs of the stored information now
   function V_PBD (PBD_M : Natural; G : Integer; Service : Boolean)
     return Integer
   is (EVC_PBD.Restriction (SI.PBD_Inputs, EVC_Fixed.Num (PBD_M) * 100, G,
                            Service));

   --  The speed of the MRSP of the snapshot at the frame position X
   function MRSP_At (X : Integer_64) return Integer is
      M : constant SIn.Speed_Profile_T := SI.Current.MRSP;
      R : Integer := M.Segments (1).Speed;
   begin
      for K in 2 .. M.Count loop
         if Integer_64 (M.Segments (K).Start) <= X then
            R := M.Segments (K).Speed;
         end if;
      end loop;
      return R;
   end MRSP_At;

   --  km/h to the nearest, as MSG_PLANNING has them
   function Kmh_Plan (Cms_V : Integer) return Natural is
     ((Cms_V * 9 + 125) / 250);

   --  The last MSG_PLANNING has a speed change to Kmh at Dist_M
   function Plan_Has_Speed (Dist_M, Kmh : Natural) return Boolean is
      G    : constant Natural := Natural (Plan_Payload (9));
      Base : constant Natural := 10 + 3 * G;
      N    : constant Natural := Natural (Plan_Payload (Base));
   begin
      for K in 0 .. N - 1 loop
         if Plan_U16 (Base + 4 * K) = Dist_M
           and then Plan_U16 (Base + 4 * K + 2) = Kmh
         then
            return True;
         end if;
      end loop;
      return False;
   end Plan_Has_Speed;

   --  3.11.11, 3.7.3.1 d), 3.7.3.1.4, 3.7.3.2 a): packet 52 through the
   --  track, the store, the MRSP and MSG_PLANNING
   procedure Scenario_PBD is
      St     : Prof.Store_T;
      V1, VA, VB, VC, VD, VE : Integer;
      Before : array (1 .. 3) of Integer := (others => 0);
      Lower  : Boolean := False;
      Kept   : Boolean := True;
   begin
      Start_X;
      Add_Group (Group (10, 100));
      Add_Group (Group (20, 200));
      Add_Group (Group (30, 300));
      Add_Group (Group (40, 400));
      Carry (1, 0, SSP ((1 => (0, 200, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 1, MA_Of ((1 => 3000), 200));
      Carry (1, 1, PBD_Of ((1 => (500, 200, 600, 0, False))));
      Run_X (15_000);
      St := TD.PBD;
      Check (St.Count = 1 and then St.List (1).Noted
             and then St.List (1).Id = 60_000
             and then St.List (1).Gradient = 0
             and then not St.List (1).Service
             and then Est (St.List (1).Start) = 60_000
             and then Est (St.List (1).Finish) = 80_000,
             "PBD: a section stored, from D_PBDSR over L_PBDSR, with its "
             & "permitted braking distance, gradient and brake (3.11.11.2)");
      V1 := V_PBD (600, 0, False);
      Check (St.List (1).Value = V1 and then V1 > 0
             and then Multiple_Of_5 (V1) and then V1 < 4_444,
             "PBD: V_PBD computed on reception (3.11.11.3), a multiple of "
             & "5 km/h (3.11.11.6):" & Integer'Image (V1) & " cm/s");
      Check (MRSP_Is ((0, 60_000, 80_000), (4_444, V1, 4_444)),
             "PBD: the restriction in the MRSP over the section, front end "
             & "only (3.13.7, 3.11.2.2 k, Table 2a)");
      Check (Plan_Frames > 0
             and then Plan_Has_Speed ((60_000 - 15_300) / 100, Kmh_Plan (V1))
             and then Plan_Has_Speed ((80_000 - 15_300) / 100, 160),
             "PBD: the restriction in MSG_PLANNING");
      Check (SI_Seen (SI.Info_PBD, SI.Change_Stored) = 1
             and then SI_Seen (SI.Info_PBD, SI.Change_Recalculated) = 0,
             "JRU: the PBD information stored, nothing computed again");
      Check (MRSP_Below_Sources, "PBD: the MRSP below its sources");

      --  several sections, uphill and downhill, emergency and service
      --  brake; 3.7.3.1 d): the new information replaces the stored one
      --  from the start of its first section
      Carry (2, 0, PBD_Of ((1 => (450, 100, 800, 10, False),
                            2 => (200, 100, 800, -10, False),
                            3 => (200, 100, 800, 0, True),
                            4 => (200, 100, 800, 0, False),
                            5 => (200, 100, 350, -25, True))));
      Run_X (25_000);
      St := TD.PBD;
      VA := V_PBD (800, 10, False);
      VB := V_PBD (800, -10, False);
      VC := V_PBD (800, 0, True);
      VD := V_PBD (800, 0, False);
      VE := V_PBD (350, -25, True);
      Check (St.Count = 6
             and then Est (St.List (1).Finish) = 65_000
             and then Est (St.List (2).Start) = 65_000
             and then Est (St.List (6).Start) = 145_000,
             "PBD: replaced from the start of the first new section, the "
             & "old one across it cut there (3.7.3.1 d)");
      Check (St.List (2).Value = VA and then St.List (3).Value = VB
             and then St.List (4).Value = VC
             and then St.List (5).Value = VD
             and then St.List (6).Value = VE
             and then St.List (4).Service and then not St.List (5).Service
             and then St.List (3).Gradient = -10,
             "PBD: every section with its own gradient and brake");
      Check (VB < VA and then VC <= VD and then VE < VC and then VE > 0,
             "PBD: lower downhill than uphill, with the service brake than "
             & "with the emergency brake (3.11.11.7):" & Integer'Image (VA)
             & Integer'Image (VB) & Integer'Image (VC) & Integer'Image (VD)
             & Integer'Image (VE));
      Check (MRSP_At (62_000) = V1 and then MRSP_At (70_000) = VA
             and then MRSP_At (80_000) = 4_444
             and then MRSP_At (90_000) = VB
             and then MRSP_At (110_000) = VC
             and then MRSP_At (130_000) = VD
             and then MRSP_At (150_000) = VE
             and then MRSP_At (160_000) = 4_444,
             "PBD: the sections in the MRSP");
      Check (Plan_Has_Speed ((85_000 - 25_300) / 100, Kmh_Plan (VB))
             and then Plan_Has_Speed ((145_000 - 25_300) / 100,
                                      Kmh_Plan (VE)),
             "PBD: the sections in MSG_PLANNING");
      Check (SI_Seen (SI.Info_PBD, SI.Change_Stored) = 2
             and then SI_Seen (SI.Info_PBD, SI.Change_Recalculated) = 0,
             "PBD: computed on reception only (3.11.11.3)");

      --  3.7.3.1.4: the relocation by the travelled distance (3.6.4.2.5
      --  c) sets the "min" and "max" items of the start of the new
      --  information apart: over the distance between them the lowest of
      --  the old and the new sections
      Run_X (35_000);
      St := TD.PBD;
      Check (Max_X (St.List (2).Start) < Est (St.List (2).Start)
             and then Min_X (St.List (1).Finish) > Est (St.List (1).Finish)
             and then Prof."=" (St.List (1).Finish, St.List (2).Start),
             "PBD: the items of the start of the new information apart "
             & "after a relocation (3.6.4.2.5 c)");
      Check (V1 < VA
             and then MRSP_At (Max_X (St.List (2).Start)) = V1
             and then MRSP_At (Min_X (St.List (1).Finish) - 1) = V1
             and then MRSP_At (Min_X (St.List (1).Finish)) = VA,
             "PBD: between the max and the min item of the start of the "
             & "new information the lower of the two (3.7.3.1.4)");
      Check (MRSP_Below_Sources, "PBD: the MRSP below its sources");

      --  3.7.3.2 a): the initial state from D_TRACKINIT
      declare
         P : T52.Packet_T;
      begin
         P.Q_DIR := 1;
         P.Q_SCALE := 1;
         P.Q_TRACKINIT := 1;
         P.Has_D_TRACKINIT := True;
         P.D_TRACKINIT := 500;
         Carry (4, 0, P);
      end;
      Run_X (45_000);
      St := TD.PBD;
      Check (St.Count = 3 and then Est (St.List (3).Finish) = 90_000
             and then MRSP_At (89_000) = VB
             and then MRSP_At (95_000) = 4_444
             and then MRSP_At (110_000) = 4_444,
             "PBD: no restriction beyond D_TRACKINIT, the section across "
             & "it cut there (3.7.3.2 a, 3.11.11.11)");

      --  3.11.11.3: new Train Data, every section computed again
      for K in 1 .. 3 loop
         Before (K) := St.List (K).Value;
      end loop;
      declare
         D : SIn.Train_Data_T := EVC_Train_Data.Default;
      begin
         D.Brake_Percentage := 70;
         EVC_Train_Data.Set (D, EVC_Train_Data.Default_Categories);
      end;
      Stand_X (100);
      St := TD.PBD;
      for K in 1 .. 3 loop
         Kept := Kept and then St.List (K).Noted
                 and then St.List (K).Value
                          = V_PBD (St.List (K).Id / 100,
                                   St.List (K).Gradient,
                                   St.List (K).Service)
                 and then St.List (K).Value <= Before (K);
         Lower := Lower or else St.List (K).Value < Before (K);
      end loop;
      Check (SI_Seen (SI.Info_PBD, SI.Change_Recalculated) = 1
             and then SI_Detail (SI.Info_PBD, SI.Change_Recalculated) = 3
             and then Kept and then Lower
             and then MRSP_At (70_000) = St.List (2).Value,
             "PBD: the Train Data changed (70 %), the three sections "
             & "computed again (3.11.11.3), lower");
      EVC_Train_Data.Set (EVC_Train_Data.Default,
                          EVC_Train_Data.Default_Categories);
      Stand_X (100);
      St := TD.PBD;
      Check (SI_Seen (SI.Info_PBD, SI.Change_Recalculated) = 2
             and then (for all K in 1 .. 3 => St.List (K).Value = Before (K)),
             "PBD: the Train Data back, the speeds back");
      Check (MRSP_Below_Sources, "PBD: the MRSP below its sources");
   end Scenario_PBD;

   --  3.11.12.2: the gradient profile of an unlinked group, relocated to
   --  the SOLR by the travelled distance (3.6.4.2.5 c), has the "max"
   --  items of its changes ahead of the "min" items (the SOLR less
   --  accurate than the unlinked group); between two elements the lower
   --  of the two, the profile covered, only the start of the profile left
   --  open
   procedure Scenario_Gradient_Gaps is
      St : Prof.Store_T;
      G  : SIn.Gradient_Profile_T;
   begin
      Start_X;
      Add_Group (With_Links (Group (10, 100),
                             Link_To ((1 => 900), (1 => 30))));
      declare
         U : Group_Def := Group (20, 300);
      begin
         U.Linked := False;
         Add_Group (U);
      end;
      Add_Group (Group (30, 1000));
      Carry (1, 0, SSP ((1 => (0, 200, False))));
      Carry (2, 0, Grad ((1 => (0, -10), 2 => (100, 5), 3 => (100, -20))));
      Run_X (32_000);
      St := TD.Gradients;
      G := SI.Current.Gradients;
      Check (St.Count = 3
             and then Min_X (St.List (2).Start) < Max_X (St.List (2).Start)
             and then Min_X (St.List (3).Start) < Max_X (St.List (3).Start),
             "gradient gaps: the max items of the changes ahead of the min "
             & "items (3.6.4.2.5 c)");
      Check (G.Count = 4 and then not G.Covered (1)
             and then Integer_64 (G.Segments (2).Start)
                        = Max_X (St.List (1).Start)
             and then G.Segments (2).Gradient = -10 and then G.Covered (2)
             and then Integer_64 (G.Segments (3).Start)
                        = Max_X (St.List (2).Start)
             and then G.Segments (3).Gradient = 5 and then G.Covered (3)
             and then Integer_64 (G.Segments (4).Start)
                        = Min_X (St.List (3).Start)
             and then G.Segments (4).Gradient = -20 and then G.Covered (4),
             "gradient gaps: covered, the lower neighbour over the gap "
             & "(-10 up to the max item of the change to 5, -20 from the "
             & "min item of the change to -20, 3.11.12.2)");
   end Scenario_Gradient_Gaps;

   --  3.6.3.2.2, 3.6.4.2.6, 3.13.7.2: the SSP of an unlinked group,
   --  relocated to the SOLR by the travelled distance (3.6.4.2.5 c), has
   --  the "max" items of its changes ahead of the "min" items (the SOLR
   --  less accurate than the unlinked group); between two elements the
   --  MRSP takes the lower of the two, not the maximum train speed, in
   --  the snapshot and in MSG_PLANNING; where the rear end counts
   --  (Q_FRONT 0) the element before the change ends a train length
   --  later and leaves no gap
   procedure Scenario_SSP_Gaps is
      St    : Prof.Store_T;
      V     : array (1 .. 6) of Integer := (others => 0);
      Apart : Boolean := True;
      Front : Integer_64;
      Ceil  : Boolean := False;

      --  MSG_PLANNING distance of the frame position X
      function Plan_M (X : Integer_64) return Natural is
        (Natural ((X - Front) / 100));
      function Lo (A, B : Integer) return Integer renames Integer'Min;
   begin
      Start_X;
      Add_Group (With_Links (Group (10, 100),
                             Link_To ((1 => 900), (1 => 30))));
      declare
         U : Group_Def := Group (20, 300);
      begin
         U.Linked := False;
         Add_Group (U);
      end;
      Add_Group (Group (30, 1000));
      Carry (1, 0, SSP ((1 => (0, 120, False))));
      Carry (1, 0, Grad ((1 => (0, 0))));
      Carry (1, 1, MA_Of ((1 => 3000), 160));
      --  from 300 m: 100, 60, 80 (rear end), 40 and 120 km/h
      Carry (2, 0, SSP ((1 => (0, 100, False), 2 => (100, 60, False),
                         3 => (100, 80, True), 4 => (100, 40, False),
                         5 => (100, 120, False))));
      Run_X (32_000);
      St := TD.SSP;
      --  the estimated front end, 3 m ahead of the antenna
      Front := Train_Cm + 300;
      for K in 1 .. Integer'Min (St.Count, 6) loop
         V (K) := St.List (K).Value;
      end loop;
      for K in 2 .. Integer'Min (St.Count, 6) loop
         Apart := Apart
           and then Min_X (St.List (K).Start) < Max_X (St.List (K).Start)
           and then Prof."=" (St.List (K - 1).Finish, St.List (K).Start);
      end loop;
      Check (St.Count = 6 and then Apart and then St.List (4).Delay_Length
             and then St.List (6).Open,
             "SSP gaps: the max items of the changes ahead of the min "
             & "items (3.6.4.2.5 c), the SSP of the linked group cut at the "
             & "start of the new one (3.7.3.1 a)");
      if St.Count /= 6 then
         return;
      end if;
      Check (MRSP_Is ((0, 10_000, Min_X (St.List (2).Start),
                       Min_X (St.List (3).Start), Max_X (St.List (4).Start),
                       Max_X (St.List (5).Start), Max_X (St.List (6).Start),
                       Min_X (St.List (4).Finish) + 20_000),
                      (4_444, V (1), V (2), V (3), V (4), V (5), V (4),
                       V (6))),
             "SSP gaps: the MRSP continuous, no step to the maximum train "
             & "speed between two SSP elements (3.6.3.2.2, 3.13.7.2)");
      Check (MRSP_At (Min_X (St.List (2).Start)) = Lo (V (1), V (2))
             and then MRSP_At (Max_X (St.List (2).Start) - 1)
                        = Lo (V (1), V (2))
             and then MRSP_At (Min_X (St.List (3).Start)) = Lo (V (2), V (3))
             and then MRSP_At (Max_X (St.List (3).Start) - 1)
                        = Lo (V (2), V (3))
             and then MRSP_At (Min_X (St.List (4).Start)) = Lo (V (3), V (4))
             and then MRSP_At (Max_X (St.List (4).Start) - 1)
                        = Lo (V (3), V (4))
             and then MRSP_At (Min_X (St.List (6).Start)) = Lo (V (5), V (6))
             and then MRSP_At (Max_X (St.List (6).Start) - 1)
                        = Lo (V (5), V (6)),
             "SSP gaps: the lower neighbour over the gap, at a decrease "
             & "(120 to 100, 100 to 60) and at an increase (60 to 80, 40 "
             & "to 120)");
      Check (Min_X (St.List (4).Finish) + 20_000 > Max_X (St.List (5).Start)
             and then MRSP_At (Min_X (St.List (5).Start)) = V (4)
             and then MRSP_At (Max_X (St.List (5).Start)) = V (5),
             "SSP gaps: the 80 km/h element up to its min end plus the "
             & "train length (3.11.3.1.3), no gap before the 40 km/h one");
      Check (MRSP_Below_Sources, "SSP gaps: the MRSP below its sources");
      --  MSG_PLANNING: the gap at 120 to 100 is behind the front end
      declare
         G    : constant Natural := Natural (Plan_Payload (9));
         Base : constant Natural := 10 + 3 * G;
         N    : constant Natural := Natural (Plan_Payload (Base));
      begin
         for K in 0 .. N - 1 loop
            Ceil := Ceil or else Plan_U16 (Base + 4 * K + 2) = 160;
         end loop;
      end;
      Check (Plan_Frames > 0 and then not Ceil
             and then Plan_Has_Speed (Plan_M (Min_X (St.List (3).Start)),
                                      Kmh_Plan (V (3)))
             and then Plan_Has_Speed (Plan_M (Max_X (St.List (4).Start)),
                                      Kmh_Plan (V (4)))
             and then Plan_Has_Speed (Plan_M (Max_X (St.List (5).Start)),
                                      Kmh_Plan (V (5)))
             and then Plan_Has_Speed (Plan_M (Max_X (St.List (6).Start)),
                                      Kmh_Plan (V (4))),
             "SSP gaps: MSG_PLANNING without the maximum train speed, 60 "
             & "km/h from the min item of the change to it, 80 km/h from "
             & "the max item of the change to it");
   end Scenario_SSP_Gaps;


end EVC_Test_PBD;
