--  ETCS on-board (EVC)
--  The movement authority of level 1 and its use on board,
--  implementation.

with EVC_Location; use EVC_Location;

package body EVC_Movement_Authority
  with SPARK_Mode => On,
       Refined_State => (State => (Current, Main_Known, Main_Speed,
                                   Main_Finish, Main_Open, Trip,
                                   Profiles, Mode_In_Use))
is

   Current     : MA_T;
   Main_Known  : Boolean := False;
   Main_Speed  : Speed_Cms_T := 0;
   Main_Finish : Location_T;
   Main_Open   : Boolean := True;
   Trip        : Boolean := False;
   Profiles    : Mode_Profile_Array;
   --  the M_MAMODE of the mode in use, 3 for another mode
   Mode_In_Use : Natural range 0 .. 3 := 3;

   function MA return MA_T is (Current)
     with Refined_Global => Current;
   function MA_Present return Boolean is (Current.Present)
     with Refined_Global => Current;
   function MA_Sense return Sense_T is (Current.Sense)
     with Refined_Global => Current;
   function V_Main_Known return Boolean is (Main_Known)
     with Refined_Global => Main_Known;
   function V_Main return Speed_Cms_T is (Main_Speed)
     with Refined_Global => Main_Speed;
   function V_Main_Finish return Location_T is (Main_Finish)
     with Refined_Global => Main_Finish;
   function V_Main_Open return Boolean is (Main_Open)
     with Refined_Global => Main_Open;
   function Trip_Ordered return Boolean is (Trip)
     with Refined_Global => Trip;
   function Mode_Profiles return Mode_Profile_Array is (Profiles)
     with Refined_Global => Profiles;
   function Mode_Profile (I : Positive) return Mode_Profile_T is
     (Profiles (I))
     with Refined_Global => Profiles;
   function SH_Profile return Boolean is
     (for some I in Profiles'Range =>
        Profiles (I).Used and then Profiles (I).Mode = 1)
     with Refined_Global => Profiles;

   --  The time since Started (0 when the clock is before it)
   function Elapsed (Now, Started : Unsigned_64) return Unsigned_64 is
     (if Now >= Started then Now - Started else 0);

   --  The value of a running timer became greater than its time-out
   function Over (X : Timer_T; Now : Unsigned_64) return Boolean is
     (X.Given and then X.Running and then not X.Infinite
      and then Elapsed (Now, X.Started) > Unsigned_64 (X.Timeout));

   --  A timer of a packet: given, T seconds, 1023 infinite
   function Timer (Given : Boolean; T : Natural) return Timer_T is
     ((Given    => Given,
       Infinite => T >= 1_023,
       Timeout  => (if T >= 1_023 then 0 else T * 1_000),
       Running  => False,
       Started  => 0))
     with Pre => T <= 1_023;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      Current := (others => <>);
      Main_Known := False;
      Main_Speed := 0;
      Main_Finish := (others => <>);
      Main_Open := True;
      Trip := False;
      Profiles := (others => No_Mode_Profile);
      Mode_In_Use := 3;
   end Clear;

   -----------------
   -- From_Packet --
   -----------------

   function From_Packet (P : ETCS_Track_Packets.P12.Packet_T;
                         M : Message_T) return MA_T
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      X     : MA_T;
      Pos   : Dist_T := 0;

      function D (Code : Natural) return Dist_T is
        (Scaled (Code, Scale))
        with Pre => Code <= 32_767 and then Scale <= 2;

      --  One more section of length L, its timer and stop location
      procedure Section (L : Natural; Q : Natural; T : Natural;
                         Stop : Natural)
        with Pre => L <= 32_767 and then Stop <= 32_767
                    and then T <= 1_023 and then Scale <= 2
                    and then X.Count < Max_Sections,
             Post => X.Count = X.Count'Old + 1
      is
         Begin_Pos : constant Dist_T := Pos;
      begin
         Pos := Sum (Pos, D (L));
         X.Count := X.Count + 1;
         X.Sections (X.Count) :=
           (Finish  => At_Offset (M, Pos),
            Timer   => Timer (Q = 1, T),
            Stop    => At_Offset (M, Sum (Begin_Pos, D (Stop))),
            Stopped => False);
      end Section;
   begin
      if Scale > 2 or else M.Origin = 0 then
         return X;
      end if;
      X.Present := True;
      X.Sense := M.Sense;
      X.Msg := M.Msg;
      X.Start := At_Offset (M, 0);
      for I in 1 .. Natural (P.N_ITER) loop
         pragma Loop_Invariant (X.Count = I - 1);
         Section (Natural (P.L_SECTION_List (I).L_SECTION),
                  Natural (P.L_SECTION_List (I).Q_SECTIONTIMER),
                  Natural (P.L_SECTION_List (I).T_SECTIONTIMER),
                  Natural (P.L_SECTION_List (I).D_SECTIONTIMERSTOPLOC));
      end loop;
      --  the End Section (3.8.3.3.1: the only one when N_ITER is 0)
      Section (Natural (P.L_ENDSECTION), Natural (P.Q_SECTIONTIMER),
               Natural (P.T_SECTIONTIMER),
               Natural (P.D_SECTIONTIMERSTOPLOC));
      if P.Q_ENDTIMER = 1 then
         X.End_Timer := Timer (True, Natural (P.T_ENDTIMER));
         X.End_Start :=
           At_Offset (M, Diff (Pos, D (Natural (P.D_ENDTIMERSTARTLOC))));
      end if;
      if P.Q_DANGERPOINT = 1 then
         X.Has_DP := True;
         X.DP := At_Offset (M, Sum (Pos, D (Natural (P.D_DP))));
         X.V_Release_DP := Natural (P.V_RELEASEDP);
      end if;
      if P.Q_OVERLAP = 1 then
         X.Has_OL := True;
         X.OL := At_Offset (M, Sum (Pos, D (Natural (P.D_OL))));
         X.OL_Start :=
           At_Offset (M, Diff (Pos, D (Natural (P.D_STARTOL))));
         X.OL_Timer := Timer (True, Natural (P.T_OL));
         X.V_Release_OL := Natural (P.V_RELEASEOL);
      end if;
      --  3.8.1.1 b): a non zero target speed makes it a LOA, the
      --  validity of the speed limited by T_EMA
      if P.V_EMA > 0 then
         X.Target_Speed := V5_To_Cms (Natural (P.V_EMA));
         X.LOA_Timer := Timer (True, Natural (P.T_EMA));
      end if;
      return X;
   end From_Packet;

   -----------------
   -- Take_V_Main --
   -----------------

   procedure Take_V_Main (P : ETCS_Track_Packets.P12.Packet_T) is
   begin
      if P.V_MAIN = 0 then
         Trip := True;
         Main_Known := False;
      else
         Main_Known := True;
         Main_Speed := V5_To_Cms (Natural (P.V_MAIN));
         Main_Open := True;
      end if;
   end Take_V_Main;

   procedure Clear_Trip_Order is
   begin
      Trip := False;
   end Clear_Trip_Order;

   --  The deletion beyond the SvL of X (A.3.4.1.3 [1])
   procedure Delete_Beyond_SvL (T       : Origin_Table_T;
                                X       : MA_T;
                                Before  : Natural;
                                Outcome : in out Outcome_T)
     with Post => Outcome.Accepted = Outcome.Accepted'Old
   is
   begin
      Outcome.Delete := True;
      Outcome.Delete_X := Frame (T, SvL_Location (X), Estimated_Item);
      Outcome.Delete_To := SvL_Location (X);
      Outcome.Delete_Before := Before;
   end Delete_Beyond_SvL;

   --  3.8.4.1.2: the End Section time-out withdraws the EOA to the train
   --  (A.3.4.1.3 [11]) and deletes beyond its max safe front end [10]
   procedure End_Section_Over (Train   : Train_Frame_T;
                               Outcome : in out Outcome_T)
     with Global => (In_Out => Current),
          Post => Current.Present = Current.Present'Old
                  and then Outcome.Accepted = Outcome.Accepted'Old
   is
   begin
      Current.Withdrawn := True;
      Current.Withdrawn_EOA := (Origin => 0, Offset => Train.Est_Front);
      Current.Withdrawn_SvL := (Origin => 0, Offset => Train.Max_Front);
      Current.Target_Speed := 0;
      Current.End_Timer.Running := False;
      Current.End_Timer.Given := False;
      Outcome.End_Expired := True;
      Outcome.Delete := True;
      Outcome.Delete_X := Train.Max_Front;
      Outcome.Delete_To := (Origin => 0, Offset => Train.Max_Front);
      Outcome.Delete_Before := Natural'Last;
   end End_Section_Over;

   --  3.8.4.4.2: the Overlap time-out deletes the overlap and its
   --  release speed; a LOA becomes an EOA
   procedure Overlap_Over (T       : Origin_Table_T;
                           Outcome : in out Outcome_T)
     with Global => (In_Out => Current),
          Post => Current.Present = Current.Present'Old
                  and then Outcome.Accepted = Outcome.Accepted'Old
   is
   begin
      Current.Has_OL := False;
      Current.OL_Timer.Running := False;
      Current.Target_Speed := 0;
      Outcome.Overlap_Expired := True;
      Delete_Beyond_SvL (T, Current, Natural'Last, Outcome);
   end Overlap_Over;

   ---------------
   -- Accept_MA --
   ---------------

   procedure Accept_MA (X          : MA_T;
                        T          : Origin_Table_T;
                        Train      : Train_Frame_T;
                        Passage_Ms : Unsigned_64;
                        Outcome    : out Outcome_T)
   is
      Old      : constant MA_T := Current;
      New_MA   : MA_T := X;
      S        : constant Sense_T := X.Sense;
      End_Now  : Boolean := False;
      OL_Now   : Boolean := False;
      Started  : constant Unsigned_64 := Passage_Ms;
   begin
      Outcome := (others => <>);
      Outcome.Accepted := True;

      --  3.8.5.1.3, 3.8.5.1.4, 3.8.5.2.4
      if Old.Present and then Old.Sense = S and then not Is_LOA (X) then
         if Is_LOA (Old)
           or else A (S, Frame (T, SvL_Location (X), Max_Item))
                   < A (S, Frame (T, SvL_Location (Old), Max_Item))
         then
            Outcome.Shortened := True;
         end if;
      end if;

      --  the section timers and the LOA speed timer: from the passage
      --  over the first balise of the group, the time the message came
      --  with (3.8.4.2.1 b, 3.8.4.3.1 b); 3.8.4.2.5
      for I in 1 .. New_MA.Count loop
         if New_MA.Sections (I).Timer.Given then
            New_MA.Sections (I).Timer.Running := True;
            New_MA.Sections (I).Timer.Started := Started;
            if Train.Valid
              and then A (S, Frame (T, New_MA.Sections (I).Stop, Min_Item))
                       <= A (S, Train.Min_Front)
            then
               New_MA.Sections (I).Stopped := True;
            end if;
         end if;
      end loop;
      if New_MA.LOA_Timer.Given then
         New_MA.LOA_Timer.Running := True;
         New_MA.LOA_Timer.Started := Started;
      end if;

      --  3.8.4.1.3, 3.8.4.1.4
      if New_MA.End_Timer.Given and then Train.Valid
        and then A (S, Frame (T, New_MA.End_Start, Max_Item))
                 <= A (S, Train.Max_Front)
      then
         if Old.Present and then Old.End_Timer.Given
           and then Old.End_Timer.Running
         then
            New_MA.End_Timer.Running := True;
            New_MA.End_Timer.Started := Old.End_Timer.Started;
         else
            End_Now := True;
         end if;
      end if;
      --  3.8.4.4.4, 3.8.4.4.5
      if New_MA.Has_OL and then Train.Valid
        and then A (S, Frame (T, New_MA.OL_Start, Max_Item))
                 <= A (S, Train.Max_Front)
      then
         if Old.Present and then Old.Has_OL and then Old.OL_Timer.Running
         then
            New_MA.OL_Timer.Running := True;
            New_MA.OL_Timer.Started := Old.OL_Timer.Started;
         else
            OL_Now := True;
         end if;
      end if;

      Current := New_MA;
      --  3.12.4.3: the mode profile goes with a new MA
      Profiles := (others => No_Mode_Profile);

      --  A.3.4.1.3 [1], 3.8.5.1.5: beyond the new SvL, of the
      --  information stored before this message
      if Outcome.Shortened then
         Delete_Beyond_SvL (T, Current, X.Msg, Outcome);
      end if;
      if End_Now then
         End_Section_Over (Train, Outcome);
      elsif OL_Now then
         Overlap_Over (T, Outcome);
      end if;
   end Accept_MA;

   -----------------------
   -- Take_Mode_Profile --
   -----------------------

   procedure Take_Mode_Profile (P : ETCS_Track_Packets.P80.Packet_T;
                                M : Message_T)
   is
      Scale : constant Natural := Natural (P.Q_SCALE);
      Start : Dist_T;
      N     : Natural range 0 .. Max_Mode_Profiles := 0;

      procedure Put (Mode : M_MAMODE_T; V : V_MAMODE_T; L : L_MAMODE_T;
                     Ack : L_ACKMAMODE_T; Q : Q_MAMODE_T)
        with Pre => Scale <= 2
      is
      begin
         if N = Max_Mode_Profiles or else Mode > 2 then
            return;
         end if;
         N := N + 1;
         Profiles (N) :=
           (Used         => True,
            Mode         => Mode,
            Speed        => V,
            Start        => At_Offset (M, Start),
            Finish       => At_Offset (M, Sum (Start,
                                               Scaled (Natural (L), Scale))),
            Open         => Mode = 1,
            Ack_Start    => At_Offset (M, Diff (Start,
                                                Scaled (Natural (Ack),
                                                        Scale))),
            SvL_At_Start => Q = 1,
            Msg          => M.Msg);
      end Put;
   begin
      if M.Origin = 0 or else Scale > 2 then
         return;
      end if;
      Profiles := (others => No_Mode_Profile);
      Start := Scaled (Natural (P.D_MAMODE), Scale);
      Put (P.M_MAMODE, P.V_MAMODE, P.L_MAMODE, P.L_ACKMAMODE, P.Q_MAMODE);
      for K in 1 .. Natural (P.N_ITER) loop
         declare
            X : ETCS_Track_Packets.P80.D_MAMODE_Item renames
              P.D_MAMODE_List (K);
         begin
            --  3.6.3.2.4 a): increments between the starts
            Start := Sum (Start, Scaled (Natural (X.D_MAMODE), Scale));
            Put (X.M_MAMODE, X.V_MAMODE, X.L_MAMODE, X.L_ACKMAMODE,
                 X.Q_MAMODE);
         end;
      end loop;
   end Take_Mode_Profile;

   ---------------
   -- Supervise --
   ---------------

   procedure Supervise (T       : Origin_Table_T;
                        Train   : Train_Frame_T;
                        Now_Ms  : Unsigned_64;
                        Outcome : out Outcome_T)
   is
      S : constant Sense_T := Current.Sense;
      K : Natural := 1;
   begin
      Outcome := (others => <>);
      if not Current.Present or else not Train.Valid then
         return;
      end if;

      --  3.8.4.2: the section timers, unless the EOA was withdrawn to the
      --  train (A.3.4.1.3 [11])
      while K <= Current.Count and then not Current.Withdrawn loop
         pragma Loop_Invariant
           (K >= 1 and then Current.Present = Current.Present'Loop_Entry);
         pragma Loop_Variant (Decreases => Current.Count - K);
         declare
            X : constant Section_T := Current.Sections (K);
            Back : constant Boolean :=
              A (S, Train.Min_Front)
                < A (S, Frame (T, X.Stop, Min_Item));
         begin
            if X.Timer.Given and then not X.Stopped
              and then not Back
            then
               --  3.8.4.2.3
               Current.Sections (K).Stopped := True;
               K := K + 1;
            elsif X.Timer.Given
              and then ((not X.Stopped and then Over (X.Timer, Now_Ms))
                        --  3.8.4.2.4
                        or else (X.Stopped and then Back
                                 and then Train.Standstill))
            then
               --  3.8.4.2.2: the EOA/LOA and the SvL at the entry of the
               --  section, the national release speed, no LOA
               Current.Count := K - 1;
               Current.Has_DP := False;
               Current.Has_OL := False;
               Current.End_Timer := (others => <>);
               Current.National_Release := True;
               Current.Target_Speed := 0;
               Current.LOA_Timer := (others => <>);
               Outcome.Section_Expired := K;
               Delete_Beyond_SvL (T, Current, Natural'Last, Outcome);
            else
               K := K + 1;
            end if;
         end;
      end loop;

      --  3.8.4.1: the End Section timer
      if Current.End_Timer.Given and then not Current.Withdrawn then
         if not Current.End_Timer.Running
           and then A (S, Train.Max_Front)
                    >= A (S, Frame (T, Current.End_Start, Max_Item))
         then
            Current.End_Timer.Running := True;
            Current.End_Timer.Started := Now_Ms;
         elsif Over (Current.End_Timer, Now_Ms) then
            End_Section_Over (Train, Outcome);
         end if;
      end if;

      --  3.8.4.4: the Overlap timer
      if Current.Has_OL and then not Current.Withdrawn then
         if not Current.OL_Timer.Running then
            if A (S, Train.Max_Front)
               >= A (S, Frame (T, Current.OL_Start, Max_Item))
            then
               Current.OL_Timer.Running := True;
               Current.OL_Timer.Started := Now_Ms;
            end if;
         elsif Over (Current.OL_Timer, Now_Ms)
           --  3.8.4.4.3
           or else Train.Standstill
         then
            Overlap_Over (T, Outcome);
         end if;
      end if;

      --  3.8.4.3: the LOA speed timer
      if Is_LOA (Current) and then Over (Current.LOA_Timer, Now_Ms) then
         Current.Target_Speed := 0;
         Current.LOA_Timer := (others => <>);
         Outcome.LOA_Expired := True;
         Delete_Beyond_SvL (T, Current, Natural'Last, Outcome);
      end if;
   end Supervise;

   -------------------
   -- Delete_Beyond --
   -------------------

   procedure Delete_Beyond (T          : Origin_Table_T;
                            X          : Dist_T;
                            To         : Location_T;
                            Before_Msg : Natural)
   is
      S : constant Sense_T := Current.Sense;
   begin
      for I in Profiles'Range loop
         if Profiles (I).Used and then Profiles (I).Msg < Before_Msg
           and then A (S, Frame (T, Profiles (I).Start, Estimated_Item))
                    >= A (S, X)
         then
            Profiles (I) := (others => <>);
         end if;
      end loop;
      if Main_Known
        and then (Main_Open
                  or else A (S, Frame (T, Main_Finish, Estimated_Item))
                          > A (S, X))
      then
         Main_Finish := To;
         Main_Open := False;
      end if;
   end Delete_Beyond;

   -------------------
   -- Delete_Behind --
   -------------------

   procedure Delete_Behind (T : Origin_Table_T; Rear : Dist_T;
                            Keep : Length_T)
   is
      S : constant Sense_T := Current.Sense;
   begin
      for I in Profiles'Range loop
         if Profiles (I).Used and then not Profiles (I).Open
           and then A (S, Frame (T, Profiles (I).Finish, Min_Item))
                    < Diff (A (S, Rear), Keep)
         then
            Profiles (I) := (others => <>);
         end if;
      end loop;
   end Delete_Behind;

   ----------
   -- Mark --
   ----------

   procedure Mark (Marks : in out Origin_Marks_T) is
   begin
      if Current.Present then
         Mark (Current.Start, Marks);
         for I in 1 .. Current.Count loop
            Mark (Current.Sections (I).Finish, Marks);
            Mark (Current.Sections (I).Stop, Marks);
         end loop;
         Mark (Current.End_Start, Marks);
         Mark (Current.DP, Marks);
         Mark (Current.OL, Marks);
         Mark (Current.OL_Start, Marks);
      end if;
      if Main_Known and then not Main_Open then
         Mark (Main_Finish, Marks);
      end if;
      for I in Profiles'Range loop
         if Profiles (I).Used then
            Mark (Profiles (I).Start, Marks);
            Mark (Profiles (I).Finish, Marks);
            Mark (Profiles (I).Ack_Start, Marks);
         end if;
      end loop;
   end Mark;

   ---------------
   -- Authority --
   ---------------

   procedure Authority (T       : Origin_Table_T;
                        V_NVREL : Speed_Cms_T;
                        R       : out Movement_Authority_T)
   is
      S : constant Sense_T := Current.Sense;
   begin
      R := (Present => False, EOA => 0, SvL => 0, LOA_Speed => 0,
            Release_Speed => (Kind => None, Speed => 0));
      if not Current.Present then
         return;
      end if;
      R.Present := True;
      if Is_LOA (Current) then
         --  an EBD target: the "max" item; no SvL, no release speed
         R.EOA := Frame (T, EOA_Location (Current), Max_Item);
         R.SvL := R.EOA;
         R.LOA_Speed := Current.Target_Speed;
         return;
      end if;
      R.EOA := Frame (T, EOA_Location (Current), Estimated_Item);
      R.SvL := Frame (T, SvL_Location (Current), Max_Item);
      if A (S, R.SvL) < A (S, R.EOA) then
         R.EOA := R.SvL;
      end if;
      if Current.Withdrawn then
         null;  -- A.3.4.1.3 [11]: no release speed
      elsif Current.National_Release then
         R.Release_Speed := (Kind => Fixed, Speed => V_NVREL);
      elsif Current.Has_OL then
         R.Release_Speed := Release (Current.V_Release_OL, V_NVREL);
      elsif Current.Has_DP then
         R.Release_Speed := Release (Current.V_Release_DP, V_NVREL);
      end if;
   end Authority;

   -------------------------
   -- Mode_Profile_Target --
   -------------------------

   procedure Set_Mode_In_Use (Code : Natural) is
   begin
      Mode_In_Use := Code;
   end Set_Mode_In_Use;

   procedure Mode_Profile_Target (T       : Origin_Table_T;
                                  Front   : Dist_T;
                                  Found   : out Boolean;
                                  EOA     : out Dist_T;
                                  Has_SvL : out Boolean;
                                  SvL     : out Dist_T)
   is
      S    : constant Sense_T := Current.Sense;
      Best : Dist_T := Max_Cm;
      K    : Natural := 0;
   begin
      Found := False;
      EOA := 0;
      Has_SvL := False;
      SvL := 0;
      if not Current.Present then
         return;
      end if;
      for I in Profiles'Range loop
         if Profiles (I).Used
           and then Natural (Profiles (I).Mode) /= Mode_In_Use
         then
            declare
               E : constant Dist_T :=
                 A (S, Frame (T, Profiles (I).Start, Estimated_Item));
            begin
               if E > A (S, Front) and then E < Best then
                  Best := E;
                  K := I;
               end if;
            end;
         end if;
      end loop;
      if K = 0 then
         return;
      end if;
      Found := True;
      EOA := Frame (T, Profiles (K).Start, Estimated_Item);
      if Profiles (K).SvL_At_Start then
         --  a)
         Has_SvL := True;
         SvL := Frame (T, Profiles (K).Start, Max_Item);
      elsif Is_LOA (Current) then
         if A (S, Frame (T, EOA_Location (Current), Min_Item))
            >= A (S, Frame (T, Profiles (K).Start, Min_Item))
         then
            --  b): as if no LOA had been given (3.8.4.5)
            Has_SvL := True;
            SvL := Frame (T, (if Current.Has_OL then Current.OL
                              elsif Current.Has_DP then Current.DP
                              else EOA_Location (Current)), Max_Item);
         else
            --  c)
            Has_SvL := True;
            SvL := Frame (T, Profiles (K).Start, Max_Item);
         end if;
      end if;
      if Has_SvL and then A (S, SvL) < A (S, EOA) then
         EOA := SvL;
      end if;
   end Mode_Profile_Target;

   ---------------
   -- Delete_MA --
   ---------------

   procedure Delete_MA is
   begin
      Current := (others => <>);
      Main_Known := False;
      Main_Speed := 0;
      Main_Finish := (others => <>);
      Main_Open := True;
      Profiles := (others => No_Mode_Profile);
   end Delete_MA;

   --------------------------
   -- Mode_Profile_Overlap --
   --------------------------

   function Mode_Profile_Overlap (T         : Origin_Table_T;
                                  Min_Front : Dist_T;
                                  Max_Front : Dist_T) return Boolean
   is
      S : constant Sense_T := Current.Sense;
   begin
      for I in Profiles'Range loop
         if Profiles (I).Used
           and then A (S, Max_Front)
                      >= A (S, Frame (T, Profiles (I).Start, Max_Item))
           and then (Profiles (I).Open
                     or else A (S, Min_Front)
                               < A (S, Frame (T, Profiles (I).Finish,
                                              Min_Item)))
         then
            return True;
         end if;
      end loop;
      return False;
   end Mode_Profile_Overlap;

end EVC_Movement_Authority;
